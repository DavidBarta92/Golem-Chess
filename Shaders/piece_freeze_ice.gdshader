shader_type canvas_item;

// A layer of ice over a frozen piece, drawn by a sprite on top of the piece with the same
// picture. What lies behind the ice comes from that picture, read at a pushed UV, not
// from the screen: a screen copy goes stale in this renderer (see the doc).

#include "res://Shaders/freeze_ice.gdshaderinc"

// Set per piece by FreezeEffectAnimator: the picture's size in board units, and the
// rows of it, 0..1, where the figure starts and ends.
uniform vec2 art_size = vec2(14.0, 24.0);
uniform vec2 figure_rows = vec2(0.0, 1.0);

// How far the ice stands proud of the figure, and how lumpy that edge is.
uniform float shell_thickness : hint_range(0.0, 3.0) = 0.75;
uniform float shell_lumps : hint_range(0.0, 1.0) = 0.4;
// How far the ice pushes what is behind it: its surface, and the bulge at its rim.
uniform float refraction : hint_range(0.0, 3.0) = 0.6;
uniform float rim_refraction : hint_range(0.0, 3.0) = 0.8;
// How much of the piece's own colour survives, and how milky the ice gets.
uniform float keep_colour : hint_range(0.0, 1.0) = 0.9;
uniform float veil : hint_range(0.0, 1.0) = 0.22;
uniform float milk : hint_range(0.0, 1.0) = 0.2;
// How much the reflection follows the figure's shape rather than the ice's surface.
uniform float figure_roundness : hint_range(0.0, 1.0) = 0.65;
// How much the part of the ice that stands clear of the figure hides the board.
uniform float rim_alpha : hint_range(0.0, 1.0) = 0.62;

const int RING_SIZE = 8;
const vec2 RING[RING_SIZE] = {
	vec2(1.0, 0.0), vec2(0.7071, 0.7071), vec2(0.0, 1.0), vec2(-0.7071, 0.7071),
	vec2(-1.0, 0.0), vec2(-0.7071, -0.7071), vec2(0.0, -1.0), vec2(0.7071, -0.7071)
};

varying vec4 piece_tint;

// A figure can touch the edge of its picture, so nothing outside 0..1 may be read:
// the sampler would smear that edge outwards.
float inside_picture(vec2 uv) {
	vec2 inside = step(vec2(0.0), uv) * step(uv, vec2(1.0));
	return inside.x * inside.y;
}

void vertex() {
	// The quad grows so the ice can stand past the edge of the picture.
	vec2 corner = sign(UV - 0.5);
	vec2 grow = shell_thickness * 1.5 / art_size;
	VERTEX += corner * grow / TEXTURE_PIXEL_SIZE;
	UV += corner * grow;
	piece_tint = COLOR;
}

void fragment() {
	vec2 units = UV * art_size;
	vec4 surface = ice_surface_at(units);
	float screen_step = length(fwidth(units));

	// How much of the figure lies around this pixel, and on which side. Sampled on two
	// rings rather than from mipmaps, because not every piece's picture has mipmaps.
	vec2 reach = shell_thickness / art_size;
	float around = 0.0;
	vec2 towards_figure = vec2(0.0);
	for (int i = 0; i < RING_SIZE; i++) {
		vec2 near_uv = UV + RING[i] * reach * 0.5;
		vec2 far_uv = UV + RING[i] * reach;
		float near = texture(TEXTURE, near_uv).a * inside_picture(near_uv);
		float far = texture(TEXTURE, far_uv).a * inside_picture(far_uv);
		around += near + far;
		towards_figure += RING[i] * (near + far);
	}
	around /= float(RING_SIZE) * 2.0;
	towards_figure /= float(RING_SIZE);

	float figure = texture(TEXTURE, UV).a * inside_picture(UV);
	float lumpy_around = around + (surface.w - 0.5) * shell_lumps * 0.3;
	float aa = max(fwidth(around), 0.01);
	float shell = max(figure, smoothstep(0.1 - aa, 0.1 + aa, lumpy_around));

	float rim = 1.0 - smoothstep(0.35, 0.95, around);

	// The light and the room wrap around the whole figure as if it were one rounded
	// lump, with the shards only roughening that; on their own the shards scatter
	// them into patches and the figure falls apart.
	vec2 across_figure = vec2(UV.x * 2.0 - 1.0, (UV.y - figure_rows.x) / max(figure_rows.y - figure_rows.x, 0.001) * 2.0 - 1.0);
	vec2 lean = across_figure * figure_roundness + surface.xy * (1.0 - figure_roundness) - towards_figure * 0.3;

	// Refraction: what is behind the ice, seen through its surface.
	vec2 behind_uv = UV + (surface.xy * refraction - towards_figure * rim_refraction) / art_size;
	vec4 behind = texture(TEXTURE, behind_uv);
	behind.a *= inside_picture(behind_uv);
	vec3 colour = mix(mix(ice_body, ice_deep, 0.5), behind.rgb * piece_tint.rgb, behind.a);

	float grey = dot(colour, vec3(0.3, 0.59, 0.11));
	colour = mix(vec3(grey), colour, keep_colour);
	colour = mix(colour, ice_body, veil + rim * 0.3);
	colour = mix(colour, ice_light, surface.w * surface.w * milk);

	vec2 reflection = ice_reflection(SCREEN_UV, lean);
	colour = mix(colour, ice_deep, reflection.x);
	colour = mix(colour, ice_light, reflection.y);

	float crack = ice_crack(surface.z, max(fwidth(surface.z), 0.04));
	colour = mix(colour, ice_light, crack);

	float glint = ice_glint(lean, TIME, max(screen_step * 0.12, 0.015));
	float sparkle = ice_sparkle(units, TIME);
	colour = mix(colour, ice_light, max(glint, sparkle));

	// The ice climbs from the feet to the head, each patch at its own moment.
	float climb = clamp((figure_rows.y - UV.y) / max(figure_rows.y - figure_rows.x, 0.001), 0.0, 1.0);
	float place = mix(0.3, 0.92, climb) + (0.5 - surface.w) * 0.16;
	float revealed = ice_reveal(place);
	colour = mix(colour, ice_light, ice_front_line(revealed) * 0.8);

	float solid = max(figure, behind.a);
	float alpha = shell * mix(rim_alpha, 1.0, solid);
	COLOR = vec4(colour, alpha * revealed * piece_tint.a);
}
