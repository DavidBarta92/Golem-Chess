extends SettingsElement
class_name TextElement

@export var DEFAULT_VALUE: String = ""
@export var TextRef: LineEdit

func _ready() -> void:
	super._ready()
	TextRef.connect("text_changed", _on_text_changed)

func init_element() -> void:
	TextRef.text = currentValue

func get_valid_values() -> Dictionary:
	return {"defaultValue": DEFAULT_VALUE}

func is_valid_value(_VALUES_: Dictionary, _RETRIEVED_VALUE) -> bool:
	return true

func _on_text_changed(new_text: String) -> void:
	currentValue = new_text
