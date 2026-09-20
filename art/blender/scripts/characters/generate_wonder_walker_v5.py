"""Walker v13: continuous organic surfaces and deterministic skin weights.

Run with Blender --background --python this_file.py from the repository root.
Writes the editable .blend and GLB to LITTLE_LIGHT_ART_OUT or art/blender/output.
Uses v4's baked paper materials, but replaces its geometry, rig and animation.
Front is Blender +Y / Godot -Z. No automatic bone-heat weights are used.
"""
import importlib.util
import math
import os
from pathlib import Path
import bpy
import bmesh
from mathutils import Vector

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("walker_materials", HERE / "generate_wonder_walker_v4.py")
old = importlib.util.module_from_spec(spec)
spec.loader.exec_module(old)
OUT = Path(old.OUT)
PARTS = []
# How much of the fused surfaces is kept after the voxel remesh. Lower is lighter for the game;
# David (generate_david_mentor_v4.py) uses the same fuse(), so this sets his weight too.
# 0.32 (the old value) left about 30k triangles of skin per character, which at the game camera is
# a figure roughly 100 px tall. 0.06 looks the same in the tabletop view, the dialogue close-up and
# mid-stride (compared side by side) and roughly halves both characters and their outline hulls.
GAME_MESH_RATIO = float(os.environ.get("LL_GAME_MESH_RATIO", "0.06"))
HIP, KNEE, SHOULDER, ELBOW, WRIST = 0.465, 0.265, 0.766, 0.623, 0.495


