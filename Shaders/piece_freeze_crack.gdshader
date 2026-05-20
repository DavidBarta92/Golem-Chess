shader_type canvas_item;

uniform float crack_depth : hint_range(0.0, 10.0) = 2.46;
uniform float crack_scale : hint_range(1.0, 10.0) = 7.96;
uniform float crack_zebra_scale : hint_range(0.0, 10.0) = 1.61;
uniform float crack_zebra_amp : hint_range(0.0, 10.0) = 1.33;
uniform float crack_profile : hint_range(0.0, 10.0) = 0.33;
uniform float crack_slope : hint_range(0.0, 50.0) = 13.03;
uniform float crack_width : hint_range(0.0, 1.0) = 0.0;
uniform float effect_alpha : hint_range(0.0, 1.0) = 1.0;
uniform bool alpha_from_cracks = false;
uniform vec4 ice_color : source_color = vec4(0.58, 0.76, 0.96, 0.62);
uniform float ice_strength : hint_range(0.0, 1.0) = 0.68;
uniform float crack_brightness : hint_range(0.0, 1.0) = 0.72;
uniform float crack_transparency : hint_range(0.0, 1.0) = 0.22;
uniform float crack_thinness : hint_range(0.2, 2.0) = 1.45;

const vec4 BACKGROUND_COLOR = vec4(0.0, 0.0, 0.0, 0.0);
const vec4 CRACK_COLOR = vec4(0.0, 0.0, 0.0, 1.0);

uniform vec2 refraction_offset = vec2(24.92, 25.0);
uniform vec2 reflection_offset = vec2(1.28, 1.0);
uniform vec4 reflection_color : source_color = vec4(0.588, 0.588, 0.588, 0.5);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

vec2 hash(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(dot(hash(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)), dot(hash(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), f.x),
		mix(dot(hash(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)), dot(hash(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), f.x),
		f.y
	);
}

vec3 voronoi_b(vec2 u) {
	vec2 p = floor(u);
	vec2 f = fract(u);
	float res = 8.0;
	vec2 c = vec2(0.0);
	vec2 nearest = vec2(0.0);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = hash(p + g);
			vec2 r = g - f + o;
			float d = dot(r, r);
			if (d < res) {
				res = d;
				c = g;
				nearest = r;
			}
		}
	}

	res = 8.0;
	for (int j = -2; j <= 2; j++) {
		for (int i = -2; i <= 2; i++) {
			vec2 g = c + vec2(float(i), float(j));
			vec2 o = hash(p + g);
			vec2 r = g - f + o;
			if (dot(nearest - r, nearest - r) > 0.00001) {
				res = min(res, 0.5 * dot(nearest + r, normalize(r - nearest)));
			}
		}
	}
	return vec3(res, nearest + f);
}

float fbm(vec2 n) {
	float total = 0.0;
	float amp = 1.0;
	for (int i = 0; i < 7; i++) {
		total += noise(n) * amp;
		n += n;
		amp *= 0.5;
	}
	return total;
}

vec4 generate_cracks(vec2 uv) {
	vec2 u = uv * crack_scale;
	vec4 color = BACKGROUND_COLOR;
	for (int i = 0; i < 10; i++) {
		if (float(i) >= crack_depth) {
			break;
		}

		vec2 distortion = vec2(crack_zebra_amp * fbm(u / crack_zebra_scale) * crack_zebra_scale);
		vec3 voronoi_value = voronoi_b(u + distortion);
		float distance = voronoi_value.x;
		distance = min(1.0, crack_slope * pow(max(0.0, distance - crack_width), crack_profile));
		color += vec4(1.0 - distance) / exp2(float(i));
		u *= 1.5;
	}
	return color * CRACK_COLOR;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	if (source.a <= 0.01) {
		discard;
	}

	vec4 cracks = generate_cracks(UV);
	float crack_alpha = pow(clamp(cracks.a, 0.0, 1.0), crack_thinness);
	float freeze_progress = clamp(crack_width / 0.7, 0.0, 1.0) * effect_alpha;
	vec3 iced_color = mix(source.rgb, ice_color.rgb, ice_strength);
	vec3 crack_color = vec3(0.92, 0.98, 1.0);
	vec3 final_rgb = mix(iced_color, crack_color, crack_alpha * crack_brightness);
	float final_alpha = source.a * ice_color.a * freeze_progress * (1.0 - crack_alpha * crack_transparency);
	if (alpha_from_cracks) {
		final_alpha *= crack_alpha;
	}
	COLOR = vec4(final_rgb, final_alpha);
}
