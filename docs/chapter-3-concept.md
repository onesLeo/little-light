# Chapter 3 — The Beginning

This is the next planned journey after The King's Camp. It is a deliberate look backward: Wonder
Light turns to an earlier page and shows how David's public story began, when Samuel came to
Bethlehem and anointed the youngest son of Jesse. The chapter is not built yet.

Implementation readiness and the required build order are tracked in
[chapter-3-readiness.md](chapter-3-readiness.md).

## Where chapter 2 leaves off

Chapter 2 ends with Jonathan and David joined in friendship at the king's camp. The child has earned
Courage and Friendship. From the Faith Journey, the path curls backward like a turned paper page.
Wonder Light says, "You know David the shepherd and David the friend. Now let us see where his
journey began."

This makes the non-chronological order explicit. The chapter is a remembered beginning, not an event
that happens after Jonathan's gifts.

## The story: Samuel anoints David

**Bible passage:** 1 Samuel 16:1–13.

God sends Samuel to Jesse's home in Bethlehem. Jesse's seven older sons pass before Samuel, but none
is the one God has chosen. Samuel learns that people look at outward appearance, while God looks at
the heart. David is still outside caring for the sheep. Jesse sends for him, Samuel anoints him, and
the Spirit of the Lord comes powerfully on David.

**Recommended value:** Faithfulness. David is doing quiet, ordinary work when nobody expects him to
be called. Faithfulness gives the child something they can practise: care for what has been placed in
front of you, even when nobody is applauding.

The story must not claim that David earned God's choice by being good enough. The direct truth of the
passage remains the centre: **God sees the heart.** "Faithful Heart" is the child-facing charm name.

**Verse:** 1 Samuel 16:7 (WEB), verified against the official World English Bible Classic:
“But Yahweh said to Samuel, ‘Don't look on his face, or on the height of his stature, because I have
rejected him; for I don't see as man sees. For man looks at the outward appearance, but Yahweh looks
at the heart.’” Keep the child-friendly explanation separate from the quotation.

**New charm:** Faithful Heart. A small heart-shaped lamp with one steady flame, readable at journal
size. The flame means quiet faithfulness; it is not a magical sign that some hearts are better than
others.

## The story, and what the child does

1. **Turn back the page.** The Faith Journey folds from the blue-hour camp into a warm Bethlehem
   morning. Wonder Light clearly names this as an earlier day.
2. **Explore Jesse's hillside home.** David is away with the sheep. His small harp, the water bowl
   for the sheep and his simple shepherd's cloak are optional discoveries in the courtyard. Wonder
   Light comments on each one, but they are not a second checklist and do not gate the story.
3. **Prepare the welcome.** Place a cushion, a cup of water and an oil lamp for Samuel. Each object
   snaps gently into a clear silhouette; there is no wrong placement or timer.
4. **Meet Samuel and Jesse.** Jesse's seven older sons pass before Samuel. They are presented with
   dignity. Nobody is mocked for being tall, strong or older.
5. **Call David home.** A soft bell or Wonder Light guides the child's gaze toward the sheep path.
   David enters from the field.
6. **Hear the Word.** Wonder Light reads 1 Samuel 16:7 and explains in easy words:
   "People notice the outside first. God sees who you are inside."
7. **The anointing.** Samuel performs it. The child watches rather than pouring the oil or choosing
   the king. A narrow gold ribbon of oil and a warm breeze make the moment readable without turning
   it into magic.
8. **Receive the Faithful Heart charm.** The reflection connects David's ordinary work to a child's
   small acts of care without claiming that David earned God's choice.

## Band

The chapter targets Band A first. The story contains names and an abstract idea, so the spoken line,
camera and staging must carry the meaning without relying on reading.

Band B may later add one reflection choice: "What can people see?" and "What can God see?" Both lead
to the same explanation. It must not become a quiz where a child can answer the Bible verse wrongly.

## Where it happens

This is Bethlehem, but not Chapter 1's open valley. Jesse's home sits on a low hillside above a
small sheep fold. The familiar distant ridge and olive shapes quietly connect it to David's valley.
The chapter should feel like a page from the same book, several years earlier.

The playable space is one compact courtyard with three readable edges: the house wall and shaded
door, the family table under an olive tree, and the sheep path arriving from the hills. The seven
brothers line one side without blocking the path.

## What carries over as-is

- The Wonder-Walker, Wonder Light, touch controls, checklist, profiles and Faith Journal.
- The tabletop and dialogue camera systems.
- David's face, colour family and paper material, adapted to a slightly younger model.
- The verse interaction, charm ceremony, colouring screen and end card.
- The low-poly paper style, ink outline and fail-free interaction rules.

## What is new work

