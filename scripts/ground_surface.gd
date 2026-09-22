extends RefCounted
## What the Wonder-Walker is standing on: "path", "water" (in the stream or the pool under the
## waterfall) or "grass". Footsteps sound different on each (see sound_library.gd).
## Use through a preload constant (no class_name):
##   const GroundSurface := preload("res://scripts/ground_surface.gd")
##
## The shapes are copied from the valley generator (art/blender/scripts/polish_valley_v6.py: PATH,
## LOWER_RIVER, POOL). Blender's (x, y) is Godot's (x, -z), so the points are listed as Blender has them
## and flipped here. If the path or river moves in the generator, move it here too.

const PATH_HALF_WIDTH := 0.7        # the painted trail is 0.62 either side of its middle line
const WATER_HALF_WIDTH := 0.9       # the river channel is 0.85 either side, and the bank slopes in
const POOL_CENTER := Vector2(-6.45, 4.5)
const POOL_RADIUS := 1.5

const PATH := [Vector2(0.3, -9.5), Vector2(0.2, -7.6), Vector2(0.1, -5.6), Vector2(0.25, -3.6), Vector2(0.45, -1.6),
	Vector2(0.5, 0.2), Vector2(0.42, 1.6), Vector2(0.55, 2.4), Vector2(0.6, 3.0)]
const RIVER := [Vector2(-6.45, 4.35), Vector2(-6.8, 2.6), Vector2(-7.4, 0.4), Vector2(-8.2, -2.2),
	Vector2(-9.2, -5.0), Vector2(-10.5, -8.2), Vector2(-12.0, -11.5)]


## The ground under a point of the world (only x and z matter).
static func at(world_position: Vector3) -> String:
	var p := Vector2(world_position.x, -world_position.z)   # into the generator's (x, y)
	if _distance_to_line(p, RIVER) < WATER_HALF_WIDTH or p.distance_to(POOL_CENTER) < POOL_RADIUS:
		return "water"
	if _distance_to_line(p, PATH) < PATH_HALF_WIDTH:
		return "path"
	return "grass"


static func _distance_to_line(p: Vector2, points: Array) -> float:
	var best := INF
	for i in points.size() - 1:
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.000001), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
	return best
