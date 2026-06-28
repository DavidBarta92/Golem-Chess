extends Control

const AI_VS_AI_UNLOCK_KEY: Key = KEY_A
const AI_VS_AI_UNLOCK_PRESS_COUNT: int = 3
const MAX_AI_VS_AI_MATCH_COUNT: int = 9999
const TOP_BAR_HEIGHT: int = 60
const COIN_TEXTURE: Texture2D = preload("res://Assets/coin.svg")
const FILM_GRAIN_SLIDER_MIN: float = 0.0
const FILM_GRAIN_SLIDER_MAX: float = 0.16
const FILM_GRAIN_SLIDER_STEP: float = 0.005

@onready var ai_vs_ai_controls: Control = $AIVsAIControls
@onready var dev_tools_window: Window = $DevToolsWindow
@onready var ai_match_count_field: LineEdit = $DevToolsWindow/DevToolsRoot/AIVsAISection/AIVsAIControls/MatchCountField
@onready var ai_csv_log_dir_field: LineEdit = $DevToolsWindow/DevToolsRoot/AIVsAISection/CsvLogDirField
@onready var ai_fast_mode_check: CheckBox = $DevToolsWindow/DevToolsRoot/AIVsAISection/AIVsAIControls/FastModeCheck
@onready var ai_random_deck_check: CheckBox = $DevToolsWindow/DevToolsRoot/AIVsAISection/AIVsAIControls/RandomDeckCheck
@onready var ai_vs_ai_button: Button = $DevToolsWindow/DevToolsRoot/AIVsAISection/AIVsAIControls/AIVsAIButton
@onready var ai_deck_option_button: OptionButton = $DevToolsWindow/DevToolsRoot/AIVsAISection/AIDeckOptionButton
@onready var promote_stamp_values_button: Button = $DevToolsWindow/DevToolsRoot/BalanceSection/BalanceButtons/PromoteStampValuesButton
@onready var open_ai_logs_button: Button = $DevToolsWindow/DevToolsRoot/BalanceSection/BalanceButtons/OpenLogsButton
@onready var reset_balance_sessions_button: Button = $DevToolsWindow/DevToolsRoot/BalanceSection/BalanceButtons/ResetSessionsButton
@onready var balance_status_label: Label = $DevToolsWindow/DevToolsRoot/BalanceSection/BalanceStatusLabel

var ai_vs_ai_unlock_presses: int = 0
var ai_deck_ids: Array[String] = []
var top_bar: HBoxContainer
var settings_button: Button
var settings_dialog: AcceptDialog
var player_name_field: LineEdit
var fullscreen_check: CheckBox
var resolution_option_button: OptionButton
var fps_limit_option_button: OptionButton
var film_grain_intensity_slider: HSlider
var film_grain_intensity_value_label: Label
var last_move_arrow_check: CheckBox
var enemy_attack_markers_check: CheckBox
var points_hud: Control
var points_label: Label
var resolution_options: Array[Vector2i] = []
var fps_limit_options: Array[int] = []

func _ready():
	if should_start_dedicated_server_from_launch():
		prepare_dedicated_server_launch()
		call_deferred("launch_dedicated_server_scene")
		return

	PlayerSettingsStore.ensure_loaded()
	PlayerProgressStore.ensure_loaded()
	ai_vs_ai_controls.visible = false
	dev_tools_window.visible = false
	_connect_once(dev_tools_window.close_requested, Callable(self, "_on_dev_tools_window_close_requested"))
	hide_legacy_player_name_controls()
	hide_legacy_exit_button()
	_bind_top_bar()
	_bind_main_menu_buttons()
	create_settings_dialog()
	sync_dev_tools_from_config()
	_populate_ai_vs_ai_deck_options()
	_connect_once(ai_random_deck_check.toggled, Callable(self, "_on_ai_random_deck_toggled"))
	_connect_once(ai_deck_option_button.item_selected, Callable(self, "_on_ai_deck_option_selected"))
	_connect_once(ai_vs_ai_button.pressed, Callable(self, "_on_ai_vs_ai_button_pressed"))
	_connect_once(promote_stamp_values_button.pressed, Callable(self, "_on_promote_stamp_values_button_pressed"))
	_connect_once(open_ai_logs_button.pressed, Callable(self, "_on_open_ai_logs_button_pressed"))
	_connect_once(reset_balance_sessions_button.pressed, Callable(self, "_on_reset_balance_sessions_button_pressed"))
	_update_ai_vs_ai_deck_controls()

