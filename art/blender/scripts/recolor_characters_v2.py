"""
Little Light — recolor pass for contrast vs sage valley hills.
- wonder_walker_v3.glb → wonder_walker_v4.glb
- david_mentor_v2.glb → david_mentor_v3.glb
- wonder_items_v2.glb → wonder_items_v3.glb (+ slight lamb/staff scale)
Preserves paper_grain via MixRGB multiply on Principled Base Color.
"""
import bpy
import os

WW_IN = os.environ.get("LL_WW_IN", r"C:\Users\onesa\wonder-walker\wonder_walker_v3.glb")
WW_OUT = os.environ.get("LL_WW_OUT", r"C:\Users\onesa\wonder-walker\wonder_walker_v4.glb")
DAVID_IN = os.environ.get("LL_DAVID_IN", r"C:\Users\onesa\wonder-walker\david_mentor_v2.glb")
DAVID_OUT = os.environ.get("LL_DAVID_OUT", r"C:\Users\onesa\wonder-walker\david_mentor_v3.glb")
ITEMS_IN = os.environ.get("LL_ITEMS_IN", r"C:\Users\onesa\wonder-walker\wonder_items_v2.glb")
ITEMS_OUT = os.environ.get("LL_ITEMS_OUT", r"C:\Users\onesa\wonder-walker\wonder_items_v3.glb")
GRAIN = os.environ.get("LL_PAPER_GRAIN", r"C:\Users\onesa\wonder-walker\paper_grain.png")

# Wonder-Walker: warm skin, soft blue tunic, coral/red sash
WW_COLORS = {
    "Skin": (0.86, 0.68, 0.52, 1.0),
    "Tunic": (0.42, 0.58, 0.78, 1.0),   # soft blue
    "Sash": (0.88, 0.32, 0.28, 1.0),    # coral / red
    "Hair": (0.22, 0.12, 0.08, 1.0),
    "Shoe": (0.32, 0.20, 0.14, 1.0),
    "Eye": (0.08, 0.08, 0.10, 1.0),
    "OL": (0.05, 0.04, 0.04, 1.0),
}

# David: ochre/gold tunic, green sash
DAVID_COLORS = {
    "D_Skin": (0.84, 0.66, 0.50, 1.0),
    "D_Tunic": (0.82, 0.62, 0.28, 1.0),  # ochre / gold
    "D_Sash": (0.28, 0.52, 0.32, 1.0),   # green
    "D_Hair": (0.18, 0.10, 0.07, 1.0),
    "D_Sandal": (0.35, 0.22, 0.14, 1.0),
    "D_Eye": (0.08, 0.08, 0.10, 1.0),
    "D_Sheep": (0.90, 0.86, 0.78, 1.0),
    "D_OL": (0.05, 0.04, 0.04, 1.0),
}

# Wonder Items
ITEM_COLORS = {
    "I_Wool": (0.93, 0.90, 0.84, 1.0),     # cream wool
    "I_Snout": (0.92, 0.62, 0.68, 1.0),    # soft pink snout
    "I_Wood": (0.42, 0.26, 0.14, 1.0),     # rich brown staff
    "I_Rock": (0.52, 0.58, 0.66, 1.0),     # cool grey-blue stone
    "I_OL": (0.05, 0.04, 0.04, 1.0),
}

ITEM_SCALE = float(os.environ.get("LL_ITEMS_SCALE", "1.4"))


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.images, bpy.data.armatures, bpy.data.actions):
        for b in list(block):
            if b.users == 0:
                block.remove(b)



def _bake_tinted_grain(name, color, grain_path, mix_fac=0.4):
    import numpy as np
    size = 256
    if grain_path and os.path.isfile(grain_path):
        src = bpy.data.images.load(grain_path)
        src.scale(size, size)
        pix = np.array(src.pixels[:], dtype=np.float32).reshape(size, size, 4)
    else:
        pix = np.ones((size, size, 4), dtype=np.float32)
    grain = pix[:, :, :3] * mix_fac + (1.0 - mix_fac)
    tint = np.array(color[:3], dtype=np.float32).reshape(1, 1, 3)
    rgb = np.clip(grain * tint, 0.0, 1.0)
    alpha = np.ones((size, size, 1), dtype=np.float32)
    out = np.concatenate([rgb, alpha], axis=2).reshape(-1)
    img = bpy.data.images.new(f"Tint_{name}", width=size, height=size, alpha=True)
    img.pixels = out.tolist()
    img.pack()
    return img


def tint_material(mat, color, mix_fac=0.9):
    if not mat or not mat.use_nodes:
        return
    nt = mat.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf = next((n for n in nodes if n.type == "BSDF_PRINCIPLED"), None)
    if not bsdf:
        return
    for link in list(bsdf.inputs["Base Color"].links):
        links.remove(link)
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = _bake_tinted_grain(mat.name, color, GRAIN, mix_fac=mix_fac)
    tex.interpolation = "Closest"
    mapn = next((n for n in nodes if n.type == "MAPPING"), None)
    if mapn is None:
        uv = nodes.new("ShaderNodeTexCoord")
        mapn = nodes.new("ShaderNodeMapping")
        mapn.inputs["Scale"].default_value = (3.2, 3.2, 3.2)
        links.new(uv.outputs["UV"], mapn.inputs["Vector"])
    links.new(mapn.outputs["Vector"], tex.inputs["Vector"])
    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.93
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.05
    mat.diffuse_color = color



def apply_colors(color_map):
    for name, color in color_map.items():
        mat = bpy.data.materials.get(name)
        if mat:
            tint_material(mat, color)
            print("RECOLOR", name, color)
        else:
            print("MISSING MAT", name)


def export_glb(path):
    d = os.path.dirname(path)
    if d:
        os.makedirs(d, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        export_apply=True,
        export_texcoords=True,
        export_normals=True,
        export_materials="EXPORT",
        export_animations=True,
    )
    print("WROTE", path)


def process_one(in_path, out_path, colors, scale_names=None, scale=1.0):
    clear_scene()
    if not os.path.isfile(in_path):
        raise FileNotFoundError(in_path)
    bpy.ops.import_scene.gltf(filepath=in_path)
    apply_colors(colors)
    if scale_names and scale != 1.0:
        for o in bpy.data.objects:
            base = o.name.replace("_Outline", "")
            if any(base.startswith(n) or base == n for n in scale_names):
                o.scale = (o.scale[0] * scale, o.scale[1] * scale, o.scale[2] * scale)
                print("SCALE", o.name, scale)
        # Apply scale so export bakes it
        bpy.ops.object.select_all(action="DESELECT")
        for o in bpy.data.objects:
            if o.type == "MESH":
                o.select_set(True)
                bpy.context.view_layer.objects.active = o
                bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
                o.select_set(False)
    export_glb(out_path)


def main():
    process_one(WW_IN, WW_OUT, WW_COLORS)
    process_one(DAVID_IN, DAVID_OUT, DAVID_COLORS)
    process_one(
        ITEMS_IN,
        ITEMS_OUT,
        ITEM_COLORS,
        scale_names=("WonderItem_Lamb", "WonderItem_Staff", "WonderItem_Stone"),
        scale=ITEM_SCALE,
    )
    print("DONE recolor_characters_v2")


if __name__ == "__main__":
    main()
