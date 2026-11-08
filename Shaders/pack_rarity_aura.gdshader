shader_type canvas_item;
render_mode blend_add, unshaded;

// The glow around a rare stamp lying face down, with a brighter run of light
// going round it. The stamp sits in the middle of the rect, `inner_size` of it.

uniform vec4 aura_color : source_color = vec4(0.72, 0.84, 1.0, 1.0);
uniform float inner_size = 0.6;
uniform float strength = 1.0;

void fragment() {
	vec2 point = abs(UV - vec2(0.5)) * 2.0;
	float outside = length(max(point - vec2(inner_size), vec2(0.0))) / (1.0 - inner_size);
	float glow = pow(clamp(1.0 - outside, 0.0, 1.0), 2.4);
	float around = atan(UV.y - 0.5, UV.x - 0.5);
	float run = 0.62 + 0.38 * sin(around * 2.0 - TIME * 2.6);
	float breath = 0.86 + 0.14 * sin(TIME * 3.1);
	COLOR = vec4(aura_color.rgb * glow * run * breath * strength, 1.0);
}
