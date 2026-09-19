"""
Wonder-Walker v4 — rounder, more human silhouette + DOGWALK-style single pass.

Builds on v3 (same rig/walk-cycle layout, same head/hair arrangement, which
already reads fine) but:
  - Torso is a tapered, beveled cylinder instead of a beveled cube, so the
    body reads as a soft rounded human shape rather than "blocks stacked
    together".
  - Materials bake color+grain into a texture directly (matches
    recolor_characters_v3.py's technique) instead of an RGB+MixRGB node
    graph, which Blender's glTF exporter does not export faithfully.
  - Outline hull is single-skin from the start (grow along normal + flip
    winding), not a Solidify shell needing a later fix_outlines_v6.py pass.

Blender 4.x / 5.x.
"""
import bpy

import os as _ll_os
from pathlib import Path as _ll_Path
_ll_root = _ll_Path(__file__).resolve().parents[2]  # art/blender
_ll_out = _ll_os.environ.get("LITTLE_LIGHT_ART_OUT", str(_ll_root / "output"))

import bmesh
import math
import numpy as np
import os
import random
from mathutils import Vector, Euler

OUT = _ll_out
GRAIN = os.path.join(OUT, "paper_grain.png") if _ll_os.path.exists(os.path.join(OUT, "paper_grain.png")) else str(_ll_root / "assets" / "textures" / "paper_grain.png")
GLB = os.path.join(OUT, "wonder_walker_v12.glb")
BLEND = os.path.join(OUT, "wonder_walker_v12.blend")
PREVIEW = os.path.join(OUT, "previews", "wonder_walker_v12.png")

CFG = {
    "skin": (0.90, 0.70, 0.54),
    "hair": (0.22, 0.13, 0.09),
    "tunic": (0.35, 0.55, 0.85),
    "sash": (0.95, 0.40, 0.38),
    "shoe": (0.34, 0.22, 0.14),
    "eye": (0.07, 0.07, 0.09),
    "mouth": (0.75, 0.35, 0.38),
    "outline": (0.06, 0.05, 0.05),
    "h": 1.15,
    "outline_thick": 0.010,
}

rng = random.Random(19)


def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for bt in (bpy.data.meshes, bpy.data.materials, bpy.data.images, bpy.data.armatures, bpy.data.actions):
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


def jitter_verts(obj, amount=0.008):
    mesh = obj.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    for v in bm.verts:
        v.co += Vector((rng.uniform(-amount, amount), rng.uniform(-amount, amount), rng.uniform(-amount * 0.5, amount * 0.5)))
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()


def _tinted_grain_image(name, color, mix_fac):
    """Bake color x grain into pixels — see courage_charm's version of this
    for why (Blender's glTF exporter drops an RGB+MixRGB node graph)."""
    size = 256
    if os.path.exists(GRAIN):
        src = bpy.data.images.load(GRAIN)
        src.scale(size, size)
        pix = np.array(src.pixels[:], dtype=np.float32).reshape(size, size, 4)
        g = pix[:, :, :3]
        g_mean = float(g.mean()) + 1e-6
        g = np.clip(g / g_mean * 0.85, 0.55, 1.0)
    else:
        g = np.ones((size, size, 3), dtype=np.float32)
    grain = g * mix_fac + (1.0 - mix_fac)
    tint = np.array(color[:3], dtype=np.float32).reshape(1, 1, 3)
    rgb = np.clip(grain * tint * 1.06, 0.0, 1.0)
    alpha = np.ones((size, size, 1), dtype=np.float32)
    out = np.concatenate([rgb, alpha], axis=2).reshape(-1)
    img = bpy.data.images.new(f"Tint_{name}", width=size, height=size, alpha=True)
    img.pixels = out.tolist()
    img.pack()
    return img


def paper_mat(name, color, mix=0.35, roughness=0.9):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nodes, links = nt.nodes, nt.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = _tinted_grain_image(name, color, mix)
    tex.interpolation = "Closest"
    tc = nodes.new("ShaderNodeTexCoord")
    mp = nodes.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (3.2, 3.2, 3.2)
    links.new(tc.outputs["UV"], mp.inputs["Vector"])
    links.new(mp.outputs["Vector"], tex.inputs["Vector"])
    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mat.diffuse_color = (*color, 1.0)
    return mat


