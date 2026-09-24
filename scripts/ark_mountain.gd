extends Node3D
## The mountaintop Noah builds on: a flat grassy top with a soft rim, slopes that
## fall away through olive, cypress and cedar trees into a quiet sea of clouds,
## far peaks standing out of the clouds, sky clouds drifting overhead and a few
## birds circling. Everything is built in code, in local coordinates with the
## top at y = 0, and everything that grows sways in the breeze.
##
## Trees, grass and clouds are MultiMeshes so hundreds of them stay cheap on a tablet.

const SWAY := preload("res://assets/shaders/paper_tree_sway.gdshader")
const SWAY_INK := preload("res://assets/shaders/paper_tree_ink.gdshader")
const MEADOW := preload("res://assets/shaders/meadow_sway.gdshader")

## Half the size of the flat top (the back edge, behind the ark, comes in closer so the
## drop into the clouds shows past the hull), and of the part the child can walk on.
const TOP := Vector2(24.0, 22.0)
const TOP_BACK := 17.5
const PLAY := Vector2(18.5, 16.5)
## The hull's footprint on the top (centre and half size), kept clear of plants.
const HULL_AT := Vector2(0.0, -5.8)
const HULL_HALF := Vector2(9.0, 3.8)
## Where the cloud sea lies, below the rim.
const CLOUD_SEA_Y := -9.0
## Slope rings: how far out from the rim, and how far down.
const RINGS := [Vector2(0.0, 0.0), Vector2(2.0, -1.6), Vector2(5.5, -6.5), Vector2(11.0, -13.0), Vector2(20.0, -24.0)]
const RIM_STEPS := 72

const GRASS_TOP := Color(0.55, 0.59, 0.44)
const GRASS_SHOULDER := Color(0.53, 0.56, 0.43)
const SLOPE := Color(0.55, 0.54, 0.46)
const SLOPE_LOW := Color(0.52, 0.53, 0.5)
const TRUNK := Color(0.44, 0.36, 0.3)
const OLIVE_LEAVES := [Color(0.54, 0.58, 0.44), Color(0.5, 0.55, 0.42), Color(0.58, 0.6, 0.47)]
const CYPRESS_LEAVES := [Color(0.36, 0.45, 0.38), Color(0.4, 0.48, 0.4)]
const CEDAR_LEAVES := [Color(0.42, 0.5, 0.45), Color(0.38, 0.47, 0.43)]
const GRASS_TINTS := [Color(0.56, 0.62, 0.44), Color(0.6, 0.64, 0.47), Color(0.52, 0.58, 0.42), Color(0.64, 0.64, 0.5)]
const CLOUD := Color(0.97, 0.96, 0.93)
const PEAK := Color(0.54, 0.6, 0.63)
const SNOW := Color(0.93, 0.94, 0.95)

var _rng := RandomNumberGenerator.new()
var _rim: PackedVector2Array = []
var _sky_clouds: Node3D
var _cloud_sea: Node3D
var _birds: Node3D
var _time: float = 0.0


func _ready() -> void:
	_rng.seed = 2024
	_build_rim()
	_build_land()
	_build_peaks()
	_build_trees()
	_build_grass()
	_build_cloud_sea()
	_build_sky_clouds()
	_build_birds()


func _process(delta: float) -> void:
	_time += delta
	if _sky_clouds:
		_sky_clouds.rotation.y += 0.006 * delta
	if _cloud_sea:
		_cloud_sea.rotation.y -= 0.003 * delta
	if _birds:
		for bird in _birds.get_children():
			var b := bird as Node3D
			var speed: float = b.get_meta("speed")
			var radius: float = b.get_meta("radius")
			var a: float = b.get_meta("phase") + _time * speed
			b.position = Vector3(cos(a) * radius, b.get_meta("height") + sin(_time * 0.7 + radius) * 0.8, sin(a) * radius)
			b.rotation.y = -a + (PI if speed > 0.0 else 0.0)
			var flap := sin(_time * 5.0 + radius) * 0.5
			(b.get_node("WingL") as Node3D).rotation.z = flap
			(b.get_node("WingR") as Node3D).rotation.z = -flap


## True where the child walks, or where the ark and its ramp stand.
static func is_busy(p: Vector2) -> bool:
	if absf(p.x) < PLAY.x and absf(p.y) < PLAY.y:
		return true
	return absf(p.x - HULL_AT.x) < HULL_HALF.x and absf(p.y - HULL_AT.y) < HULL_HALF.y


## -- Land ----------------------------------------------------------------------------

