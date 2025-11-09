extends Node2D

var multiplayer_peer = ENetMultiplayerPeer.new()
var is_server = false

var connected_peer_ids = []
var server_turn = true

func _ready():
	# Várunk egy kicsit, hogy a board betöltődjön
	await get_tree().create_timer(0.1).timeout
	
	if GameState.is_hosting:
		print("🎮 Host módban indulunk")
		host_game(GameState.server_port)
	else:
		print("🎮 Join módban indulunk - IP: %s" % GameState.server_ip)
		join_game(GameState.server_ip, GameState.server_port)

func host_game(port = 9999):
	var error = multiplayer_peer.create_server(port, 2, 0, 0, 0)
	
	if error != OK:
		push_error("Nem sikerült elindítani a szervert: %d" % error)
		return false
	
	is_server = true
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	server_turn = true if randi_range(0, 1) else false
	
	print("✓ Szerver elindult a %d porton" % port)
	
	_on_peer_connected(1)
	return true

func join_game(ip, port = 9999):
	var error = multiplayer_peer.create_client(ip, port)
	if error != OK:
		push_error("Nem sikerült csatlakozni: %d" % error)
		return false
	
	multiplayer.multiplayer_peer = multiplayer_peer
	print("Csatlakozás: %s:%d" % [ip, port])
	
	multiplayer.connected_to_server.connect(_on_connection_succeeded)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	return true

func _on_peer_connected(peer_id):
	if !is_server:
		return
		
	print("→ Játékos csatlakozott: ", peer_id)
	
	if connected_peer_ids.size() < 2 && !connected_peer_ids.has(peer_id):
		connected_peer_ids.append(peer_id)
		print("  Játékosok: %d/2" % connected_peer_ids.size())
		
		if connected_peer_ids.size() == 2:
			print("⚔ Játék kezdődik!")

			if connected_peer_ids[0] == 1:
				$board.set_turn(server_turn)
			else:
				give_turn.rpc_id(connected_peer_ids[0], server_turn)
			
			give_turn.rpc_id(connected_peer_ids[1], !server_turn)

func _on_peer_disconnected(peer_id):
	if !is_server:
		return
		
	print("← Játékos lecsatlakozott: ", peer_id)
	connected_peer_ids.erase(peer_id)
	print("  Játékosok: %d/2" % connected_peer_ids.size())

func _on_connection_succeeded():
	print("✓ Sikeresen csatlakoztál a szerverhez!")

func _on_connection_failed():
	push_error("✗ Nem sikerült csatlakozni a szerverhez!")

func _on_server_disconnected():
	print("✗ A szerver lecsatlakozott!")

func send_move(start_pos, end_pos, promotion = null):
	print("📤 send_move() hívva: ", start_pos, " → ", end_pos, " my_id=", multiplayer.get_unique_id())
	send_move_info.rpc_id(1, multiplayer.get_unique_id(), start_pos, end_pos, promotion)

@rpc("any_peer", "call_local", "reliable")
func send_move_info(id, start_pos, end_pos, promotion):
	print("🔧 send_move_info() - id=", id, " server_turn=", server_turn, " connected[0]=", connected_peer_ids[0], " connected[1]=", connected_peer_ids[1], " is_server=", is_server)
	
	if !is_server || connected_peer_ids.size() < 2:
		print("⚠️ SKIP: is_server=", is_server, " conn_size=", connected_peer_ids.size())
		return
	
	if id == connected_peer_ids[0] && server_turn:
		print("♟ Fehér lépett: %s → %s" % [start_pos, end_pos])
		return_enemy_move.rpc_id(connected_peer_ids[1], start_pos, end_pos, promotion)
		server_turn = !server_turn
	elif id == connected_peer_ids[1] && !server_turn:
		print("♟ Fekete lépett: %s → %s" % [start_pos, end_pos])
		return_enemy_move.rpc_id(connected_peer_ids[0], start_pos, end_pos, promotion)
		server_turn = !server_turn

@rpc("authority", "call_local", "reliable")
func return_enemy_move(start_pos, end_pos, promotion):
	print("📥 return_enemy_move() MEGÉRKEZETT: ", start_pos, " → ", end_pos, " my_id=", multiplayer.get_unique_id())
	$board.set_move(start_pos, end_pos, promotion)

@rpc("authority", "call_remote", "reliable")
func give_turn(turn):
	print("🎮 Kaptam színt: %s" % ("Fehér" if turn else "Fekete"))
	$board.set_turn(turn)
