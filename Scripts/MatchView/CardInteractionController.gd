extends RefCounted

const INVALID_BOARD_POS = Vector2(-1, -1)

var tween_owner: Node
var geometry
var visuals
var board_markers_node: Node2D
var card_attach_target_fill_color: Color = Color(1.0, 0.92, 0.58, 0.24)
var card_attach_target_fill_inset: float = 1.0
var card_attach_target_wiggle_rise: float = 2.2
var card_attach_target_wiggle_rotation_degrees: float = 2.2
var card_attach_target_wiggle_step_duration: float = 0.105

var hide_hover_callback: Callable
var show_hover_card_description_callback: Callable
var can_control_current_turn_provider: Callable
var controllable_color_provider: Callable
var is_mouse_out_provider: Callable
var mouse_board_position_provider: Callable
var is_valid_position_callback: Callable
var is_piece_owned_by_callback: Callable
var can_attach_card_to_piece_callback: Callable
var can_exchange_card_locally_callback: Callable
var is_mouse_over_deck_callback: Callable
var attach_card_visual_to_piece_callback: Callable
var card_visuals_provider: Callable
var card_hand_provider: Callable
var card_home_position_provider: Callable
var piece_holder_provider: Callable
var card_visual_index_provider: Callable
var tutorial_exchange_allowed_callback: Callable
var send_card_exchange_callback: Callable
var card_deck_provider: Callable
var remove_card_from_hand_index_callback: Callable
var complete_card_exchange_callback: Callable

var card_attach_target_marker: Node2D
var card_attach_target_position: Vector2 = INVALID_BOARD_POS
var card_attach_target_piece: Sprite2D
var card_attach_target_piece_base_position: Vector2 = Vector2.ZERO
var card_attach_target_piece_base_rotation: float = 0.0
var card_attach_target_piece_tween: Tween

func configure(config: Dictionary) -> void:
	tween_owner = config.get("tween_owner", tween_owner)
	geometry = config.get("geometry", geometry)
	visuals = config.get("visuals", visuals)
	board_markers_node = config.get("board_markers_node", board_markers_node)
	card_attach_target_fill_color = config.get("card_attach_target_fill_color", card_attach_target_fill_color)
	card_attach_target_fill_inset = float(config.get("card_attach_target_fill_inset", card_attach_target_fill_inset))
	card_attach_target_wiggle_rise = float(config.get("card_attach_target_wiggle_rise", card_attach_target_wiggle_rise))
	card_attach_target_wiggle_rotation_degrees = float(config.get("card_attach_target_wiggle_rotation_degrees", card_attach_target_wiggle_rotation_degrees))
	card_attach_target_wiggle_step_duration = float(config.get("card_attach_target_wiggle_step_duration", card_attach_target_wiggle_step_duration))

	hide_hover_callback = config.get("hide_hover_callback", hide_hover_callback)
	show_hover_card_description_callback = config.get("show_hover_card_description_callback", show_hover_card_description_callback)
	can_control_current_turn_provider = config.get("can_control_current_turn_provider", can_control_current_turn_provider)
	controllable_color_provider = config.get("controllable_color_provider", controllable_color_provider)
	is_mouse_out_provider = config.get("is_mouse_out_provider", is_mouse_out_provider)
	mouse_board_position_provider = config.get("mouse_board_position_provider", mouse_board_position_provider)
	is_valid_position_callback = config.get("is_valid_position_callback", is_valid_position_callback)
	is_piece_owned_by_callback = config.get("is_piece_owned_by_callback", is_piece_owned_by_callback)
	can_attach_card_to_piece_callback = config.get("can_attach_card_to_piece_callback", can_attach_card_to_piece_callback)
	can_exchange_card_locally_callback = config.get("can_exchange_card_locally_callback", can_exchange_card_locally_callback)
	is_mouse_over_deck_callback = config.get("is_mouse_over_deck_callback", is_mouse_over_deck_callback)
	attach_card_visual_to_piece_callback = config.get("attach_card_visual_to_piece_callback", attach_card_visual_to_piece_callback)
	card_visuals_provider = config.get("card_visuals_provider", card_visuals_provider)
	card_hand_provider = config.get("card_hand_provider", card_hand_provider)
	card_home_position_provider = config.get("card_home_position_provider", card_home_position_provider)
	piece_holder_provider = config.get("piece_holder_provider", piece_holder_provider)
	card_visual_index_provider = config.get("card_visual_index_provider", card_visual_index_provider)
	tutorial_exchange_allowed_callback = config.get("tutorial_exchange_allowed_callback", tutorial_exchange_allowed_callback)
	send_card_exchange_callback = config.get("send_card_exchange_callback", send_card_exchange_callback)
	card_deck_provider = config.get("card_deck_provider", card_deck_provider)
	remove_card_from_hand_index_callback = config.get("remove_card_from_hand_index_callback", remove_card_from_hand_index_callback)
	complete_card_exchange_callback = config.get("complete_card_exchange_callback", complete_card_exchange_callback)

