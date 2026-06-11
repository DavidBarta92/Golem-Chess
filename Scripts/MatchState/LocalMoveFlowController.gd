extends RefCounted

var match_board
var invalid_board_pos: Vector2 = Vector2(-1, -1)
var fragment_group_none: String = ""

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)
	fragment_group_none = str(config.get("fragment_group_none", fragment_group_none))

func set_move(start_pos: Vector2, end_pos: Vector2) -> void:
	if match_board == null or match_board.game_over:
		return

	DebugLog.info("set_move() start: white=%s start=%s end=%s piece=%s" % [
		match_board.white,
		start_pos,
		end_pos,
		match_board.board[start_pos.x][start_pos.y],
	])
	var move_context: Dictionary = create_local_move_context(start_pos, end_pos)
	apply_local_move_state(move_context)

	if finish_local_move_if_winning(move_context):
		await play_local_move_transition(move_context)
		match_board.finish_game(int(move_context.get("winner_color", 0)))
		return

	apply_local_move_post_move_effects(move_context)
	if match_board.game_over:
		await play_local_move_transition(move_context)
		return

	resolve_local_move_capture_respawn(move_context)
	finish_local_move_state_updates(move_context)
	DebugLog.info("set_move() end: waiting for END TURN")

	await play_local_move_transition(move_context)
	restore_local_move_selection(move_context)

func create_local_move_context(start_pos: Vector2, end_pos: Vector2) -> Dictionary:
	var start_piece: Piece = match_board.piece_objects[start_pos] as Piece if match_board.piece_objects.has(start_pos) else null
	var captured_piece_before_move: Piece = match_board.piece_objects[end_pos] as Piece if match_board.piece_objects.has(end_pos) else null
	return {
		"start_pos": start_pos,
		"end_pos": end_pos,
		"moving_start_texture": match_board.get_piece_visual_texture(start_piece) if start_piece != null else null,
		"captured_start_texture": match_board.get_piece_visual_texture(captured_piece_before_move) if captured_piece_before_move != null else null,
		"pending_respawn_arrivals": [],
		"should_play_capture_shatter": false,
		"shatter_respawn_pos": invalid_board_pos,
		"shatter_fragment_group": fragment_group_none,
		"winner_color": 0,
	}

func apply_local_move_state(move_context: Dictionary) -> void:
	var start_pos: Vector2 = move_context.get("start_pos", invalid_board_pos)
	var end_pos: Vector2 = move_context.get("end_pos", invalid_board_pos)
	var move_state: Dictionary = match_board.get_local_state_mutator().apply_piece_move(start_pos, end_pos)
	var moving_color: int = int(move_state.get("moving_color", 0))
	var captured_piece: Piece = move_state.get("captured_piece", null) as Piece
	var moving_piece_visible_to_enemy: bool = bool(move_state.get("moving_piece_visible_to_enemy", true))

	if bool(move_state.get("captured_nexus", false)):
		return_captured_nexus_card_to_deck(captured_piece)
	if captured_piece != null:
		captured_piece.detach_card()

	match_board.current_last_move = move_state.get("last_move", {})
	move_context["moving_color"] = moving_color
	move_context["captured_piece"] = captured_piece
	move_context["moving_piece_visible_to_enemy"] = moving_piece_visible_to_enemy
	move_context["winner_color"] = int(move_state.get("winner_color", 0))
	match_board.piece_moved.emit(start_pos, end_pos, moving_color)

func finish_local_move_if_winning(move_context: Dictionary) -> bool:
	return int(move_context.get("winner_color", 0)) != 0

func apply_local_move_post_move_effects(move_context: Dictionary) -> void:
	var end_pos: Vector2 = move_context.get("end_pos", invalid_board_pos)
	var moving_piece: Piece = match_board.piece_objects[end_pos] as Piece if match_board.piece_objects.has(end_pos) else null
	var pending_respawn_arrivals: Array = move_context.get("pending_respawn_arrivals", [])
	if moving_piece != null and !GameController.current_game_host:
		pending_respawn_arrivals.append_array(match_board.get_local_state_mutator().apply_card_effect_trigger(CardEffect.TRIGGER_ON_MOVE, end_pos, moving_piece, moving_piece.attached_card))
	consume_moved_piece_duration_locally(moving_piece, end_pos)
	move_context["pending_respawn_arrivals"] = pending_respawn_arrivals

