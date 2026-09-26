extends Node3D
## The sea in Jonah's journey (jonahs_journey.gd): a wide sheet of paper-craft water
## (flood_sea.gdshader) with long paper wave bands in front of it, each moving at its own slow
## pace, and a storm that can be turned up and down (`storm`, 0 calm to 1 at its height). The
## storm only ever rises and falls slowly: the bands lift and travel further, the water swells,
## its colours go from turquoise to slate, and paper rain falls, but nothing flashes, nothing
## shakes the camera, and the bands never cover more than the bottom of the view.
## With reduced motion (game_settings.gd), the bands barely travel and the swell stays low.
##
## Set `size`, `bands` and `calm_colours` before adding it to the tree; everything is relative
## to its own position (its y is the water line).

const Paper := preload("res://scripts/camp_paper.gd")
const GameSettings := preload("res://scripts/game_settings.gd")
const SEA_SHADER := preload("res://assets/shaders/flood_sea.gdshader")

## Turquoise harbour water and slate storm water: deep, mid, crest.
const CALM := [Color(0.16, 0.5, 0.6), Color(0.24, 0.62, 0.68), Color(0.46, 0.78, 0.8)]
const STORMY := [Color(0.18, 0.26, 0.34), Color(0.26, 0.35, 0.44), Color(0.42, 0.5, 0.58)]
const CREST := Color(0.95, 0.96, 0.92)
const RAIN := Color(0.78, 0.84, 0.9, 0.55)

## The water sheet's size (x, z), centred on this node.
var size: Vector2 = Vector2(220.0, 220.0)
## One wave band each: {"at": Vector3 (local), "length": float, "height": float, "speed": float}.
var bands: Array = []
## The colour of the water when calm, as [deep, mid, crest] (CALM by default).
var calm_colours: Array = CALM
var haze_colour: Color = Color(0.76, 0.86, 0.88)
## 0 calm to 1 at the storm's height. Tween it with set_storm().
var storm: float = 0.0

var _time: float = 0.0
var _water: MeshInstance3D
var _mat: ShaderMaterial
var _bands: Array[Node3D] = []
var _band_home: Array[Vector3] = []
var _band_speed: Array[float] = []
var _rain: CPUParticles3D
var _storm_tween: Tween


func _ready() -> void:
	var sheet := PlaneMesh.new()
	sheet.size = size
	sheet.subdivide_width = 90
	sheet.subdivide_depth = 90
	_mat = ShaderMaterial.new()
	_mat.shader = SEA_SHADER
	_mat.set_shader_parameter("haze_start", 30.0)
	_mat.set_shader_parameter("haze_end", 150.0)
	_mat.set_shader_parameter("horizon_color", haze_colour)
	_water = MeshInstance3D.new()
	_water.name = "Water"
	_water.mesh = sheet
	_water.material_override = _mat
	_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_water)
	for i in bands.size():
		var spec: Dictionary = bands[i]
		var band := wave_band(spec.get("length", 20.0), spec.get("height", 0.6), calm_colours[1].lightened(0.06 * float(i % 2)))
		band.name = "WaveBand%d" % i
		band.position = spec["at"]
		add_child(band)
		_bands.append(band)
		_band_home.append(spec["at"])
		_band_speed.append(spec.get("speed", 0.4))
	_build_rain()
	_apply_storm()


## A long paper wave, `length` along x and `height` tall, facing +z: a strip of card with a
## scalloped top, a cream crest along it and an ink rim, standing on the water line.
static func wave_band(length: float, height: float, colour: Color) -> Node3D:
	var band := Node3D.new()
	var body := Paper.part(band, "Body", _scalloped(length, height, 0.12, 0.0), colour, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, 0.02)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Its own material, so the storm can change its colour without touching every paper part.
	body.material_override = (body.material_override as StandardMaterial3D).duplicate()
	var crest := Paper.part(band, "Crest", _scalloped(length, 0.1, 0.13, height - 0.02), CREST, Vector3(0.0, 0.0, 0.01), Vector3.ZERO, Vector3.ONE, 0.0)
	crest.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return band


