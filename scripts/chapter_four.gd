extends Node
## Noah's Ark. Find three building things, finish one panel, guide three animal
## pairs, watch the others board, then the dove, the rainbow and the Trust charm.

const JournalContent := preload("res://scripts/journal_content.gd")
const Profiles := preload("res://scripts/profiles.gd")
const WordChip := preload("res://scripts/word_chip.gd")
const PaperUI := preload("res://scripts/paper_ui.gd")
const GiftChecklist := preload("res://scripts/gift_checklist.gd")
const Hints := preload("res://scripts/wonder_item_hints.gd")
const GameSettings := preload("res://scripts/game_settings.gd")
const EasyWords := preload("res://scripts/easy_words.gd")

enum Phase { IDLE, ARRIVE, HURT, FIND, MEET, PANEL, PAIRS, BOARDING, DOOR, RAIN, DOVE, SKY, LEAF, OLIVE, DRY, VERSE, WORDS, REFLECT, CHARM, DONE }

const WORD_LABELS: PackedStringArray = ["Rainbow", "Sign", "Promise"]
const WORD_LINES: PackedStringArray = ["Rainbow.", "Sign.", "Promise."]
const ROPE_STEP := 1.35
const TOOLS := ["Mallet", "RopeCoil", "Pitch"]
## Walking this close to a tool picks it up, as the gifts do in the camp.
const PICKUP_REACH := 1.4
## How long before the golden arrow helps: the hunt, the bench, choosing an animal,
## and finding its partner (the concept's "four idle seconds").
const HINT_FIND := 14.0
const HINT_PANEL := 8.0
const HINT_CHOOSE := 10.0
const HINT_MATE := 4.0
const ITEMS := {
	"Mallet": "A wooden mallet. Noah builds with it.",
	"RopeCoil": "A coil of rope. It holds the ark together.",
	"Pitch": "A jar of sticky pitch. It keeps water out.",
}

var phase: Phase = Phase.IDLE
var _found: Array[String] = []
var _pegs: int = 0
var _rope_steps: int = 0
var _rope_held: float = 0.0
var _guide: String = ""
var _matched: int = 0
var _mismatch_said: bool = false
var _dove_flights: int = 0
var _sky_turns: int = 0
var _dove_busy: bool = false
var _ceremony: bool = false
var _words_done: bool = false
var _word_said: Array[bool] = [false, false, false]
var _words: HBoxContainer
var _word_buttons: Array[Button] = []
var _line: Label
var _prompt: Label
var _audio: Node
var _camera: Node
var _player: Node3D
var _checklist: GiftChecklist
var _hints: Hints


func begin() -> void:
	if phase != Phase.IDLE and phase != Phase.DONE:
		return
	phase = Phase.ARRIVE
	_found.clear()
	_pegs = 0
	_rope_steps = 0
	_rope_held = 0.0
	_guide = ""
	_matched = 0
	_mismatch_said = false
	_dove_flights = 0
	_sky_turns = 0
	_dove_busy = false
	_ceremony = false
	_words_done = false
	_word_said = [false, false, false]
	var main := get_parent().get_parent()
	_line = main.find_child("DialogueLabel", true, false) as Label
	_prompt = main.find_child("PromptLabel", true, false) as Label
	_audio = main.get_node_or_null("AudioDirector")
	_camera = main.get_node_or_null("CameraDirector")
	_player = main.get_node_or_null("Player") as Node3D
	var banner := main.find_child("CompleteBanner", true, false) as CanvasItem
	if banner:
		banner.visible = false
	_build_words(main.get_node("UI"))
	_build_checklist(main.get_node("UI"))
	_watch(Phase.IDLE)
	_say("Wonder Light: \"Long before David, God asked Noah to trust him and build something no one had seen before.\"", "Press Space to continue")


## The word chips and the tool list live in the shared UI, outside the ark, so they go with it.
## They leave the UI at once, so a replay's new ones keep their names.
func _exit_tree() -> void:
	for node in [_words, _checklist]:
		if is_instance_valid(node):
			if node.get_parent():
				node.get_parent().remove_child(node)
			node.queue_free()


