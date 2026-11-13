extends Node

## Plays the puzzle PuzzleStore.active_puzzle_id names on Scenes/PuzzleMatch.tscn:
## a match board on plain white, set up as the puzzle says, with the player on
## white and the opponent played by the puzzle's script.
##
## The board runs in tutorial mode, as the tutorial's does - locally, with no
## host - but with no constraints on the player's own turns: every rule of the
## game holds. During the opponent's turns nothing may be touched.
##
## The puzzle is solved the moment all of its goals hold (PuzzleGoal), checked
## after everything the player does, and the reward scene takes over
## (Scenes/PuzzleReward.tscn); it fails when the turn limit runs out, when the
## opponent wins, or when the player has nothing left to do.
## Docs/Puzzles/PUZZLES.md.

const PLAYER_COLOR: int = 1
const OPPONENT_COLOR: int = -1
const PUZZLES_SCENE: String = "res://Scenes/Puzzles.tscn"
const PUZZLE_SCENE: String = "res://Scenes/PuzzleMatch.tscn"
const REWARD_SCENE: String = "res://Scenes/PuzzleReward.tscn"
const NO_ACTIONS: Dictionary = {"allowed_actions": [], "allow_auto_end_turn": false}

@export var board_path: NodePath = NodePath("../MatchBoard")
@export var match_intro_path: NodePath = NodePath("../MatchIntroController")
## How long the opponent takes over its turn: before it does anything, after
## a stamp, and before it hands back a turn without a move.
@export_range(0.0, 5.0, 0.05) var opponent_think_seconds: float = 0.8
@export_range(0.0, 5.0, 0.05) var opponent_between_stamps_seconds: float = 0.5
@export_range(0.0, 5.0, 0.05) var opponent_end_turn_delay: float = 0.6
## How long the board stays in view after the puzzle is decided, before the
## failure comes up or the reward scene takes over.
@export_range(0.0, 5.0, 0.05) var result_delay_seconds: float = 1.2

var puzzle: PuzzleDefinition
var board
var match_intro: MatchIntroController
var hud: PuzzleHud

var turns_used: int = 0
var opponent_turn_index: int = 0
var over: bool = false
## Bumped on every restart, so what an earlier run set going knows it is stale.
var run_token: int = 0
## The golems by the square they started on.
var tracked: Dictionary = {}
## Who stood where when the player's move began, to tell a capture.
var occupants: Dictionary = {}
var captured: Array[Piece] = []
var affixes: Array[Dictionary] = []
var crowned: Array[Piece] = []
var player_won: bool = false
## The game itself is over (won, lost, or stuck), not just the puzzle.
var game_ended: bool = false

func _ready() -> void:
	puzzle = PuzzleLibrary.get_puzzle(PuzzleStore.active_puzzle_id)
	GameConfig.set_match_room(MatchBackgroundController.Variant.PLAIN, false)
	call_deferred("begin")

func _exit_tree() -> void:
	GameConfig.clear_match_room()

func begin() -> void:
	board = get_node_or_null(board_path)
	match_intro = get_node_or_null(match_intro_path) as MatchIntroController
	if board == null:
		push_error("PuzzleController could not find the board.")
		return
	if puzzle == null:
		push_error("No puzzle to play: '%s'." % PuzzleStore.active_puzzle_id)
		SceneTransition.change_scene(PUZZLES_SCENE)
		return

	board.get_tutorial_match_adapter().set_mode_active(true)
	board.hold_after_result = true
	board.get_match_board_lifecycle_controller().set_turn(true)
	board.get_tutorial_match_adapter().set_constraints(NO_ACTIONS)
	# A puzzle is not played against the clock.
	board.get_turn_hud_controller().clock_enabled = false
	_connect_board()
	_set_up_board()

	var hud_layer := CanvasLayer.new()
	hud_layer.name = "PuzzleHudLayer"
	hud_layer.layer = 20
	add_child(hud_layer)
	hud = PuzzleHud.new(puzzle)
	hud.theme = preload("res://ui/themes/global_theme.tres")
	hud_layer.add_child(hud)
	hud.restart_requested.connect(restart)
	hud.leave_requested.connect(leave)
	hud.set_moves(turns_used, puzzle.turn_limit)

	if match_intro == null:
		_on_interface_revealed()
		return
	match_intro.interface_revealed.connect(_on_interface_revealed, CONNECT_ONE_SHOT)
	match_intro.begin()

