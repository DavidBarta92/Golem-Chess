shader_type canvas_item;

uniform float speed : hint_range(0.0, 2.0) = 0.24;
uniform float glow_strength : hint_range(0.0, 2.0) = 2.0;
uniform float edge_softness : hint_range(0.0, 1.0) = 0.85;
uniform float pulse_strength : hint_range(0.0, 1.0) = 1.0;
uniform float pulse_min_scale : hint_range(0.5, 1.5) = 0.88;
uniform float pulse_max_scale : hint_range(0.5, 1.5) = 1.18;
uniform vec4 color : source_color = vec4(1.0, 0.94, 0.78, 1.0);

float get_pulse_wave() {
	return 0.5 + 0.5 * sin(TIME * speed * 6.0);
}

void vertex() {
	float pulse_scale = mix(1.0, mix(pulse_min_scale, pulse_max_scale, get_pulse_wave()), pulse_strength);
	VERTEX *= pulse_scale;
}

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv);

	float fade = smoothstep(0.8, 0.2, dist);
	float edge = smoothstep(0.5, 0.5 - edge_softness, dist);
	float pulse = mix(1.0, mix(0.72, 1.18, get_pulse_wave()), pulse_strength);

	float final = fade * edge * glow_strength * pulse;
	COLOR = vec4(color.rgb, final * color.a);
}
