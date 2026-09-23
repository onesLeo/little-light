# Chapter 2 — The King's Camp

The chapter's story is not finished. The place is built: the valley's ridge top is only a few steps deep, so the camp stands on its own wide clearing that carries on from it, framed by cypress and olive on soft rises, with chapter 1 laid out below a lookout stone. The king's round tent and five ridge tents face a stone-ring fire with breathing paper flames; one lantern hangs at the king's tent; four flags lean with the wind; four guards with staffs walk slow loops; an owl glides in to a cypress by the lookout and hoots while perched; fireflies drift at the edges; crickets and the fire's crackle replace the valley's birds. It is built the first time the child visits (`kings_camp.gd`), so chapter 1 never pays for it. From the Faith Journey, The King's Camp opens that ground and turns the light to the blue hour, and chapter 1 stands down so none of its lines or keys can land on top of the camp. Jonathan stands by the fire. He is not a recolour of David: longer straight hair to his shoulders, a thin gold band in it, a longer face, wider eyes, a wine-red tunic and a gold sash. No crown. The look to judge is [jonathan-look.jpg](jonathan-look.jpg). His words, the three gifts and the friendship cord are in the camp now. She finds the robe, the bow and the belt, loops a cord three times, and receives 1 Samuel 18:1 and the Friendship charm. It ends the way chapter 1 does: the charm floats onto the Virtue Bracelet, then the cheer, confetti, "Chapter Complete!" and the end card (Play again, Colour my charm for Friendship, Faith Journey). The voice is Higgsfield now. Wonder Light is still Juno, the same narrator as chapter 1. Jonathan is Dylan, the user-selected male replacement for Julian; David remains Bram and Wonder Light remains Juno.

## Where chapter 1 leaves off

Chapter 1 is the lead-up to the fight, not the fight itself: David gets steady, earns the
Courage charm and the Joshua 1:9 verse, then walks out to the valley. Wonder Light narrates the
result in one line ("David walked out to the valley. When it was over, the camp cheered his name.") — the confrontation with Goliath happens off-screen, on purpose. The game
has stayed gentle throughout (Steady Hands always succeeds, there is no giant on screen, no
violence), so a chapter 2 that shows the fight itself would break that tone.

## The story: The King's Camp

