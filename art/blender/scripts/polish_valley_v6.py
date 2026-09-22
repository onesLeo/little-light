"""
Little Light — Bethlehem Valley (v6): sculpted terrain, natural stone, real river.

What changed from v5 and why
----------------------------
v5 dressed a flat imported slab: every prop sat at z=0, the "stream" was a row
of axis-aligned cubes and the waterfall was a stack of cubes, which reads as
floating blue boxes rather than water. v6 builds the ground itself, so the
layout can be shaped like an actual valley:

* A displaced heightfield: a flat meadow for the play area, valley walls
  rising on both sides, a ridge across the back, and a shelf (plateau) at the
  back-left whose steep front edge is the waterfall cliff.
* The river is *carved into* that heightfield — an upper reach along the
  shelf, a plunge basin at the cliff foot, and a lower reach winding out of
  the front-left corner — so the water sits between banks instead of on top
  of the ground. Water surfaces are laid at the carved channel's level.
* Ground material is chosen per face from slope, height and distance to the
  river/path: grass on the flat, scrub up high, bare rock on anything steep,
  sand in the riverbed, terracotta on the trail.
* Stones are noise-displaced icospheres (angular, all different) rather than
  squashed spheres, and everything — trees, rocks, shrubs — is planted at the
  terrain height under it.

Outlines: v5's add_outline() used a Solidify modifier, which produces a
*two-layer* shell. In Godot that renders as an opaque lid over the model
rather than a rim (no cull mode can fix a two-layer shell), so v6 builds a
true single-skin inverted hull instead: push every vertex along its normal,
flip the winding, done.

Coordinates: Blender is Z-up; glTF export converts to Godot's Y-up, mapping
Blender (x, y, z) -> Godot (x, z, -y). So Blender +Y is *away* from the
tabletop camera (the back of the diorama), which is where the ridge, the
shelf and the waterfall live. The gameplay props sit near Blender origin:
David at (0, 3), the Wonder Items along y=0 from x=0..3, the Wonder-Walker
spawn at (0, -4) — the meadow is kept flat across all of that.

Run:
    blender --background --python art/blender/scripts/polish_valley_v6.py
Env:
    LL_VALLEY_OUT   output .glb   (default assets/bethlehem_valley_v6.glb)
    LL_PAPER_GRAIN  grain texture (default art/blender/assets/textures/paper_grain.png)
"""
import bpy
import bmesh
import math
import os
import random
from mathutils import Vector, Euler
from mathutils import noise as bnoise

REPO = os.environ.get("LL_REPO", os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "..")))
OUT_GLB = os.environ.get("LL_VALLEY_OUT", os.path.join(
    REPO, "assets", "bethlehem_valley_v6.glb"))
GRAIN = os.environ.get("LL_PAPER_GRAIN", os.path.join(
    REPO, "art", "blender", "assets", "textures", "paper_grain.png"))

GRAIN_MIX = 0.15
SEED = 20260918

# -- Palette (carried over from v5, plus riverbed / scrub / cliff) -----------
COL_HILL = (0.55, 0.68, 0.48, 1.0)       # meadow grass
COL_SCRUB = (0.44, 0.58, 0.40, 1.0)      # drier growth up the valley walls
COL_PATH = (0.82, 0.61, 0.43, 1.0)       # warm terracotta trail
COL_ROCK = (0.62, 0.64, 0.70, 1.0)       # cool grey-blue stone
COL_CLIFF = (0.56, 0.57, 0.62, 1.0)      # exposed valley wall / cliff face
COL_BED = (0.78, 0.72, 0.56, 1.0)        # sandy riverbed
COL_CYPRESS = (0.25, 0.55, 0.28, 1.0)
COL_OLIVE = (0.45, 0.62, 0.32, 1.0)
COL_TRUNK = (0.55, 0.35, 0.22, 1.0)
COL_SHRUB = (0.35, 0.55, 0.32, 1.0)
COL_WATER = (0.25, 0.55, 0.75, 1.0)
COL_WATER_DEEP = (0.18, 0.42, 0.65, 1.0)
COL_FOAM = (0.96, 0.98, 0.99, 1.0)
COL_FISH_ORANGE = (0.95, 0.55, 0.18, 1.0)
COL_FISH_GOLD = (0.95, 0.78, 0.25, 1.0)
COL_FISH_BLUE = (0.35, 0.60, 0.90, 1.0)
COL_OUTLINE = (0.08, 0.06, 0.05, 1.0)

