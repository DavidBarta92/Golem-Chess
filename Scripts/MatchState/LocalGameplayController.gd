extends RefCounted

var match_board
var board_size: int = BoardConfig.BOARD_SIZE

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	board_size = int(config.get("board_size", board_size))

func refill_played_stamps_locally(owner_color: int) -> void:
	if match_board == null:
		return

	var played_slots: Array = match_board.played_stamp_hand_slots_this_turn.get(owner_color, [])
	if played_slots.is_empty():
		return

	played_slots.sort()
	for slot_value in played_slots:
		var hand: Array[Stamp] = match_board.get_stamp_hand(owner_color)
		if hand.size() >= DeckManager.HAND_SIZE:
			break

		var stamp_name: String = match_board.get_stamp_hand_state_controller().draw_refill_stamp_name(owner_color)
		if stamp_name.is_empty():
			break
		match_board.insert_drawn_stamp(owner_color, int(slot_value), stamp_name)

	match_board.played_stamp_hand_slots_this_turn[owner_color] = []

func get_moves(selected: Vector2) -> Array:
	if match_board == null:
		return []

	if match_board.piece_objects.has(selected):
		var piece: Piece = match_board.piece_objects[selected] as Piece
		if piece.can_move():
			DebugLog.info("Using stamp movement: %s" % piece.get_info())
			return get_stamp_based_moves(selected, piece, get_move_preview_player_id(selected, piece))
		else:
			DebugLog.info("No usable stamp on this piece.")
			return []

	return []

func get_move_preview_player_id(piece_position: Vector2, piece: Piece) -> int:
	var own_player_id: int = match_board.get_own_player_id()
	if match_board.can_control_current_turn() && match_board.can_player_control_piece_at(piece_position, own_player_id):
		return own_player_id
	return match_board.get_player_id_for_color(piece.color)

func get_stamp_based_moves(piece_position: Vector2, piece: Piece, player_id: int) -> Array:
	var valid_moves: Array[Vector2] = MoveRules.get_piece_moves_for_player(match_board.piece_objects, piece_position, player_id, board_size, match_board.current_board_effects)
	valid_moves = filter_tutorial_move_targets(piece_position, valid_moves, piece.color)
	DebugLog.info("  Valid moves: %s" % [valid_moves])
	return valid_moves

func filter_tutorial_move_targets(from_pos: Vector2, candidate_moves: Array[Vector2], owner_color: int) -> Array[Vector2]:
	if !match_board.tutorial_constraints_enabled:
		return candidate_moves

	var filtered_moves: Array[Vector2] = []
	for to_pos: Vector2 in candidate_moves:
		if match_board.is_tutorial_action_allowed(match_board.TUTORIAL_ACTION_MOVE_PIECE, {
			"owner_color": owner_color,
			"from_pos": from_pos,
			"to_pos": to_pos,
		}):
			filtered_moves.append(to_pos)
	return filtered_moves
