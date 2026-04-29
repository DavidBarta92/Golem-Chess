# GameState.gd - Shared game state data, not an autoload.
class_name GameStateData

var pieces: Dictionary = {}  # Vector2 -> Piece
var player_decks: Dictionary = {}  # int (player_id) -> Array[String] (card names)
var player_hands: Dictionary = {}  # int (player_id) -> Array[String] (card names)
var current_turn_player: int = 0  # 0 = white, 1 = black
var white_king_position: Vector2 = Vector2(-1, -1)
var black_king_position: Vector2 = Vector2(-1, -1)
var player_base_fields: Dictionary = {
	0: Vector2(0, 2),
	1: Vector2(4, 2),
}
var board_effects: Array = []
var attached_card_this_turn: Dictionary = {
	0: false,
	1: false,
}
var game_over: bool = false
var winner_player: int = -1

func _init():
	pass

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
	attached_card_this_turn[current_turn_player] = false
