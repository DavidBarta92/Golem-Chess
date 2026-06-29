extends RefCounted

var match_board
var default_piece_texture: Texture2D
var own_default_piece_texture: Texture2D
var invalid_board_pos: Vector2 = Vector2(-1, -1)

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	default_piece_texture = config.get("default_piece_texture", default_piece_texture)
	own_default_piece_texture = config.get("own_default_piece_texture", own_default_piece_texture)
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)

func get_default_piece_texture(piece_value: int) -> Texture2D:
	if piece_value == 0:
		return null
	if piece_value * get_own_color() > 0:
		return own_default_piece_texture
	return default_piece_texture

func get_attached_stamp_piece_texture(piece: Piece) -> Texture2D:
	if piece == null or piece.attached_stamp == null:
		return null
	return piece.attached_stamp.get_piece_texture(piece.color, get_piece_board_view(piece.color))

func get_piece_texture_for_position(board_pos: Vector2, piece_value: int) -> Texture2D:
	var attached_texture: Texture2D = null
	if match_board != null and match_board.piece_objects.has(board_pos):
		var piece: Piece = match_board.piece_objects[board_pos] as Piece
		if piece != null and piece.hidden_from_viewer:
			return null
		attached_texture = get_attached_stamp_piece_texture(piece)
	if attached_texture != null:
		return attached_texture
	return get_default_piece_texture(piece_value)

func get_stamp_piece_texture_for_color(stamp: Stamp, piece_color: int) -> Texture2D:
	if stamp == null:
		return null
	return stamp.get_piece_texture(piece_color, get_piece_board_view(piece_color))

func get_stamp_piece_preview_texture(stamp: Stamp, piece_color: int) -> Texture2D:
	if stamp == null:
		return null
	return stamp.get_piece_preview_texture(piece_color)

func get_piece_board_view(piece_color: int) -> String:
	if piece_color * get_own_color() > 0:
		return PieceVisualSet.VIEW_BACK
	return PieceVisualSet.VIEW_FRONT

func get_piece_visual_texture(piece: Piece) -> Texture2D:
	if piece == null or piece.hidden_from_viewer:
		return null

	var attached_texture: Texture2D = get_attached_stamp_piece_texture(piece)
	if attached_texture != null:
		return attached_texture
	return get_default_piece_texture(piece.color)

func get_piece_visual_state_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	if match_board == null:
		return snapshot

	for position_value in match_board.piece_objects:
		var board_pos: Vector2 = match_board.value_to_vector2(position_value, invalid_board_pos)
		var piece: Piece = match_board.piece_objects[position_value] as Piece
		if piece == null or piece.hidden_from_viewer:
			continue

		snapshot[board_pos] = {
			"color": piece.color,
			"stamp_name": piece.attached_stamp.stamp_name if piece.attached_stamp != null else "",
			"texture": get_piece_visual_texture(piece),
			"respawn_cooldown_turns": piece.respawn_cooldown_turns,
		}

	return snapshot

func get_own_color() -> int:
	if match_board == null:
		return 1
	return match_board.get_own_color()
