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
		match_board.get_visual_process_tracker().has_any_active()
		or match_board.get_stamp_animation_controller().has_pending_animations()
	)

func wait_for_pending_visual_processes() -> void:
	while is_instance_valid(match_board) and match_board.is_inside_tree() and has_pending_visual_processes():
		await match_board.get_tree().process_frame

## Says whose turn it is once the board has finished showing how it got there, so
## the words do not land on a capture still breaking apart. By then the player
## may have moved already, and the words would be out of date.
func announce_turn() -> void:
	if !should_announce_turn():
		return
	var turn_color: int = match_board.get_current_turn_color()
	# A capture's shatter only starts on the next frame, so it is not pending yet.
	await match_board.get_tree().process_frame
	await wait_for_pending_visual_processes()
	if !is_instance_valid(match_board) or match_board.game_over or match_board.get_current_turn_color() != turn_color:
		return
	match_board.get_turn_hud_controller().announce_turn(turn_color)

## Not in the tutorial, where Grandpa does the talking, and not over the intro:
## the first turn is announced as the interface comes in.
func should_announce_turn() -> bool:
	if match_board.tutorial_mode_active or GameConfig.is_ai_vs_ai_batch or GameConfig.is_dedicated_server:
		return false
	if match_board.game_over or !match_board.has_received_server_state:
		return false
	var intro: MatchIntroController = match_board.get_node_or_null("../MatchIntroController") as MatchIntroController
	return intro == null or intro.is_interface_revealed()

func can_switch_action_now() -> bool:
	var owner_color: int = match_board.get_controllable_color()
	return match_board.get_match_codex_controller().can_turn_page_locally(owner_color)

func has_tutorial_allowed_exchange_stamp(owner_color: int) -> bool:
	if !match_board.tutorial_constraints_enabled:
		return true

	var hand_stamps: Array[Stamp] = match_board.get_stamp_hand_state_controller().get_stamp_hand(owner_color)
	for stamp: Stamp in hand_stamps:
		if stamp == null:
			continue
		if match_board.get_tutorial_match_adapter().is_action_allowed(match_board.TUTORIAL_ACTION_EXCHANGE_STAMP, {
			"owner_color": owner_color,
			"stamp_name": stamp.stamp_name,
		}):
			return true
	return false

func can_affix_action_now() -> bool:
	if !match_board.can_control_current_turn():
		return false
	if !match_board.get_tutorial_match_adapter().is_action_allowed(match_board.TUTORIAL_ACTION_AFFIX_STAMP):
		return false

	var owner_color: int = match_board.get_controllable_color()
	for stamp: Stamp in match_board.get_stamp_hand_state_controller().get_stamp_hand(owner_color):
		if can_affix_stamp_now(stamp):
			return true
	return false

## Whether `stamp`, on the open codex page, could go onto one of the
## player's golems now. Asked once the turn is known to be theirs.
func can_affix_stamp_now(stamp: Stamp) -> bool:
	if stamp == null or !MoveRules.stamp_can_be_used(stamp):
		return false
	var owner_color: int = match_board.get_controllable_color()
	if !MoveRules.can_affix_stamp_for_turn(match_board.piece_objects, owner_color, stamp):
		return false
	for position_value in match_board.piece_objects:
		var piece: Piece = match_board.piece_objects[position_value] as Piece
		if piece == null or piece.color != owner_color or !piece.can_receive_stamp(stamp):
			continue
		if match_board.get_tutorial_match_adapter().is_action_allowed(match_board.TUTORIAL_ACTION_AFFIX_STAMP, {
			"owner_color": owner_color,
			"piece_pos": position_value,
			"stamp_name": stamp.stamp_name,
		}):
			return true
	return false

func can_move_action_now() -> bool:
	return !get_movable_piece_positions().is_empty()

## The squares of the pieces the player can move now: their own, and the
## other side's that carry a Shared stamp (StampEffectResolver.can_player_control_piece),
## each able to move and with somewhere to go. Empty outside their turn and
## once they have moved.
func get_movable_piece_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if !match_board.can_control_current_turn():
		return positions
	if !match_board.get_tutorial_match_adapter().is_action_allowed(match_board.TUTORIAL_ACTION_MOVE_PIECE):
		return positions
	var owner_color: int = match_board.get_controllable_color()
	if match_board.get_turn_action_state_controller().has_moved_piece_this_turn(owner_color):
		return positions

	var player_id: int = BoardConfig.get_player_id_for_color(owner_color)
	for position_value in match_board.piece_objects:
		var piece_pos: Vector2 = BoardConfig.value_to_vector2(position_value, invalid_board_pos)
		var piece: Piece = match_board.piece_objects[position_value] as Piece
		if piece == null or piece.hidden_from_viewer or !piece.can_move() or !StampEffectResolver.can_player_control_piece(piece, player_id):
			continue

		var valid_moves: Array[Vector2] = MoveRules.get_piece_moves_for_player(match_board.piece_objects, piece_pos, player_id, board_size, match_board.current_board_effects)
		for target_pos: Vector2 in valid_moves:
			if match_board.get_tutorial_match_adapter().is_action_allowed(match_board.TUTORIAL_ACTION_MOVE_PIECE, {
				"owner_color": owner_color,
				"from_pos": piece_pos,
				"to_pos": target_pos,
			}):
				positions.append(piece_pos)
				break
	return positions

func on_turn_timer_timeout(expected_turn_color: int) -> void:
	if !match_board.is_inside_tree():
		return
	await request_end_turn(false, expected_turn_color)
	if !match_board.is_inside_tree() or match_board.get_current_turn_color() != expected_turn_color:
		return

func on_end_turn_pressed() -> void:
	await request_end_turn(true)

## True when a move would throw away the one thing the player can still do:
## put a stamp from the open codex page onto a golem that has none. A move
## always ends the turn (see NetworkGameHost.handle_move), so this is the last
## moment to say so. `can_affix_action_now()` is exactly the question of
## whether a stamp could still go on, so it is asked rather than restated.
func should_warn_before_move() -> bool:
	if !SettingsDataManager.is_move_ends_turn_warning_enabled():
		return false
	if !match_board.can_control_current_turn():
		return false
	return can_affix_action_now()

func request_end_turn(emit_tutorial_rejection: bool, expected_turn_color: int = 0) -> void:
	if !match_board.can_control_current_turn():
		return
	if expected_turn_color != 0 and match_board.get_current_turn_color() != expected_turn_color:
		return
	if !match_board.get_tutorial_match_adapter().is_action_allowed(match_board.TUTORIAL_ACTION_END_TURN, {
		"owner_color": match_board.get_controllable_color(),
		"player_id": match_board.get_own_player_id(),
	}, emit_tutorial_rejection):
		return

	await wait_for_pending_visual_processes()
	if !match_board.can_control_current_turn():
		return
	if expected_turn_color != 0 and match_board.get_current_turn_color() != expected_turn_color:
		return

	GameController.send_action({
		"type": "end_turn",
		"player_id": match_board.get_own_player_id(),
	})

