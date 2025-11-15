# GameState.gd - Központi játékállapot (nem autoload, instance)
class_name GameStateData

# Game state
var pieces: Dictionary = {}  # Vector2 -> Piece (a Piece.gd-ből!)
var player_decks: Dictionary = {}  # int (player_id) -> Array[String] (card names)
var player_hands: Dictionary = {}  # int (player_id) -> Array[String] (card names)
var current_turn_player: int = 0  # 0 = fehér, 1 = fekete
var white_king_position: Vector2 = Vector2(-1, -1)
var black_king_position: Vector2 = Vector2(-1, -1)

func _init():
	pass

# Segédfüggvények
func get_piece(pos: Vector2) -> Piece:
	return pieces.get(pos)

func set_piece(pos: Vector2, piece: Piece):
	pieces[pos] = piece

func remove_piece(pos: Vector2):
	pieces.erase(pos)

func is_white_turn() -> bool:
	return current_turn_player == 0

func switch_turn():
	current_turn_player = 1 - current_turn_player
