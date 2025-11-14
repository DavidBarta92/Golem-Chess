extends Sprite2D

const BOARD_SIZE = 5
const CELL_WIDTH = 18

const TEXTURE_HOLDER = preload("res://Scenes/texture_holder.tscn")

const BLACK_BISHOP = preload("res://Assets/black_bishop.png")
const BLACK_KING = preload("res://Assets/black_king.png")
const BLACK_KNIGHT = preload("res://Assets/black_knight.png")
const BLACK_PAWN = preload("res://Assets/black_pawn.png")
const BLACK_QUEEN = preload("res://Assets/black_queen.png")
const BLACK_ROOK = preload("res://Assets/black_rook.png")
const WHITE_BISHOP = preload("res://Assets/white_bishop.png")
const WHITE_KING = preload("res://Assets/white_king.png")
const WHITE_KNIGHT = preload("res://Assets/white_knight.png")
const WHITE_PAWN = preload("res://Assets/white_pawn.png")
const WHITE_QUEEN = preload("res://Assets/white_queen.png")
const WHITE_ROOK = preload("res://Assets/white_rook.png")

const TURN_WHITE = preload("res://Assets/turn-white.png")
const TURN_BLACK = preload("res://Assets/turn-black.png")

const PIECE_MOVE = preload("res://Assets/Piece_move.png")

@onready var pieces_node = $Pieces
@onready var dots = $Dots
@onready var turn = $Turn
@onready var white_pieces = $"../CanvasLayer/white_pieces"
@onready var black_pieces = $"../CanvasLayer/black_pieces"

var board : Array
var piece_objects: Dictionary = {}  # Vector2 -> Piece objektum
var white : bool = true
var state : bool = false
var moves = []
var selected_piece : Vector2

var side #white - true, black - false

func set_turn(_turn):
	side = _turn
	print("🎯 set_turn() hívva: side=", side)
	
	# Csak a kamerát állítjuk, a bábuk már frissültek
	if side != null && !side:
		$"../Camera2D".global_rotation_degrees = 180
	else:
		$"../Camera2D".global_rotation_degrees = 0

func _ready():
	board.append([1, 1, 1, 1, 1])
	board.append([0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0])
	board.append([-1, -1, -1, -1, -1])
	
	create_pieces_from_board()
	
func create_pieces_from_board():
	piece_objects.clear()
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var value = board[i][j]
			if value != 0:
				var pos = Vector2(i, j)
				var color = 1 if value > 0 else -1
				var piece = Piece.new(pos, color)
				piece_objects[pos] = piece
				print("🔷 Piece létrehozva: pos=%s, color=%s" % [pos, "fehér" if color > 0 else "fekete"])
	
func _input(event):
	if side != null && side == white:
		if event is InputEventMouseButton && event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if is_mouse_out(): return
				var local_pos = to_local(get_global_mouse_position())
				
				var offset = (BOARD_SIZE * CELL_WIDTH) / 2.0
				var adjusted_x = local_pos.x + offset
				var adjusted_y = -local_pos.y + offset  
				
				var var1 = int(adjusted_x / CELL_WIDTH)  
				var var2 = int(adjusted_y / CELL_WIDTH)  
				
				print("Kattintás: grid=(", var1, ",", var2, ") board[", var2, "][", var1, "]=", board[var2][var1] if var2 < BOARD_SIZE && var1 < BOARD_SIZE else "invalid")
				
				if var1 < 0 || var1 >= BOARD_SIZE || var2 < 0 || var2 >= BOARD_SIZE:
					return
				
				var clicked_pos = Vector2(var2, var1)
				
				# Első kattintás: bábu kiválasztása
				if !state && (white && board[var2][var1] > 0 || !white && board[var2][var1] < 0):
					print("🔍 Kiválasztás próba: pos=", clicked_pos)
					print("  piece_objects.has?", piece_objects.has(clicked_pos))
	
					if piece_objects.has(clicked_pos):
						var piece = piece_objects[clicked_pos]
						print("  Piece info:", piece.get_info() if piece.has_method("get_info") else "N/A")
						print("  can_move?", piece.can_move())
						print("  attached_card:", piece.attached_card)
						print("  turns_remaining:", piece.turns_remaining)
		
						if piece.can_move():
							selected_piece = clicked_pos
							show_options()
							state = true
						else:
							print("⚠️ Nincs használható kártya ezen a bábun")
					else:
						print("  ❌ Nincs piece_objects-ben!")
				
				# Második kattintás: lépés végrehajtása
				elif state:
					if moves.has(clicked_pos):
						# Küldjük a lépést a szervernek
						send_move_action(selected_piece, clicked_pos)
					
					delete_dots()
					state = false

