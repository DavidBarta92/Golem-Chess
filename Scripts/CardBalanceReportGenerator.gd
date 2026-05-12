extends RefCounted
class_name CardBalanceReportGenerator

const REPORT_FILE_NAME: String = "card_balance_report.csv"
const MATCHES_FILE_NAME: String = "matches.csv"
const CARD_EVENTS_FILE_NAME: String = "card_events.csv"
const MOVE_EVENTS_FILE_NAME: String = "move_events.csv"
const EFFECT_EVENTS_FILE_NAME: String = "effect_events.csv"
const DEFAULT_LOG_DIR: String = "user://ai_match_logs"

const REPORT_HEADERS: Array[String] = [
	"card_name",
	"card_value",
	"trend_score",
	"ai_score_adjustment",
	"ai_attach_score_adjustment",
	"ai_value_multiplier",
	"sample_confidence",
	"matches_analyzed",
	"generated_unix",
	"base_reached_match_count",
	"no_valid_move_match_count",
	"nexus_card_lost_match_count",
	"unknown_win_condition_match_count",
	"seen_count",
	"attach_count",
	"attach_rate",
	"move_count",
	"move_win_count",
	"move_win_rate",
	"capture_count",
	"capture_rate",
	"nexus_capture_count",
	"base_entry_count",
	"progress_sum",
	"avg_progress_per_move",
	"delta_attach_per_player_match",
	"delta_moves_per_player_match",
	"delta_progress_per_player_match",
	"delta_captures_per_player_match",
	"expire_count",
	"return_deck_count",
	"return_hand_count",
	"effect_trigger_count",
	"base_change_effect_count",
	"cards_moved_by_effect",
	"affected_count_by_effect",
	"win_slot_count",
	"lose_slot_count",
	"win_attach_sum",
	"lose_attach_sum",
	"win_moves_sum",
	"lose_moves_sum",
	"win_progress_sum",
	"lose_progress_sum",
	"win_captures_sum",
	"lose_captures_sum",
]

func refresh_report(log_dir: String) -> bool:
	var cleaned_log_dir: String = get_clean_log_dir(log_dir)
	ensure_log_dir(cleaned_log_dir)

	var matches: Array[Dictionary] = read_csv_rows(cleaned_log_dir, MATCHES_FILE_NAME)
	if matches.is_empty():
		return false

	var card_events: Array[Dictionary] = read_csv_rows(cleaned_log_dir, CARD_EVENTS_FILE_NAME)
	var move_events: Array[Dictionary] = read_csv_rows(cleaned_log_dir, MOVE_EVENTS_FILE_NAME)
	var effect_events: Array[Dictionary] = read_csv_rows(cleaned_log_dir, EFFECT_EVENTS_FILE_NAME)
	var report_rows: Array[Dictionary] = build_report_rows(matches, card_events, move_events, effect_events)
	if report_rows.is_empty():
		return false

	write_report(cleaned_log_dir, report_rows)
	return true

func refresh_session_balance(log_dir: String, session_id: String) -> bool:
	var cleaned_log_dir: String = get_clean_log_dir(log_dir)
	var cleaned_session_id: String = session_id.strip_edges()
	if cleaned_session_id.is_empty():
		return false

	var matches: Array[Dictionary] = filter_rows_by_session(read_csv_rows(cleaned_log_dir, MATCHES_FILE_NAME), cleaned_session_id)
	if matches.is_empty():
		return false

	var card_events: Array[Dictionary] = filter_rows_by_session(read_csv_rows(cleaned_log_dir, CARD_EVENTS_FILE_NAME), cleaned_session_id)
	var move_events: Array[Dictionary] = filter_rows_by_session(read_csv_rows(cleaned_log_dir, MOVE_EVENTS_FILE_NAME), cleaned_session_id)
	var effect_events: Array[Dictionary] = filter_rows_by_session(read_csv_rows(cleaned_log_dir, EFFECT_EVENTS_FILE_NAME), cleaned_session_id)
	var raw_rows: Array[Dictionary] = build_raw_report_rows(matches, card_events, move_events, effect_events)
	if raw_rows.is_empty():
		return false

	return CardBalanceStore.save_session_balance(cleaned_log_dir, cleaned_session_id, raw_rows, matches.size())

