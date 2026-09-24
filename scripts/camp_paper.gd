extends RefCounted
## Paper-diorama building blocks for The King's Camp: flat matte colour and the
## black ink rim every prop in the valley has. The rim is an "inverted hull": a
## slightly larger copy drawn only from the inside, so it shows as an outline
## around the shape instead of covering it. Use through a preload constant.

const INK := Color(0.1, 0.06, 0.04)

static var _mats: Dictionary = {}
static var _ink: StandardMaterial3D


static func mat(color: Color) -> StandardMaterial3D:
	if _mats.has(color):
		return _mats[color]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_mats[color] = m
	return m


## Flat colour that ignores the blue light: fire, lantern paper, eyes.
static func glow_mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.disable_fog = true
	return m


static func ink() -> StandardMaterial3D:
	if _ink == null:
		_ink = StandardMaterial3D.new()
		_ink.albedo_color = INK
		_ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_ink.cull_mode = BaseMaterial3D.CULL_FRONT
	return _ink


## A mesh part with an ink rim `line` metres thick (0 for none).
static func part(parent: Node, part_name: String, mesh: Mesh, color: Color, at: Vector3,
		rot: Vector3 = Vector3.ZERO, size: Vector3 = Vector3.ONE, line: float = 0.025) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = part_name
	mi.mesh = mesh
	mi.material_override = mat(color)
	mi.position = at
	mi.rotation = rot
	mi.scale = size
	parent.add_child(mi)
	# Small parts (eyes, buttons, pegs) skip the shadow pass; it keeps tablets fast.
	if (mesh.get_aabb().size * size.abs()).length() < 0.25:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if line > 0.0:
		outline(mi, line)
	return mi


## Adds the ink rim to an existing part. The copy is stretched per axis so the
## rim is about as thick on a long tent as on a short post.
static func outline(mi: MeshInstance3D, line: float) -> MeshInstance3D:
	var box := mi.mesh.get_aabb()
	var c := box.get_center()
	var world_size := box.size * mi.scale.abs()
	var s := Vector3.ONE
	for i in 3:
		s[i] = 1.0 + 2.0 * line / maxf(world_size[i], 0.02)
	var hull := MeshInstance3D.new()
	hull.name = String(mi.name) + "Ink"
	hull.mesh = mi.mesh
	hull.material_override = ink()
	hull.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hull.transform = Transform3D(Basis.from_scale(s), c - c * s)
	mi.add_child(hull)
	return hull


## The rim for a flat cut-out that always faces the camera (the flames): the
## inverted hull does not work on a two-sided sheet, so this is a slightly larger
## black copy just behind it.
static func flat_outline(mi: MeshInstance3D, line: float) -> MeshInstance3D:
	var box := mi.mesh.get_aabb()
	var c := box.get_center()
	var s := Vector3(1.0 + 2.0 * line / maxf(box.size.x, 0.02), 1.0 + 2.0 * line / maxf(box.size.y, 0.02), 1.0)
	var m := StandardMaterial3D.new()
	m.albedo_color = INK
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_fog = true
	var back := MeshInstance3D.new()
	back.name = String(mi.name) + "Ink"
	back.mesh = mi.mesh
	back.material_override = m
	back.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	back.transform = Transform3D(Basis.from_scale(s), c - c * s + Vector3(0.0, 0.0, -0.012))
	mi.add_child(back)
	return back


## -- Primitive shapes, low-poly like the rest of the valley --------------------

static func box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


static func cylinder(radius: float, height: float, sides: int = 8, top_radius: float = -1.0) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.bottom_radius = radius
	m.top_radius = radius if top_radius < 0.0 else top_radius
	m.height = height
	m.radial_segments = sides
	m.rings = 1
	return m


static func sphere(radius: float, sides: int = 8) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = sides
	m.rings = maxi(sides / 2 - 1, 3)
	return m


