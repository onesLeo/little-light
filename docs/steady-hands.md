# Steady Hands

David is scared, and the child helps him calm down by breathing with him. It is a breathing
exercise, not a test: there is no aiming, no score and no way to fail.

## How it plays

- **Hold** Space or Enter (A on a gamepad, the big gold **BREATHE** button on touch) to **breathe in**:
  a ring grows.
- **Let go** to **breathe out**: the ring shrinks.
- A little dot fills after each breath. **Three breaths** finish it.
- The ring says **Hold**, **In...** or **Out...**, so a child who cannot read yet knows what to do.
  The prompt line under the dialogue says "Hold Space to breathe in, let go to breathe out" (reworded
  for the gamepad and touch).
- Wonder Light glows brighter and David rises a little as the ring grows, and a soft hush of air
  swells and fades with it.
- David leans down toward his lamb for the whole activity, instead of standing frozen off to the
  side — a shape key on his model (he has no rig), blended in as it starts and back to standing
  once it finishes.

## It is slow on purpose

Breathing in and out has to feel calm. The old version cycled every 1.6 seconds (0.8 s in, 0.8 s out).
Now:

- The ring fills over about **4 s** and empties over about **4.5 s**, whatever the button does.
- It **changes direction gradually**, over about 1.4 s, never with a snap. If you let go while it is
  growing, it keeps growing for a moment before it turns around.
- So it **cannot be rushed**: a breath counts only after the ring has filled and then emptied again,
  and tapping the button quickly hardly moves it: five presses a second for 20 s gets the ring to
  about a third, and after a minute of it the ring is full but still no breath has counted, because
  a breath needs the ring to empty again.
- Measured with the real logic: a breath takes about **9 seconds** when the child lets go the
  moment the ring is full, so the whole exercise takes about **27 seconds** (about 33 if they hold
  until the ring lets go by itself).

## Nobody can get stuck

- **Holding at full:** after 2 s the ring lets go by itself, even if the button is still down. The
  child has to let go and press again for the next breath.
- **Doing nothing:** after 7 s at empty the ring breathes in and out by itself, and that breath counts.
- The press that started the exercise (the Space that ended the story line before it) does not count
  until it is let go of.

## Where the numbers are

They are exported on the `SteadyHands` node in `scenes/main.tscn`, so they can be tuned in the
editor:

| Setting | Default | What it does |
|---------|---------|--------------|
| `breaths_required` | 3 | How many breaths finish it. Band B could raise this. |
| `inhale_seconds` | 4.0 | Time to fill the ring while holding |
| `exhale_seconds` | 4.5 | Time to empty it when let go |
| `turn_seconds` | 1.4 | How long a change of direction takes |
| `hold_at_full_seconds` | 2.0 | How long a full ring waits before letting go |
| `idle_help_seconds` | 7.0 | How long an empty ring waits before breathing in by itself |
| `empty_scale`, `full_scale` | 0.62, 1.32 | How small and big the ring gets |
| `air_db_still`, `air_db_breathing` | -26, -8 | Volume of the air sound at rest and at full pace |

The air sound is `assets/audio/sfx/breath_loop.wav`, rendered by `tools/make_sounds.py`; the game
raises its volume and pitch with the ring instead of baking the breathing into the file.

## Input

`ui_accept` (Space, Enter, gamepad A) is polled every frame. On touch, the on-screen button now stays
pressed for as long as the finger is down (it used to send an instant tap), which is what makes
"hold to breathe in" possible. For the NEXT and GRAB buttons nothing changes: their actions still
fire on the press.

## Checked and not checked

The smoke test covers, with simulated time: the slow pace (one second of holding fills about a
sixth), the gradual turn-around, tapping five times a second for 20 s not getting anywhere, both
rescues (doing nothing and holding forever), three breaths finishing it, Wonder Light and David
reacting and then going back to normal, the air sound starting and stopping, the touch button
holding its actions, and the reworded prompts. A screenshot check confirmed the ring is readable
(with an ink outline, so it stands out against the path).

**Not checked:** how it feels and sounds to a real child. In particular whether about 4 s in and
4.5 s out feels calm rather than long for a 6 to 8 year old, whether the air sound is pleasant, and
how it works with a finger on a real tablet.

## Design note

The original slice notes called Band A Steady Hands a "locked design": one Space tap that always
succeeds. This replaces it at the game owner's request, keeping the part that mattered (it cannot be
failed) and adding something to actually do.
