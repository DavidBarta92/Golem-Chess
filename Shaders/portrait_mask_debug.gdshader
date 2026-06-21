shader_type canvas_item;
render_mode blend_mix;

uniform vec4 debug_color : source_color = vec4(0.1, 0.85, 1.0, 0.34);

void fragment() {
	vec3 mask_rgb = texture(TEXTURE, UV).rgb;
	float mask_value = dot(mask_rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(debug_color.rgb, debug_color.a * mask_value);
}
