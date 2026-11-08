extends RefCounted
class_name PackRevealFx

## The small effects of a pack opening, each on its own and each cleaning up after
## itself: the light of what is inside, the glow of a rare stamp lying face down,
## the glint across a foil, and the flecks of paper and foil in the air.
##
## All of it is added light or plain flecks, and a stamp's effects sit in the
## stamp's own nodes, so nothing here reads the screen back: that reads stale
## pixels on stamps under the Compatibility renderer.

const RAYS_SHADER = preload("res://Shaders/pack_light_rays.gdshader")
const AURA_SHADER = preload("res://Shaders/pack_rarity_aura.gdshader")
const SWEEP_SHADER = preload("res://Shaders/pack_stamp_sweep.gdshader")
const STAMP_SHAPE_TEXTURE = preload("res://Assets/stamp_base.svg")

const FOIL_LIGHT: Color = Color("#b9d6ff")
const FULL_ART_LIGHT: Color = Color("#ffc258")
const PAPER_FLECK: Color = Color("#efe7d6")
## How far an aura reaches past its stamp, as a share of the stamp.
const AURA_MARGIN: float = 0.34
const SWEEP_SECONDS: float = 0.62
const SHADOW_OFFSET: Vector2 = Vector2(4.0, 6.0)

## The colour of a rarity's light. Basic prints have none.
static func get_light_color(rarity: int) -> Color:
	return FULL_ART_LIGHT if rarity == StampPrint.Rarity.FULL_ART else FOIL_LIGHT

## Fans of light from `origin` (in `rect`, 0 to 1 across and down). Starts dark.
static func add_rays(parent: Control, rect: Rect2, origin: Vector2, color: Color, ray_count: float = 17.0) -> ColorRect:
	var rays := ColorRect.new()
	rays.name = "PackLightRays"
	rays.position = rect.position
	rays.size = rect.size
	rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = RAYS_SHADER
	material.set_shader_parameter("light_color", color)
	material.set_shader_parameter("origin", origin)
	material.set_shader_parameter("aspect", rect.size.x / maxf(rect.size.y, 1.0))
	material.set_shader_parameter("ray_count", ray_count)
	material.set_shader_parameter("seed", randf() * 10.0)
	material.set_shader_parameter("strength", 0.0)
	rays.material = material
	parent.add_child(rays)
	return rays

## A stamp's shadow, so that plain stamp backs lying on each other stay apart.
static func add_shadow(stamp: StampVisual) -> void:
	var shadow := TextureRect.new()
	shadow.name = "StampShadow"
	shadow.texture = STAMP_SHAPE_TEXTURE
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.show_behind_parent = true
	shadow.size = stamp.size
	shadow.position = SHADOW_OFFSET
	shadow.modulate = Color(0.0, 0.0, 0.0, 0.42)
	stamp.add_child(shadow)

## A glow behind a stamp, part of the stamp: it goes wherever the stamp goes.
static func add_aura(stamp: StampVisual, rarity: int) -> ColorRect:
	var aura := ColorRect.new()
	aura.name = "RarityAura"
	aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aura.show_behind_parent = true
	aura.size = stamp.size * (1.0 + AURA_MARGIN * 2.0)
	aura.position = -stamp.size * AURA_MARGIN
	var material := ShaderMaterial.new()
	material.shader = AURA_SHADER
	material.set_shader_parameter("aura_color", get_light_color(rarity))
	material.set_shader_parameter("inner_size", 1.0 / (1.0 + AURA_MARGIN * 2.0))
	material.set_shader_parameter("strength", 1.0 if rarity == StampPrint.Rarity.FULL_ART else 0.62)
	aura.material = material
	stamp.add_child(aura)
	return aura

## One run of light across a stamp.
static func sweep(stamp: StampVisual, color: Color) -> void:
	var band := ColorRect.new()
	band.name = "RevealSweep"
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.size = stamp.size
	var material := ShaderMaterial.new()
	material.shader = SWEEP_SHADER
	material.set_shader_parameter("band_color", color)
	material.set_shader_parameter("surface_mask_texture", STAMP_SHAPE_TEXTURE)
	material.set_shader_parameter("sweep", 0.0)
	band.material = material
	stamp.add_child(band)
	var tween := band.create_tween()
	tween.tween_property(material, "shader_parameter/sweep", 1.0, SWEEP_SECONDS).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(Callable(band, "queue_free"))

## The flecks a tear throws up behind its front; on and off with `emitting`.
static func make_tear_flecks() -> CPUParticles2D:
	var flecks := _make_flecks(PAPER_FLECK, 46)
	flecks.emitting = false
	flecks.lifetime = 0.62
	flecks.spread = 38.0
	flecks.initial_velocity_min = 90.0
	flecks.initial_velocity_max = 260.0
	flecks.gravity = Vector2(0.0, 620.0)
	return flecks

## A single burst of flecks. Frees itself.
static func burst(parent: Node, position: Vector2, color: Color, amount: int = 40, speed: float = 340.0) -> void:
	var flecks := _make_flecks(color, amount)
	flecks.position = position
	flecks.one_shot = true
	flecks.explosiveness = 0.92
	flecks.lifetime = 0.95
	flecks.spread = 180.0
	flecks.initial_velocity_min = speed * 0.3
	flecks.initial_velocity_max = speed
	flecks.gravity = Vector2(0.0, 300.0)
	flecks.finished.connect(Callable(flecks, "queue_free"))
	parent.add_child(flecks)
	flecks.emitting = true

static func _make_flecks(color: Color, amount: int) -> CPUParticles2D:
	var flecks := CPUParticles2D.new()
	flecks.name = "PackFlecks"
	flecks.amount = amount
	flecks.color = color
	flecks.direction = Vector2.UP
	flecks.scale_amount_min = 1.6
	flecks.scale_amount_max = 4.4
	flecks.angle_min = -180.0
	flecks.angle_max = 180.0
	flecks.angular_velocity_min = -420.0
	flecks.angular_velocity_max = 420.0
	flecks.damping_min = 40.0
	flecks.damping_max = 120.0
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	fade.add_point(0.7, Color.WHITE)
	flecks.color_ramp = fade
	return flecks
