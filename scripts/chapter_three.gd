extends Node
## Chapter 3, The Beginning: Samuel comes to Jesse's home in Bethlehem and anoints David,
## the youngest, who is out with the sheep (1 Samuel 16:1-13). It is a look back, played
## after The King's Camp: "God sees the heart", with the Faithful Heart charm.
## Lives on the courtyard (jesses_house.gd); its lines are in assets/dialogue/jesses_house.tres,
## read by the system voice until the chapter is cast (docs/chapter-3-readiness.md).
##
## So far the story turns back the page and lets the child look round the courtyard. The
## welcome, the brothers, David's return, the verse, the anointing and the charm follow.

const Profiles := preload("res://scripts/profiles.gd")
const GameSettings := preload("res://scripts/game_settings.gd")
const DevicePrompts := preload("res://scripts/device_prompts.gd")
## The chapter's lines (dialogue_lines.gd).
const LINES := preload("res://assets/dialogue/jesses_house.tres")

enum Phase { IDLE, ARRIVE, EXPLORE, DONE }

var phase: Phase = Phase.IDLE
var _line: Label
var _prompt: Label
var _prompt_raw: String = ""
var _audio: Node
var _camera: Node
var _player: Node3D


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
	# Coming from another chapter's end card, its "Chapter Complete!" banner must not hang over this one.
	var banner := main.find_child("CompleteBanner", true, false) as CanvasItem
	if banner:
		banner.visible = false
	phase = Phase.ARRIVE
	_say([&"turn_back"], "Press Space to continue")


## Another story is starting: this one stops listening.
func stand_down() -> void:
	phase = Phase.IDLE


func _input(event: InputEvent) -> void:
	if phase != Phase.ARRIVE or not _pressed(event):
		return
	_advance()
	get_viewport().set_input_as_handled()


func _advance() -> void:
	match phase:
		Phase.ARRIVE:
			phase = Phase.EXPLORE
			_say([&"look_around"], "Walk around Jesse's home")


## What the touch button says now ("" = nothing to do), for touch_controls.gd.
func get_action_hint() -> String:
	return "NEXT" if phase == Phase.ARRIVE else ""


## Shows `parts` (the chapter's lines by id, or shared text such as a verse) and reads them aloud.
func _say(parts: Array, prompt: String) -> void:
	var said: Dictionary = LINES.block(parts, GameSettings.easy_words)
	if _player and "can_move" in _player:
		_player.can_move = phase in [Phase.EXPLORE, Phase.DONE]
	if _camera and _camera.has_method("cut_to_tabletop"):
		_camera.cut_to_tabletop()
	if _line:
		_line.text = said["text"]
	_set_prompt(prompt)
	var shell := get_parent().get_parent()
	if shell.has_method("fit_dialogue"):
		shell.fit_dialogue()
	if _audio and _audio.has_method("speak_lines"):
		_audio.speak_lines(said["spoken"])


## Prompts are written for the keyboard and worded for the device used last (device_prompts.gd).
func _set_prompt(raw: String) -> void:
	_prompt_raw = raw
	if _prompt:
		var input_setup := get_parent().get_parent().get_node_or_null("InputSetup")
		_prompt.text = DevicePrompts.reword(raw, input_setup)


func _on_device_changed(_mode: String) -> void:
	if phase == Phase.IDLE:
		return
	_set_prompt(_prompt_raw)


func _pressed(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_accept"):
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		return k == KEY_SPACE or k == KEY_ENTER
	return false
