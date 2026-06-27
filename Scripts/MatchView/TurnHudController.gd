extends RefCounted

const DIALOGUE_PANEL = preload("res://Scenes/DialoguePanel.tscn")

var canvas_layer: CanvasLayer
var tween_owner: Node

var turn_timer_limit_seconds: int = 300
var turn_timer_counter_key: int = 0
var turn_timer_gap: float = 8.0
var turn_timer_z_index: int = 961
var deck_counter_size: Vector2 = Vector2(82, 42)
var action_status_size: Vector2 = Vector2(132, 46)
var action_status_margin: float = 22.0
var action_status_cell_size: Vector2 = Vector2(36, 42)
var action_status_cell_gap: int = 7
var action_status_flip_duration: float = 0.16
var action_status_active_color: Color = Color.WHITE
var action_status_active_text_color: Color = Color(0.05, 0.05, 0.045, 1.0)
var action_status_active_border_color: Color = Color(0.12, 0.10, 0.075, 1.0)
var action_status_inactive_color: Color = Color(0.94, 0.93, 0.89, 1.0)
var action_status_blocked_color: Color = Color(0.02, 0.02, 0.02, 1.0)
var action_status_state_active: String = "active"
var action_status_state_empty: String = "empty"
var action_status_state_blocked: String = "blocked"
var end_turn_indicator_padding: float = 7.0
var end_turn_indicator_color: Color = Color(1.0, 1.0, 1.0, 0.92)
var end_turn_indicator_z_index: int = 950
var player_name_label_size: Vector2 = Vector2(180, 28)
var player_name_label_gap: float = 8.0
var player_portrait_size: Vector2 = Vector2(224, 89)
var player_portrait_margin: float = 22.0
var player_portrait_top_position: Vector2 = Vector2(70, 4)
var player_portrait_z_index: int = 928
var rules_info_button_size: Vector2 = Vector2(40, 40)
var rules_info_panel_size: Vector2 = Vector2(310, 286)
var rules_info_panel_margin: float = 24.0
var rules_info_text: String = ""

var create_digit_counter_callback: Callable
var set_digit_counter_value_callback: Callable
var end_turn_pressed_callback: Callable
var game_over_provider: Callable
var can_control_current_turn_provider: Callable
var tutorial_end_turn_allowed_provider: Callable
var show_first_turn_end_provider: Callable
var can_end_first_turn_provider: Callable
var can_switch_action_provider: Callable
var can_attach_action_provider: Callable
var can_move_action_provider: Callable
var current_turn_color_provider: Callable
var player_id_for_color_provider: Callable
var turn_timer_timeout_callback: Callable
var deck_visual_provider: Callable
var local_view_color_provider: Callable
var own_color_provider: Callable
var visible_viewport_size_provider: Callable
var board_screen_size_provider: Callable
var game_result_context_provider: Callable

var end_turn_indicator: ColorRect
var end_turn_button: Button
var action_status_container: HBoxContainer
var action_status_cells: Dictionary = {}
var action_status_labels: Dictionary = {}
var action_status_states: Dictionary = {}
var action_status_tweens: Dictionary = {}
var turn_timer_counter_container: Control
var player_clock_seconds: Dictionary = {0: 300.0, 1: 300.0}
var result_overlay: ColorRect
var result_label: Label
var player_name_labels: Dictionary = {}
var player_portrait_views: Dictionary = {}
var opponent_panel: DialoguePanel
var opponent_panel_managed_by_hud: bool = false
var rules_info_button: Button
var rules_info_panel: PanelContainer
var rules_info_label: Label
var current_player_names: Dictionary = {
	0: "Player",
	1: "Opponent",
}
var current_player_portraits: Dictionary = {
	0: PortraitLibrary.get_default_portrait_for_player_id(0),
	1: PortraitLibrary.get_default_portrait_for_player_id(1),
}

