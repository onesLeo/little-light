extends CanvasLayer
## Pause menu, read-aloud toggle and the end-of-chapter "Play again" panel.
##
## - Pause: Esc / P / gamepad Start, or the round button top-right. Offers
##   Resume, read-aloud on/off, volume and "Play again from the start".
## - Read-aloud button (speaker icon): turns text-to-speech on or off.
## - After the chapter finishes, a "Play again" / "Keep exploring" panel
##   appears once the confetti has had a moment.
## Built entirely in code so it needs no scene edits beyond adding this node.

const GameSettings := preload("res://scripts/game_settings.gd")

const PAPER := Color(0.98, 0.94, 0.83)
const INK := Color(0.35, 0.2, 0.08)
const GOLD := Color(0.98, 0.78, 0.25)

@export var end_panel_delay: float = 2.6

var _audio: Node
var _director: Node
var _root: Control
var _pause_layer: Control
var _pause_button: IconButton
var _speaker_button: IconButton
var _end_panel: PanelContainer
var _play_again_button: Button
var _resume_button: Button
var _read_check: CheckButton
var _volume: HSlider


class IconButton extends Control:
	signal pressed
	var kind: String = "pause"
	var on: bool = true

	func _init(icon_kind: String) -> void:
		kind = icon_kind
		custom_minimum_size = Vector2(64.0, 64.0)
		mouse_filter = Control.MOUSE_FILTER_STOP
		focus_mode = Control.FOCUS_NONE

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()
			accept_event()

	func _draw() -> void:
		var c := size * 0.5
		draw_circle(c, 30.0, Color(0.98, 0.94, 0.83, 0.94))
		draw_arc(c, 30.0, 0.0, TAU, 40, Color(0.35, 0.2, 0.08), 3.0)
		var ink := Color(0.35, 0.2, 0.08)
		if kind == "pause":
			draw_rect(Rect2(c + Vector2(-11.0, -12.0), Vector2(7.0, 24.0)), ink)
			draw_rect(Rect2(c + Vector2(4.0, -12.0), Vector2(7.0, 24.0)), ink)
		else:
			# Speaker body, then sound waves (or a slash when off).
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-16.0, -6.0), c + Vector2(-8.0, -6.0), c + Vector2(2.0, -14.0),
				c + Vector2(2.0, 14.0), c + Vector2(-8.0, 6.0), c + Vector2(-16.0, 6.0)]), ink)
			if on:
				draw_arc(c + Vector2(2.0, 0.0), 9.0, -0.9, 0.9, 12, ink, 3.0)
				draw_arc(c + Vector2(2.0, 0.0), 16.0, -0.9, 0.9, 12, ink, 3.0)
			else:
				draw_line(c + Vector2(-16.0, -16.0), c + Vector2(16.0, 16.0), Color(0.75, 0.2, 0.15), 4.0)


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameSettings.load_settings()
	var main := get_parent()
	_audio = main.get_node_or_null("%AudioDirector")
	_director = main.get_node_or_null("ChapterDirector")

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_corner_buttons()
	_build_pause_panel()
	_build_end_panel()

	if _director and _director.has_signal("chapter_finished"):
		_director.chapter_finished.connect(_on_chapter_finished)
	if _audio and _audio.has_signal("read_aloud_changed"):
		_audio.read_aloud_changed.connect(func(_on: bool) -> void: _refresh_speaker())
	_refresh_speaker()


func _input(event: InputEvent) -> void:
	if InputMap.has_action("pause") and event.is_action_pressed("pause") and not event.is_echo():
		set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func set_paused(paused: bool) -> void:
	get_tree().paused = paused
	_pause_layer.visible = paused
	if paused:
		if _audio and _audio.has_method("stop_speech"):
			_audio.stop_speech()
		_sync_pause_controls()
		_resume_button.grab_focus()
	else:
		get_viewport().gui_release_focus()


func _restart() -> void:
	get_tree().paused = false
	if _audio and _audio.has_method("stop_speech"):
		_audio.stop_speech()
	for action in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)
	get_tree().reload_current_scene()


func _on_chapter_finished() -> void:
	await get_tree().create_timer(end_panel_delay).timeout
	_end_panel.visible = true
	_play_again_button.grab_focus()


## -- UI construction ---------------------------------------------------------

func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER
	sb.border_color = INK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(24)
	sb.set_content_margin_all(22)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 10
	return sb


