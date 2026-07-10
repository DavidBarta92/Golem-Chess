shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D height_texture : filter_linear_mipmap, repeat_disable;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_disable;
uniform sampler2D roughness_texture : filter_linear_mipmap, repeat_disable;
uniform sampler2D foil_mask_texture : filter_linear_mipmap, repeat_disable;

uniform bool has_height_texture = false;
uniform bool has_normal_texture = false;
uniform bool has_roughness_texture = false;
uniform bool has_foil_mask_texture = false;

uniform float height_strength = 0.11;
uniform float dome_strength = 0.20;
uniform float normal_depth = 0.78;
uniform float default_roughness = 0.80;
uniform float paper_normal_mix = 0.42;
uniform float paper_specular = 0.20;
uniform float foil_intensity = 0.72;
uniform float foil_metallic = 0.82;
uniform float foil_roughness = 0.055;
uniform float foil_clearcoat = 0.9;
uniform float foil_max_albedo_mix = 0.46;
uniform float foil_color_mix = 0.58;
uniform float foil_emission_scale = 0.20;
uniform float foil_layer_opacity = 0.0;
uniform vec2 foil_tilt_offset = vec2(0.0, 0.0);
uniform float tear_cut_progress = 0.0;
uniform float tear_cut_y = 0.085;
uniform float tear_wave_strength = 0.012;
uniform float tear_seed = 0.0;
uniform float tear_edge_softness = 0.006;

float luminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

vec3 foil_palette(float hue) {
	float t = fract(hue);
	vec3 magenta = vec3(0.95, 0.20, 0.82);
	vec3 rose = vec3(1.0, 0.35, 0.50);
	vec3 amber = vec3(1.0, 0.72, 0.22);
	vec3 violet = vec3(0.58, 0.22, 0.94);
	if (t < 0.34) {
		return mix(magenta, rose, smoothstep(0.0, 0.34, t));
	}
	if (t < 0.62) {
		return mix(rose, amber, smoothstep(0.34, 0.62, t));
	}
	return mix(amber, violet, smoothstep(0.62, 1.0, t));
}

float tear_curve(float x) {
	float primary = sin((x * 3.35 + tear_seed) * 6.28318);
	float secondary = sin((x * 8.2 + tear_seed * 1.73 + 0.31) * 6.28318) * 0.42;
	float fine = sin((x * 17.0 + tear_seed * 0.61 + 0.12) * 6.28318) * 0.16;
	return tear_cut_y + (primary + secondary + fine) * tear_wave_strength;
}

void vertex() {
	vec4 base = texture(albedo_texture, UV);
	float height_sample = has_height_texture ? texture(height_texture, UV).r : luminance(base.rgb);
	vec2 centered = UV * 2.0 - vec2(1.0);
	float dome = (1.0 - smoothstep(0.0, 1.08, dot(centered, centered))) * dome_strength;
	float alpha_mask = smoothstep(0.02, 0.2, base.a);
	float displacement = ((height_sample - 0.5) * height_strength + dome) * alpha_mask;
	VERTEX += NORMAL * displacement;
}

void fragment() {
	vec4 base = texture(albedo_texture, UV);
	if (base.a < 0.025) {
		discard;
	}
	float alpha = smoothstep(0.035, 0.18, base.a);
	float cut_line = tear_curve(UV.x);
	float lower_pack_mask = smoothstep(cut_line - tear_edge_softness, cut_line + tear_edge_softness, UV.y);
	if (tear_cut_progress > 0.01 && lower_pack_mask <= 0.01) {
		discard;
	}
	alpha *= mix(1.0, lower_pack_mask, clamp(tear_cut_progress, 0.0, 1.0));
	ALPHA = alpha;
	ALPHA_SCISSOR_THRESHOLD = 0.035;

	vec3 normal_sample = has_normal_texture ? texture(normal_texture, UV).rgb : vec3(0.5, 0.5, 1.0);
	normal_sample = mix(vec3(0.5, 0.5, 1.0), normal_sample, paper_normal_mix);
	NORMAL_MAP = normal_sample;
	NORMAL_MAP_DEPTH = normal_depth;

	float roughness_sample = has_roughness_texture ? texture(roughness_texture, UV).r : default_roughness;
	float paper_roughness = clamp(mix(roughness_sample, default_roughness, 0.72), 0.68, 0.94);
	float foil_mask = has_foil_mask_texture ? texture(foil_mask_texture, UV).r : 0.0;
	foil_mask *= alpha * foil_layer_opacity;

	float ndv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndv, 2.15);
	vec2 foil_uv = UV + foil_tilt_offset;
	float wave = sin((foil_uv.x * 2.1 - foil_uv.y * 1.35 + fresnel * 1.8) * 6.28318) * 0.5 + 0.5;
	vec3 foil_color = foil_palette(fract(foil_uv.x * 0.28 + foil_uv.y * 0.16 + fresnel * 0.72 + wave * 0.18));
	float foil_visibility = foil_mask * (0.22 + fresnel * 0.7 + wave * 0.16);
	float torn_edge = (1.0 - smoothstep(0.0, tear_edge_softness * 2.4, abs(UV.y - cut_line))) * tear_cut_progress;
	vec3 torn_edge_color = mix(base.rgb, vec3(0.92, 0.82, 0.66), torn_edge * 0.62);
	vec3 foil_surface = mix(torn_edge_color, foil_color, foil_color_mix);

	ALBEDO = mix(torn_edge_color, foil_surface, clamp(foil_visibility, 0.0, foil_max_albedo_mix)) * alpha;
	METALLIC = mix(0.0, foil_metallic, foil_mask);
	SPECULAR = mix(paper_specular, 1.0, foil_mask);
	ROUGHNESS = mix(paper_roughness, foil_roughness, foil_mask);
	CLEARCOAT = foil_mask * foil_clearcoat;
	CLEARCOAT_ROUGHNESS = mix(0.62, 0.035, foil_mask);
	EMISSION = foil_color * foil_visibility * foil_intensity * foil_emission_scale * alpha;
}
