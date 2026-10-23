extends Node2D

const CONNECTION_DIAGNOSTIC_DELAY: float = 8.0
const MAX_DEDICATED_SERVER_CLIENTS: int = 64
## Longer than the client's own wait on the result screen (GameResultController)
## so a client that won by forfeit leaves by itself before this kicks in.
const FORFEIT_DISCONNECT_FALLBACK_DELAY: float = 12.0
## How often a host waiting in a quick-match lobby looks for an older one.
const QUICK_MATCH_RECHECK_INTERVAL: float = 5.0
const MULTIPLAYER_MENU_SCENE: String = "res://Scenes/MultiplayerMenu.tscn"
const MATCH_SCENE: String = "res://Scenes/main.tscn"

signal custom_lobby_list_updated(lobbies: Array)
signal custom_lobby_failed(message: String)

## Emitted after the host has applied and broadcast a change, and after a
## singleplayer AI has finished its turn. The boss dialogue director listens to
## both; nothing in the match itself depends on them, so a match with no story
## boss simply has no listeners.
signal host_state_changed()
signal ai_turn_finished(player_id: int, report: Dictionary)
signal ai_thinking_pause_started(player_id: int, seconds: float)

var multiplayer_peer = ENetMultiplayerPeer.new()
var is_server = false
var is_dedicated_server = false

var connected_peer_ids = []
var server_connected_peer_ids: Array[int] = []
var open_lobbies: Dictionary = {}
var peer_player_ids: Dictionary = {}
var peer_player_names: Dictionary = {}
var peer_player_decks: Dictionary = {}
var peer_player_portraits: Dictionary = {}
## Game version each connected peer announced (announce_client_version). A peer
## is only let into a match when it matches ours exactly.
var peer_client_versions: Dictionary = {}
var server_turn = true
var multiplayer_game_started: bool = false

var game_host: NetworkGameHost = null
var ai_players: Dictionary = {}
var ai_turn_in_progress: bool = false
var network_status_label: Label = null
var custom_lobby_panel: Control = null
var custom_lobby_status_label: Label = null
var custom_lobby_item_list: ItemList = null
var custom_lobby_refresh_button: Button = null
var custom_lobby_create_button: Button = null
var custom_lobby_join_button: Button = null
var custom_lobby_entries: Array[MultiplayerLobby] = []
var match_peer_left_return_scheduled: bool = false
var codex_bridge_poll_elapsed: float = 0.0
## The Steam lobby of a Steam match (GameConfig.is_using_steam_multiplayer()),
## created on demand.
var steam_matchmaking: SteamMatchmakingClient = null
var quick_match_recheck_elapsed: float = 0.0

func _ready():
	if !GameConfig.should_skip_ai_vs_ai_delays():
		await get_tree().create_timer(0.1).timeout

	apply_command_line_network_overrides()
	if !GameConfig.is_singleplayer:
		ensure_network_status_label()
		set_network_status(tr("Starting network..."))
		if is_using_single_server_room_mode():
			ensure_custom_lobby_panel()
	DebugLog.network("Multiplayer scene ready. singleplayer=%s hosting=%s endpoint=%s:%d log=%s" % [
		GameConfig.is_singleplayer,
		GameConfig.is_hosting,
		GameConfig.server_ip,
		GameConfig.server_port,
		DebugLog.get_network_log_path(),
	])
	DebugLog.network("Command line arguments: %s user_args=%s dedicated=%s" % [
		OS.get_cmdline_args(),
		OS.get_cmdline_user_args(),
		GameConfig.is_dedicated_server,
	])
	var start_as_dedicated_server: bool = should_start_dedicated_server()
	DebugLog.network("Resolved launch mode: dedicated_server=%s port=%d" % [start_as_dedicated_server, GameConfig.server_port])
	if start_as_dedicated_server:
		DebugLog.info("Starting in dedicated custom server mode")
		start_dedicated_custom_server(GameConfig.server_port)
	elif GameConfig.is_singleplayer:
		DebugLog.info("Starting in singleplayer mode")
		await wait_for_deck_choice()
		start_singleplayer_game()
	elif GameConfig.is_using_steam_multiplayer():
		if GameConfig.is_hosting:
			DebugLog.info("Starting in Steam host mode")
			host_steam_game()
		else:
			DebugLog.info("Starting in Steam join mode - lobby: %s" % GameConfig.selected_lobby_id)
			join_steam_game(GameConfig.selected_lobby_id)
	elif GameConfig.is_hosting:
		DebugLog.info("Starting in host mode")
		host_game(GameConfig.server_port)
	else:
		DebugLog.info("Starting in join mode - IP: %s" % GameConfig.server_ip)
		join_game(GameConfig.server_ip, GameConfig.server_port)

func apply_command_line_network_overrides() -> void:
	var arguments: Array[String] = get_network_command_line_arguments()
	for index in range(arguments.size()):
		var argument: String = str(arguments[index]).strip_edges()
		var normalized_argument: String = argument.to_lower()
		if normalized_argument.begins_with("--port="):
			GameConfig.set_server_port(argument.substr("--port=".length()))
		elif normalized_argument.begins_with("--server-port="):
			GameConfig.set_server_port(argument.substr("--server-port=".length()))
		elif normalized_argument == "--port" or normalized_argument == "--server-port":
			if index + 1 < arguments.size():
				GameConfig.set_server_port(arguments[index + 1])
	var env_port: String = OS.get_environment("GOLEM_PORT").strip_edges()
	if !env_port.is_empty():
		GameConfig.set_server_port(env_port)

func should_start_dedicated_server() -> bool:
	if GameConfig.is_dedicated_server:
		return true
	for argument in get_network_command_line_arguments():
		var normalized_argument: String = str(argument).strip_edges().to_lower()
		if normalized_argument == "--golem-server" or normalized_argument == "--server" or normalized_argument == "--dedicated-server":
			GameConfig.is_dedicated_server = true
			return true
	var env_server: String = OS.get_environment("GOLEM_SERVER").strip_edges().to_lower()
	if env_server == "1" or env_server == "true" or env_server == "yes":
		GameConfig.is_dedicated_server = true
		return true
	return OS.has_feature("dedicated_server")

func get_network_command_line_arguments() -> Array[String]:
	var arguments: Array[String] = []
	for argument in OS.get_cmdline_args():
		arguments.append(str(argument))
	for argument in OS.get_cmdline_user_args():
		var user_argument: String = str(argument)
		if !arguments.has(user_argument):
			arguments.append(user_argument)
	return arguments

func is_using_single_server_room_mode() -> bool:
	return GameConfig.is_using_custom_server_multiplayer() and GameConfig.matchmaking_mode == GameConfig.MATCHMAKING_MODE_ROOM_LIST

func _process(delta: float) -> void:
	if !is_server or game_host == null:
		return
	# A host exists from the moment hosting starts; its clock must not run
	# down while it is still waiting for an opponent.
	if !multiplayer_game_started:
		poll_quick_match_while_waiting(delta)
		return
	game_host.process(delta)
	codex_bridge_poll_elapsed += delta
	if codex_bridge_poll_elapsed < 0.25:
		return
	codex_bridge_poll_elapsed = 0.0
	if game_host.process_codex_bridge_commands():
		game_host.broadcast_full_state()

