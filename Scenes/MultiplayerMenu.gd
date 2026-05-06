extends Control

@onready var deck_option_button: OptionButton = $VBoxContainer/DeckOptionButton
@onready var host_button: Button = $VBoxContainer/HostButton
@onready var join_button: Button = $VBoxContainer/JoinButton

var deck_ids: Array[String] = []

func _ready() -> void:
	_populate_deck_options()

func _on_host_button_pressed():
	_save_selected_deck()
	GameConfig.stop_ai_vs_ai_batch()
	GameConfig.is_singleplayer = false
	GameConfig.is_hosting = true
	GameConfig.server_ip = ""
	GameConfig.reset_multiplayer_controllers()
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_join_button_pressed():
	_save_selected_deck()
	GameConfig.stop_ai_vs_ai_batch()
	GameConfig.is_singleplayer = false
	GameConfig.reset_multiplayer_controllers()
	get_tree().change_scene_to_file("res://Scenes/JoinMenu.tscn")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _populate_deck_options() -> void:
	deck_option_button.clear()
	deck_ids.clear()

	var all_decks: Array = PlayerDeckStore.list_decks()
	var decks: Array = PlayerDeckStore.list_playable_decks()
	if decks.is_empty():
		var empty_text: String = "No saved decks" if all_decks.is_empty() else "No complete decks"
		deck_option_button.add_item(empty_text)
		deck_option_button.disabled = true
		host_button.disabled = true
		join_button.disabled = true
		return

	deck_option_button.disabled = false
	host_button.disabled = false
	join_button.disabled = false

	var selected_index: int = 0
	var current_deck_id: String = GameConfig.get_selected_deck_id()
	for deck in decks:
		if !(deck is Dictionary):
			continue

		var deck_id: String = str(deck.get("deck_id", ""))
		deck_ids.append(deck_id)
		deck_option_button.add_item(str(deck.get("name", "Unnamed deck")))
		if deck_id == current_deck_id:
			selected_index = deck_ids.size() - 1

	deck_option_button.select(selected_index)
	_save_selected_deck()

func _save_selected_deck() -> void:
	var selected_index: int = deck_option_button.selected
	if selected_index < 0 or selected_index >= deck_ids.size():
		return

	GameConfig.set_selected_deck_id(deck_ids[selected_index])