static func capsule(radius: float, height: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = height
	m.radial_segments = 6
	m.rings = 2
	return m


## -- Built shapes ---------------------------------------------------------------

## A ridge tent, door facing +z: two sloped cloth sides, a triangle at each end.
static func ridge_tent(width: float, length: float, height: float) -> ArrayMesh:
	var hw := width * 0.5
	var hl := length * 0.5
	var st := _flat()
	var fl := Vector3(-hw, 0.0, hl)
	var fr := Vector3(hw, 0.0, hl)
	var ft := Vector3(0.0, height, hl + 0.08)
	var bl := Vector3(-hw, 0.0, -hl)
	var br := Vector3(hw, 0.0, -hl)
	var bt := Vector3(0.0, height, -hl - 0.08)
	_tri(st, fl, fr, ft)
	_tri(st, br, bl, bt)
	_quad(st, bl, fl, ft, bt)
	_quad(st, fr, br, bt, ft)
	st.generate_normals()
	return st.commit()


## The dark doorway on a ridge tent's front: a smaller triangle just proud of the cloth.
static func tent_door(width: float, height: float) -> ArrayMesh:
	var st := _flat()
	var hw := width * 0.5
	_tri(st, Vector3(-hw, 0.0, 0.0), Vector3(hw, 0.0, 0.0), Vector3(0.0, height, 0.0))
	_tri(st, Vector3(hw, 0.0, -0.02), Vector3(-hw, 0.0, -0.02), Vector3(0.0, height, -0.02))
	st.generate_normals()
	return st.commit()


## The king's round tent: straight walls, a cone roof that overhangs them.
static func pavilion(radius: float, wall: float, peak: float, sides: int = 10) -> ArrayMesh:
	var st := _flat()
	var eave := radius + 0.22
	var eave_y := wall - 0.12
	for k in sides:
		var a0 := TAU * k / sides
		var a1 := TAU * (k + 1) / sides
		var d0 := Vector3(sin(a0), 0.0, cos(a0))
		var d1 := Vector3(sin(a1), 0.0, cos(a1))
		# Wall panel.
		_quad(st, d0 * radius, d1 * radius, d1 * radius + Vector3(0.0, wall, 0.0), d0 * radius + Vector3(0.0, wall, 0.0))
		# Roof: from the eave up to the peak.
		_tri(st, d0 * eave + Vector3(0.0, eave_y, 0.0), d1 * eave + Vector3(0.0, eave_y, 0.0), Vector3(0.0, peak, 0.0))
		# Underside of the overhang, so the rim is closed.
		_quad(st, d1 * radius + Vector3(0.0, wall, 0.0), d1 * eave + Vector3(0.0, eave_y, 0.0),
				d0 * eave + Vector3(0.0, eave_y, 0.0), d0 * radius + Vector3(0.0, wall, 0.0))
	st.generate_normals()
	return st.commit()


## A flat flame tongue (a teardrop) facing +z, standing on the origin.
static func flame(width: float, height: float, lean: float) -> ArrayMesh:
	var st := _flat()
	var pts: Array[Vector3] = []
	var steps := 7
	for i in steps + 1:
		var t := float(i) / steps
		var r := sin(PI * pow(t, 0.8)) * width * 0.5 * (1.0 - t * 0.35)
		pts.append(Vector3(-r + lean * t * t, t * height, 0.0))
	for i in range(steps - 1, 0, -1):
		var t := float(i) / steps
		var r := sin(PI * pow(t, 0.8)) * width * 0.5 * (1.0 - t * 0.35)
		pts.append(Vector3(r + lean * t * t, t * height, 0.0))
	var centre := Vector3(lean * 0.1, height * 0.3, 0.0)
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		_tri(st, centre, a, b)
		_tri(st, centre + Vector3(0.0, 0.0, -0.01), b + Vector3(0.0, 0.0, -0.01), a + Vector3(0.0, 0.0, -0.01))
	st.generate_normals()
	return st.commit()


## A soft round glow for halos and fireflies.
static func glow_texture(inner: Color, outer: Color) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, inner)
	g.set_color(1, outer)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	return tex


static func halo(size: float, color: Color) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.no_depth_test = false
	m.disable_fog = true
	m.albedo_texture = glow_texture(Color(color, 1.0), Color(color, 0.0))
	quad.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _flat() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	return st


## Counter-clockwise as seen from the outside.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(b)


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(st, a, b, c)
	_tri(st, a, c, d)
