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

## How it would look

Same paper-craft rules as everything already in the game — nothing new to invent here, just
applied to new things:

- **Every surface is flat matte colour with a fine paper-grain texture**, and every object has a
  thin black ink outline (a slightly bigger inverted copy of itself, see `add_outline` in
  `polish_valley_v6.py`). No gradients, no gloss. This is why the valley reads as a diorama made
  of paper rather than a realistic 3D scene, and the ridge camp would follow the same rule.
- **Terrain, trees, stone and light stay exactly as they are** — the ridge already exists in the
  valley's own palette (the same cypress green, olive green, and the grey/mossy/slate stone from
  `ROCK_VARIANTS`), under the same sun and the same soft distance fog. Nothing about the *place*
  needs restyling, only new props placed in it.
- **New props, in the valley's existing material style** (flat colour + grain, like the sign
  post and the stream rocks): a canvas tent (a warm cream or worn-red, like a folded blanket, not
  a bright colour), a small ring of stones with orange "flame" shapes for the campfire (the same
  low-poly paper-flame trick used nowhere else yet, but simple to build), a couple of cloth
  banners on poles, and a log or two to sit on. Nothing elaborate — the meadow's sign post and
  wonder-item stand are a good gauge of how much detail a prop gets.
- **Jonathan**, built the same way as David and the Wonder-Walker (`generate_david_mentor_v*.py`,
  `generate_wonder_walker_v*.py`): a simple paper-doll figure, rounded low-poly body, flat matte
  cloth. David's colours are a shepherd's — a golden-brown tunic, an olive-green sash — because
  he is a shepherd. Jonathan is a prince, so his colours should read as court rather than
  hillside: I'd suggest a deep blue or wine-red tunic with a gold sash or trim, something a child
  reads as "royal" next to David's earth tones, without any texture or detail that isn't already
  in the game's vocabulary (no patterns, no jewellery beyond maybe one gold band).
- **The Wonder Items** (robe, bow, belt) would look like the existing ones: small, simple,
  paper-craft objects with the same outline and grain, sized and staged the way the stone, staff
  and lamb are today (see `WonderItemsVisual` in `main.tscn`) — not miniature versions of
  Jonathan's actual clothes, just a clear, readable icon of each.
- **Camera and lighting are unchanged.** Same tabletop follow-camera, same close-up camera for
  dialogue, same sun and fog. The one new thing is the lookout point (mentioned above), where the
  tabletop camera would have a clear sightline back down into chapter 1's valley — a visual
  callback that costs nothing extra to build, since the terrain is already there.

In short: nothing here asks for a new art style, a new lighting setup or a new technique. It's
the same recipe (flat colour, grain, black outline, low-poly, paper-doll figures) pointed at a
new location, a new character and three new small props.

## Time of day, and life in the camp

Raised after the first sketches: could the camp be lit so the fire actually shows, and could it
feel less empty?

- **Dusk, not full night.** In flat daylight the campfire's glow does not read; at night the
  scene risks feeling dark and unwelcoming for a 6-year-old. Dusk (a warm, glowing sky, not
  black) keeps the fire and a hanging lantern visible and gives the camp its own mood, while
  staying as gentle as the rest of the game. It also ties into the story: it is the evening of
  the same day the whole camp was cheering David's name. This is the first thing in the game that
  is not full daylight, so it is a genuinely new piece of work (a second `Environment`/lighting
  setup for this one location), not a free change.
- **Two camp guards**, dressed plainly (not Jonathan's court colours), standing and slowly
  patrolling near the tent — ambient life, the same idea as the lamb, the fish and the
  butterflies in chapter 1 (`3.3 A world that reacts`), not a threat and not interactive. Each
  carries a staff, not a weapon, in keeping with no violence being shown anywhere in the game.

A second sketch, at dusk with the campfire glowing, a hanging lantern, and both guards, was
shown alongside the first. Still a concept, not built.

## Open questions

1. Is "The King's Camp" / David and Jonathan the right next beat, or would you rather see other
   ideas (for example, David and Jonathan's covenant is one option among several later Bible
   scenes)?
2. Loyalty or Friendship for the charm's name?
3. Is reusing the existing ridge as the new location the right call, or should chapter 2 be a
   wholly new environment?

Nothing moves forward on this until it's decided.
