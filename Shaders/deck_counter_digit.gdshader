shader_type canvas_item;

uniform sampler2D digit_atlas : repeat_disable, filter_linear_mipmap;
uniform float roll_value = 0.0;
uniform float roll_direction = 1.0;
uniform float motion_blur = 0.0;
uniform float frame_count = 10.0;
uniform vec4 digit_color : source_color = vec4(0.02, 0.018, 0.014, 1.0);
uniform float curve_strength = 0.025;
uniform float edge_fade = 0.22;
uniform float alpha = 1.0;

vec2 get_digit_uv(vec2 uv, float value) {
	vec2 digit_uv = uv;
	digit_uv.x = clamp(digit_uv.x, 0.0, 1.0);
	digit_uv.y += cos(uv.y * PI) * curve_strength;
	digit_uv.y = clamp(digit_uv.y, 0.0, 1.0);
	digit_uv.y = mod(digit_uv.y + value, frame_count) / frame_count;
	return digit_uv;
}

float sample_digit_alpha(vec2 uv, float value) {
	return texture(digit_atlas, get_digit_uv(uv, value)).a;
}

void fragment() {
	float direction = sign(roll_direction);
	if (abs(direction) < 0.001) {
		direction = 1.0;
	}

	float digit_alpha = sample_digit_alpha(UV, roll_value) * 0.30;
	for (int i = 0; i < 9; i++) {
		float blur_offset = float(i - 4) * 0.045 * motion_blur * direction;
		digit_alpha += sample_digit_alpha(UV, roll_value + blur_offset) * 0.085;
	}
	digit_alpha = clamp(digit_alpha, 0.0, 1.0);

	float vertical_fade = smoothstep(0.0, edge_fade, UV.y) * (1.0 - smoothstep(1.0 - edge_fade, 1.0, UV.y));
	float final_alpha = digit_alpha * vertical_fade * alpha;

	COLOR = vec4(digit_color.rgb, final_alpha);
}
