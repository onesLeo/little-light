extends Node3D
## A person the child meets and hears, from the Blender paper models on the shared
## Wonder-Walker skeleton (art/blender/scripts/characters/): Noah and his wife in the ark,
## Samuel, Jesse, the younger David and Jesse's seven older sons in Bethlehem. They breathe, blink, talk while their
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
	# Jesse's sons: light, even cloth and hair, tinted per brother with tint() (jesse_sons.gd).
	"brother": {"scene": "res://assets/brother_v1.glb", "body": "BrotherBody", "outline": "BrotherOutline", "scale": 1.2},
	"brother_young": {"scene": "res://assets/brother_young_v1.glb", "body": "YoungBrotherBody", "outline": "YoungBrotherOutline", "scale": 1.14},
	"jonah": {"scene": "res://assets/jonah_v1.glb", "body": "JonahBody", "outline": "JonahOutline", "scale": 1.2},
}

## The kneeling pose, in radians at kneel = 1: the knees bend right back under the body, the
## back leans a little forward and the head bows. A negative shin angle folds the lower leg back,
## so the shins lie flat behind the knees and the feet are behind the person, never in front.
const KNEEL_THIGH := -0.12
const KNEEL_SHIN := -1.5
const KNEEL_LEAN := -0.12
const KNEEL_BOW := -0.4

## The arm poses for the feelings (upper arm: forward x, twist y, out z; forearm: bend), found with
## tools/pose_probe.gd, which prints where the hands land.
const ARM_BRACE := Vector3(0.75, 0.0, 0.3)
const FOREARM_BRACE := 0.35
const ARM_PLEAD := Vector3(0.9, 0.0, -0.65)
const FOREARM_PLEAD := 1.0
const ARM_HEART := Vector3(0.4, 1.3, 0.0)
const FOREARM_HEART := 1.9

## How quickly a person turns towards `watch`, as a share of the angle left per second.
const TURN_RATE := 5.0

## One of PEOPLE. Set this before the node enters the tree.
var who: String = "noah"
var speaking: bool = false
var walk_amount: float = 0.0
## 0 to 1: the right arm lifts forward and a little up (Samuel raising the oil horn).
var reach: float = 0.0
## A turn of the head to one side, in radians (a brother glancing about while he waits).
var look_aside: float = 0.0
## 0 to 1: down on both knees, head bowed (David, to be anointed). The model sinks by the
## height of its knees, so the knees rest on the ground.
var kneel: float = 0.0
## Feelings shown in the body, each 0 to 1 and blended with mood() (docs/chapter-5-concept.md asks for
## "reluctance, prayer and honest frustration" without a word of it on the face alone):
##   slump   sorrow or shame: the back rounds, the shoulders drop forward, the head hangs;
##   brace   steadying against the storm: both arms forward as if holding the rail, the body back;
##   plead   asking or praying: both hands raised in front, the head lifted;
##   heart   a hand on the heart ("this is because of me");
##   sway    rocking with the deck, from side to side.
var slump: float = 0.0
var brace: float = 0.0
var plead: float = 0.0
var heart: float = 0.0
var sway: float = 0.0
var _mood_tween: Tween
## Who this person turns to look at while standing (the one speaking, or the one spoken to),
## or null to keep facing the way they are. Walking always faces the way they go.
var watch: Node3D = null
var _model: Node3D
var _knee_height: float = 0.0
var _height: float = 0.0
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
	_model = model
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
	_height = _body.get_aabb().end.y * float(person["scale"])
	var shin := _skeleton.find_bone("Shin_L")
	if shin >= 0:
		var knee := _skeleton.global_transform * _skeleton.get_bone_global_rest(shin).origin
		_knee_height = (knee - model.global_transform.origin).y if model.is_inside_tree() else 0.0
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


## Moves to a feeling over `seconds`: `feelings` sets any of slump, brace, plead, heart and sway
## (0 to 1); the ones left out go back to 0. mood({}) is calm again.
func mood(feelings: Dictionary, seconds: float = 0.6) -> void:
	if _mood_tween:
		_mood_tween.kill()
	_mood_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for key in ["slump", "brace", "plead", "heart", "sway"]:
		_mood_tween.tween_property(self, key, float(feelings.get(key, 0.0)), maxf(seconds, 0.01))


