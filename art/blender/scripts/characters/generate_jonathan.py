"""Jonathan: David's organic construction, a distinct face, and a deforming rig.

Uses the same welded shoulders, sculpted hands and tapered limbs as David v13.
Long swept hair, a narrower/longer face, wine cloth and gold identify Jonathan.
Writes only jonathan_v1 assets; never rebuilds or overwrites David/Walker.
"""
import importlib.util
import math
from pathlib import Path
import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("david_shapes", HERE / "generate_david_mentor_v4.py")
david = importlib.util.module_from_spec(spec)
spec.loader.exec_module(david)
ww = david.ww
OUT = ww.OUT


def long_hair(material):
    # One continuous scalp and shoulder-length back; a gently swept front edge.
    verts, faces = [], []
    sides, rows = 40, 16
    for j in range(rows + 1):
        t = j / rows
        for k in range(sides):
            theta = math.tau * k / sides
            front = max(0.0, math.sin(theta))
            edge = 2.12 - .90 * front ** 3 + .075 * math.cos(theta) * front
            phi = .008 + (edge - .008) * t
            drape = ww.smoothstep(.65, 1.0, t) * (1 - front ** 2)
            radius = 1 + .015 * math.sin(theta * 5 + .4) * math.sin(phi)
            verts.append((.155 * math.sin(phi) * math.cos(theta) * radius,
                          -.022 + .149 * math.sin(phi) * math.sin(theta) * radius,
                          1.012 + .168 * math.cos(phi) - .145 * drape))
    for j in range(rows):
        for k in range(sides):
            a, b = j * sides + k, j * sides + (k + 1) % sides
            faces.append((a, b, b + sides, a + sides))
    faces.append(tuple(reversed(range(sides))))
    obj = ww.mesh_object("LongHair", verts, faces, material)
    bpy.context.view_layer.objects.active = obj
    solid = obj.modifiers.new("Hair edge", "SOLIDIFY")
    solid.thickness = .005
    bpy.ops.object.modifier_apply(modifier=solid.name)
    return obj


def shoulder_sash(material):
    verts, faces = [], []
    # A thin curved ribbon follows the chest instead of a rigid box.
    for i in range(19):
        t = i / 18
        x = -.053 + .138 * t
        z = .791 - .269 * t
        y = .083 + .025 * math.sin(math.pi * t)
        for side in [-1, 1]:
            verts.append((x + .021 * side, y, z + .010 * side))
        if i:
            a = (i - 1) * 2
            faces.append((a, a + 1, a + 3, a + 2))
    obj = ww.mesh_object("ShoulderSash", verts, faces, material)
    bpy.context.view_layer.objects.active = obj
    solid = obj.modifiers.new("Cloth edge", "SOLIDIFY")
    solid.thickness = .003
    bpy.ops.object.modifier_apply(modifier=solid.name)
    return obj