# -- Layout ------------------------------------------------------------------
EXTENT = 30.0            # terrain spans +-EXTENT on x and y
CELL = 0.62
MEADOW = (-9.0, -9.5, 9.0, 4.8)     # flat play area (x0, y0, x1, y1)
MEADOW_BLEND = 3.2
WALL_HEIGHT = 5.2
SHELF = (-15.0, 5.9, -3.8, 16.0)    # back-left plateau (x0, y0, x1, y1)
SHELF_Z = 3.1
SHELF_EDGE = 0.5                    # small = steep cliff
CLIFF_Y = SHELF[1]

UPPER_RIVER = [(-7.4, 15.0), (-7.0, 12.4), (-6.8, 9.8), (-6.6, 7.6), (-6.45, 6.2)]
LOWER_RIVER = [(-6.45, 4.35), (-6.8, 2.6), (-7.4, 0.4), (-8.2, -2.2),
               (-9.2, -5.0), (-10.5, -8.2), (-12.0, -11.5)]
CHANNEL_HALF = 0.85
CHANNEL_DEPTH = 0.42
POOL = (-6.45, 4.5)
POOL_R = 1.7
POOL_DEPTH = 0.55
WATER_DROP = 0.18        # water surface sits this far below the bank lip

PATH = [(0.3, -9.5), (0.2, -7.6), (0.1, -5.6), (0.25, -3.6), (0.45, -1.6),
        (0.5, 0.2), (0.42, 1.6), (0.55, 2.4), (0.6, 3.0)]
PATH_HALF = 0.62

rng = random.Random(SEED)


# -- Small maths helpers -----------------------------------------------------

def clamp(v, a=0.0, b=1.0):
    return max(a, min(b, v))


def smoothstep(a, b, x):
    if abs(b - a) < 1e-9:
        return 0.0 if x < a else 1.0
    t = clamp((x - a) / (b - a))
    return t * t * (3.0 - 2.0 * t)


def lerp(a, b, t):
    return a + (b - a) * t


def rect_dist(x, y, r):
    """Distance from (x, y) to rect (x0, y0, x1, y1); 0 inside."""
    dx = max(r[0] - x, x - r[2], 0.0)
    dy = max(r[1] - y, y - r[3], 0.0)
    return math.hypot(dx, dy)


def polyline_dist(x, y, pts):
    best = float("inf")
    for i in range(len(pts) - 1):
        ax, ay = pts[i]
        bx, by = pts[i + 1]
        abx, aby = bx - ax, by - ay
        denom = abx * abx + aby * aby
        t = 0.0 if denom < 1e-9 else clamp(((x - ax) * abx + (y - ay) * aby) / denom)
        best = min(best, math.hypot(x - (ax + abx * t), y - (ay + aby * t)))
    return best


def fbm(x, y, scale=0.085, octaves=3):
    """Deterministic fractal noise in roughly -1..1 (mathutils, no numpy seed)."""
    total, amp, freq, norm = 0.0, 1.0, 1.0, 0.0
    for _ in range(octaves):
        total += bnoise.noise(Vector((x * scale * freq + 11.3,
                                      y * scale * freq - 7.1, 0.5))) * amp
        norm += amp
        amp *= 0.5
        freq *= 2.0
    return total / norm


# -- Height field ------------------------------------------------------------

def channel_weight(x, y, pts, half=CHANNEL_HALF):
    """1 at the channel floor, easing to 0 at the bank top."""
    d = polyline_dist(x, y, pts)
    return 1.0 - smoothstep(half * 0.5, half * 1.9, d)


def terrain_height(x, y):
    """The valley surface, before the river is carved into it."""
    d_out = rect_dist(x, y, MEADOW)
    rise = smoothstep(0.0, MEADOW_BLEND + 7.0, d_out)
    h = rise * WALL_HEIGHT
    # Rough ground only on the slopes; the meadow stays walkable-flat.
    h += fbm(x, y) * 1.15 * rise
    h += fbm(x, y, scale=0.22) * 0.35 * rise
    h += fbm(x, y, scale=0.3) * 0.06 * (1.0 - rise)
    # Ridge across the back, rising to a solid skyline so the camera never
    # sees over the far edge of the mesh.
    h += smoothstep(4.0, 15.0, y) * 3.4
    h += smoothstep(16.0, 29.0, max(abs(x), abs(y))) * 5.0
    return h


