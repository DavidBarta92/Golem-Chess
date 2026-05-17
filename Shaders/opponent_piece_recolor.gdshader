shader_type canvas_item;

uniform float recolor_strength : hint_range(0.0, 1.0) = 0.86;
uniform float shadow_chroma_strength : hint_range(0.0, 0.45) = 0.16;
uniform vec4 shadow_color : source_color = vec4(0.30, 0.33, 0.38, 1.0);
uniform vec4 mid_color : source_color = vec4(0.55, 0.57, 0.60, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.78, 0.79, 0.80, 1.0);

void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	float lower_ramp = smoothstep(0.05, 0.58, luminance);
	float upper_ramp = smoothstep(0.42, 0.96, luminance);
	vec3 gray_ramp = mix(shadow_color.rgb, mid_color.rgb, lower_ramp);
	gray_ramp = mix(gray_ramp, highlight_color.rgb, upper_ramp);

	vec3 original_chroma = source.rgb - vec3(luminance);
	float shadow_weight = 1.0 - smoothstep(0.30, 0.86, luminance);
	vec3 harmonized = gray_ramp + original_chroma * shadow_chroma_strength * shadow_weight;
	vec3 recolored = mix(source.rgb, harmonized, recolor_strength);
	COLOR = vec4(clamp(recolored, vec3(0.0), vec3(1.0)), source.a);
}
