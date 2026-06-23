shader_type canvas_item;
render_mode unshaded;

uniform vec4 shadow_color : source_color = vec4(0.03, 0.025, 0.02, 0.30);
uniform float alpha_strength : hint_range(0.0, 1.0) = 0.0;
uniform float edge_softness : hint_range(0.01, 0.9) = 0.1;

void fragment() {
	vec2 centered_uv = (UV - vec2(0.5)) * 2.0;
	float distance_from_center = length(centered_uv);
	float inner_edge = clamp(1.0 - edge_softness, 0.0, 0.99);
	float mask = 1.0 - smoothstep(inner_edge, 1.0, distance_from_center);
	COLOR = vec4(shadow_color.rgb, shadow_color.a * alpha_strength * mask);
}
