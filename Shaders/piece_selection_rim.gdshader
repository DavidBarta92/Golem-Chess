shader_type canvas_item;
render_mode blend_mix, unshaded;

// The selected piece: a thin rim of light round its figure and a faint halo
// past it, in the move dots' light, instead of a wash over the piece - its
// colour is the player's, and stays readable. On a copy of the piece's
// picture (PieceDisplayController.apply_selected_piece_glow).
//
// Widths are in board units (a square is about 18), worked out from
// `art_size`, the picture's size on the board: the pictures run from 16 px to
// 1578 px tall, and every piece has to get the same rim.

uniform vec2 art_size = vec2(14.0, 24.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.94, 0.78, 1.0);
uniform float rim_width : hint_range(0.0, 2.0) = 0.5;
uniform float rim_alpha : hint_range(0.0, 1.0) = 0.95;
uniform float halo_width : hint_range(0.0, 4.0) = 1.3;
uniform float halo_alpha : hint_range(0.0, 1.0) = 0.3;
// The halo breathes; the rim stays.
uniform float breathe_speed = 2.6;
uniform float breathe_depth : hint_range(0.0, 1.0) = 0.35;
// 0..1 as it comes on.
uniform float appear : hint_range(0.0, 1.0) = 1.0;

void vertex() {
	// The quad grows so the halo can stand past the edge of the picture.
	vec2 corner = sign(UV - 0.5);
	vec2 grow = halo_width * 1.2 / art_size;
	VERTEX += corner * grow / TEXTURE_PIXEL_SIZE;
	UV += corner * grow;
}

float figure_at(sampler2D picture, vec2 uv) {
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return 0.0;
	}
	return texture(picture, uv).a;
}

// The most figure on a ring round `uv`. Sampled on rings rather than read from
// mipmaps: not every piece's picture has them.
float ring_max(sampler2D picture, vec2 uv, vec2 reach) {
	float most = 0.0;
	for (int i = 0; i < 16; i++) {
		float angle = float(i) * 0.39269908;
		most = max(most, figure_at(picture, uv + vec2(cos(angle), sin(angle)) * reach));
	}
	return most;
}

void fragment() {
	float inside = figure_at(TEXTURE, UV);
	vec2 rim_reach = rim_width / art_size;
	float near = max(ring_max(TEXTURE, UV, rim_reach), ring_max(TEXTURE, UV, rim_reach * 0.5));
	float far = ring_max(TEXTURE, UV, halo_width / art_size);
	float rim = clamp(near - inside, 0.0, 1.0);
	float halo = clamp(far - max(near, inside), 0.0, 1.0);
	float breath = 1.0 - breathe_depth * (0.5 + 0.5 * sin(TIME * breathe_speed));
	float alpha = (rim * rim_alpha + halo * halo_alpha * breath) * appear;
	COLOR = vec4(rim_color.rgb, alpha * rim_color.a);
}
