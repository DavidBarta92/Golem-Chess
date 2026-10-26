shader_type canvas_item;

// The white-parts foil for the stamp layers with no shader of their own: the name, the
// duration number, the effect and trigger icons and the role frame. StampVisual gives
// them this material only while such a foil is on.

#include "res://Shaders/foil_on_white.gdshaderinc"

void vertex() {
	foil_stamp_uv = foil_stamp_uv_of(VERTEX);
}

void fragment() {
	vec4 color = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(foil_on_white_tint(color.rgb, foil_stamp_uv), color.a);
}
