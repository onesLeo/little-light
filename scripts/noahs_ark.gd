extends Node3D
## Noah's Ark, built the first time it is visited so the valley and the camp
## do not pay for it. The ark stands on a mountaintop above a sea of clouds
## (ark_mountain.gd): a curved plank hull with its house finished at one end and bare
## ribs still going up at the other, a work bench, six animal pairs that wander and
## graze, a family at work, and three weather states, all in the camp's paper style.

const Paper := preload("res://scripts/camp_paper.gd")
const ChapterFour := preload("res://scripts/chapter_four.gd")
const PlayArea := preload("res://scripts/play_area.gd")
const Profiles := preload("res://scripts/profiles.gd")
const Mountain := preload("res://scripts/ark_mountain.gd")
const Shapes := preload("res://scripts/ark_shapes.gd")
const Shelter := preload("res://scripts/ark_shelter.gd")
const ArkPerson := preload("res://scripts/ark_person.gd")

## The mountaintop is lifted well above the valley and the camp, whose ground lies
## hidden under the cloud sea.
const ORIGIN := Vector3(96.0, 40.0, 8.0)
const START_LOCAL := Vector3(-1.2, 0.2, 7.0)
## The hull's centre line runs along x at this z; its side faces the arriving child.
const HULL_Z := -5.8
## The work bench, in front of the unfinished stern.
const PANEL := Vector3(5.3, 0.0, 0.1)
## The house window the dove leaves from.
const WINDOW := Vector3(1.6, 4.35, 0.0)
## The plank carriers' circle beside the timber stack: centre, radius, and the angle
## between the two of them (a 1.8 m plank on a 1.8 m circle).
const CARRY_CENTER := Vector3(11.6, 0.0, 2.2)
const CARRY_RADIUS := 1.8
const CARRY_GAP := PI / 3.0
## The basket carrier's walk between the food and the animal path.
const BASKET_WALK_FROM := Vector3(-8.8, 0.0, 2.1)
const BASKET_WALK_TO := Vector3(-6.0, 0.0, 2.6)
## Where the ramp meets the plain.
const RAMP_FOOT_Z := 4.6
## The doorway in the hull side: low on the curve and up to just under the deck, and
## wide enough for the elephants to walk in two by two.
const DOOR_BOTTOM := 0.4
const DOOR_TOP := 2.95
const DOOR_HALF_WIDTH := 1.5
## Flood heights (local): just under the rim while it rains, and halfway down as it recedes.
const FLOOD_HIGH := -1.1
const FLOOD_MID := -5.0
const GLOW := Color(1.0, 0.86, 0.5)
const RAIN_STREAKS := 160
const RAIN_HEIGHT := 9.0
const EARTH := Color(0.64, 0.58, 0.45)
const PLANK_LIGHT := Color(0.72, 0.59, 0.43)
const PLANK_DARK := Color(0.42, 0.31, 0.22)
const PLANK_A := Color(0.66, 0.5, 0.35)
const PLANK_B := Color(0.58, 0.43, 0.3)
const SKIN := Color(0.86, 0.66, 0.5)
## Drawn at about a grown-up's height, the elephants are scaled up to stand over them.
const ELEPHANT_SCALE := 1.7
const GUIDED := ["SheepA", "DoveA", "ElephantA"]
## Places on the plain a tool can lie: clear of the ramp, the bench, the timber, the
## baskets and the people, and in view from the arrival spot. Each visit takes three.
const TOOL_SPOTS := [
	Vector3(-4.0, 0.0, 6.0), Vector3(3.8, 0.0, 5.8), Vector3(-2.7, 0.0, 3.4), Vector3(-6.2, 0.0, 7.6),
	Vector3(3.4, 0.0, 8.0), Vector3(-4.6, 0.0, -1.8), Vector3(-3.0, 0.0, 8.4), Vector3(5.6, 0.0, 9.0),
]
## The chosen spots stay at least this far apart, and each is nudged up to TOOL_JITTER.
const TOOL_APART := 3.5
const TOOL_JITTER := 0.35
## How far an animal's spot and facing can wander from its drawn place, per visit.
const ANIMAL_JITTER := 0.5
const ANIMAL_TURN := 0.5
const MATE_OF := {
	"SheepA": "SheepB", "DoveA": "DoveB", "ElephantA": "ElephantB",
	"GoatA": "GoatB", "RabbitA": "RabbitB", "GiraffeA": "GiraffeB",
}

## How the mountaintop looks when the story starts (chapter_look.gd); the shell applies it.
@export var look: Resource = preload("res://assets/looks/ark_mountain_day.tres")
## Where the walker can go: the mountaintop plain around the ark (world x, z; see ORIGIN).
@export var play_area: Resource = PlayArea.new(Vector2(96.0, 8.0), Vector2(18.0, 16.0))
var _built: bool = false
## A new layout each visit: where the tools lie, and the animals' spots and facing.
var _layout := RandomNumberGenerator.new()
var _time: float = 0.0
var _mountain: Node3D
var _glows: Array[MeshInstance3D] = []
var _beacons: Array[Node3D] = []
var _beacons_on: bool = false
var _sockets: Array[MeshInstance3D] = []
var _door: Node3D
var _rain: Node3D
var _rainbow: Node3D
var _bands: Array[MeshInstance3D] = []
var _rope: MeshInstance3D
var _panel: MeshInstance3D
var _noah: Node3D
var _wife: Node3D
## True once the family has gone into the ark and stops working outside.
var _family_in: bool = false
signal boarding_finished
var _boarding_pending: int = 0
var _ramp_available: float = 0.0
var _shelter: Node3D
var _light_transition: Tween
var _rainbow_transition: Tween
var _story_camera: Camera3D
var weather_state := "building"
var _exited := false


func is_boarding() -> bool:
	return _boarding_pending > 0


func _unavailable(animal: Node3D) -> bool:
	return bool(animal.get_meta("aboard", false)) or bool(animal.get_meta("boarding", false))


## Starts the ark, or carries on with it. Only the shell calls this (game_shell.gd
## switch_to), after every other story has stood down.
func visit() -> void:
	# A finished run leaves the tools taken, the pegs in, the animals and family moved and
	# the door used. A fresh ark puts every piece back, including ones added later.
	var last_run := get_node_or_null("ChapterFour")
	if last_run and last_run.phase == ChapterFour.Phase.DONE:
		_fresh_ark().visit()
		return
	# Tapping the ark on the map mid-story only closes the map; the story carries on.
	if last_run and last_run.phase != ChapterFour.Phase.IDLE:
		return
	_build()
	var main := get_parent()
	set_weather("building")
	var player := main.get_node_or_null("Player") as CharacterBody3D
	if player:
		player.velocity = Vector3.ZERO
		player.global_position = _at(START_LOCAL)
		# The look set the framing: low and pulled back, so the hull rises behind the child.
		var cam := main.get_node_or_null("TabletopCamera") as Camera3D
		if cam and "offset" in cam:
			cam.global_position = player.global_position + cam.offset
			cam.look_at(player.global_position + Vector3(0.0, cam.get("look_height"), 0.0), Vector3.UP)
		var light := main.get_node_or_null("WonderLight") as Node3D
		if light and "hover_offset" in light:
			light.global_position = player.global_position + light.hover_offset
	var story := get_node_or_null("ChapterFour")
	if story and story.has_method("begin"):
		story.begin()


## True while the ark's story is under way; the shell then carries on instead of starting it.
func in_progress() -> bool:
	var story := get_node_or_null("ChapterFour")
	return story != null and story.phase != ChapterFour.Phase.IDLE and story.phase != ChapterFour.Phase.DONE


## Another story is starting: the ark makes way for an unbuilt ark, so nothing of this run
## keeps playing and the next visit starts whole. The next story's look resets the world.
func stand_down() -> void:
	if not _built:
		return
	var main := get_parent()
	# The shelter or rainbow shot may be the live camera, and it goes with this ark.
	var shots := main.get_node_or_null("CameraDirector")
	if shots and shots.has_method("cut_to_tabletop"):
		shots.cut_to_tabletop()
	_fresh_ark()


