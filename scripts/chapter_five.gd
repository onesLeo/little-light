extends Node
## Chapter 5, Jonah and the Great Fish (Jonah 1-4): God asks Jonah to go to Nineveh, and Jonah
## sails the other way; the storm, the great fish, Jonah's prayer, another chance, Nineveh
## turning from wrong, and the plant God grew and took away. "Mercy", with the Mercy charm: mercy
## for Jonah, for the frightened sailors, and for a whole city Jonah did not want forgiven.
## Lives on the world (jonahs_journey.gd), which stages the places, people and props; its lines,
## with their clips, are in assets/dialogue/jonahs_journey.tres (docs/voice-over.md).
##
## The beats: arrive at Joppa (the road to Nineveh, the ship the other way); find Jonah's bag,
## message and lamp; meet Jonah; walk to the gangway after him; out at sea, Secure the Cargo
## (three loose pieces to their outlined spaces, in any order) while the storm rises; the captain
## and Jonah speak; Jonah goes into the sea behind a great wave and the storm stops; the great
## fish rises; inside it, Prayer in the Deep (Call, Hear, Go, each light drifting to Wonder
## Light); the verse (Jonah 2:2); the shore; walking with Jonah to Nineveh's gate; his warning
## and the city's answer; the plant on the hill; God's question; the reflection; the Mercy charm.
## The child never throws Jonah or controls the sea. Nothing can go wrong and nothing is timed,
## but the sea's beats carry on by themselves if the child stops tapping (docs/chapter-5-concept.md).

const Profiles := preload("res://scripts/profiles.gd")
const JournalContent := preload("res://scripts/journal_content.gd")
const GameSettings := preload("res://scripts/game_settings.gd")
const DevicePrompts := preload("res://scripts/device_prompts.gd")
const GiftChecklist := preload("res://scripts/gift_checklist.gd")
const WordChip := preload("res://scripts/word_chip.gd")
const Hints := preload("res://scripts/wonder_item_hints.gd")
## The chapter's lines (dialogue_lines.gd).
const LINES := preload("res://assets/dialogue/jonahs_journey.tres")

enum Phase { IDLE, ARRIVE, FIND, MEET, BOARD, CARGO, STORM, ADMIT, PLEAD, OVERBOARD, FISH, PRAY, VERSE, THANKS,
		SHORE, FOLLOW, WARNING, LISTENED, HILL, WITHER, QUESTION, REFLECT, CHARM, DONE }

const THINGS := ["Bag", "Message", "Lamp"]
const FIND_LINES := {"Bag": &"found_bag", "Message": &"found_message", "Lamp": &"found_lamp"}
const CARGO := ["Jar", "Sack", "Rope"]
const LIGHT_WORDS: PackedStringArray = ["Call", "Hear", "Go"]
## The three lights' colours: warm, then warmer, then Wonder Light's own gold.
const LIGHT_COLOURS := [Color(0.62, 0.84, 1.0), Color(0.98, 0.9, 0.62), Color(1.0, 0.78, 0.36)]
const FIND_PROMPT := "Find Jonah's bag, his message and his lamp"
const CARGO_PROMPT := "Carry each piece of cargo to its space"
## The major beats the chapter can carry on from after the game was closed (Profiles places).
const RESUME_BEATS: PackedStringArray = ["find", "meet", "cargo", "storm", "prayer", "nineveh", "hill", "reflect"]
## Seconds with no progress before the golden arrow points the way.
const HINT_DELAY := 12.0
## The sea's beats move on by themselves this long after their line has been read, so the
## story never stops at sea (docs/chapter-5-concept.md, Band).
const SEA_WAIT := 4.0
## In the deep, the next light lights itself after this long with no tap.
const LIGHT_WAIT := 7.0

var phase: Phase = Phase.IDLE
var _line: Label
var _prompt: Label
var _prompt_raw: String = ""
var _audio: Node
var _camera: Node
var _player: Node3D
var _finds: GiftChecklist
var _cargo_list: GiftChecklist
var _lights: HBoxContainer
var _light_buttons: Array[Button] = []
var _lit: int = 0
var _light_idle: float = 0.0
var _hints: Hints
var _busy: bool = false
var _ceremony: bool = false
var _sea_wait: float = 0.0


