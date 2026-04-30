extends RefCounted
class_name AITurnPlanner

const DEFAULT_BOARD_SIZE: int = 5
const ACTION_ATTACH_CARD: String = "attach_card"
const ACTION_DRAW_CARD: String = "draw_card"
const ACTION_MOVE_PIECE: String = "move_piece"
const ACTION_END_TURN: String = "end_turn"

func create_turn_plans(host: NetworkGameHost, player_id: int, board_size: int = DEFAULT_BOARD_SIZE) -> Array[Dictionary]:
	if host == null or host.game_state == null or host.game_state.game_over:
		return []

	return create_turn_plans_from_state(host.game_state, player_id, board_size)

func create_turn_plans_from_state(game_state: GameStateData, player_id: int, board_size: int = DEFAULT_BOARD_SIZE) -> Array[Dictionary]:
	var plans: Array[Dictionary] = []
	if game_state == null or game_state.game_over:
		return plans

	var can_draw_now: bool = can_draw_card_from_state(game_state, player_id)
	var can_move_now: bool = !bool(game_state.moved_piece_this_turn.get(player_id, false))
	var can_attach_now: bool = !bool(game_state.attached_card_this_turn.get(player_id, false))
	var current_hand_cards: Array[Card] = AIStateSimulator.get_hand_cards_from_state(game_state, player_id)
	var no_prefix_actions: Array[Dictionary] = []

	add_branch_plans(
		plans,
		game_state,
		player_id,
		game_state.pieces,
		current_hand_cards,
		no_prefix_actions,
		false,
		"",
		can_move_now,
		can_attach_now,
		board_size
	)

	if can_draw_now:
		var drawn_card_name: String = get_next_draw_card_name(game_state, player_id)
		var draw_action: Dictionary = make_draw_action(player_id)
		var draw_actions: Array[Dictionary] = [draw_action]
		plans.append(create_plan(draw_actions, {}, [], true, drawn_card_name, "draw_only"))

		var hand_after_draw: Array[Card] = duplicate_card_array(current_hand_cards)
		var drawn_card: Card = CardLibrary.get_card(drawn_card_name)
		if drawn_card != null:
			hand_after_draw.append(drawn_card)

		add_branch_plans(
			plans,
			game_state,
			player_id,
			game_state.pieces,
			hand_after_draw,
			draw_actions,
			true,
			drawn_card_name,
			can_move_now,
			can_attach_now,
			board_size
		)

	if plans.is_empty():
		var end_actions: Array[Dictionary] = [make_end_turn_action(player_id)]
		plans.append(create_plan(end_actions, {}, [], false, "", "end_turn"))

	return plans

func can_draw_card_from_state(game_state: GameStateData, player_id: int) -> bool:
	if game_state == null or bool(game_state.drawn_card_this_turn.get(player_id, false)):
		return false
	if !game_state.player_decks.has(player_id) or !game_state.player_hands.has(player_id):
		return false

	var player_deck: Array = game_state.player_decks[player_id]
	var player_hand: Array = game_state.player_hands[player_id]
	return !player_deck.is_empty() && player_hand.size() < DeckManager.HAND_SIZE

func add_branch_plans(
	plans: Array[Dictionary],
	game_state: GameStateData,
	player_id: int,
	pieces: Dictionary,
	hand_cards: Array[Card],
	prefix_actions: Array[Dictionary],
	uses_draw: bool,
	drawn_card_name: String,
	can_move: bool,
	can_attach: bool,
	board_size: int
) -> void:
	if can_attach:
		var attach_actions: Array[Dictionary] = get_attach_actions_for_pieces(pieces, player_id, hand_cards)
		for attach_action: Dictionary in attach_actions:
			var attach_only_actions: Array[Dictionary] = duplicate_actions(prefix_actions)
			attach_only_actions.append(attach_action)
			plans.append(create_plan(attach_only_actions, {}, [attach_action], uses_draw, drawn_card_name, get_branch_name("attach_only", uses_draw)))

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
		plans.append(create_plan(move_actions, move, [], uses_draw, drawn_card_name, get_branch_name("move", uses_draw)))

		if can_attach && !bool(move.get("requires_attach", false)):
			add_move_then_attach_plans(
				plans,
				game_state,
				player_id,
				hand_cards,
				prefix_actions,
				move,
				uses_draw,
				drawn_card_name,
				board_size
			)

