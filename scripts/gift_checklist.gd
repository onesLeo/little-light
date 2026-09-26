extends PanelContainer
## A hunt list in pictures a child who cannot read yet can follow: "Gifts for David" in
## chapter 2, "Getting ready for Samuel" in chapter 3, "Tools for Noah" in chapter 4. Each thing has its own small drawing, faded
## with a dashed circle until it is found, then in full colour with a green tick that
## pops in. The count sits in the title.
## Use through a preload constant (no class_name):
##   const GiftChecklist := preload("res://scripts/gift_checklist.gd")
##   GiftChecklist.new()   # Jonathan's gifts
##   GiftChecklist.new(["Mallet", "RopeCoil", "Pitch"], "Tools for Noah", {"RopeCoil": "Rope"})

const PaperUI := preload("res://scripts/paper_ui.gd")

const GIFTS := ["Robe", "Bow", "Belt"]
const ROW := Vector2(220.0, 58.0)

var _title: Label
var _rows: Dictionary = {}
var _found: Array = []
var _items: Array = GIFTS
var _heading: String = "Gifts for David"


## One line of the list: the picture, the word, and the tick circle.
class GiftRow extends Control:
	var gift: String
	var label: String
	var found: bool = false
	var pop: float = 0.0
	var _font: Font

	func _init(gift_name: String, shown_as: String = "") -> void:
		gift = gift_name
		label = shown_as if not shown_as.is_empty() else gift_name
		custom_minimum_size = ROW
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		_font = get_theme_default_font()

	func _process(delta: float) -> void:
		if pop > 0.0:
			pop = maxf(pop - delta * 2.5, 0.0)
			queue_redraw()

	func _draw() -> void:
		var fade := 1.0 if found else 0.5
		_draw_gift(Vector2(30.0, size.y * 0.5), fade)
		if _font:
			var ink := PaperUI.INK if found else PaperUI.INK_SOFT
			draw_string(_font, Vector2(66.0, size.y * 0.5 + 9.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 26, ink)
		var c := Vector2(size.x - 22.0, size.y * 0.5)
		if found:
			var r := 15.0 * (1.0 + 0.45 * sin(pop * PI))
			draw_circle(c, r, Color(0.36, 0.62, 0.26))
			draw_arc(c, r, 0.0, TAU, 24, PaperUI.INK, 2.5, true)
			draw_polyline(PackedVector2Array([c + Vector2(-7.0, 0.0), c + Vector2(-2.0, 5.5), c + Vector2(7.5, -5.5)]), Color.WHITE, 3.5, true)
		else:
			for i in 12:
				var a := TAU * i / 12.0
				draw_arc(c, 14.0, a, a + TAU / 24.0, 4, PaperUI.INK_SOFT, 2.5, true)

	## The same simple shapes as the things in the world (chapter_two.gd, noahs_ark.gd).
	func _draw_gift(c: Vector2, fade: float) -> void:
		var ink := Color(PaperUI.INK, fade)
		match gift:
			"Mallet":
				draw_line(c + Vector2(-20.0, 14.0), c + Vector2(8.0, -8.0), ink, 8.0, true)
				draw_line(c + Vector2(-20.0, 14.0), c + Vector2(8.0, -8.0), Color(0.72, 0.56, 0.38, fade), 5.0, true)
				var head := PackedVector2Array([c + Vector2(-2.0, -22.0), c + Vector2(22.0, -2.0), c + Vector2(14.0, 8.0), c + Vector2(-10.0, -12.0)])
				draw_colored_polygon(head, Color(0.55, 0.38, 0.24, fade))
				head.append(head[0])
				draw_polyline(head, ink, 2.5, true)
			"RopeCoil":
				for k in 3:
					draw_arc(c + Vector2(0.0, 6.0 - k * 6.0), 18.0 - k * 3.0, 0.0, TAU, 28, ink, 7.0, true)
					draw_arc(c + Vector2(0.0, 6.0 - k * 6.0), 18.0 - k * 3.0, 0.0, TAU, 28, Color(0.76, 0.62, 0.4, fade), 4.0, true)
			"Pitch":
				var jar := PackedVector2Array([c + Vector2(-12.0, -14.0), c + Vector2(12.0, -14.0), c + Vector2(17.0, 14.0), c + Vector2(-17.0, 14.0)])
				draw_colored_polygon(jar, Color(0.6, 0.42, 0.3, fade))
				jar.append(jar[0])
				draw_polyline(jar, ink, 2.5, true)
				draw_rect(Rect2(c + Vector2(-10.0, -20.0), Vector2(20.0, 6.0)), Color(0.14, 0.1, 0.08, fade))
				draw_rect(Rect2(c + Vector2(-10.0, -20.0), Vector2(20.0, 6.0)), ink, false, 2.0)
			"Robe":
				var robe := Rect2(c + Vector2(-22.0, -14.0), Vector2(44.0, 28.0))
				draw_rect(robe, Color(0.28, 0.42, 0.68, fade))
				draw_rect(Rect2(c + Vector2(-22.0, 6.0), Vector2(44.0, 8.0)), Color(0.86, 0.68, 0.28, fade))
				draw_line(c + Vector2(-22.0, -2.0), c + Vector2(22.0, -2.0), Color(0.2, 0.3, 0.5, fade), 2.0)
				draw_rect(robe, ink, false, 2.5)
			"Cushion":
				var cushion := PackedVector2Array([c + Vector2(-22.0, -6.0), c + Vector2(-14.0, -14.0), c + Vector2(14.0, -14.0),
						c + Vector2(22.0, -6.0), c + Vector2(20.0, 10.0), c + Vector2(-20.0, 10.0)])
				draw_colored_polygon(cushion, Color(0.62, 0.3, 0.3, fade))
				cushion.append(cushion[0])
				draw_polyline(cushion, ink, 2.5, true)
				draw_line(c + Vector2(-16.0, -2.0), c + Vector2(16.0, -2.0), Color(0.86, 0.68, 0.28, fade), 3.0, true)
			"Cup":
				var cup := PackedVector2Array([c + Vector2(-13.0, -14.0), c + Vector2(13.0, -14.0), c + Vector2(9.0, 14.0), c + Vector2(-9.0, 14.0)])
				draw_colored_polygon(cup, Color(0.7, 0.46, 0.26, fade))
				cup.append(cup[0])
				draw_polyline(cup, ink, 2.5, true)
				draw_line(c + Vector2(-11.0, -9.0), c + Vector2(11.0, -9.0), Color(0.55, 0.72, 0.9, fade), 3.0, true)
			"Lamp":
				var dish := PackedVector2Array([c + Vector2(-22.0, 2.0), c + Vector2(20.0, 2.0), c + Vector2(24.0, -3.0),
						c + Vector2(12.0, 14.0), c + Vector2(-14.0, 14.0)])
				draw_colored_polygon(dish, Color(0.74, 0.5, 0.26, fade))
				dish.append(dish[0])
				draw_polyline(dish, ink, 2.5, true)
				var flame := PackedVector2Array([c + Vector2(20.0, -20.0), c + Vector2(25.0, -8.0), c + Vector2(20.0, -2.0), c + Vector2(15.0, -8.0)])
				draw_colored_polygon(flame, Color(0.98, 0.76, 0.26, fade))
			"Bow":
				var hub := c + Vector2(-14.0, 0.0)
				var top := hub + Vector2(cos(-1.1), sin(-1.1)) * 24.0
				var bottom := hub + Vector2(cos(1.1), sin(1.1)) * 24.0
				draw_line(top, bottom, Color(0.55, 0.5, 0.42, fade), 2.0, true)
				draw_arc(hub, 24.0, -1.1, 1.1, 18, ink, 9.0, true)
				draw_arc(hub, 24.0, -1.1, 1.1, 18, Color(0.62, 0.38, 0.18, fade), 5.5, true)
			_:
				draw_arc(c, 17.0, 0.0, TAU, 28, Color(0.45, 0.27, 0.13, fade), 7.0, true)
				draw_arc(c, 21.0, 0.0, TAU, 28, ink, 1.5, true)
				draw_rect(Rect2(c + Vector2(-6.0, 11.0), Vector2(12.0, 12.0)), Color(0.86, 0.68, 0.28, fade))
				draw_rect(Rect2(c + Vector2(-6.0, 11.0), Vector2(12.0, 12.0)), ink, false, 2.0)


func _init(items: Array = GIFTS, heading: String = "Gifts for David", labels: Dictionary = {}) -> void:
	_items = items
	_heading = heading
	name = "CampGiftChecklist"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", PaperUI.panel_style(16, 18))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	add_child(column)
	_title = PaperUI.label("", 23, HORIZONTAL_ALIGNMENT_LEFT)
	column.add_child(_title)
	for gift in _items:
		var row := GiftRow.new(gift, str(labels.get(gift, "")))
		column.add_child(row)
		_rows[gift] = row
	set_found([])


## Ticks the gifts in `names`; a gift ticked just now pops its tick.
func set_found(names: Array) -> void:
	for gift in _items:
		var row: GiftRow = _rows[gift]
		var now: bool = gift in names
		if now and not row.found:
			row.pop = 1.0
		row.found = now
		row.queue_redraw()
	_found = names.duplicate()
	_title.text = "%s  %d / %d" % [_heading, _found.size(), _items.size()]


func is_found(gift: String) -> bool:
	return (_rows[gift] as GiftRow).found
