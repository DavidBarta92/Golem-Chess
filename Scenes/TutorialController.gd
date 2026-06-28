extends Node

const PLAYER_COLOR: int = 1
const MENTOR_NAME: String = "Mentor"
const INVALID_BOARD_POS: Vector2 = Vector2(-1, -1)

@export var board_path: NodePath = NodePath("../MatchBoard")
@export var dialogue_panel_path: NodePath = NodePath("../CanvasLayer/DialoguePanel")

var board
var dialogue_panel
var mentor_portrait: PortraitConfig
var steps: Array[Dictionary] = []
var current_step_index: int = -1
var attached_this_step: int = 0
var moved_this_step: int = 0
var waiting_for_continue_after_completion: bool = false

func _ready() -> void:
	call_deferred("begin_tutorial")

func begin_tutorial() -> void:
	board = get_node_or_null(board_path)
	dialogue_panel = get_node_or_null(dialogue_panel_path)
	if board == null or dialogue_panel == null:
		push_error("TutorialController could not find the board or dialogue panel.")
		return

	GameController.set_game_host(null)
	if board.has_method("set_tutorial_mode_active"):
		board.set_tutorial_mode_active(true)
	connect_board_signals()
	connect_dialogue_signals()
	mentor_portrait = PortraitLibrary.get_tutorial_portrait()
	build_steps()
	start_step(0)

func connect_board_signals() -> void:
	board.stamp_attached.connect(_on_stamp_attached)
	board.stamp_exchanged.connect(_on_stamp_exchanged)
	board.codex_page_turned.connect(_on_codex_page_turned)
	board.piece_moved.connect(_on_piece_moved)
	board.turn_ended.connect(_on_turn_ended)
	board.tutorial_action_rejected.connect(_on_tutorial_action_rejected)

func connect_dialogue_signals() -> void:
	dialogue_panel.continue_requested.connect(_on_dialogue_continue_requested)

