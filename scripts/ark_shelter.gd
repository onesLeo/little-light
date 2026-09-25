extends Node3D
## A small open-front paper stage for the protected family, rain window and dove.
## A dedicated render layer keeps the outdoor mountain out of these intimate shots.
const Paper := preload("res://scripts/camp_paper.gd")
const Person := preload("res://scripts/ark_person.gd")
const LAYER := 1 << 10
const PERCH := Vector3(3.8, 2.9, -2.6)
const Sea := preload("res://assets/shaders/flood_sea.gdshader")
## The sea sits just under the deck floor and runs out to a far horizon behind the sky card.
const SEA_Y := -0.6
const SEA_Y_RECEDING := -1.0
var camera: Camera3D
var bird: Node3D
var rain: Node3D
var lamp: OmniLight3D
var _flight: Tween
var _camera_move: Tween
var _flapping := false
var _time := 0.0
var _shot := ""
var _rests: Array[Node3D] = []
var _sky_tween: Tween
var _sky_state := ""


func build(ark: Node3D) -> void:
	var timber := Color(0.52, 0.34, 0.22)
	var cream := Color(0.85, 0.72, 0.49)
	for i in 15:
		part("Floor", Vector3(0.94, 0.15, 7.0), timber.lightened(0.04 * (i % 3)), Vector3(-7.0 + i, 0, 0))
	part("BackLeft", Vector3(9.8, 4.8, 0.2), timber, Vector3(-2.1, 2.4, -3.5))
	part("BackRight", Vector3(1.6, 4.8, 0.2), timber, Vector3(6.2, 2.4, -3.5))
	part("BelowWindow", Vector3(2.6, 2.4, 0.2), timber, Vector3(4.1, 1.2, -3.5))
	part("AboveWindow", Vector3(2.6, 0.5, 0.2), timber, Vector3(4.1, 4.55, -3.5))
	for i in 8:
		part("PlankSeam", Vector3(9.6, 0.025, 0.025), timber.darkened(0.18), Vector3(-2.1, 0.35 + i * 0.55, -3.36))
	part("LeftSide", Vector3(0.2, 4.8, 3.4), timber.darkened(0.05), Vector3(-7.1, 2.4, -1.9))
	part("FrontBeam", Vector3(14.4, 0.2, 0.25), cream.darkened(0.2), Vector3(0, 4.85, -0.2))
	for x in [-6.9, -2.0, 2.8, 5.4, 7.0]:
		part("Rib", Vector3(0.22, 4.8, 0.32), cream.darkened(0.15), Vector3(x, 2.4, -3.25))
	part("RoofBeam", Vector3(14.4, 0.3, 0.45), timber.darkened(0.18), Vector3(0, 4.9, -2.8))
	part("Sill", Vector3(3.1, 0.16, 0.95), cream, Vector3(4.1, 2.55, -3.05))
	part("OutsideSky", Vector3(1400, 700, 0.1), Color(0.43, 0.54, 0.66), Vector3(0, 330, -300))
	_build_sea()
	for i in 4:
		part("StrawBed", Vector3(2.4, 0.08, 1.4), cream.darkened(0.05), Vector3(-5.0 + i * 3.3, 0.14, 1.3))
	for i in 2:
		var person := Person.new()
		person.who = "noah" if i == 0 else "wife"
		person.name = "ShelterNoah" if i == 0 else "ShelterWife"
		add_child(person)
		person.position = Vector3(-1.8 + i * 2.0, 0.1, -1.3)
		person.rotation.y = -0.25 if i == 0 else 0.25
	for i in 6:
		var source := ark.get_node("Family%d" % i) as Node3D
		var person := source.duplicate() as Node3D
		add_child(person)
		person.visible = true
		person.position = Vector3(-5.3 + (i % 3) * 1.4, 0.1, -2.4 + (i / 3) * 1.3)
		person.rotation = Vector3.ZERO
	for i in 6:
		var names := ["SheepA", "SheepB", "RabbitA", "RabbitB", "GoatA", "GoatB"]
		var animal := ark.get_node(names[i]).duplicate() as Node3D
		add_child(animal)
		animal.visible = true
		animal.position = Vector3(-5.2 + i * 1.9, 0.2, 1.5)
		animal.rotation = Vector3(0, -0.3 + i * 0.12, 0)
		animal.scale = Vector3.ONE * 0.9
		for child in animal.get_children():
			if child.name in ["Beacon", "Ring"]:
				child.visible = false
		_rests.append(animal)
	bird = ark.get_node("WindowDove").duplicate() as Node3D
	bird.name = "ShelterDove"
	add_child(bird)
	bird.position = PERCH
	bird.scale = Vector3.ONE * 1.5
	for side in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.name = "WingLeft" if side < 0 else "WingRight"
		bird.add_child(wing)
		wing.position = Vector3(0, 0, side * 0.06)
		Paper.part(wing, "Feathers", Paper.box(Vector3(0.21, 0.025, 0.3)), Color(0.9, 0.91, 0.87), Vector3(-0.02, 0, side * 0.15), Vector3.ZERO, Vector3.ONE, 0.009)
	rain = Node3D.new()
	rain.name = "WindowRain"
	add_child(rain)
	for i in 42:
		Paper.part(rain, "Drop", Paper.box(Vector3(0.022, 0.38, 0.022)), Color(0.74, 0.83, 0.9), Vector3(2.9 + fmod(i * 0.37, 2.5), 2.6 + fmod(i * 0.23, 1.7), -4.1), Vector3(0, 0, 0.12), Vector3.ONE, 0)
	lamp = OmniLight3D.new()
	lamp.name = "WarmShelterLight"
	lamp.position = Vector3(0, 3.5, 0.8)
	lamp.light_color = Color(1.0, 0.84, 0.61)
	lamp.light_energy = 1.4
	lamp.omni_range = 13.0
	lamp.light_cull_mask = LAYER
	add_child(lamp)
	part("LanternCord", Vector3(0.025, 1.2, 0.025), timber.darkened(0.3), Vector3(0, 4.1, 0.8))
	Paper.part(self, "Lantern", Paper.sphere(0.16, 8), Color(1, 0.8, 0.45), lamp.position, Vector3.ZERO, Vector3.ONE, 0.015)
	# Outdoor paper layers keep their cool colours under the warm interior light.
	get_node("OutsideSky").material_override = Paper.glow_mat(Color(0.43, 0.54, 0.66))
	get_node("Lantern").material_override = Paper.glow_mat(Color(1, 0.8, 0.45))
	for drop in rain.get_children():
		drop.material_override = Paper.glow_mat(Color(0.74, 0.83, 0.9))
	camera = Camera3D.new()
	camera.name = "ShelterCamera"
	camera.cull_mask = LAYER
	camera.fov = 48
	camera.environment = ark.get_parent().get_node("WorldEnvironment").environment.duplicate()
	camera.environment.ambient_light_color = Color(0.95, 0.9, 0.8)
	camera.environment.ambient_light_energy = 0.7
	camera.environment.fog_enabled = false
	add_child(camera)
	_set_layer(self)
	visible = false