func launch_dedicated_server_scene() -> void:
	if get_tree():
		SceneTransition.change_scene("res://Scenes/main.tscn")

func should_start_dedicated_server_from_launch() -> bool:
	if GameConfig.is_dedicated_server or OS.has_feature("dedicated_server"):
		return true
	for argument in get_network_command_line_arguments():
		var normalized_argument: String = str(argument).strip_edges().to_lower()
		if normalized_argument == "--golem-server" or normalized_argument == "--server" or normalized_argument == "--dedicated-server":
			return true
	var env_server: String = OS.get_environment("GOLEM_SERVER").strip_edges().to_lower()
	return env_server == "1" or env_server == "true" or env_server == "yes"

func prepare_dedicated_server_launch() -> void:
	GameConfig.is_singleplayer = false
	GameConfig.is_hosting = false
	GameConfig.is_dedicated_server = true
	GameConfig.set_multiplayer_provider(GameConfig.MULTIPLAYER_PROVIDER_CUSTOM_SERVER)
	GameConfig.set_matchmaking_mode(GameConfig.MATCHMAKING_MODE_ROOM_LIST)
	apply_dedicated_server_port_override()
	DebugLog.network("MainMenu resolved dedicated server launch on UDP port %d." % GameConfig.server_port)

func apply_dedicated_server_port_override() -> void:
	var arguments: Array[String] = get_network_command_line_arguments()
	for index in range(arguments.size()):
		var argument: String = str(arguments[index]).strip_edges()
		var normalized_argument: String = argument.to_lower()
		if normalized_argument.begins_with("--port="):
			GameConfig.set_server_port(argument.substr("--port=".length()))
		elif normalized_argument.begins_with("--server-port="):
			GameConfig.set_server_port(argument.substr("--server-port=".length()))
		elif normalized_argument == "--port" or normalized_argument == "--server-port":
			if index + 1 < arguments.size():
				GameConfig.set_server_port(arguments[index + 1])

	var env_port: String = OS.get_environment("GOLEM_PORT").strip_edges()
	if !env_port.is_empty():
		GameConfig.set_server_port(env_port)

func get_network_command_line_arguments() -> Array[String]:
	var arguments: Array[String] = []
	for argument in OS.get_cmdline_args():
		arguments.append(str(argument))
	for argument in OS.get_cmdline_user_args():
		var user_argument: String = str(argument)
		if !arguments.has(user_argument):
			arguments.append(user_argument)
	return arguments

func _connect_once(signal_value: Signal, callable: Callable) -> void:
	if !signal_value.is_connected(callable):
		signal_value.connect(callable)

func _bind_top_bar() -> void:
	top_bar = $TopBar
	settings_button = $TopBar/SettingsButton
	points_hud = $TopBar/PointsHud
	points_label = $TopBar/PointsHud/PointsLabel
	_connect_once(settings_button.pressed, Callable(self, "_on_settings_button_pressed"))
	_connect_once($TopBar/ExitButton.pressed, Callable(self, "_on_exit_button_pressed"))
	update_points_hud()

