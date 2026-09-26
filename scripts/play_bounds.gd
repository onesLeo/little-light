extends Node
## Keeps the Wonder-Walker inside the valley without an invisible wall you
## bump into. Near the edge of a rounded-rectangle play area the walker meets a
## gentle, growing push back toward the middle (like walking into a soft
## rubber band); at the very edge it cannot go further. The first time it is
## felt, Wonder Light says a friendly line.
## Runs after the Player in the tree, so it corrects the position each physics step.
## Which area it keeps is the running story's play area (play_area.gd), handed over by the
## shell (use_area); until then, the valley's (the defaults below).

@export var center: Vector2 = Vector2(0.0, 2.4)
@export var half_extents: Vector2 = Vector2(10.4, 8.2)
@export var corner_radius: float = 3.0
## The push starts this far inside the hard edge.
@export var soft_margin: float = 1.8
## Push speed at the hard edge, as a multiple of the walker's move speed.
@export var edge_push_ratio: float = 1.25

const NUDGE_LINES := [
	"Wonder Light: \"That's the edge of our little valley. Let's stay close!\"",
	"Wonder Light: \"There's so much to find right here. Let's turn back!\"",
]

## Keeps the walker inside `area` (play_area.gd) from now on.
func use_area(area: Resource) -> void:
	if area == null:
		return
	center = area.center
	half_extents = area.half_extents
	corner_radius = area.corner_radius

var _player: CharacterBody3D
var _shell: Node
var _nudge_index: int = 0


func _ready() -> void:
	var main := get_parent()
	_player = main.get_node_or_null("Player") as CharacterBody3D
	_shell = main


func _physics_process(delta: float) -> void:
	if _player == null:
		return
	var p := Vector2(_player.global_position.x, _player.global_position.z) - center
	var edge := _edge_info(p)
	var sd: float = edge["sd"]
	if sd <= -soft_margin:
		return
	var inward: Vector2 = -edge["normal"]
	var speed: float = _player.move_speed if "move_speed" in _player else 4.0
	var depth := clampf((sd + soft_margin) / soft_margin, 0.0, 1.0)
	var push := speed * edge_push_ratio * depth * depth * delta
	var moved := inward * push
	# Never let the walker end up outside the hard edge.
	if sd - push > 0.0:
		moved = inward * sd
	_player.global_position += Vector3(moved.x, 0.0, moved.y)
	if depth > 0.35 and _shell and _shell.has_method("nudge"):
		_shell.nudge(NUDGE_LINES[_nudge_index % NUDGE_LINES.size()])
		_nudge_index += 1


## Signed distance to the rounded rectangle (negative inside) and the outward normal.
func _edge_info(p: Vector2) -> Dictionary:
	var core := half_extents - Vector2(corner_radius, corner_radius)
	var q := p.abs() - core
	var sx := 1.0 if p.x >= 0.0 else -1.0
	var sy := 1.0 if p.y >= 0.0 else -1.0
	var normal: Vector2
	if q.x > 0.0 and q.y > 0.0:
		normal = Vector2(sx * q.x, sy * q.y).normalized()
	elif q.x > q.y:
		normal = Vector2(sx, 0.0)
	else:
		normal = Vector2(0.0, sy)
	var sd := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - corner_radius
	return {"sd": sd, "normal": normal}
