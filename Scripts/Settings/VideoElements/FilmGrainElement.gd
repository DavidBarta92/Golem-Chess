extends SliderElement
class_name FilmGrainElement

func _init() -> void:
	IDENTIFIER = "FilmGrainIntensity"
	MIN_VALUE = 0.0
	MAX_VALUE = 0.16
	STEP_VALUE = 0.005
	DEFAULT_VALUE = 0.02
	DISPLAY_PERCENT_VALUE = true
	VALUE_SUFFIX = "%"

func _apply_settings() -> void:
	SettingsDataManager.apply_film_grain_intensity(currentValue)
