// A foil on the stamp's white parts only. Every stamp layer that can draw white (the art,
// the pattern markers, the name, the duration and the icons) tints its own white pixels,
// so nothing has to read the screen back - an overlay doing that read stale pixels under
// the Compatibility renderer, the Collection's paper overlay and the magnifier's second
// view of the room. StampVisual sets these uniforms on each such layer's material.

#include "res://Shaders/foil.gdshaderinc"

uniform bool foil_on_white = false;
// Where white starts and where it is full, measured on a pixel's darkest channel so a
// light colour does not count.
uniform float foil_white_start : hint_range(0.0, 1.0) = 0.88;
uniform float foil_white_full : hint_range(0.0, 1.0) = 0.97;
// The layer's top-left corner within the stamp, so the foil runs across all layers as one.
uniform vec2 foil_layer_origin = vec2(0.0);

// Set in vertex() with foil_stamp_uv_of(VERTEX).
varying vec2 foil_stamp_uv;

vec2 foil_stamp_uv_of(vec2 layer_vertex) {
	return (layer_vertex + foil_layer_origin) / max(foil_stamp_size, vec2(1.0));
}

vec3 foil_on_white_tint(vec3 color, vec2 stamp_uv) {
	if (!foil_on_white) {
		return color;
	}
	float whiteness = smoothstep(foil_white_start, foil_white_full, min(color.r, min(color.g, color.b)));
	return mix(color, color * foil_band_color(stamp_uv), foil_tint_strength * whiteness);
}
