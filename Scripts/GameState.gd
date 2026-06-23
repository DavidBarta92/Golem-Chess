# GameState.gd - Shared game state data, not an autoload.
class_name GameStateData

var pieces: Dictionary = {}  # Vector2 -> Piece
var player_decks: Dictionary = {}  # int (player_id) -> Array[String] (card names)
var player_initial_decks: Dictionary = {}  # int (player_id) -> Array[String] (full starting deck order)
var player_hands: Dictionary = {}  # int (player_id) -> Array[String] (card names)
var current_turn_player: int = 0  # 0 = white, 1 = black
var completed_turn_counts: Dictionary = {0: 0, 1: 0}
var player_clock_seconds: Dictionary = {0: 300.0, 1: 300.0}
var white_nexus_position: Vector2 = Vector2(-1, -1)
var black_nexus_position: Vector2 = Vector2(-1, -1)
var player_base_fields: Dictionary = {
	0: BoardConfig.WHITE_BASE_FIELD,
	1: BoardConfig.BLACK_BASE_FIELD,
}
var board_effects: Array = []
var recent_card_transfers: Array = []
var recent_card_expirations: Array = []
var recent_bomb_effects: Array = []
var recent_pending_respawn_queues: Array = []
var recent_pending_respawn_arrivals: Array = []
var last_move: Dictionary = {}
var pending_respawns: Dictionary = {
	0: [],
	1: [],
}
var attached_card_this_turn: Dictionary = {
	0: false,
	1: false,
}
var attached_card_count_this_turn: Dictionary = {
	0: 0,
	1: 0,
}
var moved_piece_this_turn: Dictionary = {
	0: false,
	1: false,
}
var exchanged_card_this_turn: Dictionary = {
	0: false,
	1: false,
}
var played_card_hand_slots_this_turn: Dictionary = {
	0: [],
	1: [],
}
var exchanged_card_names_this_turn: Dictionary = {
	0: [],
	1: [],
}
var game_over: bool = false
var winner_player: int = -1
var win_condition: String = ""
var match_logger: MatchCsvLogger = null

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
	attached_card_count_this_turn[current_turn_player] = 0
	moved_piece_this_turn[current_turn_player] = false
	exchanged_card_this_turn[current_turn_player] = false
	played_card_hand_slots_this_turn[current_turn_player] = []
	exchanged_card_names_this_turn[current_turn_player] = []