func ensure_network_status_label() -> void:
	if network_status_label != null:
		return

	var canvas_layer: CanvasLayer = get_node_or_null("CanvasLayer") as CanvasLayer
	if canvas_layer == null:
		canvas_layer = CanvasLayer.new()
		canvas_layer.name = "CanvasLayer"
		add_child(canvas_layer)

	network_status_label = Label.new()
	network_status_label.name = "NetworkStatusLabel"
	network_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	network_status_label.position = Vector2(18, 18)
	network_status_label.size = Vector2(520, 34)
	network_status_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.78))
	network_status_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	network_status_label.add_theme_constant_override("shadow_offset_x", 2)
	network_status_label.add_theme_constant_override("shadow_offset_y", 2)
	canvas_layer.add_child(network_status_label)

func set_network_status(message: String) -> void:
	ensure_network_status_label()
	if network_status_label == null:
		return
	network_status_label.text = message

func ensure_custom_lobby_panel() -> void:
	if custom_lobby_panel != null:
		return

	var canvas_layer: CanvasLayer = get_node_or_null("CanvasLayer") as CanvasLayer
	if canvas_layer == null:
		canvas_layer = CanvasLayer.new()
		canvas_layer.name = "CanvasLayer"
		add_child(canvas_layer)

	var panel := PanelContainer.new()
	panel.name = "CustomLobbyPanel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -240.0
	panel.offset_top = -80.0
	panel.offset_right = 240.0
	panel.offset_bottom = 80.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	canvas_layer.add_child(panel)
	custom_lobby_panel = panel

	var container := VBoxContainer.new()
	container.name = "LobbyContainer"
	container.add_theme_constant_override("separation", 10)
	panel.add_child(container)

	var title_label := Label.new()
	title_label.text = tr("Server Room")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title_label)

	custom_lobby_status_label = Label.new()
	custom_lobby_status_label.text = tr("Connecting...")
	custom_lobby_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(custom_lobby_status_label)

func hide_custom_lobby_panel() -> void:
	if custom_lobby_panel != null:
		custom_lobby_panel.visible = false

func set_custom_lobby_status(message: String) -> void:
	ensure_custom_lobby_panel()
	if custom_lobby_status_label != null:
		custom_lobby_status_label.text = message

func set_custom_lobby_controls_enabled(enabled: bool) -> void:
	if custom_lobby_refresh_button != null:
		custom_lobby_refresh_button.disabled = !enabled
	if custom_lobby_create_button != null:
		custom_lobby_create_button.disabled = !enabled
	if custom_lobby_join_button != null:
		custom_lobby_join_button.disabled = !enabled

## A single-player match can open on the player's codex choice
## (MatchIntroController); the game is only set up once that is settled, so it
## deals from the codex that was picked.
func wait_for_deck_choice() -> void:
	var intro := get_node_or_null("MatchIntroController") as MatchIntroController
	if intro != null and intro.is_offering_deck_choice():
		await intro.deck_chosen

func start_singleplayer_game():
	is_server = true
	server_turn = true
	multiplayer_game_started = true
	connected_peer_ids = [1]
	peer_player_ids.clear()
	peer_player_ids[1] = get_local_human_player_id()
	peer_player_names.clear()
	peer_player_decks.clear()
	peer_player_portraits.clear()
	setup_singleplayer_player_names()
	ai_players.clear()

	game_host = NetworkGameHost.new()
	game_host.configure(self)
	GameController.set_game_host(game_host)

	var board_data = $MatchBoard.board
	game_host.initialize_game(board_data)
	game_host.game_state.current_turn_player = 0
	setup_singleplayer_ai_controllers()
	game_host.finish_if_player_has_no_valid_turn(game_host.game_state.current_turn_player)
	game_host.broadcast_full_state()
	if GameConfig.is_ai_vs_ai_batch:
		$MatchBoard.set_turn(null)
	else:
		$MatchBoard.set_turn(get_side_for_player_id(get_local_human_player_id()))

func setup_singleplayer_ai_controllers():
	ai_players.clear()
	for player_id in [0, 1]:
		if GameConfig.get_player_controller(player_id) == GameConfig.CONTROLLER_AI:
			var ai_difficulty_level: int = GameConfig.get_player_ai_difficulty_level(player_id)
			var ai_script = load("res://Scripts/HeuristicAIPlayer.gd")
			var ai_player = ai_script.new()
			ai_player.configure(player_id, ai_difficulty_level)
			# An early story boss can be set to guard its base worse than its
			# level does, so a new player's first wins come without many retries.
			var boss: BossDefinition = StoryManager.get_active_boss()
			if boss != null:
				ai_player.set_defense_scale(boss.ai_defense)
			if GameConfig.should_skip_ai_vs_ai_delays():
				ai_player.action_delay = 0.0
			# The per-turn "thinking" pause is for a human opponent; balance batches skip it.
			if GameConfig.is_ai_vs_ai_batch:
				ai_player.turn_delay_enabled = false
			ai_player.planner.thinking_pause_started.connect(ai_thinking_pause_started.emit)
			ai_players[player_id] = ai_player

func setup_singleplayer_player_names() -> void:
	for player_id in [0, 1]:
		if GameConfig.get_player_controller(player_id) == GameConfig.CONTROLLER_HUMAN:
			peer_player_names[player_id] = GameConfig.get_local_player_name()
			peer_player_portraits[player_id] = GameConfig.get_local_portrait_data()
		elif GameConfig.get_player_controller(player_id) == GameConfig.CONTROLLER_CODEX:
			peer_player_names[player_id] = tr("Codex")
			peer_player_portraits[player_id] = GameConfig.get_ai_portrait_data(player_id)
		else:
			# A story boss overrides both; without one these fall back to the
			# generic "AI White/Black" name and generated portrait.
			peer_player_names[player_id] = GameConfig.get_ai_opponent_name(player_id)
			peer_player_portraits[player_id] = GameConfig.get_ai_opponent_portrait_data(player_id)

## What the AI just did, in a form a listener can read without knowing
## anything about the AI's internals. Everything is optional: a simpler AI
## (RandomAIPlayer) has no evaluator or plan, and simply reports nothing.
func build_ai_turn_report(player_id: int, ai_player) -> Dictionary:
	var report: Dictionary = {
		"player_id": player_id,
		"strategy_mode": "",
		"affixed_stamp_names": [],
	}
	if ai_player == null:
		return report

	var evaluator = ai_player.get("evaluator")
	if evaluator != null:
		var profile = evaluator.get("last_profile")
		if profile is Dictionary:
			report["strategy_mode"] = str(profile.get("strategy_mode", ""))

	var affixed_stamp_names = ai_player.get("last_turn_affixed_stamp_names")
	if affixed_stamp_names is Array:
		report["affixed_stamp_names"] = affixed_stamp_names.duplicate()
	return report

func get_local_human_player_id() -> int:
	for player_id in [0, 1]:
		if GameConfig.get_player_controller(player_id) == GameConfig.CONTROLLER_HUMAN:
			return player_id
	return 0

func get_side_for_player_id(player_id: int) -> bool:
	return player_id == 0

func on_host_state_changed():
	host_state_changed.emit()
	maybe_play_singleplayer_ai_turn()

func maybe_play_singleplayer_ai_turn():
	if !GameConfig.is_singleplayer:
		return
	if game_host == null or game_host.game_state == null:
		return
	if ai_turn_in_progress or game_host.game_state.game_over:
		return

	var current_player_id: int = game_host.game_state.current_turn_player
	if !ai_players.has(current_player_id):
		return

	ai_turn_in_progress = true
	call_deferred("_play_singleplayer_ai_turn", current_player_id)