## The open water outside: a wide subdivided plane under the flood shader, keeping its own
## cool colours under the warm lamp.
func _build_sea() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(600, 420)
	plane.subdivide_width = 120
	plane.subdivide_depth = 84
	var mat := ShaderMaterial.new()
	mat.shader = Sea
	mat.set_shader_parameter("self_lit", 1.0)
	mat.set_shader_parameter("swell_height", 0.16)
	mat.set_shader_parameter("haze_start", 20.0)
	mat.set_shader_parameter("haze_end", 200.0)
	mat.set_shader_parameter("horizon_color", Color(0.47, 0.57, 0.68))
	var sea := MeshInstance3D.new()
	sea.name = "OutsideWater"
	sea.mesh = plane
	sea.material_override = mat
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sea.position = Vector3(0, SEA_Y, -90)
	add_child(sea)


func part(label: String, size: Vector3, color: Color, at: Vector3) -> void:
	Paper.part(self, label, Paper.box(size), color, at, Vector3.ZERO, Vector3.ONE, 0.0 if label.begins_with("Outside") else 0.018)


func _set_layer(node: Node) -> void:
	if node is VisualInstance3D:
		node.layers = LAYER
	for child in node.get_children():
		_set_layer(child)


func show_shot(shot: String) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	camera.current = true
	if shot == _shot:
		return
	var at := Vector3(2.0, 5.6, 14.5)
	var look := Vector3(0, 2.0, -0.8)
	if shot == "window":
		at = Vector3(7.7, 5.3, 7.7)
		look = Vector3(4.6, 3.4, -3.4)
	elif shot == "leaf":
		at = PERCH + Vector3(1.3, 0.8, 2.7)
		look = PERCH + Vector3(0.1, 0.1, 0)
	if _camera_move:
		_camera_move.kill()
	var start := camera.position
	var start_rotation := camera.quaternion
	camera.position = at
	camera.look_at(to_global(look), Vector3.UP)
	var finish_rotation := camera.quaternion
	if not _shot.is_empty():
		camera.position = start
		camera.quaternion = start_rotation
		_camera_move = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_camera_move.tween_property(camera, "position", at, 1.2)
		_camera_move.tween_property(camera, "quaternion", finish_rotation, 1.2)
	_shot = shot