def height_at(x, y):
    """Final ground height: terrain, shelf, then the river carved in."""
    h = terrain_height(x, y)
    # Flat shelf at the back-left; its front edge becomes the cliff.
    sm = 1.0 - smoothstep(0.0, SHELF_EDGE, rect_dist(x, y, SHELF))
    # SHELF_EDGE is only 0.5 m wide, about one terrain grid cell, so without
    # this the cliff face was one flat, razor-straight ramp between two grid
    # rows. wall_band is 0 on the flat shelf top and 0 out on ordinary
    # terrain, peaking right on the face itself, so this noise gives the wall
    # slab its own uneven, faceted relief (on top of make_ledges()'s separate
    # embedded boulders) instead of touching the meadow or the shelf top.
    wall_band = sm * (1.0 - sm) * 4.0
    shelf_h = SHELF_Z + fbm(x, y, scale=0.25) * 0.12 + fbm(x, y, scale=0.4, octaves=2) * 0.4 * wall_band
    h = lerp(h, shelf_h, sm)
    # Upper reach runs along the shelf, lower reach across the meadow.
    wu = channel_weight(x, y, UPPER_RIVER) * sm
    h = lerp(h, SHELF_Z - CHANNEL_DEPTH, wu)
    wl = channel_weight(x, y, LOWER_RIVER, CHANNEL_HALF * 1.1)
    h = lerp(h, -CHANNEL_DEPTH, wl)
    # Plunge basin under the fall.
    wp = 1.0 - smoothstep(POOL_R * 0.45, POOL_R, math.hypot(x - POOL[0], y - POOL[1]))
    h = lerp(h, -POOL_DEPTH, wp)
    return h


UPPER_WATER_Z = SHELF_Z - CHANNEL_DEPTH + WATER_DROP
LOWER_WATER_Z = -CHANNEL_DEPTH + WATER_DROP


# -- Materials ---------------------------------------------------------------

def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.images):
        for b in list(block):
            if b.users == 0:
                block.remove(b)


def _bake_tinted_grain(name, color, grain_path, mix_fac=GRAIN_MIX):
    """Pack image = (grain*mix + (1-mix)) * color — bright albedo for Godot."""
    import numpy as np
    size = 256
    if grain_path and os.path.isfile(grain_path):
        src = bpy.data.images.load(grain_path)
        src.scale(size, size)
        pix = np.array(src.pixels[:], dtype=np.float32).reshape(size, size, 4)
        g = pix[:, :, :3]
        g_mean = float(g.mean()) + 1e-6
        g = np.clip(g / g_mean * 0.85, 0.55, 1.0)
    else:
        g = np.ones((size, size, 3), dtype=np.float32)
    grain = g * mix_fac + (1.0 - mix_fac)
    tint = np.array(color[:3], dtype=np.float32).reshape(1, 1, 3)
    rgb = np.clip(grain * tint * 1.05, 0.0, 1.0)
    alpha = np.ones((size, size, 1), dtype=np.float32)
    out = np.concatenate([rgb, alpha], axis=2).reshape(-1)
    img = bpy.data.images.new(f"Tint_{name}", width=size, height=size, alpha=True)
    img.pixels = out.tolist()
    img.pack()
    return img


def matte(name, color, grain_path=None, mix_fac=GRAIN_MIX, roughness=0.95):
    # Shared by name: every prop of a kind reuses one material, so the grain
    # texture is baked once instead of per object (smaller GLB, fewer Godot
    # materials, much faster export).
    existing = bpy.data.materials.get(name)
    if existing is not None:
        return existing
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = roughness
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.05
    elif "Specular" in bsdf.inputs:
        bsdf.inputs["Specular"].default_value = 0.05
    bsdf.inputs["Base Color"].default_value = color
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = _bake_tinted_grain(name, color, grain_path, mix_fac=mix_fac)
    tex.interpolation = "Closest"
    uv = nt.nodes.new("ShaderNodeTexCoord")
    mapn = nt.nodes.new("ShaderNodeMapping")
    mapn.inputs["Scale"].default_value = (4.0, 4.0, 4.0)
    nt.links.new(uv.outputs["Object"], mapn.inputs["Vector"])
    nt.links.new(mapn.outputs["Vector"], tex.inputs["Vector"])
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mat.diffuse_color = color
    # Blender's default (double-sided) exports as glTF doubleSided:true, which
    # Godot imports as cull_mode=Disabled. That is what made the old outline
    # hulls render as a lid: with no culling, the hull's near side is drawn
    # over the model. Single-sided keeps the hull to a rim and halves the
    # fill cost everywhere else. Winding is built correct below.
    mat.use_backface_culling = True
    return mat