func build_report_rows(
	matches: Array[Dictionary],
	card_events: Array[Dictionary],
	move_events: Array[Dictionary],
	effect_events: Array[Dictionary]
) -> Array[Dictionary]:
	return format_report_rows(build_raw_report_rows(matches, card_events, move_events, effect_events))

func build_raw_report_rows(
	matches: Array[Dictionary],
	card_events: Array[Dictionary],
	move_events: Array[Dictionary],
	effect_events: Array[Dictionary]
) -> Array[Dictionary]:
	var generated_unix: int = int(Time.get_unix_time_from_system())
	var winner_by_match: Dictionary = {}
	var match_ids: Array[String] = []
	var win_condition_counts: Dictionary = count_win_conditions(matches)
	for match_row: Dictionary in matches:
		var match_id: String = str(match_row.get("match_id", ""))
		if match_id.is_empty():
			continue
		match_ids.append(match_id)
		winner_by_match[match_id] = parse_int(match_row.get("winner_player", -1), -1)

	var card_names: Dictionary = {}
	var seen_by_card: Dictionary = {}
	var attach_by_card: Dictionary = {}
	var expire_by_card: Dictionary = {}
	var return_deck_by_card: Dictionary = {}
	var return_hand_by_card: Dictionary = {}
	var attach_by_slot_card: Dictionary = {}
	var seen_by_slot_card: Dictionary = {}

	for event_row: Dictionary in card_events:
		var card_name: String = str(event_row.get("card_name", ""))
		if card_name.is_empty():
			continue
		card_names[card_name] = true
		var event_type: String = str(event_row.get("event_type", ""))
		var slot_key: String = make_slot_key(str(event_row.get("match_id", "")), parse_int(event_row.get("player_id", -1), -1), card_name)
		match event_type:
			"starting_hand", "draw_card":
				increment_count(seen_by_card, card_name)
				increment_count(seen_by_slot_card, slot_key)
			"attach_card":
				increment_count(attach_by_card, card_name)
				increment_count(attach_by_slot_card, slot_key)
			"expire_card":
				increment_count(expire_by_card, card_name)
			"return_to_deck":
				increment_count(return_deck_by_card, card_name)
			"return_to_hand":
				increment_count(return_hand_by_card, card_name)

	var moves_by_card: Dictionary = {}
	var captures_by_card: Dictionary = {}
	var nexus_captures_by_card: Dictionary = {}
	var base_entries_by_card: Dictionary = {}
	var progress_by_card: Dictionary = {}
	var move_wins_by_card: Dictionary = {}
	var move_by_slot_card: Dictionary = {}
	var progress_by_slot_card: Dictionary = {}
	var capture_by_slot_card: Dictionary = {}

	for move_row: Dictionary in move_events:
		var move_card_name: String = str(move_row.get("card_name", ""))
		if move_card_name.is_empty():
			continue
		card_names[move_card_name] = true
		var move_match_id: String = str(move_row.get("match_id", ""))
		var move_player_id: int = parse_int(move_row.get("player_id", -1), -1)
		var move_slot_key: String = make_slot_key(move_match_id, move_player_id, move_card_name)
		var base_progress: float = parse_float(move_row.get("base_progress", 0.0), 0.0)

		increment_count(moves_by_card, move_card_name)
		increment_count(move_by_slot_card, move_slot_key)
		increment_float(progress_by_card, move_card_name, base_progress)
		increment_float(progress_by_slot_card, move_slot_key, base_progress)

		if int(winner_by_match.get(move_match_id, -1)) == move_player_id:
			increment_count(move_wins_by_card, move_card_name)
		if str(move_row.get("was_capture", "")) == "true":
			increment_count(captures_by_card, move_card_name)
			increment_count(capture_by_slot_card, move_slot_key)
		if str(move_row.get("captured_nexus", "")) == "true":
			increment_count(nexus_captures_by_card, move_card_name)
		if str(move_row.get("did_enter_enemy_base", "")) == "true":
			increment_count(base_entries_by_card, move_card_name)

	var effects_by_card: Dictionary = {}
	var base_change_effects_by_card: Dictionary = {}
	var cards_moved_effects_by_card: Dictionary = {}
	var affected_effects_by_card: Dictionary = {}

	for effect_row: Dictionary in effect_events:
		var effect_card_name: String = str(effect_row.get("card_name", ""))
		if effect_card_name.is_empty():
			continue
		card_names[effect_card_name] = true
		increment_count(effects_by_card, effect_card_name)
		var base_before: String = str(effect_row.get("base_before", ""))
		var base_after: String = str(effect_row.get("base_after", ""))
		if !base_before.is_empty() and !base_after.is_empty() and base_before != base_after:
			increment_count(base_change_effects_by_card, effect_card_name)
		increment_count(cards_moved_effects_by_card, effect_card_name, parse_int(effect_row.get("cards_moved", 0), 0))
		increment_count(affected_effects_by_card, effect_card_name, parse_int(effect_row.get("affected_count", 0), 0))

	var raw_rows: Array[Dictionary] = []
	var card_name_list: Array = card_names.keys()
	card_name_list.sort()
	for card_name_value in card_name_list:
		var card_name_string: String = str(card_name_value)
		var association: Dictionary = calculate_card_association(
			card_name_string,
			match_ids,
			winner_by_match,
			attach_by_slot_card,
			move_by_slot_card,
			progress_by_slot_card,
			capture_by_slot_card
		)
		var move_count: int = int(moves_by_card.get(card_name_string, 0))
		var seen_count: int = int(seen_by_card.get(card_name_string, 0))
		var attach_count: int = int(attach_by_card.get(card_name_string, 0))
		var capture_count: int = int(captures_by_card.get(card_name_string, 0))
		var move_win_count: int = int(move_wins_by_card.get(card_name_string, 0))
		var progress_sum: float = float(progress_by_card.get(card_name_string, 0.0))
		raw_rows.append({
			"card_name": card_name_string,
			"seen_count": seen_count,
			"attach_count": attach_count,
			"attach_rate": safe_div(float(attach_count), float(seen_count)),
			"move_count": move_count,
			"move_win_count": move_win_count,
			"move_win_rate": safe_div(float(move_win_count), float(move_count)),
			"capture_count": capture_count,
			"capture_rate": safe_div(float(capture_count), float(move_count)),
			"nexus_capture_count": int(nexus_captures_by_card.get(card_name_string, 0)),
			"base_entry_count": int(base_entries_by_card.get(card_name_string, 0)),
			"progress_sum": progress_sum,
			"avg_progress_per_move": safe_div(progress_sum, float(move_count)),
			"delta_attach_per_player_match": float(association.get("delta_attach_per_player_match", 0.0)),
			"delta_moves_per_player_match": float(association.get("delta_moves_per_player_match", 0.0)),
			"delta_progress_per_player_match": float(association.get("delta_progress_per_player_match", 0.0)),
			"delta_captures_per_player_match": float(association.get("delta_captures_per_player_match", 0.0)),
			"win_slot_count": int(association.get("win_slot_count", 0)),
			"lose_slot_count": int(association.get("lose_slot_count", 0)),
			"win_attach_sum": float(association.get("win_attach_sum", 0.0)),
			"lose_attach_sum": float(association.get("lose_attach_sum", 0.0)),
			"win_moves_sum": float(association.get("win_moves_sum", 0.0)),
			"lose_moves_sum": float(association.get("lose_moves_sum", 0.0)),
			"win_progress_sum": float(association.get("win_progress_sum", 0.0)),
			"lose_progress_sum": float(association.get("lose_progress_sum", 0.0)),
			"win_captures_sum": float(association.get("win_captures_sum", 0.0)),
			"lose_captures_sum": float(association.get("lose_captures_sum", 0.0)),
			"expire_count": int(expire_by_card.get(card_name_string, 0)),
			"return_deck_count": int(return_deck_by_card.get(card_name_string, 0)),
			"return_hand_count": int(return_hand_by_card.get(card_name_string, 0)),
			"effect_trigger_count": int(effects_by_card.get(card_name_string, 0)),
			"base_change_effect_count": int(base_change_effects_by_card.get(card_name_string, 0)),
			"cards_moved_by_effect": int(cards_moved_effects_by_card.get(card_name_string, 0)),
			"affected_count_by_effect": int(affected_effects_by_card.get(card_name_string, 0)),
			"generated_unix": generated_unix,
			"matches_analyzed": match_ids.size(),
			"base_reached_match_count": int(win_condition_counts.get("base_reached", 0)),
			"no_valid_move_match_count": int(win_condition_counts.get("no_valid_move", 0)),
			"nexus_card_lost_match_count": int(win_condition_counts.get("nexus_card_lost", 0)),
			"unknown_win_condition_match_count": int(win_condition_counts.get("unknown", 0)),
		})

	add_card_values(raw_rows)
	raw_rows.sort_custom(Callable(self, "sort_report_rows_desc"))
	return raw_rows

