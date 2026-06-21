shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D scene_mask_texture : repeat_disable, filter_linear;
uniform float scene_mask_enabled = 0.0;
uniform float occlusion_bottom_y_pixels = 0.0;
uniform float mask_strength = 1.0;
uniform float mask_softness = 2.0;

void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	vec3 scene_mask_rgb = texture(scene_mask_texture, UV).rgb;
	float scene_mask_value = dot(scene_mask_rgb, vec3(0.299, 0.587, 0.114));
	float scene_alpha = mix(1.0, smoothstep(0.05, 0.07, scene_mask_value), scene_mask_enabled);
	float pixel_y = UV.y / TEXTURE_PIXEL_SIZE.y;
	float eyelid_cover = 1.0 - smoothstep(occlusion_bottom_y_pixels - mask_softness, occlusion_bottom_y_pixels + mask_softness, pixel_y);
	float occlusion = eyelid_cover * mask_strength;
	COLOR = vec4(source.rgb, source.a * (1.0 - occlusion) * scene_alpha);
}
