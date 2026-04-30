extends Node

const CONTROLLER_HUMAN: String = "human"
const CONTROLLER_AI: String = "ai"
const AI_DIFFICULTY_EASY: String = "easy"
const AI_DIFFICULTY_NORMAL: String = "normal"
const AI_DIFFICULTY_HARD: String = "hard"

var is_singleplayer: bool = false
var is_hosting: bool = false
var server_ip: String = "127.0.0.1"
var server_port: int = 9999
var player_controllers: Dictionary = {
	0: CONTROLLER_HUMAN,
	1: CONTROLLER_HUMAN,
}
var player_ai_difficulties: Dictionary = {
	0: AI_DIFFICULTY_NORMAL,
	1: AI_DIFFICULTY_NORMAL,
}

func set_player_controller(player_id: int, controller_type: String) -> void:
	player_controllers[player_id] = controller_type

func get_player_controller(player_id: int) -> String:
	return str(player_controllers.get(player_id, CONTROLLER_HUMAN))

func set_player_ai_difficulty(player_id: int, difficulty: String) -> void:
	player_ai_difficulties[player_id] = difficulty

func get_player_ai_difficulty(player_id: int) -> String:
	return str(player_ai_difficulties.get(player_id, AI_DIFFICULTY_NORMAL))

func set_singleplayer_controllers(player_0_controller: String = CONTROLLER_HUMAN, player_1_controller: String = CONTROLLER_AI) -> void:
	set_player_controller(0, player_0_controller)
	set_player_controller(1, player_1_controller)

func reset_multiplayer_controllers() -> void:
	set_player_controller(0, CONTROLLER_HUMAN)
	set_player_controller(1, CONTROLLER_HUMAN)
