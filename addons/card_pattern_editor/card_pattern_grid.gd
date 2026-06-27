@tool
extends Control

signal pattern_changed(pattern: Array)

const GRID_SIZE: int = 5
const MIN_CELL_SIZE: float = 28.0
const CELL_GAP: float = 3.0
const MOVEMENT_NONE: int = 0
const MOVEMENT_MOVE_AND_CAPTURE: int = 1
const MOVEMENT_MOVE_ONLY: int = 2
const MOVEMENT_CAPTURE_ONLY: int = 3

var brush_value: int = MOVEMENT_MOVE_AND_CAPTURE
var pattern: Array = []

func _init() -> void:
	custom_minimum_size = Vector2.ONE * (MIN_CELL_SIZE * GRID_SIZE + CELL_GAP * (GRID_SIZE - 1))
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Left click paints the selected value. Clicking the same value clears it. Right click clears. The center is the piece origin."
	set_pattern(_create_empty_pattern())

func set_pattern(value: Array) -> void:
	pattern = _normalize_pattern(value)
	queue_redraw()

func get_pattern() -> Array:
	return _duplicate_pattern(pattern)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_apply_at_position(event.position, brush_value, true)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_apply_at_position(event.position, MOVEMENT_NONE, false)
			accept_event()
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_apply_at_position(event.position, brush_value, false)
			accept_event()
		elif event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			_apply_at_position(event.position, MOVEMENT_NONE, false)
			accept_event()

func _draw() -> void:
	var cell_size: float = _get_cell_size()
	var total_size: float = _get_total_grid_size(cell_size)
	var origin: Vector2 = (size - Vector2.ONE * total_size) * 0.5

	draw_rect(Rect2(origin - Vector2.ONE, Vector2.ONE * total_size + Vector2.ONE * 2.0), _theme_color("dark_color_2", Color(0.12, 0.12, 0.12)))

	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var cell_rect: Rect2 = Rect2(
				origin + Vector2(col, row) * (cell_size + CELL_GAP),
				Vector2.ONE * cell_size
			)
			var value: int = int(pattern[row][col])
			var is_origin: bool = row == 2 && col == 2
			_draw_cell(cell_rect, value, is_origin)

func _draw_cell(rect: Rect2, value: int, is_origin: bool) -> void:
	var base_color: Color = _theme_color("base_color", Color(0.2, 0.2, 0.2))
	var border_color: Color = _theme_color("dark_color_3", Color(0.08, 0.08, 0.08))
	var center: Vector2 = rect.get_center()
	var radius: float = rect.size.x * 0.24

	draw_rect(rect, base_color)
	draw_rect(rect, border_color, false, 1.0)

	if is_origin:
		draw_circle(center, radius * 0.78, _theme_color("font_disabled_color", Color(0.45, 0.45, 0.45)))
		draw_circle(center, radius * 0.42, base_color)
		return

	match value:
		MOVEMENT_MOVE_AND_CAPTURE:
			draw_circle(center, radius, Color(0.95, 0.86, 0.38))
		MOVEMENT_MOVE_ONLY:
			draw_circle(center, radius, Color(0.27, 0.66, 1.0))
			draw_circle(center, radius * 0.55, base_color)
		MOVEMENT_CAPTURE_ONLY:
			draw_circle(center, radius, Color(1.0, 0.34, 0.28))
			draw_arc(center, radius * 0.7, 0.0, TAU, 32, base_color, 2.0)
		_:
			draw_circle(center, radius * 0.24, _theme_color("font_disabled_color", Color(0.38, 0.38, 0.38)))

func _apply_at_position(position: Vector2, value: int, toggle_same_value: bool) -> void:
	var cell: Vector2i = _cell_from_position(position)
	if cell.x < 0 || cell.y < 0:
		return
	if cell.x == 2 && cell.y == 2:
		return

	var next_value: int = clampi(value, 0, 3)
	if toggle_same_value && int(pattern[cell.x][cell.y]) == next_value:
		next_value = MOVEMENT_NONE
	if int(pattern[cell.x][cell.y]) == next_value:
		return

	pattern[cell.x][cell.y] = next_value
	queue_redraw()
	pattern_changed.emit(get_pattern())

func _cell_from_position(position: Vector2) -> Vector2i:
	var cell_size: float = _get_cell_size()
	var total_size: float = _get_total_grid_size(cell_size)
	var origin: Vector2 = (size - Vector2.ONE * total_size) * 0.5
	var local_position: Vector2 = position - origin

	if local_position.x < 0.0 || local_position.y < 0.0:
		return Vector2i(-1, -1)
	if local_position.x >= total_size || local_position.y >= total_size:
		return Vector2i(-1, -1)

	var step: float = cell_size + CELL_GAP
	var col: int = int(floor(local_position.x / step))
	var row: int = int(floor(local_position.y / step))
	var cell_offset: Vector2 = local_position - Vector2(col, row) * step

	if col < 0 || col >= GRID_SIZE || row < 0 || row >= GRID_SIZE:
		return Vector2i(-1, -1)
	if cell_offset.x > cell_size || cell_offset.y > cell_size:
		return Vector2i(-1, -1)

	return Vector2i(row, col)

func _get_cell_size() -> float:
	var available_size: float = minf(size.x, size.y)
	return maxf(MIN_CELL_SIZE, (available_size - CELL_GAP * float(GRID_SIZE - 1)) / float(GRID_SIZE))

func _get_total_grid_size(cell_size: float) -> float:
	return cell_size * float(GRID_SIZE) + CELL_GAP * float(GRID_SIZE - 1)

func _normalize_pattern(value: Array) -> Array:
	var normalized: Array = []
	for row_index in range(GRID_SIZE):
		var row: Array = []
		var source_row: Variant = []
		if row_index < value.size():
			source_row = value[row_index]

		for col_index in range(GRID_SIZE):
			var cell_value: int = MOVEMENT_NONE
			if source_row is Array && col_index < source_row.size():
				cell_value = clampi(int(source_row[col_index]), MOVEMENT_NONE, MOVEMENT_CAPTURE_ONLY)
			if row_index == 2 && col_index == 2:
				cell_value = MOVEMENT_NONE
			row.append(cell_value)

		normalized.append(row)

	return normalized

func _create_empty_pattern() -> Array:
	var empty_pattern: Array = []
	for row_index in range(GRID_SIZE):
		var row: Array = []
		for col_index in range(GRID_SIZE):
			row.append(MOVEMENT_NONE)
		empty_pattern.append(row)
	return empty_pattern

func _duplicate_pattern(value: Array) -> Array:
	var duplicate: Array = []
	for row in value:
		duplicate.append((row as Array).duplicate())
	return duplicate

func _theme_color(name: StringName, fallback: Color) -> Color:
	if has_theme_color(name, "Editor"):
		return get_theme_color(name, "Editor")
	return fallback
