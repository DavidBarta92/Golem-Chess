extends RefCounted
class_name MultiplayerLobby

const STATUS_OPEN: String = "open"
const STATUS_FULL: String = "full"
const STATUS_IN_GAME: String = "in_game"

var lobby_id: String = ""
var host_name: String = ""
var player_count: int = 0
var max_players: int = 2
var status: String = STATUS_OPEN
var endpoint_ip: String = ""
var endpoint_port: int = GameConfig.DEFAULT_SERVER_PORT
var provider: String = GameConfig.MULTIPLAYER_PROVIDER_CUSTOM_SERVER
var matchmaking_mode: String = GameConfig.MATCHMAKING_MODE_DIRECT_CONNECT
var metadata: Dictionary = {}

static func from_dictionary(data: Dictionary) -> MultiplayerLobby:
	var lobby := MultiplayerLobby.new()
	lobby.lobby_id = str(data.get("lobby_id", ""))
	lobby.host_name = GameConfig.sanitize_player_name(str(data.get("host_name", GameConfig.DEFAULT_PLAYER_NAME)))
	lobby.player_count = clampi(int(data.get("player_count", 0)), 0, int(data.get("max_players", 2)))
	lobby.max_players = max(1, int(data.get("max_players", 2)))
	lobby.status = str(data.get("status", STATUS_OPEN))
	lobby.endpoint_ip = str(data.get("endpoint_ip", ""))
	lobby.endpoint_port = GameConfig.parse_server_port(data.get("endpoint_port", GameConfig.DEFAULT_SERVER_PORT))
	lobby.provider = str(data.get("provider", GameConfig.MULTIPLAYER_PROVIDER_CUSTOM_SERVER))
	lobby.matchmaking_mode = str(data.get("matchmaking_mode", GameConfig.MATCHMAKING_MODE_DIRECT_CONNECT))
	lobby.metadata = data.get("metadata", {}).duplicate(true) if data.get("metadata", {}) is Dictionary else {}
	return lobby

func to_dictionary() -> Dictionary:
	return {
		"lobby_id": lobby_id,
		"host_name": host_name,
		"player_count": player_count,
		"max_players": max_players,
		"status": status,
		"endpoint_ip": endpoint_ip,
		"endpoint_port": endpoint_port,
		"provider": provider,
		"matchmaking_mode": matchmaking_mode,
		"metadata": metadata.duplicate(true),
	}

func is_joinable() -> bool:
	return status == STATUS_OPEN && player_count < max_players

func get_display_name() -> String:
	var safe_host_name: String = GameConfig.sanitize_player_name(host_name)
	return "%s (%d/%d)" % [safe_host_name, player_count, max_players]
