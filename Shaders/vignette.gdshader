shader_type canvas_item;
render_mode unshaded;

// Screen-space vignette overlay. Meant to sit on a full-rect ColorRect in a
// high-layer CanvasLayer (same pattern as paper_texture.gdshader), darkening
// the frame edges by fading alpha in from inner_radius to outer_radius.

uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float inner_radius : hint_range(0.0, 1.5) = 0.35;
uniform float outer_radius : hint_range(0.0, 2.0) = 0.95;
uniform float intensity : hint_range(0.0, 1.0) = 0.55;

void fragment() {
	float dist = length(UV - vec2(0.5)) * 2.0;
	float vignette = smoothstep(inner_radius, outer_radius, dist) * intensity;
	COLOR = vec4(vignette_color.rgb, vignette);
}
