shader_type canvas_item;

// Flat shade over the lower part of a Collection set tag while it is tucked
// behind the book. The shade multiplies, so the tag's ink lines stay black and
// its paper turns the same grey the book is shaded with.

uniform vec4 shadow_color : source_color = vec4(0.827, 0.835, 0.847, 1.0);
// UV.y where the shade begins; everything below it is shaded.
uniform float shadow_start : hint_range(0.0, 1.0) = 0.667;
// 1.0 while the tag sits behind the book, 0.0 once it is pulled in front.
uniform float shadow_amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV) * COLOR;
	float shade = step(shadow_start, UV.y) * shadow_amount;
	color.rgb *= mix(vec3(1.0), shadow_color.rgb, shade);
	COLOR = color;
}
