shader_type canvas_item;

// Horizontal paper gradient for the GlobalTopBar background: a slightly muted
// left edge, the lightest cream around light_stop, then an eased fall-off into
// the darker sand tone from dark_stop to the right edge. A faint static grain
// keeps it from reading as a flat vector fill. The ColorRect's own color (and
// modulate) tints the result, so leave it white for the colors below.

uniform vec4 left_color : source_color = vec4(0.914, 0.882, 0.804, 1.0);
uniform vec4 light_color : source_color = vec4(0.945, 0.922, 0.851, 1.0);
uniform vec4 dark_color : source_color = vec4(0.827, 0.796, 0.718, 1.0);
uniform float light_stop : hint_range(0.0, 1.0) = 0.28;
uniform float dark_stop : hint_range(0.0, 1.0) = 0.70;
uniform float grain_strength : hint_range(0.0, 0.1) = 0.025;

float pixel_hash(vec2 point) {
	point = fract(point * vec2(123.34, 456.21));
	point += dot(point, point + 45.32);
	return fract(point.x * point.y);
}

void fragment() {
	float x = UV.x;
	vec3 color;
	if (x < light_stop) {
		color = mix(left_color.rgb, light_color.rgb, smoothstep(0.0, max(light_stop, 0.0001), x));
	} else {
		color = mix(light_color.rgb, dark_color.rgb, smoothstep(light_stop, max(dark_stop, light_stop + 0.0001), x));
	}
	color += (pixel_hash(FRAGCOORD.xy) - 0.5) * grain_strength;
	COLOR = vec4(clamp(color, 0.0, 1.0), 1.0) * COLOR;
}
