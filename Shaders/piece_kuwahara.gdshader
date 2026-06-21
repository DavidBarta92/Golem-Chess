shader_type canvas_item;

uniform int radius = 2;
uniform vec3 offset = vec3(0.0);

void fragment() {
	vec2 src_size = TEXTURE_PIXEL_SIZE;
	vec2 uv = UV;
	vec4 source = texture(TEXTURE, uv) * COLOR;
	if (source.a <= 0.01) {
		discard;
	}

	vec3 m0 = offset;
	vec3 m1 = offset;
	vec3 m2 = offset;
	vec3 m3 = offset;
	vec3 s0 = offset;
	vec3 s1 = offset;
	vec3 s2 = offset;
	vec3 s3 = offset;
	vec4 sample_color;
	vec3 c;
	float n0 = 0.0;
	float n1 = 0.0;
	float n2 = 0.0;
	float n3 = 0.0;

	for (int j = -radius; j <= 0; ++j) {
		for (int i = -radius; i <= 0; ++i) {
			sample_color = texture(TEXTURE, uv + vec2(float(i), float(j)) * src_size) * COLOR;
			c = sample_color.rgb * sample_color.a;
			m0 += c;
			s0 += c * c;
			n0 += sample_color.a;
		}
	}

	for (int j = -radius; j <= 0; ++j) {
		for (int i = 0; i <= radius; ++i) {
			sample_color = texture(TEXTURE, uv + vec2(float(i), float(j)) * src_size) * COLOR;
			c = sample_color.rgb * sample_color.a;
			m1 += c;
			s1 += c * c;
			n1 += sample_color.a;
		}
	}

	for (int j = 0; j <= radius; ++j) {
		for (int i = 0; i <= radius; ++i) {
			sample_color = texture(TEXTURE, uv + vec2(float(i), float(j)) * src_size) * COLOR;
			c = sample_color.rgb * sample_color.a;
			m2 += c;
			s2 += c * c;
			n2 += sample_color.a;
		}
	}

	for (int j = 0; j <= radius; ++j) {
		for (int i = -radius; i <= 0; ++i) {
			sample_color = texture(TEXTURE, uv + vec2(float(i), float(j)) * src_size) * COLOR;
			c = sample_color.rgb * sample_color.a;
			m3 += c;
			s3 += c * c;
			n3 += sample_color.a;
		}
	}

	float min_sigma2 = 1e+2;
	vec3 best_color = source.rgb;

	if (n0 > 0.0) {
		m0 /= n0;
		s0 = abs(s0 / n0 - m0 * m0);
		float sigma2 = s0.r + s0.g + s0.b;
		if (sigma2 < min_sigma2) {
			min_sigma2 = sigma2;
			best_color = m0;
		}
	}

	if (n1 > 0.0) {
		m1 /= n1;
		s1 = abs(s1 / n1 - m1 * m1);
		float sigma2 = s1.r + s1.g + s1.b;
		if (sigma2 < min_sigma2) {
			min_sigma2 = sigma2;
			best_color = m1;
		}
	}

	if (n2 > 0.0) {
		m2 /= n2;
		s2 = abs(s2 / n2 - m2 * m2);
		float sigma2 = s2.r + s2.g + s2.b;
		if (sigma2 < min_sigma2) {
			min_sigma2 = sigma2;
			best_color = m2;
		}
	}

	if (n3 > 0.0) {
		m3 /= n3;
		s3 = abs(s3 / n3 - m3 * m3);
		float sigma2 = s3.r + s3.g + s3.b;
		if (sigma2 < min_sigma2) {
			min_sigma2 = sigma2;
			best_color = m3;
		}
	}

	COLOR = vec4(best_color, source.a);
}
