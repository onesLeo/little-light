# Chapter 5 — Polish checklist

Companion to [chapter-5-concept.md](chapter-5-concept.md). The concept locks the story, the safety
rules and the asset plan. This note is the experience pass: what the child should see, hear and do
so the chapter stays inside 8–12 minutes, reads as mercy rather than a fish spectacle, and matches
lessons from Chapters 1 and 2.

The chapter is not built yet. Follow this list before treating Jonah, the storm or Nineveh as done.

## Time and what to cut first

Target about 10 minutes, inside the volume's 8–12 minute journey.

| Section | About | What the child does |
|---|---|---|
| Joppa choice and three finds | 2.5 min | Look, then find the bag, message and lamp |
| Gangway and cargo | 2 min | Walk aboard once, then place those same three things |
| Calm sea, safe sailors, fish | 1.5 min | Watch |
| Prayer page | 1.5 min | Tap Call, Hear and Go |
| Shore and the road | 1.5 min | Carry the message and walk with Jonah |
| Nineveh, the plant and Care | 1.5 min | Watch, then tap Care |
| Mercy charm | 1 min | Ceremony. The volume page plays only the first time this profile earns the fifth charm |

If a timing pass runs long, shorten the gangway and cut extra Wonder Light restatements first.
Keep the sailors' safety line, the road, Nineveh, the plant question, Care and the charm. The fish
stays the middle of the chapter. It is not the picture that gets the extra time.

## Story situations

Play the choice before explaining it. Movement stays locked through the first line, as it does on
the camp arrival. The camera already holds the Nineveh sign, Jonah and the ship. Wonder Light says
"This is Joppa," and only then "Nineveh is that way. Jonah is looking at the ship."

The bag, the rolled message and the lamp are the cargo. There is no second set of objects and no
loose rope to learn. They move along the story instead of vanishing: ground, deck slots beside
Jonah, shore, the child's hands on the road, then open at the gate. A second tap does nothing.

The message is the hero prop. It carries a large road icon, not a paragraph. Near the road it turns
inland once, with one paper rustle, then rests. Tapping it, or standing at the sign, plays the same
short clip: "Nineveh."

Wonder-Walker never enters the sea or the fish. After Jonah steps behind a foreground wave, the
child remains on the calm deck with the sailors. Prayer is a lifted paper page in front of them.

The sailors get their own mercy beat. When the water settles, the captain says "We are safe" while
the crew looks at the calm sea. Then the fish rises past the stern. The ship stays outside the fish.

On the road the child carries the open message. That is the "help Jonah go" action. The walk is
short, about fifteen to twenty seconds, on one path to the gate.

At the gate Jonah says "Nineveh, turn back. God sees what you are doing." Families respond with a
visible action: a closed hand opens, and people turn toward each other. The shade hill is in the
same view as the city. Jonah says "I wanted the plant to stay." Wonder Light asks "Jonah cared
about one plant. Should God care about a whole city?" The child taps Care. The camera then rests
on the living city, with the folded plant still in frame.

Jonah does not smile the lesson away. His shoulders stay a little closed under the plant. Wonder
Light and the child carry the mercy. Jonah's ending stays an open question.

Say the safety line immediately after Jonah admits he was running: "This is Jonah's story. God
still keeps him safe." The child is a guest and is not in trouble.

## Scenery and colour

Keep the quay quiet so the sign, Jonah and the ship read in that order. Steps, two mooring posts,
folded nets, one gangway, three sailors and Jonah are enough. Market life belongs to Nineveh, so
the two places feel different. Nets never block the path or read as traps. The rail is high and the
child cannot fall overboard.

The fold-out is still three panels, and only the active panel runs full animation and collision.
One shared strip of sea belongs to both the ship and the deep, so the fish rise needs no camera
cut and no loading fade. The coast folding away covers any panel change.

Joppa and Nineveh use a daytime sun. Do not reuse the camp's blue-hour environment. In the storm,
darken the paper sky and the wave bands. Faces, cloth and hands stay paper-warm, with the same
care as the camp people shader: no blue wash on skin, and no albedo so dark the face disappears.
Wonder Light's amber glow is already on in the first frame of the prayer page.

The prayer page is a dry blue paper room with a floor. It lifts open. It does not iris in from
black. Rain and waves stay layered paper with ink edges. Wave bands never cover the whole screen.
There is no lightning and no camera shake.

Nineveh gets the warmest light and the longest hold in the chapter: rose stone, faded blue cloth,
clay jars, two or three family groups. The fish is larger than the ship and still second to this
picture.

