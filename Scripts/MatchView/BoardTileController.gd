extends RefCounted

var match_board
var visuals
var geometry
var board_size: int = 0
var invalid_board_pos: Vector2 = Vector2(-1, -1)

var board_tile_texture: Texture2D
var board_tile_base_white_texture: Texture2D
var board_tile_base_black_texture: Texture2D
var board_tile_freeze_texture: Texture2D
var board_tile_disabled_texture: Texture2D

var special_tile_none: String = ""
var special_tile_base_white: String = "base_white"
var special_tile_base_black: String = "base_black"
var special_tile_freeze: String = "freeze"
var special_tile_disabled: String = "disabled"
var special_tile_z_index: int = 1

var tile_swap_duration: float = 0.26
var tile_sunk_alpha: float = 0.32
var tile_depth_wall_color: Color = Color(0.07, 0.065, 0.055, 0.86)
var tile_occlusion_lip_color: Color = Color(0.0, 0.0, 0.0, 0.30)
var tile_occlusion_lip_inset_factor: float = 0.18
var tile_transition_cover_z_index: int = 5

var frame_width: float = 0.0
var frame_vertical_extension: float = 0.0
var frame_color: Color = Color.WHITE
var side_thickness: float = 0.0
var side_color: Color = Color.WHITE

var shadow_enabled: bool = true
var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.24)
var shadow_offset: Vector2 = Vector2(9.0, 14.0)
var shadow_spread: float = 7.0
var shadow_steps: int = 4

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	visuals = config.get("visuals", visuals)
	geometry = config.get("geometry", geometry)
	board_size = int(config.get("board_size", board_size))
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)

	board_tile_texture = config.get("board_tile_texture", board_tile_texture)
	board_tile_base_white_texture = config.get("board_tile_base_white_texture", board_tile_base_white_texture)
	board_tile_base_black_texture = config.get("board_tile_base_black_texture", board_tile_base_black_texture)
	board_tile_freeze_texture = config.get("board_tile_freeze_texture", board_tile_freeze_texture)
	board_tile_disabled_texture = config.get("board_tile_disabled_texture", board_tile_disabled_texture)

	special_tile_none = str(config.get("special_tile_none", special_tile_none))
	special_tile_base_white = str(config.get("special_tile_base_white", special_tile_base_white))
	special_tile_base_black = str(config.get("special_tile_base_black", special_tile_base_black))
	special_tile_freeze = str(config.get("special_tile_freeze", special_tile_freeze))
	special_tile_disabled = str(config.get("special_tile_disabled", special_tile_disabled))
	special_tile_z_index = int(config.get("special_tile_z_index", special_tile_z_index))

	tile_swap_duration = float(config.get("tile_swap_duration", tile_swap_duration))
	tile_sunk_alpha = float(config.get("tile_sunk_alpha", tile_sunk_alpha))
	tile_depth_wall_color = config.get("tile_depth_wall_color", tile_depth_wall_color)
	tile_occlusion_lip_color = config.get("tile_occlusion_lip_color", tile_occlusion_lip_color)
	tile_occlusion_lip_inset_factor = float(config.get("tile_occlusion_lip_inset_factor", tile_occlusion_lip_inset_factor))
	tile_transition_cover_z_index = int(config.get("tile_transition_cover_z_index", tile_transition_cover_z_index))

	frame_width = float(config.get("frame_width", frame_width))
	frame_vertical_extension = float(config.get("frame_vertical_extension", frame_vertical_extension))
	frame_color = config.get("frame_color", frame_color)
	side_thickness = float(config.get("side_thickness", side_thickness))
	side_color = config.get("side_color", side_color)

	shadow_enabled = bool(config.get("shadow_enabled", shadow_enabled))
	shadow_color = config.get("shadow_color", shadow_color)
	shadow_offset = config.get("shadow_offset", shadow_offset)
	shadow_spread = float(config.get("shadow_spread", shadow_spread))
	shadow_steps = int(config.get("shadow_steps", shadow_steps))

