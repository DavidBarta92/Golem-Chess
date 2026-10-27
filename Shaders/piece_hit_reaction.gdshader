shader_type canvas_item;

// A struck piece through the hitstop. Its drawing is washed toward
// `flash_color` by `flash_amount`, and cracks in ink run out along
// `crack_segments` from `crack_origin`, as far as `crack_reach`. Segments,
// origin and reach are in the texture's pixels, so the cracks stay on the
// drawing, and only show where it has ink.

const int MAX_CRACK_SEGMENTS = 24;

uniform vec4 flash_color : source_color = vec4(1.0, 0.95, 0.78, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 1.0;
uniform vec4 crack_color : source_color = vec4(0.08, 0.06, 0.05, 1.0);
// Each from xy to zw.
uniform vec4 crack_segments[MAX_CRACK_SEGMENTS];
uniform int crack_segment_count = 0;
uniform vec2 crack_origin = vec2(0.0);
uniform float crack_reach = 0.0;
// The cracks' width on screen, in pixels, whatever the texture's size.
uniform float crack_width = 1.8;

float distance_to_segment(vec2 point, vec2 from, vec2 to) {
	vec2 along = to - from;
	float t = clamp(dot(point - from, along) / max(dot(along, along), 0.0001), 0.0, 1.0);
	return length(point - from - along * t);
}

void fragment() {
	COLOR.rgb = mix(COLOR.rgb, flash_color.rgb, flash_amount);

	vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
	// Texture pixels to one screen pixel, here.
	float pixel_scale = max(length(dFdx(pixel)), length(dFdy(pixel)));
	float nearest = 1e6;
	for (int i = 0; i < MAX_CRACK_SEGMENTS; i++) {
		if (i >= crack_segment_count) {
			break;
		}
		nearest = min(nearest, distance_to_segment(pixel, crack_segments[i].xy, crack_segments[i].zw));
	}
	float half_width = crack_width * 0.5 * pixel_scale;
	float on_crack = 1.0 - smoothstep(half_width - pixel_scale * 0.5, half_width + pixel_scale * 0.5, nearest);
	float reached = 1.0 - smoothstep(crack_reach - pixel_scale * 3.0, crack_reach, distance(pixel, crack_origin));
	COLOR.rgb = mix(COLOR.rgb, crack_color.rgb, on_crack * reached * crack_color.a);
}
