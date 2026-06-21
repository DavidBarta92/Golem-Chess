shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D mask_texture : repeat_disable, filter_linear;
uniform float mask_threshold = 0.05;
uniform float mask_softness = 0.02;

void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	vec3 mask_rgb = texture(mask_texture, UV).rgb;
	float mask_value = dot(mask_rgb, vec3(0.299, 0.587, 0.114));
	float mask_alpha = smoothstep(mask_threshold, mask_threshold + mask_softness, mask_value);
	COLOR = vec4(source.rgb, source.a * mask_alpha);
}
