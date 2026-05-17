shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float intensity : hint_range(0.0, 0.16) = 0.045;
uniform float grain_size : hint_range(1.0, 8.0) = 1.35;
uniform float animation_speed : hint_range(0.0, 60.0) = 18.0;

float hash(vec2 point) {
	point = fract(point * vec2(123.34, 456.21));
	point += dot(point, point + 45.32);
	return fract(point.x * point.y);
}

void fragment() {
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	vec2 grain_coord = floor(FRAGCOORD.xy / max(grain_size, 0.001));
	float frame = floor(TIME * animation_speed);
	float noise = hash(grain_coord + vec2(frame, frame * 0.37));
	float grain = (noise - 0.5) * intensity;
	COLOR = vec4(clamp(screen_color.rgb + vec3(grain), vec3(0.0), vec3(1.0)), screen_color.a);
}
