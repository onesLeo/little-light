# Little Light — David & Goliath P0.2 (Godot slice)

Vertical slice: Wonder-Walker explores a Bethlehem valley diorama, finds three Wonder Items, meets David (Band A), plays **Steady Hands**, then reflects with Joshua 1:9 (WEB). No violence is shown. Wonder-Walker is a **guest**, not David.

**Engine:** Godot **4.3+** (Forward+)

## Open & run

1. Install / open **Godot 4.3** (or newer 4.x).
2. **Import** → choose this folder (`godot-david-slice/`).
3. Wait for `.glb` imports (`assets/wonder_walker_v3.glb`, `assets/bethlehem_valley_v3.glb`, `assets/david_mentor_v2.glb`, `assets/wonder_items_v2.glb`).
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
    bethlehem_valley_v3.glb
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
