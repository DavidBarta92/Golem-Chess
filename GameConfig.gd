extends Node

const CONTROLLER_HUMAN: String = "human"
const CONTROLLER_AI: String = "ai"
const MIN_AI_DIFFICULTY_LEVEL: int = 1
const MAX_AI_DIFFICULTY_LEVEL: int = 12
const DEFAULT_AI_DIFFICULTY_LEVEL: int = 12
const DEFAULT_AI_VS_AI_CSV_LOG_DIR: String = "user://ai_match_logs"
const DEFAULT_PLAYER_NAME: String = "Player"
const MAX_PLAYER_NAME_LENGTH: int = 24

var is_singleplayer: bool = false
var is_hosting: bool = false
var is_ai_vs_ai_batch: bool = false
var server_ip: String = "127.0.0.1"
var server_port: int = 9999
var player_name: String = DEFAULT_PLAYER_NAME
var ai_vs_ai_match_count: int = 1
var ai_vs_ai_matches_played: int = 0
var ai_vs_ai_log_session_id: String = ""
var ai_vs_ai_csv_log_dir: String = DEFAULT_AI_VS_AI_CSV_LOG_DIR
var selected_deck_id: String = ""
var selected_ai_deck_id: String = ""
var ai_vs_ai_results: Dictionary = {
	0: 0,
	1: 0,
}
var player_controllers: Dictionary = {
	0: CONTROLLER_HUMAN,
	1: CONTROLLER_HUMAN,
}
var player_ai_difficulty_levels: Dictionary = {
	0: DEFAULT_AI_DIFFICULTY_LEVEL,
	1: DEFAULT_AI_DIFFICULTY_LEVEL,
}

func set_player_controller(player_id: int, controller_type: String) -> void:
	player_controllers[player_id] = controller_type

func get_player_controller(player_id: int) -> String:
	return str(player_controllers.get(player_id, CONTROLLER_HUMAN))

func set_player_ai_difficulty_level(player_id: int, difficulty_level) -> void:
	player_ai_difficulty_levels[player_id] = clamp_ai_difficulty_level(difficulty_level)

func get_player_ai_difficulty_level(player_id: int) -> int:
	return clamp_ai_difficulty_level(player_ai_difficulty_levels.get(player_id, DEFAULT_AI_DIFFICULTY_LEVEL))

func set_player_ai_difficulty(player_id: int, difficulty_level) -> void:
	set_player_ai_difficulty_level(player_id, difficulty_level)

func get_player_ai_difficulty(player_id: int) -> int:
	return get_player_ai_difficulty_level(player_id)

func clamp_ai_difficulty_level(raw_level) -> int:
	var level: int = DEFAULT_AI_DIFFICULTY_LEVEL
	if raw_level is int:
		level = int(raw_level)
	elif raw_level is float:
		level = int(raw_level)
	elif raw_level is String:
		var cleaned_level: String = str(raw_level).strip_edges()
		if cleaned_level.is_valid_int():
			level = int(cleaned_level)
	return clampi(level, MIN_AI_DIFFICULTY_LEVEL, MAX_AI_DIFFICULTY_LEVEL)

func set_local_player_name(new_player_name: String) -> void:
	player_name = sanitize_player_name(new_player_name)

func get_local_player_name() -> String:
	return sanitize_player_name(player_name)

func sanitize_player_name(raw_player_name: String) -> String:
	var cleaned_name: String = raw_player_name.strip_edges()
	if cleaned_name.is_empty():
		return DEFAULT_PLAYER_NAME
	if cleaned_name.length() > MAX_PLAYER_NAME_LENGTH:
		cleaned_name = cleaned_name.substr(0, MAX_PLAYER_NAME_LENGTH)
	return cleaned_name

func set_singleplayer_controllers(player_0_controller: String = CONTROLLER_HUMAN, player_1_controller: String = CONTROLLER_AI) -> void:
	set_player_controller(0, player_0_controller)
	set_player_controller(1, player_1_controller)

func start_ai_vs_ai_batch(match_count: int) -> void:
	is_ai_vs_ai_batch = true
	ai_vs_ai_match_count = max(1, match_count)
	ai_vs_ai_matches_played = 0
	ai_vs_ai_log_session_id = ""
	ai_vs_ai_results = {
		0: 0,
		1: 0,
	}
	set_singleplayer_controllers(CONTROLLER_AI, CONTROLLER_AI)

func set_ai_vs_ai_csv_log_dir(log_dir: String) -> void:
	var cleaned_log_dir: String = log_dir.strip_edges()
	if cleaned_log_dir.is_empty():
		ai_vs_ai_csv_log_dir = DEFAULT_AI_VS_AI_CSV_LOG_DIR
		return

	ai_vs_ai_csv_log_dir = cleaned_log_dir.replace("\\", "/")

func get_ai_vs_ai_csv_log_dir() -> String:
	if ai_vs_ai_csv_log_dir.strip_edges().is_empty():
		return DEFAULT_AI_VS_AI_CSV_LOG_DIR
	return ai_vs_ai_csv_log_dir

func set_selected_deck_id(deck_id: String) -> void:
	selected_deck_id = deck_id.strip_edges()

func get_selected_deck_id() -> String:
	if selected_deck_id.strip_edges().is_empty() or !PlayerDeckStore.is_deck_playable_id(selected_deck_id):
		select_first_available_deck()
	return selected_deck_id

func select_first_available_deck() -> void:
	var first_deck: Dictionary = PlayerDeckStore.get_first_playable_deck()
	selected_deck_id = str(first_deck.get("deck_id", ""))

func has_selected_deck() -> bool:
	return !get_selected_deck_id().is_empty()

func get_selected_deck_card_names() -> Array[String]:
	var deck_id: String = get_selected_deck_id()
	if deck_id.is_empty():
		var empty_card_names: Array[String] = []
		return empty_card_names
	return PlayerDeckStore.get_deck_card_names(deck_id)

func set_selected_ai_deck_id(deck_id: String) -> void:
	selected_ai_deck_id = deck_id.strip_edges()

func get_selected_ai_deck_id() -> String:
	if selected_ai_deck_id.strip_edges().is_empty() or !PlayerDeckStore.is_deck_playable_id(selected_ai_deck_id):
		select_first_available_ai_deck()
	return selected_ai_deck_id

func select_first_available_ai_deck() -> void:
	var first_deck: Dictionary = PlayerDeckStore.get_first_playable_deck()
	selected_ai_deck_id = str(first_deck.get("deck_id", ""))

func get_selected_ai_deck_card_names() -> Array[String]:
	var deck_id: String = get_selected_ai_deck_id()
	if deck_id.is_empty():
		var empty_card_names: Array[String] = []
		return empty_card_names
	return PlayerDeckStore.get_deck_card_names(deck_id)

func record_ai_vs_ai_result(winner_player_id: int) -> void:
	if !is_ai_vs_ai_batch:
		return

	ai_vs_ai_matches_played += 1
	var current_wins: int = int(ai_vs_ai_results.get(winner_player_id, 0))
	ai_vs_ai_results[winner_player_id] = current_wins + 1

func should_continue_ai_vs_ai_batch() -> bool:
	return is_ai_vs_ai_batch && ai_vs_ai_matches_played < ai_vs_ai_match_count

func stop_ai_vs_ai_batch() -> void:
	is_ai_vs_ai_batch = false

func reset_multiplayer_controllers() -> void:
	set_player_controller(0, CONTROLLER_HUMAN)
	set_player_controller(1, CONTROLLER_HUMAN)