## The rim of the flat top: a rounded rectangle with a gentle wobble.
func _build_rim() -> void:
	for i in RIM_STEPS:
		var a := TAU * i / RIM_STEPS
		var c := cos(a)
		var s := sin(a)
		var depth := TOP.y if s > 0.0 else TOP_BACK
		var p := Vector2(TOP.x * signf(c) * pow(absf(c), 0.4), depth * signf(s) * pow(absf(s), 0.4))
		_rim.append(p * (1.0 + sin(a * 5.0 + 1.3) * 0.03 + sin(a * 11.0) * 0.015))


## A point on slope ring `k` at rim step `i`: pushed out from the rim and down.
func _ring_point(k: int, i: int) -> Vector3:
	var p: Vector2 = _rim[i % RIM_STEPS]
	var ring: Vector2 = RINGS[k]
	var out := p.normalized() * ring.x
	var wobble := 0.0 if k == 0 else sin(i * 1.7 + k * 2.3) * 0.12 * ring.x
	var q := p + out + p.normalized() * wobble
	var drop := ring.y + (0.0 if k == 0 else sin(i * 0.9 + k) * 0.08 * ring.y)
	return Vector3(q.x, drop, q.y)


func _build_land() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	# The flat top, as a fan from the middle.
	for i in RIM_STEPS:
		var a := _ring_point(0, i)
		var b := _ring_point(0, i + 1)
		_tri(st, GRASS_TOP, Vector3(0.0, 0.0, 0.0), b, a)
	# The slopes, ring by ring, darker and cooler as they go down into the clouds.
	var shades := [GRASS_SHOULDER, SLOPE, SLOPE, SLOPE_LOW]
	for k in RINGS.size() - 1:
		for i in RIM_STEPS:
			var shade: Color = shades[k]
			shade = shade.lightened(0.04) if (i + k) % 3 == 0 else (shade.darkened(0.04) if (i + k) % 3 == 1 else shade)
			_quad(st, shade, _ring_point(k, i), _ring_point(k, i + 1), _ring_point(k + 1, i + 1), _ring_point(k + 1, i))
	st.generate_normals()
	var land := MeshInstance3D.new()
	land.name = "Mountaintop"
	land.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	land.material_override = mat
	land.position.y = 0.01
	add_child(land)


## Far peaks standing out of the cloud sea all round, paler with distance.
func _build_peaks() -> void:
	var peaks := Node3D.new()
	peaks.name = "FarPeaks"
	add_child(peaks)
	for i in 18:
		var a := TAU * i / 18.0 + _rng.randf_range(-0.12, 0.12)
		var dist := _rng.randf_range(95.0, 165.0)
		var height := _rng.randf_range(16.0, 34.0) * (dist / 130.0)
		var radius := height * _rng.randf_range(0.7, 1.0)
		var base := Vector3(cos(a) * dist, CLOUD_SEA_Y - 6.0, sin(a) * dist)
		var st := _flat()
		_cone(st, PEAK.lerp(Color(0.78, 0.82, 0.86), (dist - 95.0) / 70.0), Vector3.ZERO, radius, height, 7, _rng)
		_cone(st, SNOW, Vector3(0.0, height * 0.78, 0.0), radius * 0.23, height * 0.23, 7, _rng)
		st.generate_normals()
		var mi := MeshInstance3D.new()
		mi.name = "Peak%d" % i
		mi.mesh = st.commit()
		mi.material_override = _vertex_mat()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = base
		mi.rotation.y = _rng.randf() * TAU
		peaks.add_child(mi)


## -- Trees and grass ---------------------------------------------------------------------

