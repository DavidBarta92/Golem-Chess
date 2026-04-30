extends RefCounted
class_name AIPerformanceCsvLogger

const DEFAULT_LOG_DIR: String = "user://ai_match_logs"
const FILE_NAME: String = "ai_performance.csv"
const HEADERS: Array = [
	"session_id", "match_id", "batch_index", "batch_total", "logged_unix", "logged_msec",
	"turn_index", "current_player", "player_id", "controller_type", "ai_difficulty",
	"difficulty_level", "search_depth", "own_top_n", "opponent_top_n", "randomness",
	"opponent_response_weight", "own_turn_plan_count", "own_response_candidate_count",
	"own_response_pruned_plan_count", "evaluated_own_plans", "opponent_response_branch_count",
	"opponent_response_plan_count", "opponent_response_selected_plan_count", "opponent_response_pruned_plan_count",
	"evaluated_response_plans",
	"choose_best_turn_plan_ms", "planner_ms", "own_planner_ms", "opponent_planner_ms",
	"evaluator_ms", "simulator_ms",
	"best_plan_score", "best_plan_type", "best_plan_actions", "selected_action_count",
	"white_hand_count", "black_hand_count", "white_deck_count", "black_deck_count",
	"white_piece_count", "black_piece_count", "board_effect_count"
]

static func log_decision(game_state: GameStateData, player_id: int, profile: Dictionary, selected_plan: Dictionary) -> void:
	if game_state == null:
		return

	ensure_log_dir()
	var own_planner_ms: float = float(profile.get("own_planner_ms", 0.0))
	var opponent_planner_ms: float = float(profile.get("opponent_planner_ms", 0.0))
	var row: Dictionary = {
		"session_id": get_session_id(game_state),
		"match_id": get_match_id(game_state),
		"batch_index": GameConfig.ai_vs_ai_matches_played + 1,
		"batch_total": GameConfig.ai_vs_ai_match_count,
		"logged_unix": int(Time.get_unix_time_from_system()),
		"logged_msec": Time.get_ticks_msec(),
		"turn_index": get_turn_index(game_state),
		"current_player": game_state.current_turn_player,
		"player_id": player_id,
		"controller_type": GameConfig.get_player_controller(player_id),
		"ai_difficulty": GameConfig.get_player_ai_difficulty(player_id),
		"difficulty_level": int(profile.get("difficulty_level", 0)),
		"search_depth": int(profile.get("search_depth", 1)),
		"own_top_n": int(profile.get("own_top_n", 0)),
		"opponent_top_n": int(profile.get("opponent_top_n", 0)),
		"randomness": float(profile.get("randomness", 0.0)),
		"opponent_response_weight": float(profile.get("opponent_response_weight", 0.0)),
		"own_turn_plan_count": int(profile.get("own_turn_plan_count", 0)),
		"own_response_candidate_count": int(profile.get("own_response_candidate_count", 0)),
		"own_response_pruned_plan_count": int(profile.get("own_response_pruned_plan_count", 0)),
		"evaluated_own_plans": int(profile.get("evaluated_own_plans", 0)),
		"opponent_response_branch_count": int(profile.get("opponent_response_branch_count", 0)),
		"opponent_response_plan_count": int(profile.get("opponent_response_plan_count", 0)),
		"opponent_response_selected_plan_count": int(profile.get("opponent_response_selected_plan_count", 0)),
		"opponent_response_pruned_plan_count": int(profile.get("opponent_response_pruned_plan_count", 0)),
		"evaluated_response_plans": int(profile.get("evaluated_response_plans", 0)),
		"choose_best_turn_plan_ms": format_float(float(profile.get("choose_best_turn_plan_ms", 0.0))),
		"planner_ms": format_float(own_planner_ms + opponent_planner_ms),
		"own_planner_ms": format_float(own_planner_ms),
		"opponent_planner_ms": format_float(opponent_planner_ms),
		"evaluator_ms": format_float(float(profile.get("evaluator_ms", 0.0))),
		"simulator_ms": format_float(float(profile.get("simulator_ms", 0.0))),
		"best_plan_score": format_float(float(profile.get("best_plan_score", 0.0))),
		"best_plan_type": str(profile.get("best_plan_type", selected_plan.get("plan_type", ""))),
		"best_plan_actions": summarize_plan_actions(selected_plan),
		"selected_action_count": get_plan_action_count(selected_plan),
		"white_hand_count": get_hand_count(game_state, 0),
		"black_hand_count": get_hand_count(game_state, 1),
		"white_deck_count": get_deck_count(game_state, 0),
		"black_deck_count": get_deck_count(game_state, 1),
		"white_piece_count": count_pieces(game_state, 0),
		"black_piece_count": count_pieces(game_state, 1),
		"board_effect_count": game_state.board_effects.size(),
	}
	append_row(FILE_NAME, HEADERS, row)

