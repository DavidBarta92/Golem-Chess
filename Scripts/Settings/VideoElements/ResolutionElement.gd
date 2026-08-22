extends OptionElement
class_name ResolutionElement

func _init() -> void:
	IDENTIFIER = "Resolution"
	DEFAULT_VALUE = "1280x720"
	OPTION_LIST_ = {
		"1024x576": Vector2i(1024, 576),
		"1280x720": Vector2i(1280, 720),
		"1600x900": Vector2i(1600, 900),
		"1920x1080": Vector2i(1920, 1080),
		"2560x1440": Vector2i(2560, 1440),
	}

func _apply_settings() -> void:
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		return
	if DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS):
		return

	DisplayServer.window_set_size(OPTION_LIST_[currentValue])
	center_window()

func center_window() -> void:
	var screen_id: int = DisplayServer.window_get_current_screen()
	var screen_position: Vector2i = DisplayServer.screen_get_position(screen_id)
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen_id)
	var window_size: Vector2i = DisplayServer.window_get_size()
	DisplayServer.window_set_position(screen_position + (screen_size - window_size) / 2)
