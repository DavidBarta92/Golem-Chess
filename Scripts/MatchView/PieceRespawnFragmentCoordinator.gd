extends RefCounted

var match_board
var invalid_board_pos: Vector2 = Vector2(-1, -1)
## The fragments of half golems struck in this update, by their square: off
## that square, so the piece that took it stands there in sight, and still
## lying about until the blow breaks them (`shatter_piece`).
var _struck_half_markers: Dictionary = {}

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)

func prepare_piece_shatter_respawn_reveals(animations: Array[Dictionary]) -> void:
	for animation: Dictionary in animations:
		var respawn_pos: Vector2 = BoardConfig.value_to_vector2(animation.get("respawn_pos", invalid_board_pos), invalid_board_pos)
		var fragment_group: String = str(animation.get("fragment_group", match_board.PIECE_SHATTER_FRAGMENT_GROUP_NONE))
		begin_piece_shatter_respawn_reveal(respawn_pos, fragment_group)

func prepare_pending_edge_respawn_arrival_reveals(animations: Array) -> void:
	for animation_value in animations:
		if !(animation_value is Dictionary):
			continue
		var animation: Dictionary = animation_value
		var respawn_pos: Vector2 = BoardConfig.value_to_vector2(animation.get("respawn_pos", invalid_board_pos), invalid_board_pos)
		var fragment_group: String = str(animation.get("fragment_group", match_board.PIECE_SHATTER_FRAGMENT_GROUP_BOTTOM))
		begin_piece_shatter_respawn_reveal(respawn_pos, fragment_group)

func is_piece_shatter_respawn_reveal_pending(board_pos: Vector2) -> bool:
	return match_board.pending_piece_shatter_respawn_reveal_counts.has(board_pos)

func has_piece_shatter_respawn_fragment_markers(board_pos: Vector2) -> bool:
	return match_board.respawn_piece_shatter_fragment_markers.has(board_pos)

func should_hide_piece_for_shatter_respawn(board_pos: Vector2) -> bool:
	return is_piece_shatter_respawn_reveal_pending(board_pos) or has_piece_shatter_respawn_fragment_markers(board_pos)

func add_piece_shatter_respawn_fragment_marker(respawn_pos: Vector2, fragment: Polygon2D) -> void:
	if !MoveRules.is_valid_position(respawn_pos) or fragment == null or !is_instance_valid(fragment):
		return

	var markers: Array = []
	if match_board.respawn_piece_shatter_fragment_markers.has(respawn_pos):
		markers = match_board.respawn_piece_shatter_fragment_markers[respawn_pos]
	markers.append(fragment)
	match_board.respawn_piece_shatter_fragment_markers[respawn_pos] = markers

func clear_piece_shatter_respawn_fragment_markers(respawn_pos: Vector2) -> void:
	if !match_board.respawn_piece_shatter_fragment_markers.has(respawn_pos):
		return

	free_markers(match_board.respawn_piece_shatter_fragment_markers[respawn_pos])
	match_board.respawn_piece_shatter_fragment_markers.erase(respawn_pos)

func free_markers(markers: Array) -> void:
	for marker in markers:
		var marker_node: Node = marker as Node
		if marker_node != null and is_instance_valid(marker_node):
			marker_node.queue_free()

## A half golem waiting for its top that is taken or blown up breaks again,
## so its fragments must not stay on its square: they hid the piece that took
## it, and showed a second half golem on that side. Those struck now are kept
## in sight for the blow to break (`shatter_piece`); any left on a square with
## no golem of their colour on it any more go at once (a sync that plays no
## animation). Called with the update's shatters before the board is drawn.
func hand_over_struck_halves(animations: Array[Dictionary]) -> void:
	for board_pos in _struck_half_markers.keys():
		break_struck_half(board_pos)
	for animation: Dictionary in animations:
		var source_pos: Vector2 = BoardConfig.value_to_vector2(animation.get("source_pos", invalid_board_pos), invalid_board_pos)
		var respawn_pos: Vector2 = BoardConfig.value_to_vector2(animation.get("respawn_pos", invalid_board_pos), invalid_board_pos)
		# Blown up and back on its own square: the same golem lies there still.
		if source_pos == respawn_pos or !has_piece_shatter_respawn_fragment_markers(source_pos):
			continue
		_struck_half_markers[source_pos] = match_board.respawn_piece_shatter_fragment_markers[source_pos]
		match_board.respawn_piece_shatter_fragment_markers.erase(source_pos)
	for board_pos in match_board.respawn_piece_shatter_fragment_markers.keys():
		if !markers_belong_to_piece_on(board_pos):
			clear_piece_shatter_respawn_fragment_markers(board_pos)

