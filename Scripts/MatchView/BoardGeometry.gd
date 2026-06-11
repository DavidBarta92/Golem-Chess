extends RefCounted

var board_size: int = BoardConfig.BOARD_SIZE
var cell_width: int = BoardConfig.CELL_WIDTH
var perspective_enabled: bool = true
var perspective_top_scale: float = 0.74
var perspective_bottom_scale: float = 1.05
var perspective_vertical_scale: float = 0.72
var tile_slide_distance_factor: float = 1.06
var tile_sink_offset: float = 7.0
var view_color: int = 1

func configure(config: Dictionary) -> void:
	board_size = int(config.get("board_size", board_size))
	cell_width = int(config.get("cell_width", cell_width))
	perspective_enabled = bool(config.get("perspective_enabled", perspective_enabled))
	perspective_top_scale = float(config.get("perspective_top_scale", perspective_top_scale))
	perspective_bottom_scale = float(config.get("perspective_bottom_scale", perspective_bottom_scale))
	perspective_vertical_scale = float(config.get("perspective_vertical_scale", perspective_vertical_scale))
	tile_slide_distance_factor = float(config.get("tile_slide_distance_factor", tile_slide_distance_factor))
	tile_sink_offset = float(config.get("tile_sink_offset", tile_sink_offset))
	view_color = int(config.get("view_color", view_color))

func set_view_color(new_view_color: int) -> void:
	view_color = -1 if new_view_color < 0 else 1

func get_board_rect_local() -> Rect2:
	return get_points_bounds_local(get_projected_board_rect_polygon(0.0))

func get_board_unprojected_rect_local() -> Rect2:
	return BoardConfig.get_board_rect_local()

func get_projected_board_rect_polygon(
	horizontal_expand: float = 0.0,
	vertical_expand: float = -1.0,
	clamp_to_board: bool = true
) -> PackedVector2Array:
	var resolved_vertical_expand: float = horizontal_expand if vertical_expand < 0.0 else vertical_expand
	var rect: Rect2 = get_board_unprojected_rect_local()
	rect.position.x -= horizontal_expand
	rect.size.x += horizontal_expand * 2.0
	rect.position.y -= resolved_vertical_expand
	rect.size.y += resolved_vertical_expand * 2.0
	return PackedVector2Array([
		project_point_local(rect.position, clamp_to_board),
		project_point_local(rect.position + Vector2(rect.size.x, 0.0), clamp_to_board),
		project_point_local(rect.position + rect.size, clamp_to_board),
		project_point_local(rect.position + Vector2(0.0, rect.size.y), clamp_to_board),
	])

func project_point_local(point: Vector2, clamp_to_board: bool = true) -> Vector2:
	if !perspective_enabled:
		return point

	var half_size: float = float(board_size * cell_width) * 0.5
	if half_size <= 0.0:
		return point

	var linear_depth_factor: float
	var near_y: float
	var far_direction: float
	if view_color < 0:
		near_y = -half_size
		far_direction = 1.0
		linear_depth_factor = (point.y + half_size) / (half_size * 2.0)
	else:
		near_y = half_size
		far_direction = -1.0
		linear_depth_factor = (half_size - point.y) / (half_size * 2.0)
	if clamp_to_board:
		linear_depth_factor = clampf(linear_depth_factor, 0.0, 1.0)

	var projected_depth_factor: float = get_projected_depth_factor(linear_depth_factor, clamp_to_board)
	var horizontal_scale: float = lerpf(perspective_bottom_scale, perspective_top_scale, projected_depth_factor)
	var projected_x: float = point.x * horizontal_scale
	var far_y: float = near_y + (far_direction * half_size * 2.0 * perspective_vertical_scale)
	var projected_y: float = lerpf(near_y, far_y, projected_depth_factor)
	return Vector2(projected_x, projected_y)

func get_projected_depth_factor(linear_depth_factor: float, clamp_to_board: bool = true) -> float:
	var depth_factor: float = clampf(linear_depth_factor, 0.0, 1.0) if clamp_to_board else linear_depth_factor
	var top_scale: float = max(perspective_top_scale, 0.001)
	var bottom_scale: float = max(perspective_bottom_scale, 0.001)
	var perspective_strength: float = max((bottom_scale / top_scale) - 1.0, 0.0)
	if perspective_strength <= 0.0001:
		return depth_factor

	var denominator: float = 1.0 + perspective_strength * depth_factor
	if absf(denominator) <= 0.0001:
		return depth_factor
	var projected_depth_factor: float = (depth_factor * (1.0 + perspective_strength)) / denominator
	return clampf(projected_depth_factor, 0.0, 1.0) if clamp_to_board else projected_depth_factor

