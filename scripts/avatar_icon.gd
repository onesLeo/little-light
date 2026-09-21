extends Control
## A small paper-craft picture drawn in code: a child's profile picture, a charm, or an empty
## "?" slot. Use through a preload constant:
##   const AvatarIcon := preload("res://scripts/avatar_icon.gd")
##   var pic := AvatarIcon.new("lamb", 96.0)
##
## Kinds: the names in Profiles.AVATAR_KINDS, "charm" (a gold disc on a ring), "mystery" (a "?") and "plus".

const INK := Color(0.35, 0.2, 0.08)
const CREAM := Color(0.99, 0.96, 0.87)

## Disc colour behind each picture.
const DISC := {
	"lamb": Color(0.62, 0.8, 0.55),
	"star": Color(0.55, 0.75, 0.9),
	"sun": Color(0.98, 0.85, 0.5),
	"cloud": Color(0.6, 0.8, 0.95),
	"heart": Color(0.98, 0.8, 0.8),
	"olive": Color(0.9, 0.85, 0.6),
}

var kind: String = "lamb"
var tint: Color = Color(0.95, 0.78, 0.35)


func _init(icon_kind: String = "lamb", side: float = 96.0) -> void:
	kind = icon_kind
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 3.0
	match kind:
		"mystery":
			_draw_mystery(c, r)
			return
		"charm":
			_draw_charm(c, r)
			return
		"plus":
			_draw_plus(c, r)
			return
	draw_circle(c, r, DISC.get(kind, Color(0.9, 0.9, 0.8)))
	draw_arc(c, r, 0.0, TAU, 48, INK, 3.0)
	match kind:
		"lamb":
			_draw_lamb(c, r)
		"star":
			_draw_star(c, r * 0.68, Color(0.98, 0.85, 0.3))
		"sun":
			_draw_sun(c, r)
		"cloud":
			_draw_cloud(c, r)
		"heart":
			_draw_heart(c, r)
		"olive":
			_draw_olive(c, r)


func _dot(center: Vector2, radius: float, fill: Color) -> void:
	draw_circle(center, radius, fill)
	draw_arc(center, radius, 0.0, TAU, 24, INK, 2.0)


func _outlined(points: PackedVector2Array, fill: Color) -> void:
	draw_colored_polygon(points, fill)
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, INK, 2.5)


func _draw_lamb(c: Vector2, r: float) -> void:
	for i in 7:
		var a := TAU * i / 7.0 - PI / 2.0
		_dot(c + Vector2(cos(a), sin(a)) * r * 0.36 + Vector2(0.0, -r * 0.04), r * 0.26, CREAM)
	_dot(c + Vector2(0.0, r * 0.05), r * 0.36, Color(0.78, 0.6, 0.42))
	_dot(c + Vector2(-r * 0.4, -r * 0.02), r * 0.12, Color(0.78, 0.6, 0.42))
	_dot(c + Vector2(r * 0.4, -r * 0.02), r * 0.12, Color(0.78, 0.6, 0.42))
	draw_circle(c + Vector2(-r * 0.13, 0.0), r * 0.05, INK)
	draw_circle(c + Vector2(r * 0.13, 0.0), r * 0.05, INK)
	draw_arc(c + Vector2(0.0, r * 0.1), r * 0.1, 0.3, PI - 0.3, 8, INK, 2.0)


func _draw_star(c: Vector2, r: float, fill: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + PI * i / 5.0
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	_outlined(pts, fill)


func _draw_sun(c: Vector2, r: float) -> void:
	for i in 8:
		var a := TAU * i / 8.0
		draw_line(c + Vector2(cos(a), sin(a)) * r * 0.5, c + Vector2(cos(a), sin(a)) * r * 0.8, INK, 4.0)
	_dot(c, r * 0.38, Color(0.98, 0.65, 0.2))


func _draw_cloud(c: Vector2, r: float) -> void:
	_dot(c + Vector2(-r * 0.3, r * 0.08), r * 0.26, Color.WHITE)
	_dot(c + Vector2(r * 0.3, r * 0.1), r * 0.24, Color.WHITE)
	_dot(c + Vector2(0.0, -r * 0.1), r * 0.34, Color.WHITE)
	draw_rect(Rect2(c + Vector2(-r * 0.32, r * 0.1), Vector2(r * 0.64, r * 0.24)), Color.WHITE)


func _draw_heart(c: Vector2, r: float) -> void:
	var red := Color(0.9, 0.35, 0.35)
	var pts := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		var x := 16.0 * pow(sin(t), 3.0)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(c + Vector2(x, y) * r * 0.034 + Vector2(0.0, r * 0.02))
	_outlined(pts, red)


func _draw_olive(c: Vector2, r: float) -> void:
	draw_line(c + Vector2(-r * 0.5, r * 0.45), c + Vector2(r * 0.45, -r * 0.45), INK, 4.0)
	for i in 3:
		var p := c + Vector2(-r * 0.3 + i * r * 0.28, r * 0.3 - i * r * 0.28)
		_leaf(p, Vector2(-0.6, -0.8), r * 0.3)
		_leaf(p, Vector2(0.8, 0.6), r * 0.3)


func _leaf(from: Vector2, dir: Vector2, length: float) -> void:
	var d := dir.normalized()
	var side := Vector2(-d.y, d.x) * length * 0.32
	var tip := from + d * length
	_outlined(PackedVector2Array([from, from + d * length * 0.5 + side, tip, from + d * length * 0.5 - side]), Color(0.45, 0.62, 0.3))


func _draw_charm(c: Vector2, r: float) -> void:
	draw_arc(c, r * 0.95, 0.0, TAU, 48, Color(0.82, 0.62, 0.28), 6.0)
	draw_arc(c, r * 0.95, 0.0, TAU, 48, INK, 2.0)
	_dot(c, r * 0.6, tint)
	draw_arc(c, r * 0.45, PI * 1.1, PI * 1.6, 12, Color(1.0, 0.95, 0.75), 4.0)


func _draw_dashed_ring(c: Vector2, r: float, color: Color) -> void:
	for i in 14:
		var a := TAU * i / 14.0
		draw_arc(c, r * 0.9, a, a + TAU / 28.0, 4, color, 3.0)


func _draw_plus(c: Vector2, r: float) -> void:
	var color := Color(0.7, 0.58, 0.45)
	_draw_dashed_ring(c, r, color)
	draw_line(c + Vector2(-r * 0.35, 0.0), c + Vector2(r * 0.35, 0.0), color, 8.0)
	draw_line(c + Vector2(0.0, -r * 0.35), c + Vector2(0.0, r * 0.35), color, 8.0)


func _draw_mystery(c: Vector2, r: float) -> void:
	var color := Color(0.7, 0.58, 0.45)
	_draw_dashed_ring(c, r, color)
	var font := ThemeDB.fallback_font
	var font_size := int(r * 1.1)
	var text_size := font.get_string_size("?", HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
	draw_string(font, c + Vector2(-text_size.x * 0.5, text_size.y * 0.3), "?", HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, color)
