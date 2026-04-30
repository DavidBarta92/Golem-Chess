extends RefCounted
class_name AIPlayerBase

const BOARD_SIZE: int = 5

var player_id: int = 1
var action_delay: float = 0.35

func _init(new_player_id: int = 1):
	player_id = new_player_id

func can_play_turn(host: NetworkGameHost) -> bool:
	return host != null \
		&& host.game_state != null \
		&& !host.game_state.game_over \
		&& host.game_state.current_turn_player == player_id

func get_valid_turn_moves(host: NetworkGameHost) -> Array[Dictionary]:
	var valid_moves: Array[Dictionary] = []
	if host == null or host.game_state == null:
		return valid_moves

	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	var can_attach_card: bool = !bool(host.game_state.attached_card_this_turn.get(player_id, false))
	var hand_cards: Array[Card] = host.get_hand_cards_for_player(player_id)
	valid_moves = MoveRules.get_valid_turn_moves(
		host.game_state.pieces,
		player_color,
		hand_cards,
		can_attach_card,
		BOARD_SIZE,
		host.game_state.board_effects
	)
	return valid_moves

func play_turn(_host: NetworkGameHost, _tree: SceneTree) -> bool:
	return false

func execute_turn_move(host: NetworkGameHost, tree: SceneTree, selected_move: Dictionary) -> bool:
	if host == null or host.game_state == null or host.game_state.game_over:
		return false

	if selected_move.is_empty():
		host.finish_if_player_has_no_valid_turn(player_id)
		host.broadcast_full_state()
		return false

	if bool(selected_move.get("requires_attach", false)):
		var card: Card = selected_move.get("card", null) as Card
		if card == null:
			return false

		var attach_action: Dictionary = {
			"type": "attach_card",
			"player_id": player_id,
			"card_name": card.card_name,
			"piece_pos": AIStateSimulator.get_move_from(selected_move),
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
		"from": AIStateSimulator.get_move_from(selected_move),
		"to": AIStateSimulator.get_move_to(selected_move),
	}
	host.on_player_action(move_action)
	return true
