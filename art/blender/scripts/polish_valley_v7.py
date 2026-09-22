"""
Little Light — Bethlehem Valley (v7): leafy trees and bushes, real-looking stone.

What changed from v6 and why
----------------------------
v6's shrubs were a squashed 80-face icosphere in flat green, which is the same
recipe as its boulders, so from the tabletop camera they read as *green rocks*.
The rocks themselves shared the flat "paper grain" tint with every other prop,
so nothing about them said "stone". The trees had the same problem: olives were smooth blobs on a straight trunk and cypresses a stack of cones on a bare pole (reads as a pine). v7 fixes all of these and leaves terrain, river and layout exactly as v6 has them.

* Bushes are a soft mound: a main dome and four or five smaller lobes, each covered in overlapping
  rounded leaves that lie on the dome like paper shingles (tip downhill, lifted a little), over a dark core
  that shows through the gaps. The first v7 leaves were sharp diamonds pointing straight out, which made
  bushes look like agave and olive crowns like spiky rings; rounded, lying leaves read as foliage.
* Rocks keep v6's angular displaced-icosphere shape but get a baked stone
  texture: mottled colour, mineral flecks, fine cracks and faint strata, in
  four variants (cool grey, warm limestone, dark slate, and a mossy grey with
  green patches). UVs are projected per face so each facet shows its own patch
  of stone, which suits the low-poly look. Stone uses linear filtering; the
  paper-grain props keep their crisp nearest-neighbour look.

* Olives get a leaning, root-flared trunk that forks into three limbs, each carrying a rounded clump of overlapping leaves, plus a crown clump.
* Cypresses are a slim flame-shaped column of overlapping rounded scales reaching almost to the ground over a dark core, instead of a pine-like stack of cones.
* All foliage shares ONE material and keeps its colour in the vertices (`FoliageVertexColour`), so a tree or
  bush is two draw calls (body + outline) instead of five to seven. Godot's importer leaves "vertex colour as
  albedo" off, so `scripts/foliage_colour.gd` switches it on at start. The palette numbers below are what the
  eye should see, and `_shade()` converts them to the linear values a vertex holds.
* Three flattened boulders of the valley's stone stick out of the shelf's front cliff as ledges, half buried in it, with leafy tufts on top (`make_ledges`).
* Trees stand on grass. v6's list put ten of them on the steep back wall (which the ground map paints as bare rock) or on the lip of the shelf; `TREE_MOVES` gives those a spot on grass, and the generator reports any tree left on ground steeper than 34 degrees.

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


# -- Foliage: rounded leaves, painted with vertex colours ---------------------
# v7's first leaves were sharp diamonds pointing straight out, so bushes read as agave rosettes
# and the olive crowns as spiky rings. Here every leaf is a rounded oval that lies on a dome
# (or on the flame of a cypress) like a paper shingle, tip downhill and lifted a little, so a
# bush is a soft mound of overlapping scales. The colour is stored in the vertices and all
# foliage shares one material, so a whole tree or bush is two draw calls (body + outline)
# instead of five to seven.

FOLIAGE_MATERIAL = "FoliageVertexColour"


def _foliage_material():
    existing = bpy.data.materials.get(FOLIAGE_MATERIAL)
    if existing is not None:
        return existing
    mat = bpy.data.materials.new(FOLIAGE_MATERIAL)
    mat.use_nodes = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.95
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.05
    col = nt.nodes.new("ShaderNodeVertexColor")
    col.layer_name = "Col"
    nt.links.new(col.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mat.use_backface_culling = True     # single-sided, like v6's matte() (see the outline hulls)
    return mat


class _Foliage:
    """A bmesh under construction, with a colour layer the faces are painted into."""

    def __init__(self):
        self.bm = bmesh.new()
        self.col = self.bm.loops.layers.float_color.new("Col")

    def paint(self, faces, colour):
        for f in faces:
            for loop in f.loops:
                loop[self.col] = colour


def _shade(colour, k):
    """The palette's colour, darkened by `k`, as the linear value Godot expects in a vertex.

    The palette numbers are what the eye should see (v6's materials pass them through an
    sRGB image), so they are converted here; a vertex colour is not.
    """
    return tuple(min(c * k, 1.0) ** 2.2 for c in colour[:3]) + (1.0,)


# Outline of one leaf: (fraction of its length, fraction of its half-width). Rounded like an
# ovate leaf, widest just past the middle, with a short tip.
LEAF_RIM = [(0.0, 0.0), (0.20, 0.62), (0.48, 1.0), (0.78, 0.74), (1.0, 0.0),
            (0.78, -0.74), (0.48, -1.0), (0.20, -0.62)]


def _add_leaf(fb, matrix, length, width, fold, top_left, top_right, under):
    """One rounded leaf solid (10 verts, 16 faces) transformed by `matrix`.

    The two upper halves get different greens, so the fold reads as a midrib.
    """
    bm = fb.bm
    rim = []
    for i, (t, w) in enumerate(LEAF_RIM):
        z = -fold * 0.35 if 0 < i < 4 or i > 4 else (-fold * 1.6 if i == 4 else 0.0)
        rim.append(bm.verts.new(matrix @ Vector((w * width * 0.5, t * length, z))))
    ridge = bm.verts.new(matrix @ Vector((0.0, length * 0.5, fold)))
    belly = bm.verts.new(matrix @ Vector((0.0, length * 0.5, -fold * 0.9)))
    made = []
    for i in range(len(rim)):
        j = (i + 1) % len(rim)
        for apex, colour in ((ridge, top_left if i < 4 else top_right), (belly, under)):
            try:
                f = bm.faces.new((rim[i], rim[j], apex))
            except ValueError:
                continue
            made.append((f, colour))
    bmesh.ops.recalc_face_normals(bm, faces=[f for f, _ in made])
    for f, colour in made:
        fb.paint([f], colour)


def _leaf_frame(d, z_hint):
    """Basis (columns x, y=d, z) with local +Z as close to z_hint as the axis allows."""
    z_ax = z_hint - d * z_hint.dot(d)
    if z_ax.length < 1e-4:
        z_ax = Vector((0.0, 0.0, 1.0)) - d * d.z
    z_ax.normalize()
    x_ax = d.cross(z_ax).normalized()
    return Matrix(((x_ax.x, d.x, z_ax.x), (x_ax.y, d.y, z_ax.y), (x_ax.z, d.z, z_ax.z))).to_4x4()


def _leaf_on_surface(fb, r, pos, n, length, width, families, under, shade, lift):
    """A leaf lying on a surface: base at `pos`, tip downhill, lifted `lift` radians off it."""
    down = Vector((0.0, 0.0, -1.0))
    d = down - n * down.dot(n)
    if d.length < 0.25:                     # on the crown, where "downhill" is undefined
        a = r.uniform(0.0, math.tau)
        d = Vector((math.cos(a), math.sin(a), 0.0))
        d = d - n * d.dot(n)
    d = Matrix.Rotation(r.uniform(-0.55, 0.55), 3, n) @ d.normalized()
    d = (d * math.cos(lift) + n * math.sin(lift)).normalized()
    light, mid = r.choice(families)
    k = shade * r.uniform(0.93, 1.07)
    m = Matrix.Translation(pos) @ _leaf_frame(d, n)
    _add_leaf(fb, m, length, width, fold=width * 0.10,
              top_left=_shade(light, k), top_right=_shade(mid, k), under=_shade(under, k))


def _leaf_dome(fb, r, centre, radii, count, families, under, core, leaf_scale=0.95, width_k=0.72,
               below=-0.2, lift=0.30):
    """A mound of overlapping leaves: a dark core, then `count` leaves over an ellipsoid."""
    rx, ry, rz = radii
    inner = bmesh.ops.create_icosphere(fb.bm, subdivisions=1, radius=1.0)
    for v in inner["verts"]:
        v.co = Vector((v.co.x * rx * 0.78, v.co.y * ry * 0.78, v.co.z * rz * 0.78)) + centre
    fb.paint({f for v in inner["verts"] for f in v.link_faces}, _shade(core, 1.0))

    golden = math.pi * (3.0 - math.sqrt(5.0))
    rc = (rx + ry) * 0.5
    for i in range(count):
        zc = 1.0 - (1.0 - below) * (i + 0.5) / count            # fibonacci cap
        ring = math.sqrt(max(0.0, 1.0 - zc * zc))
        phi = i * golden
        u = Vector((math.cos(phi) * ring, math.sin(phi) * ring, zc))
        pos = centre + Vector((u.x * rx, u.y * ry, u.z * rz))
        n = Vector((u.x / rx, u.y / ry, u.z / rz)).normalized()
        length = rc * leaf_scale * r.uniform(0.85, 1.2)
        shade = 0.80 + 0.20 * (0.5 + 0.5 * zc)                   # lower leaves sit in shade
        _leaf_on_surface(fb, r, pos, n, length, length * width_k, families, under, shade, lift)


def _tube(fb, pts, radii, colour, sides=6):
    """Closed tapered tube along `pts` (list of Vector) with per-point radii."""
    bm = fb.bm
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
            made.append(bm.faces.new((rings[i][k], rings[i][(k + 1) % sides],
                                      rings[i + 1][(k + 1) % sides], rings[i + 1][k])))
    for ring in (rings[0], rings[-1]):
        made.append(bm.faces.new(ring))
    bmesh.ops.recalc_face_normals(bm, faces=made)
    fb.paint(made, _shade(colour, 1.0))


def _finish(fb, name, x, y, z, outline):
    bm = fb.bm
    bm.normal_update()
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(_foliage_material())
    for poly in mesh.polygons:
        poly.use_smooth = False
    mesh.color_attributes.active_color = mesh.color_attributes["Col"]
    mesh.color_attributes.render_color_index = [a.name for a in mesh.color_attributes].index("Col")
    obj = bpy.data.objects.new(name, mesh)
    obj.location = (x, y, z)
    bpy.context.collection.objects.link(obj)
    hull = v6.add_outline(obj, outline)
    # The black hull is one shared material; vertex colours on it would tint it in Godot.
    for attr in list(hull.data.color_attributes):
        hull.data.color_attributes.remove(attr)
    return obj


# -- Bushes ------------------------------------------------------------------

def make_shrub(x, y, s=0.55, seed=0):
    """A soft mound: a main dome of overlapping rounded leaves and a few smaller lobes round it."""
    r = random.Random(SEED * 17 + seed)
    families = [(f["light"], f["mid"]) for f in LEAF_FAMILIES]
    R = s * 1.55                      # overall bush radius
    fb = _Foliage()

    main = R * 0.52
    _leaf_dome(fb, r, Vector((0.0, 0.0, main * 0.55)), (main, main, main * 0.85), 26,
               families, LEAF_UNDER, LEAF_CORE)
    lobes = r.randint(4, 5)
    a0 = r.uniform(0.0, math.tau)
    for k in range(lobes):
        a = a0 + k * math.tau / lobes + r.uniform(-0.3, 0.3)
        rr = R * r.uniform(0.30, 0.38)
        dist = R * r.uniform(0.46, 0.56)
        _leaf_dome(fb, r, Vector((math.cos(a) * dist, math.sin(a) * dist, rr * 0.45)),
                   (rr, rr, rr * 0.85), 13, families, LEAF_UNDER, LEAF_CORE)

    obj = _finish(fb, f"Shrub_{seed}", 0.0, 0.0, 0.0, 0.012)
    # World-space geometry, origin at 0, matching how v6 exports its shrubs.
    z0 = v6.height_at(x, y)
    shift = Vector((x, y, z0 - R * 0.08))
    for o in (obj, bpy.data.objects[obj.name + "_Outline"]):
        for v in o.data.vertices:
            v.co += shift
    return obj


# -- Trees -------------------------------------------------------------------

def make_olive(x, y, s=2.2, seed=0):
    """Gnarled forked trunk carrying rounded clumps of overlapping, silver-backed leaves."""
    r = random.Random(SEED * 23 + seed)
    families = [(OLIVE_LIGHT, OLIVE_MID)]
    z0 = v6.height_at(x, y) - 0.05
    fb = _Foliage()

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
    _tube(fb, trunk, radii, BARK, sides=6)

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
        _tube(fb, pts, [0.075 * s, 0.06 * s, 0.045 * s, 0.03 * s], BARK, sides=5)
        clumps.append((pts[-1] + Vector((0, 0, 0.12 * s)), s * r.uniform(0.38, 0.46)))
    clumps.append((top + Vector((0, 0, 0.5 * s)), s * 0.42))  # crown

    for centre, rc in clumps:
        _leaf_dome(fb, r, centre, (rc, rc, rc * 0.82), 26, families, OLIVE_SILVER, OLIVE_CORE,
                   leaf_scale=0.85, width_k=0.62, below=-0.35)
    return _finish(fb, f"Olive_{seed}", x, y, z0, 0.024)


def make_cypress(x, y, h=6.5, seed=0):
    """Slim flame-shaped column of overlapping rounded scales, foliage nearly to the ground."""
    r = random.Random(SEED * 29 + seed)
    families = [(CYP_LIGHT, CYP_MID)]
    z0 = v6.height_at(x, y) - 0.05
    fb = _Foliage()
    k = h / 6.5
    _tube(fb, [Vector((0, 0, 0)), Vector((0, 0, 0.6 * k)), Vector((0, 0, 1.2 * k))],
          [0.15 * k, 0.11 * k, 0.09 * k], BARK, sides=5)

    z_start, H = 0.5 * k, h - 0.5 * k
    rmax = h * 0.075

    def radius(t):
        if t < 0.3:
            u = t / 0.3
            return rmax * (0.5 + 0.5 * u * u * (3 - 2 * u))
        return rmax * max(0.0, 1.0 - (t - 0.3) / 0.7) ** 0.85

    # Dark core so gaps between scales read as shade.
    steps = 12
    pts = [Vector((0, 0, z_start + H * i / steps)) for i in range(steps + 1)]
    _tube(fb, pts, [max(0.02, radius(i / steps) * 0.75) for i in range(steps + 1)], CYP_DARK, sides=6)

    gap = 0.40 * k
    z = z_start + 0.1 * k
    while z < z_start + H * 0.985:
        t = (z - z_start) / H
        rad = radius(t)
        slope = (radius(min(1.0, t + 0.02)) - radius(max(0.0, t - 0.02))) / (0.04 * H)
        count = max(4, int(round(math.tau * rad / (0.34 * k))))
        phase = r.uniform(0, math.tau)
        for i in range(count):
            phi = phase + i * math.tau / count + r.uniform(-0.15, 0.15)
            out = Vector((math.cos(phi), math.sin(phi), 0.0))
            n = Vector((out.x, out.y, -slope)).normalized()
            pos = Vector((out.x * rad * 0.92, out.y * rad * 0.92, z + r.uniform(-0.04, 0.04)))
            cell = math.tau * rad / count
            length = max(0.5 * k, gap * 2.3) * r.uniform(0.85, 1.15)
            width = max(cell * 1.5, 0.26 * k)
            shade = 0.82 + 0.18 * t + r.uniform(-0.03, 0.03)
            _leaf_on_surface(fb, r, pos, n, length, width, families, CYP_DARK, shade, lift=0.38)
        z += gap
    return _finish(fb, f"Cypress_{seed}", x, y, z0, 0.026)


# -- Terrain: painted ground map ---------------------------------------------
# v6 gave every terrain triangle one of five materials, so every boundary
# (path, riverbank, cliff foot) was a staircase of 0.6 m triangles. v7 paints
# the ground into one 1024 px map, mapped top-down over the whole terrain, so
# borders are smooth, wavy curves and the cliffs/path can carry real detail.

GROUND_TEX_SIZE = 1024


def _ss(a, b, x):
    import numpy as np
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def _resample(grid, size):
    """Bilinear-resize a square grid to size x size."""
    import numpy as np
    n = grid.shape[0]
    coords = np.linspace(0, n - 1, size)
    i0 = np.minimum(np.floor(coords).astype(int), n - 2)
    f = (coords - i0).astype(np.float32)
    rows = grid[i0] * (1 - f)[:, None] + grid[i0 + 1] * f[:, None]
    return rows[:, i0] * (1 - f)[None, :] + rows[:, i0 + 1] * f[None, :]


def _poly_dist_np(X, Y, pts):
    import numpy as np
    best = np.full(X.shape, 1e9, dtype=np.float32)
    for (ax, ay), (bx, by) in zip(pts[:-1], pts[1:]):
        abx, aby = bx - ax, by - ay
        denom = abx * abx + aby * aby
        t = np.clip(((X - ax) * abx + (Y - ay) * aby) / denom, 0.0, 1.0)
        best = np.minimum(best, np.hypot(X - (ax + t * abx), Y - (ay + t * aby)))
    return best


def paint_ground(size=GROUND_TEX_SIZE):
    """Returns a (size, size, 3) float array of sRGB ground colours."""
    import numpy as np
    E = v6.EXTENT
    rng = np.random.default_rng(SEED + 7)

    hn = 384
    lin = np.linspace(-E, E, hn)
    H = np.empty((hn, hn), dtype=np.float32)
    for j, y in enumerate(lin):
        for i, x in enumerate(lin):
            H[j, i] = v6.height_at(x, y)
    step = 2.0 * E / (hn - 1)
    k = 6                                   # ~0.94 m either side, like v6's slope sample
    Hp = np.pad(H, k, mode="edge")
    gx = (Hp[k:-k, 2 * k:] - Hp[k:-k, :-2 * k]) / (2 * k * step)
    gy = (Hp[2 * k:, k:-k] - Hp[:-2 * k, k:-k]) / (2 * k * step)
    slope = _resample(np.degrees(np.arctan(np.hypot(gx, gy))).astype(np.float32), size)
    Hs = _resample(H, size)

    tex = np.linspace(-E, E, size, dtype=np.float32)
    X, Y = np.meshgrid(tex, tex)
    n_big = _fbm(size, 4, 4, rng)
    n_big2 = _fbm(size, 6, 3, rng)
    n_edge = _fbm(size, 24, 3, rng)
    n_fine = rng.random((size, size)).astype(np.float32)

    slope_n = slope + (n_edge - 0.5) * 14.0
    rock_w = _ss(36.0, 42.0, slope_n)
    d_up = np.where(Y > v6.CLIFF_Y, _poly_dist_np(X, Y, v6.UPPER_RIVER), 1e9)
    d_low = _poly_dist_np(X, Y, v6.LOWER_RIVER)
    d_pool = np.hypot(X - v6.POOL[0], Y - v6.POOL[1])
    ch = np.minimum(np.minimum(d_up / (v6.CHANNEL_HALF * 1.5), d_low / (v6.CHANNEL_HALF * 1.7)),
                    d_pool / (v6.POOL_R * 1.15))
    bed_w = 1.0 - _ss(0.92, 1.0, ch + (n_edge - 0.5) * 0.10)
    d_path = _poly_dist_np(X, Y, v6.PATH)
    path_w = (1.0 - _ss(v6.PATH_HALF - 0.04, v6.PATH_HALF + 0.04, d_path + (n_edge - 0.5) * 0.16)) \
        * (1.0 - _ss(15.0, 20.0, slope))
    scrub_w = np.maximum(_ss(-0.6, 0.6, Hs - (3.4 + (n_big - 0.5) * 2.6)), _ss(21.0, 26.0, slope_n))

    def c(col):
        return np.array(col[:3], dtype=np.float32).reshape(1, 1, 3)

    grain = (0.975 + 0.05 * n_fine)[:, :, None]
    grass = c(v6.COL_HILL) * (0.95 + 0.10 * n_big)[:, :, None] * grain
    scrub = c(v6.COL_SCRUB) * (0.95 + 0.10 * n_big2)[:, :, None] * grain

    strata = 0.5 + 0.5 * np.sin(Hs * 5.0 + (n_edge - 0.5) * 6.0)
    ridge = np.abs(_fbm(size, 7, 3, rng) - 0.5)
    crack = np.clip(1.0 - ridge / 0.007, 0.0, 1.0)
    rock = c(v6.COL_CLIFF) * (0.94 + 0.10 * n_big2)[:, :, None] * (0.93 + 0.09 * strata)[:, :, None]
    rock = rock * (1.0 - 0.08 * crack)[:, :, None] * grain
    # Grassy rim where the wall is not quite vertical.
    rim = (rock_w * (1.0 - _ss(46.0, 62.0, slope)) * _ss(0.45, 0.6, n_big2) * 0.55)[:, :, None]
    rock = rock * (1.0 - rim) + scrub * rim

    path = c(v6.COL_PATH) * (0.96 + 0.08 * n_big)[:, :, None]
    path = path * (1.0 - 0.08 * _ss(v6.PATH_HALF - 0.22, v6.PATH_HALF, d_path))[:, :, None]
    path = np.where((n_fine > 0.9955)[:, :, None], path * 1.12, path)
    path = np.where((n_fine < 0.003)[:, :, None], path * 0.82, path) * grain

    wet = (1.0 - _ss(0.55, 0.95, ch))[:, :, None]
    bed = c(v6.COL_BED) * (0.95 + 0.10 * n_big)[:, :, None] * (1.0 - 0.14 * wet) * grain

    def mix(a, b, w):
        return a * (1.0 - w[:, :, None]) + b * w[:, :, None]

    col = grass
    col = mix(col, scrub, scrub_w)
    col = mix(col, path, path_w)
    col = mix(col, bed, bed_w)
    col = mix(col, rock, rock_w)
    return np.clip(col, 0.0, 1.0)


def build_terrain():
    """v6's heightfield mesh, one material, top-down UVs, painted ground map."""
    import numpy as np
    E = v6.EXTENT
    n = int((E * 2.0) / v6.CELL)
    verts, faces = [], []
    for j in range(n + 1):
        for i in range(n + 1):
            x = -E + i * v6.CELL
            y = -E + j * v6.CELL
            verts.append((x, y, v6.height_at(x, y)))
    for j in range(n):
        for i in range(n):
            a = j * (n + 1) + i
            b, cc = a + 1, a + (n + 1)
            d = cc + 1
            if (i + j) % 2 == 0:
                faces += [(a, b, d), (a, d, cc)]
            else:
                faces += [(a, b, cc), (b, d, cc)]
    mesh = bpy.data.meshes.new("Valley_TerrainMesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    for poly in mesh.polygons:
        poly.use_smooth = False

    uv_layer = mesh.uv_layers.new(name="UVMap")
    co = np.empty(len(mesh.vertices) * 3, dtype=np.float32)
    mesh.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    loop_vi = np.empty(len(mesh.loops), dtype=np.int32)
    mesh.loops.foreach_get("vertex_index", loop_vi)
    uv = np.stack([(co[loop_vi, 0] + E) / (2 * E), (co[loop_vi, 1] + E) / (2 * E)], axis=1).astype(np.float32)
    uv_layer.data.foreach_set("uv", uv.ravel())

    size = GROUND_TEX_SIZE
    rgb = paint_ground(size)
    pix = np.concatenate([rgb, np.ones((size, size, 1), dtype=np.float32)], axis=2).reshape(-1)
    img = bpy.data.images.new("Ground_Painted", width=size, height=size, alpha=True)
    img.pixels.foreach_set(pix)
    img.pack()

    mat = bpy.data.materials.new("V_Ground")
    mat.use_nodes = True
    nt = mat.node_tree
    for nd in list(nt.nodes):
        nt.nodes.remove(nd)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.95
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.05
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Linear"
    tex.extension = "EXTEND"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mat.use_backface_culling = True
    mesh.materials.append(mat)

    obj = bpy.data.objects.new("Valley_Terrain", mesh)
    bpy.context.collection.objects.link(obj)
    return obj


# -- Where the trees stand ---------------------------------------------------
# The ground map paints anything steeper than ~36 degrees as bare rock, and the wall along the
# back of the valley is that steep. v6's scatter put ten trees on it (or on the lip of the
# shelf, half over the drop), so they seemed to grow out of the cliff. Each is moved here to
# the nearest grass: the foot of the wall, the top of the shelf, or the ridge behind the wall.
# The tree shapes are seeded by their index, so moving one changes nothing else about it.
# Everything else keeps the position the v6 list gives it.

TREE_MOVES = {
    ("Cypress", 4): (10.9, -2.6),
    ("Cypress", 6): (-5.3, 8.6),
    ("Cypress", 7): (3.4, 5.0),
    ("Cypress", 8): (8.6, 4.8),
    ("Cypress", 10): (11.0, 4.2),
    ("Cypress", 11): (-12.9, 7.7),
    ("Cypress", 12): (5.8, 14.0),
    ("Cypress", 13): (-1.0, 14.6),
    ("Olive", 4): (-11.0, 11.5),
    ("Olive", 5): (5.8, 4.7),
}
MAX_TREE_SLOPE = 34.0       # a tree on ground steeper than this is standing on painted rock


def _tree_spot(kind, seed, x, y):
    x, y = TREE_MOVES.get((kind, seed), (x, y))
    slope = v6.surface_slope_deg(x, y)
    if slope > MAX_TREE_SLOPE:
        print("TREE_ON_STEEP_GROUND %s_%d at (%.1f, %.1f): %.0f degrees" % (kind, seed, x, y, slope))
    return x, y


def place_olive(x, y, s=2.2, seed=0):
    x, y = _tree_spot("Olive", seed, x, y)
    return make_olive(x, y, s=s, seed=seed)


def place_cypress(x, y, h=6.5, seed=0):
    x, y = _tree_spot("Cypress", seed, x, y)
    return make_cypress(x, y, h=h, seed=seed)


# -- Cliff ledges ------------------------------------------------------------
# The shelf's cliff was one smooth slab, so a child saw a flat wall. Here flattened boulders of
# the valley's own stone (same textured stone and inked outline as the rocks on the meadow)
# stick out of it in two rows, half buried in the wall, with leafy tufts growing on top. First
# try was flat paper slabs with a grassy top; they read as floating tiles, while a rounded
# outcrop looks like it grew there. They are decoration (the play boundary keeps the walker away
# from the wall), so they are not part of the height field and nothing else has to know about
# them. The waterfall gets a clear gap.

FALL_GAP = (-8.2, -4.8)        # no outcrops where the waterfall pours (x range on the front face)


def _wall_point(face, along, z):
    """Where the cliff surface is `z` high. Returns (point, outward normal, tangent)."""
    if face == "front":                      # the face turned toward the camera, height rises with y
        lo, hi = 4.4, 6.6
        for _ in range(30):
            mid = (lo + hi) / 2
            if v6.height_at(along, mid) < z:
                lo = mid
            else:
                hi = mid
        return Vector((along, (lo + hi) / 2, z)), Vector((0.0, -1.0, 0.0)), Vector((1.0, 0.0, 0.0))
    lo, hi = -4.8, -2.6                      # the right-hand face, height falls as x grows
    for _ in range(30):
        mid = (lo + hi) / 2
        if v6.height_at(mid, along) > z:
            lo = mid
        else:
            hi = mid
    return Vector(((lo + hi) / 2, along, z)), Vector((1.0, 0.0, 0.0)), Vector((0.0, 1.0, 0.0))


def make_outcrop(point, normal, tangent, length, depth, thick, index):
    """A flattened, noise-displaced boulder half buried in the wall at `point`."""
    r = random.Random(SEED * 47 + index)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1.0, location=(0, 0, 0))
    obj = bpy.context.active_object
    ox, oy, oz = r.uniform(0, 50), r.uniform(0, 50), r.uniform(0, 50)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    for v in bm.verts:
        v.co *= 1.0 + bnoise.noise(Vector((v.co.x * 1.6 + ox, v.co.y * 1.6 + oy, v.co.z * 1.6 + oz))) * 0.32
    bm.to_mesh(obj.data)
    bm.free()
    obj.scale = (length / 2, depth, thick / 2)
    obj.rotation_euler = Euler((r.uniform(-0.05, 0.05), r.uniform(-0.05, 0.05), math.atan2(tangent.y, tangent.x)), "XYZ")
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    obj.location = point + normal * depth * 0.30 - Vector((0.0, 0.0, thick * 0.12))
    variant = ROCK_VARIANTS[(0, 3, 2, 0)[index % 4]]        # grey, mossy, slate, grey (limestone is the wall's own tan)
    name, base, dark, light, moss = variant
    obj.data.materials.append(stone_material(name, base, dark, light, moss, SEED + len(name)))
    v6.shade_flat(obj)
    _box_project_uvs(obj, scale=1.6 / max(depth, 0.3))
    v6.add_outline(obj, 0.022)
    outline = bpy.data.objects[obj.name + "_Outline"]
    outline.name = f"LedgeRock_{index}_Outline"
    obj.name = f"LedgeRock_{index}"
    return obj