func _bind_main_menu_buttons() -> void:
	var collection_button := get_node_or_null("VBoxContainer/CollectionButton") as Button
	if collection_button != null:
		collection_button.text = "Collection"
		_connect_once(collection_button.pressed, Callable(self, "_on_collection_button_pressed"))

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
	var points_hud_container := HBoxContainer.new()
	points_hud = points_hud_container
	top_bar.add_child(points_hud_container)
	points_hud_container.custom_minimum_size = Vector2(116, 38)
	points_hud_container.alignment = BoxContainer.ALIGNMENT_END
	points_hud_container.add_theme_constant_override("separation", 8)

	var point_icon := TextureRect.new()
	points_hud_container.add_child(point_icon)
	point_icon.custom_minimum_size = Vector2(24, 24)
	point_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	point_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	point_icon.texture = COIN_TEXTURE
	point_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	point_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	points_label = Label.new()
	points_hud_container.add_child(points_label)
	points_label.custom_minimum_size = Vector2(70, 28)
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
	settings_dialog.title = "Settings"
	settings_dialog.dialog_text = ""
	settings_dialog.exclusive = true
	settings_dialog.min_size = Vector2i(540, 420)
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

	var video_tab := VBoxContainer.new()
	tabs.add_child(video_tab)
	video_tab.name = "Video"
	video_tab.add_theme_constant_override("separation", 12)

	fullscreen_check = CheckBox.new()
	video_tab.add_child(fullscreen_check)
	fullscreen_check.text = "Fullscreen"

	var resolution_label := Label.new()
	video_tab.add_child(resolution_label)
	resolution_label.text = "Resolution"

	resolution_option_button = OptionButton.new()
	video_tab.add_child(resolution_option_button)
	resolution_option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	populate_resolution_options()

	var fps_limit_label := Label.new()
	video_tab.add_child(fps_limit_label)
	fps_limit_label.text = "FPS limit"

	fps_limit_option_button = OptionButton.new()
	video_tab.add_child(fps_limit_option_button)
	fps_limit_option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	populate_fps_limit_options()

	var film_grain_label := Label.new()
	video_tab.add_child(film_grain_label)
	film_grain_label.text = "Film grain intensity"

	var film_grain_row := HBoxContainer.new()
	video_tab.add_child(film_grain_row)
	film_grain_row.add_theme_constant_override("separation", 12)

	film_grain_intensity_slider = HSlider.new()
	film_grain_row.add_child(film_grain_intensity_slider)
	film_grain_intensity_slider.min_value = FILM_GRAIN_SLIDER_MIN
	film_grain_intensity_slider.max_value = FILM_GRAIN_SLIDER_MAX
	film_grain_intensity_slider.step = FILM_GRAIN_SLIDER_STEP
	film_grain_intensity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_connect_once(film_grain_intensity_slider.value_changed, Callable(self, "_on_film_grain_intensity_slider_changed"))

	film_grain_intensity_value_label = Label.new()
	film_grain_row.add_child(film_grain_intensity_value_label)
	film_grain_intensity_value_label.custom_minimum_size = Vector2(58, 0)
	film_grain_intensity_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	film_grain_intensity_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var ui_tab := VBoxContainer.new()
	tabs.add_child(ui_tab)
	ui_tab.name = "UI"
	ui_tab.add_theme_constant_override("separation", 12)

	last_move_arrow_check = CheckBox.new()
	ui_tab.add_child(last_move_arrow_check)
	last_move_arrow_check.text = "Show last move arrow"

	enemy_attack_markers_check = CheckBox.new()
	ui_tab.add_child(enemy_attack_markers_check)
	enemy_attack_markers_check.text = "Show enemy attack highlights"

	var language_tab := VBoxContainer.new()
	tabs.add_child(language_tab)
	language_tab.name = "Language"

	var audio_tab := VBoxContainer.new()
	tabs.add_child(audio_tab)
	audio_tab.name = "Audio"

func _input(event):
	if !is_dev_tools_available():
		return
	if dev_tools_window.visible:
		return
	if get_viewport().gui_get_focus_owner() is LineEdit:
		return

	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or !key_event.pressed or key_event.echo:
		return

	if key_event.keycode == AI_VS_AI_UNLOCK_KEY:
		ai_vs_ai_unlock_presses += 1
		if ai_vs_ai_unlock_presses >= AI_VS_AI_UNLOCK_PRESS_COUNT:
			show_dev_tools_window()
	else:
		ai_vs_ai_unlock_presses = 0

func is_dev_tools_available() -> bool:
	return OS.is_debug_build()

