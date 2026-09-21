extends CanvasLayer
## "Who is playing?": the first thing on a fresh start. Each child picks their picture and name (up to
## Profiles.MAX_PROFILES on one tablet) so the Faith Journal is theirs. The story waits for a choice
## (see chapter_director.gd). Pressing "Play again" keeps the same child; the pause menu's "Change
## player" shows this screen again.
## Built entirely in code, like game_menu.gd.

signal profile_chosen(id: String)

const Profiles := preload("res://scripts/profiles.gd")
const PaperUI := preload("res://scripts/paper_ui.gd")
const AvatarIcon := preload("res://scripts/avatar_icon.gd")
const GameSettings := preload("res://scripts/game_settings.gd")
const SoundBus := preload("res://scripts/sound_bus.gd")

## What is read aloud on each view, for a child who cannot read yet (recorded clips in vo_library.gd).
const PICK_LINE := "Who is playing? Tap your picture."
const CREATE_LINE := "What is your name? Type it, then pick a picture."

var _audio: Node
var _speak_token: int = 0
var _title_labels: Array = []
var _pick_view: Control
var _create_view: Control
var _profile_row: HBoxContainer
var _name_edit: LineEdit
var _hint: Label
var _back_button: Button
var _avatar_buttons: Dictionary = {}
var _selected_avatar: String = Profiles.AVATAR_KINDS[0]


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_audio = get_parent().get_node_or_null("%AudioDirector")
	_build()
	visible = false
	open_if_nobody_is_playing()


## Shows the screen when no child has been chosen yet (a fresh start, or after "Change player").
func open_if_nobody_is_playing() -> void:
	if Profiles.active_id.is_empty():
		open()


func is_open() -> bool:
	return visible


func open() -> void:
	Profiles.load_all()
	visible = true
	Profiles.picker_open = true
	get_tree().paused = true
	_refresh_profiles()
	if Profiles.count() == 0:
		_show_create()
	else:
		_show_pick()


func close() -> void:
	visible = false
	Profiles.picker_open = false
	_speak_token += 1
	if _audio:
		_audio.stop_speech()
		_audio.process_mode = Node.PROCESS_MODE_INHERIT
	get_tree().paused = false
	get_viewport().gui_release_focus()


## Makes `id` the child playing, brings back their read-aloud and volume choices, and lets the story start.
func choose(id: String) -> void:
	Profiles.set_active(id)
	if Profiles.active_id.is_empty():
		return
	GameSettings.apply_profile(Profiles.active().get("settings", {}))
	SoundBus.apply_mix()
	close()
	profile_chosen.emit(id)


## Makes a new child from what was typed and picked, and chooses them. Returns the id, or "" when the
## name is empty or the tablet is full (the hint says which).
func create_profile(display_name: String, avatar: String) -> String:
	if Profiles.clean_name(display_name).is_empty():
		_hint.text = "Type your name first"
		return ""
	if not Profiles.name_allowed(display_name):
		_hint.text = "Please pick a different name"
		return ""
	var id := Profiles.create(display_name, avatar)
	if id.is_empty():
		_hint.text = "This tablet has room for %d players" % Profiles.MAX_PROFILES
		return ""
	choose(id)
	return id


# ---- building ---------------------------------------------------------------------------------------

func _build() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = PaperUI.PAPER
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_pick_view = _centered_column()
	_pick_view.add_child(PaperUI.label("Who is playing?", 52))
	_profile_row = HBoxContainer.new()
	_profile_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_profile_row.add_theme_constant_override("separation", 22)
	_pick_view.add_child(_profile_row)
	_pick_view.add_child(PaperUI.label("Your journal stays on this tablet.", 22))

	_create_view = _centered_column()
	var create_title := PaperUI.label("What is your name?", 46)
	_create_view.add_child(create_title)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Your name"
	_name_edit.max_length = Profiles.MAX_NAME_LENGTH
	_name_edit.custom_minimum_size = Vector2(420.0, 70.0)
	_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_edit.add_theme_font_size_override("font_size", 34)
	_name_edit.add_theme_color_override("font_color", PaperUI.INK)
	_name_edit.add_theme_color_override("font_placeholder_color", PaperUI.INK_SOFT)
	_name_edit.add_theme_color_override("caret_color", PaperUI.INK)
	_name_edit.add_theme_stylebox_override("normal", PaperUI.card_style(Color.WHITE))
	_name_edit.add_theme_stylebox_override("focus", PaperUI.card_style(Color(1.0, 0.98, 0.9)))
	_name_edit.text_changed.connect(func(_t: String) -> void: _hint.text = "")
	_name_edit.text_submitted.connect(func(t: String) -> void: create_profile(t, _selected_avatar))
	_create_view.add_child(_name_edit)
	var picture_title := PaperUI.label("Pick your picture", 30)
	_create_view.add_child(picture_title)
	_title_labels = [create_title, picture_title]
	var avatars := HBoxContainer.new()
	avatars.alignment = BoxContainer.ALIGNMENT_CENTER
	avatars.add_theme_constant_override("separation", 12)
	_create_view.add_child(avatars)
	for kind in Profiles.AVATAR_KINDS:
		var b := Button.new()
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(110.0, 110.0)
		b.add_theme_stylebox_override("normal", _avatar_frame(false))
		b.add_theme_stylebox_override("hover", _avatar_frame(false))
		b.add_theme_stylebox_override("pressed", _avatar_frame(true))
		b.add_theme_stylebox_override("focus", _avatar_frame(true))
		b.add_child(_centered_icon(kind, 84.0))
		b.pressed.connect(_select_avatar.bind(kind))
		avatars.add_child(b)
		_avatar_buttons[kind] = b
	_hint = PaperUI.label("", 24)
	_hint.add_theme_color_override("font_color", Color(0.75, 0.2, 0.15))
	_create_view.add_child(_hint)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 18)
	_create_view.add_child(buttons)
	_back_button = PaperUI.button("Back", Vector2(200.0, 66.0), 28, PaperUI.PAPER_DEEP)
	_back_button.pressed.connect(_show_pick)
	buttons.add_child(_back_button)
	var done := PaperUI.button("Let's go", Vector2(280.0, 66.0), 30)
	done.pressed.connect(func() -> void: create_profile(_name_edit.text, _selected_avatar))
	buttons.add_child(done)
	_select_avatar(_selected_avatar)


