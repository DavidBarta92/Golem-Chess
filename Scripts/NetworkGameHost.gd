class_name NetworkGameHost

var game_state: GameStateData
var multiplayer_node

func _init(mp_node):
	multiplayer_node = mp_node
	game_state = GameStateData.new()

func initialize_game(board_data: Array):
	for i in range(board_data.size()):
		for j in range(board_data[i].size()):
			var value = board_data[i][j]
			if value != 0:
				var pos = Vector2(i, j)
				var color = 1 if value > 0 else -1
				var piece = Piece.new(pos, color)
				game_state.set_piece(pos, piece)

	var white_deck: Array[String] = []
	white_deck.assign(DeckManager.create_starting_deck())
	var black_deck: Array[String] = []
	black_deck.assign(DeckManager.create_starting_deck())
	var white_initial_deck: Array[String] = []
	white_initial_deck.assign(white_deck)
	var black_initial_deck: Array[String] = []
	black_initial_deck.assign(black_deck)

	game_state.player_initial_decks[0] = white_initial_deck
	game_state.player_initial_decks[1] = black_initial_deck
	game_state.player_decks[0] = white_deck
	game_state.player_decks[1] = black_deck

	var white_hand: Array[String] = []
	var black_hand: Array[String] = []

	DeckManager.draw_starting_hand(white_deck, white_hand)
	DeckManager.draw_starting_hand(black_deck, black_hand)

	game_state.player_hands[0] = white_hand
	game_state.player_hands[1] = black_hand
	setup_match_logging()

	print("NetworkGameHost: game state initialized")

	var white_first_piece_pos = Vector2(0, 1)
	var black_first_piece_pos = Vector2(4, 2)

	var white_piece = game_state.get_piece(white_first_piece_pos)
	var black_piece = game_state.get_piece(black_first_piece_pos)

	if false && white_piece:
		var king_card = CardLibrary.get_card("King")
		if king_card:
			white_piece.attach_card(king_card)
			white_piece.turns_remaining = -1
			game_state.white_king_position = white_first_piece_pos
			print("White king added: ", white_first_piece_pos)

	if false && black_piece:
		var king_card = CardLibrary.get_card("King")
		if king_card:
			black_piece.attach_card(king_card)
			black_piece.turns_remaining = -1
			game_state.black_king_position = black_first_piece_pos
			print("Black king added: ", black_first_piece_pos)

	broadcast_full_state()

func setup_match_logging() -> void:
	if !GameConfig.is_ai_vs_ai_batch:
		return

	game_state.match_logger = MatchCsvLogger.new()
	game_state.match_logger.start_match(game_state)

func on_player_action(action: Dictionary):
	print("Action received: ", action)

	match action.type:
		"attach_card":
			handle_attach_card(action)
		"move_piece":
			handle_move_piece(action)
		_:
			push_warning("Unknown action type: ", action.type)

func handle_attach_card(action: Dictionary):
	var player_id: int = int(action.player_id)
	var card_name: String = str(action.card_name)
	var piece_pos: Vector2 = CardEffectResolver.as_vector2(action.piece_pos, Vector2(-1, -1))

	print("Attach card: player=%s, card=%s, position=%s" % [player_id, card_name, piece_pos])

	if game_state.game_over:
		return
	if game_state.current_turn_player != player_id:
		return
	if bool(game_state.attached_card_this_turn.get(player_id, false)):
		return

	if !game_state.player_hands[player_id].has(card_name):
		push_warning("Card is not in hand.")
		return

	var piece = game_state.get_piece(piece_pos)
	if piece == null:
		push_warning("No piece at this position.")
		return

	var expected_color = 1 if player_id == 0 else -1
	if piece.color != expected_color:
		push_warning("This piece does not belong to the player.")
		return

	if piece.attached_card != null:
		push_warning("This piece already has a card.")
		return
	if !can_attach_card_name(player_id, card_name):
		push_warning("The King card must be played first.")
		return

	var card = CardLibrary.get_card(card_name)
	if card:
		var hand_before: Array = duplicate_player_card_list(game_state.player_hands[player_id])
		var deck_before: Array = duplicate_player_card_list(game_state.player_decks[player_id])
		var deck_top_before: String = str(deck_before[0]) if !deck_before.is_empty() else ""
		var piece_card_before: String = piece.attached_card.card_name if piece.attached_card != null else ""
		var piece_turns_before: int = piece.turns_remaining
		piece.attach_card(card)

		if card_name == "King":
			if player_id == 0:
				game_state.white_king_position = piece_pos
			else:
				game_state.black_king_position = piece_pos

		DeckManager.play_card(game_state.player_hands[player_id], card_name, game_state.player_decks[player_id])
		game_state.attached_card_this_turn[player_id] = true
		log_card_attached(player_id, card, piece, piece_pos, hand_before, deck_before, deck_top_before, piece_card_before, piece_turns_before)
		CardEffectResolver.resolve_trigger(CardEffect.TRIGGER_ON_ATTACH, game_state, {
			"player_id": player_id,
			"piece": piece,
			"piece_pos": piece_pos,
			"card": card,
		})
		finish_if_player_has_no_valid_turn(player_id)
		log_turn_snapshot("after_attach")

		print("Card attached successfully")
		broadcast_full_state()

