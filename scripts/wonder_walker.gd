extends CharacterBody3D

const GroundSurface := preload("res://scripts/ground_surface.gd")
## Wonder-Walker third-person movement (Godot 4.3+).
## Camera-relative WASD; only the Model mesh yaws (camera stays stable).

@export var move_speed: float = 4.0
@export var gravity: float = 9.8
@export var walk_anim: StringName = &"WW_Walk"
## Optional idle/RESET clip. If missing (v13 only has WW_Walk), bones snap to bind rest.
@export var idle_anim: StringName = &"RESET"
@export var turn_speed: float = 12.0

## When false, chapter director freezes walk during dialogue.
var can_move: bool = true

## Movement is always relative to this camera's framing, even while a
## cinematic/close-up camera (see camera_director.gd) is the active
## rendering camera — the tabletop gameplay view is the movement reference.
@export var movement_camera_path: NodePath = ^"../TabletopCamera"

var _anim: AnimationPlayer
var _model: Node3D
var _camera: Camera3D
var _skeleton: Skeleton3D
var _was_walking: bool = false
var _audio: Node
var _step_timer: float = 0.0


func _ready() -> void:
	_model = get_node_or_null("Model") as Node3D
	_camera = get_node_or_null(movement_camera_path) as Camera3D
	if _camera == null:
		# Fall back to whatever's active, in case the path doesn't resolve.
		_camera = get_viewport().get_camera_3d()
	add_to_group("player")
	_audio = get_node_or_null("../AudioDirector")
	if _model:
		_anim = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		_skeleton = _model.find_child("Skeleton3D", true, false) as Skeleton3D
	if _anim and _anim.has_animation(walk_anim):
		var anim := _anim.get_animation(walk_anim)
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
	# Start standing at rest (not mid-stride).
	_set_walking(false)


func _physics_process(delta: float) -> void:
	if not can_move:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.y = 0.0
		move_and_slide()
		_set_walking(false)
		return

	# WASD / arrows → camera-relative flat direction (tabletop feel).
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if _camera == null or not is_instance_valid(_camera):
		_camera = get_node_or_null(movement_camera_path) as Camera3D
		if _camera == null:
			_camera = get_viewport().get_camera_3d()
	var basis := _camera.global_transform.basis if _camera else global_transform.basis
	var cam_forward := -basis.z
	cam_forward.y = 0.0
	if cam_forward.length_squared() < 0.0001:
		cam_forward = Vector3.FORWARD
	else:
		cam_forward = cam_forward.normalized()
	var cam_right := basis.x
	cam_right.y = 0.0
	if cam_right.length_squared() < 0.0001:
		cam_right = Vector3.RIGHT
	else:
		cam_right = cam_right.normalized()

	# get_vector: y negative when "forward" pressed → use -input_dir.y for forward.
	var direction := (cam_right * input_dir.x + cam_forward * -input_dir.y)
	if direction.length_squared() > 0.0001:
		direction = direction.normalized()

	var walking := direction.length_squared() > 0.0001
	if walking:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		# Yaw only the mesh — keep CharacterBody + camera orientation fixed.
		if _model:
			# Godot Node3D forward is -Z; face move direction (fixes left/right moonwalk).
			var target_yaw := atan2(-direction.x, -direction.z)
			_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()
	_set_walking(walking)
	_update_footsteps(walking and is_on_floor(), delta)


## One soft step per foot, timed to the walk animation (two steps per cycle).
func _update_footsteps(walking: bool, delta: float) -> void:
	if not walking:
		_step_timer = 0.12  # the first step lands just after setting off
		return
	_step_timer -= delta
	if _step_timer > 0.0:
		return
	var period := 0.32
	if _anim and _anim.has_animation(walk_anim):
		period = clampf(_anim.get_animation(walk_anim).length / 2.0, 0.2, 0.6)
	_step_timer = period
	if _audio and _audio.has_method("play_step"):
		_audio.play_step(GroundSurface.at(global_position))


func _set_walking(walking: bool) -> void:
	if _anim == null:
		return
	if walking:
		if _anim.current_animation != walk_anim or not _anim.is_playing():
			_anim.play(walk_anim)
		_was_walking = true
		return
	# Leaving walk (or first boot): don't freeze on walk frame 0 (feet still apart).
	if _was_walking or _anim.is_playing() or _anim.current_animation == walk_anim:
		_go_idle()
	_was_walking = false


func _go_idle() -> void:
	# Prefer a real idle/RESET clip when the model ships one.
	if idle_anim != &"" and _anim.has_animation(idle_anim):
		_anim.play(idle_anim)
		_anim.seek(0.0, true)
		_anim.pause()
		return
	# v13 only has WW_Walk. stop() seeks to walk frame 0 (still a stride),
	# so clear the clip and snap bones to the skeleton bind/rest pose.
	_anim.stop()
	if _skeleton:
		_skeleton.reset_bone_poses()
