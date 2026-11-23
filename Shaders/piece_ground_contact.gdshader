shader_type canvas_item;
render_mode blend_mul;

// The board darkened where a piece stands on it (PieceGrounding): a soft band
// round the edge of its base, the base's own width and a little more, fading
// out evenly from that edge - not a blob under its middle, which reads as a
// hole. Multiplied in, so it is the board's own colour gone darker, not a
// grey patch laid on it. The piece's fade reaches it through the modulate's
// alpha.
//
// The quad spans the outer ellipse, where the darkening has faded out; the
// base is the inner one, `outer_to_base` times smaller along each axis.
// Inside the base it is at full strength, but the piece covers that.

uniform vec4 shade_color : source_color = vec4(0.42, 0.33, 0.27, 1.0);
uniform float amount = 0.55;
uniform vec2 outer_to_base = vec2(1.3, 1.6);
// How the darkening falls off from the base's edge: 1 straight, higher sooner.
uniform float falloff = 2.0;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float outer_q = max(length(p), 0.0001);
	float base_q = max(length(p * outer_to_base), 0.0001);
	// How far out between the base's edge (0) and the outer edge (1), along
	// the line from the middle.
	float t = clamp((1.0 - 1.0 / base_q) / (1.0 / outer_q - 1.0 / base_q), 0.0, 1.0);
	float dark = amount * pow(1.0 - t, falloff) * COLOR.a;
	COLOR = vec4(mix(vec3(1.0), shade_color.rgb, dark), 1.0);
}
