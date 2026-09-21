# Performance

How heavy the game is, what was measured, and what was changed for tablets. Backlog item 5.1.

**The limit of these numbers:** everything below was measured on one development laptop (GeForce GTX 1660 Ti
Max-Q, 1280 x 720). It runs the whole frame in under 2 ms, so it says nothing about whether a real tablet
holds 60 frames per second. What carries over is the *amount of work* (triangles, draw calls, pixels) and
which parts of the frame are expensive relative to each other. **The game has not been run on a tablet.**

## How to measure

```bash
godot --path . --script tools/profile_frame.gd --resolution 1280x720
godot --path . --rendering-method mobile --script tools/profile_frame.gd --resolution 1280x720
```

It needs the real renderer (not `--headless`). The first table counts triangles and surfaces by group, the
second times the frame with one thing switched off at a time. The second command uses the Mobile renderer,
which is what Godot uses by default on Android and iOS (the project does not need to say so; checked in the
project settings). Run it on the tablet itself once there is a build. Differences under about 0.05 ms are
noise, and the costs do not add up to the total because parts share work.

Primitives and draw calls are counted **including the sun's shadow pass**, which draws most of the scene a
second time. The 375k triangles and 254 draw calls quoted earlier in the backlog were the main pass only.

## What was found

Before any change, in the game view (Forward+ renderer):

| | Triangles (one copy) | Per frame with shadows |
|---|---:|---:|
| The two characters and their outline hulls | 266,136 (62% of the scene) | about 530,000 of 793,000 |
| Whole scene | 428,106 | 793,450 primitives, 575 draw calls |

- **The characters were the problem.** David was 153,700 triangles and the Wonder-Walker 112,436, about 30,000 of
  each being skin, for a figure roughly 100 pixels tall. The whole terrain is 18,432. A character is drawn twice
  (once with its outline hull, which is a copy of the mesh) and again in the shadow pass. Neither has LODs: the
  Wonder-Walker is skinned, and David's import has LOD generation switched off.
- **Outline hulls cast shadows.** A hull is a slightly bigger copy of its mesh, so it went into the shadow map a
  second time. Switching that off removed about 184,000 primitives per frame.
- **Shadows are the biggest single item after the characters:** without them the frame is 388k primitives and
  295 draw calls, against 793k and 575.
- **Glow** costs about 0.6 ms of GPU time here, roughly a third of the frame. **Fill rate** is the other large item:
  drawing the 3D picture at half size (a quarter of the pixels) saved about 0.9 ms.
- **Draw calls** are dominated by the trees and bushes, which have four to six material surfaces each
  (156 surfaces for 32 plants, plus their outlines), then the stream pack (35 surfaces).
- **The Mobile renderer looks the same and is cheaper**: 332 draw calls instead of 575 and about a third less GPU
  time on the same scene, with no visual difference apart from a slightly whiter waterfall.
- Godot's mesh LOD threshold barely helps (about 14% fewer primitives even at 32 pixels), because most of the
  weight was in meshes that cannot use it.

## What was changed

1. **Characters roughly half as heavy** (`GAME_MESH_RATIO` in `generate_wonder_walker_v5.py`, 0.32 to 0.06; David uses
   the same function). Compared side by side in the tabletop view, the dialogue close-up, up close, and
   mid-stride, before and after: no visible difference. David 153,700 to 59,828 triangles, Wonder-Walker 112,436 to
   41,232. The files are half the size too (2.2 MB and 2.1 MB, from 4.4 and 4.6).
2. **Outline hulls no longer cast shadows** (`performance_tuning.gd`). The shadow of a hull is the shadow of
   the mesh it copies, so nothing changes visibly.
3. **On a phone or tablet the 3D picture is drawn at most 1600 pixels wide** and scaled up to the screen
   (`performance_tuning.gd`). Tablet screens are often 2000+ pixels wide, four times the pixels of 720p. The menus
   and dialogue are 2D and stay sharp. Computers are not touched.
4. **The smoke test keeps it that way**: no outline hull casts a shadow, the render-size rule works, and there is a
   triangle budget (characters 120,000, whole scene 290,000).

Result on the same laptop:

| | Before | After |
|---|---:|---:|
| Mesh triangles, whole scene | 428,106 | 263,030 |
| Characters with outlines | 266,136 | 101,060 |
| Primitives per frame, shadows included | 793,450 | 360,916 (-54%) |
| Draw calls, Forward+ / Mobile | 575 / 332 | 514 / 267 |
| GPU time, Forward+ | 1.86 ms | 1.7 to 1.9 ms (unchanged: not the limit on this GPU) |

## What is left, in the order I would do it

1. **Run it on a real tablet** and read the same table there. Until then everything above is a proxy.
2. **Draw calls.** Trees and bushes now share one material with the colour in the vertices, so each is two draws
   (body + outline) instead of four to seven: the valley file went from 261 surfaces to 137, and Forward+ draws from
   523 to 351. The **Mobile renderer read 275 both before and after**, so the tablet may not gain from this; only a
   real tablet will tell. The new rounded leaves cost more triangles (whole scene 263,030 to 272,590, primitives
   with shadows 361k to 405k), so the budget is now 290,000 with only about 17,000 to spare.
3. **Glow is off on a phone or tablet** (`performance_tuning.gd`, `apply_glow`). It costs about 0.6 ms here and needs a full-screen HDR pass, which mobile GPUs pay more for. Screenshots with it on and off are almost the same (a little less sparkle on the water; the Wonder Light's halo is its own mesh). If the tablet has frame time to spare, set `glow_on_handhelds` on the PerformanceTuning node to bring it back.
4. **The stream pack** (35 surfaces, 29 objects, plus 24 fish objects) could be merged.
5. **David's LODs.** Not needed at his current size.

## Before making an Android or iOS build

The project setting *Rendering > Textures > VRAM compression > Import ETC2 ASTC* is off. Godot needs it on for
mobile exports, and turning it on reimports every texture. This was left alone here because there is no export
preset yet.
