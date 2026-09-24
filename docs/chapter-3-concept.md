# Chapter 3 — The Beginning

This is the next planned journey after The King's Camp. It is a deliberate look backward: Wonder
Light turns to an earlier page and shows how David's public story began, when Samuel came to
Bethlehem and anointed the youngest son of Jesse. The chapter is not built yet.

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

**Verse:** 1 Samuel 16:7 (WEB), using the complete verified wording when the script is locked.

**New charm:** Faithful Heart. A small heart-shaped lamp with one steady flame, readable at journal
size. The flame means quiet faithfulness; it is not a magical sign that some hearts are better than
others.

## The story, and what the child does

1. **Turn back the page.** The Faith Journey folds from the blue-hour camp into a warm Bethlehem
   morning. Wonder Light clearly names this as an earlier day.
2. **Explore Jesse's hillside home.** David is away with the sheep. The family is preparing to
   welcome Samuel.
3. **Find three signs of David's quiet work:** his small harp, the water bowl he fills for the sheep,
   and his simple shepherd's cloak. These are discoveries, not proof that David deserves to be king.
4. **Prepare the welcome.** Place a cushion, a cup of water and an oil lamp for Samuel. Each object
   snaps gently into a clear silhouette; there is no wrong placement or timer.
5. **Meet Samuel and Jesse.** Jesse's seven older sons pass before Samuel. They are presented with
   dignity. Nobody is mocked for being tall, strong or older.
6. **Call David home.** A soft bell or Wonder Light guides the child's gaze toward the sheep path.
   David enters from the field.
7. **Hear the Word.** Samuel speaks the heart of 1 Samuel 16:7. Wonder Light explains in easy words:
   "People notice the outside first. God sees who you are inside."
8. **The anointing.** Samuel performs it. The child watches rather than pouring the oil or choosing
   the king. A narrow gold ribbon of oil and a warm breeze make the moment readable without turning
   it into magic.
9. **Receive the Faithful Heart charm.** The reflection connects David's unseen work to a child's
   small acts of care: "God sees the kind and faithful things nobody else notices."

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
- Two new rigged character models (Samuel, Jesse), one added shape key and hair swap on the
  existing David model (younger David), and one new shared low-cost crowd rig instanced seven
  times (the brothers). Not seven new models — see **Asset inventory**.
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
- Two new voice profiles (Samuel, Jesse) and roughly 35-40 new recorded clips, plus their Easy
  Words duplicates — see **Voice design** and **Draft script**.
- New morning ambience and interaction sounds, most of them synthesizable with the same
  procedural pipeline already used for wind/stream/crickets/campfire/owl (`tools/make_sounds.py`),
  so this chapter carries little of the licensing burden flagged for chapters 4-5 (backlog 7.10).

## Asset inventory: models, rigs and props

The codebase already has two different ways to build a character, and this chapter should use
both rather than defaulting to the expensive one for everyone.

**Tier 1 — rigged, shape-keyed, camera-ready (the David/Jonathan pipeline).** `jonathan_v1.glb`
was not modelled from scratch: `art/blender/scripts/characters/generate_jonathan.py` loads
David's base construction (`generate_david_mentor_v4.py`, itself built on the shared
Wonder-Walker rig in `generate_wonder_walker_v5.py`), then swaps in new hair, sash, materials and
a slightly narrower/longer face, and adds `Blink`/`Talk` shape keys for the dialogue camera. This
tier is for anyone the child sees in close-up with a speaking line:

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
- **Younger David — not a new model.** He needs to read as "clearly the David from Chapters 1-2"
  (Decided), so the cheapest and most consistent option is one added `Young` shape key on the
  existing `david_mentor_v13.glb` (rounder cheeks, slightly shorter proportions — the same
  mechanism already used for his `Crouch` key in Steady Hands) plus a shorter-hair mesh swap, not
  a second rig. This also means his walk cycle, camera framing and touch collision need no new
  work.

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
| Harp | A small curved frame plus 5 thin `curve_mesh` strings | The same `curve_mesh` technique as Jonathan's hair band |
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

So the honest count for "how many models": **2 new rigged character models** (Samuel, Jesse),
**1 shape key + hair swap** added to the existing David model, **1 shared crowd rig** instanced 7
times, and **11 new small procedural props** — no new environment GLB, following Chapter 2's
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
  "coming from outside the family group," matching the doc's staging beat 6.

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

- **Pickup and carry** reuse the existing Wonder Item pickup (the same touch/gamepad handling the
  robe/bow/belt already use), so nothing new is needed to lift the cushion, cup or lamp.
