extends CanvasLayer
## Pause menu, read-aloud toggle, Faith Journal button and the end-of-chapter "Play again" panel.
##
## - Pause: Esc / P / gamepad Start, or the round button top-right. Offers
##   Resume, the Faith Journal, read-aloud on/off, volume, "Play again from the start"
##   and "Change player".
## - Book button (top-right): opens the Faith Journal (journal_screen.gd).
## - The end panel also offers "Colour my charm" (colour_screen.gd) and, once a
##   chapter is finished, "Faith Journey" (faith_journey_screen.gd).
## - Read-aloud button (speaker icon): turns text-to-speech on or off.
## - After the chapter finishes, a "Play again" / "Keep exploring" panel
##   appears once the confetti has had a moment.
## Built entirely in code so it needs no scene edits beyond adding this node.

const GameSettings := preload("res://scripts/game_settings.gd")
const SoundBus := preload("res://scripts/sound_bus.gd")
const Profiles := preload("res://scripts/profiles.gd")
const PaperUI := preload("res://scripts/paper_ui.gd")
const JournalContent := preload("res://scripts/journal_content.gd")

const PAPER := PaperUI.PAPER
const INK := PaperUI.INK
const GOLD := PaperUI.GOLD

@export var end_panel_delay: float = 2.6

var _audio: Node
var _director: Node
var _journal: CanvasLayer
var _colour: CanvasLayer
var _journey: CanvasLayer
var _root: Control
var _pause_layer: Control
var _pause_button: IconButton
var _speaker_button: IconButton
var _book_button: IconButton
var _end_panel: PanelContainer
var _play_again_button: Button
var _colour_charm_button: Button
var _journey_button: Button
var _resume_button: Button
var _read_check: CheckButton
var _easy_check: CheckButton
var _volume: HSlider
var _music_slider: HSlider
var _sounds_slider: HSlider
var _voice_slider: HSlider


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
		elif kind == "book":
			# An open book: two pages meeting at the spine.
			for side in [-1.0, 1.0]:
				draw_colored_polygon(PackedVector2Array([
					c + Vector2(side * 2.0, -13.0), c + Vector2(side * 18.0, -10.0),
					c + Vector2(side * 18.0, 13.0), c + Vector2(side * 2.0, 16.0)]), Color(0.99, 0.96, 0.87))
				draw_polyline(PackedVector2Array([
					c + Vector2(side * 2.0, -13.0), c + Vector2(side * 18.0, -10.0),
					c + Vector2(side * 18.0, 13.0), c + Vector2(side * 2.0, 16.0), c + Vector2(side * 2.0, -13.0)]), ink, 2.5)
				for line in 3:
					var y := -4.0 + line * 6.0
					draw_line(c + Vector2(side * 6.0, y), c + Vector2(side * 14.0, y + 1.0), ink, 1.5)
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
	_journal = main.get_node_or_null("JournalScreen")
	_colour = main.get_node_or_null("ColourScreen")
	_journey = main.get_node_or_null("FaithJourney")

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
	if _journal and _journal.has_signal("player_removed"):
		_journal.player_removed.connect(_restart)
	var picker := main.get_node_or_null("ProfileScreen")
	if picker and picker.has_signal("profile_chosen"):
		picker.profile_chosen.connect(func(_id: String) -> void: _refresh_speaker())
	_refresh_speaker()


func _input(event: InputEvent) -> void:
	if InputMap.has_action("pause") and event.is_action_pressed("pause") and not event.is_echo():
		# The "Who is playing?" screen, the journal and the colouring page handle their own way out.
		if Profiles.picker_open or (_journal != null and _journal.is_open()) or (_colour != null and _colour.is_open()):
			return
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


func _open_colouring() -> void:
	if _colour and _colour.has_method("open"):
		_colour.open(JournalContent.CHARM_COURAGE)


func _open_journal() -> void:
	if _journal and _journal.has_method("open"):
		_journal.open()


func _open_journey() -> void:
	if _journey and _journey.has_method("open"):
		_journey.open()


## Forgets who is playing and starts over, which brings back the "Who is playing?" screen.
func change_player_and_restart() -> void:
	Profiles.set_active("")
	_restart()


func _on_chapter_finished() -> void:
	await get_tree().create_timer(end_panel_delay).timeout
	_colour_charm_button.visible = Profiles.has_charm(Profiles.active_id, JournalContent.CHARM_COURAGE)
	var finished := 0
	if not Profiles.active().is_empty():
		finished = int(Profiles.active()["chapters"])
	_journey_button.visible = finished >= 1
	_end_panel.offset_top = -390.0 if _journey_button.visible else -290.0
	_end_panel.visible = true
	_play_again_button.grab_focus()


## -- UI construction ---------------------------------------------------------

func _panel_style() -> StyleBoxFlat:
	return PaperUI.panel_style()


func _make_button(text: String) -> Button:
	return PaperUI.button(text)


func _label(text: String, size: int) -> Label:
	return PaperUI.label(text, size)


