"""
Little Light — David mentor + Wonder Items v2 polish
Softer handmade papercraft silhouettes (less cube), paper-grain, inverted-hull outline.
Blender 4.x / 5.x.
"""
import bpy
import bmesh
import math
import os
import random
from mathutils import Vector, Euler

_ll_os = os
from pathlib import Path as _ll_Path
_ll_root = _ll_Path(__file__).resolve().parents[0]
_ll_out = _ll_os.environ.get("LITTLE_LIGHT_ART_OUT", r"C:\Users\onesa\wonder-walker")

OUT = _ll_out
GRAIN = os.path.join(OUT, "paper_grain.png")
if not os.path.exists(GRAIN):
    GRAIN = str(_ll_Path(r"C:\Users\onesa\wonder-walker") / "paper_grain.png")

DAVID_GLB = os.path.join(OUT, "david_mentor_v2.glb")
ITEMS_GLB = os.path.join(OUT, "wonder_items_v2.glb")
BLEND = os.path.join(OUT, "david_and_items_v2.blend")
PREV = os.path.join(OUT, "previews")

rng = random.Random(11)


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


def paper(name, color, mix=0.38):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nodes, links = nt.nodes, nt.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.92
    bsdf.inputs["Metallic"].default_value = 0.0
    rgb = nodes.new("ShaderNodeRGB")
    rgb.outputs[0].default_value = (*color, 1.0)
    mixn = nodes.new("ShaderNodeMixRGB")
    mixn.blend_type = "MULTIPLY"
    mixn.inputs["Fac"].default_value = mix
    if GRAIN and os.path.exists(GRAIN):
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
        mp.inputs["Scale"].default_value = (3.0, 3.0, 3.0)
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
    """Smooth-shaded blob for hands, feet and hooves.

    `blob()` is flat-shaded to match the papercraft body panels, which reads
    fine for a torso but makes hands/feet/hooves look like faceted paper
    lumps. This keeps a whisper of the same handmade jitter but shades the
    result smooth, so extremities read as soft and rounded — alive — against
    the flat-faceted body and limbs.
    """
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


def soft_box(name, size, loc, mat, bevel=0.12, cuts=1):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.dimensions = size
    bpy.ops.object.transform_apply(scale=True)
    bev = o.modifiers.new("Bevel", "BEVEL")
    bev.width = min(size) * bevel
    bev.segments = 3
    bpy.ops.object.modifier_apply(modifier=bev.name)
    if cuts:
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.subdivide(number_cuts=cuts)
        bpy.ops.object.mode_set(mode="OBJECT")
    jitter(o, 0.01)
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


def origin_at(obj, loc):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.context.scene.cursor.location = loc
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")


