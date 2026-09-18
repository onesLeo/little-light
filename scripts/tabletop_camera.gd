extends Camera3D
## DOGWALK-style tabletop follow cam: high, tilted down, smooth chase.
## Keep as a sibling of Player (not a child) so walking never spins the view.

@export var target_path: NodePath = ^"%Player"
@export var offset: Vector3 = Vector3(0.0, 9.5, 11.0)
@export var look_height: float = 0.7
@export var follow_speed: float = 6.0
@export var look_speed: float = 10.0

var _target: Node3D


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node3D
	if _target == null:
		_target = get_tree().get_first_node_in_group("player") as Node3D
	current = true
	if _target:
		global_position = _target.global_position + offset
		look_at(_target.global_position + Vector3(0.0, look_height, 0.0), Vector3.UP)


func _physics_process(delta: float) -> void:
	if _target == null:
		return
	var desired := _target.global_position + offset
	global_position = global_position.lerp(desired, clampf(follow_speed * delta, 0.0, 1.0))
	var look_at_pos := _target.global_position + Vector3(0.0, look_height, 0.0)
	# Smooth look by slerping basis toward look_at orientation.
	var from := global_transform.basis
	var to_xform := global_transform.looking_at(look_at_pos, Vector3.UP)
	global_transform.basis = from.slerp(to_xform.basis, clampf(look_speed * delta, 0.0, 1.0))
