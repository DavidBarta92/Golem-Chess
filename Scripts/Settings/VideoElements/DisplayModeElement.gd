extends OptionElement
class_name DisplayModeElement

const MIN_WINDOW_SIZE: Vector2i = Vector2i(1024, 576)

func _init() -> void:
	IDENTIFIER = "DisplayMode"
	DEFAULT_VALUE = "Fullscreen"
	OPTION_LIST_ = {
		"Fullscreen": DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
		"Borderless Windowed": DisplayServer.WINDOW_MODE_WINDOWED,
		"Windowed": DisplayServer.WINDOW_MODE_WINDOWED,
	}

func load_settings() -> void:
	super.load_settings()
	call_deferred("update_resolution_enabled")

func option_selected(index: int) -> void:
	super.option_selected(index)
	update_resolution_enabled()

func _apply_settings() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, true)
	DisplayServer.window_set_min_size(MIN_WINDOW_SIZE)
	DisplayServer.window_set_mode(OPTION_LIST_[currentValue])

	if currentValue == "Borderless Windowed":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		var screen_id: int = DisplayServer.window_get_current_screen()
		DisplayServer.window_set_size(DisplayServer.screen_get_size(screen_id))
		center_window()
	else:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

	if currentValue == "Windowed" and ParentRef.ELEMENT_REFERENCE_TABLE_.has("Resolution"):
		ParentRef.ELEMENT_REFERENCE_TABLE_["Resolution"]._apply_settings()

func update_resolution_enabled() -> void:
	if not ParentRef.ELEMENT_REFERENCE_TABLE_.has("Resolution"):
		return
	var resolution_element: OptionElement = ParentRef.ELEMENT_REFERENCE_TABLE_["Resolution"]
	resolution_element.OptionsRef.disabled = currentValue != "Windowed"

func center_window() -> void:
	var screen_id: int = DisplayServer.window_get_current_screen()
	var screen_position: Vector2i = DisplayServer.screen_get_position(screen_id)
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen_id)
	var window_size: Vector2i = DisplayServer.window_get_size()
	DisplayServer.window_set_position(screen_position + (screen_size - window_size) / 2)
