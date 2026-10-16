extends Node

const PLAYER_COLOR: int = 1
const OPPONENT_COLOR: int = -1
## Grandpa teaches the tutorial. He is the first boss, so his name comes from
## that boss's definition and matches what the player meets later. The
## tutorial shows no faces, only names and words.
const GRANDPA_SPEAKER: String = "grandpa"
const GRANDPA_BOSS: BossDefinition = preload("res://Story/Bosses/boss_01.tres")
const INVALID_BOARD_POS: Vector2 = Vector2(-1, -1)

@export var board_path: NodePath = NodePath("../MatchBoard")
@export var dialogue_panel_path: NodePath = NodePath("../CanvasLayer/DialoguePanel")
@export var intro_path: NodePath = NodePath("../TutorialIntro")
@export var outro_path: NodePath = NodePath("../TutorialOutro")
## How long the won game's result stays up before Grandpa's last word.
@export_range(0.0, 10.0, 0.1) var outro_delay_seconds: float = 2.5
@export var match_intro_path: NodePath = NodePath("../MatchIntroController")
## The player's codex: a long line is kept clear of its top edge.
@export var codex_path: NodePath = NodePath("../CanvasLayer/Codex")
## How far above the codex a long line's box has to stop - enough to clear
## it when it lifts under the mouse too.
@export var dialogue_codex_clearance: float = 24.0
## The highest a long line's box may be lifted to, so the name above the
## words stays on screen.
@export var dialogue_top_margin: float = 30.0

## How long Grandpa takes over his scripted turn: before he does anything,
## between stamps, and before he ends a turn that has no move in it.
@export_range(0.0, 5.0, 0.05) var opponent_think_seconds: float = 0.9
@export_range(0.0, 5.0, 0.05) var opponent_between_stamps_seconds: float = 0.5
@export_range(0.0, 5.0, 0.05) var opponent_end_turn_delay: float = 0.8

var board
var dialogue_panel
var match_intro: MatchIntroController
var steps: Array[Dictionary] = []
var current_step_index: int = -1
var affixed_this_step: int = 0
var moved_this_step: int = 0
var waiting_for_continue_after_completion: bool = false
## Bumped whenever a step starts or completes, so whatever a step set going
## (Grandpa's turn, a wait for an animation) knows when it is out of date.
var step_token: int = 0
var step_glow: HintGlow

## A move only counts once it has ended the turn - every move does - so what
## it decided is parked here until then: "complete", "retry" or nothing.
var pending_turn_outcome: String = ""
## Which of the step's scripted Grandpa turns comes next.
var opponent_turn_index: int = 0
## Continue stays away until Grandpa has finished the turn the line is about.
var continue_held_for_opponent: bool = false
## Where the opponent's pieces stand at the start of the player's turn, so a
## move can be told to be a capture.
var opponent_positions: Dictionary = {}
## For a "stamp_moves" step: the piece carrying the stamp, and how often it
## has moved.
var tracked_stamp_pos: Vector2 = INVALID_BOARD_POS
var tracked_stamp_moves: int = 0
## Where the player's last move landed, for a step that punishes a careless
## one.
var last_player_move_to: Vector2 = INVALID_BOARD_POS
## Grandpa is taking a piece left where he could reach it; once his turn is
## over the step starts again.
var retry_after_opponent: bool = false

func _ready() -> void:
	# Grandpa's room, as in his own match. Settled here because the room is
	# dressed as the scene becomes ready, before the tutorial itself begins.
	GameConfig.set_match_room(int(GRANDPA_BOSS.room_variant), GRANDPA_BOSS.show_opponent_codex)
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
	prepare_outro()
	dress_dialogue_panel()
	build_steps()
	match_intro = get_node_or_null(match_intro_path) as MatchIntroController

	var intro: TutorialIntro = get_node_or_null(intro_path) as TutorialIntro
	if intro == null or match_intro == null:
		begin_match_scene()
		return
	# The player sits on white, as in a match against the computer: they act
	# on their own turns only, and Grandpa's turns are his.
	board.set_turn(true)
	# Nothing on the board may be touched while Grandpa is talking.
	if board.has_method("set_tutorial_constraints"):
		board.set_tutorial_constraints(no_actions())
	if board.has_method("apply_tutorial_setup"):
		board.apply_tutorial_setup(grandpa_codex_setup(intro.codex_stamp_names))
	match_intro.hide_everything()
	intro.finished.connect(_on_intro_finished, CONNECT_ONE_SHOT)
	intro.play(get_speaker_name(GRANDPA_SPEAKER), board, match_intro, dialogue_panel)

