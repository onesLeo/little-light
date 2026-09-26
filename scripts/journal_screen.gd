extends CanvasLayer
## The Faith Journal: the verses and charms the child playing has earned (see journal_content.gd),
## with each one read aloud when tapped. Open it from the round book button, the pause menu, or the
## end-of-chapter panel. A small "For grown-ups" area, behind a press-and-hold, can empty this child's
## journal or take them off the tablet.
## Built entirely in code, like game_menu.gd. While it is open the game is paused and the audio
## director keeps running so the read-aloud clips can play.

signal closed
## The child was taken off the tablet: the game should go back to "Who is playing?".
signal player_removed

const Profiles := preload("res://scripts/profiles.gd")
const PaperUI := preload("res://scripts/paper_ui.gd")
const AvatarIcon := preload("res://scripts/avatar_icon.gd")
const JournalContent := preload("res://scripts/journal_content.gd")

## How long the grown-ups button has to be held down.
const HOLD_SECONDS := 3.0

var _audio: Node
var _paused_by_me: bool = false
var _title: Label
var _title_row: HBoxContainer
var _verse_box: VBoxContainer
var _charm_row: HBoxContainer
var _note: Label
var _colour_screen: CanvasLayer
var _colour_button: Button
var _journey_button: Button
var _journey: CanvasLayer
var _picked_charm: String = ""
var _close_button: Button
var _grownups_button: Button
var _grownups: Control
var _grownups_box: VBoxContainer
var _hold_bar: ProgressBar
var _holding: bool = false
var _held: float = 0.0


func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	_audio = get_parent().get_node_or_null("%AudioDirector")
	_journey = get_parent().get_node_or_null("FaithJourney")
	_colour_screen = get_parent().get_node_or_null("ColourScreen")
	if _colour_screen and _colour_screen.has_signal("closed"):
		_colour_screen.closed.connect(_on_colouring_closed)
	_build()
	visible = false


func is_open() -> bool:
	return visible


func open() -> void:
	_refresh()
	_close_grownups()
	visible = true
	if not get_tree().paused:
		get_tree().paused = true
		_paused_by_me = true
	if _audio:
		_audio.stop_speech()
		_audio.process_mode = Node.PROCESS_MODE_ALWAYS
	_close_button.grab_focus()


func close() -> void:
	if not visible:
		return
	if _audio:
		_audio.stop_speech()
		_audio.process_mode = Node.PROCESS_MODE_INHERIT
	visible = false
	_holding = false
	if _paused_by_me:
		get_tree().paused = false
		_paused_by_me = false
	get_viewport().gui_release_focus()
	closed.emit()


func _input(event: InputEvent) -> void:
	if visible and InputMap.has_action("pause") and event.is_action_pressed("pause") and not event.is_echo():
		if _colour_screen != null and _colour_screen.is_open():
			return   # the colouring page handles its own way out
		if _grownups.visible:
			_close_grownups()
		else:
			close()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _holding or not _grownups.visible:
		return
	_held += delta
	_hold_bar.value = minf(_held / HOLD_SECONDS, 1.0)
	if _held >= HOLD_SECONDS:
		_holding = false
		_show_grownup_options()


# ---- building ---------------------------------------------------------------------------------------

func _build() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.1, 0.06, 0.02, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", PaperUI.panel_style(16))
	panel.custom_minimum_size = Vector2(1040.0, 0.0)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)

	_title_row = HBoxContainer.new()
	_title_row.add_theme_constant_override("separation", 16)
	column.add_child(_title_row)
	_title_row.add_child(Control.new())   # the child's picture goes here
	_title = PaperUI.label("Faith Journal", 44, HORIZONTAL_ALIGNMENT_LEFT)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_title_row.add_child(_title)
	_close_button = PaperUI.button("Close", Vector2(170.0, 60.0), 28)
	_close_button.pressed.connect(close)
	_title_row.add_child(_close_button)

	column.add_child(PaperUI.label("Verses", 24, HORIZONTAL_ALIGNMENT_LEFT))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, 170.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_verse_box = VBoxContainer.new()
	_verse_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_verse_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_verse_box)

	column.add_child(PaperUI.label("Charms", 24, HORIZONTAL_ALIGNMENT_LEFT))
	_charm_row = HBoxContainer.new()
	_charm_row.add_theme_constant_override("separation", 18)
	column.add_child(_charm_row)
	var note_row := HBoxContainer.new()
	note_row.add_theme_constant_override("separation", 16)
	column.add_child(note_row)
	_note = PaperUI.label("", 24, HORIZONTAL_ALIGNMENT_LEFT)
	_note.custom_minimum_size.y = 34.0
	_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_row.add_child(_note)
	_colour_button = PaperUI.button("Colour my charm", Vector2(290.0, 60.0), 26)
	_colour_button.pressed.connect(_colour_picked_charm)
	note_row.add_child(_colour_button)
	_journey_button = PaperUI.button("Faith Journey", Vector2(250.0, 60.0), 26)
	_journey_button.visible = false
	_journey_button.pressed.connect(_open_journey)
	note_row.add_child(_journey_button)

	_grownups_button = PaperUI.button("For grown-ups", Vector2(230.0, 48.0), 22, PaperUI.PAPER_DEEP)
	_grownups_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_grownups_button.pressed.connect(_show_gate)
	column.add_child(_grownups_button)

	_build_grownups_overlay()


