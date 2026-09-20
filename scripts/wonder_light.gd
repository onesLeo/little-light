extends Node3D
## Wonder Light — the frame story's "small firefly-like spirit" companion
## (see the design doc: it guides the child from story to story and grows
## warmer/brighter as chapters are completed). This is its first visible,
## in-world form for the David & Goliath slice: a soft glowing orb that
## hovers near the Wonder-Walker.
##
## Gameplay purpose: a literal second pair of eyes on the diorama. The
## chapter director can call point_at() to have it drift toward whatever
## the story wants the child looking at (David, a Wonder Item), and
## celebrate() to give it a warm little pulse at good moments — all
## without a single word of dialogue, which matters for the Band A (6-8)
## no-reading play mode.

@export var follow_target_path: NodePath = ^"../Player"
@export var hover_offset: Vector3 = Vector3(0.55, 1.5, 0.45)
@export var follow_speed: float = 2.5
@export var bob_height: float = 0.12
@export var bob_speed: float = 1.8

var _target: Node3D
var _look_target: Node3D = null
var _time: float = randf() * TAU
var _glow_mat: StandardMaterial3D
var _base_energy: float = 1.0
var _pulse_tween: Tween
var _halo: MeshInstance3D
var _halo_mat: StandardMaterial3D
var _halo_tween: Tween
var _sparkles: CPUParticles3D
var _breath_level: float = 0.0

const HALO_ALPHA := 0.55

func _ready() -> void:
	_target = get_node_or_null(follow_target_path) as Node3D
	var glow := get_node_or_null("Glow") as MeshInstance3D
	if glow:
		_glow_mat = glow.get_surface_override_material(0) as StandardMaterial3D
		if _glow_mat:
			_base_energy = _glow_mat.emission_energy_multiplier
	if glow:
		glow.scale = Vector3.ONE * 0.75
	_build_halo()
	_build_sparkles()
	if _target:
		global_position = _target.global_position + hover_offset

func _process(delta: float) -> void:
	_time += delta
	var anchor := _look_target if _look_target else _target
	if anchor == null:
		return
	var desired := anchor.global_position + hover_offset
	desired.y += sin(_time * bob_speed) * bob_height
	if _halo_mat:
		# A slow firefly-like flicker.
		_halo_mat.albedo_color.a = HALO_ALPHA * (0.88 + 0.12 * sin(_time * 3.1) * sin(_time * 1.3 + 1.0))
	global_position = global_position.lerp(desired, clampf(follow_speed * delta, 0.0, 1.0))

## Have the companion drift toward and hover near something the story wants
## noticed (David, a Wonder Item). Pass null to resume following the player.
func point_at(node: Node3D) -> void:
	_look_target = node

## Glows a little brighter and its halo swells while the child breathes in
## (Steady Hands). 0 = normal, 1 = fully breathed in. A celebrate() in progress wins.
func set_breath(level: float) -> void:
	_breath_level = clampf(level, 0.0, 1.0)
	if _glow_mat and not (_pulse_tween and _pulse_tween.is_valid() and _pulse_tween.is_running()):
		_glow_mat.emission_energy_multiplier = _base_energy * (1.0 + 0.45 * _breath_level)
	if _halo and not (_halo_tween and _halo_tween.is_valid() and _halo_tween.is_running()):
		_halo.scale = Vector3.ONE * (1.0 + 0.5 * _breath_level)


## A brief warm brighten — used for "found something" / "well done" beats.
## Kept modest on purpose: the environment bloom turns big emission boosts
## into a huge flat disc.
func celebrate() -> void:
	if _glow_mat:
		if _pulse_tween and _pulse_tween.is_valid():
			_pulse_tween.kill()
		_pulse_tween = create_tween()
		_pulse_tween.tween_property(_glow_mat, "emission_energy_multiplier", _base_energy * 1.5, 0.2)
		_pulse_tween.tween_property(_glow_mat, "emission_energy_multiplier", _base_energy, 0.7)
	if _halo:
		if _halo_tween and _halo_tween.is_valid():
			_halo_tween.kill()
		_halo_tween = create_tween()
		_halo_tween.tween_property(_halo, "scale", Vector3.ONE * 1.9, 0.2).set_trans(Tween.TRANS_SINE)
		_halo_tween.tween_property(_halo, "scale", Vector3.ONE, 0.8).set_trans(Tween.TRANS_SINE)
	if _sparkles:
		_sparkles.restart()
		_sparkles.emitting = true


func _soft_dot() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	g.colors = PackedColorArray([Color(1.0, 0.96, 0.75, 1.0), Color(1.0, 0.86, 0.5, 0.35), Color(1.0, 0.8, 0.4, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	return tex


func _glow_material(color: Color, particles: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES if particles else BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = _soft_dot()
	m.albedo_color = color
	if particles:
		m.vertex_color_use_as_albedo = true
	return m


## Soft additive halo around the orb, so it reads as a glowing firefly
## rather than a hard yellow ball.
func _build_halo() -> void:
	_halo_mat = _glow_material(Color(1.0, 0.9, 0.6, HALO_ALPHA), false)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.95, 0.95)
	quad.material = _halo_mat
	_halo = MeshInstance3D.new()
	_halo.name = "Halo"
	_halo.mesh = quad
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_halo)


func _build_sparkles() -> void:
	_sparkles = CPUParticles3D.new()
	_sparkles.name = "Sparkles"
	_sparkles.amount = 16
	_sparkles.lifetime = 1.0
	_sparkles.one_shot = true
	_sparkles.explosiveness = 0.95
	_sparkles.emitting = false
	_sparkles.local_coords = false
	_sparkles.direction = Vector3.UP
	_sparkles.spread = 180.0
	_sparkles.initial_velocity_min = 0.5
	_sparkles.initial_velocity_max = 1.1
	_sparkles.gravity = Vector3(0.0, 0.2, 0.0)
	_sparkles.damping_min = 0.6
	_sparkles.damping_max = 1.0
	_sparkles.scale_amount_min = 0.5
	_sparkles.scale_amount_max = 1.2
	var quad := QuadMesh.new()
	quad.size = Vector2(0.09, 0.09)
	quad.material = _glow_material(Color(1.0, 0.9, 0.55, 1.0), true)
	_sparkles.mesh = quad
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
	_sparkles.color_ramp = fade
	_sparkles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_sparkles)
