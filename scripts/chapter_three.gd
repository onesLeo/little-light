extends Node
## Chapter 3, The Beginning: Samuel comes to Jesse's home in Bethlehem and anoints David,
## the youngest, who is out with the sheep (1 Samuel 16:1-13). It is a look back, played
## after The King's Camp: "God sees the heart", with the Faithful Heart charm.
## Lives on the courtyard (jesses_house.gd), which stages the people and props; its lines, with
## their recorded clips, are in assets/dialogue/jesses_house.tres (docs/voice-over.md).
##
## The beats: turn back the page; prepare the welcome (carry the cushion, the cup and the lamp
## to the table, in any order, while David's harp, bowl and cloak can be found on the way);
## Samuel comes and Jesse welcomes him; the seven brothers pass before Samuel; "Yahweh has not
## chosen these"; the child calls David home; the verse (1 Samuel 16:7) and its three words;
## Samuel anoints David; the reflection; the Faithful Heart charm. The child never chooses the
## king and never pours the oil. Nothing can go wrong and nothing is timed.

const Profiles := preload("res://scripts/profiles.gd")
const JournalContent := preload("res://scripts/journal_content.gd")
const GameSettings := preload("res://scripts/game_settings.gd")
const DevicePrompts := preload("res://scripts/device_prompts.gd")
const GiftChecklist := preload("res://scripts/gift_checklist.gd")
const WordChip := preload("res://scripts/word_chip.gd")
const Hints := preload("res://scripts/wonder_item_hints.gd")
## The chapter's lines (dialogue_lines.gd).
const LINES := preload("res://assets/dialogue/jesses_house.tres")

enum Phase { IDLE, ARRIVE, WELCOME, MEET, PROCESSION, NOT_THESE, ASK, CALL, HOME, DAVID, VERSE, WORDS, ANOINT, REFLECT, CHARM, DONE }

const WELCOME_THINGS := ["Cushion", "Cup", "Lamp"]
const FIND_LINES := {"Harp": &"harp", "WaterBowl": &"bowl", "Cloak": &"cloak"}
const WORD_LABELS: PackedStringArray = ["God", "Sees", "Heart"]
const WELCOME_PROMPT := "Carry the cushion, the cup and the lamp to the table"
## The major beats the chapter can carry on from after the game was closed (Profiles places).
const RESUME_BEATS: PackedStringArray = ["welcome", "meet", "not_these", "call", "david", "reflect"]
## Seconds with no progress before the golden arrow points the way.
const HINT_DELAY := 12.0

var phase: Phase = Phase.IDLE
var _line: Label
var _prompt: Label
var _prompt_raw: String = ""
var _audio: Node
var _camera: Node
var _player: Node3D
var _checklist: GiftChecklist
var _words: HBoxContainer
var _word_buttons: Array[Button] = []
var _word_said: Array[bool] = [false, false, false]
var _hints: Hints
var _busy: bool = false
var _ceremony: bool = false


## Starts the story from its first line. The courtyard calls it (jesses_house.gd visit).
func begin() -> void:
	if phase != Phase.IDLE and phase != Phase.DONE:
		return
	var main := get_parent().get_parent()
	_line = main.find_child("DialogueLabel", true, false) as Label
	_prompt = main.find_child("PromptLabel", true, false) as Label
	_audio = main.get_node_or_null("AudioDirector")
	_camera = main.get_node_or_null("CameraDirector")
	_player = main.get_node_or_null("Player") as Node3D
	var input_setup := main.get_node_or_null("InputSetup")
	if input_setup and input_setup.has_signal("device_changed") and not input_setup.device_changed.is_connected(_on_device_changed):
		input_setup.device_changed.connect(_on_device_changed)
	if _audio and _audio.has_signal("line_started") and not _audio.line_started.is_connected(_on_line_started):
		_audio.line_started.connect(_on_line_started)
	# Coming from another chapter's end card, its "Chapter Complete!" banner must not hang over this one.
	var banner := main.find_child("CompleteBanner", true, false) as CanvasItem
	if banner:
		banner.visible = false
	_build_checklist(main.get_node("UI"))
	_build_words(main.get_node("UI"))
	_busy = false
	_ceremony = false
	_word_said = [false, false, false] as Array[bool]
	if _resume(Profiles.place_in(Profiles.active_id, Profiles.CHAPTER_BEGINNING)):
		return
	phase = Phase.ARRIVE
	_say([&"turn_back"], "Press Space to continue")


