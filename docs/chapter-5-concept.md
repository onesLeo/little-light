# Chapter 5 — Jonah and the Great Fish

This is the fifth planned journey and the ending of the first store-release volume. The familiar
name is often "Jonah and the whale," but the Bible says that God appointed a great fish. The game
uses **Great Fish** in its title and dialogue; parent-facing store text may mention the familiar name
once for recognition. The chapter is not built yet. Experience, timing and acceptance notes are in
[chapter-5-polish.md](chapter-5-polish.md).

## Where chapter 4 leaves off

Chapter 4 ends under the rainbow with the Trust charm. The handoff is one camera move: the rainbow's
blue band widens into the sea, the ark settles into a distant paper silhouette, and a small ship is
already waiting at Joppa. The road God asked Jonah to take points the other way.

Movement stays locked through Wonder Light's first line, the same way Chapter 2 locks the camp
arrival. She names the place first. She names the choice only after the sign, Jonah and the ship are
in frame: "This is Joppa." Then, "Nineveh is that way. Jonah is looking at the ship."

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

**Verse:** World English Bible, confirmed against [Jonah 4](https://ebible.org/eng-web/JON04.htm) and
[Jonah 2](https://ebible.org/eng-web/JON02.htm) before recording. The played quotation is only the
mercy clause of Jonah 4:2, because the rest of that verse is Jonah's complaint and the next verse
asks to die. That request is never spoken or shown. The clause is recorded exactly: "you are a
gracious God and merciful, slow to anger, and abundant in loving kindness." Wonder Light's meaning
is a separate card. Jonah 4:11 stays in the journal as the full question. Jonah 2:2 may join it
after a read-aloud test. Jonah 2:10 is not on the default read-aloud path. See
[chapter-5-polish.md](chapter-5-polish.md).

**New charm:** Mercy. A small warm light held safely between two curved dark-blue waves. It must read
as shelter and another chance, not as Jonah trapped in teeth.

## The story, and what the child does

1. **Arrive at Joppa.** The quay is quiet, so the sign, Jonah and the ship read in that order.
   Walking is locked for the first line. Wonder Light names Joppa, then the two directions.
2. **Find Jonah's three travelling things:** his small bag, a rolled message and an oil lamp. These
   are the only cargo later. The message turns inland once and can say "Nineveh." The sign says the
   same word. Jonah keeps looking toward the ship.
3. **Meet Jonah.** Jonah admits that he does not want to go. His reluctance is real and his choice
   is wrong. He is not a comic coward.
4. **Board the ship.** One short gangway walk. The bag, message and lamp sit on the deck beside
   Jonah. The coast folds away.
5. **Storm tableau.** The captain speaks as the paper waves begin to rise. The child places the same
   three things into outlined spaces on the deck, by a drag or by a tap, with keyboard and gamepad
   too. About seven seconds of stillness eases the next piece into place. There is no fail state.
6. **Jonah enters the sea.** The child does not push or throw him, and the child stays on the deck.
   Jonah admits he was running. Wonder Light says this is Jonah's story and God still keeps him safe.
   Jonah steps behind a foreground wave. Waves, wind and rain ease down together. The captain says
   the crew is safe. The great fish then rises past the stern, larger than the ship, and the ship
   stays outside it.
7. **Prayer in the Deep.** A lit paper page lifts in front of the child. Jonah is on a dry curved
   platform in an abstract blue room. The child taps **Call**, **Hear** and **Go**. Each word is
   spoken and drifts toward Wonder Light. The same short idle assist completes a waiting light.
8. **Another chance.** The fish lets Jonah come forward onto a bright shore. No spit sound and no
   humiliating animation. The message opens toward Nineveh.
9. **Walk to Nineveh.** The child carries the message and walks with Jonah for a short road to the
   gate. Jonah's warning is understandable: turn back, God sees. Families answer by a hand opening
   and people turning toward each other.
10. **God cares for Nineveh.** The shade hill is in the same view as the city. The plant grows, then
    folds leaf by leaf. Jonah says he wanted the plant to stay, and he does not cheer up on cue.
    Wonder Light asks whether God should care about a whole city. The child taps **Care**. The camera
    rests on the living city.
11. **Receive the Mercy charm.** The reflection names both directions of mercy. The first time this
    profile earns the fifth charm, a volume page shows all five charms and the lit Faith Journey.

## Band

Band A is the volume-1 chapter. It uses three cargo outlines and three prayer lights, each with a
spoken word and its own icon, plus one Care light at the plant. Cargo and prayer idle-assist one
step after about seven seconds. The story beats around them wait for the child. Touch, keyboard and
gamepad can all finish both activities.

Band B may later let the child choose which part of the story shows mercy—Jonah's rescue, the
sailors' safety or Nineveh's forgiveness. Every choice would receive a true explanation. Band B is
not a build task for this volume. Every child gets Band A.

## Where it happens

This chapter uses one fold-out paper world with three connected panels rather than three unrelated
levels:

1. **Joppa and the ship:** a quiet sun-warmed quay on the left.
2. **The deep and shore:** layered blue paper sea in the centre. One shared strip of that sea also
   belongs to the ship, so the fish can rise past the stern without a camera cut. The prayer cutaway
   is a page lifted in front of the deck, not a place the child enters.
3. **Nineveh and the shade hill:** pale stone city and dusty road on the right, close enough to share
   one view.

Only the active panel carries full animation and collision. The others flatten into distant
story-page silhouettes. The coast-folding transition covers a panel change so it does not feel like
a load. This controls memory and helps the child understand that the story has moved.

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

- **Jonah** — a new `generate_jonah_v1.py`, wrapping the same `generate_wonder_walker_v5.py` base
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
  small `CLOTH`/`SKIN`/`HAIR` colour arrays. The deck hand and rope-handler are two `look` indices
  with a rope coil as the prop difference. The captain shares that body and gets his own head,
  because he speaks and his dialogue icon has to separate him from Jonah, Samuel and Noah.
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

The camera begins above Joppa's quiet quay. The valley's high tabletop follow is the wrong default
for a deck, so this chapter adds its own shots. The opening eye should land in this order:

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

**Jonah.** A middle-aged traveller with a stronger nose bridge, short dark curls and a compact beard,
at the same paper proportions as David and Jonathan. His clothes are dusty indigo over muted ochre.
His connected rig needs five readable hand poses: arms at his sides, hands on the rail, open prayer
hands, arms folded under the plant, and hands open toward the city. He is serious and sometimes
stubborn. He does not become a joke, and he does not smile the lesson away at the end.

**The sailors.** Three figures are enough: an older captain with his own head, a younger deck hand
and a broad rope-handler. Their clothing uses sea green, cream and rust. They keep a small work idle
during dialogue and cargo. They work together and show concern for Jonah. No ethnic caricature,
pirate styling, eye patches or comic panic.

**The people of Nineveh.** Small family and market groups in varied muted colours. They are people
capable of responding, not a faceless evil crowd. A single close family can carry the change while
the rest of the city shifts through tableau poses.

**The great fish.** A huge rounded paper silhouette, closer to a gentle whale-like fish shape than a
monster but without insisting on a biological species. It is larger than the ship, with a small calm
eye, broad fins and no visible teeth. The eye does not stare into the camera. The ship stays outside
the silhouette. The cutaway is a dry abstract blue paper room: no ribs, stomach texture, slime or
digestive imagery.

**Wonder-Walker and Wonder Light.** The Wonder-Walker helps with safe tasks, stays on the deck, and
never causes Jonah's step into the sea or controls God's mercy. Wonder Light is already visible as
a small warm guide when the prayer page starts to lift.

### The world, piece by piece

- **Joppa quay:** broad stone steps, two mooring posts, folded nets and one clear gangway. Keep it
  quiet. Nets never block the child or resemble traps. Market crowds belong to Nineveh.
- **Ship:** one mast, cream sail, low cabin and enough deck width for movement. The rail stays high
  and the child cannot fall overboard.
- **Sea:** three or four long paper bands moving at different speeds. During the storm they rise but
  never cover the whole screen.
- **Fish cutaway:** a lit paper page lifts in front of the deck and reveals a protected blue chamber.
  Wonder-Walker is still standing with the sailors.
- **Shore:** smooth wet sand, a few shells and the open Nineveh road.
- **Nineveh:** rose gate, cloth shades, clay water jars and families. Avoid exotic excess or an evil
  colour code.
- **Shade hill:** a small overlook in the same view as the city, with one fast-growing broad-leaf
  plant. Its withering is folding leaves. The worm in Jonah 4:7 stays off the played scene. The last
  frame favours the living city, with the folded plant still visible.

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
- **The prayer chamber** is a page in front of the deck, not a floor the child walks into. It holds
  Jonah, Wonder Light and three guided lights in one intimate composition. The child taps from the
  deck.
- **Nineveh's gate and shade hill** sit close enough together that the "final question" beat
  (Jonah under the plant, city visible below) doesn't need a panel change mid-reflection.

### What the camera is looking at

- **Choice at Joppa:** wide enough to hold both the Nineveh sign and the ship behind Jonah.
- **Conversation:** close on Jonah with the road soft over one shoulder and sail over the other.
- **Storm:** stable three-quarter deck view with a fixed horizon reference. The camera eases rather
  than copying every wave.
- **Jonah and the sea:** Jonah disappears behind a foreground wave; the camera stays with the sailors
  until the water settles, then looks down at the fish silhouette.
- **Prayer:** the lifted page, with Jonah and Wonder Light inside it and no looming fish anatomy.
- **Release:** exterior shore view; Jonah comes forward from behind a wave.
- **Nineveh:** city gate and responding families, with Jonah part of the scene rather than a giant
  preacher above them. This is the warmest, longest hold in the chapter.
- **Final question:** Jonah beneath the plant with Nineveh visible. The last frame favours the city.

### Never in the picture

- The player or sailors throwing Jonah, a button labelled "Throw," or a fall viewed from above.
- The child inside the sea or the fish, or the ship shown swallowed.
- Jonah drowning, gasping underwater or being chased.
- Teeth, tongue, stomach walls, bones, slime, digestion jokes or a spit sound. Jonah 2:10 stays off
  the default read-aloud path.
- Jonah asking to die, from Jonah 4:3 or 4:8.
- A worm, rot or infestation on the plant.
- Screaming sailors, crying children, lightning flashes, violent camera shake or a capsizing ship.
- Nineveh shown as a monstrous or ethnically caricatured city.
- Jonah reduced to a coward joke, or made cheerfully converted in the last shot.
- The story ending when Jonah leaves the fish; Nineveh and God's mercy remain.
- God voiced as a booming character invented for spectacle.
- A shipped line left on system text-to-speech, or an activity panel left over the verse.

## The two new interactions, in detail

Unlike Chapter 4, where all three interactions needed real new engineering, this chapter is
lighter: one is close to a direct reuse, and the other extends an existing component rather than
inventing a new one.

### Secure the Cargo, in detail

This is close to a direct reuse of Chapter 3's Prepare the Welcome, not a new system:

- **Carry and place** reuse that component's "floating beside the walker" carry state and
  automatic ease-in at a marked spot exactly as specified there. The three pieces are the bag, the
  message and the lamp already found. Each outline shows that object's icon and accepts only its
  match. Colour is not the only cue.
- **What's different here, and worth naming:** the ship is rising and falling the whole time
  (**Colour and atmosphere**'s storm state), so the outlines are parented to the deck rather than
  drawn as a screen panel. They stay below the dialogue bar and never cover a face or a verse.
  Touch may drag. Touch, keyboard and gamepad may also tap a piece and then tap its outline.
- **No fail state, no timer, no order requirement.** About seven seconds without a touch eases the
  next piece into place. The story beats around the activity do not skip themselves.
- **Purpose, per the doc:** this activity exists to give the child "a safe, constructive action
  while the adults speak," not to be a puzzle — its low novelty is a feature, not a gap. Spending
  new engineering effort here would be effort spent on the wrong problem.

### Prayer in the Deep, in detail

This is new, but it should extend `word_chip.gd` rather than replace it:

- **The three prayer lights** (Call, Hear, Go) reuse `word_chip.gd`'s established language almost
  entirely: the next light breathes to invite a tap, a tapped light pops with a ring and sparkles,
  and a lit light keeps its own soft glow — the same behaviour already proven for Chapter 1's
  "Don't. Be. Afraid." and Chapter 2's Knit/Loved/Friend. The spoken clip is that single word, and
  the label matches it: "Call." "Hear." "Go."
- **What's genuinely new** is the "guide toward Wonder Light" motion after a tap: once lit, a light
  drifts toward Wonder Light over roughly a second. The lights live on the lifted page, already lit
  with Wonder Light's amber glow. A short eased drift uses the same quadratic-bezier language as the
  dove and the fish.
- **Order and pacing:** Call, then Hear, then Go. If the child does not tap, the next light completes
  on its own after about seven idle seconds, the same principle as Steady Hands. That assist does
  not skip the shore, the road or the verse.
- **Care** is a fourth chip later, at the plant, not part of this trio and not a second three-word
  game. Its clip is "Care."
- **No fail state.** Only the next light breathes. Dismiss and free the page before any verse card.

## Animation and motion polish

This chapter carries the same rigidity risks the last two named, plus one the earlier chapters
didn't have to solve: an actual accessibility motion setting, not just a calm default.

**Reduced motion needs a real toggle, not just a calm default.** It reduces wave travel, removes
deck tilt and ducks wind and rain while the fish rise, the prayer and the mercy ending stay. Nothing
like it exists in the codebase yet. The pattern to follow already exists, though: `GameSettings.read_aloud`
and `GameSettings.easy_words` are simple boolean settings, each with its own `CheckBox` in the pause
menu (`game_menu.gd`) and its own persisted value. A `GameSettings.reduced_motion` toggle, wired
the same way, is the concrete shape of this work — not a new settings architecture, just one more
flag through the existing one. Build it before prototyping the deck.

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
| Harbour | Small waves, rope against wood, one gull crossing once. No market bed here | `STREAM`-family water, one `GULLS` pass |
| Ship | Timber creak, sail cloth and calm hull water; positioned around the deck | reuses Chapter 4's `HULL_CREAK`-style sfx |
| Storm | Wind and rain rise slowly; no thunder crack near the listener | `WIND` variant plus Chapter 4's new `RAIN` ambience, both reused rather than re-authored |
| Cargo activity | Rope wrap, wood set-down and cloth bundle, each soft and distinct | new `ROPE_WRAP`, reuses Chapter 4's `PEG_TAP`-style wood sound, new `CLOTH_BUNDLE` |
| Sea change | Storm drops quickly to a low water hush when Jonah enters the sea | a scripted crossfade between the storm and calm `STREAM`-family beds, not a new asset — see **Animation and motion polish** |
| Great fish | Deep filtered water swell and fin movement, not a monster roar | new `FISH_SWELL` sfx, low-pass filtered |
| Prayer | Low water pulse, three glassy notes and Jonah's voice clearly above them | new `PRAYER_PULSE` ambience, three new `LIGHT_*` tonal cues on the same tier as Chapter 3's word-chip tap sound |
| Shore | Gentle surf, wet footsteps and one returning seabird | reuses harbour water and a new `"wet_sand"` `SURFACES` entry |
| Nineveh | Soft market movement that falls silent for Jonah's message | new `MARKET` ambience |
| Shade plant | Leaf unfurl, dry fold and a small reflective harp phrase | new `LEAF_UNFURL`, `LEAF_FOLD` sfx |
| Music | The volume's plucked strings and pads. Prayer sits lower. Nineveh is the warmest | a new arrangement per panel, using the existing instrument family |

The storm mix needs strict loudness and frequency limits. Voice must remain at least as clear as it
is in Chapters 1 and 2. Footsteps change with the ground: quay stone, deck wood, wet sand, dusty
road. The three finds use the usual pickup chime once each. The message unrolls once and shares a
"Nineveh." clip with the road sign. Activity sounds go silent before the verse card. As with Chapter
4's rain, gulls, market ambience and the fish's water swell are cases where the project's own
synthesis caution applies — budget for credited CC0 source recordings rather than assuming synthesis
will read as convincing, and log every one in `assets/audio/CREDITS.md`.

A reduced-motion setting reduces wave travel, removes deck tilt and ducks wind and rain, while
keeping the narrative intact — see **Animation and motion polish** for the concrete `GameSettings`
shape this should take. The full mix checklist is in
[chapter-5-polish.md](chapter-5-polish.md).

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
| Captain | **New preset, TBD** | Older male, exactly two compassionate lines: the storm, and "We are safe." Needs a clear ear-test against Samuel and Noah, the cast's other older male voices |
| Nineveh | **Decision needed, default: none** | The doc allows "one adult and one child acknowledgement," but per the pattern above, defaulting to Wonder Light narrating Nineveh's response (as she already does for Jesse's brothers and Noah's family) is the cheaper, more consistent choice unless a real-child playtest specifically asks for Nineveh's own voice |

**Casting process**, continuing the same discipline as every prior chapter: 2-3 candidate presets
per role, auditioned against the *entire* existing cast (Juno, Bram, Dylan, Samuel, Jesse, Noah,
Noah's wife), not just the two or three most similar voices — this chapter's cast is now large
enough that a new voice needs to be checked against everyone, not just its closest neighbours.

**Clip budget, by precedent.** The draft script below runs to 22 spoken lines — 15 Wonder Light,
5 Jonah, 2 Captain — plus five short word clips: "Call." "Hear." "Go." "Care." "Nineveh." Easy
Words duplicates for the safety line, the plant question and the two charm lines bring the new-clip
range to about 30. Every shipped line is recorded. A missing clip must not drop its dialogue block
onto system text-to-speech.

Jonah needs the most voice testing of the new cast because the same profile must carry avoidance,
admission, prayer, the warning and frustration without becoming frightening. Direct those five lines
separately. Easy Words variants are required for the safety line, the plant question and the charm
lines. Drafts are in [chapter-5-polish.md](chapter-5-polish.md).

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

A speaker-labelled pass through the eleven story beats, in the same short present-tense register as
the other chapters. Word taps are extra clips, not extra rows: "Call." "Hear." "Go." "Care." and
"Nineveh." The mercy clause of Jonah 4:2 is a verse card, not one of these lines. Easy Words drafts
are in [chapter-5-polish.md](chapter-5-polish.md). A Bible-story reviewer still needs to accept the
compressions listed under **Decided**.

| # | Speaker | Line | Beat |
|---|---|---|---|
| 1 | Wonder Light | "This is Joppa." | 1. Arrive |
| 2 | Wonder Light | "Nineveh is that way. Jonah is looking at the ship." | 1. The choice, after the picture |
| 3 | Wonder Light | "Find Jonah's bag, his message, and his lamp." | 2. Find travelling things |
| 4 | Jonah | "I know where God wants me to go. I don't want to go there." | 3. Meet Jonah |
| 5 | Wonder Light | "The waves are rising. Let's secure Jonah's things." | 5. Cargo, as the storm begins |
| 6 | Captain | "Hold on. This storm isn't like the others." | 5. Storm tableau |
| 7 | Jonah | "This storm is because of me. I was running from God." | 6. Jonah admits it |
| 8 | Wonder Light | "This is Jonah's story. God still keeps him safe." | 6. Immediately after the admission |
| 9 | Wonder Light | "The sailors didn't want to let him go. Then the sea grew calm." | 6. Jonah enters the sea |
| 10 | Captain | "We are safe." | 6. Sailors' mercy |
| 11 | Wonder Light | "God appointed a great fish to keep Jonah safe." | 6. The fish rises |
| 12 | Wonder Light | "Call. Hear. Go. Let's pray with Jonah." | 7. Prayer in the Deep |
| 13 | Jonah | "You heard me. Thank you for another chance." | 7-8. Prayer, then release |
| 14 | Wonder Light | "The fish set Jonah safely on the shore." | 8. Another chance |
| 15 | Wonder Light | "Carry the message. Now Jonah goes to Nineveh, just as God asked." | 9. Walk to Nineveh |
| 16 | Jonah | "Nineveh, turn back. God sees what you are doing." | 9. The warning |
| 17 | Wonder Light | "The people of Nineveh listened. They turned away from harm." | 9. Families respond |
| 18 | Jonah | "I wanted the plant to stay." | 10. The plant |
| 19 | Wonder Light | "Jonah cared about one plant. Should God care about a whole city?" | 10. The question |
| 20 | Wonder Light | "God gave Jonah another chance. God cared for the people Jonah did not want to forgive." | 11. Reflect |
| 21 | Wonder Light | "A Mercy charm, for another chance, and for a city God would not give up on." | 11. Charm |
| 22 | Wonder Light | "Keep it close. Mercy is for the person who needs a second chance, and for the ones we'd rather not forgive." | 11. Charm, closing |

That is 15 Wonder Light lines, 5 Jonah, 2 Captain. Nineveh still has no dedicated voice. Lines 4, 7,
16 and 18 are the ones that need the earliest read-through, because they carry refusal, admission,
the warning and frustration. Line 8 follows line 7 immediately, so the admission does not hang as a
threat to the child.

## Decided

- The title and dialogue say Great Fish; store metadata may mention the familiar whale title once.
- Mercy is the value and includes Jonah, the sailors and Nineveh.
- The child never throws Jonah, never enters the sea or the fish, and never controls a dangerous act.
- The bag, message and lamp are the cargo. They stay visible as they move through the chapter.
- The inside of the fish is a lit paper page in front of the deck: abstract, calm and non-anatomical.
- The plant folds. The worm is not staged. Jonah's wish to die is not spoken.
- Jonah is still unhappy about the plant at the end. The lesson is not a tidy conversion.
- The story continues through Nineveh. The city gets the warmest, longest picture. The fish is the middle.
- The played scripture is the mercy clause of Jonah 4:2. The full question and any prayer passage live in the journal.
- The chapter closes the first five-journey volume. The volume page plays once per profile, with no store prompt.
- Acceptance detail lives in [chapter-5-polish.md](chapter-5-polish.md).

## Improve pass before implementation

1. Read the Jonah 4:2 mercy clause and the plant question aloud with the target age group. Keep Jonah
   2:2 in the journal only if "Sheol" is clear enough. Do not put Jonah 2:10 or Jonah 4:3 on the
   default read-aloud path.
2. Have a Bible-story reviewer check the compressions: the worm omitted from the picture, the
   death-wish lines omitted, the warning shortened, the storm framed as Jonah's story rather than a
   threat to the child, and Jonah left honestly unhappy at the end.
3. Prototype deck movement with reduced motion enabled and test it with motion-sensitive adults and
   children. Reduced motion also ducks wind and rain.
4. Storyboard the sea transition: Jonah steps behind a wave, the child stays on the deck, the sailors
   are shown safe, and the fish rises past the stern with the ship still outside it.
5. Test the fish silhouette, the prayer page and the folding plant with children for fear, sadness,
   confusion and accidental comedy. Ask whether the child can say that God gave Jonah another chance
   and still cared about the city.
6. Time a full play against the minute budget in [chapter-5-polish.md](chapter-5-polish.md). If it
   runs long, shorten the gangway and extra narration before cutting the sailors, the road, Nineveh,
   the plant question, Care or the charm.
7. Audition Jonah and the Captain against the full existing cast (Juno, Bram, Dylan, Samuel, Jesse,
   Noah, Noah's wife). The captain's two lines have to clear Samuel and Noah. Direct Jonah's five
   lines separately.
8. Test the entire chapter on tablet speakers at about half volume: voices only, ambience only, sound
   muted, and read-aloud off. Storm and water must never mask narration.
9. Play the first-time volume page with all five charms visible. It celebrates the journey and does
   not add a currency or a store prompt. A replay of this chapter shows the ordinary end card.
10. Build `GameSettings.reduced_motion` on the existing `read_aloud`/`easy_words` pattern (its own
    `CheckBox` in `game_menu.gd`, its own persisted value) before prototyping deck movement
    (Improve-pass item 3).
11. Extend `dialogue_view.gd`'s `SPEAKERS`, `_draw_face()` and speaker-detection list for Jonah and
    the Captain before recording any lines — see **Who is talking**. Every script line uses the
    exact `Speaker: "..."` prefix.
12. Keep Nineveh on Wonder Light's voice for volume 1 (**Voice design**). Reopen a Nineveh voice only
    if a family playtest asks for one.
13. Confirm `journal_content.gd`'s `MYSTERY_SLOTS` drops to 0 once this chapter's `CHARM_MERCY` is
    added, after checking whatever Chapters 3 and 4 actually shipped (5 earned charms + 0 mystery
    slots = 5). Verify the count. Do not assume it.
14. Build idle life into the sailors during Jonah's dialogue and Secure the Cargo, and cross-fade
    Nineveh's tableau poses over about half a second — see **Animation and motion polish**.
15. Follow [chapter-5-polish.md](chapter-5-polish.md) for the time budget, scenery, camera shots,
    Jonah's hand poses, input paths, sound, verse card and the definition of polished.
16. Give Secure the Cargo a tap-then-tap path for touch, keyboard and gamepad, and parent the
    outlines to the deck so they cannot cover the dialogue or the verse.
17. Add a headless chapter review that can reach the charm with idle assist, confirms the verse card
    appears with no activity panel left up, and confirms reduced motion leaves the deck level.
18. When the chapter script exists, extend the smoke test so every new clip loads and every Easy
    Words original remains a substring of that script.
19. Light Joppa and Nineveh with a daytime sun. In the storm, darken the sky and the waves and keep
    faces paper-warm.
20. Approve Jonah's close-up poses and the captain's face before recording voice.
