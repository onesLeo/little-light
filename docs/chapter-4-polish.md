# Chapter 4 — Polish checklist

Companion to [chapter-4-concept.md](chapter-4-concept.md). How each thing should move and sound so nothing reads as a statue, a conveyor belt or a weather slideshow. Reuse `chapter_two_character_motion.gd`, `lamb_life.gd`, `camp_owl.gd`, `camp_guard.gd` turn-and-walk, the valley-to-camp lighting crossfade, and the stream water shader.

## Implemented story polish (September 2026)

- Boarding follows the ramp and waits for the last family member before closing the door.
- Rain cuts to an open-front timber shelter with the family, resting animals, a warm lamp
  and rain outside the window. A separate render layer isolates the cutaway.
- Building, storm, waiting and new morning use distinct lighting. Crossfades replace unfinished
  transitions; turning the sky also lowers the water outside the shelter window.
- The dove follows a curved flight with wingbeats and a landing settle. Repeated SEND presses
  cannot overlap flights, and pausing freezes the flight and camera motion.
- The olive sprig gets a close view and its own recorded line. NEXT reveals morning and the
  family emerging; the next NEXT reveals the rainbow in a wide shot with Genesis 9:13.
- Existing recorded lines are retained. Movement is locked during the shelter/window scenes.

Run `tests/ark_review.gd` headlessly for progression checks. For rendered captures, run it without
`--headless` and append `-- --capture-ark`; images go to `.godot/ark-visual-review/`.
The broader art ambitions below remain a checklist, not a claim that every detail is finished.

## Models — humans

- **Noah** is a workman, not a prophet on a stick: rust over cream, dark belt, full grey-brown beard thicker than Samuel's. Hands stay connected to the arms (Wonder-Walker v13). One shape key for measuring / resting a palm on wood. Closed default smile, tired and steady, never smug. Thin outline hull.
- **Noah's wife** is the first real female body in the pipeline — new proportions, not a recolour of David. Hair tied back. Teal and sand. Same `Blink` / `Talk` keys as Noah.
- **Three sons and three wives** (six crowd figures, not six sons): camp-guard tier, no face rig. Vary cloth, hair and job. Never stand in a parade line.
- Do not polish eight hero faces.
- Wonder-Walker is a guest. He does not walk the ramp or stand in the family silhouette when the door closes.

### Human model acceptance

- **Silhouettes must separate before colour does.** At normal gameplay size, Noah reads through
  beard, broader work stance and belt; his wife through tied-back hair, posture and garment shape.
  Clothing colour supports identity but cannot be the only difference.
- **Connected anatomy:** shoulders flow into upper arms, elbows visibly bend, wrists meet the hand,
  and knees sit inside the robe silhouette. No spherical joint gaps or hands hovering beside cuffs.
  Test the measuring pose, one-handed talk gesture and walk at the Chapter 2 close-up distance.
- **Eyes:** shallow paper-set eyes, relaxed upper lids, small catchlights and brows separated from
  the eye shape. Reuse the Jonathan lesson: no protruding spheres or inward-sloping brows that make
  a neutral face look angry. Blink lids close over the eye instead of shrinking the eyeball.
- **Face at rest:** closed, slight smile; mouth opens only while talking and returns softly rather
  than snapping. Noah may look tired through eyelid and shoulder pose, never through a permanent
  frown.
- **Hands:** one relaxed open pose plus the measuring/resting-on-wood pose. Fingers need only read
  as a joined paper mitten at gameplay scale, but the palm must visibly contact the timber.
- **Feet and shadows:** both feet remain on the ground through idle/listen poses. A soft contact
  shadow must stay under each character; vertical breathing cannot make them float.
- **Close-up gate:** approve front, three-quarter, side, talk, blink and one-hand gesture stills
  before recording voice. A shape or rig problem is cheaper to fix before clips and cameras are
  authored around it.
