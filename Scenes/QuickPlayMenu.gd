extends Control

## Streamlined singleplayer entry point: pick only your own codex, then
## either press Start or wait out the countdown. The AI mirrors whichever
## codex is selected and gets a random difficulty level (see
## AI_DIFFICULTY_MIN/MAX) since there's no AI codex/difficulty picker here.

const COUNTDOWN_SECONDS: float = 10.0
const AI_DIFFICULTY_MIN: int = 1
const AI_DIFFICULTY_MAX: int = 6

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var deck_option_button: OptionButton = $VBoxContainer/DeckOptionButton
@onready var countdown_label: Label = $VBoxContainer/CountdownLabel

var deck_ids: Array[String] = []
var _remaining_seconds: float = COUNTDOWN_SECONDS
var _match_started: bool = false

func _ready() -> void:
	_populate_deck_options()
	_remaining_seconds = COUNTDOWN_SECONDS
	_update_countdown_label()

func _process(delta: float) -> void:
	if _match_started:
		return
	_remaining_seconds = max(0.0, _remaining_seconds - delta)
	_update_countdown_label()
	if _remaining_seconds <= 0.0:
		_start_match()

func _update_countdown_label() -> void:
	countdown_label.text = str(ceili(_remaining_seconds))

func _on_start_button_pressed() -> void:
	_start_match()

func _on_back_button_pressed() -> void:
	SceneTransition.change_scene("res://Scenes/MainMenu.tscn")

func _populate_deck_options() -> void:
	deck_option_button.clear()
	deck_ids.clear()

	var all_decks: Array = PlayerDeckStore.list_decks()
	var decks: Array = PlayerDeckStore.list_playable_decks()
	if decks.is_empty():
		var empty_text: String = tr("No saved codexes") if all_decks.is_empty() else tr("No complete codexes")
		deck_option_button.add_item(empty_text)
		deck_option_button.disabled = true
		start_button.disabled = true
		set_process(false)
		return

	deck_option_button.disabled = false
	start_button.disabled = false

	var selected_index: int = 0
	var current_deck_id: String = GameConfig.get_selected_deck_id()
	for deck in decks:
		if !(deck is Dictionary):
			continue
		var deck_id: String = str(deck.get("deck_id", ""))
		var deck_name: String = str(deck.get("name", "Unnamed codex"))
		deck_ids.append(deck_id)
		deck_option_button.add_item(deck_name)
		if deck_id == current_deck_id:
			selected_index = deck_ids.size() - 1

	deck_option_button.select(selected_index)
	_save_selected_deck()

func _save_selected_deck() -> void:
	var selected_index: int = deck_option_button.selected
	if selected_index < 0 or selected_index >= deck_ids.size():
		return
	GameConfig.set_selected_deck_id(deck_ids[selected_index])

func _start_match() -> void:
	if _match_started:
		return
	_match_started = true
	set_process(false)
	_save_selected_deck()
	GameConfig.select_deck_for_both_players(GameConfig.get_selected_deck_id())
	GameConfig.set_player_ai_difficulty_level(1, randi_range(AI_DIFFICULTY_MIN, AI_DIFFICULTY_MAX))
	GameConfig.stop_ai_vs_ai_batch()
	GameConfig.is_singleplayer = true
	GameConfig.is_hosting = true
	GameConfig.server_ip = ""
	GameConfig.set_singleplayer_controllers(GameConfig.CONTROLLER_HUMAN, GameConfig.CONTROLLER_AI)
	SceneTransition.change_scene("res://Scenes/main.tscn")
