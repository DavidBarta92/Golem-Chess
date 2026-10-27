shader_type canvas_item;

// One of the player's own pieces broken: for a moment a wash of colour rises
// from the bottom of the screen, their side of the board, and a little way up
// its sides. It is ink on paper like the scene's washes, blotchy by the same
// ink blot (ink_blot.gdshaderinc), not a smooth screen tint.

#include "res://Shaders/ink_blot.gdshaderinc"

uniform vec4 wash_color : source_color = vec4(0.55, 0.12, 0.1, 0.3);
uniform float amount : hint_range(0.0, 1.0) = 0.0;
// How far up the screen it reaches, as a share of the screen's height.
uniform float reach = 0.3;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float from_bottom = 1.0 - UV.y;
	float bottom = 1.0 - smoothstep(0.0, reach, from_bottom);
	float side = 1.0 - smoothstep(0.0, reach * 0.3, min(UV.x, 1.0 - UV.x));
	side *= 1.0 - smoothstep(0.0, 0.75, from_bottom);
	float wash = max(bottom * bottom, side * 0.6);
	wash *= ink_blot_density(ink_blot_washes, local_position, 3.0);
	COLOR = vec4(wash_color.rgb, wash_color.a * wash * amount);
}