func _centered_column() -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 26)
	center.add_child(column)
	return column


func _avatar_frame(selected: bool) -> StyleBoxFlat:
	var sb := PaperUI.card_style(PaperUI.GOLD if selected else PaperUI.PAPER)
	sb.set_border_width_all(5 if selected else 2)
	sb.set_corner_radius_all(22)
	return sb


func _centered_icon(kind: String, side: float) -> Control:
	var icon := AvatarIcon.new(kind, side)
	icon.position = Vector2(55.0 - side * 0.5, 55.0 - side * 0.5)
	return icon


func _select_avatar(kind: String) -> void:
	_selected_avatar = kind
	for k in _avatar_buttons:
		(_avatar_buttons[k] as Button).set_pressed_no_signal(k == kind)


# ---- the two views ----------------------------------------------------------------------------------

func _show_pick() -> void:
	(_create_view.get_parent() as Control).visible = false
	(_pick_view.get_parent() as Control).visible = true
	_fit_to_keyboard(0.0)
	if _profile_row.get_child_count() > 0:
		(_profile_row.get_child(0) as Control).grab_focus()
	_say(PICK_LINE)


func _show_create() -> void:
	(_pick_view.get_parent() as Control).visible = false
	(_create_view.get_parent() as Control).visible = true
	_name_edit.text = ""
	_hint.text = ""
	_back_button.visible = Profiles.count() > 0
	_name_edit.grab_focus()
	_say(CREATE_LINE)


func _refresh_profiles() -> void:
	for child in _profile_row.get_children():
		_profile_row.remove_child(child)
		child.queue_free()
	for p in Profiles.all():
		_profile_row.add_child(_profile_button(p["name"], p["avatar"], _on_profile_pressed.bind(p["id"])))
	if Profiles.can_add():
		_profile_row.add_child(_profile_button("New", "", _show_create))


func _on_profile_pressed(id: String) -> void:
	choose(id)


func _profile_button(display_name: String, kind: String, on_press: Callable) -> Button:
	var b := PaperUI.button("", Vector2(190.0, 240.0), 26, PaperUI.PAPER)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 10)
	var icon: Control = AvatarIcon.new("plus" if kind.is_empty() else kind, 120.0)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(icon)
	var name_label := PaperUI.label(display_name, 30)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(name_label)
	b.add_child(column)
	b.pressed.connect(on_press)
	return b


# ---- read aloud -------------------------------------------------------------------------------------

## Reads a line of this screen aloud after a short pause, unless the child has moved on by then. The audio
## director is kept running while the game is paused, as the journal does.
func _say(line: String) -> void:
	if _audio == null:
		return
	_speak_token += 1
	var token := _speak_token
	_audio.process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().create_timer(0.5).timeout
	if token != _speak_token or not visible or not _audio.is_read_aloud_enabled():
		return
	_audio.stop_speech()
	_audio.speak_dialogue(line)


# ---- the on-screen keyboard -------------------------------------------------------------------------

func _process(_delta: float) -> void:
	if not visible or not (_create_view.get_parent() as Control).visible:
		return
	var window_height := float(get_window().size.y)
	if window_height <= 0.0:
		return
	var keyboard_px := float(DisplayServer.virtual_keyboard_get_height())
	_fit_to_keyboard(keyboard_px * get_viewport().get_visible_rect().size.y / window_height)


## Lifts the name form above the keyboard (in screen units, 0 when there is none). With the keyboard up
## there is room for only the name field, the pictures and the buttons, so the headings step aside.
func _fit_to_keyboard(keyboard_height: float) -> void:
	var center := _create_view.get_parent() as Control
	center.offset_bottom = -keyboard_height
	var compact := keyboard_height > 0.0
	for heading in _title_labels:
		(heading as Control).visible = not compact
	_create_view.add_theme_constant_override("separation", 12 if compact else 26)
