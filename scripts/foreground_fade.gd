extends Node
## Softens large trees and shrubs that sit directly between the tabletop
## camera and the Wonder-Walker. The paper scenery still frames the valley,
## but it cannot hide the child or an item they are trying to reach.

@export var camera_path: NodePath = ^"../TabletopCamera"
@export var player_path: NodePath = ^"../Player"
@export_range(0.0, 1.0) var occluded_transparency: float = 0.62
@export var fade_speed: float = 4.0

var _camera: Camera3D
var _player: Node3D
var _amounts: Dictionary = {}


func _ready() -> void:
	_camera = get_node_or_null(camera_path) as Camera3D
	_player = get_node_or_null(player_path) as Node3D


func _physics_process(delta: float) -> void:
	if _camera == null or _player == null or not _camera.current:
		_restore_all(delta)
		return
	var wanted: Dictionary = {}
	var exclude: Array[RID] = []
	var space := _player.get_world_3d().direct_space_state
	for _i in 10:
		var query := PhysicsRayQueryParameters3D.create(
			_camera.global_position,
			_player.global_position + Vector3(0.0, 0.75, 0.0))
		query.collision_mask = 1
		query.exclude = exclude
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			break
		exclude.append(hit.rid)
		var collider := hit.collider as Node
		var mesh := collider.get_parent() as GeometryInstance3D if collider else null
		if mesh and _is_foreground_foliage(mesh):
			wanted[mesh] = true
			var outline := mesh.get_parent().get_node_or_null(String(mesh.name) + "_Outline") as GeometryInstance3D
			if outline:
				wanted[outline] = true

	for mesh in wanted:
		if not _amounts.has(mesh):
			_amounts[mesh] = 0.0
	for mesh in _amounts.keys():
		if not is_instance_valid(mesh):
			_amounts.erase(mesh)
			continue
		var target := occluded_transparency if wanted.has(mesh) else 0.0
		var amount: float = move_toward(float(_amounts[mesh]), target, fade_speed * delta)
		_amounts[mesh] = amount
		(mesh as GeometryInstance3D).transparency = amount
		if amount <= 0.001 and not wanted.has(mesh):
			_amounts.erase(mesh)


func _restore_all(delta: float) -> void:
	for mesh in _amounts.keys():
		if not is_instance_valid(mesh):
			_amounts.erase(mesh)
			continue
		var amount: float = move_toward(float(_amounts[mesh]), 0.0, fade_speed * delta)
		_amounts[mesh] = amount
		(mesh as GeometryInstance3D).transparency = amount
		if amount <= 0.001:
			_amounts.erase(mesh)


func _is_foreground_foliage(mesh: GeometryInstance3D) -> bool:
	var name := String(mesh.name)
	return name.begins_with("Olive") or name.begins_with("Cypress") or name.begins_with("Shrub")
