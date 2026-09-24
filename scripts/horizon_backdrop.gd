extends Node3D
## Fills the space beyond the valley so the diorama no longer ends in a beige
## void: layers of soft paper-cut hills that get paler and hazier with
## distance, and a slow drift of flat paper clouds. Everything is built in code.

@export var hill_seed: int = 7
## (radius, average top height, wobble, colour) from nearest to farthest.
@export var layers: Array[Dictionary] = [
	{"radius": 47.0, "height": 3.5, "wobble": 2.2, "color": Color(0.62, 0.78, 0.52)},
	{"radius": 62.0, "height": 8.0, "wobble": 4.0, "color": Color(0.62, 0.79, 0.62)},
	{"radius": 82.0, "height": 13.0, "wobble": 5.5, "color": Color(0.68, 0.82, 0.72)},
	{"radius": 108.0, "height": 19.0, "wobble": 7.0, "color": Color(0.76, 0.86, 0.84)},
]
@export var cloud_count: int = 12
@export var cloud_drift_speed: float = 0.004   ## radians per second around the valley

var _cloud_root: Node3D
var _hill_mat: StandardMaterial3D
var _cloud_mat: StandardMaterial3D


func _ready() -> void:
	_build_hills()
	_build_clouds()


func _process(delta: float) -> void:
	if _cloud_root:
		_cloud_root.rotation.y += cloud_drift_speed * delta


## The King's Camp's blue hour: the far hills step toward violet-blue and the
## clouds go a soft grey-blue. They are painted (unshaded), so the light alone
## would leave them in daytime colours.
func set_blue_hour() -> void:
	if _hill_mat:
		_hill_mat.albedo_color = Color(0.5, 0.56, 0.86)
	if _cloud_mat:
		_cloud_mat.albedo_color = Color(0.72, 0.76, 0.94, 0.85)


func set_daylight() -> void:
	# Restore the shared backdrop when leaving the King's Camp for another story.
	if _hill_mat:
		_hill_mat.albedo_color = Color.WHITE
	if _cloud_mat:
		_cloud_mat.albedo_color = Color.WHITE


## -- Hills -------------------------------------------------------------------

func _build_hills() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hill_seed
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_hill_mat = mat
	for i in layers.size():
		var layer: Dictionary = layers[i]
		var mi := MeshInstance3D.new()
		mi.name = "Hills%d" % i
		mi.mesh = _ridge_mesh(layer["radius"], layer["height"], layer["wobble"], layer["color"], rng)
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)


func _ridge_mesh(radius: float, height: float, wobble: float, color: Color, rng: RandomNumberGenerator) -> ArrayMesh:
	var segments := 220
	var p1 := rng.randf() * TAU
	var p2 := rng.randf() * TAU
	var p3 := rng.randf() * TAU
	var p4 := rng.randf() * TAU
	var floor_y := -8.0
	var top_col := color.lightened(0.08)
	var bottom_col := color.darkened(0.12)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in segments:
		var a0 := TAU * float(k) / segments
		var a1 := TAU * float(k + 1) / segments
		var h0 := height + wobble * _profile(a0, p1, p2, p3, p4)
		var h1 := height + wobble * _profile(a1, p1, p2, p3, p4)
		var v0 := Vector3(cos(a0) * radius, h0, sin(a0) * radius)
		var v1 := Vector3(cos(a1) * radius, h1, sin(a1) * radius)
		var b0 := Vector3(v0.x, floor_y, v0.z)
		var b1 := Vector3(v1.x, floor_y, v1.z)
		_tri(st, b0, v0, v1, bottom_col, top_col, top_col)
		_tri(st, b0, v1, b1, bottom_col, top_col, bottom_col)
	return st.commit()


func _profile(a: float, p1: float, p2: float, p3: float, p4: float) -> float:
	return 0.45 * sin(3.0 * a + p1) + 0.30 * sin(7.0 * a + p2) + 0.17 * sin(13.0 * a + p3) + 0.08 * sin(29.0 * a + p4)


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	st.set_color(ca)
	st.add_vertex(a)
	st.set_color(cb)
	st.add_vertex(b)
	st.set_color(cc)
	st.add_vertex(c)


## -- Clouds ------------------------------------------------------------------

func _build_clouds() -> void:
	_cloud_root = Node3D.new()
	_cloud_root.name = "Clouds"
	add_child(_cloud_root)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.albedo_texture = _cloud_texture()
	mat.disable_fog = true
	_cloud_mat = mat
	var rng := RandomNumberGenerator.new()
	rng.seed = hill_seed + 100
	for i in cloud_count:
		var quad := QuadMesh.new()
		var width := rng.randf_range(26.0, 48.0)
		quad.size = Vector2(width, width * 0.4)
		quad.material = mat
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var angle := TAU * (float(i) + rng.randf_range(-0.3, 0.3)) / cloud_count
		var dist := rng.randf_range(70.0, 115.0)
		mi.position = Vector3(cos(angle) * dist, rng.randf_range(26.0, 44.0), sin(angle) * dist)
		if rng.randf() < 0.5:
			mi.scale.x = -1.0
		_cloud_root.add_child(mi)


## A flat-bottomed, cartoon cloud: a union of soft circles, white on top and a
## faint blue-grey underside.
func _cloud_texture() -> ImageTexture:
	var w := 256
	var h := 104
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var circles := [Vector3(60.0, 70.0, 30.0), Vector3(100.0, 56.0, 40.0), Vector3(150.0, 58.0, 38.0),
		Vector3(190.0, 70.0, 28.0), Vector3(125.0, 72.0, 36.0)]
	var base_y := 88.0
	for y in h:
		for x in w:
			var cover := 0.0
			for c in circles:
				var d := Vector2(x, y).distance_to(Vector2(c.x, c.y))
				cover = maxf(cover, clampf((c.z - d) / 2.0, 0.0, 1.0))
			cover *= clampf((base_y - y) / 2.0, 0.0, 1.0)
			if cover <= 0.0:
				continue
			var shade := clampf((y - 62.0) / 26.0, 0.0, 1.0)
			var col := Color(1.0, 1.0, 1.0).lerp(Color(0.84, 0.90, 0.97), shade)
			col.a = cover * 0.95
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)
