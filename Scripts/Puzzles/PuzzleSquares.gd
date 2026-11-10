extends RefCounted
class_name PuzzleSquares

## Squares in a puzzle are written the way a chess player would, from the
## player's side of the board: columns a-g from left to right, rows 1-7 from
## the player's base line to the opponent's. "d1" is the player's base, "d7"
## the opponent's.
##
## On the board a square is Vector2(row, column), row 0 being the player's
## (white's) base line - see BoardConfig.get_cell_center_local.

const INVALID: Vector2 = Vector2(-1, -1)
const COLUMNS: String = "abcdefg"

## Vector2(row, column) for a name like "d4", or INVALID.
static func to_board(square: String) -> Vector2:
	var cleaned: String = square.strip_edges().to_lower()
	if cleaned.length() != 2:
		return INVALID
	var column: int = COLUMNS.find(cleaned[0])
	var row: int = int(cleaned[1]) - 1
	if column < 0 or !cleaned[1].is_valid_int() or row < 0 or row >= BoardConfig.BOARD_SIZE:
		return INVALID
	return Vector2(row, column)

## "d4" for Vector2(3, 3), or "" off the board.
static func to_name(board_pos: Vector2) -> String:
	var row: int = int(board_pos.x)
	var column: int = int(board_pos.y)
	if row < 0 or column < 0 or row >= BoardConfig.BOARD_SIZE or column >= COLUMNS.length():
		return ""
	return "%s%d" % [COLUMNS[column], row + 1]

static func is_valid(square: String) -> bool:
	return to_board(square) != INVALID
