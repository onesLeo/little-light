extends Control
## Jesse's home in Bethlehem, inked onto the Faith Journey map in the same hand as the ark:
## a low limestone house with a flat roof and a cloth awning, an olive tree, a little sheep
## fold with two sheep, on a low hill. The dotted trail from the camp curls back on itself
## like a page being turned, because The Beginning looks back to an earlier day.
##
## Everything is drawn in the map picture's own pixels (1792 x 1008) and scaled with the map,
## so it stays where it belongs at any window size (see map_ark_sketch.gd).

const MAP_WIDTH := 1792.0
const MAP_HEIGHT := 1008.0
## The middle of the courtyard, in map pixels: the open plain below and right of the camp.
const CENTER := Vector2(1330.0, 590.0)
## Where the map's stop sits, as a fraction of the picture: at the end of the sheep path, well
## below the house, so the "Next story" tag over the stop leaves the house in view.
const ANCHOR := Vector2(CENTER.x / MAP_WIDTH, (CENTER.y + LANE_END.y) / MAP_HEIGHT)
## Where the sheep path from the doorway ends, relative to CENTER: the stop.
const LANE_END := Vector2(0.0, 150.0)

const INK := Color(0.29, 0.19, 0.08)
const INK_SOFT := Color(0.29, 0.19, 0.08, 0.55)
const TRAIL := Color(0.54, 0.4, 0.2, 0.9)
const HILL := Color(0.86, 0.76, 0.57, 0.6)
const LIMESTONE := Color(0.95, 0.9, 0.78, 0.92)
const LIMESTONE_SHADE := Color(0.84, 0.76, 0.6, 0.8)
const DOOR := Color(0.4, 0.27, 0.13, 0.85)
const AWNING := Color(0.8, 0.5, 0.42, 0.8)
const OLIVE := Color(0.6, 0.66, 0.42, 0.75)
const WOOD := Color(0.62, 0.46, 0.28, 0.9)

var _map_rect := Rect2()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Where the map picture sits on screen; the sketch follows it.
func fit(map_rect: Rect2) -> void:
	_map_rect = map_rect
	queue_redraw()


func _draw() -> void:
	if _map_rect.size.x < 1.0:
		return
	var k := _map_rect.size.x / MAP_WIDTH
	draw_set_transform(_map_rect.position + CENTER * k, 0.0, Vector2(k, k))
	# The same wobble every frame, so the lines look drawn by hand but never shimmer.
	var rng := RandomNumberGenerator.new()
	rng.seed = 16
	_trail()
	_lane()
	_hill(rng)
	_olive_tree(rng)
	_house(rng)
	_fold(rng)
	_sheep()
	draw_set_transform(Vector2.ZERO)


## Dashes from the camp's hill that curl round like a turning page before reaching the house.
func _trail() -> void:
	var from := Vector2(1100.0, 522.0) - CENTER
	var c1 := Vector2(1330.0, 505.0) - CENTER
	var c2 := Vector2(1450.0, 640.0) - CENTER
	var to := Vector2(-96.0, 30.0)
	var steps := 22
	for i in steps:
		if i % 2 == 1:
			continue
		var a := from.bezier_interpolate(c1, c2, to, float(i) / steps)
		var b := from.bezier_interpolate(c1, c2, to, (i + 0.8) / steps)
		draw_line(a, b, TRAIL, 3.0, true)


## The worn sheep path from the courtyard down to the stop, as dashes like the trail's.
func _lane() -> void:
	var from := Vector2(-42.0, 34.0)
	var bend := Vector2(-40.0, 110.0)
	var steps := 8
	for i in steps:
		if i % 2 == 1:
			continue
		var a := from.lerp(bend, float(i) / steps).lerp(bend.lerp(LANE_END, float(i) / steps), float(i) / steps)
		var t2 := (i + 0.8) / steps
		var b := from.lerp(bend, t2).lerp(bend.lerp(LANE_END, t2), t2)
		draw_line(a, b, TRAIL, 3.0, true)


func _hill(rng: RandomNumberGenerator) -> void:
	var ridge := PackedVector2Array()
	for i in 21:
		var x := lerpf(-170.0, 170.0, i / 20.0)
		ridge.append(Vector2(x, _ridge_y(x) + rng.randf_range(-1.5, 1.5)))
	var ground := ridge.duplicate()
	var shades := PackedColorArray()
	for p in ridge:
		shades.append(HILL)
	for i in 21:
		var x := lerpf(170.0, -170.0, i / 20.0)
		ground.append(Vector2(x, 70.0 + 12.0 * (1.0 - pow(x / 170.0, 2.0))))
		shades.append(Color(HILL, 0.0))
	draw_polygon(ground, shades)
	_wobbly(ridge, INK_SOFT, 2.0, rng)
	for i in 12:
		var x := lerpf(-150.0, 150.0, i / 11.0) + rng.randf_range(-4.0, 4.0)
		var top := _ridge_y(x) + rng.randf_range(4.0, 10.0)
		var lean := 5.0 if x < 0.0 else -5.0
		draw_line(Vector2(x, top), Vector2(x + lean, minf(top + rng.randf_range(8.0, 14.0), 70.0)), INK_SOFT, 1.2, true)


