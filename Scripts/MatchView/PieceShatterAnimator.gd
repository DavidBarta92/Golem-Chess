extends RefCounted

var geometry
var piece_visuals
var pieces_node: Node
var piece_effects_node: Node
var tween_owner: Node
var board_size: int = BoardConfig.BOARD_SIZE
var cell_width: int = BoardConfig.CELL_WIDTH
var view_color: int = 1
var invalid_board_pos: Vector2 = Vector2(-1, -1)
var texture_filter_value = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
var piece_effect_light_receive_mask: int = 0
var flipped_view: bool = false

var returning_debris_count: int = 3
var scatter_duration: float = 0.46
var fade_duration: float = 0.42
var return_duration: float = 0.38
var return_fade_duration: float = 0.16
var fragment_settle_duration: float = 0.24
var scatter_radius: float = 0.84
var scatter_jitter: float = 0.28
var min_piece_scale: float = 0.16
var max_piece_scale: float = 0.32
var avoid_occupied_cells: bool = true
var route_jitter_ratio: float = 0.12
var fragment_landing_hold_duration: float = 0.08
var route_z_front_offset: int = 2
var route_z_back_offset: int = -1
var route_direct_fallback_offset: float = 0.72
var return_acceleration_progress: float = 0.5
var fragment_group_bottom: String = "bottom"

var route_cell_blocked_provider: Callable = Callable()
var finish_respawn_fragment_callback: Callable = Callable()
var player_id_for_color_provider: Callable = Callable()
var antialias_provider: Callable = Callable()

func configure(config: Dictionary) -> void:
	geometry = config.get("geometry", geometry)
	piece_visuals = config.get("piece_visuals", piece_visuals)
	pieces_node = config.get("pieces_node", pieces_node)
	piece_effects_node = config.get("piece_effects_node", piece_effects_node)
	tween_owner = config.get("tween_owner", tween_owner)
	board_size = int(config.get("board_size", board_size))
	cell_width = int(config.get("cell_width", cell_width))
	view_color = -1 if int(config.get("view_color", view_color)) < 0 else 1
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)
	texture_filter_value = config.get("texture_filter", texture_filter_value)
	piece_effect_light_receive_mask = int(config.get("piece_effect_light_receive_mask", piece_effect_light_receive_mask))
	flipped_view = bool(config.get("flipped_view", flipped_view))

	returning_debris_count = int(config.get("returning_debris_count", returning_debris_count))
	scatter_duration = float(config.get("scatter_duration", scatter_duration))
	fade_duration = float(config.get("fade_duration", fade_duration))
	return_duration = float(config.get("return_duration", return_duration))
	return_fade_duration = float(config.get("return_fade_duration", return_fade_duration))
	fragment_settle_duration = float(config.get("fragment_settle_duration", fragment_settle_duration))
	scatter_radius = float(config.get("scatter_radius", scatter_radius))
	scatter_jitter = float(config.get("scatter_jitter", scatter_jitter))
	min_piece_scale = float(config.get("min_piece_scale", min_piece_scale))
	max_piece_scale = float(config.get("max_piece_scale", max_piece_scale))
	avoid_occupied_cells = bool(config.get("avoid_occupied_cells", avoid_occupied_cells))
	route_jitter_ratio = float(config.get("route_jitter_ratio", route_jitter_ratio))
	fragment_landing_hold_duration = float(config.get("fragment_landing_hold_duration", fragment_landing_hold_duration))
	route_z_front_offset = int(config.get("route_z_front_offset", route_z_front_offset))
	route_z_back_offset = int(config.get("route_z_back_offset", route_z_back_offset))
	route_direct_fallback_offset = float(config.get("route_direct_fallback_offset", route_direct_fallback_offset))
	return_acceleration_progress = float(config.get("return_acceleration_progress", return_acceleration_progress))
	fragment_group_bottom = str(config.get("fragment_group_bottom", fragment_group_bottom))

	route_cell_blocked_provider = config.get("route_cell_blocked_provider", route_cell_blocked_provider)
	finish_respawn_fragment_callback = config.get("finish_respawn_fragment_callback", finish_respawn_fragment_callback)
	player_id_for_color_provider = config.get("player_id_for_color_provider", player_id_for_color_provider)
	antialias_provider = config.get("antialias_provider", antialias_provider)