func add_move_then_attach_plans(
	plans: Array[Dictionary],
	game_state: GameStateData,
	player_id: int,
	hand_cards: Array[Card],
	prefix_actions: Array[Dictionary],
	move: Dictionary,
	uses_draw: bool,
	drawn_card_name: String,
	_board_size: int
) -> void:
	var simulated_pieces: Dictionary = AIStateSimulator.apply_candidate_to_pieces(game_state.pieces, move)
	var attach_actions: Array[Dictionary] = get_attach_actions_for_pieces(simulated_pieces, player_id, hand_cards)
	for attach_action: Dictionary in attach_actions:
		var actions: Array[Dictionary] = duplicate_actions(prefix_actions)
		actions.append(make_move_action(player_id, move))
		actions.append(attach_action)
		plans.append(create_plan(actions, move, [attach_action], uses_draw, drawn_card_name, get_branch_name("move_then_attach", uses_draw)))

func get_attach_actions_for_pieces(pieces: Dictionary, player_id: int, hand_cards: Array[Card]) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	for position_value in pieces:
		var piece_position: Vector2 = CardEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = pieces[position_value] as Piece
		if piece == null or piece.color != player_color or piece.attached_card != null:
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
		host.on_player_action(make_end_turn_action(player_id))
		return false

	for action_value in actions:
		if host.game_state.game_over or host.game_state.current_turn_player != player_id:
			return true

		var action: Dictionary = action_value
		host.on_player_action(make_executable_action(action))

		if host.game_state.game_over or host.game_state.current_turn_player != player_id:
			return true
		if tree != null:
			await tree.create_timer(action_delay).timeout

	if host.game_state.current_turn_player == player_id && !host.player_has_remaining_turn_action(player_id):
		host.on_player_action(make_end_turn_action(player_id))

	return true

func create_plan(actions: Array[Dictionary], move: Dictionary, setup_attach_actions: Array, uses_draw: bool, drawn_card_name: String, plan_type: String) -> Dictionary:
	return {
		"actions": actions,
		"move": move,
		"setup_attach_actions": setup_attach_actions,
		"uses_draw": uses_draw,
		"drawn_card_name": drawn_card_name,
		"plan_type": plan_type,
	}

func make_attach_action(player_id: int, card: Card, piece_pos: Vector2) -> Dictionary:
	return {
		"type": ACTION_ATTACH_CARD,
		"player_id": player_id,
		"card_name": card.card_name if card != null else "",
		"piece_pos": piece_pos,
		"card": card,
	}

func make_draw_action(player_id: int) -> Dictionary:
	return {
		"type": ACTION_DRAW_CARD,
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

func duplicate_actions(source_actions: Array[Dictionary]) -> Array[Dictionary]:
	var duplicated_actions: Array[Dictionary] = []
	for action: Dictionary in source_actions:
		duplicated_actions.append(action.duplicate())
	return duplicated_actions

func duplicate_card_array(source_cards: Array[Card]) -> Array[Card]:
	var duplicated_cards: Array[Card] = []
	for card: Card in source_cards:
		duplicated_cards.append(card)
	return duplicated_cards

func get_next_draw_card_name(game_state: GameStateData, player_id: int) -> String:
	if game_state == null or !game_state.player_decks.has(player_id):
		return ""

	var deck: Array = game_state.player_decks[player_id]
	if deck.is_empty():
		return ""
	return str(deck[0])

func get_move_card(move: Dictionary) -> Card:
	return move.get("card", null) as Card

func get_branch_name(base_name: String, uses_draw: bool) -> String:
	return "draw_then_%s" % base_name if uses_draw else base_name
