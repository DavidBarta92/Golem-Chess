extends Node2D

const CONNECTION_DIAGNOSTIC_DELAY: float = 8.0
const MAX_DEDICATED_SERVER_CLIENTS: int = 64

signal custom_lobby_list_updated(lobbies: Array)
signal custom_lobby_failed(message: String)

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

func _ready():
	if !GameConfig.should_skip_ai_vs_ai_delays():
		await get_tree().create_timer(0.1).timeout

	apply_command_line_network_overrides()
	if !GameConfig.is_singleplayer:
		ensure_network_status_label()
		set_network_status("Starting network...")
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
		start_singleplayer_game()
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
	title_label.text = "Server Room"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title_label)

	custom_lobby_status_label = Label.new()
	custom_lobby_status_label.text = "Connecting..."
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
			if GameConfig.should_skip_ai_vs_ai_delays():
				ai_player.action_delay = 0.0
			ai_players[player_id] = ai_player

func setup_singleplayer_player_names() -> void:
	for player_id in [0, 1]:
		if GameConfig.get_player_controller(player_id) == GameConfig.CONTROLLER_HUMAN:
			peer_player_names[player_id] = GameConfig.get_local_player_name()
			peer_player_portraits[player_id] = GameConfig.get_local_portrait_data()
		elif GameConfig.get_player_controller(player_id) == GameConfig.CONTROLLER_CODEX:
			peer_player_names[player_id] = "Codex"
			peer_player_portraits[player_id] = GameConfig.get_ai_portrait_data(player_id)
		else:
			peer_player_names[player_id] = "AI %s" % ("White" if player_id == 0 else "Black")
			peer_player_portraits[player_id] = GameConfig.get_ai_portrait_data(player_id)

func get_local_human_player_id() -> int:
	for player_id in [0, 1]:
		if GameConfig.get_player_controller(player_id) == GameConfig.CONTROLLER_HUMAN:
			return player_id
	return 0

func get_side_for_player_id(player_id: int) -> bool:
	return player_id == 0

func on_host_state_changed():
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

	ai_turn_in_progress = false
	maybe_play_singleplayer_ai_turn()

func host_game(port = 9999):
	set_network_status("Hosting on UDP %d. Waiting for peer..." % port)
	DebugLog.network("Starting ENet host on UDP port %d. Local IPv4 addresses: %s" % [port, get_local_address_summary()])
	var error = multiplayer_peer.create_server(port, 2, 0, 0, 0)

	if error != OK:
		var error_message: String = "Failed to start ENet server on UDP port %d. Error code: %d" % [port, error]
		set_network_status("Host failed on UDP %d." % port)
		DebugLog.network_error(error_message)
		push_error(error_message)
		return false

	is_server = true
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	server_turn = true if randi_range(0, 1) else false
	multiplayer_game_started = false

	DebugLog.info("Server started on port %d" % port)
	DebugLog.network("ENet server started on UDP port %d. Waiting for remote peer." % port)
	call_deferred("_log_host_connection_status_after_delay", port)

	game_host = NetworkGameHost.new()
	game_host.configure(self)
	GameController.set_game_host(game_host)
	peer_player_names[1] = GameConfig.get_local_player_name()
	peer_player_decks[1] = GameConfig.get_selected_deck_stamp_names()
	peer_player_portraits[1] = GameConfig.get_local_portrait_data()

	_on_peer_connected(1)
	return true

