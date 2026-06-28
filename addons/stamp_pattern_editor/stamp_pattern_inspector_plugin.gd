@tool
extends EditorInspectorPlugin

const STAMP_SCRIPT_PATH: String = "res://Scripts/Stamp.gd"
const StampPatternEditorProperty = preload("res://addons/stamp_pattern_editor/stamp_pattern_editor_property.gd")

func _can_handle(object: Object) -> bool:
	if object == null:
		return false

	var script: Script = object.get_script()
	return script != null && script.resource_path == STAMP_SCRIPT_PATH

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

	add_property_editor(name, StampPatternEditorProperty.new())
	return true