func build_steps() -> void:
	steps = [
		{
			"speaker": MENTOR_NAME,
			"text": "Welcome. We will play a guided version of the game: one rule, one action, then the next rule.",
			"completion": "dialogue",
			"constraints": no_actions(),
		},
		{
			"speaker": MENTOR_NAME,
			"text": "Stamps give pieces their movement. On your first turn every piece is frozen, so you must attach at least one stamp. Drag Numero_1 onto a piece.",
			"completion": "stamp_attached",
			"expected_stamp_name": "Numero_1",
			"setup": {
				"board": starting_board(),
				"white_hand": ["Numero_1"],
				"white_deck": ["Numero_2", "Numero_3", "Numero_4"],
				"black_hand": [],
				"black_deck": [],
				"turn_color": PLAYER_COLOR,
			},
			"constraints": {
				"allowed_actions": ["attach_stamp"],
				"allowed_attach_stamp_names": ["Numero_1"],
				"allow_auto_end_turn": false,
			},
		},
		{
			"speaker": MENTOR_NAME,
			"text": "The End Turn button is now active. Press it to finish your first turn. If you attach all three stamps, the turn ends automatically.",
			"completion": "turn_ended",
			"constraints": {
				"allowed_actions": ["end_turn"],
				"allow_auto_end_turn": false,
			},
		},
		{
			"speaker": MENTOR_NAME,
			"text": "From your next turn onward, moving is mandatory and immediately ends your turn. Turn Codex pages and attach before moving. Select the ready piece, then move it to a highlighted square.",
			"completion": "piece_moved",
			"setup": {
				"board": starting_board(),
				"attached_stamps": [{"pos": Vector2(0, 1), "stamp_name": "Numero_1", "turns_remaining": 3, "exhausted": false}],
				"white_hand": [],
				"white_deck": ["Numero_2", "Numero_3", "Numero_4"],
				"black_hand": [],
				"black_deck": [],
				"turn_color": PLAYER_COLOR,
			},
			"constraints": {
				"allowed_actions": ["select_piece", "move_piece"],
				"allowed_move_sources": [Vector2(0, 1)],
				"allow_auto_end_turn": false,
			},
		},
		{
			"speaker": MENTOR_NAME,
			"text": "After a piece moves, its stamp loses one duration and the turn ends. Stamps do not tick down merely because another piece moved.",
			"completion": "dialogue",
			"constraints": no_actions(),
		},
		{
			"speaker": MENTOR_NAME,
			"text": "You can attach more than one stamp in a turn. Put both stamps from your hand onto two empty pieces.",
			"completion": "stamp_attached",
			"required_count": 2,
			"setup": {
				"board": starting_board(),
				"attached_stamps": [{"pos": Vector2(0, 1), "stamp_name": "Numero_1", "turns_remaining": 3, "exhausted": false}],
				"white_hand": ["Numero_2", "Numero_3"],
				"white_deck": ["Numero_4", "Numero_5", "Numero_6"],
				"black_hand": [],
				"black_deck": [],
				"turn_color": PLAYER_COLOR,
			},
			"constraints": {
				"allowed_actions": ["attach_stamp"],
				"allowed_attach_stamp_names": ["Numero_2", "Numero_3"],
				"allow_auto_end_turn": false,
			},
		},
		{
			"speaker": MENTOR_NAME,
			"text": "Good. Now move the piece that was already ready. A successful move ends the turn. Spent non-Seeker stamps stay out of the Codex.",
			"completion": "piece_moved",
			"constraints": {
				"allowed_actions": ["select_piece", "move_piece"],
				"allowed_move_sources": [Vector2(0, 1)],
				"allow_auto_end_turn": false,
			},
		},
		{
			"speaker": MENTOR_NAME,
			"text": "Once per turn, before attaching any stamp, you may turn the Codex to the next non-empty page. Press Turn Page.",
			"completion": "codex_page_turned",
			"continue_after_completion": true,
			"post_completion_text": "The new page is now open, and only that page's stamps are usable. Press Continue when you are ready.",
			"setup": {
				"board": starting_board(),
				"white_hand": ["Numero_4"],
				"white_deck": ["Numero_5", "Numero_6", "Training Seal"],
				"black_hand": [],
				"black_deck": [],
				"turn_color": PLAYER_COLOR,
			},
			"constraints": {
				"allowed_actions": ["turn_page"],
				"allow_auto_end_turn": false,
			},
		},
		{
			"speaker": MENTOR_NAME,
			"text": "In multiplayer, each player has five minutes for the whole match. Your clock runs only during your turns; reaching 00:00 loses the game.",
			"completion": "dialogue",
			"constraints": no_actions(),
		},
		{
			"speaker": MENTOR_NAME,
			"text": "Some stamps have effects. Drag Training Seal onto a piece; its effect will mark frozen squares around it.",
			"completion": "stamp_attached",
			"expected_stamp_name": "Training Seal",
			"setup": {
				"board": starting_board(),
				"white_hand": ["Training Seal"],
				"white_deck": ["Numero_1", "Numero_2", "Numero_3"],
				"black_hand": [],
				"black_deck": [],
				"turn_color": PLAYER_COLOR,
			},
			"constraints": {
				"allowed_actions": ["attach_stamp"],
				"allowed_attach_stamp_names": ["Training Seal"],
				"allow_auto_end_turn": false,
			},
		},
		{
			"speaker": MENTOR_NAME,
			"text": "Those blue marks are board effects. Effects can change what pieces may do, separate from the stamp's movement pattern.",
			"completion": "dialogue",
			"constraints": no_actions(),
		},
		{
			"speaker": MENTOR_NAME,
			"text": "Now capture the enemy piece. The first captured piece returns locked to a non-base square on its starting row. A later capture unlocks it instead of creating another respawn.",
			"completion": "piece_moved",
			"continue_after_completion": true,
			"post_completion_text": "The captured piece returned to its home row. Its attached stamp is gone, and it stays locked until another piece is captured. Press Continue when you are ready.",
			"expected_from": Vector2(3, 2),
			"expected_to": Vector2(3, 3),
			"setup": {
				"board": capture_board(),
				"attached_stamps": [
					{
						"pos": Vector2(3, 2),
						"stamp_name": "Training Seal",
						"turns_remaining": 3,
						"exhausted": false,
					},
				],
				"white_hand": [],
				"white_deck": ["Numero_1", "Numero_2", "Numero_3"],
				"black_hand": [],
				"black_deck": [],
				"turn_color": PLAYER_COLOR,
			},
			"constraints": {
				"allowed_actions": ["select_piece", "move_piece"],
				"allowed_move_sources": [Vector2(3, 2)],
				"allowed_move_targets": [Vector2(3, 3)],
				"allow_auto_end_turn": false,
			},
		},
		{
			"speaker": MENTOR_NAME,
			"text": "Seeker stamps are special. Attach Crown to a piece. If a Seeker is captured, it returns to its original Codex page.",
			"completion": "stamp_attached",
			"expected_stamp_name": "Crown",
			"setup": {
				"board": starting_board(),
				"white_hand": ["Crown"],
				"white_deck": ["Numero_1", "Numero_2", "Numero_3"],
				"black_hand": [],
				"black_deck": [],
				"turn_color": PLAYER_COLOR,
			},
			"constraints": {
				"allowed_actions": ["attach_stamp"],
				"allowed_attach_stamp_names": ["Crown"],
				"allow_auto_end_turn": false,
			},
		},
		{
			"speaker": MENTOR_NAME,
			"text": "To win, a piece with a Seeker must move onto the opponent's base. Make the winning move.",
			"completion": "piece_moved",
			"expected_from": Vector2(5, 3),
			"expected_to": Vector2(6, 3),
			"setup": {
				"board": win_board(),
				"attached_stamps": [
					{
						"pos": Vector2(5, 3),
						"stamp_name": "Crown",
						"turns_remaining": 5,
						"exhausted": false,
					},
				],
				"white_hand": [],
				"white_deck": ["Numero_1", "Numero_2", "Numero_3"],
				"black_hand": [],
				"black_deck": [],
				"turn_color": PLAYER_COLOR,
			},
			"constraints": {
				"allowed_actions": ["select_piece", "move_piece"],
				"allowed_move_sources": [Vector2(5, 3)],
				"allowed_move_targets": [Vector2(6, 3)],
				"allow_auto_end_turn": false,
			},
			"finish_after_completion": true,
		},
	]

