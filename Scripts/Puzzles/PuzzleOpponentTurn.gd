@tool
extends Resource
class_name PuzzleOpponentTurn

## One of the opponent's turns, as the puzzle scripts it: optionally a stamp
## from the opponent's open codex page onto one of its golems, then optionally
## a move. PuzzleDefinition.opponent_turns plays them in order, one per turn.
##
## A move that is not possible when its turn comes (its golem was captured,
## the square is no longer reachable) is skipped, and the turn ends without
## one. So does a turn with no move at all.

## A stamp from the open page of the opponent's codex. Empty: none.
@export var affix_stamp: Stamp:
	set(value):
		affix_stamp = value
		_update_name()
## The opponent golem it goes on, by the square it stands on at that moment.
@export var affix_square: String = "":
	set(value):
		affix_square = value.strip_edges().to_lower()
		_update_name()
## The move, square to square. Empty: no move.
@export var move_from: String = "":
	set(value):
		move_from = value.strip_edges().to_lower()
		_update_name()
@export var move_to: String = "":
	set(value):
		move_to = value.strip_edges().to_lower()
		_update_name()

func has_affix() -> bool:
	return affix_stamp != null and PuzzleSquares.is_valid(affix_square)

func has_move() -> bool:
	return PuzzleSquares.is_valid(move_from) and PuzzleSquares.is_valid(move_to)

func _update_name() -> void:
	var parts: Array[String] = []
	if affix_stamp != null:
		parts.append("%s on %s" % [affix_stamp.stamp_name, affix_square])
	if !move_from.is_empty() or !move_to.is_empty():
		parts.append("%s-%s" % [move_from, move_to])
	resource_name = ", ".join(parts) if !parts.is_empty() else "pass"
