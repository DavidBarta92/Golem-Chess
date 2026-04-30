extends RefCounted
class_name RandomAIPlayer

const AI_TURN_PLANNER_SCRIPT = preload("res://Scripts/AITurnPlanner.gd")
const BOARD_SIZE: int = 5
const DRAW_AT_TURN_START_BELOW_HAND_SIZE: int = 3

var player_id: int = 1
var action_delay: float = 0.35
var planner

func _init(new_player_id: int = 1):
	player_id = new_player_id
	planner = AI_TURN_PLANNER_SCRIPT.new()

func can_play_turn(host: NetworkGameHost) -> bool:
	return host != null \
		&& host.game_state != null \
		&& !host.game_state.game_over \
		&& host.game_state.current_turn_player == player_id

func play_turn(host: NetworkGameHost, tree: SceneTree) -> bool:
	if !can_play_turn(host):
		return false

	var selected_plan: Dictionary = choose_random_turn_plan(host)
	if planner == null:
		return false
	return await planner.execute_turn_plan(host, tree, player_id, selected_plan, action_delay)

func choose_random_turn_plan(host: NetworkGameHost) -> Dictionary:
	var turn_plans: Array[Dictionary] = get_turn_plans(host)
	if turn_plans.is_empty():
		return {}

	var active_plans: Array[Dictionary] = []
	for plan: Dictionary in turn_plans:
		if str(plan.get("plan_type", "")) != "end_turn":
			active_plans.append(plan)

	if active_plans.is_empty():
		return turn_plans[randi() % turn_plans.size()]
	return active_plans[randi() % active_plans.size()]

func get_turn_plans(host: NetworkGameHost) -> Array[Dictionary]:
	if planner == null:
		return []
	return planner.create_turn_plans(host, player_id, BOARD_SIZE)

func choose_random_turn_move(host: NetworkGameHost) -> Dictionary:
	var valid_moves: Array[Dictionary] = get_valid_turn_moves(host)
	if valid_moves.is_empty():
		return {}

	var attach_moves: Array[Dictionary] = []
	for move: Dictionary in valid_moves:
		if bool(move.get("requires_attach", false)):
			attach_moves.append(move)

	if !attach_moves.is_empty():
		return attach_moves[randi() % attach_moves.size()]

	return valid_moves[randi() % valid_moves.size()]

func get_valid_turn_moves(host: NetworkGameHost) -> Array[Dictionary]:
	var valid_moves: Array[Dictionary] = []
	if host == null or host.game_state == null:
		return valid_moves

	if bool(host.game_state.moved_piece_this_turn.get(player_id, false)):
		return valid_moves

	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	var can_attach_card: bool = !bool(host.game_state.attached_card_this_turn.get(player_id, false))
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
		if await try_draw_card(host, tree):
			return true
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
		if tree != null:
			await tree.create_timer(action_delay).timeout

	host.on_player_action({
		"type": "move_piece",
		"player_id": player_id,
		"from": AIStateSimulator.get_move_from(selected_move),
		"to": AIStateSimulator.get_move_to(selected_move),
	})
	if host.game_state.game_over:
		return true
	if tree != null:
		await tree.create_timer(action_delay).timeout
	end_turn(host)
	return true

func try_draw_card(host: NetworkGameHost, tree: SceneTree) -> bool:
	if host == null or host.game_state == null or !host.can_draw_card_for_player(player_id):
		return false

	host.on_player_action({
		"type": "draw_card",
		"player_id": player_id,
	})
	if tree != null:
		await tree.create_timer(action_delay).timeout
	return true

func try_draw_card_at_turn_start(host: NetworkGameHost, tree: SceneTree) -> bool:
	if !should_draw_card_at_turn_start(host):
		return false
	return await try_draw_card(host, tree)

func should_draw_card_at_turn_start(host: NetworkGameHost) -> bool:
	if host == null or host.game_state == null:
		return false
	if !host.can_draw_card_for_player(player_id):
		return false

	var hand: Array = []
	if host.game_state.player_hands.has(player_id):
		hand = host.game_state.player_hands[player_id]
	return hand.size() < DRAW_AT_TURN_START_BELOW_HAND_SIZE

func end_turn(host: NetworkGameHost) -> void:
	if host == null or host.game_state == null or host.game_state.game_over:
		return
	if host.game_state.current_turn_player != player_id:
		return
	host.on_player_action({
		"type": "end_turn",
		"player_id": player_id,
	})
