extends Control
## Who is talking, for a child who cannot read yet.
##
## Sits over the story's dialogue bar (UI/Panel) and adds two things:
## - a name tag on the bar's top edge, with a small drawn face: Wonder Light's glow, David
##   (short brown hair, blue tunic), Jonathan (long hair, gold band, wine tunic), or an open
##   book for a Bible verse. It changes to whoever is being read aloud, with a little pop;
## - the same text, drawn with each speaker's name in their colour, stage directions softer,
##   and the line being read aloud in full ink while the others step back a little, so a
##   parent can point along.
##
## The story still writes to DialogueLabel as before (tests and easy words read it). This
## node reads that text and redraws it in a RichTextLabel laid exactly over the label, with
## the same font and wrapping; the label's own text is made invisible, so its size still
## decides the bar's height.
## Use through a preload constant (no class_name):
##   const DialogueView := preload("res://scripts/dialogue_view.gd")

const PaperUI := preload("res://scripts/paper_ui.gd")

const SPEAKERS := {
	"Wonder Light": {"fill": Color(0.98, 0.78, 0.25), "ink": Color(0.35, 0.2, 0.08), "text": Color(0.66, 0.4, 0.02)},
	"David": {"fill": Color(0.36, 0.55, 0.82), "ink": Color(1.0, 0.98, 0.92), "text": Color(0.18, 0.36, 0.66)},
	"Jonathan": {"fill": Color(0.62, 0.2, 0.28), "ink": Color(1.0, 0.95, 0.88), "text": Color(0.58, 0.14, 0.24)},
	"Noah": {"fill": Color(0.62, 0.32, 0.16), "ink": Color(1.0, 0.95, 0.86), "text": Color(0.45, 0.22, 0.08)},
	"Noah's wife": {"fill": Color(0.28, 0.55, 0.52), "ink": Color(1.0, 0.96, 0.9), "text": Color(0.12, 0.36, 0.34)},
	"Bible": {"fill": Color(0.52, 0.36, 0.2), "ink": Color(1.0, 0.95, 0.85), "text": Color(0.45, 0.28, 0.1)},
}
const VERSE_REFS := ["Joshua 1:9", "1 Samuel 18:1", "Genesis 9:13"]
const INK := Color(0.3, 0.17, 0.06)
const SOFT := Color(0.55, 0.42, 0.3)
## How far the lines not being read step back while one is read.
const RESTING_ALPHA := 0.62
const TAG_HEIGHT := 46.0
const FACE := 64.0

var panel: Control
var label: Label
var audio: Node

var speaker: String = ""
var _rich: RichTextLabel
var _tag: Control
var _shown_text: String = ""
var _lines: Array[Dictionary] = []   ## {"raw", "speaker", "spoken", "kind"}
var _current: int = -1
var _pop: float = 0.0
var _font: Font


func setup(dialogue_panel: Control, dialogue_label: Label, audio_director: Node) -> void:
	panel = dialogue_panel
	label = dialogue_label
	audio = audio_director


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_font = get_theme_default_font()
	if label == null:
		return
	_rich = RichTextLabel.new()
	_rich.name = "DialogueRich"
	_rich.bbcode_enabled = true
	_rich.scroll_active = false
	_rich.autowrap_mode = label.autowrap_mode
	_rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rich.set_anchors_preset(Control.PRESET_FULL_RECT)
	var size_px := label.get_theme_font_size("font_size")
	for key in ["normal_font_size", "bold_font_size"]:
		_rich.add_theme_font_size_override(key, size_px)
	_rich.add_theme_color_override("default_color", INK)
	_rich.add_theme_constant_override("line_separation", label.get_theme_constant("line_spacing"))
	label.add_child(_rich)
	# The label keeps its size (the bar is fitted to it), but its own glyphs are not drawn.
	label.self_modulate = Color(1, 1, 1, 0)
	_tag = Control.new()
	_tag.name = "SpeakerTag"
	_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tag.draw.connect(_draw_tag)
	add_child(_tag)
	if audio and audio.has_signal("line_started"):
		# A new line is usually spoken right after new text is shown: read the text first.
		audio.line_started.connect(func(_line: Dictionary) -> void: _sync(true))


func _process(delta: float) -> void:
	if label == null:
		return
	_sync(false)
	_pop = maxf(_pop - delta * 3.0, 0.0)
	_place_tag()
	_tag.queue_redraw()


## -- reading the block --------------------------------------------------------

## Re-reads the label when its text changed, and works out who is talking. `line_changed` is
## true when the voice has just moved on to another line.
func _sync(line_changed: bool) -> void:
	if label.text != _shown_text:
		_parse(label.text)
		_refresh_current()
	elif line_changed or (_current >= 0 and not _speaking()):
		_refresh_current()


