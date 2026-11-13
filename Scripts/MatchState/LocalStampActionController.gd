extends RefCounted

var match_board
func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)

func can_exchange_stamp_locally(_owner_color: int) -> bool:
	return false

func is_tutorial_exchange_stamp_allowed(_owner_color: int, _stamp_name: String, _hand_index: int, _emit_rejection: bool) -> bool:
	return false

func complete_stamp_exchange(owner_color: int, stamp_name: String, hand_index: int, should_record_name: bool, source_global_position = null) -> void:
	if should_record_name:
		match_board.get_stamp_hand_state_controller().record_exchanged_stamp_name_this_turn(owner_color, stamp_name)
		var return_animation: Dictionary = {
			"source_player_id": BoardConfig.get_player_id_for_color(owner_color),
			"target_player_id": BoardConfig.get_player_id_for_color(owner_color),
			"stamp_name": stamp_name,
			"source_zone": "hand",
			"target_zone": "deck",
		}
		if source_global_position is Vector2:
			return_animation["source_global_position"] = source_global_position
		match_board.get_stamp_animation_controller().queue_stamp_return_to_deck_animation(return_animation)
	match_board.get_turn_action_state_controller().mark_stamp_exchanged_this_turn(owner_color)
	match_board.stamp_exchanged.emit(stamp_name, owner_color, hand_index)

func send_stamp_exchange_action(_owner_color: int, _stamp_name: String, _hand_index: int) -> bool:
	return false

func affix_stamp_visual_to_piece(stamp_visual: StampVisual, piece_position: Vector2) -> void:
	if stamp_visual == null or !is_instance_valid(stamp_visual):
		return
	if not match_board.piece_objects.has(piece_position) or stamp_visual.stamp == null:
		stamp_visual.fly_home()
		return
	var affix_stamp: Stamp = stamp_visual.stamp
	var stamp_name: String = affix_stamp.stamp_name
	var owner_color: int = stamp_visual.owner_color
	var hand_index: int = match_board.get_stamp_hand_state_controller().get_stamp_visual_index(stamp_visual)
	if !match_board.get_tutorial_match_adapter().is_action_allowed(match_board.TUTORIAL_ACTION_AFFIX_STAMP, {
		"owner_color": owner_color,
		"piece_pos": piece_position,
		"stamp_name": stamp_name,
		"hand_index": hand_index,
	}, true):
		stamp_visual.fly_home()
		return
	if !can_affix_stamp_to_piece(piece_position, stamp_name, owner_color):
		stamp_visual.fly_home()
		return

	var start_texture: Texture2D = null
	var holder: Sprite2D = match_board.get_piece_holder_at(piece_position)
	if holder != null and is_instance_valid(holder):
		start_texture = holder.texture

	match_board.begin_stamp_affix_process(piece_position)
	match_board.get_stamp_hand_state_controller().record_played_stamp_hand_slot(owner_color, hand_index)
	stamp_visual.assign_and_hide()
	if !send_stamp_affix_action(owner_color, stamp_name, piece_position, hand_index):
		match_board.finish_stamp_affix_process(piece_position)
		return
	match_board.get_turn_action_state_controller().mark_stamp_affixed_this_turn(owner_color)
	match_board.stamp_affixed.emit(piece_position, stamp_name, owner_color, hand_index)

func send_stamp_affix_action(owner_color: int, stamp_name: String, piece_position: Vector2, hand_index: int) -> bool:
	var action: Dictionary = {
		"type": "affix_stamp",
		"player_id": BoardConfig.get_player_id_for_color(owner_color),
		"stamp_name": stamp_name,
		"piece_pos": piece_position,
		"hand_index": hand_index,
	}
	return bool(GameController.send_action(action))

func can_affix_stamp_to_piece(piece_position: Vector2, stamp_name: String = "", owner_color: int = 0) -> bool:
	if not match_board.piece_objects.has(piece_position):
		return false
	if match_board.pending_stamp_affix_positions.has(piece_position):
		return false
	var action_owner_color: int = owner_color if owner_color != 0 else match_board.get_controllable_color()
	if !match_board.get_tutorial_match_adapter().is_action_allowed(match_board.TUTORIAL_ACTION_AFFIX_STAMP, {
		"owner_color": action_owner_color,
		"piece_pos": piece_position,
		"stamp_name": stamp_name,
	}):
		return false

	var piece: Piece = match_board.piece_objects[piece_position] as Piece
	return piece.can_receive_stamp(StampLibrary.get_stamp(stamp_name))

