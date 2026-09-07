shader_type canvas_item;
render_mode skip_vertex_transform;

uniform bool shadow_only = false;
uniform vec4 shadow_color : source_color;
uniform float blur_std = 0.4;
// The rect (in local pixels) that VERTEX spans for the quad being drawn --
// e.g. a TextureRect's own .size. This only equals the bound texture's
// native pixel size when that texture is shown at 1:1, which isn't true
// once a sprite is scaled down/up, so it must be supplied explicitly rather
// than derived from TEXTURE_PIXEL_SIZE (that derivation centers/expands the
// quad around the wrong point and crops it whenever the two sizes differ).
uniform vec2 control_rect_size = vec2(1.0, 1.0);

varying vec4 modulate;
varying vec2 v_uv;

void vertex() {
	float padding = ceil(blur_std * 3.0);
	VERTEX = VERTEX - control_rect_size * 0.5;
	VERTEX = VERTEX * (vec2(1.0, 1.0) + padding * 2.0 * TEXTURE_PIXEL_SIZE);
	VERTEX = VERTEX + control_rect_size * 0.5;
	VERTEX = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;

	vec2 factor = (vec2(1, 1) + 2.0 * padding * TEXTURE_PIXEL_SIZE);
	v_uv = factor * UV + vec2(0.5, 0.5) - 0.5 * factor;

	modulate = COLOR;
}

vec4 padded_sample(sampler2D tex, vec2 uv) {
	vec2 t = abs(uv - vec2(0.5, 0.5));
	float b = (t.x >= 0.5 || t.y >= 0.5) ? 0.0 : 1.0;
	return b * texture(tex, uv);
}

float erf(float x) {
	return 2.0 / sqrt(PI) * sign(x) * sqrt(1.0 - exp(-x*x)) * (sqrt(PI) / 2.0 + 31.0 * exp(-x*x) / 200.0 - 341.0 * exp(-2.0 * x * x) / 8000.0);
}

float gaussian(float x) {
	return 1.0 / sqrt(8.0) / blur_std + erf(x / sqrt(2.0) / blur_std) / sqrt(PI);
}

void fragment() {
	float weight = 0.0;
	vec2 coord = v_uv / TEXTURE_PIXEL_SIZE;
	coord -= floor(coord);
	float blur_radius = ceil(blur_std * 3.0);

	for (float x = -float(blur_radius); x <= float(blur_radius); ++x) {
		for (float y = -float(blur_radius); y <= float(blur_radius); ++y) {
			weight += (gaussian(-coord.x + x + 1.0) - gaussian(-coord.x + x))
			    * (gaussian(-coord.y + y + 1.0) - gaussian(-coord.y + y))
				* padded_sample(TEXTURE, v_uv + vec2(x, y) * TEXTURE_PIXEL_SIZE).a;
		}
	}

	vec4 c = padded_sample(TEXTURE, v_uv);
	float e = shadow_only ? 0.0 : 1.0;
	COLOR = c.a * e * c + (1.0 - c.a * e) * vec4(1.0, 1.0, 1.0, weight) * shadow_color;
	COLOR *= modulate;
}
