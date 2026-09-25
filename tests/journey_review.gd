extends SceneTree
## Headless pass over moving between the stories: every chapter entered from the Faith
## Journey map, "Play again" in every chapter as a real scene reload, and switching from
## one story to another, with nothing of the story left behind on screen.
## The safety net for moving chapter switching into one place (see docs/development.md).
##
##   godot --headless --path . --script tests/journey_review.gd
##
## The main scene is made the tree's current scene, so "Play again" and the valley's
## map stop reload it exactly as the game does.
const Profiles := preload("res://scripts/profiles.gd")
const Settings := preload("res://scripts/game_settings.gd")

const PROFILE_FILE := "res://.godot/journey-review-profile.cfg"

var failures: int = 0
var main: Node


func _initialize() -> void:
	DirAccess.remove_absolute(PROFILE_FILE)
	Profiles.use_file(PROFILE_FILE)
	Profiles.set_active(Profiles.create("Journey Review", "star"))
	Profiles.current_chapter = ""
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	_run.call_deferred()


func check(ok: bool, label: String) -> void:
	print("OK " if ok else "FAIL ", label)
	if not ok:
		failures += 1


func settle(frames: int = 5) -> void:
	for _i in frames:
		await process_frame


## Waits for a reload to replace the main scene, then for the new one to start its story.
func reloaded() -> void:
	var old := main
	for _i in 120:
		await process_frame
		if current_scene != null and current_scene != old and current_scene.is_inside_tree():
			break
	main = current_scene
	await settle(8)
	quiet()


func quiet() -> void:
	Settings.read_aloud = false
	# A map stop that reloads (the valley) has already freed this scene; reloaded() picks up the new one.
	if not is_instance_valid(main) or not main.is_inside_tree():
		return
	var audio := main.get_node_or_null("AudioDirector")
	if audio:
		audio.stop_speech()


func map_stop(stop_id: String) -> void:
	var journey: Node = main.get_node("FaithJourney")
	if not journey.is_open():
		journey.open()
	journey._on_stop(stop_id)
	await settle()
	quiet()


func camp_story() -> Node:
	return main.get_node_or_null("KingsCamp/ChapterTwo")


func ark_story() -> Node:
	return main.get_node_or_null("NoahsArk/ChapterFour")


## True when the shared world is dressed exactly as `look` says (chapter_look.gd): sky,
## air, lights, the backdrop of hills, night sounds and the tabletop camera's framing.
func looks_like(look: Resource) -> bool:
	var env: Environment = (main.get_node("WorldEnvironment") as WorldEnvironment).environment
	var sky := env.sky.sky_material as ProceduralSkyMaterial
	var sun := main.get_node("Sun") as DirectionalLight3D
	var fill := main.get_node("FillLight") as DirectionalLight3D
	var cam := main.get_node("TabletopCamera") as Camera3D
	var backdrop := main.get_node("HorizonBackdrop") as Node3D
	return sky.sky_top_color.is_equal_approx(look.sky_top) and sky.ground_bottom_color.is_equal_approx(look.ground_bottom) 			and env.ambient_light_color.is_equal_approx(look.ambient_color) and is_equal_approx(env.fog_density, look.fog_density) 			and sun.light_color.is_equal_approx(look.sun_color) and is_equal_approx(sun.light_energy, look.sun_energy) 			and fill.light_color.is_equal_approx(look.fill_color) and is_equal_approx(fill.light_energy, look.fill_energy) 			and backdrop.visible == (look.backdrop != "hidden") and main.get_node("Soundscape")._night == look.night 			and cam.offset.is_equal_approx(look.camera_offset) and is_equal_approx(cam.fov, look.camera_fov)


## True when PlayBounds keeps the walker in `area` (play_area.gd) and the walker is inside it,
## a few physics steps after the story put them there.
func kept_in(area: Resource) -> bool:
	var bounds: Node = main.get_node("PlayBounds")
	var player := main.get_node("Player") as Node3D
	var at: Vector2 = Vector2(player.global_position.x, player.global_position.z) - bounds.center
	return bounds.center.is_equal_approx(area.center) and bounds.half_extents.is_equal_approx(area.half_extents) 			and bounds._edge_info(at)["sd"] <= 0.0


## How many of the UI's own children are named like `pattern` and showing.
func showing(pattern: String) -> int:
	var n := 0
	for node in main.get_node("UI").find_children(pattern, "", false, false):
		if (node as CanvasItem).visible:
			n += 1
	return n


