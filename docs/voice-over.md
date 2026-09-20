# Voice-over

Every spoken line in the game is read aloud so children who cannot read yet can follow the story.
There are two layers:

1. **Recorded clips** (`assets/audio/vo/*.wav`), used for every line the game speaks today.
2. **System text-to-speech**, the fallback for any line without a clip (for example a line added
   later). It depends on the operating system's voices and sounds flat; it is only a safety net.

## Voices

| Character | Voice | Notes |
|-----------|-------|-------|
| Wonder Light (also the verse and item descriptions) | Juno | preset voice, default settings |
| David | Cody | preset voice, default settings; reads slightly young, which suits a shepherd boy |

The clips were generated with the Seed Audio 1.0 text-to-speech model (24 kHz), then trimmed of
leading and trailing silence and saved as mono `.wav` (23 clips, about 2 minutes of speech, 5 MB).
The tool only exposes speed, loudness and pitch, so any emotion comes from the voice and the wording.

## How it plays

- `scripts/vo_library.gd` maps the exact spoken text (speaker name and quote marks removed) to a clip
  id; the file is `assets/audio/vo/<id>.wav`.
- `AudioDirector.speak_dialogue()` splits a dialogue block into lines. If every line has a clip they
  play in order with a 0.3 s gap; otherwise the whole block is spoken by the system voice.
- Pressing Space quickly cuts the current line and starts the next one. A line still waiting in the
  queue never plays after being cut.
- The pause menu's speaker button and read-aloud checkbox switch all of it off and on.
- A clip in `AudioDirector.vo_clips` (keyed by beat name) still takes priority over everything.

## Adding or changing a line

1. Change the text in the game (`chapter_director.gd`, `play_bounds.gd`, ...).
2. Add or update the entry in `LINES` in `scripts/vo_library.gd`.
3. Generate the clip in the matching voice, trim leading and trailing silence, and save it as mono
   `assets/audio/vo/<id>.wav`.
4. Run `godot --headless --import .` once, then `godot --headless --path . --script tests/smoke_test.gd`.
   The test fails if any line the game can speak has no entry or its file does not load.

If a line is edited but the library is not, the game quietly falls back to system speech for that
block, and the smoke test reports the line.

## Open

- Nobody has listened to the whole set in the running game yet. Check the pauses between lines, the
  breathing line ("Breathe with David...") and how David's voice sits next to Wonder Light's.
- Emotion is limited to what the voices and punctuation give. A human voice actor would do more.
- A quiet ambience or music bed under the voice, with ducking, is not done (backlog 3.2).
