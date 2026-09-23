extends CanvasLayer
## On-screen controls for touch play (tablets and phones): a floating thumb
## stick anywhere on the left side of the screen, and one big action button on
## the right. The button's label follows the story (NEXT / GRAB / BREATHE) and
## it sends both `ui_accept` and `interact`, which the game already handles, so
## a child never has to pick the right button. The actions stay pressed for as
## long as the finger is down, which is what lets BREATHE be "hold to breathe in".
## Shown only while the player is using touch (see input_setup.gd).

@export var stick_radius: float = 90.0
@export var button_radius: float = 68.0
## Where the button and the stick's resting ring sit on the 1280 x 720 screen the game is designed at. On a
## wider or taller screen the button keeps its distance from the right and bottom edges and the ring from the
## left and bottom edges (see button_position() and stick_position()).
@export var button_center: Vector2 = Vector2(1130.0, 410.0)
@export var stick_home: Vector2 = Vector2(170.0, 420.0)

const GOLD := Color(0.98, 0.78, 0.25)
const INK := Color(0.35, 0.2, 0.08)
const MOVE_ACTIONS := {"left": "move_left", "right": "move_right", "up": "move_forward", "down": "move_back"}

## Touch index driving the stick / button, -1 when idle.
var _stick_id: int = -1
var _button_id: int = -1
var _stick_center: Vector2 = Vector2.ZERO
var _stick_pos: Vector2 = Vector2.ZERO
var _time: float = 0.0
var _canvas: Control
var _input_setup: Node
var _director: Node


class TouchCanvas extends Control:
	var owner_ref: Node

	func _draw() -> void:
		if owner_ref:
			owner_ref._paint(self)


func _ready() -> void:
	layer = 2
	_canvas = TouchCanvas.new()
	_canvas.owner_ref = self
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	var main := get_parent()
	_input_setup = main.get_node_or_null("InputSetup")
	_director = main.get_node_or_null("ChapterDirector")
	if _input_setup:
		_input_setup.device_changed.connect(_on_device_changed)
		_apply_mode(_input_setup.mode)
	else:
		_apply_mode("keyboard")


func _on_device_changed(mode: String) -> void:
	_apply_mode(mode)


func _apply_mode(mode: String) -> void:
	visible = mode == "touch"
	if not visible:
		_release_stick()
		if _button_id != -1:
			_set_button(false)
		_button_id = -1


func _process(delta: float) -> void:
	_time += delta
	if visible:
		_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var p: Vector2 = event.position
		if event.pressed:
			if _button_id == -1 and p.distance_to(button_position()) <= button_radius * 1.35:
				_button_id = event.index
				_set_button(true)
			elif _stick_id == -1 and p.x < _view_size().x * 0.55:
				_stick_id = event.index
				_stick_center = p
				_stick_pos = p
				_update_stick()
		elif event.index == _stick_id:
			_release_stick()
		elif event.index == _button_id:
			_set_button(false)
			_button_id = -1
	elif event is InputEventScreenDrag and event.index == _stick_id:
		_stick_pos = event.position
		_update_stick()


func _view_size() -> Vector2:
	return get_viewport().get_visible_rect().size


## How much bigger the screen is than the design size (zero on a 16:9 screen).
func _extra_size() -> Vector2:
	var design := Vector2(float(ProjectSettings.get_setting("display/window/size/viewport_width", 1280)), float(ProjectSettings.get_setting("display/window/size/viewport_height", 720)))
	return (_view_size() - design).max(Vector2.ZERO)


## The action button's centre: the same distance from the right and bottom edges on any screen shape.
func button_position() -> Vector2:
	return button_center + _extra_size()


## The thumb stick's resting ring: the same distance from the left and bottom edges.
func stick_position() -> Vector2:
	return stick_home + Vector2(0.0, _extra_size().y)


func _update_stick() -> void:
	var d := _stick_pos - _stick_center
	if d.length() > stick_radius:
		# Floating stick: the base follows the thumb so it never runs out of travel.
		_stick_center = _stick_pos - d.normalized() * stick_radius
		d = _stick_pos - _stick_center
	var v := d / stick_radius
	_press(MOVE_ACTIONS["left"], maxf(-v.x, 0.0))
	_press(MOVE_ACTIONS["right"], maxf(v.x, 0.0))
	_press(MOVE_ACTIONS["up"], maxf(-v.y, 0.0))
	_press(MOVE_ACTIONS["down"], maxf(v.y, 0.0))


func _press(action: String, strength: float) -> void:
	if strength > 0.05:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _release_stick() -> void:
	_stick_id = -1
	for action in MOVE_ACTIONS.values():
		Input.action_release(action)


## Presses (or lets go of) both actions the button stands for.
func _set_button(down: bool) -> void:
	for action in ["ui_accept", "interact"]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = down
		Input.parse_input_event(ev)


func _hint() -> String:
	var camp_story := get_parent().get_node_or_null("KingsCamp/ChapterTwo")
	if camp_story and camp_story.phase != camp_story.Phase.IDLE:
		return camp_story.get_action_hint()
	if _director and _director.has_method("get_action_hint"):
		return _director.get_action_hint()
	return ""


func _paint(c: Control) -> void:
	# Stick: a faint ghost at home while idle, the real base + knob while held.
	if _stick_id == -1:
		c.draw_arc(stick_position(), stick_radius, 0.0, TAU, 40, Color(INK, 0.25), 3.0)
		c.draw_circle(stick_position(), 34.0, Color(GOLD, 0.22))
	else:
		c.draw_circle(_stick_center, stick_radius, Color(GOLD, 0.16))
		c.draw_arc(_stick_center, stick_radius, 0.0, TAU, 40, Color(INK, 0.5), 3.0)
		var knob := _stick_center + (_stick_pos - _stick_center).limit_length(stick_radius)
		c.draw_circle(knob, 38.0, Color(GOLD, 0.85))
		c.draw_arc(knob, 38.0, 0.0, TAU, 32, INK, 3.0)

	# Action button: bright and gently pulsing when there is something to do.
	var hint := _hint()
	var active := hint != ""
	var pulse := 1.0 + (0.06 * sin(_time * 5.0) if active else 0.0)
	var pressed := _button_id != -1
	var r := button_radius * pulse * (0.92 if pressed else 1.0)
	var alpha := 0.92 if active else 0.3
	c.draw_circle(button_position(), r, Color(GOLD, alpha))
	c.draw_arc(button_position(), r, 0.0, TAU, 48, Color(INK, alpha), 4.0)
	if active:
		var font := ThemeDB.fallback_font
		var text_size := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
		c.draw_string(font, button_position() + Vector2(-text_size.x * 0.5, 9.0), hint,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 24, INK)
