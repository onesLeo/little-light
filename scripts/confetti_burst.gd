extends CPUParticles3D
## One-shot paper-confetti pop, built entirely in code (no assets). Call
## burst() with a world position; reuse the same node for every celebration.

const COLORS := [
	Color(0.95, 0.78, 0.25), Color(0.95, 0.45, 0.35), Color(0.35, 0.60, 0.90),
	Color(0.45, 0.75, 0.40), Color(0.85, 0.50, 0.80), Color(1.0, 0.95, 0.75),
]

func _ready() -> void:
	one_shot = true
	emitting = false
	explosiveness = 1.0
	lifetime = 2.6
	direction = Vector3.UP
	spread = 55.0
	gravity = Vector3(0.0, -5.5, 0.0)
	damping_min = 0.6
	damping_max = 1.4
	angle_min = -180.0
	angle_max = 180.0
	angular_velocity_min = -420.0
	angular_velocity_max = 420.0
	emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	emission_sphere_radius = 0.3

	var quad := QuadMesh.new()
	quad.size = Vector2(0.3, 0.2)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	quad.material = mat
	mesh = quad

	var ramp := Gradient.new()
	ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets := PackedFloat32Array()
	for i in COLORS.size():
		offsets.append(float(i) / COLORS.size())
	ramp.offsets = offsets
	ramp.colors = PackedColorArray(COLORS)
	color_initial_ramp = ramp


func burst(world_pos: Vector3, count: int = 90, radius: float = 0.3, speed: float = 5.5, piece_scale: float = 1.0) -> void:
	amount = count
	emission_sphere_radius = radius
	initial_velocity_min = speed * 0.6
	initial_velocity_max = speed * 1.25
	scale_amount_min = piece_scale * 0.7
	scale_amount_max = piece_scale * 1.2
	global_position = world_pos
	restart()
	emitting = true