func begin() -> void:
	if phase != Phase.IDLE and phase != Phase.DONE:
		return
	var main := _main()
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
	var banner := main.find_child("CompleteBanner", true, false) as CanvasItem
	if banner:
		banner.visible = false
	_build_lists(main.get_node("UI"))
	_build_lights(main.get_node("UI"))
	_busy = false
	_ceremony = false
	_lit = 0
	if _resume(Profiles.place_in(Profiles.active_id, Profiles.CHAPTER_JONAH)):
		return
	phase = Phase.ARRIVE
	_say([&"arrive", &"road"], "Press Space to continue")


## Carries on from the last major beat this child reached (Profiles.mark_place), with the world
## set as it stood then and that beat's line read again. False to start afresh.
func _resume(place: Dictionary) -> bool:
	var beat := str(place.get("beat", ""))
	if not beat in RESUME_BEATS:
		return false
	var world := _world()
	world.set_scene_for(beat)
	match beat:
		"find":
			_start_finding()
		"meet":
			world.go_to("joppa", Callable(), 0.0)
			_meet()
		"cargo":
			world.go_to("sea", func() -> void: world.place_jonah("sea"), 0.0)
			_start_cargo()
		"storm":
			world.go_to("sea", func() -> void: world.place_jonah("sea"), 0.0)
			world.sea().storm = 1.0
			_storm()
		"prayer":
			world.go_to("deep", func() -> void: world.place_jonah("deep"), 0.0)
			_start_prayer()
		"nineveh":
			world.go_to("land", Callable(), 0.0)
			world.jonah().global_position = world.LAND + world.JONAH_SHORE
			world.jonah().visible = true
			_follow()
		"hill", "reflect":
			world.go_to("land", func() -> void: _put_child(world.LAND + world.HILL_CHILD), 0.0)
			world.plant().grown = 1.0
			if beat == "hill":
				phase = Phase.HILL
				world.hill_shot()
				_say([&"cross"], "Press Space to continue")
			else:
				world.plant().withered = 1.0
				phase = Phase.REFLECT
				if _player:
					world.watch_child(_player)
				_say([&"reflect"], "Press Space to continue")
	return true


func _mark(beat: String) -> void:
	Profiles.mark_place(Profiles.CHAPTER_JONAH, beat)


func stand_down() -> void:
	phase = Phase.IDLE
	if _hints:
		_hints.stop()


func _exit_tree() -> void:
	for node in [_lights, _finds, _cargo_list]:
		if is_instance_valid(node):
			if node.get_parent():
				node.get_parent().remove_child(node)
			node.queue_free()


func _world() -> Node:
	return get_parent()


func _main() -> Node:
	return get_parent().get_parent()


func _input(event: InputEvent) -> void:
	if phase == Phase.IDLE or _busy or _ceremony:
		return
	if _pressed(event) and phase in [Phase.ARRIVE, Phase.MEET, Phase.STORM, Phase.ADMIT, Phase.PLEAD, Phase.FISH, Phase.VERSE,
			Phase.THANKS, Phase.SHORE, Phase.WARNING, Phase.LISTENED, Phase.HILL, Phase.WITHER, Phase.QUESTION, Phase.REFLECT, Phase.CHARM]:
		_advance()
		get_viewport().set_input_as_handled()


## Moves on from a beat that waits for the child (Space, Enter, or NEXT on a tablet).
func _advance() -> void:
	_sea_wait = 0.0
	match phase:
		Phase.ARRIVE:
			_start_finding()
		Phase.MEET:
			_board()
		Phase.STORM:
			phase = Phase.ADMIT
			_world().feel("admit")
			_two_shot(_world().jonah(), _world().captain())
			_say([&"admit", &"put_me"], "Press Space to continue")
		Phase.ADMIT:
			phase = Phase.PLEAD
			_world().feel("plead")
			_two_shot(_world().captain(), _world().jonah())
			_say([&"plead"], "Press Space to continue")
		Phase.PLEAD:
			_overboard()
		Phase.FISH:
			_go_to_prayer()
		Phase.VERSE:
			phase = Phase.THANKS
			_world().feel("thanks")
			_world().jonah().kneel = 0.4
			_say([&"thanks"], "Press Space to continue")
		Phase.THANKS:
			_to_shore()
		Phase.SHORE:
			_follow()
		Phase.WARNING:
			phase = Phase.LISTENED
			_world().feel("listened")
			_world().crowd().set_pose("sorry", _world().jonah().global_position)
			_say([&"listened", &"mercy"], "Press Space to continue")
		Phase.LISTENED:
			_to_hill()
		Phase.HILL:
			phase = Phase.WITHER
			_world().feel("wither")
			_world().plant().wither(3.2)
			_say([&"wither"], "Press Space to continue")
		Phase.WITHER:
			phase = Phase.QUESTION
			_world().feel("question")
			_say([&"question"], "Press Space to continue")
		Phase.QUESTION:
			phase = Phase.REFLECT
			_mark("reflect")
			if _player:
				_world().watch_child(_player)
			_say([&"reflect"], "Press Space to continue")
		Phase.REFLECT:
			_award_charm()
		Phase.CHARM:
			_finish()


