"""David v12: young shepherd matching Walker v13's connected organic forms.

Uses Walker v5 geometry/material helpers; does not change the Walker or items.
Run with Blender --background --python this_file.py. Outputs a static GLB and
editable .blend under LITTLE_LIGHT_ART_OUT or art/blender/output. Front is
Blender +Y / Godot -Z. The scene's ChapterDirector handles turning/nodding.
"""
import importlib.util
import math
from pathlib import Path
import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("walker_shapes", HERE / "generate_wonder_walker_v5.py")
ww = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ww)
OUT = ww.OUT


def rematerialize(obj, palette):
    for slot in obj.material_slots:
        key = slot.material.name.removeprefix("WW_")
        if key in palette:
            slot.material = palette[key]


def hair_cap(hair):
    """One closed scalp mass, shallow waves and a clear forehead hairline."""
    verts, faces = [], []
    sides, rows = 64, 24
    for j in range(rows+1):
        for k in range(sides):
            theta = 2*math.pi*k/sides
            front = max(0,math.sin(theta))
            edge = 2.10 - .76*front**2 + .055*math.sin(theta*7+.8)
            phi = .006+(edge-.006)*j/rows
            # Low broad ripples, rather than stacked sphere clumps.
            wave = 1 + .025*math.sin(theta*7+phi*2.0)*math.sin(phi)
            verts.append((.160*math.sin(phi)*math.cos(theta)*wave,
                          -.02+.151*math.sin(phi)*math.sin(theta)*wave,
                          1.006+.166*math.cos(phi)*wave))
    for j in range(rows):
        for k in range(sides):
            a=j*sides+k; b=j*sides+(k+1)%sides
            faces.append((a,b,b+sides,a+sides))
    faces.append(tuple(reversed(range(sides))))
    obj=ww.mesh_object("David_Hair",verts,faces,hair)
    bpy.context.view_layer.objects.active=obj
    mod=obj.modifiers.new("Hair edge","SOLIDIFY"); mod.thickness=.006
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def build_sandals(skin,leather):
    parts=[]
    for side,s in (("L",-1),("R",1)):
        x=s*.081
        foot=ww.profile("David_Foot_"+side,[
            (.027,x,.038,.045,.079),(.040,x,.038,.050,.087),
            (.060,x,.029,.046,.078),(.080,x,.004,.031,.039),
            (.107,x,-.005,.029,.031)],skin)
        sole=ww.profile("David_SandalSole_"+side,[
            (.011,x,.038,.047,.084),(.017,x,.038,.054,.094),
            (.026,x,.038,.054,.094),(.030,x,.038,.049,.087)],leather)
        # Broad strips hug the instep; their side ends disappear into the sole.
        verts,faces=[],[]
        for y in (.052,.077):
            for i in range(15):
                angle=math.pi*i/14
                verts.append((x+.048*math.cos(angle),y,.029+.039*math.sin(angle)))
        for i in range(14): faces.append((i,i+1,i+16,i+15))
        strap=ww.mesh_object("David_SandalStrap_"+side,verts,faces,leather)
        bpy.context.view_layer.objects.active=strap
        solid=strap.modifiers.new("Leather thickness","SOLIDIFY"); solid.thickness=.003
        bpy.ops.object.modifier_apply(modifier=solid.name)
        parts.extend([(foot,True),(sole,True),(strap,False)])
    return parts


