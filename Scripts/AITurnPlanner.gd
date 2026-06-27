extends RefCounted
class_name AITurnPlanner

const DEFAULT_BOARD_SIZE: int = BoardConfig.BOARD_SIZE
const ACTION_ATTACH_CARD: String = "attach_card"
const ACTION_TURN_PAGE: String = "turn_page"
const ACTION_MOVE_PIECE: String = "move_piece"
const ACTION_END_TURN: String = "end_turn"
const MAX_SEQUENTIAL_ATTACH_ACTIONS: int = DeckManager.HAND_SIZE
const MAX_PLAN_ATTACH_DEPTH: int = DeckManager.HAND_SIZE
const MAX_PLAN_ATTACH_OPTIONS_PER_STATE: int = 2
const MAX_PLAN_EXCHANGE_OPTIONS: int = 1
const MAX_GENERATED_TURN_PLANS: int = 120
const ATTACH_ACTION_DELAY: float = 1.00
const TACTICAL_SEARCH_SCRIPT = preload("res://Scripts/AITacticalSearch.gd")

var planning_evaluator: AIMoveEvaluator = null
var tactical_search = TACTICAL_SEARCH_SCRIPT.new()

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
	var setup_attach_actions: Array[Dictionary] = []
	var selected_move: Dictionary = {}
	var profile: Dictionary = evaluator.create_profile(0) if evaluator != null else {}
	var turned_page: bool = false
	var attach_actions_played: int = 0
	var best_score_seen: float = -INF

	if host == null or host.game_state == null or host.game_state.game_over or evaluator == null:
		return create_sequential_plan(selected_actions, selected_move, setup_attach_actions, best_score_seen, profile)

	while can_continue_sequential_turn(host, player_id):
		if attach_actions_played < MAX_SEQUENTIAL_ATTACH_ACTIONS:
			var best_attach: Dictionary = find_best_attach_setup(host.game_state, player_id, evaluator, board_size, profile)
			var attach_threshold: float = -INF if int(host.game_state.completed_turn_counts.get(player_id, 0)) == 0 else get_attach_setup_threshold(host.game_state, player_id)
			best_score_seen = max(best_score_seen, float(best_attach.get("score", -INF)))
			if float(best_attach.get("score", -INF)) >= attach_threshold:
				var attach_action: Dictionary = best_attach.get("action", {})
				if attach_action.is_empty():
					break

				setup_attach_actions.append(attach_action)
				await execute_ai_action(host, tree, attach_action, action_delay, selected_actions)
				attach_actions_played += 1
				continue

		if !turned_page and host.can_turn_page_for_player(player_id) and has_free_attach_piece(host.game_state, player_id):
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

	return create_sequential_plan(selected_actions, selected_move, setup_attach_actions, best_score_seen, profile)

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
	host.on_player_action(make_executable_action(action))
	selected_actions.append(action.duplicate())
	var delay: float = get_ai_action_delay(action, action_delay)
	if tree != null and delay > 0.0:
		await tree.create_timer(delay).timeout

func create_sequential_plan(
	actions: Array[Dictionary],
	move: Dictionary,
	setup_attach_actions: Array[Dictionary],
	best_score: float,
	profile: Dictionary
) -> Dictionary:
	if !profile.is_empty():
		profile["best_plan_score"] = best_score if best_score != -INF else 0.0
		profile["best_plan_type"] = "sequential"
	return {
		"actions": actions,
		"move": move,
		"setup_attach_actions": setup_attach_actions,
		"plan_type": "sequential",
		"profile": profile,
	}