func start_dedicated_custom_server(port: int = 9999) -> bool:
	set_network_status("Dedicated server listening on UDP %d." % port)
	hide_custom_lobby_panel()
	DebugLog.network("Starting dedicated custom server on UDP port %d. Local IPv4 addresses: %s" % [port, get_local_address_summary()])
	var error = multiplayer_peer.create_server(port, MAX_DEDICATED_SERVER_CLIENTS, 0, 0, 0)

	if error != OK:
		var error_message: String = "Failed to start dedicated custom server on UDP port %d. Error code: %d" % [port, error]
		set_network_status("Dedicated server failed on UDP %d." % port)
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
	set_network_status("Connecting to %s:%d..." % [ip, port])
	DebugLog.network("Starting ENet client. Target=%s:%d" % [ip, port])
	var error = multiplayer_peer.create_client(ip, port)
	if error != OK:
		var error_message: String = "Failed to create ENet client for %s:%d. Error code: %d" % [ip, port, error]
		set_network_status("Connection setup failed.")
		DebugLog.network_error(error_message)
		push_error(error_message)
		return false

	multiplayer.multiplayer_peer = multiplayer_peer
	DebugLog.info("Connecting to %s:%d" % [ip, port])
	DebugLog.network("ENet client created. Waiting for connection result from %s:%d" % [ip, port])

	multiplayer.connected_to_server.connect(_on_connection_succeeded)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	GameController.set_game_host(self)
	call_deferred("_log_client_connection_status_after_delay", ip, port)
	return true

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
		set_network_status("Hosting on UDP %d. Still waiting for peer." % port)
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
		set_network_status("Connection failed or timed out.")
		set_custom_lobby_status("Connection failed or timed out: %s:%d" % [ip, port])
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
		set_network_status("Dedicated server clients: %d" % server_connected_peer_ids.size())
		DebugLog.network("Dedicated server accepted connection shell for peer %s." % peer_id)
		return

	if connected_peer_ids.size() < 2 && !connected_peer_ids.has(peer_id):
		connected_peer_ids.append(peer_id)
		DebugLog.info("  Players: %d/2" % connected_peer_ids.size())
		DebugLog.network("Connected players: %d/2" % connected_peer_ids.size())
		set_network_status("Connected players: %d/2" % connected_peer_ids.size())
		_try_start_multiplayer_game()

func _on_peer_disconnected(peer_id):
	if !is_server:
		return

	DebugLog.info("Player disconnected: %s" % peer_id)
	DebugLog.network("Peer disconnected: %s" % peer_id)
	if is_dedicated_server:
		var should_close_remaining_match_peer: bool = should_close_remaining_peer_after_disconnect(peer_id)
		server_connected_peer_ids.erase(peer_id)
		remove_lobbies_for_peer(peer_id)
		connected_peer_ids.erase(peer_id)
		peer_player_ids.erase(peer_id)
		peer_player_names.erase(peer_id)
		peer_player_decks.erase(peer_id)
		peer_player_portraits.erase(peer_id)
		if should_close_remaining_match_peer and !connected_peer_ids.is_empty():
			close_remaining_match_peers_after_disconnect(peer_id)
		elif connected_peer_ids.is_empty():
			reset_dedicated_server_room()
		else:
			set_network_status("Dedicated server clients: %d" % server_connected_peer_ids.size())
		broadcast_open_lobby_list()
		return

	connected_peer_ids.erase(peer_id)
	peer_player_names.erase(peer_id)
	peer_player_decks.erase(peer_id)
	peer_player_portraits.erase(peer_id)
	if should_close_host_after_direct_peer_disconnect(peer_id):
		receive_match_peer_left("Opponent left. Returning to menu in 5 seconds.")
		return
	DebugLog.info("  Players: %d/2" % connected_peer_ids.size())
	DebugLog.network("Connected players: %d/2" % connected_peer_ids.size())
	set_network_status("Connected players: %d/2" % connected_peer_ids.size())

func _on_connection_succeeded():
	DebugLog.info("Connected to server")
	DebugLog.network("Connected to server. Local peer id: %s" % multiplayer.get_unique_id())
	if is_using_single_server_room_mode():
		set_network_status("Connected. Joining server room...")
		set_custom_lobby_status("Joining server room...")
		set_custom_lobby_controls_enabled(false)
		enter_custom_server_room.rpc_id(1, GameConfig.get_local_player_name(), GameConfig.get_selected_deck_stamp_names(), GameConfig.get_local_portrait_data())
	else:
		set_network_status("Connected. Registering player...")
		register_player_name.rpc_id(1, multiplayer.get_unique_id(), GameConfig.get_local_player_name(), GameConfig.get_selected_deck_stamp_names(), GameConfig.get_local_portrait_data())

func _on_connection_failed():
	var error_message: String = "Connection failed for %s:%d. Check host UDP port forwarding and firewall." % [GameConfig.server_ip, GameConfig.server_port]
	set_network_status("Connection failed.")
	set_custom_lobby_status(error_message)
	set_custom_lobby_controls_enabled(false)
	DebugLog.network_error(error_message)
	push_error(error_message)

