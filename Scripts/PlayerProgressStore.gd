extends Node

const PROGRESS_SCHEMA_VERSION: int = 1
const PROGRESS_PATH: String = "user://player_progress.json"
const PACK_COST: int = 15
const WIN_POINTS_PER_WIN: int = 5

var progress_data: Dictionary = {}
var is_loaded: bool = false

func ensure_loaded() -> void:
	if is_loaded:
		return

	if FileAccess.file_exists(PROGRESS_PATH):
		var file := FileAccess.open(PROGRESS_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				progress_data = _normalize_progress(parsed)
				is_loaded = true
				save_progress()
				return

	progress_data = _create_default_progress()
	is_loaded = true
	save_progress()

func get_points() -> int:
	ensure_loaded()
	return maxi(0, int(progress_data.get("points", 0)))

func add_points(amount: int) -> int:
	ensure_loaded()
	progress_data["points"] = get_points() + maxi(0, amount)
	save_progress()
	return get_points()

func spend_points(amount: int) -> bool:
	ensure_loaded()
	var normalized_amount: int = maxi(0, amount)
	if normalized_amount <= 0:
		return true
	if get_points() < normalized_amount:
		return false

	progress_data["points"] = get_points() - normalized_amount
	save_progress()
	return true

func get_unopened_pack_count() -> int:
	ensure_loaded()
	return maxi(0, int(progress_data.get("unopened_packs", 0)))

func add_unopened_packs(amount: int) -> int:
	ensure_loaded()
	progress_data["unopened_packs"] = get_unopened_pack_count() + maxi(0, amount)
	save_progress()
	return get_unopened_pack_count()

func purchase_packs(amount: int) -> bool:
	ensure_loaded()
	var pack_count: int = maxi(0, amount)
	if pack_count <= 0:
		return false

	var total_cost: int = pack_count * PACK_COST
	if !spend_points(total_cost):
		return false

	add_unopened_packs(pack_count)
	return true

func open_pack() -> bool:
	ensure_loaded()
	var pack_count: int = get_unopened_pack_count()
	if pack_count <= 0:
		return false

	progress_data["unopened_packs"] = pack_count - 1
	save_progress()
	return true

func get_max_affordable_pack_count() -> int:
	return int(floor(float(get_points()) / float(PACK_COST)))

func save_progress() -> bool:
	if progress_data.is_empty():
		progress_data = _create_default_progress()

	var file := FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not save player progress to %s" % PROGRESS_PATH)
		return false

	file.store_string(JSON.stringify(progress_data, "\t"))
	return true

func _create_default_progress() -> Dictionary:
	return {
		"schema_version": PROGRESS_SCHEMA_VERSION,
		"points": 0,
		"unopened_packs": 0,
	}

func _normalize_progress(raw_data: Dictionary) -> Dictionary:
	return {
		"schema_version": PROGRESS_SCHEMA_VERSION,
		"points": maxi(0, int(raw_data.get("points", 0))),
		"unopened_packs": maxi(0, int(raw_data.get("unopened_packs", 0))),
	}
