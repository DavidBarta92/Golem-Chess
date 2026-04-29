shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.16;
uniform float speed = 0.65;
uniform float band_scale = 14.0;
uniform float corner_radius : hint_range(0.0, 0.5) = 0.075;
uniform float shimmer_time = 0.0;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

float rounded_alpha(vec2 uv, float radius) {
	vec2 p = abs(uv * 2.0 - 1.0) - vec2(1.0 - radius);
	float d = length(max(p, vec2(0.0))) - radius;
	return 1.0 - smoothstep(0.0, 0.02, d);
}

void fragment() {
	float band = sin((UV.x + UV.y * 0.72 + shimmer_time * speed) * band_scale);
	float fine_noise = random(floor(UV * 56.0) + vec2(shimmer_time * 8.0, 0.0));
	float mask = smoothstep(0.25, 1.0, band * 0.5 + 0.5);
	vec3 shine = mix(vec3(0.65, 0.88, 1.0), vec3(1.0, 0.86, 0.42), mask);
	float alpha = (mask * 0.75 + fine_noise * 0.25) * strength * rounded_alpha(UV, corner_radius);
	COLOR = vec4(shine, alpha);
}