func _input(event: InputEvent) -> void:
	if phase == Phase.IDLE or phase == Phase.DONE or _ceremony or phase == Phase.BOARDING:
		return
	if phase == Phase.WORDS and not _words_done:
		return
	if not _pressed(event) and not event.is_action_pressed("interact"):
		return
	if phase == Phase.FIND:
		_try_collect()
	elif phase == Phase.PANEL:
		if _pegs < 3:
			_place_peg()
		# The rope uses the hold in _process. A tap still counts as a short pull.
		elif event.is_action_pressed("interact") or _pressed(event):
			add_rope(0.45)
	elif phase == Phase.PAIRS:
		_try_guide()
	elif phase == Phase.DOVE or phase == Phase.LEAF:
		_send_dove()
	elif phase == Phase.SKY:
		_turn_sky()
	else:
		_advance()
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	# Walking onto a glowing tool picks it up; E (or the button) still works from a step away.
	if phase == Phase.FIND and _player and not get_parent().nearest_item(_player.global_position, PICKUP_REACH).is_empty():
		_try_collect()
	if phase != Phase.PANEL or _pegs < 3 or _rope_steps >= 2:
		_follow(delta)
		return
	if Input.is_action_pressed("interact") or Input.is_action_pressed("ui_accept"):
		add_rope(delta)
	_follow(delta)


func _follow(delta: float) -> void:
	if phase != Phase.PAIRS or _guide.is_empty() or _player == null:
		return
	var ark := get_parent()
	ark.follow(_guide, _player.global_position + Vector3(0.0, 0.0, 0.8), delta)
	if ark.near_mate(_guide, 1.7):
		_finish_guide()
	elif ark.wrong_mate_near(_guide, 1.7) and not _mismatch_said:
		_mismatch_said = true
		_say("Wonder Light: \"This friend is looking for its match.\"", "Walk to the animal that looks the same")


func _advance() -> void:
	match phase:
		Phase.ARRIVE:
			phase = Phase.HURT
			_say("Wonder Light: \"People were hurting one another, and the world was full of violence.\"", "Press Space to continue")
		Phase.HURT:
			phase = Phase.FIND
			_watch(phase)
			_say("Wonder Light: \"Find the mallet, the rope, and the jar of pitch. Bring them to Noah.\"", "Walk to a glowing tool")
		Phase.MEET:
			phase = Phase.PANEL
			get_parent().highlight_socket(0)
			_watch(phase)
			_say("Wonder Light: \"Let's finish this panel. Three pegs, then draw the rope tight.\"", "Press E at the panel")
		Phase.DOOR:
			phase = Phase.RAIN
			_watch(phase)
			get_parent().set_weather("rain")
			_say("Wonder Light: \"The water covered the land. God kept Noah's family, and the animals with them, safe inside.\"", "Press Space to continue")
		Phase.RAIN:
			phase = Phase.DOVE
			get_parent().set_weather("waiting")
			_say("Wonder Light: \"Let's open the window and send the dove.\"", "Press E to send the dove")
		Phase.OLIVE:
			phase = Phase.DRY
			get_parent().set_weather("morning")
			get_parent().close_door(false)
			get_parent().leave_ark()
			_say("Noah: \"Dry ground. Thank you for keeping us safe.\"", "Press Space to continue")
		Phase.DRY:
			get_parent().reveal_rainbow()
			phase = Phase.VERSE
			Profiles.unlock_verse(JournalContent.VERSE_GENESIS_9_13)
			_say("Genesis 9:13 (WEB):\n\"I set my rainbow in the cloud, and it will be a sign of a covenant between me and the earth.\"", "Press Space to continue")
		Phase.VERSE:
			phase = Phase.WORDS
			_words_done = false
			_show_words(true)
			if _player and "can_move" in _player:
				_player.can_move = false
			if _prompt:
				_prompt.text = "Tap Rainbow, Sign, and Promise"
		Phase.REFLECT:
			_award_charm()
		Phase.CHARM:
			_finish()


func _try_collect() -> void:
	if _player == null:
		return
	var ark := get_parent()
	var tool_name: String = ark.nearest_item(_player.global_position, 2.4)
	if tool_name.is_empty() or tool_name in _found:
		return
	_found.append(tool_name)
	ark.take_item(tool_name)
	if _checklist:
		_checklist.set_found(_found)
	if _hints:
		_hints.found(tool_name)
	if _audio and _audio.has_method("play_pickup"):
		_audio.play_pickup()
	var light := get_parent().get_parent().get_node_or_null("WonderLight")
	if light and light.has_method("celebrate"):
		light.celebrate()
	if _found.size() >= 3:
		phase = Phase.MEET
		_watch(phase)
		_say("Noah: \"God told me to build this ark. I cannot see the rain yet, but I trust him.\"", "Press Space to continue")
	else:
		_say("Wonder Light: \"%s\"" % ITEMS[tool_name], "Find the other glowing tools")


