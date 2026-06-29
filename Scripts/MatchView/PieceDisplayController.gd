extends RefCounted

var match_board
var piece_visuals
var texture_resolver
var texture_holder_scene: PackedScene
var board_size: int = BoardConfig.BOARD_SIZE
var piece_light_receive_mask: int = 2
var selected_piece_glow_name: String = "SelectedPieceGlow"
var selected_piece_glow_z_index: int = 24
var selected_piece_glow_strength: float = 1.0
var invalid_board_pos: Vector2 = Vector2(-1, -1)

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	piece_visuals = config.get("piece_visuals", piece_visuals)
	texture_resolver = config.get("texture_resolver", texture_resolver)
	texture_holder_scene = config.get("texture_holder_scene", texture_holder_scene)
	board_size = int(config.get("board_size", board_size))
	piece_light_receive_mask = int(config.get("piece_light_receive_mask", piece_light_receive_mask))
	selected_piece_glow_name = str(config.get("selected_piece_glow_name", selected_piece_glow_name))
	selected_piece_glow_z_index = int(config.get("selected_piece_glow_z_index", selected_piece_glow_z_index))
	selected_piece_glow_strength = float(config.get("selected_piece_glow_strength", selected_piece_glow_strength))
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)

func display_board() -> void:
	if match_board == null:
		return
	DebugLog.info("display_board() called: white=%s side=%s" % [match_board.white, match_board.side])
	match_board.get_stamp_interaction_controller().clear_stamp_attach_target_feedback()
	match_board.clear_resolved_pending_stamp_attach_positions()
	match_board.update_board_markers()
	for child in match_board.pieces_node.get_children():
		child.queue_free()

	for i in board_size:
		for j in board_size:
			var board_pos := Vector2(i, j)
			var holder = texture_holder_scene.instantiate()
			if match_board.side != null and !match_board.side:
				holder.global_rotation_degrees = 180
				match_board.get_node("../Camera2D").global_rotation_degrees = 180
			match_board.pieces_node.add_child(holder)
			holder.light_mask = piece_light_receive_mask
			holder.position = match_board.get_board_position_local_position(board_pos)
			holder.set_meta("board_pos", board_pos)
			holder.z_index = piece_visuals.get_depth_z_index(board_pos) if piece_visuals != null else 0
			holder.texture = texture_resolver.get_piece_texture_for_position(board_pos, int(match_board.board[i][j])) if texture_resolver != null else null
			apply_piece_visual_size(holder, board_pos)
			apply_piece_respawn_lock_opacity(holder, board_pos)
			if match_board.get_piece_respawn_fragment_coordinator().should_hide_piece_for_shatter_respawn(board_pos):
				continue
			apply_piece_light_occluder(holder, board_pos)
			apply_piece_shadow(holder, board_pos)
			apply_piece_exhausted_material(holder, board_pos)
			apply_piece_freeze_overlay(holder, board_pos)
			apply_selected_piece_glow(holder, board_pos)

func refresh_piece_holder_visual(holder: Sprite2D, board_pos: Vector2) -> void:
	if match_board == null or piece_visuals == null or holder == null or !is_instance_valid(holder):
		return

	piece_visuals.apply_holder_base_visual(holder, board_pos)
	apply_piece_respawn_lock_opacity(holder, board_pos)
	if match_board.get_piece_respawn_fragment_coordinator().should_hide_piece_for_shatter_respawn(board_pos):
		apply_piece_exhausted_material(holder, board_pos)
		remove_piece_light_occluder(holder)
		remove_piece_shadow(holder)
		remove_piece_freeze_overlay(holder)
		remove_piece_freeze_square_overlay(board_pos)
		remove_selected_piece_glow(holder)
		return
	apply_piece_light_occluder(holder, board_pos)
	apply_piece_shadow(holder, board_pos)
	apply_piece_exhausted_material(holder, board_pos)
	apply_piece_freeze_overlay(holder, board_pos)
	apply_selected_piece_glow(holder, board_pos)

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
	piece_visuals.apply_shadow(holder, board_pos, get_piece_color_at(board_pos), match_board.get_own_color(), match_board.get_piece_effect_geometry_controller().get_attach_point_light_texture())

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

func apply_selected_piece_glow(holder: Sprite2D, board_pos: Vector2) -> void:
	remove_selected_piece_glow(holder)
	if !match_board.state or board_pos != match_board.selected_piece or holder.texture == null:
		return
	if !match_board.piece_objects.has(board_pos):
		return

	match_board.get_piece_effect_animator().create_glow_overlay(holder, selected_piece_glow_name, selected_piece_glow_z_index, selected_piece_glow_strength)

func remove_selected_piece_glow(holder: Sprite2D) -> void:
	var existing_glow: Node = holder.get_node_or_null(selected_piece_glow_name)
	if existing_glow != null:
		existing_glow.free()

func update_selected_piece_glow() -> void:
	if match_board.pieces_node == null:
		return

	for child in match_board.pieces_node.get_children():
		var holder: Sprite2D = child as Sprite2D
		if holder == null:
			continue

		var board_pos: Vector2 = match_board.value_to_vector2(holder.get_meta("board_pos", invalid_board_pos), invalid_board_pos)
		apply_selected_piece_glow(holder, board_pos)

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
