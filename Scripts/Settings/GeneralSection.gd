extends SettingsSection
class_name GeneralSection

@onready var tutorial_button: Button = $Scroll/Content/TutorialButton

func _ready() -> void:
	super._ready()
	tutorial_button.pressed.connect(_on_tutorial_button_pressed)

func _on_tutorial_button_pressed() -> void:
	SceneTransition.change_scene("res://Scenes/Tutorial.tscn")
