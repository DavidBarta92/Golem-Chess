extends RefCounted

var match_board

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)

func update_from_server_state(
	pieces_data: Dictionary,
	player_hands: Dictionary,
	current_turn: int,
	server_game_over: bool = false,
	winner_player: int = -1,
	player_deck_sizes: Dictionary = {},
	hidden_cards: Array = [],
	player_base_fields: Dictionary = {},
	board_effects: Array = [],
	player_names: Dictionary = {},
	recent_card_transfers: Array = [],
	recent_card_expirations: Array = [],
	recent_bomb_effects: Array = [],
	recent_pending_respawn_queues: Array = [],
	recent_pending_respawn_arrivals: Array = [],
	last_move: Dictionary = {},
	player_portraits: Dictionary = {}
) -> void:
	var previous_piece_visual_state: Dictionary = match_board.get_piece_visual_state_snapshot()
	var previous_hidden_card_counts: Dictionary = match_board.hidden_card_counts.duplicate()
	var current_hidden_card_counts: Dictionary = match_board.get_match_state_sync_controller().get_hidden_card_counts_from_state(hidden_cards)
	var previous_white_hand_names: Array[String] = match_board.get_card_names_from_hand(match_board.white_card_hand)
	var previous_black_hand_names: Array[String] = match_board.get_card_names_from_hand(match_board.black_card_hand)

	var parsed_piece_state: Dictionary = match_board.get_match_state_sync_controller().build_piece_state_from_server(pieces_data)
	match_board.board = parsed_piece_state.get("board", BoardConfig.create_empty_board())
	match_board.piece_objects = parsed_piece_state.get("piece_objects", {})

	var turn_transition: Dictionary = match_board.get_match_state_sync_controller().get_turn_transition_from_server(match_board.white, current_turn, match_board.has_received_server_state)
	match_board.white = bool(turn_transition.get("is_white_turn", match_board.white))
	var should_emit_turn_ended: bool = bool(turn_transition.get("should_emit_turn_ended", false))
	var server_ending_color: int = int(turn_transition.get("server_ending_color", 0))
	if bool(turn_transition.get("changed_turn", false)):
		match_board.get_turn_action_state_controller().reset_current_turn_card_attach()

	var current_white_hand_names: Array = match_board.get_match_state_sync_controller().get_hand_names_from_state(player_hands, 0)
	var current_black_hand_names: Array = match_board.get_match_state_sync_controller().get_hand_names_from_state(player_hands, 1)
	if !player_deck_sizes.is_empty():
		match_board.white_deck_count_override = match_board.get_match_state_sync_controller().get_int_from_state_dict(player_deck_sizes, 0, match_board.white_card_deck.size())
		match_board.black_deck_count_override = match_board.get_match_state_sync_controller().get_int_from_state_dict(player_deck_sizes, 1, match_board.black_card_deck.size())
	match_board.current_player_base_fields = match_board.get_match_state_sync_controller().parse_player_base_fields(player_base_fields)
	match_board.current_board_effects = match_board.get_match_state_sync_controller().parse_board_effects(board_effects)
	match_board.current_player_names = match_board.get_match_state_sync_controller().parse_player_names(player_names, match_board.current_player_names)
	match_board.current_player_portraits = match_board.get_match_state_sync_controller().parse_player_portraits(player_portraits, match_board.current_player_portraits)
	match_board.current_last_move = match_board.get_match_state_sync_controller().parse_last_move(last_move)
	match_board.get_local_state_mutator().sync_moved_piece_this_turn_from_server_state(match_board.current_last_move)
	match_board.update_end_turn_button()
	match_board.get_turn_hud_controller().update_action_status_ui()
	match_board.white_card_hand = match_board.create_card_hand_from_names(current_white_hand_names)
	match_board.black_card_hand = match_board.create_card_hand_from_names(current_black_hand_names)
	match_board.white_card_visuals = match_board.populate_card_hand(match_board.white_pieces, match_board.white_card_hand, 1)
	match_board.black_card_visuals = match_board.populate_card_hand(match_board.black_pieces, match_board.black_card_hand, -1)
	match_board.setup_deck_visuals()

	match_board.delete_dots()
	match_board.hide_hover_piece_details()
	match_board.get_hidden_card_preview_controller().update_previews(hidden_cards)
	match_board.update_card_presentation()
	var card_expiration_events: Array[Dictionary] = match_board.get_state_card_expiration_events(previous_piece_visual_state, recent_card_expirations)
	var state_attach_animations: Array[Dictionary] = match_board.get_match_state_sync_controller().collect_state_attach_animations(
		previous_piece_visual_state,
		match_board.piece_objects,
		hidden_cards,
		previous_hidden_card_counts,
		match_board.get_own_player_id(),
		match_board.has_received_server_state,
		match_board.should_skip_visual_animations()
	)
	var state_piece_revert_animations: Array[Dictionary] = match_board.get_match_state_sync_controller().collect_piece_revert_animations(
		previous_piece_visual_state,
		card_expiration_events,
		match_board.piece_objects,
		match_board.has_received_server_state,
		match_board.should_skip_visual_animations()
	)
	var state_piece_shatter_animations: Array[Dictionary] = match_board.get_match_state_sync_controller().collect_piece_shatter_animations(
		previous_piece_visual_state,
		match_board.piece_objects,
		recent_bomb_effects,
		recent_pending_respawn_queues,
		match_board.has_received_server_state,
		match_board.should_skip_visual_animations()
	)
	var state_piece_move_animation: Dictionary = match_board.get_match_state_sync_controller().collect_state_piece_move_animation(
		previous_piece_visual_state,
		match_board.piece_objects,
		match_board.current_last_move,
		match_board.has_received_server_state,
		match_board.should_skip_visual_animations(),
		match_board.piece_move_animation_enabled and match_board.is_inside_tree()
	)
	var bomb_warning_animations: Array[Dictionary] = match_board.collect_bomb_warning_animations(recent_bomb_effects, previous_piece_visual_state)
	var pending_respawn_arrival_animations: Array[Dictionary] = match_board.parse_pending_respawn_arrival_animations(recent_pending_respawn_arrivals)
	match_board.hidden_card_counts = current_hidden_card_counts
	var animated_attach_positions: Dictionary = match_board.get_attach_animation_positions(state_attach_animations)
	for position_value in animated_attach_positions.keys():
		var animated_attach_pos: Vector2 = match_board.value_to_vector2(position_value, match_board.INVALID_BOARD_POS)
		if match_board.is_valid_position(animated_attach_pos):
			match_board.begin_card_attach_process(animated_attach_pos)
	match_board.prepare_piece_shatter_respawn_reveals(state_piece_shatter_animations)
	match_board.prepare_pending_edge_respawn_arrival_reveals(pending_respawn_arrival_animations)

	var visual_context: Dictionary = {
		"animated_attach_positions": animated_attach_positions,
		"state_piece_move_animation": state_piece_move_animation,
		"state_attach_animations": state_attach_animations,
		"state_piece_revert_animations": state_piece_revert_animations,
		"state_piece_shatter_animations": state_piece_shatter_animations,
		"pending_respawn_arrival_animations": pending_respawn_arrival_animations,
		"should_play_post_state_animations": match_board.has_received_server_state and !match_board.should_skip_visual_animations(),
		"recent_card_transfers": recent_card_transfers,
		"previous_white_hand_names": previous_white_hand_names,
		"current_white_hand_names": current_white_hand_names,
		"previous_black_hand_names": previous_black_hand_names,
		"current_black_hand_names": current_black_hand_names,
		"card_expiration_events": card_expiration_events,
		"should_emit_turn_ended": should_emit_turn_ended,
		"server_ending_color": server_ending_color,
		"server_game_over": server_game_over,
		"winner_player": winner_player,
	}
	if !bomb_warning_animations.is_empty():
		match_board.defer_server_state_visual_update_for_bomb_warning(bomb_warning_animations, visual_context)
		return

	match_board.finish_server_state_visual_update(visual_context)