func configure(config: Dictionary) -> void:
	canvas_layer = config.get("canvas_layer", canvas_layer)
	tween_owner = config.get("tween_owner", tween_owner)
	turn_timer_limit_seconds = int(config.get("turn_timer_limit_seconds", turn_timer_limit_seconds))
	turn_timer_counter_key = int(config.get("turn_timer_counter_key", turn_timer_counter_key))
	turn_timer_gap = float(config.get("turn_timer_gap", turn_timer_gap))
	turn_timer_z_index = int(config.get("turn_timer_z_index", turn_timer_z_index))
	deck_counter_size = config.get("deck_counter_size", deck_counter_size)
	action_status_size = config.get("action_status_size", action_status_size)
	action_status_margin = float(config.get("action_status_margin", action_status_margin))
	action_status_cell_size = config.get("action_status_cell_size", action_status_cell_size)
	action_status_cell_gap = int(config.get("action_status_cell_gap", action_status_cell_gap))
	action_status_flip_duration = float(config.get("action_status_flip_duration", action_status_flip_duration))
	action_status_active_color = config.get("action_status_active_color", action_status_active_color)
	action_status_active_text_color = config.get("action_status_active_text_color", action_status_active_text_color)
	action_status_active_border_color = config.get("action_status_active_border_color", action_status_active_border_color)
	action_status_inactive_color = config.get("action_status_inactive_color", action_status_inactive_color)
	action_status_blocked_color = config.get("action_status_blocked_color", action_status_blocked_color)
	action_status_state_active = str(config.get("action_status_state_active", action_status_state_active))
	action_status_state_empty = str(config.get("action_status_state_empty", action_status_state_empty))
	action_status_state_blocked = str(config.get("action_status_state_blocked", action_status_state_blocked))
	end_turn_indicator_padding = float(config.get("end_turn_indicator_padding", end_turn_indicator_padding))
	end_turn_indicator_color = config.get("end_turn_indicator_color", end_turn_indicator_color)
	end_turn_indicator_z_index = int(config.get("end_turn_indicator_z_index", end_turn_indicator_z_index))
	player_name_label_size = config.get("player_name_label_size", player_name_label_size)
	player_name_label_gap = float(config.get("player_name_label_gap", player_name_label_gap))
	player_portrait_size = config.get("player_portrait_size", player_portrait_size)
	player_portrait_margin = float(config.get("player_portrait_margin", player_portrait_margin))
	player_portrait_top_position = config.get("player_portrait_top_position", player_portrait_top_position)
	player_portrait_z_index = int(config.get("player_portrait_z_index", player_portrait_z_index))
	rules_info_button_size = config.get("rules_info_button_size", rules_info_button_size)
	rules_info_panel_size = config.get("rules_info_panel_size", rules_info_panel_size)
	rules_info_panel_margin = float(config.get("rules_info_panel_margin", rules_info_panel_margin))
	rules_info_text = str(config.get("rules_info_text", rules_info_text))
	current_player_names = config.get("current_player_names", current_player_names)
	current_player_portraits = config.get("current_player_portraits", current_player_portraits)

	create_digit_counter_callback = config.get("create_digit_counter_callback", create_digit_counter_callback)
	set_digit_counter_value_callback = config.get("set_digit_counter_value_callback", set_digit_counter_value_callback)
	end_turn_pressed_callback = config.get("end_turn_pressed_callback", end_turn_pressed_callback)
	game_over_provider = config.get("game_over_provider", game_over_provider)
	can_control_current_turn_provider = config.get("can_control_current_turn_provider", can_control_current_turn_provider)
	tutorial_end_turn_allowed_provider = config.get("tutorial_end_turn_allowed_provider", tutorial_end_turn_allowed_provider)
	show_first_turn_end_provider = config.get("show_first_turn_end_provider", show_first_turn_end_provider)
	can_end_first_turn_provider = config.get("can_end_first_turn_provider", can_end_first_turn_provider)
	can_switch_action_provider = config.get("can_switch_action_provider", can_switch_action_provider)
	can_attach_action_provider = config.get("can_attach_action_provider", can_attach_action_provider)
	can_move_action_provider = config.get("can_move_action_provider", can_move_action_provider)
	current_turn_color_provider = config.get("current_turn_color_provider", current_turn_color_provider)
	player_id_for_color_provider = config.get("player_id_for_color_provider", player_id_for_color_provider)
	turn_timer_timeout_callback = config.get("turn_timer_timeout_callback", turn_timer_timeout_callback)
	deck_visual_provider = config.get("deck_visual_provider", deck_visual_provider)
	local_view_color_provider = config.get("local_view_color_provider", local_view_color_provider)
	own_color_provider = config.get("own_color_provider", own_color_provider)
	visible_viewport_size_provider = config.get("visible_viewport_size_provider", visible_viewport_size_provider)
	board_screen_size_provider = config.get("board_screen_size_provider", board_screen_size_provider)
	game_result_context_provider = config.get("game_result_context_provider", game_result_context_provider)

