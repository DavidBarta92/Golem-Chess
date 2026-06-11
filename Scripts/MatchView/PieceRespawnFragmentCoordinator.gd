extends RefCounted

var match_board
var invalid_board_pos: Vector2 = Vector2(-1, -1)

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)

func prepare_piece_shatter_respawn_reveals(animations: Array[Dictionary]) -> void:
	for animation: Dictionary in animations:
		var respawn_pos: Vector2 = match_board.value_to_vector2(animation.get("respawn_pos", invalid_board_pos), invalid_board_pos)
		var fragment_group: String = str(animation.get("fragment_group", match_board.PIECE_SHATTER_FRAGMENT_GROUP_NONE))
		begin_piece_shatter_respawn_reveal(respawn_pos, fragment_group)

func prepare_pending_edge_respawn_arrival_reveals(animations: Array[Dictionary]) -> void:
	for animation: Dictionary in animations:
		var respawn_pos: Vector2 = match_board.value_to_vector2(animation.get("respawn_pos", invalid_board_pos), invalid_board_pos)
		var fragment_group: String = str(animation.get("fragment_group", match_board.PIECE_SHATTER_FRAGMENT_GROUP_BOTTOM))
		begin_piece_shatter_respawn_reveal(respawn_pos, fragment_group)

func is_piece_shatter_respawn_reveal_pending(board_pos: Vector2) -> bool:
	return match_board.pending_piece_shatter_respawn_reveal_counts.has(board_pos)

func has_piece_shatter_respawn_fragment_markers(board_pos: Vector2) -> bool:
	return match_board.respawn_piece_shatter_fragment_markers.has(board_pos)

func should_hide_piece_for_shatter_respawn(board_pos: Vector2) -> bool:
	return is_piece_shatter_respawn_reveal_pending(board_pos) or has_piece_shatter_respawn_fragment_markers(board_pos)

func add_piece_shatter_respawn_fragment_marker(respawn_pos: Vector2, fragment: Sprite2D) -> void:
	if !match_board.is_valid_position(respawn_pos) or fragment == null or !is_instance_valid(fragment):
		return

	var markers: Array = []
	if match_board.respawn_piece_shatter_fragment_markers.has(respawn_pos):
		markers = match_board.respawn_piece_shatter_fragment_markers[respawn_pos]
	markers.append(fragment)
	match_board.respawn_piece_shatter_fragment_markers[respawn_pos] = markers

func clear_piece_shatter_respawn_fragment_markers(respawn_pos: Vector2) -> void:
	if !match_board.respawn_piece_shatter_fragment_markers.has(respawn_pos):
		return

	var markers: Array = match_board.respawn_piece_shatter_fragment_markers[respawn_pos]
	for marker in markers:
		var marker_node: Node = marker as Node
		if marker_node != null and is_instance_valid(marker_node):
			marker_node.queue_free()
	match_board.respawn_piece_shatter_fragment_markers.erase(respawn_pos)

func get_piece_shatter_return_fragment_count(fragment_group: String) -> int:
	return mini(get_piece_shatter_fragment_textures(fragment_group).size(), maxi(0, match_board.piece_shatter_returning_debris_count))

func begin_piece_shatter_respawn_reveal(respawn_pos: Vector2, fragment_group: String) -> int:
	if !match_board.is_valid_position(respawn_pos):
		return 0

	var return_count: int = get_piece_shatter_return_fragment_count(fragment_group)
	if return_count <= 0:
		return 0

	if !match_board.pending_piece_shatter_respawn_reveal_counts.has(respawn_pos):
		match_board.active_piece_shatter_animation_count += 1
	match_board.pending_piece_shatter_respawn_reveal_counts[respawn_pos] = maxi(return_count, int(match_board.pending_piece_shatter_respawn_reveal_counts.get(respawn_pos, 0)))
	match_board.pending_piece_shatter_respawn_reveal_groups[respawn_pos] = fragment_group

	var holder: Sprite2D = match_board.get_piece_holder_at(respawn_pos)
	if holder != null:
		match_board.refresh_piece_holder_visual(holder, respawn_pos)
	return return_count

func adjust_piece_shatter_respawn_reveal_count(respawn_pos: Vector2, fragment_count: int) -> void:
	if !match_board.pending_piece_shatter_respawn_reveal_counts.has(respawn_pos):
		return
	if fragment_count <= 0:
		cancel_piece_shatter_respawn_reveal(respawn_pos)
		return
	match_board.pending_piece_shatter_respawn_reveal_counts[respawn_pos] = fragment_count

