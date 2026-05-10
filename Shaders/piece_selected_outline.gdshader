shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 0.86, 0.16, 1.0);
uniform float outline_size = 2.5;

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);
	float outline_alpha = 0.0;
	vec2 pixel_size = TEXTURE_PIXEL_SIZE * outline_size;

	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(pixel_size.x, 0.0)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(-pixel_size.x, 0.0)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(0.0, pixel_size.y)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(0.0, -pixel_size.y)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(pixel_size.x, pixel_size.y)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(-pixel_size.x, pixel_size.y)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(pixel_size.x, -pixel_size.y)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(-pixel_size.x, -pixel_size.y)).a);

	float edge_alpha = max(0.0, outline_alpha - base_color.a);
	COLOR = vec4(outline_color.rgb, outline_color.a * edge_alpha);
}
