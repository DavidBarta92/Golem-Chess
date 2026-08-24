extends Node

const PROGRESS_SCHEMA_VERSION: int = 1
const PROGRESS_PATH: String = "user://story_progress.json"

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

func is_node_completed(node_id: String) -> bool:
	ensure_loaded()
	var completed_ids: Array = progress_data.get("completed_node_ids", [])
	return completed_ids.has(node_id)

func mark_node_completed(node_id: String) -> void:
	ensure_loaded()
	var normalized_id: String = node_id.strip_edges()
	if normalized_id.is_empty():
		return

	var completed_ids: Array = progress_data.get("completed_node_ids", [])
	if completed_ids.has(normalized_id):
		return

	completed_ids.append(normalized_id)
	progress_data["completed_node_ids"] = completed_ids
	save_progress()

func get_completed_node_ids() -> Array[String]:
	ensure_loaded()
	var completed_ids: Array[String] = []
	for node_id in progress_data.get("completed_node_ids", []):
		completed_ids.append(str(node_id))
	return completed_ids

func save_progress() -> bool:
	if progress_data.is_empty():
		progress_data = _create_default_progress()

	var file := FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not save story progress to %s" % PROGRESS_PATH)
		return false

	file.store_string(JSON.stringify(progress_data, "\t"))
	return true

func _create_default_progress() -> Dictionary:
	return {
		"schema_version": PROGRESS_SCHEMA_VERSION,
		"completed_node_ids": [],
	}

func _normalize_progress(raw_data: Dictionary) -> Dictionary:
	var completed_ids: Array[String] = []
	var seen_ids: Dictionary = {}
	if raw_data.get("completed_node_ids", []) is Array:
		for node_id_value in raw_data.get("completed_node_ids", []):
			var node_id: String = str(node_id_value).strip_edges()
			if node_id.is_empty() or seen_ids.has(node_id):
				continue
			seen_ids[node_id] = true
			completed_ids.append(node_id)

	return {
		"schema_version": PROGRESS_SCHEMA_VERSION,
		"completed_node_ids": completed_ids,
	}
