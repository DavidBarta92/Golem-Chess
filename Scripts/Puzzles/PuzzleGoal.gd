@tool
extends Resource
class_name PuzzleGoal

## Something the player has to bring about. A puzzle is solved the moment
## every one of its goals holds at once, within its turn limit.
##
## Kinds, and the fields each one reads:
##   WIN_GAME         a crowned golem of the player's on the opponent's base
##   CAPTURE_PIECE    the opponent golem that starts on `target_square` is
##                    captured (by a move of the player's)
##   CAPTURE_COUNT    `count` captures by the player's moves
##   REACH_SQUARE     a golem of the player's stands on `target_square`;
##                    `piece_square` and `stamp` narrow down which
##   STAMP_DURATION   a golem of the player's has `count` moves left on its
##                    stamp (`comparison`); `piece_square` and `stamp` narrow
##                    down which
##   AFFIX_STAMP      the player has affixed `stamp` (any stamp if empty)
##                    `count` times; `piece_square` narrows down onto which
##   PLACE_CROWN      the player has crowned a golem; `piece_square` narrows
##                    down which
##
## CAPTURE_*, AFFIX_STAMP and PLACE_CROWN stay done once they happen. The two
## that describe the board - REACH_SQUARE and STAMP_DURATION - have to be true
## at the moment the last goal is met.
##
## `piece_square` always names a golem by where it stands when the puzzle
## starts, and follows it wherever it goes.

enum Kind { WIN_GAME, CAPTURE_PIECE, CAPTURE_COUNT, REACH_SQUARE, STAMP_DURATION, AFFIX_STAMP, PLACE_CROWN }
enum Comparison { AT_LEAST, EXACTLY, AT_MOST }

## A Kind. (Ints rather than the enums: a typed enum with a setter does not
## resolve inside its own class_name.)
@export_enum("Win Game", "Capture Piece", "Capture Count", "Reach Square", "Stamp Duration", "Affix Stamp", "Place Crown") var kind: int = Kind.WIN_GAME:
	set(value):
		kind = value
		_update_name()
		notify_property_list_changed()

## CAPTURE_PIECE: the opponent golem's starting square. REACH_SQUARE: the
## square to reach.
@export var target_square: String = "":
	set(value):
		target_square = value.strip_edges().to_lower()
		_update_name()

## Which of the player's golems counts, by its starting square. Empty: any.
@export var piece_square: String = "":
	set(value):
		piece_square = value.strip_edges().to_lower()
		_update_name()

## AFFIX_STAMP: the stamp to affix. REACH_SQUARE / STAMP_DURATION: only a golem
## wearing it counts. Empty: any.
@export var stamp: Stamp:
	set(value):
		stamp = value
		_update_name()

## CAPTURE_COUNT: captures. STAMP_DURATION: moves left. AFFIX_STAMP: times.
@export_range(0, 20) var count: int = 1:
	set(value):
		count = value
		_update_name()

## STAMP_DURATION only.
@export_enum("At Least", "Exactly", "At Most") var comparison: int = Comparison.AT_LEAST:
	set(value):
		comparison = value
		_update_name()

func compare(value: int) -> bool:
	match comparison:
		Comparison.EXACTLY:
			return value == count
		Comparison.AT_MOST:
			return value <= count
	return value >= count

func is_event() -> bool:
	return kind in [Kind.WIN_GAME, Kind.CAPTURE_PIECE, Kind.CAPTURE_COUNT, Kind.AFFIX_STAMP, Kind.PLACE_CROWN]

## Only the fields the chosen kind reads are shown.
func _validate_property(property: Dictionary) -> void:
	var used: Dictionary = {
		Kind.WIN_GAME: [],
		Kind.CAPTURE_PIECE: ["target_square"],
		Kind.CAPTURE_COUNT: ["count"],
		Kind.REACH_SQUARE: ["target_square", "piece_square", "stamp"],
		Kind.STAMP_DURATION: ["count", "comparison", "piece_square", "stamp"],
		Kind.AFFIX_STAMP: ["stamp", "count", "piece_square"],
		Kind.PLACE_CROWN: ["piece_square"],
	}
	var name: String = str(property.get("name", ""))
	if name in ["target_square", "piece_square", "stamp", "count", "comparison"] and !(used[kind] as Array).has(name):
		property["usage"] = PROPERTY_USAGE_NO_EDITOR

func _update_name() -> void:
	var kind_name: String = str(Kind.keys()[kind]).capitalize()
	var details: Array[String] = []
	match kind:
		Kind.CAPTURE_PIECE, Kind.REACH_SQUARE:
			details.append(target_square)
		Kind.CAPTURE_COUNT:
			details.append(str(count))
		Kind.STAMP_DURATION:
			details.append(["≥", "=", "≤"][comparison] + str(count))
		Kind.AFFIX_STAMP:
			details.append(stamp.stamp_name if stamp != null else "any stamp")
	if !piece_square.is_empty() and kind in [Kind.REACH_SQUARE, Kind.STAMP_DURATION, Kind.AFFIX_STAMP, Kind.PLACE_CROWN]:
		details.append("by " + piece_square)
	resource_name = kind_name if details.is_empty() else "%s %s" % [kind_name, " ".join(details)]
