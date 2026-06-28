class_name NetworkGameHost

const CODEX_BRIDGE_SCRIPT = preload("res://Scripts/CodexBridge.gd")
const CHESS_CLOCK_SECONDS: float = 300.0

var game_state: GameStateData
var multiplayer_node
var codex_bridge = null

func _init(mp_node = null):
	configure(mp_node)

func configure(mp_node = null) -> void:
	multiplayer_node = mp_node
	game_state = GameStateData.new()
	codex_bridge = CODEX_BRIDGE_SCRIPT.new()

func initialize_game(board_data: Array):
	for i in range(board_data.size()):
		for j in range(board_data[i].size()):
			var value = board_data[i][j]
			if value != 0:
				var pos = Vector2(i, j)
				var color = 1 if value > 0 else -1
				var piece = Piece.new(pos, color)
				game_state.set_piece(pos, piece)

	var white_codex_cards: Array[String] = create_starting_deck_for_player_id(0)
	var black_codex_cards: Array[String] = create_starting_deck_for_player_id(1)
	game_state.initialize_player_codex(0, white_codex_cards)
	game_state.initialize_player_codex(1, black_codex_cards)
	setup_match_logging()

	DebugLog.info("NetworkGameHost: game state initialized")

	broadcast_full_state()

func process_codex_bridge_commands() -> bool:
	if codex_bridge == null:
		return false
	return codex_bridge.process_command_file(self)

func process(delta: float) -> void:
	if GameConfig.is_singleplayer or game_state == null or game_state.game_over:
		return
	var active_player: int = game_state.current_turn_player
	var remaining: float = maxf(float(game_state.player_clock_seconds.get(active_player, CHESS_CLOCK_SECONDS)) - maxf(delta, 0.0), 0.0)
	game_state.player_clock_seconds[active_player] = remaining
	if remaining > 0.0:
		return
	DebugLog.info("Chess clock expired for player: %d" % active_player)
	finish_game(1 - active_player, "time_expired")
	broadcast_full_state()

func detach_multiplayer_node() -> void:
	multiplayer_node = null

func create_starting_deck_for_player_id(player_id: int) -> Array[String]:
	if multiplayer_node != null && multiplayer_node.has_method("get_starting_deck_for_player_id"):
		var selected_deck: Array[String] = multiplayer_node.get_starting_deck_for_player_id(player_id)
		if !selected_deck.is_empty():
			DebugLog.info("Player %d selected codex: %s" % [player_id, selected_deck])
			return selected_deck

	return DeckManager.create_starting_deck()

func setup_match_logging() -> void:
	if !should_log_match():
		return

	game_state.match_logger = MatchCsvLogger.new()
	if GameConfig.is_dedicated_server:
		game_state.match_logger.set_log_dir(GameConfig.get_dedicated_server_log_dir())
		DebugLog.info("Dedicated match CSV logs: %s" % GameConfig.get_dedicated_server_log_dir())
	game_state.match_logger.start_match(game_state)

func should_log_match() -> bool:
	if GameConfig.is_dedicated_server:
		return true
	if GameConfig.is_ai_vs_ai_batch:
		return true
	if !GameConfig.is_singleplayer:
		return false
	for player_id in [0, 1]:
		if GameConfig.get_player_controller(player_id) == GameConfig.CONTROLLER_AI:
			return true
	return false

func on_player_action(action: Dictionary):
	DebugLog.info("Action received: %s" % [action])

	match action.type:
		"attach_card":
			handle_attach_card(action)
		"turn_page":
			return handle_turn_page(action)
		"exchange_card":
			return handle_exchange_card(action)
		"move_piece":
			handle_move_piece(action)
		"end_turn":
			handle_end_turn(action)
		_:
			push_warning("Unknown action type: ", action.type)
			return false

	return true

func handle_attach_card(action: Dictionary):
	var player_id: int = int(action.player_id)
	var card_name: String = str(action.card_name)
	var piece_pos: Vector2 = CardEffectResolver.as_vector2(action.piece_pos, Vector2(-1, -1))
	var hand_index: int = int(action.get("hand_index", -1))

	DebugLog.info("Attach card: player=%s, card=%s, position=%s" % [player_id, card_name, piece_pos])

	if game_state.game_over:
		return
	if game_state.current_turn_player != player_id:
		return

	if !game_state.player_hands[player_id].has(card_name):
		push_warning("Card is not in hand.")
		return

	var piece = game_state.get_piece(piece_pos)
	if piece == null:
		push_warning("No piece at this position.")
		return

	var expected_color: int = BoardConfig.get_color_for_player_id(player_id)
	if piece.color != expected_color:
		push_warning("This piece does not belong to the player.")
		return

	if !piece.can_receive_card():
		push_warning("This piece cannot receive a card right now.")
		return

	var card: Card = CardLibrary.duplicate_card(card_name)
	if card:
		var hand_before: Array = duplicate_player_card_list(game_state.player_hands[player_id])
		var deck_before: Array = duplicate_player_card_list(game_state.player_decks[player_id])
		var deck_top_before: String = str(deck_before[0]) if !deck_before.is_empty() else ""
		var piece_card_before: String = piece.attached_card.card_name if piece.attached_card != null else ""
		var piece_turns_before: int = piece.turns_remaining
		var consumed_stamp: Dictionary = game_state.consume_current_page_stamp_by_name(player_id, card_name, hand_index)
		if consumed_stamp.is_empty():
			push_warning("Stamp could not be removed from current Codex page.")
			return
		card.set_meta("codex_owner_player_id", player_id)
		card.set_meta("codex_page_index", int(consumed_stamp.get("page_index", game_state.get_current_page_index(player_id))))
		card.set_meta("codex_stamp_index", int(consumed_stamp.get("stamp_index", hand_index)))
		piece.attach_card(card, true)
		game_state.attached_card_this_turn[player_id] = true
		game_state.attached_card_count_this_turn[player_id] = int(game_state.attached_card_count_this_turn.get(player_id, 0)) + 1
		if MoveRules.is_seeker_card(card):
			if player_id == 0:
				game_state.white_seeker_position = piece_pos
			else:
				game_state.black_seeker_position = piece_pos
		log_card_attached(player_id, card, piece, piece_pos, hand_before, deck_before, deck_top_before, piece_card_before, piece_turns_before)
		CardEffectResolver.resolve_trigger(CardEffect.TRIGGER_ON_ATTACH, game_state, {
			"player_id": player_id,
			"piece": piece,
			"piece_pos": piece_pos,
			"card": card,
		})
		if game_state.game_over:
			log_turn_snapshot("after_attach")
			broadcast_full_state()
			return
		CardEffectResolver.resolve_symbol_count_trigger(game_state, player_id, piece, piece_pos, card, BoardConfig.BOARD_SIZE)
		if game_state.game_over:
			log_turn_snapshot("after_attach")
			broadcast_full_state()
			return
		log_turn_snapshot("after_attach")

		DebugLog.info("Card attached successfully")
		if is_first_turn_for_player(player_id) and int(game_state.attached_card_count_this_turn.get(player_id, 0)) >= DeckManager.HAND_SIZE:
			DebugLog.info("Three first-turn stamps attached. Ending turn for player: %d" % player_id)
			end_current_turn()
			return
		broadcast_full_state()

