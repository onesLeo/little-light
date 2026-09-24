extends Node3D
## Noah's Ark, built the first time it is visited so the valley and the camp
## do not pay for it. Paper hull, six animal pairs, and three weather states.

const Paper := preload("res://scripts/camp_paper.gd")
const ChapterFour := preload("res://scripts/chapter_four.gd")
const Profiles := preload("res://scripts/profiles.gd")
const Motion := preload("res://scripts/chapter_two_character_motion.gd")
const ArkPerson := preload("res://scripts/ark_person.gd")

const ORIGIN := Vector3(96.0, 0.0, 8.0)
const START_LOCAL := Vector3(0.0, 0.2, 8.0)
const GUIDED := ["SheepA", "DoveA", "ElephantA"]
const MATE_OF := {
	"SheepA": "SheepB", "DoveA": "DoveB", "ElephantA": "ElephantB",
	"GoatA": "GoatB", "RabbitA": "RabbitB", "GiraffeA": "GiraffeB",
}

var _built: bool = false
var _time: float = 0.0
var _rain: Node3D
var _rainbow: Node3D
var _bands: Array[MeshInstance3D] = []
var _rope: MeshInstance3D
var _panel: MeshInstance3D
var _noah: Node3D
var _wife: Node3D


func visit() -> void:
	Profiles.current_chapter = Profiles.CHAPTER_ARK
	_build()
	var main := get_parent()
	var director := main.get_node_or_null("ChapterDirector")
	if director and director.has_method("stand_down"):
		director.stand_down()
	var menu := main.get_node_or_null("GameMenu")
	if menu and menu.has_method("hide_end_panel"):
		menu.hide_end_panel()
	var bounds := main.get_node_or_null("PlayBounds")
	if bounds and bounds.has_method("open_ark"):
		bounds.open_ark()
	var soundscape := main.get_node_or_null("Soundscape")
	if soundscape and soundscape.has_method("set_night"):
		soundscape.set_night(false)
	set_weather("building")
	var player := main.get_node_or_null("Player") as CharacterBody3D
	if player:
		player.velocity = Vector3.ZERO
		player.global_position = _at(START_LOCAL)
		var cam := main.get_node_or_null("TabletopCamera") as Camera3D
		if cam and "offset" in cam:
			cam.offset = Vector3(0.0, 7.4, 8.4)
			if "look_height" in cam:
				cam.set("look_height", 0.9)
			cam.fov = 35.0
			cam.global_position = player.global_position + cam.offset
			cam.look_at(player.global_position + Vector3(0.0, 0.9, 0.0), Vector3.UP)
		_set_building_light(main)
		var light := main.get_node_or_null("WonderLight") as Node3D
		if light and "hover_offset" in light:
			light.global_position = player.global_position + light.hover_offset
	var story := get_node_or_null("ChapterFour")
	if story and story.has_method("begin"):
		story.begin()


func _build() -> void:
	if _built:
		return
	_built = true
	_ground()
	_plain_dressing()
	_hull()
	_items()
	_animals()
	_people()
	_family()
	_dove()
	_rain = Node3D.new()
	_rain.name = "Rain"
	add_child(_rain)
	for i in 4:
		Paper.part(_rain, "Sheet%d" % i, Paper.box(Vector3(16.0, 0.04, 8.0)), Color(0.62, 0.7, 0.78, 1.0),
				_at(Vector3(-2.0 + i * 0.4, 6.5 - i * 0.3, 2.0 - i * 1.5)), Vector3(0.4, 0.2 * i, 0.0), Vector3.ONE, 0.0)
	_rain.visible = false
	_rainbow = Node3D.new()
	_rainbow.name = "Rainbow"
	add_child(_rainbow)
	var colours := [Color(0.85, 0.28, 0.28), Color(0.92, 0.72, 0.28), Color(0.4, 0.7, 0.42), Color(0.38, 0.55, 0.85)]
	for i in colours.size():
		var band := Paper.part(_rainbow, "Band%d" % i, Paper.box(Vector3(12.0, 0.28, 0.2)), colours[i],
				_at(Vector3(0.0, 4.2 + i * 0.38, -14.0)), Vector3.ZERO, Vector3.ONE, 0.02)
		_bands.append(band)
	_rainbow.visible = false
	var story := Node.new()
	story.name = "ChapterFour"
	story.set_script(ChapterFour)
	add_child(story)


