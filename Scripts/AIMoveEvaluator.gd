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

const SCORE_WIN: float = 100000.0
const SCORE_CAPTURE_BASE_STAGING_PIECE: float = 180.0
const SCORE_CAPTURE_PIECE: float = 45.0
## The flat part of a captured stamp's value; the rest is the part of its
## estimate still ahead of it (score_stamp_material).
const SCORE_CAPTURE_STAMP: float = 10.0
const SCORE_AFFIX_STAMP: float = 10.0
const SCORE_CENTER: float = 4.0
const SCORE_USE_EXISTING_STAMP: float = 4.0
const SCORE_AFFIX_SETUP_MOBILITY: float = 5.0
const PENALTY_AFFIX_SETUP_NO_MOVE: float = 8.0
## A stamp glued into a codex by an effect, or taken from one, on top of how
## much better it is than the average stamp (score_grant_stamp_effect,
## score_give_stamp_effect).
const SCORE_CODEX_STAMP: float = 45.0
const SCORE_INVALID_MOVE_REDUCTION: float = 8.0
const PENALTY_OWN_MOVE_REDUCTION: float = 5.0
const SCORE_FROZEN_ENEMY_PIECE: float = 34.0
const PENALTY_FROZEN_OWN_PIECE: float = 38.0
const SCORE_MOVE_BASE_MIN_DISTANCE: float = 24.0
const SCORE_MOVE_BASE_AVG_DISTANCE: float = 8.0
const PENALTY_MOVE_BASE_NOOP: float = 20.0
const PENALTY_PIECE_THREATENED: float = 35.0
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
const STAMP_VALUE_AFFIX_PLAY_WEIGHT: float = 0.35
const STAMP_VALUE_AFFIX_EXCHANGE_WEIGHT: float = 0.6
## Score points per stamp estimate point (Stamp.estimated_value's scale). At 5
## a captured fresh stamp is worth about what the flat 75 + 8 a turn was on
## average, but no longer the same for every stamp.
const STAMP_ESTIMATE_POINT_SCORE: float = 5.0
## A captured Seeker goes back to its owner's codex: only this share is lost.
const SEEKER_CAPTURE_VALUE_SHARE: float = 0.5
const ROOT_FULL_SCORE_LIMIT: int = 48
const RESPONSE_FULL_SCORE_LIMIT: int = 24
const PARALLEL_FAST_SCORE_MIN_PLAN_COUNT: int = 12
const HAND_DECK_ECONOMY_WEIGHT: float = 0.18
const SCORE_TWO_TURN_BASE_THREAT: float = 260.0
const SCORE_FORCE_DEFENSE: float = 120.0
const SCORE_THREAT_MAP_OWN_ATTACK: float = 14.0
const PENALTY_THREAT_MAP_EXPOSURE: float = 18.0
const SCORE_HAND_SYNERGY: float = 18.0
const PENALTY_REPEAT_LAST_MOVE: float = 170.0
const SCORE_OPENING_CENTER_ENTRY: float = 130.0
const SCORE_OPENING_CENTER_COUNT: float = 46.0
const SCORE_OPENING_COMPLETED: float = 180.0
const SCORE_DEFENSE_THREAT_REDUCTION: float = 120.0
const SCORE_DEFENSE_BASE_GUARD: float = 52.0
const SCORE_DEFENSE_CAPTURE_BEARER: float = 1800.0
const SCORE_MOVE_BASE_PIECE_ESCAPE: float = 950.0
const PENALTY_MOVE_BASE_PIECE_THREATENED: float = 1800.0
const SCORE_MATERIAL_ADVANTAGE_FINISH: float = 360.0
const SCORE_EMERGENCY_PREVENT_BASE_WIN: float = 50000.0
const PENALTY_ALLOW_IMMEDIATE_BASE_WIN: float = 65000.0
const RESOURCE_ADVANTAGE_FOR_FINISH: float = 4.0
const ENEMY_USABLE_GOLEMS_FOR_FINISH: int = 3
## An on_capture effect put on a golem counts for the captures it can expect
## (get_expected_captures): each turn, every enemy golem it could take by then
## is a chance of this much, and each later turn counts this share of the one
## before. Looked at for at most this many of the stamp's steps.
const CAPTURE_CONTACT_CHANCE: float = 0.4
const CAPTURE_CONTACT_TURN_DECAY: float = 0.8
const CAPTURE_CONTACT_MAX_STEPS: int = 4
## A step added to (or taken from) the end of a stamp only counts if its golem
## makes every step before it; this is the chance it makes each next one
## (get_duration_step_value).
const DURATION_STEP_REACH_CHANCE: float = 0.6
## A plain step with a stamp that drains its own side, on top of what the lost
## steps are worth (score_own_drain_step): a flat part, and a part for each
## other stamped golem it drains.
const PENALTY_OWN_DRAIN_STEP: float = 120.0
const PENALTY_OWN_DRAIN_STAMP: float = 60.0
## Walking such a stamp out of a capture when it should not: with this many other
## stamped golems to drain, or a crown that can move to a safe golem instead. More
## than the crown on it is worth (PENALTY_CROWN_THREATENED and the crown race).
const OWN_DRAIN_SACRIFICE_STAMPS: int = 3
const PENALTY_OWN_DRAIN_FLIGHT: float = 3000.0
## Walking such a stamp without the crown while it has other stamped golems to
## drain, on the same scale: only a move with nothing better left does it.
const PENALTY_OWN_DRAIN_WALK: float = 3000.0
## A stamp on its last step that a +1 keeps (or a -1 ends at once): its golem
## does not stand bare, waiting a turn for a new stamp. On the crowned golem
## that turn is one of the crown race.
const SCORE_DURATION_SAVES_EXPIRY: float = 15.0
const SCORE_DURATION_CROWN_BEARER: float = 110.0
## A Se-tenant set on its way counts this share less for every codex page the
## last stamp it still needs waits behind (get_se_tenant_arrival_weight).
const SE_TENANT_PAGE_WEIGHT: float = 0.8
## How far ahead in the codex the AI looks for a stamp that a stamp put on now
## prepares (score_upcoming_partner_bonus), and the share of what that stamp
## would then do that counts now: it may not come in time.
const UPCOMING_PARTNER_LOOKAHEAD: int = 3
const UPCOMING_PARTNER_SHARE: float = 0.5
const SCORE_CAPTURE_LOCKS_GOLEM: float = 30.0
const SCORE_CAPTURE_REMOVES_GOLEM: float = 18.0
const SCORE_CAPTURE_GOLEM_SCARCITY: float = 14.0
const LOW_USABLE_GOLEM_COUNT: int = 4
## The crown race (get_crown_race_value): what a point on the meter, a crown on
## the board, and each own turn fewer its bearer needs to reach the enemy base
## are worth. Route bonuses count down from CROWN_ROUTE_HORIZON turns out.
const SCORE_CROWN_POINT: float = 40.0
const SCORE_CROWN_ON_BOARD: float = 320.0
const SCORE_CROWN_ROUTE_STEP: float = 140.0
const CROWN_ROUTE_HORIZON: int = 6
## A bearer that can step onto the base on its next turn.
const SCORE_CROWN_NEXT_TURN_WIN: float = 600.0
## How many own turns shorter the new bearer's route has to be for the crown to
## move (is_crown_move_worthwhile): the new bearer waits out the turn the old one
## could have stepped in.
const CROWN_MOVE_MIN_ROUTE_GAIN: float = 2.0
## How many steps from the enemy base a stamp may run out on a golem and it still
## be worth a crown not yet down (stamp_carries_crown): a new stamp can finish a
## walk from that near, and asking for more leaves many sides without a bearer.
## From farther out hardly any first crown got home.
const CROWN_STEPS_SHORT_ALLOWED: int = 2
## A step of the crowned golem that shortens its way home onto a square the
## enemy cannot take (score_bearer_safe_step), while the crown is what the turn
## is about: above most of what the threat map offers, which runs in the
## thousands and would otherwise outbid the walk. The crown race alone does not
## always pay for a step (a full meter's floor, a route past the horizon).
## A plan taking the enemy's crown gets the same (score_takes_enemy_crown).
const SCORE_BEARER_SAFE_STEP: float = 3000.0
## A charged crown held back is worth a crown on a golem this many turns from
## the base (see get_crown_hold_value): crowning a golem farther out loses
## value, a nearer one gains.
const CROWN_HOLD_ROUTE_TURNS: int = 3
## The share of the best bearer-to-be's route bonus a (nearly) charged crown is
## worth before it goes down: what walks golems into range first.
const CROWN_STAGING_SHARE: float = 0.25
## A bearer an enemy golem can take: the share of its value lost when the enemy
## moves next, and when its owner moves first and can still get it away.
const CROWN_EXPOSED_LOSS_SHARE: float = 0.85
const CROWN_EXPOSED_FLEE_SHARE: float = 0.25
const CROWN_RACE_DEFENSE_WEIGHT: float = 1.0
## On top of the golem itself: taking the bearer takes the crown and its charge.
## A whole Se-tenant set on top of its full crown meter: no crown capture
## empties the meter, and it can move the crown every turn.
const SCORE_SE_TENANT_WHOLE_SET: float = 120.0
## A Se-tenant set not yet whole, by its golems on the board: the share of
## the way to a full meter it is worth (get_se_tenant_progress_value).
const SE_TENANT_PROGRESS_SHARES: Array[float] = [0.0, 0.1, 0.3]
## While the set can still be made whole (get_se_tenant_build_value): each of
## its golems on the board, and each stamp it still needs that waits in the
## codex or is on its way from a grant, by how soon it comes.
const SCORE_SE_TENANT_SET_GOLEM: float = 90.0
const SCORE_SE_TENANT_SET_SOURCE: float = 30.0
## A grant that glues a Se-tenant into the player's own codex while the set is
## not whole, on top of what any new stamp is worth, by how near the open page
## it lands (score_grant_stamp_effect); and putting on the stamp that grants
## it, so those go on first (score_se_tenant_grant_affix).
const SCORE_SE_TENANT_GRANT: float = 60.0
const SCORE_SE_TENANT_GRANT_AFFIX: float = 30.0
## Turning the page away from a Se-tenant the set needs: it waits a whole
## round of the codex, while putting it on (and so emptying the page) would
## open the next page at the next turn's start anyway (score_se_tenant_page_turn).
const PENALTY_SE_TENANT_LEFT_BEHIND: float = 60.0
const SCORE_CAPTURE_CROWN: float = 420.0
const SCORE_THREATEN_CROWN: float = 420.0
const PENALTY_CROWN_THREATENED: float = 1400.0
const SCORE_CROWN_BASE_PROGRESS: float = 35.0
## A stamp on the own bearer that reaches the base in one step, and one that
## lasts the whole way there.
const SCORE_CROWN_BASE_ENTRY_THREAT: float = 900.0
const SCORE_CROWN_STAMP_IN_ROUTE: float = 220.0
const PENALTY_NON_BEARER_BASE_ENTRY: float = 420.0
const SCORE_CLEAR_OWN_GOLEM_FROM_ENEMY_BASE: float = 360.0
const MAX_BASE_ROUTE_DISTANCE: int = 8
## What a step on the way to the base counts for (see get_base_route_map): a
## move-and-capture step works whatever stands there, a move-only one needs the
## square empty, and a capture-only one needs an enemy golem standing just there.
const ROUTE_COST_MOVE_AND_CAPTURE: float = 1.0
const ROUTE_COST_MOVE_ONLY: float = 1.25
const ROUTE_COST_CAPTURE_ONLY: float = 4.0
const NO_BASE_ROUTE: Vector2 = Vector2(-1, -1)
## What a stamp running out on the way adds to a route, in own turns: the golem
## stands bare until a stamp comes, and that stamp has to fit the square it
## stopped on.
const ROUTE_TURNS_STAMP_RUNS_OUT: float = 2.0
## How much more the strategy modes weigh the crown's progress, on top of the
## crown race every plan is scored by.
const CROWN_PUSH_STRATEGY_WEIGHT: float = 1.6
const CROWN_STAGING_ENDGAME_WEIGHT: float = 1.2
const CROWN_STAGING_ATTACK_WEIGHT: float = 0.8
const CROWN_STAGING_ROUTE_SETUP_WEIGHT: float = 0.35
const INVALID_POS: Vector2 = Vector2(-1, -1)

var difficulty_level: int = DEFAULT_DIFFICULTY_LEVEL
var search_depth: int = 1
var own_top_n: int = 6
var opponent_top_n: int = 4
var randomness: float = 8.0
var opponent_response_weight: float = DEFAULT_OPPONENT_RESPONSE_WEIGHT
var tactical_defense_awareness: float = 1.0
## How readily the AI goes for the base: an earlier switch to the crown attack
## (AIStrategyDirector) and crowning golems farther from the enemy base (see
## get_crown_hold_value). A style knob, not a strength one - low levels get the
## most, so they are weak by leaving holes rather than by never attacking.
var aggression: float = 0.5
## Not part of the difficulty level: a story boss can be set to guard its base
## worse than its level does (BossDefinition.ai_defense). See begin_decision.
var defense_scale: float = 1.0
## Whether the AI looks at the opponent's threats against its base this turn.
var sees_threats_this_turn: bool = true
var deep_search_ms: int = 0
## Set only on the worker evaluators of the deep pass (see
## choose_deep_beam_plan); 0 means no limit.
var search_deadline_usec: int = 0
var last_profile: Dictionary = {}
var fast_score_cache: Dictionary = {}
var full_score_cache: Dictionary = {}
var move_score_cache: Dictionary = {}
var response_score_cache: Dictionary = {}
var simulated_state_cache: Dictionary = {}
var stamp_cache: Dictionary = {}
var base_route_cache: Dictionary = {}
var capture_reach_cache: Dictionary = {}
## Set while an on_expire effect is scored, so an expiry it sets off in turn is
## not followed (see score_expiry_effect_for_owner).
var scoring_expiry_effect: bool = false
var crown_race_value_cache: Dictionary = {}
var se_tenant_sources_cache: Dictionary = {}
var strategy_context: Dictionary = {}
# stamp_name -> the parts of its estimate the AI uses (calculate_stamp_value_parts),
# filled once on the main thread and only read afterwards.
static var stamp_value_parts: Dictionary = {}
# The average enabled stamp's fresh value, in estimate points.
static var stamp_value_fresh_mean: float = 0.0