func create_end_turn_ui() -> void:
	if canvas_layer == null or !is_instance_valid(canvas_layer):
		return

	end_turn_indicator = ColorRect.new()
	canvas_layer.add_child(end_turn_indicator)
	end_turn_indicator.name = "EndTurnIndicator"
	end_turn_indicator.color = end_turn_indicator_color
	end_turn_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_turn_indicator.z_index = end_turn_indicator_z_index
	end_turn_indicator.visible = false

	end_turn_button = Button.new()
	canvas_layer.add_child(end_turn_button)
	end_turn_button.text = "END TURN"
	end_turn_button.anchor_left = 1.0
	end_turn_button.anchor_right = 1.0
	end_turn_button.anchor_top = 1.0
	end_turn_button.anchor_bottom = 1.0
	end_turn_button.offset_left = -152.0
	end_turn_button.offset_right = -24.0
	end_turn_button.offset_top = -64.0
	end_turn_button.offset_bottom = -24.0
	end_turn_button.z_index = 960
	end_turn_button.focus_mode = Control.FOCUS_NONE
	if end_turn_pressed_callback.is_valid():
		end_turn_button.pressed.connect(func(): end_turn_pressed_callback.call())
	arrange_end_turn_indicator()
	update_end_turn_button()

func arrange_end_turn_indicator() -> void:
	if end_turn_indicator == null or end_turn_button == null:
		return

	end_turn_indicator.anchor_left = end_turn_button.anchor_left
	end_turn_indicator.anchor_right = end_turn_button.anchor_right
	end_turn_indicator.anchor_top = end_turn_button.anchor_top
	end_turn_indicator.anchor_bottom = end_turn_button.anchor_bottom
	end_turn_indicator.offset_left = end_turn_button.offset_left - end_turn_indicator_padding
	end_turn_indicator.offset_right = end_turn_button.offset_right + end_turn_indicator_padding
	end_turn_indicator.offset_top = end_turn_button.offset_top - end_turn_indicator_padding
	end_turn_indicator.offset_bottom = end_turn_button.offset_bottom + end_turn_indicator_padding

func create_action_status_ui() -> void:
	if canvas_layer == null or !is_instance_valid(canvas_layer):
		return

	action_status_container = HBoxContainer.new()
	canvas_layer.add_child(action_status_container)
	action_status_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_status_container.anchor_left = 0.5
	action_status_container.anchor_right = 0.5
	action_status_container.anchor_top = 0.5
	action_status_container.anchor_bottom = 0.5
	action_status_container.custom_minimum_size = action_status_size
	action_status_container.z_index = 910
	action_status_container.add_theme_constant_override("separation", action_status_cell_gap)

	var label_settings := LabelSettings.new()
	label_settings.font_size = 25
	label_settings.font_color = action_status_active_text_color
	label_settings.outline_size = 0

	var action_letters: Dictionary = {
		"Page": "P",
		"Attach": "A",
		"Move": "M",
	}
	for action_name in ["Page", "Attach", "Move"]:
		var action_cell := PanelContainer.new()
		action_status_container.add_child(action_cell)
		action_cell.custom_minimum_size = action_status_cell_size
		action_cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		action_cell.pivot_offset = action_status_cell_size * 0.5
		action_cell.scale = Vector2.ONE

		var action_label := Label.new()
		action_cell.add_child(action_label)
		action_label.text = str(action_letters[action_name])
		action_label.custom_minimum_size = action_status_cell_size
		action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		action_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		action_label.label_settings = label_settings.duplicate()
		action_status_cells[action_name] = action_cell
		action_status_labels[action_name] = action_label

	arrange_action_status_ui()
	update_action_status_ui()

