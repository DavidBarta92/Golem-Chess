extends Node

const PROGRESS_SCHEMA_VERSION: int = 2
const PROGRESS_PATH: String = "user://player_progress.json"
const PACK_COST: int = 15
const LEGACY_PACK_ID: String = "basic_pack"
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

func get_unopened_pack_count(pack_id: String = "") -> int:
	ensure_loaded()
	var pack_counts: Dictionary = get_unopened_pack_counts()
	var normalized_pack_id: String = pack_id.strip_edges()
	if !normalized_pack_id.is_empty():
		return maxi(0, int(pack_counts.get(normalized_pack_id, 0)))

	var total_count: int = 0
	for count_value in pack_counts.values():
		total_count += maxi(0, int(count_value))
	return total_count

func get_unopened_pack_counts() -> Dictionary:
	ensure_loaded()
	var raw_counts = progress_data.get("unopened_pack_counts", {})
	if raw_counts is Dictionary:
		var normalized_counts: Dictionary = {}
		for pack_id_value in raw_counts.keys():
			var pack_id: String = str(pack_id_value).strip_edges()
			if pack_id.is_empty():
				continue
			var count: int = maxi(0, int(raw_counts.get(pack_id_value, 0)))
			if count > 0:
				normalized_counts[pack_id] = count
		return normalized_counts
	return {}

func get_unopened_pack_ids() -> Array[String]:
	var pack_ids: Array[String] = []
	var pack_counts: Dictionary = get_unopened_pack_counts()
	for pack_id_value in pack_counts.keys():
		var pack_id: String = str(pack_id_value)
		if int(pack_counts.get(pack_id, 0)) > 0:
			pack_ids.append(pack_id)
	pack_ids.sort()
	return pack_ids

func add_unopened_packs(amount: int, pack_id: String = LEGACY_PACK_ID) -> int:
	ensure_loaded()
	var normalized_pack_id: String = _normalize_pack_id(pack_id)
	var pack_counts: Dictionary = get_unopened_pack_counts()
	pack_counts[normalized_pack_id] = maxi(0, int(pack_counts.get(normalized_pack_id, 0))) + maxi(0, amount)
	progress_data["unopened_pack_counts"] = _remove_empty_pack_counts(pack_counts)
	save_progress()
	return get_unopened_pack_count(normalized_pack_id)

func purchase_packs(amount: int, pack_id: String = LEGACY_PACK_ID, pack_price: int = PACK_COST) -> bool:
	ensure_loaded()
	var pack_count: int = maxi(0, amount)
	if pack_count <= 0:
		return false

	var total_cost: int = pack_count * maxi(0, pack_price)
	if !spend_points(total_cost):
		return false

	add_unopened_packs(pack_count, pack_id)
	return true

func open_pack(pack_id: String = "") -> bool:
	ensure_loaded()
	var normalized_pack_id: String = pack_id.strip_edges()
	if normalized_pack_id.is_empty():
		normalized_pack_id = get_first_unopened_pack_id()
	var pack_count: int = get_unopened_pack_count(normalized_pack_id)
	if pack_count <= 0:
		return false

	var pack_counts: Dictionary = get_unopened_pack_counts()
	var next_count: int = pack_count - 1
	if next_count <= 0:
		pack_counts.erase(normalized_pack_id)
	else:
		pack_counts[normalized_pack_id] = next_count
	progress_data["unopened_pack_counts"] = _remove_empty_pack_counts(pack_counts)
	save_progress()
	return true

func get_first_unopened_pack_id() -> String:
	var pack_ids: Array[String] = get_unopened_pack_ids()
	return pack_ids[0] if !pack_ids.is_empty() else ""

func get_max_affordable_pack_count(pack_price: int = PACK_COST) -> int:
	var normalized_price: int = maxi(0, pack_price)
	if normalized_price <= 0:
		return 99
	return int(floor(float(get_points()) / float(normalized_price)))

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
		"unopened_pack_counts": {},
	}

func _normalize_progress(raw_data: Dictionary) -> Dictionary:
	var pack_counts: Dictionary = {}
	if raw_data.get("unopened_pack_counts", {}) is Dictionary:
		var raw_counts: Dictionary = raw_data.get("unopened_pack_counts", {})
		for pack_id_value in raw_counts.keys():
			var pack_id: String = str(pack_id_value).strip_edges()
			if pack_id.is_empty():
				continue
			var count: int = maxi(0, int(raw_counts.get(pack_id_value, 0)))
			if count > 0:
				pack_counts[pack_id] = count
	else:
		var legacy_count: int = maxi(0, int(raw_data.get("unopened_packs", 0)))
		if legacy_count > 0:
			pack_counts[LEGACY_PACK_ID] = legacy_count

	return {
		"schema_version": PROGRESS_SCHEMA_VERSION,
		"points": maxi(0, int(raw_data.get("points", 0))),
		"unopened_pack_counts": pack_counts,
	}

func _normalize_pack_id(pack_id: String) -> String:
	var normalized_pack_id: String = pack_id.strip_edges()
	return normalized_pack_id if !normalized_pack_id.is_empty() else LEGACY_PACK_ID

func _remove_empty_pack_counts(pack_counts: Dictionary) -> Dictionary:
	var normalized_counts: Dictionary = {}
	for pack_id_value in pack_counts.keys():
		var pack_id: String = str(pack_id_value).strip_edges()
		if pack_id.is_empty():
			continue
		var count: int = maxi(0, int(pack_counts.get(pack_id_value, 0)))
		if count > 0:
			normalized_counts[pack_id] = count
	return normalized_counts