def build_lamb():
    """A soft, compact companion; separate from David's body and face."""
    wool=ww.old.paper_mat("D_LambWool",(.88,.83,.70),.22)
    skin=ww.old.paper_mat("D_LambFace",(.48,.35,.24),.12)
    hoof=ww.old.paper_mat("D_LambHoof",(.20,.135,.085),.12)
    eye=ww.old.paper_mat("D_LambEye",(.038,.027,.020),0)
    origin=Vector((.39,.015,.008))
    def p(x,y,z): return tuple(origin+Vector((x,y,z)))
    forms=[ww.blob("LambBody",p(0,-.01,.18),(.11,.16,.12),wool)]
    for x,y,z,r in [(-.055,.055,.255,.055),(.053,.045,.26,.055),
                    (-.05,-.06,.255,.057),(.05,-.07,.249,.055),
                    (0,-.12,.23,.052),(0,0,.277,.06)]:
        forms.append(ww.blob("Wool",p(x,y,z),(r,r,r*.8),wool))
    body=ww.fuse("CompanionLamb_Wool",forms,wool,.004)
    face=ww.blob("CompanionLamb_Face",p(0,.145,.238),(.062,.065,.079),skin)
    parts=[(body,True),(face,True)]
    for side,s in (("L",-1),("R",1)):
        parts.append((ww.blob("LambEar_"+side,p(s*.073,.136,.262),(.041,.018,.022),skin),True))
        parts.append((ww.blob("LambEye_"+side,p(s*.030,.202,.253),(.007,.004,.009),eye),False))
    for i,(x,y) in enumerate([(-.062,-.095),(.062,-.095),(-.062,.087),(.062,.087)]):
        parts.append((ww.profile("LambLeg_%d"%i,[(.028,origin.x+x,origin.y+y,.017,.018),
            (.095,origin.x+x,origin.y+y,.018,.02),(.17,origin.x+x,origin.y+y,.025,.025)],skin),True))
        parts.append((ww.blob("LambHoof_%d"%i,p(x,y,.021),(.022,.025,.021),hoof),True))
    parts.append((ww.blob("LambTail",p(0,-.167,.195),(.032,.045,.038),wool),True))
    return parts


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    (OUT/".gdignore").touch()
    ww.old.clear()
    ww.PARTS.clear()
    ww.build_geometry()
    palette={
        "Skin":ww.old.paper_mat("D_Skin",(.79,.52,.32),.16),
        "Tunic":ww.old.paper_mat("D_Tunic",(.76,.54,.22),.28),
        "Sash":ww.old.paper_mat("D_Sash",(.27,.40,.21),.25),
        "Hair":ww.old.paper_mat("D_Hair",(.15,.065,.025),.25),
        "Eye":ww.old.paper_mat("D_Eye",(.045,.028,.017),0),
        "Mouth":ww.old.paper_mat("D_Mouth",(.30,.10,.053),0),
    }
    leather=ww.old.paper_mat("D_Leather",(.27,.15,.069),.22)
    parts=[]
    for obj,outlined in ww.PARTS:
        if obj.name.startswith(("HairCap","SideLock","Shoe_")):
            bpy.data.objects.remove(obj,do_unlink=True)
            continue
        rematerialize(obj,palette)
        if obj.name.startswith("TrouserLeg"):
            obj.data.materials.clear(); obj.data.materials.append(palette["Skin"])
            for poly in obj.data.polygons: poly.material_index=0
        if obj.name=="Tunic":
            # Longer shepherd's tunic, ending above the knee.
            for v in obj.data.vertices:
                v.co.z -= .050*(1-ww.smoothstep(.41,.505,v.co.z))
        obj.name="David_"+obj.name
        parts.append((obj,outlined))
    parts.append((hair_cap(palette["Hair"]),True))
    parts.extend(build_sandals(palette["Skin"],leather))
    # A small leather sling pouch on his hip, kept well below the face.
    pouch=ww.blob("David_SlingPouch",(.127,.064,.475),(.043,.026,.054),leather)
    parts.append((pouch,True))
    # Slightly taller than the Walker, retaining the shared visual language.
    for obj,_ in parts:
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True); bpy.context.view_layer.objects.active=obj
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        for v in obj.data.vertices:
            v.co.x*=1.04
            v.co.z+=.060*ww.smoothstep(.06,.84,v.co.z)
        obj.vertex_groups.clear()
        ww.old.uv(obj)
    # The companion lamb is built, UV'd and outlined separately from David's own
    # parts, and joined into its own two objects rather than folded into his body
    # mesh -- so it stays a separate node in the exported scene that a runtime
    # script (companion_sheep_life.gd) can move on its own: a little breathing
    # sway and a glance toward the Wonder-Walker, the same idea as the collectible
    # lamb's life script, without needing it welded into David's single mesh.
    lamb_parts=build_lamb()
    bodies,hulls=[],[]
    for obj,outlined in parts:
        ww.old.uv(obj)
        bodies.append(obj)
        if outlined:
            hull=ww.old.single_skin_outline(obj,.0026,(.07,.043,.026))
            for face in hull.data.polygons: face.use_smooth=True
            hulls.append(hull)
    lamb_bodies,lamb_hulls=[],[]
    for obj,outlined in lamb_parts:
        ww.old.uv(obj)
        lamb_bodies.append(obj)
        if outlined:
            hull=ww.old.single_skin_outline(obj,.0026,(.07,.043,.026))
            for face in hull.data.polygons: face.use_smooth=True
            lamb_hulls.append(hull)
    body=ww.old.join(bodies,"David_Mentor")
    hull=ww.old.join(hulls,"David_Mentor_Outline")
    lamb_body=ww.old.join(lamb_bodies,"David_CompanionLamb")
    lamb_hull=ww.old.join(lamb_hulls,"David_CompanionLamb_Outline")
    # The rigless model turns around its feet, not its mesh's former center.
    bpy.context.scene.cursor.location=(0,0,0)
    for obj in (body,hull):
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True); bpy.context.view_layer.objects.active=obj
        bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    # The lamb pivots around where it stands (build_lamb()'s own origin point,
    # at the ground), not David's feet, so a gentle turn-to-look reads as the
    # lamb turning in place rather than swinging around David's position.
    bpy.context.scene.cursor.location=(.39,.015,0.0)
    for obj in (lamb_body,lamb_hull):
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True); bpy.context.view_layer.objects.active=obj
        bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    hull.data.materials[0].name="D_OutlineInk"
    assert hull.data.materials[0].use_backface_culling
    assert lamb_hull.data.materials[0].name=="D_OutlineInk"
    assert not any(any(term in m.name.lower() for term in ("teeth","tongue","interior"))
                   for m in body.data.materials)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"david_mentor_v13.blend"))
    bpy.ops.object.select_all(action="DESELECT")
    for obj in (body,hull,lamb_body,lamb_hull):
        obj.select_set(True)
    bpy.context.view_layer.objects.active=body
    bpy.ops.export_scene.gltf(filepath=str(OUT/"david_mentor_v13.glb"),export_format="GLB",
        use_selection=True,export_apply=True,export_yup=True)
    print("DAVID_V13_COMPLETE",len(body.data.vertices),"body vertices",
          len(lamb_body.data.vertices),"companion lamb vertices")


if __name__=="__main__": main()