The plant grows with one smooth height change, holds, then folds leaf by leaf. Folding is the
wither. The biblical worm is omitted from the picture on purpose. A Bible-story reviewer should
confirm that the journal may name the worm in the full passage while the played scene does not
stage it.

## Camera

`CameraDirector` needs shots this chapter can actually use. The valley's high tabletop follow
makes a deck look like a flat rug.

- **Choice:** wide enough for the sign, Jonah and the ship, in that order.
- **Conversation:** close on Jonah, road soft over one shoulder and sail over the other.
- **Deck:** stable three-quarter view, fixed horizon. The deck may heave slowly. The camera eases
  and does not copy every wave.
- **Sea:** stay with the sailors until the water settles, then look just past the stern. The fish
  is already in that sightline.
- **Prayer:** the page fills the middle of the frame. Jonah and Wonder Light sit inside it. No
  fish anatomy looms behind them.
- **Shore:** Jonah comes forward from behind a wave onto wet sand.
- **Gate:** Jonah stands among the families, not above them.
- **Question:** Jonah under the plant, city visible. The last frame favours the city.

Reduced motion removes deck tilt and almost all wave travel. The fish rise remains a slow ease so
the story is still there. Build `GameSettings.reduced_motion` on the `read_aloud` / `easy_words`
pattern, with its own pause-menu checkbox and its own saved value, before prototyping the deck.

## Models and characters

**Jonah.** Same paper proportions as David and Jonathan. Short dark curls, a compact beard, dusty
indigo over muted ochre. A stronger nose bridge is enough of a difference. Do not enlarge the nose
into a joke. `Blink` / `Talk`, plus five hand poses: arms at his sides, hands on the rail, open
prayer hands, arms folded under the plant, hands open toward the city. Approve front,
three-quarter, side, blink, talk and those hand poses at Chapter 2 close-up distance before
recording his voice.

**Captain.** His own head, because he speaks. The dialogue-tag icon has to separate him from Jonah,
Samuel and Noah at a glance: plainer older face, no compact beard like Jonah's, no full beard like
Noah's. Sea-green and cream cloth.

**Deck hand and rope-handler.** One shared crowd rig, camp-guard tier, distinguished by a rope coil
and cloth from the sea-green / cream / rust set. No pirate styling, eye patches or comic panic.
Mouths stay closed except the captain while he speaks.

**Nineveh families.** Two or three groups on the same crowd tier. Poses are turned-away, listening
and turned-toward. Cross-fade about half a second. The change reads as a hand opening and people
turning toward each other. No crying children, no caricature and no evil colour code.

**Great fish.** One large soft paper body, a tapered tail and broad fins, built the way Chapter 4
builds large animals, moved with the camp owl's slow state machine: `WAITING`, `SURFACING`,
`GONE`. It is bigger than the ship, has a small eye that blinks slowly, and has no teeth. The eye
does not stare into the camera. The ship is never inside the silhouette. If a tablet hitches,
reduce outline hull, shadow and far detail before losing the silhouette.

**Sail and nets.** Use the camp flag-cloth shader. No new cloth physics.

Wonder-Walker helps with safe tasks and never causes Jonah's step into the sea.

## Motion

Jonah needs authored beats on top of `chapter_two_character_motion.gd`: the admission at the rail,
prayer hands on the page, and folded arms under the plant. Breath, a small listening nod and a
one-handed speaking pulse still run underneath. Two-arm lifts read as robots.

The three sailors keep a small work idle while Jonah talks and while cargo is placed. Start times
differ. After the sea calms they look at the water, then toward the fish. They do not freeze for
those beats.

The storm-to-calm change is one crossfade. Wave height, wave speed, wind, rain and the lighting
environment ease down together on the timeline of Jonah stepping behind the wave.

The message turns once. It does not rustle on a loop. The plant's growth and each folding leaf are
eased. The fish eases up and eases away. Nineveh's pose change cross-fades. Nothing hard-cuts from
"turned away" to "turned toward."

## Activities

**Secure the Cargo** reuses Chapter 3's place-at-an-outline pattern, with these checks:

- The three outlines are the bag, the message and the lamp. Each outline shows that object's icon.
  An outline accepts only its match. Colour is not the only cue.
- Outlines are parented to the deck, so they ride the slow heave. They are world objects, not a
  screen panel. They stay below the dialogue bar and never cover a face or a verse.
- Touch may drag. Touch, keyboard and gamepad may also tap a piece and then tap its outline.
- There is no fail state, timer or required order.
- If a touch does not come in about seven seconds, the next piece eases into place on its own, the
  way Steady Hands finishes an idle breath. The story beats around the activity do not skip
  themselves.

