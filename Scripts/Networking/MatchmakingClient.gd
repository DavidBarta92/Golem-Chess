extends Node
class_name MatchmakingClient

signal lobby_list_updated(lobbies: Array)
signal lobby_created(lobby: MultiplayerLobby)
signal lobby_join_requested(lobby: MultiplayerLobby)
signal friend_invite_requested(friend_id: String)
signal quick_match_requested()
signal matchmaking_failed(message: String)

func refresh_lobbies() -> void:
	push_warning("MatchmakingClient.refresh_lobbies() is not implemented by this provider.")
	lobby_list_updated.emit([])

func create_lobby(_player_name: String, _deck_stamp_names: Array[String]) -> void:
	matchmaking_failed.emit("Lobby creation is not implemented by this provider.")

func join_lobby(lobby: MultiplayerLobby) -> void:
	if lobby == null or !lobby.is_joinable():
		matchmaking_failed.emit("This lobby is no longer joinable.")
		return
	lobby_join_requested.emit(lobby)

func invite_friend(friend_id: String) -> void:
	if friend_id.strip_edges().is_empty():
		matchmaking_failed.emit("No friend was selected.")
		return
	friend_invite_requested.emit(friend_id)

func start_quick_match() -> void:
	quick_match_requested.emit()
