extends Node3D
## Gentle "where is it?" nudge for the Wonder Item hunt. If the child has not
## collected anything for a while, a bobbing golden arrow appears over the
## nearest missing item. When that item is off-screen, a matching arrow sits at
## the screen edge pointing the way. Purely visual, so it also works for the
## no-reading Band A play mode.
##
## Chapter 1's copy finds the valley's WonderItem_ areas and follows the chapter
## director. Chapter 2 makes its own copy for Jonathan's gifts: set `main` before
## adding it, then call watch() with the gifts, found() for each one picked up,
## and stop() when the hunt is over.

@export var hint_delay: float = 18.0
@export var arrow_height: float = 2.0
@export var edge_margin := Vector4(60.0, 60.0, 60.0, 230.0) ## left, top, right, bottom (bottom clears the dialogue panel)

const GameShell := preload("res://scripts/game_shell.gd")
const GOLD := Color(0.98, 0.78, 0.2)
const INK := Color(0.35, 0.2, 0.08)

## The main scene. Left empty, it is this node's grandparent (chapter 1's layout).
var main: Node
var _director: Node
var _player: Node3D
var _items: Array[Area3D] = []
var _collected: Dictionary = {}
var _active: bool = false
var _idle: float = 0.0
var _fade: float = 0.0
var _time: float = 0.0
var _arrow3d: Node3D
var _arrow2d: Node2D


func _ready() -> void:
	var auto := main == null
	if auto:
		main = GameShell.of(self)
	_player = main.get_node_or_null("Player") as Node3D
	if auto:
		_director = get_parent().get_parent().get_node_or_null("ChapterDirector")
		for child in get_parent().get_children():
			if child is Area3D and String(child.name).begins_with("WonderItem_"):
				_items.append(child)
	if _director:
		_director.explore_started.connect(_on_explore_started)
		_director.wonder_item_collected.connect(_on_item_collected)
		if _director.has_signal("stood_down"):
			_director.stood_down.connect(func() -> void: _active = false)
	_build_arrow3d()
	var ui := main.get_node_or_null("UI")
	_build_arrow2d(ui if ui else self)


## Starts helping with a new hunt: after `hint_delay` seconds with nothing found, the arrow
## points at the nearest of `items` still to find.
func watch(items: Array) -> void:
	_items.clear()
	for item in items:
		if item is Area3D:
			_items.append(item)
	_collected.clear()
	_active = true
	_idle = 0.0
	_fade = 0.0


## One of the watched items was found: the wait starts again, and the arrow looks for the next.
func found(item_name: String) -> void:
	_on_item_collected(item_name)


func stop() -> void:
	_active = false


## The flat arrow may live in the UI rather than under this node; it goes when the hints do.
func _exit_tree() -> void:
	if is_instance_valid(_arrow2d) and _arrow2d.get_parent() != self:
		if _arrow2d.get_parent():
			_arrow2d.get_parent().remove_child(_arrow2d)
		_arrow2d.queue_free()


func is_pointing() -> bool:
	return _arrow3d.visible or _arrow2d.visible


func _on_explore_started() -> void:
	_active = true
	_idle = 0.0


func _on_item_collected(item_name: String) -> void:
	_collected[item_name] = true
	_idle = 0.0
	_fade = 0.0


func _process(delta: float) -> void:
	_time += delta
	var target := _nearest_missing() if _active else null
	if target == null:
		_arrow3d.visible = false
		_arrow2d.visible = false
		return
	_idle += delta
	_fade = move_toward(_fade, 1.0 if _idle >= hint_delay else 0.0, delta * 1.5)
	if _fade <= 0.0:
		_arrow3d.visible = false
		_arrow2d.visible = false
		return
	var eased := smoothstep(0.0, 1.0, _fade)
	_update_arrow3d(target, eased)
	_update_arrow2d(target, eased)


func _nearest_missing() -> Area3D:
	var best: Area3D = null
	var best_d := INF
	for item in _items:
		if _collected.has(item.name):
			continue
		var d := 0.0
		if _player:
			d = item.global_position.distance_squared_to(_player.global_position)
		if d < best_d:
			best_d = d
			best = item
	return best


func _update_arrow3d(target: Area3D, eased: float) -> void:
	_arrow3d.visible = true
	var bob := sin(_time * 3.2) * 0.14
	_arrow3d.global_position = target.global_position + Vector3(0.0, arrow_height + bob, 0.0)
	_arrow3d.scale = Vector3.ONE * eased
	_arrow3d.rotation.y = _time * 1.2


func _update_arrow2d(target: Area3D, eased: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		_arrow2d.visible = false
		return
	var world := target.global_position + Vector3(0.0, 0.8, 0.0)
	var behind := cam.is_position_behind(world)
	var screen := cam.unproject_position(world)
	var size := get_viewport().get_visible_rect().size
	var rect := Rect2(Vector2(edge_margin.x, edge_margin.y),
			size - Vector2(edge_margin.x + edge_margin.z, edge_margin.y + edge_margin.w))
	if not behind and rect.has_point(screen):
		_arrow2d.visible = false
		return
	var dir := screen - size * 0.5
	if behind:
		dir = -dir
	dir = dir.normalized() if dir.length() > 0.001 else Vector2.UP
	var half := rect.size * 0.5
	var t := INF
	if absf(dir.x) > 0.0001:
		t = minf(t, half.x / absf(dir.x))
	if absf(dir.y) > 0.0001:
		t = minf(t, half.y / absf(dir.y))
	_arrow2d.visible = true
	_arrow2d.position = rect.get_center() + dir * t
	_arrow2d.rotation = dir.angle()
	_arrow2d.scale = Vector2.ONE * eased * (1.0 + 0.12 * sin(_time * 5.0))


func _build_arrow3d() -> void:
	_arrow3d = Node3D.new()
	_arrow3d.name = "HintArrow3D"
	_arrow3d.visible = false
	add_child(_arrow3d)

	var outline := StandardMaterial3D.new()
	outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline.albedo_color = INK
	outline.cull_mode = BaseMaterial3D.CULL_FRONT
	outline.grow = true
	outline.grow_amount = 0.035
	var gold := StandardMaterial3D.new()
	gold.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gold.albedo_color = GOLD
	gold.emission_enabled = true
	gold.emission = GOLD
	gold.emission_energy_multiplier = 0.5
	gold.next_pass = outline

	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.3
	cone.height = 0.5
	cone.radial_segments = 4
	cone.material = gold
	var tip := MeshInstance3D.new()
	tip.mesh = cone
	tip.rotation_degrees.x = 180.0 # apex points down at the item
	_arrow3d.add_child(tip)

	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.1
	stem_mesh.bottom_radius = 0.1
	stem_mesh.height = 0.45
	stem_mesh.radial_segments = 4
	stem_mesh.material = gold
	var stem := MeshInstance3D.new()
	stem.mesh = stem_mesh
	stem.position.y = 0.47
	_arrow3d.add_child(stem)


func _build_arrow2d(parent: Node) -> void:
	_arrow2d = Node2D.new()
	_arrow2d.name = "HintArrow2D"
	_arrow2d.visible = false
	var back := Polygon2D.new()
	back.color = INK
	back.polygon = PackedVector2Array([Vector2(-20, -24), Vector2(28, 0), Vector2(-20, 24)])
	_arrow2d.add_child(back)
	var front := Polygon2D.new()
	front.color = GOLD
	front.polygon = PackedVector2Array([Vector2(-13, -16), Vector2(19, 0), Vector2(-13, 16)])
	_arrow2d.add_child(front)
	parent.add_child(_arrow2d)
