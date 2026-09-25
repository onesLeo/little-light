extends Node3D
## A person the child meets and hears, from the Blender paper models on the shared
## Wonder-Walker skeleton (art/blender/scripts/characters/): Noah and his wife in the ark,
## Samuel, Jesse and the younger David in Bethlehem. They breathe, blink, talk while their
## line plays, gesture a little, and walk. The block people stay for the crowds.
const CharacterMotion := preload("res://scripts/chapter_two_character_motion.gd")

## who -> the model, its body and outline meshes, and how tall it stands (the models share one
## ~1.1 m base, so height is set here, never by stretching the mesh off its joints).
const PEOPLE := {
	"noah": {"scene": "res://assets/noah_v1.glb", "body": "NoahBody", "outline": "NoahOutline", "scale": 1.2},
	"wife": {"scene": "res://assets/noahs_wife_v1.glb", "body": "NoahsWifeBody", "outline": "NoahsWifeOutline", "scale": 1.2},
	"samuel": {"scene": "res://assets/samuel_v1.glb", "body": "SamuelBody", "outline": "SamuelOutline", "scale": 1.26},
	"jesse": {"scene": "res://assets/jesse_v1.glb", "body": "JesseBody", "outline": "JesseOutline", "scale": 1.22},
	"young_david": {"scene": "res://assets/young_david_v1.glb", "body": "YoungDavidBody", "outline": "YoungDavidOutline", "scale": 1.06},
}

## One of PEOPLE. Set this before the node enters the tree.
var who: String = "noah"
var speaking: bool = false
var walk_amount: float = 0.0
## 0 to 1: the right arm lifts forward and a little up (Samuel raising the oil horn).
var reach: float = 0.0
var _time: float = 0.0
var _blink: float = 2.4
var _talk: float = 0.0
var _skeleton: Skeleton3D
var _body: MeshInstance3D
var _bones: Dictionary = {}
var _axes: Dictionary = {}
var _rest_rotations: Dictionary = {}
var _blink_shape: int = -1
var _talk_shape: int = -1
var _measure_shape: int = -1


func _ready() -> void:
	var person: Dictionary = PEOPLE[who]
	var model := (load(person["scene"]) as PackedScene).instantiate() as Node3D
	model.name = "Model"
	model.scale = Vector3.ONE * float(person["scale"])
	add_child(model)
	_skeleton = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_body = model.find_child(person["body"], true, false) as MeshInstance3D
	var outline := model.find_child(person["outline"], true, false) as MeshInstance3D
	for bone_name in ["Hips", "Spine", "Chest", "Head", "UpperArm_L", "LowerArm_L", "UpperArm_R", "LowerArm_R", "Thigh_L", "Shin_L", "Thigh_R", "Shin_R"]:
		var index := _skeleton.find_bone(bone_name)
		_bones[bone_name] = index
		if index < 0:
			continue
		_axes[bone_name] = _skeleton.get_bone_global_rest(index).basis.inverse()
		_rest_rotations[bone_name] = _skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
	_blink_shape = _body.find_blend_shape_by_name("Blink")
	_talk_shape = _body.find_blend_shape_by_name("Talk")
	_measure_shape = _body.find_blend_shape_by_name("Measure")
	if outline:
		outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in outline.mesh.get_surface_count():
			var mat := outline.get_active_material(i)
			if mat == null:
				continue
			mat = mat.duplicate()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.cull_mode = BaseMaterial3D.CULL_BACK
			outline.set_surface_override_material(i, mat)


## Hangs `prop` on one of the skeleton's bones (a staff in a hand), so it moves with it.
func attach(bone_name: String, prop: Node3D) -> void:
	if _skeleton == null or _skeleton.find_bone(bone_name) < 0:
		add_child(prop)
		return
	var holder := BoneAttachment3D.new()
	holder.name = bone_name + "Holder"
	holder.bone_name = bone_name
	_skeleton.add_child(holder)
	holder.add_child(prop)


func _process(delta: float) -> void:
	if _skeleton == null or _body == null:
		return
	_time += delta
	_talk = move_toward(_talk, 1.0 if speaking else 0.0, delta * 4.0)
	_blink -= delta
	var closed := 0.0
	if _blink < 0.0:
		closed = clampf(1.0 - absf(_blink + 0.10) / 0.10, 0.0, 1.0)
		if _blink < -0.20:
			_blink = randf_range(2.8, 5.6)
	if _blink_shape >= 0:
		_body.set_blend_shape_value(_blink_shape, closed)
	if _talk_shape >= 0:
		_body.set_blend_shape_value(_talk_shape, _talk * (0.2 + 0.8 * maxf(sin(_time * 12.0), 0.0)))
	if _measure_shape >= 0:
		_body.set_blend_shape_value(_measure_shape, _talk * 0.35)
	var breath := CharacterMotion.breath(_time)
	var gesture := CharacterMotion.speaking_pulse(_time) * _talk
	_pose("Hips", Vector3(0, 0, sin(_time * 0.9) * 0.008))
	_pose("Spine", Vector3(breath * 0.006, 0, 0))
	_pose("Chest", Vector3(0, sin(_time * 1.1) * 0.012, 0))
	_pose("Head", Vector3(sin(_time * 2.4) * (0.012 + _talk * 0.025), sin(_time * 0.7) * 0.035, 0))
	for side in ["L", "R"]:
		var sign_side := -1.0 if side == "L" else 1.0
		var lead := 1.0 if side == "R" else 0.25
		var stride := sin(_time * 9.0) * sign_side * walk_amount
		_pose("Thigh_" + side, Vector3(stride * 0.28, 0, 0))
		_pose("Shin_" + side, Vector3(maxf(-stride, 0.0) * 0.3, 0, 0))
		var lift := reach if side == "R" else 0.0
		_pose("UpperArm_" + side, Vector3(0.02 + gesture * 0.03 * lead - stride * 0.18 + lift * 1.15, 0, sign_side * 0.02))
		_pose("LowerArm_" + side, Vector3(0.03 + gesture * 0.05 * lead + lift * 0.35, 0, 0))


func _pose(bone_name: String, angles: Vector3) -> void:
	if int(_bones.get(bone_name, -1)) < 0:
		return
	var axes: Basis = _axes[bone_name]
	var pose := Quaternion((axes * Vector3.RIGHT).normalized(), angles.x) * Quaternion((axes * Vector3.UP).normalized(), angles.y) * Quaternion((axes * Vector3.BACK).normalized(), angles.z)
	_skeleton.set_bone_pose_rotation(_bones[bone_name], _rest_rotations[bone_name] * pose)
