extends Camera2D
class_name MatchCamera

## Keeps the match camera at the scale of the drawings behind it.
##
## The background art is scaled to cover the viewport, so it grows when the
## window gets wider. World space would not, and the board would quietly
## shrink off the drawn table - which is exactly what happened before this
## existed. `BoardCanvas` owns the rule; this node applies it, and re-applies
## it whenever the window changes shape.

func _ready() -> void:
	_fit_to_canvas()
	get_viewport().size_changed.connect(_fit_to_canvas)

func _fit_to_canvas() -> void:
	zoom = Vector2.ONE * BoardCanvas.zoom_for(get_viewport_rect().size)