func create_fragment(source_pos: Vector2, texture_value: Texture2D, fragment_index: int) -> Sprite2D:
	if texture_value == null or piece_effects_node == null or !is_instance_valid(piece_effects_node):
		return null
	if !_is_valid_position(source_pos):
		return null

	var fragment := Sprite2D.new()
	if flipped_view:
		fragment.global_rotation_degrees = 180
	piece_effects_node.add_child(fragment)
	fragment.name = "PieceShatterFragment_%d" % fragment_index
	fragment.light_mask = piece_effect_light_receive_mask
	fragment.texture_filter = texture_filter_value
	fragment.texture = texture_value
	fragment.z_as_relative = false
	fragment.position = get_position_local(source_pos)
	fragment.set_meta("board_pos", source_pos)
	fragment.z_index = get_z_index_for_local_position(fragment.position)
	fragment.self_modulate = Color.WHITE
	apply_piece_visual_size(fragment, source_pos)
	return fragment

func create_pending_edge_fragment_markers(piece_color: int, fragment_textures: Array[Texture2D], return_count: int) -> Array[Sprite2D]:
	var fragments: Array[Sprite2D] = []
	if piece_effects_node == null or !is_instance_valid(piece_effects_node):
		return fragments

	var home_pos: Vector2 = Vector2(BoardConfig.get_home_row_for_player_id(get_player_id_for_color(piece_color)), BoardConfig.CENTER_INDEX)
	for fragment_index in range(return_count):
		if fragment_index >= fragment_textures.size():
			break
		var texture_value: Texture2D = fragment_textures[fragment_index]
		if texture_value == null:
			continue

		var fragment := Sprite2D.new()
		if flipped_view:
			fragment.global_rotation_degrees = 180
		piece_effects_node.add_child(fragment)
		fragment.name = "PendingRespawnFragment_%d" % fragment_index
		fragment.light_mask = piece_effect_light_receive_mask
		fragment.texture_filter = texture_filter_value
		fragment.texture = texture_value
		fragment.z_as_relative = false
		fragment.position = get_pending_respawn_edge_fragment_target(piece_color, fragment_index)
		fragment.z_index = get_z_index_for_local_position(fragment.position)
		fragment.self_modulate = Color.WHITE
		apply_piece_visual_size(fragment, home_pos)
		fragments.append(fragment)
	return fragments

func animate_fragment(fragment: Sprite2D, scatter_target: Vector2, source_pos: Vector2, respawn_pos: Vector2, fragment_group: String, fragment_index: int) -> void:
	if fragment == null or !is_instance_valid(fragment) or !_is_valid_position(respawn_pos):
		return

	var rest_rotation: float = fragment.rotation
	var target_transform: Dictionary = get_visual_transform_for_texture(fragment.texture, respawn_pos)
	var target_scale: Vector2 = target_transform.get("scale", fragment.scale)
	var target_offset: Vector2 = target_transform.get("offset", fragment.offset)
	var fall_duration: float = maxf(0.05, scatter_duration * 0.62)
	var bounce_duration: float = maxf(0.03, scatter_duration * 0.18)
	var roll_duration: float = maxf(0.03, scatter_duration * 0.20)
	var bounce_target: Vector2 = scatter_target + Vector2(randf_range(-5.0, 5.0), -randf_range(5.0, 10.0))
	var settled_target: Vector2 = scatter_target + Vector2(randf_range(-4.0, 4.0), randf_range(-2.0, 2.0))
	var scattered_rotation: float = rest_rotation + randf_range(-PI * 0.75, PI * 0.75)
	var settled_rotation: float = scattered_rotation + randf_range(-PI * 0.18, PI * 0.18)
	var return_path: Array[Vector2] = [settled_target]
	return_path.append_array(get_return_route_points(source_pos, respawn_pos, fragment_index))

	var tween: Tween = create_animation_tween()
	if tween == null:
		return
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(local_pos: Vector2): update_item_motion(fragment, local_pos), fragment.position, scatter_target, fall_duration)
	tween.parallel().tween_property(fragment, "rotation", scattered_rotation, fall_duration)
	tween.parallel().tween_property(fragment, "scale", fragment.scale * randf_range(0.92, 1.12), fall_duration)

	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_method(func(local_pos: Vector2): update_item_motion(fragment, local_pos), scatter_target, bounce_target, bounce_duration)
	tween.parallel().tween_property(fragment, "rotation", scattered_rotation + randf_range(-PI * 0.10, PI * 0.10), bounce_duration)

	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(func(local_pos: Vector2): update_item_motion(fragment, local_pos), bounce_target, settled_target, roll_duration)
	tween.parallel().tween_property(fragment, "rotation", settled_rotation, roll_duration)

	tween.tween_interval(fragment_settle_duration)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(progress: float): update_respawn_path_motion(fragment, return_path, get_return_motion_progress(progress), respawn_pos), 0.0, 1.0, return_duration)
	tween.parallel().tween_property(fragment, "rotation", rest_rotation, return_duration)
	tween.parallel().tween_property(fragment, "scale", target_scale, return_duration)
	tween.parallel().tween_property(fragment, "offset", target_offset, return_duration)
	tween_respawn_finish_callback(tween, respawn_pos)
	if fragment_group == fragment_group_bottom:
		return

	tween.tween_interval(fragment_landing_hold_duration)
	tween.tween_property(fragment, "self_modulate:a", 0.0, return_fade_duration)
	tween.finished.connect(func():
		if is_instance_valid(fragment):
			fragment.queue_free()
	)

