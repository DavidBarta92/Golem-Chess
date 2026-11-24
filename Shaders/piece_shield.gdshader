shader_type canvas_item;
render_mode blend_mix, unshaded;

// The ward over an uncapturable piece: a red bubble standing on its square
// (Scripts/MatchView/PieceShield.gd). Drawn twice, on a plain quad round the
// bubble. `front` 0 is what lies behind the piece: the inside's tint, the far
// edge of its base and its rim seen from inside. `front` 1 is what lies over
// it: the rim, washes of colour drifting on it, a glint and sparkles.
//
// Flat tones with hard edges, as the ice's: a smooth gradient looks like a
// render on top of a drawing; flat tones look painted.
//
// Its shape: the upper half of an ellipse `height_ratio` times as tall as it
// is wide, standing on the base - the ring on the board, an ellipse
// `depth_ratio` times as deep as it is wide. Lengths in its own half width,
// line widths in board units (`px_per_unit`).

uniform float front = 1.0;
uniform vec2 bounds_px = vec2(100.0, 100.0);
uniform vec2 base_offset_px = vec2(0.0, 0.0);
uniform float half_width_px = 40.0;
uniform float height_ratio = 2.0;
uniform float depth_ratio = 0.4;
uniform float px_per_unit = 20.0;

// Red, with violet drifting through it in flat patches: along the band
// inside the rim and in the washes on its skin.
uniform vec4 rim_color : source_color = vec4(0.93, 0.17, 0.22, 1.0);
uniform vec4 second_color : source_color = vec4(0.56, 0.24, 0.98, 1.0);
uniform vec4 tint_color : source_color = vec4(0.92, 0.26, 0.3, 1.0);
uniform vec4 wash_a : source_color = vec4(0.64, 0.38, 1.0, 1.0);
uniform vec4 wash_b : source_color = vec4(1.0, 0.3, 0.28, 1.0);
uniform vec4 glint_color : source_color = vec4(1.0, 0.9, 0.93, 1.0);
// How much of the band is violet, and how fast the patches drift round.
uniform float second_share : hint_range(0.0, 1.0) = 0.42;
uniform float second_drift = 0.45;
// A thin film: a fine rim line and a narrow band of colour just inside it
// (a share of the radius).
uniform float rim_line_units = 0.18;
uniform float rim_band = 0.03;
uniform float line_alpha : hint_range(0.0, 1.0) = 0.75;
uniform float band_alpha : hint_range(0.0, 1.0) = 0.22;
uniform float tint_alpha : hint_range(0.0, 1.0) = 0.07;
uniform float wash_alpha : hint_range(0.0, 1.0) = 0.14;
uniform float glint_alpha : hint_range(0.0, 1.0) = 0.42;
uniform float sparkle_units = 0.55;
uniform float sparkle_alpha : hint_range(0.0, 1.0) = 0.6;

// Driven by PieceShield: how far up it has grown, how strong it is (lower on
// its last turn), its flicker then, a tremble, and its popping - a hole
// tearing open from `burst_at` (in its half widths) and running across it.
// How much of it shows: it is out of sight but for a while at a time.
uniform float shown : hint_range(0.0, 1.0) = 1.0;
uniform float rise : hint_range(0.0, 1.0) = 1.0;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float flicker : hint_range(0.0, 1.0) = 0.0;
uniform float tremble : hint_range(0.0, 1.0) = 0.0;
uniform float pop : hint_range(0.0, 1.0) = 0.0;
uniform vec2 burst_at = vec2(0.3, -1.4);
uniform vec4 tear_color : source_color = vec4(1.0, 0.88, 0.9, 1.0);
uniform float tear_edge_width = 0.07;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void layer(inout vec4 result, vec3 colour, float alpha) {
	alpha = clamp(alpha, 0.0, 1.0);
	result.rgb = mix(result.rgb, colour, alpha);
	result.a = result.a + alpha * (1.0 - result.a);
}

// How far out a point is: 1 on the bubble's outline.
float dome_distance(vec2 q) {
	return q.y < 0.0 ? length(vec2(q.x, q.y / height_ratio)) : length(vec2(q.x, q.y / depth_ratio));
}

