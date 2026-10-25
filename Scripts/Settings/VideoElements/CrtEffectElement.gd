extends ToggleElement
class_name CrtEffectElement

func _init() -> void:
	IDENTIFIER = "CrtEffect"
	DEFAULT_VALUE = true

func _apply_settings() -> void:
	SettingsDataManager.apply_crt_effect(currentValue)