func animate_pending_edge_fragment(fragment: Sprite2D, scatter_target: Vector2, source_pos: Vector2, piece_color: int, fragment_index: int) -> void:
	if fragment == null or !is_instance_valid(fragment):
		return

	var rest_rotation: float = fragment.rotation
	var fall_duration: float = maxf(0.05, scatter_duration * 0.62)
	var bounce_duration: float = maxf(0.03, scatter_duration * 0.18)
	var roll_duration: float = maxf(0.03, scatter_duration * 0.20)
	var bounce_target: Vector2 = scatter_target + Vector2(randf_range(-5.0, 5.0), -randf_range(5.0, 10.0))
	var settled_target: Vector2 = scatter_target + Vector2(randf_range(-4.0, 4.0), randf_range(-2.0, 2.0))
	var edge_target: Vector2 = get_pending_respawn_edge_fragment_target(piece_color, fragment_index)
	var scattered_rotation: float = rest_rotation + randf_range(-PI * 0.75, PI * 0.75)
	var settled_rotation: float = scattered_rotation + randf_range(-PI * 0.18, PI * 0.18)
	var return_path: Array[Vector2] = [settled_target]
	return_path.append_array(get_edge_route_points(source_pos, edge_target, fragment_index))
	return_path.append(edge_target)

	var tween: Tween = create_animation_tween()
	if tween == null:
		return
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(local_pos: Vector2): update_item_motion(fragment, local_pos), fragment.position, scatter_target, fall_duration)
	tween.parallel().tween_property(fragment, "rotation", scattered_rotation, fall_duration)
	tween.parallel().tween_property(fragment, "scale", fragment.scale * randf_range(0.92, 1.12), fall_duration)

	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_method(func(local_pos: Vector2): update_item_motion(fragment, local_pos), scatter_target, bounce_target, bounce_duration)
	tween.parallel().tween_property(fragment, "rotation", scattered_rotation + randf_range(-PI * 0.10, PI * 0.10), bounce_duration)

	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(func(local_pos: Vector2): update_item_motion(fragment, local_pos), bounce_target, settled_target, roll_duration)
	tween.parallel().tween_property(fragment, "rotation", settled_rotation, roll_duration)

	tween.tween_interval(fragment_settle_duration)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(progress: float): update_item_path_motion(fragment, return_path, get_return_motion_progress(progress)), 0.0, 1.0, return_duration)
	tween.parallel().tween_property(fragment, "rotation", rest_rotation, return_duration)

