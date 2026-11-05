extends RefCounted

## The crown in a match: both players' crown points on the board's rim
## (CrownRim), the crown the player drags from there onto one of their golems
## (CrownMeter), and the crown on a crowned golem (CrownMark). The rule itself
## lives with the match state (GameStateData.place_crown); this only shows it
## and sends the player's move. The numbers follow each state as it arrives, but
## the rim shows them once that state's pieces are in place and its move has been
## played (show_state_points), so that a point won by a move comes off the golem
## after it has landed.
## The tutorial plays without a host, so there it keeps the points itself: it
## sets them (set_local_points), and each turn and crowning after that goes the
## way the host would have it (begin_local_turn, place_crown_locally).

signal crown_placed(piece_pos: Vector2, owner_color: int)

const CrownMeter = preload("res://Scripts/MatchView/CrownMeter.gd")
const CrownRim = preload("res://Scripts/MatchView/CrownRim.gd")
const CrownMark = preload("res://Scripts/MatchView/CrownMark.gd")

const CROWN_MARK_NAME: String = "CrownMark"
const INVALID_BOARD_POS: Vector2 = Vector2(-1, -1)

var match_board

## By colour (1 white, -1 black), as the rest of the match view keys things.
var crown_points: Dictionary = {1: 0, -1: 0}
var crown_points_required: int = 5
var crowned_this_turn: Dictionary = {1: false, -1: false}

var own_meter: Control
var opponent_meter: Control
## By colour: the rims stay where they are on the board whoever is playing.
var rims: Dictionary = {}
var _has_state: bool = false
## Crowned in a state that the rim has not shown yet, by colour.
var _crowning_due: Dictionary = {1: false, -1: false}

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)

func create_ui() -> void:
	if match_board.canvas_layer == null or own_meter != null:
		return
	var row_centre_canvas_x: float = match_board.get_turn_hud_controller().END_TURN_TAB_CANVAS_X
	for owner_color in [1, -1]:
		var rim: Node2D = CrownRim.new()
		rim.name = "CrownRimWhite" if owner_color == 1 else "CrownRimBlack"
		match_board.add_child(rim)
		rim.setup(match_board, owner_color, row_centre_canvas_x)
		rim.rebuilt.connect(_place_meters_after_camera)
		rims[owner_color] = rim
	own_meter = CrownMeter.new()
	own_meter.name = "OwnCrownMeter"
	opponent_meter = CrownMeter.new()
	opponent_meter.name = "OpponentCrownMeter"
	for meter in [own_meter, opponent_meter]:
		meter.visible = false
		match_board.canvas_layer.add_child(meter)
	opponent_meter.mouse_filter = Control.MOUSE_FILTER_PASS
	own_meter.crown_drag_moved.connect(_on_crown_drag_moved)
	own_meter.crown_drag_released.connect(_on_crown_drag_released)
	own_meter.get_viewport().size_changed.connect(_place_meters_after_camera)
	place_meters()

## The camera takes up a new window's scale or a turned view on its next frame,
## and the meters are placed through it.
func _place_meters_after_camera() -> void:
	if !match_board.is_inside_tree():
		return
	await match_board.get_tree().process_frame
	place_meters()

## The interface's part of the meters stands over the rims, wherever those are
## on this window, for this viewer.
func place_meters() -> void:
	if own_meter == null or !is_instance_valid(own_meter):
		return
	var own_color: int = match_board.get_own_color()
	own_meter.set_rim(rims[own_color])
	opponent_meter.set_rim(rims[-own_color])
	own_meter.fit_to_rim()
	opponent_meter.fit_to_rim()

## The points as the host reports them (by player id) - both players' are open.
func apply_state_from_server(points_by_player: Dictionary, points_required: int, crowned_by_player: Dictionary) -> void:
	crown_points_required = maxi(1, points_required)
	for player_id in [0, 1]:
		var owner_color: int = match_board.get_color_for_player_id(player_id)
		crown_points[owner_color] = int(points_by_player.get(player_id, points_by_player.get(str(player_id), 0)))
		var was_crowned: bool = bool(crowned_this_turn.get(owner_color, false))
		crowned_this_turn[owner_color] = bool(crowned_by_player.get(player_id, crowned_by_player.get(str(player_id), false)))
		if _has_state and !was_crowned and crowned_this_turn[owner_color]:
			_crowning_due[owner_color] = true
	_has_state = true
	refresh()

