extends Control
## Noah's Ark, inked onto the Faith Journey map in the same hand as the valley and the
## camp: sepia lines, a pale wash, a little hatching, on its own low hill with a faint
## rainbow behind it and a dotted trail back to the camp.
##
## Everything is drawn in the map picture's own pixels (1792 x 1008) and scaled with
## the map, so it stays where it belongs at any window size.

const MAP_WIDTH := 1792.0
const MAP_HEIGHT := 1008.0
## The middle of the ark's deck, in map pixels: the open ground left of the camp,
## under the mountains.
const CENTER := Vector2(620.0, 355.0)
## Where the map's stop sits, as a fraction of the picture: the foot of the hull, so the
## label hangs below the hill and the ark itself stays in view.
const ANCHOR := Vector2(CENTER.x / MAP_WIDTH, (CENTER.y + 34.0) / MAP_HEIGHT)

const INK := Color(0.29, 0.19, 0.08)
const INK_SOFT := Color(0.29, 0.19, 0.08, 0.55)
const TRAIL := Color(0.54, 0.4, 0.2, 0.9)
const HILL := Color(0.86, 0.76, 0.57, 0.6)
const WOOD := Color(0.8, 0.66, 0.46, 0.82)
const WOOD_SHADE := Color(0.72, 0.57, 0.37, 0.55)
const CABIN := Color(0.95, 0.88, 0.72, 0.9)
const ROOF := Color(0.74, 0.58, 0.37, 0.85)
const DOOR := Color(0.4, 0.27, 0.13, 0.85)
const RAINBOW := [Color(0.85, 0.42, 0.33, 0.2), Color(0.93, 0.74, 0.35, 0.2), Color(0.55, 0.7, 0.42, 0.2), Color(0.45, 0.6, 0.75, 0.2)]

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
	rng.seed = 7
	_rainbow()
	_trail()
	_hill(rng)
	_ramp()
	_hull(rng)
	_cabin(rng)
	_animals()
	draw_set_transform(Vector2.ZERO)


func _rainbow() -> void:
	var r := 136.0
	for band in RAINBOW:
		draw_arc(Vector2(0.0, 40.0), r, PI + 0.12, TAU - 0.12, 48, band, 7.0, true)
		r -= 7.0


## Dashes from the camp's hill to the foot of the ark's hill, like the footprints on the map.
func _trail() -> void:
	var from := Vector2(870.0, 505.0) - CENTER
	var bend := Vector2(820.0, 470.0) - CENTER
	var to := Vector2(150.0, 48.0)
	var steps := 16
	for i in steps:
		if i % 2 == 1:
			continue
		var a := _bezier(from, bend, to, float(i) / steps)
		var b := _bezier(from, bend, to, (i + 0.8) / steps)
		draw_line(a, b, TRAIL, 3.0, true)


func _hill(rng: RandomNumberGenerator) -> void:
	var ridge := PackedVector2Array()
	for i in 21:
		var x := lerpf(-160.0, 160.0, i / 20.0)
		ridge.append(Vector2(x, _ridge_y(x) + rng.randf_range(-1.5, 1.5)))
	# The wash fades out downhill instead of stopping on a hard edge.
	var ground := ridge.duplicate()
	var shades := PackedColorArray()
	for p in ridge:
		shades.append(HILL)
	for i in 21:
		var x := lerpf(160.0, -160.0, i / 20.0)
		ground.append(Vector2(x, 68.0 + 14.0 * (1.0 - pow(x / 160.0, 2.0))))
		shades.append(Color(HILL, 0.0))
	draw_polygon(ground, shades)
	_wobbly(ridge, INK_SOFT, 2.0, rng)
	# Scratchy strokes down the slopes, as on the camp's hill.
	for i in 14:
		var x := lerpf(-140.0, 140.0, i / 13.0) + rng.randf_range(-4.0, 4.0)
		var top := _ridge_y(x) + rng.randf_range(4.0, 10.0)
		var lean := 5.0 if x < 0.0 else -5.0
		draw_line(Vector2(x, top), Vector2(x + lean, minf(top + rng.randf_range(8.0, 14.0), 68.0)), INK_SOFT, 1.2, true)


static func _ridge_y(x: float) -> float:
	return 68.0 - 40.0 * (1.0 - pow(x / 160.0, 2.0))


func _ramp() -> void:
	var top_a := Vector2(-90.0, 8.0)
	var top_b := Vector2(-78.0, 14.0)
	var foot_a := Vector2(-146.0, 50.0)
	var foot_b := Vector2(-132.0, 56.0)
	draw_colored_polygon(PackedVector2Array([top_a, top_b, foot_b, foot_a]), WOOD)
	draw_line(top_a, foot_a, INK, 2.0, true)
	draw_line(top_b, foot_b, INK, 2.0, true)
	for i in range(1, 5):
		var t := i / 5.0
		draw_line(top_a.lerp(foot_a, t), top_b.lerp(foot_b, t), INK_SOFT, 1.3, true)


const BOW := Vector2(-128.0, -30.0)
const STERN := Vector2(126.0, -28.0)


