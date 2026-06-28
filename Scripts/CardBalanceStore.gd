extends RefCounted
class_name CardBalanceStore

const PROJECT_BALANCE_PATH: String = "res://Data/Balance/card_values.tres"
const SESSION_FOLDER_NAME: String = "balance_sessions"
const SESSION_FILE_EXTENSION: String = ".tres"

const INT_STAT_KEYS: Array[String] = [
	"seen", "attach", "move", "move_win", "capture", "seeker_capture", "base_entry",
	"expire", "return_deck", "return_hand", "effect", "base_effect",
	"effect_cards_moved", "effect_affected", "win_slots", "lose_slots",
]

const FLOAT_STAT_KEYS: Array[String] = [
	"progress", "win_attach", "lose_attach", "win_moves", "lose_moves",
	"win_progress", "lose_progress", "win_captures", "lose_captures",
]

const WIN_CONDITION_KEYS: Array[String] = [
	"base_reached",
	"no_valid_move",
	"seeker_card_lost",
	"unknown",
]

static var project_balance_cache: CardBalanceData = null

static func load_project_balance() -> CardBalanceData:
	if project_balance_cache != null:
		return project_balance_cache

	var data := load(PROJECT_BALANCE_PATH) as CardBalanceData
	if data != null:
		project_balance_cache = data
		return data

	project_balance_cache = CardBalanceData.new()
	return project_balance_cache

static func get_card_value(card_name: String, fallback: float = 0.0) -> float:
	return load_project_balance().get_card_value(card_name, fallback)

static func save_session_balance(log_dir: String, session_id: String, raw_rows: Array[Dictionary], source_match_count: int) -> bool:
	if session_id.strip_edges().is_empty() or raw_rows.is_empty():
		return false

	var data := rows_to_balance_data(raw_rows, source_match_count)
	data.session_id = session_id
	var session_dir: String = get_session_dir(log_dir)
	DirAccess.make_dir_recursive_absolute(globalize_path(session_dir))
	return save_balance_data(data, "%s/%s.tres" % [session_dir.trim_suffix("/"), sanitize_file_name(session_id)])

static func promote_unpromoted_sessions(log_dir: String) -> Dictionary:
	var project_data := load_project_balance()
	var session_files: Array[String] = list_session_files(log_dir)
	var merged_sessions: Array[String] = []
	var skipped_sessions: Array[String] = []
	var failed_sessions: Array[String] = []

	for session_path: String in session_files:
		var session_data := load(session_path) as CardBalanceData
		if session_data == null:
			failed_sessions.append(session_path)
			continue

		var session_id: String = session_data.session_id.strip_edges()
		if session_id.is_empty():
			session_id = session_path.get_file().get_basename()

		if project_data.promoted_sessions.has(session_id):
			skipped_sessions.append(session_id)
			continue

		merge_balance_data(project_data, session_data)
		project_data.promoted_sessions.append(session_id)
		merged_sessions.append(session_id)

	recalculate_balance_data(project_data)
	project_data.generated_unix = int(Time.get_unix_time_from_system())
	DirAccess.make_dir_recursive_absolute(globalize_path(PROJECT_BALANCE_PATH.get_base_dir()))
	var saved: bool = save_balance_data(project_data, PROJECT_BALANCE_PATH)
	if saved:
		project_balance_cache = project_data
	return {
		"ok": saved,
		"merged_sessions": merged_sessions,
		"skipped_sessions": skipped_sessions,
		"failed_sessions": failed_sessions,
		"saved_path": PROJECT_BALANCE_PATH,
	}

static func delete_session_files(log_dir: String) -> int:
	var deleted_count: int = 0
	for session_path: String in list_session_files(log_dir):
		var error: int = DirAccess.remove_absolute(globalize_path(session_path))
		if error == OK:
			deleted_count += 1
	return deleted_count

static func rows_to_balance_data(raw_rows: Array[Dictionary], source_match_count: int) -> CardBalanceData:
	var data := CardBalanceData.new()
	data.schema_version = CardBalanceData.CURRENT_SCHEMA_VERSION
	data.source_match_count = source_match_count
	data.generated_unix = int(Time.get_unix_time_from_system())
	data.win_condition_counts = get_win_condition_counts_from_rows(raw_rows)
	for row: Dictionary in raw_rows:
		var card_name: String = str(row.get("card_name", "")).strip_edges()
		if card_name.is_empty():
			continue
		data.cards[card_name] = row_to_stats(row)
	return data