static func append_row(file_name: String, headers: Array, row: Dictionary) -> void:
	var path: String = get_log_file_path(file_name)
	var file_exists: bool = FileAccess.file_exists(path)
	var needs_header: bool = !file_exists
	var header_changed: bool = file_exists && !has_matching_header(path, headers)
	var file: FileAccess = null
	if !file_exists:
		file = FileAccess.open(path, FileAccess.WRITE)
	else:
		file = FileAccess.open(path, FileAccess.READ_WRITE)

	if file == null:
		push_warning("Could not open AI performance CSV log file: %s" % path)
		return

	if needs_header:
		file.store_line(csv_line(headers))
	else:
		file.seek_end()
		if header_changed:
			file.store_line(csv_line(headers))

	var values: Array = []
	for header_value in headers:
		var header: String = str(header_value)
		values.append(row.get(header, ""))
	file.store_line(csv_line(values))
	file.close()

static func has_matching_header(path: String, headers: Array) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false

	var first_line: String = file.get_line()
	file.close()
	return first_line == csv_line(headers)

static func csv_line(values: Array) -> String:
	var escaped_values: Array[String] = []
	for value in values:
		escaped_values.append(csv_escape(value))
	return ",".join(escaped_values)

static func csv_escape(value) -> String:
	var text: String = stringify_value(value)
	var must_quote: bool = text.contains(",") or text.contains("\"") or text.contains("\n") or text.contains("\r")
	text = text.replace("\"", "\"\"")
	if must_quote:
		return "\"%s\"" % text
	return text

static func stringify_value(value) -> String:
	if value == null:
		return ""
	if value is Array or value is Dictionary:
		return JSON.stringify(normalize_value(value))
	if value is Vector2:
		var vector_value: Vector2 = value
		return "%d:%d" % [int(vector_value.x), int(vector_value.y)]
	if value is bool:
		return "true" if bool(value) else "false"
	return str(value)

static func normalize_value(value):
	if value is Vector2:
		var vector_value: Vector2 = value
		return [vector_value.x, vector_value.y]
	if value is Card:
		var card: Card = value
		return card.card_name
	if value is Array:
		var source_array: Array = value
		var output_array: Array = []
		for item in source_array:
			output_array.append(normalize_value(item))
		return output_array
	if value is Dictionary:
		var source_dict: Dictionary = value
		var output_dict: Dictionary = {}
		for key in source_dict:
			if str(key) == "card":
				continue
			output_dict[str(key)] = normalize_value(source_dict[key])
		return output_dict
	return value

static func summarize_plan_actions(plan: Dictionary) -> Array:
	var summaries: Array = []
	var actions: Array = plan.get("actions", [])
	for action_value in actions:
		var action: Dictionary = action_value
		summaries.append({
			"type": str(action.get("type", "")),
			"card_name": str(action.get("card_name", "")),
			"piece_pos": action.get("piece_pos", ""),
			"from": action.get("from", ""),
			"to": action.get("to", ""),
		})
	return summaries

static func get_plan_action_count(plan: Dictionary) -> int:
	var actions: Array = plan.get("actions", [])
	return actions.size()

static func get_session_id(game_state: GameStateData) -> String:
	if game_state.match_logger != null and !game_state.match_logger.session_id.is_empty():
		return game_state.match_logger.session_id
	if GameConfig.ai_vs_ai_log_session_id.is_empty():
		var datetime: String = Time.get_datetime_string_from_system(false, true)
		datetime = datetime.replace(":", "-").replace(" ", "_")
		GameConfig.ai_vs_ai_log_session_id = "%s_%d" % [datetime, randi() % 100000]
	return GameConfig.ai_vs_ai_log_session_id

static func get_match_id(game_state: GameStateData) -> String:
	if game_state.match_logger != null and !game_state.match_logger.match_id.is_empty():
		return game_state.match_logger.match_id
	return "%s_match_live" % get_session_id(game_state)

static func get_turn_index(game_state: GameStateData) -> int:
	if game_state.match_logger != null:
		return game_state.match_logger.turn_index
	return -1

static func ensure_log_dir() -> void:
	DirAccess.make_dir_recursive_absolute(get_absolute_log_dir())

static func get_log_file_path(file_name: String) -> String:
	return "%s/%s" % [get_log_dir().trim_suffix("/"), file_name]

static func get_log_dir() -> String:
	var log_dir: String = GameConfig.get_ai_vs_ai_csv_log_dir()
	if log_dir.strip_edges().is_empty():
		return DEFAULT_LOG_DIR
	return log_dir.strip_edges().replace("\\", "/")

static func get_absolute_log_dir() -> String:
	var log_dir: String = get_log_dir()
	if log_dir.begins_with("user://") or log_dir.begins_with("res://"):
		return ProjectSettings.globalize_path(log_dir)
	return log_dir

static func get_hand_count(game_state: GameStateData, player_id: int) -> int:
	var hand: Array = game_state.player_hands.get(player_id, [])
	return hand.size()

static func get_deck_count(game_state: GameStateData, player_id: int) -> int:
	var deck: Array = game_state.player_decks.get(player_id, [])
	return deck.size()

static func count_pieces(game_state: GameStateData, player_id: int) -> int:
	var expected_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	var count: int = 0
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null and piece.color == expected_color:
			count += 1
	return count

static func format_float(value: float) -> String:
	return "%.3f" % value