func no_actions() -> Dictionary:
	return {
		"allowed_actions": [],
		"allow_auto_end_turn": false,
	}

func starting_board() -> Array:
	return [
		[1, 1, 1, 0, 1, 1, 1],
		[0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0],
		[-1, -1, -1, 0, -1, -1, -1],
	]

func capture_board() -> Array:
	return [
		[1, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0],
		[0, 0, 1, -1, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, -1],
	]

func win_board() -> Array:
	return [
		[0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 1, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0],
	]

func start_step(step_index: int) -> void:
	if step_index < 0 or step_index >= steps.size():
		finish_tutorial()
		return

	current_step_index = step_index
	attached_this_step = 0
	moved_this_step = 0
	waiting_for_continue_after_completion = false

	var step: Dictionary = steps[current_step_index]
	if step.has("setup") and board.has_method("apply_tutorial_setup"):
		board.apply_tutorial_setup(step.get("setup", {}))

	var constraints: Dictionary = step.get("constraints", {}).duplicate(true)
	if board.has_method("set_tutorial_constraints"):
		board.set_tutorial_constraints(constraints)

	var speaker: String = str(step.get("speaker", MENTOR_NAME))
	dialogue_panel.show_line(speaker, str(step.get("text", "")), get_portrait_for_speaker(speaker), should_show_continue_for_step(step))

func finish_tutorial() -> void:
	if board != null and board.has_method("clear_tutorial_constraints"):
		board.clear_tutorial_constraints()
	if board != null and board.has_method("set_tutorial_mode_active"):
		board.set_tutorial_mode_active(false)
	current_step_index = -1
	dialogue_panel.show_line(MENTOR_NAME, "Tutorial complete. Good work.", mentor_portrait, true)

func _on_dialogue_continue_requested() -> void:
	if waiting_for_continue_after_completion:
		waiting_for_continue_after_completion = false
		advance_current_step()
		return

	if !is_current_completion("dialogue"):
		return
	advance_current_step()

