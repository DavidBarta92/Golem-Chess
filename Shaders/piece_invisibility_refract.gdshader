shader_type canvas_item;

const float PI_VALUE = 3.14156;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;
uniform float dist = 16.0;
uniform float alpha : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 canvas_color = COLOR;
	vec2 pixel_offset = SCREEN_PIXEL_SIZE * dist;
	vec2 offset_r = vec2(pixel_offset.x * cos(TIME * 2.0 * PI_VALUE), pixel_offset.y * cos(TIME * 0.7 * 2.0 * PI_VALUE));
	vec2 offset_g = vec2(pixel_offset.x * cos(1.0 + TIME * 2.0 * PI_VALUE), pixel_offset.y * cos(3.0 + TIME * 0.7 * 2.0 * PI_VALUE));
	vec2 offset_b = vec2(pixel_offset.x * cos(TIME * 1.5 * PI_VALUE), pixel_offset.y * cos(TIME * 0.9 * 2.0 * PI_VALUE));

	vec4 back_col_r = texture(SCREEN_TEXTURE, SCREEN_UV + offset_r);
	vec4 back_col_g = texture(SCREEN_TEXTURE, SCREEN_UV + offset_g);
	vec4 back_col_b = texture(SCREEN_TEXTURE, SCREEN_UV + offset_b);
	vec4 tex_col = texture(TEXTURE, UV) * canvas_color;
	vec4 refracted_col = vec4(back_col_r.r, back_col_g.g, back_col_b.b, tex_col.a);
	COLOR = mix(tex_col, refracted_col, alpha);
}
