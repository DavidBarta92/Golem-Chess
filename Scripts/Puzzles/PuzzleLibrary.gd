extends RefCounted
class_name PuzzleLibrary

## Every puzzle under res://Puzzles/ (subfolders too), loaded once. A puzzle
## with problems (PuzzleDefinition.get_problems) is left out with a warning.

const PUZZLES_PATH: String = "res://Puzzles"

static var _puzzles: Array[PuzzleDefinition] = []
static var _loaded: bool = false

## The enabled puzzles, in their `order`, then by id.
static func get_puzzles() -> Array[PuzzleDefinition]:
	if !_loaded:
		_load()
	return _puzzles.duplicate()

static func get_puzzle(puzzle_id: String) -> PuzzleDefinition:
	for puzzle in get_puzzles():
		if puzzle.puzzle_id == puzzle_id:
			return puzzle
	return null

static func reload() -> void:
	_loaded = false
	_puzzles.clear()

static func _load() -> void:
	_loaded = true
	_puzzles.clear()
	var seen_ids: Dictionary = {}
	for path in _find_resource_paths(PUZZLES_PATH):
		var puzzle := load(path) as PuzzleDefinition
		if puzzle == null or !puzzle.enabled:
			continue
		var problems: Array[String] = puzzle.get_problems()
		if seen_ids.has(puzzle.puzzle_id):
			problems.append("puzzle_id '%s' is used by %s too" % [puzzle.puzzle_id, seen_ids[puzzle.puzzle_id]])
		if !problems.is_empty():
			push_warning("Puzzle %s left out: %s" % [path, "; ".join(problems)])
			continue
		seen_ids[puzzle.puzzle_id] = path
		_puzzles.append(puzzle)
	_puzzles.sort_custom(func(a: PuzzleDefinition, b: PuzzleDefinition) -> bool:
		if a.order != b.order:
			return a.order < b.order
		return a.puzzle_id < b.puzzle_id)

## Exported games list "x.tres.remap" in place of "x.tres".
static func _find_resource_paths(directory_path: String) -> Array[String]:
	var paths: Array[String] = []
	var dir: DirAccess = DirAccess.open(directory_path)
	if dir == null:
		push_warning("Puzzle folder not found: %s" % directory_path)
		return paths
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		var path: String = directory_path.path_join(file_name)
		if dir.current_is_dir():
			if !file_name.begins_with("."):
				paths.append_array(_find_resource_paths(path))
		else:
			var resource_name: String = file_name.trim_suffix(".remap")
			if resource_name.ends_with(".tres") or resource_name.ends_with(".res"):
				paths.append(directory_path.path_join(resource_name))
		file_name = dir.get_next()
	dir.list_dir_end()
	paths.sort()
	return paths
