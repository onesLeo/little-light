#!/usr/bin/env python3
"""Download the Seed Audio takes for the lines added with the Faith Journey map and chapter 2's
easy words, trim them, and save them as the game's voice clips (assets/audio/vo/<id>.wav).

Standard library only, so it runs the same on Windows, macOS and Linux:

    python tools/fetch_vo.py            # every clip not in assets/audio/vo yet
    python tools/fetch_vo.py --force    # download again and overwrite

Then open the project in Godot once (or run `godot --headless --import .`) so the new clips are
imported, and run the smoke test. See docs/voice-over.md.

The takes are Seed Audio 1.0 jobs on the project's Higgsfield account: Wonder Light in the Juno
preset, Jonathan in Dylan. Each is cut to a short lead-in and about a third of a second after the
last word (a tighter tail cuts the sentence off), and saved as mono 16-bit PCM.
"""
from __future__ import annotations

import argparse
import array
import io
import struct
import sys
import urllib.request
import wave
from pathlib import Path

BASE = "https://d8j0ntlcm91z4.cloudfront.net/user_3BOfcZDWOCLs82mm9wcEBP5ET6w/"

# clip id -> (result file, voice, the exact line as it is spoken)
CLIPS = {
    "wl_hello": ("hf_20260923_220440_80818d0e-b819-471b-8260-16f054c8c3ef.wav", "Juno", "Hello!"),
    "wl_map_valley": ("hf_20260923_220440_507c9427-ba5f-461c-a1b3-7e2c228f0ddb.wav", "Juno", "Your journey starts in the valley."),
    "wl_map_camp": ("hf_20260923_220440_423b81b2-f56e-47b8-a57b-0e9596de3e48.wav", "Juno", "The King's Camp is next."),
    "wl_map_any": ("hf_20260923_220440_5154b0db-d7a5-4081-aa50-691befa9a2cd.wav", "Juno", "Tap a story to begin."),
    "wl_path_ahead": ("hf_20260923_220440_448cc513-8373-4d9d-9560-53e88a23e9ed.wav", "Juno", "This part of the path is still ahead. New stories will be waiting here."),
    "ez_jn_arrive": ("hf_20260923_220440_6bb9826d-4d23-4908-8969-92144e433311.wav", "Juno", "This is the king's camp. It is almost night."),
    "ez_jn_robe": ("hf_20260923_220440_8e70efd4-57cb-4460-9a32-c93eb1a2e054.wav", "Juno", "A robe. It is a gift for David."),
    "jn_lookout": ("hf_20260923_220539_a82ba3a2-4a2c-4540-8dc2-4476c4e21aec.wav", "Juno", "Look. David's valley is still down there."),
    "wl_map_open": ("hf_20260923_220539_051551ca-6aac-46b8-b9e3-feb2af3b4ebc.wav", "Juno", "One story at a time."),
    "wl_locked_camp": ("hf_20260923_220539_01b3f259-1a67-47d0-99f6-085dfc43e8d4.wav", "Juno", "Finish Chapter 1, The valley, first. Then The King's Camp will open for you."),
    "ez_jn_find": ("hf_20260923_220756_1d61c291-5f7f-4eed-8171-019962ff3f52.wav", "Juno", "Find the robe, the bow, and the belt. They are gifts for David."),
    "ez_jn_bow": ("hf_20260923_220754_7652dfd1-6eed-42f3-952a-ca2af79c70e4.wav", "Juno", "A bow. It is a gift, not for fighting."),
    "ez_jn_belt": ("hf_20260923_220802_1ec785fb-6b41-4d12-a239-3416c0a8f0c3.wav", "Juno", "A belt. Friends share what they have."),
    "ez_jn_cord": ("hf_20260923_220902_081e74e5-c0e8-45df-9073-715e812a91e3.wav", "Juno", "Loop the cord. Three slow loops."),
    "ez_jn_charm": ("hf_20260923_220903_ec140e67-b97a-46e8-a55a-aa72121b2d62.wav", "Juno", "A Friendship charm, because Jonathan gave to his friend."),
    "ez_jn_hello": ("hf_20260923_220910_9b139b4b-8dce-4478-ac8e-fb8ffead0d55.wav", "Dylan", "I am Jonathan. God was with David today."),
    "ez_jn_give": ("hf_20260923_221334_78d0e038-3dad-4b0d-944a-3df9bf995fd3.wav", "Dylan", "These were mine. Now they are David's. He is my friend."),
}

