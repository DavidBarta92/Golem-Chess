shader_type canvas_item;

// Screen-space paper overlay, inspired by shaders.paper.design/paper-texture.
// Meant to sit on a full-rect ColorRect in a high-layer CanvasLayer (same
// pattern as crt_vhs.gdshader / CrtOverlay.tscn), so it tints
// whatever was already rendered below it instead of painting its own opaque
// background. Assign a seamless NoiseTexture2D (FastNoiseLite, fractal type,
// seamless on) to noise_texture -- no noise math is hand-rolled here, we just
// resample it at a few different scales/offsets to fake large folds + fine
// fiber grain.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D noise_texture : repeat_enable, filter_linear_mipmap;

uniform vec2 fold_scale = vec2(2.2, 2.2);
uniform float fiber_scale : hint_range(4.0, 120.0) = 55.0;
uniform float fiber_stretch : hint_range(1.0, 40.0) = 12.0;
uniform float fiber_edge : hint_range(0.01, 0.25) = 0.05;
uniform float fiber_strength : hint_range(0.0, 0.3) = 0.10;
uniform float grain_strength : hint_range(0.0, 0.2) = 0.02;

uniform vec4 highlight_tint : source_color = vec4(1.04, 1.02, 0.95, 1.0);
uniform vec4 shadow_tint : source_color = vec4(0.68, 0.64, 0.55, 1.0);
uniform vec3 light_dir = vec3(0.35, 0.55, 0.75);
uniform float bump_strength : hint_range(0.0, 8.0) = 2.5;
uniform float light_strength : hint_range(0.0, 2.0) = 0.55;
uniform float contrast : hint_range(0.5, 3.0) = 1.25;
uniform float effect_opacity : hint_range(0.0, 1.0) = 0.5;
// Multiplied into the screen before the paper look, for scenes whose art is
// opaque white rather than drawn over the cream paper ColorRect the other
// scenes use. White (the default) leaves the screen as it is.
uniform vec4 paper_color : source_color = vec4(1.0);

float pixel_hash(vec2 point) {
	point = fract(point * vec2(123.34, 456.21));
	point += dot(point, point + 45.32);
	return fract(point.x * point.y);
}

float height_at(vec2 uv) {
	float large_folds = texture(noise_texture, uv * fold_scale).r;
	float medium_creases = texture(noise_texture, uv * fold_scale * 3.7 + vec2(5.2, 1.3)).r;
	return large_folds * 0.65 + medium_creases * 0.35;
}

// Thin curly threads traced along the noise field's 0.5 contour line -- this
// reads as fiber strands, unlike raw stretched noise which just looks blurry.
float fiber_line(vec2 uv, float scale, float stretch, float angle) {
	float s = sin(angle);
	float c = cos(angle);
	vec2 ruv = vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
	vec2 fuv = vec2(ruv.x * scale, ruv.y * scale * stretch);
	float n = texture(noise_texture, fuv).r;
	return 1.0 - smoothstep(0.0, fiber_edge, abs(n - 0.5));
}

void fragment() {
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	vec3 paper_base = screen_color.rgb * paper_color.rgb;

	float fibers = fiber_line(UV, fiber_scale, fiber_stretch, 0.0) * 0.65;
	fibers += fiber_line(UV, fiber_scale * 1.4, fiber_stretch * 0.6, 0.6) * 0.35;

	float h = height_at(UV);
	vec2 texel = vec2(1.0) / vec2(textureSize(noise_texture, 0));
	float h_dx = height_at(UV + vec2(texel.x, 0.0)) - h;
	float h_dy = height_at(UV + vec2(0.0, texel.y)) - h;
	vec3 normal = normalize(vec3(-h_dx * bump_strength, -h_dy * bump_strength, 1.0));
	float diffuse = dot(normal, normalize(light_dir));

	float shade = clamp((diffuse - 0.5) * light_strength + 0.5, 0.0, 1.0);
	shade = clamp((shade - 0.5) * contrast + 0.5, 0.0, 1.0);

	vec3 tint = mix(shadow_tint.rgb, highlight_tint.rgb, shade);
	vec3 color = paper_base * tint;
	color += fibers * fiber_strength;
	color += (pixel_hash(FRAGCOORD.xy) - 0.5) * grain_strength;

	COLOR = vec4(mix(paper_base, clamp(color, 0.0, 1.0), effect_opacity), screen_color.a);
}