def build_lamb(prefix, origin, wool, leg_mat, eye_mat, snout_mat=None, horn_mat=None,
               is_ram=False, scale=1.0):
    """A flock animal built around `origin`: body, head, ears, snout, four
    soft-hoofed legs and eyes — shared by David's companion sheep and the
    collectible Wonder-Item lamb so both read as living animals rather than
    wool cushions. `is_ram=True` (adult male) adds a pair of short,
    backward-curving horns.
    """
    ox, oy, oz = origin

    def P(dx, dy, dz):
        return (ox + dx * scale, oy + dy * scale, oz + dz * scale)

    def S(*v):
        return tuple(c * scale for c in v)

    parts = []
    parts.append(blob(f"{prefix}Body", P(0, 0, 0.18), S(0.16, 0.14, 0.13), wool, 2, 0.012))
    parts.append(blob(f"{prefix}Head", P(0, 0.16, 0.26), S(0.09, 0.08, 0.09), wool, 2, 0.008))
    for side, xs in (("L", -1), ("R", 1)):
        parts.append(blob(f"{prefix}Ear{side}", P(xs * 0.06, 0.20, 0.30), S(0.035, 0.02, 0.045), wool, 1, 0.003))
    if snout_mat:
        parts.append(blob(f"{prefix}Snout", P(0, 0.24, 0.22), S(0.05, 0.04, 0.04), snout_mat, 1, 0.003))

    # Eyes — small dark beads flanking the snout. The single biggest thing
    # that makes this read as an animal rather than a cushion of wool.
    for side, xs in (("L", -1), ("R", 1)):
        parts.append(soft_blob(f"{prefix}Eye{side}", P(xs * 0.045, 0.235, 0.275), S(0.015, 0.015, 0.015), eye_mat, 2, 0.0))

    # Horns — adult male only. Two short segments per side, the second more
    # sharply swept than the first: a single straight cone reads as a spike,
    # two segments at different angles is what sells "curved ram horn" at
    # this poly budget.
    if is_ram and horn_mat:
        for side, xs in (("L", -1), ("R", 1)):
            base = Vector(P(xs * 0.055, 0.14, 0.35))
            # Segment A: rooted at `base` (a cone is centered on its own
            # location, so the true root/tip sit at +/- half its length along
            # its rotated axis — chaining on the *center* would leave a gap).
            len1 = 0.09 * scale
            rot1 = Euler((math.radians(-30), 0, math.radians(xs * 25)))
            h1 = limb(f"{prefix}Horn{side}A", tuple(base), len1, 0.020 * scale, 0.013 * scale, horn_mat, 6)
            h1.rotation_euler = rot1
            bpy.ops.object.transform_apply(rotation=True)
            tip = base + (rot1.to_matrix() @ Vector((0, 0, 1))) * (len1 / 2)
            # Segment B: swept back further, its near end centered exactly on
            # segment A's tip so the two visibly join.
            len2 = 0.07 * scale
            rot2 = Euler((math.radians(-68), 0, math.radians(xs * 42)))
            h2_center = tip + (rot2.to_matrix() @ Vector((0, 0, 1))) * (len2 / 2)
            h2 = limb(f"{prefix}Horn{side}B", tuple(h2_center), len2, 0.013 * scale, 0.005 * scale, horn_mat, 6)
            h2.rotation_euler = rot2
            bpy.ops.object.transform_apply(rotation=True)
            parts.append(h1)
            parts.append(h2)

    # Legs with a soft, smooth-shaded hoof cap instead of a bare cone point —
    # softer silhouette and the tonal/shading break reads as an actual hoof.
    leg_offsets = [(-0.08, -0.05, 0.0), (0.08, -0.05, 0.0), (-0.08, 0.09, 0.0), (0.08, 0.09, 0.0)]
    for i, (dx, dy, dz) in enumerate(leg_offsets):
        parts.append(limb(f"{prefix}Leg{i}", P(dx, dy, 0.07 + dz), 0.13 * scale, 0.027 * scale, 0.021 * scale, leg_mat, 6))
        parts.append(soft_blob(f"{prefix}Hoof{i}", P(dx, dy, 0.006 + dz), S(0.026, 0.026, 0.02), leg_mat, 2))

    # Shaggy wool fluff clumps for a less-uniform silhouette.
    fluff_specs = [((0.08, 0.02, 0.06), 0.08), ((-0.07, -0.02, 0.05), 0.07),
                   ((0.03, -0.08, 0.04), 0.065), ((-0.02, 0.08, 0.05), 0.06),
                   ((0.0, 0.0, 0.10), 0.07)]
    for i, (off, sc) in enumerate(fluff_specs):
        parts.append(blob(f"{prefix}Fluff{i}", P(off[0], off[1], 0.18 + off[2]), S(sc, sc, sc), wool, 1, 0.012))

    return parts


def build_david():
    skin = paper("D_Skin", (0.88, 0.70, 0.53), 0.28)
    hair = paper("D_Hair", (0.32, 0.20, 0.12), 0.42)
    tunic = paper("D_Tunic", (0.52, 0.62, 0.46), 0.4)
    sash = paper("D_Sash", (0.78, 0.55, 0.28), 0.35)
    sandal = paper("D_Sandal", (0.38, 0.26, 0.16), 0.35)
    eye = paper("D_Eye", (0.07, 0.07, 0.09), 0.0)
    wool = paper("D_Sheep", (0.94, 0.92, 0.87), 0.45)
    snout = paper("D_Snout", (0.90, 0.82, 0.75), 0.25)
    ol = paper("D_OL", (0.04, 0.04, 0.05), 0.0)

    parts = []
    # Kneeling: thighs up, shins along ground — softer tapered limbs
    for side, x in (("L", -0.11), ("R", 0.11)):
        # shin along Y
        shin = limb(f"Shin_{side}", (x, 0.14, 0.07), 0.30, 0.055, 0.045, tunic, 10)
        shin.rotation_euler = Euler((math.pi / 2, 0, 0))
        bpy.ops.object.transform_apply(rotation=True)
        parts.append(shin)
        parts.append(soft_blob(f"Foot_{side}", (x, 0.28, 0.045), (0.085, 0.125, 0.045), sandal))
        parts.append(limb(f"Thigh_{side}", (x, 0.02, 0.28), 0.26, 0.065, 0.055, tunic, 10))

    hip_z = 0.42
    parts.append(soft_box("Torso", (0.32, 0.18, 0.30), (0, 0, hip_z + 0.15), tunic, 0.16, 1))
    parts.append(soft_box("Sash", (0.34, 0.20, 0.055), (0, 0, hip_z + 0.06), sash, 0.2, 0))

    for side, xs in (("L", -1), ("R", 1)):
        x = xs * 0.20
        parts.append(limb(f"Arm_{side}", (x, 0.05 if xs > 0 else 0.0, hip_z + 0.16), 0.26, 0.045, 0.035, skin, 9))
        parts.append(soft_blob(f"Hand_{side}", (x, 0.12 if xs > 0 else -0.02, hip_z + 0.04), (0.055,) * 3, skin))

    head_z = hip_z + 0.40
    parts.append(blob("Head", (0, 0, head_z), (0.13, 0.12, 0.14), skin, 2, 0.008))
    parts.append(blob("Hair0", (0.02, -0.03, head_z + 0.08), (0.14, 0.12, 0.08), hair, 1))
    parts.append(blob("Hair1", (-0.05, 0.02, head_z + 0.05), (0.07, 0.06, 0.05), hair, 1))
    for side, xs in (("L", -1), ("R", 1)):
        parts.append(blob(f"Cheek_{side}", (xs * 0.09, 0.04, head_z - 0.02), (0.04,) * 3, skin, 1, 0.004))
        parts.append(blob(f"Eye_{side}", (xs * 0.045, 0.11, head_z + 0.01), (0.018,) * 3, eye, 1, 0.001))

    # Companion sheep — shared lamb rig (body/head/ears/snout/eyes/hooves).
    # Not a ram: David's flock companion stays hornless here.
    parts.extend(build_lamb("Sheep", (0.48, 0.12, 0.0), wool, sandal, eye, snout_mat=snout, is_ram=False))
    body = join(parts, "David_Mentor")
    origin_at(body, (0, 0, 0))
    ol_o = outline(body, 0.011, ol)
    return body, ol_o


