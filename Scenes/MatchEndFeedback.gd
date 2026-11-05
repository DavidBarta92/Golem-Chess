extends Control

const MAIN_MENU_SCENE: String = "res://Scenes/MainMenu.tscn"
const FEEDBACK_FORM_URL: String = "https://docs.google.com/forms/d/e/1FAIpQLScYGkf0VRVpqFOIf9XYMX2fDn_c1RGDnMCYRjjugctRHYcYtA/viewform?usp=header"


func _on_main_menu_button_pressed() -> void:
	# In the story this screen is a node of its own, and leaving it without
	# completing that node would have the hub send the player straight back.
	if _is_current_story_node():
		StoryManager.finish_current_node()
		return
	SceneTransition.change_scene(MAIN_MENU_SCENE)


func _on_feedback_button_pressed() -> void:
	OS.shell_open(FEEDBACK_FORM_URL)


func _is_current_story_node() -> bool:
	var story_node := StoryManager.get_current_node() as SceneStoryNode
	return story_node != null and ResourceUID.ensure_path(story_node.scene_path) == scene_file_path
