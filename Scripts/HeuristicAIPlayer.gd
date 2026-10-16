extends RefCounted
class_name HeuristicAIPlayer

const AI_TURN_PLANNER_SCRIPT = preload("res://Scripts/AITurnPlanner.gd")
const AI_STRATEGY_DIRECTOR_SCRIPT = preload("res://Scripts/AIStrategyDirector.gd")
const BOARD_SIZE: int = BoardConfig.BOARD_SIZE
## Seconds from the start of an AI turn to its closing action, rolled once per
## turn from [x, y] by difficulty level and spread over the turn's actions
## (see AITurnPlanner.begin_turn_pacing). Level 1 is deliberately quick.
const TURN_DELAY_RANGES: Dictionary = {
	1: Vector2(0.0, 4.0),
	2: Vector2(9.0, 14.0),
	3: Vector2(8.0, 13.0),
	4: Vector2(7.0, 12.0),
	5: Vector2(6.0, 11.0),
	6: Vector2(5.0, 10.0),
	7: Vector2(4.0, 9.0),
	8: Vector2(3.0, 8.0),
	9: Vector2(2.0, 7.0),
	10: Vector2(2.0, 6.0),
	11: Vector2(1.0, 5.0),
	12: Vector2(0.0, 4.0),
}

var player_id: int = 1
var action_delay: float = 0.35
var turn_delay_enabled: bool = true
var evaluator
var planner
var strategy_director
var strategy_memory: Dictionary = {}
## Stamp names affixed during the last completed turn, in play order. Read by
## the boss dialogue director so a boss can react to putting down a specific
## stamp; nothing in the AI itself depends on it.
var last_turn_affixed_stamp_names: Array[String] = []

# Owned exclusively by the AI-thinking call chain (choose_plan_threaded's
# background thread, or its same-thread fallback) and never touched by the
# main thread while that thread is alive, so reusing them across turns is
# safe even though GDScript dictionaries aren't thread-safe under concurrent
# access. Persisting them (instead of building fresh ones every turn) is what
# lets AIMoveEvaluator's internal caches (stamp_cache, seeker_route_cache)
# actually carry over between turns.
var _persistent_thread_evaluator
var _persistent_thread_planner

func _init(new_player_id: int = 1, ai_difficulty_level: int = 12):
	configure(new_player_id, ai_difficulty_level)

func configure(new_player_id: int = 1, ai_difficulty_level: int = 12) -> void:
	player_id = new_player_id
	var evaluator_script = load("res://Scripts/AIMoveEvaluator.gd")
	evaluator = evaluator_script.new()
	evaluator.set_difficulty_level(ai_difficulty_level)
	planner = AI_TURN_PLANNER_SCRIPT.new()
	strategy_director = AI_STRATEGY_DIRECTOR_SCRIPT.new()
	strategy_memory = {}

func can_play_turn(host: NetworkGameHost) -> bool:
	return host != null \
		&& host.game_state != null \
		&& !host.game_state.game_over \
		&& host.game_state.current_turn_player == player_id

func play_turn(host: NetworkGameHost, tree: SceneTree) -> bool:
	if !can_play_turn(host):
		return false

	# Started before planning so the thinking time counts toward the turn's pause.
	planner.begin_turn_pacing(roll_turn_delay_seconds())
	var planner_start_usec: int = Time.get_ticks_usec()
	var selected_plan: Dictionary = await choose_plan_threaded(host, tree)
	var own_planner_ms: float = float(Time.get_ticks_usec() - planner_start_usec) / 1000.0
	if selected_plan.is_empty():
		selected_plan = await execute_planned_turn(host, tree)
		own_planner_ms = float(Time.get_ticks_usec() - planner_start_usec) / 1000.0
	elif !can_play_turn(host):
		return false
	else:
		await execute_turn_plan(host, tree, selected_plan)

	# A plan the host partly rejected leaves the turn open. The step-by-step
	# fallback (turn page, affix, move, end turn) always closes it.
	if can_play_turn(host):
		var fallback_plan: Dictionary = await execute_sequential_turn(host, tree)
		if selected_plan.is_empty():
			selected_plan = fallback_plan
		else:
			var combined_actions: Array = selected_plan.get("actions", []).duplicate()
			combined_actions.append_array(fallback_plan.get("actions", []))
			selected_plan["actions"] = combined_actions

	last_turn_affixed_stamp_names = collect_affixed_stamp_names(selected_plan)
	var profile: Dictionary = selected_plan.get("profile", {}).duplicate()
	profile["own_planner_ms"] = own_planner_ms
	evaluator.last_profile = profile
	update_strategy_memory_from_profile(profile)
	AIPerformanceCsvLogger.log_decision(host.game_state, player_id, profile, selected_plan)
	return !selected_plan.is_empty()

