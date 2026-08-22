extends SettingsElement
class_name ToggleElement

@export var DEFAULT_VALUE: bool = false
@export var ToggleRef: CheckBox

func _ready() -> void:
	super._ready()
	ToggleRef.connect("toggled", _on_toggled)

func init_element() -> void:
	ToggleRef.button_pressed = currentValue

func get_valid_values() -> Dictionary:
	return {
		"defaultValue": DEFAULT_VALUE,
		"validOptions": [true, false],
	}

func _on_toggled(state: bool) -> void:
	currentValue = state
