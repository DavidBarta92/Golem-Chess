shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform sampler2D card_mask_texture : repeat_disable, filter_linear_mipmap;
uniform sampler2D type_mask_texture : repeat_disable, filter_linear_mipmap;
uniform bool has_card_mask = false;
uniform vec2 art_texture_size = vec2(1.0, 1.0);
uniform vec2 art_target_size = vec2(1.0, 1.0);
uniform float edge_softness : hint_range(0.0, 0.08) = 0.015;

float mask_value(vec4 mask_sample) {
	float luma = dot(mask_sample.rgb, vec3(0.2126, 0.7152, 0.0722));
	return max(mask_sample.a, luma);
}

vec2 get_center_cover_uv(vec2 card_uv) {
	vec2 safe_texture_size = max(art_texture_size, vec2(1.0));
	vec2 safe_target_size = max(art_target_size, vec2(1.0));
	float texture_aspect = safe_texture_size.x / safe_texture_size.y;
	float target_aspect = safe_target_size.x / safe_target_size.y;
	vec2 art_uv = card_uv;

	if (texture_aspect > target_aspect) {
		float visible_width = target_aspect / texture_aspect;
		art_uv.x = (card_uv.x - 0.5) * visible_width + 0.5;
	} else if (texture_aspect < target_aspect) {
		float visible_height = texture_aspect / target_aspect;
		art_uv.y = (card_uv.y - 0.5) * visible_height + 0.5;
	}

	return clamp(art_uv, vec2(0.0), vec2(1.0));
}

void fragment() {
	vec2 card_uv = UV;
	vec4 source_art = texture(TEXTURE, get_center_cover_uv(card_uv));
	vec4 art = vec4(source_art.rgb, source_art.a * COLOR.a);
	float type_mask = mask_value(texture(type_mask_texture, card_uv));
	float card_mask = has_card_mask ? mask_value(texture(card_mask_texture, card_uv)) : 0.0;
	float final_mask = has_card_mask ? card_mask : type_mask;
	float alpha = smoothstep(0.0, max(edge_softness, 0.0001), final_mask);
	art.a *= alpha;
	COLOR = art;
}
