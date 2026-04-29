extends Control

@onready var ip_input = $VBoxContainer/IPLineEdit

func _on_connect_button_pressed():
	var ip = ip_input.text
	if ip == "":
		ip = "127.0.0.1"

	print("Joining IP: ", ip)

	GameConfig.is_hosting = false
	GameConfig.server_ip = ip

	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
