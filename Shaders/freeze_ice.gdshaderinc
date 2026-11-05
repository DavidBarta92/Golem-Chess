// The ice on a frozen piece and on its square (Docs/Style/FREEZE_ICE.md). Both shaders
// include this, so the two read as one sheet of ice. Everything carries an ice_ prefix,
// and every length here is in board units, the same on a piece and on a square.

// 0 is no ice, 1 is all of it. FreezeEffectAnimator tweens this.
uniform float ice_freeze : hint_range(0.0, 1.0) = 1.0;
// Set per square, so neighbours do not share a pattern.
uniform vec2 ice_seed = vec2(0.0);

// See tools/generate_ice_textures.py for what each channel holds.
uniform sampler2D ice_surface : repeat_enable, filter_linear_mipmap;
uniform sampler2D ice_room : repeat_disable, filter_linear;
// How wide one tile of ice_surface is laid. Smaller makes finer shards.
uniform float ice_surface_size : hint_range(8.0, 80.0) = 34.0;

group_uniforms Colours;
// The world's own paper and ink, so the ice belongs to the drawing.
uniform vec3 ice_light : source_color = vec3(0.957, 0.941, 0.902);
uniform vec3 ice_body : source_color = vec3(0.70, 0.80, 0.84);
uniform vec3 ice_deep : source_color = vec3(0.09, 0.17, 0.26);
group_uniforms;

group_uniforms Reflection;
// The row of the room the ice looks at, 0 the top of the room and 1 the bottom,
// and how far a leaning surface looks away from it, in room widths.
uniform float ice_room_row : hint_range(0.0, 1.0) = 0.16;
uniform float ice_room_spread : hint_range(0.0, 1.5) = 0.5;
// The room is flattened into washes: below ice_room_dark it reads as shadow,
// above ice_room_bright as light, and in between the ice stays clear.
uniform float ice_room_dark : hint_range(0.0, 1.0) = 0.42;
uniform float ice_room_bright : hint_range(0.0, 1.0) = 0.9;
uniform float ice_room_dark_strength : hint_range(0.0, 1.0) = 0.24;
uniform float ice_room_bright_strength : hint_range(0.0, 1.0) = 0.26;
group_uniforms;

group_uniforms Glints;
// Where the light comes from, as a lean of the surface, and how tightly a surface
// has to face it to catch it. The light drifts by ice_glint_drift, so a shard
// catches it now and then.
uniform vec2 ice_glint_lean = vec2(-0.42, -0.62);
uniform float ice_glint_size : hint_range(0.0, 1.0) = 0.2;
uniform float ice_glint_strength : hint_range(0.0, 1.0) = 0.8;
uniform float ice_glint_drift : hint_range(0.0, 1.0) = 0.16;
uniform float ice_glint_speed : hint_range(0.0, 2.0) = 0.35;
group_uniforms;

group_uniforms Cracks;
uniform float ice_crack_strength : hint_range(0.0, 1.0) = 0.8;
uniform float ice_crack_thinness : hint_range(0.0, 1.0) = 0.55;
group_uniforms;

group_uniforms Sparkles;
// Star points, one per grid cell at most. ice_sparkle_amount is the share of
// cells with one, ice_sparkle_grid the cell's width.
uniform float ice_sparkle_amount : hint_range(0.0, 1.0) = 0.3;
uniform float ice_sparkle_grid : hint_range(0.5, 10.0) = 3.0;
uniform float ice_sparkle_speed : hint_range(0.0, 2.0) = 0.3;
group_uniforms;

const float ICE_FRONT_SOFTNESS = 0.14;

// xy the surface's lean, -1..1, z cracks, w milkiness.
vec4 ice_surface_at(vec2 units) {
	vec4 surface = texture(ice_surface, units / ice_surface_size + ice_seed);
	surface.xy = surface.xy * 2.0 - 1.0;
	return surface;
}

// place: 0 freezes first, 1 freezes last. Melting runs the same way backwards.
float ice_reveal(float place) {
	return smoothstep(place, place + ICE_FRONT_SOFTNESS, ice_freeze * (1.0 + ICE_FRONT_SOFTNESS));
}

// The bright line along the edge of the ice while it spreads.
float ice_front_line(float revealed) {
	return revealed * (1.0 - revealed) * 4.0;
}

// The room in two flat washes: x the shadow, y the light.
vec2 ice_reflection(vec2 screen_uv, vec2 lean) {
	vec2 room_uv = vec2(screen_uv.x, ice_room_row) + lean * ice_room_spread;
	float room = texture(ice_room, room_uv).r;
	float shadow = 1.0 - smoothstep(ice_room_dark - 0.02, ice_room_dark + 0.02, room);
	float light = smoothstep(ice_room_bright - 0.02, ice_room_bright + 0.02, room);
	return vec2(shadow * ice_room_dark_strength, light * ice_room_bright_strength);
}

// A hard-edged patch where the surface faces the light, the way ice is painted.
float ice_glint(vec2 lean, float time, float aa) {
	vec2 light = ice_glint_lean;
	if (ice_glint_drift > 0.0) {
		float phase = time * ice_glint_speed + ice_seed.x * 40.0;
		light += vec2(sin(phase), cos(phase * 0.73)) * ice_glint_drift;
	}
	float away = length(lean - light);
	return (1.0 - smoothstep(ice_glint_size - aa, ice_glint_size + aa, away)) * ice_glint_strength;
}

float ice_crack(float crack, float aa) {
	float edge = mix(0.12, 0.72, ice_crack_thinness);
	return smoothstep(edge - aa, edge + aa, crack) * ice_crack_strength;
}

float ice_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// A four-pointed star that opens and closes, each at its own moment.
float ice_sparkle(vec2 units, float time) {
	if (ice_sparkle_amount <= 0.0) {
		return 0.0;
	}
	vec2 grid = units / ice_sparkle_grid;
	vec2 cell = floor(grid);
	vec2 salted = cell + floor(ice_seed * 97.0);
	if (ice_hash(salted) > ice_sparkle_amount) {
		return 0.0;
	}
	float r1 = ice_hash(salted + vec2(17.3, 5.1));
	float r2 = ice_hash(salted + vec2(3.7, 29.9));
	vec2 local = fract(grid) - (vec2(r1, r2) * 0.5 + 0.25);
	float phase = fract(r1 * 13.7 + time * ice_sparkle_speed * (0.6 + r2));
	float flash = smoothstep(0.0, 0.12, phase) * (1.0 - smoothstep(0.12, 0.42, phase));
	// Thick for its size: the board's painterly filter eats anything a pixel wide.
	float reach = mix(0.2, 0.62, flash);
	float arms = (1.0 - smoothstep(0.03, 0.1, abs(local.y))) * (1.0 - smoothstep(0.0, reach, abs(local.x)))
		+ (1.0 - smoothstep(0.03, 0.1, abs(local.x))) * (1.0 - smoothstep(0.0, reach, abs(local.y)));
	float core = 1.0 - smoothstep(0.06, 0.16, length(local));
	return clamp(arms + core, 0.0, 1.0) * flash;
}
