extends RefCounted

const INVALID_BOARD_POS = Vector2(-1, -1)

var canvas_layer: CanvasLayer
var tween_owner: Node
var card_visual_scene: PackedScene
var card_ui_size: Vector2 = Vector2(168.7, 229)
var card_burn_sequence_gap: float = 0.08
var return_to_deck_start_scale: float = 0.555
var return_to_deck_end_scale: float = 0.324
var return_to_deck_duration: float = 0.62

var color_for_player_provider: Callable
var player_id_for_color_provider: Callable
var local_view_color_provider: Callable
var is_valid_position_callback: Callable
var board_screen_position_provider: Callable
var card_draw_start_position_provider: Callable
var card_return_to_deck_target_position_provider: Callable
var card_hand_source_position_provider: Callable
var deck_visual_provider: Callable
var viewport_size_provider: Callable
var value_to_vector2_provider: Callable
var card_visuals_provider: Callable

var pending_card_burn_animations: Array = []
var card_burn_animation_sequence_running: bool = false

func configure(config: Dictionary) -> void:
	canvas_layer = config.get("canvas_layer", canvas_layer)
	tween_owner = config.get("tween_owner", tween_owner)
	card_visual_scene = config.get("card_visual_scene", card_visual_scene)
	card_ui_size = config.get("card_ui_size", card_ui_size)
	card_burn_sequence_gap = float(config.get("card_burn_sequence_gap", card_burn_sequence_gap))
	return_to_deck_start_scale = float(config.get("return_to_deck_start_scale", return_to_deck_start_scale))
	return_to_deck_end_scale = float(config.get("return_to_deck_end_scale", return_to_deck_end_scale))
	return_to_deck_duration = float(config.get("return_to_deck_duration", return_to_deck_duration))
	color_for_player_provider = config.get("color_for_player_provider", color_for_player_provider)
	player_id_for_color_provider = config.get("player_id_for_color_provider", player_id_for_color_provider)
	local_view_color_provider = config.get("local_view_color_provider", local_view_color_provider)
	is_valid_position_callback = config.get("is_valid_position_callback", is_valid_position_callback)
	board_screen_position_provider = config.get("board_screen_position_provider", board_screen_position_provider)
	card_draw_start_position_provider = config.get("card_draw_start_position_provider", card_draw_start_position_provider)
	card_return_to_deck_target_position_provider = config.get("card_return_to_deck_target_position_provider", card_return_to_deck_target_position_provider)
	card_hand_source_position_provider = config.get("card_hand_source_position_provider", card_hand_source_position_provider)
	deck_visual_provider = config.get("deck_visual_provider", deck_visual_provider)
	viewport_size_provider = config.get("viewport_size_provider", viewport_size_provider)
	value_to_vector2_provider = config.get("value_to_vector2_provider", value_to_vector2_provider)
	card_visuals_provider = config.get("card_visuals_provider", card_visuals_provider)

func has_pending_animations() -> bool:
	return card_burn_animation_sequence_running or !pending_card_burn_animations.is_empty()

func animate_card_draw(owner_color: int, card_visual: CardVisual) -> void:
	if card_visual == null or !is_instance_valid(card_visual):
		return

	var deck_visual: CardVisual = get_deck_visual(owner_color)
	if deck_visual and is_instance_valid(deck_visual):
		deck_visual.play_draw_pulse()
	card_visual.fly_from_global_position(get_card_draw_start_position(owner_color))

func animate_state_draw_if_needed(owner_color: int, previous_names: Array, current_names: Array) -> void:
	if previous_names.is_empty() or arrays_match(previous_names, current_names):
		return
	if current_names.size() < previous_names.size():
		return

	var visuals: Array[CardVisual] = get_card_visuals(owner_color)
	if visuals.is_empty():
		return

	animate_card_draw(owner_color, visuals[visuals.size() - 1])

