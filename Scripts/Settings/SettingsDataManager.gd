extends Node

signal settings_retrieved

const FILE_NAME: String = "settings.cfg"
var PATH: String = "user://" + FILE_NAME

const CRT_OVERLAY_SCENE = preload("res://Scenes/CrtOverlay.tscn")
## The CRT pass reworks the finished frame, so it sits above every other canvas
## layer: the scene transition (1000), the embedded popup windows (1024), the
## top bar (1200), the scenes' paper (1210) and the hint arrows (1250) included.
const CRT_LAYER: int = RenderingServer.CANVAS_LAYER_MAX

var settingsData_: Dictionary = {}
var SECTION_REFERENCE_TABLE_: Dictionary = {}

var noSaveFile: bool = false
var invalidSaveFile: bool = false

var crt_overlay: CanvasLayer
var crt_aberration_tween: Tween
var crt_rest_aberration: float = 0.0

func _ready() -> void:
	if FileAccess.file_exists(PATH):
		call_deferred("get_data")
	else:
		noSaveFile = true
	call_deferred("emit_signal", "settings_retrieved")
	ensure_crt_overlay()
	settings_retrieved.connect(_apply_saved_crt_effect)

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
	return bool(settingsData_.get("UI", {}).get("ShowLastMoveArrow", false))

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

## Whether a capture may jolt the board and flash: off for players these
## bother. The rest of a capture - its cracks and sounds - stays.
func is_screen_shake_enabled() -> bool:
	return bool(settingsData_.get("UI", {}).get("ScreenShake", true))

## The overlay exists from startup, so every scene gets it, even one run on its
## own; the saved setting only switches it on or off.
func is_crt_effect_enabled() -> bool:
	return bool(settingsData_.get("Video", {}).get("CrtEffect", true))

func _apply_saved_crt_effect() -> void:
	apply_crt_effect(is_crt_effect_enabled())

func apply_crt_effect(enabled: bool) -> void:
	ensure_crt_overlay()
	crt_overlay.visible = enabled

## The overlay's material is the shared res://Shaders/crt_vhs_material.tres, not
## a copy, so editing that resource in the inspector while the game runs from
## the editor updates the effect live.
func ensure_crt_overlay() -> void:
	if crt_overlay == null or !is_instance_valid(crt_overlay):
		crt_overlay = CRT_OVERLAY_SCENE.instantiate()
		crt_overlay.layer = CRT_LAYER
		add_child(crt_overlay)

## A shudder through the old screen: the CRT pass's colour fringes swing from
## `amplitude` to minus `amplitude` and back, `swings` times over `duration`,
## then settle back on the material's own value. The tween is this autoload's,
## so it finishes and puts the value back even if the scene that asked is
## gone by then - the material is shared by every scene. A second shudder
## while one is running starts over from the same resting value.
func wobble_crt_aberration(amplitude: float, duration: float, swings: float) -> void:
	ensure_crt_overlay()
	var overlay: CanvasItem = crt_overlay.get_node_or_null("Overlay") as CanvasItem
	var material: ShaderMaterial = overlay.material as ShaderMaterial if overlay != null else null
	if material == null:
		return
	if crt_aberration_tween != null and crt_aberration_tween.is_valid():
		crt_aberration_tween.kill()
	else:
		crt_rest_aberration = float(material.get_shader_parameter(&"aberration"))
	var rest: float = crt_rest_aberration
	crt_aberration_tween = create_tween()
	crt_aberration_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	crt_aberration_tween.tween_method(func(progress: float):
		# Full swings for the first part, then dying away onto the resting value.
		var swing: float = amplitude * sin(progress * TAU * swings) * (1.0 - smoothstep(0.4, 1.0, progress))
		material.set_shader_parameter(&"aberration", swing + rest * smoothstep(0.6, 1.0, progress))
	, 0.0, 1.0, maxf(duration, 0.01))
	crt_aberration_tween.tween_callback(func(): material.set_shader_parameter(&"aberration", rest))