def shade_flat(obj):
    for poly in obj.data.polygons:
        poly.use_smooth = False


def add_outline(obj, thickness=0.03):
    """A single-skin inverted hull.

    Not Solidify: that builds a two-layer shell, and in Godot the near layer
    renders as an opaque lid over the model instead of a rim. Pushing the
    vertices out along their normals and flipping the winding gives one skin,
    which back-face culling reduces to the silhouette line we want.
    """
    outline = obj.copy()
    outline.data = obj.data.copy()
    outline.name = obj.name + "_Outline"
    bpy.context.collection.objects.link(outline)

    bm = bmesh.new()
    bm.from_mesh(outline.data)
    bm.normal_update()
    for v in bm.verts:
        v.co += v.normal * thickness
    for f in bm.faces:
        f.normal_flip()
    bm.to_mesh(outline.data)
    bm.free()

    mat = matte("OutlineBlack", COL_OUTLINE, mix_fac=0.0)
    outline.data.materials.clear()
    outline.data.materials.append(mat)
    shade_flat(outline)
    return outline


def join_selected(name):
    bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = name
    return obj


def select_only(objs):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]


# -- Terrain mesh ------------------------------------------------------------

def surface_slope_deg(x, y, eps=0.9):
    """Slope from the analytic height field over ~2m, not from one triangle.

    Per-triangle slope on a noisy mesh flips between categories from face to
    face, which speckles the hillsides with grey confetti. Sampling wider
    gives coherent patches.
    """
    hx = (height_at(x + eps, y) - height_at(x - eps, y)) / (2.0 * eps)
    hy = (height_at(x, y + eps) - height_at(x, y - eps)) / (2.0 * eps)
    return math.degrees(math.atan(math.hypot(hx, hy)))