func animate_pending_edge_arrival_fragment(fragment: Sprite2D, respawn_pos: Vector2, fragment_group: String, fragment_index: int) -> void:
	if fragment == null or !is_instance_valid(fragment) or !_is_valid_position(respawn_pos):
		return

	var rest_rotation: float = fragment.rotation
	var target_transform: Dictionary = get_visual_transform_for_texture(fragment.texture, respawn_pos)
	var target_scale: Vector2 = target_transform.get("scale", fragment.scale)
	var target_offset: Vector2 = target_transform.get("offset", fragment.offset)
	var start_pos: Vector2 = fragment.position
	var target_pos: Vector2 = get_position_local(respawn_pos)
	var path_points: Array[Vector2] = [start_pos]
	path_points.append_array(get_edge_route_points(get_nearest_board_position_for_local_position(start_pos), target_pos, fragment_index))
	path_points.append(target_pos)

	var tween: Tween = create_animation_tween()
	if tween == null:
		return
	tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(progress: float): update_respawn_path_motion(fragment, path_points, get_return_motion_progress(progress), respawn_pos), 0.0, 1.0, return_duration)
	tween.parallel().tween_property(fragment, "rotation", rest_rotation, return_duration)
	tween.parallel().tween_property(fragment, "scale", target_scale, return_duration)
	tween.parallel().tween_property(fragment, "offset", target_offset, return_duration)
	tween_respawn_finish_callback(tween, respawn_pos)
	if fragment_group == fragment_group_bottom:
		return

	tween.tween_interval(fragment_landing_hold_duration)
	tween.tween_property(fragment, "self_modulate:a", 0.0, return_fade_duration)
	tween.finished.connect(func():
		if is_instance_valid(fragment):
			fragment.queue_free()
	)

func create_shard(source_pos: Vector2, piece_color: int, debris_index: int) -> Polygon2D:
	if piece_effects_node == null or !is_instance_valid(piece_effects_node):
		return null

	var source_center: Vector2 = get_position_local(source_pos)
	var shard := Polygon2D.new()
	var shard_scale_min: float = minf(min_piece_scale, max_piece_scale)
	var shard_scale_max: float = maxf(min_piece_scale, max_piece_scale)
	shard.name = "PieceShatter_%d" % debris_index
	shard.position = source_center + Vector2(randf_range(-2.0, 2.0), randf_range(-3.0, 2.0))
	shard.rotation = randf_range(-PI, PI)
	shard.scale = Vector2.ONE * randf_range(shard_scale_min, shard_scale_max) * get_perspective_scale(source_pos)
	shard.color = get_piece_shatter_color(piece_color)
	shard.polygon = create_shatter_polygon()
	shard.z_as_relative = false
	shard.z_index = get_z_index_for_local_position(shard.position)
	shard.light_mask = piece_effect_light_receive_mask
	enable_antialiasing(shard)
	piece_effects_node.add_child(shard)
	return shard

func create_shatter_polygon() -> PackedVector2Array:
	var point_count: int = randi_range(3, 5)
	var radius: float = randf_range(7.0, 13.0)
	var points := PackedVector2Array()
	for point_index in range(point_count):
		var angle: float = TAU * float(point_index) / float(point_count) + randf_range(-0.22, 0.22)
		var point_radius: float = radius * randf_range(0.58, 1.08)
		points.append(Vector2(cos(angle), sin(angle)) * point_radius)
	return points

func get_piece_shatter_color(piece_color: int) -> Color:
	var base_color: Color = Color(0.62, 0.60, 0.55, 1.0) if piece_color > 0 else Color(0.22, 0.22, 0.21, 1.0)
	var warm_tint: Color = Color(0.78, 0.70, 0.58, 1.0) if piece_color > 0 else Color(0.34, 0.32, 0.29, 1.0)
	var tint_amount: float = randf_range(0.0, 0.38)
	var brightness: float = randf_range(0.86, 1.16)
	var color: Color = base_color.lerp(warm_tint, tint_amount)
	color.r = clampf(color.r * brightness, 0.0, 1.0)
	color.g = clampf(color.g * brightness, 0.0, 1.0)
	color.b = clampf(color.b * brightness, 0.0, 1.0)
	color.a = 1.0
	return color

func animate_shard(shard: Polygon2D, scatter_target: Vector2, return_center: Vector2, returns_to_respawn: bool) -> void:
	if shard == null or !is_instance_valid(shard):
		return

	var tween: Tween = create_animation_tween()
	if tween == null:
		return
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(func(local_pos: Vector2): update_item_motion(shard, local_pos), shard.position, scatter_target, scatter_duration)
	tween.parallel().tween_property(shard, "rotation", shard.rotation + randf_range(-PI * 1.4, PI * 1.4), scatter_duration)
	tween.parallel().tween_property(shard, "scale", shard.scale * randf_range(0.82, 1.18), scatter_duration)

	if returns_to_respawn and return_center != invalid_board_pos:
		tween.tween_interval(fade_duration)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_method(func(local_pos: Vector2): update_item_motion(shard, local_pos), scatter_target, return_center + Vector2(randf_range(-3.0, 3.0), randf_range(-5.0, 2.0)), return_duration)
		tween.parallel().tween_property(shard, "rotation", shard.rotation + randf_range(-PI * 2.0, PI * 2.0), return_duration)
		tween.tween_property(shard, "modulate:a", 0.0, return_fade_duration)
	else:
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(shard, "modulate:a", 0.0, fade_duration)

	tween.finished.connect(func():
		if is_instance_valid(shard):
			shard.queue_free()
	)

