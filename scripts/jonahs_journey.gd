extends Node3D
## Jonah's journey, for Chapter 5, Jonah and the Great Fish (Jonah 1-4): one fold-out paper world
## of four places, far apart so only one is ever in view:
##   Joppa      the sun-warmed harbour: the quay, the ship, the road sign to Nineveh (JOPPA);
##   the ship   out at sea, where the storm rises and calms and the great fish comes (AT_SEA);
##   the deep   a calm blue chamber inside the fish, where Jonah prays (DEEP);
##   the land   the shore where the fish sets Jonah down, the road to Nineveh's gate, the city's
##              people and the little hill outside it with the shade plant (LAND).
## The story (chapter_five.gd) moves between them with go_to(), a page turning over; only the
## place in view is shown (the others are hidden and do not process). Built in code from paper
## parts, the way the courtyard and the camp are (camp_paper.gd), so there is no environment
## model to load.
##
## Who is here: Jonah, the captain and two sailors (Blender paper people, story_person.gd), the
## great fish (great_fish.gd), and Nineveh's families (nineveh_crowd.gd).
## What the child does here: finds Jonah's bag, his message and his lamp at the harbour; walks up
## to the gangway after him; on the ship, carries three loose pieces of cargo to their places
## (Secure the Cargo); later walks with Jonah to Nineveh's gate. The child never touches Jonah or
## the sea: the sailors, the sea and the fish are the story's, not the child's.

const Paper := preload("res://scripts/camp_paper.gd")
const PlayArea := preload("res://scripts/play_area.gd")
const ChapterFive := preload("res://scripts/chapter_five.gd")
const StoryPerson := preload("res://scripts/story_person.gd")
const JonahSea := preload("res://scripts/jonah_sea.gd")
const GreatFish := preload("res://scripts/great_fish.gd")
const NinevehCrowd := preload("res://scripts/nineveh_crowd.gd")
const ShadePlant := preload("res://scripts/shade_plant.gd")

## Where each place stands. Far apart, so the haze hides one from another.
const JOPPA := Vector3(0.0, 0.0, 0.0)
const AT_SEA := Vector3(400.0, 0.0, 0.0)
const DEEP := Vector3(800.0, 0.0, 0.0)
const LAND := Vector3(1200.0, 0.0, 0.0)
const PLACES := ["joppa", "sea", "deep", "land"]

const TERRACOTTA := Color(0.78, 0.46, 0.32)
const LIMESTONE := Color(0.88, 0.8, 0.64)
const QUAY_STONE := Color(0.8, 0.68, 0.52)
const HULL := Color(0.66, 0.3, 0.2)
const DECK := Color(0.72, 0.52, 0.3)
const WOOD := Color(0.42, 0.27, 0.15)
const SAIL := Color(0.95, 0.9, 0.78)
const ROPE := Color(0.78, 0.66, 0.44)
const SAND := Color(0.93, 0.84, 0.62)
const ROSE := Color(0.88, 0.7, 0.64)
const FADED_BLUE := Color(0.52, 0.64, 0.76)
const GOLD := Color(0.98, 0.8, 0.36)
const INDIGO := Color(0.16, 0.2, 0.4)

# ---- Joppa ----------------------------------------------------------------------------------
const JOPPA_ARRIVE := Vector3(0.0, 0.25, 7.0)
## The quay's seaward edge: the water starts beyond it.
const QUAY_EDGE := -6.0
## The ship lies alongside the quay, bow to the right (+x); its deck is this high.
const MOORED := Vector3(4.2, 0.0, -9.6)
const MOORED_DECK := 0.9
const GANGWAY_FOOT := Vector3(1.5, 0.0, -5.4)
## Where the child walks to follow Jonah on board, and how near counts.
const GANGWAY_SPOT := Vector3(1.5, 0.0, -4.4)
const GANGWAY_REACH := 1.3
const JONAH_JOPPA := Vector3(-2.6, 0.0, -2.4)
const SIGN := Vector3(-8.2, 0.0, 0.2)
## Jonah's three travelling things, and how near the walker must come to find one.
const THINGS := {
	"Bag": Vector3(5.8, 0.0, 3.4),
	"Message": Vector3(-6.4, 0.0, -1.4),
	"Lamp": Vector3(-4.6, 0.0, 5.2),
}
const FIND_REACH := 1.25

# ---- at sea ---------------------------------------------------------------------------------
## The deck is flat and level at the place's own height; the rail runs round it.
const DECK_SIZE := Vector2(10.0, 3.6)
const SEA_ARRIVE := Vector3(2.4, 0.25, 0.6)
## The three loose pieces of cargo: where each lies, and the outlined space it goes to.
const CARGO := {
	"Jar": {"at": Vector3(3.9, 0.0, -1.0), "spot": Vector3(-3.1, 0.0, -1.05)},
	"Sack": {"at": Vector3(1.8, 0.0, 1.2), "spot": Vector3(-3.1, 0.0, 0.0)},
	"Rope": {"at": Vector3(-1.2, 0.0, -1.1), "spot": Vector3(-3.1, 0.0, 1.05)},
}
const CARGO_REACH := 1.0
## Carrying a piece, the walker only has to come this near its outlined space.
const SPOT_REACH := 1.0
const CAPTAIN_AT := Vector3(-0.2, 0.0, 1.35)
const DECKHAND_AT := Vector3(2.5, 0.0, -1.35)
const ROPEMAN_AT := Vector3(4.2, 0.0, 0.9)
const JONAH_AT_SEA := Vector3(0.9, 0.0, -1.2)
## Where Jonah goes over the side, and the great wave that hides him from view as he does.
const OVER_SIDE := Vector3(-2.2, 0.0, 1.5)
const COVER_WAVE := Vector3(-2.4, -1.1, 3.3)
## Where the great fish rises: off the ship's side, near its stern.
const FISH_RISE := Vector3(-9.5, -0.9, 5.0)

# ---- the deep -------------------------------------------------------------------------------
const DEEP_CHILD := Vector3(0.9, 0.25, 0.4)
const JONAH_DEEP := Vector3(-0.8, 0.0, -0.2)

# ---- the land -------------------------------------------------------------------------------
const LAND_ARRIVE := Vector3(-5.0, 0.25, 4.6)
## The fish comes in close behind a wave, and Jonah walks up out of the shallows.
const SHORE_FISH := Vector3(-17.0, -0.7, -1.0)
const SHORE_WAVE := Vector3(-12.6, -0.7, 1.8)
const JONAH_SHALLOWS := Vector3(-12.0, 0.0, 0.2)
const JONAH_SHORE := Vector3(-7.4, 0.0, 0.8)
const GATE := Vector3(14.0, 0.0, 0.5)
## Jonah stands here to give God's message, and the child walks with him to here.
const JONAH_GATE := Vector3(7.6, 0.0, 0.2)
const GATE_SPOT := Vector3(5.8, 0.0, 1.8)
const GATE_REACH := 1.5
const CROWD_AT := Vector3(10.4, 0.0, 0.8)
## The hill outside the city where Jonah sits, and the plant beside him.
const HILL := Vector3(2.4, 0.0, -8.2)
const HILL_TOP := 1.3
const JONAH_HILL := Vector3(2.0, HILL_TOP, -7.9)
const PLANT_AT := Vector3(2.9, HILL_TOP, -8.3)
const HILL_CHILD := Vector3(1.4, 0.25, -4.2)

## The looks (chapter_look.gd) for each place; the storm is a crossfade from the sea's.
@export var look: Resource = preload("res://assets/looks/joppa_harbour.tres")
@export var sea_look: Resource = preload("res://assets/looks/jonah_at_sea.tres")
@export var storm_look: Resource = preload("res://assets/looks/jonah_storm.tres")
@export var deep_look: Resource = preload("res://assets/looks/jonah_deep.tres")
@export var land_look: Resource = preload("res://assets/looks/nineveh_day.tres")
## Where the walker can go at the harbour (the shell applies it); the other places have their own.
@export var play_area: Resource = PlayArea.new(Vector2(0.0, 2.0), Vector2(11.2, 7.0))
var sea_area: Resource = PlayArea.new(Vector2(AT_SEA.x + 0.6, 0.0), Vector2(3.7, 1.35), 0.6)
var deep_area: Resource = PlayArea.new(Vector2(DEEP.x + 0.6, 0.3), Vector2(0.8, 0.6), 0.4)
var land_area: Resource = PlayArea.new(Vector2(LAND.x - 0.5, 0.5), Vector2(11.0, 7.4))

var place: String = ""
var _built: bool = false
var _time: float = 0.0
var _roots: Dictionary = {}
var _jonah: Node3D
var _captain: Node3D
var _crew: Array[Node3D] = []
var _sea: Node3D
var _harbour_sea: Node3D
var _shore_sea: Node3D
var _fish: Node3D
var _shore_fish: Node3D
var _crowd: Node3D
var _plant: Node3D
var _cover_wave: Node3D
var _shore_wave: Node3D
var _sail: Node3D
var _things: Dictionary = {}
var _found: Array = []
var _cargo: Dictionary = {}
var _spots: Dictionary = {}
var _secured: Array = []
var _carrying: String = ""
var _message: Node3D
var _gulls: Array[Node3D] = []
var _page: ColorRect
var _light_tween: Tween
## Seconds to the next glance for each crew member (they look about while they wait).
var _glance: Array[float] = []
var _deep_light: OmniLight3D
var _gangway_ring: Area3D
var _gate_ring: Area3D


## Builds the world and starts the story, or carries on with it. Only the shell calls this.
func visit() -> void:
	_build()
	if in_progress():
		return
	_show_place("joppa")
	var story := get_node_or_null("ChapterFive")
	if story and story.has_method("begin"):
		story.begin()


