extends SceneTree
## Captures the major Chapter 1 beats with the real renderer.
##
## Run from the project folder (not headless):
##   godot --path . --script tests/chapter_visual_review.gd --resolution 1280x720
##
## PNGs are written to `.godot/chapter-visual-review/`. A scratch profile is
## used, so this never changes the children or journals saved on the device.

const Profiles := preload("res://scripts/profiles.gd")

const OUTPUT_DIR := "res://.godot/chapter-visual-review"
const PROFILE_FILE := "res://.godot/chapter-visual-review-profile.cfg"

var _main: Node
var _director: Node
var _steady: Node


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	Profiles.use_file(PROFILE_FILE)
	var id := Profiles.create("Visual Review", "star")
	if id.is_empty():
		var saved: Array = Profiles.all()
		if not saved.is_empty():
			id = saved[0]["id"]
	Profiles.set_active(id)
	_main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(_main)
	_run.call_deferred()


func _run() -> void:
	# The shell loads the valley once the scene is ready, after this script's _initialize().
	_director = _main.get_node("Valley/ChapterDirector")
	_steady = _main.get_node("Valley/SteadyHands")
	await _settle(12)
	await _shot("01_arrive")

	_director._enter_beat(_director.Beat.EXPLORE)
	await _settle(8)
	await _shot("02_explore")

	var item_names := ["WonderItem_Stone", "WonderItem_Staff", "WonderItem_Lamb"]
	for i in item_names.size():
		_director._near_item = _main.get_node("Valley/WonderItems/" + item_names[i])
		_director._try_collect_near_item()
		await _settle(5)
		if i == 0:
			await _shot("03_first_item_checked")

	# The last item deliberately holds on this handoff before the close-up.
	await _shot("04_handoff_to_david")
	await _wait_for_dialogue("Oh! Hello there", 180)
	await _shot("05_meet_david")

	_director._enter_beat(_director.Beat.STEADY_INTRO)
	await _settle(6)
	await _shot("06_steady_intro")

	_director._enter_beat(_director.Beat.STEADY_PLAY)
	# Place the real minigame midway through an inhale for a representative frame.
	_steady.level = 0.62
	_steady.velocity = 0.2
	_steady._update_visuals()
	await _settle(5)
	await _shot("07_steady_hands")

	# Use the minigame's real finish path so its ring and dots fade away and the
	# director advances through the same signal used during normal play.
	_steady._finish_breath()
	await _wait_for_dialogue("I feel steady now", 120)
	await _shot("08_steady_done")

	_director._enter_beat(_director.Beat.RESOLUTION)
	await _settle(6)
	await _shot("09_resolution")

	_director._enter_beat(_director.Beat.REFLECT)
	await _settle(6)
	await _shot("10_reflect")

	_director._enter_beat(_director.Beat.VERSE_REWARD)
	await _settle(6)
	await _shot("11_verse")

	_director._enter_beat(_director.Beat.CHARM_AWARD)
	await _settle(55)
	await _shot("12_charm_award")

	_director._enter_beat(_director.Beat.DONE)
	await _settle(12)
	await _shot("13_complete")

	print("VISUAL REVIEW CAPTURED: ", ProjectSettings.globalize_path(OUTPUT_DIR))
	quit()


func _settle(frames: int) -> void:
	for _i in frames:
		await process_frame


func _wait_for_dialogue(fragment: String, max_frames: int) -> void:
	for _i in max_frames:
		if fragment in _director.dialogue_label.text:
			await _settle(6)
			return
		await process_frame
	push_error("Visual review timed out waiting for dialogue: %s" % fragment)


func _shot(file_stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := OUTPUT_DIR + "/" + file_stem + ".png"
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save visual-review frame: %s (%s)" % [path, error_string(error)])
