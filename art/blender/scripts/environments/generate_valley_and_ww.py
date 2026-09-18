"""
Little Light P0.1 — Wonder-Walker paper-grain pass + rough Bethlehem valley diorama.
Blender 4.x / 5.x. Exports glTF for Godot placeholders.
"""
import bpy
import math
import os
import random

OUT_DIR = r"C:\Users\onesa\wonder-walker"
WW_GLB = os.path.join(OUT_DIR, "wonder_walker.glb")
VALLEY_GLB = os.path.join(OUT_DIR, "bethlehem_valley_placeholder.glb")
BLEND = os.path.join(OUT_DIR, "little_light_p0.blend")

CONFIG = {
    "skin_tone": (0.85, 0.65, 0.48),
    "hair_color": (0.25, 0.15, 0.10),
    "outfit_primary": (0.75, 0.35, 0.20),
    "outfit_secondary": (0.92, 0.85, 0.70),
    "shoe_color": (0.35, 0.22, 0.15),
    "height_m": 1.15,
    "outline_thickness": 0.012,
    "outline_color": (0.05, 0.05, 0.06),
    # Warm gold pastoral valley
    "hill_color": (0.82, 0.68, 0.32),
    "ground_color": (0.72, 0.58, 0.28),
    "path_color": (0.78, 0.70, 0.48),
    "rock_color": (0.55, 0.50, 0.42),
    "silhouette_color": (0.12, 0.10, 0.12),
}


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block_type in (bpy.data.meshes, bpy.data.materials, bpy.data.armatures, bpy.data.images, bpy.data.node_groups):
        for block in list(block_type):
            if getattr(block, "users", 0) == 0:
                block_type.remove(block)


