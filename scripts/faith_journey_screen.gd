extends CanvasLayer
## The Faith Journey: an old paper map of the stories, not a blank page of icons.
## The valley, the river and the mountains are the picture. Each story is a small
## numbered label sitting on its place.
##
## It is the first stop after "Who is playing?" (open_to_choose): a bouncing "Start here"
## tag shows where the child's next story is. A chapter opens once the one before it is
## finished; tapping a closed one brings up a friendly "Not yet!" card that says which
## story comes first. Later it opens from the journal, the pause menu and the end of a
## chapter (open), with a Back button.

signal closed

const Profiles := preload("res://scripts/profiles.gd")
const PaperUI := preload("res://scripts/paper_ui.gd")
const MapArkSketch := preload("res://scripts/map_ark_sketch.gd")

const MAP_PATH := "res://assets/ui/faith_journey_map.jpg"
const MAP_ASPECT := 16.0 / 9.0
const STOP_SIZE := Vector2(270.0, 58.0)
const LOCKED_FILL := Color(0.86, 0.8, 0.68)
const DONE_FILL := Color(0.99, 0.95, 0.82)

## Where each story sits on the map, as a fraction of the picture. `chapter` is the
## Profiles chapter id; the last stop is the path still ahead.
const STOPS := [
	{"id": "valley", "chapter": Profiles.CHAPTER_VALLEY, "number": 1, "title": "The valley", "at": Vector2(0.22, 0.76)},
	{"id": "camp", "chapter": Profiles.CHAPTER_CAMP, "number": 2, "title": "The King's Camp", "at": Vector2(0.545, 0.50)},
	{"id": "ark", "chapter": Profiles.CHAPTER_ARK, "number": 3, "title": "Noah's Ark", "at": MapArkSketch.ANCHOR},
	{"id": "ahead", "chapter": "", "number": 4, "title": "Coming soon", "at": Vector2(0.84, 0.22)},
]

var _audio: Node
var _paused_by_me: bool = false
## True when the map is the first stop and no story has started behind it yet.
var _choosing: bool = false
var _map: TextureRect
var _ark_sketch: Control
var _line: Label
var _back: Button
var _change_player: Button
var _stops: Array = []
var _marker: Marker
var _ring: Ring
var _marker_stop: String = ""
var _notice: Control
var _notice_card: PanelContainer
var _notice_title: Label
var _notice_body: Label
var _notice_go: Button
var _notice_ok: Button
var _notice_action: Callable


## A small padlock, drawn so it does not depend on the font having an emoji.
class LockIcon extends Control:
	var ink := PaperUI.INK

	func _init(side: float) -> void:
		custom_minimum_size = Vector2(side, side)
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var s := size.x
		var body := Rect2(s * 0.18, s * 0.44, s * 0.64, s * 0.46)
		draw_arc(Vector2(s * 0.5, s * 0.44), s * 0.22, PI, TAU, 16, ink, maxf(2.0, s * 0.09))
		draw_rect(body, Color(0.98, 0.78, 0.25))
		draw_rect(body, ink, false, maxf(2.0, s * 0.06))
		draw_circle(Vector2(s * 0.5, s * 0.62), s * 0.07, ink)
		draw_line(Vector2(s * 0.5, s * 0.62), Vector2(s * 0.5, s * 0.76), ink, maxf(2.0, s * 0.06))


## A gold seal with a tick, for a story already finished.
class DoneBadge extends Control:
	func _init(side: float) -> void:
		custom_minimum_size = Vector2(side, side)
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var s := size.x
		var c := Vector2(s, s) * 0.5
		draw_circle(c, s * 0.46, PaperUI.GOLD)
		draw_arc(c, s * 0.46, 0.0, TAU, 24, PaperUI.INK, maxf(2.0, s * 0.07))
		draw_polyline(PackedVector2Array([c + Vector2(-s * 0.2, 0.0), c + Vector2(-s * 0.05, s * 0.16), c + Vector2(s * 0.22, -s * 0.16)]), PaperUI.INK, maxf(2.5, s * 0.1))


