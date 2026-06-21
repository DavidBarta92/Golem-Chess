extends RefCounted

var match_board
var texture_holder_scene: PackedScene
var board_size: int = BoardConfig.BOARD_SIZE
var piece_light_receive_mask: int = 2
var selected_piece_glow_name: String = "SelectedPieceGlow"
var selected_piece_glow_z_index: int = 24
var selected_piece_glow_strength: float = 1.0
var invalid_board_pos: Vector2 = Vector2(-1, -1)

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	texture_holder_scene = config.get("texture_holder_scene", texture_holder_scene)
	board_size = int(config.get("board_size", board_size))
	piece_light_receive_mask = int(config.get("piece_light_receive_mask", piece_light_receive_mask))
	selected_piece_glow_name = str(config.get("selected_piece_glow_name", selected_piece_glow_name))
	selected_piece_glow_z_index = int(config.get("selected_piece_glow_z_index", selected_piece_glow_z_index))
	selected_piece_glow_strength = float(config.get("selected_piece_glow_strength", selected_piece_glow_strength))
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)

func display_board() -> void:
	DebugLog.info("display_board() called: white=%s side=%s" % [match_board.white, match_board.side])
	match_board.get_card_interaction_controller().clear_card_attach_target_feedback()
	match_board.clear_resolved_pending_card_attach_positions()
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
			holder.z_index = match_board.get_piece_depth_z_index(board_pos)
			holder.texture = match_board.get_piece_texture_for_position(board_pos, int(match_board.board[i][j]))
			match_board.apply_piece_visual_size(holder, board_pos)
			match_board.apply_piece_respawn_lock_opacity(holder, board_pos)
			if match_board.should_hide_piece_for_shatter_respawn(board_pos):
				continue
			match_board.apply_piece_light_occluder(holder, board_pos)
			match_board.apply_piece_shadow(holder, board_pos)
			apply_piece_exhausted_material(holder, board_pos)
			apply_piece_freeze_overlay(holder, board_pos)
			apply_selected_piece_glow(holder, board_pos)

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
	holder.material = match_board.get_piece_kuwahara_material()

func apply_piece_freeze_overlay(holder: Sprite2D, board_pos: Vector2) -> void:
	match_board.get_freeze_effect_animator().apply_overlay(holder, board_pos)

func refresh_piece_freeze_overlay(board_pos: Vector2) -> void:
	match_board.get_freeze_effect_animator().refresh(board_pos)

func remove_piece_freeze_overlay(holder: Sprite2D) -> void:
	match_board.get_freeze_effect_animator().remove_overlay(holder)

func remove_piece_freeze_square_overlay(board_pos: Vector2) -> void:
	match_board.get_freeze_effect_animator().remove_square_overlay(board_pos)