func _place_peg() -> void:
	if _player == null:
		return
	var panel := get_parent().get_node_or_null("WorkPanel") as Node3D
	if panel and _player.global_position.distance_to(panel.global_position) > 3.2:
		return
	get_parent().show_peg(_pegs)
	_pegs += 1
	get_parent().highlight_socket(_pegs if _pegs < 3 else -1)
	if _hints:
		_hints.stop()
	if _audio and _audio.has_method("play_tap"):
		_audio.play_tap()
	# The line was just said; only the next step changes, so it is not read out again.
	_set_prompt("Hold E to pull the rope  •  0 / 2" if _pegs >= 3 else "Press E for the next peg  •  %d / 3" % _pegs)


func add_rope(delta: float) -> void:
	if phase != Phase.PANEL or _pegs < 3 or _rope_steps >= 2:
		return
	_rope_held += delta
	get_parent().set_rope((float(_rope_steps) + clampf(_rope_held / ROPE_STEP, 0.0, 1.0)) / 2.0)
	if _rope_held < ROPE_STEP:
		return
	_rope_held = 0.0
	_rope_steps += 1
	if _audio and _audio.has_method("play_tap"):
		_audio.play_tap()
	if _rope_steps >= 2:
		_begin_pairs()
	else:
		_set_prompt("Tighter! Hold E again  •  %d / 2" % _rope_steps)


func _begin_pairs() -> void:
	phase = Phase.PAIRS
	get_parent().show_beacons(true)
	_watch(phase)
	_say("Wonder Light: \"Two by two, they're coming. Help these animals find their partners.\"\nNoah's wife: \"This way. Walk together up the wide ramp.\"", "Press E beside an animal")


func _try_guide() -> void:
	if _player == null or not _guide.is_empty():
		return
	var critter_name: String = get_parent().nearest_guide(_player.global_position, 2.6)
	if critter_name.is_empty():
		return
	_guide = critter_name
	_mismatch_said = false
	get_parent().mark_mate(_guide, true)
	_watch(phase)
	_set_prompt("Walk to the animal that looks the same")


func _finish_guide() -> void:
	var ark := get_parent()
	ark.mark_mate(_guide, false)
	ark.board_pair(_guide)
	_guide = ""
	_matched += 1
	_watch(phase)
	if _audio and _audio.has_method("play_success"):
		_audio.play_success()
	if _matched < 3:
		_say("Wonder Light: \"Two by two, they're coming. Help these animals find their partners.\"", "Guide the next pair  •  %d / 3" % _matched)
		return
	ark.board_remaining()
	phase = Phase.BOARDING
	ark.show_beacons(false)
	_watch(phase)
	ark.family_inside()
	ark.keep_guest_outside(_player)
	_say("", "Watch the animals and Noah's family walk aboard")
	if ark.is_boarding():
		await ark.boarding_finished
	if phase != Phase.BOARDING:
		return
	phase = Phase.DOOR
	ark.close_door(true)
	_say("Wonder Light: \"Noah's family and the animals are safely inside. God closes the door and keeps them safe.\"", "Press Space to continue")


func _send_dove() -> void:
	if _dove_busy:
		return
	_dove_busy = true
	_dove_flights += 1
	var ark := get_parent()
	_set_prompt("Watch the dove fly")
	await ark.fly_dove(_dove_flights == 2)
	_on_dove_back()


func _on_dove_back() -> void:
	if not _dove_busy:
		return
	_dove_busy = false
	var ark := get_parent()
	if _dove_flights == 1:
		phase = Phase.SKY
		_say("Wonder Light: \"The dove came back safe. The water is still too high.\"", "Press E to turn the sky")
	else:
		ark.show_leaf(true)
		phase = Phase.OLIVE
		_say("Wonder Light: \"Look, an olive leaf. The water is going down.\"", "Press Space to continue")


