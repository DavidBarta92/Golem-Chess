extends SettingsElement
class_name OptionElement

@export var DEFAULT_VALUE: String
@export var OptionsRef: OptionButton

var OPTION_LIST_

func _ready() -> void:
	super._ready()
	OptionsRef.connect("item_selected", option_selected)

func init_element() -> void:
	fill_options_button()

func get_valid_values() -> Dictionary:
	if not OPTION_LIST_.has(DEFAULT_VALUE):
		DEFAULT_VALUE = (OPTION_LIST_.keys()[0] if OPTION_LIST_ is Dictionary else OPTION_LIST_[0])

	return {
		"defaultValue": DEFAULT_VALUE,
		"validOptions": OPTION_LIST_,
	}

func fill_options_button() -> void:
	if OptionsRef.get_item_count() == 0:
		var index: int = 0
		for option in OPTION_LIST_:
			OptionsRef.add_item(option, index)
			index += 1

	var selected_index: int = 0
	for i in OptionsRef.get_item_count():
		if OptionsRef.get_item_text(i) == currentValue:
			selected_index = i
			break
	OptionsRef.select(selected_index)

func option_selected(index: int) -> void:
	currentValue = OptionsRef.get_item_text(index)
