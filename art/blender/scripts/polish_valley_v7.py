"""
Little Light — Bethlehem Valley (v7): leafy trees and bushes, real-looking stone.

What changed from v6 and why
----------------------------
v6's shrubs were a squashed 80-face icosphere in flat green, which is the same
recipe as its boulders, so from the tabletop camera they read as *green rocks*.
The rocks themselves shared the flat "paper grain" tint with every other prop,
so nothing about them said "stone". The trees had the same problem: olives were smooth blobs on a straight trunk and cypresses a stack of cones on a bare pole (reads as a pine). v7 fixes all of these and leaves terrain, river and layout exactly as v6 has them.

* Bushes are now built from ~140 individual leaves: each one is a small folded
  diamond leaf solid (its two upper faces carry different greens, so the fold
  reads as a midrib) laid over a dome like shingles, with a dark core showing
  through the gaps. Leaves are splayed at random and pick one of two green
  families, so the silhouette is leafy instead of a smooth blob.
* Rocks keep v6's angular displaced-icosphere shape but get a baked stone
  texture: mottled colour, mineral flecks, fine cracks and faint strata, in
  four variants (cool grey, warm limestone, dark slate, and a mossy grey with
  green patches). UVs are projected per face so each facet shows its own patch
  of stone, which suits the low-poly look. Stone uses linear filtering; the
  paper-grain props keep their crisp nearest-neighbour look.

* Olives get a leaning, root-flared trunk that forks into three limbs, each carrying a clump of narrow leaves (silvery undersides, like real olive leaves) plus a crown clump.
* Cypresses are a slim flame-shaped column of overlapping upward-leaning fronds reaching almost to the ground over a dark core, instead of a pine-like stack of cones.

Object names are unchanged (Shrub_N / Rock_N / Olive_N / Cypress_N and their *_Outline hulls) because
runtime scripts match on them (stream_placement.gd nudges trees and shrubs out of the
water; mesh_collision_baker.gd bakes colliders).

Implemented by importing v6 and swapping make_shrub / make_boulder / make_olive / make_cypress, with their
own random streams so the rest of v6's scatter is not perturbed.

Run:
    blender --background --python art/blender/scripts/polish_valley_v7.py
Env:
    LL_VALLEY_OUT   output .glb   (default assets/bethlehem_valley_v7.glb)
"""
import importlib.util
import math
import os
import random

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector
from mathutils import noise as bnoise

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.environ.get("LL_REPO", os.path.abspath(os.path.join(HERE, "..", "..", "..")))
os.environ.setdefault("LL_VALLEY_OUT", os.path.join(REPO, "assets", "bethlehem_valley_v7.glb"))

_spec = importlib.util.spec_from_file_location("polish_valley_v6", os.path.join(HERE, "polish_valley_v6.py"))
v6 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(v6)

SEED = v6.SEED

# -- Leaf palettes (two families so bushes are not one flat green) -----------
LEAF_FAMILIES = [
    {  # spring green
        "light": (0.35, 0.62, 0.26, 1.0),
        "mid": (0.26, 0.50, 0.23, 1.0),
    },
    {  # olive green
        "light": (0.46, 0.64, 0.27, 1.0),
        "mid": (0.35, 0.53, 0.24, 1.0),
    },
]
LEAF_UNDER = (0.20, 0.38, 0.20, 1.0)
LEAF_CORE = (0.15, 0.30, 0.17, 1.0)

# -- Tree palettes -----------------------------------------------------------
BARK = (0.38, 0.28, 0.20, 1.0)
OLIVE_LIGHT = (0.44, 0.62, 0.31, 1.0)
OLIVE_MID = (0.33, 0.51, 0.26, 1.0)
OLIVE_SILVER = (0.50, 0.62, 0.45, 1.0)   # olive leaves are silvery underneath
OLIVE_CORE = (0.24, 0.38, 0.21, 1.0)
CYP_LIGHT = (0.30, 0.60, 0.28, 1.0)
CYP_MID = (0.20, 0.48, 0.25, 1.0)
CYP_DARK = (0.13, 0.32, 0.18, 1.0)