func show_dev_tools_window() -> void:
	sync_dev_tools_from_config()
	_populate_ai_vs_ai_deck_options()
	_update_ai_vs_ai_deck_controls()
	ai_vs_ai_unlock_presses = 0
	var target_size := Vector2i(760, 430)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	dev_tools_window.size = target_size
	dev_tools_window.position = Vector2i(
		maxi(0, int((viewport_size.x - float(target_size.x)) * 0.5)),
		maxi(0, int((viewport_size.y - float(target_size.y)) * 0.5))
	)
	dev_tools_window.visible = true
	ai_match_count_field.grab_focus()

func sync_dev_tools_from_config() -> void:
	ai_match_count_field.text = str(GameConfig.ai_vs_ai_match_count)
	ai_csv_log_dir_field.text = GameConfig.get_ai_vs_ai_csv_log_dir()
	ai_fast_mode_check.button_pressed = GameConfig.ai_vs_ai_fast_mode
	ai_random_deck_check.button_pressed = GameConfig.ai_vs_ai_use_random_database_decks
	if balance_status_label != null:
		balance_status_label.text = "Balance sessions are saved during AI vs AI runs."

func _on_dev_tools_window_close_requested() -> void:
	dev_tools_window.hide()
	ai_vs_ai_unlock_presses = 0

func _on_singleplayer_button_pressed():
	save_player_name()
	SceneTransition.change_scene("res://Scenes/SingleplayerMenu.tscn")

func _on_tutorial_button_pressed():
	save_player_name()
	SceneTransition.change_scene("res://Scenes/Tutorial.tscn")

func _on_ai_vs_ai_button_pressed():
	if !is_dev_tools_available():
		return
	save_player_name()
	var match_count: int = get_ai_vs_ai_match_count()
	GameConfig.is_singleplayer = true
	GameConfig.is_hosting = true
	GameConfig.server_ip = ""
	GameConfig.set_ai_vs_ai_csv_log_dir(ai_csv_log_dir_field.text)
	GameConfig.set_ai_vs_ai_fast_mode(ai_fast_mode_check.button_pressed)
	GameConfig.set_ai_vs_ai_use_random_database_decks(ai_random_deck_check.button_pressed)
	if !ai_random_deck_check.button_pressed:
		var selected_deck_id: String = get_selected_ai_vs_ai_deck_id()
		if !selected_deck_id.is_empty():
			GameConfig.select_deck_for_both_players(selected_deck_id)
	GameConfig.start_ai_vs_ai_batch(match_count)
	SceneTransition.change_scene("res://Scenes/main.tscn")

func _on_promote_stamp_values_button_pressed() -> void:
	if !is_dev_tools_available():
		return

	GameConfig.set_ai_vs_ai_csv_log_dir(ai_csv_log_dir_field.text)
	var result: Dictionary = StampBalanceStore.promote_unpromoted_sessions(GameConfig.get_ai_vs_ai_csv_log_dir())
	var merged_sessions: Array = result.get("merged_sessions", [])
	var skipped_sessions: Array = result.get("skipped_sessions", [])
	var failed_sessions: Array = result.get("failed_sessions", [])
	if bool(result.get("ok", false)):
		balance_status_label.text = "Promoted %d session(s). Skipped %d, failed %d." % [
			merged_sessions.size(),
			skipped_sessions.size(),
			failed_sessions.size(),
		]
	else:
		balance_status_label.text = "Could not save promoted stamp values."

func _on_open_ai_logs_button_pressed() -> void:
	if !is_dev_tools_available():
		return

	GameConfig.set_ai_vs_ai_csv_log_dir(ai_csv_log_dir_field.text)
	var absolute_path: String = StampBalanceStore.globalize_path(GameConfig.get_ai_vs_ai_csv_log_dir())
	DirAccess.make_dir_recursive_absolute(absolute_path)
	OS.shell_open(absolute_path)
	balance_status_label.text = "Opened AI log folder."

func _on_reset_balance_sessions_button_pressed() -> void:
	if !is_dev_tools_available():
		return

	GameConfig.set_ai_vs_ai_csv_log_dir(ai_csv_log_dir_field.text)
	var deleted_count: int = StampBalanceStore.delete_session_files(GameConfig.get_ai_vs_ai_csv_log_dir())
	balance_status_label.text = "Deleted %d balance session file(s). CSV logs were kept." % deleted_count

