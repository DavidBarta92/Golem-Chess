extends RefCounted
class_name AIMoveEvaluator

## The AI's choice of a turn. It ranks the planner's turn plans by their score
## (AIPlanScoring and the modules under it, in Scripts/AIScoring/), weighs the
## opponent's best reply, and at the top levels searches two turns deeper (the
## deep pass, on worker threads). It holds the difficulty knobs and the search's
## caches, and builds its own set of scoring modules: a worker evaluator has its
## own, so no two threads share a cache.

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
		"tactical_defense_awareness": 0.35,
		"aggression": 0.85,
	},
	2: {
		"search_depth": 1,
		"own_top_n": 2,
		"opponent_top_n": 0,
		"randomness": 35.0,
		"opponent_response_weight": 0.0,
		"tactical_defense_awareness": 0.45,
		"aggression": 0.85,
	},
	3: {
		"search_depth": 1,
		"own_top_n": 3,
		"opponent_top_n": 0,
		"randomness": 28.0,
		"opponent_response_weight": 0.0,
		"tactical_defense_awareness": 0.55,
		"aggression": 0.8,
	},
	4: {
		"search_depth": 1,
		"own_top_n": 4,
		"opponent_top_n": 0,
		"randomness": 20.0,
		"opponent_response_weight": 0.0,
		"tactical_defense_awareness": 0.65,
		"aggression": 0.8,
	},
	5: {
		"search_depth": 2,
		"own_top_n": 5,
		"opponent_top_n": 2,
		"randomness": 15.0,
		"opponent_response_weight": 0.35,
		"tactical_defense_awareness": 0.75,
		"aggression": 0.75,
	},
	6: {
		"search_depth": 2,
		"own_top_n": 6,
		"opponent_top_n": 4,
		"randomness": 10.0,
		"opponent_response_weight": 0.50,
		"tactical_defense_awareness": 0.85,
		"aggression": 0.7,
	},
	7: {
		"search_depth": 2,
		"own_top_n": 7,
		"opponent_top_n": 6,
		"randomness": 6.0,
		"opponent_response_weight": 0.58,
		"tactical_defense_awareness": 0.90,
		"aggression": 0.65,
	},
	8: {
		"search_depth": 2,
		"own_top_n": 8,
		"opponent_top_n": 8,
		"randomness": 4.0,
		"opponent_response_weight": 0.64,
		"tactical_defense_awareness": 0.95,
		"aggression": 0.6,
	},
	9: {
		"search_depth": 2,
		"own_top_n": 9,
		"opponent_top_n": 10,
		"randomness": 2.0,
		"opponent_response_weight": 0.70,
		"tactical_defense_awareness": 1.0,
		"aggression": 0.55,
	},
	10: {
		"search_depth": 2,
		"own_top_n": 8,
		"opponent_top_n": 6,
		"randomness": 1.0,
		"opponent_response_weight": 0.76,
		"tactical_defense_awareness": 1.0,
		"aggression": 0.55,
	},
	11: {
		"search_depth": 4,
		"own_top_n": 8,
		"opponent_top_n": 6,
		"randomness": 0.0,
		"opponent_response_weight": 0.80,
		"tactical_defense_awareness": 1.0,
		"aggression": 0.55,
		"deep_search_ms": 4000,
	},
	12: {
		"search_depth": 4,
		"own_top_n": 9,
		"opponent_top_n": 7,
		"randomness": 0.0,
		"opponent_response_weight": 0.82,
		"tactical_defense_awareness": 1.0,
		"aggression": 0.55,
		"deep_search_ms": 7000,
	},
}
const DEFAULT_OPPONENT_RESPONSE_WEIGHT: float = 0.62
const DEEP_ROOT_BEAM_WIDTH: int = 4
const DEEP_OPPONENT_FIRST_BEAM_WIDTH: int = 4
const DEEP_OWN_SECOND_BEAM_WIDTH: int = 2
const DEEP_OPPONENT_SECOND_BEAM_WIDTH: int = 2
const DEEP_SECOND_OWN_WEIGHT: float = 0.72
const DEEP_SECOND_OPPONENT_WEIGHT: float = 0.62
## The deep pass may use at most this share of the AI's remaining match clock,
## so a long think can never be what loses the game on time.
const DEEP_SEARCH_CLOCK_SHARE: float = 1.0 / 30.0
const ROOT_FULL_SCORE_LIMIT: int = 48
const RESPONSE_FULL_SCORE_LIMIT: int = 24
const PARALLEL_FAST_SCORE_MIN_PLAN_COUNT: int = 12
const SCORE_WIN: float = AIScoringContext.SCORE_WIN