## A tapered swell from y = `base` to `base` + `height`. Both edges meet the water at the ends,
## and a pair of sine curves makes the crest roll smoothly instead of reading as a moving block.
## When `base` is above zero this makes the thin cream crest that follows the wave's top.
static func _scalloped(length: float, height: float, thickness: float, base: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := maxi(int(length * 3.0), 8)
	var half := thickness * 0.5
	var prev_top := Vector3.ZERO
	var prev_bottom := Vector3.ZERO
	for i in steps + 1:
		var t := float(i) / float(steps)
		var x := -length * 0.5 + length * t
		var envelope := pow(sin(PI * t), 0.72)
		var ripple := (sin(x * 1.05 + 0.35) + sin(x * 2.1 - 0.6) * 0.38) * 0.11
		var top := Vector3(x, ((base + height) + ripple) * envelope, 0.0)
		var bottom_level := base if base > 0.0 else -0.22
		var bottom := Vector3(x, (bottom_level + ripple * 0.42) * envelope, 0.0)
		if i > 0:
			for side in [half, -half]:
				var s: float = side
				var a := prev_bottom + Vector3(0, 0, s)
				var b := bottom + Vector3(0, 0, s)
				var c := top + Vector3(0, 0, s)
				var d := prev_top + Vector3(0, 0, s)
				if s > 0.0:
					_quad(st, a, b, c, d)
				else:
					_quad(st, b, a, d, c)
			# The top edge, so the strip is closed from above.
			_quad(st, prev_top + Vector3(0, 0, half), top + Vector3(0, 0, half), top + Vector3(0, 0, -half), prev_top + Vector3(0, 0, -half))
		prev_top = top
		prev_bottom = bottom
	st.generate_normals()
	return st.commit()


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for v in [a, c, b, a, d, c]:
		st.add_vertex(v)


## Paper rain: thin pale streaks falling a little aslant, only while the storm is up.
func _build_rain() -> void:
	_rain = CPUParticles3D.new()
	_rain.name = "Rain"
	_rain.amount = 360
	_rain.lifetime = 1.4
	_rain.preprocess = 1.4
	_rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_rain.emission_box_extents = Vector3(16.0, 0.5, 12.0)
	_rain.position = Vector3(0.0, 11.0, 2.0)
	_rain.direction = Vector3(0.18, -1.0, 0.0)
	_rain.spread = 3.0
	_rain.gravity = Vector3.ZERO
	_rain.initial_velocity_min = 9.0
	_rain.initial_velocity_max = 11.0
	var streak := QuadMesh.new()
	streak.size = Vector2(0.025, 0.42)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = RAIN
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.disable_fog = true
	streak.material = m
	_rain.mesh = streak
	_rain.emitting = false
	_rain.visible = false
	add_child(_rain)


## Turns the storm to `amount` (0 to 1) over `seconds`, easing in and out.
func set_storm(amount: float, seconds: float) -> Tween:
	# A newer change of weather takes over from one still under way.
	if _storm_tween:
		_storm_tween.kill()
	var tw := create_tween()
	_storm_tween = tw
	tw.tween_property(self, "storm", clampf(amount, 0.0, 1.0), maxf(seconds, 0.01)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tw


## How much the sea may move: less with reduced motion on.
static func motion() -> float:
	return 0.25 if GameSettings.reduced_motion else 1.0


func rain_falling() -> bool:
	return _rain != null and _rain.emitting


func band_nodes() -> Array[Node3D]:
	return _bands


func _process(delta: float) -> void:
	_time += delta
	_apply_storm()
	var move := motion()
	for i in _bands.size():
		var speed := _band_speed[i]
		var travel := (0.4 + storm * 1.4) * move
		var lift := (0.04 + storm * 0.3) * move
		var band := _bands[i]
		band.position = _band_home[i] + Vector3(sin(_time * speed + float(i) * 1.7) * travel,
				sin(_time * speed * 1.9 + float(i)) * lift + storm * 0.35, 0.0)
		band.scale.y = 1.0 + storm * 0.5


func _apply_storm() -> void:
	if _mat == null:
		return
	var move := motion()
	_mat.set_shader_parameter("swell_height", lerpf(0.1, 0.42, storm) * move)
	_mat.set_shader_parameter("speed", lerpf(0.28, 0.7, storm) * lerpf(1.0, 0.6, 1.0 - move))
	_mat.set_shader_parameter("deep_color", (calm_colours[0] as Color).lerp(STORMY[0], storm))
	_mat.set_shader_parameter("mid_color", (calm_colours[1] as Color).lerp(STORMY[1], storm))
	_mat.set_shader_parameter("crest_color", (calm_colours[2] as Color).lerp(STORMY[2], storm))
	_mat.set_shader_parameter("horizon_color", haze_colour.lerp(Color(0.5, 0.56, 0.62), storm))
	var raining := storm > 0.3
	if _rain.emitting != raining:
		_rain.emitting = raining
		_rain.visible = raining or _rain.visible
	_rain.speed_scale = lerpf(0.5, 1.0, move)
	for i in _bands.size():
		var body := _bands[i].get_node_or_null("Body") as MeshInstance3D
		if body:
			(body.material_override as StandardMaterial3D).albedo_color = (calm_colours[1] as Color).lerp(STORMY[1], storm).lightened(0.06 * float(i % 2))
