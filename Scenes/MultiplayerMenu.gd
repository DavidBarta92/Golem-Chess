extends Control

@onready var deck_option_button: OptionButton = $VBoxContainer/DeckOptionButton
@onready var server_ip_input: LineEdit = $VBoxContainer/ServerIPLineEdit
@onready var port_input: LineEdit = $VBoxContainer/PortLineEdit
@onready var host_button: Button = $VBoxContainer/HostButton
@onready var join_button: Button = $VBoxContainer/JoinButton
@onready var server_rooms_button: Button = $VBoxContainer/ServerRoomsButton
@onready var status_label: Label = $VBoxContainer/StatusLabel

var deck_ids: Array[String] = []

func _ready() -> void:
	server_ip_input.text = GameConfig.server_ip
	port_input.text = str(GameConfig.server_port)
	server_rooms_button.text = "Server Room"
	show_status_message(GameConfig.consume_multiplayer_menu_status_message())
	_populate_deck_options()

func _on_host_button_pressed():
	_save_selected_deck()
	_save_server_port()
	GameConfig.stop_ai_vs_ai_batch()
	GameConfig.is_singleplayer = false
	GameConfig.is_hosting = true
	GameConfig.is_dedicated_server = false
	GameConfig.server_ip = ""
	GameConfig.set_multiplayer_provider(GameConfig.MULTIPLAYER_PROVIDER_CUSTOM_SERVER)
	GameConfig.set_matchmaking_mode(GameConfig.MATCHMAKING_MODE_DIRECT_CONNECT)
	GameConfig.reset_multiplayer_controllers()
	SceneTransition.change_scene("res://Scenes/main.tscn")

func _on_join_button_pressed():
	_save_selected_deck()
	_save_server_port()
	GameConfig.stop_ai_vs_ai_batch()
	GameConfig.is_singleplayer = false
	GameConfig.is_dedicated_server = false
	GameConfig.set_multiplayer_provider(GameConfig.MULTIPLAYER_PROVIDER_CUSTOM_SERVER)
	GameConfig.set_matchmaking_mode(GameConfig.MATCHMAKING_MODE_DIRECT_CONNECT)
	GameConfig.reset_multiplayer_controllers()
	SceneTransition.change_scene("res://Scenes/JoinMenu.tscn")

func _on_server_rooms_button_pressed():
	_save_selected_deck()
	GameConfig.use_default_public_server_endpoint()
	server_ip_input.text = GameConfig.server_ip
	port_input.text = str(GameConfig.server_port)
	show_status_message("")
	GameConfig.stop_ai_vs_ai_batch()
	GameConfig.is_singleplayer = false
	GameConfig.is_hosting = false
	GameConfig.is_dedicated_server = false
	GameConfig.set_multiplayer_provider(GameConfig.MULTIPLAYER_PROVIDER_CUSTOM_SERVER)
	GameConfig.set_matchmaking_mode(GameConfig.MATCHMAKING_MODE_ROOM_LIST)
	GameConfig.reset_multiplayer_controllers()
	SceneTransition.change_scene("res://Scenes/main.tscn")

func _on_back_button_pressed():
	SceneTransition.change_scene("res://Scenes/MainMenu.tscn")

func show_status_message(message: String) -> void:
	if status_label == null:
		return
	status_label.text = message
	status_label.visible = !message.strip_edges().is_empty()

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
		server_rooms_button.disabled = true
		return

	deck_option_button.disabled = false
	host_button.disabled = false
	join_button.disabled = false
	server_rooms_button.disabled = false

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

func _save_server_ip() -> void:
	var server_ip: String = server_ip_input.text.strip_edges()
	if server_ip.is_empty():
		server_ip = GameConfig.DEFAULT_SERVER_IP
	GameConfig.server_ip = server_ip

func _save_server_port() -> void:
	GameConfig.set_server_port(port_input.text)
	port_input.text = str(GameConfig.server_port)