var difficulty_level: int = DEFAULT_DIFFICULTY_LEVEL
var search_depth: int = 1
var own_top_n: int = 6
var opponent_top_n: int = 4
var randomness: float = 8.0
var opponent_response_weight: float = DEFAULT_OPPONENT_RESPONSE_WEIGHT
var tactical_defense_awareness: float = 1.0
## How readily the AI goes for the base (AIScoringContext.aggression).
## The scoring reads it from the context, so it is kept there.
var aggression: float:
	get:
		return context.aggression
	set(value):
		context.aggression = value
## Not part of the difficulty level: a story boss can be set to guard its base
## worse than its level does (BossDefinition.ai_defense). See begin_decision.
var defense_scale: float = 1.0
## Whether the AI looks at the opponent's threats this turn (see begin_decision).
## The scoring reads it from the context, so it is kept there.
var sees_threats_this_turn: bool:
	get:
		return context.sees_threats_this_turn
	set(value):
		context.sees_threats_this_turn = value
var deep_search_ms: int = 0
## Set only on the worker evaluators of the deep pass (see
## choose_deep_beam_plan); 0 means no limit.
var search_deadline_usec: int = 0
var last_profile: Dictionary = {}
var fast_score_cache: Dictionary = {}
var full_score_cache: Dictionary = {}
var response_score_cache: Dictionary = {}
## The strategy mode and what it knows (AIStrategyDirector), set by set_strategy_context.
## The scoring reads it from the context, so it is kept there.
var strategy_context: Dictionary:
	get:
		return context.strategy_context
	set(value):
		context.strategy_context = value
## The scoring modules, built with the evaluator (see _init).
var context: AIScoringContext = AIScoringContext.new()
var reach: AIReach
var se_tenant_scoring: AISeTenantScoring
var effect_scoring: AIEffectScoring
var crown_race: AICrownRace
var move_scoring: AIMoveScoring
var strategy_scoring: AIStrategyScoring
var plan_scoring: AIPlanScoring

func _init(new_difficulty_level = DEFAULT_DIFFICULTY_LEVEL):
	reach = AIReach.new(context)
	se_tenant_scoring = AISeTenantScoring.new(context, reach)
	effect_scoring = AIEffectScoring.new(context, se_tenant_scoring)
	crown_race = AICrownRace.new(context, reach, se_tenant_scoring, effect_scoring)
	move_scoring = AIMoveScoring.new(context, reach, se_tenant_scoring, effect_scoring, crown_race)
	strategy_scoring = AIStrategyScoring.new(context, reach, effect_scoring, crown_race, move_scoring)
	plan_scoring = AIPlanScoring.new(context, se_tenant_scoring, effect_scoring, crown_race, move_scoring, strategy_scoring)
	set_difficulty_level(new_difficulty_level)
	AIStampValues.prepare_stamp_values()

func set_difficulty_level(new_difficulty_level) -> void:
	difficulty_level = parse_difficulty_level(new_difficulty_level)
	apply_difficulty_config(difficulty_level)

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
	tactical_defense_awareness = float(config.get("tactical_defense_awareness", 1.0))
	aggression = float(config.get("aggression", 0.5))
	deep_search_ms = int(config.get("deep_search_ms", 0))

## Rolled once per turn, before the AI looks at its options: on a turn it does
## not see the opponent's threats, it neither takes the defensive shortcuts nor
## scores the enemy's side of the crown race, nor reads the opponent's
## replies - it plays as if its base were not under attack. Always
## sees them at the default defense_scale of 1.0.
func begin_decision() -> void:
	sees_threats_this_turn = defense_scale >= 1.0 or randf() < defense_scale

func should_notice_defensive_tactics() -> bool:
	# Guards the defensive forced-tactical shortcuts (AITacticalSearch) - immediate base defense
	# and staging-capture - which have no equivalent recognition in the normal
	# fast-prefilter scoring pass (AIPlanScoring.score_turn_plan_fast never sees the huge hard-rule bonuses
	# from AIPlanScoring.score_hard_tactical_rules_for_plan, only the full scorer does). Skipping this check is
	# what lets low difficulty realistically miss "if I don't respond now, I lose next turn" -
	# the same blind spot a beginner has - instead of just being a slower version of perfect play.
	# The "immediate win" shortcut is intentionally NOT gated by this: an unblocked winning move
	# is something the normal scorer already reliably finds on its own (AIMoveScoring.score_move_fast awards
	# it SCORE_WIN directly), so hiding it here would only slow the AI down, not make it weaker.
	# Nor is the AI's own two-turn threat: a weak AI should defend badly, not attack timidly.
	if tactical_defense_awareness >= 1.0:
		return true
	return randf() < tactical_defense_awareness