func get_ai_vs_ai_match_count() -> int:
	var match_count: int = int(ai_match_count_field.text.strip_edges())
	if match_count < 1:
		return 1
	if match_count > MAX_AI_VS_AI_MATCH_COUNT:
		return MAX_AI_VS_AI_MATCH_COUNT
	return match_count

func _populate_ai_vs_ai_deck_options() -> void:
	if ai_deck_option_button == null:
		return

	ai_deck_option_button.clear()
	ai_deck_ids.clear()

	var all_decks: Array = PlayerDeckStore.list_decks()
	var playable_decks: Array = PlayerDeckStore.list_playable_decks()
	if playable_decks.is_empty():
		var empty_text: String = "No saved codexes" if all_decks.is_empty() else "No complete codexes"
		ai_deck_option_button.add_item(empty_text)
		ai_deck_option_button.disabled = true
		return

	var selected_index: int = 0
	var current_deck_id: String = GameConfig.get_selected_ai_deck_id()
	for deck in playable_decks:
		if !(deck is Dictionary):
			continue
		var deck_id: String = str(deck.get("deck_id", ""))
		if deck_id.is_empty():
			continue
		ai_deck_ids.append(deck_id)
		ai_deck_option_button.add_item(str(deck.get("name", "Unnamed codex")))
		if deck_id == current_deck_id:
			selected_index = ai_deck_ids.size() - 1

	if !ai_deck_ids.is_empty():
		ai_deck_option_button.select(selected_index)

func get_selected_ai_vs_ai_deck_id() -> String:
	var selected_index: int = ai_deck_option_button.selected
	if selected_index < 0 or selected_index >= ai_deck_ids.size():
		return ""
	return ai_deck_ids[selected_index]

func _on_ai_deck_option_selected(_index: int) -> void:
	var selected_deck_id: String = get_selected_ai_vs_ai_deck_id()
	if !selected_deck_id.is_empty():
		GameConfig.set_selected_ai_deck_id(selected_deck_id)

func _on_ai_random_deck_toggled(enabled: bool) -> void:
	GameConfig.set_ai_vs_ai_use_random_database_decks(enabled)
	_update_ai_vs_ai_deck_controls()

func _update_ai_vs_ai_deck_controls() -> void:
	if ai_deck_option_button == null:
		return
	ai_deck_option_button.disabled = ai_random_deck_check.button_pressed or ai_deck_ids.is_empty()
	if ai_random_deck_check.button_pressed:
		ai_deck_option_button.tooltip_text = "Random database codexes are enabled."
	else:
		ai_deck_option_button.tooltip_text = "Both AI players use this saved codex."

func save_player_name() -> void:
	PlayerSettingsStore.set_player_name(PlayerSettingsStore.get_player_name())

func _on_multiplayer_button_pressed():
	save_player_name()
	SceneTransition.change_scene("res://Scenes/MultiplayerMenu.tscn")

func _on_collection_button_pressed():
	save_player_name()
	SceneTransition.change_scene("res://Scenes/Collection.tscn")

func _on_exit_button_pressed():
	get_tree().quit()

func _on_settings_button_pressed() -> void:
	player_name_field.text = PlayerSettingsStore.get_player_name()
	fullscreen_check.button_pressed = PlayerSettingsStore.is_fullscreen_enabled()
	select_current_resolution_option()
	select_current_fps_limit_option()
	film_grain_intensity_slider.value = PlayerSettingsStore.get_film_grain_intensity()
	update_film_grain_intensity_value_label(film_grain_intensity_slider.value)
	last_move_arrow_check.button_pressed = PlayerSettingsStore.is_last_move_arrow_enabled()
	enemy_attack_markers_check.button_pressed = PlayerSettingsStore.is_enemy_attack_markers_enabled()
	settings_dialog.popup_centered(Vector2i(540, 420))

