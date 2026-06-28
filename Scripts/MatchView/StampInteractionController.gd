extends RefCounted

const INVALID_BOARD_POS = Vector2(-1, -1)

var tween_owner: Node
var geometry
var visuals
var board_markers_node: Node2D
var stamp_attach_target_fill_color: Color = Color(1.0, 0.92, 0.58, 0.24)
var stamp_attach_target_fill_inset: float = 1.0
var stamp_attach_target_wiggle_rise: float = 2.2
var stamp_attach_target_wiggle_rotation_degrees: float = 2.2
var stamp_attach_target_wiggle_step_duration: float = 0.105

var hide_hover_callback: Callable
var show_hover_stamp_description_callback: Callable
var can_control_current_turn_provider: Callable
var controllable_color_provider: Callable
var is_mouse_out_provider: Callable
var mouse_board_position_provider: Callable
var is_valid_position_callback: Callable
var is_piece_owned_by_callback: Callable
var can_attach_stamp_to_piece_callback: Callable
var can_exchange_stamp_locally_callback: Callable
var is_mouse_over_deck_callback: Callable
var attach_stamp_visual_to_piece_callback: Callable
var stamp_visuals_provider: Callable
var stamp_hand_provider: Callable
var stamp_home_position_provider: Callable
var piece_holder_provider: Callable
var stamp_visual_index_provider: Callable
var tutorial_exchange_allowed_callback: Callable
var send_stamp_exchange_callback: Callable
var stamp_deck_provider: Callable
var remove_stamp_from_hand_index_callback: Callable
var complete_stamp_exchange_callback: Callable

var stamp_attach_target_marker: Node2D
var stamp_attach_target_position: Vector2 = INVALID_BOARD_POS
var stamp_attach_target_piece: Sprite2D
var stamp_attach_target_piece_base_position: Vector2 = Vector2.ZERO
var stamp_attach_target_piece_base_rotation: float = 0.0
var stamp_attach_target_piece_tween: Tween

func configure(config: Dictionary) -> void:
	tween_owner = config.get("tween_owner", tween_owner)
	geometry = config.get("geometry", geometry)
	visuals = config.get("visuals", visuals)
	board_markers_node = config.get("board_markers_node", board_markers_node)
	stamp_attach_target_fill_color = config.get("stamp_attach_target_fill_color", stamp_attach_target_fill_color)
	stamp_attach_target_fill_inset = float(config.get("stamp_attach_target_fill_inset", stamp_attach_target_fill_inset))
	stamp_attach_target_wiggle_rise = float(config.get("stamp_attach_target_wiggle_rise", stamp_attach_target_wiggle_rise))
	stamp_attach_target_wiggle_rotation_degrees = float(config.get("stamp_attach_target_wiggle_rotation_degrees", stamp_attach_target_wiggle_rotation_degrees))
	stamp_attach_target_wiggle_step_duration = float(config.get("stamp_attach_target_wiggle_step_duration", stamp_attach_target_wiggle_step_duration))

	hide_hover_callback = config.get("hide_hover_callback", hide_hover_callback)
	show_hover_stamp_description_callback = config.get("show_hover_stamp_description_callback", show_hover_stamp_description_callback)
	can_control_current_turn_provider = config.get("can_control_current_turn_provider", can_control_current_turn_provider)
	controllable_color_provider = config.get("controllable_color_provider", controllable_color_provider)
	is_mouse_out_provider = config.get("is_mouse_out_provider", is_mouse_out_provider)
	mouse_board_position_provider = config.get("mouse_board_position_provider", mouse_board_position_provider)
	is_valid_position_callback = config.get("is_valid_position_callback", is_valid_position_callback)
	is_piece_owned_by_callback = config.get("is_piece_owned_by_callback", is_piece_owned_by_callback)
	can_attach_stamp_to_piece_callback = config.get("can_attach_stamp_to_piece_callback", can_attach_stamp_to_piece_callback)
	can_exchange_stamp_locally_callback = config.get("can_exchange_stamp_locally_callback", can_exchange_stamp_locally_callback)
	is_mouse_over_deck_callback = config.get("is_mouse_over_deck_callback", is_mouse_over_deck_callback)
	attach_stamp_visual_to_piece_callback = config.get("attach_stamp_visual_to_piece_callback", attach_stamp_visual_to_piece_callback)
	stamp_visuals_provider = config.get("stamp_visuals_provider", stamp_visuals_provider)
	stamp_hand_provider = config.get("stamp_hand_provider", stamp_hand_provider)
	stamp_home_position_provider = config.get("stamp_home_position_provider", stamp_home_position_provider)
	piece_holder_provider = config.get("piece_holder_provider", piece_holder_provider)
	stamp_visual_index_provider = config.get("stamp_visual_index_provider", stamp_visual_index_provider)
	tutorial_exchange_allowed_callback = config.get("tutorial_exchange_allowed_callback", tutorial_exchange_allowed_callback)
	send_stamp_exchange_callback = config.get("send_stamp_exchange_callback", send_stamp_exchange_callback)
	stamp_deck_provider = config.get("stamp_deck_provider", stamp_deck_provider)
	remove_stamp_from_hand_index_callback = config.get("remove_stamp_from_hand_index_callback", remove_stamp_from_hand_index_callback)
	complete_stamp_exchange_callback = config.get("complete_stamp_exchange_callback", complete_stamp_exchange_callback)