func animate_recent_card_transfers(recent_card_transfers: Array, previous_white_names: Array, current_white_names: Array, previous_black_names: Array, current_black_names: Array) -> void:
	var used_indices_by_owner: Dictionary = {
		1: [],
		-1: [],
	}

	for transfer_value in recent_card_transfers:
		if !(transfer_value is Dictionary):
			continue

		var transfer: Dictionary = transfer_value
		var target_zone: String = str(transfer.get("target_zone", ""))
		if target_zone == "deleted":
			play_transfer_source_pulse(transfer)
			queue_card_transfer_burn_animation(transfer)
			continue
		if target_zone == "deck" and str(transfer.get("source_zone", "")) == "piece":
			queue_card_return_to_deck_animation(transfer)
			continue
		if target_zone != "hand":
			continue

		var target_player_id: int = int(transfer.get("target_player_id", -1))
		if target_player_id < 0:
			continue

		var owner_color: int = get_color_for_player_id(target_player_id)
		var card_name: String = str(transfer.get("card_name", ""))
		if card_name.is_empty():
			continue

		var previous_names: Array = previous_white_names if owner_color == 1 else previous_black_names
		var current_names: Array = current_white_names if owner_color == 1 else current_black_names
		var used_indices: Array = used_indices_by_owner.get(owner_color, [])
		var target_visual: CardVisual = find_transfer_target_visual(owner_color, previous_names, current_names, card_name, used_indices)
		if target_visual == null:
			continue

		used_indices_by_owner[owner_color] = used_indices
		play_transfer_source_pulse(transfer)
		target_visual.fly_from_global_position(get_card_transfer_source_position(transfer))

func find_transfer_target_visual(owner_color: int, previous_names: Array, current_names: Array, card_name: String, used_indices: Array) -> CardVisual:
	var visuals: Array[CardVisual] = get_card_visuals(owner_color)
	if visuals.is_empty():
		return null

	var previous_count: int = count_card_name(previous_names, card_name)
	var seen_count: int = 0
	for index in range(current_names.size()):
		if str(current_names[index]) != card_name:
			continue
		seen_count += 1
		if seen_count <= previous_count:
			continue
		if used_indices.has(index) or index >= visuals.size():
			continue
		used_indices.append(index)
		return visuals[index]

	var last_index: int = mini(current_names.size(), visuals.size()) - 1
	for index in range(last_index, -1, -1):
		if used_indices.has(index):
			continue
		if str(current_names[index]) == card_name:
			used_indices.append(index)
			return visuals[index]

	return null

func animate_recent_card_expirations(recent_card_expirations: Array) -> void:
	for expiration_value in recent_card_expirations:
		if !(expiration_value is Dictionary):
			continue

		var expiration: Dictionary = expiration_value
		var card_name: String = str(expiration.get("card_name", ""))
		if card_name.is_empty():
			continue

		var piece_pos: Vector2 = value_to_vector2(expiration.get("piece_pos", INVALID_BOARD_POS), INVALID_BOARD_POS)
		if !is_valid_position(piece_pos):
			continue

		var expired_card: Card = CardLibrary.duplicate_card(card_name)
		if expired_card == null:
			continue
		if MoveRules.is_seeker_card(expired_card):
			continue
		if expired_card.effect_type == CardEffect.TYPE_GIVE_CARD && expired_card.effect_trigger == CardEffect.TRIGGER_ON_EXPIRE:
			continue

		queue_card_expire_animation(piece_pos, expired_card)

func arrays_match(left: Array, right: Array) -> bool:
	if left.size() != right.size():
		return false
	for i in left.size():
		if str(left[i]) != str(right[i]):
			return false
	return true

func count_card_name(card_names: Array, card_name: String) -> int:
	var count: int = 0
	for card_name_value in card_names:
		if str(card_name_value) == card_name:
			count += 1
	return count

func queue_card_transfer_burn_animation(transfer: Dictionary) -> void:
	pending_card_burn_animations.append({
		"type": "transfer",
		"transfer": transfer.duplicate(true),
	})
	process_card_burn_animation_queue()

