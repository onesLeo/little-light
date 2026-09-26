# Chapter 5 — Jonah and the Great Fish

This is the fifth planned journey and the ending of the first store-release volume. The familiar
name is often "Jonah and the whale," but the Bible says that God appointed a great fish. The game
uses **Great Fish** in its title and dialogue; parent-facing store text may mention the familiar name
once for recognition. The chapter is playable; see [chapter-5-readiness.md](chapter-5-readiness.md).

## Where chapter 4 leaves off

Chapter 4 ends under the rainbow with the Trust charm. On the Faith Journey, the rainbow's blue band
becomes a coastline. A small ship waits at Joppa while the road God asked Jonah to take points in the
other direction.

Wonder Light says, "Noah trusted God before he could see the rain. Jonah heard God too—but Jonah ran
the other way."

## The story: Jonah and God's mercy

**Bible passage:** Jonah 1–4.

God tells Jonah to go to Nineveh. Jonah boards a ship going away from the city. A storm rises. Jonah
admits that he is running from God and tells the sailors what must happen; the sailors reluctantly
put him into the sea, and the storm becomes calm. God appoints a great fish to carry Jonah. Jonah
prays, the fish releases him onto dry land, and Jonah goes to Nineveh. The people turn from their
wrongdoing and God shows mercy. Jonah is angry, and God uses the plant and the final question to show
that he cares for the people of Nineveh too.

The fish is not the moral of the story. It is God's provision in the middle of a story about mercy:
mercy for Jonah, mercy for frightened sailors, and mercy for Nineveh.

**Value:** Mercy.

**Verse:** still to be locked after read-aloud testing. Jonah 2:2 supports prayer and rescue; Jonah
4:2 directly names God's gracious and merciful character but is longer. The final chapter may use a
short verse in the activity and the longer passage in the Faith Journal.

**New charm:** Mercy. A small warm light held safely between two curved dark-blue waves. It must read
as shelter and another chance, not as Jonah trapped in teeth.

## The story, and what the child does

1. **Arrive at Joppa.** The harbour is busy but gentle. Wonder Light shows the road marker for
   Nineveh and the ship leaving the other way.
2. **Find Jonah's three travelling things:** his small bag, a rolled message naming Nineveh and an
   oil lamp. The message keeps turning toward the road while Jonah keeps looking toward the ship.
3. **Meet Jonah.** Jonah admits that he does not want to go. The story does not make him a comic
   coward; his reluctance is real and his choice is wrong.
4. **Board the ship.** The child walks up the gangway after Jonah. Sailors secure the bag, rope and
   lamp while the coast folds away behind them.
5. **Storm tableau.** The ship rises and falls slowly between layered paper waves. The child secures
   three loose pieces of cargo by dragging them into outlined spaces. This gives the child a safe,
   constructive action while the adults speak. There is no steering challenge or failure state.
6. **Jonah enters the sea.** The child does not push or throw him. Wonder Light narrates the sailors'
   reluctance; Jonah steps behind a foreground wave, the storm quiets, and the great fish silhouette
   rises beneath a warm point of light.
7. **Prayer in the Deep.** A calm paper cutaway shows Jonah on a dry curved platform inside an
   abstract blue chamber. The child guides three lights carrying the ideas **Call**, **Hear** and
   **Go** toward Wonder Light. Each part adds a note to Jonah's prayer.
8. **Another chance.** The fish releases Jonah onto a bright shore without a comic spit sound or
   humiliating animation. The rolled message opens toward Nineveh.
9. **Walk to Nineveh.** The child and Jonah follow a short road to the city gate. Jonah gives the
   warning; a paper-page montage shows families turning away from harm.
10. **God cares for Nineveh.** Outside the city, the shade plant grows and later withers. Wonder
    Light gives the final question in age-clear language: Jonah cared about the plant; God cared
    about a whole city of people.
11. **Receive the Mercy charm.** The reflection names both directions of mercy: "God gave Jonah
    another chance. God cared for the people Jonah did not want to forgive."

## Band

Band A uses three large cargo outlines and three prayer lights with spoken words and distinct icons.
The sea sequence advances even if the child stops touching the screen.

Band B may later let the child choose which part of the story shows mercy—Jonah's rescue, the
sailors' safety or Nineveh's forgiveness. Every choice receives a true explanation; none is marked
wrong because all three belong to the theme.

## Where it happens

This chapter uses one fold-out paper world with three connected panels rather than three unrelated
levels:

