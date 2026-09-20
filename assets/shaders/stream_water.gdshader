shader_type spatial;
// Paper-craft water for the brook: shallow-to-deep tint from the water depth,
// thin ripple lines that flow along the stream, a foam rim where the water
// meets the bank, white streaks down the waterfall, and a little sparkle.
// World-space patterns, so it works on the imported mesh whatever its UVs are.
render_mode blend_mix, depth_draw_opaque, cull_disabled, specular_schlick_ggx;

uniform vec3 shallow_color : source_color = vec3(0.62, 0.90, 0.97);
uniform vec3 deep_color : source_color = vec3(0.22, 0.60, 0.84);
uniform vec3 foam_color : source_color = vec3(0.97, 0.99, 1.0);
uniform vec2 flow_dir = vec2(-0.35, 0.94);     // world XZ direction the brook flows
uniform float flow_speed : hint_range(0.0, 3.0) = 0.7;
uniform float ripple_scale : hint_range(0.2, 6.0) = 1.6;
uniform float foam_width : hint_range(0.02, 1.0) = 0.28;
uniform float fall_speed : hint_range(0.0, 8.0) = 3.2;
uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;

varying vec3 world_pos;
varying vec3 world_normal;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * vnoise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	bool fall = world_normal.y < 0.6;

	// How much water we are looking through (used for tint and the shore foam).
	float raw_depth = texture(depth_tex, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, raw_depth);
	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_pos.xyz /= view_pos.w;
	float thickness = max(-view_pos.z + VERTEX.z, 0.0);

	float lines = 0.0;
	float streak = 0.0;
	float sparkle = 0.0;
	if (fall) {
		vec2 uv = vec2(world_pos.x * 5.0 + world_pos.z * 5.0, world_pos.y * 1.1 + TIME * fall_speed);
		float n = fbm(uv);
		streak = smoothstep(0.50, 0.75, n);
	} else {
		vec2 flow = normalize(flow_dir);
		vec2 uv = world_pos.xz * ripple_scale - flow * TIME * flow_speed;
		float w = fbm(uv + fbm(uv * 0.7 + 3.1) * 0.6);
		lines = smoothstep(0.40, 0.48, abs(fract(w * 4.0) - 0.5));
		vec2 cell = floor(world_pos.xz * 9.0);
		float r = hash21(cell);
		sparkle = smoothstep(0.965, 1.0, r) * (0.5 + 0.5 * sin(TIME * 4.0 + r * 60.0));
	}

	float deep_mix = smoothstep(0.08, 1.4, thickness);
	vec3 col = mix(shallow_color, deep_color, deep_mix);
	col = mix(col, foam_color, lines * 0.32);

	float wobble = (vnoise(world_pos.xz * 5.0 + TIME * 0.4) - 0.5) * 0.12;
	float t_w = thickness + wobble;
	// A rim band, not a fill: shallow tops of submerged rocks stay water-coloured.
	float shore = smoothstep(0.02, 0.10, t_w) * (1.0 - smoothstep(0.10, foam_width, t_w));
	shore = fall ? 0.0 : shore;
	col = mix(col, foam_color, clamp(shore * 0.9 + streak * 0.55, 0.0, 1.0));
	col += vec3(sparkle * 0.6);

	ALBEDO = col;
	EMISSION = col * 0.12;
	ROUGHNESS = 0.35;
	SPECULAR = 0.35;
	ALPHA = clamp(mix(0.62, 0.96, smoothstep(0.02, 0.5, thickness)) + shore * 0.3, 0.0, 1.0);
	if (fall) {
		ALPHA = 0.94;
	}
}