- A Bethlehem courtyard environment (runtime paper-prop construction, the way `kings_camp.gd`
  builds the ridge — see **Asset inventory** below) and a five-stop Faith Journey map state
  (tracked separately as backlog 7.8).
- Three new rigged character models (Samuel, Jesse and younger David) built from the shared
  Wonder-Walker/Jonathan rig, and one new shared low-cost crowd rig instanced seven times (the
  brothers). The current adult David mesh is rigless, so a shape key alone cannot give younger
  David the natural walk-in this scene needs — see **Asset inventory**.
- Eleven new small paper props: harp, water bowl, cloak, cushion, cup, oil lamp, Samuel's oil
  horn, the welcome table, the house wall and doorway, the awning, and the sheep-fold fence.
  Background sheep reuse the existing lamb/companion-sheep mesh.
- A Prepare the Welcome activity: a new "place, don't just collect" interaction (no equivalent
  exists yet — see **Prepare the Welcome, in detail**).
- A short processional system for the seven brothers and David's entrance (see **The seven
  brothers, staged**).
- Faithful Heart journal art and a 3D charm (`journal_content.gd`'s `MYSTERY_SLOTS` already
  budgets for this: 3 earned charms + 2 mystery slots = 5, matching the five-journey roadmap, so
  no journal layout change is needed beyond the new entry).
- Two new voice profiles (Samuel, Jesse) and roughly 30-32 new recorded clips, including their Easy
  Words duplicates — see **Voice design** and **Draft script**.
- New morning ambience and interaction sounds. Tonal cues can use the procedural pipeline in
  `tools/make_sounds.py`; natural footsteps, birds and object foley should use credited CC0 source
  recordings when synthesis does not sound convincing, following the existing lamb/footstep rule.
- Two new entries in the "who is talking" name tag (`dialogue_view.gd`) for Samuel and Jesse — see
  **Who is talking**.
- Idle-life and secondary-motion work beyond the base rigs and props: crowd idle glances for the
  brothers, conversational nods/gestures for the three speaking characters, breathing placement
  rings, an unfurling oil ribbon, ambient doves and cloth sway for Samuel/Jesse — see **Animation
  and motion polish**. None of it is a new technique, but all of it is easy to omit unless it is
  planned in from the start.

## Asset inventory: models, rigs and props

The codebase already has two different ways to build a character, and this chapter should use
both rather than defaulting to the expensive one for everyone.

**Tier 1 — rigged, shape-keyed, camera-ready (the Wonder-Walker/Jonathan pipeline).**
`jonathan_v1.glb` uses the shared Wonder-Walker skeleton, then changes hair, sash, materials and
face proportions and adds `Blink`/`Talk` shape keys for the dialogue camera. The current
`david_mentor_v13.glb` is a joined, rigless mesh with a `Crouch` shape key; it can pose in place but
does not contain the natural walk cycle this chapter needs. This tier is for anyone the child sees
walking or speaking in close-up:

- **Samuel** — a new `generate_samuel_v1.py` wrapping the same base build. New geometry: short
  grey textured hair (a capped, not swept-long, hair mesh — closer to David's own hair shape than
  Jonathan's), a short grey beard, a cream outer / muted-blue under robe pair (reuse the two-layer
  cloth approach `Tunic`/`Sash` already gives Jonathan), a plain walking staff (already exists as
  a prop primitive — the camp guards carry one), and a new small oil-horn prop. `Blink` and `Talk`
  shape keys, same as Jonathan.
- **Jesse** — a second `generate_jesse_v1.py`, same base build. New geometry: a warm brown/olive
  robe palette, a somewhat heavier torso profile (sturdy, older), and short greying hair with no
  beard change needed if a plain hair cap reads as "father" clearly enough — confirm in the
  side-by-side sketch pass (Improve-pass item 4). `Blink`/`Talk` shape keys.
- **Younger David — a new rigged variant, not a reshape of the adult GLB.** Build him on the same
  skeleton as Jonathan, then match the current David's face language, skin, robe palette and ink
  outline closely enough to be immediately recognisable. Shorter proportions, rounder cheeks and
  shorter hair make the age difference clear. Give him `Blink`/`Talk` and a restrained walk cycle;
  reuse the existing David framing only after a side-by-side camera check.

**Tier 2 — lightweight, unrigged, crowd-ready (the camp-guard pipeline).** The four King's Camp
guards (`scripts/camp_guard.gd`) are not GLB models at all: a pure-GDScript pivot hierarchy built
from `camp_paper.gd` primitives (capsule legs, sphere head, box cape), animated with simple
rotation math for the walk cycle, with no bones and no face rig. Visual variety across the four
guards comes from indexing into three small colour arrays (`CLOTH`, `CAPE`, `SKIN`) by a `look`
parameter, not from four separate builds. This is the right tier for the brothers:

- **The seven brothers — one shared script, not seven models.** A new `jesse_sons.gd`, built the
  same way as `camp_guard.gd`: one pivot-hierarchy body, a `look` index (0-6) into small
  `TUNIC`/`SKIN`/`HAIR` colour arrays and a `height_scale` array (say 0.94-1.08) so the seven read
  as a family without being clones or needing seven face rigs. No shape keys, no speaking
  animation — they don't need `Talk`, since no brother has an individual line (Band A design,
  confirmed in **Voice design**).

**New paper props (all `camp_paper.gd`-style primitives, the same tier as the camp's tents, fire
and flags — not GLB assets):**

| Prop | Built from | Reuses |
|---|---|---|
| Harp | An angled low-poly frame plus 5 thin cylinder strings | `camp_paper.gd` primitives |
| Water bowl | A shallow cylinder cap with a flat disc "water" surface | — |
| Shepherd's cloak | A folded box, the same icon language as the robe gift in Chapter 2 | `gift_checklist.gd`'s "Robe" drawing, adapted |
| Cushion | A rounded box | — |
| Cup | A small cylinder | The belt/cup proportions already used for camp props |
| Oil lamp | A shallow cylinder base + one small flame shape | `Paper.flame()`, already built for the campfire |
| Samuel's oil horn | A tapered capsule | — |
| Welcome table | A box top on four cylinder legs | — |
| House wall + doorway | A flat panel with a darker doorway inset | The tent-wall panel approach in `camp_paper.gd` |
| Awning | A cloth quad on the wind shader | Chapter 2's `FLAG_SHADER`, reused directly for cloth lift |
| Sheep-fold fence | A row of thin cylinder posts and rails | — |

**Reused as-is, zero new cost:** the cypress/olive tree builder and ground/rock variants already
in `kings_camp.gd`/the valley pack, and the lamb/companion-sheep mesh for the two or three
background fold sheep (non-interactive, so no new collision or pickup logic).

So the honest count for "how many models": **3 new rigged character models** (Samuel, Jesse and
younger David), **1 shared crowd rig** instanced 7 times, and **11 new small procedural props** —
no new environment GLB, following Chapter 2's
precedent of building the space at runtime rather than importing a sculpted terrain.

## How it looks

The whole chapter uses warm early-morning colour: pale limestone, dusty rose, olive green and clear
cream sunlight. Chapter 2 was blue with one warm fire; Chapter 3 is warm everywhere but still quiet.
It should resemble a remembered morning, not a royal coronation.

### The first view

The camera opens behind the Wonder-Walker at the courtyard entrance. The eye should land in this
order:

1. Samuel approaching with his walking staff and small oil horn.
2. Jesse welcoming him beside the low table.
3. Seven brothers forming a loose line in the shade.
4. The empty sheep path at the bright edge of the courtyard.
5. David's harp resting where the child can discover it.

No crown, throne, palace or army appears. The visual question is "Who is missing?"

### Colour and light

| What | Colour and treatment | Purpose |
|---|---|---|
| Sky | Pale clear blue with warm cream near the horizon | Earlier and gentler than Chapter 1 noon |
| House | Matte limestone and clay, dark ink edges | Plain family home, not a palace |
| Ground | Warm sand with a worn rose-brown path | Keeps the walking route obvious |
| Olive tree | Muted green with small silver leaf faces | Familiar Bethlehem continuity |
| Family clothing | Ochre, clay, olive, cream and muted blue | A group without looking uniform |
| Samuel | Cream outer robe, muted blue under-robe | Readable as a visitor and spiritual elder |
| David | Familiar golden-brown tunic and olive sash | Immediately recognisable as younger David |
| Anointing | Thin warm-gold ribbon and a soft cloth flutter | Sacred and clear without spectacle |

### Characters

**Samuel.** An older man with a calm, observant face, grey textured hair and a short grey beard. His
body uses the same connected-limb construction as the polished David model, with soft shoulders and
natural elbows. He wears a cream robe over muted blue, simple sandals, and carries a plain walking
staff. His small oil horn hangs at his side. No ornate mitre, glowing eyes or priestly costume copied
from a later historical period.

**Jesse.** A sturdy older father in warm brown and olive. His posture is welcoming but slightly
formal because an honoured guest has arrived. His face must not become cruel when he forgets to call
David; he is focused on the sons already in front of him.

**The seven brothers.** Seven figures must be present because the passage says seven passed before
Samuel. They can share one lightweight rig and material set, with varied height, hair, tunic colour
and stance. Each steps forward once and returns to the group. They do not sneer, shove David or look
foolish. Their purpose is to show that outward impressiveness is not God's measure.