func _process(delta: float) -> void:
	match phase:
		Phase.FIND:
			_finding()
		Phase.BOARD:
			if _player and _world().at_gangway(_player.global_position) and not _busy:
				_set_sail()
		Phase.CARGO:
			_carrying_cargo()
		Phase.FOLLOW:
			if _player and _world().at_gate(_player.global_position) and not _busy:
				_warning()
		Phase.PRAY:
			_light_idle += delta
			if _light_idle >= LIGHT_WAIT and _lit < LIGHT_WORDS.size():
				press_light(_lit)
	# The sea's beats carry on by themselves once their line has been read.
	if phase in [Phase.STORM, Phase.ADMIT, Phase.PLEAD, Phase.FISH] and not _busy and not _speaking():
		_sea_wait += delta
		if _sea_wait >= SEA_WAIT:
			_advance()


func _speaking() -> bool:
	return _audio != null and _audio.has_method("is_speaking") and _audio.is_speaking()


# ---- Joppa ----------------------------------------------------------------------------------

func _start_finding() -> void:
	phase = Phase.FIND
	_mark("find")
	_world().open_finds()
	_say([&"find"], FIND_PROMPT)
	if _finds:
		_finds.set_found(_world().found_things())
	_watch(_world().find_spots())


func _finding() -> void:
	if _player == null:
		return
	var thing: String = _world().find_near(_player.global_position)
	if thing.is_empty():
		return
	if _audio and _audio.has_method("play_pickup"):
		_audio.play_pickup()
	_celebrate_light()
	var found: Array = _world().found_things()
	if _finds:
		_finds.set_found(found)
	if found.size() < THINGS.size():
		_say([FIND_LINES[thing]], FIND_PROMPT)
		_watch(_world().find_spots())
		return
	if _hints:
		_hints.stop()
	_mark("meet")
	_meet(FIND_LINES[thing])


## Jonah, between the road and the ship, says what he has decided.
func _meet(found_line: StringName = &"") -> void:
	phase = Phase.MEET
	var parts: Array = [] if found_line.is_empty() else [found_line]
	parts.append(&"meet")
	_world().feel("meet")
	if _camera and _camera.has_method("cut_to_closeup"):
		_camera.cut_to_closeup(_world().jonah())
	_say(parts, "Press Space to continue")


## Jonah walks up the gangway; the child follows him to its foot.
func _board() -> void:
	phase = Phase.BOARD
	_say([&"board"], "Walk up to the gangway after Jonah")
	_world().jonah_boards()
	_world().show_gangway_ring(true)
	_watch([_world().gangway_ring()])


# ---- at sea ---------------------------------------------------------------------------------

## The page turns to the ship out at sea: the sky is darkening and the cargo is loose.
func _set_sail() -> void:
	_busy = true
	if _hints:
		_hints.stop()
	_world().show_gangway_ring(false)
	if _audio and _audio.has_method("play_success"):
		_audio.play_success()
	var world := _world()
	var turn: Tween = world.go_to("sea", func() -> void: world.place_jonah("sea"))
	await turn.finished
	if phase != Phase.BOARD:
		return
	_busy = false
	_mark("cargo")
	_start_cargo(true)


func _start_cargo(first_time: bool = false) -> void:
	phase = Phase.CARGO
	_world().open_cargo()
	_world().sea().set_storm(0.35, 8.0)
	_say([&"sail", &"cargo"] if first_time else [&"cargo"], CARGO_PROMPT)
	if _cargo_list:
		_cargo_list.set_found(_world().secured())
	_watch(_world().cargo_spots())