# -- Stone variants ----------------------------------------------------------
# (name, base colour, dark tone, light tone, moss amount)
ROCK_VARIANTS = [
    ("RockGrey", (0.39, 0.42, 0.48), (0.31, 0.34, 0.40), (0.48, 0.51, 0.57), 0.0),
    ("RockLimestone", (0.54, 0.49, 0.41), (0.49, 0.44, 0.36), (0.59, 0.54, 0.45), 0.0),
    ("RockSlate", (0.30, 0.33, 0.38), (0.22, 0.24, 0.29), (0.39, 0.42, 0.47), 0.0),
    ("RockMossy", (0.32, 0.35, 0.39), (0.25, 0.28, 0.32), (0.40, 0.43, 0.47), 1.0),
]
MOSS_DARK = (0.13, 0.28, 0.10)
MOSS_LIGHT = (0.22, 0.40, 0.14)


# -- Materials ---------------------------------------------------------------

def _value_noise(size, cells, rng):
    """Bilinear value noise, `cells` lattice cells across a size x size image."""
    import numpy as np
    grid = rng.random((cells + 1, cells + 1)).astype(np.float32)
    coords = np.linspace(0, cells, size, endpoint=False)
    i0 = np.floor(coords).astype(int)
    f = coords - i0
    f = f * f * (3.0 - 2.0 * f)
    top = grid[np.ix_(i0, i0)] * (1 - f)[None, :] + grid[np.ix_(i0, i0 + 1)] * f[None, :]
    bot = grid[np.ix_(i0 + 1, i0)] * (1 - f)[None, :] + grid[np.ix_(i0 + 1, i0 + 1)] * f[None, :]
    return top * (1 - f)[:, None] + bot * f[:, None]


def _fbm(size, base_cells, octaves, rng):
    import numpy as np
    total = np.zeros((size, size), dtype=np.float32)
    amp, norm = 1.0, 0.0
    for o in range(octaves):
        total += _value_noise(size, base_cells * (2 ** o), rng) * amp
        norm += amp
        amp *= 0.5
    return total / norm


def stone_material(name, base, dark, light, moss, seed):
    existing = bpy.data.materials.get(name)
    if existing is not None:
        return existing
    import numpy as np
    size = 256
    rng = np.random.default_rng(seed)

    blotch = _fbm(size, 3, 4, rng)                         # big mottling
    tone = np.clip((blotch - 0.25) / 0.5, 0.0, 1.0)[:, :, None]
    dark_c = np.array(dark, dtype=np.float32).reshape(1, 1, 3)
    base_c = np.array(base, dtype=np.float32).reshape(1, 1, 3)
    light_c = np.array(light, dtype=np.float32).reshape(1, 1, 3)
    rgb = np.where(tone < 0.5, dark_c + (base_c - dark_c) * (tone * 2.0),
                   base_c + (light_c - base_c) * ((tone - 0.5) * 2.0))

    # Granular body: mid-frequency lumps plus per-pixel grain give a rough,
    # speckled stone rather than marble-like veining.
    lumps = _fbm(size, 20, 3, rng)
    rgb = rgb * (0.90 + 0.20 * lumps[:, :, None])

    # A few hairline cracks.
    ridge = np.abs(_fbm(size, 6, 3, rng) - 0.5)
    crack = np.clip(1.0 - ridge / 0.010, 0.0, 1.0)[:, :, None]
    rgb = rgb * (1.0 - 0.14 * crack)

    # Mineral flecks: light and dark grains.
    grain = rng.random((size, size)).astype(np.float32)
    rgb = np.where((grain > 0.955)[:, :, None], rgb * 1.20, rgb)
    rgb = np.where((grain < 0.04)[:, :, None], rgb * 0.70, rgb)
    rgb = rgb * (0.94 + 0.12 * rng.random((size, size, 1)).astype(np.float32))

    if moss > 0.0:
        m = _fbm(size, 3, 3, rng)
        cover = np.clip((m - 0.52) / 0.07, 0.0, 1.0)[:, :, None] * moss
        moss_tone = _fbm(size, 8, 2, rng)[:, :, None]
        moss_c = (np.array(MOSS_DARK, dtype=np.float32).reshape(1, 1, 3) * (1 - moss_tone)
                  + np.array(MOSS_LIGHT, dtype=np.float32).reshape(1, 1, 3) * moss_tone)
        rgb = rgb * (1 - cover) + moss_c * cover

    rgb = np.clip(rgb * 1.05, 0.0, 1.0)
    out = np.concatenate([rgb, np.ones((size, size, 1), dtype=np.float32)], axis=2).reshape(-1)
    img = bpy.data.images.new(f"Stone_{name}", width=size, height=size, alpha=True)
    img.pixels = out.tolist()
    img.pack()

    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out_node = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.92
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.05
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Linear"
    tex.extension = "REPEAT"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(bsdf.outputs["BSDF"], out_node.inputs["Surface"])
    mat.diffuse_color = (*base, 1.0)
    mat.use_backface_culling = True
    return mat


