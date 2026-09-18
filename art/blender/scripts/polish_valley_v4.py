"""
Little Light — Bethlehem Valley polish pass (v4)
- Sage hills + terracotta path (contrast vs cream characters)
- Tall cypress (5.5–7.5m) + larger olives (~2.0–2.5 scale)
- Paper stream + small waterfall (static stylized water)
Run: blender --background --python polish_valley_v4.py
"""
import bpy
import math
import os
from mathutils import Vector, Euler

IN_GLB = os.environ.get(
    "LL_VALLEY_IN",
    r"C:\Users\onesa\wonder-walker\bethlehem_valley_v2.glb",
)
OUT_GLB = os.environ.get(
    "LL_VALLEY_OUT",
    r"C:\Users\onesa\wonder-walker\bethlehem_valley_v4.glb",
)
GRAIN = os.environ.get(
    "LL_PAPER_GRAIN",
    r"C:\Users\onesa\wonder-walker\paper_grain.png",
)

# Contrast palette — NOT cream
COL_HILL = (0.40, 0.50, 0.36, 1.0)       # soft sage / dusty green
COL_PATH = (0.78, 0.42, 0.24, 1.0)       # warm terracotta / ochre
COL_ROCK = (0.58, 0.56, 0.52, 1.0)       # cool stone grey
COL_SIL = (0.32, 0.40, 0.30, 1.0)        # darker ridge silhouette
COL_CYPRESS = (0.22, 0.40, 0.28, 1.0)    # readable green foliage
COL_OLIVE = (0.40, 0.52, 0.30, 1.0)
COL_TRUNK = (0.38, 0.26, 0.16, 1.0)      # brown trunks
COL_SHRUB = (0.30, 0.46, 0.28, 1.0)
COL_WATER = (0.28, 0.58, 0.70, 1.0)      # soft blue-teal
COL_WATER_DEEP = (0.20, 0.45, 0.58, 1.0)
COL_FOAM = (0.92, 0.95, 0.96, 1.0)
COL_OUTLINE = (0.08, 0.06, 0.05, 1.0)

# Material tint map for existing valley slots
VALLEY_TINTS = {
    "V_Hill": COL_HILL,
    "V_Path": COL_PATH,
    "V_Rock": COL_ROCK,
    "V_Sil": COL_SIL,
    "V_OL": COL_OUTLINE,
}


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.images):
        for b in list(block):
            if b.users == 0:
                block.remove(b)



def _bake_tinted_grain(name, color, grain_path, mix_fac=0.35):
    """Pack image = (grain*mix + (1-mix)) * color so glTF keeps the tint."""
    import numpy as np
    size = 256
    if grain_path and os.path.isfile(grain_path):
        src = bpy.data.images.load(grain_path)
        src.scale(size, size)
        pix = np.array(src.pixels[:], dtype=np.float32).reshape(size, size, 4)
    else:
        pix = np.ones((size, size, 4), dtype=np.float32)
    grain = pix[:, :, :3] * mix_fac + (1.0 - mix_fac)
    tint = np.array(color[:3], dtype=np.float32).reshape(1, 1, 3)
    rgb = np.clip(grain * tint, 0.0, 1.0)
    alpha = np.ones((size, size, 1), dtype=np.float32)
    out = np.concatenate([rgb, alpha], axis=2).reshape(-1)
    img = bpy.data.images.new(f"Tint_{name}", width=size, height=size, alpha=True)
    img.pixels = out.tolist()
    img.pack()
    return img


def matte(name, color, grain_path=None):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.95
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.05
    elif "Specular" in bsdf.inputs:
        bsdf.inputs["Specular"].default_value = 0.05
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = _bake_tinted_grain(name, color, grain_path, mix_fac=0.35)
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    uv = nt.nodes.new("ShaderNodeTexCoord")
    mapn = nt.nodes.new("ShaderNodeMapping")
    mapn.inputs["Scale"].default_value = (4.0, 4.0, 4.0)
    nt.links.new(uv.outputs["Object"], mapn.inputs["Vector"])
    nt.links.new(mapn.outputs["Vector"], tex.inputs["Vector"])
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mat.diffuse_color = color
    return mat


