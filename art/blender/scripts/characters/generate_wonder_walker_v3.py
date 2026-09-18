"""
Wonder-Walker v3 — handmade papercraft silhouette pass.
More organic low-poly (not boxes), crease folds, asymmetry, grain + 12fps walk.
"""
import bpy

# --- Little Light path override (repo-friendly) ---
import os as _ll_os
from pathlib import Path as _ll_Path
_ll_root = _ll_Path(__file__).resolve().parents[2]  # art/blender
_ll_out = _ll_os.environ.get("LITTLE_LIGHT_ART_OUT", str(_ll_root / "output"))
# -------------------------------------------------
import bmesh
import math
import os
import random
from mathutils import Vector, Euler, Matrix

OUT = _ll_out
GRAIN = os.path.join(OUT, "paper_grain.png") if _ll_os.path.exists(os.path.join(OUT, "paper_grain.png")) else str(_ll_root / "assets" / "textures" / "paper_grain.png")
GLB = os.path.join(OUT, "wonder_walker_v3.glb")
BLEND = os.path.join(OUT, "wonder_walker_v3.blend")
PREVIEW = os.path.join(OUT, "previews", "wonder_walker_v3.png")

CFG = {
    "skin": (0.87, 0.67, 0.52),
    "hair": (0.20, 0.11, 0.08),
    "tunic": (0.80, 0.40, 0.24),
    "sash": (0.94, 0.88, 0.74),
    "shoe": (0.30, 0.18, 0.12),
    "eye": (0.06, 0.06, 0.08),
    "outline": (0.04, 0.04, 0.05),
    "h": 1.15,
    "outline_thick": 0.009,
}

rng = random.Random(7)


def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for bt in (bpy.data.meshes, bpy.data.materials, bpy.data.armatures, bpy.data.actions):
        for b in list(bt):
            if b.users == 0:
                bt.remove(b)


def flat(obj):
    for p in obj.data.polygons:
        p.use_smooth = False
    return obj


def uv(obj):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    if not obj.data.uv_layers:
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.03)
        bpy.ops.object.mode_set(mode="OBJECT")