func connect_card_visual_signals(card_visual: CardVisual) -> void:
	if card_visual == null or !is_instance_valid(card_visual):
		return

	if !card_visual.drag_started.is_connected(on_card_drag_started):
		card_visual.drag_started.connect(on_card_drag_started)
	if !card_visual.drag_moved.is_connected(on_card_drag_moved):
		card_visual.drag_moved.connect(on_card_drag_moved)
	if !card_visual.drag_released.is_connected(on_card_drag_released):
		card_visual.drag_released.connect(on_card_drag_released)
	card_visual.mouse_entered.connect(on_hand_card_mouse_entered.bind(card_visual))
	card_visual.mouse_exited.connect(on_hand_card_mouse_exited.bind(card_visual))

func on_card_drag_started(card_visual: CardVisual) -> void:
	call_no_args(hide_hover_callback)
	if card_visual != null and is_instance_valid(card_visual):
		card_visual.set_drop_target_active(false)
	update_card_attach_target_feedback(INVALID_BOARD_POS)

func on_card_drag_moved(card_visual: CardVisual) -> void:
	var target_pos: Vector2 = get_card_drop_piece_position(card_visual)
	var can_drop_on_deck: bool = can_drop_card_on_deck(card_visual)
	if card_visual != null and is_instance_valid(card_visual):
		card_visual.set_drop_target_active(target_pos != INVALID_BOARD_POS or can_drop_on_deck)
	update_card_attach_target_feedback(target_pos)
	handle_card_reorder(card_visual)

func on_card_drag_released(card_visual: CardVisual) -> void:
	var target_pos: Vector2 = get_card_drop_piece_position(card_visual)
	update_card_attach_target_feedback(INVALID_BOARD_POS)
	if target_pos != INVALID_BOARD_POS:
		if attach_card_visual_to_piece_callback.is_valid():
			attach_card_visual_to_piece_callback.call(card_visual, target_pos)
	elif can_drop_card_on_deck(card_visual):
		exchange_card_visual_with_deck(card_visual)
	elif card_visual != null and is_instance_valid(card_visual):
		card_visual.fly_home()

func on_hand_card_mouse_entered(card_visual: CardVisual) -> void:
	if card_visual == null or !is_instance_valid(card_visual):
		return
	if card_visual.card == null or card_visual.face_down or card_visual.is_dragging:
		return
	if show_hover_card_description_callback.is_valid():
		show_hover_card_description_callback.call(card_visual.card)

func on_hand_card_mouse_exited(_card_visual: CardVisual) -> void:
	call_no_args(hide_hover_callback)

