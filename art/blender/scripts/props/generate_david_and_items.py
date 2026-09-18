"""
Little Light — deferred art from QA P0.2:
  - Young David mentor placeholder (kneeling by sheep vibe)
  - Real Wonder Item meshes: smooth stone, shepherd staff, woolly lamb
Exports separate glbs for Godot swap (replace gold orbs / dialogue stub).
"""
import bpy

# --- Little Light path override (repo-friendly) ---
import os as _ll_os
from pathlib import Path as _ll_Path
_ll_root = _ll_Path(__file__).resolve().parents[2]  # art/blender
_ll_out = _ll_os.environ.get("LITTLE_LIGHT_ART_OUT", str(_ll_root / "output"))
# -------------------------------------------------
import os

OUT = _ll_out
DAVID_GLB = os.path.join(OUT, "david_mentor_placeholder.glb")
ITEMS_GLB = os.path.join(OUT, "wonder_items.glb")
BLEND = os.path.join(OUT, "david_and_wonder_items.blend")


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for bt in (bpy.data.meshes, bpy.data.materials, bpy.data.images):
        for b in list(bt):
            if b.users == 0:
                bt.remove(b)


def make_paper(name, color, roughness=0.92, grain=14.0, strength=0.12):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nodes, links = nt.nodes, nt.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    out.location = (500, 0)
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (250, 0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = 0.0
    base = nodes.new("ShaderNodeRGB")
    base.location = (-350, 80)
    base.outputs[0].default_value = (*color, 1.0)
    if strength <= 0.001:
        links.new(base.outputs["Color"], bsdf.inputs["Base Color"])
    else:
        tc = nodes.new("ShaderNodeTexCoord")
        tc.location = (-750, -80)
        mp = nodes.new("ShaderNodeMapping")
        mp.location = (-550, -80)
        mp.inputs["Scale"].default_value = (grain, grain, grain)
        noise = nodes.new("ShaderNodeTexNoise")
        noise.location = (-350, -80)
        noise.inputs["Scale"].default_value = 6.0
        noise.inputs["Detail"].default_value = 8.0
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.location = (-150, -80)
        ramp.color_ramp.elements[0].position = 0.35
        ramp.color_ramp.elements[0].color = (1 - strength,) * 3 + (1,)
        ramp.color_ramp.elements[1].position = 0.75
        ramp.color_ramp.elements[1].color = (1 + strength * 0.5,) * 3 + (1,)
        mix = nodes.new("ShaderNodeMixRGB")
        mix.location = (50, 40)
        mix.blend_type = "MULTIPLY"
        mix.inputs["Fac"].default_value = 1.0
        links.new(tc.outputs["Object"], mp.inputs["Vector"])
        links.new(mp.outputs["Vector"], noise.inputs["Vector"])
        links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
        links.new(base.outputs["Color"], mix.inputs["Color1"])
        links.new(ramp.outputs["Color"], mix.inputs["Color2"])
        links.new(mix.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mat.diffuse_color = (*color, 1.0)
    return mat


def flat(obj):
    for p in obj.data.polygons:
        p.use_smooth = False
    return obj


def box(name, size, loc, mat=None, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if mat:
        o.data.materials.append(mat)
    return flat(o)


def cyl(name, r, d, loc, mat=None, verts=6, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=d, location=loc, rotation=rot, vertices=verts)
    o = bpy.context.active_object
    o.name = name
    if mat:
        o.data.materials.append(mat)
    return flat(o)


def sph(name, r, loc, mat=None, seg=6, rings=4):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=seg, ring_count=rings)
    o = bpy.context.active_object
    o.name = name
    if mat:
        o.data.materials.append(mat)
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
    m = o.modifiers.new("OutlineSolidify", "SOLIDIFY")
    m.thickness = thick
    m.offset = 1.0
    m.use_flip_normals = True
    bpy.ops.object.modifier_apply(modifier=m.name)
    o.data.materials.clear()
    o.data.materials.append(mat)
    o.visible_shadow = False
    return o


def origin_feet(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")


def export_glb(path, objs):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
        for c in o.children_recursive:
            c.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.gltf(
        filepath=path, export_format="GLB", use_selection=True, export_apply=True, export_yup=True
    )
    print("[LL]", path)


def build_david():
    """Young shepherd ~1.2m, kneeling pose (knees down, torso upright). Guest mentor — not the player."""
    skin = make_paper("David_Skin", (0.88, 0.70, 0.52), grain=20)
    hair = make_paper("David_Hair", (0.35, 0.22, 0.12), grain=14)
    tunic = make_paper("David_Tunic", (0.55, 0.62, 0.48), grain=12)  # soft olive/sage shepherd cloth
    sash = make_paper("David_Sash", (0.78, 0.55, 0.28), grain=12)
    sandal = make_paper("David_Sandal", (0.40, 0.28, 0.18), grain=10)
    eye = make_paper("David_Eye", (0.08, 0.08, 0.10), strength=0.0, roughness=0.4)
    out_mat = make_paper("David_Outline", (0.05, 0.05, 0.06), strength=0.0, roughness=1.0)

    h = 1.05  # kneeling figure overall height lower than standing WW
    parts = []
    # Kneeling: thighs forward, shins under, torso up
    # Shins along ground (Y)
    for side, x in (("L", -0.12), ("R", 0.12)):
        parts.append(cyl(f"Shin_{side}", 0.07, 0.32, (x, 0.12, 0.07), tunic, 6, rot=(math_pi_half(), 0, 0)))
        parts.append(box(f"Foot_{side}", (0.14, 0.22, 0.08), (x, 0.28, 0.05), sandal))
        # Thighs angled / vertical-ish from knee to hip
        parts.append(cyl(f"Thigh_{side}", 0.08, 0.28, (x, 0.02, 0.28), tunic, 6))

    hip_z = 0.42
    parts.append(box("Torso", (0.34, 0.20, 0.32), (0, 0, hip_z + 0.16), tunic))
    parts.append(box("Sash", (0.36, 0.22, 0.06), (0, 0, hip_z + 0.08), sash))

    for side, xs in (("L", -1), ("R", 1)):
        x = xs * 0.22
        # Arms resting / one slightly forward (gentle)
        parts.append(cyl(f"Arm_{side}", 0.05, 0.28, (x, 0.06 if xs > 0 else -0.02, hip_z + 0.18), skin, 6))
        parts.append(sph(f"Hand_{side}", 0.06, (x, 0.12 if xs > 0 else -0.04, hip_z + 0.05), skin))

    head_z = hip_z + 0.42
    parts.append(sph("Head", 0.14, (0, 0, head_z), skin, 8, 6))
    parts.append(box("Hair", (0.26, 0.24, 0.14), (0, -0.02, head_z + 0.08), hair))
    for side, x in (("L", -0.05), ("R", 0.05)):
        parts.append(sph(f"Eye_{side}", 0.02, (x, 0.12, head_z + 0.01), eye))

    # Small sheep nearby (script: kneeling by a sheep)
    wool = make_paper("Sheep_Wool", (0.93, 0.91, 0.86), grain=22)
    parts.append(sph("Sheep_Body", 0.18, (0.45, 0.15, 0.20), wool))
    parts.append(sph("Sheep_Head", 0.10, (0.45, 0.30, 0.28), wool))

    body = join(parts, "David_Mentor")
    origin_feet(body)
    ol = outline(body, 0.012, out_mat)
    return body, ol


def math_pi_half():
    import math
    return math.pi / 2


def build_wonder_items():
    rock = make_paper("Item_Rock", (0.62, 0.58, 0.50), grain=10)
    wood = make_paper("Item_Wood", (0.48, 0.32, 0.18), grain=8)
    wool = make_paper("Item_Wool", (0.94, 0.92, 0.86), grain=20)
    out_mat = make_paper("Item_Outline", (0.05, 0.05, 0.06), strength=0.0, roughness=1.0)

    # Separate empties-as-roots would be nicer; export as three joined-named meshes in one file
    # spaced along X so Godot can split / instance by node name after import.
    stone = sph("WonderItem_Stone", 0.16, (0, 0, 0.16), rock, 7, 5)
    # Slightly irregular: squash
    stone.scale = (1.15, 0.95, 0.85)
    bpy.ops.object.transform_apply(scale=True)
    stone_ol = outline(stone, 0.01, out_mat)

    staff = cyl("WonderItem_Staff", 0.045, 1.15, (1.5, 0, 0.575), wood, 6)
    # Crook tip
    crook = cyl("WonderItem_StaffCrook", 0.04, 0.28, (1.5, 0.12, 1.12), wood, 6, rot=(0.9, 0, 0))
    staff_j = join([staff, crook], "WonderItem_Staff")
    origin_at(staff_j, (1.5, 0, 0))
    staff_ol = outline(staff_j, 0.01, out_mat)

    lamb_b = sph("WonderItem_LambBody", 0.22, (3.0, 0, 0.24), wool)
    lamb_h = sph("WonderItem_LambHead", 0.12, (3.0, 0.22, 0.36), wool)
    ear_l = sph("WonderItem_LambEarL", 0.04, (2.92, 0.28, 0.40), wool)
    ear_r = sph("WonderItem_LambEarR", 0.04, (3.08, 0.28, 0.40), wool)
    leg1 = cyl("WonderItem_LambLeg1", 0.035, 0.16, (2.90, -0.06, 0.08), wood, 5)
    leg2 = cyl("WonderItem_LambLeg2", 0.035, 0.16, (3.10, -0.06, 0.08), wood, 5)
    leg3 = cyl("WonderItem_LambLeg3", 0.035, 0.16, (2.90, 0.10, 0.08), wood, 5)
    leg4 = cyl("WonderItem_LambLeg4", 0.035, 0.16, (3.10, 0.10, 0.08), wood, 5)
    lamb = join([lamb_b, lamb_h, ear_l, ear_r, leg1, leg2, leg3, leg4], "WonderItem_Lamb")
    origin_at(lamb, (3.0, 0, 0))
    lamb_ol = outline(lamb, 0.01, out_mat)

    return [stone, stone_ol, staff_j, staff_ol, lamb, lamb_ol]


def origin_at(obj, loc):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.context.scene.cursor.location = loc
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")


def main():
    os.makedirs(OUT, exist_ok=True)

    clear_scene()
    body, ol = build_david()
    export_glb(DAVID_GLB, [body, ol])

    clear_scene()
    items = build_wonder_items()
    export_glb(ITEMS_GLB, items)

    # Combined blend for polish
    clear_scene()
    body, ol = build_david()
    body.location = (-2, 0, 0)
    items = build_wonder_items()
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)
    print("[LL] Deferred art done.")


if __name__ == "__main__":
    main()
