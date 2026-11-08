shader_type canvas_item;

// The ink that floods the screen from a full art stamp, along a ragged front,
// with a lit rim where it is still running.

uniform vec4 flood_color : source_color = vec4(0.05, 0.075, 0.12, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.76, 0.35, 1.0);
uniform sampler2D front_noise : repeat_enable, filter_linear;
// Where it starts, 0 to 1 across and down.
uniform vec2 origin = vec2(0.5);
uniform float aspect = 1.78;
// 0 none, 1 the whole screen.
uniform float progress = 0.0;
uniform float raggedness = 0.34;

void fragment() {
	vec2 point = (UV - origin) * vec2(aspect, 1.0);
	float away = length(point);
	vec2 noise_uv = UV * vec2(aspect, 1.0) * 1.7;
	float wander = texture(front_noise, noise_uv).r * 0.75 + texture(front_noise, noise_uv * 2.3).g * 0.25;
	float reach = away + (wander - 0.5) * raggedness;
	float front = progress * (aspect * 0.75 + 0.5 + raggedness);
	float covered = 1.0 - smoothstep(front - 0.015, front + 0.015, reach);
	float rim = covered * (1.0 - smoothstep(0.0, 0.09, front - reach)) * step(progress, 0.995);
	COLOR = vec4(mix(flood_color.rgb, rim_color.rgb, rim), flood_color.a * covered);
}