## Swaps this ark for an unbuilt one with the same name and place in the scene, so the
## map, the director and the touch button still find it. Its tweens go with it.
func _fresh_ark() -> Node3D:
	var main := get_parent()
	var index := get_index()
	var fresh := Node3D.new()
	fresh.set_script(get_script())
	main.remove_child(self)
	fresh.name = name
	main.add_child(fresh)
	main.move_child(fresh, index)
	queue_free()
	return fresh


func _build() -> void:
	if _built:
		return
	_built = true
	_layout.randomize()
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
	var colours := [Color(0.84, 0.52, 0.48), Color(0.9, 0.72, 0.5), Color(0.92, 0.86, 0.6), Color(0.6, 0.76, 0.58), Color(0.56, 0.68, 0.84)]
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
	var mountain := Mountain.new()
	mountain.name = "Mountain"
	mountain.position = ORIGIN
	add_child(mountain)
	_mountain = mountain


func _set_rain_light(main: Node) -> void:
	var world := main.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world and world.environment:
		var env := world.environment
		if env.sky:
			var sky := env.sky.sky_material as ProceduralSkyMaterial
			if sky:
				sky.sky_top_color = Color(0.4, 0.46, 0.55)
				sky.sky_horizon_color = Color(0.62, 0.66, 0.72)
		env.ambient_light_color = Color(0.66, 0.72, 0.84)
		env.ambient_light_energy = 0.75
		env.fog_light_color = Color(0.5, 0.56, 0.66)
		env.fog_density = 0.006
	var sun := main.get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		sun.light_color = Color(0.72, 0.8, 0.94)
		sun.light_energy = 0.45


## After the rain: still grey, but softer and lighter, with pale light through the window.
func _brighten_waiting(main: Node) -> void:
	var world := main.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world and world.environment:
		var env := world.environment
		var sky := env.sky.sky_material as ProceduralSkyMaterial if env.sky else null
		if sky:
			sky.sky_top_color = Color(0.5, 0.6, 0.7)
			sky.sky_horizon_color = Color(0.74, 0.78, 0.82)
		env.ambient_light_energy = 0.8
		env.fog_density = 0.004
	var sun := main.get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		sun.light_energy = 0.6


