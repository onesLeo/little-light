extends Node3D
## Jesse's home in Bethlehem, for Chapter 3, The Beginning (1 Samuel 16): a warm morning
## courtyard on a low hillside, with the house wall and shaded doorway along the back, the
## welcome table under an olive tree, and the sheep fold and path on the bright open edge.
## It is its own scene (scenes/chapters/jesses_house.tscn): the shell loads it when the
## story starts and frees it when another one does, and it stands at the world's origin
## with nothing else loaded, like the ark. Built in code from paper parts, the way the
## camp and the ark are (camp_paper.gd), so there is no environment model to load.
##
## Who is here: Samuel (with his staff; the oil horn only for the anointing), Jesse, his
## seven older sons in a line along the left side (jesse_sons.gd), and David, out on the
## sheep path until he is called home. Samuel, Jesse and David are the Blender models
## (story_person.gd); the brothers are light paper people.
##
## What the child does here: optional finds (David's harp, the sheep's water bowl, his
## cloak), and Prepare the Welcome: carry the cushion, the cup and the lamp, one at a time,
## to their rings in front of the table. The story (chapter_three.gd) says when.
##
## Layout, looking the way the tabletop camera looks (towards -z): the house along the back,
## the table and olive tree right of centre, the brothers in a row in front of the house, the
## fold and the sheep path at the front right, and the arrival spot at the front, in the open.
## A low field-stone wall frames it; the small moving things (cloud shadows, breeze, doves) are
## in courtyard_life.gd.

const Paper := preload("res://scripts/camp_paper.gd")
const PlayArea := preload("res://scripts/play_area.gd")
const ChapterThree := preload("res://scripts/chapter_three.gd")
const StoryPerson := preload("res://scripts/story_person.gd")
const JesseSons := preload("res://scripts/jesse_sons.gd")
const CourtyardLife := preload("res://scripts/courtyard_life.gd")

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
const WOOL := Color(0.92, 0.88, 0.8)
const GOLD := Color(0.98, 0.8, 0.36)

const TABLE := Vector3(3.4, 0.0, -1.2)
## Where each welcome thing waits, where its ring is (in front of the table, where the child
## walks), and where it sits on the table once placed.
const WELCOME := {
	"Cushion": {"at": Vector3(-7.6, 0.0, 2.2), "ring": Vector3(2.1, 0.0, 0.2), "on": Vector3(2.3, 0.94, -1.2)},
	"Cup": {"at": Vector3(8.6, 0.0, -1.4), "ring": Vector3(3.4, 0.0, 0.3), "on": Vector3(3.4, 0.96, -1.2)},
	"Lamp": {"at": Vector3(-5.4, 0.0, 4.2), "ring": Vector3(4.7, 0.0, 0.2), "on": Vector3(4.5, 0.9, -1.2)},
}
const RING_RADIUS := 0.62
## Carrying something, the walker only has to come this near the table (anywhere round its top,
## measured from the edge) for the thing to go onto its own place there. Finding the exact ring
## was too fiddly for small hands; the rings still show where each thing will sit.
const TABLE_REACH := 1.05
const TABLE_TOP := Vector2(3.4, 1.55)
## How near the walker must come to pick up a welcome thing or notice one of David's things.
const PICK_REACH := 1.1
const FIND_REACH := 1.3
## David's things, which Wonder Light comments on if the child finds them. Not a checklist.
const FINDS := {
	"Harp": Vector3(-4.4, 0.0, 1.4),
	"WaterBowl": Vector3(6.4, 0.0, 3.2),
	"Cloak": Vector3(0.8, 0.0, 4.6),
}
## Where the people stand. Samuel starts at the courtyard's edge and comes to the table.
const SAMUEL_START := Vector3(-3.2, 0.0, 2.8)
const SAMUEL_PLACE := Vector3(-0.9, 0.0, 0.3)
const JESSE_PLACE := Vector3(-1.5, 0.0, -1.9)
## David waits out on the sheep path, beyond the courtyard, and walks in when called.
const DAVID_AWAY := Vector3(8.3, 0.0, 13.5)
const DAVID_PLACE := Vector3(0.5, 0.0, 0.9)
## The brothers stand in a row across the back, in front of the house wall and clear of its
## side wall, and step out towards Samuel one by one.
const BROTHERS_START := Vector3(-7.9, 0.0, -3.6)
const BROTHERS_ALONG := Vector3(0.95, 0.0, 0.0)
## At the anointing Samuel stands this close in front of the kneeling David, and this far to
## the left, so the horn in his raised right hand is over David's head.
## The horn's mouth, in the forearm bone's units (just past the hand), and how long the horn is.
## ANOINT_GAP and ANOINT_SIDE are measured from it (beginning_review.gd prints the offset).
const HORN_MOUTH := Vector3(0.0, 0.24, 0.02)
const HORN_LENGTH := 0.26
const ANOINT_GAP := 0.4
const ANOINT_SIDE := 0.27
## How far Samuel steps back once the oil is poured.
const STEP_BACK := 0.85
## A still view of the whole row and Samuel for the procession: from the front, a little aside.
## How far from Jesse and Samuel the welcome shot stands.
const MEET_DISTANCE := 4.6
const PROCESSION_EYE := Vector3(-2.6, 2.8, 6.0)
const PROCESSION_LOOK := Vector3(-3.7, 0.9, -2.2)

## The warm morning the story starts in (chapter_look.gd); the shell applies it.
@export var look: Resource = preload("res://assets/looks/bethlehem_morning.tres")
## Where the walker can go: the courtyard, the fold and the start of the sheep path.
@export var play_area: Resource = PlayArea.new(Vector2(0.0, 0.5), Vector2(11.0, 9.0))

var _built: bool = false
var _time: float = 0.0
var _samuel: Node3D
var _jesse: Node3D
var _david: Node3D
var _sons: Node3D
var _horn: Node3D
var _oil: MeshInstance3D
var _awning: Node3D
var _leaves: Array[Node3D] = []
var _sheep: Array[Node3D] = []
var _rings: Dictionary = {}
var _welcome: Dictionary = {}
var _finds: Dictionary = {}
var _placed: Array = []
var _found: Array = []
var _carrying: String = ""
var _breeze: float = 0.0
var _life: Node3D
## True from David kneeling to Samuel stepping back: nobody turns to watch anyone then, so the
## horn stays over David's head.
var _anointing: bool = false


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
	set_child_watch(null)
	var story := get_node_or_null("ChapterThree")
	if story and story.has_method("stand_down"):
		story.stand_down()