1. **Joppa and the ship:** sun-warmed harbour on the left.
2. **The deep and shore:** layered blue paper sea in the centre, with the fish cutaway appearing only
   during prayer.
3. **Nineveh and the shade hill:** pale stone city and dusty road on the right.

Only the active panel carries full animation and collision. The others flatten into distant
story-page silhouettes. This controls memory and helps the child understand that the story has
moved to a new place.

## What carries over as-is

- Wonder-Walker, Wonder Light, profiles, controls, checklist and accessibility settings.
- Camera director, dialogue panels, verse presentation, charm ceremony and end card.
- Paper water techniques from Chapter 1, reworked as broad sea layers rather than a realistic ocean.
- Camp wind and cloth principles for sails and clothing.
- The chapter-state and lazy-build approach used by The King's Camp.

## What is new work

- A three-panel fold-out environment (runtime paper-prop construction, the same lazy-build,
  only-the-active-panel-animates pattern `kings_camp.gd` already established) and transitions
  between harbour, deep, shore and Nineveh — see **Asset inventory**.
- One new rigged character model (Jonah), one new shared low-cost crowd rig for the three sailors,
  and a second crowd rig (or a pose-swap variant of the same technique) for Nineveh's families —
  see **Asset inventory**.
- A great-fish exterior with its own swim state machine, closely modelled on the camp owl's
  existing fly/perch state machine rather than built from scratch, and an abstract cutaway interior
  built the same paper-prop way as the ark's cutaway — see **Asset inventory**.