func _on_settings_confirmed() -> void:
	PlayerSettingsStore.set_player_name(player_name_field.text)
	PlayerSettingsStore.set_fullscreen_enabled(fullscreen_check.button_pressed)
	PlayerSettingsStore.set_window_resolution(get_selected_window_resolution())
	PlayerSettingsStore.set_fps_limit(get_selected_fps_limit())
	PlayerSettingsStore.set_film_grain_intensity(float(film_grain_intensity_slider.value))
	PlayerSettingsStore.set_last_move_arrow_enabled(last_move_arrow_check.button_pressed)
	PlayerSettingsStore.set_enemy_attack_markers_enabled(enemy_attack_markers_check.button_pressed)

func _on_settings_canceled() -> void:
	player_name_field.text = PlayerSettingsStore.get_player_name()
	fullscreen_check.button_pressed = PlayerSettingsStore.is_fullscreen_enabled()
	select_current_resolution_option()
	select_current_fps_limit_option()
	film_grain_intensity_slider.value = PlayerSettingsStore.get_film_grain_intensity()
	update_film_grain_intensity_value_label(film_grain_intensity_slider.value)
	last_move_arrow_check.button_pressed = PlayerSettingsStore.is_last_move_arrow_enabled()
	enemy_attack_markers_check.button_pressed = PlayerSettingsStore.is_enemy_attack_markers_enabled()

func _on_film_grain_intensity_slider_changed(value: float) -> void:
	update_film_grain_intensity_value_label(value)

func update_film_grain_intensity_value_label(value: float) -> void:
	if film_grain_intensity_value_label == null:
		return
	film_grain_intensity_value_label.text = "%.1f%%" % (value * 100.0)

func populate_resolution_options() -> void:
	if resolution_option_button == null:
		return

	resolution_option_button.clear()
	resolution_options = PlayerSettingsStore.get_supported_window_resolutions()
	for resolution in resolution_options:
		resolution_option_button.add_item(format_resolution_label(resolution))
	select_current_resolution_option()

func select_current_resolution_option() -> void:
	if resolution_option_button == null:
		return

	var current_resolution: Vector2i = PlayerSettingsStore.get_window_resolution()
	var selected_index: int = resolution_options.find(current_resolution)
	if selected_index < 0:
		resolution_options.append(current_resolution)
		resolution_option_button.add_item(format_resolution_label(current_resolution))
		selected_index = resolution_options.size() - 1
	resolution_option_button.select(selected_index)

func get_selected_window_resolution() -> Vector2i:
	if resolution_option_button == null:
		return PlayerSettingsStore.get_window_resolution()
	var selected_index: int = resolution_option_button.selected
	if selected_index < 0 or selected_index >= resolution_options.size():
		return PlayerSettingsStore.get_window_resolution()
	return resolution_options[selected_index]

func format_resolution_label(resolution: Vector2i) -> String:
	return "%d x %d" % [resolution.x, resolution.y]

func populate_fps_limit_options() -> void:
	if fps_limit_option_button == null:
		return

	fps_limit_option_button.clear()
	fps_limit_options = PlayerSettingsStore.get_supported_fps_limits()
	for fps_limit in fps_limit_options:
		fps_limit_option_button.add_item(format_fps_limit_label(fps_limit))
	select_current_fps_limit_option()

func select_current_fps_limit_option() -> void:
	if fps_limit_option_button == null:
		return

	var current_fps_limit: int = PlayerSettingsStore.get_fps_limit()
	var selected_index: int = fps_limit_options.find(current_fps_limit)
	if selected_index < 0:
		fps_limit_options.append(current_fps_limit)
		fps_limit_option_button.add_item(format_fps_limit_label(current_fps_limit))
		selected_index = fps_limit_options.size() - 1
	fps_limit_option_button.select(selected_index)

func get_selected_fps_limit() -> int:
	if fps_limit_option_button == null:
		return PlayerSettingsStore.get_fps_limit()
	var selected_index: int = fps_limit_option_button.selected
	if selected_index < 0 or selected_index >= fps_limit_options.size():
		return PlayerSettingsStore.get_fps_limit()
	return fps_limit_options[selected_index]

func format_fps_limit_label(fps_limit: int) -> String:
	if fps_limit <= 0:
		return "Default / VSync"
	return "%d FPS" % fps_limit
