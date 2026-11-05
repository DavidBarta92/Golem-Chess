extends RefCounted
class_name AITacticalSearch

const ACTION_MOVE_PIECE: String = "move_piece"
const ACTION_PLACE_CROWN: String = "place_crown"
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

	# Low difficulty misses the defensive shortcuts some of the time; its own
	# two-turn threat it always sees. Gating that too made weak levels look as
	# if they did not want to win, rather than as if they defended poorly.
	var notices_defense: bool = evaluator == null or (evaluator.sees_threats_this_turn and evaluator.should_notice_defensive_tactics())
	if notices_defense:
		var defense_move: Dictionary = find_immediate_base_defense_move(game_state, player_id, evaluator, board_size)
		if !defense_move.is_empty():
			return create_move_plan(player_id, defense_move, "immediate_base_defense")

	var two_turn_threat_plan: Dictionary = find_two_turn_base_threat_plan(game_state, player_id, evaluator, board_size)
	if !two_turn_threat_plan.is_empty():
		return two_turn_threat_plan

	if notices_defense:
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
		if AIStateSimulator.is_base_win_move(game_state.pieces, move, player_id, opponent_base):
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

## A turn after which the player's crowned golem can step onto the enemy base,
## the opponent has no win of their own and cannot take the crowned golem:
## either a move with the crown already on the board, or the crown put (or
## moved) on a golem already in reach of the base, plus the turn's move.
func find_two_turn_base_threat_plan(
	game_state: GameStateData,
	player_id: int,
	evaluator: AIMoveEvaluator,
	board_size: int
) -> Dictionary:
	var prefixes: Array = []
	if game_state.has_crown_on_board(player_id):
		prefixes.append([])
	if game_state.can_place_crown(player_id):
		for crown_pos: Vector2 in get_crown_strike_positions(game_state, player_id, board_size):
			prefixes.append([create_crown_action(player_id, crown_pos)])

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var best_plan: Dictionary = {}
	var best_score: float = -INF
	for prefix_value in prefixes:
		var prefix: Array = prefix_value
		var prefix_state: GameStateData = AIStateSimulator.clone_game_state(game_state)
		for crown_action: Dictionary in prefix:
			AIStateSimulator.apply_place_crown_action(prefix_state, player_id, crown_action)
		var valid_moves: Array[Dictionary] = MoveRules.get_existing_stamp_moves(
			prefix_state.pieces,
			player_color,
			board_size,
			prefix_state.board_effects
		)
		for move: Dictionary in valid_moves:
			var plan: Dictionary = create_move_plan(player_id, move, "two_turn_base_threat", prefix)
			var simulated_state: GameStateData = AIStateSimulator.apply_turn_plan(game_state, player_id, plan, board_size)
			if simulated_state.game_over:
				continue
			if !find_immediate_base_win_move(simulated_state, 1 - player_id, board_size).is_empty():
				continue
			if find_immediate_base_win_move(simulated_state, player_id, board_size).is_empty():
				continue
			if can_capture_crowned_golem(simulated_state, 1 - player_id, player_id, board_size):
				continue

			var score: float = evaluator.score_move(prefix_state, player_id, move, board_size) if evaluator != null else 0.0
			if best_plan.is_empty() or score > best_score:
				best_plan = plan
				best_score = score
	return best_plan

## Golems the player may crown that could step onto the enemy base on their
## next turn with the stamp they carry.
func get_crown_strike_positions(game_state: GameStateData, player_id: int, board_size: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	for position_value in game_state.pieces:
		var piece_pos: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.affixed_stamp == null or !game_state.can_crown_piece(player_id, piece_pos):
			continue
		var stamp_moves: Array[Vector2] = MoveRules.get_stamp_moves_for_piece(
			game_state.pieces,
			piece_pos,
			player_color,
			piece.affixed_stamp,
			board_size,
			game_state.board_effects
		)
		if stamp_moves.has(opponent_base):
			positions.append(piece_pos)
	return positions

func can_capture_crowned_golem(game_state: GameStateData, attacker_player_id: int, owner_player_id: int, board_size: int) -> bool:
	var crowned_pos: Vector2 = game_state.get_crowned_piece_position(owner_player_id)
	if crowned_pos == Vector2(-1, -1):
		return false
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_stamp_moves(
		game_state.pieces,
		StampEffectResolver.get_color_for_player_id(attacker_player_id),
		board_size,
		game_state.board_effects
	)
	for move: Dictionary in valid_moves:
		if AIStateSimulator.get_move_to(move) == crowned_pos:
			return true
	return false

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

## Golems the player can crown on their coming turn and walk onto the base on
## the turn after: those carrying a stamp that already reaches it, and bare
## ones a stamp from the open codex page would put within one step.
func get_base_staging_positions(game_state: GameStateData, player_id: int, board_size: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if !AIMoveEvaluator.can_crown_next_turn(game_state, player_id):
		return positions

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var hand_stamps: Array[Stamp] = AIStateSimulator.get_hand_stamps_from_state(game_state, player_id)
	for position_value in game_state.pieces:
		var piece_pos: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != player_color or piece_pos == opponent_base:
			continue

		var stamps: Array[Stamp] = []
		if piece.affixed_stamp != null:
			stamps.append(piece.affixed_stamp)
		else:
			stamps = hand_stamps
		for stamp: Stamp in stamps:
			var stamp_moves: Array[Vector2] = MoveRules.get_stamp_moves_for_piece(
				game_state.pieces,
				piece_pos,
				player_color,
				stamp,
				board_size,
				game_state.board_effects
			)
			if stamp_moves.has(opponent_base):
				positions.append(piece_pos)
				break
	return positions

func create_crown_action(player_id: int, piece_pos: Vector2) -> Dictionary:
	return {
		"type": ACTION_PLACE_CROWN,
		"player_id": player_id,
		"piece_pos": piece_pos,
	}

func create_move_plan(player_id: int, move: Dictionary, plan_type: String, prefix_actions: Array = []) -> Dictionary:
	var actions: Array = prefix_actions.duplicate(true)
	actions.append({
		"type": ACTION_MOVE_PIECE,
		"player_id": player_id,
		"from": AIStateSimulator.get_move_from(move),
		"to": AIStateSimulator.get_move_to(move),
	})
	actions.append({
		"type": ACTION_END_TURN,
		"player_id": player_id,
	})
	return {
		"actions": actions,
		"move": move,
		"setup_affix_actions": [],
		"plan_type": plan_type,
	}
