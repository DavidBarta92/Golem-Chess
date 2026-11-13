extends RefCounted

# The board carries no scale of its own: its size comes from the perspective
# constants in BoardGeometry, which are fitted to the ink in
# Assets/board_grid_line.png in world units. Scaling the node here would move the board off the drawn table
# without moving the drawing with it. See Scripts/MatchView/BoardCanvas.gd.
const BOARD_VISUAL_SCALE: float = 1.0

var match_board

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)

func set_turn(turn_value) -> void:
	match_board.side = turn_value
	match_board.get_turn_action_state_controller().reset_current_turn_stamp_affix()
	match_board.get_stamp_hand_state_controller().update_stamp_presentation()
	match_board.get_board_tile_controller().create_board_tiles()
	match_board.get_piece_display_controller().display_board()
	match_board.get_board_environment_controller().create_board_shader_overlay()
	match_board.get_turn_hud_controller().update_end_turn_button()
	if match_board.side != null and !match_board.side:
		match_board.get_node("../Camera2D").global_rotation_degrees = 180
	else:
		match_board.get_node("../Camera2D").global_rotation_degrees = 0
	# The board has just turned round, and the player may be someone else.
	match_board.turn_changed.emit(match_board.get_current_turn_color(), false)

func ready() -> void:
	randomize()
	match_board.texture = null
	apply_board_visual_scale()
	match_board.get_controller_registry().initialize_startup_controllers()
	match_board.get_board_tile_controller().create_board_tiles()
	match_board.create_board_markers_node()
	match_board.create_piece_effects_node()
	match_board.get_controller_registry().initialize_startup_controllers()
	match_board.get_board_environment_controller().create_ambient_board_light()
	match_board.board = BoardConfig.create_starting_board()

	match_board.create_pieces_from_board()
	match_board.get_board_environment_controller().create_board_shader_overlay()
	match_board.get_stamp_hand_state_controller().setup_player_stamp_hands()
	match_board.create_hover_piece_ui()
	match_board.get_board_effect_icon_grid_controller().create_ui()
	match_board.get_turn_hud_controller().create_result_ui()
	match_board.get_deck_counter_controller().create_deck_count_ui()
	match_board.get_deck_counter_controller().create_deck_counter_ui()
	match_board.get_match_codex_controller().create_ui()
	match_board.get_crown_controller().create_ui()
	match_board.get_turn_hud_controller().initialize_player_portraits()
	match_board.current_player_portraits = match_board.get_turn_hud_controller().current_player_portraits
	match_board.get_turn_hud_controller().create_player_portrait_ui()
	match_board.get_turn_hud_controller().create_player_name_ui()
	match_board.create_quit_confirmation_ui()
	match_board.get_turn_hud_controller().create_end_turn_ui()
	match_board.get_turn_hud_controller().create_turn_timer_ui()
	match_board.get_turn_hud_controller().create_turn_banner_ui()
	match_board.turn_changed.connect(Callable(match_board.get_board_environment_controller(), "follow_turn"))
	match_board.turn_changed.connect(Callable(match_board.get_crown_controller(), "follow_turn"))
	match_board.game_finished.connect(Callable(match_board.get_board_environment_controller(), "set_turn_vignette").bind(0.0).unbind(1))
	var turn_flow = match_board.get_turn_flow_controller()
	match_board.turn_ended.connect(Callable(turn_flow, "announce_turn").unbind(2))
	var intro: MatchIntroController = match_board.get_node_or_null("../MatchIntroController") as MatchIntroController
	if intro != null:
		intro.interface_revealed.connect(Callable(turn_flow, "announce_turn"))
		# The edge stays where it is through the intro, whoever is on the move.
		intro.interface_revealed.connect(func() -> void:
			match_board.turn_changed.emit(match_board.get_current_turn_color(), true)
		)
	var hud_controller = match_board.get_turn_hud_controller()
	var resize_callable := Callable(self, "on_viewport_size_changed")
	if !match_board.get_viewport().size_changed.is_connected(resize_callable):
		match_board.get_viewport().size_changed.connect(resize_callable)
	hud_controller.update_player_name_labels()
	hud_controller.update_player_portrait_views()
	# Every node the controllers' configs point at exists now: from here on each
	# controller is configured once (see MatchBoardControllerRegistry._needs_sync).
	match_board.get_controller_registry().settle()

func on_viewport_size_changed() -> void:
	match_board.get_controller_registry().sync_turn_hud_controller()
	match_board.get_turn_hud_controller().update_player_name_labels()
	match_board.get_turn_hud_controller().update_player_portrait_views()

func apply_board_visual_scale() -> void:
	match_board.scale = Vector2.ONE * BOARD_VISUAL_SCALE
