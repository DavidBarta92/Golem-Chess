extends Control

## The part of a player's crown meter that answers the pointer. The meter itself
## lies on the board (CrownRim); this stands over it in the interface, for the
## tooltip and, once the crown has formed, for dragging it off the board onto one
## of the player's golems, the way a stamp is dragged off the codex
## (CrownController takes it from there).

const CrownGold = preload("res://Scripts/MatchView/CrownGold.gd")

signal crown_drag_started
signal crown_drag_moved
signal crown_drag_released

## A crown the player can use breathes, so it is noticed.
const PULSE_SECONDS: float = 1.4
const PULSE_SCALE: float = 0.12

var rim
var draggable: bool = false

var _dragging: bool = false
var _pulse_time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_process(false)

func set_rim(new_rim) -> void:
	if new_rim == rim:
		return
	if rim != null:
		rim.set_ring_pulse(1.0)
	rim = new_rim

## Over its row, wherever the board has that on this window.
func fit_to_rim() -> void:
	if rim == null:
		return
	var row: Rect2 = rim.get_row_screen_rect()
	position = row.position
	size = row.size

func set_points(points: int, points_required: int) -> void:
	tooltip_text = tr("CROWN_METER_TOOLTIP").format({"points": points, "required": points_required})

func set_draggable(value: bool) -> void:
	draggable = value
	if !draggable:
		if _dragging:
			_dragging = false
			return_crown()
		if rim != null:
			rim.set_ring_pulse(1.0)
		_pulse_time = 0.0
	set_process(draggable)

func is_full() -> bool:
	return rim != null and rim.is_ring_ready()

func is_dragging() -> bool:
	return _dragging

func get_crown_rect() -> Rect2:
	if rim == null:
		return Rect2()
	var groove: Rect2 = rim.get_groove_screen_rect()
	return Rect2(groove.position - position, groove.size)

## A drag that came to nothing: the crown goes back in its groove.
func return_crown() -> void:
	if rim != null:
		rim.set_ring_lifted(false)
	queue_redraw()

func _process(delta: float) -> void:
	if !is_full():
		return
	_pulse_time = fmod(_pulse_time + delta, PULSE_SECONDS)
	rim.set_ring_pulse(1.0 + PULSE_SCALE * 0.5 * (1.0 - cos(TAU * _pulse_time / PULSE_SECONDS)))

func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT or !button.pressed:
		return
	if !draggable or !is_full() or !get_crown_rect().grow(4.0).has_point(button.position):
		return
	_dragging = true
	rim.set_ring_pulse(1.0)
	rim.set_ring_lifted(true)
	accept_event()
	crown_drag_started.emit()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if !_dragging:
		return
	if event is InputEventMouseMotion:
		crown_drag_moved.emit()
		queue_redraw()
		return
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT and !button.pressed:
		_dragging = false
		crown_drag_released.emit()
		queue_redraw()

func _draw() -> void:
	if !_dragging:
		return
	# The same ring as in the groove, at the size it lay there.
	var held_size: Vector2 = get_crown_rect().size
	draw_texture_rect(CrownGold.ring_texture(), Rect2(get_local_mouse_position() - held_size * 0.5, held_size), false)