## Carries on from the last major beat this child reached (Profiles.mark_place), with the
## courtyard set as it stood then and that beat's line read again. False to start afresh.
func _resume(place: Dictionary) -> bool:
	var beat := str(place.get("beat", ""))
	var placed: Array = (place.get("placed", []) as Array).filter(func(t: Variant) -> bool: return t in WELCOME_THINGS) \
			if place.get("placed", []) is Array else []
	if not beat in RESUME_BEATS:
		return false
	var house := _house()
	house.set_scene_for(beat, placed)
	match beat:
		"welcome":
			phase = Phase.WELCOME
			house.open_welcome()
			_say([&"samuel_coming"], WELCOME_PROMPT)
			if _checklist:
				_checklist.set_found(house.placed())
			_watch()
		"meet":
			phase = Phase.MEET
			_say([&"jesse_welcome"], "Press Space to continue")
			house.meet_shot()
		"not_these":
			phase = Phase.NOT_THESE
			if _camera and _camera.has_method("cut_to_closeup"):
				_camera.cut_to_closeup(house.samuel())
			_say([&"not_these", &"waits"], "Press Space to continue")
		"call":
			phase = Phase.CALL
			_say([&"call_david"], "Press E to call David home")
		"david":
			phase = Phase.DAVID
			if _camera and _camera.has_method("cut_to_two_shot"):
				_camera.cut_to_two_shot(house.david(), house.samuel())
			_say([&"david_called"], "Press Space to continue")
		"reflect":
			phase = Phase.REFLECT
			if _player:
				house.watch_child(_player)
			_say([&"reflect"], "Press Space to continue")
	return true


## Remembers this beat for the child playing, so the chapter can carry on from it.
func _mark(beat: String, extra: Dictionary = {}) -> void:
	Profiles.mark_place(Profiles.CHAPTER_BEGINNING, beat, extra)


## Another story is starting: this one stops listening.
func stand_down() -> void:
	phase = Phase.IDLE
	if _hints:
		_hints.stop()


## The checklist, the word chips and the arrow live in the shared UI, outside the courtyard,
## so they go with it. They leave the UI at once, so a replay's new ones keep their names.
func _exit_tree() -> void:
	for node in [_words, _checklist]:
		if is_instance_valid(node):
			if node.get_parent():
				node.get_parent().remove_child(node)
			node.queue_free()


func _house() -> Node:
	return get_parent()


func _input(event: InputEvent) -> void:
	if phase == Phase.IDLE or _busy or _ceremony:
		return
	var tapped := _pressed(event)
	if phase == Phase.CALL and (tapped or event.is_action_pressed("interact")):
		_call_david()
		get_viewport().set_input_as_handled()
		return
	if tapped and phase in [Phase.ARRIVE, Phase.MEET, Phase.NOT_THESE, Phase.ASK, Phase.DAVID, Phase.VERSE, Phase.ANOINT, Phase.REFLECT, Phase.CHARM]:
		_advance()
		get_viewport().set_input_as_handled()


## Moves on from a beat that waits for the child (Space, Enter, or NEXT on a tablet).
func _advance() -> void:
	match phase:
		Phase.ARRIVE:
			phase = Phase.WELCOME
			_house().set_child_watch(null)
			_house().open_welcome()
			_mark("welcome", {"placed": []})
			_say([&"look_around", &"samuel_coming"], WELCOME_PROMPT)
			_watch()
		Phase.MEET:
			phase = Phase.PROCESSION
			_procession()
		Phase.NOT_THESE:
			phase = Phase.ASK
			_say([&"ask", &"youngest"], "Press Space to continue")
		Phase.ASK:
			phase = Phase.CALL
			_mark("call")
			_say([&"call_david"], "Press E to call David home")
		Phase.DAVID:
			phase = Phase.VERSE
			Profiles.unlock_verse(JournalContent.VERSE_SAMUEL_16_7)
			_celebrate_light()
			_say([JournalContent.verse_card(JournalContent.VERSE_SAMUEL_16_7)], "Press Space to continue")
		Phase.VERSE:
			phase = Phase.WORDS
			_say([&"heart"], "Tap God, Sees and Heart")
			_show_words(true)
		Phase.ANOINT:
			phase = Phase.REFLECT
			_mark("reflect")
			if _player:
				_house().watch_child(_player)
			_say([&"reflect"], "Press Space to continue")
		Phase.REFLECT:
			_award_charm()
		Phase.CHARM:
			_finish()


