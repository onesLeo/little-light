# Little Light — Blender generators

Procedural **Blender Python (`bpy`)** scripts that build papercraft / DOGWALK-inspired low-poly assets for *Little Light*, then export **glTF/GLB** for Godot 4.x.

These are **script-generated** meshes (often run headless). Hand polish in the Blender UI is optional afterward.

## Layout

```
art/blender/
  assets/textures/paper_grain.png
  scripts/characters/   # Wonder-Walker v1–v3
  scripts/props/        # David mentor + Wonder Items
  scripts/environments/ # Bethlehem valley placeholder
  scripts/_paths.py     # LITTLE_LIGHT_ART_OUT helper
  docs/                 # art-tech pipeline notes
  output/               # local exports (gitignored)
```

## Requirements

- Blender **4.x or 5.x** (tested with 5.2 LTS)
- Scripts use the Blender bundled Python (`bpy`)

## How to run

### In Blender UI
1. Open **Scripting** workspace
2. Open a generator `.py`
3. **Run Script**

### Headless (recommended for bots / CI)

```bash
# Optional: where .glb / .blend land
export LITTLE_LIGHT_ART_OUT="$PWD/art/blender/output"

blender --background --python art/blender/scripts/characters/generate_wonder_walker_v3.py
```

Windows (PowerShell) example:

```powershell
$env:LITTLE_LIGHT_ART_OUT = "C:\Users\onesa\wonder-walker"   # example only
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" --background --python art\blender\scripts\characters\generate_wonder_walker_v3.py
```

## Output

By default scripts should write under `art/blender/output/` when using `_paths.py`.  
Older generators may still embed an absolute Windows path — prefer setting `LITTLE_LIGHT_ART_OUT` until all scripts are fully migrated.

## Art constraints (locked for Little Light)

- Flat / matte shading + paper-grain + dark inverted-hull outline (exports to glTF; Freestyle does not)
- Stop-motion style ~**12fps** step poses for character walks
- **Wonder-Walker** = original child guest/helper (~1.15m), not “play as David”
- No graphic violence props (David chapter uses Steady Hands rhythm UI)

See `docs/little-light-art-tech-pipeline.md`.

## Latest character

Prefer **`generate_wonder_walker_v3.py`** (handmade silhouette jitter, creases, layered hair, grain, 12fps walk).
