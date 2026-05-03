shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float darken : hint_range(0.0, 1.0) = 0.22;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	float gray = dot(base.rgb, vec3(0.299, 0.587, 0.114));
	vec3 grayscale = vec3(gray) * (1.0 - darken);
	COLOR = vec4(mix(base.rgb, grayscale, strength), base.a);
}
