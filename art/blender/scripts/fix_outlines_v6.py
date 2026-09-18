"""
Little Light — rebuild the inverted-hull outlines in an already-exported GLB.

Why this exists
---------------
The generators build each model's ink outline with a Solidify modifier
(`use_flip_normals=True`). Solidify produces a **two-layer** shell: the grown
skin *and* a copy of the original surface. Blender's preview never showed the
problem because the preview scripts hide `*_Outline` objects, but in Godot the
result is an opaque, lit shell that completely encases the model — the
Wonder-Walker, David, the lambs and the props all render as flat black
silhouettes. No cull mode rescues a two-layer shell: whichever side you cull,
one skin still sits in front of the body.

Two things are needed for a real toon outline, and this script applies both to
an existing GLB without regenerating the character:

1. A **single-skin** hull: push every vertex along its normal and flip the
   winding, so the only thing drawn is the far side of a slightly larger copy —
   which shows as a rim around the silhouette.
2. **Backface culling on the outline material.** Blender's default material is
   double-sided, which exports as glTF `doubleSided: true` and imports into
   Godot as `cull_mode = Disabled`. An unculled inverted hull is just a lid
   again, so the outline material is marked single-sided here.

Body materials are deliberately left double-sided — some of these meshes have
triangle winding that disagrees with their normals, and culling them would
make the visible side of a character disappear.

Skinned meshes keep their armature modifier and vertex groups (the hull is an
object copy), so the Wonder-Walker's outline still follows the walk cycle.

Run:
    LL_FIX_IN=assets/wonder_walker_v5.glb LL_FIX_OUT=assets/wonder_walker_v6.glb \
    blender --background --python art/blender/scripts/fix_outlines_v6.py
"""
import bpy
import bmesh
import os
import sys
from mathutils import Vector

IN_GLB = os.environ.get("LL_FIX_IN")
OUT_GLB = os.environ.get("LL_FIX_OUT")
# Outline width as a fraction of the model's bounding-box diagonal, so a lamb
# and a 7m cypress both get a proportionate line.
WIDTH_FRAC = float(os.environ.get("LL_FIX_WIDTH", "0.006"))
WIDTH_MIN, WIDTH_MAX = 0.008, 0.05
OUTLINE_RGBA = (0.08, 0.06, 0.05, 1.0)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.images):
        for b in list(block):
            if b.users == 0:
                block.remove(b)


def outline_material():
    mat = bpy.data.materials.get("OutlineInk")
    if mat:
        return mat
    mat = bpy.data.materials.new("OutlineInk")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = OUTLINE_RGBA
    bsdf.inputs["Roughness"].default_value = 1.0
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.0
    # The essential half of the fix — see the module docstring.
    mat.use_backface_culling = True
    mat.diffuse_color = OUTLINE_RGBA
    return mat


def bbox_diagonal(obj):
    corners = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    lo = Vector((min(c.x for c in corners), min(c.y for c in corners), min(c.z for c in corners)))
    hi = Vector((max(c.x for c in corners), max(c.y for c in corners), max(c.z for c in corners)))
    return (hi - lo).length


def build_hull(base, mat):
    """A single-skin inverted hull copied from `base`."""
    hull = base.copy()
    hull.data = base.data.copy()
    hull.name = base.name + "_Outline"
    bpy.context.collection.objects.link(hull)
    hull.parent = base.parent
    hull.matrix_parent_inverse = base.matrix_parent_inverse.copy()
    hull.matrix_world = base.matrix_world.copy()

    scale = max(abs(base.matrix_world.to_scale().x), 1e-4)
    width = min(WIDTH_MAX, max(WIDTH_MIN, bbox_diagonal(base) * WIDTH_FRAC)) / scale

    bm = bmesh.new()
    bm.from_mesh(hull.data)
    bm.normal_update()
    for v in bm.verts:
        v.co += v.normal * width
    for f in bm.faces:
        f.normal_flip()
    bm.to_mesh(hull.data)
    bm.free()

    hull.data.materials.clear()
    hull.data.materials.append(mat)
    for p in hull.data.polygons:
        p.use_smooth = False
    return hull, width


def main():
    if not IN_GLB or not OUT_GLB:
        sys.exit("set LL_FIX_IN and LL_FIX_OUT")
    if not os.path.isfile(IN_GLB):
        sys.exit(f"missing input: {IN_GLB}")

    clear_scene()
    bpy.ops.import_scene.gltf(filepath=IN_GLB)

    mat = outline_material()
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    by_name = {o.name: o for o in meshes}
    old_hulls = [o for o in meshes if o.name.endswith("_Outline") or o.name.endswith("_OL")]

    rebuilt, orphaned = 0, []
    for hull in old_hulls:
        base_name = hull.name.rsplit("_Outline", 1)[0].rsplit("_OL", 1)[0]
        base = by_name.get(base_name)
        if base is None:
            # No body to regrow from: at least stop it acting as a lid.
            for slot in hull.material_slots:
                if slot.material:
                    slot.material.use_backface_culling = True
            orphaned.append(hull.name)
            continue
        bpy.data.objects.remove(hull, do_unlink=True)
        new_hull, width = build_hull(base, mat)
        print(f"REBUILT {new_hull.name} width={width:.4f}")
        rebuilt += 1

    print("REBUILT_COUNT", rebuilt)
    print("ORPHANED", orphaned)

    out_dir = os.path.dirname(OUT_GLB)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=OUT_GLB,
        export_format="GLB",
        export_apply=False,          # keep armature modifiers intact
        export_texcoords=True,
        export_normals=True,
        export_materials="EXPORT",
        export_animations=True,
    )
    print("WROTE", OUT_GLB)


if __name__ == "__main__":
    main()
