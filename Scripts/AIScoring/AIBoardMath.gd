extends RefCounted
class_name AIBoardMath

## Distances and counts on the board that the scoring uses.

static func count_valid_turn_moves_for_player(game_state: GameStateData, pieces: Dictionary, player_id: int, board_effects: Array, board_size: int) -> int:
	var hand_stamps: Array[Stamp] = AIStateSimulator.get_hand_stamps_from_state(game_state, player_id)
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	return MoveRules.get_valid_turn_moves(
		pieces,
		player_color,
		hand_stamps,
		true,
		board_size,
		board_effects
	).size()

static func get_piece_positions_for_player(pieces: Dictionary, player_id: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	for position_value in pieces:
		var position: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = pieces[position_value] as Piece
		if piece != null && piece.color == player_color:
			positions.append(position)
	return positions

static func get_min_distance_to_positions(source_pos: Vector2, positions: Array[Vector2]) -> float:
	var min_distance: float = INF
	for target_pos: Vector2 in positions:
		var distance: float = get_manhattan_distance(source_pos, target_pos)
		if distance < min_distance:
			min_distance = distance
	return min_distance

static func get_average_distance_to_positions(source_pos: Vector2, positions: Array[Vector2]) -> float:
	if positions.is_empty():
		return 0.0

	var total_distance: float = 0.0
	for target_pos: Vector2 in positions:
		total_distance += get_manhattan_distance(source_pos, target_pos)
	return total_distance / float(positions.size())

static func get_manhattan_distance(left: Vector2, right: Vector2) -> float:
	return abs(left.x - right.x) + abs(left.y - right.y)
