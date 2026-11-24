extends Node

## Thirty seconds into the player's own turn with nothing done, everything
## they can still do lights up with the soft yellow glow new main menu buttons
## and the tutorial use (HintGlow): the Turn Page and End Turn tabs while they
## are up, the stamps on the open codex page that can go onto a golem, and
## every piece that can move - a Shared one of the other colour too, the one
## most easily missed. A click or a key takes it all away and the wait starts
## again. A child of the board, made in MatchBoardLifecycleController.ready().
##
## It waits only when the turn would be announced (TurnFlowController.should_announce_turn):
## not in the tutorial or a puzzle, where the scene does the pointing, nor in
## an AI batch or before the interface has come in; and not while the board
## is still showing how the turn came about.

const PIECE_HINT_GLOW_SCRIPT = preload("res://Scripts/MatchView/PieceHintGlow.gd")
const NODE_NAME: String = "TurnReminder"
const IDLE_SECONDS: float = 30.0
## While lit, what can be done is looked at again this often: a codex coming
## up late, or a board drawn anew, gets its glows without a click.
const RECHECK_SECONDS: float = 0.5
## How far a glow spreads, as a multiple of what it is behind: the part of a
## tab that shows (the tutorial's tab glow), a stamp. A piece's is
## PieceHintGlow.SPREAD.
const TAB_GLOW_SPREAD: Vector2 = Vector2(2.2, 3.0)
const STAMP_GLOW_SPREAD: Vector2 = Vector2(1.7, 1.7)

enum Kind { TAB, STAMP, PIECE }

var _match_board
var _idle: float = 0.0
var _lit: bool = false
var _recheck: float = 0.0
## What is lit, and its glow.
var _glows: Dictionary = {}

func _init(match_board = null) -> void:
	name = NODE_NAME
	_match_board = match_board

func _process(delta: float) -> void:
	if !_is_waiting():
		_idle = 0.0
		dismiss()
		return
	if _lit:
		_recheck -= delta
		if _recheck <= 0.0:
			_sync()
		return
	_idle += delta
	if _idle >= IDLE_SECONDS:
		_lit = true
		_sync()

## Seen before the interface handles it, so a click on a tab or a stamp
## counts as doing something as much as one on the board.
func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventKey or event is InputEventScreenTouch) and event.is_pressed():
		_idle = 0.0
		dismiss()

func is_lit() -> bool:
	return _lit

func dismiss() -> void:
	_lit = false
	for target in _glows.keys():
		_dismiss_glow(_glows[target])
	_glows.clear()

## Glows for what can be done now, and none for what no longer can.
func _sync() -> void:
	_recheck = RECHECK_SECONDS
	var wanted: Dictionary = _get_targets()
	for target in _glows.keys():
		var glow = _glows[target]
		if !is_instance_valid(target) or !wanted.has(target) or glow == null or !is_instance_valid(glow) or glow.is_queued_for_deletion():
			_dismiss_glow(glow)
			_glows.erase(target)
	for target in wanted.keys():
		if !_glows.has(target):
			var glow = _attach(target, wanted[target])
			if glow != null:
				_glows[target] = glow

## Everything the player can do now, each with its kind.
func _get_targets() -> Dictionary:
	var targets: Dictionary = {}
	for tab_value in [_match_board.get_turn_hud_controller().end_turn_button, _match_board.get_match_codex_controller().turn_page_button]:
		var tab := tab_value as MatchTabButton
		if tab != null and is_instance_valid(tab) and tab.is_visible_in_tree() and !tab.disabled:
			targets[tab] = Kind.TAB

	var turn_flow = _match_board.get_turn_flow_controller()
	var owner_color: int = _match_board.get_controllable_color()
	for stamp_visual: StampVisual in _match_board.get_stamp_hand_state_controller().get_stamp_visuals(owner_color):
		if stamp_visual == null or !is_instance_valid(stamp_visual) or !stamp_visual.is_visible_in_tree() or !stamp_visual.draggable:
			continue
		if turn_flow.can_affix_stamp_now(stamp_visual.stamp):
			targets[stamp_visual] = Kind.STAMP

	for board_pos: Vector2 in turn_flow.get_movable_piece_positions():
		var holder: Sprite2D = _match_board.get_piece_holder_at(board_pos)
		if holder != null and holder.texture != null:
			targets[holder] = Kind.PIECE
	return targets

func _attach(target, kind: int):
	match kind:
		Kind.TAB:
			# A tab only shows its top above the screen's edge; the glow goes there.
			var shown := Vector2(target.size.x, target.raised_height)
			return HintGlow.attach(target, shown * 0.5, shown * TAB_GLOW_SPREAD)
		Kind.STAMP:
			return HintGlow.attach(target, target.size * 0.5, target.size * STAMP_GLOW_SPREAD)
		Kind.PIECE:
			return PIECE_HINT_GLOW_SCRIPT.attach(target, _match_board.get_piece_visuals().get_footprint_metrics(target.texture))
	return null

func _dismiss_glow(glow) -> void:
	if glow != null and is_instance_valid(glow) and !glow.is_queued_for_deletion():
		glow.dismiss()

func _is_waiting() -> bool:
	if _match_board == null or !is_instance_valid(_match_board) or !_match_board.is_inside_tree():
		return false
	if !_match_board.can_control_current_turn():
		return false
	var turn_flow = _match_board.get_turn_flow_controller()
	return turn_flow.should_announce_turn() and !turn_flow.has_pending_visual_processes()
