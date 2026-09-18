"""Render EEVEE previews of valley v6 (layout + river detail) with characters
in place for scale.

Two shots are written:
  valley_preview_v6.png        wide, front-right — reads the whole valley layout
  valley_preview_v6_river.png  close on the cliff, waterfall and plunge pool

The v6 valley's own outline hulls are left visible on purpose: they are
single-skin inverted hulls with backface culling, so this preview is also the
check that they render as a rim. The legacy character GLBs (v4/v5) still carry
Solidify two-layer hulls, which render as a lid, so those are hidden here.

Run: blender --background --python art/blender/scripts/render_valley_preview_v6.py
"""
import bpy
import math
import os
from mathutils import Vector, Euler

REPO = os.environ.get("LL_REPO", os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "..")))
ASSETS = os.environ.get("LL_ASSETS", os.path.join(REPO, "assets"))
OUT_DIR = os.environ.get("LL_PREVIEW_DIR", os.path.join(REPO, "art", "previews"))

VALLEY = "bethlehem_valley_v6.glb"
# Blender coords; glTF maps Blender (x, y, z) -> Godot (x, z, -y), so these
# match where main.tscn puts each actor in the Godot scene.
CHARACTERS = [
    ("wonder_walker_v5.glb", (0.0, -4.0, 0.0), (1, 1, 1)),
    ("david_mentor_v4.glb", (0.0, 3.0, 0.0), (1, 1, 1)),
    ("wonder_items_v4.glb", (2.0, 0.0, 0.0), (1.35, 1.35, 1.35)),
]

SHOTS = [
    ("valley_preview_v6.png", (13.0, -19.0, 12.0), (-2.0, 1.5, 1.0), 32),
    ("valley_preview_v6_river.png", (0.5, -3.0, 3.6), (-6.4, 4.6, 1.3), 40),
]


def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def import_at(path, loc, scale, hide_outlines):
    if not os.path.isfile(path):
        raise FileNotFoundError(path)
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    for o in new:
        if o.parent is None:
            o.location = tuple(o.location[i] + loc[i] for i in range(3))
            o.scale = tuple(o.scale[i] * scale[i] for i in range(3))
        if hide_outlines and ("Outline" in o.name or o.name.endswith("_OL")):
            o.hide_render = True
            o.hide_viewport = True
    print("IMPORTED", os.path.basename(path), len(new), "objects")
    return new


def setup_world():
    world = bpy.data.worlds.new("PreviewWorld")
    bpy.context.scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.93, 0.86, 0.72, 1.0)  # warm paper sky
    bg.inputs[1].default_value = 1.0


def setup_lights():
    bpy.ops.object.light_add(type="SUN", location=(4, 6, 14))
    sun = bpy.context.active_object
    sun.data.energy = 3.0
    sun.data.color = (1.0, 0.95, 0.85)
    sun.data.angle = math.radians(6.0)
    sun.rotation_euler = Euler((math.radians(48), math.radians(12), math.radians(-35)), "XYZ")

    bpy.ops.object.light_add(type="AREA", location=(-10, -8, 9))
    fill = bpy.context.active_object
    fill.data.energy = 300
    fill.data.color = (0.75, 0.85, 1.0)
    fill.data.size = 18


def setup_eevee(scene):
    try:
        scene.render.engine = "BLENDER_EEVEE"
    except Exception:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 900
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    if hasattr(scene, "eevee"):
        ee = scene.eevee
        if hasattr(ee, "taa_render_samples"):
            ee.taa_render_samples = 48
        if hasattr(ee, "use_gtao"):
            ee.use_gtao = True
        if hasattr(ee, "use_soft_shadows"):
            ee.use_soft_shadows = True


def render_shot(name, loc, target, lens):
    bpy.ops.object.camera_add(location=loc)
    cam = bpy.context.active_object
    cam.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = lens
    cam.data.clip_end = 400
    bpy.context.scene.camera = cam
    out = os.path.join(OUT_DIR, name)
    bpy.context.scene.render.filepath = out
    print("RENDERING", name, flush=True)
    bpy.ops.render.render(write_still=True)
    print("PREVIEW_WROTE", out)
    bpy.data.objects.remove(cam, do_unlink=True)


def main():
    clear()
    setup_world()
    import_at(os.path.join(ASSETS, VALLEY), (0, 0, 0), (1, 1, 1), hide_outlines=False)
    for fname, loc, scale in CHARACTERS:
        path = os.path.join(ASSETS, fname)
        if os.path.isfile(path):
            import_at(path, loc, scale, hide_outlines=True)
        else:
            print("SKIP (missing)", fname)
    setup_lights()
    setup_eevee(bpy.context.scene)
    bpy.context.view_layer.update()
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, loc, target, lens in SHOTS:
        render_shot(name, loc, target, lens)


if __name__ == "__main__":
    main()
