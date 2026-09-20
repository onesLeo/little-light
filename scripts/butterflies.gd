extends Node3D
## A few paper butterflies drifting over the meadow. They flap, wander between
## random spots, and flutter away when the Wonder-Walker gets close.

@export var count: int = 8
@export var area_min: Vector2 = Vector2(-7.5, -4.0)
@export var area_max: Vector2 = Vector2(9.0, 9.0)
@export var scare_radius: float = 2.3
@export var min_height: float = 0.5
@export var max_height: float = 1.5

const SoundBus := preload("res://scripts/sound_bus.gd")
const SoundLibrary := preload("res://scripts/sound_library.gd")

const COLORS := [Color(1.0, 0.86, 0.3), Color(1.0, 1.0, 0.95), Color(1.0, 0.6, 0.72),
		Color(0.6, 0.78, 1.0), Color(1.0, 0.66, 0.3)]

var _flies: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _player: Node3D
var _time: float = 0.0
var _wing_tex: ImageTexture
var _flutter_players: Array[AudioStreamPlayer3D] = []
var _flutter_cool: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_player = get_parent().get_node_or_null("Player") as Node3D
	_wing_tex = _make_wing_texture()
	_make_flutter_players()
	for i in count:
		_flies.append(_make_fly(i))


func _random_spot() -> Vector3:
	return Vector3(_rng.randf_range(area_min.x, area_max.x), _rng.randf_range(min_height, max_height),
			_rng.randf_range(area_min.y, area_max.y))


func _clamp_spot(p: Vector3) -> Vector3:
	return Vector3(clampf(p.x, area_min.x, area_max.x), clampf(p.y, min_height, max_height + 0.6),
			clampf(p.z, area_min.y, area_max.y))


func _make_fly(i: int) -> Dictionary:
	var root := Node3D.new()
	root.name = "Butterfly%d" % i
	root.position = _random_spot()
	add_child(root)
	var col: Color = COLORS[i % COLORS.size()]
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_texture = _wing_tex
	mat.albedo_color = col
	var hinges: Array[Node3D] = []
	for side in [-1.0, 1.0]:
		var hinge := Node3D.new()
		root.add_child(hinge)
		var quad := QuadMesh.new()
		quad.size = Vector2(0.13, 0.11)
		quad.material = mat
		var wing := MeshInstance3D.new()
		wing.mesh = quad
		wing.rotation_degrees.x = -90.0
		wing.position = Vector3(side * 0.06, 0.0, 0.0)
		wing.scale.x = -side
		wing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hinge.add_child(wing)
		hinges.append(hinge)
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.012
	body_mesh.height = 0.11
	body_mesh.radial_segments = 6
	body_mesh.rings = 2
	var body_mat := StandardMaterial3D.new()
	body_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	body_mat.albedo_color = Color(0.2, 0.13, 0.1)
	body_mesh.material = body_mat
	var body := MeshInstance3D.new()
	body.mesh = body_mesh
	body.rotation_degrees.x = 90.0
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(body)
	return {"root": root, "left": hinges[0], "right": hinges[1], "target": _random_spot(), "retarget": _rng.randf_range(0.5, 3.0),
			"speed": 0.7, "speed_now": 0.7, "cool": 0.0, "phase": _rng.randf() * TAU, "yaw": 0.0}


func _process(delta: float) -> void:
	_time += delta
	_flutter_cool = maxf(_flutter_cool - delta, 0.0)
	for f in _flies:
		var root: Node3D = f["root"]
		var pos := root.position
		var scared := false
		var away := Vector3.ZERO
		if _player:
			away = pos - _player.global_position
			away.y = 0.0
			scared = away.length() < scare_radius
		f["cool"] = maxf(float(f["cool"]) - delta, 0.0)
		f["retarget"] = float(f["retarget"]) - delta
		if scared and float(f["cool"]) <= 0.0:
			var dir := away.normalized() if away.length() > 0.01 else Vector3.RIGHT
			f["target"] = _clamp_spot(pos + dir * 3.5 + Vector3(0.0, _rng.randf_range(0.2, 0.6), 0.0))
			_flutter(pos)
			f["speed"] = 2.4
			f["cool"] = 1.0
			f["retarget"] = 2.0
		elif float(f["retarget"]) <= 0.0:
			f["target"] = _random_spot()
			f["speed"] = 0.7
			f["retarget"] = _rng.randf_range(2.5, 5.0)
		f["speed_now"] = lerpf(float(f["speed_now"]), float(f["speed"]), clampf(delta * 3.0, 0.0, 1.0))
		var to_target: Vector3 = f["target"] - pos
		if to_target.length() > 0.05:
			var step := to_target.normalized() * minf(float(f["speed_now"]) * delta, to_target.length())
			pos += step
			var flat := Vector2(to_target.x, to_target.z)
			if flat.length() > 0.02:
				f["yaw"] = lerp_angle(float(f["yaw"]), atan2(-to_target.x, -to_target.z), clampf(delta * 4.0, 0.0, 1.0))
		pos.y += sin(_time * 3.0 + float(f["phase"])) * 0.25 * delta
		root.position = pos
		root.rotation = Vector3(0.0, f["yaw"], 0.0)
		var flap := 0.35 + 0.75 * absf(sin(_time * (14.0 if scared else 10.0) + float(f["phase"])))
		(f["left"] as Node3D).rotation.z = -flap
		(f["right"] as Node3D).rotation.z = flap


## A rounded wing with a darker rim and a light spot, white so it takes any tint.
func _make_wing_texture() -> ImageTexture:
	var w := 64
	var h := 56
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			# Wing shape: an ellipse hinged at the left edge, plus a small lower lobe.
			var p := Vector2(float(x) / w, float(y) / h)
			var e1 := Vector2((p.x - 0.05) / 0.95, (p.y - 0.36) / 0.36).length()
			var e2 := Vector2((p.x - 0.12) / 0.62, (p.y - 0.74) / 0.24).length()
			var inside := minf(e1, e2)
			if inside > 1.0:
				continue
			var shade := 1.0
			if inside > 0.86:
				shade = 0.62
			var spot := Vector2((p.x - 0.55) / 0.11, (p.y - 0.34) / 0.13).length()
			if spot < 1.0:
				shade = 1.0
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, 1.0))
				continue
			img.set_pixel(x, y, Color(shade, shade, shade, 1.0))
	return ImageTexture.create_from_image(img)


## A soft rustle of wings when a butterfly takes off. A few players are shared,
## and only one rustle can start every 0.4 s, so a whole group flying up is not loud.
func _make_flutter_players() -> void:
	var stream := SoundLibrary.load_stream(SoundLibrary.FLUTTER)
	for i in 3:
		var p := AudioStreamPlayer3D.new()
		p.stream = stream
		p.top_level = true
		p.bus = SoundBus.EFFECTS
		p.volume_db = -10.0
		p.unit_size = 2.0
		p.max_distance = 15.0
		add_child(p)
		_flutter_players.append(p)


func _flutter(at: Vector3) -> void:
	if _flutter_cool > 0.0:
		return
	for p in _flutter_players:
		if not p.playing:
			p.global_position = at
			p.pitch_scale = _rng.randf_range(0.9, 1.2)
			p.play()
			_flutter_cool = 0.4
			return
