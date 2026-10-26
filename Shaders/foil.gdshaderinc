// A stamp's foil (see Scripts/FoilStyle.gd): bands of colour from a gradient, bent by a
// height-map pattern, flowing while the stamp moves or tilts, with optional glitter.
// StampVisual fills these uniforms from the print's FoilStyle. Built on "Rainbow Flow
// (CanvasItem)" by muzi1983 and "2D Holographic Card Shader" by AquaBaby, both on
// godotshaders.com under CC0. Everything carries a foil_ prefix, so the shaders that
// include this keep their own uniform names.

uniform sampler2D foil_gradient : repeat_disable, filter_linear;
uniform bool foil_gradient_mirrored = true;
uniform sampler2D foil_height_map : repeat_enable, filter_linear;
uniform bool foil_has_height_map = false;
uniform float foil_pattern_scale = 1.0;
uniform float foil_pattern_bend = 0.5;
uniform float foil_band_density = 1.0;
uniform vec2 foil_band_direction = vec2(0.7071, 0.7071);
uniform float foil_speed = 0.5;
// Like the shimmer's time, StampVisual advances it only while the stamp moves or tilts,
// so the foil stands still on a resting stamp.
uniform float foil_flow_time = 0.0;
uniform float foil_tint_strength : hint_range(0.0, 1.0) = 1.0;
uniform float foil_shine_strength : hint_range(0.0, 1.0) = 0.0;
uniform float foil_sparkle_amount : hint_range(0.0, 1.0) = 0.0;
uniform float foil_sparkle_size = 6.0;
uniform vec2 foil_stamp_size = vec2(168.7, 229.0);

// stamp_uv runs from 0 to 1 across the whole stamp in everything below.
float foil_pattern_height(vec2 stamp_uv) {
	if (!foil_has_height_map) {
		return 0.0;
	}
	// One tile spans foil_pattern_scale stamp heights, centred on the stamp, so a
	// centred pattern (waves, sunburst) sits in the stamp's middle.
	vec2 aspect = vec2(foil_stamp_size.x / max(foil_stamp_size.y, 1.0), 1.0);
	vec2 pattern_uv = (stamp_uv - 0.5) * aspect / max(foil_pattern_scale, 0.001) + 0.5;
	return texture(foil_height_map, pattern_uv).r;
}

vec3 foil_band_color(vec2 stamp_uv) {
	float run = dot(stamp_uv - 0.5, foil_band_direction) * foil_band_density
		+ foil_flow_time * foil_speed
		+ foil_pattern_height(stamp_uv) * foil_pattern_bend;
	float u = foil_gradient_mirrored ? abs(fract(run) * 2.0 - 1.0) : fract(run);
	return texture(foil_gradient, vec2(u, 0.5)).rgb;
}

float foil_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// Glitter: at most one point per grid cell, each flashing at its own moment of the flow,
// so a resting stamp keeps a few lit and a moving one twinkles.
float foil_sparkle(vec2 stamp_uv) {
	if (foil_sparkle_amount <= 0.0) {
		return 0.0;
	}
	vec2 grid = stamp_uv * foil_stamp_size / max(foil_sparkle_size, 0.5);
	vec2 cell = floor(grid);
	if (foil_hash(cell) > foil_sparkle_amount) {
		return 0.0;
	}
	float r1 = foil_hash(cell + vec2(17.3, 5.1));
	float r2 = foil_hash(cell + vec2(3.7, 29.9));
	vec2 local = fract(grid) - (vec2(r1, r2) * 0.6 + 0.2);
	float point = 1.0 - smoothstep(0.0, 0.3, length(local));
	float arm_x = (1.0 - smoothstep(0.0, 0.06, abs(local.y))) * (1.0 - smoothstep(0.0, 0.45, abs(local.x)));
	float arm_y = (1.0 - smoothstep(0.0, 0.06, abs(local.x))) * (1.0 - smoothstep(0.0, 0.45, abs(local.y)));
	float phase = fract(r1 * 13.7 + foil_flow_time * foil_speed * (0.6 + r2));
	float flash = smoothstep(0.0, 0.15, phase) * (1.0 - smoothstep(0.15, 0.5, phase));
	return clamp(point + (arm_x + arm_y) * 0.6, 0.0, 1.0) * flash;
}