func queue_card_return_to_deck_animation(transfer: Dictionary) -> void:
	pending_card_burn_animations.append({
		"type": "return_to_deck",
		"transfer": transfer.duplicate(true),
	})
	process_card_burn_animation_queue()

func queue_seeker_card_return_to_deck_animation(owner_color: int, card: Card, piece_pos: Vector2) -> void:
	if card == null:
		return

	var owner_player_id: int = get_player_id_for_color(owner_color)
	queue_card_return_to_deck_animation({
		"source_player_id": owner_player_id,
		"target_player_id": owner_player_id,
		"card_name": card.card_name,
		"source_zone": "piece",
		"target_zone": "deck",
		"source_pos": [piece_pos.x, piece_pos.y],
	})

func queue_card_expire_animation(piece_position: Vector2, expired_card: Card) -> void:
	if expired_card == null:
		return

	var queued_card: Card = expired_card.duplicate() as Card
	if queued_card == null:
		queued_card = expired_card
	pending_card_burn_animations.append({
		"type": "expire",
		"piece_position": piece_position,
		"expired_card": queued_card,
	})
	process_card_burn_animation_queue()

func process_card_burn_animation_queue() -> void:
	if card_burn_animation_sequence_running:
		return

	card_burn_animation_sequence_running = true
	while !pending_card_burn_animations.is_empty():
		var animation_data: Dictionary = pending_card_burn_animations.pop_front()
		var card_visual: CardVisual = null
		var animation_type: String = str(animation_data.get("type", ""))
		if animation_type == "transfer":
			card_visual = play_card_transfer_burn_animation(animation_data.get("transfer", {}))
		elif animation_type == "return_to_deck":
			card_visual = play_card_return_to_deck_animation(animation_data.get("transfer", {}))
		elif animation_type == "expire":
			var piece_position: Vector2 = value_to_vector2(animation_data.get("piece_position", INVALID_BOARD_POS), INVALID_BOARD_POS)
			var expired_card: Card = animation_data.get("expired_card", null) as Card
			card_visual = play_card_expire_animation(piece_position, expired_card)
		if card_visual != null and is_instance_valid(card_visual):
			await card_visual.burn_finished
		if !pending_card_burn_animations.is_empty() and tween_owner != null and is_instance_valid(tween_owner) and tween_owner.get_tree() != null:
			await tween_owner.get_tree().create_timer(card_burn_sequence_gap).timeout

	card_burn_animation_sequence_running = false

func play_card_transfer_burn_animation(transfer: Dictionary) -> CardVisual:
	if canvas_layer == null or card_visual_scene == null:
		return null

	var card_name: String = str(transfer.get("card_name", ""))
	var card: Card = CardLibrary.duplicate_card(card_name)
	if card == null:
		return null

	var card_visual: CardVisual = card_visual_scene.instantiate() as CardVisual
	canvas_layer.add_child(card_visual)
	card_visual.set_card(card)
	card_visual.set_face_down(false)
	card_visual.draggable = false
	card_visual.disabled = true
	card_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var animation_scale: float = 0.74
	var source_position: Vector2 = get_card_transfer_source_position(transfer)
	var visual_size: Vector2 = card_ui_size * animation_scale
	card_visual.global_position = source_position - visual_size * 0.5
	card_visual.scale = Vector2.ONE * animation_scale
	card_visual.rotation = deg_to_rad(randf_range(-4.0, 4.0))
	card_visual.z_index = 980
	card_visual.play_burn_away_and_free()
	return card_visual