func handle_move_piece(action: Dictionary):
	var player_id: int = int(action.player_id)
	var from_pos: Vector2 = CardEffectResolver.as_vector2(action.from, Vector2(-1, -1))
	var to_pos: Vector2 = CardEffectResolver.as_vector2(action.to, Vector2(-1, -1))

	print("Move: player=%s, %s -> %s" % [player_id, from_pos, to_pos])

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

	if !is_valid_move(piece, from_pos, to_pos, player_id):
		push_warning("Invalid move.")
		return

	var captured_piece = game_state.get_piece(to_pos)
	var captured_king: bool = is_king_piece(captured_piece)
	var move_log_context: Dictionary = create_move_log_context(player_id, from_pos, to_pos, piece, captured_piece)

	if captured_piece != null:
		print("Piece captured at: ", to_pos)
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
				game_state.switch_turn()
				advance_logged_turn()
				CardEffectResolver.tick_board_effects(game_state)
				finish_if_player_has_no_valid_turn(game_state.current_turn_player)
				log_turn_snapshot("turn_end")
				broadcast_full_state()
				return

		if captured_king:
			print("King captured. Player %d wins." % player_id)

		if !captured_king && captured_piece.attached_card != null && captured_piece.turns_remaining > 0:
			var enemy_player = 1 - player_id
			DeckManager.return_card_to_deck(game_state.player_decks[enemy_player], captured_piece.attached_card.card_name)
			log_card_returned_to_deck(enemy_player, captured_piece.attached_card, to_pos, "captured_piece")

	game_state.remove_piece(from_pos)
	piece.position = to_pos
	game_state.set_piece(to_pos, piece)

	if piece.attached_card != null && piece.attached_card.card_name == "King":
		var moved_piece_owner_player_id: int = CardEffectResolver.get_player_id_for_color(piece.color)
		if moved_piece_owner_player_id == 0:
			game_state.white_king_position = to_pos
		else:
			game_state.black_king_position = to_pos

	if captured_king:
		finish_game(player_id, "king_capture")
		log_move_result(move_log_context, game_state.win_condition)
		broadcast_full_state()
		return

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

	var opponent_base_field: Vector2 = CardEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var entered_opponent_base: bool = to_pos == opponent_base_field
	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	if is_king_piece(piece) && piece.color == player_color && entered_opponent_base:
		print("Opponent base reached by king. Player %d wins." % player_id)
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

	var expired_card: Card = piece.use_turn()
	if expired_card != null:
		log_card_expired(player_id, expired_card, piece, to_pos)
		CardEffectResolver.resolve_trigger(CardEffect.TRIGGER_ON_EXPIRE, game_state, {
			"player_id": player_id,
			"piece": piece,
			"piece_pos": to_pos,
			"card": expired_card,
		})
		if game_state.game_over:
			log_move_result(move_log_context, game_state.win_condition)
			broadcast_full_state()
			return

	log_move_result(move_log_context, "")
	game_state.switch_turn()
	advance_logged_turn()
	CardEffectResolver.tick_board_effects(game_state)
	finish_if_player_has_no_valid_turn(game_state.current_turn_player)
	log_turn_snapshot("turn_end")

	print("Move complete. Next player: ", game_state.current_turn_player)

	broadcast_full_state()

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
	print("No valid moves: losing player=%d, winning player=%d" % [player_id, winner_player])
	finish_game(winner_player, "no_valid_move")
	return true

