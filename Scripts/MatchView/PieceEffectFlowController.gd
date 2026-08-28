extends RefCounted

var match_board
var invalid_board_pos: Vector2 = Vector2(-1, -1)

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)

func play_state_attach_animations(animations: Array[Dictionary]) -> void:
	if match_board == null:
		return

	match_board.begin_visual_process(match_board.VISUAL_PROCESS_STATE_STAMP_ATTACH)
	for animation: Dictionary in animations:
		var board_pos: Vector2 = match_board.value_to_vector2(animation.get("position", invalid_board_pos), invalid_board_pos)
		var stamp: Stamp = animation.get("stamp", null) as Stamp
		var start_texture: Texture2D = animation.get("start_texture", null) as Texture2D
		var hide_after_attach: bool = bool(animation.get("hide_after_attach", false))
		if !match_board.is_valid_position(board_pos) or stamp == null:
			match_board.finish_stamp_attach_process(board_pos)
			continue

		if hide_after_attach:
			var piece_color: int = int(animation.get("piece_color", 0))
			if piece_color == 0:
				piece_color = match_board.get_color_for_player_id(1 - match_board.get_own_player_id())
			await play_hidden_piece_invisibility_attach_animation(board_pos, stamp, start_texture, piece_color)
		else:
			await play_piece_stamp_attach_animation(board_pos, stamp, start_texture)
		match_board.finish_stamp_attach_process(board_pos)
	match_board.finish_visual_process(match_board.VISUAL_PROCESS_STATE_STAMP_ATTACH)

func play_piece_stamp_attach_animation(piece_position: Vector2, stamp: Stamp, start_texture: Texture2D = null) -> void:
	if match_board == null or match_board.should_skip_visual_animations() or !match_board.is_inside_tree():
		return
	if stamp == null or !match_board.piece_objects.has(piece_position):
		return

	var piece: Piece = match_board.piece_objects[piece_position] as Piece
	if piece == null:
		return

	var attached_texture: Texture2D = match_board.get_piece_texture_resolver().get_stamp_piece_texture_for_color(stamp, piece.color)
	if attached_texture == null:
		return

	var holder: Sprite2D = match_board.get_piece_holder_at(piece_position)
	if holder == null or holder.texture == null:
		return

	if start_texture != null and holder.texture != start_texture:
		holder.texture = start_texture
		match_board.refresh_piece_holder_visual(holder, piece_position)

	SFXManager.play("attach_stamp")
	await match_board.get_piece_effect_animator().play_attach_sequence(holder, piece_position, attached_texture, {
		"post_morph_callback": Callable(self, "apply_visible_piece_attach_morph_result").bind(piece_position, attached_texture),
		"disable_holder_occluder": true,
	})

func apply_visible_piece_attach_morph_result(holder: Sprite2D, piece_position: Vector2, attached_texture: Texture2D) -> void:
	if match_board == null or holder == null or !is_instance_valid(holder):
		return

	holder.texture = attached_texture
	match_board.refresh_piece_holder_visual(holder, piece_position)

func play_hidden_piece_invisibility_attach_animation(piece_position: Vector2, stamp: Stamp, start_texture: Texture2D, piece_color: int) -> void:
	if match_board == null or match_board.should_skip_visual_animations() or !match_board.is_inside_tree():
		return
	if stamp == null or !match_board.is_valid_position(piece_position):
		return
	if start_texture == null:
		start_texture = match_board.get_piece_texture_resolver().get_default_piece_texture(piece_color)
	if start_texture == null:
		return

	var holder: Sprite2D = create_hidden_invisibility_animation_holder(piece_position, start_texture)
	if holder == null:
		return

	var attached_texture: Texture2D = match_board.get_piece_texture_resolver().get_stamp_piece_texture_for_color(stamp, piece_color)
	if attached_texture == null:
		attached_texture = start_texture

	SFXManager.play("attach_stamp")
	var completed: bool = await match_board.get_piece_effect_animator().play_attach_sequence(holder, piece_position, attached_texture, {
		"post_morph_callback": Callable(self, "apply_hidden_piece_attach_morph_result").bind(piece_position, attached_texture),
		"disable_holder_occluder": false,
	})
	if !completed:
		return

	SFXManager.play("invisibility_effect")
	await match_board.get_piece_effect_animator().play_invisibility_exit(holder)

func apply_hidden_piece_attach_morph_result(holder: Sprite2D, piece_position: Vector2, attached_texture: Texture2D) -> void:
	if match_board == null or holder == null or !is_instance_valid(holder):
		return

	holder.texture = attached_texture
	match_board.get_piece_visuals().apply_visual_size(holder, piece_position)