def _leaf_materials():
    mats = {"under": v6.matte("LeafUnder", LEAF_UNDER, v6.GRAIN),
            "core": v6.matte("LeafCore", LEAF_CORE, v6.GRAIN)}
    for i, fam in enumerate(LEAF_FAMILIES):
        mats[f"light{i}"] = v6.matte(f"LeafLight{i}", fam["light"], v6.GRAIN)
        mats[f"mid{i}"] = v6.matte(f"LeafMid{i}", fam["mid"], v6.GRAIN)
    return mats


# -- Rocks -------------------------------------------------------------------

def _box_project_uvs(obj, scale=1.0):
    """Per-face planar projection along each face's dominant axis."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    uv = bm.loops.layers.uv.verify()
    for f in bm.faces:
        n = f.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        a, b = [i for i in range(3) if i != ax]
        for loop in f.loops:
            co = loop.vert.co
            loop[uv].uv = (co[a] * scale, co[b] * scale)
    bm.to_mesh(obj.data)
    bm.free()


def make_rock(x, y, s=0.5, seed=0):
    """v6's angular displaced icosphere, with a stone texture and per-face UVs."""
    r = random.Random(SEED * 31 + seed)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=s, location=(0, 0, 0))
    obj = bpy.context.active_object
    obj.name = f"Rock_{seed}"
    ox, oy, oz = r.uniform(0, 50), r.uniform(0, 50), r.uniform(0, 50)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    for v in bm.verts:
        k = 1.0 + bnoise.noise(Vector((v.co.x * 2.4 + ox, v.co.y * 2.4 + oy, v.co.z * 2.4 + oz))) * 0.55
        v.co *= k
    bm.to_mesh(obj.data)
    bm.free()
    obj.scale = (1.0 + r.uniform(0.0, 0.5), 1.0 + r.uniform(0.0, 0.35), 0.55 + r.uniform(0.0, 0.3))
    obj.rotation_euler = Euler((r.uniform(-0.25, 0.25), r.uniform(-0.25, 0.25), r.uniform(0, math.tau)), "XYZ")
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    zs = [v.co.z for v in obj.data.vertices]
    obj.location = (x, y, v6.height_at(x, y) - min(zs) - s * 0.3)

    name, base, dark, light, moss = ROCK_VARIANTS[seed % len(ROCK_VARIANTS)]
    obj.data.materials.append(stone_material(name, base, dark, light, moss, SEED + len(name)))
    v6.shade_flat(obj)
    _box_project_uvs(obj, scale=1.6 / max(s, 0.3))
    v6.add_outline(obj, 0.022)
    return obj


# -- Bushes ------------------------------------------------------------------

def _add_leaf(bm, slots, matrix, length, width, fold):
    """One folded diamond leaf solid (6 verts, 8 faces) transformed by `matrix`.

    `slots` = (top_left, top_right, under) material slot indices.
    """
    pts = [
        (0.0, 0.0, 0.0),                                   # 0 base
        (0.0, length, -fold * 2.0),                        # 1 tip (droops slightly)
        (-width * 0.5, length * 0.50, -fold * 0.6),        # 2 left edge
        (width * 0.5, length * 0.50, -fold * 0.6),         # 3 right edge
        (0.0, length * 0.46, fold),                        # 4 midrib (top ridge)
        (0.0, length * 0.44, -fold * 0.9),                 # 5 underside
    ]
    verts = [bm.verts.new(matrix @ Vector(p)) for p in pts]
    tl, tr, un = slots
    faces = [
        ((0, 3, 4), tr), ((0, 4, 2), tl), ((1, 4, 3), tr), ((1, 2, 4), tl),
        ((0, 2, 5), un), ((0, 5, 3), un), ((1, 5, 2), un), ((1, 3, 5), un),
    ]
    made = []
    for tri, mi in faces:
        try:
            f = bm.faces.new([verts[i] for i in tri])
        except ValueError:
            continue
        f.material_index = mi
        made.append(f)
    bmesh.ops.recalc_face_normals(bm, faces=made)


