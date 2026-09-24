extends Node3D
## Noah's Ark, built the first time it is visited so the valley and the camp
## do not pay for it. A curved plank hull with its house finished at one end and bare
## ribs still going up at the other, a work bench, six animal pairs, and three weather
## states, all in the camp's paper-diorama style.

const Paper := preload("res://scripts/camp_paper.gd")
const ChapterFour := preload("res://scripts/chapter_four.gd")
const Profiles := preload("res://scripts/profiles.gd")
const Motion := preload("res://scripts/chapter_two_character_motion.gd")
const Shapes := preload("res://scripts/ark_shapes.gd")

const ORIGIN := Vector3(96.0, 0.0, 8.0)
const START_LOCAL := Vector3(-1.2, 0.2, 7.0)
const CAMERA_OFFSET := Vector3(0.0, 5.4, 10.0)
const CAMERA_LOOK := 2.6
## The hull's centre line runs along x at this z; its side faces the arriving child.
const HULL_Z := -5.8
## The work bench, in front of the unfinished stern.
const PANEL := Vector3(5.3, 0.0, 0.1)
## The house window the dove leaves from.
const WINDOW := Vector3(1.6, 4.35, 0.0)
## Where the ramp meets the plain.
const RAMP_FOOT_Z := 4.6
const RAIN_STREAKS := 160
const RAIN_HEIGHT := 9.0
const EARTH := Color(0.64, 0.48, 0.29)
const PLANK_LIGHT := Color(0.8, 0.6, 0.35)
const PLANK_DARK := Color(0.45, 0.28, 0.15)
const PLANK_A := Color(0.74, 0.5, 0.27)
const PLANK_B := Color(0.65, 0.42, 0.21)
const SKIN := Color(0.86, 0.66, 0.5)
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
var _hand: Node3D


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
			# Low and pulled back, so the hull rises out of the plain behind the child.
			cam.offset = CAMERA_OFFSET
			if "look_height" in cam:
				cam.set("look_height", CAMERA_LOOK)
			cam.fov = 42.0
			cam.global_position = player.global_position + cam.offset
			cam.look_at(player.global_position + Vector3(0.0, CAMERA_LOOK, 0.0), Vector3.UP)
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
	_upper_works()
	_work_station()
	_items()
	_animals()
	_people()
	_family()
	_dove()
	_rain = Node3D.new()
	_rain.name = "Rain"
	add_child(_rain)
	# Silver streaks that keep falling around the ark; the sky turns slate blue with them.
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	var streak := Paper.box(Vector3(0.03, 0.8, 0.03))
	for i in RAIN_STREAKS:
		var drop := MeshInstance3D.new()
		drop.name = "Drop%d" % i
		drop.mesh = streak
		drop.material_override = Paper.glow_mat(Color(0.8, 0.86, 0.94))
		drop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		drop.position = _at(Vector3(rng.randf_range(-14.0, 14.0), rng.randf_range(0.0, RAIN_HEIGHT), rng.randf_range(-12.0, 10.0)))
		drop.rotation.z = 0.12
		_rain.add_child(drop)
	_rain.visible = false
	# Broad matte paper bands behind the ark, not a glassy arc across the sky.
	_rainbow = Node3D.new()
	_rainbow.name = "Rainbow"
	add_child(_rainbow)
	var colours := [Color(0.84, 0.36, 0.3), Color(0.93, 0.66, 0.3), Color(0.94, 0.84, 0.44), Color(0.5, 0.72, 0.44), Color(0.4, 0.58, 0.8)]
	for i in colours.size():
		var band := MeshInstance3D.new()
		band.name = "Band%d" % i
		band.mesh = Shapes.arc_band(15.0 - i * 0.7, 0.72)
		band.material_override = Shapes.sheet_mat(colours[i])
		band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		band.position = _at(Vector3(0.0, -1.5, -17.0 + i * 0.02))
		_rainbow.add_child(band)
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
	# The sand runs on to the horizon, well past where the child can walk.
	Paper.part(self, "Earth", Paper.box(Vector3(160.0, 0.08, 120.0)), EARTH,
			_at(Vector3(0.0, 0.02, -8.0)), Vector3.ZERO, Vector3.ONE, 0.0)


func _set_building_light(main: Node) -> void:
	# Chapter 2 leaves the shared world at blue hour; the ark opens in warm daylight.
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
			env.ambient_light_color = Color(0.9, 0.82, 0.7)
			env.ambient_light_energy = 0.7
			env.fog_light_color = Color(0.82, 0.74, 0.6)
			env.fog_density = 0.0015
	var sun := main.get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		sun.light_color = Color(1.0, 0.88, 0.7)
		sun.light_energy = 1.05
	var fill := main.get_node_or_null("FillLight") as DirectionalLight3D
	if fill:
		fill.light_color = Color(0.76, 0.84, 0.94)
		fill.light_energy = 0.35
	var backdrop := main.get_node_or_null("HorizonBackdrop")
	if backdrop and backdrop.has_method("set_daylight"):
		backdrop.set_daylight()


