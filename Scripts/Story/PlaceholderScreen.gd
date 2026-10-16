extends Control

## A stand-in for a screen whose design is still to come (Quests, Trade, the
## story's multiplayer). Shows its name and a way back to the main menu, so
## the button that opens it can already be wired up and gated by the story.

const MAIN_MENU_SCENE: String = "res://Scenes/MainMenu.tscn"

## Translation key or plain text shown as the screen's title.
@export var title_key: String = ""

@onready var title_label: Label = $Layout/Title
@onready var back_button: Button = $BackButton

func _ready() -> void:
	if title_label != null and !title_key.strip_edges().is_empty():
		title_label.text = tr(title_key)
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	back_button.disabled = true
	SceneTransition.change_scene(MAIN_MENU_SCENE)
