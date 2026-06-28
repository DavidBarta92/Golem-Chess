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

static func stamp_can_be_used(stamp: Stamp) -> bool:
	return stamp != null && (stamp.duration > 0 || stamp.duration == -1)

static func is_seeker_stamp(stamp: Stamp) -> bool:
	return stamp != null && stamp.role == Stamp.Role.SEEKER

static func is_shared_stamp(stamp: Stamp) -> bool:
	return stamp != null && stamp.role == Stamp.Role.SHARED

static func is_se_tenant_stamp(stamp: Stamp) -> bool:
	return stamp != null && stamp.role == Stamp.Role.SE_TENANT

static func is_overseal_stamp(stamp: Stamp) -> bool:
	return stamp != null && stamp.role == Stamp.Role.OVERSEAL

static func has_attached_seeker(pieces: Dictionary, player_color: int) -> bool:
	for position_value: Vector2 in pieces:
		var piece: Piece = get_piece_at(pieces, position_value)
		if piece != null && piece.color == player_color && is_seeker_stamp(piece.attached_stamp):
			return true
	return false

static func can_attach_stamp_for_turn(pieces: Dictionary, player_color: int, stamp: Stamp) -> bool:
	return stamp_can_be_used(stamp)

static func get_stamp_moves_for_piece(pieces: Dictionary, piece_position: Vector2, piece_color: int, stamp: Stamp, board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> Array[Vector2]:
	var valid_moves: Array[Vector2] = []
	if stamp == null:
		return valid_moves
	var player_id: int = BoardConfig.get_player_id_for_color(piece_color)
	if StampEffectResolver.is_square_frozen(board_effects, piece_position, player_id):
		return valid_moves

	var movement_options: Array[Dictionary] = stamp.get_movement_options()
	for movement_option: Dictionary in movement_options:
		var direction: Vector2 = movement_option.get("offset", Vector2.ZERO)
		var movement_type: int = int(movement_option.get("movement_type", StampEffect.MOVEMENT_MOVE_AND_CAPTURE))
		var target_pos: Vector2 = piece_position + (direction * piece_color)
		if !is_valid_position(target_pos, board_size):
			continue
		if StampEffectResolver.is_square_invalid(board_effects, target_pos, player_id):
			continue

		var target_piece: Piece = get_piece_at(pieces, target_pos)
		if is_target_allowed_by_movement_type(target_piece, piece_color, movement_type):
			valid_moves.append(target_pos)

	return valid_moves

static func is_target_allowed_by_movement_type(target_piece: Piece, piece_color: int, movement_type: int) -> bool:
	match movement_type:
		StampEffect.MOVEMENT_MOVE_ONLY:
			return target_piece == null
		StampEffect.MOVEMENT_CAPTURE_ONLY:
			return can_capture_target_piece(target_piece, piece_color)
		StampEffect.MOVEMENT_MOVE_AND_CAPTURE:
			return target_piece == null || can_capture_target_piece(target_piece, piece_color)
		_:
			return false

static func can_capture_target_piece(target_piece: Piece, piece_color: int) -> bool:
	if target_piece == null or target_piece.color == piece_color:
		return false
	return !StampEffectResolver.piece_has_attached_effect(target_piece, StampEffect.TYPE_UNCAPTURABLE)

static func get_piece_moves(pieces: Dictionary, piece_position: Vector2, board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> Array[Vector2]:
	var piece: Piece = get_piece_at(pieces, piece_position)
	if piece == null || !piece.can_move():
		var empty_moves: Array[Vector2] = []
		return empty_moves
	var owner_player_id: int = BoardConfig.get_player_id_for_color(piece.color)
	return get_piece_moves_for_player(pieces, piece_position, owner_player_id, board_size, board_effects)

static func get_piece_moves_for_player(pieces: Dictionary, piece_position: Vector2, player_id: int, board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> Array[Vector2]:
	var piece: Piece = get_piece_at(pieces, piece_position)
	if piece == null || !piece.can_move():
		var empty_moves: Array[Vector2] = []
		return empty_moves
	if !StampEffectResolver.can_player_control_piece(piece, player_id):
		var empty_control_moves: Array[Vector2] = []
		return empty_control_moves

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	return get_stamp_moves_for_piece(pieces, piece_position, player_color, piece.attached_stamp, board_size, board_effects)

static func get_existing_stamp_moves(pieces: Dictionary, player_color: int, board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> Array[Dictionary]:
	var valid_moves: Array[Dictionary] = []

	for position_value: Vector2 in pieces:
		var piece_position: Vector2 = position_value
		var piece: Piece = get_piece_at(pieces, piece_position)
		var player_id: int = BoardConfig.get_player_id_for_color(player_color)
		if piece == null || !StampEffectResolver.can_player_control_piece(piece, player_id) || !piece.can_move():
			continue

		var targets: Array[Vector2] = get_piece_moves_for_player(pieces, piece_position, player_id, board_size, board_effects)
		for target_pos: Vector2 in targets:
			valid_moves.append({
				"from": piece_position,
				"to": target_pos,
				"stamp": piece.attached_stamp,
				"requires_attach": false,
			})

	return valid_moves

static func get_attach_stamp_moves(pieces: Dictionary, player_color: int, hand_stamps: Array[Stamp], board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> Array[Dictionary]:
	var valid_moves: Array[Dictionary] = []
	for position_value: Vector2 in pieces:
		var piece_position: Vector2 = position_value
		var piece: Piece = get_piece_at(pieces, piece_position)
		if piece == null || piece.color != player_color || !piece.can_receive_stamp():
			continue

		for stamp: Stamp in hand_stamps:
			if !stamp_can_be_used(stamp):
				continue
			if !can_attach_stamp_for_turn(pieces, player_color, stamp):
				continue
			var targets: Array[Vector2] = get_stamp_moves_for_piece(pieces, piece_position, player_color, stamp, board_size, board_effects)
			for target_pos: Vector2 in targets:
				valid_moves.append({
					"from": piece_position,
					"to": target_pos,
					"stamp": stamp,
					"requires_attach": true,
				})

	return valid_moves

static func can_attach_any_stamp(pieces: Dictionary, player_color: int, hand_stamps: Array[Stamp]) -> bool:
	for position_value: Vector2 in pieces:
		var piece_position: Vector2 = position_value
		var piece: Piece = get_piece_at(pieces, piece_position)
		if piece == null || piece.color != player_color || !piece.can_receive_stamp():
			continue

		for stamp: Stamp in hand_stamps:
			if !stamp_can_be_used(stamp):
				continue
			if can_attach_stamp_for_turn(pieces, player_color, stamp):
				return true

	return false

static func get_valid_turn_moves(pieces: Dictionary, player_color: int, hand_stamps: Array[Stamp], can_attach_stamp: bool, board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> Array[Dictionary]:
	var valid_moves: Array[Dictionary] = get_existing_stamp_moves(pieces, player_color, board_size, board_effects)
	return valid_moves

static func has_valid_piece_move(pieces: Dictionary, player_color: int, board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> bool:
	var player_id: int = BoardConfig.get_player_id_for_color(player_color)
	for position_value: Vector2 in pieces:
		var piece_position: Vector2 = position_value
		var piece: Piece = get_piece_at(pieces, piece_position)
		if piece == null || !StampEffectResolver.can_player_control_piece(piece, player_id) || !piece.can_move():
			continue
		if !get_piece_moves_for_player(pieces, piece_position, player_id, board_size, board_effects).is_empty():
			return true
	return false

static func has_frozen_movable_piece(pieces: Dictionary, player_color: int, board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> bool:
	var player_id: int = BoardConfig.get_player_id_for_color(player_color)
	for position_value: Vector2 in pieces:
		var piece_position: Vector2 = position_value
		var piece: Piece = get_piece_at(pieces, piece_position)
		if piece == null || !StampEffectResolver.can_player_control_piece(piece, player_id):
			continue
		if piece.attached_stamp != null and piece.exhausted_this_turn:
			return true
		if piece.can_move() and StampEffectResolver.is_square_frozen(board_effects, piece_position, player_id):
			return true
	return false

static func has_valid_attachment_move(pieces: Dictionary, player_color: int, hand_stamps: Array[Stamp], board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> bool:
	return can_attach_any_stamp(pieces, player_color, hand_stamps)

static func has_valid_turn_action(pieces: Dictionary, player_color: int, hand_stamps: Array[Stamp], can_attach_stamp: bool, board_size: int = DEFAULT_BOARD_SIZE, board_effects: Array = []) -> bool:
	if has_valid_piece_move(pieces, player_color, board_size, board_effects):
		return true
	if can_attach_stamp && has_valid_attachment_move(pieces, player_color, hand_stamps, board_size, board_effects):
		return true
	return has_frozen_movable_piece(pieces, player_color, board_size, board_effects)

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
		if StampEffectResolver.is_square_frozen(board_effects, piece_position, player_id):
			continue

		for movement_option: Dictionary in piece.attached_stamp.get_movement_options():
			var movement_type: int = int(movement_option.get("movement_type", StampEffect.MOVEMENT_MOVE_AND_CAPTURE))
			if movement_type == StampEffect.MOVEMENT_MOVE_ONLY:
				continue

			var offset: Vector2 = movement_option.get("offset", Vector2.ZERO)
			var target_pos: Vector2 = piece_position + (offset * attacking_color)
			if !is_valid_position(target_pos, board_size):
				continue
			if StampEffectResolver.is_square_invalid(board_effects, target_pos, player_id):
				continue

			var target_piece: Piece = get_piece_at(pieces, target_pos)
			if target_piece != null && target_piece.color == attacking_color:
				continue
			if !attacked_squares.has(target_pos):
				attacked_squares.append(target_pos)

	return attacked_squares
