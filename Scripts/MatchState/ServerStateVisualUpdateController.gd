extends RefCounted

var match_board
var invalid_board_pos: Vector2 = Vector2(-1, -1)

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)

func defer_for_bomb_warning(bomb_warning_animations: Array[Dictionary], visual_context: Dictionary) -> void:
	match_board.begin_visual_process(match_board.VISUAL_PROCESS_BOMB_WARNING)
	match_board.play_bomb_warning_animations(bomb_warning_animations)

	var tween: Tween = match_board.create_tween()
	tween.tween_interval(match_board.bomb_warning_duration)
	tween.tween_callback(Callable(self, "finish").bind(visual_context))
	tween.finished.connect(func():
		match_board.finish_visual_process(match_board.VISUAL_PROCESS_BOMB_WARNING)
	)

func finish(visual_context: Dictionary) -> void:
	match_board.display_board()

	var state_piece_move_animation: Dictionary = visual_context.get("state_piece_move_animation", {})
	var state_piece_shatter_animations: Array = visual_context.get("state_piece_shatter_animations", [])
	if !state_piece_move_animation.is_empty():
		await match_board.get_piece_effect_flow_controller().play_state_piece_move_animation(state_piece_move_animation, state_piece_shatter_animations)

	var animated_affix_positions: Dictionary = visual_context.get("animated_affix_positions", {})
	finish_resolved_pending_stamp_affix_processes(animated_affix_positions)

	var state_affix_animations: Array = visual_context.get("state_affix_animations", [])
	var state_piece_revert_animations: Array = visual_context.get("state_piece_revert_animations", [])
	var pending_respawn_arrival_animations: Array = visual_context.get("pending_respawn_arrival_animations", [])
	if !state_affix_animations.is_empty():
		await match_board.get_piece_effect_flow_controller().play_state_affix_animations(state_affix_animations)
	# After the move and the stamp that set an effect off, every piece whose
	# duration it raised or lowered shows its count change at once.
	for animation: Dictionary in visual_context.get("state_duration_change_animations", []):
		match_board.play_duration_change_animation(
			match_board.value_to_vector2(animation.get("position", invalid_board_pos), invalid_board_pos),
			int(animation.get("old_duration", 0)),
			int(animation.get("new_duration", 0))
		)
	if !state_piece_revert_animations.is_empty():
		match_board.call_deferred("play_piece_revert_animations", state_piece_revert_animations)
	if !state_piece_shatter_animations.is_empty():
		match_board.get_piece_respawn_fragment_coordinator().call_deferred("play_piece_shatter_animations", state_piece_shatter_animations)
	if !pending_respawn_arrival_animations.is_empty():
		match_board.get_piece_respawn_fragment_coordinator().call_deferred("play_pending_edge_respawn_arrival_animations", pending_respawn_arrival_animations)

	# Recompute the active-effects grid before the activation flash below, so
	# an effect that both appears AND fires for the first time in the same
	# sync already has a cell to flash. recent_effect_activations is passed
	# in too so a persistent entry whose trigger fires on the same sync it
	# leaves the active set (on_captured/on_expire) still flashes before it
	# burns away instead of silently vanishing.
	match_board.get_board_effect_icon_grid_controller().refresh_active_effects(visual_context.get("recent_effect_activations", []))

	if bool(visual_context.get("should_play_post_state_animations", false)):
		play_post_state_stamp_animations(visual_context)

	if bool(visual_context.get("should_emit_turn_ended", false)):
		match_board.turn_ended.emit(int(visual_context.get("server_ending_color", 0)), match_board.get_current_turn_color())
	match_board.has_received_server_state = true

	if bool(visual_context.get("server_game_over", false)) && int(visual_context.get("winner_player", -1)) != -1:
		reveal_hidden_last_move_arrow_for_game_over()
		match_board.finish_game(match_board.get_color_for_player_id(int(visual_context.get("winner_player", -1))))

func play_post_state_stamp_animations(visual_context: Dictionary) -> void:
	var recent_stamp_transfers: Array = visual_context.get("recent_stamp_transfers", [])
	var previous_white_hand_names: Array = visual_context.get("previous_white_hand_names", [])
	var current_white_hand_names: Array = visual_context.get("current_white_hand_names", [])
	var previous_black_hand_names: Array = visual_context.get("previous_black_hand_names", [])
	var current_black_hand_names: Array = visual_context.get("current_black_hand_names", [])
	if recent_stamp_transfers.is_empty():
		# A page turn swaps the whole hand out; the fly-in-from-deck animation
		# is meant for drawing a single replacement stamp and looks wrong
		# here, plus the codex's own slide-down animation already covers the
		# swap. Skip it specifically for the hand that just turned a page.
		if !bool(visual_context.get("white_page_turned_this_update", false)):
			match_board.get_stamp_animation_controller().animate_state_draw_if_needed(1, previous_white_hand_names, current_white_hand_names)
		if !bool(visual_context.get("black_page_turned_this_update", false)):
			match_board.get_stamp_animation_controller().animate_state_draw_if_needed(-1, previous_black_hand_names, current_black_hand_names)
	else:
		match_board.get_stamp_animation_controller().animate_recent_stamp_transfers(recent_stamp_transfers, previous_white_hand_names, current_white_hand_names, previous_black_hand_names, current_black_hand_names)
	match_board.get_stamp_animation_controller().animate_recent_stamp_expirations(visual_context.get("stamp_expiration_events", []))
	match_board.get_board_effect_icon_grid_controller().animate_recent_effect_activations(visual_context.get("recent_effect_activations", []))

func reveal_hidden_last_move_arrow_for_game_over() -> void:
	if match_board.current_last_move.is_empty() or bool(match_board.current_last_move.get("visible_to_enemy", true)):
		return

	var revealed_last_move: Dictionary = match_board.current_last_move.duplicate()
	revealed_last_move["visible_to_enemy"] = true
	match_board.current_last_move = revealed_last_move
	match_board.update_board_markers()

func get_affix_animation_positions(animations: Array[Dictionary]) -> Dictionary:
	var positions: Dictionary = {}
	for animation: Dictionary in animations:
		var board_pos: Vector2 = match_board.value_to_vector2(animation.get("position", invalid_board_pos), invalid_board_pos)
		if match_board.is_valid_position(board_pos):
			positions[board_pos] = true
	return positions

func finish_resolved_pending_stamp_affix_processes(excluded_positions: Dictionary = {}) -> void:
	for position_value in match_board.pending_stamp_affix_positions.keys():
		var board_pos: Vector2 = match_board.value_to_vector2(position_value, invalid_board_pos)
		if excluded_positions.has(board_pos):
			continue
		match_board.finish_stamp_affix_process(position_value)

func clear_resolved_pending_stamp_affix_positions() -> void:
	for position_value in match_board.pending_stamp_affix_positions.keys():
		var board_pos: Vector2 = match_board.value_to_vector2(position_value, invalid_board_pos)
		if !match_board.piece_objects.has(board_pos):
			match_board.finish_stamp_affix_process(position_value)