func _carrying_cargo() -> void:
	if _player == null:
		return
	var world := _world()
	var at := _player.global_position
	var near: String = world.cargo_within_reach(at)
	if not near.is_empty() and world.pick_up(near):
		if _audio and _audio.has_method("play_pickup"):
			_audio.play_pickup()
		_set_prompt("Take the %s to its space" % near.to_lower())
		_watch(world.cargo_spots())
		return
	if world.at_carried_spot(at):
		world.place_carried()
		if _audio and _audio.has_method("play_tap"):
			_audio.play_tap()
		_celebrate_light()
		var done: Array = world.secured()
		if _cargo_list:
			_cargo_list.set_found(done)
		if done.size() < CARGO.size():
			_set_prompt(CARGO_PROMPT)
			_watch(world.cargo_spots())
			return
		if _hints:
			_hints.stop()
		_storm()


## The storm at its height (slowly, never a flash): the captain speaks.
func _storm() -> void:
	phase = Phase.STORM
	_mark("storm")
	_world().set_storm(1.0, 5.0)
	_world().feel("storm")
	_two_shot(_world().captain(), _world().jonah())
	_say([&"captain"], "Press Space to continue")


## Jonah goes into the sea behind a great wave, and the storm stops on the same breath.
func _overboard() -> void:
	phase = Phase.OVERBOARD
	_busy = true
	_world().over_side_shot()
	_world().feel("overboard")
	_say([&"calm"], "…")
	var go: Tween = _world().jonah_into_sea()
	await go.finished
	if phase != Phase.OVERBOARD:
		return
	phase = Phase.FISH
	_world().feel("after_storm")
	_world().fish_shot()
	_say([&"fish"], "…")
	var rise: Tween = _world().fish().rise(4.0)
	await rise.finished
	if phase != Phase.FISH:
		return
	_busy = false
	_sea_wait = 0.0
	_set_prompt("Press Space to continue")


# ---- the deep -------------------------------------------------------------------------------

func _go_to_prayer() -> void:
	_busy = true
	var world := _world()
	var turn: Tween = world.go_to("deep", func() -> void: world.place_jonah("deep"))
	await turn.finished
	if phase != Phase.FISH:
		return
	_busy = false
	_mark("prayer")
	_start_prayer()


## Prayer in the Deep: three lights, Call, Hear and Go, one after another. The next one breathes;
## a tapped one sends its light drifting up to Wonder Light. If nobody taps, it lights itself.
func _start_prayer() -> void:
	phase = Phase.PRAY
	_lit = 0
	_light_idle = 0.0
	_world().prayer_shot()
	_world().feel("pray")
	_say([&"pray"], "Tap Call, Hear and Go")
	_show_lights(true)


func press_light(index: int) -> void:
	if phase != Phase.PRAY or index != _lit:
		return
	_lit += 1
	_light_idle = 0.0
	var chip := _light_buttons[index] as WordChip
	chip.set_lit(true)
	chip.pop()
	_world().send_prayer_light(index, LIGHT_COLOURS[index])
	if _audio and _audio.has_method("play_tap"):
		_audio.play_tap()
	if _audio and _audio.has_method("speak_lines"):
		_audio.speak_lines([{"speaker": "Wonder Light", "text": LIGHT_WORDS[index] + "."}] as Array[Dictionary])
	_show_lights(true)
	if _lit < LIGHT_WORDS.size():
		return
	_busy = true
	await get_tree().create_timer(1.4).timeout
	if phase != Phase.PRAY:
		return
	_busy = false
	_show_lights(false)
	phase = Phase.VERSE
	Profiles.unlock_verse(JournalContent.VERSE_JONAH_2_2)
	_celebrate_light()
	_say([JournalContent.verse_card(JournalContent.VERSE_JONAH_2_2)], "Press Space to continue")


# ---- the land -------------------------------------------------------------------------------

func _to_shore() -> void:
	phase = Phase.SHORE
	_busy = true
	var world := _world()
	var turn: Tween = world.go_to("land", func() -> void:
		world.jonah().kneel = 0.0
		world.release_shot())
	await turn.finished
	if phase != Phase.SHORE:
		return
	_say([&"shore"], "…")
	world.feel("shore")
	var out: Tween = world.release()
	await out.finished
	if phase != Phase.SHORE:
		return
	_busy = false
	_set_prompt("Press Space to continue")


