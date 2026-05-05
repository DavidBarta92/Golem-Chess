extends Control

const AI_VS_AI_UNLOCK_KEY: Key = KEY_A
const AI_VS_AI_UNLOCK_PRESS_COUNT: int = 3
const MAX_AI_VS_AI_MATCH_COUNT: int = 9999

@onready var ai_vs_ai_controls: Control = $AIVsAIControls
@onready var ai_match_count_field: LineEdit = $AIVsAIControls/MatchCountField
@onready var ai_csv_log_dir_field: LineEdit = $AIVsAIControls/CsvLogDirField

var ai_vs_ai_unlock_presses: int = 0
var settings_button: Button
var settings_dialog: AcceptDialog
var player_name_field: LineEdit
var fullscreen_check: CheckBox

func _ready():
	PlayerSettingsStore.ensure_loaded()
	ai_vs_ai_controls.visible = false
	hide_legacy_player_name_controls()
	create_settings_button()
	create_settings_dialog()
	ai_match_count_field.text = str(GameConfig.ai_vs_ai_match_count)
	ai_csv_log_dir_field.text = GameConfig.get_ai_vs_ai_csv_log_dir()

func hide_legacy_player_name_controls() -> void:
	var legacy_name_label: Label = get_node_or_null("VBoxContainer/NameLabel") as Label
	var legacy_name_field: LineEdit = get_node_or_null("VBoxContainer/PlayerNameField") as LineEdit
	if legacy_name_label != null:
		legacy_name_label.visible = false
	if legacy_name_field != null:
		legacy_name_field.visible = false

func create_settings_button() -> void:
	settings_button = Button.new()
	add_child(settings_button)
	settings_button.text = "⚙"
	settings_button.tooltip_text = "Settings"
	settings_button.custom_minimum_size = Vector2(44, 44)
	settings_button.size = Vector2(44, 44)
	settings_button.anchor_left = 1.0
	settings_button.anchor_right = 1.0
	settings_button.anchor_top = 0.0
	settings_button.anchor_bottom = 0.0
	settings_button.offset_left = -60.0
	settings_button.offset_right = -16.0
	settings_button.offset_top = 16.0
	settings_button.offset_bottom = 60.0
	settings_button.focus_mode = Control.FOCUS_NONE
	settings_button.pressed.connect(_on_settings_button_pressed)

func create_settings_dialog() -> void:
	settings_dialog = AcceptDialog.new()
	add_child(settings_dialog)
	settings_dialog.title = "Settings"
	settings_dialog.dialog_text = ""
	settings_dialog.exclusive = true
	settings_dialog.min_size = Vector2i(440, 320)
	settings_dialog.confirmed.connect(_on_settings_confirmed)
	settings_dialog.canceled.connect(_on_settings_canceled)

	var root := VBoxContainer.new()
	settings_dialog.add_child(root)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 14)

	var tabs := TabContainer.new()
	root.add_child(tabs)
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var general_tab := VBoxContainer.new()
	tabs.add_child(general_tab)
	general_tab.name = "General"
	general_tab.add_theme_constant_override("separation", 12)

	var name_label := Label.new()
	general_tab.add_child(name_label)
	name_label.text = "Player name"

	player_name_field = LineEdit.new()
	general_tab.add_child(player_name_field)
	player_name_field.placeholder_text = GameConfig.DEFAULT_PLAYER_NAME
	player_name_field.max_length = GameConfig.MAX_PLAYER_NAME_LENGTH

	fullscreen_check = CheckBox.new()
	general_tab.add_child(fullscreen_check)
	fullscreen_check.text = "Fullscreen"

	var language_tab := VBoxContainer.new()
	tabs.add_child(language_tab)
	language_tab.name = "Language"

	var audio_tab := VBoxContainer.new()
	tabs.add_child(audio_tab)
	audio_tab.name = "Audio"

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
	get_tree().change_scene_to_file("res://Scenes/SingleplayerMenu.tscn")

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
	PlayerSettingsStore.set_player_name(PlayerSettingsStore.get_player_name())

func _on_multiplayer_button_pressed():
	save_player_name()
	get_tree().change_scene_to_file("res://Scenes/MultiplayerMenu.tscn")

func _on_deckbuilder_button_pressed():
	save_player_name()
	get_tree().change_scene_to_file("res://Scenes/Deckbuilder.tscn")

func _on_exit_button_pressed():
	get_tree().quit()

func _on_settings_button_pressed() -> void:
	player_name_field.text = PlayerSettingsStore.get_player_name()
	fullscreen_check.button_pressed = PlayerSettingsStore.is_fullscreen_enabled()
	settings_dialog.popup_centered(Vector2i(440, 320))

func _on_settings_confirmed() -> void:
	PlayerSettingsStore.set_player_name(player_name_field.text)
	PlayerSettingsStore.set_fullscreen_enabled(fullscreen_check.button_pressed)

func _on_settings_canceled() -> void:
	player_name_field.text = PlayerSettingsStore.get_player_name()
	fullscreen_check.button_pressed = PlayerSettingsStore.is_fullscreen_enabled()
