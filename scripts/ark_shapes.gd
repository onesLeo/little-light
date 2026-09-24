extends RefCounted
## Built shapes for Noah's Ark, in the same paper-diorama hand as the camp: flat
## matte faces, a few broad planks, and the ink rim from camp_paper.gd. Use through a
## preload constant.
##
## The hull runs along x. Its cross-section is a rounded box (a superellipse), so the
## upper sides stand nearly straight and the bottom curves into the keel; the bow and
## stern close to a stem, and the deck and keel rise towards both ends.

const HALF_LENGTH := 8.4
const HALF_BEAM := 3.3
const DECK := 3.0
const KEEL := 0.3
const RINGS := 30
const SIDE_STEPS := 12

const PLANK_A := Color(0.74, 0.5, 0.27)
const PLANK_B := Color(0.65, 0.42, 0.21)
const BILGE := Color(0.5, 0.31, 0.16)
const DECK_COLOR := Color(0.8, 0.62, 0.38)

static var _vertex_mat: StandardMaterial3D
static var _sheet_mats: Dictionary = {}


## Half the hull's width at the deck, `x` metres from the middle.
static func half_beam(x: float) -> float:
	var t := clampf(absf(x) / HALF_LENGTH, 0.0, 1.0)
	return HALF_BEAM * sqrt(maxf(1.0 - pow(t, 4.0), 0.0))


static func deck_y(x: float) -> float:
	return DECK + 0.7 * pow(clampf(absf(x) / HALF_LENGTH, 0.0, 1.0), 4.0)


static func keel_y(x: float) -> float:
	return KEEL + 1.6 * pow(clampf(absf(x) / HALF_LENGTH, 0.0, 1.0), 4.0)


## How far the hull side stands out from the centre line at height `y`.
static func side_z(x: float, y: float) -> float:
	var d := deck_y(x)
	var k := keel_y(x)
	var t := clampf((d - y) / maxf(d - k, 0.01), 0.0, 1.0)
	return half_beam(x) * pow(1.0 - pow(t, 4.0), 0.25)


## A point on the hull: `a` runs 0 (deck edge, +z side) through PI/2 (keel) to PI
## (deck edge, -z side).
static func _hull_point(x: float, a: float) -> Vector3:
	var c := cos(a)
	var s := sin(a)
	var z := half_beam(x) * signf(c) * pow(absf(c), 0.5)
	var y := deck_y(x) - (deck_y(x) - keel_y(x)) * pow(absf(s), 0.5)
	return Vector3(x, y, z)


## The hull and its deck, coloured plank by plank.
static func hull() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var xs := PackedFloat32Array()
	for i in RINGS + 1:
		# Closer rings towards the ends, where the hull curves most.
		xs.append(-HALF_LENGTH * cos(PI * i / RINGS))
	for i in RINGS:
		for j in SIDE_STEPS:
			var a0 := PI * j / SIDE_STEPS
			var a1 := PI * (j + 1) / SIDE_STEPS
			var from_keel := absf(j + 0.5 - SIDE_STEPS * 0.5)
			var color := BILGE if from_keel < 1.5 else (PLANK_A if j % 2 == 0 else PLANK_B)
			_quad(st, color, _hull_point(xs[i], a0), _hull_point(xs[i], a1), _hull_point(xs[i + 1], a1), _hull_point(xs[i + 1], a0))
		var near_l := _hull_point(xs[i], 0.0)
		var near_r := _hull_point(xs[i + 1], 0.0)
		var far_r := _hull_point(xs[i + 1], PI)
		var far_l := _hull_point(xs[i], PI)
		_quad(st, DECK_COLOR, near_l, near_r, far_r, far_l)
	st.generate_normals()
	return st.commit()


## Counter-clockwise as seen from outside, like camp_paper.gd.
static func _quad(st: SurfaceTool, color: Color, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for p in [a, c, b, a, d, c]:
		st.set_color(color)
		st.add_vertex(p)


static func vertex_mat() -> StandardMaterial3D:
	if _vertex_mat == null:
		_vertex_mat = StandardMaterial3D.new()
		_vertex_mat.vertex_color_use_as_albedo = true
		_vertex_mat.roughness = 1.0
		_vertex_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return _vertex_mat


## A flat paper band bent into an arch, facing +z: a rainbow stripe.
static func arc_band(radius: float, width: float, steps: int = 32) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in steps:
		var a0 := PI * i / steps
		var a1 := PI * (i + 1) / steps
		var o0 := Vector3(cos(a0), sin(a0), 0.0) * radius
		var o1 := Vector3(cos(a1), sin(a1), 0.0) * radius
		var i0 := Vector3(cos(a0), sin(a0), 0.0) * (radius - width)
		var i1 := Vector3(cos(a1), sin(a1), 0.0) * (radius - width)
		for p in [o0, i0, i1, o0, i1, o1]:
			st.set_normal(Vector3.BACK)
			st.add_vertex(p)
	return st.commit()


## Matte colour seen from both sides, for paper sheets that have no thickness.
static func sheet_mat(color: Color) -> StandardMaterial3D:
	if _sheet_mats.has(color):
		return _sheet_mats[color]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_fog = true
	_sheet_mats[color] = m
	return m
