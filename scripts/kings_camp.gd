extends Node3D
## The King's Camp, on the ridge that is already behind the waterfall.
## Built when the scene loads, so the tents can be seen from the valley.
## visit() is what lets the child walk up there: the valley's soft edge
## opens, the light becomes the blue hour, and she stands at the clearing.

const CAMP := Vector3(-2.0, 0.0, 28.0)

var _clearing := Vector3.ZERO
var _built: bool = false
var _flames: Array[MeshInstance3D] = []
var _banners: Array[Node3D] = []
var _guards: Array[Node3D] = []
var _guard_home: Array[Vector3] = []
var _time: float = 0.0


func _ready() -> void:
	call_deferred("_build")


func tent_count() -> int:
	var n := 0
	for child in get_children():
		if str(child.name).begins_with("Tent"):
			n += 1
	return n


func visit() -> void:
	var bounds := get_parent().get_node_or_null("PlayBounds")
	if bounds and bounds.has_method("open_camp"):
		bounds.open_camp()
	_blue_hour()
	var player := get_parent().get_node_or_null("Player") as CharacterBody3D
	if player:
		var ground := _ground(Vector3(-2.0, 0.0, 24.0))
		player.velocity = Vector3.ZERO
		player.global_position = ground + Vector3(0.0, 0.2, 0.0)
	var line := get_parent().find_child("DialogueLabel", true, false) as Label
	if line:
		line.text = "Jonathan is by the fire. His hair is long, and his tunic is red."
	var david := get_parent().get_node_or_null("DavidMentor") as Node3D
	if david:
		david.global_position = _ground(_clearing + Vector3(1.15, 0.0, -0.35))


func _process(delta: float) -> void:
	_time += delta
	for i in _flames.size():
		var flame := _flames[i]
		var s := 0.85 + 0.2 * sin(_time * 3.0 + float(i))
		flame.scale = Vector3(s, 0.7 + 0.35 * sin(_time * 4.0 + float(i) * 1.7), s)
	for i in _banners.size():
		_banners[i].rotation.z = sin(_time * 0.7 + float(i)) * 0.12
	for i in _guards.size():
		var home: Vector3 = _guard_home[i]
		var along := sin(_time * 0.25 + float(i) * 1.4)
		_guards[i].global_position = home + Vector3(along * 1.2, 0.0, 0.0)


func _build() -> void:
	if _built:
		return
	_built = true
	var here := _ground(CAMP)
	_clearing = here
	_tent("TentLarge", here + Vector3(0.0, 0.0, 2.2), 1.7, Color(0.93, 0.86, 0.72))
	_tent("TentA", here + Vector3(-3.2, 0.0, 1.4), 1.05, Color(0.90, 0.84, 0.70))
	_tent("TentB", here + Vector3(3.0, 0.0, 1.6), 1.0, Color(0.88, 0.82, 0.68))
	_tent("TentC", here + Vector3(1.6, 0.0, 3.4), 0.9, Color(0.91, 0.85, 0.71))
	_fire(_ground(here + Vector3(0.2, 0.0, -1.2)))
	_banner(_ground(here + Vector3(-2.2, 0.0, 0.4)), Color(0.25, 0.38, 0.62))
	_banner(_ground(here + Vector3(2.4, 0.0, 0.2)), Color(0.55, 0.28, 0.32))
	_banner(_ground(here + Vector3(-4.0, 0.0, 2.6)), Color(0.55, 0.28, 0.32))
	_banner(_ground(here + Vector3(4.0, 0.0, 2.8)), Color(0.25, 0.38, 0.62))
	for spot in [Vector3(-4.5, 0.0, -0.5), Vector3(4.4, 0.0, -0.2), Vector3(-3.5, 0.0, 3.8), Vector3(3.6, 0.0, 4.0)]:
		_guard(_ground(here + spot))
	_place_jonathan(here)
	var light := OmniLight3D.new()
	light.name = "FireLight"
	light.light_color = Color(1.0, 0.62, 0.28)
	light.light_energy = 1.4
	light.omni_range = 8.0
	light.position = _ground(here + Vector3(0.2, 0.0, -1.2)) + Vector3(0.0, 0.8, 0.0)
	add_child(light)


func _tent(tent_name: String, at: Vector3, size: float, color: Color) -> void:
	var tent := MeshInstance3D.new()
	tent.name = tent_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.08
	mesh.bottom_radius = size
	mesh.height = size * 1.35
	mesh.radial_segments = 6
	mesh.material = _mat(color)
	tent.mesh = mesh
	tent.position = at + Vector3(0.0, mesh.height * 0.5, 0.0)
	add_child(tent)


func _fire(at: Vector3) -> void:
	for i in 3:
		var flame := MeshInstance3D.new()
		var mesh := PrismMesh.new()
		mesh.size = Vector3(0.28 + float(i) * 0.08, 0.55 + float(i) * 0.15, 0.08)
		mesh.material = _mat(Color(0.95, 0.45 - float(i) * 0.08, 0.12))
		flame.mesh = mesh
		flame.position = at + Vector3(float(i - 1) * 0.12, 0.35, 0.0)
		add_child(flame)
		_flames.append(flame)


func _banner(at: Vector3, color: Color) -> void:
	var pole := MeshInstance3D.new()
	var stick := BoxMesh.new()
	stick.size = Vector3(0.06, 2.2, 0.06)
	stick.material = _mat(Color(0.45, 0.32, 0.18))
	pole.mesh = stick
	pole.position = at + Vector3(0.0, 1.1, 0.0)
	add_child(pole)
	var cloth := MeshInstance3D.new()
	var flag := BoxMesh.new()
	flag.size = Vector3(0.7, 0.45, 0.04)
	flag.material = _mat(color)
	cloth.mesh = flag
	cloth.position = Vector3(0.35, 0.7, 0.0)
	pole.add_child(cloth)
	_banners.append(cloth)


func _guard(at: Vector3) -> void:
	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.22
	mesh.height = 1.15
	mesh.radial_segments = 6
	mesh.rings = 2
	mesh.material = _mat(Color(0.62, 0.5, 0.34))
	body.mesh = mesh
	body.position = at + Vector3(0.0, 0.7, 0.0)
	add_child(body)
	_guards.append(body)
	_guard_home.append(body.global_position)


func _place_jonathan(here: Vector3) -> void:
	var jon := preload("res://scripts/jonathan.gd").new()
	jon.name = "Jonathan"
	add_child(jon)
	jon.global_position = _ground(here + Vector3(-1.15, 0.0, -0.55))


func _blue_hour() -> void:
	var world := get_parent().get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world and world.environment and world.environment.sky:
		var sky := world.environment.sky.sky_material as ProceduralSkyMaterial
		if sky:
			sky.sky_top_color = Color(0.45, 0.62, 0.86)
			sky.sky_horizon_color = Color(0.72, 0.8, 0.9)
			sky.ground_horizon_color = Color(0.62, 0.7, 0.82)
		world.environment.ambient_light_color = Color(0.75, 0.82, 0.95)
		world.environment.fog_light_color = Color(0.7, 0.78, 0.9)
	var sun := get_parent().get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		sun.light_color = Color(0.75, 0.82, 0.95)
		sun.light_energy = 0.55


func _ground(at: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	if space == null:
		return at
	var query := PhysicsRayQueryParameters3D.create(Vector3(at.x, 40.0, at.z), Vector3(at.x, -5.0, at.z))
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return at
	return hit.position


func _mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return mat
