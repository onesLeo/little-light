# Audio credits

Almost everything in this folder is synthesized by `tools/make_sounds.py` and needs no credit.
The recorded voices, one recorded animal sound and the footsteps are the exceptions.

| Files | Source | Licence |
|-------|--------|---------|
| `vo/*.wav` (Wonder Light, David) | generated with a text-to-speech voice model (Seed Audio 1.0; voices "Juno" and "Bram"), then trimmed; see `docs/voice-over.md` | generated for this project |
| `sfx/bleat_1.wav` (the lamb) | "Sheep #2" by Joseph Sardin, [BigSoundBank](https://bigsoundbank.com/sheep-2-s2344.html), sound no. 2344. The original is kept in `tools/source/sheep_2_bigsoundbank.wav`. `tools/make_sounds.py` pitches it up by 30 %, removes the room boom and echo, and adds a little presence so it sounds small and close. | CC0 (public domain): free for any use, no attribution required. Credit is given here as a courtesy. |
| `sfx/step_path_1.wav` ... `step_path_4.wav` (steps on the trail) | "Footsteps on gravels #1" by Joseph Sardin, [BigSoundBank](https://bigsoundbank.com/detail-0510-steps-on-gravels.html), sound no. 510, kept whole in `tools/source/steps_gravel_bigsoundbank.wav`. `tools/make_sounds.py` finds the first four footfalls, keeps 0.24 s of each and shortens the crunch. | CC0 (public domain), as above. |
| `sfx/step_water_1.wav` ... `step_water_4.wav` (steps in the stream) | "Steps in the Mud" by Joseph Sardin, [BigSoundBank](https://bigsoundbank.com/steps-in-the-mud-s0495.html), sound no. 495, kept whole in `tools/source/steps_mud_bigsoundbank.wav`. The four "pops" where a boot leaves the mud are used, softened. Not real splashing: a stand-in until a recording of steps in shallow water is found. | CC0 (public domain), as above. |
| `sfx/step_1.wav` ... `step_4.wav` (footsteps on grass) | "Steps in the Grass, Slow" by Joseph Sardin, [BigSoundBank](https://bigsoundbank.com/steps-in-the-grass-slow-s1253.html), sound no. 1253. Four steps of the 24 s recording are kept in `tools/source/steps_grass_slow_excerpt.wav`. `tools/make_sounds.py` cuts each one from the moment the foot lands, keeps 0.26 s, and lets it fade faster with a gentle high cut, so it thuds instead of swishing. | CC0 (public domain), as above. |
