shader_type spatial;
render_mode blend_add, unshaded, cull_back, depth_draw_never;

// Soft pulsing rim glow, layered on top of a Wonder Item's own material via
// material_overlay so the paper-craft base look underneath is untouched.
// Additive + rim-only keeps it readable as "this is findable" without
// turning the item into a glowing ball.

uniform vec3 glow_color : source_color = vec3(0.95, 0.78, 0.25);
uniform float rim_power : hint_range(0.5, 6.0) = 2.5;
uniform float pulse_speed : hint_range(0.1, 5.0) = 1.6;
uniform float base_intensity : hint_range(0.0, 1.0) = 0.35;
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.25;

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	float pulse = base_intensity + pulse_intensity * (0.5 + 0.5 * sin(TIME * pulse_speed));
	ALBEDO = glow_color;
	ALPHA = fresnel * pulse;
}