static func row_to_stats(row: Dictionary) -> Dictionary:
	return {
		"v": parse_float(row.get("card_value", 0.0)),
		"w": parse_int(row.get("move_count", 0)),
		"trend": parse_float(row.get("trend_score", 50.0)),
		"conf": parse_float(row.get("sample_confidence", 0.0)),
		"seen": parse_int(row.get("seen_count", 0)),
		"attach": parse_int(row.get("attach_count", 0)),
		"move": parse_int(row.get("move_count", 0)),
		"move_win": parse_int(row.get("move_win_count", 0)),
		"capture": parse_int(row.get("capture_count", 0)),
		"seeker_capture": parse_int(row.get("seeker_capture_count", 0)),
		"base_entry": parse_int(row.get("base_entry_count", 0)),
		"progress": parse_float(row.get("progress_sum", 0.0)),
		"expire": parse_int(row.get("expire_count", 0)),
		"return_deck": parse_int(row.get("return_deck_count", 0)),
		"return_hand": parse_int(row.get("return_hand_count", 0)),
		"effect": parse_int(row.get("effect_trigger_count", 0)),
		"base_effect": parse_int(row.get("base_change_effect_count", 0)),
		"effect_cards_moved": parse_int(row.get("cards_moved_by_effect", 0)),
		"effect_affected": parse_int(row.get("affected_count_by_effect", 0)),
		"win_slots": parse_int(row.get("win_slot_count", 0)),
		"lose_slots": parse_int(row.get("lose_slot_count", 0)),
		"win_attach": parse_float(row.get("win_attach_sum", 0.0)),
		"lose_attach": parse_float(row.get("lose_attach_sum", 0.0)),
		"win_moves": parse_float(row.get("win_moves_sum", 0.0)),
		"lose_moves": parse_float(row.get("lose_moves_sum", 0.0)),
		"win_progress": parse_float(row.get("win_progress_sum", 0.0)),
		"lose_progress": parse_float(row.get("lose_progress_sum", 0.0)),
		"win_captures": parse_float(row.get("win_captures_sum", 0.0)),
		"lose_captures": parse_float(row.get("lose_captures_sum", 0.0)),
	}

static func merge_balance_data(target: CardBalanceData, session_data: CardBalanceData) -> void:
	target.source_match_count += max(0, session_data.source_match_count)
	for card_name_value in session_data.cards:
		var card_name: String = str(card_name_value)
		var incoming_value = session_data.cards.get(card_name, {})
		if !(incoming_value is Dictionary):
			continue
		var incoming: Dictionary = incoming_value
		var current_value = target.cards.get(card_name, {})
		var current: Dictionary = {}
		if current_value is Dictionary:
			current = current_value

		for key: String in INT_STAT_KEYS:
			current[key] = int(current.get(key, 0)) + int(incoming.get(key, 0))
		for key: String in FLOAT_STAT_KEYS:
			current[key] = float(current.get(key, 0.0)) + float(incoming.get(key, 0.0))
		target.cards[card_name] = current

	for key: String in WIN_CONDITION_KEYS:
		target.win_condition_counts[key] = int(target.win_condition_counts.get(key, 0)) + int(session_data.win_condition_counts.get(key, 0))

static func recalculate_balance_data(data: CardBalanceData) -> void:
	var rows: Array[Dictionary] = []
	for card_name_value in data.cards:
		var card_name: String = str(card_name_value)
		var stats_value = data.cards.get(card_name, {})
		if stats_value is Dictionary:
			var stats: Dictionary = stats_value
			rows.append(stats_to_row(card_name, stats, data.source_match_count, data.generated_unix, data.win_condition_counts))

	var generator := CardBalanceReportGenerator.new()
	generator.add_card_values(rows)
	rows.sort_custom(Callable(generator, "sort_report_rows_desc"))

	data.cards.clear()
	for row: Dictionary in rows:
		data.cards[str(row.get("card_name", ""))] = row_to_stats(row)

