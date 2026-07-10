shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D side_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D mask_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform float pack_width = 1.965;
uniform float pack_height = 2.62;
uniform float alpha_threshold = 0.035;
uniform vec3 side_tint = vec3(0.23, 0.18, 0.30);
uniform float tear_cut_progress = 0.0;
uniform float tear_cut_y = 0.085;
uniform float tear_wave_strength = 0.012;
uniform float tear_seed = 0.0;
uniform float tear_edge_softness = 0.006;

varying vec2 projected_uv;
varying float side_amount;

float tear_curve(float x) {
	float primary = sin((x * 3.35 + tear_seed) * 6.28318);
	float secondary = sin((x * 8.2 + tear_seed * 1.73 + 0.31) * 6.28318) * 0.42;
	float fine = sin((x * 17.0 + tear_seed * 0.61 + 0.12) * 6.28318) * 0.16;
	return tear_cut_y + (primary + secondary + fine) * tear_wave_strength;
}

void vertex() {
	projected_uv = vec2(
		VERTEX.x / max(pack_width, 0.001) + 0.5,
		0.5 - VERTEX.y / max(pack_height, 0.001)
	);
	side_amount = clamp(max(abs(NORMAL.x), abs(NORMAL.y)), 0.0, 1.0);
}

void fragment() {
	if (projected_uv.x < 0.0 || projected_uv.x > 1.0 || projected_uv.y < 0.0 || projected_uv.y > 1.0) {
		discard;
	}

	vec4 mask_sample = texture(mask_texture, projected_uv);
	if (mask_sample.a < alpha_threshold) {
		discard;
	}

	vec4 side_sample = texture(side_texture, projected_uv);
	float alpha = smoothstep(alpha_threshold, 0.22, mask_sample.a);
	float cut_line = tear_curve(projected_uv.x);
	float lower_pack_mask = smoothstep(cut_line - tear_edge_softness, cut_line + tear_edge_softness, projected_uv.y);
	if (tear_cut_progress > 0.01 && lower_pack_mask <= 0.01) {
		discard;
	}
	alpha *= mix(1.0, lower_pack_mask, clamp(tear_cut_progress, 0.0, 1.0));
	vec3 darkened_side = mix(side_sample.rgb * 0.46, side_tint, 0.42);
	vec3 final_color = mix(side_sample.rgb * 0.82, darkened_side, side_amount);

	ALBEDO = final_color;
	ALPHA = alpha;
	METALLIC = 0.0;
	SPECULAR = 0.22;
	ROUGHNESS = 0.78;
}
