// The ink blot (Docs/Style/INK_BLOT.md): ink soaked unevenly into the paper.
// Inside the ink its density drifts in blotches; along its edge the ink is
// pushed in and out by a noise field, the way ink bleeds into paper. Written
// for this game after the Rorschach ink test shader's look, not taken from it.
//
// One look in four groups, each with strengths of its own: the UI, the
// scenes' line art, the scenes' grey washes and the stamps. The values are
// global shader uniforms, declared in project.godot and set by the InkBlot
// autoload from Shaders/ink_blot_settings.tres - tune them there.
//
// Everything is sampled in the item's own units, so the blotches stay put on
// an item as it moves and keep their size whatever the screen. Nothing here
// moves on its own.

// Baked by tools/generate_ink_stamps.py: blotches spread evenly over 0..1 in
// red, the edge's wander around 0.5 in green (x) and blue (y). It tiles, and
// has mipmaps, so a stamp drawn small does not shimmer.
global uniform sampler2D ink_blot_noise : repeat_enable, filter_linear_mipmap;
// Per group: x = density (0 = even ink, 1 = the palest blotches lose all their
// ink), y = how far an edge is pushed at most, in units, z = the blotches'
// size and w = the size of the edge's bends, in units.
global uniform vec4 ink_blot_ui;
global uniform vec4 ink_blot_lines;
global uniform vec4 ink_blot_washes;
global uniform vec4 ink_blot_stamps;
// How sharply a blotch's border is drawn: 0 soft, 1 crisp.
global uniform float ink_blot_contrast;

// The noise's feature sizes, in its texels. Keep in step with BLOT_NOISE_BLOTCH
// and BLOT_NOISE_WANDER in the tool.
const float INK_BLOT_NOISE_BLOTCH = 64.0;
const float INK_BLOT_NOISE_WANDER = 16.0;

// Where in the noise an item with this seed starts, so two items do not share
// a pattern.
vec2 ink_blot_seed_offset(float seed) {
	return vec2(fract(seed * 0.6180339), fract(seed * 0.7548777));
}

// The share of the ink kept at a point, given in the item's own units.
float ink_blot_density(vec4 group, vec2 position, float seed) {
	if (group.x <= 0.0) {
		return 1.0;
	}
	float texels = float(textureSize(ink_blot_noise, 0).x);
	vec2 uv = position / max(group.z, 1.0) * (INK_BLOT_NOISE_BLOTCH / texels) + ink_blot_seed_offset(seed);
	float blotch = texture(ink_blot_noise, uv).r;
	float softness = max(1.0 - ink_blot_contrast, 0.02);
	blotch = clamp((blotch - 0.5) / softness + 0.5, 0.0, 1.0);
	return 1.0 - group.x * (1.0 - blotch);
}

// How far the edge is pushed at a point, in the item's own units.
vec2 ink_blot_wander(vec4 group, vec2 position, float seed) {
	if (group.y <= 0.0) {
		return vec2(0.0);
	}
	float texels = float(textureSize(ink_blot_noise, 0).x);
	vec2 uv = position / max(group.w, 0.5) * (INK_BLOT_NOISE_WANDER / texels) + ink_blot_seed_offset(seed + 0.5);
	return (texture(ink_blot_noise, uv).gb - 0.5) * 2.0 * group.y;
}

// A shift in the item's own units as a shift in UV, for sampling the item's
// texture where its wandering edge puts it. Worked out from screen-space
// derivatives, so it must be called outside any branch.
vec2 ink_blot_uv_shift(vec2 shift, vec2 uv, vec2 position) {
	mat2 uv_per_pixel = mat2(dFdx(uv), dFdy(uv));
	mat2 units_per_pixel = mat2(dFdx(position), dFdy(position));
	if (abs(determinant(units_per_pixel)) < 1e-10) {
		return vec2(0.0);
	}
	return uv_per_pixel * inverse(units_per_pixel) * shift;
}
