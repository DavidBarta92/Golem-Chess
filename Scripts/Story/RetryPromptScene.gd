extends Control

## The "play again right away?" beat after losing a story boss fight.
## Yes restarts the same fight; no returns to the hub with the node still
## pending, so Play brings the fight back later.

@onready var yes_button: Button = $Panel/Layout/Buttons/YesButton
@onready var no_button: Button = $Panel/Layout/Buttons/NoButton

func _ready() -> void:
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)
	yes_button.grab_focus()

func _on_yes_pressed() -> void:
	_disable_buttons()
	StoryManager.restart_current_node()

func _on_no_pressed() -> void:
	_disable_buttons()
	StoryManager.return_to_hub()

func _disable_buttons() -> void:
	yes_button.disabled = true
	no_button.disabled = true
