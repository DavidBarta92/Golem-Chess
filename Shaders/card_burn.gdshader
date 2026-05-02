shader_type canvas_item;

uniform float burn_progress : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.01, 0.25) = 0.08;
uniform float noise_scale : hint_range(1.0, 48.0) = 18.0;
uniform float noise_strength : hint_range(0.0, 0.45) = 0.22;
uniform float seed = 0.0;
uniform vec4 ember_color : source_color = vec4(1.0, 0.35, 0.05, 1.0);
uniform vec4 hot_color : source_color = vec4(1.0, 0.9, 0.22, 1.0);
uniform vec4 ash_color : source_color = vec4(0.08, 0.075, 0.065, 1.0);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float a = hash(i + seed);
	float b = hash(i + vec2(1.0, 0.0) + seed);
	float c = hash(i + vec2(0.0, 1.0) + seed);
	float d = hash(i + vec2(1.0, 1.0) + seed);

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += value_noise(p) * amplitude;
		p *= 2.03;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	float noise = fbm(UV * noise_scale);
	float dissolve_map = clamp(noise + (UV.y - 0.5) * noise_strength, 0.0, 1.0);
	float threshold = burn_progress * 1.12 - 0.06;
	float burned = smoothstep(dissolve_map - 0.035, dissolve_map + 0.035, threshold);
	float distance_to_edge = abs(dissolve_map - threshold);
	float edge = (1.0 - smoothstep(0.0, edge_width, distance_to_edge)) * (1.0 - burned);
	float ash = smoothstep(edge_width * 1.8, 0.0, threshold - dissolve_map) * (1.0 - burned);

	vec3 color = mix(base.rgb, ash_color.rgb, ash * 0.7);
	color = mix(color, ember_color.rgb, edge * 0.85);
	color = mix(color, hot_color.rgb, edge * edge * 0.45);

	COLOR = vec4(color, base.a * (1.0 - burned));
}
