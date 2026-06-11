extends RefCounted

var match_board
var card_visual_scene: PackedScene
var card_ui_size: Vector2 = Vector2(164, 229)
var card_hand_scale: float = 0.648

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	card_visual_scene = config.get("card_visual_scene", card_visual_scene)
	card_ui_size = config.get("card_ui_size", card_ui_size)
	card_hand_scale = float(config.get("card_hand_scale", card_hand_scale))

func setup_player_card_hands() -> void:
	match_board.white_card_deck = DeckManager.create_starting_deck()
	match_board.black_card_deck = DeckManager.create_starting_deck()
	match_board.white_card_hand = draw_starting_cards_from_deck(1)
	match_board.black_card_hand = draw_starting_cards_from_deck(-1)

	match_board.white_card_visuals = populate_card_hand(match_board.white_pieces, match_board.white_card_hand, 1)
	match_board.black_card_visuals = populate_card_hand(match_board.black_pieces, match_board.black_card_hand, -1)
	setup_deck_visuals()
	update_card_presentation()

func draw_starting_cards_from_deck(owner_color: int) -> Array[Card]:
	var hand_names: Array[String] = []
	var deck: Array[String] = get_card_deck(owner_color)
	DeckManager.draw_starting_hand(deck, hand_names)
	return create_card_hand_from_names(hand_names)

func create_card_hand_from_names(card_names: Array) -> Array[Card]:
	var hand: Array[Card] = []
	for card_name_value in card_names:
		var card_name: String = str(card_name_value)
		var card: Card = CardLibrary.duplicate_card(card_name)
		if card:
			hand.append(card)
	return hand

func populate_card_hand(hand_node: Control, cards: Array[Card], owner_color: int) -> Array[CardVisual]:
	return match_board.get_card_hud_controller().populate_card_hand(hand_node, cards, owner_color, Callable(match_board.get_card_interaction_controller(), "connect_card_visual_signals"))

func setup_deck_visuals() -> void:
	match_board.get_card_hud_controller().free_existing_deck_visual(match_board.white_deck_visual)
	match_board.get_card_hud_controller().free_existing_deck_visual(match_board.black_deck_visual)
	match_board.white_deck_visual = match_board.get_card_hud_controller().create_deck_visual(match_board.white_pieces, 1)
	match_board.black_deck_visual = match_board.get_card_hud_controller().create_deck_visual(match_board.black_pieces, -1)

func get_card_home_position(index: int) -> Vector2:
	return match_board.get_card_hud_controller().get_card_home_position(index)

func get_card_hand(owner_color: int) -> Array[Card]:
	return match_board.white_card_hand if owner_color == 1 else match_board.black_card_hand

func get_card_visuals(owner_color: int) -> Array[CardVisual]:
	return match_board.white_card_visuals if owner_color == 1 else match_board.black_card_visuals

func get_card_deck(owner_color: int) -> Array[String]:
	return match_board.white_card_deck if owner_color == 1 else match_board.black_card_deck

func get_card_deck_count(owner_color: int) -> int:
	if owner_color == 1:
		return match_board.white_deck_count_override if match_board.white_deck_count_override >= 0 else match_board.white_card_deck.size()
	return match_board.black_deck_count_override if match_board.black_deck_count_override >= 0 else match_board.black_card_deck.size()

func get_card_hand_node(owner_color: int) -> Control:
	return match_board.white_pieces if owner_color == 1 else match_board.black_pieces

func get_deck_visual(owner_color: int) -> CardVisual:
	return match_board.white_deck_visual if owner_color == 1 else match_board.black_deck_visual

func get_card_draw_start_position(owner_color: int) -> Vector2:
	var deck_visual: CardVisual = get_deck_visual(owner_color)
	if deck_visual and is_instance_valid(deck_visual):
		return deck_visual.global_position

	var hand_node: Control = get_card_hand_node(owner_color)
	return hand_node.global_position + match_board.get_card_hud_controller().get_deck_home_position()

func get_card_return_to_deck_target_position(owner_color: int, target_scale: float) -> Vector2:
	var target_size: Vector2 = card_ui_size * target_scale
	var deck_visual: CardVisual = get_deck_visual(owner_color)
	if deck_visual != null and is_instance_valid(deck_visual):
		return deck_visual.get_global_rect().get_center() - target_size * 0.5

	return get_card_draw_start_position(owner_color)

func update_card_presentation() -> void:
	var local_color: int = match_board.get_local_view_color()
	match_board.get_card_hud_controller().configure_hand_container(match_board.white_pieces, local_color != 1)
	match_board.get_card_hud_controller().configure_hand_container(match_board.black_pieces, local_color != -1)
	match_board.update_card_face_visibility(local_color)
	update_card_drag_permissions()
	match_board.get_turn_hud_controller().update_player_name_labels()
	match_board.get_turn_hud_controller().update_player_portrait_views()
	match_board.update_end_turn_button()
	match_board.get_turn_hud_controller().update_rules_info_ui()
	match_board.get_turn_hud_controller().update_action_status_ui()

