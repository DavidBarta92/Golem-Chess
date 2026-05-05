shader_type canvas_item;
render_mode blend_mix;

uniform float strength : hint_range(0.0, 1.0) = 0.34;
uniform float speed = 0.72;
uniform float band_scale = 13.0;
uniform float shimmer_time = 0.0;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	float max_channel = max(base.r, max(base.g, base.b));
	float marker_mask = smoothstep(0.72, 0.95, base.a) * smoothstep(0.38, 0.72, max_channel);
	float band = sin((UV.x + UV.y * 0.72 + shimmer_time * speed) * band_scale);
	float shimmer_mask = smoothstep(0.22, 1.0, band * 0.5 + 0.5);
	float noise = random(floor(UV * 54.0) + vec2(shimmer_time * 7.0, 0.0));
	float shine_amount = marker_mask * (shimmer_mask * 0.8 + noise * 0.2) * strength;
	vec3 shine_color = mix(vec3(0.65, 0.88, 1.0), vec3(1.0, 0.9, 0.46), shimmer_mask);
	base.rgb = mix(base.rgb, max(base.rgb, shine_color), shine_amount);
	base.rgb += shine_color * shine_amount * 0.28;
	COLOR = base;
}
