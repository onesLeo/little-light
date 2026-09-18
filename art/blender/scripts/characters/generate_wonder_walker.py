"""
Little Light -- Wonder-Walker Character Generator
==================================================

Builds a low-poly, papercraft/stop-motion-style character mesh in Blender,
matching the art direction already locked in the project's Art & Tech
Pipeline doc:

    - DOGWALK-inspired papercraft look
    - Flat / matte shading (no smooth shading, faceted low-poly)
    - Thin dark edge outlines (built as real geometry via an inverted-hull
      "outline shell", so it survives glTF export into Godot -- Blender's
      Freestyle line render does NOT export to glTF, so we don't use it)
    - Customizable in skin tone and outfit color (per the design doc:
      "an original child avatar, the Wonder-Walker, customizable in name,
      skin tone, and outfit")
    - Exported at real-world meter scale for a direct glTF -> Godot import

This is a FIRST PASS base mesh + simple rig, meant to replace the
CapsuleMesh placeholder currently used in `little-light-wonder-walker.gd`.
It is not final art -- no paper-grain texture, no hand-authored asymmetry,
no face detail beyond simple eye markers. Treat it as the next step up
from a placeholder, ready to refine by hand in Blender or swap for real
art later.

USAGE
-----
Run this whole file inside Blender (Scripting tab -> Run Script), or have
your Blender-control bot execute it as one Python payload. It is written
as a single top-to-bottom script (no CLI args) so a bot that just executes
"blocks of Python" can run it unmodified. To customize the look, edit the
CONFIG block below before running, or call `generate_wonder_walker(...)`
again afterward with different arguments (each call clears the scene
first).

Tested against the Blender 4.x / 5.x Python API (bpy).
"""

import bpy
import math
import os


# ---------------------------------------------------------------------------
# CONFIG -- tweak these and re-run to get a different Wonder-Walker variant.
# Colors are linear-ish RGB 0-1 tuples (Blender's color picker uses the same
# scale). Feel free to hand these values off to your bot as parameters.
# ---------------------------------------------------------------------------

