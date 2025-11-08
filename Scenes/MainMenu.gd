extends Control

func _on_host_button_pressed():
	# Jelezzük, hogy host módban indulunk
	GameState.is_hosting = true
	GameState.server_ip = ""
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_join_button_pressed():
	# Váltsunk a Join menüre
	get_tree().change_scene_to_file("res://Scenes/JoinMenu.tscn")