**Younger David.** Clearly the David from Chapters 1 and 2, perhaps a little shorter with a rounder
young face and slightly shorter hair. His proportions and connected limbs should match the polished
David standard. He arrives dusty from the sheep field, curious rather than posing heroically. He has
no crown and does not suddenly stand like a king after the oil is poured.

**Wonder-Walker and Wonder Light.** Unchanged. Wonder Light does most of the explanation so Samuel's
spoken lines can remain short and weighty.

### The courtyard, piece by piece

- **Jesse's house:** one low limestone wall, a shaded doorway and a flat cloth awning. The interior
  is suggested with warm darkness, not explored.
- **Welcome table:** a low table beneath the olive tree with silhouettes for the cushion, cup and
  lamp used in the activity.
- **Sheep fold:** a low woven fence and two or three background sheep. They breathe and turn but are
  not collectibles.
- **David's signs:** a small five-string harp, a filled clay water bowl and a folded shepherd cloak.
  Each sits in clear space and receives the existing Wonder Item glow only while relevant.
- **Oil horn:** small and practical, held by Samuel only during the final beat.
- **Breeze:** awning, olive leaves and clothing hems all lift together when David is anointed. There
  is no particle tornado.

### Courtyard geometry, concretely

Following `kings_camp.gd`'s pattern of one clearing centre with everything else placed relative to
it, a `bethlehem_courtyard.gd` layout would read something like this (illustrative distances in
metres, to be tuned against the actual camera once built, not final coordinates):

- **Courtyard centre**, roughly 9m across — small enough that the tabletop camera holds the whole
  scene, the same footprint discipline as the camp's clearing.
- **House wall and doorway** along the back edge, the family table and olive tree a few metres in
  front of it, the sheep-fold fence and path opening on the opposite edge from the house — the
  doc's "three readable edges," laid out so the child's eye and walking line never have to cross
  the brothers' line.
- **The seven brothers** stand in a loose line along the side edge, evenly spaced (roughly 1m
  apart, the same spacing discipline the camp guards keep from the path) so the processional beat
  can step each one forward into open ground without bumping the next.
- **David's three signs** (harp, water bowl, cloak) sit in the open middle ground, in clear sight
  lines the way the camp's gifts do, not tucked behind the house or the brothers.
- **Sheep path** enters from the brightest, most open edge, so David's later entrance reads as
  "coming from outside the family group," matching the doc's staging beat 5.

### What the camera is looking at

- **Arrival:** medium-wide courtyard view with Samuel on one side and the empty sheep path on the
  other.
- **Items:** ordinary close shots that make work feel cared for, not treasure reveals.
- **Brothers:** a respectful side-on composition. Each brother crosses the same patch of light; the
  camera does not exaggerate muscles, height or rejection reactions.
- **David's entrance:** a slow look toward the bright sheep path, then a modest push in as he enters.
- **Verse:** Samuel and the child at similar visual height, with the brothers soft behind them.
- **Anointing:** close enough to see Samuel's hand, David's face and the thin line of oil. The camera
  stays still while the breeze moves the scene.
- **Charm:** the existing ceremony, with the heart-lamp flame kept small and steady.

### Never in the picture

- A crown dropping onto David, a throne, palace or cheering crowd.
- Brothers shown as villains, rejected failures or comic fools.
- A beauty contest UI, ranking, red X marks or a child choosing who God prefers.
- A giant magical beam, supernatural eyes or oil that glows like a potion.
- A child performing the anointing.
- Text implying that appearance is bad or that attractive or strong people have bad hearts.

## The two new interactions, in detail

Nothing in the codebase today lets the child place an object rather than just collect one, and
nothing runs a multi-figure procession. Both are genuine new engineering, so they need their own
spec rather than being waved at as "a signature activity."

### Prepare the Welcome, in detail

- **Selection** reuses the existing proximity/touch input from the Chapter 2 gifts, but carrying is
  new. Those gifts disappear and are respawned beside David; they do not attach to or follow the
  child. Here the selected cushion, cup or lamp remains visible, floating gently beside Wonder
  Light until it reaches the table. This avoids an object looking glued to the walker's hand while
  still making the action read as carrying.
- **Placement** is new: three marked spots on the welcome table, each drawn as a simple dashed ring
  made from small flat mesh segments. It borrows the unfinished dashed-circle language from
  `gift_checklist.gd`, but needs new 3D geometry and placement state. A ring only accepts its own
  object (the cushion ring cannot take the cup), so "no wrong placement" is true by construction,
  not by an error message the child has to parse.