func get_card_drop_piece_position(card_visual: CardVisual) -> Vector2:
	if card_visual == null or !is_instance_valid(card_visual):
		return INVALID_BOARD_POS
	if !get_bool(can_control_current_turn_provider, false):
		return INVALID_BOARD_POS
	if card_visual.owner_color != get_int(controllable_color_provider, 0):
		return INVALID_BOARD_POS
	if get_bool(is_mouse_out_provider, true):
		return INVALID_BOARD_POS

	var board_pos: Vector2 = get_vector2(mouse_board_position_provider, INVALID_BOARD_POS)
	var card_name: String = card_visual.card.card_name if card_visual.card else ""
	if is_valid_position(board_pos) and is_piece_owned_by(board_pos, card_visual.owner_color) and can_attach_card_to_piece(board_pos, card_name, card_visual.owner_color):
		return board_pos

	return INVALID_BOARD_POS

func can_drop_card_on_deck(card_visual: CardVisual) -> bool:
	return false

func exchange_card_visual_with_deck(card_visual: CardVisual) -> void:
	if card_visual == null or !is_instance_valid(card_visual) or card_visual.card == null:
		return

	var owner_color: int = card_visual.owner_color
	if !can_exchange_card_locally(owner_color):
		card_visual.fly_home()
		return

	var hand_index: int = get_card_visual_index(card_visual)
	if hand_index < 0:
		card_visual.fly_home()
		return

	var card_name: String = card_visual.card.card_name
	if !is_tutorial_exchange_allowed(owner_color, card_name, hand_index, true):
		card_visual.fly_home()
		return

	if GameController.current_game_host:
		if send_card_exchange(owner_color, card_name, hand_index):
			complete_card_exchange(owner_color, card_name, hand_index, false)
		if is_instance_valid(card_visual):
			card_visual.fly_home()
		return

	var deck: Array = get_card_deck(owner_color)
	if deck.is_empty():
		card_visual.fly_home()
		return

	var replacement_card_name: String = draw_exchange_replacement_card_name(deck, card_name)
	if replacement_card_name.is_empty():
		card_visual.fly_home()
		return

	var return_source_position: Vector2 = card_visual.global_position
	remove_card_from_hand_index(owner_color, hand_index, true, replacement_card_name)
	DeckManager.return_card_to_deck(deck, card_name)
	complete_card_exchange(owner_color, card_name, hand_index, true, return_source_position)
	if is_instance_valid(card_visual):
		card_visual.assign_and_hide()
		card_visual.queue_free()

func draw_exchange_replacement_card_name(deck: Array, returned_card_name: String) -> String:
	return draw_card_from_deck_avoiding_names(deck, [returned_card_name])

func draw_card_from_deck_avoiding_names(deck: Array, avoided_card_names: Array) -> String:
	if deck.is_empty():
		return ""

	var draw_index: int = -1
	for i in deck.size():
		var candidate_name: String = str(deck[i])
		if !avoided_card_names.has(candidate_name):
			draw_index = i
			break
	if draw_index == -1:
		draw_index = 0

	var drawn_card_name: String = str(deck[draw_index])
	deck.remove_at(draw_index)
	return drawn_card_name

func update_card_attach_target_feedback(target_pos: Vector2) -> void:
	if target_pos == card_attach_target_position:
		return

	clear_card_attach_target_feedback()
	if target_pos == INVALID_BOARD_POS or !is_valid_position(target_pos):
		return

	card_attach_target_position = target_pos
	card_attach_target_marker = create_card_attach_target_marker(target_pos)
	start_card_attach_target_piece_wiggle(target_pos)

func create_card_attach_target_marker(target_pos: Vector2) -> Node2D:
	if board_markers_node == null or !is_instance_valid(board_markers_node) or geometry == null:
		return null

	var marker_group := Node2D.new()
	marker_group.name = "CardAttachTargetMarker"
	marker_group.z_index = 0
	var marker := Polygon2D.new()
	marker.name = "Fill"
	marker.color = card_attach_target_fill_color
	marker.polygon = geometry.get_cell_polygon_local(target_pos, card_attach_target_fill_inset)
	if visuals != null:
		visuals.enable_canvas_item_antialiasing(marker)
	marker_group.add_child(marker)
	board_markers_node.add_child(marker_group)
	return marker_group

