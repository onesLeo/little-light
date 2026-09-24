shader_type spatial;
// Trees, bushes and grass on Noah's mountain (see ark_mountain.gd), drawn as
// MultiMeshes. The per-instance colour tints each one; the higher a vertex, the
// more the breeze moves it, and each plant's own position offsets its phase so
// they never sway in step. paper_tree_ink.gdshader draws the matching ink rim.
render_mode specular_disabled;

uniform float sway_amount : hint_range(0.0, 0.3) = 0.05;
uniform float sway_speed : hint_range(0.0, 3.0) = 0.8;

varying vec3 tint;

void vertex() {
	tint = COLOR.rgb;
	vec3 anchor = MODEL_MATRIX[3].xyz;
	float phase = anchor.x * 0.37 + anchor.z * 0.29;
	float h = max(VERTEX.y, 0.0);
	float bend = h * h * 0.12;
	float gust = sin(TIME * sway_speed + phase) + 0.4 * sin(TIME * sway_speed * 2.1 + phase * 1.3);
	VERTEX.x += gust * sway_amount * bend;
	VERTEX.z += cos(TIME * sway_speed * 0.7 + phase) * sway_amount * 0.5 * bend;
}

void fragment() {
	ALBEDO = tint;
	ROUGHNESS = 1.0;
}
