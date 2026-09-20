extends Node
## Adds gamepad bindings and a `pause` action at runtime, and tracks which kind
## of device the player last used ("keyboard", "touch" or "gamepad") so prompts
## and on-screen controls can match it.

signal device_changed(mode: String)

var mode: String = "keyboard"


func _ready() -> void:
	_bind_actions()
	if DisplayServer.is_touchscreen_available():
		mode = "touch"


func set_mode(new_mode: String) -> void:
	if new_mode != mode:
		mode = new_mode
		device_changed.emit(mode)


func _input(event: InputEvent) -> void:
	# Mouse events are ignored on purpose: touch screens also emit emulated mouse events.
	if event is InputEventKey and event.pressed:
		set_mode("keyboard")
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		set_mode("touch")
	elif event is InputEventJoypadButton and event.pressed:
		set_mode("gamepad")
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.5:
		set_mode("gamepad")


func _bind_actions() -> void:
	_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_axis("move_forward", JOY_AXIS_LEFT_Y, -1.0)
	_axis("move_back", JOY_AXIS_LEFT_Y, 1.0)
	_button("move_left", JOY_BUTTON_DPAD_LEFT)
	_button("move_right", JOY_BUTTON_DPAD_RIGHT)
	_button("move_forward", JOY_BUTTON_DPAD_UP)
	_button("move_back", JOY_BUTTON_DPAD_DOWN)
	_button("ui_accept", JOY_BUTTON_A)
	_button("interact", JOY_BUTTON_A)
	_button("interact", JOY_BUTTON_X)
	_key("pause", KEY_ESCAPE)
	_key("pause", KEY_P)
	_button("pause", JOY_BUTTON_START)


func _ensure(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)


func _add(action: StringName, event: InputEvent) -> void:
	_ensure(action)
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)


func _axis(action: StringName, axis: JoyAxis, value: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	_add(action, e)


func _button(action: StringName, button: JoyButton) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	_add(action, e)


func _key(action: StringName, keycode: Key) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = keycode
	_add(action, e)