func handle_turn_page(action: Dictionary) -> bool:
	var player_id: int = int(action.player_id)
	DebugLog.info("Turn Codex page: player=%s" % player_id)

	if game_state.game_over:
		return false
	if game_state.current_turn_player != player_id:
		return false
	if !game_state.turn_page(player_id):
		push_warning("This player cannot turn the Codex page now.")
		return false

	log_turn_snapshot("after_turn_page")
	broadcast_full_state()
	return true

func handle_exchange_card(action: Dictionary):
	var player_id: int = int(action.player_id)
	var card_name: String = str(action.get("card_name", ""))
	var hand_index: int = int(action.get("hand_index", -1))

	DebugLog.info("Exchange card: player=%s, card=%s, hand_index=%s" % [player_id, card_name, hand_index])

	push_warning("Card exchange is disabled. Use turn_page instead.")
	return false

func get_exchange_card_hand_index(hand: Array, card_name: String, hand_index: int) -> int:
	if hand_index >= 0 && hand_index < hand.size():
		if card_name.is_empty() or str(hand[hand_index]) == card_name:
			return hand_index
	if !card_name.is_empty():
		return hand.find(card_name)
	return -1

func handle_move_piece(action: Dictionary):
	var player_id: int = int(action.player_id)
	var from_pos: Vector2 = CardEffectResolver.as_vector2(action.from, Vector2(-1, -1))
	var to_pos: Vector2 = CardEffectResolver.as_vector2(action.to, Vector2(-1, -1))

	DebugLog.info("Move: player=%s, %s -> %s" % [player_id, from_pos, to_pos])

	if game_state.game_over:
		return

	var piece = game_state.get_piece(from_pos)
	if piece == null:
		push_warning("No piece at the start position.")
		return

	if !CardEffectResolver.can_player_control_piece(piece, player_id):
		push_warning("This piece does not belong to the player.")
		return

	if !piece.can_move():
		push_warning("This piece has no usable card.")
		return

	if game_state.current_turn_player != player_id:
		push_warning("It is not this player's turn.")
		return
	if bool(game_state.moved_piece_this_turn.get(player_id, false)):
		push_warning("This player has already moved this turn.")
		return

	if !is_valid_move(piece, from_pos, to_pos, player_id):
		push_warning("Invalid move.")
		return

	var captured_piece = game_state.get_piece(to_pos)
	var captured_seeker: bool = is_seeker_piece(captured_piece)
	var captured_piece_owner_player_id: int = CardEffectResolver.get_player_id_for_color(captured_piece.color) if captured_piece != null else -1
	var move_log_context: Dictionary = create_move_log_context(player_id, from_pos, to_pos, piece, captured_piece)
	var moving_piece_visible_to_enemy: bool = !CardEffectResolver.piece_has_attached_effect(piece, CardEffect.TYPE_INVISIBLE_TO_ENEMY)

	if captured_piece != null:
		DebugLog.info("Piece captured at: %s" % to_pos)
		if captured_piece.attached_card != null:
			CardEffectResolver.resolve_trigger(CardEffect.TRIGGER_ON_CAPTURED, game_state, {
				"player_id": 1 - player_id,
				"piece": captured_piece,
				"piece_pos": to_pos,
				"card": captured_piece.attached_card,
				"capturing_piece": piece,
				"capturing_piece_pos": from_pos,
			})
			if game_state.game_over:
				log_move_result(move_log_context, game_state.win_condition)
				broadcast_full_state()
				return
			if game_state.get_piece(from_pos) != piece:
				log_move_result(move_log_context, "capturing_piece_removed")
				game_state.moved_piece_this_turn[player_id] = true
				log_turn_snapshot("after_move")
				end_current_turn()
				return

		if captured_seeker && captured_piece.attached_card != null:
			return_card_to_player_deck(captured_piece_owner_player_id, captured_piece.attached_card, "captured_seeker", to_pos)

	game_state.remove_piece(from_pos)
	piece.position = to_pos
	game_state.set_piece(to_pos, piece)
	record_last_move(player_id, from_pos, to_pos, moving_piece_visible_to_enemy, captured_piece)

	if MoveRules.is_seeker_card(piece.attached_card):
		var moved_piece_owner_player_id: int = CardEffectResolver.get_player_id_for_color(piece.color)
		if moved_piece_owner_player_id == 0:
			game_state.white_seeker_position = to_pos
		else:
			game_state.black_seeker_position = to_pos

	if captured_seeker:
		var captured_player_id: int = captured_piece_owner_player_id
		CardEffectResolver.clear_seeker_position_if_needed(game_state, captured_player_id, true)
		DebugLog.info("Seeker piece captured. Seeker card returned to player %d deck." % captured_player_id)

	if captured_piece != null && piece.attached_card != null:
		CardEffectResolver.resolve_trigger(CardEffect.TRIGGER_ON_CAPTURE, game_state, {
			"player_id": player_id,
			"piece": piece,
			"piece_pos": to_pos,
			"card": piece.attached_card,
			"captured_piece": captured_piece,
			"captured_piece_pos": to_pos,
		})
		if game_state.game_over:
			log_move_result(move_log_context, game_state.win_condition)
			broadcast_full_state()
			return

	if captured_piece != null:
		captured_piece.detach_card()
		respawn_captured_piece(captured_piece, captured_piece_owner_player_id)
	CardEffectResolver.resolve_pending_respawns_for_all_players(game_state)

	var opponent_base_field: Vector2 = CardEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var entered_opponent_base: bool = to_pos == opponent_base_field
	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	if is_seeker_piece(piece) && piece.color == player_color && entered_opponent_base:
		DebugLog.info("Opponent base reached by Seeker. Player %d wins." % player_id)
		finish_game(player_id, "base_reached")
		log_move_result(move_log_context, game_state.win_condition)
		broadcast_full_state()
		return

	if piece.attached_card != null:
		CardEffectResolver.resolve_trigger(CardEffect.TRIGGER_ON_MOVE, game_state, {
			"player_id": player_id,
			"piece": piece,
			"piece_pos": to_pos,
			"card": piece.attached_card,
			"from_pos": from_pos,
			"to_pos": to_pos,
		})
		if game_state.game_over:
			log_move_result(move_log_context, game_state.win_condition)
			broadcast_full_state()
			return

	consume_moved_piece_duration(player_id, piece, to_pos)
	if game_state.game_over:
		log_move_result(move_log_context, game_state.win_condition)
		broadcast_full_state()
		return

	log_move_result(move_log_context, "")
	game_state.moved_piece_this_turn[player_id] = true
	log_turn_snapshot("after_move")

	DebugLog.info("Move complete. Ending turn for player: %s" % game_state.current_turn_player)
	end_current_turn()