func _play_singleplayer_ai_turn(player_id: int):
	if !GameConfig.should_skip_ai_vs_ai_delays():
		await get_tree().create_timer(0.45).timeout
	var ai_player = ai_players.get(player_id, null)
	if ai_player != null and game_host != null and !game_host.game_state.game_over and game_host.game_state.current_turn_player == player_id:
		await ai_player.play_turn(game_host, get_tree())
		ai_turn_finished.emit(player_id, build_ai_turn_report(player_id, ai_player))

	ai_turn_in_progress = false
	maybe_play_singleplayer_ai_turn()

func host_game(port = 9999):
	set_network_status(tr("Hosting on UDP %d. Waiting for peer...") % port)
	DebugLog.network("Starting ENet host on UDP port %d. Local IPv4 addresses: %s" % [port, get_local_address_summary()])
	var error = multiplayer_peer.create_server(port, 2, 0, 0, 0)

	if error != OK:
		var error_message: String = "Failed to start ENet server on UDP port %d. Error code: %d" % [port, error]
		set_network_status(tr("Host failed on UDP %d.") % port)
		DebugLog.network_error(error_message)
		push_error(error_message)
		return false

	DebugLog.info("Server started on port %d" % port)
	DebugLog.network("ENet server started on UDP port %d. Waiting for remote peer." % port)
	call_deferred("_log_host_connection_status_after_delay", port)
	start_hosting_match()
	return true

## Takes over once multiplayer_peer listens, whatever carries the connection
## (ENet or Steam): this player is peer 1, hosts the game and waits here for
## the opponent.
func start_hosting_match() -> void:
	is_server = true
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	server_turn = true if randi_range(0, 1) else false
	multiplayer_game_started = false

	game_host = NetworkGameHost.new()
	game_host.configure(self)
	GameController.set_game_host(game_host)
	peer_player_names[1] = GameConfig.get_local_player_name()
	peer_player_decks[1] = GameConfig.get_selected_deck_stamp_names()
	peer_player_portraits[1] = GameConfig.get_local_portrait_data()

	_on_peer_connected(1)

func start_dedicated_custom_server(port: int = 9999) -> bool:
	set_network_status(tr("Dedicated server listening on UDP %d.") % port)
	hide_custom_lobby_panel()
	DebugLog.network("Starting dedicated custom server on UDP port %d. Local IPv4 addresses: %s" % [port, get_local_address_summary()])
	var error = multiplayer_peer.create_server(port, MAX_DEDICATED_SERVER_CLIENTS, 0, 0, 0)

	if error != OK:
		var error_message: String = "Failed to start dedicated custom server on UDP port %d. Error code: %d" % [port, error]
		set_network_status(tr("Dedicated server failed on UDP %d.") % port)
		DebugLog.network_error(error_message)
		push_error(error_message)
		return false

	is_server = true
	is_dedicated_server = true
	GameConfig.is_dedicated_server = true
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	server_turn = true
	multiplayer_game_started = false
	connected_peer_ids.clear()
	server_connected_peer_ids.clear()
	open_lobbies.clear()
	peer_player_ids.clear()
	peer_player_names.clear()
	peer_player_decks.clear()
	peer_player_portraits.clear()
	GameController.set_game_host(null)

	DebugLog.network("Dedicated custom server started on UDP port %d." % port)
	return true

func join_game(ip, port = 9999):
	set_network_status(tr("Connecting to %s:%d...") % [ip, port])
	DebugLog.network("Starting ENet client. Target=%s:%d" % [ip, port])
	var error = multiplayer_peer.create_client(ip, port)
	if error != OK:
		var error_message: String = "Failed to create ENet client for %s:%d. Error code: %d" % [ip, port, error]
		set_network_status(tr("Connection setup failed."))
		DebugLog.network_error(error_message)
		push_error(error_message)
		return false

	DebugLog.info("Connecting to %s:%d" % [ip, port])
	DebugLog.network("ENet client created. Waiting for connection result from %s:%d" % [ip, port])
	start_joining_match()
	call_deferred("_log_client_connection_status_after_delay", ip, port)
	return true

## Takes over once multiplayer_peer is connecting to a host, whatever carries
## the connection (ENet or Steam). _on_connection_succeeded follows.
func start_joining_match() -> void:
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer.connected_to_server.connect(_on_connection_succeeded)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	GameController.set_game_host(self)

#region Steam
## The Steam lobby helper, created the first time a Steam match needs it.
func ensure_steam_matchmaking() -> SteamMatchmakingClient:
	if steam_matchmaking == null:
		steam_matchmaking = SteamMatchmakingClient.new()
		steam_matchmaking.name = "SteamMatchmaking"
		add_child(steam_matchmaking)
		steam_matchmaking.matchmaking_failed.connect(return_to_multiplayer_menu)
	return steam_matchmaking

## Hosting over Steam: open a lobby, then listen on it. The friend joins by
## invite, a quick-match opponent by finding the lobby; either way Steam
## relays the connection, so nobody needs an address or an open port.
func host_steam_game() -> void:
	set_network_status(tr("Creating Steam lobby..."))
	var matchmaking: SteamMatchmakingClient = ensure_steam_matchmaking()
	matchmaking.lobby_created.connect(_on_steam_lobby_created)
	matchmaking.lobby_list_updated.connect(_on_steam_quick_match_lobbies)
	matchmaking.create_lobby(GameConfig.get_local_player_name(), GameConfig.get_selected_deck_stamp_names())

func _on_steam_lobby_created(lobby: MultiplayerLobby) -> void:
	# Untyped: the class only exists while the Steam extension is loaded.
	var peer = ClassDB.instantiate("SteamMultiplayerPeer")
	if peer == null or peer.create_host(0) != OK:
		return_to_multiplayer_menu(tr("Could not create the Steam lobby."))
		return
	multiplayer_peer = peer
	DebugLog.network("Hosting Steam lobby %s (%s)." % [lobby.lobby_id, GameConfig.matchmaking_mode])
	start_hosting_match()
	if GameConfig.matchmaking_mode == GameConfig.MATCHMAKING_MODE_QUICK_MATCH:
		set_network_status(tr("Waiting for a Steam opponent..."))
	else:
		set_network_status(tr("Waiting for your friend. Invite them in the Steam overlay (Shift+Tab)."))
		steam_matchmaking.invite_friend("")

func join_steam_game(lobby_id: String) -> void:
	set_network_status(tr("Joining Steam lobby..."))
	var matchmaking: SteamMatchmakingClient = ensure_steam_matchmaking()
	matchmaking.lobby_entered.connect(_on_steam_lobby_entered)
	var lobby := MultiplayerLobby.new()
	lobby.lobby_id = lobby_id
	matchmaking.join_lobby(lobby)

func _on_steam_lobby_entered(lobby: MultiplayerLobby, owner_steam_id: int) -> void:
	var peer = ClassDB.instantiate("SteamMultiplayerPeer")
	if peer == null or peer.create_client(owner_steam_id, 0) != OK:
		return_to_multiplayer_menu(tr("Could not connect to the host through Steam."))
		return
	multiplayer_peer = peer
	DebugLog.network("Joined Steam lobby %s; connecting to its owner %d." % [lobby.lobby_id, owner_steam_id])
	set_network_status(tr("Connecting to the host through Steam..."))
	start_joining_match()

