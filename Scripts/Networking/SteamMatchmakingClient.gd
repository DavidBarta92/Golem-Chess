extends MatchmakingClient
class_name SteamMatchmakingClient

## Steam lobbies for a player-hosted match. The lobby owner hosts the game
## (SteamMultiplayerPeer.create_host) and the guest connects to the owner's
## Steam ID; no IP address is exchanged, Steam relays the traffic. Lives as a
## child node of whatever scene is using it, and only works while
## SteamManager.is_available().

## Entered a lobby someone else owns: connect to owner_steam_id now.
signal lobby_entered(lobby: MultiplayerLobby, owner_steam_id: int)

## Lobby data. Spacewar (app 480) shares one lobby list with every game being
## tested on it, so every search filters on LOBBY_KEY_GAME first.
const LOBBY_KEY_GAME: String = "golem_chess"
const LOBBY_GAME_VALUE: String = "1"
const LOBBY_KEY_VERSION: String = "golem_version"
const LOBBY_KEY_MODE: String = "golem_mode"
const LOBBY_KEY_HOST_NAME: String = "golem_host_name"
const MAX_LOBBY_MEMBERS: int = 2

var lobby_id: int = 0
var _steam: Object = null
var _creating_lobby: bool = false
var _host_name: String = ""
var _joining_lobby_id: int = 0
var _quick_match_search_pending: bool = false

func _ready() -> void:
	_steam = SteamManager.get_steam()
	if _steam == null:
		return
	_steam.connect("lobby_created", _on_lobby_created)
	_steam.connect("lobby_joined", _on_lobby_joined)
	_steam.connect("lobby_match_list", _on_lobby_match_list)

func is_ready() -> bool:
	if _steam != null:
		return true
	matchmaking_failed.emit(tr("Steam is not running."))
	return false

#region Hosting
## Opens a lobby for GameConfig.matchmaking_mode: friends only for an invite,
## public for a quick match. lobby_created follows.
func create_lobby(player_name: String, _deck_stamp_names: Array[String]) -> void:
	if !is_ready():
		return
	_creating_lobby = true
	_host_name = GameConfig.sanitize_player_name(player_name)
	var lobby_type: int = SteamManager.LOBBY_TYPE_PUBLIC if GameConfig.matchmaking_mode == GameConfig.MATCHMAKING_MODE_QUICK_MATCH else SteamManager.LOBBY_TYPE_FRIENDS_ONLY
	_steam.createLobby(lobby_type, MAX_LOBBY_MEMBERS)

func _on_lobby_created(result: int, new_lobby_id: int) -> void:
	if !_creating_lobby:
		return
	_creating_lobby = false
	if result != SteamManager.RESULT_OK:
		matchmaking_failed.emit(tr("Could not create the Steam lobby."))
		return
	lobby_id = new_lobby_id
	_steam.setLobbyData(lobby_id, LOBBY_KEY_GAME, LOBBY_GAME_VALUE)
	_steam.setLobbyData(lobby_id, LOBBY_KEY_VERSION, GameConfig.get_game_version())
	_steam.setLobbyData(lobby_id, LOBBY_KEY_MODE, GameConfig.matchmaking_mode)
	_steam.setLobbyData(lobby_id, LOBBY_KEY_HOST_NAME, _host_name)
	lobby_created.emit(build_lobby(lobby_id))

## Opens the Steam overlay's invite dialog for our lobby.
func invite_friend(_friend_id: String) -> void:
	if !is_ready() or lobby_id == 0:
		return
	_steam.activateGameOverlayInviteDialog(lobby_id)

## Takes the lobby out of quick-match searches once the match is on.
func set_lobby_joinable(joinable: bool) -> void:
	if _steam != null and lobby_id != 0:
		_steam.setLobbyJoinable(lobby_id, joinable)
#endregion

