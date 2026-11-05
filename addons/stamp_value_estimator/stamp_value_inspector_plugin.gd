@tool
extends EditorInspectorPlugin

const StampValueProperty = preload("res://addons/stamp_value_estimator/stamp_value_property.gd")

func _can_handle(object: Object) -> bool:
	return object is Stamp

func _parse_property(
	object: Object,
	type,
	name: String,
	hint_type,
	hint_string: String,
	usage_flags: int,
	wide: bool
) -> bool:
	if name != "estimated_value":
		return false

	add_property_editor(name, StampValueProperty.new(), false, "Becsült érték")
	return true
