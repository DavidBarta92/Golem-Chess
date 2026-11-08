shader_type canvas_item;
render_mode blend_add, unshaded;

// One band of light crossing a stamp as it is turned over.

uniform vec4 band_color : source_color = vec4(0.8, 0.9, 1.0, 1.0);
// 0 before the stamp, 1 past it.
uniform float sweep = 0.0;
uniform float band_width = 0.2;
// The stamp's paper shape, so the light stays on the stamp.
uniform sampler2D surface_mask_texture : repeat_disable, filter_linear_mipmap;

void fragment() {
	float surface = smoothstep(0.02, 0.16, texture(surface_mask_texture, UV).a);
	float position = UV.x + UV.y * 0.55;
	float centre = mix(-0.4, 1.95, sweep);
	float band = exp(-pow((position - centre) / band_width, 2.0));
	COLOR = vec4(band_color.rgb * band * surface, 1.0);
}
