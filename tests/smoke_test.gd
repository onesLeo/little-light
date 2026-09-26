extends SceneTree
## Headless smoke test — not part of the shipped game.
## Run with (from the project folder, after opening it in the editor at
## least once so assets are imported — or `godot --headless --import .`):
##   godot --headless --path . --script tests/smoke_test.gd
## Instances main.tscn directly (no window/input needed) and drives the
## beat machine + minigame + companion/camera wiring programmatically to
## catch null-ref / bad-node-path errors the passive idle run can't reach.
## Exits 0 on success, 1 if any check fails (CI-friendly).

const Profiles := preload("res://scripts/profiles.gd")
const JournalContent := preload("res://scripts/journal_content.gd")
const GameSettings := preload("res://scripts/game_settings.gd")
const CharmArt := preload("res://scripts/charm_art.gd")
const GroundSurface := preload("res://scripts/ground_surface.gd")
const SoundLibraryFile := preload("res://scripts/sound_library.gd")
const TEST_PROFILES := "user://smoke_test_profiles.cfg"

var _failures: int = 0
var _minigame_signal_fired: bool = false

func _on_test_minigame_completed() -> void:
	_minigame_signal_fired = true

func _check(cond: bool, label: String) -> void:
	if cond:
		print("  OK   ", label)
	else:
		_failures += 1
		print("  FAIL ", label)

## The terrain's surface at (x, z): casts straight down, ignoring trees, rocks and anything else on top.
func _terrain_hit(space: PhysicsDirectSpaceState3D, x: float, z: float) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, 40.0, z), Vector3(x, -10.0, z))
	var skip: Array[RID] = []
	for _i in 12:
		query.exclude = skip
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			return {}
		if str((hit["collider"] as Node).get_path()).contains("Valley_Terrain"):
			return hit
		skip.append(hit["rid"])
	return {}