func _on_server_disconnected():
	DebugLog.info("Server disconnected")
	set_network_status("Server disconnected.")
	set_custom_lobby_status("Server disconnected.")
	set_custom_lobby_controls_enabled(false)
	DebugLog.network_error("Server disconnected.")
	if has_received_match_state():
		receive_match_peer_left("Opponent left. Returning to menu in 5 seconds.")

func send_move(start_pos, end_pos):
	DebugLog.info("send_move(): %s -> %s my_id=%s" % [start_pos, end_pos, multiplayer.get_unique_id()])
	send_move_info.rpc_id(1, multiplayer.get_unique_id(), start_pos, end_pos)

func close_game_connection():
	if game_host != null:
		game_host.detach_multiplayer_node()
	game_host = null
	GameController.set_game_host(null)
	multiplayer_peer.close()
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
	set_custom_lobby_status("Joining server room...")
	enter_custom_server_room.rpc_id(1, GameConfig.get_local_player_name(), GameConfig.get_selected_deck_stamp_names(), GameConfig.get_local_portrait_data())

func join_lobby_on_server(lobby_id: String) -> void:
	if !can_send_custom_lobby_request():
		report_custom_lobby_connection_problem()
		return
	set_custom_lobby_status("Joining room...")
	join_custom_lobby.rpc_id(1, lobby_id, GameConfig.get_local_player_name(), GameConfig.get_selected_deck_stamp_names(), GameConfig.get_local_portrait_data())

func can_send_custom_lobby_request() -> bool:
	return !is_server \
		&& multiplayer.multiplayer_peer != null \
		&& multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED \
		&& multiplayer.get_unique_id() != 1

func report_custom_lobby_connection_problem() -> void:
	var status_text: String = get_peer_connection_status_text()
	var message: String = "Not connected to the custom server as a client. Status: %s. Target: %s:%d." % [
		status_text,
		GameConfig.server_ip,
		GameConfig.server_port,
	]
	if is_server or multiplayer.get_unique_id() == 1:
		message = "This game instance is the server. Start a separate client window for Server Room."
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
		set_custom_lobby_status("That room is no longer available.")
		return
	var lobby: MultiplayerLobby = custom_lobby_entries[index]
	if !lobby.is_joinable():
		set_custom_lobby_status("That room is no longer joinable.")
		return
	join_lobby_on_server(lobby.lobby_id)

