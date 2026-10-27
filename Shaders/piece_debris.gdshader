shader_type canvas_item;

// What a broken piece leaves on the board - its chips, the blot where it
// stood - soaking into the paper: as `soak` goes from 0 to 1 the ink goes in
// blotches, palest first. The blotches are the ink blot's
// (ink_blot.gdshaderinc), whose noise is spread evenly over 0..1, so `soak`
// is about the share of the ink gone.

#include "res://Shaders/ink_blot.gdshaderinc"

// How big the blotches are, in the item's own units.
uniform float blot_size = 40.0;
instance uniform float soak = 0.0;
instance uniform float soak_seed = 0.0;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float texels = float(textureSize(ink_blot_noise, 0).x);
	vec2 uv = local_position / max(blot_size, 1.0) * (INK_BLOT_NOISE_BLOTCH / texels) + ink_blot_seed_offset(soak_seed);
	float blotch = texture(ink_blot_noise, uv).r;
	COLOR.a *= smoothstep(soak * 1.1 - 0.1, soak * 1.1, blotch);
}
