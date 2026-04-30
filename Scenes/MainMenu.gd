extends Control

const AI_VS_AI_UNLOCK_KEY: Key = KEY_A
const AI_VS_AI_UNLOCK_PRESS_COUNT: int = 3
const MAX_AI_VS_AI_MATCH_COUNT: int = 9999

@onready var ai_vs_ai_controls: Control = $AIVsAIControls
@onready var player_name_field: LineEdit = $VBoxContainer/PlayerNameField
@onready var ai_match_count_field: LineEdit = $AIVsAIControls/MatchCountField
@onready var ai_csv_log_dir_field: LineEdit = $AIVsAIControls/CsvLogDirField

var ai_vs_ai_unlock_presses: int = 0

func _ready():
	ai_vs_ai_controls.visible = false
	player_name_field.text = GameConfig.get_local_player_name()
	ai_match_count_field.text = str(GameConfig.ai_vs_ai_match_count)
	ai_csv_log_dir_field.text = GameConfig.get_ai_vs_ai_csv_log_dir()

func _input(event):
	if ai_vs_ai_controls.visible:
		return
	if get_viewport().gui_get_focus_owner() is LineEdit:
		return

	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or !key_event.pressed or key_event.echo:
		return

	if key_event.keycode == AI_VS_AI_UNLOCK_KEY:
		ai_vs_ai_unlock_presses += 1
		if ai_vs_ai_unlock_presses >= AI_VS_AI_UNLOCK_PRESS_COUNT:
			ai_vs_ai_controls.visible = true
	else:
		ai_vs_ai_unlock_presses = 0

func _on_singleplayer_button_pressed():
	save_player_name()
	GameConfig.stop_ai_vs_ai_batch()
	GameConfig.is_singleplayer = true
	GameConfig.is_hosting = true
	GameConfig.server_ip = ""
	GameConfig.set_singleplayer_controllers(GameConfig.CONTROLLER_HUMAN, GameConfig.CONTROLLER_AI)
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_ai_vs_ai_button_pressed():
	save_player_name()
	var match_count: int = get_ai_vs_ai_match_count()
	GameConfig.is_singleplayer = true
	GameConfig.is_hosting = true
	GameConfig.server_ip = ""
	GameConfig.set_ai_vs_ai_csv_log_dir(ai_csv_log_dir_field.text)
	GameConfig.start_ai_vs_ai_batch(match_count)
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func get_ai_vs_ai_match_count() -> int:
	var match_count: int = int(ai_match_count_field.text.strip_edges())
	if match_count < 1:
		return 1
	if match_count > MAX_AI_VS_AI_MATCH_COUNT:
		return MAX_AI_VS_AI_MATCH_COUNT
	return match_count

func save_player_name() -> void:
	GameConfig.set_local_player_name(player_name_field.text)

func _on_host_button_pressed():
	save_player_name()
	GameConfig.stop_ai_vs_ai_batch()
	GameConfig.is_singleplayer = false
	GameConfig.is_hosting = true
	GameConfig.server_ip = ""
	GameConfig.reset_multiplayer_controllers()
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_join_button_pressed():
	save_player_name()
	GameConfig.stop_ai_vs_ai_batch()
	GameConfig.is_singleplayer = false
	GameConfig.reset_multiplayer_controllers()
	get_tree().change_scene_to_file("res://Scenes/JoinMenu.tscn")
