extends Node3D
## David's organic construction with Jonathan's own face, hair and clothing.
## Both skin and outline use the same skeleton: shoulders stay joined in motion.
const MODEL := preload("res://assets/jonathan_v1.glb")
const CharacterMotion := preload("res://scripts/chapter_two_character_motion.gd")
var speaking: bool = false
var _time: float = 0.0
var _blink: float = 2.8
var _talk: float = 0.0
var _skeleton: Skeleton3D
var _body: MeshInstance3D
var _outline: MeshInstance3D
var _audio: Node
var _bones: Dictionary = {}
var _axes: Dictionary = {}
var _rest_rotations: Dictionary = {}
var _blink_shape: int = -1
var _talk_shape: int = -1

func _ready() -> void:
	var model := MODEL.instantiate() as Node3D
	model.name = "Model"
	model.scale = Vector3.ONE * 1.06
	add_child(model)
	_skeleton = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_body = model.find_child("JonathanBody", true, false) as MeshInstance3D
	_outline = model.find_child("JonathanOutline", true, false) as MeshInstance3D
	_audio = get_parent().get_parent().get_node_or_null("AudioDirector")
	for bone_name in ["Hips", "Spine", "Chest", "Head", "UpperArm_L", "LowerArm_L", "UpperArm_R", "LowerArm_R"]:
		var index := _skeleton.find_bone(bone_name)
		_bones[bone_name] = index
		_axes[bone_name] = _skeleton.get_bone_global_rest(index).basis.inverse()
		_rest_rotations[bone_name] = _skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
	_blink_shape = _body.find_blend_shape_by_name("Blink")
	_talk_shape = _body.find_blend_shape_by_name("Talk")
	# The Blender hull already has inward-facing triangles. Keep back-face
	# culling, as on the exported David mesh, and avoid a duplicate shadow pass.
	_outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in _outline.mesh.get_surface_count():
		var mat := _outline.get_active_material(i).duplicate() as StandardMaterial3D
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_BACK
		_outline.set_surface_override_material(i, mat)

func _process(delta: float) -> void:
	if _skeleton == null:
		return
	_time += delta
	var talking: bool = speaking and _audio != null and _audio.is_speaking()
	_talk = move_toward(_talk, 1.0 if talking else 0.0, delta * 4.0)
	_blink -= delta
	var closed := 0.0
	if _blink < 0.0:
		closed = clampf(1.0 - absf(_blink + 0.10) / 0.10, 0.0, 1.0)
		if _blink < -0.20:
			_blink = randf_range(2.8, 5.6)
	_body.set_blend_shape_value(_blink_shape, closed)
	_body.set_blend_shape_value(_talk_shape, _talk * (0.2 + 0.8 * maxf(sin(_time * 12.0), 0.0)))
	var breath := CharacterMotion.breath(_time)
	var gesture := CharacterMotion.speaking_pulse(_time) * _talk
	_pose("Hips", Vector3(0, 0, sin(_time * 0.9) * 0.008))
	_pose("Spine", Vector3(breath * 0.006, 0, 0))
	_pose("Chest", Vector3(0, sin(_time * 1.1) * 0.012, 0))
	_pose("Head", Vector3(sin(_time * 2.4) * (0.012 + _talk * 0.025), sin(_time * 0.7) * 0.035, 0))
	for side in ["L", "R"]:
		var sign_side := -1.0 if side == "L" else 1.0
		# A small one-handed gesture reads as conversation. The old symmetric
		# forearm lift put both hands beside Jonathan's ears and looked robotic.
		var lead := 1.0 if side == "R" else 0.35
		_pose("UpperArm_" + side, Vector3(0.025 + gesture * 0.028 * lead, 0, sign_side * 0.018))
		_pose("LowerArm_" + side, Vector3(0.035 + gesture * 0.055 * lead, 0, sign_side * gesture * 0.012))

func _pose(bone_name: String, angles: Vector3) -> void:
	var axes: Basis = _axes[bone_name]
	var pose := Quaternion((axes * Vector3.RIGHT).normalized(), angles.x) * Quaternion((axes * Vector3.UP).normalized(), angles.y) * Quaternion((axes * Vector3.BACK).normalized(), angles.z)
	_skeleton.set_bone_pose_rotation(_bones[bone_name], _rest_rotations[bone_name] * pose)
