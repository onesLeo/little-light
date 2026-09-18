"""
Little Light — Wonder-Walker v2 polish pass
Softer DOGWALK-inspired low-poly silhouette, exportable paper-grain,
simple ~12fps stop-motion walk cycle. Blender 4.x / 5.x.
"""
import bpy

# --- Little Light path override (repo-friendly) ---
import os as _ll_os
from pathlib import Path as _ll_Path
_ll_root = _ll_Path(__file__).resolve().parents[2]  # art/blender
_ll_out = _ll_os.environ.get("LITTLE_LIGHT_ART_OUT", str(_ll_root / "output"))
# -------------------------------------------------
import math
import os
from mathutils import Vector, Euler

OUT = _ll_out
GRAIN = os.path.join(OUT, "paper_grain.png") if _ll_os.path.exists(os.path.join(OUT, "paper_grain.png")) else str(_ll_root / "assets" / "textures" / "paper_grain.png")
GLB = os.path.join(OUT, "wonder_walker_v2.glb")
BLEND = os.path.join(OUT, "wonder_walker_v2.blend")
PREVIEW = os.path.join(OUT, "previews", "wonder_walker_v2.png")

CONFIG = {
    "skin_tone": (0.86, 0.66, 0.50),
    "hair_color": (0.22, 0.13, 0.09),
    "outfit_primary": (0.78, 0.38, 0.22),
    "outfit_secondary": (0.93, 0.86, 0.72),
    "shoe_color": (0.32, 0.20, 0.14),
    "outline_color": (0.04, 0.04, 0.05),
    "height_m": 1.15,
    "outline_thickness": 0.010,
}


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for bt in (bpy.data.meshes, bpy.data.materials, bpy.data.armatures, bpy.data.actions, bpy.data.images):
        for b in list(bt):
            if getattr(b, "users", 1) == 0:
                bt.remove(b)


def flat(obj):
    for p in obj.data.polygons:
        p.use_smooth = False
    return obj


def ensure_uv(obj):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    if not obj.data.uv_layers:
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02)
        bpy.ops.object.mode_set(mode="OBJECT")


