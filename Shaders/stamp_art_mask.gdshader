shader_type canvas_item;
render_mode blend_mix, unshaded;

// The masks and the role's frame are sampled several times per screen pixel at their full resolution,
// so the art's edge and the thin frame line stay sharp and antialiased at small stamp sizes too.
const int MAX_EDGE_SAMPLES = 4;

uniform sampler2D stamp_mask_texture : repeat_disable, filter_linear;
uniform sampler2D type_mask_texture : repeat_disable, filter_linear;
uniform sampler2D type_frame_texture : repeat_disable, filter_linear;
uniform bool has_type_frame = false;
uniform bool has_stamp_mask = false;
uniform bool stamp_mask_follows_art = false;
uniform bool stamp_mask_uses_alpha = true;
uniform vec2 art_texture_size = vec2(1.0, 1.0);
uniform vec2 art_target_size = vec2(1.0, 1.0);
uniform float edge_softness : hint_range(0.0, 0.08) = 0.015;

#include "res://Shaders/foil_on_white.gdshaderinc"
#include "res://Shaders/stamp_ink_blot.gdshaderinc"

void vertex() {
	foil_stamp_uv = foil_stamp_uv_of(VERTEX);
	stamp_blot_position = stamp_blot_position_of(VERTEX);
}

float mask_value(vec4 mask_sample) {
	float luma = dot(mask_sample.rgb, vec3(0.2126, 0.7152, 0.0722));
	return max(mask_sample.a, luma);
}

// A mask with transparency marks its shape with opaque pixels; a fully opaque one draws it in black on white.
float stamp_mask_value(vec4 mask_sample) {
	if (stamp_mask_uses_alpha) {
		return mask_sample.a;
	}
	return 1.0 - dot(mask_sample.rgb, vec3(0.2126, 0.7152, 0.0722));
}

vec2 get_center_cover_uv(vec2 stamp_uv) {
	vec2 safe_texture_size = max(art_texture_size, vec2(1.0));
	vec2 safe_target_size = max(art_target_size, vec2(1.0));
	float texture_aspect = safe_texture_size.x / safe_texture_size.y;
	float target_aspect = safe_target_size.x / safe_target_size.y;
	vec2 art_uv = stamp_uv;

	if (texture_aspect > target_aspect) {
		float visible_width = target_aspect / texture_aspect;
		art_uv.x = (stamp_uv.x - 0.5) * visible_width + 0.5;
	} else if (texture_aspect < target_aspect) {
		float visible_height = texture_aspect / target_aspect;
		art_uv.y = (stamp_uv.y - 0.5) * visible_height + 0.5;
	}

	return clamp(art_uv, vec2(0.0), vec2(1.0));
}

void fragment() {
	vec2 stamp_uv = UV;
	vec4 source_art = texture(TEXTURE, get_center_cover_uv(stamp_uv));

	vec2 mask_texels = max(vec2(textureSize(type_mask_texture, 0)), vec2(textureSize(stamp_mask_texture, 0)));
	vec2 texels_per_pixel = fwidth(stamp_uv) * mask_texels;
	int samples = clamp(int(ceil(max(texels_per_pixel.x, texels_per_pixel.y))), 1, MAX_EDGE_SAMPLES);
	vec2 uv_dx = dFdx(stamp_uv);
	vec2 uv_dy = dFdy(stamp_uv);
	float softness = max(edge_softness, 0.0001);

	float art_coverage = 0.0;
	float frame_coverage = 0.0;
	vec3 frame_color = vec3(0.0);
	for (int x = 0; x < samples; x++) {
		for (int y = 0; y < samples; y++) {
			vec2 offset = (vec2(float(x), float(y)) + 0.5) / float(samples) - 0.5;
			vec2 sample_uv = stamp_uv + uv_dx * offset.x + uv_dy * offset.y;
			float type_mask = mask_value(textureLod(type_mask_texture, sample_uv, 0.0));
			vec4 frame = has_type_frame ? textureLod(type_frame_texture, sample_uv, 0.0) : vec4(0.0);
			float stamp_mask = 0.0;
			if (has_stamp_mask) {
				// A mask drawn over the art is cropped the same way as the art, so the two stay aligned.
				vec2 stamp_mask_uv = stamp_mask_follows_art ? get_center_cover_uv(sample_uv) : sample_uv;
				stamp_mask = smoothstep(0.0, softness, stamp_mask_value(textureLod(stamp_mask_texture, stamp_mask_uv, 0.0)));
			}

			// Inside the role's shape the art stops at the frame's inner edge, so the frame always shows.
			// A stamp mask drawn over the art adds its own shape in front of the frame; a stamp-shaped one
			// (full art prints) covers the whole stamp but stays behind the frame.
			float in_front = stamp_mask_follows_art ? stamp_mask : 0.0;
			float behind_frame = stamp_mask_follows_art ? 0.0 : stamp_mask;
			float frame_weight = frame.a * (1.0 - in_front);
			float inside_frame = clamp(type_mask - frame.a, 0.0, 1.0);
			art_coverage += max(max(inside_frame, behind_frame * (1.0 - frame.a)), in_front);
			frame_coverage += frame_weight;
			frame_color += frame.rgb * frame_weight;
		}
	}
	float sample_count = float(samples * samples);
	art_coverage /= sample_count;
	frame_coverage /= sample_count;
	frame_color /= sample_count;

	// The art and the frame are blended in one pass, so no background seeps in between them.
	float art_alpha = art_coverage * source_art.a;
	float alpha = art_alpha + frame_coverage;
	vec3 color = (source_art.rgb * art_alpha + frame_color) / max(alpha, 0.0001);
	// The ink blot takes ink away towards the stamp's white paper, rather than
	// letting the coloured square beneath show through the art.
	color = mix(vec3(1.0), color, stamp_blot_density(stamp_blot_position));
	COLOR = vec4(foil_on_white_tint(color, foil_stamp_uv), alpha * COLOR.a);
}
