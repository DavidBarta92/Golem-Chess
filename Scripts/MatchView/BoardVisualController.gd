extends RefCounted

var geometry

func configure(board_geometry) -> void:
	geometry = board_geometry

func create_tile_polygon(board_pos: Vector2, tile_texture: Texture2D) -> Polygon2D:
	var tile := Polygon2D.new()
	tile.texture = tile_texture
	tile.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tile.color = Color.WHITE
	tile.set_meta("board_pos", board_pos)
	refresh_tile_polygon(tile, board_pos)
	enable_canvas_item_antialiasing(tile)
	return tile

func refresh_tile_polygon(tile: Polygon2D, board_pos: Vector2) -> void:
	if tile == null or !is_instance_valid(tile) or geometry == null:
		return

	var polygon: PackedVector2Array = geometry.get_cell_polygon_local(board_pos)
	tile.set_meta("board_pos", board_pos)
	tile.polygon = polygon
	tile.uv = get_tile_texture_uvs(tile.texture)

func get_tile_texture_uvs(tile_texture: Texture2D) -> PackedVector2Array:
	var texture_size := Vector2.ONE
	if tile_texture != null:
		texture_size = tile_texture.get_size()
	return PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(texture_size.x, 0.0),
		Vector2(texture_size.x, texture_size.y),
		Vector2(0.0, texture_size.y),
	])

func create_frame_visuals(
	board_frame_node: Node2D,
	frame_width: float,
	vertical_extension: float,
	frame_color: Color,
	side_thickness: float,
	side_color: Color
) -> void:
	if board_frame_node == null or !is_instance_valid(board_frame_node) or geometry == null:
		return

	for child in board_frame_node.get_children():
		child.free()

	var inner_polygon: PackedVector2Array = geometry.get_projected_board_rect_polygon(0.0, 0.0, false)
	var outer_polygon: PackedVector2Array = geometry.get_projected_board_rect_polygon(frame_width, vertical_extension, false)
	if inner_polygon.size() < 4 or outer_polygon.size() < 4:
		return

	create_side_visual(board_frame_node, outer_polygon, side_thickness, side_color)
	for index in range(4):
		var next_index: int = (index + 1) % 4
		var frame_strip := Polygon2D.new()
		frame_strip.name = "BoardFrameStrip_%d" % index
		frame_strip.color = frame_color
		frame_strip.z_index = -1
		frame_strip.polygon = PackedVector2Array([
			outer_polygon[index],
			outer_polygon[next_index],
			inner_polygon[next_index],
			inner_polygon[index],
		])
		enable_canvas_item_antialiasing(frame_strip)
		board_frame_node.add_child(frame_strip)

func create_side_visual(
	board_frame_node: Node2D,
	outer_polygon: PackedVector2Array,
	side_thickness: float,
	side_color: Color
) -> void:
	if board_frame_node == null or !is_instance_valid(board_frame_node) or geometry == null:
		return

	var edge_indices: Array = geometry.get_tile_near_edge_indices()
	if outer_polygon.size() < 4 or edge_indices.size() < 2:
		return

	var edge_a: Vector2 = outer_polygon[int(edge_indices[0])]
	var edge_b: Vector2 = outer_polygon[int(edge_indices[1])]
	var side_offset: Vector2 = geometry.get_near_direction_local() * side_thickness
	var side := Polygon2D.new()
	side.name = "BoardSideNear"
	side.color = side_color
	side.z_index = -2
	side.polygon = PackedVector2Array([
		edge_a,
		edge_b,
		edge_b + side_offset,
		edge_a + side_offset,
	])
	enable_canvas_item_antialiasing(side)
	board_frame_node.add_child(side)

func create_square_fill(board_markers_node: Node2D, board_pos: Vector2, marker_color: Color) -> Polygon2D:
	if board_markers_node == null or !is_instance_valid(board_markers_node) or geometry == null:
		return null

	var marker := Polygon2D.new()
	marker.color = marker_color
	marker.polygon = geometry.get_cell_polygon_local(board_pos)
	enable_canvas_item_antialiasing(marker)
	board_markers_node.add_child(marker)
	return marker

func add_line(board_markers_node: Node2D, points: Array, line_color: Color, line_width: float) -> Line2D:
	if board_markers_node == null or !is_instance_valid(board_markers_node):
		return null

	var line := Line2D.new()
	line.default_color = line_color
	line.width = line_width
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	enable_canvas_item_antialiasing(line)
	for point_value in points:
		line.add_point(point_value)
	board_markers_node.add_child(line)
	return line

func add_arrow(
	board_markers_node: Node2D,
	from_pos: Vector2,
	to_pos: Vector2,
	arrow_color: Color,
	line_width: float,
	endpoint_inset: float,
	head_length: float,
	head_half_width: float
) -> Polygon2D:
	if board_markers_node == null or !is_instance_valid(board_markers_node) or geometry == null:
		return null

	var start_point: Vector2 = geometry.get_position_local(from_pos)
	var end_point: Vector2 = geometry.get_position_local(to_pos)
	var direction: Vector2 = end_point - start_point
	if direction.length() <= 0.0:
		return null

	var normalized_direction: Vector2 = direction.normalized()
	var perpendicular: Vector2 = Vector2(-normalized_direction.y, normalized_direction.x)
	start_point += normalized_direction * endpoint_inset
	end_point -= normalized_direction * endpoint_inset

	var arrow_head := Polygon2D.new()
	var head_base: Vector2 = end_point - normalized_direction * head_length
	add_line(board_markers_node, [start_point, head_base], arrow_color, line_width)
	arrow_head.color = arrow_color
	arrow_head.polygon = PackedVector2Array([
		end_point,
		head_base + perpendicular * head_half_width,
		head_base - perpendicular * head_half_width,
	])
	enable_canvas_item_antialiasing(arrow_head)
	board_markers_node.add_child(arrow_head)
	return arrow_head

func get_cell_polygon_uvs(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() == 4:
		return PackedVector2Array([
			Vector2(0.0, 0.0),
			Vector2(1.0, 0.0),
			Vector2(1.0, 1.0),
			Vector2(0.0, 1.0),
		])

	if geometry == null:
		return PackedVector2Array()

	var bounds: Rect2 = geometry.get_points_bounds_local(points)
	var uv_points := PackedVector2Array()
	for point: Vector2 in points:
		var uv := Vector2.ZERO
		if bounds.size.x > 0.0001:
			uv.x = (point.x - bounds.position.x) / bounds.size.x
		if bounds.size.y > 0.0001:
			uv.y = (point.y - bounds.position.y) / bounds.size.y
		uv_points.append(uv)
	return uv_points

func enable_canvas_item_antialiasing(canvas_item: Object) -> void:
	if canvas_item == null:
		return
	for property: Dictionary in canvas_item.get_property_list():
		if str(property.get("name", "")) == "antialiased":
			canvas_item.set("antialiased", true)
			return
