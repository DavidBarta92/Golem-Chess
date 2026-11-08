// The tear across a pack: where it runs and how far it has got. Shared by the
// pack's front, its sides and the strip torn off, so all three cut along the
// same ragged line. Pack3DView sets these on all of them.

// How far the tear has run across the pack, 0 to 1.
uniform float tear_front = 0.0;
// 1 when it runs from the left edge, -1 from the right.
uniform float tear_direction = 1.0;
uniform float tear_cut_y = 0.085;
uniform float tear_wave_strength = 0.012;
uniform float tear_seed = 0.0;
uniform float tear_edge_softness = 0.006;

float tear_curve(float x) {
	float primary = sin((x * 3.35 + tear_seed) * 6.28318);
	float secondary = sin((x * 8.2 + tear_seed * 1.73 + 0.31) * 6.28318) * 0.42;
	float fine = sin((x * 17.0 + tear_seed * 0.61 + 0.12) * 6.28318) * 0.16;
	return tear_cut_y + (primary + secondary + fine) * tear_wave_strength;
}

// How far along the tear x lies, 0 to 1 from the edge it began at.
float tear_along(float x) {
	return tear_direction > 0.0 ? x : 1.0 - x;
}

// 1 where the tear has passed x, 0 where it has not got to yet.
float tear_passed(float x) {
	return step(0.0005, tear_front) * step(tear_along(x), tear_front);
}

// How deep the torn paper's bare, fibrous edge reaches under the line at x.
float tear_fibre_depth(float x) {
	float fibres = 2.6 + 1.3 * sin(x * 140.0 + tear_seed * 40.0) + 0.9 * sin(x * 311.0 + tear_seed * 17.0);
	return tear_edge_softness * max(fibres, 0.6);
}
