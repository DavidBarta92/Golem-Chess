shader_type canvas_item;
render_mode blend_add, unshaded;

// Slowly turning fans of light from one point: what a rare stamp sends out of a
// torn pack, and what stands behind a full art stamp. Added light, so it needs
// nothing from what lies beneath.

uniform vec4 light_color : source_color = vec4(1.0, 0.76, 0.35, 1.0);
uniform float strength = 0.0;
// Where the light comes from, 0 to 1 across and down the rect.
uniform vec2 origin = vec2(0.5, 1.0);
// The rect's width over its height, so the fans stay round.
uniform float aspect = 1.0;
uniform float ray_count = 17.0;
uniform float seed = 0.0;
// How far the light reaches, in the rect's heights.
uniform float reach = 1.0;

void fragment() {
	vec2 point = (UV - origin) * vec2(aspect, 1.0);
	float away = length(point);
	float angle = atan(point.x, -point.y);
	float wide = sin(angle * ray_count + TIME * 0.55 + seed);
	float narrow = sin(angle * (ray_count * 0.41) - TIME * 0.85 + seed * 2.3);
	float rays = 0.42 + 0.58 * clamp(wide * 0.55 + narrow * 0.45 + 0.35, 0.0, 1.0);
	float falloff = pow(clamp(1.0 - away / reach, 0.0, 1.0), 1.9);
	COLOR = vec4(light_color.rgb * rays * falloff * strength, 1.0);
}
