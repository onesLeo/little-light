extends CanvasLayer
## "Colour your charm": a paper page with the charm outlined in ink. Tap a paint, then tap a part of the
## charm to fill it. No freehand drawing, so a finger on a tablet cannot make a mess. What the child chose
## is saved for them at once (Profiles), shows on the charm in the Faith Journal, and is what the 3D charm
## looks like the next time the ceremony plays (charm_award.gd).
## Opened from the Faith Journal or the end-of-chapter panel. While it is open the game is paused.

signal closed

const Profiles := preload("res://scripts/profiles.gd")
const PaperUI := preload("res://scripts/paper_ui.gd")
const CharmArt := preload("res://scripts/charm_art.gd")
const JournalContent := preload("res://scripts/journal_content.gd")

const PAGE_SIDE := 470.0
const SWATCH_SIDE := 76.0


## The picture itself. Draws the charm and reports which part of it was tapped.
class Page extends Control:
	signal tapped(region: int)
	var charm_id: String = ""
	var colours: Array = []

	func _init() -> void:
		custom_minimum_size = Vector2(PAGE_SIDE, PAGE_SIDE)
		mouse_filter = Control.MOUSE_FILTER_STOP
		focus_mode = Control.FOCUS_NONE

	## Where the charm is drawn on the sheet.
	func art_rect() -> Rect2:
		return Rect2(Vector2(18.0, 14.0), size - Vector2(36.0, 28.0))

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var art := art_rect()
			tapped.emit(CharmArt.hit(charm_id, (event.position - art.position) / art.size))
			accept_event()

	func _draw() -> void:
		var sheet := StyleBoxFlat.new()
		sheet.bg_color = Color(1.0, 0.99, 0.95)
		sheet.border_color = PaperUI.INK_SOFT
		sheet.set_border_width_all(3)
		sheet.set_corner_radius_all(14)
		draw_style_box(sheet, Rect2(Vector2.ZERO, size))
		CharmArt.draw(self, art_rect(), charm_id, colours, 4.0)


var _audio: Node
var _paused_by_me: bool = false
var _charm_id: String = ""
var _colours: Array = []
var _history: Array = []
var _selected: int = 0
var _title: Label
var _page: Page
var _swatches: Array = []
var _done_button: Button


func _ready() -> void:
	layer = 14
	process_mode = Node.PROCESS_MODE_ALWAYS
	_audio = get_parent().get_node_or_null("%AudioDirector")
	_build()
	visible = false


func is_open() -> bool:
	return visible


## Opens the page for one of the playing child's charms.
func open(charm_id: String) -> void:
	var p := Profiles.active()
	if p.is_empty() or not Profiles.has_charm(p["id"], charm_id):
		return
	_charm_id = charm_id
	_colours = Profiles.charm_colours(p["id"], charm_id)
	_history.clear()
	var charm := JournalContent.charm(charm_id)
	_title.text = "Colour your %s charm" % charm.get("name", "")
	_page.charm_id = charm_id
	_page.colours = _colours
	_page.queue_redraw()
	_select(_selected)
	visible = true
	if not get_tree().paused:
		get_tree().paused = true
		_paused_by_me = true
	_done_button.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	if _paused_by_me:
		get_tree().paused = false
		_paused_by_me = false
	get_viewport().gui_release_focus()
	closed.emit()


func _input(event: InputEvent) -> void:
	if visible and InputMap.has_action("pause") and event.is_action_pressed("pause") and not event.is_echo():
		close()
		get_viewport().set_input_as_handled()


# ---- painting ---------------------------------------------------------------------------------------

func _select(index: int) -> void:
	_selected = clampi(index, 0, CharmArt.PALETTE.size() - 1)
	for i in _swatches.size():
		var swatch: Button = _swatches[i]
		var box := swatch.get_theme_stylebox("normal") as StyleBoxFlat
		box.set_border_width_all(9 if i == _selected else 3)


## Fills the tapped part with the chosen paint. A tap on the paper between the parts does nothing.
func paint(region: int) -> void:
	if region < 0 or region >= _colours.size() or int(_colours[region]) == _selected:
		return
	_history.append([[region, _colours[region]]])
	_colours[region] = _selected
	_changed()


func undo() -> void:
	if _history.is_empty():
		return
	for change in _history.pop_back():
		_colours[change[0]] = change[1]
	_changed()


## Clears every part. Undo brings it back.
func start_again() -> void:
	var changes: Array = []
	for i in _colours.size():
		if int(_colours[i]) >= 0:
			changes.append([i, _colours[i]])
			_colours[i] = -1
	if changes.is_empty():
		return
	_history.append(changes)
	_changed()


func _changed() -> void:
	_page.colours = _colours
	_page.queue_redraw()
	Profiles.set_charm_colours(Profiles.active_id, _charm_id, _colours)


# ---- building ---------------------------------------------------------------------------------------

func _build() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.1, 0.06, 0.02, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", PaperUI.panel_style(20))
	center.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	panel.add_child(row)

	_page = Page.new()
	_page.tapped.connect(paint)
	_page.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_page)

	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 14)
	side.custom_minimum_size.x = 400.0
	row.add_child(side)
	_title = PaperUI.label("Colour your charm", 34, HORIZONTAL_ALIGNMENT_LEFT)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_title)
	var hint := PaperUI.label("Tap a colour, then tap the charm.", 22, HORIZONTAL_ALIGNMENT_LEFT)
	hint.add_theme_color_override("font_color", PaperUI.INK_SOFT)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(hint)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	side.add_child(grid)
	for i in CharmArt.PALETTE.size():
		var swatch := PaperUI.button("", Vector2(SWATCH_SIDE, SWATCH_SIDE), 20, CharmArt.PALETTE[i])
		for state in ["normal", "hover", "focus", "pressed"]:
			(swatch.get_theme_stylebox(state) as StyleBoxFlat).set_corner_radius_all(int(SWATCH_SIDE / 2.0))
		swatch.pressed.connect(_select.bind(i))
		grid.add_child(swatch)
		_swatches.append(swatch)

	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 12)
	side.add_child(tools)
	var undo_button := PaperUI.button("Undo", Vector2(180.0, 62.0), 26, PaperUI.PAPER_DEEP)
	undo_button.pressed.connect(undo)
	tools.add_child(undo_button)
	var again_button := PaperUI.button("Start again", Vector2(208.0, 62.0), 26, PaperUI.PAPER_DEEP)
	again_button.pressed.connect(start_again)
	tools.add_child(again_button)

	_done_button = PaperUI.button("Done", Vector2(400.0, 66.0), 30)
	_done_button.pressed.connect(close)
	side.add_child(_done_button)
