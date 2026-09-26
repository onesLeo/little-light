# Chapter 5 — where the build stands

Jonah and the Great Fish ([chapter-5-concept.md](chapter-5-concept.md)) is playable from Joppa to
the Mercy charm, built the Chapter 3 way: the story is data and code on the shared shell, the world
is paper parts in code, and a review test plays every beat.

Decided on 2026-09-26: same scope as Chapter 3 (greybox plus final characters and recorded voices),
the verse is **Jonah 2:2** (WEB, checked against [ebible.org](https://ebible.org/eng-web/JON02.htm),
shown without its opening "He said,"), and Nineveh has no voice of its own: Wonder Light tells what
the city did. New voices only for Jonah and the Captain.

## What is in

| Area | Where |
|---|---|
| Story, 11 beats, resume at 8 of them | `scripts/chapter_five.gd`, lines in `assets/dialogue/jonahs_journey.tres` |
| Four places, one shown at a time, page-turn between | `scripts/jonahs_journey.gd` (Joppa, the ship, the deep, the land) |
| Sea, storm, rain; Calm motion setting | `scripts/jonah_sea.gd`, `GameSettings.reduced_motion` ("Calm motion" in the pause menu) |
| The great fish (soft paper blobs, no teeth) | `scripts/great_fish.gd` |
| Nineveh's families, cross-fading poses | `scripts/nineveh_crowd.gd` |
| The shade plant, growing and folding | `scripts/shade_plant.gd` |
| Map stop 5, verse, Mercy charm, speaker tags | `map_ship_sketch.gd`, `journal_content.gd`, `charm_art.gd`, `dialogue_view.gd` |
| Review test | `tests/jonah_review.gd` |

The child never throws Jonah and never steers: Jonah walks to the ship's side and a great wave hides
him while the storm eases on the same timeline. The sea's beats and the prayer carry on by
themselves if the child stops tapping.

## Still to do

- Jonah's own Blender model (for now he and the sailors are the tinted brother models).
- Recorded voices for Jonah, the Captain and Wonder Light (the system voice reads them until then).
- Harbour, storm, deep and market sound beds.
- Playtests from the concept's improve pass: the fish silhouette and the storm with children and
  motion-sensitive adults, and a Bible-story review of the script.
