extends Control
## A visible, fail-free hold-and-release activity, shared by keyboard and touch.
signal completed

const PaperUI := preload("res://scripts/paper_ui.gd")
var loops: int = 0
var progress: float = 0.0
var ready_to_release: bool = false
var _armed: bool = false
var _button: Button
var _caption: Label
var _finished: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(600, 310)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption = PaperUI.label("", 26)
	_caption.position = Vector2(0, 18)
	_caption.size = Vector2(600, 38)
	add_child(_caption)
	_button = PaperUI.button("Hold to loop", Vector2(310, 60), 24)
	_button.position = Vector2(145, 228)
	_button.focus_mode = Control.FOCUS_NONE
	add_child(_button)
	_update_text()

func _process(delta: float) -> void:
	if not visible or _finished:
		return
	step(delta, Input.is_action_pressed("ui_accept") or _button.button_pressed)

func step(delta: float, holding: bool) -> void:
	if _finished:
		return
	# The key that opened the activity must be released first.
	if not _armed:
		_armed = not holding
		return
	if holding and not ready_to_release:
		progress = minf(progress + delta / 1.6, 1.0)
		ready_to_release = progress >= 1.0
	elif not holding and ready_to_release:
		loops += 1
		progress = 0.0
		ready_to_release = false
		if loops == 3:
			_finished = true
			completed.emit()
	# Releasing early keeps progress: there is no failure or lost work.
	_update_text()
	queue_redraw()

func _update_text() -> void:
	_caption.text = "Friendship cord  •  %d / 3 loops" % loops
	_button.text = "Release to tie" if ready_to_release else "Hold to loop"
	if _finished:
		_button.text = "Tied together!"
		_button.disabled = true

func _draw() -> void:
	draw_style_box(PaperUI.panel_style(), Rect2(Vector2.ZERO, Vector2(600, 310)))
	var gold := Color(0.72, 0.43, 0.13)
	draw_line(Vector2(64, 154), Vector2(536, 154), Color(0.77, 0.66, 0.48), 7, true)
	for i in 3:
		var center := Vector2(180 + i * 120, 139)
		draw_arc(center, 48, 0, TAU, 64, Color(0.86, 0.79, 0.64), 8, true)
		var amount := 1.0 if i < loops else (progress if i == loops else 0.0)
		if amount > 0.0:
			draw_arc(center, 48, PI * 0.5, PI * 0.5 + TAU * amount, 64, gold, 9, true)
		if i < loops:
			draw_circle(center + Vector2(0, 45), 10, PaperUI.INK)