func _parse(text: String) -> void:
	_shown_text = text
	_lines.clear()
	var who := ""
	for raw in text.split("\n"):
		var line := raw.strip_edges()
		var entry := {"raw": raw, "speaker": "", "spoken": "", "kind": "text", "name": ""}
		if line.is_empty():
			entry["kind"] = "blank"
		elif line.begins_with("("):
			entry["kind"] = "direction"
		else:
			var named := false
			for who_name in ["Wonder Light", "David", "Jonathan", "Noah's wife", "Noah"]:
				if line.begins_with(who_name + ":"):
					who = who_name
					named = true
					entry["name"] = who_name
					line = line.substr(who_name.length() + 1)
					break
			if not named:
				for ref in VERSE_REFS:
					if line.begins_with(ref):
						who = "Bible"
						entry["kind"] = "reference"
			entry["speaker"] = who
			entry["spoken"] = line.replace("\"", "").strip_edges()
		_lines.append(entry)


func _speaking() -> bool:
	return audio != null and audio.has_method("is_speaking") and audio.is_speaking()


## Which line is being read now, and so whose tag shows.
func _refresh_current() -> void:
	var now: Dictionary = audio.current_line if audio and "current_line" in audio and _speaking() else {}
	var found := -1
	if not now.is_empty():
		for i in _lines.size():
			if _lines[i]["spoken"] == now["text"] or (_lines[i]["kind"] == "reference" and now["speaker"] == "Reader"):
				found = i
				break
	_current = found
	var who := ""
	if found >= 0:
		who = _lines[found]["speaker"]
	elif _lines.any(func(l: Dictionary) -> bool: return l["speaker"] == speaker and speaker != ""):
		who = speaker   # read-aloud has finished: the last voice keeps the tag
	else:
		for l in _lines:
			if l["speaker"] != "":
				who = l["speaker"]
				break
	if who != speaker:
		speaker = who
		_pop = 1.0
	_rich.text = _bbcode()


func _bbcode() -> String:
	var out: PackedStringArray = []
	for i in _lines.size():
		var l: Dictionary = _lines[i]
		var alpha := 1.0 if _current < 0 or i == _current or l["kind"] == "blank" else RESTING_ALPHA
		var raw: String = l["raw"]
		match l["kind"]:
			"blank":
				out.append("")
			"direction":
				out.append(_colour(raw, SOFT, alpha))
			"reference":
				out.append(_colour(raw, SPEAKERS["Bible"]["text"], alpha))
			_:
				var who_name: String = l["name"]
				if who_name.is_empty():
					out.append(_colour(raw, INK, alpha))
				else:
					var at := raw.find(who_name + ":")
					var rest := raw.substr(at + who_name.length() + 1)
					out.append(_colour(raw.substr(0, at) + who_name + ":", SPEAKERS[who_name]["text"], alpha) + _colour(rest, INK, alpha))
	return "\n".join(out)


static func _colour(text: String, colour: Color, alpha: float) -> String:
	var c := Color(colour, colour.a * alpha)
	return "[color=#%s]%s[/color]" % [c.to_html(true), text.replace("[", "[lb]")]


## -- the name tag -------------------------------------------------------------