func send_move_action(from: Vector2, to: Vector2):
	var player_id = 0 if side else 1
	var action = {
		"type": "move_piece",
		"player_id": player_id,
		"from": from,
		"to": to
	}
	
	print("📤 Lépés action küldése: ", action)
	GameController.send_action(action)
	
func is_mouse_out():
	if get_rect().has_point(to_local(get_global_mouse_position())): return false
	return true
	
func display_board():
	print("🎨 display_board() hívva: white=", white, " side=", side)
	for child in pieces_node.get_children():
		child.queue_free()
	
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = TEXTURE_HOLDER.instantiate()
			if !side:
				holder.global_rotation_degrees = 180
				$"../Camera2D".global_rotation_degrees = 180
			pieces_node.add_child(holder)
			var offset = -(BOARD_SIZE * CELL_WIDTH) / 2.0
			holder.position = Vector2(j * CELL_WIDTH + (CELL_WIDTH / 2) + offset, -i * CELL_WIDTH - (CELL_WIDTH / 2) - offset)
			
			match board[i][j]:
				-6: holder.texture = BLACK_KING
				-5: holder.texture = BLACK_QUEEN
				-4: holder.texture = BLACK_ROOK
				-3: holder.texture = BLACK_BISHOP
				-2: holder.texture = BLACK_KNIGHT
				-1: holder.texture = BLACK_PAWN
				0: holder.texture = null
				6: holder.texture = WHITE_KING
				5: holder.texture = WHITE_QUEEN
				4: holder.texture = WHITE_ROOK
				3: holder.texture = WHITE_BISHOP
				2: holder.texture = WHITE_KNIGHT
				1: holder.texture = WHITE_PAWN
				
	if white: turn.texture = TURN_WHITE
	else: turn.texture = TURN_BLACK

func show_options():
	moves = get_moves(selected_piece)
	print("🎯 show_options() - mozgási lehetőségek: ", moves)
	if moves == []:
		state = false
		return
	show_dots()
	
func show_dots():
	print("🔵 show_dots() - pontok megjelenítése: ", moves.size(), " darab")
	for i in moves:
		var holder = TEXTURE_HOLDER.instantiate()
		dots.add_child(holder)
		holder.texture = PIECE_MOVE
		var offset = -(BOARD_SIZE * CELL_WIDTH) / 2.0
		holder.position = Vector2(i.y * CELL_WIDTH + (CELL_WIDTH / 2) + offset, -i.x * CELL_WIDTH - (CELL_WIDTH / 2) - offset)
		print("  🔵 Pont pozíció: ", holder.position)

func delete_dots():
	for child in dots.get_children():
		child.queue_free()

func set_move(start_pos : Vector2, end_pos : Vector2, promotion = null):
	print("🔄 set_move KEZDÉS: white=", white, " start=", start_pos, " end=", end_pos, " bábu=", board[start_pos.x][start_pos.y])
	
	if piece_objects.has(start_pos):
		var piece = piece_objects[start_pos]
		piece.position = end_pos
		piece_objects.erase(start_pos)
		piece_objects[end_pos] = piece
		print("  🔷 Piece mozgatva: %s -> %s" % [start_pos, end_pos])
	
	var just_now = false

	board[end_pos.x][end_pos.y] = board[start_pos.x][start_pos.y]
	board[start_pos.x][start_pos.y] = 0
	white = !white
	print("✅ set_move VÉGE: white MOST=", white)
	
	if piece_objects.has(end_pos): 
		var piece = piece_objects[end_pos]
		if piece.attached_card:
			if piece.turns_remaining != -1:  # Ha nem végtelen
				piece.use_turn()
	
	display_board()
	
	if (start_pos.x != end_pos.x || start_pos.y != end_pos.y) && (white && board[end_pos.x][end_pos.y] > 0 || !white && board[end_pos.x][end_pos.y] < 0):
		start_pos = end_pos
		show_options()
		state = true
	elif is_stalemate():
		print("DRAW")

func get_moves(selected : Vector2):
	if piece_objects.has(selected):
		var piece = piece_objects[selected]
		if piece.can_move():
			print("🎴 Kártya mozgás használata: %s" % piece.get_info())
			return get_card_based_moves(selected, piece)
		else:
			print("⚠️ Nincs használható kártya ezen a bábun!")
			return []
	
	return []
	