func resolve_local_move_capture_respawn(move_context: Dictionary) -> void:
	var captured_piece: Piece = move_context.get("captured_piece", null) as Piece
	var pending_respawn_arrivals: Array = move_context.get("pending_respawn_arrivals", [])
	if captured_piece != null:
		var shatter_respawn_info: Dictionary = match_board.get_local_state_mutator().resolve_capture_respawn(captured_piece)
		var shatter_respawn_pos: Vector2 = match_board.value_to_vector2(shatter_respawn_info.get("respawn_pos", invalid_board_pos), invalid_board_pos)
		var shatter_fragment_group: String = str(shatter_respawn_info.get("fragment_group", fragment_group_none))
		move_context["should_play_capture_shatter"] = true
		move_context["shatter_respawn_pos"] = shatter_respawn_pos
		move_context["shatter_fragment_group"] = shatter_fragment_group
		match_board.begin_piece_shatter_respawn_reveal(shatter_respawn_pos, shatter_fragment_group)
		pending_respawn_arrivals.append_array(shatter_respawn_info.get("pending_respawn_arrivals", []))
	else:
		pending_respawn_arrivals.append_array(match_board.get_local_state_mutator().resolve_pending_respawns_for_all())
	match_board.prepare_pending_edge_respawn_arrival_reveals(pending_respawn_arrivals)
	move_context["pending_respawn_arrivals"] = pending_respawn_arrivals

func finish_local_move_state_updates(move_context: Dictionary) -> void:
	match_board.get_turn_action_state_controller().mark_piece_moved_this_turn(int(move_context.get("moving_color", 0)))
	match_board.update_card_presentation()

func play_local_move_transition(move_context: Dictionary) -> void:
	var start_pos: Vector2 = move_context.get("start_pos", invalid_board_pos)
	var end_pos: Vector2 = move_context.get("end_pos", invalid_board_pos)
	var moving_start_texture: Texture2D = move_context.get("moving_start_texture", null) as Texture2D
	var moving_piece_visible_to_enemy: bool = bool(move_context.get("moving_piece_visible_to_enemy", true))
	var should_play_capture_shatter: bool = bool(move_context.get("should_play_capture_shatter", false))
	var captured_start_texture: Texture2D = move_context.get("captured_start_texture", null) as Texture2D

	match_board.display_board()
	var capture_placeholder: Sprite2D = match_board.create_piece_move_capture_placeholder(end_pos, captured_start_texture) if should_play_capture_shatter else null
	await match_board.play_piece_move_animation(start_pos, end_pos, moving_start_texture, moving_piece_visible_to_enemy)
	if is_instance_valid(capture_placeholder):
		capture_placeholder.queue_free()
	if should_play_capture_shatter:
		var captured_piece: Piece = move_context.get("captured_piece", null) as Piece
		var captured_color: int = captured_piece.color if captured_piece != null else 0
		var shatter_respawn_pos: Vector2 = match_board.value_to_vector2(move_context.get("shatter_respawn_pos", invalid_board_pos), invalid_board_pos)
		var shatter_fragment_group: String = str(move_context.get("shatter_fragment_group", fragment_group_none))
		match_board.play_piece_shatter_animation(end_pos, shatter_respawn_pos, captured_color, shatter_fragment_group)
	var pending_respawn_arrivals: Array = move_context.get("pending_respawn_arrivals", [])
	if !pending_respawn_arrivals.is_empty():
		match_board.play_pending_edge_respawn_arrival_animations(pending_respawn_arrivals)
	match_board.call_deferred("play_pending_piece_revert_animations")

func restore_local_move_selection(move_context: Dictionary) -> void:
	var start_pos: Vector2 = move_context.get("start_pos", invalid_board_pos)
	var end_pos: Vector2 = move_context.get("end_pos", invalid_board_pos)
	if (start_pos.x != end_pos.x || start_pos.y != end_pos.y) and (match_board.white and match_board.board[end_pos.x][end_pos.y] > 0 || !match_board.white and match_board.board[end_pos.x][end_pos.y] < 0):
		match_board.selected_piece = end_pos
		match_board.show_options()
		match_board.state = true

func return_captured_nexus_card_to_deck(captured_piece: Piece) -> void:
	if captured_piece == null or captured_piece.attached_card == null:
		return
	match_board.get_card_animation_controller().queue_nexus_card_return_to_deck_animation(captured_piece.color, captured_piece.attached_card, captured_piece.position)
	DeckManager.return_card_to_deck(match_board.get_card_deck(captured_piece.color), captured_piece.attached_card.card_name)

func consume_moved_piece_duration_locally(piece: Piece, piece_pos: Vector2) -> void:
	if piece == null or piece.attached_card == null:
		return

	var owner_color: int = piece.color
	var expiring_piece_texture: Texture2D = match_board.get_piece_visual_texture(piece)
	var expired_card: Card = piece.use_turn()
	if expired_card == null:
		return

	match_board.queue_piece_revert_animation(piece_pos, expiring_piece_texture)
	if MoveRules.is_nexus_card(expired_card):
		match_board.handle_expired_nexus_card_locally(owner_color, expired_card, piece_pos)
		return

	match_board.get_card_animation_controller().queue_card_expire_animation(piece_pos, expired_card)