- **Placement** is new: three marked spots on the welcome table, each a dashed ground-ring decal —
  visually the same "dashed circle, not yet done" language `gift_checklist.gd` already draws for
  an unfound gift, just moved from a 2D checklist onto the 3D table. A ring only accepts its own
  object (the cushion ring cannot take the cup), so "no wrong placement" is true by construction,
  not by an error message the child has to parse.
- **The motion:** walking into a ring while carrying its matching object triggers an automatic
  ease-in tween (roughly 0.6s, the same unhurried pacing family as Steady Hands' breathing ring),
  ending in a distinct sound per object (a soft cloth-set thud for the cushion, a small ceramic
  click for the cup, a gentle chime for the lamp — three different sounds, so a child listening
  without looking still knows which one just landed).
- **A checklist** mirrors `gift_checklist.gd` exactly (same panel, same tick-and-pop animation),
  relabelled "Getting ready for Samuel" with the cushion/cup/lamp icons instead of robe/bow/belt —
  cheap to build since it is the same component with new art and new data, not new logic.
- **No fail state, no order requirement, no timer.** All three can be placed in any order; nothing
  the child can do here is wrong, matching Steady Hands' and the friendship cord's own rules.
- **Completion** (all three placed) is the cue that starts the seven-brothers procession, giving
  the activity a clear, felt handoff into the next story beat rather than just unlocking a menu.

### The seven brothers, staged

- Built on `jesse_sons.gd` (see **Asset inventory**): seven lightweight instances standing in the
  courtyard line before the scene starts.
- On cue, each brother in turn takes a few steps forward into the light in front of Samuel, holds
  for a beat, and steps back — the same kind of pivot-rotation walk the camp guards already do,
  just triggered in a fixed sequence instead of a patrol loop.
- **Pacing:** roughly 1.5-2s in front, a short pause, then return — about 12-14 seconds for all
  seven, brisk enough to hold a six-year-old's attention across a beat with no interaction, while
  still showing every brother individually, as the doc's Decided section requires. This is a
  number to verify against a real playtest (Improve-pass item 2), not a fixed budget.
- **The camera stays still** (per "What the camera is looking at") — only the brothers move, which
  keeps the beat calm and keeps the respectful side-on framing intact for all seven rather than
  re-composing seven times.
- **No individual brother lines.** Jesse or Wonder Light carries any needed acknowledgement per
  brother (for example a single shared line like "Not this one" spoken once by Wonder Light over
  the first pass, not repeated seven times) — see **Draft script**.

## What you hear in Bethlehem

| Sound | Behaviour | Likely `sound_library.gd` entry |
|---|---|---|
| Morning air | Soft breeze with occasional awning cloth; ducks under speech | `WIND` variant, reused |
| Birds | Sparse doves and small hillside birds, gentler than Chapter 1 | new `DOVES` ambience |
| Sheep | Two or three distant bleats, never over dialogue | reuses the existing `BLEAT_COUNT` bleat |
| Courtyard life | One clay-cup touch, sandals on dust and a faint wooden stool movement | new `"dust"` entry in `SURFACES` (footsteps already support a surface-keyed sound; this just adds a third alongside `path`/`water`) |
| Harp | A short five-note motif when the harp is found; it becomes the chapter's music motif | new `HARP_MOTIF` sfx |
| Welcome activity | Soft cloth placement, cup set-down and lamp chime, each distinct | new `CLOTH_SET`, `CUP_SET`, `LAMP_CHIME` sfx |
| Brothers | Sandal steps and cloth movement; no muttering crowd loop | reuses footstep/cloth sounds already built for the guards |
| Anointing | Quiet oil pour, one warm low chime and the coordinated breeze | new `OIL_POUR`, `LOW_CHIME` sfx |
| Music | Lullaby instrumentation led by plucked harp and soft frame drum, no royal brass | a variant of `music/meadow_lullaby.wav`, not a new track |

The existing ducking rules apply. Sheep and birds wait during speech. The anointing sound must remain
below Samuel's words rather than functioning as a victory fanfare. Every new sound above is short
foley or a simple tonal cue — the same tier as `campfire.wav`, `owl_hoot.wav` and `crickets.wav`,
all of which `tools/make_sounds.py` already synthesizes rather than sourcing as licensed samples.
The same tool should be extended for these rather than sourcing outside audio, keeping Chapter 3
free of the rights/attribution question backlog 7.10 raises for chapters 4-5's animal, rain and
harbour recordings.

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
and verse text) runs to 20 standard lines — 15 Wonder Light, 2 Jesse, 2 David, 1 Samuel — plus Easy
Words duplicates for the youngest-facing subset (roughly 10-12 of those lines) — **call it 30-32
new clips**, a shade under Chapter 2's scale, which fits a chapter with one fewer new speaking
character carrying dialogue. All Seed Audio, mono 24kHz PCM, trimmed with `tools/fetch_vo.py`'s
existing pause/click trimming, per `voice-over.md`.