func _set_rain_light(main: Node) -> void:
	var world := main.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world and world.environment:
		var env := world.environment
		if env.sky:
			var sky := env.sky.sky_material as ProceduralSkyMaterial
			if sky:
				sky.sky_top_color = Color(0.32, 0.4, 0.52)
				sky.sky_horizon_color = Color(0.56, 0.62, 0.7)
		env.ambient_light_color = Color(0.66, 0.72, 0.84)
		env.ambient_light_energy = 0.75
		env.fog_light_color = Color(0.5, 0.56, 0.66)
		env.fog_density = 0.006
	var sun := main.get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		sun.light_color = Color(0.72, 0.8, 0.94)
		sun.light_energy = 0.45


func _plain_dressing() -> void:
	# A worn path gives the child a clear line from the timber stack up to the ramp.
	Paper.part(self, "WornPath", Paper.box(Vector3(3.6, 0.035, 12.0)), EARTH.lightened(0.12),
			_at(Vector3(0.0, 0.075, 7.0)), Vector3.ZERO, Vector3.ONE, 0.0)
	# Sun-baked patches break up the flat earth.
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for i in 14:
		var at := Vector3(rng.randf_range(-17.0, 17.0), 0.07, rng.randf_range(-14.0, 17.0))
		if absf(at.x) < 9.0 and at.z < 1.0:
			continue
		Paper.part(self, "Patch%d" % i, Paper.cylinder(1.0, 0.02, 9), EARTH.darkened(0.08) if i % 2 == 0 else EARTH.lightened(0.07),
				_at(at), Vector3(0.0, rng.randf() * TAU, 0.0), Vector3(rng.randf_range(1.0, 2.6), 1.0, rng.randf_range(0.7, 1.6)), 0.0)
	# Low paper dunes on the horizon leave the ark in view.
	var dunes := [
		Vector4(-16.0, -12.0, 6.5, 2.2), Vector4(-8.0, -16.0, 5.3, 1.6),
		Vector4(10.0, -16.0, 6.0, 1.9), Vector4(17.0, -10.0, 5.4, 1.8),
		Vector4(-27.0, 2.0, 7.0, 2.6), Vector4(-25.0, 16.0, 6.0, 2.0),
		Vector4(27.0, 4.0, 7.0, 2.4), Vector4(26.0, 18.0, 6.0, 2.1),
	]
	for i in dunes.size():
		var d: Vector4 = dunes[i]
		Paper.part(self, "Dune%d" % i, Paper.sphere(1.0, 9), EARTH.darkened(0.06) if i % 2 == 0 else EARTH,
				_at(Vector3(d.x, 0.0, d.y)), Vector3.ZERO, Vector3(d.z, d.w, 2.6), 0.03)
	# Olive scrub and a few rocks show scale without cluttering the animal route.
	for i in 12:
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := side * (9.5 + float((i * 5) % 7))
		var z := 13.0 - float(i) * 2.2
		_scrub("Scrub%d" % i, _at(Vector3(x, 0.0, z)), 0.8 + float(i % 3) * 0.25)
	for i in 6:
		var side := -1.0 if i % 2 == 0 else 1.0
		Paper.part(self, "Rock%d" % i, Paper.sphere(0.45, 6), Color(0.66, 0.6, 0.52),
				_at(Vector3(side * (8.0 + i * 1.3), 0.12, 9.0 - i * 3.4)), Vector3(0.0, i * 0.9, 0.2), Vector3(1.3, 0.6, 1.0), 0.025)
	# The stack of squared timbers, where the plank carriers are fetching from.
	for layer in 3:
		for k in 3 - layer:
			Paper.part(self, "Timber%d_%d" % [layer, k], Paper.box(Vector3(3.2, 0.34, 0.34)),
					PLANK_LIGHT if (layer + k) % 2 == 0 else PLANK_DARK,
					_at(Vector3(10.6, 0.2 + layer * 0.34, 5.6 + (k + layer * 0.5) * 0.36)), Vector3(0.0, 0.08, 0.0), Vector3.ONE, 0.02)
	# Food baskets and sacks, organised by Noah's wife beside the animal path.
	var baskets := [Vector3(-7.4, 0.0, -0.6), Vector3(-6.6, 0.0, -1.3), Vector3(-7.9, 0.0, 0.4), Vector3(-6.3, 0.0, -0.1)]
	for i in baskets.size():
		_basket("Basket%d" % i, _at(baskets[i]), [Color(0.86, 0.66, 0.28), Color(0.52, 0.62, 0.3), Color(0.74, 0.34, 0.24), Color(0.9, 0.82, 0.6)][i])
	Paper.part(self, "Sack", Paper.sphere(0.36, 7), Color(0.84, 0.76, 0.6), _at(Vector3(-8.3, 0.3, -0.9)), Vector3.ZERO, Vector3(1.0, 0.9, 0.9), 0.02)


func _scrub(scrub_name: String, at: Vector3, size: float) -> void:
	var root := Node3D.new()
	root.name = scrub_name
	root.position = at
	add_child(root)
	Paper.part(root, "Stem", Paper.cylinder(0.05, 0.5 * size, 5, 0.03), Color(0.42, 0.34, 0.22), Vector3(0.0, 0.25 * size, 0.0), Vector3.ZERO, Vector3.ONE, 0.015)
	for k in 3:
		var a := TAU * k / 3.0
		Paper.part(root, "Leaf%d" % k, Paper.sphere(0.3 * size, 6), Color(0.5, 0.56, 0.32) if k != 1 else Color(0.44, 0.5, 0.29),
				Vector3(cos(a) * 0.18 * size, 0.55 * size + k * 0.06, sin(a) * 0.18 * size), Vector3.ZERO, Vector3(1.2, 0.8, 1.0), 0.02)