def paper_mat(name, color, mix=0.4):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nodes, links = nt.nodes, nt.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.93
    bsdf.inputs["Metallic"].default_value = 0.0
    rgb = nodes.new("ShaderNodeRGB")
    rgb.outputs[0].default_value = (*color, 1.0)
    mixn = nodes.new("ShaderNodeMixRGB")
    mixn.blend_type = "MULTIPLY"
    mixn.inputs["Fac"].default_value = mix
    if os.path.exists(GRAIN):
        img = bpy.data.images.load(GRAIN)
        try:
            img.pack()
        except Exception:
            pass
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = img
        tex.interpolation = "Closest"
        tc = nodes.new("ShaderNodeTexCoord")
        mp = nodes.new("ShaderNodeMapping")
        mp.inputs["Scale"].default_value = (3.2, 3.2, 3.2)
        links.new(tc.outputs["UV"], mp.inputs["Vector"])
        links.new(mp.outputs["Vector"], tex.inputs["Vector"])
        links.new(tex.outputs["Color"], mixn.inputs["Color2"])
    else:
        mixn.inputs["Fac"].default_value = 0.0
        mixn.inputs["Color2"].default_value = (1, 1, 1, 1)
    links.new(rgb.outputs["Color"], mixn.inputs["Color1"])
    links.new(mixn.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mat.diffuse_color = (*color, 1.0)
    return mat


def jitter_verts(obj, amount=0.008):
    """Handmade paper unevenness."""
    mesh = obj.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    for v in bm.verts:
        v.co += Vector((rng.uniform(-amount, amount), rng.uniform(-amount, amount), rng.uniform(-amount * 0.5, amount * 0.5)))
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()


def crease_inset(obj, thickness=0.012):
    """Shallow inset faces for paper fold feel."""
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    try:
        bpy.ops.mesh.inset(thickness=thickness, depth=0.004)
    except Exception:
        pass
    bpy.ops.object.mode_set(mode="OBJECT")


def make_blob(name, loc, scale, mat, subdiv=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv, radius=1, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    # Light remesh-ish: decimate not needed; add slight cast
    jitter_verts(obj, 0.01)
    if mat:
        obj.data.materials.append(mat)
    uv(obj)
    return flat(obj)


def make_soft_blob(name, loc, scale, mat, subdiv=3, j=0.004):
    """Smooth-shaded, lightly-jittered blob for hands/feet.

    `make_blob` is flat-shaded to match the papercraft body, which is fine
    for a torso panel but makes hands/feet read as faceted paperweights.
    This keeps the same handmade wobble (tiny jitter) but shades the result
    smooth, so extremities look soft and rounded — more like a living hand
    or foot — against the flat-faceted body and limbs.
    """
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv, radius=1, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    jitter_verts(obj, j)
    if mat:
        obj.data.materials.append(mat)
    uv(obj)
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


def make_limb(name, loc, length, r0, r1, mat, axis="Z"):
    bpy.ops.mesh.primitive_cone_add(vertices=9, radius1=r0, radius2=r1, depth=length, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    jitter_verts(obj, 0.006)
    if mat:
        obj.data.materials.append(mat)
    uv(obj)
    return flat(obj)


def make_tunic(name, loc, size, mat):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(scale=True)
    # Bevel heavily for soft paper block
    bev = obj.modifiers.new("Bevel", "BEVEL")
    bev.width = min(size) * 0.14
    bev.segments = 3
    bpy.ops.object.modifier_apply(modifier=bev.name)
    # Subdivide once then jitter
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.subdivide(number_cuts=1)
    bpy.ops.object.mode_set(mode="OBJECT")
    crease_inset(obj, 0.015)
    jitter_verts(obj, 0.012)
    if mat:
        obj.data.materials.append(mat)
    uv(obj)
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


def outline(src, thick, mat):
    bpy.ops.object.select_all(action="DESELECT")
    src.select_set(True)
    bpy.context.view_layer.objects.active = src
    bpy.ops.object.duplicate()
    o = bpy.context.active_object
    o.name = src.name + "_Outline"
    m = o.modifiers.new("OL", "SOLIDIFY")
    m.thickness = thick
    m.offset = 1.0
    m.use_flip_normals = True
    bpy.ops.object.modifier_apply(modifier=m.name)
    o.data.materials.clear()
    o.data.materials.append(mat)
    o.visible_shadow = False
    return o


def build():
    h = CFG["h"]
    skin = paper_mat("Skin", CFG["skin"], 0.28)
    hair = paper_mat("Hair", CFG["hair"], 0.45)
    tunic = paper_mat("Tunic", CFG["tunic"], 0.42)
    sash = paper_mat("Sash", CFG["sash"], 0.35)
    shoe = paper_mat("Shoe", CFG["shoe"], 0.4)
    eye = paper_mat("Eye", CFG["eye"], 0.0)
    olmat = paper_mat("OL", CFG["outline"], 0.0)

    torso_h = h * 0.30
    torso_w = h * 0.32
    torso_d = h * 0.20
    leg_len = h * 0.33
    arm_len = h * 0.27
    hip_y = leg_len
    shoulder_y = hip_y + torso_h
    head_r = h * 0.15

    parts = []
    # Legs
    for side, x in (("L", -torso_w * 0.18), ("R", torso_w * 0.18)):
        parts.append(make_limb(f"Leg_{side}", (x, 0, leg_len / 2), leg_len, h * 0.072, h * 0.05, tunic))
        foot = make_soft_blob(f"Foot_{side}", (x, h * 0.06, h * 0.05), (h * 0.10, h * 0.14, h * 0.05), shoe)
        parts.append(foot)

    parts.append(make_tunic("Torso", (0, 0, hip_y + torso_h / 2), (torso_w, torso_d, torso_h), tunic))
    # Sash band
    sash_o = make_tunic("Sash", (0, 0, hip_y + torso_h * 0.30), (torso_w * 1.08, torso_d * 1.1, torso_h * 0.14), sash)
    parts.append(sash_o)

    # Arms
    for side, xs in (("L", -1), ("R", 1)):
        x = xs * (torso_w * 0.55)
        parts.append(make_limb(f"Arm_{side}", (x, 0.02 * xs, shoulder_y - arm_len / 2), arm_len, h * 0.05, h * 0.038, skin))
        parts.append(make_soft_blob(f"Hand_{side}", (x, 0.02 * xs, shoulder_y - arm_len), (h * 0.06, h * 0.058, h * 0.06), skin))

    # Head cluster
    head_z = shoulder_y + head_r * 0.95
    parts.append(make_soft_blob("Head", (0, 0, head_z), (head_r, head_r * 0.92, head_r * 1.05), skin, 3, 0.003))
    # Asymmetric hair clumps (papercraft layered paper)
    for i, (off, sc) in enumerate([
        ((0.02, -0.04, head_r * 0.35), (head_r * 1.05, head_r * 0.95, head_r * 0.55)),
        ((-0.06, 0.02, head_r * 0.25), (head_r * 0.55, head_r * 0.5, head_r * 0.4)),
        ((0.08, 0.0, head_r * 0.2), (head_r * 0.45, head_r * 0.4, head_r * 0.35)),
    ]):
        parts.append(make_soft_blob(f"Hair_{i}", (off[0], off[1], head_z + off[2]), sc, hair, 3, 0.003))

    for side, xs in (("L", -1), ("R", 1)):
        parts.append(make_soft_blob(f"Cheek_{side}", (xs * head_r * 0.7, head_r * 0.2, head_z - head_r * 0.15), (head_r * 0.28,) * 3, skin, 2, 0.002))
        parts.append(make_blob(f"Eye_{side}", (xs * head_r * 0.32, head_r * 0.75, head_z + head_r * 0.02), (head_r * 0.11,) * 3, eye, 1))

    body = join(parts, "WonderWalker_Body")
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    ol = outline(body, CFG["outline_thick"], olmat)
    return body, ol, hip_y, shoulder_y, h, arm_len, leg_len, torso_w


def build_rig(h, hip_y, shoulder_y, torso_w, arm_len, leg_len):
    data = bpy.data.armatures.new("WW_Armature")
    arm = bpy.data.objects.new("WW_Armature", data)
    bpy.context.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    eb = data.edit_bones

    def bone(n, a, b, p=None):
        x = eb.new(n)
        x.head, x.tail = a, b
        if p:
            x.parent = p
            x.use_connect = False
        return x

    root = bone("Root", (0, 0, 0), (0, 0, 0.08))
    hips = bone("Hips", (0, 0, hip_y), (0, 0, hip_y + 0.06), root)
    spine = bone("Spine", (0, 0, hip_y + 0.06), (0, 0, shoulder_y - 0.05), hips)
    chest = bone("Chest", (0, 0, shoulder_y - 0.05), (0, 0, shoulder_y + 0.04), spine)
    neck = bone("Neck", (0, 0, shoulder_y + 0.04), (0, 0, shoulder_y + 0.12), chest)
    bone("Head", (0, 0, shoulder_y + 0.12), (0, 0, h), neck)
    for side, xs in (("L", -1), ("R", 1)):
        sx = xs * (torso_w / 2 + 0.02)
        ua = bone(f"UpperArm_{side}", (sx, 0, shoulder_y), (sx, 0, shoulder_y - arm_len * 0.5), chest)
        bone(f"LowerArm_{side}", (sx, 0, shoulder_y - arm_len * 0.5), (sx, 0, shoulder_y - arm_len), ua)
        lx = xs * torso_w * 0.18
        th = bone(f"Thigh_{side}", (lx, 0, hip_y), (lx, 0, hip_y - leg_len * 0.5), hips)
        bone(f"Shin_{side}", (lx, 0, hip_y - leg_len * 0.5), (lx, 0, 0.03), th)
    bpy.ops.object.mode_set(mode="OBJECT")
    return arm


def parent_auto(mesh, arm):
    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")


def walk(arm, fps=12, frames=12):
    scene = bpy.context.scene
    scene.render.fps = fps
    scene.frame_start = 1
    scene.frame_end = frames
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

    def rot(n, f, e):
        b = pb.get(n)
        if not b:
            return
        b.rotation_mode = "XYZ"
        b.rotation_euler = Euler(tuple(math.radians(a) for a in e))
        b.keyframe_insert("rotation_euler", frame=f)

    def loc(n, f, l):
        b = pb.get(n)
        if not b:
            return
        b.location = l
        b.keyframe_insert("location", frame=f)

    keys = [
        (1, (28, 0, 0), (8, 0, 0), (-22, 0, 0), (18, 0, 0), (-18, 0, 0), (20, 0, 0), 0.0),
        (4, (8, 0, 0), (2, 0, 0), (-8, 0, 0), (6, 0, 0), (-6, 0, 0), (8, 0, 0), 0.025),
        (7, (-22, 0, 0), (18, 0, 0), (28, 0, 0), (8, 0, 0), (20, 0, 0), (-18, 0, 0), 0.0),
        (10, (-8, 0, 0), (6, 0, 0), (8, 0, 0), (2, 0, 0), (8, 0, 0), (-6, 0, 0), 0.025),
    ]
    for fr, tl, sl, tr, sr, al, ar, bob in keys:
        rot("Thigh_L", fr, tl); rot("Shin_L", fr, sl)
        rot("Thigh_R", fr, tr); rot("Shin_R", fr, sr)
        rot("UpperArm_L", fr, al); rot("UpperArm_R", fr, ar)
        loc("Hips", fr, (0, 0, bob))
        rot("Chest", fr, (0, 0, 4 if fr in (1, 7) else -3))
    bpy.ops.object.mode_set(mode="OBJECT")


def export(arm, path):
    bpy.ops.object.select_all(action="DESELECT")
    arm.select_set(True)
    for c in arm.children_recursive:
        c.select_set(True)
    bpy.context.view_layer.objects.active = arm
    kwargs = dict(filepath=path, export_format="GLB", use_selection=True, export_apply=True,
                  export_yup=True, export_animations=True, export_force_sampling=True)
    try:
        bpy.ops.export_scene.gltf(**kwargs, export_sampling_interpolation_fallback="STEP")
    except TypeError:
        bpy.ops.export_scene.gltf(**kwargs)
    print("exported", path)


def preview(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    for o in bpy.context.scene.objects:
        if "Outline" in o.name:
            o.hide_render = True
    for o in list(bpy.data.objects):
        if o.type == "LIGHT":
            bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.object.light_add(type="SUN", location=(5, -4, 10))
    bpy.context.active_object.data.energy = 5
    bpy.context.active_object.rotation_euler = Euler((0.7, 0.2, 0.3))
    bpy.ops.object.light_add(type="AREA", location=(-3, 3, 4))
    bpy.context.active_object.data.energy = 120
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH" and not o.hide_render]
    min_c = Vector((1e9,) * 3); max_c = Vector((-1e9,) * 3)
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
    bpy.ops.object.camera_add(location=(center.x + size * 1.8, center.y - size * 2.3, center.z + size * 1.0))
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
    s.frame_set(1)
    s.render.filepath = path
    bpy.ops.render.render(write_still=True)
    s.frame_set(7)
    s.render.filepath = path.replace(".png", "_walk.png")
    bpy.ops.render.render(write_still=True)
    print("preview ok")


def main():
    clear()
    body, ol, hip_y, shoulder_y, h, arm_len, leg_len, torso_w = build()
    arm = build_rig(h, hip_y, shoulder_y, torso_w, arm_len, leg_len)
    parent_auto(body, arm)
    parent_auto(ol, arm)
    walk(arm)
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)
    export(arm, GLB)
    preview(PREVIEW)
    print("v3 done")


if __name__ == "__main__":
    main()