func count_win_conditions(matches: Array[Dictionary]) -> Dictionary:
	var counts: Dictionary = {
		"base_reached": 0,
		"no_valid_move": 0,
		"nexus_card_lost": 0,
		"unknown": 0,
	}
	for match_row: Dictionary in matches:
		var win_condition: String = str(match_row.get("win_condition", "")).strip_edges()
		if win_condition.is_empty() or !counts.has(win_condition):
			win_condition = "unknown"
		counts[win_condition] = int(counts.get(win_condition, 0)) + 1
	return counts

func calculate_card_association(
	card_name: String,
	match_ids: Array[String],
	winner_by_match: Dictionary,
	attach_by_slot_card: Dictionary,
	move_by_slot_card: Dictionary,
	progress_by_slot_card: Dictionary,
	capture_by_slot_card: Dictionary
) -> Dictionary:
	var win_count: int = 0
	var lose_count: int = 0
	var win_attach: float = 0.0
	var lose_attach: float = 0.0
	var win_moves: float = 0.0
	var lose_moves: float = 0.0
	var win_progress: float = 0.0
	var lose_progress: float = 0.0
	var win_captures: float = 0.0
	var lose_captures: float = 0.0

	for match_id: String in match_ids:
		for player_id in [0, 1]:
			var key: String = make_slot_key(match_id, player_id, card_name)
			if int(winner_by_match.get(match_id, -1)) == player_id:
				win_count += 1
				win_attach += float(attach_by_slot_card.get(key, 0))
				win_moves += float(move_by_slot_card.get(key, 0))
				win_progress += float(progress_by_slot_card.get(key, 0.0))
				win_captures += float(capture_by_slot_card.get(key, 0))
			else:
				lose_count += 1
				lose_attach += float(attach_by_slot_card.get(key, 0))
				lose_moves += float(move_by_slot_card.get(key, 0))
				lose_progress += float(progress_by_slot_card.get(key, 0.0))
				lose_captures += float(capture_by_slot_card.get(key, 0))

	return {
		"delta_attach_per_player_match": safe_div(win_attach, float(win_count)) - safe_div(lose_attach, float(lose_count)),
		"delta_moves_per_player_match": safe_div(win_moves, float(win_count)) - safe_div(lose_moves, float(lose_count)),
		"delta_progress_per_player_match": safe_div(win_progress, float(win_count)) - safe_div(lose_progress, float(lose_count)),
		"delta_captures_per_player_match": safe_div(win_captures, float(win_count)) - safe_div(lose_captures, float(lose_count)),
		"win_slot_count": win_count,
		"lose_slot_count": lose_count,
		"win_attach_sum": win_attach,
		"lose_attach_sum": lose_attach,
		"win_moves_sum": win_moves,
		"lose_moves_sum": lose_moves,
		"win_progress_sum": win_progress,
		"lose_progress_sum": lose_progress,
		"win_captures_sum": win_captures,
		"lose_captures_sum": lose_captures,
	}