## The fragments struck on `board_pos` this update go as the blow lands.
func break_struck_half(board_pos: Vector2) -> void:
	if !_struck_half_markers.has(board_pos):
		return
	free_markers(_struck_half_markers[board_pos])
	_struck_half_markers.erase(board_pos)

## Whether the golem standing on `board_pos` is the one these fragments make
## up: one of their colour (they are cut from its golem drawing). A half golem
## coming together, or one whose top is on its way, is such a golem.
func markers_belong_to_piece_on(board_pos: Vector2) -> bool:
	var piece: Piece = match_board.piece_objects.get(board_pos, null) as Piece
	if piece == null:
		return false
	var golem_texture: Texture2D = match_board.get_piece_texture_resolver().get_default_piece_texture(piece.color)
	for marker in match_board.respawn_piece_shatter_fragment_markers.get(board_pos, []):
		var fragment: Polygon2D = marker as Polygon2D
		if fragment != null and is_instance_valid(fragment) and fragment.texture == golem_texture:
			return true
	return false

## Every fragment lying around for a piece still to come back, removed at
## once - for a board that is being replaced wholesale, as the tutorial's
## setups do; the pieces those fragments were waiting for are gone with it.
func clear_all_fragment_markers() -> void:
	for respawn_pos in match_board.respawn_piece_shatter_fragment_markers.keys():
		clear_piece_shatter_respawn_fragment_markers(respawn_pos)
	for board_pos in _struck_half_markers.keys():
		break_struck_half(board_pos)
	for key in match_board.pending_edge_respawn_fragment_markers:
		for marker in match_board.pending_edge_respawn_fragment_markers[key]:
			var marker_node: Node = marker as Node
			if marker_node != null and is_instance_valid(marker_node):
				marker_node.queue_free()
	match_board.pending_edge_respawn_fragment_markers.clear()
	match_board.pending_piece_shatter_respawn_reveal_counts.clear()
	match_board.pending_piece_shatter_respawn_reveal_groups.clear()
	match_board.get_piece_shatter_animator().clear_debris()

func get_piece_shatter_return_fragment_count(fragment_group: String) -> int:
	return mini(get_piece_shatter_fragment_cut_indices(fragment_group).size(), maxi(0, match_board.piece_shatter_returning_debris_count))

func begin_piece_shatter_respawn_reveal(respawn_pos: Vector2, fragment_group: String) -> int:
	if !MoveRules.is_valid_position(respawn_pos):
		return 0

	var return_count: int = get_piece_shatter_return_fragment_count(fragment_group)
	if return_count <= 0:
		return 0

	if !match_board.pending_piece_shatter_respawn_reveal_counts.has(respawn_pos):
		match_board.get_visual_process_tracker().begin(match_board.VISUAL_PROCESS_PIECE_SHATTER)
	match_board.pending_piece_shatter_respawn_reveal_counts[respawn_pos] = maxi(return_count, int(match_board.pending_piece_shatter_respawn_reveal_counts.get(respawn_pos, 0)))
	match_board.pending_piece_shatter_respawn_reveal_groups[respawn_pos] = fragment_group

	var holder: Sprite2D = match_board.get_piece_holder_at(respawn_pos)
	if holder != null:
		match_board.get_piece_display_controller().refresh_piece_holder_visual(holder, respawn_pos)
	return return_count