func create_board_tiles() -> void:
	if match_board == null:
		return
	visuals = match_board.get_board_visuals()
	geometry = match_board.get_board_geometry()

	if match_board.board_tiles_node == null:
		match_board.board_tiles_node = Node2D.new()
		match_board.board_tiles_node.name = "BoardTiles"
		match_board.add_child(match_board.board_tiles_node)
		match_board.move_child(match_board.board_tiles_node, 0)

	match_board.board_tiles_node.z_index = 0
	for child in match_board.board_tiles_node.get_children():
		child.free()

	match_board.board_special_tile_nodes.clear()
	match_board.board_special_tile_types.clear()
	match_board.board_special_tiles_initialized = false

	create_board_shadow_visuals()

	match_board.board_frame_node = Node2D.new()
	match_board.board_frame_node.name = "BoardFrame"
	match_board.board_frame_node.z_index = -2
	match_board.board_tiles_node.add_child(match_board.board_frame_node)
	create_board_frame_visuals()

	match_board.board_base_tiles_node = Node2D.new()
	match_board.board_base_tiles_node.name = "BaseTiles"
	match_board.board_base_tiles_node.z_index = 0
	match_board.board_tiles_node.add_child(match_board.board_base_tiles_node)

	match_board.board_special_tiles_node = Node2D.new()
	match_board.board_special_tiles_node.name = "SpecialTiles"
	match_board.board_special_tiles_node.z_index = 1
	match_board.board_tiles_node.add_child(match_board.board_special_tiles_node)

	for row in board_size:
		for col in board_size:
			var board_pos := Vector2(row, col)
			var tile := create_board_tile_polygon(board_pos, board_tile_texture)
			tile.name = "BoardTile_%d_%d" % [row, col]
			match_board.board_base_tiles_node.add_child(tile)

func create_board_tile_polygon(board_pos: Vector2, tile_texture: Texture2D) -> Polygon2D:
	return visuals.create_tile_polygon(board_pos, tile_texture)

func refresh_board_tile_polygon(tile: Polygon2D, board_pos: Vector2) -> void:
	visuals.refresh_tile_polygon(tile, board_pos)

func get_board_tile_texture_uvs(tile_texture: Texture2D) -> PackedVector2Array:
	return visuals.get_tile_texture_uvs(tile_texture)

func create_board_shadow_visuals() -> void:
	if !shadow_enabled:
		return

	var outer_polygon: PackedVector2Array = match_board.get_projected_board_rect_polygon(
		frame_width,
		frame_vertical_extension,
		false
	)
	if outer_polygon.size() < 4:
		return

	var shadow_node := Node2D.new()
	shadow_node.name = "BoardShadow"
	shadow_node.z_index = -24
	match_board.board_tiles_node.add_child(shadow_node)

	var center := Vector2.ZERO
	for point: Vector2 in outer_polygon:
		center += point
	center /= float(outer_polygon.size())

	var layer_count: int = max(1, shadow_steps)
	for index in range(layer_count):
		var ratio: float = 0.0 if layer_count <= 1 else float(index) / float(layer_count - 1)
		var layer_polygon := PackedVector2Array()
		for point: Vector2 in outer_polygon:
			var direction: Vector2 = point - center
			if direction.length_squared() > 0.0001:
				direction = direction.normalized()
			layer_polygon.append(point + shadow_offset + direction * shadow_spread * ratio)

		var shadow_layer := Polygon2D.new()
		shadow_layer.name = "BoardShadowLayer_%d" % index
		shadow_layer.z_index = -index
		shadow_layer.color = Color(
			shadow_color.r,
			shadow_color.g,
			shadow_color.b,
			shadow_color.a * (1.0 - ratio * 0.82)
		)
		shadow_layer.polygon = layer_polygon
		visuals.enable_canvas_item_antialiasing(shadow_layer)
		shadow_node.add_child(shadow_layer)

func create_board_frame_visuals() -> void:
	visuals.create_frame_visuals(
		match_board.board_frame_node,
		frame_width,
		frame_vertical_extension,
		frame_color,
		side_thickness,
		side_color
	)

