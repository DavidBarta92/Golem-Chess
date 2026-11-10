@tool
extends Resource
class_name PuzzlePiece

## One golem standing on a puzzle's board. Add one per golem to
## PuzzleDefinition.pieces; a square left out stays empty.

enum Side { PLAYER, OPPONENT }

## Side.PLAYER or Side.OPPONENT. (An int rather than the enum: a typed enum
## with a setter does not resolve inside its own class_name.)
@export_enum("Player", "Opponent") var side: int = Side.PLAYER:
	set(value):
		side = value
		_update_name()

## Where it stands, from the player's side: "a1" is the player's left corner,
## "d1" the player's base, "d7" the opponent's base.
@export var square: String = "a1":
	set(value):
		square = value.strip_edges().to_lower()
		_update_name()

## The stamp it already wears. Empty: a bare golem.
@export var stamp: Stamp:
	set(value):
		stamp = value
		_update_name()

## How many moves its stamp has left. -1: the stamp's own duration.
@export_range(-1, 20) var moves_left: int = -1

## Wore its stamp or its crown only this turn: it may not move until the
## next one.
@export var exhausted: bool = false

## Wears its side's crown. At most one crowned golem per side.
@export var crowned: bool = false:
	set(value):
		crowned = value
		_update_name()

func get_color() -> int:
	return 1 if side == Side.PLAYER else -1

func get_board_position() -> Vector2:
	return PuzzleSquares.to_board(square)

func get_moves_left() -> int:
	if stamp == null:
		return 0
	return stamp.duration if moves_left < 0 else moves_left

## What the inspector's list shows for it: "Player d4 Knight (crowned)".
func _update_name() -> void:
	var words: Array[String] = ["Player" if side == Side.PLAYER else "Opponent", square]
	words.append(stamp.stamp_name if stamp != null else "bare")
	if crowned:
		words.append("(crowned)")
	resource_name = " ".join(words)