func add_card_values(rows: Array[Dictionary]) -> void:
	var progress_values: Array[float] = collect_float_values(rows, "avg_progress_per_move")
	var capture_values: Array[float] = collect_float_values(rows, "capture_rate")
	var nexus_capture_values: Array[float] = collect_float_values(rows, "nexus_capture_count")
	var base_entry_values: Array[float] = collect_float_values(rows, "base_entry_count")
	var win_delta_values: Array[float] = collect_float_values(rows, "delta_progress_per_player_match")
	var move_count_values: Array[float] = collect_float_values(rows, "move_count")
	var max_move_count: float = max_float_value(move_count_values, 1.0)

	for row: Dictionary in rows:
		var progress_component: float = minmax_value(float(row.get("avg_progress_per_move", 0.0)), progress_values)
		var capture_component: float = minmax_value(float(row.get("capture_rate", 0.0)), capture_values)
		var nexus_pressure_component: float = (
			0.55 * minmax_value(float(row.get("nexus_capture_count", 0.0)), nexus_capture_values)
			+ 0.45 * minmax_value(float(row.get("base_entry_count", 0.0)), base_entry_values)
		)
		var win_association_component: float = minmax_value(float(row.get("delta_progress_per_player_match", 0.0)), win_delta_values)
		var usage_confidence: float = sqrt(maxf(float(row.get("move_count", 0.0)), 0.0)) / sqrt(maxf(max_move_count, 1.0))
		var raw_score: float = 100.0 * (
			0.38 * progress_component
			+ 0.22 * capture_component
			+ 0.20 * nexus_pressure_component
			+ 0.20 * win_association_component
		)
		var trend_score: float = 50.0 + (raw_score - 50.0) * usage_confidence
		var ai_score_adjustment: float = clampf((trend_score - 50.0) * 2.0, -30.0, 30.0)
		var ai_attach_score_adjustment: float = clampf((trend_score - 50.0) * 0.8, -12.0, 12.0)
		row["sample_confidence"] = usage_confidence
		row["trend_score"] = trend_score
		row["card_value"] = ai_score_adjustment
		row["ai_score_adjustment"] = ai_score_adjustment
		row["ai_attach_score_adjustment"] = ai_attach_score_adjustment
		row["ai_value_multiplier"] = clampf(1.0 + ai_score_adjustment / 100.0, 0.70, 1.30)