## The rims catch up with the last state. `animate` is false for what should
## simply be there: the first state, and matches nobody is watching.
func show_state_points(recent_effect_activations: Array, animate: bool) -> void:
	if rims.is_empty():
		return
	for owner_color in rims:
		var points: int = int(crown_points.get(owner_color, 0))
		var crowning: bool = bool(_crowning_due[owner_color])
		_crowning_due[owner_color] = false
		if !animate:
			rims[owner_color].set_points_at_once(points, crown_points_required)
			continue
		if crowning:
			rims[owner_color].take_crown()
			_play_crowning(owner_color)
		rims[owner_color].show_points(
			points,
			_get_point_sources(recent_effect_activations, owner_color),
			_count_points_taken(recent_effect_activations, owner_color)
		)

## Where the points this player has just won by an effect come from, in the
## rim's own space. A golem hidden from this viewer is not on the board here, so
## its point comes up in its pit and does not give it away.
func _get_point_sources(recent_effect_activations: Array, owner_color: int) -> Array[Vector2]:
	var sources: Array[Vector2] = []
	for activation_value in recent_effect_activations:
		var activation: Dictionary = activation_value
		if match_board.get_color_for_player_id(int(activation.get("player_id", -1))) != owner_color:
			continue
		var stamp: Stamp = StampLibrary.get_stamp(str(activation.get("stamp_name", "")))
		if stamp == null or stamp.effect_type != StampEffect.TYPE_GAIN_CROWN_POINT:
			continue
		var holder: Sprite2D = match_board.get_piece_holder_at(match_board.value_to_vector2(activation.get("source_pos", INVALID_BOARD_POS), INVALID_BOARD_POS))
		if holder != null and holder.texture != null:
			sources.append(rims[owner_color].to_local(CrownMark.get_point_over_head(holder)))
	return sources

## How many of this player's points effects have just taken. The turn's point
## usually arrives in the same state, as the move that took one ends the turn.
func _count_points_taken(recent_effect_activations: Array, owner_color: int) -> int:
	var taken: int = 0
	for activation_value in recent_effect_activations:
		var activation: Dictionary = activation_value
		var stamp: Stamp = StampLibrary.get_stamp(str(activation.get("stamp_name", "")))
		if stamp != null and stamp.effect_type == StampEffect.TYPE_REMOVE_ENEMY_CROWN_POINT and match_board.get_color_for_player_id(int(activation.get("player_id", -1))) == -owner_color:
			taken += 1
	return taken

## A crown on a golem hidden from this viewer is not on the board here, so
## nothing plays and the light does not give it away.
func _play_crowning(owner_color: int) -> void:
	for board_pos in match_board.piece_objects:
		var piece: Piece = match_board.piece_objects[board_pos] as Piece
		if piece != null and piece.color == owner_color and piece.has_crown:
			CrownMark.play_crowning(match_board, board_pos)
			return

## The points by colour, for a match with no host to report them. Also what
## brings the meters up: until a host or this says something, there are none.
func set_local_points(points_by_color: Dictionary, points_required: int) -> void:
	crown_points_required = maxi(1, points_required)
	for owner_color in [1, -1]:
		crown_points[owner_color] = int(points_by_color.get(owner_color, 0))
		crowned_this_turn[owner_color] = false
		rims[owner_color].set_points_at_once(crown_points[owner_color], crown_points_required)
	_has_state = true
	refresh()

## The point at the start of a turn, for a match with no host. A match that
## shows no meters keeps no points.
func begin_local_turn(owner_color: int) -> void:
	if !_has_state or GameController.current_game_host != null:
		return
	crowned_this_turn[owner_color] = false
	crown_points[owner_color] = mini(crown_points_required, int(crown_points.get(owner_color, 0)) + 1)
	rims[owner_color].show_points(crown_points[owner_color])
	refresh()

