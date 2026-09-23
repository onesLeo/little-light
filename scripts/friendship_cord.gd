extends Control
## A visible, fail-free hold-and-release activity, shared by keyboard and touch.
signal completed

const PaperUI := preload("res://scripts/paper_ui.gd")
## One loop takes about as long as one Steady Hands breath, so it cannot be rushed.
const HOLD_SECONDS := 4.0
const PANEL := Vector2(560, 176)
var loops: int = 0
var progress: float = 0.0
var ready_to_release: bool = false
var _armed: bool = false
var _button: Button
var _caption: Label
var _finished: bool = false

func _ready() -> void:
	custom_minimum_size = PANEL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption = PaperUI.label("", 24)
	_caption.position = Vector2(0, 8)
	_caption.size = Vector2(PANEL.x, 32)
	add_child(_caption)
	_button = PaperUI.button("Hold to loop", Vector2(280, 48), 22)
	_button.position = Vector2(140, 114)
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
		progress = minf(progress + delta / HOLD_SECONDS, 1.0)
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
	draw_style_box(PaperUI.panel_style(12, 18), Rect2(Vector2.ZERO, PANEL))
	var gold := Color(0.72, 0.43, 0.13)
	draw_line(Vector2(36, 78), Vector2(PANEL.x - 36, 78), Color(0.77, 0.66, 0.48), 6, true)
	for i in 3:
		var center := Vector2(110 + i * 170, 72)
		draw_arc(center, 28, 0, TAU, 48, Color(0.86, 0.79, 0.64), 6, true)
		var amount := 1.0 if i < loops else (progress if i == loops else 0.0)
		if amount > 0.0:
			draw_arc(center, 28, PI * 0.5, PI * 0.5 + TAU * amount, 48, gold, 7, true)
		if i < loops:
			draw_circle(center + Vector2(0, 34), 7, PaperUI.INK)
