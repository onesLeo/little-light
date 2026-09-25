shader_type spatial;
// The ink rim for paper_tree_sway.gdshader: the same mesh pushed out along its
// (smooth) normals and drawn from the inside, swaying exactly like the plant.
render_mode cull_front, unshaded, shadows_disabled;

uniform float sway_amount : hint_range(0.0, 0.3) = 0.05;
uniform float sway_speed : hint_range(0.0, 3.0) = 0.8;
uniform float line = 0.05;
uniform vec3 ink_color : source_color = vec3(0.1, 0.06, 0.04);

void vertex() {
	VERTEX += NORMAL * line;
	vec3 anchor = MODEL_MATRIX[3].xyz;
	float phase = anchor.x * 0.37 + anchor.z * 0.29;
	float h = max(VERTEX.y, 0.0);
	float bend = h * h * 0.12;
	float gust = sin(TIME * sway_speed + phase) + 0.4 * sin(TIME * sway_speed * 2.1 + phase * 1.3);
	VERTEX.x += gust * sway_amount * bend;
	VERTEX.z += cos(TIME * sway_speed * 0.7 + phase) * sway_amount * 0.5 * bend;
}

void fragment() {
	ALBEDO = ink_color;
}