func choose_best_move(game_state: GameStateData, player_id: int, valid_moves: Array[Dictionary], board_size: int = BoardConfig.BOARD_SIZE) -> Dictionary:
	if game_state == null or valid_moves.is_empty():
		return {}

	var best_move: Dictionary = {}
	var best_score: float = -INF
	for move: Dictionary in valid_moves:
		var move_score: float = move_scoring.score_move_cached(game_state, player_id, move, board_size)
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
	var best_clean_score: float = -INF
	profile["move_response_candidate_count"] = valid_moves.size()
	for move: Dictionary in valid_moves:
		var plan: Dictionary = create_move_response_plan(player_id, move)
		var clean_move_score: float = score_turn_plan_with_response(game_state, player_id, plan, board_size, turn_planner, profile, best_clean_score)
		var move_score: float = clean_move_score
		if randomness > 0.0:
			move_score += randf_range(-randomness, randomness)

		if best_move.is_empty() or move_score > best_score:
			best_move = move
			best_score = move_score
		if clean_move_score > best_clean_score:
			best_clean_score = clean_move_score

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
		"setup_affix_actions": [],
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
		var best_clean_score: float = -INF
		var response_scored_plans: Array[Dictionary] = []
		for scored_plan: Dictionary in response_candidates:
			var plan: Dictionary = scored_plan.get("plan", {})
			var own_score: float = float(scored_plan.get("score", 0.0))
			var response_score_ceiling: float = get_opponent_response_score_ceiling(own_score, best_clean_score)
			var opponent_response_score: float = score_best_opponent_response(
				game_state,
				player_id,
				plan,
				board_size,
				turn_planner,
				profile,
				response_score_ceiling
			)
			var clean_plan_score: float = own_score - opponent_response_score * opponent_response_weight
			response_scored_plans.append({"plan": plan, "score": clean_plan_score})
			var plan_score: float = clean_plan_score
			if randomness > 0.0:
				plan_score += randf_range(-randomness, randomness)

			if best_plan.is_empty() or plan_score > best_score:
				best_plan = plan
				best_score = plan_score
			if clean_plan_score > best_clean_score:
				best_clean_score = clean_plan_score

		if should_score_deep_beam(turn_planner):
			var deep_choice: Dictionary = choose_deep_beam_plan(game_state, player_id, response_scored_plans, board_size, turn_planner, profile)
			if !deep_choice.is_empty():
				best_plan = deep_choice.get("plan", best_plan)
				best_score = float(deep_choice.get("score", best_score))

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
	var breakdown: Dictionary = plan_scoring.score_turn_plan_breakdown(game_state, player_id, best_plan, board_size)
	profile["best_plan_move_score"] = float(breakdown.get("move", 0.0))
	profile["best_plan_setup_score"] = float(breakdown.get("setup", 0.0))
	profile["best_plan_action_count_score"] = float(breakdown.get("action_count", 0.0))
	profile["best_plan_economy_score"] = float(breakdown.get("economy", 0.0))
	profile["best_plan_threat_score"] = float(breakdown.get("threat", 0.0))
	profile["best_plan_crown_score"] = float(breakdown.get("crown", 0.0))
	profile["best_plan_strategy_score"] = float(breakdown.get("strategy", 0.0))
	profile["best_plan_hard_rule_score"] = float(breakdown.get("hard_rules", 0.0))

func score_own_turn_plans(game_state: GameStateData, player_id: int, turn_plans: Array[Dictionary], board_size: int, profile: Dictionary) -> Array[Dictionary]:
	var scored_plans: Array[Dictionary] = []
	var own_score_start_usec: int = Time.get_ticks_usec()
	var fast_scored_plans: Array[Dictionary] = score_turn_plans_fast(game_state, player_id, turn_plans, board_size, profile)

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