func create_board_side_visual(outer_polygon: PackedVector2Array) -> void:
	visuals.create_side_visual(match_board.board_frame_node, outer_polygon, side_thickness, side_color)

func update_board_special_tiles() -> void:
	if match_board.board_special_tiles_node == null or !is_instance_valid(match_board.board_special_tiles_node):
		return

	var animate_changes: bool = match_board.board_special_tiles_initialized
	var target_tiles: Dictionary = get_board_special_tile_targets()
	var previous_types: Dictionary = match_board.board_special_tile_types.duplicate()

	for position_value in previous_types.keys():
		var board_pos: Vector2 = match_board.value_to_vector2(position_value, invalid_board_pos)
		if !match_board.is_valid_position(board_pos):
			continue

		var previous_type: String = str(previous_types[position_value])
		var target_type: String = str(target_tiles.get(board_pos, special_tile_none))
		if previous_type == target_type:
			var existing_tile: Polygon2D = match_board.board_special_tile_nodes.get(board_pos, null) as Polygon2D
			if existing_tile != null and is_instance_valid(existing_tile):
				refresh_board_tile_polygon(existing_tile, board_pos)
				continue
			match_board.board_special_tile_nodes.erase(board_pos)
			match_board.board_special_tile_types.erase(board_pos)

		var old_tile: Polygon2D = match_board.board_special_tile_nodes.get(board_pos, null) as Polygon2D
		if old_tile != null and is_instance_valid(old_tile):
			animate_board_tile_out(old_tile, animate_changes)
		match_board.board_special_tile_nodes.erase(board_pos)
		match_board.board_special_tile_types.erase(board_pos)

	for position_value in target_tiles.keys():
		var board_pos: Vector2 = match_board.value_to_vector2(position_value, invalid_board_pos)
		if !match_board.is_valid_position(board_pos):
			continue

		var target_type: String = str(target_tiles[position_value])
		var existing_tile: Polygon2D = match_board.board_special_tile_nodes.get(board_pos, null) as Polygon2D
		if str(previous_types.get(board_pos, special_tile_none)) == target_type and existing_tile != null and is_instance_valid(existing_tile):
			continue

		if animate_changes and !previous_types.has(board_pos):
			var base_clone := create_board_tile_polygon(board_pos, board_tile_texture)
			base_clone.name = "BoardTileSink_%d_%d" % [int(board_pos.x), int(board_pos.y)]
			base_clone.z_index = special_tile_z_index
			match_board.board_special_tiles_node.add_child(base_clone)
			animate_board_tile_out(base_clone, true)

		var new_tile := create_board_tile_polygon(board_pos, get_board_special_tile_texture(target_type))
		new_tile.name = "BoardSpecialTile_%s_%d_%d" % [target_type, int(board_pos.x), int(board_pos.y)]
		new_tile.z_index = special_tile_z_index + 2
		match_board.board_special_tiles_node.add_child(new_tile)
		match_board.board_special_tile_nodes[board_pos] = new_tile
		match_board.board_special_tile_types[board_pos] = target_type
		animate_board_tile_in(new_tile, board_pos, animate_changes)

	match_board.board_special_tiles_initialized = true

func get_board_special_tile_targets() -> Dictionary:
	var targets: Dictionary = {}
	for player_id in [0, 1]:
		var base_pos: Vector2 = match_board.current_player_base_fields.get(player_id, BoardConfig.get_base_field_for_player_id(player_id))
		if !match_board.is_valid_position(base_pos):
			continue
		set_board_special_tile_target(
			targets,
			base_pos,
			special_tile_base_white if player_id == 0 else special_tile_base_black
		)

	for effect_value in match_board.current_board_effects:
		var effect: Dictionary = effect_value
		var effect_type: String = str(effect.get("effect_type", ""))
		var tile_type: String = special_tile_none
		if effect_type == CardEffect.TYPE_INVALID_SQUARES:
			tile_type = special_tile_disabled
		elif effect_type == CardEffect.TYPE_FROZEN_SQUARES:
			tile_type = special_tile_freeze
		if tile_type == special_tile_none:
			continue

		var squares: Array = effect.get("squares", [])
		for square_value in squares:
			var square_pos: Vector2 = match_board.value_to_vector2(square_value, invalid_board_pos)
			if match_board.is_valid_position(square_pos):
				set_board_special_tile_target(targets, square_pos, tile_type)

	return targets