func create_turn_timer_ui() -> void:
	if !create_digit_counter_callback.is_valid():
		return
	turn_timer_counter_container = create_digit_counter_callback.call("ChessClock", turn_timer_counter_key, 4, true) as Control
	if turn_timer_counter_container == null:
		return
	turn_timer_counter_container.z_index = turn_timer_z_index
	reset_turn_timer()
	arrange_turn_timer_ui()
	update_turn_timer_visibility()

func create_result_ui() -> void:
	if canvas_layer == null or !is_instance_valid(canvas_layer):
		return

	result_overlay = ColorRect.new()
	canvas_layer.add_child(result_overlay)
	result_overlay.visible = false
	result_overlay.color = Color(0.0, 0.0, 0.0, 0.62)
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	result_overlay.anchor_right = 1.0
	result_overlay.anchor_bottom = 1.0
	result_overlay.offset_left = 0.0
	result_overlay.offset_top = 0.0
	result_overlay.offset_right = 0.0
	result_overlay.offset_bottom = 0.0
	result_overlay.z_index = 2000

	result_label = Label.new()
	result_overlay.add_child(result_label)
	result_label.anchor_right = 1.0
	result_label.anchor_bottom = 1.0
	result_label.offset_left = 0.0
	result_label.offset_top = 0.0
	result_label.offset_right = 0.0
	result_label.offset_bottom = 0.0
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label_settings := LabelSettings.new()
	label_settings.font_size = 72
	label_settings.font_color = Color(1.0, 1.0, 1.0)
	label_settings.outline_size = 8
	label_settings.outline_color = Color(0.0, 0.0, 0.0)
	result_label.label_settings = label_settings

func show_result_message(winner_color: int) -> void:
	if result_label == null or result_overlay == null:
		return

	var context: Dictionary = get_game_result_context()
	if bool(context.get("is_ai_vs_ai_batch", false)):
		result_label.text = "%s WINS!\nMATCH %d / %d" % [
			"WHITE" if winner_color == 1 else "BLACK",
			int(context.get("ai_matches_played", 0)) + 1,
			int(context.get("ai_match_count", 0)),
		]
	elif bool(context.get("side_is_null", false)):
		result_label.text = "WHITE WINS!" if winner_color == 1 else "BLACK WINS!"
	else:
		result_label.text = "YOU WON!" if winner_color == get_own_color() else "YOU LOST!"
	result_overlay.visible = true

func initialize_player_portraits() -> void:
	current_player_portraits = {
		0: PortraitLibrary.get_default_portrait_for_player_id(0),
		1: PortraitLibrary.get_default_portrait_for_player_id(1),
	}

func create_player_portrait_ui() -> void:
	ensure_opponent_panel()
	update_opponent_panel()

func create_player_name_ui() -> void:
	ensure_opponent_panel()
	update_opponent_panel()

func ensure_opponent_panel() -> void:
	if opponent_panel != null and is_instance_valid(opponent_panel):
		return
	if canvas_layer == null or !is_instance_valid(canvas_layer):
		return

	var existing_panel := canvas_layer.get_node_or_null("DialoguePanel") as DialoguePanel
	if existing_panel != null:
		opponent_panel = existing_panel
		opponent_panel_managed_by_hud = false
		return

	opponent_panel = DIALOGUE_PANEL.instantiate() as DialoguePanel
	opponent_panel.name = "OpponentPanel"
	opponent_panel.z_index = player_portrait_z_index
	canvas_layer.add_child(opponent_panel)
	opponent_panel_managed_by_hud = true