func score_turn_plans_fast(game_state: GameStateData, player_id: int, turn_plans: Array[Dictionary], board_size: int, profile: Dictionary) -> Array[Dictionary]:
	if turn_plans.size() < PARALLEL_FAST_SCORE_MIN_PLAN_COUNT:
		return score_turn_plans_fast_sequential(game_state, player_id, turn_plans, board_size)
	return score_turn_plans_fast_parallel(game_state, player_id, turn_plans, board_size, profile)

func score_turn_plans_fast_sequential(game_state: GameStateData, player_id: int, turn_plans: Array[Dictionary], board_size: int) -> Array[Dictionary]:
	var fast_scored_plans: Array[Dictionary] = []
	for plan: Dictionary in turn_plans:
		fast_scored_plans.append({
			"plan": plan,
			"score": score_turn_plan_fast_cached(game_state, player_id, plan, board_size),
		})
	return fast_scored_plans

func score_turn_plans_fast_parallel(game_state: GameStateData, player_id: int, turn_plans: Array[Dictionary], board_size: int, profile: Dictionary) -> Array[Dictionary]:
	# Each candidate plan's fast score depends only on (game_state, player_id, plan, board_size)
	# plus read-only constants, StampLibrary lookups and the stamp value table (both populated once
	# and never mutated during play), so scoring every plan is embarrassingly parallel.
	# Each task gets its own throwaway AIMoveEvaluator (rather than `self`) purely so the cache
	# writes of its scoring modules never touch this evaluator's shared caches from multiple threads
	# at once; results are folded into fast_score_cache afterward on the calling thread, so all cache
	# writes stay single-threaded even though the scoring itself runs in parallel.
	var evaluator_script = get_script()
	var results: Array = []
	results.resize(turn_plans.size())
	var fast_score_task: Callable = func(index: int) -> void:
		var scratch_evaluator = evaluator_script.new()
		results[index] = scratch_evaluator.plan_scoring.score_turn_plan_fast(game_state, player_id, turn_plans[index], board_size)

	var task_id: int = WorkerThreadPool.add_group_task(fast_score_task, turn_plans.size())
	if task_id < 0:
		increment_profile_count(profile, "fast_score_parallel_fallback")
		return score_turn_plans_fast_sequential(game_state, player_id, turn_plans, board_size)
	WorkerThreadPool.wait_for_group_task_completion(task_id)

	var fast_scored_plans: Array[Dictionary] = []
	for index in range(turn_plans.size()):
		var plan: Dictionary = turn_plans[index]
		var score: float = float(results[index])
		var cache_key: String = "fast|%s|p%d|%s" % [context.get_state_hash(game_state), player_id, context.get_plan_hash(plan)]
		fast_score_cache[cache_key] = score
		fast_scored_plans.append({"plan": plan, "score": score})
	increment_profile_count(profile, "fast_score_parallel_batches")
	return fast_scored_plans

func get_root_full_score_limit(plan_count: int) -> int:
	return mini(maxi(own_top_n * 4, 12), mini(ROOT_FULL_SCORE_LIMIT, plan_count))

func should_score_opponent_responses(turn_planner) -> bool:
	return search_depth >= 2 \
		&& sees_threats_this_turn \
		&& turn_planner != null \
		&& opponent_response_weight > 0.0 \
		&& own_top_n > 0 \
		&& opponent_top_n > 0 \
		&& !is_safe_opening_phase()

func is_safe_opening_phase() -> bool:
	# Early game, no crown pressure on either side yet, and the opening
	# development goal not met (AIStrategyDirector only picks MODE_OPENING once every higher-
	# priority defensive/finishing mode has been ruled out - see AIStrategyDirector.gd). No
	# capture or tactical exchange is possible yet, so the expensive opponent-response lookahead
	# can't change which stamp/piece choice is best. This is this game's equivalent of an
	# "opening book" cost-reduction: since decks (and therefore starting hands) vary per match,
	# there's no fixed line to memorize, so the shortcut is a safety-gated condition rather than
	# a lookup table.
	return str(strategy_context.get("mode", "")) == AIStrategyDirector.MODE_OPENING

func should_score_deep_beam(turn_planner) -> bool:
	return search_depth >= 4 && deep_search_ms > 0 && should_score_opponent_responses(turn_planner)

func get_response_candidate_plans(scored_plans: Array[Dictionary]) -> Array[Dictionary]:
	if scored_plans.is_empty():
		var empty_scored_plans: Array[Dictionary] = []
		return empty_scored_plans
	if search_depth < 2 or own_top_n <= 0:
		var empty_candidate_plans: Array[Dictionary] = []
		return empty_candidate_plans
	return get_top_scored_plans(scored_plans, own_top_n)