func adjust_piece_shatter_respawn_reveal_count(respawn_pos: Vector2, fragment_count: int) -> void:
	if !match_board.pending_piece_shatter_respawn_reveal_counts.has(respawn_pos):
		return
	if fragment_count <= 0:
		cancel_piece_shatter_respawn_reveal(respawn_pos)
		return
	match_board.pending_piece_shatter_respawn_reveal_counts[respawn_pos] = fragment_count

func cancel_piece_shatter_respawn_reveal(respawn_pos: Vector2) -> void:
	if match_board.pending_piece_shatter_respawn_reveal_counts.has(respawn_pos):
		match_board.pending_piece_shatter_respawn_reveal_counts.erase(respawn_pos)
		match_board.pending_piece_shatter_respawn_reveal_groups.erase(respawn_pos)
		match_board.get_visual_process_tracker().finish(match_board.VISUAL_PROCESS_PIECE_SHATTER)
	refresh_piece_shatter_respawn_piece_visibility(respawn_pos)

func finish_piece_shatter_respawn_fragment(respawn_pos: Vector2) -> void:
	if !match_board.pending_piece_shatter_respawn_reveal_counts.has(respawn_pos):
		return

	var fragment_group: String = str(match_board.pending_piece_shatter_respawn_reveal_groups.get(respawn_pos, match_board.PIECE_SHATTER_FRAGMENT_GROUP_NONE))
	var remaining_count: int = maxi(0, int(match_board.pending_piece_shatter_respawn_reveal_counts.get(respawn_pos, 0)) - 1)
	if remaining_count > 0:
		match_board.pending_piece_shatter_respawn_reveal_counts[respawn_pos] = remaining_count
		return

	match_board.pending_piece_shatter_respawn_reveal_counts.erase(respawn_pos)
	match_board.pending_piece_shatter_respawn_reveal_groups.erase(respawn_pos)
	match_board.get_visual_process_tracker().finish(match_board.VISUAL_PROCESS_PIECE_SHATTER)
	if fragment_group == match_board.PIECE_SHATTER_FRAGMENT_GROUP_BOTTOM:
		refresh_piece_shatter_respawn_piece_visibility(respawn_pos)
		add_broken_top(respawn_pos)
		return

	if fragment_group == match_board.PIECE_SHATTER_FRAGMENT_GROUP_TOP:
		clear_piece_shatter_respawn_fragment_markers(respawn_pos)
	reveal_piece_shatter_respawn_piece(respawn_pos)
	wake_respawned_piece(respawn_pos)

## The bottom half waiting on `respawn_pos` is all there: it gets its broken
## top, kept with its fragments so that it goes when they do.
func add_broken_top(respawn_pos: Vector2) -> void:
	var texture_value: Texture2D = null
	for marker in match_board.respawn_piece_shatter_fragment_markers.get(respawn_pos, []):
		var fragment: Polygon2D = marker as Polygon2D
		if fragment != null and is_instance_valid(fragment) and fragment.texture != null:
			texture_value = fragment.texture
			break
	if texture_value == null:
		return
	var top: Polygon2D = match_board.get_piece_shatter_animator().create_broken_top(respawn_pos, texture_value)
	if top != null:
		add_piece_shatter_respawn_fragment_marker(respawn_pos, top)

## The golem whole again: it stands up with a little hop and a puff.
func wake_respawned_piece(respawn_pos: Vector2) -> void:
	if match_board.should_skip_visual_animations():
		return
	var holder: Sprite2D = match_board.get_piece_holder_at(respawn_pos)
	if holder == null or holder.texture == null:
		return
	SFXManager.play("piece_placed")
	match_board.get_piece_move_animator().play_wake_hop(holder, respawn_pos)
	match_board.get_piece_shatter_animator().play_ground_puff(respawn_pos, holder.texture)

func refresh_piece_shatter_respawn_piece_visibility(respawn_pos: Vector2) -> void:
	if !MoveRules.is_valid_position(respawn_pos):
		return
	var holder: Sprite2D = match_board.get_piece_holder_at(respawn_pos)
	if holder != null:
		match_board.get_piece_display_controller().refresh_piece_holder_visual(holder, respawn_pos)
		return
	match_board.get_piece_display_controller().display_board()