func _init(new_difficulty_level = DEFAULT_DIFFICULTY_LEVEL):
	set_difficulty_level(new_difficulty_level)
	prepare_stamp_values()

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
	# fast-prefilter scoring pass (score_turn_plan_fast never sees the huge hard-rule bonuses
	# from score_hard_tactical_rules_for_plan, only the full scorer does). Skipping this check is
	# what lets low difficulty realistically miss "if I don't respond now, I lose next turn" -
	# the same blind spot a beginner has - instead of just being a slower version of perfect play.
	# The "immediate win" shortcut is intentionally NOT gated by this: an unblocked winning move
	# is something the normal scorer already reliably finds on its own (score_move_fast awards
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
	var breakdown: Dictionary = score_turn_plan_breakdown(game_state, player_id, best_plan, board_size)
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
	# Each task gets its own throwaway AIMoveEvaluator (rather than `self`) purely so its internal
	# stamp_cache writes never touch this evaluator's shared caches from multiple threads at once;
	# results are folded into fast_score_cache afterward on the calling thread, so all cache
	# writes stay single-threaded even though the scoring itself runs in parallel.
	var evaluator_script = get_script()
	var results: Array = []
	results.resize(turn_plans.size())
	var fast_score_task: Callable = func(index: int) -> void:
		var scratch_evaluator = evaluator_script.new()
		results[index] = scratch_evaluator.score_turn_plan_fast(game_state, player_id, turn_plans[index], board_size)

	var task_id: int = WorkerThreadPool.add_group_task(fast_score_task, turn_plans.size())
	if task_id < 0:
		increment_profile_count(profile, "fast_score_parallel_fallback")
		return score_turn_plans_fast_sequential(game_state, player_id, turn_plans, board_size)
	WorkerThreadPool.wait_for_group_task_completion(task_id)

	var fast_scored_plans: Array[Dictionary] = []
	for index in range(turn_plans.size()):
		var plan: Dictionary = turn_plans[index]
		var score: float = float(results[index])
		var cache_key: String = "fast|%s|p%d|%s" % [get_state_hash(game_state), player_id, get_plan_hash(plan)]
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
	var response_cache_key: String = "response|%s|p%d|%s" % [get_state_hash(game_state), player_id, get_plan_hash(plan)]
	if response_score_cache.has(response_cache_key):
		increment_profile_count(profile, "response_cache_hits")
		return float(response_score_cache[response_cache_key])

	var simulator_start_usec: int = Time.get_ticks_usec()
	var simulated_state: GameStateData = get_simulated_turn_plan_state(game_state, player_id, plan, board_size)
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
	simulated_state_cache.clear()
	crown_race_value_cache.clear()
	se_tenant_sources_cache.clear()
	# stamp_cache (keyed by stamp name only), base_route_cache (keyed by
	# stamp/side/base occupant, see get_base_route_map) and capture_reach_cache
	# (stamp/side/square, see get_capture_reach_map) stay valid across
	# decisions as long as the evaluator instance itself persists, so
	# clearing them here would only force pointless recomputation.

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