## God asks Jonah again, and this time he goes: the child walks with him to the city gate.
func _follow() -> void:
	phase = Phase.FOLLOW
	_mark("nineveh")
	_say([&"again"], "Walk with Jonah to the city gate")
	_world().jonah_to_gate()
	_world().show_gate_ring(true)
	_watch([_world().gate_ring()])


func _warning() -> void:
	phase = Phase.WARNING
	if _hints:
		_hints.stop()
	_world().show_gate_ring(false)
	_world().face(_world().jonah(), _world().LAND + _world().CROWD_AT)
	_world().gate_shot()
	_world().crowd().set_pose("listening", _world().jonah().global_position)
	_world().feel("warning")
	_say([&"warning"], "Press Space to continue")


## Jonah on the hill outside the city, cross; God makes the plant grow over him.
func _to_hill() -> void:
	phase = Phase.HILL
	_busy = true
	var world := _world()
	var turn: Tween = world.go_to("land", func() -> void:
		_put_child(world.LAND + world.HILL_CHILD)
		world.crowd().set_pose("sorry", world.LAND + world.JONAH_GATE, 0.0)
		world.to_hill()
		world.hill_shot())
	await turn.finished
	if phase != Phase.HILL:
		return
	_mark("hill")
	world.feel("cross")
	_say([&"cross"], "Press Space to continue")
	var grow: Tween = world.plant().grow(3.0)
	await grow.finished
	_busy = false


func _put_child(at: Vector3) -> void:
	if _player:
		_player.global_position = at
		if "velocity" in _player:
			_player.velocity = Vector3.ZERO
		_world()._snap_followers(_player)


func _award_charm() -> void:
	phase = Phase.CHARM
	Profiles.unlock_charm(JournalContent.CHARM_MERCY)
	_say([&"charm", &"charm_arrives"], "…")
	var award := _main().get_node_or_null("CharmAward") as Node3D
	if award == null or _player == null or not award.has_method("play_ceremony"):
		_on_charm_sealed()
		return
	_ceremony = true
	if "can_move" in _player:
		_player.can_move = false
	award.global_position = _player.global_position + Vector3(0.35, 1.15, 0.9)
	_world().set_child_watch(award)
	if _camera and _camera.has_method("cut_to_charm"):
		_camera.cut_to_charm(award)
	award.ceremony_finished.connect(_on_charm_sealed, CONNECT_ONE_SHOT)
	award.play_ceremony(JournalContent.CHARM_MERCY)


func _on_charm_sealed() -> void:
	_ceremony = false
	_set_prompt("Press Space to keep your charm")


func _finish() -> void:
	phase = Phase.DONE
	_world().set_child_watch(null)
	var main := _main()
	Profiles.finish_chapter(Profiles.CHAPTER_JONAH)
	_say([&"keep_close"], "Well done, Wonder-Walker!")
	if main.has_method("play_finale"):
		main.play_finale("Chapter 5 Complete!")
	var menu := main.get_node_or_null("GameMenu")
	if menu and menu.has_method("show_end_panel"):
		menu.show_end_panel(JournalContent.CHARM_MERCY)


## What the touch button says now ("" = nothing to do), for touch_controls.gd.
func get_action_hint() -> String:
	if _busy or phase in [Phase.IDLE, Phase.FIND, Phase.BOARD, Phase.CARGO, Phase.OVERBOARD, Phase.PRAY, Phase.FOLLOW, Phase.DONE]:
		return ""
	if phase == Phase.CHARM and _ceremony:
		return ""
	return "NEXT"


