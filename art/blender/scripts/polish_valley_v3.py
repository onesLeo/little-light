"""
Little Light — Bethlehem Valley polish pass (v3)
Adds paper-craft trees, shrubs, rocks for a more natural Judean-hills diorama.
Run: blender --background --python polish_valley_v3.py
"""
import bpy
import math
import os
from mathutils import Vector, Euler

# Paths — prefer env, else Windows wonder-walker folder when run on laptop
IN_GLB = os.environ.get(
    "LL_VALLEY_IN",
    r"C:\Users\onesa\wonder-walker\bethlehem_valley_v2.glb",
)
OUT_GLB = os.environ.get(
    "LL_VALLEY_OUT",
    r"C:\Users\onesa\wonder-walker\bethlehem_valley_v3.glb",
)
GRAIN = os.environ.get(
    "LL_PAPER_GRAIN",
    r"C:\Users\onesa\wonder-walker\paper_grain.png",
)

# Warm paper palette (Judean hills)
COL_HILL = (0.86, 0.74, 0.52, 1.0)
COL_GROUND = (0.78, 0.70, 0.50, 1.0)
COL_CYPRESS = (0.28, 0.42, 0.30, 1.0)
COL_OLIVE = (0.45, 0.52, 0.34, 1.0)
COL_TRUNK = (0.42, 0.30, 0.20, 1.0)
COL_ROCK = (0.62, 0.58, 0.52, 1.0)
COL_SHRUB = (0.35, 0.48, 0.32, 1.0)
COL_OUTLINE = (0.08, 0.06, 0.05, 1.0)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.images):
        for b in list(block):
            if b.users == 0:
                block.remove(b)


def matte(name, color, grain_path=None):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = 0.95
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.05
    elif "Specular" in bsdf.inputs:
        bsdf.inputs["Specular"].default_value = 0.05
    if grain_path and os.path.isfile(grain_path):
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(grain_path)
        tex.interpolation = "Closest"
        mix = nt.nodes.new("ShaderNodeMixRGB")
        mix.blend_type = "MULTIPLY"
        mix.inputs["Fac"].default_value = 0.35
        mix.inputs["Color1"].default_value = color
        nt.links.new(tex.outputs["Color"], mix.inputs["Color2"])
        nt.links.new(mix.outputs["Color"], bsdf.inputs["Base Color"])
        uv = nt.nodes.new("ShaderNodeTexCoord")
        mapn = nt.nodes.new("ShaderNodeMapping")
        mapn.inputs["Scale"].default_value = (4.0, 4.0, 4.0)
        nt.links.new(uv.outputs["Object"], mapn.inputs["Vector"])
        nt.links.new(mapn.outputs["Vector"], tex.inputs["Vector"])
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mat.diffuse_color = color
    return mat


def shade_flat(obj):
    for poly in obj.data.polygons:
        poly.use_smooth = False


def add_outline(obj, thickness=0.035):
    """Inverted-hull outline shell (exports to glTF)."""
    outline = obj.copy()
    outline.data = obj.data.copy()
    outline.name = obj.name + "_Outline"
    bpy.context.collection.objects.link(outline)
    # Solidify outward + black backface material
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