def make_shrub(x, y, s=0.55, seed=0):
    """A leafy bush: broad folded leaves overlapping like shingles over a dome."""
    r = random.Random(SEED * 17 + seed)
    mats = _leaf_materials()
    # slot 0 core, 1 under, then (light, mid) for each family
    slots = [mats["core"], mats["under"]]
    for i in range(len(LEAF_FAMILIES)):
        slots += [mats[f"light{i}"], mats[f"mid{i}"]]

    R = s * 1.55                      # overall bush radius
    Rd = R * 0.60                     # radius of the dome the leaves sit on
    centre = Vector((0.0, 0.0, Rd * 0.30))
    z0 = v6.height_at(x, y)
    bm = bmesh.new()

    # Dark core just inside the dome: gaps between leaves show shade, not ground.
    core = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=Rd * 0.5)
    for v in core["verts"]:
        v.co = v.co * Vector((1.0, 1.0, 0.85)) + centre + Vector((0.0, 0.0, Rd * 0.1))
    for f in bm.faces:
        f.material_index = 0

    # (elevation deg, leaf count): a ground-hugging skirt first, then rings up the dome.
    rings = [(4, 22), (10, 22), (20, 24), (32, 24), (46, 20), (60, 14), (74, 9), (85, 4), (90, 1)]
    for e_deg, count in rings:
        e = math.radians(e_deg)
        up = e_deg / 90.0
        phase = r.uniform(0, math.tau)
        for i in range(count):
            phi = phase + i * math.tau / count + r.uniform(-0.22, 0.22)
            n = Vector((math.cos(phi) * math.cos(e), math.sin(phi) * math.cos(e), math.sin(e)))
            t_up = Vector((-math.cos(phi) * math.sin(e), -math.sin(phi) * math.sin(e), math.cos(e)))
            d = (n * 0.95 + t_up * 0.2).normalized()
            z_ax = (n - d * n.dot(d)).normalized()
            x_ax = d.cross(z_ax).normalized()
            basis = Matrix(((x_ax.x, d.x, z_ax.x), (x_ax.y, d.y, z_ax.y), (x_ax.z, d.z, z_ax.z)))
            # Random splay (wilder near the crown) so leaves do not line up in tidy rows.
            k = 0.6 + up
            jitter = (Matrix.Rotation(math.radians(r.uniform(-22.0, 22.0) * k), 4, "Z")
                      @ Matrix.Rotation(math.radians(r.uniform(-10.0, 10.0) * k), 4, "X")
                      @ Matrix.Rotation(math.radians(r.uniform(-18.0, 18.0)), 4, "Y"))
            m = Matrix.Translation(centre + n * Rd * 0.92) @ basis.to_4x4() @ jitter
            length = R * 0.30 * r.uniform(0.75, 1.30) * (1.1 - 0.30 * up)
            width = length * r.uniform(0.72, 0.92)
            fam = r.randrange(len(LEAF_FAMILIES))
            leaf_slots = (2 + fam * 2, 3 + fam * 2, 1)
            _add_leaf(bm, leaf_slots, m, length, width, fold=width * 0.09)

    bm.normal_update()
    mesh = bpy.data.meshes.new(f"Shrub_{seed}")
    bm.to_mesh(mesh)
    bm.free()
    for m in slots:
        mesh.materials.append(m)
    for poly in mesh.polygons:
        poly.use_smooth = False
    obj = bpy.data.objects.new(f"Shrub_{seed}", mesh)
    bpy.context.collection.objects.link(obj)
    # World-space geometry, origin at 0, matching how v6 exports its shrubs.
    for v in mesh.vertices:
        v.co += Vector((x, y, z0 - R * 0.08))
    v6.add_outline(obj, 0.018)
    return obj


# -- Trees -------------------------------------------------------------------

def _tube(bm, pts, radii, mat_index, sides=6):
    """Closed tapered tube along `pts` (list of Vector) with per-point radii."""
    mean_t = (pts[-1] - pts[0]).normalized()
    ref = Vector((1.0, 0.0, 0.0)) if abs(mean_t.z) > 0.7 else Vector((0.0, 0.0, 1.0))
    rings = []
    for i, p in enumerate(pts):
        t = ((pts[i + 1] - p) if i < len(pts) - 1 else (p - pts[i - 1])).normalized()
        u = t.cross(ref).normalized()
        v = t.cross(u).normalized()
        rings.append([bm.verts.new(p + (u * math.cos(a) + v * math.sin(a)) * radii[i])
                      for a in (k * math.tau / sides for k in range(sides))])
    made = []
    for i in range(len(rings) - 1):
        for k in range(sides):
            f = bm.faces.new((rings[i][k], rings[i][(k + 1) % sides],
                              rings[i + 1][(k + 1) % sides], rings[i + 1][k]))
            f.material_index = mat_index
            made.append(f)
    for ring in (rings[0], rings[-1]):
        f = bm.faces.new(ring)
        f.material_index = mat_index
        made.append(f)
    bmesh.ops.recalc_face_normals(bm, faces=made)