func connect_stamp_visual_signals(stamp_visual: StampVisual) -> void:
	if stamp_visual == null or !is_instance_valid(stamp_visual):
		return

	if !stamp_visual.drag_started.is_connected(on_stamp_drag_started):
		stamp_visual.drag_started.connect(on_stamp_drag_started)
	if !stamp_visual.drag_moved.is_connected(on_stamp_drag_moved):
		stamp_visual.drag_moved.connect(on_stamp_drag_moved)
	if !stamp_visual.drag_released.is_connected(on_stamp_drag_released):
		stamp_visual.drag_released.connect(on_stamp_drag_released)
	stamp_visual.mouse_entered.connect(on_hand_stamp_mouse_entered.bind(stamp_visual))
	stamp_visual.mouse_exited.connect(on_hand_stamp_mouse_exited.bind(stamp_visual))

func on_stamp_drag_started(stamp_visual: StampVisual) -> void:
	call_no_args(hide_hover_callback)
	if stamp_visual != null and is_instance_valid(stamp_visual):
		stamp_visual.set_drop_target_active(false)
	update_stamp_attach_target_feedback(INVALID_BOARD_POS)

func on_stamp_drag_moved(stamp_visual: StampVisual) -> void:
	var target_pos: Vector2 = get_stamp_drop_piece_position(stamp_visual)
	var can_drop_on_deck: bool = can_drop_stamp_on_deck(stamp_visual)
	if stamp_visual != null and is_instance_valid(stamp_visual):
		stamp_visual.set_drop_target_active(target_pos != INVALID_BOARD_POS or can_drop_on_deck)
	update_stamp_attach_target_feedback(target_pos)
	handle_stamp_reorder(stamp_visual)

func on_stamp_drag_released(stamp_visual: StampVisual) -> void:
	var target_pos: Vector2 = get_stamp_drop_piece_position(stamp_visual)
	update_stamp_attach_target_feedback(INVALID_BOARD_POS)
	if target_pos != INVALID_BOARD_POS:
		if attach_stamp_visual_to_piece_callback.is_valid():
			attach_stamp_visual_to_piece_callback.call(stamp_visual, target_pos)
	elif can_drop_stamp_on_deck(stamp_visual):
		exchange_stamp_visual_with_deck(stamp_visual)
	elif stamp_visual != null and is_instance_valid(stamp_visual):
		stamp_visual.fly_home()

func on_hand_stamp_mouse_entered(stamp_visual: StampVisual) -> void:
	if stamp_visual == null or !is_instance_valid(stamp_visual):
		return
	if stamp_visual.stamp == null or stamp_visual.face_down or stamp_visual.is_dragging:
		return
	if show_hover_stamp_description_callback.is_valid():
		show_hover_stamp_description_callback.call(stamp_visual.stamp)

func on_hand_stamp_mouse_exited(_stamp_visual: StampVisual) -> void:
	call_no_args(hide_hover_callback)

func get_stamp_drop_piece_position(stamp_visual: StampVisual) -> Vector2:
	if stamp_visual == null or !is_instance_valid(stamp_visual):
		return INVALID_BOARD_POS
	if !get_bool(can_control_current_turn_provider, false):
		return INVALID_BOARD_POS
	if stamp_visual.owner_color != get_int(controllable_color_provider, 0):
		return INVALID_BOARD_POS
	if get_bool(is_mouse_out_provider, true):
		return INVALID_BOARD_POS

	var board_pos: Vector2 = get_vector2(mouse_board_position_provider, INVALID_BOARD_POS)
	var stamp_name: String = stamp_visual.stamp.stamp_name if stamp_visual.stamp else ""
	if is_valid_position(board_pos) and is_piece_owned_by(board_pos, stamp_visual.owner_color) and can_attach_stamp_to_piece(board_pos, stamp_name, stamp_visual.owner_color):
		return board_pos

	return INVALID_BOARD_POS