func get_return_route_points(source_pos: Vector2, respawn_pos: Vector2, fragment_index: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if !_is_valid_position(respawn_pos):
		return points

	var route_cells: Array[Vector2] = get_route_cells(source_pos, respawn_pos)
	if route_cells.size() > 2:
		for route_index in range(1, route_cells.size() - 1):
			points.append(get_route_cell_local_point(route_cells[route_index], fragment_index, route_index))
	else:
		points.append_array(get_direct_fallback_route_points(source_pos, respawn_pos, fragment_index))

	points.append(get_position_local(respawn_pos))
	return points

func get_route_cells(source_pos: Vector2, respawn_pos: Vector2) -> Array[Vector2]:
	var fallback: Array[Vector2] = []
	if _is_valid_position(source_pos):
		fallback.append(source_pos)
	if _is_valid_position(respawn_pos) and respawn_pos != source_pos:
		fallback.append(respawn_pos)
	if !avoid_occupied_cells or !_is_valid_position(source_pos) or !_is_valid_position(respawn_pos):
		return fallback

	var open_cells: Array[Vector2] = [source_pos]
	var came_from: Dictionary = {}
	came_from[source_pos] = invalid_board_pos
	while !open_cells.is_empty():
		var current_pos: Vector2 = open_cells.pop_front()
		if current_pos == respawn_pos:
			return reconstruct_route_cells(came_from, respawn_pos)

		for direction: Vector2 in get_route_directions(current_pos, respawn_pos):
			var next_pos: Vector2 = current_pos + direction
			if came_from.has(next_pos):
				continue
			if is_route_cell_blocked(next_pos, source_pos, respawn_pos):
				continue
			if absf(direction.x) > 0.0 and absf(direction.y) > 0.0:
				var horizontal_pos: Vector2 = current_pos + Vector2(direction.x, 0.0)
				var vertical_pos: Vector2 = current_pos + Vector2(0.0, direction.y)
				if is_route_cell_blocked(horizontal_pos, source_pos, respawn_pos) and is_route_cell_blocked(vertical_pos, source_pos, respawn_pos):
					continue

			came_from[next_pos] = current_pos
			open_cells.append(next_pos)

	return fallback

func reconstruct_route_cells(came_from: Dictionary, end_pos: Vector2) -> Array[Vector2]:
	var route: Array[Vector2] = []
	var current_pos: Vector2 = end_pos
	while _is_valid_position(current_pos):
		route.push_front(current_pos)
		current_pos = value_to_vector2(came_from.get(current_pos, invalid_board_pos), invalid_board_pos)
	return route

func get_route_directions(current_pos: Vector2, target_pos: Vector2) -> Array[Vector2]:
	var directions: Array[Vector2] = [
		Vector2(-1, 0),
		Vector2(1, 0),
		Vector2(0, -1),
		Vector2(0, 1),
		Vector2(-1, -1),
		Vector2(-1, 1),
		Vector2(1, -1),
		Vector2(1, 1),
	]
	directions.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return (current_pos + a).distance_squared_to(target_pos) < (current_pos + b).distance_squared_to(target_pos)
	)
	return directions

func get_route_cell_local_point(board_pos: Vector2, fragment_index: int, route_index: int) -> Vector2:
	var center: Vector2 = get_position_local(board_pos)
	var jitter_radius: float = float(cell_width) * route_jitter_ratio * get_perspective_scale(board_pos)
	if jitter_radius <= 0.0:
		return center
	var jitter_angle: float = randf_range(0.0, TAU) + float(fragment_index + route_index) * 0.37
	var jitter := Vector2(cos(jitter_angle), sin(jitter_angle) * 0.65) * randf_range(jitter_radius * 0.35, jitter_radius)
	return center + jitter