@rpc("any_peer", "call_remote", "reliable")
func request_custom_lobby_list() -> void:
	if !is_server or !is_dedicated_server:
		return
	send_open_lobby_list_to_peer(multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable")
func enter_custom_server_room(player_name: String, deck_stamp_names: Array = [], portrait_data: Dictionary = {}) -> void:
	if !is_server or !is_dedicated_server:
		return
	var peer_id: int = multiplayer.get_remote_sender_id()
	if multiplayer_game_started or connected_peer_ids.size() >= 2:
		send_custom_lobby_error(peer_id, "Server room is full. Please try again in a few minutes.")
		call_deferred("disconnect_dedicated_peer_after_delay", peer_id)
		return

	register_dedicated_peer_data(peer_id, player_name, deck_stamp_names, portrait_data)
	if !connected_peer_ids.has(peer_id):
		connected_peer_ids.append(peer_id)

	if connected_peer_ids.size() == 1:
		receive_custom_room_waiting.rpc_id(peer_id, "Waiting for another player.")
		set_network_status("Dedicated server room: 1/2. Waiting for another player.")
		DebugLog.network("Peer %d is waiting in the single server room." % peer_id)
		return

	await start_dedicated_match(int(connected_peer_ids[0]), int(connected_peer_ids[1]))

@rpc("any_peer", "call_remote", "reliable")
func create_custom_lobby(player_name: String, deck_stamp_names: Array = [], portrait_data: Dictionary = {}) -> void:
	if !is_server or !is_dedicated_server:
		return
	var peer_id: int = multiplayer.get_remote_sender_id()
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

func close_remaining_match_peers_after_disconnect(disconnected_peer_id: int) -> void:
	set_network_status("A player left. Closing the match in 5 seconds.")
	DebugLog.network("Peer %d left an active dedicated match. Closing remaining peer(s) in 5 seconds." % disconnected_peer_id)
	for remaining_peer_id in connected_peer_ids:
		receive_match_peer_left.rpc_id(int(remaining_peer_id), "Opponent left. Returning to menu in 5 seconds.")
	call_deferred("disconnect_remaining_match_peers_after_delay", connected_peer_ids.duplicate())

func disconnect_remaining_match_peers_after_delay(peer_ids: Array) -> void:
	await get_tree().create_timer(5.2).timeout
	for peer_id in peer_ids:
		if server_connected_peer_ids.has(peer_id):
			disconnect_dedicated_peer(int(peer_id))

func reset_dedicated_server_room() -> void:
	multiplayer_game_started = false
	server_turn = true
	game_host = null
	GameController.set_game_host(null)
	set_network_status("Dedicated server room is open.")
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
	game_host.game_state.current_turn_player = 0 if server_turn else 1
	game_host.finish_if_player_has_no_valid_turn(game_host.game_state.current_turn_player)
	game_host.broadcast_full_state()
	broadcast_open_lobby_list()

	await get_tree().create_timer(0.2).timeout
	give_turn.rpc_id(host_peer_id, server_turn)
	give_turn.rpc_id(joining_peer_id, !server_turn)
	set_network_status("Dedicated match running: %d vs %d" % [host_peer_id, joining_peer_id])
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
	custom_lobby_failed.emit(message)
	set_network_status(message)
	set_custom_lobby_status(message)
	if is_using_single_server_room_mode():
		GameConfig.set_multiplayer_menu_status_message(message)
		close_game_connection()
		SceneTransition.change_scene("res://Scenes/MultiplayerMenu.tscn")

@rpc("authority", "call_remote", "reliable")
func receive_custom_room_waiting(message: String) -> void:
	set_network_status(message)
	set_custom_lobby_status(message)

@rpc("authority", "call_remote", "reliable")
func receive_match_peer_left(message: String) -> void:
	if match_peer_left_return_scheduled:
		return
	match_peer_left_return_scheduled = true
	set_network_status(message)
	if is_using_single_server_room_mode():
		set_custom_lobby_status(message)
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
		set_custom_lobby_status("Waiting for another player.")
	else:
		set_custom_lobby_status("Server room is available.")

@rpc("any_peer", "call_local", "reliable")
func register_player_name(peer_id: int, player_name: String, deck_stamp_names: Array = [], portrait_data: Dictionary = {}):
	if !is_server:
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
		set_network_status("Connected players: %d/2. Waiting for peer..." % connected_peer_ids.size())
		DebugLog.network("Waiting for remote peer. Connected players: %d/2" % connected_peer_ids.size())
		return

	for peer_id in connected_peer_ids:
		if !peer_player_names.has(peer_id) or !peer_player_decks.has(peer_id):
			set_network_status("Waiting for peer registration...")
			DebugLog.network("Waiting for peer registration data. Peer=%s has_name=%s has_deck=%s" % [
				peer_id,
				peer_player_names.has(peer_id),
				peer_player_decks.has(peer_id),
			])
			return

	multiplayer_game_started = true
	var first_player_id: int = 0 if server_turn else 1
	peer_player_ids[connected_peer_ids[0]] = first_player_id
	peer_player_ids[connected_peer_ids[1]] = 1 - first_player_id
	DebugLog.info("Game starting")
	DebugLog.network("Game starting. peer_ids=%s server_turn=%s first_player_id=%d" % [connected_peer_ids, server_turn, first_player_id])
	set_network_status("Game starting...")

	var board_data = $MatchBoard.board
	game_host.initialize_game(board_data)
	game_host.game_state.current_turn_player = 0 if server_turn else 1
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

@rpc("any_peer", "call_local", "reliable")
func send_player_action(peer_id: int, action: Dictionary):
	if !is_server || game_host == null:
		return

	var player_id: int = int(peer_player_ids.get(peer_id, action.get("player_id", 0)))
	action["player_id"] = player_id
	game_host.on_player_action(action)

@rpc("any_peer", "call_local", "reliable")
func send_move_info(id, start_pos, end_pos):
	DebugLog.info("send_move_info() - id=%s server_turn=%s connected=%s is_server=%s" % [id, server_turn, connected_peer_ids, is_server])

	if !is_server || connected_peer_ids.size() < 2:
		DebugLog.info("SKIP: is_server=%s conn_size=%s" % [is_server, connected_peer_ids.size()])
		return

	if id == connected_peer_ids[0] && server_turn:
		DebugLog.info("White moved: %s -> %s" % [start_pos, end_pos])
		return_enemy_move.rpc_id(connected_peer_ids[1], start_pos, end_pos)
		server_turn = !server_turn
	elif id == connected_peer_ids[1] && !server_turn:
		DebugLog.info("Black moved: %s -> %s" % [start_pos, end_pos])
		return_enemy_move.rpc_id(connected_peer_ids[0], start_pos, end_pos)
		server_turn = !server_turn

@rpc("authority", "call_local", "reliable")
func return_enemy_move(start_pos, end_pos):
	DebugLog.info("return_enemy_move(): %s -> %s my_id=%s" % [start_pos, end_pos, multiplayer.get_unique_id()])
	$MatchBoard.set_move(start_pos, end_pos)

@rpc("authority", "call_remote", "reliable")
func give_turn(turn):
	DebugLog.info("Assigned side: %s" % ("White" if turn else "Black"))
	hide_custom_lobby_panel()
	$MatchBoard.set_turn(turn)

@rpc("authority", "call_remote", "reliable")
func receive_game_state(state_data: Dictionary):
	DebugLog.info("Game state received from server")
	DebugLog.info("  Pieces: %s" % state_data.pieces.size())
	DebugLog.info("  White hand: %s" % [state_data.player_hands[0]])
	DebugLog.info("  Black hand: %s" % [state_data.player_hands[1]])

	apply_game_state(state_data)

func apply_game_state(state_data: Dictionary):
	DebugLog.info("apply_game_state() start")
	DebugLog.network("Applying game state as viewer_player_id=%d current_turn=%s" % [
		int(state_data.get("viewer_player_id", -1)),
		str(state_data.get("current_turn", "?")),
	])

	var pieces_data = {}

	for piece_data in state_data.pieces:
		var pos = Vector2(piece_data.position[0], piece_data.position[1])
		pieces_data[pos] = {
			"position": pos,
			"color": piece_data.color,
			"stamp_name": piece_data.stamp_name,
			"turns_remaining": piece_data.turns_remaining,
			"exhausted_this_turn": bool(piece_data.get("exhausted_this_turn", false)),
			"respawn_cooldown_turns": int(piece_data.get("respawn_cooldown_turns", 0)),
			"hidden_from_viewer": bool(piece_data.get("hidden_from_viewer", false))
		}
		DebugLog.info("  Piece loaded: pos=%s, stamp=%s, turns=%d" % [pos, piece_data.stamp_name, piece_data.turns_remaining])

	$MatchBoard.update_from_server_state(
		pieces_data,
		state_data.player_hands,
		state_data.current_turn,
		state_data.get("game_over", false),
		state_data.get("winner_player", -1),
		state_data.get("player_decks_size", {}),
		state_data.get("player_codex_state", {}),
		state_data.get("hidden_stamps", []),
		state_data.get("player_base_fields", {}),
		state_data.get("board_effects", []),
		state_data.get("player_names", {}),
		state_data.get("recent_stamp_transfers", []),
		state_data.get("recent_stamp_expirations", []),
		state_data.get("recent_bomb_effects", []),
		state_data.get("recent_pending_respawn_queues", []),
		state_data.get("recent_pending_respawn_arrivals", []),
		state_data.get("last_move", {}),
		state_data.get("player_portraits", {}),
		int(state_data.get("viewer_player_id", -1)),
		state_data.get("turn_action_state", {}),
		state_data.get("player_clock_seconds", {})
	)

	DebugLog.info("apply_game_state() end")

func get_player_names_by_id() -> Dictionary:
	if GameConfig.is_singleplayer:
		return {
			0: str(peer_player_names.get(0, "AI White")),
			1: str(peer_player_names.get(1, "AI Black")),
		}

	var player_names: Dictionary = {
		0: "Player",
		1: "Player",
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
			return GameConfig.get_selected_deck_stamp_names()
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