def build_terrain():
    """One flat-shaded heightfield with per-face materials."""
    mats = [
        matte("V_Hill", COL_HILL, GRAIN),
        matte("V_Scrub", COL_SCRUB, GRAIN),
        matte("V_Rock", COL_CLIFF, GRAIN),
        matte("V_Bed", COL_BED, GRAIN),
        matte("V_Path", COL_PATH, GRAIN),
    ]
    M_HILL, M_SCRUB, M_ROCK, M_BED, M_PATH = range(5)

    n = int((EXTENT * 2.0) / CELL)
    verts, faces = [], []
    for j in range(n + 1):
        for i in range(n + 1):
            x = -EXTENT + i * CELL
            y = -EXTENT + j * CELL
            verts.append((x, y, height_at(x, y)))
    for j in range(n):
        for i in range(n):
            a = j * (n + 1) + i
            b = a + 1
            c = a + (n + 1)
            d = c + 1
            # Alternate the split so slopes don't show a single diagonal grain.
            if (i + j) % 2 == 0:
                faces.append((a, b, d))
                faces.append((a, d, c))
            else:
                faces.append((a, b, c))
                faces.append((b, d, c))

    mesh = bpy.data.meshes.new("Valley_TerrainMesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    for m in mats:
        mesh.materials.append(m)

    for poly in mesh.polygons:
        poly.use_smooth = False
        cx = sum(verts[v][0] for v in poly.vertices) / len(poly.vertices)
        cy = sum(verts[v][1] for v in poly.vertices) / len(poly.vertices)
        cz = sum(verts[v][2] for v in poly.vertices) / len(poly.vertices)
        # Low-frequency noise on the threshold breaks the boundary into
        # organic outcrops instead of a clean contour line.
        slope = surface_slope_deg(cx, cy) + fbm(cx, cy, scale=0.05) * 7.0
        in_upper = polyline_dist(cx, cy, UPPER_RIVER) < CHANNEL_HALF * 1.5 and cy > CLIFF_Y
        in_lower = polyline_dist(cx, cy, LOWER_RIVER) < CHANNEL_HALF * 1.7
        in_pool = math.hypot(cx - POOL[0], cy - POOL[1]) < POOL_R * 1.15
        # Bare rock only where ground really is too steep to hold soil —
        # a lower threshold turned the whole valley wall grey.
        if slope > 44.0:
            poly.material_index = M_ROCK
        elif in_upper or in_lower or in_pool:
            poly.material_index = M_BED
        elif polyline_dist(cx, cy, PATH) < PATH_HALF and slope < 18.0:
            poly.material_index = M_PATH
        elif cz > 3.4 + fbm(cx, cy, scale=0.06) * 1.3 or slope > 24.0:
            poly.material_index = M_SCRUB
        else:
            poly.material_index = M_HILL

    obj = bpy.data.objects.new("Valley_Terrain", mesh)
    bpy.context.collection.objects.link(obj)
    return obj


# -- Props -------------------------------------------------------------------

def make_boulder(x, y, s=0.5, seed=0):
    """Angular stone: an icosphere with every vertex knocked about by noise."""
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=s, location=(0, 0, 0))
    obj = bpy.context.active_object
    obj.name = f"Rock_{seed}"
    ox, oy, oz = rng.uniform(0, 50), rng.uniform(0, 50), rng.uniform(0, 50)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    for v in bm.verts:
        k = 1.0 + bnoise.noise(Vector((v.co.x * 2.4 + ox,
                                       v.co.y * 2.4 + oy,
                                       v.co.z * 2.4 + oz))) * 0.55
        v.co *= k
    bm.to_mesh(obj.data)
    bm.free()
    obj.scale = (1.0 + rng.uniform(0.0, 0.5), 1.0 + rng.uniform(0.0, 0.35),
                 0.55 + rng.uniform(0.0, 0.3))
    obj.rotation_euler = Euler((rng.uniform(-0.25, 0.25), rng.uniform(-0.25, 0.25),
                                rng.uniform(0, math.tau)), "XYZ")
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    # Settle it into the ground so it doesn't look dropped on top.
    zs = [v.co.z for v in obj.data.vertices]
    obj.location = (x, y, height_at(x, y) - min(zs) - s * 0.3)
    obj.data.materials.append(matte("RockMat", COL_ROCK, GRAIN))
    shade_flat(obj)
    add_outline(obj, 0.022)
    return obj


def make_cypress(x, y, h=6.5, seed=0):
    z = height_at(x, y) - 0.05
    mats = {"trunk": matte("Trunk", COL_TRUNK, GRAIN),
            "leaf": matte("CypressLeaf", COL_CYPRESS, GRAIN)}
    parts = []
    trunk_h = h * 0.22
    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.14 * (h / 6.5),
                                        depth=trunk_h, location=(x, y, z + trunk_h * 0.5))
    trunk = bpy.context.active_object
    trunk.data.materials.append(mats["trunk"])
    shade_flat(trunk)
    parts.append(trunk)
    for i, (zh, r_frac, d_frac) in enumerate([(0.38, 0.12, 0.32), (0.55, 0.095, 0.30),
                                              (0.72, 0.07, 0.28), (0.88, 0.045, 0.24)]):
        bpy.ops.mesh.primitive_cone_add(vertices=7, radius1=h * r_frac, radius2=0.02,
                                        depth=h * d_frac, location=(x, y, z + h * zh))
        leaf = bpy.context.active_object
        leaf.data.materials.append(mats["leaf"])
        shade_flat(leaf)
        parts.append(leaf)
    select_only(parts)
    obj = join_selected(f"Cypress_{seed}")
    add_outline(obj, 0.045)
    return obj


