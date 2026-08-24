shader_type canvas_item;

// Arrival look for the main menu opponent silhouette: a directional blur and
// a Kuwahara "oil paint" pass (same technique as piece_kuwahara.gdshader /
// board_kuwahara.gdshader), each blended in independently via *_amount so
// both can be tweened smoothly from 1.0 (full effect, at the start of the
// walk-in) down to 0.0 (fully sharp, once the opponent has arrived).

uniform float blur_amount : hint_range(0.0, 1.0) = 0.0;
uniform float blur_radius_px : hint_range(0.0, 64.0) = 24.0;
uniform float paint_amount : hint_range(0.0, 1.0) = 0.0;
uniform int paint_radius = 2;

const float TAU_CONST = 6.28318530718;
const int BLUR_RING_TAPS = 8;
const int BLUR_RINGS = 4;

// Filled-disk blur (uniform-weighted, like a camera's circle of confusion)
// instead of a single ring of samples — a single ring just produces N
// evenly-spaced ghost copies of the source at full radius. Sampling several
// concentric, rotation-staggered rings fills the disk in and reads as a
// genuinely soft blob instead of an "echo" pattern.
vec4 sample_blurred(sampler2D tex, vec2 uv, vec2 pixel_size, float radius_px) {
	vec4 center = texture(tex, uv);
	if (radius_px <= 0.001) {
		return center;
	}

	vec3 rgb_sum = center.rgb * center.a;
	float a_sum = center.a;
	float weight = 1.0;

	for (int ring = 1; ring <= BLUR_RINGS; ring++) {
		float ring_radius = radius_px * float(ring) / float(BLUR_RINGS);
		float angle_offset = float(ring) * 0.6;
		for (int i = 0; i < BLUR_RING_TAPS; i++) {
			float angle = float(i) / float(BLUR_RING_TAPS) * TAU_CONST + angle_offset;
			vec2 dir = vec2(cos(angle), sin(angle));
			vec4 c = texture(tex, uv + dir * ring_radius * pixel_size);
			rgb_sum += c.rgb * c.a;
			a_sum += c.a;
			weight += 1.0;
		}
	}

	float a = a_sum / weight;
	vec3 rgb = a > 0.001 ? (rgb_sum / weight) / a : center.rgb;
	return vec4(rgb, a);
}

vec3 sample_oil_paint(sampler2D tex, vec2 uv, vec2 pixel_size, int radius) {
	vec3 m0 = vec3(0.0);
	vec3 m1 = vec3(0.0);
	vec3 m2 = vec3(0.0);
	vec3 m3 = vec3(0.0);
	vec3 s0 = vec3(0.0);
	vec3 s1 = vec3(0.0);
	vec3 s2 = vec3(0.0);
	vec3 s3 = vec3(0.0);
	float n0 = 0.0;
	float n1 = 0.0;
	float n2 = 0.0;
	float n3 = 0.0;
	vec4 sample_color;
	vec3 c;

	for (int j = -radius; j <= 0; j++) {
		for (int i = -radius; i <= 0; i++) {
			sample_color = texture(tex, uv + vec2(float(i), float(j)) * pixel_size);
			c = sample_color.rgb * sample_color.a;
			m0 += c;
			s0 += c * c;
			n0 += sample_color.a;
		}
	}
	for (int j = -radius; j <= 0; j++) {
		for (int i = 0; i <= radius; i++) {
			sample_color = texture(tex, uv + vec2(float(i), float(j)) * pixel_size);
			c = sample_color.rgb * sample_color.a;
			m1 += c;
			s1 += c * c;
			n1 += sample_color.a;
		}
	}
	for (int j = 0; j <= radius; j++) {
		for (int i = 0; i <= radius; i++) {
			sample_color = texture(tex, uv + vec2(float(i), float(j)) * pixel_size);
			c = sample_color.rgb * sample_color.a;
			m2 += c;
			s2 += c * c;
			n2 += sample_color.a;
		}
	}
	for (int j = 0; j <= radius; j++) {
		for (int i = -radius; i <= 0; i++) {
			sample_color = texture(tex, uv + vec2(float(i), float(j)) * pixel_size);
			c = sample_color.rgb * sample_color.a;
			m3 += c;
			s3 += c * c;
			n3 += sample_color.a;
		}
	}

	float min_sigma2 = 1e+2;
	vec3 best_color = texture(tex, uv).rgb;

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

	return best_color;
}

void fragment() {
	// Blur/paint sample the raw, unmodulated texture (sample_blurred and
	// sample_oil_paint both read TEXTURE directly, not COLOR), so modulate
	// (the opponent's fade-in opacity) is applied once at the very end
	// instead of being baked into "source" here. Multiplying it in earlier
	// meant it got partially overridden by the blur pass's own raw alpha
	// whenever blur_amount was high, which is what caused the sprite to
	// flash visible at the start regardless of how transparent it was set.
	vec4 tex_color = texture(TEXTURE, UV);
	if (tex_color.a * COLOR.a <= 0.01) {
		discard;
	}

	vec3 base_rgb = tex_color.rgb;
	float base_a = tex_color.a;

	if (blur_amount > 0.001) {
		vec4 blurred = sample_blurred(TEXTURE, UV, TEXTURE_PIXEL_SIZE, blur_radius_px);
		base_rgb = mix(base_rgb, blurred.rgb, blur_amount);
		base_a = mix(base_a, blurred.a, blur_amount);
	}

	if (paint_amount > 0.001) {
		vec3 painted = sample_oil_paint(TEXTURE, UV, TEXTURE_PIXEL_SIZE, paint_radius);
		base_rgb = mix(base_rgb, painted, paint_amount);
	}

	COLOR = vec4(base_rgb * COLOR.rgb, base_a * COLOR.a);
}
