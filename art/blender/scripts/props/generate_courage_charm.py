"""
Little Light — Courage charm + Virtue Bracelet (CHARM_AWARD ceremony art).
Papercraft style matching David/Wonder Items v6: flat paper-grain materials,
handmade jitter, single-skin inverted-hull outline. Blender 4.x / 5.x.

Replaces the runtime-primitive placeholder built in scripts/charm_award.gd
(_build_placeholders(): a bare TorusMesh + CylinderMesh) with an authored
GLB. The charm keeps a single material slot so the game script can still
grab it at runtime and drive the gold "snap" emission pulse.

Run headless:
    LITTLE_LIGHT_ART_OUT=$PWD/art/blender/output \
    blender --background --python art/blender/scripts/props/generate_courage_charm.py
"""
import bpy
import bmesh
import math
import numpy as np
import os
import random
from pathlib import Path
from mathutils import Vector, Euler

OUT = os.environ.get("LITTLE_LIGHT_ART_OUT", str(Path(__file__).resolve().parents[2] / "output"))
GRAIN_CANDIDATES = [
    os.path.join(OUT, "paper_grain.png"),
    str(Path(__file__).resolve().parents[2] / "assets" / "textures" / "paper_grain.png"),
]
GRAIN = next((p for p in GRAIN_CANDIDATES if os.path.exists(p)), None)

CHARM_GLB = os.path.join(OUT, "courage_charm_v1.glb")
PREV = os.path.join(OUT, "previews")

rng = random.Random(37)


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


def jitter(o, amt=0.006):
    bm = bmesh.new()
    bm.from_mesh(o.data)
    for v in bm.verts:
        v.co += Vector((rng.uniform(-amt, amt), rng.uniform(-amt, amt), rng.uniform(-amt, amt)))
    bm.to_mesh(o.data)
    bm.free()
    o.data.update()


def _tinted_grain_image(name, color, mix_fac):
    """Bake color x grain into actual pixels (256x256) instead of a Blender
    node-graph multiply. Blender's glTF exporter only faithfully exports a
    single Image Texture wired straight to Base Color — an RGB+MixRGB graph
    (what earlier generators used) gets dropped, leaving Godot with a plain
    white/grain-only albedo and none of the intended color. See
    recolor_characters_v3.py's `_bake_tinted_grain`, which this mirrors.
    """
    size = 256
    if GRAIN:
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


def paper(name, color, mix=0.35, roughness=0.75, metallic=0.0):
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
    mp.inputs["Scale"].default_value = (4.0, 4.0, 4.0)
    links.new(tc.outputs["UV"], mp.inputs["Vector"])
    links.new(mp.outputs["Vector"], tex.inputs["Vector"])
    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mat.diffuse_color = (*color, 1.0)
    return mat


def soft_blob(name, loc, scale, mat, subdiv=2, j=0.003):
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


def ring(name, major_r, minor_r, mat, major_seg=24, minor_seg=8, j=0.003):
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major_r, minor_radius=minor_r,
        major_segments=major_seg, minor_segments=minor_seg,
    )
    o = bpy.context.active_object
    o.name = name
    jitter(o, j)
    if mat:
        o.data.materials.append(mat)
    uv(o)
    return flat(o)


def disc(name, radius, height, mat, segments=14, j=0.0025):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=height, vertices=segments)
    o = bpy.context.active_object
    o.name = name
    jitter(o, j)
    if mat:
        o.data.materials.append(mat)
    uv(o)
    return flat(o)


def cone(name, loc, radius, height, mat, segments=10, j=0.002):
    bpy.ops.mesh.primitive_cone_add(vertices=segments, radius1=radius, depth=height, location=loc)
    o = bpy.context.active_object
    o.name = name
    jitter(o, j)
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


def origin_at(obj, loc):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.context.scene.cursor.location = loc
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")


def outline_material():
    mat = bpy.data.materials.get("Charm_OL")
    if mat:
        return mat
    mat = paper("Charm_OL", (0.05, 0.05, 0.06), 0.0, roughness=1.0)
    mat.use_backface_culling = True
    return mat


def single_skin_outline(base, thickness=0.0028):
    """A single-skin inverted hull (grow along normals + flip winding),
    matching fix_outlines_v6.py's approach — a Solidify shell renders as an
    opaque lid in Godot, this does not."""
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
    hull.data.materials.append(outline_material())
    for p in hull.data.polygons:
        p.use_smooth = False
    return hull