def make_olive(x, y, s=2.2, seed=0):
    z = height_at(x, y) - 0.05
    mats = {"trunk": matte("OliveTrunk", COL_TRUNK, GRAIN),
            "leaf": matte("OliveLeaf", COL_OLIVE, GRAIN)}
    parts = []
    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.09 * s, depth=0.65 * s,
                                        location=(x, y, z + 0.32 * s))
    trunk = bpy.context.active_object
    trunk.data.materials.append(mats["trunk"])
    shade_flat(trunk)
    parts.append(trunk)
    for ox, oy, oz, r in [(0.0, 0.0, 0.85, 0.50), (0.28, 0.12, 0.78, 0.36),
                          (-0.25, -0.14, 0.76, 0.34), (0.08, 0.22, 0.95, 0.30),
                          (-0.1, 0.05, 1.05, 0.24)]:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=r * s,
                                              location=(x + ox * s, y + oy * s, z + oz * s))
        canopy = bpy.context.active_object
        canopy.data.materials.append(mats["leaf"])
        shade_flat(canopy)
        parts.append(canopy)
    select_only(parts)
    obj = join_selected(f"Olive_{seed}")
    add_outline(obj, 0.035)
    return obj


def make_shrub(x, y, s=0.55, seed=0):
    z = height_at(x, y)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=s,
                                          location=(x, y, z + s * 0.5))
    obj = bpy.context.active_object
    obj.name = f"Shrub_{seed}"
    obj.scale = (1.1, 0.9, 0.7)
    bpy.ops.object.transform_apply(scale=True)
    obj.data.materials.append(matte("ShrubMat", COL_SHRUB, GRAIN))
    shade_flat(obj)
    add_outline(obj, 0.022)
    return obj


# -- River -------------------------------------------------------------------

def _ribbon(name, pts, z_of, half_width, mat):
    """Water surface strip following a centreline."""
    verts, faces = [], []
    for i, (x, y) in enumerate(pts):
        if i == 0:
            dx, dy = pts[1][0] - x, pts[1][1] - y
        elif i == len(pts) - 1:
            dx, dy = x - pts[i - 1][0], y - pts[i - 1][1]
        else:
            dx, dy = pts[i + 1][0] - pts[i - 1][0], pts[i + 1][1] - pts[i - 1][1]
        ln = math.hypot(dx, dy) or 1.0
        sx, sy = -dy / ln * half_width, dx / ln * half_width
        z = z_of(x, y)
        verts.append((x - sx, y - sy, z))
        verts.append((x + sx, y + sy, z))
    for i in range(len(pts) - 1):
        a = i * 2
        faces.append((a, a + 1, a + 3, a + 2))
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    face_normals_up(obj)
    shade_flat(obj)
    return obj