func play_card_expire_animation(piece_position: Vector2, expired_card: Card) -> CardVisual:
	if expired_card == null or canvas_layer == null or card_visual_scene == null or !is_valid_position(piece_position):
		return null

	var display_card: Card = expired_card.duplicate() as Card
	if display_card == null:
		display_card = expired_card
	display_card.duration = 0

	var card_visual: CardVisual = card_visual_scene.instantiate() as CardVisual
	canvas_layer.add_child(card_visual)
	card_visual.set_card(display_card)
	card_visual.set_face_down(false)
	card_visual.draggable = false
	card_visual.disabled = true
	card_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var animation_scale: float = 0.74 * 0.75
	var piece_screen_position: Vector2 = get_board_position_screen_position(piece_position)
	var visual_size: Vector2 = card_ui_size * animation_scale
	card_visual.global_position = piece_screen_position - visual_size * 0.5 + Vector2(0.0, -visual_size.y * 0.72)
	card_visual.scale = Vector2.ONE * animation_scale
	card_visual.rotation = deg_to_rad(randf_range(-4.0, 4.0))
	card_visual.z_index = 980
	card_visual.play_burn_away_and_free()
	return card_visual

func play_card_return_to_deck_animation(transfer: Dictionary) -> CardVisual:
	if canvas_layer == null or card_visual_scene == null:
		return null

	var card_name: String = str(transfer.get("card_name", ""))
	var card: Card = CardLibrary.duplicate_card(card_name)
	if card == null:
		return null

	var target_player_id: int = int(transfer.get("target_player_id", transfer.get("source_player_id", -1)))
	var owner_color: int = get_color_for_player_id(target_player_id) if target_player_id >= 0 else get_local_view_color()
	var animation_scale: float = return_to_deck_start_scale
	var visual_size: Vector2 = card_ui_size * animation_scale
	var source_position: Vector2 = get_card_transfer_source_position(transfer)

	var card_visual: CardVisual = card_visual_scene.instantiate() as CardVisual
	canvas_layer.add_child(card_visual)
	card_visual.set_card(card)
	card_visual.set_face_down(false)
	card_visual.draggable = false
	card_visual.disabled = true
	card_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_visual.global_position = source_position - visual_size * 0.5 + Vector2(0.0, -visual_size.y * 0.72)
	card_visual.scale = Vector2.ONE * animation_scale
	card_visual.rotation = deg_to_rad(randf_range(-4.0, 4.0))
	card_visual.z_index = 980

	var target_scale: Vector2 = Vector2.ONE * return_to_deck_end_scale
	var target_position: Vector2 = get_card_return_to_deck_target_position(owner_color, return_to_deck_end_scale)
	var deck_visual: CardVisual = get_deck_visual(owner_color)
	if deck_visual != null and is_instance_valid(deck_visual):
		card_visual.burn_finished.connect(func(_finished_card):
			if deck_visual != null and is_instance_valid(deck_visual):
				deck_visual.play_draw_pulse()
		)
	card_visual.play_return_to_deck_and_free(target_position, target_scale, return_to_deck_duration)
	return card_visual

func play_transfer_source_pulse(transfer: Dictionary) -> void:
	var source_zone: String = str(transfer.get("source_zone", ""))
	if source_zone != "deck" and source_zone != "enemy_deck":
		return

	var source_player_id: int = int(transfer.get("source_player_id", -1))
	if source_player_id < 0:
		return

	var deck_visual: CardVisual = get_deck_visual(get_color_for_player_id(source_player_id))
	if deck_visual != null and is_instance_valid(deck_visual):
		deck_visual.play_draw_pulse()