def _finish_tree(bm, name, slots, x, y, z, outline):
    bm.normal_update()
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    for m in slots:
        mesh.materials.append(m)
    for poly in mesh.polygons:
        poly.use_smooth = False
    obj = bpy.data.objects.new(name, mesh)
    obj.location = (x, y, z)
    bpy.context.collection.objects.link(obj)
    v6.add_outline(obj, outline)
    return obj


def _leaf_frame(d, z_hint):
    """Basis (columns x, y=d, z) with local +Z as close to z_hint as the axis allows."""
    z_ax = z_hint - d * z_hint.dot(d)
    if z_ax.length < 1e-4:
        z_ax = Vector((0.0, 0.0, 1.0)) - d * d.z
    z_ax.normalize()
    x_ax = d.cross(z_ax).normalized()
    return Matrix(((x_ax.x, d.x, z_ax.x), (x_ax.y, d.y, z_ax.y), (x_ax.z, d.z, z_ax.z))).to_4x4()


def _jitter(r, yaw, pitch, roll):
    return (Matrix.Rotation(math.radians(r.uniform(-yaw, yaw)), 4, "Z")
            @ Matrix.Rotation(math.radians(r.uniform(-pitch, pitch)), 4, "X")
            @ Matrix.Rotation(math.radians(r.uniform(-roll, roll)), 4, "Y"))


def make_olive(x, y, s=2.2, seed=0):
    """Gnarled forked trunk carrying clumps of narrow, silver-backed leaves."""
    r = random.Random(SEED * 23 + seed)
    slots = [v6.matte("TreeBark", BARK, v6.GRAIN), v6.matte("OliveCore", OLIVE_CORE, v6.GRAIN),
             v6.matte("OliveLight", OLIVE_LIGHT, v6.GRAIN), v6.matte("OliveMid", OLIVE_MID, v6.GRAIN),
             v6.matte("OliveSilver", OLIVE_SILVER, v6.GRAIN)]
    z0 = v6.height_at(x, y) - 0.05
    bm = bmesh.new()

    # Trunk: leaning, slightly wobbling, flared at the root.
    lean_dir = r.uniform(0, math.tau)
    lean = r.uniform(0.04, 0.12) * s
    trunk = []
    for i in range(6):
        t = i / 5
        trunk.append(Vector((math.cos(lean_dir) * lean * t * t + r.uniform(-0.02, 0.02) * s * t,
                             math.sin(lean_dir) * lean * t * t + r.uniform(-0.02, 0.02) * s * t,
                             0.72 * s * t)))
    radii = [0.20 * s, 0.14 * s, 0.12 * s, 0.11 * s, 0.10 * s, 0.09 * s]
    _tube(bm, trunk, radii, 0, sides=6)

    # Three limbs fork off the top and carry the leaf clumps.
    top = trunk[-1]
    clumps = []
    a0 = r.uniform(0, math.tau)
    for k in range(3):
        phi = a0 + k * math.tau / 3 + r.uniform(-0.3, 0.3)
        elev = math.radians(r.uniform(40, 58))
        length = s * r.uniform(0.45, 0.6)
        d = Vector((math.cos(phi) * math.cos(elev), math.sin(phi) * math.cos(elev), math.sin(elev)))
        pts = [top - Vector((0, 0, 0.04 * s)), top + d * length * 0.4 + Vector((0, 0, 0.03 * s)),
               top + d * length * 0.75 + Vector((0, 0, 0.07 * s)), top + d * length + Vector((0, 0, 0.1 * s))]
        _tube(bm, pts, [0.075 * s, 0.06 * s, 0.045 * s, 0.03 * s], 0, sides=5)
        clumps.append((pts[-1] + Vector((0, 0, 0.12 * s)), s * r.uniform(0.36, 0.44)))
    clumps.append((top + Vector((0, 0, 0.5 * s)), s * 0.40))  # crown

    golden = math.pi * (3.0 - math.sqrt(5.0))
    for centre, rc in clumps:
        core = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=rc * 0.5)
        for v in core["verts"]:
            v.co = v.co * Vector((1.0, 1.0, 0.8)) + centre
            for f in v.link_faces:
                f.material_index = 1
        count = 90
        for i in range(count):
            zc = 1.0 - 2.0 * (i + 0.5) / count            # fibonacci sphere
            ring = math.sqrt(max(0.0, 1.0 - zc * zc))
            phi = i * golden
            n = Vector((math.cos(phi) * ring, math.sin(phi) * ring, zc))
            if n.z < -0.55:
                continue                                    # flatten the underside of the crown
            d = (n + Vector((0, 0, -0.3))).normalized()
            m = (Matrix.Translation(centre + Vector((n.x, n.y, n.z * 0.8)) * rc * 0.8)
                 @ _leaf_frame(d, (n + Vector((0, 0, 0.6))).normalized()) @ _jitter(r, 20, 12, 20))
            length = s * 0.22 * r.uniform(0.75, 1.3)
            width = length * r.uniform(0.38, 0.50)
            top_a, top_b = (2, 3) if r.random() < 0.5 else (3, 2)
            _add_leaf(bm, (top_a, top_b, 4), m, length, width, fold=width * 0.12)
    return _finish_tree(bm, f"Olive_{seed}", slots, x, y, z0, 0.03)


