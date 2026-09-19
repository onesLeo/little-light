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

## Valley v6 (current)

`scripts/polish_valley_v6.py` replaces the v3–v5 "dress a flat slab" approach.
It builds the ground itself as a displaced heightfield — flat meadow for the
play area, valley walls, a back ridge, and a shelf whose steep front edge is
the waterfall cliff — and **carves the river into it**, so water sits between
banks instead of on top of them. Ground material is picked per face from a
smoothed slope/height field (grass, scrub, bare rock, sandy riverbed,
terracotta path); stones are noise-displaced icospheres; trees, rocks and
shrubs are planted at the terrain height under them.

```bash
blender --background --python art/blender/scripts/polish_valley_v6.py
blender --background --python art/blender/scripts/render_valley_preview_v6.py
```

### Two glTF gotchas worth knowing before you touch outlines

1. **Solidify makes a lid, not an outline.** `add_outline()` in v3–v5 used a
   Solidify modifier, which produces a *two-layer* shell — the grown skin plus
   a copy of the original surface. Blender never showed it because the preview
   scripts hide `*_Outline`, but in Godot it renders as an opaque shell that
   encases the model: the Wonder-Walker, David and the lambs all came out as
   flat black silhouettes. v6 builds a **single-skin** hull instead (push each
   vertex along its normal, flip the winding).
2. **Materials must be single-sided for an inverted hull to work.** Blender's
   default material exports as glTF `doubleSided: true`, which Godot imports as
   `cull_mode = Disabled` — and an unculled inverted hull is a lid again. v6
   sets `use_backface_culling = True`.

`scripts/fix_outlines_v6.py` applies both fixes to an already-exported GLB, so
a character does not have to be regenerated:

```bash
LL_FIX_IN=assets/wonder_walker_v5.glb LL_FIX_OUT=assets/wonder_walker_v6.glb \
  blender --background --python art/blender/scripts/fix_outlines_v6.py
```

It keeps armature modifiers and vertex groups, so the walk cycle still drives
the outline, and leaves body materials double-sided (some of these meshes have
winding that disagrees with their normals — culling them would make the
visible side of a character vanish).

## Latest character

Prefer **`generate_wonder_walker_v4.py`** — same rig/walk-cycle/head layout as v3,
but the torso is a tapered, beveled cylinder instead of a beveled cube, so
the body reads as a soft rounded human shape ("DOGWALK-style") instead of
blocks stacked together. Also bakes materials and builds the outline hull
inline (see "One-shot generation" below) instead of needing the separate
recolor + fix-outline passes v3 needed.

## Latest props

Prefer **`scripts/props/generate_david_and_items_v3.py`** for David mentor +
Wonder Items (stone/staff/lamb). Same rounded-torso treatment as WW v4, and
a substantially reworked `build_lamb()`: an elongated capsule body instead
of a near-sphere, legs splayed to the four corners so the body visibly
clears the ground, smoother/smaller overlapping wool blobs instead of a
handful of large jittery lumps (which read as a pile of rocks), floppier
ears, and a short tail — reads as an actual lamb rather than a wool
cushion. Shared by David's companion sheep and the collectible
`WonderItem_Lamb` (`is_ram=True` adds horns to the latter).

## One-shot generation (v4 / v3 props and later)

`generate_wonder_walker_v4.py` and `generate_david_and_items_v3.py` fold the
three-stage pipeline (generate → `recolor_characters_v3.py` → `fix_outlines_v6.py`)
into a single script:

- **Materials bake color+grain into a texture directly** instead of an
  RGB+MixRGB node graph. Blender's glTF exporter does not export that node
  graph faithfully — it keeps only the (near-white) grain texture and drops
  the color, so the model comes out bleached in Godot. See
  `_tinted_grain_image()` / `_bake_tinted_grain()`. Any new `paper()`-style
  material function should bake, not multiply-in-the-graph.
- **Outline hulls are single-skin from the start** (`single_skin_outline()`:
  grow each vertex along its normal, flip the winding, cull the outline
  material's backface) instead of a Solidify shell that needs a later fix
  pass — see the "Two glTF gotchas" section above for why Solidify alone
  renders as a black shell in Godot.

Run the same way as any other generator:

```bash
LITTLE_LIGHT_ART_OUT=$PWD/art/blender/output \
  blender --background --python art/blender/scripts/characters/generate_wonder_walker_v4.py
LITTLE_LIGHT_ART_OUT=$PWD/art/blender/output \
  blender --background --python art/blender/scripts/props/generate_david_and_items_v3.py
```

## Character liveliness pass

Wonder-Walker's and David's `Hand_*`/`Foot_*` blobs, and the lamb/sheep
hoof caps, are now built with `soft_blob()` / `make_soft_blob()` instead of
`blob()` / `make_blob()`: same handmade jitter, but smooth-shaded instead of
flat, so extremities read as soft and rounded against the flat-faceted
paper body rather than as faceted lumps.

The two sheep-shaped things in the game (David's companion and the
collectible `WonderItem_Lamb`) are now built from one shared
`build_lamb()` helper in `generate_david_and_items_v2.py`: body, head,
ears, snout, eyes, and four legs with soft hoof caps. Passing
`is_ram=True` (used for `WonderItem_Lamb`, the adult male) adds a pair of
short, backward-curving horns — two cone segments per side, chained tip to
tip using the segment's actual rotated endpoint rather than a guessed
offset, so they visibly join instead of floating apart.

New materials from this pass (`D_Snout`, `I_Eye`, `I_Horn`) are recolored
by `recolor_characters_v3.py` alongside the existing set — extend that
script's color dicts too if you add another new material name.

## Smooth heads and hair

Wonder-Walker's and David's `Head`, `Hair*` and `Cheek_*` are now built with
`make_soft_blob()` / `soft_blob()` (subdivision 3, whisper of jitter) instead of
the flat-shaded `blob()`, so heads and hair read as smooth and rounded rather
than faceted. Eyes stay flat. Regenerate with the usual chain: generator →
`recolor_characters_v3.py` → `fix_outlines_v6.py`.

## Hair back coverage

`Hair_3` (walker) and `Hair2` (David) are extra soft blobs over the back and
sides of the head. Before, hair only sat on top, so the camera behind the
player showed a bald back of the head. The nape stays bare on purpose.
