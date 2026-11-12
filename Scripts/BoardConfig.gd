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
const STARTING_PIECE_COUNT: int = 6
const STARTING_PIECE_COLUMNS: Array[int] = [0, 1, 2, 4, 5, 6]
const CENTER_INDEX: int = int(BOARD_SIZE / 2)
const WHITE_HOME_ROW: int = 0
const BLACK_HOME_ROW: int = BOARD_SIZE - 1
const WHITE_BASE_FIELD: Vector2 = Vector2(WHITE_HOME_ROW, CENTER_INDEX)
const BLACK_BASE_FIELD: Vector2 = Vector2(BLACK_HOME_ROW, CENTER_INDEX)

## How far apart two neighbouring ranks sit in the drawing order.
##
## More than one, so that a piece in flight can be slotted *between* two ranks:
## just behind the piece it is passing, yet still in front of everything
## further back. With a stride of one there is no such slot - a moving piece can
## only ever be a whole rank out - and it has to snap past its neighbour in a
## single frame, which reads as passing through it. Four leaves room inside a
## rank for the near/far side offset and for the lift of a piece in the air.
const DEPTH_Z_STRIDE: int = 4

static func get_color_for_player_id(player_id: int) -> int:
	return WHITE_COLOR if player_id == WHITE_PLAYER_ID else BLACK_COLOR

static func get_player_id_for_color(player_color: int) -> int:
	return WHITE_PLAYER_ID if player_color == WHITE_COLOR else BLACK_PLAYER_ID

## A square as it comes out of a synced state or a saved step: a Vector2, a
## Vector2i, an [x, y] array or an {x, y} dictionary. Anything else is `fallback`.
static func value_to_vector2(value, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		var vector_value: Vector2i = value
		return Vector2(vector_value.x, vector_value.y)
	if value is Array:
		var array_value: Array = value
		if array_value.size() >= 2:
			return Vector2(float(array_value[0]), float(array_value[1]))
	if value is Dictionary:
		var dict_value: Dictionary = value
		if dict_value.has("x") and dict_value.has("y"):
			return Vector2(float(dict_value.x), float(dict_value.y))
	return fallback

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
	for col in STARTING_PIECE_COLUMNS:
		if col < 0 or col >= BOARD_SIZE:
			continue
		output[WHITE_HOME_ROW][col] = STARTING_PIECE_VALUE
		output[BLACK_HOME_ROW][col] = -STARTING_PIECE_VALUE
	return output

static func get_home_row_for_player_id(player_id: int) -> int:
	return WHITE_HOME_ROW if player_id == WHITE_PLAYER_ID else BLACK_HOME_ROW

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
