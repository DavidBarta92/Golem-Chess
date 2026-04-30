extends Node

const CONTROLLER_HUMAN: String = "human"
const CONTROLLER_AI: String = "ai"
const AI_DIFFICULTY_EASY: String = "easy"
const AI_DIFFICULTY_NORMAL: String = "normal"
const AI_DIFFICULTY_HARD: String = "hard"
const DEFAULT_AI_VS_AI_CSV_LOG_DIR: String = "user://ai_match_logs"

var is_singleplayer: bool = false
var is_hosting: bool = false
var is_ai_vs_ai_batch: bool = false
var server_ip: String = "127.0.0.1"
var server_port: int = 9999
var ai_vs_ai_match_count: int = 1
var ai_vs_ai_matches_played: int = 0
var ai_vs_ai_log_session_id: String = ""
var ai_vs_ai_csv_log_dir: String = DEFAULT_AI_VS_AI_CSV_LOG_DIR
var ai_vs_ai_results: Dictionary = {
	0: 0,
	1: 0,
}
var player_controllers: Dictionary = {
	0: CONTROLLER_HUMAN,
	1: CONTROLLER_HUMAN,
}
var player_ai_difficulties: Dictionary = {
	0: AI_DIFFICULTY_NORMAL,
	1: AI_DIFFICULTY_NORMAL,
}

func set_player_controller(player_id: int, controller_type: String) -> void:
	player_controllers[player_id] = controller_type

func get_player_controller(player_id: int) -> String:
	return str(player_controllers.get(player_id, CONTROLLER_HUMAN))

func set_player_ai_difficulty(player_id: int, difficulty: String) -> void:
	player_ai_difficulties[player_id] = difficulty

func get_player_ai_difficulty(player_id: int) -> String:
	return str(player_ai_difficulties.get(player_id, AI_DIFFICULTY_NORMAL))

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
