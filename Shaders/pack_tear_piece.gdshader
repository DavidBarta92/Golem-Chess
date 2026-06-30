shader_type canvas_item;

uniform float tear_cut_y = 0.085;
uniform float tear_wave_strength = 0.012;
uniform float tear_seed = 0.0;
uniform float tear_edge_softness = 0.006;
uniform vec4 tear_edge_tint : source_color = vec4(0.92, 0.82, 0.68, 1.0);

float tear_curve(float x) {
	float primary = sin((x * 3.35 + tear_seed) * 6.28318);
	float secondary = sin((x * 8.2 + tear_seed * 1.73 + 0.31) * 6.28318) * 0.42;
	float fine = sin((x * 17.0 + tear_seed * 0.61 + 0.12) * 6.28318) * 0.16;
	return tear_cut_y + (primary + secondary + fine) * tear_wave_strength;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	if (source.a < 0.02) {
		discard;
	}

	float cut_line = tear_curve(UV.x);
	float top_mask = 1.0 - smoothstep(cut_line - tear_edge_softness, cut_line + tear_edge_softness, UV.y);
	if (top_mask <= 0.01) {
		discard;
	}

	float edge = 1.0 - smoothstep(0.0, tear_edge_softness * 2.6, abs(UV.y - cut_line));
	vec3 edge_color = mix(source.rgb, tear_edge_tint.rgb, edge * 0.58);
	COLOR = vec4(edge_color, source.a * top_mask);
}