func _build_grownups_overlay() -> void:
	_grownups = Control.new()
	_grownups.set_anchors_preset(Control.PRESET_FULL_RECT)
	_grownups.mouse_filter = Control.MOUSE_FILTER_STOP
	_grownups.visible = false
	add_child(_grownups)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.1, 0.06, 0.02, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grownups.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grownups.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", PaperUI.panel_style())
	panel.custom_minimum_size = Vector2(640.0, 0.0)
	center.add_child(panel)
	_grownups_box = VBoxContainer.new()
	_grownups_box.add_theme_constant_override("separation", 16)
	panel.add_child(_grownups_box)


# ---- the journal itself -----------------------------------------------------------------------------

func _refresh() -> void:
	var p := Profiles.active()
	_title.text = "%s's Faith Journal" % p["name"] if not p.is_empty() else "Faith Journal"
	_title_row.get_child(0).queue_free()
	var picture: Control = AvatarIcon.new(p["avatar"] if not p.is_empty() else "olive", 76.0)
	_title_row.add_child(picture)
	_title_row.move_child(picture, 0)
	_note.text = ""
	_grownups_button.visible = not p.is_empty()
	if p.is_empty() or not Profiles.has_charm(p["id"], _picked_charm):
		_picked_charm = ""

	for child in _verse_box.get_children():
		_verse_box.remove_child(child)
		child.queue_free()
	var earned_verses := 0
	for v in JournalContent.VERSES:
		if p.is_empty() or not Profiles.has_verse(p["id"], v["id"]):
			continue
		earned_verses += 1
		_verse_box.add_child(_verse_card(v))
	if earned_verses == 0:
		var empty := PaperUI.label("Your first verse is waiting in the story.", 26, HORIZONTAL_ALIGNMENT_LEFT)
		_verse_box.add_child(empty)

	for child in _charm_row.get_children():
		_charm_row.remove_child(child)
		child.queue_free()
	for c in JournalContent.CHARMS:
		if p.is_empty() or not Profiles.has_charm(p["id"], c["id"]):
			continue
		_charm_row.add_child(_charm_button(c))
		if _picked_charm.is_empty():
			_picked_charm = c["id"]
	for _i in JournalContent.MYSTERY_SLOTS:
		_charm_row.add_child(_mystery_slot())
	_colour_button.visible = _colour_screen != null and not _picked_charm.is_empty()
	_journey_button.visible = _journey != null and not p.is_empty()


func _open_journey() -> void:
	if _journey and _journey.has_method("open"):
		close()
		_journey.open()


func _verse_card(v: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", PaperUI.card_style())
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_column)
	text_column.add_child(PaperUI.label(v["ref"], 26, HORIZONTAL_ALIGNMENT_LEFT))
	var body := PaperUI.label("\"%s\"" % v["text"], 24, HORIZONTAL_ALIGNMENT_LEFT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 640.0
	text_column.add_child(body)
	if v.has("why") and not str(v["why"]).is_empty():
		var why := PaperUI.label(str(v["why"]), 20, HORIZONTAL_ALIGNMENT_LEFT)
		why.name = "WhyNote"
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why.modulate = Color(0.35, 0.28, 0.18, 1.0)
		why.custom_minimum_size.x = 640.0
		text_column.add_child(why)
	var hear := PaperUI.button("Hear it", Vector2(170.0, 60.0), 26)
	hear.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hear.pressed.connect(_hear.bind(JournalContent.verse_dialogue(v["id"])))
	row.add_child(hear)
	return card


func _charm_button(c: Dictionary) -> Button:
	var b := PaperUI.button("", Vector2(150.0, 180.0), 22, PaperUI.PAPER)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 6)
	var icon = AvatarIcon.new("charm", 104.0)
	icon.tint = c["color"]
	icon.charm_id = c["id"]
	icon.colours = Profiles.charm_colours(Profiles.active_id, c["id"]) if Profiles.has_coloured_charm(Profiles.active_id, c["id"]) else []
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(icon)
	# Two-word names (Faithful Heart) wrap onto a second line inside the card instead of running out.
	var name_label := PaperUI.label(c["name"], 22 if " " in str(c["name"]) else 26)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.x = 136.0
	column.add_child(name_label)
	b.add_child(column)
	b.pressed.connect(func() -> void:
		_picked_charm = c["id"]
		_note.text = c["reason"]
		_hear(c["spoken"]))
	return b