func create_rules_info_ui() -> void:
	if canvas_layer == null or !is_instance_valid(canvas_layer):
		return

	rules_info_button = Button.new()
	canvas_layer.add_child(rules_info_button)
	rules_info_button.text = "i"
	rules_info_button.tooltip_text = "Rules"
	rules_info_button.anchor_left = 1.0
	rules_info_button.anchor_right = 1.0
	rules_info_button.anchor_top = 1.0
	rules_info_button.anchor_bottom = 1.0
	var button_right_offset: float = -160.0
	if end_turn_button != null:
		button_right_offset = end_turn_button.offset_left - 8.0
	rules_info_button.offset_left = button_right_offset - rules_info_button_size.x
	rules_info_button.offset_right = button_right_offset
	rules_info_button.offset_top = end_turn_button.offset_top if end_turn_button != null else -64.0
	rules_info_button.offset_bottom = end_turn_button.offset_bottom if end_turn_button != null else -24.0
	rules_info_button.z_index = 960
	rules_info_button.focus_mode = Control.FOCUS_NONE
	rules_info_button.pressed.connect(toggle_rules_info_panel)

	rules_info_panel = PanelContainer.new()
	canvas_layer.add_child(rules_info_panel)
	rules_info_panel.visible = false
	rules_info_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	rules_info_panel.anchor_left = 0.5
	rules_info_panel.anchor_right = 0.5
	rules_info_panel.anchor_top = 0.5
	rules_info_panel.anchor_bottom = 0.5
	rules_info_panel.z_index = 970

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.055, 0.065, 0.92)
	panel_style.border_color = Color(1.0, 1.0, 1.0, 0.18)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.content_margin_left = 14
	panel_style.content_margin_top = 12
	panel_style.content_margin_right = 14
	panel_style.content_margin_bottom = 12
	rules_info_panel.add_theme_stylebox_override("panel", panel_style)

	var panel_layout := VBoxContainer.new()
	rules_info_panel.add_child(panel_layout)
	panel_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_layout.add_theme_constant_override("separation", 8)

	var title_label := Label.new()
	panel_layout.add_child(title_label)
	title_label.text = "How to Play"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.add_theme_font_size_override("font_size", 17)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82))

	rules_info_label = Label.new()
	panel_layout.add_child(rules_info_label)
	rules_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules_info_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules_info_label.text = rules_info_text
	rules_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_info_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	rules_info_label.add_theme_font_size_override("font_size", 13)
	rules_info_label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.9))

	arrange_rules_info_panel()
	update_rules_info_ui()

func update_player_name_labels() -> void:
	update_opponent_panel()

func update_player_portrait_views() -> void:
	update_opponent_panel()

func update_opponent_panel() -> void:
	ensure_opponent_panel()
	if opponent_panel == null or !is_instance_valid(opponent_panel) or !opponent_panel_managed_by_hud:
		return

	for owner_color in [1, -1]:
		if !is_card_hand_top(owner_color):
			continue

		var player_id: int = get_player_id_for_color(owner_color)
		opponent_panel.show_profile(
			get_display_name_for_player(player_id),
			get_portrait_config_for_player(player_id)
		)
		opponent_panel.set_turn_focus(owner_color == get_current_turn_color())
		return

func update_rules_info_ui() -> void:
	if rules_info_button == null:
		return

	rules_info_button.visible = !is_game_over()
	if is_game_over() and rules_info_panel != null:
		rules_info_panel.visible = false

func toggle_rules_info_panel() -> void:
	if rules_info_panel == null:
		return

	rules_info_panel.visible = !rules_info_panel.visible
	if rules_info_panel.visible:
		arrange_rules_info_panel()

