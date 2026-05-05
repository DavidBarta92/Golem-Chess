extends Node

const SETTINGS_SCHEMA_VERSION: int = 1
const SETTINGS_PATH: String = "user://settings.json"
const TARGET_WIDTH: int = 1280
const TARGET_HEIGHT: int = 720
const MIN_WINDOW_WIDTH: int = 1024
const MIN_WINDOW_HEIGHT: int = 576

var settings_data: Dictionary = {}
var is_loaded: bool = false

func _ready() -> void:
	ensure_loaded()
	apply_runtime_settings()

func ensure_loaded() -> void:
	if is_loaded:
		return

	if FileAccess.file_exists(SETTINGS_PATH):
		var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			settings_data = _normalize_settings(parsed)
			is_loaded = true
			_sync_game_config()
			save_settings()
			return

	settings_data = _create_default_settings()
	is_loaded = true
	_sync_game_config()
	save_settings()

func get_player_name() -> String:
	ensure_loaded()
	return GameConfig.sanitize_player_name(str(settings_data.get("player_name", GameConfig.DEFAULT_PLAYER_NAME)))

func set_player_name(player_name: String) -> void:
	ensure_loaded()
	settings_data["player_name"] = GameConfig.sanitize_player_name(player_name)
	_sync_game_config()
	save_settings()

func is_fullscreen_enabled() -> bool:
	ensure_loaded()
	return bool(settings_data.get("fullscreen", false))

func set_fullscreen_enabled(enabled: bool) -> void:
	ensure_loaded()
	settings_data["fullscreen"] = enabled
	apply_window_mode()
	save_settings()

func apply_runtime_settings() -> void:
	apply_window_settings()
	_sync_game_config()

func apply_window_settings() -> void:
	DisplayServer.window_set_min_size(Vector2i(MIN_WINDOW_WIDTH, MIN_WINDOW_HEIGHT))
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_size(Vector2i(TARGET_WIDTH, TARGET_HEIGHT))
		center_window()
	apply_window_mode()

func apply_window_mode() -> void:
	var target_mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN if is_fullscreen_enabled() else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(target_mode)
	if target_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_min_size(Vector2i(MIN_WINDOW_WIDTH, MIN_WINDOW_HEIGHT))
		DisplayServer.window_set_size(Vector2i(TARGET_WIDTH, TARGET_HEIGHT))
		center_window()

func center_window() -> void:
	var screen_id: int = DisplayServer.window_get_current_screen()
	var screen_position: Vector2i = DisplayServer.screen_get_position(screen_id)
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen_id)
	var window_size: Vector2i = DisplayServer.window_get_size()
	DisplayServer.window_set_position(screen_position + ((screen_size - window_size) / 2))

func save_settings() -> bool:
	if settings_data.is_empty():
		settings_data = _create_default_settings()

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not save player settings to %s" % SETTINGS_PATH)
		return false

	file.store_string(JSON.stringify(settings_data, "\t"))
	return true

func _sync_game_config() -> void:
	GameConfig.set_local_player_name(get_player_name())

func _create_default_settings() -> Dictionary:
	return {
		"schema_version": SETTINGS_SCHEMA_VERSION,
		"player_name": GameConfig.DEFAULT_PLAYER_NAME,
		"fullscreen": false,
		"language": "en",
		"master_volume": 1.0,
	}

func _normalize_settings(raw_data) -> Dictionary:
	var normalized := _create_default_settings()
	if !(raw_data is Dictionary):
		return normalized

	normalized["schema_version"] = int(raw_data.get("schema_version", SETTINGS_SCHEMA_VERSION))
	normalized["player_name"] = GameConfig.sanitize_player_name(str(raw_data.get("player_name", GameConfig.DEFAULT_PLAYER_NAME)))
	normalized["fullscreen"] = bool(raw_data.get("fullscreen", false))
	normalized["language"] = str(raw_data.get("language", "en"))
	normalized["master_volume"] = clampf(float(raw_data.get("master_volume", 1.0)), 0.0, 1.0)
	return normalized
