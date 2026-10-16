extends Node

signal settings_retrieved

const FILE_NAME: String = "settings.cfg"
var PATH: String = "user://" + FILE_NAME

const FILM_GRAIN_SHADER = preload("res://Shaders/film_grain.gdshader")
const FILM_GRAIN_SIZE: float = 1.55
const FILM_GRAIN_SPEED: float = 12.0
const FILM_GRAIN_LAYER: int = 128

var settingsData_: Dictionary = {}
var SECTION_REFERENCE_TABLE_: Dictionary = {}

var noSaveFile: bool = false
var invalidSaveFile: bool = false

var film_grain_layer: CanvasLayer
var film_grain_overlay: ColorRect

func _ready() -> void:
	if FileAccess.file_exists(PATH):
		call_deferred("get_data")
	else:
		noSaveFile = true
	call_deferred("emit_signal", "settings_retrieved")

func save_data() -> void:
	var config := ConfigFile.new()
	for section in settingsData_:
		for element in settingsData_[section]:
			config.set_value(section, element, settingsData_[section][element])

	var err := config.save(PATH)
	if err != OK:
		push_error("Failed to save settings data: ", err)
		return

	noSaveFile = false
	invalidSaveFile = false

func get_data() -> void:
	var config := ConfigFile.new()
	var err := config.load(PATH)
	if err != OK:
		push_error("Failed to load settings data: ", err)
		noSaveFile = true
		return

	var data_: Dictionary = {}
	for section in config.get_sections():
		data_[section] = {}
		for key in config.get_section_keys(section):
			data_[section][key] = config.get_value(section, key)

	verify_settings_data_(data_)
	settingsData_ = data_.duplicate(true)

func verify_settings_data_(data_: Dictionary) -> void:
	for section in SECTION_REFERENCE_TABLE_:
		if not data_.has(section):
			data_[section] = {}
			invalidSaveFile = true

func is_last_move_arrow_enabled() -> bool:
	return bool(settingsData_.get("UI", {}).get("ShowLastMoveArrow", true))

## Whether to stop a player about to move while a stamp is still waiting to
## go on a golem. A move ends the turn, so that is the moment it matters. Turned off from the warning itself, by the player who has
## learned the rule and does not want asking again.
func is_move_ends_turn_warning_enabled() -> bool:
	return bool(settingsData_.get("UI", {}).get("WarnBeforeMoveEndsTurn", true))

func set_move_ends_turn_warning_enabled(enabled: bool) -> void:
	if !settingsData_.has("UI"):
		settingsData_["UI"] = {}
	settingsData_["UI"]["WarnBeforeMoveEndsTurn"] = enabled
	save_data()

func is_enemy_attack_markers_enabled() -> bool:
	return bool(settingsData_.get("UI", {}).get("ShowEnemyAttackMarkers", true))

func apply_film_grain_intensity(intensity: float) -> void:
	ensure_film_grain_overlay()
	film_grain_overlay.visible = intensity > 0.0
	var material := film_grain_overlay.material as ShaderMaterial
	material.set_shader_parameter("intensity", intensity)
	material.set_shader_parameter("grain_size", FILM_GRAIN_SIZE)
	material.set_shader_parameter("animation_speed", FILM_GRAIN_SPEED)

func ensure_film_grain_overlay() -> void:
	if film_grain_layer == null or !is_instance_valid(film_grain_layer):
		film_grain_layer = CanvasLayer.new()
		film_grain_layer.name = "GlobalFilmGrainLayer"
		film_grain_layer.layer = FILM_GRAIN_LAYER
		add_child(film_grain_layer)

	if film_grain_overlay == null or !is_instance_valid(film_grain_overlay):
		film_grain_overlay = ColorRect.new()
		film_grain_overlay.name = "GlobalFilmGrainOverlay"
		film_grain_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		film_grain_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		film_grain_overlay.color = Color.WHITE
		film_grain_layer.add_child(film_grain_overlay)

		var material := ShaderMaterial.new()
		material.shader = FILM_GRAIN_SHADER
		film_grain_overlay.material = material
