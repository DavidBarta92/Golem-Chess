shader_type canvas_item;

// The UI's ink pressed onto the paper like a rubber stamp: a little ink taken
// away in small specks. Ink is only removed, never lightened, so the specks
// show whatever is beneath. The mask is the same one the framed controls'
// prints are baked from (tools/generate_ink_stamps.py), sampled in the item's
// local pixels so a speck keeps its size, and shifted by a per-node seed so
// two items do not share a pattern. Nothing here moves. Its red channel holds
// a line's specks, its green the sparser specks of an ink fill.
//
// It can re-ink black UI art first (pager arrows, the codex buttons' icons):
// black becomes ink_color, white stays white, greys fall in between. A plain
// modulate cannot do it - multiplying never lifts black off zero.
//
// The ink also gets the UI's ink blot (ink_blot.gdshaderinc), its density
// only: titles sample a font atlas, where a wandering edge would pull in the
// neighbouring glyphs.

#include "res://Shaders/ink_blot.gdshaderinc"

uniform sampler2D stamp_mask : repeat_enable, filter_linear, hint_default_white;
// 1 = the mask as baked, 0 = no specks.
uniform float strength : hint_range(0.0, 1.0) = 1.0;
instance uniform float stamp_seed = 0.0;
// The point of the item the pattern is pinned to, in its pixels: the origin,
// or for an item whose ink moves inside it, a point that moves with the ink.
instance uniform vec2 stamp_anchor = vec2(0.0);
// 1 for an item that is mostly ink fill (a ribbon, a pip): the fill's specks.
instance uniform float stamp_fill = 0.0;
// UiPalette.INK, for re-inked art.
uniform vec4 ink_color : source_color = vec4(0.090196, 0.172549, 0.262745, 1.0);
// 1 for black art to re-ink in ink_color.
instance uniform float stamp_reink = 0.0;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX - stamp_anchor;
}

void fragment() {
	if (stamp_reink > 0.5) {
		float lightness = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
		COLOR.rgb = mix(ink_color.rgb, vec3(1.0), lightness);
	}
	vec2 mask_size = vec2(textureSize(stamp_mask, 0));
	vec2 offset = vec2(fract(stamp_seed * 0.6180339), fract(stamp_seed * 0.7548777)) * mask_size;
	vec2 masks = texture(stamp_mask, (local_position + offset) / mask_size).rg;
	float keep = mix(masks.r, masks.g, stamp_fill);
	COLOR.a *= mix(1.0, keep, strength) * ink_blot_density(ink_blot_ui, local_position, stamp_seed);
}
