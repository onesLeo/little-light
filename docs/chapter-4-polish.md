# Chapter 4 — Polish checklist

Companion to [chapter-4-concept.md](chapter-4-concept.md). How each thing should move and sound so nothing reads as a statue, a conveyor belt or a weather slideshow. Reuse `chapter_two_character_motion.gd`, `lamb_life.gd`, `camp_owl.gd`, `camp_guard.gd` turn-and-walk, the valley-to-camp lighting crossfade, and the stream water shader.

## Models — humans

- **Noah** is a workman, not a prophet on a stick: rust over cream, dark belt, full grey-brown beard thicker than Samuel's. Hands stay connected to the arms (Wonder-Walker v13). One shape key for measuring / resting a palm on wood. Closed default smile, tired and steady, never smug. Thin outline hull.
- **Noah's wife** is the first real female body in the pipeline — new proportions, not a recolour of David. Hair tied back. Teal and sand. Same `Blink` / `Talk` keys as Noah.
- **Three sons and three wives** (six crowd figures, not six sons): camp-guard tier, no face rig. Vary cloth, hair and job. Never stand in a parade line.
- Do not polish eight hero faces.
- Wonder-Walker is a guest. He does not walk the ramp or stand in the family silhouette when the door closes.

## Models — animals

Paper-blob language, not zoo realism. One shared build per pair plus a look flag (ear angle, patch side).

| Pair | Polish focus |
|---|---|
| Sheep | Reuse the lamb blob; only wool tint / patch changes |
| Goats | Leaner body and small horn blobs so they do not read as sheep |
| Rabbits | Smaller scale and long ears |
| Doves | Owl flight rig, smaller, lighter colour |
| Elephants | Trunk as a tapered profile that can sway |
| Giraffes | Neck as a chain that can nod; patches in the material |

Relative size: rabbit < sheep < goat < giraffe neck < elephant body. If the tablet hitch, drop elephants and giraffes to flat boarding cutouts.

## Movement — humans

Short lines look more robotic if the body is still. Drive Noah and his wife from `chapter_two_character_motion.gd`: `breath()`, `listening_nod()`, `speaking_pulse()`.

- Always: slow breath, offset per person.
- Listening: a small nod, not a bow.
- Speaking: one leading hand (Jonathan's fix). Two-arm lifts read as robots.
- Noah extra: measure the hull, rest a palm on a rib, then return.
- Wife extra: glance at the ramp or an animal, then back to the child.
- Crowd: cheap breath plus a two- or three-pose work cycle, start time randomized.

## Movement — animals

Waiting animals are this chapter's rigidity trap. Per animal, cheap and desynced: breath like `lamb_life.gd`, occasional head turn, ear flick or tail swish, dove blinks from `camp_owl.gd`.

Walk is not a slide: turn, quadruped leg phase, arrive and settle. Stagger ramp boarding. Only the guided pair uses a full walk. Press **GUIDE**; the match happens at the partner, not by bumping.

## Scenery and ark

Build one playable hull strip, not a tourable ship. Repeated ribs, wide planks, ink seams. Work area off the animal path. Ramp wider than Chapters 1–2. Waiting circles and water bowls, never cages. Window on the wall the tabletop camera already faces. Cutaway is a simpler set: amber beams, baskets, straw, alcoves. Finished panel shifts from raw timber to sealed wood.

Greybox that strip with three blob animals and the owl-as-dove before generating Noah.

## Situations

1. Arrive — bright dry plain, no storm cloud.
2. Tools — first item already in frame. Pitch is “sticky pitch that keeps water out.”
3. Meet — Noah faces the child before the camera cuts in.
4. Panel — three snapping pegs, two rope pulls that click tighter in steps.
5. Two by Two — waves, not twelve at once. Child guides three; three board in a montage.
6. Door — from inside. God closes it. The child does not.
7. Rain — stable cutaway, no shake. Rain on the paper roof only.
8. Dove — “came back safe,” then **TURN THE SKY**. Leaf return gets a small pause and glow.
9. Morning — one sprout, one olive, rainbow bands one at a time.

## Weather

Three states on one space, crossfaded like valley-to-camp. Time passes only when the child turns the sky.

| State | Look | Motion |
|---|---|---|
| Building | Ochre ground, honey wood, pale sky | Dry breeze, dust motes |
| Rain | Slate paper sky, silver sheets, amber inside | Roof drips, slow hull rock, no lightning |
| New morning | Cream sun, little green, matte rainbow | Quiet puddle ripple, leaves lift |

Rainbow: wide paper bands over about two seconds. Not neon, not a sky laser.

## Sound

Reuse `WIND`, `FLUTTER` and the ducked voice bus. Record rather than synthesise animal calls, rain, timber/straw footsteps, peg taps, rope pulls and hull creaks. Creaks only when the hull is visibly moving. One animal pair at a time, mute under dialogue.

Rain: roof taps, then a soft wash, then drop highs and level before every spoken line. Tablet-speaker test is mandatory. Rainbow: one warm chime, no fanfare. Log every CC0 clip in `assets/audio/CREDITS.md`.

## Verse and wording

Lock Genesis 9:13 to the World English Bible before recording:

“I set my rainbow in the cloud, and it will be a sign of a covenant between me and the earth.”

Do not record the NIV-like draft.

- Split the verse across two pages if needed, then **RAINBOW / SIGN / PROMISE**.
- Gloss: “God's covenant is a promise God chooses to keep.”
- Rain line: “the animals with them,” not “every animal.”
- Name the brokenness once, after trust is named.
- Finished panel: paraphrase Genesis 6:22.
- Charm line: “Noah kept building before he could see the rain.”
- Speaker tag: **“Noah's wife.”**
- God stays Wonder Light plus scripture.

## Build order

1. Greybox hull strip, three blob animals, owl-as-dove, rain ducking on a tablet.
2. Idle-life on those animals so the waiting area is never frozen.
3. Noah and his wife on `chapter_two_character_motion.gd` with a one-handed talk gesture.
4. Weather crossfade and sequenced rainbow bands.
5. WEB verse, Easy Words, and RAINBOW / SIGN / PROMISE.
6. CC0 rain and animal calls, then voice presets.