func _make_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320.0, 62.0)
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_focus_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	var normal := StyleBoxFlat.new()
	normal.bg_color = GOLD
	normal.border_color = INK
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(18)
	b.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = GOLD.lightened(0.18)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", hover)
	var press := normal.duplicate() as StyleBoxFlat
	press.bg_color = GOLD.darkened(0.12)
	b.add_theme_stylebox_override("pressed", press)
	return b


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", INK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _build_corner_buttons() -> void:
	var box := HBoxContainer.new()
	box.anchor_left = 1.0
	box.anchor_right = 1.0
	box.offset_left = -160.0
	box.offset_right = -16.0
	box.offset_top = 16.0
	box.offset_bottom = 80.0
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	box.add_theme_constant_override("separation", 12)
	_root.add_child(box)
	_speaker_button = IconButton.new("speaker")
	_speaker_button.pressed.connect(_on_speaker_pressed)
	box.add_child(_speaker_button)
	_pause_button = IconButton.new("pause")
	_pause_button.pressed.connect(func() -> void: set_paused(true))
	box.add_child(_pause_button)


func _build_pause_panel() -> void:
	_pause_layer = Control.new()
	_pause_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_layer.visible = false
	_root.add_child(_pause_layer)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.1, 0.06, 0.02, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	vbox.add_child(_label("Paused", 40))

	_resume_button = _make_button("Resume")
	_resume_button.pressed.connect(func() -> void: set_paused(false))
	vbox.add_child(_resume_button)

	_read_check = CheckButton.new()
	_read_check.text = "Read the story aloud"
	_read_check.add_theme_font_size_override("font_size", 24)
	_read_check.add_theme_color_override("font_color", INK)
	_read_check.add_theme_color_override("font_hover_color", INK)
	_read_check.add_theme_color_override("font_focus_color", INK)
	_read_check.add_theme_color_override("font_pressed_color", INK)
	_read_check.toggled.connect(_on_read_check_toggled)
	vbox.add_child(_read_check)

	var vol_row := HBoxContainer.new()
	vol_row.add_theme_constant_override("separation", 14)
	vol_row.add_child(_label("Volume", 24))
	_volume = HSlider.new()
	_volume.min_value = 0.0
	_volume.max_value = 1.0
	_volume.step = 0.05
	_volume.custom_minimum_size = Vector2(220.0, 32.0)
	_volume.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_volume.value_changed.connect(_on_volume_changed)
	vol_row.add_child(_volume)
	vbox.add_child(vol_row)

	var restart := _make_button("Play again from the start")
	restart.pressed.connect(_restart)
	vbox.add_child(restart)


func _build_end_panel() -> void:
	_end_panel = PanelContainer.new()
	_end_panel.add_theme_stylebox_override("panel", _panel_style())
	_end_panel.anchor_left = 0.5
	_end_panel.anchor_right = 0.5
	_end_panel.anchor_top = 1.0
	_end_panel.anchor_bottom = 1.0
	_end_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_end_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_end_panel.offset_top = -290.0
	_end_panel.offset_bottom = -290.0
	_end_panel.visible = false
	_root.add_child(_end_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	_end_panel.add_child(row)
	_play_again_button = _make_button("Play again")
	_play_again_button.custom_minimum_size = Vector2(240.0, 62.0)
	_play_again_button.pressed.connect(_restart)
	row.add_child(_play_again_button)
	var keep := _make_button("Keep exploring")
	keep.custom_minimum_size = Vector2(280.0, 62.0)
	keep.pressed.connect(func() -> void:
		_end_panel.visible = false
		get_viewport().gui_release_focus())
	row.add_child(keep)


## -- Settings sync -----------------------------------------------------------

func _sync_pause_controls() -> void:
	_read_check.visible = _audio != null and _audio.has_method("is_read_aloud_available") and _audio.is_read_aloud_available()
	_read_check.set_pressed_no_signal(GameSettings.read_aloud)
	_volume.set_value_no_signal(GameSettings.master_volume)


func _refresh_speaker() -> void:
	var available: bool = _audio != null and _audio.has_method("is_read_aloud_available") and _audio.is_read_aloud_available()
	_speaker_button.visible = available
	_speaker_button.on = available and GameSettings.read_aloud
	_speaker_button.queue_redraw()


func _on_speaker_pressed() -> void:
	if _audio and _audio.has_method("set_read_aloud"):
		_audio.set_read_aloud(not GameSettings.read_aloud)
	_refresh_speaker()


func _on_read_check_toggled(pressed: bool) -> void:
	if _audio and _audio.has_method("set_read_aloud"):
		_audio.set_read_aloud(pressed)
	_refresh_speaker()


func _on_volume_changed(value: float) -> void:
	GameSettings.master_volume = value
	GameSettings.apply_volume()
	GameSettings.save_settings()
