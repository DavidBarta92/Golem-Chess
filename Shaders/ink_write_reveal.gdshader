shader_type canvas_item;

// Words written onto the paper in ink, from `write_from` to `write_to` along
// x, in the item's own pixels. The ink runs in along a front that wanders by
// the ink blot's noise (ink_blot.gdshaderinc), so the edge of what has been
// written is never ruled. `progress` 0 is nothing written, 1 all of it.

#include "res://Shaders/ink_blot.gdshaderinc"

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float write_from = 0.0;
uniform float write_to = 1.0;
// How far the front wanders either way, and how soft it is, in pixels.
uniform float raggedness = 18.0;
uniform float softness = 10.0;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float texels = float(textureSize(ink_blot_noise, 0).x);
	vec2 noise_uv = local_position / 60.0 * (INK_BLOT_NOISE_WANDER / texels);
	float wander = (texture(ink_blot_noise, noise_uv).g - 0.5) * 2.0 * raggedness;
	float margin = raggedness + softness;
	float front = write_from - margin + (write_to - write_from + margin * 2.0) * progress;
	COLOR.a *= 1.0 - smoothstep(front - softness, front + softness, local_position.x + wander);
}