## Soft rings that keep spreading out from the stop where the next story starts.
class Ring extends Control:
	var t: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(1.0, 1.0)

	func _process(delta: float) -> void:
		if visible:
			t += delta
			queue_redraw()

	func _draw() -> void:
		for i in 3:
			var k := fmod(t * 0.55 + i / 3.0, 1.0)
			var radius := lerpf(26.0, 120.0, k)
			draw_circle(Vector2.ZERO, radius, Color(1.0, 0.84, 0.3, 0.3 * (1.0 - k)))
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.9, 0.6, 0.12, 0.85 * (1.0 - k)), 3.5, true)
		draw_circle(Vector2.ZERO, 11.0 + sin(t * 4.0) * 2.0, Color(1.0, 0.86, 0.35))
		draw_arc(Vector2.ZERO, 11.0 + sin(t * 4.0) * 2.0, 0.0, TAU, 24, PaperUI.INK, 2.5, true)


## The "Start here" tag: a gold paper flag with a point, bobbing over the stop.
class Marker extends Control:
	var text: String = "Start here"
	var t: float = 0.0
	var tip: Vector2 = Vector2.ZERO
	var _font: Font
	const FONT_SIZE := 28

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(1.0, 1.0)

	func _ready() -> void:
		_font = get_theme_default_font()

	func _process(delta: float) -> void:
		if visible:
			t += delta
			position = tip + Vector2(0.0, -absf(sin(t * 3.2)) * 16.0)
			queue_redraw()

	func _draw() -> void:
		if _font == null:
			return
		var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x + 44.0
		var h := 54.0
		var box := Rect2(-w * 0.5, -h - 22.0, w, h)
		var shadow := box
		shadow.position += Vector2(3.0, 5.0)
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(18)
		sb.bg_color = Color(0.0, 0.0, 0.0, 0.18)
		draw_style_box(sb, shadow)
		sb.bg_color = PaperUI.GOLD
		sb.border_color = PaperUI.INK
		sb.set_border_width_all(3)
		draw_style_box(sb, box)
		var point := PackedVector2Array([Vector2(-14.0, -25.0), Vector2(14.0, -25.0), Vector2(0.0, -2.0)])
		draw_colored_polygon(point, PaperUI.GOLD)
		draw_polyline(PackedVector2Array([point[0], point[2], point[1]]), PaperUI.INK, 3.0, true)
		var baseline := box.position.y + h * 0.5 + _font.get_ascent(FONT_SIZE) * 0.5 - 3.0
		draw_string(_font, Vector2(box.position.x, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, w, FONT_SIZE, PaperUI.INK)


func _ready() -> void:
	layer = 14
	process_mode = Node.PROCESS_MODE_ALWAYS
	_audio = get_parent().get_node_or_null("%AudioDirector")
	_build()
	visible = false
	get_viewport().size_changed.connect(_layout)


func is_open() -> bool:
	return visible


## From the journal, the pause menu or the end of a chapter: the map with a Back button.
func open() -> void:
	_choosing = false
	_show_map("One story at a time.")


## The first stop, before any story has started: no Back, since there is nothing behind the
## map yet. The child taps where their story starts.
func open_to_choose() -> void:
	_choosing = true
	var p := Profiles.active()
	var next := Profiles.next_chapter(Profiles.active_id)
	var line := "Tap a story to begin."
	if next == Profiles.CHAPTER_VALLEY:
		line = "Your journey starts in the valley."
	elif next == Profiles.CHAPTER_CAMP:
		line = "The King's Camp is next."
	elif next == Profiles.CHAPTER_ARK:
		line = "Noah's Ark is next."
	# The name is on the screen only: the recorded "Hello!" cannot say every child's name.
	var hello := "Hello, %s! " % p["name"] if not p.is_empty() else "Hello! "
	_show_map(hello + line, "Hello!\n" + line)


## `spoken` is what Wonder Light reads (one recorded clip per line); by default the line itself.
func _show_map(line: String, spoken: String = "") -> void:
	_line.text = line
	visible = true
	_notice.visible = false
	_back.visible = not _choosing
	_change_player.visible = _choosing
	if not get_tree().paused:
		get_tree().paused = true
		_paused_by_me = true
	_refresh_stops()
	if _audio:
		_audio.stop_speech()
		_audio.process_mode = Node.PROCESS_MODE_ALWAYS
		_audio.speak_dialogue(_wonder_light(spoken if not spoken.is_empty() else line))
	_layout()
	var first := _stop_button(_marker_stop) if not _marker_stop.is_empty() else null
	if first:
		first.grab_focus()
	elif _back.visible:
		_back.grab_focus()


func close() -> void:
	if not visible:
		return
	if _audio:
		_audio.stop_speech()
		_audio.process_mode = Node.PROCESS_MODE_INHERIT
	visible = false
	_notice.visible = false
	_choosing = false
	if _paused_by_me:
		get_tree().paused = false
		_paused_by_me = false
	get_viewport().gui_release_focus()
	closed.emit()


func is_locked(stop_id: String) -> bool:
	var stop := _stop_data(stop_id)
	if stop.is_empty():
		return true
	if str(stop["chapter"]).is_empty():
		return true
	return not Profiles.is_unlocked(Profiles.active_id, stop["chapter"])


func _input(event: InputEvent) -> void:
	if not visible or not InputMap.has_action("pause") or not event.is_action_pressed("pause") or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if _notice.visible:
		_hide_notice()
	elif not _choosing:
		close()


# ---- building ---------------------------------------------------------------------------------------

func _build() -> void:
	var ground := ColorRect.new()
	ground.set_anchors_preset(Control.PRESET_FULL_RECT)
	ground.color = Color(0.93, 0.86, 0.70)
	ground.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(ground)

	_map = TextureRect.new()
	_map.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(MAP_PATH):
		_map.texture = load(MAP_PATH)
	add_child(_map)

	# The valley and the camp are painted into the map; the ark is inked on top in the same hand.
	_ark_sketch = MapArkSketch.new()
	_ark_sketch.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_ark_sketch)

	var title := PaperUI.label("Faith Journey", 40)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_top = 18.0
	title.offset_bottom = 70.0
	title.offset_left = -280.0
	title.offset_right = 280.0
	add_child(title)

	_ring = Ring.new()
	add_child(_ring)

	for stop in STOPS:
		var button := PaperUI.button("%d  %s" % [stop["number"], stop["title"]], STOP_SIZE, 24, PaperUI.PAPER)
		button.set_anchors_preset(Control.PRESET_TOP_LEFT)
		for state in ["normal", "hover", "focus", "pressed"]:
			(button.get_theme_stylebox(state) as StyleBoxFlat).content_margin_left = 40.0
		var lock := LockIcon.new(30.0)
		lock.position = Vector2(12.0, (STOP_SIZE.y - 30.0) * 0.5)
		button.add_child(lock)
		var badge := DoneBadge.new(30.0)
		badge.position = lock.position
		button.add_child(badge)
		button.pressed.connect(_on_stop.bind(stop["id"]))
		add_child(button)
		_stops.append({"id": stop["id"], "at": stop["at"], "button": button, "lock": lock, "badge": badge})

	_marker = Marker.new()
	add_child(_marker)

	# What Wonder Light says sits under the title, clear of the stops on the map.
	_line = PaperUI.label("One story at a time.", 26)
	_line.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_line.offset_left = -560.0
	_line.offset_right = 560.0
	_line.offset_top = 74.0
	_line.offset_bottom = 116.0
	_line.add_theme_color_override("font_outline_color", PaperUI.PAPER)
	_line.add_theme_constant_override("outline_size", 10)
	add_child(_line)

	_back = PaperUI.button("Back", Vector2(200.0, 58.0), 26)
	_back.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_back.offset_left = -100.0
	_back.offset_right = 100.0
	_back.offset_top = -80.0
	_back.offset_bottom = -22.0
	_back.pressed.connect(close)
	add_child(_back)

	_change_player = PaperUI.button("Change player", Vector2(230.0, 52.0), 22, PaperUI.PAPER_DEEP)
	_change_player.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_change_player.offset_left = 22.0
	_change_player.offset_right = 252.0
	_change_player.offset_top = -74.0
	_change_player.offset_bottom = -22.0
	_change_player.pressed.connect(_on_change_player)
	add_child(_change_player)

	_build_notice()