func format_report_rows(rows: Array[Dictionary]) -> Array[Dictionary]:
	var formatted_rows: Array[Dictionary] = []
	for row: Dictionary in rows:
		var formatted_row: Dictionary = {}
		for header: String in REPORT_HEADERS:
			var value = row.get(header, "")
			if value is float:
				formatted_row[header] = format_float(float(value))
			else:
				formatted_row[header] = value
		formatted_rows.append(formatted_row)
	return formatted_rows

func sort_report_rows_desc(left: Dictionary, right: Dictionary) -> bool:
	return float(left.get("card_value", 0.0)) > float(right.get("card_value", 0.0))

func collect_float_values(rows: Array[Dictionary], key: String) -> Array[float]:
	var values: Array[float] = []
	for row: Dictionary in rows:
		values.append(float(row.get(key, 0.0)))
	return values

func minmax_value(value: float, values: Array[float]) -> float:
	if values.is_empty():
		return 0.5

	var min_value: float = values[0]
	var max_value: float = values[0]
	for current_value: float in values:
		min_value = minf(min_value, current_value)
		max_value = maxf(max_value, current_value)

	if is_equal_approx(min_value, max_value):
		return 0.5
	return (value - min_value) / (max_value - min_value)

func max_float_value(values: Array[float], fallback: float) -> float:
	if values.is_empty():
		return fallback
	var output: float = values[0]
	for value: float in values:
		output = maxf(output, value)
	return output