# ---- what the story asks of the courtyard ---------------------------------------------------

func samuel() -> Node3D:
	return _samuel


func jesse() -> Node3D:
	return _jesse


func david() -> Node3D:
	return _david


func sons() -> Node3D:
	return _sons


func carrying() -> String:
	return _carrying


func placed() -> Array:
	return _placed.duplicate()


func found_things() -> Array:
	return _found.duplicate()


## The Area3D spots the golden arrow can point at (wonder_item_hints.gd): the welcome
## things still to pick up, or the ring for the one being carried.
func welcome_spots() -> Array:
	if not _carrying.is_empty():
		return [_rings[_carrying]]
	var out: Array = []
	for thing in WELCOME:
		if not _placed.has(thing):
			out.append(_welcome[thing])
	return out


## Sets the courtyard as it stands at a story beat the child is carrying on from
## (chapter_three.gd _resume): the welcome things already on the table (all of them after
## "welcome"), Samuel at the table from "meet" on, and David home from "david" on.
func set_scene_for(beat: String, placed: Array) -> void:
	for thing in WELCOME:
		if beat != "welcome" or placed.has(thing):
			_set_on_table(thing)
	if beat in ["meet", "not_these", "call", "david", "reflect"]:
		_samuel.global_position = SAMUEL_PLACE
		face(_samuel, JESSE_PLACE)
		face(_jesse, SAMUEL_PLACE)
	if beat in ["david", "reflect"]:
		_david.visible = true
		_david.global_position = DAVID_PLACE
		face(_david, SAMUEL_PLACE)
		face(_samuel, DAVID_PLACE)


## A welcome thing already on the table, at once (no tween, no sound).
func _set_on_table(thing: String) -> void:
	if not _placed.has(thing):
		_placed.append(thing)
	var node := _welcome[thing] as Node3D
	node.visible = true
	node.global_position = WELCOME[thing]["on"]
	node.rotation = Vector3.ZERO
	(_rings[thing] as Node3D).visible = false


## Shows the welcome things and their rings, so the child can start carrying.
func open_welcome() -> void:
	for thing in WELCOME:
		(_welcome[thing] as Node3D).visible = not _placed.has(thing)
		(_rings[thing] as Node3D).visible = not _placed.has(thing)


## Picks up the welcome thing `thing` (the walker has reached it). It then floats beside
## Wonder Light until it reaches its ring. Returns false while another is being carried.
func pick_up(thing: String) -> bool:
	if not _carrying.is_empty() or _placed.has(thing):
		return false
	_carrying = thing
	_fade_rings()
	return true


## While something is carried, the other rings fade back so its own ring stands out.
func _fade_rings() -> void:
	for thing in _rings:
		var faded: bool = not _carrying.is_empty() and thing != _carrying
		for part in (_rings[thing] as Node3D).find_children("*", "GeometryInstance3D", true, false):
			(part as GeometryInstance3D).transparency = 0.7 if faded else 0.0


## Sets the carried thing on the table over about 0.6 s. Returns the thing placed.
func place_carried() -> String:
	var thing := _carrying
	if thing.is_empty():
		return ""
	_carrying = ""
	_placed.append(thing)
	_fade_rings()
	var node := _welcome[thing] as Node3D
	var tw := create_tween().set_parallel(true)
	tw.tween_property(node, "global_position", WELCOME[thing]["on"], 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "rotation", Vector3.ZERO, 0.6)
	(_rings[thing] as Node3D).visible = false
	return thing


## The welcome thing within reach of `at` that can be picked up now, or "".
func welcome_within_reach(at: Vector3) -> String:
	if not _carrying.is_empty():
		return ""
	for thing in WELCOME:
		if _placed.has(thing) or not (_welcome[thing] as Node3D).visible:
			continue
		if _flat_distance(at, (_welcome[thing] as Node3D).global_position) < PICK_REACH:
			return thing
	return ""


## True when `at` is near enough the table (or the carried thing's ring) to set it down.
func in_carried_ring(at: Vector3) -> bool:
	if _carrying.is_empty():
		return false
	if _flat_distance(at, WELCOME[_carrying]["ring"]) < RING_RADIUS + 0.4:
		return true
	var outside := Vector2(maxf(absf(at.x - TABLE.x) - TABLE_TOP.x * 0.5, 0.0), maxf(absf(at.z - TABLE.z) - TABLE_TOP.y * 0.5, 0.0))
	return outside.length() < TABLE_REACH


## One of David's things near `at` that has not been noticed yet, marked as noticed, or "".
func notice_find(at: Vector3) -> String:
	for thing in FINDS:
		if _found.has(thing) or _flat_distance(at, FINDS[thing]) > FIND_REACH:
			continue
		_found.append(thing)
		var glow := (_finds[thing] as Node3D).get_node_or_null("Glow") as Node3D
		if glow:
			glow.visible = false
		return thing
	return ""


## Turns person `who` to face a world point (the models face -Z).
func face(who: Node3D, point: Vector3) -> void:
	var to := point - who.global_position
	if Vector2(to.x, to.z).length() > 0.01:
		who.rotation.y = atan2(-to.x, -to.z)


## Walks `who` to `to` over `seconds`, legs moving, then faces `then_face`.
func walk(who: Node3D, to: Vector3, seconds: float, then_face: Vector3) -> Tween:
	face(who, to)
	who.set("walk_amount", 1.0)
	var tw := create_tween()
	tw.tween_property(who, "global_position", to, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		who.set("walk_amount", 0.0)
		face(who, then_face))
	return tw


## Samuel comes from the courtyard's edge to the table, and he and Jesse face each other.
func samuel_to_table() -> Tween:
	face(_jesse, SAMUEL_PLACE)
	return walk(_samuel, SAMUEL_PLACE, 2.4, JESSE_PLACE)


## David walks home along the sheep path to stand before Samuel; it lasts `seconds`.
func david_comes_home(seconds: float = 4.2) -> Tween:
	_david.visible = true
	_david.global_position = DAVID_AWAY
	face(_samuel, DAVID_PLACE)
	return walk(_david, DAVID_PLACE, seconds, SAMUEL_PLACE)