## Two players who search at the same moment both find nothing, both open a
## lobby and would wait for ever. So a host waiting in a quick-match lobby keeps
## looking, and whichever of the two has the newer lobby moves to the older one.
func poll_quick_match_while_waiting(delta: float) -> void:
	if steam_matchmaking == null or steam_matchmaking.lobby_id == 0:
		return
	if GameConfig.matchmaking_mode != GameConfig.MATCHMAKING_MODE_QUICK_MATCH:
		return
	quick_match_recheck_elapsed += delta
	if quick_match_recheck_elapsed < QUICK_MATCH_RECHECK_INTERVAL:
		return
	quick_match_recheck_elapsed = 0.0
	steam_matchmaking.refresh_lobbies()

func _on_steam_quick_match_lobbies(lobbies: Array) -> void:
	if multiplayer_game_started or connected_peer_ids.size() >= 2:
		return
	for lobby in lobbies:
		if lobby.is_joinable() and int(lobby.lobby_id) < steam_matchmaking.lobby_id:
			DebugLog.network("Quick match: moving from our lobby %d to the older lobby %s." % [steam_matchmaking.lobby_id, lobby.lobby_id])
			close_game_connection()
			GameConfig.prepare_steam_join(lobby.lobby_id, GameConfig.MATCHMAKING_MODE_QUICK_MATCH)
			SceneTransition.change_scene(MATCH_SCENE)
			return
#endregion

## Leaves this scene for the multiplayer menu, which shows message.
func return_to_multiplayer_menu(message: String) -> void:
	if match_peer_left_return_scheduled:
		return
	match_peer_left_return_scheduled = true
	DebugLog.network_error(message)
	GameConfig.set_multiplayer_menu_status_message(message)
	close_game_connection()
	SceneTransition.change_scene(MULTIPLAYER_MENU_SCENE)

func _log_host_connection_status_after_delay(port: int) -> void:
	await get_tree().create_timer(CONNECTION_DIAGNOSTIC_DELAY).timeout
	if !is_server:
		return
	var status_text: String = get_peer_connection_status_text()
	var peer_summary: String = str(multiplayer.get_peers())
	DebugLog.network("Host diagnostic after %.1fs: status=%s local_and_remote_players=%d/2 multiplayer_peers=%s udp_port=%d" % [
		CONNECTION_DIAGNOSTIC_DELAY,
		status_text,
		connected_peer_ids.size(),
		peer_summary,
		port,
	])
	if connected_peer_ids.size() < 2:
		set_network_status(tr("Hosting on UDP %d. Still waiting for peer.") % port)
		DebugLog.network_error("No remote peer reached the host. Most likely cause: UDP %d is not forwarded to this PC, Windows Firewall blocked the game, wrong public IP was used, or the host is behind CGNAT." % port)

func _log_client_connection_status_after_delay(ip: String, port: int) -> void:
	await get_tree().create_timer(CONNECTION_DIAGNOSTIC_DELAY).timeout
	if is_server:
		return
	var status_text: String = get_peer_connection_status_text()
	var peer_summary: String = str(multiplayer.get_peers())
	DebugLog.network("Client diagnostic after %.1fs: status=%s multiplayer_peers=%s target=%s:%d" % [
		CONNECTION_DIAGNOSTIC_DELAY,
		status_text,
		peer_summary,
		ip,
		port,
	])
	if status_text != "connected":
		set_network_status(tr("Connection failed or timed out."))
		set_custom_lobby_status(tr("Connection failed or timed out: %s:%d") % [ip, port])
		set_custom_lobby_controls_enabled(false)
		DebugLog.network_error("Client is not connected to %s:%d. Check that the host gave the public IPv4 address and UDP %d is reachable." % [ip, port, port])

func get_local_address_summary() -> String:
	var addresses: PackedStringArray = IP.get_local_addresses()
	var ipv4_summary: String = ""
	for address_value in addresses:
		var address: String = str(address_value)
		if address.find(":") != -1:
			continue
		if address.begins_with("127."):
			continue
		if !ipv4_summary.is_empty():
			ipv4_summary += ", "
		ipv4_summary += address
	if !ipv4_summary.is_empty():
		return ipv4_summary

	var fallback_summary: String = ""
	for address_value in addresses:
		if !fallback_summary.is_empty():
			fallback_summary += ", "
		fallback_summary += str(address_value)
	return fallback_summary if !fallback_summary.is_empty() else "none"

func get_peer_connection_status_text() -> String:
	match multiplayer_peer.get_connection_status():
		MultiplayerPeer.CONNECTION_CONNECTED:
			return "connected"
		MultiplayerPeer.CONNECTION_CONNECTING:
			return "connecting"
		MultiplayerPeer.CONNECTION_DISCONNECTED:
			return "disconnected"
		_:
			return "unknown"

func _on_peer_connected(peer_id):
	if !is_server:
		return

	DebugLog.info("Player connected: %s" % peer_id)
	DebugLog.network("Peer connected: %s" % peer_id)

	if is_dedicated_server:
		if !server_connected_peer_ids.has(peer_id):
			server_connected_peer_ids.append(peer_id)
		set_network_status(tr("Dedicated server clients: %d") % server_connected_peer_ids.size())
		DebugLog.network("Dedicated server accepted connection shell for peer %s." % peer_id)
		return

	if connected_peer_ids.size() < 2 && !connected_peer_ids.has(peer_id):
		connected_peer_ids.append(peer_id)
		DebugLog.info("  Players: %d/2" % connected_peer_ids.size())
		DebugLog.network("Connected players: %d/2" % connected_peer_ids.size())
		set_network_status(tr("Connected players: %d/2") % connected_peer_ids.size())
		_try_start_multiplayer_game()

func _on_peer_disconnected(peer_id):
	if !is_server:
		return

	DebugLog.info("Player disconnected: %s" % peer_id)
	DebugLog.network("Peer disconnected: %s" % peer_id)
	var was_rejected_for_version: bool = peer_client_versions.has(peer_id) and !is_peer_version_accepted(peer_id)
	peer_client_versions.erase(peer_id)
	if is_dedicated_server:
		var should_close_remaining_match_peer: bool = should_close_remaining_peer_after_disconnect(peer_id)
		var left_player_id: int = int(peer_player_ids.get(peer_id, -1))
		server_connected_peer_ids.erase(peer_id)
		remove_lobbies_for_peer(peer_id)
		connected_peer_ids.erase(peer_id)
		if should_close_remaining_match_peer and !connected_peer_ids.is_empty():
			# The names stay until the forfeit is broadcast, so the result
			# still shows who left.
			close_remaining_match_peers_after_disconnect(peer_id, left_player_id)
		peer_player_ids.erase(peer_id)
		peer_player_names.erase(peer_id)
		peer_player_decks.erase(peer_id)
		peer_player_portraits.erase(peer_id)
		if connected_peer_ids.is_empty():
			reset_dedicated_server_room()
		elif !should_close_remaining_match_peer:
			set_network_status(tr("Dedicated server clients: %d") % server_connected_peer_ids.size())
		broadcast_open_lobby_list()
		return

	connected_peer_ids.erase(peer_id)
	if should_close_host_after_direct_peer_disconnect(peer_id):
		award_match_to_remaining_player(int(peer_player_ids[peer_id]))
	peer_player_names.erase(peer_id)
	peer_player_decks.erase(peer_id)
	peer_player_portraits.erase(peer_id)
	# Keep what the status already says: the forfeit result, or why a peer
	# with another game version was sent away.
	if multiplayer_game_started or was_rejected_for_version:
		return
	DebugLog.info("  Players: %d/2" % connected_peer_ids.size())
	DebugLog.network("Connected players: %d/2" % connected_peer_ids.size())
	set_network_status(tr("Connected players: %d/2") % connected_peer_ids.size())

