extends Node

## Single gateway to the GodotSteam GDExtension (res://addons/godotsteam).
##
## Every Steam call in the game should go through here, so the game keeps
## running when Steam is not there: dedicated server builds, headless batch
## runs, launching without the Steam client, or a non-Steam export (itch.io)
## that leaves the extension out. The singleton is looked up dynamically
## instead of referenced as `Steam`, so this script still compiles when the
## extension is missing. Check is_available() before relying on any Steam-only
## feature.
##
## It also takes Steam invites: accepting one, in the Steam overlay or by
## starting the game from it, joins the inviter's lobby (start_lobby_join).

## Valve's public test app (Spacewar) - replace with the game's own App ID
## once Steamworks assigns one.
const STEAM_APP_ID: int = 480
const STEAM_SINGLETON_NAME: String = "Steam"
const STEAM_INIT_RESULT_OK: int = 0
## Custom feature tag of the exports that ship without Steam (the itch.io
## preset). Those builds must never touch a running Steam client, even if the
## extension somehow made it into the pack.
const NO_STEAM_FEATURE: String = "no_steam"

## Steamworks enum values (EResult, ELobbyType, ELobbyComparison,
## ELobbyDistanceFilter, EChatRoomEnterResponse). Mirrored here because the
## singleton's own constants cannot be named while the extension may be absent.
const RESULT_OK: int = 1
const LOBBY_TYPE_FRIENDS_ONLY: int = 1
const LOBBY_TYPE_PUBLIC: int = 2
const LOBBY_COMPARISON_EQUAL: int = 0
const LOBBY_DISTANCE_FILTER_WORLDWIDE: int = 3
const CHAT_ROOM_ENTER_RESPONSE_SUCCESS: int = 1

## Steam puts this before the lobby id on the command line of a game it starts
## from an invite.
const CONNECT_LOBBY_ARGUMENT: String = "+connect_lobby"
const MATCH_SCENE: String = "res://Scenes/main.tscn"
const TUTORIAL_SCENE: String = "res://Scenes/Tutorial.tscn"
const MULTIPLAYER_MENU_SCENE: String = "res://Scenes/MultiplayerMenu.tscn"

var _steam: Object = null
var _init_result: Dictionary = {}
## An accepted invite that could not be followed yet - the game was just
## starting, or a match was running. The main menu picks it up.
var _pending_lobby_join_id: int = 0


func _ready() -> void:
	# Callbacks must keep flowing while the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)

	if OS.has_feature(NO_STEAM_FEATURE):
		return
	if OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		return
	initialize()


## Connects to the Steam client. _ready() does this unless the build or the
## launch has no business with Steam; calling it directly overrides that, for
## a headless run that does want Steam.
func initialize() -> bool:
	if is_available():
		return true
	if !Engine.has_singleton(STEAM_SINGLETON_NAME):
		push_warning("GodotSteam extension is not loaded; Steam features are disabled.")
		return false

	var steam: Object = Engine.get_singleton(STEAM_SINGLETON_NAME)
	_init_result = steam.steamInitEx(STEAM_APP_ID, false)
	if int(_init_result.get("status", -1)) != STEAM_INIT_RESULT_OK:
		push_warning("Steam failed to initialize, Steam features are disabled: %s" % _init_result)
		return false

	_steam = steam
	_steam.connect("join_requested", _on_join_requested)
	_pending_lobby_join_id = get_launch_lobby_id()
	set_process(true)
	return true


func _process(_delta: float) -> void:
	_steam.run_callbacks()


func is_available() -> bool:
	return _steam != null


## The GodotSteam singleton, or null when Steam is not available. Untyped on
## purpose: see the note at the top.
func get_steam() -> Object:
	return _steam


## The raw steamInitEx() result ({"status": int, "verbal": String}), empty
## when initialization was skipped.
func get_init_result() -> Dictionary:
	return _init_result


func get_steam_id() -> int:
	if !is_available():
		return 0
	return _steam.getSteamID()


func get_persona_name() -> String:
	if !is_available():
		return ""
	return _steam.getPersonaName()


#region Invites
## The lobby a Steam invite started this game for, or 0.
func get_launch_lobby_id() -> int:
	var arguments: PackedStringArray = OS.get_cmdline_args()
	var index: int = arguments.find(CONNECT_LOBBY_ARGUMENT)
	if index == -1 or index + 1 >= arguments.size() or !arguments[index + 1].is_valid_int():
		return 0
	return int(arguments[index + 1])


## Accepting an invite in the overlay while the game runs. A running match is
## not abandoned for it: the invite waits until the player is back in the menu.
func _on_join_requested(lobby_id: int, _friend_steam_id: int) -> void:
	_pending_lobby_join_id = lobby_id
	if is_match_running():
		DebugLog.network("Steam invite to lobby %d accepted during a match; joining from the main menu." % lobby_id)
		return
	start_lobby_join(lobby_id)


func is_match_running() -> bool:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return false
	return scene.scene_file_path == MATCH_SCENE or scene.scene_file_path == TUTORIAL_SCENE


func has_pending_lobby_join() -> bool:
	return _pending_lobby_join_id != 0

## Follows an invite that is still waiting. Returns true when it did, so the
## caller leaves the scene change to it.
func start_pending_lobby_join() -> bool:
	if _pending_lobby_join_id == 0:
		return false
	start_lobby_join(_pending_lobby_join_id)
	return true


## Joins a Steam lobby as the guest; its owner hosts the match.
func start_lobby_join(lobby_id: int) -> void:
	_pending_lobby_join_id = 0
	DebugLog.network("Joining Steam lobby %d from an invite." % lobby_id)
	if !GameConfig.has_selected_deck():
		GameConfig.set_multiplayer_menu_status_message(tr("You need a complete codex to accept a Steam invite."))
		SceneTransition.change_scene(MULTIPLAYER_MENU_SCENE)
		return
	GameConfig.prepare_steam_join(str(lobby_id), GameConfig.MATCHMAKING_MODE_FRIEND_INVITE)
	SceneTransition.change_scene(MATCH_SCENE)
#endregion
