extends RefCounted
class_name AIMoveEvaluator

const DIFFICULTY_EASY: String = "easy"
const DIFFICULTY_NORMAL: String = "normal"
const DIFFICULTY_HARD: String = "hard"

const SCORE_WIN: float = 100000.0
const SCORE_CAPTURE_KING: float = 160.0
const SCORE_ATTACH_KING: float = 600.0
const SCORE_THREATEN_KING: float = 420.0
const SCORE_CAPTURE_PIECE: float = 45.0
const SCORE_CAPTURE_CARD: float = 75.0
const SCORE_KING_BASE_PROGRESS: float = 35.0
const SCORE_ATTACH_CARD: float = 10.0
const SCORE_CENTER: float = 4.0
const SCORE_USE_EXISTING_CARD: float = 4.0
const PENALTY_GIVE_CARD: float = 35.0
const SCORE_INVALID_MOVE_REDUCTION: float = 8.0
const PENALTY_OWN_MOVE_REDUCTION: float = 5.0
const SCORE_FROZEN_ENEMY_PIECE: float = 34.0
const PENALTY_FROZEN_OWN_PIECE: float = 38.0
const SCORE_SHARED_OWN_MOBILITY: float = 4.0
const PENALTY_SHARED_OPPONENT_MOBILITY: float = 2.0
const PENALTY_SHARED_FUTURE_THREAT_MULTIPLIER: float = 0.35
const SCORE_MOVE_BASE_MIN_DISTANCE: float = 24.0
const SCORE_MOVE_BASE_AVG_DISTANCE: float = 8.0
const PENALTY_MOVE_BASE_NOOP: float = 20.0
const PENALTY_KING_THREATENED: float = 1400.0
const PENALTY_PIECE_THREATENED: float = 35.0

var difficulty: String = DIFFICULTY_NORMAL
var search_depth: int = 1
var randomness: float = 8.0

func _init(new_difficulty: String = DIFFICULTY_NORMAL):
	set_difficulty(new_difficulty)

func set_difficulty(new_difficulty: String) -> void:
	difficulty = new_difficulty
	match difficulty:
		DIFFICULTY_EASY:
			search_depth = 1
			randomness = 35.0
		DIFFICULTY_HARD:
			search_depth = 1
			randomness = 0.0
		_:
			search_depth = 1
			randomness = 8.0

func choose_best_move(game_state: GameStateData, player_id: int, valid_moves: Array[Dictionary], board_size: int = 5) -> Dictionary:
	if game_state == null or valid_moves.is_empty():
		return {}

	var best_move: Dictionary = {}
	var best_score: float = -INF
	for move: Dictionary in valid_moves:
		var move_score: float = score_move(game_state, player_id, move, board_size)
		if randomness > 0.0:
			move_score += randf_range(-randomness, randomness)

		if best_move.is_empty() or move_score > best_score:
			best_move = move
			best_score = move_score

	return best_move

func score_move(game_state: GameStateData, player_id: int, move: Dictionary, board_size: int = 5) -> float:
	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var score: float = 0.0
	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	var opponent_player_id: int = 1 - player_id
	var moving_piece: Piece = game_state.get_piece(from_pos)
	if moving_piece == null:
		return -SCORE_WIN

	var card: Card = AIStateSimulator.get_card_for_candidate(game_state.pieces, move)
	var captured_piece: Piece = AIStateSimulator.get_captured_piece(game_state.pieces, move)
	var is_own_king_move: bool = AIStateSimulator.is_own_king_candidate(game_state.pieces, move, player_id)

	if bool(move.get("requires_attach", false)):
		score += score_attached_card(game_state, player_id, moving_piece, card, from_pos, to_pos, captured_piece, move, board_size)
	else:
		score += SCORE_USE_EXISTING_CARD

	if captured_piece != null:
		score += score_capture(captured_piece)

	if is_own_king_move:
		score += score_king_base_progress(game_state, player_id, from_pos, to_pos)
		var opponent_base: Vector2 = CardEffectResolver.get_base_field_for_player(game_state, opponent_player_id)
		if moving_piece.color == player_color && to_pos == opponent_base:
			score += SCORE_WIN

	score += score_center_control(to_pos, board_size)
	score += score_king_threat(game_state, player_id, move, board_size)
	score -= score_danger_after_move(game_state, player_id, move, board_size)
	return score

