extends CanvasLayer
## Pause menu, read-aloud toggle, Faith Journal button and the end-of-chapter "Play again" panel.
##
## - Pause: Esc / P / gamepad Start, or the round button top-right. Offers
##   Resume, the Faith Journal, the Faith Journey map, read-aloud on/off, volume,
##   "Start this chapter again" and "Change player".
## - Book button (top-right): opens the Faith Journal (journal_screen.gd).
## - The end panel also offers "Colour my charm" (colour_screen.gd) and the
##   "Faith Journey" map (faith_journey_screen.gd), where the next chapter is chosen.
## - Read-aloud button (speaker icon): turns text-to-speech on or off.
## - After the chapter finishes, a "Play again" / "Keep exploring" panel
##   appears once the confetti has had a moment. "Play again" replays the chapter
##   just finished (Profiles.current_chapter), not the whole journey.
## Built entirely in code so it needs no scene edits beyond adding this node.

const GameSettings := preload("res://scripts/game_settings.gd")
const SoundBus := preload("res://scripts/sound_bus.gd")
const Profiles := preload("res://scripts/profiles.gd")
const PaperUI := preload("res://scripts/paper_ui.gd")
const JournalContent := preload("res://scripts/journal_content.gd")

const PAPER := PaperUI.PAPER
const INK := PaperUI.INK
const GOLD := PaperUI.GOLD
## Every text colour a toggle switch uses, so none falls back to the default white.
const TOGGLE_TEXT_STATES := ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]

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
## True while the pause menu has put the end card aside; Resume brings it back.
var _end_paused_away: bool = false
var _end_title: Label
var _end_token: int = 0
var _play_again_button: Button
var _colour_charm_button: Button
var _end_charm: String = JournalContent.CHARM_COURAGE
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
	# The end card first, so the pause menu is drawn over it.
	_build_end_panel()
	_build_pause_panel()

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
		# The "Who is playing?" screen, the journal, the colouring page and the
		# Faith Journey map handle their own way out.
		if Profiles.picker_open or (_journal != null and _journal.is_open()) or (_colour != null and _colour.is_open()) or (_journey != null and _journey.is_open()):
			return
		set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func set_paused(paused: bool) -> void:
	get_tree().paused = paused
	_pause_layer.visible = paused
	# The end card steps aside while paused, so its buttons neither show through nor take focus.
	if paused and _end_panel.visible:
		_end_paused_away = true
		_end_panel.visible = false
	elif not paused and _end_paused_away:
		_end_paused_away = false
		_end_panel.visible = true
	if paused:
		if _audio and _audio.has_method("stop_speech"):
			_audio.stop_speech()
		_sync_pause_controls()
		_resume_button.grab_focus()
	else:
		get_viewport().gui_release_focus()


## Loads the scene again. With a child still playing, the chapter they were on starts over
## (Profiles.current_chapter); with nobody, "Who is playing?" and then the map come first.
func _restart() -> void:
	if Profiles.active_id.is_empty():
		Profiles.current_chapter = ""
	get_tree().paused = false
	if _audio and _audio.has_method("stop_speech"):
		_audio.stop_speech()
	for action in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)
	get_tree().reload_current_scene()


func _open_colouring() -> void:
	if _colour and _colour.has_method("open"):
		_colour.open(_end_charm)


func _open_journal() -> void:
	if _journal and _journal.has_method("open"):
		_journal.open()


func _open_journey() -> void:
	if _journey and _journey.has_method("open"):
		_journey.open()


## The end-of-chapter card steps aside once the child walks into another story.
func hide_end_panel() -> void:
	_end_token += 1
	_end_paused_away = false
	_end_panel.visible = false
	_set_dialogue_visible(true)


## The story's dialogue bar only repeats the last line while the end card is up, so it
## steps aside and the card has the bottom of the screen to itself.
func _set_dialogue_visible(on: bool) -> void:
	var bar := get_parent().get_node_or_null("UI/Panel") as CanvasItem
	if bar:
		bar.visible = on


## Forgets who is playing and starts over, which brings back the "Who is playing?" screen.
func change_player_and_restart() -> void:
	Profiles.set_active("")
	Profiles.current_chapter = ""
	_restart()


func _on_chapter_finished() -> void:
	show_end_panel(JournalContent.CHARM_COURAGE)


