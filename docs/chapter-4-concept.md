# Chapter 4 — Noah's Ark

This is the fourth planned journey and the first to leave David's life. It opens the Faith Journey
into a wider collection of Bible stories while keeping the same play pattern, paper-diorama style
and calm, fail-free interaction. A greybox now plays on `feat/chapter-4`: the plain, the hull,
the three building items, one panel, six paper animal pairs, the dove, the rain and the rainbow.
Final models are still ahead. The `ark_` voice clips are temporary readings so the journal can
speak; replace them when Noah, his wife and Wonder Light are recorded.

## Where chapter 3 leaves off

Chapter 3 gives the child a Faithful Heart charm and closes the remembered beginning of David's
story. The Faith Journey then opens onto a much older page: a broad plain, an enormous wooden shape
and small animals arriving from both sides.

Wonder Light says, "Long before David, God asked Noah to trust him and build something no one had
seen before."

## The story: Noah builds the ark

**Bible passage:** Genesis 6–9.

The world has become full of violence and harm. God tells Noah to build an ark and bring his family
and the animals inside. Noah does what God says. The rain comes, God keeps those inside the ark safe,
the water eventually goes down, and a dove returns with an olive leaf. God sets the rainbow as the
sign of his covenant.

The flood cannot be presented merely as a cheerful animal parade, but its destruction must not be
shown to young children. Wonder Light can name the brokenness in one simple line: "People were
hurting one another, and the world was full of violence." The playable story then stays with Noah's
trust, the work of building, God's protection and the covenant.

**Value:** Trust. Obedience is visible in Noah's actions; trust explains why he continues before he
can see the rain or the rescue.

**Verse:** Genesis 9:13 (WEB), verified before the script is locked. Genesis 6:22 can be paraphrased
in the building sequence: Noah did all that God commanded him.

**New charm:** Trust. A small rainbow over one dark-blue water line. Wonder Light explains that the
rainbow is the sign of God's promise, not a prize Noah earned.

## The story, and what the child does

1. **Arrive on the plain.** The ark's frame rises above Noah and his family. Wonder Light names the
   long work and the reason Noah trusts God.
2. **Find three building items:** a wooden mallet, a coil of rope and a sealed jar of pitch. The child
   brings them to the marked work area.
3. **Meet Noah.** Noah thanks the Wonder-Walker and says, "I cannot see the rain yet. I can trust the
   One who told me what to do."
4. **Finish one ark panel.** A short fail-free activity places three pegs and draws one rope tight.
   Every action visibly strengthens the same section of the hull.
5. **Two by Two.** Six representative animal pairs arrive in small waves. The child guides three
   animals to their mates; those pairs walk up the ramp, and the other three join the short boarding
   montage. Any attempted mismatch pauses and offers another visual clue; there is no wrong sound or
   animal left behind.
6. **The door closes.** Noah's family enters. God closes the door in the narration; the child does
   not shut anyone out.
7. **Rain montage.** The camera moves to a warm ark cutaway while rain travels over the paper roof.
   Wonder Light says that the water covered the land and God kept Noah's family and the animals safe.
   No disaster is visible outside.
8. **Wait and watch.** The child opens a small window, sends the dove and watches it return first
   without a leaf, then later with an olive leaf. Time passes through turning paper sky layers.
9. **Dry ground and rainbow.** The family and animals leave into a washed, bright morning. The verse
   is heard and the Trust charm is received.

## User-experience pass

Chapter 4 has the widest story arc and the largest cast so far. Its UX priority is to make the scale
feel generous without making the child repeat every action the story implies. The full journey
should still fit the roadmap's **8–12 minute** target on a first playthrough, including spoken lines.

### Pacing budget

| Beat | Target | UX limit |
|---|---:|---|
| Arrival and three building items | 1:30–2:00 | The first item is close and acts as the tutorial; hints begin early enough that searching never stalls |
| Meet Noah and finish one panel | 1:15–1:45 | Three auto-snapping pegs and two short rope pulls; about 40 seconds of direct activity |
| Two by Two | 1:45–2:15 | Three child-guided pairs; three more pairs board during a short living-world montage |
| Door and rain transition | 0:45–1:15 | One reassuring line, then a smooth cutaway transition; no long unskippable weather shot |
| Dove and passing time | 1:00–1:30 | Two immediate send/return cycles separated by a child-triggered paper-sky turn, never real waiting |
| Dry ground, verse, reflection and charm | 1:30–2:00 | Verse split into short read-aloud pages, then one concise word interaction and reward |

This leaves room for normal walking and a little child hesitation while keeping the likely total near
9–11 minutes. If a prototype exceeds 12 minutes, reduce repetitions before shortening spoken Bible
context.

### One control language

Every new action uses the same large context button already used by the earlier chapters. Its label
changes to match the immediate verb: **PICK UP**, **PLACE**, **PULL**, **RELEASE**, **GUIDE**,
**OPEN**, **SEND** or **NEXT**. Keyboard and gamepad use the same interaction action; touch never
requires dragging a small animal or peg precisely.

For Two by Two, pressing **GUIDE** beside an animal makes it follow the Wonder-Walker at a gentle
pace. Reaching the correct partner completes the match automatically. Do not depend on collision
nudging: it is unclear on keyboard/gamepad, easy to trigger accidentally and gives no obvious state
change on touch.

Only the current objective is shown. The building-item checklist fades out before the panel
activity; the animal-pair counter appears only when Two by Two begins. This avoids stacking two
checklists and dialogue over an already busy scene.

