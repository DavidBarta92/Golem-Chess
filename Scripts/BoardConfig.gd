extends RefCounted
class_name BoardConfig

const BOARD_SIZE: int = 7
const CELL_WIDTH: int = 18
const WHITE_PLAYER_ID: int = 0
const BLACK_PLAYER_ID: int = 1
const WHITE_COLOR: int = 1
const BLACK_COLOR: int = -1
const EMPTY_CELL: int = 0
const STARTING_PIECE_VALUE: int = 1
const STARTING_PIECE_COUNT: int = 5
const CENTER_INDEX: int = int(BOARD_SIZE / 2)
const WHITE_HOME_ROW: int = 0
const BLACK_HOME_ROW: int = BOARD_SIZE - 1
const WHITE_BASE_FIELD: Vector2 = Vector2(WHITE_HOME_ROW, CENTER_INDEX)
const BLACK_BASE_FIELD: Vector2 = Vector2(BLACK_HOME_ROW, CENTER_INDEX)

static func get_color_for_player_id(player_id: int) -> int:
	return WHITE_COLOR if player_id == WHITE_PLAYER_ID else BLACK_COLOR

static func get_player_id_for_color(player_color: int) -> int:
	return WHITE_PLAYER_ID if player_color == WHITE_COLOR else BLACK_PLAYER_ID

static func get_base_field_for_player_id(player_id: int) -> Vector2:
	return WHITE_BASE_FIELD if player_id == WHITE_PLAYER_ID else BLACK_BASE_FIELD

static func get_opponent_base_field_for_color(player_color: int) -> Vector2:
	return BLACK_BASE_FIELD if player_color == WHITE_COLOR else WHITE_BASE_FIELD

static func create_empty_board() -> Array:
	var output: Array = []
	for _row in BOARD_SIZE:
		var row_data: Array = []
		for _col in BOARD_SIZE:
			row_data.append(EMPTY_CELL)
		output.append(row_data)
	return output

static func create_starting_board() -> Array:
	var output: Array = create_empty_board()
	var piece_count: int = mini(STARTING_PIECE_COUNT, BOARD_SIZE)
	var start_col: int = int((BOARD_SIZE - piece_count) / 2)
	for offset in piece_count:
		var col: int = start_col + offset
		output[WHITE_HOME_ROW][col] = STARTING_PIECE_VALUE
		output[BLACK_HOME_ROW][col] = -STARTING_PIECE_VALUE
	return output

static func get_board_pixel_size() -> float:
	return float(BOARD_SIZE * CELL_WIDTH)

static func get_board_rect_local() -> Rect2:
	var board_width: float = get_board_pixel_size()
	return Rect2(Vector2.ONE * -board_width * 0.5, Vector2.ONE * board_width)

static func get_cell_center_local(board_pos: Vector2) -> Vector2:
	var offset: float = -get_board_pixel_size() * 0.5
	return Vector2(
		board_pos.y * CELL_WIDTH + (CELL_WIDTH * 0.5) + offset,
		-board_pos.x * CELL_WIDTH - (CELL_WIDTH * 0.5) - offset
	)
