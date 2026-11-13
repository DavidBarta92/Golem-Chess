extends RefCounted

const LOCAL_MATCH_LINK_SCRIPT = preload("res://Scripts/MatchState/LocalMatchLink.gd")

var match_board
var invalid_board_pos: Vector2 = Vector2(-1, -1)
var board_size: int = BoardConfig.BOARD_SIZE

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)
	board_size = int(config.get("board_size", board_size))

func set_constraints(constraints: Dictionary) -> void:
	match_board.tutorial_constraints = constraints.duplicate(true)
	match_board.tutorial_constraints_enabled = !match_board.tutorial_constraints.is_empty() and bool(match_board.tutorial_constraints.get("enabled", true))
	refresh_dependent_ui()

func set_mode_active(active: bool) -> void:
	match_board.tutorial_mode_active = active

func clear_constraints() -> void:
	match_board.tutorial_constraints.clear()
	match_board.tutorial_constraints_enabled = false
	refresh_dependent_ui()

func refresh_dependent_ui() -> void:
	match_board.get_stamp_hand_state_controller().update_stamp_drag_permissions()
	match_board.get_turn_hud_controller().update_end_turn_button()
	# The page-turn tab rises and sinks with whether turning is allowed.
	match_board.get_match_codex_controller().update_ui()
	match_board.get_crown_controller().refresh()
	if match_board.state:
		match_board.get_match_input_controller().show_options()

func is_action_allowed(action_name: String, context: Dictionary = {}, emit_rejection: bool = false) -> bool:
	if !match_board.tutorial_constraints_enabled:
		return true
	if !is_action_name_allowed(action_name):
		return reject_action(action_name, context, emit_rejection)

	var allowed: bool = true
	match action_name:
		match_board.TUTORIAL_ACTION_SELECT_PIECE:
			if context.has("piece_pos"):
				allowed = vector_allowed(["allowed_select_piece_positions", "allowed_move_sources", "allowed_piece_positions", "allowed_pieces"], context.get("piece_pos"))
		match_board.TUTORIAL_ACTION_AFFIX_STAMP:
			if context.has("piece_pos"):
				allowed = allowed and vector_allowed(["allowed_affix_piece_positions", "allowed_piece_positions", "allowed_pieces"], context.get("piece_pos"))
			if context.has("stamp_name"):
				allowed = allowed and string_allowed(["allowed_affix_stamp_names", "allowed_stamp_names", "allowed_stamps"], str(context.get("stamp_name", "")))
		match_board.TUTORIAL_ACTION_MOVE_PIECE:
			if context.has("from_pos"):
				allowed = allowed and vector_allowed(["allowed_move_sources", "allowed_piece_positions", "allowed_pieces"], context.get("from_pos"))
			if context.has("to_pos"):
				allowed = allowed and vector_allowed(["allowed_move_targets"], context.get("to_pos"))
		match_board.TUTORIAL_ACTION_EXCHANGE_STAMP:
			if context.has("stamp_name"):
				allowed = allowed and string_allowed(["allowed_exchange_stamp_names", "allowed_stamp_names", "allowed_stamps"], str(context.get("stamp_name", "")))
		match_board.TUTORIAL_ACTION_PLACE_CROWN:
			if context.has("piece_pos"):
				allowed = vector_allowed(["allowed_crown_positions"], context.get("piece_pos"))

	if !allowed:
		return reject_action(action_name, context, emit_rejection)
	return true

func is_action_name_allowed(action_name: String) -> bool:
	if !match_board.tutorial_constraints.has("allowed_actions"):
		return true
	var allowed_actions: Array = constraint_array(["allowed_actions"])
	return allowed_actions.has(action_name)

func reject_action(action_name: String, context: Dictionary, emit_rejection: bool) -> bool:
	if emit_rejection:
		match_board.tutorial_action_rejected.emit(action_name, context.duplicate(true))
	return false

func string_allowed(keys: Array, candidate: String) -> bool:
	if !has_constraint(keys):
		return true
	var allowed_values: Array = constraint_array(keys)
	for value in allowed_values:
		if str(value) == candidate:
			return true
	return false

func vector_allowed(keys: Array, candidate) -> bool:
	if !has_constraint(keys):
		return true
	var allowed_values: Array = constraint_array(keys)

	var candidate_pos: Vector2 = BoardConfig.value_to_vector2(candidate, invalid_board_pos)
	if candidate_pos == invalid_board_pos:
		return false
	for value in allowed_values:
		if BoardConfig.value_to_vector2(value, invalid_board_pos) == candidate_pos:
			return true
	return false

