shader_type canvas_item;
render_mode blend_mix;

uniform vec4 glow_color : source_color = vec4(1.0, 0.82, 0.28, 1.0);
uniform float glow_strength : hint_range(0.0, 5.0) = 0.0;
uniform float glow_size : hint_range(0.0, 10.0) = 4.5;
uniform float fill_strength : hint_range(0.0, 1.0) = 0.28;

void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	vec2 pixel_size = TEXTURE_PIXEL_SIZE * glow_size;
	float expanded_alpha = source.a;

	expanded_alpha = max(expanded_alpha, texture(TEXTURE, UV + vec2(pixel_size.x, 0.0)).a * COLOR.a);
	expanded_alpha = max(expanded_alpha, texture(TEXTURE, UV + vec2(-pixel_size.x, 0.0)).a * COLOR.a);
	expanded_alpha = max(expanded_alpha, texture(TEXTURE, UV + vec2(0.0, pixel_size.y)).a * COLOR.a);
	expanded_alpha = max(expanded_alpha, texture(TEXTURE, UV + vec2(0.0, -pixel_size.y)).a * COLOR.a);
	expanded_alpha = max(expanded_alpha, texture(TEXTURE, UV + vec2(pixel_size.x, pixel_size.y)).a * COLOR.a);
	expanded_alpha = max(expanded_alpha, texture(TEXTURE, UV + vec2(-pixel_size.x, pixel_size.y)).a * COLOR.a);
	expanded_alpha = max(expanded_alpha, texture(TEXTURE, UV + vec2(pixel_size.x, -pixel_size.y)).a * COLOR.a);
	expanded_alpha = max(expanded_alpha, texture(TEXTURE, UV + vec2(-pixel_size.x, -pixel_size.y)).a * COLOR.a);
	expanded_alpha = max(expanded_alpha, texture(TEXTURE, UV + vec2(pixel_size.x * 1.75, 0.0)).a * COLOR.a * 0.7);
	expanded_alpha = max(expanded_alpha, texture(TEXTURE, UV + vec2(-pixel_size.x * 1.75, 0.0)).a * COLOR.a * 0.7);
	expanded_alpha = max(expanded_alpha, texture(TEXTURE, UV + vec2(0.0, pixel_size.y * 1.75)).a * COLOR.a * 0.7);
	expanded_alpha = max(expanded_alpha, texture(TEXTURE, UV + vec2(0.0, -pixel_size.y * 1.75)).a * COLOR.a * 0.7);

	float outer_alpha = max(0.0, expanded_alpha - source.a);
	float inner_alpha = source.a * fill_strength;
	float strength_alpha = min(glow_strength, 3.2);
	float glow_alpha = (outer_alpha + inner_alpha) * glow_color.a * strength_alpha;
	float overbright = 1.0 + max(0.0, glow_strength - 1.0) * 0.85;
	float yellow_fill = clamp(glow_strength * 0.22, 0.0, 0.88) * source.a;
	vec3 glow_rgb = mix(glow_color.rgb, vec3(1.0, 0.92, 0.03), yellow_fill);

	COLOR = vec4(glow_rgb * overbright, clamp(glow_alpha + yellow_fill * 0.62, 0.0, 1.0));
}