func cancel_piece_shatter_respawn_reveal(respawn_pos: Vector2) -> void:
	if match_board.pending_piece_shatter_respawn_reveal_counts.has(respawn_pos):
		match_board.pending_piece_shatter_respawn_reveal_counts.erase(respawn_pos)
		match_board.pending_piece_shatter_respawn_reveal_groups.erase(respawn_pos)
		match_board.active_piece_shatter_animation_count = maxi(0, match_board.active_piece_shatter_animation_count - 1)
	refresh_piece_shatter_respawn_piece_visibility(respawn_pos)

func finish_piece_shatter_respawn_fragment(respawn_pos: Vector2) -> void:
	if !match_board.pending_piece_shatter_respawn_reveal_counts.has(respawn_pos):
		return

	var fragment_group: String = str(match_board.pending_piece_shatter_respawn_reveal_groups.get(respawn_pos, match_board.PIECE_SHATTER_FRAGMENT_GROUP_NONE))
	var remaining_count: int = maxi(0, int(match_board.pending_piece_shatter_respawn_reveal_counts.get(respawn_pos, 0)) - 1)
	if remaining_count > 0:
		match_board.pending_piece_shatter_respawn_reveal_counts[respawn_pos] = remaining_count
		return

	match_board.pending_piece_shatter_respawn_reveal_counts.erase(respawn_pos)
	match_board.pending_piece_shatter_respawn_reveal_groups.erase(respawn_pos)
	match_board.active_piece_shatter_animation_count = maxi(0, match_board.active_piece_shatter_animation_count - 1)
	if fragment_group == match_board.PIECE_SHATTER_FRAGMENT_GROUP_BOTTOM:
		refresh_piece_shatter_respawn_piece_visibility(respawn_pos)
		return

	if fragment_group == match_board.PIECE_SHATTER_FRAGMENT_GROUP_TOP:
		clear_piece_shatter_respawn_fragment_markers(respawn_pos)
	reveal_piece_shatter_respawn_piece(respawn_pos)

func refresh_piece_shatter_respawn_piece_visibility(respawn_pos: Vector2) -> void:
	if !match_board.is_valid_position(respawn_pos):
		return
	var holder: Sprite2D = match_board.get_piece_holder_at(respawn_pos)
	if holder != null:
		match_board.refresh_piece_holder_visual(holder, respawn_pos)
		return
	match_board.display_board()

func reveal_piece_shatter_respawn_piece(respawn_pos: Vector2) -> void:
	if !match_board.is_valid_position(respawn_pos):
		return
	var holder: Sprite2D = match_board.get_piece_holder_at(respawn_pos)
	if holder != null:
		match_board.refresh_piece_holder_visual(holder, respawn_pos)
		return
	match_board.display_board()

func play_piece_shatter_animations(animations: Array[Dictionary]) -> void:
	for animation: Dictionary in animations:
		var source_pos: Vector2 = match_board.value_to_vector2(animation.get("source_pos", invalid_board_pos), invalid_board_pos)
		var respawn_pos: Vector2 = match_board.value_to_vector2(animation.get("respawn_pos", invalid_board_pos), invalid_board_pos)
		var piece_color: int = int(animation.get("piece_color", 0))
		var fragment_group: String = str(animation.get("fragment_group", match_board.PIECE_SHATTER_FRAGMENT_GROUP_NONE))
		play_piece_shatter_animation(source_pos, respawn_pos, piece_color, fragment_group)