- **The motion:** walking into a ring while carrying its matching object triggers an automatic
  ease-in tween (roughly 0.6s, the same unhurried pacing family as Steady Hands' breathing ring),
  ending in a distinct sound per object (a soft cloth-set thud for the cushion, a small ceramic
  click for the cup, a gentle chime for the lamp — three different sounds, so a child listening
  without looking still knows which one just landed).
- **A checklist** reuses the `gift_checklist.gd` layout and tick-and-pop animation, relabelled
  "Getting ready for Samuel" with cushion/cup/lamp icons. Refactor the component to accept a title
  and item data instead of copying the Chapter 2 script. David's harp, bowl and cloak remain
  optional observations, so this is the chapter's only three-item checklist.
- **No fail state, no order requirement, no timer.** All three can be placed in any order; nothing
  the child can do here is wrong, matching Steady Hands' and the friendship cord's own rules.
- **Completion** (all three placed) is the cue that starts the seven-brothers procession, giving
  the activity a clear, felt handoff into the next story beat rather than just unlocking a menu.

### The seven brothers, staged

- Built on `jesse_sons.gd` (see **Asset inventory**): seven lightweight instances standing in the
  courtyard line before the scene starts.
- On cue, the line advances through one patch of light. Each brother takes two short steps forward,
  holds for a beat, then begins returning as the next brother moves. This uses the same
  pivot-rotation walk as the camp guards, triggered in a fixed overlapping sequence.
- **Pacing:** target 8-10 seconds for all seven, roughly one second of clear focus apiece with
  overlapping returns. Every brother remains individually visible without asking the child to
  watch seven complete walk-out/walk-back loops. Verify this against a real playtest (Improve-pass
  item 2); slow it only if children cannot count or distinguish the seven figures.
- **The camera stays still** (per "What the camera is looking at") — only the brothers move, which
  keeps the beat calm and keeps the respectful side-on framing intact for all seven rather than
  re-composing seven times.
- **No individual brother lines.** Jesse or Wonder Light carries any needed acknowledgement per
  brother (for example a single shared line like "Not this one" spoken once by Wonder Light over
  the first pass, not repeated seven times) — see **Draft script**.

## Animation and motion polish

The courtyard risks reading stiffer than Chapters 1-2 if the following are left as later polish
rather than built in from the start. None of this is a new technique to invent — each point below
is already proven somewhere else in the game, just not yet specified for this chapter.

**The seven brothers need an idle layer, not only a procession.** "The seven brothers, staged"
above only covers their one ~8-10s cued beat. For the rest of the scene — exploring, then working
through Prepare the Welcome — they are simply standing in a line, potentially for 30-60s. Seven
motionless figures in the background would be the most rigid thing in the chapter by contrast with
everything else moving. `camp_guard.gd` already solves this for its own standing crowd: an idle
glance cycle (`_look_from`/`_look_to`, a randomized pause, then a settle-legs blend back to rest)
between patrol legs. `jesse_sons.gd` should carry the same idle-glance/weight-shift behaviour
while waiting, not just the forward-and-back procession step. The procession itself should also
avoid uniform timing — if all seven step at identical cadence it reads as a conveyor belt, not
seven different young men. `camp_guard.gd` gives each guard a randomized phase offset
(`_phase = randf() * TAU`); the brothers' procession sequence should vary each one's step timing
slightly around the ~1.1s-per-brother average, rather than firing on a fixed metronome.

**Samuel, Jesse and younger David need conversational motion, not just `Blink`/`Talk`.** Chapter
2's actual playtest polish — not just its own concept doc — added "Jonathan blinks, nods and
gestures while his recording plays, and David shifts and nods as he listens." That is what keeps a
dialogue beat from feeling like two puppets reading subtitles at each other. This chapter's
**Asset inventory** only commits the three new rigs to `Blink`/`Talk` shape keys, which is
necessary but not sufficient. Each speaking character needs the same nod/gesture/weight-shift
treatment during their own lines, and whoever is listening needs small reactive motion too, rather
than standing frozen while someone else's line plays.

**The placement rings should breathe, not just react.** The Prepare the Welcome rings currently
only have a reaction — the 0.6s ease-in tween once an object lands. Until then they are static
dashed-ring geometry, and they are the most-looked-at object during the whole activity.
`word_chip.gd` already has the fix for this elsewhere in the game: "the next word breathes," a
slow idle pulse that invites a tap without a label. The empty rings should use the same
breathing-pulse language rather than sitting inert until touched.

**The anointing oil should unfurl, not appear.** "A narrow gold ribbon of oil" is staged carefully
camera-wise, but nothing above specifies how it appears on screen. If it simply pops into
existence it will be the stiffest single moment in the chapter's most important beat — the
opposite of the calm pacing every other interaction here commits to. The harp already uses a
`curve_mesh` for its strings, the same technique used for Jonathan's hair band; the oil ribbon is
a natural fit for the same approach, animating its length and opacity over roughly 1.5-2s so it
unfurls rather than snapping in.

**The courtyard needs visible ambient life beyond the sheep.** Chapter 1 has butterflies; Chapter
2 has fireflies and an owl with its own glide-and-perch animation. This chapter gives only sheep
as visible ambient life — doves and birds exist solely in the sound table below, with no on-screen
counterpart. Next to either previous chapter, a courtyard with only audio-implied birds will read
as noticeably emptier and stiller. Even one or two doves drifting between the roof edge and the
olive tree, using the drift-and-settle motion already built for the fireflies, would close this
gap cheaply.

**Younger David's walk should read younger, not just look younger.** Now that he is correctly a
separate rigged model rather than a reshaped adult (**Asset inventory**), his walk cycle is a real
opportunity the doc doesn't yet use: age read through motion, not only through face and height. A
slightly quicker cadence and lighter weight than adult David's established walk — rather than the
same gait timing on a smaller rig — would make "younger David" felt as much as seen, and keep his
entrance from reading as a costume change on the same character.

**Samuel and Jesse's robes need their own secondary motion.** Jonathan's shoulder sash is a
dedicated ribbon mesh with its own subtle sway. Samuel and Jesse's robes don't yet commit to
equivalent secondary cloth motion; standing in the same scene family as Jonathan without it, both
would read visibly stiffer by direct comparison.

## What you hear in Bethlehem

| Sound | Behaviour | Likely `sound_library.gd` entry |
|---|---|---|
| Morning air | Soft breeze with occasional awning cloth; ducks under speech | `WIND` variant, reused |
| Birds | Sparse doves and small hillside birds, gentler than Chapter 1 | new `DOVES` ambience |
| Sheep | Two or three distant bleats, never over dialogue | reuses the existing `BLEAT_COUNT` bleat |
| Courtyard life | One clay-cup touch, sandals on dust and a faint wooden stool movement | new `"dust"` entry in `SURFACES` (grass remains the default; `path` and `water` are the two named entries today) |
| Harp | A short five-note motif when the harp is found; it becomes the chapter's music motif | new `HARP_MOTIF` sfx |
| Welcome activity | Soft cloth placement, cup set-down and lamp chime, each distinct | new `CLOTH_SET`, `CUP_SET`, `LAMP_CHIME` sfx |
| Brothers | Sandal steps and cloth movement; no muttering crowd loop | reuse or retune the credited real footsteps; add cloth only if it reads cleanly |
| Anointing | Quiet oil pour, one warm low chime and the coordinated breeze | new `OIL_POUR`, `LOW_CHIME` sfx |
| Music | Lullaby theme rearranged for plucked harp and soft frame drum, no royal brass | a new rendered arrangement based on `music/meadow_lullaby.wav` |

The existing ducking rules apply. Sheep and birds wait during speech. The anointing sound must remain
below Samuel's words rather than functioning as a victory fanfare. Extend `tools/make_sounds.py`
for the harp motif, chime and ambience layers that survive an in-game listening test. The current
sound notes record that synthesized lambs and footsteps sounded false, so natural birds, dust
steps, cloth, cup and oil should use credited CC0 recordings when synthesis has the same problem.
Any sourced file must be added to `assets/audio/CREDITS.md` and checked on a tablet speaker.

## Voice design

**Exactly two new voice profiles are needed** — the cast grows from three presets (Juno, Bram,
Dylan) to five. No further profiles are needed for Jesse's sons or the sheep fold.

| Role | Voice | Status |
|---|---|---|
| Wonder Light | Juno | Existing, unchanged |
| David (younger) | Bram | Existing; same preset, wording and pacing adjusted for a younger David — do not pitch-shift him into a cartoon child, per the Jonathan/David casting notes already in `voice-over.md` |
| Samuel | **New preset, TBD** | Warm older male, measured and clear, authority without sternness — needs its own name once cast (following the Juno/Bram/Dylan naming convention) |
| Jesse | **New preset, TBD** | Adult male, audibly distinct from Samuel *and* Bram — the same distinctness test already applied when Dylan was chosen over Julian for Jonathan |
| The seven brothers | — | No dedicated voice. No brother has an individual line; Jesse and Wonder Light carry every beat that touches them |

**Casting process**, mirroring how Bram (over Cody) and Dylan (over Julian) were chosen: generate
2-3 candidate presets per role from the Seed Audio catalogue, listen to them back to back against
Bram/Dylan on the same lines, and reject anything that "sounds like it was recorded in a room" (the
documented reason Cody was passed over) or that sits too close to an existing voice. Do not lock
Samuel and Jesse in isolation — always compare them to each other and to the existing cast.

**Clip budget, by precedent.** Chapter 1 shipped 31 story lines; Chapter 2 added roughly 26 more
across its story, map and Easy Words lines. The draft script below (including the verse reference
and verse text) runs to 20 standard lines — 15 Wonder Light, 2 Jesse, 1 David, 2 Samuel — plus Easy
Words duplicates for the youngest-facing subset (roughly 10-12 of those lines) — **call it 30-32
new clips**, a shade under Chapter 2's scale, which fits a chapter with one fewer new speaking
character carrying dialogue. All Seed Audio, mono 24kHz PCM, trimmed with `tools/fetch_vo.py`'s
existing pause/click trimming, per `voice-over.md`.

Voice casting remains open for Samuel and Jesse. Every final line needs a recorded clip and an Easy
Words review before implementation is complete.

## Who is talking

Chapter 2 added a name tag on the dialogue bar (`dialogue_view.gd`): a small drawn face plus the
speaker's name in their own colour, so a child who cannot read yet still knows who is speaking by
sight, and a parent can follow along by the colour of the words. It follows whichever line is
currently playing (`AudioDirector.line_started`), so a block with two speakers switches
automatically as the voice changes. This carries over as-is (**What carries over as-is**), but it
needs real extension, not just inheritance, for this chapter's two new named speakers:

- **`SPEAKERS`** (`dialogue_view.gd`, currently four entries: Wonder Light, David, Jonathan, Bible)
  needs two new colour entries — Samuel (cream/grey, matching his robe and hair) and Jesse
  (brown/olive, matching his), each with its own fill, ink and text colour the way the existing
  four are defined.
- **`_draw_face()`**'s match statement needs two new small icons alongside the existing Wonder
  Light glow, David, Jonathan and open-book cases — Samuel's grey hair and short beard, Jesse's
  brown hair — drawn at the same tiny scale and stroke weight as the existing four so the set reads
  as one family of icons, not a mismatched addition.
- **The speaker-detection list**, currently `["Wonder Light", "David", "Jonathan"]`, needs
  `"Samuel"` and `"Jesse"` added, and every line in the final script must use an exact
  `Speaker: "..."` prefix for the tag to pick it up. The **Draft script** table below labels one
  row "David (younger)" for the reader's clarity only — the actual line in the game must be
  written `David: "..."`, the same prefix Chapters 1-2 already use, or the tag will not show.
- **"David" needs no new entry.** Younger David keeps the same tag, colour and drawn face as
  Chapters 1-2 (same tunic/sash colour), so the child recognises him by the tag as much as by the
  model — one more thread tying "this is still David" together alongside his face and clothing.
- **The seven brothers still need no entry.** They have no individual lines (**Voice design**), so
  there is no tag to draw for them; Jesse and Wonder Light's existing tags cover every line that
  touches them.

Easy to let slip since it is "just" four lines of data and one new match branch, but it is a real
piece of the accessibility and readability story Chapter 2 already established, not a
nice-to-have — worth its own line in **Improve pass before implementation** rather than being
assumed to come along for free with the rigged models.

## Draft script (for timing and casting, not final)

A speaker-labelled pass through the eight story beats, wording only — **not** checked against the
WEB text for 1 Samuel 16:7, not through an Easy Words pass, and not reviewed for theology (that is
Improve-pass item 7). Written in short, present-tense sentences to match the existing cast's
register (compare `vo_library.gd`'s "This is David's valley. He looks after sheep. God looks after
him."), and grouped so promoting it into `LINES` later is a copy, not a rewrite.

| # | Speaker | Line | Beat |
|---|---|---|---|
| 1 | Wonder Light | "We are turning back the page. This is Bethlehem, before the valley — David's family, getting ready for a guest." | 1. Turn back the page |
| 2 | Wonder Light | "David is out with the sheep. You may notice the things he uses to care for them while we get ready for Samuel." | 2. Optional courtyard discoveries |
| 3 | Wonder Light | "A small harp. David plays it while he watches the sheep." | 2. Optional harp discovery |
| 4 | Wonder Light | "A bowl of water for the sheep. David cares for them every day." | 2. Optional water-bowl discovery |
| 5 | Wonder Light | "A plain shepherd's cloak, made for work outside." | 2. Optional cloak discovery |
| 6 | Wonder Light | "Samuel is coming. Let's get the cushion, the cup and the lamp ready for him." | 3. Prepare the welcome |
| 7 | Jesse | "Samuel! Welcome to our home." | 4. Meet Samuel and Jesse |
| 8 | Wonder Light | "Jesse's seven older sons come forward, one by one." | 4. Brothers pass |
| 9 | Samuel | "Yahweh has not chosen these." | 4. Brothers have passed; calm, never dismissive |
| 10 | Wonder Light | "Samuel waits. The one God has chosen is not here yet." | 4-5. The missing son |
| 11 | Samuel | "Are all your children here?" | 5. Samuel asks for the missing son |
| 12 | Jesse | "The youngest is still caring for the sheep." | 5. Call David home |
| 13 | Wonder Light | "Let's call David home." | 5. Call David home |
| 14 | David (younger) | "You called for me?" | 5. David enters — attentive, modest, not anxious or heroic |
| 15 | Wonder Light | "First Samuel, chapter sixteen, verse seven." | 6. Verse reference |
| 16 | Wonder Light | "But Yahweh said to Samuel, 'Don't look on his face, or on the height of his stature, because I have rejected him; for I don't see as man sees. For man looks at the outward appearance, but Yahweh looks at the heart.'" | 6. Verse text — verified WEB wording; split across readable pages if needed |
| 17 | Wonder Light | "Samuel pours the oil. God has chosen David, the youngest shepherd." | 7. The anointing |
| 18 | Wonder Light | "David was caring for the sheep when nobody expected him to be called. God saw his heart. God sees you too." | 8. Reflect without making faithfulness the price of being chosen |
| 19 | Wonder Light | "A Faithful Heart charm, for caring well in quiet places." | 8. Charm |
| 20 | Wonder Light | "Keep it close. Be faithful with the small things in front of you." | 8. Charm, closing |

That is 15 Wonder Light lines, 2 Jesse, 1 David and 2 Samuel — light enough that Jesse and Samuel stay
"used for only a few short lines" as the Voice design section already commits to, while Wonder
Light continues to carry most of the explanation, as she does in Chapters 1 and 2. Line 9 is the
one place Samuel's tone most needs a real read-through with a candidate voice before locking: it
must sound patient and discerning rather than stern or dismissive.

## Decided

- The chapter is a clearly announced prequel after Chapter 2.
- Faithfulness is the working value; "God sees the heart" is the central truth.
- Samuel, not the player, chooses and anoints David.
- All seven older brothers are visible and treated respectfully.
- The scene is a family courtyard, never a coronation.
- The chapter ends with Faithful Heart in the journal and on the bracelet.

## Improve pass before implementation

1. Test **Faithfulness**, **Faithful Heart** and the easy-word explanation with parents and children;
   keep "God sees the heart" even if the charm name changes.
2. Storyboard the seven-brother sequence so it is clear without becoming repetitive or expensive.
3. Prototype Prepare the Welcome with touch, including the visible Wonder Light carry state, and
   verify that placing three objects feels different from collecting three Wonder Items.
4. Design Samuel and younger David side by side with the current David model before generating any
   final assets; verify younger David's rig and walk before committing to close-up shots.
5. Record temporary voices and time the whole chapter before commissioning final voice clips.
6. Test whether the anointing is understandable without a crown or magical glow.
7. Review the complete script for biblical wording, age clarity and the difference between God's
   grace and David's faithfulness.
8. Build `jesse_sons.gd` early, on the camp-guard pattern, since its pacing (Improve-pass item 2)
   sets the time budget for a beat the child cannot speed up or skip.
9. Read candidate Samuel takes specifically against draft line 9 ("Yahweh has not chosen these.")
   before locking his voice — it is the line most likely to read as stern or dismissive if the
   casting choice is wrong.
10. Confirm `journal_content.gd`'s `MYSTERY_SLOTS` math still lands on 5 total charm slots once
    `CHARM_FAITHFUL_HEART` is added (3 earned + `MYSTERY_SLOTS = 2` already matches the five-journey
    roadmap, so this should be a no-op, but verify rather than assume).
11. Extend `dialogue_view.gd`'s `SPEAKERS`, `_draw_face()` and speaker-detection list for Samuel
    and Jesse before recording any lines — see **Who is talking**. Confirm every script line uses
    the exact `Speaker: "..."` prefix so the tag actually appears; this is easy to build correctly
    and just as easy to silently omit.
12. Build `jesse_sons.gd`'s idle-glance layer alongside its procession step, not after — a static
    crowd is easy to miss until the scene is actually played, not read. Give the procession's
    per-brother timing a randomized offset rather than a fixed cadence, the same way
    `camp_guard.gd` already varies its guards — see **Animation and motion polish**.
13. Confirm Samuel, Jesse and younger David each ship with conversational nod/gesture motion
    during their own lines and small reactive motion while listening, not just `Blink`/`Talk` —
    compare against Chapter 2's actual playtest-polish pass, not just its concept doc, before
    calling this chapter's dialogue beats done.