func _on_interface_revealed() -> void:
	# Nobody sits across the table.
	board.get_turn_hud_controller().set_hud_element_visible(&"opponent_panel", false)
	hud.fade_in()
	_begin_player_turn()

func _connect_board() -> void:
	board.stamp_affixed.connect(_on_stamp_affixed)
	board.piece_moved.connect(_on_piece_moved)
	board.turn_ended.connect(_on_turn_ended)
	board.game_finished.connect(_on_game_finished)
	board.get_crown_controller().crown_placed.connect(_on_crown_placed)

# --- The board ------------------------------------------------------------------

## The puzzle's position, as a board in the middle of a game: both sides have
## played a turn, so the first-turn rules do not apply. The board plays it on a
## host of its own, by every rule of the game, the opponent's side by script.
func _set_up_board() -> void:
	var rows: Array = []
	for _row in range(BoardConfig.BOARD_SIZE):
		var row: Array = []
		row.resize(BoardConfig.BOARD_SIZE)
		row.fill(0)
		rows.append(row)
	var affixed: Array = []
	var crowned_squares: Array = []
	var exhausted_squares: Array = []
	for piece in puzzle.pieces:
		if piece == null:
			continue
		var pos: Vector2 = piece.get_board_position()
		rows[int(pos.x)][int(pos.y)] = piece.get_color()
		if piece.crowned:
			crowned_squares.append(pos)
		if piece.exhausted:
			exhausted_squares.append(pos)
		if piece.stamp != null:
			affixed.append({
				"pos": pos,
				"stamp_name": piece.stamp.stamp_name,
				"turns_remaining": piece.get_moves_left(),
				"exhausted": piece.exhausted,
			})

	var setup: Dictionary = {
		"board": rows,
		"affixed_stamps": affixed,
		"crowned": crowned_squares,
		"exhausted": exhausted_squares,
		# The pages exactly as written, empty slots and all.
		"white_pages": puzzle.get_player_pages(),
		"black_pages": puzzle.get_opponent_pages(),
		"turn_color": PLAYER_COLOR,
		"crown_points": {
			PLAYER_COLOR: puzzle.player_crown_points,
			OPPONENT_COLOR: puzzle.opponent_crown_points,
		},
		"completed_turns": {PLAYER_COLOR: 1, OPPONENT_COLOR: 1},
	}
	if GameController.current_game_host == null:
		board.get_tutorial_match_adapter().start_local_host(setup, [OPPONENT_COLOR])
	else:
		board.get_tutorial_match_adapter().apply_setup(setup)

	# The golems as the host keeps them, which stay the same objects through
	# every move, capture and return - the board's are rebuilt with each state.
	tracked.clear()
	for piece in puzzle.pieces:
		if piece == null:
			continue
		var in_play: Piece = _state().get_piece(piece.get_board_position())
		if in_play != null:
			tracked[piece.square] = in_play
	_note_occupants()

## The match as the host has it: the puzzle is judged on that, not on the
## board's picture of it.
func _state() -> GameStateData:
	return GameController.current_game_host.game_state

func _note_occupants() -> void:
	occupants = _state().pieces.duplicate()

## The player's turn: the whole game is theirs to play.
func _begin_player_turn() -> void:
	if over:
		return
	_note_occupants()
	board.get_tutorial_match_adapter().clear_constraints()
	hud.set_moves(turns_used, puzzle.turn_limit)
	_check_goals()

# --- What the player does -------------------------------------------------------

