#!/usr/bin/env python3
"""Download the Seed Audio takes for the lines added with the Faith Journey map, chapter 2's
easy words and chapter 4, trim them, and save them as the game's voice clips
(assets/audio/vo/<id>.wav).

Standard library only, so it runs the same on Windows, macOS and Linux:

    python tools/fetch_vo.py            # every clip not in assets/audio/vo yet
    python tools/fetch_vo.py --force    # download again and overwrite
    python tools/fetch_vo.py --only ark_ --force   # only chapter 4's clips, replacing the stand-ins

A take saved as MP3 (the Seed Speech engine only writes MP3) needs `pip install miniaudio` to decode.

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
    # Chapter 4 (Noah's Ark), Wonder Light in Juno. Seed Audio 1.0 failed the olive leaf and
    # Genesis 9:13 again and again, so those two are Juno through Seed Speech (MP3; see read_audio).
    # Noah in Arthur (the one preset marked "old"), his wife in Helena.
    "ark_map": ("hf_20260924_233009_a809ac8f-7526-4631-a6da-733af7d87ecc.wav", "Juno", "Noah's Ark is next."),
    "ark_arrive": ("hf_20260924_233009_2223c5cb-7fbc-4fb3-881f-6c8198545d69.wav", "Juno", "Long before David, God asked Noah to trust him and build something no one had seen before."),
    "ark_hurt": ("hf_20260924_233039_dfeaee00-1544-45ac-b463-6f407ec391f4.wav", "Juno", "People were hurting one another, and the world was full of violence."),
    "ark_find": ("hf_20260924_233038_88b0a606-77b9-4629-9b3d-315a8e67bf75.wav", "Juno", "Find the mallet, the rope, and the jar of pitch. Bring them to Noah."),
    "ark_mallet": ("hf_20260924_233038_a0a92b34-ca90-4912-8b1a-e712135fd83f.wav", "Juno", "A wooden mallet. Noah builds with it."),
    "ark_rope": ("hf_20260924_233127_28102037-3449-438c-8af6-6421a3960632.wav", "Juno", "A coil of rope. It holds the ark together."),
    "ark_pitch": ("hf_20260924_233127_35c58ce2-6fa6-4666-b58b-8c1ad6bf06a5.wav", "Juno", "A jar of sticky pitch. It keeps water out."),
    "ark_panel": ("hf_20260924_233127_7bb8128e-327a-4d2c-898d-91687702bdf4.wav", "Juno", "Let's finish this panel. Three pegs, then draw the rope tight."),
    "ark_pairs": ("hf_20260924_233243_406e327c-6644-4f5b-bf75-95b691096465.wav", "Juno", "Two by two, they're coming. Help these animals find their partners."),
    "ark_match": ("hf_20260924_233159_b1a43d20-b626-4ed7-9d4e-d98470fd8c74.wav", "Juno", "This friend is looking for its match."),
    "ark_door": ("hf_20260924_233158_261f4bf1-36ab-4ed1-95e9-4cf5f275b124.wav", "Juno", "Noah's family and the animals are safely inside. God closes the door and keeps them safe."),
    "ark_rain": ("hf_20260924_233243_32dd4199-89d0-410b-b088-f4c1b32e8f11.wav", "Juno", "The water covered the land. God kept Noah's family, and the animals with them, safe inside."),
    "ark_send": ("hf_20260924_233243_1fef697f-c99f-438a-a16f-ad4d1f66def8.wav", "Juno", "Let's open the window and send the dove."),
    "ark_dove_back": ("hf_20260924_233410_371ae1ce-ed81-4aaa-b4b0-f89f51d1120c.wav", "Juno", "The dove came back safe. The water is still too high."),
    "ark_leaf": ("hf_20260924_233934_d01eed8d-df2a-4796-b26a-661d84624838.mp3", "Juno (Seed Speech)", "Look, an olive leaf. The water is going down."),
    "ark_verse_ref": ("hf_20260924_233410_42d6e91a-e4d3-4459-8053-175a5f9d14ef.wav", "Juno", "Genesis, chapter nine, verse thirteen."),
    "ark_verse": ("hf_20260924_233934_fbfaa8dd-a91a-4d7a-8754-4947e5d47b70.mp3", "Juno (Seed Speech)", "I set my rainbow in the cloud, and it will be a sign of a covenant between me and the earth."),
    "ark_covenant": ("hf_20260924_233444_fe8a604d-2e0d-410a-a0d9-96374b59705e.wav", "Juno", "God's covenant is a promise God chooses to keep."),
    "ark_word_rainbow": ("hf_20260924_233628_191cf45f-d2b4-4aea-a44a-60e184f356d0.wav", "Juno", "Rainbow."),
    "ark_word_sign": ("hf_20260924_233654_ffb2db77-ba87-488b-b740-fba4be511522.wav", "Juno", "Sign."),
    "ark_word_promise": ("hf_20260924_233725_e842db2b-e007-4187-8aa8-73cd8158cfd4.wav", "Juno", "Promise."),
    "ark_charm": ("hf_20260924_233443_7d53496e-3a56-4430-89b8-92a575a49934.wav", "Juno", "A Trust charm. Noah kept building before he could see the rain."),
    "ark_keep": ("hf_20260924_233529_e663cc86-90d6-4906-8769-524b2043456b.wav", "Juno", "Keep it close. Trust God, even before you see the way through."),
    "ark_noah": ("hf_20260924_232807_00432a3e-7f80-46fc-89ff-c6c9a948b15b.wav", "Arthur", "God told me to build this ark. I cannot see the rain yet, but I trust him."),
    "ark_dry": ("hf_20260924_234814_07e9880a-2156-420b-86c8-0de7ac1ef2fb.wav", "Arthur", "Dry ground. Thank you for keeping us safe."),
    "ark_wife": ("hf_20260924_232847_f900dcfa-849c-40ed-87f6-e2e80dddfed2.wav", "Helena", "This way. Walk together up the wide ramp."),
    # Chapter 3 (The Beginning): Wonder Light in Juno (1 Samuel 16:7 through Seed Speech, as Seed
    # Audio 1.0 failed it twice), Samuel in Gideon, Jesse in Desmond, the younger David in Bram.
    "bg_turn_back": ("hf_20260925_154704_5356b3ba-2ba4-4cf8-a315-08b70a76f406.wav", "Juno", "We are turning back the page. This is Bethlehem, before the valley. David's family is getting ready for a guest."),
    "bg_look_around": ("hf_20260925_154704_72900905-0be4-480c-98a1-eacc53e8ae9e.wav", "Juno", "David is out with the sheep. You may notice the things he uses to care for them."),
    "bg_samuel_coming": ("hf_20260925_154704_17fc83ca-5760-4199-80c7-0962e5f415e8.wav", "Juno", "Samuel is coming. Let's get the cushion, the cup and the lamp ready for him."),
    "bg_harp": ("hf_20260925_154704_5b16cea5-90ce-43ec-9484-e8582a3dcebd.wav", "Juno", "A small harp. David plays it while he watches the sheep."),
    "bg_bowl": ("hf_20260925_154703_29365e01-bf31-47c1-b408-cef81626199d.wav", "Juno", "A bowl of water for the sheep. David cares for them every day."),
    "bg_cloak": ("hf_20260925_154703_4e62650b-e65a-4e63-aa1a-cfa3f2bbd760.wav", "Juno", "A plain shepherd's cloak, made for work outside."),
    "bg_ready": ("hf_20260925_154703_be15678a-8ff6-4959-99b9-ff0ad822df24.wav", "Juno", "Everything is ready. Here comes Samuel."),
    "bg_brothers": ("hf_20260925_154703_a8642baa-8e32-41b9-a122-abf40a3a98fe.wav", "Juno", "Jesse's seven older sons come forward, one by one."),
    "bg_waits": ("hf_20260925_154945_93055584-ad90-4f9a-9f02-529c43ff5d24.wav", "Juno", "Samuel waits. The one God has chosen is not here yet."),
    "bg_call_david": ("hf_20260925_154703_86b2d1e9-7e16-4d33-a45c-1704c9e23e59.wav", "Juno", "Let's call David home."),
    "bg_heart": ("hf_20260925_154945_805e49ea-6baa-4aff-b6fc-fe9a23f2f15a.wav", "Juno", "People notice the outside first. God sees who you are inside."),
    "bg_anoint": ("hf_20260925_154703_1bd87c98-6b40-49b5-b243-4a99ca10e160.wav", "Juno", "Samuel pours the oil. God has chosen David, the youngest shepherd."),
    "bg_reflect": ("hf_20260925_154809_851fe9de-5715-49ad-9ae4-2bde63cda833.wav", "Juno", "David was caring for the sheep when nobody expected him to be called. God saw his heart. God sees you too."),
    "bg_charm": ("hf_20260925_154809_46895acb-1cc0-4d74-9c04-77a741e5a742.wav", "Juno", "A Faithful Heart charm, for caring well in quiet places."),
    "bg_keep_close": ("hf_20260925_154945_dd3e71ba-9630-4f84-9937-def69bad0f31.wav", "Juno", "Keep it close. Be faithful with the small things in front of you."),
    "bg_map": ("hf_20260925_154809_0f8a750a-224f-4027-a8a2-beed2592955a.wav", "Juno", "The Beginning is next."),
    "bg_locked": ("hf_20260925_154809_6a31cbec-451c-46b3-9c98-8f44d6bd5d49.wav", "Juno", "Finish Chapter 2, The King's Camp, first. Then The Beginning will open for you."),
    "bg_locked_ark": ("hf_20260925_154945_0b09d07a-ba4a-4b2d-a08e-c2ca3c5546fd.wav", "Juno", "Finish Chapter 3, The Beginning, first. Then Noah's Ark will open for you."),
    "bg_verse_ref": ("hf_20260925_154945_0859a9e5-3545-43ef-be2c-9d668fdb0f62.wav", "Juno", "First Samuel, chapter sixteen, verse seven."),
    "bg_verse": ("hf_20260925_160647_4c497bba-a3d4-4894-9124-f5eb3e43460c.mp3", "Juno (Seed Speech)", "But Yahweh said to Samuel, ‘Don't look on his face, or on the height of his stature, because I have rejected him; for I don't see as man sees. For man looks at the outward appearance, but Yahweh looks at the heart.’"),
    "bg_word_god": ("hf_20260925_160603_e7919092-b6f9-4283-970d-008b3f7f55e4.wav", "Juno", "God."),
    "bg_word_sees": ("hf_20260925_155740_823309ee-efb5-413f-b302-7bdb054bf851.wav", "Juno", "Sees."),
    "bg_word_heart": ("hf_20260925_155739_84799076-1a03-4e02-b3df-2d504ba57fb7.wav", "Juno", "Heart."),
    "bg_not_these": ("hf_20260925_155739_fdb01241-8a44-4a06-bbb5-596d926ce0ac.wav", "Gideon", "Yahweh has not chosen these."),
    "bg_ask": ("hf_20260925_155739_920045a2-363e-4960-bcf7-294422ca4c28.wav", "Gideon", "Are all your children here?"),
    "bg_jesse_welcome": ("hf_20260925_160602_08799f53-e487-43bd-84a1-b179564773bf.wav", "Desmond", "Samuel! Welcome to our home."),
    "bg_youngest": ("hf_20260925_155739_b1282b21-ab0c-446c-a22c-55b7e6804f9d.wav", "Desmond", "The youngest is still caring for the sheep."),
    "bg_david_called": ("hf_20260925_155739_882a0418-10f8-43ef-bf8a-9d66e3671a6a.wav", "Bram", "You called for me?"),
    # Chapter 3 in easy words (ez_bg_*): Wonder Light in Juno, Samuel in Gideon, Jesse in Desmond.
    "ez_bg_turn_back": ("hf_20260925_172605_ed3fed3a-7e34-434b-b271-4e80eca311c7.wav", "Juno", "This is Bethlehem, long ago. David's family is waiting for a guest."),
    "ez_bg_look_around": ("hf_20260925_172121_774a73bb-ad77-4741-b3c4-09e955ec07a2.wav", "Juno", "David is with the sheep. Look for his things."),
    "ez_bg_samuel_coming": ("hf_20260925_172121_1f68d988-8a9d-4db9-82cc-260ceac4f6ac.wav", "Juno", "Samuel is coming. Let's bring the cushion, the cup and the lamp."),
    "ez_bg_brothers": ("hf_20260925_172807_2bae845f-ee94-4e9a-a155-5a2d5ebf9bf8.wav", "Juno", "Here come David's seven big brothers, one by one."),
    "ez_bg_waits": ("hf_20260925_172122_ecce89cf-e310-4241-a1dd-2902dc4a91e4.wav", "Juno", "Samuel waits. God's choice is not here yet."),
    "ez_bg_heart": ("hf_20260925_172121_8ee7710b-03f6-41f7-a412-a1ea19ea9507.wav", "Juno", "People look at the outside. God looks at your heart."),
    "ez_bg_anoint": ("hf_20260925_172605_75879663-6928-439e-9462-7d0ab5562cba.wav", "Juno", "Samuel pours oil on David's head. God chose David."),
    "ez_bg_reflect": ("hf_20260925_172605_6faeac6b-423b-4730-bbfb-2771b7168cbf.wav", "Juno", "Nobody thought of David. But God saw his heart. God sees you too."),
    "ez_bg_charm": ("hf_20260925_172605_fb24afed-d906-452f-b918-4de6e779cacd.wav", "Juno", "A Faithful Heart charm, for caring for little things."),
    "ez_bg_keep_close": ("hf_20260925_172807_18ef844c-d004-4f9e-b1ed-81ac032c2119.wav", "Juno", "Keep it close. Care well for little things."),
    "ez_bg_not_these": ("hf_20260925_172956_c3d98125-bf4a-44cb-92f2-bde409ff7bb2.wav", "Gideon", "God has not chosen these."),
    "ez_bg_youngest": ("hf_20260925_172605_84263fa2-84bc-46f4-9c61-4c9373fe42fc.wav", "Desmond", "My youngest son is out with the sheep."),
}

LEAD_SECONDS = 0.06
TAIL_SECONDS = 0.35
THRESHOLD = 0.02  # of full scale


def read_audio(data: bytes, name: str) -> tuple[list[float], int]:
    """Mono samples and the sample rate from a WAV take, or an MP3 one through miniaudio."""
    if not name.endswith(".mp3"):
        return read_wav(data)
    try:
        import miniaudio  # noqa: PLC0415 - only needed for the few MP3 takes
    except ImportError as error:
        raise RuntimeError("this take is MP3; run `pip install miniaudio` and try again") from error
    decoded = miniaudio.decode(data, output_format=miniaudio.SampleFormat.FLOAT32, nchannels=1)
    return list(decoded.samples), decoded.sample_rate


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


## A click or pop is loud for a moment only; a word stays up for at least this long.
MIN_SPEECH_SECONDS = 0.1
SPEECH_LEVEL = 0.04  # of full scale, for a window to count towards a word
WINDOW_SECONDS = 0.02
## A pause inside a line longer than this is shortened to PAUSE_KEEP_SECONDS: some takes stop for
## a second and a half after a full stop, and a child's attention goes with it.
LONG_PAUSE_SECONDS = 0.6
PAUSE_KEEP_SECONDS = 0.45


def _speech_windows(samples: list[float], win: int) -> list[bool]:
    """True for each window that is part of a word (a run of loud windows long enough)."""
    peaks = [max((abs(v) for v in samples[i:i + win]), default=0.0) for i in range(0, len(samples), win)]
    need = max(int(round(MIN_SPEECH_SECONDS / WINDOW_SECONDS)), 1)
    speech = [False] * len(peaks)
    start = None
    for i, peak in enumerate(peaks + [0.0]):
        if peak >= SPEECH_LEVEL:
            start = i if start is None else start
        elif start is not None:
            if i - start >= need:
                for k in range(start, i):
                    speech[k] = True
            start = None
    return speech


def trim(samples: list[float], rate: int) -> list[float]:
    """A short lead-in before the first word, pauses inside the line kept short, and about a third
    of a second after the last word. The takes end with a click or two, which must not count as
    a word, or the silence before them is kept."""
    win = max(int(WINDOW_SECONDS * rate), 1)
    speech = _speech_windows(samples, win)
    words = [i for i, on in enumerate(speech) if on]
    if not words:
        return samples
    first, last = words[0], words[-1]
    start = max(first * win - int(LEAD_SECONDS * rate), 0)
    end = min((last + 1) * win + int(TAIL_SECONDS * rate), len(samples))
    out: list[float] = []
    cursor = start
    i = first
    while i <= last:
        if speech[i]:
            i += 1
            continue
        gap_end = i
        while gap_end <= last and not speech[gap_end]:
            gap_end += 1
        gap = (gap_end - i) * win
        if gap > LONG_PAUSE_SECONDS * rate:
            keep_after = int(PAUSE_KEEP_SECONDS * rate * 0.45)
            keep_before = int(PAUSE_KEEP_SECONDS * rate) - keep_after
            out.extend(samples[cursor:i * win + keep_after])
            cursor = gap_end * win - keep_before
        i = gap_end
    out.extend(samples[cursor:end])
    # A take that stops right after its last word gets the usual quiet tail added.
    short = (last + 1) * win + int(TAIL_SECONDS * rate) - end
    if short > 0:
        out.extend([0.0] * short)
    return out


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
    parser.add_argument("--retrim", action="store_true", help="trim the clips already saved again, without downloading")
    parser.add_argument("--only", default="", help="only the clips whose id starts with this, e.g. ark_")
    args = parser.parse_args()
    out_dir = Path(__file__).resolve().parent.parent / "assets" / "audio" / "vo"
    if args.retrim:
        for clip_id in CLIPS:
            target = out_dir / f"{clip_id}.wav"
            if target.exists():
                samples, rate = read_wav(target.read_bytes())
                trimmed = trim(samples, rate)
                write_wav(target, trimmed, rate)
                print(f"  trimmed {clip_id}: {len(samples) / rate:.2f}s -> {len(trimmed) / rate:.2f}s")
        return 0
    failed = 0
    for clip_id, (result, voice, line) in CLIPS.items():
        if not clip_id.startswith(args.only):
            continue
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
                samples, rate = read_audio(response.read(), result)
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