func _place_tag() -> void:
	var on := speaker != "" and panel != null and panel.is_visible_in_tree() and not label.text.strip_edges().is_empty()
	_tag.visible = on
	if not on:
		return
	var rect := panel.get_global_rect()
	var width := FACE + 12.0 + (_font.get_string_size(_tag_name(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24).x if _font else 120.0) + 20.0
	_tag.size = Vector2(width, FACE)
	# Sitting on the bar's top edge, clear of the first line of text.
	_tag.global_position = Vector2(rect.position.x + 18.0, rect.position.y - FACE + 6.0)


func _tag_name() -> String:
	return "Bible verse" if speaker == "Bible" else speaker


func _draw_tag() -> void:
	if not SPEAKERS.has(speaker):
		return
	var style: Dictionary = SPEAKERS[speaker]
	var grow := 1.0 + 0.18 * sin(_pop * PI)
	var r := FACE * 0.5
	var face_c := Vector2(r, r)
	# The name, on a pill running out from behind the face.
	var pill := Rect2(Vector2(r, r - TAG_HEIGHT * 0.5 + 6.0), Vector2(_tag.size.x - r, TAG_HEIGHT - 8.0))
	var sb := StyleBoxFlat.new()
	sb.bg_color = style["fill"]
	sb.border_color = PaperUI.INK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(18)
	_tag.draw_style_box(sb, pill)
	if _font:
		# The name starts after the face, so no letter hides behind it.
		_tag.draw_string(_font, Vector2(FACE + 10.0, pill.get_center().y + 8.0), _tag_name(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, style["ink"])
	# The face, in a paper circle.
	var fr := r * grow
	_tag.draw_circle(face_c, fr, Color(0.99, 0.95, 0.84))
	_draw_face(face_c, fr - 3.0)
	_tag.draw_arc(face_c, fr, 0.0, TAU, 40, PaperUI.INK, 3.0, true)


func _draw_face(c: Vector2, r: float) -> void:
	match speaker:
		"Wonder Light":
			for i in 4:
				_tag.draw_circle(c, r * (0.95 - i * 0.18), Color(1.0, 0.84, 0.3, 0.18 + i * 0.12))
			for i in 4:
				var a := TAU * i / 4.0 + PI * 0.25
				_tag.draw_line(c + Vector2(cos(a), sin(a)) * r * 0.3, c + Vector2(cos(a), sin(a)) * r * 0.8, Color(1.0, 0.95, 0.7, 0.9), 3.0, true)
			_tag.draw_circle(c, r * 0.3, Color(1.0, 0.99, 0.9))
		"David":
			_person(c, r, Color(0.36, 0.55, 0.82), Color(0.42, 0.26, 0.12), false)
		"Jonathan":
			_person(c, r, Color(0.62, 0.2, 0.28), Color(0.22, 0.13, 0.08), true)
		"Noah":
			_person(c, r, Color(0.62, 0.32, 0.16), Color(0.35, 0.28, 0.22), false)
			_tag.draw_circle(c + Vector2(0.0, r * 0.18), r * 0.26, Color(0.35, 0.28, 0.22))
		"Noah's wife":
			_person(c, r, Color(0.28, 0.55, 0.52), Color(0.25, 0.16, 0.1), false)
			_tag.draw_circle(c + Vector2(0.0, -r * 0.62), r * 0.16, Color(0.25, 0.16, 0.1))
		"Bible":
			for side in [-1.0, 1.0]:
				var page := PackedVector2Array([c + Vector2(side * 2.0, -r * 0.42), c + Vector2(side * r * 0.72, -r * 0.34),
						c + Vector2(side * r * 0.72, r * 0.4), c + Vector2(side * 2.0, r * 0.5)])
				_tag.draw_colored_polygon(page, Color(1.0, 0.98, 0.9))
				page.append(page[0])
				_tag.draw_polyline(page, PaperUI.INK, 2.5, true)
				for k in 3:
					var y := -r * 0.14 + k * r * 0.2
					_tag.draw_line(c + Vector2(side * r * 0.16, y), c + Vector2(side * r * 0.56, y + 1.0), SOFT, 1.5)


## A child's face in the paper style: tunic, face, hair, two eyes and a smile.
func _person(c: Vector2, r: float, tunic: Color, hair: Color, long_hair: bool) -> void:
	var shoulders := PackedVector2Array()
	for i in 13:
		var a := lerpf(0.2 * PI, 0.8 * PI, i / 12.0)
		shoulders.append(c + Vector2(cos(a), sin(a)) * r)
	shoulders.append(c + Vector2(-r * 0.5, r * 0.4))
	shoulders.append(c + Vector2(r * 0.5, r * 0.4))
	_tag.draw_colored_polygon(shoulders, tunic)
	var head := c + Vector2(0.0, -r * 0.08)
	if long_hair:
		_tag.draw_rect(Rect2(head + Vector2(-r * 0.5, -r * 0.2), Vector2(r, r * 0.72)), hair)
	_tag.draw_circle(head + Vector2(0.0, -r * 0.1), r * 0.5, hair)
	_tag.draw_circle(head + Vector2(0.0, r * 0.04), r * 0.4, Color(0.95, 0.78, 0.62))
	if long_hair:
		_tag.draw_line(head + Vector2(-r * 0.42, -r * 0.22), head + Vector2(r * 0.42, -r * 0.22), Color(0.95, 0.76, 0.3), 3.0, true)
	else:
		_tag.draw_rect(Rect2(head + Vector2(-r * 0.4, -r * 0.46), Vector2(r * 0.8, r * 0.2)), hair)
	for side in [-1.0, 1.0]:
		_tag.draw_circle(head + Vector2(side * r * 0.15, r * 0.02), r * 0.055, PaperUI.INK)
	_tag.draw_arc(head + Vector2(0.0, r * 0.12), r * 0.14, 0.2 * PI, 0.8 * PI, 10, PaperUI.INK, 2.0, true)