## "Not yet!": a small card over the dimmed map, for a story that has not opened.
func _build_notice() -> void:
	_notice = Control.new()
	_notice.set_anchors_preset(Control.PRESET_FULL_RECT)
	_notice.mouse_filter = Control.MOUSE_FILTER_STOP
	_notice.visible = false
	add_child(_notice)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.1, 0.06, 0.02, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_hide_notice())
	_notice.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notice.add_child(center)
	_notice_card = PanelContainer.new()
	_notice_card.add_theme_stylebox_override("panel", PaperUI.panel_style(30, 28))
	center.add_child(_notice_card)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 16)
	_notice_card.add_child(column)
	var lock := LockIcon.new(72.0)
	lock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(lock)
	_notice_title = PaperUI.label("Not yet!", 44)
	column.add_child(_notice_title)
	_notice_body = PaperUI.label("", 27)
	_notice_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice_body.custom_minimum_size = Vector2(560.0, 0.0)
	column.add_child(_notice_body)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	column.add_child(row)
	_notice_go = PaperUI.button("Play Chapter 1", Vector2(290.0, 64.0), 26)
	_notice_go.pressed.connect(func() -> void:
		_hide_notice()
		if _notice_action.is_valid():
			_notice_action.call())
	row.add_child(_notice_go)
	_notice_ok = PaperUI.button("OK", Vector2(150.0, 64.0), 26, PaperUI.PAPER_DEEP)
	_notice_ok.pressed.connect(_hide_notice)
	row.add_child(_notice_ok)


