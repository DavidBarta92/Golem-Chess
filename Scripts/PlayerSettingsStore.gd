extends Node

const FILM_GRAIN_SHADER = preload("res://Shaders/film_grain.gdshader")

const SETTINGS_SCHEMA_VERSION: int = 6
const SETTINGS_PATH: String = "user://settings.json"
const TARGET_WIDTH: int = 1280
const TARGET_HEIGHT: int = 720
const MIN_WINDOW_WIDTH: int = 1024
const MIN_WINDOW_HEIGHT: int = 576
const DEFAULT_FPS_LIMIT: int = 0
const PREVIOUS_DEFAULT_FILM_GRAIN_INTENSITY: float = 0.045
const DEFAULT_FILM_GRAIN_INTENSITY: float = 0.02
const MIN_FILM_GRAIN_INTENSITY: float = 0.0
const MAX_FILM_GRAIN_INTENSITY: float = 0.16
const FILM_GRAIN_SIZE: float = 1.35
const FILM_GRAIN_SPEED: float = 18.0
const FILM_GRAIN_LAYER: int = 128
const SUPPORTED_WINDOW_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1024, 576),
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]
const SUPPORTED_FPS_LIMITS: Array[int] = [
	0,
	30,
	60,
	90,
	120,
	144,
	165,
	240,
]

var settings_data: Dictionary = {}
var is_loaded: bool = false
var film_grain_layer: CanvasLayer
var film_grain_overlay: ColorRect

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

func get_player_portrait_data() -> Dictionary:
	ensure_loaded()
	var portrait_data = settings_data.get("player_portrait", {})
	return PortraitLibrary.config_from_data_or_default(portrait_data, 0).to_dict()

func set_player_portrait_data(portrait_data: Dictionary) -> void:
	ensure_loaded()
	settings_data["player_portrait"] = PortraitLibrary.config_from_data_or_default(portrait_data, 0).to_dict()
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

func get_window_resolution() -> Vector2i:
	ensure_loaded()
	return _sanitize_window_resolution(settings_data.get("window_resolution", Vector2i(TARGET_WIDTH, TARGET_HEIGHT)))

func set_window_resolution(resolution: Vector2i) -> void:
	ensure_loaded()
	settings_data["window_resolution"] = _window_resolution_to_settings_dict(_sanitize_window_resolution(resolution))
	apply_window_resolution()
	save_settings()

func get_fps_limit() -> int:
	ensure_loaded()
	return _sanitize_fps_limit(int(settings_data.get("fps_limit", DEFAULT_FPS_LIMIT)))

func set_fps_limit(fps_limit: int) -> void:
	ensure_loaded()
	settings_data["fps_limit"] = _sanitize_fps_limit(fps_limit)
	apply_frame_rate_settings()
	save_settings()

func get_supported_window_resolutions() -> Array[Vector2i]:
	var output: Array[Vector2i] = []
	for resolution in SUPPORTED_WINDOW_RESOLUTIONS:
		output.append(resolution)
	return output

func get_supported_fps_limits() -> Array[int]:
	var output: Array[int] = []
	for fps_limit in SUPPORTED_FPS_LIMITS:
		output.append(fps_limit)
	return output

func is_last_move_arrow_enabled() -> bool:
	ensure_loaded()
	return bool(settings_data.get("show_last_move_arrow", true))

func set_last_move_arrow_enabled(enabled: bool) -> void:
	ensure_loaded()
	settings_data["show_last_move_arrow"] = enabled
	save_settings()

func is_enemy_attack_markers_enabled() -> bool:
	ensure_loaded()
	return bool(settings_data.get("show_enemy_attack_markers", true))

func set_enemy_attack_markers_enabled(enabled: bool) -> void:
	ensure_loaded()
	settings_data["show_enemy_attack_markers"] = enabled
	save_settings()

func get_film_grain_intensity() -> float:
	ensure_loaded()
	return clampf(float(settings_data.get("film_grain_intensity", DEFAULT_FILM_GRAIN_INTENSITY)), MIN_FILM_GRAIN_INTENSITY, MAX_FILM_GRAIN_INTENSITY)

func set_film_grain_intensity(intensity: float) -> void:
	ensure_loaded()
	settings_data["film_grain_intensity"] = clampf(intensity, MIN_FILM_GRAIN_INTENSITY, MAX_FILM_GRAIN_INTENSITY)
	apply_film_grain_settings()
	save_settings()

func apply_runtime_settings() -> void:
	apply_window_settings()
	apply_frame_rate_settings()
	_sync_game_config()
	ensure_film_grain_overlay()

func ensure_film_grain_overlay() -> void:
	if film_grain_layer == null || !is_instance_valid(film_grain_layer):
		film_grain_layer = CanvasLayer.new()
		film_grain_layer.name = "GlobalFilmGrainLayer"
		film_grain_layer.layer = FILM_GRAIN_LAYER
		add_child(film_grain_layer)

	if film_grain_overlay == null || !is_instance_valid(film_grain_overlay):
		film_grain_overlay = ColorRect.new()
		film_grain_overlay.name = "GlobalFilmGrainOverlay"
		film_grain_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		film_grain_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		film_grain_overlay.offset_left = 0.0
		film_grain_overlay.offset_top = 0.0
		film_grain_overlay.offset_right = 0.0
		film_grain_overlay.offset_bottom = 0.0
		film_grain_overlay.color = Color.WHITE
		film_grain_layer.add_child(film_grain_overlay)

		var material := ShaderMaterial.new()
		material.shader = FILM_GRAIN_SHADER
		film_grain_overlay.material = material

	apply_film_grain_settings()