- Ship, layered sea (reusing Chapter 1's stream water shader family, not a new water system),
  harbour props, Nineveh gate, a growing-then-withering shade plant, and the road — see **Asset
  inventory**.
- Two new interactions: Secure the Cargo (a near-direct reuse of Chapter 3's Prepare the Welcome
  placement system) and Prayer in the Deep (a new "guide toward a point" mechanic, extending
  `word_chip.gd`'s glow/tap language rather than replacing it) — see **The two new interactions,
  in detail**.
- Calm storm motion that cannot cause motion sickness, **and** a genuinely new accessibility
  setting: reduced motion. No reduced-motion toggle exists anywhere in the codebase today — this
  chapter is the first to need one, not a variant of something that already exists. See
  **Animation and motion polish**.
- Two definite new voice profiles (Jonah, Captain) and a decision to make, not just cast, about
  whether Nineveh gets its own one or two voices or is carried by Wonder Light like Chapter 3's
  brothers and Chapter 4's family — see **Voice design**.
- Two new entries in the "who is talking" name tag (`dialogue_view.gd`) for Jonah and the Captain,
  plus a third only if Nineveh gets a dedicated voice — see **Who is talking**.
- Harbour, storm, underwater, shore and city sound states — see **What you hear across the
  journey**.
- Mercy journal art, charm and first-volume completion treatment.

## Asset inventory: models, rigs and props

Same two-tier character approach as Chapters 3 and 4, plus the animal/creature technique Chapter
4 established, applied here to one large creature instead of six pairs.

**Tier 1 — rigged, shape-keyed, camera-ready.** For Jonah alone, since he is the only new
character the doc calls for real facial range ("expressive shoulders and hands because much of
the story is reluctance, prayer and honest frustration"):

- **Jonah** — `generate_jonah_v1.py`, wrapping the same shared paper-person rig
  as David, Jonathan, Samuel, Jesse and Noah. New geometry: short dark curls, a compact beard, a
  strong-nose face profile distinct from every other named character so far (**Voice design**'s
  "must not resemble Dylan's Jonathan or Bram's David" is a visual requirement too, not only a
  voice one), dusty indigo over muted ochre cloth. `Blink`/`Talk` shape keys, plus wider shoulder
  and hand expressiveness than the calmer characters — closer to the range Jonathan already has
  than to Samuel's restrained economy of motion.

**Tier 2 — lightweight, unrigged, crowd-ready (the camp-guard pipeline).** For the three sailors
and for Nineveh's families:

- **The three sailors** — one new `sailors.gd`, built like `camp_guard.gd`, Chapter 3's
  `jesse_sons.gd` and Chapter 4's `noahs_family.gd`: pivot-hierarchy bodies, no bones, variety from
  small `CLOTH`/`SKIN`/`HAIR` colour arrays. Three named roles (captain, deck hand, rope-handler)
  are just three `look` indices with slightly different held-prop attachments (a coil of rope, a
  line), not three separate builds.
- **Nineveh's families** — the same crowd-rig technique, but used differently: the doc's "families
  turning away from harm" montage doesn't need continuous walk-cycle animation the way the sailors
  or Chapter 3's brothers do. A cheaper, appropriate build here is 2-3 fixed *poses* per instance
  (turned-away, listening, turned-toward) swapped on a timed cut rather than blended, closer to
  a paper tableau than a walk cycle — matching the doc's own "paper-page montage" language, and
  meaningfully cheaper than animating a crowd that is only ever seen from a respectful distance.

**A new creature technique: the great fish's swim state machine.** `camp_owl.gd` already solves
almost exactly this problem for a different animal: a `WAITING`/`FLYING`/`PERCHED`-style state
machine (here, better named `WAITING`/`SURFACING`/`GONE`) driving an eased position along a curve,
with motion confined to slow, predictable phases rather than free improvisation. The fish's rise
("a warm point of light" beneath the water, per the story beats) should reuse that same
quadratic-bezier arc technique for a slow vertical rise rather than inventing new motion math — the
owl's glide-in, the fish's rise-and-surface, and (were it ever needed) any future creature's
entrance are all the same underlying problem. Body construction follows the soft-blob/profile
technique Chapter 4 generalised from the lamb: one large blob body, a tapered profile chain for
the tail, small fin blobs — same tooling as the ark's elephants and giraffes, applied to a bigger,
simpler silhouette (the doc is explicit: "closer to a gentle whale-like fish shape... without
insisting on a biological species," which is exactly what a soft-blob build produces well).

**Environment and props (`camp_paper.gd`-style primitives, the lazy-build panel pattern from
`kings_camp.gd`):** the ship (mast, sail, low cabin, high rail), harbour props (mooring posts,
folded nets, gangway), the Nineveh gate and cloth shades, the shade plant (a soft-blob or simple
scaling form that can grow then visibly wither — see **Animation and motion polish**), and the
sea itself.

**The sea is not a new water system.** Chapter 1's animated stream already has a dedicated shader
(`assets/shaders/stream_water.gdshader`) and a fish-animation precedent
(`bethlehem_stream_fish_alive_v7.glb`, procedurally placed by `stream_placement.gd`). The doc's
"paper water techniques from Chapter 1, reworked as broad sea layers" should mean reusing that
shader family across three or four long moving bands, not authoring a new ocean shader — the
difference from Chapter 1 is scale and layout, not technique.

So the honest count: **1 new rigged character model** (Jonah), **1 shared crowd rig** for the
sailors, **1 pose-swap variant of the same rig** for Nineveh, **1 large creature** on Chapter 4's
existing animal-construction technique with a new swim state machine adapted from `camp_owl.gd`,
and roughly a dozen new procedural props — no new water shader, no new environment GLB.

## How it looks

The chapter moves through the strongest colour change in the volume: sunlit terracotta harbour,
slate and turquoise storm, deep indigo prayer, pale gold shore, then rose-and-cream Nineveh. Wonder
Light's amber glow is the thread through every state.

### The first view

The camera begins above Joppa's quay. The eye should land in this order:

1. The Nineveh road sign pointing inland.
2. Jonah standing between the road and the ship.
3. The ship's cream sail and ochre-red hull.
4. The rolled message lying near the road.
5. Sailors preparing a calm departure.

The sea is blue and inviting at first. No storm appears until the ship is away from shore.

### Colour and atmosphere

| Place | Palette | Emotional purpose |
|---|---|---|
| Joppa | Terracotta, cream sail, turquoise water | Choice and departure |
| Storm | Slate-blue waves with white paper edges | Serious but readable danger |
| The deep | Indigo, muted turquoise and one amber light | Quiet prayer, not horror |
| Shore | Pale gold, sea green and cream | Relief and another chance |
| Nineveh | Rose limestone, faded blue cloth, green shade plant | A real community God cares about |

Rain and waves remain layered paper shapes with ink outlines. There is no photoreal water, black
void or flashing white lightning.

### Characters

**Jonah.** A middle-aged traveller with a strong nose, short dark curls and a compact beard. His
clothes are dusty indigo over muted ochre, distinct from David, Jonathan and Noah. His connected rig
needs expressive shoulders and hands because much of the story is reluctance, prayer and honest
frustration. He is serious and sometimes stubborn, never a slapstick figure.

**The sailors.** Three figures are enough to represent the crew: an older captain, a younger deck
hand and a broad rope-handler. Their clothing uses sea green, cream and rust. They work together and
show concern for Jonah. No ethnic caricature, pirate styling, eye patches or comic panic.

**The people of Nineveh.** Small family and market groups in varied muted colours. They are people
capable of responding, not a faceless evil crowd. A single close family can carry the change while
the rest of the city shifts through tableau poses.

**The great fish.** A huge rounded paper silhouette, closer to a gentle whale-like fish shape than a
monster but without insisting on a biological species. It has a small calm eye, broad fins and no
visible teeth. Its outline moves slowly beneath the layered water. The cutaway is abstract blue
paper space: no ribs, stomach texture, slime or digestive imagery.

**Wonder-Walker and Wonder Light.** The Wonder-Walker helps with safe tasks but never causes Jonah's
fall or controls God's mercy. Wonder Light stays visible as a small warm guide in the deep.

### The world, piece by piece

- **Joppa quay:** broad stone steps, two mooring posts, folded nets and one clear gangway. Nets never
  block the child or resemble traps.
- **Ship:** one mast, cream sail, low cabin and enough deck width for movement. The rail stays high
  and the child cannot fall overboard.
- **Sea:** three or four long paper bands moving at different speeds. During the storm they rise but
  never cover the whole screen.
- **Fish cutaway:** appears as if the top paper layer has lifted to reveal a protected blue chamber.
- **Shore:** smooth wet sand, a few shells and the open Nineveh road.
- **Nineveh:** rose gate, cloth shades, clay water jars and families. Avoid exotic excess or an evil
  colour code.
- **Shade hill:** a small overlook outside the city, with one fast-growing broad-leaf plant. Its
  withering is shown as folding leaves, not rot or infestation.

### World geometry, concretely

Following `kings_camp.gd`'s pattern of placing everything relative to one reference point per
panel (illustrative distances, to be tuned against the actual camera once built, not final
coordinates):

- **Three panels laid out left to right** (Joppa/ship, deep/shore, Nineveh/shade hill), each with
  its own local origin rather than one continuous coordinate space — matching the doc's "only the
  active panel carries full animation and collision," which only works cleanly if each panel can be
  built, walked and torn down independently.
- **The ship's deck** is the tightest playable footprint in the chapter — a rail-bounded rectangle
  narrow enough that Secure the Cargo's three outlined spaces are always in view together, wide
  enough that the child's walk between them doesn't feel like pacing a corridor.
- **The fish's rise point** sits just past the ship's stern, in the same sightline the camera holds
  after Jonah "steps behind a foreground wave" — so the reveal doesn't require a camera cut to find
  it, the same discipline Chapter 4 applied to the ark's window/dove sightline.
- **The prayer chamber** is a separate, small, enclosed footprint (per **Asset inventory**'s
  cutaway note) — it only needs to hold Jonah, Wonder Light and three guided lights in one
  intimate, static composition, not support walking.
- **Nineveh's gate and shade hill** sit close enough together that the "final question" beat
  (Jonah under the plant, city visible below) doesn't need a panel change mid-reflection.

### What the camera is looking at

- **Choice at Joppa:** wide enough to hold both the Nineveh sign and the ship behind Jonah.
- **Conversation:** close on Jonah with the road soft over one shoulder and sail over the other.
- **Storm:** stable three-quarter deck view with a fixed horizon reference. The camera eases rather
  than copying every wave.
- **Jonah and the sea:** Jonah disappears behind a foreground wave; the camera stays with the sailors
  until the water settles, then looks down at the fish silhouette.
- **Prayer:** intimate side view with Jonah and Wonder Light, no looming fish anatomy.
- **Release:** exterior shore view; the fish opens behind a wave and Jonah comes forward safely.
- **Nineveh:** city gate and responding families, with Jonah part of the scene rather than a giant
  preacher above them.
- **Final question:** Jonah beneath the plant with Nineveh visible below.

### Never in the picture

- The player or sailors throwing Jonah, a button labelled "Throw," or a fall viewed from above.
- Jonah drowning, gasping underwater or being chased.
- Teeth, tongue, stomach walls, bones, slime or digestion jokes.
- Screaming sailors, lightning flashes, violent camera shake or a capsizing ship.
- Nineveh shown as a monstrous or ethnically caricatured city.
- Jonah reduced to a coward joke or the fish treated as punishment alone.
- The story ending when Jonah leaves the fish; Nineveh and God's mercy must remain.
- God voiced as a booming character invented for spectacle.

## The two new interactions, in detail

Unlike Chapter 4, where all three interactions needed real new engineering, this chapter is
lighter: one is close to a direct reuse, and the other extends an existing component rather than
inventing a new one.

### Secure the Cargo, in detail

This is close to a direct reuse of Chapter 3's Prepare the Welcome, not a new system:

- **Carry and place** reuse that component's "floating beside the walker" carry state and
  automatic ease-in at a marked spot exactly as specified there — three cargo pieces, three
  outlined spaces on deck, no wrong placement possible by construction (an outline only accepts its
  matching piece).
- **What's different here, and worth naming:** the ship is rising and falling the whole time
  (**Colour and atmosphere**'s storm state), so the placement outlines need to stay visually locked
  to the deck rather than to a fixed screen position — a small but real difference from the
  courtyard's static table, worth a specific check during implementation rather than assuming the
  component ports over with zero changes.
- **No fail state, no timer, no order requirement** — matching every other placement activity in
  the game so far.
- **Purpose, per the doc:** this activity exists to give the child "a safe, constructive action
  while the adults speak," not to be a puzzle — its low novelty is a feature, not a gap. Spending
  new engineering effort here would be effort spent on the wrong problem.

### Prayer in the Deep, in detail

This is new, but it should extend `word_chip.gd` rather than replace it:

- **The three prayer lights** (Call, Hear, Go) reuse `word_chip.gd`'s established language almost
  entirely: the next light breathes to invite a tap, a tapped light pops with a ring and sparkles,
  and a lit light keeps its own soft glow — the same behaviour already proven for Chapter 1's
  "Don't. Be. Afraid." and Chapter 2's Knit/Loved/Friend.
- **What's genuinely new** is the "guide toward Wonder Light" motion after a tap: once lit, a light
  should drift from where the child tapped it toward Wonder Light's position over roughly a second,
  rather than simply changing colour in place — this is what makes the activity read as *prayer
  reaching toward someone* rather than a third instance of the same verse-word tap. A short eased
  drift (the same quadratic-bezier language used for the dove and the fish, not a new curve type)
  keeps the visual vocabulary consistent across chapters rather than adding a fourth kind of motion
  curve to the codebase.
- **Order and pacing:** the doc's beat list implies Call, then Hear, then Go — but per **Band**,
  "the sea sequence advances even if the child stops touching the screen," so this activity should
  auto-advance on a gentle timer if the child doesn't tap, the same idle-assist principle Steady
  Hands already uses (a breath completes on its own after 7 idle seconds) rather than leaving the
  scene stalled.
- **No fail state.** A light cannot be mis-tapped since there is only one correct next light at a
  time, following the same "next word breathes" cueing `word_chip.gd` already uses to make the
  correct action obvious without instruction text.

## Animation and motion polish

This chapter carries the same rigidity risks the last two named, plus one the earlier chapters
didn't have to solve: an actual accessibility motion setting, not just a calm default.

**Reduced motion needs a real toggle, not just a calm default.** The doc requires it explicitly
("A reduced-motion setting should also reduce wave travel and remove any deck tilt while keeping
the narrative intact" — **What you hear across the journey**), and nothing like it exists anywhere
in the codebase yet. The pattern to follow already exists, though: `GameSettings.read_aloud` and
`GameSettings.easy_words` are simple boolean settings, each with its own `CheckBox` in the pause
menu (`game_menu.gd`) and its own persisted value. A `GameSettings.reduced_motion` toggle, wired
the same way, is the concrete shape of this work — not a new settings architecture, just one more
flag through the existing one.

**Jonah needs more than the shared module's baseline, and that should be named as a real
requirement, not assumed away.** `chapter_two_character_motion.gd`'s `breath()`/`listening_nod()`/
`speaking_pulse()` are the right starting point (as for Noah in Chapter 4), but the doc calls for
Jonah to carry "reluctance, prayer and honest frustration" — an emotional range wider than any
character built so far, including Jonathan, who already needed his own asymmetric-gesture fix on
top of the shared baseline. Budget for Jonah needing authored motion beats layered on top of the
shared module for specific moments (the admission at beat 3, the prayer at beat 7), not just the
shared idle/conversational layer running underneath everything uniformly.

**The storm-to-calm transition when Jonah enters the sea should be one felt crossfade, not an
audio cue with an unrelated visual cut.** The sound table already commits to "storm drops quickly
to a low water hush" the moment Jonah enters the sea — the wave bands' speed and height need to
ease down on the same timeline as that audio drop, the same lighting/`Environment`-crossfade
discipline Chapter 4 recommended for its own weather-state changes, applied here to a faster,
more dramatic beat rather than a slow morning-to-afternoon shift.

**The sailors need idle life while Jonah and Wonder Light talk, and while the child works through
Secure the Cargo** — the same gap Chapter 3 flagged for the seven brothers and Chapter 4 flagged
for waiting animal pairs. Three sailors standing frozen during two of this chapter's dialogue-heavy
beats would be its most visible rigidity risk, for the same reason: they're the ones on screen the
longest doing nothing in the current spec.

**Nineveh's pose-swap crowd (Asset inventory) needs a brief cross-fade between poses, not a hard
snap.** A pose-swap technique is the right cost tier for a background crowd seen from a distance,
but an instant snap between "turned away" and "turned toward" will read as a slideshow rather than
a response — a short tween (perhaps 0.4-0.6s) between poses keeps it feeling like people changing
their minds rather than frames flipping.

**The shade plant's growth and withering both need to be eased motion, not an instant scale
change.** Nothing precedent-wise exists for "a plant that visibly grows" in this codebase, so this
is genuinely new, but cheap: a smooth scale/height tween from small to full size for growth, and
for withering, individual leaf blobs folding or lowering in sequence rather than the whole plant
shrinking uniformly — folding reads as "wilting," uniform shrinking reads as "disappearing," and
the doc is explicit that withering must not read as rot or infestation either way.

**The fish's rise and any submerge should ease in and out, matching the arrival easing `camp_owl.gd`
already uses for landing** — worth stating explicitly alongside the swim-state-machine reuse in
**Asset inventory**, since an abrupt appear/disappear would undercut the calm, non-frightening
reveal the whole characters section is built around.

**The sail and nets should use the existing wind-cloth shader family, not new physics.** The doc's
own "carries over as-is" list already names "camp wind and cloth principles for sails and
clothing" — worth pointing at the concrete asset (`kings_camp.gd`'s `FLAG_SHADER`, already proven
for cloth lift in wind) rather than leaving "principles" undefined.

## What you hear across the journey

| Sound | Behaviour | Likely `sound_library.gd` entry |
|---|---|---|
| Harbour | Small waves, rope against wood, sparse gulls and one distant market bed | `STREAM`-family water, new `GULLS` ambience |
| Ship | Timber creak, sail cloth and calm hull water; positioned around the deck | reuses Chapter 4's `HULL_CREAK`-style sfx |
| Storm | Wind and rain rise slowly; no thunder crack near the listener | `WIND` variant plus Chapter 4's new `RAIN` ambience, both reused rather than re-authored |
| Cargo activity | Rope wrap, wood set-down and cloth bundle, each soft and distinct | new `ROPE_WRAP`, reuses Chapter 4's `PEG_TAP`-style wood sound, new `CLOTH_BUNDLE` |
| Sea change | Storm drops quickly to a low water hush when Jonah enters the sea | a scripted crossfade between the storm and calm `STREAM`-family beds, not a new asset — see **Animation and motion polish** |
| Great fish | Deep filtered water swell and fin movement, not a monster roar | new `FISH_SWELL` sfx, low-pass filtered |
| Prayer | Low water pulse, three glassy notes and Jonah's voice clearly above them | new `PRAYER_PULSE` ambience, three new `LIGHT_*` tonal cues on the same tier as Chapter 3's word-chip tap sound |
| Shore | Gentle surf, wet footsteps and one returning seabird | reuses harbour water and a new `"wet_sand"` `SURFACES` entry |
| Nineveh | Soft market movement that falls silent for Jonah's message | new `MARKET` ambience |
| Shade plant | Leaf unfurl, dry fold and a small reflective harp phrase | new `LEAF_UNFURL`, `LEAF_FOLD` sfx |
| Music | Plucked oud-like strings at Joppa, deep pad in prayer, warmer strings at Nineveh | a new arrangement per panel, the third chapter running its own musical identity after Chapter 4 |

The storm mix needs strict loudness and frequency limits. Voice must remain at least as clear as it
is in Chapters 1 and 2. As with Chapter 4's rain, gulls, market ambience and the fish's water swell
are cases where the project's own synthesis caution applies — budget for credited CC0 source
recordings rather than assuming synthesis will read as convincing, and log every one in
`assets/audio/CREDITS.md`.

A reduced-motion setting should also reduce wave travel and remove any deck tilt while keeping the
narrative intact — see **Animation and motion polish** for the concrete `GameSettings` shape this
should take.

## Voice design

**Two new voice profiles are definite; Nineveh is a decision to make, not just a role to cast.**
Every other chapter's crowd (Chapter 3's brothers, Chapter 4's family) got zero dedicated voices,
carried instead by Wonder Light or the chapter's own named characters — Nineveh should default to
the same pattern unless testing shows a real need for its own voice. That keeps the cast at 9
presets (Juno, Bram, Dylan, Samuel, Jesse, Noah, Noah's wife, Jonah, Captain) rather than 10-11.

| Role | Voice | Status |
|---|---|---|
| Wonder Light | Juno | Existing, unchanged. Narrates God's direction and the dangerous transitions |
| Jonah | **New preset, TBD** | Adult male, warmth under reluctance, capable of prayer without theatrical booming — must not resemble Dylan's Jonathan or Bram's David, and needs the widest emotional range of any new voice so far (avoidance, fear, prayer, obedience, frustration) without ever becoming frightening |
| Captain | **New preset, TBD** | Older male, two short compassionate lines — needs a clear ear-test against Samuel and Noah, the cast's other "older male" voices, following the same distinctness discipline Chapter 4 applied to Noah against Samuel |
| Nineveh | **Decision needed, default: none** | The doc allows "one adult and one child acknowledgement," but per the pattern above, defaulting to Wonder Light narrating Nineveh's response (as she already does for Jesse's brothers and Noah's family) is the cheaper, more consistent choice unless a real-child playtest specifically asks for Nineveh's own voice |

**Casting process**, continuing the same discipline as every prior chapter: 2-3 candidate presets
per role, auditioned against the *entire* existing cast (Juno, Bram, Dylan, Samuel, Jesse, Noah,
Noah's wife), not just the two or three most similar voices — this chapter's cast is now large
enough that a new voice needs to be checked against everyone, not just its closest neighbours.

**Clip budget, by precedent.** The draft script below runs to 19 standard lines — 14 Wonder Light,
4 Jonah, 1 Captain — close to Chapter 4's 18-line scale despite this chapter having more story
beats (11, versus Chapter 4's 9): most of the extra beats are carried by Wonder Light narrating
transitions rather than by new dialogue, and Nineveh's default of no dedicated voice
(**Who is talking**) keeps the speaking cast small. Plus Easy Words duplicates for the
youngest-facing subset, **call it 22-26 new clips**.

Jonah needs the most voice testing of the new cast because the same profile must carry avoidance,
fear, prayer, obedience and frustration without becoming frightening. Easy Words variants are
required for the storm explanation and God's final question.

## Who is talking

The same `dialogue_view.gd` extension pattern as Chapters 3 and 4:

- **`SPEAKERS`** needs a new colour entry for Jonah (dusty indigo/muted ochre, matching his cloth)
  and one for the Captain (sea green/cream, matching the sailors' palette). No entry is needed for
  Nineveh unless **Voice design**'s default is overturned.
- **`_draw_face()`** needs two new small icons — Jonah's dark curls and compact beard (distinct at
  a glance from Noah's fuller beard and Samuel's short one — the cast now has three bearded older
  male-adjacent characters, so the icons carry real disambiguation weight, not just decoration),
  and the Captain's plainer, older sailor's face.
- **The speaker-detection list** needs `"Jonah"` and `"Captain"` added.
- **No entry for the sailors as a group or for Nineveh** (pending the voice decision above) — same
  "no individual lines, no tag" logic as Chapter 3's brothers and Chapter 4's family.

## Draft script (for timing and casting, not final)

A speaker-labelled pass through the eleven story beats, wording only — not reviewed for theology,
not checked against either candidate verse (Jonah 2:2 / Jonah 4:2), and not through an Easy Words
pass. Written in the same short, present-tense register as the other chapters' scripts.

| # | Speaker | Line | Beat |
|---|---|---|---|
| 1 | Wonder Light | "Noah trusted God before he could see the rain. Jonah heard God too — but Jonah ran the other way." | 1. Arrive at Joppa |
| 2 | Wonder Light | "Nineveh is that way. Jonah's ship is going the other way." | 1. Road and ship |
| 3 | Wonder Light | "Find Jonah's bag, his message, and his lamp." | 2. Find travelling things |
| 4 | Jonah | "I know where God wants me to go. I don't want to go there." | 3. Meet Jonah |
| 5 | Wonder Light | "Let's help secure the cargo before the storm." | 5. Secure the Cargo |
| 6 | Captain | "Hold on. This storm isn't like the others." | 5. Storm tableau |
| 7 | Jonah | "This storm is because of me. I was running from God." | 6. Jonah admits it |
| 8 | Wonder Light | "The sailors didn't want to. But the sea grew calm." | 6. Jonah enters the sea |
| 9 | Wonder Light | "God appointed a great fish to keep Jonah safe." | 6. The fish rises |
| 10 | Wonder Light | "Call. Hear. Go. Let's pray with Jonah." | 7. Prayer in the Deep |
| 11 | Jonah | "You heard me. Thank you for another chance." | 7-8. Prayer, then release |
| 12 | Wonder Light | "The fish set Jonah safely on the shore." | 8. Another chance |
| 13 | Wonder Light | "Now Jonah goes to Nineveh, just as God asked." | 9. Walk to Nineveh |
| 14 | Jonah | "Nineveh — forty days, and this will all change." | 9. The warning |
| 15 | Wonder Light | "The people of Nineveh listened. They turned away from harm." | 9. Families respond |
| 16 | Wonder Light | "Jonah cared about the plant. God cared about a whole city of people." | 10. The final question |
| 17 | Wonder Light | "God gave Jonah another chance. God cared for the people Jonah did not want to forgive." | 11. Reflect |
| 18 | Wonder Light | "A Mercy charm, for another chance, and for a city God would not give up on." | 11. Charm |
| 19 | Wonder Light | "Keep it close. Mercy is for the person who needs a second chance, and for the ones we'd rather not forgive." | 11. Charm, closing |

That is 14 Wonder Light lines, 4 Jonah, 1 Captain — heavier on Jonah than Chapter 4 was on Noah,
matching this chapter's higher beat count and Jonah's wider required emotional range, and
consistent with **Voice design**'s default of no dedicated Nineveh voice (its beats are carried by
Wonder Light, lines 9 and 15). Line 4 and line 7 are the two places that range is most
load-bearing and worth the earliest possible read-through with a candidate voice.

## Decided

- The title and dialogue say Great Fish; store metadata may mention the familiar whale title once.
- Mercy is the value and includes both Jonah and Nineveh.
- The child never throws Jonah or controls a dangerous act.
- The inside of the fish is abstract, calm and non-anatomical.
- The story continues through Nineveh and God's final lesson; rescue is not the ending.
- The chapter closes the first five-journey volume.

## Improve pass before implementation

1. Lock the verse after testing Jonah 2:2 and Jonah 4:2 aloud with the target age group.
2. Have a Bible-story reviewer check what is narrated, what is compressed and how the ending of
   Jonah remains an open question rather than a falsely tidy conversion for Jonah.
3. Prototype deck movement with reduced motion enabled and test it with motion-sensitive adults and
   children.
4. Storyboard the sea transition so Jonah's danger is understood without showing drowning or making
   the child responsible.
5. Test the fish silhouette and cutaway with children for fear, confusion and accidental comedy.
6. Time the harbour, storm, prayer, Nineveh and plant beats; cut dialogue before cutting the mercy
   ending.
7. Audition Jonah and Captain voices against the full existing cast (Juno, Bram, Dylan, Samuel,
   Jesse, Noah, Noah's wife), not just the first three — the cast is large enough now that a new
   voice can collide with any of them, not only the most obvious neighbours.
8. Test the entire chapter on tablet speakers; storm and water must never mask narration.
9. Decide the first-volume completion reward after all five charms can be viewed together. It should
   celebrate the journey without adding an unrelated currency or store prompt.
10. Build `GameSettings.reduced_motion` on the existing `read_aloud`/`easy_words` pattern (its own
    `CheckBox` in `game_menu.gd`, its own persisted value) before prototyping deck movement
    (Improve-pass item 3) — the setting needs to exist before it can be tested.
11. Extend `dialogue_view.gd`'s `SPEAKERS`, `_draw_face()` and speaker-detection list for Jonah and
    the Captain before recording any lines — see **Who is talking**.
12. Settle the Nineveh-voice decision (**Voice design**) before locking the script or the speaker
    tag list — it changes the clip budget, the cast size and whether `dialogue_view.gd` needs a
    third new entry.
13. Confirm `journal_content.gd`'s `MYSTERY_SLOTS` drops to 0 once this chapter's `CHARM_MERCY` is
    added, assuming Chapters 3 and 4's charms already exist (5 earned charms + 0 mystery slots = 5)
    — the same kind of check Chapters 3 and 4 each needed, with a different answer each time, so
    it is worth verifying fresh here rather than assuming a pattern.
14. Build idle life into the sailors during Jonah's dialogue beats and Secure the Cargo, and use a
    real cross-fade (not a hard snap) between Nineveh's tableau poses — see **Animation and motion
    polish**.
