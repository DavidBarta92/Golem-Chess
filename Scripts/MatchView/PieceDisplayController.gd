extends RefCounted

const PIECE_SHIELD_SCRIPT = preload("res://Scripts/MatchView/PieceShield.gd")
const PIECE_SELECTION_LEAN_SCRIPT = preload("res://Scripts/MatchView/PieceSelectionLean.gd")
const SELECTION_RIM_SHADER: Shader = preload("res://Shaders/piece_selection_rim.gdshader")
const SELECTED_PIECE_GLOW_NAME: String = "SelectedPieceGlow"
const SELECTED_PIECE_GLOW_Z_INDEX: int = 24
## The selected piece's rim of light comes on over this long.
const SELECTION_RIM_APPEAR_SECONDS: float = 0.16
## On trial: the selected piece tips a little towards the cursor, onto the
## edge of its base (PieceSelectionLean).
const SELECTION_LEAN_ENABLED: bool = true
const PIECE_HOVER_DIM_COLOR: Color = Color(0.68, 0.68, 0.68, 1.0)
const PIECE_HOVER_DIM_TWEEN_DURATION: float = 0.18

var match_board
var piece_visuals
var texture_resolver
var texture_holder_scene: PackedScene
var board_size: int = BoardConfig.BOARD_SIZE
var piece_light_receive_mask: int = 2
var invalid_board_pos: Vector2 = Vector2(-1, -1)

const PIECE_HOVER_DIM_TWEEN_META: String = "hover_dim_tween"

## Shields (PieceShield): the squares that had one at the last redraw, with
## the side and stamp of the piece under it, so a new one grows in and one
## that lapsed pops; the squares whose new shield waits for the move or the
## stamp that brought it to finish playing (reveal_new_shields); and, during
## a redraw, what was there before it.
var _shield_squares: Dictionary = {}
var _shield_squares_before: Dictionary = {}
var _pending_shield_squares: Dictionary = {}
var _redrawing_shields: bool = false
## During a redraw: how much longer each square's bubble was still to show,
## so the new shield goes on showing it.
var _shield_show_left: Dictionary = {}
## The square whose selection the rim and the lean were last put on for, so
## a redraw keeps them rather than bringing them on again.
var _rim_selection: Vector2 = Vector2(-1, -1)

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	piece_visuals = config.get("piece_visuals", piece_visuals)
	texture_resolver = config.get("texture_resolver", texture_resolver)
	texture_holder_scene = config.get("texture_holder_scene", texture_holder_scene)
	board_size = int(config.get("board_size", board_size))
	piece_light_receive_mask = int(config.get("piece_light_receive_mask", piece_light_receive_mask))
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)

func display_board() -> void:
	if match_board == null:
		return
	DebugLog.info("display_board() called: white=%s side=%s" % [match_board.white, match_board.side])
	match_board.get_stamp_interaction_controller().clear_stamp_affix_target_feedback()
	match_board.get_server_state_visual_update_controller().clear_resolved_pending_stamp_affix_positions()
	match_board.get_board_marker_controller().update_markers()
	for child in match_board.pieces_node.get_children():
		child.queue_free()

	_begin_shield_redraw()
	for i in board_size:
		for j in board_size:
			var board_pos := Vector2(i, j)
			var holder = texture_holder_scene.instantiate()
			if match_board.side != null and !match_board.side:
				holder.global_rotation_degrees = 180
				match_board.get_node("../Camera2D").global_rotation_degrees = 180
			match_board.pieces_node.add_child(holder)
			holder.light_mask = piece_light_receive_mask
			holder.position = match_board.get_board_geometry().get_position_local(board_pos)
			holder.set_meta("board_pos", board_pos)
			holder.z_index = piece_visuals.get_depth_z_index(board_pos) if piece_visuals != null else 0
			holder.texture = texture_resolver.get_piece_texture_for_position(board_pos, int(match_board.board[i][j])) if texture_resolver != null else null
			apply_piece_visual_size(holder, board_pos)
			apply_piece_respawn_lock_opacity(holder, board_pos)
			match_board.get_crown_controller().apply_crown_mark(holder, board_pos)
			if match_board.get_piece_respawn_fragment_coordinator().should_hide_piece_for_shatter_respawn(board_pos):
				continue
			apply_piece_light_occluder(holder, board_pos)
			apply_piece_shadow(holder, board_pos)
			apply_piece_exhausted_material(holder, board_pos)
			apply_piece_freeze_overlay(holder, board_pos)
			apply_piece_shield(holder, board_pos)
			apply_selected_piece_glow(holder, board_pos)
			apply_piece_hover_dim(holder, board_pos)
	_end_shield_redraw()
	match_board.get_crown_controller().refresh()