## Holds the camera still on the brothers' row and Samuel while the brothers pass (the
## story cuts back with the camera director afterwards).
func procession_shot() -> void:
	_still_shot(PROCESSION_EYE, PROCESSION_LOOK)


## Jesse welcoming Samuel, seen from the house side of the two: the table and the welcome
## things are behind them in the frame rather than filling its front.
func meet_shot() -> void:
	var mid := (_jesse.global_position + _samuel.global_position) * 0.5
	var across := _samuel.global_position - _jesse.global_position
	across.y = 0.0
	var side := across.normalized().cross(Vector3.UP)
	# The side away from the table.
	if side.dot(TABLE - mid) > 0.0:
		side = -side
	_still_shot(mid + side * MEET_DISTANCE + Vector3(0.0, 1.35, 0.0), mid + Vector3(0.0, 0.95, 0.0))


## Holds the courtyard's own still camera at `eye`, looking at `look`, until the story cuts
## back with the camera director.
func _still_shot(eye: Vector3, look: Vector3) -> void:
	var cam := get_node_or_null("StillCamera") as Camera3D
	if cam == null:
		cam = Camera3D.new()
		cam.name = "StillCamera"
		cam.fov = 42.0
		add_child(cam)
	cam.look_at_from_position(eye, look, Vector3.UP)
	cam.current = true


## Who speaks now, for the talking faces: "Samuel", "Jesse", "David" or "". The one speaking
## turns to the one they talk to, and the others turn to the speaker. Wonder Light's lines leave
## everyone looking where they were.
func set_speaking(speaker: String) -> void:
	for pair in [[_samuel, "Samuel"], [_jesse, "Jesse"], [_david, "David"]]:
		if pair[0]:
			pair[0].speaking = speaker == pair[1]
	var speaking: Node3D = {"Samuel": _samuel, "Jesse": _jesse, "David": _david}.get(speaker)
	# The child looks at whoever is talking too, even during the pour.
	if speaking:
		set_child_watch(speaking)
	if _anointing:
		return
	var david_here := _david.visible and _flat_distance(_david.global_position, _samuel.global_position) < 3.0
	match speaker:
		"Samuel":
			_samuel.watch = _david if david_here else _jesse
			_jesse.watch = _samuel
			if david_here:
				_david.watch = _samuel
		"Jesse":
			_jesse.watch = _samuel
			_samuel.watch = _jesse
			if david_here:
				_david.watch = _jesse
		"David":
			_david.watch = _samuel
			_samuel.watch = _david
			_jesse.watch = _david


## Who the Wonder-Walker turns to look at while standing (null: the way it last walked).
func set_child_watch(target: Node3D) -> void:
	var player := get_parent().get_node_or_null("Player") if get_parent() else null
	if player and "watch" in player:
		player.watch = target


## Samuel, Jesse and David all turn to look at the child (for the reflection and the charm).
func watch_child(child: Node3D) -> void:
	if _anointing:
		return
	for person in [_samuel, _jesse, _david]:
		if person.visible:
			person.watch = child


## While the brothers pass, Samuel looks along their row, and Jesse watches his sons with him.
func watch_brothers() -> void:
	var middle: Node3D = _sons.brothers()[3]
	_samuel.watch = middle
	_jesse.watch = middle
	set_child_watch(middle)


