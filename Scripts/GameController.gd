# GameController.gd - Autoload
extends Node

signal state_updated(game_state: GameStateData)
signal action_result(success: bool, message: String)

var current_game_host = null  # LocalGameHost vagy NetworkGameHost

func set_game_host(host):
	current_game_host = host
	print("🎮 GameController: Host beállítva: ", host)

func send_action(action: Dictionary):
	if current_game_host:
		current_game_host.on_player_action(action)
	else:
		push_error("❌ Nincs game host beállítva!")

func broadcast_state(game_state: GameStateData):
	state_updated.emit(game_state)