func can_drop_stamp_on_deck(stamp_visual: StampVisual) -> bool:
	return false

func exchange_stamp_visual_with_deck(stamp_visual: StampVisual) -> void:
	if stamp_visual == null or !is_instance_valid(stamp_visual) or stamp_visual.stamp == null:
		return

	var owner_color: int = stamp_visual.owner_color
	if !can_exchange_stamp_locally(owner_color):
		stamp_visual.fly_home()
		return

	var hand_index: int = get_stamp_visual_index(stamp_visual)
	if hand_index < 0:
		stamp_visual.fly_home()
		return

	var stamp_name: String = stamp_visual.stamp.stamp_name
	if !is_tutorial_exchange_allowed(owner_color, stamp_name, hand_index, true):
		stamp_visual.fly_home()
		return

	if GameController.current_game_host:
		if send_stamp_exchange(owner_color, stamp_name, hand_index):
			complete_stamp_exchange(owner_color, stamp_name, hand_index, false)
		if is_instance_valid(stamp_visual):
			stamp_visual.fly_home()
		return

	var deck: Array = get_stamp_deck(owner_color)
	if deck.is_empty():
		stamp_visual.fly_home()
		return

	var replacement_stamp_name: String = draw_exchange_replacement_stamp_name(deck, stamp_name)
	if replacement_stamp_name.is_empty():
		stamp_visual.fly_home()
		return

	var return_source_position: Vector2 = stamp_visual.global_position
	remove_stamp_from_hand_index(owner_color, hand_index, true, replacement_stamp_name)
	DeckManager.return_stamp_to_deck(deck, stamp_name)
	complete_stamp_exchange(owner_color, stamp_name, hand_index, true, return_source_position)
	if is_instance_valid(stamp_visual):
		stamp_visual.assign_and_hide()
		stamp_visual.queue_free()

func draw_exchange_replacement_stamp_name(deck: Array, returned_stamp_name: String) -> String:
	return draw_stamp_from_deck_avoiding_names(deck, [returned_stamp_name])

func draw_stamp_from_deck_avoiding_names(deck: Array, avoided_stamp_names: Array) -> String:
	if deck.is_empty():
		return ""

	var draw_index: int = -1
	for i in deck.size():
		var candidate_name: String = str(deck[i])
		if !avoided_stamp_names.has(candidate_name):
			draw_index = i
			break
	if draw_index == -1:
		draw_index = 0

	var drawn_stamp_name: String = str(deck[draw_index])
	deck.remove_at(draw_index)
	return drawn_stamp_name

func update_stamp_attach_target_feedback(target_pos: Vector2) -> void:
	if target_pos == stamp_attach_target_position:
		return

	clear_stamp_attach_target_feedback()
	if target_pos == INVALID_BOARD_POS or !is_valid_position(target_pos):
		return

	stamp_attach_target_position = target_pos
	stamp_attach_target_marker = create_stamp_attach_target_marker(target_pos)
	start_stamp_attach_target_piece_wiggle(target_pos)

func create_stamp_attach_target_marker(target_pos: Vector2) -> Node2D:
	if board_markers_node == null or !is_instance_valid(board_markers_node) or geometry == null:
		return null

	var marker_group := Node2D.new()
	marker_group.name = "StampAttachTargetMarker"
	marker_group.z_index = 0
	var marker := Polygon2D.new()
	marker.name = "Fill"
	marker.color = stamp_attach_target_fill_color
	marker.polygon = geometry.get_cell_polygon_local(target_pos, stamp_attach_target_fill_inset)
	if visuals != null:
		visuals.enable_canvas_item_antialiasing(marker)
	marker_group.add_child(marker)
	board_markers_node.add_child(marker_group)
	return marker_group