### Teach, then let the child do it

- **First building item:** begins within the initial camera view. Wonder Light names the picture and
  the checklist row pulses once.
- **Pitch jar:** Wonder Light calls it “sticky pitch that keeps water out” the first time; *pitch*
  alone is unfamiliar to many children.
- **First peg:** its socket glows softly and the carried peg snaps into a generous target.
- **First animal pair:** Noah's wife walks beside the child for a few steps and the matching partner
  answers with a quiet call. The second and third pairs remove that extra guidance.
- **First mismatch:** the guided animal pauses, looks toward its real mate and calls; Wonder Light
  says, “This friend is looking for its match.” There is no error sound. After a second mismatch or
  four idle seconds, the matching silhouette pulses and an edge arrow appears if it is off-screen.

Stage animals in three small waves rather than showing twelve equally active animals at once. This
keeps the mobile view readable, reduces accidental selection and lets the waiting area feel alive
without becoming visual noise. Six pairs still appear and enter the ark; the child actively guides
three representative pairs, while the other three follow during the boarding montage.

### No awkward waiting

The chapter depicts a long wait without making the player wait. After the first dove returns, the
line begins positively: “The dove came back safe. The water is still too high.” A large **TURN THE
SKY** / **NEXT** prompt advances paper sky layers, water height and window light. The second send is
then immediately available. Idle time only plays breathing, animal and water motion; it never gates
progress.

All story camera holds expose **NEXT** after the spoken line has had time to begin. Replay can show
the full animation again, but returning from pause or a checkpoint must not force a child to repeat
the rain montage.

### Verse and meaning

Split Genesis 9:13 across two short read-aloud pages if the final verified wording does not fit at
the established tablet text size. Follow it with the three tappable words **RAINBOW**, **SIGN** and
**PROMISE**. Wonder Light explains *covenant* in child language: “God's covenant is a promise God
chooses to keep.” The words may be tapped in any order, speak when touched, and never mark an answer
wrong.

### Camera, sound and recovery

- Keep the top-down Two by Two camera centred on the guided animal and its possible destinations,
  with the normal look-around range available. Do not shrink all twelve animals into one overview.
- Keep rain visually present but lower its high frequencies and volume before every voice line. The
  owl lesson from Chapter 2 applies in reverse here: this ambience must remain felt without hiding
  the words.
- Save at the end of item finding, panel building, Two by Two, the rain transition and the verse.
  Resume at the latest completed beat with its environment state restored.
- The pause menu's **Play again** equivalent for an unfinished chapter should restart the current
  activity, not silently erase ten minutes of progress.
- Test every interaction with read-aloud on, Easy Words on, touch-only input and a child who does
  not read the button label.

## Band

Band A uses colour, silhouette and sound to match animal pairs. Each pair has at least two cues, such
as shape plus coat pattern, so colour vision is never the only clue.

Band B may later include more pairs and tracks leading toward the correct partner. It must not add a
timer, limited moves or consequences for mismatch.

## Where it happens

The main environment is a broad dry plain with distant low hills and one enormous ark under
construction. The chapter has three controlled visual states rather than three full worlds:

1. **Building:** warm dry afternoon around the exterior and ramp.
2. **Rain:** the same ark shown as a paper cutaway, warm inside and blue-grey outside.
3. **New morning:** wet earth, a few shallow reflections, an olive sprout and a wide rainbow.

The playable area stays near one side of the ark. The full vessel extends beyond the frame so it
feels large without requiring an explorable ship.

## What carries over as-is

- Wonder-Walker, Wonder Light, profiles, checklist, controls and accessibility settings.
- The chapter state pattern, item collection, camera director and end sequence.
- The charm journal and colouring system.
- Existing sheep animation and some animal-life behaviours as starting points.
- Paper wind, cloth movement, particle limits and audio ducking.

## What is new work

- A large modular ark exterior, ramp and warm cutaway interior (runtime paper-prop construction,
  the way `kings_camp.gd` builds the ridge — see **Asset inventory** below), plus a five-stop
  Faith Journey map state (tracked separately as backlog 7.8).
- Two new rigged character models (Noah, Noah's wife) and one new shared low-cost crowd rig
  instanced for the six background sons-and-wives figures. See **Asset inventory**.
- Six animal pairs. Not twelve rigs: sheep and goats can share the existing lamb-style soft-blob
  quadruped construction with new proportions; rabbits are a smaller variant of the same technique;
  doves reuse the camp owl's flight rig almost directly; elephants and giraffes need their own new
  profile curves (very different body plans) but the same soft-blob/profile *technique*, not new
  tooling. See **Asset inventory**.
- New paper props for the building activity (mallet, rope coil, pitch jar, three work stations)
  and for staging (ramp, work area markers, animal waiting circles, window frame) — see **Asset
  inventory**.
- Three new interactions, none of which has an existing equivalent: Finish one ark panel (peg + rope
  tightening), Two by Two (guide a moving pair together), and the dove send-and-return. See **The
  three new interactions, in detail**.
- Three environment states (Building, Rain, New morning) on one space, not three separate scenes —
  see **Where it happens** and **Animation and motion polish** for how the transitions should feel,
  not just look.
- Trust charm journal art and a 3D charm. Once Chapter 3's `CHARM_FAITHFUL_HEART` exists,
  `journal_content.gd`'s `MYSTERY_SLOTS` must drop from 2 to 1 when `CHARM_TRUST` is added (4 earned
  + 1 mystery slot = 5, matching the five-journey roadmap) — unlike Chapter 3, where the constant
  needed no change. Worth its own Improve-pass item so the two chapters aren't assumed to behave
  the same way here.