func arrange_rules_info_panel() -> void:
	if rules_info_panel == null:
		return

	var viewport_size: Vector2 = get_visible_viewport_size()
	var board_screen_size: float = get_board_screen_size()
	var left_offset: float = -board_screen_size * 0.5 - rules_info_panel_margin - rules_info_panel_size.x
	var top_offset: float = -board_screen_size * 0.5
	var min_top_offset: float = -viewport_size.y * 0.5 + rules_info_panel_margin
	var max_top_offset: float = viewport_size.y * 0.5 - rules_info_panel_size.y - rules_info_panel_margin
	left_offset = max(left_offset, -viewport_size.x * 0.5 + rules_info_panel_margin)
	top_offset = clamp(top_offset, min_top_offset, max_top_offset)
	rules_info_panel.offset_left = left_offset
	rules_info_panel.offset_right = left_offset + rules_info_panel_size.x
	rules_info_panel.offset_top = top_offset
	rules_info_panel.offset_bottom = top_offset + rules_info_panel_size.y

func get_portrait_config_for_player(player_id: int) -> PortraitConfig:
	if current_player_portraits.has(player_id):
		return PortraitLibrary.config_from_data_or_default(current_player_portraits[player_id], player_id)

	var string_key: String = str(player_id)
	if current_player_portraits.has(string_key):
		return PortraitLibrary.config_from_data_or_default(current_player_portraits[string_key], player_id)

	return PortraitLibrary.get_default_portrait_for_player_id(player_id)

func get_display_name_for_player(player_id: int) -> String:
	if current_player_names.has(player_id):
		return str(current_player_names[player_id])
	var string_key: String = str(player_id)
	if current_player_names.has(string_key):
		return str(current_player_names[string_key])
	return "Player"

func update_end_turn_button() -> void:
	if end_turn_button == null:
		return
	end_turn_button.visible = !is_game_over() and get_bool(show_first_turn_end_provider, false)
	end_turn_button.disabled = !can_control_current_turn() or !get_bool(can_end_first_turn_provider, false) or !is_tutorial_end_turn_allowed()
	update_end_turn_indicator()

func update_end_turn_indicator() -> void:
	if end_turn_indicator == null:
		return
	end_turn_indicator.visible = end_turn_button != null and end_turn_button.visible and can_control_current_turn()

func update_action_status_ui() -> void:
	if action_status_container == null:
		return

	action_status_container.visible = !is_game_over()
	set_action_status_label("Page", get_bool(can_switch_action_provider, false))
	set_action_status_label("Attach", get_bool(can_attach_action_provider, false))
	set_action_status_label("Move", get_bool(can_move_action_provider, false))

func set_action_status_label(action_name: String, is_available: bool) -> void:
	var action_state: String = action_status_state_blocked
	if can_control_current_turn():
		action_state = action_status_state_active if is_available else action_status_state_empty
	set_action_status_cell_state(action_name, action_state)

func set_action_status_cell_state(action_name: String, action_state: String) -> void:
	var action_cell: PanelContainer = action_status_cells.get(action_name, null) as PanelContainer
	if action_cell == null:
		return

	var previous_state: String = str(action_status_states.get(action_name, ""))
	if previous_state == action_state:
		return
	action_status_states[action_name] = action_state

	var previous_tween: Tween = action_status_tweens.get(action_name, null) as Tween
	if previous_tween != null:
		previous_tween.kill()

	if previous_state == "" or tween_owner == null or !is_instance_valid(tween_owner):
		apply_action_status_cell_state(action_name, action_state)
		return

	action_cell.pivot_offset = action_status_cell_size * 0.5
	var tween: Tween = tween_owner.create_tween()
	action_status_tweens[action_name] = tween
	tween.finished.connect(func():
		if action_status_tweens.get(action_name, null) == tween:
			action_status_tweens.erase(action_name)
	)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(action_cell, "scale:y", 0.0, action_status_flip_duration * 0.5)
	tween.tween_callback(Callable(self, "apply_action_status_cell_state").bind(action_name, action_state))
	tween.tween_property(action_cell, "scale:y", 1.0, action_status_flip_duration * 0.5)

