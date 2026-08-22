extends SettingsElement
class_name SliderElement

@export var MIN_VALUE: float = 0
@export var MAX_VALUE: float = 1
@export var STEP_VALUE: float = 0.1
@export var DEFAULT_VALUE: float = 1
@export var DISPLAY_PERCENT_VALUE: bool = false
@export var VALUE_SUFFIX: String = ""

@export var SliderRef: HSlider
@export var ValueBoxRef: Label

func init_element() -> void:
	init_slider(100.0 if DISPLAY_PERCENT_VALUE else 1.0)

func init_slider(FACTOR: float) -> void:
	SliderRef.set_min(MIN_VALUE * FACTOR)
	SliderRef.set_max(MAX_VALUE * FACTOR)
	SliderRef.set_step(STEP_VALUE * FACTOR)
	SliderRef.set_value(currentValue * FACTOR)

	if not SliderRef.is_connected("value_changed", slider_value_changed):
		SliderRef.connect("value_changed", slider_value_changed.bind(FACTOR))

	update_value_label(currentValue)

func get_valid_values() -> Dictionary:
	return {
		"defaultValue": clampf(DEFAULT_VALUE, MIN_VALUE, MAX_VALUE),
		"minValue": MIN_VALUE,
		"maxValue": MAX_VALUE,
	}

func slider_value_changed(value: float, FACTOR: float) -> void:
	currentValue = value / FACTOR
	update_value_label(currentValue)

func update_value_label(value: float) -> void:
	if ValueBoxRef == null:
		return
	var display_value: float = value * (100.0 if DISPLAY_PERCENT_VALUE else 1.0)
	ValueBoxRef.text = "%.0f%s" % [display_value, VALUE_SUFFIX]