## The top of the head in the world, standing or kneeling (where the oil runs to).
func head_top() -> Vector3:
	return global_position + Vector3(0.0, _height - _knee_height * kneel, 0.0)


## Colours this person's own cloth and hair: `colours` maps a material's part name (the end of
## its name: "Tunic", "UnderTunic", "Sash", "Hair", "Skin") to a colour its paper is multiplied
## by. Each person gets copies, so seven brothers from one model each keep their own.
func tint(colours: Dictionary) -> void:
	if _body == null:
		return
	for i in _body.mesh.get_surface_count():
		var mat := _body.get_active_material(i) as StandardMaterial3D
		if mat == null:
			continue
		var part := mat.resource_name.get_slice("_", mat.resource_name.get_slice_count("_") - 1)
		if colours.has(part):
			mat = mat.duplicate() as StandardMaterial3D
			mat.albedo_color = colours[part]
			_body.set_surface_override_material(i, mat)


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
	_model.position.y = -_knee_height * kneel
	_turn_to_watch(delta)
	var rock := sin(_time * 1.3) * sway
	_pose("Hips", Vector3(0, 0, sin(_time * 0.9) * 0.008 + rock * 0.06))
	_pose("Spine", Vector3(breath * 0.006 + kneel * KNEEL_LEAN - slump * 0.22 + brace * 0.08, 0, -rock * 0.05))
	_pose("Chest", Vector3(-slump * 0.12, sin(_time * 1.1) * 0.012, -rock * 0.03))
	_pose("Head", Vector3(sin(_time * 2.4) * (0.012 + _talk * 0.025) + kneel * KNEEL_BOW - slump * 0.3 + plead * 0.18 + brace * 0.05,
			sin(_time * 0.7) * 0.035 + look_aside, 0))
	for side in ["L", "R"]:
		var sign_side := -1.0 if side == "L" else 1.0
		var lead := 1.0 if side == "R" else 0.25
		var stride := sin(_time * 9.0) * sign_side * walk_amount
		_pose("Thigh_" + side, Vector3(stride * 0.28 + kneel * KNEEL_THIGH, 0, 0))
		# The knee bends backwards as the leg swings back, as knees do.
		_pose("Shin_" + side, Vector3(-maxf(-stride, 0.0) * 0.3 + kneel * KNEEL_SHIN, 0, 0))
		var lift := reach if side == "R" else 0.0
		var on_heart := heart if side == "R" else 0.0
		_pose("UpperArm_" + side, Vector3(0.02 + gesture * 0.03 * lead - stride * 0.18 + lift * 1.9 + kneel * 0.25
				+ slump * 0.12 + brace * ARM_BRACE.x + plead * ARM_PLEAD.x + on_heart * ARM_HEART.x, sign_side * on_heart * ARM_HEART.y,
				sign_side * (0.02 + brace * ARM_BRACE.z + plead * ARM_PLEAD.z + on_heart * ARM_HEART.z)))
		_pose("LowerArm_" + side, Vector3(0.03 + gesture * 0.05 * lead + lift * 0.2 + brace * FOREARM_BRACE + plead * FOREARM_PLEAD
				+ on_heart * FOREARM_HEART, 0, 0))


## Turns smoothly (the models face -Z) towards `watch`, but only while standing still.
func _turn_to_watch(delta: float) -> void:
	if watch == null or not is_instance_valid(watch) or walk_amount > 0.0:
		return
	var to := watch.global_position - global_position
	if Vector2(to.x, to.z).length() < 0.05:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), minf(1.0, delta * TURN_RATE))


func _pose(bone_name: String, angles: Vector3) -> void:
	if int(_bones.get(bone_name, -1)) < 0:
		return
	var axes: Basis = _axes[bone_name]
	var pose := Quaternion((axes * Vector3.RIGHT).normalized(), angles.x) * Quaternion((axes * Vector3.UP).normalized(), angles.y) * Quaternion((axes * Vector3.BACK).normalized(), angles.z)
	_skeleton.set_bone_pose_rotation(_bones[bone_name], _rest_rotations[bone_name] * pose)
