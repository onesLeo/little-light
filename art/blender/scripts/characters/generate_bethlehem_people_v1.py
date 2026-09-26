"""Samuel, Jesse and the younger David, for Chapter 3 (The Beginning, 1 Samuel 16).

All three reuse the shared paper-people build that Noah and his wife use (David's connected
body on the Wonder-Walker skeleton, generate_noah_v1.py), so they walk, blink and talk the
same way in Godot (ark_person.gd / bethlehem_person.gd):

Heights are set in Godot (bethlehem_person.gd scales each model), never by stretching the mesh:
the shared rig's joints sit at fixed heights, so a stretched body would bend a little off its joints.

- Samuel: an older visitor. Cream outer robe over muted blue, grey textured hair and a short
  grey beard, a longer robe (to the knee, so his legs never push through it when he
  walks), and the tallest of the three in the game. Calm rather than stern: no heavy brow.
- Jesse: a sturdy older father in warm brown and olive, greying brown hair, no beard, so he
  never reads as a second Samuel.
- Younger David: clearly the David of Chapters 1-2 (his own skin, golden tunic, olive sash,
  hair cap and sandals), a little shorter and rounder in the cheek.
- Jesse's seven older sons, from two models: "brother" (a grown man with a short beard and
  Jesse's sturdier build, for the three eldest) and "brother_young" (clean-shaven, David's
  build). Their tunic, under-tunic, sash and hair are a light, even paper, so Godot tints
  each of the seven his own colours (jesse_sons.gd) from these two files.

None overwrites another model. Every file lands in LITTLE_LIGHT_ART_OUT (or
art/blender/output); copy just the .glb into assets/.

Run from the repo root, once per person:
  blender --background --python art/blender/scripts/characters/generate_bethlehem_people_v1.py -- samuel
  blender --background --python art/blender/scripts/characters/generate_bethlehem_people_v1.py -- jesse
  blender --background --python art/blender/scripts/characters/generate_bethlehem_people_v1.py -- young_david
  blender --background --python art/blender/scripts/characters/generate_bethlehem_people_v1.py -- brother
  blender --background --python art/blender/scripts/characters/generate_bethlehem_people_v1.py -- brother_young
"""
import importlib.util
import math
import sys
from pathlib import Path
import bpy

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("noah_builder", HERE / "generate_noah_v1.py")
noah = importlib.util.module_from_spec(spec)
spec.loader.exec_module(noah)
david = noah.david
ww = noah.ww
OUT = ww.OUT

# kind -> (file stem, node prefix, material prefix)
PEOPLE = {
    "samuel": ("samuel_v1", "Samuel", "S"),
    "jesse": ("jesse_v1", "Jesse", "J"),
    "young_david": ("young_david_v1", "YoungDavid", "Y"),
    "brother": ("brother_v1", "Brother", "B"),
    "brother_young": ("brother_young_v1", "YoungBrother", "YB"),
    "jonah": ("jonah_v1", "Jonah", "JN"),
}
## The brothers' cloth and hair: a light, even paper that Godot multiplies by each brother's colour.
TINTABLE = (0.93, 0.92, 0.90)


