extends RefCounted

var match_board
var board_size: int = BoardConfig.BOARD_SIZE
var invalid_board_pos: Vector2 = Vector2(-1, -1)

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	board_size = int(config.get("board_size", board_size))
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)

func has_pending_visual_processes() -> bool:
	return (
		match_board.active_card_attach_process_count > 0
		or match_board.active_piece_revert_animation_count > 0
		or match_board.active_piece_move_animation_count > 0
		or match_board.active_piece_shatter_animation_count > 0
		or match_board.active_bomb_warning_animation_count > 0
		or match_board.get_card_animation_controller().has_pending_animations()
		or !match_board.pending_piece_revert_animations.is_empty()
	)

func wait_for_pending_visual_processes() -> void:
	while match_board.is_inside_tree() and has_pending_visual_processes():
		await match_board.get_tree().process_frame

func can_switch_action_now() -> bool:
	if !match_board.can_control_current_turn():
		return false
	if !match_board.is_tutorial_action_allowed(match_board.TUTORIAL_ACTION_EXCHANGE_CARD):
		return false
	var owner_color: int = match_board.get_controllable_color()
	return match_board.can_exchange_card_locally(owner_color) and has_tutorial_allowed_exchange_card(owner_color)

func has_tutorial_allowed_exchange_card(owner_color: int) -> bool:
	if !match_board.tutorial_constraints_enabled:
		return true

	var hand_cards: Array[Card] = match_board.get_card_hand(owner_color)
	for card: Card in hand_cards:
		if card == null:
			continue
		if match_board.is_tutorial_action_allowed(match_board.TUTORIAL_ACTION_EXCHANGE_CARD, {
			"owner_color": owner_color,
			"card_name": card.card_name,
		}):
			return true
	return false

func can_attach_action_now() -> bool:
	if !match_board.can_control_current_turn():
		return false
	if !match_board.is_tutorial_action_allowed(match_board.TUTORIAL_ACTION_ATTACH_CARD):
		return false

	var owner_color: int = match_board.get_controllable_color()
	var hand_cards: Array[Card] = match_board.get_card_hand(owner_color)
	if hand_cards.is_empty():
		return false

	for position_value in match_board.piece_objects:
		var piece: Piece = match_board.piece_objects[position_value] as Piece
		if piece == null or piece.color != owner_color or piece.attached_card != null:
			continue

		for card: Card in hand_cards:
			if !MoveRules.card_can_be_used(card):
				continue
			if !match_board.is_tutorial_action_allowed(match_board.TUTORIAL_ACTION_ATTACH_CARD, {
				"owner_color": owner_color,
				"piece_pos": position_value,
				"card_name": card.card_name,
			}):
				continue
			if MoveRules.can_attach_card_for_turn(match_board.piece_objects, owner_color, card):
				return true

	return false

func can_move_action_now() -> bool:
	if !match_board.can_control_current_turn():
		return false
	if !match_board.is_tutorial_action_allowed(match_board.TUTORIAL_ACTION_MOVE_PIECE):
		return false

	var owner_color: int = match_board.get_controllable_color()
	if match_board.get_turn_action_state_controller().has_moved_piece_this_turn(owner_color):
		return false
	return has_tutorial_allowed_piece_move(owner_color)

func has_tutorial_allowed_piece_move(owner_color: int) -> bool:
	for position_value in match_board.piece_objects:
		var piece_pos: Vector2 = match_board.value_to_vector2(position_value, invalid_board_pos)
		var piece: Piece = match_board.piece_objects[position_value] as Piece
		if piece == null or piece.color != owner_color or !piece.can_move():
			continue

		var player_id: int = match_board.get_player_id_for_color(owner_color)
		var valid_moves: Array[Vector2] = MoveRules.get_piece_moves_for_player(match_board.piece_objects, piece_pos, player_id, board_size, match_board.current_board_effects)
		for target_pos: Vector2 in valid_moves:
			if match_board.is_tutorial_action_allowed(match_board.TUTORIAL_ACTION_MOVE_PIECE, {
				"owner_color": owner_color,
				"from_pos": piece_pos,
				"to_pos": target_pos,
			}):
				return true
	return false

func has_remaining_turn_action_now() -> bool:
	return can_switch_action_now() or can_attach_action_now() or can_move_action_now()

func on_turn_timer_timeout(expected_turn_color: int) -> void:
	if !match_board.is_inside_tree():
		return
	await request_end_turn(false, expected_turn_color)
	if !match_board.is_inside_tree() or match_board.get_current_turn_color() != expected_turn_color:
		return
	if GameController.current_game_host == null:
		match_board.get_turn_hud_controller().clear_turn_timer_timeout_pending()

func maybe_auto_end_turn_locally() -> void:
	if GameController.current_game_host:
		return
	if !match_board.can_auto_end_turn_now():
		return
	if match_board.local_auto_end_turn_pending or match_board.game_over or !match_board.can_control_current_turn():
		return
	if has_remaining_turn_action_now():
		return

	match_board.local_auto_end_turn_pending = true
	match_board.call_deferred("_auto_end_turn_locally_if_still_needed")

func auto_end_turn_locally_if_still_needed() -> void:
	match_board.local_auto_end_turn_pending = false
	if GameController.current_game_host or match_board.game_over or !match_board.can_control_current_turn():
		return
	await wait_for_pending_visual_processes()
	if match_board.game_over or !match_board.can_control_current_turn():
		return
	if has_remaining_turn_action_now():
		return
	end_current_turn_locally()

func on_end_turn_pressed() -> void:
	await request_end_turn(true)

func request_end_turn(emit_tutorial_rejection: bool, expected_turn_color: int = 0) -> void:
	if !match_board.can_control_current_turn():
		return
	if expected_turn_color != 0 and match_board.get_current_turn_color() != expected_turn_color:
		return
	if !match_board.is_tutorial_action_allowed(match_board.TUTORIAL_ACTION_END_TURN, {
		"owner_color": match_board.get_controllable_color(),
		"player_id": match_board.get_own_player_id(),
	}, emit_tutorial_rejection):
		return

	await wait_for_pending_visual_processes()
	if !match_board.can_control_current_turn():
		return
	if expected_turn_color != 0 and match_board.get_current_turn_color() != expected_turn_color:
		return

	if GameController.current_game_host:
		GameController.send_action({
			"type": "end_turn",
			"player_id": match_board.get_own_player_id(),
		})
		return

	end_current_turn_locally()

func end_current_turn_locally() -> void:
	match_board.local_auto_end_turn_pending = false
	var ending_color: int = match_board.get_current_turn_color()
	match_board.refill_played_cards_locally(ending_color)
	match_board.get_card_hand_state_controller().clear_exchanged_card_names_this_turn(ending_color)
	match_board.get_local_state_mutator().tick_board_effects()
	match_board.get_local_state_mutator().clear_piece_exhaustion_for_color(ending_color)
	match_board.white = !match_board.white
	match_board.get_turn_action_state_controller().reset_current_turn_card_attach()
	match_board.state = false
	match_board.delete_dots()
	match_board.hide_hover_piece_details()
	match_board.update_card_presentation()
	match_board.display_board()
	match_board.turn_ended.emit(ending_color, match_board.get_current_turn_color())
	match_board.finish_if_current_player_has_no_valid_turn()
