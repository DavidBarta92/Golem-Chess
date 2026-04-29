extends Control

func _on_singleplayer_button_pressed():
	GameConfig.is_singleplayer = true
	GameConfig.is_hosting = true
	GameConfig.server_ip = ""
	GameConfig.set_singleplayer_controllers(GameConfig.CONTROLLER_HUMAN, GameConfig.CONTROLLER_AI)
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_host_button_pressed():
	GameConfig.is_singleplayer = false
	GameConfig.is_hosting = true
	GameConfig.server_ip = ""
	GameConfig.reset_multiplayer_controllers()
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_join_button_pressed():
	GameConfig.is_singleplayer = false
	GameConfig.reset_multiplayer_controllers()
	get_tree().change_scene_to_file("res://Scenes/JoinMenu.tscn")