def tint_existing_material(mat, color, grain_path=None, mix_fac=0.85):
    """Replace Base Color with baked tinted grain (glTF-safe)."""
    if not mat or not mat.use_nodes:
        return
    nt = mat.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf = next((n for n in nodes if n.type == "BSDF_PRINCIPLED"), None)
    if not bsdf:
        return
    for link in list(bsdf.inputs["Base Color"].links):
        links.remove(link)
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = _bake_tinted_grain(mat.name, color, grain_path, mix_fac=mix_fac)
    tex.interpolation = "Closest"
    tex.location = (-300, 100)
    mapn = next((n for n in nodes if n.type == "MAPPING"), None)
    if mapn is None:
        uv = nodes.new("ShaderNodeTexCoord")
        mapn = nodes.new("ShaderNodeMapping")
        mapn.inputs["Scale"].default_value = (4.0, 4.0, 4.0)
        links.new(uv.outputs["Object"], mapn.inputs["Vector"])
    links.new(mapn.outputs["Vector"], tex.inputs["Vector"])
    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.95
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.05
    mat.diffuse_color = color



def shade_flat(obj):
    for poly in obj.data.polygons:
        poly.use_smooth = False


def add_outline(obj, thickness=0.035):
    outline = obj.copy()
    outline.data = obj.data.copy()
    outline.name = obj.name + "_Outline"
    bpy.context.collection.objects.link(outline)
    mod = outline.modifiers.new("OutlineSolidify", "SOLIDIFY")
    mod.thickness = thickness
    mod.offset = 1.0
    mod.use_flip_normals = True
    bpy.context.view_layer.objects.active = outline
    bpy.ops.object.modifier_apply(modifier="OutlineSolidify")
    mat = matte("OutlineBlack", COL_OUTLINE)
    outline.data.materials.clear()
    outline.data.materials.append(mat)
    shade_flat(outline)
    return outline


def join_selected(name):
    bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = name
    return obj


def make_cypress(x, y, z, h=6.5, seed=0):
    """Tall paper cypress — mesh height ~= h metres (taller than ~1.2m kids)."""
    mats = {
        "trunk": matte("Trunk", COL_TRUNK, GRAIN),
        "leaf": matte("Cypress", COL_CYPRESS, GRAIN),
    }
    parts = []
    trunk_h = h * 0.22
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=6, radius=0.14 * (h / 6.5), depth=trunk_h,
        location=(x, y, z + trunk_h * 0.5),
    )
    trunk = bpy.context.active_object
    trunk.name = f"CypressTrunk_{seed}"
    trunk.data.materials.append(mats["trunk"])
    shade_flat(trunk)
    parts.append(trunk)

    # Four stacked cones spanning from ~trunk top to full height h
    # (center_z, radius1, depth) as fractions of h
    layers = [
        (0.38, 0.12, 0.32),
        (0.55, 0.095, 0.30),
        (0.72, 0.07, 0.28),
        (0.88, 0.045, 0.24),
    ]
    for i, (zh, r_frac, d_frac) in enumerate(layers):
        depth = h * d_frac
        bpy.ops.mesh.primitive_cone_add(
            vertices=7,
            radius1=h * r_frac,
            radius2=0.02,
            depth=depth,
            location=(x, y, z + h * zh),
        )
        leaf = bpy.context.active_object
        leaf.name = f"CypressLeaf_{seed}_{i}"
        leaf.data.materials.append(mats["leaf"])
        shade_flat(leaf)
        parts.append(leaf)

    bpy.ops.object.select_all(action="DESELECT")
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    obj = join_selected(f"Cypress_{seed}")
    add_outline(obj, 0.045)
    return obj


