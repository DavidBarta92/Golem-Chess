shader_type canvas_item;
render_mode blend_mix;

uniform float morph_progress : hint_range(0.0, 1.0) = 0.0;
uniform float noise_strength : hint_range(0.0, 0.35) = 0.08;
uniform float shine_strength : hint_range(0.0, 0.8) = 0.22;
uniform vec4 shine_color : source_color = vec4(1.0, 0.88, 0.22, 1.0);

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	vec4 target_color = texture(TEXTURE, UV) * COLOR;
	float grain = noise(UV * 18.0 + vec2(TIME * 1.7, -TIME * 1.1));
	float reveal_noise = (grain - 0.5) * noise_strength * morph_progress;
	float reveal = clamp(morph_progress + reveal_noise, 0.0, 1.0);
	float shine = (1.0 - abs(reveal - 0.5) * 2.0) * shine_strength * target_color.a;
	target_color.rgb += shine_color.rgb * shine;
	target_color.a *= reveal;
	COLOR = target_color;
}