func _on_stamp_affixed(piece_pos: Vector2, stamp_name: String, owner_color: int, _hand_index: int) -> void:
	if owner_color != PLAYER_COLOR or over:
		return
	affixes.append({"stamp_name": stamp_name, "piece": _state().get_piece(piece_pos)})
	_check_goals_after_visuals()

func _on_crown_placed(piece_pos: Vector2, owner_color: int) -> void:
	if owner_color != PLAYER_COLOR or over:
		return
	var piece: Piece = _state().get_piece(piece_pos)
	if piece != null:
		crowned.append(piece)
	_check_goals_after_visuals()

## A move by the player that lands where an opponent's golem stood took it.
func _on_piece_moved(_from_pos: Vector2, to_pos: Vector2, owner_color: int) -> void:
	if owner_color != PLAYER_COLOR or over:
		return
	var victim: Piece = occupants.get(to_pos, null) as Piece
	if victim != null and victim.color == OPPONENT_COLOR:
		captured.append(victim)

func _on_turn_ended(ending_color: int, _next_color: int) -> void:
	if over:
		return
	var token: int = run_token
	await board.get_turn_flow_controller().wait_for_pending_visual_processes()
	if token != run_token or over:
		return
	if ending_color == PLAYER_COLOR:
		turns_used += 1
		if _check_goals():
			return
		if turns_used >= puzzle.turn_limit:
			_fail(tr("PUZZLE_FAILED_OUT_OF_MOVES") % puzzle.turn_limit)
			return
		hud.set_moves_text(tr("PUZZLE_OPPONENT_MOVING"))
		_play_opponent_turn(token)
	else:
		_begin_player_turn()

func _on_game_finished(winner_color: int) -> void:
	# The puzzle's own result takes the place of the match's; the match has
	# already played its sound.
	var result_overlay: Control = board.get_turn_hud_controller().result_overlay
	if result_overlay != null:
		result_overlay.visible = false
	if over:
		return
	game_ended = true
	if winner_color == PLAYER_COLOR:
		player_won = true
		if !_check_goals():
			_fail(tr("PUZZLE_FAILED_WON_WRONG"))
		return
	_fail(tr("PUZZLE_FAILED_OPPONENT_WON") if _opponent_reached_base() else tr("PUZZLE_FAILED_STUCK"))

func _opponent_reached_base() -> bool:
	var base: Vector2 = StampEffectResolver.get_base_field_for_player(_state(), BoardConfig.get_player_id_for_color(PLAYER_COLOR))
	var piece: Piece = _state().get_piece(base)
	return piece != null and piece.color == OPPONENT_COLOR and piece.has_crown

# --- Goals ----------------------------------------------------------------------

func _check_goals_after_visuals() -> void:
	var token: int = run_token
	await board.get_turn_flow_controller().wait_for_pending_visual_processes()
	if token == run_token:
		_check_goals()

## True, and the puzzle is solved, when every goal holds.
func _check_goals() -> bool:
	if over or puzzle.goals.is_empty():
		return false
	for goal in puzzle.goals:
		if goal != null and !_is_goal_met(goal):
			return false
	_solve()
	return true

func _is_goal_met(goal: PuzzleGoal) -> bool:
	match goal.kind:
		PuzzleGoal.Kind.WIN_GAME:
			return player_won
		PuzzleGoal.Kind.CAPTURE_PIECE:
			var target: Piece = tracked.get(goal.target_square, null) as Piece
			return target != null and captured.has(target)
		PuzzleGoal.Kind.CAPTURE_COUNT:
			return captured.size() >= goal.count
		PuzzleGoal.Kind.REACH_SQUARE:
			var piece: Piece = _state().get_piece(PuzzleSquares.to_board(goal.target_square))
			return _is_goal_piece(goal, piece)
		PuzzleGoal.Kind.STAMP_DURATION:
			for position_value in _state().pieces:
				var piece: Piece = _state().pieces[position_value] as Piece
				if _is_goal_piece(goal, piece) and piece.affixed_stamp != null and goal.compare(piece.turns_remaining):
					return true
			return false
		PuzzleGoal.Kind.AFFIX_STAMP:
			var count: int = 0
			for affix in affixes:
				if goal.stamp != null and str(affix["stamp_name"]) != goal.stamp.stamp_name:
					continue
				if !goal.piece_square.is_empty() and affix["piece"] != tracked.get(goal.piece_square, null):
					continue
				count += 1
			return count >= maxi(1, goal.count)
		PuzzleGoal.Kind.PLACE_CROWN:
			for piece in crowned:
				if goal.piece_square.is_empty() or piece == tracked.get(goal.piece_square, null):
					return true
			return false
	return false