## Shows `parts` (the chapter's lines by id, or shared text such as the verse) and reads them
## aloud, with the camera and the child's walking set for the beat.
func _say(parts: Array, prompt: String) -> void:
	var said: Dictionary = LINES.block(parts, GameSettings.easy_words)
	if _player and "can_move" in _player:
		_player.can_move = phase in [Phase.FIND, Phase.BOARD, Phase.CARGO, Phase.FOLLOW, Phase.DONE]
	if _camera and phase in [Phase.ARRIVE, Phase.FIND, Phase.BOARD, Phase.CARGO, Phase.FOLLOW, Phase.REFLECT, Phase.DONE]:
		if _camera.has_method("cut_to_tabletop"):
			_camera.cut_to_tabletop()
	if _finds:
		_finds.visible = phase == Phase.FIND
	if _cargo_list:
		_cargo_list.visible = phase == Phase.CARGO
	if _line:
		_line.text = said["text"]
	_set_prompt(prompt)
	var shell := _main()
	if shell.has_method("fit_dialogue"):
		shell.fit_dialogue()
	# Who the people turn to: the first character in the block, not Wonder Light's narration before
	# them (with read-aloud on, each line turns them again as it is read; with it off, this is all).
	_world().set_speaking(_first_character(said["spoken"]))
	if _audio and _audio.has_method("speak_lines"):
		_audio.speak_lines(said["spoken"])


func _two_shot(a: Node3D, b: Node3D) -> void:
	if _camera and _camera.has_method("cut_to_two_shot"):
		_camera.cut_to_two_shot(a, b)


## The first speaker in `spoken` who is one of the story's people, or Wonder Light when only she
## speaks, or "" for nobody.
static func _first_character(spoken: Array) -> String:
	for line in spoken:
		if String(line["speaker"]) != "Wonder Light":
			return String(line["speaker"])
	return "" if spoken.is_empty() else String(spoken[0]["speaker"])


func _on_line_started(line: Dictionary) -> void:
	if phase != Phase.IDLE:
		_world().set_speaking(String(line.get("speaker", "")))


func _set_prompt(raw: String) -> void:
	_prompt_raw = raw
	if _prompt:
		var input_setup := _main().get_node_or_null("InputSetup")
		_prompt.text = DevicePrompts.reword(raw, input_setup)


func _on_device_changed(_mode: String) -> void:
	if phase == Phase.IDLE:
		return
	_set_prompt(_prompt_raw)


## The golden arrow (wonder_item_hints.gd) points at the nearest of `spots` after a while.
func _watch(spots: Array) -> void:
	var world := _world()
	if _hints == null:
		_hints = Hints.new()
		_hints.name = "JonahHints"
		_hints.main = world.get_parent()
		_hints.hint_delay = HINT_DELAY
		world.add_child(_hints)
	_hints.stop()
	_hints.watch(spots)


func _celebrate_light() -> void:
	var light := _main().get_node_or_null("WonderLight")
	if light and light.has_method("celebrate"):
		light.celebrate()


func _build_lists(ui: Node) -> void:
	for old in [_finds, _cargo_list]:
		if is_instance_valid(old):
			old.queue_free()
	_finds = GiftChecklist.new(THINGS, "Jonah's things")
	_finds.name = "JonahThingsList"
	_finds.position = Vector2(24, 90)
	_finds.visible = false
	ui.add_child(_finds)
	_cargo_list = GiftChecklist.new(CARGO, "Secure the cargo")
	_cargo_list.name = "CargoList"
	_cargo_list.position = Vector2(24, 90)
	_cargo_list.visible = false
	ui.add_child(_cargo_list)


func _build_lights(ui: Node) -> void:
	if is_instance_valid(_lights):
		_lights.queue_free()
	_light_buttons.clear()
	_lights = HBoxContainer.new()
	_lights.name = "PrayerLights"
	_lights.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_lights.offset_left = -380.0
	_lights.offset_right = 380.0
	_lights.offset_top = -250.0
	_lights.offset_bottom = -150.0
	_lights.alignment = BoxContainer.ALIGNMENT_CENTER
	_lights.add_theme_constant_override("separation", 36)
	_lights.visible = false
	ui.add_child(_lights)
	for i in LIGHT_WORDS.size():
		var chip := WordChip.new(LIGHT_WORDS[i], Vector2(200, 86), 32)
		chip.pressed.connect(press_light.bind(i))
		_lights.add_child(chip)
		_light_buttons.append(chip)


## Only the next light breathes and can be tapped; the ones lit keep their glow.
func _show_lights(on: bool) -> void:
	if _lights:
		_lights.visible = on
	for i in _light_buttons.size():
		var chip := _light_buttons[i] as WordChip
		chip.set_beckon(on and i == _lit)
		chip.disabled = i != _lit and i >= _lit


func _pressed(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_accept"):
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		return k == KEY_SPACE or k == KEY_ENTER
	return false
