@tool
extends EditorInspectorPlugin

const CARD_SCRIPT_PATH: String = "res://Scripts/Card.gd"
const CardPatternEditorProperty = preload("res://addons/card_pattern_editor/card_pattern_editor_property.gd")

func _can_handle(object: Object) -> bool:
	if object == null:
		return false

	var script: Script = object.get_script()
	return script != null && script.resource_path == CARD_SCRIPT_PATH

func _parse_property(
	object: Object,
	type,
	name: String,
	hint_type,
	hint_string: String,
	usage_flags: int,
	wide: bool
) -> bool:
	if name != "movement_pattern":
		return false

	add_property_editor(name, CardPatternEditorProperty.new())
	return true
