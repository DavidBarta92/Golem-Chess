extends RefCounted
class_name AITurnPlanner

const DEFAULT_BOARD_SIZE: int = BoardConfig.BOARD_SIZE
const ACTION_AFFIX_STAMP: String = "affix_stamp"
const ACTION_TURN_PAGE: String = "turn_page"
const ACTION_MOVE_PIECE: String = "move_piece"
const ACTION_END_TURN: String = "end_turn"
const MAX_SEQUENTIAL_AFFIX_ACTIONS: int = DeckManager.HAND_SIZE
const MAX_PLAN_AFFIX_DEPTH: int = DeckManager.HAND_SIZE
const MAX_PLAN_AFFIX_OPTIONS_PER_STATE: int = 2
const MAX_PLAN_EXCHANGE_OPTIONS: int = 1
const MAX_GENERATED_TURN_PLANS: int = 120
const AFFIX_ACTION_DELAY: float = 1.00
const TACTICAL_SEARCH_SCRIPT = preload("res://Scripts/AITacticalSearch.gd")

## A pacing pause is starting before one of the AI's actions. Lets the match
## show the opponent thinking (see OpponentThinkingChatter).
signal thinking_pause_started(player_id: int, seconds: float)

var planning_evaluator: AIMoveEvaluator = null
var tactical_search = TACTICAL_SEARCH_SCRIPT.new()

# Per-turn pacing budget (see begin_turn_pacing). Planning time and the
# post-action animation delays count toward it, so it is measured from the
# turn's start instead of being added on top of them.
var turn_pacing_start_msec: int = 0
var turn_pacing_total_seconds: float = 0.0
var turn_pacing_scheduled_seconds: float = 0.0

func execute_planned_turn(
	host: NetworkGameHost,
	tree: SceneTree,
	player_id: int,
	evaluator: AIMoveEvaluator,
	action_delay: float,
	board_size: int = DEFAULT_BOARD_SIZE
) -> Dictionary:
	if host == null or host.game_state == null or host.game_state.game_over or evaluator == null:
		return {}

	var selected_plan: Dictionary = choose_planned_turn(host.game_state, player_id, evaluator, board_size)
	if selected_plan.is_empty():
		return await execute_sequential_turn(host, tree, player_id, evaluator, action_delay, board_size)

	await execute_turn_plan(host, tree, player_id, selected_plan, action_delay)
	return selected_plan

func choose_planned_turn(
	game_state: GameStateData,
	player_id: int,
	evaluator: AIMoveEvaluator,
	board_size: int = DEFAULT_BOARD_SIZE
) -> Dictionary:
	if game_state == null or game_state.game_over or evaluator == null:
		return {}

	evaluator.begin_decision()
	planning_evaluator = evaluator
	var tactical_plan: Dictionary = tactical_search.find_forced_tactical_plan(game_state, player_id, evaluator, board_size)
	if !tactical_plan.is_empty():
		var tactical_profile: Dictionary = evaluator.create_profile(1)
		tactical_profile["best_plan_type"] = str(tactical_plan.get("plan_type", "tactical"))
		tactical_profile["best_plan_score"] = AIMoveEvaluator.SCORE_WIN
		tactical_plan["profile"] = tactical_profile
		planning_evaluator = null
		return tactical_plan

	var turn_plans: Array[Dictionary] = create_turn_plans_from_state(game_state, player_id, board_size)
	if turn_plans.is_empty():
		planning_evaluator = null
		return {}

	var selected_plan: Dictionary = evaluator.choose_best_turn_plan(game_state, player_id, turn_plans, board_size, self)
	if selected_plan.is_empty():
		planning_evaluator = null
		return {}

	var selected_profile: Dictionary = evaluator.last_profile.duplicate()
	selected_profile["own_turn_plan_count"] = turn_plans.size()
	selected_plan["profile"] = selected_profile
	planning_evaluator = null
	return selected_plan

