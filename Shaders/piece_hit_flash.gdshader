shader_type canvas_item;

// A struck piece lit up for the hitstop: its own drawing, washed toward
// `flash_color` by `flash_amount`, with the silhouette left as it is.
uniform vec4 flash_color : source_color = vec4(1.0, 0.95, 0.78, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	COLOR.rgb = mix(COLOR.rgb, flash_color.rgb, flash_amount);
}
