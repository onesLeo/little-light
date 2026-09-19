"""Render exported Walker GLBs, including their imported animation.

WW_REVIEW_ASSET selects a repository-relative GLB; WW_REVIEW_NAME selects
the output prefix. Renders front, rear and four walk poses into output/review.
Run with Blender --background --python art/blender/scripts/render_walker_review.py.
"""
import bpy
import math
import os
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "art/blender/output/review"
OUT.mkdir(parents=True, exist_ok=True)
asset = ROOT / os.environ.get("WW_REVIEW_ASSET", "assets/wonder_walker_v12.glb")
name = os.environ.get("WW_REVIEW_NAME", asset.stem)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(asset))
for obj in bpy.context.scene.objects:
    if "Outline" in obj.name:
        obj.hide_render = True  # Godot review separately checks inverted hulls.
    if obj.type == "ARMATURE":
        print("REVIEW_RIG", obj.name, list(obj.data.bones.keys()))
        if obj.animation_data:
            print("REVIEW_ACTION", obj.animation_data.action)

scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 24
scene.render.resolution_x = 650
scene.render.resolution_y = 800
scene.render.resolution_percentage = 100
scene.world.color = (0.35, 0.35, 0.35)
scene.view_settings.view_transform = "Standard"
scene.render.image_settings.file_format = "PNG"
bpy.ops.mesh.primitive_plane_add(size=200)
ground = bpy.context.object
mat = bpy.data.materials.new("ReviewSand")
mat.diffuse_color = (0.78, 0.73, 0.64, 1)
ground.data.materials.append(mat)
for pos, power, size in [((3, 4, 5), 350, 4), ((-3, 1, 3), 150, 3)]:
    bpy.ops.object.light_add(type="AREA", location=pos)
    light = bpy.context.object
    light.data.energy, light.data.shape, light.data.size = power, "DISK", size
    light.rotation_euler = (Vector((0, 0, 0.65)) - light.location).to_track_quat("-Z", "Y").to_euler()
bpy.ops.object.camera_add()
cam = bpy.context.object
scene.camera = cam
cam.data.type = "ORTHO"
cam.data.ortho_scale = 1.48
rigs = [o for o in scene.objects if o.type == "ARMATURE"]
shots = [("front", (1.7, 4, 1.9), None), ("rear", (-1.7, -4, 2.1), None)]
shots += [("walk_%02d" % f, (1.7, 4, 1.9), f) for f in (1, 7, 13, 19)]
for label, pos, frame in shots:
    for rig in rigs:
        rig.data.pose_position = "REST" if frame is None else "POSE"
    scene.frame_set(frame or 1)
    cam.location = pos
    cam.rotation_euler = (Vector((0, 0, 0.62)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = str(OUT / (name + "_" + label + ".png"))
    bpy.ops.render.render(write_still=True)
print("REVIEW_COMPLETE", name)
