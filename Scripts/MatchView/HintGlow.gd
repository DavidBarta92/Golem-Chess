extends TextureRect
class_name HintGlow

## A soft yellow glow pulsing behind a control the player is being asked to
## press - the tutorial's way of saying "this one".
##
## It is put behind the control as its child (show_behind_parent), so it
## follows the control wherever it moves - a tab sliding up from the bottom
## edge takes its glow with it.

const GLOW_COLOR: Color = Color(1.0, 0.78, 0.22, 1.0)
const FADE_SECONDS: float = 0.4
const PULSE_SECONDS: float = 0.9
const PULSE_LOW_ALPHA: float = 0.55

var _arrive: Tween
var _pulse: Tween

## `centre` and `glow_size` are in the target's own pixels: where the middle
## of the glow sits on it, and how far the glow spreads.
static func attach(target: Control, centre: Vector2, glow_size: Vector2) -> HintGlow:
	if target == null or !is_instance_valid(target):
		return null
	var glow := HintGlow.new()
	glow.name = "HintGlow"
	glow.show_behind_parent = true
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.texture = _make_texture()
	glow.place(centre, glow_size)
	target.add_child(glow)
	return glow

## Moves the glow on its target, in the same terms as attach - for a target
## that changes size after the glow went up.
func place(centre: Vector2, glow_size: Vector2) -> void:
	size = glow_size
	position = centre - glow_size * 0.5

static func _make_texture() -> GradientTexture2D:
	# A bright core that holds for a while before it thins out, so it still
	# reads against the light paper and not only against the dark board.
	var half: Color = GLOW_COLOR
	half.a = 0.6
	var clear: Color = GLOW_COLOR
	clear.a = 0.0
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gradient.colors = PackedColorArray([GLOW_COLOR, half, clear])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 128
	texture.height = 128
	return texture

func _ready() -> void:
	modulate.a = 0.0
	_arrive = create_tween()
	_arrive.tween_property(self, "modulate:a", 1.0, FADE_SECONDS)
	_arrive.tween_callback(_start_pulse)

func _start_pulse() -> void:
	_pulse = create_tween().set_loops()
	_pulse.tween_property(self, "modulate:a", PULSE_LOW_ALPHA, PULSE_SECONDS) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse.tween_property(self, "modulate:a", 1.0, PULSE_SECONDS) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Fades out and removes itself.
func dismiss() -> void:
	# Dismissed while still fading in, the arrival must not go on to start
	# the pulse underneath the fade-out.
	if _arrive != null and _arrive.is_valid():
		_arrive.kill()
	if _pulse != null and _pulse.is_valid():
		_pulse.kill()
	var leave := create_tween()
	leave.tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
	leave.tween_callback(queue_free)