func get_cell_polygon_local(board_pos: Vector2, inset: float = 0.0, clamp_to_board: bool = true) -> PackedVector2Array:
	var center: Vector2 = BoardConfig.get_cell_center_local(board_pos)
	var half_cell: float = float(cell_width) * 0.5
	var corners := [
		center + Vector2(-half_cell, -half_cell),
		center + Vector2(half_cell, -half_cell),
		center + Vector2(half_cell, half_cell),
		center + Vector2(-half_cell, half_cell),
	]
	var polygon := PackedVector2Array()
	var projected_center: Vector2 = get_position_local(board_pos, clamp_to_board)
	var inset_factor: float = clampf(inset / half_cell, 0.0, 0.95) if half_cell > 0.0 else 0.0
	for corner: Vector2 in corners:
		var projected_corner: Vector2 = project_point_local(corner, clamp_to_board)
		polygon.append(projected_corner.lerp(projected_center, inset_factor))
	return polygon

func get_position_local(board_pos: Vector2, clamp_to_board: bool = true) -> Vector2:
	return project_point_local(BoardConfig.get_cell_center_local(board_pos), clamp_to_board)

func get_cell_rect_local(board_pos: Vector2) -> Rect2:
	return get_points_bounds_local(get_cell_polygon_local(board_pos))

func get_points_bounds_local(points: PackedVector2Array) -> Rect2:
	if points.size() == 0:
		return Rect2()

	var min_point: Vector2 = points[0]
	var max_point: Vector2 = points[0]
	for point: Vector2 in points:
		min_point.x = min(min_point.x, point.x)
		min_point.y = min(min_point.y, point.y)
		max_point.x = max(max_point.x, point.x)
		max_point.y = max(max_point.y, point.y)
	return Rect2(min_point, max_point - min_point)

func get_mouse_board_position(local_pos: Vector2, invalid_pos: Vector2) -> Vector2:
	for row in board_size:
		for col in board_size:
			var board_pos := Vector2(row, col)
			if Geometry2D.is_point_in_polygon(local_pos, get_cell_polygon_local(board_pos)):
				return board_pos
	return invalid_pos

func get_tile_slide_offset(board_pos: Vector2) -> Vector2:
	var bounds: Rect2 = get_cell_rect_local(board_pos)
	var distance: float = maxf(bounds.size.x, bounds.size.y) * tile_slide_distance_factor
	match randi() % 4:
		0:
			return Vector2(distance, 0.0)
		1:
			return Vector2(-distance, 0.0)
		2:
			return Vector2(0.0, distance)
		_:
			return Vector2(0.0, -distance)

func get_tile_sink_offset() -> Vector2:
	return get_near_direction_local() * tile_sink_offset

func get_near_direction_local() -> Vector2:
	return Vector2(0.0, -1.0) if view_color < 0 else Vector2(0.0, 1.0)

func get_tile_near_neighbor_position(board_pos: Vector2) -> Vector2:
	var row_delta: int = 1 if view_color < 0 else -1
	return board_pos + Vector2(row_delta, 0.0)

func get_tile_far_neighbor_position(board_pos: Vector2) -> Vector2:
	var row_delta: int = -1 if view_color < 0 else 1
	return board_pos + Vector2(row_delta, 0.0)

func get_tile_near_edge_indices() -> Array:
	if view_color < 0:
		return [0, 1]
	return [2, 3]

func get_tile_far_edge_indices() -> Array:
	if view_color < 0:
		return [2, 3]
	return [0, 1]

func get_tile_entry_edge_indices(slide_offset: Vector2) -> Array:
	if absf(slide_offset.x) > absf(slide_offset.y):
		if slide_offset.x > 0.0:
			return [1, 2]
		return [3, 0]
	if slide_offset.y * get_near_direction_local().y > 0.0:
		return get_tile_near_edge_indices()
	return get_tile_far_edge_indices()

func get_tile_slide_cover_position(board_pos: Vector2, slide_offset: Vector2) -> Vector2:
	if absf(slide_offset.x) > absf(slide_offset.y):
		var col_delta: int = 1 if slide_offset.x > 0.0 else -1
		return board_pos + Vector2(0.0, col_delta)
	if slide_offset.y * get_near_direction_local().y > 0.0:
		return get_tile_near_neighbor_position(board_pos)
	return get_tile_far_neighbor_position(board_pos)