static func _ridge_y(x: float) -> float:
	return 70.0 - 34.0 * (1.0 - pow(x / 170.0, 2.0))


## A plain family house: one limestone block with a flat roof, a dark doorway and small windows,
## and a cloth awning on poles. Not a palace.
func _house(rng: RandomNumberGenerator) -> void:
	var walls := Rect2(-104.0, -30.0, 96.0, 58.0)
	draw_rect(walls, LIMESTONE)
	# The shaded side wall, for depth.
	draw_colored_polygon(PackedVector2Array([Vector2(-104.0, -30.0), Vector2(-118.0, -38.0), Vector2(-118.0, 20.0), Vector2(-104.0, 28.0)]), LIMESTONE_SHADE)
	# Stone courses.
	for y in [-14.0, 2.0, 16.0]:
		draw_line(Vector2(-102.0, y), Vector2(-10.0, y + rng.randf_range(-1.0, 1.0)), Color(INK_SOFT, 0.35), 1.0, true)
	# Flat roof with a low parapet.
	draw_rect(Rect2(-108.0, -36.0, 104.0, 7.0), LIMESTONE_SHADE)
	_wobbly(PackedVector2Array([Vector2(-104.0, 28.0), Vector2(-104.0, -30.0), Vector2(-8.0, -30.0), Vector2(-8.0, 28.0)]), INK, 2.2, rng)
	_wobbly(PackedVector2Array([Vector2(-118.0, 20.0), Vector2(-118.0, -38.0), Vector2(-104.0, -30.0)]), INK, 1.8, rng)
	_wobbly(PackedVector2Array([Vector2(-108.0, -29.0), Vector2(-108.0, -36.0), Vector2(-4.0, -36.0), Vector2(-4.0, -29.0)]), INK, 1.8, rng)
	draw_rect(Rect2(-50.0, -6.0, 16.0, 34.0), DOOR)
	draw_rect(Rect2(-50.0, -6.0, 16.0, 34.0), INK, false, 1.6)
	for x in [-90.0, -22.0]:
		draw_rect(Rect2(x, -18.0, 9.0, 8.0), DOOR)
		draw_rect(Rect2(x, -18.0, 9.0, 8.0), INK, false, 1.3)
	# The awning: a cloth sloping out from the wall on two poles, shading the doorway.
	var awning := PackedVector2Array([Vector2(-66.0, -10.0), Vector2(-14.0, -10.0), Vector2(-4.0, 6.0), Vector2(-60.0, 6.0)])
	draw_colored_polygon(awning, AWNING)
	awning.append(awning[0])
	_wobbly(awning, INK, 1.8, rng)
	for x in [-58.0, -6.0]:
		draw_line(Vector2(x, 6.0), Vector2(x, 28.0), INK, 1.6, true)


## An olive tree beside the house: a crooked trunk and a soft, scribbled crown.
func _olive_tree(rng: RandomNumberGenerator) -> void:
	var trunk := PackedVector2Array([Vector2(26.0, 30.0), Vector2(24.0, 10.0), Vector2(30.0, -8.0), Vector2(26.0, -22.0)])
	_wobbly(trunk, INK, 3.0, rng)
	for blob in [Vector3(12.0, -30.0, 18.0), Vector3(34.0, -38.0, 20.0), Vector3(50.0, -26.0, 16.0), Vector3(28.0, -20.0, 16.0)]:
		_ellipse(Vector2(blob.x, blob.y), Vector2(blob.z, blob.z * 0.72), OLIVE, INK_SOFT)


## The sheep fold: a low fence of posts and two rails, open towards the path David comes home by.
func _fold(rng: RandomNumberGenerator) -> void:
	var posts := [Vector2(62.0, 26.0), Vector2(86.0, 20.0), Vector2(110.0, 22.0), Vector2(134.0, 30.0), Vector2(150.0, 44.0)]
	for p in posts:
		draw_line(p, p + Vector2(0.0, 18.0), WOOD, 2.4, true)
		draw_line(p, p + Vector2(0.0, 18.0), INK, 1.2, true)
	for drop in [5.0, 12.0]:
		var rail := PackedVector2Array()
		for p in posts:
			rail.append(p + Vector2(0.0, drop))
		_wobbly(rail, INK, 1.4, rng)


## Two sheep in the fold, the same little cloud as the ones by the ark.
func _sheep() -> void:
	for at in [Vector2(96.0, 46.0), Vector2(122.0, 52.0)]:
		for leg in [-5.0, 5.0]:
			draw_line(at + Vector2(leg, 4.0), at + Vector2(leg, 10.0), INK, 1.6, true)
		_ellipse(at, Vector2(11.0, 7.0), Color(0.98, 0.95, 0.88), INK)
		draw_circle(at + Vector2(11.0, -2.0), 3.6, INK)


func _ellipse(center: Vector2, radius: Vector2, fill: Color, ink: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	draw_polyline(pts, ink, 1.5, true)


## An ink line with a slight tremble, so it sits with the hand-drawn map.
func _wobbly(points: PackedVector2Array, color: Color, width: float, rng: RandomNumberGenerator) -> void:
	var shaken := PackedVector2Array()
	for p in points:
		shaken.append(p + Vector2(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.6)))
	draw_polyline(shaken, color, width, true)
