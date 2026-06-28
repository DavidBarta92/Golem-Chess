extends RefCounted
class_name AIMoveEvaluator

const MIN_DIFFICULTY_LEVEL: int = 1
const MAX_DIFFICULTY_LEVEL: int = 12
const DEFAULT_DIFFICULTY_LEVEL: int = 12

const DIFFICULTY_CONFIGS: Dictionary = {
	1: {
		"search_depth": 1,
		"own_top_n": 1,
		"opponent_top_n": 0,
		"randomness": 45.0,
		"opponent_response_weight": 0.0,
	},
	2: {
		"search_depth": 1,
		"own_top_n": 2,
		"opponent_top_n": 0,
		"randomness": 35.0,
		"opponent_response_weight": 0.0,
	},
	3: {
		"search_depth": 1,
		"own_top_n": 3,
		"opponent_top_n": 0,
		"randomness": 28.0,
		"opponent_response_weight": 0.0,
	},
	4: {
		"search_depth": 1,
		"own_top_n": 4,
		"opponent_top_n": 0,
		"randomness": 20.0,
		"opponent_response_weight": 0.0,
	},
	5: {
		"search_depth": 2,
		"own_top_n": 5,
		"opponent_top_n": 2,
		"randomness": 15.0,
		"opponent_response_weight": 0.35,
	},
	6: {
		"search_depth": 2,
		"own_top_n": 6,
		"opponent_top_n": 4,
		"randomness": 10.0,
		"opponent_response_weight": 0.50,
	},
	7: {
		"search_depth": 2,
		"own_top_n": 7,
		"opponent_top_n": 6,
		"randomness": 6.0,
		"opponent_response_weight": 0.58,
	},
	8: {
		"search_depth": 2,
		"own_top_n": 8,
		"opponent_top_n": 8,
		"randomness": 4.0,
		"opponent_response_weight": 0.64,
	},
	9: {
		"search_depth": 2,
		"own_top_n": 9,
		"opponent_top_n": 10,
		"randomness": 2.0,
		"opponent_response_weight": 0.70,
	},
	10: {
		"search_depth": 2,
		"own_top_n": 8,
		"opponent_top_n": 6,
		"randomness": 1.0,
		"opponent_response_weight": 0.76,
	},
	11: {
		"search_depth": 2,
		"own_top_n": 8,
		"opponent_top_n": 6,
		"randomness": 0.0,
		"opponent_response_weight": 0.80,
	},
	12: {
		"search_depth": 2,
		"own_top_n": 9,
		"opponent_top_n": 7,
		"randomness": 0.0,
		"opponent_response_weight": 0.82,
	},
}

const SCORE_WIN: float = 100000.0
const SCORE_CAPTURE_SEEKER: float = 160.0
const SCORE_ATTACH_SEEKER: float = 35.0
const SCORE_THREATEN_SEEKER: float = 420.0
const SCORE_SEEKER_BASE_ENTRY_THREAT: float = 900.0
const SCORE_CAPTURE_BASE_STAGING_PIECE: float = 180.0
const SCORE_CAPTURE_PIECE: float = 45.0
const SCORE_CAPTURE_STAMP: float = 75.0
const SCORE_SEEKER_BASE_PROGRESS: float = 35.0
const SCORE_ATTACH_STAMP: float = 10.0
const SCORE_CENTER: float = 4.0
const SCORE_USE_EXISTING_STAMP: float = 4.0
const SCORE_ATTACH_SETUP_MOBILITY: float = 5.0
const PENALTY_ATTACH_SETUP_NO_MOVE: float = 8.0
const PENALTY_GIVE_STAMP: float = 35.0
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
const PENALTY_SEEKER_THREATENED: float = 1400.0
const PENALTY_PIECE_THREATENED: float = 35.0
const DEFAULT_OPPONENT_RESPONSE_WEIGHT: float = 0.62
const DEEP_ROOT_BEAM_WIDTH: int = 4
const DEEP_OPPONENT_FIRST_BEAM_WIDTH: int = 4
const DEEP_OWN_SECOND_BEAM_WIDTH: int = 2
const DEEP_OPPONENT_SECOND_BEAM_WIDTH: int = 2
const DEEP_SECOND_OWN_WEIGHT: float = 0.72
const DEEP_SECOND_OPPONENT_WEIGHT: float = 0.62
const STAMP_VALUE_ATTACH_PLAY_WEIGHT: float = 0.35
const STAMP_VALUE_ATTACH_EXCHANGE_WEIGHT: float = 0.6
const STAMP_VALUE_CAPTURE_WEIGHT: float = 1.2
const ROOT_FULL_SCORE_LIMIT: int = 48
const RESPONSE_FULL_SCORE_LIMIT: int = 24
const HAND_DECK_ECONOMY_WEIGHT: float = 0.18
const SCORE_TWO_TURN_BASE_THREAT: float = 260.0
const SCORE_FORCE_DEFENSE: float = 120.0
const SCORE_THREAT_MAP_OWN_ATTACK: float = 14.0
const PENALTY_THREAT_MAP_EXPOSURE: float = 18.0
const SCORE_HAND_SYNERGY: float = 18.0
const SCORE_SEEKER_ROUTE_STAGING: float = 32.0
const SCORE_SEEKER_ATTACH_IN_ROUTE: float = 220.0
const PENALTY_SEEKER_ATTACH_OUT_OF_ROUTE: float = 180.0
const PENALTY_EARLY_SEEKER_COMMITMENT: float = 520.0
const PENALTY_SEEKER_CAPTURE_DISTRACTION: float = 650.0
const SCORE_ACTIVE_SEEKER_PUSH: float = 75.0
const SCORE_ACTIVE_SEEKER_CLEAR_ROUTE: float = 95.0
const PENALTY_ACTIVE_SEEKER_DANGER: float = 60.0
const SCORE_ACTIVE_SEEKER_FINISH: float = 850.0
const PENALTY_ACTIVE_SEEKER_RETREAT: float = 360.0
const PENALTY_ACTIVE_SEEKER_STALL: float = 140.0
const PENALTY_IGNORE_ACTIVE_SEEKER_PUSH: float = 380.0
const SCORE_FORCED_CLOSING_ROUTE_PROGRESS: float = 240.0
const SCORE_HOLD_SEEKER_STAGING_SQUARE: float = 620.0
const PENALTY_LEAVE_SEEKER_STAGING_SQUARE: float = 780.0
const PENALTY_ENDGAME_NON_CLOSING_CAPTURE: float = 520.0
const PENALTY_NON_SEEKER_BASE_ENTRY_WHILE_SEEKER_ACTIVE: float = 520.0
const PENALTY_NON_SEEKER_BASE_BLOCKS_SEEKER_PLAN: float = 420.0
const SCORE_CLEAR_OWN_NON_SEEKER_FROM_ENEMY_BASE: float = 360.0
const PENALTY_REPEAT_LAST_MOVE: float = 170.0
const MAX_SEEKER_ROUTE_DISTANCE: int = 8
const SCORE_OPENING_CENTER_ENTRY: float = 130.0
const SCORE_OPENING_CENTER_COUNT: float = 46.0
const SCORE_OPENING_COMPLETED: float = 180.0
const SCORE_DEFENSE_THREAT_REDUCTION: float = 120.0
const SCORE_DEFENSE_CAPTURE_SEEKER: float = 1800.0
const SCORE_DEFENSE_BASE_GUARD: float = 52.0
const SCORE_DEFENSE_PUSH_SEEKER_BACK: float = 420.0
const PENALTY_IGNORE_ENEMY_SEEKER_PUSH: float = 2600.0
const SCORE_MOVE_BASE_PIECE_ESCAPE: float = 950.0
const PENALTY_MOVE_BASE_PIECE_THREATENED_BY_SEEKER: float = 1800.0
const SCORE_MATERIAL_ADVANTAGE_FINISH: float = 360.0
const PENALTY_AHEAD_NON_CLOSING_CAPTURE: float = 380.0
const SCORE_ENDGAME_SEEKER_ROUTE: float = 95.0
const SCORE_ENDGAME_SEEKER_ATTACH_READY: float = 520.0
const SCORE_ENDGAME_SEEKER_ATTACH_NEAR: float = 260.0
const PENALTY_ENDGAME_NON_SEEKER_ATTACH: float = 75.0
const PENALTY_ENDGAME_EXCHANGE_SEEKER_PLAN: float = 420.0
const SCORE_EMERGENCY_PREVENT_BASE_WIN: float = 50000.0
const PENALTY_ALLOW_IMMEDIATE_BASE_WIN: float = 65000.0
const PENALTY_EXCHANGE_LAST_SEEKER: float = 900.0
const PENALTY_MOVE_OFF_ENEMY_BASE_WITHOUT_SEEKER: float = 450.0

var difficulty_level: int = DEFAULT_DIFFICULTY_LEVEL
var search_depth: int = 1
var own_top_n: int = 6
var opponent_top_n: int = 4
var randomness: float = 8.0
var opponent_response_weight: float = DEFAULT_OPPONENT_RESPONSE_WEIGHT
var last_profile: Dictionary = {}
var fast_score_cache: Dictionary = {}
var full_score_cache: Dictionary = {}
var move_score_cache: Dictionary = {}
var response_score_cache: Dictionary = {}
var stamp_cache: Dictionary = {}
var seeker_route_cache: Dictionary = {}
var strategy_context: Dictionary = {}

func _init(new_difficulty_level = DEFAULT_DIFFICULTY_LEVEL):
	set_difficulty_level(new_difficulty_level)

func set_difficulty_level(new_difficulty_level) -> void:
	difficulty_level = parse_difficulty_level(new_difficulty_level)
	apply_difficulty_config(difficulty_level)

func set_difficulty(new_difficulty_level) -> void:
	set_difficulty_level(new_difficulty_level)

func set_strategy_context(new_strategy_context: Dictionary) -> void:
	strategy_context = new_strategy_context.duplicate()

func parse_difficulty_level(raw_difficulty_level) -> int:
	var level: int = DEFAULT_DIFFICULTY_LEVEL
	if raw_difficulty_level is int:
		level = int(raw_difficulty_level)
	elif raw_difficulty_level is float:
		level = int(raw_difficulty_level)
	elif raw_difficulty_level is String:
		var cleaned_level: String = str(raw_difficulty_level).strip_edges()
		if cleaned_level.is_valid_int():
			level = int(cleaned_level)
	return clampi(level, MIN_DIFFICULTY_LEVEL, MAX_DIFFICULTY_LEVEL)

func apply_difficulty_config(level: int) -> void:
	var clamped_level: int = clampi(level, MIN_DIFFICULTY_LEVEL, MAX_DIFFICULTY_LEVEL)
	var config: Dictionary = DIFFICULTY_CONFIGS.get(clamped_level, DIFFICULTY_CONFIGS[6])
	search_depth = int(config.get("search_depth", 2))
	own_top_n = int(config.get("own_top_n", 6))
	opponent_top_n = int(config.get("opponent_top_n", 4))
	randomness = float(config.get("randomness", 8.0))
	opponent_response_weight = float(config.get("opponent_response_weight", DEFAULT_OPPONENT_RESPONSE_WEIGHT))

func choose_best_move(game_state: GameStateData, player_id: int, valid_moves: Array[Dictionary], board_size: int = BoardConfig.BOARD_SIZE) -> Dictionary:
	if game_state == null or valid_moves.is_empty():
		return {}

	var best_move: Dictionary = {}
	var best_score: float = -INF
	for move: Dictionary in valid_moves:
		var move_score: float = score_move_cached(game_state, player_id, move, board_size)
		if randomness > 0.0:
			move_score += randf_range(-randomness, randomness)

		if best_move.is_empty() or move_score > best_score:
			best_move = move
			best_score = move_score

	return best_move

func choose_best_move_with_response(
	game_state: GameStateData,
	player_id: int,
	valid_moves: Array[Dictionary],
	board_size: int = BoardConfig.BOARD_SIZE,
	turn_planner = null,
	profile: Dictionary = {}
) -> Dictionary:
	if game_state == null or valid_moves.is_empty():
		return {}
	if !should_score_opponent_responses(turn_planner):
		increment_profile_count(profile, "evaluated_own_plans", valid_moves.size())
		return choose_best_move(game_state, player_id, valid_moves, board_size)

	var best_move: Dictionary = {}
	var best_score: float = -INF
	profile["move_response_candidate_count"] = valid_moves.size()
	for move: Dictionary in valid_moves:
		var plan: Dictionary = create_move_response_plan(player_id, move)
		var move_score: float = score_turn_plan_with_response(game_state, player_id, plan, board_size, turn_planner, profile)
		if randomness > 0.0:
			move_score += randf_range(-randomness, randomness)

		if best_move.is_empty() or move_score > best_score:
			best_move = move
			best_score = move_score

	profile["best_move_response_score"] = best_score
	return best_move

func create_move_response_plan(player_id: int, move: Dictionary) -> Dictionary:
	return {
		"actions": [{
			"type": "move_piece",
			"player_id": player_id,
			"from": AIStateSimulator.get_move_from(move),
			"to": AIStateSimulator.get_move_to(move),
		}],
		"move": move,
		"setup_attach_actions": [],
		"plan_type": "move_response",
	}

func choose_best_turn_plan(game_state: GameStateData, player_id: int, turn_plans: Array[Dictionary], board_size: int = BoardConfig.BOARD_SIZE, turn_planner = null) -> Dictionary:
	if game_state == null or turn_plans.is_empty():
		last_profile = create_profile(0)
		return {}

	reset_decision_caches()
	var profile: Dictionary = create_profile(turn_plans.size())
	var start_usec: int = Time.get_ticks_usec()
	var scored_plans: Array[Dictionary] = score_own_turn_plans(game_state, player_id, turn_plans, board_size, profile)
	var response_candidates: Array[Dictionary] = get_response_candidate_plans(scored_plans)
	profile["own_response_candidate_count"] = response_candidates.size()
	if should_score_opponent_responses(turn_planner):
		profile["own_response_pruned_plan_count"] = max(0, turn_plans.size() - response_candidates.size())

	var best_plan: Dictionary = choose_best_scored_plan(scored_plans, profile)
	var best_score: float = float(profile.get("best_plan_score", -INF))
	if should_score_opponent_responses(turn_planner):
		best_plan = {}
		best_score = -INF
		for scored_plan: Dictionary in response_candidates:
			var plan: Dictionary = scored_plan.get("plan", {})
			var own_score: float = float(scored_plan.get("score", 0.0))
			var plan_score: float = 0.0
			if should_score_deep_beam(turn_planner):
				plan_score = score_deep_beam_turn_plan(game_state, player_id, plan, own_score, board_size, turn_planner, profile)
			else:
				var opponent_response_score: float = score_best_opponent_response(
					game_state,
					player_id,
					plan,
					board_size,
					turn_planner,
					profile
				)
				plan_score = own_score - opponent_response_score * opponent_response_weight
			if randomness > 0.0:
				plan_score += randf_range(-randomness, randomness)

			if best_plan.is_empty() or plan_score > best_score:
				best_plan = plan
				best_score = plan_score

	profile["choose_best_turn_plan_ms"] = usec_to_ms(Time.get_ticks_usec() - start_usec)
	profile["best_plan_score"] = best_score
	profile["best_plan_type"] = str(best_plan.get("plan_type", ""))
	add_best_plan_breakdown_to_profile(profile, game_state, player_id, best_plan, board_size)
	profile["strategy_mode"] = str(strategy_context.get("mode", ""))
	profile["strategy_memory"] = strategy_context.get("memory", {}).duplicate()
	profile["opening_completed"] = bool(strategy_context.get("opening_completed", false))
	last_profile = profile
	return best_plan

func add_best_plan_breakdown_to_profile(profile: Dictionary, game_state: GameStateData, player_id: int, best_plan: Dictionary, board_size: int) -> void:
	if best_plan.is_empty():
		return
	var breakdown: Dictionary = score_turn_plan_breakdown(game_state, player_id, best_plan, board_size)
	profile["best_plan_move_score"] = float(breakdown.get("move", 0.0))
	profile["best_plan_setup_score"] = float(breakdown.get("setup", 0.0))
	profile["best_plan_action_count_score"] = float(breakdown.get("action_count", 0.0))
	profile["best_plan_economy_score"] = float(breakdown.get("economy", 0.0))
	profile["best_plan_threat_score"] = float(breakdown.get("threat", 0.0))
	profile["best_plan_seeker_route_score"] = float(breakdown.get("seeker_route", 0.0))
	profile["best_plan_strategy_score"] = float(breakdown.get("strategy", 0.0))
	profile["best_plan_hard_rule_score"] = float(breakdown.get("hard_rules", 0.0))