func execute_sequential_turn(
	host: NetworkGameHost,
	tree: SceneTree,
	player_id: int,
	evaluator: AIMoveEvaluator,
	action_delay: float,
	board_size: int = DEFAULT_BOARD_SIZE
) -> Dictionary:
	var selected_actions: Array[Dictionary] = []
	var setup_affix_actions: Array[Dictionary] = []
	var selected_move: Dictionary = {}
	var profile: Dictionary = evaluator.create_profile(0) if evaluator != null else {}
	var turned_page: bool = false
	var affix_actions_played: int = 0
	var best_score_seen: float = -INF

	if host == null or host.game_state == null or host.game_state.game_over or evaluator == null:
		return create_sequential_plan(selected_actions, selected_move, setup_affix_actions, best_score_seen, profile)

	evaluator.begin_decision()
	while can_continue_sequential_turn(host, player_id):
		if affix_actions_played < MAX_SEQUENTIAL_AFFIX_ACTIONS:
			var best_affix: Dictionary = find_best_affix_setup(host.game_state, player_id, evaluator, board_size, profile)
			var affix_action: Dictionary = best_affix.get("action", {})
			var affix_threshold: float = -INF if int(host.game_state.completed_turn_counts.get(player_id, 0)) == 0 else get_affix_setup_threshold(host.game_state, player_id)
			best_score_seen = max(best_score_seen, float(best_affix.get("score", -INF)))
			# With no piece able to move, affixing is the only thing that unlocks
			# the end-turn button, so the best stamp goes down even if it scores low.
			var must_affix: bool = affix_actions_played == 0 \
				and !host.can_move_any_piece_for_player(player_id) \
				and !host.can_end_turn_by_button(player_id)
			# An empty action means nothing on this page fits: fall through to turning the page.
			if !affix_action.is_empty() and (float(best_affix.get("score", -INF)) >= affix_threshold or must_affix):
				setup_affix_actions.append(affix_action)
				await execute_ai_action(host, tree, affix_action, action_delay, selected_actions)
				affix_actions_played += 1
				continue

		if !turned_page and host.can_turn_page_for_player(player_id) and has_free_affix_piece(host.game_state, player_id):
			var turn_page_action: Dictionary = make_turn_page_action(player_id)
			await execute_ai_action(host, tree, turn_page_action, action_delay, selected_actions)
			turned_page = true
			continue

		break

	if can_continue_sequential_turn(host, player_id):
		selected_move = find_best_existing_move(host.game_state, player_id, evaluator, board_size, profile)
		if !selected_move.is_empty():
			await execute_ai_action(host, tree, make_move_action(player_id, selected_move), action_delay, selected_actions)

	if can_continue_sequential_turn(host, player_id) and host.can_end_turn_by_button(player_id):
		await execute_ai_action(host, tree, make_end_turn_action(player_id), action_delay, selected_actions)

	# Nothing legal is left (no move, nothing to affix, no page to turn, and the
	# end-turn exceptions don't apply): pass rather than sit on the turn forever.
	if can_continue_sequential_turn(host, player_id):
		var forced_end_action: Dictionary = make_end_turn_action(player_id)
		await wait_turn_pacing_before_action(host, tree, forced_end_action)
		if host.force_end_turn_for_ai(player_id):
			selected_actions.append(forced_end_action)

	return create_sequential_plan(selected_actions, selected_move, setup_affix_actions, best_score_seen, profile)

func can_continue_sequential_turn(host: NetworkGameHost, player_id: int) -> bool:
	return host != null \
		&& host.game_state != null \
		&& !host.game_state.game_over \
		&& host.game_state.current_turn_player == player_id

func execute_ai_action(
	host: NetworkGameHost,
	tree: SceneTree,
	action: Dictionary,
	action_delay: float,
	selected_actions: Array[Dictionary]
) -> void:
	await wait_turn_pacing_before_action(host, tree, action)
	if !can_continue_sequential_turn(host, int(action.get("player_id", -1))):
		return
	host.on_player_action(make_executable_action(action))
	selected_actions.append(action.duplicate())
	var delay: float = get_ai_action_delay(action, action_delay)
	if tree != null and delay > 0.0:
		await tree.create_timer(delay).timeout

## Rolls this turn's whole pause up front. Each action before the closing one
## then takes a random slice of what is left, and the closing action (the move,
## the end-turn button, or the stamp that auto-ends the first turn) waits out
## the rest. A total of zero turns pacing off.
func begin_turn_pacing(total_seconds: float) -> void:
	turn_pacing_start_msec = Time.get_ticks_msec()
	turn_pacing_total_seconds = maxf(total_seconds, 0.0)
	turn_pacing_scheduled_seconds = 0.0