func find_best_attach_setup(
	game_state: GameStateData,
	player_id: int,
	evaluator: AIMoveEvaluator,
	board_size: int,
	profile: Dictionary = {}
) -> Dictionary:
	var best_action: Dictionary = {}
	var best_score: float = -INF
	var hand_names: Array = game_state.player_hands.get(player_id, [])
	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)

	for hand_index in range(hand_names.size()):
		var card_name: String = str(hand_names[hand_index])
		var card: Card = CardLibrary.get_card(card_name)
		if card == null or !MoveRules.card_can_be_used(card):
			continue

		for position_value in game_state.pieces:
			var piece_pos: Vector2 = CardEffectResolver.as_vector2(position_value, Vector2(-1, -1))
			var piece: Piece = game_state.pieces[position_value] as Piece
			if piece == null or piece.color != player_color or piece.attached_card != null:
				continue
			if !MoveRules.can_attach_card_for_turn(game_state.pieces, player_color, card):
				continue

			var attach_action: Dictionary = make_attach_action(player_id, card, piece_pos, hand_index)
			var attach_score: float = evaluator.score_attach_setup(game_state, player_id, attach_action, board_size)
			increment_profile_count(profile, "evaluated_own_plans")
			if best_action.is_empty() or attach_score > best_score:
				best_action = attach_action
				best_score = attach_score

	return {
		"action": best_action,
		"score": best_score,
	}

func find_exchange_action_for_worst_card(
	game_state: GameStateData,
	player_id: int,
	evaluator: AIMoveEvaluator,
	board_size: int,
	profile: Dictionary = {}
) -> Dictionary:
	var hand_names: Array = game_state.player_hands.get(player_id, [])
	var worst_hand_index: int = -1
	var worst_card_name: String = ""
	var worst_score: float = INF

	for hand_index in range(hand_names.size()):
		var card_name: String = str(hand_names[hand_index])
		var card_score: float = score_best_fit_for_card(game_state, player_id, card_name, hand_index, evaluator, board_size, profile)
		if worst_hand_index == -1 or card_score < worst_score:
			worst_hand_index = hand_index
			worst_card_name = card_name
			worst_score = card_score

	if worst_hand_index == -1:
		return {}

	return make_exchange_action(player_id, worst_card_name, worst_hand_index)

func score_best_fit_for_card(
	game_state: GameStateData,
	player_id: int,
	card_name: String,
	hand_index: int,
	evaluator: AIMoveEvaluator,
	board_size: int,
	profile: Dictionary = {}
) -> float:
	var card: Card = CardLibrary.get_card(card_name)
	if card == null or !MoveRules.card_can_be_used(card):
		return -INF

	var best_score: float = -INF
	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	for position_value in game_state.pieces:
		var piece_pos: Vector2 = CardEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != player_color or piece.attached_card != null:
			continue

		var attach_action: Dictionary = make_attach_action(player_id, card, piece_pos, hand_index)
		var attach_score: float = evaluator.score_attach_setup_for_exchange(game_state, player_id, attach_action, board_size)
		increment_profile_count(profile, "evaluated_own_plans")
		best_score = max(best_score, attach_score)

	return best_score

func get_attach_setup_threshold(game_state: GameStateData, player_id: int) -> float:
	var free_piece_count: int = count_free_attach_pieces(game_state, player_id)
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

func has_free_attach_piece(game_state: GameStateData, player_id: int) -> bool:
	return count_free_attach_pieces(game_state, player_id) > 0

