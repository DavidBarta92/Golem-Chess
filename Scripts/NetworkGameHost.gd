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

	game_state.player_decks[0] = white_deck
	game_state.player_decks[1] = black_deck

	var white_hand: Array[String] = []
	var black_hand: Array[String] = []

	DeckManager.draw_starting_hand(white_deck, white_hand)
	DeckManager.draw_starting_hand(black_deck, black_hand)

	game_state.player_hands[0] = white_hand
	game_state.player_hands[1] = black_hand

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
	var player_id = action.player_id
	var card_name = action.card_name
	var piece_pos = action.piece_pos

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
		piece.attach_card(card)

		if card_name == "King":
			if player_id == 0:
				game_state.white_king_position = piece_pos
			else:
				game_state.black_king_position = piece_pos

		DeckManager.play_card(game_state.player_hands[player_id], card_name, game_state.player_decks[player_id])
		game_state.attached_card_this_turn[player_id] = true
		CardEffectResolver.resolve_trigger(CardEffect.TRIGGER_ON_ATTACH, game_state, {
			"player_id": player_id,
			"piece": piece,
			"piece_pos": piece_pos,
			"card": card,
		})
		finish_if_player_has_no_valid_turn(player_id)

		print("Card attached successfully")
		broadcast_full_state()

func handle_move_piece(action: Dictionary):
	var player_id = action.player_id
	var from_pos = action.from
	var to_pos = action.to

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
				broadcast_full_state()
				return
			if game_state.get_piece(from_pos) != piece:
				game_state.switch_turn()
				CardEffectResolver.tick_board_effects(game_state)
				finish_if_player_has_no_valid_turn(game_state.current_turn_player)
				broadcast_full_state()
				return

		if captured_king:
			print("King captured. Player %d wins." % player_id)

		if !captured_king && captured_piece.attached_card != null && captured_piece.turns_remaining > 0:
			var enemy_player = 1 - player_id
			DeckManager.return_card_to_deck(game_state.player_decks[enemy_player], captured_piece.attached_card.card_name)

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
		finish_game(player_id)
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
			broadcast_full_state()
			return

	var opponent_base_field: Vector2 = CardEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var entered_opponent_base: bool = to_pos == opponent_base_field
	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	if is_king_piece(piece) && piece.color == player_color && entered_opponent_base:
		print("Opponent base reached by king. Player %d wins." % player_id)
		finish_game(player_id)
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
			broadcast_full_state()
			return

	var expired_card: Card = piece.use_turn()
	if expired_card != null:
		CardEffectResolver.resolve_trigger(CardEffect.TRIGGER_ON_EXPIRE, game_state, {
			"player_id": player_id,
			"piece": piece,
			"piece_pos": to_pos,
			"card": expired_card,
		})
		if game_state.game_over:
			broadcast_full_state()
			return

	game_state.switch_turn()
	CardEffectResolver.tick_board_effects(game_state)
	finish_if_player_has_no_valid_turn(game_state.current_turn_player)

	print("Move complete. Next player: ", game_state.current_turn_player)

	broadcast_full_state()

func finish_game(winner_player: int):
	game_state.game_over = true
	game_state.winner_player = winner_player

func finish_if_player_has_no_valid_turn(player_id: int) -> bool:
	if game_state.game_over:
		return false
	if player_has_valid_turn_action(player_id):
		return false

	var winner_player: int = 1 - player_id
	print("No valid moves: losing player=%d, winning player=%d" % [player_id, winner_player])
	finish_game(winner_player)
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
			local_state_data.board_effects
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
