shader_type canvas_item;

// The bottom of a piece a little darker, where the board shades it
// (PieceGrounding): its own picture again, kept only in a band up from its
// feet and coloured dark.

uniform vec4 shade_color : source_color = vec4(0.12, 0.08, 0.06, 1.0);
uniform float strength = 0.45;
// The figure's feet, as the picture's v, and how far up the shade reaches.
uniform float feet_v = 0.94;
uniform float band = 0.08;

void fragment() {
	float in_band = smoothstep(feet_v - band, feet_v, UV.y);
	COLOR = vec4(shade_color.rgb, COLOR.a * in_band * strength);
}