## The keel, from the stern round under the hull to the bow.
static func _keel(t: float, depth: float = 44.0) -> Vector2:
	return STERN.bezier_interpolate(Vector2(108.0, depth), Vector2(-108.0, depth), BOW, t)


## The rail's height at `x`: level along the deck, rising towards the bow and the stern.
static func _rail_y(x: float) -> float:
	if absf(x) <= 80.0:
		return -6.0
	var end_y := BOW.y if x < 0.0 else STERN.y
	return lerpf(-6.0, end_y, clampf((absf(x) - 80.0) / 46.0, 0.0, 1.0))


## A point a fraction `p` of the way down the hull, from the rail to the keel.
static func _between(t: float, p: float) -> Vector2:
	var bottom := _keel(t)
	return Vector2(bottom.x, _rail_y(bottom.x)).lerp(bottom, p)


func _hull(rng: RandomNumberGenerator) -> void:
	# Gunwale: level along the deck, rising into a bow and a stern.
	var rail := PackedVector2Array()
	for i in 13:
		rail.append(_bezier(BOW, Vector2(-108.0, -6.0), Vector2(-80.0, -6.0), i / 12.0))
	for i in range(1, 13):
		rail.append(_bezier(Vector2(80.0, -6.0), Vector2(106.0, -6.0), STERN, i / 12.0))
	var body := rail.duplicate()
	for i in range(1, 24):
		body.append(_keel(i / 24.0))
	draw_colored_polygon(body, WOOD)
	# Shade the lower half of the hull, and let planks follow the curve of the keel.
	var shade := PackedVector2Array()
	for i in 25:
		shade.append(_keel(i / 24.0))
	for i in range(1, 24):
		shade.append(_between(1.0 - i / 24.0, 0.5))
	draw_colored_polygon(shade, WOOD_SHADE)
	for p in [0.3, 0.55, 0.8]:
		var plank := PackedVector2Array()
		for i in 21:
			plank.append(_between(i / 20.0, p))
		_wobbly(plank, INK_SOFT, 1.3, rng)
	# Hatching on the shaded stern side.
	for i in 7:
		var t := 0.06 + i * 0.035
		draw_line(_between(t, 0.5), _between(t + 0.01, 0.92), INK_SOFT, 1.1, true)
	var outline := body.duplicate()
	outline.append(body[0])
	_wobbly(outline, INK, 2.4, rng)


func _cabin(rng: RandomNumberGenerator) -> void:
	var walls := Rect2(-50.0, -44.0, 92.0, 38.0)
	draw_rect(walls, CABIN)
	for i in range(1, 8):
		var x := walls.position.x + i * 11.5
		draw_line(Vector2(x, -42.0), Vector2(x, -8.0), Color(INK_SOFT, 0.25), 1.0, true)
	_wobbly(PackedVector2Array([Vector2(-50.0, -6.0), Vector2(-50.0, -44.0), Vector2(42.0, -44.0), Vector2(42.0, -6.0)]), INK, 2.2, rng)
	draw_rect(Rect2(-8.0, -30.0, 16.0, 24.0), DOOR)
	draw_rect(Rect2(-8.0, -30.0, 16.0, 24.0), INK, false, 1.6)
	for x in [-38.0, 22.0]:
		draw_rect(Rect2(x, -36.0, 9.0, 8.0), DOOR)
		draw_rect(Rect2(x, -36.0, 9.0, 8.0), INK, false, 1.3)
	var eave_l := Vector2(-60.0, -42.0)
	var ridge := Vector2(-4.0, -68.0)
	var eave_r := Vector2(52.0, -42.0)
	draw_colored_polygon(PackedVector2Array([eave_l, ridge, eave_r]), ROOF)
	# Shingle hatching, sloping with each side of the roof.
	for i in range(1, 7):
		var t := i / 7.0
		var left := eave_l.lerp(ridge, t)
		var right := eave_r.lerp(ridge, t)
		var drop := 14.0 * (1.0 - t) + 3.0
		draw_line(left, left + Vector2(drop * 0.5, drop), INK_SOFT, 1.2, true)
		draw_line(right, right + Vector2(-drop * 0.5, drop), INK_SOFT, 1.2, true)
	_wobbly(PackedVector2Array([eave_l, ridge, eave_r, eave_l]), INK, 2.4, rng)


## Two sheep waiting by the ramp, the same little cloud as the one in the valley.
func _animals() -> void:
	for at in [Vector2(-168.0, 46.0), Vector2(-146.0, 52.0)]:
		for leg in [-5.0, 5.0]:
			draw_line(at + Vector2(leg, 4.0), at + Vector2(leg, 10.0), INK, 1.6, true)
		_ellipse(at, Vector2(11.0, 7.0), Color(0.98, 0.95, 0.88), INK)
		draw_circle(at + Vector2(-11.0, -2.0), 3.6, INK)


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


static func _bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	return a.lerp(b, t).lerp(b.lerp(c, t), t)


static func _cubic(a: Vector2, b: Vector2, c: Vector2, d: Vector2, t: float) -> Vector2:
	return a.bezier_interpolate(b, c, d, t)
