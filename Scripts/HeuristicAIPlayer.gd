extends RefCounted
class_name HeuristicAIPlayer

const AI_TURN_PLANNER_SCRIPT = preload("res://Scripts/AITurnPlanner.gd")
const BOARD_SIZE: int = BoardConfig.BOARD_SIZE

var player_id: int = 1
var action_delay: float = 0.35
var evaluator: AIMoveEvaluator
var planner

func _init(new_player_id: int = 1, ai_difficulty_level: int = AIMoveEvaluator.DEFAULT_DIFFICULTY_LEVEL):
	player_id = new_player_id
	evaluator = AIMoveEvaluator.new(ai_difficulty_level)
	planner = AI_TURN_PLANNER_SCRIPT.new()

func can_play_turn(host: NetworkGameHost) -> bool:
	return host != null \
		&& host.game_state != null \
		&& !host.game_state.game_over \
		&& host.game_state.current_turn_player == player_id

func play_turn(host: NetworkGameHost, tree: SceneTree) -> bool:
	if !can_play_turn(host):
		return false

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

	var profile: Dictionary = selected_plan.get("profile", {}).duplicate()
	profile["own_planner_ms"] = own_planner_ms
	evaluator.last_profile = profile
	AIPerformanceCsvLogger.log_decision(host.game_state, player_id, profile, selected_plan)
	return !selected_plan.is_empty()

func choose_plan_threaded(host: NetworkGameHost, tree: SceneTree) -> Dictionary:
	if host == null or host.game_state == null or evaluator == null:
		return {}

	var state_snapshot: GameStateData = AIStateSimulator.clone_game_state(host.game_state)
	var thread_args: Dictionary = {
		"game_state": state_snapshot,
		"player_id": player_id,
		"difficulty_level": evaluator.difficulty_level,
		"board_size": BOARD_SIZE,
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
	var difficulty_level: int = int(thread_args.get("difficulty_level", AIMoveEvaluator.DEFAULT_DIFFICULTY_LEVEL))
	var board_size: int = int(thread_args.get("board_size", BOARD_SIZE))
	return choose_plan_on_main_thread(game_state, thread_player_id, difficulty_level, board_size)

func choose_plan_on_main_thread(
	game_state: GameStateData,
	thread_player_id: int = -1,
	difficulty_level: int = -1,
	board_size: int = BOARD_SIZE
) -> Dictionary:
	if game_state == null:
		return {}

	var effective_player_id: int = player_id if thread_player_id == -1 else thread_player_id
	var effective_difficulty: int = evaluator.difficulty_level if difficulty_level == -1 else difficulty_level
	var thread_evaluator: AIMoveEvaluator = AIMoveEvaluator.new(effective_difficulty)
	var thread_planner = AI_TURN_PLANNER_SCRIPT.new()
	var selected_plan: Dictionary = thread_planner.choose_planned_turn(game_state, effective_player_id, thread_evaluator, board_size)
	return strip_thread_plan_values(selected_plan)

func strip_thread_plan_values(value):
	if value is Dictionary:
		var source_dict: Dictionary = value
		var output_dict: Dictionary = {}
		for key in source_dict:
			if str(key) == "card":
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

	var selected_plan: Dictionary = evaluator.choose_best_turn_plan(host.game_state, player_id, turn_plans, BOARD_SIZE, planner)
	var profile: Dictionary = evaluator.last_profile.duplicate()
	profile["own_planner_ms"] = own_planner_ms
	profile["own_turn_plan_count"] = turn_plans.size()
	AIPerformanceCsvLogger.log_decision(host.game_state, player_id, profile, selected_plan)
	return selected_plan

func get_turn_plans(host: NetworkGameHost) -> Array[Dictionary]:
	if planner == null:
		return []
	return planner.create_turn_plans(host, player_id, BOARD_SIZE)

func execute_turn_plan(host: NetworkGameHost, tree: SceneTree, selected_plan: Dictionary) -> bool:
	if planner == null:
		return false
	return await planner.execute_turn_plan(host, tree, player_id, selected_plan, action_delay)

func choose_turn_move(host: NetworkGameHost) -> Dictionary:
	var valid_moves: Array[Dictionary] = get_valid_turn_moves(host)
	if valid_moves.is_empty():
		return {}

	return evaluator.choose_best_move(host.game_state, player_id, valid_moves, BOARD_SIZE)

func get_valid_turn_moves(host: NetworkGameHost) -> Array[Dictionary]:
	var valid_moves: Array[Dictionary] = []
	if host == null or host.game_state == null:
		return valid_moves

	if bool(host.game_state.moved_piece_this_turn.get(player_id, false)):
		return valid_moves

	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	var can_attach_card: bool = true
	var hand_cards: Array[Card] = host.get_hand_cards_for_player(player_id)
	return MoveRules.get_valid_turn_moves(
		host.game_state.pieces,
		player_color,
		hand_cards,
		can_attach_card,
		BOARD_SIZE,
		host.game_state.board_effects
	)

func execute_turn_move(host: NetworkGameHost, tree: SceneTree, selected_move: Dictionary) -> bool:
	if host == null or host.game_state == null or host.game_state.game_over:
		return false

	if selected_move.is_empty():
		end_turn(host)
		return false

	if bool(selected_move.get("requires_attach", false)):
		var card: Card = selected_move.get("card", null) as Card
		if card == null:
			return false

		host.on_player_action({
			"type": "attach_card",
			"player_id": player_id,
			"card_name": card.card_name,
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
