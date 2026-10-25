shader_type canvas_item;

// mainmenu_line_reveal.gdshader for coloured art: the item's own texture is
// drawn as it is, uncovered stroke by stroke along a line reveal mask made
// for it by tools/generate_line_reveal_mask.py (R = progress along the
// stroke, G = start delay, B = stroke length; see that script). The mask has
// the art's proportions, so the two share UVs. Used for the top bar's logo,
// written letter by letter (its mask is made with --left-to-right).

uniform sampler2D reveal_mask : filter_linear;
uniform float time = 0.0;
uniform float base_duration : hint_range(0.1, 6.0) = 0.5;
uniform float min_duration_frac : hint_range(0.0, 1.0) = 0.45;
uniform float max_delay : hint_range(0.0, 6.0) = 1.0;
uniform float feather : hint_range(0.0, 0.2) = 0.03;

void fragment() {
	vec4 mask = texture(reveal_mask, UV);
	float delay = mask.g * max_delay;
	float duration = base_duration * mix(min_duration_frac, 1.0, mask.b);
	float t = min((time - delay) / max(duration, 0.001), 1.0);
	COLOR.a *= 1.0 - smoothstep(t, t + feather, mask.r);
}
