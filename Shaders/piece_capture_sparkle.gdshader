shader_type canvas_item;
render_mode blend_add;

uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float scale : hint_range(0.1, 10000.0, 0.1) = 7500.0;
uniform float circle_ratio : hint_range(0.0, 100.0, 0.1) = 0.0;
uniform float decay_magnitude : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float rotate_speed : hint_range(-1000.0, 1000.0, 0.01) = 1.0;
uniform float time_speed : hint_range(-1000.0, 1000.0, 0.01) = 1.0;
uniform float frequency_base : hint_range(0.0, 10.0, 0.01) = 1.0;
uniform float frequency_disturbance_scale : hint_range(0.0, 10.0, 0.01) = 0.0;
uniform float alpha_strength : hint_range(0.0, 1.0) = 1.0;

float onedx(float x) {
	if (x + 1.0 - 1.0 == 0.0) {
		return 1.0;
	} else {
		return 1.0 / x;
	}
}

float onedx2(float x) {
	return onedx(x) * onedx(x);
}

float getBetaW(float x, float f, float pattern_size) {
	return pattern_size * x * 3.1415926 / f;
}

float getBetaH(float y, float f, float pattern_size) {
	return pattern_size * y * 3.1415926 / f;
}

float getI(vec2 uv, float f, vec2 pattern_size) {
	return onedx2(getBetaW(uv.x, f, pattern_size.x)) * onedx2(getBetaH(uv.y, f, pattern_size.y));
}

vec2 rotate(vec2 uv, float addtheta) {
	float theta = atan(uv.y / uv.x) + addtheta;
	float r = sqrt(uv.x * uv.x + uv.y * uv.y);
	return vec2(r * cos(theta), r * sin(theta));
}

void fragment() {
	vec2 st = rotate((UV - 0.5) * scale, TIME * rotate_speed);
	float r = sqrt(st.x * st.x + st.y * st.y);
	st = st * pow(r, circle_ratio);
	float time = TIME * time_speed;
	float f = frequency_base + frequency_disturbance_scale * (3.0 * sin(time) + 2.0 * cos(time * 4.0) + 6.0 * sin(time * 2.0) + sin(time * 3.0));
	float L = distance(UV, st);
	float M = exp(-L * L * decay_magnitude * decay_magnitude / scale);
	M = M < 0.05 ? 0.0 : M;
	COLOR = vec4(min(vec3(getI(st, f, SCREEN_PIXEL_SIZE)) * M, 1.0), 1.0) * color * alpha_strength;
}
