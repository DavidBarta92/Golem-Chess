extends RefCounted
class_name AITacticalSearch

const ACTION_MOVE_PIECE: String = "move_piece"
const ACTION_END_TURN: String = "end_turn"

func find_forced_tactical_plan(
	game_state: GameStateData,
	player_id: int,
	evaluator: AIMoveEvaluator,
	board_size: int = BoardConfig.BOARD_SIZE
) -> Dictionary:
	if game_state == null or game_state.game_over:
		return {}

	var winning_move: Dictionary = find_immediate_base_win_move(game_state, player_id, board_size)
	if !winning_move.is_empty():
		return create_move_plan(player_id, winning_move, "immediate_base_win")

	var defense_move: Dictionary = find_immediate_base_defense_move(game_state, player_id, evaluator, board_size)
	if !defense_move.is_empty():
		return create_move_plan(player_id, defense_move, "immediate_base_defense")

	var two_turn_threat_move: Dictionary = find_two_turn_base_threat_move(game_state, player_id, evaluator, board_size)
	if !two_turn_threat_move.is_empty():
		return create_move_plan(player_id, two_turn_threat_move, "two_turn_base_threat")

	var staging_capture_move: Dictionary = find_base_staging_capture_move(game_state, player_id, evaluator, board_size)
	if !staging_capture_move.is_empty():
		return create_move_plan(player_id, staging_capture_move, "base_staging_capture")

	return {}

func find_immediate_base_win_move(game_state: GameStateData, player_id: int, board_size: int) -> Dictionary:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_stamp_moves(
		game_state.pieces,
		player_color,
		board_size,
		game_state.board_effects
	)
	for move: Dictionary in valid_moves:
		if AIStateSimulator.get_move_to(move) != opponent_base:
			continue
		if AIStateSimulator.is_own_seeker_candidate(game_state.pieces, move, player_id):
			return move
	return {}

func find_immediate_base_defense_move(
	game_state: GameStateData,
	player_id: int,
	evaluator: AIMoveEvaluator,
	board_size: int
) -> Dictionary:
	if find_immediate_base_win_move(game_state, 1 - player_id, board_size).is_empty():
		return {}

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_stamp_moves(
		game_state.pieces,
		player_color,
		board_size,
		game_state.board_effects
	)
	var best_move: Dictionary = {}
	var best_score: float = -INF
	for move: Dictionary in valid_moves:
		var plan: Dictionary = create_move_plan(player_id, move, "defense_candidate")
		var simulated_state: GameStateData = AIStateSimulator.apply_turn_plan(game_state, player_id, plan, board_size)
		if simulated_state.game_over:
			if simulated_state.winner_player == player_id:
				return move
			continue
		if !find_immediate_base_win_move(simulated_state, 1 - player_id, board_size).is_empty():
			continue

		var score: float = evaluator.score_move(game_state, player_id, move, board_size) if evaluator != null else 0.0
		if best_move.is_empty() or score > best_score:
			best_move = move
			best_score = score
	return best_move

func find_two_turn_base_threat_move(
	game_state: GameStateData,
	player_id: int,
	evaluator: AIMoveEvaluator,
	board_size: int
) -> Dictionary:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_stamp_moves(
		game_state.pieces,
		player_color,
		board_size,
		game_state.board_effects
	)
	var best_move: Dictionary = {}
	var best_score: float = -INF
	for move: Dictionary in valid_moves:
		var plan: Dictionary = create_move_plan(player_id, move, "two_turn_candidate")
		var simulated_state: GameStateData = AIStateSimulator.apply_turn_plan(game_state, player_id, plan, board_size)
		if simulated_state.game_over:
			continue
		if !find_immediate_base_win_move(simulated_state, 1 - player_id, board_size).is_empty():
			continue
		if find_immediate_base_win_move(simulated_state, player_id, board_size).is_empty():
			continue

		var score: float = evaluator.score_move(game_state, player_id, move, board_size) if evaluator != null else 0.0
		if best_move.is_empty() or score > best_score:
			best_move = move
			best_score = score
	return best_move

func find_base_staging_capture_move(
	game_state: GameStateData,
	player_id: int,
	evaluator: AIMoveEvaluator,
	board_size: int
) -> Dictionary:
	var staging_positions: Array[Vector2] = get_base_staging_positions(game_state, 1 - player_id, board_size)
	if staging_positions.is_empty():
		return {}

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_stamp_moves(
		game_state.pieces,
		player_color,
		board_size,
		game_state.board_effects
	)
	var best_move: Dictionary = {}
	var best_score: float = -INF
	for move: Dictionary in valid_moves:
		if !staging_positions.has(AIStateSimulator.get_move_to(move)):
			continue

		var score: float = evaluator.score_move(game_state, player_id, move, board_size) if evaluator != null else 0.0
		if best_move.is_empty() or score > best_score:
			best_move = move
			best_score = score
	return best_move

func get_base_staging_positions(game_state: GameStateData, player_id: int, board_size: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var seeker_stamps: Array[Stamp] = get_seeker_stamps_in_hand(game_state, player_id)
	if seeker_stamps.is_empty():
		return positions

	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	for position_value in game_state.pieces:
		var piece_pos: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != player_color or piece.attached_stamp != null:
			continue

		for seeker_stamp: Stamp in seeker_stamps:
			var seeker_moves: Array[Vector2] = MoveRules.get_stamp_moves_for_piece(
				game_state.pieces,
				piece_pos,
				player_color,
				seeker_stamp,
				board_size,
				game_state.board_effects
			)
			if seeker_moves.has(opponent_base):
				positions.append(piece_pos)
				break
	return positions

func get_seeker_stamps_in_hand(game_state: GameStateData, player_id: int) -> Array[Stamp]:
	var seeker_stamps: Array[Stamp] = []
	var hand_stamps: Array[Stamp] = AIStateSimulator.get_hand_stamps_from_state(game_state, player_id)
	for stamp: Stamp in hand_stamps:
		if MoveRules.is_seeker_stamp(stamp):
			seeker_stamps.append(stamp)
	return seeker_stamps

func create_move_plan(player_id: int, move: Dictionary, plan_type: String) -> Dictionary:
	return {
		"actions": [
			{
				"type": ACTION_MOVE_PIECE,
				"player_id": player_id,
				"from": AIStateSimulator.get_move_from(move),
				"to": AIStateSimulator.get_move_to(move),
			},
			{
				"type": ACTION_END_TURN,
				"player_id": player_id,
			}
		],
		"move": move,
		"setup_attach_actions": [],
		"plan_type": plan_type,
	}