def facial_shapes(body):
    body.shape_key_add(name="Basis")
    blink = body.shape_key_add(name="Blink")
    talk = body.shape_key_add(name="Talk")
    eye_vertices, mouth_vertices = set(), set()
    for poly in body.data.polygons:
        name = body.data.materials[poly.material_index].name
        if name in ("J_Eye", "J_Catchlight"):
            eye_vertices.update(poly.vertices)
        elif name == "J_Mouth":
            mouth_vertices.update(poly.vertices)
    eye_z = .84 + (.976 - .84) * 1.08
    mouth_z = .84 + (.912 - .84) * 1.08
    for i in eye_vertices:
        v = body.data.vertices[i].co
        blink.data[i].co.z = eye_z + (v.z - eye_z) * .10
    for i in mouth_vertices:
        v = body.data.vertices[i].co
        talk.data[i].co.z = mouth_z + (v.z - mouth_z) * 2.5 - .003


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / ".gdignore").touch()
    ww.old.clear()
    ww.PARTS.clear()
    # Match the camp's tablet budget. Keep welded skin quality, but use fewer
    # rings on small cloth/leg profiles and fewer facets on tiny facial details.
    original_profile = ww.profile
    ww.profile = lambda name, rings, mat, sides=18, steps=2: original_profile(name, rings, mat, sides, steps)
    ww.blob = lambda name, pos, scale, mat: ww.old.make_soft_blob(name, pos, scale, mat, subdiv=2, j=0)
    ww.build_geometry()
    palette = {
        "Skin": ww.old.paper_mat("J_Skin", (.82, .565, .37), .16),
        "Tunic": ww.old.paper_mat("J_Tunic", (.48, .115, .19), .28),
        "Sash": ww.old.paper_mat("J_Sash", (.86, .64, .24), .25),
        "Hair": ww.old.paper_mat("J_Hair", (.095, .043, .024), .25),
        "Eye": ww.old.paper_mat("J_Eye", (.085, .042, .023), 0),
        "Mouth": ww.old.paper_mat("J_Mouth", (.39, .16, .10), 0),
    }
    leather = ww.old.paper_mat("J_Leather", (.25, .135, .065), .22)
    kept = []
    for obj, outlined in ww.PARTS:
        if obj.name.startswith(("HairCap", "SideLock", "Shoe_")):
            bpy.data.objects.remove(obj, do_unlink=True)
            continue
        david.rematerialize(obj, palette)
        if obj.name.startswith("TrouserLeg"):
            obj.data.materials.clear()
            obj.data.materials.append(palette["Skin"])
            for face in obj.data.polygons:
                face.material_index = 0
        if obj.name == "Tunic":
            for v in obj.data.vertices:
                v.co.z -= .035 * (1 - ww.smoothstep(.41, .505, v.co.z))
        kept.append((obj, outlined))
    ww.PARTS[:] = kept
    for obj, outlined in david.build_sandals(palette["Skin"], leather):
        side = "L" if obj.name.endswith("L") else "R"
        ww.weighted(obj, ww.fixed("Shin_" + side), outlined)
    ww.weighted(long_hair(palette["Hair"]), ww.fixed("Head"))
    ww.weighted(shoulder_sash(palette["Sash"]), ww.torso_weights, False)
    band = [( .145 * math.cos(t), -.022 + .136 * math.sin(t), 1.078 + .003 * math.sin(t))
            for t in [math.tau * i / 64 for i in range(65)]]
    ww.weighted(ww.curve_mesh("HairBand", band, .004, palette["Sash"]), ww.fixed("Head"), False)
    highlight = ww.old.paper_mat("J_Catchlight", (.98, .93, .82), 0)
    for side, sign in [("L", -1), ("R", 1)]:
        ww.weighted(ww.blob("Catchlight_" + side, (sign * .047 - .002, .109, .981),
                            (.0025, .0015, .0025), highlight), ww.fixed("Head"), False)
    # The same face construction as David, with a longer jaw and narrower cheeks.
    for obj, _ in ww.PARTS:
        for v in obj.data.vertices:
            blend = ww.smoothstep(.81, .89, v.co.z)
            v.co.x *= 1 - .045 * blend
            if v.co.z > .84:
                v.co.z = .84 + (v.co.z - .84) * 1.08
    for obj, _ in ww.PARTS:
        # Preserve the sculpted silhouette and skin weights, while reducing
        # regular tessellation that is invisible at the dialogue camera size.
        # Apply before making the hull so its contour and deformation match.
        if len(obj.data.vertices) > 100 and obj.name != "Smile":
            bpy.context.view_layer.objects.active = obj
            decimate = obj.modifiers.new("Camp tablet budget", "DECIMATE")
            decimate.ratio = .40
            bpy.ops.object.modifier_apply(modifier=decimate.name)
        print("PART_VERTICES", obj.name, len(obj.data.vertices))
    arm = ww.rig()
    arm.name = "JonathanRig"
    body = next(o for o in arm.children if o.name == "WonderWalker_Body")
    hull = next(o for o in arm.children if o.name == "WonderWalker_Outline")
    body.name, hull.name = "JonathanBody", "JonathanOutline"
    facial_shapes(body)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "jonathan_v1.blend"))
    bpy.ops.object.select_all(action="DESELECT")
    for obj in (arm, body, hull):
        obj.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.export_scene.gltf(filepath=str(OUT / "jonathan_v1.glb"), export_format="GLB",
        use_selection=True, export_apply=False, export_morph=True, export_skins=True,
        export_animations=False, export_yup=True)
    print("JONATHAN_COMPLETE", len(body.data.vertices), "body vertices")


if __name__ == "__main__":
    main()