func apply_action_status_cell_state(action_name: String, action_state: String) -> void:
	var action_cell: PanelContainer = action_status_cells.get(action_name, null) as PanelContainer
	var action_label: Label = action_status_labels.get(action_name, null) as Label
	if action_cell == null or action_label == null:
		return

	var cell_color: Color = action_status_active_color
	var border_color: Color = action_status_active_border_color
	var label_color: Color = action_status_active_text_color
	var label_text: String = get_action_status_letter(action_name)
	if action_state == action_status_state_empty:
		cell_color = action_status_inactive_color
		label_text = ""
	elif action_state == action_status_state_blocked:
		cell_color = action_status_blocked_color
		border_color = Color(0.0, 0.0, 0.0, 1.0)
		label_text = ""

	var style_box := StyleBoxFlat.new()
	style_box.bg_color = cell_color
	style_box.border_color = border_color
	style_box.set_border_width_all(2)
	style_box.set_corner_radius_all(3)
	action_cell.add_theme_stylebox_override("panel", style_box)
	action_label.text = label_text

	var label_settings: LabelSettings = action_label.label_settings
	if label_settings != null:
		label_settings.font_color = label_color

func reset_turn_timer() -> void:
	player_clock_seconds = {0: float(turn_timer_limit_seconds), 1: float(turn_timer_limit_seconds)}
	update_turn_timer_label()
	update_turn_timer_visibility()

func sync_player_clocks(clock_state: Dictionary) -> void:
	if clock_state.is_empty():
		return
	for player_id in [0, 1]:
		var value = clock_state.get(player_id, clock_state.get(str(player_id), turn_timer_limit_seconds))
		player_clock_seconds[player_id] = maxf(float(value), 0.0)
	update_turn_timer_label()

func update_turn_timer(delta: float) -> void:
	if turn_timer_counter_container == null:
		return
	if is_game_over():
		turn_timer_counter_container.visible = false
		return

	update_turn_timer_visibility()
	if !should_run_turn_timer():
		return
	var own_player_id: int = get_player_id_for_color(get_own_color())
	player_clock_seconds[own_player_id] = maxf(float(player_clock_seconds.get(own_player_id, turn_timer_limit_seconds)) - maxf(delta, 0.0), 0.0)
	update_turn_timer_label()

func update_turn_timer_label(animate: bool = true) -> void:
	var own_player_id: int = get_player_id_for_color(get_own_color())
	var total_seconds: int = maxi(ceili(float(player_clock_seconds.get(own_player_id, turn_timer_limit_seconds))), 0)
	var timer_digits: int = floori(float(total_seconds) / 60.0) * 100 + total_seconds % 60
	set_digit_counter_value(turn_timer_counter_key, timer_digits, animate)

func update_turn_timer_visibility() -> void:
	if turn_timer_counter_container == null:
		return
	turn_timer_counter_container.visible = !is_game_over() and should_show_turn_timer()

func clear_turn_timer_timeout_pending() -> void:
	pass

func should_show_turn_timer() -> bool:
	if GameConfig.is_ai_vs_ai_batch:
		return false
	if GameConfig.is_singleplayer:
		return false
	return true

func should_run_turn_timer() -> bool:
	if !should_show_turn_timer():
		return false
	return can_control_current_turn() and is_current_turn_human_controlled()

func is_current_turn_human_controlled() -> bool:
	var player_id: int = get_player_id_for_color(get_current_turn_color())
	if GameConfig.is_singleplayer:
		return GameConfig.get_player_controller(player_id) == GameConfig.CONTROLLER_HUMAN
	return true

func arrange_action_status_ui() -> void:
	if action_status_container == null:
		return

	action_status_container.anchor_left = 1.0
	action_status_container.anchor_right = 1.0
	action_status_container.anchor_top = 1.0
	action_status_container.anchor_bottom = 1.0

	var button_center_x: float = -action_status_margin - action_status_size.x * 0.5
	var bottom_offset: float = -action_status_margin - action_status_size.y
	if end_turn_button != null:
		button_center_x = (end_turn_button.offset_left + end_turn_button.offset_right) * 0.5
		bottom_offset = end_turn_button.offset_top - 8.0
	var left_offset: float = button_center_x - action_status_size.x * 0.5
	var top_offset: float = bottom_offset - action_status_size.y
	action_status_container.offset_left = left_offset
	action_status_container.offset_right = left_offset + action_status_size.x
	action_status_container.offset_top = top_offset
	action_status_container.offset_bottom = bottom_offset