def _ledge_tuft(fb, r, centre, s):
    """A small mound of rounded leaves growing on top of an outcrop."""
    families = [(f["light"], f["mid"]) for f in LEAF_FAMILIES]
    _leaf_dome(fb, r, centre + Vector((0.0, 0.0, s * 0.30)), (s, s, s * 0.8), 14, families,
               LEAF_UNDER, LEAF_CORE, leaf_scale=0.95, below=-0.1)


def make_ledges():
    r = random.Random(SEED * 41)
    tufts = _Foliage()
    count = 0
    # Where the wall is tall enough: the front face left of the fall, and a little of it right of the
    # fall, plus the shelf's right-hand side face. Widened as far as the shelf's own rectangle allows;
    # the per-spot "tall enough" check below skips the stretches where the ground rises to meet the
    # wall on its own, so nothing needs to be measured by hand.
    spans = [("front", -14.7, -8.5), ("front", -4.85, -3.85), ("right", 6.0, 7.6)]
    for face, start, stop in spans:
        for level, frac in enumerate((0.30, 0.66)):
            along = start + r.uniform(0.0, 0.3) + 0.9 * level
            while along < stop - 0.7:
                length = min(r.uniform(2.0, 3.2), stop - along)
                mid = along + length / 2
                if face == "front" and (FALL_GAP[0] - length / 2 < mid < FALL_GAP[1] + length / 2):
                    along += 0.6
                    continue
                # The foot (ground level at the base of the wall) sits a little in front of the
                # face: below it in y for the front face, out past it in x for the right-hand one.
                foot = v6.height_at(mid, 4.0) if face == "front" else v6.height_at(-2.0, mid)
                z = foot + (v6.SHELF_Z - foot) * frac
                if z - foot < 0.5 or v6.SHELF_Z - z < 0.45:
                    along += length + 0.5
                    continue
                point, normal, tangent = _wall_point(face, mid, z)
                depth = r.uniform(0.7, 0.9)
                thick = r.uniform(0.5, 0.7)
                make_outcrop(point, normal, tangent, length, depth, thick, count)
                if r.random() < 0.7:
                    off = tangent * r.uniform(-length * 0.25, length * 0.25) + normal * depth * 0.10
                    _ledge_tuft(tufts, r, point + off + Vector((0.0, 0.0, thick * 0.34)), r.uniform(0.14, 0.2))
                count += 1
                along += length + r.uniform(0.15, 0.5)
    print("LEDGES", count)
    _finish(tufts, "Ledge_Tufts", 0.0, 0.0, 0.0, 0.01)


# -- Swap into v6 and run ----------------------------------------------------

v6.make_boulder = make_rock
v6.build_terrain = build_terrain
v6.make_shrub = make_shrub
v6.make_olive = place_olive
v6.make_cypress = place_cypress

_scatter_vegetation = v6.scatter_vegetation


def scatter_with_ledges():
    _scatter_vegetation()
    make_ledges()


v6.scatter_vegetation = scatter_with_ledges

if __name__ == "__main__":
    v6.OUT_GLB = os.environ["LL_VALLEY_OUT"]
    v6.main()