func get_card_transfer_source_position(transfer: Dictionary) -> Vector2:
	if transfer.has("source_global_position"):
		var provided_source_position: Vector2 = value_to_vector2(transfer.get("source_global_position"), INVALID_BOARD_POS)
		if provided_source_position != INVALID_BOARD_POS:
			return provided_source_position

	var source_player_id: int = int(transfer.get("source_player_id", -1))
	var source_color: int = get_color_for_player_id(source_player_id) if source_player_id >= 0 else get_local_view_color()
	var source_zone: String = str(transfer.get("source_zone", ""))
	var source_pos: Vector2 = value_to_vector2(transfer.get("source_pos", INVALID_BOARD_POS), INVALID_BOARD_POS)

	if source_zone == "piece":
		if is_valid_position(source_pos):
			return get_board_position_screen_position(source_pos)
		return get_card_hand_source_position(source_color)

	if source_zone == "deck" or source_zone == "enemy_deck":
		return get_card_draw_start_position(source_color)

	if source_zone == "hand" or source_zone == "enemy_hand":
		return get_card_hand_source_position(source_color)

	if source_zone == "effect" and is_valid_position(source_pos):
		return get_board_position_screen_position(source_pos)

	return get_viewport_size() * 0.5

func get_color_for_player_id(player_id: int) -> int:
	if color_for_player_provider.is_valid():
		return int(color_for_player_provider.call(player_id))
	return 1 if player_id == 0 else -1

func get_player_id_for_color(owner_color: int) -> int:
	if player_id_for_color_provider.is_valid():
		return int(player_id_for_color_provider.call(owner_color))
	return 0 if owner_color == 1 else 1

func get_local_view_color() -> int:
	if local_view_color_provider.is_valid():
		return int(local_view_color_provider.call())
	return 1

func is_valid_position(pos: Vector2) -> bool:
	return bool(is_valid_position_callback.call(pos)) if is_valid_position_callback.is_valid() else false

func get_board_position_screen_position(board_pos: Vector2) -> Vector2:
	if board_screen_position_provider.is_valid():
		var value = board_screen_position_provider.call(board_pos)
		if value is Vector2:
			return value
	return Vector2.ZERO

func get_card_draw_start_position(owner_color: int) -> Vector2:
	if card_draw_start_position_provider.is_valid():
		var value = card_draw_start_position_provider.call(owner_color)
		if value is Vector2:
			return value
	return Vector2.ZERO

func get_card_return_to_deck_target_position(owner_color: int, target_scale: float) -> Vector2:
	if card_return_to_deck_target_position_provider.is_valid():
		var value = card_return_to_deck_target_position_provider.call(owner_color, target_scale)
		if value is Vector2:
			return value
	return get_card_draw_start_position(owner_color)

func get_card_hand_source_position(owner_color: int) -> Vector2:
	if card_hand_source_position_provider.is_valid():
		var value = card_hand_source_position_provider.call(owner_color)
		if value is Vector2:
			return value
	return get_viewport_size() * 0.5

func get_deck_visual(owner_color: int) -> CardVisual:
	if deck_visual_provider.is_valid():
		var value = deck_visual_provider.call(owner_color)
		if value is CardVisual:
			return value
	return null

func get_card_visuals(owner_color: int) -> Array[CardVisual]:
	var typed_visuals: Array[CardVisual] = []
	if card_visuals_provider.is_valid():
		var value = card_visuals_provider.call(owner_color)
		if value is Array:
			for visual_value in value:
				if visual_value is CardVisual:
					typed_visuals.append(visual_value)
	return typed_visuals

func get_viewport_size() -> Vector2:
	if viewport_size_provider.is_valid():
		var value = viewport_size_provider.call()
		if value is Vector2:
			return value
	return Vector2.ZERO

func value_to_vector2(value, fallback: Vector2) -> Vector2:
	if value_to_vector2_provider.is_valid():
		var provided_value = value_to_vector2_provider.call(value, fallback)
		if provided_value is Vector2:
			return provided_value
	if value is Vector2:
		return value
	if value is Vector2i:
		var vector_value: Vector2i = value
		return Vector2(vector_value.x, vector_value.y)
	if value is Array:
		var array_value: Array = value
		if array_value.size() >= 2:
			return Vector2(float(array_value[0]), float(array_value[1]))
	if value is Dictionary:
		var dict_value: Dictionary = value
		if dict_value.has("x") and dict_value.has("y"):
			return Vector2(float(dict_value.x), float(dict_value.y))
	return fallback