func roll_turn_delay_seconds() -> float:
	if !turn_delay_enabled or evaluator == null:
		return 0.0
	var delay_range: Vector2 = TURN_DELAY_RANGES.get(int(evaluator.difficulty_level), Vector2.ZERO)
	return randf_range(delay_range.x, delay_range.y)

func collect_affixed_stamp_names(plan: Dictionary) -> Array[String]:
	var stamp_names: Array[String] = []
	for action_value in plan.get("actions", []):
		if !(action_value is Dictionary):
			continue
		var action: Dictionary = action_value
		if str(action.get("type", "")) != AITurnPlanner.ACTION_AFFIX_STAMP:
			continue
		var stamp_name: String = str(action.get("stamp_name", "")).strip_edges()
		if !stamp_name.is_empty():
			stamp_names.append(stamp_name)
	return stamp_names

func choose_plan_threaded(host: NetworkGameHost, tree: SceneTree) -> Dictionary:
	if host == null or host.game_state == null or evaluator == null:
		return {}

	var state_snapshot: GameStateData = AIStateSimulator.clone_game_state(host.game_state)
	var thread_args: Dictionary = {
		"game_state": state_snapshot,
		"player_id": player_id,
		"difficulty_level": evaluator.difficulty_level,
		"board_size": BOARD_SIZE,
		"strategy_memory": strategy_memory.duplicate(),
	}
	var ai_thread: Thread = Thread.new()
	var start_error: int = ai_thread.start(Callable(self, "_choose_plan_thread").bind(thread_args))
	if start_error != OK:
		push_warning("Could not start AI planning thread. Falling back to main-thread planning.")
		return choose_plan_on_main_thread(state_snapshot)

	if tree == null:
		var blocking_result = ai_thread.wait_to_finish()
		return blocking_result if blocking_result is Dictionary else {}

	while ai_thread.is_alive():
		await tree.process_frame

	var result = ai_thread.wait_to_finish()
	return result if result is Dictionary else {}

func _choose_plan_thread(thread_args: Dictionary) -> Dictionary:
	var game_state: GameStateData = thread_args.get("game_state", null) as GameStateData
	var thread_player_id: int = int(thread_args.get("player_id", player_id))
	var difficulty_level: int = int(thread_args.get("difficulty_level", 12))
	var board_size: int = int(thread_args.get("board_size", BOARD_SIZE))
	var thread_strategy_memory: Dictionary = thread_args.get("strategy_memory", {}).duplicate()
	return choose_plan_on_main_thread(game_state, thread_player_id, difficulty_level, board_size, thread_strategy_memory)

func choose_plan_on_main_thread(
	game_state: GameStateData,
	thread_player_id: int = -1,
	difficulty_level: int = -1,
	board_size: int = BOARD_SIZE,
	planning_strategy_memory: Dictionary = {}
) -> Dictionary:
	if game_state == null:
		return {}

	var effective_player_id: int = player_id if thread_player_id == -1 else thread_player_id
	var effective_difficulty: int = evaluator.difficulty_level if difficulty_level == -1 else difficulty_level
	var effective_strategy_memory: Dictionary = strategy_memory.duplicate() if planning_strategy_memory.is_empty() else planning_strategy_memory.duplicate()
	var thread_evaluator = get_persistent_thread_evaluator(effective_difficulty)
	var thread_strategy_director = AI_STRATEGY_DIRECTOR_SCRIPT.new()
	thread_evaluator.set_strategy_context(thread_strategy_director.evaluate_strategy(game_state, effective_player_id, effective_strategy_memory, board_size))
	var thread_planner = get_persistent_thread_planner()
	var selected_plan: Dictionary = thread_planner.choose_planned_turn(game_state, effective_player_id, thread_evaluator, board_size)
	return strip_thread_plan_values(selected_plan)

func get_persistent_thread_evaluator(difficulty_level: int):
	if _persistent_thread_evaluator == null:
		var evaluator_script = load("res://Scripts/AIMoveEvaluator.gd")
		_persistent_thread_evaluator = evaluator_script.new()
	_persistent_thread_evaluator.set_difficulty_level(difficulty_level)
	return _persistent_thread_evaluator

func get_persistent_thread_planner():
	if _persistent_thread_planner == null:
		_persistent_thread_planner = AI_TURN_PLANNER_SCRIPT.new()
	return _persistent_thread_planner

func strip_thread_plan_values(value):
	if value is Dictionary:
		var source_dict: Dictionary = value
		var output_dict: Dictionary = {}
		for key in source_dict:
			if str(key) == "stamp":
				continue
			output_dict[key] = strip_thread_plan_values(source_dict[key])
		return output_dict
	if value is Array:
		var source_array: Array = value
		var output_array: Array = []
		for item in source_array:
			output_array.append(strip_thread_plan_values(item))
		return output_array
	return value

func execute_planned_turn(host: NetworkGameHost, tree: SceneTree) -> Dictionary:
	if planner == null:
		return {}
	prepare_strategy_context(host.game_state, evaluator)
	return await planner.execute_planned_turn(host, tree, player_id, evaluator, action_delay, BOARD_SIZE)

