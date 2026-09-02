extends Sprite2D

const SLIDE_DISTANCE: float = 260.0
const SLIDE_DOWN_DURATION: float = 0.45
const SLIDE_UP_DURATION: float = 0.35
const SLIDE_HOLD_DURATION: float = 0.6

const TURN_SINK_VISIBLE_HEIGHT: float = 20.0
const SINK_FALL_DURATION: float = 0.22
const SINK_BOUNCE_DISTANCE: float = 10.0
const SINK_BOUNCE_DURATION: float = 0.11

var rest_position: Vector2
var turn_sink_distance: float = 0.0
var slide_tween: Tween
var turn_tween: Tween

var page_slide_offset: float = 0.0
var turn_sink_offset: float = 0.0
var is_turn_active: bool = true

func _ready() -> void:
	rest_position = position
	# Sprite2D is center-anchored, so sinking by (rendered height - the
	# desired peek) pushes the sprite down almost its own height -- leaving
	# only a sliver of its top edge (the last part to go) still in view.
	var rendered_height: float = texture.get_height() * scale.y if texture != null else 0.0
	turn_sink_distance = max(rendered_height - TURN_SINK_VISIBLE_HEIGHT, 0.0)

func apply_position() -> void:
	position = rest_position + Vector2(0.0, page_slide_offset + turn_sink_offset)

func set_page_slide_offset(value: float) -> void:
	page_slide_offset = value
	apply_position()

func set_turn_sink_offset(value: float) -> void:
	turn_sink_offset = value
	apply_position()

func play_turn_page_animation() -> void:
	if slide_tween != null and slide_tween.is_valid():
		slide_tween.kill()
	set_page_slide_offset(0.0)
	slide_tween = create_tween()
	slide_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	slide_tween.tween_method(set_page_slide_offset, 0.0, SLIDE_DISTANCE, SLIDE_DOWN_DURATION)
	slide_tween.tween_interval(SLIDE_HOLD_DURATION)
	slide_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	slide_tween.tween_method(set_page_slide_offset, SLIDE_DISTANCE, 0.0, SLIDE_UP_DURATION)

# "active" means it's the opponent's own turn -- rises when they can act,
# sinks lower (out of the way) whenever it's our turn instead.
func set_turn_active(active: bool) -> void:
	if is_turn_active == active:
		return
	is_turn_active = active
	animate_turn_sink_offset_to(0.0 if active else turn_sink_distance)

func animate_turn_sink_offset_to(target: float) -> void:
	if turn_tween != null and turn_tween.is_valid():
		turn_tween.kill()
	var start: float = turn_sink_offset
	if is_equal_approx(start, target):
		set_turn_sink_offset(target)
		return
	var direction_sign: float = 1.0 if target > start else -1.0
	var overshoot: float = target + direction_sign * SINK_BOUNCE_DISTANCE
	var rebound: float = target - direction_sign * SINK_BOUNCE_DISTANCE * 0.4
	turn_tween = create_tween()
	turn_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	turn_tween.tween_method(set_turn_sink_offset, start, overshoot, SINK_FALL_DURATION)
	turn_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	turn_tween.tween_method(set_turn_sink_offset, overshoot, rebound, SINK_BOUNCE_DURATION)
	turn_tween.tween_method(set_turn_sink_offset, rebound, target, SINK_BOUNCE_DURATION)
