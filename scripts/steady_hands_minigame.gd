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

func _ready() -> void:
	taps_done = 0
	active = false
	set_process_unhandled_input(false)
	if _breath:
		_breath.visible = false
		_breath.modulate.a = 1.0
		_breath.scale = Vector2(0.7, 0.7)

func start_minigame() -> void:
	taps_done = 0
	active = true
	set_process_unhandled_input(true)
	_start_ambient_breath()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	# ui_accept = Space / gamepad A. Mobile would call _on_tap() from a button.
	if event.is_action_pressed("ui_accept"):
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
	_tween.tween_property(_breath, "scale", Vector2.ONE * 1.15, breath_cycle_seconds * 0.5)
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
		minigame_completed.emit()
	)

func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
