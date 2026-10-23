extends Control

const AI_VS_AI_UNLOCK_KEY: Key = KEY_A
const AI_VS_AI_UNLOCK_PRESS_COUNT: int = 3
const MAX_AI_VS_AI_MATCH_COUNT: int = 9999
const TOP_BAR_HEIGHT: int = 60
const SETTINGS_DIALOG_SCREEN_MARGIN: int = 30
const SETTINGS_DIALOG_WIDTH: int = 540
const SETTINGS_DIALOG_BELOW_TOP_BAR_LAYER: int = -10

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
@onready var settings_dialog: AcceptDialog = $SettingsDialog
## Started by hand once the menu is really going to be seen; see _ready.
@onready var menu_music: SceneMusicCue = $MenuMusic
@onready var chords_cycle: MusicStemCycle = $ChordsCycle
@onready var general_section: SettingsSection = $SettingsDialog/Root/Tabs/General
@onready var video_section: SettingsSection = $SettingsDialog/Root/Tabs/Video
@onready var controls_section: ControlsSection = $SettingsDialog/Root/Tabs/Controls
@onready var ui_section: SettingsSection = $SettingsDialog/Root/Tabs/UI
@onready var audio_section: SettingsSection = $SettingsDialog/Root/Tabs/Audio
@onready var rebind_keys_button: Button = $SettingsDialog/Root/Tabs/Controls/Scroll/Content/RebindKeysButton
@onready var input_rebind_dialog: InputRebindDialog = $InputRebindDialog
@onready var background_lines: TextureRect = $BackgroundLines
@onready var street_view: MainMenuStreetView = $MainMenuStreetView
@onready var play_button: TextureButton = $PlayButton

const BACKGROUND_LINES_FALLBACK_BASE_DURATION: float = 1.6
const BACKGROUND_LINES_FALLBACK_MAX_DELAY: float = 1.8
const NEXT_BOSS_STAKES_FONT_SIZE: int = 22
const NEXT_BOSS_STAKES_GAP: float = 6.0
const NEXT_BOSS_STAKES_OUTLINE_SIZE: int = 8
const NEXT_BOSS_STAKES_OUTLINE_COLOR: Color = Color(0.9366637, 0.9330646, 0.89437205, 1.0)

var ai_vs_ai_unlock_presses: int = 0
var background_lines_animating: bool = false
var background_lines_elapsed: float = 0.0
var background_lines_total_duration: float = 0.0
var settings_dialog_saved_top_bar_layer: int = 0
var ai_deck_ids: Array[String] = []
var points_label: Label
var next_boss_stakes_label: Label

func _ready():
	if should_start_dedicated_server_from_launch():
		prepare_dedicated_server_launch()
		call_deferred("launch_dedicated_server_scene")
		return

	# Reaching the hub always ends any story match that was in flight - a
	# player who quit mid-fight must not have their next result reported
	# against a boss node they walked away from.
	StoryManager.clear_active_match()

	if StoryManager.should_block_hub():
		call_deferred("launch_blocking_story_node")
		return

	# A Steam invite that started the game, or was accepted mid-match, is
	# followed as soon as the hub is reachable.
	if SteamManager.has_pending_lobby_join():
		SteamManager.call_deferred("start_pending_lobby_join")
		return

	# Only past the hand-offs above: the menu is the game's first scene, and
	# its music must not start under a story that is about to take over.
	menu_music.play()
	chords_cycle.start()

	PlayerProgressStore.ensure_loaded()
	dev_tools_window.visible = false
	_connect_once(dev_tools_window.close_requested, Callable(self, "_on_dev_tools_window_close_requested"))
	input_rebind_dialog.controls_section = controls_section
	_connect_once(rebind_keys_button.pressed, Callable(self, "_on_rebind_keys_button_pressed"))
	_bind_top_bar()
	_build_next_boss_stakes_label()
	sync_dev_tools_from_config()
	_populate_ai_vs_ai_deck_options()
	_connect_once(ai_random_deck_check.toggled, Callable(self, "_on_ai_random_deck_toggled"))
	_connect_once(ai_deck_option_button.item_selected, Callable(self, "_on_ai_deck_option_selected"))
	_connect_once(ai_vs_ai_button.pressed, Callable(self, "_on_ai_vs_ai_button_pressed"))
	_connect_once(promote_stamp_values_button.pressed, Callable(self, "_on_promote_stamp_values_button_pressed"))
	_connect_once(open_ai_logs_button.pressed, Callable(self, "_on_open_ai_logs_button_pressed"))
	_connect_once(reset_balance_sessions_button.pressed, Callable(self, "_on_reset_balance_sessions_button_pressed"))
	_update_ai_vs_ai_deck_controls()
	SFXManager.play("mainmenu_drawing")
	_start_background_line_reveal()
	_connect_once(street_view.opponent_arrived, Callable(self, "_on_opponent_arrived"))

func _process(delta: float) -> void:
	if !background_lines_animating:
		return
	background_lines_elapsed += delta
	var line_material: ShaderMaterial = background_lines.material as ShaderMaterial
	if line_material != null:
		line_material.set_shader_parameter("time", background_lines_elapsed)
	if background_lines_elapsed >= background_lines_total_duration:
		background_lines_animating = false
		set_process(false)

func _start_background_line_reveal() -> void:
	var line_material: ShaderMaterial = background_lines.material as ShaderMaterial
	if line_material == null:
		return
	var base_duration_value = line_material.get_shader_parameter("base_duration")
	var max_delay_value = line_material.get_shader_parameter("max_delay")
	var base_duration: float = float(base_duration_value) if base_duration_value != null else BACKGROUND_LINES_FALLBACK_BASE_DURATION
	var max_delay: float = float(max_delay_value) if max_delay_value != null else BACKGROUND_LINES_FALLBACK_MAX_DELAY
	background_lines_total_duration = base_duration + max_delay
	background_lines_elapsed = 0.0
	line_material.set_shader_parameter("time", 0.0)
	background_lines_animating = true
	set_process(true)