func _on_connection_succeeded():
	DebugLog.info("Connected to server")
	DebugLog.network("Connected to server. Local peer id: %s" % multiplayer.get_unique_id())
	# Nothing else goes out until the host answers with the same version: a
	# build with other RPCs would read any other message as a different call.
	set_network_status(tr("Connected. Checking game version..."))
	announce_client_version.rpc_id(1, GameConfig.get_game_version())

## Runs once the host confirmed it plays the same game version.
func enter_match_after_version_check() -> void:
	if is_using_single_server_room_mode():
		set_network_status(tr("Connected. Joining server room..."))
		set_custom_lobby_status(tr("Joining server room..."))
		set_custom_lobby_controls_enabled(false)
		enter_custom_server_room.rpc_id(1, GameConfig.get_local_player_name(), GameConfig.get_selected_deck_stamp_names(), GameConfig.get_local_portrait_data())
	else:
		set_network_status(tr("Connected. Registering player..."))
		register_player_name.rpc_id(1, multiplayer.get_unique_id(), GameConfig.get_local_player_name(), GameConfig.get_selected_deck_stamp_names(), GameConfig.get_local_portrait_data())

func _on_connection_failed():
	if GameConfig.is_using_steam_multiplayer():
		return_to_multiplayer_menu(tr("Could not connect to the host through Steam."))
		return
	var error_message: String = tr("Connection failed for %s:%d. Check host UDP port forwarding and firewall.") % [GameConfig.server_ip, GameConfig.server_port]
	set_network_status(tr("Connection failed."))
	set_custom_lobby_status(error_message)
	set_custom_lobby_controls_enabled(false)
	DebugLog.network_error(error_message)
	push_error(error_message)

func _on_server_disconnected():
	DebugLog.info("Server disconnected")
	set_network_status(tr("Server disconnected."))
	set_custom_lobby_status(tr("Server disconnected."))
	set_custom_lobby_controls_enabled(false)
	DebugLog.network_error("Server disconnected.")
	if !has_received_match_state():
		# A Steam host gone before the first state leaves nothing to wait for.
		var match_board = get_node_or_null("MatchBoard")
		var match_started: bool = match_board != null and bool(match_board.get("has_received_server_state"))
		if GameConfig.is_using_steam_multiplayer() and !match_started:
			return_to_multiplayer_menu(tr("The host left before the match started."))
		return
	# Losing a dedicated server is nobody's forfeit. Losing a host that is the
	# opponent's own game is: they left, so this player wins.
	if is_using_single_server_room_mode():
		receive_match_peer_left("Opponent left. Returning to menu in 5 seconds.")
		return
	claim_win_after_host_left()

## The host is gone, so no game-over state is coming: the result is decided
## here, through the same match-end flow a won game takes.
func claim_win_after_host_left() -> void:
	var match_board = get_node_or_null("MatchBoard")
	if match_board == null:
		return
	set_network_status(tr("Opponent left. You win."))
	DebugLog.network("Host left an active match; claiming the win locally.")
	match_board.finish_game(match_board.get_own_color())

func close_game_connection():
	if game_host != null:
		game_host.detach_multiplayer_node()
	game_host = null
	GameController.set_game_host(null)
	multiplayer_peer.close()
	if steam_matchmaking != null:
		steam_matchmaking.leave_lobby()
	# The story flow can swap the scene before this runs (instantly, with the
	# transition skipped); out of the tree there is no MultiplayerAPI to clear.
	if is_inside_tree():
		multiplayer.multiplayer_peer = null

func request_lobby_list_from_server() -> void:
	if !can_send_custom_lobby_request():
		report_custom_lobby_connection_problem()
		return
	request_custom_lobby_list.rpc_id(1)

func create_lobby_on_server() -> void:
	if !can_send_custom_lobby_request():
		report_custom_lobby_connection_problem()
		return
	set_custom_lobby_status(tr("Joining server room..."))
	enter_custom_server_room.rpc_id(1, GameConfig.get_local_player_name(), GameConfig.get_selected_deck_stamp_names(), GameConfig.get_local_portrait_data())

func join_lobby_on_server(lobby_id: String) -> void:
	if !can_send_custom_lobby_request():
		report_custom_lobby_connection_problem()
		return
	set_custom_lobby_status(tr("Joining room..."))
	join_custom_lobby.rpc_id(1, lobby_id, GameConfig.get_local_player_name(), GameConfig.get_selected_deck_stamp_names(), GameConfig.get_local_portrait_data())

func can_send_custom_lobby_request() -> bool:
	return !is_server \
		&& multiplayer.multiplayer_peer != null \
		&& multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED \
		&& multiplayer.get_unique_id() != 1

func report_custom_lobby_connection_problem() -> void:
	var status_text: String = get_peer_connection_status_text()
	var message: String = tr("Not connected to the custom server as a client. Status: %s. Target: %s:%d.") % [
		status_text,
		GameConfig.server_ip,
		GameConfig.server_port,
	]
	if is_server or multiplayer.get_unique_id() == 1:
		message = tr("This game instance is the server. Start a separate client window for Server Room.")
	custom_lobby_failed.emit(message)
	set_custom_lobby_status(message)
	DebugLog.network_error("%s status=%s is_server=%s unique_id=%s" % [
		message,
		get_peer_connection_status_text(),
		is_server,
		multiplayer.get_unique_id(),
	])

func _on_custom_lobby_refresh_pressed() -> void:
	create_lobby_on_server()

func _on_custom_lobby_create_pressed() -> void:
	create_lobby_on_server()

func _on_custom_lobby_join_pressed() -> void:
	create_lobby_on_server()

func _on_custom_lobby_item_activated(index: int) -> void:
	join_custom_lobby_at_index(index)

func join_custom_lobby_at_index(index: int) -> void:
	if index < 0 or index >= custom_lobby_entries.size():
		set_custom_lobby_status(tr("That room is no longer available."))
		return
	var lobby: MultiplayerLobby = custom_lobby_entries[index]
	if !lobby.is_joinable():
		set_custom_lobby_status(tr("That room is no longer joinable."))
		return
	join_lobby_on_server(lobby.lobby_id)

