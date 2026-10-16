extends Control

@onready var deck_option_button: OptionButton = $VBoxContainer/DeckOptionButton
@onready var server_ip_input: LineEdit = $VBoxContainer/ServerIPLineEdit
@onready var port_input: LineEdit = $VBoxContainer/PortLineEdit
@onready var host_button: Button = $VBoxContainer/HostButton
@onready var join_button: Button = $VBoxContainer/JoinButton
@onready var server_rooms_button: Button = $VBoxContainer/ServerRoomsButton
@onready var status_label: Label = $VBoxContainer/StatusLabel

var deck_ids: Array[String] = []
## Only there while Steam runs (SteamManager.is_available()).
var steam_friend_button: Button = null
var steam_quick_match_button: Button = null
var steam_matchmaking: SteamMatchmakingClient = null

func _ready() -> void:
	server_ip_input.text = GameConfig.server_ip
	port_input.text = str(GameConfig.server_port)
	server_rooms_button.text = tr("Server Room")
	show_status_message(GameConfig.consume_multiplayer_menu_status_message())
	_create_steam_buttons()
	_populate_deck_options()

func _create_steam_buttons() -> void:
	if !SteamManager.is_available():
		return
	steam_friend_button = _add_button_after(server_rooms_button, tr("Steam: Invite a Friend"), _on_steam_friend_button_pressed)
	steam_quick_match_button = _add_button_after(steam_friend_button, tr("Steam: Quick Match"), _on_steam_quick_match_button_pressed)

func _add_button_after(previous: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	var container: Node = previous.get_parent()
	container.add_child(button)
	container.move_child(button, previous.get_index() + 1)
	return button

func _set_steam_buttons_disabled(disabled: bool) -> void:
	for button in [steam_friend_button, steam_quick_match_button]:
		if button != null:
			button.disabled = disabled

## Hosts a friends-only Steam lobby; the match scene opens the overlay's invite
## dialog once the lobby exists.
func _on_steam_friend_button_pressed() -> void:
	_save_selected_deck()
	GameConfig.prepare_steam_host(GameConfig.MATCHMAKING_MODE_FRIEND_INVITE)
	SceneTransition.change_scene("res://Scenes/main.tscn")

## Joins an open quick-match lobby if there is one, and opens one otherwise.
func _on_steam_quick_match_button_pressed() -> void:
	_save_selected_deck()
	show_status_message(tr("Searching for a Steam match..."))
	_set_steam_buttons_disabled(true)
	if steam_matchmaking == null:
		steam_matchmaking = SteamMatchmakingClient.new()
		add_child(steam_matchmaking)
		steam_matchmaking.lobby_join_requested.connect(_on_steam_quick_match_found)
		steam_matchmaking.quick_match_requested.connect(_on_steam_quick_match_empty)
		steam_matchmaking.matchmaking_failed.connect(_on_steam_matchmaking_failed)
	steam_matchmaking.start_quick_match()

func _on_steam_quick_match_found(lobby: MultiplayerLobby) -> void:
	GameConfig.prepare_steam_join(lobby.lobby_id, GameConfig.MATCHMAKING_MODE_QUICK_MATCH)
	SceneTransition.change_scene("res://Scenes/main.tscn")

func _on_steam_quick_match_empty() -> void:
	GameConfig.prepare_steam_host(GameConfig.MATCHMAKING_MODE_QUICK_MATCH)
	SceneTransition.change_scene("res://Scenes/main.tscn")

func _on_steam_matchmaking_failed(message: String) -> void:
	show_status_message(message)
	_set_steam_buttons_disabled(false)

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
		var empty_text: String = tr("No saved codexes") if all_decks.is_empty() else tr("No complete codexes")
		deck_option_button.add_item(empty_text)
		deck_option_button.disabled = true
		host_button.disabled = true
		join_button.disabled = true
		server_rooms_button.disabled = true
		_set_steam_buttons_disabled(true)
		return

	deck_option_button.disabled = false
	host_button.disabled = false
	join_button.disabled = false
	server_rooms_button.disabled = false
	_set_steam_buttons_disabled(false)

	var selected_index: int = 0
	var current_deck_id: String = GameConfig.get_selected_deck_id()
	for deck in decks:
		if !(deck is Dictionary):
			continue

		var deck_id: String = str(deck.get("deck_id", ""))
		deck_ids.append(deck_id)
		deck_option_button.add_item(str(deck.get("name", "Unnamed codex")))
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