func _process(_delta: float) -> void:
	if phase != Phase.WELCOME or _player == null:
		return
	var house := _house()
	var at := _player.global_position
	var noticed: String = house.notice_find(at)
	if not noticed.is_empty():
		_say([FIND_LINES[noticed]], _prompt_raw)
		if _audio and _audio.has_method("play_tap"):
			_audio.play_tap()
	var reached: String = house.welcome_within_reach(at)
	if not reached.is_empty() and house.pick_up(reached):
		if _audio and _audio.has_method("play_pickup"):
			_audio.play_pickup()
		_set_prompt("Take the %s to the table" % reached.to_lower())
		_watch()
		return
	if house.in_carried_ring(at):
		var thing: String = house.place_carried()
		_on_placed(thing)


## A welcome thing is set on the table: its own sound, a tick on the list, and once all
## three are there, Samuel comes.
func _on_placed(thing: String) -> void:
	if _audio:
		match thing:
			"Cushion":
				if _audio.has_method("play_pickup"):
					_audio.play_pickup()
			"Cup":
				if _audio.has_method("play_tap"):
					_audio.play_tap()
			_:
				if _audio.has_method("play_success"):
					_audio.play_success()
	_celebrate_light()
	var done: Array = _house().placed()
	if _checklist:
		_checklist.set_found(done)
	if done.size() < WELCOME_THINGS.size():
		_mark("welcome", {"placed": done})
		_set_prompt(WELCOME_PROMPT)
		_watch()
		return
	phase = Phase.MEET
	_mark("meet")
	_busy = true
	if _hints:
		_hints.stop()
	_say([&"ready", &"jesse_welcome"], "Press Space to continue")
	var walk: Tween = _house().samuel_to_table()
	await walk.finished
	if phase != Phase.MEET:
		return
	_busy = false
	_house().meet_shot()


## Jesse's sons pass before Samuel, one by one. The camera stays still while they move.
func _procession() -> void:
	_busy = true
	_say([&"brothers"], "")
	var sons: Node = _house().sons()
	# A still view of the whole row and Samuel; only the brothers move.
	_house().procession_shot()
	_house().watch_brothers()
	sons.pass_before(_house().samuel().global_position)
	await sons.procession_finished
	if phase != Phase.PROCESSION:
		return
	_busy = false
	phase = Phase.NOT_THESE
	_mark("not_these")
	if _camera and _camera.has_method("cut_to_closeup"):
		_camera.cut_to_closeup(_house().samuel())
	_say([&"not_these", &"waits"], "Press Space to continue")


## The child calls: a soft chime, and David comes home along the sheep path.
func _call_david() -> void:
	phase = Phase.HOME
	_busy = true
	if _audio and _audio.has_method("play_success"):
		_audio.play_success()
	_celebrate_light()
	_set_prompt("")
	var walk: Tween = _house().david_comes_home()
	await walk.finished
	if phase != Phase.HOME:
		return
	_busy = false
	phase = Phase.DAVID
	_mark("david")
	if _camera and _camera.has_method("cut_to_two_shot"):
		_camera.cut_to_two_shot(_house().david(), _house().samuel())
	_say([&"david_called"], "Press Space to continue")


## One of God, Sees and Heart. Tapping all three (in any order) moves on to the anointing.
func press_word(index: int) -> void:
	if phase != Phase.WORDS or _word_said[index]:
		return
	_word_said[index] = true
	var chip := _word_buttons[index] as WordChip
	chip.set_lit(true)
	chip.set_beckon(false)
	chip.pop()
	if _audio and _audio.has_method("speak_lines"):
		_audio.speak_lines([{"speaker": "Wonder Light", "text": WORD_LABELS[index] + "."}] as Array[Dictionary])
	if _word_said.has(false):
		return
	_show_words(false)
	_anoint()


## Samuel anoints David. The child watches; the camera holds still while the breeze moves.
func _anoint() -> void:
	phase = Phase.ANOINT
	_busy = true
	if _camera and _camera.has_method("cut_to_two_shot"):
		_camera.cut_to_two_shot(_house().samuel(), _house().david())
	_say([&"anoint"], "…")
	_house().set_child_watch(_house().david())
	var pour: Tween = _house().anoint()
	await pour.finished
	if phase != Phase.ANOINT:
		return
	_busy = false
	_set_prompt("Press Space to continue")


func _award_charm() -> void:
	phase = Phase.CHARM
	Profiles.unlock_charm(JournalContent.CHARM_FAITHFUL_HEART)
	_say([&"charm", &"charm_arrives"], "…")
	var main := get_parent().get_parent()
	var award := main.get_node_or_null("CharmAward") as Node3D
	if award == null or _player == null or not award.has_method("play_ceremony"):
		_on_charm_sealed()
		return
	_ceremony = true
	if "can_move" in _player:
		_player.can_move = false
	award.global_position = _player.global_position + Vector3(0.35, 1.15, 0.9)
	# The child turns to the charm as it floats in, towards the camera.
	_house().set_child_watch(award)
	if _camera and _camera.has_method("cut_to_charm"):
		_camera.cut_to_charm(award)
	award.ceremony_finished.connect(_on_charm_sealed, CONNECT_ONE_SHOT)
	award.play_ceremony(JournalContent.CHARM_FAITHFUL_HEART)