## David kneels and Samuel steps up close to him; Samuel lifts the horn over David's head and a
## thin line of oil runs down onto it, over about two seconds, while a warm breeze lifts the
## awning and the olive leaves. Then Samuel lowers the horn and David stands. No glow, no crown.
func anoint(seconds: float = 2.0) -> Tween:
	_anointing = true
	_samuel.watch = null
	_david.watch = null
	face(_david, _samuel.global_position)
	var to_samuel := _samuel.global_position - _david.global_position
	to_samuel.y = 0.0
	var ahead := -to_samuel.normalized()
	var right := ahead.cross(Vector3.UP)
	var close := _david.global_position - ahead * ANOINT_GAP - right * ANOINT_SIDE
	face(_samuel, close)
	_samuel.walk_amount = 1.0
	var tw := create_tween()
	tw.tween_property(_david, "kneel", 1.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(_samuel, "global_position", close, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		_samuel.walk_amount = 0.0
		face(_samuel, close + ahead)
		_horn.visible = true)
	tw.tween_property(_samuel, "reach", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void: _oil.visible = true)
	tw.tween_method(_pour, 0.0, 1.0, seconds).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(self, "_breeze", 1.0, seconds * 0.5)
	tw.tween_property(self, "_breeze", 0.0, 1.2)
	tw.tween_callback(func() -> void: _oil.visible = false)
	tw.tween_property(_samuel, "reach", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void: _horn.visible = false)
	tw.tween_property(_david, "kneel", 0.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Samuel steps back from David, still facing him, so there is room between them again.
	tw.tween_callback(func() -> void: _samuel.walk_amount = 0.5)
	tw.tween_property(_samuel, "global_position", close - ahead * STEP_BACK, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		_samuel.walk_amount = 0.0
		_anointing = false
		_samuel.watch = _david
		_david.watch = _samuel)
	return tw


func life() -> Node3D:
	return _life


func oil_shown() -> bool:
	return _oil != null and _oil.visible


func _pour(amount: float) -> void:
	# The line of oil runs from the horn's lip down onto the top of the kneeling David's head.
	var from := (_horn.get_node("Horn") as Node3D).global_position + Vector3(0.0, -0.04, 0.0)
	var to: Vector3 = _david.head_top()
	var end := from.lerp(to, amount)
	_oil.global_position = (from + end) * 0.5
	_oil.scale = Vector3(1.0, maxf(from.distance_to(end), 0.001), 1.0)
	var down := (end - from).normalized() if from.distance_to(end) > 0.001 else Vector3.DOWN
	_oil.global_basis = Basis(Quaternion(Vector3.UP, -down)) * Basis.from_scale(_oil.scale)
	(_oil.material_override as StandardMaterial3D).albedo_color.a = lerpf(0.4, 0.95, amount)


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _process(delta: float) -> void:
	if not _built:
		return
	_time += delta
	# The carried thing floats beside Wonder Light, bobbing a little.
	if not _carrying.is_empty():
		var light := get_parent().get_node_or_null("WonderLight") as Node3D
		var node := _welcome[_carrying] as Node3D
		if light:
			var want := light.global_position + Vector3(0.45, -0.25 + sin(_time * 3.0) * 0.05, 0.0)
			node.global_position = node.global_position.lerp(want, minf(1.0, delta * 8.0))
			node.rotation.y += delta * 0.8
	# The empty rings breathe, the one for the carried thing most; the others fade back while
	# something is carried, so the one it goes to stands out.
	for thing in _rings:
		var ring := _rings[thing] as Node3D
		if ring.visible:
			var strong := 1.0 if thing == _carrying else 0.45
			ring.scale = Vector3.ONE * (1.0 + sin(_time * 2.6) * 0.06 * strong) * (1.15 if thing == _carrying else 1.0)
			ring.position.y = 0.04
	for thing in _finds:
		var glow := (_finds[thing] as Node3D).get_node_or_null("Glow") as Node3D
		if glow and glow.visible:
			glow.scale = Vector3.ONE * (1.0 + sin(_time * 2.0 + float(thing.length())) * 0.12)
	for i in _sheep.size():
		var sheep := _sheep[i]
		sheep.rotation.y = sin(_time * 0.3 + i * 2.0) * 0.4 + i
		sheep.get_child(0).position.y = 0.42 + sin(_time * 1.6 + i) * 0.01
	# The breeze at the anointing, and a faint one always.
	var sway := 0.02 + _breeze * 0.18
	if _life:
		_life.breeze = _breeze
	if _awning:
		_awning.rotation.x = 0.12 + sin(_time * 2.2) * sway * 0.6
	for i in _leaves.size():
		_leaves[i].rotation.z = sin(_time * 1.7 + i) * sway


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
	_yard()
	_welcome_things()
	_david_things()
	_people()
	_markers()
	_life = CourtyardLife.new()
	_life.name = "CourtyardLife"
	add_child(_life)
	var story := Node.new()
	story.name = "ChapterThree"
	story.set_script(ChapterThree)
	add_child(story)


func _ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "CourtyardGround"
	ground.position = Vector3(0.0, -0.3, 0.0)
	add_child(ground)
	var earth := Paper.part(ground, "Earth", Paper.box(Vector3(GROUND.x, 0.6, GROUND.y)), EARTH, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, 0.04)
	earth.material_override = _earth_material()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(GROUND.x, 0.6, GROUND.y)
	collision.shape = shape
	ground.add_child(collision)
	# The worn sheep path, from the bright open edge to the courtyard: David comes home by it.
	_sheep_path()
	_footpath()
	_patio()
	# Pebbles and dry tufts over the open ground, and grass thick along the foot of the walls.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1616
	var pebbles: Array[Transform3D] = []
	var pebble_tints: Array[Color] = []
	var tufts: Array[Transform3D] = []
	for i in 70:
		var at := Vector3(rng.randf_range(-12.0, 12.0), 0.0, rng.randf_range(-10.0, 10.5))
		if not _clear_of_busy(at, 1.3) or Vector2(at.x - TABLE.x, at.z - TABLE.z).length() < 2.4:
			continue
		if i % 2 == 0:
			var size := rng.randf_range(0.6, 1.3)
			pebbles.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(1.4, 0.55, 1.0) * size), at + Vector3(0.0, 0.03, 0.0)))
			pebble_tints.append(LIMESTONE.darkened(rng.randf_range(0.06, 0.22)))
		else:
			_tuft(tufts, rng, at)
	for i in 90:
		# Along the inside of the low wall (x = +-12.3, z = -9) and the house's foot.
		var side := i % 4
		var at := Vector3(-11.8, 0.0, rng.randf_range(-8.6, 9.5))
		if side == 1:
			at = Vector3(11.8, 0.0, rng.randf_range(-8.6, 1.8))
		elif side == 2:
			at = Vector3(rng.randf_range(-11.8, 11.8), 0.0, -8.5)
		elif side == 3:
			at = Vector3(rng.randf_range(1.4, 11.0), 0.0, rng.randf_range(-8.6, -7.2))
		_tuft(tufts, rng, at + Vector3(rng.randf_range(-0.3, 0.3), 0.0, rng.randf_range(-0.3, 0.3)))
	var pebble_tint_array: Array = pebble_tints
	_scatter("Pebbles", Paper.sphere(0.16, 6), pebbles, pebble_tint_array)
	_scatter("Tufts", Paper.cylinder(0.02, 0.3, 4, 0.0), tufts, [OLIVE.lightened(0.15), OLIVE, OLIVE.lightened(0.3)])


## True when `at` is at least `margin` from every spot where someone stands or something waits
## (the arrival, the table, the people, the welcome things and rings, David's things, the doves).
func _clear_of_busy(at: Vector3, margin: float) -> bool:
	var busy: Array[Vector3] = [ARRIVE, TABLE, SAMUEL_START, SAMUEL_PLACE, JESSE_PLACE, DAVID_PLACE]
	for thing in WELCOME:
		busy.append(WELCOME[thing]["at"])
		busy.append(WELCOME[thing]["ring"])
	for thing in FINDS:
		busy.append(FINDS[thing])
	busy.append_array(CourtyardLife.DOVE_SPOTS)
	for spot in busy:
		if Vector2(at.x - spot.x, at.z - spot.z).length() < margin:
			return false
	return true


## A few blades of dry grass leaning out from `at`.
func _tuft(into: Array[Transform3D], rng: RandomNumberGenerator, at: Vector3) -> void:
	var turn := rng.randf() * TAU
	for k in 3:
		var lean := Basis(Vector3.UP, turn) * Basis(Vector3.BACK, (k - 1) * 0.4)
		into.append(Transform3D(lean.scaled(Vector3.ONE * rng.randf_range(0.8, 1.3)), at + Vector3(0.0, 0.14, 0.0)))