def smoothstep(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def mesh_object(name, verts, faces, material):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    for face in mesh.polygons:
        face.use_smooth = True
    return obj


def profile(name, rings, material, sides=32, steps=3):
    """One continuous surface: z, center-x, center-y, width-radius, depth-radius.

    Catmull-Rom profile interpolation supplies shoulder slopes, muscle taper,
    wrists and palms without separate cylinders or joint spheres.
    """
    rows = []
    for i in range(len(rings) - 1):
        p0, p1 = rings[max(0, i - 1)], rings[i]
        p2, p3 = rings[i + 1], rings[min(len(rings) - 1, i + 2)]
        for j in range(steps):
            t = j / steps
            row = [0.5 * ((2*b) + (-a+c)*t + (2*a-5*b+4*c-d)*t*t + (-a+3*b-3*c+d)*t*t*t)
                   for a, b, c, d in zip(p0, p1, p2, p3)]
            row[3], row[4] = max(0.001, row[3]), max(0.001, row[4])
            rows.append(row)
    rows.append(rings[-1])
    verts, faces = [], []
    for z, cx, cy, rx, ry in rows:
        for k in range(sides):
            t = 2 * math.pi * k / sides
            # Broad, quiet surface variation; no per-vertex random lumps.
            grain = 1 + 0.007 * math.sin(t * 3 + z * 12)
            verts.append((cx + rx * math.cos(t) * grain, cy + ry * math.sin(t) * grain, z))
    for j in range(len(rows) - 1):
        for k in range(sides):
            a, b = j*sides+k, j*sides+(k+1)%sides
            faces.append((a, b, b+sides, a+sides))
    faces += [tuple(reversed(range(sides))), tuple((len(rows)-1)*sides+k for k in range(sides))]
    return mesh_object(name, verts, faces, material)


def blob(name, pos, scale, material):
    return old.make_soft_blob(name, pos, scale, material, subdiv=3, j=0)


def fuse(name, objects, material, voxel=0.004):
    """Weld overlapping forms into a single surface before assigning weights."""
    obj = old.join(objects, name)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    remesh = obj.modifiers.new("Weld sculpt forms", "REMESH")
    remesh.mode = "VOXEL"
    remesh.voxel_size = voxel
    remesh.use_smooth_shade = True
    bpy.ops.object.modifier_apply(modifier=remesh.name)
    smooth = obj.modifiers.new("Relax transitions", "SMOOTH")
    smooth.factor, smooth.iterations = 0.65, 4
    bpy.ops.object.modifier_apply(modifier=smooth.name)
    decimate = obj.modifiers.new("Game mesh", "DECIMATE")
    decimate.ratio = GAME_MESH_RATIO
    bpy.ops.object.modifier_apply(modifier=decimate.name)
    obj.data.materials.clear()
    obj.data.materials.append(material)
    for p in obj.data.polygons:
        p.material_index, p.use_smooth = 0, True
    return obj


def weighted(obj, rule, outline=True):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for v in obj.data.vertices:
        weights = {k: w for k, w in rule(v.co).items() if w > 0.00001}
        total = sum(weights.values())
        assert total > 0, (obj.name, v.index)
        for name, weight in weights.items():
            group = obj.vertex_groups.get(name) or obj.vertex_groups.new(name=name)
            group.add([v.index], weight / total, "REPLACE")
    old.uv(obj)
    PARTS.append((obj, outline))
    return obj


def fixed(name):
    return lambda p: {name: 1.0}


def limb_weights(side, arm=True):
    def rule(p):
        joint = ELBOW if arm else KNEE
        above = smoothstep(joint - 0.045, joint + 0.045, p.z)
        return {(('UpperArm_' if arm else 'Thigh_')+side): above,
                (('LowerArm_' if arm else 'Shin_')+side): 1-above}
    return rule


def torso_weights(p):
    side = "L" if p.x < 0 else "R"
    sleeve = smoothstep(0.128, 0.185, abs(p.x)) * smoothstep(0.66, 0.72, p.z)
    chest = smoothstep(0.55, 0.72, p.z)
    hips = 1-smoothstep(0.465, 0.59, p.z)
    return {"UpperArm_"+side: sleeve, "Chest": (1-sleeve)*chest,
            "Hips": (1-sleeve)*(1-chest)*hips, "Spine": (1-sleeve)*(1-chest)*(1-hips)}


def head_weights(p):
    head = smoothstep(0.81, 0.87, p.z)
    return {"Head": head, "Neck": 1-head}


def curve_mesh(name, points, radius, material):
    data = bpy.data.curves.new(name, "CURVE")
    data.dimensions = "3D"
    data.bevel_depth, data.bevel_resolution = radius, 2
    spline = data.splines.new("POLY")
    spline.points.add(len(points)-1)
    for p, xyz in zip(spline.points, points):
        p.co = (*xyz, 1)
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    return bpy.context.object


def build_geometry():
    skin = old.paper_mat("WW_Skin", (0.87, 0.62, 0.43), 0.15)
    tunic = old.paper_mat("WW_Tunic", (0.27, 0.46, 0.69), 0.28)
    pants = old.paper_mat("WW_Trousers", (0.21, 0.29, 0.38), 0.28)
    sash = old.paper_mat("WW_Sash", (0.77, 0.27, 0.20), 0.25)
    shoe = old.paper_mat("WW_Shoe", (0.27, 0.16, 0.095), 0.22)
    hair = old.paper_mat("WW_Hair", (0.18, 0.085, 0.040), 0.25)
    eye = old.paper_mat("WW_Eye", (0.055, 0.032, 0.023), 0)
    mouth = old.paper_mat("WW_Mouth", (0.32, 0.115, 0.072), 0)

    # A tunic with a chest, soft waist, flared hem and sloping shoulders.
    torso = profile("Tunic", [
        (0.402, 0, 0, .136, .083), (.425,0,0,.146,.090),
        (.48,0,0,.143,.091), (.54,0,0,.125,.085), (.61,0,.002,.137,.089),
        (.70,0,0,.147,.096), (.743,0,0,.148,.089),
        (.772,0,0,.128,.078), (.796,0,0,.083,.060),
        (.808,0,0,.057,.047)], tunic)
    sleeves = []
    for side, s in (("L",-1),("R",1)):
        sleeves.append(profile("Sleeve_"+side, [
            (.686,s*.184,0,.045,.045), (.718,s*.175,0,.050,.051),
            (.748,s*.151,0,.054,.053), (.766,s*.132,0,.039,.038)], tunic))
    weighted(fuse("Tunic", [torso]+sleeves, tunic, .005), torso_weights)
    weighted(profile("ClothSash", [(.499,0,0,.141,.093),(.503,0,0,.143,.095),
             (.53,0,0,.135,.092),(.536,0,0,.130,.088)], sash), torso_weights)
    # A small fabric knot and hanging end, rather than a rigid belt ring.
    weighted(blob("SashKnot",(-.105,.072,.514),(.025,.023,.026),sash), torso_weights)
    weighted(profile("SashTail",[(.426,-.098,.088,.018,.008),(.46,-.106,.096,.022,.009),
                     (.512,-.106,.085,.019,.011)],sash), torso_weights)

    for side, s in (("L",-1),("R",1)):
        x = s*.081
        weighted(profile("TrouserLeg_"+side, [
            (.070,x,-.006,.031,.033), (.10,x,-.005,.033,.036),
            (.18,x,-.012,.043,.047), (.245,x,.003,.038,.040),
            (.278,x,.008,.041,.043), (.36,x,0,.053,.056),
            (.443,x,0,.062,.064),(.48,x,0,.050,.056)], pants), limb_weights(side,False))
        weighted(profile("Shoe_"+side, [
            (.012,x,.039,.049,.096),(.022,x,.039,.059,.108),
            (.047,x,.042,.061,.107),(.073,x,.025,.050,.079),
            (.098,x,-.003,.031,.036),(.111,x,-.005,.029,.032)],shoe),fixed("Shin_"+side))
        # Continuous upper arm → elbow → forearm → wrist → flattened palm.
        arm = profile("ArmPalm_"+side, [
            (.426,s*.219,.019,.010,.010), (.438,s*.221,.019,.020,.014),
            (.46,s*.22,.015,.024,.020), (.48,s*.213,.008,.022,.020),
            (.50,s*.211,.002,.017,.019),(.525,s*.21,-.003,.022,.023),
            (.565,s*.209,-.006,.030,.030),(.606,s*.204,-.006,.029,.031),
            (.63,s*.2,-.006,.027,.030),(.668,s*.191,-.004,.034,.036),
            (.709,s*.18,0,.036,.035),(.729,s*.171,0,.031,.033)],skin)
        thumb = blob("Thumb_"+side,(s*.194,.028,.465),(.014,.017,.028),skin)
        arm = fuse("ArmHand_"+side,[arm,thumb],skin,.0032)
        weighted(arm,limb_weights(side))

    # Jaw, cheeks and forehead are all in the same head surface.
    head = profile("Head", [
        (.844,0,.003,.029,.032),(.858,0,.011,.055,.051),
        (.884,0,.012,.091,.075),(.918,0,.002,.119,.095),
        (.95,0,-.001,.134,.108),(.993,0,-.008,.138,.114),
        (1.045,0,-.014,.133,.113),(1.09,0,-.020,.113,.101),
        (1.124,0,-.022,.075,.076),(1.142,0,-.022,.012,.015)],skin)
    neck = profile("Neck",[(.785,0,-.008,.049,.044),(.815,0,-.006,.042,.040),
                           (.851,0,0,.041,.039),(.88,0,.005,.050,.043)],skin)
    nose = blob("Nose",(0,.105,.945),(.021,.026,.030),skin)
    ears = [blob("Ear_"+side,(s*.133,-.003,.947),(.023,.021,.038),skin)
            for side,s in (("L",-1),("R",1))]
    weighted(fuse("FaceNeck",[head,neck,nose]+ears,skin,.0035),head_weights)
    # Small flat eye shapes and brows sit on the face, never on top of hair.
    for side,s in (("L",-1),("R",1)):
        weighted(blob("Eye_"+side,(s*.047,.103,.976),(.009,.006,.013),eye),fixed("Head"),False)
        brow = [(s*(.029+.010*i), .102-.002*i, 1.004+.004*math.sin(i*math.pi/3)) for i in range(4)]
        weighted(curve_mesh("Brow_"+side,brow,.0028,hair),fixed("Head"),False)
    smile = []
    for i in range(13):
        x = -.033 + i*.066/12
        smile.append((x,.095-abs(x)*.12,.907+.010*(x/.033)**2))
    weighted(curve_mesh("Smile",smile,.0025,mouth),fixed("Head"),False)

    # A single scalp cap, with a designed hairline and side-swept fringe.
    verts, faces = [], []
    sides, rows = 64, 20
    for j in range(rows+1):
        for k in range(sides):
            t = 2*math.pi*k/sides
            front = max(0, math.sin(t))
            edge = 2.08 - .83*front**3 + .045*math.sin(5*t+.6)
            phi = .008 + (edge-.008)*j/rows
            r = 1 + .012*math.sin(5*t + phi*2)*math.sin(phi)
            verts.append((.153*math.sin(phi)*math.cos(t)*r,
                          -.018+.144*math.sin(phi)*math.sin(t)*r,
                          1.006+.161*math.cos(phi)*r))
    for j in range(rows):
        for k in range(sides):
            a=j*sides+k; b=j*sides+(k+1)%sides
            faces.append((a,b,b+sides,a+sides))
    faces.append(tuple(reversed(range(sides))))
    cap = mesh_object("HairCap",verts,faces,hair)
    bpy.context.view_layer.objects.active=cap
    solid=cap.modifiers.new("Hair edge thickness","SOLIDIFY")
    solid.thickness=.005
    bpy.ops.object.modifier_apply(modifier=solid.name)
    weighted(cap,fixed("Head"))
    # Quiet locks, same broad hair mass rather than several ball-shaped clumps.
    weighted(blob("SideLock",(-.116,.037,.999),(.025,.034,.058),hair),fixed("Head"))


def rig():
    data = bpy.data.armatures.new("WW_Armature")
    arm = bpy.data.objects.new("WW_Armature",data)
    bpy.context.collection.objects.link(arm)
    bpy.context.view_layer.objects.active=arm
    bpy.ops.object.select_all(action="DESELECT")
    arm.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    def bone(name,start,end,parent=None):
        b=data.edit_bones.new(name); b.head=start; b.tail=end
        if parent: b.parent=data.edit_bones[parent]
    bone("Root",(0,0,0),(0,0,.08))
    bone("Hips",(0,0,HIP),(0,0,.54),"Root")
    bone("Spine",(0,0,.54),(0,0,.7),"Hips")
    bone("Chest",(0,0,.7),(0,0,.796),"Spine")
    bone("Neck",(0,0,.796),(0,0,.861),"Chest")
    bone("Head",(0,0,.861),(0,0,1.125),"Neck")
    for side,s in (("L",-1),("R",1)):
        bone("UpperArm_"+side,(s*.171,0,SHOULDER),(s*.2,-.006,ELBOW),"Chest")
        bone("LowerArm_"+side,(s*.2,-.006,ELBOW),(s*.212,.002,WRIST),"UpperArm_"+side)
        bone("Thigh_"+side,(s*.081,0,HIP),(s*.081,.008,KNEE),"Hips")
        bone("Shin_"+side,(s*.081,.008,KNEE),(s*.081,-.005,.07),"Thigh_"+side)
    bpy.ops.object.mode_set(mode="OBJECT")
    bodies, hulls = [], []
    for obj,outlined in PARTS:
        bodies.append(obj)
        if outlined:
            # Thin contour; inherited vertex groups are identical on the hull.
            hull=old.single_skin_outline(obj,.0028,(.07,.043,.026))
            for p in hull.data.polygons: p.use_smooth=True
            hulls.append(hull)
    for obj in (old.join(bodies,"WonderWalker_Body"),old.join(hulls,"WonderWalker_Outline")):
        obj.parent=arm
        mod=obj.modifiers.new("Armature","ARMATURE"); mod.object=arm
        for v in obj.data.vertices:
            assert abs(sum(g.weight for g in v.groups)-1)<.001, (obj.name,v.index)
        print("SKIN_VALID",obj.name,len(obj.data.vertices),"vertices")
    return arm


def animate(arm):
    scene=bpy.context.scene
    scene.render.fps=12
    scene.frame_start,scene.frame_end=1,13
    arm.animation_data_create()
    action=bpy.data.actions.new("WW_Walk")
    arm.animation_data.action=action
    def rotate(name,frame,xyz):
        b=arm.pose.bones[name]; b.rotation_mode="XYZ"
        b.rotation_euler=[math.radians(v) for v in xyz]
        b.keyframe_insert("rotation_euler",frame=frame)
    for f in range(1,14):
        phase=(f-1)/12*2*math.pi
        stride=math.cos(phase)
        for side,sgn in (("L",1),("R",-1)):
            swing=stride*sgn
            rotate("Thigh_"+side,f,(23*swing,0,0))
            rotate("Shin_"+side,f,(-5-25*max(0,-swing),0,0))
            rotate("UpperArm_"+side,f,(-14*swing,0,0))
            rotate("LowerArm_"+side,f,(10+7*max(0,swing),0,0))
        rotate("Hips",f,(0,2*math.sin(phase),2*stride))
        rotate("Chest",f,(0,-1.4*math.sin(phase),-2.8*stride))
        rotate("Head",f,(0,.7*math.sin(phase),.8*stride))
        hips=arm.pose.bones["Hips"]
        # Hips bone local Y is world Z. Keep bob vertical, not front/back.
        hips.location=(.003*math.sin(phase),.010*math.sin(phase)**2,0)
        hips.keyframe_insert("location",frame=f)
    # Support both legacy and layered Action APIs.
    if hasattr(action,"fcurves"):
        curves=action.fcurves
    else:
        curves=[fc for layer in action.layers for strip in layer.strips
                for bag in strip.channelbags for fc in bag.fcurves]
    for fc in curves:
        for kp in fc.keyframe_points: kp.interpolation="CONSTANT"
    # Keep the lowest shoe on the ground in every baked pose. Evaluating the
    # actual skinned body avoids guessing offsets from bone lengths alone.
    body = next(o for o in arm.children if o.name == "WonderWalker_Body")
    for f in range(1,14):
        scene.frame_set(f)
        evaluated = body.evaluated_get(bpy.context.evaluated_depsgraph_get())
        mesh = evaluated.to_mesh()
        low = min((evaluated.matrix_world @ v.co).z for v in mesh.vertices)
        evaluated.to_mesh_clear()
        hips = arm.pose.bones["Hips"]
        hips.location.y -= low - .006
        hips.keyframe_insert("location",frame=f)
    for fc in curves:
        for kp in fc.keyframe_points: kp.interpolation="CONSTANT"
    scene.frame_set(1)


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    # Intermediate .blend files and review renders must not be auto-imported.
    (OUT/".gdignore").touch()
    old.clear()
    build_geometry()
    arm=rig()
    animate(arm)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"wonder_walker_v13.blend"))
    old.export(arm,str(OUT/"wonder_walker_v13.glb"))
    print("WALKER_V13_COMPLETE")


if __name__=="__main__": main()