func _run() -> void:
	await settle()
	quiet()
	var director: Node = main.get_node("ChapterDirector")
	var journey: Node = main.get_node("FaithJourney")
	check(journey.is_open() and journey._choosing, "with a child chosen, the game opens on the Faith Journey map")

	print("-- the valley from the map, at the start --")
	await map_stop("valley")
	check(director.beat == director.Beat.ARRIVE and Profiles.current_chapter == Profiles.CHAPTER_VALLEY,
			"tapping the valley starts chapter 1 in place")
	var kid := Profiles.active_id
	Profiles.finish_chapter(Profiles.CHAPTER_VALLEY)
	Profiles.finish_chapter(Profiles.CHAPTER_CAMP)
	check(Profiles.is_unlocked(kid, Profiles.CHAPTER_ARK), "finishing the valley and the camp opens every story")

	print("-- the camp from the map, mid-valley --")
	await map_stop("camp")
	check(camp_story() != null and camp_story().phase == camp_story().Phase.ARRIVE and Profiles.current_chapter == Profiles.CHAPTER_CAMP,
			"the camp starts from its first line")
	check(director.beat == director.Beat.CAMP, "the valley's story stands down for the camp")
	check(looks_like(main.get_node("KingsCamp").look), "the world takes the camp's look: blue hour, night sounds")
	await settle(10)
	check(kept_in(main.get_node("KingsCamp").play_area), "the walker is kept to the camp's play area")

	print("-- the ark from the map, mid-camp --")
	await map_stop("ark")
	check(ark_story() != null and ark_story().phase == ark_story().Phase.ARRIVE and Profiles.current_chapter == Profiles.CHAPTER_ARK,
			"the ark starts from its first line")
	check(camp_story().phase == camp_story().Phase.IDLE and showing("Camp*") == 0,
			"the camp's story stops, and none of its cards stay on screen")
	check(looks_like(main.get_node("NoahsArk").look), "the world takes the ark's look: daylight, no hills, its own framing")
	await settle(10)
	check(kept_in(main.get_node("NoahsArk").play_area), "the walker is kept to the ark's play area, far from the valley")
	# Leave the ark mid-rain: its crossfade must not keep painting over the next story.
	main.get_node("NoahsArk").set_weather("rain")

	print("-- Play again in the ark --")
	main.get_node("GameMenu")._restart()
	await reloaded()
	check(ark_story() != null and ark_story().phase == ark_story().Phase.ARRIVE and Profiles.current_chapter == Profiles.CHAPTER_ARK,
			"Play again reloads straight back into the ark's first line")
	check(main.get_node("UI").find_children("ArkWords*", "", false, false).size() == 1, "with one set of the ark's word chips")
	check(looks_like(main.get_node("NoahsArk").look), "and in the ark's look")
	main.get_node("NoahsArk").set_weather("rain")

	print("-- the camp from the map, mid-ark, then Play again --")
	await map_stop("camp")
	check(camp_story().phase == camp_story().Phase.ARRIVE and not main.get_node("NoahsArk")._built and showing("Ark*") == 0,
			"the camp starts, the ark is put away, and none of its cards stay on screen")
	await create_timer(0.6).timeout
	check(looks_like(main.get_node("KingsCamp").look), "left mid-rain, the ark's weather gives way to the camp's whole look")
	main.get_node("GameMenu")._restart()
	await reloaded()
	check(camp_story().phase == camp_story().Phase.ARRIVE and Profiles.current_chapter == Profiles.CHAPTER_CAMP,
			"Play again reloads straight back into the camp's first line")

	print("-- the valley from the map, mid-camp --")
	await map_stop("valley")
	await reloaded()
	director = main.get_node("ChapterDirector")
	check(director.beat == director.Beat.ARRIVE and Profiles.current_chapter == Profiles.CHAPTER_VALLEY,
			"the valley reloads the scene and starts chapter 1 from its first line")
	check(looks_like(director.look), "in the valley's daylight")
	check(kept_in(director.play_area), "and kept to the valley's play area")
	check(camp_story() == null or camp_story().phase == camp_story().Phase.IDLE, "and the camp is not running behind it")
	check(not main.get_node("NoahsArk")._built, "and the ark is not built")

	print("-- Play again in the valley --")
	main.get_node("GameMenu")._restart()
	await reloaded()
	director = main.get_node("ChapterDirector")
	check(director.beat == director.Beat.ARRIVE and Profiles.current_chapter == Profiles.CHAPTER_VALLEY,
			"Play again reloads straight back into the valley's first line")

	quiet()
	await create_timer(0.3).timeout
	DirAccess.remove_absolute(PROFILE_FILE)
	print("JOURNEY REVIEW %s" % ("PASSED" if failures == 0 else "FAILED"))
	quit(0 if failures == 0 else 1)