func reveal_piece_shatter_respawn_piece(respawn_pos: Vector2) -> void:
	if !MoveRules.is_valid_position(respawn_pos):
		return
	var holder: Sprite2D = match_board.get_piece_holder_at(respawn_pos)
	if holder != null:
		match_board.get_piece_display_controller().refresh_piece_holder_visual(holder, respawn_pos)
		return
	match_board.get_piece_display_controller().display_board()

func play_piece_shatter_animations(animations: Array[Dictionary]) -> void:
	for animation: Dictionary in animations:
		var source_pos: Vector2 = BoardConfig.value_to_vector2(animation.get("source_pos", invalid_board_pos), invalid_board_pos)
		var respawn_pos: Vector2 = BoardConfig.value_to_vector2(animation.get("respawn_pos", invalid_board_pos), invalid_board_pos)
		var piece_color: int = int(animation.get("piece_color", 0))
		var fragment_group: String = str(animation.get("fragment_group", match_board.PIECE_SHATTER_FRAGMENT_GROUP_NONE))
		play_piece_shatter_animation(source_pos, respawn_pos, piece_color, fragment_group)

## A piece broken without a blow to read (a bomb, a sync with no move shown):
## a golem's chips, flying every way, with the sparkle going off as it breaks.
func play_piece_shatter_animation(source_pos: Vector2, respawn_pos: Vector2, piece_color: int, fragment_group: String = "") -> void:
	shatter_piece(source_pos, respawn_pos, piece_color, fragment_group, null, Vector2.ZERO, true)

## A piece broken by a blow, once the hitstop is over: its chips are cut from
## `captured_texture`, the drawing it showed, and fly along `blow_direction`
## (board steps, from the striker's square towards its own). Its sparkle went
## off at contact.
func play_capture_shatter_animation(source_pos: Vector2, respawn_pos: Vector2, piece_color: int, fragment_group: String, captured_texture: Texture2D, blow_direction: Vector2) -> void:
	shatter_piece(source_pos, respawn_pos, piece_color, fragment_group, captured_texture, blow_direction, false)

func shatter_piece(source_pos: Vector2, respawn_pos: Vector2, piece_color: int, fragment_group: String, captured_texture: Texture2D, blow_direction: Vector2, with_impact_effects: bool) -> void:
	# A half golem broken here goes with the blow, whatever else is shown.
	break_struck_half(source_pos)
	if match_board.should_skip_visual_animations():
		return
	if piece_color == 0:
		return
	if !MoveRules.is_valid_position(source_pos):
		return
	if match_board.piece_effects_node == null or !is_instance_valid(match_board.piece_effects_node):
		match_board.create_piece_effects_node()
	if match_board.piece_effects_node == null:
		return

	if with_impact_effects:
		play_capture_impact_effects(source_pos)

	var resolved_fragment_group: String = fragment_group
	if resolved_fragment_group.is_empty():
		resolved_fragment_group = match_board.PIECE_SHATTER_FRAGMENT_GROUP_NONE
	# The fragments that roll away are the golem that will stand up again,
	# whatever the broken piece looked like.
	var golem_texture: Texture2D = match_board.get_piece_texture_resolver().get_default_piece_texture(piece_color)
	var fragment_polygons: Array[PackedVector2Array] = get_piece_shatter_fragment_polygons(resolved_fragment_group, golem_texture)
	var returns_to_pending_edge: bool = resolved_fragment_group == match_board.PIECE_SHATTER_FRAGMENT_GROUP_PENDING
	var return_count: int = get_piece_shatter_return_fragment_count(resolved_fragment_group) if returns_to_pending_edge else begin_piece_shatter_respawn_reveal(respawn_pos, resolved_fragment_group)
	var can_return_fragments: bool = (MoveRules.is_valid_position(respawn_pos) or returns_to_pending_edge) and !fragment_polygons.is_empty() and return_count > 0
	var debris_count: int = maxi(0, match_board.piece_shatter_debris_count)
	if debris_count <= 0 and !can_return_fragments:
		return

	var debris_texture: Texture2D = captured_texture if captured_texture != null else golem_texture
	match_board.get_piece_shatter_animator().play_debris(source_pos, debris_texture, debris_count, blow_direction)

	if returns_to_pending_edge and can_return_fragments:
		play_piece_shatter_pending_edge_fragments(source_pos, piece_color, golem_texture, fragment_polygons, blow_direction)
	elif can_return_fragments:
		play_piece_shatter_return_fragments(source_pos, respawn_pos, golem_texture, fragment_polygons, resolved_fragment_group, blow_direction)

