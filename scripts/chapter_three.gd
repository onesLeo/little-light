extends Node3D
## Lazy-built Chapter 3 greybox. It establishes the courtyard layout and stable
## staging anchors before final characters, interaction, voices, and art land.

const Paper := preload("res://scripts/camp_paper.gd")
const PaperUI := preload("res://scripts/paper_ui.gd")
const Profiles := preload("res://scripts/profiles.gd")

const CENTRE := Vector3(58.0, 0.0, 2.0)
const ARRIVAL := Vector3(58.0, 0.25, 10.0)
const EARTH := Color(0.68, 0.55, 0.38)
const LIMESTONE := Color(0.78, 0.69, 0.53)
const WOOD := Color(0.39, 0.25, 0.13)
const BROTHER_TUNICS := [
	Color(0.58, 0.32, 0.22), Color(0.50, 0.44, 0.25), Color(0.36, 0.46, 0.35),
	Color(0.68, 0.51, 0.28), Color(0.48, 0.35, 0.45), Color(0.63, 0.39, 0.25),
	Color(0.42, 0.48, 0.54),
]
const SKINS := [Color(0.78, 0.53, 0.34), Color(0.68, 0.43, 0.27), Color(0.84, 0.61, 0.42)]

var _built := false
var _active := false
var _courtyard: Node3D
var _hud: CanvasLayer
var _idle_parts: Array[Node3D] = []
var _time := 0.0


func is_built() -> bool:
	return _built


func is_active() -> bool:
	return _active


func visit() -> void:
	Profiles.current_chapter = Profiles.CHAPTER_BEGINNING
	_build()
	_active = true
	visible = true
	_hud.visible = true
	var main := get_parent()
	var camp := main.get_node_or_null("KingsCamp") as Node3D
	if camp:
		camp.visible = false
	var director := main.get_node_or_null("ChapterDirector")
	if director and director.has_method("stand_down"):
		director.stand_down()
	var menu := main.get_node_or_null("GameMenu")
	if menu and menu.has_method("hide_end_panel"):
		menu.hide_end_panel()
	var bounds := main.get_node_or_null("PlayBounds")
	if bounds and bounds.has_method("open_beginning"):
		bounds.open_beginning(Vector2(CENTRE.x, CENTRE.z))
	_set_morning()
	var player := main.get_node_or_null("Player") as CharacterBody3D
	if player:
		player.velocity = Vector3.ZERO
		player.global_position = ARRIVAL
		player.can_move = true
		_snap_followers(player)
	var line := main.find_child("DialogueLabel", true, false) as Label
	if line:
		line.text = "Years earlier, Samuel comes to Jesse's home. Who might be missing?"
	var prompt := main.find_child("PromptLabel", true, false) as Label
	if prompt:
		prompt.text = "Chapter 3 greybox — explore the courtyard"


func leave() -> void:
	_active = false
	if _hud:
		_hud.visible = false
	visible = false


func _process(delta: float) -> void:
	if not _active:
		return
	_time += delta
	for i in _idle_parts.size():
		var part := _idle_parts[i]
		if is_instance_valid(part):
			part.rotation.y = sin(_time * (0.55 + float(i % 3) * 0.08) + float(i)) * 0.10


func _build() -> void:
	if _built:
		return
	_built = true
	_courtyard = Node3D.new()
	_courtyard.name = "Courtyard"
	add_child(_courtyard)
	_build_ground()
	_build_house()
	_build_tree_and_table()
	_build_fold()
	_build_people()
	_build_markers()
	_build_hud()


func _build_ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "CourtyardGround"
	ground.position = CENTRE + Vector3(0.0, -0.3, 0.0)
	_courtyard.add_child(ground)
	Paper.part(ground, "Earth", Paper.box(Vector3(25.0, 0.6, 21.0)), EARTH, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, 0.04)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(25.0, 0.6, 21.0)
	collision.shape = shape
	ground.add_child(collision)
	Paper.part(_courtyard, "SheepPath", Paper.box(Vector3(3.1, 0.05, 12.0)), Color(0.60, 0.42, 0.30),
			CENTRE + Vector3(0.5, 0.025, 4.1), Vector3(0.0, -0.08, 0.0), Vector3.ONE, 0.015)