func in_progress() -> bool:
	var story := get_node_or_null("ChapterFive")
	return story != null and story.phase != ChapterFive.Phase.IDLE and story.phase != ChapterFive.Phase.DONE


func stand_down() -> void:
	set_child_watch(null)
	var story := get_node_or_null("ChapterFive")
	if story and story.has_method("stand_down"):
		story.stand_down()


# ---- what the story asks of the world ------------------------------------------------------

func jonah() -> Node3D:
	return _jonah


func captain() -> Node3D:
	return _captain


func crew() -> Array[Node3D]:
	return _crew


func sea() -> Node3D:
	return _sea


func fish() -> Node3D:
	return _fish


func shore_fish() -> Node3D:
	return _shore_fish


func crowd() -> Node3D:
	return _crowd


func plant() -> Node3D:
	return _plant


func found_things() -> Array:
	return _found.duplicate()


func secured() -> Array:
	return _secured.duplicate()


func carrying() -> String:
	return _carrying


func place_root(which: String) -> Node3D:
	return _roots.get(which)


## Turns the page to place `which` ("joppa", "sea", "deep" or "land"): the paper covers the view,
## the walker, the camera and the light move there, and the paper lifts. `then` runs while it is
## covered. Returns the tween (null when `seconds` is 0: then it all happens at once).
func go_to(which: String, then: Callable = Callable(), seconds: float = 0.45) -> Tween:
	if seconds <= 0.0:
		_show_place(which)
		if then.is_valid():
			then.call()
		return null
	var page := _page_cover()
	var tw := create_tween()
	tw.tween_property(page, "color:a", 1.0, seconds).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		_show_place(which)
		if then.is_valid():
			then.call())
	tw.tween_interval(0.15)
	tw.tween_property(page, "color:a", 0.0, seconds * 1.2).set_trans(Tween.TRANS_SINE)
	return tw


func _show_place(which: String) -> void:
	place = which
	for key in _roots:
		var root := _roots[key] as Node3D
		root.visible = key == which
		root.process_mode = Node.PROCESS_MODE_INHERIT if key == which else Node.PROCESS_MODE_DISABLED
	# Jonah goes where the story is (he is in every place but in the fish's mouth on the way).
	var main := get_parent()
	var player := main.get_node_or_null("Player") as CharacterBody3D
	var arrive: Vector3 = {"joppa": JOPPA_ARRIVE, "sea": AT_SEA + SEA_ARRIVE, "deep": DEEP + DEEP_CHILD, "land": LAND + LAND_ARRIVE}[which]
	if player:
		player.velocity = Vector3.ZERO
		player.global_position = arrive
		_snap_followers(player)
	var place_look: Resource = {"joppa": look, "sea": sea_look, "deep": deep_look, "land": land_look}[which]
	if main.has_method("apply_look"):
		main.apply_look(place_look)
		if player:
			_snap_followers(player)
	var bounds := main.get_node_or_null("PlayBounds")
	if bounds and bounds.has_method("use_area"):
		bounds.use_area({"joppa": play_area, "sea": sea_area, "deep": deep_area, "land": land_area}[which])
	var camera := get_node_or_null("StillCamera") as Camera3D
	if camera:
		camera.current = false
		var tabletop := main.get_node_or_null("TabletopCamera") as Camera3D
		if tabletop:
			tabletop.current = true


## The page that turns between places: warm paper over the whole view.
func _page_cover() -> ColorRect:
	if _page == null:
		var layer := CanvasLayer.new()
		layer.name = "PageTurn"
		layer.layer = 12
		add_child(layer)
		_page = ColorRect.new()
		_page.name = "Page"
		_page.set_anchors_preset(Control.PRESET_FULL_RECT)
		_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_page.color = Color(0.96, 0.9, 0.76, 0.0)
		layer.add_child(_page)
	return _page


func page_showing() -> bool:
	return _page != null and _page.color.a > 0.01


## Crossfades the sky and lights to `to` (a chapter_look.gd) over `seconds`, from how they are
## now: the storm coming on, and going again.
func fade_light(to: Resource, seconds: float) -> void:
	var main := get_parent()
	if _light_tween:
		_light_tween.kill()
	var env: Environment = (main.get_node("WorldEnvironment") as WorldEnvironment).environment
	var sky := env.sky.sky_material as ProceduralSkyMaterial if env.sky else null
	var groups := [
		[env, ["ambient_light_color", "ambient_light_energy", "fog_light_color", "fog_density"]],
		[main.get_node("Sun"), ["light_color", "light_energy"]], [main.get_node("FillLight"), ["light_color", "light_energy"]],
	]
	if sky:
		groups.append([sky, ["sky_top_color", "sky_horizon_color", "ground_horizon_color", "ground_bottom_color"]])
	var before: Array = []
	for group in groups:
		for property in group[1]:
			before.append(group[0].get(property))
	main.apply_lighting(to)
	_light_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var i := 0
	for group in groups:
		for property in group[1]:
			var target: Variant = group[0].get(property)
			group[0].set(property, before[i])
			_light_tween.tween_property(group[0], property, target, seconds)
			i += 1


## -- Joppa: Jonah's things ------------------------------------------------------------------

## Shows Jonah's three travelling things, each with a soft glow, so the child can find them.
func open_finds() -> void:
	for thing in _things:
		var node := _things[thing] as Node3D
		node.visible = not _found.has(thing)


