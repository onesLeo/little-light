# Sound design

The valley has a soundscape: a slow music-box lullaby, wind, a stream, birds, footsteps, a lamb that
says "baa", and butterflies that rustle as they take off. All of it is synthesized by code, so there
are no third-party recordings, and every file can be rebuilt and retuned.

## What you hear

| Sound | When | Where it is made |
|-------|------|------------------|
| Lullaby (music box, soft pad, bass), 42 s loop | from the start, fading in over 4 s | `Soundscape` |
| Wind, 16 s loop | always, very quiet; eases in over 6 s | `Soundscape` |
| Stream, 12 s loop | always, eases in over 6 s; louder and panned toward the water as you walk near it | `Soundscape` |
| Seven bird calls | every 4-11 s from somewhere around you; sometimes a second bird answers | `Soundscape` |
| Footsteps (four variations) | while the Wonder-Walker walks, two per walk cycle | `wonder_walker.gd` |
| Lamb "baa" (two variations) | when the lamb notices you, then every 6-11 s while you stay close | `lamb_life.gd` |
| Wing rustle | when butterflies take off; at most one every 0.4 s | `butterflies.gd` |
| Chimes, fanfare, cheer | pickups, Steady Hands, the finale (unchanged, made at startup by `chime_synth.gd`) | `audio_director.gd` |

## The mix

Everything plays on one of four buses under Master (`scripts/sound_bus.gd`):

| Bus | Carries | Base level |
|-----|---------|-----------|
| Music | the lullaby | -11 dB |
| Ambience | wind, stream, birds | -7 dB |
| Effects | chimes, footsteps, lamb, butterflies | -2 dB |
| Voice | Wonder Light and David | +3 dB |

The voice clips speak at about -23 dBFS, which the Voice bus lifts to about -20 dBFS. Rough levels
of everything else, in dBFS (RMS, before distance), so you can see what competes with the voice:

| Sound | Level | While somebody is speaking |
|-------|-------|----------------------------|
| Voice | -20 | |
| Music | -29 | -38 |
| Stream (right at the water) | -39 | -49 |
| Wind | -37 | -47 |
| Footsteps | -27 to -24 | |
| Lamb "baa" (3 m away) | about -21 | waits until the voice has finished |

Speech is easiest to follow when it is 15 dB or more above the background, so the ambience is kept
well below it. A limiter on the Master bus (ceiling -1 dB) means the louder voice plus a sound effect
can never clip.

**Ducking.** While anybody is speaking (a recorded clip, the gap between two clips, or system speech)
the Music bus drops 9 dB and Ambience 10 dB; it dips in a quarter of a second and comes back over a
second. Birds also stay silent while somebody is speaking, and the lamb waits to bleat until the
voice has finished. While the game is paused they drop about 60 % of that, and the music keeps playing behind the
menu.

**Volume sliders.** The pause menu has Volume (master), Music, Sounds (ambience and effects) and
Voices. They are saved in `user://settings.cfg`. A slider sets the bus level relative to its base
level, so 50 % is 6 dB quieter.

**Where things sound from.** 3D sounds (stream, birds, lamb, butterflies) are heard from the
Wonder-Walker, but panned the way the tabletop camera looks, so "the stream is on the left" matches
the screen. The stream sounds as if it is at the nearest point of the water.

## Rebuilding and tuning the sounds

```bash
python tools/make_sounds.py
```

It needs only Python's standard library, takes about 20 seconds, uses a fixed random seed, and prints
each file's length, peak and loudness (and, for loops, how big the jump is where the end meets the
start). Then import in Godot (`godot --headless --import .`, or just open the editor).

Where to change what:

- Notes, tempo and chords: `MELODY`, `CHORDS`, `BASS`, `BPM` in the music section.
- Bird calls: `BIRDS` (a list of rising, falling and warbling tones).
- The lamb: `render_bleat(dur, f_start, f_end, formant1, formant2, seed)`; the formants make the vowel.
- Overall balance: `BASE_DB` and `DUCK_DB` in `scripts/sound_bus.gd`, and the exported values on the
  `Soundscape` node (bird interval and distance, music fade-in, pause ducking).

## What was checked, and what was not

Checked by the smoke test: all 17 files load; the four buses exist and the players are routed to them;
music and wind loop; the stream follows the player along the water; a footstep plays when walking
and none when standing; the lamb says "baa" once when it notices you, then waits; a group of
butterflies taking off makes one rustle; birds and the lamb stay quiet during speech; the master limiter
is in place; the music ducks while speaking and while paused and comes
back; the sliders set the bus levels.

Checked by measuring the rendered files: no clipping, loops join without a click, the music's notes
are at the intended pitches, the lamb has energy at its two vowel formants (about 850 and 1500 Hz),
and a falling bird whistle really falls (3.9 kHz to 3.0 kHz).

**Not checked: how it sounds.** Nobody has listened to this in the running game yet. Please check
the loudness balance against the voice, whether the lullaby is pleasant or grating after a few
minutes, whether the lamb sounds like a lamb, and whether the stream is too loud beside the water.
The levels above are the first thing to tune.

## Not done

- A breathing sound for Steady Hands (goes with backlog 3.1).
- Different footstep sounds on the path and in the water.
- Sound for Wonder Light itself beyond the existing chimes.
