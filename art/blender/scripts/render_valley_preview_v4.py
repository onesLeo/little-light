"""Render EEVEE tabletop preview of valley v4 + characters for contrast check."""
import bpy
import math
import os
from mathutils import Vector, Euler

ASSETS = os.environ.get(
    "LL_ASSETS",
    "/workspace/little-light/little-light-godot/assets",
)
OUT = os.environ.get(
    "LL_PREVIEW_OUT",
    "/workspace/little-light/little-light-godot/art/previews/valley_preview_v4.png",
)

FILES = [
    ("bethlehem_valley_v4.glb", (0, 0, 0), (1, 1, 1)),
    ("wonder_walker_v4.glb", (3.5, 0.0, 0), (1, 1, 1)),
    ("david_mentor_v3.glb", (2.0, -1.2, 0), (1, 1, 1)),
    ("wonder_items_v3.glb", (3.8, -0.5, 0), (1.35, 1.35, 1.35)),
]


def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def import_at(path, loc, scale):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    roots = [o for o in bpy.data.objects if o not in before and o.parent is None]
    for o in bpy.data.objects:
        if o not in before:
            o.select_set(False)
    # Move all newly imported objects relative to origin by shifting root empties/meshes
    for o in list(bpy.data.objects):
        if o not in before and o.parent is None:
            o.location = (
                o.location[0] + loc[0],
                o.location[1] + loc[1],
                o.location[2] + loc[2],
            )
            o.scale = (
                o.scale[0] * scale[0],
                o.scale[1] * scale[1],
                o.scale[2] * scale[2],
            )


def setup_world():
    world = bpy.data.worlds.new("PreviewWorld")
    bpy.context.scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.78, 0.86, 0.80, 1.0)  # soft sage sky
    bg.inputs[1].default_value = 0.55


def setup_lights():
    bpy.ops.object.light_add(type="SUN", location=(4, 6, 14))
    sun = bpy.context.active_object
    sun.data.energy = 1.4
    sun.data.color = (1.0, 0.95, 0.85)
    sun.rotation_euler = Euler((math.radians(45), math.radians(15), math.radians(-30)), "XYZ")

    bpy.ops.object.light_add(type="AREA", location=(-6, -2, 8))
    fill = bpy.context.active_object
    fill.data.energy = 40
    fill.data.color = (0.75, 0.85, 1.0)
    fill.data.size = 12


def setup_camera():
    # High tabletop / DOGWALK-ish angle looking at center
    bpy.ops.object.camera_add(location=(6.5, -10.0, 8.0))
    cam = bpy.context.active_object
    cam.name = "PreviewCam"
    # Tabletop angle toward stream/waterfall + characters
    direction = Vector((4.8, 0.5, 1.0)) - Vector(cam.location)
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = 32
    cam.data.clip_end = 200
    bpy.context.scene.camera = cam


def setup_eevee(scene):
    scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in dir(bpy.types) or True else "BLENDER_EEVEE"
    # Blender 4.3 uses EEVEE
    try:
        scene.render.engine = "BLENDER_EEVEE"
    except Exception:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 1000
    scene.render.filepath = OUT
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    # Soft look
    if hasattr(scene, "eevee"):
        ee = scene.eevee
        if hasattr(ee, "taa_render_samples"):
            ee.taa_render_samples = 32
        if hasattr(ee, "use_gtao"):
            ee.use_gtao = True


def main():
    clear()
    setup_world()
    for fname, loc, scale in FILES:
        path = os.path.join(ASSETS, fname)
        if not os.path.isfile(path):
            raise FileNotFoundError(path)
        import_at(path, loc, scale)
        print("IMPORTED", path)
    
    # Hide inverted-hull outlines for EEVEE preview (they shade as solid black)
    for o in bpy.data.objects:
        if "Outline" in o.name or o.name.endswith("_OL"):
            o.hide_render = True
            o.hide_viewport = True

    setup_lights()
    setup_camera()
    setup_eevee(bpy.context.scene)
    bpy.context.view_layer.update()
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    print("RENDERING…", flush=True)
    bpy.ops.render.render(write_still=True)
    print("PREVIEW_WROTE", OUT)


if __name__ == "__main__":
    main()
