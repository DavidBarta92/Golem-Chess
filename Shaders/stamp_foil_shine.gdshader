shader_type canvas_item;
render_mode blend_add, unshaded;

// The shine half of a whole-stamp foil: adds the band colour and the glitter as light,
// so the foil glows on dark parts too.

#include "res://Shaders/foil.gdshaderinc"

// The stamp's paper shape, so the foil never touches what lies around the stamp.
uniform sampler2D surface_mask_texture : repeat_disable, filter_linear_mipmap;

void fragment() {
	float surface = smoothstep(0.02, 0.16, texture(surface_mask_texture, UV).a);
	vec3 band = foil_band_color(UV);
	vec3 light = band * foil_shine_strength + mix(vec3(1.0), band, 0.35) * foil_sparkle(UV);
	// Added light times alpha: outside the stamp nothing is added, not even alpha.
	COLOR = vec4(light, surface * COLOR.a);
}