func _build_trees() -> void:
	var olives: Array[Transform3D] = []
	var cypresses: Array[Transform3D] = []
	var cedars: Array[Transform3D] = []
	# On the top, between the walking area and the rim.
	var tries := 0
	while olives.size() + cypresses.size() < 60 and tries < 4000:
		tries += 1
		var p := Vector2(_rng.randf_range(-TOP.x, TOP.x), _rng.randf_range(-TOP.y, TOP.y))
		if is_busy(p) or not _inside_rim(p, 0.93):
			continue
		# Nothing near the camera, and nothing straight behind the ark, where the
		# view drops away into the clouds.
		if p.y > 12.0 or (p.y < -12.0 and absf(p.x) < 13.0):
			continue
		var xf := _tree_xform(Vector3(p.x, 0.0, p.y), _rng.randf_range(0.9, 1.4))
		if _rng.randf() < 0.3:
			cypresses.append(xf)
		else:
			olives.append(xf)
	# Down the slopes, thinning out towards the clouds.
	for i in 260:
		var step := _rng.randi_range(0, RIM_STEPS - 1)
		var k := 0 if _rng.randf() < 0.55 else 1
		var t := _rng.randf()
		var a := _ring_point(k, step).lerp(_ring_point(k, step + 1), _rng.randf())
		var b := _ring_point(k + 1, step).lerp(_ring_point(k + 1, step + 1), _rng.randf())
		var at := a.lerp(b, t)
		if at.y < CLOUD_SEA_Y + 2.0:
			continue
		# Keep the slopes behind the camera bare, and the drop behind the ark open.
		if at.z > 12.0 or (at.z < -12.0 and absf(at.x) < 15.0):
			continue
		var roll := _rng.randf()
		var xf := _tree_xform(at, _rng.randf_range(1.0, 1.7))
		if roll < 0.45:
			cedars.append(xf)
		elif roll < 0.7:
			cypresses.append(xf)
		else:
			olives.append(xf)
	_plant("Olives", _olive_mesh(false), _olive_mesh(true), olives, OLIVE_LEAVES, 0.06)
	_plant("OliveTrunks", _trunk_mesh(false), _trunk_mesh(true), olives, [TRUNK], 0.02)
	_plant("Cypresses", _cypress_mesh(false), _cypress_mesh(true), cypresses, CYPRESS_LEAVES, 0.03)
	_plant("Cedars", _cedar_mesh(false), _cedar_mesh(true), cedars, CEDAR_LEAVES, 0.04)
	_plant("CedarTrunks", _trunk_mesh(false, 0.9), _trunk_mesh(true, 0.9), cedars, [TRUNK], 0.02)


func _inside_rim(p: Vector2, margin: float) -> bool:
	var a := fposmod(atan2(p.y, p.x), TAU)
	var rim: Vector2 = _rim[int(round(a / TAU * RIM_STEPS)) % RIM_STEPS]
	return p.length() < rim.length() * margin


func _tree_xform(at: Vector3, size: float) -> Transform3D:
	var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * size)
	return Transform3D(basis, at)


## One MultiMesh of a plant part, with a second one for its ink rim.
func _plant(plant_name: String, mesh: Mesh, ink_mesh: Mesh, where: Array[Transform3D], tints: Array, line: float) -> void:
	if where.is_empty():
		return
	var mat := ShaderMaterial.new()
	mat.shader = SWAY
	var ink := ShaderMaterial.new()
	ink.shader = SWAY_INK
	ink.set_shader_parameter("line", line)
	for layer in 2:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = mesh if layer == 0 else ink_mesh
		mm.instance_count = where.size()
		for i in where.size():
			mm.set_instance_transform(i, where[i])
			mm.set_instance_color(i, tints[i % tints.size()])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = plant_name if layer == 0 else plant_name + "Ink"
		mmi.multimesh = mm
		mmi.material_override = mat if layer == 0 else ink
		if layer == 1:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)


## An olive: a round, broad crown of three soft lumps.
func _olive_mesh(smooth: bool) -> ArrayMesh:
	var st := _surface(smooth)
	_blob(st, Color.WHITE, Vector3(0.0, 1.75, 0.0), Vector3(0.95, 0.7, 0.9), 8, 5)
	_blob(st, Color.WHITE, Vector3(0.55, 1.5, 0.25), Vector3(0.6, 0.5, 0.6), 7, 4)
	_blob(st, Color.WHITE, Vector3(-0.5, 1.55, -0.25), Vector3(0.62, 0.5, 0.6), 7, 4)
	st.generate_normals()
	return st.commit()


func _trunk_mesh(smooth: bool, height: float = 1.4) -> ArrayMesh:
	var st := _surface(smooth)
	_cone(st, Color.WHITE, Vector3.ZERO, 0.16, height, 6, null, 0.09)
	st.generate_normals()
	return st.commit()


## A cypress: one tall, narrow flame of green.
func _cypress_mesh(smooth: bool) -> ArrayMesh:
	var st := _surface(smooth)
	_blob(st, Color.WHITE, Vector3(0.0, 2.0, 0.0), Vector3(0.55, 2.0, 0.55), 7, 6)
	st.generate_normals()
	return st.commit()


## A mountain cedar: three stacked, spreading tiers.
func _cedar_mesh(smooth: bool) -> ArrayMesh:
	var st := _surface(smooth)
	for k in 3:
		_cone(st, Color.WHITE, Vector3(0.0, 0.8 + k * 0.85, 0.0), 1.3 - k * 0.32, 1.3, 8, null)
	st.generate_normals()
	return st.commit()


