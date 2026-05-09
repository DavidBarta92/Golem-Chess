extends RefCounted
class_name MoveRules

const DEFAULT_BOARD_SIZE: int = BoardConfig.BOARD_SIZE

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

static func is_nexus_card(card: Card) -> bool:
	return card != null && card.role == Card.Role.NEXUS

static func is_shared_card(card: Card) -> bool:
	return card != null && card.role == Card.Role.SHARED

static func has_attached_nexus(pieces: Dictionary, player_color: int) -> bool:
	for position_value: Vector2 in pieces:
		var piece: Piece = get_piece_at(pieces, position_value)
		if piece != null && piece.color == player_color && is_nexus_card(piece.attached_card):
			return true
	return false

static func can_attach_card_for_turn(pieces: Dictionary, player_color: int, card: Card) -> bool:
	return card_can_be_used(card)

static func get_card_moves_for_piece(pieces: Dictionary, piece_position: Vector2, piece_color: int, card: Card, board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> Array[Vector2]:
	var valid_moves: Array[Vector2] = []
	if card == null:
		return valid_moves
	var player_id: int = BoardConfig.get_player_id_for_color(piece_color)
	if CardEffectResolver.is_square_frozen(board_effects, piece_position, player_id):
		return valid_moves

	var movement_options: Array[Dictionary] = card.get_movement_options()
	for movement_option: Dictionary in movement_options:
		var direction: Vector2 = movement_option.get("offset", Vector2.ZERO)
		var movement_type: int = int(movement_option.get("movement_type", CardEffect.MOVEMENT_MOVE_AND_CAPTURE))
		var target_pos: Vector2 = piece_position + (direction * piece_color)
		if !is_valid_position(target_pos, board_size):
			continue
		if CardEffectResolver.is_square_invalid(board_effects, target_pos, player_id):
			continue

		var target_piece: Piece = get_piece_at(pieces, target_pos)
		if is_target_allowed_by_movement_type(target_piece, piece_color, movement_type):
			valid_moves.append(target_pos)

	return valid_moves

static func is_target_allowed_by_movement_type(target_piece: Piece, piece_color: int, movement_type: int) -> bool:
	match movement_type:
		CardEffect.MOVEMENT_MOVE_ONLY:
			return target_piece == null
		CardEffect.MOVEMENT_CAPTURE_ONLY:
			return can_capture_target_piece(target_piece, piece_color)
		CardEffect.MOVEMENT_MOVE_AND_CAPTURE:
			return target_piece == null || can_capture_target_piece(target_piece, piece_color)
		_:
			return false

static func can_capture_target_piece(target_piece: Piece, piece_color: int) -> bool:
	if target_piece == null or target_piece.color == piece_color:
		return false
	return !CardEffectResolver.piece_has_attached_effect(target_piece, CardEffect.TYPE_UNCAPTURABLE)

static func get_piece_moves(pieces: Dictionary, piece_position: Vector2, board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> Array[Vector2]:
	var piece: Piece = get_piece_at(pieces, piece_position)
	if piece == null || !piece.can_move():
		return []
	var owner_player_id: int = BoardConfig.get_player_id_for_color(piece.color)
	return get_piece_moves_for_player(pieces, piece_position, owner_player_id, board_size, board_effects)

static func get_piece_moves_for_player(pieces: Dictionary, piece_position: Vector2, player_id: int, board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> Array[Vector2]:
	var piece: Piece = get_piece_at(pieces, piece_position)
	if piece == null || !piece.can_move():
		return []
	if !CardEffectResolver.can_player_control_piece(piece, player_id):
		return []

	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	return get_card_moves_for_piece(pieces, piece_position, player_color, piece.attached_card, board_size, board_effects)

static func get_existing_card_moves(pieces: Dictionary, player_color: int, board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> Array[Dictionary]:
	var valid_moves: Array[Dictionary] = []

	for position_value: Vector2 in pieces:
		var piece_position: Vector2 = position_value
		var piece: Piece = get_piece_at(pieces, piece_position)
		var player_id: int = BoardConfig.get_player_id_for_color(player_color)
		if piece == null || !CardEffectResolver.can_player_control_piece(piece, player_id) || !piece.can_move():
			continue

		var targets: Array[Vector2] = get_piece_moves_for_player(pieces, piece_position, player_id, board_size, board_effects)
		for target_pos: Vector2 in targets:
			valid_moves.append({
				"from": piece_position,
				"to": target_pos,
				"card": piece.attached_card,
				"requires_attach": false,
			})

	return valid_moves

static func get_attach_card_moves(pieces: Dictionary, player_color: int, hand_cards: Array[Card], board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> Array[Dictionary]:
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
			var targets: Array[Vector2] = get_card_moves_for_piece(pieces, piece_position, player_color, card, board_size, board_effects)
			for target_pos: Vector2 in targets:
				valid_moves.append({
					"from": piece_position,
					"to": target_pos,
					"card": card,
					"requires_attach": true,
				})

	return valid_moves

static func can_attach_any_card(pieces: Dictionary, player_color: int, hand_cards: Array[Card]) -> bool:
	for position_value: Vector2 in pieces:
		var piece_position: Vector2 = position_value
		var piece: Piece = get_piece_at(pieces, piece_position)
		if piece == null || piece.color != player_color || piece.attached_card != null:
			continue

		for card: Card in hand_cards:
			if !card_can_be_used(card):
				continue
			if can_attach_card_for_turn(pieces, player_color, card):
				return true

	return false

static func get_valid_turn_moves(pieces: Dictionary, player_color: int, hand_cards: Array[Card], can_attach_card: bool, board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> Array[Dictionary]:
	var valid_moves: Array[Dictionary] = get_existing_card_moves(pieces, player_color, board_size, board_effects)
	return valid_moves

static func has_valid_piece_move(pieces: Dictionary, player_color: int, board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> bool:
	var player_id: int = BoardConfig.get_player_id_for_color(player_color)
	for position_value: Vector2 in pieces:
		var piece_position: Vector2 = position_value
		var piece: Piece = get_piece_at(pieces, piece_position)
		if piece == null || !CardEffectResolver.can_player_control_piece(piece, player_id) || !piece.can_move():
			continue
		if !get_piece_moves_for_player(pieces, piece_position, player_id, board_size, board_effects).is_empty():
			return true
	return false

static func has_valid_attachment_move(pieces: Dictionary, player_color: int, hand_cards: Array[Card], board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> bool:
	return can_attach_any_card(pieces, player_color, hand_cards)

static func has_valid_turn_action(pieces: Dictionary, player_color: int, hand_cards: Array[Card], can_attach_card: bool, board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> bool:
	if has_valid_piece_move(pieces, player_color, board_size, board_effects):
		return true
	if !can_attach_card:
		return false
	return has_valid_attachment_move(pieces, player_color, hand_cards, board_size, board_effects)

static func is_valid_move(pieces: Dictionary, from_pos: Vector2, to_pos: Vector2, board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> bool:
	var valid_moves: Array[Vector2] = get_piece_moves(pieces, from_pos, board_size, board_effects)
	return valid_moves.has(to_pos)

static func is_valid_move_for_player(pieces: Dictionary, from_pos: Vector2, to_pos: Vector2, player_id: int, board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> bool:
	var valid_moves: Array[Vector2] = get_piece_moves_for_player(pieces, from_pos, player_id, board_size, board_effects)
	return valid_moves.has(to_pos)

static func get_attacked_squares_for_player(pieces: Dictionary, attacking_color: int, board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> Array[Vector2]:
	var attacked_squares: Array[Vector2] = []
	var player_id: int = BoardConfig.get_player_id_for_color(attacking_color)

	for position_value: Vector2 in pieces:
		var piece_position: Vector2 = position_value
		var piece: Piece = get_piece_at(pieces, piece_position)
		if piece == null || piece.color != attacking_color || !piece.can_move():
			continue
		if CardEffectResolver.is_square_frozen(board_effects, piece_position, player_id):
			continue

		for movement_option: Dictionary in piece.attached_card.get_movement_options():
			var movement_type: int = int(movement_option.get("movement_type", CardEffect.MOVEMENT_MOVE_AND_CAPTURE))
			if movement_type == CardEffect.MOVEMENT_MOVE_ONLY:
				continue

			var offset: Vector2 = movement_option.get("offset", Vector2.ZERO)
			var target_pos: Vector2 = piece_position + (offset * attacking_color)
			if !is_valid_position(target_pos, board_size):
				continue
			if CardEffectResolver.is_square_invalid(board_effects, target_pos, player_id):
				continue

			var target_piece: Piece = get_piece_at(pieces, target_pos)
			if target_piece != null && target_piece.color == attacking_color:
				continue
			if !attacked_squares.has(target_pos):
				attacked_squares.append(target_pos)

	return attacked_squares
