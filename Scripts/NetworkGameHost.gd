# NetworkGameHost.gd - Multiplayer játék host
class_name NetworkGameHost

var game_state: GameStateData
var multiplayer_node  # Referencia a Multiplayer.gd-re

func _init(mp_node):
	multiplayer_node = mp_node
	game_state = GameStateData.new()

# Játékállapot inicializálása
func initialize_game(board_data: Array):
	# Pieces létrehozása a board-ból
	for i in range(board_data.size()):
		for j in range(board_data[i].size()):
			var value = board_data[i][j]
			if value != 0:
				var pos = Vector2(i, j)
				var color = 1 if value > 0 else -1
				var piece = GameStateData.PieceData.new(pos, color)
				game_state.set_piece(pos, piece)
	
	# Paklik és kezek
	var white_deck: Array[String] = []
	white_deck.assign(DeckManager.create_starting_deck())
	var black_deck: Array[String] = []
	black_deck.assign(DeckManager.create_starting_deck())
	
	game_state.player_decks[0] = white_deck
	game_state.player_decks[1] = black_deck
	
	var white_hand: Array[String] = []
	var black_hand: Array[String] = []
	
	DeckManager.draw_starting_hand(white_deck, white_hand)
	DeckManager.draw_starting_hand(black_deck, black_hand)
	
	game_state.player_hands[0] = white_hand
	game_state.player_hands[1] = black_hand
	
	print("🎮 NetworkGameHost: Game state inicializálva!")
	
		# TESZT: Automatikusan kijátsszuk a király kártyákat
	var white_first_piece_pos = Vector2(0, 1)
	var black_first_piece_pos = Vector2(4, 2)
	
	var white_piece = game_state.get_piece(white_first_piece_pos)
	var black_piece = game_state.get_piece(black_first_piece_pos)
	
	if white_piece:
		white_piece.card_name = "King"
		white_piece.turns_remaining = -1
		game_state.white_king_position = white_first_piece_pos
		print("👑 Fehér király hozzáadva: ", white_first_piece_pos)
	
	if black_piece:
		black_piece.card_name = "King"
		black_piece.turns_remaining = -1
		game_state.black_king_position = black_first_piece_pos
		print("👑 Fekete király hozzáadva: ", black_first_piece_pos)
		
	if white_piece:
		white_piece.card_name = "King"
		white_piece.turns_remaining = -1
		game_state.white_king_position = white_first_piece_pos
		print("👑 Fehér király hozzáadva: ", white_first_piece_pos)
		print("   Ellenőrzés: ", game_state.get_piece(white_first_piece_pos).card_name)
	
	# Broadcast kezdő state
	broadcast_full_state()

# Játékos akció kezelése
func on_player_action(action: Dictionary):
	print("🎯 Action received: ", action)
	
	match action.type:
		"attach_card":
			handle_attach_card(action)
		"move_piece":
			handle_move_piece(action)
		_:
			push_warning("⚠️ Ismeretlen action type: ", action.type)

func handle_attach_card(action: Dictionary):
	# action = {type: "attach_card", player_id: int, card_name: String, piece_pos: Vector2}
	var player_id = action.player_id
	var card_name = action.card_name
	var piece_pos = action.piece_pos
	
	print("🎴 Kártya csatolás: %s játékos, %s kártya, %s pozíció" % [player_id, card_name, piece_pos])
	
	# 1. Validálás: Van-e a kártya a játékos kezében?
	if !game_state.player_hands[player_id].has(card_name):
		push_warning("⚠️ Nincs ilyen kártya a kézben!")
		return
	
	# 2. Validálás: Létezik-e a bábu?
	var piece = game_state.get_piece(piece_pos)
	if piece == null:
		push_warning("⚠️ Nincs bábu ezen a pozíción!")
		return
	
	# 3. Validálás: A játékos bábuja-e?
	var expected_color = 1 if player_id == 0 else -1
	if piece.color != expected_color:
		push_warning("⚠️ Nem a játékos bábuja!")
		return
	
	# 4. Validálás: Van-e már kártya rajta?
	if piece.has_card():
		push_warning("⚠️ Már van kártya ezen a bábun!")
		return
	
	# 5. Alkalmazzuk a változást
	var card = CardLibrary.get_card(card_name)
	if card:
		piece.card_name = card_name
		piece.turns_remaining = card.duration
		
		# Király pozíció követése
		if card_name == "King":
			if player_id == 0:
				game_state.white_king_position = piece_pos
			else:
				game_state.black_king_position = piece_pos
		
		# Kártya kijátszása a kézből
		DeckManager.play_card(game_state.player_hands[player_id], card_name, game_state.player_decks[player_id])
		
		print("✅ Kártya sikeresen csatolva!")
		
		# Broadcast
		broadcast_full_state()

