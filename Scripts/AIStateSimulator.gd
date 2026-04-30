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
