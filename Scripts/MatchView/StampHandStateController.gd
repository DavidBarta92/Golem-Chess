extends RefCounted

var match_board
var stamp_visual_scene: PackedScene
var stamp_ui_size: Vector2 = Vector2(168.7, 229)
var stamp_hand_scale: float = 0.648

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	stamp_visual_scene = config.get("stamp_visual_scene", stamp_visual_scene)
	stamp_ui_size = config.get("stamp_ui_size", stamp_ui_size)
	stamp_hand_scale = float(config.get("stamp_hand_scale", stamp_hand_scale))

func setup_player_stamp_hands() -> void:
	match_board.white_stamp_deck = DeckManager.create_starting_deck()
	match_board.black_stamp_deck = DeckManager.create_starting_deck()
	match_board.set_codex_pages(1, DeckManager.create_codex_pages(match_board.white_stamp_deck))
	match_board.set_codex_pages(-1, DeckManager.create_codex_pages(match_board.black_stamp_deck))
	match_board.set_codex_page_index(1, 0)
	match_board.set_codex_page_index(-1, 0)
	match_board.white_stamp_hand = create_stamp_hand_from_names(match_board.white_codex_pages[0])
	match_board.black_stamp_hand = create_stamp_hand_from_names(match_board.black_codex_pages[0])

	match_board.white_stamp_visuals = populate_stamp_hand(match_board.white_pieces, match_board.white_stamp_hand, 1)
	match_board.black_stamp_visuals = populate_stamp_hand(match_board.black_pieces, match_board.black_stamp_hand, -1)
	setup_deck_visuals()
	update_stamp_presentation()

func draw_starting_stamps_from_deck(owner_color: int) -> Array[Stamp]:
	var hand_names: Array[String] = []
	var deck: Array[String] = get_stamp_deck(owner_color)
	DeckManager.draw_starting_hand(deck, hand_names)
	return create_stamp_hand_from_names(hand_names)

func create_stamp_hand_from_names(stamp_names: Array) -> Array[Stamp]:
	var hand: Array[Stamp] = []
	for stamp_name_value in stamp_names:
		var stamp_name: String = str(stamp_name_value)
		var stamp: Stamp = StampLibrary.duplicate_stamp(stamp_name)
		if stamp:
			hand.append(stamp)
	return hand

func populate_stamp_hand(hand_node: Control, stamps: Array[Stamp], owner_color: int) -> Array[StampVisual]:
	return match_board.get_stamp_hud_controller().populate_stamp_hand(hand_node, stamps, owner_color, Callable(match_board.get_stamp_interaction_controller(), "connect_stamp_visual_signals"))

func setup_deck_visuals() -> void:
	match_board.get_stamp_hud_controller().free_existing_deck_visual(match_board.white_deck_visual)
	match_board.get_stamp_hud_controller().free_existing_deck_visual(match_board.black_deck_visual)
	match_board.white_deck_visual = null
	match_board.black_deck_visual = null

func get_stamp_home_position(index: int) -> Vector2:
	return match_board.get_stamp_hud_controller().get_stamp_home_position(index)

func get_stamp_hand(owner_color: int) -> Array[Stamp]:
	return match_board.white_stamp_hand if owner_color == 1 else match_board.black_stamp_hand

func get_stamp_visuals(owner_color: int) -> Array[StampVisual]:
	return match_board.white_stamp_visuals if owner_color == 1 else match_board.black_stamp_visuals

func get_stamp_deck(owner_color: int) -> Array[String]:
	return match_board.white_stamp_deck if owner_color == 1 else match_board.black_stamp_deck

func get_stamp_deck_count(owner_color: int) -> int:
	if owner_color == 1:
		return match_board.white_deck_count_override if match_board.white_deck_count_override >= 0 else get_codex_remaining_count(owner_color)
	return match_board.black_deck_count_override if match_board.black_deck_count_override >= 0 else get_codex_remaining_count(owner_color)

func get_codex_remaining_count(owner_color: int) -> int:
	var total: int = 0
	for page_count in match_board.get_codex_page_counts(owner_color):
		total += int(page_count)
	return total

func get_stamp_hand_node(owner_color: int) -> Control:
	return match_board.white_pieces if owner_color == 1 else match_board.black_pieces

func get_deck_visual(owner_color: int) -> StampVisual:
	return match_board.white_deck_visual if owner_color == 1 else match_board.black_deck_visual

func get_stamp_draw_start_position(owner_color: int) -> Vector2:
	var deck_visual: StampVisual = get_deck_visual(owner_color)
	if deck_visual and is_instance_valid(deck_visual):
		return deck_visual.global_position
	if match_board.codex_panel != null and is_instance_valid(match_board.codex_panel):
		return match_board.codex_panel.get_global_rect().get_center()

	var hand_node: Control = get_stamp_hand_node(owner_color)
	return hand_node.global_position + match_board.get_stamp_hud_controller().get_deck_home_position()

func get_stamp_return_to_deck_target_position(owner_color: int, target_scale: float) -> Vector2:
	var target_size: Vector2 = stamp_ui_size * target_scale
	var deck_visual: StampVisual = get_deck_visual(owner_color)
	if deck_visual != null and is_instance_valid(deck_visual):
		return deck_visual.get_global_rect().get_center() - target_size * 0.5
	if match_board.codex_panel != null and is_instance_valid(match_board.codex_panel):
		return match_board.codex_panel.get_global_rect().get_center() - target_size * 0.5

	return get_stamp_draw_start_position(owner_color)