func get_simulated_turn_plan_state(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> GameStateData:
	# Several independent scoring sub-functions (crown race, threat map, hard tactical
	# rules, strategy mode) each need "the state after this plan" for the exact same
	# (game_state, player_id, plan), so a single simulation is cached and shared between
	# them instead of re-cloning and re-resolving stamp effects once per sub-function.
	var cache_key: String = "sim|%s|p%d|%s" % [get_state_hash(game_state), player_id, get_plan_hash(plan)]
	if simulated_state_cache.has(cache_key):
		return simulated_state_cache[cache_key]

	var simulated_state: GameStateData = AIStateSimulator.apply_turn_plan(game_state, player_id, plan, board_size)
	simulated_state_cache[cache_key] = simulated_state
	return simulated_state

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
		var stamp_name: String = piece.affixed_stamp.stamp_name if piece.affixed_stamp != null else ""
		piece_parts.append("%d:%d:%d:%s:%d:%s:%d%s" % [
			int(pos.x),
			int(pos.y),
			piece.color,
			stamp_name,
			piece.turns_remaining,
			"e" if piece.exhausted_this_turn else "r",
			piece.respawn_cooldown_turns,
			"c" if piece.has_crown else "",
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

	return "t%d|cp%d,%d%s%s|p%s|h%s|d%s|fx%s" % [
		game_state.current_turn_player,
		int(game_state.crown_points.get(0, 0)),
		int(game_state.crown_points.get(1, 0)),
		"c" if bool(game_state.crowned_this_turn.get(0, false)) else "",
		"c" if bool(game_state.crowned_this_turn.get(1, false)) else "",
		";".join(piece_parts),
		get_stamp_list_dictionary_hash(game_state.player_hands),
		get_stamp_list_dictionary_hash(game_state.player_decks),
		";".join(effect_parts),
	]

func get_piece_occupancy_hash(game_state: GameStateData) -> String:
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
		var stamp_name: String = piece.affixed_stamp.stamp_name if piece.affixed_stamp != null else ""
		piece_parts.append("%d:%d:%d:%s" % [int(pos.x), int(pos.y), piece.color, stamp_name])
	return ";".join(piece_parts)

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
		str(move.get("requires_affix", false)),
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

	var actions: Array = plan.get("actions", [])
	for action_value in actions:
		if action_value is Dictionary and str(action_value.get("type", "")) == "place_crown":
			score += score_crown_action(game_state, player_id, action_value, board_size)
		elif action_value is Dictionary and str(action_value.get("type", "")) == "turn_page":
			score += score_se_tenant_page_turn(game_state, player_id)

	var setup_affix_actions: Array = plan.get("setup_affix_actions", [])
	for affix_action_value in setup_affix_actions:
		var affix_action: Dictionary = affix_action_value
		score += score_affix_setup_fast(game_state, player_id, affix_action, board_size)

	var move: Dictionary = plan.get("move", {})
	if !move.is_empty():
		score += score_move_fast(game_state, player_id, move, board_size)

	score -= float(maxi(0, actions.size() - 1)) * 0.4
	return score

func score_affix_setup_fast(game_state: GameStateData, player_id: int, affix_action: Dictionary, board_size: int) -> float:
	var piece_pos: Vector2 = StampEffectResolver.as_vector2(affix_action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
	var piece: Piece = game_state.get_piece(piece_pos)
	if piece == null:
		return 0.0

	var stamp: Stamp = affix_action.get("stamp", null) as Stamp
	if stamp == null:
		stamp = get_cached_stamp(str(affix_action.get("stamp_name", "")))
	if stamp == null:
		return 0.0

	var move: Dictionary = {
		"from": piece_pos,
		"to": piece_pos,
		"stamp": stamp,
		"requires_affix": true,
	}
	var score: float = SCORE_AFFIX_STAMP + max(0, stamp.duration) * 2.0
	score += float(stamp.get_directions().size()) * 2.5
	score += get_stamp_value_above_average(stamp) * STAMP_VALUE_AFFIX_PLAY_WEIGHT
	score += score_bearer_stamp(game_state, player_id, piece, piece_pos, stamp, board_size) * 0.75
	score += score_stamp_effect_fast(game_state, player_id, piece, stamp, piece_pos, piece_pos, null, move, board_size) * 0.65
	score -= score_affix_danger(game_state, player_id, affix_action, board_size, false)
	score -= score_covered_stamp_loss(piece, STAMP_VALUE_AFFIX_PLAY_WEIGHT)
	score += score_se_tenant_affix(game_state, player_id, affix_action)
	score += score_se_tenant_grant_affix(game_state, player_id, stamp)
	return score

## How the affix moves the player's Se-tenant set: a Se-tenant stamp put on,
## or one covered by an Overseal. Full plan scoring sees this through the crown
## race; ranking affixes and the fast scores need it spelled out.
func score_se_tenant_affix(game_state: GameStateData, player_id: int, affix_action: Dictionary) -> float:
	var piece: Piece = game_state.get_piece(StampEffectResolver.as_vector2(affix_action.get("piece_pos", INVALID_POS), INVALID_POS))
	if piece == null:
		return 0.0
	var stamp: Stamp = affix_action.get("stamp", null) as Stamp
	if stamp == null:
		stamp = get_cached_stamp(str(affix_action.get("stamp_name", "")))
	var delta: int = int(MoveRules.is_se_tenant_stamp(stamp)) - int(MoveRules.is_se_tenant_stamp(piece.affixed_stamp))
	return score_se_tenant_change(game_state, player_id, delta)

func score_move_fast(game_state: GameStateData, player_id: int, move: Dictionary, board_size: int = BoardConfig.BOARD_SIZE) -> float:
	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var moving_piece: Piece = game_state.get_piece(from_pos)
	if moving_piece == null:
		return -SCORE_WIN

	var stamp: Stamp = AIStateSimulator.get_stamp_for_candidate(game_state.pieces, move)
	var captured_piece: Piece = AIStateSimulator.get_captured_piece(game_state.pieces, move)
	var score: float = 0.0
	if bool(move.get("requires_affix", false)):
		if stamp != null:
			score += SCORE_AFFIX_STAMP + max(0, stamp.duration) * 2.0
			score += get_stamp_value_above_average(stamp) * STAMP_VALUE_AFFIX_PLAY_WEIGHT
	else:
		score += SCORE_USE_EXISTING_STAMP

	if captured_piece != null:
		score += score_capture_at(game_state, captured_piece) * 0.9
		score += score_capture_respawn_effect(game_state, captured_piece) * 0.9
		score += score_base_staging_capture(game_state, player_id, captured_piece, to_pos, board_size) * 0.9
		score += score_captured_trigger(game_state, player_id, move, captured_piece, board_size) * 0.9
		if MoveRules.is_se_tenant_stamp(captured_piece.affixed_stamp):
			score -= score_se_tenant_change(game_state, BoardConfig.get_player_id_for_color(captured_piece.color), -1)
	if is_se_tenant_expiring_move(moving_piece, move):
		score += score_se_tenant_change(game_state, player_id, -1)

	score += score_repeat_last_move_penalty(game_state, player_id, move)
	# A capture that blows up the capturing golem ends the move there.
	if AIStateSimulator.capture_blows_up_capturer(game_state.pieces, move):
		return score
	score += score_bearer_move(game_state, player_id, move)
	score += score_center_control(to_pos, board_size) * 0.7
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
	var fire_share: float = get_effect_fire_share(game_state, player_id, moving_piece, stamp, from_pos, to_pos, captured_piece, move)
	if fire_share > 0.0:
		match stamp.effect_type:
			StampEffect.TYPE_INVISIBLE_TO_ENEMY:
				score += 32.0
				if moving_piece != null and moving_piece.has_crown:
					score += 80.0
			StampEffect.TYPE_STEAL_STAMP:
				score += 50.0
			StampEffect.TYPE_GRANT_STAMP:
				score += score_grant_stamp_effect(game_state, player_id, stamp)
			StampEffect.TYPE_GIVE_STAMP:
				score += score_give_stamp_effect(game_state, player_id, stamp)
			StampEffect.TYPE_MOVE_BASE:
				score += score_move_base_effect(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
			StampEffect.TYPE_INVALID_SQUARES:
				score += score_invalid_squares_effect_fast(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
			StampEffect.TYPE_FROZEN_SQUARES:
				score += score_frozen_squares_effect_fast(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
			StampEffect.TYPE_BOMB:
				score += score_bomb_effect(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
			StampEffect.TYPE_UNCAPTURABLE:
				score += score_uncapturable_effect(moving_piece)
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
			StampEffect.TYPE_GAIN_CROWN_POINT:
				score += score_crown_point_effect(game_state, player_id, player_id, 1)
			StampEffect.TYPE_REMOVE_ENEMY_CROWN_POINT:
				score += score_crown_point_effect(game_state, player_id, 1 - player_id, -1)
			_:
				pass

		if stamp.effect_trigger == StampEffect.TRIGGER_ON_CAPTURE && captured_piece != null:
			score += 20.0
		if stamp.effect_trigger == StampEffect.TRIGGER_ON_MOVE:
			score += 8.0
		if stamp.effect_trigger == StampEffect.TRIGGER_ON_EXPIRE:
			score += 5.0
		score *= fire_share
	if to_pos == from_pos:
		score -= 10.0
	score += score_own_drain_step(game_state, player_id, moving_piece, stamp, from_pos, to_pos, captured_piece, move, board_size)
	return score

## A plain step with a stamp whose every plain step takes a turn off the own
## stamps (Black Hole). Each -1 looks cheap at the far end of a stamp
## (get_duration_step_value), but such steps empty the own board and codex, so
## this stamp should capture rather than walk. A golem without the crown walks it
## only with no other stamped golem to drain, or out of an attack with fewer than
## OWN_DRAIN_SACRIFICE_STAMPS of them: with more the stamp is better lost. The
## exception is a crown it carries in: the step reaches the base or leaves it one
## more step away. Under attack a crowned golem should not walk away either with
## that many to drain, or if its crown can move to a safe golem. Being a score,
## none of this stops a step when nothing else can move.
func score_own_drain_step(
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
	if captured_piece != null or from_pos == to_pos or bool(move.get("requires_affix", false)):
		return 0.0
	if stamp.effect_type != StampEffect.TYPE_DECREASE_OWN_DURATIONS or stamp.effect_trigger != StampEffect.TRIGGER_ON_MOVE:
		return 0.0
	var crowned: bool = moving_piece != null and moving_piece.has_crown
	if crowned:
		if to_pos == StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id):
			return 0.0
		if int(get_base_route(game_state, player_id, stamp, to_pos, board_size).y) == 1:
			return 0.0

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var drained: int = 0
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null and piece != moving_piece and piece.color == player_color and piece.affixed_stamp != null and piece.turns_remaining > 0:
			drained += 1
	var penalty: float = PENALTY_OWN_DRAIN_STEP + float(drained) * PENALTY_OWN_DRAIN_STAMP
	var sacrifice: bool = drained >= OWN_DRAIN_SACRIFICE_STAMPS
	if !crowned:
		if drained > 0 and (sacrifice or !is_square_attacked_by(game_state, 1 - player_id, from_pos, board_size)):
			penalty += PENALTY_OWN_DRAIN_WALK
	elif is_square_attacked_by(game_state, 1 - player_id, from_pos, board_size):
		if sacrifice or can_crown_move_to_safety(game_state, player_id, board_size):
			penalty += PENALTY_OWN_DRAIN_FLIGHT
	return -penalty

## Whether the crown can go, this turn, onto a golem that has a route and that
## the enemy cannot take. Asked with its bearer under attack.
func can_crown_move_to_safety(game_state: GameStateData, player_id: int, board_size: int) -> bool:
	for position_value in game_state.pieces:
		var square: Vector2 = StampEffectResolver.as_vector2(position_value, INVALID_POS)
		if game_state.can_crown_piece(player_id, square) and is_crown_move_worthwhile(game_state, player_id, square, board_size):
			return true
	return false

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

		var target_player_id: int = BoardConfig.get_player_id_for_color(target_piece.color)
		if !stamp_effect_targets_player(stamp, target_player_id):
			continue

		var piece_score: float = get_piece_target_score(target_piece) * 0.75 + SCORE_FROZEN_ENEMY_PIECE
		if target_player_id == player_id:
			score -= piece_score
		else:
			score += piece_score
	return score

## A grant glues new copies of a stamp into the target's codex, as many as fit
## in its free slots. A Se-tenant the player's set can use counts
## SCORE_SE_TENANT_GRANT more, by how near the open page it lands.
func score_grant_stamp_effect(game_state: GameStateData, player_id: int, stamp: Stamp) -> float:
	if game_state == null or stamp == null:
		return 0.0

	var granted_stamp: Stamp = get_cached_stamp(str(stamp.effect_settings.get("stamp_name", stamp.stamp_name)))
	if granted_stamp == null:
		return 0.0

	var target_player_id: int = int(stamp.effect_settings.get("target_player_id", player_id))
	var amount: int = max(1, int(stamp.effect_settings.get("amount", 1)))
	var granted_count: int = amount
	if game_state.has_codex_for_player(target_player_id):
		granted_count = mini(amount, game_state.count_free_codex_slots(target_player_id))
	var stamp_worth: float = SCORE_CODEX_STAMP + get_stamp_value_above_average(granted_stamp) * STAMP_VALUE_AFFIX_PLAY_WEIGHT
	if target_player_id == player_id and MoveRules.is_se_tenant_stamp(granted_stamp) and can_complete_se_tenant_set(game_state, player_id):
		stamp_worth += SCORE_SE_TENANT_GRANT * get_codex_landing_weight(game_state, player_id, true)
	var score: float = stamp_worth * granted_count
	return score if target_player_id == player_id else -score

## A give takes stamps at random from the player's open page - each lost to
## them at what a granted one is worth - and puts them on the target's open
## page while it has room, where the opponent gains them.
func score_give_stamp_effect(game_state: GameStateData, player_id: int, stamp: Stamp) -> float:
	if game_state == null or stamp == null:
		return 0.0
	var hand: Array = game_state.player_hands.get(player_id, [])
	if hand.is_empty():
		return 0.0

	var target_player_id: int = int(stamp.effect_settings.get("target_player_id", 1 - player_id))
	var given_count: int = mini(max(1, int(stamp.effect_settings.get("amount", 1))), hand.size())
	var max_hand_size: int = max(1, int(stamp.effect_settings.get("max_hand_size", StampEffectResolver.DEFAULT_MAX_HAND_SIZE)))
	var value_above_average: float = 0.0
	for stamp_name_value in hand:
		value_above_average += get_stamp_value_above_average(get_cached_stamp(str(stamp_name_value)))
	var stamp_worth: float = SCORE_CODEX_STAMP + value_above_average / float(hand.size()) * STAMP_VALUE_AFFIX_PLAY_WEIGHT
	var score: float = -stamp_worth * float(given_count)
	if target_player_id != player_id:
		var target_room: int = maxi(0, max_hand_size - (game_state.player_hands.get(target_player_id, []) as Array).size())
		score -= stamp_worth * float(mini(given_count, target_room))
	return score

func score_hand_deck_economy_for_plan(game_state: GameStateData, player_id: int, plan: Dictionary) -> float:
	if game_state == null:
		return 0.0

	var score: float = 0.0
	var actions: Array = plan.get("actions", [])
	var has_affix_action: bool = false
	for action_value in actions:
		if !(action_value is Dictionary):
			continue
		var action: Dictionary = action_value
		match str(action.get("type", "")):
			"affix_stamp":
				var affixed_stamp: Stamp = get_cached_stamp(str(action.get("stamp_name", "")))
				if affixed_stamp != null:
					has_affix_action = true
					score -= get_stamp_value_above_average(affixed_stamp) * 0.20
					score += max(0, affixed_stamp.duration) * 0.75
					score += score_stamp_synergy_for_affix(game_state, player_id, action, affixed_stamp)
					score += score_upcoming_partner_bonus(game_state, player_id, affixed_stamp, StampEffectResolver.as_vector2(action.get("piece_pos", INVALID_POS), INVALID_POS))
			"exchange_stamp":
				var exchanged_stamp: Stamp = get_cached_stamp(str(action.get("stamp_name", "")))
				if exchanged_stamp != null:
					score -= get_stamp_value_above_average(exchanged_stamp) * 0.35
					score += score_deck_draw_quality(game_state, player_id, str(action.get("stamp_name", ""))) * 0.35
			"turn_page":
				score += score_se_tenant_page_turn(game_state, player_id)

	score += score_remaining_hand_quality(game_state, player_id, actions) * HAND_DECK_ECONOMY_WEIGHT
	score += score_remaining_deck_quality(game_state, player_id) * HAND_DECK_ECONOMY_WEIGHT * 0.35
	score += score_hand_synergy(game_state, player_id) * HAND_DECK_ECONOMY_WEIGHT
	if has_affix_action:
		score += SCORE_AFFIX_STAMP * 1.5
	return score

func score_stamp_synergy_for_affix(game_state: GameStateData, player_id: int, action: Dictionary, stamp: Stamp) -> float:
	if game_state == null or stamp == null:
		return 0.0

	var piece_pos: Vector2 = StampEffectResolver.as_vector2(action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var distance_to_base: float = get_manhattan_distance(piece_pos, opponent_base)
	var movement_count: int = stamp.get_directions().size()
	var score: float = 0.0
	if stamp.effect_type == StampEffect.TYPE_FROZEN_SQUARES or stamp.effect_type == StampEffect.TYPE_INVALID_SQUARES:
		score += maxf(0.0, float(BoardConfig.BOARD_SIZE) - distance_to_base) * 1.5
	if stamp.effect_type == StampEffect.TYPE_INCREASE_SELF_DURATION and movement_count >= 4:
		score += SCORE_HAND_SYNERGY
	if stamp.effect_type == StampEffect.TYPE_MOVE_BASE:
		score += SCORE_HAND_SYNERGY * 0.75
	return score

## A one-step stamp put on now for one the codex brings soon (the next
## UPCOMING_PARTNER_LOOKAHEAD stamps after the open page): it stays on its last
## step until then, as a step would end it. A stamp that adds a step to every
## own stamp on affix keeps it; one that takes a step off every own stamp sets
## off its on_expire effect, right where it is put on now - counted only when
## that helps, as the owner need not make that move, and on a stamp that does
## it on its moves only if it makes one (DURATION_STEP_REACH_CHANCE).
## UPCOMING_PARTNER_SHARE of it counts now, as the stamp may not come in time.
func score_upcoming_partner_bonus(game_state: GameStateData, player_id: int, stamp: Stamp, piece_pos: Vector2) -> float:
	if stamp == null or stamp.duration != 1 or !game_state.has_codex_for_player(player_id):
		return 0.0
	var extender_coming: bool = false
	var shortener_share: float = 0.0
	for stamp_name in game_state.get_upcoming_stamp_names_in_turn_order(player_id, UPCOMING_PARTNER_LOOKAHEAD):
		var upcoming: Stamp = get_cached_stamp(stamp_name)
		if upcoming == null or !upcoming.has_effect():
			continue
		if upcoming.effect_type == StampEffect.TYPE_INCREASE_OWN_DURATIONS and upcoming.effect_trigger == StampEffect.TRIGGER_ON_AFFIX:
			extender_coming = true
		elif upcoming.effect_type == StampEffect.TYPE_DECREASE_OWN_DURATIONS:
			if upcoming.effect_trigger == StampEffect.TRIGGER_ON_AFFIX:
				shortener_share = 1.0
			elif upcoming.effect_trigger == StampEffect.TRIGGER_ON_MOVE:
				shortener_share = maxf(shortener_share, DURATION_STEP_REACH_CHANCE)

	var bonus: float = 0.0
	if extender_coming:
		bonus += (get_stamp_remaining_value(stamp, 2) - get_stamp_remaining_value(stamp, 1)) * STAMP_ESTIMATE_POINT_SCORE * DURATION_STEP_REACH_CHANCE + SCORE_DURATION_SAVES_EXPIRY
	var piece: Piece = game_state.get_piece(piece_pos)
	if shortener_share > 0.0 and piece != null and stamp.has_effect() and stamp.effect_trigger == StampEffect.TRIGGER_ON_EXPIRE:
		var expiry_move: Dictionary = {"from": piece_pos, "to": piece_pos, "stamp": stamp, "requires_affix": false}
		bonus += maxf(0.0, score_effect_value(game_state, player_id, piece, stamp, piece_pos, expiry_move, BoardConfig.BOARD_SIZE)) * shortener_share
	return bonus * UPCOMING_PARTNER_SHARE

## The route onto the enemy base as Vector2(cost, steps), NO_BASE_ROUTE when there
## is none. See get_base_route_map.
func get_base_route(game_state: GameStateData, player_id: int, stamp: Stamp, from_pos: Vector2, board_size: int) -> Vector2:
	if game_state == null or stamp == null:
		return NO_BASE_ROUTE
	return get_base_route_map(game_state, player_id, stamp, board_size).get(from_pos, NO_BASE_ROUTE)

func get_route_step_cost(movement_type: int) -> float:
	match movement_type:
		StampEffect.MOVEMENT_MOVE_ONLY:
			return ROUTE_COST_MOVE_ONLY
		StampEffect.MOVEMENT_CAPTURE_ONLY:
			return ROUTE_COST_CAPTURE_ONLY
	return ROUTE_COST_MOVE_AND_CAPTURE

## The cheapest route from each square onto the enemy base for a golem carrying
## this stamp, keyed by square, as Vector2(cost, steps). The steps on the way
## follow the stamp's cells and ignore the pieces in the way, which come and go,
## so a cell counts for how far it can be relied on (ROUTE_COST_*). The last step
## onto the base follows the movement rules for whatever stands there now (see
## can_stamp_enter_base_from), so it costs 1 whatever its cell. So the map
## depends only on the stamp, the side, the base and its occupant, and stays
## cached from turn to turn.
func get_base_route_map(game_state: GameStateData, player_id: int, stamp: Stamp, board_size: int) -> Dictionary:
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var base_piece: Piece = game_state.get_piece(opponent_base)
	var cache_key: String = "%s|c%d|base%s|%s" % [
		stamp.stamp_name,
		player_color,
		vector_hash(opponent_base),
		get_base_occupant_key(base_piece, player_color),
	]
	if base_route_cache.has(cache_key):
		return base_route_cache[cache_key]

	var route_map: Dictionary = {}
	var predecessors: Dictionary = {}
	var open_routes: Dictionary = {}
	for x in range(board_size):
		for y in range(board_size):
			var square: Vector2 = Vector2(x, y)
			if can_stamp_enter_base_from(base_piece, player_color, stamp, square, opponent_base):
				open_routes[square] = Vector2(1.0, 1.0)
			for movement_option: Dictionary in stamp.get_movement_options():
				var offset: Vector2 = movement_option.get("offset", Vector2.ZERO)
				var next_square: Vector2 = square + offset * player_color
				if next_square == square or next_square == opponent_base or !MoveRules.is_valid_position(next_square, board_size):
					continue
				if !predecessors.has(next_square):
					predecessors[next_square] = []
				predecessors[next_square].append({
					"square": square,
					"cost": get_route_step_cost(int(movement_option.get("movement_type", StampEffect.MOVEMENT_MOVE_AND_CAPTURE))),
				})

	while !open_routes.is_empty():
		var target: Vector2 = get_cheapest_route_square(open_routes)
		var route: Vector2 = open_routes[target]
		open_routes.erase(target)
		route_map[target] = route
		if int(route.y) >= MAX_BASE_ROUTE_DISTANCE:
			continue
		for link: Dictionary in predecessors.get(target, []):
			var square: Vector2 = link["square"]
			if route_map.has(square):
				continue
			var cost: float = route.x + float(link["cost"])
			if !open_routes.has(square) or cost < Vector2(open_routes[square]).x:
				open_routes[square] = Vector2(cost, route.y + 1.0)

	base_route_cache[cache_key] = route_map
	return route_map

func get_cheapest_route_square(routes: Dictionary) -> Vector2:
	var best_square: Vector2 = INVALID_POS
	var best_cost: float = INF
	for square: Vector2 in routes:
		var cost: float = Vector2(routes[square]).x
		if cost < best_cost:
			best_cost = cost
			best_square = square
	return best_square

func get_base_occupant_key(base_piece: Piece, player_color: int) -> String:
	if base_piece == null:
		return "empty"
	if base_piece.color == player_color:
		return "own"
	return "enemy" if MoveRules.can_capture_target_piece(base_piece, player_color) else "guarded"

## The last step onto the base follows the movement rules exactly: a move-only
## step cannot enter an occupied base, a capture-only one only by taking a
## piece that stands there, and nothing enters over a golem of its own side.
## That is what makes a golem parked on its own base a wall against some
## stamps, and an empty base a wall against others.
func can_stamp_enter_base_from(base_piece: Piece, player_color: int, stamp: Stamp, candidate_pos: Vector2, base_pos: Vector2) -> bool:
	for movement_option: Dictionary in stamp.get_movement_options():
		var offset: Vector2 = movement_option.get("offset", Vector2.ZERO)
		if candidate_pos + offset * player_color != base_pos:
			continue
		var movement_type: int = int(movement_option.get("movement_type", StampEffect.MOVEMENT_MOVE_AND_CAPTURE))
		if MoveRules.is_target_allowed_by_movement_type(base_piece, player_color, movement_type):
			return true
	return false

## How many of the player's own turns until they can put the crown down (or,
## with it on the board, move it): 0 means on this turn if it is theirs, else
## at the start of their next one.
static func get_crown_turns_to_ready(game_state: GameStateData, player_id: int) -> int:
	var points: int = int(game_state.crown_points.get(player_id, 0))
	# A turn's point comes at its start, so a player waiting for their turn
	# still has one due.
	if game_state.current_turn_player != player_id:
		points += 1
	return maxi(0, game_state.crown_points_required - points)

static func can_crown_next_turn(game_state: GameStateData, player_id: int) -> bool:
	return get_crown_turns_to_ready(game_state, player_id) == 0

## The player's standing in the crown race: the points gathered - a (nearly)
## charged crown also by how close its best bearer would be - and a crown on
## the board by how close its bearer is to taking the enemy base. With both,
## the better of the two counts: the points only move the crown, and a capture
## takes them along with it. A Se-tenant set on the board, whole or on its
## way, adds its own share.
func get_crown_race_value(game_state: GameStateData, player_id: int, board_size: int) -> float:
	var cache_key: String = "%s|p%d" % [get_state_hash(game_state), player_id]
	if crown_race_value_cache.has(cache_key):
		return float(crown_race_value_cache[cache_key])

	var points: int = int(game_state.crown_points.get(player_id, 0))
	var value: float = float(points) * SCORE_CROWN_POINT
	if points >= game_state.crown_points_required:
		value = get_crown_hold_value()
	if points + 1 >= game_state.crown_points_required:
		value += get_crown_route_bonus(get_best_crown_candidate_route_turns(game_state, player_id, board_size)) * CROWN_STAGING_SHARE
	var crowned_pos: Vector2 = game_state.get_crowned_piece_position(player_id)
	if crowned_pos != INVALID_POS:
		value = maxf(value, score_crown_bearer(game_state, player_id, crowned_pos, board_size, game_state.current_turn_player == player_id))
	value += get_se_tenant_progress_value(game_state, player_id, game_state.count_se_tenant_golems(player_id))
	crown_race_value_cache[cache_key] = value
	return value

func get_crown_race_value_delta(before_state: GameStateData, after_state: GameStateData, player_id: int, board_size: int) -> float:
	return get_crown_race_value(after_state, player_id, board_size) - get_crown_race_value(before_state, player_id, board_size)

## How the plan moves the crown race: the player's own standing, and - when the
## AI sees the threats this turn - the opponent's, against it.
func score_crown_race_for_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	if game_state == null or plan.is_empty():
		return 0.0

	var simulated_state: GameStateData = get_simulated_turn_plan_state(game_state, player_id, plan, board_size)
	if simulated_state.game_over:
		return 0.0
	var score: float = get_crown_race_value_delta(game_state, simulated_state, player_id, board_size)
	if sees_threats_this_turn:
		score -= get_crown_race_value_delta(game_state, simulated_state, 1 - player_id, board_size) * CROWN_RACE_DEFENSE_WEIGHT
	for action_value in plan.get("actions", []):
		if action_value is Dictionary and str(action_value.get("type", "")) == "place_crown":
			score += score_crown_condition_effect(game_state, player_id, StampEffectResolver.as_vector2(action_value.get("piece_pos", INVALID_POS), INVALID_POS), board_size)
	return score

## A charged crown not yet down is worth as much as a crown on a golem
## CROWN_HOLD_ROUTE_TURNS from the base - less for a more aggressive AI, which
## so crowns golems farther out.
func get_crown_hold_value() -> float:
	return SCORE_CROWN_ON_BOARD + get_crown_route_bonus(CROWN_HOLD_ROUTE_TURNS) - aggression * SCORE_CROWN_ROUTE_STEP

func get_crown_route_bonus(route_turns: float) -> float:
	if route_turns < 0.0:
		return 0.0
	return maxf(0.0, float(CROWN_ROUTE_HORIZON) - route_turns) * SCORE_CROWN_ROUTE_STEP

## The crown on this golem (it need not be there yet): its route to the enemy
## base, less the risk of losing it to an enemy golem that can take it - all
## but certain when the enemy moves next, smaller when the owner moves first
## and can still get it away. A golem crowned this turn waits it out, so for
## a crown about to go down the owner does not move first.
func score_crown_bearer(game_state: GameStateData, player_id: int, piece_pos: Vector2, board_size: int, owner_moves_next: bool = false) -> float:
	var route_turns: float = get_golem_route_turns(game_state, player_id, piece_pos, board_size)
	var value: float = SCORE_CROWN_ON_BOARD + get_crown_route_bonus(route_turns)
	if route_turns == 1.0:
		value += SCORE_CROWN_NEXT_TURN_WIN
	if is_square_attacked_by(game_state, 1 - player_id, piece_pos, board_size):
		value *= 1.0 - (CROWN_EXPOSED_FLEE_SHARE if owner_moves_next else CROWN_EXPOSED_LOSS_SHARE)
	return value

## The crown race's quick take on crowning this golem now rather than holding
## the charged crown back.
func score_crown_action(game_state: GameStateData, player_id: int, action: Dictionary, board_size: int) -> float:
	var piece_pos: Vector2 = StampEffectResolver.as_vector2(action.get("piece_pos", INVALID_POS), INVALID_POS)
	return score_crown_landing(game_state, player_id, piece_pos, board_size) - get_crown_hold_value()

## score_crown_bearer for a crown about to go down: on the board the crowning
## leaves (Mercury's freeze can take the attacker off it, Goat is safe), and with
## what the crowning itself does.
func score_crown_landing(game_state: GameStateData, player_id: int, piece_pos: Vector2, board_size: int) -> float:
	var crowned_state: GameStateData = get_crowned_state(game_state, player_id, piece_pos)
	return score_crown_bearer(crowned_state, player_id, piece_pos, board_size) + score_crown_condition_effect(game_state, player_id, piece_pos, board_size)

## The board once this golem is crowned, its crown_condition effect gone off. The
## state itself for a stamp without one, the usual case.
func get_crowned_state(game_state: GameStateData, player_id: int, piece_pos: Vector2) -> GameStateData:
	if !has_crown_condition_effect(game_state.get_piece(piece_pos)):
		return game_state
	var crowned_state: GameStateData = AIStateSimulator.clone_game_state(game_state)
	AIStateSimulator.apply_place_crown_action(crowned_state, player_id, {"piece_pos": piece_pos})
	return crowned_state

func has_crown_condition_effect(piece: Piece) -> bool:
	if piece == null or piece.affixed_stamp == null:
		return false
	return piece.affixed_stamp.has_effect() and piece.affixed_stamp.effect_trigger == StampEffect.TRIGGER_CROWN_CONDITION

## What the golem's crown_condition effect is worth as it goes off, on the board
## before it does: a frozen golem counts by the moves it loses. The golem itself
## as it stands crowned, which an uncapturable crown is worth more for.
func score_crown_condition_effect(game_state: GameStateData, player_id: int, piece_pos: Vector2, board_size: int) -> float:
	var piece: Piece = game_state.get_piece(piece_pos)
	if !has_crown_condition_effect(piece):
		return 0.0
	var crowned_piece: Piece = get_crowned_state(game_state, player_id, piece_pos).get_piece(piece_pos)
	var crowning: Dictionary = {"from": piece_pos, "to": piece_pos, "stamp": piece.affixed_stamp, "requires_affix": false}
	return score_effect_value(game_state, player_id, crowned_piece, piece.affixed_stamp, piece_pos, crowning, board_size)

## Whether the crown should go onto this golem now. It costs the turn the bearer
## could have stepped in and the page turn, while a whole Se-tenant set leaves the
## meter full, so the crown race alone does not hold it back. A crown not yet
## down waits for a golem that can carry it (near enough) home: a full meter loses
## nothing by waiting. A crown on the board moves for a route
## CROWN_MOVE_MIN_ROUTE_GAIN turns shorter, or to get it off a bearer under attack
## or without a route, and never onto a golem without a route or one the enemy
## can take. All of it as the board stands once the golem is crowned.
func is_crown_move_worthwhile(game_state: GameStateData, player_id: int, piece_pos: Vector2, board_size: int) -> bool:
	var crowned_state: GameStateData = get_crowned_state(game_state, player_id, piece_pos)
	var bearer_pos: Vector2 = game_state.get_crowned_piece_position(player_id)
	if bearer_pos == INVALID_POS:
		return can_golem_carry_crown(crowned_state, player_id, piece_pos, board_size)
	var route_turns: float = get_golem_route_turns(crowned_state, player_id, piece_pos, board_size)
	if route_turns < 0.0:
		return false
	var bearer_turns: float = get_golem_route_turns(game_state, player_id, bearer_pos, board_size)
	if bearer_turns >= 0.0 and bearer_turns - route_turns < CROWN_MOVE_MIN_ROUTE_GAIN and !is_square_attacked_by(game_state, 1 - player_id, bearer_pos, board_size):
		return false
	return !is_square_attacked_by(crowned_state, 1 - player_id, piece_pos, board_size)

## Whether the golem can walk the crown home or near enough: on the stamp it
## carries, or for a bare golem, on one from the open codex page.
func can_golem_carry_crown(game_state: GameStateData, player_id: int, piece_pos: Vector2, board_size: int) -> bool:
	var piece: Piece = game_state.get_piece(piece_pos)
	if piece == null or piece.is_respawn_locked():
		return false
	if piece.affixed_stamp != null:
		return stamp_carries_crown(game_state, player_id, piece.affixed_stamp, piece.turns_remaining, piece_pos, board_size)
	for stamp: Stamp in get_open_page_stamps(game_state, player_id):
		if stamp_carries_crown(game_state, player_id, stamp, stamp.duration if stamp.duration == -1 else maxi(1, stamp.duration), piece_pos, board_size):
			return true
	return false

func stamp_carries_crown(game_state: GameStateData, player_id: int, stamp: Stamp, turns_left: int, piece_pos: Vector2, board_size: int) -> bool:
	var route: Vector2 = get_base_route(game_state, player_id, stamp, piece_pos, board_size)
	if route.y < 0.0:
		return false
	return stamp_outlasts_route(stamp, turns_left, int(route.y)) or int(route.y) - turns_left <= CROWN_STEPS_SHORT_ALLOWED

## Own turns the golem needs to step onto the enemy base, as far as the route can
## be relied on (see get_base_route_map): with the stamp it carries while that
## lasts (ROUTE_TURNS_STAMP_RUNS_OUT more if it runs out on the way), or for a
## bare golem a turn to be stamped first, with the best stamp on the open codex
## page. -1 when no route is in sight.
func get_golem_route_turns(game_state: GameStateData, player_id: int, piece_pos: Vector2, board_size: int) -> float:
	var piece: Piece = game_state.get_piece(piece_pos)
	if piece == null or piece.is_respawn_locked():
		return -1.0
	if piece.affixed_stamp != null:
		var carried_route: Vector2 = get_base_route(game_state, player_id, piece.affixed_stamp, piece_pos, board_size)
		if carried_route.y < 0.0:
			return -1.0
		if !stamp_outlasts_route(piece.affixed_stamp, piece.turns_remaining, int(carried_route.y)):
			return carried_route.x + ROUTE_TURNS_STAMP_RUNS_OUT
		return carried_route.x

	var best_turns: float = -1.0
	for stamp: Stamp in get_open_page_stamps(game_state, player_id):
		var route: Vector2 = get_base_route(game_state, player_id, stamp, piece_pos, board_size)
		if route.y < 0.0:
			continue
		var turns: float = route.x + 1.0
		if !stamp_outlasts_route(stamp, stamp.duration if stamp.duration == -1 else maxi(1, stamp.duration), int(route.y)):
			turns += ROUTE_TURNS_STAMP_RUNS_OUT
		if best_turns < 0.0 or turns < best_turns:
			best_turns = turns
	return best_turns

## Whether the stamp lasts a route of this many steps: on the turns it has left
## (-1 never runs out), or because a plain step costs it nothing (Cherry tree).
func stamp_outlasts_route(stamp: Stamp, turns_left: int, steps: int) -> bool:
	if turns_left == -1 or steps <= turns_left:
		return true
	return stamp.effect_type == StampEffect.TYPE_INCREASE_SELF_DURATION and stamp.effect_trigger == StampEffect.TRIGGER_ON_MOVE

func get_best_crown_candidate_route_turns(game_state: GameStateData, player_id: int, board_size: int) -> float:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var best_turns: float = -1.0
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != player_color or piece.has_crown:
			continue
		var turns: float = get_golem_route_turns(game_state, player_id, StampEffectResolver.as_vector2(position_value, INVALID_POS), board_size)
		if turns >= 0.0 and (best_turns < 0.0 or turns < best_turns):
			best_turns = turns
	return best_turns

## The route the crown race is about: its bearer's, or while the crown is not
## down, that of the best golem to put it on.
func get_crown_staging_route_turns(game_state: GameStateData, player_id: int, board_size: int) -> float:
	var crowned_pos: Vector2 = game_state.get_crowned_piece_position(player_id)
	if crowned_pos != INVALID_POS:
		return get_golem_route_turns(game_state, player_id, crowned_pos, board_size)
	return get_best_crown_candidate_route_turns(game_state, player_id, board_size)

func get_open_page_stamps(game_state: GameStateData, player_id: int) -> Array[Stamp]:
	var stamps: Array[Stamp] = []
	var seen: Dictionary = {}
	for stamp_name_value in game_state.player_hands.get(player_id, []):
		var stamp_name: String = str(stamp_name_value)
		if seen.has(stamp_name):
			continue
		seen[stamp_name] = true
		var stamp: Stamp = get_cached_stamp(stamp_name)
		if stamp != null and MoveRules.stamp_can_be_used(stamp):
			stamps.append(stamp)
	return stamps

func is_square_attacked_by(game_state: GameStateData, attacker_player_id: int, square: Vector2, board_size: int) -> bool:
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_stamp_moves(
		game_state.pieces,
		StampEffectResolver.get_color_for_player_id(attacker_player_id),
		board_size,
		game_state.board_effects
	)
	for move: Dictionary in valid_moves:
		if AIStateSimulator.get_move_to(move) == square:
			return true
	return false

## Whether the crown is on the board or near enough to charged to plan around.
func player_has_crown_plan(game_state: GameStateData, player_id: int) -> bool:
	return game_state.has_crown_on_board(player_id) or get_crown_turns_to_ready(game_state, player_id) <= 1

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

	var has_duration: bool = false
	var mobility_total: int = 0
	for stamp_name_value in hand:
		var stamp: Stamp = get_cached_stamp(str(stamp_name_value))
		if stamp == null:
			continue
		has_duration = has_duration or stamp.effect_type == StampEffect.TYPE_INCREASE_SELF_DURATION or stamp.effect_type == StampEffect.TYPE_INCREASE_OWN_DURATIONS
		mobility_total += stamp.get_directions().size()

	if has_duration and mobility_total >= hand.size() * 3:
		return SCORE_HAND_SYNERGY * 0.75
	return 0.0

func score_remaining_hand_quality(game_state: GameStateData, player_id: int, actions: Array) -> float:
	var consumed_stamp_names: Array = []
	for action_value in actions:
		if !(action_value is Dictionary):
			continue
		var action: Dictionary = action_value
		if str(action.get("type", "")) == "affix_stamp":
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
		score += get_stamp_value_above_average(stamp)
		remaining_count += 1

	if remaining_count <= 0:
		return -8.0
	return score / float(remaining_count)

func score_remaining_deck_quality(game_state: GameStateData, player_id: int) -> float:
	var deck: Array = game_state.get_upcoming_stamp_names_in_turn_order(player_id, 5)
	if deck.is_empty():
		return -6.0

	var sample_count: int = deck.size()
	var score: float = 0.0
	for stamp_name_value in deck:
		var stamp: Stamp = get_cached_stamp(str(stamp_name_value))
		if stamp == null:
			continue
		score += get_stamp_value_above_average(stamp)
	return score / float(sample_count)

func score_deck_draw_quality(game_state: GameStateData, player_id: int, avoided_stamp_name: String) -> float:
	var deck: Array = game_state.get_upcoming_stamp_names_in_turn_order(player_id)
	if deck.is_empty():
		return -10.0

	for stamp_name_value in deck:
		var stamp_name: String = str(stamp_name_value)
		if stamp_name == avoided_stamp_name:
			continue
		var stamp: Stamp = get_cached_stamp(stamp_name)
		if stamp == null:
			continue
		return get_stamp_value_above_average(stamp)
	return -5.0

func score_threat_map_for_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	if game_state == null or plan.is_empty():
		return 0.0

	var simulated_state: GameStateData = get_simulated_turn_plan_state(game_state, player_id, plan, board_size)
	if simulated_state.game_over:
		return clampf(get_terminal_score_for_player(simulated_state, player_id) * 0.05, -SCORE_WIN * 0.05, SCORE_WIN * 0.05)

	var opponent_player_id: int = 1 - player_id
	var score: float = 0.0
	score += score_two_turn_base_pressure(simulated_state, player_id, board_size)
	if sees_threats_this_turn:
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

	# Only a crowned golem wins, and a move cannot crown one, so without a crown
	# already on the board no move can set up a base entry for next turn, and
	# the per-move simulation (the expensive part of full plan scoring) has
	# nothing to find.
	var has_bearer: bool = game_state.has_crown_on_board(player_id)
	var best_pressure: float = 0.0
	for move: Dictionary in valid_moves:
		var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
		var is_bearer_move: bool = AIStateSimulator.is_own_crown_candidate(game_state.pieces, move, player_id)
		if AIStateSimulator.is_base_win_move(game_state.pieces, move, player_id, opponent_base):
			best_pressure = maxf(best_pressure, SCORE_WIN * 0.25)
			continue

		var distance_after: float = get_manhattan_distance(to_pos, opponent_base)
		var pressure: float = maxf(0.0, float(board_size) - distance_after) * 8.0
		if is_bearer_move:
			pressure += SCORE_TWO_TURN_BASE_THREAT
		if has_bearer:
			var simulated_plan: Dictionary = {
				"actions": [{
					"type": "move_piece",
					"player_id": player_id,
					"from": AIStateSimulator.get_move_from(move),
					"to": to_pos,
				}],
				"move": move,
				"setup_affix_actions": [],
				"plan_type": "threat_probe",
			}
			var next_state: GameStateData = AIStateSimulator.apply_turn_plan(game_state, player_id, simulated_plan, board_size)
			if !next_state.game_over and has_immediate_base_win(next_state, player_id, board_size):
				pressure += SCORE_FORCE_DEFENSE
		best_pressure = maxf(best_pressure, pressure)
	return best_pressure

func has_immediate_base_win(game_state: GameStateData, player_id: int, board_size: int) -> bool:
	if !game_state.has_crown_on_board(player_id):
		return false
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
		var target_player_id: int = BoardConfig.get_player_id_for_color(target_piece.color)
		if target_player_id != opponent_player_id:
			continue
		pressure += get_piece_target_score(target_piece, game_state)
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

	var setup_affix_actions: Array = plan.get("setup_affix_actions", [])
	for affix_index in range(setup_affix_actions.size()):
		var affix_action: Dictionary = setup_affix_actions[affix_index]
		setup_score += score_affix_setup(get_affix_scoring_state(game_state, player_id, plan, affix_index, board_size), player_id, affix_action, board_size)

	var actions: Array = plan.get("actions", [])
	action_score = -float(maxi(0, actions.size() - 1)) * 0.8
	var economy_score: float = score_hand_deck_economy_for_plan(game_state, player_id, plan)
	var threat_score: float = score_threat_map_for_plan(game_state, player_id, plan, board_size)
	var crown_score: float = score_crown_race_for_plan(game_state, player_id, plan, board_size)
	var strategy_score: float = score_strategy_mode_for_plan(game_state, player_id, plan, board_size)
	var hard_rule_score: float = score_hard_tactical_rules_for_plan(game_state, player_id, plan, board_size)
	var total_score: float = move_score + setup_score + action_score + economy_score + threat_score + crown_score + strategy_score + hard_rule_score
	return {
		"move": move_score,
		"setup": setup_score,
		"action_count": action_score,
		"economy": economy_score,
		"threat": threat_score,
		"crown": crown_score,
		"strategy": strategy_score,
		"hard_rules": hard_rule_score,
		"total": total_score,
	}

## The state a plan's setup affix is scored on: the turn's start, except for a
## stamp whose on_affix effect works on the board as the turn's earlier actions
## left it - a War Drummer put on after the turn's one-step stamps extends
## them too.
func get_affix_scoring_state(game_state: GameStateData, player_id: int, plan: Dictionary, affix_index: int, board_size: int) -> GameStateData:
	if affix_index <= 0:
		return game_state
	var affix_action: Dictionary = plan.get("setup_affix_actions", [])[affix_index]
	var stamp: Stamp = get_cached_stamp(str(affix_action.get("stamp_name", "")))
	if stamp == null or !stamp.has_effect() or stamp.effect_trigger != StampEffect.TRIGGER_ON_AFFIX:
		return game_state

	var state: GameStateData = AIStateSimulator.clone_game_state(game_state)
	state.current_turn_player = player_id
	var affixes_done: int = 0
	for action_value in plan.get("actions", []):
		var action: Dictionary = action_value
		var action_type: String = str(action.get("type", ""))
		if action_type == "affix_stamp":
			if affixes_done == affix_index:
				break
			AIStateSimulator.apply_affix_action(state, player_id, action, board_size)
			affixes_done += 1
		elif action_type == "turn_page":
			AIStateSimulator.apply_turn_page_action(state, player_id)
		elif action_type == "place_crown":
			AIStateSimulator.apply_place_crown_action(state, player_id, action)
	return state

func score_hard_tactical_rules_for_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	if game_state == null or plan.is_empty():
		return 0.0

	var simulated_state: GameStateData = get_simulated_turn_plan_state(game_state, player_id, plan, board_size)
	# A finished game has no next turn to defend: without this, a winning plan
	# would still be charged for the base threat the opponent never gets to use,
	# and a win by leaving the opponent without a legal action would go unseen.
	if simulated_state.game_over:
		return get_terminal_score_for_player(simulated_state, player_id)

	var score: float = 0.0
	if sees_threats_this_turn:
		var opponent_player_id: int = 1 - player_id
		var opponent_had_immediate_base_win: bool = has_immediate_base_win(game_state, opponent_player_id, board_size)
		var opponent_has_immediate_base_win_after: bool = has_immediate_base_win(simulated_state, opponent_player_id, board_size)
		if opponent_had_immediate_base_win:
			score += SCORE_EMERGENCY_PREVENT_BASE_WIN if !opponent_has_immediate_base_win_after else -PENALTY_ALLOW_IMMEDIATE_BASE_WIN
		elif opponent_has_immediate_base_win_after:
			score -= PENALTY_ALLOW_IMMEDIATE_BASE_WIN

	if sees_threats_this_turn:
		score += score_move_base_piece_escape_rule(game_state, simulated_state, player_id, plan, board_size)
	score += score_material_advantage_finish_rule(game_state, simulated_state, player_id, board_size)
	score += score_move_off_enemy_base_rule(game_state, player_id, plan)
	return score

func score_material_advantage_finish_rule(
	before_state: GameStateData,
	after_state: GameStateData,
	player_id: int,
	board_size: int
) -> float:
	# Golem counts hardly ever differ (captured golems respawn), so the lead is
	# measured in what each side can still do - see get_resource_advantage.
	var resource_advantage: float = AIStrategyDirector.get_resource_advantage(before_state, player_id)
	if resource_advantage < RESOURCE_ADVANTAGE_FOR_FINISH and count_usable_golems(before_state, 1 - player_id) > ENEMY_USABLE_GOLEMS_FOR_FINISH:
		return 0.0
	# In golem-sized units, the scale the bonus below was tuned for.
	var material_advantage: int = int(floor(resource_advantage / AIStrategyDirector.RESOURCE_WEIGHT_USABLE_GOLEM))

	# Ahead, the crown is what turns the lead into a win: push it harder.
	var score: float = get_crown_race_value_delta(before_state, after_state, player_id, board_size) * 0.8
	score += float(maxi(0, material_advantage)) * SCORE_MATERIAL_ADVANTAGE_FINISH
	return score

func score_move_base_piece_escape_rule(
	before_state: GameStateData,
	after_state: GameStateData,
	player_id: int,
	plan: Dictionary,
	board_size: int
) -> float:
	var before_risk: float = score_move_base_piece_crown_risk(before_state, player_id, board_size)
	if before_risk <= 0.0:
		return 0.0

	var after_risk: float = score_move_base_piece_crown_risk(after_state, player_id, board_size)
	var score: float = (before_risk - after_risk) * SCORE_MOVE_BASE_PIECE_ESCAPE
	if after_risk >= before_risk:
		score -= PENALTY_MOVE_BASE_PIECE_THREATENED

	var move: Dictionary = plan.get("move", {})
	if !move.is_empty():
		var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
		var moving_piece: Piece = before_state.get_piece(from_pos)
		if is_move_base_piece(moving_piece):
			score += SCORE_MOVE_BASE_PIECE_ESCAPE * 0.75
	return score

## How close the enemy's crowned golem is to the player's base-moving golems.
func score_move_base_piece_crown_risk(game_state: GameStateData, player_id: int, board_size: int) -> float:
	if game_state == null:
		return 0.0

	var opponent_player_id: int = 1 - player_id
	var bearer_pos: Vector2 = game_state.get_crowned_piece_position(opponent_player_id)
	if bearer_pos == INVALID_POS:
		return 0.0
	var bearer_moves: Array[Vector2] = MoveRules.get_piece_moves_for_player(
		game_state.pieces,
		bearer_pos,
		opponent_player_id,
		board_size,
		game_state.board_effects
	)

	var risk: float = 0.0
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	for position_value in game_state.pieces:
		var pos: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != player_color or !is_move_base_piece(piece):
			continue

		if bearer_moves.has(pos):
			risk += 3.0
			continue

		var bearer_distance: float = get_manhattan_distance(bearer_pos, pos)
		if bearer_distance <= 1.0:
			risk += 2.0
		elif bearer_distance <= 2.0:
			risk += 1.0
	return risk

func is_move_base_piece(piece: Piece) -> bool:
	return piece != null and piece.affixed_stamp != null and piece.affixed_stamp.effect_type == StampEffect.TYPE_MOVE_BASE

func score_move_off_enemy_base_rule(game_state: GameStateData, player_id: int, plan: Dictionary) -> float:
	var move: Dictionary = plan.get("move", {})
	if move.is_empty():
		return 0.0

	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	if from_pos != opponent_base or to_pos == opponent_base:
		return 0.0

	# A bearer crowned on the base has to step off and back on anyway.
	var moving_piece: Piece = game_state.get_piece(from_pos)
	if moving_piece != null and moving_piece.has_crown:
		return 0.0
	if player_has_crown_plan(game_state, player_id):
		return SCORE_CLEAR_OWN_GOLEM_FROM_ENEMY_BASE
	return 0.0

## Any own golem but the bearer on the enemy base only stands in the bearer's
## way: nothing steps onto a square its own side holds.
func score_non_bearer_base_entry_penalty(game_state: GameStateData, player_id: int, move: Dictionary) -> float:
	if game_state == null or move.is_empty():
		return 0.0

	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	if to_pos != opponent_base:
		return 0.0
	if AIStateSimulator.is_own_crown_candidate(game_state.pieces, move, player_id):
		return 0.0
	if player_has_crown_plan(game_state, player_id):
		return -PENALTY_NON_BEARER_BASE_ENTRY
	return -PENALTY_NON_BEARER_BASE_ENTRY * 0.35

## A move by the player's crowned golem: the win when it steps onto the enemy
## base, otherwise its progress toward it.
func score_bearer_move(game_state: GameStateData, player_id: int, move: Dictionary) -> float:
	if !AIStateSimulator.is_own_crown_candidate(game_state.pieces, move, player_id):
		return score_non_bearer_base_entry_penalty(game_state, player_id, move)

	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	if to_pos == StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id):
		return SCORE_WIN
	return score_crown_base_progress(game_state, player_id, from_pos, to_pos)

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
	# On a turn the threats go unseen, the defensive modes have nothing to defend.
	if !sees_threats_this_turn and str(strategy_context.get("mode", "")) in ["soft_defense", "emergency_defense"]:
		return 0.0

	match str(strategy_context.get("mode", "")):
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

	var simulated_state: GameStateData = get_simulated_turn_plan_state(game_state, player_id, plan, board_size)
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
	return score

## With the crown on the board, everything goes into walking its bearer home.
func score_crown_push_strategy_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	if game_state == null or plan.is_empty():
		return 0.0
	var simulated_state: GameStateData = get_simulated_turn_plan_state(game_state, player_id, plan, board_size)
	if simulated_state.game_over:
		return 0.0
	return get_crown_race_value_delta(game_state, simulated_state, player_id, board_size) * CROWN_PUSH_STRATEGY_WEIGHT \
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
## its own price (score_own_drain_step).
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
	if score_own_drain_step(game_state, player_id, game_state.get_piece(from_pos), stamp, from_pos, to_pos, captured_piece, move, board_size) < 0.0:
		return 0.0
	var turns_before: float = get_golem_route_turns(game_state, player_id, from_pos, board_size)
	var turns_after: float = get_golem_route_turns(simulated_state, player_id, to_pos, board_size)
	if turns_after < 0.0 or (turns_before >= 0.0 and turns_after >= turns_before):
		return 0.0
	return 0.0 if is_square_attacked_by(simulated_state, 1 - player_id, to_pos, board_size) else SCORE_BEARER_SAFE_STEP

## The crown is (nearly) charged: walk golems into reach of the enemy base, so
## the crown has a bearer close to it. Scored by the bearer's route, or while
## the crown is not down, by that of the best golem to put it on; whether to
## put it down is the crown race's call.
func score_crown_staging_strategy_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	if game_state == null or plan.is_empty():
		return 0.0
	var simulated_state: GameStateData = get_simulated_turn_plan_state(game_state, player_id, plan, board_size)
	if simulated_state.game_over:
		return 0.0
	return get_crown_route_bonus(get_crown_staging_route_turns(simulated_state, player_id, board_size)) \
		- get_crown_route_bonus(get_crown_staging_route_turns(game_state, player_id, board_size))

func score_defense_strategy_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int, urgency: float) -> float:
	if game_state == null or plan.is_empty():
		return 0.0

	var simulated_state: GameStateData = get_simulated_turn_plan_state(game_state, player_id, plan, board_size)
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
	var enemy_crown_turns: int = get_crown_turns_to_ready(game_state, enemy_player_id)
	var enemy_crown_soon: bool = enemy_crown_turns <= 1
	var threat: float = 0.0
	for position_value in game_state.pieces:
		var pos: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != enemy_color:
			continue

		var distance: float = get_manhattan_distance(pos, own_base)
		if distance <= 3.0:
			threat += float(board_size) - distance
		if piece.has_crown:
			threat += 18.0
			if distance <= 3.0:
				threat += 24.0
		elif enemy_crown_soon and distance <= 2.0:
			threat += 8.0
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

func score_affix_setup(game_state: GameStateData, player_id: int, affix_action: Dictionary, board_size: int) -> float:
	return score_affix_setup_with_stamp_value_weight(game_state, player_id, affix_action, board_size, STAMP_VALUE_AFFIX_PLAY_WEIGHT)

func score_affix_setup_for_exchange(game_state: GameStateData, player_id: int, affix_action: Dictionary, board_size: int) -> float:
	return score_affix_setup_with_stamp_value_weight(game_state, player_id, affix_action, board_size, STAMP_VALUE_AFFIX_EXCHANGE_WEIGHT)

func score_affix_setup_with_stamp_value_weight(
	game_state: GameStateData,
	player_id: int,
	affix_action: Dictionary,
	board_size: int,
	stamp_value_weight: float
) -> float:
	var piece_pos: Vector2 = StampEffectResolver.as_vector2(affix_action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
	var piece: Piece = game_state.get_piece(piece_pos)
	if piece == null:
		return 0.0

	var stamp: Stamp = affix_action.get("stamp", null) as Stamp
	if stamp == null:
		stamp = get_cached_stamp(str(affix_action.get("stamp_name", "")))
	if stamp == null:
		return 0.0

	var score: float = SCORE_AFFIX_STAMP
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var setup_moves: Array[Vector2] = MoveRules.get_stamp_moves_for_piece(
		game_state.pieces,
		piece_pos,
		player_color,
		stamp,
		board_size,
		game_state.board_effects
	)
	score += float(setup_moves.size()) * SCORE_AFFIX_SETUP_MOBILITY
	if setup_moves.is_empty():
		score -= PENALTY_AFFIX_SETUP_NO_MOVE
	score += get_stamp_value_above_average(stamp) * stamp_value_weight
	score += score_bearer_stamp(game_state, player_id, piece, piece_pos, stamp, board_size)

	var setup_move: Dictionary = {
		"from": piece_pos,
		"to": piece_pos,
		"stamp": stamp,
		"requires_affix": true,
	}
	score += score_stamp_effect(game_state, player_id, piece, stamp, piece_pos, piece_pos, null, setup_move, board_size) * 0.65
	score -= score_affix_danger(game_state, player_id, affix_action, board_size, true)
	score -= score_covered_stamp_loss(piece, stamp_value_weight)
	score += score_se_tenant_grant_affix(game_state, player_id, stamp)
	return score

## What an Overseal throws away when it goes onto a golem that already has a
## stamp: the turns the covered stamp had left and, unless it is a Seeker that
## goes back to the codex, the stamp itself, at what it is still worth. Weighed
## like the new stamp's own value, so a nearly spent stamp costs little to
## cover, though never less than an empty golem.
func score_covered_stamp_loss(piece: Piece, stamp_value_weight: float) -> float:
	if piece == null or piece.affixed_stamp == null:
		return 0.0
	var loss: float = float(maxi(0, piece.turns_remaining)) * 2.0
	if !MoveRules.is_seeker_stamp(piece.affixed_stamp):
		var value_above_average: float = (get_stamp_remaining_value(piece.affixed_stamp, piece.turns_remaining) - stamp_value_fresh_mean) * STAMP_ESTIMATE_POINT_SCORE
		loss += SCORE_AFFIX_STAMP + value_above_average * stamp_value_weight
	return maxf(0.0, loss)

func score_move(game_state: GameStateData, player_id: int, move: Dictionary, board_size: int = BoardConfig.BOARD_SIZE) -> float:
	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var score: float = 0.0
	var moving_piece: Piece = game_state.get_piece(from_pos)
	if moving_piece == null:
		return -SCORE_WIN

	var stamp: Stamp = AIStateSimulator.get_stamp_for_candidate(game_state.pieces, move)
	var captured_piece: Piece = AIStateSimulator.get_captured_piece(game_state.pieces, move)

	if bool(move.get("requires_affix", false)):
		score += score_affixed_stamp(game_state, player_id, moving_piece, stamp, from_pos, to_pos, captured_piece, move, board_size)
	else:
		score += SCORE_USE_EXISTING_STAMP
		# The crown race sees a crown point move in the plan's simulated state.
		if stamp != null and !is_crown_point_effect(stamp):
			score += score_stamp_effect(game_state, player_id, moving_piece, stamp, from_pos, to_pos, captured_piece, move, board_size)

	if captured_piece != null:
		score += score_capture_at(game_state, captured_piece)
		score += score_capture_respawn_effect(game_state, captured_piece)
		score += score_base_staging_capture(game_state, player_id, captured_piece, to_pos, board_size)
		score += score_captured_trigger(game_state, player_id, move, captured_piece, board_size)

	score += score_repeat_last_move_penalty(game_state, player_id, move)
	# A capture that blows up the capturing golem ends the move there.
	if AIStateSimulator.capture_blows_up_capturer(game_state.pieces, move):
		return score
	score += score_bearer_move(game_state, player_id, move)
	score += score_center_control(to_pos, board_size)
	score += score_crown_threat(game_state, player_id, move, board_size)
	score -= score_danger_after_move(game_state, player_id, move, board_size)
	return score

func score_affixed_stamp(
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

	var score: float = SCORE_AFFIX_STAMP
	score += max(0, stamp.duration) * 3.0
	score += get_stamp_value_above_average(stamp) * STAMP_VALUE_AFFIX_PLAY_WEIGHT
	score += score_stamp_effect(game_state, player_id, moving_piece, stamp, from_pos, to_pos, captured_piece, move, board_size)
	return score

func score_capture(captured_piece: Piece) -> float:
	if captured_piece == null:
		return 0.0

	var score: float = SCORE_CAPTURE_PIECE + score_stamp_material(captured_piece)
	if captured_piece.has_crown:
		score += SCORE_CAPTURE_CROWN
	return score

## score_capture on the board: the on_expire effect the golem's stamp has still
## to set off goes with it (score_expiry_at_stake), though the stamp never
## counts below nothing.
func score_capture_at(game_state: GameStateData, captured_piece: Piece) -> float:
	return score_capture(captured_piece) + maxf(score_expiry_at_stake(game_state, captured_piece), -score_stamp_material(captured_piece))

## The on_expire effect a golem's stamp has still to set off, for its owner: what
## taking the golem spares them (a Ballista giving a stamp away) or costs them
## (a Nova's blast). A harmful one counts in full - the owner either pays it or
## leaves the stamp's last step unused - a helpful one only if the golem makes
## every step to it (DURATION_STEP_REACH_CHANCE each).
func score_expiry_at_stake(game_state: GameStateData, piece: Piece) -> float:
	if game_state == null or piece == null or piece.affixed_stamp == null or piece.turns_remaining <= 0:
		return 0.0
	var value: float = score_expiry_effect_for_owner(game_state, piece, piece.position, BoardConfig.BOARD_SIZE)
	if value <= 0.0:
		return value
	return value * pow(DURATION_STEP_REACH_CHANCE, piece.turns_remaining - 1)

## What the stamp on a golem is worth to its owner: a flat part plus the part
## of its estimate still ahead of it. A Seeker goes back to its owner's codex
## when taken, so only part of it is lost.
func score_stamp_material(piece: Piece) -> float:
	if piece == null or piece.affixed_stamp == null:
		return 0.0
	var value: float = get_stamp_remaining_value(piece.affixed_stamp, piece.turns_remaining) * STAMP_ESTIMATE_POINT_SCORE
	if MoveRules.is_seeker_stamp(piece.affixed_stamp):
		value *= SEEKER_CAPTURE_VALUE_SHARE
	return SCORE_CAPTURE_STAMP + value

## What the capture does to the victim's golems beyond the lost stamp. A
## captured golem respawns locked, unless its owner already has a locked one:
## then that one is freed and the captured golem leaves the board for good. So
## every first capture costs the victim a usable golem, every second one only
## thins the board out. The fewer usable golems the victim has left, the more a
## lock hurts: fewer pieces to stamp, and closer to having no legal action.
func score_capture_respawn_effect(game_state: GameStateData, captured_piece: Piece) -> float:
	if game_state == null or captured_piece == null:
		return 0.0
	# A locked golem just respawns locked again somewhere on its home row.
	if captured_piece.is_respawn_locked():
		return 0.0

	var victim_player_id: int = BoardConfig.get_player_id_for_color(captured_piece.color)
	if player_has_respawn_locked_golem(game_state, victim_player_id):
		return SCORE_CAPTURE_REMOVES_GOLEM

	var usable_after: int = count_usable_golems(game_state, victim_player_id) - 1
	return SCORE_CAPTURE_LOCKS_GOLEM + float(maxi(0, LOW_USABLE_GOLEM_COUNT - usable_after)) * SCORE_CAPTURE_GOLEM_SCARCITY

func player_has_respawn_locked_golem(game_state: GameStateData, player_id: int) -> bool:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null and piece.color == player_color and piece.is_respawn_locked():
			return true
	for pending_piece_value in game_state.pending_respawns.get(player_id, []):
		var pending_piece: Piece = pending_piece_value as Piece
		if pending_piece != null and pending_piece.is_respawn_locked():
			return true
	return false

func count_usable_golems(game_state: GameStateData, player_id: int) -> int:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var count: int = 0
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null and piece.color == player_color and !piece.is_respawn_locked():
			count += 1
	return count

func score_crown_base_progress(game_state: GameStateData, player_id: int, from_pos: Vector2, to_pos: Vector2) -> float:
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	return (get_manhattan_distance(from_pos, opponent_base) - get_manhattan_distance(to_pos, opponent_base)) * SCORE_CROWN_BASE_PROGRESS

## A stamp on the player's own crowned golem: worth most when it puts the base
## one step away, and a fair amount when it lasts the whole way there.
func score_bearer_stamp(game_state: GameStateData, player_id: int, piece: Piece, piece_pos: Vector2, stamp: Stamp, board_size: int) -> float:
	if game_state == null or stamp == null or !AIStateSimulator.is_crown_carrier_of(piece, player_id):
		return 0.0

	var route: Vector2 = get_base_route(game_state, player_id, stamp, piece_pos, board_size)
	if route.y < 0.0:
		return 0.0
	var steps: int = int(route.y)
	if steps == 1:
		return SCORE_CROWN_BASE_ENTRY_THREAT
	if stamp_outlasts_route(stamp, stamp.duration, steps):
		# Counts for as much as the route can be relied on.
		return (SCORE_CROWN_STAMP_IN_ROUTE + float(maxi(0, stamp.duration - steps)) * 32.0) * route.y / route.x
	return 0.0

## Taking an enemy golem the enemy could crown on their coming turn and walk
## onto the own base on the turn after: one whose stamp reaches the base, or a
## bare one a stamp from their open codex page would put a step away.
func score_base_staging_capture(game_state: GameStateData, player_id: int, captured_piece: Piece, captured_pos: Vector2, board_size: int) -> float:
	if game_state == null or captured_piece == null:
		return 0.0

	var opponent_player_id: int = 1 - player_id
	if BoardConfig.get_player_id_for_color(captured_piece.color) != opponent_player_id:
		return 0.0
	if !can_crown_next_turn(game_state, opponent_player_id):
		return 0.0
	var route_turns: float = get_golem_route_turns(game_state, opponent_player_id, captured_pos, board_size)
	if route_turns == 1.0 or captured_piece.affixed_stamp == null and route_turns == 2.0:
		return SCORE_CAPTURE_BASE_STAGING_PIECE
	return 0.0

func score_center_control(pos: Vector2, board_size: int) -> float:
	var center: Vector2 = Vector2(float(board_size - 1) / 2.0, float(board_size - 1) / 2.0)
	var distance: float = abs(pos.x - center.x) + abs(pos.y - center.y)
	return max(0.0, float(board_size) - distance) * SCORE_CENTER

func score_crown_threat(game_state: GameStateData, player_id: int, move: Dictionary, board_size: int) -> float:
	var simulated_pieces: Dictionary = AIStateSimulator.apply_candidate_to_pieces(game_state.pieces, move)
	var moved_to: Vector2 = AIStateSimulator.get_move_to(move)
	var enemy_bearer_pos: Vector2 = AIStateSimulator.find_crowned_position(simulated_pieces, 1 - player_id)
	if enemy_bearer_pos == INVALID_POS:
		return 0.0

	var next_moves: Array[Vector2] = MoveRules.get_piece_moves_for_player(
		simulated_pieces,
		moved_to,
		player_id,
		board_size,
		game_state.board_effects
	)
	if next_moves.has(enemy_bearer_pos):
		return SCORE_THREATEN_CROWN
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
	return score_threatened_piece_loss(threatened_piece, game_state)

func score_affix_danger(
	game_state: GameStateData,
	player_id: int,
	affix_action: Dictionary,
	board_size: int,
	simulate_effects: bool
) -> float:
	if game_state == null:
		return 0.0

	var piece_pos: Vector2 = StampEffectResolver.as_vector2(affix_action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
	var stamp: Stamp = affix_action.get("stamp", null) as Stamp
	if stamp == null:
		stamp = StampLibrary.get_stamp(str(affix_action.get("stamp_name", "")))
	if stamp == null:
		return 0.0

	var simulated_state: GameStateData = null
	var simulated_pieces: Dictionary = {}
	var simulated_board_effects: Array = []
	var affixed_piece: Piece = null
	if simulate_effects:
		simulated_state = AIStateSimulator.clone_game_state(game_state)
		AIStateSimulator.apply_affix_action(simulated_state, player_id, affix_action, board_size)
		if simulated_state.game_over:
			if simulated_state.winner_player == player_id:
				return 0.0
			return SCORE_WIN
		simulated_pieces = simulated_state.pieces
		simulated_board_effects = simulated_state.board_effects
		affixed_piece = simulated_state.get_piece(piece_pos)
	else:
		simulated_pieces = AIStateSimulator.clone_pieces(game_state.pieces)
		simulated_board_effects = game_state.board_effects
		affixed_piece = simulated_pieces.get(piece_pos, null) as Piece
		if affixed_piece != null:
			affixed_piece.affixed_stamp = stamp
			affixed_piece.turns_remaining = stamp.duration
			affixed_piece.exhausted_this_turn = true

	if affixed_piece == null or affixed_piece.affixed_stamp == null:
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

	return score_threatened_piece_loss(affixed_piece, threat_state)

func score_threatened_piece_loss(piece: Piece, game_state: GameStateData = null) -> float:
	if piece == null:
		return 0.0
	if piece.has_crown:
		return PENALTY_CROWN_THREATENED
	var loss: float = score_capture_at(game_state, piece) + score_capture_respawn_effect(game_state, piece)
	if game_state != null and MoveRules.is_se_tenant_stamp(piece.affixed_stamp):
		loss -= score_se_tenant_change(game_state, BoardConfig.get_player_id_for_color(piece.color), -1)
	loss -= score_on_captured_deterrent(game_state, piece)
	return maxf(PENALTY_PIECE_THREATENED, loss)

## What the captured stamp's on_captured effect does to the capturing player.
## It goes off with the capturing golem on the captured golem's square (see
## NetworkGameHost.handle_move_piece), so a bomb there takes that golem too.
func score_captured_trigger(game_state: GameStateData, player_id: int, move: Dictionary, captured_piece: Piece, board_size: int) -> float:
	var stamp: Stamp = captured_piece.affixed_stamp if captured_piece != null else null
	if stamp == null or !stamp.has_effect() or stamp.effect_trigger != StampEffect.TRIGGER_ON_CAPTURED:
		return 0.0
	if stamp.effect_type != StampEffect.TYPE_BOMB:
		var owner_value: float = score_on_captured_effect_for_owner(game_state, captured_piece)
		return owner_value if BoardConfig.get_player_id_for_color(captured_piece.color) == player_id else -owner_value

	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var score: float = 0.0
	for square: Vector2 in StampEffectResolver.get_effect_squares(stamp, to_pos, board_size, captured_piece.color):
		var target_piece: Piece = null
		if square == to_pos:
			target_piece = game_state.get_piece(from_pos)
		elif square != from_pos:
			target_piece = game_state.get_piece(square)
		if target_piece == null:
			continue
		var target_loss: float = score_capture_at(game_state, target_piece) + score_capture_respawn_effect(game_state, target_piece)
		if BoardConfig.get_player_id_for_color(target_piece.color) == player_id:
			score -= target_loss
		else:
			score += target_loss
	return score

## What a golem's on_captured effect is worth to its owner when it goes off.
## A bomb is left out: what it takes depends on the capturing golem.
func score_on_captured_effect_for_owner(game_state: GameStateData, piece: Piece) -> float:
	var stamp: Stamp = piece.affixed_stamp if piece != null else null
	if game_state == null or stamp == null or !stamp.has_effect() or stamp.effect_trigger != StampEffect.TRIGGER_ON_CAPTURED:
		return 0.0
	var owner_id: int = BoardConfig.get_player_id_for_color(piece.color)
	match stamp.effect_type:
		StampEffect.TYPE_INCREASE_OWN_DURATIONS:
			return score_duration_adjustment_effect(game_state, owner_id, owner_id, 1, piece)
		StampEffect.TYPE_INCREASE_ENEMY_DURATIONS:
			return score_duration_adjustment_effect(game_state, owner_id, 1 - owner_id, 1, piece)
		StampEffect.TYPE_DECREASE_OWN_DURATIONS:
			return score_duration_adjustment_effect(game_state, owner_id, owner_id, -1, piece)
		StampEffect.TYPE_DECREASE_ENEMY_DURATIONS:
			return score_duration_adjustment_effect(game_state, owner_id, 1 - owner_id, -1, piece)
		StampEffect.TYPE_GAIN_CROWN_POINT:
			return score_crown_point_effect(game_state, owner_id, owner_id, 1)
		StampEffect.TYPE_REMOVE_ENEMY_CROWN_POINT:
			return score_crown_point_effect(game_state, owner_id, 1 - owner_id, -1)
	return 0.0

## How much of a threatened golem's loss its on_captured effect pays back: a
## bomb on its own square takes the capturing golem (a stamped one, as it has
## to move), any other effect works for the owner.
func score_on_captured_deterrent(game_state: GameStateData, piece: Piece) -> float:
	var stamp: Stamp = piece.affixed_stamp if piece != null else null
	if !AIStateSimulator.is_on_captured_bomb(stamp):
		return score_on_captured_effect_for_owner(game_state, piece)
	if stamp.get_effect_offsets().has(Vector2.ZERO):
		# The capturer is not known yet: an average fresh stamp.
		return SCORE_CAPTURE_PIECE + SCORE_CAPTURE_STAMP + stamp_value_fresh_mean * STAMP_ESTIMATE_POINT_SCORE
	return 0.0

## A whole Se-tenant set keeps the crown meter full; this is what the player's
## standing gains (or loses) with delta Se-tenant golems more on the board.
## Losing one from a whole set drops the meter to 0.
func score_se_tenant_change(game_state: GameStateData, player_id: int, delta: int) -> float:
	if game_state == null or delta == 0:
		return 0.0
	var golem_count: int = game_state.count_se_tenant_golems(player_id)
	var set_size: int = GameStateData.SE_TENANT_SET_SIZE
	var points_value: float = float(int(game_state.crown_points.get(player_id, 0))) * SCORE_CROWN_POINT
	var full_meter_value: float = get_crown_hold_value() + get_se_tenant_progress_value(game_state, player_id, set_size)
	var before: float = full_meter_value if golem_count >= set_size else points_value + get_se_tenant_progress_value(game_state, player_id, golem_count)
	var after_count: int = maxi(0, golem_count + delta)
	var after: float = 0.0
	if after_count >= set_size:
		after = full_meter_value
	elif golem_count >= set_size:
		after = get_se_tenant_progress_value(game_state, player_id, after_count)
	else:
		after = points_value + get_se_tenant_progress_value(game_state, player_id, after_count)
	return after - before

## A Se-tenant set on its way: its share of filling the crown meter for good,
## while the codex still holds the stamps to finish it. A whole set is worth
## SCORE_SE_TENANT_WHOLE_SET on top of its full meter: no crown capture
## empties it, and it can move the crown every turn. With the crown already on
## the board a full meter only moves it, so then that is all the set is on
## its way to. Both on top of what its golems and stamps are worth as they
## build up (get_se_tenant_build_value).
func get_se_tenant_progress_value(game_state: GameStateData, player_id: int, golem_count: int) -> float:
	var set_size: int = GameStateData.SE_TENANT_SET_SIZE
	var build_value: float = get_se_tenant_build_value(game_state, player_id, golem_count)
	if golem_count >= set_size:
		return SCORE_SE_TENANT_WHOLE_SET + build_value
	if golem_count <= 0:
		return build_value
	var arrival_weight: float = get_se_tenant_arrival_weight(game_state, player_id, set_size - golem_count)
	if arrival_weight <= 0.0:
		return build_value
	var share: float = SE_TENANT_PROGRESS_SHARES[mini(golem_count, SE_TENANT_PROGRESS_SHARES.size() - 1)] * arrival_weight
	if game_state.has_crown_on_board(player_id):
		return SCORE_SE_TENANT_WHOLE_SET * share + build_value
	var points_value: float = float(int(game_state.crown_points.get(player_id, 0))) * SCORE_CROWN_POINT
	return maxf(0.0, get_crown_hold_value() - points_value) * share + build_value

## A set the codex can still finish: SCORE_SE_TENANT_SET_GOLEM for each of its
## golems on the board, and SCORE_SE_TENANT_SET_SOURCE for each stamp it still
## needs, by how soon that comes (get_se_tenant_sources); a whole set its three
## golems. It is what makes the AI put a Se-tenant on as soon as it has one -
## even the first of the set - bring its page round, run out the stamps that
## grant them and have a free slot on the open page for what they grant.
func get_se_tenant_build_value(game_state: GameStateData, player_id: int, golem_count: int) -> float:
	if !game_state.has_codex_for_player(player_id):
		return 0.0
	var missing: int = GameStateData.SE_TENANT_SET_SIZE - golem_count
	if missing <= 0:
		return float(GameStateData.SE_TENANT_SET_SIZE) * SCORE_SE_TENANT_SET_GOLEM
	var sources: Array[float] = get_se_tenant_sources(game_state, player_id)
	if sources.size() < missing:
		return 0.0
	var value: float = float(golem_count) * SCORE_SE_TENANT_SET_GOLEM
	for source_index in range(missing):
		value += sources[source_index] * SCORE_SE_TENANT_SET_SOURCE
	return value

## Whether the Se-tenant golems on the board and the stamps on their way
## (get_se_tenant_sources) are enough for a whole set.
func can_complete_se_tenant_set(game_state: GameStateData, player_id: int) -> bool:
	if !game_state.has_codex_for_player(player_id):
		return false
	return game_state.count_se_tenant_golems(player_id) + get_se_tenant_sources(game_state, player_id).size() >= GameStateData.SE_TENANT_SET_SIZE

## How soon the codex brings the missing Se-tenant stamps of a set: 1 when they
## are all on the open page, less the further off the last of them is (see
## get_se_tenant_sources), 0 when the codex does not hold enough. Without a
## codex the hand and the deck count, all at once.
func get_se_tenant_arrival_weight(game_state: GameStateData, player_id: int, missing: int) -> float:
	if missing <= 0:
		return 1.0
	if !game_state.has_codex_for_player(player_id):
		var found: int = 0
		for zone in [game_state.player_hands, game_state.player_decks]:
			for stamp_name_value in zone.get(player_id, []):
				if MoveRules.is_se_tenant_stamp(get_cached_stamp(str(stamp_name_value))):
					found += 1
		return 1.0 if found >= missing else 0.0

	var sources: Array[float] = get_se_tenant_sources(game_state, player_id)
	return sources[missing - 1] if sources.size() >= missing else 0.0

## How soon each Se-tenant stamp the player's set can still draw on comes, best
## first - each SE_TENANT_PAGE_WEIGHT less for every turn it is off:
## - one in the codex: a turn for each page turn to it;
## - one on its way from a grant (get_granted_se_tenant_stamp): on a golem, the
##   steps until its stamp runs out, one for each step it has left for a grant
##   on a step, or for a grant on a capture one turn at the chance of a capture
##   in the steps it has left; in the codex, the page turns to the granting
##   stamp and the steps it then needs (CAPTURE_CONTACT_CHANCE for a capture).
##   Both also by the page the new stamp lands on (get_codex_landing_weight),
##   and nothing with the codex full.
func get_se_tenant_sources(game_state: GameStateData, player_id: int) -> Array[float]:
	var cache_key: String = "%s|p%d" % [get_state_hash(game_state), player_id]
	if se_tenant_sources_cache.has(cache_key):
		return se_tenant_sources_cache[cache_key]

	var sources: Array[float] = []
	var landing_weight: float = get_codex_landing_weight(game_state, player_id, false)
	var open_index: int = get_effective_open_page_index(game_state, player_id)
	var pages: Array = game_state.get_codex_pages(player_id)
	for page_index in range(pages.size()):
		if !(pages[page_index] is Array):
			continue
		var page_turns: int = get_codex_page_distance(game_state, player_id, open_index, page_index)
		for stamp_name_value in pages[page_index]:
			var stamp: Stamp = get_cached_stamp(str(stamp_name_value))
			if MoveRules.is_se_tenant_stamp(stamp):
				sources.append(pow(SE_TENANT_PAGE_WEIGHT, page_turns))
			elif landing_weight > 0.0 and get_granted_se_tenant_stamp(stamp, player_id) != null:
				var weight: float = 0.0
				match stamp.effect_trigger:
					StampEffect.TRIGGER_ON_AFFIX:
						weight = pow(SE_TENANT_PAGE_WEIGHT, page_turns)
					StampEffect.TRIGGER_ON_MOVE:
						for step in range(1, get_grant_step_count(stamp, stamp.duration)):
							append_se_tenant_grant_source(sources, stamp, pow(SE_TENANT_PAGE_WEIGHT, page_turns + step) * landing_weight)
						weight = pow(SE_TENANT_PAGE_WEIGHT, page_turns + get_grant_step_count(stamp, stamp.duration))
					StampEffect.TRIGGER_ON_EXPIRE:
						if stamp.duration > 0:
							weight = pow(SE_TENANT_PAGE_WEIGHT, page_turns + stamp.duration)
					StampEffect.TRIGGER_ON_CAPTURE:
						weight = CAPTURE_CONTACT_CHANCE * pow(SE_TENANT_PAGE_WEIGHT, page_turns + 1)
				append_se_tenant_grant_source(sources, stamp, weight * landing_weight)

	if landing_weight > 0.0:
		var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
		for position_value in game_state.pieces:
			var piece: Piece = game_state.pieces[position_value] as Piece
			if piece == null or piece.color != player_color or get_granted_se_tenant_stamp(piece.affixed_stamp, player_id) == null:
				continue
			var stamp: Stamp = piece.affixed_stamp
			var weight: float = 0.0
			match stamp.effect_trigger:
				StampEffect.TRIGGER_ON_MOVE:
					for step in range(1, get_grant_step_count(stamp, piece.turns_remaining)):
						append_se_tenant_grant_source(sources, stamp, pow(SE_TENANT_PAGE_WEIGHT, step) * landing_weight)
					weight = pow(SE_TENANT_PAGE_WEIGHT, get_grant_step_count(stamp, piece.turns_remaining))
				StampEffect.TRIGGER_ON_EXPIRE:
					if stamp.duration > 0:
						weight = pow(SE_TENANT_PAGE_WEIGHT, maxi(1, piece.turns_remaining))
				StampEffect.TRIGGER_ON_CAPTURE:
					var capture_chance: float = minf(1.0, get_expected_captures(game_state, player_id, stamp, StampEffectResolver.as_vector2(position_value, INVALID_POS), piece.turns_remaining))
					weight = capture_chance * SE_TENANT_PAGE_WEIGHT
			append_se_tenant_grant_source(sources, stamp, weight * landing_weight)

	sources.sort()
	sources.reverse()
	se_tenant_sources_cache[cache_key] = sources
	return sources

## The steps a stamp that grants on each step still has to do it: the ones it
## has left, at most SE_TENANT_SET_SIZE, as more cannot add to one set.
func get_grant_step_count(stamp: Stamp, steps_left: int) -> int:
	if stamp.duration < 0:
		return GameStateData.SE_TENANT_SET_SIZE
	return clampi(steps_left, 1, GameStateData.SE_TENANT_SET_SIZE)

func append_se_tenant_grant_source(sources: Array[float], stamp: Stamp, weight: float) -> void:
	if weight <= 0.0:
		return
	for _copy in range(maxi(1, int(stamp.effect_settings.get("amount", 1)))):
		sources.append(weight)

## The Se-tenant stamp this stamp's grant glues into the player's own codex
## (Advocate a Sun, Consul a Moon, Logician a Bicycle), or null.
func get_granted_se_tenant_stamp(stamp: Stamp, player_id: int) -> Stamp:
	if stamp == null or !stamp.has_effect() or stamp.effect_type != StampEffect.TYPE_GRANT_STAMP:
		return null
	if int(stamp.effect_settings.get("target_player_id", player_id)) != player_id:
		return null
	var granted_stamp: Stamp = get_cached_stamp(str(stamp.effect_settings.get("stamp_name", stamp.stamp_name)))
	return granted_stamp if MoveRules.is_se_tenant_stamp(granted_stamp) else null

## Turning the page while the open page holds Se-tenant stamps the set still
## needs: PENALTY_SE_TENANT_LEFT_BEHIND for each, up to the number missing.
func score_se_tenant_page_turn(game_state: GameStateData, player_id: int) -> float:
	if !game_state.has_codex_for_player(player_id):
		return 0.0
	var missing: int = GameStateData.SE_TENANT_SET_SIZE - game_state.count_se_tenant_golems(player_id)
	if missing <= 0 or !can_complete_se_tenant_set(game_state, player_id):
		return 0.0
	var left_behind: int = 0
	for stamp_name_value in game_state.get_current_page(player_id):
		if MoveRules.is_se_tenant_stamp(get_cached_stamp(str(stamp_name_value))):
			left_behind += 1
	return -PENALTY_SE_TENANT_LEFT_BEHIND * float(mini(left_behind, missing))

## Putting on a stamp that grants a Se-tenant while the set can still be made
## whole: it starts that stamp on its way, so these go on first.
func score_se_tenant_grant_affix(game_state: GameStateData, player_id: int, stamp: Stamp) -> float:
	if get_granted_se_tenant_stamp(stamp, player_id) == null:
		return 0.0
	if game_state.count_se_tenant_golems(player_id) >= GameStateData.SE_TENANT_SET_SIZE or !can_complete_se_tenant_set(game_state, player_id):
		return 0.0
	return SCORE_SE_TENANT_GRANT_AFFIX

## The page the codex is open on at the player's next turn: the open one, or -
## when that is empty - the next one that is not, which the turn's start turns
## to (GameStateData.reset_turn_page_state).
func get_effective_open_page_index(game_state: GameStateData, player_id: int) -> int:
	var current_index: int = game_state.get_current_page_index(player_id)
	if game_state.has_stamps_on_page(player_id, current_index):
		return current_index
	var next_index: int = game_state.find_next_non_empty_page(player_id, current_index)
	return next_index if next_index != -1 else current_index

## Page turns from one page to another: one for each page with stamps on the
## way, as empty pages are passed over.
func get_codex_page_distance(game_state: GameStateData, player_id: int, from_index: int, to_index: int) -> int:
	var page_turns: int = 0
	var page_index: int = from_index
	for _step in range(DeckManager.CODEX_PAGE_COUNT):
		if page_index == to_index:
			break
		if game_state.has_stamps_on_page(player_id, page_index):
			page_turns += 1
		page_index = (page_index + 1) % DeckManager.CODEX_PAGE_COUNT
	return page_turns

## How soon a stamp glued into the codex comes up: SE_TENANT_PAGE_WEIGHT less
## for each page turn to the nearest free slot, where it lands
## (GameStateData.add_stamp_to_nearest_free_slot), 0 with the codex full. A
## grant that goes off now lands on the open page if it has room - an emptied
## one then stays open - one later from the page open by then.
func get_codex_landing_weight(game_state: GameStateData, player_id: int, goes_off_now: bool) -> float:
	var pages: Array = game_state.get_codex_pages(player_id)
	var start_index: int = game_state.get_current_page_index(player_id) if goes_off_now else get_effective_open_page_index(game_state, player_id)
	for offset in range(DeckManager.CODEX_PAGE_COUNT):
		var page_index: int = (start_index + offset) % DeckManager.CODEX_PAGE_COUNT
		if page_index >= pages.size():
			continue
		var page_size: int = (pages[page_index] as Array).size() if pages[page_index] is Array else 0
		if page_size < DeckManager.CODEX_STAMPS_PER_PAGE:
			return pow(SE_TENANT_PAGE_WEIGHT, get_codex_page_distance(game_state, player_id, start_index, page_index))
	return 0.0

## A move after which the golem's Se-tenant stamp runs out.
func is_se_tenant_expiring_move(moving_piece: Piece, move: Dictionary) -> bool:
	return moving_piece != null \
		and !bool(move.get("requires_affix", false)) \
		and MoveRules.is_se_tenant_stamp(moving_piece.affixed_stamp) \
		and moving_piece.turns_remaining == 1

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
	var fire_share: float = get_effect_fire_share(game_state, player_id, moving_piece, stamp, from_pos, to_pos, captured_piece, move)
	if fire_share > 0.0:
		score += score_effect_value(game_state, player_id, moving_piece, stamp, effect_source_pos, move, board_size)

		if stamp.effect_trigger == StampEffect.TRIGGER_ON_CAPTURE && captured_piece != null:
			score += 20.0
		if stamp.effect_trigger == StampEffect.TRIGGER_ON_MOVE:
			score += 8.0
		if stamp.effect_trigger == StampEffect.TRIGGER_ON_EXPIRE:
			score += 5.0
		score *= fire_share
	if to_pos == from_pos:
		score -= 10.0
	score += score_own_drain_step(game_state, player_id, moving_piece, stamp, from_pos, to_pos, captured_piece, move, board_size)

	return score

## Of an effect's value, the share a move or affix brings. An effect put on now
## counts in full, except an on_capture one that does not go off right away: it
## counts for the captures the golem can expect before the stamp runs out. On a
## golem that only moves, an effect counts when it goes off: on a step that
## takes nothing, on a capture, or when this step runs the stamp out.
func get_effect_fire_share(
	game_state: GameStateData,
	player_id: int,
	moving_piece: Piece,
	stamp: Stamp,
	from_pos: Vector2,
	to_pos: Vector2,
	captured_piece: Piece,
	move: Dictionary
) -> float:
	if bool(move.get("requires_affix", false)):
		if stamp.effect_trigger == StampEffect.TRIGGER_ON_MOVE and captured_piece != null:
			return 0.0
		if stamp.effect_trigger != StampEffect.TRIGGER_ON_CAPTURE or captured_piece != null:
			return 1.0
		# An affix with no step keeps every step for later.
		var steps_left: int = stamp.duration if from_pos == to_pos else stamp.duration - 1
		return get_expected_captures(game_state, player_id, stamp, to_pos, steps_left)
	match stamp.effect_trigger:
		StampEffect.TRIGGER_ON_MOVE:
			return 1.0 if captured_piece == null else 0.0
		StampEffect.TRIGGER_ON_CAPTURE:
			return 1.0 if captured_piece != null else 0.0
		StampEffect.TRIGGER_ON_EXPIRE:
			return 1.0 if moving_piece != null and moving_piece.turns_remaining == 1 else 0.0
	return 0.0

## The captures a golem with this stamp on this square can expect in its next
## steps_left steps. On each of its turns, every enemy golem it could take by
## then is a CAPTURE_CONTACT_CHANCE chance of one capture, and each later turn
## counts CAPTURE_CONTACT_TURN_DECAY of the one before: the enemy moves too, and
## the golem need not move every turn. So a stamp put on far from the enemy, as
## in the opening, expects little, and one put on in the thick of it a lot.
func get_expected_captures(game_state: GameStateData, player_id: int, stamp: Stamp, pos: Vector2, steps_left: int) -> float:
	if stamp.duration < 0:
		steps_left = CAPTURE_CONTACT_MAX_STEPS
	steps_left = mini(steps_left, CAPTURE_CONTACT_MAX_STEPS)
	if steps_left <= 0:
		return 0.0

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var reach_map: Dictionary = get_capture_reach_map(stamp, player_color, pos, steps_left, BoardConfig.BOARD_SIZE)
	var targets_by_step: Array[int] = []
	targets_by_step.resize(steps_left + 1)
	for position_value in game_state.pieces:
		var target: Piece = game_state.pieces[position_value] as Piece
		if !MoveRules.can_capture_target_piece(target, player_color):
			continue
		var reach_step: int = int(reach_map.get(StampEffectResolver.as_vector2(position_value, INVALID_POS), 0))
		if reach_step > 0:
			targets_by_step[reach_step] += 1

	var expected: float = 0.0
	var turn_weight: float = 1.0
	var targets_in_reach: int = 0
	for step in range(1, steps_left + 1):
		targets_in_reach += targets_by_step[step]
		expected += (1.0 - pow(1.0 - CAPTURE_CONTACT_CHANCE, targets_in_reach)) * turn_weight
		turn_weight *= CAPTURE_CONTACT_TURN_DECAY
	return expected

## Square -> the step on which a golem with this stamp, from this square, could
## first capture there, within max_steps steps. The steps on the way follow
## the stamp's non-capturing offsets and ignore what stands in the way, so the
## map depends only on the stamp, the side and the square, and stays cached.
func get_capture_reach_map(stamp: Stamp, player_color: int, from_pos: Vector2, max_steps: int, board_size: int) -> Dictionary:
	var cache_key: String = "%s|c%d|%s|%d" % [stamp.stamp_name, player_color, vector_hash(from_pos), max_steps]
	if capture_reach_cache.has(cache_key):
		return capture_reach_cache[cache_key]

	var walk_offsets: Array[Vector2] = []
	var capture_offsets: Array[Vector2] = []
	for movement_option: Dictionary in stamp.get_movement_options():
		var offset: Vector2 = movement_option.get("offset", Vector2.ZERO) * player_color
		var movement_type: int = int(movement_option.get("movement_type", StampEffect.MOVEMENT_NONE))
		if movement_type != StampEffect.MOVEMENT_CAPTURE_ONLY:
			walk_offsets.append(offset)
		if movement_type != StampEffect.MOVEMENT_MOVE_ONLY:
			capture_offsets.append(offset)

	var reach_map: Dictionary = {}
	var visited: Dictionary = {from_pos: true}
	var frontier: Array[Vector2] = [from_pos]
	for step in range(1, max_steps + 1):
		var next_frontier: Array[Vector2] = []
		for square: Vector2 in frontier:
			for offset: Vector2 in capture_offsets:
				var target: Vector2 = square + offset
				if MoveRules.is_valid_position(target, board_size) and !reach_map.has(target):
					reach_map[target] = step
			if step == max_steps:
				continue
			for offset: Vector2 in walk_offsets:
				var next_square: Vector2 = square + offset
				if MoveRules.is_valid_position(next_square, board_size) and !visited.has(next_square):
					visited[next_square] = true
					next_frontier.append(next_square)
		frontier = next_frontier

	capture_reach_cache[cache_key] = reach_map
	return reach_map

## What the stamp's effect does for the player when it goes off here, before
## the share of it the move or affix brings (see score_stamp_effect).
func score_effect_value(
	game_state: GameStateData,
	player_id: int,
	moving_piece: Piece,
	stamp: Stamp,
	effect_source_pos: Vector2,
	move: Dictionary,
	board_size: int
) -> float:
	var score: float = 0.0
	match stamp.effect_type:
		StampEffect.TYPE_INVISIBLE_TO_ENEMY:
			score += 32.0
			if moving_piece != null and moving_piece.has_crown:
				score += 80.0
		StampEffect.TYPE_STEAL_STAMP:
			score += 50.0
		StampEffect.TYPE_GRANT_STAMP:
			score += score_grant_stamp_effect(game_state, player_id, stamp)
		StampEffect.TYPE_GIVE_STAMP:
			score += score_give_stamp_effect(game_state, player_id, stamp)
		StampEffect.TYPE_MOVE_BASE:
			score += score_move_base_effect(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
		StampEffect.TYPE_INVALID_SQUARES:
			score += score_invalid_squares_effect(game_state, player_id, stamp, move, effect_source_pos, board_size)
		StampEffect.TYPE_FROZEN_SQUARES:
			score += score_frozen_squares_effect(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
		StampEffect.TYPE_BOMB:
			score += score_bomb_effect(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
		StampEffect.TYPE_UNCAPTURABLE:
			score += score_uncapturable_effect(moving_piece)
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
		StampEffect.TYPE_GAIN_CROWN_POINT:
			score += score_crown_point_effect(game_state, player_id, player_id, 1)
		StampEffect.TYPE_REMOVE_ENEMY_CROWN_POINT:
			score += score_crown_point_effect(game_state, player_id, 1 - player_id, -1)
		_:
			pass
	return score

## What a golem's on_expire effect does for its owner when its stamp runs out
## on its square. An expiry it sets off in turn is not followed.
func score_expiry_effect_for_owner(game_state: GameStateData, piece: Piece, piece_pos: Vector2, board_size: int) -> float:
	var stamp: Stamp = piece.affixed_stamp
	if scoring_expiry_effect or stamp == null or !stamp.has_effect() or stamp.effect_trigger != StampEffect.TRIGGER_ON_EXPIRE:
		return 0.0
	scoring_expiry_effect = true
	var expiry_move: Dictionary = {"from": piece_pos, "to": piece_pos, "stamp": stamp, "requires_affix": false}
	var owner_id: int = BoardConfig.get_player_id_for_color(piece.color)
	var value: float = score_effect_value(game_state, owner_id, piece, stamp, piece_pos, expiry_move, board_size)
	scoring_expiry_effect = false
	return value

## Every golem in the blast, the player's own against them, at what losing it
## costs. The golem that sets it off by a move still stands on the square it
## left in the state scored, so it counts only where the blast is centred.
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
		if target_piece == null or (target_piece == moving_piece and target_pos != source_pos):
			continue

		var target_player_id: int = BoardConfig.get_player_id_for_color(target_piece.color)
		var target_score: float = score_capture_at(game_state, target_piece) + score_capture_respawn_effect(game_state, target_piece)
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

		var target_player_id: int = BoardConfig.get_player_id_for_color(target_piece.color)
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

func get_effect_source_pos(stamp: Stamp, from_pos: Vector2, to_pos: Vector2) -> Vector2:
	if stamp.effect_trigger == StampEffect.TRIGGER_ON_MOVE \
		or stamp.effect_trigger == StampEffect.TRIGGER_ON_CAPTURE \
		or stamp.effect_trigger == StampEffect.TRIGGER_ON_EXPIRE:
		return to_pos
	return from_pos

func get_frozen_piece_score(game_state: GameStateData, piece: Piece, piece_pos: Vector2, target_player_id: int, board_size: int) -> float:
	var score: float = SCORE_FROZEN_ENEMY_PIECE
	score += score_stamp_material(piece) * 0.45
	if piece.has_crown:
		score += SCORE_CAPTURE_CROWN * 0.65

	var moves_before_freeze: Array[Vector2] = MoveRules.get_piece_moves_for_player(
		game_state.pieces,
		piece_pos,
		target_player_id,
		board_size,
		game_state.board_effects
	)
	score += float(moves_before_freeze.size()) * 4.0
	return score

func is_crown_point_effect(stamp: Stamp) -> bool:
	return stamp.effect_type == StampEffect.TYPE_GAIN_CROWN_POINT or stamp.effect_type == StampEffect.TYPE_REMOVE_ENEMY_CROWN_POINT

func stamp_effect_targets_player(stamp: Stamp, target_player_id: int) -> bool:
	var effect_target_player_id: int = int(stamp.effect_settings.get("target_player_id", -1))
	return effect_target_player_id == -1 || effect_target_player_id == target_player_id

func score_uncapturable_effect(piece: Piece) -> float:
	var score: float = 46.0
	if piece != null and piece.has_crown:
		score += 120.0
	return score

## A crown point effect is worth one point of the crown race to the player:
## their own point gained, or the opponent's taken away. Nothing when the
## meter has no room to move.
func score_crown_point_effect(game_state: GameStateData, player_id: int, target_player_id: int, delta: int) -> float:
	var points: int = int(game_state.crown_points.get(target_player_id, 0))
	if (delta > 0 and points >= game_state.crown_points_required) or (delta < 0 and points <= 0):
		return 0.0
	var side: float = 1.0 if target_player_id == player_id else -1.0
	return SCORE_CROWN_POINT * float(delta) * side

## One step more (delta 1) or less (-1) on each of the target's stamped golems
## (see get_duration_step_value). excluded_piece is left out: a captured golem
## is off the board by the time its on_captured effect works.
func score_duration_adjustment_effect(game_state: GameStateData, player_id: int, target_player_id: int, delta: int, excluded_piece: Piece = null) -> float:
	var target_color: int = StampEffectResolver.get_color_for_player_id(target_player_id)
	var helps_player: bool = (delta > 0) == (target_player_id == player_id)
	var score: float = 0.0
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece == excluded_piece or piece.color != target_color or piece.affixed_stamp == null or piece.turns_remaining <= 0:
			continue
		var step_value: float = get_duration_step_value(game_state, piece, StampEffectResolver.as_vector2(position_value, INVALID_POS), delta)
		score += step_value if helps_player else -step_value
	return score

## What one step more (delta 1) or less (-1) on the golem's stamp is worth to
## its owner. The step comes at the end of the stamp, so it only counts if the
## golem makes every step before it - DURATION_STEP_REACH_CHANCE for each - and
## the stamp's later steps are worth less (its estimate's T(D)). A stamp on its
## last step gains the most: a +1 keeps it from running out on the golem's next
## move, a -1 ends it at once, and either way decides whether the golem stands
## bare, waiting a turn for a new stamp. Ended at once, its on_expire effect
## goes off: a Black Hole's -1 sets off the Nova next to it.
func get_duration_step_value(game_state: GameStateData, piece: Piece, piece_pos: Vector2, delta: int) -> float:
	var turns: int = piece.turns_remaining
	var step: int = turns + 1 if delta > 0 else turns
	var step_value: float = (get_stamp_remaining_value(piece.affixed_stamp, step) - get_stamp_remaining_value(piece.affixed_stamp, step - 1)) * STAMP_ESTIMATE_POINT_SCORE
	var value: float = step_value * pow(DURATION_STEP_REACH_CHANCE, step - 1)
	# What hangs on the stamp running out comes on its last step.
	var expiry_value: float = SCORE_DURATION_SAVES_EXPIRY if turns == 1 else 0.0
	if piece.has_crown:
		expiry_value += SCORE_DURATION_CROWN_BEARER
	value += expiry_value * pow(DURATION_STEP_REACH_CHANCE, turns - 1)
	if delta < 0 and turns == 1:
		value -= score_expiry_effect_for_owner(game_state, piece, piece_pos, BoardConfig.BOARD_SIZE)
	return value

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

## What taking the golem is worth to the attacker, less what its on_captured
## effect pays back (a bomb takes the capturing golem along).
func get_piece_target_score(piece: Piece, game_state: GameStateData = null) -> float:
	return maxf(0.0, score_capture_at(game_state, piece) - score_on_captured_deterrent(game_state, piece))

## Estimate points still ahead of a stamp with turns_left turns to go (see
## Docs/Balance/STAMP_VALUE.md): its movement part over those turns, and the
## effects that fire on every step or capture. The rest of the estimate is left
## to the scoring that sees the board: on_affix effects have fired once the
## stamp is on, and on_captured, on_expire, crown conditions and the Se-tenant
## set are scored where they happen, for whoever they help.
static func get_stamp_remaining_value(stamp: Stamp, turns_left: int) -> float:
	if stamp == null:
		return 0.0
	var parts: Dictionary = stamp_value_parts.get(stamp.stamp_name, {})
	if parts.is_empty():
		parts = calculate_stamp_value_parts(stamp, StampValueCalculator.load_weights())
	var turns: float = float(parts.duration) if stamp.duration < 0 else float(maxi(0, turns_left))
	return float(parts.movement) * pow(turns, float(parts.exponent)) + float(parts.effect_per_turn) * turns

static func get_stamp_fresh_value(stamp: Stamp) -> float:
	return get_stamp_remaining_value(stamp, stamp.duration) if stamp != null else 0.0

## A fresh stamp's value on the score scale, against the average enabled stamp.
func get_stamp_value_above_average(stamp: Stamp) -> float:
	if stamp == null:
		return 0.0
	return (get_stamp_fresh_value(stamp) - stamp_value_fresh_mean) * STAMP_ESTIMATE_POINT_SCORE

## M × S, the exponent of T(D), D and the per-turn value of the effects that
## repeat, out of the estimate's breakdown.
static func calculate_stamp_value_parts(stamp: Stamp, weights: StampValueWeights) -> Dictionary:
	var breakdown: StampValueCalculator.Breakdown = StampValueCalculator.calculate(stamp, weights)
	var repeating_value: float = 0.0
	for effect: Dictionary in breakdown.effects:
		var trigger: String = str(effect.get("trigger", ""))
		if trigger == StampEffect.TRIGGER_ON_MOVE or trigger == StampEffect.TRIGGER_ON_CAPTURE:
			repeating_value += float(effect.get("value", 0.0))
	return {
		"movement": breakdown.movement * breakdown.role_factor,
		"exponent": weights.duration_exponent,
		"duration": breakdown.duration,
		"effect_per_turn": repeating_value / breakdown.duration if breakdown.duration > 0.0 else 0.0,
	}

## Works out every library stamp's parts once, on the main thread, so the
## parallel scoring only reads them.
static func prepare_stamp_values() -> void:
	if !stamp_value_parts.is_empty() or OS.get_thread_caller_id() != OS.get_main_thread_id():
		return
	var weights: StampValueWeights = StampValueCalculator.load_weights()
	var fresh_total: float = 0.0
	var enabled_count: int = 0
	for stamp_value in StampLibrary.all_stamps.values():
		var stamp: Stamp = stamp_value as Stamp
		if stamp == null:
			continue
		stamp_value_parts[stamp.stamp_name] = calculate_stamp_value_parts(stamp, weights)
		if stamp.enabled:
			fresh_total += get_stamp_fresh_value(stamp)
			enabled_count += 1
	stamp_value_fresh_mean = fresh_total / float(maxi(1, enabled_count))
