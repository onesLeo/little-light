# Chapter 3 — implementation readiness

**Decision: GO for foundation work and a playable greybox. HOLD final character art, paid voice
generation and production audio until the story/value and prototype gates below pass.**

This audit compares [chapter-3-concept.md](chapter-3-concept.md) with the current Chapter 1–2 code,
progression, journal, map and test structure.

## What is ready

| Area | Status | Evidence |
|---|---|---|
| Story shape | Ready for prototype | Eight clear beats, explicit prequel framing and a defined child role |
| Player safety | Ready | The player prepares the welcome and observes the anointing; the child never chooses the king |
| Environment | Ready for greybox | One compact courtyard with house, table, fold, sheep path and brother staging area |
| Asset scope | Ready for estimates | Three hero rigs, one shared brother rig, eleven procedural props and reused sheep/vegetation |
| Core activity | Ready for paper prototype | Prepare the Welcome has three objects, generous placement silhouettes and no failure state |
| Procession | Ready for prototype | Seven respectful brothers, overlapping 8–10 second sequence and no repeated dialogue |
| Motion direction | Ready | Shared conversation motion, desynchronised brother idle, younger-David walk and cloth/oil motion are specified |
| Camera and tone | Ready | Shot purpose is documented; the scene avoids coronation spectacle and ranking imagery |
| Verse source | Text verified | 1 Samuel 16:7 now uses the complete World English Bible Classic wording |