#region Joining
func join_lobby(lobby: MultiplayerLobby) -> void:
	if lobby == null or !is_ready():
		return
	_joining_lobby_id = int(lobby.lobby_id)
	_steam.joinLobby(_joining_lobby_id)

## Steam reports entering our own new lobby here too; only a join we asked for
## counts.
func _on_lobby_joined(joined_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if _joining_lobby_id == 0 or joined_lobby_id != _joining_lobby_id:
		return
	_joining_lobby_id = 0
	if response != SteamManager.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		matchmaking_failed.emit(tr("Could not join the Steam lobby."))
		return
	lobby_id = joined_lobby_id
	var host_version: String = _steam.getLobbyData(lobby_id, LOBBY_KEY_VERSION)
	if host_version != GameConfig.get_game_version():
		leave_lobby()
		matchmaking_failed.emit(tr("Version mismatch: you have %s, the other side has %s.") % [GameConfig.get_game_version(), host_version])
		return
	lobby_entered.emit(build_lobby(lobby_id), int(_steam.getLobbyOwner(lobby_id)))
#endregion

#region Quick match
## Lists the open quick-match lobbies of this game version, oldest first.
## lobby_list_updated follows.
func refresh_lobbies() -> void:
	if !is_ready():
		return
	# Filters apply to the next request only.
	_steam.addRequestLobbyListStringFilter(LOBBY_KEY_GAME, LOBBY_GAME_VALUE, SteamManager.LOBBY_COMPARISON_EQUAL)
	_steam.addRequestLobbyListStringFilter(LOBBY_KEY_VERSION, GameConfig.get_game_version(), SteamManager.LOBBY_COMPARISON_EQUAL)
	_steam.addRequestLobbyListStringFilter(LOBBY_KEY_MODE, GameConfig.MATCHMAKING_MODE_QUICK_MATCH, SteamManager.LOBBY_COMPARISON_EQUAL)
	_steam.addRequestLobbyListFilterSlotsAvailable(1)
	_steam.addRequestLobbyListDistanceFilter(SteamManager.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	_steam.requestLobbyList()

## Joins the oldest open quick-match lobby (lobby_join_requested), or asks for
## a new one to be opened when there is none (quick_match_requested).
func start_quick_match() -> void:
	_quick_match_search_pending = true
	refresh_lobbies()

func _on_lobby_match_list(found_lobby_ids: Array) -> void:
	var lobbies: Array[MultiplayerLobby] = []
	for found_lobby_id in found_lobby_ids:
		if int(found_lobby_id) == lobby_id:
			continue
		lobbies.append(build_lobby(int(found_lobby_id)))
	lobbies.sort_custom(func(a: MultiplayerLobby, b: MultiplayerLobby) -> bool: return int(a.lobby_id) < int(b.lobby_id))
	lobby_list_updated.emit(lobbies)

	if !_quick_match_search_pending:
		return
	_quick_match_search_pending = false
	for lobby in lobbies:
		if lobby.is_joinable():
			lobby_join_requested.emit(lobby)
			return
	quick_match_requested.emit()
#endregion

func leave_lobby() -> void:
	if _steam != null and lobby_id != 0:
		_steam.leaveLobby(lobby_id)
	lobby_id = 0

func build_lobby(source_lobby_id: int) -> MultiplayerLobby:
	var lobby := MultiplayerLobby.new()
	lobby.lobby_id = str(source_lobby_id)
	lobby.host_name = GameConfig.sanitize_player_name(_steam.getLobbyData(source_lobby_id, LOBBY_KEY_HOST_NAME))
	lobby.player_count = maxi(int(_steam.getNumLobbyMembers(source_lobby_id)), 1)
	lobby.max_players = MAX_LOBBY_MEMBERS
	lobby.provider = GameConfig.MULTIPLAYER_PROVIDER_STEAM
	lobby.matchmaking_mode = _steam.getLobbyData(source_lobby_id, LOBBY_KEY_MODE)
	return lobby