func start_card_attach_target_piece_wiggle(target_pos: Vector2) -> void:
	var holder: Sprite2D = get_piece_holder_at(target_pos)
	if holder == null or !is_instance_valid(holder):
		return
	if tween_owner == null or !is_instance_valid(tween_owner):
		return

	card_attach_target_piece = holder
	card_attach_target_piece_base_position = holder.position
	card_attach_target_piece_base_rotation = holder.rotation
	var lift: Vector2 = Vector2(0.0, -card_attach_target_wiggle_rise)
	var tilt: float = deg_to_rad(card_attach_target_wiggle_rotation_degrees)
	card_attach_target_piece_tween = tween_owner.create_tween().set_loops().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	card_attach_target_piece_tween.tween_property(holder, "position", card_attach_target_piece_base_position + lift, card_attach_target_wiggle_step_duration)
	card_attach_target_piece_tween.parallel().tween_property(holder, "rotation", card_attach_target_piece_base_rotation + tilt, card_attach_target_wiggle_step_duration)
	card_attach_target_piece_tween.tween_property(holder, "position", card_attach_target_piece_base_position, card_attach_target_wiggle_step_duration)
	card_attach_target_piece_tween.parallel().tween_property(holder, "rotation", card_attach_target_piece_base_rotation - tilt, card_attach_target_wiggle_step_duration)
	card_attach_target_piece_tween.tween_property(holder, "position", card_attach_target_piece_base_position + lift * 0.55, card_attach_target_wiggle_step_duration)
	card_attach_target_piece_tween.parallel().tween_property(holder, "rotation", card_attach_target_piece_base_rotation, card_attach_target_wiggle_step_duration)
	card_attach_target_piece_tween.tween_property(holder, "position", card_attach_target_piece_base_position, card_attach_target_wiggle_step_duration)

func clear_card_attach_target_feedback() -> void:
	if card_attach_target_marker != null and is_instance_valid(card_attach_target_marker):
		card_attach_target_marker.queue_free()
	card_attach_target_marker = null
	card_attach_target_position = INVALID_BOARD_POS

	if card_attach_target_piece_tween != null and card_attach_target_piece_tween.is_running():
		card_attach_target_piece_tween.kill()
	card_attach_target_piece_tween = null
	if card_attach_target_piece != null and is_instance_valid(card_attach_target_piece):
		card_attach_target_piece.position = card_attach_target_piece_base_position
		card_attach_target_piece.rotation = card_attach_target_piece_base_rotation
	card_attach_target_piece = null

func handle_card_reorder(card_visual: CardVisual) -> void:
	if card_visual == null or !is_instance_valid(card_visual):
		return
	handle_card_reorder_in_hand(card_visual, get_card_visuals(card_visual.owner_color), get_card_hand(card_visual.owner_color))

func handle_card_reorder_in_hand(card_visual: CardVisual, visuals_array: Array, cards_array: Array) -> void:
	var visuals: Array[CardVisual] = []
	for visual_value in visuals_array:
		if visual_value is CardVisual:
			visuals.append(visual_value)
	var cards: Array[Card] = []
	for card_value in cards_array:
		if card_value is Card:
			cards.append(card_value)

	var card_index: int = visuals.find(card_visual)
	if card_index == -1:
		return

	var hand_node: Control = card_visual.get_parent() as Control
	if hand_node == null:
		return

	var mouse_pos: Vector2 = hand_node.get_local_mouse_position()
	var swap_index: int = -1
	var left_index: int = card_index - 1
	var right_index: int = card_index + 1

	if left_index >= 0:
		var left_midpoint: float = (get_card_home_position(left_index).x + get_card_home_position(card_index).x) * 0.5
		if mouse_pos.x < left_midpoint:
			swap_index = left_index
	if swap_index == -1 and right_index < visuals.size():
		var right_midpoint: float = (get_card_home_position(right_index).x + get_card_home_position(card_index).x) * 0.5
		if mouse_pos.x > right_midpoint:
			swap_index = right_index

	if swap_index == -1:
		return

	var visual_temp: CardVisual = visuals_array[card_index]
	visuals_array[card_index] = visuals_array[swap_index]
	visuals_array[swap_index] = visual_temp

	var card_temp: Card = cards_array[card_index]
	cards_array[card_index] = cards_array[swap_index]
	cards_array[swap_index] = card_temp

	arrange_card_visuals(visuals_array, true)