## Jonah's thing within reach of `at` that has not been found yet, taken, or "".
func find_near(at: Vector3) -> String:
	for thing in THINGS:
		var node := _things[thing] as Node3D
		if _found.has(thing) or not node.visible or _flat_distance(at, node.global_position) > FIND_REACH:
			continue
		_found.append(thing)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(node, "scale", Vector3.ONE * 0.05, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_property(node, "position:y", node.position.y + 0.8, 0.45)
		tw.chain().tween_callback(func() -> void: node.visible = false)
		return thing
	return ""


## The things still to find, for the golden arrow (wonder_item_hints.gd).
func find_spots() -> Array:
	var out: Array = []
	for thing in THINGS:
		if not _found.has(thing):
			out.append(_things[thing])
	return out


## The dashed ring at the gangway's foot, where the child follows Jonah on board.
func show_gangway_ring(on: bool) -> void:
	_gangway_ring.visible = on


func gangway_ring() -> Area3D:
	return _gangway_ring


func show_gate_ring(on: bool) -> void:
	_gate_ring.visible = on


func gate_ring() -> Area3D:
	return _gate_ring


func at_gangway(at: Vector3) -> bool:
	return _flat_distance(at, GANGWAY_SPOT) < GANGWAY_REACH


## Jonah walks from where he stands, along the quay and up the gangway onto the ship's deck.
func jonah_boards() -> Tween:
	_jonah.watch = null
	var tw := walk(_jonah, GANGWAY_FOOT, 2.2, MOORED + Vector3(0.0, MOORED_DECK, 0.0))
	tw.tween_callback(func() -> void: _jonah.walk_amount = 1.0)
	tw.tween_property(_jonah, "global_position", Vector3(GANGWAY_FOOT.x, MOORED_DECK, MOORED.z + 1.0), 1.4)
	tw.tween_callback(func() -> void:
		_jonah.walk_amount = 0.0
		face(_jonah, GANGWAY_SPOT))
	return tw


## -- at sea: Secure the Cargo ---------------------------------------------------------------

func open_cargo() -> void:
	for piece in CARGO:
		(_cargo[piece] as Node3D).visible = true
		(_spots[piece] as Node3D).visible = not _secured.has(piece)


func cargo_within_reach(at: Vector3) -> String:
	if not _carrying.is_empty():
		return ""
	for piece in CARGO:
		if _secured.has(piece):
			continue
		if _flat_distance(at, (_cargo[piece] as Node3D).global_position) < CARGO_REACH:
			return piece
	return ""


func pick_up(piece: String) -> bool:
	if not _carrying.is_empty() or _secured.has(piece):
		return false
	_carrying = piece
	return true


## True when the carried piece is near enough its own outlined space to be set down.
func at_carried_spot(at: Vector3) -> bool:
	return not _carrying.is_empty() and _flat_distance(at, AT_SEA + CARGO[_carrying]["spot"]) < SPOT_REACH


## Sets the carried piece into its space over about half a second. Returns it.
func place_carried() -> String:
	var piece := _carrying
	if piece.is_empty():
		return ""
	_carrying = ""
	_secured.append(piece)
	var node := _cargo[piece] as Node3D
	var tw := create_tween().set_parallel(true)
	tw.tween_property(node, "global_position", AT_SEA + CARGO[piece]["spot"], 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "rotation", Vector3.ZERO, 0.5)
	(_spots[piece] as Node3D).visible = false
	return piece


## The spots the golden arrow can point at: the loose pieces, or the space for the carried one.
func cargo_spots() -> Array:
	if not _carrying.is_empty():
		return [_spots[_carrying]]
	var out: Array = []
	for piece in CARGO:
		if not _secured.has(piece):
			out.append(_cargo[piece])
	return out


## -- at sea: the storm and the sea ----------------------------------------------------------

## The storm rises to `amount` over `seconds`: sea, rain and sky together.
func set_storm(amount: float, seconds: float) -> Tween:
	fade_light(storm_look if amount > 0.5 else sea_look, seconds)
	return _sea.set_storm(amount, seconds)


## Jonah walks to the ship's side; the great wave rises between him and the view and he is gone
## behind it, and as it sinks back the storm goes quiet with it, on the same timeline. Nobody
## throws him, and the child does nothing here but watch (Jonah 1:15).
func jonah_into_sea(seconds: float = 6.0) -> Tween:
	_jonah.watch = null
	var tw := walk(_jonah, AT_SEA + OVER_SIDE, 1.6, AT_SEA + OVER_SIDE + Vector3(0.0, 0.0, 2.0))
	tw.tween_property(_cover_wave, "position:y", COVER_WAVE.y + 2.7, seconds * 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void: _jonah.visible = false)
	tw.tween_interval(seconds * 0.1)
	tw.tween_callback(func() -> void: set_storm(0.0, seconds * 0.5))
	tw.tween_property(_cover_wave, "position:y", COVER_WAVE.y, seconds * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tw


## Holds the still camera on the ship's side while Jonah goes (the crew stay in view).
func over_side_shot() -> void:
	_still_shot(AT_SEA + Vector3(3.6, 1.9, 8.2), AT_SEA + Vector3(-1.6, 1.0, 0.8))


## Looks down over the side at the water where the great fish rises.
func fish_shot() -> void:
	_still_shot(AT_SEA + Vector3(-2.6, 3.6, 7.6), AT_SEA + FISH_RISE + Vector3(0.0, 0.4, -0.6))


func cover_wave_top() -> float:
	return _cover_wave.global_position.y


## -- the deep --------------------------------------------------------------------------------

## A quiet side view of Jonah and Wonder Light in the chamber.
func prayer_shot() -> void:
	_still_shot(DEEP + Vector3(0.1, 1.45, 4.4), DEEP + Vector3(0.1, 0.9, 0.0))


## One of the prayer's three lights: it rises from Jonah's hands and drifts along a gentle curve
## to Wonder Light over about a second, then glows beside it. Returns the light.
func send_prayer_light(index: int, colour: Color) -> Node3D:
	var root := _roots["deep"] as Node3D
	var light := Paper.halo(0.55, colour)
	light.name = "PrayerLight%d" % index
	root.add_child(light)
	var from := _jonah.global_position + Vector3(0.25, 1.0, 0.1)
	light.global_position = from
	var wonder := get_parent().get_node_or_null("WonderLight") as Node3D
	var to := (wonder.global_position if wonder else from + Vector3(1.4, 1.0, 0.0)) + Vector3(-0.35 + 0.35 * index, 0.25, 0.0)
	var bend := (from + to) * 0.5 + Vector3(0.0, 0.9, 0.0)
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		light.global_position = from.lerp(bend, t).lerp(bend.lerp(to, t), t), 0.0, 1.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return light


## -- the land --------------------------------------------------------------------------------

## The fish comes in to the shore behind a wave, and Jonah walks up out of the shallows onto the
## dry sand, then the fish goes back into the deep. No spitting and nothing silly (Jonah 2:10).
func release(seconds: float = 4.0) -> Tween:
	_jonah.visible = false
	_jonah.global_position = LAND + JONAH_SHALLOWS
	face(_jonah, LAND + JONAH_SHORE)
	var tw: Tween = _shore_fish.rise(seconds * 0.35)
	tw.tween_property(_shore_wave, "position:y", SHORE_WAVE.y + 1.4, seconds * 0.15).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void: _jonah.visible = true)
	tw.tween_callback(func() -> void:
		walk(_jonah, LAND + JONAH_SHORE, seconds * 0.45, LAND + LAND_ARRIVE)
		_shore_fish.sink(seconds * 0.5))
	tw.tween_property(_shore_wave, "position:y", SHORE_WAVE.y, seconds * 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(0.2)
	tw.tween_callback(func() -> void: _open_message())
	# Time for the message to open before the story moves on.
	tw.tween_interval(0.9)
	return tw


func release_shot() -> void:
	_still_shot(LAND + Vector3(-3.4, 2.4, 8.4), LAND + Vector3(-10.4, 0.5, 0.4))


## The rolled message opens, and turns towards the road to Nineveh.
func _open_message() -> void:
	if _message == null:
		return
	_message.visible = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_message, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_message, "rotation:y", -PI * 0.5, 0.9).set_trans(Tween.TRANS_SINE)


func message_open() -> bool:
	return _message != null and _message.visible and _message.scale.x > 0.9


## Jonah sets off along the road to Nineveh's gate.
func jonah_to_gate(seconds: float = 6.5) -> Tween:
	_jonah.watch = null
	return walk(_jonah, LAND + JONAH_GATE, seconds, LAND + CROWD_AT)


func at_gate(at: Vector3) -> bool:
	return _flat_distance(at, LAND + GATE_SPOT) < GATE_REACH


func gate_shot() -> void:
	_still_shot(LAND + Vector3(6.2, 2.6, 8.0), LAND + Vector3(10.0, 1.0, 0.4))


## Jonah sits on the hill outside the city, with the city below and the plant beside him.
func to_hill() -> void:
	_jonah.visible = true
	_jonah.walk_amount = 0.0
	_jonah.global_position = LAND + JONAH_HILL
	face(_jonah, LAND + GATE)
	_jonah.kneel = 0.8
	_jonah.watch = null


func hill_shot() -> void:
	_still_shot(LAND + Vector3(-3.6, 3.4, -1.2), LAND + Vector3(6.4, 1.6, -7.2))


## -- staging ---------------------------------------------------------------------------------

## Sets the world as it stands at a story beat the child is carrying on from (chapter_five.gd).
func set_scene_for(beat: String) -> void:
	match beat:
		"find":
			open_finds()
		"cargo", "storm":
			_found = THINGS.keys()
			if beat == "storm":
				_secured = CARGO.keys()
			_jonah.global_position = AT_SEA + JONAH_AT_SEA
			face(_jonah, AT_SEA + CAPTAIN_AT)
		"prayer":
			_found = THINGS.keys()
			_secured = CARGO.keys()
			_jonah.global_position = DEEP + JONAH_DEEP
			_jonah.kneel = 1.0
		"nineveh", "hill", "reflect":
			_found = THINGS.keys()
			_secured = CARGO.keys()
			_jonah.kneel = 0.0
			_jonah.global_position = LAND + JONAH_GATE
			face(_jonah, LAND + CROWD_AT)
			_message.visible = true
			_message.scale = Vector3.ONE
			if beat != "nineveh":
				_crowd.set_pose("sorry", LAND + JONAH_GATE, 0.0)
				to_hill()
	for piece in _secured:
		var node := _cargo[piece] as Node3D
		node.global_position = AT_SEA + CARGO[piece]["spot"]
		node.rotation = Vector3.ZERO
		(_spots[piece] as Node3D).visible = false


## Jonah for this place: on the quay at Joppa, on deck at sea, kneeling in the deep.
func place_jonah(which: String) -> void:
	_jonah.visible = true
	_jonah.walk_amount = 0.0
	match which:
		"sea":
			_jonah.kneel = 0.0
			_jonah.global_position = AT_SEA + JONAH_AT_SEA
			face(_jonah, AT_SEA + CAPTAIN_AT)
		"deep":
			_jonah.global_position = DEEP + JONAH_DEEP
			face(_jonah, DEEP + DEEP_CHILD)
			_jonah.kneel = 1.0


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


## Who speaks now: "Jonah", "Captain" or "". The one speaking turns to whom they talk to, and
## the others on deck turn to the speaker. The child looks at whoever is talking.
func set_speaking(speaker: String) -> void:
	_jonah.speaking = speaker == "Jonah"
	_captain.speaking = speaker == "Captain"
	var speaking: Node3D = {"Jonah": _jonah, "Captain": _captain}.get(speaker)
	if speaking == null or not speaking.visible:
		return
	set_child_watch(speaking)
	if place != "sea":
		return
	for member in _crew:
		if member != speaking:
			member.watch = speaking
	if speaking == _captain:
		_captain.watch = _jonah
		_jonah.watch = _captain
	else:
		_jonah.watch = _captain


func set_child_watch(target: Node3D) -> void:
	var player := get_parent().get_node_or_null("Player") if get_parent() else null
	if player and "watch" in player:
		player.watch = target


## Jonah turns to the child (the reflection).
func watch_child(child: Node3D) -> void:
	if _jonah.visible:
		_jonah.watch = child


## Holds the world's own still camera at `eye`, looking at `look`, until the story cuts back
## with the camera director (or the page turns to another place).
func _still_shot(eye: Vector3, at: Vector3) -> void:
	var cam := get_node_or_null("StillCamera") as Camera3D
	if cam == null:
		cam = Camera3D.new()
		cam.name = "StillCamera"
		cam.fov = 44.0
		add_child(cam)
	cam.look_at_from_position(eye, at, Vector3.UP)
	cam.current = true


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _snap_followers(player: Node3D) -> void:
	var main := get_parent()
	var cam := main.get_node_or_null("TabletopCamera") as Camera3D
	if cam and "offset" in cam:
		cam.global_position = player.global_position + cam.offset
		cam.look_at(player.global_position + Vector3(0.0, cam.get("look_height"), 0.0), Vector3.UP)
	var light := main.get_node_or_null("WonderLight") as Node3D
	if light and "hover_offset" in light:
		light.global_position = player.global_position + light.hover_offset


func _process(delta: float) -> void:
	if not _built:
		return
	_time += delta
	# The carried piece floats beside Wonder Light, bobbing a little.
	if not _carrying.is_empty():
		var light := get_parent().get_node_or_null("WonderLight") as Node3D
		var node := _cargo[_carrying] as Node3D
		if light:
			var want := light.global_position + Vector3(0.45, -0.3 + sin(_time * 3.0) * 0.05, 0.0)
			node.global_position = node.global_position.lerp(want, minf(1.0, delta * 8.0))
			node.rotation.y += delta * 0.8
	for piece in _spots:
		var spot := _spots[piece] as Node3D
		if spot.visible:
			var strong := 1.0 if piece == _carrying else 0.5
			spot.scale = Vector3.ONE * (1.0 + sin(_time * 2.6) * 0.06 * strong) * (1.12 if piece == _carrying else 1.0)
	for ring in [_gangway_ring, _gate_ring]:
		if ring and ring.visible:
			ring.scale = Vector3.ONE * (1.0 + sin(_time * 2.6) * 0.07)
	for thing in _things:
		var glow := (_things[thing] as Node3D).get_node_or_null("Glow") as Node3D
		if glow:
			glow.scale = Vector3.ONE * (1.0 + sin(_time * 2.0 + float(thing.length())) * 0.12)
	# The sail fills and slackens; in the storm it pulls harder.
	if _sail:
		var gust: float = _sea.storm if _sea else 0.0
		_sail.rotation.y = 0.55 + sin(_time * 1.3) * (0.03 + gust * 0.08) * JonahSea.motion()
	for i in _gulls.size():
		var a := _time * 0.35 + float(i) * PI
		_gulls[i].position = Vector3(cos(a) * (9.0 + i * 3.0) + 2.0, 7.0 + i * 1.2 + sin(_time + i) * 0.4, sin(a) * 6.0 - 12.0)
		_gulls[i].rotation.y = -a
		(_gulls[i].get_child(0) as Node3D).rotation.z = sin(_time * 5.0 + i) * 0.35
		(_gulls[i].get_child(1) as Node3D).rotation.z = -sin(_time * 5.0 + i) * 0.35
	_crew_glances(delta)
	if _deep_light:
		_deep_light.light_energy = 1.6 + sin(_time * 1.3) * 0.2


## The sailors look about now and then while nobody is talking to them, so they are never frozen.
func _crew_glances(delta: float) -> void:
	for i in _crew.size():
		var member := _crew[i]
		if member.watch != null or member.speaking:
			member.look_aside = lerpf(member.look_aside, 0.0, minf(1.0, delta * 3.0))
			continue
		_glance[i] -= delta
		if _glance[i] <= 0.0:
			_glance[i] = randf_range(2.5, 6.0)
			member.set_meta("glance_to", randf_range(-0.6, 0.6))
		member.look_aside = lerpf(member.look_aside, float(member.get_meta("glance_to", 0.0)), minf(1.0, delta * 1.6))


# ---- building -------------------------------------------------------------------------------

func _build() -> void:
	if _built:
		return
	_built = true
	for key in PLACES:
		var root := Node3D.new()
		root.name = {"joppa": "Joppa", "sea": "AtSea", "deep": "Deep", "land": "Land"}[key]
		root.position = {"joppa": JOPPA, "sea": AT_SEA, "deep": DEEP, "land": LAND}[key]
		add_child(root)
		_roots[key] = root
	_build_joppa(_roots["joppa"])
	_build_at_sea(_roots["sea"])
	_build_deep(_roots["deep"])
	_build_land(_roots["land"])
	_people()
	var story := Node.new()
	story.name = "ChapterFive"
	story.set_script(ChapterFive)
	add_child(story)


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


## Ground the walker stands on: a box whose top is at y = 0, with a paper top of `colour`.
func _floor(parent: Node3D, floor_name: String, size: Vector2, at: Vector3, colour: Color, material: Material = null) -> void:
	var ground := _solid(parent, floor_name, Vector3(size.x, 0.6, size.y), at + Vector3(0.0, -0.3, 0.0))
	var top := Paper.part(ground, "Top", Paper.box(Vector3(size.x, 0.6, size.y)), colour, at + Vector3(0.0, -0.3, 0.0), Vector3.ZERO, Vector3.ONE, 0.03)
	if material:
		top.material_override = material


## Stone in a few close tones laid in soft patches, mapped from above in world space.
func _stone_material(base: Color, seed_value: int, scale: float) -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	noise.cellular_jitter = 0.8
	noise.frequency = 0.06
	noise.seed = seed_value
	var tones := Gradient.new()
	tones.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	tones.offsets = PackedFloat32Array([0.0, 0.3, 0.55, 0.8])
	tones.colors = PackedColorArray([base.darkened(0.06), base, base.lightened(0.05), base.darkened(0.03)])
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
	mat.uv1_scale = Vector3.ONE / scale
	return mat


func _build_joppa(root: Node3D) -> void:
	_floor(root, "Quay", Vector2(28.0, 17.0), Vector3(0.0, 0.0, 2.5), QUAY_STONE, _stone_material(QUAY_STONE, 505, 9.0))
	# The quay's edge: a kerb of big stones; the walker cannot step off it.
	var rng := RandomNumberGenerator.new()
	rng.seed = 5050
	var x := -13.5
	while x < 13.8:
		var w := rng.randf_range(1.0, 1.5)
		Paper.part(root, "Kerb", Paper.box(Vector3(w - 0.06, 0.28, 0.7)), LIMESTONE.darkened(rng.randf_range(0.02, 0.14)), Vector3(x + w * 0.5, 0.1, QUAY_EDGE + 0.3),
				Vector3.ZERO, Vector3.ONE, 0.015)
		x += w
	_solid(root, "QuayEdge", Vector3(28.0, 3.0, 0.6), Vector3(0.0, 1.5, QUAY_EDGE - 0.1))
	# Broad stone steps down into the water at the left, where small boats tie up.
	for i in 3:
		Paper.part(root, "Step%d" % i, Paper.box(Vector3(3.2, 0.3, 0.6)), LIMESTONE.darkened(0.08 + i * 0.04), Vector3(-9.0, -0.2 - i * 0.3, QUAY_EDGE - 0.4 - i * 0.6),
				Vector3.ZERO, Vector3.ONE, 0.015)
	_harbour_sea = JonahSea.new()
	_harbour_sea.name = "HarbourSea"
	_harbour_sea.size = Vector2(240.0, 200.0)
	_harbour_sea.position = Vector3(0.0, -0.8, -95.0)
	_harbour_sea.bands = [
		{"at": Vector3(-4.0, 0.0, 83.0), "length": 26.0, "height": 0.35, "speed": 0.35},
		{"at": Vector3(6.0, 0.0, 76.0), "length": 30.0, "height": 0.45, "speed": 0.28},
	]
	root.add_child(_harbour_sea)
	var moored := _ship(root, "MooredShip", MOORED + Vector3(0.0, MOORED_DECK, 0.0))
	moored.rotation.z = 0.0
	# The gangway from the quay up onto the deck, with a rope rail.
	var gangway := Node3D.new()
	gangway.name = "Gangway"
	root.add_child(gangway)
	var top := Vector3(GANGWAY_FOOT.x, MOORED_DECK, MOORED.z + 1.6)
	var mid := (GANGWAY_FOOT + top) * 0.5
	var plank := Paper.part(gangway, "Plank", Paper.box(Vector3(0.9, 0.08, GANGWAY_FOOT.distance_to(top))), DECK.darkened(0.08), mid + Vector3(0.0, 0.05, 0.0))
	plank.rotation.x = atan2(top.y - GANGWAY_FOOT.y, GANGWAY_FOOT.z - top.z)
	for side in [-0.45, 0.45]:
		var rail := Paper.part(gangway, "RopeRail", Paper.cylinder(0.02, GANGWAY_FOOT.distance_to(top), 5), ROPE, mid + Vector3(side, 0.62, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
		rail.rotation.x = PI * 0.5 + plank.rotation.x
	for post in [Vector3(-0.8, 0.0, -5.5), Vector3(9.0, 0.0, -5.5)]:
		Paper.part(root, "MooringPost", Paper.cylinder(0.2, 0.9, 8, 0.16), WOOD, post + Vector3(0.0, 0.45, 0.0))
		_solid(root, "PostBody", Vector3(0.5, 1.0, 0.5), post + Vector3(0.0, 0.5, 0.0))
		var line := Paper.part(root, "MooringLine", Paper.cylinder(0.025, 4.0, 5), ROPE, post + Vector3(0.0, 0.8, -1.9), Vector3(PI * 0.5 - 0.1, 0.0, 0.0), Vector3.ONE, 0.0)
		line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Folded nets, clear of the path, and crates and jars by the harbour houses.
	for i in 3:
		Paper.part(root, "Net%d" % i, Paper.box(Vector3(1.3 - i * 0.15, 0.14, 0.9 - i * 0.1)), Color(0.66, 0.6, 0.46).darkened(0.05 * i),
				Vector3(10.6, 0.07 + i * 0.14, -4.3), Vector3(0.0, 0.2 * i, 0.0), Vector3.ONE, 0.012)
	_solid(root, "NetsBody", Vector3(1.4, 0.5, 1.0), Vector3(10.6, 0.25, -4.3))
	for crate in [Vector3(-10.8, 0.0, -3.8), Vector3(-11.9, 0.0, -3.3), Vector3(-11.3, 0.7, -3.6)]:
		Paper.part(root, "Crate", Paper.box(Vector3(0.9, 0.7, 0.9)), WOOD.lightened(0.18), crate + Vector3(0.0, 0.35, 0.0), Vector3(0.0, crate.x * 0.3, 0.0))
	_solid(root, "CratesBody", Vector3(2.2, 1.4, 1.4), Vector3(-11.3, 0.7, -3.6))
	for jar in [Vector3(10.4, 0.0, 5.6), Vector3(11.0, 0.0, 6.2), Vector3(10.2, 0.0, 6.6)]:
		Paper.part(root, "Jar", Paper.cylinder(0.24, 0.7, 9, 0.14), TERRACOTTA, jar + Vector3(0.0, 0.35, 0.0))
	_solid(root, "JarsBody", Vector3(1.4, 0.8, 1.6), Vector3(10.5, 0.4, 6.1))
	_gangway_ring = _ring(root, "GangwayRing", GANGWAY_SPOT, 0.7)
	_harbour_houses(root)
	_road_sign(root)
	_joppa_things(root)
	for i in 2:
		var gull := _gull()
		gull.name = "Gull%d" % i
		root.add_child(gull)
		_gulls.append(gull)


## Flat-roofed houses of warm stone and terracotta along the back of the quay's sides, with dark
## doorways and a striped awning over a stall, so the harbour is a real place.
func _harbour_houses(root: Node3D) -> void:
	var houses := [
		[Vector3(-12.8, 0.0, 1.0), Vector3(3.2, 3.2, 3.6), LIMESTONE], [Vector3(-13.2, 0.0, 5.4), Vector3(3.6, 2.6, 3.8), TERRACOTTA.lightened(0.2)],
		[Vector3(13.0, 0.0, 1.8), Vector3(3.4, 3.6, 3.6), TERRACOTTA.lightened(0.28)], [Vector3(13.4, 0.0, 6.6), Vector3(3.8, 2.8, 4.0), LIMESTONE.darkened(0.04)],
	]
	for house in houses:
		var at: Vector3 = house[0]
		var size: Vector3 = house[1]
		Paper.part(root, "House", Paper.box(size), house[2], at + Vector3(0.0, size.y * 0.5, 0.0))
		Paper.part(root, "Roof", Paper.box(Vector3(size.x + 0.2, 0.18, size.z + 0.2)), (house[2] as Color).darkened(0.12), at + Vector3(0.0, size.y + 0.09, 0.0))
		var inward := -signf(at.x)
		Paper.part(root, "Door", Paper.box(Vector3(0.06, 1.8, 1.0)), Color(0.32, 0.2, 0.12), at + Vector3(inward * (size.x * 0.5 + 0.03), 0.9, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
		_solid(root, "HouseBody", size, at + Vector3(0.0, size.y * 0.5, 0.0))
	# A stall with a striped awning, by the houses on the right.
	var stall := Vector3(10.6, 0.0, 3.4)
	for post in [Vector3(-0.9, 0.0, -0.8), Vector3(0.9, 0.0, -0.8), Vector3(-0.9, 0.0, 0.8), Vector3(0.9, 0.0, 0.8)]:
		Paper.part(root, "StallPost", Paper.cylinder(0.05, 2.2, 6), WOOD, stall + post + Vector3(0.0, 1.1, 0.0), Vector3.ZERO, Vector3.ONE, 0.01)
	for i in 4:
		Paper.part(root, "Awning%d" % i, Paper.box(Vector3(0.5, 0.05, 2.0)), SAIL if i % 2 == 0 else TERRACOTTA, stall + Vector3(-0.75 + i * 0.5, 2.2, 0.0),
				Vector3(0.0, 0.0, 0.12), Vector3.ONE, 0.01)
	Paper.part(root, "StallTable", Paper.box(Vector3(1.8, 0.1, 1.2)), WOOD.lightened(0.2), stall + Vector3(0.0, 0.8, 0.0))
	for i in 5:
		Paper.part(root, "Fruit%d" % i, Paper.sphere(0.1, 6), [Color(0.9, 0.56, 0.2), Color(0.6, 0.3, 0.46), Color(0.78, 0.7, 0.3)][i % 3],
				stall + Vector3(-0.5 + i * 0.25, 0.92, 0.1 * (i % 2)), Vector3.ZERO, Vector3.ONE, 0.0)
	_solid(root, "StallBody", Vector3(2.0, 1.0, 1.8), stall + Vector3(0.0, 0.5, 0.0))


## The road marker at the quay's corner, its arrow pointing inland to Nineveh, the way God asked
## Jonah to go, while the ship behind it points out to sea. A dusty road runs off beside it.
func _road_sign(root: Node3D) -> void:
	var sign_post := Node3D.new()
	sign_post.name = "NinevehSign"
	sign_post.position = SIGN
	root.add_child(sign_post)
	Paper.part(sign_post, "Post", Paper.cylinder(0.08, 2.3, 6), WOOD, Vector3(0.0, 1.15, 0.0))
	var board := Node3D.new()
	board.name = "Arrow"
	board.position = Vector3(-0.55, 1.95, 0.0)
	sign_post.add_child(board)
	Paper.part(board, "Board", Paper.box(Vector3(1.2, 0.34, 0.06)), SAND, Vector3.ZERO)
	var tip := Paper.part(board, "Tip", Paper.cylinder(0.24, 0.06, 3), SAND, Vector3(-0.66, 0.0, 0.0), Vector3(PI * 0.5, 0.0, PI * 0.5))
	tip.scale = Vector3(1.0, 1.0, 1.0)
	var words := Label3D.new()
	words.name = "Words"
	words.text = "Nineveh"
	words.font_size = 48
	words.pixel_size = 0.004
	words.modulate = Color(0.3, 0.18, 0.08)
	words.outline_size = 0
	words.position = Vector3(0.0, 0.0, 0.04)
	board.add_child(words)
	_solid(root, "SignBody", Vector3(0.4, 2.0, 0.4), SIGN + Vector3(0.0, 1.0, 0.0))
	# The dusty road inland, from the sign off past the quay's corner.
	var patches: Array[Transform3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 5051
	for i in 10:
		var t := float(i) / 9.0
		var at := SIGN.lerp(Vector3(-15.0, 0.0, 9.0), t) + Vector3(sin(t * PI) * 0.5, 0.014, 0.0)
		patches.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(rng.randf_range(1.5, 2.0), 1.0, rng.randf_range(1.1, 1.4))), at))
	_scatter(root, "Road", Paper.cylinder(0.6, 0.02, 9), patches, [SAND.darkened(0.06), SAND.darkened(0.1)])


## Jonah's bag, the rolled message and his lamp, each with a soft glow until found.
func _joppa_things(root: Node3D) -> void:
	for thing in THINGS:
		var node := _spot_area(thing, FIND_REACH)
		root.add_child(node)
		node.position = THINGS[thing]
		match thing:
			"Bag":
				Paper.part(node, "Sack", Paper.sphere(0.3, 8), Color(0.56, 0.44, 0.3), Vector3(0.0, 0.26, 0.0), Vector3.ZERO, Vector3(1.0, 0.9, 0.8))
				Paper.part(node, "Tie", Paper.cylinder(0.08, 0.14, 6), ROPE, Vector3(0.0, 0.56, 0.0))
				Paper.part(node, "Strap", Paper.box(Vector3(0.06, 0.04, 0.9)), Color(0.4, 0.3, 0.2), Vector3(0.0, 0.3, 0.0), Vector3(0.0, 0.4, 0.5), Vector3.ONE, 0.0)
			"Message":
				Paper.part(node, "Scroll", Paper.cylinder(0.07, 0.5, 8), Color(0.96, 0.9, 0.74), Vector3(0.0, 0.08, 0.0), Vector3(0.0, 0.0, PI * 0.5))
				Paper.part(node, "Cord", Paper.cylinder(0.075, 0.05, 8), Color(0.62, 0.24, 0.2), Vector3(0.0, 0.08, 0.0), Vector3(0.0, 0.0, PI * 0.5), Vector3.ONE, 0.0)
			"Lamp":
				Paper.part(node, "Dish", Paper.cylinder(0.22, 0.12, 8, 0.15), Color(0.74, 0.5, 0.26), Vector3(0.0, 0.06, 0.0), Vector3.ZERO, Vector3(1.0, 1.0, 0.7))
				var flame := Paper.part(node, "Flame", Paper.flame(0.08, 0.2, 0.0), GOLD, Vector3(0.2, 0.12, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
				flame.material_override = Paper.glow_mat(GOLD)
		var glow := Paper.halo(1.1, Color(1.0, 0.86, 0.5, 0.5))
		glow.name = "Glow"
		glow.position = Vector3(0.0, 0.3, 0.0)
		node.add_child(glow)
		node.visible = false
		_things[thing] = node


## A sailing ship of Jonah's day: a broad ochre-red hull, a deck of planks with a high rail,
## a low cabin at the stern, one mast with a cream square sail on its yard. `deck_at` is the
## middle of the deck's top; the bow points +x. With `walkable`, the deck and rail are solid.
func _ship(parent: Node3D, ship_name: String, deck_at: Vector3, walkable: bool = false) -> Node3D:
	var ship := Node3D.new()
	ship.name = ship_name
	ship.position = deck_at
	parent.add_child(ship)
	var hull := Node3D.new()
	hull.name = "Hull"
	ship.add_child(hull)
	Paper.part(hull, "Belly", Paper.box(Vector3(DECK_SIZE.x, 1.7, DECK_SIZE.y + 0.3)), HULL, Vector3(0.0, -0.95, 0.0))
	Paper.part(hull, "Keel", Paper.box(Vector3(DECK_SIZE.x - 1.2, 0.8, DECK_SIZE.y - 0.8)), HULL.darkened(0.12), Vector3(0.0, -2.0, 0.0))
	# The bow and the stern curve up, like the ships painted on old pots.
	for end in [1.0, -1.0]:
		Paper.part(hull, "Prow" if end > 0.0 else "Stern", Paper.cylinder(1.95, 1.7, 3), HULL.lightened(0.04),
				Vector3(end * (DECK_SIZE.x * 0.5 + 0.55), -0.95, 0.0), Vector3(0.0, (PI / 6.0) if end > 0.0 else -(PI / 6.0) + PI, 0.0), Vector3(0.55, 1.0, 1.0))
		Paper.part(hull, "Post", Paper.cylinder(0.12, 1.6, 6, 0.06), WOOD, Vector3(end * (DECK_SIZE.x * 0.5 + 1.25), 0.2, 0.0), Vector3(0.0, 0.0, -end * 0.35))
	# A painted band and an eye near the bow, as sailors then painted on their ships.
	Paper.part(hull, "Band", Paper.box(Vector3(DECK_SIZE.x + 0.02, 0.18, DECK_SIZE.y + 0.34)), GOLD.darkened(0.2), Vector3(0.0, -0.35, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
	Paper.part(hull, "Deck", Paper.box(Vector3(DECK_SIZE.x, 0.12, DECK_SIZE.y)), DECK, Vector3(0.0, -0.06, 0.0), Vector3.ZERO, Vector3.ONE, 0.015)
	for i in 9:
		Paper.part(hull, "Plank%d" % i, Paper.box(Vector3(DECK_SIZE.x - 0.1, 0.005, 0.02)), DECK.darkened(0.14), Vector3(0.0, 0.003, -DECK_SIZE.y * 0.5 + 0.4 * (i + 0.5)),
				Vector3.ZERO, Vector3.ONE, 0.0)
	# The rail: posts and a top rail all round, high enough that nobody could fall over.
	for side in [-1.0, 1.0]:
		Paper.part(ship, "Rail", Paper.box(Vector3(DECK_SIZE.x, 0.1, 0.1)), WOOD, Vector3(0.0, 1.0, side * DECK_SIZE.y * 0.5))
		Paper.part(ship, "Bulwark", Paper.box(Vector3(DECK_SIZE.x, 0.5, 0.08)), HULL.lightened(0.1), Vector3(0.0, 0.25, side * DECK_SIZE.y * 0.5))
		for k in 9:
			Paper.part(ship, "RailPost", Paper.cylinder(0.04, 1.0, 5), WOOD, Vector3(-DECK_SIZE.x * 0.5 + 0.5 + k * 1.125, 0.5, side * DECK_SIZE.y * 0.5), Vector3.ZERO, Vector3.ONE, 0.01)
	# The low cabin at the stern.
	Paper.part(ship, "Cabin", Paper.box(Vector3(1.2, 1.1, DECK_SIZE.y - 0.3)), LIMESTONE.darkened(0.1), Vector3(-DECK_SIZE.x * 0.5 + 0.6, 0.55, 0.0))
	Paper.part(ship, "CabinRoof", Paper.box(Vector3(1.4, 0.1, DECK_SIZE.y - 0.1)), WOOD.lightened(0.1), Vector3(-DECK_SIZE.x * 0.5 + 0.6, 1.15, 0.0))
	Paper.part(ship, "CabinDoor", Paper.box(Vector3(0.05, 0.8, 0.6)), Color(0.3, 0.2, 0.12), Vector3(-DECK_SIZE.x * 0.5 + 1.22, 0.4, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
	# The steering oar over the stern.
	Paper.part(ship, "SteeringOar", Paper.cylinder(0.06, 2.6, 6), WOOD, Vector3(-DECK_SIZE.x * 0.5 - 0.3, 0.2, DECK_SIZE.y * 0.5 - 0.3), Vector3(0.0, 0.0, 0.9))
	# The mast, its yard and the square sail, which fills with the wind.
	var mast_at := Vector3(0.9, 0.0, 0.0)
	Paper.part(ship, "Mast", Paper.cylinder(0.13, 6.4, 7, 0.09), WOOD, mast_at + Vector3(0.0, 3.2, 0.0))
	_sail = Node3D.new()
	_sail.name = "SailRig"
	_sail.position = mast_at + Vector3(0.0, 5.6, 0.0)
	_sail.rotation.y = 0.55
	ship.add_child(_sail)
	Paper.part(_sail, "Yard", Paper.cylinder(0.06, 4.0, 6), WOOD, Vector3.ZERO, Vector3(PI * 0.5, 0.0, 0.0))
	Paper.part(_sail, "Sail", Paper.box(Vector3(0.05, 3.2, 3.7)), SAIL, Vector3(0.18, -1.65, 0.0), Vector3(0.0, 0.0, 0.08), Vector3(1.0, 1.0, 1.0))
	for k in 3:
		Paper.part(_sail, "SailSeam%d" % k, Paper.box(Vector3(0.06, 3.1, 0.03)), SAIL.darkened(0.08), Vector3(0.2, -1.65, -1.2 + k * 1.2), Vector3(0.0, 0.0, 0.08), Vector3.ONE, 0.0)
	for side in [-1.0, 1.0]:
		var stay := Paper.part(ship, "Stay", Paper.cylinder(0.018, 6.3, 4), ROPE, mast_at + Vector3(side * 2.4, 3.0, 0.0), Vector3(0.0, 0.0, side * 0.72), Vector3.ONE, 0.0)
		stay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if walkable:
		_solid(ship, "DeckBody", Vector3(DECK_SIZE.x, 0.4, DECK_SIZE.y), Vector3(0.0, -0.2, 0.0))
		for side in [-1.0, 1.0]:
			_solid(ship, "RailBody", Vector3(DECK_SIZE.x + 1.0, 2.0, 0.3), Vector3(0.0, 1.0, side * (DECK_SIZE.y * 0.5 + 0.1)))
			_solid(ship, "EndBody", Vector3(0.3, 2.0, DECK_SIZE.y), Vector3(side * (DECK_SIZE.x * 0.5 + 0.1), 1.0, 0.0))
		_solid(ship, "CabinBody", Vector3(1.3, 1.2, DECK_SIZE.y), Vector3(-DECK_SIZE.x * 0.5 + 0.6, 0.6, 0.0))
		_solid(ship, "MastBody", Vector3(0.35, 2.0, 0.35), mast_at + Vector3(0.0, 1.0, 0.0))
	return ship


func _build_at_sea(root: Node3D) -> void:
	_ship(root, "Ship", Vector3.ZERO, true)
	_sea = JonahSea.new()
	_sea.name = "Sea"
	_sea.size = Vector2(240.0, 240.0)
	_sea.position = Vector3(0.0, -1.1, -40.0)
	_sea.calm_colours = [Color(0.14, 0.42, 0.56), Color(0.22, 0.54, 0.64), Color(0.44, 0.72, 0.78)]
	_sea.bands = [
		{"at": Vector3(-6.0, 0.0, 35.0), "length": 26.0, "height": 0.7, "speed": 0.42},
		{"at": Vector3(8.0, 0.0, 30.0), "length": 30.0, "height": 0.9, "speed": 0.33},
		{"at": Vector3(-2.0, 0.0, 24.0), "length": 36.0, "height": 1.1, "speed": 0.27},
		{"at": Vector3(3.0, 0.0, 45.5), "length": 34.0, "height": 0.4, "speed": 0.36},
	]
	root.add_child(_sea)
	_fish = GreatFish.new()
	_fish.name = "GreatFish"
	_fish.position = FISH_RISE
	_fish.rotation.y = -0.3
	root.add_child(_fish)
	# The great wave that rises at the ship's side when Jonah goes into the sea.
	_cover_wave = JonahSea.wave_band(9.0, 1.5, Color(0.28, 0.4, 0.5))
	_cover_wave.name = "CoverWave"
	_cover_wave.position = COVER_WAVE
	root.add_child(_cover_wave)
	for piece in CARGO:
		var node := _spot_area(piece, CARGO_REACH)
		root.add_child(node)
		node.position = CARGO[piece]["at"]
		node.rotation.y = randf_range(-0.5, 0.5)
		match piece:
			"Jar":
				Paper.part(node, "Jar", Paper.cylinder(0.26, 0.8, 9, 0.16), TERRACOTTA, Vector3(0.0, 0.4, 0.0))
				Paper.part(node, "Neck", Paper.cylinder(0.1, 0.18, 8, 0.12), TERRACOTTA.darkened(0.1), Vector3(0.0, 0.88, 0.0))
			"Sack":
				Paper.part(node, "Sack", Paper.sphere(0.36, 8), Color(0.82, 0.72, 0.52), Vector3(0.0, 0.3, 0.0), Vector3.ZERO, Vector3(1.2, 0.85, 0.9))
				Paper.part(node, "Tie", Paper.cylinder(0.1, 0.12, 6), ROPE.darkened(0.2), Vector3(0.0, 0.6, 0.0))
			"Rope":
				for k in 4:
					Paper.part(node, "Coil%d" % k, Paper.cylinder(0.34 - k * 0.02, 0.07, 12, 0.34 - k * 0.02), ROPE.darkened(0.05 * (k % 2)), Vector3(0.0, 0.04 + k * 0.07, 0.0),
							Vector3.ZERO, Vector3.ONE, 0.01)
		_cargo[piece] = node
		var spot := _spot_area(piece + "Space", SPOT_REACH)
		root.add_child(spot)
		spot.position = CARGO[piece]["spot"] + Vector3(0.0, 0.03, 0.0)
		# A dashed outline of the piece's own shape: a square for the sack, rings for the others.
		var dashes := 14
		for k in dashes:
			var a := TAU * float(k) / float(dashes)
			var at := Vector3(cos(a) * 0.42, 0.0, sin(a) * 0.42)
			if piece == "Sack":
				var sq := Vector3(clampf(cos(a) * 0.6, -0.42, 0.42), 0.0, clampf(sin(a) * 0.6, -0.42, 0.42))
				at = sq
			Paper.part(spot, "Dash%d" % k, Paper.box(Vector3(0.14, 0.02, 0.05)), GOLD, at, Vector3(0.0, -a + PI * 0.5, 0.0), Vector3.ONE, 0.0)
		spot.visible = false
		_spots[piece] = spot


## The inside of the great fish, as a calm paper chamber: a curved dry platform, deep indigo
## paper curving over it in layers, a few slow motes of light and one warm glow. No ribs, no
## teeth, nothing of a stomach: just a protected blue place.
func _build_deep(root: Node3D) -> void:
	_floor(root, "Platform", Vector2(4.4, 3.0), Vector3(0.0, 0.0, 0.0), Color(0.86, 0.8, 0.64))
	Paper.part(root, "PlatformCurve", Paper.cylinder(2.5, 0.4, 16), Color(0.8, 0.74, 0.58), Vector3(0.0, -0.22, 0.0), Vector3.ZERO, Vector3(1.0, 1.0, 0.7))
	var dome := MeshInstance3D.new()
	dome.name = "Dome"
	var shell := SphereMesh.new()
	shell.radius = 7.0
	shell.height = 9.0
	shell.radial_segments = 24
	shell.rings = 12
	dome.mesh = shell
	var inside := StandardMaterial3D.new()
	inside.albedo_color = INDIGO
	inside.cull_mode = BaseMaterial3D.CULL_FRONT
	inside.roughness = 1.0
	inside.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	dome.material_override = inside
	dome.position = Vector3(0.0, 1.0, 0.0)
	root.add_child(dome)
	# Layers of paper arching over, turquoise to indigo, like the edges of torn paper.
	for i in 5:
		var arch := Node3D.new()
		arch.name = "Arch%d" % i
		arch.position = Vector3(-3.2 + i * 1.6, 0.0, -2.6 - absf(i - 2) * 0.4)
		root.add_child(arch)
		var colour := Color(0.24, 0.46, 0.56).lerp(INDIGO, float(i % 3) * 0.3)
		for k in 9:
			var a := PI * float(k) / 8.0
			Paper.part(arch, "Piece%d" % k, Paper.box(Vector3(0.9, 0.5, 0.08)), colour, Vector3(cos(a) * 3.4, sin(a) * 3.4 - 0.3, 0.0), Vector3(0.0, 0.0, a + PI * 0.5), Vector3.ONE, 0.015)
	var motes := CPUParticles3D.new()
	motes.name = "Motes"
	motes.amount = 26
	motes.lifetime = 7.0
	motes.preprocess = 7.0
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	motes.emission_box_extents = Vector3(4.0, 0.5, 2.0)
	motes.position = Vector3(0.0, 0.2, -0.6)
	motes.direction = Vector3.UP
	motes.gravity = Vector3.ZERO
	motes.initial_velocity_min = 0.12
	motes.initial_velocity_max = 0.3
	var dot := QuadMesh.new()
	dot.size = Vector2(0.06, 0.06)
	var dot_mat := StandardMaterial3D.new()
	dot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dot_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dot_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dot_mat.albedo_color = Color(0.7, 0.9, 1.0, 0.6)
	dot.material = dot_mat
	motes.mesh = dot
	root.add_child(motes)
	_deep_light = OmniLight3D.new()
	_deep_light.name = "WarmGlow"
	_deep_light.light_color = Color(1.0, 0.82, 0.5)
	_deep_light.light_energy = 1.6
	_deep_light.omni_range = 7.0
	_deep_light.position = Vector3(0.4, 2.4, 1.2)
	root.add_child(_deep_light)


func _build_land(root: Node3D) -> void:
	_floor(root, "Ground", Vector2(30.0, 22.0), Vector3(2.0, 0.0, -0.5), Color(0.86, 0.76, 0.56), _stone_material(Color(0.86, 0.76, 0.56), 707, 12.0))
	# The shore: pale sand at the water's edge, then the shallows the fish comes into.
	Paper.part(root, "Sand", Paper.box(Vector3(6.0, 0.04, 22.0)), SAND, Vector3(-10.0, 0.01, -0.5), Vector3.ZERO, Vector3.ONE, 0.0)
	Paper.part(root, "WetSand", Paper.box(Vector3(1.6, 0.03, 22.0)), SAND.darkened(0.12), Vector3(-12.2, 0.0, -0.5), Vector3.ZERO, Vector3.ONE, 0.0)
	_solid(root, "ShoreEdge", Vector3(0.6, 3.0, 22.0), Vector3(-13.3, 1.5, -0.5))
	for shell in [Vector3(-9.0, 0.0, 3.2), Vector3(-10.4, 0.0, -2.4), Vector3(-8.6, 0.0, -4.6), Vector3(-11.2, 0.0, 5.0)]:
		Paper.part(root, "Shell", Paper.sphere(0.12, 6), Color(0.98, 0.9, 0.86), shell + Vector3(0.0, 0.04, 0.0), Vector3(0.0, shell.x, 0.0), Vector3(1.0, 0.4, 0.8), 0.008)
	_shore_sea = JonahSea.new()
	_shore_sea.name = "ShoreSea"
	_shore_sea.size = Vector2(200.0, 240.0)
	_shore_sea.position = Vector3(-113.2, -0.7, -20.0)
	_shore_sea.calm_colours = [Color(0.2, 0.52, 0.56), Color(0.34, 0.66, 0.66), Color(0.56, 0.84, 0.8)]
	_shore_sea.bands = [{"at": Vector3(94.0, 0.0, 30.0), "length": 12.0, "height": 0.3, "speed": 0.4}]
	root.add_child(_shore_sea)
	_shore_wave = JonahSea.wave_band(6.0, 0.9, Color(0.36, 0.66, 0.66))
	_shore_wave.name = "ShoreWave"
	_shore_wave.position = SHORE_WAVE
	_shore_wave.rotation.y = PI * 0.5
	root.add_child(_shore_wave)
	_shore_fish = GreatFish.new()
	_shore_fish.name = "ShoreFish"
	_shore_fish.position = SHORE_FISH
	_shore_fish.rotation.y = PI * 0.1
	root.add_child(_shore_fish)
	# The road from the shore to Nineveh's gate.
	var patches: Array[Transform3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 7071
	for i in 16:
		var t := float(i) / 15.0
		var at := Vector3(-7.4, 0.0, 0.8).lerp(GATE + Vector3(-0.8, 0.0, 0.0), t) + Vector3(0.0, 0.014, sin(t * PI * 1.4) * 0.6)
		patches.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(rng.randf_range(1.5, 2.0), 1.0, rng.randf_range(1.1, 1.4))), at))
	_scatter(root, "Road", Paper.cylinder(0.6, 0.02, 9), patches, [Color(0.8, 0.66, 0.48), Color(0.76, 0.62, 0.44)])
	# The rolled message, lying open on the sand once Jonah is ashore.
	_message = Node3D.new()
	_message.name = "OpenMessage"
	_message.position = Vector3(-6.2, 0.05, 2.0)
	root.add_child(_message)
	Paper.part(_message, "Sheet", Paper.box(Vector3(0.7, 0.02, 0.45)), Color(0.97, 0.92, 0.78), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, 0.01)
	for side in [-1.0, 1.0]:
		Paper.part(_message, "Roll", Paper.cylinder(0.05, 0.47, 8), Color(0.92, 0.86, 0.7), Vector3(side * 0.36, 0.04, 0.0), Vector3(PI * 0.5, 0.0, 0.0))
	for k in 3:
		Paper.part(_message, "Line%d" % k, Paper.box(Vector3(0.44, 0.005, 0.02)), Color(0.4, 0.28, 0.16), Vector3(0.0, 0.012, -0.12 + k * 0.12), Vector3.ZERO, Vector3.ONE, 0.0)
	var glow := Paper.halo(1.0, Color(1.0, 0.86, 0.5, 0.5))
	glow.position = Vector3(0.0, 0.3, 0.0)
	_message.add_child(glow)
	_message.scale = Vector3.ONE * 0.05
	_message.visible = false
	_gate_ring = _ring(root, "GateRing", GATE_SPOT, 0.8)
	_nineveh(root)
	_hill(root)
	_crowd = NinevehCrowd.new()
	_crowd.name = "NinevehCrowd"
	_crowd.position = CROWD_AT
	root.add_child(_crowd)


## Nineveh: a wall of rose limestone with a tall gate, towers either side, flat roofs rising
## behind, faded blue cloth shades over the square outside the gate, and clay water jars. A real
## city of families, not a dark or monstrous place.
func _nineveh(root: Node3D) -> void:
	var city := Node3D.new()
	city.name = "Nineveh"
	root.add_child(city)
	for run in [[-11.0, -1.4], [2.4, 11.0]]:
		var z0: float = run[0]
		var z1: float = run[1]
		var at := Vector3(GATE.x, 1.8, (z0 + z1) * 0.5)
		Paper.part(city, "Wall", Paper.box(Vector3(0.9, 3.6, z1 - z0)), ROSE, at)
		_solid(city, "WallBody", Vector3(1.2, 3.6, z1 - z0), at)
		var n := int((z1 - z0) / 1.1)
		for k in n:
			Paper.part(city, "Merlon", Paper.box(Vector3(0.9, 0.4, 0.55)), ROSE.darkened(0.06), Vector3(GATE.x, 3.8, z0 + 0.55 + k * 1.1), Vector3.ZERO, Vector3.ONE, 0.012)
	for side in [-1.0, 1.0]:
		var tower := Vector3(GATE.x, 2.4, GATE.z + side * 2.4)
		Paper.part(city, "Tower", Paper.box(Vector3(1.7, 4.8, 1.5)), ROSE.lightened(0.05), tower)
		Paper.part(city, "TowerTop", Paper.box(Vector3(1.9, 0.3, 1.7)), ROSE.darkened(0.08), tower + Vector3(0.0, 2.55, 0.0))
		_solid(city, "TowerBody", Vector3(1.8, 4.8, 1.6), tower)
	Paper.part(city, "Lintel", Paper.box(Vector3(1.1, 0.7, 3.4)), ROSE.darkened(0.04), Vector3(GATE.x, 3.35, GATE.z))
	Paper.part(city, "Gateway", Paper.box(Vector3(0.1, 3.0, 2.9)), Color(0.36, 0.26, 0.2), Vector3(GATE.x + 0.3, 1.5, GATE.z), Vector3.ZERO, Vector3.ONE, 0.0)
	_solid(city, "GateBody", Vector3(0.6, 3.0, 3.0), Vector3(GATE.x + 0.4, 1.5, GATE.z))
	# Roofs of the city behind the wall, stepping up away from it.
	var houses: Array[Transform3D] = []
	var tints: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 7072
	for i in 26:
		var at := Vector3(GATE.x + rng.randf_range(1.6, 11.0), 0.0, rng.randf_range(-11.0, 11.0))
		var size := Vector3(rng.randf_range(1.8, 3.0), rng.randf_range(3.2, 6.0) + (at.x - GATE.x) * 0.2, rng.randf_range(1.8, 3.0))
		houses.append(Transform3D(Basis.from_scale(size), at + Vector3(0.0, size.y * 0.5, 0.0)))
		tints.append([ROSE, ROSE.lightened(0.1), Color(0.94, 0.88, 0.76), ROSE.darkened(0.06)][i % 4])
	_scatter(root, "CityHouses", Paper.box(Vector3.ONE), houses, tints)
	# Cloth shades over the square, on poles, and water jars.
	for shade in [Vector3(9.4, 0.0, -3.4), Vector3(11.4, 0.0, 4.6), Vector3(8.4, 0.0, 5.6)]:
		for post in [Vector3(-0.9, 0.0, -0.7), Vector3(0.9, 0.0, -0.7), Vector3(-0.9, 0.0, 0.7), Vector3(0.9, 0.0, 0.7)]:
			Paper.part(city, "ShadePost", Paper.cylinder(0.05, 2.3, 6), WOOD, shade + post + Vector3(0.0, 1.15, 0.0), Vector3.ZERO, Vector3.ONE, 0.01)
		Paper.part(city, "Shade", Paper.box(Vector3(2.1, 0.05, 1.7)), FADED_BLUE, shade + Vector3(0.0, 2.3, 0.0), Vector3(0.1, 0.0, 0.0), Vector3.ONE, 0.012)
	for jar in [Vector3(12.6, 0.0, -1.8), Vector3(12.9, 0.0, -2.5), Vector3(12.5, 0.0, 3.0)]:
		Paper.part(city, "Jar", Paper.cylinder(0.25, 0.72, 9, 0.15), TERRACOTTA, jar + Vector3(0.0, 0.36, 0.0))


## The little hill outside the city where Jonah sits, with the plant beside him.
func _hill(root: Node3D) -> void:
	var hill := Node3D.new()
	hill.name = "ShadeHill"
	hill.position = HILL
	root.add_child(hill)
	for k in 3:
		var r := 3.6 - k * 1.0
		Paper.part(hill, "Rise%d" % k, Paper.cylinder(r, HILL_TOP / 3.0, 14, r * 0.92), Color(0.78, 0.7, 0.48).darkened(0.03 * k),
				Vector3(0.0, HILL_TOP / 3.0 * (k + 0.5), 0.0), Vector3.ZERO, Vector3(1.0, 1.0, 0.8), 0.02)
	_solid(hill, "HillBody", Vector3(5.4, HILL_TOP * 2.0, 4.4), Vector3(0.0, 0.0, 0.0))
	_plant = ShadePlant.new()
	_plant.name = "ShadePlant"
	root.add_child(_plant)
	_plant.position = PLANT_AT


## An area the golden arrow can point at (wonder_item_hints.gd follows Area3D nodes): a thing
## to find or carry, or a space to carry it to. Nothing detects it; the story measures distances.
func _spot_area(area_name: String, radius: float) -> Area3D:
	var area := Area3D.new()
	area.name = area_name
	area.monitoring = false
	area.monitorable = false
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	area.add_child(shape)
	return area


## A dashed gold ring on the ground, the "go here" of the whole game (the courtyard's rings).
func _ring(parent: Node3D, ring_name: String, at: Vector3, radius: float) -> Area3D:
	var ring := _spot_area(ring_name, radius)
	parent.add_child(ring)
	ring.position = at + Vector3(0.0, 0.04, 0.0)
	for k in 16:
		var a := TAU * float(k) / 16.0
		Paper.part(ring, "Dash%d" % k, Paper.box(Vector3(0.22, 0.02, 0.06)), GOLD, Vector3(cos(a) * radius, 0.0, sin(a) * radius),
				Vector3(0.0, -a + PI * 0.5, 0.0), Vector3.ONE, 0.0)
	ring.visible = false
	return ring


## Many copies of one small mesh in one draw call, each with its own colour from `tints`.
func _scatter(parent: Node3D, scatter_name: String, mesh: Mesh, where: Array[Transform3D], tints: Array) -> MultiMeshInstance3D:
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
	mat.vertex_color_is_srgb = true
	mat.roughness = 1.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	var mmi := MultiMeshInstance3D.new()
	mmi.name = scatter_name
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)
	return mmi


func _gull() -> Node3D:
	var gull := Node3D.new()
	for side in [-1.0, 1.0]:
		var wing := Node3D.new()
		gull.add_child(wing)
		Paper.part(wing, "Wing", Paper.box(Vector3(0.7, 0.03, 0.22)), Color(0.96, 0.96, 0.94), Vector3(side * 0.35, 0.0, 0.0), Vector3.ZERO, Vector3.ONE, 0.01)
		Paper.part(wing, "Tip", Paper.box(Vector3(0.2, 0.035, 0.2)), Color(0.3, 0.3, 0.32), Vector3(side * 0.62, 0.0, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
	Paper.part(gull, "Body", Paper.sphere(0.12, 6), Color(0.98, 0.98, 0.96), Vector3.ZERO, Vector3.ZERO, Vector3(0.9, 0.8, 1.9), 0.01)
	return gull


## Jonah, the captain and his two sailors. Jonah goes from place to place with the story; the
## crew are on the moored ship at Joppa and on deck at sea.
func _people() -> void:
	# Jonah belongs to no one place: he goes where the story goes.
	_jonah = _person("jonah", "Jonah", self, JONAH_JOPPA)
	face(_jonah, MOORED)
	_captain = _person("captain", "Captain", _roots["sea"], AT_SEA + CAPTAIN_AT)
	var deckhand := _person("deckhand", "DeckHand", _roots["sea"], AT_SEA + DECKHAND_AT)
	var ropeman := _person("ropeman", "RopeHandler", _roots["sea"], AT_SEA + ROPEMAN_AT)
	_crew = [_captain, deckhand, ropeman] as Array[Node3D]
	for member in _crew:
		face(member, AT_SEA + JONAH_AT_SEA)
		_glance.append(randf_range(1.0, 4.0))
	# A coil of rope on the rope-handler's shoulder.
	var coil := Node3D.new()
	coil.name = "ShoulderCoil"
	for k in 3:
		Paper.part(coil, "Loop%d" % k, Paper.cylinder(0.1, 0.02, 10, 0.1), ROPE, Vector3(0.0, k * 0.02, 0.0), Vector3(PI * 0.5, 0.0, 0.0), Vector3.ONE, 0.004)
	ropeman.attach("UpperArm_L", coil)
	# Two sailors on the quay and deck at Joppa, getting the ship ready (the crew's harbour selves).
	var quay_hand := _person("deckhand", "QuayHand", _roots["joppa"], Vector3(3.2, 0.0, -4.8))
	face(quay_hand, MOORED)
	var quay_rope := _person("ropeman", "QuayRopeHandler", _roots["joppa"], Vector3(8.2, 0.0, -4.7))
	face(quay_rope, Vector3(9.0, 0.0, -5.5))
	var deck_captain := _person("captain", "DeckCaptain", _roots["joppa"], MOORED + Vector3(2.6, MOORED_DECK, 0.4))
	face(deck_captain, GANGWAY_FOOT)


## Who each person is: which model (story_person.gd) and its colours. Jonah in dusty indigo
## over muted ochre; the sailors in sea green, cream and rust, the captain grey-haired.
const CAST := {
	"jonah": {"model": "brother", "height": 1.02,
			"tint": {"Tunic": Color(0.4, 0.44, 0.66), "UnderTunic": Color(0.84, 0.66, 0.36), "Sash": Color(0.78, 0.58, 0.3), "Hair": Color(0.18, 0.12, 0.08)}},
	"captain": {"model": "brother", "height": 1.0,
			"tint": {"Tunic": Color(0.42, 0.62, 0.56), "UnderTunic": Color(0.9, 0.86, 0.74), "Sash": Color(0.7, 0.4, 0.26), "Hair": Color(0.66, 0.64, 0.6)}},
	"deckhand": {"model": "brother_young", "height": 0.98,
			"tint": {"Tunic": Color(0.76, 0.44, 0.28), "UnderTunic": Color(0.88, 0.84, 0.72), "Sash": Color(0.42, 0.58, 0.52), "Hair": Color(0.2, 0.13, 0.08)}},
	"ropeman": {"model": "brother", "height": 1.04,
			"tint": {"Tunic": Color(0.9, 0.84, 0.7), "UnderTunic": Color(0.44, 0.6, 0.54), "Sash": Color(0.74, 0.4, 0.26), "Hair": Color(0.14, 0.1, 0.07)}},
}


func _person(role: String, node_name: String, parent: Node3D, at: Vector3) -> Node3D:
	var spec: Dictionary = CAST[role]
	var person := Node3D.new()
	person.name = node_name
	person.set_script(StoryPerson)
	person.who = spec["model"]
	parent.add_child(person)
	person.global_position = at
	person.scale = Vector3.ONE * float(spec["height"])
	person.tint(spec["tint"])
	return person
