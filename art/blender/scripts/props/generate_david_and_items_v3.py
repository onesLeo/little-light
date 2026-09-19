"""
Little Light — David mentor + Wonder Items v3.
Rounder, more human torso (tapered cylinder, not a beveled cube) and a
substantially reworked lamb (elongated body, smoother wool, better leg
stance, floppier ears) so both David's companion sheep and the collectible
WonderItem_Lamb read as an actual lamb instead of a lumpy cushion.

Materials bake color+grain into a texture directly (matches
recolor_characters_v3.py's technique) instead of an RGB+MixRGB node graph,
which Blender's glTF exporter does not export faithfully. Outline hulls are
single-skin from the start (grow along normal + flip winding), not a
Solidify shell needing a later fix_outlines_v6.py pass.

Blender 4.x / 5.x.
"""
import bpy
import bmesh
import math
import os
import random
import numpy as np
from mathutils import Vector, Euler

_ll_os = os
from pathlib import Path as _ll_Path
_ll_root = _ll_Path(__file__).resolve().parents[2]  # art/blender
_ll_out = _ll_os.environ.get("LITTLE_LIGHT_ART_OUT", str(_ll_root / "output"))

OUT = _ll_out
GRAIN = os.path.join(OUT, "paper_grain.png")
if not os.path.exists(GRAIN):
    GRAIN = str(_ll_root / "assets" / "textures" / "paper_grain.png")

DAVID_GLB = os.path.join(OUT, "david_mentor_v9.glb")
ITEMS_GLB = os.path.join(OUT, "wonder_items_v7.glb")
BLEND = os.path.join(OUT, "david_and_items_v3.blend")
PREV = os.path.join(OUT, "previews")

rng = random.Random(29)


def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for bt in (bpy.data.meshes, bpy.data.materials, bpy.data.images):
        for b in list(bt):
            if b.users == 0:
                bt.remove(b)


def flat(o):
    for p in o.data.polygons:
        p.use_smooth = False
    return o


def uv(o):
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
    if not o.data.uv_layers:
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.03)
        bpy.ops.object.mode_set(mode="OBJECT")


def jitter(o, amt=0.008):
    bm = bmesh.new()
    bm.from_mesh(o.data)
    for v in bm.verts:
        v.co += Vector((rng.uniform(-amt, amt), rng.uniform(-amt, amt), rng.uniform(-amt * 0.4, amt * 0.4)))
    bm.to_mesh(o.data)
    bm.free()
    o.data.update()


def _tinted_grain_image(name, color, mix_fac):
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


def paper(name, color, mix=0.38, roughness=0.9, metallic=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nodes, links = nt.nodes, nt.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = _tinted_grain_image(name, color, mix)
    tex.interpolation = "Closest"
    tc = nodes.new("ShaderNodeTexCoord")
    mp = nodes.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (3.0, 3.0, 3.0)
    links.new(tc.outputs["UV"], mp.inputs["Vector"])
    links.new(mp.outputs["Vector"], tex.inputs["Vector"])
    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mat.diffuse_color = (*color, 1.0)
    return mat


def blob(name, loc, scale, mat, subdiv=2, j=0.01):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv, radius=1, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    jitter(o, j)
    if mat:
        o.data.materials.append(mat)
    uv(o)
    return flat(o)


def soft_blob(name, loc, scale, mat, subdiv=3, j=0.003):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv, radius=1, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    jitter(o, j)
    if mat:
        o.data.materials.append(mat)
    uv(o)
    for p in o.data.polygons:
        p.use_smooth = True
    return o


def make_torso(name, loc, height, r_bottom, r_top, mat, sides=10, bevel_w=0.02, j=0.010):
    """Tapered, beveled cylinder torso — rounder and more human than a
    beveled cube. Narrower at the hips, broader at the shoulders."""
    bpy.ops.mesh.primitive_cone_add(vertices=sides, radius1=r_bottom, radius2=r_top, depth=height, location=loc)
    o = bpy.context.active_object
    o.name = name
    bev = o.modifiers.new("Bevel", "BEVEL")
    bev.width = bevel_w
    bev.segments = 2
    bpy.ops.object.modifier_apply(modifier=bev.name)
    jitter(o, j)
    if mat:
        o.data.materials.append(mat)
    uv(o)
    return flat(o)


def limb(name, loc, length, r0, r1, mat, verts=10):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r0, radius2=r1, depth=length, location=loc)
    o = bpy.context.active_object
    o.name = name
    jitter(o, 0.006)
    if mat:
        o.data.materials.append(mat)
    uv(o)
    return flat(o)


def join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    j = bpy.context.active_object
    j.name = name
    return j