func refresh_piece_holder_visual(holder: Sprite2D, board_pos: Vector2) -> void:
	if match_board == null or piece_visuals == null or holder == null or !is_instance_valid(holder):
		return

	piece_visuals.apply_holder_base_visual(holder, board_pos)
	apply_piece_respawn_lock_opacity(holder, board_pos)
	match_board.get_crown_controller().apply_crown_mark(holder, board_pos)
	if match_board.get_piece_respawn_fragment_coordinator().should_hide_piece_for_shatter_respawn(board_pos):
		apply_piece_exhausted_material(holder, board_pos)
		remove_piece_light_occluder(holder)
		remove_piece_shadow(holder)
		remove_piece_freeze_overlay(holder)
		remove_piece_freeze_square_overlay(board_pos)
		match_board.get_freeze_effect_animator().forget(board_pos)
		remove_selected_piece_glow(holder)
		var shield = PIECE_SHIELD_SCRIPT.get_on(holder)
		if shield != null:
			shield.free()
		return
	apply_piece_light_occluder(holder, board_pos)
	apply_piece_shadow(holder, board_pos)
	apply_piece_exhausted_material(holder, board_pos)
	apply_piece_freeze_overlay(holder, board_pos)
	apply_piece_shield(holder, board_pos)
	apply_selected_piece_glow(holder, board_pos)
	apply_piece_hover_dim(holder, board_pos)

func apply_piece_visual_size(holder: Sprite2D, board_pos: Vector2) -> void:
	if piece_visuals != null:
		piece_visuals.apply_visual_size(holder, board_pos)

func apply_piece_respawn_lock_opacity(holder: Sprite2D, board_pos: Vector2) -> void:
	if match_board == null:
		return
	var is_respawn_locked: bool = false
	if match_board.piece_objects.has(board_pos):
		var piece: Piece = match_board.piece_objects[board_pos] as Piece
		is_respawn_locked = piece != null and piece.is_respawn_locked()
	if piece_visuals != null:
		piece_visuals.apply_respawn_lock_opacity(holder, match_board.get_piece_respawn_fragment_coordinator().should_hide_piece_for_shatter_respawn(board_pos), is_respawn_locked)

func apply_piece_shadow(holder: Sprite2D, board_pos: Vector2) -> void:
	if piece_visuals == null:
		return
	piece_visuals.apply_shadow(holder, get_piece_color_at(board_pos), match_board.get_own_color())

func remove_piece_shadow(holder: Sprite2D) -> void:
	if piece_visuals != null:
		piece_visuals.remove_shadow(holder)

func apply_piece_light_occluder(holder: Sprite2D, board_pos: Vector2) -> void:
	if piece_visuals != null:
		piece_visuals.apply_light_occluder(holder, match_board.piece_objects.has(board_pos))

func remove_piece_light_occluder(holder: Sprite2D) -> void:
	if piece_visuals != null:
		piece_visuals.remove_light_occluder(holder)

func get_piece_color_at(board_pos: Vector2) -> int:
	if !match_board.piece_objects.has(board_pos):
		return 0
	var piece: Piece = match_board.piece_objects[board_pos] as Piece
	return piece.color if piece != null else 0