func update_stamp_presentation() -> void:
	var local_color: int = match_board.get_local_view_color()
	match_board.get_stamp_hud_controller().configure_hand_container(match_board.white_pieces, local_color != 1)
	match_board.get_stamp_hud_controller().configure_hand_container(match_board.black_pieces, local_color != -1)
	match_board.update_stamp_face_visibility(local_color)
	update_stamp_drag_permissions()
	match_board.get_turn_hud_controller().update_player_name_labels()
	match_board.get_turn_hud_controller().update_player_portrait_views()
	match_board.update_end_turn_button()
	match_board.get_turn_hud_controller().update_rules_info_ui()
	match_board.get_turn_hud_controller().update_action_status_ui()
	match_board.update_codex_ui()

func update_stamp_drag_permissions() -> void:
	var active_color: int = match_board.get_controllable_color()
	var can_drag: bool = match_board.can_control_current_turn()
	for stamp_visual in match_board.white_stamp_visuals:
		stamp_visual.draggable = can_drag_stamp_visual_now(stamp_visual, active_color, can_drag)
	for stamp_visual in match_board.black_stamp_visuals:
		stamp_visual.draggable = can_drag_stamp_visual_now(stamp_visual, active_color, can_drag)

func can_drag_stamp_visual_now(stamp_visual: StampVisual, active_color: int, can_drag: bool) -> bool:
	if !can_drag or stamp_visual == null or stamp_visual.owner_color != active_color:
		return false
	if stamp_visual.stamp == null:
		return false
	if !match_board.tutorial_constraints_enabled:
		return true

	var context: Dictionary = {
		"owner_color": stamp_visual.owner_color,
		"stamp_name": stamp_visual.stamp.stamp_name,
		"hand_index": match_board.get_stamp_visual_index(stamp_visual),
	}
	return match_board.is_tutorial_action_allowed(match_board.TUTORIAL_ACTION_ATTACH_STAMP, context)

func remove_stamp_from_hand(stamp_visual: StampVisual) -> String:
	return remove_stamp_from_hand_index(stamp_visual.owner_color, get_stamp_visual_index(stamp_visual), false)

func get_stamp_visual_index(stamp_visual: StampVisual) -> int:
	if stamp_visual.owner_color == 1:
		return match_board.white_stamp_visuals.find(stamp_visual)
	return match_board.black_stamp_visuals.find(stamp_visual)

func remove_stamp_from_hand_index(owner_color: int, hand_index: int, should_draw_replacement: bool = false, replacement_stamp_name: String = "") -> String:
	if hand_index == -1:
		return ""

	var visuals: Array[StampVisual] = get_stamp_visuals(owner_color)
	var stamps: Array[Stamp] = get_stamp_hand(owner_color)
	if hand_index < 0 or hand_index >= visuals.size() or hand_index >= stamps.size():
		return ""

	var removed_visual: StampVisual = visuals[hand_index]
	visuals.remove_at(hand_index)
	stamps.remove_at(hand_index)
	if !GameController.current_game_host:
		match_board.remove_local_codex_stamp(owner_color, hand_index)

	if removed_visual and is_instance_valid(removed_visual):
		removed_visual.assign_and_hide()
		removed_visual.queue_free()

	var drawn_stamp_name: String = ""
	if should_draw_replacement:
		drawn_stamp_name = replacement_stamp_name
		if !drawn_stamp_name.is_empty():
			insert_drawn_stamp(owner_color, hand_index, drawn_stamp_name)
		else:
			match_board.arrange_stamp_visuals(visuals, true)
	else:
		match_board.arrange_stamp_visuals(visuals, true)

	update_stamp_presentation()
	return drawn_stamp_name

func insert_drawn_stamp(owner_color: int, hand_index: int, stamp_name: String) -> void:
	var stamp: Stamp = StampLibrary.duplicate_stamp(stamp_name)
	if stamp == null:
		push_warning("Stamp not found for draw: %s" % stamp_name)
		return

	var visuals: Array[StampVisual] = get_stamp_visuals(owner_color)
	var stamps: Array[Stamp] = get_stamp_hand(owner_color)
	var hand_node: Control = get_stamp_hand_node(owner_color)
	var insert_index: int = clampi(hand_index, 0, stamps.size())
	stamps.insert(insert_index, stamp)

	var stamp_visual: StampVisual = stamp_visual_scene.instantiate() as StampVisual
	hand_node.add_child(stamp_visual)
	stamp_visual.set_rest_scale(Vector2.ONE * stamp_hand_scale)
	stamp_visual.set_hand_context(owner_color, insert_index, get_stamp_home_position(insert_index))
	stamp_visual.set_stamp(stamp)
	stamp_visual.set_face_down(owner_color != match_board.get_local_view_color())
	match_board.get_stamp_interaction_controller().connect_stamp_visual_signals(stamp_visual)
	visuals.insert(insert_index, stamp_visual)

	stamp_visual.global_position = get_stamp_draw_start_position(owner_color)
	stamp_visual.scale = Vector2.ONE * stamp_hand_scale
	match_board.arrange_stamp_visuals(visuals, true)
	match_board.get_stamp_animation_controller().animate_stamp_draw(owner_color, stamp_visual)

func draw_refill_stamp_name(owner_color: int) -> String:
	var deck: Array[String] = get_stamp_deck(owner_color)
	var protected_names: Array = match_board.exchanged_stamp_names_this_turn.get(owner_color, [])
	return draw_stamp_from_deck_avoiding_names(deck, protected_names)

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

func record_exchanged_stamp_name_this_turn(owner_color: int, stamp_name: String) -> void:
	var exchanged_names: Array = match_board.exchanged_stamp_names_this_turn.get(owner_color, [])
	exchanged_names.append(stamp_name)
	match_board.exchanged_stamp_names_this_turn[owner_color] = exchanged_names

func clear_exchanged_stamp_names_this_turn(owner_color: int) -> void:
	match_board.exchanged_stamp_names_this_turn[owner_color] = []
