extends RefCounted
class_name AIScoringContext

## What all of the AI's scoring shares, one per evaluator: the knobs the scoring
## reads (aggression, whether the threats are seen this turn, the strategy mode),
## the stamp and simulated-state caches, and the hashes those and the search's
## caches are keyed by. AIMoveEvaluator builds it with its scoring modules and
## sets the knobs; a worker evaluator has its own, so no thread shares a cache.

const SCORE_WIN: float = 100000.0
const INVALID_POS: Vector2 = Vector2(-1, -1)

## How readily the AI goes for the base: an earlier switch to the crown attack
## (AIStrategyDirector) and crowning golems farther from the enemy base (see
## AIReach.get_crown_hold_value). A style knob, not a strength one - low levels get the
## most, so they are weak by leaving holes rather than by never attacking.
var aggression: float = 0.5
## Whether the AI looks at the opponent's threats against its base this turn.
var sees_threats_this_turn: bool = true
var simulated_state_cache: Dictionary = {}
var stamp_cache: Dictionary = {}
var strategy_context: Dictionary = {}

func get_terminal_score_for_player(game_state: GameStateData, player_id: int) -> float:
	if game_state == null or !game_state.game_over:
		return 0.0
	if game_state.winner_player == player_id:
		return SCORE_WIN
	return -SCORE_WIN

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