func _mystery_slot() -> Control:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(150.0, 180.0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 6)
	var icon: Control = AvatarIcon.new("mystery", 104.0)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(icon)
	var soon := PaperUI.label("Not yet", 22)
	soon.add_theme_color_override("font_color", PaperUI.INK_SOFT)
	column.add_child(soon)
	return column


## Opens the colouring page for the charm the child last tapped (or their first one).
func _colour_picked_charm() -> void:
	if _colour_screen == null or _picked_charm.is_empty():
		return
	if _audio:
		_audio.stop_speech()
	_colour_screen.open(_picked_charm)


func _on_colouring_closed() -> void:
	if visible:
		_refresh()
		_colour_button.grab_focus()


func _hear(text: String) -> void:
	if _audio == null or text.is_empty():
		return
	if not _audio.is_read_aloud_enabled():
		_note.text = "Reading aloud is off. You can turn it on in the pause menu."
		return
	_audio.speak_dialogue(text)


# ---- for grown-ups ----------------------------------------------------------------------------------

func _clear_grownups() -> void:
	for child in _grownups_box.get_children():
		_grownups_box.remove_child(child)
		child.queue_free()


func _close_grownups() -> void:
	_holding = false
	_held = 0.0
	_grownups.visible = false


func _show_gate() -> void:
	_clear_grownups()
	_held = 0.0
	_holding = false
	_grownups_box.add_child(PaperUI.label("For grown-ups", 40))
	var explain := PaperUI.label("Press and hold the button for %d seconds to change this journal." % int(HOLD_SECONDS), 24)
	explain.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explain.custom_minimum_size.x = 580.0
	_grownups_box.add_child(explain)
	var hold := PaperUI.button("Hold here", Vector2(320.0, 70.0), 28)
	hold.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hold.button_down.connect(func() -> void:
		_holding = true
		_held = 0.0)
	var release := func() -> void:
		_holding = false
		_held = 0.0
		_hold_bar.value = 0.0
	hold.button_up.connect(release)
	hold.focus_exited.connect(release)
	_grownups_box.add_child(hold)
	_hold_bar = ProgressBar.new()
	_hold_bar.max_value = 1.0
	_hold_bar.step = 0.01
	_hold_bar.show_percentage = false
	_hold_bar.custom_minimum_size = Vector2(320.0, 18.0)
	_hold_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_grownups_box.add_child(_hold_bar)
	var cancel := PaperUI.button("Back to the journal", Vector2(320.0, 56.0), 24, PaperUI.PAPER_DEEP)
	cancel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel.pressed.connect(_close_grownups)
	_grownups_box.add_child(cancel)
	_grownups.visible = true
	cancel.grab_focus()


func _show_grownup_options() -> void:
	_clear_grownups()
	var p := Profiles.active()
	var who: String = p["name"] if not p.is_empty() else "this player"
	_grownups_box.add_child(PaperUI.label("What would you like to do?", 34))
	var erase := PaperUI.button("Empty %s's journal" % who, Vector2(560.0, 62.0), 26)
	erase.pressed.connect(_show_confirm.bind("Empty %s's journal and start again? Their verses and charms will be gone." % who, "Empty it", _erase))
	_grownups_box.add_child(erase)
	var remove := PaperUI.button("Remove %s from this tablet" % who, Vector2(560.0, 62.0), 26)
	remove.pressed.connect(_show_confirm.bind("Remove %s from this tablet? Their name, journal and settings will be gone." % who, "Remove", _remove))
	_grownups_box.add_child(remove)
	var back := PaperUI.button("Back to the journal", Vector2(560.0, 56.0), 24, PaperUI.PAPER_DEEP)
	back.pressed.connect(_close_grownups)
	_grownups_box.add_child(back)
	back.grab_focus()


func _show_confirm(question: String, yes_label: String, on_yes: Callable) -> void:
	_clear_grownups()
	var q := PaperUI.label(question, 28)
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q.custom_minimum_size.x = 580.0
	_grownups_box.add_child(q)
	_grownups_box.add_child(PaperUI.label("This cannot be undone.", 24))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	_grownups_box.add_child(row)
	var no := PaperUI.button("Keep it", Vector2(220.0, 62.0), 26)
	no.pressed.connect(_close_grownups)
	row.add_child(no)
	var yes := PaperUI.button(yes_label, Vector2(220.0, 62.0), 26, Color(0.93, 0.6, 0.55))
	yes.pressed.connect(on_yes)
	row.add_child(yes)
	no.grab_focus()


func _erase() -> void:
	Profiles.erase_progress(Profiles.active_id)
	_close_grownups()
	_refresh()


func _remove() -> void:
	var id := Profiles.active_id
	_close_grownups()
	close()
	Profiles.remove(id)
	player_removed.emit()