func get_direct_fallback_route_points(source_pos: Vector2, respawn_pos: Vector2, fragment_index: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if !_is_valid_position(source_pos) or !_is_valid_position(respawn_pos) or source_pos == respawn_pos:
		return points

	var source_center: Vector2 = get_position_local(source_pos)
	var target_center: Vector2 = get_position_local(respawn_pos)
	var travel: Vector2 = target_center - source_center
	if travel.length_squared() <= 0.001:
		return points

	var side_sign: float = 1.0 if fragment_index % 2 == 0 else -1.0
	var perpendicular: Vector2 = Vector2(-travel.y, travel.x).normalized() * side_sign
	var route_offset: Vector2 = perpendicular * float(cell_width) * route_direct_fallback_offset
	points.append(source_center.lerp(target_center, 0.36) + route_offset)
	points.append(source_center.lerp(target_center, 0.68) + route_offset * 0.58)
	return points

func get_pending_respawn_edge_anchor_local(piece_color: int) -> Vector2:
	var player_id: int = get_player_id_for_color(piece_color)
	var home_row: int = BoardConfig.get_home_row_for_player_id(player_id)
	var home_pos: Vector2 = Vector2(home_row, BoardConfig.CENTER_INDEX)
	var inside_row: int = clampi(home_row + (1 if home_row == 0 else -1), 0, board_size - 1)
	var inside_pos: Vector2 = Vector2(inside_row, BoardConfig.CENTER_INDEX)
	var home_center: Vector2 = get_position_local(home_pos)
	var inside_center: Vector2 = get_position_local(inside_pos)
	var outward: Vector2 = home_center - inside_center
	if outward.length_squared() <= 0.001:
		outward = Vector2(0.0, 1.0 if home_row == 0 else -1.0)
	return home_center + outward.normalized() * float(cell_width) * 1.15

func get_pending_respawn_edge_fragment_target(piece_color: int, fragment_index: int) -> Vector2:
	var anchor: Vector2 = get_pending_respawn_edge_anchor_local(piece_color)
	var player_id: int = get_player_id_for_color(piece_color)
	var home_row: int = BoardConfig.get_home_row_for_player_id(player_id)
	var home_center: Vector2 = get_position_local(Vector2(home_row, BoardConfig.CENTER_INDEX))
	var outward: Vector2 = anchor - home_center
	if outward.length_squared() <= 0.001:
		outward = Vector2(0.0, 1.0)
	outward = outward.normalized()
	var tangent := Vector2(-outward.y, outward.x)
	var spread_offset: float = float(fragment_index - 1) * float(cell_width) * 0.26
	var depth_offset: float = float((fragment_index % 2) - 0.5) * float(cell_width) * 0.10
	return anchor + tangent * spread_offset + outward * depth_offset

func get_edge_route_points(source_pos: Vector2, target_local_pos: Vector2, fragment_index: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if !_is_valid_position(source_pos):
		return points

	var source_center: Vector2 = get_position_local(source_pos)
	var travel: Vector2 = target_local_pos - source_center
	if travel.length_squared() <= 0.001:
		return points

	var side_sign: float = 1.0 if fragment_index % 2 == 0 else -1.0
	var perpendicular: Vector2 = Vector2(-travel.y, travel.x).normalized() * side_sign
	var route_offset: Vector2 = perpendicular * float(cell_width) * route_direct_fallback_offset
	points.append(source_center.lerp(target_local_pos, 0.42) + route_offset)
	points.append(source_center.lerp(target_local_pos, 0.72) + route_offset * 0.48)
	return points

func get_scatter_target(source_pos: Vector2, debris_index: int) -> Vector2:
	var directions: Array[Vector2] = [
		Vector2(-1, -1),
		Vector2(-1, 0),
		Vector2(-1, 1),
		Vector2(0, -1),
		Vector2(0, 1),
		Vector2(1, -1),
		Vector2(1, 0),
		Vector2(1, 1),
	]
	var direction: Vector2 = get_scatter_direction(source_pos, debris_index, directions)
	var source_center: Vector2 = get_position_local(source_pos)
	var target_pos: Vector2 = source_pos + direction
	var target_center: Vector2 = source_center
	if _is_valid_position(target_pos):
		target_center = get_position_local(target_pos)
	else:
		target_center = source_center + direction.normalized() * float(cell_width) * scatter_radius

	var travel: Vector2 = target_center - source_center
	var jitter_radius: float = maxf(3.0, float(cell_width) * scatter_jitter)
	var jitter: Vector2 = Vector2(randf_range(-jitter_radius, jitter_radius), randf_range(-jitter_radius, jitter_radius))
	var travel_factor_min: float = minf(scatter_radius * 0.68, scatter_radius)
	var travel_factor_max: float = maxf(travel_factor_min, scatter_radius)
	return source_center + travel * randf_range(travel_factor_min, travel_factor_max) + jitter

func get_scatter_direction(source_pos: Vector2, debris_index: int, directions: Array[Vector2]) -> Vector2:
	if directions.is_empty():
		return Vector2.ZERO
	if !avoid_occupied_cells:
		return directions[debris_index % directions.size()]

	var start_index: int = debris_index % directions.size()
	for offset in range(directions.size()):
		var direction: Vector2 = directions[(start_index + offset) % directions.size()]
		var target_pos: Vector2 = source_pos + direction
		if is_route_cell_blocked(target_pos, source_pos, invalid_board_pos):
			continue
		if absf(direction.x) > 0.0 and absf(direction.y) > 0.0:
			var horizontal_pos: Vector2 = source_pos + Vector2(direction.x, 0.0)
			var vertical_pos: Vector2 = source_pos + Vector2(0.0, direction.y)
			if is_route_cell_blocked(horizontal_pos, source_pos, invalid_board_pos) and is_route_cell_blocked(vertical_pos, source_pos, invalid_board_pos):
				continue
		return direction

	return directions[start_index]

func update_item_path_motion(item: Node2D, path_points: Array[Vector2], progress: float) -> void:
	update_item_motion(item, get_polyline_position(path_points, progress))

func update_respawn_path_motion(item: Node2D, path_points: Array[Vector2], progress: float, respawn_pos: Vector2) -> void:
	var local_pos: Vector2 = get_polyline_position(path_points, progress)
	update_respawn_item_motion(item, local_pos, respawn_pos)

func update_item_motion(item: Node2D, local_pos: Vector2) -> void:
	if item == null or !is_instance_valid(item):
		return
	item.position = local_pos
	item.z_index = get_z_index_for_local_position(local_pos)

func update_respawn_item_motion(item: Node2D, local_pos: Vector2, respawn_pos: Vector2) -> void:
	if item == null or !is_instance_valid(item):
		return
	item.position = local_pos
	item.z_index = get_respawn_z_index_for_local_position(local_pos, respawn_pos)

func get_return_motion_progress(progress: float) -> float:
	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	var split_progress: float = clampf(return_acceleration_progress, 0.05, 0.95)
	if clamped_progress <= split_progress:
		var acceleration_progress: float = clamped_progress / split_progress
		return split_progress * get_exponential_ease_in_progress(acceleration_progress)

	var deceleration_progress: float = (clamped_progress - split_progress) / (1.0 - split_progress)
	return split_progress + (1.0 - split_progress) * get_exponential_ease_out_progress(deceleration_progress)

func get_exponential_ease_in_progress(progress: float) -> float:
	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	if clamped_progress <= 0.0:
		return 0.0
	if clamped_progress >= 1.0:
		return 1.0
	return pow(2.0, 10.0 * (clamped_progress - 1.0))

func get_exponential_ease_out_progress(progress: float) -> float:
	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	if clamped_progress <= 0.0:
		return 0.0
	if clamped_progress >= 1.0:
		return 1.0
	return 1.0 - pow(2.0, -10.0 * clamped_progress)

func get_polyline_position(path_points: Array[Vector2], progress: float) -> Vector2:
	if path_points.is_empty():
		return Vector2.ZERO
	if path_points.size() == 1:
		return path_points[0]

	var total_length: float = 0.0
	var segment_lengths: Array[float] = []
	for index in range(path_points.size() - 1):
		var segment_length: float = maxf(0.001, path_points[index].distance_to(path_points[index + 1]))
		segment_lengths.append(segment_length)
		total_length += segment_length

	var target_distance: float = clampf(progress, 0.0, 1.0) * total_length
	var covered_distance: float = 0.0
	for index in range(segment_lengths.size()):
		var segment_length: float = segment_lengths[index]
		if covered_distance + segment_length >= target_distance:
			var segment_progress: float = (target_distance - covered_distance) / segment_length
			return path_points[index].lerp(path_points[index + 1], segment_progress)
		covered_distance += segment_length

	return path_points[path_points.size() - 1]

func get_z_index_for_local_position(local_pos: Vector2) -> int:
	var base_z_index: int = int(pieces_node.z_index) if pieces_node != null else 0
	var nearest_pos: Vector2 = get_nearest_board_position_for_local_position(local_pos)
	if !_is_valid_position(nearest_pos):
		return base_z_index

	var nearest_center: Vector2 = get_position_local(nearest_pos)
	var front_side: bool = (local_pos.y - nearest_center.y) * float(view_color) >= 0.0
	var side_offset: int = route_z_front_offset if front_side else route_z_back_offset
	return base_z_index + get_depth_z_index(nearest_pos) + side_offset

func get_respawn_z_index_for_local_position(local_pos: Vector2, respawn_pos: Vector2) -> int:
	var base_z_index: int = int(pieces_node.z_index) if pieces_node != null else 0
	if _is_valid_position(respawn_pos):
		var nearest_pos: Vector2 = get_nearest_board_position_for_local_position(local_pos)
		if nearest_pos == respawn_pos:
			return base_z_index + get_depth_z_index(respawn_pos)
	return get_z_index_for_local_position(local_pos)

func get_nearest_board_position_for_local_position(local_pos: Vector2) -> Vector2:
	var nearest_pos: Vector2 = invalid_board_pos
	var nearest_distance: float = INF
	for row in range(board_size):
		for col in range(board_size):
			var board_pos := Vector2(row, col)
			var distance: float = local_pos.distance_squared_to(get_position_local(board_pos))
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_pos = board_pos
	return nearest_pos

func get_position_local(board_pos: Vector2, clamp_to_board: bool = true) -> Vector2:
	if geometry == null:
		return Vector2.ZERO
	return geometry.get_position_local(board_pos, clamp_to_board)

func get_visual_transform_for_texture(texture_value: Texture2D, board_pos: Vector2) -> Dictionary:
	if piece_visuals == null:
		return {"scale": Vector2.ONE, "offset": Vector2.ZERO}
	return piece_visuals.get_visual_transform_for_texture(texture_value, board_pos)

func apply_piece_visual_size(holder: Sprite2D, board_pos: Vector2) -> void:
	if piece_visuals != null:
		piece_visuals.apply_visual_size(holder, board_pos)

func get_perspective_scale(board_pos: Vector2) -> float:
	if piece_visuals == null:
		return 1.0
	return piece_visuals.get_perspective_scale(board_pos)

func get_depth_z_index(board_pos: Vector2) -> int:
	if piece_visuals != null:
		return piece_visuals.get_depth_z_index(board_pos)
	if view_color < 0:
		return int(board_pos.x)
	return board_size - 1 - int(board_pos.x)

func is_route_cell_blocked(board_pos: Vector2, source_pos: Vector2, respawn_pos: Vector2) -> bool:
	if route_cell_blocked_provider.is_valid():
		return bool(route_cell_blocked_provider.call(board_pos, source_pos, respawn_pos))
	if !_is_valid_position(board_pos):
		return true
	return board_pos != source_pos and board_pos != respawn_pos

func get_player_id_for_color(piece_color: int) -> int:
	if player_id_for_color_provider.is_valid():
		return int(player_id_for_color_provider.call(piece_color))
	return 0 if piece_color > 0 else 1

func tween_respawn_finish_callback(tween: Tween, respawn_pos: Vector2) -> void:
	if tween != null and finish_respawn_fragment_callback.is_valid():
		tween.tween_callback(finish_respawn_fragment_callback.bind(respawn_pos))

func create_animation_tween() -> Tween:
	if tween_owner == null or !is_instance_valid(tween_owner):
		return null
	return tween_owner.create_tween()

func enable_antialiasing(canvas_item: Object) -> void:
	if antialias_provider.is_valid():
		antialias_provider.call(canvas_item)

func _is_valid_position(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x < board_size and pos.y >= 0 and pos.y < board_size

func value_to_vector2(value, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		var vector_value: Vector2i = value
		return Vector2(vector_value.x, vector_value.y)
	if value is Array:
		var array_value: Array = value
		if array_value.size() >= 2:
			return Vector2(float(array_value[0]), float(array_value[1]))
	if value is Dictionary:
		var dict_value: Dictionary = value
		if dict_value.has("x") && dict_value.has("y"):
			return Vector2(float(dict_value.x), float(dict_value.y))
	return fallback
