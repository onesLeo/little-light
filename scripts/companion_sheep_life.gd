extends Node
## Gives David's companion sheep a little life: a gentle breathing sway all the
## time, plus a glance toward the Wonder-Walker when they come close. It never
## leaves David's side -- it only nudges its own position/rotation in his local
## space, on top of wherever he is standing or however he is turned, the same
## way the collectible lamb (lamb_life.gd) breathes and turns without wandering
## off its spot.
## Sits as a child of DavidMentor; finds the sheep meshes by name once ready.

const SHEEP := "David_CompanionLamb"

@export var notice_radius: float = 5.0
@export var glance_degrees: float = 24.0

var _meshes: Array[Node3D] = []
var _base_pos: Dictionary = {}
var _base_yaw: float = 0.0
var _yaw_offset: float = 0.0
var _time: float = 0.0
var _player: Node3D
var _ready_to_animate: bool = false


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var david := get_parent() as Node3D
	if david == null:
		return
	_player = david.get_parent().get_node_or_null("Player") as Node3D
	_meshes.clear()
	for n in [SHEEP, SHEEP + "_Outline"]:
		var mesh := david.find_child(n, false, false) as Node3D
		if mesh:
			_meshes.append(mesh)
			_base_pos[mesh] = mesh.position
	if _meshes.is_empty():
		return
	_base_yaw = _meshes[0].rotation.y
	_ready_to_animate = true


func _process(delta: float) -> void:
	if not _ready_to_animate or not _meshes[0].visible:
		return
	_time += delta
	var david := get_parent() as Node3D
	var sheep := _meshes[0]
	var base: Vector3 = _base_pos[sheep]

	var target_offset := 0.0
	if _player and david:
		# The player's position in David's own local space, so the glance is
		# correct whichever way the chapter has turned David to face.
		var local_player: Vector3 = david.to_local(_player.global_position)
		var to_player := local_player - base
		to_player.y = 0.0
		if to_player.length() < notice_radius:
			target_offset = deg_to_rad(glance_degrees) * signf(-to_player.x)
	_yaw_offset = lerp_angle(_yaw_offset, target_offset, clampf(delta * 1.2, 0.0, 1.0))

	var breathe := sin(_time * 1.1) * 0.010
	var sway := sin(_time * 0.7 + 1.3) * deg_to_rad(2.0)
	for mesh in _meshes:
		var bp: Vector3 = _base_pos[mesh]
		mesh.position = Vector3(bp.x, bp.y + breathe, bp.z)
		mesh.rotation.y = _base_yaw + _yaw_offset + sway
