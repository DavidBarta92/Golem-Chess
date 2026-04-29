extends RefCounted
class_name MoveRules

const DEFAULT_BOARD_SIZE: int = 5
const KING_CARD_NAME: String = "King"

static func get_piece_at(pieces: Dictionary, pos: Vector2) -> Piece:
	if !pieces.has(pos):
		return null
	return pieces[pos] as Piece

static func is_valid_position(pos: Vector2, board_size: int = DEFAULT_BOARD_SIZE) -> bool:
	return pos.x >= 0 && pos.x < board_size && pos.y >= 0 && pos.y < board_size

static func has_any_piece(pieces: Dictionary, player_color: int) -> bool:
	for position_value: Vector2 in pieces:
		var piece: Piece = get_piece_at(pieces, position_value)
		if piece != null && piece.color == player_color:
			return true
	return false

static func card_can_be_used(card: Card) -> bool:
	return card != null && (card.duration > 0 || card.duration == -1)

static func is_king_card(card: Card) -> bool:
	return card != null && card.card_name == KING_CARD_NAME

static func has_attached_king(pieces: Dictionary, player_color: int) -> bool:
	for position_value: Vector2 in pieces:
		var piece: Piece = get_piece_at(pieces, position_value)
		if piece != null && piece.color == player_color && is_king_card(piece.attached_card):
			return true
	return false

static func can_attach_card_for_turn(pieces: Dictionary, player_color: int, card: Card) -> bool:
	if has_attached_king(pieces, player_color):
		return true
	return is_king_card(card)

static func get_card_moves_for_piece(pieces: Dictionary, piece_position: Vector2, piece_color: int, card: Card, board_size: int = DEFAULT_BOARD_SIZE) -> Array[Vector2]:
	var valid_moves: Array[Vector2] = []
	if card == null:
		return valid_moves

	var directions: Array = card.get_directions()
	for direction: Vector2 in directions:
		var target_pos: Vector2 = piece_position + (direction * piece_color)
		if !is_valid_position(target_pos, board_size):
			continue

		var target_piece: Piece = get_piece_at(pieces, target_pos)
		if target_piece == null || target_piece.color != piece_color:
			valid_moves.append(target_pos)

	return valid_moves

static func get_piece_moves(pieces: Dictionary, piece_position: Vector2, board_size: int = DEFAULT_BOARD_SIZE) -> Array[Vector2]:
	var piece: Piece = get_piece_at(pieces, piece_position)
	if piece == null || !piece.can_move():
		return []
	if !has_attached_king(pieces, piece.color):
		return []
	return get_card_moves_for_piece(pieces, piece_position, piece.color, piece.attached_card, board_size)

static func get_existing_card_moves(pieces: Dictionary, player_color: int, board_size: int = DEFAULT_BOARD_SIZE) -> Array[Dictionary]:
	var valid_moves: Array[Dictionary] = []
	if !has_attached_king(pieces, player_color):
		return valid_moves

	for position_value: Vector2 in pieces:
		var piece_position: Vector2 = position_value
		var piece: Piece = get_piece_at(pieces, piece_position)
		if piece == null || piece.color != player_color || !piece.can_move():
			continue

		var targets: Array[Vector2] = get_piece_moves(pieces, piece_position, board_size)
		for target_pos: Vector2 in targets:
			valid_moves.append({
				"from": piece_position,
				"to": target_pos,
				"card": piece.attached_card,
				"requires_attach": false,
			})

	return valid_moves

static func get_attach_card_moves(pieces: Dictionary, player_color: int, hand_cards: Array[Card], board_size: int = DEFAULT_BOARD_SIZE) -> Array[Dictionary]:
	var valid_moves: Array[Dictionary] = []
	for position_value: Vector2 in pieces:
		var piece_position: Vector2 = position_value
		var piece: Piece = get_piece_at(pieces, piece_position)
		if piece == null || piece.color != player_color || piece.attached_card != null:
			continue

		for card: Card in hand_cards:
			if !card_can_be_used(card):
				continue
			if !can_attach_card_for_turn(pieces, player_color, card):
				continue
			var targets: Array[Vector2] = get_card_moves_for_piece(pieces, piece_position, player_color, card, board_size)
			for target_pos: Vector2 in targets:
				valid_moves.append({
					"from": piece_position,
					"to": target_pos,
					"card": card,
					"requires_attach": true,
				})

	return valid_moves

static func get_valid_turn_moves(pieces: Dictionary, player_color: int, hand_cards: Array[Card], can_attach_card: bool, board_size: int = DEFAULT_BOARD_SIZE) -> Array[Dictionary]:
	var valid_moves: Array[Dictionary] = get_existing_card_moves(pieces, player_color, board_size)
	if can_attach_card:
		valid_moves.append_array(get_attach_card_moves(pieces, player_color, hand_cards, board_size))
	return valid_moves

static func has_valid_piece_move(pieces: Dictionary, player_color: int, board_size: int = DEFAULT_BOARD_SIZE) -> bool:
	if !has_attached_king(pieces, player_color):
		return false

	for position_value: Vector2 in pieces:
		var piece_position: Vector2 = position_value
		var piece: Piece = get_piece_at(pieces, piece_position)
		if piece == null || piece.color != player_color || !piece.can_move():
			continue
		if !get_piece_moves(pieces, piece_position, board_size).is_empty():
			return true
	return false

static func has_valid_attachment_move(pieces: Dictionary, player_color: int, hand_cards: Array[Card], board_size: int = DEFAULT_BOARD_SIZE) -> bool:
	for position_value: Vector2 in pieces:
		var piece_position: Vector2 = position_value
		var piece: Piece = get_piece_at(pieces, piece_position)
		if piece == null || piece.color != player_color || piece.attached_card != null:
			continue

		for card: Card in hand_cards:
			if !card_can_be_used(card):
				continue
			if !can_attach_card_for_turn(pieces, player_color, card):
				continue
			if !get_card_moves_for_piece(pieces, piece_position, player_color, card, board_size).is_empty():
				return true

	return false

static func has_valid_turn_action(pieces: Dictionary, player_color: int, hand_cards: Array[Card], can_attach_card: bool, board_size: int = DEFAULT_BOARD_SIZE) -> bool:
	if has_valid_piece_move(pieces, player_color, board_size):
		return true
	if !can_attach_card:
		return false
	return has_valid_attachment_move(pieces, player_color, hand_cards, board_size)

static func is_valid_move(pieces: Dictionary, from_pos: Vector2, to_pos: Vector2, board_size: int = DEFAULT_BOARD_SIZE) -> bool:
	var valid_moves: Array[Vector2] = get_piece_moves(pieces, from_pos, board_size)
	return valid_moves.has(to_pos)