## A golem of the player's that the goal is about: the one it names by its
## starting square, wearing the stamp it names.
func _is_goal_piece(goal: PuzzleGoal, piece: Piece) -> bool:
	if piece == null or piece.color != PLAYER_COLOR:
		return false
	if !goal.piece_square.is_empty() and piece != tracked.get(goal.piece_square, null):
		return false
	if goal.stamp != null and (piece.affixed_stamp == null or piece.affixed_stamp.stamp_name != goal.stamp.stamp_name):
		return false
	return true

# --- The opponent ---------------------------------------------------------------

## One turn of the opponent's: a win or a capture if it takes its chances and
## has one, otherwise the script's stamp and move; a turn without a move ends
## on its own.
func _play_opponent_turn(token: int) -> void:
	board.get_tutorial_match_adapter().set_constraints(NO_ACTIONS)
	await get_tree().create_timer(opponent_think_seconds).timeout
	if token != run_token or over:
		return
	var script: PuzzleOpponentTurn = null
	if opponent_turn_index < puzzle.opponent_turns.size():
		script = puzzle.opponent_turns[opponent_turn_index]
	opponent_turn_index += 1

	if puzzle.opponent_takes_chances:
		var chance: Dictionary = _find_opponent_chance()
		if !chance.is_empty():
			board.get_tutorial_match_adapter().play_scripted_move(OPPONENT_COLOR, chance["from"], chance["to"])
			return

	if script != null and script.has_affix():
		await _play_opponent_affix(script)
		if token != run_token or over:
			return

	if script != null and script.has_move():
		var from_pos: Vector2 = PuzzleSquares.to_board(script.move_from)
		var to_pos: Vector2 = PuzzleSquares.to_board(script.move_to)
		if _opponent_moves_from(from_pos).has(to_pos):
			board.get_tutorial_match_adapter().play_scripted_move(OPPONENT_COLOR, from_pos, to_pos)
			return
		push_warning("Puzzle %s: the opponent cannot move %s-%s; it passes." % [puzzle.puzzle_id, script.move_from, script.move_to])

	await get_tree().create_timer(opponent_end_turn_delay).timeout
	if token == run_token and !over and !board.game_over:
		board.get_tutorial_match_adapter().pass_scripted_turn(OPPONENT_COLOR)

func _play_opponent_affix(script: PuzzleOpponentTurn) -> void:
	var stamp_name: String = script.affix_stamp.stamp_name
	var piece_pos: Vector2 = PuzzleSquares.to_board(script.affix_square)
	var piece: Piece = _state().get_piece(piece_pos)
	if !_state().player_hands.get(BoardConfig.get_player_id_for_color(OPPONENT_COLOR), []).has(stamp_name) or piece == null or piece.color != OPPONENT_COLOR or !piece.can_receive_stamp(script.affix_stamp):
		push_warning("Puzzle %s: the opponent cannot affix %s on %s." % [puzzle.puzzle_id, stamp_name, script.affix_square])
		return
	await board.get_tutorial_match_adapter().play_scripted_affix(OPPONENT_COLOR, stamp_name, piece_pos)
	await get_tree().create_timer(opponent_between_stamps_seconds).timeout