def make_cypress(x, y, z, h=2.4, seed=0):
    """Tall paper cypress — typical Judean silhouette."""
    mats = {
        "trunk": matte("Trunk", COL_TRUNK, GRAIN),
        "leaf": matte("Cypress", COL_CYPRESS, GRAIN),
    }
    parts = []
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=6, radius=0.08 * (h / 2.4), depth=h * 0.25,
        location=(x, y, z + h * 0.12),
    )
    trunk = bpy.context.active_object
    trunk.name = f"CypressTrunk_{seed}"
    trunk.data.materials.append(mats["trunk"])
    shade_flat(trunk)
    parts.append(trunk)

    # Stacked tapered cones / icospheres for foliage
    layers = [
        (0.35, 0.55, 0.32),
        (0.28, 0.50, 0.55),
        (0.20, 0.42, 0.78),
        (0.12, 0.28, 0.95),
    ]
    for i, (r, d, zh) in enumerate(layers):
        bpy.ops.mesh.primitive_cone_add(
            vertices=7,
            radius1=r * (h / 2.4),
            radius2=0.02,
            depth=d * (h / 2.4),
            location=(x, y, z + h * zh * 0.55),
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
    add_outline(obj, 0.028)
    return obj


def make_olive(x, y, z, s=1.0, seed=0):
    """Short rounded olive-tree silhouette."""
    mats = {
        "trunk": matte("OliveTrunk", COL_TRUNK, GRAIN),
        "leaf": matte("OliveLeaf", COL_OLIVE, GRAIN),
    }
    parts = []
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=6, radius=0.07 * s, depth=0.55 * s,
        location=(x, y, z + 0.28 * s),
    )
    trunk = bpy.context.active_object
    trunk.data.materials.append(mats["trunk"])
    shade_flat(trunk)
    parts.append(trunk)

    for i, (ox, oy, oz, r) in enumerate([
        (0.0, 0.0, 0.75, 0.45),
        (0.22, 0.1, 0.70, 0.32),
        (-0.2, -0.12, 0.68, 0.30),
        (0.05, 0.18, 0.85, 0.26),
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
    add_outline(obj, 0.025)
    return obj


def make_shrub(x, y, z, s=0.45, seed=0):
    bpy.ops.mesh.primitive_ico_sphere_add(
        subdivisions=1, radius=s, location=(x, y, z + s * 0.55)
    )
    obj = bpy.context.active_object
    obj.name = f"Shrub_{seed}"
    obj.scale = (1.1, 0.9, 0.7)
    bpy.ops.object.transform_apply(scale=True)
    obj.data.materials.append(matte("Shrub", COL_SHRUB, GRAIN))
    shade_flat(obj)
    add_outline(obj, 0.02)
    return obj


def make_rock(x, y, z, s=0.35, seed=0):
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
    add_outline(obj, 0.018)
    return obj


def import_valley(path):
    if not os.path.isfile(path):
        raise FileNotFoundError(path)
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    imported = [o for o in bpy.data.objects if o not in before]
    for o in imported:
        shade_flat(o)
    return imported


def main():
    clear_scene()
    import_valley(IN_GLB)

    # Scatter — keep playable center clear-ish; denser on ridges
    cypress = [
        (-6.5, -3.0, 0.0, 2.6),
        (-7.2, 1.5, 0.0, 2.2),
        (-5.0, 4.5, 0.0, 2.8),
        (6.0, -2.5, 0.0, 2.4),
        (7.0, 2.0, 0.0, 2.9),
        (5.5, 5.0, 0.0, 2.1),
        (-3.5, -5.5, 0.0, 2.3),
        (3.0, -6.0, 0.0, 2.5),
        (-8.0, -1.0, 0.0, 3.0),
        (8.2, 0.5, 0.0, 2.7),
    ]
    for i, (x, y, z, h) in enumerate(cypress):
        make_cypress(x, y, z, h=h, seed=i)

    olives = [
        (-2.0, 3.2, 0.0, 1.1),
        (2.4, 2.8, 0.0, 0.95),
        (-4.0, -1.5, 0.0, 1.0),
        (4.2, -0.8, 0.0, 1.15),
        (-1.0, -3.8, 0.0, 0.9),
        (1.5, 5.2, 0.0, 1.05),
    ]
    for i, (x, y, z, s) in enumerate(olives):
        make_olive(x, y, z, s=s, seed=i)

    shrubs = [
        (-3.2, 1.0, 0.0, 0.4),
        (3.5, 1.2, 0.0, 0.35),
        (-2.5, -2.8, 0.0, 0.38),
        (2.8, -3.2, 0.0, 0.42),
        (0.5, 3.8, 0.0, 0.33),
        (-5.5, 2.5, 0.0, 0.4),
        (5.8, -4.0, 0.0, 0.36),
        (-0.8, -5.0, 0.0, 0.3),
    ]
    for i, (x, y, z, s) in enumerate(shrubs):
        make_shrub(x, y, z, s=s, seed=i)

    rocks = [
        (-1.5, 0.8, 0.0, 0.28),
        (1.8, -1.2, 0.0, 0.32),
        (-4.5, -3.5, 0.0, 0.4),
        (4.8, 3.5, 0.0, 0.35),
        (0.2, -2.5, 0.0, 0.22),
        (-6.0, 0.2, 0.0, 0.45),
    ]
    for i, (x, y, z, s) in enumerate(rocks):
        make_rock(x, y, z, s=s, seed=i)

    # Ensure units meters
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0

    os.makedirs(os.path.dirname(OUT_GLB), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=OUT_GLB,
        export_format="GLB",
        export_apply=True,
        export_texcoords=True,
        export_normals=True,
        export_materials="EXPORT",
    )
    print("WROTE", OUT_GLB)


if __name__ == "__main__":
    main()
