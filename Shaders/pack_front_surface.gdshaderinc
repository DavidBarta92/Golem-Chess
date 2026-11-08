// The pack's printed face. pack_front_3d.gdshader draws what stays on the pack;
// pack_tear_flap_3d.gdshader defines PACK_TEAR_FLAP and draws the strip above the
// tear, curling away from the line behind the tear's front. Both are the same
// paper in the same light, so the strip is never a different colour from the pack.

#include "res://Shaders/pack_tear.gdshaderinc"

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

#ifdef PACK_TEAR_FLAP
uniform float pack_width = 1.965;
// The strip opens up like a lid behind the front: it bends in a curve of this
// radius, as far as this angle, and runs straight from there on. Its face stays
// towards the viewer, so it reads as a strip of the pack and not as an edge.
uniform float curl_radius = 0.6;
uniform float curl_max_angle = 0.5;
// The way the free end leaves the pack: this much up, this much towards the viewer.
uniform float curl_lift = 0.97;
uniform float curl_out = 0.24;
// The back of the paper.
uniform vec3 flap_back_color = vec3(0.86, 0.80, 0.70);
#endif

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

void vertex() {
	vec4 base = texture(albedo_texture, UV);
	float height_sample = has_height_texture ? texture(height_texture, UV).r : luminance(base.rgb);
	vec2 centered = UV * 2.0 - vec2(1.0);
	float dome = (1.0 - smoothstep(0.0, 1.08, dot(centered, centered))) * dome_strength;
	float alpha_mask = smoothstep(0.02, 0.2, base.a);
	float displacement = ((height_sample - 0.5) * height_strength + dome) * alpha_mask;
	VERTEX += NORMAL * displacement;

#ifdef PACK_TEAR_FLAP
	float peeled = max(tear_front - tear_along(UV.x), 0.0) * pack_width;
	if (peeled > 0.0) {
		float angle = min(peeled / curl_radius, curl_max_angle);
		float straight = max(peeled - curl_radius * curl_max_angle, 0.0);
		float back = curl_radius * sin(angle) + straight * cos(angle);
		float rise = curl_radius * (1.0 - cos(angle)) + straight * sin(angle);
		float front_x = (tear_direction > 0.0 ? tear_front - 0.5 : 0.5 - tear_front) * pack_width;
		VERTEX.x = front_x - tear_direction * back;
		VERTEX.y += rise * curl_lift;
		VERTEX.z += rise * curl_out;
		NORMAL = normalize(vec3(tear_direction * curl_out * sin(angle), 0.0, cos(angle)));
	}
#endif
}

void fragment() {
	vec4 base = texture(albedo_texture, UV);
	if (base.a < 0.025) {
		discard;
	}
	float alpha = smoothstep(0.035, 0.18, base.a);
	float cut_line = tear_curve(UV.x);
	float passed = tear_passed(UV.x);
	float lower_pack_mask = smoothstep(cut_line - tear_edge_softness, cut_line + tear_edge_softness, UV.y);
#ifdef PACK_TEAR_FLAP
	// Only what the tear has already freed; the pack itself draws the rest.
	if (passed < 0.5 || lower_pack_mask >= 0.99) {
		discard;
	}
	alpha *= 1.0 - lower_pack_mask;
#else
	if (passed > 0.5 && lower_pack_mask <= 0.01) {
		discard;
	}
	alpha *= mix(1.0, lower_pack_mask, passed);
#endif
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
	// The bare paper along the tear, where the printed surface came away.
	float fibre_depth = tear_fibre_depth(UV.x);
	float torn_edge = (1.0 - smoothstep(fibre_depth * 0.55, fibre_depth, abs(UV.y - cut_line))) * passed;
	vec3 torn_edge_color = mix(base.rgb, vec3(0.97, 0.93, 0.84), torn_edge * 0.92);
	vec3 foil_surface = mix(torn_edge_color, foil_color, foil_color_mix);

	vec3 printed = mix(torn_edge_color, foil_surface, clamp(foil_visibility, 0.0, foil_max_albedo_mix)) * alpha;
#ifdef PACK_TEAR_FLAP
	ALBEDO = FRONT_FACING ? printed : flap_back_color * alpha;
#else
	ALBEDO = printed;
#endif
	METALLIC = mix(0.0, foil_metallic, foil_mask);
	SPECULAR = mix(paper_specular, 1.0, foil_mask);
	ROUGHNESS = mix(paper_roughness, foil_roughness, foil_mask);
	CLEARCOAT = foil_mask * foil_clearcoat;
	CLEARCOAT_ROUGHNESS = mix(0.62, 0.035, foil_mask);
	EMISSION = foil_color * foil_visibility * foil_intensity * foil_emission_scale * alpha;
}
