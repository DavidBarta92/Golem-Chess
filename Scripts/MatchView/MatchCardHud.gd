extends RefCounted

var card_visual_scene: PackedScene
var card_ui_size: Vector2 = Vector2(164, 229)
var player_hand_size: int = DeckManager.HAND_SIZE
var card_hand_scale: float = 0.648
var deck_card_scale: float = 0.648
var deck_extra_left_offset: float = 200.0
var card_ui_gap: float = 10.0
var top_card_hand_margin: float = -28.0
var bottom_card_hand_margin: float = 34.0

func configure(config: Dictionary) -> void:
	card_visual_scene = config.get("card_visual_scene", card_visual_scene)
	card_ui_size = config.get("card_ui_size", card_ui_size)
	player_hand_size = int(config.get("player_hand_size", player_hand_size))
	card_hand_scale = float(config.get("card_hand_scale", card_hand_scale))
	deck_card_scale = float(config.get("deck_card_scale", deck_card_scale))
	deck_extra_left_offset = float(config.get("deck_extra_left_offset", deck_extra_left_offset))
	card_ui_gap = float(config.get("card_ui_gap", card_ui_gap))
	top_card_hand_margin = float(config.get("top_card_hand_margin", top_card_hand_margin))
	bottom_card_hand_margin = float(config.get("bottom_card_hand_margin", bottom_card_hand_margin))

func get_hand_layout_size() -> Vector2:
	return card_ui_size * card_hand_scale

func get_hand_step() -> float:
	return get_hand_layout_size().x + card_ui_gap

func get_card_home_position(index: int) -> Vector2:
	return Vector2(index * get_hand_step(), 0)

func get_deck_home_position() -> Vector2:
	return Vector2(-(card_ui_size.x * deck_card_scale) - (card_ui_gap * 2.0) - deck_extra_left_offset, 0)

func configure_hand_container(hand_node: Control, is_top: bool) -> void:
	if hand_node == null or !is_instance_valid(hand_node):
		return

	var scaled_card_size: Vector2 = get_hand_layout_size()
	var hand_width: float = scaled_card_size.x * float(player_hand_size) + card_ui_gap * float(player_hand_size - 1)
	hand_node.visible = true
	hand_node.mouse_filter = Control.MOUSE_FILTER_PASS
	hand_node.anchor_left = 0.5
	hand_node.anchor_right = 0.5
	hand_node.offset_left = -hand_width * 0.5
	hand_node.offset_right = hand_width * 0.5

	if is_top:
		hand_node.anchor_top = 0.0
		hand_node.anchor_bottom = 0.0
		hand_node.offset_top = top_card_hand_margin
		hand_node.offset_bottom = top_card_hand_margin + scaled_card_size.y
	else:
		hand_node.anchor_top = 1.0
		hand_node.anchor_bottom = 1.0
		hand_node.offset_top = -bottom_card_hand_margin - scaled_card_size.y
		hand_node.offset_bottom = -bottom_card_hand_margin

func populate_card_hand(hand_node: Control, cards: Array[Card], owner_color: int, signal_connector: Callable = Callable()) -> Array[CardVisual]:
	if hand_node == null or !is_instance_valid(hand_node):
		return []

	for child in hand_node.get_children():
		hand_node.remove_child(child)
		child.queue_free()

	var visuals: Array[CardVisual] = []
	for i in cards.size():
		var card_visual: CardVisual = card_visual_scene.instantiate() as CardVisual if card_visual_scene != null else null
		if card_visual == null:
			continue

		hand_node.add_child(card_visual)
		card_visual.set_rest_scale(Vector2.ONE * card_hand_scale)
		card_visual.set_hand_context(owner_color, i, get_card_home_position(i))
		card_visual.set_card(cards[i])
		if signal_connector.is_valid():
			signal_connector.call(card_visual)
		visuals.append(card_visual)

	return visuals

func free_existing_deck_visual(deck_visual: CardVisual) -> void:
	if deck_visual != null and is_instance_valid(deck_visual) and !deck_visual.is_queued_for_deletion():
		var parent_node: Node = deck_visual.get_parent()
		if parent_node != null:
			parent_node.remove_child(deck_visual)
		deck_visual.queue_free()

func create_deck_visual(hand_node: Control, owner_color: int) -> CardVisual:
	if hand_node == null or !is_instance_valid(hand_node) or card_visual_scene == null:
		return null

	var deck_visual: CardVisual = card_visual_scene.instantiate() as CardVisual
	if deck_visual == null:
		return null

	hand_node.add_child(deck_visual)
	deck_visual.set_hand_context(owner_color, -1, get_deck_home_position())
	deck_visual.set_card(null)
	deck_visual.set_face_down(true)
	deck_visual.draggable = false
	deck_visual.disabled = true
	deck_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_visual.set_rest_scale(Vector2.ONE * deck_card_scale)
	deck_visual.z_index = -1
	return deck_visual