func _on_stamp_attached(piece_pos: Vector2, stamp_name: String, owner_color: int, _hand_index: int) -> void:
	if !is_current_completion("stamp_attached"):
		return

	var step: Dictionary = get_current_step()
	if owner_color != PLAYER_COLOR:
		return
	var expected_stamp_name: String = str(step.get("expected_stamp_name", ""))
	if !expected_stamp_name.is_empty() and stamp_name != expected_stamp_name:
		return

	attached_this_step += 1
	if attached_this_step >= int(step.get("required_count", 1)):
		complete_current_action_step()

func _on_stamp_exchanged(stamp_name: String, owner_color: int, _hand_index: int) -> void:
	if !is_current_completion("stamp_exchanged"):
		return

	var step: Dictionary = get_current_step()
	if owner_color != PLAYER_COLOR:
		return
	var expected_stamp_name: String = str(step.get("expected_stamp_name", ""))
	if !expected_stamp_name.is_empty() and stamp_name != expected_stamp_name:
		return

	complete_current_action_step()

func _on_codex_page_turned(owner_color: int, _page_index: int) -> void:
	if !is_current_completion("codex_page_turned"):
		return
	if owner_color != PLAYER_COLOR:
		return
	complete_current_action_step()

func _on_piece_moved(from_pos: Vector2, to_pos: Vector2, owner_color: int) -> void:
	if !is_current_completion("piece_moved"):
		return

	var step: Dictionary = get_current_step()
	if owner_color != PLAYER_COLOR:
		return
	var expected_from: Vector2 = value_to_vector2(step.get("expected_from", INVALID_BOARD_POS), INVALID_BOARD_POS)
	if expected_from != INVALID_BOARD_POS and from_pos != expected_from:
		return

	var expected_to: Vector2 = value_to_vector2(step.get("expected_to", INVALID_BOARD_POS), INVALID_BOARD_POS)
	if expected_to != INVALID_BOARD_POS and to_pos != expected_to:
		return

	moved_this_step += 1
	if moved_this_step < int(step.get("required_count", 1)):
		return

	if bool(step.get("finish_after_completion", false)):
		current_step_index = -1
		return

	complete_current_action_step()

func _on_turn_ended(ending_color: int, _next_color: int) -> void:
	if !is_current_completion("turn_ended") or ending_color != PLAYER_COLOR:
		return
	complete_current_action_step()

func _on_tutorial_action_rejected(_action_name: String, _context: Dictionary) -> void:
	if current_step_index < 0 or current_step_index >= steps.size():
		return

	var step: Dictionary = steps[current_step_index]
	var speaker: String = str(step.get("speaker", MENTOR_NAME))
	dialogue_panel.show_line(speaker, str(step.get("rejection_text", step.get("text", ""))), get_portrait_for_speaker(speaker), should_show_continue_for_step(step))

func advance_current_step() -> void:
	start_step(current_step_index + 1)

func complete_current_action_step() -> void:
	var step: Dictionary = get_current_step()
	if bool(step.get("continue_after_completion", false)):
		waiting_for_continue_after_completion = true
		if board != null and board.has_method("set_tutorial_constraints"):
			board.set_tutorial_constraints(no_actions())
		var speaker: String = str(step.get("speaker", MENTOR_NAME))
		dialogue_panel.show_line(speaker, str(step.get("post_completion_text", step.get("text", ""))), get_portrait_for_speaker(speaker), true)
		return

	advance_current_step()

func get_portrait_for_speaker(speaker: String) -> PortraitConfig:
	if speaker == MENTOR_NAME:
		return mentor_portrait
	return null

func get_current_step() -> Dictionary:
	if current_step_index < 0 or current_step_index >= steps.size():
		return {}
	return steps[current_step_index]

func is_current_completion(completion_name: String) -> bool:
	return str(get_current_step().get("completion", "")) == completion_name

func should_show_continue_for_step(step: Dictionary) -> bool:
	return str(step.get("completion", "")) == "dialogue"

func value_to_vector2(value, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		var vector_value: Vector2i = value
		return Vector2(vector_value.x, vector_value.y)
	if value is Array:
		var array_value: Array = value
		if array_value.size() >= 2:
			return Vector2(float(array_value[0]), float(array_value[1]))
	return fallback