func execute_sequential_turn(host: NetworkGameHost, tree: SceneTree) -> Dictionary:
	if planner == null:
		return {}
	return await planner.execute_sequential_turn(host, tree, player_id, evaluator, action_delay, BOARD_SIZE)

func choose_turn_plan(host: NetworkGameHost) -> Dictionary:
	var planner_start_usec: int = Time.get_ticks_usec()
	var turn_plans: Array[Dictionary] = get_turn_plans(host)
	var own_planner_ms: float = float(Time.get_ticks_usec() - planner_start_usec) / 1000.0
	if turn_plans.is_empty():
		return {}

	prepare_strategy_context(host.game_state, evaluator)
	var selected_plan: Dictionary = evaluator.choose_best_turn_plan(host.game_state, player_id, turn_plans, BOARD_SIZE, planner)
	var profile: Dictionary = evaluator.last_profile.duplicate()
	profile["own_planner_ms"] = own_planner_ms
	profile["own_turn_plan_count"] = turn_plans.size()
	update_strategy_memory_from_profile(profile)
	AIPerformanceCsvLogger.log_decision(host.game_state, player_id, profile, selected_plan)
	return selected_plan

func get_turn_plans(host: NetworkGameHost) -> Array[Dictionary]:
	if planner == null:
		var empty_plans: Array[Dictionary] = []
		return empty_plans
	return planner.create_turn_plans(host, player_id, BOARD_SIZE)

func execute_turn_plan(host: NetworkGameHost, tree: SceneTree, selected_plan: Dictionary) -> bool:
	if planner == null:
		return false
	return await planner.execute_turn_plan(host, tree, player_id, selected_plan, action_delay)

func choose_turn_move(host: NetworkGameHost) -> Dictionary:
	var valid_moves: Array[Dictionary] = get_valid_turn_moves(host)
	if valid_moves.is_empty():
		return {}

	prepare_strategy_context(host.game_state, evaluator)
	return evaluator.choose_best_move(host.game_state, player_id, valid_moves, BOARD_SIZE)

func prepare_strategy_context(game_state: GameStateData, target_evaluator) -> Dictionary:
	if game_state == null or target_evaluator == null:
		return {}
	if strategy_director == null:
		strategy_director = AI_STRATEGY_DIRECTOR_SCRIPT.new()
	var context: Dictionary = strategy_director.evaluate_strategy(game_state, player_id, strategy_memory, BOARD_SIZE)
	target_evaluator.set_strategy_context(context)
	return context

func update_strategy_memory_from_profile(profile: Dictionary) -> void:
	var profile_memory: Dictionary = profile.get("strategy_memory", {})
	if profile_memory.is_empty():
		return
	strategy_memory = profile_memory.duplicate()

func get_valid_turn_moves(host: NetworkGameHost) -> Array[Dictionary]:
	var valid_moves: Array[Dictionary] = []
	if host == null or host.game_state == null:
		return valid_moves

	if bool(host.game_state.moved_piece_this_turn.get(player_id, false)):
		return valid_moves

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var can_affix_stamp: bool = true
	var hand_stamps: Array[Stamp] = host.get_hand_stamps_for_player(player_id)
	return MoveRules.get_valid_turn_moves(
		host.game_state.pieces,
		player_color,
		hand_stamps,
		can_affix_stamp,
		BOARD_SIZE,
		host.game_state.board_effects
	)

func execute_turn_move(host: NetworkGameHost, tree: SceneTree, selected_move: Dictionary) -> bool:
	if host == null or host.game_state == null or host.game_state.game_over:
		return false

	if selected_move.is_empty():
		end_turn(host)
		return false

	if bool(selected_move.get("requires_affix", false)):
		var stamp: Stamp = selected_move.get("stamp", null) as Stamp
		if stamp == null:
			return false

		host.on_player_action({
			"type": "affix_stamp",
			"player_id": player_id,
			"stamp_name": stamp.stamp_name,
			"piece_pos": AIStateSimulator.get_move_from(selected_move),
			"hand_index": -1,
		})

		if host.game_state.game_over:
			return true
		if tree != null and action_delay > 0.0:
			await tree.create_timer(action_delay).timeout

	host.on_player_action({
		"type": "move_piece",
		"player_id": player_id,
		"from": AIStateSimulator.get_move_from(selected_move),
		"to": AIStateSimulator.get_move_to(selected_move),
	})
	if host.game_state.game_over:
		return true
	if tree != null and action_delay > 0.0:
		await tree.create_timer(action_delay).timeout
	end_turn(host)
	return true

func end_turn(host: NetworkGameHost) -> void:
	if host == null or host.game_state == null or host.game_state.game_over:
		return
	if host.game_state.current_turn_player != player_id:
		return
	host.on_player_action({
		"type": "end_turn",
		"player_id": player_id,
	})