## The end-of-chapter card, a moment after the celebration. `charm_id` is the charm the
## chapter gave, so "Colour my charm" opens that one.
func show_end_panel(charm_id: String) -> void:
	_end_token += 1
	var token := _end_token
	await get_tree().create_timer(end_panel_delay).timeout
	if token != _end_token:
		return
	_end_charm = charm_id
	_colour_charm_button.visible = Profiles.has_charm(Profiles.active_id, charm_id)
	_journey_button.visible = _journey != null
	var charm_name := "Courage"
	for c in JournalContent.CHARMS:
		if c["id"] == charm_id:
			charm_name = str(c.get("name", charm_name))
	_end_title.text = "You earned the %s charm!" % charm_name
	_set_dialogue_visible(false)
	_end_panel.visible = true
	# The card is only as tall as what is on it: no empty paper under the buttons.
	_end_panel.reset_size()
	_end_panel.pivot_offset = _end_panel.size * 0.5
	_end_panel.scale = Vector2(0.85, 0.85)
	_end_panel.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_end_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_end_panel, "modulate:a", 1.0, 0.2)
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

	var map_button := _make_button("Faith Journey map")
	map_button.pressed.connect(_open_journey)
	vbox.add_child(map_button)

	_read_check = CheckButton.new()
	_read_check.text = "Read the story aloud"
	_read_check.add_theme_font_size_override("font_size", 24)
	# Ink in every state: a switch that is on and hovered uses font_hover_pressed_color, white by default.
	for color_name in TOGGLE_TEXT_STATES:
		_read_check.add_theme_color_override(color_name, INK)
	_read_check.toggled.connect(_on_read_check_toggled)
	vbox.add_child(_read_check)

	_easy_check = CheckButton.new()
	_easy_check.text = "Easy words"
	_easy_check.add_theme_font_size_override("font_size", 24)
	for color_name in TOGGLE_TEXT_STATES:
		_easy_check.add_theme_color_override(color_name, INK)
	_easy_check.toggled.connect(_on_easy_check_toggled)
	vbox.add_child(_easy_check)

	_volume = _add_slider_row(vbox, "Volume", _on_volume_changed)
	_music_slider = _add_slider_row(vbox, "Music", _on_music_changed)
	_sounds_slider = _add_slider_row(vbox, "Sounds", _on_sounds_changed)
	_voice_slider = _add_slider_row(vbox, "Voices", _on_voice_changed)

	var restart := _make_button("Start this chapter again")
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


## The end-of-chapter card, centred under the "Chapter Complete!" banner: what was earned,
## then the two big choices (play this chapter again, or go on along the Faith Journey), then
## the small ones. It grows to fit what is on it.
func _build_end_panel() -> void:
	_end_panel = PanelContainer.new()
	_end_panel.add_theme_stylebox_override("panel", PaperUI.panel_style(28, 26))
	_end_panel.anchor_left = 0.5
	_end_panel.anchor_right = 0.5
	_end_panel.anchor_top = 0.62
	_end_panel.anchor_bottom = 0.62
	_end_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_end_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_end_panel.visible = false
	_root.add_child(_end_panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	_end_panel.add_child(column)
	_end_title = _label("You earned a charm!", 32)
	column.add_child(_end_title)

	var big_row := HBoxContainer.new()
	big_row.alignment = BoxContainer.ALIGNMENT_CENTER
	big_row.add_theme_constant_override("separation", 18)
	column.add_child(big_row)
	_play_again_button = PaperUI.button("Play again", Vector2(270.0, 70.0), 28)
	_play_again_button.pressed.connect(_restart)
	big_row.add_child(_play_again_button)
	_journey_button = PaperUI.button("Faith Journey", Vector2(270.0, 70.0), 28)
	_journey_button.pressed.connect(_open_journey)
	big_row.add_child(_journey_button)

	var small_row := HBoxContainer.new()
	small_row.alignment = BoxContainer.ALIGNMENT_CENTER
	small_row.add_theme_constant_override("separation", 14)
	column.add_child(small_row)
	var journal_button := PaperUI.button("My journal", Vector2(190.0, 54.0), 22, PAPER)
	journal_button.pressed.connect(_open_journal)
	small_row.add_child(journal_button)
	_colour_charm_button = PaperUI.button("Colour my charm", Vector2(230.0, 54.0), 22, PAPER)
	_colour_charm_button.pressed.connect(_open_colouring)
	small_row.add_child(_colour_charm_button)
	var keep := PaperUI.button("Keep exploring", Vector2(210.0, 54.0), 22, PAPER)
	keep.pressed.connect(func() -> void:
		hide_end_panel()
		var banner := get_parent().find_child("CompleteBanner", true, false) as CanvasItem
		if banner:
			banner.visible = false
		get_viewport().gui_release_focus())
	small_row.add_child(keep)


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