def make_olive(x, y, z, s=2.2, seed=0):
    mats = {
        "trunk": matte("OliveTrunk", COL_TRUNK, GRAIN),
        "leaf": matte("OliveLeaf", COL_OLIVE, GRAIN),
    }
    parts = []
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=6, radius=0.09 * s, depth=0.65 * s,
        location=(x, y, z + 0.32 * s),
    )
    trunk = bpy.context.active_object
    trunk.data.materials.append(mats["trunk"])
    shade_flat(trunk)
    parts.append(trunk)

    for i, (ox, oy, oz, r) in enumerate([
        (0.0, 0.0, 0.85, 0.50),
        (0.28, 0.12, 0.78, 0.36),
        (-0.25, -0.14, 0.76, 0.34),
        (0.08, 0.22, 0.95, 0.30),
        (-0.1, 0.05, 1.05, 0.24),
    ]):
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=1, radius=r * s,
            location=(x + ox * s, y + oy * s, z + oz * s),
        )
        canopy = bpy.context.active_object
        canopy.data.materials.append(mats["leaf"])
        shade_flat(canopy)
        parts.append(canopy)

    bpy.ops.object.select_all(action="DESELECT")
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    obj = join_selected(f"Olive_{seed}")
    add_outline(obj, 0.035)
    return obj


def make_shrub(x, y, z, s=0.55, seed=0):
    bpy.ops.mesh.primitive_ico_sphere_add(
        subdivisions=1, radius=s, location=(x, y, z + s * 0.55)
    )
    obj = bpy.context.active_object
    obj.name = f"Shrub_{seed}"
    obj.scale = (1.1, 0.9, 0.7)
    bpy.ops.object.transform_apply(scale=True)
    obj.data.materials.append(matte("Shrub", COL_SHRUB, GRAIN))
    shade_flat(obj)
    add_outline(obj, 0.022)
    return obj


def make_rock(x, y, z, s=0.4, seed=0):
    bpy.ops.mesh.primitive_ico_sphere_add(
        subdivisions=1, radius=s, location=(x, y, z + s * 0.35)
    )
    obj = bpy.context.active_object
    obj.name = f"Rock_{seed}"
    obj.scale = (1.3, 0.9, 0.6)
    obj.rotation_euler = Euler((0.2, 0.1 * seed, 0.4 * seed), "XYZ")
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    obj.data.materials.append(matte("Rock", COL_ROCK, GRAIN))
    shade_flat(obj)
    add_outline(obj, 0.02)
    return obj


