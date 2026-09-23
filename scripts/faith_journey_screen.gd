extends CanvasLayer
## The Faith Journey: an old paper map of the stories, not a blank page of icons.
## The valley, the river and the mountains are the picture. Each story is a small
## label sitting on its place. Opened from the end of a chapter, or from the journal,
## once chapter 1 has been finished. Chapter 2 is drawn, and not playable yet.

signal closed

const Profiles := preload("res://scripts/profiles.gd")
const PaperUI := preload("res://scripts/paper_ui.gd")

const MAP_PATH := "res://assets/ui/faith_journey_map.jpg"
const MAP_ASPECT := 16.0 / 9.0

## Where each story sits on the map, as a fraction of the picture.
const STOPS := [
	{"id": "valley", "title": "The valley", "at": Vector2(0.30, 0.76)},
	{"id": "camp", "title": "The King's Camp", "at": Vector2(0.545, 0.48)},
	{"id": "ahead", "title": "", "at": Vector2(0.80, 0.30)},
]

var _audio: Node
var _paused_by_me: bool = false
var _map: TextureRect
var _line: Label
var _back: Button
var _stops: Array = []


func _ready() -> void:
	layer = 14
	process_mode = Node.PROCESS_MODE_ALWAYS
	_audio = get_parent().get_node_or_null("%AudioDirector")
	_build()
	visible = false
	get_viewport().size_changed.connect(_layout)


func is_open() -> bool:
	return visible


func open() -> void:
	_line.text = "One story at a time."
	visible = true
	if not get_tree().paused:
		get_tree().paused = true
		_paused_by_me = true
	if _audio:
		_audio.stop_speech()
		_audio.process_mode = Node.PROCESS_MODE_ALWAYS
		_audio.speak_dialogue("Wonder Light: \"One story at a time.\"")
	_layout()
	_back.grab_focus()


func close() -> void:
	if not visible:
		return
	if _audio:
		_audio.stop_speech()
		_audio.process_mode = Node.PROCESS_MODE_INHERIT
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

	var title := PaperUI.label("Faith Journey", 40)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_top = 18.0
	title.offset_bottom = 70.0
	title.offset_left = -280.0
	title.offset_right = 280.0
	add_child(title)

	for stop in STOPS:
		var button := PaperUI.button(stop["title"] if stop["title"] != "" else "·", Vector2(210.0, 54.0), 22, PaperUI.PAPER)
		button.set_anchors_preset(Control.PRESET_TOP_LEFT)
		button.pressed.connect(_on_stop.bind(stop["id"]))
		add_child(button)
		_stops.append({"id": stop["id"], "at": stop["at"], "button": button})

	_line = PaperUI.label("One story at a time.", 24)
	_line.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_line.offset_left = -420.0
	_line.offset_right = 420.0
	_line.offset_top = -132.0
	_line.offset_bottom = -88.0
	add_child(_line)

	_back = PaperUI.button("Back", Vector2(200.0, 58.0), 26)
	_back.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_back.offset_left = -100.0
	_back.offset_right = 100.0
	_back.offset_top = -80.0
	_back.offset_bottom = -22.0
	_back.pressed.connect(close)
	add_child(_back)


func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	if view.x < 1.0 or view.y < 1.0:
		return
	var fitted := _fitted_map(view)
	for stop in _stops:
		var at: Vector2 = stop["at"]
		var button: Button = stop["button"]
		var point := fitted.position + Vector2(fitted.size.x * at.x, fitted.size.y * at.y)
		button.position = point - button.custom_minimum_size * 0.5 + Vector2(0.0, 28.0)


func _fitted_map(view: Vector2) -> Rect2:
	var view_aspect := view.x / view.y
	if view_aspect > MAP_ASPECT:
		var h := view.y
		var w := h * MAP_ASPECT
		return Rect2((view.x - w) * 0.5, 0.0, w, h)
	var w := view.x
	var h := w / MAP_ASPECT
	return Rect2(0.0, (view.y - h) * 0.5, w, h)


func _on_stop(id: String) -> void:
	if id == "valley":
		_replay_valley()
	elif id == "camp":
		var camp := get_parent().get_node_or_null("KingsCamp")
		if camp and camp.has_method("visit"):
			close()
			camp.visit()
		else:
			_say("The King's Camp is still being prepared.")
	else:
		_say("This part of the path is still ahead.")


func _say(text: String) -> void:
	_line.text = text
	if _audio:
		_audio.speak_dialogue("Wonder Light: \"%s\"" % text)


func _replay_valley() -> void:
	get_tree().paused = false
	_paused_by_me = false
	if _audio and _audio.has_method("stop_speech"):
		_audio.stop_speech()
	for action in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)
	get_tree().reload_current_scene()
