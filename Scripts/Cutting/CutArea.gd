extends Control
class_name CutArea

## Turns mouse drags on this control into a CutStroke against `guide`, in this
## control's own space. What a cut does is left to whoever listens: a pack tears
## after the mouse, an envelope would keep the shape drawn on it.

signal cut_started(stroke: CutStroke)
signal cut_moved(stroke: CutStroke)
signal cut_ended(stroke: CutStroke)
## Pressed and let go without drawing anything. No cut_ended comes after it.
signal tapped(position: Vector2)

## How far the mouse may wander in a press that still counts as a tap.
const TAP_TRAVEL: float = 8.0

var guide: CutGuide
var tolerance: float = 12.0
## The stroke being drawn, null between strokes.
var stroke: CutStroke

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if guide == null:
		return
	if event is InputEventMouseMotion:
		if stroke != null:
			stroke.extend(event.position)
			cut_moved.emit(stroke)
			accept_event()
		return
	var button_event := event as InputEventMouseButton
	if button_event == null or button_event.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	if button_event.pressed:
		stroke = CutStroke.new(guide, tolerance)
		stroke.begin(button_event.position)
		cut_started.emit(stroke)
	elif stroke != null:
		_finish_stroke(button_event.position)

func _finish_stroke(position: Vector2) -> void:
	var finished: CutStroke = stroke
	stroke = null
	finished.extend(position)
	if finished.points[0].distance_to(position) <= TAP_TRAVEL and finished.direction == 0:
		tapped.emit(position)
	else:
		cut_ended.emit(finished)
