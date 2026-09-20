extends Node
## Gives the collectible lamb a little life. It breathes gently while waiting;
## when the Wonder-Walker comes near it turns to look at them and hops with
## excitement. It never moves away from its spot, so the pickup stays where the
## hint arrows and the E-prompt expect it.
## Sits under WonderItems and waits for the scatter to place the items first.

const LAMB := "WonderItem_Lamb"

@export var notice_radius: float = 4.2
@export var hop_height: float = 0.17
@export var hop_period: float = 0.85
## Extra turn if a future lamb model does not face -Z (the current one does).
@export var face_offset_degrees: float = 0.0

var _meshes: Array[Node3D] = []
var _base_pos: Dictionary = {}
var _base_yaw: float = 0.0
var _yaw: float = 0.0
var _excite: float = 0.0
var _hop_time: float = 0.0
var _time: float = 0.0
var _player: Node3D
var _ready_to_animate: bool = false


func _ready() -> void:
	var items := get_parent()
	_player = items.get_parent().get_node_or_null("Player") as Node3D
	var scatter := items.get_node_or_null("Scatter")
	if scatter and scatter.has_signal("scattered"):
		scatter.scattered.connect(func(_positions: Dictionary) -> void: _capture())
	else:
		call_deferred("_capture")


func _capture() -> void:
	var visuals := get_parent().get_node_or_null("WonderItemsVisual")
	if visuals == null:
		return
	_meshes.clear()
	for n in [LAMB, LAMB + "_Outline"]:
		var mesh := visuals.find_child(n, true, false) as Node3D
		if mesh:
			_meshes.append(mesh)
			_base_pos[mesh] = mesh.global_position
	if _meshes.is_empty():
		return
	_base_yaw = _meshes[0].rotation.y
	_yaw = _base_yaw
	_ready_to_animate = true


func _process(delta: float) -> void:
	if not _ready_to_animate or _meshes.is_empty() or not _meshes[0].visible:
		return
	_time += delta
	var lamb := _meshes[0]
	var base: Vector3 = _base_pos[lamb]

	var target_excite := 0.0
	var to_player := Vector3.ZERO
	if _player:
		to_player = _player.global_position - base
		to_player.y = 0.0
		if to_player.length() < notice_radius:
			target_excite = 1.0
	_excite = move_toward(_excite, target_excite, delta * 2.5)

	if _excite > 0.05:
		_hop_time += delta * (TAU / hop_period) * _excite
		var target_yaw := atan2(-to_player.x, -to_player.z) + deg_to_rad(face_offset_degrees)
		_yaw = lerp_angle(_yaw, target_yaw, clampf(delta * 5.0, 0.0, 1.0))
	else:
		_yaw = lerp_angle(_yaw, _base_yaw, clampf(delta * 1.5, 0.0, 1.0))

	var idle := sin(_time * 1.6) * 0.008
	var hop := absf(sin(_hop_time * 0.5)) * hop_height * _excite
	var squash := 1.0 - 0.06 * _excite * pow(1.0 - absf(sin(_hop_time * 0.5)), 6.0)
	for mesh in _meshes:
		var bp: Vector3 = _base_pos[mesh]
		mesh.global_position = Vector3(bp.x, bp.y + idle + hop, bp.z)
		mesh.rotation.y = _yaw
		mesh.scale = Vector3(1.0, squash, 1.0)