func _at(local: Vector3) -> Vector3:
	return ORIGIN + local


func _ground() -> void:
	var body := StaticBody3D.new()
	body.name = "Plain"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 1.0, 36.0)
	shape.shape = box
	body.add_child(shape)
	body.position = _at(Vector3(0.0, -0.5, 2.0))
	add_child(body)
	Paper.part(self, "Earth", Paper.box(Vector3(40.0, 0.08, 36.0)), Color(0.69, 0.59, 0.44),
			_at(Vector3(0.0, 0.02, 2.0)), Vector3.ZERO, Vector3.ONE, 0.0)


func _set_building_light(main: Node) -> void:
	# Chapter 2 leaves the shared world at blue hour; the ark opens in daylight.
	var world := main.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world and world.environment:
		var env := world.environment
		if env.sky:
			var sky := env.sky.sky_material as ProceduralSkyMaterial
			if sky:
				sky.sky_top_color = Color(0.43, 0.67, 0.86)
				sky.sky_horizon_color = Color(0.91, 0.82, 0.66)
				sky.ground_horizon_color = Color(0.7, 0.61, 0.47)
				sky.ground_bottom_color = Color(0.42, 0.36, 0.3)
			env.ambient_light_color = Color(0.88, 0.81, 0.68)
			env.ambient_light_energy = 0.9
			env.fog_light_color = Color(0.79, 0.7, 0.56)
			env.fog_density = 0.0015
	var sun := main.get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		sun.light_color = Color(1.0, 0.9, 0.73)
		sun.light_energy = 1.0
	var fill := main.get_node_or_null("FillLight") as DirectionalLight3D
	if fill:
		fill.light_color = Color(0.76, 0.84, 0.94)
		fill.light_energy = 0.4
	var backdrop := main.get_node_or_null("HorizonBackdrop")
	if backdrop and backdrop.has_method("set_daylight"):
		backdrop.set_daylight()


func _plain_dressing() -> void:
	# A worn path gives the child a clear line from the tools to the hull.
	Paper.part(self, "WornPath", Paper.box(Vector3(3.4, 0.035, 17.0)), Color(0.75, 0.63, 0.46),
			_at(Vector3(0.0, 0.075, 3.0)), Vector3(0.0, 0.025, 0.0), Vector3.ONE, 0.0)
	# Low paper dunes break up the empty horizon while leaving the ark in view.
	var dunes := [
		Vector4(-15.0, -10.0, 5.5, 1.7), Vector4(-8.0, -13.0, 4.3, 1.2),
		Vector4(10.0, -13.0, 5.0, 1.5), Vector4(16.0, -9.0, 4.4, 1.4),
	]
	for i in dunes.size():
		var d: Vector4 = dunes[i]
		Paper.part(self, "Dune%d" % i, Paper.sphere(1.0, 7),
				Color(0.75, 0.66, 0.52) if i % 2 == 0 else Color(0.79, 0.70, 0.57),
				_at(Vector3(d.x, d.w * 0.35, d.y)), Vector3.ZERO, Vector3(d.z, d.w, 2.1), 0.0)
	# Sparse olive scrub shows scale without cluttering the animal route.
	for i in 9:
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := side * (8.0 + float((i * 3) % 7))
		var z := 10.0 - float(i) * 2.4
		Paper.part(self, "ScrubStem%d" % i, Paper.cylinder(0.035, 0.42, 5), Color(0.42, 0.38, 0.24),
				_at(Vector3(x, 0.22, z)), Vector3(0.0, 0.0, 0.12 * side), Vector3.ONE, 0.0)
		Paper.part(self, "ScrubLeaf%d" % i, Paper.sphere(0.22, 6), Color(0.48, 0.53, 0.32),
				_at(Vector3(x + side * 0.12, 0.42, z)), Vector3.ZERO, Vector3(1.4, 0.7, 0.8), 0.0)


