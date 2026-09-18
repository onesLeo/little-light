extends Node
## Steady Hands breathing mini-game — David & Goliath chapter.
## No fail state: always succeeds after taps_required gentle Space taps.
## No aiming, no target, no violence. Band A: 1 tap auto-succeed (locked design). Band B can raise taps_required later.

signal minigame_completed

@export var taps_required: int = 1
var taps_done: int = 0
var active: bool = false

func _ready() -> void:
	taps_done = 0
	active = false
	set_process_unhandled_input(false)

func start_minigame() -> void:
	taps_done = 0
	active = true
	set_process_unhandled_input(true)
	print("Steady Hands: breathe in... and out. Press Space.")

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
	print("Breathe... (%d / %d)" % [taps_done, taps_required])
	if taps_done >= taps_required:
		print("Steady now. Well done.")
		active = false
		set_process_unhandled_input(false)
		minigame_completed.emit()
