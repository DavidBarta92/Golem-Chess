extends RefCounted

var match_board

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)

func has_attached_card_this_turn(_owner_color: int) -> bool:
	return false

func mark_card_attached_this_turn(_owner_color: int) -> void:
	match_board.update_card_drag_permissions()
	match_board.get_turn_hud_controller().update_action_status_ui()

func reset_current_turn_card_attach() -> void:
	var current_color: int = match_board.get_current_turn_color()
	match_board.attached_card_this_turn[current_color] = false
	match_board.moved_piece_this_turn[current_color] = false
	match_board.exchanged_card_this_turn[current_color] = false
	match_board.played_card_hand_slots_this_turn[current_color] = []
	match_board.exchanged_card_names_this_turn[current_color] = []
	match_board.get_turn_hud_controller().update_action_status_ui()

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
