extends RefCounted
class_name AIStateSimulator

static func clone_pieces(source_pieces: Dictionary) -> Dictionary:
	var cloned_pieces: Dictionary = {}
	for position_value in source_pieces:
		var position: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = source_pieces[position_value] as Piece
		if piece == null:
			continue
		cloned_pieces[position] = clone_piece(piece)
	return cloned_pieces

static func clone_piece(piece: Piece) -> Piece:
	var cloned_piece: Piece = Piece.new(piece.position, piece.color)
	cloned_piece.attached_stamp = piece.attached_stamp
	cloned_piece.turns_remaining = piece.turns_remaining
	cloned_piece.exhausted_this_turn = piece.exhausted_this_turn
	cloned_piece.respawn_cooldown_turns = piece.respawn_cooldown_turns
	return cloned_piece

static func clone_game_state(source_state: GameStateData) -> GameStateData:
	var cloned_state: GameStateData = GameStateData.new()
	if source_state == null:
		return cloned_state

	cloned_state.pieces = clone_pieces(source_state.pieces)
	cloned_state.player_decks = duplicate_stamp_list_dictionary(source_state.player_decks)
	cloned_state.player_initial_decks = duplicate_stamp_list_dictionary(source_state.player_initial_decks)
	cloned_state.player_hands = duplicate_stamp_list_dictionary(source_state.player_hands)
	cloned_state.player_codex_pages = duplicate_codex_pages_dictionary(source_state.player_codex_pages)
	cloned_state.current_page_index = source_state.current_page_index.duplicate()
	cloned_state.has_turned_page_this_turn = source_state.has_turned_page_this_turn.duplicate()
	cloned_state.spent_stamps = duplicate_spent_stamps_dictionary(source_state.spent_stamps)
	cloned_state.current_turn_player = source_state.current_turn_player
	cloned_state.completed_turn_counts = source_state.completed_turn_counts.duplicate()
	cloned_state.player_clock_seconds = source_state.player_clock_seconds.duplicate()
	cloned_state.white_seeker_position = source_state.white_seeker_position
	cloned_state.black_seeker_position = source_state.black_seeker_position
	cloned_state.player_base_fields = duplicate_vector2_dictionary(source_state.player_base_fields)
	cloned_state.board_effects = duplicate_board_effects(source_state.board_effects)
	cloned_state.recent_stamp_transfers = []
	cloned_state.recent_stamp_expirations = []
	cloned_state.recent_bomb_effects = []
	cloned_state.recent_pending_respawn_queues = []
	cloned_state.recent_pending_respawn_arrivals = []
	cloned_state.last_move = source_state.last_move.duplicate(true)
	cloned_state.pending_respawns = duplicate_pending_respawns(source_state.pending_respawns)
	cloned_state.attached_stamp_this_turn = source_state.attached_stamp_this_turn.duplicate()
	cloned_state.attached_stamp_count_this_turn = source_state.attached_stamp_count_this_turn.duplicate()
	cloned_state.moved_piece_this_turn = source_state.moved_piece_this_turn.duplicate()
	cloned_state.exchanged_stamp_this_turn = source_state.exchanged_stamp_this_turn.duplicate()
	cloned_state.played_stamp_hand_slots_this_turn = duplicate_int_list_dictionary(source_state.played_stamp_hand_slots_this_turn)
	cloned_state.exchanged_stamp_names_this_turn = duplicate_stamp_list_dictionary(source_state.exchanged_stamp_names_this_turn)
	cloned_state.game_over = source_state.game_over
	cloned_state.winner_player = source_state.winner_player
	cloned_state.win_condition = source_state.win_condition
	cloned_state.match_logger = null
	return cloned_state

