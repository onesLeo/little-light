shader_type spatial;
// Grass tufts, tiny flowers and pebbles for the meadow (see meadow_dressing.gd).
// One shader for all three: the mesh's UV.x says which part a vertex belongs to
// (0 grass blade, 1 flower stem, 2 petal, 3 flower centre, 4 pebble) and UV.y is
// how far up it is (0 at the ground, 1 at the tip), which drives the wind sway.
// The per-instance colour tints blades, petals and pebbles.
render_mode cull_disabled, specular_disabled;

uniform float sway_amount : hint_range(0.0, 0.4) = 0.10;
uniform float sway_speed : hint_range(0.0, 4.0) = 1.4;
uniform vec3 stem_color : source_color = vec3(0.34, 0.62, 0.27);
uniform vec3 center_color : source_color = vec3(1.0, 0.82, 0.2);
// Set every frame by meadow_dressing.gd: blades lean away from the Wonder-Walker.
uniform vec3 player_pos = vec3(1000.0, 0.0, 1000.0);
uniform float bend_radius : hint_range(0.2, 3.0) = 1.3;
uniform float bend_strength : hint_range(0.0, 0.6) = 0.30;

varying vec3 tint;
varying float part;
varying float hfrac;

void vertex() {
	part = UV.x;
	hfrac = UV.y;
	tint = COLOR.rgb;
	vec3 anchor = MODEL_MATRIX[3].xyz;
	float phase = anchor.x * 0.6 + anchor.z * 0.45;
	float bend = hfrac * hfrac;
	float gust = sin(TIME * sway_speed + phase) + 0.5 * sin(TIME * sway_speed * 2.3 + phase * 1.7);
	VERTEX.x += gust * sway_amount * bend;
	VERTEX.z += cos(TIME * sway_speed * 0.8 + phase) * sway_amount * 0.5 * bend;
	vec2 away = anchor.xz - player_pos.xz;
	float dist = length(away);
	float push = 1.0 - smoothstep(0.15, bend_radius, dist);
	vec2 dir = dist > 0.001 ? away / dist : vec2(1.0, 0.0);
	vec3 world_push = vec3(dir.x, 0.0, dir.y) * push * bend_strength * bend;
	VERTEX += inverse(mat3(MODEL_MATRIX)) * world_push;
	VERTEX.y *= 1.0 - push * 0.30 * bend;
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	vec3 c;
	if (part < 0.5) {
		c = tint * mix(0.50, 0.90, hfrac);
	} else if (part < 1.5) {
		c = stem_color;
	} else if (part < 2.5) {
		c = tint;
	} else if (part < 3.5) {
		c = center_color;
	} else {
		c = tint;
	}
	ALBEDO = c;
	ROUGHNESS = 1.0;
}