func _on_charm_sealed() -> void:
	_ceremony = false
	_set_prompt("Press Space to keep your charm")


func _finish() -> void:
	phase = Phase.DONE
	_house().set_child_watch(null)
	var main := get_parent().get_parent()
	Profiles.finish_chapter(Profiles.CHAPTER_BEGINNING)
	_say([&"keep_close"], "Well done, Wonder-Walker!")
	if main.has_method("play_finale"):
		main.play_finale("Chapter 3 Complete!")
	var menu := main.get_node_or_null("GameMenu")
	if menu and menu.has_method("show_end_panel"):
		menu.show_end_panel(JournalContent.CHARM_FAITHFUL_HEART)


## What the touch button says now ("" = nothing to do), for touch_controls.gd.
func get_action_hint() -> String:
	if _busy or phase in [Phase.IDLE, Phase.WELCOME, Phase.WORDS, Phase.PROCESSION, Phase.HOME, Phase.DONE]:
		return ""
	if phase == Phase.CALL:
		return "CALL"
	if phase == Phase.CHARM and _ceremony:
		return ""
	return "NEXT"


## Shows `parts` (the chapter's lines by id, or shared text such as the verse) and reads them
## aloud, with the camera and the child's walking set for the beat.
func _say(parts: Array, prompt: String) -> void:
	var said: Dictionary = LINES.block(parts, GameSettings.easy_words)
	if _player and "can_move" in _player:
		_player.can_move = phase in [Phase.WELCOME, Phase.DONE]
	if _camera and phase in [Phase.ARRIVE, Phase.WELCOME, Phase.CALL, Phase.HOME, Phase.REFLECT, Phase.DONE]:
		if _camera.has_method("cut_to_tabletop"):
			_camera.cut_to_tabletop()
	if _checklist:
		_checklist.visible = phase == Phase.WELCOME
	if _line:
		_line.text = said["text"]
	_set_prompt(prompt)
	var shell := get_parent().get_parent()
	if shell.has_method("fit_dialogue"):
		shell.fit_dialogue()
	var first: Array = said["spoken"]
	_house().set_speaking("" if first.is_empty() else String(first[0]["speaker"]))
	if _audio and _audio.has_method("speak_lines"):
		_audio.speak_lines(said["spoken"])


func _on_line_started(line: Dictionary) -> void:
	if phase != Phase.IDLE:
		_house().set_speaking(String(line.get("speaker", "")))


## Prompts are written for the keyboard and worded for the device used last (device_prompts.gd).
## On a tablet the gold button says CALL when David is to be called.
func _set_prompt(raw: String) -> void:
	_prompt_raw = raw
	if _prompt:
		var input_setup := get_parent().get_parent().get_node_or_null("InputSetup")
		_prompt.text = DevicePrompts.reword(raw, input_setup, "CALL")


func _on_device_changed(_mode: String) -> void:
	if phase == Phase.IDLE:
		return
	_set_prompt(_prompt_raw)


## The golden arrow (wonder_item_hints.gd) points at the next welcome thing, or at the ring
## for the one being carried, after a little while with no progress.
func _watch() -> void:
	var house := _house()
	if _hints == null:
		_hints = Hints.new()
		_hints.name = "WelcomeHints"
		_hints.main = house.get_parent()
		_hints.hint_delay = HINT_DELAY
		house.add_child(_hints)
	_hints.stop()
	_hints.watch(house.welcome_spots())


func _celebrate_light() -> void:
	var light := get_parent().get_parent().get_node_or_null("WonderLight")
	if light and light.has_method("celebrate"):
		light.celebrate()


func _build_checklist(ui: Node) -> void:
	if is_instance_valid(_checklist):
		_checklist.queue_free()
	_checklist = GiftChecklist.new(WELCOME_THINGS, "Getting ready for Samuel")
	_checklist.name = "WelcomeChecklist"
	_checklist.position = Vector2(24, 90)
	_checklist.visible = false
	ui.add_child(_checklist)


func _build_words(ui: Node) -> void:
	if is_instance_valid(_words):
		_words.queue_free()
	_word_buttons.clear()
	_words = HBoxContainer.new()
	_words.name = "BeginningWords"
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


func _pressed(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_accept"):
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		return k == KEY_SPACE or k == KEY_ENTER
	return false