## The selected piece: a rim of light round its figure (piece_selection_rim
## .gdshader) rather than a wash over it, and, on trial, a lean towards the
## cursor. A redraw puts them on the new holder as they were; only a new
## selection brings the rim on.
func apply_selected_piece_glow(holder: Sprite2D, board_pos: Vector2) -> void:
	var selected: bool = match_board.state and board_pos == match_board.selected_piece and holder.texture != null and match_board.piece_objects.has(board_pos)
	if !selected:
		remove_selected_piece_glow(holder)
		return
	if holder.get_node_or_null(SELECTED_PIECE_GLOW_NAME) != null:
		return

	var rim := Sprite2D.new()
	rim.name = SELECTED_PIECE_GLOW_NAME
	rim.z_index = SELECTED_PIECE_GLOW_Z_INDEX
	rim.z_as_relative = true
	match_board.get_piece_effect_animator().sync_sprite_overlay_to_holder(rim, holder)
	var rim_material := ShaderMaterial.new()
	rim_material.shader = SELECTION_RIM_SHADER
	rim_material.set_shader_parameter(&"art_size", holder.texture.get_size() * holder.scale.abs())
	rim.material = rim_material
	holder.add_child(rim)

	var newly_selected: bool = _rim_selection != board_pos
	_rim_selection = board_pos
	if newly_selected:
		rim_material.set_shader_parameter(&"appear", 0.0)
		var appear: Tween = rim.create_tween()
		appear.tween_method(func(amount: float): rim_material.set_shader_parameter(&"appear", amount), 0.0, 1.0, SELECTION_RIM_APPEAR_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	if SELECTION_LEAN_ENABLED and holder.get_node_or_null(PIECE_SELECTION_LEAN_SCRIPT.NODE_NAME) == null:
		holder.add_child(PIECE_SELECTION_LEAN_SCRIPT.new(Callable(piece_visuals, "get_footprint_metrics")))

func remove_selected_piece_glow(holder: Sprite2D) -> void:
	var existing_glow: Node = holder.get_node_or_null(SELECTED_PIECE_GLOW_NAME)
	if existing_glow != null:
		existing_glow.free()
	var lean: Node = holder.get_node_or_null(PIECE_SELECTION_LEAN_SCRIPT.NODE_NAME)
	if lean != null:
		lean.release()

func update_selected_piece_glow() -> void:
	if match_board.pieces_node == null:
		return

	var selected_before: Vector2 = _rim_selection
	if !match_board.state:
		_rim_selection = invalid_board_pos
	for child in match_board.pieces_node.get_children():
		var holder: Sprite2D = child as Sprite2D
		if holder == null:
			continue

		var board_pos: Vector2 = BoardConfig.value_to_vector2(holder.get_meta("board_pos", invalid_board_pos), invalid_board_pos)
		apply_selected_piece_glow(holder, board_pos)
	if match_board.state and _rim_selection != selected_before:
		tremble_shields_in_reach(match_board.selected_piece)

## The ward over an uncapturable piece (PieceShield), while the rules say it
## is one. A new one waits to grow until the move or the stamp that brought it
## has played (reveal_new_shields); one that lapsed under its piece pops.
func apply_piece_shield(holder: Sprite2D, board_pos: Vector2) -> void:
	if holder == null or !is_instance_valid(holder):
		return
	var existing = PIECE_SHIELD_SCRIPT.get_on(holder)
	var before: Dictionary = _shield_squares_before if _redrawing_shields else _shield_squares
	var had: String = str(before.get(board_pos, ""))
	var piece: Piece = match_board.piece_objects.get(board_pos, null) as Piece
	var piece_shown: bool = piece != null and holder.texture != null and !piece.hidden_from_viewer
	if !piece_shown or !StampEffectResolver.piece_has_affixed_effect(piece, StampEffect.TYPE_UNCAPTURABLE):
		if existing != null:
			existing.free()
		_shield_squares.erase(board_pos)
		_pending_shield_squares.erase(board_pos)
		# Lapsed under its piece, which is still there: it pops.
		if piece_shown and had.begins_with("%d:" % piece.color) and _can_animate_shields():
			PIECE_SHIELD_SCRIPT.add_to(match_board, holder, board_pos, true).pop_and_free()
		return

	var signature: String = "%d:%s" % [piece.color, piece.affixed_stamp.stamp_name]
	_shield_squares[board_pos] = signature
	var shield = existing
	if shield == null:
		var waits: bool = _pending_shield_squares.has(board_pos) or (had != signature and _can_animate_shields())
		shield = PIECE_SHIELD_SCRIPT.add_to(match_board, holder, board_pos, !waits)
		if waits:
			_pending_shield_squares[board_pos] = true
		elif float(_shield_show_left.get(board_pos, 0.0)) > 0.0:
			shield.show_for(float(_shield_show_left[board_pos]), false)
	shield.set_last_turn(piece.protection_turns_remaining == 1)

## The move or the stamp that brought the new shields has played: they grow.
func reveal_new_shields() -> void:
	for board_pos: Vector2 in _pending_shield_squares.keys():
		var shield = PIECE_SHIELD_SCRIPT.get_on(match_board.get_piece_holder_at(board_pos))
		if shield != null:
			shield.grow()
	_pending_shield_squares.clear()

## The piece on `selected_pos` has just been picked up: the shields over the
## pieces it could take but for them tremble.
func tremble_shields_in_reach(selected_pos: Vector2) -> void:
	var mover: Piece = match_board.piece_objects.get(selected_pos, null) as Piece
	if mover == null or _shield_squares.is_empty():
		return
	# Each shielded piece stood in for by a bare one, which can be taken.
	var stand_ins: Dictionary = match_board.piece_objects.duplicate()
	var shielded: Array[Vector2] = []
	for board_pos: Vector2 in _shield_squares:
		var piece: Piece = stand_ins.get(board_pos, null) as Piece
		if piece == null or piece.color == mover.color:
			continue
		stand_ins[board_pos] = Piece.new(board_pos, piece.color)
		shielded.append(board_pos)
	if shielded.is_empty():
		return
	var reach: Array[Vector2] = MoveRules.get_piece_moves_for_player(stand_ins, selected_pos, BoardConfig.get_player_id_for_color(mover.color), board_size, match_board.current_board_effects)
	for board_pos: Vector2 in shielded:
		if reach.has(board_pos):
			var shield = PIECE_SHIELD_SCRIPT.get_on(match_board.get_piece_holder_at(board_pos))
			if shield != null:
				shield.tremble()

func _begin_shield_redraw() -> void:
	_shield_squares_before = _shield_squares
	_shield_squares = {}
	_redrawing_shields = true
	# The holders going out still carry their shields.
	_shield_show_left = {}
	for child in match_board.pieces_node.get_children():
		var old_shield = PIECE_SHIELD_SCRIPT.get_on(child as Sprite2D)
		if old_shield != null and old_shield.get_show_left() > 0.0:
			_shield_show_left[BoardConfig.value_to_vector2(child.get_meta("board_pos", invalid_board_pos), invalid_board_pos)] = old_shield.get_show_left()
	# A shielded piece that has moved takes its shield along.
	var last_move: Dictionary = match_board.current_last_move
	var from_pos: Vector2 = BoardConfig.value_to_vector2(last_move.get("from", invalid_board_pos), invalid_board_pos)
	var to_pos: Vector2 = BoardConfig.value_to_vector2(last_move.get("to", invalid_board_pos), invalid_board_pos)
	if _shield_squares_before.has(from_pos) and !_shield_squares_before.has(to_pos):
		_shield_squares_before[to_pos] = _shield_squares_before[from_pos]
		_shield_squares_before.erase(from_pos)
		if _pending_shield_squares.has(from_pos):
			_pending_shield_squares[to_pos] = true
			_pending_shield_squares.erase(from_pos)
		if _shield_show_left.has(from_pos):
			_shield_show_left[to_pos] = _shield_show_left[from_pos]
			_shield_show_left.erase(from_pos)

func _end_shield_redraw() -> void:
	_redrawing_shields = false
	_shield_squares_before = {}
	_shield_show_left = {}
	for board_pos: Vector2 in _pending_shield_squares.keys():
		if !_shield_squares.has(board_pos):
			_pending_shield_squares.erase(board_pos)

func _can_animate_shields() -> bool:
	return match_board.has_received_server_state and !match_board.should_skip_visual_animations() and match_board.is_inside_tree()

func apply_piece_hover_dim(holder: Sprite2D, board_pos: Vector2, animate: bool = false) -> void:
	if holder == null or !is_instance_valid(holder):
		return

	var highlighted_pos: Vector2 = match_board.hover_highlighted_piece
	var should_dim: bool = highlighted_pos != invalid_board_pos and board_pos != highlighted_pos
	var tint: Color = PIECE_HOVER_DIM_COLOR if should_dim else Color(1.0, 1.0, 1.0)
	var ice: Sprite2D = match_board.get_freeze_effect_animator().get_overlay(holder)
	var shield = PIECE_SHIELD_SCRIPT.get_on(holder)

	# get_meta() reads a null default as "no default" and reports the key as
	# missing, so ask first.
	var existing_tween: Tween = holder.get_meta(PIECE_HOVER_DIM_TWEEN_META) as Tween if holder.has_meta(PIECE_HOVER_DIM_TWEEN_META) else null
	if existing_tween != null and existing_tween.is_valid():
		existing_tween.kill()

	if !animate:
		var current: Color = holder.self_modulate
		holder.self_modulate = Color(tint.r, tint.g, tint.b, current.a)
		if ice != null:
			ice.self_modulate = holder.self_modulate
		if shield != null:
			shield.modulate = Color(tint.r, tint.g, tint.b, shield.modulate.a)
		return

	# Alpha (respawn-lock opacity, hidden-for-shatter, etc.) is driven
	# independently elsewhere -- tweening only the r/g/b subproperties keeps
	# this fade from fighting whatever last set the holder's alpha.
	var tween: Tween = holder.create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(holder, "self_modulate:r", tint.r, PIECE_HOVER_DIM_TWEEN_DURATION)
	tween.tween_property(holder, "self_modulate:g", tint.g, PIECE_HOVER_DIM_TWEEN_DURATION)
	tween.tween_property(holder, "self_modulate:b", tint.b, PIECE_HOVER_DIM_TWEEN_DURATION)
	if ice != null:
		tween.tween_property(ice, "self_modulate:r", tint.r, PIECE_HOVER_DIM_TWEEN_DURATION)
		tween.tween_property(ice, "self_modulate:g", tint.g, PIECE_HOVER_DIM_TWEEN_DURATION)
		tween.tween_property(ice, "self_modulate:b", tint.b, PIECE_HOVER_DIM_TWEEN_DURATION)
	if shield != null:
		tween.tween_property(shield, "modulate:r", tint.r, PIECE_HOVER_DIM_TWEEN_DURATION)
		tween.tween_property(shield, "modulate:g", tint.g, PIECE_HOVER_DIM_TWEEN_DURATION)
		tween.tween_property(shield, "modulate:b", tint.b, PIECE_HOVER_DIM_TWEEN_DURATION)
	holder.set_meta(PIECE_HOVER_DIM_TWEEN_META, tween)

func update_piece_hover_dim() -> void:
	if match_board.pieces_node == null:
		return

	for child in match_board.pieces_node.get_children():
		var holder: Sprite2D = child as Sprite2D
		if holder == null:
			continue

		var board_pos: Vector2 = BoardConfig.value_to_vector2(holder.get_meta("board_pos", invalid_board_pos), invalid_board_pos)
		apply_piece_hover_dim(holder, board_pos, true)

func apply_piece_exhausted_material(holder: Sprite2D, board_pos: Vector2) -> void:
	if holder.texture == null or !match_board.piece_objects.has(board_pos):
		holder.material = null
		return
	holder.material = match_board.get_board_environment_controller().get_piece_kuwahara_material()

func apply_piece_freeze_overlay(holder: Sprite2D, board_pos: Vector2) -> void:
	match_board.get_freeze_effect_animator().apply_overlay(holder, board_pos)

func refresh_piece_freeze_overlay(board_pos: Vector2) -> void:
	match_board.get_freeze_effect_animator().refresh(board_pos)

func remove_piece_freeze_overlay(holder: Sprite2D) -> void:
	match_board.get_freeze_effect_animator().remove_overlay(holder)

func remove_piece_freeze_square_overlay(board_pos: Vector2) -> void:
	match_board.get_freeze_effect_animator().remove_square_overlay(board_pos)
