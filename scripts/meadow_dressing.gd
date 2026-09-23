extends Node3D
## Dresses the empty meadow: swaying grass tufts, tiny flowers and pebbles,
## scattered on flat open ground (never on the path, near the stream, or
## against rocks, bushes and trees). Each kind is a single MultiMesh, so the
## whole meadow costs three draw calls.

const SWAY_SHADER := preload("res://assets/shaders/meadow_sway.gdshader")

## Meadow rectangle on the ground plane (x, z).
@export var area_min: Vector2 = Vector2(-11.0, -8.5)
@export var area_max: Vector2 = Vector2(11.0, 9.5)
@export var tuft_count: int = 700
@export var flower_count: int = 120
@export var pebble_count: int = 60
@export var path_clearance: float = 0.9
@export var stream_clearance: float = 2.6
## 0 = different every run.
@export var seed_override: int = 0
## Only ground between these heights is dressed (the meadow floor by default).
@export var ground_y_range: Vector2 = Vector2(-0.05, 0.35)
## Round spots to leave bare: (x, z, radius) in world space.
@export var clear_circles: Array[Vector3] = []
@export var player_path: NodePath = ^"../Player"

var _mat: ShaderMaterial
var _player: Node3D

## The walking path and the lower stream, as (x, z) polylines in world space.
const PATH_XZ := [Vector2(0.3, 9.5), Vector2(0.2, 7.6), Vector2(0.1, 5.6), Vector2(0.25, 3.6),
		Vector2(0.45, 1.6), Vector2(0.5, -0.2), Vector2(0.42, -1.6), Vector2(0.55, -2.4), Vector2(0.6, -3.0)]
const STREAM_XZ := [Vector2(-6.45, -4.35), Vector2(-6.45, -4.35), Vector2(-6.8, -2.6), Vector2(-7.4, -0.4),
		Vector2(-8.2, 2.2), Vector2(-9.2, 5.0), Vector2(-10.5, 8.2), Vector2(-12.0, 11.5)]
const TUFT_COLORS := [Color(0.40, 0.68, 0.30), Color(0.48, 0.73, 0.32), Color(0.34, 0.60, 0.27),
		Color(0.60, 0.76, 0.34), Color(0.52, 0.66, 0.30)]
const FLOWER_COLORS := [Color(1.0, 1.0, 0.94), Color(1.0, 0.84, 0.26), Color(1.0, 0.62, 0.72), Color(0.76, 0.64, 0.96)]
const PEBBLE_COLORS := [Color(0.62, 0.63, 0.68), Color(0.72, 0.68, 0.60), Color(0.52, 0.55, 0.60)]


func _ready() -> void:
	# Valley colliders reach the physics space only after a step or two.
	await get_tree().physics_frame
	await get_tree().physics_frame
	var rng := RandomNumberGenerator.new()
	if seed_override != 0:
		rng.seed = seed_override
	else:
		rng.randomize()
	var space := get_world_3d().direct_space_state
	var mat := ShaderMaterial.new()
	mat.shader = SWAY_SHADER
	_mat = mat
	_player = get_node_or_null(player_path) as Node3D

	var tuft_spots := _pick_spots(space, rng, tuft_count)
	var half := tuft_spots.size() / 2
	_spawn("TuftsA", _tuft_mesh(rng, 7), tuft_spots.slice(0, half), TUFT_COLORS, mat, rng, 0.8, 1.4)
	_spawn("TuftsB", _tuft_mesh(rng, 5), tuft_spots.slice(half), TUFT_COLORS, mat, rng, 0.9, 1.6)
	_spawn("Flowers", _flower_mesh(), _pick_spots(space, rng, flower_count), FLOWER_COLORS, mat, rng, 0.8, 1.3)
	_spawn("Pebbles", _pebble_mesh(), _pick_spots(space, rng, pebble_count), PEBBLE_COLORS, mat, rng, 0.6, 1.5)


func _process(_delta: float) -> void:
	if _mat and _player:
		_mat.set_shader_parameter("player_pos", _player.global_position)


## -- Placement ---------------------------------------------------------------

func _pick_spots(space: PhysicsDirectSpaceState3D, rng: RandomNumberGenerator, count: int) -> Array[Vector3]:
	var spots: Array[Vector3] = []
	var attempts := 0
	while spots.size() < count and attempts < count * 12:
		attempts += 1
		var p := Vector2(rng.randf_range(area_min.x, area_max.x), rng.randf_range(area_min.y, area_max.y))
		if _dist_to_polyline(p, PATH_XZ) < path_clearance or _dist_to_polyline(p, STREAM_XZ) < stream_clearance:
			continue
		if _in_clear_circle(p):
			continue
		var ground: Variant = _flat_ground(space, p)
		if ground != null:
			spots.append(ground)
	return spots


func _flat_ground(space: PhysicsDirectSpaceState3D, p: Vector2) -> Variant:
	var hit := _cast(space, p)
	if hit.is_empty():
		return null
	var y: float = hit.position.y
	if y < ground_y_range.x or y > ground_y_range.y or hit.normal.y < 0.97:
		return null
	# Ring check keeps clear of rocks, bushes and trunks.
	for k in 4:
		var a := TAU * k / 4.0
		var ring := _cast(space, p + Vector2(cos(a), sin(a)) * 0.45)
		if ring.is_empty() or absf(ring.position.y - y) > 0.1:
			return null
	return Vector3(p.x, y, p.y)


