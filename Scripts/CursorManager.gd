extends Node

const DEFAULT_CURSOR_TEXTURE := preload("res://Assets/curzor.svg")
const STAMP_DRAG_CURSOR_TEXTURE := preload("res://Assets/curzor_pickup.svg")
const DEFAULT_CURSOR_HOTSPOT := Vector2.ZERO

var _custom_cursor_enabled := false


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return

	_custom_cursor_enabled = true
	set_default_cursor()


func set_default_cursor() -> void:
	if !_custom_cursor_enabled:
		return

	Input.set_custom_mouse_cursor(DEFAULT_CURSOR_TEXTURE, Input.CURSOR_ARROW, DEFAULT_CURSOR_HOTSPOT)


func set_stamp_drag_cursor() -> void:
	if !_custom_cursor_enabled:
		return

	Input.set_custom_mouse_cursor(STAMP_DRAG_CURSOR_TEXTURE, Input.CURSOR_ARROW, DEFAULT_CURSOR_HOTSPOT)
