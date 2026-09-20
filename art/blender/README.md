# Little Light — Blender generators

Procedural **Blender Python (`bpy`)** scripts that build papercraft / DOGWALK-inspired low-poly assets for *Little Light*, then export **glTF/GLB** for Godot 4.x.

These are **script-generated** meshes (often run headless). Hand polish in the Blender UI is optional afterward.

## Layout

```
art/blender/
  assets/textures/paper_grain.png
  scripts/characters/   # Wonder-Walker v1–v5 and current David generator
  scripts/props/        # Wonder Items and historical David generators
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

blender --background --python art/blender/scripts/characters/generate_wonder_walker_v5.py
```

Windows (PowerShell) example:

```powershell
$env:LITTLE_LIGHT_ART_OUT = Join-Path (Get-Location) "art\blender\output"
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" --background --python art\blender\scripts\characters\generate_wonder_walker_v5.py
```

## Output

By default scripts should write under `art/blender/output/` when using `_paths.py`.  
Older generators may still embed an absolute Windows path — prefer setting `LITTLE_LIGHT_ART_OUT` until all scripts are fully migrated.

### Generator outputs versus scene assets

Run the examples from the repository root. The current character/props generators write:

| Generator | GLB outputs |
|-----------|-------------|
| `scripts/characters/generate_wonder_walker_v5.py` | `wonder_walker_v13.glb` |
| `scripts/characters/generate_wonder_walker_v4.py` | `wonder_walker_v12.glb` |
| `scripts/characters/generate_david_mentor_v4.py` | `david_mentor_v12.glb` |
| `scripts/props/generate_david_and_items_v3.py` | `david_mentor_v9.glb`, `wonder_items_v7.glb` |

The main scene loads **Walker v13, David v12, and items v7**. Use the separate David character generator for the current mentor; the older props generator still outputs David v9. Outputs stay in the output directory until explicitly copied into the project's `assets/` folder; generating a GLB does not change `scenes/main.tscn`. See the [project README](../../README.md#current-scene-assets) for all active scene assets. The technical notes below include earlier iterations as development history.

## Art constraints (locked for Little Light)

- Flat / matte shading + paper-grain + dark inverted-hull outline (exports to glTF; Freestyle does not)
- Stop-motion style ~**12fps** step poses for character walks
- **Wonder-Walker** = original child guest/helper (~1.15m), not “play as David”
- No graphic violence props (David chapter uses Steady Hands rhythm UI)

See `docs/little-light-art-tech-pipeline.md`.

## Valley v7 (current)

`scripts/polish_valley_v7.py` imports v6 and swaps only two builders, so
terrain, river, trees and layout are unchanged:

- **Bushes** (`Shrub_N`) are ~140 individual folded diamond leaves laid over a
  dome like shingles (two green families, upper faces in two greens so the fold
  reads as a midrib), instead of v6's squashed green sphere that read as a
  green rock. Runtime colliders for `Shrub*` are a convex hull, see
  `scripts/mesh_collision_baker.gd`.
- **Trees**: olives (`Olive_N`) get a leaning trunk that forks into three limbs carrying clumps of narrow, silver-backed leaves; cypresses (`Cypress_N`) are a slim flame-shaped column of overlapping fronds down to the ground. `Cypress*` colliders are a convex hull like shrubs.
- **Rocks** (`Rock_N`) keep v6's angular shape but use a baked stone texture
  (granular lumps, flecks, hairline cracks) in four variants: grey, limestone,
  slate and mossy grey with green patches. Per-face UV projection, linear
  filtering.

```bash
blender --background --python art/blender/scripts/polish_valley_v7.py
```

Import the GLB with `gltf/embedded_image_handling=3` (as v6 does), otherwise
Godot extracts every embedded texture into loose PNGs next to it.

## Valley v6

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

Use **`scripts/characters/generate_wonder_walker_v5.py`**, which produces
**Walker v13** and an editable `wonder_walker_v13.blend`. It imports the v4
generator's material/export helpers, so keep both scripts together.

