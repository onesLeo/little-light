# Audio credits

Almost everything in this folder is synthesized by `tools/make_sounds.py` and needs no credit.
The recorded voices, one recorded animal sound and the footsteps are the exceptions.

| Files | Source | Licence |
|-------|--------|---------|
| `vo/*.wav` (Wonder Light, David) | generated with a text-to-speech voice model (Seed Audio 1.0; voices "Juno" and "Bram"), then trimmed; see `docs/voice-over.md` | generated for this project |
| `sfx/bleat_1.wav` (the lamb) | "Sheep #2" by Joseph Sardin, [BigSoundBank](https://bigsoundbank.com/sheep-2-s2344.html), sound no. 2344. The original is kept in `tools/source/sheep_2_bigsoundbank.wav`. `tools/make_sounds.py` pitches it up by 30 %, removes the room boom and echo, and adds a little presence so it sounds small and close. | CC0 (public domain): free for any use, no attribution required. Credit is given here as a courtesy. |
| `sfx/step_1.wav` ... `step_4.wav` (footsteps) | "Steps in the Grass, Slow" by Joseph Sardin, [BigSoundBank](https://bigsoundbank.com/steps-in-the-grass-slow-s1253.html), sound no. 1253. Four steps of the 24 s recording are kept in `tools/source/steps_grass_slow_excerpt.wav`. `tools/make_sounds.py` cuts each one from the moment the foot lands, keeps 0.26 s, and lets it fade faster with a gentle high cut, so it thuds instead of swishing. | CC0 (public domain), as above. |
