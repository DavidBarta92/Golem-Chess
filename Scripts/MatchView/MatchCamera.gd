extends Camera2D
class_name MatchCamera

## Keeps the match camera at the scale of the drawings behind it.
##
## The background art is scaled to cover the viewport, so it grows when the
## window gets wider. World space would not, and the board would quietly
## shrink off the drawn table - which is exactly what happened before this
## existed. `BoardCanvas` owns the rule; this node applies it, and re-applies
## it whenever the window changes shape.

var _jolt_tween: Tween

func _ready() -> void:
	_fit_to_canvas()
	get_viewport().size_changed.connect(_fit_to_canvas)

func _fit_to_canvas() -> void:
	zoom = Vector2.ONE * BoardCanvas.zoom_for(get_viewport_rect().size)

## A blow landing makes the board jump on the table. Only the world moves -
## the drawn room is on a layer of its own - so it is the board and what
## stands on it that shake, against a still room, and the room's drawing never
## shows its edge. `direction` is in world space, the first swing goes that
## way; `distance` is in screen pixels and dies away over `duration`.
func jolt(direction: Vector2, distance: float, duration: float, swings: float) -> void:
	if _jolt_tween != null and _jolt_tween.is_valid():
		_jolt_tween.kill()
	var along: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	var world_distance: float = distance / maxf(absf(zoom.x), 0.001)
	_jolt_tween = create_tween()
	_jolt_tween.tween_method(func(progress: float): _set_jolt(along, world_distance, swings, progress), 0.0, 1.0, maxf(duration, 0.01))
	_jolt_tween.tween_callback(func(): offset = Vector2.ZERO)

func _set_jolt(along: Vector2, world_distance: float, swings: float, progress: float) -> void:
	var fade: float = pow(1.0 - progress, 2.0)
	# A little across the blow as well, out of step, so it is not a slide.
	var across: Vector2 = along.orthogonal() * 0.3 * sin(progress * TAU * swings * 1.7)
	offset = (along * sin(progress * TAU * swings) + across) * world_distance * fade