func _opponent_moves_from(from_pos: Vector2) -> Array[Vector2]:
	var player_id: int = BoardConfig.get_player_id_for_color(OPPONENT_COLOR)
	return MoveRules.get_piece_moves_for_player(_state().pieces, from_pos, player_id, BoardConfig.BOARD_SIZE, _state().board_effects)

## The opponent's best chance: a crowned golem onto the player's base, or else
## the most valuable capture - a crowned golem, then one a goal is about, then
## one with moves on its stamp. Empty when it has neither.
func _find_opponent_chance() -> Dictionary:
	var player_base: Vector2 = StampEffectResolver.get_base_field_for_player(_state(), BoardConfig.get_player_id_for_color(PLAYER_COLOR))
	var goal_pieces: Array = []
	for goal in puzzle.goals:
		if goal != null and !goal.piece_square.is_empty():
			goal_pieces.append(tracked.get(goal.piece_square, null))
	var best: Dictionary = {}
	var best_score: int = -1
	var positions: Array = _state().pieces.keys()
	positions.sort()
	for position_value in positions:
		var piece: Piece = _state().pieces[position_value] as Piece
		if piece == null or piece.color != OPPONENT_COLOR:
			continue
		for target: Vector2 in _opponent_moves_from(position_value):
			var score: int = -1
			if target == player_base and piece.has_crown:
				score = 10000
			var victim: Piece = _state().get_piece(target)
			if victim != null and victim.color == PLAYER_COLOR:
				var value: int = 100
				if victim.has_crown:
					value += 1000
				if goal_pieces.has(victim):
					value += 500
				if victim.affixed_stamp != null:
					value += 50 + maxi(0, victim.turns_remaining)
				score = maxi(score, value)
			if score > best_score:
				best_score = score
				best = {"from": position_value, "to": target}
	return best

# --- The end --------------------------------------------------------------------

func _solve() -> void:
	over = true
	run_token += 1
	board.get_tutorial_match_adapter().set_constraints(NO_ACTIONS)
	# Quests count a puzzle once, the first time it is solved.
	if !PuzzleStore.is_solved(puzzle.puzzle_id):
		QuestStore.record_event(QuestCondition.EVENT_PUZZLE_SOLVED, {"puzzle_id": puzzle.puzzle_id})
	PuzzleStore.mark_solved(puzzle.puzzle_id)
	PuzzleStore.last_reward_paid = PuzzleStore.grant_reward(puzzle)
	hud.set_moves_text(tr("PUZZLE_STATE_SOLVED"))
	await board.get_turn_flow_controller().wait_for_pending_visual_processes()
	if !game_ended:
		SFXManager.play("win")
	# The board stays in view a moment; the reward has a scene of its own.
	await get_tree().create_timer(result_delay_seconds).timeout
	SceneTransition.change_scene(REWARD_SCENE)

func _fail(reason: String) -> void:
	over = true
	run_token += 1
	board.get_tutorial_match_adapter().set_constraints(NO_ACTIONS)
	await board.get_turn_flow_controller().wait_for_pending_visual_processes()
	await get_tree().create_timer(result_delay_seconds).timeout
	if !game_ended:
		SFXManager.play("lose")
	hud.show_failed(reason)

## From the top: the same position on a fresh board, in place when the board
## is at rest. A finished game, or a move still under way, reloads the scene.
func restart() -> void:
	if board.game_over or board.get_turn_flow_controller().has_pending_visual_processes():
		run_token += 1
		SceneTransition.change_scene(PUZZLE_SCENE)
		return
	run_token += 1
	over = false
	game_ended = false
	turns_used = 0
	opponent_turn_index = 0
	captured.clear()
	affixes.clear()
	crowned.clear()
	player_won = false
	hud.hide_result()
	board.get_tutorial_match_adapter().set_constraints(NO_ACTIONS)
	_set_up_board()
	_begin_player_turn()

func leave() -> void:
	run_token += 1
	SceneTransition.change_scene(PUZZLES_SCENE)
