shader_type canvas_item;

// The scene washes' ink blot (ink_blot.gdshaderinc) on a drawn picture: its
// texture drawn as it is, with blotchy density and a wandering edge. Shared
// through two materials: ink_blot_washes.tres for the grey washes under the
// line art, ink_blot_pictures.tres for the collection's pictures on their own
// paper.

#include "res://Shaders/ink_blot.gdshaderinc"

// A picture on its own paper (the collection's book and case): ink is taken
// away towards that paper's white instead of letting the scene through.
uniform bool opaque_paper = false;

varying vec2 local_position;
varying vec4 modulate_color;

void vertex() {
	local_position = VERTEX;
	modulate_color = COLOR;
}

void fragment() {
	vec2 shift = ink_blot_wander(ink_blot_washes, local_position, 1.0);
	vec4 color = texture(TEXTURE, UV + ink_blot_uv_shift(shift, UV, local_position)) * modulate_color;
	float keep = ink_blot_density(ink_blot_washes, local_position, 1.0);
	if (opaque_paper) {
		color.rgb = mix(vec3(1.0), color.rgb, keep);
	} else {
		color.a *= keep;
	}
	COLOR = color;
}