def palette_for(kind, p):
    mat = ww.old.paper_mat
    if kind == "samuel":
        return {
            "Skin": mat(p + "_Skin", (0.80, 0.60, 0.45), 0.16),
            "Tunic": mat(p + "_Robe", (0.91, 0.86, 0.73), 0.28),
            "Trousers": mat(p + "_UnderRobe", (0.42, 0.51, 0.63), 0.25),
            "Sash": mat(p + "_Sash", (0.42, 0.51, 0.63), 0.22),
            "Hair": mat(p + "_Hair", (0.70, 0.69, 0.66), 0.28),
            "Eye": mat(p + "_Eye", (0.09, 0.05, 0.03), 0),
            "Mouth": mat(p + "_Mouth", (0.45, 0.24, 0.18), 0),
        }
    if kind == "jesse":
        return {
            "Skin": mat(p + "_Skin", (0.78, 0.54, 0.36), 0.16),
            "Tunic": mat(p + "_Tunic", (0.52, 0.37, 0.22), 0.28),
            "Trousers": mat(p + "_UnderTunic", (0.52, 0.53, 0.32), 0.25),
            "Sash": mat(p + "_Sash", (0.44, 0.46, 0.25), 0.22),
            "Hair": mat(p + "_Hair", (0.40, 0.34, 0.29), 0.25),
            "Eye": mat(p + "_Eye", (0.08, 0.05, 0.03), 0),
            "Mouth": mat(p + "_Mouth", (0.40, 0.18, 0.12), 0),
        }
    if kind in ("brother", "brother_young"):
        return {
            "Skin": mat(p + "_Skin", (0.78, 0.54, 0.36), 0.16),
            "Tunic": mat(p + "_Tunic", TINTABLE, 0.28),
            "Trousers": mat(p + "_UnderTunic", TINTABLE, 0.25),
            "Sash": mat(p + "_Sash", TINTABLE, 0.22),
            "Hair": mat(p + "_Hair", TINTABLE, 0.25),
            "Eye": mat(p + "_Eye", (0.08, 0.05, 0.03), 0),
            "Mouth": mat(p + "_Mouth", (0.40, 0.18, 0.12), 0),
        }
    if kind == "jonah":
        return {
            "Skin": mat(p + "_Skin", (0.79, 0.55, 0.38), 0.16),
            "Tunic": mat(p + "_Tunic", (0.40, 0.44, 0.66), 0.28),
            "Trousers": mat(p + "_UnderTunic", (0.84, 0.66, 0.36), 0.25),
            "Sash": mat(p + "_Sash", (0.78, 0.58, 0.30), 0.22),
            "Hair": mat(p + "_Hair", (0.18, 0.12, 0.08), 0.25),
            "Eye": mat(p + "_Eye", (0.07, 0.04, 0.025), 0),
            "Mouth": mat(p + "_Mouth", (0.40, 0.18, 0.12), 0),
        }
    # Younger David: David's own colours (generate_david_mentor_v4.py), unchanged.
    return {
        "Skin": mat(p + "_Skin", (0.79, 0.52, 0.32), 0.16),
        "Tunic": mat(p + "_Tunic", (0.76, 0.54, 0.22), 0.28),
        "Trousers": mat(p + "_Skin", (0.79, 0.52, 0.32), 0.16),
        "Sash": mat(p + "_Sash", (0.27, 0.40, 0.21), 0.25),
        "Hair": mat(p + "_Hair", (0.15, 0.065, 0.025), 0.25),
        "Eye": mat(p + "_Eye", (0.045, 0.028, 0.017), 0),
        "Mouth": mat(p + "_Mouth", (0.30, 0.10, 0.053), 0),
    }


def shape(kind):
    """Body and face, before the rig is built (the weights move with the vertices)."""
    for obj, _outlined in ww.PARTS:
        clothing = obj.name in ("Tunic", "ClothSash", "SashKnot", "SashTail")
        for v in obj.data.vertices:
            if kind == "samuel":
                # A robe to mid-shin, not the ankle: the robe follows the hips, so a longer one
                # would let his shins push through it as he walks.
                if obj.name == "Tunic":
                    v.co.z -= 0.12 * (1 - ww.smoothstep(0.41, 0.52, v.co.z))
                    v.co.x *= 1.0 + 0.05 * (1 - ww.smoothstep(0.30, 0.50, v.co.z))
                if v.co.z > 0.82:
                    # An older, longer face, but no heavy brow: calm, not stern.
                    v.co.x *= 0.98
                    if v.co.z < 0.90:
                        v.co.z -= 0.006
            elif kind in ("jesse", "brother"):
                if clothing and 0.40 < v.co.z < 0.80:
                    v.co.x *= 1.12
                    v.co.y *= 1.06
                if v.co.z > 0.82:
                    v.co.x *= 1.06
            elif kind == "brother_young":
                # A tunic to just above the knee, like the eldest's; the face as David's.
                if obj.name == "Tunic":
                    v.co.z -= 0.08 * (1 - ww.smoothstep(0.41, 0.505, v.co.z))
            elif kind == "jonah":
                # A compact, sturdy traveller. Push the existing nose forward without making
                # the whole face long, so his profile remains recognisable at tabletop scale.
                if clothing and 0.40 < v.co.z < 0.78:
                    v.co.x *= 1.04
                if 0.91 < v.co.z < 0.99 and abs(v.co.x) < 0.030 and v.co.y > 0.075:
                    v.co.y += 0.024 * (1.0 - abs(v.co.x) / 0.030)
            else:
                if obj.name == "Tunic":
                    v.co.z -= 0.05 * (1 - ww.smoothstep(0.41, 0.505, v.co.z))
                if v.co.z > 0.84:
                    # Rounder, younger cheeks.
                    cheek = ww.smoothstep(0.86, 0.93, v.co.z) * (1 - ww.smoothstep(0.96, 1.02, v.co.z))
                    v.co.x *= 1.0 + 0.05 * cheek