## Many copies of one small mesh in one draw call (pebbles, tufts, flowers), each with its
## own colour from `tints`. Flat colour like the paper parts; too small to need an ink rim.
func _scatter(scatter_name: String, mesh: Mesh, where: Array[Transform3D], tints: Array) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = where.size()
	for i in where.size():
		mm.set_instance_transform(i, where[i])
		mm.set_instance_color(i, tints[i % tints.size()])
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	# The tints are the same sRGB colours the paper parts use, not linear values.
	mat.vertex_color_is_srgb = true
	mat.roughness = 1.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	var mmi := MultiMeshInstance3D.new()
	mmi.name = scatter_name
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	return mmi


## Packed earth in a few close tones laid in soft patches, so the ground reads as ground and
## not one flat sheet of colour. Mapped from above in world space, so it lies the same way
## however the box is cut.
func _earth_material() -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	noise.cellular_jitter = 0.9
	noise.frequency = 0.05
	noise.seed = 1616
	var tones := Gradient.new()
	tones.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	tones.offsets = PackedFloat32Array([0.0, 0.3, 0.55, 0.8])
	tones.colors = PackedColorArray([EARTH.darkened(0.06), EARTH, EARTH.lightened(0.05), EARTH.darkened(0.03)])
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	texture.noise = noise
	texture.color_ramp = tones
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.roughness = 1.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE / 14.0
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return mat


## The sheep path David comes home by, from the bright open edge to the courtyard: a
## winding trail of trodden, slightly darker earth, wider than the footpath.
func _sheep_path() -> void:
	var from := DAVID_AWAY + Vector3(-0.8, 0.0, -3.0)
	var to := Vector3(3.2, 0.0, -0.9)
	var patches: Array[Transform3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 1617
	for i in 16:
		var t := float(i) / 15.0
		var at := from.lerp(to, t) + Vector3(sin(t * PI * 2.0) * 0.6, 0.014, 0.0)
		var size := Vector3(rng.randf_range(1.6, 2.1), 1.0, rng.randf_range(1.2, 1.5))
		patches.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(size), at))
	var trodden := EARTH.darkened(0.1).lerp(PATH, 0.25)
	_scatter("SheepPath", Paper.cylinder(0.6, 0.02, 9), patches, [trodden, trodden.lightened(0.03)])


## The footpath worn from the courtyard's open front to the welcome table: a chain of flat,
## lighter patches of trodden earth.
func _footpath() -> void:
	var from := ARRIVE + Vector3(0.0, 0.0, 2.2)
	var to := TABLE + Vector3(-0.6, 0.0, 1.9)
	var steps: Array[Transform3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 1604
	for i in 11:
		var t := float(i) / 10.0
		var at := from.lerp(to, t) + Vector3(sin(t * PI * 1.6) * 0.5, 0.012, 0.0)
		var size := Vector3(rng.randf_range(1.2, 1.6), 1.0, rng.randf_range(0.9, 1.2))
		steps.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(size), at))
	_scatter("Footpath", Paper.cylinder(0.6, 0.02, 9), steps, [EARTH.lerp(LIMESTONE, 0.35), EARTH.lerp(LIMESTONE, 0.28)])


## Flagstones in front of the house, under and around the awning, where the family sits: flat
## many-sided stones in a loose grid, each a slightly different limestone.
func _patio() -> void:
	var stones: Array[Transform3D] = []
	var tints: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 1610
	var x := -8.1
	while x < 1.0:
		var z := -5.5
		while z < -2.7:
			var at := Vector3(x + rng.randf_range(-0.08, 0.08), 0.015, z + rng.randf_range(-0.08, 0.08))
			var size := Vector3(rng.randf_range(0.9, 1.1), 1.0, rng.randf_range(0.85, 1.05))
			stones.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(size), at))
			tints.append(LIMESTONE.lightened(rng.randf_range(0.02, 0.12)))
			z += 0.78
		x += 0.8
	_scatter("Flagstones", Paper.cylinder(0.37, 0.03, 6), stones, tints)


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
	_awning = Node3D.new()
	_awning.name = "Awning"
	_awning.position = Vector3(1.4, 3.35, 0.2)
	house.add_child(_awning)
	Paper.part(_awning, "Cloth", Paper.box(Vector3(5.4, 0.08, 2.2)), CLAY, Vector3(0.0, 0.0, 1.0))
	for x in [-1.1, 3.9]:
		Paper.part(house, "AwningPole", Paper.cylinder(0.06, 3.3, 6), WOOD, Vector3(x, 1.65, 2.2))
	_solid(house, "WallBody", Vector3(10.0, 4.2, 0.8), Vector3(0.0, 2.1, 0.0))
	_solid(house, "SideWallBody", Vector3(0.8, 4.2, 5.2), Vector3(-4.8, 2.1, 2.2))


