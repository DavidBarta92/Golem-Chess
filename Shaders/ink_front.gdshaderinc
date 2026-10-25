// The ragged front of ink spreading into paper from a rect's edges, shared by
// a button's hover fill (ink_flood.gdshader) and the top bar's leaving items
// (ink_dissolve.gdshader). The front wanders by
// ui/themes/stamp/ink_flood_noise.png (baked by tools/generate_ink_stamps.py),
// sampled in the item's own pixels, so the blotches keep their size on an
// item of any size.

uniform sampler2D front_noise : repeat_enable, filter_linear;
// How far the front wanders, as a share of the way from the edge to the middle.
uniform float raggedness = 0.6;

// Signed distance to a rounded box around the origin, negative inside.
float front_rounded_box(vec2 point, vec2 half_size, vec4 radii) {
	float radius = point.x < 0.0 ? (point.y < 0.0 ? radii.x : radii.w) : (point.y < 0.0 ? radii.y : radii.z);
	radius = min(radius, min(half_size.x, half_size.y));
	vec2 q = abs(point) - half_size + vec2(radius);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

// The pattern's shift for a seed, in pixels of a texture that size.
vec2 front_offset(float seed, vec2 texture_size) {
	return vec2(fract(seed * 0.6180339), fract(seed * 0.7548777)) * texture_size;
}

// 1 where a front at progress (0 none, 1 all) has come in over point, 0 where
// it has not yet, with a soft edge; 0 outside the rect (size, corner radii:
// top left, top right, bottom right, bottom left). The front runs from a
// little outside the edge to a little past the middle - the noise seldom
// wanders further - so it is on the move for the whole of the progress.
float ink_front(vec2 point, vec2 size, vec4 radii, float progress, float seed) {
	vec2 half_size = size * 0.5;
	float half_depth = max(min(half_size.x, half_size.y), 1.0);
	float inside = -front_rounded_box(point - half_size, half_size, radii);
	// 0 at the edge, 1 along the middle.
	float depth = inside / half_depth;

	vec2 noise_size = vec2(textureSize(front_noise, 0));
	vec2 noise = texture(front_noise, (point + front_offset(seed, noise_size)) / noise_size).rg;
	float wander = (noise.r * 0.75 + noise.g * 0.25 - 0.5) * 2.0;

	float front = mix(-0.35, 1.35, progress);
	float soft = 0.75 / half_depth;
	float covered = 1.0 - smoothstep(front - soft, front + soft, depth + wander * raggedness);
	covered = progress >= 0.999 ? 1.0 : covered * step(0.001, progress);
	return covered * clamp(inside + 0.5, 0.0, 1.0);
}
