extends Control

func _on_host_button_pressed():
	GameConfig.stop_ai_vs_ai_batch()
	GameConfig.is_singleplayer = false
	GameConfig.is_hosting = true
	GameConfig.server_ip = ""
	GameConfig.reset_multiplayer_controllers()
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_join_button_pressed():
	GameConfig.stop_ai_vs_ai_batch()
	GameConfig.is_singleplayer = false
	GameConfig.reset_multiplayer_controllers()
	get_tree().change_scene_to_file("res://Scenes/JoinMenu.tscn")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
