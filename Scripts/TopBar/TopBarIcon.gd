extends Control

## One of TopBarIcons' drawn icons as a control, for rows and labels. A name
## starting with "mini_" draws the small ribbon silhouette of that quest kind
## ("mini_story", "mini_reward", "mini_daily") filled with fill_color.
## Printed with the ink stamp.

const TopBarIcons = preload("res://Scripts/TopBar/TopBarIcons.gd")
const TopBarStyle = preload("res://Scripts/TopBar/TopBarStyle.gd")
const InkStampMaterial = preload("res://Scripts/InkStamp/InkStampMaterial.gd")

var icon_name: String = "":
	set(value):
		icon_name = value
		queue_redraw()
var color: Color = TopBarStyle.INK:
	set(value):
		color = value
		queue_redraw()
var fill_color: Color = TopBarStyle.STORY:
	set(value):
		fill_color = value
		queue_redraw()
var mono: bool = false:
	set(value):
		mono = value
		queue_redraw()

func _init(name_of_icon: String = "", icon_size: float = TopBarStyle.ICON_MENU, icon_color: Color = TopBarStyle.INK, mono_icon: bool = false) -> void:
	icon_name = name_of_icon
	color = icon_color
	mono = mono_icon
	custom_minimum_size = Vector2.ONE * icon_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	InkStampMaterial.apply(self)

func _draw() -> void:
	if icon_name.begins_with("mini_"):
		TopBarIcons.draw_mini_ribbon(self, icon_name.trim_prefix("mini_"), Rect2(Vector2.ZERO, size), fill_color, color)
		return
	TopBarIcons.draw_icon(self, icon_name, Rect2(Vector2.ZERO, size), color, mono)
