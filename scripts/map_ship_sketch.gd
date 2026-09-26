extends Control
## Jonah's journey, inked onto the Faith Journey map in the same hand as the ark and Jesse's
## home: a stretch of sea in the map's lower right corner, a little quay on its shore, a ship
## with a square sail heading out, and the gentle curve of the great fish's back rising under
## the waves, with a dotted trail from the ark to the quay.
##
## Everything is drawn in the map picture's own pixels (1792 x 1008) and scaled with the map,
## so it stays where it belongs at any window size (see map_ark_sketch.gd).

const MAP_WIDTH := 1792.0
const MAP_HEIGHT := 1008.0
## The middle of the scene, in map pixels: the open plain's lower right corner.
const CENTER := Vector2(1540.0, 790.0)
## Where the map's stop sits: on the quay, so the tag above it leaves the ship and fish in view.
const ANCHOR := Vector2((CENTER.x - 120.0) / MAP_WIDTH, (CENTER.y + 40.0) / MAP_HEIGHT)

const INK := Color(0.29, 0.19, 0.08)
const INK_SOFT := Color(0.29, 0.19, 0.08, 0.55)
const TRAIL := Color(0.54, 0.4, 0.2, 0.9)
const SEA := Color(0.55, 0.72, 0.78, 0.45)
const SEA_DEEP := Color(0.42, 0.6, 0.7, 0.4)
const STONE := Color(0.9, 0.82, 0.66, 0.85)
const HULL := Color(0.78, 0.46, 0.34, 0.85)
const SAIL := Color(0.99, 0.95, 0.84, 0.95)
const FISH := Color(0.46, 0.58, 0.68, 0.7)

var _map_rect := Rect2()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func fit(map_rect: Rect2) -> void:
	_map_rect = map_rect
	queue_redraw()


func _draw() -> void:
	if _map_rect.size.x < 1.0:
		return
	var k := _map_rect.size.x / MAP_WIDTH
	draw_set_transform(_map_rect.position + CENTER * k, 0.0, Vector2(k, k))
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	_trail()
	_sea(rng)
	_fish(rng)
	_quay(rng)
	_ship(rng)
	draw_set_transform(Vector2.ZERO)


## Dashes from the foot of the ark's hill down across the plain to the quay.
func _trail() -> void:
	var from := Vector2(700.0, 420.0) - CENTER
	var bend := Vector2(1000.0, 800.0) - CENTER
	var to := Vector2(-150.0, 30.0)
	var steps := 34
	for i in steps:
		if i % 2 == 1:
			continue
		draw_line(_bezier(from, bend, to, float(i) / steps), _bezier(from, bend, to, (i + 0.8) / steps), TRAIL, 3.0, true)


## A pale wash of sea with a few long wave strokes, reaching to the map's edge.
func _sea(rng: RandomNumberGenerator) -> void:
	var shore := PackedVector2Array()
	for i in 17:
		var t := float(i) / 16.0
		shore.append(Vector2(lerpf(-110.0, 200.0, t), lerpf(40.0, -150.0, t) + sin(t * 9.0) * 8.0))
	var water := shore.duplicate()
	water.append(Vector2(200.0, 150.0))
	water.append(Vector2(-110.0, 150.0))
	draw_colored_polygon(water, SEA)
	var deeper := PackedVector2Array([Vector2(40.0, 10.0), Vector2(200.0, -80.0), Vector2(200.0, 150.0), Vector2(40.0, 150.0)])
	draw_colored_polygon(deeper, SEA_DEEP)
	_wobbly(shore, INK, 2.0, rng)
	for row in 5:
		var y := -60.0 + row * 34.0
		var x0 := -40.0 + row * 20.0
		var wave := PackedVector2Array()
		for i in 9:
			var t := float(i) / 8.0
			wave.append(Vector2(x0 + t * 110.0, y + sin(t * TAU * 1.5) * 4.0))
		_wobbly(wave, INK_SOFT, 1.4, rng)


## The fish's broad back rising under the waves, with its tail flukes: calm, not a monster.
func _fish(rng: RandomNumberGenerator) -> void:
	var back := PackedVector2Array()
	for i in 17:
		var t := float(i) / 16.0
		back.append(Vector2(lerpf(20.0, 170.0, t), 92.0 - sin(t * PI) * 34.0))
	var body := back.duplicate()
	body.append(Vector2(170.0, 96.0))
	body.append(Vector2(20.0, 96.0))
	draw_colored_polygon(body, FISH)
	_wobbly(back, INK, 2.0, rng)
	var tail := PackedVector2Array([Vector2(12.0, 90.0), Vector2(-6.0, 70.0), Vector2(0.0, 88.0), Vector2(-10.0, 100.0), Vector2(12.0, 94.0)])
	draw_colored_polygon(tail, FISH)
	_wobbly(tail, INK, 1.8, rng)
	draw_circle(Vector2(146.0, 76.0), 3.0, INK)


func _quay(rng: RandomNumberGenerator) -> void:
	var stones := PackedVector2Array([Vector2(-150.0, 18.0), Vector2(-86.0, -2.0), Vector2(-70.0, 22.0), Vector2(-136.0, 44.0)])
	draw_colored_polygon(stones, STONE)
	stones.append(stones[0])
	_wobbly(stones, INK, 2.0, rng)
	for i in 3:
		var a := Vector2(-140.0 + i * 20.0, 34.0 - i * 6.0)
		draw_line(a, a + Vector2(16.0, -5.0), INK_SOFT, 1.2, true)
	# A little house on the quay, flat-roofed.
	draw_rect(Rect2(-138.0, -12.0, 26.0, 20.0), STONE)
	draw_rect(Rect2(-138.0, -12.0, 26.0, 20.0), INK, false, 1.8)
	draw_rect(Rect2(-128.0, -2.0, 7.0, 10.0), INK_SOFT)


## The ship heading out to sea, away from the road: a round red hull and a cream square sail.
func _ship(rng: RandomNumberGenerator) -> void:
	var hull := PackedVector2Array()
	for i in 13:
		var t := float(i) / 12.0
		hull.append(Vector2(lerpf(-36.0, 42.0, t), -2.0 + sin(t * PI) * 16.0))
	hull.append(Vector2(50.0, -14.0))
	hull.insert(0, Vector2(-44.0, -12.0))
	draw_colored_polygon(hull, HULL)
	var edge := hull.duplicate()
	edge.append(hull[0])
	_wobbly(edge, INK, 2.2, rng)
	draw_line(Vector2(2.0, -2.0), Vector2(2.0, -64.0), INK, 2.2, true)
	var sail := PackedVector2Array([Vector2(-22.0, -60.0), Vector2(26.0, -60.0), Vector2(30.0, -16.0), Vector2(-18.0, -12.0)])
	draw_colored_polygon(sail, SAIL)
	sail.append(sail[0])
	_wobbly(sail, INK, 2.0, rng)
	for x in [-6.0, 10.0]:
		draw_line(Vector2(x, -58.0), Vector2(x + 2.0, -14.0), INK_SOFT, 1.1, true)


func _wobbly(points: PackedVector2Array, color: Color, width: float, rng: RandomNumberGenerator) -> void:
	var shaken := PackedVector2Array()
	for p in points:
		shaken.append(p + Vector2(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.6)))
	draw_polyline(shaken, color, width, true)


static func _bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	return a.lerp(b, t).lerp(b.lerp(c, t), t)