def outline_material(name, color):
    mat = bpy.data.materials.get(name)
    if mat:
        return mat
    mat = paper(name, color, 0.0, roughness=1.0)
    mat.use_backface_culling = True
    return mat


def single_skin_outline(src, thick, mat_name, color):
    hull = src.copy()
    hull.data = src.data.copy()
    hull.name = src.name + "_Outline"
    bpy.context.collection.objects.link(hull)
    bm = bmesh.new()
    bm.from_mesh(hull.data)
    bm.normal_update()
    for v in bm.verts:
        v.co += v.normal * thick
    for f in bm.faces:
        f.normal_flip()
    bm.to_mesh(hull.data)
    bm.free()
    hull.data.materials.clear()
    hull.data.materials.append(outline_material(mat_name, color))
    for p in hull.data.polygons:
        p.use_smooth = False
    return hull


def origin_at(obj, loc):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.context.scene.cursor.location = loc
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")


def build_lamb(prefix, origin, wool, leg_mat, eye_mat, snout_mat=None, horn_mat=None,
               is_ram=False, scale=1.0):
    """A flock animal built around `origin`. Body is an elongated, tapered
    capsule (not a near-sphere) so it reads as a quadruped body rather than
    a round cushion; legs are splayed to the four corners and set slightly
    inward so the body visibly rests on them; wool is smooth-shaded soft
    blobs layered closely over the body instead of large jittery lumps, so
    it reads as a fluffy coat rather than a pile of rocks.
    """
    ox, oy, oz = origin

    def P(dx, dy, dz):
        return (ox + dx * scale, oy + dy * scale, oz + dz * scale)

    def S(*v):
        return tuple(c * scale for c in v)

    parts = []
    # Body: a horizontally elongated soft capsule (longer along Y, the
    # front-back axis) instead of a near-spherical blob.
    parts.append(soft_blob(f"{prefix}Body", P(0, 0.0, 0.20), S(0.13, 0.21, 0.145), wool, 3, 0.010))
    parts.append(soft_blob(f"{prefix}Head", P(0, 0.22, 0.27), S(0.085, 0.09, 0.085), wool, 3, 0.006))
    for side, xs in (("L", -1), ("R", 1)):
        # Small, slightly forward-drooping ears — floppier than a stiff nub.
        parts.append(soft_blob(f"{prefix}Ear{side}", P(xs * 0.075, 0.24, 0.29), S(0.045, 0.028, 0.055), wool, 2, 0.003))
    if snout_mat:
        parts.append(soft_blob(f"{prefix}Snout", P(0, 0.31, 0.24), S(0.055, 0.05, 0.045), snout_mat, 2, 0.003))

    for side, xs in (("L", -1), ("R", 1)):
        parts.append(soft_blob(f"{prefix}Eye{side}", P(xs * 0.05, 0.295, 0.285), S(0.016, 0.016, 0.016), eye_mat, 2, 0.0))

    if is_ram and horn_mat:
        for side, xs in (("L", -1), ("R", 1)):
            base = Vector(P(xs * 0.06, 0.19, 0.36))
            len1 = 0.09 * scale
            rot1 = Euler((math.radians(-30), 0, math.radians(xs * 25)))
            h1 = limb(f"{prefix}Horn{side}A", tuple(base), len1, 0.020 * scale, 0.013 * scale, horn_mat, 6)
            h1.rotation_euler = rot1
            bpy.ops.object.transform_apply(rotation=True)
            tip = base + (rot1.to_matrix() @ Vector((0, 0, 1))) * (len1 / 2)
            len2 = 0.07 * scale
            rot2 = Euler((math.radians(-68), 0, math.radians(xs * 42)))
            h2_center = tip + (rot2.to_matrix() @ Vector((0, 0, 1))) * (len2 / 2)
            h2 = limb(f"{prefix}Horn{side}B", tuple(h2_center), len2, 0.013 * scale, 0.005 * scale, horn_mat, 6)
            h2.rotation_euler = rot2
            bpy.ops.object.transform_apply(rotation=True)
            parts.append(h1)
            parts.append(h2)

    # Legs: splayed toward the four corners of the elongated body, thin and
    # a touch longer, so the body visibly clears the ground on four legs.
    leg_offsets = [(-0.075, -0.11, 0.0), (0.075, -0.11, 0.0), (-0.075, 0.15, 0.0), (0.075, 0.15, 0.0)]
    for i, (dx, dy, dz) in enumerate(leg_offsets):
        parts.append(limb(f"{prefix}Leg{i}", P(dx, dy, 0.085 + dz), 0.16 * scale, 0.024 * scale, 0.018 * scale, leg_mat, 6))
        parts.append(soft_blob(f"{prefix}Hoof{i}", P(dx, dy, 0.006 + dz), S(0.024, 0.024, 0.018), leg_mat, 2))

    # Short fluffy tail.
    parts.append(soft_blob(f"{prefix}Tail", P(0, -0.19, 0.22), S(0.045, 0.05, 0.045), wool, 2, 0.006))

    # Wool coat: smaller, smoother, closely-overlapping soft blobs instead of
    # a handful of large jittery lumps — reads as a fluffy coat texture
    # rather than a stack of separate rocks.
    fluff_specs = [
        ((0.075, 0.10, 0.075), 0.075), ((-0.07, 0.08, 0.07), 0.07),
        ((0.08, -0.05, 0.065), 0.068), ((-0.075, -0.07, 0.06), 0.065),
        ((0.0, 0.13, 0.09), 0.065), ((0.0, -0.10, 0.07), 0.062),
        ((0.06, 0.02, 0.10), 0.06), ((-0.06, 0.0, 0.095), 0.058),
        ((0.0, 0.03, 0.12), 0.07), ((0.0, -0.02, 0.03), 0.05),
    ]
    for i, (off, sc) in enumerate(fluff_specs):
        parts.append(soft_blob(f"{prefix}Fluff{i}", P(off[0], off[1], 0.18 + off[2]), S(sc, sc, sc), wool, 2, 0.006))

    return parts


