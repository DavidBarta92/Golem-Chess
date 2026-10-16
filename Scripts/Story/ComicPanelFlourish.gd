extends RefCounted
class_name ComicPanelFlourish

## The two flourishes a comic panel can carry when it lands: a glint, and a
## slow pulse afterwards.
##
## The glow is the match's attach glow. The glint is *not* the match's capture
## sparkle, and that is deliberate: that shader is additive, which is what makes
## it blaze over the dark board, and on the comics' cream paper there is no
## headroom left to add to - measured, and it comes out invisible. So the glint
## here is made the way the paper allows: the star lands slightly oversized and
## the glow behind it flares and settles, which reads as the same beat.
##
## Kept in its own file because a panel is about drawing itself, and this is
## about what happens once it has.

const GLOW_SHADER = preload("res://Shaders/piece_attach_glow.gdshader")

const GLOW_SIZE: float = 4.5
const GLOW_FILL_STRENGTH: float = 0.0
## How much bigger the thing lands than it settles.
const GLINT_OVERSHOOT: float = 1.5
## How far the flare overshoots the resting pulse.
const GLINT_FLARE_RATIO: float = 2.4

## The glint: the picture drops in from slightly too big while the glow behind
## it flares and settles. `source` is the layer showing the artwork and `glow`
## the layer made by start_pulse, which the flare borrows for a moment before
## the steady pulse takes it back.
static func play_glint(source: TextureRect, glow: CanvasItem, strength: float, seconds: float) -> void:
	if source == null or !is_instance_valid(source) or seconds <= 0.0:
		return

	source.pivot_offset = source.size * 0.5
	source.scale = Vector2.ONE * GLINT_OVERSHOOT
	var settle: Tween = source.create_tween()
	settle.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	settle.tween_property(source, "scale", Vector2.ONE, seconds)

	if glow == null or !is_instance_valid(glow) or glow.material == null:
		return
	var flare: Tween = glow.create_tween()
	flare.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	flare.tween_property(glow.material, "shader_parameter/glow_strength",
		strength * GLINT_FLARE_RATIO, seconds * 0.25)
	flare.tween_property(glow.material, "shader_parameter/glow_strength", 0.0, seconds * 0.75)

## Breathes a glow around whatever `source` is showing, for as long as it
## lives, and hands back the layer it made so the caller can take it away.
##
## A layer of its own rather than a material on the picture: the glow shader
## writes only the glow, discarding the colour it was handed, which is why the
## match hangs it on an overlay sprite over the piece instead of on the piece.
## Set on the drawing itself it would paint over it, and a gold star would come
## out a flat pale yellow.
static func start_pulse(source: TextureRect, color: Color, strength: float, period: float, delay: float = 0.0) -> CanvasItem:
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

	# Up and down in equal halves, easing at both ends, so it reads as
	# breathing rather than as a blinking light. The wait lets a glint have the
	# glow to itself first.
	var half: float = maxf(0.05, period * 0.5)
	var tween: Tween = overlay.create_tween().set_loops()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(material, "shader_parameter/glow_strength", strength, half)
	tween.tween_property(material, "shader_parameter/glow_strength", 0.0, half)
	return overlay