func _basket(basket_name: String, at: Vector3, food: Color) -> void:
	var root := Node3D.new()
	root.name = basket_name
	root.position = at
	add_child(root)
	Paper.part(root, "Weave", Paper.cylinder(0.26, 0.34, 9, 0.34), Color(0.72, 0.55, 0.32), Vector3(0.0, 0.17, 0.0), Vector3.ZERO, Vector3.ONE, 0.02)
	Paper.part(root, "Rim", Paper.cylinder(0.35, 0.05, 9), Color(0.58, 0.42, 0.24), Vector3(0.0, 0.35, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
	Paper.part(root, "Food", Paper.sphere(0.27, 7), food, Vector3(0.0, 0.36, 0.0), Vector3.ZERO, Vector3(1.0, 0.45, 1.0), 0.0)


## The hull: a real curved boat shape in warm planks, a door the ramp climbs to, and a
## body the child cannot walk through.
func _hull() -> void:
	var hull := MeshInstance3D.new()
	hull.name = "Hull"
	hull.mesh = Shapes.hull()
	hull.material_override = Shapes.vertex_mat()
	hull.position = _at(Vector3(0.0, 0.0, HULL_Z))
	add_child(hull)
	Paper.outline(hull, 0.05)
	var body := StaticBody3D.new()
	body.name = "HullBody"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(Shapes.HALF_LENGTH * 1.8, 4.0, Shapes.HALF_BEAM * 1.9)
	shape.shape = box
	body.add_child(shape)
	body.position = _at(Vector3(0.0, 2.0, HULL_Z))
	add_child(body)
	# Rub-rails: two dark strakes that give the hull its long line.
	for y in [1.6, 2.6]:
		for x in range(-6, 7):
			var z := Shapes.side_z(float(x), y)
			Paper.part(self, "Strake", Paper.box(Vector3(1.02, 0.12, 0.08)), PLANK_DARK.darkened(0.25),
					_at(Vector3(float(x), y, HULL_Z + z + 0.02)), Vector3.ZERO, Vector3.ONE, 0.0)
	# The door, low in the side, and a wide shallow ramp up to it.
	var door_y := 1.95
	var door_z := HULL_Z + Shapes.side_z(0.0, door_y)
	Paper.part(self, "Entrance", Paper.box(Vector3(2.0, 1.6, 0.14)), Color(0.24, 0.15, 0.09),
			_at(Vector3(0.0, door_y, door_z + 0.05)), Vector3.ZERO, Vector3.ONE, 0.03)
	var ramp_top := Vector3(0.0, 1.15, door_z + 0.2)
	var ramp_foot := Vector3(0.0, 0.05, RAMP_FOOT_Z)
	var run := ramp_foot - ramp_top
	var tilt := atan2(run.y, run.z)
	var ramp := Paper.part(self, "Ramp", Paper.box(Vector3(3.2, 0.16, run.length())), PLANK_B,
			_at((ramp_top + ramp_foot) * 0.5), Vector3(-tilt, 0.0, 0.0), Vector3.ONE, 0.025)
	for i in 6:
		Paper.part(ramp, "RampCleat%d" % i, Paper.box(Vector3(2.9, 0.08, 0.1)), PLANK_DARK,
				Vector3(0.0, 0.11, -run.length() * 0.4 + i * run.length() * 0.16), Vector3.ZERO, Vector3.ONE, 0.0)
	var ramp_body := StaticBody3D.new()
	ramp_body.name = "RampBody"
	var ramp_shape := CollisionShape3D.new()
	var ramp_box := BoxShape3D.new()
	ramp_box.size = Vector3(3.2, 0.16, run.length())
	ramp_shape.shape = ramp_box
	ramp_body.add_child(ramp_shape)
	ramp_body.position = _at((ramp_top + ramp_foot) * 0.5)
	ramp_body.rotation = Vector3(-tilt, 0.0, 0.0)
	add_child(ramp_body)


## On the deck: the finished house with its roof and window at the bow end, and the bare
## curved ribs of the part still being built at the stern end.
func _upper_works() -> void:
	var deck := Shapes.DECK
	Paper.part(self, "House", Paper.box(Vector3(8.6, 2.1, 4.2)), Color(0.86, 0.66, 0.4),
			_at(Vector3(-1.7, deck + 0.95, HULL_Z)), Vector3.ZERO, Vector3.ONE, 0.035)
	for i in 9:
		Paper.part(self, "HouseSeam%d" % i, Paper.box(Vector3(0.05, 2.0, 0.03)), PLANK_DARK,
				_at(Vector3(-5.6 + i * 0.97, deck + 0.95, HULL_Z + 2.12)), Vector3.ZERO, Vector3.ONE, 0.0)
	Paper.part(self, "Roof", Paper.ridge_tent(5.2, 9.4, 1.5), Color(0.62, 0.36, 0.2),
			_at(Vector3(-1.7, deck + 2.0, HULL_Z)), Vector3(0.0, PI / 2.0, 0.0), Vector3.ONE, 0.04)
	for x in [-5.0, -3.0, -0.6]:
		Paper.part(self, "Porthole", Paper.box(Vector3(0.6, 0.5, 0.06)), Color(0.3, 0.2, 0.12),
				_at(Vector3(x, deck + 1.25, HULL_Z + 2.13)), Vector3.ZERO, Vector3.ONE, 0.02)
	# The window the dove leaves from: the one bright rectangle on the house.
	Paper.part(self, "Window", Paper.box(Vector3(1.0, 0.8, 0.06)), Color(0.98, 0.9, 0.66),
			_at(Vector3(WINDOW.x, WINDOW.y, HULL_Z + 2.13)), Vector3.ZERO, Vector3.ONE, 0.03)
	Paper.part(self, "WindowSill", Paper.box(Vector3(1.3, 0.1, 0.3)), PLANK_DARK,
			_at(Vector3(WINDOW.x, WINDOW.y - 0.45, HULL_Z + 2.22)), Vector3.ZERO, Vector3.ONE, 0.015)
	# Unfinished: four ribs arching over the stern deck, tied by a ridge beam and a stringer.
	var rib_xs := [3.4, 4.6, 5.8, 7.0]
	for r in rib_xs.size():
		var x: float = rib_xs[r]
		var half := Shapes.half_beam(x) - 0.25
		var base_y := Shapes.deck_y(x)
		var rise := 2.4
		var steps := 9
		for k in steps:
			var a0 := PI * k / steps
			var a1 := PI * (k + 1) / steps
			var p0 := Vector2(cos(a0) * half, sin(a0) * rise)
			var p1 := Vector2(cos(a1) * half, sin(a1) * rise)
			var mid := (p0 + p1) * 0.5
			var seg := p1 - p0
			Paper.part(self, "Rib%d_%d" % [r, k], Paper.box(Vector3(0.22, 0.2, seg.length() + 0.08)),
					PLANK_A if r % 2 == 0 else PLANK_B,
					_at(Vector3(x, base_y + mid.y, HULL_Z + mid.x)), Vector3(atan2(-seg.y, seg.x), 0.0, 0.0), Vector3.ONE, 0.02)
	Paper.part(self, "RidgeBeam", Paper.box(Vector3(4.2, 0.2, 0.2)), PLANK_B,
			_at(Vector3(5.2, Shapes.deck_y(5.2) + 2.45, HULL_Z)), Vector3.ZERO, Vector3.ONE, 0.02)
	for side in [-1.0, 1.0]:
		Paper.part(self, "Stringer", Paper.box(Vector3(4.2, 0.16, 0.16)), PLANK_A,
				_at(Vector3(5.2, Shapes.deck_y(5.2) + 1.2, HULL_Z + side * (Shapes.half_beam(5.2) - 0.55))), Vector3.ZERO, Vector3.ONE, 0.02)
	# A ladder leaning on the hull where the work is.
	var ladder := Node3D.new()
	ladder.name = "Ladder"
	ladder.position = _at(Vector3(7.3, 0.0, HULL_Z + Shapes.side_z(7.3, 1.2) + 0.9))
	ladder.rotation = Vector3(-0.32, 0.0, 0.0)
	add_child(ladder)
	for side in [-0.35, 0.35]:
		Paper.part(ladder, "Rail", Paper.box(Vector3(0.1, 3.6, 0.1)), PLANK_DARK, Vector3(side, 1.8, 0.0), Vector3.ZERO, Vector3.ONE, 0.015)
	for i in 6:
		Paper.part(ladder, "Rung%d" % i, Paper.box(Vector3(0.7, 0.07, 0.07)), PLANK_LIGHT, Vector3(0.0, 0.4 + i * 0.55, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)


## The work bench in front of the stern: the panel the child pegs and ties, on two trestles.
func _work_station() -> void:
	for side in [-1.0, 1.0]:
		var trestle := Node3D.new()
		trestle.name = "Trestle"
		trestle.position = _at(PANEL + Vector3(side * 1.0, 0.0, 0.0))
		add_child(trestle)
		Paper.part(trestle, "Bar", Paper.box(Vector3(0.14, 0.14, 1.2)), PLANK_DARK, Vector3(0.0, 0.8, 0.0), Vector3.ZERO, Vector3.ONE, 0.015)
		for leg in [-1.0, 1.0]:
			Paper.part(trestle, "Leg", Paper.box(Vector3(0.1, 0.9, 0.1)), PLANK_DARK, Vector3(0.0, 0.4, leg * 0.42), Vector3(leg * 0.35, 0.0, 0.0), Vector3.ONE, 0.012)
	_panel = Paper.part(self, "WorkPanel", Paper.box(Vector3(2.4, 1.6, 0.18)), Color(0.72, 0.52, 0.3),
			_at(PANEL + Vector3(0.0, 1.1, 0.0)), Vector3(-1.05, 0.0, 0.0), Vector3.ONE, 0.025)
	# The panel's own material, so pegging it darkens only this panel.
	_panel.material_override = (_panel.material_override as StandardMaterial3D).duplicate()
	for i in 3:
		Paper.part(_panel, "Plank%d" % i, Paper.box(Vector3(2.36, 0.03, 0.02)), PLANK_DARK,
				Vector3(0.0, -0.53 + i * 0.53, 0.1), Vector3.ZERO, Vector3.ONE, 0.0)
		Paper.part(_panel, "Socket%d" % i, Paper.cylinder(0.08, 0.08, 8), Color(0.35, 0.22, 0.12),
				Vector3(-0.7 + i * 0.7, 0.15, 0.12), Vector3(PI / 2.0, 0.0, 0.0), Vector3.ONE, 0.0)
	_rope = Paper.part(_panel, "PanelRope", Paper.cylinder(0.05, 2.2, 6), Color(0.62, 0.46, 0.24),
			Vector3(0.0, 0.62, 0.14), Vector3(0.0, 0.0, PI / 2.0), Vector3.ONE, 0.012)


func _items() -> void:
	_tool("Mallet", _at(Vector3(-4.0, 0.0, 6.0)))
	_tool("RopeCoil", _at(Vector3(4.2, 0.0, 5.4)))
	_tool("Pitch", _at(Vector3(-2.7, 0.0, 3.4)))


## Wood, rope and sealed pitch, each with its own clear shape; nothing sharp.
func _tool(tool_name: String, at: Vector3) -> void:
	var root := Node3D.new()
	root.name = tool_name
	root.position = at
	add_child(root)
	# A soft paler ground circle marks each tool from across the plain.
	Paper.part(root, "Spot", Paper.cylinder(0.62, 0.02, 12), EARTH.lightened(0.2), Vector3(0.0, 0.06, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
	match tool_name:
		"Mallet":
			Paper.part(root, "Handle", Paper.cylinder(0.05, 0.9, 6), Color(0.72, 0.52, 0.3), Vector3(0.1, 0.12, 0.0), Vector3(0.0, 0.3, PI / 2.0), Vector3.ONE, 0.015)
			Paper.part(root, "Body", Paper.cylinder(0.17, 0.46, 8), Color(0.55, 0.34, 0.17), Vector3(-0.36, 0.18, -0.12), Vector3(PI / 2.0, 0.3, 0.0), Vector3.ONE, 0.02)
		"RopeCoil":
			for k in 3:
				var ring := TorusMesh.new()
				ring.inner_radius = 0.16 - k * 0.02
				ring.outer_radius = 0.3 - k * 0.03
				ring.rings = 12
				ring.ring_segments = 6
				Paper.part(root, "Body" if k == 0 else "Coil%d" % k, ring, Color(0.76, 0.6, 0.34) if k % 2 == 0 else Color(0.66, 0.5, 0.28),
						Vector3(0.0, 0.08 + k * 0.08, 0.0), Vector3.ZERO, Vector3.ONE, 0.012)
		"Pitch":
			Paper.part(root, "Body", Paper.cylinder(0.2, 0.42, 9, 0.13), Color(0.56, 0.34, 0.2), Vector3(0.0, 0.25, 0.0), Vector3.ZERO, Vector3.ONE, 0.02)
			Paper.part(root, "Lip", Paper.cylinder(0.15, 0.06, 9), Color(0.46, 0.28, 0.16), Vector3(0.0, 0.48, 0.0), Vector3.ZERO, Vector3.ONE, 0.012)
			Paper.part(root, "Tar", Paper.cylinder(0.12, 0.02, 9), Color(0.12, 0.09, 0.07), Vector3(0.0, 0.51, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
			Paper.part(root, "Stick", Paper.cylinder(0.025, 0.5, 5), Color(0.72, 0.52, 0.3), Vector3(0.05, 0.62, 0.0), Vector3(0.0, 0.0, -0.3), Vector3.ONE, 0.0)


func _animals() -> void:
	_critter("SheepA", "sheep", Vector3(-5.5, 0.0, 5.0))
	_critter("SheepB", "sheep", Vector3(2.6, 0.0, 6.4))
	_critter("DoveA", "dove", Vector3(-2.3, 0.0, 5.4))
	_critter("DoveB", "dove", Vector3(3.0, 0.0, 3.1))
	_critter("ElephantA", "elephant", Vector3(6.0, 0.0, 4.0))
	_critter("ElephantB", "elephant", Vector3(7.8, 0.0, 6.8))
	_critter("GoatA", "goat", Vector3(-8.0, 0.0, 3.0))
	_critter("GoatB", "goat", Vector3(-5.5, 0.0, 1.0))
	_critter("RabbitA", "rabbit", Vector3(8.0, 0.0, 5.0))
	_critter("RabbitB", "rabbit", Vector3(6.0, 0.0, 2.8))
	_critter("GiraffeA", "giraffe", Vector3(-4.0, 0.0, 2.0))
	_critter("GiraffeB", "giraffe", Vector3(-2.2, 0.0, 0.2))


## Paper-diorama animals: each pair shares a silhouette and colour, and the second of
## the two has one small difference (an ear, a patch, a horn angle).
func _critter(critter_name: String, kind: String, at: Vector3) -> void:
	var root := Node3D.new()
	root.name = critter_name
	root.position = _at(at)
	root.rotation.y = 0.35 if critter_name.ends_with("A") else -0.35
	root.set_meta("kind", kind)
	root.set_meta("home", root.position)
	root.set_meta("aboard", false)
	add_child(root)
	var b := critter_name.ends_with("B")
	var tilt := 0.25 if b else -0.1
	match kind:
		"sheep":
			var wool := Color(0.96, 0.94, 0.88)
			_legs(root, 0.16, 0.12, 0.34, Color(0.22, 0.18, 0.16))
			Paper.part(root, "Body", Paper.sphere(0.36, 9), wool, Vector3(0.0, 0.46, 0.0), Vector3.ZERO, Vector3(1.0, 0.85, 1.25), 0.025)
			Paper.part(root, "Head", Paper.sphere(0.15, 8), Color(0.25, 0.2, 0.18), Vector3(0.0, 0.58, 0.44), Vector3.ZERO, Vector3(1.0, 1.1, 1.2), 0.015)
			for side in [-1.0, 1.0]:
				Paper.part(root, "Ear", Paper.box(Vector3(0.14, 0.05, 0.07)), Color(0.25, 0.2, 0.18), Vector3(side * 0.17, 0.64, 0.4), Vector3(0.0, 0.0, side * (0.5 if b and side > 0.0 else 0.2)), Vector3.ONE, 0.0)
		"goat":
			var coat := Color(0.66, 0.5, 0.34)
			_legs(root, 0.13, 0.12, 0.4, Color(0.4, 0.3, 0.2))
			Paper.part(root, "Body", Paper.sphere(0.3, 8), coat, Vector3(0.0, 0.52, 0.0), Vector3.ZERO, Vector3(0.9, 0.8, 1.3), 0.02)
			Paper.part(root, "Head", Paper.sphere(0.14, 8), coat.lightened(0.1), Vector3(0.0, 0.76, 0.38), Vector3.ZERO, Vector3(0.9, 1.0, 1.3), 0.015)
			Paper.part(root, "Beard", Paper.cylinder(0.04, 0.12, 5, 0.01), Color(0.9, 0.86, 0.78), Vector3(0.0, 0.62, 0.5), Vector3.ZERO, Vector3.ONE, 0.0)
			for side in [-1.0, 1.0]:
				Paper.part(root, "Horn", Paper.cylinder(0.03, 0.26, 5, 0.01), Color(0.35, 0.27, 0.2), Vector3(side * 0.07, 0.95, 0.34), Vector3(-0.5 - tilt, 0.0, side * 0.2), Vector3.ONE, 0.0)
			if b:
				Paper.part(root, "Patch", Paper.sphere(0.14, 6), Color(0.94, 0.9, 0.82), Vector3(0.18, 0.58, -0.05), Vector3.ZERO, Vector3(0.6, 1.0, 1.2), 0.0)
		"rabbit":
			var fur := Color(0.84, 0.78, 0.7)
			Paper.part(root, "Body", Paper.sphere(0.2, 8), fur, Vector3(0.0, 0.2, 0.0), Vector3.ZERO, Vector3(1.0, 0.95, 1.2), 0.015)
			Paper.part(root, "Head", Paper.sphere(0.13, 8), fur, Vector3(0.0, 0.36, 0.17), Vector3.ZERO, Vector3.ONE, 0.012)
			Paper.part(root, "Tail", Paper.sphere(0.07, 6), Color(0.98, 0.96, 0.92), Vector3(0.0, 0.24, -0.24), Vector3.ZERO, Vector3.ONE, 0.0)
			for side in [-1.0, 1.0]:
				var droop := 0.9 if b and side > 0.0 else 0.1
				Paper.part(root, "Ear", Paper.box(Vector3(0.07, 0.3, 0.035)), fur.darkened(0.08), Vector3(side * 0.06, 0.58, 0.14), Vector3(0.0, 0.0, side * droop), Vector3.ONE, 0.01)
		"dove":
			var feather := Color(0.97, 0.97, 0.94)
			Paper.part(root, "Body", Paper.sphere(0.15, 8), feather, Vector3(0.0, 0.26, 0.0), Vector3.ZERO, Vector3(0.9, 0.85, 1.4), 0.012)
			Paper.part(root, "Head", Paper.sphere(0.09, 8), feather, Vector3(0.0, 0.38, 0.16), Vector3.ZERO, Vector3.ONE, 0.01)
			Paper.part(root, "Beak", Paper.cylinder(0.025, 0.08, 5, 0.0), Color(0.9, 0.6, 0.3), Vector3(0.0, 0.37, 0.27), Vector3(PI / 2.0, 0.0, 0.0), Vector3.ONE, 0.0)
			Paper.part(root, "Tail", Paper.box(Vector3(0.14, 0.03, 0.16)), Color(0.82, 0.84, 0.86), Vector3(0.0, 0.27, -0.24), Vector3(0.2, 0.0, 0.0), Vector3.ONE, 0.0)
			for side in [-1.0, 1.0]:
				Paper.part(root, "Wing", Paper.box(Vector3(0.05, 0.12, 0.26)), Color(0.8, 0.82, 0.86) if not b else Color(0.88, 0.88, 0.9), Vector3(side * 0.13, 0.28, -0.02), Vector3(0.0, 0.0, side * 0.3), Vector3.ONE, 0.0)
		"elephant":
			var hide := Color(0.52, 0.54, 0.58)
			_legs(root, 0.3, 0.3, 0.55, hide.darkened(0.1), 0.13)
			Paper.part(root, "Body", Paper.sphere(0.55, 9), hide, Vector3(0.0, 0.85, 0.0), Vector3.ZERO, Vector3(1.0, 0.85, 1.25), 0.03)
			Paper.part(root, "Head", Paper.sphere(0.36, 8), hide, Vector3(0.0, 1.05, 0.62), Vector3.ZERO, Vector3.ONE, 0.025)
			Paper.part(root, "Trunk", Paper.cylinder(0.1, 0.62, 7, 0.06), hide.darkened(0.04), Vector3(0.0, 0.72, 0.9), Vector3(0.35, 0.0, 0.0), Vector3.ONE, 0.018)
			for side in [-1.0, 1.0]:
				Paper.part(root, "Ear", Paper.sphere(0.3, 7), Color(0.7, 0.62, 0.64), Vector3(side * 0.36, 1.1, 0.5), Vector3(0.0, side * (0.5 + tilt), 0.0), Vector3(0.25, 1.0, 0.9), 0.02)
		"giraffe":
			var coat := Color(0.92, 0.74, 0.38)
			_legs(root, 0.16, 0.18, 0.9, coat.darkened(0.08), 0.06)
			Paper.part(root, "Body", Paper.sphere(0.3, 8), coat, Vector3(0.0, 1.0, 0.0), Vector3.ZERO, Vector3(0.95, 0.8, 1.3), 0.02)
			Paper.part(root, "Neck", Paper.cylinder(0.09, 1.1, 6, 0.07), coat, Vector3(0.0, 1.6, 0.3), Vector3(0.3, 0.0, 0.0), Vector3.ONE, 0.018)
			Paper.part(root, "Head", Paper.sphere(0.13, 7), coat, Vector3(0.0, 2.15, 0.52), Vector3.ZERO, Vector3(0.9, 0.9, 1.5), 0.015)
			for side in [-1.0, 1.0]:
				Paper.part(root, "Ossicone", Paper.cylinder(0.025, 0.14, 5), Color(0.45, 0.3, 0.18), Vector3(side * 0.05, 2.28, 0.46), Vector3(0.0, 0.0, side * 0.15), Vector3.ONE, 0.0)
			var spots := [Vector3(0.2, 1.05, 0.1), Vector3(-0.2, 1.0, -0.15), Vector3(0.15, 0.95, -0.25)] if not b else [Vector3(-0.2, 1.05, 0.12), Vector3(0.21, 0.98, -0.1), Vector3(-0.12, 1.12, -0.28)]
			for k in spots.size():
				Paper.part(root, "Spot%d" % k, Paper.sphere(0.09, 6), Color(0.62, 0.4, 0.2), spots[k], Vector3.ZERO, Vector3(0.6, 1.0, 1.0), 0.0)


func _legs(root: Node3D, half_x: float, half_z: float, height: float, color: Color, radius: float = 0.045) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Paper.part(root, "Leg", Paper.cylinder(radius, height, 6), color, Vector3(sx * half_x, height * 0.5, sz * half_z), Vector3.ZERO, Vector3.ONE, 0.01)


func _people() -> void:
	# Noah works at the bench beside the unfinished ribs; his wife keeps the food and the path.
	_noah = _person("Noah", _at(Vector3(3.5, 0.0, -0.3)), Color(0.6, 0.3, 0.17), Color(0.56, 0.5, 0.44), true, Color(0.93, 0.87, 0.74))
	_noah.rotation.y = 0.5
	_wife = _person("NoahsWife", _at(Vector3(-6.9, 0.0, 1.0)), Color(0.18, 0.46, 0.46), Color(0.25, 0.16, 0.1), false, Color(0.86, 0.74, 0.54), "bun")
	_wife.rotation.y = 0.3
	_hand = _noah.get_node("Hand") as Node3D


func _person(person_name: String, at: Vector3, cloth: Color, hair: Color, beard: bool, under: Color = Color(0.9, 0.84, 0.7), style: String = "") -> Node3D:
	var root := Node3D.new()
	root.name = person_name
	root.position = at
	add_child(root)
	Paper.part(root, "Hem", Paper.cylinder(0.36, 0.16, 9, 0.34), under, Vector3(0.0, 0.08, 0.0), Vector3.ZERO, Vector3.ONE, 0.02)
	Paper.part(root, "Body", Paper.cylinder(0.33, 1.15, 9, 0.2), cloth, Vector3(0.0, 0.7, 0.0), Vector3.ZERO, Vector3.ONE, 0.025)
	Paper.part(root, "Belt", Paper.cylinder(0.265, 0.09, 9), Color(0.22, 0.14, 0.09), Vector3(0.0, 0.84, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
	Paper.part(root, "Head", Paper.sphere(0.2, 10), SKIN, Vector3(0.0, 1.46, 0.0), Vector3.ZERO, Vector3.ONE, 0.018)
	for side in [-1.0, 1.0]:
		Paper.part(root, "Eye", Paper.sphere(0.028, 6), Color(0.12, 0.08, 0.06), Vector3(side * 0.07, 1.49, 0.18), Vector3.ZERO, Vector3.ONE, 0.0)
	Paper.part(root, "Hair", Paper.sphere(0.21, 8), hair, Vector3(0.0, 1.55, -0.04), Vector3.ZERO, Vector3(1.02, 0.62, 1.0), 0.0)
	if beard:
		Paper.part(root, "Beard", Paper.sphere(0.15, 8), hair, Vector3(0.0, 1.32, 0.1), Vector3.ZERO, Vector3(1.0, 1.0, 0.7), 0.012)
	match style:
		"bun":
			Paper.part(root, "Bun", Paper.sphere(0.11, 7), hair, Vector3(0.0, 1.52, -0.22), Vector3.ZERO, Vector3.ONE, 0.01)
		"wrap":
			Paper.part(root, "Wrap", Paper.sphere(0.22, 8), under, Vector3(0.0, 1.56, -0.03), Vector3.ZERO, Vector3(1.05, 0.66, 1.05), 0.012)
	Paper.part(root, "ArmL", Paper.capsule(0.08, 0.62), cloth.darkened(0.08), Vector3(-0.32, 0.98, 0.04), Vector3(0.0, 0.0, -0.18), Vector3.ONE, 0.015)
	var hand := Node3D.new()
	hand.name = "Hand"
	hand.position = Vector3(0.34, 0.95, 0.12)
	root.add_child(hand)
	Paper.part(hand, "Sleeve", Paper.capsule(0.08, 0.5), cloth.darkened(0.08), Vector3(0.0, 0.1, -0.04), Vector3(0.0, 0.0, 0.15), Vector3.ONE, 0.015)
	Paper.part(hand, "Palm", Paper.sphere(0.08, 8), SKIN, Vector3(0.02, -0.18, 0.0), Vector3.ZERO, Vector3.ONE, 0.01)
	return root


## Noah's sons and their wives, working in pairs: two carry a plank, two sort the
## food, two steady the ramp.
func _family() -> void:
	var colours := [Color(0.55, 0.4, 0.28), Color(0.46, 0.55, 0.4), Color(0.72, 0.52, 0.34), Color(0.5, 0.4, 0.56), Color(0.66, 0.46, 0.3), Color(0.36, 0.5, 0.6)]
	var spots := [Vector3(8.4, 0.0, 1.2), Vector3(10.2, 0.0, 1.2), Vector3(-9.2, 0.0, -0.8), Vector3(-8.8, 0.0, 1.3), Vector3(2.4, 0.0, 3.6), Vector3(2.2, 0.0, 1.4)]
	var hair := [Color(0.3, 0.2, 0.12), Color(0.22, 0.14, 0.08), Color(0.4, 0.26, 0.14)]
	for i in colours.size():
		var style := "wrap" if i % 2 == 1 else ""
		var person := _person("Family%d" % i, _at(spots[i]), colours[i], hair[i % 3], i == 4, Color(0.9, 0.84, 0.7), style)
		person.rotation.y = [0.0, 0.0, 0.6, -0.4, -0.3, 0.3][i]
		person.set_meta("home", person.position)
	# The plank rides between the first two on their shoulders, so it travels with them.
	var carrier := get_node("Family0") as Node3D
	Paper.part(carrier, "CarriedPlank", Paper.box(Vector3(2.6, 0.12, 0.34)), PLANK_LIGHT, Vector3(0.9, 1.1, 0.0), Vector3.ZERO, Vector3.ONE, 0.02)
	_basket("HeldBasket", Vector3.ZERO, Color(0.86, 0.66, 0.28))
	var held := get_node("HeldBasket") as Node3D
	held.reparent(get_node("Family3"), false)
	held.position = Vector3(0.0, 0.62, 0.36)
	held.scale = Vector3(0.8, 0.8, 0.8)


func _dove() -> void:
	var dove := Node3D.new()
	dove.name = "WindowDove"
	dove.position = _at(Vector3(WINDOW.x, WINDOW.y - 0.28, HULL_Z + 2.28))
	add_child(dove)
	Paper.part(dove, "Body", Paper.sphere(0.14, 8), Color(0.97, 0.97, 0.94), Vector3.ZERO, Vector3.ZERO, Vector3(1.4, 0.8, 1.0), 0.012)
	Paper.part(dove, "Head", Paper.sphere(0.08, 8), Color(0.97, 0.97, 0.94), Vector3(0.16, 0.08, 0.0), Vector3.ZERO, Vector3.ONE, 0.01)
	var leaf := Paper.part(dove, "Leaf", Paper.box(Vector3(0.16, 0.05, 0.08)), Color(0.4, 0.62, 0.32), Vector3(0.26, 0.04, 0.04), Vector3.ZERO, Vector3.ONE, 0.0)
	leaf.visible = false


func set_weather(state: String) -> void:
	if _rain:
		_rain.visible = state == "rain"
	if state == "rain":
		_set_rain_light(get_parent())
	elif _built:
		_set_building_light(get_parent())
	if _rainbow:
		_rainbow.visible = state == "morning"
	if state == "morning":
		var tw := create_tween()
		for band in _bands:
			band.scale = Vector3(0.05, 1.0, 1.0)
			tw.tween_property(band, "scale", Vector3.ONE, 0.35)


func set_speaking(who: String) -> void:
	if _noah:
		_noah.set_meta("speaking", who == "Noah")
	if _wife:
		_wife.set_meta("speaking", who == "Noah's wife")


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


## When the door closes the child watches from the plain: anyone on the ramp, at the
## bench or against the hull steps back to where they arrived, with the whole ark in view.
func keep_guest_outside(player: Node3D) -> void:
	if player == null:
		return
	var local := player.global_position - ORIGIN
	if local.z < RAMP_FOOT_Z:
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
	if _rain and _rain.visible:
		for drop in _rain.get_children():
			var d := drop as Node3D
			d.position.y -= 9.0 * delta
			if d.position.y < 0.0:
				d.position.y += RAIN_HEIGHT
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