func score_attached_card(
	game_state: GameStateData,
	player_id: int,
	moving_piece: Piece,
	card: Card,
	from_pos: Vector2,
	to_pos: Vector2,
	captured_piece: Piece,
	move: Dictionary,
	board_size: int
) -> float:
	if card == null:
		return 0.0

	var score: float = SCORE_ATTACH_CARD
	if MoveRules.is_king_card(card):
		score += SCORE_ATTACH_KING

	score += max(0, card.duration) * 3.0
	score += score_card_effect(game_state, player_id, moving_piece, card, from_pos, to_pos, captured_piece, move, board_size)
	return score

func score_capture(captured_piece: Piece) -> float:
	if CardEffectResolver.is_king_piece(captured_piece):
		return SCORE_CAPTURE_KING

	var score: float = SCORE_CAPTURE_PIECE
	if captured_piece.attached_card != null:
		score += SCORE_CAPTURE_CARD
		score += max(0, captured_piece.turns_remaining) * 8.0
	return score

func score_king_base_progress(game_state: GameStateData, player_id: int, from_pos: Vector2, to_pos: Vector2) -> float:
	var opponent_base: Vector2 = CardEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var distance_before: float = abs(from_pos.x - opponent_base.x) + abs(from_pos.y - opponent_base.y)
	var distance_after: float = abs(to_pos.x - opponent_base.x) + abs(to_pos.y - opponent_base.y)
	return (distance_before - distance_after) * SCORE_KING_BASE_PROGRESS

func score_center_control(pos: Vector2, board_size: int) -> float:
	var center: Vector2 = Vector2(float(board_size - 1) / 2.0, float(board_size - 1) / 2.0)
	var distance: float = abs(pos.x - center.x) + abs(pos.y - center.y)
	return max(0.0, float(board_size) - distance) * SCORE_CENTER

func score_king_threat(game_state: GameStateData, player_id: int, move: Dictionary, board_size: int) -> float:
	var simulated_pieces: Dictionary = AIStateSimulator.apply_candidate_to_pieces(game_state.pieces, move)
	var moved_to: Vector2 = AIStateSimulator.get_move_to(move)
	var opponent_king_pos: Vector2 = AIStateSimulator.find_king_position(simulated_pieces, 1 - player_id)
	if opponent_king_pos == Vector2(-1, -1):
		return 0.0

	var next_moves: Array[Vector2] = MoveRules.get_piece_moves_for_player(
		simulated_pieces,
		moved_to,
		player_id,
		board_size,
		game_state.board_effects
	)
	if next_moves.has(opponent_king_pos):
		return SCORE_THREATEN_KING
	return 0.0