func update_card_drag_permissions() -> void:
	var active_color: int = match_board.get_controllable_color()
	var can_drag: bool = match_board.can_control_current_turn()
	for card_visual in match_board.white_card_visuals:
		card_visual.draggable = can_drag_card_visual_now(card_visual, active_color, can_drag)
	for card_visual in match_board.black_card_visuals:
		card_visual.draggable = can_drag_card_visual_now(card_visual, active_color, can_drag)

func can_drag_card_visual_now(card_visual: CardVisual, active_color: int, can_drag: bool) -> bool:
	if !can_drag or card_visual == null or card_visual.owner_color != active_color:
		return false
	if card_visual.card == null:
		return false
	if !match_board.tutorial_constraints_enabled:
		return true

	var context: Dictionary = {
		"owner_color": card_visual.owner_color,
		"card_name": card_visual.card.card_name,
		"hand_index": match_board.get_card_visual_index(card_visual),
	}
	return match_board.is_tutorial_action_allowed(match_board.TUTORIAL_ACTION_ATTACH_CARD, context) or match_board.is_tutorial_action_allowed(match_board.TUTORIAL_ACTION_EXCHANGE_CARD, context)

func remove_card_from_hand(card_visual: CardVisual) -> String:
	return remove_card_from_hand_index(card_visual.owner_color, get_card_visual_index(card_visual), false)

func get_card_visual_index(card_visual: CardVisual) -> int:
	if card_visual.owner_color == 1:
		return match_board.white_card_visuals.find(card_visual)
	return match_board.black_card_visuals.find(card_visual)

func remove_card_from_hand_index(owner_color: int, hand_index: int, should_draw_replacement: bool = false, replacement_card_name: String = "") -> String:
	if hand_index == -1:
		return ""

	var visuals: Array[CardVisual] = get_card_visuals(owner_color)
	var cards: Array[Card] = get_card_hand(owner_color)
	if hand_index < 0 or hand_index >= visuals.size() or hand_index >= cards.size():
		return ""

	var removed_visual: CardVisual = visuals[hand_index]
	visuals.remove_at(hand_index)
	cards.remove_at(hand_index)

	if removed_visual and is_instance_valid(removed_visual):
		removed_visual.assign_and_hide()
		removed_visual.queue_free()

	var drawn_card_name: String = ""
	if should_draw_replacement:
		drawn_card_name = replacement_card_name
		if !drawn_card_name.is_empty():
			insert_drawn_card(owner_color, hand_index, drawn_card_name)
		else:
			match_board.arrange_card_visuals(visuals, true)
	else:
		match_board.arrange_card_visuals(visuals, true)

	update_card_presentation()
	return drawn_card_name

func insert_drawn_card(owner_color: int, hand_index: int, card_name: String) -> void:
	var card: Card = CardLibrary.duplicate_card(card_name)
	if card == null:
		push_warning("Card not found for draw: %s" % card_name)
		return

	var visuals: Array[CardVisual] = get_card_visuals(owner_color)
	var cards: Array[Card] = get_card_hand(owner_color)
	var hand_node: Control = get_card_hand_node(owner_color)
	var insert_index: int = clampi(hand_index, 0, cards.size())
	cards.insert(insert_index, card)

	var card_visual: CardVisual = card_visual_scene.instantiate() as CardVisual
	hand_node.add_child(card_visual)
	card_visual.set_rest_scale(Vector2.ONE * card_hand_scale)
	card_visual.set_hand_context(owner_color, insert_index, get_card_home_position(insert_index))
	card_visual.set_card(card)
	card_visual.set_face_down(owner_color != match_board.get_local_view_color())
	match_board.get_card_interaction_controller().connect_card_visual_signals(card_visual)
	visuals.insert(insert_index, card_visual)

	card_visual.global_position = get_card_draw_start_position(owner_color)
	card_visual.scale = Vector2.ONE * card_hand_scale
	match_board.arrange_card_visuals(visuals, true)
	match_board.get_card_animation_controller().animate_card_draw(owner_color, card_visual)

func draw_refill_card_name(owner_color: int) -> String:
	var deck: Array[String] = get_card_deck(owner_color)
	var protected_names: Array = match_board.exchanged_card_names_this_turn.get(owner_color, [])
	return draw_card_from_deck_avoiding_names(deck, protected_names)

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

func record_exchanged_card_name_this_turn(owner_color: int, card_name: String) -> void:
	var exchanged_names: Array = match_board.exchanged_card_names_this_turn.get(owner_color, [])
	exchanged_names.append(card_name)
	match_board.exchanged_card_names_this_turn[owner_color] = exchanged_names

func clear_exchanged_card_names_this_turn(owner_color: int) -> void:
	match_board.exchanged_card_names_this_turn[owner_color] = []