func safe_div(numerator: float, denominator: float) -> float:
	if is_zero_approx(denominator):
		return 0.0
	return numerator / denominator

func read_csv_rows(log_dir: String, file_name: String) -> Array[Dictionary]:
	var path: String = get_log_file_path(log_dir, file_name)
	if !FileAccess.file_exists(path):
		return []

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Could not read CSV file for card balance report: %s" % path)
		return []

	var header_values: PackedStringArray = file.get_csv_line()
	var headers: Array[String] = []
	for header_value in header_values:
		headers.append(str(header_value))

	var rows: Array[Dictionary] = []
	while !file.eof_reached():
		var values: PackedStringArray = file.get_csv_line()
		if is_empty_csv_line(values):
			continue

		var row: Dictionary = {}
		for index in range(headers.size()):
			row[headers[index]] = str(values[index]) if index < values.size() else ""
		rows.append(row)

	file.close()
	return rows

func filter_rows_by_session(rows: Array[Dictionary], session_id: String) -> Array[Dictionary]:
	var filtered_rows: Array[Dictionary] = []
	for row: Dictionary in rows:
		if str(row.get("session_id", "")) == session_id:
			filtered_rows.append(row)
	return filtered_rows

func is_empty_csv_line(values: PackedStringArray) -> bool:
	if values.is_empty():
		return true
	return values.size() == 1 and str(values[0]).is_empty()

func write_report(log_dir: String, rows: Array[Dictionary]) -> void:
	var path: String = get_log_file_path(log_dir, REPORT_FILE_NAME)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write card balance report: %s" % path)
		return

	file.store_line(csv_line(REPORT_HEADERS))
	for row: Dictionary in rows:
		var values: Array = []
		for header: String in REPORT_HEADERS:
			values.append(row.get(header, ""))
		file.store_line(csv_line(values))
	file.close()

func csv_line(values: Array) -> String:
	var escaped_values: Array[String] = []
	for value in values:
		escaped_values.append(csv_escape(value))
	return ",".join(escaped_values)

func csv_escape(value) -> String:
	var text: String = str(value)
	var must_quote: bool = text.contains(",") or text.contains("\"") or text.contains("\n") or text.contains("\r")
	text = text.replace("\"", "\"\"")
	if must_quote:
		return "\"%s\"" % text
	return text

func increment_count(target: Dictionary, key: String, amount: int = 1) -> void:
	target[key] = int(target.get(key, 0)) + amount

func increment_float(target: Dictionary, key: String, amount: float) -> void:
	target[key] = float(target.get(key, 0.0)) + amount

func make_slot_key(match_id: String, player_id: int, card_name: String) -> String:
	return "%s|%d|%s" % [match_id, player_id, card_name]

func parse_int(value, fallback: int = 0) -> int:
	if value is int:
		return int(value)
	if value is float:
		return int(value)
	var text: String = str(value).strip_edges()
	return int(text) if text.is_valid_int() else fallback

func parse_float(value, fallback: float = 0.0) -> float:
	if value is float or value is int:
		return float(value)
	var text: String = str(value).strip_edges()
	return float(text) if text.is_valid_float() else fallback

func format_float(value: float) -> String:
	return "%.4f" % value

func ensure_log_dir(log_dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(get_absolute_log_dir(log_dir))

func get_log_file_path(log_dir: String, file_name: String) -> String:
	return "%s/%s" % [get_clean_log_dir(log_dir).trim_suffix("/"), file_name]

func get_clean_log_dir(log_dir: String) -> String:
	var cleaned_log_dir: String = log_dir.strip_edges()
	if cleaned_log_dir.is_empty():
		cleaned_log_dir = DEFAULT_LOG_DIR
	return cleaned_log_dir.replace("\\", "/")

func get_absolute_log_dir(log_dir: String) -> String:
	var cleaned_log_dir: String = get_clean_log_dir(log_dir)
	if cleaned_log_dir.begins_with("user://") or cleaned_log_dir.begins_with("res://"):
		return ProjectSettings.globalize_path(cleaned_log_dir)
	return cleaned_log_dir
