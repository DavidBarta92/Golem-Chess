extends RefCounted
class_name RandomAIPlayer

const BOARD_SIZE: int = 5

var player_id: int = 1
var action_delay: float = 0.35

func _init(new_player_id: int = 1):
	player_id = new_player_id

func play_turn(host: NetworkGameHost, tree: SceneTree) -> bool:
	if host == null or host.game_state == null or host.game_state.game_over:
		return false
	if host.game_state.current_turn_player != player_id:
		return false

	var selected_move: Dictionary = choose_random_turn_move(host)
	if selected_move.is_empty():
		host.finish_if_player_has_no_valid_turn(player_id)
		host.broadcast_full_state()
		return false

	if bool(selected_move.get("requires_attach", false)):
		var card: Card = selected_move.get("card") as Card
		if card == null:
			return false

		var attach_action: Dictionary = {
			"type": "attach_card",
			"player_id": player_id,
			"card_name": card.card_name,
			"piece_pos": selected_move.get("from"),
			"hand_index": -1,
		}
		host.on_player_action(attach_action)

		if host.game_state.game_over:
			return true
		if tree != null:
			await tree.create_timer(action_delay).timeout

	var move_action: Dictionary = {
		"type": "move_piece",
		"player_id": player_id,
		"from": selected_move.get("from"),
		"to": selected_move.get("to"),
	}
	host.on_player_action(move_action)
	return true

func choose_random_turn_move(host: NetworkGameHost) -> Dictionary:
	var player_color: int = 1 if player_id == 0 else -1
	var can_attach_card: bool = !bool(host.game_state.attached_card_this_turn.get(player_id, false))
	var hand_cards: Array[Card] = host.get_hand_cards_for_player(player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_valid_turn_moves(host.game_state.pieces, player_color, hand_cards, can_attach_card, BOARD_SIZE, host.game_state.board_effects)
	if valid_moves.is_empty():
		return {}

	var attach_moves: Array[Dictionary] = []
	for move: Dictionary in valid_moves:
		if bool(move.get("requires_attach", false)):
			attach_moves.append(move)

	if !attach_moves.is_empty():
		return attach_moves[randi() % attach_moves.size()]

	return valid_moves[randi() % valid_moves.size()]
