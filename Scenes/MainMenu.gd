extends Control

const AI_VS_AI_UNLOCK_KEY: Key = KEY_A
const AI_VS_AI_UNLOCK_PRESS_COUNT: int = 3
const MAX_AI_VS_AI_MATCH_COUNT: int = 9999
const TOP_BAR_HEIGHT: int = 60

@onready var ai_vs_ai_controls: Control = $AIVsAIControls
@onready var ai_match_count_field: LineEdit = $AIVsAIControls/MatchCountField
@onready var ai_csv_log_dir_field: LineEdit = $AIVsAIControls/CsvLogDirField

var ai_vs_ai_unlock_presses: int = 0
var top_bar: HBoxContainer
var settings_button: Button
var settings_dialog: AcceptDialog
var player_name_field: LineEdit
var fullscreen_check: CheckBox
var points_hud: HBoxContainer
var points_label: Label

func _ready():
	PlayerSettingsStore.ensure_loaded()
	PlayerProgressStore.ensure_loaded()
	ai_vs_ai_controls.visible = false
	hide_legacy_player_name_controls()
	hide_legacy_exit_button()
	_bind_top_bar()
	create_settings_dialog()
	ai_match_count_field.text = str(GameConfig.ai_vs_ai_match_count)
	ai_csv_log_dir_field.text = GameConfig.get_ai_vs_ai_csv_log_dir()

func _connect_once(signal_value: Signal, callable: Callable) -> void:
	if !signal_value.is_connected(callable):
		signal_value.connect(callable)

func _mark_generated_ui(_node: Node) -> void:
	pass

func _bind_top_bar() -> void:
	top_bar = $TopBar
	settings_button = $TopBar/SettingsButton
	points_hud = $TopBar/PointsHud
	points_label = $TopBar/PointsHud/PointsLabel
	_connect_once(settings_button.pressed, Callable(self, "_on_settings_button_pressed"))
	_connect_once($TopBar/ExitButton.pressed, Callable(self, "_on_exit_button_pressed"))
	update_points_hud()

func hide_legacy_player_name_controls() -> void:
	var legacy_name_label: Label = get_node_or_null("VBoxContainer/NameLabel") as Label
	var legacy_name_field: LineEdit = get_node_or_null("VBoxContainer/PlayerNameField") as LineEdit
	if legacy_name_label != null:
		legacy_name_label.visible = false
	if legacy_name_field != null:
		legacy_name_field.visible = false

func hide_legacy_exit_button() -> void:
	var legacy_exit_button: Button = get_node_or_null("VBoxContainer/ExitButton") as Button
	if legacy_exit_button != null:
		legacy_exit_button.visible = false

func create_top_bar() -> void:
	var top_background := ColorRect.new()
	add_child(top_background)
	_mark_generated_ui(top_background)
	top_background.anchor_left = 0.0
	top_background.anchor_right = 1.0
	top_background.anchor_top = 0.0
	top_background.anchor_bottom = 0.0
	top_background.offset_left = 0.0
	top_background.offset_top = 0.0
	top_background.offset_right = 0.0
	top_background.offset_bottom = TOP_BAR_HEIGHT
	top_background.color = Color(0.36, 0.32, 0.32, 1.0)

	top_bar = HBoxContainer.new()
	add_child(top_bar)
	_mark_generated_ui(top_bar)
	top_bar.anchor_left = 0.0
	top_bar.anchor_right = 1.0
	top_bar.anchor_top = 0.0
	top_bar.anchor_bottom = 0.0
	top_bar.offset_left = 24.0
	top_bar.offset_right = -24.0
	top_bar.offset_top = 10.0
	top_bar.offset_bottom = TOP_BAR_HEIGHT - 8.0
	top_bar.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_bar.add_theme_constant_override("separation", 12)

	var top_spacer := Control.new()
	top_bar.add_child(top_spacer)
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func create_settings_button() -> void:
	settings_button = Button.new()
	top_bar.add_child(settings_button)
	settings_button.text = "⚙"
	settings_button.tooltip_text = "Settings"
	settings_button.text = "Settings"
	settings_button.custom_minimum_size = Vector2(110, 40)
	settings_button.focus_mode = Control.FOCUS_NONE
	settings_button.pressed.connect(_on_settings_button_pressed)

	var exit_button := Button.new()
	top_bar.add_child(exit_button)
	exit_button.text = "Exit"
	exit_button.custom_minimum_size = Vector2(92, 40)
	exit_button.focus_mode = Control.FOCUS_NONE
	exit_button.pressed.connect(_on_exit_button_pressed)

func create_points_hud() -> void:
	points_hud = HBoxContainer.new()
	top_bar.add_child(points_hud)
	points_hud.custom_minimum_size = Vector2(116, 38)
	points_hud.alignment = BoxContainer.ALIGNMENT_END
	points_hud.add_theme_constant_override("separation", 8)

	var point_icon := PanelContainer.new()
	points_hud.add_child(point_icon)
	point_icon.custom_minimum_size = Vector2(18, 18)
	point_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = Color(1.0, 0.82, 0.12)
	icon_style.border_color = Color(0.58, 0.42, 0.02)
	icon_style.border_width_left = 1
	icon_style.border_width_top = 1
	icon_style.border_width_right = 1
	icon_style.border_width_bottom = 1
	icon_style.corner_radius_top_left = 9
	icon_style.corner_radius_top_right = 9
	icon_style.corner_radius_bottom_left = 9
	icon_style.corner_radius_bottom_right = 9
	point_icon.add_theme_stylebox_override("panel", icon_style)

	points_label = Label.new()
	points_hud.add_child(points_label)
	points_label.custom_minimum_size = Vector2(78, 28)
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	points_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_label.add_theme_font_size_override("font_size", 20)
	points_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82))
	update_points_hud()

func update_points_hud() -> void:
	if points_label == null:
		return
	if Engine.is_editor_hint():
		points_label.text = "0"
		return
	points_label.text = str(PlayerProgressStore.get_points())

func create_settings_dialog() -> void:
	settings_dialog = AcceptDialog.new()
	add_child(settings_dialog)
	_mark_generated_ui(settings_dialog)
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
