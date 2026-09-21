extends RefCounted
## The picture of a charm that a child can colour, made of a few regions (a ribbon, the ring, the
## middle, a star). The shapes are polygons in a unit square, listed back to front, so a tap goes to the
## front-most region under the finger and a region drawn on top hides the ones behind it.
## Use through a preload constant (no class_name):
##   const CharmArt := preload("res://scripts/charm_art.gd")
##
## What a child chose is a list with one number per region: an index into PALETTE, or -1 for "not
## coloured yet" (shown as blank paper). Profiles keeps that list for each child and charm.
## Only the Courage charm has a picture so far; any other charm id shows the same one until it gets its own.

const INK := Color(0.35, 0.2, 0.08)
const PAPER := Color(0.99, 0.97, 0.9)

## The paints, in the order the colouring page shows them.
const PALETTE: Array[Color] = [
	Color(0.96, 0.78, 0.3),    # gold
	Color(0.9, 0.42, 0.3),     # red
	Color(0.94, 0.56, 0.7),    # pink
	Color(0.64, 0.5, 0.84),    # purple
	Color(0.4, 0.66, 0.92),    # blue
	Color(0.42, 0.74, 0.5),    # green
	Color(0.62, 0.42, 0.28),   # brown
	Color(0.97, 0.93, 0.8),    # cream
]

const MEDAL_CENTER := Vector2(0.5, 0.42)


static func _circle(center: Vector2, radius: float, sides: int = 48) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in sides:
		var a := TAU * i / sides
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return pts


static func _star(center: Vector2, outer: float, inner: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + PI * i / 5.0
		pts.append(center + Vector2(cos(a), sin(a)) * (outer if i % 2 == 0 else inner))
	return pts


## The regions of a charm's picture, back to front, in unit coordinates.
static func regions(_charm_id: String) -> Array:
	var c := MEDAL_CENTER
	return [
		PackedVector2Array([Vector2(0.27, 0.62), Vector2(0.15, 0.97), Vector2(0.31, 0.89), Vector2(0.41, 0.99), Vector2(0.5, 0.66)]),
		PackedVector2Array([Vector2(0.73, 0.62), Vector2(0.85, 0.97), Vector2(0.69, 0.89), Vector2(0.59, 0.99), Vector2(0.5, 0.66)]),
		_circle(c, 0.36),
		_circle(c, 0.27),
		_star(c + Vector2(0.0, 0.01), 0.22, 0.1),
		_circle(c + Vector2(0.0, 0.02), 0.07, 24),
	]


static func region_count(charm_id: String) -> int:
	return regions(charm_id).size()


## The front-most region at a point in the unit square, or -1.
static func hit(charm_id: String, point: Vector2) -> int:
	var polys := regions(charm_id)
	for i in range(polys.size() - 1, -1, -1):
		if Geometry2D.is_point_in_polygon(point, polys[i]):
			return i
	return -1


static func fill_colour(colours: Array, region: int) -> Color:
	if region >= colours.size():
		return PAPER
	var index := int(colours[region])
	return PAPER if index < 0 or index >= PALETTE.size() else PALETTE[index]


## Draws the picture into `rect` of any canvas item (a control's _draw).
static func draw(item: CanvasItem, rect: Rect2, charm_id: String, colours: Array, line_width: float = 3.0) -> void:
	var polys := regions(charm_id)
	for i in polys.size():
		var pts := PackedVector2Array()
		for q in polys[i]:
			pts.append(rect.position + q * rect.size)
		item.draw_colored_polygon(pts, fill_colour(colours, i))
		var closed := pts.duplicate()
		closed.append(pts[0])
		item.draw_polyline(closed, INK, line_width)


## The picture as an image with a see-through background, for the 3D charm in the ceremony.
static func render_image(charm_id: String, colours: Array, side: int = 128) -> Image:
	var img := Image.create(side, side, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	var polys := regions(charm_id)
	for i in polys.size():
		var pts := PackedVector2Array()
		for q in polys[i]:
			pts.append(q * float(side))
		var lo := pts[0]
		var hi := pts[0]
		for p in pts:
			lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
			hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
		var colour := fill_colour(colours, i)
		for y in range(maxi(int(lo.y), 0), mini(int(hi.y) + 1, side)):
			for x in range(maxi(int(lo.x), 0), mini(int(hi.x) + 1, side)):
				if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
					img.set_pixel(x, y, colour)
		for k in pts.size():
			var a := pts[k]
			var b := pts[(k + 1) % pts.size()]
			var steps := maxi(int(ceilf(a.distance_to(b))), 1)
			for s in steps + 1:
				var p := a.lerp(b, float(s) / steps)
				img.fill_rect(Rect2i(int(p.x) - 1, int(p.y) - 1, 3, 3), INK)
	return img