static func duplicate_stamp_list_dictionary(source: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for key in source:
		var source_list: Array = source[key]
		var duplicated_list: Array = []
		for stamp_name_value in source_list:
			duplicated_list.append(str(stamp_name_value))
		output[key] = duplicated_list
	return output

static func duplicate_codex_pages_dictionary(source: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for key in source:
		var pages: Array = source[key]
		var duplicated_pages: Array = []
		for page_value in pages:
			var duplicated_page: Array = []
			if page_value is Array:
				for stamp_name_value in page_value:
					duplicated_page.append(str(stamp_name_value))
			duplicated_pages.append(duplicated_page)
		output[key] = duplicated_pages
	return output

static func duplicate_spent_stamps_dictionary(source: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for key in source:
		var source_list: Array = source[key]
		var duplicated_list: Array = []
		for value in source_list:
			if value is Dictionary:
				duplicated_list.append((value as Dictionary).duplicate(true))
		output[key] = duplicated_list
	return output

static func duplicate_int_list_dictionary(source: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for key in source:
		var source_list: Array = source[key]
		var duplicated_list: Array = []
		for value in source_list:
			duplicated_list.append(int(value))
		output[key] = duplicated_list
	return output

static func duplicate_vector2_dictionary(source: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for key in source:
		output[key] = StampEffectResolver.as_vector2(source[key], Vector2(-1, -1))
	return output

static func duplicate_board_effects(source_effects: Array) -> Array:
	var output: Array = []
	for effect_value in source_effects:
		var effect: Dictionary = effect_value
		var duplicated_squares: Array[Vector2] = []
		var squares: Array = effect.get("squares", [])
		for square_value in squares:
			duplicated_squares.append(StampEffectResolver.as_vector2(square_value, Vector2(-1, -1)))

		var duplicated_effect: Dictionary = {
			"effect_type": str(effect.get("effect_type", "")),
			"owner_player_id": int(effect.get("owner_player_id", -1)),
			"target_player_id": int(effect.get("target_player_id", -1)),
			"squares": duplicated_squares,
			"turns_remaining": int(effect.get("turns_remaining", -1)),
		}
		if bool(effect.get("skip_next_tick", false)):
			duplicated_effect["skip_next_tick"] = true
		output.append(duplicated_effect)
	return output

static func duplicate_pending_respawns(source: Dictionary) -> Dictionary:
	var output: Dictionary = {
		0: [],
		1: [],
	}
	for key in source:
		var source_list: Array = source[key]
		var duplicated_list: Array = []
		for piece_value in source_list:
			var piece: Piece = piece_value as Piece
			if piece != null:
				duplicated_list.append(clone_piece(piece))
		output[key] = duplicated_list
	return output

static func apply_turn_plan(source_state: GameStateData, player_id: int, plan: Dictionary, board_size: int = BoardConfig.BOARD_SIZE) -> GameStateData:
	var simulated_state: GameStateData = clone_game_state(source_state)
	if simulated_state.game_over:
		return simulated_state

	simulated_state.current_turn_player = player_id
	var actions: Array = plan.get("actions", [])
	for action_value in actions:
		var action: Dictionary = action_value
		match str(action.get("type", "")):
			"attach_stamp":
				apply_attach_action(simulated_state, player_id, action, board_size)
			"turn_page":
				apply_turn_page_action(simulated_state, player_id)
			"exchange_stamp":
				apply_exchange_action(simulated_state, player_id, action)
			"move_piece":
				apply_move_action(simulated_state, player_id, action, board_size)
			"end_turn":
				break

		if simulated_state.game_over:
			return simulated_state

	end_simulated_turn(simulated_state, player_id, board_size)
	return simulated_state

static func apply_attach_action(game_state: GameStateData, player_id: int, action: Dictionary, board_size: int) -> void:
	var piece_pos: Vector2 = StampEffectResolver.as_vector2(action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
	var piece: Piece = game_state.get_piece(piece_pos)
	if piece == null or !piece.can_receive_stamp():
		return

	var stamp_name: String = str(action.get("stamp_name", ""))
	var stamp: Stamp = StampLibrary.get_stamp(stamp_name)
	if stamp == null:
		return

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	if piece.color != player_color or !MoveRules.can_attach_stamp_for_turn(game_state.pieces, player_color, stamp):
		return

	var consumed_stamp: Dictionary = game_state.consume_current_page_stamp_by_name(player_id, stamp_name, int(action.get("hand_index", -1)))
	if consumed_stamp.is_empty():
		return
	var removed_hand_index: int = int(consumed_stamp.get("stamp_index", int(action.get("hand_index", -1))))
	record_played_stamp_hand_slot(game_state, player_id, removed_hand_index)
	game_state.attached_stamp_this_turn[player_id] = true
	game_state.attached_stamp_count_this_turn[player_id] = int(game_state.attached_stamp_count_this_turn.get(player_id, 0)) + 1
	var attached_stamp: Stamp = stamp.duplicate()
	attached_stamp.set_meta("codex_owner_player_id", player_id)
	attached_stamp.set_meta("codex_page_index", int(consumed_stamp.get("page_index", game_state.get_current_page_index(player_id))))
	attached_stamp.set_meta("codex_stamp_index", int(consumed_stamp.get("stamp_index", removed_hand_index)))
	piece.attached_stamp = attached_stamp
	piece.turns_remaining = stamp.duration
	piece.exhausted_this_turn = true
	simulate_trigger_effect(game_state, StampEffect.TRIGGER_ON_ATTACH, player_id, piece, piece_pos, attached_stamp, board_size)
	if game_state.game_over:
		return
	StampEffectResolver.resolve_symbol_count_trigger(game_state, player_id, piece, piece_pos, attached_stamp, board_size)
	_refresh_seeker_positions(game_state)

static func apply_turn_page_action(game_state: GameStateData, player_id: int) -> void:
	if game_state == null:
		return
	game_state.turn_page(player_id)

static func apply_exchange_action(game_state: GameStateData, player_id: int, action: Dictionary) -> void:
	return

static func get_exchange_stamp_index(hand: Array, stamp_name: String, hand_index: int) -> int:
	if hand_index >= 0 and hand_index < hand.size():
		if stamp_name.is_empty() or str(hand[hand_index]) == stamp_name:
			return hand_index
	if !stamp_name.is_empty():
		return hand.find(stamp_name)
	return -1

static func draw_stamp_from_deck_avoiding_names(deck: Array, avoided_stamp_names: Array) -> String:
	if deck.is_empty():
		return ""

	var draw_index: int = -1
	for index in range(deck.size()):
		var candidate_name: String = str(deck[index])
		if !avoided_stamp_names.has(candidate_name):
			draw_index = index
			break
	if draw_index == -1:
		draw_index = 0

	var drawn_stamp_name: String = str(deck[draw_index])
	deck.remove_at(draw_index)
	return drawn_stamp_name

static func apply_move_action(game_state: GameStateData, player_id: int, action: Dictionary, board_size: int) -> void:
	if bool(game_state.moved_piece_this_turn.get(player_id, false)):
		return

	var from_pos: Vector2 = StampEffectResolver.as_vector2(action.get("from", Vector2(-1, -1)), Vector2(-1, -1))
	var to_pos: Vector2 = StampEffectResolver.as_vector2(action.get("to", Vector2(-1, -1)), Vector2(-1, -1))
	var moving_piece: Piece = game_state.get_piece(from_pos)
	if moving_piece == null:
		return

	var captured_piece: Piece = game_state.get_piece(to_pos)
	var captured_player_id: int = StampEffectResolver.get_player_id_for_color(captured_piece.color) if captured_piece != null else -1
	if captured_piece != null:
		handle_captured_piece_stamp(game_state, captured_piece, captured_player_id, to_pos)
		if game_state.game_over:
			return
	game_state.remove_piece(from_pos)
	moving_piece.position = to_pos
	game_state.set_piece(to_pos, moving_piece)
	game_state.moved_piece_this_turn[player_id] = true
	if captured_piece != null:
		respawn_captured_piece(game_state, captured_piece, captured_player_id)
	StampEffectResolver.resolve_pending_respawns_for_all_players(game_state)

	if MoveRules.is_seeker_stamp(moving_piece.attached_stamp):
		if player_id == 0:
			game_state.white_seeker_position = to_pos
		else:
			game_state.black_seeker_position = to_pos

	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	if MoveRules.is_seeker_stamp(moving_piece.attached_stamp) && to_pos == opponent_base:
		game_state.game_over = true
		game_state.winner_player = player_id
		game_state.win_condition = "base_reached"
		return

	if captured_piece != null && StampEffectResolver.is_seeker_piece(captured_piece):
		StampEffectResolver.clear_seeker_position_if_needed(game_state, captured_player_id, true)

	if moving_piece.attached_stamp != null:
		var moving_stamp: Stamp = moving_piece.attached_stamp
		if captured_piece != null:
			simulate_trigger_effect(game_state, StampEffect.TRIGGER_ON_CAPTURE, player_id, moving_piece, to_pos, moving_stamp, board_size, {
				"captured_piece": captured_piece,
				"captured_piece_pos": to_pos,
			})
			if game_state.game_over:
				return

		simulate_trigger_effect(game_state, StampEffect.TRIGGER_ON_MOVE, player_id, moving_piece, to_pos, moving_stamp, board_size, {
			"from_pos": from_pos,
			"to_pos": to_pos,
		})
		if game_state.game_over:
			return

	consume_moved_piece_duration(game_state, player_id, moving_piece, to_pos, board_size)
	if game_state.game_over:
		return

	_refresh_seeker_positions(game_state)

static func simulate_trigger_effect(
	game_state: GameStateData,
	trigger: String,
	player_id: int,
	piece: Piece,
	source_pos: Vector2,
	stamp: Stamp,
	board_size: int,
	extra_context: Dictionary = {}
) -> void:
	if stamp == null or !stamp.has_effect() or stamp.effect_trigger != trigger:
		return

	var context: Dictionary = {
		"player_id": player_id,
		"piece": piece,
		"piece_pos": source_pos,
		"stamp": stamp,
	}
	for key in extra_context:
		context[key] = extra_context[key]

	StampEffectResolver.resolve_trigger(trigger, game_state, context, board_size)
	_refresh_seeker_positions(game_state)

static func remove_stamp_name_from_hand(game_state: GameStateData, player_id: int, stamp_name: String) -> int:
	if !game_state.player_hands.has(player_id):
		return -1

	var hand: Array = game_state.player_hands[player_id]
	var stamp_index: int = hand.find(stamp_name)
	if stamp_index != -1:
		hand.remove_at(stamp_index)
	game_state.player_hands[player_id] = hand
	return stamp_index

static func end_simulated_turn(game_state: GameStateData, player_id: int, board_size: int) -> void:
	if game_state.game_over:
		return

	game_state.current_turn_player = player_id
	game_state.played_stamp_hand_slots_this_turn[player_id] = []
	game_state.exchanged_stamp_names_this_turn[player_id] = []
	clear_piece_exhaustion_for_player(game_state, player_id)
	game_state.completed_turn_counts[player_id] = int(game_state.completed_turn_counts.get(player_id, 0)) + 1
	game_state.switch_turn()
	StampEffectResolver.tick_board_effects(game_state)

static func clear_piece_exhaustion_for_player(game_state: GameStateData, player_id: int) -> void:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null and piece.color == player_color:
			if piece.is_respawn_locked():
				continue
			piece.exhausted_this_turn = false

static func record_played_stamp_hand_slot(game_state: GameStateData, player_id: int, current_hand_index: int) -> void:
	var played_slots: Array = game_state.played_stamp_hand_slots_this_turn.get(player_id, [])
	played_slots.append(get_original_hand_slot_for_play(game_state, player_id, current_hand_index))
	game_state.played_stamp_hand_slots_this_turn[player_id] = played_slots

static func get_original_hand_slot_for_play(game_state: GameStateData, player_id: int, current_hand_index: int) -> int:
	var played_slots: Array = game_state.played_stamp_hand_slots_this_turn.get(player_id, [])
	for candidate in range(current_hand_index, DeckManager.HAND_SIZE):
		if played_slots.has(candidate):
			continue

		var previous_slots_before_candidate: int = 0
		for slot_value in played_slots:
			if int(slot_value) < candidate:
				previous_slots_before_candidate += 1
		if candidate - previous_slots_before_candidate == current_hand_index:
			return candidate
	return clampi(current_hand_index, 0, DeckManager.HAND_SIZE - 1)

static func refill_played_stamps_for_player(game_state: GameStateData, player_id: int) -> void:
	var played_slots: Array = game_state.played_stamp_hand_slots_this_turn.get(player_id, [])
	if played_slots.is_empty():
		game_state.exchanged_stamp_names_this_turn[player_id] = []
		return
	if !game_state.player_decks.has(player_id) or !game_state.player_hands.has(player_id):
		game_state.played_stamp_hand_slots_this_turn[player_id] = []
		game_state.exchanged_stamp_names_this_turn[player_id] = []
		return

	played_slots.sort()
	var deck: Array = game_state.player_decks[player_id]
	var hand: Array = game_state.player_hands[player_id]
	var protected_names: Array = game_state.exchanged_stamp_names_this_turn.get(player_id, [])
	for slot_value in played_slots:
		if deck.is_empty() or hand.size() >= DeckManager.HAND_SIZE:
			break

		var drawn_stamp_name: String = draw_stamp_from_deck_avoiding_names(deck, protected_names)
		if drawn_stamp_name.is_empty():
			break
		var insert_index: int = clampi(int(slot_value), 0, hand.size())
		hand.insert(insert_index, drawn_stamp_name)

	game_state.player_decks[player_id] = deck
	game_state.player_hands[player_id] = hand
	game_state.played_stamp_hand_slots_this_turn[player_id] = []
	game_state.exchanged_stamp_names_this_turn[player_id] = []

static func handle_expired_seeker_stamp(game_state: GameStateData, player_id: int, expired_stamp: Stamp, piece_pos: Vector2) -> void:
	StampEffectResolver.clear_seeker_position_if_needed(game_state, player_id, true)
	StampEffectResolver.return_stamp_to_owner_deck(game_state, player_id, expired_stamp.stamp_name, piece_pos, "expired_seeker", expired_stamp)

static func handle_captured_piece_stamp(game_state: GameStateData, captured_piece: Piece, captured_player_id: int, piece_pos: Vector2) -> void:
	if captured_piece == null or captured_piece.attached_stamp == null:
		return

	var captured_stamp: Stamp = captured_piece.attached_stamp
	var captured_was_seeker: bool = StampEffectResolver.is_seeker_piece(captured_piece)
	if captured_was_seeker:
		StampEffectResolver.return_stamp_to_owner_deck(game_state, captured_player_id, captured_stamp.stamp_name, piece_pos, "effect_capture", captured_stamp)

	captured_piece.detach_stamp()
	if captured_was_seeker:
		StampEffectResolver.clear_seeker_position_if_needed(game_state, captured_player_id, true)

static func respawn_captured_piece(game_state: GameStateData, captured_piece: Piece, captured_player_id: int) -> bool:
	return StampEffectResolver.respawn_captured_piece(game_state, captured_piece, captured_player_id)

static func release_pending_respawn_piece(game_state: GameStateData, player_id: int) -> bool:
	return StampEffectResolver.release_pending_respawn_piece(game_state, player_id)

static func get_random_empty_home_position(game_state: GameStateData, player_id: int) -> Vector2:
	return StampEffectResolver.get_random_empty_home_position(game_state, player_id)

static func consume_moved_piece_duration(game_state: GameStateData, player_id: int, piece: Piece, piece_pos: Vector2, board_size: int) -> void:
	if piece == null or piece.attached_stamp == null:
		return

	var expired_stamp: Stamp = piece.use_turn()
	if expired_stamp == null:
		return

	if MoveRules.is_seeker_stamp(expired_stamp):
		handle_expired_seeker_stamp(game_state, player_id, expired_stamp, piece_pos)
		return

	simulate_trigger_effect(game_state, StampEffect.TRIGGER_ON_EXPIRE, player_id, piece, piece_pos, expired_stamp, board_size)

static func _refresh_seeker_positions(game_state: GameStateData) -> void:
	game_state.white_seeker_position = find_seeker_position(game_state.pieces, 0)
	game_state.black_seeker_position = find_seeker_position(game_state.pieces, 1)

static func apply_candidate_to_pieces(source_pieces: Dictionary, move: Dictionary) -> Dictionary:
	var simulated_pieces: Dictionary = clone_pieces(source_pieces)
	var from_pos: Vector2 = get_move_from(move)
	var to_pos: Vector2 = get_move_to(move)
	var moving_piece: Piece = simulated_pieces.get(from_pos, null) as Piece
	if moving_piece == null:
		return simulated_pieces

	if bool(move.get("requires_attach", false)):
		var stamp: Stamp = move.get("stamp", null) as Stamp
		if stamp != null:
			moving_piece.attached_stamp = stamp
			moving_piece.turns_remaining = stamp.duration
			moving_piece.exhausted_this_turn = true

	var captured_piece: Piece = simulated_pieces.get(to_pos, null) as Piece
	simulated_pieces.erase(from_pos)
	moving_piece.position = to_pos
	simulated_pieces[to_pos] = moving_piece
	moving_piece.use_turn()
	if captured_piece != null:
		captured_piece.detach_stamp()
		respawn_captured_piece_in_pieces(simulated_pieces, captured_piece)
	return simulated_pieces

static func respawn_captured_piece_in_pieces(pieces: Dictionary, captured_piece: Piece) -> bool:
	if captured_piece == null:
		return false

	var player_id: int = StampEffectResolver.get_player_id_for_color(captured_piece.color)
	if release_pending_respawn_piece_in_pieces(pieces, player_id):
		return true

	var home_row: int = BoardConfig.get_home_row_for_player_id(player_id)
	var empty_positions: Array[Vector2] = []
	for col in BoardConfig.BOARD_SIZE:
		var pos: Vector2 = Vector2(home_row, col)
		if !pieces.has(pos) and pos != BoardConfig.WHITE_BASE_FIELD and pos != BoardConfig.BLACK_BASE_FIELD:
			empty_positions.append(pos)

	if empty_positions.is_empty():
		return false

	var respawn_pos: Vector2 = empty_positions[randi() % empty_positions.size()]
	captured_piece.position = respawn_pos
	captured_piece.set_respawn_cooldown(GameConfig.RESPAWN_COOLDOWN_OWN_TURNS)
	pieces[respawn_pos] = captured_piece
	return true

static func release_pending_respawn_piece_in_pieces(pieces: Dictionary, player_id: int) -> bool:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	for position_value in pieces:
		var piece: Piece = pieces[position_value] as Piece
		if piece != null and piece.color == player_color and piece.is_respawn_locked():
			piece.set_respawn_cooldown(0)
			return true
	return false

static func get_move_from(move: Dictionary) -> Vector2:
	return StampEffectResolver.as_vector2(move.get("from", Vector2(-1, -1)), Vector2(-1, -1))

static func get_move_to(move: Dictionary) -> Vector2:
	return StampEffectResolver.as_vector2(move.get("to", Vector2(-1, -1)), Vector2(-1, -1))

static func get_stamp_for_candidate(pieces: Dictionary, move: Dictionary) -> Stamp:
	var move_stamp: Stamp = move.get("stamp", null) as Stamp
	if move_stamp != null:
		return move_stamp

	var from_pos: Vector2 = get_move_from(move)
	var piece: Piece = pieces.get(from_pos, null) as Piece
	if piece == null:
		return null
	return piece.attached_stamp

static func get_captured_piece(pieces: Dictionary, move: Dictionary) -> Piece:
	var to_pos: Vector2 = get_move_to(move)
	return pieces.get(to_pos, null) as Piece

static func find_seeker_position(pieces: Dictionary, player_id: int) -> Vector2:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	for position_value in pieces:
		var position: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = pieces[position_value] as Piece
		if piece != null && piece.color == player_color && StampEffectResolver.is_seeker_piece(piece):
			return position
	return Vector2(-1, -1)

static func is_own_seeker_candidate(pieces: Dictionary, move: Dictionary, player_id: int) -> bool:
	var from_pos: Vector2 = get_move_from(move)
	var moving_piece: Piece = pieces.get(from_pos, null) as Piece
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	if moving_piece == null or moving_piece.color != player_color:
		return false

	var stamp: Stamp = get_stamp_for_candidate(pieces, move)
	return MoveRules.is_seeker_stamp(stamp)

static func get_hand_stamps_from_state(game_state: GameStateData, player_id: int) -> Array[Stamp]:
	var hand_stamps: Array[Stamp] = []
	if game_state == null or !game_state.player_hands.has(player_id):
		return hand_stamps

	var hand_stamp_names: Array = game_state.player_hands[player_id]
	for stamp_name_value in hand_stamp_names:
		var stamp_name: String = str(stamp_name_value)
		var stamp: Stamp = StampLibrary.get_stamp(stamp_name)
		if stamp != null:
			hand_stamps.append(stamp)
	return hand_stamps

static func is_square_threatened(
	pieces: Dictionary,
	target_pos: Vector2,
	attacker_player_id: int,
	hand_stamps: Array[Stamp],
	board_effects: Array,
	board_size: int
) -> bool:
	var attacker_color: int = StampEffectResolver.get_color_for_player_id(attacker_player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_valid_turn_moves(
		pieces,
		attacker_color,
		hand_stamps,
		true,
		board_size,
		board_effects
	)

	for move: Dictionary in valid_moves:
		if get_move_to(move) == target_pos:
			return true
	return false
