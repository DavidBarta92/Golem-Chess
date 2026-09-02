shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 color_a : source_color = vec4(0.867, 0.561, 0.016, 1.0);
uniform vec4 color_b : source_color = vec4(0.867, 0.561, 0.016, 1.0);
uniform float gradient_start : hint_range(0.0, 1.0) = 0.1021;
uniform float gradient_end : hint_range(0.0, 1.0) = 0.8969;
uniform float edge_softness : hint_range(0.0, 0.08) = 0.015;

float mask_value(vec4 mask_sample) {
	float luma = dot(mask_sample.rgb, vec3(0.2126, 0.7152, 0.0722));
	return max(mask_sample.a, luma);
}

void fragment() {
	float mask = mask_value(texture(TEXTURE, UV));
	float shape_alpha = smoothstep(0.0, max(edge_softness, 0.0001), mask);
	float local_x = clamp((UV.x - gradient_start) / max(gradient_end - gradient_start, 0.0001), 0.0, 1.0);
	vec4 gradient_color = mix(color_a, color_b, local_x);
	COLOR = vec4(gradient_color.rgb, gradient_color.a * shape_alpha * COLOR.a);
}
