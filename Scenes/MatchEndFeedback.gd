extends Control

const MAIN_MENU_SCENE: String = "res://Scenes/MainMenu.tscn"
const FEEDBACK_FORM_URL: String = "https://docs.google.com/forms/d/e/1FAIpQLScYGkf0VRVpqFOIf9XYMX2fDn_c1RGDnMCYRjjugctRHYcYtA/viewform?usp=header"


func _on_main_menu_button_pressed() -> void:
	SceneTransition.change_scene(MAIN_MENU_SCENE)


func _on_feedback_button_pressed() -> void:
	OS.shell_open(FEEDBACK_FORM_URL)