func handle_move_piece(action: Dictionary):
	# action = {type: "move_piece", player_id: int, from: Vector2, to: Vector2}
	var player_id = action.player_id
	var from_pos = action.from
	var to_pos = action.to
	
	print("♟️ Lépés: %s játékos, %s → %s" % [player_id, from_pos, to_pos])
	
	# 1. Validálás: Létezik-e a bábu?
	var piece = game_state.get_piece(from_pos)
	if piece == null:
		push_warning("⚠️ Nincs bábu a kiindulási pozíción!")
		return
	
	# 2. Validálás: A játékos bábuja-e?
	var expected_color = 1 if player_id == 0 else -1
	if piece.color != expected_color:
		push_warning("⚠️ Nem a játékos bábuja!")
		return
	
	# 3. Validálás: Van-e kártya és tud-e lépni?
	if !piece.can_move():
		push_warning("⚠️ Nincs használható kártya ezen a bábun!")
		return
	
	# 4. Validálás: A játékos köre van-e?
	if game_state.current_turn_player != player_id:
		push_warning("⚠️ Nem a játékos köre!")
		return
	
	# 5. Validálás: Érvényes lépés-e? (kártya mozgási minta alapján)
	if !is_valid_move(piece, from_pos, to_pos):
		push_warning("⚠️ Érvénytelen lépés!")
		return
	
	# 6. Alkalmazzuk a lépést
	var captured_piece = game_state.get_piece(to_pos)
	
	# Leütés kezelése
	if captured_piece != null:
		print("💥 Bábu leütve: ", to_pos)
		
		# Király leütés?
		if captured_piece.card_name == "King":
			print("👑 KIRÁLY LEÜTVE! Játékos %d nyert!" % player_id)
			# TODO: Játék vége
		
		# Leütött bábu kártyájának visszaadása
		if captured_piece.has_card() && captured_piece.turns_remaining > 0:
			var enemy_player = 1 - player_id
			DeckManager.return_card_to_deck(game_state.player_decks[enemy_player], captured_piece.card_name)
	
	# Bábu mozgatása
	game_state.remove_piece(from_pos)
	piece.position = to_pos
	game_state.set_piece(to_pos, piece)
	
	# Király pozíció frissítése
	if piece.card_name == "King":
		if player_id == 0:
			game_state.white_king_position = to_pos
		else:
			game_state.black_king_position = to_pos
	
	# Bázis elfoglalás?
	var base_y = 2  # Középső oszlop
	if (player_id == 0 && to_pos.x == 4 && to_pos.y == base_y) || \
	   (player_id == 1 && to_pos.x == 0 && to_pos.y == base_y):
		print("🏁 BÁZIS ELFOGLALVA! Játékos %d nyert!" % player_id)
		# TODO: Játék vége
	
	# Kártya használat (kör csökkentés)
	piece.use_turn()
	if piece.turns_remaining == 0 && piece.card_name != "King":
		# Kártya lejárt, visszakerül a pakliba
		DeckManager.return_card_to_deck(game_state.player_decks[player_id], piece.card_name)
		piece.card_name = ""
	
	# Kör váltás
	game_state.switch_turn()
	
	print("✅ Lépés végrehajtva! Következő játékos: ", game_state.current_turn_player)
	
	# Broadcast
	broadcast_full_state()

# Segédfüggvény: Lépés validálása
func is_valid_move(piece: GameStateData.PieceData, from_pos: Vector2, to_pos: Vector2) -> bool:
	var card = CardLibrary.get_card(piece.card_name)
	if !card:
		return false
	
	var directions = card.get_directions()
	var move_vector = to_pos - from_pos
	
	return directions.has(move_vector)
	
# Teljes state broadcast minden kliensnek
func broadcast_full_state():
	print("📡 Broadcasting full state...")
	
	# Szerializáljuk a game state-et Dictionary-vé
	var state_data = serialize_state()
	
	# A SZERVER saját magának is frissíti (ha van board node)
	if multiplayer_node.has_node("board"):
		var pieces_data = {}
		for piece_data in state_data.pieces:
			var pos = Vector2(piece_data.position[0], piece_data.position[1])
			pieces_data[pos] = {
				"position": pos,
				"color": piece_data.color,
				"card_name": piece_data.card_name,
				"turns_remaining": piece_data.turns_remaining
			}
		multiplayer_node.get_node("board").update_from_server_state(pieces_data, state_data.player_hands, state_data.current_turn)
	
	# Küldjük el minden KLIENS-nek
	for peer_id in multiplayer_node.connected_peer_ids:
		if peer_id != 1:
			multiplayer_node.receive_game_state.rpc_id(peer_id, state_data)
	
	print("✅ State broadcast kész")

func serialize_state() -> Dictionary:
	var data = {
		"pieces": [],  # <-- Array legyen, nem Dictionary!
		"player_hands": game_state.player_hands,
		"player_decks_size": {
			0: game_state.player_decks[0].size(),
			1: game_state.player_decks[1].size()
		},
		"current_turn": game_state.current_turn_player
	}
	
	# Pieces szerializálása
	for pos in game_state.pieces:
		var piece: GameStateData.PieceData = game_state.pieces[pos]
		data.pieces.append({
			"position": [pos.x, pos.y],  # <-- Array-ként küldjük
			"color": piece.color,
			"card_name": piece.card_name,
			"turns_remaining": piece.turns_remaining
		})
	
	return data