func play_capture_impact_effects(board_pos: Vector2, sparkle_color: Color = Color.TRANSPARENT) -> void:
	if !MoveRules.is_valid_position(board_pos):
		return
	if match_board.piece_effects_node == null or !is_instance_valid(match_board.piece_effects_node):
		match_board.create_piece_effects_node()
	if match_board.piece_effects_node == null:
		return
	match_board.get_piece_effect_animator().play_capture_sparkle(board_pos, sparkle_color)

## Which pieces of `PieceShatterAnimator.get_fragment_cut()` a group carries:
## the top three, or the bottom three.
func get_piece_shatter_fragment_cut_indices(fragment_group: String) -> Array[int]:
	match fragment_group:
		match_board.PIECE_SHATTER_FRAGMENT_GROUP_BOTTOM, match_board.PIECE_SHATTER_FRAGMENT_GROUP_PENDING:
			return [3, 4, 5]
		match_board.PIECE_SHATTER_FRAGMENT_GROUP_TOP:
			return [0, 1, 2]
	return []

func get_piece_shatter_fragment_polygons(fragment_group: String, golem_texture: Texture2D) -> Array[PackedVector2Array]:
	var polygons: Array[PackedVector2Array] = []
	if golem_texture == null:
		return polygons

	var cut: Array[PackedVector2Array] = match_board.get_piece_shatter_animator().get_fragment_cut(golem_texture)
	var cut_indices: Array[int] = get_piece_shatter_fragment_cut_indices(fragment_group)
	for cut_index in cut_indices.slice(0, get_piece_shatter_return_fragment_count(fragment_group)):
		if cut_index < cut.size():
			polygons.append(cut[cut_index])
	return polygons

func play_piece_shatter_return_fragments(source_pos: Vector2, respawn_pos: Vector2, golem_texture: Texture2D, fragment_polygons: Array[PackedVector2Array], fragment_group: String, blow_direction: Vector2) -> void:
	var created_count: int = 0
	for fragment_index in range(fragment_polygons.size()):
		var fragment: Polygon2D = match_board.get_piece_shatter_animator().create_fragment(source_pos, golem_texture, fragment_polygons[fragment_index], fragment_index)
		if fragment == null:
			continue

		created_count += 1
		if fragment_group == match_board.PIECE_SHATTER_FRAGMENT_GROUP_BOTTOM:
			add_piece_shatter_respawn_fragment_marker(respawn_pos, fragment)
		var scatter_target: Vector2 = match_board.get_piece_shatter_animator().get_scatter_target(source_pos, fragment_index, blow_direction)
		match_board.get_piece_shatter_animator().animate_fragment(fragment, scatter_target, source_pos, respawn_pos, fragment_group, fragment_index)
	adjust_piece_shatter_respawn_reveal_count(respawn_pos, created_count)

func play_piece_shatter_pending_edge_fragments(source_pos: Vector2, piece_color: int, golem_texture: Texture2D, fragment_polygons: Array[PackedVector2Array], blow_direction: Vector2) -> void:
	for fragment_index in range(fragment_polygons.size()):
		var fragment: Polygon2D = match_board.get_piece_shatter_animator().create_fragment(source_pos, golem_texture, fragment_polygons[fragment_index], fragment_index)
		if fragment == null:
			continue

		add_pending_edge_respawn_fragment_marker(piece_color, fragment)
		var scatter_target: Vector2 = match_board.get_piece_shatter_animator().get_scatter_target(source_pos, fragment_index, blow_direction)
		match_board.get_piece_shatter_animator().animate_pending_edge_fragment(fragment, scatter_target, source_pos, piece_color, fragment_index)

