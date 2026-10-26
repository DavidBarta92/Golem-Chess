@tool
extends Node

## Hands Shaders/ink_blot_settings.tres to the global shader uniforms the ink
## blot (Shaders/ink_blot.gdshaderinc) reads: once at start, and again on
## every change. A tool script, so the editor's own view follows the settings
## too. project.godot only declares the uniforms; these values win.

const SETTINGS: InkBlotSettings = preload("res://Shaders/ink_blot_settings.tres")

func _ready() -> void:
	if !SETTINGS.changed.is_connected(SETTINGS.apply):
		SETTINGS.changed.connect(SETTINGS.apply)
	SETTINGS.apply()
