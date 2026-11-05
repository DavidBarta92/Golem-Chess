shader_type canvas_item;

// A sheet of ice on the square under a frozen piece. It lets the tile show through by
// alpha alone: the tile has no picture of its own to refract, and the grid is drawn
// above it.

#include "res://Shaders/freeze_ice.gdshaderinc"

// How much the ice hides the tile: where it is clear, and at the frosted edge.
uniform float sheet_alpha : hint_range(0.0, 1.0) = 0.36;
uniform float edge_alpha : hint_range(0.0, 1.0) = 0.8;
uniform float edge_width : hint_range(0.0, 0.5) = 0.12;
// Squares lie flat and are seen at a slant, so their shards are squashed.
uniform float flatten : hint_range(1.0, 3.0) = 1.5;

varying vec2 units;

void vertex() {
	units = VERTEX * vec2(1.0, flatten);
}

void fragment() {
	// UV is 0..1 across the square. The pattern takes the square's position instead:
	// UV bends at the diagonal where a slanted square's two triangles meet.
	vec4 surface = ice_surface_at(units);
	float screen_step = length(fwidth(units));
	vec2 from_edge = min(UV, 1.0 - UV);
	float edge = 1.0 - smoothstep(0.0, edge_width, min(from_edge.x, from_edge.y) + (surface.w - 0.5) * 0.06);

	vec3 colour = mix(ice_body, ice_light, surface.w * 0.6 + edge * 0.4);
	float alpha = mix(sheet_alpha, edge_alpha, edge) * mix(0.7, 1.0, surface.w);

	// A flat sheet leans less than a shell does, so it catches the light in slivers.
	vec2 lean = surface.xy * 0.52;
	// Only the room's shadow: its light would just be more of the same paper colour.
	float shadow = ice_reflection(SCREEN_UV, lean).x;
	colour = mix(colour, ice_deep, shadow);

	float crack = ice_crack(surface.z, max(fwidth(surface.z), 0.04));
	float glint = ice_glint(lean, TIME, max(screen_step * 0.12, 0.015));
	float sparkle = ice_sparkle(units, TIME);
	float shine = max(max(crack, glint), sparkle);
	colour = mix(colour, ice_light, shine);
	alpha = max(alpha, shine);

	// The floor freezes first, from under the piece outwards.
	float place = length(UV - 0.5) * 0.62 + (0.5 - surface.w) * 0.12;
	float revealed = ice_reveal(place);
	colour = mix(colour, ice_light, ice_front_line(revealed) * 0.8);
	COLOR = vec4(colour, alpha * revealed);
}