- **Noah's wife:** distinguish her with authored proportions, face, tied-back hair and work motion,
  without exaggerated adult body shapes. She should read as a capable partner at the same visual
  importance as Noah in her spoken beat.

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

Relative scale: rabbits are smallest; sheep and goats share the middle range; giraffes are tallest;
elephants carry the greatest body mass. If the tablet hitches, use the optimization order below
before reducing the large animals to flat boarding cutouts.

Correct the fallback order before flattening a hero animal: first reduce outline hull detail, shadow
casting, material count and far-idle update rate; then use a low-detail distant version. Elephants
and giraffes are the strongest scale cues in the procession, so a flat cutout is the last fallback,
not the first optimization.

### Animal model and motion language

| Pair | Waiting life | Guided/boarding motion | Meeting its mate |
|---|---|---|---|
| Sheep | slow chest breath, ear flick, tiny chew | short four-beat walk, wool body settles | nose turn and one soft bleat |
| Goats | ear turn, brief hoof shift | slightly quicker, firmer steps; small head bob | both heads lower gently, never butt |
| Rabbits | nose twitch, asymmetric ear turn, occasional sit-up | two small hops and settle rather than sliding feet | face one another and lower ears |
| Doves | blink, head tilt, one peck/preen | short wing-assisted hop/glide, feet fold and extend | perch close and alternate head tilts |
| Elephants | slow ear fan, trunk curl, weight shift | heavy alternating walk with planted feet; trunk counter-swings | trunks lift toward one another without tangling |
| Giraffes | slow blink, tail swish, neck look | long restrained stride; neck counters the body bob | small mirrored neck lean, not a large bow |

Keep eyes, feet and harmless species features readable at normal camera distance. Horns, tusks and
beaks are rounded paper shapes. No teeth, claws, threat pose or realistic predator detail.

## Movement — humans

Short lines look more robotic if the body is still. Drive Noah and his wife from `chapter_two_character_motion.gd`: `breath()`, `listening_nod()`, `speaking_pulse()`.

