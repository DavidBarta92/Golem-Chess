extends MatchmakingClient
class_name CustomServerMatchmakingClient

var cached_lobbies: Array[MultiplayerLobby] = []

func refresh_lobbies() -> void:
	lobby_list_updated.emit(cached_lobbies.duplicate())

func set_lobbies_from_server(raw_lobbies: Array) -> void:
	cached_lobbies.clear()
	for raw_lobby in raw_lobbies:
		if raw_lobby is Dictionary:
			cached_lobbies.append(MultiplayerLobby.from_dictionary(raw_lobby))
	lobby_list_updated.emit(cached_lobbies.duplicate())

func create_lobby(player_name: String, _deck_card_names: Array[String]) -> void:
	var lobby := MultiplayerLobby.new()
	lobby.lobby_id = "local-%d" % Time.get_unix_time_from_system()
	lobby.host_name = GameConfig.sanitize_player_name(player_name)
	lobby.player_count = 1
	lobby.max_players = 2
	lobby.status = MultiplayerLobby.STATUS_OPEN
	lobby.endpoint_ip = GameConfig.server_ip
	lobby.endpoint_port = GameConfig.server_port
	lobby.provider = GameConfig.MULTIPLAYER_PROVIDER_CUSTOM_SERVER
	lobby.matchmaking_mode = GameConfig.MATCHMAKING_MODE_ROOM_LIST
	lobby_created.emit(lobby)

func invite_friend(_friend_id: String) -> void:
	matchmaking_failed.emit("Friend invites require the Steam matchmaking provider.")

func start_quick_match() -> void:
	matchmaking_failed.emit("Quick match is not available on the alpha custom server provider yet.")