def face_normals_up(obj):
    """Flip any face pointing downwards — an open strip built left-to-right
    comes out facing -Z, which single-sided materials would render as a hole."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    for f in bm.faces:
        if f.normal.z < 0.0:
            f.normal_flip()
    bm.to_mesh(obj.data)
    bm.free()


def build_river():
    water = matte("WaterTeal", COL_WATER, GRAIN, mix_fac=0.10, roughness=0.25)
    deep = matte("WaterDeep", COL_WATER_DEEP, GRAIN, mix_fac=0.10, roughness=0.25)
    foam_mat = matte("FoamWhite", COL_FOAM, GRAIN, mix_fac=0.08)

    _ribbon("Stream_Upper", UPPER_RIVER, lambda x, y: UPPER_WATER_Z,
            CHANNEL_HALF * 0.95, water)
    _ribbon("Stream_Lower", LOWER_RIVER, lambda x, y: LOWER_WATER_Z,
            CHANNEL_HALF * 1.05, water)

    # Plunge pool.
    bpy.ops.mesh.primitive_circle_add(vertices=14, radius=POOL_R * 0.92, fill_type="NGON",
                                      location=(POOL[0], POOL[1], LOWER_WATER_Z))
    pool = bpy.context.active_object
    pool.name = "Stream_Pool"
    pool.scale = (1.15, 1.0, 1.0)
    bpy.ops.object.transform_apply(scale=True)
    pool.data.materials.append(deep)
    shade_flat(pool)

    # The fall itself: a curved sheet from the lip down to the pool, given a
    # little thickness so it reads as water from any angle.
    lip_x = UPPER_RIVER[-1][0]
    top_z = UPPER_WATER_Z
    bot_z = LOWER_WATER_Z + 0.05
    segs = 9
    verts, faces = [], []
    for i in range(segs + 1):
        t = i / segs
        y = CLIFF_Y - 0.06 - 0.62 * t * t          # bulges outward as it falls
        z = lerp(top_z, bot_z, t ** 1.18)
        w = lerp(CHANNEL_HALF * 0.85, CHANNEL_HALF * 1.25, t)
        verts.append((lip_x - w, y, z))
        verts.append((lip_x + w, y, z))
    for i in range(segs):
        a = i * 2
        faces.append((a, a + 1, a + 3, a + 2))
    mesh = bpy.data.meshes.new("Waterfall_SheetMesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    mesh.materials.append(water)
    fall = bpy.data.objects.new("Waterfall_Sheet", mesh)
    bpy.context.collection.objects.link(fall)
    shade_flat(fall)
    mod = fall.modifiers.new("Thickness", "SOLIDIFY")
    mod.thickness = 0.14
    mod.offset = 0.0
    bpy.context.view_layer.objects.active = fall
    bpy.ops.object.modifier_apply(modifier="Thickness")
    bm = bmesh.new()
    bm.from_mesh(fall.data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(fall.data)
    bm.free()

    # Foam: a lip line where the water tips over, a ring where it lands.
    bpy.ops.mesh.primitive_cube_add(size=1, location=(lip_x, CLIFF_Y - 0.02, top_z + 0.03))
    lipf = bpy.context.active_object
    lipf.name = "Foam_Lip"
    lipf.scale = (CHANNEL_HALF * 1.55, 0.12, 0.05)
    bpy.ops.object.transform_apply(scale=True)
    lipf.data.materials.append(foam_mat)
    shade_flat(lipf)
    add_outline(lipf, 0.012)

    for i in range(9):
        ang = i / 9.0 * math.tau
        r = POOL_R * rng.uniform(0.45, 0.85)
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=1, radius=rng.uniform(0.13, 0.24),
            location=(POOL[0] + math.cos(ang) * r * 1.1,
                      POOL[1] + math.sin(ang) * r - 0.15,
                      LOWER_WATER_Z + rng.uniform(0.02, 0.12)))
        f = bpy.context.active_object
        f.name = f"Foam_Splash_{i}"
        f.scale = (1.3, 1.1, 0.45)
        bpy.ops.object.transform_apply(scale=True)
        f.data.materials.append(foam_mat)
        shade_flat(f)

    # Spray flecks beside the fall.
    for i in range(7):
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=1, radius=rng.uniform(0.045, 0.085),
            location=(lip_x + rng.uniform(-0.95, 0.95),
                      CLIFF_Y - rng.uniform(0.35, 1.15),
                      lerp(bot_z, top_z, rng.uniform(0.0, 0.42)) + 0.06))
        s = bpy.context.active_object
        s.name = f"Foam_Spray_{i}"
        s.data.materials.append(foam_mat)
        shade_flat(s)

    # Wet stones in and beside the channel.
    for i, (px, py, ps) in enumerate([
        (-6.9, 3.4, 0.42), (-5.8, 3.9, 0.36), (-7.1, 1.6, 0.30),
        (-6.4, -0.3, 0.34), (-8.6, -3.4, 0.40), (-9.9, -6.4, 0.32),
        (-5.55, 5.3, 0.45), (-7.5, 5.4, 0.5),
    ]):
        make_boulder(px, py, s=ps, seed=100 + i)


def make_fish(x, y, z, color, seed=0, yaw=0.0):
    fish_mat = matte("FishMat_%02X%02X%02X" % tuple(int(c * 255) for c in color[:3]), color, GRAIN, mix_fac=0.10)
    parts = []
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.18, location=(x, y, z))
    body = bpy.context.active_object
    body.scale = (1.35, 0.45, 0.55)
    body.rotation_euler = (0, 0, yaw)
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    body.data.materials.append(fish_mat)
    shade_flat(body)
    parts.append(body)
    bpy.ops.mesh.primitive_cone_add(
        vertices=4, radius1=0.12, radius2=0.0, depth=0.16,
        location=(x - math.cos(yaw) * 0.22, y - math.sin(yaw) * 0.22, z))
    tail = bpy.context.active_object
    tail.rotation_euler = (math.radians(90), 0, yaw + math.radians(180))
    bpy.ops.object.transform_apply(rotation=True)
    tail.scale = (0.55, 1.0, 0.35)
    bpy.ops.object.transform_apply(scale=True)
    tail.data.materials.append(fish_mat)
    shade_flat(tail)
    parts.append(tail)
    select_only(parts)
    obj = join_selected(f"Fish_{seed}")
    add_outline(obj, 0.012)
    return obj


# -- Scatter -----------------------------------------------------------------

def scatter_vegetation():
    cypress = [(-11.0, 2.4, 6.2), (-12.2, -1.6, 5.8), (-10.4, -6.2, 6.6),
               (11.2, 1.8, 6.0), (12.4, -2.6, 7.0), (10.6, -6.8, 5.6),
               (-4.6, 8.6, 6.4), (2.6, 9.4, 6.8), (7.4, 8.2, 7.2),
               (-9.2, 9.6, 5.9), (13.0, 4.2, 6.3), (-13.4, 5.2, 6.0),
               (5.8, 12.0, 6.6), (-2.0, 12.6, 6.1)]
    for i, (x, y, h) in enumerate(cypress):
        make_cypress(x, y, h=h, seed=i)

    olives = [(-8.4, 1.2, 2.2), (7.6, 2.6, 2.0), (-8.0, -4.6, 2.3),
              (8.2, -4.0, 2.1), (-5.2, 6.8, 2.0), (4.4, 6.4, 2.4),
              (9.6, 0.2, 2.15), (-10.2, -9.0, 2.2)]
    for i, (x, y, s) in enumerate(olives):
        make_olive(x, y, s=s, seed=i)

    shrubs = [(-4.4, -2.0, 0.5), (4.6, -1.4, 0.45), (-3.0, 4.4, 0.48),
              (3.4, 4.8, 0.52), (-6.2, -7.4, 0.4), (6.0, -7.0, 0.5),
              (-8.8, 3.6, 0.45), (8.8, 4.4, 0.38), (-5.0, 0.6, 0.42),
              (5.4, 1.0, 0.44)]
    for i, (x, y, s) in enumerate(shrubs):
        make_shrub(x, y, s=s, seed=i)

    stones = [(-3.2, -3.4, 0.34), (3.6, -2.4, 0.40), (-2.4, 5.0, 0.30),
              (4.8, 3.2, 0.36), (-7.6, -8.6, 0.55), (7.2, -8.0, 0.48),
              (-11.6, 0.4, 0.62), (11.8, -0.6, 0.58), (-4.0, 9.0, 0.5),
              (6.4, 10.2, 0.54), (1.8, -7.2, 0.32), (-1.4, -8.6, 0.38)]
    for i, (x, y, s) in enumerate(stones):
        make_boulder(x, y, s=s, seed=i)

    fish = [(-6.7, 2.2, COL_FISH_ORANGE, 1.8), (-7.6, -0.4, COL_FISH_GOLD, 1.6),
            (-8.6, -3.2, COL_FISH_BLUE, 1.7), (-6.5, 4.2, COL_FISH_ORANGE, 0.4),
            (-9.6, -5.8, COL_FISH_BLUE, 1.9)]
    for i, (x, y, col, yaw) in enumerate(fish):
        make_fish(x, y, LOWER_WATER_Z + 0.02, col, seed=i, yaw=yaw)


# -- Main --------------------------------------------------------------------

def main():
    clear_scene()
    terrain = build_terrain()
    print("TERRAIN_POLYS", len(terrain.data.polygons))
    build_river()
    scatter_vegetation()

    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0

    out_dir = os.path.dirname(OUT_GLB)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=OUT_GLB,
        export_format="GLB",
        export_apply=True,
        export_texcoords=True,
        export_normals=True,
        export_materials="EXPORT",
    )
    print("WROTE", OUT_GLB)

    # Sanity: the meadow the player walks must stay flat, and the cliff must
    # actually be a cliff.
    spot_checks = [(0, -4), (0, 0), (0, 3), (3, 0), (-2, -6)]
    flat = [round(height_at(x, y), 3) for x, y in spot_checks]
    print("MEADOW_HEIGHTS", flat)
    print("CLIFF_DROP", round(height_at(-6.45, CLIFF_Y + 0.6) - height_at(-6.45, CLIFF_Y - 1.2), 2))
    print("WATER_LEVELS upper=%.2f lower=%.2f" % (UPPER_WATER_Z, LOWER_WATER_Z))


if __name__ == "__main__":
    main()
