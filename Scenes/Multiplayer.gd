extends Node2D

var multiplayer_peer = ENetMultiplayerPeer.new()
var is_server = false

var connected_peer_ids = []
var peer_player_ids: Dictionary = {}
var server_turn = true

var game_host: NetworkGameHost = null
var singleplayer_ai: RandomAIPlayer = null
var singleplayer_ai_turn_in_progress: bool = false

func _ready():
	await get_tree().create_timer(0.1).timeout

	if GameConfig.is_singleplayer:
		print("Starting in singleplayer mode")
		start_singleplayer_game()
	elif GameConfig.is_hosting:
		print("Starting in host mode")
		host_game(GameConfig.server_port)
	else:
		print("Starting in join mode - IP: %s" % GameConfig.server_ip)
		join_game(GameConfig.server_ip, GameConfig.server_port)

func start_singleplayer_game():
	is_server = true
	server_turn = true
	connected_peer_ids = [1]
	peer_player_ids[1] = 0
	singleplayer_ai = RandomAIPlayer.new(1)

	game_host = NetworkGameHost.new(self)
	GameController.set_game_host(game_host)

	var board_data = $board.board
	game_host.initialize_game(board_data)
	game_host.game_state.current_turn_player = 0
	game_host.finish_if_player_has_no_valid_turn(game_host.game_state.current_turn_player)
	game_host.broadcast_full_state()
	$board.set_turn(true)

func on_host_state_changed():
	maybe_play_singleplayer_ai_turn()

func maybe_play_singleplayer_ai_turn():
	if !GameConfig.is_singleplayer:
		return
	if singleplayer_ai == null or game_host == null or game_host.game_state == null:
		return
	if singleplayer_ai_turn_in_progress or game_host.game_state.game_over:
		return
	if game_host.game_state.current_turn_player != singleplayer_ai.player_id:
		return

	singleplayer_ai_turn_in_progress = true
	call_deferred("_play_singleplayer_ai_turn")

func _play_singleplayer_ai_turn():
	await get_tree().create_timer(0.45).timeout
	if singleplayer_ai != null and game_host != null and !game_host.game_state.game_over and game_host.game_state.current_turn_player == singleplayer_ai.player_id:
		await singleplayer_ai.play_turn(game_host, get_tree())

	singleplayer_ai_turn_in_progress = false
	maybe_play_singleplayer_ai_turn()

func host_game(port = 9999):
	var error = multiplayer_peer.create_server(port, 2, 0, 0, 0)

	if error != OK:
		push_error("Failed to start server: %d" % error)
		return false

	is_server = true
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	server_turn = true if randi_range(0, 1) else false

	print("Server started on port %d" % port)

	game_host = NetworkGameHost.new(self)
	GameController.set_game_host(game_host)

	_on_peer_connected(1)
	return true

func join_game(ip, port = 9999):
	var error = multiplayer_peer.create_client(ip, port)
	if error != OK:
		push_error("Failed to connect: %d" % error)
		return false

	multiplayer.multiplayer_peer = multiplayer_peer
	print("Connecting to %s:%d" % [ip, port])

	multiplayer.connected_to_server.connect(_on_connection_succeeded)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	GameController.set_game_host(self)
	return true

func _on_peer_connected(peer_id):
	if !is_server:
		return

	print("Player connected: ", peer_id)

	if connected_peer_ids.size() < 2 && !connected_peer_ids.has(peer_id):
		connected_peer_ids.append(peer_id)
		print("  Players: %d/2" % connected_peer_ids.size())

		if connected_peer_ids.size() == 2:
			var first_player_id: int = 0 if server_turn else 1
			peer_player_ids[connected_peer_ids[0]] = first_player_id
			peer_player_ids[connected_peer_ids[1]] = 1 - first_player_id
			print("Game starting")

			var board_data = $board.board
			game_host.initialize_game(board_data)
			game_host.game_state.current_turn_player = 0 if server_turn else 1
			game_host.finish_if_player_has_no_valid_turn(game_host.game_state.current_turn_player)
			game_host.broadcast_full_state()

			await get_tree().create_timer(0.2).timeout

			if connected_peer_ids[0] == 1:
				$board.set_turn(server_turn)
			else:
				give_turn.rpc_id(connected_peer_ids[0], server_turn)

			give_turn.rpc_id(connected_peer_ids[1], !server_turn)