func _on_opponent_arrived() -> void:
	play_button.disabled = false
	if next_boss_stakes_label != null:
		next_boss_stakes_label.visible = true

## When Play would start a boss fight, the lines under it name the boss and
## say what the fight can do to the player's rating - nothing more: the number
## goes up by this much with a win and down by that much with a loss.
func _build_next_boss_stakes_label() -> void:
	var boss_node := StoryManager.get_current_node() as BossGameStoryNode
	if boss_node == null or boss_node.boss == null:
		return
	var stakes: Dictionary = PlayerProgressStore.get_rating_stakes(float(boss_node.boss.rating))
	next_boss_stakes_label = Label.new()
	next_boss_stakes_label.name = "NextBossStakesLabel"
	next_boss_stakes_label.text = "%s\n%s" % [
		tr("RATING_NEXT_OPPONENT").format({"name": boss_node.boss.get_localized_display_name()}),
		tr("RATING_STAKES").format({"win": "%+d" % int(stakes.get("win", 0)), "loss": "%+d" % int(stakes.get("loss", 0))}),
	]
	next_boss_stakes_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_boss_stakes_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_boss_stakes_label.add_theme_font_size_override("font_size", NEXT_BOSS_STAKES_FONT_SIZE)
	next_boss_stakes_label.add_theme_color_override("font_color", UiPalette.INK)
	next_boss_stakes_label.add_theme_color_override("font_outline_color", NEXT_BOSS_STAKES_OUTLINE_COLOR)
	next_boss_stakes_label.add_theme_constant_override("outline_size", NEXT_BOSS_STAKES_OUTLINE_SIZE)
	play_button.add_child(next_boss_stakes_label)
	next_boss_stakes_label.anchor_left = 0.0
	next_boss_stakes_label.anchor_right = 1.0
	next_boss_stakes_label.anchor_top = 1.0
	next_boss_stakes_label.anchor_bottom = 1.0
	next_boss_stakes_label.offset_top = NEXT_BOSS_STAKES_GAP
	next_boss_stakes_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	next_boss_stakes_label.visible = !play_button.disabled

func launch_dedicated_server_scene() -> void:
	if get_tree():
		SceneTransition.change_scene("res://Scenes/main.tscn")

func launch_blocking_story_node() -> void:
	if get_tree():
		StoryManager.start_current_node()

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
	GlobalTopBar.show_main_menu(Callable(self, "_on_settings_button_pressed"), Callable(self, "_on_exit_button_pressed"), Callable(self, "_on_singleplayer_button_pressed"), Callable(self, "_on_multiplayer_button_pressed"))
	points_label = GlobalTopBar.points_label
	update_points_hud()

func update_points_hud() -> void:
	GlobalTopBar.refresh_points()
	if points_label == null:
		return
	if Engine.is_editor_hint():
		points_label.text = "0"
		return
	points_label.text = str(PlayerProgressStore.get_points())

func _input(event):
	if !is_dev_tools_available():
		return
	if dev_tools_window.visible:
		return
	if input_rebind_dialog.visible:
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
	SceneTransition.change_scene("res://Scenes/SingleplayerMenu.tscn")

func _on_tutorial_button_pressed():
	SceneTransition.change_scene("res://Scenes/Tutorial.tscn")

func _on_ai_vs_ai_button_pressed():
	if !is_dev_tools_available():
		return
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

func _on_multiplayer_button_pressed():
	SceneTransition.change_scene("res://Scenes/MultiplayerMenu.tscn")

func _on_collection_button_pressed():
	SceneTransition.change_scene("res://Scenes/Collection.tscn")

func _on_exit_button_pressed():
	get_tree().quit()

func _on_settings_button_pressed() -> void:
	general_section.load_all()
	video_section.load_all()
	controls_section.load_all()
	ui_section.load_all()
	audio_section.load_all()
	settings_dialog_saved_top_bar_layer = GlobalTopBar.layer
	GlobalTopBar.layer = SETTINGS_DIALOG_BELOW_TOP_BAR_LAYER
	settings_dialog.popup(_compute_settings_dialog_rect())

func _compute_settings_dialog_rect() -> Rect2i:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var top_bar_height: int = TOP_BAR_HEIGHT
	if GlobalTopBar.top_background != null:
		top_bar_height = int(GlobalTopBar.top_background.size.y)

	var dialog_height: int = maxi(
		int(settings_dialog.min_size.y),
		int(viewport_size.y) - top_bar_height - SETTINGS_DIALOG_SCREEN_MARGIN * 2
	)
	var position_x: int = maxi(0, int((viewport_size.x - SETTINGS_DIALOG_WIDTH) * 0.5))
	var position_y: int = top_bar_height + SETTINGS_DIALOG_SCREEN_MARGIN
	return Rect2i(position_x, position_y, SETTINGS_DIALOG_WIDTH, dialog_height)

func _on_settings_confirmed() -> void:
	general_section.apply_all()
	video_section.apply_all()
	controls_section.apply_all()
	ui_section.apply_all()
	audio_section.apply_all()
	SettingsDataManager.save_data()
	GlobalTopBar.layer = settings_dialog_saved_top_bar_layer

func _on_settings_canceled() -> void:
	general_section.load_all()
	video_section.load_all()
	controls_section.load_all()
	ui_section.load_all()
	audio_section.load_all()
	GlobalTopBar.layer = settings_dialog_saved_top_bar_layer

func _on_rebind_keys_button_pressed() -> void:
	input_rebind_dialog.open()
