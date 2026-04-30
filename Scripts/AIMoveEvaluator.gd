extends RefCounted
class_name AIMoveEvaluator

const DIFFICULTY_EASY: String = "easy"
const DIFFICULTY_NORMAL: String = "normal"
const DIFFICULTY_HARD: String = "hard"

const SCORE_WIN: float = 100000.0
const SCORE_CAPTURE_KING: float = 90000.0
const SCORE_ATTACH_KING: float = 600.0
const SCORE_THREATEN_KING: float = 420.0
const SCORE_CAPTURE_PIECE: float = 45.0
const SCORE_CAPTURE_CARD: float = 75.0
const SCORE_KING_BASE_PROGRESS: float = 35.0
const SCORE_ATTACH_CARD: float = 10.0
const SCORE_CENTER: float = 4.0
const SCORE_USE_EXISTING_CARD: float = 4.0
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
		score += score_attached_card(game_state, player_id, moving_piece, card, from_pos, to_pos, captured_piece, board_size)
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
	board_size: int
) -> float:
	if card == null:
		return 0.0

	var score: float = SCORE_ATTACH_CARD
	if card.card_name == MoveRules.KING_CARD_NAME:
		score += SCORE_ATTACH_KING

	score += max(0, card.duration) * 3.0
	score += score_card_effect(game_state, player_id, moving_piece, card, from_pos, to_pos, captured_piece, board_size)
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
	board_size: int
) -> float:
	if card == null or !card.has_effect():
		return 0.0

	var score: float = 0.0
	match card.effect_type:
		CardEffect.TYPE_SHARED_CONTROL:
			score += 38.0
		CardEffect.TYPE_INVISIBLE_TO_ENEMY:
			score += 32.0
			if card.card_name == MoveRules.KING_CARD_NAME:
				score += 80.0
		CardEffect.TYPE_STEAL_CARD:
			score += 50.0
		CardEffect.TYPE_GRANT_CARD:
			score += 45.0
		CardEffect.TYPE_MOVE_BASE:
			score += 30.0
		CardEffect.TYPE_INVALID_SQUARES:
			score += 22.0
		CardEffect.TYPE_FROZEN_SQUARES:
			score += 28.0
		CardEffect.TYPE_BOMB:
			score += score_bomb_effect(game_state, player_id, moving_piece, card, from_pos, board_size)
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
