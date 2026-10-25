shader_type canvas_item;

// The top bar's items leaving: the hover's ink turned inside out - paper
// floods in over the whole item from its edges along the same ragged front
// (ink_front.gdshaderinc), until nothing is left. Scenes/GlobalTopBar.gd
// drives dissolve_progress from 0 (all there) to 1 (gone) and fades the item
// at the same time.

#include "res://Shaders/ink_front.gdshaderinc"

instance uniform float dissolve_progress = 0.0;
instance uniform float dissolve_seed = 0.0;
instance uniform vec2 dissolve_size = vec2(1.0);

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	// Square corners: the front works in from the item's whole rect, whatever
	// is drawn in it.
	float gone = ink_front(local_position, dissolve_size, vec4(0.0), dissolve_progress, dissolve_seed);
	COLOR.a *= 1.0 - gone;
}
