shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D card_mask_texture : repeat_disable, filter_linear_mipmap;
uniform sampler2D type_mask_texture : repeat_disable, filter_linear_mipmap;
uniform bool has_card_mask = false;
uniform float edge_softness : hint_range(0.0, 0.08) = 0.015;

float mask_value(vec4 mask_sample) {
	float luma = dot(mask_sample.rgb, vec3(0.2126, 0.7152, 0.0722));
	return max(mask_sample.a, luma);
}

void fragment() {
	vec4 art = texture(TEXTURE, UV) * COLOR;
	float type_mask = mask_value(texture(type_mask_texture, UV));
	float card_mask = has_card_mask ? mask_value(texture(card_mask_texture, UV)) : 0.0;
	float final_mask = max(type_mask, card_mask);
	float alpha = smoothstep(0.0, max(edge_softness, 0.0001), final_mask);
	art.a *= alpha;
	COLOR = art;
}
