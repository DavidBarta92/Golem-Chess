shader_type canvas_item;

// The Collection's magnifier lens. lens_texture is a SubViewport that renders
// the room itself - the same canvas as the screen, not a copy of it - around
// the lens centre at the magnified scale, so stamps show their full-resolution
// art instead of stretched screen pixels. The view covers `coverage` times the
// lens so the barrel distortion at the rim still has picture to sample.

uniform sampler2D lens_texture : repeat_disable, filter_linear;
uniform float coverage = 1.12;
uniform float distortion : hint_range(0.0, 0.5, 0.01) = 0.12;
uniform float edge_feather : hint_range(0.001, 0.08, 0.001) = 0.025;
uniform vec4 glass_tint : source_color = vec4(0.9, 0.97, 1.0, 0.12);

void fragment() {
	vec2 lens_uv = UV - vec2(0.5);
	float radius = length(lens_uv);
	float lens_alpha = 1.0 - smoothstep(0.5 - edge_feather, 0.5, radius);

	if (lens_alpha <= 0.001) {
		COLOR = vec4(0.0);
	} else {
		float normalized_radius = clamp(radius * 2.0, 0.0, 1.0);
		float edge_distortion = 1.0 + distortion * normalized_radius * normalized_radius;
		vec4 view_color = texture(lens_texture, vec2(0.5) + lens_uv * edge_distortion / coverage);
		// The view is rendered on a transparent background; past the edge of
		// the room it shows the white paper underneath.
		vec3 room_color = view_color.rgb + (1.0 - view_color.a) * vec3(1.0);
		COLOR = vec4(mix(room_color, glass_tint.rgb, glass_tint.a), lens_alpha);
	}
}
