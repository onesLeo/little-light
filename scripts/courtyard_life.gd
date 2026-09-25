extends Node3D
## The small moving things that keep Jesse's courtyard from standing still: cloud shadows
## drifting slowly across the ground (and over the people), a few leaves carried on the breeze,
## two doves circling high up and two more pecking in the courtyard, which flutter off when
## the child walks up to them and land a little way away. Built by jesses_house.gd, which sets
## `breeze` (0 to 1) for the gust at the anointing.
const Paper := preload("res://scripts/camp_paper.gd")

## How far the shadows travel before they wrap round to the other side, and how fast.
const CLOUD_SPAN := 44.0
const CLOUD_SPEED := 0.45
const DOVE := Color(0.93, 0.92, 0.88)
const DOVE_GREY := Color(0.72, 0.72, 0.74)
const BEAK := Color(0.85, 0.55, 0.45)
## Where the ground doves peck, and how near the child comes before they take off.
const DOVE_SPOTS: Array[Vector3] = [Vector3(5.2, 0.0, -4.4), Vector3(5.9, 0.0, -4.9)]
const DOVE_SHY := 1.8

## 0 to 1, from jesses_house.gd: the gust at the anointing blows the leaves faster.
var breeze: float = 0.0

var _time: float = 0.0
var _clouds: Array[Node3D] = []
var _leaves: CPUParticles3D
var _flyers: Array[Node3D] = []
var _walkers: Array[Node3D] = []
## Per ground dove: seconds left in the air (0 when on the ground).
var _airborne: Array[float] = []
var _player: Node3D


func _ready() -> void:
	_cloud_shadows()
	_breeze_leaves()
	for i in 2:
		var dove := _dove("FlyingDove%d" % i)
		add_child(dove)
		_flyers.append(dove)
	for i in DOVE_SPOTS.size():
		var dove := _dove("GroundDove%d" % i)
		add_child(dove)
		dove.position = DOVE_SPOTS[i]
		dove.rotation.y = 1.2 + i * 2.1
		_walkers.append(dove)
		_airborne.append(0.0)


## The doves on the ground, for tests.
func ground_doves() -> Array[Node3D]:
	return _walkers


func cloud_shadows() -> Array[Node3D]:
	return _clouds


func _process(delta: float) -> void:
	_time += delta
	for cloud in _clouds:
		cloud.position.x += CLOUD_SPEED * delta * (1.0 + breeze)
		if cloud.position.x > CLOUD_SPAN * 0.5:
			cloud.position.x -= CLOUD_SPAN
	if _leaves:
		_leaves.speed_scale = 1.0 + breeze * 2.5
	# Two doves circle high over the courtyard, a little apart, wings beating then gliding.
	for i in _flyers.size():
		var dove := _flyers[i]
		var angle := _time * 0.16 + i * 0.7
		var radius := 9.0 + i * 1.4
		dove.position = Vector3(cos(angle) * radius, 7.5 + i * 0.6 + sin(_time * 0.5 + i) * 0.3, -2.0 + sin(angle) * radius * 0.8)
		dove.rotation.y = -angle
		_flap(dove, 0.5 + 0.5 * sin(_time * 0.9 + i) > 0.35, 11.0)
	_ground_doves(delta)


func _ground_doves(delta: float) -> void:
	if _player == null and get_parent() and get_parent().get_parent():
		_player = get_parent().get_parent().get_node_or_null("Player") as Node3D
	var player := _player
	for i in _walkers.size():
		var dove := _walkers[i]
		if _airborne[i] > 0.0:
			_airborne[i] -= delta
			_flap(dove, true, 16.0)
			if _airborne[i] <= 0.0:
				dove.position.y = 0.0
				_flap(dove, false, 0.0)
			continue
		# Pecking: the head dips now and then, and the dove turns a little.
		var head := dove.get_node("Body/Head") as Node3D
		var peck := maxf(sin(_time * 2.3 + i * 1.7), 0.0)
		head.position.y = 0.1 - peck * peck * 0.07
		dove.rotation.y += sin(_time * 0.4 + i) * delta * 0.3
		if player and Vector2(player.global_position.x - dove.global_position.x, player.global_position.z - dove.global_position.z).length() < DOVE_SHY:
			_take_off(i, player.global_position)