Official verse source: [World English Bible Classic, 1 Samuel
16](https://ebible.org/study/content/texts/eng-web/S116.html).

## Gates before final production

### 1. Value and script lock

The working value is **Faithfulness / Faithful Heart**, while the passage's central truth remains
**God sees the heart**. Test that framing with parents and children, then have the complete script
reviewed for biblical wording and for any suggestion that David earned God's choice. The verified
verse must stay distinct from Wonder Light's easier explanation.

This does not block a silent greybox. It blocks final recorded dialogue, journal copy and marketing
claims about the chapter's value.

### 2. Shared chapter foundation

The current implementation is still two chapter-specific controllers:

- `chapter_director.gd`: roughly 768 lines;
- `chapter_two.gd`: roughly 665 lines.

Before adding another full controller, extract or introduce shared components for:

- dialogue/advance and device prompts;
- verse-page and tappable-word flow;
- checklist/objective presentation;
- charm award and chapter-complete handoff;
- chapter cleanup/reset;
- environment activation;
- checkpoint save/resume.

Keep the extraction narrow. Do not rewrite working Chapter 1–2 behavior. Add regression coverage
around the existing chapters first, migrate one shared behavior at a time, and preserve old profile
files.

### 3. Progression and five-stop map

`profiles.gd` currently defines only `valley` and `camp`; `faith_journey_screen.gd` shows those two
plus one “Coming soon” stop. Before Chapter 3 can be selected:

- add a stable `beginning` chapter id without changing the two existing ids;
- append it to progression without deleting unknown/older saved data;
- replace the three-stop map data with the planned five stops;
- visually show Chapter 3 as a turned-back page while it remains the third playable stop;
- test old profiles with Chapter 1 only, Chapters 1–2, and repeated completions;
- keep Chapters 4–5 visible as locked previews until implemented.

### 4. Prepare the Welcome prototype

Build this with placeholder boxes before final props:

1. approach cushion/cup/lamp and press the normal context action;
2. the object floats visibly beside Wonder Light or the player;
3. the correct placement ring breathes and remains large enough for touch;
4. entering its generous area changes the button to **PLACE**;
5. placement auto-snaps over about 0.6 seconds with visual and sound confirmation;
6. objects can be placed in any order and never produce a wrong response;
7. idle hints and edge arrows prevent searching or placement stalls.

Test touch, keyboard and gamepad. Confirm that it feels like preparing a space rather than repeating
the Chapters 1–2 collection hunts.

### 5. Character and procession prototype

Before final models:

- build `jesse_sons.gd` with seven lightweight placeholders, idle glances and varied step timing;
- time the complete procession with temporary narration;
- build side-by-side Samuel, Jesse, younger David and current David reference sheets;
- prove younger David's walk, face continuity and close-up framing on the shared skeleton;
- confirm Samuel/Jesse do not resemble one another or make the neutral face appear stern;
- prove the oil-ribbon animation reads as anointing without a crown or magical glow.

### 6. Temporary audio before casting

Use temporary read-aloud for the whole prototype. Do not spend voice-generation credits until:

- the script and Easy Words pass are locked;
- the complete read-aloud playthrough fits 8–12 minutes;
- Samuel's “Yahweh has not chosen these” line reads as calm rather than dismissive;
- candidate Samuel and Jesse voices are distinct from Bram and each other;
- every final line id and exact text is stable in `vo_library.gd`.

## Recommended implementation sequence

### Milestone A — safe foundation

**Done on `feat/chapter-3` (2026-09-25), built on the refactored structure rather than the first
`feature/chapter-3` attempt:** the stable `beginning` id, played third (the ark moves to fourth, and a
save that already had the ark open keeps it), the five-stop map with Jesse's house inked in, the
1 Samuel 16:7 verse and the Faithful Heart charm with its colouring picture, Samuel and Jesse name tags,
and the courtyard as its own scene loaded by the shell, with its first lines as data. The "shared
chapter foundation" gate is met by the refactor: one shell starts, stops and switches every story,
looks and play areas are data, prompts are worded in one place (`device_prompts.gd`), lines are data
with their clips (`assets/dialogue/`), and every story cleans up after itself when freed.

- Add Chapter 3 ids and map data with save-compatibility tests.
- Add the Chapter 3 journal verse/charm data and placeholder charm art without requiring audio yet.
- Extract the smallest shared chapter behaviors, protected by Chapter 1–2 regression tests.
- Create an empty/lazy Chapter 3 environment that does not add cost while Chapters 1–2 run.

**Exit:** old profiles still unlock the same chapters, both existing chapters complete unchanged,
and a developer-only Chapter 3 stop can open and return safely.

### Milestone B — playable greybox

**Done on `feat/chapter-3` (2026-09-25).** The whole chapter plays from the first line to the end
card (`tests/beginning_review.gd`): the optional harp, bowl and cloak; Prepare the Welcome (carry the
cushion, cup and lamp one at a time to breathing rings in front of the table, any order, a ring only
takes its own thing, the golden arrow after 12 s); Samuel's arrival; the seven brothers
(`jesse_sons.gd`: idle glances and weight shifts, then out-hold-back in about nine seconds, on a
still camera); "Yahweh has not chosen these"; calling David home (CALL on a tablet); 1 Samuel 16:7
with God, Sees and Heart to tap; the anointing (David kneels, Samuel steps up and holds the horn
over his head, and a thin line of oil runs down onto it, a breeze, no glow); the reflection; the
Faithful Heart ceremony. Recorded voices (2026-09-26, `docs/voice-over.md`). The house's side wall,
the table, the olive trunk, the fence and the water jars are solid, and the brothers stand clear of
the walls. The courtyard is dressed and alive (`courtyard_life.gd`): water jars, a mat and a bread
basket under the awning, firewood, a low field-stone wall with bushes and a fig tree, wildflowers,
cloud shadows drifting over the ground and the people, leaves on the breeze, two doves circling and
two pecking, which flutter off when the child walks up. The ground is packed earth in soft patches,
with flagstones in front of the house and a trodden footpath to the table (2026-09-26).
People turn to whoever is speaking, and all look at the child for the reflection and the charm;
Samuel steps back from David after the anointing. Carrying a welcome thing, walking up to any side
of the table sets it on its place (the exact ring was too fiddly).
Not yet: resume after a reload mid-chapter (Play again restarts it), per-object placement sounds
beyond the three existing effects, and the family/tablet tests of Milestone C.

- Greybox the courtyard, house edge, table, fold and sheep path.
- Implement Prepare the Welcome with three placeholder objects.
- Implement seven brother placeholders, procession, idle life and skip-safe timing.
- Stage placeholder Samuel, Jesse and younger David with temporary lines.
- Add verse pages, observation-only anointing and placeholder Faithful Heart reward.

**Exit:** one complete 8–12 minute Chapter 3 playthrough works with touch, keyboard and gamepad,
uses no final paid voice or art, and can resume after pause/reload at major beats.

### Milestone C — story and family validation

- Test value comprehension, placement clarity, procession pacing, anointing meaning and verse
  readability with families on a real tablet.
- Revise the activity and script before commissioning final assets.

**Exit:** a child can proceed without reading, understands that God sees the heart, and does not
describe the charm or David's ordinary work as the reason he earned selection.

### Milestone D — production assets

**Characters done early, by the owner's decision (2026-09-25):** Samuel, Jesse and the younger
David are rigged Blender models on the shared skeleton
(`art/blender/scripts/characters/generate_bethlehem_people_v1.py`), with Blink and Talk, driven
by `story_person.gd` (breath, blink, talk, gesture, walk, kneel; Samuel's arm lifts the horn).
Voices are recorded (Juno, Gideon, Desmond, Bram). Charm art polish, soundscape and foley are still
to come.

- Generate and review Samuel, Jesse and younger David models.
- Add final courtyard props, charm art, motion, soundscape and licensed foley.
- Cast and record Samuel/Jesse plus all standard/Easy Words lines.
- Add repeatable visual captures and Chapter 3 automated flow checks.

## Start decision

Development can start now with **Milestone A**, followed by the greybox in **Milestone B**. Do not
start by generating the three final hero characters or recording the 30–32 final voice clips. The
foundation and prototype will expose save, pacing and interaction problems while those changes are
still inexpensive.
