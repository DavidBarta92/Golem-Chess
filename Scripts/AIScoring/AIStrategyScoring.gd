extends RefCounted
class_name AIStrategyScoring

## What the strategy mode the AIStrategyDirector picked adds to a plan: the
## opening's development, walking the crown home, staging golems near the enemy
## base, guarding the own base.

const SCORE_OPENING_CENTER_ENTRY: float = 130.0
const SCORE_OPENING_CENTER_COUNT: float = 46.0
const SCORE_OPENING_COMPLETED: float = 180.0
const SCORE_DEFENSE_THREAT_REDUCTION: float = 120.0
const SCORE_DEFENSE_BASE_GUARD: float = 52.0
const SCORE_DEFENSE_CAPTURE_BEARER: float = 1800.0
## A step of the crowned golem that shortens its way home onto a square the
## enemy cannot take (score_bearer_safe_step), while the crown is what the turn
## is about: above most of what the threat map offers, which runs in the
## thousands and would otherwise outbid the walk. The crown race alone does not
## always pay for a step (a full meter's floor, a route past the horizon).
## A plan taking the enemy's crown gets the same (score_takes_enemy_crown).
const SCORE_BEARER_SAFE_STEP: float = 3000.0
## How much more the strategy modes weigh the crown's progress, on top of the
## crown race every plan is scored by.
const CROWN_PUSH_STRATEGY_WEIGHT: float = 1.6
const CROWN_STAGING_ENDGAME_WEIGHT: float = 1.2
const CROWN_STAGING_ATTACK_WEIGHT: float = 0.8
const CROWN_STAGING_ROUTE_SETUP_WEIGHT: float = 0.35

var context: AIScoringContext
var reach: AIReach
var effect_scoring: AIEffectScoring
var crown_race: AICrownRace
var move_scoring: AIMoveScoring

func _init(
	new_context: AIScoringContext,
	new_reach: AIReach,
	new_effect_scoring: AIEffectScoring,
	new_crown_race: AICrownRace,
	new_move_scoring: AIMoveScoring,
) -> void:
	context = new_context
	reach = new_reach
	effect_scoring = new_effect_scoring
	crown_race = new_crown_race
	move_scoring = new_move_scoring

func score_strategy_mode_for_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	if context.strategy_context.is_empty() or int(context.strategy_context.get("player_id", -1)) != player_id:
		return 0.0
	# On a turn the threats go unseen, the defensive modes have nothing to defend.
	if !context.sees_threats_this_turn and str(context.strategy_context.get("mode", "")) in ["soft_defense", "emergency_defense"]:
		return 0.0

	match str(context.strategy_context.get("mode", "")):
		"opening":
			return score_opening_strategy_plan(game_state, player_id, plan, board_size)
		"crown_push":
			return score_crown_push_strategy_plan(game_state, player_id, plan, board_size)
		"endgame_finish":
			return score_crown_staging_strategy_plan(game_state, player_id, plan, board_size) * CROWN_STAGING_ENDGAME_WEIGHT
		"crown_attack":
			return score_crown_staging_strategy_plan(game_state, player_id, plan, board_size) * CROWN_STAGING_ATTACK_WEIGHT
		"soft_defense":
			return score_defense_strategy_plan(game_state, player_id, plan, board_size, 1.0)
		"emergency_defense":
			return score_defense_strategy_plan(game_state, player_id, plan, board_size, 2.0)
		"route_setup":
			return score_crown_staging_strategy_plan(game_state, player_id, plan, board_size) * CROWN_STAGING_ROUTE_SETUP_WEIGHT
		_:
			return 0.0

func score_opening_strategy_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	if game_state == null or plan.is_empty():
		return 0.0

	var simulated_state: GameStateData = context.get_simulated_turn_plan_state(game_state, player_id, plan, board_size)
	if simulated_state.game_over:
		return 0.0

	var before_center_count: int = count_player_pieces_in_strategy_center(game_state, player_id, board_size)
	var after_center_count: int = count_player_pieces_in_strategy_center(simulated_state, player_id, board_size)
	var target_count: int = int(context.strategy_context.get("opening_target_count", 3))
	var score: float = float(after_center_count - before_center_count) * SCORE_OPENING_CENTER_ENTRY
	score += float(after_center_count) * SCORE_OPENING_CENTER_COUNT
	if before_center_count < target_count and after_center_count >= target_count:
		score += SCORE_OPENING_COMPLETED

	var move: Dictionary = plan.get("move", {})
	if !move.is_empty():
		var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
		var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
		if !is_strategy_center_square(from_pos) and is_strategy_center_square(to_pos):
			score += SCORE_OPENING_CENTER_ENTRY
		score += (get_distance_to_board_center(from_pos, board_size) - get_distance_to_board_center(to_pos, board_size)) * 22.0
	return score

## With the crown on the board, everything goes into walking its bearer home.
func score_crown_push_strategy_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	if game_state == null or plan.is_empty():
		return 0.0
	var simulated_state: GameStateData = context.get_simulated_turn_plan_state(game_state, player_id, plan, board_size)
	if simulated_state.game_over:
		return 0.0
	return crown_race.get_crown_race_value_delta(game_state, simulated_state, player_id, board_size) * CROWN_PUSH_STRATEGY_WEIGHT \
		+ score_bearer_safe_step(game_state, simulated_state, player_id, plan, board_size) \
		+ score_takes_enemy_crown(game_state, player_id, plan)