def make_stream_and_waterfall():
    """
    Side-channel brook (east of center roam path) + small ridge waterfall.
    Water meshes named Stream_*/Waterfall_*/Foam_* so collision baker can skip.
    """
    water_mat = matte("WaterTeal", COL_WATER, GRAIN)
    deep_mat = matte("WaterDeep", COL_WATER_DEEP, GRAIN)
    foam_mat = matte("FoamWhite", COL_FOAM, GRAIN)
    rock_mat = matte("WaterfallRock", COL_ROCK, GRAIN)

    # --- Winding stream bed along +X side (keeps |x|<2 clear for roam) ---
    # Centerline samples (x, y) — shallow flat slabs
    path = [
        (4.2, -7.0), (4.6, -5.2), (5.0, -3.5), (4.8, -1.8),
        (5.2, 0.0), (5.5, 1.8), (5.1, 3.6), (4.6, 5.4), (4.2, 7.0),
    ]
    stream_parts = []
    for i in range(len(path) - 1):
        x0, y0 = path[i]
        x1, y1 = path[i + 1]
        mx, my = (x0 + x1) * 0.5, (y0 + y1) * 0.5
        dx, dy = x1 - x0, y1 - y0
        length = math.hypot(dx, dy) + 0.15
        ang = math.atan2(dy, dx)
        bpy.ops.mesh.primitive_cube_add(size=1, location=(mx, my, 0.35))
        seg = bpy.context.active_object
        seg.name = f"Stream_Seg_{i}"
        seg.scale = (length * 0.55, 1.1, 0.08)
        seg.rotation_euler = (0, 0, ang)
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        seg.data.materials.append(water_mat if i % 2 == 0 else deep_mat)
        shade_flat(seg)
        stream_parts.append(seg)

        # Soft foam bank strips
        for side, oy in ((0, 0.78), (1, -0.78)):
            bpy.ops.mesh.primitive_cube_add(
                size=1,
                location=(mx - math.sin(ang) * oy, my + math.cos(ang) * oy, 0.40),
            )
            foam = bpy.context.active_object
            foam.name = f"Foam_Bank_{i}_{side}"
            foam.scale = (length * 0.48, 0.08, 0.015)
            foam.rotation_euler = (0, 0, ang)
            bpy.ops.object.transform_apply(scale=True, rotation=True)
            foam.data.materials.append(foam_mat)
            shade_flat(foam)
            add_outline(foam, 0.012)

    bpy.ops.object.select_all(action="DESELECT")
    for p in stream_parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = stream_parts[0]
    stream = join_selected("Stream_Main")
    add_outline(stream, 0.018)

    # --- Small waterfall from a rock ledge into the stream ---
    ledge_x, ledge_y = 5.0, 1.5
    # Supporting rocks (these SHOULD get collision)
    for i, (ox, oy, oz, s) in enumerate([
        (0.0, 0.0, 0.9, 0.75),
        (-0.55, 0.25, 0.7, 0.55),
        (0.5, -0.2, 0.75, 0.58),
        (0.1, 0.4, 1.35, 0.5),
        (-0.2, -0.3, 0.55, 0.45),
    ]):
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=1, radius=s,
            location=(ledge_x + ox, ledge_y + oy, oz),
        )
        rk = bpy.context.active_object
        rk.name = f"Rock_Waterfall_{i}"
        rk.scale = (1.2, 0.95, 0.7)
        bpy.ops.object.transform_apply(scale=True)
        rk.data.materials.append(rock_mat)
        shade_flat(rk)
        add_outline(rk, 0.02)

    # Cascading water slabs (vertical-ish)
    cascade = [
        (ledge_x + 0.05, ledge_y - 0.1, 2.2, 0.55, 0.18, 0.45),
        (ledge_x + 0.0, ledge_y - 0.35, 1.5, 0.60, 0.20, 0.55),
        (ledge_x - 0.05, ledge_y - 0.6, 0.85, 0.70, 0.22, 0.50),
        (ledge_x - 0.1, ledge_y - 0.85, 0.45, 0.85, 0.28, 0.25),
    ]
    wf_parts = []
    for i, (wx, wy, wz, sx, sy, sz) in enumerate(cascade):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(wx, wy, wz))
        slab = bpy.context.active_object
        slab.name = f"Waterfall_Sheet_{i}"
        slab.scale = (sx, sy, sz)
        slab.rotation_euler = (math.radians(18), 0, math.radians(-12))
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        slab.data.materials.append(water_mat if i < 2 else deep_mat)
        shade_flat(slab)
        wf_parts.append(slab)

    bpy.ops.object.select_all(action="DESELECT")
    for p in wf_parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = wf_parts[0]
    waterfall = join_selected("Waterfall_Main")
    add_outline(waterfall, 0.02)

    # Splash foam pool at base
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=8, radius=0.55, depth=0.04,
        location=(ledge_x - 0.2, ledge_y - 1.0, 0.38),
    )
    splash = bpy.context.active_object
    splash.name = "Foam_Splash"
    splash.scale = (1.2, 0.85, 1.0)
    bpy.ops.object.transform_apply(scale=True)
    splash.data.materials.append(foam_mat)
    shade_flat(splash)
    add_outline(splash, 0.014)

    # Tiny foam strips on cascade edges
    for i, (wx, wy, wz) in enumerate([
        (ledge_x + 0.25, ledge_y - 0.15, 1.05),
        (ledge_x - 0.22, ledge_y - 0.3, 0.7),
        (ledge_x + 0.18, ledge_y - 0.45, 0.4),
    ]):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(wx, wy, wz))
        edge = bpy.context.active_object
        edge.name = f"Foam_Cascade_{i}"
        edge.scale = (0.08, 0.18, 0.04)
        bpy.ops.object.transform_apply(scale=True)
        edge.data.materials.append(foam_mat)
        shade_flat(edge)
        add_outline(edge, 0.01)


def import_valley(path):
    if not os.path.isfile(path):
        raise FileNotFoundError(path)
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    imported = [o for o in bpy.data.objects if o not in before]
    for o in imported:
        if o.type == "MESH":
            shade_flat(o)
    return imported


