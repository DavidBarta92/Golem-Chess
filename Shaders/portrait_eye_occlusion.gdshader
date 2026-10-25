shader_type canvas_item;
render_mode blend_mix;

uniform float occlusion_bottom_y_pixels = 0.0;
uniform float mask_strength = 1.0;
uniform float mask_softness = 2.0;

void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	float pixel_y = UV.y / TEXTURE_PIXEL_SIZE.y;
	float eyelid_cover = 1.0 - smoothstep(occlusion_bottom_y_pixels - mask_softness, occlusion_bottom_y_pixels + mask_softness, pixel_y);
	float occlusion = eyelid_cover * mask_strength;
	COLOR = vec4(source.rgb, source.a * (1.0 - occlusion));
}