func play_piece_shatter_animation(source_pos: Vector2, respawn_pos: Vector2, piece_color: int, fragment_group: String = "") -> void:
	if match_board.should_skip_visual_animations():
		return
	if piece_color == 0:
		return
	if !match_board.is_valid_position(source_pos):
		return
	if match_board.piece_effects_node == null or !is_instance_valid(match_board.piece_effects_node):
		match_board.create_piece_effects_node()
	if match_board.piece_effects_node == null:
		return

	play_capture_flash_animation(source_pos)

	var resolved_fragment_group: String = fragment_group
	if resolved_fragment_group.is_empty():
		resolved_fragment_group = match_board.PIECE_SHATTER_FRAGMENT_GROUP_NONE
	var fragment_textures: Array[Texture2D] = get_piece_shatter_fragment_textures(resolved_fragment_group)
	var returns_to_pending_edge: bool = resolved_fragment_group == match_board.PIECE_SHATTER_FRAGMENT_GROUP_PENDING
	var return_count: int = get_piece_shatter_return_fragment_count(resolved_fragment_group) if returns_to_pending_edge else begin_piece_shatter_respawn_reveal(respawn_pos, resolved_fragment_group)
	var can_return_fragments: bool = (match_board.is_valid_position(respawn_pos) or returns_to_pending_edge) and !fragment_textures.is_empty() and return_count > 0
	var debris_count: int = maxi(0, match_board.piece_shatter_debris_count)
	if debris_count <= 0 and !can_return_fragments:
		return

	for debris_index in range(debris_count):
		var shard: Polygon2D = match_board.get_piece_shatter_animator().create_shard(source_pos, piece_color, debris_index)
		if shard == null:
			continue

		var scatter_target: Vector2 = match_board.get_piece_shatter_animator().get_scatter_target(source_pos, debris_index)
		match_board.get_piece_shatter_animator().animate_shard(shard, scatter_target, invalid_board_pos, false)

	if returns_to_pending_edge and can_return_fragments:
		play_piece_shatter_pending_edge_fragments(source_pos, piece_color, fragment_textures)
	elif can_return_fragments:
		play_piece_shatter_return_fragments(source_pos, respawn_pos, fragment_textures, resolved_fragment_group)

func play_capture_flash_animation(board_pos: Vector2) -> void:
	if !match_board.is_valid_position(board_pos):
		return
	if match_board.piece_effects_node == null or !is_instance_valid(match_board.piece_effects_node):
		match_board.create_piece_effects_node()
	if match_board.piece_effects_node == null:
		return
	match_board.get_piece_effect_animator().play_capture_flash(board_pos)

func get_piece_shatter_fragment_textures(fragment_group: String) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	match fragment_group:
		match_board.PIECE_SHATTER_FRAGMENT_GROUP_BOTTOM:
			textures.append(match_board.GOLEM_FRAGMENT_BOTTOM_LEFT_TEXTURE)
			textures.append(match_board.GOLEM_FRAGMENT_BOTTOM_CENTER_TEXTURE)
			textures.append(match_board.GOLEM_FRAGMENT_BOTTOM_RIGHT_TEXTURE)
		match_board.PIECE_SHATTER_FRAGMENT_GROUP_TOP:
			textures.append(match_board.GOLEM_FRAGMENT_TOP_LEFT_TEXTURE)
			textures.append(match_board.GOLEM_FRAGMENT_TOP_CENTER_TEXTURE)
			textures.append(match_board.GOLEM_FRAGMENT_TOP_RIGHT_TEXTURE)
		match_board.PIECE_SHATTER_FRAGMENT_GROUP_PENDING:
			textures.append(match_board.GOLEM_FRAGMENT_BOTTOM_LEFT_TEXTURE)
			textures.append(match_board.GOLEM_FRAGMENT_BOTTOM_CENTER_TEXTURE)
			textures.append(match_board.GOLEM_FRAGMENT_BOTTOM_RIGHT_TEXTURE)
	return textures

func play_piece_shatter_return_fragments(source_pos: Vector2, respawn_pos: Vector2, fragment_textures: Array[Texture2D], fragment_group: String) -> void:
	var return_count: int = mini(fragment_textures.size(), maxi(0, match_board.piece_shatter_returning_debris_count))
	var created_count: int = 0
	for fragment_index in range(return_count):
		var fragment_texture: Texture2D = fragment_textures[fragment_index]
		var fragment: Sprite2D = match_board.get_piece_shatter_animator().create_fragment(source_pos, fragment_texture, fragment_index)
		if fragment == null:
			continue

		created_count += 1
		if fragment_group == match_board.PIECE_SHATTER_FRAGMENT_GROUP_BOTTOM:
			add_piece_shatter_respawn_fragment_marker(respawn_pos, fragment)
		var scatter_target: Vector2 = match_board.get_piece_shatter_animator().get_scatter_target(source_pos, match_board.piece_shatter_debris_count + fragment_index)
		match_board.get_piece_shatter_animator().animate_fragment(fragment, scatter_target, source_pos, respawn_pos, fragment_group, fragment_index)
	adjust_piece_shatter_respawn_reveal_count(respawn_pos, created_count)

