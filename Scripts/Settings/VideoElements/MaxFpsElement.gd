extends OptionElement
class_name MaxFpsElement

func _init() -> void:
	IDENTIFIER = "MaxFPS"
	DEFAULT_VALUE = "Unlimited"
	OPTION_LIST_ = {
		"Unlimited": 0,
		"30": 30,
		"60": 60,
		"90": 90,
		"120": 120,
		"144": 144,
		"165": 165,
		"240": 240,
	}

func _apply_settings() -> void:
	if ParentRef.ELEMENT_REFERENCE_TABLE_.has("VSync"):
		var vsync_element: SettingsElement = ParentRef.ELEMENT_REFERENCE_TABLE_["VSync"]
		if vsync_element.currentValue != "Disabled":
			return

	Engine.max_fps = OPTION_LIST_[currentValue]