## Triangles in every mesh under a node (one copy of each; shadows and outlines are not counted twice).
func _triangles_under(node: Node) -> int:
	var total: int = 0
	for found in node.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = (found as MeshInstance3D).mesh
		if mesh == null:
			continue
		for surface in mesh.get_surface_count():
			var arrays: Array = mesh.surface_get_arrays(surface)
			var indices = arrays[Mesh.ARRAY_INDEX]
			total += (indices.size() if indices != null else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return total

func paused_now() -> bool:
	return root.get_tree().paused

func _initialize() -> void:
	# Never touch the real saved profiles: a scratch file, with one child already playing.
	DirAccess.remove_absolute(TEST_PROFILES)
	Profiles.use_file(TEST_PROFILES)
	Profiles.set_active(Profiles.create("Test", "lamb"))
	# As after "Play again" in the valley: the story goes straight into chapter 1.
	Profiles.current_chapter = Profiles.CHAPTER_VALLEY
	# The tablet's saved settings, then the story's plain words and full motion, whatever a child
	# last chose while playing (Easy words is saved to the tablet too).
	GameSettings.load_settings()
	GameSettings.easy_words = false
	GameSettings.reduced_motion = false
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame  # let _ready() propagate through the tree first

	var director: Node = main.get_node("Valley/ChapterDirector")
	var wonder_light: Node = main.get_node("WonderLight")
	var steady_hands: Node = main.get_node("Valley/SteadyHands")
	var breath: Control = main.get_node("UI/BreathIndicator")
	var closeup_cam: Camera3D = main.get_node("CloseUpCamera")
	var tabletop_cam: Camera3D = main.get_node("TabletopCamera")
	var david: Node3D = main.get_node("Valley/DavidMentor")
	var input_setup: Node = main.get_node("InputSetup")
	var touch_controls: CanvasLayer = main.get_node("TouchControls")
	var game_menu: CanvasLayer = main.get_node("GameMenu")
	game_menu.end_panel_delay = 0.05

	print("-- boot --")
	_check(director.beat == director.Beat.ARRIVE, "ChapterDirector auto-enters ARRIVE on ready")
	_check(tabletop_cam.current == true, "tabletop camera is active on ARRIVE")
	_check(closeup_cam.current == false, "close-up camera is inactive on ARRIVE")

	print("-- input devices: gamepad, touch, keyboard --")
	_check(InputMap.has_action("pause"), "pause action is registered")
	_check(InputMap.action_get_events("ui_accept").any(func(e): return e is InputEventJoypadButton), "gamepad A is bound to ui_accept")
	_check(InputMap.action_get_events("move_left").any(func(e): return e is InputEventJoypadMotion), "left stick is bound to movement")
	input_setup.set_mode("touch")
	_check(touch_controls.visible, "touch controls show in touch mode")
	_check(director._localize_prompt("Press Space to continue") == "Tap NEXT to continue", "prompts are reworded for touch")
	_check(director.get_action_hint() == "NEXT", "action button says NEXT while dialogue waits")
	input_setup.set_mode("gamepad")
	_check(director._localize_prompt("Press E to collect") == "Press A to collect", "prompts are reworded for gamepad")
	input_setup.set_mode("keyboard")
	_check(not touch_controls.visible, "touch controls hide in keyboard mode")
	_check(director._localize_prompt("Press Space to continue") == "Press Space to continue", "keyboard prompts are unchanged")
	# Every story words its prompts through device_prompts.gd; each keeps its own name for the gold button.
	var prompts: GDScript = load("res://scripts/device_prompts.gd")
	var gold: String = prompts.GOLD_BUTTON
	_check(prompts.for_mode("Press E to collect, or press E again", "touch", "GRAB") == "Tap GRAB to collect, or tap GRAB again"
			and prompts.for_mode("[A / D: look around]", "touch", "GRAB") == "[stick: look around]",
			"the valley names the gold button GRAB on a tablet")
	_check(prompts.for_mode("Hold Space / Enter or the button, then release to tie", "touch", gold, "LOOP") == "Hold LOOP, then release to tie"
			and prompts.for_mode("Hold Space / Enter or the button, then release to tie", "gamepad", gold, "LOOP") == "Hold A, then release to tie"
			and prompts.for_mode("Press Space  •  A / D or arrows: look around", "touch", gold, "LOOP") == "Tap NEXT  •  stick: look around",
			"the camp's cord says Hold LOOP on a tablet and Hold A on a gamepad")
	_check(prompts.for_mode("Press E for the next peg", "touch") == "Tap the gold button for the next peg"
			and prompts.for_mode("Hold E to pull the rope", "touch") == "Hold the gold button to pull the rope"
			and prompts.for_mode("Hold E to pull the rope", "gamepad") == "Hold A to pull the rope",
			"the ark calls it the gold button, since its label changes from step to step")

	print("-- pause menu --")
	game_menu.set_paused(true)
	_check(paused, "pause action pauses the tree")
	game_menu.set_paused(false)
	_check(not paused, "resuming unpauses the tree")

	print("-- living world: boundary, lamb, fish, butterflies, no invisible walls --")
	await create_timer(0.4).timeout  # let the scatter and the deferred setups finish
	var player: CharacterBody3D = main.get_node("Player")
	var bounds: Node = main.get_node("PlayBounds")
	var inside: Dictionary = bounds._edge_info(Vector2(0.0, 0.0))
	_check(float(inside["sd"]) < -5.0, "the middle of the valley is well inside the play area")
	var outside: Dictionary = bounds._edge_info(Vector2(bounds.half_extents.x + 3.0, 0.0))
	_check(float(outside["sd"]) > 2.5 and (outside["normal"] as Vector2).x > 0.9, "past the edge reads as outside, with an outward normal")
	director._enter_beat(director.Beat.EXPLORE)
	player.global_position = Vector3(40.0, 1.0, 40.0)
	await physics_frame
	await physics_frame
	var after: Dictionary = bounds._edge_info(Vector2(player.global_position.x, player.global_position.z) - bounds.center)
	_check(float(after["sd"]) <= 0.01, "a player far outside is brought back to the edge")
	_check(director.dialogue_label.text.contains("valley"), "Wonder Light gives a friendly nudge at the edge")
	var lamb_life: Node = main.get_node("Valley/WonderItems/LambLife")
	_check(lamb_life._ready_to_animate, "the lamb is set up after the items are scattered")
	_check(main.get_node("Valley/StreamFish")._fish.size() == 3, "three shy fish are swimming")
	_check(main.get_node("Valley/Butterflies")._flies.size() == 8, "eight butterflies are fluttering")
	var walls := 0
	for bank in main.get_node("Valley/StreamFishAlive/Art").find_children("Bank_*", "MeshInstance3D", true, false):
		if bank.get_node_or_null("BakedCollision") != null:
			walls += 1
	_check(walls == 0, "hidden stream banks have no collision (no invisible walls)")

	print("-- scenery: trees stand on grass, the brook's rocks are the valley's stone --")
	await physics_frame
	await physics_frame
	var space: PhysicsDirectSpaceState3D = main.get_world_3d().direct_space_state
	var tree_count: int = 0
	var steepest: float = 0.0
	var worst_gap: float = 0.0
	var lost: Array = []
	for tree in main.get_node("Valley/BethlehemValley").find_children("*", "MeshInstance3D", true, false):
		var tree_name: String = String(tree.name)
		if tree_name.ends_with("_Outline") or not (tree_name.begins_with("Cypress_") or tree_name.begins_with("Olive_")):
			continue
		tree_count += 1
		var base: Vector3 = (tree as Node3D).global_position
		var ground: Dictionary = _terrain_hit(space, base.x, base.z)
		if ground.is_empty():
			lost.append(tree_name)
			continue
		steepest = maxf(steepest, rad_to_deg(acos(clampf((ground["normal"] as Vector3).y, -1.0, 1.0))))
		worst_gap = maxf(worst_gap, absf(base.y - (ground["position"] as Vector3).y))
	_check(tree_count == 22 and lost.is_empty(), "all 22 trees have ground under them %s" % [lost])
	_check(steepest <= 42.0, "no tree stands on the bare cliff wall (steepest ground %.0f degrees)" % steepest)
	_check(worst_gap <= 0.35, "no tree floats or is buried, even after the stream nudges it (worst %.2f m)" % worst_gap)
	var plants: int = 0
	var white_or_split: Array = []
	for plant in main.get_node("Valley/BethlehemValley").find_children("*", "MeshInstance3D", true, false):
		var plant_name: String = String(plant.name)
		if plant_name.ends_with("_Outline") or not (plant_name.begins_with("Cypress_") or plant_name.begins_with("Olive_") or plant_name.begins_with("Shrub_")):
			continue
		plants += 1
		var plant_mesh: Mesh = (plant as MeshInstance3D).mesh
		var leaf_material: BaseMaterial3D = plant_mesh.surface_get_material(0) as BaseMaterial3D
		if plant_mesh.get_surface_count() != 1 or leaf_material == null or leaf_material.resource_name != "FoliageVertexColour" or not leaf_material.vertex_color_use_as_albedo:
			white_or_split.append(plant_name)
	_check(plants == 32 and white_or_split.is_empty(), "all %d trees and bushes are one painted surface (two draws with the outline) %s" % [plants, white_or_split])
	var ledge_rocks: int = 0
	var ledge_problems: Array = []
	for outcrop in main.get_node("Valley/BethlehemValley").find_children("LedgeRock_*", "MeshInstance3D", true, false):
		var outcrop_name: String = String(outcrop.name)
		if outcrop_name.ends_with("_Outline"):
			continue
		ledge_rocks += 1
		var outcrop_material: Material = (outcrop as MeshInstance3D).mesh.surface_get_material(0)
		if outcrop_material == null or not (outcrop_material.resource_name in ["RockGrey", "RockSlate", "RockMossy"]) or outcrop.get_node_or_null("BakedCollision") != null:
			ledge_problems.append(outcrop_name)
	_check(ledge_rocks >= 3 and ledge_problems.is_empty(), "the cliff wall has %d stone ledges, decoration only (no collision) %s" % [ledge_rocks, ledge_problems])
	var brook_rocks: int = 0
	var not_stone: Array = []
	var no_outline: Array = []
	var brook_art: Node = main.get_node("Valley/StreamFishAlive/Art")
	for rock in brook_art.find_children("Rock_*", "MeshInstance3D", true, false):
		var rock_name: String = String(rock.name)
		if rock_name.ends_with("_Outline"):
			continue
		brook_rocks += 1
		var stone_material: Material = (rock as MeshInstance3D).mesh.surface_get_material(0)
		if stone_material == null or not (stone_material.resource_name in ["RockGrey", "RockSlate", "RockMossy"]):
			not_stone.append(rock_name)
		var outline: Node3D = brook_art.get_node_or_null(rock_name + "_Outline") as Node3D
		if outline == null or not outline.visible:
			no_outline.append(rock_name)
	_check(brook_rocks == 11 and not_stone.is_empty(), "all %d brook rocks have the valley's stone, not the tan pack material %s" % [brook_rocks, not_stone])
	_check(no_outline.is_empty(), "and they keep an outline like every other stone %s" % [no_outline])

	print("-- performance: light enough for a tablet --")
	var outline_count: int = 0
	var casting: Array = []
	for hull in main.find_children("*_Outline", "MeshInstance3D", true, false):
		outline_count += 1
		if (hull as MeshInstance3D).cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			casting.append(String(hull.name))
	_check(outline_count > 60 and casting.is_empty(), "none of the %d outline hulls casts a shadow %s" % [outline_count, casting])
	var perf: Node = main.get_node("PerformanceTuning")
	_check(perf.render_scale_for(1280.0, 1600.0) == 1.0 and perf.render_scale_for(1600.0, 1600.0) == 1.0, "a window no wider than the cap is drawn at full size")
	_check(is_equal_approx(perf.render_scale_for(2400.0, 1600.0), 2.0 / 3.0), "a 2400 px wide tablet draws the 3D picture at 1600 px")
	_check(perf.render_scale_for(9000.0, 1600.0) == 0.5, "a huge screen never drops below half size")
	_check(main.get_viewport().scaling_3d_scale == 1.0, "on a computer the picture is still drawn at full size")
	var scene_environment: Environment = (main.find_children("*", "WorldEnvironment", true, false)[0] as WorldEnvironment).environment
	_check(scene_environment.glow_enabled, "on a computer the glow stays on")
	perf.apply_glow(true)
	_check(not scene_environment.glow_enabled, "on a phone or tablet the glow is off")
	perf.glow_on_handhelds = true
	perf.apply_glow(true)
	_check(scene_environment.glow_enabled, "unless it is asked to stay on")
	perf.glow_on_handhelds = false
	perf.apply_glow(false)
	perf.cap_on_computers = true
	perf.max_render_width = 40   # a headless window is only 100 px wide
	perf._update_render_scale()
	var capped: float = main.get_viewport().scaling_3d_scale
	_check(capped < 1.0 and is_equal_approx(capped, perf.render_scale_for(float(main.get_window().size.x), 40.0)), "the cap shrinks the 3D picture when it is on (%.2f)" % capped)
	perf.cap_on_computers = false
	main.get_viewport().scaling_3d_scale = 1.0
	var character_triangles: int = _triangles_under(david) + _triangles_under(main.get_node("Player"))
	var scene_triangles: int = _triangles_under(main)
	_check(character_triangles <= 120000, "the two characters and their outlines stay light (%d triangles, budget 120000)" % character_triangles)
	_check(scene_triangles <= 290000, "and so does the whole scene (%d triangles, budget 290000)" % scene_triangles)

	print("-- meeting David cuts to close-up + points Wonder Light --")
	# The characters finish turning before the dialogue camera cuts.
	await director._enter_beat(director.Beat.MEET_DAVID_A)
	_check(closeup_cam.current == true, "MEET_DAVID_A cuts to close-up")
	_check(tabletop_cam.current == false, "tabletop stops being current after cut")
	_check(wonder_light._look_target == david, "Wonder Light looks at David during MEET_DAVID_A")
	var cam_dir: Node = main.get_node("CameraDirector")
	var walker_body: Node3D = main.get_node("Player")
	var david_front := -david.global_transform.basis.z
	david_front.y = 0.0
	david_front = david_front.normalized()
	walker_body.global_position = david.global_position + david_front * 1.5
	cam_dir._orbit_target = david
	cam_dir._orbit_angle = -cam_dir.closeup_side_angle
	cam_dir._place_closeup()
	var head := walker_body.global_position + Vector3(0.0, 1.17, 0.0)
	var view := closeup_cam.get_viewport().get_visible_rect().size
	var head_screen := closeup_cam.unproject_position(head)
	_check(not closeup_cam.is_position_behind(head), "from David's side the walker's head is in front of the camera")
	_check(head_screen.y > view.y * 0.04 and head_screen.y < view.y * 0.78,
			"the walker's head stays on screen instead of being cut off (y %.0f of %.0f)" % [head_screen.y, view.y])
	_check(closeup_cam.global_position.distance_to(walker_body.global_position + Vector3(0.0, 0.7, 0.0)) > 1.1,
			"the close-up stays outside the walker")
	walker_body.global_position = david.global_position + david_front.rotated(Vector3.UP, 2.2) * 2.2
	cam_dir._orbit_angle = 0.0
	cam_dir._place_closeup()
	var david_head := david.global_position + Vector3(0.0, 1.15, 0.0)
	_check(not closeup_cam.is_position_behind(david_head), "David's own close-up still sees his head")

	print("-- steady hands starts the breathing indicator --")
	director._enter_beat(director.Beat.STEADY_PLAY)
	_check(steady_hands.active == true, "minigame active after STEADY_PLAY")
	_check(breath.visible == true, "breath indicator visible while minigame active")

	print("-- steady hands: slow and calm, and it cannot be rushed --")
	_check(director.prompt_label.text.begins_with("Hold Space"), "the prompt says to hold Space to breathe in")
	_check(director.get_action_hint() == "BREATHE", "the action button says BREATHE while breathing")
	_check(steady_hands._air.playing, "the air sound plays while breathing")
	# The press that started this step must be let go of before it counts.
	steady_hands._advance(1.0, true)
	_check(steady_hands.level == 0.0, "the press that started Steady Hands does not count until it is let go of")
	steady_hands._advance(0.1, false)
	_check(steady_hands._breath_label.text == "Hold", "an empty ring says Hold")
	for i in 10:
		steady_hands._advance(0.1, true)
	var after_second: float = steady_hands.level
	_check(after_second > 0.05 and after_second < 0.30, "one second of holding fills only a small part of the ring (%.2f)" % after_second)
	_check(steady_hands._breath_label.text == "In...", "the ring says In... while it fills")
	_check(steady_hands._air.volume_db > steady_hands.air_db_still + 6.0, "the air sound swells as the child breathes in")
	for i in 2:
		steady_hands._advance(0.1, false)
	_check(steady_hands.level > after_second and steady_hands.velocity > 0.0, "letting go does not snap the ring around: it keeps rising for a moment")
	for i in 60:
		steady_hands._advance(0.1, false)  # six seconds: empty, but not yet long enough for the ring to breathe by itself
	_check(steady_hands.level == 0.0, "the ring empties completely when nobody is pressing")
	var label_changes := 0
	var last_label: String = steady_hands._label_text
	for i in 200:
		steady_hands._advance(0.1, i % 2 == 0)  # pressing five times a second for 20 seconds
		if steady_hands._label_text != last_label:
			label_changes += 1
			last_label = steady_hands._label_text
	_check(steady_hands.level < 0.40 and steady_hands.breaths_done == 0,
			"tapping quickly cannot rush it (ring at %.2f, %d breaths)" % [steady_hands.level, steady_hands.breaths_done])
	_check(label_changes <= 4, "and the label does not flicker between In and Out (%d changes in 20 s)" % label_changes)

	print("-- steady hands: nobody can get stuck --")
	steady_hands.start_minigame()
	steady_hands._advance(0.1, false)
	for i in 250:
		steady_hands._advance(0.1, false)  # never pressing anything
	_check(steady_hands.breaths_done >= 1, "if nobody presses, the ring breathes in by itself and the breath counts (%d)" % steady_hands.breaths_done)
	steady_hands.start_minigame()
	steady_hands._advance(0.1, false)
	var lowest_after_full := 1.0
	var was_full := false
	for i in 400:
		steady_hands._advance(0.1, true)  # holding the button down for 40 seconds
		was_full = was_full or steady_hands.level > 0.95
		if was_full:
			lowest_after_full = minf(lowest_after_full, steady_hands.level)
	_check(lowest_after_full < 0.3 and steady_hands.breaths_done >= 1, "if the button is held at full, the ring lets go by itself (lowest %.2f)" % lowest_after_full)

	print("-- steady hands: three slow breaths finish it --")
	steady_hands.start_minigame()
	steady_hands._advance(0.1, false)
	steady_hands.minigame_completed.connect(_on_test_minigame_completed)
	var breaths_seen: Array = []
	steady_hands.breath_completed.connect(func(n: int) -> void: breaths_seen.append(n))
	var glow_at_full := 0.0
	var david_at_full := 1.0
	for b in 3:
		for i in 45:
			steady_hands._advance(0.1, true)  # breathe in for 4.5 s
		glow_at_full = maxf(glow_at_full, wonder_light._breath_level)
		david_at_full = maxf(david_at_full, david.scale.y)
		if b == 0:
			_check(steady_hands._breath_label.text == "Out..." and steady_hands.level > 0.9, "a full ring tells the child to breathe out")
		for i in 80:
			steady_hands._advance(0.1, false)  # breathe out for 8 s
		if b < 2:
			_check(steady_hands._dots.done == b + 1, "a dot fills after each breath (%d of 3)" % (b + 1))
	_check(breaths_seen == [1, 2, 3], "three breaths are counted one by one %s" % [breaths_seen])
	_check(glow_at_full > 0.9 and david_at_full > 1.01, "Wonder Light glows and David rises as the ring fills (glow %.2f, David %.3f)" % [glow_at_full, david_at_full])
	# The success feedback is a ~0.9s tween (bloom + fade) before the signal
	# fires by design — give it real frames to actually finish before checking.
	for i in range(180):
		await process_frame
		if _minigame_signal_fired:
			break
	_check(_minigame_signal_fired, "minigame_completed fires after the success tween finishes")
	_check(steady_hands.active == false, "minigame deactivates after success")
	_check(wonder_light._breath_level == 0.0 and david.scale.is_equal_approx(Vector3.ONE), "Wonder Light and David go back to normal")
	for i in range(120):
		await process_frame
		if not steady_hands._air.playing:
			break
	_check(not steady_hands._air.playing, "the air sound fades out and stops")

	print("-- steady hands: David leans down toward the lamb, and back up --")
	_check(steady_hands._crouch_shape >= 0, "his Crouch shape key is found on both his body and its outline hull")
	steady_hands.start_minigame()
	await create_timer(1.3).timeout
	var david_mesh: MeshInstance3D = steady_hands._david_meshes[0]
	_check(david_mesh.get_blend_shape_value(steady_hands._crouch_shape) > 0.9, "he leans down while the child breathes with him")
	steady_hands._tween_crouch(0.0, 1.0)
	await create_timer(1.2).timeout
	_check(david_mesh.get_blend_shape_value(steady_hands._crouch_shape) < 0.1, "and rises back to standing once the activity ends")
	steady_hands.active = false
	steady_hands.set_process(false)

	print("-- steady hands: holding on touch and gamepad --")
	input_setup.set_mode("touch")
	var finger := InputEventScreenTouch.new()
	finger.index = 0
	finger.pressed = true
	finger.position = touch_controls.button_position()
	touch_controls._input(finger)
	await process_frame  # injected input is applied at the end of the frame
	_check(Input.is_action_pressed("ui_accept") and Input.is_action_pressed("interact"), "the touch button stays pressed while a finger is on it")
	var lifted: InputEventScreenTouch = finger.duplicate()
	lifted.pressed = false
	touch_controls._input(lifted)
	await process_frame
	_check(not Input.is_action_pressed("ui_accept") and not Input.is_action_pressed("interact"), "and lets go when the finger lifts")
	var hold_line := "Hold Space to breathe in, let go to breathe out"
	_check(director._localize_prompt(hold_line) == "Hold BREATHE to breathe in, let go to breathe out", "the hold prompt is reworded for touch")
	input_setup.set_mode("gamepad")
	_check(director._localize_prompt(hold_line) == "Hold A to breathe in, let go to breathe out", "and for a gamepad")
	input_setup.set_mode("keyboard")
	_check(director._localize_prompt(hold_line) == hold_line, "and left alone for the keyboard")

	print("-- item collection triggers Wonder Light celebrate() without error --")
	director._enter_beat(director.Beat.EXPLORE)
	_check(tabletop_cam.current == true, "EXPLORE cuts back to tabletop")
	_check("for David" in director.prompt_label.text and "Stone" in director.prompt_label.text
			and "Staff" in director.prompt_label.text and "Little Lamb" in director.prompt_label.text,
			"the hunt names all three things as something the child is finding for David")
	await process_frame
	var panel_height: float = director.dialogue_panel.offset_bottom - director.dialogue_panel.offset_top
	_check(panel_height <= 150.0, "a short line uses a compact dialogue panel instead of hiding the valley (%.0f px)" % panel_height)
	var stone: Area3D = main.get_node("Valley/WonderItems/WonderItem_Stone")
	director._near_item = stone
	director._try_collect_near_item()
	_check(director.wonder_items_found == 1, "collecting an item increments the counter")
	_check("Stone ✓" in director.prompt_label.text, "the hunt checks off the thing that was found")
	var foreground_fade: Node = main.get_node("ForegroundFade")
	var olive: GeometryInstance3D = main.get_node("Valley/BethlehemValley").find_children("Olive*", "MeshInstance3D", true, false)[0]
	_check(foreground_fade._is_foreground_foliage(olive), "foreground foliage can soften instead of hiding the player")

	print("-- reflect beat returns to the wide tabletop shot --")
	director._enter_beat(director.Beat.REFLECT)
	_check(tabletop_cam.current == true, "REFLECT is a tabletop (wide) shot")
	director._enter_beat(director.Beat.RESOLUTION)
	_check("Goliath" in director.dialogue_label.text and "The people were safe" in director.dialogue_label.text,
			"the gentle ending still clearly explains what happened")

	print("-- voice-over: every spoken line has a recorded clip --")
	var audio: Node = main.get_node("AudioDirector")
	var vo_lib := load("res://scripts/vo_library.gd")
	var missing_files: Array = []
	for text in vo_lib.LINES:
		if vo_lib.clip_for(text) == null:
			missing_files.append(vo_lib.LINES[text])
	_check(missing_files.is_empty(), "all %d clips in the voice-over library load %s" % [vo_lib.LINES.size(), missing_files])
	var unrecorded: Array = []
	var spoken_texts: Array = []
	await director._enter_beat(director.Beat.MEET_DAVID_A)
	spoken_texts.append(director.dialogue_label.text)
	for b in [director.Beat.ARRIVE, director.Beat.EXPLORE, director.Beat.MEET_DAVID_B, director.Beat.STEADY_INTRO,
			director.Beat.STEADY_DONE, director.Beat.RESOLUTION, director.Beat.REFLECT, director.Beat.VERSE_REWARD]:
		director._enter_beat(b)
		spoken_texts.append(director.dialogue_label.text)
	spoken_texts.append(director.LINES.block(director.VERSE_PAGE_TWO, false)["text"])
	spoken_texts.append("Wonder Light: \"Breathe with David...\"")
	spoken_texts.append("Wonder Light: \"Keep this close. Courage is yours to carry.\"")
	spoken_texts.append("Wonder Light: \"A Courage charm — for staying with David, and breathing God's promise with him.\"")
	spoken_texts.append("Wonder Light: \"God was with David. God is with you.\"")
	spoken_texts.append(director.LINES.block(director.ITEM_FLAVOR.values(), false)["text"])
	for nudge in main.get_node("PlayBounds").NUDGE_LINES:
		spoken_texts.append(nudge)
	# The valley's own lines carry their clips (checked with the lines below); anything else on the
	# bar is read by its words, so it needs an entry in the library.
	var valley_words: Dictionary = {}
	for l in director.LINES.lines:
		valley_words[l.text] = true
		valley_words[l.easy_text] = true
	for block in spoken_texts:
		for line in audio._spoken_lines(block):
			if vo_lib.clip_for(line["text"]) == null and not valley_words.has(line["text"]):
				unrecorded.append(line["text"])
	_check(unrecorded.is_empty(), "no spoken line in the game is missing its recording %s" % [unrecorded])
	var map_script := load("res://scripts/faith_journey_screen.gd")
	var map_unrecorded: Array = []
	for block in ["Hello!\nYour journey starts in the valley.", "Hello!\nThe King's Camp is next.", "Hello!\nNoah's Ark is next.", "Hello!\nTap a story to begin.",
			"Hello!\nThe Beginning is next.", "Finish Chapter 2, The King's Camp, first. Then The Beginning will open for you.",
			"Finish Chapter 3, The Beginning, first. Then Noah's Ark will open for you.",
			"Hello!\nJonah and the Great Fish is next.", "Finish Chapter 4, Noah's Ark, first. Then Jonah will open for you.",
			"One story at a time.", "Finish Chapter 1, The valley, first. Then The King's Camp will open for you.",
			"This part of the path is still ahead. New stories will be waiting here."]:
		for line in audio._spoken_lines(map_script._wonder_light(block)):
			if vo_lib.clip_for(line["text"]) == null:
				map_unrecorded.append(line["text"])
	_check(map_unrecorded.is_empty(), "the Faith Journey map speaks in the recorded voice too %s" % [map_unrecorded])
	# A story's own lines are data (assets/dialogue/*.tres, dialogue_line.gd), each with its clips.
	for story in [["res://assets/dialogue/bethlehem_valley.tres", "res://scripts/chapter_director.gd"],
			["res://assets/dialogue/kings_camp.tres", "res://scripts/chapter_two.gd"],
			["res://assets/dialogue/noahs_ark.tres", "res://scripts/chapter_four.gd"],
			["res://assets/dialogue/jesses_house.tres", "res://scripts/chapter_three.gd"],
			["res://assets/dialogue/jonahs_journey.tres", "res://scripts/chapter_five.gd"]]:
		var book: Resource = load(story[0])
		var seen: Dictionary = {}
		var faults: Array = []
		for l in book.lines:
			if String(l.id).is_empty() or seen.has(l.id):
				faults.append("id '%s' empty or used twice" % l.id)
			seen[l.id] = true
			if book.recorded and l.is_spoken() and l.clip == null:
				faults.append("%s has no clip" % l.id)
			if book.recorded and l.has_easy() and (l.easy_clip == null or not l.is_spoken()):
				faults.append("%s has an easier version with no clip" % l.id)
		var asked := RegEx.create_from_string("&\"(\\w+)\"")
		for m in asked.search_all(FileAccess.get_file_as_string(story[1])):
			if not seen.has(StringName(m.get_string(1))):
				faults.append("%s asks for '%s', which is not in its lines" % [story[1].get_file(), m.get_string(1)])
		_check(faults.is_empty(), "%s: every line has its clip, and every line the story asks for is there %s" % [story[0].get_file(), faults])

	print("-- voice-over: playback, chaining and fast skipping --")
	var settings := load("res://scripts/game_settings.gd")
	settings.read_aloud = true
	var vo_player: AudioStreamPlayer = audio.get_node("Vo")
	audio.stop_speech()
	var valley_lines: Resource = director.LINES
	audio.speak_lines(valley_lines.block([&"david_hello", &"david_giant"], false)["spoken"])
	_check(vo_player.playing and vo_player.stream == valley_lines.line(&"david_hello").clip, "the first line of a block plays its recorded clip")
	_check(audio._clip_queue.size() == 1, "the second line waits in the queue")
	vo_player.finished.emit()
	audio.speak_lines(director.LINES.block([&"breathe"], false)["spoken"])
	await create_timer(0.5).timeout
	_check(vo_player.stream == valley_lines.line(&"breathe").clip and audio._clip_queue.is_empty(),
			"skipping ahead cuts the old line and a stale queued line never plays")
	audio.speak_lines(valley_lines.block([&"explore", &"david_stay_close"], false)["spoken"])
	vo_player.finished.emit()
	await create_timer(0.5).timeout
	_check(vo_player.stream == valley_lines.line(&"david_stay_close").clip, "clips of one block play one after another")
	audio.stop_speech()
	_check(not vo_player.playing and not audio._speaking_clips, "stop_speech silences the clip")
	audio.speak_dialogue("Wonder Light: \"A line nobody has recorded yet.\"")
	_check(not vo_player.playing and not audio._speaking_clips, "a line with no clip falls back to system speech, not a wrong clip")
	audio.stop_speech()

	print("-- sound: files, buses and the soundscape --")
	var sound_bus := load("res://scripts/sound_bus.gd")
	var sound_lib := load("res://scripts/sound_library.gd")
	var missing_sounds: Array = []
	for path in sound_lib.all_paths():
		if sound_lib.load_stream(path) == null:
			missing_sounds.append(path)
	_check(missing_sounds.is_empty(), "all %d sound files load %s" % [sound_lib.all_paths().size(), missing_sounds])
	for bus_name in ["Music", "Ambience", "Effects", "Voice"]:
		_check(AudioServer.get_bus_index(bus_name) != -1, "the %s bus exists" % bus_name)
	_check(vo_player.bus == &"Voice" and audio.get_node("SfxA").bus == &"Effects", "voice and effects play on their own buses")
	var soundscape: Node = main.get_node("Soundscape")
	_check(soundscape._music.playing and soundscape._wind.playing and soundscape._stream.playing, "music, wind and stream are playing")
	_check((soundscape._music.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "the music loops")
	soundscape._ambience_gain = 0.0
	soundscape._process(0.0)
	var silent_start: bool = soundscape._stream.volume_db < -60.0 and soundscape._wind.volume_db < -60.0
	soundscape._process(soundscape.ambience_fade_in + 1.0)
	_check(silent_start and absf(soundscape._stream.volume_db - soundscape.stream_db) < 0.5,
			"the stream and wind ease in from silence to their set level")
	var walker: CharacterBody3D = main.get_node("Player")
	walker.global_position = Vector3(-6.0, 1.0, -2.6)
	soundscape._move_stream()
	var near_water: float = soundscape._stream.global_position.distance_to(walker.global_position)
	walker.global_position = Vector3(5.0, 1.0, 5.0)
	soundscape._move_stream()
	var far_water: float = soundscape._stream.global_position.distance_to(walker.global_position)
	_check(near_water < 2.5 and far_water > 8.0, "the stream sounds like it is at the water (%.1f m near, %.1f m far)" % [near_water, far_water])
	soundscape._call_bird(0.0)
	_check(soundscape._birds.any(func(b): return b.playing), "a bird calls")
	for b in soundscape._birds:
		b.stop()
	audio.speak_lines(director.LINES.block([&"breathe"], false)["spoken"])
	soundscape._call_bird(0.0)
	_check(not soundscape._birds.any(func(b): return b.playing), "birds stay quiet while somebody is speaking")
	audio.stop_speech()
	var has_limiter := false
	for i in AudioServer.get_bus_effect_count(0):
		has_limiter = has_limiter or AudioServer.get_bus_effect(0, i) is AudioEffectLimiter
	_check(has_limiter, "the master output has a limiter, so a loud moment cannot clip")
	_check(sound_bus.BASE_DB["Voice"] > sound_bus.BASE_DB["Ambience"] + 6.0, "the voice is set well above the ambience")

	print("-- sound: footsteps, lamb, butterflies --")
	for p in audio._step_players:
		p.stop()
	walker._update_footsteps(true, 0.5)
	_check(audio._step_players.any(func(p): return p.playing), "walking makes a footstep")
	for p in audio._step_players:
		p.stop()
	walker._update_footsteps(false, 0.5)
	walker._update_footsteps(true, 0.01)
	_check(not audio._step_players.any(func(p): return p.playing), "standing still makes none, and the first step waits a moment")
	_check(GroundSurface.at(Vector3(5.0, 0.0, 0.0)) == "grass" and GroundSurface.at(Vector3(0.45, 0.0, 1.6)) == "path" and GroundSurface.at(Vector3(0.3, 0.0, 9.5)) == "path", "the walker can tell grass from the path")
	_check(GroundSurface.at(Vector3(-8.2, 0.0, 2.2)) == "water" and GroundSurface.at(Vector3(-6.45, 0.0, -4.5)) == "water" and GroundSurface.at(Vector3(-3.0, 0.0, 3.0)) == "grass", "and the stream and the pool under the waterfall")
	var surface_names: Array = []
	for surface in ["grass", "path", "water"]:
		var one_step: AudioStream = SoundLibraryFile.step(0, surface)
		var other_step: AudioStream = SoundLibraryFile.step(1, surface)
		if one_step == null or other_step == null or one_step == other_step or (surface != "grass" and not one_step.resource_path.contains("step_" + surface)):
			surface_names.append(surface)
	_check(surface_names.is_empty(), "each ground has its own recorded steps %s" % [surface_names])
	for p in audio._step_players:
		p.stop()
	audio.play_step("water")
	_check(audio._step_players.any(func(p): return p.playing and p.stream.resource_path.contains("step_water_")), "a step in the stream makes the splashy sound")
	var lamb_node: Node = main.get_node("Valley/WonderItems/LambLife")
	_check(lamb_node._bleat != null, "the lamb has a voice")
	lamb_node._excite = 0.0
	lamb_node._bleat_wait = 0.0
	lamb_node._update_bleat(0.1, 0.0)
	_check(not lamb_node._bleat.playing, "a lamb that has not noticed anyone stays quiet")
	lamb_node._excite = 1.0
	lamb_node._update_bleat(0.1, 0.0)
	_check(lamb_node._bleat.playing and lamb_node._bleat_wait > 5.0, "the lamb says baa when it notices the Wonder-Walker, then waits")
	lamb_node._bleat.stop()
	lamb_node._bleat_wait = 0.0
	audio.speak_lines(director.LINES.block([&"breathe"], false)["spoken"])
	lamb_node._update_bleat(0.1, 1.0)
	_check(not lamb_node._bleat.playing, "the lamb does not bleat over a voice")
	audio.stop_speech()
	lamb_node._update_bleat(0.1, 1.0)
	_check(lamb_node._bleat.playing, "and bleats as soon as the voice has finished")
	var flies: Node = main.get_node("Valley/Butterflies")
	flies._flutter_cool = 0.0
	walker.global_position = (flies._flies[0]["root"] as Node3D).global_position
	await process_frame
	await process_frame
	_check(flies._flutter_players.any(func(p): return p.playing), "butterflies rustle as they take off")
	for p in flies._flutter_players:
		p.stop()
	flies._flutter_cool = 0.0
	flies._flutter(Vector3.ZERO)
	flies._flutter(Vector3.ZERO)
	_check(flies._flutter_players.filter(func(p): return p.playing).size() == 1, "a group taking off in one moment makes one rustle, not a roar")

	print("-- David's companion sheep --")
	var sheep_life: Node = david.get_node("CompanionSheepLife")
	await process_frame
	_check(sheep_life._ready_to_animate, "it is set up once David's model is ready, found as its own node")
	var sheep_mesh: Node3D = sheep_life._meshes[0]
	var sheep_base: Vector3 = sheep_life._base_pos[sheep_mesh]
	sheep_life._time = 0.25
	sheep_life._process(0.016)
	var sheep_move: float = (sheep_mesh.position - sheep_base).length()
	_check(sheep_move > 0.0 and sheep_move < 0.05, "it breathes gently, a small nudge, not a jump")
	walker.global_position = david.global_position + Vector3(1.0, 0.0, 0.0)
	for i in range(30):
		sheep_life._process(0.05)
	_check(absf(sheep_life._yaw_offset) > 0.1, "and glances toward the Wonder-Walker when they come close")
	walker.global_position = david.global_position + Vector3(50.0, 0.0, 0.0)
	for i in range(60):
		sheep_life._process(0.05)
	_check(absf(sheep_life._yaw_offset) < 0.01, "and settles back once they wander off, never leaving its own spot")
	_check(sheep_mesh.position.x == sheep_base.x and sheep_mesh.position.z == sheep_base.z, "its footprint (x/z) never moves at all, only a breathing bob and a glance")

	print("-- sound: the music ducks under speech and while paused --")
	walker.global_position = Vector3(0.0, 1.0, 4.0)
	settings.read_aloud = true
	audio.speak_lines(director.LINES.block([&"reflect"], false)["spoken"])
	await create_timer(0.8).timeout
	var music_idx := AudioServer.get_bus_index("Music")
	_check(audio.is_speaking() and sound_bus.duck > 0.5, "the music ducks while somebody is speaking")
	_check(AudioServer.get_bus_volume_db(music_idx) < sound_bus.BASE_DB["Music"] - 3.0, "the music bus is quieter while speaking")
	audio.stop_speech()
	await create_timer(1.6).timeout
	_check(sound_bus.duck < 0.05, "the music comes back after the voice stops")
	paused = true
	await create_timer(0.6).timeout
	_check(sound_bus.duck > 0.4 and soundscape._music.playing, "the music keeps playing, quieter, behind the pause menu")
	paused = false
	await create_timer(1.6).timeout
	_check(sound_bus.duck < 0.05, "and returns when the game resumes")

	print("-- who is talking: the name tag over the dialogue bar --")
	var talk_view: Control = main.get_node("UI/DialogueView")
	audio.stop_speech()
	director._say([&"david_job", &"david_stay_close"])
	await process_frame
	await process_frame
	_check(talk_view.speaker == "Wonder Light" and talk_view._current == 0 and talk_view._tag.visible
			and director.dialogue_label.self_modulate.a == 0.0 and "Thanks. Will you stay close" in talk_view._rich.text,
			"the tag shows Wonder Light while her line is read, over the same text drawn in colour")
	vo_player.finished.emit()
	await create_timer(audio.CLIP_GAP + 0.2).timeout
	_check(talk_view.speaker == "David" and talk_view._current == 1, "when David's line starts, the tag turns to David")
	audio.stop_speech()
	director._say(["Jonathan: \"I am Jonathan. David was brave today, because God was with him.\""])
	await process_frame
	_check(talk_view.speaker == "Jonathan", "Jonathan has his own tag")
	director._say(director.verse_page_one())
	await process_frame
	_check(talk_view.speaker == "Bible", "a verse shows the Bible tag")
	director._say([&"charm_arrives"])
	await process_frame
	_check(not talk_view._tag.visible, "a line with nobody speaking has no tag")
	audio.stop_speech()

	print("-- sound: volume sliders --")
	var full_db: float = sound_bus.bus_db("Music", 1.0)
	var half_db: float = sound_bus.bus_db("Music", 0.5)
	_check(absf((full_db - half_db) - 6.02) < 0.1, "half volume is 6 dB quieter")
	settings.music_volume = 0.5
	sound_bus.apply_mix()
	_check(absf(AudioServer.get_bus_volume_db(music_idx) - half_db) < 0.1, "the music slider sets the Music bus")
	settings.music_volume = 1.0
	sound_bus.apply_mix()
	game_menu._sync_pause_controls()
	_check(is_equal_approx(game_menu._music_slider.value, 1.0) and game_menu._voice_slider.value_changed.is_connected(game_menu._on_voice_changed),
			"the pause menu has music, sounds and voice sliders")
	walker.global_position = Vector3(0.0, 1.0, 4.0)

	print("-- spine: the word comes before the breath --")
	director.beat = director.Beat.MEET_DAVID_B
	director._advance_ready = true
	director._on_advance()
	_check(director.beat == director.Beat.VERSE_REWARD, "after Meet David the child hears Joshua 1:9, before breathing")
	_check("Haven't I commanded you?" in director.dialogue_label.text and "Yahweh is God's name" in director.dialogue_label.text
			and not ("Don't. Be. Afraid." in director.dialogue_label.text) and not director._word_row.visible
			and director.get_action_hint() == "NEXT", "page one is the verse and what Yahweh means, with NEXT to turn the page")
	director._on_advance()
	_check(director.beat == director.Beat.VERSE_REWARD and "Don't. Be. Afraid." in director.dialogue_label.text
			and not ("Haven't I" in director.dialogue_label.text), "page two: the three words are said with David before he walks")
	_check(Profiles.has_verse(Profiles.active_id, JournalContent.VERSE_JOSHUA_1_9), "the verse is in the journal before Steady Hands")
	director._on_advance()
	_check(director.beat == director.Beat.VERSE_REWARD, "tapping next does not skip her turn with the three words")
	director.press_word(0)
	director.press_word(1)
	director._on_advance()
	_check(director.beat == director.Beat.VERSE_REWARD and director._word_row.visible, "two words are not enough, and the word buttons are on screen")
	director.press_word(2)
	_check(director._advance_ready, "after all three words the breath can begin")
	director._on_advance()
	_check(director.beat == director.Beat.STEADY_INTRO, "the breath comes after the word")
	_check("God's promise" in director.dialogue_label.text, "Steady Hands is breathing the promise, not manufacturing calm")
	director._enter_beat(director.Beat.MEET_DAVID_B)
	_check("God gave David a job" in director.dialogue_label.text, "Wonder Light names David's purpose before the verse")
	director._enter_beat(director.Beat.REFLECT)
	_check("for you too" in director.dialogue_label.text and "Stay close" in director.dialogue_label.text and "remember the words" in director.dialogue_label.text,
			"the child is given a purpose: stay close and remember the words")
	_check("sheep to keep safe" in director.LINES.line(&"david_giant").text, "David names his job: keep the sheep safe")
	_check("small thing" in director.LINES.line(director.ITEM_FLAVOR["WonderItem_Stone"]).text, "the stone flavour names God, not just a sling")
	director._enter_beat(director.Beat.ARRIVE)
	_check("David's valley" in director.dialogue_label.text and "God looks after him" in director.dialogue_label.text,
			"God is named through David from the first beat")
	director._enter_beat(director.Beat.VERSE_REWARD)
	_check("Yahweh is God's name" in director.dialogue_label.text, "Yahweh is explained so a child (and a parent) can hear it")
	_check("lion and the bear" in director.LINES.line(&"david_lion_bear").text,
			"David speaks 1 Samuel 17:37 in his own words")
	_check("God was with David" in director.LINES.line(&"complete").text,
			"the ending names God, not a secular slogan")
	director.beat = director.Beat.STEADY_DONE
	director._advance_ready = true
	director._on_advance()
	_check(director.beat == director.Beat.RESOLUTION, "after the breath, David walks")
	_check("small stone" in director.dialogue_label.text and "Goliath" in director.dialogue_label.text,
			"resolution ties the hunted stone to what God used against Goliath")
	director.beat = director.Beat.REFLECT
	director._advance_ready = true
	director._on_advance()
	_check(director.beat == director.Beat.CHARM_AWARD, "reflect goes to the charm, not a second verse prize")

	print("-- full beat traversal reaches DONE without throwing --")
	for b in [director.Beat.MEET_DAVID_B, director.Beat.STEADY_INTRO, director.Beat.STEADY_DONE,
			director.Beat.RESOLUTION, director.Beat.REFLECT, director.Beat.VERSE_REWARD, director.Beat.CHARM_AWARD, director.Beat.DONE]:
		director._enter_beat(b)
	_check(director.beat == director.Beat.DONE, "beat machine reaches DONE cleanly")

	print("-- end of chapter offers Play again --")
	await create_timer(0.3).timeout
	_check(game_menu._end_panel.visible, "end panel appears after the chapter finishes")
	_check(game_menu._journey_button.visible, "Faith Journey is offered once the chapter is finished")
	_check("Courage" in game_menu._end_title.text and director.complete_banner.text == "Chapter 1 Complete!",
			"the end card names the charm earned, and the banner names the chapter")
	_check(game_menu._end_panel.size.y < 330.0 and not (main.get_node("UI/Panel") as Control).visible,
			"the end card is only as tall as its buttons, and the dialogue bar steps aside for it")
	_check(Profiles.has_finished(Profiles.active_id, Profiles.CHAPTER_VALLEY) and Profiles.current_chapter == Profiles.CHAPTER_VALLEY,
			"the valley is marked finished, and Play again would replay the valley")
	var journey: CanvasLayer = main.get_node("FaithJourney")
	journey.open()
	_check(journey.is_open() and journey._map.texture != null, "the journey opens on the old map, not a blank page")
	_check(journey._back.visible and not journey._change_player.visible and not journey.is_locked("camp")
			and journey._marker.visible and journey._marker_stop == "camp",
			"opened later it has Back, and with the valley done the King's Camp is open and marked as next")
	journey._on_stop("ahead")
	_check(journey._notice.visible and "still ahead" in journey._notice_body.text, "a stop further on is a kind card, not a dead end")
	journey._hide_notice()

	print("-- the Faith Journey comes first, and chapter 2 waits for chapter 1 --")
	var finished_kid: String = Profiles.active_id
	var new_kid: String = Profiles.create("New", "sun")
	Profiles.set_active(new_kid)
	_check(Profiles.next_chapter(new_kid) == Profiles.CHAPTER_VALLEY and Profiles.is_unlocked(new_kid, Profiles.CHAPTER_VALLEY)
			and not Profiles.is_unlocked(new_kid, Profiles.CHAPTER_CAMP), "a new child starts at the valley, and the camp is closed")
	journey.close()
	journey.open_to_choose()
	_check(journey.is_open() and paused_now() and not journey._back.visible and journey._change_player.visible
			and "New" in journey._line.text, "straight after \"Who is playing?\" the map greets the child by name, with no Back")
	_check(journey._marker.visible and journey._marker_stop == "valley" and journey._marker.text == "Start here"
			and journey._ring.visible, "a bouncing Start here tag and rings mark the valley")
	journey._on_stop("camp")
	_check(journey._notice.visible and "Chapter 1" in journey._notice_body.text and journey._notice_go.visible
			and journey._notice_go.text == "Play Chapter 1" and main.get_node_or_null("KingsCamp") == null,
			"tapping the King's Camp first says to finish Chapter 1, and offers to play it")
	var pause_key := InputEventAction.new()
	pause_key.action = "pause"
	pause_key.pressed = true
	root.push_input(pause_key)
	_check(not journey._notice.visible and journey.is_open(), "the pause key closes the card, and the map stays up to choose from")
	root.push_input(pause_key)
	_check(journey.is_open(), "with nothing started yet, the pause key does not leave the map")
	journey.close()
	Profiles.set_active(finished_kid)
	Profiles.remove(new_kid)
	var legacy := ConfigFile.new()
	legacy.set_value("app", "order", ["p1"])
	legacy.set_value("profile_p1", "name", "Old")
	legacy.set_value("profile_p1", "chapters", 2)
	legacy.save("user://smoke-legacy-profiles.cfg")
	Profiles.use_file("user://smoke-legacy-profiles.cfg")
	_check(Profiles.has_finished("p1", Profiles.CHAPTER_VALLEY) and Profiles.is_unlocked("p1", Profiles.CHAPTER_CAMP),
			"a save from before chapters were told apart still has the valley finished")
	DirAccess.remove_absolute("user://smoke-legacy-profiles.cfg")
	# Saves from before The Beginning was put ahead of the ark: nobody loses a chapter they had open.
	var pre_beginning := ConfigFile.new()
	pre_beginning.set_value("app", "order", ["p1", "p2"])
	pre_beginning.set_value("profile_p1", "name", "Ahead")
	pre_beginning.set_value("profile_p1", "finished", [Profiles.CHAPTER_VALLEY, Profiles.CHAPTER_CAMP])
	pre_beginning.set_value("profile_p2", "name", "Behind")
	pre_beginning.set_value("profile_p2", "finished", [Profiles.CHAPTER_VALLEY])
	pre_beginning.save("user://smoke-pre-beginning.cfg")
	Profiles.use_file("user://smoke-pre-beginning.cfg")
	_check(Profiles.is_unlocked("p1", Profiles.CHAPTER_ARK) and Profiles.is_unlocked("p1", Profiles.CHAPTER_BEGINNING)
			and Profiles.next_chapter("p1") == Profiles.CHAPTER_BEGINNING,
			"a child who had finished the camp keeps Noah's Ark open, and The Beginning opens for them too")
	Profiles.set_active("p2")
	Profiles.finish_chapter(Profiles.CHAPTER_CAMP)
	_check(Profiles.is_unlocked("p2", Profiles.CHAPTER_BEGINNING) and not Profiles.is_unlocked("p2", Profiles.CHAPTER_ARK),
			"a child who finishes the camp now goes on to The Beginning before the ark")
	Profiles.use_file("user://smoke-pre-beginning.cfg")
	_check(Profiles.is_unlocked("p1", Profiles.CHAPTER_ARK) and not Profiles.is_unlocked("p2", Profiles.CHAPTER_ARK),
			"saved again and read back, that stays the same")
	Profiles.set_active("p2")
	Profiles.finish_chapter(Profiles.CHAPTER_ARK)
	_check(Profiles.is_unlocked("p2", Profiles.CHAPTER_ARK), "a chapter a child has finished always stays open to replay")
	DirAccess.remove_absolute("user://smoke-pre-beginning.cfg")
	Profiles.use_file(TEST_PROFILES)
	Profiles.set_active(finished_kid)
	journey.open()
	_check(main.get_node_or_null("KingsCamp") == null, "the camp is not loaded while the child is still in the valley")
	# As after Play again: chapter 1 is waiting for Space when the child jumps to the camp.
	director._advance_ready = true
	journey._on_stop("camp")
	var camp: Node = main.get_node("KingsCamp")
	var camp_walker: Node3D = main.get_node("Player")
	_check(camp.tent_count() >= 4, "the king's camp has its tents on the ridge")
	_check(camp_walker.global_position.z > 20.0, "the journey can walk up to the camp")
	var jon := camp.get_node_or_null("Jonathan")
	_check(jon != null and jon._skeleton != null and jon._skeleton.find_bone("LowerArm_L") >= 0,
			"Jonathan uses connected organic limbs with a deforming arm rig")
	var jon_body := jon._body as MeshInstance3D
	var has_wine_cloth := false
	var has_own_hair := false
	for surface in jon_body.mesh.get_surface_count():
		var material := jon_body.get_active_material(surface)
		has_wine_cloth = has_wine_cloth or material.resource_name == "J_Tunic"
		has_own_hair = has_own_hair or material.resource_name == "J_Hair"
	_check(has_wine_cloth and has_own_hair, "Jonathan keeps his own wine tunic and long-hair materials")
	_check(jon._outline.skin != null and jon._outline.skeleton == jon._body.skeleton,
			"Jonathan's skin and inward outline deform on the same skeleton")
	_check(jon_body.get_aabb().size.y > 1.0 and jon_body.get_aabb().size.y < 1.4,
			"Jonathan retains David's child-sized organic proportions")
	_check(jon._blink_shape >= 0 and jon._talk_shape >= 0,
			"Jonathan's sculpted face supports blinking and speech")

	_check(journey.is_open() == false and director.beat == director.Beat.CAMP and not director._advance_ready,
			"chapter 1 stands down when the camp opens")
	_check(not director.complete_banner.visible and not game_menu._end_panel.visible,
			"chapter 1's Chapter Complete banner and end card do not hang over the camp")
	var space_key := InputEventKey.new()
	space_key.keycode = KEY_SPACE
	space_key.physical_keycode = KEY_SPACE
	space_key.pressed = true
	root.push_input(space_key)
	var space_up := space_key.duplicate() as InputEventKey
	space_up.pressed = false
	root.push_input(space_up)
	var story: Node = camp.get_node("ChapterTwo")
	_check(story.phase == story.Phase.MEET and "I am Jonathan" in director.dialogue_label.text,
			"Space at the camp moves the camp story on, and chapter 1 does not take it")
	_check(Profiles.current_chapter == Profiles.CHAPTER_CAMP, "from here, Play again comes back to the camp")
	_check(director.beat == director.Beat.CAMP and not ("David needs his stone" in director.dialogue_label.text),
			"the valley's item hunt never shows up at the camp")

	print("-- the gift hunt: pictures to tick, and the golden arrow --")
	story._advance()
	_check(story.phase == story.Phase.FIND and story._checklist.visible and not story._checklist.is_found("Robe")
			and story._checklist.get_child(0).get_child_count() == 4, "the gift list shows the three gifts as pictures, none ticked yet")
	var gift_hints: Node3D = story._hints
	_check(gift_hints != null and gift_hints._active and gift_hints._items.size() == 3 and not gift_hints.is_pointing(),
			"the golden arrow watches the three gifts, and waits before it shows")
	gift_hints._idle = story.HINT_DELAY + 1.0
	for _i in 40:
		await process_frame
	_check(gift_hints.is_pointing(), "after a while with nothing found, the arrow points to the nearest gift")
	story._on_gift(camp_walker, story.get_node("Robe"))
	_check(story._checklist.is_found("Robe") and story._checklist._title.text.contains("1 / 3") and gift_hints._idle == 0.0
			and gift_hints._collected.has("Robe"), "finding the robe ticks its picture, and the arrow waits again for the next gift")
	story._on_gift(camp_walker, story.get_node("Bow"))
	story._on_gift(camp_walker, story.get_node("Belt"))
	_check(story.phase == story.Phase.GIVE and not gift_hints._active, "with all three found, the arrow is put away")
	for _i in 6:
		await physics_frame
	_check(camp_walker.global_position.y > 9.0, "the child stands on the camp ground instead of falling through")
	var seam_camp: float = camp._ground(Vector3(-2.0, 0.0, 29.62)).y
	var seam_valley: Dictionary = _terrain_hit(camp_walker.get_world_3d().direct_space_state, -2.0, 29.4)
	_check(not seam_valley.is_empty() and absf(seam_camp - float(seam_valley["position"].y)) < 0.12,
			"the camp ground carries on from the valley's ridge without a step")
	_check(camp.get_node_or_null("Campfire/FireLight") != null and camp.get_node_or_null("TentKing/Lantern") != null,
			"the fire and one lantern are the warm lights")
	var guards := 0
	for child in camp.get_children():
		if String(child.name).begins_with("Guard"):
			guards += 1
	_check(guards == 4, "four guards walk the camp")
	var owl: Node3D = camp.get_node_or_null("Owl")
	_check(owl != null and owl.visible and owl.perches.size() == 2, "the owl is in the air when the child arrives, with two branches to sit on")
	var fireflies: Node3D = camp.get_node_or_null("Fireflies")
	_check(fireflies != null and fireflies.visible and fireflies.get_child_count() >= 6, "fireflies light up at the edge of the clearing")
	_check(camp.get_node("CampSounds").is_playing() and main.get_node("Soundscape")._night,
			"the ridge sounds like evening: crickets and the fire, no daytime birds")
	var camp_triangles := _triangles_under(camp)
	_check(camp_triangles <= 80000, "the camp stays light (%d triangles, budget 80000)" % camp_triangles)

	print("-- Knit, Loved, Friend: each tapped word lights up on its own --")
	story.phase = story.Phase.GIVE
	story._advance()
	var chips: Array = story._word_buttons
	_check(story.phase == story.Phase.WORDS and story._words.visible and chips.size() == 3
			and chips[0].beckon and not chips[0].lit, "the three words are up, and the first one beckons")
	var bar := main.get_node("UI/Panel") as Control
	_check(story._words.offset_bottom < bar.offset_top, "the words sit above the dialogue bar, not over it")
	story.press_word(0)
	_check(chips[0].lit and not chips[0].beckon and chips[1].beckon and chips[0]._sparks.size() > 0,
			"a tapped word pops with sparkles and stays lit, and the next one beckons")
	for _i in 20:
		await process_frame
	_check(chips[0]._glow > 0.5 and chips[2]._glow < 0.05, "a lit word glows, an untapped one does not")
	story.press_word(1)
	story.press_word(2)
	_check(story._words_done and chips.all(func(c: Node) -> bool: return c.lit), "all three lit: the cord can come next")
	story._advance()
	_check(story.phase == story.Phase.CORD and is_instance_valid(story._cord)
			and story._cord.offset_bottom < bar.offset_top, "the cord card sits above the dialogue bar, so the line stays readable")
	_check(story._cord.PANEL.y <= 120.0 and story._cord.offset_top > -420.0,
			"the cord card is short, so it stays below the child standing in the camp")

	print("-- The King's Camp ends the way chapter 1 does --")
	# A scratch child, so the journal checks further down still see only chapter 1's progress.
	var valley_kid: String = Profiles.active_id
	var camp_kid: String = Profiles.create("Camp", "star")
	Profiles.set_active(camp_kid)
	var chapters_before := int(Profiles.active()["chapters"])
	var award: Node3D = main.get_node("CharmAward")
	story.phase = story.Phase.VERSE
	story._advance()
	_check(story.phase == story.Phase.CHARM and story._ceremony and award.charm_id == JournalContent.CHARM_FRIENDSHIP
			and Profiles.has_charm(Profiles.active_id, JournalContent.CHARM_FRIENDSHIP),
			"the Friendship charm floats onto the Virtue Bracelet, like the Courage charm")
	_check(award._charm.get_node_or_null("ChildColouring") != null, "and it shows its own picture, not a plain Courage disc")
	story._advance()
	_check(story.phase == story.Phase.CHARM, "Space waits until the charm has landed")
	for _i in 60:
		if not story._ceremony:
			break
		await create_timer(0.1).timeout
	_check(not story._ceremony and "keep your charm" in director.prompt_label.text, "once it lands, Space keeps the charm")
	story._advance()
	_check(story.phase == story.Phase.DONE and "Friends stay tied together" in director.dialogue_label.text
			and "Well done" in director.prompt_label.text and director.complete_banner.visible,
			"the camp ends with the cheer, the confetti and the Chapter Complete banner")
	_check(int(Profiles.active()["chapters"]) == chapters_before + 1 and Profiles.has_finished(camp_kid, Profiles.CHAPTER_CAMP)
			and director.complete_banner.text == "Chapter 2 Complete!", "and it counts as chapter 2 finished")
	await create_timer(game_menu.end_panel_delay + 0.3).timeout
	_check(game_menu._end_panel.visible and game_menu._journey_button.visible and game_menu._colour_charm_button.visible
			and game_menu._end_charm == JournalContent.CHARM_FRIENDSHIP,
			"then the end card offers Play again, the Faith Journey, and colouring the Friendship charm")
	_check("Friendship" in game_menu._end_title.text and Profiles.current_chapter == Profiles.CHAPTER_CAMP,
			"it names the Friendship charm, and Play again replays the camp, not the valley")
	game_menu.hide_end_panel()
	Profiles.set_active(valley_kid)
	Profiles.remove(camp_kid)
	game_menu._end_charm = JournalContent.CHARM_COURAGE   # back to chapter 1's end card for the checks below
	journey.close()
	_check(not journey.is_open(), "Back leaves the map")

	print("-- profiles: who is playing, and what is saved --")
	var kid_id: String = Profiles.active_id
	_check(Profiles.clean_name("  Maya  ") == "Maya" and Profiles.clean_name("Bartholomew the Great").length() <= Profiles.MAX_NAME_LENGTH, "names are trimmed and kept short")
	_check(Profiles.create("   ", "sun") == "", "a name of only spaces makes no profile")
	_check(Profiles.unlock_verse("made_up_verse") and not Profiles.unlock_verse("made_up_verse"), "a verse can be earned once")
	var extras: Array = []
	while Profiles.can_add():
		extras.append(Profiles.create("Kid %d" % extras.size(), "star"))
	_check(Profiles.count() == Profiles.MAX_PROFILES and Profiles.create("Fifth", "sun") == "", "a tablet holds up to %d children" % Profiles.MAX_PROFILES)
	Profiles.use_file(TEST_PROFILES)   # read it back from disk
	Profiles.set_active(kid_id)
	_check(Profiles.count() == Profiles.MAX_PROFILES and Profiles.has_verse(kid_id, "made_up_verse") and Profiles.has_charm(kid_id, JournalContent.CHARM_COURAGE), "everything is still there after reading the file again")
	for extra in extras:
		Profiles.remove(extra)
	_check(Profiles.count() == 1 and Profiles.active_id == kid_id, "removing other children leaves this one playing")
	var settings_before: Dictionary = GameSettings.as_dictionary()
	GameSettings.music_volume = 0.4
	GameSettings.save_settings()
	_check(is_equal_approx(float(Profiles.active()["settings"]["music_volume"]), 0.4), "a child's volume choices are kept for that child")
	var second_id: String = Profiles.create("Sam", "heart")
	var picker: CanvasLayer = main.get_node("ProfileScreen")
	var chosen: Array = []
	picker.profile_chosen.connect(func(id: String) -> void: chosen.append(id))
	picker.choose(second_id)
	GameSettings.music_volume = 0.9
	GameSettings.save_settings()
	picker.choose(kid_id)
	_check(is_equal_approx(GameSettings.music_volume, 0.4), "choosing a child brings back their own volume (0.4, not Sam's 0.9)")
	GameSettings.apply_profile(settings_before)
	GameSettings.save_settings()
	Profiles.remove(second_id)
	Profiles.set_active(kid_id)

	print("-- easy words: the story for younger readers --")
	var easy_count := 0
	for l in director.LINES.lines:
		easy_count += 1 if l.has_easy() else 0
	_check(easy_count == 12, "twelve of the valley's lines have an easier version (%d)" % easy_count)
	GameSettings.easy_words = true
	director._say(director.verse_page_one())
	_check(director.dialogue_label.text.begins_with(JournalContent.verse_card(JournalContent.VERSE_JOSHUA_1_9)),
			"the Joshua 1:9 verse is never changed")
	director._say(director.VERSE_PAGE_TWO)
	_check(director.dialogue_label.text == "Wonder Light: \"This verse has three special words. Can you say them with me?\nDon't. Be. Afraid.\"",
			"the three words carry on Wonder Light's line, in the same quote marks, on a row of their own")
	var arrive: Resource = director.LINES.line(&"arrive")
	GameSettings.easy_words = false
	director._say([&"arrive"])
	_check(director.dialogue_label.text == "Wonder Light: \"This is David's valley. He looks after sheep. God looks after him.\""
			and vo_player.stream == arrive.clip and vo_player.stream.resource_path.ends_with("wl_arrive.wav"),
			"a child who is 9 or older gets the story as written, in the original voice clip")
	GameSettings.easy_words = true
	director._say([&"arrive"])
	_check(director.dialogue_label.text == "Wonder Light: \"This is David's valley. God looks after him.\""
			and vo_player.stream == arrive.easy_clip and vo_player.stream.resource_path.ends_with("ez_arrive.wav"),
			"with Easy words on, the easier line is shown and read aloud")
	var camp_story: Node = main.get_node("KingsCamp/ChapterTwo")
	camp_story._say([&"jonathan_hello"], "")
	_check(director.dialogue_label.text == "Jonathan: \"I am Jonathan. God was with David today.\"", "the King's Camp has easier words too")
	_check(vo_player.stream != null and vo_player.stream == camp_story.LINES.line(&"jonathan_hello").easy_clip
			and vo_player.stream.resource_path.ends_with("ez_jn_hello.wav"),
			"and Jonathan reads his easier line in his own recorded voice")
	var mixed: String = director._say([&"david_stay_close"])
	_check(mixed == "David: \"Thanks. Will you stay close while I get ready?\"", "a line with no easier version stays as it is")
	GameSettings.easy_words = false

	print("-- Faith Journal: the story fills it, and it reads aloud --")
	var kid: Dictionary = Profiles.active()
	_check(Profiles.has_verse(kid_id, JournalContent.VERSE_JOSHUA_1_9), "reaching the verse puts Joshua 1:9 in the child's journal")
	_check(Profiles.has_charm(kid_id, JournalContent.CHARM_COURAGE), "the Courage charm is in it too")
	_check(int(kid["chapters"]) == 1, "and the finished chapter is counted")
	var unrecorded_journal: Array = []
	# A chapter not cast yet marks its entries "recorded": false; the system voice reads those.
	for v in JournalContent.VERSES:
		for line in [v["spoken_ref"], v["text"]]:
			if v.get("recorded", true) and not vo_lib.LINES.has(line):
				unrecorded_journal.append(line)
	for c in JournalContent.CHARMS:
		if c.get("recorded", true) and not vo_lib.LINES.has(c["spoken"]):
			unrecorded_journal.append(c["spoken"])
	_check(unrecorded_journal.is_empty(), "every verse and charm in the journal has a recorded clip %s" % [unrecorded_journal])
	var journal: CanvasLayer = main.get_node("JournalScreen")
	game_menu.set_paused(false)
	journal.open()
	_check(journal.is_open() and paused_now(), "opening the journal pauses the game")
	_check(journal._title.text == "Test's Faith Journal", "the journal is titled with the child's name")
	_check("The same God who was with Joshua was with David" in JournalContent.VERSES[0]["why"],
			"the journal tells a parent why Joshua 1:9 belongs in David's story")
	_check("lion and the bear" in JournalContent.VERSES[0]["why"],
			"the parent note ties Joshua 1:9 to David's own words (1 Samuel 17:37)")
	_check(journal._verse_box.find_child("WhyNote", true, false) != null,
			"the journal card actually shows that parent note under the verse")
	_check(journal._verse_box.get_child_count() == 1, "it shows the verse the child has earned")
	_check(journal._charm_row.get_child_count() == 1 + JournalContent.MYSTERY_SLOTS and journal._charm_row.get_child(0) is Button, "it shows the Courage charm and %d empty slots" % JournalContent.MYSTERY_SLOTS)
	_check(audio.process_mode == Node.PROCESS_MODE_ALWAYS, "the audio keeps running while the game is paused")
	journal._hear(JournalContent.verse_dialogue(JournalContent.VERSE_JOSHUA_1_9))
	_check(audio._speaking_clips and vo_player.stream == vo_lib.clip_for(JournalContent.VERSES[0]["spoken_ref"]), "tapping Hear it reads the verse aloud in the recorded voice")
	journal._hear(JournalContent.CHARMS[0]["spoken"])
	_check(vo_player.stream == vo_lib.clip_for(JournalContent.CHARMS[0]["spoken"]), "tapping the charm reads its line")
	var pause_event := InputEventAction.new()
	pause_event.action = "pause"
	pause_event.pressed = true
	game_menu._input(pause_event)
	_check(journal.is_open() and paused_now(), "the pause key does not pause behind the journal")
	journal.close()
	_check(not journal.is_open() and not paused_now() and not audio._speaking_clips and audio.process_mode == Node.PROCESS_MODE_INHERIT, "closing the journal resumes the game and stops the voice")
	game_menu.set_paused(true)
	journal.open()
	journal.close()
	_check(paused_now(), "a journal opened from the pause menu goes back to the pause menu")
	game_menu.set_paused(false)

	print("-- colour your charm --")
	var courage: String = JournalContent.CHARM_COURAGE
	_check(CharmArt.region_count(courage) == 6, "the charm picture has six parts to colour")
	_check(CharmArt.hit(courage, Vector2(0.5, 0.44)) == 5 and CharmArt.hit(courage, Vector2(0.5, 0.27)) == 4, "a tap on the middle finds the middle, and one on the star finds the star")
	_check(CharmArt.hit(courage, Vector2(0.7, 0.42)) == 3 and CharmArt.hit(courage, Vector2(0.5, 0.10)) == 2, "and the inner disc and the ring")
	_check(CharmArt.hit(courage, Vector2(0.3, 0.8)) == 0 and CharmArt.hit(courage, Vector2(0.7, 0.8)) == 1 and CharmArt.hit(courage, Vector2(0.03, 0.03)) == -1, "the ribbons too, and the bare paper is nothing")
	var colour_screen: CanvasLayer = main.get_node("ColourScreen")
	_check(not colour_screen.is_open() and Profiles.charm_colours(kid_id, courage) == [-1, -1, -1, -1, -1, -1], "a new charm is blank paper")
	journal.open()
	_check(journal._colour_button.visible, "the journal offers to colour the charm the child has earned")
	journal._colour_button.pressed.emit()
	await process_frame
	_check(colour_screen.is_open() and paused_now() and journal.is_open(), "the colouring page opens over the journal")
	game_menu._input(pause_event)
	_check(not game_menu._pause_layer.visible and colour_screen.is_open(), "the pause key does not pause behind the colouring page")
	colour_screen._select(1)
	colour_screen.paint(2)
	_check(Profiles.charm_colours(kid_id, courage)[2] == 1, "tapping a part fills it with the chosen paint, saved at once")
	var art: Rect2 = colour_screen._page.art_rect()
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	colour_screen._select(5)
	tap.position = art.position + Vector2(0.5, 0.44) * art.size
	colour_screen._page._gui_input(tap)
	_check(Profiles.charm_colours(kid_id, courage)[5] == 5, "a finger on the page colours the part under it")
	colour_screen.paint(-1)
	_check(Profiles.charm_colours(kid_id, courage) == [-1, -1, 1, -1, -1, 5], "a tap on the bare paper changes nothing")
	colour_screen.undo()
	_check(Profiles.charm_colours(kid_id, courage)[5] == -1, "Undo takes the last colour off")
	colour_screen._select(3)
	colour_screen.paint(0)
	colour_screen.start_again()
	_check(Profiles.charm_colours(kid_id, courage) == [-1, -1, -1, -1, -1, -1], "Start again clears the page")
	colour_screen.undo()
	_check(Profiles.charm_colours(kid_id, courage)[0] == 3 and Profiles.charm_colours(kid_id, courage)[2] == 1, "and Undo brings it all back")
	var move := InputEventAction.new()
	move.action = "ui_right"
	move.pressed = true
	colour_screen._page.cursor = 4
	colour_screen._page._gui_input(move)
	_check(colour_screen._page.cursor == 5, "with a gamepad or keyboard, right moves to the next part of the charm")
	colour_screen._select(6)
	var press := InputEventAction.new()
	press.action = "ui_accept"
	press.pressed = true
	colour_screen._page._gui_input(press)
	_check(Profiles.charm_colours(kid_id, courage)[5] == 6, "and accept fills it with the chosen paint")
	move.action = "ui_left"
	colour_screen._page.cursor = 0
	colour_screen._page._gui_input(move)
	_check(colour_screen._page.cursor == 5, "left from the first part wraps round to the last")
	Profiles.use_file(TEST_PROFILES)   # read it back from disk
	Profiles.set_active(kid_id)
	_check(Profiles.charm_colours(kid_id, courage)[2] == 1 and Profiles.has_coloured_charm(kid_id, courage), "the colours are still there after reading the file again")
	colour_screen._input(pause_event)
	_check(not colour_screen.is_open() and journal.is_open() and paused_now(), "the pause key closes the colouring page and leaves the journal open")
	_check((journal._charm_row.get_child(0).get_child(0).get_child(0) as Control).get("colours").size() == 6, "the journal shows the child's colours on the charm")
	journal.close()
	var stamp: Image = CharmArt.render_image(courage, Profiles.charm_colours(kid_id, courage), 64)
	_check(absf(stamp.get_pixel(32, 6).r - CharmArt.PALETTE[1].r) < 0.01 and absf(stamp.get_pixel(32, 6).b - CharmArt.PALETTE[1].b) < 0.01 and stamp.get_pixel(0, 0).a == 0.0, "the picture can be drawn as an image for the 3D charm")
	var charm_award: Node3D = main.get_node("CharmAward")
	charm_award.charm_id = courage
	charm_award.apply_child_colours()
	_check(charm_award._charm.get_node_or_null("ChildColouring") != null, "the 3D charm wears the child's colouring")
	var other_id: String = Profiles.create("Sam", "sun")
	Profiles.set_active(other_id)
	charm_award.apply_child_colours()
	_check(charm_award._charm.get_node_or_null("ChildColouring") == null and Profiles.charm_colours(other_id, courage) == [-1, -1, -1, -1, -1, -1], "another child's charm is not coloured by it")
	Profiles.remove(other_id)
	Profiles.set_active(kid_id)
	game_menu._colour_charm_button.pressed.emit()
	_check(colour_screen.is_open(), "the end-of-chapter panel offers colouring too")
	colour_screen.close()
	_check(not colour_screen.is_open() and not paused_now(), "closing it lets the game go on")
	Profiles.set_charm_colours(kid_id, "made_up_charm", [1, 2])
	_check(Profiles.charm_colours(kid_id, "made_up_charm") == [-1, -1, -1, -1, -1, -1], "colours can only be kept for a charm the child has earned")

	print("-- Faith Journal: for grown-ups --")
	journal.open()
	journal._show_gate()
	var hold: Button = journal._grownups_box.get_child(2)
	hold.button_down.emit()
	journal._process(1.0)
	hold.button_up.emit()
	journal._process(5.0)
	_check(journal._grownups_box.get_child(0).text == "For grown-ups", "letting go early does not open the grown-ups options")
	hold.button_down.emit()
	for _i in 4:
		journal._process(1.0)
	_check(journal._grownups_box.get_child(0).text == "What would you like to do?", "holding for %d seconds does" % int(journal.HOLD_SECONDS))
	journal._erase()
	_check(Profiles.get_profile(kid_id)["verses"].is_empty() and Profiles.get_profile(kid_id)["charms"].is_empty() and Profiles.count() == 1, "emptying the journal clears the verses and charms but keeps the child")
	_check(journal._verse_box.get_child(0) is Label and not (journal._charm_row.get_child(0) is Button), "and the journal shows it as empty")
	var removed_signal: Array = []
	journal.player_removed.connect(func() -> void: removed_signal.append(true))
	journal.player_removed.disconnect(game_menu._restart)   # the test scene is not the current scene, so it cannot be reloaded
	var leaving_id: String = Profiles.create("Leaving", "cloud")
	Profiles.set_active(leaving_id)
	journal._remove()
	_check(Profiles.get_profile(leaving_id).is_empty() and Profiles.active_id == "" and removed_signal.size() == 1 and not journal.is_open(), "removing a child takes them off the tablet and asks for the picker")
	Profiles.set_active(kid_id)
	_check(game_menu.has_method("change_player_and_restart") and game_menu._journal == journal, "the pause menu can open the journal and change player")

	print("-- Who is playing? screen --")
	_check(not picker.is_open() and not Profiles.picker_open, "the picker stays out of the way while a child is playing")
	Profiles.set_active("")
	picker.open()
	_check(picker.is_open() and paused_now() and Profiles.picker_open, "opening the picker pauses the game")
	_check(picker._profile_row.get_child_count() == Profiles.count() + 1, "it shows one button per child, and New")
	_check(vo_lib.LINES.has(picker.PICK_LINE) and vo_lib.LINES.has(picker.CREATE_LINE) and vo_lib.clip_for(picker.PICK_LINE) != null and vo_lib.clip_for(picker.CREATE_LINE) != null, "both lines of the screen have a recorded clip")
	await create_timer(0.8).timeout
	_check(vo_player.stream == vo_lib.clip_for(picker.PICK_LINE) and audio.process_mode == Node.PROCESS_MODE_ALWAYS, "it reads \"Who is playing?\" aloud for a child who cannot read yet")
	game_menu._input(pause_event)
	_check(paused_now() and not game_menu._pause_layer.visible, "the pause key does nothing behind the picker")
	_check(picker.create_profile("   ", "sun") == "" and picker._hint.text == "Type your name first", "an empty name is not accepted, and the hint says why")
	_check(Profiles.name_allowed("Maya") and Profiles.name_allowed("Cassie") and Profiles.name_allowed("Dickson"), "ordinary names, even ones that contain short words, are welcome")
	_check(not Profiles.name_allowed("Sh1t") and not Profiles.name_allowed("F u c k") and not Profiles.name_allowed("POOP") and not Profiles.name_allowed("  ass "), "a rude word is not accepted as a name, whatever the capitals, spaces or look-alike digits")
	var profiles_before: int = Profiles.count()
	_check(picker.create_profile("Sh1t", "sun") == "" and picker._hint.text == "Please pick a different name" and Profiles.count() == profiles_before, "and the hint asks for a different name without making a profile")
	picker._fit_to_keyboard(300.0)
	_check(is_equal_approx((picker._create_view.get_parent() as Control).offset_bottom, -300.0) and not (picker._title_labels[0] as Control).visible, "the name form lifts above the on-screen keyboard and drops its headings to fit")
	picker._fit_to_keyboard(0.0)
	_check(is_equal_approx((picker._create_view.get_parent() as Control).offset_bottom, 0.0) and (picker._title_labels[0] as Control).visible, "and goes back when the keyboard goes away")
	var made: String = picker.create_profile("Maya", "sun")
	_check(not made.is_empty() and Profiles.active_id == made and Profiles.active()["avatar"] == "sun" and chosen.back() == made, "a new child is made and chosen")
	_check(not picker.is_open() and not paused_now() and not Profiles.picker_open, "then the game carries on")
	Profiles.remove(made)
	Profiles.set_active(kid_id)
	picker.open()
	picker._show_create()
	picker._name_edit.text = "Zed"
	_check(picker.submit() == "" and picker._hint.text == "Pick your age" and Profiles.count() == 1, "a name without an age is not enough: the hint asks for the age")
	picker._select_age("younger")
	var zed: String = picker.submit()
	_check(not zed.is_empty() and GameSettings.easy_words and Profiles.get_profile(zed)["settings"]["easy_words"] == true, "a child who is 8 or younger gets Easy words, kept with them")
	Profiles.remove(zed)
	Profiles.set_active(kid_id)
	picker.open()
	picker._show_create()
	picker._name_edit.text = "Yan"
	picker._select_age("older")
	var yan: String = picker.submit()
	_check(not yan.is_empty() and not GameSettings.easy_words and Profiles.get_profile(yan)["settings"]["easy_words"] == false, "and one who is 9 or older gets the story as written")
	Profiles.remove(yan)
	Profiles.set_active(kid_id)
	GameSettings.easy_words = false
	picker.open()
	picker.choose(kid_id)
	_check(chosen.back() == kid_id and not picker.is_open(), "tapping a child chooses them")

	print("-- the story waits for a child to be chosen --")
	Profiles.set_active("")
	picker.open_if_nobody_is_playing()
	_check(picker.is_open() and paused_now(), "a fresh start shows Who is playing?")
	director.beat = director.Beat.DONE
	director.dialogue_label.text = ""
	director._start_story()
	_check(director.beat == director.Beat.DONE and director.dialogue_label.text == "", "and the story does not start yet")
	picker.choose(kid_id)
	var first_map: CanvasLayer = main.get_node("FaithJourney")
	_check(first_map.is_open() and first_map._choosing and paused_now() and director.beat == director.Beat.DONE,
			"choosing a child opens the Faith Journey map first, and the story still waits")
	first_map._on_stop("valley")
	_check(not first_map.is_open() and director.beat == director.Beat.ARRIVE and director.dialogue_label.text.contains("valley") and not paused_now(),
			"tapping the valley on the map starts chapter 1 right there")
	Profiles.set_active(kid_id)
	Profiles.current_chapter = Profiles.CHAPTER_VALLEY
	director.beat = director.Beat.DONE
	director._start_story()
	_check(director.beat == director.Beat.ARRIVE, "with a child already playing (Play again), the chapter they were on starts straight away")
	Profiles.current_chapter = Profiles.CHAPTER_CAMP
	director._start_story()
	await process_frame
	var replay_story: Node = main.get_node("KingsCamp/ChapterTwo")
	_check(director.beat == director.Beat.CAMP and replay_story.phase == replay_story.Phase.ARRIVE,
			"and Play again after the King's Camp goes back to the camp, not the valley")

	audio.stop_speech()   # the story was just restarted, so its first line may be playing
	vo_player.stream = null
	await create_timer(0.5).timeout   # the audio server lets go of finished sounds a moment later
	DirAccess.remove_absolute(TEST_PROFILES)
	sound_lib._cache.clear()  # the shared streams would otherwise be reported as leaked at exit
	vo_lib._cache.clear()
	print("")
	if _failures == 0:
		print("SMOKE TEST PASSED")
	else:
		print("SMOKE TEST FAILED (%d)" % _failures)
	quit(1 if _failures > 0 else 0)