func start_stamp_attach_target_piece_wiggle(target_pos: Vector2) -> void:
	var holder: Sprite2D = get_piece_holder_at(target_pos)
	if holder == null or !is_instance_valid(holder):
		return
	if tween_owner == null or !is_instance_valid(tween_owner):
		return

	stamp_attach_target_piece = holder
	stamp_attach_target_piece_base_position = holder.position
	stamp_attach_target_piece_base_rotation = holder.rotation
	var lift: Vector2 = Vector2(0.0, -stamp_attach_target_wiggle_rise)
	var tilt: float = deg_to_rad(stamp_attach_target_wiggle_rotation_degrees)
	stamp_attach_target_piece_tween = tween_owner.create_tween().set_loops().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	stamp_attach_target_piece_tween.tween_property(holder, "position", stamp_attach_target_piece_base_position + lift, stamp_attach_target_wiggle_step_duration)
	stamp_attach_target_piece_tween.parallel().tween_property(holder, "rotation", stamp_attach_target_piece_base_rotation + tilt, stamp_attach_target_wiggle_step_duration)
	stamp_attach_target_piece_tween.tween_property(holder, "position", stamp_attach_target_piece_base_position, stamp_attach_target_wiggle_step_duration)
	stamp_attach_target_piece_tween.parallel().tween_property(holder, "rotation", stamp_attach_target_piece_base_rotation - tilt, stamp_attach_target_wiggle_step_duration)
	stamp_attach_target_piece_tween.tween_property(holder, "position", stamp_attach_target_piece_base_position + lift * 0.55, stamp_attach_target_wiggle_step_duration)
	stamp_attach_target_piece_tween.parallel().tween_property(holder, "rotation", stamp_attach_target_piece_base_rotation, stamp_attach_target_wiggle_step_duration)
	stamp_attach_target_piece_tween.tween_property(holder, "position", stamp_attach_target_piece_base_position, stamp_attach_target_wiggle_step_duration)

func clear_stamp_attach_target_feedback() -> void:
	if stamp_attach_target_marker != null and is_instance_valid(stamp_attach_target_marker):
		stamp_attach_target_marker.queue_free()
	stamp_attach_target_marker = null
	stamp_attach_target_position = INVALID_BOARD_POS

	if stamp_attach_target_piece_tween != null and stamp_attach_target_piece_tween.is_running():
		stamp_attach_target_piece_tween.kill()
	stamp_attach_target_piece_tween = null
	if stamp_attach_target_piece != null and is_instance_valid(stamp_attach_target_piece):
		stamp_attach_target_piece.position = stamp_attach_target_piece_base_position
		stamp_attach_target_piece.rotation = stamp_attach_target_piece_base_rotation
	stamp_attach_target_piece = null

func handle_stamp_reorder(stamp_visual: StampVisual) -> void:
	if stamp_visual == null or !is_instance_valid(stamp_visual):
		return
	handle_stamp_reorder_in_hand(stamp_visual, get_stamp_visuals(stamp_visual.owner_color), get_stamp_hand(stamp_visual.owner_color))

func handle_stamp_reorder_in_hand(stamp_visual: StampVisual, visuals_array: Array, stamps_array: Array) -> void:
	var visuals: Array[StampVisual] = []
	for visual_value in visuals_array:
		if visual_value is StampVisual:
			visuals.append(visual_value)
	var stamps: Array[Stamp] = []
	for stamp_value in stamps_array:
		if stamp_value is Stamp:
			stamps.append(stamp_value)

	var stamp_index: int = visuals.find(stamp_visual)
	if stamp_index == -1:
		return

	var hand_node: Control = stamp_visual.get_parent() as Control
	if hand_node == null:
		return

	var mouse_pos: Vector2 = hand_node.get_local_mouse_position()
	var swap_index: int = -1
	var left_index: int = stamp_index - 1
	var right_index: int = stamp_index + 1

	if left_index >= 0:
		var left_midpoint: float = (get_stamp_home_position(left_index).x + get_stamp_home_position(stamp_index).x) * 0.5
		if mouse_pos.x < left_midpoint:
			swap_index = left_index
	if swap_index == -1 and right_index < visuals.size():
		var right_midpoint: float = (get_stamp_home_position(right_index).x + get_stamp_home_position(stamp_index).x) * 0.5
		if mouse_pos.x > right_midpoint:
			swap_index = right_index

	if swap_index == -1:
		return

	var visual_temp: StampVisual = visuals_array[stamp_index]
	visuals_array[stamp_index] = visuals_array[swap_index]
	visuals_array[swap_index] = visual_temp

	var stamp_temp: Stamp = stamps_array[stamp_index]
	stamps_array[stamp_index] = stamps_array[swap_index]
	stamps_array[swap_index] = stamp_temp

	arrange_stamp_visuals(visuals_array, true)