## A still, invisible body the walker bumps into instead of walking through.
func _solid(parent: Node3D, body_name: String, size: Vector3, at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = body_name
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	body.add_child(shape)
	parent.add_child(body)
	return body


func _olive_tree() -> void:
	var tree := Node3D.new()
	tree.name = "OliveTree"
	tree.position = Vector3(6.4, 0.0, -3.4)
	add_child(tree)
	Paper.part(tree, "Trunk", Paper.cylinder(0.35, 3.8, 7, 0.26), WOOD, Vector3(0.0, 1.9, 0.0))
	_solid(tree, "TrunkBody", Vector3(0.6, 2.0, 0.6), Vector3(0.0, 1.0, 0.0))
	for i in 7:
		var angle := TAU * float(i) / 7.0
		var holder := Node3D.new()
		holder.position = Vector3(cos(angle) * 1.2, 3.7 + 0.18 * float(i % 3), sin(angle) * 1.05)
		tree.add_child(holder)
		Paper.part(holder, "Leaves%d" % i, Paper.sphere(0.9, 7), OLIVE.lightened(0.08 * float(i % 2)),
				Vector3.ZERO, Vector3.ZERO, Vector3(1.35, 0.7, 0.9))
		_leaves.append(holder)


## The welcome table under the olive tree, with a stool for the guest.
func _table() -> void:
	var table := Node3D.new()
	table.name = "WelcomeTable"
	table.position = TABLE
	add_child(table)
	Paper.part(table, "Top", Paper.box(Vector3(3.4, 0.18, 1.55)), WOOD.lightened(0.1), Vector3(0.0, 0.8, 0.0))
	for x in [-1.35, 1.35]:
		for z in [-0.52, 0.52]:
			Paper.part(table, "Leg", Paper.cylinder(0.08, 0.8, 6), WOOD, Vector3(x, 0.4, z))
	_solid(table, "TableBody", Vector3(3.4, 0.9, 1.55), Vector3(0.0, 0.45, 0.0))


func _fold() -> void:
	var fold := Node3D.new()
	fold.name = "SheepFold"
	fold.position = Vector3(7.6, 0.0, 4.4)
	add_child(fold)
	for x in [-2.4, 0.0, 2.4]:
		Paper.part(fold, "FencePost", Paper.cylinder(0.09, 1.2, 6), WOOD, Vector3(x, 0.6, 0.0))
	for y in [0.38, 0.84]:
		Paper.part(fold, "FenceRail", Paper.cylinder(0.055, 4.9, 6), WOOD, Vector3(0.0, y, 0.0), Vector3(0.0, 0.0, PI * 0.5))
	_solid(fold, "FenceBody", Vector3(4.9, 1.2, 0.3), Vector3(0.0, 0.6, 0.0))
	# Two sheep behind the fence. They breathe and turn; nothing to collect.
	for i in 2:
		var sheep := Node3D.new()
		sheep.name = "FoldSheep%d" % i
		sheep.position = Vector3(8.9 + i * 1.1, 0.0, 6.2 - i * 0.9)
		add_child(sheep)
		var body := Node3D.new()
		sheep.add_child(body)
		Paper.part(body, "Wool", Paper.sphere(0.32, 8), WOOL, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 0.85, 1.35))
		Paper.part(body, "Head", Paper.sphere(0.13, 7), Color(0.3, 0.22, 0.16), Vector3(0.0, 0.08, -0.46), Vector3.ZERO, Vector3(0.85, 1.0, 1.2))
		for leg in [Vector3(-0.14, -0.3, -0.22), Vector3(0.14, -0.3, -0.22), Vector3(-0.14, -0.3, 0.22), Vector3(0.14, -0.3, 0.22)]:
			Paper.part(body, "Leg", Paper.cylinder(0.035, 0.3, 5), Color(0.3, 0.22, 0.16), leg)
		_sheep.append(sheep)


## A lived-in yard: water jars by the door, a woven mat and a basket of bread under the awning,
## firewood by the side wall, a low field-stone wall round the edge with bushes and a second
## tree beyond it, and wildflowers in the corners. Kept clear of the welcome things, David's
## things, the rings and the paths the people walk.
func _yard() -> void:
	var yard := Node3D.new()
	yard.name = "Yard"
	add_child(yard)
	for jar in [[Vector3(-0.7, 0.0, -5.2), 1.0], [Vector3(-0.15, 0.0, -5.0), 0.8], [Vector3(-1.25, 0.0, -4.95), 0.7]]:
		var s: float = jar[1]
		Paper.part(yard, "Jar", Paper.cylinder(0.24 * s, 0.62 * s, 9, 0.16 * s), CLAY, jar[0] + Vector3(0.0, 0.31 * s, 0.0))
		Paper.part(yard, "JarNeck", Paper.cylinder(0.1 * s, 0.14 * s, 8, 0.13 * s), CLAY.darkened(0.08), jar[0] + Vector3(0.0, 0.68 * s, 0.0))
	_solid(yard, "JarsBody", Vector3(1.5, 0.8, 0.7), Vector3(-0.7, 0.4, -5.05))
	Paper.part(yard, "Mat", Paper.box(Vector3(2.2, 0.02, 1.3)), Color(0.82, 0.62, 0.36), Vector3(-2.7, 0.042, -4.7), Vector3(0.0, 0.08, 0.0), Vector3.ONE, 0.0)
	for i in 4:
		Paper.part(yard, "MatStripe", Paper.box(Vector3(2.2, 0.022, 0.1)), Color(0.66, 0.34, 0.26),
				Vector3(-2.7, 0.044, -5.15 + i * 0.3), Vector3(0.0, 0.08, 0.0), Vector3.ONE, 0.0)
	Paper.part(yard, "Basket", Paper.cylinder(0.3, 0.2, 10, 0.34), Color(0.72, 0.56, 0.32), Vector3(-2.2, 0.1, -4.5))
	for i in 3:
		Paper.part(yard, "Bread", Paper.sphere(0.12, 7), Color(0.86, 0.66, 0.4), Vector3(-2.3 + i * 0.1, 0.22, -4.55 + (i % 2) * 0.1),
				Vector3.ZERO, Vector3(1.0, 0.5, 1.0), 0.0)
	for i in 5:
		Paper.part(yard, "Log", Paper.cylinder(0.09, 1.0, 6), WOOD.lightened(0.05 * (i % 2)),
				Vector3(-7.9 + (i % 3) * 0.2, 0.1 + (i / 3) * 0.17, -5.4 + (i % 3) * 0.19), Vector3(PI * 0.5, 0.0, 0.0), Vector3.ONE, 0.015)
	# The low wall of field stones round the yard, open at the front; outside the walker's play
	# area, so it only frames the courtyard.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1613
	var runs := [[Vector3(-12.3, 0.0, 9.5), Vector3(-12.3, 0.0, -9.0)], [Vector3(-12.3, 0.0, -9.0), Vector3(12.3, 0.0, -9.0)],
			[Vector3(12.3, 0.0, -9.0), Vector3(12.3, 0.0, 2.0)]]
	for run in runs:
		var a: Vector3 = run[0]
		var b: Vector3 = run[1]
		var count := int(a.distance_to(b) / 0.7)
		for i in count:
			var at := a.lerp(b, (float(i) + 0.5) / float(count))
			Paper.part(yard, "WallStone", Paper.box(Vector3(0.72, 0.5, 0.55)), LIMESTONE.darkened(rng.randf_range(0.04, 0.16)),
					at + Vector3(0.0, 0.22 + rng.randf_range(-0.04, 0.04), 0.0),
					Vector3(0.0, atan2(b.x - a.x, b.z - a.z) + PI * 0.5 + rng.randf_range(-0.12, 0.12), rng.randf_range(-0.06, 0.06)),
					Vector3.ONE, 0.015)
	for bush in [Vector3(-11.2, 0.0, -7.8), Vector3(-11.4, 0.0, 6.6), Vector3(11.1, 0.0, -7.6), Vector3(10.9, 0.0, -4.9), Vector3(-10.6, 0.0, 1.0)]:
		var s := rng.randf_range(0.8, 1.2)
		Paper.part(yard, "Bush", Paper.sphere(0.7, 7), OLIVE.darkened(rng.randf_range(0.0, 0.12)), bush + Vector3(0.0, 0.45 * s, 0.0),
				Vector3(0.0, rng.randf() * TAU, 0.0), Vector3(1.3, 0.85, 1.1) * s)
	var fig := Node3D.new()
	fig.name = "FigTree"
	fig.position = Vector3(-10.4, 0.0, -6.6)
	yard.add_child(fig)
	Paper.part(fig, "Trunk", Paper.cylinder(0.24, 2.6, 7, 0.18), WOOD, Vector3(0.0, 1.3, 0.0))
	for i in 5:
		var angle := TAU * float(i) / 5.0
		Paper.part(fig, "Leaves%d" % i, Paper.sphere(0.8, 7), OLIVE.darkened(0.05 + 0.05 * float(i % 2)),
				Vector3(cos(angle) * 0.8, 2.7 + 0.2 * float(i % 2), sin(angle) * 0.7), Vector3.ZERO, Vector3(1.2, 0.75, 1.0))
	# Wildflowers: little clusters of red anemones, yellow, white and purple, off the busy ground.
	var colours := [Color(0.86, 0.3, 0.3), Color(0.96, 0.84, 0.36), Color(0.97, 0.95, 0.9), Color(0.72, 0.5, 0.82)]
	var stems: Array[Transform3D] = []
	var blooms: Array[Transform3D] = []
	var bloom_tints: Array = []
	var placed := 0
	while placed < 26:
		var at := Vector3(rng.randf_range(-11.0, 11.5), 0.0, rng.randf_range(-8.2, 9.8))
		# Not on the sheep path, nor where the brothers stand and walk.
		var clear := absf(at.x - 5.5) > 1.9 or at.z < -1.6
		clear = clear and not (at.z < -2.4 and at.x > -9.2 and at.x < 1.4)
		clear = clear and _clear_of_busy(at, 1.6)
		if not clear:
			continue
		var colour: Color = colours[placed % colours.size()]
		for k in 4:
			var petal := at + Vector3(rng.randf_range(-0.22, 0.22), 0.0, rng.randf_range(-0.22, 0.22))
			stems.append(Transform3D(Basis.IDENTITY, petal + Vector3(0.0, 0.08, 0.0)))
			blooms.append(Transform3D(Basis.from_scale(Vector3(1.0, 0.6, 1.0)), petal + Vector3(0.0, 0.17, 0.0)))
			bloom_tints.append(colour)
		placed += 1
	_scatter("FlowerStems", Paper.cylinder(0.008, 0.16, 3), stems, [OLIVE])
	_scatter("Flowers", Paper.sphere(0.045, 5), blooms, bloom_tints)