def curly_hair(material):
    """One dense, irregular field of curls over the whole scalp.

    The earlier version placed two circular rows around an empty crown. From the game camera that
    read as a bald head wearing stacked garlands. These points use a golden-angle distribution over
    a scalp dome instead: no latitude rings, no repeated row height, and plenty of crown/back mass.
    A continuous dark scalp mesh sits underneath so even small gaps between curls read as hair.
    """
    curls = []
    golden = math.pi * (3.0 - math.sqrt(5.0))
    candidates = 58
    for i in range(candidates):
        # Sample from the crown down over the back and sides. The front hairline stops above the
        # eyes, while the back falls lower toward the nape. This asymmetry keeps it natural.
        dome_z = 0.98 - 1.52 * ((i + 0.5) / candidates)
        angle = i * golden + 0.31
        radial = math.sqrt(max(0.0, 1.0 - dome_z * dome_z))
        dx, dy = math.cos(angle) * radial, math.sin(angle) * radial
        if dy > 0.08 and dome_z < -0.05:
            continue
        if abs(dx) > 0.78 and dome_z < -0.32:
            continue
        # Uneven size, depth and oval direction break up the procedural distribution without
        # adding random state that could make regenerated assets drift between builds.
        wobble = math.sin(i * 2.17) * 0.004
        size = 0.034 + 0.004 * math.sin(i * 1.71 + 0.4)
        # The tabletop camera looks down into the face. Taper the forward locks so their outline
        # stays curly without turning into a dark shelf above Jonah's small eyes and brows.
        front_scale = 0.84 if dy > 0.28 else (0.92 if dy > 0.0 else 1.0)
        front_lift = 0.008 if dy > 0.18 else 0.0
        curls.append(ww.blob(
            "Curl_%02d" % i,
            (dx * (0.151 + wobble), -0.016 + dy * (0.143 + wobble),
             1.020 + dome_z * 0.154 + 0.004 * math.cos(i * 1.37) + front_lift),
            (size * front_scale * (1.04 + 0.08 * math.sin(i)),
             size * front_scale * 0.90,
             size * front_scale * (0.94 + 0.07 * math.cos(i * 0.83))), material))
    # Break the front edge into five offset curls. Their heights and depths differ, so this is a
    # hairline rather than another garland around the head.
    hairline = [(-0.105, 0.105, 1.046), (-0.058, 0.117, 1.055), (-0.010, 0.121, 1.049),
                (0.041, 0.116, 1.059), (0.092, 0.107, 1.043)]
    for i, (x, y, z) in enumerate(hairline):
        size = 0.025 + 0.0015 * (i % 2)
        curls.append(ww.blob("HairlineCurl_%d" % i, (x, y, z),
                            (size * 1.1, size * 0.86, size), material))
    return ww.fuse("CurlyHair", curls, material, 0.005)


def compact_beard(material):
    """A neat rounded beard that reads across the jaw instead of as a pointed chin patch."""
    parts = [
        ww.blob("BeardChin", (0.0, 0.062, 0.858), (0.052, 0.025, 0.028), material),
        ww.blob("BeardJawL", (-0.045, 0.052, 0.875), (0.030, 0.019, 0.022), material),
        ww.blob("BeardJawR", (0.045, 0.052, 0.875), (0.030, 0.019, 0.022), material),
        ww.blob("BeardCheekL", (-0.067, 0.042, 0.894), (0.018, 0.014, 0.021), material),
        ww.blob("BeardCheekR", (0.067, 0.042, 0.894), (0.018, 0.014, 0.021), material),
    ]
    return ww.fuse("CompactBeard", parts, material, 0.005)


