"""Noah and Noah's wife: David's connected body, dressed for the ark.

Noah is a broader workman: rust over cream, a dark belt, short grey-brown hair
and a full beard. His wife is the first different proportion on this base:
narrower shoulders, a little shorter, teal and sand, hair tied back. Neither
file overwrites David, Jonathan or the Wonder-Walker.

Run from the repo root:
  blender --background --python art/blender/scripts/characters/generate_noah_v1.py
  blender --background --python art/blender/scripts/characters/generate_noahs_wife_v1.py
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


def _solid(obj, thickness):
    bpy.context.view_layer.objects.active = obj
    solid = obj.modifiers.new("Paper edge", "SOLIDIFY")
    solid.thickness = thickness
    bpy.ops.object.modifier_apply(modifier=solid.name)
    return obj


def work_hair(material, tied):
    """A short work cap. Tied hair keeps the forehead clear and stops at the nape."""
    verts, faces = [], []
    sides, rows = 36, 12
    for j in range(rows + 1):
        t = j / rows
        for k in range(sides):
            theta = math.tau * k / sides
            front = max(0.0, math.sin(theta))
            edge = (1.55 if tied else 1.85) - 0.55 * front ** 2
            phi = 0.02 + (edge - 0.02) * t
            drape = 0.0 if tied else ww.smoothstep(0.75, 1.0, t) * (1 - front) * 0.35
            verts.append((0.150 * math.sin(phi) * math.cos(theta),
                          -0.02 + 0.142 * math.sin(phi) * math.sin(theta),
                          1.02 + 0.150 * math.cos(phi) - 0.08 * drape))
    for j in range(rows):
        for k in range(sides):
            a, b = j * sides + k, j * sides + (k + 1) % sides
            faces.append((a, b, b + sides, a + sides))
    faces.append(tuple(reversed(range(sides))))
    return _solid(ww.mesh_object("WorkHair", verts, faces, material), 0.005)


def bun(material):
    return ww.blob("HairBun", (0.0, -0.055, 1.045), (0.042, 0.038, 0.040), material)


def beard(material):
    """Jaw, cheeks and a short chin. Rounded masses, not a flat tab under the mouth."""
    parts = [
        ww.blob("BeardChin", (0.0, 0.055, 0.855), (0.058, 0.042, 0.048), material),
        ww.blob("BeardJawL", (-0.055, 0.035, 0.885), (0.032, 0.028, 0.034), material),
        ww.blob("BeardJawR", (0.055, 0.035, 0.885), (0.032, 0.028, 0.034), material),
        ww.blob("BeardTip", (0.0, 0.072, 0.815), (0.034, 0.030, 0.038), material),
    ]
    return ww.fuse("Beard", parts, material, 0.006)


def belt(material):
    return ww.profile("WorkBelt", [
        (0.50, 0, 0.01, 0.132, 0.086),
        (0.525, 0, 0.01, 0.136, 0.090),
        (0.545, 0, 0.01, 0.130, 0.084),
    ], material, sides=18, steps=2)


def shape_face(kind):
    """Noah reads broader and older. His wife reads narrower through the jaw."""
    for obj, _outlined in ww.PARTS:
        for v in obj.data.vertices:
            if v.co.z < 0.82:
                continue
            if kind == "noah":
                v.co.x *= 1.05
                if 0.90 < v.co.z < 1.00 and abs(v.co.x) < 0.045 and v.co.y > 0.05:
                    v.co.y += 0.014
            else:
                jaw = ww.smoothstep(0.82, 0.90, v.co.z) * (1.0 - ww.smoothstep(0.96, 1.05, v.co.z))
                v.co.x *= 1.0 - 0.08 * jaw


def shape_body(kind):
    for obj, _outlined in ww.PARTS:
        for v in obj.data.vertices:
            if kind == "noah" and obj.name in ("Tunic", "ClothSash", "SashKnot", "SashTail"):
                v.co.x *= 1.08
            if kind == "wife":
                if v.co.z > 0.66:
                    v.co.x *= 0.88
                if 0.30 < v.co.z < 0.55:
                    v.co.x *= 1.08


def facial_shapes(body, prefix):
    body.shape_key_add(name="Basis")
    blink = body.shape_key_add(name="Blink")
    talk = body.shape_key_add(name="Talk")
    eyes, mouth = set(), set()
    for poly in body.data.polygons:
        name = body.data.materials[poly.material_index].name
        if name in (prefix + "_Eye", prefix + "_Catchlight"):
            eyes.update(poly.vertices)
        elif name == prefix + "_Mouth":
            mouth.update(poly.vertices)
    for i in eyes:
        v = body.data.vertices[i].co
        blink.data[i].co.z = v.z * 0.15 + 0.90
    for i in mouth:
        v = body.data.vertices[i].co
        talk.data[i].co.z = v.z + 0.012
        talk.data[i].co.y = v.y + 0.004


def measure_hand(body):
    """The right palm turns forward and down, as if resting on a timber."""
    key = body.shape_key_add(name="Measure")
    for i, v in enumerate(body.data.vertices):
        co = v.co
        if co.x > 0.15 and 0.40 < co.z < 0.55 and co.y > -0.03:
            key.data[i].co = co + Vector((0.012, 0.075, -0.05))
    key.value = 0.0


def stills(arm, stem, measure):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.render.resolution_x = 720
    scene.render.resolution_y = 960
    scene.render.film_transparent = False
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.show_object_outline = False
    for obj in bpy.data.objects:
        if "Outline" in obj.name:
            obj.hide_render = True
    world = bpy.data.worlds.new("PaperSky")
    world.color = (0.96, 0.93, 0.86)
    scene.world = world
    cam_data = bpy.data.cameras.new("DesignCam")
    cam_data.lens = 55
    cam = bpy.data.objects.new("DesignCam", cam_data)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    target = Vector((0.0, 0.0, 0.72))
    shots = [("front", (0.0, 2.35, 0.78)), ("three_quarter", (1.15, 1.85, 0.86))]
    if measure:
        shots.append(("measure", (1.25, 1.55, 0.7)))
    folder = OUT / "previews"
    folder.mkdir(parents=True, exist_ok=True)
    for name, loc in shots:
        if name == "measure" and body_key(arm, "Measure"):
            body_key(arm, "Measure").value = 1.0
        cam.location = Vector(loc)
        cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = str(folder / f"{stem}_{name}.png")
        bpy.ops.render.render(write_still=True)
        if name == "measure" and body_key(arm, "Measure"):
            body_key(arm, "Measure").value = 0.0


def body_key(arm, name):
    body = next(o for o in arm.children if o.name.endswith("Body"))
    keys = body.data.shape_keys
    if keys is None:
        return None
    return keys.key_blocks.get(name)


def build_person(kind):
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / ".gdignore").touch()
    ww.old.clear()
    ww.PARTS.clear()
    original_profile = ww.profile
    ww.profile = lambda name, rings, mat, sides=18, steps=2: original_profile(name, rings, mat, sides, steps)
    ww.blob = lambda name, pos, scale, mat: ww.old.make_soft_blob(name, pos, scale, mat, subdiv=2, j=0)
    ww.build_geometry()
    noah = kind == "noah"
    prefix = "N" if noah else "W"
    palette = {
        "Skin": ww.old.paper_mat(prefix + "_Skin", (0.84, 0.62, 0.46) if noah else (0.86, 0.66, 0.52), 0.16),
        "Tunic": ww.old.paper_mat(prefix + "_Tunic", (0.62, 0.32, 0.16) if noah else (0.28, 0.50, 0.48), 0.28),
        "Trousers": ww.old.paper_mat(prefix + "_Cream", (0.93, 0.86, 0.72), 0.25),
        "Sash": ww.old.paper_mat(prefix + "_Belt" if noah else prefix + "_Sand",
                                 (0.18, 0.12, 0.08) if noah else (0.82, 0.70, 0.48), 0.22),
        "Hair": ww.old.paper_mat(prefix + "_Hair", (0.42, 0.34, 0.28) if noah else (0.28, 0.18, 0.12), 0.25),
        "Eye": ww.old.paper_mat(prefix + "_Eye", (0.09, 0.05, 0.03), 0),
        "Mouth": ww.old.paper_mat(prefix + "_Mouth", (0.45, 0.22, 0.16), 0),
    }
    leather = ww.old.paper_mat(prefix + "_Leather", (0.25, 0.15, 0.08), 0.22)
    kept = []
    for obj, outlined in ww.PARTS:
        if obj.name.startswith(("HairCap", "SideLock", "Shoe_")):
            bpy.data.objects.remove(obj, do_unlink=True)
            continue
        david.rematerialize(obj, palette)
        kept.append((obj, outlined))
    ww.PARTS[:] = kept
    shape_body(kind)
    shape_face(kind)
    for obj, outlined in david.build_sandals(palette["Skin"], leather):
        side = "L" if obj.name.endswith("L") else "R"
        ww.weighted(obj, ww.fixed("Shin_" + side), outlined)
    hair = palette["Hair"]
    ww.weighted(work_hair(hair, tied=not noah), ww.fixed("Head"))
    if noah:
        ww.weighted(beard(hair), ww.fixed("Head"))
        ww.weighted(belt(palette["Sash"]), ww.torso_weights, False)
    else:
        ww.weighted(bun(hair), ww.fixed("Head"), False)
    highlight = ww.old.paper_mat(prefix + "_Catchlight", (0.98, 0.93, 0.82), 0)
    for side, sign in [("L", -1), ("R", 1)]:
        ww.weighted(ww.blob("Catchlight_" + side, (sign * 0.047, 0.109, 0.981),
                            (0.0025, 0.0015, 0.0025), highlight), ww.fixed("Head"), False)
    if not noah:
        for obj, _outlined in ww.PARTS:
            for v in obj.data.vertices:
                v.co.z *= 0.96
    for obj, _outlined in ww.PARTS:
        if len(obj.data.vertices) > 100 and obj.name != "Smile":
            bpy.context.view_layer.objects.active = obj
            decimate = obj.modifiers.new("Tablet budget", "DECIMATE")
            decimate.ratio = 0.40
            bpy.ops.object.modifier_apply(modifier=decimate.name)
    arm = ww.rig()
    stem = "noah_v1" if noah else "noahs_wife_v1"
    arm.name = "NoahRig" if noah else "NoahsWifeRig"
    body = next(o for o in arm.children if o.name == "WonderWalker_Body")
    hull = next(o for o in arm.children if o.name == "WonderWalker_Outline")
    body.name = "NoahBody" if noah else "NoahsWifeBody"
    hull.name = "NoahOutline" if noah else "NoahsWifeOutline"
    facial_shapes(body, prefix)
    if noah:
        measure_hand(body)
    stills(arm, stem, measure=noah)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT / f"{stem}.blend"))
    bpy.ops.object.select_all(action="DESELECT")
    for obj in (arm, body, hull):
        obj.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.export_scene.gltf(
        filepath=str(OUT / f"{stem}.glb"), export_format="GLB", use_selection=True,
        export_apply=False, export_morph=True, export_skins=True,
        export_animations=False, export_yup=True)
    print("DESIGN_MODEL_COMPLETE", stem, len(body.data.vertices))


if __name__ == "__main__":
    build_person("noah")