## Once the game is won the result goes up as in any match, but the tutorial
## does not leave on its own: Grandpa asks if the player is ready for a real
## game, and the answer moves the story on.
func prepare_outro() -> void:
	var outro: TutorialOutro = get_node_or_null(outro_path) as TutorialOutro
	if outro == null:
		return
	board.hold_after_result = true
	board.game_finished.connect(_on_game_finished.bind(outro), CONNECT_ONE_SHOT)
	outro.answered.connect(_on_outro_answered, CONNECT_ONE_SHOT)

func _on_game_finished(_winner_color: int, outro: TutorialOutro) -> void:
	finish_tutorial()
	await get_tree().create_timer(outro_delay_seconds).timeout
	outro.play(get_speaker_name(GRANDPA_SPEAKER))

## The tutorial is done; the story goes on to whatever follows it.
func _on_outro_answered() -> void:
	StoryManager.finish_current_node()

## Names and words only: no face, and with nothing above the words they are
## centred on the middle of the screen - lifted only as far as a long line
## needs to stay off the codex.
func dress_dialogue_panel() -> void:
	dialogue_panel.set_portrait_enabled(false)
	dialogue_panel.centre_on_screen_middle(get_dialogue_bottom_limit, dialogue_top_margin)

## The top of the codex where it rests, less the clearance. Asked for afresh
## every time, because the codex rests lower or higher as the window changes.
func get_dialogue_bottom_limit() -> float:
	var codex = get_node_or_null(codex_path)
	if codex == null or !("rest_position" in codex):
		return INF
	return float(codex.rest_position.y) - dialogue_codex_clearance

## The room, the board and the HUD draw themselves, and the first step starts.
func begin_match_scene() -> void:
	if match_intro != null:
		match_intro.begin()
	start_step(0)

## The intro has brought the room, the board and most of the interface in;
## the steps take the words over from here.
func _on_intro_finished() -> void:
	start_step(0)

## The board as a game starts, with Grandpa's codex in the player's hands: the
## page the intro shows first, and the rest of his fifteen stamps behind it.
## Grandpa plays from his deck as it is in his own match.
func grandpa_codex_setup(first_page: Array[String]) -> Dictionary:
	var rest: Array[String] = grandpa_deck_without(first_page)
	var grandpa_deck: Array[String] = GRANDPA_BOSS.get_deck_stamp_names()
	var opponent_page: Array[String] = []
	opponent_page.assign(grandpa_deck.slice(0, DeckManager.CODEX_STAMPS_PER_PAGE))
	var opponent_rest: Array[String] = []
	opponent_rest.assign(grandpa_deck.slice(DeckManager.CODEX_STAMPS_PER_PAGE))
	return {
		"board": starting_board(),
		"white_hand": first_page,
		"white_deck": rest,
		"black_hand": opponent_page,
		"black_deck": opponent_rest,
		"turn_color": PLAYER_COLOR,
	}

## Grandpa's fifteen stamps, one of each of `page` taken out - the rest of a
## codex whose open page is `page`.
func grandpa_deck_without(page: Array[String]) -> Array[String]:
	var rest: Array[String] = GRANDPA_BOSS.get_deck_stamp_names()
	for stamp_name in page:
		rest.erase(stamp_name)
	return rest

func connect_board_signals() -> void:
	board.stamp_affixed.connect(_on_stamp_affixed)
	board.stamp_exchanged.connect(_on_stamp_exchanged)
	board.codex_page_turned.connect(_on_codex_page_turned)
	board.piece_moved.connect(_on_piece_moved)
	board.turn_ended.connect(_on_turn_ended)
	board.tutorial_action_rejected.connect(_on_tutorial_action_rejected)

func connect_dialogue_signals() -> void:
	dialogue_panel.continue_requested.connect(_on_dialogue_continue_requested)

