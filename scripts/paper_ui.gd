extends RefCounted
## The paper-and-ink look shared by the pause menu, the "Who is playing?" screen and the Faith Journal.
## Use through a preload constant (no class_name):
##   const PaperUI := preload("res://scripts/paper_ui.gd")

const PAPER := Color(0.98, 0.94, 0.83)
const PAPER_DEEP := Color(0.96, 0.88, 0.68)
const INK := Color(0.35, 0.2, 0.08)
const INK_SOFT := Color(0.6, 0.46, 0.32)
const GOLD := Color(0.98, 0.78, 0.25)


static func panel_style(margin: int = 22, radius: int = 24) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER
	sb.border_color = INK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 10
	return sb


## A smaller card sitting on a panel (a verse, a name field).
static func card_style(fill: Color = PAPER_DEEP) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = INK
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(14)
	return sb


static func button(text: String, min_size: Vector2 = Vector2(320.0, 62.0), font_size: int = 26, fill: Color = GOLD) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	# Every state in ink, including hover on a toggled-on button, whose default is white.
	for color_name in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(color_name, INK)
	var normal := StyleBoxFlat.new()
	normal.bg_color = fill
	normal.border_color = INK
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(18)
	b.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = fill.lightened(0.18)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", hover)
	var press := normal.duplicate() as StyleBoxFlat
	press.bg_color = fill.darkened(0.12)
	b.add_theme_stylebox_override("pressed", press)
	return b


static func label(text: String, size: int, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", INK)
	l.horizontal_alignment = align
	return l