func _build_house() -> void:
	var house := Node3D.new()
	house.name = "JessesHouse"
	house.position = CENTRE + Vector3(-7.3, 0.0, -4.2)
	_courtyard.add_child(house)
	Paper.part(house, "Wall", Paper.box(Vector3(9.0, 4.2, 0.55)), LIMESTONE, Vector3(0.0, 2.1, 0.0))
	Paper.part(house, "SideWall", Paper.box(Vector3(0.55, 4.2, 5.0)), LIMESTONE.darkened(0.05), Vector3(-4.2, 2.1, 2.2))
	Paper.part(house, "Doorway", Paper.box(Vector3(2.1, 3.1, 0.08)), Color(0.28, 0.20, 0.14), Vector3(1.4, 1.55, -0.32))
	Paper.part(house, "Awning", Paper.box(Vector3(5.4, 0.08, 2.2)), Color(0.64, 0.38, 0.27),
			Vector3(0.3, 3.35, 1.0), Vector3(0.08, 0.0, 0.0))


func _build_tree_and_table() -> void:
	var tree := Node3D.new()
	tree.name = "OliveTree"
	tree.position = CENTRE + Vector3(5.9, 0.0, -2.8)
	_courtyard.add_child(tree)
	Paper.part(tree, "Trunk", Paper.cylinder(0.35, 3.8, 7, 0.26), WOOD, Vector3(0.0, 1.9, 0.0))
	for i in 7:
		var angle := TAU * float(i) / 7.0
		Paper.part(tree, "Leaves%d" % i, Paper.sphere(0.9, 7), Color(0.38, 0.49, 0.27).lightened(0.08 * float(i % 2)),
				Vector3(cos(angle) * 1.2, 3.7 + 0.18 * float(i % 3), sin(angle) * 1.05),
				Vector3.ZERO, Vector3(1.35, 0.70, 0.90))
	var table := Node3D.new()
	table.name = "WelcomeTable"
	table.position = CENTRE + Vector3(3.3, 0.0, 0.8)
	_courtyard.add_child(table)
	Paper.part(table, "Top", Paper.box(Vector3(3.4, 0.18, 1.55)), WOOD.lightened(0.10), Vector3(0.0, 1.0, 0.0))
	for x in [-1.35, 1.35]:
		for z in [-0.52, 0.52]:
			Paper.part(table, "Leg", Paper.cylinder(0.08, 1.0, 6), WOOD, Vector3(x, 0.5, z))
	Paper.part(table, "Cushion", Paper.box(Vector3(0.95, 0.24, 0.75)), Color(0.58, 0.30, 0.31), Vector3(-0.95, 1.22, 0.0))
	Paper.part(table, "Cup", Paper.cylinder(0.18, 0.32, 8, 0.15), Color(0.64, 0.45, 0.25), Vector3(0.15, 1.25, 0.0))
	Paper.part(table, "Lamp", Paper.cylinder(0.28, 0.18, 8, 0.20), Color(0.72, 0.49, 0.22), Vector3(1.05, 1.18, 0.0))


func _build_fold() -> void:
	var fold := Node3D.new()
	fold.name = "SheepFold"
	fold.position = CENTRE + Vector3(6.8, 0.0, 5.6)
	_courtyard.add_child(fold)
	for x in [-3.2, 0.0, 3.2]:
		Paper.part(fold, "FencePost", Paper.cylinder(0.09, 1.35, 6), WOOD, Vector3(x, 0.68, 0.0))
	for y in [0.42, 0.92]:
		Paper.part(fold, "FenceRail", Paper.cylinder(0.055, 6.4, 6), WOOD, Vector3(0.0, y, 0.0), Vector3(0.0, 0.0, PI * 0.5))


func _build_people() -> void:
	_make_person("Samuel", CENTRE + Vector3(-1.8, 0.0, 1.0), Color(0.86, 0.78, 0.61), SKINS[1], Color(0.64, 0.64, 0.60), 1.08, true)
	_make_person("Jesse", CENTRE + Vector3(0.3, 0.0, -1.5), Color(0.47, 0.40, 0.25), SKINS[0], Color(0.24, 0.15, 0.09), 1.06)
	_make_person("YoungerDavid", CENTRE + Vector3(5.1, 0.0, 5.2), Color(0.69, 0.47, 0.23), SKINS[0], Color(0.29, 0.17, 0.08), 0.90)
	var start := CENTRE + Vector3(-4.3, 0.0, -0.2)
	for i in 7:
		var pos := start + Vector3(float(i % 4) * 1.35, 0.0, float(i / 4) * 1.65)
		_make_person("Brother%d" % (i + 1), pos, BROTHER_TUNICS[i], SKINS[i % SKINS.size()], Color(0.22, 0.13, 0.07), 0.96 + 0.025 * float(i % 4))