- Two new voice profiles (Noah, Noah's wife) and roughly 20-24 new recorded clips, plus their Easy
  Words duplicates — see **Voice design** and **Draft script**.
- New morning/rain ambience and interaction sounds. Rain, in particular, has no existing precedent
  in the codebase (unlike most other new sound in this chapter) and needs its own speech-masking
  test on a tablet speaker before anything else — see **What you hear around the ark**.
- Two new entries in the "who is talking" name tag (`dialogue_view.gd`) for Noah and Noah's wife —
  see **Who is talking**.
- Idle-life and secondary-motion work beyond the base rigs and props — see **Animation and motion
  polish**. As with Chapter 3, none of it is a new technique to invent; the codebase now has a real
  shared conversational-motion module (`chapter_two_character_motion.gd`) built for Chapter 2 that
  this chapter should reuse directly rather than reinvent.

## Asset inventory: models, rigs and props

The same two-tier approach used for Chapter 3 (and, before that, the King's Camp) applies here,
plus a third tier this chapter is the first to need: procedurally built quadrupeds.

**Tier 1 — rigged, shape-keyed, camera-ready.** For anyone the child sees in close-up with a
speaking line, following the David/Jonathan/Samuel pipeline (`generate_wonder_walker_v5.py` base,
wrapped by a per-character generator script):

- **Noah** — a new `generate_noah_v1.py`. New geometry: grey-brown textured hair and a full beard
  (fuller than Samuel's short one — Noah reads as a working man, not a visiting elder), broad
  connected hands with a "measuring/lifting" hand pose available as a shape key, a muted rust robe
  over cream with a dark work belt. `Blink`/`Talk` shape keys.
- **Noah's wife** — a new `generate_noahs_wife_v1.py`. New geometry: a female body proportion
  variant of the same base (the codebase has no existing female rig outside placeholder meshes, so
  this is genuinely new construction, not a recolour), deep-teal and warm-sand cloth, hair tied
  back for work. `Blink`/`Talk` shape keys — she has real lines (**Draft script**), so she needs
  the same facial range as Noah, not a silent-background treatment.

**Tier 2 — lightweight, unrigged, crowd-ready (the camp-guard pipeline).** For the six sons and
their wives: one new `noahs_family.gd`, built exactly like `camp_guard.gd` and Chapter 3's
`jesse_sons.gd` — a pivot-hierarchy body with no bones and no face rig, visual variety from small
`CLOTH`/`SKIN`/`HAIR` colour arrays and a `look` index, each instance carrying supplies, guiding an
animal or securing the ramp rather than idling in a line. This is the right tier for them: the doc
is explicit that "the chapter does not need eight close-up faces."

**Tier 3 — animals, a genuinely new construction pattern for this chapter.** The lamb Wonder Item
already proves the technique: `build_lamb()` (`generate_david_mentor_v4.py`) is a soft-blob body
(`ww.blob`, fused with `ww.fuse`) plus four simple leg profiles (`ww.profile`) and blob ears/eyes —
cheap, small, and already tablet-tested. That technique, not the lamb's specific proportions,
generalises across the six pairs:

| Pair | Built from | Cost |
|---|---|---|
| Sheep | The existing lamb soft-blob body, new wool colour/pattern | Near-zero — closest reuse of the existing asset |
| Goats | Same soft-blob technique, new proportions (leaner body, small horns as blob additions) | Low |
| Rabbits | Same technique, smaller scale, longer ear blobs | Low |
| Doves | The camp owl's flight rig (`camp_owl.gd`) reused almost directly: same glide/wingbeat/perch state machine, new (smaller, lighter) proportions and colour | Low — this is the strongest single reuse in the whole chapter |
| Elephants | New profile curves on the same blob/fuse/profile technique — big body, trunk as a tapered profile, large ear blobs | Higher — genuinely new silhouette, but not new tooling |
| Giraffes | New profile curves — long neck as an extended profile chain, patch pattern via material | Higher — same reason as elephants |

Each pair needs only one shared build (a "look" or side parameter for the two-of-a-kind variation
the doc already asks for — ear angle, patch placement), not two full separate models, matching how
Chapter 2's guards vary from one script.

**New paper props (`camp_paper.gd`-style primitives, not GLB assets):** wooden mallet, rope coil,
sealed pitch jar, three work-station markers, the ramp, animal-waiting ground circles and water
bowls, the window frame, and the rainbow's broad paper bands. The ark hull itself (ribs and planks)
is the one environment piece worth checking against the tablet performance budget early
(Improve-pass item 3) — it is the largest repeated-geometry structure any chapter has attempted, larger than the camp's tents or Chapter 3's house wall.

**Reused as-is, zero new cost:** ground/rock variants and paper wind/cloth shaders already in
`kings_camp.gd`, and the `chapter_two_character_motion.gd` conversational-motion module for
Noah and his wife (see **Animation and motion polish**).

So the honest count: **2 new rigged character models** (Noah, Noah's wife), **1 shared crowd rig**
for the six sons-and-wives figures, **6 new animal pairs** (2 near-free reuses, 2 low-cost variants,
2 higher-cost new silhouettes, all on one existing technique), and roughly a dozen new procedural
props — no new environment GLB.

## How it looks

The chapter begins with sun-baked ochre and timber brown, turns to layered slate blue during the
rain, then opens into clean blue-green morning. The changing palette carries time and emotion. The
ark remains warm wood throughout, so it reads as shelter rather than a dark box.

### The first view

The Wonder-Walker enters beside a stack of squared timbers. The camera is low enough for the ark to
rise out of frame. The eye should land in this order:

1. Noah fitting a peg into the hull.
2. The immense curved ribs of the unfinished ark.
3. The broad ramp pointing toward the entrance.
4. Two small animals waiting together at a distance.
5. The three missing tools placed around the safe work area.

The horizon remains open and bright. There is no storm cloud in the first view.

### Colour and weather

| State | Palette | Movement |
|---|---|---|
| Building | Ochre earth, honey-brown timber, pale blue sky | Dust motes, rope and clothing in a dry breeze |
| Animals arrive | Same warmth with more cloth and coat colours | Ears, tails, heads and slow paired walking |
| Rain | Slate-blue paper sky, silver rain, amber ark interior | Rain sheets, roof drips and gentle hull rocking |
| Waiting | Softer blue with pale light through the window | Dove wings and slow water movement |
| New morning | Clean cream sun, wet green shoots and a soft rainbow | Animals step out, puddles ripple, leaves lift |

The rainbow uses broad matte paper bands. It is not neon, transparent glass or a laser across the
sky.

### Characters

**Noah.** An older working man with sun-warmed skin, grey-brown hair and beard, broad connected hands
and a practical stance. His robe is muted rust over cream with a dark work belt. He carries no staff
of authority. His animation shows measuring, lifting and resting a hand on the wood. His expression
is steady, sometimes tired, never smug while others are judged.

**Noah's wife.** A capable partner in deep teal and warm sand, organising food baskets and checking
the animal path. She has at least one short spoken line so she is not scenery.

**Sons and their wives.** Six lightweight figures working in pairs in the mid-ground. Shared rigs and
materials keep the cost reasonable; varied clothes, hair and jobs keep them from looking cloned.
They carry supplies, guide animals and secure the ramp. The chapter does not need eight close-up
faces.

**Animals.** Begin with six readable pairs: sheep, goats, doves, rabbits, elephants and giraffes.
They are paper-diorama animals rather than realistic zoo models. Each pair shares a silhouette but
has one small harmless variation such as ear angle or patch placement. Scale is compressed so large
animals fit the scene, but their relative size remains understandable.

**Wonder-Walker and Wonder Light.** Unchanged. Wonder Light stays near the child's shoulder during
the rain montage rather than flying into the storm.

### The ark and plain, piece by piece

- **Ark hull:** repeated timber ribs and broad planks with black ink seams. Detail density stays low;
  scale comes from repetition and framing.
- **Work area:** three clear stations for mallet, rope and pitch, outside the animal route.
- **Ramp:** wide, shallow and unobstructed. Pairs never bunch up or clip through one another.
- **Animal waiting areas:** soft ground markings and water bowls, never cages.
- **Interior cutaway:** amber beams, stacked food baskets, clean straw and pairs resting in alcoves.
  It is spacious enough to avoid a trapped feeling.
- **Window:** the one strong rectangle of cool light during the rain, used for the dove activity.
- **Dry ground:** a simple new sprout and olive branch, not an instant lush jungle.

### Plain and ark geometry, concretely

Following `kings_camp.gd`'s pattern of one clearing centre with everything placed relative to it
(illustrative distances, to be tuned against the actual camera once built, not final coordinates):

- **The playable footprint stays close to one side of the ark**, not its full length — a strip
  roughly 10-12m long against the hull, wide enough for the work area, the ramp and the animal
  waiting circles without crowding, echoing the doc's own "the full vessel extends beyond the
  frame."
- **Three work stations** (mallet, rope, pitch) sit outside the animal route, so the building
  activity and Two by Two never compete for the same ground.
- **The ramp** is the widest single path any chapter has needed — pairs must never bunch or clip,
  so it should be noticeably wider than the camp's or courtyard's walking paths, with the animal
  waiting circles set back far enough from its base that an arriving pair has clear room before
  its "go" cue.
- **The window** sits on the hull wall closest to the tabletop camera's rest position, so the dove
  beat (**The three new interactions, in detail**) doesn't require a camera cut to a wall the child
  has not been oriented toward.
- **The interior cutaway** is a separate, simpler footprint (beams, baskets, straw, alcoves) rather
  than a scaled-down copy of the exterior — it only needs to read as spacious in one held shot, not
  support free walking the way the exterior does.

### What the camera is looking at

- **Arrival:** low wide view that establishes the ark's scale without distorting Noah.
- **Building items:** close, tactile views of wood, rope and sealed pitch; no sharp tools near the
  child's hands.
- **Noah:** medium close-up with the ark ribs behind him and open sky above.
- **Two by Two:** a more top-down tabletop view so all matching spaces are visible.
- **Door:** viewed from inside with warm family silhouettes as the light narrows gently.
- **Rain:** stable cutaway view. The horizon never tilts and the camera does not shake.
- **Dove:** the camera follows only to the window, then lets the bird cross the paper sky.
- **Rainbow:** widest view of the chapter, with family, animals and ark all small beneath it.

### Never in the picture

- Drowning people or animals, bodies, hands outside the ark or a town being destroyed.
- Panicked crowds, anyone pounding on the door, or the child closing the door.
- Lightning striking nearby, violent camera shake or a black horror sky.
- Predators stalking prey, animal fighting, cages or cramped piles of animals.
- Noah celebrating other people's destruction.
- A claim that exactly one pair of every animal is a complete literal inventory. The scene is a
  representative procession, while narration follows the passage without turning it into arithmetic.
- A rainbow presented as Noah's reward rather than God's covenant sign.

## The three new interactions, in detail

None of these three has an existing equivalent in the codebase. Steady Hands (hold/release
breathing) and the friendship cord (hold/release looping) are the closest relatives for the
building activity; nothing existing resembles guiding a moving pair together or sending a bird
out and watching it return, so those two need a fuller spec.

### Finish one ark panel, in detail

- **Peg placement** borrows the "carry, then release at a marked spot" language Chapter 3's
  Prepare the Welcome introduces (a floating-beside-the-walker carry, then an automatic ease-in at
  each of three marked peg points on one hull panel) — reuse that component rather than building a
  second placement system from scratch.
- **The rope pull** is new: a Steady-Hands-style hold-and-release, but instead of a breathing ring
  it visibly draws two rope ends together over the panel, tightening in clearly graduated steps
  (not a smooth analog fill) so a child can see it visibly get tighter each pull rather than
  guessing when it's "enough." Use **two short holds** after the three peg placements; three or four
  adds repetition without teaching anything new. Early release preserves progress, exactly as the
  friendship cord does, and the button changes from **PULL** to **RELEASE** when a step is ready.
- **Feedback:** each peg lands with the same wooden-knock sound described in **What you hear around
  the ark**, and the panel visibly strengthens (a colour or texture shift from raw to finished
  timber) as work completes, echoing chapter 2's gift-checklist tick language but expressed on the
  3D object itself rather than only in a UI list.
- **No fail state, no timer, no wrong order** — pegs and rope can be done in any sequence.

### Two by Two, in detail

- **The core problem this activity solves that the others don't:** every previous matching-style
  interaction in this game is the child bringing one held object to one marked spot. Here, two
  living things must find each other, and neither is being carried. The simplest fail-free version:
  the child presses the normal context action beside one waiting animal, changing the button to
  **GUIDE**, and it walks beside the Wonder-Walker toward its silhouette-matched partner near the
  ramp. Reaching the correct partner completes the match automatically. Wrong pairings pause and
  offer the next clue rather than producing an error state. Do not use physical nudging as the
  input; it is inconsistent across touch, keyboard and gamepad.
- **The clue layers**, concretely: shape/silhouette first (a sheep and a goat read as different
  silhouettes even in the same palette), then coat pattern or ear shape as the second, non-colour
  cue the Band A requirement calls for. A third optional clue — a matching soft call from each
  animal in a pair, ducked under dialogue like the sheep bleat already is — helps a child who is
  looking at the UI rather than the animals.
- **The walk itself** should not be a straight-line slide: reuse `camp_guard.gd`'s "turn toward
  target, animate a walk phase, arrive and settle" logic, even though the guard's own two-legged
  pose data doesn't apply — the leg-swing math needs a quadruped adaptation, but the turning and
  pacing behaviour underneath it is exactly what a guided animal needs, so a pair turns and paces
  like living things, not tokens sliding along a rail.
- **Completion:** once a pair reaches the ramp together, they walk it and enter on their own (no
  further child input needed for that pair), and the checklist-style pair counter ticks — reusing
  the same tick-and-pop language as Chapter 2's and Chapter 3's checklists for continuity across
  all three chapters. Band A asks the child to guide **three** pairs. The remaining three join the
  ramp procession during the short completion montage, so all six are present without six rounds
  of the same input.

### The dove send-and-return, in detail

This is the strongest reuse opportunity in the whole chapter. `camp_owl.gd` already implements
almost exactly this sequence for a different bird: a state machine (`WAITING`/`FLYING`/`PERCHED`)
driving a quadratic-bezier glide path (`_t*t*(3.0-2.0*t)` eased position, a midpoint arc lifted
above the straight line), wingbeats only during takeoff and landing with a long calm glide between,
and a landing/settle state with its own idle blinks and head turns.

- **Send:** the child opens the window (a simple tap/press, no precision needed) and the dove
  launches using the same flight-arc technique, exiting through the window rather than gliding to a
  branch.
- **First return (no leaf):** the same arc in reverse, landing back at the window sill — reuse the
  landing/settle behaviour (wing fold, a few idle blinks) so the "nothing yet" beat still feels
  alive rather than being a flat non-event. Lead with the successful return (“The dove came back
  safe”) before saying the water is still high, so a young child does not read this as a failed
  action.
- **Passage of time:** the child presses **NEXT** to turn two or three paper sky layers and lower the
  water. This takes a few seconds and has an immediate visual response; there is no timer or idle
  wait before the second send.
- **Second return (with the olive leaf):** identical flight technique, with the leaf attached to
  the dove model for this pass. The moment of the leaf becoming visible should get the same kind of
  small warm emphasis Chapter 3's oil ribbon or Chapter 2's charm-float moments get — a soft
  highlight or a small pause on arrival, not a flat swap.
- **Given the strength of this reuse,** the "observational vs. active" open question in **Decided**
  /Improve-pass item 6 should lean active-but-simple (child triggers send/watches return) rather
  than fully observational — the interaction cost of reusing `camp_owl.gd`'s state machine is low
  enough that making it a real, if tiny, action is close to free.

## Animation and motion polish

Chapter 3's equivalent section made the case from a mostly-doc-level Chapter 2 precedent. That
precedent is now real code (`chapter_two_character_motion.gd`, added in the actual Chapter 2
motion-and-pacing polish pass), which makes several of this chapter's risks cheaper to close than
they were when Chapter 3 was written — the module is intentionally chapter-agnostic (pure
`RefCounted` functions: `speaking_pulse(time)`, `listening_nod(time)`, `breath(time)`), built
specifically so a new rig can reuse the same conversational rhythm without copying Jonathan's
geometry.

**Noah and his wife should drive their idle/conversational motion directly from
`chapter_two_character_motion.gd`, not a new hand-tuned equivalent.** Their dialogue beats are
short (**Draft script**), which makes it tempting to skip breathing/nod/gesture motion as
"not worth it for two lines" — that is exactly backwards, since a short line delivered by a
motionless rig reads as more robotic than a long one, not less. Reuse `breath()` for idle sway,
`listening_nod()` while each hears the other, and `speaking_pulse()` to drive a small one-sided
gesture while talking, the same asymmetric-gesture fix Chapter 2's actual polish pass made to
Jonathan (the old symmetric two-armed lift "looked robotic"; the fix was a single-handed lead
gesture) — Noah should get the same asymmetry, not the older, already-rejected pattern.

**Six animal pairs standing in a waiting area is this chapter's version of Chapter 3's seven
motionless brothers.** Nothing in the current doc specifies idle motion for a pair waiting to be
guided — only the moment of walking to the ramp. A field of frozen animal models would be the
stiffest thing in the chapter, worse than the brothers' case because there are more of them and
they are meant to read as alive, not as a respectful line of people. At minimum: slow breathing
(scale pulse, the same idea as the lamb's own idle motion), an occasional head turn or ear flick,
and a tail movement where the species has one — small, cheap, per-instance-randomized motion, not
a shared synchronized loop (synchronized idle motion across six pairs would itself look
artificial, like a chorus line rather than living animals).

**Boarding the ramp needs staggered, not uniform, timing.** Once guided together, six pairs
walking to the ramp on identical cadence will read as a conveyor belt — the same risk Chapter 3
flagged for the brothers' procession, and the same fix applies: a small randomized per-pair offset
in when each pair starts its walk and how it paces, rather than firing all six on the same clock.

**The rope-tightening activity needs visibly graduated feedback, not a smooth analog fill.** This
is already specified in **Finish one ark panel, in detail** — worth repeating here because it is
the chapter's other hold-and-release mechanic besides Two by Two's animal-guiding, and the whole
point of graduated steps (versus Steady Hands' continuous breathing ring) is that "getting
tighter" needs to visibly click forward, or it will feel like nothing is happening across the
whole hold.

**The three environment-state transitions (Building → Rain → New morning) need to be felt
crossfades, not hard cuts.** The colour table already commits to three distinct palettes, but
nothing in the doc says how the game moves between them. Chapter 2 already solved an analogous
problem — the transition from the valley's daylight into the camp's blue hour when the child first
climbs the ridge — with its own dedicated lighting/`Environment` crossfade; this chapter's weather
transitions are a direct relative of that problem and should reuse the same class of technique
rather than a jump-cut, especially given the storyboarding concern already flagged in Improve-pass
item 5.

**The rainbow should bloom into place, not appear.** As the visual and emotional climax of the
chapter (and the widest shot in the doc — **What the camera is looking at**), an instant pop-in
would undercut the moment more than almost anything else here could. Chapter 3 recommends the same
fix for its oil ribbon via a `curve_mesh` length/opacity tween; this chapter's rainbow, being
"broad matte paper bands," is a good fit for each band appearing in sequence over a couple of
seconds rather than all seven at once — a small, deliberate reveal matching the doc's own "no
laser across the sky" restraint.

**Puddle reflections in the New morning state should ripple, not sit flat.** "A few shallow
reflections" (**Colour and weather**) risks reading as a static mirrored texture if left
unspecified. The meadow's stream already has a subtle animated-water shader; the same family of
technique, toned down to a still-puddle scale, would keep the wet ground from looking like a
painted-on effect rather than standing water.

**The dove's motion is already the strongest point in the chapter** — see **The three new
interactions, in detail** for why `camp_owl.gd`'s existing flight/perch state machine is close to
a direct reuse. No further note needed here beyond confirming it should stay that grounded rather
than being redesigned from scratch.

## What you hear around the ark

| Sound | Behaviour | Likely `sound_library.gd` entry |
|---|---|---|
| Dry wind | Low open-air bed during building; softer near speech | `WIND` variant, reused |
| Timber work | Rounded wooden knocks, peg taps and one rope pull; never metallic construction noise | new `PEG_TAP`, `ROPE_PULL` sfx |
| Ark wood | Occasional low creak tied to visible movement | new `HULL_CREAK` sfx |
| Animals | Sparse, recognisable calls; one pair at a time and silent during dialogue | credited CC0 recordings per species (see below) |
| Footsteps | Dust outside, timber on the ramp and soft straw inside | reuses Chapter 3's `"dust"` surface entry, plus new `"timber"`/`"straw"` entries in `SURFACES` |
| Rain | Begins with individual roof taps, grows to a broad soft wash, ducks strongly under voice | new `RAIN` ambience — no existing precedent; the one sound in this chapter with genuinely nothing to reuse |
| Water | Low movement outside the cutaway, without crashing waves | a quieter variant of `STREAM` |
| Dove | Soft wing flutter leaving and returning; one small coo with the olive leaf | reuses `FLUTTER`, already built for the camp owl |
| Rainbow | Harp harmonics and one warm chime, no triumphant blast | new `RAINBOW_CHIME` sfx, on the same tonal-cue tier as Chapter 3's `LOW_CHIME` |
| Music | Wooden percussion, plucked strings and a slow repeated building rhythm | a new arrangement, not a `meadow_lullaby.wav` variant — this chapter is the first to need its own musical identity rather than a relative of the valley's theme |

The rain must be checked on a tablet speaker. Broadband rain easily masks speech, so it should sit
well below the existing ambience target and lose high-frequency energy during dialogue. Unlike
Chapter 3, where most new sound could be synthesized with `tools/make_sounds.py`, this chapter
leans the other way: animal calls, footsteps on straw/timber and rain are all cases where the
existing sound notes' own caution (synthesized lambs and footsteps sounded false) applies directly
— budget for credited CC0 source recordings as the default here, not the exception, and confirm
every one is logged in `assets/audio/CREDITS.md` before it ships.

## Voice design

**Exactly two new voice profiles are needed** — the cast grows to seven presets (Juno, Bram, Dylan,
plus Chapter 3's Samuel and Jesse, plus Noah and Noah's wife here). Noah's wife is the cast's
**second female voice**, after Juno/Wonder Light — the first time this matters, since every other
named voice so far has been male.

| Role | Voice | Status |
|---|---|---|
| Wonder Light | Juno | Existing, unchanged. Narrates God's instruction rather than inventing a booming disembodied voice for God |
| Noah | **New preset, TBD** | Older warm male, practical and calm; can sound tired during the work but never fearful or self-righteous — must be distinct from Samuel and Jesse (Chapter 3), not just from Bram/Dylan |
| Noah's wife | **New preset, TBD** | Warm adult female, distinct from Juno; two or three purposeful lines, not a silent-background role |
| The six sons and wives | — | No dedicated voice. Background effort sounds only (footsteps, cloth, occasional grunt of effort) — no six additional speaking profiles, matching the doc's existing "Decided"-level intent |

**Casting process**, continuing the same comparison discipline used for Samuel and Jesse: generate
2-3 candidate presets per role, listen against the full existing cast (not just Bram/Dylan), and
reject anything too close to an existing voice — Noah in particular needs a clear ear-test against
Samuel, since both are "warm older male" on paper and risk being interchangeable if cast carelessly.

**Clip budget, by precedent.** Chapters 2 and 3 landed in the high-20s/low-30s for new clips each.
This chapter's dialogue is lighter — Noah gets a few lines, his wife two or three, Wonder Light
carries the narration around the flood, building and covenant beats — so a **draft script of
roughly 18-20 standard lines**, plus Easy Words duplicates for the youngest-facing subset, points
to **20-24 new clips**, the lightest of the three chapters so far. Animal sounds are a separate,
larger question: they require source and licence documentation in `assets/audio/CREDITS.md`, and
weak synthetic substitutes should not be accepted merely to avoid finding appropriate recordings —
see **What you hear around the ark**.

## Who is talking

The same `dialogue_view.gd` name-tag system introduced in Chapter 2 (a small drawn face plus the
speaker's name in their own colour, following whichever line is currently playing) needs the same
kind of extension Chapter 3 specified for Samuel and Jesse:

- **`SPEAKERS`** needs two new colour entries — Noah (rust/cream, matching his robe) and Noah's
  wife (deep teal/warm sand, matching hers).
- **`_draw_face()`** needs two new small icons — Noah's grey-brown hair and full beard (fuller than
  Samuel's short one, so the two "older male" tags stay visually distinct at a glance, not just in
  voice), and Noah's wife's tied-back hair.
- **The speaker-detection list** needs `"Noah"` and a name for his wife added (the script does not
  name her in Scripture; pick a placeholder like "Noah's wife" or a chosen name before locking the
  script, since the exact string must match the `Speaker: "..."` prefix used in every line).
- **The six sons and wives need no entry**, matching the "no dedicated voice" decision in **Voice
  design** — there is no tag to draw for a group with no individual lines.

## Draft script (for timing and casting, not final)

A speaker-labelled pass through the nine story beats, wording only — not reviewed for theology or
checked against the WEB text for Genesis 9:13, and not through an Easy Words pass. Written in the
same short, present-tense register as the other chapters' scripts, so promoting it into `LINES`
later is a copy, not a rewrite.

| # | Speaker | Line | Beat |
|---|---|---|---|
| 1 | Wonder Light | "Long before David, God asked Noah to trust him and build something no one had seen before." | 1. Arrive on the plain |
| 2 | Wonder Light | "People were hurting one another, and the world was full of violence." | 1. Naming the brokenness, once |
| 3 | Wonder Light | "Find the mallet, the rope, and the jar of pitch. Bring them to Noah." | 2. Find building items |
| 4 | Noah | "God told me to build this ark. I cannot see the rain yet, but I trust him." | 3. Meet Noah |
| 5 | Wonder Light | "Let's finish this panel. Three pegs, then draw the rope tight." | 4. Finish one ark panel |
| 6 | Wonder Light | "Two by two, they're coming. Help these animals find their partners." | 5. Two by Two |
| 7 | Noah's wife | "This way. Walk together up the wide ramp." | 5. Two by Two, in-scene guidance |
| 8 | Wonder Light | "Noah's family and the animals are safely inside. God closes the door and keeps them safe." | 6. The door closes |
| 9 | Wonder Light | "The water covered the land. God kept Noah's family, and every animal, safe inside." | 7. Rain montage |
| 10 | Wonder Light | "Let's open the window and send the dove." | 8. Dove, first send |
| 11 | Wonder Light | "The dove came back safe. The water is still too high." | 8. First return, no leaf |
| 12 | Wonder Light | "Look — an olive leaf. The water is going down." | 8. Second return, with leaf |
| 13 | Noah | "Dry ground. Thank you for keeping us safe." | 9. Dry ground |
| 14 | Wonder Light | "Genesis, chapter nine, verse thirteen." | 9. Verse reference |
| 15 | Wonder Light | "I have set my rainbow in the cloud. It will be the sign of the covenant between me and the earth." | 9. Verse text — **draft wording, verify against WEB before recording** |
| 16 | Wonder Light | "The rainbow is a sign of God's covenant — a promise God chooses to keep." | 9. Reflect — explains covenant and protects against a "reward" misreading |
| 17 | Wonder Light | "A Trust charm, for believing what you cannot yet see." | 9. Charm |
| 18 | Wonder Light | "Keep it close. Trust God, even before you see the way through." | 9. Charm, closing |

That is 15 Wonder Light lines, 2 Noah, 1 Noah's wife — Wonder Light carrying most of the narration
as she does in every chapter, while Noah and his wife stay light enough to match **Voice design**'s
"two or three purposeful lines," and the six sons and wives keep their whole presence in motion and
sound rather than dialogue.

## Decided

- Trust is the value and the rainbow is the charm image.
- The chapter spans building, boarding, rain, waiting and covenant; it is not only an animal match.
- The brokenness before the flood is named once but destruction is never shown.
- God closes the door in narration; the child does not exclude anyone.
- Six animal pairs represent the larger procession.
- God is narrated through Scripture and Wonder Light, not played as a character voice.

## Improve pass before implementation

1. Have a Bible-story reviewer check the flood narration, including animal-count wording and the
   distinction between trust, obedience, judgment and covenant.
2. Paper-prototype Two by Two with children and verify shape cues without relying on colour.
3. Benchmark six paired animated species on a low-end Android tablet before final modelling.
4. Test the warm cutaway and rain mix for fear, visual clarity and speech masking.
5. Storyboard the passage of time so the full flood arc fits without feeling rushed.
6. Decide whether the dove interaction is active or observational after testing the chapter length
   — leaning active-but-simple, since reusing `camp_owl.gd`'s flight state machine keeps the cost
   low either way (**The three new interactions, in detail**).
7. Audit every animal recording and voice clip for commercial rights and attribution.
8. Confirm that the rainbow charm remains readable when reduced to the journal icon and bracelet.
9. Extend `dialogue_view.gd`'s `SPEAKERS`, `_draw_face()` and speaker-detection list for Noah and
   Noah's wife before recording any lines, and settle on how she is named in a spoken-line prefix
   — see **Who is talking**.
10. Build animal idle-life (breathing, head turn, tail flick, randomized per instance) into the
    waiting-area animals from the start, not as later polish, and give ramp-boarding a staggered
    per-pair timing rather than a uniform cadence — six frozen or synchronized pairs would be this
    chapter's most visible rigidity risk. See **Animation and motion polish**.
11. Reuse `chapter_two_character_motion.gd` directly for Noah and his wife's idle/conversational
    motion rather than hand-authoring an equivalent, and carry over the asymmetric single-handed
    gesture fix already applied to Jonathan rather than the symmetric pattern it replaced.
12. Confirm `journal_content.gd`'s `MYSTERY_SLOTS` drops from 2 to 1 when `CHARM_TRUST` is added
    (assuming Chapter 3's `CHARM_FAITHFUL_HEART` already exists): 4 earned charms + 1 mystery slot
    = 5. Verify the build order and the constant rather than assuming this chapter behaves like
    Chapter 3, where the constant needed no change.
13. Prototype the rainbow's sequenced-band reveal and benchmark the ark hull's repeated-rib-and-
    plank geometry together (**Asset inventory**, **Animation and motion polish**) — both are new,
    chapter-defining pieces without a close existing precedent to fall back on if either turns out
    too expensive for the tablet budget.
14. Time a complete read-aloud prototype against the **8–12 minute** target. Use three child-guided
    animal pairs and let three more board in the montage; add repetitions only if children finish
    too quickly and ask for more.
15. Test the GUIDE interaction on touch, keyboard and gamepad. It must be explicit context-button
    input rather than physics nudging, with the first mismatch producing a gentle living-world clue
    within four seconds.
16. Add resumable checkpoints at the end of finding, building, matching, rain and verse beats, and
    verify that resume restores the correct weather, water height, animals and ark state.
17. Verify the final verse at the established tablet font size, split it into two pages if needed,
    and child-test **RAINBOW / SIGN / PROMISE** plus the one-sentence covenant explanation.
18. Follow the build-order notes in [chapter-4-polish.md](chapter-4-polish.md) for models, motion,
    scenery, weather, sound and verse wording. The greybox follows that order only as far as a
    playable hull, three blob-style pairs the child guides, three more that board in the montage,
    and the WEB wording of Genesis 9:13.
