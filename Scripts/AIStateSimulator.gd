extends RefCounted
class_name AIStateSimulator

static func clone_pieces(source_pieces: Dictionary) -> Dictionary:
	var cloned_pieces: Dictionary = {}
	for position_value in source_pieces:
		var position: Vector2 = CardEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = source_pieces[position_value] as Piece
		if piece == null:
			continue
		cloned_pieces[position] = clone_piece(piece)
	return cloned_pieces

static func clone_piece(piece: Piece) -> Piece:
	var cloned_piece: Piece = Piece.new(piece.position, piece.color)
	cloned_piece.attached_card = piece.attached_card
	cloned_piece.turns_remaining = piece.turns_remaining
	return cloned_piece

static func clone_game_state(source_state: GameStateData) -> GameStateData:
	var cloned_state: GameStateData = GameStateData.new()
	if source_state == null:
		return cloned_state

	cloned_state.pieces = clone_pieces(source_state.pieces)
	cloned_state.player_decks = duplicate_card_list_dictionary(source_state.player_decks)
	cloned_state.player_initial_decks = duplicate_card_list_dictionary(source_state.player_initial_decks)
	cloned_state.player_hands = duplicate_card_list_dictionary(source_state.player_hands)
	cloned_state.current_turn_player = source_state.current_turn_player
	cloned_state.white_king_position = source_state.white_king_position
	cloned_state.black_king_position = source_state.black_king_position
	cloned_state.player_base_fields = duplicate_vector2_dictionary(source_state.player_base_fields)
	cloned_state.board_effects = duplicate_board_effects(source_state.board_effects)
	cloned_state.recent_card_transfers = []
	cloned_state.recent_card_expirations = []
	cloned_state.attached_card_this_turn = source_state.attached_card_this_turn.duplicate()
	cloned_state.moved_piece_this_turn = source_state.moved_piece_this_turn.duplicate()
	cloned_state.drawn_card_this_turn = source_state.drawn_card_this_turn.duplicate()
	cloned_state.game_over = source_state.game_over
	cloned_state.winner_player = source_state.winner_player
	cloned_state.win_condition = source_state.win_condition
	cloned_state.match_logger = null
	return cloned_state