func play_piece_shatter_pending_edge_fragments(source_pos: Vector2, piece_color: int, fragment_textures: Array[Texture2D]) -> void:
	var return_count: int = mini(fragment_textures.size(), maxi(0, match_board.piece_shatter_returning_debris_count))
	for fragment_index in range(return_count):
		var fragment_texture: Texture2D = fragment_textures[fragment_index]
		var fragment: Sprite2D = match_board.get_piece_shatter_animator().create_fragment(source_pos, fragment_texture, fragment_index)
		if fragment == null:
			continue

		add_pending_edge_respawn_fragment_marker(piece_color, fragment)
		var scatter_target: Vector2 = match_board.get_piece_shatter_animator().get_scatter_target(source_pos, match_board.piece_shatter_debris_count + fragment_index)
		match_board.get_piece_shatter_animator().animate_pending_edge_fragment(fragment, scatter_target, source_pos, piece_color, fragment_index)

func add_pending_edge_respawn_fragment_marker(piece_color: int, fragment: Sprite2D) -> void:
	if piece_color == 0 or fragment == null or !is_instance_valid(fragment):
		return

	var key: int = get_pending_edge_respawn_key(piece_color)
	var markers: Array = match_board.pending_edge_respawn_fragment_markers.get(key, [])
	markers.append(fragment)
	match_board.pending_edge_respawn_fragment_markers[key] = markers

func take_pending_edge_respawn_fragment_markers(piece_color: int) -> Array[Sprite2D]:
	var markers: Array[Sprite2D] = []
	var key: int = get_pending_edge_respawn_key(piece_color)
	var stored_markers: Array = match_board.pending_edge_respawn_fragment_markers.get(key, [])
	for marker_value in stored_markers:
		var marker: Sprite2D = marker_value as Sprite2D
		if marker != null and is_instance_valid(marker):
			markers.append(marker)
	match_board.pending_edge_respawn_fragment_markers.erase(key)
	return markers

func get_pending_edge_respawn_key(piece_color: int) -> int:
	return match_board.get_player_id_for_color(piece_color)

func play_pending_edge_respawn_arrival_animations(animations: Array[Dictionary]) -> void:
	for animation: Dictionary in animations:
		var respawn_pos: Vector2 = match_board.value_to_vector2(animation.get("respawn_pos", invalid_board_pos), invalid_board_pos)
		var piece_color: int = int(animation.get("piece_color", 0))
		var fragment_group: String = str(animation.get("fragment_group", match_board.PIECE_SHATTER_FRAGMENT_GROUP_BOTTOM))
		if !match_board.is_valid_position(respawn_pos) or piece_color == 0:
			continue

		var fragments: Array[Sprite2D] = take_pending_edge_respawn_fragment_markers(piece_color)
		if fragments.is_empty():
			fragments = create_pending_edge_respawn_fragment_markers(piece_color)
		if fragments.is_empty():
			cancel_piece_shatter_respawn_reveal(respawn_pos)
			continue

		var created_count: int = 0
		for fragment_index in range(fragments.size()):
			var fragment: Sprite2D = fragments[fragment_index]
			if fragment == null or !is_instance_valid(fragment):
				continue
			created_count += 1
			add_piece_shatter_respawn_fragment_marker(respawn_pos, fragment)
			match_board.get_piece_shatter_animator().animate_pending_edge_arrival_fragment(fragment, respawn_pos, fragment_group, fragment_index)
		adjust_piece_shatter_respawn_reveal_count(respawn_pos, created_count)

func create_pending_edge_respawn_fragment_markers(piece_color: int) -> Array[Sprite2D]:
	if match_board.piece_effects_node == null or !is_instance_valid(match_board.piece_effects_node):
		match_board.create_piece_effects_node()
	if match_board.piece_effects_node == null:
		return []

	var fragment_textures: Array[Texture2D] = get_piece_shatter_fragment_textures(match_board.PIECE_SHATTER_FRAGMENT_GROUP_PENDING)
	var return_count: int = mini(fragment_textures.size(), maxi(0, match_board.piece_shatter_returning_debris_count))
	return match_board.get_piece_shatter_animator().create_pending_edge_fragment_markers(piece_color, fragment_textures, return_count)

func is_piece_shatter_route_cell_blocked(board_pos: Vector2, source_pos: Vector2, respawn_pos: Vector2) -> bool:
	if !match_board.is_valid_position(board_pos):
		return true
	if board_pos == source_pos or board_pos == respawn_pos:
		return false
	if match_board.piece_objects.has(board_pos):
		return true
	if int(match_board.board[int(board_pos.x)][int(board_pos.y)]) != 0:
		return true
	if has_piece_shatter_respawn_fragment_markers(board_pos):
		return true
	return false
