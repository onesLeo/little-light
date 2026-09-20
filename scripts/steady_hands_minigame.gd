extends Node
## Steady Hands breathing mini-game — David & Goliath chapter.
## No fail state: always succeeds after taps_required gentle Space taps.
## No aiming, no target, no violence. Band A: 1 tap auto-succeed (locked design). Band B can raise taps_required later.
##
## Visual feedback: a soft circle (see main.tscn UI/BreathIndicator) breathes
## in and out on its own while waiting, pulses on each tap, and blooms +
## fades on success — so the "breathe in... and out" line has something
## for a 6-12 year old to actually watch, not just a console print.

signal minigame_completed

@export var taps_required: int = 1
@export var breath_cycle_seconds: float = 1.6

var taps_done: int = 0
var active: bool = false

@onready var _breath: Control = get_node_or_null("%BreathIndicator") as Control
@onready var _audio: Node = get_node_or_null("%AudioDirector")
var _tween: Tween
var _breath_label: Label

func _ready() -> void:
	taps_done = 0
	active = false
	set_process_unhandled_input(false)
	if _breath:
		_breath.visible = false
		_breath.modulate.a = 1.0
		_breath.scale = Vector2(0.7, 0.7)
		# "In..." / "Out..." so a child who cannot read the story still knows what to do.
		_breath_label = Label.new()
		_breath_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_breath_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_breath_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_breath_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_breath_label.add_theme_font_size_override("font_size", 30)
		_breath_label.add_theme_color_override("font_color", Color(0.35, 0.2, 0.08))
		_breath.add_child(_breath_label)

func start_minigame() -> void:
	taps_done = 0
	active = true
	set_process_unhandled_input(true)
	_start_ambient_breath()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	# ui_accept = Space / Enter / gamepad A. Also accept raw Space if InputMap misses.
	var space := event.is_action_pressed("ui_accept")
	if not space and event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		var pk: int = event.physical_keycode
		space = k == KEY_SPACE or pk == KEY_SPACE or k == KEY_ENTER or pk == KEY_ENTER
	if space:
		_on_tap()
		get_viewport().set_input_as_handled()

func _on_tap() -> void:
	if not active:
		return
	taps_done += 1
	if _audio and _audio.has_method("play_tap"):
		_audio.play_tap()
	_pulse_breath()
	if taps_done >= taps_required:
		active = false
		set_process_unhandled_input(false)
		_finish_breath()

## Slow, continuous scale breathing while we wait for the next tap.
func _start_ambient_breath() -> void:
	if _breath == null:
		return
	_breath.visible = true
	_breath.modulate.a = 1.0
	_kill_tween()
	_tween = create_tween().set_loops()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(_set_breath_text.bind("In..."))
	_tween.tween_property(_breath, "scale", Vector2.ONE * 1.15, breath_cycle_seconds * 0.5)
	_tween.tween_callback(_set_breath_text.bind("Out..."))
	_tween.tween_property(_breath, "scale", Vector2.ONE * 0.7, breath_cycle_seconds * 0.5)

## A quick, satisfying bump on every tap, then back to ambient breathing.
func _pulse_breath() -> void:
	if _breath == null:
		return
	_kill_tween()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_breath, "scale", Vector2.ONE * 1.35, 0.15)
	_tween.tween_property(_breath, "scale", Vector2.ONE * 0.95, 0.25)
	_tween.finished.connect(func():
		if active:
			_start_ambient_breath()
	)

## Success: one warm bloom-out, then hide and tell the director we're done.
func _finish_breath() -> void:
	if _audio and _audio.has_method("play_success"):
		_audio.play_success()
	if _breath == null:
		minigame_completed.emit()
		return
	_kill_tween()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_breath, "scale", Vector2.ONE * 1.5, 0.35)
	_tween.parallel().tween_property(_breath, "modulate:a", 0.0, 0.55)
	_tween.tween_callback(func():
		_breath.visible = false
		_set_breath_text("")
		minigame_completed.emit()
	)

func _set_breath_text(text: String) -> void:
	if _breath_label:
		_breath_label.text = text

func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
