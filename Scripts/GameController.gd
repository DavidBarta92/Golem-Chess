# GameController.gd - Autoload
extends Node

signal state_updated(game_state: GameStateData)
signal action_result(success: bool, message: String)

## A NetworkGameHost when this machine runs the match (single player, hosting, or
## the tutorial and the puzzles on a host of their own), the Multiplayer scene
## when it has joined one and sends its actions on, and null outside a match.
var current_game_host = null

func set_game_host(host):
	current_game_host = host
	DebugLog.info("GameController: host set: %s" % [host])

func send_action(action: Dictionary):
	if current_game_host:
		return current_game_host.on_player_action(action)

	push_error("No game host is set.")
	return false

func broadcast_state(game_state: GameStateData):
	state_updated.emit(game_state)
