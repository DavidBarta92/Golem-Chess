// The stamps' ink blot (ink_blot.gdshaderinc). Every inked layer of a stamp
// works in the stamp's own units, so the blotches run across the square, the
// art and the lettering as one print. StampVisual sets the instance uniform
// on each layer.

#include "res://Shaders/ink_blot.gdshaderinc"

// xy = the layer's top-left corner in the stamp, z = stamp units per layer
// unit (the stamp's usual height over its height now, so a smaller stamp
// shows the same blotches), w = the stamp's seed.
instance uniform vec4 stamp_blot_frame = vec4(0.0, 0.0, 1.0, 0.0);

// Set in vertex() with stamp_blot_position_of(VERTEX).
varying vec2 stamp_blot_position;

vec2 stamp_blot_position_of(vec2 layer_vertex) {
	return (layer_vertex + stamp_blot_frame.xy) * stamp_blot_frame.z;
}

// The share of the ink kept at a point of the stamp.
float stamp_blot_density(vec2 stamp_position) {
	return ink_blot_density(ink_blot_stamps, stamp_position, stamp_blot_frame.w);
}

// The UV to sample the layer's texture at, so its edge wanders. Call it
// outside any branch.
vec2 stamp_blot_uv(vec2 uv, vec2 stamp_position) {
	vec2 shift = ink_blot_wander(ink_blot_stamps, stamp_position, stamp_blot_frame.w);
	return uv + ink_blot_uv_shift(shift, uv, stamp_position);
}
