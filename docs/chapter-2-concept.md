# Chapter 2 — a concept, not yet approved

This is a proposal, not a plan. Nothing here is built. It exists so the idea can be looked at
and decided on before any art or code work starts.

## Where chapter 1 leaves off

Chapter 1 is the lead-up to the fight, not the fight itself: David gets steady, earns the
Courage charm and the Joshua 1:9 verse, then walks out to the valley. Wonder Light narrates the
result in one line ("David walked out to the valley. And when it was over, the whole camp was
cheering his name.") — the confrontation with Goliath happens off-screen, on purpose. The game
has stayed gentle throughout (Steady Hands always succeeds, there is no giant on screen, no
violence), so a chapter 2 that shows the fight itself would break that tone.

## The proposal: "The King's Camp"

**Bible passage:** 1 Samuel 18:1-4 — after the battle, Jonathan (King Saul's son) becomes
David's loyal friend and gives him his robe, sword, bow and belt as a sign of that friendship.
No violence, no giant, a natural next beat after chapter 1's ending line, and it introduces a
second virtue alongside courage.

**New verse:** 1 Samuel 18:1 (WEB) — "...the soul of Jonathan was knit with the soul of David,
and Jonathan loved him as his own soul."

**New charm:** Loyalty (or Friendship — either reads well; worth deciding once the wording is
final, since the charm's name is spoken aloud by the recorded voice).

**New Wonder Items:** instead of a stone, a staff and a lamb, three of Jonathan's gifts — a robe,
a bow and a belt — each found and given to David in turn, mirroring how chapter 1's items work
today.

## The story, and what the child does

Same shape as chapter 1, so it stays recognisable rather than becoming a different game halfway
through:

1. **Explore.** The Wonder-Walker (a guest in the story, not David — chapter 1 is explicit about
   that, and this keeps it true) arrives at the camp on the ridge and looks around: tents,
   banners, a campfire, the valley visible below.
2. **Find three Wonder Items.** Jonathan's robe, bow and belt, scattered around the camp the way
   the stone, staff and lamb are scattered around the meadow today.
3. **Meet Jonathan.** A short dialogue beat, the same shape as meeting David: he explains what
   the gifts mean and that he is giving them to David because of what David did.
4. **A signature activity, fail-free like Steady Hands.** Working name **"Tying the Friendship
   Cord"**: the same hold-and-release breathing-ring mechanic Steady Hands already uses, re-skinned
   as looping a cord three times instead of three slow breaths. Reusing the mechanic keeps the
   engineering small; only the visuals and words change. (A different activity is possible, but
   this is the cheapest one that still feels like its own thing rather than a copy.)
5. **Reflect and receive the verse:** 1 Samuel 18:1, read aloud, the same way Joshua 1:9 is today.
6. **The charm ceremony,** unchanged code, new charm.
7. **End panel:** Play again, My journal, Colour my charm, Keep exploring — same as today.

So the child does the same *kind* of things as chapter 1 (walk around, collect, listen, one calm
fail-free activity, a verse, a charm to keep and colour), with a different story, a different
place and a different small idea (loyalty, not courage) — not a new genre of gameplay.

## Band

Chapter 2 targets **Band A**, the same as chapter 1 today (see the README's Band notes): **Meet
Jonathan** would be an auto line, no reply choices, and **Tying the Friendship Cord** would be
fail-free and impossible to rush, the same way Steady Hands is.

**Band B (ages 9-12) — pending, not decided, not built.** Looking into what actually holds older
kids' interest, the current thinking is that the difference should be *more to explore*, not a way
to fail or lose — this game's "cannot be failed" pillar stays for every age:

- The three Wonder Items (robe, bow, belt) would be spread across the whole camp — behind a tent,
  past the lookout point, near the patrolling guards — instead of close together near the path, so
  an older child has to actually search the space, maybe backtrack, maybe use the lookout view
  down into the valley as a clue.
- **Meet Jonathan** could offer a real reply choice that changes his next line, instead of an auto
  line.
- **Tying the Friendship Cord** could take a little longer and ask for steadier attention, but
  stays fail-free — more patience required, never a chance to get it wrong.

Every child, on either band, still reaches the same verse, the same charm and the same ending.
This is a direction to react to, not a decision: it stays a documented idea for both chapters,
picked up together if it ever is, not built ahead of chapter 1 where Band B still doesn't exist.

## Where it would happen

Chapter 1's valley already has scenery above and behind the waterfall cliff that the player
never reaches: a ridge with its own trees and a view back down over the whole valley. It was
built as backdrop, not as a place to stand, but it is already there. Two screenshots from the
existing (unmodified) valley, taken from a camera placed on that ridge, are attached to this
message — one looking down at the cliff and waterfall from above, one closer in among the trees.
That view, made walkable, becomes King Saul's camp: a clearing among the same cypress and olive
trees, a large tent, a campfire, banners, and a lookout point where the whole of chapter 1's
valley is visible below — waterfall, stream, and the path where David and the Wonder-Walker
first met. It would reuse the terrain, trees and stone that already exist rather than building a
new environment from nothing, and the walk up to it could start near the cliff ledges added in
backlog 4.4.

## What would carry over as-is

- The charm ceremony (float-in, snap onto the Virtue Bracelet, gold pulse) already fits "Jonathan
  gives David a gift" without changing anything.
- Who is playing, the Faith Journal, colouring, Easy words, read-aloud and the pause menu all
  work per-chapter already; a second chapter's verse and charm just need entries in
  `journal_content.gd` and recorded clips.
- Wonder Item collection, camera director and touch/gamepad input all work as they are.

## What would be new work

- A Jonathan character model (or a simple placeholder, the way the charm ceremony uses
  placeholder meshes today).
- Making the ridge walkable: a path up from the cliff-ledge area, a boundary for the new area,
  and camp props (tent, campfire, banners).
- A short new beat sequence in `chapter_director.gd`, three new Wonder Item flavour lines, and a
  new charm-award reason.
- Recorded clips for the new lines, in the same two voices.

## How it would look

This is the picture to build from. It is still the chapter 1 diorama — flat matte colour, paper grain, a thin black ink outline, low-poly paper-doll people. What changes is the hour, and the few new things standing in it.

The evening of the same day. Down in the meadow it is still the valley the child just walked, only seen from above and already going blue. Up on the ridge the day has tipped into a calm blue hour. Not a black night, and not a warm orange sunset. The blue is a real colour, bright enough to play in. One fire does the comforting. The reference for the *feeling* is a gentle bedtime picture: you can see every face, the path is obvious, and the dark is a colour rather than a hole. Sleepytime and a quiet campfire are the mood. A horror still is not.

### The first view

The path climbs through the trees the child already knows, cypress and olive, and opens onto one clearing. The eye should land in this order:

1. The campfire, the only bright warm thing, a little right of centre.
2. One cream tent behind it, open toward the fire, big enough to be "the camp" and not a city of tents.
3. Jonathan near the fire, in a wine-red tunic, so he does not disappear into the blue.
4. David, smaller, in the same golden-brown tunic and olive sash as chapter 1, so the child knows him before anyone speaks.
5. Past a low stone at the cliff edge, the whole of chapter 1 laid out below: waterfall, stream, the path where they first met. The fog must not eat that view. It is the reward for walking up.

Two plain guards walk a short, slow loop near the tent. They are life in the camp, like the lamb and the butterflies, not a puzzle and not a threat. Sand and brown cloth, a staff each, no armour, no swords, no torches. The fire and one hanging lantern are the only warm lights. A torch in every hand would turn the blue hour back into daylight.

### The blue, and the one warm note

Same paper surfaces as the valley. The light is a second set of flat colours, not a realistic night render and not a gradient painted onto the rocks.

| What | Colour | So that |
|---|---|---|
| Sky | A clear mid blue, lighter toward the horizon | The top of the picture feels open, not like a lid |
| Far hills and the valley below | Blue, a step toward violet | They sit back, and the child still recognises the waterfall |
| Near ground | Pale dusty blue, light enough to walk | Nobody has to guess where the floor is |
| The path | The same warm stone as chapter 1, only a little cooler | It stays the "walk here" colour |
| Tree shadows | Blue, never black or grey | The ink outline is the dark line. The shadow is not |
| Cypress and olive | The same greens, seen in blue light | The place is still the ridge, not a new forest |
| Moon | A soft pale disc, low in the sky | It is there. It is not a spotlight |
| Fire | Flat orange shapes with a smaller yellow centre, in a ring of the valley's own stones | It reads as fire from across the clearing |
| Warm pool | A soft orange only on the nearest tent wall, the log, and the cheek turned toward the fire | The rest of the camp stays blue |
| Lantern | One, cream paper with a yellow centre, hung at the tent mouth | A second comfort, not a second sun |

Faces stay the paper skin colour from chapter 1. They are not dipped in blue, or they look cold and unwell. The fire may warm one edge of a cheek in the close-up. Eyes, mouths and the ink line stay as readable as they are in the meadow.

Paper grain and the black outline stay on everything, including the flame and the lantern. This is a change of light, not a change to a lineless cartoon.

It needs its own `Environment` on this ridge. Chapter 1's sun and daytime sky stay down in the meadow. Carrying the daytime sun up here would hide the fire, which is the whole point of the hour.

### The camp, piece by piece

Nothing here is more detailed than the meadow's signpost. If a prop needs a pattern, a jewel or a second material, it is too much.

- **The tent.** One large tent, warm cream, like a folded blanket. The front is open so the inside is a darker cream, not a black cave. A smaller folded canvas may sit behind it. No crowd of tents, no guy-ropes to trip on, no flags so small the child cannot read them.
- **The banners.** Two. Simple cloth rectangles on plain poles: one deep blue, one dull wine. No crest, no writing, no animal. They may sway as slowly as the meadow grass. They do not snap or flutter hard.
- **The fire.** A low ring of the grey, moss and slate stones already used in the valley (`ROCK_VARIANTS`). The flame is a few flat paper shapes, the way a paper diorama fakes fire, not a bright particle glow that blows the scene out. A log on the near side gives Jonathan somewhere to be.
- **The gifts.** Three small paper objects, staged like the stone, the staff and the lamb, each obvious from a few steps away. The robe is a folded rectangle of deep blue with one gold edge. The bow is one curved piece with a single string, and no arrow anywhere near it. The belt is a short brown loop with one small gold square. They are icons, not tiny copies of real clothes. The sword in the Bible verse is not a Wonder Item and not a prop. It stays off the screen the way Goliath did.
- **Jonathan.** Built like David and the Wonder-Walker: rounded low-poly, flat matte cloth, ink outline. A prince next to a shepherd, so the child can tell them apart at a glance. Wine-red tunic, a gold sash, maybe one gold band at the neck. No pattern, no crown, no jewellery beyond that. Deep blue was the other idea for him. In this hour a blue tunic would vanish into the trees, so the wine-red is the one to use.
- **David.** Unchanged from chapter 1. The familiar clothes do the introducing.
- **The guards.** Two. Plain sand and brown, shorter capes or none, staffs held down. They walk a loop that never crosses the path the child needs, and they never turn to face the child as if to stop them.
- **The lookout.** The cliff edge, one low stone to mark "stand here," and the valley in clear view underneath. The waterfall keeps the bright blue the child already knows, so the place reads as "where I was" even in the new light.
- **The owl.** One, small, paper, high in a cypress at the back of the clearing. It blinks slowly and sometimes turns its head. It does not fly at the child, and it does not leave the branch. A child should be able to find it and smile, not jump.
- **The fireflies.** Six or eight. Tiny warm paper dots drifting over the grass at the edge of the clearing, the night version of chapter 1's butterflies. They are dimmer than the lantern and they do not light the ground. Walk toward them and they lift aside, the way the butterflies do, then settle again. No swarm, and none on the path, so the walking colour stays clear.

### What the camera is looking at

The tabletop camera and the close-up camera stay the ones from chapter 1. The framing is what changes.

- **Arriving.** Wide enough to hold the fire, the tent and a slice of the valley below. The child's head is fully in frame. The blue sky gets room above the cypress.
- **Finding a gift.** The gift sits in clear space, not tucked in a dark corner. Blue hour is bright enough to see a bow lying on a stone without a glow. A gift beside the fire may pick up a little warm light. A gift near the lookout stays blue and still readable.
- **Meeting Jonathan.** Close-up on his face, the same intimate cut as meeting David. Behind him: blue tent or blue trees, and a little of the fire. David can sit small in the mid-ground so the friendship is visible, not only spoken.
- **The friendship cord.** The activity fills the lower middle of the picture: two hands and a cream-gold cord, looped three times, in the warm pool of the fire. The camp stays soft behind it. The cord is a gift being tied, not a rope, not a weapon.
- **The verse and the charm.** The same paper ceremony as chapter 1. The new charm reads as friendship at thumbnail size: two small loops linked, or a simple knot. Not a sword, not a crown.

### Never in the picture

- Black sky, grey fog, or a shadow dark enough to hide the path.
- A giant, a drawn sword, arrows, armour, or a guard who blocks the way.
- More than the fire and one lantern as lights that paint the camp. Fireflies are allowed, and they are specks, not lamps.
- A screech, a wolf, a branch snap, or anything that makes the child check behind them.
- Gloss, gradients on the props, or a lineless style. The outline stays.
- Blue poured over the characters' skin. The world goes blue. The people stay themselves.

## What you hear on the ridge

The meadow's daytime bed does not come up the hill. Birds and the close stream belong to chapter 1. The ridge keeps the same lullaby, a little quieter, and replaces the rest.

| Sound | What it is like | When it rests |
|---|---|---|
| Lullaby | The same music box, a little further away | Ducks while anyone speaks, as it does now |
| Wind | The same wind, slower and quieter | Stays, very low, under the voice |
| Crickets | A few soft chirps, not a wall of summer noise. This is the sound that makes the blue hour feel like evening | Ducks with the other ambience |
| Campfire | A small dry crackle, sitting on the fire itself, louder as you walk up to it | Ducks while anyone speaks |
| Owl | Two low notes, "hoo-hoo," from the cypress, once every 15 to 25 seconds. Gentle, never a screech, never close to the camera | Silent the whole time somebody is speaking, the way the birds wait in chapter 1 |
| Valley, from the lookout only | A faint stream, and now and then one far sheep. It says the meadow is still down there | Only while the child is standing at the edge |

The fireflies make no sound. A tick or a chime on each one would turn them into a toy and crowd the voice. The owl is the night bird. The crickets are the bed. The fire is the close, warm sound, matched to the one warm light.

Nothing else. No wolves, no thunder, no armour, no startled wing-clap. If a sound would make a six-year-old look around to see what went wrong, it does not belong here.

## Open questions

1. Is "The King's Camp" / David and Jonathan the right next beat, or would you rather see other
   ideas (for example, David and Jonathan's covenant is one option among several later Bible
   scenes)?
2. Loyalty or Friendship for the charm's name?
3. Is reusing the existing ridge as the new location the right call, or should chapter 2 be a
   wholly new environment?

Nothing moves forward on this until it's decided.