def make_paper_mat(name, color, grain_path=GRAIN, grain_mix=0.35):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nodes, links = nt.nodes, nt.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    out.location = (700, 0)
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (450, 0)
    bsdf.inputs["Roughness"].default_value = 0.92
    bsdf.inputs["Metallic"].default_value = 0.0
    base = nodes.new("ShaderNodeRGB")
    base.location = (-200, 120)
    base.outputs[0].default_value = (*color, 1.0)

    mix = nodes.new("ShaderNodeMixRGB")
    mix.location = (200, 40)
    mix.blend_type = "MULTIPLY"
    mix.inputs["Fac"].default_value = grain_mix

    if grain_path and os.path.exists(grain_path):
        img = bpy.data.images.load(grain_path)
        img.pack()
        tex = nodes.new("ShaderNodeTexImage")
        tex.location = (-200, -120)
        tex.image = img
        tex.interpolation = "Closest"  # keep papercraft crispy
        uv = nodes.new("ShaderNodeTexCoord")
        uv.location = (-500, -120)
        mapping = nodes.new("ShaderNodeMapping")
        mapping.location = (-350, -120)
        mapping.inputs["Scale"].default_value = (2.5, 2.5, 2.5)
        links.new(uv.outputs["UV"], mapping.inputs["Vector"])
        links.new(mapping.outputs["Vector"], tex.inputs["Vector"])
        links.new(tex.outputs["Color"], mix.inputs["Color2"])
    else:
        mix.inputs["Color2"].default_value = (1, 1, 1, 1)
        mix.inputs["Fac"].default_value = 0.0

    links.new(base.outputs["Color"], mix.inputs["Color1"])
    links.new(mix.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mat.diffuse_color = (*color, 1.0)
    return mat


def add_rounded_box(name, size, loc, mat, segments=2):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(scale=True)
    # Soften edges with bevel (still low-poly)
    bevel = obj.modifiers.new("Bevel", "BEVEL")
    bevel.width = min(size) * 0.08
    bevel.segments = segments
    bevel.limit_method = "ANGLE"
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    if mat:
        obj.data.materials.append(mat)
    ensure_uv(obj)
    return flat(obj)


def add_sphere(name, radius, loc, mat, segments=10, rings=8, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=loc, segments=segments, ring_count=rings)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    if mat:
        obj.data.materials.append(mat)
    ensure_uv(obj)
    return flat(obj)


def add_taper_cyl(name, r_top, r_bot, depth, loc, mat, verts=8):
    bpy.ops.mesh.primitive_cone_add(
        radius1=r_bot, radius2=r_top, depth=depth, location=loc, vertices=verts
    )
    obj = bpy.context.active_object
    obj.name = name
    if mat:
        obj.data.materials.append(mat)
    ensure_uv(obj)
    return flat(obj)


def join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    j = bpy.context.active_object
    j.name = name
    return j


def outline_shell(src, thick, mat):
    bpy.ops.object.select_all(action="DESELECT")
    src.select_set(True)
    bpy.context.view_layer.objects.active = src
    bpy.ops.object.duplicate()
    o = bpy.context.active_object
    o.name = src.name + "_Outline"
    m = o.modifiers.new("OutlineSolidify", "SOLIDIFY")
    m.thickness = thick
    m.offset = 1.0
    m.use_flip_normals = True
    bpy.ops.object.modifier_apply(modifier=m.name)
    o.data.materials.clear()
    o.data.materials.append(mat)
    o.visible_shadow = False
    return o


def build_mesh(cfg):
    h = cfg["height_m"]
    head_r = h * 0.145
    torso_h = h * 0.28
    torso_w = h * 0.30
    torso_d = h * 0.18
    leg_len = h * 0.34
    arm_len = h * 0.26
    hip_y = leg_len
    shoulder_y = hip_y + torso_h

    mat_skin = make_paper_mat("WW_Skin", cfg["skin_tone"], grain_mix=0.28)
    mat_hair = make_paper_mat("WW_Hair", cfg["hair_color"], grain_mix=0.4)
    mat_out1 = make_paper_mat("WW_Outfit1", cfg["outfit_primary"], grain_mix=0.38)
    mat_out2 = make_paper_mat("WW_Outfit2", cfg["outfit_secondary"], grain_mix=0.32)
    mat_shoe = make_paper_mat("WW_Shoe", cfg["shoe_color"], grain_mix=0.35)
    mat_eye = make_paper_mat("WW_Eye", (0.07, 0.07, 0.09), grain_mix=0.0)
    mat_ol = make_paper_mat("WW_Outline", cfg["outline_color"], grain_mix=0.0)

    parts = []
    # Legs — soft tapered cylinders, not boxes
    for side, x in (("L", -torso_w * 0.20), ("R", torso_w * 0.20)):
        parts.append(add_taper_cyl(f"Leg_{side}", h * 0.055, h * 0.07, leg_len, (x, 0, leg_len / 2), mat_out1, 8))
        foot = add_rounded_box(f"Foot_{side}", (h * 0.12, h * 0.18, h * 0.07), (x, h * 0.04, h * 0.04), mat_shoe, 2)
        parts.append(foot)

    # Torso — beveled soft block (papercraft tunic)
    parts.append(add_rounded_box("Torso", (torso_w, torso_d, torso_h), (0, 0, hip_y + torso_h / 2), mat_out1, 3))
    parts.append(add_rounded_box("Sash", (torso_w * 1.05, torso_d * 1.08, torso_h * 0.16), (0, 0, hip_y + torso_h * 0.32), mat_out2, 2))

    # Arms — tapered, skin tone
    for side, xs in (("L", -1), ("R", 1)):
        x = xs * (torso_w / 2 + h * 0.04)
        parts.append(add_taper_cyl(f"Arm_{side}", h * 0.04, h * 0.05, arm_len, (x, 0, shoulder_y - arm_len / 2), mat_skin, 8))
        parts.append(add_sphere(f"Hand_{side}", h * 0.055, (x, 0, shoulder_y - arm_len), mat_skin, 8, 6))

    # Head — softer sphere, slight squash (child)
    head_z = shoulder_y + head_r * 1.05
    parts.append(add_sphere("Head", head_r, (0, 0, head_z), mat_skin, 12, 10, scale=(1.0, 0.95, 1.05)))
    # Hair cap — slightly asymmetric for handmade feel
    hair = add_rounded_box("Hair", (head_r * 1.85, head_r * 1.7, head_r * 0.95), (0.02, -0.03, head_z + head_r * 0.35), mat_hair, 2)
    parts.append(hair)
    # Eyes
    for side, x in (("L", -head_r * 0.35), ("R", head_r * 0.35)):
        parts.append(add_sphere(f"Eye_{side}", head_r * 0.12, (x, head_r * 0.78, head_z + head_r * 0.05), mat_eye, 8, 6))

    # Soft cheeks / ear nubs for silhouette interest
    for side, xs in (("L", -1), ("R", 1)):
        parts.append(add_sphere(f"Cheek_{side}", head_r * 0.22, (xs * head_r * 0.75, head_r * 0.15, head_z - head_r * 0.1), mat_skin, 8, 6))

    body = join(parts, "WonderWalker_Body")
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")

    ol = outline_shell(body, cfg["outline_thickness"], mat_ol)
    return body, ol, hip_y, shoulder_y, h, arm_len, leg_len, torso_w


def build_rig(h, hip_y, shoulder_y, torso_w, arm_len, leg_len):
    data = bpy.data.armatures.new("WW_Armature")
    arm = bpy.data.objects.new("WW_Armature", data)
    bpy.context.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    bones = data.edit_bones

    def b(name, head, tip, parent=None):
        bone = bones.new(name)
        bone.head = head
        bone.tail = tip
        if parent:
            bone.parent = parent
            bone.use_connect = False
        return bone

    root = b("Root", (0, 0, 0), (0, 0, 0.08))
    hips = b("Hips", (0, 0, hip_y), (0, 0, hip_y + 0.06), root)
    spine = b("Spine", (0, 0, hip_y + 0.06), (0, 0, shoulder_y - 0.05), hips)
    chest = b("Chest", (0, 0, shoulder_y - 0.05), (0, 0, shoulder_y + 0.04), spine)
    neck = b("Neck", (0, 0, shoulder_y + 0.04), (0, 0, shoulder_y + 0.12), chest)
    b("Head", (0, 0, shoulder_y + 0.12), (0, 0, h), neck)

    for side, xs in (("L", -1), ("R", 1)):
        sx = xs * (torso_w / 2 + 0.02)
        ua = b(f"UpperArm_{side}", (sx, 0, shoulder_y), (sx, 0, shoulder_y - arm_len * 0.5), chest)
        b(f"LowerArm_{side}", (sx, 0, shoulder_y - arm_len * 0.5), (sx, 0, shoulder_y - arm_len), ua)
        lx = xs * torso_w * 0.20
        th = b(f"Thigh_{side}", (lx, 0, hip_y), (lx, 0, hip_y - leg_len * 0.5), hips)
        b(f"Shin_{side}", (lx, 0, hip_y - leg_len * 0.5), (lx, 0, 0.03), th)

    bpy.ops.object.mode_set(mode="OBJECT")
    return arm


def parent_auto(mesh, arm):
    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")


def _iter_action_fcurves(action):
    """Blender 5 layered actions + legacy fcurves."""
    if hasattr(action, "fcurves") and action.fcurves:
        for fc in action.fcurves:
            yield fc
        return
    # Blender 5.0+ layered Action API
    try:
        for layer in action.layers:
            for strip in layer.strips:
                channelbag = strip.channelbag(action.slots[0]) if action.slots else None
                if channelbag is None:
                    # try without slot
                    try:
                        channelbag = strip.channelbags[0]
                    except Exception:
                        channelbag = None
                if channelbag is None:
                    continue
                for fc in channelbag.fcurves:
                    yield fc
    except Exception as e:
        print("[WW v2] fcurve iter fallback:", e)


def make_walk_cycle(arm, fps=12, frames=12):
    """Simple in-place walk. Pose holds every frame = stop-motion on 12fps."""
    scene = bpy.context.scene
    scene.render.fps = fps
    scene.frame_start = 1
    scene.frame_end = frames
    scene.frame_current = 1

    # Force CONSTANT (step) keys for stop-motion look — works across Blender 5
    try:
        bpy.context.preferences.edit.keyframe_new_interpolation_type = "CONSTANT"
    except Exception:
        pass

    arm.animation_data_create()
    action = bpy.data.actions.new("WW_Walk")
    arm.animation_data.action = action

    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    pb = arm.pose.bones

    def set_rot(bone_name, frame, euler_deg):
        bone = pb.get(bone_name)
        if not bone:
            return
        bone.rotation_mode = "XYZ"
        bone.rotation_euler = Euler(tuple(math.radians(a) for a in euler_deg))
        bone.keyframe_insert(data_path="rotation_euler", frame=frame)

    def set_loc(bone_name, frame, loc):
        bone = pb.get(bone_name)
        if not bone:
            return
        bone.location = loc
        bone.keyframe_insert(data_path="location", frame=frame)

    # 12-frame loop: L forward / R back, then swap
    # frames 1,4,7,10 key poses; constants hold between
    poses = [
        # frame, thighL, shinL, thighR, shinR, armL, armR, hips_bob_z
        (1,  (25, 0, 0), (5, 0, 0), (-20, 0, 0), (15, 0, 0), (-15, 0, 0), (18, 0, 0), 0.0),
        (4,  (5, 0, 0),  (0, 0, 0), (-5, 0, 0),  (5, 0, 0),  (-5, 0, 0),  (5, 0, 0), 0.02),
        (7,  (-20, 0, 0), (15, 0, 0), (25, 0, 0), (5, 0, 0), (18, 0, 0), (-15, 0, 0), 0.0),
        (10, (-5, 0, 0), (5, 0, 0), (5, 0, 0), (0, 0, 0), (5, 0, 0), (-5, 0, 0), 0.02),
        (13, (25, 0, 0), (5, 0, 0), (-20, 0, 0), (15, 0, 0), (-15, 0, 0), (18, 0, 0), 0.0),  # loop
    ]
    for fr, tl, sl, tr, sr, al, ar, bob in poses:
        f = fr if fr <= frames else 1  # loop key on frame 1 already; skip 13 write as frame 1 duplicate
        if fr == 13:
            continue
        set_rot("Thigh_L", fr, tl)
        set_rot("Shin_L", fr, sl)
        set_rot("Thigh_R", fr, tr)
        set_rot("Shin_R", fr, sr)
        set_rot("UpperArm_L", fr, al)
        set_rot("UpperArm_R", fr, ar)
        set_loc("Hips", fr, (0, 0, bob))
        set_rot("Hips", fr, (0, 0, 3 if fr in (1, 7) else -2))

    # Force step/constant interpolation on all keyed curves (Blender 5 safe)
    for fc in _iter_action_fcurves(action):
        for kp in fc.keyframe_points:
            kp.interpolation = "CONSTANT"

    scene.frame_end = frames
    bpy.ops.object.mode_set(mode="OBJECT")
    return action


def export_glb(path, arm):
    bpy.ops.object.select_all(action="DESELECT")
    arm.select_set(True)
    for c in arm.children_recursive:
        c.select_set(True)
    bpy.context.view_layer.objects.active = arm
    # Blender 5 glTF: force step sampling for held poses
    kwargs = dict(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_nla_strips=False,
        export_force_sampling=True,
        export_frame_step=1,
        export_optimize_animation_size=False,
    )
    # Sampling interpolation fallback = STEP if available
    try:
        bpy.ops.export_scene.gltf(**kwargs, export_sampling_interpolation_fallback="STEP")
    except TypeError:
        try:
            bpy.ops.export_scene.gltf(**kwargs)
        except TypeError:
            # older signature
            bpy.ops.export_scene.gltf(
                filepath=path,
                export_format="GLB",
                use_selection=True,
                export_apply=True,
                export_yup=True,
                export_animations=True,
            )
    print("[WW v2] exported", path)


def render_preview(arm, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    # Hide outline for readable color preview
    for o in bpy.context.scene.objects:
        if "Outline" in o.name:
            o.hide_render = True
    # Simplify materials to flat for EEVEE reliability but keep RGB
    for mat in bpy.data.materials:
        if not mat.use_nodes:
            continue
        rgb = mat.diffuse_color[:3]
        for n in mat.node_tree.nodes:
            if n.type == "RGB":
                rgb = n.outputs[0].default_value[:3]
                break
        # keep textured mats as-is for preview
    for o in list(bpy.data.objects):
        if o.type == "LIGHT":
            bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.object.light_add(type="SUN", location=(4, -3, 9))
    bpy.context.active_object.data.energy = 4.5
    bpy.context.active_object.rotation_euler = Euler((0.7, 0.2, 0.3))
    bpy.ops.object.light_add(type="AREA", location=(-3, 2, 4))
    bpy.context.active_object.data.energy = 100
    bpy.context.active_object.data.size = 5

    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH" and not o.hide_render]
    min_c = Vector((1e9, 1e9, 1e9))
    max_c = Vector((-1e9, -1e9, -1e9))
    for obj in meshes:
        for corner in obj.bound_box:
            w = obj.matrix_world @ Vector(corner)
            min_c = Vector(tuple(min(min_c[i], w[i]) for i in range(3)))
            max_c = Vector(tuple(max(max_c[i], w[i]) for i in range(3)))
    center = (min_c + max_c) * 0.5
    size = max((max_c - min_c).length, 0.5)
    for o in list(bpy.data.objects):
        if o.type == "CAMERA":
            bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.object.camera_add(location=(center.x + size * 1.9, center.y - size * 2.4, center.z + size * 1.0))
    cam = bpy.context.active_object
    bpy.context.scene.camera = cam
    cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()

    s = bpy.context.scene
    for eng in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
        try:
            s.render.engine = eng
            break
        except Exception:
            pass
    s.render.resolution_x = 1280
    s.render.resolution_y = 960
    s.render.filepath = path
    s.frame_set(1)
    bpy.ops.render.render(write_still=True)
    # also mid-walk pose
    mid = path.replace(".png", "_walk.png")
    s.frame_set(4)
    s.render.filepath = mid
    bpy.ops.render.render(write_still=True)
    print("[WW v2] previews", path, mid)


def main():
    os.makedirs(OUT, exist_ok=True)
    # grain should already be copied beside script
    clear_scene()
    body, ol, hip_y, shoulder_y, h, arm_len, leg_len, torso_w = build_mesh(CONFIG)
    arm = build_rig(h, hip_y, shoulder_y, torso_w, arm_len, leg_len)
    parent_auto(body, arm)
    parent_auto(ol, arm)
    make_walk_cycle(arm, fps=12, frames=12)
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)
    export_glb(GLB, arm)
    render_preview(arm, PREVIEW)
    print("[WW v2] done")


if __name__ == "__main__":
    main()
