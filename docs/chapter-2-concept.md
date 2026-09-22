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

## Open questions

1. Is "The King's Camp" / David and Jonathan the right next beat, or would you rather see other
   ideas (for example, David and Jonathan's covenant is one option among several later Bible
   scenes)?
2. Loyalty or Friendship for the charm's name?
3. Is reusing the existing ridge as the new location the right call, or should chapter 2 be a
   wholly new environment?

Nothing moves forward on this until it's decided.
