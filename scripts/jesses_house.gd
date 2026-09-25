extends Node3D
## Jesse's home in Bethlehem, for Chapter 3, The Beginning (1 Samuel 16): a warm morning
## courtyard on a low hillside, with the house wall and shaded doorway along the back, the
## welcome table under an olive tree, and the sheep fold and path on the bright open edge.
## It is its own scene (scenes/chapters/jesses_house.tscn): the shell loads it when the
## story starts and frees it when another one does, and it stands at the world's origin
## with nothing else loaded, like the ark. Built in code from paper parts, the way the
## camp and the ark are (camp_paper.gd), so there is no environment model to load.
##
## Layout, looking the way the tabletop camera looks (towards -z):
## the house along the back, the table and olive tree right of centre, the fold and the
## sheep path at the front right, and the arrival spot at the front, in the open.

const Paper := preload("res://scripts/camp_paper.gd")
const PlayArea := preload("res://scripts/play_area.gd")
const ChapterThree := preload("res://scripts/chapter_three.gd")

## The Wonder-Walker arrives here, at the open front edge.
const ARRIVE := Vector3(0.0, 0.25, 7.0)
const GROUND := Vector2(26.0, 22.0)
const EARTH := Color(0.74, 0.6, 0.42)
const PATH := Color(0.66, 0.46, 0.34)
const LIMESTONE := Color(0.84, 0.76, 0.6)
const CLAY := Color(0.7, 0.44, 0.34)
const WOOD := Color(0.39, 0.25, 0.13)
const OLIVE := Color(0.46, 0.55, 0.33)
const HILLS := Color(0.78, 0.66, 0.48)

## The warm morning the story starts in (chapter_look.gd); the shell applies it.
@export var look: Resource = preload("res://assets/looks/bethlehem_morning.tres")
## Where the walker can go: the courtyard, the fold and the start of the sheep path.
@export var play_area: Resource = PlayArea.new(Vector2(0.0, 0.5), Vector2(11.0, 9.0))

var _built: bool = false


## Builds the courtyard and starts the story, or carries on with it. Only the shell calls
## this (game_shell.gd switch_to), after every other story has stood down.
func visit() -> void:
	_build()
	if in_progress():
		return
	var main := get_parent()
	var player := main.get_node_or_null("Player") as CharacterBody3D
	if player:
		player.velocity = Vector3.ZERO
		player.global_position = ARRIVE
		_snap_followers(player)
	var story := get_node_or_null("ChapterThree")
	if story and story.has_method("begin"):
		story.begin()


## True while the story is under way; the shell then carries on instead of starting it.
func in_progress() -> bool:
	var story := get_node_or_null("ChapterThree")
	return story != null and story.phase != ChapterThree.Phase.IDLE and story.phase != ChapterThree.Phase.DONE


## Another story is starting: this one stops listening, and the shell frees the courtyard next.
func stand_down() -> void:
	var story := get_node_or_null("ChapterThree")
	if story and story.has_method("stand_down"):
		story.stand_down()


func _snap_followers(player: Node3D) -> void:
	var main := get_parent()
	var cam := main.get_node_or_null("TabletopCamera") as Camera3D
	if cam and "offset" in cam:
		cam.global_position = player.global_position + cam.offset
		cam.look_at(player.global_position + Vector3(0.0, cam.get("look_height"), 0.0), Vector3.UP)
	var light := main.get_node_or_null("WonderLight") as Node3D
	if light and "hover_offset" in light:
		light.global_position = player.global_position + light.hover_offset


func _build() -> void:
	if _built:
		return
	_built = true
	_ground()
	_hills()
	_house()
	_olive_tree()
	_table()
	_fold()
	_markers()
	var story := Node.new()
	story.name = "ChapterThree"
	story.set_script(ChapterThree)
	add_child(story)


func _ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "CourtyardGround"
	ground.position = Vector3(0.0, -0.3, 0.0)
	add_child(ground)
	Paper.part(ground, "Earth", Paper.box(Vector3(GROUND.x, 0.6, GROUND.y)), EARTH, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, 0.04)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(GROUND.x, 0.6, GROUND.y)
	collision.shape = shape
	ground.add_child(collision)
	# The worn sheep path, from the bright open edge to the courtyard: David comes home by it.
	Paper.part(self, "SheepPath", Paper.box(Vector3(3.1, 0.05, 12.0)), PATH, Vector3(5.5, 0.025, 4.6),
			Vector3(0.0, -0.35, 0.0), Vector3.ONE, 0.015)