def build_david():
    skin = paper("D_Skin", (0.88, 0.70, 0.53), 0.26)
    hair = paper("D_Hair", (0.32, 0.20, 0.12), 0.4)
    tunic = paper("D_Tunic", (0.52, 0.62, 0.46), 0.32)
    sash = paper("D_Sash", (0.78, 0.55, 0.28), 0.3)
    sandal = paper("D_Sandal", (0.38, 0.26, 0.16), 0.35)
    eye = paper("D_Eye", (0.07, 0.07, 0.09), 0.0)
    mouth = paper("D_Mouth", (0.72, 0.36, 0.34), 0.0)
    wool = paper("D_Sheep", (0.94, 0.92, 0.87), 0.4)
    snout = paper("D_Snout", (0.90, 0.82, 0.75), 0.22)
    ol_color = (0.05, 0.04, 0.04)

    parts = []
    for side, x in (("L", -0.11), ("R", 0.11)):
        shin = limb(f"Shin_{side}", (x, 0.14, 0.07), 0.30, 0.055, 0.045, tunic, 10)
        shin.rotation_euler = Euler((math.pi / 2, 0, 0))
        bpy.ops.object.transform_apply(rotation=True)
        parts.append(shin)
        parts.append(soft_blob(f"Foot_{side}", (x, 0.28, 0.045), (0.085, 0.125, 0.045), sandal))
        parts.append(limb(f"Thigh_{side}", (x, 0.02, 0.28), 0.26, 0.065, 0.055, tunic, 10))

    hip_z = 0.42
    # Tapered rounded torso instead of a beveled cube — narrower at the
    # waist, broader at the chest/shoulders (mentor build, sturdier than WW).
    parts.append(make_torso("Torso", (0, 0, hip_z + 0.17), 0.34, 0.155, 0.185, tunic, sides=10, bevel_w=0.022))
    parts.append(make_torso("Sash", (0, 0, hip_z + 0.045), 0.09, 0.168, 0.175, sash, sides=10, bevel_w=0.012))

    for side, xs in (("L", -1), ("R", 1)):
        x = xs * 0.20
        parts.append(limb(f"Arm_{side}", (x, 0.05 if xs > 0 else 0.0, hip_z + 0.16), 0.26, 0.045, 0.035, skin, 9))
        parts.append(soft_blob(f"Hand_{side}", (x, 0.12 if xs > 0 else -0.02, hip_z + 0.04), (0.055,) * 3, skin))

    head_z = hip_z + 0.40
    parts.append(soft_blob("Head", (0, 0, head_z), (0.13, 0.12, 0.14), skin, 3, 0.004))
    parts.append(soft_blob("Hair0", (0.02, -0.03, head_z + 0.08), (0.14, 0.12, 0.08), hair, 3, 0.003))
    parts.append(soft_blob("Hair1", (-0.05, 0.02, head_z + 0.05), (0.07, 0.06, 0.05), hair, 3, 0.003))
    parts.append(soft_blob("Hair2", (0.0, -0.05, head_z + 0.02), (0.145, 0.115, 0.13), hair, 3, 0.003))
    # Fringe over the forehead so the face reads as framed, not a bald dome.
    # Bottom must clear the eyes (Eye_* top ≈ head_z+0.025) with real margin,
    # or this reads as a thick uni-brow slab instead of forehead hair.
    parts.append(soft_blob("HairFringe", (0.0, 0.085, head_z + 0.105), (0.105, 0.05, 0.045), hair, 3, 0.003))
    for side, xs in (("L", -1), ("R", 1)):
        parts.append(soft_blob(f"Cheek_{side}", (xs * 0.09, 0.04, head_z - 0.02), (0.04,) * 3, skin, 2, 0.002))
        parts.append(blob(f"Eye_{side}", (xs * 0.045, 0.115, head_z + 0.005), (0.020,) * 3, eye, 1, 0.001))
    parts.append(soft_blob("Mouth", (0, 0.12, head_z - 0.055), (0.03, 0.012, 0.016), mouth, 2, 0.0))

    # Companion sheep — shared lamb rig. Not a ram: David's flock companion
    # stays hornless here.
    parts.extend(build_lamb("Sheep", (0.5, 0.12, 0.0), wool, sandal, eye, snout_mat=snout, is_ram=False))
    body = join(parts, "David_Mentor")
    origin_at(body, (0, 0, 0))
    ol = single_skin_outline(body, 0.0026, "D_OL", ol_color)
    return body, ol


