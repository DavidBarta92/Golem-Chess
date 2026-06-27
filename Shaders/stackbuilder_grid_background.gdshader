shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.976, 0.906, 0.808, 1.0);
uniform vec4 line_color : source_color = vec4(0.851, 0.816, 0.835, 1.0);
uniform float cell_size = 32.0;
uniform float line_width = 0.65;

void fragment() {
	vec2 grid_position = mod(FRAGCOORD.xy, vec2(cell_size));
	float nearest_line = min(min(grid_position.x, cell_size - grid_position.x), min(grid_position.y, cell_size - grid_position.y));
	float line_alpha = 1.0 - smoothstep(line_width, line_width + 0.75, nearest_line);
	COLOR = mix(base_color, line_color, line_alpha);
}
