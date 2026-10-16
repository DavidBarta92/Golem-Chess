extends Control
class_name PolygonClip

## Shows its children only inside a polygon, while the clip is on.
##
## The polygon is drawn as the mask (clip_children = CLIP_CHILDREN_ONLY) and is
## never visible itself. With the clip off the children draw as usual and the
## polygon is ignored, so the node can sit around a stack of artwork from the
## start and only start cutting it when asked.

var polygon: PackedVector2Array = PackedVector2Array():
	set(value):
		polygon = value
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_clip_enabled(enabled: bool) -> void:
	clip_children = CanvasItem.CLIP_CHILDREN_ONLY if enabled else CanvasItem.CLIP_CHILDREN_DISABLED
	queue_redraw()

func _draw() -> void:
	if clip_children == CanvasItem.CLIP_CHILDREN_DISABLED or polygon.size() < 3:
		return
	draw_colored_polygon(polygon, Color.WHITE)
