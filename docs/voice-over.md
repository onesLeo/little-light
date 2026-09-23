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
| David | Bram | preset voice, default settings; a dry, young-adult voice. Chosen over Cody, whose recording sounded like it was made in a room and was too young |
| Jonathan | Dylan | User-selected male preset voice, default settings. Replaces Julian for both Jonathan lines. |

The clips were generated with the Seed Audio 1.0 text-to-speech model (24 kHz), then trimmed of
leading silence and saved as mono `.wav` (43 clips: 31 of the story as written plus the "Who is playing?" prompts, and 12 easier lines for younger children).
Leave about a third of a second after the last word. A tighter trim cuts the sentence off before it finishes.
Voice clips are imported as uncompressed PCM (`compress/mode=0`). Godot's default Quite OK Audio
compression is fine for footsteps, but on a tablet speaker it puts a haze on speech.
Voices differ in how "dry" they sound; if one sounds like it was recorded in a room, try another.
The tool only exposes speed, loudness and pitch, so any emotion comes from the voice and the wording.

On `feat/spine-god-is-the-source` the story lines were retimed in the same Juno / Bram voices.
Rushed lines were slowed, and a few wordy sentences were split into shorter beats so a child can
hold them. Joshua 1:9 and “Don't. Be. Afraid.” were left as they were. Exact wording lives in
`vo_library.gd`. Do **not** recut an unchanged line just to refresh it — a new take of the same
sentence will sit next to the old one and sound like a different recording.

## How it plays

- `scripts/vo_library.gd` maps the exact spoken text (speaker name and quote marks removed) to a clip
  id; the file is `assets/audio/vo/<id>.wav`.
- `AudioDirector.speak_dialogue()` splits a dialogue block into lines. If every line has a clip they
  play in order with a 0.3 s gap; otherwise the whole block is spoken by the system voice.
- Pressing Space quickly cuts the current line and starts the next one. A line still waiting in the
  queue never plays after being cut. After Joshua 1:9, Space does not skip ahead: the child taps
  Don't, Be, and Afraid, and each tap plays that one word (`wl_word_dont`, `wl_word_be`,
  `wl_word_afraid`, cut from the same take as `wl_dont_be_afraid`).
- The pause menu's speaker button and read-aloud checkbox switch all of it off and on.
- A clip in `AudioDirector.vo_clips` (keyed by beat name) still takes priority over everything.

## Easy words

A child who says they are 8 or younger when they are made ("How old are you?" on the "Who is playing?"
screen) plays with **Easy words** on: twelve lines swap for a simpler version (`scripts/easy_words.gd`), each
with its own recorded clip (`ez_*`). Every other line, and the Joshua 1:9 verse, is never changed. The
choice is kept with the child like read-aloud, and can be switched in the pause menu at any time; the
line on screen when it is switched stays as it is until the next line.

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

- The Juno/Bram set, including the spine / purpose / item recuts, has not yet been heard on a tablet speaker.
- Emotion is limited to what the voices and punctuation give. A human voice actor would do more.
- A quiet ambience or music bed under the voice, with ducking, is done (backlog 3.2).


The Chapter 2 arrival was regenerated in Juno on 2026-09-23: “This is the king's camp. The day is turning into night.” (`jn_arrive.wav`, mono 24 kHz PCM, Seed Audio job `50c40233-52c9-4109-97a3-27687e3753f1`). Jonathan's two lines were regenerated in the user-selected Dylan preset (`b847bc29-f184-583a-8ad9-d1f1e16d1a60`): `jn_hello` (job `13328a4f-32e0-47a9-a8df-482122c35694`) and `jn_give` (job `df42d83a-2791-42ba-ae72-97f6a525dc09`). Both use Seed Audio, mono 24 kHz PCM, with a short lead-in and a tail after the last word.

## Faith Journey map and chapter 2 easy words (2026-09-23)

Seventeen more clips, all Seed Audio 1.0, mono 24 kHz:

- **The Faith Journey map**, in Juno: "Hello!", "Your journey starts in the valley.", "The King's Camp is
  next.", "Tap a story to begin.", "One story at a time.", the locked card ("Finish Chapter 1, The valley,
  first. Then The King's Camp will open for you.") and the path ahead ("This part of the path is still
  ahead. New stories will be waiting here."). The greeting on screen has the child's name ("Hello, Maya!");
  the voice says only "Hello!", because a recording cannot say every name.
- **The camp lookout**, in Juno: "Look. David's valley is still down there." (`jn_lookout`).
- **Chapter 2 in easy words** (`ez_jn_*`): seven lines in Juno, and Jonathan's two in Dylan.

The takes are downloaded, trimmed (a short lead-in, about a third of a second after the last word) and
saved by `python tools/fetch_vo.py`, which also writes each clip's import settings as uncompressed PCM.
It uses only the Python standard library. Run it once from the project folder, open the project in Godot
(or `godot --headless --import .`), then run the smoke test; until then those lines fall back to the
system voice, and the smoke test lists them as missing.

## Who is talking

Above the dialogue bar a name tag shows who is being read aloud, with a small drawn face: Wonder
Light's gold glow, David (short brown hair, blue tunic), Jonathan (long hair, gold band, wine tunic),
or an open book for a Bible verse (`scripts/dialogue_view.gd`). It follows `AudioDirector.line_started`,
so in a block with two speakers it changes as the voice changes. In the bar, each speaker's name is in
their colour, stage directions are softer, and while a block is read the line being spoken stays in
full ink and the others step back a little, so a parent can point along. The story still writes plain
text to `DialogueLabel`; the view draws the same text over it with the same font and wrapping.
