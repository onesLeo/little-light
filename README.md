# Little Light — David & Goliath P0.2 (Godot slice)

Vertical slice: Wonder-Walker explores a Bethlehem valley diorama, finds three Wonder Items, meets David (Band A), plays **Steady Hands**, then reflects with Joshua 1:9 (WEB). No violence is shown. Wonder-Walker is a **guest**, not David.

**Engine:** Godot **4.3+** (Forward+)

## Open & run

1. Install / open **Godot 4.3** (or newer 4.x).
2. **Import** → choose this folder (`godot-david-slice/`).
3. Wait for `.glb` imports (`assets/wonder_walker_v6.glb`, `assets/bethlehem_valley_v6.glb`, `assets/david_mentor_v6.glb`, `assets/wonder_items_v6.glb`).
4. Press **F5** (main scene: `res://scenes/main.tscn`).

## Controls

| Action        | Key   | Notes                                      |
|---------------|-------|--------------------------------------------|
| Move          | WASD  | Third-person; avatar faces move direction  |
| Continue / tap| Space | Dialogue advance; Steady Hands breathes    |
| Interact      | E     | Collect Wonder Item when near stone/staff/lamb |

## What you'll play through

1. **Arrive** — Wonder Light VO (Space to continue)
2. **Explore** — find 3 Wonder Items (stone / staff / lamb meshes), press **E**
3. **Meet David** — Band A auto line (no reply choices)
4. **Steady Hands** — press **Space** once (Band A; always succeeds)
5. **Resolution** — narrated off-screen; no fight
6. **Reflect** + **Joshua 1:9** + “Don't. Be. Afraid.” + Courage charm stub

## Project layout

```
godot-david-slice/
  project.godot
  scenes/main.tscn
  scripts/
    wonder_walker.gd
    steady_hands_minigame.gd
    chapter_director.gd
  assets/
    wonder_walker_v3.glb
    bethlehem_valley_v6.glb
    david_mentor_v2.glb
    wonder_items_v2.glb
```

## Notes / placeholders

- Valley, WW, David mentor, and wonder-item meshes are placeholder GLBs.
- Safety floor under the diorama so the player cannot fall forever.
- Tabletop camera is a `Camera3D` child of the player (~behind/above).
- Courage charm / Faith Journal are text stubs only in this slice.


## Band notes
- **Band A Steady Hands:** 1 Space tap (locked design — auto-succeed).
- Band B multi-tap can raise `taps_required` later.

- Wonder-Walker **v3**: paper-grain material + 12fps step walk animation (swap from Models Creations).

## Controls tip
WASD is **camera-relative** (W walks toward the top of the screen). Movement unlocks after the first Space on Arrive. Arrows also work.

## Lighting
Target: soft **paper-warm** diorama (not harsh studio). Lower sun, strong warm ambient, soft shadows, ACES tonemap.

## Collision
Valley + David meshes bake **trimesh StaticBody** colliders at runtime so the walker cannot pass through solids.


## Valley polish (v3)
- Paper-craft cypress + olive trees, shrubs, and rocks on the Judean hills silhouette.
- Flat matte materials + inverted-hull outlines (same paper-diorama look).
- Center play space kept mostly clear for roaming.


## Art version note (v6)

The scene uses the **v6** assets. `bethlehem_valley_v6.glb` is sculpted terrain
(valley floor, walls, back ridge, a cliff shelf) with the river carved into it
— an upper reach, a waterfall, a plunge pool and a lower reach — rather than
props laid on a flat slab. The character/prop `_v6` files are the v4/v5 models
with their outline hulls rebuilt: the old Solidify hulls rendered in Godot as
an opaque shell that made every character a black silhouette. Both are
generated from `art/blender/scripts/` — see that folder's README.

`SafetyFloor` sits at y=-2.5 because the riverbed is carved below y=0; at its
old y=-0.5 its top face capped the channel.

### Offscreen screenshots (no display needed)

`tests/screenshot_autoload.gd` saves the real Forward+ frame to
`/tmp/godot_screenshot.png`. Register it temporarily as an autoload in
`project.godot`:

```
[autoload]

ScreenshotHelper="*res://tests/screenshot_autoload.gd"
```

then run under a virtual display (`xvfb-run -a -s "-screen 0 1280x720x24" godot
--path . scenes/main.tscn`; software Vulkan via `mesa-vulkan-drivers` is
enough). `HIDE_NODE`, `CAM_POS`, `CAM_LOOK` and `SHOT_FRAME` steer the capture
— `HIDE_NODE` in particular is how you find out what is actually drawing at a
pixel. Remove the autoload again before committing.

## Alive stream pack

`assets/bethlehem_stream_fish_alive.glb` — papercraft brook + waterfall foam + 3 fish (12fps STEP loops). Instanced as `StreamFishAlive` on the west stream bank; static valley water/fish meshes are hidden at runtime. Water meshes skip collision via `mesh_collision_baker.gd`.

## Wonder-Walker v8

Player mesh uses `assets/wonder_walker_v8.glb` (solid hair crown for top-down read). `WW_Walk` @ 12fps STEP; import keeps `remove_immutable_tracks=false`.
## Courage charm award

After Joshua 1:9 / "Don't. Be. Afraid.", beat `CHARM_AWARD` plays a placeholder bracelet+charm float-snap ceremony (`scripts/charm_award.gd`). Swap meshes later with authored art.