func constraint_array(keys: Array) -> Array:
	for key_value in keys:
		var key: String = str(key_value)
		if !match_board.tutorial_constraints.has(key):
			continue
		var value = match_board.tutorial_constraints[key]
		if value is Array:
			return value
	return []

func has_constraint(keys: Array) -> bool:
	for key_value in keys:
		if match_board.tutorial_constraints.has(str(key_value)):
			return true
	return false

## The board plays on a host of its own, with no network: every rule is the
## host's, as in a match against the computer. `scripted_colors` are the sides a
## script plays (play_scripted_affix, play_scripted_move, pass_scripted_turn);
## having nothing to do does not lose them the game. The match starts from
## `setup` (NetworkGameHost.apply_setup has the keys).
func start_local_host(setup: Dictionary, scripted_colors: Array) -> void:
	var host := NetworkGameHost.new(LOCAL_MATCH_LINK_SCRIPT.new(match_board))
	for owner_color in scripted_colors:
		host.scripted_player_ids.append(BoardConfig.get_player_id_for_color(int(owner_color)))
	GameController.set_game_host(host)
	# Leaving the scene leaves no host behind for the next one to find.
	match_board.tree_exiting.connect(func() -> void:
		if GameController.current_game_host == host:
			GameController.set_game_host(null)
	, CONNECT_ONE_SHOT)
	prepare_board_for_setup()
	host.initialize_from_setup(setup)

## Puts a position in place, and the board shows it at once rather than playing
## the change.
func apply_setup(setup: Dictionary) -> void:
	var host = GameController.current_game_host
	if host == null or !host.has_method("apply_setup"):
		push_error("A setup needs the board's own host (start_local_host).")
		return
	prepare_board_for_setup()
	host.apply_setup(setup)

## Clears what only the board knows of the position it is about to leave -
## fragments of golems still to come back, a selection, the codex slots this
## turn has emptied - and makes the next state count as the first, which is
## shown as it is.
func prepare_board_for_setup() -> void:
	match_board.get_piece_respawn_fragment_coordinator().clear_all_fragment_markers()
	match_board.state = false
	match_board.get_match_input_controller().delete_dots()
	for owner_color in [1, -1]:
		match_board.played_stamp_hand_slots_this_turn[owner_color] = []
		match_board.exchanged_stamp_names_this_turn[owner_color] = []
	match_board.has_received_server_state = false

## A stamp from a scripted side's open codex page onto one of its golems, sent
## to the host as a player's would be. Returns once the board has shown it.
func play_scripted_affix(owner_color: int, stamp_name: String, piece_pos: Vector2) -> void:
	var hand_names: Array = match_board.get_match_state_sync_controller().get_stamp_names_from_hand(match_board.get_stamp_hand_state_controller().get_stamp_hand(owner_color))
	var hand_index: int = hand_names.find(stamp_name)
	if hand_index < 0:
		push_warning("Scripted side cannot play %s at %s: it is not on the open page." % [stamp_name, piece_pos])
		return
	GameController.send_action({
		"type": "affix_stamp",
		"player_id": BoardConfig.get_player_id_for_color(owner_color),
		"stamp_name": stamp_name,
		"hand_index": hand_index,
		"piece_pos": piece_pos,
	})
	await wait_for_board()

## A scripted side's move, sent to the host. A move ends the turn.
func play_scripted_move(owner_color: int, from_pos: Vector2, to_pos: Vector2) -> void:
	GameController.send_action({
		"type": "move_piece",
		"player_id": BoardConfig.get_player_id_for_color(owner_color),
		"from": from_pos,
		"to": to_pos,
	})

## A scripted side's turn handed back with nothing more done.
func pass_scripted_turn(owner_color: int) -> void:
	var host = GameController.current_game_host
	if host != null and host.has_method("pass_turn"):
		host.pass_turn(BoardConfig.get_player_id_for_color(owner_color))

## Until the board has shown what the host just sent: a frame for the state to
## start, then whatever it set playing.
func wait_for_board() -> void:
	if !match_board.is_inside_tree():
		return
	await match_board.get_tree().process_frame
	await match_board.get_turn_flow_controller().wait_for_pending_visual_processes()
