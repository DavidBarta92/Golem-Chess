extends Control
class_name SpeechCountdown

## The small dial that sits under a spoken line, where the Continue button goes
## in a dialogue the player drives.
##
## It is a pie that empties as the line's time runs out, so the player can see
## when the words will go. Pointing at the line stops that time running, which
## the caller handles by simply not counting down - there is nothing to press
## here and nothing to read but the dial.
##
## It never takes mouse input, so a line sitting over the board cannot swallow
## a click meant for a square.

const DIAMETER: float = 22.0
const RING_WIDTH: float = 2.0
const SEGMENTS: int = 48

@export var ring_color: Color = Color(UiPalette.INK, 0.35)
@export var pie_color: Color = Color(UiPalette.INK, 0.55)

var _remaining: float = 1.0

func _ready() -> void:
	custom_minimum_size = Vector2(DIAMETER, DIAMETER)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE

## How much of the line's time is left, 1 down to 0.
func set_remaining(fraction: float) -> void:
	var clamped: float = clampf(fraction, 0.0, 1.0)
	if is_equal_approx(clamped, _remaining):
		return
	_remaining = clamped
	queue_redraw()

func _draw() -> void:
	var centre: Vector2 = size * 0.5
	var radius: float = DIAMETER * 0.5 - RING_WIDTH * 0.5

	draw_arc(centre, radius, 0.0, TAU, SEGMENTS, ring_color, RING_WIDTH, true)
	if _remaining <= 0.0:
		return

	# A wedge from twelve o'clock, shrinking clockwise as the time goes.
	var points := PackedVector2Array([centre])
	var sweep: float = TAU * _remaining
	var steps: int = maxi(2, int(ceil(SEGMENTS * _remaining)))
	for index in range(steps + 1):
		var angle: float = -PI * 0.5 + sweep * (float(index) / float(steps))
		points.append(centre + Vector2(cos(angle), sin(angle)) * (radius - RING_WIDTH * 0.5))
	draw_colored_polygon(points, pie_color)