static func stats_to_row(card_name: String, stats: Dictionary, source_match_count: int, generated_unix: int, win_condition_counts: Dictionary = {}) -> Dictionary:
	var seen_count: int = int(stats.get("seen", 0))
	var attach_count: int = int(stats.get("attach", 0))
	var move_count: int = int(stats.get("move", 0))
	var move_win_count: int = int(stats.get("move_win", 0))
	var capture_count: int = int(stats.get("capture", 0))
	var progress_sum: float = float(stats.get("progress", 0.0))
	var win_slots: int = int(stats.get("win_slots", 0))
	var lose_slots: int = int(stats.get("lose_slots", 0))
	var win_attach: float = float(stats.get("win_attach", 0.0))
	var lose_attach: float = float(stats.get("lose_attach", 0.0))
	var win_moves: float = float(stats.get("win_moves", 0.0))
	var lose_moves: float = float(stats.get("lose_moves", 0.0))
	var win_progress: float = float(stats.get("win_progress", 0.0))
	var lose_progress: float = float(stats.get("lose_progress", 0.0))
	var win_captures: float = float(stats.get("win_captures", 0.0))
	var lose_captures: float = float(stats.get("lose_captures", 0.0))

	return {
		"card_name": card_name,
		"seen_count": seen_count,
		"attach_count": attach_count,
		"attach_rate": safe_div(float(attach_count), float(seen_count)),
		"move_count": move_count,
		"move_win_count": move_win_count,
		"move_win_rate": safe_div(float(move_win_count), float(move_count)),
		"capture_count": capture_count,
		"capture_rate": safe_div(float(capture_count), float(move_count)),
		"seeker_capture_count": int(stats.get("seeker_capture", 0)),
		"base_entry_count": int(stats.get("base_entry", 0)),
		"progress_sum": progress_sum,
		"avg_progress_per_move": safe_div(progress_sum, float(move_count)),
		"delta_attach_per_player_match": safe_div(win_attach, float(win_slots)) - safe_div(lose_attach, float(lose_slots)),
		"delta_moves_per_player_match": safe_div(win_moves, float(win_slots)) - safe_div(lose_moves, float(lose_slots)),
		"delta_progress_per_player_match": safe_div(win_progress, float(win_slots)) - safe_div(lose_progress, float(lose_slots)),
		"delta_captures_per_player_match": safe_div(win_captures, float(win_slots)) - safe_div(lose_captures, float(lose_slots)),
		"expire_count": int(stats.get("expire", 0)),
		"return_deck_count": int(stats.get("return_deck", 0)),
		"return_hand_count": int(stats.get("return_hand", 0)),
		"effect_trigger_count": int(stats.get("effect", 0)),
		"base_change_effect_count": int(stats.get("base_effect", 0)),
		"cards_moved_by_effect": int(stats.get("effect_cards_moved", 0)),
		"affected_count_by_effect": int(stats.get("effect_affected", 0)),
		"win_slot_count": win_slots,
		"lose_slot_count": lose_slots,
		"win_attach_sum": win_attach,
		"lose_attach_sum": lose_attach,
		"win_moves_sum": win_moves,
		"lose_moves_sum": lose_moves,
		"win_progress_sum": win_progress,
		"lose_progress_sum": lose_progress,
		"win_captures_sum": win_captures,
		"lose_captures_sum": lose_captures,
		"generated_unix": generated_unix,
		"matches_analyzed": source_match_count,
		"base_reached_match_count": int(win_condition_counts.get("base_reached", 0)),
		"no_valid_move_match_count": int(win_condition_counts.get("no_valid_move", 0)),
		"seeker_card_lost_match_count": int(win_condition_counts.get("seeker_card_lost", 0)),
		"unknown_win_condition_match_count": int(win_condition_counts.get("unknown", 0)),
	}

static func get_win_condition_counts_from_rows(raw_rows: Array[Dictionary]) -> Dictionary:
	var counts: Dictionary = {
		"base_reached": 0,
		"no_valid_move": 0,
		"seeker_card_lost": 0,
		"unknown": 0,
	}
	if raw_rows.is_empty():
		return counts

	var first_row: Dictionary = raw_rows[0]
	counts["base_reached"] = parse_int(first_row.get("base_reached_match_count", 0))
	counts["no_valid_move"] = parse_int(first_row.get("no_valid_move_match_count", 0))
	counts["seeker_card_lost"] = parse_int(first_row.get("seeker_card_lost_match_count", 0))
	counts["unknown"] = parse_int(first_row.get("unknown_win_condition_match_count", 0))
	return counts

static func list_session_files(log_dir: String) -> Array[String]:
	var session_dir: String = get_session_dir(log_dir)
	var dir := DirAccess.open(session_dir)
	if dir == null:
		return []

	var files: Array[String] = []
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while !file_name.is_empty():
		if !dir.current_is_dir() and file_name.ends_with(SESSION_FILE_EXTENSION):
			files.append("%s/%s" % [session_dir.trim_suffix("/"), file_name])
		file_name = dir.get_next()
	dir.list_dir_end()
	files.sort()
	return files

static func save_balance_data(data: CardBalanceData, path: String) -> bool:
	var error: int = ResourceSaver.save(data, path)
	if error != OK:
		push_warning("Could not save card balance data to %s. Error: %s" % [path, error])
		return false
	return true

static func get_session_dir(log_dir: String) -> String:
	return "%s/%s" % [clean_log_dir(log_dir).trim_suffix("/"), SESSION_FOLDER_NAME]

static func clean_log_dir(log_dir: String) -> String:
	var cleaned: String = log_dir.strip_edges()
	if cleaned.is_empty():
		cleaned = GameConfig.DEFAULT_AI_VS_AI_CSV_LOG_DIR
	return cleaned.replace("\\", "/")

static func globalize_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	return path

static func sanitize_file_name(raw_name: String) -> String:
	var output: String = raw_name.strip_edges()
	for character: String in [":", "\\", "/", "*", "?", "\"", "<", ">", "|", " "]:
		output = output.replace(character, "_")
	return output

static func safe_div(numerator: float, denominator: float) -> float:
	if is_zero_approx(denominator):
		return 0.0
	return numerator / denominator

static func parse_int(value, fallback: int = 0) -> int:
	if value is int:
		return int(value)
	if value is float:
		return int(value)
	var text: String = str(value).strip_edges()
	return int(text) if text.is_valid_int() else fallback

static func parse_float(value, fallback: float = 0.0) -> float:
	if value is float or value is int:
		return float(value)
	var text: String = str(value).strip_edges()
	return float(text) if text.is_valid_float() else fallback