func player_has_valid_turn_action(player_id: int) -> bool:
	var player_color: int = 1 if player_id == 0 else -1
	var can_attach_card: bool = !bool(game_state.attached_card_this_turn.get(player_id, false))
	var hand_cards: Array[Card] = get_hand_cards_for_player(player_id)
	return MoveRules.has_valid_turn_action(game_state.pieces, player_color, hand_cards, can_attach_card, 5, game_state.board_effects)

func can_attach_card_name(player_id: int, card_name: String) -> bool:
	var player_color: int = 1 if player_id == 0 else -1
	if MoveRules.has_attached_king(game_state.pieces, player_color):
		return true
	return card_name == MoveRules.KING_CARD_NAME

func is_king_piece(piece: Piece) -> bool:
	return piece != null && piece.attached_card != null && piece.attached_card.card_name == MoveRules.KING_CARD_NAME

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
	var expected_color: int = 1 if player_id == 0 else -1
	return MoveRules.has_any_piece(game_state.pieces, expected_color)

func is_valid_move(_piece: Piece, from_pos: Vector2, to_pos: Vector2, player_id: int) -> bool:
	return MoveRules.is_valid_move_for_player(game_state.pieces, from_pos, to_pos, player_id, 5, game_state.board_effects)

func broadcast_full_state():
	print("Broadcasting full state")

	var local_viewer_player_id: int = get_viewer_player_id_for_peer(1)
	var local_state_data: Dictionary = serialize_state_for_player(local_viewer_player_id)

	if multiplayer_node.has_node("board"):
		var pieces_data = {}
		for piece_data in local_state_data.pieces:
			var pos = Vector2(piece_data.position[0], piece_data.position[1])
			pieces_data[pos] = {
				"position": pos,
				"color": piece_data.color,
				"card_name": piece_data.card_name,
				"turns_remaining": piece_data.turns_remaining
			}
		multiplayer_node.get_node("board").update_from_server_state(
			pieces_data,
			local_state_data.player_hands,
			local_state_data.current_turn,
			local_state_data.game_over,
			local_state_data.winner_player,
			local_state_data.player_decks_size,
			local_state_data.hidden_cards,
			local_state_data.player_base_fields,
			local_state_data.board_effects,
			local_state_data.player_names
		)

	for peer_id in multiplayer_node.connected_peer_ids:
		if peer_id != 1:
			var viewer_player_id: int = get_viewer_player_id_for_peer(peer_id)
			var peer_state_data: Dictionary = serialize_state_for_player(viewer_player_id)
			multiplayer_node.receive_game_state.rpc_id(peer_id, peer_state_data)

	if multiplayer_node.has_method("on_host_state_changed"):
		multiplayer_node.on_host_state_changed()

	print("State broadcast complete")

func serialize_state() -> Dictionary:
	return serialize_state_for_player(-1)

func serialize_state_for_player(viewer_player_id: int) -> Dictionary:
	var data = {
		"pieces": [],
		"hidden_cards": [],
		"player_hands": game_state.player_hands,
		"player_decks_size": {
			0: game_state.player_decks[0].size(),
			1: game_state.player_decks[1].size()
		},
		"current_turn": game_state.current_turn_player,
		"game_over": game_state.game_over,
		"winner_player": game_state.winner_player,
		"player_base_fields": serialize_player_base_fields(),
		"board_effects": serialize_board_effects(),
		"player_names": get_serialized_player_names(),
	}

	for pos in game_state.pieces:
		var piece: Piece = game_state.pieces[pos]
		if viewer_player_id != -1 && !CardEffectResolver.is_piece_visible_to_player(piece, viewer_player_id):
			append_hidden_card_data(data["hidden_cards"], piece)
			continue
		data.pieces.append({
			"position": [pos.x, pos.y],
			"color": piece.color,
			"card_name": piece.attached_card.card_name if piece.attached_card else "",
			"turns_remaining": piece.turns_remaining
		})

	return data

func append_hidden_card_data(hidden_cards: Array, piece: Piece) -> void:
	if piece == null or piece.attached_card == null:
		return

	hidden_cards.append({
		"card_name": piece.attached_card.card_name,
		"turns_remaining": piece.turns_remaining,
		"owner_player_id": CardEffectResolver.get_player_id_for_color(piece.color),
	})

func get_viewer_player_id_for_peer(peer_id: int) -> int:
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

func duplicate_player_card_list(source) -> Array:
	var output: Array = []
	if source is Array:
		for card_name_value in source:
			output.append(str(card_name_value))
	return output

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
		"target_zone": "deck",
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
