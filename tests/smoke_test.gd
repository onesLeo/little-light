extends SceneTree
## Headless smoke test — not part of the shipped game.
## Run with (from the project folder, after opening it in the editor at
## least once so assets are imported — or `godot --headless --import .`):
##   godot --headless --path . --script tests/smoke_test.gd
## Instances main.tscn directly (no window/input needed) and drives the
## beat machine + minigame + companion/camera wiring programmatically to
## catch null-ref / bad-node-path errors the passive idle run can't reach.
## Exits 0 on success, 1 if any check fails (CI-friendly).

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

func _initialize() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame  # let _ready() propagate through the tree first

	var director: Node = main.get_node("ChapterDirector")
	var wonder_light: Node = main.get_node("WonderLight")
	var steady_hands: Node = main.get_node("SteadyHands")
	var breath: Control = main.get_node("UI/BreathIndicator")
	var closeup_cam: Camera3D = main.get_node("CloseUpCamera")
	var tabletop_cam: Camera3D = main.get_node("TabletopCamera")
	var david: Node3D = main.get_node("DavidMentor")
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

	print("-- pause menu --")
	game_menu.set_paused(true)
	_check(paused, "pause action pauses the tree")
	game_menu.set_paused(false)
	_check(not paused, "resuming unpauses the tree")

	print("-- meeting David cuts to close-up + points Wonder Light --")
	# The characters finish turning before the dialogue camera cuts.
	await director._enter_beat(director.Beat.MEET_DAVID_A)
	_check(closeup_cam.current == true, "MEET_DAVID_A cuts to close-up")
	_check(tabletop_cam.current == false, "tabletop stops being current after cut")
	_check(wonder_light._look_target == david, "Wonder Light looks at David during MEET_DAVID_A")

	print("-- steady hands starts the breathing indicator --")
	director._enter_beat(director.Beat.STEADY_PLAY)
	_check(steady_hands.active == true, "minigame active after STEADY_PLAY")
	_check(breath.visible == true, "breath indicator visible while minigame active")

	print("-- tapping completes the minigame and signals the director --")
	# NOTE: a lambda connected here would capture a local bool BY VALUE in
	# GDScript (reassigning it inside the callback wouldn't be visible out
	# here), so we use the instance var _minigame_signal_fired instead.
	steady_hands.minigame_completed.connect(_on_test_minigame_completed)
	steady_hands._on_tap()
	# The success feedback is a ~0.9s tween (bloom + fade) before the signal
	# fires by design — give it real frames to actually finish before checking.
	for i in range(180):
		await process_frame
		if _minigame_signal_fired:
			break
	_check(_minigame_signal_fired, "minigame_completed fires after the success tween finishes")
	_check(steady_hands.active == false, "minigame deactivates after success")

	print("-- item collection triggers Wonder Light celebrate() without error --")
	director._enter_beat(director.Beat.EXPLORE)
	_check(tabletop_cam.current == true, "EXPLORE cuts back to tabletop")
	var stone: Area3D = main.get_node("WonderItems/WonderItem_Stone")
	director._near_item = stone
	director._try_collect_near_item()
	_check(director.wonder_items_found == 1, "collecting an item increments the counter")

	print("-- reflect beat returns to the wide tabletop shot --")
	director._enter_beat(director.Beat.REFLECT)
	_check(tabletop_cam.current == true, "REFLECT is a tabletop (wide) shot")

	print("-- full beat traversal reaches DONE without throwing --")
	for b in [director.Beat.MEET_DAVID_B, director.Beat.STEADY_INTRO, director.Beat.STEADY_DONE,
			director.Beat.RESOLUTION, director.Beat.REFLECT, director.Beat.VERSE_REWARD, director.Beat.DONE]:
		director._enter_beat(b)
	_check(director.beat == director.Beat.DONE, "beat machine reaches DONE cleanly")

	print("-- end of chapter offers Play again --")
	await create_timer(0.3).timeout
	_check(game_menu._end_panel.visible, "end panel appears after the chapter finishes")

	print("")
	if _failures == 0:
		print("SMOKE TEST PASSED")
	else:
		print("SMOKE TEST FAILED (%d)" % _failures)
	quit(1 if _failures > 0 else 0)