func handle_end_turn(action: Dictionary):
	var player_id: int = int(action.player_id)
	if game_state.game_over or game_state.current_turn_player != player_id:
		return
	if !can_end_turn_by_button(player_id):
		push_warning("End turn rejected for player %d: a move is required unless the first-turn or frozen-piece exception applies." % player_id)
		return
	end_current_turn()

func end_current_turn():
	if game_state.game_over:
		return

	var ending_player_id: int = game_state.current_turn_player
	game_state.played_card_hand_slots_this_turn[ending_player_id] = []
	clear_exchanged_card_names_this_turn(ending_player_id)
	clear_piece_exhaustion_for_player(ending_player_id)
	game_state.completed_turn_counts[ending_player_id] = int(game_state.completed_turn_counts.get(ending_player_id, 0)) + 1
	game_state.switch_turn()
	advance_logged_turn()
	CardEffectResolver.tick_board_effects(game_state)
	finish_if_player_has_no_valid_turn(game_state.current_turn_player)
	log_turn_snapshot("turn_end")
	DebugLog.info("Turn ended. Next player: %s" % game_state.current_turn_player)
	broadcast_full_state()

func clear_piece_exhaustion_for_player(player_id: int) -> void:
	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null && piece.color == player_color:
			if piece.is_respawn_locked():
				continue
			piece.exhausted_this_turn = false

func handle_expired_seeker_card(player_id: int, expired_card: Card, piece_pos: Vector2) -> void:
	CardEffectResolver.clear_seeker_position_if_needed(game_state, player_id, true)
	return_card_to_player_deck(player_id, expired_card, "expired_seeker", piece_pos)

func consume_moved_piece_duration(player_id: int, piece: Piece, piece_pos: Vector2) -> void:
	if piece == null or piece.attached_card == null:
		return

	var expired_card: Card = piece.use_turn()
	if expired_card == null:
		return

	if MoveRules.is_seeker_card(expired_card):
		handle_expired_seeker_card(player_id, expired_card, piece_pos)
		return

	register_card_expiration(player_id, expired_card, piece_pos)
	log_card_expired(player_id, expired_card, piece, piece_pos)
	CardEffectResolver.resolve_trigger(CardEffect.TRIGGER_ON_EXPIRE, game_state, {
		"player_id": player_id,
		"piece": piece,
		"piece_pos": piece_pos,
		"card": expired_card,
	})

func respawn_captured_piece(captured_piece: Piece, player_id: int) -> bool:
	return CardEffectResolver.respawn_captured_piece(game_state, captured_piece, player_id)

func release_pending_respawn_piece(player_id: int) -> bool:
	return CardEffectResolver.release_pending_respawn_piece(game_state, player_id)

func get_random_empty_home_position(player_id: int) -> Vector2:
	return CardEffectResolver.get_random_empty_home_position(game_state, player_id)

func maybe_auto_end_turn(player_id: int) -> bool:
	return false

func is_first_turn_for_player(player_id: int) -> bool:
	return int(game_state.completed_turn_counts.get(player_id, 0)) == 0

func player_has_remaining_turn_action(player_id: int) -> bool:
	if can_attach_any_card_for_player(player_id):
		return true
	if can_move_any_piece_for_player(player_id):
		return true
	if can_turn_page_for_player(player_id):
		return true
	return false

