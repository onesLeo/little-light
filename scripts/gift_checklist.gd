extends PanelContainer
## "Gifts for David": the chapter 2 hunt list, in pictures a child who cannot read yet can follow.
## Each gift has its own small drawing (the folded blue robe, the bow, the belt with its gold
## square), faded with a dashed circle until it is found, then in full colour with a green tick
## that pops in. The count sits in the title.
## Use through a preload constant (no class_name):
##   const GiftChecklist := preload("res://scripts/gift_checklist.gd")

const PaperUI := preload("res://scripts/paper_ui.gd")

const GIFTS := ["Robe", "Bow", "Belt"]
const ROW := Vector2(220.0, 58.0)

var _title: Label
var _rows: Dictionary = {}
var _found: Array = []


## One line of the list: the picture, the word, and the tick circle.
class GiftRow extends Control:
	var gift: String
	var found: bool = false
	var pop: float = 0.0
	var _font: Font

	func _init(gift_name: String) -> void:
		gift = gift_name
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
			draw_string(_font, Vector2(66.0, size.y * 0.5 + 9.0), gift, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 26, ink)
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

	## The same simple shapes as the gifts in the camp (chapter_two.gd).
	func _draw_gift(c: Vector2, fade: float) -> void:
		var ink := Color(PaperUI.INK, fade)
		match gift:
			"Robe":
				var robe := Rect2(c + Vector2(-22.0, -14.0), Vector2(44.0, 28.0))
				draw_rect(robe, Color(0.28, 0.42, 0.68, fade))
				draw_rect(Rect2(c + Vector2(-22.0, 6.0), Vector2(44.0, 8.0)), Color(0.86, 0.68, 0.28, fade))
				draw_line(c + Vector2(-22.0, -2.0), c + Vector2(22.0, -2.0), Color(0.2, 0.3, 0.5, fade), 2.0)
				draw_rect(robe, ink, false, 2.5)
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


func _init() -> void:
	name = "CampGiftChecklist"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", PaperUI.panel_style(16, 18))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	add_child(column)
	_title = PaperUI.label("", 23, HORIZONTAL_ALIGNMENT_LEFT)
	column.add_child(_title)
	for gift in GIFTS:
		var row := GiftRow.new(gift)
		column.add_child(row)
		_rows[gift] = row
	set_found([])


## Ticks the gifts in `names`; a gift ticked just now pops its tick.
func set_found(names: Array) -> void:
	for gift in GIFTS:
		var row: GiftRow = _rows[gift]
		var now: bool = gift in names
		if now and not row.found:
			row.pop = 1.0
		row.found = now
		row.queue_redraw()
	_found = names.duplicate()
	_title.text = "Gifts for David  %d / %d" % [_found.size(), GIFTS.size()]


func is_found(gift: String) -> bool:
	return (_rows[gift] as GiftRow).found