func wait_turn_pacing_before_action(host: NetworkGameHost, tree: SceneTree, action: Dictionary) -> void:
	if tree == null or turn_pacing_total_seconds <= 0.0:
		return

	if action_closes_turn(host, action):
		turn_pacing_scheduled_seconds = turn_pacing_total_seconds
	else:
		var remaining_seconds: float = maxf(turn_pacing_total_seconds - turn_pacing_scheduled_seconds, 0.0)
		turn_pacing_scheduled_seconds += randf_range(0.0, remaining_seconds)

	var elapsed_seconds: float = float(Time.get_ticks_msec() - turn_pacing_start_msec) / 1000.0
	var wait_seconds: float = turn_pacing_scheduled_seconds - elapsed_seconds
	if wait_seconds > 0.0:
		thinking_pause_started.emit(int(action.get("player_id", -1)), wait_seconds)
		await tree.create_timer(wait_seconds).timeout

func action_closes_turn(host: NetworkGameHost, action: Dictionary) -> bool:
	match str(action.get("type", "")):
		ACTION_MOVE_PIECE, ACTION_END_TURN:
			return true
		ACTION_AFFIX_STAMP:
			# NetworkGameHost.handle_affix_stamp ends the first turn on the last hand stamp.
			var player_id: int = int(action.get("player_id", -1))
			return host != null \
				and host.game_state != null \
				and host.is_first_turn_for_player(player_id) \
				and int(host.game_state.affixed_stamp_count_this_turn.get(player_id, 0)) + 1 >= DeckManager.HAND_SIZE
	return false

func create_sequential_plan(
	actions: Array[Dictionary],
	move: Dictionary,
	setup_affix_actions: Array[Dictionary],
	best_score: float,
	profile: Dictionary
) -> Dictionary:
	if !profile.is_empty():
		profile["best_plan_score"] = best_score if best_score != -INF else 0.0
		profile["best_plan_type"] = "sequential"
	return {
		"actions": actions,
		"move": move,
		"setup_affix_actions": setup_affix_actions,
		"plan_type": "sequential",
		"profile": profile,
	}

func find_best_affix_setup(
	game_state: GameStateData,
	player_id: int,
	evaluator: AIMoveEvaluator,
	board_size: int,
	profile: Dictionary = {}
) -> Dictionary:
	var best_action: Dictionary = {}
	var best_score: float = -INF
	var hand_names: Array = game_state.player_hands.get(player_id, [])
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)

	for hand_index in range(hand_names.size()):
		var stamp_name: String = str(hand_names[hand_index])
		var stamp: Stamp = StampLibrary.get_stamp(stamp_name)
		if stamp == null or !MoveRules.stamp_can_be_used(stamp):
			continue

		for position_value in game_state.pieces:
			var piece_pos: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
			var piece: Piece = game_state.pieces[position_value] as Piece
			if piece == null or piece.color != player_color or !piece.can_receive_stamp():
				continue
			if !MoveRules.can_affix_stamp_for_turn(game_state.pieces, player_color, stamp):
				continue

			var affix_action: Dictionary = make_affix_action(player_id, stamp, piece_pos, hand_index)
			var affix_score: float = evaluator.score_affix_setup(game_state, player_id, affix_action, board_size)
			increment_profile_count(profile, "evaluated_own_plans")
			if best_action.is_empty() or affix_score > best_score:
				best_action = affix_action
				best_score = affix_score

	return {
		"action": best_action,
		"score": best_score,
	}

func find_exchange_action_for_worst_stamp(
	game_state: GameStateData,
	player_id: int,
	evaluator: AIMoveEvaluator,
	board_size: int,
	profile: Dictionary = {}
) -> Dictionary:
	var hand_names: Array = game_state.player_hands.get(player_id, [])
	var worst_hand_index: int = -1
	var worst_stamp_name: String = ""
	var worst_score: float = INF

	for hand_index in range(hand_names.size()):
		var stamp_name: String = str(hand_names[hand_index])
		var stamp_score: float = score_best_fit_for_stamp(game_state, player_id, stamp_name, hand_index, evaluator, board_size, profile)
		if worst_hand_index == -1 or stamp_score < worst_score:
			worst_hand_index = hand_index
			worst_stamp_name = stamp_name
			worst_score = stamp_score

	if worst_hand_index == -1:
		return {}

	return make_exchange_action(player_id, worst_stamp_name, worst_hand_index)

