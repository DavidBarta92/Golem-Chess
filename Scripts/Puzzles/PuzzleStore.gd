extends RefCounted
class_name PuzzleStore

## What the player has done with each puzzle, in user://puzzles.json:
##   "opened"   ids of letters read at least once
##   "solved"   ids of puzzles solved at least once
##   "rewarded" ids whose reward has been paid - once per puzzle, ever
## Plus which puzzle the board scene should load (`active_puzzle_id`), which
## only lives for the session.

const FILE_NAME: String = "puzzles.json"
const SCHEMA_VERSION: int = 1
const KEY_OPENED: String = "opened"
const KEY_SOLVED: String = "solved"
const KEY_REWARDED: String = "rewarded"

enum State { NEW, OPEN, SOLVED }

static var active_puzzle_id: String = ""
## The page of letters the screen was on, so coming back from a puzzle lands
## there again.
static var last_page: int = 0
## Whether the puzzle just solved paid its reward (the first solve) or not:
## the reward scene plays either way, but only moves the counters for one.
static var last_reward_paid: bool = false
static var _data: Dictionary = {}
static var _loaded: bool = false

static func get_state(puzzle_id: String) -> State:
	if _has(KEY_SOLVED, puzzle_id):
		return State.SOLVED
	if _has(KEY_OPENED, puzzle_id):
		return State.OPEN
	return State.NEW

static func is_solved(puzzle_id: String) -> bool:
	return _has(KEY_SOLVED, puzzle_id)

static func mark_opened(puzzle_id: String) -> void:
	_add(KEY_OPENED, puzzle_id)

static func mark_solved(puzzle_id: String) -> void:
	_add(KEY_OPENED, puzzle_id)
	_add(KEY_SOLVED, puzzle_id)

## Pays the puzzle's reward unless it was paid before. True when this call
## paid it.
static func grant_reward(puzzle: PuzzleDefinition) -> bool:
	if puzzle == null or _has(KEY_REWARDED, puzzle.puzzle_id):
		return false
	match puzzle.reward_kind:
		PuzzleDefinition.RewardKind.COINS:
			PlayerProgressStore.add_points(puzzle.reward_amount)
		PuzzleDefinition.RewardKind.DRAW_POINTS:
			PlayerProgressStore.add_draw_points(puzzle.reward_amount)
		PuzzleDefinition.RewardKind.STAMP:
			var print_id: String = puzzle.get_reward_print_id()
			if print_id.is_empty():
				push_warning("Puzzle %s: no print to pay out." % puzzle.puzzle_id)
				return false
			PlayerCollectionStore.add_local_print_copy(print_id, puzzle.reward_amount)
	_add(KEY_REWARDED, puzzle.puzzle_id)
	return true

static func count_unopened(puzzles: Array[PuzzleDefinition]) -> int:
	var count: int = 0
	for puzzle in puzzles:
		if get_state(puzzle.puzzle_id) == State.NEW:
			count += 1
	return count

static func _has(key: String, puzzle_id: String) -> bool:
	_ensure_loaded()
	return (_data.get(key, []) as Array).has(puzzle_id)

static func _add(key: String, puzzle_id: String) -> void:
	_ensure_loaded()
	var ids: Array = _data.get(key, [])
	if ids.has(puzzle_id):
		return
	ids.append(puzzle_id)
	_data[key] = ids
	SaveIO.write_json(FILE_NAME, _data, SCHEMA_VERSION)

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var raw: Dictionary = SaveIO.read_json(FILE_NAME)
	_data = {}
	for key in [KEY_OPENED, KEY_SOLVED, KEY_REWARDED]:
		var ids: Array = []
		var raw_ids = raw.get(key, [])
		if raw_ids is Array:
			for id_value in raw_ids:
				var id: String = str(id_value).strip_edges()
				if !id.is_empty() and !ids.has(id):
					ids.append(id)
		_data[key] = ids
