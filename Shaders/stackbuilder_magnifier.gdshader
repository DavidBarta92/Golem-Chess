shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_linear;
uniform vec2 center_screen_uv = vec2(0.5, 0.5);
uniform float zoom : hint_range(1.0, 3.0, 0.01) = 1.85;
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
		vec2 sample_offset = (SCREEN_UV - center_screen_uv) / (zoom / edge_distortion);
		vec4 screen_color = texture(SCREEN_TEXTURE, center_screen_uv + sample_offset);
		vec3 tinted_color = mix(screen_color.rgb, glass_tint.rgb, glass_tint.a);

		COLOR = vec4(tinted_color, lens_alpha);
	}
}
