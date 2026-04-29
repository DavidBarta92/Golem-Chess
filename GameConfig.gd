extends Node

const CONTROLLER_HUMAN: String = "human"
const CONTROLLER_AI: String = "ai"

var is_singleplayer: bool = false
var is_hosting: bool = false
var server_ip: String = "127.0.0.1"
var server_port: int = 9999
var player_controllers: Dictionary = {
	0: CONTROLLER_HUMAN,
	1: CONTROLLER_HUMAN,
}

func set_player_controller(player_id: int, controller_type: String) -> void:
	player_controllers[player_id] = controller_type

func get_player_controller(player_id: int) -> String:
	return str(player_controllers.get(player_id, CONTROLLER_HUMAN))

func set_singleplayer_controllers(player_0_controller: String = CONTROLLER_HUMAN, player_1_controller: String = CONTROLLER_AI) -> void:
	set_player_controller(0, player_0_controller)
	set_player_controller(1, player_1_controller)

func reset_multiplayer_controllers() -> void:
	set_player_controller(0, CONTROLLER_HUMAN)
	set_player_controller(1, CONTROLLER_HUMAN)
