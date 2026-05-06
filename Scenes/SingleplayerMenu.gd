extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var deck_option_button: OptionButton = $VBoxContainer/DeckOptionButton
@onready var ai_difficulty_option_button: OptionButton = $VBoxContainer/AIDifficultyOptionButton
@onready var ai_deck_option_button: OptionButton = $VBoxContainer/AIDeckOptionButton

var deck_ids: Array[String] = []
var ai_deck_ids: Array[String] = []

func _ready() -> void:
	_populate_deck_options()
	_populate_ai_difficulty_options()

func _on_start_button_pressed() -> void:
	_save_selected_deck()
	_save_selected_ai_deck()
	_save_ai_difficulty()
	GameConfig.stop_ai_vs_ai_batch()
	GameConfig.is_singleplayer = true
	GameConfig.is_hosting = true
	GameConfig.server_ip = ""
	GameConfig.set_singleplayer_controllers(GameConfig.CONTROLLER_HUMAN, GameConfig.CONTROLLER_AI)
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _populate_deck_options() -> void:
	deck_option_button.clear()
	ai_deck_option_button.clear()
	deck_ids.clear()
	ai_deck_ids.clear()

	var all_decks: Array = PlayerDeckStore.list_decks()
	var decks: Array = PlayerDeckStore.list_playable_decks()
	if decks.is_empty():
		var empty_text: String = "No saved decks" if all_decks.is_empty() else "No complete decks"
		deck_option_button.add_item(empty_text)
		ai_deck_option_button.add_item(empty_text)
		deck_option_button.disabled = true
		ai_deck_option_button.disabled = true
		start_button.disabled = true
		return

	deck_option_button.disabled = false
	ai_deck_option_button.disabled = false
	start_button.disabled = false

	var selected_index: int = 0
	var selected_ai_index: int = 0
	var current_deck_id: String = GameConfig.get_selected_deck_id()
	var current_ai_deck_id: String = GameConfig.get_selected_ai_deck_id()
	for deck in decks:
		if !(deck is Dictionary):
			continue

		var deck_id: String = str(deck.get("deck_id", ""))
		var deck_name: String = str(deck.get("name", "Unnamed deck"))
		deck_ids.append(deck_id)
		ai_deck_ids.append(deck_id)
		deck_option_button.add_item(deck_name)
		ai_deck_option_button.add_item(deck_name)
		if deck_id == current_deck_id:
			selected_index = deck_ids.size() - 1
		if deck_id == current_ai_deck_id:
			selected_ai_index = ai_deck_ids.size() - 1

	deck_option_button.select(selected_index)
	ai_deck_option_button.select(selected_ai_index)
	_save_selected_deck()
	_save_selected_ai_deck()

func _populate_ai_difficulty_options() -> void:
	ai_difficulty_option_button.clear()
	var selected_index: int = 0
	var current_level: int = GameConfig.get_player_ai_difficulty_level(1)
	for level in range(GameConfig.MIN_AI_DIFFICULTY_LEVEL, GameConfig.MAX_AI_DIFFICULTY_LEVEL + 1):
		ai_difficulty_option_button.add_item("Level %d" % level)
		ai_difficulty_option_button.set_item_metadata(ai_difficulty_option_button.get_item_count() - 1, level)
		if level == current_level:
			selected_index = ai_difficulty_option_button.get_item_count() - 1

	ai_difficulty_option_button.select(selected_index)
	_save_ai_difficulty()

func _save_selected_deck() -> void:
	var selected_index: int = deck_option_button.selected
	if selected_index < 0 or selected_index >= deck_ids.size():
		return

	GameConfig.set_selected_deck_id(deck_ids[selected_index])

func _save_selected_ai_deck() -> void:
	var selected_index: int = ai_deck_option_button.selected
	if selected_index < 0 or selected_index >= ai_deck_ids.size():
		return

	GameConfig.set_selected_ai_deck_id(ai_deck_ids[selected_index])

func _save_ai_difficulty() -> void:
	var selected_index: int = ai_difficulty_option_button.selected
	if selected_index < 0:
		return

	GameConfig.set_player_ai_difficulty_level(1, ai_difficulty_option_button.get_item_metadata(selected_index))