def build_bracelet():
    cord_mat = paper("Bracelet_Cord", (0.26, 0.15, 0.07), 0.45, roughness=0.9)
    gold_a = paper("Bracelet_GoldA", (0.88, 0.64, 0.16), 0.24, roughness=0.5, metallic=0.15)
    gold_b = paper("Bracelet_GoldB", (0.68, 0.47, 0.11), 0.28, roughness=0.55, metallic=0.15)

    major_r = 0.155
    cord = ring("Cord", major_r, 0.017, cord_mat, j=0.004)

    parts = [cord]
    bead_count = 10
    for i in range(bead_count):
        ang = (i / bead_count) * math.tau
        # Beads sit proud of the cord, alternating two gold tones for a
        # handmade woven-bead look rather than a uniform smooth band.
        r = major_r + 0.006
        loc = (math.cos(ang) * r, math.sin(ang) * r, 0.0)
        mat = gold_a if i % 2 == 0 else gold_b
        sc = 0.026 if i % 2 == 0 else 0.021
        parts.append(soft_blob(f"Bead{i}", loc, (sc, sc, sc), mat, 2, 0.0025))

    body = join(parts, "VirtueBracelet")
    origin_at(body, (0, 0, 0))
    ol = single_skin_outline(body, 0.0022)
    # Torus/bead ring is built flat (normal along local Z); tilt it to the
    # same near-vertical, camera-facing angle the old placeholder used.
    for o in (body, ol):
        o.rotation_euler = Euler((math.radians(70.0), 0.0, 0.0))
        bpy.context.view_layer.objects.active = o
        o.select_set(True)
        bpy.ops.object.transform_apply(rotation=True)
    return body, ol


def build_charm():
    gold = paper("Charm_Gold", (0.92, 0.70, 0.20), 0.18, roughness=0.45, metallic=0.18)

    base = disc("CharmBase", 0.075, 0.026, gold, segments=14, j=0.0025)
    rim = ring("CharmRim", 0.072, 0.009, gold, major_seg=18, minor_seg=6, j=0.0015)
    rim.rotation_euler = Euler((math.radians(90.0), 0.0, 0.0))
    bpy.context.view_layer.objects.active = rim
    rim.select_set(True)
    bpy.ops.object.transform_apply(rotation=True)
    # Small raised flame/light emblem at the charm's center — a single cone,
    # reads as "little light" at this scale without needing a custom curve.
    flame = cone("CharmFlame", (0.0, 0.0, 0.02), 0.026, 0.05, gold, segments=9, j=0.0015)

    body = join([base, rim, flame], "CourageCharm")
    origin_at(body, (0, 0, 0))
    ol = single_skin_outline(body, 0.0018)
    return body, ol


def export(path, objs):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.gltf(
        filepath=path, export_format="GLB", use_selection=True,
        export_apply=True, export_yup=True,
    )
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
    bpy.ops.object.light_add(type="SUN", location=(3, -3, 6))
    bpy.context.active_object.data.energy = 3.2
    bpy.context.active_object.rotation_euler = Euler((0.7, 0.2, 0.3))
    bpy.ops.object.light_add(type="AREA", location=(-2, 1.5, 2))
    bpy.context.active_object.data.energy = 35
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH" and not o.hide_render]
    min_c = Vector((1e9,) * 3)
    max_c = Vector((-1e9,) * 3)
    for obj in meshes:
        for corner in obj.bound_box:
            w = obj.matrix_world @ Vector(corner)
            min_c = Vector(tuple(min(min_c[i], w[i]) for i in range(3)))
            max_c = Vector(tuple(max(max_c[i], w[i]) for i in range(3)))
    center = (min_c + max_c) * 0.5
    size = max((max_c - min_c).length, 0.2)
    for o in list(bpy.data.objects):
        if o.type == "CAMERA":
            bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.object.camera_add(location=(center.x + size * 1.4, center.y - size * 1.9, center.z + size * 0.8))
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
    s.render.resolution_y = 768
    s.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("preview", path)


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PREV, exist_ok=True)

    clear()
    bracelet, bracelet_ol = build_bracelet()
    bracelet.location = (0.0, 0.0, 0.0)
    charm, charm_ol = build_charm()
    # Lay the charm out beside the bracelet in edit space; charm_award.gd
    # repositions both at runtime, so only relative art matters here.
    charm.location = (0.35, 0.0, 0.0)
    charm_ol.location = (0.35, 0.0, 0.0)

    export(CHARM_GLB, [bracelet, bracelet_ol, charm, charm_ol])
    preview(os.path.join(PREV, "courage_charm_v1.png"))
    print("courage charm v1 done")


if __name__ == "__main__":
    main()