func score_own_turn_plans(game_state: GameStateData, player_id: int, turn_plans: Array[Dictionary], board_size: int, profile: Dictionary) -> Array[Dictionary]:
	var scored_plans: Array[Dictionary] = []
	var own_score_start_usec: int = Time.get_ticks_usec()
	var fast_scored_plans: Array[Dictionary] = []
	for plan: Dictionary in turn_plans:
		fast_scored_plans.append({
			"plan": plan,
			"score": score_turn_plan_fast_cached(game_state, player_id, plan, board_size),
		})

	var full_score_limit: int = get_root_full_score_limit(turn_plans.size())
	var ordered_candidates: Array[Dictionary] = get_top_scored_plans(fast_scored_plans, full_score_limit)
	for scored_plan: Dictionary in ordered_candidates:
		var plan: Dictionary = scored_plan.get("plan", {})
		scored_plans.append({
			"plan": plan,
			"score": score_turn_plan_cached(game_state, player_id, plan, board_size),
		})
	add_profile_time(profile, "evaluator_ms", Time.get_ticks_usec() - own_score_start_usec)
	increment_profile_count(profile, "evaluated_own_plans", ordered_candidates.size())
	profile["root_fast_prefilter_count"] = turn_plans.size()
	profile["root_full_score_count"] = ordered_candidates.size()
	return scored_plans

func get_root_full_score_limit(plan_count: int) -> int:
	return mini(maxi(own_top_n * 4, 12), mini(ROOT_FULL_SCORE_LIMIT, plan_count))

func should_score_opponent_responses(turn_planner) -> bool:
	return search_depth >= 2 \
		&& turn_planner != null \
		&& opponent_response_weight > 0.0 \
		&& own_top_n > 0 \
		&& opponent_top_n > 0

func should_score_deep_beam(turn_planner) -> bool:
	return search_depth >= 4 && should_score_opponent_responses(turn_planner)

func get_response_candidate_plans(scored_plans: Array[Dictionary]) -> Array[Dictionary]:
	if scored_plans.is_empty():
		var empty_scored_plans: Array[Dictionary] = []
		return empty_scored_plans
	if search_depth < 2 or own_top_n <= 0:
		var empty_candidate_plans: Array[Dictionary] = []
		return empty_candidate_plans
	var candidate_limit: int = DEEP_ROOT_BEAM_WIDTH if search_depth >= 4 else own_top_n
	return get_top_scored_plans(scored_plans, candidate_limit)

func choose_best_scored_plan(scored_plans: Array[Dictionary], profile: Dictionary) -> Dictionary:
	var best_plan: Dictionary = {}
	var best_score: float = -INF
	for scored_plan: Dictionary in scored_plans:
		var plan: Dictionary = scored_plan.get("plan", {})
		var plan_score: float = float(scored_plan.get("score", 0.0))
		if randomness > 0.0:
			plan_score += randf_range(-randomness, randomness)

		if best_plan.is_empty() or plan_score > best_score:
			best_plan = plan
			best_score = plan_score

	profile["best_plan_score"] = best_score
	profile["best_plan_type"] = str(best_plan.get("plan_type", ""))
	return best_plan

func score_turn_plan_with_response(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int = BoardConfig.BOARD_SIZE, turn_planner = null, profile: Dictionary = {}) -> float:
	var own_score_start_usec: int = Time.get_ticks_usec()
	var own_score: float = score_turn_plan_cached(game_state, player_id, plan, board_size)
	add_profile_time(profile, "evaluator_ms", Time.get_ticks_usec() - own_score_start_usec)
	increment_profile_count(profile, "evaluated_own_plans")
	if !should_score_opponent_responses(turn_planner):
		return own_score

	if should_score_deep_beam(turn_planner):
		return score_deep_beam_turn_plan(game_state, player_id, plan, own_score, board_size, turn_planner, profile)

	var opponent_response_score: float = score_best_opponent_response(game_state, player_id, plan, board_size, turn_planner, profile)
	return own_score - opponent_response_score * opponent_response_weight

func score_best_opponent_response(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int, turn_planner, profile: Dictionary = {}) -> float:
	var response_cache_key: String = "response|%s|p%d|%s" % [get_state_hash(game_state), player_id, get_plan_hash(plan)]
	if response_score_cache.has(response_cache_key):
		increment_profile_count(profile, "response_cache_hits")
		return float(response_score_cache[response_cache_key])

	var simulator_start_usec: int = Time.get_ticks_usec()
	var simulated_state: GameStateData = AIStateSimulator.apply_turn_plan(game_state, player_id, plan, board_size)
	add_profile_time(profile, "simulator_ms", Time.get_ticks_usec() - simulator_start_usec)
	if simulated_state.game_over:
		if simulated_state.winner_player == player_id:
			response_score_cache[response_cache_key] = -SCORE_WIN
			return -SCORE_WIN
		response_score_cache[response_cache_key] = SCORE_WIN
		return SCORE_WIN

	var opponent_player_id: int = 1 - player_id
	var opponent_planner_start_usec: int = Time.get_ticks_usec()
	var opponent_plans: Array[Dictionary] = turn_planner.create_turn_plans_from_state(simulated_state, opponent_player_id, board_size)
	add_profile_time(profile, "opponent_planner_ms", Time.get_ticks_usec() - opponent_planner_start_usec)
	increment_profile_count(profile, "opponent_response_branch_count")
	increment_profile_count(profile, "opponent_response_plan_count", opponent_plans.size())
	if opponent_plans.is_empty():
		response_score_cache[response_cache_key] = 0.0
		return 0.0

	var selected_response_plans: Array[Dictionary] = select_top_opponent_response_plans(
		simulated_state,
		opponent_player_id,
		opponent_plans,
		board_size,
		profile
	)
	increment_profile_count(profile, "opponent_response_selected_plan_count", selected_response_plans.size())
	increment_profile_count(profile, "opponent_response_pruned_plan_count", max(0, opponent_plans.size() - selected_response_plans.size()))
	if selected_response_plans.is_empty():
		response_score_cache[response_cache_key] = 0.0
		return 0.0

	var best_response_score: float = -INF
	var response_eval_start_usec: int = Time.get_ticks_usec()
	var ordered_response_plans: Array[Dictionary] = order_plans_for_full_scoring(simulated_state, opponent_player_id, selected_response_plans, board_size, RESPONSE_FULL_SCORE_LIMIT, profile)
	for opponent_plan: Dictionary in ordered_response_plans:
		var response_score: float = score_turn_plan_cached(simulated_state, opponent_player_id, opponent_plan, board_size)
		if response_score > best_response_score:
			best_response_score = response_score
	add_profile_time(profile, "evaluator_ms", Time.get_ticks_usec() - response_eval_start_usec)
	increment_profile_count(profile, "evaluated_response_plans", ordered_response_plans.size())

	var final_response_score: float = best_response_score if best_response_score != -INF else 0.0
	response_score_cache[response_cache_key] = final_response_score
	return final_response_score

func score_deep_beam_turn_plan(
	game_state: GameStateData,
	player_id: int,
	plan: Dictionary,
	own_score: float,
	board_size: int,
	turn_planner,
	profile: Dictionary = {}
) -> float:
	var simulator_start_usec: int = Time.get_ticks_usec()
	var state_after_first_plan: GameStateData = AIStateSimulator.apply_turn_plan(game_state, player_id, plan, board_size)
	add_profile_time(profile, "simulator_ms", Time.get_ticks_usec() - simulator_start_usec)
	increment_profile_count(profile, "deep_beam_root_count")
	if state_after_first_plan.game_over:
		return own_score + get_terminal_score_for_player(state_after_first_plan, player_id)

	var opponent_player_id: int = 1 - player_id
	var opponent_plans: Array[Dictionary] = get_plans_for_player_with_profile(
		state_after_first_plan,
		opponent_player_id,
		board_size,
		turn_planner,
		profile,
		"opponent_planner_ms",
		"deep_beam_opponent_first_plan_count"
	)
	if opponent_plans.is_empty():
		return own_score

	var opponent_beam: Array[Dictionary] = select_top_plans_for_player(
		state_after_first_plan,
		opponent_player_id,
		opponent_plans,
		board_size,
		DEEP_OPPONENT_FIRST_BEAM_WIDTH,
		profile
	)
	increment_profile_count(profile, "deep_beam_opponent_first_selected_count", opponent_beam.size())
	if opponent_beam.is_empty():
		return own_score

	var worst_branch_value: float = INF
	for opponent_plan: Dictionary in opponent_beam:
		var branch_value: float = score_deep_beam_opponent_branch(
			state_after_first_plan,
			player_id,
			opponent_plan,
			board_size,
			turn_planner,
			profile
		)
		if branch_value < worst_branch_value:
			worst_branch_value = branch_value

	return own_score + (worst_branch_value if worst_branch_value != INF else 0.0)

func score_deep_beam_opponent_branch(
	state_after_first_plan: GameStateData,
	player_id: int,
	opponent_plan: Dictionary,
	board_size: int,
	turn_planner,
	profile: Dictionary
) -> float:
	var opponent_player_id: int = 1 - player_id
	var opponent_score: float = score_turn_plan_cached(state_after_first_plan, opponent_player_id, opponent_plan, board_size)
	increment_profile_count(profile, "evaluated_response_plans")

	var simulator_start_usec: int = Time.get_ticks_usec()
	var state_after_opponent: GameStateData = AIStateSimulator.apply_turn_plan(state_after_first_plan, opponent_player_id, opponent_plan, board_size)
	add_profile_time(profile, "simulator_ms", Time.get_ticks_usec() - simulator_start_usec)
	if state_after_opponent.game_over:
		return get_terminal_score_for_player(state_after_opponent, player_id)

	var own_second_plans: Array[Dictionary] = get_plans_for_player_with_profile(
		state_after_opponent,
		player_id,
		board_size,
		turn_planner,
		profile,
		"own_second_planner_ms",
		"deep_beam_own_second_plan_count"
	)
	if own_second_plans.is_empty():
		return -opponent_score * opponent_response_weight

	var own_second_beam: Array[Dictionary] = select_top_plans_for_player(
		state_after_opponent,
		player_id,
		own_second_plans,
		board_size,
		DEEP_OWN_SECOND_BEAM_WIDTH,
		profile
	)
	increment_profile_count(profile, "deep_beam_own_second_selected_count", own_second_beam.size())
	if own_second_beam.is_empty():
		return -opponent_score * opponent_response_weight

	var best_continuation_value: float = -INF
	for own_second_plan: Dictionary in own_second_beam:
		var continuation_value: float = score_deep_beam_own_second_branch(
			state_after_opponent,
			player_id,
			own_second_plan,
			board_size,
			turn_planner,
			profile
		)
		if continuation_value > best_continuation_value:
			best_continuation_value = continuation_value

	if best_continuation_value == -INF:
		best_continuation_value = 0.0
	return -opponent_score * opponent_response_weight + best_continuation_value * DEEP_SECOND_OWN_WEIGHT

func score_deep_beam_own_second_branch(
	state_after_opponent: GameStateData,
	player_id: int,
	own_second_plan: Dictionary,
	board_size: int,
	turn_planner,
	profile: Dictionary
) -> float:
	var own_second_score: float = score_turn_plan_cached(state_after_opponent, player_id, own_second_plan, board_size)
	increment_profile_count(profile, "deep_beam_evaluated_own_second_plans")

	var simulator_start_usec: int = Time.get_ticks_usec()
	var state_after_own_second: GameStateData = AIStateSimulator.apply_turn_plan(state_after_opponent, player_id, own_second_plan, board_size)
	add_profile_time(profile, "simulator_ms", Time.get_ticks_usec() - simulator_start_usec)
	if state_after_own_second.game_over:
		return get_terminal_score_for_player(state_after_own_second, player_id)

	var opponent_player_id: int = 1 - player_id
	var opponent_second_plans: Array[Dictionary] = get_plans_for_player_with_profile(
		state_after_own_second,
		opponent_player_id,
		board_size,
		turn_planner,
		profile,
		"opponent_second_planner_ms",
		"deep_beam_opponent_second_plan_count"
	)
	if opponent_second_plans.is_empty():
		return own_second_score

	var opponent_second_beam: Array[Dictionary] = select_top_plans_for_player(
		state_after_own_second,
		opponent_player_id,
		opponent_second_plans,
		board_size,
		DEEP_OPPONENT_SECOND_BEAM_WIDTH,
		profile
	)
	increment_profile_count(profile, "deep_beam_opponent_second_selected_count", opponent_second_beam.size())
	var best_opponent_second_score: float = get_best_plan_score_for_player(
		state_after_own_second,
		opponent_player_id,
		opponent_second_beam,
		board_size,
		profile
	)
	return own_second_score - best_opponent_second_score * DEEP_SECOND_OPPONENT_WEIGHT

func get_plans_for_player_with_profile(
	game_state: GameStateData,
	player_id: int,
	board_size: int,
	turn_planner,
	profile: Dictionary,
	time_key: String,
	count_key: String
) -> Array[Dictionary]:
	var planner_start_usec: int = Time.get_ticks_usec()
	var plans: Array[Dictionary] = turn_planner.create_turn_plans_from_state(game_state, player_id, board_size)
	add_profile_time(profile, time_key, Time.get_ticks_usec() - planner_start_usec)
	increment_profile_count(profile, count_key, plans.size())
	return plans

func select_top_plans_for_player(
	game_state: GameStateData,
	player_id: int,
	plans: Array[Dictionary],
	board_size: int,
	limit: int,
	profile: Dictionary
) -> Array[Dictionary]:
	if limit <= 0 or plans.is_empty():
		var empty_plans: Array[Dictionary] = []
		return empty_plans

	var fast_score_start_usec: int = Time.get_ticks_usec()
	var scored_plans: Array[Dictionary] = []
	for plan: Dictionary in plans:
		scored_plans.append({
			"plan": plan,
			"score": score_turn_plan_fast_cached(game_state, player_id, plan, board_size),
		})
	add_profile_time(profile, "evaluator_ms", Time.get_ticks_usec() - fast_score_start_usec)
	return extract_plans(get_top_scored_plans(scored_plans, limit))

func get_best_plan_score_for_player(
	game_state: GameStateData,
	player_id: int,
	plans: Array[Dictionary],
	board_size: int,
	profile: Dictionary
) -> float:
	if plans.is_empty():
		return 0.0

	var best_score: float = -INF
	var eval_start_usec: int = Time.get_ticks_usec()
	var ordered_plans: Array[Dictionary] = order_plans_for_full_scoring(game_state, player_id, plans, board_size, RESPONSE_FULL_SCORE_LIMIT, profile)
	for plan: Dictionary in ordered_plans:
		var score: float = score_turn_plan_cached(game_state, player_id, plan, board_size)
		if score > best_score:
			best_score = score
	add_profile_time(profile, "evaluator_ms", Time.get_ticks_usec() - eval_start_usec)
	increment_profile_count(profile, "deep_beam_evaluated_opponent_second_plans", ordered_plans.size())
	return best_score if best_score != -INF else 0.0

func get_terminal_score_for_player(game_state: GameStateData, player_id: int) -> float:
	if game_state == null or !game_state.game_over:
		return 0.0
	if game_state.winner_player == player_id:
		return SCORE_WIN
	return -SCORE_WIN

func select_top_opponent_response_plans(
	game_state: GameStateData,
	player_id: int,
	opponent_plans: Array[Dictionary],
	board_size: int,
	profile: Dictionary
) -> Array[Dictionary]:
	if opponent_top_n <= 0:
		var empty_plans: Array[Dictionary] = []
		return empty_plans
	return select_top_plans_for_player(game_state, player_id, opponent_plans, board_size, opponent_top_n, profile)

func extract_plans(scored_plans: Array[Dictionary]) -> Array[Dictionary]:
	var plans: Array[Dictionary] = []
	for scored_plan: Dictionary in scored_plans:
		var plan: Dictionary = scored_plan.get("plan", {})
		if !plan.is_empty():
			plans.append(plan)
	return plans

func get_top_scored_plans(scored_plans: Array[Dictionary], limit: int) -> Array[Dictionary]:
	var sorted_plans: Array[Dictionary] = scored_plans.duplicate()
	sorted_plans.sort_custom(Callable(self, "sort_scored_plan_desc"))

	var output: Array[Dictionary] = []
	var output_count: int = mini(maxi(0, limit), sorted_plans.size())
	for index: int in range(output_count):
		output.append(sorted_plans[index])
	return output

