shader_type canvas_item;
render_mode blend_mul, unshaded;

// The tint half of a whole-stamp foil: multiplies everything drawn beneath it by the band
// colour, so light parts take the colour and black stays black.

#include "res://Shaders/foil.gdshaderinc"

// The stamp's paper shape, so the foil never touches what lies around the stamp.
uniform sampler2D surface_mask_texture : repeat_disable, filter_linear_mipmap;

void fragment() {
	float surface = smoothstep(0.02, 0.16, texture(surface_mask_texture, UV).a);
	float amount = foil_tint_strength * surface * COLOR.a;
	// Multiplying by white leaves the stamp unchanged where the foil fades out.
	COLOR = vec4(mix(vec3(1.0), foil_band_color(UV), amount), 1.0);
}