func add_pending_edge_respawn_fragment_marker(piece_color: int, fragment: Polygon2D) -> void:
	if piece_color == 0 or fragment == null or !is_instance_valid(fragment):
		return

	var key: int = get_pending_edge_respawn_key(piece_color)
	var markers: Array = match_board.pending_edge_respawn_fragment_markers.get(key, [])
	markers.append(fragment)
	match_board.pending_edge_respawn_fragment_markers[key] = markers

func take_pending_edge_respawn_fragment_markers(piece_color: int) -> Array[Polygon2D]:
	var markers: Array[Polygon2D] = []
	var key: int = get_pending_edge_respawn_key(piece_color)
	var stored_markers: Array = match_board.pending_edge_respawn_fragment_markers.get(key, [])
	for marker_value in stored_markers:
		var marker: Polygon2D = marker_value as Polygon2D
		if marker != null and is_instance_valid(marker):
			markers.append(marker)
	match_board.pending_edge_respawn_fragment_markers.erase(key)
	return markers

func get_pending_edge_respawn_key(piece_color: int) -> int:
	return BoardConfig.get_player_id_for_color(piece_color)

func play_pending_edge_respawn_arrival_animations(animations: Array) -> void:
	for animation_value in animations:
		if !(animation_value is Dictionary):
			continue
		var animation: Dictionary = animation_value
		var respawn_pos: Vector2 = BoardConfig.value_to_vector2(animation.get("respawn_pos", invalid_board_pos), invalid_board_pos)
		var piece_color: int = int(animation.get("piece_color", 0))
		var fragment_group: String = str(animation.get("fragment_group", match_board.PIECE_SHATTER_FRAGMENT_GROUP_BOTTOM))
		if !MoveRules.is_valid_position(respawn_pos) or piece_color == 0:
			continue

		var fragments: Array[Polygon2D] = take_pending_edge_respawn_fragment_markers(piece_color)
		if fragments.is_empty():
			fragments = create_pending_edge_respawn_fragment_markers(piece_color)
		if fragments.is_empty():
			cancel_piece_shatter_respawn_reveal(respawn_pos)
			continue

		var created_count: int = 0
		for fragment_index in range(fragments.size()):
			var fragment: Polygon2D = fragments[fragment_index]
			if fragment == null or !is_instance_valid(fragment):
				continue
			created_count += 1
			add_piece_shatter_respawn_fragment_marker(respawn_pos, fragment)
			match_board.get_piece_shatter_animator().animate_pending_edge_arrival_fragment(fragment, respawn_pos, fragment_group, fragment_index)
		adjust_piece_shatter_respawn_reveal_count(respawn_pos, created_count)

func create_pending_edge_respawn_fragment_markers(piece_color: int) -> Array[Polygon2D]:
	if match_board.piece_effects_node == null or !is_instance_valid(match_board.piece_effects_node):
		match_board.create_piece_effects_node()
	if match_board.piece_effects_node == null:
		return []

	var golem_texture: Texture2D = match_board.get_piece_texture_resolver().get_default_piece_texture(piece_color)
	var fragment_polygons: Array[PackedVector2Array] = get_piece_shatter_fragment_polygons(match_board.PIECE_SHATTER_FRAGMENT_GROUP_PENDING, golem_texture)
	return match_board.get_piece_shatter_animator().create_pending_edge_fragment_markers(piece_color, golem_texture, fragment_polygons)

func is_piece_shatter_route_cell_blocked(board_pos: Vector2, source_pos: Vector2, respawn_pos: Vector2) -> bool:
	if !MoveRules.is_valid_position(board_pos):
		return true
	if board_pos == source_pos or board_pos == respawn_pos:
		return false
	if match_board.piece_objects.has(board_pos):
		return true
	if int(match_board.board[int(board_pos.x)][int(board_pos.y)]) != 0:
		return true
	if has_piece_shatter_respawn_fragment_markers(board_pos):
		return true
	return false
