extends RefCounted

var match_board
var invalid_board_pos: Vector2 = Vector2(-1, -1)
var main_menu_scene: String = "res://Scenes/MainMenu.tscn"

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)
	main_menu_scene = str(config.get("main_menu_scene", main_menu_scene))

func process(delta: float) -> void:
	update_hovered_piece()
	match_board.get_deck_counter_controller().update_deck_count_hover()
	match_board.get_deck_counter_controller().update_deck_counter_ui()
	match_board.get_turn_hud_controller().update_action_status_ui()
	match_board.get_turn_hud_controller().arrange_action_status_ui()
	match_board.get_turn_hud_controller().update_turn_timer(delta)
	match_board.get_turn_hud_controller().arrange_turn_timer_ui()
	match_board.get_turn_hud_controller().arrange_rules_info_panel()

func select_piece_for_action(piece_pos: Vector2) -> bool:
	var player_id: int = match_board.get_own_player_id()
	if !match_board.can_player_control_piece_at(piece_pos, player_id):
		return false
	if !match_board.is_tutorial_action_allowed(match_board.TUTORIAL_ACTION_SELECT_PIECE, {
		"owner_color": match_board.get_controllable_color(),
		"player_id": player_id,
		"piece_pos": piece_pos,
	}, true):
		return false

	match_board.selected_piece = piece_pos
	match_board.state = true
	match_board.piece_selected.emit(piece_pos, player_id)
	show_options()
	return match_board.state

func try_move_selected_piece(target_pos: Vector2) -> bool:
	if !match_board.state or !match_board.moves.has(target_pos):
		return false
	if !match_board.is_tutorial_action_allowed(match_board.TUTORIAL_ACTION_MOVE_PIECE, {
		"owner_color": match_board.get_controllable_color(),
		"player_id": match_board.get_own_player_id(),
		"from_pos": match_board.selected_piece,
		"to_pos": target_pos,
	}, true):
		return false

	send_move_action(match_board.selected_piece, target_pos)
	return true

func clear_piece_selection() -> void:
	delete_dots()
	match_board.state = false
	match_board.update_selected_piece_glow()
	match_board.hovered_piece = Vector2(-1, -1)
	hide_hover_piece_details()

func handle_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and !key_event.echo and key_event.keycode == KEY_ESCAPE:
			match_board.show_quit_confirmation()
			match_board.get_viewport().set_input_as_handled()
			return

	if match_board.can_control_current_turn():
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if is_mouse_out():
					return
				if match_board.get_turn_action_state_controller().has_moved_piece_this_turn(match_board.get_controllable_color()):
					return
				var clicked_pos: Vector2 = match_board.get_mouse_board_position()
				var clicked_cell_value = "invalid"
				if match_board.is_valid_position(clicked_pos):
					clicked_cell_value = match_board.board[int(clicked_pos.x)][int(clicked_pos.y)]

				DebugLog.info("Click: board[%s][%s]=%s" % [
					int(clicked_pos.x),
					int(clicked_pos.y),
					clicked_cell_value,
				])

				if !match_board.is_valid_position(clicked_pos):
					return

				if !match_board.state and match_board.can_player_control_piece_at(clicked_pos, match_board.get_own_player_id()):
					select_piece_for_action(clicked_pos)
				elif match_board.state:
					if match_board.moves.has(clicked_pos):
						try_move_selected_piece(clicked_pos)
					clear_piece_selection()

func send_move_action(from_pos: Vector2, to_pos: Vector2) -> void:
	if !match_board.is_tutorial_action_allowed(match_board.TUTORIAL_ACTION_MOVE_PIECE, {
		"owner_color": match_board.get_controllable_color(),
		"player_id": match_board.get_own_player_id(),
		"from_pos": from_pos,
		"to_pos": to_pos,
	}, true):
		return

	if GameController.current_game_host:
		var action: Dictionary = {
			"type": "move_piece",
			"player_id": match_board.get_own_player_id(),
			"from": from_pos,
			"to": to_pos,
		}
		GameController.send_action(action)
		return

	if match_board.get_parent().has_method("send_move"):
		match_board.get_parent().send_move(from_pos, to_pos)
	match_board.set_move(from_pos, to_pos)

func is_mouse_out() -> bool:
	return match_board.get_mouse_board_position() == invalid_board_pos

func update_hovered_piece() -> void:
	if match_board.state:
		return

	if match_board.game_over or is_mouse_out():
		if match_board.hovered_piece != Vector2(-1, -1):
			match_board.hovered_piece = Vector2(-1, -1)
			delete_dots()
			hide_hover_piece_details()
		return

	var board_pos: Vector2 = match_board.get_mouse_board_position()
	if board_pos == match_board.hovered_piece:
		update_hover_duration_label_position()
		return

	match_board.hovered_piece = board_pos
	delete_dots()
	hide_hover_piece_details()

	if match_board.is_valid_position(board_pos) and !match_board.is_empty(board_pos):
		match_board.moves = match_board.get_moves(board_pos)
		show_dots(board_pos)
		show_hover_piece_details(board_pos)

func show_hover_piece_details(board_pos: Vector2) -> void:
	if !match_board.piece_objects.has(board_pos):
		return

	var piece: Piece = match_board.piece_objects[board_pos] as Piece
	if piece.attached_card == null:
		return

	var preview_card: Card = piece.attached_card.duplicate() as Card
	if preview_card:
		preview_card.duration = piece.turns_remaining
		var preview_texture: Texture2D = match_board.get_card_piece_preview_texture(preview_card, piece.color)
		var duration_text: String = "INF" if piece.turns_remaining < 0 else str(piece.turns_remaining)
		match_board.get_card_hover_preview_controller().show_piece_details(preview_card, preview_texture, duration_text)
	update_hover_duration_label_position()

func hide_hover_piece_details() -> void:
	match_board.get_card_hover_preview_controller().hide()

func update_hover_duration_label_position() -> void:
	if !match_board.hover_duration_label or !match_board.hover_duration_label.visible:
		return
	if !match_board.is_valid_position(match_board.hovered_piece):
		return

	var piece_screen_position: Vector2 = match_board.get_board_position_screen_position(match_board.hovered_piece)
	match_board.get_card_hover_preview_controller().update_duration_label_position(piece_screen_position)

func show_hover_piece_preview(card: Card, piece_color: int) -> void:
	var preview_texture: Texture2D = match_board.get_card_piece_preview_texture(card, piece_color)
	match_board.get_card_hover_preview_controller().show_piece_preview(preview_texture)

func show_options() -> void:
	match_board.moves = match_board.get_moves(match_board.selected_piece)
	if match_board.moves == []:
		match_board.state = false
		match_board.update_selected_piece_glow()
		return
	delete_dots()
	show_dots(match_board.selected_piece)
	match_board.update_selected_piece_glow()
	show_hover_piece_details(match_board.selected_piece)

func show_dots(source_pos: Vector2 = Vector2(-1, -1)) -> void:
	match_board.get_board_marker_controller().show_dots(match_board.moves, source_pos)

func delete_dots() -> void:
	match_board.get_board_marker_controller().delete_dots()
