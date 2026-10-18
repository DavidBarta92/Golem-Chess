extends RefCounted
class_name ComicPanelFlourish

## What a comic panel can do once it has finished drawing: arrive with the
## flourish a stamp makes when it is affixed to a golem, and then glow.
##
## Both are the match's own effects, with the match's tuning, so a player who
## has played a game recognises them. Only the blending differs: the match's
## rays are additive, which is what makes them blaze over the dark board, and
## on the comics' cream paper there is nothing left to add to - measured, and
## they come out invisible. Shaders/comic_affix_rays.gdshader is the same ray
## field laid down as colour instead. The glow needs no such treatment; it
## already mixes.
##
## Kept in its own file because a panel is about drawing itself, and this is
## about what happens once it has.

const RAYS_SHADER = preload("res://Shaders/comic_affix_rays.gdshader")
const GLOW_SHADER = preload("res://Shaders/piece_attach_glow.gdshader")

## Taken from the match's affix (MatchBoard's PIECE_ATTACH_* constants).
## Re-copy if those are retuned; the point is that the two read alike.
const RAYS_SPREAD: float = 0.5
const RAYS_CUTOFF: float = 0.39
const RAYS_SPEED: float = 1.4
const RAYS_RAY1_DENSITY: float = 8.0
const RAYS_RAY2_DENSITY: float = 10.0
const RAYS_RAY2_INTENSITY: float = 0.3
const RAYS_CORE_INTENSITY: float = 2.0
const RAYS_SEED: float = 5.0
## The rays start wide and close in on the thing they are landing on, which is
## the shape of the affix: light gathering rather than light spreading.
const RAYS_START_SIZE: float = 10.0
const RAYS_END_SIZE: float = 1.0
## How far across the thing it lands on the ray square reaches. The match uses
## a wider spread relative to a piece, but a piece stands alone on its square
## while this star sits inside a letter: much wider and the flash swallows the
## word it is meant to decorate.
const RAYS_SIZE_RATIO: float = 4.5

## The sound a stamp makes going on, slowed and dropped: the title is a heavier
## moment than a stamp. The sample runs 4.6 seconds, so this pitch stretches it
## to about 6.6 - deeper and longer, without turning into a drone over a flash
## that lasts one second.
const AFFIX_SOUND: String = "attach_stamp"
const AFFIX_SOUND_PITCH: float = 0.70

const GLOW_SIZE: float = 4.8
const GLOW_FILL_STRENGTH: float = 0.30
## The affix flashes the glow hard at the moment the stamp bites, then lets it
## fall back to its resting level.
const GLOW_FLASH_RATIO: float = 4.0
const GLOW_FLASH_SECONDS: float = 0.08

## The arrival: rays gather onto `centre` while the glow flashes, then both
## settle - the glow down to `floor_strength`, where its breathing starts.
## `host` is the panel, and `centre`/`extent` are in its space.
static func play_affix(host: Control, centre: Vector2, extent: float, glow: CanvasItem,
		resting_strength: float, seconds: float, floor_strength: float = 0.0) -> void:
	if host == null or !is_instance_valid(host) or seconds <= 0.0:
		return

	var rays := ColorRect.new()
	rays.name = "AffixRays"
	rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rays.color = Color.WHITE
	var side: float = maxf(1.0, extent * RAYS_SIZE_RATIO)
	rays.size = Vector2(side, side)
	rays.position = centre - rays.size * 0.5

	var material := ShaderMaterial.new()
	material.shader = RAYS_SHADER
	material.set_shader_parameter("gradient", _rays_gradient())
	material.set_shader_parameter("spread", RAYS_SPREAD)
	material.set_shader_parameter("cutoff", RAYS_CUTOFF)
	material.set_shader_parameter("speed", RAYS_SPEED)
	material.set_shader_parameter("ray1_density", RAYS_RAY1_DENSITY)
	material.set_shader_parameter("ray2_density", RAYS_RAY2_DENSITY)
	material.set_shader_parameter("ray2_intensity", RAYS_RAY2_INTENSITY)
	material.set_shader_parameter("core_intensity", RAYS_CORE_INTENSITY)
	material.set_shader_parameter("seed", RAYS_SEED)
	material.set_shader_parameter("size", RAYS_START_SIZE)
	material.set_shader_parameter("alpha_strength", 0.0)
	rays.material = material
	host.add_child(rays)
	SFXManager.play_pitched(AFFIX_SOUND, AFFIX_SOUND_PITCH)

	var gather: Tween = rays.create_tween()
	gather.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	gather.tween_property(material, "shader_parameter/size", RAYS_END_SIZE, seconds * 0.55)
	gather.parallel().tween_property(material, "shader_parameter/alpha_strength", 1.0, seconds * 0.3)
	gather.tween_property(material, "shader_parameter/alpha_strength", 0.0, seconds * 0.45)
	gather.tween_callback(Callable(rays, "queue_free"))

	_flash_glow(glow, resting_strength, seconds, floor_strength)