def build_items():
    rock = paper("I_Rock", (0.64, 0.58, 0.48), 0.4)
    wood = paper("I_Wood", (0.50, 0.34, 0.18), 0.38)
    wool = paper("I_Wool", (0.95, 0.93, 0.88), 0.42)
    snout = paper("I_Snout", (0.90, 0.82, 0.75), 0.22)
    eye = paper("I_Eye", (0.07, 0.07, 0.09), 0.0)
    horn = paper("I_Horn", (0.58, 0.48, 0.34), 0.36)
    ol_color = (0.05, 0.04, 0.04)

    stone = blob("WonderItem_Stone", (0, 0, 0.12), (0.14, 0.11, 0.10), rock, 2, 0.018)
    stone.scale = (1.15, 0.9, 0.85)
    bpy.context.view_layer.objects.active = stone
    stone.select_set(True)
    bpy.ops.object.transform_apply(scale=True)
    stone_ol = single_skin_outline(stone, 0.0022, "I_OL", ol_color)

    shaft = limb("StaffShaft", (1.6, 0, 0.55), 1.1, 0.04, 0.032, wood, 10)
    crook = limb("StaffCrook", (1.6, 0.10, 1.12), 0.32, 0.035, 0.03, wood, 10)
    crook.rotation_euler = Euler((1.0, 0.15, 0))
    bpy.ops.object.transform_apply(rotation=True)
    knot = blob("StaffKnot", (1.6, 0.01, 0.7), (0.045, 0.045, 0.04), wood, 1, 0.004)
    staff = join([shaft, crook, knot], "WonderItem_Staff")
    origin_at(staff, (1.6, 0, 0))
    staff_ol = single_skin_outline(staff, 0.0022, "I_OL", ol_color)

    lamb_parts = build_lamb("Lamb", (3.2, 0.0, 0.0), wool, wood, eye, snout_mat=snout, horn_mat=horn, is_ram=True)
    lamb = join(lamb_parts, "WonderItem_Lamb")
    origin_at(lamb, (3.2, 0, 0))
    lamb_ol = single_skin_outline(lamb, 0.0022, "I_OL", ol_color)

    return [stone, stone_ol, staff, staff_ol, lamb, lamb_ol]


def export(path, objs):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
        for c in getattr(o, "children_recursive", []):
            c.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True, export_yup=True)
    print("exported", path)


def preview(path, hide_outline=True):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if hide_outline:
        for o in bpy.context.scene.objects:
            if "Outline" in o.name:
                o.hide_render = True
    for o in list(bpy.data.objects):
        if o.type == "LIGHT":
            bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.object.light_add(type="SUN", location=(5, -4, 9))
    bpy.context.active_object.data.energy = 3.0
    bpy.context.active_object.rotation_euler = Euler((0.7, 0.2, 0.3))
    bpy.ops.object.light_add(type="AREA", location=(-3, 2, 4))
    bpy.context.active_object.data.energy = 55
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH" and not o.hide_render]
    min_c = Vector((1e9,) * 3)
    max_c = Vector((-1e9,) * 3)
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
    bpy.ops.object.camera_add(location=(center.x + size * 1.7, center.y - size * 2.2, center.z + size * 0.9))
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
    bpy.ops.render.render(write_still=True)
    print("preview", path)


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PREV, exist_ok=True)

    clear()
    body, ol = build_david()
    export(DAVID_GLB, [body, ol])
    preview(os.path.join(PREV, "david_mentor_v9.png"))

    clear()
    items = build_items()
    export(ITEMS_GLB, items)
    preview(os.path.join(PREV, "wonder_items_v7.png"))

    clear()
    body, ol = build_david()
    body.location = (-1.5, 0, 0)
    items = build_items()
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)
    print("v3 props done")


if __name__ == "__main__":
    main()