V12 joined separate cylinders and spheres without welding their surfaces.
V13 builds continuous profiles for the limbs, palms, clothing and head;
voxel-remeshes the shoulder/sleeve junctions, thumbs and face/neck forms;
then assigns explicit, normalized weights. Knees and elbows no longer use
separate joint balls. The outline copies the body's weights exactly.
The blue tunic, coral sash and dark hair remain, with a thinner contour and
12fps stepped animation. [DOGWALK concept art](https://studio.blender.org/projects/dogwalk/3db3f971fec36a/)
is a style reference; the Walker mesh is generated locally.

After generation, copy `output/wonder_walker_v13.glb` to `assets/` at the
repository root and let Godot reimport it. Preserve `animation/fps=12` and
`animation/remove_immutable_tracks=false` in its `.import` settings. The
generator creates `.gdignore` in its output directory so intermediate Blender
files and review images are not imported as game assets.

From the repository root, validate the exported skeleton, STEP animation,
movement and active scene wiring:

```sh
godot --headless --path . --script tests/walker_visual_review.gd
godot --headless --path . --script tests/smoke_test.gd
```

Omit `--headless` from the Walker review to render before/after views and
four walk poses in Godot, plus the Walker in the valley. Images are saved to
`art/blender/output/review/`. On Windows, `--rendering-driver d3d12` can be
used to run the review with Forward+ on Direct3D 12. The separate Blender
helper `scripts/render_walker_review.py` also imports exported GLBs for
inspection; its `WW_REVIEW_ASSET` environment variable selects a path relative
to the repository root. Blender reviews hide outline hulls; Godot reviews
include them.

### Historical v4 generator (Walker v12)

The earlier **`generate_wonder_walker_v4.py`** uses the same rig/walk-cycle/head layout as v3,
but the torso is a tapered, beveled cylinder instead of a beveled cube, so
the body reads as a soft rounded human shape ("DOGWALK-style") instead of
blocks stacked together. Also bakes materials and builds the outline hull
inline (see "One-shot generation" below) instead of needing the separate
recolor + fix-outline passes v3 needed.

## Current David mentor

Use **`scripts/characters/generate_david_mentor_v4.py`** for **David v12**:

```sh
blender --background --python art/blender/scripts/characters/generate_david_mentor_v4.py
```

This imports Walker v5's geometry helpers and v4's material helpers, so keep
those scripts together. It writes `output/david_mentor_v12.glb` and the editable
`output/david_mentor_v12.blend`; copy the GLB into the repository's `assets/`
directory to update the game. It does not regenerate the Walker or collectibles.

The body has welded shoulder/sleeve transitions, tapered arms and wrists,
integrated thumbs, a shaped face and a closed smile. David is slightly taller
than the Walker, with a longer golden tunic, green sash, leather pouch, sandals,
and a distinct wavy scalp cap. His lamb uses a fused wool surface. All geometry
is static, with the root origin at his feet for the chapter's existing turn
and nod tweens. Body and outline meshes remain separate so the collision baker
can skip outlines. Hull thickness is 2.6 mm; outline materials cull back faces.

V11's mouth interiors and overlapping shells are not reused. The scene no
longer needs its old `FixDavidMentorVisuals` node, which pointed to the wrong
relative path and could not hide mouth surfaces merged into a larger mesh.

```sh
godot --headless --path . --script tests/david_visual_review.gd
```

Omit `--headless` to save front/rear/three-quarter comparisons and real dialogue
views under `output/review/`. On Windows, `--rendering-driver d3d12` selects
Forward+ on Direct3D 12. Review the exported GLB in Godot with its outlines
visible; a Blender render with hidden outlines cannot verify this fix.

## Wonder Items and historical David props

Use **`scripts/props/generate_david_and_items_v3.py`** for Wonder Items v7
(stone/staff/lamb). Its David v9 output is historical. That David used the same rounded-torso treatment as WW v4, and
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

## Visible neck

Both characters' heads used to sit flush on (and slightly sink into) the
torso top with no transition — a `soft_blob` head practically touching a
flat torso top reads as "glued on", not "attached by a neck". Both
generators now insert a short, visibly-narrower cylinder between
`shoulder_y`/`torso_top` and the head, then raise `head_z` to sit just
above it (a couple % overlap, not a hard seam). For the rigged
Wonder-Walker, `neck_h` is threaded through into `build_rig()` so the
`Neck` bone's edit-bone span actually matches the new geometry instead of
the old fixed `shoulder_y + 0.04` to `shoulder_y + 0.12` guess; the
`pin_head_vertices()` z-threshold from the hair fix above naturally splits
the neck's own weighting too — its lower half stays on `ARMATURE_AUTO`
(blends toward Chest, which is correct for a real neck), its upper half
gets pinned to Head. David has no armature, so it's pure static geometry
for him.

**First pass still read as "stacked", not attached.** The neck's base
radius was only ~35-40% of the torso-top's width, so there was a sharp
step straight down from a wide flat torso top to a narrow post — that
step is what reads as a separate part stacked on top, independent of how
smooth the neck's own surface is. Fixed by widening the base to ~60% of
the shoulder/torso-top radius (a gradual taper, not a step) and switching
from `limb()`/`make_limb()` (sharp-edged) to `make_torso()`'s beveled
construction for both rims. Lesson: a visible-part-boundary problem like
this is about the **radius jump at the seam**, not the part's own
geometry quality — smoothing the wrong thing doesn't fix it.

## A resting smile, not a blank stare

Both characters' mouths were a single flat oval `soft_blob` — reads as a
neutral-to-blank stare at rest, unlike a reference like DOGWALK where the
default face reads warm/pleasant even when idle. Added two small
`MouthCorner_L/R` blobs, slightly smaller than the main mouth shape and
offset a touch upward and outward, in the same mouth material. This is a
deliberately cheap technique — three overlapping soft blobs reading as a
curved smile via silhouette — chosen over trimming a torus into a true
arc, which would need bmesh angle-math tuned by eye in the Blender
viewport to get right; not something to get right blind from a script.
**This is a static default expression, not a dynamic system** — there's
no per-context (talking / neutral / smiling) expression swapping yet.
That would need multiple mouth/eye variants plus a swap trigger wired into
`chapter_director.gd`'s beats, which is a separate, larger feature.

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

## Hair detaching during the walk animation — a third glTF/rig gotcha

Wonder-Walker's hair looked correct in **every static shot** — Blender's
own render, and a Godot render with no animation playing — but went almost
fully bald in Godot specifically while `WW_Walk` was running. Comparing a
rest-pose Godot render (fine) against an animated one (bald) of the exact
same GLB is what isolated it: this is a runtime skinning issue, not a
geometry or material one, so a static preview screenshot can pass clean
and still ship a broken walk animation.

**Root cause:** `ARMATURE_AUTO`'s automatic bone weights are a proximity
heuristic, not a guarantee. The v3→v4 torso swap (beveled cube → wider
tapered cylinder) was enough to flip some hair vertices from "closest to
Head" to "closest to Chest". In the bind pose that's invisible; during the
walk cycle (legs/arms/chest all rotating) that hair gets dragged along
with the chest instead of the head and collapses into the torso.

**Fix, two parts:**
1. `pin_head_vertices()` forces every vertex at/above a z threshold
   (head/hair/cheeks/eyes/mouth — comfortably above the torso top and the
   arms' shoulder attachment, which both sit at `shoulder_y`) onto the
   `Head` bone with full weight, overriding `ARMATURE_AUTO`'s guess. Call
   it on **both** the body and its outline hull — they get independent
   `ARMATURE_AUTO` passes and can end up with different weights.
2. Consolidated hair from several small separate clumps into fewer,
   larger, generously-overlapping ones (`Hair_Crown`, `Hair_Back`,
   `Hair_Side_L/R`, `Hair_Fringe`). Several small islands are individually
   fragile — each only needs its own weights to be slightly off to leave a
   visible gap. One big overlapping mass tolerates that: a partially-off
   clump stays hidden under its neighbors instead of leaving a bald patch.
   This mirrors what this repo's own history already found necessary (see
   the "Wonder-Walker v8 ... solid hair crown for top-down read" note in
   the main README) — it just wasn't understood as a weighting problem
   until now.

**Verify any future hair/rig change against the actual animation, not just
a static pose**, e.g. in Godot:

```gdscript
anim_player.play("WW_Walk")
anim_player.speed_scale = 0.0
anim_player.seek(0.2 * anim_player.current_animation_length, true)  # then screenshot
```

**Clearance margins matter, not just position.** Two follow-up bugs came
from hair/fringe geometry sitting *too close* to a boundary rather than in
the wrong place outright:
- `Hair_Fringe` on David dipped low enough to overlap the eyes' top edge,
  reading as a thick uni-brow instead of forehead hair.
- `Hair_Crown` on the Wonder-Walker was a hair's-width shorter than the
  Head blob's own apex, so skin poked through right at the crown — most
  visible from the tabletop camera's above-and-behind angle.

Both were fixed by adding real margin (not just flipping a sign), and
both were caught only by looking at the actual in-engine angle the bug
showed up from (close-up front for the brow, tabletop-camera-angle from
above for the crown) — a generic front-on render didn't reveal either.

## The "Roblox rigid" fix — animate the elbow, add joint volume

A side-by-side with a reference (DOGWALK) surfaced why the walk read as
stiff/segmented rather than smooth: `UpperArm_*` and `LowerArm_*` bones
both existed in the rig since v3, but `walk()` only ever keyframed
`UpperArm` — the elbow was never animated, so the whole arm swung as one
rigid rod pivoting only at the shoulder. That is *exactly* the classic
"Roblox" look: separate rigid parts that pivot at a joint instead of a
mesh that actually bends through it.

Fix:
- `LowerArm_L/R` now get a rotation keyframe at every walk-cycle pose — a
  resting bend that's never fully straight, plus a fraction of the
  shoulder swing (`al * 0.35 + 14` degrees) so the elbow visibly moves
  with the stride instead of tagging along rigidly.
- Added small `soft_blob` "Elbow"/"Knee" bulges centered exactly on each
  bone-pair's shared boundary (`shoulder_y - arm_len * 0.5` for the elbow,
  `leg_len * 0.5` for the knee — the latter already matches the leg
  cone's own geometric center). This adds volume so the joint reads as an
  actual hinge instead of a cone quietly bending partway along its length.
  Unlike the hair case, this does *not* need explicit vertex pinning:
  `ARMATURE_AUTO` blends a small blob centered on a joint boundary
  reasonably well on its own — pinning is for when the automatic guess
  gets it *wrong*, not a default to reach for everywhere.
- Legs already had two animated bones (`Thigh`/`Shin`) since v3, so the
  knee was already bending — it only lacked the same volume/readability
  treatment as the elbow.

Still open if picking this up again: more joints per limb / secondary
motion (follow-through, hip-spine counter-rotation). The 12fps STEP
cadence itself is done — see below.

## The 12fps STEP cadence, actually completed

The art constraints call for "~12fps step poses", but `walk()` only ever
keyed 4 of the 12 frames (1, 4, 7, 10), each held 3 frames — the shipped
cadence was really **~4 poses/sec**, not 12. Checked with the project
owner before touching this (the alternative was dropping the stop-motion
style for smooth interpolation entirely — declined; this keeps the snap,
just completes the pose density the constraint already called for).

A second, independent bug was hiding underneath: the line meant to make
poses snap instead of blend,
`bpy.context.preferences.edit.keyframe_new_interpolation_type = "CONSTANT"`,
is a **UI preference** — it doesn't reliably govern script-driven
`keyframe_insert()` calls, and was wrapped in a bare `try/except` that
silently swallowed the failure. The exported glTF animation had been
**LINEAR**-interpolated all along, not STEP. Caught by inspecting the
exported GLB's animation samplers directly rather than trusting the
Blender-side setting:

```python
import struct, json
with open("wonder_walker_v12.glb", "rb") as f:
    data = f.read()
# ...parse the glTF JSON chunk, then for each animation sampler:
print(sampler["interpolation"])  # was "LINEAR", should be "STEP"
```

Fix:
- `walk()` now keys every one of the 12 frames, each pose eased
  (`smoothstep`) between the same 4 proven cardinal poses (contact/passing,
  mirrored) rather than inventing new pose data — same motion, denser
  sampling of it.
- Interpolation is now forced directly on every fcurve's keyframe points
  (`kp.interpolation = "CONSTANT"`) right before export, which is what a
  glTF exporter actually reads — not the preferences dialog. If you ever
  need STEP-interpolated keyframes from a script again, this is the
  reliable way to get them; don't reach for the preferences property.