func _on_peer_disconnected(peer_id):
	if !is_server:
		return

	print("Player disconnected: ", peer_id)
	connected_peer_ids.erase(peer_id)
	print("  Players: %d/2" % connected_peer_ids.size())

func _on_connection_succeeded():
	print("Connected to server")

func _on_connection_failed():
	push_error("Failed to connect to server")

func _on_server_disconnected():
	print("Server disconnected")

func send_move(start_pos, end_pos, promotion = null):
	print("send_move(): ", start_pos, " -> ", end_pos, " my_id=", multiplayer.get_unique_id())
	send_move_info.rpc_id(1, multiplayer.get_unique_id(), start_pos, end_pos, promotion)

func close_game_connection():
	multiplayer_peer.close()
	multiplayer.multiplayer_peer = null

func on_player_action(action: Dictionary):
	send_player_action.rpc_id(1, multiplayer.get_unique_id(), action)

@rpc("any_peer", "call_local", "reliable")
func send_player_action(peer_id: int, action: Dictionary):
	if !is_server || game_host == null:
		return

	var player_id: int = int(peer_player_ids.get(peer_id, action.get("player_id", 0)))
	action["player_id"] = player_id
	game_host.on_player_action(action)

@rpc("any_peer", "call_local", "reliable")
func send_move_info(id, start_pos, end_pos, promotion):
	print("send_move_info() - id=", id, " server_turn=", server_turn, " connected[0]=", connected_peer_ids[0], " connected[1]=", connected_peer_ids[1], " is_server=", is_server)

	if !is_server || connected_peer_ids.size() < 2:
		print("SKIP: is_server=", is_server, " conn_size=", connected_peer_ids.size())
		return

	if id == connected_peer_ids[0] && server_turn:
		print("White moved: %s -> %s" % [start_pos, end_pos])
		return_enemy_move.rpc_id(connected_peer_ids[1], start_pos, end_pos, promotion)
		server_turn = !server_turn
	elif id == connected_peer_ids[1] && !server_turn:
		print("Black moved: %s -> %s" % [start_pos, end_pos])
		return_enemy_move.rpc_id(connected_peer_ids[0], start_pos, end_pos, promotion)
		server_turn = !server_turn

@rpc("authority", "call_local", "reliable")
func return_enemy_move(start_pos, end_pos, promotion):
	print("return_enemy_move(): ", start_pos, " -> ", end_pos, " my_id=", multiplayer.get_unique_id())
	$board.set_move(start_pos, end_pos, promotion)

@rpc("authority", "call_remote", "reliable")
func give_turn(turn):
	print("Assigned side: %s" % ("White" if turn else "Black"))
	$board.set_turn(turn)

@rpc("authority", "call_remote", "reliable")
func receive_game_state(state_data: Dictionary):
	print("Game state received from server")
	print("  Pieces: ", state_data.pieces.size())
	print("  White hand: ", state_data.player_hands[0])
	print("  Black hand: ", state_data.player_hands[1])

	apply_game_state(state_data)

func apply_game_state(state_data: Dictionary):
	print("apply_game_state() start")

	var pieces_data = {}

	for piece_data in state_data.pieces:
		var pos = Vector2(piece_data.position[0], piece_data.position[1])
		pieces_data[pos] = {
			"position": pos,
			"color": piece_data.color,
			"card_name": piece_data.card_name,
			"turns_remaining": piece_data.turns_remaining
		}
		print("  Piece loaded: pos=%s, card=%s, turns=%d" % [pos, piece_data.card_name, piece_data.turns_remaining])

	$board.update_from_server_state(
		pieces_data,
		state_data.player_hands,
		state_data.current_turn,
		state_data.get("game_over", false),
		state_data.get("winner_player", -1),
		state_data.get("player_decks_size", {})
	)

	print("apply_game_state() end")