func _hull() -> void:
	Paper.part(self, "Keel", Paper.box(Vector3(11.8, 1.4, 11.2)), Color(0.48, 0.29, 0.15),
			_at(Vector3(0.0, 0.72, -4.0)), Vector3.ZERO, Vector3.ONE, 0.035)
	Paper.part(self, "Hull", Paper.box(Vector3(13.0, 2.0, 10.8)), Color(0.66, 0.43, 0.23),
			_at(Vector3(0.0, 1.75, -4.0)), Vector3.ZERO, Vector3.ONE, 0.035)
	Paper.part(self, "Deck", Paper.box(Vector3(12.6, 0.20, 10.1)), Color(0.76, 0.56, 0.32),
			_at(Vector3(0.0, 2.72, -4.0)), Vector3.ZERO, Vector3.ONE, 0.025)
	for side in [-1.0, 1.0]:
		for row in 3:
			Paper.part(self, "HullPlank", Paper.box(Vector3(0.22, 0.48, 10.1)),
					Color(0.53, 0.33, 0.17) if row % 2 == 0 else Color(0.72, 0.49, 0.27),
					_at(Vector3(side * 6.52, 0.68 + row * 0.58, -4.0)), Vector3.ZERO, Vector3.ONE, 0.012)
	for i in 6:
		var rib_z := -9.0 + float(i) * 1.9
		var rib := Paper.part(self, "Rib%d" % i, _ark_rib_mesh(0.34),
				Color(0.48, 0.29, 0.15) if i % 2 == 0 else Color(0.56, 0.35, 0.18),
				_at(Vector3(0.0, 0.0, rib_z)), Vector3.ZERO, Vector3.ONE, 0.025)
		rib.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Paper.part(self, "Entrance", Paper.box(Vector3(2.0, 1.9, 0.12)), Color(0.27, 0.17, 0.10),
			_at(Vector3(0.0, 1.62, 1.40)), Vector3.ZERO, Vector3.ONE, 0.025)
	Paper.part(self, "Ramp", Paper.box(Vector3(3.2, 0.16, 6.4)), Color(0.72, 0.51, 0.29),
			_at(Vector3(0.0, 0.95, 4.2)), Vector3(-0.19, 0.0, 0.0), Vector3.ONE, 0.02)
	for i in 5:
		Paper.part(self, "RampCleat", Paper.box(Vector3(3.0, 0.10, 0.10)), Color(0.45, 0.29, 0.16),
				_at(Vector3(0.0, 0.78 + i * 0.055, 1.8 + i * 0.95)), Vector3(-0.19, 0.0, 0.0), Vector3.ONE, 0.0)
	_panel = Paper.part(self, "WorkPanel", Paper.box(Vector3(2.4, 1.6, 0.18)), Color(0.72, 0.52, 0.3),
			_at(Vector3(5.3, 1.8, -2.1)), Vector3.ZERO, Vector3.ONE, 0.02)
	for i in 3:
		Paper.part(_panel, "Socket%d" % i, Paper.cylinder(0.08, 0.08, 8), Color(0.35, 0.22, 0.12),
				Vector3(-0.7 + i * 0.7, 0.15, 0.12), Vector3(PI / 2.0, 0.0, 0.0), Vector3.ONE, 0.0)
	_rope = Paper.part(self, "PanelRope", Paper.cylinder(0.05, 2.2, 6), Color(0.55, 0.4, 0.22),
			_at(Vector3(5.3, 2.45, -1.95)), Vector3(0.0, 0.0, PI / 2.0), Vector3.ONE, 0.0)