def make_paper_material(name, color, roughness=0.92, grain_scale=18.0, grain_strength=0.12):
    """Flat/matte Principled + procedural paper grain (Noise -> Mix)."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nodes = nt.nodes
    links = nt.links
    nodes.clear()

    out = nodes.new("ShaderNodeOutputMaterial")
    out.location = (600, 0)
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (300, 0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = 0.0

    base = nodes.new("ShaderNodeRGB")
    base.location = (-400, 100)
    base.outputs[0].default_value = (*color, 1.0)

    tex_coord = nodes.new("ShaderNodeTexCoord")
    tex_coord.location = (-800, -100)
    mapping = nodes.new("ShaderNodeMapping")
    mapping.location = (-600, -100)
    mapping.inputs["Scale"].default_value = (grain_scale, grain_scale, grain_scale)

    noise = nodes.new("ShaderNodeTexNoise")
    noise.location = (-400, -100)
    noise.inputs["Scale"].default_value = 6.0
    noise.inputs["Detail"].default_value = 8.0
    noise.inputs["Roughness"].default_value = 0.65

    # Remap noise to subtle multiply factor around 1.0
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.location = (-200, -100)
    ramp.color_ramp.elements[0].position = 0.35
    ramp.color_ramp.elements[0].color = (1.0 - grain_strength, 1.0 - grain_strength, 1.0 - grain_strength, 1.0)
    ramp.color_ramp.elements[1].position = 0.75
    ramp.color_ramp.elements[1].color = (1.0 + grain_strength * 0.5, 1.0 + grain_strength * 0.5, 1.0 + grain_strength * 0.5, 1.0)

    mix = nodes.new("ShaderNodeMixRGB")
    mix.location = (50, 50)
    mix.blend_type = "MULTIPLY"
    mix.inputs["Fac"].default_value = 1.0

    links.new(tex_coord.outputs["Object"], mapping.inputs["Vector"])
    links.new(mapping.outputs["Vector"], noise.inputs["Vector"])
    links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    links.new(base.outputs["Color"], mix.inputs["Color1"])
    links.new(ramp.outputs["Color"], mix.inputs["Color2"])
    links.new(mix.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])

    mat.diffuse_color = (*color, 1.0)
    return mat


def add_box(name, size, location, material=None, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location, rotation=rotation)
    obj = bpy.context.active_object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if material:
        obj.data.materials.append(material)
    for p in obj.data.polygons:
        p.use_smooth = False
    return obj


def add_cylinder(name, radius, depth, location, material=None, vertices=6, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(
        radius=radius, depth=depth, location=location, rotation=rotation, vertices=vertices
    )
    obj = bpy.context.active_object
    obj.name = name
    if material:
        obj.data.materials.append(material)
    for p in obj.data.polygons:
        p.use_smooth = False
    return obj


def add_sphere(name, radius, location, material=None, segments=8, ring_count=6):
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=radius, location=location, segments=segments, ring_count=ring_count
    )
    obj = bpy.context.active_object
    obj.name = name
    if material:
        obj.data.materials.append(material)
    for p in obj.data.polygons:
        p.use_smooth = False
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
    bpy.ops.object.select_all(action="DESELECT")
    source_obj.select_set(True)
    bpy.context.view_layer.objects.active = source_obj
    bpy.ops.object.duplicate()
    outline = bpy.context.active_object
    outline.name = source_obj.name + "_Outline"
    solidify = outline.modifiers.new(name="OutlineSolidify", type="SOLIDIFY")
    solidify.thickness = thickness
    solidify.offset = 1.0
    solidify.use_flip_normals = True
    bpy.ops.object.modifier_apply(modifier=solidify.name)
    outline.data.materials.clear()
    outline.data.materials.append(material)
    outline.visible_shadow = False
    return outline


def build_simple_rig(height, hip_y, shoulder_y, torso_w, arm_len, leg_len, arm_r):
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
    add_bone("Head", (0, 0, shoulder_y + 0.12), (0, 0, height), neck)

    for side, x_sign in (("L", -1), ("R", 1)):
        sx = x_sign * (torso_w / 2 + arm_r * 0.5)
        upper = add_bone(f"UpperArm_{side}", (sx, 0, shoulder_y), (sx, 0, shoulder_y - arm_len * 0.5), chest)
        add_bone(f"LowerArm_{side}", (sx, 0, shoulder_y - arm_len * 0.5), (sx, 0, shoulder_y - arm_len), upper)
        lx = x_sign * torso_w * 0.22
        thigh = add_bone(f"Thigh_{side}", (lx, 0, hip_y), (lx, 0, hip_y - leg_len * 0.5), hips)
        add_bone(f"Shin_{side}", (lx, 0, hip_y - leg_len * 0.5), (lx, 0, 0.02), thigh)

    bpy.ops.object.mode_set(mode="OBJECT")
    return arm_obj


def parent_auto(mesh_obj, armature_obj):
    bpy.ops.object.select_all(action="DESELECT")
    mesh_obj.select_set(True)
    armature_obj.select_set(True)
    bpy.context.view_layer.objects.active = armature_obj
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")


def generate_wonder_walker(config=CONFIG):
    h = config["height_m"]
    head_size = h * 0.28
    torso_h = h * 0.30
    torso_w = h * 0.34
    torso_d = h * 0.20
    leg_len = h * 0.34
    leg_r = h * 0.075
    arm_len = h * 0.28
    arm_r = h * 0.055
    hip_y = leg_len
    shoulder_y = hip_y + torso_h

    mat_skin = make_paper_material("WW_Skin", config["skin_tone"], grain_scale=22)
    mat_hair = make_paper_material("WW_Hair", config["hair_color"], grain_scale=16)
    mat_outfit1 = make_paper_material("WW_Outfit_Primary", config["outfit_primary"], grain_scale=14)
    mat_outfit2 = make_paper_material("WW_Outfit_Secondary", config["outfit_secondary"], grain_scale=14)
    mat_shoe = make_paper_material("WW_Shoes", config["shoe_color"], grain_scale=12)
    mat_outline = make_paper_material("WW_Outline", config["outline_color"], roughness=1.0, grain_strength=0.0)
    mat_eye = make_paper_material("WW_Eyes", (0.08, 0.08, 0.10), roughness=0.4, grain_strength=0.0)

    parts = []
    for side, x in (("L", -torso_w * 0.22), ("R", torso_w * 0.22)):
        parts.append(add_cylinder(f"Leg_{side}", leg_r, leg_len, (x, 0, leg_len / 2), mat_outfit1, 6))
        parts.append(add_box(f"Foot_{side}", (leg_r * 2.4, leg_r * 3.2, leg_r * 1.2), (x, leg_r * 1.0, leg_r * 0.6), mat_shoe))

    parts.append(add_box("Torso", (torso_w, torso_d, torso_h), (0, 0, hip_y + torso_h / 2), mat_outfit1))
    parts.append(add_box("Sash", (torso_w * 1.02, torso_d * 1.05, torso_h * 0.18), (0, 0, hip_y + torso_h * 0.35), mat_outfit2))

    for side, x_sign in (("L", -1), ("R", 1)):
        x = x_sign * (torso_w / 2 + arm_r)
        parts.append(add_cylinder(f"Arm_{side}", arm_r, arm_len, (x, 0, shoulder_y - arm_len / 2), mat_skin, 6))
        parts.append(add_sphere(f"Hand_{side}", arm_r * 1.15, (x, 0, shoulder_y - arm_len), mat_skin, 6, 4))

    head_z = shoulder_y + head_size * 0.55
    parts.append(add_sphere("Head", head_size * 0.5, (0, 0, head_z), mat_skin, 8, 6))
    parts.append(add_box("Hair", (head_size * 0.95, head_size * 0.90, head_size * 0.55), (0, -head_size * 0.05, head_z + head_size * 0.22), mat_hair))
    for side, x in (("L", -head_size * 0.18), ("R", head_size * 0.18)):
        parts.append(add_sphere(f"Eye_{side}", head_size * 0.055, (x, head_size * 0.42, head_z + head_size * 0.02), mat_eye, 6, 4))

    body = join_objects(parts, "WonderWalker_Body")
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")

    outline = make_outline_shell(body, config["outline_thickness"], mat_outline)
    armature = build_simple_rig(h, hip_y, shoulder_y, torso_w, arm_len, leg_len, arm_r)
    parent_auto(body, armature)
    parent_auto(outline, armature)
    return armature, body, outline


def generate_valley(config=CONFIG):
    """Rough warm-gold paper valley + Wonder Items + distant Goliath silhouette."""
    mat_hill = make_paper_material("Valley_Hill", config["hill_color"], grain_scale=8, grain_strength=0.15)
    mat_ground = make_paper_material("Valley_Ground", config["ground_color"], grain_scale=10, grain_strength=0.14)
    mat_path = make_paper_material("Valley_Path", config["path_color"], grain_scale=12, grain_strength=0.1)
    mat_rock = make_paper_material("Valley_Rock", config["rock_color"], grain_scale=10)
    mat_wood = make_paper_material("Valley_Wood", (0.45, 0.30, 0.18), grain_scale=8)
    mat_lamb = make_paper_material("Valley_Lamb", (0.92, 0.90, 0.84), grain_scale=20)
    mat_sil = make_paper_material("Valley_Silhouette", config["silhouette_color"], roughness=1.0, grain_strength=0.0)
    mat_outline = make_paper_material("Valley_Outline", config["outline_color"], roughness=1.0, grain_strength=0.0)

    pieces = []
    # Ground plate
    pieces.append(add_box("Ground", (24, 18, 0.25), (0, 0, -0.12), mat_ground))
    # Soft paper hills (blocky)
    hills = [
        ("Hill_Near_L", (6, 5, 1.8), (-5, 3, 0.9)),
        ("Hill_Near_R", (5, 4.5, 1.4), (5.5, 2.5, 0.7)),
        ("Hill_Mid", (8, 6, 2.4), (0, 7, 1.2)),
        ("Hill_Far_L", (7, 5, 3.0), (-8, 11, 1.5)),
        ("Hill_Far_R", (9, 6, 3.5), (6, 12, 1.7)),
    ]
    for name, size, loc in hills:
        pieces.append(add_box(name, size, loc, mat_hill))

    # Path strip toward valley center
    pieces.append(add_box("Path", (2.2, 10, 0.08), (0, 2, 0.02), mat_path))

    # Wonder Items (simple readable placeholders)
    pieces.append(add_sphere("WonderItem_Stone", 0.18, (-2.5, 1.2, 0.22), mat_rock, 6, 4))
    pieces.append(add_cylinder("WonderItem_Staff", 0.05, 1.1, (2.8, 0.8, 0.55), mat_wood, 6))
    lamb_body = add_sphere("WonderItem_LambBody", 0.28, (-1.0, 3.5, 0.35), mat_lamb, 6, 4)
    lamb_head = add_sphere("WonderItem_LambHead", 0.16, (-1.0, 3.75, 0.55), mat_lamb, 6, 4)
    pieces.extend([lamb_body, lamb_head])

    # Distant Goliath silhouette on far ridge — flat thin block, never up close
    sil = add_box("Goliath_Silhouette", (1.6, 0.25, 3.2), (2.0, 14.5, 3.4), mat_sil)
    pieces.append(sil)

    # A few paper rocks
    for i, loc in enumerate([(-4, -1, 0.25), (3.5, 4, 0.3), (-6, 6, 0.4)]):
        pieces.append(add_box(f"Rock_{i}", (0.6, 0.5, 0.45), loc, mat_rock))

    valley = join_objects(pieces, "BethlehemValley_Placeholder")
    bpy.ops.object.select_all(action="DESELECT")
    valley.select_set(True)
    bpy.context.view_layer.objects.active = valley
    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")

    outline = make_outline_shell(valley, 0.04, mat_outline)
    return valley, outline


def export_glb(filepath, objects):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
        # also select children
        for child in obj.children_recursive:
            child.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(
        filepath=filepath,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
    )
    print(f"[LittleLight] Exported {filepath}")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    clear_scene()

    # --- Wonder-Walker ---
    arm, body, outline = generate_wonder_walker()
    export_glb(WW_GLB, [arm])

    # Clear and build valley alone so exports stay clean
    clear_scene()
    valley, v_outline = generate_valley()
    export_glb(VALLEY_GLB, [valley, v_outline])

    # Rebuild both into one .blend for hand polish
    clear_scene()
    arm, body, outline = generate_wonder_walker()
    # Offset WW to spawn on path
    arm.location = (0, 0, 0)
    valley, v_outline = generate_valley()
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)
    print(f"[LittleLight] Saved blend {BLEND}")
    print("[LittleLight] P0.1 paper-grain WW + valley placeholder done.")


if __name__ == "__main__":
    main()
