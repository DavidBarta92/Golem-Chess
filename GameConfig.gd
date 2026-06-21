extends Node

const CONTROLLER_HUMAN: String = "human"
const CONTROLLER_AI: String = "ai"
const CONTROLLER_CODEX: String = "codex"
const MIN_AI_DIFFICULTY_LEVEL: int = 1
const MAX_AI_DIFFICULTY_LEVEL: int = 12
const DEFAULT_AI_DIFFICULTY_LEVEL: int = 12
const DEFAULT_AI_VS_AI_CSV_LOG_DIR: String = "user://ai_match_logs"
const DEFAULT_SERVER_IP: String = "79.76.116.120"
const DEFAULT_SERVER_PORT: int = 9999
const MULTIPLAYER_PROVIDER_CUSTOM_SERVER: String = "custom_server"
const MULTIPLAYER_PROVIDER_STEAM: String = "steam"
const MATCHMAKING_MODE_DIRECT_CONNECT: String = "direct_connect"
const MATCHMAKING_MODE_ROOM_LIST: String = "room_list"
const MATCHMAKING_MODE_FRIEND_INVITE: String = "friend_invite"
const MATCHMAKING_MODE_QUICK_MATCH: String = "quick_match"
const RESPAWN_COOLDOWN_OWN_TURNS: int = 1
const DEFAULT_PLAYER_NAME: String = "Player"
const MAX_PLAYER_NAME_LENGTH: int = 24

var is_singleplayer: bool = false
var is_hosting: bool = false
var is_dedicated_server: bool = false
var is_ai_vs_ai_batch: bool = false
var server_ip: String = DEFAULT_SERVER_IP
var server_port: int = DEFAULT_SERVER_PORT
var multiplayer_provider: String = MULTIPLAYER_PROVIDER_CUSTOM_SERVER
var matchmaking_mode: String = MATCHMAKING_MODE_DIRECT_CONNECT
var selected_lobby_id: String = ""
var player_name: String = DEFAULT_PLAYER_NAME
var local_portrait_data: Dictionary = {}
var ai_vs_ai_match_count: int = 1
var ai_vs_ai_matches_played: int = 0
var ai_vs_ai_log_session_id: String = ""
var ai_vs_ai_csv_log_dir: String = DEFAULT_AI_VS_AI_CSV_LOG_DIR
var ai_vs_ai_fast_mode: bool = false
var ai_vs_ai_use_random_database_decks: bool = false
var selected_deck_id: String = ""
var selected_ai_deck_id: String = ""
var multiplayer_menu_status_message: String = ""
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

func set_local_portrait_data(portrait_data: Dictionary) -> void:
	local_portrait_data = PortraitLibrary.config_from_data_or_default(portrait_data, 0).to_dict()

func get_local_portrait_data() -> Dictionary:
	if local_portrait_data.is_empty():
		local_portrait_data = PortraitLibrary.get_default_player_portrait().to_dict()
	return local_portrait_data.duplicate(true)

func get_ai_portrait_data(player_id: int) -> Dictionary:
	return PortraitLibrary.create_ai_portrait(player_id, get_player_ai_difficulty_level(player_id)).to_dict()

func sanitize_player_name(raw_player_name: String) -> String:
	var cleaned_name: String = raw_player_name.strip_edges()
	if cleaned_name.is_empty():
		return DEFAULT_PLAYER_NAME
	if cleaned_name.length() > MAX_PLAYER_NAME_LENGTH:
		cleaned_name = cleaned_name.substr(0, MAX_PLAYER_NAME_LENGTH)
	return cleaned_name

func set_server_port(raw_port) -> void:
	server_port = parse_server_port(raw_port)

func use_default_public_server_endpoint() -> void:
	server_ip = DEFAULT_SERVER_IP
	server_port = DEFAULT_SERVER_PORT

func set_multiplayer_provider(provider: String) -> void:
	match provider:
		MULTIPLAYER_PROVIDER_CUSTOM_SERVER, MULTIPLAYER_PROVIDER_STEAM:
			multiplayer_provider = provider
		_:
			multiplayer_provider = MULTIPLAYER_PROVIDER_CUSTOM_SERVER

func is_using_custom_server_multiplayer() -> bool:
	return multiplayer_provider == MULTIPLAYER_PROVIDER_CUSTOM_SERVER

func is_using_steam_multiplayer() -> bool:
	return multiplayer_provider == MULTIPLAYER_PROVIDER_STEAM

func set_matchmaking_mode(mode: String) -> void:
	match mode:
		MATCHMAKING_MODE_DIRECT_CONNECT, MATCHMAKING_MODE_ROOM_LIST, MATCHMAKING_MODE_FRIEND_INVITE, MATCHMAKING_MODE_QUICK_MATCH:
			matchmaking_mode = mode
		_:
			matchmaking_mode = MATCHMAKING_MODE_DIRECT_CONNECT

func set_multiplayer_menu_status_message(message: String) -> void:
	multiplayer_menu_status_message = message.strip_edges()

func consume_multiplayer_menu_status_message() -> String:
	var message: String = multiplayer_menu_status_message
	multiplayer_menu_status_message = ""
	return message

func parse_server_port(raw_port) -> int:
	var parsed_port: int = DEFAULT_SERVER_PORT
	if raw_port is int:
		parsed_port = int(raw_port)
	elif raw_port is float:
		parsed_port = int(raw_port)
	else:
		var cleaned_port: String = str(raw_port).strip_edges()
		if cleaned_port.is_valid_int():
			parsed_port = int(cleaned_port)
	return clampi(parsed_port, 1, 65535)

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
	ensure_selected_decks()

func set_ai_vs_ai_fast_mode(enabled: bool) -> void:
	ai_vs_ai_fast_mode = enabled

func should_skip_ai_vs_ai_delays() -> bool:
	return is_ai_vs_ai_batch && ai_vs_ai_fast_mode

func set_ai_vs_ai_use_random_database_decks(enabled: bool) -> void:
	ai_vs_ai_use_random_database_decks = enabled

func should_ai_vs_ai_use_random_database_decks() -> bool:
	return is_ai_vs_ai_batch && ai_vs_ai_use_random_database_decks

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
	var first_deck: Dictionary = PlayerDeckStore.get_default_playable_deck()
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
	var first_deck: Dictionary = PlayerDeckStore.get_default_playable_deck()
	selected_ai_deck_id = str(first_deck.get("deck_id", ""))

func select_default_decks() -> void:
	var default_deck_id: String = PlayerDeckStore.get_default_playable_deck_id()
	selected_deck_id = default_deck_id
	selected_ai_deck_id = default_deck_id

func select_deck_for_both_players(deck_id: String) -> void:
	var cleaned_deck_id: String = deck_id.strip_edges()
	selected_deck_id = cleaned_deck_id
	selected_ai_deck_id = cleaned_deck_id

func ensure_selected_decks() -> void:
	if selected_deck_id.strip_edges().is_empty() or !PlayerDeckStore.is_deck_playable_id(selected_deck_id):
		select_first_available_deck()
	if selected_ai_deck_id.strip_edges().is_empty() or !PlayerDeckStore.is_deck_playable_id(selected_ai_deck_id):
		selected_ai_deck_id = selected_deck_id
		if selected_ai_deck_id.strip_edges().is_empty() or !PlayerDeckStore.is_deck_playable_id(selected_ai_deck_id):
			select_first_available_ai_deck()

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