def build_items():
    rock = paper("I_Rock", (0.64, 0.58, 0.48), 0.4)
    wood = paper("I_Wood", (0.50, 0.34, 0.18), 0.42)
    wool = paper("I_Wool", (0.95, 0.93, 0.88), 0.48)
    snout = paper("I_Snout", (0.90, 0.82, 0.75), 0.25)
    eye = paper("I_Eye", (0.07, 0.07, 0.09), 0.0)
    horn = paper("I_Horn", (0.58, 0.48, 0.34), 0.4)
    ol = paper("I_OL", (0.04, 0.04, 0.05), 0.0)

    # --- Stone: irregular low-poly pebble (not a perfect sphere) ---
    stone = blob("WonderItem_Stone", (0, 0, 0.12), (0.14, 0.11, 0.10), rock, 2, 0.018)
    # squash slightly
    stone.scale = (1.15, 0.9, 0.85)
    bpy.context.view_layer.objects.active = stone
    stone.select_set(True)
    bpy.ops.object.transform_apply(scale=True)
    stone_ol = outline(stone, 0.009, ol)

    # --- Staff: tapered shaft + crook, slight bend feel ---
    shaft = limb("StaffShaft", (1.6, 0, 0.55), 1.1, 0.04, 0.032, wood, 10)
    crook = limb("StaffCrook", (1.6, 0.10, 1.12), 0.32, 0.035, 0.03, wood, 10)
    crook.rotation_euler = Euler((1.0, 0.15, 0))
    bpy.ops.object.transform_apply(rotation=True)
    # knot bump
    knot = blob("StaffKnot", (1.6, 0.01, 0.7), (0.045, 0.045, 0.04), wood, 1, 0.004)
    staff = join([shaft, crook, knot], "WonderItem_Staff")
    origin_at(staff, (1.6, 0, 0))
    staff_ol = outline(staff, 0.009, ol)

    # --- Lamb: shared lamb rig, adult male (horned) ---
    lamb_parts = build_lamb("Lamb", (3.2, 0.0, 0.0), wool, wood, eye, snout_mat=snout, horn_mat=horn, is_ram=True)
    lamb = join(lamb_parts, "WonderItem_Lamb")
    origin_at(lamb, (3.2, 0, 0))
    lamb_ol = outline(lamb, 0.009, ol)

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
    bpy.context.active_object.data.energy = 5
    bpy.context.active_object.rotation_euler = Euler((0.7, 0.2, 0.3))
    bpy.ops.object.light_add(type="AREA", location=(-3, 2, 4))
    bpy.context.active_object.data.energy = 110
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
    preview(os.path.join(PREV, "david_mentor_v2.png"))

    clear()
    items = build_items()
    export(ITEMS_GLB, items)
    preview(os.path.join(PREV, "wonder_items_v2.png"))

    # combined blend
    clear()
    body, ol = build_david()
    body.location = (-1.5, 0, 0)
    items = build_items()
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)
    print("v2 props done")


if __name__ == "__main__":
    main()