CONFIG = {
    "skin_tone":        (0.85, 0.65, 0.48),   # warm mid skin tone
    "hair_color":       (0.25, 0.15, 0.10),   # dark brown
    "outfit_primary":   (0.75, 0.35, 0.20),   # warm terracotta tunic
    "outfit_secondary": (0.92, 0.85, 0.70),   # cream trim / sash
    "shoe_color":       (0.35, 0.22, 0.15),   # brown sandals

    "height_m": 1.15,          # a child character -- ~1.15m tall
    "outline_thickness": 0.012,  # in meters; papercraft edge-line thickness
    "outline_color": (0.05, 0.05, 0.06),

    # Absolute path preferred when running headless; // is Blender-relative.
    "export_path": r"C:\Users\onesa\wonder-walker\wonder_walker.glb",
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def clear_scene():
    """Remove all existing objects, meshes, materials, armatures."""
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block_type in (bpy.data.meshes, bpy.data.materials, bpy.data.armatures):
        for block in list(block_type):
            if block.users == 0:
                block_type.remove(block)


def make_flat_material(name, color, roughness=0.85, metallic=0.0):
    """Flat/matte Principled BSDF material -- the papercraft look wants
    no shine, no reflections, just flat honest color."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    mat.diffuse_color = (*color, 1.0)  # solid-shading viewport color
    return mat


def add_box(name, size, location, material=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.active_object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if material:
        obj.data.materials.append(material)
    # Keep faceted look -- never shade smooth
    for poly in obj.data.polygons:
        poly.use_smooth = False
    return obj


def add_cylinder(name, radius, depth, location, rotation=(0, 0, 0), material=None, vertices=8):
    bpy.ops.mesh.primitive_cylinder_add(
        radius=radius, depth=depth, location=location, rotation=rotation, vertices=vertices
    )
    obj = bpy.context.active_object
    obj.name = name
    if material:
        obj.data.materials.append(material)
    for poly in obj.data.polygons:
        poly.use_smooth = False
    return obj


def add_sphere(name, radius, location, material=None, segments=8, ring_count=6):
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=radius, location=location, segments=segments, ring_count=ring_count
    )
    obj = bpy.context.active_object
    obj.name = name
    if material:
        obj.data.materials.append(material)
    for poly in obj.data.polygons:
        poly.use_smooth = False
    return obj


def join_objects(objects, result_name):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    joined = bpy.context.active_object
    joined.name = result_name
    return joined


def make_outline_shell(source_obj, thickness, material):
    """Inverted-hull outline: duplicate, solidify outward, flip normals,
    assign dark mat. Exports as real geo into glTF (unlike Freestyle)."""
    bpy.ops.object.select_all(action="DESELECT")
    source_obj.select_set(True)
    bpy.context.view_layer.objects.active = source_obj
    bpy.ops.object.duplicate()
    outline = bpy.context.active_object
    outline.name = source_obj.name + "_Outline"

    solidify = outline.modifiers.new(name="OutlineSolidify", type="SOLIDIFY")
    solidify.thickness = thickness
    solidify.offset = 1.0  # push outward
    solidify.use_flip_normals = True
    bpy.ops.object.modifier_apply(modifier=solidify.name)

    outline.data.materials.clear()
    outline.data.materials.append(material)

    # Backface-only style: disable shadow so the shell reads as a line
    outline.visible_shadow = False
    return outline


def build_simple_rig(height, hip_y, shoulder_y, torso_w, arm_len, leg_len, arm_r):
    """Minimal humanoid armature: root, hips, spine, chest, neck, head,
    and L/R upper/lower arm + leg bones. Enough for a placeholder roam."""
    arm_data = bpy.data.armatures.new("WW_Armature")
    arm_obj = bpy.data.objects.new("WW_Armature", arm_data)
    bpy.context.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode="EDIT")
    bones = arm_data.edit_bones

    def add_bone(name, head, tip, parent=None):
        b = bones.new(name)
        b.head = head
        b.tail = tip
        if parent is not None:
            b.parent = parent
            b.use_connect = False
        return b

    root = add_bone("Root", (0, 0, 0), (0, 0, 0.08))
    hips = add_bone("Hips", (0, 0, hip_y), (0, 0, hip_y + 0.08), root)
    spine = add_bone("Spine", (0, 0, hip_y + 0.08), (0, 0, shoulder_y - 0.06), hips)
    chest = add_bone("Chest", (0, 0, shoulder_y - 0.06), (0, 0, shoulder_y + 0.04), spine)
    neck = add_bone("Neck", (0, 0, shoulder_y + 0.04), (0, 0, shoulder_y + 0.12), chest)
    head = add_bone("Head", (0, 0, shoulder_y + 0.12), (0, 0, height), neck)

    for side, x_sign in (("L", -1), ("R", 1)):
        sx = x_sign * (torso_w / 2 + arm_r * 0.5)
        # Arms hang down from shoulders
        upper = add_bone(
            f"UpperArm_{side}",
            (sx, 0, shoulder_y),
            (sx, 0, shoulder_y - arm_len * 0.5),
            chest,
        )
        add_bone(
            f"LowerArm_{side}",
            (sx, 0, shoulder_y - arm_len * 0.5),
            (sx, 0, shoulder_y - arm_len),
            upper,
        )
        lx = x_sign * torso_w * 0.22
        thigh = add_bone(
            f"Thigh_{side}",
            (lx, 0, hip_y),
            (lx, 0, hip_y - leg_len * 0.5),
            hips,
        )
        add_bone(
            f"Shin_{side}",
            (lx, 0, hip_y - leg_len * 0.5),
            (lx, 0, 0.02),
            thigh,
        )

    bpy.ops.object.mode_set(mode="OBJECT")
    return arm_obj


def parent_with_automatic_weights(mesh_obj, armature_obj):
    bpy.ops.object.select_all(action="DESELECT")
    mesh_obj.select_set(True)
    armature_obj.select_set(True)
    bpy.context.view_layer.objects.active = armature_obj
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")


# ---------------------------------------------------------------------------
# Main build
# ---------------------------------------------------------------------------

def generate_wonder_walker(config=None):
    if config is None:
        config = CONFIG
    clear_scene()

    h = config["height_m"]
    # Rough proportions scaled off overall height (child-like: bigger head
    # ratio than an adult figure, short limbs, blocky papercraft shapes).
    head_size   = h * 0.28
    torso_h     = h * 0.30
    torso_w     = h * 0.34
    torso_d     = h * 0.20
    leg_len     = h * 0.34
    leg_r       = h * 0.075
    arm_len     = h * 0.28
    arm_r       = h * 0.055
    hip_y       = leg_len
    shoulder_y  = hip_y + torso_h

    # --- Materials -----------------------------------------------------
    mat_skin    = make_flat_material("WW_Skin", config["skin_tone"])
    mat_hair    = make_flat_material("WW_Hair", config["hair_color"])
    mat_outfit1 = make_flat_material("WW_Outfit_Primary", config["outfit_primary"])
    mat_outfit2 = make_flat_material("WW_Outfit_Secondary", config["outfit_secondary"])
    mat_shoe    = make_flat_material("WW_Shoes", config["shoe_color"])
    mat_outline = make_flat_material("WW_Outline", config["outline_color"], roughness=1.0)
    mat_eye     = make_flat_material("WW_Eyes", (0.08, 0.08, 0.10), roughness=0.4)

    parts = []

    # --- Legs (blocky, papercraft cylinders) ----------------------------
    for side, x in (("L", -torso_w * 0.22), ("R", torso_w * 0.22)):
        leg = add_cylinder(
            f"Leg_{side}", radius=leg_r, depth=leg_len,
            location=(x, 0, leg_len / 2), material=mat_outfit1, vertices=6,
        )
        parts.append(leg)
        foot = add_box(
            f"Foot_{side}", size=(leg_r * 2.4, leg_r * 3.2, leg_r * 1.2),
            location=(x, leg_r * 1.0, leg_r * 0.6), material=mat_shoe,
        )
        parts.append(foot)

    # --- Torso (tunic) ---------------------------------------------------
    torso = add_box(
        "Torso", size=(torso_w, torso_d, torso_h),
        location=(0, 0, hip_y + torso_h / 2), material=mat_outfit1,
    )
    parts.append(torso)

    # Sash / trim band -- second outfit color for visual interest
    sash = add_box(
        "Sash", size=(torso_w * 1.02, torso_d * 1.05, torso_h * 0.18),
        location=(0, 0, hip_y + torso_h * 0.35), material=mat_outfit2,
    )
    parts.append(sash)

    # --- Arms --------------------------------------------------------------
    for side, x_sign in (("L", -1), ("R", 1)):
        x = x_sign * (torso_w / 2 + arm_r)
        arm = add_cylinder(
            f"Arm_{side}", radius=arm_r, depth=arm_len,
            location=(x, 0, shoulder_y - arm_len / 2),
            rotation=(0, 0, 0), material=mat_skin, vertices=6,
        )
        parts.append(arm)
        hand = add_sphere(
            f"Hand_{side}", radius=arm_r * 1.15,
            location=(x, 0, shoulder_y - arm_len),
            material=mat_skin, segments=6, ring_count=4,
        )
        parts.append(hand)

    # --- Head + hair + simple eye markers --------------------------------
    head_z = shoulder_y + head_size * 0.55
    head = add_sphere(
        "Head", radius=head_size * 0.5,
        location=(0, 0, head_z),
        material=mat_skin, segments=8, ring_count=6,
    )
    parts.append(head)

    # Blocky papercraft hair cap
    hair = add_box(
        "Hair",
        size=(head_size * 0.95, head_size * 0.90, head_size * 0.55),
        location=(0, -head_size * 0.05, head_z + head_size * 0.22),
        material=mat_hair,
    )
    parts.append(hair)

    # Tiny dark eye markers (not sockets -- just readable dots)
    eye_y = head_size * 0.42
    eye_z = head_z + head_size * 0.02
    eye_r = head_size * 0.055
    for side, x in (("L", -head_size * 0.18), ("R", head_size * 0.18)):
        eye = add_sphere(
            f"Eye_{side}", radius=eye_r,
            location=(x, eye_y, eye_z),
            material=mat_eye, segments=6, ring_count=4,
        )
        parts.append(eye)

    # --- Join body mesh ----------------------------------------------------
    body = join_objects(parts, "WonderWalker_Body")

    # Origin at feet for Godot-friendly import
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")

    # --- Inverted-hull outline shell --------------------------------------
    outline = make_outline_shell(body, config["outline_thickness"], mat_outline)

    # --- Simple rig --------------------------------------------------------
    armature = build_simple_rig(h, hip_y, shoulder_y, torso_w, arm_len, leg_len, arm_r)
    parent_with_automatic_weights(body, armature)
    # Outline follows the same armature so it deforms with the body
    outline.parent = armature
    outline.parent_type = "OBJECT"
    # Better: also weight the outline the same way
    parent_with_automatic_weights(outline, armature)

    # Ensure armature is the active root for export
    bpy.ops.object.select_all(action="DESELECT")
    armature.select_set(True)
    body.select_set(True)
    outline.select_set(True)
    bpy.context.view_layer.objects.active = armature

    export_path = config.get("export_path")
    if export_path:
        # Resolve Blender-relative // paths
        if export_path.startswith("//"):
            blend = bpy.data.filepath
            base = os.path.dirname(blend) if blend else os.getcwd()
            export_path = os.path.join(base, export_path[2:])
        export_dir = os.path.dirname(export_path)
        if export_dir:
            os.makedirs(export_dir, exist_ok=True)
        bpy.ops.export_scene.gltf(
            filepath=export_path,
            export_format="GLB",
            use_selection=True,
            export_apply=True,
            export_yup=True,
        )
        print(f"[WonderWalker] Exported glTF -> {export_path}")

    print("[WonderWalker] Generation complete.")
    return {"body": body, "outline": outline, "armature": armature}


# Run on load / script execute
if __name__ == "__main__":
    generate_wonder_walker(CONFIG)