- Always: slow breath, offset per person.
- Listening: a small nod, not a bow.
- Speaking: one leading hand (Jonathan's fix). Two-arm lifts read as robots.
- Noah extra: measure the hull, rest a palm on a rib, then return.
- Wife extra: glance at the ramp or an animal, then back to the child.
- Crowd: cheap breath plus a two- or three-pose work cycle, start time randomized.

Use explicit motion states rather than adding sine waves indefinitely:

1. **Idle:** breathing, rare blink and one gaze target.
2. **Work:** lift/place/rest cycle tied to a real prop; hands meet the basket, rope or timber.
3. **Listen:** body quiets, eyes/head track the speaker, one restrained nod near the end.
4. **Speak:** mouth plus one asymmetric hand lead; listener continues subtle breath and gaze.
5. **Walk:** feet plant, hips translate and arms counter-swing; stop pose blends over a few frames.
6. **React:** one authored glance toward the finished panel, arriving animals, first rain or rainbow.

The gaze target matters as much as the gesture. Noah looks at the child while speaking, at the panel
while measuring, and toward his wife/animals when listening. His wife looks at the current pair or
ramp before giving guidance, then returns to the child. Nobody stares through the camera.

Randomize phase and cycle choice per background figure, not merely speed. Two workers may share a
rig but should not lift baskets or turn their heads on the same frame. During close dialogue, reduce
background work amplitude rather than freezing everybody.

Motion limits: no shoulder rise that reaches the ears, no elbow hyperextension, no head rotation
beyond a comfortable glance, and no root bob large enough to detach feet from the floor. Blend back
to rest after every gesture so an arm never remains stuck in its speaking pose.

## Movement — animals

Waiting animals are this chapter's rigidity trap. Per animal, cheap and desynced: breath like `lamb_life.gd`, occasional head turn, ear flick or tail swish, dove blinks from `camp_owl.gd`.

Walk is not a slide: turn, quadruped leg phase, arrive and settle. Stagger ramp boarding. The current
guided pair uses full-detail gait and reaction; distant montage pairs may use a cheaper walk cycle.
Press **GUIDE**; the match happens at the partner, not by bumping.

Each animal moves through **WAITING → NOTICE → FOLLOW → MEET → BOARD → REST**. The button press must
produce an immediate response: the animal looks at the child, gives one small acknowledgement and
starts following within about half a second. At the partner, both animals react before boarding so
the successful match reads without relying on the checklist tick.

- Keep at least two feet visually planted during a walk; body travel, leg phase and foot contact
  must agree. Large animals should not bounce like the collectible lamb.
- Follow terrain height and ramp slope at every step. Feet may compress slightly into paper ground,
  but must not float above it or clip through the ramp.
- Use a wide turn radius for elephant and giraffe. If the route is blocked, pause and re-route rather
  than rotating in place through another animal.
- Give each pair its own idle seed. Avoid simultaneous blinking, tail motion, calls or breathing.
- Distant waiting pairs use lower-frequency idle updates. The current guided pair and its mate keep
  full motion; this focuses attention and protects the tablet budget.
- Inside the cutaway, show slow breathing, a head settling onto straw and a dove folding its wings.
  Do not freeze the animals as soon as the door closes.

## Scenery and ark

Build one playable hull strip, not a tourable ship. Repeated ribs, wide planks, ink seams. Work area off the animal path. Ramp wider than Chapters 1–2. Waiting circles and water bowls, never cages. Window on the wall the tabletop camera already faces. Cutaway is a simpler set: amber beams, baskets, straw, alcoves. Finished panel shifts from raw timber to sealed wood.

Greybox that strip with three blob animals and the owl-as-dove before generating Noah.

### Ark construction and environmental life

The ark needs visible cause and effect, not only a finished model swap:

- Start the playable panel with three empty peg holes, a slightly lifted plank edge and loose rope.
- Each peg auto-snaps, gives a short wood response and visibly closes part of the plank gap.
- Rope pull one aligns the panel; pull two tightens the knot and settles the whole panel once.
- Sealed wood becomes slightly darker and less chalky. Do not use a glossy “completed” glow.
- Nearby Noah places his palm on the panel after completion and the hull gives one quiet creak. The
  creak is motivated by visible contact.

Keep the world working around the child: one family member carries a basket, another checks a rope,
cloth and rope ends respond to wind, a water-bowl surface ripples after an animal drinks, and dust
settles after a pair walks past. Choose two or three of these at once; every prop moving together
would be as artificial as a frozen scene.

The hull must communicate scale without blocking play:

- use repeated ribs and shadows to lead the eye upward, with the top allowed to leave frame;
- keep the active panel and ramp brighter than decorative ribs;
- simplify collision to broad planes rather than every plank seam;
- keep the ramp edge visually distinct from the ground and wide enough for child plus animal;
- prevent the hull, family figures and large animals from occluding the player or the active mate;
- place an invisible camera-safe boundary before the child can walk underneath the cutaway wall.

The rain cutaway is a staged cross-section, not an explorable second level. Change to it through one
clear paper-page transition so the child understands that time and viewpoint changed.

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

### Situation staging checks

| Beat | Camera and control | Life that must continue |
|---|---|---|
| Arrival | low wide reveal, then return control promptly | Noah works, family crosses mid-ground, rope/cloth moves |
| Tools | normal follow camera and visible checklist | distant work continues; first tool has a small material/shape cue |
| Meet | medium close-up; look-around allowed, walking locked | Noah talks; wife listens/works softly; background amplitude lowers |
| Panel | camera frames hands, peg holes and rope together | Noah watches and reacts; hull/rope responds to each action |
| Two by Two | tabletop follow on active pair, not a view of all twelve | inactive waves breathe/turn; correct mate answers the guided animal |
| Door | warm interior view, no player action | family settles, animals breathe, narrowing light stays gentle |
| Rain | stable cutaway and optional NEXT after narration starts | roof drips, restrained hull rock, loose basket cloth sways |
| Dove | window and sill remain in one readable composition | bird blinks/folds wings; water and sky change only on NEXT |
| Morning | widest view with stable horizon | animals exit at varied cadence; rainbow reveals after verse begins |

Never take camera control during free movement without first stopping the player cleanly. Never
return control while the camera is still blending. Any cinematic longer than a spoken line exposes
NEXT, and pause/resume restores the exact beat rather than replaying a long transition.

## Weather

Three states on one space, crossfaded like valley-to-camp. Time passes only when the child turns the sky.

| State | Look | Motion |
|---|---|---|
| Building | Ochre ground, honey wood, pale sky | Dry breeze, dust motes |
| Rain | Slate paper sky, silver sheets, amber inside | Roof drips, slow hull rock, no lightning |
| New morning | Cream sun, little green, matte rainbow | Quiet puddle ripple, leaves lift |

Rainbow: wide paper bands over about two seconds. Not neon, not a sky laser.

### Weather transition choreography

- **Building → warning of rain (3–4 s):** breeze eases, cloth settles, light cools slightly and the
  first isolated roof taps arrive. No thunder sting or sudden black cloud.
- **Rain grows (5–7 s):** two or three broad paper rain layers fade in at different depths, roof
  drips begin and the cutaway interior warms by contrast. Prefer layered sheets/meshes over thousands
  of independent particles.
- **During rain:** hull rocking is slow and very small; hanging rope, baskets and animal bodies react
  at different amplitudes. The camera and horizon stay fixed so the room feels safe.
- **Time turn:** each NEXT advances sky colour, window light and water height together. Give the
  child one visible before/after state per page turn.
- **Rain → morning (4–6 s):** rain thins before it stops, drips remain, cool light becomes cream and
  puddles begin a low-cost ripple. Do not jump from storm to a fully dry green world.
- **Rainbow:** reveal matte bands in a slightly offset sequence over roughly two seconds, hold long
  enough to hear the verse, then settle to an almost still state. Avoid continuous pulsing.

Weather motion is never the only information. A child with sounds muted still sees the state change;
a child who cannot distinguish the palette still sees rain sheets, water level, window light and
the rainbow silhouette.

## Sound

Reuse `WIND`, `FLUTTER` and the ducked voice bus. Record rather than synthesise animal calls, rain, timber/straw footsteps, peg taps, rope pulls and hull creaks. Creaks only when the hull is visibly moving. One animal pair at a time, mute under dialogue.

Rain: roof taps, then a soft wash, then drop highs and level before every spoken line. Tablet-speaker test is mandatory. Rainbow: one warm chime, no fanfare. Log every CC0 clip in `assets/audio/CREDITS.md`.

### Sound implementation polish

- Give peg taps, timber steps, straw steps and creaks at least three short variants with small pitch
  variation. The same sample repeated six times will make the ark feel mechanical.
- Put local sounds on `AudioStreamPlayer3D`: peg at the panel, footstep at the walker, call at the
  animal and creak at the moving rib. Rain/music remain broad ambience.
- Limit animal calls to one pair at a time with randomized quiet gaps. A mate may answer the current
  guided animal once; the waiting area must never become a wall of zoo noise.
- Duck Music and Ambience for speech through the existing buses. Also suppress new animal calls and
  loud peg/rope transients until the spoken line finishes.
- Make the success tick, visible partner reaction and checklist animation arrive together. Sound is
  confirmation, never the only sign that a match worked.
- Crossfade rain loops at a zero crossing and audition the seam through headphones and a cheap
  tablet speaker. Listen for a rhythmic “reset” every loop.
- Keep the dove's wing flutter attached to takeoff/landing only; silence during the long glide makes
  it feel calmer and matches `camp_owl.gd`.
- Record a clean no-music/no-ambience pass of every spoken line for QA. If a line is unclear there,
  fix the voice clip before compensating with excessive volume.

Minimum audio review: full mix on a tablet at 50% device volume, voices-only, ambience-only, sound
muted, and read-aloud off. The chapter must remain understandable in all five passes.

## Verse and wording

Lock Genesis 9:13 to the World English Bible before recording:

“I set my rainbow in the cloud, and it will be a sign of a covenant between me and the earth.”

Do not record the NIV-like draft.

This wording is confirmed against the official [World English Bible Classic, Genesis
9:13](https://ebible.org/eng-web/GEN09.htm). Record and display the verse exactly; do not silently
replace *covenant* with *promise* inside the quotation.

- Split the verse across two pages if needed, then **RAINBOW / SIGN / PROMISE**.
- Gloss: “God's covenant is a promise God chooses to keep.”
- Rain line: “the animals with them,” not “every animal.”
- Name the brokenness once, after trust is named.
- Finished panel: paraphrase Genesis 6:22.
- Charm line: “Noah kept building before he could see the rain.”
- Speaker tag: **“Noah's wife.”**
- God stays Wonder Light plus scripture.

Presentation order:

1. **Reference:** “Genesis, chapter nine, verse thirteen.”
2. **Exact verse:** show at the established tablet font size across at most two pages and read the
   exact WEB text.
3. **Meaning:** move to a visibly separate Wonder Light panel: “God's covenant is a promise God
   chooses to keep.” This is explanation, not part of the quotation.
4. **Words:** **RAINBOW** and **SIGN** may use clean cuts from the verse recording; **PROMISE** must
   use the explanation recording because that word is not in Genesis 9:13 WEB.
5. **Reflection/charm:** connect trust to Noah building before he saw rain, then show the rainbow
   charm. Do not imply the charm or rainbow is a prize for completing the activity.

Keep the rainbow behind or above the verse panel, never crossing the letter shapes. The verse screen
is calm: no camera orbit, animal crossing, repeated chime or animated band behind the text. Easy
Words may shorten the explanation, but must keep the exact Scripture quotation labelled separately.

## Build order

1. Greybox hull strip, three blob animals, owl-as-dove, rain ducking on a tablet.
2. Idle-life on those animals so the waiting area is never frozen.
3. Noah and his wife on `chapter_two_character_motion.gd` with a one-handed talk gesture.
4. Weather crossfade and sequenced rainbow bands.
5. WEB verse, Easy Words, and RAINBOW / SIGN / PROMISE.
6. CC0 rain and animal calls, then voice presets.

## Definition of polished

- [ ] Noah and his wife pass front/three-quarter/side, blink, talk, hand-contact and foot-contact
  review at dialogue distance.
- [ ] Every human has idle, listen, speak/work and recovery motion; no two background figures share
  the same phase and action start.
- [ ] Every animal pair has distinct waiting, guided, meeting, boarding and resting motion with no
  floating feet, sliding body or synchronized idle loop.
- [ ] The active panel visibly changes after every peg and rope pull; sound and motion originate at
  the affected object.
- [ ] Player, animals and camera never clip through the hull, ramp, cutaway or one another during a
  full automated boarding run.
- [ ] Weather transitions crossfade without a hard lighting jump, sudden loud rain, camera shake or
  frame-time spike on the target tablet.
- [ ] Dialogue remains clear over rain at 50% tablet volume, and no animal call overlaps speech.
- [ ] Genesis 9:13 matches the WEB source exactly; explanation and Easy Words are visually separate
  from the quotation.
- [ ] The entire waiting area remains alive for a 30-second observation without looking frozen or
  synchronized.
- [ ] A complete read-aloud playthrough stays inside 8–12 minutes and resumes correctly after pause
  or app interruption at each major beat.
- [ ] Review stills exist for arrival, Noah, Noah's wife, panel stages, each animal species, door,
  rain cutaway, dove return, morning and verse/charm.