**Prayer in the Deep** extends `word_chip.gd`:

- The page is already lit. Call, then Hear, then Go. The next light breathes. A tap plays that
  single word in Juno's voice. The label and the clip match: "Call." "Hear." "Go."
- After the tap, the light drifts to Wonder Light over about one second.
- The same seven-second idle assist completes the next light. It does not skip the shore, the road
  or the verse.
- Dismiss and free the page before any verse card. Chapter 2's cord card covered the scripture
  when it stayed up.

**Care** is one chip at the plant, same glow and the clip "Care." It is not a second three-word
game. Band B's "which mercy?" choice stays a later idea and is not a build task for this volume.

## Sound

| Moment | What to hear |
|---|---|
| Quay | Small paper waves, rope on wood, one gull crossing once. No market bed |
| Steps | Stone on the quay, wood on the deck, wet sand on the shore, dust on the road. A few variants each |
| Finds | The usual pickup chime, once per object |
| Message | One unroll, then the shared "Nineveh." clip |
| Storm | Wind and rain rise slowly. No thunder near the listener. Voice stays above the bed |
| Cargo | Soft rope, wood set-down and cloth, each distinct, ducked under speech |
| Sea change | The storm bed and the wave motion fade down together into a low water hush |
| Sailors safe | Hush holds under the captain's line |
| Fish | A low filtered swell from a credited recording. No roar and no spit |
| Prayer | A quiet water pulse under Jonah. Three stable glassy pitches, one per word |
| Nineveh | A soft market bed that ducks out for the warning and returns gently after |
| Plant | One unfurl, then small dry folds |
| Verse | Silence the activity sounds before the card. One warm phrase at most |
| Music | The volume's plucked strings and pads. Prayer sits lower and more spacious. Nineveh is the warmest |

Reduced motion ducks wind and rain as well as calming the picture. Gulls, market murmur, hull
creak, rain and the fish swell are the clips most likely to need credited recordings rather than
synthesis. Log each one in `assets/audio/CREDITS.md`.

Minimum mix check, same as Chapter 4: a tablet at about half volume, voices only, ambience only,
sound muted, and read-aloud off. The chapter still makes sense in all five passes. Storm and water
never mask narration.

## Voice, narration and verse

Record every shipped line. Wonder Light is Juno. A missing clip must not drop a whole dialogue
block onto system text-to-speech, which is what `speak_dialogue` does when any line in the block
has no clip. Do not leave a Chapter 2-style lookout line on the system voice.

Word clips are the single spoken words, including the period the library already uses: "Call."
"Hear." "Go." "Care." "Nineveh."

Jonah's five lines need separate direction, not one flat read: quiet refusal, the admission at the
rail, the thank-you, the warning, and the short plant complaint. He stays warm enough that
frustration never becomes frightening. The captain has two lines, "Hold on. This storm isn't like
the others." and "We are safe." Audition both new presets against the full cast: Juno, Bram,
Dylan, Samuel, Jesse, Noah and Noah's wife. The captain in particular has to clear Samuel and Noah.

Nineveh has no new voice unless a later playtest asks for one. Wonder Light carries the city's
response. God is not a new booming voice.

Easy Words drafts, to be tested before they are final:

| Original | Easier draft |
|---|---|
| This is Jonah's story. God still keeps him safe. | This is Jonah's story. God keeps him safe. |
| Jonah cared about one plant. Should God care about a whole city? | Jonah cared about one plant. God cares about a whole city. |
| A Mercy charm, for another chance, and for a city God would not give up on. | A Mercy charm, for another chance, and for a whole city. |
| Keep it close. Mercy is for the person who needs a second chance, and for the ones we'd rather not forgive. | Keep it close. Mercy is for people who need another chance. |

The smoke test requires every Easy Words original to remain a substring of the chapter script, and
every clip to load. Add the new lines to that check when the chapter script exists. Speaker lines
use the exact `Speaker: "..."` prefix so `dialogue_view.gd` can tag Jonah and the Captain.

### Verse