func set_board_special_tile_target(targets: Dictionary, board_pos: Vector2, tile_type: String) -> void:
	var current_type: String = str(targets.get(board_pos, special_tile_none))
	if get_board_special_tile_priority(tile_type) >= get_board_special_tile_priority(current_type):
		targets[board_pos] = tile_type

func get_board_special_tile_priority(tile_type: String) -> int:
	match tile_type:
		special_tile_base_white, special_tile_base_black:
			return 1
		special_tile_freeze:
			return 2
		special_tile_disabled:
			return 3
		_:
			return 0

func get_board_special_tile_texture(tile_type: String) -> Texture2D:
	match tile_type:
		special_tile_base_white:
			return board_tile_base_white_texture
		special_tile_base_black:
			return board_tile_base_black_texture
		special_tile_freeze:
			return board_tile_freeze_texture
		special_tile_disabled:
			return board_tile_disabled_texture
		_:
			return board_tile_texture

func animate_board_tile_out(tile: Polygon2D, animate_change: bool) -> void:
	if tile == null or !is_instance_valid(tile):
		return
	if !animate_change:
		tile.queue_free()
		return

	var board_pos: Vector2 = match_board.value_to_vector2(tile.get_meta("board_pos", invalid_board_pos), invalid_board_pos)
	var sink_offset: Vector2 = geometry.get_tile_sink_offset()
	if match_board.is_valid_position(board_pos):
		animate_board_tile_depth_wall(board_pos, sink_offset, tile_swap_duration)
		create_temporary_board_tile_cover(geometry.get_tile_near_neighbor_position(board_pos), tile_swap_duration)
		create_temporary_board_tile_edge_lip(board_pos, geometry.get_tile_near_edge_indices(), tile_swap_duration)

	tile.z_index = special_tile_z_index + 1
	tile.position = Vector2.ZERO
	tile.modulate = Color.WHITE
	var tween: Tween = match_board.create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tile, "position", sink_offset, tile_swap_duration)
	tween.parallel().tween_property(tile, "modulate:a", tile_sunk_alpha, tile_swap_duration)
	tween.finished.connect(func():
		if is_instance_valid(tile):
			tile.queue_free()
	)

func animate_board_tile_in(tile: Polygon2D, board_pos: Vector2, animate_change: bool) -> void:
	if tile == null or !is_instance_valid(tile):
		return
	if !animate_change:
		tile.position = Vector2.ZERO
		tile.modulate = Color.WHITE
		return

	var slide_offset: Vector2 = geometry.get_tile_slide_offset(board_pos)
	create_temporary_board_tile_cover(geometry.get_tile_slide_cover_position(board_pos, slide_offset), tile_swap_duration)
	create_temporary_board_tile_edge_lip(board_pos, geometry.get_tile_entry_edge_indices(slide_offset), tile_swap_duration)

	tile.position = slide_offset
	tile.modulate = Color.WHITE
	var tween: Tween = match_board.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tile, "position", Vector2.ZERO, tile_swap_duration)

func animate_board_tile_depth_wall(board_pos: Vector2, sink_offset: Vector2, duration: float) -> void:
	if match_board.board_special_tiles_node == null or !is_instance_valid(match_board.board_special_tiles_node):
		return

	var wall := Polygon2D.new()
	wall.name = "BoardTileDepthWall_%d_%d" % [int(board_pos.x), int(board_pos.y)]
	wall.color = tile_depth_wall_color
	wall.z_index = special_tile_z_index + tile_transition_cover_z_index - 1
	visuals.enable_canvas_item_antialiasing(wall)
	match_board.board_special_tiles_node.add_child(wall)
	set_board_tile_depth_wall_polygon(wall, board_pos, sink_offset, 0.0)

	var tween: Tween = match_board.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_method(set_board_tile_depth_wall_progress.bind(wall, board_pos, sink_offset), 0.0, 1.0, duration)
	tween.finished.connect(func():
		if is_instance_valid(wall):
			wall.queue_free()
	)