## GameStateData.place_crown, for a match with no host.
func place_crown_locally(owner_color: int, piece_pos: Vector2) -> void:
	for position_value in match_board.piece_objects:
		var worn_by: Piece = match_board.piece_objects[position_value] as Piece
		if worn_by != null and worn_by.color == owner_color:
			worn_by.has_crown = false
	var piece: Piece = match_board.piece_objects[piece_pos] as Piece
	piece.has_crown = true
	piece.exhausted_this_turn = true
	crown_points[owner_color] = 0
	crowned_this_turn[owner_color] = true
	match_board.display_board()
	rims[owner_color].take_crown()
	_play_crowning(owner_color)
	crown_placed.emit(piece_pos, owner_color)

func has_crowned_this_turn(owner_color: int) -> bool:
	return bool(crowned_this_turn.get(owner_color, false))

func refresh() -> void:
	if own_meter == null or !is_instance_valid(own_meter):
		return
	own_meter.visible = _has_state
	opponent_meter.visible = _has_state
	if _has_state:
		for owner_color in rims:
			rims[owner_color].show_rim()
	place_meters()
	var own_color: int = match_board.get_own_color()
	own_meter.set_points(int(crown_points.get(own_color, 0)), crown_points_required)
	opponent_meter.set_points(int(crown_points.get(-own_color, 0)), crown_points_required)
	own_meter.set_draggable(can_place_crown_locally(own_color, false))

## Mirrors GameStateData.can_place_crown on the view's side; the host has the
## last word. Whether an animation is still playing changes too often to keep
## the meter's look in step with, so only the drop itself waits for it.
func can_place_crown_locally(owner_color: int, require_action_ready: bool = true) -> bool:
	if !_has_state or !match_board.is_tutorial_action_allowed(match_board.TUTORIAL_ACTION_PLACE_CROWN):
		return false
	if owner_color != match_board.get_controllable_color() or !match_board.can_control_current_turn():
		return false
	if require_action_ready and match_board.has_pending_visual_processes():
		return false
	if bool(match_board.moved_piece_this_turn.get(owner_color, false)):
		return false
	return int(crown_points.get(owner_color, 0)) >= crown_points_required

func can_crown_piece_locally(owner_color: int, board_pos: Vector2) -> bool:
	var piece: Piece = match_board.piece_objects.get(board_pos, null) as Piece
	if piece == null or piece.color != owner_color or piece.is_respawn_locked() or piece.has_crown:
		return false
	return match_board.is_tutorial_action_allowed(match_board.TUTORIAL_ACTION_PLACE_CROWN, {"piece_pos": board_pos})

func get_drop_target(owner_color: int) -> Vector2:
	if match_board.is_mouse_out():
		return INVALID_BOARD_POS
	var board_pos: Vector2 = match_board.get_mouse_board_position()
	if board_pos == INVALID_BOARD_POS or !can_crown_piece_locally(owner_color, board_pos):
		return INVALID_BOARD_POS
	return board_pos

func _on_crown_drag_moved() -> void:
	match_board.get_stamp_interaction_controller().update_stamp_affix_target_feedback(get_drop_target(match_board.get_own_color()))

func _on_crown_drag_released() -> void:
	var owner_color: int = match_board.get_own_color()
	var target: Vector2 = get_drop_target(owner_color)
	match_board.get_stamp_interaction_controller().clear_stamp_affix_target_feedback()
	if target == INVALID_BOARD_POS or !can_place_crown_locally(owner_color):
		own_meter.return_crown()
		return
	SFXManager.play("stamp_glue")
	if GameController.current_game_host == null:
		place_crown_locally(owner_color, target)
		return
	if !GameController.send_action({
		"type": "place_crown",
		"player_id": match_board.get_player_id_for_color(owner_color),
		"piece_pos": target,
	}):
		own_meter.return_crown()

## Puts the crown on a crowned golem's head, or takes it off one that lost it.
## Called whenever a holder is drawn or redrawn.
func apply_crown_mark(holder: Sprite2D, board_pos: Vector2) -> void:
	if holder == null or !is_instance_valid(holder):
		return
	var existing: Node = holder.get_node_or_null(CROWN_MARK_NAME)
	var piece: Piece = match_board.piece_objects.get(board_pos, null) as Piece
	var crowned: bool = piece != null and piece.has_crown and holder.texture != null
	if !crowned:
		if existing != null:
			existing.queue_free()
		return
	var mark = existing if existing != null else CrownMark.new()
	if existing == null:
		mark.name = CROWN_MARK_NAME
		holder.add_child(mark)
	mark.fit_to_holder(holder)