## Taking the enemy's crown is paid like a safe step, so the size of that
## reward alone never decides between the two.
func score_takes_enemy_crown(game_state: GameStateData, player_id: int, plan: Dictionary) -> float:
	var move: Dictionary = plan.get("move", {})
	if move.is_empty():
		return 0.0
	var captured_piece: Piece = AIStateSimulator.get_captured_piece(game_state.pieces, move)
	if captured_piece == null or !captured_piece.has_crown or BoardConfig.get_player_id_for_color(captured_piece.color) == player_id:
		return 0.0
	return SCORE_BEARER_SAFE_STEP

## SCORE_BEARER_SAFE_STEP for a plan that walks the crowned golem nearer the base,
## counting what comes next if the step ends its stamp, onto a square the enemy
## cannot take. Not for a step that drains the own stamps: Black Hole's walk has
## its own price (AIMoveScoring.score_own_drain_step).
func score_bearer_safe_step(game_state: GameStateData, simulated_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	var move: Dictionary = plan.get("move", {})
	if move.is_empty() or !AIStateSimulator.is_own_crown_candidate(game_state.pieces, move, player_id):
		return 0.0
	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	if simulated_state.get_crowned_piece_position(player_id) != to_pos:
		return 0.0
	var stamp: Stamp = AIStateSimulator.get_stamp_for_candidate(game_state.pieces, move)
	var captured_piece: Piece = AIStateSimulator.get_captured_piece(game_state.pieces, move)
	if move_scoring.score_own_drain_step(game_state, player_id, game_state.get_piece(from_pos), stamp, from_pos, to_pos, captured_piece, move, board_size) < 0.0:
		return 0.0
	var turns_before: float = reach.get_golem_route_turns(game_state, player_id, from_pos, board_size)
	var turns_after: float = reach.get_golem_route_turns(simulated_state, player_id, to_pos, board_size)
	if turns_after < 0.0 or (turns_before >= 0.0 and turns_after >= turns_before):
		return 0.0
	return 0.0 if reach.is_square_attacked_by(simulated_state, 1 - player_id, to_pos, board_size) else SCORE_BEARER_SAFE_STEP

## The crown is (nearly) charged: walk golems into reach of the enemy base, so
## the crown has a bearer close to it. Scored by the bearer's route, or while
## the crown is not down, by that of the best golem to put it on; whether to
## put it down is the crown race's call.
func score_crown_staging_strategy_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	if game_state == null or plan.is_empty():
		return 0.0
	var simulated_state: GameStateData = context.get_simulated_turn_plan_state(game_state, player_id, plan, board_size)
	if simulated_state.game_over:
		return 0.0
	return reach.get_crown_route_bonus(crown_race.get_crown_staging_route_turns(simulated_state, player_id, board_size)) \
		- reach.get_crown_route_bonus(crown_race.get_crown_staging_route_turns(game_state, player_id, board_size))

func score_defense_strategy_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int, urgency: float) -> float:
	if game_state == null or plan.is_empty():
		return 0.0

	var simulated_state: GameStateData = context.get_simulated_turn_plan_state(game_state, player_id, plan, board_size)
	var before_threat: float = score_base_threat_against_player(game_state, player_id, board_size)
	var after_threat: float = score_base_threat_against_player(simulated_state, player_id, board_size)
	var score: float = (before_threat - after_threat) * SCORE_DEFENSE_THREAT_REDUCTION * urgency

	var move: Dictionary = plan.get("move", {})
	if !move.is_empty():
		var captured_piece: Piece = AIStateSimulator.get_captured_piece(game_state.pieces, move)
		if captured_piece != null and BoardConfig.get_player_id_for_color(captured_piece.color) != player_id:
			if captured_piece.has_crown:
				score += SCORE_DEFENSE_CAPTURE_BEARER * urgency
			else:
				score += effect_scoring.get_piece_target_score(captured_piece) * 0.8 * urgency

		var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
		var own_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, player_id)
		if AIBoardMath.get_manhattan_distance(to_pos, own_base) <= 2.0:
			score += SCORE_DEFENSE_BASE_GUARD * urgency
	return score

func score_base_threat_against_player(game_state: GameStateData, player_id: int, board_size: int) -> float:
	if game_state == null:
		return 0.0

	var enemy_player_id: int = 1 - player_id
	var enemy_color: int = StampEffectResolver.get_color_for_player_id(enemy_player_id)
	var own_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, player_id)
	var enemy_crown_turns: int = AICrownRace.get_crown_turns_to_ready(game_state, enemy_player_id)
	var enemy_crown_soon: bool = enemy_crown_turns <= 1
	var threat: float = 0.0
	for position_value in game_state.pieces:
		var pos: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != enemy_color:
			continue

		var distance: float = AIBoardMath.get_manhattan_distance(pos, own_base)
		if distance <= 3.0:
			threat += float(board_size) - distance
		if piece.has_crown:
			threat += 18.0
			if distance <= 3.0:
				threat += 24.0
		elif enemy_crown_soon and distance <= 2.0:
			threat += 8.0
	return threat

func count_player_pieces_in_strategy_center(game_state: GameStateData, player_id: int, board_size: int) -> int:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var count: int = 0
	for position_value in game_state.pieces:
		var pos: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null and piece.color == player_color and is_strategy_center_square(pos):
			count += 1
	return count

func is_strategy_center_square(pos: Vector2) -> bool:
	var center_zone_keys: Array = context.strategy_context.get("center_zone_keys", [])
	return center_zone_keys.has(context.vector_hash(pos))

func get_distance_to_board_center(pos: Vector2, board_size: int) -> float:
	var center: Vector2 = Vector2(float(board_size - 1) / 2.0, float(board_size - 1) / 2.0)
	return AIBoardMath.get_manhattan_distance(pos, center)