func _ark_rib_mesh(depth: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half_depth := depth * 0.5
	var half_beam := 0.12
	var steps := 10
	var arch_width := 6.25
	var spring_y := 2.72
	var rise := 3.55
	for step in steps:
		var a0 := PI * float(step) / steps
		var a1 := PI * float(step + 1) / steps
		var p0 := Vector2(cos(a0) * arch_width, spring_y + sin(a0) * rise)
		var p1 := Vector2(cos(a1) * arch_width, spring_y + sin(a1) * rise)
		var direction := (p1 - p0).normalized()
		var normal := Vector2(-direction.y, direction.x) * half_beam
		var front := [
			Vector3(p0.x + normal.x, p0.y + normal.y, -half_depth),
			Vector3(p0.x - normal.x, p0.y - normal.y, -half_depth),
			Vector3(p1.x - normal.x, p1.y - normal.y, -half_depth),
			Vector3(p1.x + normal.x, p1.y + normal.y, -half_depth),
		]
		var back := PackedVector3Array()
		for point in front:
			back.append(Vector3(point.x, point.y, half_depth))
		_add_rib_quad(surface, front[0], front[1], front[2], front[3])
		_add_rib_quad(surface, back[3], back[2], back[1], back[0])
		for edge in 4:
			var next := (edge + 1) % 4
			_add_rib_quad(surface, front[edge], back[edge], back[next], front[next])
	surface.generate_normals()
	return surface.commit()


func _add_rib_quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)
	surface.add_vertex(a)
	surface.add_vertex(c)
	surface.add_vertex(d)


func _items() -> void:
	_tool("Mallet", _at(Vector3(-4.0, 0.35, 6.0)), Color(0.55, 0.34, 0.16))
	_tool("RopeCoil", _at(Vector3(4.2, 0.3, 5.4)), Color(0.62, 0.46, 0.24))
	_tool("Pitch", _at(Vector3(0.0, 0.35, 3.2)), Color(0.25, 0.2, 0.16))


func _tool(tool_name: String, at: Vector3, color: Color) -> void:
	var root := Node3D.new()
	root.name = tool_name
	root.position = at
	add_child(root)
	Paper.part(root, "Body", Paper.box(Vector3(0.45, 0.28, 0.45)), color, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, 0.015)


func _animals() -> void:
	_critter("SheepA", "sheep", Vector3(-5.5, 0.0, 5.0))
	_critter("SheepB", "sheep", Vector3(4.6, 0.0, 2.0))
	_critter("DoveA", "dove", Vector3(-2.3, 0.0, 5.4))
	_critter("DoveB", "dove", Vector3(3.0, 0.0, 3.1))
	_critter("ElephantA", "elephant", Vector3(6.0, 0.0, 4.0))
	_critter("ElephantB", "elephant", Vector3(5.3, 0.0, 1.6))
	_critter("GoatA", "goat", Vector3(-8.0, 0.0, 3.0))
	_critter("GoatB", "goat", Vector3(-5.5, 0.0, 1.0))
	_critter("RabbitA", "rabbit", Vector3(8.0, 0.0, 5.0))
	_critter("RabbitB", "rabbit", Vector3(6.0, 0.0, 2.8))
	_critter("GiraffeA", "giraffe", Vector3(-4.0, 0.0, 2.0))
	_critter("GiraffeB", "giraffe", Vector3(-2.2, 0.0, 0.2))