func score_best_fit_for_stamp(
	game_state: GameStateData,
	player_id: int,
	stamp_name: String,
	hand_index: int,
	evaluator: AIMoveEvaluator,
	board_size: int,
	profile: Dictionary = {}
) -> float:
	var stamp: Stamp = StampLibrary.get_stamp(stamp_name)
	if stamp == null or !MoveRules.stamp_can_be_used(stamp):
		return -INF

	var best_score: float = -INF
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	for position_value in game_state.pieces:
		var piece_pos: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != player_color or piece.affixed_stamp != null:
			continue

		var affix_action: Dictionary = make_affix_action(player_id, stamp, piece_pos, hand_index)
		var affix_score: float = evaluator.score_affix_setup_for_exchange(game_state, player_id, affix_action, board_size)
		increment_profile_count(profile, "evaluated_own_plans")
		best_score = max(best_score, affix_score)

	return best_score

func get_affix_setup_threshold(game_state: GameStateData, player_id: int) -> float:
	var free_piece_count: int = count_free_affix_pieces(game_state, player_id)
	if free_piece_count >= 6:
		return 7.0
	if free_piece_count == 5:
		return 8.0
	if free_piece_count == 4:
		return 10.0
	if free_piece_count == 3:
		return 12.0
	if free_piece_count == 2:
		return 14.0
	return 16.0

func has_free_affix_piece(game_state: GameStateData, player_id: int) -> bool:
	return count_free_affix_pieces(game_state, player_id) > 0

func count_free_affix_pieces(game_state: GameStateData, player_id: int) -> int:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var count: int = 0
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null and piece.color == player_color and piece.can_receive_stamp():
			count += 1
	return count

func find_best_existing_move(
	game_state: GameStateData,
	player_id: int,
	evaluator: AIMoveEvaluator,
	board_size: int,
	profile: Dictionary = {}
) -> Dictionary:
	if bool(game_state.moved_piece_this_turn.get(player_id, false)):
		return {}

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_stamp_moves(
		game_state.pieces,
		player_color,
		board_size,
		game_state.board_effects
	)
	if valid_moves.is_empty():
		return {}

	increment_profile_count(profile, "own_turn_plan_count", valid_moves.size())
	return evaluator.choose_best_move_with_response(game_state, player_id, valid_moves, board_size, self, profile)

func create_turn_plans(host: NetworkGameHost, player_id: int, board_size: int = DEFAULT_BOARD_SIZE) -> Array[Dictionary]:
	if host == null or host.game_state == null or host.game_state.game_over:
		var empty_plans: Array[Dictionary] = []
		return empty_plans

	return create_turn_plans_from_state(host.game_state, player_id, board_size)

func create_turn_plans_from_state(game_state: GameStateData, player_id: int, board_size: int = DEFAULT_BOARD_SIZE) -> Array[Dictionary]:
	var plans: Array[Dictionary] = []
	if game_state == null or game_state.game_over:
		return plans

	var root_state: GameStateData = AIStateSimulator.clone_game_state(game_state)
	var root_actions: Array[Dictionary] = []
	var root_setup_actions: Array[Dictionary] = []
	add_sequential_turn_plan_branches(
		plans,
		root_state,
		player_id,
		root_actions,
		root_setup_actions,
		0,
		board_size
	)

	return plans

