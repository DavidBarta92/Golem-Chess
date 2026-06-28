@tool
extends EditorPlugin

var inspector_plugin: EditorInspectorPlugin

func _enter_tree() -> void:
	inspector_plugin = preload("res://addons/stamp_pattern_editor/stamp_pattern_inspector_plugin.gd").new()
	add_inspector_plugin(inspector_plugin)

func _exit_tree() -> void:
	if inspector_plugin != null:
		remove_inspector_plugin(inspector_plugin)
		inspector_plugin = null