## The cushion, the cup of water and the oil lamp for Samuel, each waiting somewhere in the
## courtyard, and the dashed ring in front of the table where each one goes. Hidden until the
## story asks for the welcome.
func _welcome_things() -> void:
	for thing in WELCOME:
		var node := Area3D.new()
		node.name = thing
		node.monitoring = false
		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = PICK_REACH
		shape.shape = sphere
		node.add_child(shape)
		add_child(node)
		node.global_position = WELCOME[thing]["at"] + Vector3(0.0, 0.3, 0.0)
		match thing:
			"Cushion":
				Paper.part(node, "Cushion", Paper.box(Vector3(0.7, 0.2, 0.55)), Color(0.62, 0.3, 0.3), Vector3.ZERO)
				Paper.part(node, "Band", Paper.box(Vector3(0.72, 0.06, 0.1)), Color(0.86, 0.68, 0.28), Vector3(0.0, 0.08, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
			"Cup":
				Paper.part(node, "Cup", Paper.cylinder(0.14, 0.28, 8, 0.17), Color(0.7, 0.46, 0.26), Vector3.ZERO)
				Paper.part(node, "Water", Paper.cylinder(0.15, 0.02, 8), Color(0.55, 0.72, 0.9), Vector3(0.0, 0.12, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
			"Lamp":
				Paper.part(node, "Dish", Paper.cylinder(0.24, 0.12, 8, 0.16), Color(0.74, 0.5, 0.26), Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 0.7))
				var flame := Paper.part(node, "Flame", Paper.flame(0.08, 0.2, 0.0), GOLD, Vector3(0.2, 0.12, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
				flame.material_override = Paper.glow_mat(GOLD)
		node.visible = false
		_welcome[thing] = node
		var ring := Area3D.new()
		ring.name = thing + "Ring"
		ring.monitoring = false
		var ring_shape := CollisionShape3D.new()
		var disc := SphereShape3D.new()
		disc.radius = RING_RADIUS
		ring_shape.shape = disc
		ring.add_child(ring_shape)
		add_child(ring)
		ring.global_position = WELCOME[thing]["ring"]
		# A dashed circle of small flat pieces, the "not yet" look of the checklist's circles.
		for k in 14:
			var a := TAU * float(k) / 14.0
			Paper.part(ring, "Dash%d" % k, Paper.box(Vector3(0.2, 0.02, 0.06)), GOLD,
					Vector3(cos(a) * RING_RADIUS, 0.0, sin(a) * RING_RADIUS), Vector3(0.0, -a + PI * 0.5, 0.0), Vector3.ONE, 0.0)
		ring.visible = false
		_rings[thing] = ring


## David's harp, the sheep's water bowl and his shepherd's cloak, each with a soft glow until noticed.
func _david_things() -> void:
	for thing in FINDS:
		var node := Node3D.new()
		node.name = thing
		add_child(node)
		node.global_position = FINDS[thing]
		match thing:
			"Harp":
				# A small five-string harp, leaning on a stone.
				var frame := Node3D.new()
				frame.position = Vector3(0.0, 0.32, 0.0)
				frame.rotation = Vector3(0.0, 0.4, -0.25)
				node.add_child(frame)
				Paper.part(frame, "Arm", Paper.box(Vector3(0.06, 0.6, 0.06)), WOOD, Vector3(-0.2, 0.0, 0.0))
				Paper.part(frame, "Top", Paper.box(Vector3(0.46, 0.06, 0.06)), WOOD, Vector3(0.0, 0.28, 0.0), Vector3(0.0, 0.0, -0.2))
				Paper.part(frame, "Base", Paper.box(Vector3(0.46, 0.08, 0.1)), WOOD.lightened(0.1), Vector3(0.0, -0.28, 0.0))
				for s in 5:
					Paper.part(frame, "String%d" % s, Paper.cylinder(0.006, 0.5, 4), Color(0.95, 0.9, 0.78),
							Vector3(-0.12 + s * 0.07, 0.0, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
				Paper.part(node, "Stone", Paper.sphere(0.2, 6), LIMESTONE.darkened(0.1), Vector3(0.2, 0.1, 0.1), Vector3.ZERO, Vector3(1.2, 0.6, 1.0))
			"WaterBowl":
				Paper.part(node, "Bowl", Paper.cylinder(0.36, 0.14, 10, 0.26), Color(0.7, 0.48, 0.3), Vector3(0.0, 0.07, 0.0))
				Paper.part(node, "Water", Paper.cylinder(0.33, 0.02, 10), Color(0.55, 0.72, 0.9), Vector3(0.0, 0.14, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
			"Cloak":
				Paper.part(node, "Cloak", Paper.box(Vector3(0.7, 0.14, 0.5)), Color(0.5, 0.42, 0.3), Vector3(0.0, 0.07, 0.0), Vector3(0.0, 0.3, 0.0))
				Paper.part(node, "Fold", Paper.box(Vector3(0.66, 0.06, 0.2)), Color(0.58, 0.49, 0.36), Vector3(0.0, 0.16, 0.08), Vector3(0.0, 0.3, 0.0))
		var glow := Paper.halo(1.0, Color(1.0, 0.86, 0.5, 0.5))
		glow.name = "Glow"
		glow.position = Vector3(0.0, 0.25, 0.0)
		node.add_child(glow)
		_finds[thing] = node


func _people() -> void:
	_samuel = _person("samuel", "Samuel", SAMUEL_START)
	_jesse = _person("jesse", "Jesse", JESSE_PLACE)
	_david = _person("young_david", "David", DAVID_AWAY)
	_david.visible = false
	face(_samuel, JESSE_PLACE)
	face(_jesse, SAMUEL_START)
	# Samuel's walking staff in his left hand; the small oil horn waits for the anointing.
	# The forearm bone runs from the elbow down to the wrist (+Y), in the model's own units (the
	# model is scaled up in story_person.gd): the staff stands from the ground to above his head.
	var staff := Node3D.new()
	staff.name = "Staff"
	Paper.part(staff, "Pole", Paper.cylinder(0.018, 1.15, 6), WOOD, Vector3(0.0, 0.06, 0.0), Vector3.ZERO, Vector3.ONE, 0.01)
	_samuel.attach("LowerArm_L", staff)
	_horn = _oil_horn()
	_samuel.attach("LowerArm_R", _horn)
	_horn.visible = false
	_oil = MeshInstance3D.new()
	_oil.name = "Oil"
	var ribbon := CylinderMesh.new()
	ribbon.top_radius = 0.012
	ribbon.bottom_radius = 0.008
	ribbon.height = 1.0
	ribbon.radial_segments = 6
	_oil.mesh = ribbon
	var oil_mat := StandardMaterial3D.new()
	oil_mat.albedo_color = Color(0.95, 0.76, 0.3, 0.9)
	oil_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	oil_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_oil.material_override = oil_mat
	_oil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_oil.visible = false
	add_child(_oil)
	_sons = JesseSons.new()
	_sons.name = "JesseSons"
	add_child(_sons)
	_sons.line_up(BROTHERS_START, BROTHERS_ALONG, 1.0, SAMUEL_PLACE)


## Samuel's horn of oil: a ram's horn, wide at the mouth and curving to a dark tip, held in his
## right hand (in the forearm bone's own units, +Y running from elbow to hand). The mouth sits
## just past his fingers, the horn runs back through his grip and curls up behind it. "Horn"
## marks the mouth the oil runs from.
func _oil_horn() -> Node3D:
	var horn := Node3D.new()
	horn.name = "OilHorn"
	var mouth := Node3D.new()
	mouth.name = "Horn"
	mouth.position = HORN_MOUTH
	horn.add_child(mouth)
	var ivory := Color(0.84, 0.72, 0.5)
	var segments := 6
	var prev := HORN_MOUTH
	for i in segments:
		var t := float(i + 1) / float(segments)
		# Back through the hand, then curling away: about half a turn over the horn's length.
		var angle := t * PI * 0.6
		var at := HORN_MOUTH + Vector3(-(1.0 - cos(angle)) * HORN_LENGTH * 0.55, -sin(angle) * HORN_LENGTH * 0.55, 0.0)
		var mid := (prev + at) * 0.5
		var along := at - prev
		var radius := lerpf(0.034, 0.008, t)
		var colour := ivory.lerp(Color(0.42, 0.32, 0.22), maxf(t - 0.6, 0.0) * 2.0)
		var piece := Paper.part(horn, "Segment%d" % i, Paper.cylinder(radius * 0.8, along.length() * 1.15, 7, radius), colour, mid,
				Vector3.ZERO, Vector3.ONE, 0.006)
		piece.basis = Basis(Quaternion(Vector3.UP, along.normalized()))
		prev = at
	return horn


func _person(who: String, node_name: String, at: Vector3) -> Node3D:
	var person := Node3D.new()
	person.name = node_name
	person.set_script(StoryPerson)
	person.who = who
	add_child(person)
	person.global_position = at
	return person


## Where the story's people and moments stand, so staging is tuned here, not in the story.
func _markers() -> void:
	var markers := {
		"SamuelArrival": SAMUEL_START, "SamuelPlace": SAMUEL_PLACE, "Jesse": JESSE_PLACE,
		"BrotherLine": BROTHERS_START, "DavidEntrance": DAVID_AWAY, "Anointing": DAVID_PLACE,
	}
	for marker_name in markers:
		var marker := Marker3D.new()
		marker.name = marker_name
		marker.position = markers[marker_name]
		add_child(marker)
