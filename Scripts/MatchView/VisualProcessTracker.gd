extends RefCounted

var active_counts: Dictionary = {}

func begin(process_name: String) -> void:
	active_counts[process_name] = get_count(process_name) + 1

func finish(process_name: String) -> void:
	var remaining_count: int = maxi(0, get_count(process_name) - 1)
	if remaining_count == 0:
		active_counts.erase(process_name)
		return
	active_counts[process_name] = remaining_count

func get_count(process_name: String) -> int:
	return int(active_counts.get(process_name, 0))

func is_active(process_name: String) -> bool:
	return get_count(process_name) > 0

func has_any_active(process_names: Array = []) -> bool:
	if process_names.is_empty():
		for process_name in active_counts.keys():
			if get_count(str(process_name)) > 0:
				return true
		return false

	for process_name in process_names:
		if is_active(str(process_name)):
			return true
	return false