def build(kind):
    stem, node, p = PEOPLE[kind]
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / ".gdignore").touch()
    ww.old.clear()
    ww.PARTS.clear()
    original_profile = ww.profile
    ww.profile = lambda name, rings, mat, sides=18, steps=2: original_profile(name, rings, mat, sides, steps)
    ww.blob = lambda name, pos, scale, mat: ww.old.make_soft_blob(name, pos, scale, mat, subdiv=2, j=0)
    ww.build_geometry()
    palette = palette_for(kind, p)
    leather = ww.old.paper_mat(p + "_Leather", (0.26, 0.15, 0.08), 0.22)
    kept = []
    for obj, outlined in ww.PARTS:
        if obj.name.startswith(("HairCap", "SideLock", "Shoe_")):
            bpy.data.objects.remove(obj, do_unlink=True)
            continue
        david.rematerialize(obj, palette)
        kept.append((obj, outlined))
    ww.PARTS[:] = kept
    shape(kind)
    for obj, outlined in david.build_sandals(palette["Skin"], leather):
        side = "L" if obj.name.endswith("L") else "R"
        ww.weighted(obj, ww.fixed("Shin_" + side), outlined)
    hair = palette["Hair"]
    if kind == "young_david":
        ww.weighted(david.hair_cap(hair), ww.fixed("Head"))
    elif kind == "jonah":
        scalp = noah.work_hair(hair, tied=False)
        scalp.name = "CurlyScalp"
        # The curls provide the outer ink silhouette; keeping the buried scalp out of the outline
        # hull prevents black seams between overlapping curls while guaranteeing zero bald gaps.
        ww.weighted(scalp, ww.fixed("Head"), False)
        ww.weighted(curly_hair(hair), ww.fixed("Head"))
    else:
        ww.weighted(noah.work_hair(hair, tied=False), ww.fixed("Head"))
    if kind in ("samuel", "brother"):
        ww.weighted(noah.beard(hair), ww.fixed("Head"))
    elif kind == "jonah":
        ww.weighted(compact_beard(hair), ww.fixed("Head"))
    if kind in ("jesse", "brother", "brother_young"):
        ww.weighted(noah.belt(palette["Sash"]), ww.torso_weights, False)
    highlight = ww.old.paper_mat(p + "_Catchlight", (0.98, 0.93, 0.82), 0)
    for side, sign in [("L", -1), ("R", 1)]:
        ww.weighted(ww.blob("Catchlight_" + side, (sign * 0.047, 0.109, 0.981),
                            (0.0025, 0.0015, 0.0025), highlight), ww.fixed("Head"), False)
    # The same tablet budget as Noah: decimate the dense parts, keep the smile.
    for obj, _outlined in ww.PARTS:
        if len(obj.data.vertices) > 100 and obj.name != "Smile":
            bpy.context.view_layer.objects.active = obj
            decimate = obj.modifiers.new("Tablet budget", "DECIMATE")
            decimate.ratio = 0.40
            bpy.ops.object.modifier_apply(modifier=decimate.name)
    arm = ww.rig()
    arm.name = node + "Rig"
    body = next(o for o in arm.children if o.name == "WonderWalker_Body")
    hull = next(o for o in arm.children if o.name == "WonderWalker_Outline")
    body.name = node + "Body"
    hull.name = node + "Outline"
    noah.facial_shapes(body, p)
    noah.stills(arm, stem, measure=False)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT / f"{stem}.blend"))
    bpy.ops.object.select_all(action="DESELECT")
    for obj in (arm, body, hull):
        obj.select_set(True)
    bpy.context.view_layer.objects.active = arm
    # export_apply stays off: it would drop the Blink/Talk shape keys (see the David generator).
    bpy.ops.export_scene.gltf(
        filepath=str(OUT / f"{stem}.glb"), export_format="GLB", use_selection=True,
        export_apply=False, export_morph=True, export_skins=True,
        export_animations=False, export_yup=True)
    tris = sum(len(poly.vertices) - 2 for poly in body.data.polygons)
    print("BETHLEHEM_PERSON_COMPLETE", stem, len(body.data.vertices), "vertices", tris, "triangles")


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else ["samuel"]
    for who in args:
        build(who)