**Bible passage:** 1 Samuel 18:1-4 — after the battle, Jonathan (King Saul's son) becomes
David's loyal friend and gives him his robe, sword, bow and belt as a sign of that friendship.
No violence, no giant, a natural next beat after chapter 1's ending line, and it introduces a
second virtue alongside courage.

**New verse:** 1 Samuel 18:1 (WEB) — "...the soul of Jonathan was knit with the soul of David,
and Jonathan loved him as his own soul."

**New charm:** Friendship. The name is spoken aloud, so the recorded line says "Friendship," not Loyalty. The charm itself is two small loops linked, the same picture as the ceremony.

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
7. **End panel:** Play again, My journal, Colour my charm, Keep exploring — same as today — plus **Faith Journey**, the paper path described in `docs/faith-journal.md`. Chapter 1's valley is a finished stop. The ridge is the next one.

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
That view, made walkable, becomes King Saul's camp. The ground, the cypress, the olives and the stone stay. What is new is only what a child needs in order to say "this is a king's camp": several tents, banners, guards, a fire, and a lookout back down onto chapter 1. No second valley is built. The walk up can start near the cliff ledges from backlog 4.4.

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
  and camp props (tents, campfire, banners, guards).
- A short new beat sequence in `chapter_director.gd`, three new Wonder Item flavour lines, and a
  new charm-award reason.
- Recorded clips for the new lines, in the same two voices.

## How it would look

This is the picture to build from. It is still the chapter 1 diorama — flat matte colour, paper grain, a thin black ink outline, low-poly paper-doll people. What changes is the hour, and the few new things standing in it.

The evening of the same day. Down in the meadow it is still the valley the child just walked, only seen from above and already going blue. Up on the ridge the day has tipped into a calm blue hour. Not a black night, and not a warm orange sunset. The blue is a real colour, bright enough to play in. One fire does the comforting. The reference for the *feeling* is a gentle bedtime picture: you can see every face, the path is obvious, and the dark is a colour rather than a hole. Sleepytime and a quiet campfire are the mood. A horror still is not.

### The first view

The path climbs through the trees the child already knows, cypress and olive, and opens onto one clearing. The eye should land in this order:

1. The camp itself: one large tent and three smaller ones, so it reads as a king's camp and not a single shelter.
2. The campfire, the only bright warm thing, a little right of centre, in front of the large tent.
3. Jonathan near the fire, in a wine-red tunic, so he does not disappear into the blue.
4. David, smaller, in the same golden-brown tunic and olive sash as chapter 1, so the child knows him before anyone speaks.
5. Past a low stone at the cliff edge, the whole of chapter 1 laid out below: waterfall, stream, the path where they first met. The fog must not eat that view. It is the reward for walking up.

Four plain guards walk slow loops among the tents. They are life in the camp, like the lamb and the butterflies, not a puzzle and not a threat. Sand and brown cloth, a staff each, no armour, no swords, no torches. They never cross the path the child needs, and they never turn to stop her. The fire and one hanging lantern are the only warm lights. A torch in every hand would turn the blue hour back into daylight.

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

- **The tents.** One large tent, warm cream, open toward the fire. The inside is a darker cream, not a black cave. Three smaller tents of the same cloth sit further back and to the sides, enough to say "the king's camp" without becoming a city. No guy-ropes on the path. The large tent's door cloth and the banners move when the wind does.
- **The banners.** Four. Simple cloth rectangles on plain poles: deep blue and dull wine, two of each, set among the tents. No crest, no writing, no animal. They lean with the wind, the same slow way the meadow grass leans, and settle again. They do not snap.
- **The fire.** A low ring of the grey, moss and slate stones already used in the valley (`ROCK_VARIANTS`). The flame is three or four flat paper shapes with the usual ink outline, orange around a smaller yellow centre. They are animated, the way the meadow grass already leans: each tongue slowly grows, shrinks and tips, on its own timing, so the fire breathes instead of sitting still. The warm pool on the tent wall brightens and eases with it, slowly. No sparks flying out, and no flash. A log on the near side gives Jonathan somewhere to be.
- **The gifts.** Three small paper objects, staged like the stone, the staff and the lamb, each obvious from a few steps away. The robe is a folded rectangle of deep blue with one gold edge. The bow is one curved piece with a single string, and no arrow anywhere near it. The belt is a short brown loop with one small gold square. They are icons, not tiny copies of real clothes. The sword in the Bible verse is not a Wonder Item and not a prop. It stays off the screen the way Goliath did.
- **Jonathan.** Built like David and the Wonder-Walker: rounded low-poly, flat matte cloth, ink outline. A prince next to a shepherd, so the child can tell them apart at a glance. Wine-red tunic, a gold sash, maybe one gold band at the neck. No pattern, no crown, no jewellery beyond that. Deep blue was the other idea for him. In this hour a blue tunic would vanish into the trees, so the wine-red is the one to use.
- **David.** Unchanged from chapter 1. The familiar clothes do the introducing.
- **The guards.** Four. Plain sand and brown, shorter capes or none, staffs held down. They walk loops that stay off the child's path.
- **The wind.** A breeze you can see. Every so often the banners, the tent door, and the grass at the edge of the clearing all lean the same way, then ease back. A few paper leaves, or one loose strip of cream cloth, drift across the clearing and leave. It is the same idea as the meadow grass that leans when she walks, not a storm and not a cloud of particles. The path stays clear. Nothing blows into her face.
- **The lookout.** The cliff edge, one low stone to mark "stand here," and the valley in clear view underneath. The waterfall keeps the bright blue the child already knows, so the place reads as "where I was" even in the new light.
- **The owl.** One, small, paper, with wings that can open. When the child first reaches the clearing it is already in the air: a slow glide in from the side, two or three calm wingbeats, then it lands on a high branch of the back cypress and folds its wings. It does not dive, and it does not cross in front of her face. Once it has stopped it stays a while: a slow blink, a turn of the head, a little settle, and the soft "hoo-hoo" only while it is perched. After a long pause it may glide to a second branch on that same tree and stop again. Same kind of motion as the butterflies, not a chase.
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
| Wind | A soft evening breeze, the same recording family as chapter 1, a little closer here so it matches the banners moving. It swells when the visible gust passes and settles after. Never a howl | Stays under the voice, quieter while someone is speaking |
| Crickets | A few soft chirps, not a wall of summer noise. This is the sound that makes the blue hour feel like evening | Ducks with the other ambience |
| Campfire | A small dry crackle, sitting on the fire itself, louder as you walk up to it | Ducks while anyone speaks |
| Owl | Two low notes, "hoo-hoo," only while it is perched, once every 15 to 25 seconds. A single soft wing-flutter as it lands, the same family as the butterfly rustle, and never a clap | Silent the whole time somebody is speaking |
| Valley, from the lookout only | A faint stream, and now and then one far sheep. It says the meadow is still down there | Only while the child is standing at the edge |

The fireflies make no sound. A tick or a chime on each one would turn them into a toy and crowd the voice. The wind is the sound you can match to something you see. The owl is the night bird. The crickets are the bed. The fire is the close, warm sound.

Nothing else. No wolves, no thunder, no armour, no gale, no startled wing-clap. If a sound would make a six-year-old look around to see what went wrong, it does not belong here.

## Decided

1. **The title is The King's Camp.** The story is still David and Jonathan, the evening after the camp cheered David's name. A later covenant can be its own chapter. It is not this one.
2. **The charm is Friendship.**
3. **The place is the ridge that is already in the valley.** Same ground, trees and stone. Tents, banners, guards, the fire and the wind are added so the clearing looks like a king's camp. A wholly new environment is not needed.

Nothing else on this page is built yet.


## September 2026 playtest polish

The gift hunt now keeps a robe/bow/belt checklist on screen. Each pickup checks its own row and sounds a chime. Jonathan and David face one another; Jonathan blinks, nods and gestures while his recording plays, and David shifts and nods as he listens. Jonathan's smaller, shallow eyes have relaxed brows and catchlights.

Jonathan's dialogue uses a gentle camera push-in, with A/D, arrows, or the tablet stick for looking around. Walking resumes for the hunt and after the ending. The friendship cord now has a visible panel: hold Space, Enter, the on-screen button, or the tablet action button to draw a loop, then release to tie it. Three loops unlock the verse. Early release keeps progress; idle waiting never completes it. The tablet action label changes between LOOP and RELEASE.

The camp breeze is 6 dB above the valley level, and the owl has greater reach across the clearing. The arrival text and Juno recording now say “The day is turning into night.” Jonathan's two spoken lines now use the user-selected Dylan voice in place of Julian.

Validation: `tests/camp_review.gd` covers the chapter flow, duplicate/out-of-order gifts, idle/release behavior, camera, facing and replay. Run with `-- --visual` to save review frames under `.godot/camp-*.png`.