func _in_clear_circle(p: Vector2) -> bool:
	for c in clear_circles:
		if p.distance_to(Vector2(c.x, c.y)) < c.z:
			return true
	return false


func _cast(space: PhysicsDirectSpaceState3D, p: Vector2) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, ground_y_range.y + 20.0, p.y), Vector3(p.x, ground_y_range.x - 5.0, p.y))
	q.collision_mask = 1
	return space.intersect_ray(q)


func _dist_to_polyline(p: Vector2, pts: Array) -> float:
	var best := INF
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var ab := b - a
		var len2 := ab.length_squared()
		var t := 0.0 if len2 < 0.0001 else clampf((p - a).dot(ab) / len2, 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
	return best


func _spawn(node_name: String, mesh: Mesh, spots: Array[Vector3], colors: Array, mat: ShaderMaterial,
		rng: RandomNumberGenerator, scale_min: float, scale_max: float) -> void:
	if spots.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = spots.size()
	for i in spots.size():
		var s := rng.randf_range(scale_min, scale_max)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.85, 1.2), s))
		mm.set_instance_transform(i, Transform3D(basis, spots[i] - Vector3(0.0, 0.02, 0.0)))
		mm.set_instance_color(i, colors[rng.randi() % colors.size()])
	var mi := MultiMeshInstance3D.new()
	mi.name = node_name
	mi.multimesh = mm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## -- Meshes (UV.x = part id, UV.y = height fraction; see the shader) ---------

func _v(st: SurfaceTool, pos: Vector3, part: float, h: float) -> void:
	st.set_uv(Vector2(part, h))
	st.add_vertex(pos)


func _tuft_mesh(rng: RandomNumberGenerator, blades: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in blades:
		var yaw := TAU * float(i) / blades + rng.randf_range(-0.3, 0.3)
		var height := rng.randf_range(0.16, 0.30)
		var width := rng.randf_range(0.035, 0.055)
		var lean := rng.randf_range(0.04, 0.16)
		var base := Vector3(rng.randf_range(-0.04, 0.04), 0.0, rng.randf_range(-0.04, 0.04))
		var rot := Basis(Vector3.UP, yaw)
		_v(st, base + rot * Vector3(-width * 0.5, 0.0, 0.0), 0.0, 0.0)
		_v(st, base + rot * Vector3(width * 0.5, 0.0, 0.0), 0.0, 0.0)
		_v(st, base + rot * Vector3(lean, height, 0.0), 0.0, 1.0)
	return st.commit()


func _flower_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stem_h := 0.26
	# Stem: a thin crossed pair of quads.
	for yaw in [0.0, PI * 0.5]:
		var rot := Basis(Vector3.UP, yaw)
		var w := 0.008
		_v(st, rot * Vector3(-w, 0.0, 0.0), 1.0, 0.0)
		_v(st, rot * Vector3(w, 0.0, 0.0), 1.0, 0.0)
		_v(st, rot * Vector3(w, stem_h, 0.0), 1.0, 1.0)
		_v(st, rot * Vector3(-w, 0.0, 0.0), 1.0, 0.0)
		_v(st, rot * Vector3(w, stem_h, 0.0), 1.0, 1.0)
		_v(st, rot * Vector3(-w, stem_h, 0.0), 1.0, 1.0)
	# Five petals, then the centre.
	var top := Vector3(0.0, stem_h, 0.0)
	for k in 5:
		var a0 := TAU * k / 5.0
		var a1 := TAU * (k + 0.5) / 5.0
		var a2 := TAU * (k + 1.0) / 5.0
		var tip := top + Vector3(cos(a1) * 0.075, 0.012, sin(a1) * 0.075)
		_v(st, top, 2.0, 1.0)
		_v(st, top + Vector3(cos(a0) * 0.035, 0.004, sin(a0) * 0.035), 2.0, 1.0)
		_v(st, tip, 2.0, 1.0)
		_v(st, top, 2.0, 1.0)
		_v(st, tip, 2.0, 1.0)
		_v(st, top + Vector3(cos(a2) * 0.035, 0.004, sin(a2) * 0.035), 2.0, 1.0)
	for k in 6:
		var a0 := TAU * k / 6.0
		var a1 := TAU * (k + 1.0) / 6.0
		_v(st, top + Vector3(0.0, 0.016, 0.0), 3.0, 1.0)
		_v(st, top + Vector3(cos(a0) * 0.028, 0.008, sin(a0) * 0.028), 3.0, 1.0)
		_v(st, top + Vector3(cos(a1) * 0.028, 0.008, sin(a1) * 0.028), 3.0, 1.0)
	return st.commit()


func _pebble_mesh() -> ArrayMesh:
	var sphere := SphereMesh.new()
	sphere.radius = 0.06
	sphere.height = 0.075
	sphere.radial_segments = 6
	sphere.rings = 3
	var arrays := sphere.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs := PackedVector2Array()
	uvs.resize(verts.size())
	uvs.fill(Vector2(4.0, 0.0))
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