func set_board_tile_depth_wall_progress(progress: float, wall: Polygon2D, board_pos: Vector2, sink_offset: Vector2) -> void:
	if is_instance_valid(wall):
		set_board_tile_depth_wall_polygon(wall, board_pos, sink_offset, progress)

func set_board_tile_depth_wall_polygon(wall: Polygon2D, board_pos: Vector2, sink_offset: Vector2, progress: float) -> void:
	if wall == null or !is_instance_valid(wall):
		return

	var polygon: PackedVector2Array = match_board.get_board_cell_polygon_local(board_pos)
	if polygon.size() < 4:
		return

	var edge_indices: Array = geometry.get_tile_far_edge_indices()
	var edge_a: Vector2 = polygon[int(edge_indices[0])]
	var edge_b: Vector2 = polygon[int(edge_indices[1])]
	var current_offset: Vector2 = sink_offset * clampf(progress, 0.0, 1.0)
	wall.polygon = PackedVector2Array([
		edge_a,
		edge_b,
		edge_b + current_offset,
		edge_a + current_offset,
	])
	wall.modulate = Color(1.0, 1.0, 1.0, clampf(progress * 1.15, 0.0, 1.0))

func create_temporary_board_tile_cover(board_pos: Vector2, duration: float) -> void:
	if match_board.board_special_tiles_node == null or !is_instance_valid(match_board.board_special_tiles_node):
		return
	if !match_board.is_valid_position(board_pos):
		return

	var cover := create_board_tile_polygon(board_pos, get_board_visible_tile_texture(board_pos))
	cover.name = "BoardTileTransitionCover_%d_%d" % [int(board_pos.x), int(board_pos.y)]
	cover.z_index = special_tile_z_index + tile_transition_cover_z_index
	match_board.board_special_tiles_node.add_child(cover)
	var tween: Tween = match_board.create_tween()
	tween.tween_interval(duration)
	tween.finished.connect(func():
		if is_instance_valid(cover):
			cover.queue_free()
	)

func create_temporary_board_tile_edge_lip(board_pos: Vector2, edge_indices: Array, duration: float) -> void:
	if match_board.board_special_tiles_node == null or !is_instance_valid(match_board.board_special_tiles_node):
		return
	if !match_board.is_valid_position(board_pos) or edge_indices.size() < 2:
		return

	var polygon: PackedVector2Array = match_board.get_board_cell_polygon_local(board_pos)
	if polygon.size() < 4:
		return

	var center: Vector2 = match_board.get_board_position_local_position(board_pos)
	var edge_a: Vector2 = polygon[int(edge_indices[0])]
	var edge_b: Vector2 = polygon[int(edge_indices[1])]
	var lip := Polygon2D.new()
	lip.name = "BoardTileTransitionLip_%d_%d" % [int(board_pos.x), int(board_pos.y)]
	lip.color = tile_occlusion_lip_color
	lip.z_index = special_tile_z_index + tile_transition_cover_z_index + 1
	lip.polygon = PackedVector2Array([
		edge_a,
		edge_b,
		edge_b.lerp(center, tile_occlusion_lip_inset_factor),
		edge_a.lerp(center, tile_occlusion_lip_inset_factor),
	])
	visuals.enable_canvas_item_antialiasing(lip)
	match_board.board_special_tiles_node.add_child(lip)

	var tween: Tween = match_board.create_tween()
	tween.tween_interval(duration)
	tween.finished.connect(func():
		if is_instance_valid(lip):
			lip.queue_free()
	)

func get_board_visible_tile_texture(board_pos: Vector2) -> Texture2D:
	var tile_type: String = str(match_board.board_special_tile_types.get(board_pos, special_tile_none))
	return get_board_special_tile_texture(tile_type)
