shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(0.78, 0.08, 0.08, 1.0);
uniform float grayscale_strength : hint_range(0.0, 1.0) = 0.75;
uniform float tint_strength : hint_range(0.0, 1.0) = 0.38;

void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	float gray = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	vec3 desaturated = mix(source.rgb, vec3(gray), grayscale_strength);
	vec3 tinted = mix(desaturated, tint_color.rgb, tint_strength);
	COLOR = vec4(tinted, source.a);
}