func _make_person(person_name: String, at: Vector3, cloth: Color, skin: Color, hair: Color, height: float, staff := false) -> void:
	var person := Node3D.new()
	person.name = person_name
	person.position = at
	person.scale = Vector3.ONE * height
	_courtyard.add_child(person)
	Paper.part(person, "Tunic", Paper.cylinder(0.28, 0.78, 8, 0.20), cloth, Vector3(0.0, 0.95, 0.0))
	Paper.part(person, "Head", Paper.sphere(0.17, 8), skin, Vector3(0.0, 1.55, 0.0), Vector3.ZERO, Vector3(1.0, 1.08, 1.0))
	Paper.part(person, "Hair", Paper.sphere(0.18, 8), hair, Vector3(0.0, 1.62, 0.04), Vector3.ZERO, Vector3(1.0, 0.65, 1.0), 0.015)
	var arms := Node3D.new()
	arms.name = "Arms"
	arms.position = Vector3(0.0, 1.25, 0.0)
	person.add_child(arms)
	Paper.part(arms, "ArmL", Paper.capsule(0.07, 0.56), cloth, Vector3(-0.31, -0.22, 0.0), Vector3(0.08, 0.0, -0.16))
	Paper.part(arms, "ArmR", Paper.capsule(0.07, 0.56), cloth, Vector3(0.31, -0.22, 0.0), Vector3(-0.08, 0.0, 0.16))
	_idle_parts.append(arms)
	if staff:
		Paper.part(person, "Staff", Paper.cylinder(0.035, 1.85, 6), WOOD, Vector3(0.43, 0.92, -0.08))
		Paper.part(person, "OilHorn", Paper.capsule(0.10, 0.34), Color(0.74, 0.64, 0.43), Vector3(-0.30, 0.92, -0.12), Vector3(0.0, 0.0, 0.45))


func _build_markers() -> void:
	var markers := {
		"SamuelArrival": Vector3(-2.6, 0.0, 3.6), "WelcomePlacement": Vector3(3.3, 0.0, 0.8),
		"BrotherProcession": Vector3(-0.8, 0.0, -0.1), "DavidEntrance": Vector3(4.7, 0.0, 5.4),
		"Anointing": Vector3(1.3, 0.0, 1.0),
	}
	for marker_name in markers:
		var marker := Marker3D.new()
		marker.name = marker_name
		marker.position = CENTRE + markers[marker_name]
		_courtyard.add_child(marker)


func _build_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.name = "ChapterThreeUI"
	_hud.layer = 8
	add_child(_hud)
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER_TOP)
	card.offset_left = -360.0
	card.offset_right = 360.0
	card.offset_top = 18.0
	card.offset_bottom = 112.0
	card.add_theme_stylebox_override("panel", PaperUI.panel_style(20, 18))
	_hud.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	card.add_child(row)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(PaperUI.label("Chapter 3 — The Beginning", 28))
	copy.add_child(PaperUI.label("Greybox: courtyard layout and story staging anchors", 18))
	var journey := PaperUI.button("Faith Journey", Vector2(190.0, 54.0), 21, PaperUI.PAPER_DEEP)
	journey.pressed.connect(_open_journey)
	row.add_child(journey)
	_hud.visible = false


func _open_journey() -> void:
	var journey := get_parent().get_node_or_null("FaithJourney")
	if journey and journey.has_method("open"):
		journey.open()


func _snap_followers(player: Node3D) -> void:
	var main := get_parent()
	var camera := main.get_node_or_null("TabletopCamera") as Camera3D
	if camera and "offset" in camera:
		camera.global_position = player.global_position + camera.offset
		camera.look_at(player.global_position + Vector3(0.0, camera.look_height, 0.0), Vector3.UP)
	var light := main.get_node_or_null("WonderLight") as Node3D
	if light and "hover_offset" in light:
		light.global_position = player.global_position + light.hover_offset


func _set_morning() -> void:
	var main := get_parent()
	var world := main.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world and world.environment:
		var env := world.environment
		if env.sky:
			var sky := env.sky.sky_material as ProceduralSkyMaterial
			if sky:
				sky.sky_top_color = Color(0.37, 0.64, 0.88)
				sky.sky_horizon_color = Color(0.95, 0.78, 0.56)
		env.ambient_light_color = Color(0.94, 0.84, 0.69)
		env.ambient_light_energy = 0.9
		env.fog_density = 0.002
	var sun := main.get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		sun.light_color = Color(1.0, 0.84, 0.65)
		sun.light_energy = 0.95
	var soundscape := main.get_node_or_null("Soundscape")
	if soundscape and soundscape.has_method("set_night"):
		soundscape.set_night(false)