func _turn_sky() -> void:
	_sky_turns += 1
	var ark := get_parent()
	if _sky_turns == 1:
		# Days pass: the water goes down a little. The line has been said, so only the prompt moves on.
		ark.set_weather("receding")
		_set_prompt("The water is going down. Press E to turn the sky again")
		return
	phase = Phase.LEAF
	_say("Wonder Light: \"Let's open the window and send the dove.\"", "Press E to send the dove")


func _build_words(ui: Node) -> void:
	if _words and is_instance_valid(_words):
		_words.queue_free()
	_word_buttons.clear()
	_words = HBoxContainer.new()
	_words.name = "ArkWords"
	_words.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_words.offset_left = -380.0
	_words.offset_right = 380.0
	_words.offset_top = -250.0
	_words.offset_bottom = -150.0
	_words.alignment = BoxContainer.ALIGNMENT_CENTER
	_words.add_theme_constant_override("separation", 36)
	_words.visible = false
	ui.add_child(_words)
	for i in WORD_LABELS.size():
		var chip := WordChip.new(WORD_LABELS[i], Vector2(200, 86), 32)
		chip.pressed.connect(press_word.bind(i))
		_words.add_child(chip)
		_word_buttons.append(chip)


func _show_words(on: bool) -> void:
	if _words:
		_words.visible = on
	for i in _word_buttons.size():
		(_word_buttons[i] as WordChip).set_beckon(on and not _word_said[i])


func press_word(index: int) -> void:
	if phase != Phase.WORDS or _word_said[index]:
		return
	_word_said[index] = true
	var chip := _word_buttons[index] as WordChip
	chip.set_lit(true)
	chip.set_beckon(false)
	chip.pop()
	if _audio and _audio.has_method("play_line"):
		_audio.play_line(WORD_LINES[index])
	if _word_said[0] and _word_said[1] and _word_said[2]:
		_words_done = true
		_show_words(false)
		phase = Phase.REFLECT
		_say("Wonder Light: \"God's covenant is a promise God chooses to keep.\"", "Press Space to continue")


func _award_charm() -> void:
	phase = Phase.CHARM
	_show_words(false)
	Profiles.unlock_charm(JournalContent.CHARM_TRUST)
	_say("Wonder Light: \"A Trust charm. Noah kept building before he could see the rain.\"\n(Virtue Bracelet receives the charm.)", "…")
	var main := get_parent().get_parent()
	var award := main.get_node_or_null("CharmAward") as Node3D
	if award == null or _player == null or not award.has_method("play_ceremony"):
		_on_charm_sealed()
		return
	_ceremony = true
	if "can_move" in _player:
		_player.can_move = false
	award.global_position = _player.global_position + Vector3(0.35, 1.15, 0.9)
	if _camera and _camera.has_method("cut_to_charm"):
		_camera.cut_to_charm(award)
	award.ceremony_finished.connect(_on_charm_sealed, CONNECT_ONE_SHOT)
	award.play_ceremony(JournalContent.CHARM_TRUST)


func _on_charm_sealed() -> void:
	_ceremony = false
	if _prompt:
		_prompt.text = "Press Space to keep your charm"


func _finish() -> void:
	phase = Phase.DONE
	_show_words(false)
	_watch(phase)
	var main := get_parent().get_parent()
	Profiles.finish_chapter(Profiles.CHAPTER_ARK)
	if _camera and _camera.has_method("cut_to_tabletop"):
		_camera.cut_to_tabletop()
	if _player and "can_move" in _player:
		_player.can_move = true
	_say("Wonder Light: \"Keep it close. Trust God, even before you see the way through.\"", "Well done, Wonder-Walker!")
	var director := main.get_node_or_null("ChapterDirector")
	if director and director.has_method("play_finale"):
		director.play_finale("Chapter 4 Complete!")
	var menu := main.get_node_or_null("GameMenu")
	if menu and menu.has_method("show_end_panel"):
		menu.show_end_panel(JournalContent.CHARM_TRUST)