func can_attach_any_card_for_player(player_id: int) -> bool:
	if !game_state.player_hands.has(player_id):
		return false

	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	var hand_cards: Array[Card] = get_hand_cards_for_player(player_id)
	if hand_cards.is_empty():
		return false

	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != player_color or piece.attached_card != null:
			continue

		for card: Card in hand_cards:
			if !MoveRules.card_can_be_used(card):
				continue
			if MoveRules.can_attach_card_for_turn(game_state.pieces, player_color, card):
				return true

	return false

func can_move_any_piece_for_player(player_id: int) -> bool:
	if bool(game_state.moved_piece_this_turn.get(player_id, false)):
		return false

	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	return MoveRules.has_valid_piece_move(game_state.pieces, player_color, BoardConfig.BOARD_SIZE, game_state.board_effects)

func finish_game(winner_player: int, win_condition: String = "unknown"):
	game_state.game_over = true
	game_state.winner_player = winner_player
	game_state.win_condition = win_condition
	if game_state.match_logger != null:
		game_state.match_logger.log_match_end(game_state, win_condition)

func finish_if_player_has_no_valid_turn(player_id: int) -> bool:
	if game_state.game_over:
		return false
	if player_has_valid_turn_action(player_id):
		return false

	var winner_player: int = 1 - player_id
	DebugLog.info("No valid moves: losing player=%d, winning player=%d" % [player_id, winner_player])
	finish_game(winner_player, "no_valid_move")
	return true

func player_has_valid_turn_action(player_id: int) -> bool:
	if is_first_turn_for_player(player_id):
		return int(game_state.attached_card_count_this_turn.get(player_id, 0)) > 0 or can_attach_any_card_for_player(player_id) or can_turn_page_for_player(player_id)
	if can_move_any_piece_for_player(player_id):
		return true
	if can_attach_any_card_for_player(player_id):
		return true
	if can_turn_page_for_player(player_id):
		return true
	if can_end_turn_due_to_frozen_piece(player_id):
		return true
	return false

func can_end_turn_by_button(player_id: int) -> bool:
	if is_first_turn_for_player(player_id):
		return int(game_state.attached_card_count_this_turn.get(player_id, 0)) >= 1
	return can_end_turn_due_to_frozen_piece(player_id)

func can_end_turn_due_to_frozen_piece(player_id: int) -> bool:
	if can_move_any_piece_for_player(player_id):
		return false
	var player_color: int = BoardConfig.get_color_for_player_id(player_id)
	return MoveRules.has_frozen_movable_piece(game_state.pieces, player_color, BoardConfig.BOARD_SIZE, game_state.board_effects)

func can_exchange_card_for_player(player_id: int) -> bool:
	return false

func can_turn_page_for_player(player_id: int) -> bool:
	if game_state == null:
		return false
	return game_state.can_turn_page(player_id)

func draw_exchange_replacement_card(deck: Array, returned_card_name: String) -> String:
	return draw_card_from_deck_avoiding_names(deck, [returned_card_name])

func draw_refill_card_for_player(player_id: int, deck: Array) -> String:
	var protected_names: Array = game_state.exchanged_card_names_this_turn.get(player_id, [])
	return draw_card_from_deck_avoiding_names(deck, protected_names)

func draw_card_from_deck_avoiding_names(deck: Array, avoided_card_names: Array) -> String:
	if deck.is_empty():
		return ""

	var draw_index: int = -1
	for i in deck.size():
		var candidate_name: String = str(deck[i])
		if !avoided_card_names.has(candidate_name):
			draw_index = i
			break
	if draw_index == -1:
		draw_index = 0

	var drawn_card_name: String = str(deck[draw_index])
	deck.remove_at(draw_index)
	return drawn_card_name

func record_exchanged_card_name_this_turn(player_id: int, card_name: String) -> void:
	var exchanged_names: Array = game_state.exchanged_card_names_this_turn.get(player_id, [])
	exchanged_names.append(card_name)
	game_state.exchanged_card_names_this_turn[player_id] = exchanged_names

func clear_exchanged_card_names_this_turn(player_id: int) -> void:
	game_state.exchanged_card_names_this_turn[player_id] = []

func should_hold_turn_for_optional_exchange(player_id: int) -> bool:
	return false

func is_seeker_piece(piece: Piece) -> bool:
	return piece != null && MoveRules.is_seeker_card(piece.attached_card)

func get_hand_cards_for_player(player_id: int) -> Array[Card]:
	var hand_cards: Array[Card] = []
	if !game_state.player_hands.has(player_id):
		return hand_cards

	var hand_card_names: Array = game_state.player_hands[player_id]
	for card_name_value in hand_card_names:
		var card_name: String = str(card_name_value)
		var card: Card = CardLibrary.get_card(card_name)
		if card != null:
			hand_cards.append(card)

	return hand_cards

func has_any_piece(player_id: int) -> bool:
	var expected_color: int = BoardConfig.get_color_for_player_id(player_id)
	return MoveRules.has_any_piece(game_state.pieces, expected_color)

func is_valid_move(_piece: Piece, from_pos: Vector2, to_pos: Vector2, player_id: int) -> bool:
	return MoveRules.is_valid_move_for_player(game_state.pieces, from_pos, to_pos, player_id, BoardConfig.BOARD_SIZE, game_state.board_effects)