def strip_old_props():
    """If importing v3 by mistake, remove tiny prop meshes."""
    prefixes = ("Cypress_", "Olive_", "Shrub_", "Rock_", "Stream_", "Waterfall_", "Foam_")
    doomed = [
        o for o in list(bpy.data.objects)
        if o.name.startswith(prefixes) or any(o.name.startswith(p + "Outline") or o.name.endswith("_Outline") and any(o.name.startswith(p) for p in prefixes) for p in prefixes)
    ]
    # Simpler: any Cypress_/Olive_/Shrub_/Rock_ including outlines
    doomed = []
    for o in list(bpy.data.objects):
        base = o.name.replace("_Outline", "")
        if base.startswith(("Cypress_", "Olive_", "Shrub_", "Rock_", "Stream_", "Waterfall_", "Foam_")):
            doomed.append(o)
    for o in doomed:
        bpy.data.objects.remove(o, do_unlink=True)


def recolor_valley_materials():
    for name, color in VALLEY_TINTS.items():
        mat = bpy.data.materials.get(name)
        if mat:
            tint_existing_material(mat, color, GRAIN, mix_fac=0.88)
            print("TINTED", name, color)


def main():
    clear_scene()
    import_valley(IN_GLB)
    strip_old_props()
    recolor_valley_materials()

    # Tall trees — keep center roam (|x|<2.5, |y|<3) mostly clear
    cypress = [
        (-6.5, -3.0, 0.0, 6.2),
        (-7.2, 1.5, 0.0, 5.8),
        (-5.0, 4.5, 0.0, 7.0),
        (6.8, -2.8, 0.0, 6.0),
        (7.4, 3.2, 0.0, 7.2),
        (6.2, 5.5, 0.0, 5.6),
        (-3.8, -5.8, 0.0, 6.4),
        (3.2, -6.2, 0.0, 6.8),
        (-8.2, -1.0, 0.0, 7.5),
        (8.4, 0.8, 0.0, 6.6),
        (-6.0, 6.0, 0.0, 5.9),
        (2.8, 6.5, 0.0, 6.3),
    ]
    for i, (x, y, z, h) in enumerate(cypress):
        make_cypress(x, y, z, h=h, seed=i)

    olives = [
        (-3.2, 3.8, 0.0, 2.2),
        (2.8, 3.5, 0.0, 2.0),
        (-4.5, -2.0, 0.0, 2.3),
        (3.5, -3.5, 0.0, 2.1),
        (-2.2, -4.5, 0.0, 2.0),
        (1.8, 5.5, 0.0, 2.4),
        (-5.5, 2.8, 0.0, 2.15),
    ]
    for i, (x, y, z, s) in enumerate(olives):
        make_olive(x, y, z, s=s, seed=i)

    shrubs = [
        (-3.5, 1.2, 0.0, 0.5),
        (3.2, 1.5, 0.0, 0.45),
        (-2.8, -3.0, 0.0, 0.48),
        (2.5, -3.5, 0.0, 0.52),
        (0.8, 4.2, 0.0, 0.4),
        (-5.8, 2.2, 0.0, 0.5),
        (6.2, -4.5, 0.0, 0.45),
        (-1.2, -5.2, 0.0, 0.38),
    ]
    for i, (x, y, z, s) in enumerate(shrubs):
        make_shrub(x, y, z, s=s, seed=i)

    rocks = [
        (-1.8, 1.0, 0.0, 0.32),
        (1.6, -1.5, 0.0, 0.36),
        (-4.8, -3.8, 0.0, 0.45),
        (4.2, 4.0, 0.0, 0.38),
        (0.3, -2.8, 0.0, 0.26),
        (-6.2, 0.4, 0.0, 0.5),
    ]
    for i, (x, y, z, s) in enumerate(rocks):
        make_rock(x, y, z, s=s, seed=i)

    make_stream_and_waterfall()

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
    # Height sanity print
    for o in bpy.data.objects:
        if o.name.startswith("Cypress_") and "_Outline" not in o.name:
            bb = [o.matrix_world @ Vector(c) for c in o.bound_box]
            zs = [v.z for v in bb]
            print(f"HEIGHT {o.name}: {max(zs) - min(zs):.2f}m")


if __name__ == "__main__":
    main()