def make_cypress(x, y, h=6.5, seed=0):
    """Slim flame-shaped column of overlapping fronds, foliage nearly to the ground."""
    r = random.Random(SEED * 29 + seed)
    slots = [v6.matte("TreeBark", BARK, v6.GRAIN), v6.matte("CypDark", CYP_DARK, v6.GRAIN),
             v6.matte("CypLight", CYP_LIGHT, v6.GRAIN), v6.matte("CypMid", CYP_MID, v6.GRAIN)]
    z0 = v6.height_at(x, y) - 0.05
    bm = bmesh.new()
    k = h / 6.5
    _tube(bm, [Vector((0, 0, 0)), Vector((0, 0, 0.6 * k)), Vector((0, 0, 1.2 * k))],
          [0.15 * k, 0.11 * k, 0.09 * k], 0, sides=5)

    z_start, H = 0.5 * k, h - 0.5 * k
    rmax = h * 0.075

    def radius(t):
        if t < 0.3:
            u = t / 0.3
            return rmax * (0.5 + 0.5 * u * u * (3 - 2 * u))
        return rmax * max(0.0, 1.0 - (t - 0.3) / 0.7) ** 0.85

    # Dark core so gaps between fronds read as shade.
    steps = 12
    pts = [Vector((0, 0, z_start + H * i / steps)) for i in range(steps + 1)]
    _tube(bm, pts, [max(0.02, radius(i / steps) * 0.7) for i in range(steps + 1)], 1, sides=6)

    z = z_start + 0.15 * k
    while z < z_start + H * 0.985:
        t = (z - z_start) / H
        rad = radius(t)
        count = max(3, int(round(math.tau * rad / (0.30 * k))))
        phase = r.uniform(0, math.tau)
        alpha = math.radians(50.0 - 28.0 * t)                # lean from vertical
        for i in range(count):
            phi = phase + i * math.tau / count + r.uniform(-0.2, 0.2)
            d = Vector((math.cos(phi) * math.sin(alpha), math.sin(phi) * math.sin(alpha), math.cos(alpha)))
            out = Vector((math.cos(phi), math.sin(phi), 0.0))
            base = Vector((math.cos(phi) * rad * 0.55, math.sin(phi) * rad * 0.55, z + r.uniform(-0.05, 0.05)))
            m = Matrix.Translation(base) @ _leaf_frame(d, out) @ _jitter(r, 18, 10, 20)
            length = max(0.42 * k, 1.25 * rad * 0.55 / max(0.25, math.sin(alpha))) * r.uniform(0.85, 1.2)
            width = length * r.uniform(0.40, 0.55)
            light = r.random() < 0.25 + 0.5 * t
            _add_leaf(bm, (2, 3, 1) if light else (3, 3, 1), m, length, width, fold=width * 0.12)
        z += 0.30 * k
    return _finish_tree(bm, f"Cypress_{seed}", slots, x, y, z0, 0.035)


# -- Swap into v6 and run ----------------------------------------------------

v6.make_boulder = make_rock
v6.make_shrub = make_shrub
v6.make_olive = make_olive
v6.make_cypress = make_cypress

if __name__ == "__main__":
    v6.OUT_GLB = os.environ["LL_VALLEY_OUT"]
    v6.main()