@rpc("any_peer", "call_remote", "reliable")
func request_custom_lobby_list() -> void:
	if !is_server or !is_dedicated_server:
		return
	var peer_id: int = multiplayer.get_remote_sender_id()
	if !ensure_peer_version_accepted(peer_id):
		return
	send_open_lobby_list_to_peer(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func enter_custom_server_room(player_name: String, deck_stamp_names: Array = [], portrait_data: Dictionary = {}) -> void:
	if !is_server or !is_dedicated_server:
		return
	var peer_id: int = multiplayer.get_remote_sender_id()
	if !ensure_peer_version_accepted(peer_id):
		return
	if multiplayer_game_started or connected_peer_ids.size() >= 2:
		send_custom_lobby_error(peer_id, "Server room is full. Please try again in a few minutes.")
		call_deferred("disconnect_dedicated_peer_after_delay", peer_id)
		return

	register_dedicated_peer_data(peer_id, player_name, deck_stamp_names, portrait_data)
	if !connected_peer_ids.has(peer_id):
		connected_peer_ids.append(peer_id)

	if connected_peer_ids.size() == 1:
		receive_custom_room_waiting.rpc_id(peer_id, "Waiting for another player.")
		set_network_status(tr("Dedicated server room: 1/2. Waiting for another player."))
		DebugLog.network("Peer %d is waiting in the single server room." % peer_id)
		return

	await start_dedicated_match(int(connected_peer_ids[0]), int(connected_peer_ids[1]))

@rpc("any_peer", "call_remote", "reliable")
func create_custom_lobby(player_name: String, deck_stamp_names: Array = [], portrait_data: Dictionary = {}) -> void:
	if !is_server or !is_dedicated_server:
		return
	var peer_id: int = multiplayer.get_remote_sender_id()
	if !ensure_peer_version_accepted(peer_id):
		return
	if multiplayer_game_started:
		send_custom_lobby_error(peer_id, "A match is already running on this alpha server.")
		return
	remove_lobbies_for_peer(peer_id)
	register_dedicated_peer_data(peer_id, player_name, deck_stamp_names, portrait_data)

	var lobby_id: String = "custom-%d-%d" % [peer_id, Time.get_unix_time_from_system()]
	open_lobbies[lobby_id] = {
		"lobby_id": lobby_id,
		"host_peer_id": peer_id,
		"host_name": GameConfig.sanitize_player_name(player_name),
		"player_count": 1,
		"max_players": 2,
		"status": MultiplayerLobby.STATUS_OPEN,
		"endpoint_ip": GameConfig.server_ip,
		"endpoint_port": GameConfig.server_port,
		"provider": GameConfig.MULTIPLAYER_PROVIDER_CUSTOM_SERVER,
		"matchmaking_mode": GameConfig.MATCHMAKING_MODE_ROOM_LIST,
	}
	DebugLog.network("Custom lobby created by peer %d: %s" % [peer_id, lobby_id])
	broadcast_open_lobby_list()

@rpc("any_peer", "call_remote", "reliable")
func join_custom_lobby(lobby_id: String, player_name: String, deck_stamp_names: Array = [], portrait_data: Dictionary = {}) -> void:
	if !is_server or !is_dedicated_server:
		return
	var peer_id: int = multiplayer.get_remote_sender_id()
	if !ensure_peer_version_accepted(peer_id):
		return
	if multiplayer_game_started:
		send_custom_lobby_error(peer_id, "A match is already running on this alpha server.")
		return
	if !open_lobbies.has(lobby_id):
		send_custom_lobby_error(peer_id, "This lobby no longer exists.")
		return

	var lobby: Dictionary = open_lobbies[lobby_id]
	var host_peer_id: int = int(lobby.get("host_peer_id", 0))
	if host_peer_id == peer_id:
		send_custom_lobby_error(peer_id, "You are already hosting this lobby.")
		return
	if !server_connected_peer_ids.has(host_peer_id):
		open_lobbies.erase(lobby_id)
		send_custom_lobby_error(peer_id, "The lobby host disconnected.")
		broadcast_open_lobby_list()
		return

	register_dedicated_peer_data(peer_id, player_name, deck_stamp_names, portrait_data)
	open_lobbies.erase(lobby_id)
	await start_dedicated_match(host_peer_id, peer_id)

func register_dedicated_peer_data(peer_id: int, player_name: String, deck_stamp_names: Array = [], portrait_data: Dictionary = {}) -> void:
	peer_player_names[peer_id] = GameConfig.sanitize_player_name(player_name)
	peer_player_decks[peer_id] = duplicate_string_array(deck_stamp_names)
	peer_player_portraits[peer_id] = PortraitLibrary.config_from_data_or_default(portrait_data, 0).to_dict()

func send_open_lobby_list_to_peer(peer_id: int) -> void:
	if peer_id <= 0:
		return
	receive_custom_lobby_list.rpc_id(peer_id, serialize_open_lobbies())

func broadcast_open_lobby_list() -> void:
	var serialized_lobbies: Array = serialize_open_lobbies()
	for peer_id in server_connected_peer_ids:
		# Only to peers past the version handshake: anyone else may read this
		# message as a different call.
		if is_peer_version_accepted(peer_id):
			receive_custom_lobby_list.rpc_id(peer_id, serialized_lobbies)

func serialize_open_lobbies() -> Array:
	var serialized_lobbies: Array = []
	for lobby_id in open_lobbies:
		var lobby: Dictionary = open_lobbies[lobby_id]
		serialized_lobbies.append(lobby.duplicate(true))
	return serialized_lobbies

func remove_lobbies_for_peer(peer_id: int) -> void:
	var lobbies_to_remove: Array[String] = []
	for lobby_id in open_lobbies:
		var lobby: Dictionary = open_lobbies[lobby_id]
		if int(lobby.get("host_peer_id", 0)) == peer_id:
			lobbies_to_remove.append(str(lobby_id))
	for lobby_id in lobbies_to_remove:
		open_lobbies.erase(lobby_id)

func send_custom_lobby_error(peer_id: int, message: String) -> void:
	if peer_id <= 0:
		return
	receive_custom_lobby_error.rpc_id(peer_id, message)

func disconnect_dedicated_peer(peer_id: int) -> void:
	if multiplayer_peer != null and peer_id > 1:
		multiplayer_peer.disconnect_peer(peer_id)

func disconnect_dedicated_peer_after_delay(peer_id: int) -> void:
	await get_tree().create_timer(0.35).timeout
	disconnect_dedicated_peer(peer_id)

func should_close_remaining_peer_after_disconnect(peer_id: int) -> bool:
	if !is_dedicated_server or !multiplayer_game_started:
		return false
	if !connected_peer_ids.has(peer_id):
		return false
	if game_host == null or game_host.game_state == null:
		return false
	return !game_host.game_state.game_over

func should_close_host_after_direct_peer_disconnect(peer_id: int) -> bool:
	if is_dedicated_server or !multiplayer_game_started:
		return false
	if !peer_player_ids.has(peer_id):
		return false
	if game_host == null or game_host.game_state == null:
		return false
	return !game_host.game_state.game_over

func has_received_match_state() -> bool:
	var match_board = get_node_or_null("MatchBoard")
	return match_board != null and bool(match_board.get("has_received_server_state")) and !bool(match_board.get("game_over"))

## A player who leaves a running dedicated match forfeits it. The one still
## connected gets the game-over state like any other win; its own match-end flow
## then leaves the server, which frees the room. The delayed disconnect is only
## the fallback for a client that never does.
func close_remaining_match_peers_after_disconnect(disconnected_peer_id: int, left_player_id: int) -> void:
	set_network_status(tr("A player left. Closing the match in 5 seconds."))
	DebugLog.network("Peer %d left an active dedicated match; the remaining player wins." % disconnected_peer_id)
	award_match_to_remaining_player(left_player_id)
	call_deferred("disconnect_remaining_match_peers_after_delay", connected_peer_ids.duplicate())

func disconnect_remaining_match_peers_after_delay(peer_ids: Array) -> void:
	await get_tree().create_timer(FORFEIT_DISCONNECT_FALLBACK_DELAY).timeout
	for peer_id in peer_ids:
		if server_connected_peer_ids.has(peer_id):
			disconnect_dedicated_peer(int(peer_id))

## Ends the match in favour of whoever did not leave, through the same
## game-over state a won game sends, so both the host's own board and a
## remaining client show it as a win.
func award_match_to_remaining_player(left_player_id: int) -> void:
	if left_player_id != 0 and left_player_id != 1:
		return
	if game_host == null or game_host.game_state == null or game_host.game_state.game_over:
		return
	if !is_dedicated_server:
		set_network_status(tr("Opponent left. You win."))
	DebugLog.network("Player %d left the match; player %d wins." % [left_player_id, 1 - left_player_id])
	game_host.finish_game(1 - left_player_id, "opponent_left")
	game_host.broadcast_full_state()

func reset_dedicated_server_room() -> void:
	multiplayer_game_started = false
	server_turn = true
	game_host = null
	GameController.set_game_host(null)
	set_network_status(tr("Dedicated server room is open."))
	DebugLog.network("Dedicated server room reset and is open.")

func start_dedicated_match(host_peer_id: int, joining_peer_id: int) -> void:
	if multiplayer_game_started:
		return
	multiplayer_game_started = true
	server_turn = true if randi_range(0, 1) else false
	connected_peer_ids = [host_peer_id, joining_peer_id]
	peer_player_ids.clear()
	peer_player_ids[host_peer_id] = 0 if server_turn else 1
	peer_player_ids[joining_peer_id] = 1 if server_turn else 0

	game_host = NetworkGameHost.new()
	game_host.configure(self)
	GameController.set_game_host(game_host)
	var board_data = $MatchBoard.board
	game_host.initialize_game(board_data)
	# The colours are drawn above; white always starts.
	game_host.game_state.current_turn_player = BoardConfig.WHITE_PLAYER_ID
	game_host.finish_if_player_has_no_valid_turn(game_host.game_state.current_turn_player)
	game_host.broadcast_full_state()
	broadcast_open_lobby_list()

	await get_tree().create_timer(0.2).timeout
	give_turn.rpc_id(host_peer_id, server_turn)
	give_turn.rpc_id(joining_peer_id, !server_turn)
	set_network_status(tr("Dedicated match running: %d vs %d") % [host_peer_id, joining_peer_id])
	DebugLog.network("Dedicated custom match started: %d vs %d server_turn=%s" % [host_peer_id, joining_peer_id, server_turn])

@rpc("authority", "call_remote", "reliable")
func receive_custom_lobby_list(raw_lobbies: Array) -> void:
	var lobbies: Array[MultiplayerLobby] = []
	for raw_lobby in raw_lobbies:
		if raw_lobby is Dictionary:
			lobbies.append(MultiplayerLobby.from_dictionary(raw_lobby))
	custom_lobby_entries = lobbies
	update_custom_lobby_list_ui()
	custom_lobby_list_updated.emit(lobbies)

@rpc("authority", "call_remote", "reliable")
func receive_custom_lobby_error(message: String) -> void:
	var translated_message: String = tr(message)
	custom_lobby_failed.emit(translated_message)
	set_network_status(translated_message)
	set_custom_lobby_status(translated_message)
	if is_using_single_server_room_mode():
		GameConfig.set_multiplayer_menu_status_message(translated_message)
		close_game_connection()
		SceneTransition.change_scene("res://Scenes/MultiplayerMenu.tscn")

@rpc("authority", "call_remote", "reliable")
func receive_custom_room_waiting(message: String) -> void:
	set_network_status(tr(message))
	set_custom_lobby_status(tr(message))

@rpc("authority", "call_remote", "reliable")
func receive_match_peer_left(message: String) -> void:
	if match_peer_left_return_scheduled:
		return
	match_peer_left_return_scheduled = true
	set_network_status(tr(message))
	if is_using_single_server_room_mode():
		set_custom_lobby_status(tr(message))
	call_deferred("return_to_menu_after_match_peer_left")

func return_to_menu_after_match_peer_left() -> void:
	await get_tree().create_timer(5.0).timeout
	close_game_connection()
	if get_tree():
		SceneTransition.change_scene("res://Scenes/MainMenu.tscn")

func update_custom_lobby_list_ui() -> void:
	ensure_custom_lobby_panel()
	if custom_lobby_item_list == null:
		return
	custom_lobby_item_list.clear()
	for lobby in custom_lobby_entries:
		custom_lobby_item_list.add_item(lobby.get_display_name())
	if custom_lobby_entries.is_empty():
		set_custom_lobby_status(tr("Waiting for another player."))
	else:
		set_custom_lobby_status(tr("Server room is available."))

## The peer id argument is kept for older clients that still send it, but never
## trusted: who is registering is whoever the network says sent this.
@rpc("any_peer", "call_local", "reliable")
func register_player_name(_claimed_peer_id: int, player_name: String, deck_stamp_names: Array = [], portrait_data: Dictionary = {}):
	if !is_server:
		return
	var peer_id: int = get_rpc_sender_peer_id()
	if !ensure_peer_version_accepted(peer_id):
		return

	DebugLog.network("Registering peer %s as '%s' with %d deck stamps." % [peer_id, GameConfig.sanitize_player_name(player_name), deck_stamp_names.size()])
	peer_player_names[peer_id] = GameConfig.sanitize_player_name(player_name)
	peer_player_decks[peer_id] = duplicate_string_array(deck_stamp_names)
	peer_player_portraits[peer_id] = PortraitLibrary.config_from_data_or_default(portrait_data, int(peer_player_ids.get(peer_id, 0))).to_dict()
	_try_start_multiplayer_game()
	if game_host != null && game_host.game_state != null && game_host.game_state.player_hands.has(0):
		game_host.broadcast_full_state()

func _try_start_multiplayer_game() -> void:
	if !is_server or GameConfig.is_singleplayer or multiplayer_game_started:
		return
	if connected_peer_ids.size() < 2:
		set_network_status(tr("Connected players: %d/2. Waiting for peer...") % connected_peer_ids.size())
		DebugLog.network("Waiting for remote peer. Connected players: %d/2" % connected_peer_ids.size())
		return

	for peer_id in connected_peer_ids:
		if !peer_player_names.has(peer_id) or !peer_player_decks.has(peer_id):
			set_network_status(tr("Waiting for peer registration..."))
			DebugLog.network("Waiting for peer registration data. Peer=%s has_name=%s has_deck=%s" % [
				peer_id,
				peer_player_names.has(peer_id),
				peer_player_decks.has(peer_id),
			])
			return

	multiplayer_game_started = true
	# A Steam lobby with a match on must not turn up in quick-match searches.
	if steam_matchmaking != null:
		steam_matchmaking.set_lobby_joinable(false)
	var first_player_id: int = 0 if server_turn else 1
	peer_player_ids[connected_peer_ids[0]] = first_player_id
	peer_player_ids[connected_peer_ids[1]] = 1 - first_player_id
	DebugLog.info("Game starting")
	DebugLog.network("Game starting. peer_ids=%s server_turn=%s first_player_id=%d" % [connected_peer_ids, server_turn, first_player_id])
	set_network_status(tr("Game starting..."))

	var board_data = $MatchBoard.board
	game_host.initialize_game(board_data)
	# The colours are drawn above; white always starts.
	game_host.game_state.current_turn_player = BoardConfig.WHITE_PLAYER_ID
	game_host.finish_if_player_has_no_valid_turn(game_host.game_state.current_turn_player)
	game_host.broadcast_full_state()

	await get_tree().create_timer(0.2).timeout

	if connected_peer_ids[0] == 1:
		$MatchBoard.set_turn(server_turn)
	else:
		give_turn.rpc_id(connected_peer_ids[0], server_turn)

	give_turn.rpc_id(connected_peer_ids[1], !server_turn)

func on_player_action(action: Dictionary):
	send_player_action.rpc_id(1, multiplayer.get_unique_id(), action)
	return true

## The peer id argument is kept for older clients that still send it, but never
## trusted: the action is played for the player the sending connection owns,
## whatever player id it claims, so nobody can act for their opponent.
@rpc("any_peer", "call_local", "reliable")
func send_player_action(_claimed_peer_id: int, action: Dictionary):
	if !is_server || game_host == null:
		return

	var peer_id: int = get_rpc_sender_peer_id()
	if !peer_player_ids.has(peer_id):
		DebugLog.network("Ignored an action from peer %d, which plays no side in this match." % peer_id)
		return
	action["player_id"] = int(peer_player_ids[peer_id])
	var revision_before: int = game_host.state_revision
	game_host.on_player_action(action)
	# A rejected action changes nothing and broadcasts nothing. The sender's
	# board may already show it under way (a stamp lifted off the codex), so
	# it gets the unchanged state back to drop that.
	if game_host.state_revision == revision_before and peer_id != multiplayer.get_unique_id():
		game_host.send_state_to_peer(peer_id)

## The connection an RPC arrived on. A call_local RPC run on this machine
## reports no remote sender, so that one is ours.
func get_rpc_sender_peer_id() -> int:
	var sender_id: int = multiplayer.get_remote_sender_id()
	return sender_id if sender_id != 0 else multiplayer.get_unique_id()

#region Version handshake
# Godot numbers a node's RPCs by sorting their names, and checks nothing across
# peers: two builds with different RPCs read the same message as different
# calls. The handshake below is the one exchange every version has to
# understand, so announce_client_version and announce_host_version must stay
# the first two RPC names alphabetically, with these signatures, for good.

## A client's first message after connecting. The host and a client only play
## when they run the same game version: a different one can disagree about any
## stamp or rule, which would split the two boards silently.
@rpc("any_peer", "call_remote", "reliable")
func announce_client_version(client_version: String) -> void:
	if !is_server:
		return
	var peer_id: int = get_rpc_sender_peer_id()
	peer_client_versions[peer_id] = client_version
	announce_host_version.rpc_id(peer_id, GameConfig.get_game_version())
	if client_version != GameConfig.get_game_version():
		reject_peer_version(peer_id, client_version)

## The host's answer. The client goes on into the match only on a match, and
## otherwise goes back to the multiplayer menu saying why.
@rpc("authority", "call_remote", "reliable")
func announce_host_version(host_version: String) -> void:
	if host_version == GameConfig.get_game_version():
		enter_match_after_version_check()
		return
	return_to_multiplayer_menu(tr("Version mismatch: you have %s, the other side has %s.") % [GameConfig.get_game_version(), host_version])

## True once the peer announced a version equal to ours. Every RPC a client can
## call checks this first, so a peer that skipped the handshake - an older
## build, whose messages land on the wrong calls here - is turned away instead
## of being half-understood.
func ensure_peer_version_accepted(peer_id: int) -> bool:
	if peer_id == multiplayer.get_unique_id():
		return true
	if !peer_client_versions.has(peer_id):
		peer_client_versions[peer_id] = ""
		reject_peer_version(peer_id, "")
		return false
	return is_peer_version_accepted(peer_id)

func is_peer_version_accepted(peer_id: int) -> bool:
	return str(peer_client_versions.get(peer_id, "")) == GameConfig.get_game_version()

func reject_peer_version(peer_id: int, client_version: String) -> void:
	var shown_client_version: String = client_version if !client_version.is_empty() else "?"
	DebugLog.network("Rejected peer %d: game version %s, ours is %s." % [peer_id, shown_client_version, GameConfig.get_game_version()])
	if !is_dedicated_server:
		set_network_status(tr("A player with a different game version (%s) tried to join.") % shown_client_version)
	call_deferred("disconnect_dedicated_peer_after_delay", peer_id)
#endregion

@rpc("authority", "call_remote", "reliable")
func give_turn(turn):
	DebugLog.info("Assigned side: %s" % ("White" if turn else "Black"))
	hide_custom_lobby_panel()
	$MatchBoard.set_turn(turn)

@rpc("authority", "call_remote", "reliable")
func receive_game_state(state_data: Dictionary):
	DebugLog.info("Game state received from server")
	apply_game_state(state_data)

func apply_game_state(state_data: Dictionary):
	DebugLog.network("Applying game state as viewer_player_id=%d current_turn=%s" % [
		int(state_data.get("viewer_player_id", -1)),
		str(state_data.get("current_turn", "?")),
	])
	$MatchBoard.apply_server_state_data(state_data)

func get_player_names_by_id() -> Dictionary:
	if GameConfig.is_singleplayer:
		return {
			0: str(peer_player_names.get(0, tr("AI %s") % tr("White"))),
			1: str(peer_player_names.get(1, tr("AI %s") % tr("Black"))),
		}

	var player_names: Dictionary = {
		0: tr("Player"),
		1: tr("Player"),
	}
	for peer_id in peer_player_ids:
		var player_id: int = int(peer_player_ids[peer_id])
		player_names[player_id] = str(peer_player_names.get(peer_id, "Player"))
	return player_names

func get_player_portraits_by_id() -> Dictionary:
	if GameConfig.is_singleplayer:
		return {
			0: PortraitLibrary.config_from_data_or_default(peer_player_portraits.get(0, {}), 0).to_dict(),
			1: PortraitLibrary.config_from_data_or_default(peer_player_portraits.get(1, {}), 1).to_dict(),
		}

	var player_portraits: Dictionary = {
		0: PortraitLibrary.get_default_portrait_for_player_id(0).to_dict(),
		1: PortraitLibrary.get_default_portrait_for_player_id(1).to_dict(),
	}
	for peer_id in peer_player_ids:
		var player_id: int = int(peer_player_ids[peer_id])
		player_portraits[player_id] = PortraitLibrary.config_from_data_or_default(peer_player_portraits.get(peer_id, {}), player_id).to_dict()
	return player_portraits

func get_starting_deck_for_player_id(player_id: int) -> Array[String]:
	if GameConfig.is_singleplayer:
		if GameConfig.should_ai_vs_ai_use_random_database_decks():
			return DeckManager.create_random_database_deck()
		if GameConfig.is_ai_vs_ai_batch:
			return GameConfig.get_selected_ai_deck_stamp_names()
		if GameConfig.get_player_controller(player_id) == GameConfig.CONTROLLER_HUMAN:
			if GameConfig.has_player_deck_override():
				return GameConfig.get_player_deck_override_stamp_names()
			return GameConfig.get_selected_deck_stamp_names()
		if GameConfig.has_ai_opponent_deck_override():
			return GameConfig.get_ai_opponent_deck_stamp_names()
		return GameConfig.get_selected_ai_deck_stamp_names()

	for peer_id in peer_player_ids:
		if int(peer_player_ids[peer_id]) == player_id:
			return duplicate_string_array(peer_player_decks.get(peer_id, []))
	var empty_deck: Array[String] = []
	return empty_deck

func duplicate_string_array(source) -> Array[String]:
	var output: Array[String] = []
	if source is Array:
		for value in source:
			output.append(str(value))
	return output
