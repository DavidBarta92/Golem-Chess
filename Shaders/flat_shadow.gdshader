shader_type canvas_item;

// A texture's silhouette in one flat colour - the cast shadow the tutorial
// drawings use: no blur, just the shape again, offset and in grey.

uniform vec4 shadow_color : source_color = vec4(0.827, 0.835, 0.847, 1.0);

varying float v_alpha;

void vertex() {
	// The node's modulate, kept so the shadow can still be faded.
	v_alpha = COLOR.a;
}

void fragment() {
	COLOR = vec4(shadow_color.rgb, shadow_color.a * texture(TEXTURE, UV).a * v_alpha);
}
