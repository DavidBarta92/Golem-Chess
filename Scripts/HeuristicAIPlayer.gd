extends AIPlayerBase
class_name HeuristicAIPlayer

var evaluator: AIMoveEvaluator

func _init(new_player_id: int = 1, ai_difficulty: String = AIMoveEvaluator.DIFFICULTY_NORMAL):
	super(new_player_id)
	evaluator = AIMoveEvaluator.new(ai_difficulty)

func play_turn(host: NetworkGameHost, tree: SceneTree) -> bool:
	if !can_play_turn(host):
		return false

	var selected_move: Dictionary = choose_turn_move(host)
	return await execute_turn_move(host, tree, selected_move)

func choose_turn_move(host: NetworkGameHost) -> Dictionary:
	var valid_moves: Array[Dictionary] = get_valid_turn_moves(host)
	if valid_moves.is_empty():
		return {}

	return evaluator.choose_best_move(host.game_state, player_id, valid_moves, BOARD_SIZE)