## Second pass on top of the two-turn lookahead: the best few plans by that
## score are searched two full turns deeper (score_deep_beam_turn_plan) and the
## best of them wins. The pass runs against a time budget, and one that runs out
## is thrown away whole, because a plan searched deeper and one that was not are
## not comparable; the two-turn choice then stands.
##
## The roots are independent, so each is searched on its own worker thread with
## its own evaluator and planner (the same reasoning as in
## score_turn_plans_fast_parallel: their caches are never shared between threads,
## and game_state is only read).
func choose_deep_beam_plan(
	game_state: GameStateData,
	player_id: int,
	response_scored_plans: Array[Dictionary],
	board_size: int,
	turn_planner,
	profile: Dictionary
) -> Dictionary:
	var budget_usec: int = get_deep_search_budget_usec(game_state, player_id)
	if budget_usec <= 0 or response_scored_plans.is_empty():
		return {}

	var start_usec: int = Time.get_ticks_usec()
	var deadline_usec: int = start_usec + budget_usec
	var roots: Array[Dictionary] = []
	for scored_plan: Dictionary in get_top_scored_plans(response_scored_plans, DEEP_ROOT_BEAM_WIDTH):
		var plan: Dictionary = scored_plan.get("plan", {})
		roots.append({
			"plan": plan,
			"own_score": score_turn_plan_cached(game_state, player_id, plan, board_size),
		})

	var results: Array = []
	results.resize(roots.size())
	var planner_script = turn_planner.get_script()
	var root_search_task: Callable = func(index: int) -> void:
		var worker_evaluator = create_search_worker(deadline_usec)
		var worker_planner = planner_script.new()
		worker_planner.planning_evaluator = worker_evaluator
		var root: Dictionary = roots[index]
		var plan: Dictionary = root.get("plan", {})
		var deep_score: float = worker_evaluator.score_deep_beam_turn_plan(game_state, player_id, plan, float(root.get("own_score", 0.0)), board_size, worker_planner, {})
		results[index] = {
			"plan": plan,
			"score": deep_score,
			"timed_out": worker_evaluator.is_search_out_of_time(),
		}

	var task_id: int = WorkerThreadPool.add_group_task(root_search_task, roots.size())
	if task_id < 0:
		for index in range(roots.size()):
			root_search_task.call(index)
	else:
		WorkerThreadPool.wait_for_group_task_completion(task_id)

	var best_choice: Dictionary = {}
	for result in results:
		if !(result is Dictionary) or bool(result.get("timed_out", true)):
			best_choice = {}
			break
		if best_choice.is_empty() or float(result.get("score", -INF)) > float(best_choice.get("score", -INF)):
			best_choice = result

	profile["deep_search_ms"] = usec_to_ms(Time.get_ticks_usec() - start_usec)
	profile["deep_search_completed"] = !best_choice.is_empty()
	return best_choice

func create_search_worker(deadline_usec: int):
	var worker = get_script().new(difficulty_level)
	worker.set_strategy_context(strategy_context)
	worker.defense_scale = defense_scale
	worker.sees_threats_this_turn = sees_threats_this_turn
	worker.search_deadline_usec = deadline_usec
	return worker

func get_deep_search_budget_usec(game_state: GameStateData, player_id: int) -> int:
	var budget_ms: float = float(deep_search_ms)
	if game_state != null and game_state.player_clock_seconds.has(player_id):
		var clock_ms: float = float(game_state.player_clock_seconds[player_id]) * 1000.0
		budget_ms = minf(budget_ms, clock_ms * DEEP_SEARCH_CLOCK_SHARE)
	return int(maxf(budget_ms, 0.0) * 1000.0)

func is_search_out_of_time() -> bool:
	return search_deadline_usec > 0 and Time.get_ticks_usec() >= search_deadline_usec

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

func score_turn_plan_with_response(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int = BoardConfig.BOARD_SIZE, turn_planner = null, profile: Dictionary = {}, known_best_clean_score: float = -INF) -> float:
	var own_score_start_usec: int = Time.get_ticks_usec()
	var own_score: float = score_turn_plan_cached(game_state, player_id, plan, board_size)
	add_profile_time(profile, "evaluator_ms", Time.get_ticks_usec() - own_score_start_usec)
	increment_profile_count(profile, "evaluated_own_plans")
	if !should_score_opponent_responses(turn_planner):
		return own_score

	var response_score_ceiling: float = get_opponent_response_score_ceiling(own_score, known_best_clean_score)
	var opponent_response_score: float = score_best_opponent_response(game_state, player_id, plan, board_size, turn_planner, profile, response_score_ceiling)
	return own_score - opponent_response_score * opponent_response_weight