func arrange_card_visuals(visuals_array: Array, animate: bool) -> void:
	for i in visuals_array.size():
		var card_visual: CardVisual = visuals_array[i] as CardVisual
		if card_visual == null or !is_instance_valid(card_visual):
			continue
		card_visual.hand_index = i
		card_visual.set_home_position(get_card_home_position(i), animate)

func get_card_visuals(owner_color: int) -> Array:
	if card_visuals_provider.is_valid():
		var value = card_visuals_provider.call(owner_color)
		if value is Array:
			return value
	return []

func get_card_hand(owner_color: int) -> Array:
	if card_hand_provider.is_valid():
		var value = card_hand_provider.call(owner_color)
		if value is Array:
			return value
	return []

func get_card_home_position(index: int) -> Vector2:
	if card_home_position_provider.is_valid():
		var value = card_home_position_provider.call(index)
		if value is Vector2:
			return value
	return Vector2.ZERO

func get_piece_holder_at(board_pos: Vector2) -> Sprite2D:
	if piece_holder_provider.is_valid():
		var value = piece_holder_provider.call(board_pos)
		if value is Sprite2D:
			return value
	return null

func get_card_visual_index(card_visual: CardVisual) -> int:
	if card_visual_index_provider.is_valid():
		return int(card_visual_index_provider.call(card_visual))
	return -1

func is_tutorial_exchange_allowed(owner_color: int, card_name: String, hand_index: int, emit_rejection: bool) -> bool:
	if tutorial_exchange_allowed_callback.is_valid():
		return bool(tutorial_exchange_allowed_callback.call(owner_color, card_name, hand_index, emit_rejection))
	return true

func send_card_exchange(owner_color: int, card_name: String, hand_index: int) -> bool:
	if send_card_exchange_callback.is_valid():
		return bool(send_card_exchange_callback.call(owner_color, card_name, hand_index))
	return false

func get_card_deck(owner_color: int) -> Array:
	if card_deck_provider.is_valid():
		var value = card_deck_provider.call(owner_color)
		if value is Array:
			return value
	return []

func remove_card_from_hand_index(owner_color: int, hand_index: int, should_draw_replacement: bool, replacement_card_name: String) -> void:
	if remove_card_from_hand_index_callback.is_valid():
		remove_card_from_hand_index_callback.call(owner_color, hand_index, should_draw_replacement, replacement_card_name)

func complete_card_exchange(owner_color: int, card_name: String, hand_index: int, should_record_name: bool, source_global_position = null) -> void:
	if complete_card_exchange_callback.is_valid():
		complete_card_exchange_callback.call(owner_color, card_name, hand_index, should_record_name, source_global_position)

func is_valid_position(board_pos: Vector2) -> bool:
	return bool(is_valid_position_callback.call(board_pos)) if is_valid_position_callback.is_valid() else false

func is_piece_owned_by(board_pos: Vector2, owner_color: int) -> bool:
	return bool(is_piece_owned_by_callback.call(board_pos, owner_color)) if is_piece_owned_by_callback.is_valid() else false

func can_attach_card_to_piece(board_pos: Vector2, card_name: String, owner_color: int) -> bool:
	return bool(can_attach_card_to_piece_callback.call(board_pos, card_name, owner_color)) if can_attach_card_to_piece_callback.is_valid() else false

func can_exchange_card_locally(owner_color: int) -> bool:
	return bool(can_exchange_card_locally_callback.call(owner_color)) if can_exchange_card_locally_callback.is_valid() else false

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
