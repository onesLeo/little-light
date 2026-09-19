extends Node
## Scatters the three Wonder Items to random spots in the meadow each run.
## The item GLB ships them in a neat row, so this moves each item's visual
## (and its outline) plus its pickup Area3D together onto valid ground.

const ITEM_NAMES := ["WonderItem_Stone", "WonderItem_Staff", "WonderItem_Lamb"]

## Meadow rectangle (x, z) the items may land in.
@export var area_min := Vector2(-4.5, -5.0)
@export var area_max := Vector2(8.0, 7.0)
@export var min_separation: float = 5.0
@export var keep_clear_radius: float = 3.0
## Pickup Area3D sits this far above the ground point.
@export var area_height: float = 0.5
## 0 = different every run; set to reproduce a layout.
@export var seed_override: int = 0

signal scattered(positions: Dictionary)

var positions: Dictionary = {}


func _ready() -> void:
	var items_root := get_parent() as Node3D
	var visuals := items_root.get_node_or_null("WonderItemsVisual") as Node3D
	if visuals:
		visuals.visible = false
	# Valley colliders are baked in _ready and only reach the physics space after a step.
	await get_tree().physics_frame
	await get_tree().physics_frame

	var rng := RandomNumberGenerator.new()
	if seed_override != 0:
		rng.seed = seed_override
	else:
		rng.randomize()

	var main := items_root.get_parent()
	var avoid: Array[Vector3] = []
	for path in ["Player", "DavidMentor"]:
		var n := main.get_node_or_null(path) as Node3D
		if n:
			avoid.append(n.global_position)

	var space := items_root.get_world_3d().direct_space_state
	var chosen: Array[Vector3] = []
	var separation := min_separation
	var rounds := 0
	while chosen.size() < ITEM_NAMES.size() and rounds < 24:
		rounds += 1
		var p: Variant = _try_pick(space, rng, chosen, avoid, separation, 250)
		if p != null:
			chosen.append(p)
		else:
			separation *= 0.7

	# Any item that found no valid spot simply stays where the GLB put it.
	for i in chosen.size():
		_place(items_root, visuals, ITEM_NAMES[i], chosen[i], rng.randf() * TAU)
		positions[ITEM_NAMES[i]] = chosen[i]
	if visuals:
		visuals.visible = true
	scattered.emit(positions)


func _try_pick(space: PhysicsDirectSpaceState3D, rng: RandomNumberGenerator, chosen: Array[Vector3],
		avoid: Array[Vector3], separation: float, attempts: int) -> Variant:
	for _i in attempts:
		var x := rng.randf_range(area_min.x, area_max.x)
		var z := rng.randf_range(area_min.y, area_max.y)
		var ground: Variant = _flat_ground(space, x, z)
		if ground == null:
			continue
		var p: Vector3 = ground
		if _too_close(p, avoid, keep_clear_radius) or _too_close(p, chosen, separation):
			continue
		return p
	return null


func _too_close(p: Vector3, others: Array[Vector3], dist: float) -> bool:
	for o in others:
		if Vector2(p.x - o.x, p.z - o.z).length() < dist:
			return true
	return false


## Ground point at (x, z) if it is low, level and unobstructed, else null.
func _flat_ground(space: PhysicsDirectSpaceState3D, x: float, z: float) -> Variant:
	var hit := _cast(space, x, z)
	if hit.is_empty():
		return null
	var p: Vector3 = hit.position
	if p.y < -0.15 or p.y > 0.3 or hit.normal.y < 0.97:
		return null
	# Ring check keeps items off the edge of rocks, shrubs and the stream bank.
	for k in 6:
		var a := TAU * k / 6.0
		var ring := _cast(space, x + cos(a) * 0.7, z + sin(a) * 0.7)
		if ring.is_empty() or absf(ring.position.y - p.y) > 0.12 or ring.normal.y < 0.95:
			return null
	return p


func _cast(space: PhysicsDirectSpaceState3D, x: float, z: float) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 20.0, z), Vector3(x, -5.0, z))
	q.collision_mask = 1
	return space.intersect_ray(q)


func _place(items_root: Node3D, visuals: Node3D, item_name: String, ground: Vector3, yaw: float) -> void:
	var area := items_root.get_node_or_null(item_name) as Node3D
	if area:
		area.global_position = ground + Vector3(0.0, area_height, 0.0)
	if visuals == null:
		return
	for n in [item_name, item_name + "_Outline"]:
		var mesh := visuals.find_child(n, true, false) as Node3D
		if mesh:
			mesh.global_position = ground
			mesh.rotation.y = yaw