func sort_scored_plan_desc(left: Dictionary, right: Dictionary) -> bool:
	return float(left.get("score", 0.0)) > float(right.get("score", 0.0))

func reset_decision_caches() -> void:
	fast_score_cache.clear()
	full_score_cache.clear()
	move_score_cache.clear()
	response_score_cache.clear()
	stamp_cache.clear()
	seeker_route_cache.clear()

func order_plans_for_full_scoring(
	game_state: GameStateData,
	player_id: int,
	plans: Array[Dictionary],
	board_size: int,
	limit: int,
	profile: Dictionary = {}
) -> Array[Dictionary]:
	if plans.is_empty():
		var empty_plans: Array[Dictionary] = []
		return empty_plans

	var fast_scored_plans: Array[Dictionary] = []
	for plan: Dictionary in plans:
		fast_scored_plans.append({
			"plan": plan,
			"score": score_turn_plan_fast_cached(game_state, player_id, plan, board_size),
		})

	var selected_count: int = mini(maxi(1, limit), plans.size())
	increment_profile_count(profile, "fast_ordered_plan_count", plans.size())
	return extract_plans(get_top_scored_plans(fast_scored_plans, selected_count))

func score_turn_plan_fast_cached(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int = BoardConfig.BOARD_SIZE) -> float:
	var cache_key: String = "fast|%s|p%d|%s" % [get_state_hash(game_state), player_id, get_plan_hash(plan)]
	if fast_score_cache.has(cache_key):
		return float(fast_score_cache[cache_key])

	var score: float = score_turn_plan_fast(game_state, player_id, plan, board_size)
	fast_score_cache[cache_key] = score
	return score

func score_turn_plan_cached(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int = BoardConfig.BOARD_SIZE) -> float:
	var cache_key: String = "full|%s|p%d|%s" % [get_state_hash(game_state), player_id, get_plan_hash(plan)]
	if full_score_cache.has(cache_key):
		return float(full_score_cache[cache_key])

	var score: float = score_turn_plan(game_state, player_id, plan, board_size)
	full_score_cache[cache_key] = score
	return score

func score_move_cached(game_state: GameStateData, player_id: int, move: Dictionary, board_size: int = BoardConfig.BOARD_SIZE) -> float:
	var cache_key: String = "move|%s|p%d|%s" % [get_state_hash(game_state), player_id, get_move_hash(move)]
	if move_score_cache.has(cache_key):
		return float(move_score_cache[cache_key])

	var score: float = score_move(game_state, player_id, move, board_size)
	move_score_cache[cache_key] = score
	return score

func get_cached_stamp(stamp_name: String) -> Stamp:
	var normalized_name: String = stamp_name.strip_edges()
	if normalized_name.is_empty():
		return null
	if stamp_cache.has(normalized_name):
		return stamp_cache[normalized_name] as Stamp

	var stamp: Stamp = StampLibrary.get_stamp(normalized_name)
	stamp_cache[normalized_name] = stamp
	return stamp

func get_state_hash(game_state: GameStateData) -> String:
	if game_state == null:
		return "null"

	var piece_parts: Array = []
	var piece_positions: Array = game_state.pieces.keys()
	piece_positions.sort_custom(Callable(self, "sort_vector2_values"))
	for position_value in piece_positions:
		var pos: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null:
			continue
		var stamp_name: String = piece.attached_stamp.stamp_name if piece.attached_stamp != null else ""
		piece_parts.append("%d:%d:%d:%s:%d:%s:%d" % [
			int(pos.x),
			int(pos.y),
			piece.color,
			stamp_name,
			piece.turns_remaining,
			"e" if piece.exhausted_this_turn else "r",
			piece.respawn_cooldown_turns,
		])

	var effect_parts: Array = []
	for effect_value in game_state.board_effects:
		var effect: Dictionary = effect_value
		effect_parts.append("%s:%d:%d:%d:%s" % [
			str(effect.get("effect_type", "")),
			int(effect.get("owner_player_id", -1)),
			int(effect.get("target_player_id", -1)),
			int(effect.get("turns_remaining", -1)),
			str(effect.get("squares", [])),
		])

	return "t%d|w%d,%d|b%d,%d|p%s|h%s|d%s|fx%s" % [
		game_state.current_turn_player,
		int(game_state.white_seeker_position.x),
		int(game_state.white_seeker_position.y),
		int(game_state.black_seeker_position.x),
		int(game_state.black_seeker_position.y),
		";".join(piece_parts),
		get_stamp_list_dictionary_hash(game_state.player_hands),
		get_stamp_list_dictionary_hash(game_state.player_decks),
		";".join(effect_parts),
	]

func get_stamp_list_dictionary_hash(stamp_lists: Dictionary) -> String:
	var parts: Array = []
	var keys: Array = stamp_lists.keys()
	keys.sort()
	for key in keys:
		var stamp_names: Array = stamp_lists[key]
		var stamp_name_parts: Array = []
		for stamp_name_value in stamp_names:
			stamp_name_parts.append(str(stamp_name_value))
		parts.append("%s:%s" % [str(key), "|".join(stamp_name_parts)])
	return ";".join(parts)

func get_plan_hash(plan: Dictionary) -> String:
	var action_parts: Array[String] = []
	var actions: Array = plan.get("actions", [])
	for action_value in actions:
		action_parts.append(get_action_hash(action_value))
	return "%s{%s}" % [str(plan.get("plan_type", "")), ";".join(action_parts)]

func get_action_hash(action_value) -> String:
	if !(action_value is Dictionary):
		return str(action_value)
	var action: Dictionary = action_value
	return "%s:%s:%s:%s:%s" % [
		str(action.get("type", "")),
		str(action.get("stamp_name", "")),
		vector_hash(action.get("piece_pos", "")),
		vector_hash(action.get("from", "")),
		vector_hash(action.get("to", "")),
	]

func get_move_hash(move: Dictionary) -> String:
	return "%s>%s:%s:%s" % [
		vector_hash(AIStateSimulator.get_move_from(move)),
		vector_hash(AIStateSimulator.get_move_to(move)),
		get_move_hash_stamp_name(move),
		str(move.get("requires_attach", false)),
	]

func get_move_hash_stamp_name(move: Dictionary) -> String:
	var stamp_name: String = str(move.get("stamp_name", ""))
	if !stamp_name.is_empty():
		return stamp_name
	var stamp: Stamp = move.get("stamp", null) as Stamp
	return stamp.stamp_name if stamp != null else ""

func vector_hash(value) -> String:
	if value is Vector2:
		var vector_value: Vector2 = value
		return "%d,%d" % [int(vector_value.x), int(vector_value.y)]
	return str(value)

func sort_vector2_values(left, right) -> bool:
	var left_vector: Vector2 = StampEffectResolver.as_vector2(left, Vector2(-1, -1))
	var right_vector: Vector2 = StampEffectResolver.as_vector2(right, Vector2(-1, -1))
	if int(left_vector.x) == int(right_vector.x):
		return int(left_vector.y) < int(right_vector.y)
	return int(left_vector.x) < int(right_vector.x)

func create_profile(own_turn_plan_count: int) -> Dictionary:
	return {
		"own_turn_plan_count": own_turn_plan_count,
		"own_response_candidate_count": 0,
		"own_response_pruned_plan_count": 0,
		"evaluated_own_plans": 0,
		"opponent_response_branch_count": 0,
		"opponent_response_plan_count": 0,
		"opponent_response_selected_plan_count": 0,
		"opponent_response_pruned_plan_count": 0,
		"evaluated_response_plans": 0,
		"choose_best_turn_plan_ms": 0.0,
		"opponent_planner_ms": 0.0,
		"evaluator_ms": 0.0,
		"simulator_ms": 0.0,
		"best_plan_score": 0.0,
		"best_plan_type": "",
		"difficulty_level": difficulty_level,
		"search_depth": search_depth,
		"own_top_n": own_top_n,
		"opponent_top_n": opponent_top_n,
		"randomness": randomness,
		"opponent_response_weight": opponent_response_weight,
	}

func add_profile_time(profile: Dictionary, key: String, elapsed_usec: int) -> void:
	if profile.is_empty():
		return
	profile[key] = float(profile.get(key, 0.0)) + usec_to_ms(elapsed_usec)

func increment_profile_count(profile: Dictionary, key: String, amount: int = 1) -> void:
	if profile.is_empty():
		return
	profile[key] = int(profile.get(key, 0)) + amount

func usec_to_ms(elapsed_usec: int) -> float:
	return float(elapsed_usec) / 1000.0

func score_turn_plan_fast(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int = BoardConfig.BOARD_SIZE) -> float:
	var score: float = 0.0

	var setup_attach_actions: Array = plan.get("setup_attach_actions", [])
	for attach_action_value in setup_attach_actions:
		var attach_action: Dictionary = attach_action_value
		score += score_attach_setup_fast(game_state, player_id, attach_action, board_size)

	var move: Dictionary = plan.get("move", {})
	if !move.is_empty():
		score += score_move_fast(game_state, player_id, move, board_size)

	var actions: Array = plan.get("actions", [])
	score -= float(maxi(0, actions.size() - 1)) * 0.4
	return score

func score_attach_setup_fast(game_state: GameStateData, player_id: int, attach_action: Dictionary, board_size: int) -> float:
	var piece_pos: Vector2 = StampEffectResolver.as_vector2(attach_action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
	var piece: Piece = game_state.get_piece(piece_pos)
	if piece == null:
		return 0.0

	var stamp: Stamp = attach_action.get("stamp", null) as Stamp
	if stamp == null:
		stamp = get_cached_stamp(str(attach_action.get("stamp_name", "")))
	if stamp == null:
		return 0.0

	var move: Dictionary = {
		"from": piece_pos,
		"to": piece_pos,
		"stamp": stamp,
		"requires_attach": true,
	}
	var is_seeker_stamp: bool = MoveRules.is_seeker_stamp(stamp)
	var seeker_ready: bool = !is_seeker_stamp or is_seeker_attach_in_timing_window(game_state, player_id, stamp, piece_pos, board_size)
	var score: float = SCORE_ATTACH_STAMP + max(0, stamp.duration) * 2.0
	if is_seeker_stamp:
		if seeker_ready:
			score += SCORE_ATTACH_SEEKER * 0.85
		else:
			score -= PENALTY_EARLY_SEEKER_COMMITMENT
	score += float(stamp.get_directions().size()) * 2.5
	score += get_stamp_balance_value(stamp) * STAMP_VALUE_ATTACH_PLAY_WEIGHT
	if is_seeker_stamp:
		score += score_seeker_attach_timing(game_state, player_id, stamp, piece_pos, piece_pos, board_size) * 0.75
		var seeker_effect_weight: float = 0.45 if seeker_ready else 0.05
		score += score_stamp_effect_fast(game_state, player_id, piece, stamp, piece_pos, piece_pos, null, move, board_size) * seeker_effect_weight
	else:
		score += score_seeker_base_entry_threat(game_state, player_id, piece_pos, stamp, board_size)
		score += score_stamp_effect_fast(game_state, player_id, piece, stamp, piece_pos, piece_pos, null, move, board_size) * 0.65
	score -= score_attachment_danger(game_state, player_id, attach_action, board_size, false)
	return score

func score_move_fast(game_state: GameStateData, player_id: int, move: Dictionary, board_size: int = BoardConfig.BOARD_SIZE) -> float:
	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var moving_piece: Piece = game_state.get_piece(from_pos)
	if moving_piece == null:
		return -SCORE_WIN

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var opponent_player_id: int = 1 - player_id
	var stamp: Stamp = AIStateSimulator.get_stamp_for_candidate(game_state.pieces, move)
	var captured_piece: Piece = AIStateSimulator.get_captured_piece(game_state.pieces, move)
	var score: float = 0.0
	if bool(move.get("requires_attach", false)):
		if stamp != null:
			score += SCORE_ATTACH_STAMP + max(0, stamp.duration) * 2.0
			if MoveRules.is_seeker_stamp(stamp):
				if is_seeker_attach_in_timing_window(game_state, player_id, stamp, from_pos, board_size):
					score += SCORE_ATTACH_SEEKER * 0.85
				else:
					score -= PENALTY_EARLY_SEEKER_COMMITMENT
			score += get_stamp_balance_value(stamp) * STAMP_VALUE_ATTACH_PLAY_WEIGHT
	else:
		score += SCORE_USE_EXISTING_STAMP

	if captured_piece != null:
		score += score_capture(captured_piece) * 0.9
		score += score_base_staging_capture(game_state, player_id, captured_piece, to_pos, board_size) * 0.9
		score += score_seeker_capture_discipline(game_state, player_id, move, captured_piece, board_size) * 0.9
		if has_active_seeker_near_finish(game_state, player_id, board_size) and !AIStateSimulator.is_own_seeker_candidate(game_state.pieces, move, player_id):
			score -= PENALTY_ENDGAME_NON_CLOSING_CAPTURE * 0.9

	if AIStateSimulator.is_own_seeker_candidate(game_state.pieces, move, player_id):
		score += score_seeker_base_progress(game_state, player_id, from_pos, to_pos)
		var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, opponent_player_id)
		if moving_piece.color == player_color && to_pos == opponent_base:
			score += SCORE_WIN
	else:
		score += score_non_seeker_base_entry_penalty(game_state, player_id, move)

	score += score_center_control(to_pos, board_size) * 0.7
	score += score_repeat_last_move_penalty(game_state, player_id, move)
	score += score_stamp_effect_fast(game_state, player_id, moving_piece, stamp, from_pos, to_pos, captured_piece, move, board_size)
	return score

