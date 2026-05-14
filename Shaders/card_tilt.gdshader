shader_type canvas_item;

uniform float x_rot = 0.0;
uniform float y_rot = 0.0;
uniform float warp_strength = 0.045;
uniform float shine_strength = 0.18;

void fragment() {
	vec2 centered = (UV * 2.0) - vec2(1.0);
	float xr = radians(x_rot);
	float yr = radians(y_rot);
	vec2 warped_uv = UV;
	warped_uv.x += centered.x * abs(centered.y) * sin(yr) * warp_strength;
	warped_uv.y += centered.y * abs(centered.x) * sin(xr) * warp_strength;

	vec2 clamped_uv = clamp(warped_uv, vec2(0.0), vec2(1.0));
	float in_bounds = step(0.0, warped_uv.x) * step(warped_uv.x, 1.0) * step(0.0, warped_uv.y) * step(warped_uv.y, 1.0);
	vec4 tex = texture(TEXTURE, clamped_uv);
	float light = 1.0 + (centered.x * sin(yr) + centered.y * sin(xr)) * 0.18;
	float glare = 1.0 - smoothstep(0.0, 0.55, distance(UV, vec2(0.24 + sin(yr) * 0.18, 0.18 + sin(xr) * 0.18)));
	vec3 color = tex.rgb * light + vec3(0.88, 0.95, 1.0) * glare * shine_strength;
	COLOR = vec4(color, tex.a * in_bounds);
}
