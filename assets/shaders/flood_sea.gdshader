shader_type spatial;
// The flood around Noah's Ark: from outside on the mountain (ark_mountain.gd) and
// through the shelter window (ark_shelter.gd). Slow rolling swells, a few flat tones
// like layered paper, thin cream strokes along the crests drifting with the wind, and
// a haze that melts it into the sky at the horizon. Calm, never rough. World-space
// patterns on a flat, subdivided plane.
render_mode cull_disabled, specular_disabled;

uniform vec3 deep_color : source_color = vec3(0.25, 0.39, 0.51);
uniform vec3 mid_color : source_color = vec3(0.35, 0.51, 0.62);
uniform vec3 crest_color : source_color = vec3(0.52, 0.66, 0.74);
uniform vec3 foam_color : source_color = vec3(0.93, 0.95, 0.91);
uniform vec3 horizon_color : source_color = vec3(0.62, 0.7, 0.78);
uniform float swell_height = 0.18;
uniform float swell_length = 10.0;
uniform float speed = 0.35;
uniform float haze_start = 25.0;
uniform float haze_end = 140.0;
// 0 takes the scene's light; 1 keeps its own colours (the shelter's warm lamp must not tint the sea).
uniform float self_lit : hint_range(0.0, 1.0) = 0.0;

varying vec3 world_pos;

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

// Three long swells crossing at different angles, in -1..1.
float wave(vec2 p, float t) {
	float k = 6.2831 / swell_length;
	float h = sin(dot(p, vec2(0.8, 0.6)) * k + t * 2.0);
	h += 0.6 * sin(dot(p, vec2(-0.35, 0.94)) * k * 1.7 + t * 2.6 + 1.3);
	h += 0.3 * sin(dot(p, vec2(0.96, -0.28)) * k * 3.1 + t * 3.4 + 2.1);
	return h / 1.9;
}

void vertex() {
	vec3 flat_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * speed;
	float swell = wave(flat_pos.xz, t);
	VERTEX.y += swell * swell_height;
	world_pos = flat_pos + vec3(0.0, swell * swell_height, 0.0);
	float e = 0.4;
	float dx = (wave(flat_pos.xz + vec2(e, 0.0), t) - wave(flat_pos.xz - vec2(e, 0.0), t)) * swell_height / (2.0 * e);
	float dz = (wave(flat_pos.xz + vec2(0.0, e), t) - wave(flat_pos.xz - vec2(0.0, e), t)) * swell_height / (2.0 * e);
	NORMAL = normalize(vec3(-dx, 1.0, -dz));
}

void fragment() {
	// Worked out again per pixel: the vertices are metres apart, and interpolating their
	// heights would break the soft bands into shards.
	float swell = wave(world_pos.xz, TIME * speed);
	// Flat tones with soft edges: troughs deep, faces mid, tops light.
	vec3 col = mix(deep_color, mid_color, smoothstep(-0.25, -0.12, swell));
	col = mix(col, crest_color, smoothstep(0.55, 0.64, swell));
	// A thin cream stroke just below each crest, broken up so it reads as hand-drawn dashes.
	float stroke = smoothstep(0.74, 0.78, swell) * (1.0 - smoothstep(0.84, 0.9, swell));
	float dashes = step(0.42, vnoise(world_pos.xz * vec2(0.45, 0.3) + vec2(TIME * 0.06, 0.0)));
	float dist = length(world_pos - CAMERA_POSITION_WORLD);
	float haze = smoothstep(haze_start, haze_end, dist);
	col = mix(col, foam_color, stroke * dashes * 0.55 * (1.0 - haze));
	col = mix(col, horizon_color, haze);
	ALBEDO = col * (1.0 - self_lit);
	EMISSION = col * self_lit;
	ROUGHNESS = 0.9;
}