func arrange_stamp_visuals(visuals_array: Array, animate: bool) -> void:
	for i in visuals_array.size():
		var stamp_visual: StampVisual = visuals_array[i] as StampVisual
		if stamp_visual == null or !is_instance_valid(stamp_visual):
			continue
		stamp_visual.hand_index = i
		stamp_visual.set_home_position(get_stamp_home_position(i), animate)

func get_stamp_visuals(owner_color: int) -> Array:
	if stamp_visuals_provider.is_valid():
		var value = stamp_visuals_provider.call(owner_color)
		if value is Array:
			return value
	return []

func get_stamp_hand(owner_color: int) -> Array:
	if stamp_hand_provider.is_valid():
		var value = stamp_hand_provider.call(owner_color)
		if value is Array:
			return value
	return []

func get_stamp_home_position(index: int) -> Vector2:
	if stamp_home_position_provider.is_valid():
		var value = stamp_home_position_provider.call(index)
		if value is Vector2:
			return value
	return Vector2.ZERO

func get_piece_holder_at(board_pos: Vector2) -> Sprite2D:
	if piece_holder_provider.is_valid():
		var value = piece_holder_provider.call(board_pos)
		if value is Sprite2D:
			return value
	return null

func get_stamp_visual_index(stamp_visual: StampVisual) -> int:
	if stamp_visual_index_provider.is_valid():
		return int(stamp_visual_index_provider.call(stamp_visual))
	return -1

func is_tutorial_exchange_allowed(owner_color: int, stamp_name: String, hand_index: int, emit_rejection: bool) -> bool:
	if tutorial_exchange_allowed_callback.is_valid():
		return bool(tutorial_exchange_allowed_callback.call(owner_color, stamp_name, hand_index, emit_rejection))
	return true

func send_stamp_exchange(owner_color: int, stamp_name: String, hand_index: int) -> bool:
	if send_stamp_exchange_callback.is_valid():
		return bool(send_stamp_exchange_callback.call(owner_color, stamp_name, hand_index))
	return false

func get_stamp_deck(owner_color: int) -> Array:
	if stamp_deck_provider.is_valid():
		var value = stamp_deck_provider.call(owner_color)
		if value is Array:
			return value
	return []

func remove_stamp_from_hand_index(owner_color: int, hand_index: int, should_draw_replacement: bool, replacement_stamp_name: String) -> void:
	if remove_stamp_from_hand_index_callback.is_valid():
		remove_stamp_from_hand_index_callback.call(owner_color, hand_index, should_draw_replacement, replacement_stamp_name)

func complete_stamp_exchange(owner_color: int, stamp_name: String, hand_index: int, should_record_name: bool, source_global_position = null) -> void:
	if complete_stamp_exchange_callback.is_valid():
		complete_stamp_exchange_callback.call(owner_color, stamp_name, hand_index, should_record_name, source_global_position)

func is_valid_position(board_pos: Vector2) -> bool:
	return bool(is_valid_position_callback.call(board_pos)) if is_valid_position_callback.is_valid() else false

func is_piece_owned_by(board_pos: Vector2, owner_color: int) -> bool:
	return bool(is_piece_owned_by_callback.call(board_pos, owner_color)) if is_piece_owned_by_callback.is_valid() else false

func can_attach_stamp_to_piece(board_pos: Vector2, stamp_name: String, owner_color: int) -> bool:
	return bool(can_attach_stamp_to_piece_callback.call(board_pos, stamp_name, owner_color)) if can_attach_stamp_to_piece_callback.is_valid() else false

func can_exchange_stamp_locally(owner_color: int) -> bool:
	return bool(can_exchange_stamp_locally_callback.call(owner_color)) if can_exchange_stamp_locally_callback.is_valid() else false

func is_mouse_over_deck(owner_color: int) -> bool:
	return bool(is_mouse_over_deck_callback.call(owner_color)) if is_mouse_over_deck_callback.is_valid() else false

func call_no_args(callback: Callable) -> void:
	if callback.is_valid():
		callback.call()

func get_bool(provider: Callable, fallback: bool) -> bool:
	if provider.is_valid():
		return bool(provider.call())
	return fallback

func get_int(provider: Callable, fallback: int) -> int:
	if provider.is_valid():
		return int(provider.call())
	return fallback

func get_vector2(provider: Callable, fallback: Vector2) -> Vector2:
	if provider.is_valid():
		var value = provider.call()
		if value is Vector2:
			return value
	return fallback