func play_local_move_transition(move_context: Dictionary) -> void:
	if match_board == null:
		return

	var start_pos: Vector2 = move_context.get("start_pos", invalid_board_pos)
	var end_pos: Vector2 = move_context.get("end_pos", invalid_board_pos)
	var moving_start_texture: Texture2D = move_context.get("moving_start_texture", null) as Texture2D
	var moving_piece_visible_to_enemy: bool = bool(move_context.get("moving_piece_visible_to_enemy", true))
	var should_play_capture_shatter: bool = bool(move_context.get("should_play_capture_shatter", false))
	var captured_start_texture: Texture2D = move_context.get("captured_start_texture", null) as Texture2D

	match_board.display_board()
	var capture_placeholder: Sprite2D = create_piece_move_capture_placeholder(end_pos, captured_start_texture) if should_play_capture_shatter else null
	var capture_impact_callback: Callable = Callable()
	if should_play_capture_shatter:
		var captured_piece: Piece = move_context.get("captured_piece", null) as Piece
		var captured_color: int = captured_piece.color if captured_piece != null else 0
		var shatter_respawn_pos: Vector2 = match_board.value_to_vector2(move_context.get("shatter_respawn_pos", invalid_board_pos), invalid_board_pos)
		var shatter_fragment_group: String = str(move_context.get("shatter_fragment_group", match_board.PIECE_SHATTER_FRAGMENT_GROUP_NONE))
		var capturing_cast: String = get_capturing_cast_sound_name(end_pos)
		capture_impact_callback = func() -> void:
			if is_instance_valid(capture_placeholder):
				capture_placeholder.queue_free()
			match_board.get_piece_respawn_fragment_coordinator().play_piece_shatter_animation(end_pos, shatter_respawn_pos, captured_color, shatter_fragment_group)
			if !capturing_cast.is_empty():
				SFXManager.play(capturing_cast)
			SFXManager.play("piece_captured")
	await play_piece_move_animation(start_pos, end_pos, moving_start_texture, moving_piece_visible_to_enemy, capture_impact_callback)
	if is_instance_valid(capture_placeholder):
		capture_placeholder.queue_free()
	var pending_respawn_arrivals: Array = move_context.get("pending_respawn_arrivals", [])
	if !pending_respawn_arrivals.is_empty():
		match_board.get_piece_respawn_fragment_coordinator().play_pending_edge_respawn_arrival_animations(pending_respawn_arrivals)
	match_board.call_deferred("play_pending_piece_revert_animations")

func play_state_piece_move_animation(state_piece_move_animation: Dictionary, state_piece_shatter_animations: Array) -> void:
	if match_board == null:
		return

	var move_to_pos: Vector2 = match_board.value_to_vector2(state_piece_move_animation.get("to", invalid_board_pos), invalid_board_pos)
	var move_from_pos: Vector2 = match_board.value_to_vector2(state_piece_move_animation.get("from", invalid_board_pos), invalid_board_pos)
	var move_piece_color: int = int(state_piece_move_animation.get("piece_color", 0))
	var capture_placeholder: Sprite2D = create_piece_move_capture_placeholder(
		move_to_pos,
		state_piece_move_animation.get("captured_texture", null) as Texture2D
	)
	if capture_placeholder != null and bool(state_piece_move_animation.get("captured_reveal_from_invisibility", false)):
		play_capture_invisibility_reveal(capture_placeholder)

	var capture_shatter_animation_index: int = get_piece_shatter_animation_index_for_source(state_piece_shatter_animations, move_to_pos) if capture_placeholder != null else -1
	var capture_shatter_animation: Dictionary = state_piece_shatter_animations[capture_shatter_animation_index] if capture_shatter_animation_index >= 0 else {}
	var capture_impact_callback: Callable = Callable()
	if capture_placeholder != null:
		var capturing_cast: String = get_capturing_cast_sound_name(move_to_pos)
		capture_impact_callback = func() -> void:
			if is_instance_valid(capture_placeholder):
				capture_placeholder.queue_free()
			if !capture_shatter_animation.is_empty():
				remove_piece_shatter_animation_from_list(state_piece_shatter_animations, capture_shatter_animation, capture_shatter_animation_index)
				match_board.get_piece_respawn_fragment_coordinator().play_piece_shatter_animation(
					move_to_pos,
					match_board.value_to_vector2(capture_shatter_animation.get("respawn_pos", invalid_board_pos), invalid_board_pos),
					int(capture_shatter_animation.get("piece_color", 0)),
					str(capture_shatter_animation.get("fragment_group", match_board.PIECE_SHATTER_FRAGMENT_GROUP_NONE))
				)
			if !capturing_cast.is_empty():
				SFXManager.play(capturing_cast)
			SFXManager.play("piece_captured")

	await play_piece_move_animation(
		move_from_pos,
		move_to_pos,
		state_piece_move_animation.get("start_texture", null) as Texture2D,
		bool(state_piece_move_animation.get("visible_to_enemy", true)),
		capture_impact_callback
	)
	if is_instance_valid(capture_placeholder):
		capture_placeholder.queue_free()
	if move_piece_color != 0:
		match_board.piece_moved.emit(move_from_pos, move_to_pos, move_piece_color)