func apply_film_grain_settings() -> void:
	if film_grain_overlay == null || !is_instance_valid(film_grain_overlay):
		return

	var intensity: float = get_film_grain_intensity()
	film_grain_overlay.visible = intensity > 0.0
	var material := film_grain_overlay.material as ShaderMaterial
	if material == null:
		material = ShaderMaterial.new()
		material.shader = FILM_GRAIN_SHADER
		film_grain_overlay.material = material
	material.set_shader_parameter("intensity", intensity)
	material.set_shader_parameter("grain_size", FILM_GRAIN_SIZE)
	material.set_shader_parameter("animation_speed", FILM_GRAIN_SPEED)

func apply_window_settings() -> void:
	DisplayServer.window_set_min_size(Vector2i(MIN_WINDOW_WIDTH, MIN_WINDOW_HEIGHT))
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_size(get_window_resolution())
		center_window()
	apply_window_mode()

func apply_window_mode() -> void:
	var target_mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN if is_fullscreen_enabled() else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(target_mode)
	if target_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		apply_window_resolution()

func apply_window_resolution() -> void:
	DisplayServer.window_set_min_size(Vector2i(MIN_WINDOW_WIDTH, MIN_WINDOW_HEIGHT))
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		return
	DisplayServer.window_set_size(get_window_resolution())
	center_window()

func apply_frame_rate_settings() -> void:
	Engine.max_fps = get_fps_limit()

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
	GameConfig.set_local_portrait_data(get_player_portrait_data())

func _create_default_settings() -> Dictionary:
	return {
		"schema_version": SETTINGS_SCHEMA_VERSION,
		"player_name": GameConfig.DEFAULT_PLAYER_NAME,
		"player_portrait": PortraitLibrary.get_default_player_portrait().to_dict(),
		"fullscreen": false,
		"window_resolution": _window_resolution_to_settings_dict(Vector2i(TARGET_WIDTH, TARGET_HEIGHT)),
		"fps_limit": DEFAULT_FPS_LIMIT,
		"language": "en",
		"master_volume": 1.0,
		"show_last_move_arrow": true,
		"show_enemy_attack_markers": true,
		"film_grain_intensity": DEFAULT_FILM_GRAIN_INTENSITY,
	}

func _normalize_settings(raw_data) -> Dictionary:
	var normalized := _create_default_settings()
	if !(raw_data is Dictionary):
		return normalized

	var raw_schema_version: int = int(raw_data.get("schema_version", 0))
	normalized["schema_version"] = SETTINGS_SCHEMA_VERSION
	normalized["player_name"] = GameConfig.sanitize_player_name(str(raw_data.get("player_name", GameConfig.DEFAULT_PLAYER_NAME)))
	normalized["player_portrait"] = PortraitLibrary.config_from_data_or_default(raw_data.get("player_portrait", {}), 0).to_dict()
	normalized["fullscreen"] = bool(raw_data.get("fullscreen", false))
	normalized["window_resolution"] = _window_resolution_to_settings_dict(_sanitize_window_resolution(raw_data.get("window_resolution", Vector2i(TARGET_WIDTH, TARGET_HEIGHT))))
	normalized["fps_limit"] = _sanitize_fps_limit(int(raw_data.get("fps_limit", DEFAULT_FPS_LIMIT)))
	normalized["language"] = str(raw_data.get("language", "en"))
	normalized["master_volume"] = clampf(float(raw_data.get("master_volume", 1.0)), 0.0, 1.0)
	normalized["show_last_move_arrow"] = bool(raw_data.get("show_last_move_arrow", true))
	normalized["show_enemy_attack_markers"] = bool(raw_data.get("show_enemy_attack_markers", true))
	var film_grain_intensity: float = float(raw_data.get("film_grain_intensity", DEFAULT_FILM_GRAIN_INTENSITY))
	if raw_schema_version < SETTINGS_SCHEMA_VERSION && is_equal_approx(film_grain_intensity, PREVIOUS_DEFAULT_FILM_GRAIN_INTENSITY):
		film_grain_intensity = DEFAULT_FILM_GRAIN_INTENSITY
	normalized["film_grain_intensity"] = clampf(film_grain_intensity, MIN_FILM_GRAIN_INTENSITY, MAX_FILM_GRAIN_INTENSITY)
	return normalized

func _sanitize_window_resolution(value) -> Vector2i:
	var resolution := Vector2i(TARGET_WIDTH, TARGET_HEIGHT)
	if value is Vector2i:
		resolution = value
	elif value is Vector2:
		resolution = Vector2i(int(value.x), int(value.y))
	elif value is Dictionary:
		var width: int = int(value.get("width", value.get("x", TARGET_WIDTH)))
		var height: int = int(value.get("height", value.get("y", TARGET_HEIGHT)))
		resolution = Vector2i(width, height)
	elif value is Array and value.size() >= 2:
		resolution = Vector2i(int(value[0]), int(value[1]))

	resolution.x = maxi(resolution.x, MIN_WINDOW_WIDTH)
	resolution.y = maxi(resolution.y, MIN_WINDOW_HEIGHT)
	return resolution

func _window_resolution_to_settings_dict(resolution: Vector2i) -> Dictionary:
	return {
		"width": resolution.x,
		"height": resolution.y,
	}

func _sanitize_fps_limit(value: int) -> int:
	if value <= 0:
		return DEFAULT_FPS_LIMIT
	return clampi(value, 15, 360)