func _critter(critter_name: String, kind: String, at: Vector3) -> void:
	var root := Node3D.new()
	root.name = critter_name
	root.position = _at(at)
	root.set_meta("kind", kind)
	root.set_meta("home", root.position)
	root.set_meta("aboard", false)
	add_child(root)
	match kind:
		"sheep":
			Paper.part(root, "Body", Paper.sphere(0.38, 8), Color(0.95, 0.93, 0.86), Vector3(0.0, 0.4, 0.0), Vector3.ZERO, Vector3(1.2, 0.9, 1.0), 0.02)
			Paper.part(root, "Head", Paper.sphere(0.16, 8), Color(0.93, 0.9, 0.82), Vector3(0.0, 0.62, 0.28), Vector3.ZERO, Vector3.ONE, 0.01)
		"goat":
			Paper.part(root, "Body", Paper.sphere(0.32, 8), Color(0.72, 0.58, 0.4), Vector3(0.0, 0.4, 0.0), Vector3.ZERO, Vector3(1.0, 0.85, 1.15), 0.02)
			Paper.part(root, "Horn", Paper.cylinder(0.03, 0.22, 5), Color(0.45, 0.34, 0.22), Vector3(0.08, 0.72, 0.16), Vector3.ZERO, Vector3.ONE, 0.0)
		"rabbit":
			Paper.part(root, "Body", Paper.sphere(0.22, 8), Color(0.9, 0.86, 0.8), Vector3(0.0, 0.24, 0.0), Vector3.ZERO, Vector3.ONE, 0.015)
			Paper.part(root, "Ear", Paper.box(Vector3(0.06, 0.28, 0.04)), Color(0.9, 0.8, 0.75), Vector3(0.06, 0.5, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
		"dove":
			Paper.part(root, "Body", Paper.sphere(0.16, 8), Color(0.96, 0.96, 0.93), Vector3(0.0, 0.28, 0.0), Vector3.ZERO, Vector3(1.3, 0.8, 1.0), 0.01)
			Paper.part(root, "Wing", Paper.box(Vector3(0.34, 0.04, 0.12)), Color(0.9, 0.9, 0.86), Vector3(0.0, 0.3, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
		"elephant":
			Paper.part(root, "Body", Paper.sphere(0.55, 8), Color(0.62, 0.64, 0.66), Vector3(0.0, 0.6, 0.0), Vector3.ZERO, Vector3(1.3, 1.0, 1.0), 0.02)
			Paper.part(root, "Trunk", Paper.cylinder(0.06, 0.45, 6), Color(0.58, 0.6, 0.62), Vector3(0.0, 0.4, 0.45), Vector3(0.6, 0.0, 0.0), Vector3.ONE, 0.0)
		"giraffe":
			Paper.part(root, "Body", Paper.sphere(0.28, 8), Color(0.86, 0.7, 0.38), Vector3(0.0, 0.7, 0.0), Vector3.ZERO, Vector3(1.1, 0.7, 0.8), 0.02)
			Paper.part(root, "Neck", Paper.cylinder(0.08, 0.9, 6), Color(0.9, 0.74, 0.4), Vector3(0.0, 1.35, 0.15), Vector3.ZERO, Vector3.ONE, 0.01)


func _people() -> void:
	# In front of the crowd, facing the child. The model faces the ark until turned.
	_noah = _designed("Noah", "noah", Vector3(-0.4, 0.0, 5.6))
	_wife = _designed("NoahsWife", "wife", Vector3(1.5, 0.0, 5.2))


func _designed(person_name: String, who: String, at: Vector3) -> Node3D:
	var person := Node3D.new()
	person.name = person_name
	person.set_script(ArkPerson)
	person.who = who
	person.position = _at(at)
	person.rotation.y = PI
	add_child(person)
	return person


func _person(person_name: String, at: Vector3, cloth: Color, hair: Color, beard: bool) -> Node3D:
	var root := Node3D.new()
	root.name = person_name
	root.position = at
	add_child(root)
	Paper.part(root, "Body", Paper.capsule(0.28, 0.9), cloth, Vector3(0.0, 0.7, 0.0), Vector3.ZERO, Vector3.ONE, 0.02)
	Paper.part(root, "Head", Paper.sphere(0.2, 10), Color(0.93, 0.78, 0.62), Vector3(0.0, 1.35, 0.0), Vector3.ZERO, Vector3.ONE, 0.015)
	Paper.part(root, "Hair", Paper.sphere(0.16, 8), hair, Vector3(0.0, 1.5, -0.02), Vector3.ZERO, Vector3(1.1, 0.6, 1.0), 0.0)
	if beard:
		Paper.part(root, "Beard", Paper.sphere(0.12, 8), hair, Vector3(0.0, 1.22, 0.1), Vector3.ZERO, Vector3(1.0, 0.7, 0.6), 0.0)
	Paper.part(root, "Belt", Paper.box(Vector3(0.5, 0.08, 0.32)), Color(0.2, 0.14, 0.1), Vector3(0.0, 0.85, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
	var hand := Node3D.new()
	hand.name = "Hand"
	hand.position = Vector3(0.34, 0.95, 0.12)
	root.add_child(hand)
	Paper.part(hand, "Palm", Paper.sphere(0.08, 8), Color(0.93, 0.78, 0.62), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, 0.0)
	return root


func _family() -> void:
	var colours := [Color(0.55, 0.4, 0.28), Color(0.4, 0.5, 0.45), Color(0.7, 0.55, 0.4), Color(0.45, 0.38, 0.5), Color(0.6, 0.48, 0.32), Color(0.36, 0.48, 0.55)]
	for i in colours.size():
		var person := _person("Family%d" % i, _at(Vector3(-2.5 + (i % 3) * 1.3, 0.0, 2.4 + int(i / 3) * 1.1)), colours[i], Color(0.3, 0.2, 0.12), false)
		person.set_meta("home", person.position)


func _dove() -> void:
	var dove := Node3D.new()
	dove.name = "WindowDove"
	dove.position = _at(Vector3(6.6, 3.0, -5.4))
	add_child(dove)
	Paper.part(dove, "Body", Paper.sphere(0.14, 8), Color(0.97, 0.97, 0.94), Vector3.ZERO, Vector3.ZERO, Vector3(1.4, 0.8, 1.0), 0.01)
	var leaf := Paper.part(dove, "Leaf", Paper.box(Vector3(0.16, 0.05, 0.08)), Color(0.4, 0.62, 0.32), Vector3(0.16, -0.02, 0.08), Vector3.ZERO, Vector3.ONE, 0.0)
	leaf.visible = false


func set_weather(state: String) -> void:
	if _rain:
		_rain.visible = state == "rain"
	if _rainbow:
		_rainbow.visible = state == "morning"
	if state == "morning":
		var tw := create_tween()
		for band in _bands:
			band.scale = Vector3(0.05, 1.0, 1.0)
			tw.tween_property(band, "scale", Vector3.ONE, 0.35)


func set_speaking(who: String) -> void:
	if _noah and "speaking" in _noah:
		_noah.speaking = who == "Noah"
	if _wife and "speaking" in _wife:
		_wife.speaking = who == "Noah's wife"


func nearest_item(from: Vector3, reach: float) -> String:
	var best := ""
	var best_d := reach
	for tool_name in ["Mallet", "RopeCoil", "Pitch"]:
		var tool := get_node_or_null(tool_name) as Node3D
		if tool == null or not tool.visible:
			continue
		var d := tool.global_position.distance_to(from)
		if d < best_d:
			best_d = d
			best = tool_name
	return best


func take_item(tool_name: String) -> void:
	var tool := get_node_or_null(tool_name) as Node3D
	if tool:
		tool.visible = false


func show_peg(index: int) -> void:
	if _panel == null:
		return
	Paper.part(_panel, "Peg%d" % index, Paper.cylinder(0.07, 0.22, 8), Color(0.85, 0.7, 0.4),
			Vector3(-0.7 + index * 0.7, 0.2, 0.2), Vector3(PI / 2.0, 0.0, 0.0), Vector3.ONE, 0.0)
	var mat := _panel.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = Color(0.72, 0.52, 0.3).lerp(Color(0.55, 0.36, 0.18), float(index + 1) / 3.0)


func set_rope(amount: float) -> void:
	if _rope:
		_rope.scale = Vector3(1.0, lerpf(1.15, 0.72, clampf(amount, 0.0, 1.0)), 1.0)


func nearest_guide(from: Vector3, reach: float) -> String:
	var best := ""
	var best_d := reach
	for critter_name in GUIDED:
		var animal := get_node_or_null(critter_name) as Node3D
		if animal == null or bool(animal.get_meta("aboard")):
			continue
		var d := animal.global_position.distance_to(from)
		if d < best_d:
			best_d = d
			best = critter_name
	return best


func follow(critter_name: String, target: Vector3, delta: float) -> void:
	var animal := get_node_or_null(critter_name) as Node3D
	if animal == null:
		return
	var next := animal.global_position.move_toward(target, 3.2 * delta)
	animal.global_position = next
	var flat := target - animal.global_position
	flat.y = 0.0
	if flat.length() > 0.05:
		animal.rotation.y = atan2(flat.x, flat.z)


func near_mate(critter_name: String, reach: float) -> bool:
	var animal := get_node_or_null(critter_name) as Node3D
	var mate := get_node_or_null(str(MATE_OF.get(critter_name, ""))) as Node3D
	return animal != null and mate != null and animal.global_position.distance_to(mate.global_position) <= reach


func wrong_mate_near(critter_name: String, reach: float) -> bool:
	var animal := get_node_or_null(critter_name) as Node3D
	if animal == null:
		return false
	var kind := str(animal.get_meta("kind"))
	for other_name in MATE_OF.values():
		if other_name == str(MATE_OF[critter_name]):
			continue
		var other := get_node_or_null(str(other_name)) as Node3D
		if other and str(other.get_meta("kind")) != kind and animal.global_position.distance_to(other.global_position) <= reach:
			return true
	return false


func board_pair(critter_name: String) -> void:
	var mate_name := str(MATE_OF.get(critter_name, ""))
	_board_one(critter_name, 0.0)
	_board_one(mate_name, 0.6)


func board_remaining() -> void:
	var slot := 0.0
	for critter_name in MATE_OF.keys():
		var animal := get_node_or_null(critter_name) as Node3D
		if animal and not bool(animal.get_meta("aboard")):
			board_pair(critter_name)
			slot += 1.0


func aboard_count() -> int:
	var n := 0
	for child in get_children():
		if child is Node3D and child.has_meta("aboard") and bool(child.get_meta("aboard")):
			n += 1
	return n


func _board_one(critter_name: String, side: float) -> void:
	var animal := get_node_or_null(critter_name) as Node3D
	if animal == null or bool(animal.get_meta("aboard")):
		return
	animal.set_meta("aboard", true)
	animal.position = _at(Vector3(-2.0 + side, 1.3, -4.0))


func family_inside() -> void:
	if _noah:
		_noah.position = _at(Vector3(-1.0, 0.0, -4.8))
	if _wife:
		_wife.position = _at(Vector3(0.4, 0.0, -4.6))
	for i in 6:
		var person := get_node_or_null("Family%d" % i) as Node3D
		if person:
			person.position = _at(Vector3(-2.2 + (i % 3) * 0.8, 0.0, -4.3 - int(i / 3) * 0.5))


func keep_guest_outside(player: Node3D) -> void:
	if player == null:
		return
	var local := player.global_position - ORIGIN
	if local.z < -3.0:
		player.global_position = _at(START_LOCAL)
		if "velocity" in player:
			player.velocity = Vector3.ZERO


func dove() -> Node3D:
	return get_node_or_null("WindowDove") as Node3D


func show_leaf(on: bool) -> void:
	var dove := dove()
	if dove:
		var leaf := dove.get_node_or_null("Leaf") as Node3D
		if leaf:
			leaf.visible = on


func _process(delta: float) -> void:
	if not _built:
		return
	_time += delta
	_live(_noah, 0.0)
	_live(_wife, 1.4)
	for child in get_children():
		if child is Node3D and child.has_meta("kind") and not bool(child.get_meta("aboard")):
			var bob := sin(_time * 1.6 + float(str(child.name).hash()) * 0.001) * 0.03
			child.position.y = (child.get_meta("home") as Vector3).y + bob


func _live(person: Node3D, offset: float) -> void:
	if person == null:
		return
	var body := person.get_node_or_null("Body") as Node3D
	if body:
		body.position.y = 0.7 + Motion.breath(_time + offset) * 0.015
	var hand := person.get_node_or_null("Hand") as Node3D
	if hand:
		var talking := bool(person.get_meta("speaking", false))
		hand.rotation.x = -0.7 * Motion.speaking_pulse(_time + offset) if talking else 0.0
		hand.rotation.z = 0.15 if talking else 0.0