# ---- state ------------------------------------------------------------------------------------------

func _refresh_stops() -> void:
	var next := Profiles.next_chapter(Profiles.active_id)
	_marker_stop = ""
	for stop in _stops:
		var data := _stop_data(stop["id"])
		var chapter: String = data["chapter"]
		var locked := is_locked(stop["id"])
		var done := not chapter.is_empty() and Profiles.has_finished(Profiles.active_id, chapter)
		var button: Button = stop["button"]
		(stop["lock"] as Control).visible = locked
		(stop["badge"] as Control).visible = done
		var fill := LOCKED_FILL if locked else (DONE_FILL if done else PaperUI.GOLD)
		for state in ["normal", "hover", "focus", "pressed"]:
			var sb := button.get_theme_stylebox(state) as StyleBoxFlat
			sb.bg_color = fill.lightened(0.12) if state in ["hover", "focus"] and not locked else fill
		var ink := PaperUI.INK_SOFT if locked else PaperUI.INK
		for color_name in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
			button.add_theme_color_override(color_name, ink)
		if chapter == next and not chapter.is_empty():
			_marker_stop = stop["id"]
	_marker.visible = not _marker_stop.is_empty()
	_ring.visible = _marker.visible
	var played_before := int(Profiles.active().get("chapters", 0)) > 0
	_marker.text = "Next story" if played_before else "Start here"


func _stop_data(stop_id: String) -> Dictionary:
	for stop in STOPS:
		if stop["id"] == stop_id:
			return stop
	return {}


func _stop_button(stop_id: String) -> Button:
	for stop in _stops:
		if stop["id"] == stop_id:
			return stop["button"]
	return null


func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	if view.x < 1.0 or view.y < 1.0:
		return
	var fitted := _fitted_map(view)
	_ark_sketch.fit(fitted)
	for stop in _stops:
		var at: Vector2 = stop["at"]
		var button: Button = stop["button"]
		var point := fitted.position + Vector2(fitted.size.x * at.x, fitted.size.y * at.y)
		# The label hangs just under its place, so the tents and trees stay in view.
		button.position = point - STOP_SIZE * 0.5 + Vector2(0.0, 64.0)
		if stop["id"] == _marker_stop:
			_ring.position = point
			_marker.tip = point - Vector2(0.0, 8.0)
			_marker.position = _marker.tip


func _fitted_map(view: Vector2) -> Rect2:
	var view_aspect := view.x / view.y
	if view_aspect > MAP_ASPECT:
		var h := view.y
		var w := h * MAP_ASPECT
		return Rect2((view.x - w) * 0.5, 0.0, w, h)
	var w := view.x
	var h := w / MAP_ASPECT
	return Rect2(0.0, (view.y - h) * 0.5, w, h)


