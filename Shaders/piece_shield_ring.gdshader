shader_type canvas_item;
render_mode blend_mix, unshaded;

// The ring of the ward over an uncapturable piece, drawn on its square
// (Scripts/MatchView/PieceShield.gd): an outer line, a thin inner one and
// runes between them, turning slowly. On a plain quad laid on the board's
// plane, so the circle comes out in the board's perspective; UV 0..1 spans
// the circle's width. Line widths in board units (`radius_units` is its
// radius in them).

uniform float radius_units = 8.0;
// The lines red, the runes the bubble's violet. Light enough to read on the
// board's brown.
uniform vec4 ink_color : source_color = vec4(1.0, 0.38, 0.4, 1.0);
uniform vec4 rune_color : source_color = vec4(0.82, 0.55, 1.0, 1.0);
uniform float outer_units = 0.22;
uniform float inner_units = 0.15;
uniform float rune_units = 0.42;
uniform float rune_count = 16.0;
uniform float turn_speed = 0.015;
uniform float line_alpha : hint_range(0.0, 1.0) = 0.65;
uniform float rune_alpha : hint_range(0.0, 1.0) = 0.5;

// Driven by PieceShield: how much of the circle is drawn (it sweeps round as
// it comes), and the same strength, flicker, tremble and going as the dome's.
uniform float draw : hint_range(0.0, 1.0) = 1.0;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float flicker : hint_range(0.0, 1.0) = 0.0;
uniform float tremble : hint_range(0.0, 1.0) = 0.0;
uniform float pop : hint_range(0.0, 1.0) = 0.0;

float hash(float n) {
	return fract(sin(n * 91.345) * 47453.5453);
}

float band(float r, float from_r, float to_r, float aa) {
	return smoothstep(from_r - aa, from_r, r) * (1.0 - smoothstep(to_r, to_r + aa, r));
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float angle = atan(p.y, p.x);
	float r = length(p) + tremble * 0.035 * sin(angle * 9.0 - TIME * 34.0);
	float unit = 1.0 / radius_units;
	float aa = max(fwidth(r), 0.0005);

	float outer = band(r, 1.0 - outer_units * unit, 1.0, aa);
	float inner_r = 1.0 - (outer_units + 1.6) * unit;
	float inner = band(r, inner_r - inner_units * unit, inner_r, aa);

	// Runes between the lines: dashes of differing length, each with a dot.
	float turns = angle / 6.2831853 + 0.5 + TIME * turn_speed;
	float slot = floor(turns * rune_count);
	float along = fract(turns * rune_count);
	float rune_r = 1.0 - (outer_units + 0.8) * unit;
	float rune_band = band(r, rune_r - rune_units * unit, rune_r, aa);
	float dash = step(0.12, along) * step(along, 0.25 + 0.4 * hash(slot));
	float dot_at = 0.78 + 0.1 * hash(slot + 4.0);
	float dot_mark = step(abs(along - dot_at), 0.045);
	float runes = rune_band * max(dash, dot_mark);

	// On its last turn it is broken and flickers.
	float broken = mix(1.0, step(0.3, fract(angle * 2.2281692 + TIME * 0.05)), flicker);
	float flick = 1.0 - flicker * 0.45 * step(0.35, sin(TIME * 9.0 + sin(TIME * 3.7) * 2.0));
	// It is drawn round from the back as it comes.
	float drawn = step(fract(angle / 6.2831853 + 0.75), draw);

	float line_part = (outer + inner) * line_alpha * broken;
	float rune_part = runes * rune_alpha;
	float alpha = clamp(line_part + rune_part, 0.0, 1.0) * drawn;
	vec3 colour = mix(ink_color.rgb, rune_color.rgb, rune_part / max(line_part + rune_part, 0.0001));
	COLOR = vec4(colour, alpha * strength * flick * (1.0 - pop));
}