func should_play_piece_move_animation(from_pos: Vector2, to_pos: Vector2, visible_to_enemy: bool = true) -> bool:
	if match_board == null:
		return false
	if !match_board.piece_move_animation_enabled or match_board.should_skip_visual_animations() or !match_board.is_inside_tree():
		return false
	if !match_board.is_valid_position(from_pos) or !match_board.is_valid_position(to_pos):
		return false
	return from_pos != to_pos

func play_piece_move_animation(
	from_pos: Vector2,
	to_pos: Vector2,
	start_texture: Texture2D = null,
	visible_to_enemy: bool = true,
	capture_impact_callback: Callable = Callable()
) -> void:
	if !should_play_piece_move_animation(from_pos, to_pos, visible_to_enemy):
		return

	var holder: Sprite2D = match_board.get_piece_holder_at(to_pos)
	if holder == null or !is_instance_valid(holder) or holder.texture == null:
		return

	match_board.begin_visual_process(match_board.VISUAL_PROCESS_PIECE_MOVE)
	var end_texture: Texture2D = holder.texture
	var display_texture: Texture2D = start_texture if start_texture != null else end_texture
	var start_transform: Dictionary = match_board.get_piece_visuals().get_visual_transform_for_texture(display_texture, from_pos)
	var end_transform: Dictionary = match_board.get_piece_visuals().get_visual_transform_for_texture(end_texture, to_pos)
	var start_scale: Vector2 = start_transform.get("scale", holder.scale)
	var end_scale: Vector2 = end_transform.get("scale", holder.scale)
	var start_offset: Vector2 = start_transform.get("offset", holder.offset)
	var end_offset: Vector2 = end_transform.get("offset", holder.offset)

	holder.texture = display_texture
	holder.position = match_board.get_board_position_local_position(from_pos)
	holder.scale = start_scale
	holder.offset = start_offset
	match_board.get_piece_visuals().remove_shadow(holder)
	match_board.get_piece_visuals().remove_light_occluder(holder)
	SFXManager.play("piece_lifted")
	var landed_callback: Callable = func() -> void:
		SFXManager.play("piece_placed")
	await match_board.get_piece_move_animator().play_move_sequence(
		holder,
		from_pos,
		to_pos,
		start_scale,
		end_scale,
		start_offset,
		end_offset,
		capture_impact_callback,
		landed_callback
	)

	if is_instance_valid(holder):
		holder.texture = end_texture
		match_board.refresh_piece_holder_visual(holder, to_pos)
	match_board.finish_visual_process(match_board.VISUAL_PROCESS_PIECE_MOVE)

func create_piece_move_capture_placeholder(board_pos: Vector2, texture_value: Texture2D) -> Sprite2D:
	if match_board == null or texture_value == null or !match_board.is_valid_position(board_pos):
		return null

	var placeholder: Sprite2D = create_piece_effect_holder(board_pos, texture_value, "PieceMoveCaptureTarget")
	if placeholder == null:
		return null
	placeholder.z_index = match_board.pieces_node.z_index + match_board.get_piece_visuals().get_depth_z_index(board_pos)
	return placeholder

func play_capture_invisibility_reveal(capture_placeholder: Sprite2D) -> void:
	if match_board != null:
		match_board.get_piece_effect_animator().play_invisibility_reveal(capture_placeholder)

func create_hidden_invisibility_animation_holder(piece_position: Vector2, start_texture: Texture2D) -> Sprite2D:
	return create_piece_effect_holder(piece_position, start_texture, "HiddenInvisibilityPiece")

func create_piece_effect_holder(piece_position: Vector2, texture_value: Texture2D, holder_name: String = "PieceEffect") -> Sprite2D:
	if match_board == null or texture_value == null or !match_board.is_valid_position(piece_position):
		return null
	if match_board.piece_effects_node == null or !is_instance_valid(match_board.piece_effects_node):
		match_board.create_piece_effects_node()
	if match_board.piece_effects_node == null:
		return null
	return match_board.get_piece_effect_animator().create_effect_holder(piece_position, texture_value, holder_name)

func get_piece_shatter_animation_index_for_source(animations: Array, source_pos: Vector2) -> int:
	for index in range(animations.size()):
		var animation: Dictionary = animations[index]
		var animation_source_pos: Vector2 = match_board.value_to_vector2(animation.get("source_pos", invalid_board_pos), invalid_board_pos)
		if animation_source_pos != source_pos:
			continue
		return index
	return -1

func remove_piece_shatter_animation_from_list(animations: Array, animation: Dictionary, preferred_index: int) -> void:
	if preferred_index >= 0 and preferred_index < animations.size() and animations[preferred_index] == animation:
		animations.remove_at(preferred_index)
		return
	animations.erase(animation)

func get_capturing_cast_sound_name(capturing_piece_pos: Vector2) -> String:
	if match_board == null:
		return ""
	var capturing_piece: Piece = match_board.piece_objects.get(capturing_piece_pos, null) as Piece
	if capturing_piece == null or capturing_piece.attached_stamp == null:
		return ""
	return "%s_capture" % capturing_piece.attached_stamp.Set.to_lower()