func _build_corner_buttons() -> void:
	var box := HBoxContainer.new()
	box.anchor_left = 1.0
	box.anchor_right = 1.0
	box.offset_left = -232.0
	box.offset_right = -16.0
	box.offset_top = 16.0
	box.offset_bottom = 80.0
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	box.add_theme_constant_override("separation", 12)
	_root.add_child(box)
	_book_button = IconButton.new("book")
	_book_button.pressed.connect(_open_journal)
	box.add_child(_book_button)
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
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	vbox.add_child(_label("Paused", 40))

	_resume_button = _make_button("Resume")
	_resume_button.pressed.connect(func() -> void: set_paused(false))
	vbox.add_child(_resume_button)

	var journal_button := _make_button("Faith Journal")
	journal_button.pressed.connect(_open_journal)
	vbox.add_child(journal_button)

	_read_check = CheckButton.new()
	_read_check.text = "Read the story aloud"
	_read_check.add_theme_font_size_override("font_size", 24)
	_read_check.add_theme_color_override("font_color", INK)
	_read_check.add_theme_color_override("font_hover_color", INK)
	_read_check.add_theme_color_override("font_focus_color", INK)
	_read_check.add_theme_color_override("font_pressed_color", INK)
	_read_check.toggled.connect(_on_read_check_toggled)
	vbox.add_child(_read_check)

	_easy_check = CheckButton.new()
	_easy_check.text = "Easy words"
	_easy_check.add_theme_font_size_override("font_size", 24)
	for color_name in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		_easy_check.add_theme_color_override(color_name, INK)
	_easy_check.toggled.connect(_on_easy_check_toggled)
	vbox.add_child(_easy_check)

	_volume = _add_slider_row(vbox, "Volume", _on_volume_changed)
	_music_slider = _add_slider_row(vbox, "Music", _on_music_changed)
	_sounds_slider = _add_slider_row(vbox, "Sounds", _on_sounds_changed)
	_voice_slider = _add_slider_row(vbox, "Voices", _on_voice_changed)

	var restart := _make_button("Play again from the start")
	restart.pressed.connect(_restart)
	vbox.add_child(restart)

	var change_player := _make_button("Change player")
	change_player.pressed.connect(change_player_and_restart)
	vbox.add_child(change_player)


func _add_slider_row(parent: Control, text: String, on_change: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var label := _label(text, 24)
	label.custom_minimum_size.x = 110.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(220.0, 32.0)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	parent.add_child(row)
	return slider


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
	_end_panel.offset_bottom = -24.0
	_end_panel.visible = false
	_root.add_child(_end_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_end_panel.add_child(column)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	_play_again_button = _make_button("Play again")
	_play_again_button.custom_minimum_size = Vector2(200.0, 62.0)
	_play_again_button.pressed.connect(_restart)
	row.add_child(_play_again_button)
	var journal_button := _make_button("My journal")
	journal_button.custom_minimum_size = Vector2(200.0, 62.0)
	journal_button.pressed.connect(_open_journal)
	row.add_child(journal_button)
	_colour_charm_button = _make_button("Colour my charm")
	_colour_charm_button.custom_minimum_size = Vector2(290.0, 62.0)
	_colour_charm_button.pressed.connect(_open_colouring)
	row.add_child(_colour_charm_button)
	var keep := _make_button("Keep exploring")
	keep.custom_minimum_size = Vector2(240.0, 62.0)
	keep.pressed.connect(func() -> void:
		_end_panel.visible = false
		get_viewport().gui_release_focus())
	row.add_child(keep)
	_journey_button = _make_button("Faith Journey")
	_journey_button.custom_minimum_size = Vector2(280.0, 62.0)
	_journey_button.visible = false
	_journey_button.pressed.connect(_open_journey)
	var journey_row := CenterContainer.new()
	journey_row.add_child(_journey_button)
	column.add_child(journey_row)


## -- Settings sync -----------------------------------------------------------

func _sync_pause_controls() -> void:
	_read_check.visible = _audio != null and _audio.has_method("is_read_aloud_available") and _audio.is_read_aloud_available()
	_read_check.set_pressed_no_signal(GameSettings.read_aloud)
	_easy_check.set_pressed_no_signal(GameSettings.easy_words)
	_volume.set_value_no_signal(GameSettings.master_volume)
	_music_slider.set_value_no_signal(GameSettings.music_volume)
	_sounds_slider.set_value_no_signal(GameSettings.sounds_volume)
	_voice_slider.set_value_no_signal(GameSettings.voice_volume)


func _refresh_speaker() -> void:
	var available: bool = _audio != null and _audio.has_method("is_read_aloud_available") and _audio.is_read_aloud_available()
	_speaker_button.visible = available
	_speaker_button.on = available and GameSettings.read_aloud
	_speaker_button.queue_redraw()


func _on_speaker_pressed() -> void:
	if _audio and _audio.has_method("set_read_aloud"):
		_audio.set_read_aloud(not GameSettings.read_aloud)
	_refresh_speaker()


## Takes effect from the next line of the story; what is on screen now stays as it is.
func _on_easy_check_toggled(pressed: bool) -> void:
	GameSettings.easy_words = pressed
	GameSettings.save_settings()


func _on_read_check_toggled(pressed: bool) -> void:
	if _audio and _audio.has_method("set_read_aloud"):
		_audio.set_read_aloud(pressed)
	_refresh_speaker()


func _on_volume_changed(value: float) -> void:
	GameSettings.master_volume = value
	_commit_mix()


func _on_music_changed(value: float) -> void:
	GameSettings.music_volume = value
	_commit_mix()


func _on_sounds_changed(value: float) -> void:
	GameSettings.sounds_volume = value
	_commit_mix()


func _on_voice_changed(value: float) -> void:
	GameSettings.voice_volume = value
	_commit_mix()


func _commit_mix() -> void:
	SoundBus.apply_mix()
	GameSettings.save_settings()
