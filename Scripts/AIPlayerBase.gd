extends RefCounted

const BOARD_SIZE: int = BoardConfig.BOARD_SIZE

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

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var can_attach_stamp: bool = true
	if bool(host.game_state.moved_piece_this_turn.get(player_id, false)):
		return valid_moves
	var hand_stamps: Array[Stamp] = host.get_hand_stamps_for_player(player_id)
	valid_moves = MoveRules.get_valid_turn_moves(
		host.game_state.pieces,
		player_color,
		hand_stamps,
		can_attach_stamp,
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
		end_turn(host)
		return false

	if bool(selected_move.get("requires_attach", false)):
		var stamp: Stamp = selected_move.get("stamp", null) as Stamp
		if stamp == null:
			return false

		var attach_action: Dictionary = {
			"type": "attach_stamp",
			"player_id": player_id,
			"stamp_name": stamp.stamp_name,
			"piece_pos": AIStateSimulator.get_move_from(selected_move),
			"hand_index": -1,
		}
		host.on_player_action(attach_action)

		if host.game_state.game_over:
			return true
		if tree != null and action_delay > 0.0:
			await tree.create_timer(action_delay).timeout

	var move_action: Dictionary = {
		"type": "move_piece",
		"player_id": player_id,
		"from": AIStateSimulator.get_move_from(selected_move),
		"to": AIStateSimulator.get_move_to(selected_move),
	}
	host.on_player_action(move_action)
	if host.game_state.game_over:
		return true
	if tree != null and action_delay > 0.0:
		await tree.create_timer(action_delay).timeout
	end_turn(host)
	return true

func end_turn(host: NetworkGameHost) -> void:
	if host == null or host.game_state == null or host.game_state.game_over:
		return
	host.on_player_action({
		"type": "end_turn",
		"player_id": player_id,
	})