func broadcast_full_state():
	DebugLog.info("Broadcasting full state")
	if multiplayer_node == null or !is_instance_valid(multiplayer_node):
		DebugLog.info("State broadcast skipped: multiplayer node is no longer available")
		return

	var local_viewer_player_id: int = get_viewer_player_id_for_peer(1)
	var local_state_data: Dictionary = serialize_state_for_player(local_viewer_player_id)
	var match_board = multiplayer_node.get_node_or_null("MatchBoard")

	if match_board != null:
		var pieces_data = {}
		for piece_data in local_state_data.pieces:
			var pos = Vector2(piece_data.position[0], piece_data.position[1])
			pieces_data[pos] = {
				"position": pos,
				"color": piece_data.color,
				"card_name": piece_data.card_name,
				"turns_remaining": piece_data.turns_remaining,
				"exhausted_this_turn": piece_data.exhausted_this_turn,
				"respawn_cooldown_turns": int(piece_data.get("respawn_cooldown_turns", 0)),
				"hidden_from_viewer": bool(piece_data.get("hidden_from_viewer", false))
			}
		match_board.update_from_server_state(
			pieces_data,
			local_state_data.player_hands,
			local_state_data.current_turn,
			local_state_data.game_over,
			local_state_data.winner_player,
			local_state_data.player_decks_size,
			local_state_data.player_codex_state,
			local_state_data.hidden_cards,
			local_state_data.player_base_fields,
			local_state_data.board_effects,
			local_state_data.player_names,
			local_state_data.recent_card_transfers,
			local_state_data.recent_card_expirations,
			local_state_data.recent_bomb_effects,
			local_state_data.recent_pending_respawn_queues,
			local_state_data.recent_pending_respawn_arrivals,
			local_state_data.last_move,
			local_state_data.player_portraits,
			int(local_state_data.get("viewer_player_id", -1)),
			local_state_data.turn_action_state,
			local_state_data.player_clock_seconds
		)

	for peer_id in multiplayer_node.connected_peer_ids:
		if peer_id != 1:
			var viewer_player_id: int = get_viewer_player_id_for_peer(peer_id)
			var peer_state_data: Dictionary = serialize_state_for_player(viewer_player_id)
			multiplayer_node.receive_game_state.rpc_id(peer_id, peer_state_data)

	if multiplayer_node.has_method("on_host_state_changed"):
		multiplayer_node.on_host_state_changed()

	if codex_bridge != null:
		codex_bridge.export_state(self, "broadcast")

	game_state.recent_card_transfers.clear()
	game_state.recent_card_expirations.clear()
	game_state.recent_bomb_effects.clear()
	game_state.recent_pending_respawn_queues.clear()
	game_state.recent_pending_respawn_arrivals.clear()
	DebugLog.info("State broadcast complete")

func serialize_state() -> Dictionary:
	return serialize_state_for_player(-1)

func serialize_state_for_player(viewer_player_id: int) -> Dictionary:
	var data = {
		"viewer_player_id": viewer_player_id,
		"pieces": [],
		"hidden_cards": [],
		"player_hands": game_state.player_hands,
		"player_decks_size": {
			0: game_state.get_remaining_codex_stamp_count(0),
			1: game_state.get_remaining_codex_stamp_count(1)
		},
		"player_codex_state": serialize_player_codex_state(),
		"current_turn": game_state.current_turn_player,
		"game_over": game_state.game_over,
		"winner_player": game_state.winner_player,
		"player_base_fields": serialize_player_base_fields(),
		"board_effects": serialize_board_effects(),
		"player_names": get_serialized_player_names(),
		"player_portraits": get_serialized_player_portraits(),
		"recent_card_transfers": serialize_recent_card_transfers(viewer_player_id),
		"recent_card_expirations": serialize_recent_card_expirations(),
		"recent_bomb_effects": serialize_recent_bomb_effects(),
		"recent_pending_respawn_queues": serialize_recent_pending_respawn_queues(),
		"recent_pending_respawn_arrivals": serialize_recent_pending_respawn_arrivals(),
		"last_move": serialize_last_move_for_player(viewer_player_id),
		"turn_action_state": serialize_turn_action_state(),
		"player_clock_seconds": game_state.player_clock_seconds.duplicate(),
	}

	for pos in game_state.pieces:
		var piece: Piece = game_state.pieces[pos]
		var hidden_from_viewer: bool = viewer_player_id != -1 && !CardEffectResolver.is_piece_visible_to_player(piece, viewer_player_id)
		if hidden_from_viewer:
			append_hidden_card_data(data["hidden_cards"], piece)
		data.pieces.append({
			"position": [pos.x, pos.y],
			"color": piece.color,
			"card_name": "" if hidden_from_viewer else (piece.attached_card.card_name if piece.attached_card else ""),
			"turns_remaining": 0 if hidden_from_viewer else piece.turns_remaining,
			"exhausted_this_turn": true if hidden_from_viewer else piece.exhausted_this_turn,
			"respawn_cooldown_turns": piece.respawn_cooldown_turns,
			"hidden_from_viewer": hidden_from_viewer,
		})

	return data

func serialize_turn_action_state() -> Dictionary:
	return {
		"attached_card_this_turn": duplicate_bool_dictionary(game_state.attached_card_this_turn),
		"moved_piece_this_turn": duplicate_bool_dictionary(game_state.moved_piece_this_turn),
		"exchanged_card_this_turn": duplicate_bool_dictionary(game_state.exchanged_card_this_turn),
		"has_turned_page_this_turn": duplicate_bool_dictionary(game_state.has_turned_page_this_turn),
		"attached_card_count_this_turn": game_state.attached_card_count_this_turn.duplicate(),
		"completed_turn_counts": game_state.completed_turn_counts.duplicate(),
	}

func serialize_player_codex_state() -> Dictionary:
	return {
		0: {
			"current_page_index": game_state.get_current_page_index(0),
			"page_counts": game_state.get_page_stamp_counts(0),
			"pages": serialize_codex_pages_for_player(0),
			"has_turned_page_this_turn": bool(game_state.has_turned_page_this_turn.get(0, false)),
		},
		1: {
			"current_page_index": game_state.get_current_page_index(1),
			"page_counts": game_state.get_page_stamp_counts(1),
			"pages": serialize_codex_pages_for_player(1),
			"has_turned_page_this_turn": bool(game_state.has_turned_page_this_turn.get(1, false)),
		},
	}