func arrange_turn_timer_ui() -> void:
	if turn_timer_counter_container == null:
		return

	turn_timer_counter_container.anchor_left = 1.0
	turn_timer_counter_container.anchor_right = 1.0
	turn_timer_counter_container.anchor_top = 1.0
	turn_timer_counter_container.anchor_bottom = 1.0

	var button_center_x: float = -action_status_margin - deck_counter_size.x * 0.5
	var bottom_offset: float = -action_status_margin - action_status_size.y - turn_timer_gap
	if action_status_container != null:
		button_center_x = (action_status_container.offset_left + action_status_container.offset_right) * 0.5
		bottom_offset = action_status_container.offset_top - turn_timer_gap
	elif end_turn_button != null:
		button_center_x = (end_turn_button.offset_left + end_turn_button.offset_right) * 0.5
		bottom_offset = end_turn_button.offset_top - turn_timer_gap

	var timer_size: Vector2 = turn_timer_counter_container.size
	var left_offset: float = button_center_x - timer_size.x * 0.5
	var top_offset: float = bottom_offset - timer_size.y
	turn_timer_counter_container.offset_left = left_offset
	turn_timer_counter_container.offset_right = left_offset + timer_size.x
	turn_timer_counter_container.offset_top = top_offset
	turn_timer_counter_container.offset_bottom = bottom_offset

func get_action_status_letter(action_name: String) -> String:
	match action_name:
		"Switch":
			return "S"
		"Page":
			return "P"
		"Attach":
			return "A"
		"Move":
			return "M"
	return ""

func set_digit_counter_value(owner_key: int, count: int, animate: bool) -> void:
	if set_digit_counter_value_callback.is_valid():
		set_digit_counter_value_callback.call(owner_key, count, animate)

func is_game_over() -> bool:
	return get_bool(game_over_provider, false)

func can_control_current_turn() -> bool:
	return get_bool(can_control_current_turn_provider, false)

func is_tutorial_end_turn_allowed() -> bool:
	return get_bool(tutorial_end_turn_allowed_provider, true)

func get_current_turn_color() -> int:
	return get_int(current_turn_color_provider, 1)

func get_player_id_for_color(owner_color: int) -> int:
	if player_id_for_color_provider.is_valid():
		return int(player_id_for_color_provider.call(owner_color))
	return 0

func get_deck_visual(owner_color: int) -> CardVisual:
	if deck_visual_provider.is_valid():
		return deck_visual_provider.call(owner_color) as CardVisual
	return null

func is_card_hand_top(owner_color: int) -> bool:
	return owner_color != get_local_view_color()

func get_local_view_color() -> int:
	return get_int(local_view_color_provider, 1)

func get_own_color() -> int:
	return get_int(own_color_provider, 1)

func get_visible_viewport_size() -> Vector2:
	if visible_viewport_size_provider.is_valid():
		return visible_viewport_size_provider.call()
	if canvas_layer != null and is_instance_valid(canvas_layer):
		return canvas_layer.get_viewport().get_visible_rect().size
	return Vector2.ZERO

func get_board_screen_size() -> float:
	if board_screen_size_provider.is_valid():
		return float(board_screen_size_provider.call())
	return 0.0

func get_game_result_context() -> Dictionary:
	if game_result_context_provider.is_valid():
		return game_result_context_provider.call()
	return {}

func get_bool(provider: Callable, fallback: bool) -> bool:
	if provider.is_valid():
		return bool(provider.call())
	return fallback

func get_int(provider: Callable, fallback: int) -> int:
	if provider.is_valid():
		return int(provider.call())
	return fallback
