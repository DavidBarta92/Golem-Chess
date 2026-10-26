shader_type canvas_item;

// A button's hover fill: ink flooding in from the button's edges along a
// ragged front (ink_front.gdshaderinc), like ink spreading into paper, until
// the whole face is ink. Scripts/InkStamp/InkHoverFill.gd drives
// flood_progress from 0 (no ink) to 1 (all ink) on a layer behind the
// button, so its outline and label stay on top. The ink then gets the stamp's
// fill specks and the UI's ink blot, as the pressed print has.

#include "res://Shaders/ink_front.gdshaderinc"
#include "res://Shaders/ink_blot.gdshaderinc"

// UiPalette.INK.
uniform vec4 ink_color : source_color = vec4(0.090196, 0.172549, 0.262745, 1.0);
uniform sampler2D stamp_mask : repeat_enable, filter_linear, hint_default_white;

instance uniform float flood_progress = 0.0;
instance uniform float flood_seed = 0.0;
instance uniform vec2 flood_size = vec2(1.0);
// The button's corner radii: top left, top right, bottom right, bottom left.
instance uniform vec4 flood_radii = vec4(4.0);

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float ink = ink_front(local_position, flood_size, flood_radii, flood_progress, flood_seed);
	vec2 mask_size = vec2(textureSize(stamp_mask, 0));
	float keep = texture(stamp_mask, (local_position + front_offset(flood_seed, mask_size)) / mask_size).g;
	keep *= ink_blot_density(ink_blot_ui, local_position, flood_seed);
	COLOR = vec4(ink_color.rgb, ink_color.a * ink * keep);
}