## The interactive part that follows the intro, one step at a time.
##
## A step is a Dictionary:
##   "speaker"     who talks (GRANDPA_SPEAKER)
##   "text"        translation key of the line shown while the step is on;
##                 leave it out to keep the previous line up
##   "completion"  what ends the step:
##                   "dialogue"          Continue
##                   "stamp_affixed", "stamp_exchanged", "codex_page_turned"
##                   "piece_moved"       a move, once it has ended the turn
##                   "piece_captured"    a capturing move, likewise
##                   "stamp_moves"       the piece wearing "track_stamp" has
##                                       moved "required_count" times
##                   "turn_ended"        the player's turn, or "turn_color"'s
##                   "game_won"          nothing here: the winning move ends
##                                       the game, and a won game ends the
##                                       tutorial
##   "constraints" what the player may do meanwhile - see no_actions() and
##                 TutorialMatchAdapter.is_action_allowed() for the keys
##                 ("allowed_actions", "allowed_affix_stamp_names",
##                 "allowed_move_sources", "allowed_move_targets", ...)
## and optionally:
##   "setup"                      the board, hands and turn to put in place
##                                first (TutorialMatchAdapter.apply_setup())
##   "expected_stamp_name"        only this stamp counts for "stamp_affixed"
##   "expected_from", "expected_to"  only this move counts for "piece_moved"
##   "required_count"             how many affixes/moves the step needs
##   "retry_on_miss"              "piece_captured": a move that captures
##                                nothing starts the step over
##   "track_stamp"                "stamp_moves": the stamp to follow; if it
##                                comes off before enough moves, the step
##                                starts over
##   "rejection_text"             the line shown when the player tries
##                                something not allowed (default: "text")
##   "continue_after_completion"  after the action, show
##   "post_completion_text"       this line and wait for Continue
##   "finish_after_completion"    the action ends the step list without
##                                finish_tutorial() - for a winning move,
##                                whose game over completes the tutorial
##   "reveal_hud"                 names of interface parts to bring in
##   "glow"                       name of an interface part to glow behind
##                                while the step is on
##   "opponent_turns"             Grandpa's scripted turns while the step is
##                                on, in order, one each time it is his turn:
##                                {"affixes": [{"stamp_name", "pos"}...],
##                                 "move": {"from", "to"}}. A turn with a move
##                                ends with it (a move a script asks for that
##                                is not possible is swapped for one that
##                                captures nothing); one without ends after
##                                the stamps. Run out, and he makes any quiet
##                                move.
##   "punish_unsafe_moves"        a move onto a square Grandpa can capture on
##                                is answered by that capture, and the step
##                                starts over once his turn is done
##   "check_turn"                 name of a method asked after each of the
##                                player's turns; false starts the step over
##                                (the part can no longer be finished)
##   "text_on_opponent_move"      show "text" when Grandpa moves rather than
##                                when the step starts; a "dialogue" step
##                                with Grandpa turns holds Continue until his
##                                turn is over
func build_steps() -> void:
	steps = [
		# First turn: a stamp has to go on before anything else.
		{
			"speaker": GRANDPA_SPEAKER,
			"text": "TUTORIAL_INTRO_7",
			"completion": "stamp_affixed",
			"constraints": {
				"allowed_actions": ["affix_stamp", "turn_page"],
				"allow_auto_end_turn": false,
			},
		},
		{
			"speaker": GRANDPA_SPEAKER,
			"text": "TUTORIAL_STEP_END_TURN",
			"completion": "turn_ended",
			"reveal_hud": ["EndTurnTab"],
			"glow": "EndTurnTab",
			"constraints": {
				"allowed_actions": ["end_turn"],
				"allow_auto_end_turn": false,
			},
		},
		# Grandpa's first turn: two stamps next to his court, then over to the
		# player. His line from the step before stays up meanwhile.
		{
			"speaker": GRANDPA_SPEAKER,
			"completion": "turn_ended",
			"turn_color": OPPONENT_COLOR,
			"opponent_turns": [
				{"affixes": [
					{"stamp_name": "Knight", "pos": Vector2(6, 2)},
					{"stamp_name": "Warlord", "pos": Vector2(6, 4)},
				]},
			],
			"constraints": no_actions(),
		},
		# Second turn: everything is open, and the turn ends with a move.
		{
			"speaker": GRANDPA_SPEAKER,
			"text": "TUTORIAL_STEP_FIRST_MOVE",
			"completion": "piece_moved",
			"constraints": {
				"allowed_actions": ["turn_page", "affix_stamp", "select_piece", "move_piece"],
				"allow_auto_end_turn": false,
			},
		},
		# Grandpa moves his Warlord, which has a single move in it: the stamp
		# runs out under the player's eyes, and the line explains it.
		{
			"speaker": GRANDPA_SPEAKER,
			"text": "TUTORIAL_STEP_EXPIRED",
			"text_on_opponent_move": true,
			"completion": "dialogue",
			"opponent_turns": [
				{"move": {"from": Vector2(6, 4), "to": Vector2(4, 5)}},
			],
			"constraints": no_actions(),
		},
		# A fresh board with captures to choose from: a Knight that can take
		# any of three, a Lance that can take one.
		{
			"speaker": GRANDPA_SPEAKER,
			"text": "TUTORIAL_STEP_CAPTURE",
			"completion": "piece_captured",
			"retry_on_miss": true,
			"setup": capture_setup(),
			"constraints": {
				"allowed_actions": ["select_piece", "move_piece"],
				"allow_auto_end_turn": false,
			},
		},
		# The Golem: its capture gives it a move back. Every golem of the
		# player's is bare and only The Golem may go on; either golem out in
		# front has two captures in a row ahead of it, and Grandpa keeps out
		# of the way with his Lance on the far side.
		{
			"speaker": GRANDPA_SPEAKER,
			"text": "TUTORIAL_STEP_ABILITY",
			"completion": "stamp_moves",
			"track_stamp": "The Golem",
			"required_count": 2,
			"setup": golem_setup(),
			"opponent_turns": [
				{"move": {"from": Vector2(6, 6), "to": Vector2(5, 6)}},
				{"move": {"from": Vector2(5, 6), "to": Vector2(4, 6)}},
			],
			"constraints": {
				"allowed_actions": ["affix_stamp", "end_turn", "select_piece", "move_piece"],
				"allowed_affix_stamp_names": ["The Golem"],
				"allow_auto_end_turn": false,
			},
		},
		# Every one of Grandpa's pieces wears a stamp, and between them they
		# cover all but one of the squares the player's Warlord can jump to.
		# The one left is next to his War Drummer, which can only move onto
		# it, not capture there.
		{
			"speaker": GRANDPA_SPEAKER,
			"text": "TUTORIAL_STEP_DANGER",
			"completion": "piece_moved",
			"punish_unsafe_moves": true,
			"setup": danger_setup(),
			"constraints": {
				"allowed_actions": ["select_piece", "move_piece"],
				"allow_auto_end_turn": false,
			},
		},
		# The last one: the Knight has a single jump left. Land it next to
		# Grandpa's court on the square he cannot reach, put the Prince (a
		# pentagon) on the bare golem, and step into the court. Winning ends
		# the tutorial.
		{
			"speaker": GRANDPA_SPEAKER,
			"text": "TUTORIAL_STEP_COURT",
			"completion": "game_won",
			"punish_unsafe_moves": true,
			"check_turn": "can_still_reach_court",
			"setup": court_setup(),
			"opponent_turns": [
				{"move": {"from": Vector2(6, 0), "to": Vector2(5, 0)}},
				{"move": {"from": Vector2(5, 0), "to": Vector2(6, 0)}},
				{"move": {"from": Vector2(6, 0), "to": Vector2(5, 0)}},
				{"move": {"from": Vector2(5, 0), "to": Vector2(6, 0)}},
			],
			"constraints": {
				"allowed_actions": ["affix_stamp", "end_turn", "select_piece", "move_piece"],
				"allow_auto_end_turn": false,
			},
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

## Row 0 is the player's base line, row 6 Grandpa's. The Knight on (2, 3) can
## take (4, 2), (4, 4) or (3, 5); the Lance on (2, 5) can take (3, 5) too.
func capture_setup() -> Dictionary:
	return {
		"board": [
			[1, 1, 0, 0, 0, 1, 1],
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 1, 0, 1, 0],
			[0, 0, 0, 0, 0, -1, 0],
			[0, 0, -1, 0, -1, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
			[-1, -1, 0, 0, 0, 0, -1],
		],
		"affixed_stamps": [
			{"pos": Vector2(2, 3), "stamp_name": "Knight", "turns_remaining": 3, "exhausted": false},
			{"pos": Vector2(2, 5), "stamp_name": "Lance", "turns_remaining": 2, "exhausted": false},
			{"pos": Vector2(3, 5), "stamp_name": "Archer", "turns_remaining": 1, "exhausted": false},
		],
		"turn_color": PLAYER_COLOR,
	}

## The golems on (2, 2) and (2, 4) are each one step from a capture, and the
## captured piece's square is one step from another: (3, 2) then (4, 2), or
## (3, 4) then (4, 4). The Golem's page is the open one. Grandpa's Lance on
## (6, 6) is the piece he moves, well away from it all.
func golem_setup() -> Dictionary:
	var golem_page: Array[String] = ["Berserk", "The Golem", "War Drummer"]
	var opponent_page: Array[String] = ["Prince", "Knight", "Warlord"]
	return {
		"board": [
			[1, 1, 0, 0, 0, 1, 1],
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 1, 0, 1, 0, 0],
			[0, 0, -1, 0, -1, 0, 0],
			[0, 0, -1, 0, -1, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
			[-1, 0, 0, 0, 0, 0, -1],
		],
		"affixed_stamps": [
			{"pos": Vector2(3, 2), "stamp_name": "Knight", "turns_remaining": 3, "exhausted": false},
			{"pos": Vector2(4, 4), "stamp_name": "Archer", "turns_remaining": 1, "exhausted": false},
			{"pos": Vector2(6, 6), "stamp_name": "Lance", "turns_remaining": 2, "exhausted": false},
		],
		"white_hand": golem_page,
		"white_deck": grandpa_deck_without(golem_page),
		"black_hand": opponent_page,
		"black_deck": grandpa_deck_without(opponent_page),
		"turn_color": PLAYER_COLOR,
	}

## The Warlord on (2, 3) can jump to (4, 2), (4, 4), (3, 1) or (3, 5).
## The Archer on (5, 1) captures on (4, 2) and (3, 1), the Knight on (6, 5)
## and the Lance on (5, 4) both on (4, 4). Only (3, 5) is safe: the War
## Drummer beside it on (4, 6) can only move diagonally, never capture. The
## Gold General on (6, 1) adds to how crowded it all looks.
func danger_setup() -> Dictionary:
	return {
		"board": [
			[1, 1, 0, 0, 0, 1, 1],
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 1, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, -1],
			[0, -1, 0, 0, -1, 0, 0],
			[0, -1, 0, 0, 0, -1, 0],
		],
		"affixed_stamps": [
			{"pos": Vector2(2, 3), "stamp_name": "Warlord", "turns_remaining": 1, "exhausted": false},
			{"pos": Vector2(5, 1), "stamp_name": "Archer", "turns_remaining": 1, "exhausted": false},
			{"pos": Vector2(5, 4), "stamp_name": "Lance", "turns_remaining": 2, "exhausted": false},
			{"pos": Vector2(6, 5), "stamp_name": "Knight", "turns_remaining": 3, "exhausted": false},
			{"pos": Vector2(4, 6), "stamp_name": "War Drummer", "turns_remaining": 3, "exhausted": false},
			{"pos": Vector2(6, 1), "stamp_name": "Gold General", "turns_remaining": 1, "exhausted": false},
		],
		"turn_color": PLAYER_COLOR,
	}

## The Knight on (3, 3) has one jump left; its stamp runs out wherever it
## lands. From (5, 2) or (5, 4) a Prince steps diagonally into the court on
## (6, 3) - but Grandpa's Knight on (6, 6) covers (5, 4), so (5, 2) is the
## square. The Prince is on the open page. Grandpa's Lance on (6, 0) goes back
## and forth meanwhile; his bare golems on (6, 2) and (6, 4) only look the
## part.
func court_setup() -> Dictionary:
	var court_page: Array[String] = ["Archer", "Prince", "Gold General"]
	var opponent_page: Array[String] = ["Prince", "Knight", "Warlord"]
	return {
		"board": [
			[1, 0, 0, 0, 0, 0, 1],
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 1, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
			[-1, 0, -1, 0, -1, 0, -1],
		],
		"affixed_stamps": [
			{"pos": Vector2(3, 3), "stamp_name": "Knight", "turns_remaining": 1, "exhausted": false},
			{"pos": Vector2(6, 6), "stamp_name": "Knight", "turns_remaining": 4, "exhausted": false},
			{"pos": Vector2(6, 0), "stamp_name": "Lance", "turns_remaining": 6, "exhausted": false},
		],
		"white_hand": court_page,
		"white_deck": grandpa_deck_without(court_page),
		"black_hand": opponent_page,
		"black_deck": grandpa_deck_without(opponent_page),
		"turn_color": PLAYER_COLOR,
	}

func start_step(step_index: int) -> void:
	if step_index < 0 or step_index >= steps.size():
		finish_tutorial()
		return

	current_step_index = step_index
	step_token += 1
	affixed_this_step = 0
	moved_this_step = 0
	waiting_for_continue_after_completion = false
	pending_turn_outcome = ""
	opponent_turn_index = 0
	continue_held_for_opponent = false
	tracked_stamp_pos = INVALID_BOARD_POS
	tracked_stamp_moves = 0
	last_player_move_to = INVALID_BOARD_POS
	retry_after_opponent = false
	clear_step_glow()

	var step: Dictionary = steps[current_step_index]
	if step.has("setup") and board.has_method("apply_tutorial_setup"):
		board.apply_tutorial_setup(step.get("setup", {}))
	refresh_opponent_positions()

	var constraints: Dictionary = step.get("constraints", {}).duplicate(true)
	if board.has_method("set_tutorial_constraints"):
		board.set_tutorial_constraints(constraints)

	var reveal_names: Array[String] = []
	reveal_names.assign(step.get("reveal_hud", []))
	if !reveal_names.is_empty() and match_intro != null:
		match_intro.reveal_hud_nodes(reveal_names)
	if step.has("glow"):
		glow_behind(str(step.get("glow", "")))

	var has_opponent_turns: bool = !(step.get("opponent_turns", []) as Array).is_empty()
	continue_held_for_opponent = has_opponent_turns and is_current_completion("dialogue")
	if step.has("text") and !bool(step.get("text_on_opponent_move", false)):
		show_step_line(step, str(step.get("text", "")), should_show_continue_for_step(step))
	if has_opponent_turns and board.get_current_turn_color() == OPPONENT_COLOR:
		play_next_opponent_turn()

func show_step_line(step: Dictionary, text_key: String, allow_continue: bool) -> void:
	var speaker: String = str(step.get("speaker", GRANDPA_SPEAKER))
	dialogue_panel.visible = true
	dialogue_panel.show_line(get_speaker_name(speaker), tr(text_key), null, allow_continue and !continue_held_for_opponent)

## The step again from the top - its board, its line, its Grandpa turns -
## once the board has finished showing the move that missed.
func retry_current_step() -> void:
	step_token += 1
	var token: int = step_token
	if board.has_method("set_tutorial_constraints"):
		board.set_tutorial_constraints(no_actions())
	if board.has_method("wait_for_pending_visual_processes"):
		await board.wait_for_pending_visual_processes()
	if token != step_token:
		return
	start_step(current_step_index)

## The steps have run out: the board is the player's to play. Tutorial mode
## stays on, because it is a won game that completes the tutorial in the
## story (GameResultController hands that to StoryManager).
func finish_tutorial() -> void:
	if board != null and board.has_method("clear_tutorial_constraints"):
		board.clear_tutorial_constraints()
	current_step_index = -1
	clear_step_glow()
	# Nothing left to say; an empty box would only show its placeholder name.
	dialogue_panel.visible = false

func _on_dialogue_continue_requested() -> void:
	if waiting_for_continue_after_completion:
		waiting_for_continue_after_completion = false
		advance_current_step()
		return

	if !is_current_completion("dialogue"):
		return
	advance_current_step()

func _on_stamp_affixed(piece_pos: Vector2, stamp_name: String, owner_color: int, _hand_index: int) -> void:
	if owner_color != PLAYER_COLOR:
		return
	var step: Dictionary = get_current_step()
	if is_current_completion("stamp_moves") and stamp_name == str(step.get("track_stamp", "")):
		tracked_stamp_pos = piece_pos
		tracked_stamp_moves = 0
		return
	if !is_current_completion("stamp_affixed"):
		return
	var expected_stamp_name: String = str(step.get("expected_stamp_name", ""))
	if !expected_stamp_name.is_empty() and stamp_name != expected_stamp_name:
		return

	affixed_this_step += 1
	if affixed_this_step >= int(step.get("required_count", 1)):
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

## A move ends the turn, so what it means for the step is settled in
## _on_turn_ended(), once the board has gone over to Grandpa.
func _on_piece_moved(from_pos: Vector2, to_pos: Vector2, owner_color: int) -> void:
	if owner_color != PLAYER_COLOR or current_step_index < 0:
		return
	var step: Dictionary = get_current_step()
	last_player_move_to = to_pos

	if is_current_completion("stamp_moves"):
		if from_pos == tracked_stamp_pos:
			tracked_stamp_pos = to_pos
			tracked_stamp_moves += 1
		return

	if is_current_completion("piece_captured"):
		if opponent_positions.has(to_pos):
			pending_turn_outcome = "complete"
		elif bool(step.get("retry_on_miss", false)):
			pending_turn_outcome = "retry"
		return

	if !is_current_completion("piece_moved"):
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
	pending_turn_outcome = "complete"

func _on_turn_ended(ending_color: int, _next_color: int) -> void:
	if current_step_index < 0:
		return
	var step: Dictionary = get_current_step()

	if ending_color == OPPONENT_COLOR:
		refresh_opponent_positions()
		if retry_after_opponent:
			retry_after_opponent = false
			retry_current_step()
			return
		if continue_held_for_opponent:
			continue_held_for_opponent = false
			dialogue_panel.set_continue_allowed(true)

	if ending_color == PLAYER_COLOR:
		if bool(step.get("punish_unsafe_moves", false)) and punish_unsafe_move():
			return
		if pending_turn_outcome == "complete":
			complete_current_action_step()
			return
		if pending_turn_outcome == "retry":
			retry_current_step()
			return
		if step.has("check_turn") and !bool(call(str(step.get("check_turn", "")))):
			retry_current_step()
			return
		if is_current_completion("stamp_moves") and tracked_stamp_pos != INVALID_BOARD_POS:
			if tracked_stamp_moves >= int(step.get("required_count", 1)):
				complete_current_action_step()
				return
			if !is_tracked_stamp_on_board():
				retry_current_step()
				return

	if is_current_completion("turn_ended") and ending_color == int(step.get("turn_color", PLAYER_COLOR)):
		complete_current_action_step()
		return

	if ending_color == PLAYER_COLOR and !(step.get("opponent_turns", []) as Array).is_empty():
		play_next_opponent_turn()

## Grandpa takes the piece the player has just put where he can reach it, if
## he can; the step then starts over after his turn. False when the square
## was safe.
func punish_unsafe_move() -> bool:
	var target: Vector2 = last_player_move_to
	last_player_move_to = INVALID_BOARD_POS
	if target == INVALID_BOARD_POS:
		return false
	var capture: Dictionary = find_opponent_capture(target)
	if capture.is_empty():
		return false
	pending_turn_outcome = ""
	retry_after_opponent = true
	play_opponent_turn({"move": capture}, step_token)
	return true

func find_opponent_capture(target: Vector2) -> Dictionary:
	if !board.piece_objects.has(target):
		return {}
	var player_id: int = board.get_player_id_for_color(OPPONENT_COLOR)
	for position_value in board.piece_objects:
		var piece: Piece = board.piece_objects[position_value] as Piece
		if piece == null or piece.color != OPPONENT_COLOR:
			continue
		var targets: Array[Vector2] = MoveRules.get_piece_moves_for_player(board.piece_objects, position_value, player_id, BoardConfig.BOARD_SIZE, board.current_board_effects)
		if targets.has(target):
			return {"from": position_value, "to": target}
	return {}

## The last part's check: can a pentagon stamp still step into Grandpa's court
## in one move - one already on a golem, or one from the open page on a bare
## golem standing where it would need to be? Once neither is true the part
## cannot be finished any more.
func can_still_reach_court() -> bool:
	var court: Vector2 = board.get_local_state_mutator().get_base_field_for_player(board.get_player_id_for_color(OPPONENT_COLOR))
	var hand_seekers: Array[Stamp] = []
	for stamp: Stamp in board.get_stamp_hand(PLAYER_COLOR):
		if MoveRules.is_seeker_stamp(stamp):
			hand_seekers.append(stamp)
	for position_value in board.piece_objects:
		var piece: Piece = board.piece_objects[position_value] as Piece
		if piece == null or piece.color != PLAYER_COLOR:
			continue
		if MoveRules.is_seeker_stamp(piece.affixed_stamp):
			if stamp_reaches(position_value, piece.affixed_stamp, court):
				return true
		elif piece.affixed_stamp == null:
			for stamp in hand_seekers:
				if stamp_reaches(position_value, stamp, court):
					return true
	return false

func stamp_reaches(from_pos: Vector2, stamp: Stamp, target: Vector2) -> bool:
	return MoveRules.get_stamp_moves_for_piece(board.piece_objects, from_pos, PLAYER_COLOR, stamp, BoardConfig.BOARD_SIZE, board.current_board_effects).has(target)

func is_tracked_stamp_on_board() -> bool:
	var piece: Piece = board.piece_objects.get(tracked_stamp_pos, null) as Piece
	if piece == null or piece.color != PLAYER_COLOR or piece.affixed_stamp == null:
		return false
	return piece.affixed_stamp.stamp_name == str(get_current_step().get("track_stamp", ""))

func refresh_opponent_positions() -> void:
	opponent_positions.clear()
	for position_value in board.piece_objects:
		var piece: Piece = board.piece_objects[position_value] as Piece
		if piece != null and piece.color == OPPONENT_COLOR:
			opponent_positions[position_value] = true

func _on_tutorial_action_rejected(_action_name: String, _context: Dictionary) -> void:
	if current_step_index < 0 or current_step_index >= steps.size():
		return

	var step: Dictionary = steps[current_step_index]
	if !step.has("text") and !step.has("rejection_text"):
		return
	show_step_line(step, str(step.get("rejection_text", step.get("text", ""))), should_show_continue_for_step(step))

func advance_current_step() -> void:
	start_step(current_step_index + 1)

## The action is done: nothing more may be done for this step, and the next
## one waits until the board has finished showing what just happened - the
## stamp settling on its piece, the piece arriving on its square.
func complete_current_action_step() -> void:
	var step: Dictionary = get_current_step()
	step_token += 1
	var token: int = step_token
	if board != null and board.has_method("set_tutorial_constraints"):
		board.set_tutorial_constraints(no_actions())
	clear_step_glow()
	if board != null and board.has_method("wait_for_pending_visual_processes"):
		await board.wait_for_pending_visual_processes()
	if token != step_token:
		return

	if bool(step.get("continue_after_completion", false)):
		waiting_for_continue_after_completion = true
		show_step_line(step, str(step.get("post_completion_text", step.get("text", ""))), true)
		return

	advance_current_step()

# --- Grandpa's turns ------------------------------------------------------------

func play_next_opponent_turn() -> void:
	var turns: Array = get_current_step().get("opponent_turns", [])
	var script: Dictionary = turns[opponent_turn_index] if opponent_turn_index < turns.size() else {}
	opponent_turn_index += 1
	play_opponent_turn(script, step_token)

## One scripted turn of Grandpa's: his stamps go on one after another, the way
## any stamp does, then he moves - which ends the turn - or, with no move in
## the script, he hands the turn back.
func play_opponent_turn(script: Dictionary, token: int) -> void:
	await get_tree().create_timer(opponent_think_seconds).timeout
	for entry_value in script.get("affixes", []):
		if token != step_token:
			return
		var entry: Dictionary = entry_value
		var stamp_name: String = str(entry.get("stamp_name", ""))
		var hand_index: int = board.get_stamp_names_from_hand(board.get_stamp_hand(OPPONENT_COLOR)).find(stamp_name)
		var piece_pos: Vector2 = value_to_vector2(entry.get("pos", INVALID_BOARD_POS), INVALID_BOARD_POS)
		if hand_index < 0 or piece_pos == INVALID_BOARD_POS:
			push_warning("Tutorial opponent cannot play %s at %s." % [stamp_name, piece_pos])
			continue
		await board.affix_hand_stamp_locally(OPPONENT_COLOR, hand_index, piece_pos)
		await get_tree().create_timer(opponent_between_stamps_seconds).timeout
	if token != step_token:
		return

	var wants_move: bool = script.has("move") or !script.has("affixes")
	var move: Dictionary = choose_opponent_move(script.get("move", {})) if wants_move else {}
	if move.is_empty():
		await get_tree().create_timer(opponent_end_turn_delay).timeout
		if token == step_token:
			board.end_current_turn_locally()
		return

	var step: Dictionary = get_current_step()
	if bool(step.get("text_on_opponent_move", false)) and step.has("text"):
		show_step_line(step, str(step.get("text", "")), should_show_continue_for_step(step))
	board.set_move(move["from"], move["to"])

## The move the script asks for if Grandpa can make it, otherwise any move of
## his that captures nothing; empty when he has none.
func choose_opponent_move(wanted: Dictionary) -> Dictionary:
	var player_id: int = board.get_player_id_for_color(OPPONENT_COLOR)
	var from_pos: Vector2 = value_to_vector2(wanted.get("from", INVALID_BOARD_POS), INVALID_BOARD_POS)
	var to_pos: Vector2 = value_to_vector2(wanted.get("to", INVALID_BOARD_POS), INVALID_BOARD_POS)
	if from_pos != INVALID_BOARD_POS:
		var targets: Array[Vector2] = MoveRules.get_piece_moves_for_player(board.piece_objects, from_pos, player_id, BoardConfig.BOARD_SIZE, board.current_board_effects)
		if targets.has(to_pos):
			return {"from": from_pos, "to": to_pos}
	for position_value in board.piece_objects:
		var piece: Piece = board.piece_objects[position_value] as Piece
		if piece == null or piece.color != OPPONENT_COLOR:
			continue
		for target: Vector2 in MoveRules.get_piece_moves_for_player(board.piece_objects, position_value, player_id, BoardConfig.BOARD_SIZE, board.current_board_effects):
			if !board.piece_objects.has(target):
				return {"from": position_value, "to": target}
	return {}

# --- Odds and ends --------------------------------------------------------------

## A soft glow behind the named part of the interface, until the step ends.
func glow_behind(node_name: String) -> void:
	if match_intro == null:
		return
	var target := match_intro.get_hud_node(node_name) as Control
	if target == null:
		return
	# A tab only shows its top above the screen's edge; the glow goes there.
	var visible_height: float = target.raised_height if target is MatchTabButton else target.size.y
	var centre := Vector2(target.size.x * 0.5, visible_height * 0.5)
	step_glow = HintGlow.attach(target, centre, Vector2(target.size.x * 2.2, visible_height * 3.0))

func clear_step_glow() -> void:
	if step_glow != null and is_instance_valid(step_glow):
		step_glow.dismiss()
	step_glow = null

func get_speaker_name(speaker: String) -> String:
	if speaker == GRANDPA_SPEAKER:
		return GRANDPA_BOSS.get_localized_display_name()
	return tr(speaker)

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
