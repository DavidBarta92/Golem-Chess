# GameState.gd - Központi játékállapot (nem autoload, instance)
class_name GameStateData

# Piece adat
class PieceData:
	var position: Vector2
	var color: int  # 1 = white, -1 = black
	var card_name: String = ""
	var turns_remaining: int = 0
	
	func _init(pos: Vector2, col: int):
		position = pos
		color = col
	
	func has_card() -> bool:
		return card_name != ""
	
	func can_move() -> bool:
		return has_card() && (turns_remaining > 0 || turns_remaining == -1)

# Game state
var pieces: Dictionary = {}  # Vector2 -> PieceData
var player_decks: Dictionary = {}  # int (player_id) -> Array[String] (card names)
var player_hands: Dictionary = {}  # int (player_id) -> Array[String] (card names)
var current_turn_player: int = 0  # 0 = fehér, 1 = fekete
var white_king_position: Vector2 = Vector2(-1, -1)
var black_king_position: Vector2 = Vector2(-1, -1)

func _init():
	pass

# Segédfüggvények
func get_piece(pos: Vector2) -> PieceData:
	return pieces.get(pos)

func set_piece(pos: Vector2, piece: PieceData):
	pieces[pos] = piece

func remove_piece(pos: Vector2):
	pieces.erase(pos)

func is_white_turn() -> bool:
	return current_turn_player == 0

func switch_turn():
	current_turn_player = 1 - current_turn_player
