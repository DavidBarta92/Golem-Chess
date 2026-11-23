shader_type canvas_item;

// A piece's shadow on the board (PieceGrounding): its own picture, flipped,
// laid flat and leaned by the node that draws it, softened by reading a
// smaller mip, and fading from its feet towards its head.

uniform vec4 shadow_color : source_color = vec4(0.1, 0.06, 0.04, 1.0);
uniform float strength = 0.3;
// How soft, in mip levels.
uniform float blur = 2.5;
// The figure's feet and head, as the picture's v.
uniform float feet_v = 0.94;
uniform float head_v = 0.33;

void fragment() {
	float shape = textureLod(TEXTURE, UV, blur).a;
	float near_feet = smoothstep(head_v, feet_v, UV.y);
	COLOR = vec4(shadow_color.rgb, shape * strength * mix(0.3, 1.0, near_feet) * COLOR.a);
}
