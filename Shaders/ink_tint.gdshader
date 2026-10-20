shader_type canvas_item;

// Re-inks black UI art (pager arrows, codex buttons) in the UI's ink colour:
// black becomes ink_color, white stays white, greys fall in between. A plain
// modulate cannot do it - multiplying never lifts black off zero.

uniform vec4 ink_color : source_color = vec4(0.090196, 0.172549, 0.262745, 1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float lightness = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(ink_color.rgb, vec3(1.0), lightness), c.a);
}
