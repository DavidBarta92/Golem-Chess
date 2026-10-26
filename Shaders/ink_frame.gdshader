shader_type canvas_item;

// A flooded button's own drawing (Scripts/InkStamp/InkHoverFill.gd): the UI's
// ink blot (ink_blot.gdshaderinc) on its frame, drawn live in the button's own
// units with the seed its hover ink (ink_flood.gdshader) uses, so the outline,
// the hover's ink and the pressed fill share one pattern. These buttons'
// prints are baked without the blot (live_blot in InkStampStyleBox).
//
// Where the hover's ink already lies beneath, the frame adds only what that
// ink lacks: the two together are one layer of ink, not two. Otherwise a
// pale blotch shows paper through the hover's ink but not through the
// outline over it, and the outline stands out as a dark frame. The hover's
// state reaches this shader as the button's own flood_* instance uniforms.
//
// The label is left alone. It samples a font atlas, which is square, and a
// print never is: that is how the two are told apart. Within a print only
// the ink takes the blot; a paper fill keeps its paper.

#include "res://Shaders/ink_front.gdshaderinc"
#include "res://Shaders/ink_blot.gdshaderinc"

// The same mask as the hover's ink, for its fill specks.
uniform sampler2D stamp_mask : repeat_enable, filter_linear, hint_default_white;

instance uniform float ink_blot_seed = 0.0;
instance uniform float flood_progress = 0.0;
instance uniform vec2 flood_size = vec2(1.0);
instance uniform vec4 flood_radii = vec4(4.0);

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float keep = ink_blot_density(ink_blot_ui, local_position, ink_blot_seed);
	// The hover's ink beneath this point, as ink_flood.gdshader draws it.
	float covered = ink_front(local_position, flood_size, flood_radii, flood_progress, ink_blot_seed);
	vec2 mask_size = vec2(textureSize(stamp_mask, 0));
	float specks = texture(stamp_mask, (local_position + front_offset(ink_blot_seed, mask_size)) / mask_size).g;
	float flood = keep * covered * specks;
	// The frame's ink with the blot, joined with the hover's ink: where either
	// has ink, there is one layer of it.
	float together = keep * max(covered * specks, COLOR.a);
	float frame_alpha = max(together - flood, 0.0) / max(1.0 - flood, 0.001);

	vec2 texture_size = vec2(textureSize(TEXTURE, 0));
	float is_print = step(0.5, abs(texture_size.x - texture_size.y));
	float ink = 1.0 - smoothstep(0.5, 0.85, dot(COLOR.rgb, vec3(0.299, 0.587, 0.114)));
	COLOR.a = mix(COLOR.a, frame_alpha, is_print * ink);
}