func add_sequential_turn_plan_branches(
	plans: Array[Dictionary],
	game_state: GameStateData,
	player_id: int,
	prefix_actions: Array[Dictionary],
	setup_affix_actions: Array[Dictionary],
	affix_depth: int,
	board_size: int
) -> void:
	if plans.size() >= MAX_GENERATED_TURN_PLANS or game_state == null or game_state.game_over:
		return

	add_current_state_finish_plans(plans, game_state, player_id, prefix_actions, setup_affix_actions, board_size)
	if plans.size() >= MAX_GENERATED_TURN_PLANS:
		return

	if can_turn_page_in_plan(game_state, player_id) and prefix_actions.is_empty():
		var turn_page_state: GameStateData = AIStateSimulator.clone_game_state(game_state)
		var turn_page_action: Dictionary = make_turn_page_action(player_id)
		AIStateSimulator.apply_turn_page_action(turn_page_state, player_id)
		if bool(turn_page_state.has_turned_page_this_turn.get(player_id, false)):
			var turn_page_prefix: Array[Dictionary] = duplicate_actions(prefix_actions)
			turn_page_prefix.append(turn_page_action)
			add_sequential_turn_plan_branches(
				plans,
				turn_page_state,
				player_id,
				turn_page_prefix,
				duplicate_actions(setup_affix_actions),
				affix_depth,
				board_size
			)

	if affix_depth >= MAX_PLAN_AFFIX_DEPTH:
		return

	var affix_actions: Array[Dictionary] = get_ranked_affix_actions_for_state(game_state, player_id, board_size)
	for affix_action: Dictionary in affix_actions:
		if plans.size() >= MAX_GENERATED_TURN_PLANS:
			return

		var next_state: GameStateData = AIStateSimulator.clone_game_state(game_state)
		var piece_pos: Vector2 = StampEffectResolver.as_vector2(affix_action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
		AIStateSimulator.apply_affix_action(next_state, player_id, affix_action, board_size)
		var affixed_piece: Piece = next_state.get_piece(piece_pos)
		if affixed_piece == null or affixed_piece.affixed_stamp == null:
			continue

		var next_prefix: Array[Dictionary] = duplicate_actions(prefix_actions)
		next_prefix.append(affix_action)
		var next_setup: Array[Dictionary] = duplicate_actions(setup_affix_actions)
		next_setup.append(affix_action)
		add_sequential_turn_plan_branches(
			plans,
			next_state,
			player_id,
			next_prefix,
			next_setup,
			affix_depth + 1,
			board_size
		)

func add_current_state_finish_plans(
	plans: Array[Dictionary],
	game_state: GameStateData,
	player_id: int,
	prefix_actions: Array[Dictionary],
	setup_affix_actions: Array[Dictionary],
	board_size: int
) -> void:
	if plans.size() >= MAX_GENERATED_TURN_PLANS:
		return

	var is_first_turn: bool = int(game_state.completed_turn_counts.get(player_id, 0)) == 0
	if is_first_turn and !setup_affix_actions.is_empty():
		var setup_only_actions: Array[Dictionary] = duplicate_actions(prefix_actions)
		setup_only_actions.append(make_end_turn_action(player_id))
		plans.append(create_plan(setup_only_actions, {}, duplicate_actions(setup_affix_actions), "setup_only"))
		return

	if bool(game_state.moved_piece_this_turn.get(player_id, false)):
		return

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_stamp_moves(
		game_state.pieces,
		player_color,
		board_size,
		game_state.board_effects
	)
	for move: Dictionary in valid_moves:
		if plans.size() >= MAX_GENERATED_TURN_PLANS:
			return

		var move_actions: Array[Dictionary] = duplicate_actions(prefix_actions)
		move_actions.append(make_move_action(player_id, move))
		var plan_type: String = "setup_move" if !setup_affix_actions.is_empty() else "move"
		plans.append(create_plan(move_actions, move, duplicate_actions(setup_affix_actions), plan_type))

	# With nothing able to move, a turn can only close through the end-turn
	# button, which needs a frozen or freshly stamped piece. Without these plans
	# the planner finds nothing and the AI stalls.
	if !is_first_turn and valid_moves.is_empty() and can_end_turn_without_move_in_plan(game_state, player_id, board_size):
		var end_turn_actions: Array[Dictionary] = duplicate_actions(prefix_actions)
		end_turn_actions.append(make_end_turn_action(player_id))
		var end_plan_type: String = "setup_end_turn" if !setup_affix_actions.is_empty() else "end_turn"
		plans.append(create_plan(end_turn_actions, {}, duplicate_actions(setup_affix_actions), end_plan_type))

## Mirrors NetworkGameHost.can_end_turn_due_to_frozen_piece for a simulated state.
func can_end_turn_without_move_in_plan(game_state: GameStateData, player_id: int, board_size: int) -> bool:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	if MoveRules.has_valid_piece_move(game_state.pieces, player_color, board_size, game_state.board_effects):
		return false
	return MoveRules.has_frozen_movable_piece(game_state.pieces, player_color, board_size, game_state.board_effects)

func get_ranked_affix_actions_for_state(game_state: GameStateData, player_id: int, board_size: int) -> Array[Dictionary]:
	var hand_stamps: Array[Stamp] = AIStateSimulator.get_hand_stamps_from_state(game_state, player_id)
	var affix_actions: Array[Dictionary] = get_affix_actions_for_pieces(game_state.pieces, player_id, hand_stamps)
	var scored_actions: Array[Dictionary] = []
	for affix_action: Dictionary in affix_actions:
		var score: float = 0.0
		if planning_evaluator != null:
			score = planning_evaluator.score_affix_setup(game_state, player_id, affix_action, board_size)
		scored_actions.append({
			"action": affix_action,
			"score": score,
		})
	scored_actions.sort_custom(Callable(self, "sort_scored_action_desc"))

	var ranked_actions: Array[Dictionary] = []
	var action_count: int = mini(MAX_PLAN_AFFIX_OPTIONS_PER_STATE, scored_actions.size())
	for index in range(action_count):
		ranked_actions.append(scored_actions[index].get("action", {}))
	return ranked_actions

func get_exchange_actions_for_state(game_state: GameStateData, player_id: int, board_size: int) -> Array[Dictionary]:
	var hand_names: Array = game_state.player_hands.get(player_id, [])
	var scored_actions: Array[Dictionary] = []
	for hand_index in range(hand_names.size()):
		var stamp_name: String = str(hand_names[hand_index])
		var score: float = 0.0
		if planning_evaluator != null:
			score = score_best_fit_for_stamp(game_state, player_id, stamp_name, hand_index, planning_evaluator, board_size)
		scored_actions.append({
			"action": make_exchange_action(player_id, stamp_name, hand_index),
			"score": score,
		})
	scored_actions.sort_custom(Callable(self, "sort_scored_action_asc"))

	var exchange_actions: Array[Dictionary] = []
	var action_count: int = mini(MAX_PLAN_EXCHANGE_OPTIONS, scored_actions.size())
	for index in range(action_count):
		exchange_actions.append(scored_actions[index].get("action", {}))
	return exchange_actions

func can_exchange_in_plan(game_state: GameStateData, player_id: int) -> bool:
	return false

func can_turn_page_in_plan(game_state: GameStateData, player_id: int) -> bool:
	return game_state != null and game_state.can_turn_page(player_id)

func sort_scored_action_desc(left: Dictionary, right: Dictionary) -> bool:
	return float(left.get("score", 0.0)) > float(right.get("score", 0.0))

func sort_scored_action_asc(left: Dictionary, right: Dictionary) -> bool:
	return float(left.get("score", 0.0)) < float(right.get("score", 0.0))

func add_branch_plans(
	plans: Array[Dictionary],
	game_state: GameStateData,
	player_id: int,
	pieces: Dictionary,
	hand_stamps: Array[Stamp],
	prefix_actions: Array[Dictionary],
	can_move: bool,
	can_affix: bool,
	board_size: int
) -> void:
	if can_affix:
		var affix_actions: Array[Dictionary] = get_affix_actions_for_pieces(pieces, player_id, hand_stamps)
		for affix_action: Dictionary in affix_actions:
			var affix_only_actions: Array[Dictionary] = duplicate_actions(prefix_actions)
			affix_only_actions.append(affix_action)
			plans.append(create_plan(affix_only_actions, {}, [affix_action], "affix_only"))

	if !can_move:
		return

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_valid_turn_moves(
		pieces,
		player_color,
		hand_stamps,
		can_affix,
		board_size,
		game_state.board_effects
	)

	for move: Dictionary in valid_moves:
		var move_actions: Array[Dictionary] = duplicate_actions(prefix_actions)
		if bool(move.get("requires_affix", false)):
			var move_affix_action: Dictionary = make_affix_action(player_id, get_move_stamp(move), AIStateSimulator.get_move_from(move))
			move_actions.append(move_affix_action)

		move_actions.append(make_move_action(player_id, move))
		plans.append(create_plan(move_actions, move, [], "move"))


func add_move_then_affix_plans(
	plans: Array[Dictionary],
	game_state: GameStateData,
	player_id: int,
	hand_stamps: Array[Stamp],
	prefix_actions: Array[Dictionary],
	move: Dictionary,
	_board_size: int
) -> void:
	var simulated_pieces: Dictionary = AIStateSimulator.apply_candidate_to_pieces(game_state.pieces, move)
	var affix_actions: Array[Dictionary] = get_affix_actions_for_pieces(simulated_pieces, player_id, hand_stamps)
	for affix_action: Dictionary in affix_actions:
		var actions: Array[Dictionary] = duplicate_actions(prefix_actions)
		actions.append(make_move_action(player_id, move))
		actions.append(affix_action)
		plans.append(create_plan(actions, move, [affix_action], "move_then_affix"))

func get_affix_actions_for_pieces(pieces: Dictionary, player_id: int, hand_stamps: Array[Stamp]) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	for position_value in pieces:
		var piece_position: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = pieces[position_value] as Piece
		if piece == null or piece.color != player_color or !piece.can_receive_stamp():
			continue

		for stamp: Stamp in hand_stamps:
			if !MoveRules.stamp_can_be_used(stamp):
				continue
			if !MoveRules.can_affix_stamp_for_turn(pieces, player_color, stamp):
				continue
			actions.append(make_affix_action(player_id, stamp, piece_position))

	return actions

func execute_turn_plan(host: NetworkGameHost, tree: SceneTree, player_id: int, plan: Dictionary, action_delay: float) -> bool:
	if host == null or host.game_state == null or host.game_state.game_over:
		return false

	var actions: Array = plan.get("actions", [])
	if actions.is_empty():
		return false

	for action_value in actions:
		if host.game_state.game_over or host.game_state.current_turn_player != player_id:
			return true

		var action: Dictionary = action_value
		await wait_turn_pacing_before_action(host, tree, action)
		if host.game_state.game_over or host.game_state.current_turn_player != player_id:
			return true
		host.on_player_action(make_executable_action(action))

		if host.game_state.game_over or host.game_state.current_turn_player != player_id:
			return true
		var delay: float = get_ai_action_delay(action, action_delay)
		if tree != null and delay > 0.0:
			await tree.create_timer(delay).timeout

	if can_continue_sequential_turn(host, player_id) and host.can_end_turn_by_button(player_id):
		var end_turn_action: Dictionary = make_end_turn_action(player_id)
		await wait_turn_pacing_before_action(host, tree, end_turn_action)
		if can_continue_sequential_turn(host, player_id):
			host.on_player_action(make_executable_action(end_turn_action))

	return true

func create_plan(actions: Array[Dictionary], move: Dictionary, setup_affix_actions: Array, plan_type: String) -> Dictionary:
	return {
		"actions": actions,
		"move": move,
		"setup_affix_actions": setup_affix_actions,
		"plan_type": plan_type,
	}

func make_affix_action(player_id: int, stamp: Stamp, piece_pos: Vector2, hand_index: int = -1) -> Dictionary:
	return {
		"type": ACTION_AFFIX_STAMP,
		"player_id": player_id,
		"stamp_name": stamp.stamp_name if stamp != null else "",
		"piece_pos": piece_pos,
		"hand_index": hand_index,
		"stamp": stamp,
	}

func make_exchange_action(player_id: int, stamp_name: String, hand_index: int) -> Dictionary:
	return {
		"type": ACTION_TURN_PAGE,
		"player_id": player_id,
	}

func make_turn_page_action(player_id: int) -> Dictionary:
	return {
		"type": ACTION_TURN_PAGE,
		"player_id": player_id,
	}

func make_move_action(player_id: int, move: Dictionary) -> Dictionary:
	return {
		"type": ACTION_MOVE_PIECE,
		"player_id": player_id,
		"from": AIStateSimulator.get_move_from(move),
		"to": AIStateSimulator.get_move_to(move),
	}

func make_end_turn_action(player_id: int) -> Dictionary:
	return {
		"type": ACTION_END_TURN,
		"player_id": player_id,
	}

func make_executable_action(action: Dictionary) -> Dictionary:
	var executable_action: Dictionary = {}
	for key in action:
		if str(key) == "stamp":
			continue
		executable_action[key] = action[key]
	return executable_action

func get_ai_action_delay(action: Dictionary, action_delay: float) -> float:
	if action_delay <= 0.0:
		return 0.0
	if str(action.get("type", "")) == ACTION_AFFIX_STAMP:
		return maxf(action_delay, AFFIX_ACTION_DELAY)
	return action_delay

func duplicate_actions(source_actions: Array[Dictionary]) -> Array[Dictionary]:
	var duplicated_actions: Array[Dictionary] = []
	for action: Dictionary in source_actions:
		duplicated_actions.append(action.duplicate())
	return duplicated_actions

func get_move_stamp(move: Dictionary) -> Stamp:
	return move.get("stamp", null) as Stamp

func increment_profile_count(profile: Dictionary, key: String, amount: int = 1) -> void:
	if profile.is_empty():
		return
	profile[key] = int(profile.get(key, 0)) + amount