func _say(text: String, prompt: String) -> void:
	if GameSettings.easy_words:
		text = EasyWords.apply(text)
	if _checklist:
		_checklist.visible = phase in [Phase.FIND, Phase.MEET]
	var ark := get_parent()
	var speaker := ""
	if text.begins_with("Noah's wife:"):
		speaker = "Noah's wife"
	elif text.begins_with("Noah:"):
		speaker = "Noah"
	ark.set_speaking(speaker)
	var moving := phase in [Phase.FIND, Phase.PANEL, Phase.PAIRS, Phase.DONE]
	if _player and "can_move" in _player:
		_player.can_move = moving
	if _camera:
		if phase == Phase.MEET and ark.get_node_or_null("Noah"):
			_camera.cut_to_closeup(ark.get_node("Noah"))
		elif phase != Phase.CHARM:
			_camera.cut_to_tabletop()
	if phase == Phase.RAIN:
		ark.show_story_shot("shelter")
	elif phase in [Phase.DOVE, Phase.SKY, Phase.LEAF]:
		ark.show_story_shot("window")
	elif phase == Phase.OLIVE:
		ark.show_story_shot("leaf")
	elif phase in [Phase.VERSE, Phase.REFLECT]:
		ark.show_story_shot("rainbow")
	else:
		ark.show_story_shot("")
	if _line:
		_line.text = text
	_set_prompt(prompt)
	var director := get_parent().get_parent().get_node_or_null("ChapterDirector")
	if director and director.has_method("_fit_dialogue_panel"):
		director._fit_dialogue_panel()
	if _audio and _audio.has_method("speak_dialogue"):
		_audio.speak_dialogue(text)


func _pressed(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_accept"):
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.physical_keycode == KEY_ENTER
	return false


func _set_prompt(raw: String) -> void:
	if _prompt:
		_prompt.text = _device_prompt(raw)


## Prompts are written for the keyboard. On a tablet or a gamepad they name that
## device's buttons instead, as chapters 1 and 2 do.
func _device_prompt(raw: String) -> String:
	var input_setup := get_parent().get_parent().get_node_or_null("InputSetup")
	var mode: String = input_setup.mode if input_setup and "mode" in input_setup else "keyboard"
	match mode:
		"touch":
			return raw.replace("Press Space", "Tap NEXT").replace("Press E", "Tap the gold button") \
					.replace("Hold E", "Hold the gold button")
		"gamepad":
			return raw.replace("Press Space", "Press A").replace("Press E", "Press A").replace("Hold E", "Hold A")
	return raw


## What the on-screen action button says right now ("" = nothing to do), for touch_controls.gd.
func get_action_hint() -> String:
	var ark := get_parent()
	match phase:
		Phase.IDLE, Phase.DONE, Phase.BOARDING:
			return ""
		Phase.FIND:
			return "GRAB" if _player and not ark.nearest_item(_player.global_position, 2.4).is_empty() else ""
		Phase.PANEL:
			if _pegs >= 3:
				return "PULL"
			var panel := ark.get_node_or_null("WorkPanel") as Node3D
			return "PEG" if _player and panel and _player.global_position.distance_to(panel.global_position) <= 3.2 else ""
		Phase.PAIRS:
			if not _guide.is_empty() or _player == null:
				return ""
			return "LEAD" if not ark.nearest_guide(_player.global_position, 2.6).is_empty() else ""
		Phase.DOVE, Phase.LEAF:
			return "" if _dove_busy else "SEND"
		Phase.SKY:
			return "TURN"
		Phase.WORDS:
			return "NEXT" if _words_done else ""
	return "" if _ceremony else "NEXT"


func _build_checklist(ui: Node) -> void:
	if is_instance_valid(_checklist):
		_checklist.queue_free()
	_checklist = GiftChecklist.new(TOOLS, "Tools for Noah", {"RopeCoil": "Rope"})
	_checklist.name = "ArkToolChecklist"
	_checklist.position = Vector2(24, 90)
	_checklist.visible = false
	ui.add_child(_checklist)


## The golden arrow (wonder_item_hints.gd) helps with whatever this step is looking for,
## after a little while with no progress.
func _watch(step: Phase) -> void:
	var ark := get_parent()
	if _hints == null:
		_hints = Hints.new()
		_hints.name = "ArkHints"
		_hints.main = ark.get_parent()
		ark.add_child(_hints)
	_hints.stop()
	match step:
		Phase.FIND:
			_hints.hint_delay = HINT_FIND
			_hints.watch(ark.tool_spots())
		Phase.PANEL:
			_hints.hint_delay = HINT_PANEL
			_hints.watch([ark.panel_spot()])
		Phase.PAIRS:
			if _guide.is_empty():
				_hints.hint_delay = HINT_CHOOSE
				_hints.watch(ark.guide_spots())
			else:
				_hints.hint_delay = HINT_MATE
				_hints.watch([ark.mate_spot(_guide)])