## Short tufts of mountain grass on the top, swaying like the valley meadow.
func _build_grass() -> void:
	var spots: Array[Transform3D] = []
	var tints: Array = []
	var tries := 0
	while spots.size() < 700 and tries < 8000:
		tries += 1
		var p := Vector2(_rng.randf_range(-TOP.x, TOP.x), _rng.randf_range(-TOP.y, TOP.y))
		if not _inside_rim(p, 0.97):
			continue
		# Not on the path, the ramp, under the hull, or on the bench's work spot.
		if absf(p.x) < 2.4 and p.y > -2.0 and p.y < 14.0:
			continue
		if absf(p.x - HULL_AT.x) < HULL_HALF.x and absf(p.y - HULL_AT.y) < HULL_HALF.y:
			continue
		if p.distance_to(Vector2(5.3, 0.6)) < 2.2:
			continue
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.8, 1.4))
		spots.append(Transform3D(basis, Vector3(p.x, 0.02, p.y)))
		tints.append(GRASS_TINTS[_rng.randi() % GRASS_TINTS.size()])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _tuft_mesh()
	mm.instance_count = spots.size()
	for i in spots.size():
		mm.set_instance_transform(i, spots[i])
		mm.set_instance_color(i, tints[i])
	var mat := ShaderMaterial.new()
	mat.shader = MEADOW
	mat.set_shader_parameter("sway_amount", 0.08)
	mat.set_shader_parameter("bend_strength", 0.0)
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Grass"
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


## A few thin blades leaning out from one spot. UV.x = 0 (a blade) and UV.y = height,
## the meadow shader's convention.
func _tuft_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 5:
		var a := TAU * k / 5.0 + 0.3
		var lean := Vector3(cos(a), 0.0, sin(a)) * 0.07
		var side := Vector3(-sin(a), 0.0, cos(a)) * 0.035
		var h := 0.24 + (k % 3) * 0.06
		for v in [[-side, 0.0], [side, 0.0], [lean * 2.0 + Vector3(0.0, h, 0.0), 1.0]]:
			st.set_uv(Vector2(0.0, v[1]))
			st.add_vertex(v[0])
	return st.commit()


## -- Clouds and birds ------------------------------------------------------------------

## A calm sea of cloud all round the foot of the mountain, drifting very slowly.
func _build_cloud_sea() -> void:
	_cloud_sea = Node3D.new()
	_cloud_sea.name = "CloudSea"
	add_child(_cloud_sea)
	var spots: Array[Transform3D] = []
	for i in 320:
		var a := _rng.randf() * TAU
		var dist := _rng.randf_range(26.0, 190.0)
		var size := Vector3(_rng.randf_range(7.0, 16.0), _rng.randf_range(2.0, 4.0), _rng.randf_range(6.0, 12.0)) * (0.7 + dist / 190.0)
		var at := Vector3(cos(a) * dist, CLOUD_SEA_Y + _rng.randf_range(-1.5, 1.5), sin(a) * dist)
		spots.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(size), at))
	_cloud_sea.add_child(_clouds("SeaPuffs", spots, 0.94))


## Soft paper clouds high up, drifting round the mountain.
func _build_sky_clouds() -> void:
	_sky_clouds = Node3D.new()
	_sky_clouds.name = "SkyClouds"
	add_child(_sky_clouds)
	var spots: Array[Transform3D] = []
	for c in 16:
		var a := TAU * c / 16.0 + _rng.randf_range(-0.2, 0.2)
		var dist := _rng.randf_range(55.0, 140.0)
		var center := Vector3(cos(a) * dist, _rng.randf_range(16.0, 34.0), sin(a) * dist)
		var width := _rng.randf_range(6.0, 12.0)
		for k in 5:
			var off := Vector3(_rng.randf_range(-1.0, 1.0) * width * 0.6, _rng.randf_range(0.0, 1.2), _rng.randf_range(-1.0, 1.0) * 2.0)
			var size := Vector3(width * _rng.randf_range(0.35, 0.55), width * _rng.randf_range(0.18, 0.28), width * _rng.randf_range(0.3, 0.45))
			spots.append(Transform3D(Basis.IDENTITY.scaled(size), center + off))
	_sky_clouds.add_child(_clouds("SkyPuffs", spots, 1.0))