Voice casting remains open for Samuel and Jesse. Every final line needs a recorded clip and an Easy
Words review before implementation is complete.

## Draft script (for timing and casting, not final)

A speaker-labelled pass through the nine story beats, wording only — **not** checked against the
WEB text for 1 Samuel 16:7, not through an Easy Words pass, and not reviewed for theology (that is
Improve-pass item 7). Written in short, present-tense sentences to match the existing cast's
register (compare `vo_library.gd`'s "This is David's valley. He looks after sheep. God looks after
him."), and grouped so promoting it into `LINES` later is a copy, not a rewrite.

| # | Speaker | Line | Beat |
|---|---|---|---|
| 1 | Wonder Light | "We are turning back the page. This is Bethlehem, before the valley — David's family, getting ready for a guest." | 1. Turn back the page |
| 2 | Wonder Light | "Find David's harp, his water bowl, and his shepherd's cloak. They show the quiet work he does every day." | 3. Find three signs |
| 3 | Wonder Light | "A small harp. David plays it while he watches the sheep." | 3. Harp found |
| 4 | Wonder Light | "A bowl of water, filled for the sheep. Nobody told him to. He just does it." | 3. Water bowl found |
| 5 | Wonder Light | "A plain shepherd's cloak, made for outdoor work, not for a palace." | 3. Cloak found |
| 6 | Wonder Light | "Samuel is coming. Let's get the cushion, the cup and the lamp ready for him." | 4. Prepare the welcome |
| 7 | Jesse | "Samuel! Welcome to our home." | 5. Meet Samuel and Jesse |
| 8 | Wonder Light | "Jesse has seven sons. Samuel looks at each one." | 5. Brothers pass |
| 9 | Samuel | "Not this one. Yahweh does not see the way people see." | 7. Samuel speaks the heart of the verse, in-scene |
| 10 | Wonder Light | "People notice the outside first. God sees who you are, inside." | 7. Easy-words explanation (already in the outline) |
| 11 | Jesse | "There is still the youngest. He's out with the sheep." | 6. Call David home |
| 12 | Wonder Light | "Let's call David home." | 6. Call David home |
| 13 | David (younger) | "Coming! Did I do something wrong?" | 6. David enters — curious, a little worried, not heroic |
| 14 | Wonder Light | "No. Samuel has something for you." | 6-7 transition |
| 15 | Wonder Light | "First Samuel, chapter sixteen, verse seven." | 7. Verse reference |
| 16 | Wonder Light | "Yahweh doesn't see the way man sees. Man looks at the outward appearance, but Yahweh looks at the heart." | 7. Verse text — **draft wording, verify against WEB before recording** |
| 17 | Wonder Light | "Samuel pours the oil. It's a sign: God has chosen David's heart." | 8. The anointing |
| 18 | Wonder Light | "God saw the kind, faithful things David did when nobody was watching. He sees yours too." | 9. Reflect |
| 19 | Wonder Light | "A Faithful Heart charm, for the quiet work nobody else was watching." | 9. Charm |
| 20 | Wonder Light | "Keep it close. Faithfulness is yours to carry." | 9. Charm, closing |

That is 15 Wonder Light lines, 2 Jesse, 2 David, 1 Samuel — light enough that Jesse and Samuel stay
"used for only a few short lines" as the Voice design section already commits to, while Wonder
Light continues to carry most of the explanation, as she does in Chapters 1 and 2. Line 9 is the
one place Samuel's tone most needs a real read-through with a candidate voice before locking —
it is the line most likely to sound stern or dismissive if mis-cast, which is exactly what the
doc's "Never in the picture" list warns against.

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
3. Prototype Prepare the Welcome with touch and verify that placing three objects feels different
   from collecting three Wonder Items.
4. Design Samuel and younger David side by side with the current David model before generating any
   final assets.
5. Record temporary voices and time the whole chapter before commissioning final voice clips.
6. Test whether the anointing is understandable without a crown or magical glow.
7. Review the complete script for biblical wording, age clarity and the difference between God's
   grace and David's faithfulness.
8. Build `jesse_sons.gd` early, on the camp-guard pattern, since its pacing (Improve-pass item 2)
   sets the time budget for a beat the child cannot speed up or skip.
9. Read candidate Samuel takes specifically against draft line 9 ("Not this one. Yahweh does not
   see the way people see.") before locking his voice — it is the line most likely to read as
   stern or dismissive if the casting choice is wrong.
10. Confirm `journal_content.gd`'s `MYSTERY_SLOTS` math still lands on 5 total charm slots once
    `CHARM_FAITHFUL_HEART` is added (3 earned + `MYSTERY_SLOTS = 2` already matches the five-journey
    roadmap, so this should be a no-op, but verify rather than assume).