# ---- choosing a story -------------------------------------------------------------------------------

func _on_stop(id: String) -> void:
	if is_locked(id):
		_show_locked(id)
		return
	if id == "valley":
		_play_valley()
	elif id == "camp":
		var camp := get_parent().get_node_or_null("KingsCamp")
		if camp and camp.has_method("visit"):
			close()
			camp.visit()
		else:
			_say("The King's Camp is still being prepared.")
	elif id == "ark":
		var ark := get_parent().get_node_or_null("NoahsArk")
		if ark and ark.has_method("visit"):
			close()
			ark.visit()
		else:
			_say("Noah's Ark is still being prepared.")


## The story is closed: the button gives a little shake, and a card says which story
## comes first, with a button that goes straight to it.
func _show_locked(id: String) -> void:
	var button := _stop_button(id)
	if button:
		_shake(button)
	var data := _stop_data(id)
	var before: Dictionary = {}
	for i in range(1, STOPS.size()):
		if STOPS[i]["id"] == id:
			before = STOPS[i - 1]
	if str(data.get("chapter", "")).is_empty():
		_notice_title.text = "Coming soon!"
		_notice_body.text = "This part of the path is still ahead. New stories will be waiting here."
		_notice_action = Callable()
		_notice_go.visible = false
	else:
		_notice_title.text = "Not yet!"
		_notice_body.text = "Finish Chapter %d, %s, first.\nThen %s will open for you." % [before["number"], before["title"], data["title"]]
		_notice_go.visible = true
		var in_that_story: bool = not _choosing and Profiles.current_chapter == before["chapter"]
		_notice_go.text = "Back to my story" if in_that_story else "Play Chapter %d" % before["number"]
		_notice_action = close if in_that_story else _on_stop.bind(before["id"])
	_notice.visible = true
	_notice_card.pivot_offset = _notice_card.size * 0.5
	_notice_card.scale = Vector2(0.7, 0.7)
	_notice_card.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_notice_card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_notice_card, "modulate:a", 1.0, 0.2)
	(_notice_go if _notice_go.visible else _notice_ok).grab_focus()
	_say(_notice_body.text.replace("\n", " "), false)


func _hide_notice() -> void:
	if not _notice.visible:
		return
	_notice.visible = false
	if _audio:
		_audio.stop_speech()
	var focus := _stop_button(_marker_stop)
	if focus:
		focus.grab_focus()
	elif _back.visible:
		_back.grab_focus()


func _shake(control: Control) -> void:
	var home := control.position
	var tw := create_tween()
	for dx in [-10.0, 9.0, -6.0, 4.0, 0.0]:
		tw.tween_property(control, "position:x", home.x + dx, 0.05)


func _say(text: String, show_on_map: bool = true) -> void:
	if show_on_map:
		_line.text = text
	if _audio:
		_audio.stop_speech()
		_audio.speak_dialogue(_wonder_light(text))


## A block of lines in Wonder Light's voice, for AudioDirector.speak_dialogue().
static func _wonder_light(text: String) -> String:
	var lines: PackedStringArray = []
	for line in text.split("\n", false):
		lines.append("Wonder Light: \"%s\"" % line)
	return "\n".join(lines)


## Chapter 1. When the map is the first stop the valley is already waiting behind it, so it
## simply begins; otherwise the scene is loaded fresh so the valley starts from its first line.
func _play_valley() -> void:
	var director := get_parent().get_node_or_null("ChapterDirector")
	if _choosing and director and director.has_method("begin_valley"):
		close()
		director.begin_valley()
		return
	Profiles.current_chapter = Profiles.CHAPTER_VALLEY
	get_tree().paused = false
	_paused_by_me = false
	if _audio and _audio.has_method("stop_speech"):
		_audio.stop_speech()
	for action in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)
	get_tree().reload_current_scene()


func _on_change_player() -> void:
	var menu := get_parent().get_node_or_null("GameMenu")
	if menu and menu.has_method("change_player_and_restart"):
		visible = false
		_paused_by_me = false
		menu.change_player_and_restart()
