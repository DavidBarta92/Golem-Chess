extends Sprite2D

## HintGlow for a piece on the board: the same soft yellow glow, pulsing the
## same way, behind the figure instead of behind a control. A child of the
## piece's holder one step behind it, so the pieces in front still cover it,
## and it moves, squashes and tilts with its piece.

const NODE_NAME: String = "PieceHintGlow"
## How far it spreads, as a multiple of the figure's width and height. Its
## bright middle is behind the figure, so it has to reach well past it to
## read on the warm board as the stamps' glow does on the paper.
const SPREAD: Vector2 = Vector2(3.0, 2.0)

var _arrive: Tween
var _pulse: Tween

## `metrics` is the figure's footprint in its picture
## (PieceVisualController.get_footprint_metrics): the glow sits on its middle.
static func attach(holder: Sprite2D, metrics: Dictionary):
	if holder == null or !is_instance_valid(holder) or holder.texture == null:
		return null
	var existing: Node = holder.get_node_or_null(NODE_NAME)
	if existing != null:
		existing.free()
	var picture_size: Vector2 = holder.texture.get_size()
	var figure := Rect2(
		Vector2(float(metrics.get("left_x", 0.0)), float(metrics.get("top_y", 0.0))),
		Vector2(
			float(metrics.get("right_x", picture_size.x)) - float(metrics.get("left_x", 0.0)),
			float(metrics.get("bottom_y", picture_size.y)) - float(metrics.get("top_y", 0.0))
		)
	)
	var glow = new()
	glow.name = NODE_NAME
	glow.texture = HintGlow.make_texture()
	glow.z_index = -1
	glow.z_as_relative = true
	# Bright on the dark board whatever light falls on it, as on the paper.
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	glow.material = unshaded
	var corner: Vector2 = holder.offset - picture_size * 0.5 if holder.centered else holder.offset
	glow.position = corner + figure.get_center()
	glow.scale = figure.size * SPREAD / glow.texture.get_size()
	holder.add_child(glow)
	return glow

func _ready() -> void:
	modulate.a = 0.0
	_arrive = create_tween()
	_arrive.tween_property(self, "modulate:a", 1.0, HintGlow.FADE_SECONDS)
	_arrive.tween_callback(_start_pulse)

func _start_pulse() -> void:
	_pulse = create_tween().set_loops()
	_pulse.tween_property(self, "modulate:a", HintGlow.PULSE_LOW_ALPHA, HintGlow.PULSE_SECONDS) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse.tween_property(self, "modulate:a", 1.0, HintGlow.PULSE_SECONDS) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Fades out and removes itself, as HintGlow.dismiss.
func dismiss() -> void:
	if _arrive != null and _arrive.is_valid():
		_arrive.kill()
	if _pulse != null and _pulse.is_valid():
		_pulse.kill()
	# Gone this way, a new glow on the same piece does not find it by name.
	name = NODE_NAME + "Going"
	var leave := create_tween()
	leave.tween_property(self, "modulate:a", 0.0, HintGlow.FADE_SECONDS)
	leave.tween_callback(queue_free)