func fly(with_leaf: bool) -> void:
	if _flight and _flight.is_running():
		return
	bird.get_node("Leaf").visible = false
	_flapping = true
	_flight = create_tween()
	_flight.tween_method(func(t: float) -> void:
		var angle := TAU * t
		bird.position = PERCH + Vector3(3.3 * sin(angle) * sin(PI * t), 2.2 * sin(PI * t), -3.0 * sin(PI * t))
		var tangent := Vector3(3.3 * (TAU * cos(angle) * sin(PI * t) + PI * sin(angle) * cos(PI * t)), 0, -3.0 * PI * cos(PI * t))
		bird.rotation.y = -atan2(tangent.z, tangent.x)
		bird.rotation.z = sin(angle) * 0.16
		if with_leaf and t > 0.55:
			bird.get_node("Leaf").visible = true
	, 0.0, 1.0, 4.6)
	_flight.tween_callback(func() -> void: _flapping = false)
	_flight.tween_property(bird, "rotation", Vector3.ZERO, 0.35)
	_flight.tween_property(bird, "position", PERCH + Vector3(0, -0.035, 0), 0.12)
	_flight.tween_property(bird, "position", PERCH, 0.2)
	await _flight.finished


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	for drop in rain.get_children():
		drop.position.y = 2.6 + fposmod(drop.position.y - 2.6 - delta * 3.2, 1.7)
	for i in _rests.size():
		var animal := _rests[i]
		animal.scale.y = 0.9 + sin(_time * 1.5 + i) * 0.007
	var flap := sin(_time * 22.0) * 0.8 if _flapping else 0.12
	bird.get_node("WingLeft").rotation.x = flap
	bird.get_node("WingRight").rotation.x = -flap


func set_sky(state: String) -> void:
	if state == _sky_state:
		return
	_sky_state = state
	if _sky_tween:
		_sky_tween.kill()
	var sky := get_node("OutsideSky") as MeshInstance3D
	var material := sky.material_override.duplicate() as StandardMaterial3D
	sky.material_override = material
	var color := Color(0.43, 0.54, 0.66) if state == "rain" else Color(0.66, 0.75, 0.8)
	var sea := get_node("OutsideWater") as MeshInstance3D
	var sea_mat := sea.material_override as ShaderMaterial
	var horizon: Color = sea_mat.get_shader_parameter("horizon_color")
	_sky_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	_sky_tween.tween_property(material, "albedo_color", color, 2.0)
	# The far water takes the sky's colour, so the horizon stays one soft line.
	_sky_tween.tween_method(func(c: Color) -> void: sea_mat.set_shader_parameter("horizon_color", c),
			horizon, color.lerp(Color.WHITE, 0.08), 2.0)
	_sky_tween.tween_property(sea, "position:y", SEA_Y_RECEDING if state == "receding" else SEA_Y, 2.5)
