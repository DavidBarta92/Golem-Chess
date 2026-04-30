extends AIPlayerBase
class_name RandomAIPlayer

func _init(new_player_id: int = 1):
	super(new_player_id)

func play_turn(host: NetworkGameHost, tree: SceneTree) -> bool:
	if !can_play_turn(host):
		return false

	var selected_move: Dictionary = choose_random_turn_move(host)
	return await execute_turn_move(host, tree, selected_move)

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
