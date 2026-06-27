extends RefCounted

var match_board

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)

func has_attached_card_this_turn(owner_color: int) -> bool:
	return bool(match_board.attached_card_this_turn.get(owner_color, false))

func mark_card_attached_this_turn(owner_color: int) -> void:
	var player_id: int = match_board.get_player_id_for_color(owner_color)
	match_board.attached_card_this_turn[owner_color] = true
	if !GameController.current_game_host:
		match_board.attached_card_count_this_turn[player_id] = int(match_board.attached_card_count_this_turn.get(player_id, 0)) + 1
	match_board.update_end_turn_button()
	match_board.update_card_drag_permissions()
	match_board.get_turn_hud_controller().update_action_status_ui()

func reset_current_turn_card_attach() -> void:
	var current_color: int = match_board.get_current_turn_color()
	match_board.attached_card_this_turn[current_color] = false
	match_board.attached_card_count_this_turn[match_board.get_player_id_for_color(current_color)] = 0
	match_board.moved_piece_this_turn[current_color] = false
	match_board.exchanged_card_this_turn[current_color] = false
	match_board.has_turned_page_this_turn[current_color] = false
	match_board.played_card_hand_slots_this_turn[current_color] = []
	match_board.exchanged_card_names_this_turn[current_color] = []
	match_board.advance_empty_codex_page_at_turn_start(current_color)
	match_board.update_end_turn_button()
	match_board.get_turn_hud_controller().update_action_status_ui()
	match_board.update_codex_ui()

func has_moved_piece_this_turn(owner_color: int) -> bool:
	return bool(match_board.moved_piece_this_turn.get(owner_color, false))

func mark_piece_moved_this_turn(owner_color: int) -> void:
	match_board.moved_piece_this_turn[owner_color] = true
	match_board.update_end_turn_button()
	match_board.get_turn_hud_controller().update_action_status_ui()

func has_exchanged_card_this_turn(owner_color: int) -> bool:
	return bool(match_board.exchanged_card_this_turn.get(owner_color, false))

func mark_card_exchanged_this_turn(owner_color: int) -> void:
	match_board.exchanged_card_this_turn[owner_color] = true
	match_board.get_turn_hud_controller().update_action_status_ui()