func _plain_dressing() -> void:
	# A worn earth path through the grass gives the child a clear line up to the ramp.
	Paper.part(self, "WornPath", Paper.box(Vector3(3.6, 0.035, 12.0)), EARTH.lightened(0.12),
			_at(Vector3(0.0, 0.075, 7.0)), Vector3.ZERO, Vector3.ONE, 0.0)
	# A few grey rocks at the edges of the work area.
	for i in 6:
		var side := -1.0 if i % 2 == 0 else 1.0
		Paper.part(self, "Rock%d" % i, Paper.sphere(0.45, 6), Color(0.66, 0.65, 0.6),
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
		_basket("Basket%d" % i, _at(baskets[i]), [Color(0.82, 0.7, 0.44), Color(0.56, 0.62, 0.42), Color(0.72, 0.48, 0.4), Color(0.88, 0.82, 0.66)][i])
	Paper.part(self, "Sack", Paper.sphere(0.36, 7), Color(0.84, 0.76, 0.6), _at(Vector3(-8.3, 0.3, -0.9)), Vector3.ZERO, Vector3(1.0, 0.9, 0.9), 0.02)


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
			if absi(x) <= 1:
				continue  # the doorway
			var z := Shapes.side_z(float(x), y)
			Paper.part(self, "Strake", Paper.box(Vector3(1.02, 0.12, 0.08)), PLANK_DARK.darkened(0.25),
					_at(Vector3(float(x), y, HULL_Z + z + 0.02)), Vector3.ZERO, Vector3.ONE, 0.0)
	# The doorway, tall enough for an elephant, and a long shallow ramp up to its sill.
	# The hull curves in towards the keel, so the opening, its frame and the door are
	# boards laid along that curve rather than flat cards.
	var entrance := Node3D.new()
	entrance.name = "Entrance"
	add_child(entrance)
	_along_side(entrance, "Dark", 0.0, DOOR_BOTTOM, DOOR_TOP, DOOR_HALF_WIDTH * 2.0, Color(0.26, 0.2, 0.16), 0.03)
	for side in [-1.0, 1.0]:
		_along_side(entrance, "Jamb", side * (DOOR_HALF_WIDTH + 0.11), DOOR_BOTTOM - 0.05, DOOR_TOP + 0.02, 0.22, PLANK_DARK, 0.07)
	Paper.part(entrance, "Lintel", Paper.box(Vector3(DOOR_HALF_WIDTH * 2.0 + 0.5, 0.2, 0.16)), PLANK_DARK,
			_at(Vector3(0.0, DOOR_TOP + 0.02, HULL_Z + Shapes.side_z(0.0, DOOR_TOP) + 0.07)), Vector3.ZERO, Vector3.ONE, 0.015)
	# The door itself, folded up under the lintel until God closes it (close_door): its
	# boards hang from the top, so growing it downwards unrolls it over the curve.
	_door = Node3D.new()
	_door.name = "Door"
	_door.position = _at(Vector3(0.0, DOOR_TOP, HULL_Z + Shapes.side_z(0.0, DOOR_TOP)))
	_door.scale = Vector3(1.0, 0.01, 1.0)
	_door.visible = false
	add_child(_door)
	_along_side(_door, "Leaf", 0.0, DOOR_BOTTOM, DOOR_TOP, DOOR_HALF_WIDTH * 2.0 + 0.1, PLANK_B, 0.11)
	for i in 4:
		var y := lerpf(DOOR_BOTTOM + 0.3, DOOR_TOP - 0.3, i / 3.0)
		Paper.part(_door, "Batten%d" % i, Paper.box(Vector3(DOOR_HALF_WIDTH * 2.0 - 0.1, 0.12, 0.05)), PLANK_DARK,
				_at(Vector3(0.0, y, HULL_Z + Shapes.side_z(0.0, y) + 0.17)) - _door.position, Vector3.ZERO, Vector3.ONE, 0.0)
	var ramp_top := Vector3(0.0, DOOR_BOTTOM - 0.05, HULL_Z + Shapes.side_z(0.0, DOOR_BOTTOM) + 0.2)
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


## Boards laid up the hull side at `x`, from `y0` to `y1`, following its curve and
## standing `out` proud of the planking, under `parent` (the ark or a node in it).
func _along_side(parent: Node3D, part_name: String, x: float, y0: float, y1: float, width: float, color: Color, out: float) -> void:
	var offset := Vector3.ZERO if parent == self else parent.position
	var steps := 10
	for k in steps:
		var ya := lerpf(y0, y1, float(k) / steps)
		var yb := lerpf(y0, y1, float(k + 1) / steps)
		# (z, y) points on the side, a little out from it.
		var a := Vector2(Shapes.side_z(x, ya) + out, ya)
		var b := Vector2(Shapes.side_z(x, yb) + out, yb)
		var mid := (a + b) * 0.5
		var seg := b - a
		Paper.part(parent, "%s%d" % [part_name, k], Paper.box(Vector3(width, seg.length() + 0.02, 0.06)), color,
				_at(Vector3(x, mid.y, HULL_Z + mid.x)) - offset, Vector3(atan2(seg.x, seg.y), 0.0, 0.0), Vector3.ONE, 0.0)


## Where a walker steps into (or out of) the doorway, `lane` metres along from its middle.
func _doorstep(lane: float) -> Vector3:
	return _at(Vector3(lane, DOOR_BOTTOM + 0.07, HULL_Z + Shapes.side_z(0.0, DOOR_BOTTOM) + 0.25))


## On the deck: the finished house with its roof and window at the bow end, and the bare
## curved ribs of the part still being built at the stern end.
func _upper_works() -> void:
	var deck := Shapes.DECK
	Paper.part(self, "House", Paper.box(Vector3(8.6, 2.1, 4.2)), Color(0.8, 0.72, 0.58),
			_at(Vector3(-1.7, deck + 0.95, HULL_Z)), Vector3.ZERO, Vector3.ONE, 0.035)
	for i in 9:
		Paper.part(self, "HouseSeam%d" % i, Paper.box(Vector3(0.05, 2.0, 0.03)), PLANK_DARK,
				_at(Vector3(-5.6 + i * 0.97, deck + 0.95, HULL_Z + 2.12)), Vector3.ZERO, Vector3.ONE, 0.0)
	Paper.part(self, "Roof", Paper.ridge_tent(5.2, 9.4, 1.5), Color(0.56, 0.42, 0.35),
			_at(Vector3(-1.7, deck + 2.0, HULL_Z)), Vector3(0.0, PI / 2.0, 0.0), Vector3.ONE, 0.04)
	for x in [-5.0, -3.0, -0.6]:
		Paper.part(self, "Porthole", Paper.box(Vector3(0.6, 0.5, 0.06)), Color(0.3, 0.2, 0.12),
				_at(Vector3(x, deck + 1.25, HULL_Z + 2.13)), Vector3.ZERO, Vector3.ONE, 0.02)
	# The window the dove leaves from: the one bright rectangle on the house.
	Paper.part(self, "Window", Paper.box(Vector3(1.0, 0.8, 0.06)), Color(0.95, 0.9, 0.76),
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
	for i in 3:
		var socket_glow := Paper.halo(0.55, GLOW)
		socket_glow.name = "SocketGlow%d" % i
		socket_glow.position = Vector3(-0.7 + i * 0.7, 0.15, 0.25)
		socket_glow.visible = false
		_panel.add_child(socket_glow)
		_sockets.append(socket_glow)
	var spot := Area3D.new()
	spot.name = "PanelSpot"
	spot.collision_layer = 0
	spot.collision_mask = 0
	spot.monitoring = false
	spot.position = _at(PANEL + Vector3(0.0, 0.2, 0.0))
	add_child(spot)
	_rope = Paper.part(_panel, "PanelRope", Paper.cylinder(0.05, 2.2, 6), Color(0.62, 0.46, 0.24),
			Vector3(0.0, 0.62, 0.14), Vector3(0.0, 0.0, PI / 2.0), Vector3.ONE, 0.012)


func _items() -> void:
	var spots := tool_layout(_layout)
	_tool("Mallet", _at(spots[0]))
	_tool("RopeCoil", _at(spots[1]))
	_tool("Pitch", _at(spots[2]))


## Three of TOOL_SPOTS, in a shuffled order, kept TOOL_APART apart and each nudged a little.
static func tool_layout(rng: RandomNumberGenerator) -> Array[Vector3]:
	var order: Array = TOOL_SPOTS.duplicate()
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: Vector3 = order[i]
		order[i] = order[j]
		order[j] = swap
	var picked: Array[Vector3] = []
	for spot in order:
		var far := true
		for other in picked:
			if (spot as Vector3).distance_to(other) < TOOL_APART:
				far = false
		if far:
			picked.append(spot)
		if picked.size() == 3:
			break
	for i in picked.size():
		picked[i] += Vector3(rng.randf_range(-TOOL_JITTER, TOOL_JITTER), 0.0, rng.randf_range(-TOOL_JITTER, TOOL_JITTER))
	return picked


## Wood, rope and sealed pitch, each with its own clear shape; nothing sharp.
func _tool(tool_name: String, at: Vector3) -> void:
	# An Area3D, so the chapter's golden hint arrow (wonder_item_hints.gd) can point at it.
	var root := Area3D.new()
	root.name = tool_name
	root.collision_layer = 0
	root.collision_mask = 2
	root.monitoring = false
	root.position = at
	add_child(root)
	# A soft gold glow that breathes, like the Wonder Items in the valley.
	var glow := Paper.halo(1.7, GLOW)
	glow.name = "Glow"
	glow.position = Vector3(0.0, 0.45, 0.0)
	root.add_child(glow)
	_glows.append(glow)
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
	_critter("ElephantA", "elephant", Vector3(6.4, 0.0, 4.4))
	_critter("ElephantB", "elephant", Vector3(8.2, 0.0, 7.4))
	_critter("GoatA", "goat", Vector3(-9.6, 0.0, 4.4))
	_critter("GoatB", "goat", Vector3(-5.5, 0.0, 1.0))
	_critter("RabbitA", "rabbit", Vector3(8.4, 0.0, 4.6))
	_critter("RabbitB", "rabbit", Vector3(5.6, 0.0, 2.4))
	_critter("GiraffeA", "giraffe", Vector3(-4.0, 0.0, 2.0))
	_critter("GiraffeB", "giraffe", Vector3(-2.2, 0.0, 0.2))


## Paper-diorama animals: each pair shares a silhouette and colour, and the second of
## the two has one small difference (an ear, a patch, a horn angle). Legs hang from hip
## pivots so they can swing (_stride), and end in a hoof, a pad or a foot.
func _critter(critter_name: String, kind: String, at: Vector3) -> void:
	var root := Node3D.new()
	root.name = critter_name
	# Each visit the herd stands a little differently; the big elephants move least.
	var wander := ANIMAL_JITTER * (0.5 if kind == "elephant" else 1.0)
	root.position = _at(at + Vector3(_layout.randf_range(-wander, wander), 0.0, _layout.randf_range(-wander, wander)))
	root.rotation.y = (0.35 if critter_name.ends_with("A") else -0.35) + _layout.randf_range(-ANIMAL_TURN, ANIMAL_TURN)
	# Elephants stand well above the grown-ups; everything else is at its drawn size.
	root.scale = Vector3.ONE * (ELEPHANT_SCALE if kind == "elephant" else 1.0)
	root.set_meta("kind", kind)
	root.set_meta("home", root.position)
	root.set_meta("aboard", false)
	add_child(root)
	_critter_marks(root, critter_name, kind)
	var b := critter_name.ends_with("B")
	var tilt := 0.25 if b else -0.1
	match kind:
		"sheep":
			var wool := Color(0.96, 0.94, 0.88)
			var face := Color(0.25, 0.2, 0.18)
			_legs(root, 0.16, 0.14, 0.34, face, 0.045, Color(0.14, 0.11, 0.1))
			# A smooth, slightly long fleece, like a toy: only a soft wavy line of wool along the
			# spine, so it reads as woolly without bumps that look like growths.
			var body_at := Vector3(0.0, 0.47, 0.0)
			var radii := Vector3(0.3, 0.27, 0.4)
			Paper.part(root, "Body", Paper.sphere(1.0, 16), wool, body_at, Vector3.ZERO, radii, 0.022)
			for k in 4:
				var along := lerpf(-0.7, 0.55, k / 3.0)
				Paper.part(root, "Fleece", Paper.sphere(0.16, 14), wool, body_at + Vector3(0.0, cos(along) * radii.y * 0.86, sin(along) * radii.z * 0.86),
						Vector3.ZERO, Vector3(1.1, 0.42, 1.0), 0.0)
			Paper.part(root, "Tail", Paper.sphere(0.06, 10), wool, body_at + Vector3(0.0, 0.05, -radii.z * 0.97), Vector3.ZERO, Vector3(1.0, 1.2, 0.7), 0.0)
			# The dark face stands clear of the fleece at the front, a little bowed, with a wool tuft.
			var head_at := Vector3(0.0, 0.56, 0.47)
			var head := Paper.part(root, "Head", Paper.sphere(0.13, 14), face, head_at, Vector3(0.35, 0.0, 0.0), Vector3(0.85, 1.0, 1.3), 0.015)
			Paper.part(root, "WoolCap", Paper.sphere(0.1, 12), wool, head_at + Vector3(0.0, 0.1, -0.06), Vector3.ZERO, Vector3(1.2, 0.6, 1.1), 0.0)
			for side in [-1.0, 1.0]:
				# On the head itself, so the eyes bow with it.
				Paper.part(head, "Eye", Paper.sphere(0.018, 6), Color(0.95, 0.93, 0.88), Vector3(side * 0.065, 0.045, 0.09), Vector3.ZERO, Vector3.ONE, 0.0)
			for side in [-1.0, 1.0]:
				# Out from the sides of the head and drooping; one of the pair's second droops lower.
				var droop := 0.75 if b and side > 0.0 else 0.35
				Paper.part(root, "Ear", Paper.sphere(0.075, 8), face, head_at + Vector3(side * 0.14, 0.02, -0.03), Vector3(0.0, 0.0, -side * droop), Vector3(1.0, 0.35, 0.6), 0.008)
		"goat":
			var coat := Color(0.64, 0.55, 0.43)
			_legs(root, 0.13, 0.14, 0.4, Color(0.4, 0.3, 0.2), 0.04, Color(0.16, 0.12, 0.1))
			Paper.part(root, "Body", Paper.sphere(0.3, 8), coat, Vector3(0.0, 0.54, 0.0), Vector3.ZERO, Vector3(0.9, 0.8, 1.3), 0.02)
			Paper.part(root, "Neck", Paper.cylinder(0.09, 0.26, 6, 0.07), coat, Vector3(0.0, 0.7, 0.3), Vector3(0.6, 0.0, 0.0), Vector3.ONE, 0.012)
			Paper.part(root, "Head", Paper.sphere(0.14, 8), coat.lightened(0.1), Vector3(0.0, 0.8, 0.42), Vector3.ZERO, Vector3(0.9, 1.0, 1.3), 0.015)
			Paper.part(root, "Beard", Paper.cylinder(0.04, 0.12, 5, 0.01), Color(0.9, 0.86, 0.78), Vector3(0.0, 0.66, 0.54), Vector3.ZERO, Vector3.ONE, 0.0)
			Paper.part(root, "Tail", Paper.box(Vector3(0.05, 0.14, 0.04)), coat.darkened(0.2), Vector3(0.0, 0.66, -0.4), Vector3(-0.6, 0.0, 0.0), Vector3.ONE, 0.0)
			for side in [-1.0, 1.0]:
				Paper.part(root, "Horn", Paper.cylinder(0.03, 0.26, 5, 0.01), Color(0.35, 0.27, 0.2), Vector3(side * 0.07, 0.99, 0.38), Vector3(-0.5 - tilt, 0.0, side * 0.2), Vector3.ONE, 0.0)
				Paper.part(root, "Ear", Paper.box(Vector3(0.16, 0.04, 0.07)), coat, Vector3(side * 0.15, 0.84, 0.38), Vector3(0.0, 0.0, side * -0.3), Vector3.ONE, 0.0)
			if b:
				Paper.part(root, "Patch", Paper.sphere(0.14, 6), Color(0.94, 0.9, 0.82), Vector3(0.18, 0.6, -0.05), Vector3.ZERO, Vector3(0.6, 1.0, 1.2), 0.0)
		"rabbit":
			var fur := Color(0.84, 0.78, 0.7)
			Paper.part(root, "Body", Paper.sphere(0.2, 8), fur, Vector3(0.0, 0.22, 0.0), Vector3.ZERO, Vector3(1.0, 0.95, 1.2), 0.015)
			Paper.part(root, "Head", Paper.sphere(0.13, 8), fur, Vector3(0.0, 0.38, 0.17), Vector3.ZERO, Vector3.ONE, 0.012)
			Paper.part(root, "Nose", Paper.sphere(0.025, 5), Color(0.86, 0.56, 0.56), Vector3(0.0, 0.38, 0.3), Vector3.ZERO, Vector3.ONE, 0.0)
			Paper.part(root, "Tail", Paper.sphere(0.07, 6), Color(0.98, 0.96, 0.92), Vector3(0.0, 0.26, -0.24), Vector3.ZERO, Vector3.ONE, 0.0)
			for side in [-1.0, 1.0]:
				var droop := 0.9 if b and side > 0.0 else 0.1
				Paper.part(root, "Ear", Paper.box(Vector3(0.07, 0.3, 0.035)), fur.darkened(0.08), Vector3(side * 0.06, 0.6, 0.14), Vector3(0.0, 0.0, side * droop), Vector3.ONE, 0.01)
				# Folded haunches, long flat hind feet and two small front paws: it sits up on them.
				Paper.part(root, "Haunch", Paper.sphere(0.11, 7), fur.darkened(0.04), Vector3(side * 0.12, 0.13, -0.08), Vector3.ZERO, Vector3(0.6, 0.9, 1.2), 0.01)
				Paper.part(root, "HindFoot", Paper.box(Vector3(0.07, 0.04, 0.2)), fur.lightened(0.12), Vector3(side * 0.11, 0.02, -0.02), Vector3.ZERO, Vector3.ONE, 0.008)
				Paper.part(root, "Paw", Paper.sphere(0.035, 6), fur.lightened(0.12), Vector3(side * 0.06, 0.03, 0.17), Vector3.ZERO, Vector3(1.0, 0.8, 1.3), 0.006)
		"dove":
			var feather := Color(0.97, 0.97, 0.94)
			var shin := Color(0.86, 0.5, 0.44)
			Paper.part(root, "Body", Paper.sphere(0.15, 8), feather, Vector3(0.0, 0.26, 0.0), Vector3.ZERO, Vector3(0.9, 0.85, 1.4), 0.012)
			Paper.part(root, "Head", Paper.sphere(0.09, 8), feather, Vector3(0.0, 0.38, 0.16), Vector3.ZERO, Vector3.ONE, 0.01)
			Paper.part(root, "Beak", Paper.cylinder(0.025, 0.08, 5, 0.0), Color(0.9, 0.6, 0.3), Vector3(0.0, 0.37, 0.27), Vector3(PI / 2.0, 0.0, 0.0), Vector3.ONE, 0.0)
			Paper.part(root, "Tail", Paper.box(Vector3(0.14, 0.03, 0.16)), Color(0.82, 0.84, 0.86), Vector3(0.0, 0.27, -0.24), Vector3(0.2, 0.0, 0.0), Vector3.ONE, 0.0)
			root.set_meta("gait_rate", 20.0)
			for side in [-1.0, 1.0]:
				Paper.part(root, "Wing", Paper.box(Vector3(0.05, 0.12, 0.26)), Color(0.8, 0.82, 0.86) if not b else Color(0.88, 0.88, 0.9), Vector3(side * 0.13, 0.28, -0.02), Vector3(0.0, 0.0, side * 0.3), Vector3.ONE, 0.0)
				# Two thin pink legs with three-toed feet, so it stands rather than sits on the grass.
				var hip := _hip(root, Vector3(side * 0.05, 0.15, 0.0), side)
				Paper.part(hip, "Shin", Paper.cylinder(0.012, 0.14, 5), shin, Vector3(0.0, -0.07, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
				for toe in [-0.5, 0.0, 0.5]:
					Paper.part(hip, "Toe", Paper.box(Vector3(0.012, 0.012, 0.06)), shin, Vector3(0.0, -0.14, 0.025), Vector3(0.0, toe, 0.0), Vector3.ONE, 0.0)
		"elephant":
			var hide := Color(0.52, 0.54, 0.58)
			_legs(root, 0.3, 0.3, 0.55, hide.darkened(0.1), 0.13, hide.darkened(0.2), true)
			Paper.part(root, "Body", Paper.sphere(0.55, 9), hide, Vector3(0.0, 0.85, 0.0), Vector3.ZERO, Vector3(1.0, 0.85, 1.25), 0.03)
			Paper.part(root, "Head", Paper.sphere(0.36, 8), hide, Vector3(0.0, 1.05, 0.62), Vector3.ZERO, Vector3.ONE, 0.025)
			Paper.part(root, "Trunk", Paper.cylinder(0.1, 0.62, 7, 0.06), hide.darkened(0.04), Vector3(0.0, 0.72, 0.9), Vector3(0.35, 0.0, 0.0), Vector3.ONE, 0.018)
			Paper.part(root, "Tail", Paper.cylinder(0.025, 0.36, 5, 0.015), hide.darkened(0.1), Vector3(0.0, 0.78, -0.7), Vector3(-0.3, 0.0, 0.0), Vector3.ONE, 0.0)
			Paper.part(root, "TailTuft", Paper.sphere(0.05, 6), Color(0.25, 0.22, 0.2), Vector3(0.0, 0.6, -0.76), Vector3.ZERO, Vector3(0.8, 1.4, 0.8), 0.0)
			for side in [-1.0, 1.0]:
				Paper.part(root, "Ear", Paper.sphere(0.3, 7), Color(0.7, 0.62, 0.64), Vector3(side * 0.36, 1.1, 0.5), Vector3(0.0, side * (0.5 + tilt), 0.0), Vector3(0.25, 1.0, 0.9), 0.02)
				# Short cream tusks either side of the trunk; the pair's second has shorter ones.
				Paper.part(root, "Tusk", Paper.cylinder(0.04, 0.26 if not b else 0.18, 6, 0.012), Color(0.96, 0.92, 0.82), Vector3(side * 0.13, 0.84, 0.92), Vector3(1.2, 0.0, side * -0.2), Vector3.ONE, 0.008)
				Paper.part(root, "Eye", Paper.sphere(0.035, 6), Color(0.1, 0.08, 0.07), Vector3(side * 0.24, 1.14, 0.86), Vector3.ZERO, Vector3.ONE, 0.0)
		"giraffe":
			var coat := Color(0.86, 0.75, 0.53)
			var patch := Color(0.6, 0.47, 0.34)
			_legs(root, 0.16, 0.2, 0.9, coat.darkened(0.08), 0.06, Color(0.22, 0.17, 0.13))
			Paper.part(root, "Body", Paper.sphere(0.3, 8), coat, Vector3(0.0, 1.0, 0.0), Vector3.ZERO, Vector3(0.95, 0.8, 1.3), 0.02)
			Paper.part(root, "Neck", Paper.cylinder(0.09, 1.1, 6, 0.07), coat, Vector3(0.0, 1.6, 0.3), Vector3(0.3, 0.0, 0.0), Vector3.ONE, 0.018)
			# A short brown mane down the back of the neck.
			Paper.part(root, "Mane", Paper.box(Vector3(0.035, 1.0, 0.07)), patch.darkened(0.15), Vector3(0.0, 1.62, 0.2), Vector3(0.3, 0.0, 0.0), Vector3.ONE, 0.0)
			Paper.part(root, "Head", Paper.sphere(0.13, 7), coat, Vector3(0.0, 2.15, 0.52), Vector3.ZERO, Vector3(0.9, 0.9, 1.5), 0.015)
			Paper.part(root, "Tail", Paper.cylinder(0.02, 0.4, 5, 0.012), coat.darkened(0.1), Vector3(0.0, 0.92, -0.42), Vector3(-0.25, 0.0, 0.0), Vector3.ONE, 0.0)
			Paper.part(root, "TailTuft", Paper.sphere(0.05, 6), Color(0.25, 0.18, 0.12), Vector3(0.0, 0.72, -0.47), Vector3.ZERO, Vector3(0.8, 1.5, 0.8), 0.0)
			for side in [-1.0, 1.0]:
				Paper.part(root, "Ossicone", Paper.cylinder(0.025, 0.14, 5), Color(0.45, 0.3, 0.18), Vector3(side * 0.05, 2.28, 0.46), Vector3(0.0, 0.0, side * 0.15), Vector3.ONE, 0.0)
				Paper.part(root, "Ear", Paper.box(Vector3(0.12, 0.035, 0.06)), coat, Vector3(side * 0.11, 2.22, 0.44), Vector3(0.0, 0.0, side * 0.35), Vector3.ONE, 0.0)
			var spots := [Vector3(0.2, 1.05, 0.1), Vector3(-0.2, 1.0, -0.15), Vector3(0.15, 0.95, -0.25)] if not b else [Vector3(-0.2, 1.05, 0.12), Vector3(0.21, 0.98, -0.1), Vector3(-0.12, 1.12, -0.28)]
			for k in spots.size():
				Paper.part(root, "Spot%d" % k, Paper.sphere(0.09, 6), patch, spots[k], Vector3.ZERO, Vector3(0.6, 1.0, 1.0), 0.0)


## Four legs in diagonal pairs, each hung from its hip so a stride swings it from the
## top, ending in a darker hoof or, for the elephant, a broad pad with cream toenails.
func _legs(root: Node3D, half_x: float, half_z: float, height: float, color: Color, radius: float = 0.045,
		hoof: Color = Color(0.18, 0.14, 0.12), pads: bool = false) -> void:
	# Longer legs take longer steps: the gait turns this many radians per metre walked.
	root.set_meta("gait_rate", 2.4 / (height * root.scale.y))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var hip := _hip(root, Vector3(sx * half_x, height, sz * half_z), sx * sz)
			Paper.part(hip, "Leg", Paper.cylinder(radius, height, 6), color, Vector3(0.0, -height * 0.5, 0.0), Vector3.ZERO, Vector3.ONE, 0.01)
			if pads:
				Paper.part(hip, "Pad", Paper.cylinder(radius * 1.2, 0.1, 8), color.darkened(0.06), Vector3(0.0, -height + 0.05, 0.0), Vector3.ZERO, Vector3.ONE, 0.012)
				for toe in [-0.6, 0.0, 0.6]:
					Paper.part(hip, "Toenail", Paper.sphere(0.035, 5), Color(0.9, 0.86, 0.76), Vector3(sin(toe) * radius * 1.05, -height + 0.05, cos(toe) * radius * 1.12), Vector3.ZERO, Vector3(1.0, 0.8, 0.6), 0.0)
			else:
				Paper.part(hip, "Hoof", Paper.cylinder(radius * 1.15, 0.07, 6, radius), hoof, Vector3(0.0, -height + 0.035, 0.0), Vector3.ZERO, Vector3.ONE, 0.008)


## An empty joint the leg parts hang from; `stride_side` says which half of the gait it takes.
func _hip(root: Node3D, at: Vector3, side: float) -> Node3D:
	var hip := Node3D.new()
	hip.name = "Hip"
	hip.position = at
	hip.set_meta("stride_side", side)
	root.add_child(hip, true)
	return hip


## Swings the legs in diagonal pairs by how far the animal has just moved, so an amble
## is a slow step and being led is a real walk; standing still lets them settle.
func _stride(animal: Node3D, moved: float, delta: float) -> void:
	var gait := float(animal.get_meta("gait", 0.0)) + moved * float(animal.get_meta("gait_rate", 7.0))
	animal.set_meta("gait", gait)
	var want := clampf(moved / maxf(delta, 0.0001) / 1.2, 0.0, 1.0)
	var amount := move_toward(float(animal.get_meta("gait_amount", 0.0)), want, delta * 4.0)
	animal.set_meta("gait_amount", amount)
	for part in animal.get_children():
		if part is Node3D and part.has_meta("stride_side"):
			part.rotation.x = sin(gait) * float(part.get_meta("stride_side")) * 0.5 * amount


func _people() -> void:
	# In front of the crowd, facing the child, either side of the path up to the ramp.
	# The models face the ark until turned.
	_noah = _designed("Noah", "noah", Vector3(-2.3, 0.0, 5.3))
	_wife = _designed("NoahsWife", "wife", Vector3(2.2, 0.0, 5.0))


func _designed(person_name: String, who: String, at: Vector3) -> Node3D:
	var person := Node3D.new()
	person.name = person_name
	person.set_script(ArkPerson)
	person.who = who
	person.position = _at(at)
	person.rotation.y = PI
	# The Blender models face -z, where the block people and animals face +z; a walk turns them this much more.
	person.set_meta("forward_yaw", PI)
	add_child(person)
	return person


func _person(person_name: String, at: Vector3, cloth: Color, hair: Color, beard: bool, under: Color = Color(0.9, 0.84, 0.7), style: String = "") -> Node3D:
	var root := Node3D.new()
	root.name = person_name
	root.position = at
	add_child(root)
	for side in [-1.0, 1.0]:
		var foot := Paper.part(root, "Foot", Paper.box(Vector3(0.16, 0.12, 0.28)), PLANK_DARK, Vector3(side * 0.17, 0.06, 0.08), Vector3.ZERO, Vector3.ONE, 0.01)
		foot.set_meta("step_side", side)
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
	var colours := [Color(0.56, 0.46, 0.36), Color(0.5, 0.56, 0.46), Color(0.66, 0.56, 0.44), Color(0.52, 0.48, 0.56), Color(0.62, 0.5, 0.4), Color(0.44, 0.52, 0.58)]
	var spots := [Vector3(8.4, 0.0, 1.2), Vector3(10.2, 0.0, 1.2), Vector3(-9.2, 0.0, -0.8), Vector3(-8.8, 0.0, 1.3), Vector3(2.4, 0.0, 3.6), Vector3(2.2, 0.0, 1.4)]
	var hair := [Color(0.3, 0.2, 0.12), Color(0.22, 0.14, 0.08), Color(0.4, 0.26, 0.14)]
	for i in colours.size():
		var style := "wrap" if i % 2 == 1 else ""
		var person := _person("Family%d" % i, _at(spots[i]), colours[i], hair[i % 3], i == 4, Color(0.9, 0.84, 0.7), style)
		person.rotation.y = [0.0, 0.0, 0.6, -0.4, -0.3, 0.3][i]
		person.set_meta("home", person.position)
	# The plank rides between the first two on their shoulders, so it travels with them.
	var carrier := get_node("Family0") as Node3D
	Paper.part(carrier, "CarriedPlank", Paper.box(Vector3(0.34, 0.12, 2.6)), PLANK_LIGHT, Vector3(0.0, 1.1, 0.9), Vector3.ZERO, Vector3.ONE, 0.02)
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
	for side in [-1.0, 1.0]:
		Paper.part(dove, "Eye", Paper.sphere(0.012, 7), Color(0.12, 0.1, 0.08), Vector3(0.19, 0.105, side * 0.063), Vector3.ZERO, Vector3.ONE, 0)
	Paper.part(dove, "Beak", Paper.cylinder(0.026, 0.09, 6, 0.0), Color(0.69, 0.51, 0.28), Vector3(0.26, 0.07, 0), Vector3(0, 0, -PI / 2.0), Vector3.ONE, 0.005)
	Paper.part(dove, "Tail", Paper.sphere(0.1, 7), Color(0.87, 0.88, 0.84), Vector3(-0.23, 0.02, 0), Vector3(0, 0, -0.2), Vector3(1.3, 0.15, 0.75), 0.006)
	var leaf := Node3D.new()
	leaf.name = "Leaf"
	dove.add_child(leaf)
	Paper.part(leaf, "Twig", Paper.cylinder(0.008, 0.23, 6), Color(0.39, 0.33, 0.17), Vector3(0.36, 0.05, 0), Vector3(0, 0, PI / 2.0), Vector3.ONE, 0)
	for side in [-1.0, 1.0]:
		Paper.part(leaf, "OliveLeaf", Paper.sphere(0.08, 8), Color(0.35, 0.53, 0.24), Vector3(0.38, 0.055, side * 0.045), Vector3(0, side * 0.5, 0), Vector3(1.25, 0.12, 0.55), 0.004)
	leaf.visible = false


## "building" (dry daylight), "rain" (rain, water rising over the cloud sea), "waiting"
## (rain stopped, water still high, soft grey-blue), "receding" (the water going down)
## and "morning" (dry ground and the rainbow).
func set_weather(state: String) -> void:
	weather_state = state
	if _rain:
		_rain.visible = state == "rain"
	_transition_light(state)
	if _shelter:
		_shelter.rain.visible = state == "rain"
		_shelter.set_sky(state)
	if _mountain and _mountain.has_method("set_flood"):
		match state:
			"rain":
				_mountain.set_flood(FLOOD_HIGH, 5.0)
			"waiting":
				_mountain.set_flood(FLOOD_HIGH, 1.0)
			"receding":
				_mountain.set_flood(FLOOD_MID, 3.0)
			_:
				_mountain.set_flood(-100.0, 3.0 if state == "morning" else 0.0)
	if state != "morning":
		if _rainbow_transition:
			_rainbow_transition.kill()
		_rainbow.visible = false


## Capture the current lighting before setting the new palette, then crossfade.
## Killing the previous tween makes quick NEXT/sky turns converge on the newest state.
func _transition_light(state: String) -> void:
	if _light_transition:
		_light_transition.kill()
	var main := get_parent()
	var env: Environment = main.get_node("WorldEnvironment").environment
	var sky: ProceduralSkyMaterial = env.sky.sky_material
	var sun: Node = main.get_node("Sun")
	var fill: Node = main.get_node("FillLight")
	var groups := [
		[env, ["ambient_light_color", "ambient_light_energy", "fog_light_color", "fog_density"]],
		[sky, ["sky_top_color", "sky_horizon_color", "ground_horizon_color", "ground_bottom_color"]],
		[sun, ["light_color", "light_energy"]], [fill, ["light_color", "light_energy"]],
	]
	var previous: Array = []
	for group in groups:
		for property in group[1]:
			previous.append(group[0].get(property))
	# Every weather starts from the story's own look, then changes what it needs.
	if main.has_method("apply_lighting"):
		main.apply_lighting(look)
	if state in ["rain", "waiting", "receding"]:
		_set_rain_light(main)
		if state != "rain":
			_brighten_waiting(main)
	elif state == "morning":
		sky.sky_top_color = Color(0.55, 0.77, 0.88)
		sky.sky_horizon_color = Color(0.93, 0.91, 0.81)
		sky.ground_horizon_color = Color(0.91, 0.88, 0.75)
		env.ambient_light_color = Color(0.88, 0.91, 0.84)
		env.ambient_light_energy = 0.75
		env.fog_light_color = Color(0.86, 0.91, 0.9)
		env.fog_density = 0.002
		sun.light_color = Color(1.0, 0.95, 0.84)
		sun.light_energy = 1.02
		fill.light_color = Color(0.72, 0.86, 0.91)
	if state == "building":
		return
	_light_transition = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var i := 0
	for group in groups:
		for property in group[1]:
			var target: Variant = group[0].get(property)
			group[0].set(property, previous[i])
			_light_transition.tween_property(group[0], property, target, 2.5)
			i += 1


func show_story_shot(shot: String) -> void:
	if shot in ["shelter", "window", "leaf"]:
		if _shelter == null:
			_shelter = Shelter.new()
			_shelter.name = "Shelter"
			_shelter.position = ORIGIN + Vector3(0, 60, 0)
			add_child(_shelter)
			_shelter.build(self)
		_shelter.rain.visible = weather_state == "rain"
		_shelter.set_sky(weather_state)
		_shelter.show_shot(shot)
	else:
		if _shelter:
			_shelter.visible = false
			_shelter.process_mode = Node.PROCESS_MODE_DISABLED
		if shot == "rainbow":
			if _story_camera == null:
				_story_camera = Camera3D.new()
				_story_camera.name = "RainbowCamera"
				add_child(_story_camera)
			_story_camera.fov = 55.0
			_story_camera.global_position = _at(Vector3(0, 9.5, 28))
			_story_camera.look_at(_at(Vector3(0, 6.5, -7)), Vector3.UP)
			_story_camera.current = true


func reveal_rainbow() -> void:
	if _rainbow_transition:
		_rainbow_transition.kill()
	_rainbow.visible = true
	_rainbow_transition = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for i in _bands.size():
		_bands[i].scale = Vector3(1, 0.01, 1)
		_rainbow_transition.tween_property(_bands[i], "scale:y", 1.0, 1.5).set_delay(i * 0.12)


func fly_dove(with_leaf: bool) -> void:
	show_story_shot("window")
	await _shelter.fly(with_leaf)


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


## The tools still lying on the ground, for the hint arrow.
func tool_spots() -> Array:
	var out: Array = []
	for tool_name in ["Mallet", "RopeCoil", "Pitch"]:
		var tool := get_node_or_null(tool_name) as Area3D
		if tool and tool.visible:
			out.append(tool)
	return out


func panel_spot() -> Area3D:
	return get_node_or_null("PanelSpot") as Area3D


## The next socket to peg glows; -1 puts the glow away.
func highlight_socket(index: int) -> void:
	for i in _sockets.size():
		_sockets[i].visible = i == index


## Gold markers over the animals the child can lead, while Two by Two is on.
func show_beacons(on: bool) -> void:
	_beacons_on = on
	for beacon in _beacons:
		beacon.visible = on and not _unavailable(beacon.get_parent() as Node3D)


## The spot under an animal, for the hint arrow: the guided ones before one is chosen,
## then the partner of the one being led.
func guide_spots() -> Array:
	var out: Array = []
	for critter_name in GUIDED:
		var animal := get_node_or_null(critter_name) as Node3D
		if animal and not _unavailable(animal):
			out.append(animal.get_node("%sSpot" % critter_name))
	return out


func mate_spot(critter_name: String) -> Area3D:
	var mate_name := str(MATE_OF.get(critter_name, ""))
	var mate := get_node_or_null(mate_name) as Node3D
	return mate.get_node_or_null("%sSpot" % mate_name) as Area3D if mate else null


## A gold ring on the ground under the partner the led animal is looking for.
func mark_mate(critter_name: String, on: bool) -> void:
	for other in MATE_OF.values():
		var animal := get_node_or_null(str(other)) as Node3D
		if animal:
			(animal.get_node("Ring") as Node3D).visible = on and other == MATE_OF.get(critter_name, "")


## God closes the door: it folds down over the entrance. `false` opens it again.
func close_door(closed: bool) -> void:
	if _door == null:
		return
	var tw := create_tween()
	if closed:
		_door.visible = true
		_door.scale = Vector3(1.0, 0.01, 1.0)
		tw.tween_property(_door, "scale:y", 1.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		tw.tween_property(_door, "scale:y", 0.01, 1.0).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func() -> void: _door.visible = false)


func _critter_marks(root: Node3D, critter_name: String, kind: String) -> void:
	var spot := Area3D.new()
	spot.name = "%sSpot" % critter_name
	spot.collision_layer = 0
	spot.collision_mask = 0
	spot.monitoring = false
	root.add_child(spot)
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.72 if kind in ["elephant", "giraffe"] else 0.48
	ring_mesh.outer_radius = ring_mesh.inner_radius + 0.12
	ring_mesh.rings = 24
	ring_mesh.ring_segments = 4
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	ring.mesh = ring_mesh
	ring.material_override = Paper.glow_mat(GLOW)
	ring.scale = Vector3(1.0, 0.3, 1.0)
	ring.position.y = 0.05
	ring.visible = false
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)
	if critter_name not in GUIDED:
		return
	# Local heights: the elephant's is inside its scale, so it still floats just over its head.
	var heights := {"sheep": 1.2, "dove": 0.85, "elephant": 1.7, "giraffe": 2.8, "goat": 1.3, "rabbit": 1.0}
	var beacon := Node3D.new()
	beacon.name = "Beacon"
	beacon.position.y = heights.get(kind, 1.3)
	beacon.set_meta("y", beacon.position.y)
	beacon.visible = false
	root.add_child(beacon)
	Paper.part(beacon, "Gem", Paper.box(Vector3(0.24, 0.24, 0.24)), GLOW, Vector3.ZERO, Vector3(0.0, 0.0, PI / 4.0), Vector3(1.0, 1.4, 1.0), 0.02)
	var halo := Paper.halo(0.9, GLOW)
	beacon.add_child(halo)
	_beacons.append(beacon)


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
		if animal == null or _unavailable(animal):
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
	_stride(animal, Vector2(next.x - animal.global_position.x, next.z - animal.global_position.z).length(), delta)
	animal.global_position = next
	# Wherever the child leaves it, that becomes its new spot to graze around.
	animal.set_meta("led_at", _time)
	animal.set_meta("home", Vector3(next.x, (animal.get_meta("home") as Vector3).y, next.z))
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
	for critter_name in MATE_OF.keys():
		var animal := get_node_or_null(critter_name) as Node3D
		if animal and not _unavailable(animal):
			board_pair(critter_name)


func aboard_count() -> int:
	var n := 0
	for child in get_children():
		if child is Node3D and child.has_meta("kind") and bool(child.get_meta("aboard", false)):
			n += 1
	return n


func _board_one(critter_name: String, side: float) -> void:
	var animal := get_node_or_null(critter_name) as Node3D
	if animal == null or _unavailable(animal):
		return
	_queue_boarding(animal, -0.45 if side == 0.0 else 0.45)


func family_inside() -> void:
	if _family_in:
		return
	_family_in = true
	set_speaking("")
	# Leave the shared timber at the work site before its carriers separate.
	var plank := get_node_or_null("Family0/CarriedPlank") as Node3D
	if plank:
		plank.reparent(self, true)
		create_tween().tween_property(plank, "position:y", ORIGIN.y + 0.15, 0.4).set_trans(Tween.TRANS_SINE)
	for i in 6:
		var person := get_node_or_null("Family%d" % i) as Node3D
		if person:
			_queue_boarding(person, -0.4 if i % 2 == 0 else 0.4)
	if _wife:
		_queue_boarding(_wife, -0.4)
	if _noah:
		_queue_boarding(_noah, 0.4)


## Approach in front of the work area, then take a timed slot on the ramp.
## Node-bound tweens pause with the story and are cancelled when it is freed.
func _queue_boarding(actor: Node3D, lane: float) -> void:
	actor.set_meta("boarding", true)
	actor.rotation.x = 0.0
	_boarding_pending += 1
	var start := actor.position
	var front := Vector3(start.x, ORIGIN.y + 0.12, ORIGIN.z + RAMP_FOOT_Z + 1.1)
	var foot := _at(Vector3(lane, 0.12, RAMP_FOOT_Z + 0.2))
	var entrance := _doorstep(lane)
	var approach := maxf(start.distance_to(front) / 3.0, 0.05) + maxf(front.distance_to(foot) / 3.0, 0.05)
	var ramp_start := maxf(_time + approach, _ramp_available)
	_ramp_available = ramp_start + 0.8
	var tw := create_tween()
	if ramp_start > _time + approach:
		tw.tween_interval(ramp_start - _time - approach)
	_walk_segment(tw, actor, start, front)
	_walk_segment(tw, actor, front, foot)
	_walk_segment(tw, actor, foot, entrance)
	tw.tween_callback(func() -> void:
		actor.set_meta("boarding", false)
		actor.set_meta("aboard", true)
		actor.visible = false
		actor.position.z -= 1.5
		_boarding_pending -= 1
		if _boarding_pending == 0:
			boarding_finished.emit()
	)


func _walk_segment(tw: Tween, actor: Node3D, start: Vector3, finish: Vector3) -> void:
	var duration := maxf(start.distance_to(finish) / 3.0, 0.05)
	tw.tween_callback(func() -> void: actor.set_meta("walk_yaw", actor.rotation.y))
	tw.tween_method(func(t: float) -> void:
		var direction := finish - start
		var yaw := atan2(direction.x, direction.z) + float(actor.get_meta("forward_yaw", 0.0))
		var from_yaw := float(actor.get_meta("walk_yaw"))
		# A sharp corner is turned on the spot first, so nobody slides backwards round it.
		var turn_share := clampf(absf(angle_difference(from_yaw, yaw)) / PI, 0.0, 1.0) * 0.3
		actor.rotation.y = lerp_angle(from_yaw, yaw, smoothstep(0.0, maxf(turn_share, 0.12), t))
		var along := clampf((t - turn_share) / (1.0 - turn_share), 0.0, 1.0)
		var stride := sin(along * duration * 9.0)
		var settle := sin(PI * along)
		actor.position = start.lerp(finish, along) + Vector3.UP * absf(stride) * 0.035 * settle
		for part in actor.get_children():
			if part is Node3D and part.has_meta("stride_side"):
				part.rotation.x = stride * float(part.get_meta("stride_side")) * 0.28 * settle
			if part is Node3D and part.has_meta("step_side"):
				var step := stride * float(part.get_meta("step_side")) * settle
				part.position.z = 0.08 + step * 0.13
				part.position.y = 0.06 + maxf(step, 0.0) * 0.06
		if "walk_amount" in actor:
			actor.walk_amount = settle
	, 0.0, 1.0, duration)


## Frame the procession from the arrival spot, clear of the ramp and work bench.
func keep_guest_outside(player: Node3D) -> void:
	if player == null:
		return
	if player.global_position != _at(START_LOCAL):
		player.global_position = _at(START_LOCAL)
		if "velocity" in player:
			player.velocity = Vector3.ZERO


func dove() -> Node3D:
	return _shelter.bird if _shelter and _shelter.visible else get_node_or_null("WindowDove") as Node3D


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
			if d.position.y < ORIGIN.y:
				d.position.y += RAIN_HEIGHT
	for child in get_children():
		if child is Node3D and child.has_meta("kind") and not _unavailable(child):
			_graze(child, delta)
	var breathe := 1.0 + sin(_time * 3.0) * 0.12
	for glow in _glows:
		glow.scale = Vector3.ONE * breathe
	for beacon in _beacons:
		var animal := beacon.get_parent() as Node3D
		var led := _time - float(animal.get_meta("led_at", -10.0)) < 0.6
		beacon.visible = _beacons_on and not led and not _unavailable(animal)
		beacon.rotation.y = _time * 1.6
		beacon.position.y = float(beacon.get_meta("y")) + sin(_time * 3.0) * 0.08
	for socket in _sockets:
		socket.scale = Vector3.ONE * (1.0 + sin(_time * 5.0) * 0.2)
	if not _family_in:
		_work(delta)


## An animal left alone ambles in a small loop around its spot, turning as it goes,
## and now and then dips its head to graze. The one the child is leading is left alone.
func _graze(animal: Node3D, delta: float) -> void:
	var seed := float(absi(str(animal.name).hash()) % 997) * 0.013
	var head := animal.get_node_or_null("Head") as Node3D
	if head:
		var rest: Vector3 = head.get_meta("rest", head.position)
		head.set_meta("rest", rest)
		var dip := clampf(sin(_time * 0.45 + seed * 3.0) * 2.0 - 1.1, 0.0, 1.0)
		head.position = rest + Vector3(0.0, -0.14 * dip + sin(_time * 2.2 + seed) * 0.012, 0.06 * dip)
	if _time - float(animal.get_meta("led_at", -10.0)) < 0.6:
		return
	var kind := str(animal.get_meta("kind"))
	var home: Vector3 = animal.get_meta("home")
	var reach := 0.5 if kind in ["elephant", "giraffe"] else 0.32
	var t := _time * 0.2 + seed
	var target := home + Vector3(sin(t), 0.0, sin(t * 0.73 + 1.1)) * reach
	var step := Vector3(target.x - animal.position.x, 0.0, target.z - animal.position.z)
	var moved := animal.position.move_toward(Vector3(target.x, home.y, target.z), 0.3 * delta)
	var hop := 0.0
	if kind in ["rabbit", "dove"]:
		hop = maxf(sin(_time * 5.0 + seed * 7.0), 0.0) * (0.07 if kind == "rabbit" else 0.04)
	_stride(animal, Vector2(moved.x - animal.position.x, moved.z - animal.position.z).length(), delta)
	animal.position = Vector3(moved.x, home.y + hop, moved.z)
	if step.length() > 0.02:
		animal.rotation.y = lerp_angle(animal.rotation.y, atan2(step.x, step.z), 1.5 * delta)


## The family keeps working: two carry a plank round the timber stack, one walks a
## basket between the food and the path, and the others bend, straighten and look about.
func _work(delta: float) -> void:
	var tail := get_node_or_null("Family0") as Node3D
	var lead := get_node_or_null("Family1") as Node3D
	if tail and lead:
		var a := _time * 0.22
		var lead_at := CARRY_CENTER + Vector3(cos(a + CARRY_GAP), 0.0, sin(a + CARRY_GAP)) * CARRY_RADIUS
		var tail_at := CARRY_CENTER + Vector3(cos(a), 0.0, sin(a)) * CARRY_RADIUS
		lead.position = _at(lead_at) + Vector3(0.0, absf(sin(_time * 4.2)) * 0.03, 0.0)
		tail.position = _at(tail_at) + Vector3(0.0, absf(sin(_time * 4.2 + 1.2)) * 0.03, 0.0)
		# The one behind faces the one ahead, so the plank on its shoulder runs between them.
		var ahead := lead.position - tail.position
		tail.rotation.y = atan2(ahead.x, ahead.z)
		lead.rotation.y = atan2(-sin(a + CARRY_GAP), cos(a + CARRY_GAP))
	var walker := get_node_or_null("Family3") as Node3D
	if walker:
		var s := (1.0 - cos(_time * 0.3)) * 0.5
		var was := walker.position
		walker.position = _at(BASKET_WALK_FROM.lerp(BASKET_WALK_TO, s)) + Vector3(0.0, absf(sin(_time * 4.0)) * 0.025, 0.0)
		var going := walker.position - was
		if Vector2(going.x, going.z).length() > 0.0005:
			walker.rotation.y = lerp_angle(walker.rotation.y, atan2(going.x, going.z), 4.0 * delta)
	for i in [2, 4, 5]:
		var person := get_node_or_null("Family%d" % i) as Node3D
		if person == null:
			continue
		var home_yaw: float = person.get_meta("yaw", person.rotation.y)
		person.set_meta("yaw", home_yaw)
		person.rotation.x = maxf(sin(_time * 0.6 + i), 0.0) * 0.28
		person.rotation.y = home_yaw + sin(_time * 0.35 + i * 2.0) * 0.5
		person.rotation.z = sin(_time * 1.1 + i) * 0.03


## The morning has people in it: the saved family and animals emerge into daylight.
func leave_ark() -> void:
	if _exited:
		return
	_exited = true
	var actors: Array[Node3D] = [_noah, _wife]
	for i in 6:
		actors.append(get_node("Family%d" % i))
	for pair in MATE_OF:
		actors.append(get_node(pair))
		actors.append(get_node(MATE_OF[pair]))
	for i in actors.size():
		var actor := actors[i]
		var lane := -0.45 if i % 2 == 0 else 0.45
		var start := _doorstep(lane)
		var foot := _at(Vector3(lane, 0.12, RAMP_FOOT_Z + 0.4))
		var target := _at(Vector3((-1.0 if i % 2 == 0 else 1.0) * (2.8 + (i % 5) * 1.15), 0.12, 5.8 + (i / 5) * 1.1))
		var tw := create_tween()
		tw.tween_interval(1.0 + i * 0.35)
		tw.tween_callback(func() -> void:
			actor.position = start
			actor.rotation.y = 0.0
			actor.visible = true)
		_walk_segment(tw, actor, start, foot)
		_walk_segment(tw, actor, foot, target)
