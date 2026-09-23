extends SceneTree
## Run headless for interaction checks, or with -- --visual for PNGs.
const Profiles := preload("res://scripts/profiles.gd")
const Settings := preload("res://scripts/game_settings.gd")
var failures: int = 0
var main: Node
var visual: bool = false

func _initialize() -> void:
	visual = "--visual" in OS.get_cmdline_user_args()
	DirAccess.remove_absolute("res://.godot/camp-review-profile.cfg")
	Profiles.use_file("res://.godot/camp-review-profile.cfg")
	Profiles.set_active(Profiles.create("Camp Review", "star"))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	print("OK " if ok else "FAIL ", label)
	if not ok:
		failures += 1

func settle(frames: int = 5) -> void:
	for i in frames:
		await process_frame

func shot(label: String) -> void:
	if not visual:
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/camp-" + label + ".png")

func _run() -> void:
	await settle()
	check(not paused, "scratch profile opens the game without the picker")
	Settings.read_aloud = false
	main.get_node("AudioDirector").stop_speech()
	var camp: Node = main.get_node("KingsCamp")
	camp.visit()
	await settle()
	var story: Node = camp.get_node("ChapterTwo")
	var player: Node3D = main.get_node("Player")
	var jon: Node3D = camp.get_node("Jonathan")
	var david: Node3D = main.get_node("DavidMentor")
	check("turning into night" in story._line.text, "arrival says night")
	check(not player.can_move, "arrival holds still so she sees the camp")
	check((-david.basis.z).dot((jon.position - camp.to_local(david.global_position)).normalized()) > 0.9, "David faces Jonathan")
	check((-jon.global_basis.z).dot((david.global_position - jon.global_position).normalized()) > 0.9, "Jonathan faces David")
	story._advance()
	await settle(100 if visual else 5)
	check(main.get_node("CameraDirector").is_orbiting() and not player.can_move, "dialogue frames Jonathan and locks walking")
	var camera: Node = main.get_node("CameraDirector")
	var camera_start: Vector3 = main.get_node("CloseUpCamera").position
	camera._orbit_angle += 0.5
	camera._place_closeup()
	check(main.get_node("CloseUpCamera").position.distance_to(camera_start) > 0.2, "look-around changes the view")
	camera._orbit_angle = 0
	camera._place_closeup()
	await shot("jonathan")
	check(jon._body.skin != null and jon._outline.skin != null, "organic body and outline are skinned")
	var elbow_at: Vector3 = jon._skeleton.get_bone_global_pose(jon._skeleton.find_bone("LowerArm_L")).origin
	var shoulder_at: Vector3 = jon._skeleton.get_bone_global_pose(jon._skeleton.find_bone("UpperArm_L")).origin
	check(elbow_at.y < shoulder_at.y - 0.08, "rest rotations keep relaxed arms below the shoulders")
	var left_arm: int = jon._skeleton.find_bone("LowerArm_L")
	var first_pose: Quaternion = jon._skeleton.get_bone_pose_rotation(left_arm)
	jon._talk = 1.0
	jon._process(0.05)
	check(not jon._skeleton.get_bone_pose_rotation(left_arm).is_equal_approx(first_pose), "conversation bends the sculpted elbow")
	jon._blink = -0.10
	jon._process(0.0)
	check(jon._body.get_blend_shape_value(jon._blink_shape) > 0.95, "sculpted eyes blink")
	jon._blink = 2.8

	check(david.get_node("CampConversation")._parts.size() == 2, "David and outline animate together")
	story._advance()
	check(player.can_move and story._checklist.visible, "hunt restores walking and shows checklist")
	story._on_gift(player, story.get_node("Bow"))
	story._on_gift(player, story.get_node("Bow"))
	check(story._found == 1 and "☑  Bow" in story._checks.text, "out-of-order pickup checks the right gift only once")
	await settle()
	await shot("checklist")
	story._on_gift(player, story.get_node("Robe"))
	story._on_gift(player, story.get_node("Belt"))
	check(story.phase == story.Phase.GIVE and story._found == 3, "three gifts enter handoff")
	check(camp.get_node("GivenGifts").get_child_count() == 3, "the gifts sit beside David")
	story._advance()
	check(story.phase == story.Phase.WORDS, "the tying words come before the cord")
	for i in [2, 0, 1]:
		story.press_word(i)
	check(story._words_done, "Knit, Loved, and Friend can be tapped in any order")
	story._advance()
	var cord: Control = story._cord
	var hold: float = cord.HOLD_SECONDS
	cord.set_process(false)
	cord.step(10.0, true)
	check(cord.progress == 0.0, "opening key cannot draw a loop")
	cord.step(30.0, false)
	cord.step(30.0, false)
	check(cord.loops == 0 and story.phase == story.Phase.CORD, "waiting cannot complete the activity")
	cord.step(hold * 0.5, true)
	cord.step(0.3, false)
	check(is_equal_approx(cord.progress, 0.5), "early release preserves progress")
	await settle()
	await shot("cord")
	cord.step(hold * 0.5 + 0.05, true)
	check(cord.ready_to_release and cord.loops == 0, "full loop waits for release")
	cord.step(0.1, false)
	for i in 2:
		cord.step(hold + 0.1, true)
		cord.step(0.1, false)
	check(story.phase == story.Phase.VERSE and cord.loops == 3 and camp.get_node_or_null("CordLoop2") != null, "three slow loops unlock the verse, and the cord is in the camp")
	story._advance()
	if story._ceremony:
		story._on_charm_sealed()
	story._advance()
	check(player.can_move and not story._checklist.visible, "ending restores exploration")
	story.begin()
	await settle()
	check(story._found == 0 and story.get_node_or_null("Bow") != null, "replay resets gifts with stable names")
	check(camp.get_node("Owl")._hoot_player.unit_size == 18.0, "owl reaches across the clearing")
	if visual:
		await comparison(jon, david, camp)
	print("CAMP REVIEW PASSED" if failures == 0 else "CAMP REVIEW FAILED")
	quit(0 if failures == 0 else 1)

func comparison(jon: Node3D, david: Node3D, camp: Node) -> void:
	main.get_node("CameraDirector").set_process(false)
	for child in main.get_children():
		if child is CanvasLayer:
			child.visible = false
	main.get_node("Player").visible = false
	main.get_node("WonderLight").visible = false
	var center: Vector3 = camp._clearing + Vector3(0, 0, 6)
	david.global_position = center + Vector3(-0.48, 0, 0)
	jon.global_position = center + Vector3(0.48, 0, 0)
	david.rotation = Vector3.ZERO
	jon.rotation = Vector3.ZERO
	var cam: Camera3D = main.get_node("CloseUpCamera")
	cam.global_position = center + Vector3(0, 1.0, -3.6)
	cam.look_at(center + Vector3(0, 0.65, 0), Vector3.UP)
	cam.current = true
	var labels := CanvasLayer.new()
	main.add_child(labels)
	for entry in [[david, "DAVID"], [jon, "JONATHAN"]]:
		var label := Label.new()
		label.text = entry[1]
		label.add_theme_font_size_override("font_size", 27)
		label.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.04))
		label.add_theme_constant_override("outline_size", 6)
		label.position = cam.unproject_position(entry[0].global_position + Vector3(0, 1.4, 0)) - Vector2(85, 0)
		label.size.x = 170
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		labels.add_child(label)
	await settle(8)
	await shot("character-comparison")
