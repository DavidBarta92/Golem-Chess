extends OptionElement
class_name AntiAliasingElement

func _init() -> void:
	IDENTIFIER = "AntiAliasing"
	DEFAULT_VALUE = "Disabled"
	OPTION_LIST_ = {
		"Disabled": Viewport.SCREEN_SPACE_AA_DISABLED,
		"FXAA": Viewport.SCREEN_SPACE_AA_FXAA,
	}

func _apply_settings() -> void:
	get_viewport().set_screen_space_aa(OPTION_LIST_[currentValue])