func count_free_attach_pieces(game_state: GameStateData, player_id: int) -> int:
	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	var count: int = 0
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null and piece.color == player_color and piece.can_receive_card():
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

	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_card_moves(
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
	setup_attach_actions: Array[Dictionary],
	attach_depth: int,
	board_size: int
) -> void:
	if plans.size() >= MAX_GENERATED_TURN_PLANS or game_state == null or game_state.game_over:
		return

	add_current_state_finish_plans(plans, game_state, player_id, prefix_actions, setup_attach_actions, board_size)
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
				duplicate_actions(setup_attach_actions),
				attach_depth,
				board_size
			)

	if attach_depth >= MAX_PLAN_ATTACH_DEPTH:
		return

	var attach_actions: Array[Dictionary] = get_ranked_attach_actions_for_state(game_state, player_id, board_size)
	for attach_action: Dictionary in attach_actions:
		if plans.size() >= MAX_GENERATED_TURN_PLANS:
			return

		var next_state: GameStateData = AIStateSimulator.clone_game_state(game_state)
		var piece_pos: Vector2 = CardEffectResolver.as_vector2(attach_action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
		AIStateSimulator.apply_attach_action(next_state, player_id, attach_action, board_size)
		var attached_piece: Piece = next_state.get_piece(piece_pos)
		if attached_piece == null or attached_piece.attached_card == null:
			continue

		var next_prefix: Array[Dictionary] = duplicate_actions(prefix_actions)
		next_prefix.append(attach_action)
		var next_setup: Array[Dictionary] = duplicate_actions(setup_attach_actions)
		next_setup.append(attach_action)
		add_sequential_turn_plan_branches(
			plans,
			next_state,
			player_id,
			next_prefix,
			next_setup,
			attach_depth + 1,
			board_size
		)

func add_current_state_finish_plans(
	plans: Array[Dictionary],
	game_state: GameStateData,
	player_id: int,
	prefix_actions: Array[Dictionary],
	setup_attach_actions: Array[Dictionary],
	board_size: int
) -> void:
	if plans.size() >= MAX_GENERATED_TURN_PLANS:
		return

	var is_first_turn: bool = int(game_state.completed_turn_counts.get(player_id, 0)) == 0
	if is_first_turn and !setup_attach_actions.is_empty():
		var setup_only_actions: Array[Dictionary] = duplicate_actions(prefix_actions)
		setup_only_actions.append(make_end_turn_action(player_id))
		plans.append(create_plan(setup_only_actions, {}, duplicate_actions(setup_attach_actions), "setup_only"))
		return

	if bool(game_state.moved_piece_this_turn.get(player_id, false)):
		return

	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_card_moves(
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
		var plan_type: String = "setup_move" if !setup_attach_actions.is_empty() else "move"
		plans.append(create_plan(move_actions, move, duplicate_actions(setup_attach_actions), plan_type))

func get_ranked_attach_actions_for_state(game_state: GameStateData, player_id: int, board_size: int) -> Array[Dictionary]:
	var hand_cards: Array[Card] = AIStateSimulator.get_hand_cards_from_state(game_state, player_id)
	var attach_actions: Array[Dictionary] = get_attach_actions_for_pieces(game_state.pieces, player_id, hand_cards)
	var scored_actions: Array[Dictionary] = []
	for attach_action: Dictionary in attach_actions:
		var score: float = 0.0
		if planning_evaluator != null:
			score = planning_evaluator.score_attach_setup(game_state, player_id, attach_action, board_size)
		scored_actions.append({
			"action": attach_action,
			"score": score,
		})
	scored_actions.sort_custom(Callable(self, "sort_scored_action_desc"))

	var ranked_actions: Array[Dictionary] = []
	var action_count: int = mini(MAX_PLAN_ATTACH_OPTIONS_PER_STATE, scored_actions.size())
	for index in range(action_count):
		ranked_actions.append(scored_actions[index].get("action", {}))
	return ranked_actions

func get_exchange_actions_for_state(game_state: GameStateData, player_id: int, board_size: int) -> Array[Dictionary]:
	var hand_names: Array = game_state.player_hands.get(player_id, [])
	var scored_actions: Array[Dictionary] = []
	for hand_index in range(hand_names.size()):
		var card_name: String = str(hand_names[hand_index])
		var score: float = 0.0
		if planning_evaluator != null:
			score = score_best_fit_for_card(game_state, player_id, card_name, hand_index, planning_evaluator, board_size)
		scored_actions.append({
			"action": make_exchange_action(player_id, card_name, hand_index),
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
	hand_cards: Array[Card],
	prefix_actions: Array[Dictionary],
	can_move: bool,
	can_attach: bool,
	board_size: int
) -> void:
	if can_attach:
		var attach_actions: Array[Dictionary] = get_attach_actions_for_pieces(pieces, player_id, hand_cards)
		for attach_action: Dictionary in attach_actions:
			var attach_only_actions: Array[Dictionary] = duplicate_actions(prefix_actions)
			attach_only_actions.append(attach_action)
			plans.append(create_plan(attach_only_actions, {}, [attach_action], "attach_only"))

	if !can_move:
		return

	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_valid_turn_moves(
		pieces,
		player_color,
		hand_cards,
		can_attach,
		board_size,
		game_state.board_effects
	)

	for move: Dictionary in valid_moves:
		var move_actions: Array[Dictionary] = duplicate_actions(prefix_actions)
		if bool(move.get("requires_attach", false)):
			var move_attach_action: Dictionary = make_attach_action(player_id, get_move_card(move), AIStateSimulator.get_move_from(move))
			move_actions.append(move_attach_action)

		move_actions.append(make_move_action(player_id, move))
		plans.append(create_plan(move_actions, move, [], "move"))


func add_move_then_attach_plans(
	plans: Array[Dictionary],
	game_state: GameStateData,
	player_id: int,
	hand_cards: Array[Card],
	prefix_actions: Array[Dictionary],
	move: Dictionary,
	_board_size: int
) -> void:
	var simulated_pieces: Dictionary = AIStateSimulator.apply_candidate_to_pieces(game_state.pieces, move)
	var attach_actions: Array[Dictionary] = get_attach_actions_for_pieces(simulated_pieces, player_id, hand_cards)
	for attach_action: Dictionary in attach_actions:
		var actions: Array[Dictionary] = duplicate_actions(prefix_actions)
		actions.append(make_move_action(player_id, move))
		actions.append(attach_action)
		plans.append(create_plan(actions, move, [attach_action], "move_then_attach"))

func get_attach_actions_for_pieces(pieces: Dictionary, player_id: int, hand_cards: Array[Card]) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	for position_value in pieces:
		var piece_position: Vector2 = CardEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = pieces[position_value] as Piece
		if piece == null or piece.color != player_color or !piece.can_receive_card():
			continue

		for card: Card in hand_cards:
			if !MoveRules.card_can_be_used(card):
				continue
			if !MoveRules.can_attach_card_for_turn(pieces, player_color, card):
				continue
			actions.append(make_attach_action(player_id, card, piece_position))

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
		host.on_player_action(make_executable_action(action))

		if host.game_state.game_over or host.game_state.current_turn_player != player_id:
			return true
		var delay: float = get_ai_action_delay(action, action_delay)
		if tree != null and delay > 0.0:
			await tree.create_timer(delay).timeout

	if can_continue_sequential_turn(host, player_id) and host.can_end_turn_by_button(player_id):
		host.on_player_action(make_executable_action(make_end_turn_action(player_id)))

	return true

func create_plan(actions: Array[Dictionary], move: Dictionary, setup_attach_actions: Array, plan_type: String) -> Dictionary:
	return {
		"actions": actions,
		"move": move,
		"setup_attach_actions": setup_attach_actions,
		"plan_type": plan_type,
	}

func make_attach_action(player_id: int, card: Card, piece_pos: Vector2, hand_index: int = -1) -> Dictionary:
	return {
		"type": ACTION_ATTACH_CARD,
		"player_id": player_id,
		"card_name": card.card_name if card != null else "",
		"piece_pos": piece_pos,
		"hand_index": hand_index,
		"card": card,
	}

func make_exchange_action(player_id: int, card_name: String, hand_index: int) -> Dictionary:
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
		if str(key) == "card":
			continue
		executable_action[key] = action[key]
	return executable_action

func get_ai_action_delay(action: Dictionary, action_delay: float) -> float:
	if action_delay <= 0.0:
		return 0.0
	if str(action.get("type", "")) == ACTION_ATTACH_CARD:
		return maxf(action_delay, ATTACH_ACTION_DELAY)
	return action_delay

func duplicate_actions(source_actions: Array[Dictionary]) -> Array[Dictionary]:
	var duplicated_actions: Array[Dictionary] = []
	for action: Dictionary in source_actions:
		duplicated_actions.append(action.duplicate())
	return duplicated_actions

func get_move_card(move: Dictionary) -> Card:
	return move.get("card", null) as Card

func increment_profile_count(profile: Dictionary, key: String, amount: int = 1) -> void:
	if profile.is_empty():
		return
	profile[key] = int(profile.get(key, 0)) + amount