## The glow spiking as the thing lands, then falling back to where the steady
## pulse picks it up.
static func _flash_glow(glow: CanvasItem, resting_strength: float, seconds: float,
		floor_strength: float) -> void:
	if glow == null or !is_instance_valid(glow) or glow.material == null:
		return
	var flash: Tween = glow.create_tween()
	flash.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	flash.tween_property(glow.material, "shader_parameter/glow_strength",
		resting_strength * GLOW_FLASH_RATIO, GLOW_FLASH_SECONDS)
	flash.tween_property(glow.material, "shader_parameter/glow_strength", floor_strength,
		maxf(0.05, seconds - GLOW_FLASH_SECONDS))

## The same orange-to-yellow ramp the match's affix rays use.
static func _rays_gradient() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.set_offset(0, 0.0)
	gradient.set_color(0, Color(1.0, 0.42, 0.0, 0.0))
	gradient.set_offset(1, 1.0)
	gradient.set_color(1, Color(1.0, 0.96, 0.03, 1.0))
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture

## Breathes a glow around whatever `source` is showing, for as long as it
## lives, and hands back the layer it made so the caller can take it away.
##
## A layer of its own rather than a material on the picture: the glow shader
## writes only the glow, discarding the colour it was handed, which is why the
## match hangs it on an overlay sprite over the piece instead of on the piece.
## Set on the drawing itself it would paint over it, and a gold star would come
## out a flat pale yellow.
static func start_pulse(source: TextureRect, color: Color, strength: float, period: float,
		delay: float = 0.0, floor_strength: float = 0.0) -> CanvasItem:
	if source == null or !is_instance_valid(source) or strength <= 0.0:
		return null
	if source.texture == null:
		return null

	var overlay := TextureRect.new()
	overlay.name = "Glow"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.texture = source.texture
	overlay.expand_mode = source.expand_mode
	overlay.stretch_mode = source.stretch_mode
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var material := ShaderMaterial.new()
	material.shader = GLOW_SHADER
	material.set_shader_parameter("glow_color", color)
	material.set_shader_parameter("glow_size", GLOW_SIZE)
	material.set_shader_parameter("fill_strength", GLOW_FILL_STRENGTH)
	material.set_shader_parameter("glow_strength", 0.0)
	overlay.material = material
	source.add_child(overlay)

	# A sine wave between `floor_strength` and `strength`, round and round with
	# no pause at either end, so it reads as breathing rather than as a light
	# blinking. It breathes down to the floor rather than to nothing, so the
	# thing stays lit between breaths. Each breath starts at the floor, which
	# is where an affix flash leaves the glow.
	#
	# The wait lets an arrival have the glow to itself first, and it runs once,
	# before the breathing: inside the looping tween it would hold the glow at
	# the floor for `delay` on every single breath.
	var breath_seconds: float = maxf(0.1, period)
	var breathe := func(phase: float) -> void:
		material.set_shader_parameter("glow_strength",
			lerpf(floor_strength, strength, 0.5 - 0.5 * cos(phase * TAU)))
	var start_breathing := func() -> void:
		if !is_instance_valid(overlay):
			return
		var breathing: Tween = overlay.create_tween().set_loops()
		breathing.tween_method(breathe, 0.0, 1.0, breath_seconds)
	if delay > 0.0:
		var wait: Tween = overlay.create_tween()
		wait.tween_interval(delay)
		wait.tween_callback(start_breathing)
	else:
		start_breathing.call()
	return overlay
