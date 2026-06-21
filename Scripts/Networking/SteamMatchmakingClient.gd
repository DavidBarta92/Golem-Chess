extends MatchmakingClient
class_name SteamMatchmakingClient

func refresh_lobbies() -> void:
	matchmaking_failed.emit("Steam public lobby browsing is not planned for this game mode yet.")

func create_lobby(_player_name: String, _deck_card_names: Array[String]) -> void:
	matchmaking_failed.emit("Steam matchmaking is not integrated yet.")

func invite_friend(friend_id: String) -> void:
	if friend_id.strip_edges().is_empty():
		matchmaking_failed.emit("No Steam friend was selected.")
		return
	friend_invite_requested.emit(friend_id)

func start_quick_match() -> void:
	quick_match_requested.emit()
