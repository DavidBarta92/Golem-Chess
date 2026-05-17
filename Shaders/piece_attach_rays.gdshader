shader_type canvas_item;
render_mode blend_add;

uniform sampler2D gradient : repeat_disable, filter_linear;
uniform float spread = 0.5;
uniform float cutoff = 0.39;
uniform float size = 10.0;
uniform float speed = 1.4;
uniform float ray1_density = 8.0;
uniform float ray2_density = 10.0;
uniform float ray2_intensity = 0.3;
uniform float core_intensity = 2.0;
uniform bool hdr = false;
uniform float seed = 5.0;
uniform float alpha_strength : hint_range(0.0, 1.0) = 1.0;

float random(vec2 _uv) {
	return fract(sin(dot(_uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(in vec2 uv) {
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
	vec2 centered_uv = (UV - 0.5) * size;
	float radius = length(centered_uv);
	float angle = atan(centered_uv.y, centered_uv.x) + 3.14159265359;

	vec2 ray1 = vec2(angle * ray1_density + TIME * speed + seed + sin(angle * 3.0), radius * 2.0);
	vec2 ray2 = vec2(angle * ray2_density + TIME * speed * 1.5 + seed + cos(angle * 2.0), radius * 2.0);

	float cut = 1.0 - smoothstep(cutoff, cutoff + 0.2, radius);
	ray1 *= cut;
	ray2 *= cut;

	float rays = noise(ray1) + (noise(ray2) * ray2_intensity);
	if (!hdr) {
		rays = clamp(rays, 0.0, 1.0);
	}

	float radial_fade = 1.0 - smoothstep(spread * 0.18, spread * 1.05, radius);
	rays *= radial_fade;
	float core = smoothstep(0.2, 0.0, radius) * core_intensity;
	rays += core;

	vec4 gradient_color = texture(gradient, vec2(clamp(rays, 0.0, 1.0), 0.5));
	float visible_rays = smoothstep(0.08, 0.45, rays);
	vec3 shine = vec3(rays) * gradient_color.rgb * 1.35;

	float edge_fade = smoothstep(0.0, 0.04, UV.x)
		* smoothstep(0.0, 0.04, UV.y)
		* smoothstep(0.0, 0.04, 1.0 - UV.x)
		* smoothstep(0.0, 0.04, 1.0 - UV.y);
	float alpha = visible_rays * gradient_color.a * alpha_strength * edge_fade;
	COLOR = vec4(shine * visible_rays * alpha_strength * edge_fade, alpha);
}