void fragment() {
	vec2 q = ((UV - 0.5) * bounds_px - base_offset_px) / half_width_px;
	float unit = px_per_unit / half_width_px;
	float angle = atan(q.y, q.x);

	// The tremble runs round its surface as a ripple.
	float ripple = tremble * 0.06 * sin(angle * 9.0 - TIME * 34.0) * (0.6 + 0.4 * sin(TIME * 23.0 + q.y * 5.0));
	float d = dome_distance(q) + ripple;
	float aa = max(fwidth(d), 0.0005);
	float inside = 1.0 - smoothstep(1.0 - aa, 1.0, d);

	// It grows up from its base: 0 at the base, 1 at the top.
	float up = clamp(-q.y / height_ratio, 0.0, 1.0);
	float risen = rise <= 0.0 ? 0.0 : 1.0 - smoothstep(rise - 0.05, rise, up);

	// On its last turn it is thinner and broken, and flickers.
	float line_width = rim_line_units * unit * mix(0.6, 1.0, strength);
	float broken = mix(1.0, step(0.3, fract(angle * 2.2281692 + TIME * 0.05)), flicker);
	float flick = 1.0 - flicker * 0.45 * step(0.35, sin(TIME * 9.0 + sin(TIME * 3.7) * 2.0));

	// Popping: the film is gone inside the hole; just outside it, the edge of
	// the torn film is a thin bright line, a little ragged.
	vec2 from_burst = q - burst_at;
	float tear_reach = pop * (1.4 + height_ratio);
	float tear_d = length(from_burst) + 0.035 * sin(atan(from_burst.y, from_burst.x) * 11.0);
	float torn = pop <= 0.0 ? 0.0 : 1.0 - smoothstep(tear_reach - 0.02, tear_reach, tear_d);
	float tear_edge = (pop <= 0.0 || pop >= 1.0) ? 0.0 : step(tear_reach, tear_d) * step(tear_d, tear_reach + tear_edge_width) * inside;

	float line = smoothstep(1.0 - line_width - aa, 1.0 - line_width, d) * inside * broken;
	float band = step(1.0 - rim_band, d) * inside;
	// Patches of the second colour drifting round the band, hard-edged.
	float swirl = sin(angle * 2.0 + TIME * second_drift + q.y * 1.3 + 0.8 * sin(angle * 5.0 - TIME * 0.3));
	float second = smoothstep(1.0 - 2.0 * second_share - 0.04, 1.0 - 2.0 * second_share + 0.04, swirl);
	vec3 band_colour = mix(rim_color.rgb, second_color.rgb, second);
	vec4 result = vec4(tint_color.rgb, 0.0);

	if (front < 0.5) {
		layer(result, tint_color.rgb, tint_alpha * inside);
		layer(result, band_colour, band_alpha * 0.45 * band);
		// The far half of its base, behind the feet.
		float base_d = length(vec2(q.x, q.y / depth_ratio));
		float far_edge = q.y < 0.0 ? 1.0 - smoothstep(line_width * 0.6, line_width * 0.6 + aa, abs(base_d - 1.0)) : 0.0;
		layer(result, band_colour, line_alpha * 0.55 * far_edge * broken);
	} else {
		// Washes drifting on its skin, kept off the middle so the piece shows.
		float wave = sin(q.x * 2.3 + q.y * 1.6 + TIME * 0.5 + 1.7 * sin(q.y * 2.9 - TIME * 0.37));
		float edge_share = smoothstep(0.2, 0.75, d) * inside;
		layer(result, wash_a.rgb, wash_alpha * step(0.5, wave) * edge_share);
		layer(result, wash_b.rgb, wash_alpha * step(0.5, -wave) * edge_share);
		layer(result, band_colour, band_alpha * band * (1.0 + 0.4 * second));
		layer(result, band_colour, line_alpha * line);

		// A glint up on its left shoulder, flat, drifting a little.
		vec2 glint_at = vec2(-0.48 + 0.04 * sin(TIME * 0.7), -height_ratio * 0.64);
		vec2 g = (q - glint_at) / vec2(0.11, 0.24 * min(height_ratio, 2.5) * 0.5);
		float glint = 1.0 - smoothstep(1.0 - aa * 8.0, 1.0, length(g));
		layer(result, glint_color.rgb, glint_alpha * glint * inside);

		// Sparkles rising slowly over its skin.
		vec2 cell_space = vec2(q.x * 3.0, q.y * 3.0 / max(height_ratio, 0.5) + TIME * 0.35);
		vec2 cell = floor(cell_space);
		float seed = hash(cell);
		vec2 spot = cell + vec2(hash(cell + 3.1), hash(cell + 7.7)) * 0.8 + 0.1;
		float spot_size = sparkle_units * unit * 3.0;
		float twinkle = max(sin(TIME * 2.6 + seed * 6.2831), 0.0);
		float sparkle = step(0.72, seed) * (1.0 - smoothstep(spot_size * 0.6, spot_size, length(cell_space - spot))) * twinkle;
		layer(result, glint_color.rgb, sparkle_alpha * sparkle * edge_share);
		layer(result, tear_color.rgb, 0.95 * tear_edge);
	}

	COLOR = vec4(result.rgb, result.a * shown * risen * strength * flick * (1.0 - torn));
}