func serialize_codex_pages_for_player(player_id: int) -> Array:
	var serialized_pages: Array = []
	var pages: Array = game_state.get_codex_pages(player_id)
	for page_index in range(DeckManager.CODEX_PAGE_COUNT):
		var serialized_page: Array[String] = []
		if page_index < pages.size() and pages[page_index] is Array:
			for card_name_value in pages[page_index]:
				serialized_page.append(str(card_name_value))
		serialized_pages.append(serialized_page)
	return serialized_pages

func duplicate_bool_dictionary(source: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for key in source:
		output[key] = bool(source[key])
	return output

func serialize_recent_card_transfers(_viewer_player_id: int) -> Array:
	var serialized_transfers: Array = []
	for transfer_value in game_state.recent_card_transfers:
		var transfer: Dictionary = transfer_value
		var source_pos: Vector2 = CardEffectResolver.as_vector2(transfer.get("source_pos", [-1, -1]), Vector2(-1, -1))
		serialized_transfers.append({
			"source_player_id": int(transfer.get("source_player_id", -1)),
			"target_player_id": int(transfer.get("target_player_id", -1)),
			"card_name": str(transfer.get("card_name", "")),
			"source_zone": str(transfer.get("source_zone", "")),
			"target_zone": str(transfer.get("target_zone", "")),
			"source_pos": vector2_to_array(source_pos),
		})

	return serialized_transfers

func serialize_recent_card_expirations() -> Array:
	var serialized_expirations: Array = []
	for expiration_value in game_state.recent_card_expirations:
		var expiration: Dictionary = expiration_value
		var piece_pos: Vector2 = CardEffectResolver.as_vector2(expiration.get("piece_pos", [-1, -1]), Vector2(-1, -1))
		serialized_expirations.append({
			"player_id": int(expiration.get("player_id", -1)),
			"card_name": str(expiration.get("card_name", "")),
			"piece_pos": vector2_to_array(piece_pos),
		})

	return serialized_expirations

func serialize_recent_bomb_effects() -> Array:
	var serialized_effects: Array = []
	for effect_value in game_state.recent_bomb_effects:
		var effect: Dictionary = effect_value
		var serialized_squares: Array = []
		var squares: Array = effect.get("squares", [])
		for square_value in squares:
			serialized_squares.append(vector2_to_array(CardEffectResolver.as_vector2(square_value, Vector2(-1, -1))))

		var serialized_affected_positions: Array = []
		var affected_positions: Array = effect.get("affected_positions", [])
		for position_value in affected_positions:
			serialized_affected_positions.append(vector2_to_array(CardEffectResolver.as_vector2(position_value, Vector2(-1, -1))))

		serialized_effects.append({
			"player_id": int(effect.get("player_id", -1)),
			"card_name": str(effect.get("card_name", "")),
			"source_pos": vector2_to_array(CardEffectResolver.as_vector2(effect.get("source_pos", Vector2(-1, -1)), Vector2(-1, -1))),
			"squares": serialized_squares,
			"affected_positions": serialized_affected_positions,
		})

	return serialized_effects

func serialize_recent_pending_respawn_queues() -> Array:
	var serialized_queues: Array = []
	for queue_value in game_state.recent_pending_respawn_queues:
		var queue_event: Dictionary = queue_value
		serialized_queues.append({
			"player_id": int(queue_event.get("player_id", -1)),
			"piece_color": int(queue_event.get("piece_color", 0)),
			"source_pos": vector2_to_array(CardEffectResolver.as_vector2(queue_event.get("source_pos", Vector2(-1, -1)), Vector2(-1, -1))),
		})

	return serialized_queues

func serialize_recent_pending_respawn_arrivals() -> Array:
	var serialized_arrivals: Array = []
	for arrival_value in game_state.recent_pending_respawn_arrivals:
		var arrival: Dictionary = arrival_value
		serialized_arrivals.append({
			"player_id": int(arrival.get("player_id", -1)),
			"piece_color": int(arrival.get("piece_color", 0)),
			"respawn_pos": vector2_to_array(CardEffectResolver.as_vector2(arrival.get("respawn_pos", Vector2(-1, -1)), Vector2(-1, -1))),
			"respawn_cooldown_turns": int(arrival.get("respawn_cooldown_turns", 0)),
		})

	return serialized_arrivals

func serialize_last_move_for_player(viewer_player_id: int) -> Dictionary:
	if game_state.last_move.is_empty():
		return {}

	var mover_player_id: int = int(game_state.last_move.get("player_id", -1))
	var is_mover_viewer: bool = viewer_player_id != -1 && mover_player_id == viewer_player_id
	if viewer_player_id != -1 && !is_mover_viewer && !bool(game_state.last_move.get("visible_to_enemy", true)):
		return {}

	var from_pos: Vector2 = CardEffectResolver.as_vector2(game_state.last_move.get("from", Vector2(-1, -1)), Vector2(-1, -1))
	var to_pos: Vector2 = CardEffectResolver.as_vector2(game_state.last_move.get("to", Vector2(-1, -1)), Vector2(-1, -1))
	if from_pos == Vector2(-1, -1) or to_pos == Vector2(-1, -1) or from_pos == to_pos:
		return {}

	var moving_piece: Piece = game_state.get_piece(to_pos)
	if moving_piece == null:
		return {}
	if viewer_player_id != -1 && !is_mover_viewer && !CardEffectResolver.is_piece_visible_to_player(moving_piece, viewer_player_id):
		return {}

	var serialized_last_move := {
		"from": vector2_to_array(from_pos),
		"to": vector2_to_array(to_pos),
		"player_id": mover_player_id,
		"piece_color": int(game_state.last_move.get("piece_color", CardEffectResolver.get_color_for_player_id(mover_player_id))),
		"visible_to_enemy": bool(game_state.last_move.get("visible_to_enemy", true)),
		"show_arrow": !is_mover_viewer,
	}
	if int(game_state.last_move.get("captured_piece_color", 0)) != 0:
		serialized_last_move["captured_piece_color"] = int(game_state.last_move.get("captured_piece_color", 0))
		serialized_last_move["captured_card_name"] = str(game_state.last_move.get("captured_card_name", ""))
	return serialized_last_move

func append_hidden_card_data(hidden_cards: Array, piece: Piece) -> void:
	if piece == null or piece.attached_card == null:
		return

	hidden_cards.append({
		"card_name": piece.attached_card.card_name,
		"turns_remaining": piece.turns_remaining,
		"owner_player_id": CardEffectResolver.get_player_id_for_color(piece.color),
	})

func get_viewer_player_id_for_peer(peer_id: int) -> int:
	if multiplayer_node == null or !is_instance_valid(multiplayer_node):
		return 0
	if multiplayer_node.peer_player_ids.has(peer_id):
		return int(multiplayer_node.peer_player_ids[peer_id])
	return 0

func serialize_player_base_fields() -> Dictionary:
	return {
		0: vector2_to_array(CardEffectResolver.get_base_field_for_player(game_state, 0)),
		1: vector2_to_array(CardEffectResolver.get_base_field_for_player(game_state, 1)),
	}

func serialize_board_effects() -> Array:
	var serialized_effects: Array = []
	for effect_value in game_state.board_effects:
		var effect: Dictionary = effect_value
		var serialized_squares: Array = []
		var squares: Array = effect.get("squares", [])
		for square_value in squares:
			serialized_squares.append(vector2_to_array(CardEffectResolver.as_vector2(square_value, Vector2(-1, -1))))

		serialized_effects.append({
			"effect_type": str(effect.get("effect_type", "")),
			"owner_player_id": int(effect.get("owner_player_id", -1)),
			"target_player_id": int(effect.get("target_player_id", -1)),
			"squares": serialized_squares,
			"turns_remaining": int(effect.get("turns_remaining", -1)),
		})

	return serialized_effects

func vector2_to_array(value: Vector2) -> Array:
	return [value.x, value.y]

func get_serialized_player_names() -> Dictionary:
	if multiplayer_node != null && multiplayer_node.has_method("get_player_names_by_id"):
		return multiplayer_node.get_player_names_by_id()

	return {
		0: "Player",
		1: "Player",
	}

func get_serialized_player_portraits() -> Dictionary:
	if multiplayer_node != null && multiplayer_node.has_method("get_player_portraits_by_id"):
		return multiplayer_node.get_player_portraits_by_id()

	return {
		0: PortraitLibrary.get_default_portrait_for_player_id(0).to_dict(),
		1: PortraitLibrary.get_default_portrait_for_player_id(1).to_dict(),
	}

func duplicate_player_card_list(source) -> Array:
	var output: Array = []
	if source is Array:
		for card_name_value in source:
			output.append(str(card_name_value))
	return output

func record_last_move(player_id: int, from_pos: Vector2, to_pos: Vector2, visible_to_enemy: bool, captured_piece: Piece = null) -> void:
	if from_pos == to_pos:
		game_state.last_move = {}
		return

	game_state.last_move = {
		"from": from_pos,
		"to": to_pos,
		"player_id": player_id,
		"piece_color": CardEffectResolver.get_color_for_player_id(player_id),
		"visible_to_enemy": visible_to_enemy,
	}
	if captured_piece != null:
		game_state.last_move["captured_piece_color"] = captured_piece.color
		game_state.last_move["captured_card_name"] = captured_piece.attached_card.card_name if captured_piece.attached_card != null else ""

func play_card_from_player_hand(player_id: int, card_name: String, hand_index: int) -> bool:
	if !game_state.player_hands.has(player_id):
		return false

	var hand: Array = game_state.player_hands[player_id]
	var remove_index: int = hand.find(card_name)
	if hand_index >= 0 && hand_index < hand.size() && str(hand[hand_index]) == card_name:
		remove_index = hand_index
	if remove_index == -1:
		return false

	var original_slot: int = get_original_hand_slot_for_play(player_id, remove_index)
	hand.remove_at(remove_index)
	game_state.player_hands[player_id] = hand
	record_played_card_hand_slot(player_id, original_slot)
	DebugLog.info("Card played: %s" % card_name)
	return true

func get_original_hand_slot_for_play(player_id: int, current_hand_index: int) -> int:
	var played_slots: Array = game_state.played_card_hand_slots_this_turn.get(player_id, [])
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

func record_played_card_hand_slot(player_id: int, hand_slot: int) -> void:
	var played_slots: Array = game_state.played_card_hand_slots_this_turn.get(player_id, [])
	played_slots.append(clampi(hand_slot, 0, DeckManager.HAND_SIZE - 1))
	game_state.played_card_hand_slots_this_turn[player_id] = played_slots

func refill_played_cards_for_player(player_id: int) -> void:
	var played_slots: Array = game_state.played_card_hand_slots_this_turn.get(player_id, [])
	if played_slots.is_empty():
		clear_exchanged_card_names_this_turn(player_id)
		return
	if !game_state.player_decks.has(player_id) or !game_state.player_hands.has(player_id):
		game_state.played_card_hand_slots_this_turn[player_id] = []
		clear_exchanged_card_names_this_turn(player_id)
		return

	played_slots.sort()
	var deck: Array = game_state.player_decks[player_id]
	var hand: Array = game_state.player_hands[player_id]
	for slot_value in played_slots:
		if deck.is_empty() or hand.size() >= DeckManager.HAND_SIZE:
			break

		var hand_before: Array = duplicate_player_card_list(hand)
		var deck_before: Array = duplicate_player_card_list(deck)
		var deck_top_before: String = str(deck_before[0]) if !deck_before.is_empty() else ""
		var drawn_card_name: String = draw_refill_card_for_player(player_id, deck)
		if drawn_card_name.is_empty():
			break
		var insert_index: int = clampi(int(slot_value), 0, hand.size())
		hand.insert(insert_index, drawn_card_name)
		CardEffectResolver.register_card_transfer(game_state, player_id, player_id, drawn_card_name, "deck", "hand")
		log_card_drawn(player_id, drawn_card_name, hand_before, deck_before, deck_top_before, "hand", "turn_end_refill")

	game_state.player_decks[player_id] = deck
	game_state.player_hands[player_id] = hand
	game_state.played_card_hand_slots_this_turn[player_id] = []
	clear_exchanged_card_names_this_turn(player_id)

func return_card_to_player_deck(player_id: int, card: Card, reason: String, piece_pos: Vector2 = Vector2(-1, -1)) -> void:
	if card == null:
		return
	var page_index: int = int(card.get_meta("codex_page_index", -1))
	var stamp_index: int = int(card.get_meta("codex_stamp_index", -1))
	game_state.return_stamp_to_codex_page(player_id, card.card_name, page_index, stamp_index)
	CardEffectResolver.register_card_transfer(game_state, player_id, player_id, card.card_name, "piece", "codex", piece_pos)
	log_card_returned_to_deck(player_id, card, piece_pos, reason)

func player_has_available_seeker_card(player_id: int) -> bool:
	if game_state.player_hands.has(player_id) && DeckManager.has_seeker_card(game_state.player_hands[player_id]):
		return true
	if game_state.player_decks.has(player_id) && DeckManager.has_seeker_card(game_state.player_decks[player_id]):
		return true

	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null && piece.color == player_color && MoveRules.is_seeker_card(piece.attached_card):
			return true
	return false

func setup_logger_if_needed() -> MatchCsvLogger:
	return game_state.match_logger

func log_card_attached(player_id: int, card: Card, piece: Piece, piece_pos: Vector2, hand_before: Array, deck_before: Array, deck_top_before: String, piece_card_before: String, piece_turns_before: int) -> void:
	if game_state.match_logger == null:
		return

	var drawn_card: String = ""
	if deck_before.size() > game_state.player_decks[player_id].size():
		drawn_card = deck_top_before
	game_state.match_logger.log_card_event(game_state, "attach_card", {
		"player_id": player_id,
		"card": card,
		"piece": piece,
		"piece_pos": piece_pos,
		"piece_card_before": piece_card_before,
		"piece_turns_before": piece_turns_before,
		"hand_before": hand_before,
		"deck_count_before": deck_before.size(),
		"deck_top_before": deck_top_before,
		"drawn_card": drawn_card,
		"reason": "played_from_hand",
	})

func log_card_returned_to_deck(player_id: int, card: Card, piece_pos: Vector2, reason: String) -> void:
	if game_state.match_logger == null:
		return

	game_state.match_logger.log_card_event(game_state, "return_to_deck", {
		"player_id": player_id,
		"card": card,
		"piece_pos": piece_pos,
		"returned_card": card.card_name if card != null else "",
		"target_zone": "codex",
		"reason": reason,
	})

func log_card_drawn(player_id: int, drawn_card_name: String, hand_before: Array, deck_before: Array, deck_top_before: String, target_zone: String = "hand", reason: String = "turn_end_refill") -> void:
	if game_state.match_logger == null:
		return

	var drawn_card: Card = CardLibrary.get_card(drawn_card_name)
	game_state.match_logger.log_card_event(game_state, "draw_card", {
		"player_id": player_id,
		"card": drawn_card,
		"card_name": drawn_card_name,
		"hand_before": hand_before,
		"deck_count_before": deck_before.size(),
		"deck_top_before": deck_top_before,
		"drawn_card": drawn_card_name,
		"source_zone": "deck",
		"target_zone": target_zone,
		"reason": reason,
	})

func log_card_expired(player_id: int, card: Card, piece: Piece, piece_pos: Vector2) -> void:
	if game_state.match_logger == null:
		return

	game_state.match_logger.log_card_event(game_state, "expire_card", {
		"player_id": player_id,
		"card": card,
		"piece": piece,
		"piece_pos": piece_pos,
		"reason": "duration_ended",
	})

func register_card_expiration(player_id: int, card: Card, piece_pos: Vector2) -> void:
	if card == null:
		return

	game_state.recent_card_expirations.append({
		"player_id": player_id,
		"card_name": card.card_name,
		"piece_pos": piece_pos,
	})

func create_move_log_context(player_id: int, from_pos: Vector2, to_pos: Vector2, piece: Piece, captured_piece: Piece) -> Dictionary:
	if game_state.match_logger == null:
		return {}
	return game_state.match_logger.create_move_context(game_state, player_id, from_pos, to_pos, piece, captured_piece)

func log_move_result(move_log_context: Dictionary, win_condition_after: String) -> void:
	if game_state.match_logger == null or move_log_context.is_empty():
		return
	game_state.match_logger.log_move_event(game_state, move_log_context, win_condition_after)

func advance_logged_turn() -> void:
	if game_state.match_logger == null:
		return
	game_state.match_logger.advance_turn()

func log_turn_snapshot(event_type: String) -> void:
	if game_state.match_logger == null:
		return
	game_state.match_logger.log_turn_snapshot(game_state, event_type)