func get_card_based_moves(piece_position: Vector2, piece: Piece) -> Array:
	var _moves = []
	var directions = piece.get_movement_directions()
	
	print("  📍 Irányok: ", directions)
	
	for direction in directions:
		var target_pos = piece_position + direction
		
		if !is_valid_position(target_pos):
			continue
		
		if is_empty(target_pos) || is_enemy(target_pos):
			var original_value = board[target_pos.x][target_pos.y]
			board[target_pos.x][target_pos.y] = board[piece_position.x][piece_position.y]
			board[piece_position.x][piece_position.y] = 0
			
			_moves.append(target_pos)
			
			board[piece_position.x][piece_position.y] = board[target_pos.x][target_pos.y]
			board[target_pos.x][target_pos.y] = original_value
	
	print("  ✅ Érvényes lépések: ", _moves)
	return _moves

func is_valid_position(pos : Vector2):
	if pos.x >= 0 && pos.x < BOARD_SIZE && pos.y >= 0 && pos.y < BOARD_SIZE: return true
	return false
	
func is_empty(pos : Vector2):
	if board[pos.x][pos.y] == 0: return true
	return false
	
func is_enemy(pos : Vector2):
	if white && board[pos.x][pos.y] < 0 || !white && board[pos.x][pos.y] > 0: return true
	return false

func is_in_check(king_pos: Vector2):
	var directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
	Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	
	var pawn_direction = 1 if white else -1
	var pawn_attacks = [
		king_pos + Vector2(pawn_direction, 1),
		king_pos + Vector2(pawn_direction, -1)
	]
	
	for i in pawn_attacks:
		if is_valid_position(i):
			if white && board[i.x][i.y] == -1 || !white && board[i.x][i.y] == 1: return true
	
	for i in directions:
		var pos = king_pos + i
		if is_valid_position(pos):
			if white && board[pos.x][pos.y] == -6 || !white && board[pos.x][pos.y] == 6: return true
			
	for i in directions:
		var pos = king_pos + i
		while is_valid_position(pos):
			if !is_empty(pos):
				var piece = board[pos.x][pos.y]
				if (i.x == 0 || i.y == 0) && (white && piece in [-4, -5] || !white && piece in [4, 5]):
					return true
				elif (i.x != 0 && i.y != 0) && (white && piece in [-3, -5] || !white && piece in [3, 5]):
					return true
				break
			pos += i
			
	var knight_directions = [Vector2(2, 1), Vector2(2, -1), Vector2(1, 2), Vector2(1, -2),
	Vector2(-2, 1), Vector2(-2, -1), Vector2(-1, 2), Vector2(-1, -2)]
	
	for i in knight_directions:
		var pos = king_pos + i
		if is_valid_position(pos):
			if white && board[pos.x][pos.y] == -2 || !white && board[pos.x][pos.y] == 2:
				return true
				
	return false

func is_stalemate():
	if white:
		for i in BOARD_SIZE:
			for j in BOARD_SIZE:
				if board[i][j] > 0:
					if get_moves(Vector2(i, j)) != []: return false
				
	else:
		for i in BOARD_SIZE:
			for j in BOARD_SIZE:
				if board[i][j] < 0:
					if get_moves(Vector2(i, j)) != []: return false
	return true

# Szerver state alapján frissítés
func update_from_server_state(pieces_data: Dictionary, player_hands: Dictionary, current_turn: int):
	print("🔄 Board frissítése szerver state-ből")
	print("📦 Kapott pieces_data:")
	for pos in pieces_data:
		print("  ", pos, " -> ", pieces_data[pos])
	
	# Piece objektumok TELJES frissítése
	piece_objects.clear()
	
	for pos in pieces_data:
		var data = pieces_data[pos]
		var piece = Piece.new(data.position, data.color)
		
		# Kártya csatolása ha van
		if data.card_name != "":
			var card = CardLibrary.get_card(data.card_name)
			if card:
				piece.attach_card(card)
				piece.turns_remaining = data.turns_remaining
				print("  🎴 Piece-hez kártya csatolva: pos=%s, card=%s, turns=%d" % [pos, data.card_name, data.turns_remaining])
		
		piece_objects[pos] = piece
	
	print("  ✅ %d piece frissítve" % piece_objects.size())
	print("  🃏 Fehér kéz: ", player_hands[0])
	print("  🃏 Fekete kéz: ", player_hands[1])
	
	# Újrarajzoljuk a táblát
	display_board()
