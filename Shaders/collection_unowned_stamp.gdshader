shader_type canvas_item;
render_mode unshaded;

// For a CanvasGroup around a stamp the player does not own: the whole stamp,
// flattened first, turns black and white and half see-through. Doing it on the
// group keeps the stamp's own layers (face, art, frame) from showing through
// each other the way per-node transparency would.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float opacity : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	if (c.a > 0.0001) {
		c.rgb /= c.a;
	}
	float grey = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR *= vec4(vec3(grey), c.a * opacity);
}