func score_stamp_effect_fast(
	game_state: GameStateData,
	player_id: int,
	moving_piece: Piece,
	stamp: Stamp,
	from_pos: Vector2,
	to_pos: Vector2,
	captured_piece: Piece,
	move: Dictionary,
	board_size: int
) -> float:
	if stamp == null or !stamp.has_effect():
		return 0.0

	var effect_source_pos: Vector2 = get_effect_source_pos(stamp, from_pos, to_pos)
	var score: float = 0.0
	match stamp.effect_type:
		StampEffect.TYPE_SHARED_CONTROL:
			score += score_shared_control_effect_fast(stamp)
		StampEffect.TYPE_INVISIBLE_TO_ENEMY:
			score += 32.0
			if MoveRules.is_seeker_stamp(stamp):
				score += 80.0
		StampEffect.TYPE_STEAL_STAMP:
			score += 50.0
		StampEffect.TYPE_GRANT_STAMP:
			score += score_grant_stamp_effect(game_state, player_id, stamp)
		StampEffect.TYPE_GIVE_STAMP:
			score -= PENALTY_GIVE_STAMP
		StampEffect.TYPE_MOVE_BASE:
			score += score_move_base_effect(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
		StampEffect.TYPE_INVALID_SQUARES:
			score += score_invalid_squares_effect_fast(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
		StampEffect.TYPE_FROZEN_SQUARES:
			score += score_frozen_squares_effect_fast(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
		StampEffect.TYPE_BOMB:
			score += score_bomb_effect(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
		StampEffect.TYPE_UNCAPTURABLE:
			score += score_uncapturable_effect(stamp)
		StampEffect.TYPE_INCREASE_OWN_DURATIONS:
			score += score_duration_adjustment_effect(game_state, player_id, player_id, 1)
		StampEffect.TYPE_INCREASE_ENEMY_DURATIONS:
			score += score_duration_adjustment_effect(game_state, player_id, 1 - player_id, 1)
		StampEffect.TYPE_DECREASE_OWN_DURATIONS:
			score += score_duration_adjustment_effect(game_state, player_id, player_id, -1)
		StampEffect.TYPE_DECREASE_ENEMY_DURATIONS:
			score += score_duration_adjustment_effect(game_state, player_id, 1 - player_id, -1)
		StampEffect.TYPE_INCREASE_SELF_DURATION:
			score += 18.0
		_:
			pass

	if stamp.effect_trigger == StampEffect.TRIGGER_ON_CAPTURE && captured_piece != null:
		score += 20.0
	if stamp.effect_trigger == StampEffect.TRIGGER_ON_MOVE:
		score += 8.0
	if stamp.effect_trigger == StampEffect.TRIGGER_ON_EXPIRE:
		score += 5.0
	if to_pos == from_pos:
		score -= 10.0
	return score

func score_invalid_squares_effect_fast(game_state: GameStateData, player_id: int, moving_piece: Piece, stamp: Stamp, source_pos: Vector2, board_size: int) -> float:
	if moving_piece == null:
		return 0.0

	var effect_color: int = moving_piece.color
	var target_squares: Array[Vector2] = StampEffectResolver.get_effect_squares(stamp, source_pos, board_size, effect_color)
	target_squares = StampEffectResolver.filter_out_base_fields(game_state, target_squares)
	if target_squares.is_empty():
		return 0.0

	var opponent_positions: Array[Vector2] = get_piece_positions_for_player(game_state.pieces, 1 - player_id)
	var own_positions: Array[Vector2] = get_piece_positions_for_player(game_state.pieces, player_id)
	var score: float = float(target_squares.size()) * 2.0
	for target_square: Vector2 in target_squares:
		for opponent_pos: Vector2 in opponent_positions:
			var opponent_distance: float = get_manhattan_distance(target_square, opponent_pos)
			if opponent_distance <= 1.0:
				score += 10.0
			elif opponent_distance <= 2.0:
				score += 4.0
		for own_pos: Vector2 in own_positions:
			var own_distance: float = get_manhattan_distance(target_square, own_pos)
			if own_distance <= 1.0:
				score -= 6.0
	return score

func score_frozen_squares_effect_fast(game_state: GameStateData, player_id: int, moving_piece: Piece, stamp: Stamp, source_pos: Vector2, board_size: int) -> float:
	if moving_piece == null:
		return 0.0

	var effect_color: int = moving_piece.color
	var target_squares: Array[Vector2] = StampEffectResolver.get_effect_squares(stamp, source_pos, board_size, effect_color)
	var score: float = 0.0
	for target_pos: Vector2 in target_squares:
		var target_piece: Piece = game_state.get_piece(target_pos)
		if target_piece == null:
			continue

		var target_player_id: int = StampEffectResolver.get_player_id_for_color(target_piece.color)
		if !stamp_effect_targets_player(stamp, target_player_id):
			continue

		var piece_score: float = get_piece_target_score(target_piece) * 0.75 + SCORE_FROZEN_ENEMY_PIECE
		if target_player_id == player_id:
			score -= piece_score
		else:
			score += piece_score
	return score

func score_shared_control_effect_fast(stamp: Stamp) -> float:
	var movement_count: int = 0
	if stamp != null:
		movement_count = stamp.get_directions().size()
	return float(movement_count) * (SCORE_SHARED_OWN_MOBILITY - PENALTY_SHARED_OPPONENT_MOBILITY)

func score_grant_stamp_effect(game_state: GameStateData, player_id: int, stamp: Stamp) -> float:
	if game_state == null or stamp == null:
		return 0.0

	var target_player_id: int = int(stamp.effect_settings.get("target_player_id", player_id))
	var granted_stamp_name: String = str(stamp.effect_settings.get("stamp_name", stamp.stamp_name))
	if granted_stamp_name.is_empty():
		return 0.0

	var deck: Array = game_state.player_decks.get(target_player_id, [])
	var available_count: int = 0
	for deck_stamp_name_value in deck:
		if str(deck_stamp_name_value) == granted_stamp_name:
			available_count += 1

	var amount: int = max(1, int(stamp.effect_settings.get("amount", 1)))
	return 45.0 * min(amount, available_count)

func score_hand_deck_economy_for_plan(game_state: GameStateData, player_id: int, plan: Dictionary) -> float:
	if game_state == null:
		return 0.0

	var score: float = 0.0
	var actions: Array = plan.get("actions", [])
	for action_value in actions:
		if !(action_value is Dictionary):
			continue
		var action: Dictionary = action_value
		match str(action.get("type", "")):
			"attach_stamp":
				var attached_stamp: Stamp = get_cached_stamp(str(action.get("stamp_name", "")))
				if attached_stamp != null:
					score -= get_stamp_balance_value(attached_stamp) * 0.20
					score += max(0, attached_stamp.duration) * 0.75
					score += score_stamp_synergy_for_attach(game_state, player_id, action, attached_stamp)
			"exchange_stamp":
				var exchanged_stamp: Stamp = get_cached_stamp(str(action.get("stamp_name", "")))
				if exchanged_stamp != null:
					score -= get_stamp_balance_value(exchanged_stamp) * 0.35
					if MoveRules.is_seeker_stamp(exchanged_stamp):
						score -= get_seeker_exchange_penalty(game_state, player_id)
					score += score_deck_draw_quality(game_state, player_id, str(action.get("stamp_name", ""))) * 0.35

	score += score_remaining_hand_quality(game_state, player_id, actions) * HAND_DECK_ECONOMY_WEIGHT
	score += score_remaining_deck_quality(game_state, player_id) * HAND_DECK_ECONOMY_WEIGHT * 0.35
	score += score_hand_synergy(game_state, player_id) * HAND_DECK_ECONOMY_WEIGHT
	if has_non_seeker_attach_action(actions):
		score += SCORE_ATTACH_STAMP * 1.5
	return score

func get_seeker_exchange_penalty(game_state: GameStateData, player_id: int) -> float:
	if game_state == null:
		return PENALTY_EXCHANGE_LAST_SEEKER

	var active_seeker_count: int = get_active_seeker_pieces_for_player(game_state, player_id).size()
	if active_seeker_count <= 0:
		return PENALTY_EXCHANGE_LAST_SEEKER
	return PENALTY_EXCHANGE_LAST_SEEKER * 0.35

func has_non_seeker_attach_action(actions: Array) -> bool:
	for action_value in actions:
		if !(action_value is Dictionary):
			continue
		var action: Dictionary = action_value
		if str(action.get("type", "")) != "attach_stamp":
			continue
		var stamp: Stamp = get_cached_stamp(str(action.get("stamp_name", "")))
		if stamp != null and !MoveRules.is_seeker_stamp(stamp):
			return true
	return false

func score_stamp_synergy_for_attach(game_state: GameStateData, player_id: int, action: Dictionary, stamp: Stamp) -> float:
	if game_state == null or stamp == null:
		return 0.0

	var piece_pos: Vector2 = StampEffectResolver.as_vector2(action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var distance_to_base: float = get_manhattan_distance(piece_pos, opponent_base)
	var movement_count: int = stamp.get_directions().size()
	var score: float = 0.0
	if MoveRules.is_seeker_stamp(stamp):
		var route_distance: int = get_seeker_route_distance(game_state, player_id, stamp, piece_pos, BoardConfig.BOARD_SIZE)
		var allowed_steps: int = max(1, stamp.duration)
		if is_seeker_attach_in_timing_window(game_state, player_id, stamp, piece_pos, BoardConfig.BOARD_SIZE):
			score += SCORE_SEEKER_ATTACH_IN_ROUTE + float(allowed_steps - route_distance) * 24.0
			score += maxf(0.0, float(BoardConfig.BOARD_SIZE) - distance_to_base) * 4.0
			if stamp.effect_type == StampEffect.TYPE_INVISIBLE_TO_ENEMY or stamp.effect_type == StampEffect.TYPE_UNCAPTURABLE:
				score += SCORE_HAND_SYNERGY * 1.5
		else:
			score -= get_early_seeker_attach_penalty(game_state, player_id, stamp, piece_pos)
	if stamp.effect_type == StampEffect.TYPE_SHARED_CONTROL:
		score += float(movement_count) * 2.0
	if stamp.effect_type == StampEffect.TYPE_FROZEN_SQUARES or stamp.effect_type == StampEffect.TYPE_INVALID_SQUARES:
		score += maxf(0.0, float(BoardConfig.BOARD_SIZE) - distance_to_base) * 1.5
	if stamp.effect_type == StampEffect.TYPE_INCREASE_SELF_DURATION and movement_count >= 4:
		score += SCORE_HAND_SYNERGY
	if stamp.effect_type == StampEffect.TYPE_MOVE_BASE:
		score += SCORE_HAND_SYNERGY * 0.75
	return score

func get_early_seeker_attach_penalty(game_state: GameStateData, player_id: int, stamp: Stamp, piece_pos: Vector2) -> float:
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var distance_to_base: float = get_manhattan_distance(piece_pos, opponent_base)
	var penalty: float = PENALTY_SEEKER_ATTACH_OUT_OF_ROUTE + PENALTY_EARLY_SEEKER_COMMITMENT
	if distance_to_base <= float(max(2, stamp.duration + 1)):
		penalty *= 0.78
	if is_endgame_seeker_finish_mode():
		penalty *= 0.5
	if stamp.effect_type == StampEffect.TYPE_INVISIBLE_TO_ENEMY or stamp.effect_type == StampEffect.TYPE_UNCAPTURABLE:
		penalty *= 0.9
	return penalty

func score_seeker_route_strategy_for_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	if game_state == null or plan.is_empty():
		return 0.0

	var simulated_state: GameStateData = AIStateSimulator.apply_turn_plan(game_state, player_id, plan, board_size)
	if simulated_state.game_over:
		return 0.0

	var move: Dictionary = plan.get("move", {})
	var score: float = 0.0
	if should_push_active_board_seeker(game_state, player_id):
		if !move.is_empty():
			score += score_active_seeker_push_plan(game_state, simulated_state, player_id, move, board_size)
		return score

	if !move.is_empty():
		score += score_move_toward_seeker_routes(game_state, simulated_state, player_id, move, board_size)
		score += score_force_seeker_closing_plan(game_state, simulated_state, player_id, plan, board_size)

	var setup_attach_actions: Array = plan.get("setup_attach_actions", [])
	for action_value in setup_attach_actions:
		if !(action_value is Dictionary):
			continue
		var action: Dictionary = action_value
		if str(action.get("type", "")) != "attach_stamp":
			continue
		var stamp: Stamp = get_cached_stamp(str(action.get("stamp_name", "")))
		if stamp != null and MoveRules.is_seeker_stamp(stamp):
			var piece_pos: Vector2 = StampEffectResolver.as_vector2(action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
			var distance: int = get_seeker_route_distance(game_state, player_id, stamp, piece_pos, board_size)
			if is_seeker_attach_in_timing_window(game_state, player_id, stamp, piece_pos, board_size):
				score += SCORE_SEEKER_ATTACH_IN_ROUTE
			else:
				score -= get_early_seeker_attach_penalty(game_state, player_id, stamp, piece_pos)

	return score

func score_force_seeker_closing_plan(
	before_state: GameStateData,
	after_state: GameStateData,
	player_id: int,
	plan: Dictionary,
	board_size: int
) -> float:
	if before_state == null or after_state == null or should_push_active_board_seeker(before_state, player_id):
		return 0.0
	if get_available_seeker_stamps_for_player(before_state, player_id).is_empty():
		return 0.0

	var move: Dictionary = plan.get("move", {})
	if move.is_empty():
		return 0.0

	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var before_distance: int = get_best_available_seeker_route_distance(before_state, player_id, from_pos, board_size)
	var after_distance: int = get_best_available_seeker_route_distance(after_state, player_id, to_pos, board_size)
	if after_distance < 0:
		return -PENALTY_LEAVE_SEEKER_STAGING_SQUARE

	var score: float = 0.0
	var ready_before: bool = is_any_available_seeker_ready_on_piece(before_state, player_id, from_pos, board_size)
	var ready_after: bool = is_any_available_seeker_ready_on_piece(after_state, player_id, to_pos, board_size)
	if ready_before and !ready_after:
		score -= PENALTY_LEAVE_SEEKER_STAGING_SQUARE
	if ready_after:
		score += SCORE_HOLD_SEEKER_STAGING_SQUARE
	if before_distance >= 0:
		var delta: int = before_distance - after_distance
		score += float(delta) * SCORE_FORCED_CLOSING_ROUTE_PROGRESS
		if delta < 0:
			score += float(delta) * SCORE_FORCED_CLOSING_ROUTE_PROGRESS
	else:
		score += SCORE_FORCED_CLOSING_ROUTE_PROGRESS * 0.35

	var captured_piece: Piece = AIStateSimulator.get_captured_piece(before_state.pieces, move)
	if captured_piece != null and !ready_after:
		score -= PENALTY_ENDGAME_NON_CLOSING_CAPTURE
	if !ready_after:
		score += score_seeker_staging_stamp_block(after_state, player_id, to_pos, board_size)
	return score

func should_push_active_board_seeker(game_state: GameStateData, player_id: int) -> bool:
	return !get_active_seeker_pieces_for_player(game_state, player_id).is_empty()

func get_active_seeker_pieces_for_player(game_state: GameStateData, player_id: int) -> Array[Dictionary]:
	var active_seeker_pieces: Array[Dictionary] = []
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	for position_value in game_state.pieces:
		var pos: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != player_color:
			continue
		if !MoveRules.is_seeker_stamp(piece.attached_stamp):
			continue
		active_seeker_pieces.append({
			"position": pos,
			"piece": piece,
			"stamp": piece.attached_stamp,
		})
	return active_seeker_pieces

func score_active_seeker_push_plan(
	before_state: GameStateData,
	after_state: GameStateData,
	player_id: int,
	move: Dictionary,
	board_size: int
) -> float:
	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var moving_piece: Piece = before_state.get_piece(from_pos)
	var score: float = 0.0
	if moving_piece != null and MoveRules.is_seeker_stamp(moving_piece.attached_stamp):
		score += score_active_seeker_direct_progress(before_state, after_state, player_id, moving_piece.attached_stamp, from_pos, to_pos, board_size)
	else:
		var clearing_score: float = score_route_clearing_move(before_state, player_id, move, board_size)
		score += clearing_score
		if clearing_score <= 0.0:
			score -= PENALTY_IGNORE_ACTIVE_SEEKER_PUSH
	return score

func score_active_seeker_direct_progress(
	before_state: GameStateData,
	after_state: GameStateData,
	player_id: int,
	seeker_stamp: Stamp,
	from_pos: Vector2,
	to_pos: Vector2,
	board_size: int
) -> float:
	var before_distance: int = get_seeker_route_distance(before_state, player_id, seeker_stamp, from_pos, board_size)
	var after_distance: int = get_seeker_route_distance(after_state, player_id, seeker_stamp, to_pos, board_size)
	if after_distance < 0:
		return -SCORE_ACTIVE_SEEKER_PUSH

	var score: float = 0.0
	if before_distance >= 0:
		var distance_delta: int = before_distance - after_distance
		score += float(distance_delta) * SCORE_ACTIVE_SEEKER_PUSH
		if distance_delta < 0:
			score -= float(abs(distance_delta)) * PENALTY_ACTIVE_SEEKER_RETREAT
		elif distance_delta == 0 and after_distance > 0:
			score -= PENALTY_ACTIVE_SEEKER_STALL + float(after_distance) * 55.0
	else:
		score += SCORE_ACTIVE_SEEKER_PUSH * 0.5
	if after_distance == 0:
		score += SCORE_WIN + SCORE_ACTIVE_SEEKER_FINISH
	elif after_distance <= 2:
		score += SCORE_ACTIVE_SEEKER_FINISH * 0.45
	score -= score_square_danger_for_player(after_state, player_id, to_pos, board_size) * PENALTY_ACTIVE_SEEKER_DANGER
	return score

func has_active_seeker_near_finish(game_state: GameStateData, player_id: int, board_size: int, max_distance: int = 2) -> bool:
	var best_distance: int = get_best_active_seeker_route_distance(game_state, player_id, board_size)
	return best_distance >= 0 and best_distance <= max_distance

func score_route_clearing_move(before_state: GameStateData, player_id: int, move: Dictionary, board_size: int) -> float:
	var captured_piece: Piece = AIStateSimulator.get_captured_piece(before_state.pieces, move)
	if captured_piece == null:
		return 0.0

	var captured_player_id: int = StampEffectResolver.get_player_id_for_color(captured_piece.color)
	if captured_player_id == player_id:
		return 0.0

	var capture_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var best_route_distance: int = get_best_active_seeker_route_distance_to_square(before_state, player_id, capture_pos, board_size)
	if best_route_distance < 0:
		return 0.0

	var score: float = SCORE_ACTIVE_SEEKER_CLEAR_ROUTE
	score += maxf(0.0, float(MAX_SEEKER_ROUTE_DISTANCE - best_route_distance)) * 12.0
	score += get_piece_target_score(captured_piece) * 0.8
	return score

func get_best_active_seeker_route_distance_to_square(game_state: GameStateData, player_id: int, square: Vector2, board_size: int) -> int:
	var best_distance: int = 999
	for entry: Dictionary in get_active_seeker_pieces_for_player(game_state, player_id):
		var stamp: Stamp = entry.get("stamp", null) as Stamp
		if stamp == null:
			continue
		var distance: int = get_seeker_route_distance(game_state, player_id, stamp, square, board_size)
		if distance >= 0:
			best_distance = mini(best_distance, distance)
	return best_distance if best_distance != 999 else -1

func get_best_available_seeker_route_distance(game_state: GameStateData, player_id: int, square: Vector2, board_size: int) -> int:
	var best_distance: int = 999
	for stamp in get_available_seeker_stamps_for_player(game_state, player_id):
		if stamp == null:
			continue
		var distance: int = get_seeker_route_distance(game_state, player_id, stamp, square, board_size)
		if distance >= 0:
			best_distance = mini(best_distance, distance)
	return best_distance if best_distance != 999 else -1

func is_any_available_seeker_ready_from_square(game_state: GameStateData, player_id: int, square: Vector2, board_size: int) -> bool:
	for stamp in get_available_seeker_stamps_for_player(game_state, player_id):
		if stamp != null and is_seeker_attach_in_timing_window(game_state, player_id, stamp, square, board_size):
			return true
	return false

func is_any_available_seeker_ready_on_piece(game_state: GameStateData, player_id: int, square: Vector2, board_size: int) -> bool:
	if !can_piece_receive_seeker_at(game_state, player_id, square):
		return false
	return is_any_available_seeker_ready_from_square(game_state, player_id, square, board_size)

func can_piece_receive_seeker_at(game_state: GameStateData, player_id: int, square: Vector2) -> bool:
	if game_state == null:
		return false
	var piece: Piece = game_state.get_piece(square)
	if piece == null:
		return false
	if StampEffectResolver.get_player_id_for_color(piece.color) != player_id:
		return false
	return piece.can_receive_stamp()

func score_seeker_staging_stamp_block(game_state: GameStateData, player_id: int, square: Vector2, board_size: int) -> float:
	if game_state == null:
		return 0.0
	if !is_any_available_seeker_ready_from_square(game_state, player_id, square, board_size):
		return 0.0
	if can_piece_receive_seeker_at(game_state, player_id, square):
		return 0.0
	var piece: Piece = game_state.get_piece(square)
	if piece == null or piece.attached_stamp == null:
		return 0.0
	return -minf(PENALTY_LEAVE_SEEKER_STAGING_SQUARE * 0.55, 180.0 + float(maxi(0, piece.turns_remaining)) * 70.0)

func score_square_danger_for_player(game_state: GameStateData, player_id: int, square: Vector2, board_size: int) -> float:
	var opponent_player_id: int = 1 - player_id
	var opponent_color: int = StampEffectResolver.get_color_for_player_id(opponent_player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_stamp_moves(
		game_state.pieces,
		opponent_color,
		board_size,
		game_state.board_effects
	)
	var danger: float = 0.0
	for move: Dictionary in valid_moves:
		if AIStateSimulator.get_move_to(move) == square:
			var moving_piece: Piece = game_state.get_piece(AIStateSimulator.get_move_from(move))
			danger += get_piece_target_score(moving_piece) if moving_piece != null else 1.0
	return danger

func score_move_toward_seeker_routes(
	before_state: GameStateData,
	after_state: GameStateData,
	player_id: int,
	move: Dictionary,
	board_size: int
) -> float:
	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var moving_piece: Piece = before_state.get_piece(from_pos)
	if moving_piece == null:
		return 0.0

	var seeker_stamps: Array = get_available_seeker_stamps_for_player(before_state, player_id)
	if seeker_stamps.is_empty():
		return 0.0

	var best_before: int = 999
	var best_after: int = 999
	var best_duration: int = 1
	for stamp in seeker_stamps:
		if stamp == null:
			continue
		var before_distance: int = get_seeker_route_distance(before_state, player_id, stamp, from_pos, board_size)
		var after_distance: int = get_seeker_route_distance(after_state, player_id, stamp, to_pos, board_size)
		if before_distance >= 0:
			best_before = mini(best_before, before_distance)
		if after_distance >= 0:
			best_after = mini(best_after, after_distance)
			best_duration = max(1, stamp.duration)

	if best_after == 999:
		return 0.0

	var score: float = 0.0
	if best_before != 999:
		score += float(best_before - best_after) * SCORE_SEEKER_ROUTE_STAGING
	else:
		score += SCORE_SEEKER_ROUTE_STAGING * 0.5
	if best_after <= best_duration:
		score += SCORE_SEEKER_ATTACH_IN_ROUTE * 0.45
	return score

func get_available_seeker_stamps_for_player(game_state: GameStateData, player_id: int) -> Array:
	var stamps: Array = []
	var seen: Dictionary = {}
	var stamp_names: Array = []
	stamp_names.append_array(game_state.player_hands.get(player_id, []))
	stamp_names.append_array(game_state.player_decks.get(player_id, []))

	for stamp_name_value in stamp_names:
		var stamp_name: String = str(stamp_name_value)
		if seen.has(stamp_name):
			continue
		seen[stamp_name] = true
		var stamp: Stamp = get_cached_stamp(stamp_name)
		if stamp != null and MoveRules.is_seeker_stamp(stamp):
			stamps.append(stamp)
	return stamps

func get_seeker_route_distance(game_state: GameStateData, player_id: int, seeker_stamp: Stamp, from_pos: Vector2, board_size: int) -> int:
	if game_state == null or seeker_stamp == null:
		return -1

	var route_map: Dictionary = get_seeker_route_map(game_state, player_id, seeker_stamp, board_size)
	var key: String = vector_hash(from_pos)
	if !route_map.has(key):
		return -1
	return int(route_map[key])

func get_best_distance_to_seeker_route(game_state: GameStateData, player_id: int, seeker_stamp: Stamp, from_pos: Vector2, board_size: int) -> int:
	if game_state == null or seeker_stamp == null:
		return -1

	var route_map: Dictionary = get_seeker_route_map(game_state, player_id, seeker_stamp, board_size)
	var best_distance: int = 999
	for x in range(board_size):
		for y in range(board_size):
			var candidate_pos: Vector2 = Vector2(x, y)
			if !route_map.has(vector_hash(candidate_pos)):
				continue
			var distance: int = int(abs(candidate_pos.x - from_pos.x) + abs(candidate_pos.y - from_pos.y))
			best_distance = mini(best_distance, distance)
	return best_distance if best_distance != 999 else -1

func get_seeker_route_map(game_state: GameStateData, player_id: int, seeker_stamp: Stamp, board_size: int) -> Dictionary:
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var cache_key: String = "%s|p%d|base%s|fx%s" % [
		seeker_stamp.stamp_name,
		player_id,
		vector_hash(opponent_base),
		get_board_effects_hash(game_state.board_effects),
	]
	if seeker_route_cache.has(cache_key):
		return seeker_route_cache[cache_key]

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var route_map: Dictionary = {}
	var frontier: Array = [opponent_base]
	route_map[vector_hash(opponent_base)] = 0

	var depth: int = 0
	while !frontier.is_empty() and depth < MAX_SEEKER_ROUTE_DISTANCE:
		var next_frontier: Array = []
		for target_pos in frontier:
			for x in range(board_size):
				for y in range(board_size):
					var candidate_pos: Vector2 = Vector2(x, y)
					var candidate_key: String = vector_hash(candidate_pos)
					if route_map.has(candidate_key):
						continue
					if seeker_route_candidate_reaches_target(game_state, player_color, seeker_stamp, candidate_pos, target_pos, board_size):
						route_map[candidate_key] = depth + 1
						next_frontier.append(candidate_pos)
		frontier = next_frontier
		depth += 1

	seeker_route_cache[cache_key] = route_map
	return route_map

func seeker_route_candidate_reaches_target(
	game_state: GameStateData,
	player_color: int,
	seeker_stamp: Stamp,
	candidate_pos: Vector2,
	target_pos: Vector2,
	board_size: int
) -> bool:
	var moves: Array = MoveRules.get_stamp_moves_for_piece(
		game_state.pieces,
		candidate_pos,
		player_color,
		seeker_stamp,
		board_size,
		game_state.board_effects
	)
	if moves.has(target_pos):
		return true

	for direction_value in seeker_stamp.get_directions():
		var direction: Vector2 = StampEffectResolver.as_vector2(direction_value, Vector2.ZERO)
		if direction == Vector2.ZERO:
			continue
		if candidate_pos + direction == target_pos:
			return true
		if candidate_pos - direction == target_pos:
			return true
	return false

func get_board_effects_hash(board_effects: Array) -> String:
	var parts: Array = []
	for effect_value in board_effects:
		var effect: Dictionary = effect_value
		parts.append("%s:%d:%d:%d:%s" % [
			str(effect.get("effect_type", "")),
			int(effect.get("owner_player_id", -1)),
			int(effect.get("target_player_id", -1)),
			int(effect.get("turns_remaining", -1)),
			str(effect.get("squares", [])),
		])
	return ";".join(parts)

func score_hand_synergy(game_state: GameStateData, player_id: int) -> float:
	var hand: Array = game_state.player_hands.get(player_id, [])
	if hand.size() < 2:
		return 0.0

	var has_seeker: bool = false
	var has_protection: bool = false
	var has_control: bool = false
	var has_duration: bool = false
	var mobility_total: int = 0
	for stamp_name_value in hand:
		var stamp: Stamp = get_cached_stamp(str(stamp_name_value))
		if stamp == null:
			continue
		has_seeker = has_seeker or MoveRules.is_seeker_stamp(stamp)
		has_protection = has_protection or stamp.effect_type == StampEffect.TYPE_INVISIBLE_TO_ENEMY or stamp.effect_type == StampEffect.TYPE_UNCAPTURABLE
		has_control = has_control or stamp.effect_type == StampEffect.TYPE_FROZEN_SQUARES or stamp.effect_type == StampEffect.TYPE_INVALID_SQUARES or stamp.effect_type == StampEffect.TYPE_MOVE_BASE
		has_duration = has_duration or stamp.effect_type == StampEffect.TYPE_INCREASE_SELF_DURATION or stamp.effect_type == StampEffect.TYPE_INCREASE_OWN_DURATIONS
		mobility_total += stamp.get_directions().size()

	var score: float = 0.0
	if has_seeker and has_protection:
		score += SCORE_HAND_SYNERGY * 2.0
	if has_seeker and has_control:
		score += SCORE_HAND_SYNERGY
	if has_duration and mobility_total >= hand.size() * 3:
		score += SCORE_HAND_SYNERGY * 0.75
	if !has_seeker:
		score -= 8.0
	return score

func score_remaining_hand_quality(game_state: GameStateData, player_id: int, actions: Array) -> float:
	var consumed_stamp_names: Array = []
	for action_value in actions:
		if !(action_value is Dictionary):
			continue
		var action: Dictionary = action_value
		if str(action.get("type", "")) == "attach_stamp":
			consumed_stamp_names.append(str(action.get("stamp_name", "")))

	var hand: Array = game_state.player_hands.get(player_id, [])
	var score: float = 0.0
	var remaining_count: int = 0
	for stamp_name_value in hand:
		var stamp_name: String = str(stamp_name_value)
		var consumed_index: int = consumed_stamp_names.find(stamp_name)
		if consumed_index != -1:
			consumed_stamp_names.remove_at(consumed_index)
			continue

		var stamp: Stamp = get_cached_stamp(stamp_name)
		if stamp == null:
			continue
		score += get_stamp_balance_value(stamp)
		if MoveRules.is_seeker_stamp(stamp):
			score += 12.0
		remaining_count += 1

	if remaining_count <= 0:
		return -8.0
	return score / float(remaining_count)

func score_remaining_deck_quality(game_state: GameStateData, player_id: int) -> float:
	var deck: Array = game_state.player_decks.get(player_id, [])
	if deck.is_empty():
		return -6.0

	var sample_count: int = mini(5, deck.size())
	var score: float = 0.0
	for index in range(sample_count):
		var stamp: Stamp = get_cached_stamp(str(deck[index]))
		if stamp == null:
			continue
		score += get_stamp_balance_value(stamp)
		if MoveRules.is_seeker_stamp(stamp):
			score += 8.0
	return score / float(sample_count)

func score_deck_draw_quality(game_state: GameStateData, player_id: int, avoided_stamp_name: String) -> float:
	var deck: Array = game_state.player_decks.get(player_id, [])
	if deck.is_empty():
		return -10.0

	for stamp_name_value in deck:
		var stamp_name: String = str(stamp_name_value)
		if stamp_name == avoided_stamp_name:
			continue
		var stamp: Stamp = get_cached_stamp(stamp_name)
		if stamp == null:
			continue
		var score: float = get_stamp_balance_value(stamp)
		if MoveRules.is_seeker_stamp(stamp):
			score += 10.0
		return score
	return -5.0

func score_threat_map_for_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	if game_state == null or plan.is_empty():
		return 0.0

	var simulated_state: GameStateData = AIStateSimulator.apply_turn_plan(game_state, player_id, plan, board_size)
	if simulated_state.game_over:
		return clampf(get_terminal_score_for_player(simulated_state, player_id) * 0.05, -SCORE_WIN * 0.05, SCORE_WIN * 0.05)

	var opponent_player_id: int = 1 - player_id
	var score: float = 0.0
	score += score_two_turn_base_pressure(simulated_state, player_id, board_size)
	score -= score_two_turn_base_pressure(simulated_state, opponent_player_id, board_size) * 1.25
	score += score_attack_map_pressure(simulated_state, player_id, board_size) * SCORE_THREAT_MAP_OWN_ATTACK
	score -= score_attack_map_pressure(simulated_state, opponent_player_id, board_size) * PENALTY_THREAT_MAP_EXPOSURE
	return score

func score_two_turn_base_pressure(game_state: GameStateData, player_id: int, board_size: int) -> float:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var opponent_player_id: int = 1 - player_id
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, opponent_player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_stamp_moves(
		game_state.pieces,
		player_color,
		board_size,
		game_state.board_effects
	)

	var best_pressure: float = 0.0
	for move: Dictionary in valid_moves:
		var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
		if AIStateSimulator.is_own_seeker_candidate(game_state.pieces, move, player_id) and to_pos == opponent_base:
			best_pressure = maxf(best_pressure, SCORE_WIN * 0.25)
			continue

		var distance_after: float = get_manhattan_distance(to_pos, opponent_base)
		var pressure: float = maxf(0.0, float(board_size) - distance_after) * 8.0
		if AIStateSimulator.is_own_seeker_candidate(game_state.pieces, move, player_id):
			pressure += SCORE_TWO_TURN_BASE_THREAT
		var simulated_plan: Dictionary = {
			"actions": [{
				"type": "move_piece",
				"player_id": player_id,
				"from": AIStateSimulator.get_move_from(move),
				"to": to_pos,
			}],
			"move": move,
			"setup_attach_actions": [],
			"plan_type": "threat_probe",
		}
		var next_state: GameStateData = AIStateSimulator.apply_turn_plan(game_state, player_id, simulated_plan, board_size)
		if !next_state.game_over and has_immediate_base_win(next_state, player_id, board_size):
			pressure += SCORE_FORCE_DEFENSE
		best_pressure = maxf(best_pressure, pressure)
	return best_pressure

func has_immediate_base_win(game_state: GameStateData, player_id: int, board_size: int) -> bool:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_stamp_moves(
		game_state.pieces,
		player_color,
		board_size,
		game_state.board_effects
	)
	for move: Dictionary in valid_moves:
		if AIStateSimulator.get_move_to(move) == opponent_base and AIStateSimulator.is_own_seeker_candidate(game_state.pieces, move, player_id):
			return true
	return false

func score_attack_map_pressure(game_state: GameStateData, player_id: int, board_size: int) -> float:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var opponent_player_id: int = 1 - player_id
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_stamp_moves(
		game_state.pieces,
		player_color,
		board_size,
		game_state.board_effects
	)
	var pressure: float = 0.0
	var threatened_squares: Dictionary = {}
	for move: Dictionary in valid_moves:
		var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
		var square_key: String = vector_hash(to_pos)
		if threatened_squares.has(square_key):
			continue
		threatened_squares[square_key] = true

		var target_piece: Piece = game_state.get_piece(to_pos)
		if target_piece == null:
			continue
		var target_player_id: int = StampEffectResolver.get_player_id_for_color(target_piece.color)
		if target_player_id != opponent_player_id:
			continue
		pressure += get_piece_target_score(target_piece)
	return pressure

func score_turn_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int = BoardConfig.BOARD_SIZE) -> float:
	var breakdown: Dictionary = score_turn_plan_breakdown(game_state, player_id, plan, board_size)
	return float(breakdown.get("total", 0.0))

func score_turn_plan_breakdown(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int = BoardConfig.BOARD_SIZE) -> Dictionary:
	var move_score: float = 0.0
	var setup_score: float = 0.0
	var action_score: float = 0.0

	var move: Dictionary = plan.get("move", {})
	if !move.is_empty():
		move_score = score_move_cached(game_state, player_id, move, board_size)

	var setup_attach_actions: Array = plan.get("setup_attach_actions", [])
	for attach_action_value in setup_attach_actions:
		var attach_action: Dictionary = attach_action_value
		setup_score += score_attach_setup(game_state, player_id, attach_action, board_size)

	var actions: Array = plan.get("actions", [])
	action_score = -float(maxi(0, actions.size() - 1)) * 0.8
	var economy_score: float = score_hand_deck_economy_for_plan(game_state, player_id, plan)
	var threat_score: float = score_threat_map_for_plan(game_state, player_id, plan, board_size)
	var route_score: float = score_seeker_route_strategy_for_plan(game_state, player_id, plan, board_size)
	var strategy_score: float = score_strategy_mode_for_plan(game_state, player_id, plan, board_size)
	var hard_rule_score: float = score_hard_tactical_rules_for_plan(game_state, player_id, plan, board_size)
	var total_score: float = move_score + setup_score + action_score + economy_score + threat_score + route_score + strategy_score + hard_rule_score
	return {
		"move": move_score,
		"setup": setup_score,
		"action_count": action_score,
		"economy": economy_score,
		"threat": threat_score,
		"seeker_route": route_score,
		"strategy": strategy_score,
		"hard_rules": hard_rule_score,
		"total": total_score,
	}

func score_hard_tactical_rules_for_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	if game_state == null or plan.is_empty():
		return 0.0

	var opponent_player_id: int = 1 - player_id
	var opponent_had_immediate_base_win: bool = has_immediate_base_win(game_state, opponent_player_id, board_size)
	var simulated_state: GameStateData = AIStateSimulator.apply_turn_plan(game_state, player_id, plan, board_size)
	var opponent_has_immediate_base_win_after: bool = has_immediate_base_win(simulated_state, opponent_player_id, board_size)
	var score: float = 0.0

	if opponent_had_immediate_base_win:
		score += SCORE_EMERGENCY_PREVENT_BASE_WIN if !opponent_has_immediate_base_win_after else -PENALTY_ALLOW_IMMEDIATE_BASE_WIN
	elif opponent_has_immediate_base_win_after:
		score -= PENALTY_ALLOW_IMMEDIATE_BASE_WIN

	score += score_active_seeker_finish_rule(game_state, simulated_state, player_id, plan, board_size)
	score += score_opponent_active_seeker_defense_rule(game_state, simulated_state, player_id, plan, board_size)
	score += score_move_base_piece_escape_rule(game_state, simulated_state, player_id, plan, board_size)
	score += score_material_advantage_finish_rule(game_state, simulated_state, player_id, plan, board_size)
	score += score_move_off_enemy_base_rule(game_state, player_id, plan)
	return score

func score_opponent_active_seeker_defense_rule(
	before_state: GameStateData,
	after_state: GameStateData,
	player_id: int,
	plan: Dictionary,
	board_size: int
) -> float:
	var opponent_player_id: int = 1 - player_id
	var before_distance: int = get_best_active_seeker_route_distance(before_state, opponent_player_id, board_size)
	if before_distance < 0:
		return 0.0
	if after_state.game_over:
		return -SCORE_WIN if after_state.winner_player == opponent_player_id else SCORE_WIN

	var after_distance: int = get_best_active_seeker_route_distance(after_state, opponent_player_id, board_size)
	var score: float = 0.0
	if after_distance < 0:
		return SCORE_DEFENSE_CAPTURE_SEEKER * 2.0

	score += float(after_distance - before_distance) * SCORE_DEFENSE_PUSH_SEEKER_BACK
	if before_distance <= 2 and after_distance <= before_distance:
		score -= PENALTY_IGNORE_ENEMY_SEEKER_PUSH
	if before_distance <= 1 and after_distance <= 1:
		score -= PENALTY_ALLOW_IMMEDIATE_BASE_WIN * 0.35

	var move: Dictionary = plan.get("move", {})
	if !move.is_empty():
		var captured_piece: Piece = AIStateSimulator.get_captured_piece(before_state.pieces, move)
		if captured_piece != null and MoveRules.is_seeker_stamp(captured_piece.attached_stamp):
			score += SCORE_DEFENSE_CAPTURE_SEEKER * 1.5
	return score

func score_material_advantage_finish_rule(
	before_state: GameStateData,
	after_state: GameStateData,
	player_id: int,
	plan: Dictionary,
	board_size: int
) -> float:
	var own_pieces: int = count_player_pieces_on_board(before_state, player_id)
	var enemy_pieces: int = count_player_pieces_on_board(before_state, 1 - player_id)
	var material_advantage: int = own_pieces - enemy_pieces
	if material_advantage < 2 and enemy_pieces > 4:
		return 0.0

	var score: float = 0.0
	if should_push_active_board_seeker(before_state, player_id):
		score += score_active_seeker_finish_rule(before_state, after_state, player_id, plan, board_size) * 0.8
	else:
		score += score_force_seeker_closing_plan(before_state, after_state, player_id, plan, board_size) * 0.9

	var move: Dictionary = plan.get("move", {})
	if !move.is_empty():
		var captured_piece: Piece = AIStateSimulator.get_captured_piece(before_state.pieces, move)
		var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
		var closing_ready: bool = is_any_available_seeker_ready_on_piece(after_state, player_id, to_pos, board_size)
		if captured_piece != null and !closing_ready and !AIStateSimulator.is_own_seeker_candidate(before_state.pieces, move, player_id):
			score -= PENALTY_AHEAD_NON_CLOSING_CAPTURE
	score += float(maxi(0, material_advantage)) * SCORE_MATERIAL_ADVANTAGE_FINISH
	return score

func score_move_base_piece_escape_rule(
	before_state: GameStateData,
	after_state: GameStateData,
	player_id: int,
	plan: Dictionary,
	board_size: int
) -> float:
	var before_risk: float = score_move_base_piece_seeker_risk(before_state, player_id, board_size)
	if before_risk <= 0.0:
		return 0.0

	var after_risk: float = score_move_base_piece_seeker_risk(after_state, player_id, board_size)
	var score: float = (before_risk - after_risk) * SCORE_MOVE_BASE_PIECE_ESCAPE
	if after_risk >= before_risk:
		score -= PENALTY_MOVE_BASE_PIECE_THREATENED_BY_SEEKER

	var move: Dictionary = plan.get("move", {})
	if !move.is_empty():
		var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
		var moving_piece: Piece = before_state.get_piece(from_pos)
		if is_move_base_piece(moving_piece):
			score += SCORE_MOVE_BASE_PIECE_ESCAPE * 0.75
	return score

func score_move_base_piece_seeker_risk(game_state: GameStateData, player_id: int, board_size: int) -> float:
	if game_state == null:
		return 0.0

	var risk: float = 0.0
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var opponent_player_id: int = 1 - player_id
	for position_value in game_state.pieces:
		var pos: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != player_color or !is_move_base_piece(piece):
			continue

		if can_opponent_seeker_capture_square(game_state, opponent_player_id, pos, board_size):
			risk += 3.0
			continue

		var nearest_seeker_distance: float = get_nearest_active_seeker_distance(game_state, opponent_player_id, pos)
		if nearest_seeker_distance <= 1.0:
			risk += 2.0
		elif nearest_seeker_distance <= 2.0:
			risk += 1.0
	return risk

func is_move_base_piece(piece: Piece) -> bool:
	return piece != null and piece.attached_stamp != null and piece.attached_stamp.effect_type == StampEffect.TYPE_MOVE_BASE

func can_opponent_seeker_capture_square(game_state: GameStateData, opponent_player_id: int, square: Vector2, board_size: int) -> bool:
	var opponent_color: int = StampEffectResolver.get_color_for_player_id(opponent_player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_stamp_moves(
		game_state.pieces,
		opponent_color,
		board_size,
		game_state.board_effects
	)
	for move: Dictionary in valid_moves:
		if AIStateSimulator.get_move_to(move) == square and AIStateSimulator.is_own_seeker_candidate(game_state.pieces, move, opponent_player_id):
			return true
	return false

func get_nearest_active_seeker_distance(game_state: GameStateData, player_id: int, square: Vector2) -> float:
	var best_distance: float = 999.0
	for entry: Dictionary in get_active_seeker_pieces_for_player(game_state, player_id):
		var pos: Vector2 = StampEffectResolver.as_vector2(entry.get("position", Vector2(-1, -1)), Vector2(-1, -1))
		best_distance = minf(best_distance, get_manhattan_distance(pos, square))
	return best_distance

func score_active_seeker_finish_rule(before_state: GameStateData, after_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	if !should_push_active_board_seeker(before_state, player_id):
		return 0.0
	if after_state.game_over:
		return SCORE_WIN if after_state.winner_player == player_id else -SCORE_WIN

	var before_distance: int = get_best_active_seeker_route_distance(before_state, player_id, board_size)
	var after_distance: int = get_best_active_seeker_route_distance(after_state, player_id, board_size)
	if before_distance < 0:
		return 0.0
	if after_distance < 0:
		return -PENALTY_ACTIVE_SEEKER_RETREAT

	var move: Dictionary = plan.get("move", {})
	var route_clear_score: float = score_route_clearing_move(before_state, player_id, move, board_size) if !move.is_empty() else 0.0
	if after_distance < before_distance:
		return float(before_distance - after_distance) * SCORE_ACTIVE_SEEKER_FINISH
	if route_clear_score > 0.0:
		return route_clear_score * 1.8
	if after_distance == before_distance:
		return -PENALTY_IGNORE_ACTIVE_SEEKER_PUSH
	return -PENALTY_ACTIVE_SEEKER_RETREAT * float(after_distance - before_distance)

func get_best_active_seeker_route_distance(game_state: GameStateData, player_id: int, board_size: int) -> int:
	var best_distance: int = 999
	for entry: Dictionary in get_active_seeker_pieces_for_player(game_state, player_id):
		var pos: Vector2 = StampEffectResolver.as_vector2(entry.get("position", Vector2(-1, -1)), Vector2(-1, -1))
		var stamp: Stamp = entry.get("stamp", null) as Stamp
		if stamp == null:
			continue
		var distance: int = get_seeker_route_distance(game_state, player_id, stamp, pos, board_size)
		if distance >= 0:
			best_distance = mini(best_distance, distance)
	return best_distance if best_distance < 999 else -1

func score_move_off_enemy_base_rule(game_state: GameStateData, player_id: int, plan: Dictionary) -> float:
	var move: Dictionary = plan.get("move", {})
	if move.is_empty():
		return 0.0

	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	if from_pos != opponent_base or to_pos == opponent_base:
		return 0.0

	var moving_piece: Piece = game_state.get_piece(from_pos)
	if moving_piece != null and MoveRules.is_seeker_stamp(moving_piece.attached_stamp):
		return 0.0
	if player_has_seeker_win_plan(game_state, player_id):
		return SCORE_CLEAR_OWN_NON_SEEKER_FROM_ENEMY_BASE
	return 0.0

func score_non_seeker_base_entry_penalty(game_state: GameStateData, player_id: int, move: Dictionary) -> float:
	if game_state == null or move.is_empty():
		return 0.0

	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	if to_pos != opponent_base:
		return 0.0
	if AIStateSimulator.is_own_seeker_candidate(game_state.pieces, move, player_id):
		return 0.0
	if should_push_active_board_seeker(game_state, player_id):
		return -PENALTY_NON_SEEKER_BASE_ENTRY_WHILE_SEEKER_ACTIVE
	if !get_available_seeker_stamps_for_player(game_state, player_id).is_empty():
		return -PENALTY_NON_SEEKER_BASE_BLOCKS_SEEKER_PLAN
	return -PENALTY_MOVE_OFF_ENEMY_BASE_WITHOUT_SEEKER * 0.35

func player_has_seeker_win_plan(game_state: GameStateData, player_id: int) -> bool:
	return should_push_active_board_seeker(game_state, player_id) or !get_available_seeker_stamps_for_player(game_state, player_id).is_empty()

func score_repeat_last_move_penalty(game_state: GameStateData, player_id: int, move: Dictionary) -> float:
	if game_state == null or game_state.last_move.is_empty() or move.is_empty():
		return 0.0
	if int(game_state.last_move.get("player_id", -1)) != player_id:
		return 0.0

	var last_from: Vector2 = StampEffectResolver.as_vector2(game_state.last_move.get("from", Vector2(-1, -1)), Vector2(-1, -1))
	var last_to: Vector2 = StampEffectResolver.as_vector2(game_state.last_move.get("to", Vector2(-1, -1)), Vector2(-1, -1))
	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	if from_pos == last_to and to_pos == last_from:
		return -PENALTY_REPEAT_LAST_MOVE
	return 0.0

func score_strategy_mode_for_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	if strategy_context.is_empty() or int(strategy_context.get("player_id", -1)) != player_id:
		return 0.0

	match str(strategy_context.get("mode", "")):
		"opening":
			return score_opening_strategy_plan(game_state, player_id, plan, board_size)
		"active_seeker_push":
			return score_active_seeker_strategy_plan(game_state, player_id, plan, board_size)
		"endgame_seeker_finish":
			return score_endgame_seeker_finish_strategy_plan(game_state, player_id, plan, board_size)
		"soft_defense":
			return score_defense_strategy_plan(game_state, player_id, plan, board_size, 1.0)
		"emergency_defense":
			return score_defense_strategy_plan(game_state, player_id, plan, board_size, 2.0)
		"route_setup":
			return score_seeker_route_strategy_for_plan(game_state, player_id, plan, board_size) * 0.35
		_:
			return 0.0

func score_opening_strategy_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	if game_state == null or plan.is_empty():
		return 0.0

	var simulated_state: GameStateData = AIStateSimulator.apply_turn_plan(game_state, player_id, plan, board_size)
	if simulated_state.game_over:
		return 0.0

	var before_center_count: int = count_player_pieces_in_strategy_center(game_state, player_id, board_size)
	var after_center_count: int = count_player_pieces_in_strategy_center(simulated_state, player_id, board_size)
	var target_count: int = int(strategy_context.get("opening_target_count", 3))
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

	var setup_attach_actions: Array = plan.get("setup_attach_actions", [])
	for action_value in setup_attach_actions:
		if !(action_value is Dictionary):
			continue
		var action: Dictionary = action_value
		var stamp: Stamp = get_cached_stamp(str(action.get("stamp_name", "")))
		if stamp != null and MoveRules.is_seeker_stamp(stamp):
			score -= 95.0
	return score

func score_active_seeker_strategy_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	var move: Dictionary = plan.get("move", {})
	if move.is_empty():
		return 0.0
	var simulated_state: GameStateData = AIStateSimulator.apply_turn_plan(game_state, player_id, plan, board_size)
	if simulated_state.game_over:
		return SCORE_WIN * 0.25
	return score_active_seeker_push_plan(game_state, simulated_state, player_id, move, board_size) * 2.6

func score_endgame_seeker_finish_strategy_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	if game_state == null or plan.is_empty():
		return 0.0

	var simulated_state: GameStateData = AIStateSimulator.apply_turn_plan(game_state, player_id, plan, board_size)
	if simulated_state.game_over:
		return SCORE_WIN * 0.35 if simulated_state.winner_player == player_id else -SCORE_WIN

	var score: float = 0.0
	var move: Dictionary = plan.get("move", {})
	if should_push_active_board_seeker(game_state, player_id):
		if !move.is_empty():
			score += score_active_seeker_push_plan(game_state, simulated_state, player_id, move, board_size) * 3.4
		return score

	if !move.is_empty():
		score += score_endgame_move_toward_seeker_finish(game_state, simulated_state, player_id, move, board_size)
		score += score_force_seeker_closing_plan(game_state, simulated_state, player_id, plan, board_size)

	var actions: Array = plan.get("actions", [])
	for action_value in actions:
		if !(action_value is Dictionary):
			continue
		var action: Dictionary = action_value
		match str(action.get("type", "")):
			"attach_stamp":
				score += score_endgame_attach_action(game_state, player_id, action, board_size)
			"exchange_stamp":
				var exchanged_stamp: Stamp = get_cached_stamp(str(action.get("stamp_name", "")))
				if exchanged_stamp != null and MoveRules.is_seeker_stamp(exchanged_stamp):
					score -= PENALTY_ENDGAME_EXCHANGE_SEEKER_PLAN
	return score

func score_endgame_move_toward_seeker_finish(
	before_state: GameStateData,
	after_state: GameStateData,
	player_id: int,
	move: Dictionary,
	board_size: int
) -> float:
	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var seeker_stamps: Array = get_available_seeker_stamps_for_player(before_state, player_id)
	if seeker_stamps.is_empty():
		return 0.0

	var best_before: int = 999
	var best_after: int = 999
	var best_allowed_steps: int = 1
	for stamp in seeker_stamps:
		if stamp == null:
			continue
		var before_distance: int = get_seeker_route_distance(before_state, player_id, stamp, from_pos, board_size)
		var after_distance: int = get_seeker_route_distance(after_state, player_id, stamp, to_pos, board_size)
		if before_distance >= 0:
			best_before = mini(best_before, before_distance)
		if after_distance >= 0:
			best_after = mini(best_after, after_distance)
			best_allowed_steps = max(1, stamp.duration)

	if best_after == 999:
		return -SCORE_ENDGAME_SEEKER_ROUTE * 0.5

	var score: float = 0.0
	if best_before != 999:
		var delta: int = best_before - best_after
		score += float(delta) * SCORE_ENDGAME_SEEKER_ROUTE
		if delta < 0:
			score += float(delta) * SCORE_ENDGAME_SEEKER_ROUTE
	else:
		score += SCORE_ENDGAME_SEEKER_ROUTE * 0.35
	var can_attach_after_move: bool = can_piece_receive_seeker_at(after_state, player_id, to_pos)
	if best_after <= best_allowed_steps and can_attach_after_move:
		score += SCORE_ENDGAME_SEEKER_ATTACH_READY + SCORE_HOLD_SEEKER_STAGING_SQUARE
	elif best_after <= best_allowed_steps + 2:
		score += SCORE_ENDGAME_SEEKER_ATTACH_NEAR
	if !can_attach_after_move:
		score += score_seeker_staging_stamp_block(after_state, player_id, to_pos, board_size)
	return score

func score_endgame_attach_action(game_state: GameStateData, player_id: int, action: Dictionary, board_size: int) -> float:
	var stamp: Stamp = get_cached_stamp(str(action.get("stamp_name", "")))
	if stamp == null:
		return 0.0

	var piece_pos: Vector2 = StampEffectResolver.as_vector2(action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
	if !MoveRules.is_seeker_stamp(stamp):
		return -PENALTY_ENDGAME_NON_SEEKER_ATTACH

	var route_distance: int = get_seeker_route_distance(game_state, player_id, stamp, piece_pos, board_size)
	var allowed_steps: int = max(1, stamp.duration)
	if route_distance >= 0 and route_distance <= allowed_steps:
		return SCORE_ENDGAME_SEEKER_ATTACH_READY + float(allowed_steps - route_distance) * 55.0
	if route_distance >= 0 and route_distance <= allowed_steps + 2:
		return SCORE_ENDGAME_SEEKER_ATTACH_NEAR - float(route_distance - allowed_steps) * 45.0
	return -PENALTY_SEEKER_ATTACH_OUT_OF_ROUTE

func score_defense_strategy_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int, urgency: float) -> float:
	if game_state == null or plan.is_empty():
		return 0.0

	var simulated_state: GameStateData = AIStateSimulator.apply_turn_plan(game_state, player_id, plan, board_size)
	var before_threat: float = score_base_threat_against_player(game_state, player_id, board_size)
	var after_threat: float = score_base_threat_against_player(simulated_state, player_id, board_size)
	var score: float = (before_threat - after_threat) * SCORE_DEFENSE_THREAT_REDUCTION * urgency

	var move: Dictionary = plan.get("move", {})
	if !move.is_empty():
		var captured_piece: Piece = AIStateSimulator.get_captured_piece(game_state.pieces, move)
		if captured_piece != null and StampEffectResolver.get_player_id_for_color(captured_piece.color) != player_id:
			if MoveRules.is_seeker_stamp(captured_piece.attached_stamp):
				score += SCORE_DEFENSE_CAPTURE_SEEKER * urgency
			else:
				score += get_piece_target_score(captured_piece) * 0.8 * urgency

		var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
		var own_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, player_id)
		if get_manhattan_distance(to_pos, own_base) <= 2.0:
			score += SCORE_DEFENSE_BASE_GUARD * urgency
	return score

func score_base_threat_against_player(game_state: GameStateData, player_id: int, board_size: int) -> float:
	if game_state == null:
		return 0.0

	var enemy_player_id: int = 1 - player_id
	var enemy_color: int = StampEffectResolver.get_color_for_player_id(enemy_player_id)
	var own_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, player_id)
	var threat: float = 0.0
	for position_value in game_state.pieces:
		var pos: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != enemy_color:
			continue

		var distance: float = get_manhattan_distance(pos, own_base)
		if distance <= 3.0:
			threat += float(board_size) - distance
		if MoveRules.is_seeker_stamp(piece.attached_stamp):
			threat += 18.0
			if distance <= 3.0:
				threat += 24.0
	return threat

func count_player_pieces_on_board(game_state: GameStateData, player_id: int) -> int:
	if game_state == null:
		return 0
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var count: int = 0
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null and piece.color == player_color:
			count += 1
	return count

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
	var center_zone_keys: Array = strategy_context.get("center_zone_keys", [])
	return center_zone_keys.has(vector_hash(pos))

func get_distance_to_board_center(pos: Vector2, board_size: int) -> float:
	var center: Vector2 = Vector2(float(board_size - 1) / 2.0, float(board_size - 1) / 2.0)
	return get_manhattan_distance(pos, center)

func score_attach_setup(game_state: GameStateData, player_id: int, attach_action: Dictionary, board_size: int) -> float:
	return score_attach_setup_with_stamp_value_weight(game_state, player_id, attach_action, board_size, STAMP_VALUE_ATTACH_PLAY_WEIGHT)

func score_attach_setup_for_exchange(game_state: GameStateData, player_id: int, attach_action: Dictionary, board_size: int) -> float:
	return score_attach_setup_with_stamp_value_weight(game_state, player_id, attach_action, board_size, STAMP_VALUE_ATTACH_EXCHANGE_WEIGHT)

func score_attach_setup_with_stamp_value_weight(
	game_state: GameStateData,
	player_id: int,
	attach_action: Dictionary,
	board_size: int,
	stamp_value_weight: float
) -> float:
	var piece_pos: Vector2 = StampEffectResolver.as_vector2(attach_action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
	var piece: Piece = game_state.get_piece(piece_pos)
	if piece == null:
		return 0.0

	var stamp: Stamp = attach_action.get("stamp", null) as Stamp
	if stamp == null:
		stamp = get_cached_stamp(str(attach_action.get("stamp_name", "")))
	if stamp == null:
		return 0.0

	var is_seeker_stamp: bool = MoveRules.is_seeker_stamp(stamp)
	var seeker_ready: bool = !is_seeker_stamp or is_seeker_attach_in_timing_window(game_state, player_id, stamp, piece_pos, board_size)
	var score: float = SCORE_ATTACH_STAMP
	if is_seeker_stamp:
		if seeker_ready:
			score += SCORE_ATTACH_SEEKER
		else:
			score -= PENALTY_EARLY_SEEKER_COMMITMENT

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var setup_moves: Array[Vector2] = MoveRules.get_stamp_moves_for_piece(
		game_state.pieces,
		piece_pos,
		player_color,
		stamp,
		board_size,
		game_state.board_effects
	)
	score += float(setup_moves.size()) * SCORE_ATTACH_SETUP_MOBILITY
	if setup_moves.is_empty():
		score -= PENALTY_ATTACH_SETUP_NO_MOVE
	score += get_stamp_balance_value(stamp) * stamp_value_weight
	if is_seeker_stamp:
		score += score_seeker_attach_timing(game_state, player_id, stamp, piece_pos, piece_pos, board_size)
	else:
		score += score_seeker_base_entry_threat(game_state, player_id, piece_pos, stamp, board_size)

	var setup_move: Dictionary = {
		"from": piece_pos,
		"to": piece_pos,
		"stamp": stamp,
		"requires_attach": true,
	}
	var stamp_effect_weight: float = 0.65
	if is_seeker_stamp and !seeker_ready:
		stamp_effect_weight = 0.05
	score += score_stamp_effect(game_state, player_id, piece, stamp, piece_pos, piece_pos, null, setup_move, board_size) * stamp_effect_weight
	score -= score_attachment_danger(game_state, player_id, attach_action, board_size, true)
	return score

func score_move(game_state: GameStateData, player_id: int, move: Dictionary, board_size: int = BoardConfig.BOARD_SIZE) -> float:
	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var score: float = 0.0
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var opponent_player_id: int = 1 - player_id
	var moving_piece: Piece = game_state.get_piece(from_pos)
	if moving_piece == null:
		return -SCORE_WIN

	var stamp: Stamp = AIStateSimulator.get_stamp_for_candidate(game_state.pieces, move)
	var captured_piece: Piece = AIStateSimulator.get_captured_piece(game_state.pieces, move)
	var is_own_seeker_move: bool = AIStateSimulator.is_own_seeker_candidate(game_state.pieces, move, player_id)

	if bool(move.get("requires_attach", false)):
		score += score_attached_stamp(game_state, player_id, moving_piece, stamp, from_pos, to_pos, captured_piece, move, board_size)
	else:
		score += SCORE_USE_EXISTING_STAMP

	if captured_piece != null:
		score += score_capture(captured_piece)
		score += score_base_staging_capture(game_state, player_id, captured_piece, to_pos, board_size)
		score += score_seeker_capture_discipline(game_state, player_id, move, captured_piece, board_size)
		if has_active_seeker_near_finish(game_state, player_id, board_size) and !is_own_seeker_move:
			score -= PENALTY_ENDGAME_NON_CLOSING_CAPTURE

	if is_own_seeker_move:
		score += score_seeker_base_progress(game_state, player_id, from_pos, to_pos)
		var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, opponent_player_id)
		if moving_piece.color == player_color && to_pos == opponent_base:
			score += SCORE_WIN
	else:
		score += score_non_seeker_base_entry_penalty(game_state, player_id, move)

	score += score_center_control(to_pos, board_size)
	score += score_seeker_threat(game_state, player_id, move, board_size)
	score += score_repeat_last_move_penalty(game_state, player_id, move)
	score -= score_danger_after_move(game_state, player_id, move, board_size)
	return score

func score_attached_stamp(
	game_state: GameStateData,
	player_id: int,
	moving_piece: Piece,
	stamp: Stamp,
	from_pos: Vector2,
	to_pos: Vector2,
	captured_piece: Piece,
	move: Dictionary,
	board_size: int
) -> float:
	if stamp == null:
		return 0.0

	var score: float = SCORE_ATTACH_STAMP
	var is_seeker_stamp: bool = MoveRules.is_seeker_stamp(stamp)
	var seeker_ready: bool = !is_seeker_stamp or is_seeker_attach_in_timing_window(game_state, player_id, stamp, to_pos, board_size)
	if is_seeker_stamp:
		if seeker_ready:
			score += SCORE_ATTACH_SEEKER
		else:
			score -= PENALTY_EARLY_SEEKER_COMMITMENT

	score += max(0, stamp.duration) * 3.0
	score += get_stamp_balance_value(stamp) * STAMP_VALUE_ATTACH_PLAY_WEIGHT
	if is_seeker_stamp:
		score += score_seeker_attach_timing(game_state, player_id, stamp, from_pos, to_pos, board_size)
	var stamp_effect_weight: float = 1.0
	if is_seeker_stamp and !seeker_ready:
		stamp_effect_weight = 0.05
	score += score_stamp_effect(game_state, player_id, moving_piece, stamp, from_pos, to_pos, captured_piece, move, board_size) * stamp_effect_weight
	return score

func is_seeker_attach_in_timing_window(game_state: GameStateData, player_id: int, stamp: Stamp, pos: Vector2, board_size: int) -> bool:
	if game_state == null or !MoveRules.is_seeker_stamp(stamp):
		return false
	var route_distance: int = get_seeker_route_distance(game_state, player_id, stamp, pos, board_size)
	if route_distance < 0:
		return false
	var allowed_steps: int = max(1, stamp.duration)
	if route_distance <= max(1, allowed_steps - 1):
		return true
	return is_endgame_seeker_finish_mode() and route_distance <= allowed_steps

func is_endgame_seeker_finish_mode() -> bool:
	return str(strategy_context.get("mode", "")) == "endgame_seeker_finish"

func score_seeker_attach_timing(
	game_state: GameStateData,
	player_id: int,
	stamp: Stamp,
	from_pos: Vector2,
	to_pos: Vector2,
	board_size: int
) -> float:
	if game_state == null or !MoveRules.is_seeker_stamp(stamp):
		return 0.0

	var allowed_steps: int = max(1, stamp.duration)
	var route_distance: int = get_seeker_route_distance(game_state, player_id, stamp, to_pos, board_size)
	if is_seeker_attach_in_timing_window(game_state, player_id, stamp, to_pos, board_size):
		return SCORE_SEEKER_ATTACH_IN_ROUTE + float(allowed_steps - route_distance) * 32.0

	var penalty: float = get_early_seeker_attach_penalty(game_state, player_id, stamp, from_pos)
	var distance_to_route: int = get_best_distance_to_seeker_route(game_state, player_id, stamp, to_pos, board_size)
	if distance_to_route >= 0:
		penalty += float(distance_to_route) * 28.0
	else:
		penalty += 90.0
	return -penalty

func score_seeker_capture_discipline(
	game_state: GameStateData,
	player_id: int,
	move: Dictionary,
	captured_piece: Piece,
	board_size: int
) -> float:
	if game_state == null or captured_piece == null:
		return 0.0
	if !AIStateSimulator.is_own_seeker_candidate(game_state.pieces, move, player_id):
		return 0.0
	if StampEffectResolver.is_seeker_piece(captured_piece):
		return 0.0

	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	if to_pos == opponent_base:
		return 0.0

	var stamp: Stamp = AIStateSimulator.get_stamp_for_candidate(game_state.pieces, move)
	if stamp == null or !MoveRules.is_seeker_stamp(stamp):
		return 0.0

	var before_route_distance: int = get_seeker_route_distance(game_state, player_id, stamp, from_pos, board_size)
	var after_route_distance: int = get_seeker_route_distance(game_state, player_id, stamp, to_pos, board_size)
	var penalty: float = PENALTY_SEEKER_CAPTURE_DISTRACTION
	if after_route_distance >= 0 and (before_route_distance < 0 or after_route_distance < before_route_distance):
		penalty *= 0.35
	if is_endgame_seeker_finish_mode():
		penalty *= 0.5
	return -penalty

func score_capture(captured_piece: Piece) -> float:
	if captured_piece == null:
		return 0.0
	if StampEffectResolver.is_seeker_piece(captured_piece):
		return SCORE_CAPTURE_SEEKER

	var score: float = SCORE_CAPTURE_PIECE
	if captured_piece.attached_stamp != null:
		score += SCORE_CAPTURE_STAMP
		score += max(0, captured_piece.turns_remaining) * 8.0
		score += get_stamp_balance_value(captured_piece.attached_stamp) * STAMP_VALUE_CAPTURE_WEIGHT
	return score

func score_seeker_base_progress(game_state: GameStateData, player_id: int, from_pos: Vector2, to_pos: Vector2) -> float:
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var distance_before: float = abs(from_pos.x - opponent_base.x) + abs(from_pos.y - opponent_base.y)
	var distance_after: float = abs(to_pos.x - opponent_base.x) + abs(to_pos.y - opponent_base.y)
	return (distance_before - distance_after) * SCORE_SEEKER_BASE_PROGRESS

func score_seeker_base_entry_threat(game_state: GameStateData, player_id: int, piece_pos: Vector2, stamp: Stamp, board_size: int) -> float:
	if game_state == null or !MoveRules.is_seeker_stamp(stamp):
		return 0.0

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var seeker_moves: Array[Vector2] = MoveRules.get_stamp_moves_for_piece(
		game_state.pieces,
		piece_pos,
		player_color,
		stamp,
		board_size,
		game_state.board_effects
	)
	if seeker_moves.has(opponent_base):
		return SCORE_SEEKER_BASE_ENTRY_THREAT
	return 0.0

func score_base_staging_capture(game_state: GameStateData, player_id: int, captured_piece: Piece, captured_pos: Vector2, board_size: int) -> float:
	if game_state == null or captured_piece == null or captured_piece.attached_stamp != null:
		return 0.0

	var opponent_player_id: int = 1 - player_id
	if StampEffectResolver.get_player_id_for_color(captured_piece.color) != opponent_player_id:
		return 0.0
	if !player_has_seeker_base_entry_from_hand(game_state, opponent_player_id, captured_pos, board_size):
		return 0.0
	return SCORE_CAPTURE_BASE_STAGING_PIECE

func player_has_seeker_base_entry_from_hand(game_state: GameStateData, player_id: int, piece_pos: Vector2, board_size: int) -> bool:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var hand_stamps: Array[Stamp] = AIStateSimulator.get_hand_stamps_from_state(game_state, player_id)
	for stamp: Stamp in hand_stamps:
		if !MoveRules.is_seeker_stamp(stamp):
			continue
		var seeker_moves: Array[Vector2] = MoveRules.get_stamp_moves_for_piece(
			game_state.pieces,
			piece_pos,
			player_color,
			stamp,
			board_size,
			game_state.board_effects
		)
		if seeker_moves.has(opponent_base):
			return true
	return false

func score_center_control(pos: Vector2, board_size: int) -> float:
	var center: Vector2 = Vector2(float(board_size - 1) / 2.0, float(board_size - 1) / 2.0)
	var distance: float = abs(pos.x - center.x) + abs(pos.y - center.y)
	return max(0.0, float(board_size) - distance) * SCORE_CENTER

func score_seeker_threat(game_state: GameStateData, player_id: int, move: Dictionary, board_size: int) -> float:
	var simulated_pieces: Dictionary = AIStateSimulator.apply_candidate_to_pieces(game_state.pieces, move)
	var moved_to: Vector2 = AIStateSimulator.get_move_to(move)
	var opponent_seeker_pos: Vector2 = AIStateSimulator.find_seeker_position(simulated_pieces, 1 - player_id)
	if opponent_seeker_pos == Vector2(-1, -1):
		return 0.0

	var next_moves: Array[Vector2] = MoveRules.get_piece_moves_for_player(
		simulated_pieces,
		moved_to,
		player_id,
		board_size,
		game_state.board_effects
	)
	if next_moves.has(opponent_seeker_pos):
		return SCORE_THREATEN_SEEKER
	return 0.0

func score_danger_after_move(game_state: GameStateData, player_id: int, move: Dictionary, board_size: int) -> float:
	var simulated_pieces: Dictionary = AIStateSimulator.apply_candidate_to_pieces(game_state.pieces, move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var opponent_player_id: int = 1 - player_id
	var opponent_hand_stamps: Array[Stamp] = AIStateSimulator.get_hand_stamps_from_state(game_state, opponent_player_id)
	var is_threatened: bool = AIStateSimulator.is_square_threatened(
		simulated_pieces,
		to_pos,
		opponent_player_id,
		opponent_hand_stamps,
		game_state.board_effects,
		board_size
	)
	if !is_threatened:
		return 0.0

	var threatened_piece: Piece = simulated_pieces.get(to_pos, null) as Piece
	return score_threatened_piece_loss(threatened_piece)

func score_attachment_danger(
	game_state: GameStateData,
	player_id: int,
	attach_action: Dictionary,
	board_size: int,
	simulate_effects: bool
) -> float:
	if game_state == null:
		return 0.0

	var piece_pos: Vector2 = StampEffectResolver.as_vector2(attach_action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
	var stamp: Stamp = attach_action.get("stamp", null) as Stamp
	if stamp == null:
		stamp = StampLibrary.get_stamp(str(attach_action.get("stamp_name", "")))
	if stamp == null:
		return 0.0

	var simulated_state: GameStateData = null
	var simulated_pieces: Dictionary = {}
	var simulated_board_effects: Array = []
	var attached_piece: Piece = null
	if simulate_effects:
		simulated_state = AIStateSimulator.clone_game_state(game_state)
		AIStateSimulator.apply_attach_action(simulated_state, player_id, attach_action, board_size)
		if simulated_state.game_over:
			if simulated_state.winner_player == player_id:
				return 0.0
			return SCORE_WIN
		simulated_pieces = simulated_state.pieces
		simulated_board_effects = simulated_state.board_effects
		attached_piece = simulated_state.get_piece(piece_pos)
	else:
		simulated_pieces = AIStateSimulator.clone_pieces(game_state.pieces)
		simulated_board_effects = game_state.board_effects
		attached_piece = simulated_pieces.get(piece_pos, null) as Piece
		if attached_piece != null:
			attached_piece.attached_stamp = stamp
			attached_piece.turns_remaining = stamp.duration
			attached_piece.exhausted_this_turn = true

	if attached_piece == null or attached_piece.attached_stamp == null:
		return 0.0

	var opponent_player_id: int = 1 - player_id
	var threat_state: GameStateData = game_state
	if simulated_state != null:
		threat_state = simulated_state
	var opponent_hand_stamps: Array[Stamp] = AIStateSimulator.get_hand_stamps_from_state(threat_state, opponent_player_id)
	if !AIStateSimulator.is_square_threatened(
		simulated_pieces,
		piece_pos,
		opponent_player_id,
		opponent_hand_stamps,
		simulated_board_effects,
		board_size
	):
		return 0.0

	return score_threatened_piece_loss(attached_piece)

func score_threatened_piece_loss(piece: Piece) -> float:
	if piece == null:
		return 0.0
	if StampEffectResolver.is_seeker_piece(piece):
		return PENALTY_SEEKER_THREATENED
	return maxf(PENALTY_PIECE_THREATENED, score_capture(piece))

func score_stamp_effect(
	game_state: GameStateData,
	player_id: int,
	moving_piece: Piece,
	stamp: Stamp,
	from_pos: Vector2,
	to_pos: Vector2,
	captured_piece: Piece,
	move: Dictionary,
	board_size: int
) -> float:
	if stamp == null or !stamp.has_effect():
		return 0.0

	var score: float = 0.0
	var effect_source_pos: Vector2 = get_effect_source_pos(stamp, from_pos, to_pos)
	match stamp.effect_type:
		StampEffect.TYPE_SHARED_CONTROL:
			score += score_shared_control_effect(game_state, player_id, stamp, move, to_pos, board_size)
		StampEffect.TYPE_INVISIBLE_TO_ENEMY:
			score += 32.0
			if MoveRules.is_seeker_stamp(stamp):
				score += 80.0
		StampEffect.TYPE_STEAL_STAMP:
			score += 50.0
		StampEffect.TYPE_GRANT_STAMP:
			score += score_grant_stamp_effect(game_state, player_id, stamp)
		StampEffect.TYPE_GIVE_STAMP:
			score -= PENALTY_GIVE_STAMP
		StampEffect.TYPE_MOVE_BASE:
			score += score_move_base_effect(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
		StampEffect.TYPE_INVALID_SQUARES:
			score += score_invalid_squares_effect(game_state, player_id, stamp, move, effect_source_pos, board_size)
		StampEffect.TYPE_FROZEN_SQUARES:
			score += score_frozen_squares_effect(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
		StampEffect.TYPE_BOMB:
			score += score_bomb_effect(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
		StampEffect.TYPE_UNCAPTURABLE:
			score += score_uncapturable_effect(stamp)
		StampEffect.TYPE_INCREASE_OWN_DURATIONS:
			score += score_duration_adjustment_effect(game_state, player_id, player_id, 1)
		StampEffect.TYPE_INCREASE_ENEMY_DURATIONS:
			score += score_duration_adjustment_effect(game_state, player_id, 1 - player_id, 1)
		StampEffect.TYPE_DECREASE_OWN_DURATIONS:
			score += score_duration_adjustment_effect(game_state, player_id, player_id, -1)
		StampEffect.TYPE_DECREASE_ENEMY_DURATIONS:
			score += score_duration_adjustment_effect(game_state, player_id, 1 - player_id, -1)
		StampEffect.TYPE_INCREASE_SELF_DURATION:
			score += 18.0
		_:
			pass

	if stamp.effect_trigger == StampEffect.TRIGGER_ON_CAPTURE && captured_piece != null:
		score += 20.0
	if stamp.effect_trigger == StampEffect.TRIGGER_ON_MOVE:
		score += 8.0
	if stamp.effect_trigger == StampEffect.TRIGGER_ON_EXPIRE:
		score += 5.0
	if to_pos == from_pos:
		score -= 10.0

	return score

func score_bomb_effect(game_state: GameStateData, player_id: int, moving_piece: Piece, stamp: Stamp, source_pos: Vector2, board_size: int) -> float:
	if moving_piece == null:
		return 0.0

	var score: float = 0.0
	var effect_color: int = moving_piece.color
	for offset: Vector2 in stamp.get_effect_offsets():
		var target_pos: Vector2 = source_pos + (offset * effect_color)
		if !MoveRules.is_valid_position(target_pos, board_size):
			continue

		var target_piece: Piece = game_state.get_piece(target_pos)
		if target_piece == null:
			continue

		var target_player_id: int = StampEffectResolver.get_player_id_for_color(target_piece.color)
		var target_score: float = SCORE_CAPTURE_PIECE
		if StampEffectResolver.is_seeker_piece(target_piece):
			target_score = SCORE_CAPTURE_SEEKER
		elif target_piece.attached_stamp != null:
			target_score += SCORE_CAPTURE_STAMP

		if target_player_id == player_id:
			score -= target_score
		else:
			score += target_score

	return score

func score_frozen_squares_effect(game_state: GameStateData, player_id: int, moving_piece: Piece, stamp: Stamp, source_pos: Vector2, board_size: int) -> float:
	if moving_piece == null:
		return 0.0

	var score: float = 0.0
	var effect_color: int = moving_piece.color
	var target_squares: Array[Vector2] = StampEffectResolver.get_effect_squares(stamp, source_pos, board_size, effect_color)
	for target_pos: Vector2 in target_squares:
		var target_piece: Piece = game_state.get_piece(target_pos)
		if target_piece == null:
			continue

		var target_player_id: int = StampEffectResolver.get_player_id_for_color(target_piece.color)
		if !stamp_effect_targets_player(stamp, target_player_id):
			continue

		var piece_score: float = get_frozen_piece_score(game_state, target_piece, target_pos, target_player_id, board_size)
		if target_player_id == player_id:
			score -= piece_score
		else:
			score += piece_score

	return score

func score_invalid_squares_effect(game_state: GameStateData, player_id: int, stamp: Stamp, move: Dictionary, source_pos: Vector2, board_size: int) -> float:
	var moving_piece: Piece = game_state.get_piece(AIStateSimulator.get_move_from(move))
	if moving_piece == null:
		return 0.0

	var effect_color: int = moving_piece.color
	var target_squares: Array[Vector2] = StampEffectResolver.get_effect_squares(stamp, source_pos, board_size, effect_color)
	target_squares = StampEffectResolver.filter_out_base_fields(game_state, target_squares)
	if target_squares.is_empty():
		return 0.0

	var simulated_pieces: Dictionary = AIStateSimulator.apply_candidate_to_pieces(game_state.pieces, move)
	var opponent_player_id: int = 1 - player_id
	var board_effects_with_invalid: Array = game_state.board_effects.duplicate()
	board_effects_with_invalid.append({
		"effect_type": StampEffect.TYPE_INVALID_SQUARES,
		"owner_player_id": player_id,
		"target_player_id": int(stamp.effect_settings.get("target_player_id", -1)),
		"squares": target_squares,
		"turns_remaining": max(1, int(stamp.effect_settings.get("turns_remaining", stamp.duration))),
	})

	var opponent_moves_before: int = count_valid_turn_moves_for_player(game_state, simulated_pieces, opponent_player_id, game_state.board_effects, board_size)
	var opponent_moves_after: int = count_valid_turn_moves_for_player(game_state, simulated_pieces, opponent_player_id, board_effects_with_invalid, board_size)
	var opponent_reduced_moves: int = max(0, opponent_moves_before - opponent_moves_after)

	var own_moves_before: int = count_valid_turn_moves_for_player(game_state, simulated_pieces, player_id, game_state.board_effects, board_size)
	var own_moves_after: int = count_valid_turn_moves_for_player(game_state, simulated_pieces, player_id, board_effects_with_invalid, board_size)
	var own_reduced_moves: int = max(0, own_moves_before - own_moves_after)

	return float(opponent_reduced_moves) * SCORE_INVALID_MOVE_REDUCTION - float(own_reduced_moves) * PENALTY_OWN_MOVE_REDUCTION

func score_move_base_effect(game_state: GameStateData, player_id: int, moving_piece: Piece, stamp: Stamp, source_pos: Vector2, board_size: int) -> float:
	if moving_piece == null:
		return 0.0

	var raw_target_squares: Array[Vector2] = StampEffectResolver.get_effect_squares_unfiltered(stamp, source_pos, moving_piece.color)
	if raw_target_squares.is_empty():
		return -PENALTY_MOVE_BASE_NOOP

	var new_base_pos: Vector2 = raw_target_squares[0]
	if !MoveRules.is_valid_position(new_base_pos, board_size):
		return -PENALTY_MOVE_BASE_NOOP
	if StampEffectResolver.is_base_field_for_other_player(game_state, new_base_pos, player_id):
		return -PENALTY_MOVE_BASE_NOOP

	var current_base_pos: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, player_id)
	var opponent_positions: Array[Vector2] = get_piece_positions_for_player(game_state.pieces, 1 - player_id)
	if opponent_positions.is_empty():
		return 0.0

	var min_distance_before: float = get_min_distance_to_positions(current_base_pos, opponent_positions)
	var min_distance_after: float = get_min_distance_to_positions(new_base_pos, opponent_positions)
	var avg_distance_before: float = get_average_distance_to_positions(current_base_pos, opponent_positions)
	var avg_distance_after: float = get_average_distance_to_positions(new_base_pos, opponent_positions)
	return (min_distance_after - min_distance_before) * SCORE_MOVE_BASE_MIN_DISTANCE \
		+ (avg_distance_after - avg_distance_before) * SCORE_MOVE_BASE_AVG_DISTANCE

func score_shared_control_effect(game_state: GameStateData, player_id: int, stamp: Stamp, move: Dictionary, piece_pos_after_move: Vector2, board_size: int) -> float:
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
		if target_piece != null && StampEffectResolver.get_player_id_for_color(target_piece.color) != player_id:
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
		if immediate_target != null && StampEffectResolver.get_player_id_for_color(immediate_target.color) == player_id:
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
			if future_target != null && StampEffectResolver.get_player_id_for_color(future_target.color) == player_id:
				score -= get_piece_target_score(future_target) * PENALTY_SHARED_FUTURE_THREAT_MULTIPLIER

	return score

func get_effect_source_pos(stamp: Stamp, from_pos: Vector2, to_pos: Vector2) -> Vector2:
	if stamp.effect_trigger == StampEffect.TRIGGER_ON_MOVE \
		or stamp.effect_trigger == StampEffect.TRIGGER_ON_CAPTURE \
		or stamp.effect_trigger == StampEffect.TRIGGER_ON_EXPIRE:
		return to_pos
	return from_pos

func get_frozen_piece_score(game_state: GameStateData, piece: Piece, piece_pos: Vector2, target_player_id: int, board_size: int) -> float:
	var score: float = SCORE_FROZEN_ENEMY_PIECE
	if StampEffectResolver.is_seeker_piece(piece):
		score += SCORE_CAPTURE_SEEKER * 0.65
	elif piece.attached_stamp != null:
		score += SCORE_CAPTURE_STAMP * 0.45
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

func stamp_effect_targets_player(stamp: Stamp, target_player_id: int) -> bool:
	var effect_target_player_id: int = int(stamp.effect_settings.get("target_player_id", -1))
	return effect_target_player_id == -1 || effect_target_player_id == target_player_id

func score_uncapturable_effect(stamp: Stamp) -> float:
	var score: float = 46.0
	if MoveRules.is_seeker_stamp(stamp):
		score += 120.0
	return score

func score_duration_adjustment_effect(game_state: GameStateData, player_id: int, target_player_id: int, delta: int) -> float:
	var target_color: int = StampEffectResolver.get_color_for_player_id(target_player_id)
	var target_is_own: bool = target_player_id == player_id
	var score: float = 0.0
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != target_color or piece.attached_stamp == null or piece.turns_remaining <= 0:
			continue

		var piece_value: float = 16.0 + float(piece.turns_remaining) * 2.0
		if StampEffectResolver.is_seeker_piece(piece):
			piece_value += 110.0

		if delta > 0:
			if target_is_own:
				score += piece_value
			else:
				score -= piece_value
		else:
			if target_is_own:
				score -= piece_value
			else:
				score += piece_value
	return score

func count_valid_turn_moves_for_player(game_state: GameStateData, pieces: Dictionary, player_id: int, board_effects: Array, board_size: int) -> int:
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

func get_piece_positions_for_player(pieces: Dictionary, player_id: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	for position_value in pieces:
		var position: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
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
	return score_capture(piece)

func get_stamp_balance_value(stamp: Stamp) -> float:
	if stamp == null:
		return 0.0
	return StampBalanceStore.get_stamp_value(stamp.stamp_name, 0.0)
