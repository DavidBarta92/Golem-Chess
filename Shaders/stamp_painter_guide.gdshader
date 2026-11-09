shader_type canvas_item;
render_mode blend_mix, unshaded;

// The stamp painter's mask guide, laid over the drawing (a node the size of the
// art). It shades what the stamp will not show and draws the role's frame where
// the stamp draws it. The mapping is the inverse of stamp_art_mask.gdshader's
// get_center_cover_uv: the stamp shows the art scaled to cover it, cropped in
// the middle, and inside that only the role's mask minus the frame.

uniform sampler2D type_mask_texture : repeat_disable, filter_linear;
uniform sampler2D type_frame_texture : repeat_disable, filter_linear;
uniform bool has_type_frame = true;
uniform vec2 art_size = vec2(554.0, 700.0);
uniform vec2 stamp_size = vec2(168.7, 229.0);
uniform vec4 shade_color : source_color = vec4(0.09, 0.17, 0.26, 1.0);
uniform float shade_alpha : hint_range(0.0, 1.0) = 0.6;
uniform float frame_alpha : hint_range(0.0, 1.0) = 1.0;

float mask_value(vec4 mask_sample) {
	float luma = dot(mask_sample.rgb, vec3(0.2126, 0.7152, 0.0722));
	return max(mask_sample.a, luma);
}

vec2 stamp_uv_of(vec2 art_uv) {
	float art_aspect = art_size.x / max(art_size.y, 1.0);
	float stamp_aspect = stamp_size.x / max(stamp_size.y, 1.0);
	vec2 stamp_uv = art_uv;
	if (art_aspect > stamp_aspect) {
		stamp_uv.x = (art_uv.x - 0.5) * art_aspect / stamp_aspect + 0.5;
	} else if (art_aspect < stamp_aspect) {
		stamp_uv.y = (art_uv.y - 0.5) * stamp_aspect / art_aspect + 0.5;
	}
	return stamp_uv;
}

void fragment() {
	vec2 stamp_uv = stamp_uv_of(UV);
	bool on_stamp = stamp_uv.x >= 0.0 && stamp_uv.y >= 0.0 && stamp_uv.x <= 1.0 && stamp_uv.y <= 1.0;
	float type_mask = on_stamp ? mask_value(texture(type_mask_texture, stamp_uv)) : 0.0;
	vec4 frame = (on_stamp && has_type_frame) ? texture(type_frame_texture, stamp_uv) : vec4(0.0);
	float shown = clamp(type_mask - frame.a, 0.0, 1.0);

	float shade = shade_alpha * (1.0 - shown);
	float frame_weight = frame.a * frame_alpha;
	float alpha = frame_weight + shade * (1.0 - frame_weight);
	vec3 color = (frame.rgb * frame_weight + shade_color.rgb * shade * (1.0 - frame_weight)) / max(alpha, 0.0001);
	COLOR = vec4(color, alpha * COLOR.a);
}
