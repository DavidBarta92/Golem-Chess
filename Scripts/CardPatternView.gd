extends Control
class_name CardPatternView

const GRID_SIZE: int = 5

@export var dot_texture: Texture2D
@export var active_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var center_color: Color = Color(0.08, 0.08, 0.08, 0.9)
@export var guide_color: Color = Color(0.1, 0.1, 0.1, 0.13)

var movement_pattern: Array = []

func set_pattern(pattern: Array) -> void:
	movement_pattern = pattern
	queue_redraw()

func _draw() -> void:
	var cell_size: float = minf(size.x, size.y) / float(GRID_SIZE)
	var grid_size: float = cell_size * GRID_SIZE
	var origin: Vector2 = (size - Vector2(grid_size, grid_size)) * 0.5

	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var cell_origin: Vector2 = origin + Vector2(col, row) * cell_size
			var center: Vector2 = cell_origin + Vector2.ONE * cell_size * 0.5
			draw_circle(center, cell_size * 0.08, guide_color)

			if row == 2 and col == 2:
				draw_circle(center, cell_size * 0.16, center_color)
			elif _is_active(row, col):
				_draw_move_dot(center, cell_size)

func _is_active(row: int, col: int) -> bool:
	if row < 0 or row >= movement_pattern.size():
		return false

	var pattern_row = movement_pattern[row]
	if col < 0 or col >= pattern_row.size():
		return false

	return int(pattern_row[col]) == 1

func _draw_move_dot(center: Vector2, cell_size: float) -> void:
	var dot_size: float = cell_size * 0.62
	var rect: Rect2 = Rect2(center - Vector2.ONE * dot_size * 0.5, Vector2.ONE * dot_size)

	if dot_texture:
		draw_texture_rect(dot_texture, rect, false, active_color)
	else:
		draw_circle(center, dot_size * 0.45, active_color)