Confirm the wording against the [World English Bible Classic, Jonah 4](https://ebible.org/eng-web/JON04.htm)
and [Jonah 2](https://ebible.org/eng-web/JON02.htm) before recording.

Jonah 4:2 is the mercy verse, and most of it is Jonah's complaint. Verse 3 asks to die. That
request is never spoken or shown. The playable quotation is only this clause, recorded exactly:

"you are a gracious God and merciful, slow to anger, and abundant in loving kindness"

Spoken reference: "Part of Jonah, chapter four, verse two." Show it on its own card, in the
established verse style. The next card is Wonder Light, visibly separate from the quotation: "God
is kind. He gives another chance. He cares about the whole city." Do not add a third word game on
that card. Call, Hear, Go and Care have already been tapped.

Jonah 4:11 is God's question and it is too long for the activity. The plant line is Wonder Light's
short question, not a fake quotation. The exact WEB verse belongs in the Faith Journal.

Jonah 2:2 may be the journal's prayer passage after a read-aloud test. "Sheol" needs that test.
Do not read Jonah 2:10 on the default journal tap or in the chapter. The played shore line stays
"The fish set Jonah safely on the shore."

Dismiss cargo outlines and the prayer page before the verse card.

## Ending the volume

Reuse the Chapter 1 and 2 ending: hide the previous chapter's banner on arrival, charm ceremony,
Chapter Complete, `finish_chapter`, and an end card whose Colour my charm opens the Mercy charm.
The charm picture is a small warm light held between two curved dark-blue waves. It reads as
shelter and another chance. It has no teeth. Journal colouring works the same way as Courage.

The first time a profile earns the fifth charm, a volume page shows all five charms and the Faith
Journey with every stop lit. Offer replay. No store prompt and no new currency. A later replay of
Chapter 5 shows the ordinary end card. Completion is saved per child.

`journal_content.gd` should end this volume at five earned charms and `MYSTERY_SLOTS` of 0. Verify
that against whatever Chapters 3 and 4 actually added. Do not assume the count.

The map handoff from Chapter 4 is one camera move: the rainbow's blue band widens into the sea,
the ark becomes a distant paper silhouette, and the ship is already at the quay.

## Never in the picture or the played script

- The child or the sailors throwing Jonah, a Throw button, or a fall from above.
- The child inside the sea or inside the fish. The ship swallowed.
- Drowning, gasping, being chased, teeth, stomach, slime, or a spit sound.
- Jonah 4:3 or 4:8, or any line about wanting to die.
- A worm, rot or infestation. The plant folds.
- Lightning, camera shake, a capsizing ship, screaming sailors, crying children.
- A booming God voice. Pirate costumes. An evil or caricatured city.
- Jonah played as a coward joke, or turned cheerful at the last line.
- The chapter ending when the fish reaches shore.
- System text-to-speech for a shipped line.
- An activity panel left up over the verse.

## Build order

1. `GameSettings.reduced_motion`, a level greybox deck, and the shared sea strip.
2. Jonah's close-up poses, then the captain's head and the two crowd sailors with idle life.
3. The three travelling things, checklist, pickup chime and deck placement, including idle assist
   and a non-drag tap path.
4. The sea crossfade, the sailors' safety beat, and the fish rise past the stern.
5. The prayer page, Call / Hear / Go, then the shore and the carried message.
6. Nineveh's pose cross-fade, the folding plant, the question and Care.
7. The WEB clause, Easy Words, Juno and the two new voices. Record after the close-up gate.
8. The Mercy ceremony and the first-time volume page.
9. Tablet mix at half volume, then a family playtest.

## Definition of polished

- [ ] A full play stays near 10 minutes and, if cut, still includes the sailors, the road, Nineveh,
  the plant question, Care and the charm.
- [ ] The first frame shows the sign, Jonah and the ship before Wonder Light explains the choice.
  Walking is locked until that first line finishes.
- [ ] The bag, message and lamp are the only cargo, stay visible as they move, and cannot be
  collected twice.
- [ ] The child remains on the deck. The prayer page lifts in front of the sailors. The ship is
  outside the fish.
- [ ] Cargo and prayer can be finished by touch, keyboard and gamepad, and each idle-assists one
  step after about seven seconds.
- [ ] No activity control remains on screen when the verse card appears.
- [ ] Faces stay paper-warm in the storm. Nineveh is the warmest, longest picture. The last plant
  shot includes the living city.
- [ ] Jonah's five hand poses and the captain's face pass a close-up check before voice recording.
  Sailors keep idle life through dialogue and cargo.
- [ ] Reduced motion levels the deck, quiets the waves and ducks wind and rain without removing the
  fish, the prayer or the mercy ending.
- [ ] Every shipped line has a recorded clip. Button clips match the labels. Storm and water stay
  under the voice on a tablet speaker.
- [ ] The spoken quotation matches the Jonah 4:2 mercy clause exactly and stays separate from Wonder
  Light's explanation. Jonah 2:10 and the death-wish lines are not in the played script.
- [ ] The fifth charm, once per profile, lights the whole Faith Journey and does not open a store.
