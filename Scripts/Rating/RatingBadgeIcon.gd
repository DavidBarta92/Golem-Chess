extends Control

## The rating's mark in the top bar: two stacked chevrons, read as a rank.
## Drawn rather than loaded so it needs no imported texture.

var color: Color = UiPalette.INK:
	set(value):
		color = value
		queue_redraw()

func _draw() -> void:
	var thickness: float = maxf(2.0, size.x * 0.13)
	for index in range(2):
		var top: float = size.y * (0.2 + 0.32 * float(index))
		var chevron := PackedVector2Array([
			Vector2(size.x * 0.14, top + size.y * 0.3),
			Vector2(size.x * 0.5, top),
			Vector2(size.x * 0.86, top + size.y * 0.3),
		])
		draw_polyline(chevron, color, thickness, true)