func get_opponent_response_score_ceiling(own_score: float, known_best_clean_score: float) -> float:
	# Alpha-beta bound: plan_score = own_score - weight * opponent_response_score, and
	# opponent_response_score only ever grows as score_best_opponent_response examines more
	# candidates, so plan_score can only fall from here. Once it can no longer beat the best
	# clean (non-jittered) score found so far, the inner search can stop early without changing
	# which plan ultimately wins.
	if opponent_response_weight <= 0.0 or known_best_clean_score == -INF:
		return INF
	return (own_score - known_best_clean_score) / opponent_response_weight

func score_best_opponent_response(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int, turn_planner, profile: Dictionary = {}, response_score_ceiling: float = INF) -> float:
	var response_cache_key: String = "response|%s|p%d|%s" % [context.get_state_hash(game_state), player_id, context.get_plan_hash(plan)]
	if response_score_cache.has(response_cache_key):
		increment_profile_count(profile, "response_cache_hits")
		return float(response_score_cache[response_cache_key])

	var simulator_start_usec: int = Time.get_ticks_usec()
	var simulated_state: GameStateData = context.get_simulated_turn_plan_state(game_state, player_id, plan, board_size)
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
	var alpha_beta_cutoff: bool = false
	var evaluated_response_count: int = 0
	for opponent_plan: Dictionary in ordered_response_plans:
		var response_score: float = score_turn_plan_cached(simulated_state, opponent_player_id, opponent_plan, board_size)
		evaluated_response_count += 1
		if response_score > best_response_score:
			best_response_score = response_score
		if best_response_score >= response_score_ceiling:
			alpha_beta_cutoff = true
			increment_profile_count(profile, "opponent_response_alpha_beta_cutoffs")
			break
	add_profile_time(profile, "evaluator_ms", Time.get_ticks_usec() - response_eval_start_usec)
	increment_profile_count(profile, "evaluated_response_plans", evaluated_response_count)

	var final_response_score: float = best_response_score if best_response_score != -INF else 0.0
	# A cutoff result is only a lower bound on the true best opponent response, not the exact
	# value, so it must not be cached as if it were - a later query without a tight ceiling
	# (e.g. a different decision) would otherwise silently read a too-optimistic score.
	if !alpha_beta_cutoff:
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
		return own_score + context.get_terminal_score_for_player(state_after_first_plan, player_id)

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
		if is_search_out_of_time():
			break
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
		return context.get_terminal_score_for_player(state_after_opponent, player_id)

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
		if is_search_out_of_time():
			break
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
		return context.get_terminal_score_for_player(state_after_own_second, player_id)

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
	move_scoring.move_score_cache.clear()
	response_score_cache.clear()
	context.simulated_state_cache.clear()
	crown_race.crown_race_value_cache.clear()
	se_tenant_scoring.se_tenant_sources_cache.clear()
	# context.stamp_cache (keyed by stamp name only), reach.base_route_cache
	# (keyed by stamp/side/base occupant, see AIReach.get_base_route_map) and
	# reach.capture_reach_cache (stamp/side/square, see
	# AIReach.get_capture_reach_map) stay valid across decisions as long as
	# the evaluator instance itself persists, so clearing them here would only
	# force pointless recomputation.

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
	var cache_key: String = "fast|%s|p%d|%s" % [context.get_state_hash(game_state), player_id, context.get_plan_hash(plan)]
	if fast_score_cache.has(cache_key):
		return float(fast_score_cache[cache_key])

	var score: float = plan_scoring.score_turn_plan_fast(game_state, player_id, plan, board_size)
	fast_score_cache[cache_key] = score
	return score

func score_turn_plan_cached(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int = BoardConfig.BOARD_SIZE) -> float:
	var cache_key: String = "full|%s|p%d|%s" % [context.get_state_hash(game_state), player_id, context.get_plan_hash(plan)]
	if full_score_cache.has(cache_key):
		return float(full_score_cache[cache_key])

	var score: float = plan_scoring.score_turn_plan(game_state, player_id, plan, board_size)
	full_score_cache[cache_key] = score
	return score

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
