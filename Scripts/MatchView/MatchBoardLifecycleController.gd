extends RefCounted

var match_board
var board_visual_scale: float = 1.0

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	board_visual_scale = float(config.get("board_visual_scale", board_visual_scale))

func set_turn(turn_value) -> void:
	match_board.side = turn_value
	match_board.get_turn_action_state_controller().reset_current_turn_card_attach()
	match_board.update_card_presentation()
	match_board.get_board_tile_controller().create_board_tiles()
	match_board.display_board()
	match_board.create_board_shader_overlay()
	match_board.update_end_turn_button()
	if match_board.side != null and !match_board.side:
		match_board.get_node("../Camera2D").global_rotation_degrees = 180
	else:
		match_board.get_node("../Camera2D").global_rotation_degrees = 0

func ready() -> void:
	randomize()
	match_board.texture = null
	match_board.hide_portrait_placement_preview()
	apply_board_visual_scale()
	match_board.initialize_board_view_helpers()
	match_board.initialize_board_tile_controller()
	match_board.initialize_match_state_sync_controller()
	match_board.initialize_server_state_update_controller()
	match_board.initialize_local_state_mutator()
	match_board.initialize_local_move_flow_controller()
	match_board.initialize_tutorial_match_adapter()
	match_board.initialize_game_result_controller()
	match_board.initialize_turn_flow_controller()
	match_board.initialize_turn_action_state_controller()
	match_board.initialize_piece_visual_controller()
	match_board.initialize_piece_move_animator()
	match_board.get_board_tile_controller().create_board_tiles()
	match_board.create_board_markers_node()
	match_board.initialize_board_marker_controller()
	match_board.initialize_card_interaction_controller()
	match_board.initialize_card_animation_controller()
	match_board.initialize_deck_counter_controller()
	match_board.initialize_turn_hud_controller()
	match_board.initialize_match_input_controller()
	match_board.initialize_card_hand_state_controller()
	match_board.create_piece_effects_node()
	match_board.initialize_piece_shatter_animator()
	match_board.initialize_piece_respawn_fragment_coordinator()
	match_board.initialize_piece_display_controller()
	match_board.initialize_piece_effect_animator()
	match_board.initialize_freeze_effect_animator()
	match_board.create_ambient_board_light()
	match_board.board = BoardConfig.create_starting_board()

	match_board.create_pieces_from_board()
	match_board.create_board_shader_overlay()
	match_board.setup_player_card_hands()
	match_board.create_hover_piece_ui()
	match_board.get_hidden_card_preview_controller().create_ui()
	match_board.get_turn_hud_controller().create_result_ui()
	match_board.get_deck_counter_controller().create_deck_count_ui()
	match_board.get_deck_counter_controller().create_deck_counter_ui()
	match_board.get_turn_hud_controller().initialize_player_portraits()
	match_board.current_player_portraits = match_board.get_turn_hud_controller().current_player_portraits
	match_board.get_turn_hud_controller().create_player_portrait_ui()
	match_board.get_turn_hud_controller().create_player_name_ui()
	match_board.create_quit_confirmation_ui()
	match_board.get_turn_hud_controller().create_end_turn_ui()
	match_board.get_turn_hud_controller().create_rules_info_ui()
	match_board.get_turn_hud_controller().create_action_status_ui()
	match_board.get_turn_hud_controller().create_turn_timer_ui()
	var hud_controller = match_board.get_turn_hud_controller()
	var resize_callable := Callable(self, "on_viewport_size_changed")
	if !match_board.get_viewport().size_changed.is_connected(resize_callable):
		match_board.get_viewport().size_changed.connect(resize_callable)
	hud_controller.update_player_name_labels()
	hud_controller.update_player_portrait_views()

func on_viewport_size_changed() -> void:
	match_board.sync_turn_hud_controller()
	match_board.get_turn_hud_controller().update_player_name_labels()
	match_board.get_turn_hud_controller().update_player_portrait_views()

func apply_board_visual_scale() -> void:
	match_board.scale = Vector2.ONE * board_visual_scale