## Low hills all round, soft in the haze, so the courtyard sits on a hillside above Bethlehem
## rather than on a board in empty sky.
func _hills() -> void:
	# The hillside the courtyard is cut into: wide, a little lower, the colour of the far hills,
	# so the courtyard's edge is a step down onto open ground and never a board over nothing.
	Paper.part(self, "Hillside", Paper.cylinder(60.0, 0.4, 24), HILLS.darkened(0.04), Vector3(0.0, -0.55, 0.0),
			Vector3.ZERO, Vector3.ONE, 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 316
	for i in 14:
		var angle := TAU * float(i) / 14.0 + rng.randf_range(-0.1, 0.1)
		var distance := rng.randf_range(34.0, 46.0)
		var at := Vector3(cos(angle) * distance, -2.0, sin(angle) * distance)
		var size := Vector3(rng.randf_range(14.0, 22.0), rng.randf_range(4.0, 7.5), rng.randf_range(10.0, 16.0))
		Paper.part(self, "Hill%d" % i, Paper.sphere(1.0, 10), HILLS.lightened(rng.randf_range(0.0, 0.12)), at,
				Vector3(0.0, angle, 0.0), size, 0.0)


func _house() -> void:
	var house := Node3D.new()
	house.name = "JessesHouse"
	house.position = Vector3(-4.0, 0.0, -6.0)
	add_child(house)
	Paper.part(house, "Wall", Paper.box(Vector3(10.0, 4.2, 0.55)), LIMESTONE, Vector3(0.0, 2.1, 0.0))
	Paper.part(house, "SideWall", Paper.box(Vector3(0.55, 4.2, 5.0)), LIMESTONE.darkened(0.06), Vector3(-4.8, 2.1, 2.2))
	Paper.part(house, "Doorway", Paper.box(Vector3(2.1, 3.1, 0.08)), Color(0.28, 0.2, 0.14), Vector3(1.6, 1.55, 0.3))
	Paper.part(house, "Awning", Paper.box(Vector3(5.4, 0.08, 2.2)), CLAY, Vector3(1.4, 3.35, 1.2), Vector3(0.12, 0.0, 0.0))
	for x in [-1.1, 3.9]:
		Paper.part(house, "AwningPole", Paper.cylinder(0.06, 3.3, 6), WOOD, Vector3(x, 1.65, 2.2))
	var wall := StaticBody3D.new()
	wall.name = "WallBody"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10.0, 4.2, 0.8)
	shape.shape = box
	shape.position = Vector3(0.0, 2.1, 0.0)
	wall.add_child(shape)
	house.add_child(wall)


func _olive_tree() -> void:
	var tree := Node3D.new()
	tree.name = "OliveTree"
	tree.position = Vector3(6.4, 0.0, -3.4)
	add_child(tree)
	Paper.part(tree, "Trunk", Paper.cylinder(0.35, 3.8, 7, 0.26), WOOD, Vector3(0.0, 1.9, 0.0))
	for i in 7:
		var angle := TAU * float(i) / 7.0
		Paper.part(tree, "Leaves%d" % i, Paper.sphere(0.9, 7), OLIVE.lightened(0.08 * float(i % 2)),
				Vector3(cos(angle) * 1.2, 3.7 + 0.18 * float(i % 3), sin(angle) * 1.05), Vector3.ZERO, Vector3(1.35, 0.7, 0.9))


## The welcome table under the olive tree. Its three places (cushion, cup, lamp) are marked
## later by the Prepare the Welcome rings.
func _table() -> void:
	var table := Node3D.new()
	table.name = "WelcomeTable"
	table.position = Vector3(3.4, 0.0, -1.2)
	add_child(table)
	Paper.part(table, "Top", Paper.box(Vector3(3.4, 0.18, 1.55)), WOOD.lightened(0.1), Vector3(0.0, 0.8, 0.0))
	for x in [-1.35, 1.35]:
		for z in [-0.52, 0.52]:
			Paper.part(table, "Leg", Paper.cylinder(0.08, 0.8, 6), WOOD, Vector3(x, 0.4, z))


func _fold() -> void:
	var fold := Node3D.new()
	fold.name = "SheepFold"
	fold.position = Vector3(7.6, 0.0, 4.4)
	add_child(fold)
	for x in [-2.4, 0.0, 2.4]:
		Paper.part(fold, "FencePost", Paper.cylinder(0.09, 1.2, 6), WOOD, Vector3(x, 0.6, 0.0))
	for y in [0.38, 0.84]:
		Paper.part(fold, "FenceRail", Paper.cylinder(0.055, 4.9, 6), WOOD, Vector3(0.0, y, 0.0), Vector3(0.0, 0.0, PI * 0.5))


## Where the story's people and moments stand, so staging is tuned here, not in the story.
func _markers() -> void:
	var markers := {
		"SamuelArrival": Vector3(-3.0, 0.0, 2.6), "Jesse": Vector3(-0.6, 0.0, -2.8),
		"BrotherLine": Vector3(-8.0, 0.0, -1.0), "DavidEntrance": Vector3(8.2, 0.0, 8.0),
		"Anointing": Vector3(0.8, 0.0, 0.6),
	}
	for marker_name in markers:
		var marker := Marker3D.new()
		marker.name = marker_name
		marker.position = markers[marker_name]
		add_child(marker)