## A ground dove flutters up and lands a few metres away from the child, still in the courtyard.
func _take_off(i: int, away_from: Vector3) -> void:
	var dove := _walkers[i]
	var from := dove.position
	var away := Vector3(from.x - away_from.x, 0.0, from.z - away_from.z).normalized()
	if away == Vector3.ZERO:
		away = Vector3.RIGHT
	var to := from + away * 3.0
	to.x = clampf(to.x, -9.0, 10.0)
	to.z = clampf(to.z, -5.0, 8.0)
	dove.rotation.y = atan2(-(to.x - from.x), -(to.z - from.z))
	_airborne[i] = 1.4
	var tw := create_tween()
	tw.tween_property(dove, "position", (from + to) * 0.5 + Vector3(0.0, 1.3, 0.0), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(dove, "position", to, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _flap(dove: Node3D, beating: bool, speed: float) -> void:
	var lift := sin(_time * speed) * 0.7 if beating else 0.12
	for side in ["L", "R"]:
		var wing := dove.get_node("Body/Wing" + side) as Node3D
		wing.rotation.z = lift * (1.0 if side == "L" else -1.0)


## A small paper dove, facing -Z like the people: round body, head, tail and two wings.
func _dove(dove_name: String) -> Node3D:
	var dove := Node3D.new()
	dove.name = dove_name
	var body := Node3D.new()
	body.name = "Body"
	body.position = Vector3(0.0, 0.12, 0.0)
	dove.add_child(body)
	Paper.part(body, "Breast", Paper.sphere(0.1, 7), DOVE, Vector3.ZERO, Vector3.ZERO, Vector3(0.9, 0.85, 1.4), 0.008)
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0.0, 0.1, -0.13)
	body.add_child(head)
	Paper.part(head, "Skull", Paper.sphere(0.055, 6), DOVE, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, 0.006)
	Paper.part(head, "Beak", Paper.cylinder(0.012, 0.04, 4, 0.0), BEAK, Vector3(0.0, -0.005, -0.06), Vector3(-PI * 0.5, 0.0, 0.0), Vector3.ONE, 0.0)
	Paper.part(body, "Tail", Paper.box(Vector3(0.09, 0.02, 0.12)), DOVE_GREY, Vector3(0.0, 0.02, 0.15), Vector3(0.25, 0.0, 0.0), Vector3.ONE, 0.006)
	for side in ["L", "R"]:
		var wing := Node3D.new()
		wing.name = "Wing" + side
		var sx := -1.0 if side == "L" else 1.0
		wing.position = Vector3(sx * 0.06, 0.04, 0.0)
		body.add_child(wing)
		Paper.part(wing, "Feathers", Paper.box(Vector3(0.18, 0.015, 0.12)), DOVE_GREY.lightened(0.1), Vector3(sx * 0.09, 0.0, 0.02), Vector3.ZERO, Vector3.ONE, 0.006)
	return dove


## Three soft cloud shadows, each two or three overlapping blobs, spread out along the drift.
## They are decals, so they darken the ground and anyone standing in them.
func _cloud_shadows() -> void:
	var blob := Paper.glow_texture(Color(0.32, 0.25, 0.2, 0.42), Color(0.32, 0.25, 0.2, 0.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1607
	for c in 3:
		var cloud := Node3D.new()
		cloud.name = "CloudShadow%d" % c
		cloud.position = Vector3(-CLOUD_SPAN * 0.5 + c * CLOUD_SPAN / 3.0 + rng.randf_range(-3.0, 3.0), 1.5, rng.randf_range(-7.0, 8.0))
		add_child(cloud)
		for b in 3:
			var decal := Decal.new()
			decal.name = "Blob%d" % b
			var size := rng.randf_range(7.0, 10.0)
			decal.size = Vector3(size * 1.3, 5.0, size)
			decal.position = Vector3(rng.randf_range(-3.5, 3.5), 0.0, rng.randf_range(-2.2, 2.2))
			decal.texture_albedo = blob
			decal.normal_fade = 0.4
			decal.cull_mask = 1
			cloud.add_child(decal)
		_clouds.append(cloud)


## A few olive leaves and dry petals drifting across the courtyard on the breeze.
func _breeze_leaves() -> void:
	_leaves = CPUParticles3D.new()
	_leaves.name = "BreezeLeaves"
	_leaves.position = Vector3(-4.0, 1.4, 0.0)
	_leaves.amount = 14
	_leaves.lifetime = 9.0
	_leaves.preprocess = 9.0
	var quad := QuadMesh.new()
	quad.size = Vector2(0.09, 0.045)
	var leaf := StandardMaterial3D.new()
	leaf.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	leaf.vertex_color_use_as_albedo = true
	leaf.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	leaf.cull_mode = BaseMaterial3D.CULL_DISABLED
	quad.material = leaf
	_leaves.mesh = quad
	_leaves.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_leaves.emission_box_extents = Vector3(9.0, 1.0, 9.0)
	_leaves.direction = Vector3(1.0, 0.08, 0.3)
	_leaves.spread = 14.0
	_leaves.gravity = Vector3(0.0, -0.04, 0.0)
	_leaves.initial_velocity_min = 0.5
	_leaves.initial_velocity_max = 0.9
	_leaves.angle_min = -180.0
	_leaves.angle_max = 180.0
	_leaves.angular_velocity_min = -90.0
	_leaves.angular_velocity_max = 90.0
	var colors := Gradient.new()
	colors.set_color(0, Color(0.52, 0.6, 0.36))
	colors.set_color(1, Color(0.9, 0.82, 0.6))
	_leaves.color_initial_ramp = colors
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.1, 0.85, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	_leaves.color_ramp = fade
	leaf.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	add_child(_leaves)