def make_blob(name, loc, scale, mat, subdiv=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv, radius=1, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    jitter_verts(obj, 0.01)
    if mat:
        obj.data.materials.append(mat)
    uv(obj)
    return flat(obj)


def make_soft_blob(name, loc, scale, mat, subdiv=3, j=0.004):
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


def make_limb(name, loc, length, r0, r1, mat, axis="Z", verts=10):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r0, radius2=r1, depth=length, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    jitter_verts(obj, 0.006)
    if mat:
        obj.data.materials.append(mat)
    uv(obj)
    return flat(obj)


def make_torso(name, loc, height, r_bottom, r_top, mat, sides=10, bevel_w=0.018, j=0.010):
    """A tapered, beveled cylinder torso — rounder and more human than a
    beveled cube (DOGWALK's people read as soft capsule-ish shapes, not
    blocks). Wider at the shoulders, narrower at the hips.
    """
    bpy.ops.mesh.primitive_cone_add(vertices=sides, radius1=r_bottom, radius2=r_top, depth=height, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    bev = obj.modifiers.new("Bevel", "BEVEL")
    bev.width = bevel_w
    bev.segments = 2
    bpy.ops.object.modifier_apply(modifier=bev.name)
    jitter_verts(obj, j)
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


def outline_material(color):
    mat = bpy.data.materials.get("WW_OutlineInk")
    if mat:
        return mat
    mat = paper_mat("WW_OutlineInk", color, 0.0, roughness=1.0)
    mat.use_backface_culling = True
    return mat


def single_skin_outline(base, thickness, color):
    hull = base.copy()
    hull.data = base.data.copy()
    hull.name = base.name + "_Outline"
    bpy.context.collection.objects.link(hull)
    bm = bmesh.new()
    bm.from_mesh(hull.data)
    bm.normal_update()
    for v in bm.verts:
        v.co += v.normal * thickness
    for f in bm.faces:
        f.normal_flip()
    bm.to_mesh(hull.data)
    bm.free()
    hull.data.materials.clear()
    hull.data.materials.append(outline_material(color))
    for p in hull.data.polygons:
        p.use_smooth = False
    return hull


def build():
    h = CFG["h"]
    skin = paper_mat("WW_Skin", CFG["skin"], 0.24)
    hair = paper_mat("WW_Hair", CFG["hair"], 0.4)
    tunic = paper_mat("WW_Tunic", CFG["tunic"], 0.3)
    sash = paper_mat("WW_Sash", CFG["sash"], 0.3)
    shoe = paper_mat("WW_Shoe", CFG["shoe"], 0.35)
    eye = paper_mat("WW_Eye", CFG["eye"], 0.0)
    mouth = paper_mat("WW_Mouth", CFG["mouth"], 0.0)

    torso_h = h * 0.30
    hip_r = h * 0.135
    shoulder_r = h * 0.165
    leg_len = h * 0.33
    arm_len = h * 0.27
    hip_y = leg_len
    shoulder_y = hip_y + torso_h
    head_r = h * 0.15

    parts = []
    for side, x in (("L", -hip_r * 0.62), ("R", hip_r * 0.62)):
        parts.append(make_limb(f"Leg_{side}", (x, 0, leg_len / 2), leg_len, h * 0.070, h * 0.050, tunic))
        parts.append(make_soft_blob(f"Foot_{side}", (x, h * 0.06, h * 0.05), (h * 0.10, h * 0.14, h * 0.05), shoe))

    # Tapered rounded torso — narrow at the hips, broad at the shoulders.
    parts.append(make_torso("Torso", (0, 0, hip_y + torso_h / 2), torso_h, hip_r, shoulder_r, tunic))
    # Thin sash band around the waist.
    sash_o = make_torso("Sash", (0, 0, hip_y + torso_h * 0.16), torso_h * 0.16, hip_r * 1.12, hip_r * 1.2, sash, bevel_w=0.01)
    parts.append(sash_o)

    for side, xs in (("L", -1), ("R", 1)):
        x = xs * (shoulder_r * 0.92)
        parts.append(make_limb(f"Arm_{side}", (x, 0.02 * xs, shoulder_y - arm_len / 2), arm_len, h * 0.050, h * 0.038, skin))
        parts.append(make_soft_blob(f"Hand_{side}", (x, 0.02 * xs, shoulder_y - arm_len), (h * 0.06, h * 0.058, h * 0.06), skin))

    head_z = shoulder_y + head_r * 0.95
    parts.append(make_soft_blob("Head", (0, 0, head_z), (head_r, head_r * 0.92, head_r * 1.05), skin, 3, 0.003))
    # One large "solid crown" (per the earlier hand-tweaked v8's approach —
    # see art/blender/README.md) instead of several small separate clumps:
    # a big, generously-oversized dome covering the whole top/side/back of
    # the head with heavy overlap. Several small islands are individually
    # fragile — if any one of them picks up a slightly different bone
    # weight than its neighbors, that one clump visibly detaches during the
    # walk cycle even though everything sits correctly in the bind pose.
    # One big overlapping mass tolerates that: even a partially-off clump
    # stays hidden under its neighbors' overlap instead of leaving a bald gap.
    # Top must clear the Head blob's own apex (head_z + head_r*1.05) with
    # real margin, or skin pokes through right at the crown — exactly where
    # the tabletop camera, looking down at the player, sees it most.
    parts.append(make_soft_blob("Hair_Crown", (0.0, -0.02, head_z + head_r * 0.22), (head_r * 1.12, head_r * 1.04, head_r * 0.95), hair, 3, 0.004))
    parts.append(make_soft_blob("Hair_Back", (0.0, -head_r * 0.42, head_z + head_r * 0.08), (head_r * 1.05, head_r * 0.78, head_r * 0.70), hair, 3, 0.004))
    for side, xs in (("L", -1), ("R", 1)):
        parts.append(make_soft_blob(f"Hair_Side_{side}", (xs * head_r * 0.72, head_r * 0.15, head_z - head_r * 0.05), (head_r * 0.42, head_r * 0.5, head_r * 0.55), hair, 3, 0.004))
    # Fringe — a low front clump so the face reads as framed by hair
    # instead of a bald dome; sits above eye height so it doesn't hide them.
    parts.append(make_soft_blob("Hair_Fringe", (0.0, head_r * 0.55, head_z + head_r * 0.30), (head_r * 0.80, head_r * 0.38, head_r * 0.30), hair, 3, 0.004))

    for side, xs in (("L", -1), ("R", 1)):
        parts.append(make_soft_blob(f"Cheek_{side}", (xs * head_r * 0.7, head_r * 0.2, head_z - head_r * 0.15), (head_r * 0.26,) * 3, skin, 2, 0.002))
        parts.append(make_blob(f"Eye_{side}", (xs * head_r * 0.34, head_r * 0.80, head_z - head_r * 0.02), (head_r * 0.135,) * 3, eye, 1))
    parts.append(make_soft_blob("Mouth", (0, head_r * 0.82, head_z - head_r * 0.32), (head_r * 0.20, head_r * 0.06, head_r * 0.10), mouth, 2, 0.0))

    body = join(parts, "WonderWalker_Body")
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    ol = single_skin_outline(body, CFG["outline_thick"], CFG["outline"])
    return body, ol, hip_y, shoulder_y, h, arm_len, leg_len, hip_r * 2, head_r


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


def pin_head_vertices(obj, z_min, bone_name="Head"):
    """Force every vertex at/above `z_min` (head, hair, cheeks, eyes, mouth)
    onto the Head bone with full weight, overriding ARMATURE_AUTO's envelope
    guess.

    ARMATURE_AUTO's automatic weights are a proximity heuristic, not a
    guarantee — enlarging or reshaping nearby geometry (e.g. the v3->v4
    torso swap from a beveled cube to a wider tapered cylinder) can flip
    some hair vertices from "closest to Head" to "closest to Chest", so the
    hair visibly detaches from the head and hides inside the torso during
    the walk cycle, even though it sits correctly in the bind pose. Pinning
    removes the guesswork for the one bone where "rigidly follows the head"
    is exactly the desired behavior anyway.
    """
    vg = obj.vertex_groups.get(bone_name)
    if vg is None:
        vg = obj.vertex_groups.new(name=bone_name)
    other_groups = [g for g in obj.vertex_groups if g.name != bone_name]
    idx = [v.index for v in obj.data.vertices if v.co.z >= z_min]
    print(f"PIN {obj.name}: {len(idx)}/{len(obj.data.vertices)} verts >= z={z_min:.4f} -> {bone_name}")
    for g in other_groups:
        g.remove(idx)
    if idx:
        vg.add(idx, 1.0, "REPLACE")


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
    bpy.context.active_object.data.energy = 3.2
    bpy.context.active_object.rotation_euler = Euler((0.7, 0.2, 0.3))
    bpy.ops.object.light_add(type="AREA", location=(-3, 3, 4))
    bpy.context.active_object.data.energy = 45
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
    bpy.ops.object.camera_add(location=(center.x, center.y - size * 2.1, center.z + size * 0.15))
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
    s.render.resolution_x = 1024
    s.render.resolution_y = 1024
    s.frame_set(1)
    s.render.filepath = path
    bpy.ops.render.render(write_still=True)
    s.frame_set(7)
    s.render.filepath = path.replace(".png", "_walk.png")
    bpy.ops.render.render(write_still=True)
    print("preview ok")


def main():
    clear()
    body, ol, hip_y, shoulder_y, h, arm_len, leg_len, torso_w, head_r = build()
    arm = build_rig(h, hip_y, shoulder_y, torso_w, arm_len, leg_len)
    parent_auto(body, arm)
    parent_auto(ol, arm)
    # Comfortably above the torso top (== shoulder_y) and the arms' shoulder
    # attachment (which also sits at shoulder_y), so only head/hair/face
    # vertices get pinned — see pin_head_vertices()'s docstring.
    head_pin_z = shoulder_y + head_r * 0.15
    pin_head_vertices(body, head_pin_z)
    pin_head_vertices(ol, head_pin_z)
    walk(arm)
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)
    export(arm, GLB)
    preview(PREVIEW)
    print("v12 done")


if __name__ == "__main__":
    main()
