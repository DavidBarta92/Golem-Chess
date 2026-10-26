shader_type canvas_item;

// The stamp layers with no shader of their own: the name, the duration number,
// the effect and trigger icons and the role frame. They always get the stamps'
// ink blot (stamp_ink_blot.gdshaderinc) - its density only, since the
// lettering samples a font atlas, where a wandering edge would pull in its
// neighbours - and the white-parts foil while such a foil is on.

#include "res://Shaders/foil_on_white.gdshaderinc"
#include "res://Shaders/stamp_ink_blot.gdshaderinc"

void vertex() {
	foil_stamp_uv = foil_stamp_uv_of(VERTEX);
	stamp_blot_position = stamp_blot_position_of(VERTEX);
}

void fragment() {
	vec4 color = texture(TEXTURE, UV) * COLOR;
	color.a *= stamp_blot_density(stamp_blot_position);
	COLOR = vec4(foil_on_white_tint(color.rgb, foil_stamp_uv), color.a);
}
