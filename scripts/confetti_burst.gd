extends CPUParticles3D
## One-shot confetti pop, built entirely in code (no assets). Call burst()
## with a world position; reuse the same node for every celebration.
## Pieces are small soft-edged chips that flutter (flip edge-on), sway, catch
## a glint, then drift down and fade, rather than flat spinning rectangles.

const COLORS := [
	Color(0.98, 0.72, 0.12), Color(0.93, 0.32, 0.25), Color(0.20, 0.50, 0.92),
	Color(0.30, 0.72, 0.35), Color(0.82, 0.35, 0.78), Color(1.0, 0.97, 0.85),
	Color(0.10, 0.70, 0.72), Color(1.0, 0.55, 0.15), Color(0.98, 0.60, 0.75),
	Color(0.55, 0.78, 0.98), Color(0.98, 0.88, 0.35), Color(0.55, 0.40, 0.85),
]

const PIECE_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

uniform float aspect = 1.6;

varying vec4 v_col;
varying float v_face;
varying float v_round;

void vertex() {
	float id = float(INSTANCE_ID);
	float h1 = fract(sin(id * 12.9898) * 43758.5453);
	float h2 = fract(sin(id * 78.233 + 1.7) * 24634.6345);
	float h3 = fract(sin(id * 39.346 + 4.1) * 12345.6789);
	float age = INSTANCE_CUSTOM.y;
	float s = length(MODEL_MATRIX[0].xyz);

	// Camera-facing billboard at the particle position.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);

	// Lazy side-to-side sway once the initial pop has slowed down.
	float sway_t = TIME * (1.6 + h2 * 1.6) + h1 * 6.2831;
	float sway_amt = smoothstep(0.12, 0.5, age);
	MODELVIEW_MATRIX[3].xy += vec2(sin(sway_t), 0.35 * sin(sway_t * 1.7 + 1.3)) * 0.22 * sway_amt;

	// Flutter: squash the chip along its own axis, like it is flipping in the air.
	float flip = cos(TIME * (3.0 + h3 * 4.0) + h1 * 6.2831);
	v_face = flip;
	vec2 p = VERTEX.xy;
	p.y *= mix(0.15, 1.0, abs(flip));

	float a = h2 * 6.2831 + TIME * (h3 - 0.5) * 3.0;
	p = vec2(p.x * cos(a) - p.y * sin(a), p.x * sin(a) + p.y * cos(a));

	VERTEX = vec3(p * s, 0.0);
	v_col = COLOR;
	v_round = h1;
}

void fragment() {
	// Rounded-rectangle SDF: some chips are near-rectangles, some pills/dots.
	vec2 half_ext = vec2(aspect, 1.0) * 0.5;
	vec2 p = (UV - 0.5) * vec2(aspect, 1.0);
	float r = mix(0.1, 0.5, v_round * v_round);
	vec2 q = abs(p) - (half_ext - vec2(r));
	float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
	float shape = 1.0 - smoothstep(-0.05, 0.0, d);

	// Back side is slightly darker; a quick glint when the chip faces the camera.
	float shade = 0.82 + 0.18 * v_face;
	float glint = pow(max(v_face, 0.0), 10.0) * 0.28;
	ALBEDO = v_col.rgb * shade + vec3(glint);
	ALPHA = shape * v_col.a;
}
"""

func _ready() -> void:
	one_shot = true
	emitting = false
	explosiveness = 1.0
	lifetime = 3.4
	direction = Vector3.UP
	spread = 60.0
	gravity = Vector3(0.0, -4.0, 0.0)
	damping_min = 2.6
	damping_max = 3.4
	emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	emission_sphere_radius = 0.3
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var quad := QuadMesh.new()
	quad.size = Vector2(0.2, 0.125)
	var shader := Shader.new()
	shader.code = PIECE_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
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

	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	color_ramp = fade

	var size_curve := Curve.new()
	size_curve.add_point(Vector2(0.0, 0.0))
	size_curve.add_point(Vector2(0.08, 1.0))
	size_curve.add_point(Vector2(1.0, 0.6))
	scale_amount_curve = size_curve


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