static func duplicate_card_list_dictionary(source: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for key in source:
		var source_list: Array = source[key]
		var duplicated_list: Array = []
		for card_name_value in source_list:
			duplicated_list.append(str(card_name_value))
		output[key] = duplicated_list
	return output

static func duplicate_vector2_dictionary(source: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for key in source:
		output[key] = CardEffectResolver.as_vector2(source[key], Vector2(-1, -1))
	return output

static func duplicate_board_effects(source_effects: Array) -> Array:
	var output: Array = []
	for effect_value in source_effects:
		var effect: Dictionary = effect_value
		var duplicated_squares: Array[Vector2] = []
		var squares: Array = effect.get("squares", [])
		for square_value in squares:
			duplicated_squares.append(CardEffectResolver.as_vector2(square_value, Vector2(-1, -1)))

		output.append({
			"effect_type": str(effect.get("effect_type", "")),
			"owner_player_id": int(effect.get("owner_player_id", -1)),
			"target_player_id": int(effect.get("target_player_id", -1)),
			"squares": duplicated_squares,
			"turns_remaining": int(effect.get("turns_remaining", -1)),
		})
	return output

static func apply_turn_plan(source_state: GameStateData, player_id: int, plan: Dictionary, board_size: int = 5) -> GameStateData:
	var simulated_state: GameStateData = clone_game_state(source_state)
	if simulated_state.game_over:
		return simulated_state

	simulated_state.current_turn_player = player_id
	var actions: Array = plan.get("actions", [])
	for action_value in actions:
		var action: Dictionary = action_value
		match str(action.get("type", "")):
			"draw_card":
				apply_draw_action(simulated_state, player_id)
			"attach_card":
				apply_attach_action(simulated_state, player_id, action, board_size)
			"move_piece":
				apply_move_action(simulated_state, player_id, action, board_size)
			"end_turn":
				break

		if simulated_state.game_over:
			return simulated_state

	end_simulated_turn(simulated_state, player_id, board_size)
	return simulated_state

static func apply_draw_action(game_state: GameStateData, player_id: int) -> void:
	if bool(game_state.drawn_card_this_turn.get(player_id, false)):
		return
	if !game_state.player_decks.has(player_id) or !game_state.player_hands.has(player_id):
		return

	var deck: Array = game_state.player_decks[player_id]
	var hand: Array = game_state.player_hands[player_id]
	if deck.is_empty():
		return

	var drawn_card_name: String = str(deck.pop_front())
	if hand.size() < DeckManager.HAND_SIZE:
		hand.append(drawn_card_name)
	game_state.player_decks[player_id] = deck
	game_state.player_hands[player_id] = hand
	game_state.drawn_card_this_turn[player_id] = true

static func apply_attach_action(game_state: GameStateData, player_id: int, action: Dictionary, board_size: int) -> void:
	if bool(game_state.attached_card_this_turn.get(player_id, false)):
		return

	var piece_pos: Vector2 = CardEffectResolver.as_vector2(action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
	var piece: Piece = game_state.get_piece(piece_pos)
	if piece == null or piece.attached_card != null:
		return

	var card_name: String = str(action.get("card_name", ""))
	var card: Card = CardLibrary.get_card(card_name)
	if card == null:
		return

	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	if piece.color != player_color or !MoveRules.can_attach_card_for_turn(game_state.pieces, player_color, card):
		return

	remove_card_name_from_hand(game_state, player_id, card_name)
	piece.attached_card = card
	piece.turns_remaining = card.duration
	game_state.attached_card_this_turn[player_id] = true
	simulate_trigger_effect(game_state, CardEffect.TRIGGER_ON_ATTACH, player_id, piece, piece_pos, card, board_size)

static func apply_move_action(game_state: GameStateData, player_id: int, action: Dictionary, board_size: int) -> void:
	if bool(game_state.moved_piece_this_turn.get(player_id, false)):
		return

	var from_pos: Vector2 = CardEffectResolver.as_vector2(action.get("from", Vector2(-1, -1)), Vector2(-1, -1))
	var to_pos: Vector2 = CardEffectResolver.as_vector2(action.get("to", Vector2(-1, -1)), Vector2(-1, -1))
	var moving_piece: Piece = game_state.get_piece(from_pos)
	if moving_piece == null:
		return

	var captured_piece: Piece = game_state.get_piece(to_pos)
	game_state.remove_piece(from_pos)
	moving_piece.position = to_pos
	game_state.set_piece(to_pos, moving_piece)
	game_state.moved_piece_this_turn[player_id] = true

	if MoveRules.is_king_card(moving_piece.attached_card):
		if player_id == 0:
			game_state.white_king_position = to_pos
		else:
			game_state.black_king_position = to_pos

	var opponent_base: Vector2 = CardEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	if MoveRules.is_king_card(moving_piece.attached_card) && to_pos == opponent_base:
		game_state.game_over = true
		game_state.winner_player = player_id
		game_state.win_condition = "base_reached"
		return

	if captured_piece != null && CardEffectResolver.is_king_piece(captured_piece):
		var captured_player_id: int = CardEffectResolver.get_player_id_for_color(captured_piece.color)
		CardEffectResolver.clear_king_position_if_needed(game_state, captured_player_id, true)

	if moving_piece.attached_card != null:
		var moving_card: Card = moving_piece.attached_card
		if captured_piece != null:
			simulate_trigger_effect(game_state, CardEffect.TRIGGER_ON_CAPTURE, player_id, moving_piece, to_pos, moving_card, board_size, {
				"captured_piece": captured_piece,
				"captured_piece_pos": to_pos,
			})
			if game_state.game_over:
				return

		simulate_trigger_effect(game_state, CardEffect.TRIGGER_ON_MOVE, player_id, moving_piece, to_pos, moving_card, board_size, {
			"from_pos": from_pos,
			"to_pos": to_pos,
		})
		if game_state.game_over:
			return

	_refresh_king_positions(game_state)

static func simulate_trigger_effect(
	game_state: GameStateData,
	trigger: String,
	player_id: int,
	piece: Piece,
	source_pos: Vector2,
	card: Card,
	board_size: int,
	extra_context: Dictionary = {}
) -> void:
	if card == null or !card.has_effect() or card.effect_trigger != trigger:
		return

	var context: Dictionary = {
		"player_id": player_id,
		"piece": piece,
		"piece_pos": source_pos,
		"card": card,
	}
	for key in extra_context:
		context[key] = extra_context[key]

	CardEffectResolver.resolve_trigger(trigger, game_state, context, board_size)
	_refresh_king_positions(game_state)

static func remove_card_name_from_hand(game_state: GameStateData, player_id: int, card_name: String) -> void:
	if !game_state.player_hands.has(player_id):
		return

	var hand: Array = game_state.player_hands[player_id]
	var card_index: int = hand.find(card_name)
	if card_index != -1:
		hand.remove_at(card_index)
	game_state.player_hands[player_id] = hand

static func end_simulated_turn(game_state: GameStateData, player_id: int, board_size: int) -> void:
	if game_state.game_over:
		return

	game_state.current_turn_player = player_id
	if should_tick_attached_cards_this_end_turn(game_state):
		tick_attached_cards(game_state, board_size)
		if game_state.game_over:
			return
	game_state.switch_turn()
	CardEffectResolver.tick_board_effects(game_state)

static func tick_attached_cards(game_state: GameStateData, board_size: int) -> void:
	var positions: Array = game_state.pieces.keys()
	for position_value in positions:
		var piece_pos: Vector2 = CardEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.get_piece(piece_pos)
		if piece == null or piece.attached_card == null:
			continue

		var player_id: int = CardEffectResolver.get_player_id_for_color(piece.color)
		var expired_card: Card = piece.use_turn()
		if expired_card == null:
			continue

		if MoveRules.is_king_card(expired_card):
			handle_expired_king_card(game_state, player_id, expired_card, piece_pos)
			if game_state.game_over:
				return
			continue

		simulate_trigger_effect(game_state, CardEffect.TRIGGER_ON_EXPIRE, player_id, piece, piece_pos, expired_card, board_size)
		if game_state.game_over:
			return

	_refresh_king_positions(game_state)

static func handle_expired_king_card(game_state: GameStateData, player_id: int, expired_card: Card, piece_pos: Vector2) -> void:
	CardEffectResolver.clear_king_position_if_needed(game_state, player_id, true)
	var king_card_returned: bool = CardEffectResolver.return_card_to_owner_hand(game_state, player_id, expired_card.card_name, piece_pos)
	if !king_card_returned && !CardEffectResolver.player_has_available_king_card(game_state, player_id):
		game_state.game_over = true
		game_state.winner_player = 1 - player_id
		game_state.win_condition = "king_card_lost"

static func should_tick_attached_cards_this_end_turn(game_state: GameStateData) -> bool:
	return game_state.current_turn_player == 1

static func _refresh_king_positions(game_state: GameStateData) -> void:
	game_state.white_king_position = find_king_position(game_state.pieces, 0)
	game_state.black_king_position = find_king_position(game_state.pieces, 1)

static func apply_candidate_to_pieces(source_pieces: Dictionary, move: Dictionary) -> Dictionary:
	var simulated_pieces: Dictionary = clone_pieces(source_pieces)
	var from_pos: Vector2 = get_move_from(move)
	var to_pos: Vector2 = get_move_to(move)
	var moving_piece: Piece = simulated_pieces.get(from_pos, null) as Piece
	if moving_piece == null:
		return simulated_pieces

	if bool(move.get("requires_attach", false)):
		var card: Card = move.get("card", null) as Card
		if card != null:
			moving_piece.attached_card = card
			moving_piece.turns_remaining = card.duration

	simulated_pieces.erase(from_pos)
	moving_piece.position = to_pos
	simulated_pieces[to_pos] = moving_piece
	return simulated_pieces

static func get_move_from(move: Dictionary) -> Vector2:
	return CardEffectResolver.as_vector2(move.get("from", Vector2(-1, -1)), Vector2(-1, -1))

static func get_move_to(move: Dictionary) -> Vector2:
	return CardEffectResolver.as_vector2(move.get("to", Vector2(-1, -1)), Vector2(-1, -1))

static func get_card_for_candidate(pieces: Dictionary, move: Dictionary) -> Card:
	var move_card: Card = move.get("card", null) as Card
	if move_card != null:
		return move_card

	var from_pos: Vector2 = get_move_from(move)
	var piece: Piece = pieces.get(from_pos, null) as Piece
	if piece == null:
		return null
	return piece.attached_card

static func get_captured_piece(pieces: Dictionary, move: Dictionary) -> Piece:
	var to_pos: Vector2 = get_move_to(move)
	return pieces.get(to_pos, null) as Piece

static func find_king_position(pieces: Dictionary, player_id: int) -> Vector2:
	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	for position_value in pieces:
		var position: Vector2 = CardEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = pieces[position_value] as Piece
		if piece != null && piece.color == player_color && CardEffectResolver.is_king_piece(piece):
			return position
	return Vector2(-1, -1)

static func is_own_king_candidate(pieces: Dictionary, move: Dictionary, player_id: int) -> bool:
	var from_pos: Vector2 = get_move_from(move)
	var moving_piece: Piece = pieces.get(from_pos, null) as Piece
	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	if moving_piece == null or moving_piece.color != player_color:
		return false

	var card: Card = get_card_for_candidate(pieces, move)
	return MoveRules.is_king_card(card)

static func get_hand_cards_from_state(game_state: GameStateData, player_id: int) -> Array[Card]:
	var hand_cards: Array[Card] = []
	if game_state == null or !game_state.player_hands.has(player_id):
		return hand_cards

	var hand_card_names: Array = game_state.player_hands[player_id]
	for card_name_value in hand_card_names:
		var card_name: String = str(card_name_value)
		var card: Card = CardLibrary.get_card(card_name)
		if card != null:
			hand_cards.append(card)
	return hand_cards

static func is_square_threatened(
	pieces: Dictionary,
	target_pos: Vector2,
	attacker_player_id: int,
	hand_cards: Array[Card],
	board_effects: Array,
	board_size: int
) -> bool:
	var attacker_color: int = CardEffectResolver.get_color_for_player_id(attacker_player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_valid_turn_moves(
		pieces,
		attacker_color,
		hand_cards,
		true,
		board_size,
		board_effects
	)

	for move: Dictionary in valid_moves:
		if get_move_to(move) == target_pos:
			return true
	return false