func _clouds(cloud_name: String, spots: Array[Transform3D], light: float) -> MultiMeshInstance3D:
	var st := _surface(true)
	_blob(st, Color.WHITE, Vector3.ZERO, Vector3.ONE, 9, 5)
	st.generate_normals()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = st.commit()
	mm.instance_count = spots.size()
	for i in spots.size():
		mm.set_instance_transform(i, spots[i])
	var mat := StandardMaterial3D.new()
	mat.albedo_color = CLOUD * light
	mat.roughness = 1.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	# A little of their own light, so the shaded sides stay soft rather than grey.
	mat.emission_enabled = true
	mat.emission = Color(0.55, 0.56, 0.58)
	var mmi := MultiMeshInstance3D.new()
	mmi.name = cloud_name
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mmi


## A few birds gliding in slow circles high over the ark.
func _build_birds() -> void:
	_birds = Node3D.new()
	_birds.name = "Birds"
	add_child(_birds)
	var ink := Color(0.3, 0.27, 0.26)
	for i in 4:
		var bird := Node3D.new()
		bird.name = "Bird%d" % i
		bird.set_meta("radius", 14.0 + i * 5.0)
		bird.set_meta("height", 13.0 + i * 2.5)
		bird.set_meta("phase", i * 1.7)
		bird.set_meta("speed", 0.12 if i % 2 == 0 else -0.09)
		_birds.add_child(bird)
		var body := MeshInstance3D.new()
		body.mesh = _box(Vector3(0.12, 0.1, 0.45))
		body.material_override = _flat_mat(ink)
		bird.add_child(body)
		for side in [-1.0, 1.0]:
			var pivot := Node3D.new()
			pivot.name = "WingL" if side < 0.0 else "WingR"
			bird.add_child(pivot)
			var wing := MeshInstance3D.new()
			wing.mesh = _box(Vector3(0.7, 0.03, 0.26))
			wing.material_override = _flat_mat(ink)
			wing.position = Vector3(side * 0.38, 0.0, 0.0)
			pivot.add_child(wing)


## -- Mesh helpers ------------------------------------------------------------------

func _surface(smooth: bool) -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0 if smooth else -1)
	return st


func _flat() -> SurfaceTool:
	return _surface(false)


## Counter-clockwise as seen from outside (the camp_paper.gd convention).
func _tri(st: SurfaceTool, color: Color, a: Vector3, b: Vector3, c: Vector3) -> void:
	for p in [a, c, b]:
		st.set_color(color)
		st.add_vertex(p)


func _quad(st: SurfaceTool, color: Color, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(st, color, a, b, c)
	_tri(st, color, a, c, d)


## A low-poly ellipsoid.
func _blob(st: SurfaceTool, color: Color, center: Vector3, radius: Vector3, sides: int, rings: int) -> void:
	for j in rings:
		var t0 := -PI / 2.0 + PI * j / rings
		var t1 := -PI / 2.0 + PI * (j + 1) / rings
		for i in sides:
			var p0 := TAU * i / sides
			var p1 := TAU * (i + 1) / sides
			var a := center + Vector3(cos(t0) * cos(p0), sin(t0), cos(t0) * sin(p0)) * radius
			var b := center + Vector3(cos(t1) * cos(p0), sin(t1), cos(t1) * sin(p0)) * radius
			var c := center + Vector3(cos(t1) * cos(p1), sin(t1), cos(t1) * sin(p1)) * radius
			var d := center + Vector3(cos(t0) * cos(p1), sin(t0), cos(t0) * sin(p1)) * radius
			_quad(st, color, a, b, c, d)


## A cone (or, with `top` > 0, a tapered post) standing on `base`.
func _cone(st: SurfaceTool, color: Color, base: Vector3, radius: float, height: float, sides: int, rng: RandomNumberGenerator, top: float = 0.0) -> void:
	for i in sides:
		var p0 := TAU * i / sides
		var p1 := TAU * (i + 1) / sides
		var j0 := 1.0 if rng == null else rng.randf_range(0.8, 1.15)
		var j1 := 1.0 if rng == null else rng.randf_range(0.8, 1.15)
		var a := base + Vector3(cos(p0), 0.0, sin(p0)) * radius * j0
		var d := base + Vector3(cos(p1), 0.0, sin(p1)) * radius * j1
		var b := base + Vector3(cos(p0) * top, height, sin(p0) * top)
		var c := base + Vector3(cos(p1) * top, height, sin(p1) * top)
		if top > 0.0:
			_quad(st, color, a, b, c, d)
		else:
			_tri(st, color, a, b, d)


func _vertex_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


func _flat_mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m