func score_danger_after_move(game_state: GameStateData, player_id: int, move: Dictionary, board_size: int) -> float:
	var simulated_pieces: Dictionary = AIStateSimulator.apply_candidate_to_pieces(game_state.pieces, move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var opponent_player_id: int = 1 - player_id
	var opponent_hand_cards: Array[Card] = AIStateSimulator.get_hand_cards_from_state(game_state, opponent_player_id)
	var is_threatened: bool = AIStateSimulator.is_square_threatened(
		simulated_pieces,
		to_pos,
		opponent_player_id,
		opponent_hand_cards,
		game_state.board_effects,
		board_size
	)
	if !is_threatened:
		return 0.0

	if AIStateSimulator.is_own_king_candidate(game_state.pieces, move, player_id):
		return PENALTY_KING_THREATENED
	return PENALTY_PIECE_THREATENED

func score_card_effect(
	game_state: GameStateData,
	player_id: int,
	moving_piece: Piece,
	card: Card,
	from_pos: Vector2,
	to_pos: Vector2,
	captured_piece: Piece,
	move: Dictionary,
	board_size: int
) -> float:
	if card == null or !card.has_effect():
		return 0.0

	var score: float = 0.0
	var effect_source_pos: Vector2 = get_effect_source_pos(card, from_pos, to_pos)
	match card.effect_type:
		CardEffect.TYPE_SHARED_CONTROL:
			score += score_shared_control_effect(game_state, player_id, card, move, to_pos, board_size)
		CardEffect.TYPE_INVISIBLE_TO_ENEMY:
			score += 32.0
			if MoveRules.is_king_card(card):
				score += 80.0
		CardEffect.TYPE_STEAL_CARD:
			score += 50.0
		CardEffect.TYPE_GRANT_CARD:
			score += 45.0
		CardEffect.TYPE_GIVE_CARD:
			score -= PENALTY_GIVE_CARD
		CardEffect.TYPE_MOVE_BASE:
			score += score_move_base_effect(game_state, player_id, moving_piece, card, effect_source_pos, board_size)
		CardEffect.TYPE_INVALID_SQUARES:
			score += score_invalid_squares_effect(game_state, player_id, card, move, effect_source_pos, board_size)
		CardEffect.TYPE_FROZEN_SQUARES:
			score += score_frozen_squares_effect(game_state, player_id, moving_piece, card, effect_source_pos, board_size)
		CardEffect.TYPE_BOMB:
			score += score_bomb_effect(game_state, player_id, moving_piece, card, effect_source_pos, board_size)
		_:
			pass

	if card.effect_trigger == CardEffect.TRIGGER_ON_CAPTURE && captured_piece != null:
		score += 20.0
	if card.effect_trigger == CardEffect.TRIGGER_ON_MOVE:
		score += 8.0
	if card.effect_trigger == CardEffect.TRIGGER_ON_EXPIRE:
		score += 5.0
	if to_pos == from_pos:
		score -= 10.0

	return score

func score_bomb_effect(game_state: GameStateData, player_id: int, moving_piece: Piece, card: Card, source_pos: Vector2, board_size: int) -> float:
	if moving_piece == null:
		return 0.0

	var score: float = 0.0
	var effect_color: int = moving_piece.color
	for offset: Vector2 in card.get_effect_offsets():
		var target_pos: Vector2 = source_pos + (offset * effect_color)
		if !MoveRules.is_valid_position(target_pos, board_size):
			continue

		var target_piece: Piece = game_state.get_piece(target_pos)
		if target_piece == null:
			continue

		var target_player_id: int = CardEffectResolver.get_player_id_for_color(target_piece.color)
		var target_score: float = SCORE_CAPTURE_PIECE
		if CardEffectResolver.is_king_piece(target_piece):
			target_score = SCORE_CAPTURE_KING
		elif target_piece.attached_card != null:
			target_score += SCORE_CAPTURE_CARD

		if target_player_id == player_id:
			score -= target_score
		else:
			score += target_score

	return score

func score_frozen_squares_effect(game_state: GameStateData, player_id: int, moving_piece: Piece, card: Card, source_pos: Vector2, board_size: int) -> float:
	if moving_piece == null:
		return 0.0

	var score: float = 0.0
	var effect_color: int = moving_piece.color
	var target_squares: Array[Vector2] = CardEffectResolver.get_effect_squares(card, source_pos, board_size, effect_color)
	for target_pos: Vector2 in target_squares:
		var target_piece: Piece = game_state.get_piece(target_pos)
		if target_piece == null:
			continue

		var target_player_id: int = CardEffectResolver.get_player_id_for_color(target_piece.color)
		if !card_effect_targets_player(card, target_player_id):
			continue

		var piece_score: float = get_frozen_piece_score(game_state, target_piece, target_pos, target_player_id, board_size)
		if target_player_id == player_id:
			score -= piece_score
		else:
			score += piece_score

	return score

func score_invalid_squares_effect(game_state: GameStateData, player_id: int, card: Card, move: Dictionary, source_pos: Vector2, board_size: int) -> float:
	var moving_piece: Piece = game_state.get_piece(AIStateSimulator.get_move_from(move))
	if moving_piece == null:
		return 0.0

	var effect_color: int = moving_piece.color
	var target_squares: Array[Vector2] = CardEffectResolver.get_effect_squares(card, source_pos, board_size, effect_color)
	target_squares = CardEffectResolver.filter_out_base_fields(game_state, target_squares)
	if target_squares.is_empty():
		return 0.0

	var simulated_pieces: Dictionary = AIStateSimulator.apply_candidate_to_pieces(game_state.pieces, move)
	var opponent_player_id: int = 1 - player_id
	var board_effects_with_invalid: Array = game_state.board_effects.duplicate()
	board_effects_with_invalid.append({
		"effect_type": CardEffect.TYPE_INVALID_SQUARES,
		"owner_player_id": player_id,
		"target_player_id": int(card.effect_settings.get("target_player_id", -1)),
		"squares": target_squares,
		"turns_remaining": max(1, int(card.effect_settings.get("turns_remaining", card.duration))),
	})

	var opponent_moves_before: int = count_valid_turn_moves_for_player(game_state, simulated_pieces, opponent_player_id, game_state.board_effects, board_size)
	var opponent_moves_after: int = count_valid_turn_moves_for_player(game_state, simulated_pieces, opponent_player_id, board_effects_with_invalid, board_size)
	var opponent_reduced_moves: int = max(0, opponent_moves_before - opponent_moves_after)

	var own_moves_before: int = count_valid_turn_moves_for_player(game_state, simulated_pieces, player_id, game_state.board_effects, board_size)
	var own_moves_after: int = count_valid_turn_moves_for_player(game_state, simulated_pieces, player_id, board_effects_with_invalid, board_size)
	var own_reduced_moves: int = max(0, own_moves_before - own_moves_after)

	return float(opponent_reduced_moves) * SCORE_INVALID_MOVE_REDUCTION - float(own_reduced_moves) * PENALTY_OWN_MOVE_REDUCTION

func score_move_base_effect(game_state: GameStateData, player_id: int, moving_piece: Piece, card: Card, source_pos: Vector2, board_size: int) -> float:
	if moving_piece == null:
		return 0.0

	var raw_target_squares: Array[Vector2] = CardEffectResolver.get_effect_squares_unfiltered(card, source_pos, moving_piece.color)
	if raw_target_squares.is_empty():
		return -PENALTY_MOVE_BASE_NOOP

	var new_base_pos: Vector2 = raw_target_squares[0]
	if !MoveRules.is_valid_position(new_base_pos, board_size):
		return -PENALTY_MOVE_BASE_NOOP

	var current_base_pos: Vector2 = CardEffectResolver.get_base_field_for_player(game_state, player_id)
	var opponent_positions: Array[Vector2] = get_piece_positions_for_player(game_state.pieces, 1 - player_id)
	if opponent_positions.is_empty():
		return 0.0

	var min_distance_before: float = get_min_distance_to_positions(current_base_pos, opponent_positions)
	var min_distance_after: float = get_min_distance_to_positions(new_base_pos, opponent_positions)
	var avg_distance_before: float = get_average_distance_to_positions(current_base_pos, opponent_positions)
	var avg_distance_after: float = get_average_distance_to_positions(new_base_pos, opponent_positions)
	return (min_distance_after - min_distance_before) * SCORE_MOVE_BASE_MIN_DISTANCE \
		+ (avg_distance_after - avg_distance_before) * SCORE_MOVE_BASE_AVG_DISTANCE

func score_shared_control_effect(game_state: GameStateData, player_id: int, card: Card, move: Dictionary, piece_pos_after_move: Vector2, board_size: int) -> float:
	var simulated_pieces: Dictionary = AIStateSimulator.apply_candidate_to_pieces(game_state.pieces, move)
	var shared_piece: Piece = simulated_pieces.get(piece_pos_after_move, null) as Piece
	if shared_piece == null:
		return 0.0

	var own_future_moves: Array[Vector2] = MoveRules.get_piece_moves_for_player(
		simulated_pieces,
		piece_pos_after_move,
		player_id,
		board_size,
		game_state.board_effects
	)
	var score: float = float(own_future_moves.size()) * SCORE_SHARED_OWN_MOBILITY
	for target_pos: Vector2 in own_future_moves:
		var target_piece: Piece = simulated_pieces.get(target_pos, null) as Piece
		if target_piece != null && CardEffectResolver.get_player_id_for_color(target_piece.color) != player_id:
			score += get_piece_target_score(target_piece) * 0.35

	var opponent_player_id: int = 1 - player_id
	var opponent_moves: Array[Vector2] = MoveRules.get_piece_moves_for_player(
		simulated_pieces,
		piece_pos_after_move,
		opponent_player_id,
		board_size,
		game_state.board_effects
	)
	score -= float(opponent_moves.size()) * PENALTY_SHARED_OPPONENT_MOBILITY
	for opponent_target_pos: Vector2 in opponent_moves:
		var immediate_target: Piece = simulated_pieces.get(opponent_target_pos, null) as Piece
		if immediate_target != null && CardEffectResolver.get_player_id_for_color(immediate_target.color) == player_id:
			score -= get_piece_target_score(immediate_target)

		var opponent_future_pieces: Dictionary = simulate_piece_move(simulated_pieces, piece_pos_after_move, opponent_target_pos)
		var future_moves: Array[Vector2] = MoveRules.get_piece_moves_for_player(
			opponent_future_pieces,
			opponent_target_pos,
			opponent_player_id,
			board_size,
			game_state.board_effects
		)
		for future_target_pos: Vector2 in future_moves:
			var future_target: Piece = opponent_future_pieces.get(future_target_pos, null) as Piece
			if future_target != null && CardEffectResolver.get_player_id_for_color(future_target.color) == player_id:
				score -= get_piece_target_score(future_target) * PENALTY_SHARED_FUTURE_THREAT_MULTIPLIER

	return score

func get_effect_source_pos(card: Card, from_pos: Vector2, to_pos: Vector2) -> Vector2:
	if card.effect_trigger == CardEffect.TRIGGER_ON_MOVE \
		or card.effect_trigger == CardEffect.TRIGGER_ON_CAPTURE \
		or card.effect_trigger == CardEffect.TRIGGER_ON_EXPIRE:
		return to_pos
	return from_pos

func get_frozen_piece_score(game_state: GameStateData, piece: Piece, piece_pos: Vector2, target_player_id: int, board_size: int) -> float:
	var score: float = SCORE_FROZEN_ENEMY_PIECE
	if CardEffectResolver.is_king_piece(piece):
		score += SCORE_CAPTURE_KING * 0.65
	elif piece.attached_card != null:
		score += SCORE_CAPTURE_CARD * 0.45
		score += max(0, piece.turns_remaining) * 4.0

	var moves_before_freeze: Array[Vector2] = MoveRules.get_piece_moves_for_player(
		game_state.pieces,
		piece_pos,
		target_player_id,
		board_size,
		game_state.board_effects
	)
	score += float(moves_before_freeze.size()) * 4.0
	return score

func card_effect_targets_player(card: Card, target_player_id: int) -> bool:
	var effect_target_player_id: int = int(card.effect_settings.get("target_player_id", -1))
	return effect_target_player_id == -1 || effect_target_player_id == target_player_id

func count_valid_turn_moves_for_player(game_state: GameStateData, pieces: Dictionary, player_id: int, board_effects: Array, board_size: int) -> int:
	var hand_cards: Array[Card] = AIStateSimulator.get_hand_cards_from_state(game_state, player_id)
	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	return MoveRules.get_valid_turn_moves(
		pieces,
		player_color,
		hand_cards,
		true,
		board_size,
		board_effects
	).size()

func get_piece_positions_for_player(pieces: Dictionary, player_id: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	for position_value in pieces:
		var position: Vector2 = CardEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = pieces[position_value] as Piece
		if piece != null && piece.color == player_color:
			positions.append(position)
	return positions

func get_min_distance_to_positions(source_pos: Vector2, positions: Array[Vector2]) -> float:
	var min_distance: float = INF
	for target_pos: Vector2 in positions:
		var distance: float = get_manhattan_distance(source_pos, target_pos)
		if distance < min_distance:
			min_distance = distance
	return min_distance

func get_average_distance_to_positions(source_pos: Vector2, positions: Array[Vector2]) -> float:
	if positions.is_empty():
		return 0.0

	var total_distance: float = 0.0
	for target_pos: Vector2 in positions:
		total_distance += get_manhattan_distance(source_pos, target_pos)
	return total_distance / float(positions.size())

func get_manhattan_distance(left: Vector2, right: Vector2) -> float:
	return abs(left.x - right.x) + abs(left.y - right.y)

func simulate_piece_move(source_pieces: Dictionary, from_pos: Vector2, to_pos: Vector2) -> Dictionary:
	var simulated_pieces: Dictionary = AIStateSimulator.clone_pieces(source_pieces)
	var moving_piece: Piece = simulated_pieces.get(from_pos, null) as Piece
	if moving_piece == null:
		return simulated_pieces

	simulated_pieces.erase(from_pos)
	moving_piece.position = to_pos
	simulated_pieces[to_pos] = moving_piece
	return simulated_pieces

func get_piece_target_score(piece: Piece) -> float:
	if piece == null:
		return 0.0
	if CardEffectResolver.is_king_piece(piece):
		return SCORE_CAPTURE_KING

	var score: float = SCORE_CAPTURE_PIECE
	if piece.attached_card != null:
		score += SCORE_CAPTURE_CARD
		score += max(0, piece.turns_remaining) * 8.0
	return score