LEAD_SECONDS = 0.06
TAIL_SECONDS = 0.35
THRESHOLD = 0.02  # of full scale


def read_wav(data: bytes) -> tuple[list[float], int]:
    """Mono samples in -1..1 and the sample rate, from 16-bit PCM or 32-bit float WAV."""
    if data[:4] != b"RIFF" or data[8:12] != b"WAVE":
        raise ValueError("not a WAV file")
    pos, fmt, raw = 12, None, None
    while pos + 8 <= len(data):
        chunk, size = data[pos:pos + 4], struct.unpack("<I", data[pos + 4:pos + 8])[0]
        body = data[pos + 8:pos + 8 + size]
        if chunk == b"fmt ":
            fmt = struct.unpack("<HHIIHH", body[:16])
        elif chunk == b"data":
            raw = body
        pos += 8 + size + (size & 1)
    if fmt is None or raw is None:
        raise ValueError("WAV without fmt or data")
    kind, channels, rate, _, _, bits = fmt
    if kind == 1 and bits == 16:
        values = array.array("h")
        values.frombytes(raw[: len(raw) // 2 * 2])
        if sys.byteorder == "big":
            values.byteswap()
        scaled = [v / 32768.0 for v in values]
    elif kind == 3 and bits == 32:
        values = array.array("f")
        values.frombytes(raw[: len(raw) // 4 * 4])
        if sys.byteorder == "big":
            values.byteswap()
        scaled = list(values)
    else:
        raise ValueError(f"unsupported WAV format {kind}/{bits} bit")
    if channels > 1:
        scaled = [sum(scaled[i:i + channels]) / channels for i in range(0, len(scaled), channels)]
    return scaled, rate


def trim(samples: list[float], rate: int) -> list[float]:
    loud = [i for i, v in enumerate(samples) if abs(v) >= THRESHOLD]
    if not loud:
        return samples
    start = max(loud[0] - int(LEAD_SECONDS * rate), 0)
    end = min(loud[-1] + int(TAIL_SECONDS * rate), len(samples))
    return samples[start:end]


def write_wav(path: Path, samples: list[float], rate: int) -> None:
    pcm = array.array("h", (max(-32768, min(32767, int(round(v * 32767)))) for v in samples))
    if sys.byteorder == "big":
        pcm.byteswap()
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(rate)
        out.writeframes(pcm.tobytes())


# Voice clips are imported as uncompressed PCM: Godot's default Quite OK Audio compression puts a
# haze on speech on a tablet speaker. Godot fills in the rest of this file on the next import.
IMPORT_SETTINGS = """[remap]

importer="wav"
type="AudioStreamWAV"

[params]

force/8_bit=false
force/mono=false
force/max_rate=false
force/max_rate_hz=44100
edit/trim=false
edit/normalize=false
edit/loop_mode=0
edit/loop_begin=0
edit/loop_end=-1
compress/mode=0
"""


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--force", action="store_true", help="download and overwrite clips that exist")
    args = parser.parse_args()
    out_dir = Path(__file__).resolve().parent.parent / "assets" / "audio" / "vo"
    failed = 0
    for clip_id, (result, voice, line) in CLIPS.items():
        target = out_dir / f"{clip_id}.wav"
        if target.exists() and not args.force:
            print(f"  have  {clip_id}")
            continue
        if result.startswith("JOB:"):
            print(f"  skip  {clip_id}: the take ({result[4:]}) has no file name yet; download it from Higgsfield")
            failed += 1
            continue
        try:
            with urllib.request.urlopen(BASE + result, timeout=60) as response:
                samples, rate = read_wav(response.read())
            write_wav(target, trim(samples, rate), rate)
            settings = target.with_name(target.name + ".import")
            if not settings.exists():
                settings.write_text(IMPORT_SETTINGS, encoding="utf-8")
            print(f"  saved {clip_id} ({voice}): {line}")
        except Exception as error:  # noqa: BLE001 - report and carry on with the rest
            print(f"  FAIL  {clip_id}: {error}")
            failed += 1
    print("done" if failed == 0 else f"{failed} clip(s) not saved")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
