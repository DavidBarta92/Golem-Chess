extends Sprite2D

const BOARD_SIZE = 5
const CELL_WIDTH = 18

const TEXTURE_HOLDER = preload("res://Scenes/texture_holder.tscn")
const CARD_VISUAL = preload("res://Scenes/CardVisual.tscn")

const BLACK_BISHOP = preload("res://Assets/black_bishop.png")
const BLACK_KING = preload("res://Assets/black_king.png")
const BLACK_KNIGHT = preload("res://Assets/black_knight.png")
const BLACK_PAWN = preload("res://Assets/black_pawn.png")
const BLACK_QUEEN = preload("res://Assets/black_queen.png")
const BLACK_ROOK = preload("res://Assets/black_rook.png")
const WHITE_BISHOP = preload("res://Assets/white_bishop.png")
const WHITE_KING = preload("res://Assets/white_king.png")
const WHITE_KNIGHT = preload("res://Assets/white_knight.png")
const WHITE_PAWN = preload("res://Assets/white_pawn.png")
const WHITE_QUEEN = preload("res://Assets/white_queen.png")
const WHITE_ROOK = preload("res://Assets/white_rook.png")

const TURN_WHITE = preload("res://Assets/turn-white.png")
const TURN_BLACK = preload("res://Assets/turn-black.png")

const PIECE_MOVE = preload("res://Assets/Piece_move.png")

const PLAYER_HAND_SIZE = 5
const CARD_UI_SIZE = Vector2(126, 176)
const CARD_UI_GAP = 14
const CARD_HAND_MARGIN = 18
const HOVER_CARD_MARGIN = 24
const HIDDEN_CARD_MARGIN = 24
const HIDDEN_CARD_GAP = 10
const HIDDEN_CARD_SCALE = 0.78
const BOARD_MARKER_LINE_WIDTH = 1.8
const DECK_COUNT_LABEL_SIZE = Vector2(88, 28)
const DECK_COUNT_LABEL_GAP = 8
const PLAYER_NAME_LABEL_SIZE = Vector2(180, 28)
const PLAYER_NAME_LABEL_GAP = 8
const INVALID_BOARD_POS = Vector2(-1, -1)
const WHITE_BASE_FIELD = Vector2(0, 2)
const BLACK_BASE_FIELD = Vector2(4, 2)
const MAIN_MENU_SCENE = "res://Scenes/MainMenu.tscn"

@onready var pieces_node = $Pieces
@onready var dots = $Dots
@onready var turn = $Turn
@onready var canvas_layer = $"../CanvasLayer"
@onready var white_pieces = $"../CanvasLayer/white_pieces"
@onready var black_pieces = $"../CanvasLayer/black_pieces"

var board : Array
var piece_objects: Dictionary = {}
var white : bool = true
var state : bool = false
var moves = []
var selected_piece : Vector2
var hovered_piece : Vector2 = Vector2(-1, -1)
var white_card_deck: Array[String] = []
var black_card_deck: Array[String] = []
var white_card_hand: Array[Card] = []
var black_card_hand: Array[Card] = []
var white_card_visuals: Array[CardVisual] = []
var black_card_visuals: Array[CardVisual] = []
var white_deck_visual: CardVisual
var black_deck_visual: CardVisual
var attached_card_this_turn: Dictionary = {
	1: false,
	-1: false,
}
var moved_piece_this_turn: Dictionary = {
	1: false,
	-1: false,
}
var drawn_card_this_turn: Dictionary = {
	1: false,
	-1: false,
}
var game_over: bool = false
var hover_card_preview: CardVisual
var hover_duration_label: Label
var result_overlay: ColorRect
var result_label: Label
var has_received_server_state: bool = false
var deck_count_label: Label
var player_name_labels: Dictionary = {}
var quit_confirmation_dialog: ConfirmationDialog
var end_turn_button: Button
var white_deck_count_override: int = -1
var black_deck_count_override: int = -1
var hidden_card_preview_container: Control
var hidden_card_previews: Array[CardVisual] = []
var board_markers_node: Node2D
var current_board_effects: Array = []
var current_player_base_fields: Dictionary = {
	0: WHITE_BASE_FIELD,
	1: BLACK_BASE_FIELD,
}
var current_player_names: Dictionary = {
	0: "Player",
	1: "Player",
}

var side

func set_turn(_turn):
	side = _turn
	reset_current_turn_card_attach()
	update_card_presentation()
	display_board()
	if side != null && !side:
		$"../Camera2D".global_rotation_degrees = 180
	else:
		$"../Camera2D".global_rotation_degrees = 0

func _ready():
	randomize()
	create_board_markers_node()
	board.append([1, 1, 1, 1, 1])
	board.append([0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0])
	board.append([-1, -1, -1, -1, -1])

	create_pieces_from_board()
	setup_player_card_hands()
	create_hover_piece_ui()
	create_hidden_card_preview_ui()
	create_result_ui()
	create_deck_count_ui()
	create_player_name_ui()
	create_quit_confirmation_ui()
	create_end_turn_ui()
	update_player_name_labels()

func create_board_markers_node():
	board_markers_node = Node2D.new()
	board_markers_node.name = "BoardMarkers"
	board_markers_node.z_index = 1
	add_child(board_markers_node)
	move_child(board_markers_node, 0)
	pieces_node.z_index = 10
	dots.z_index = 20
	turn.z_index = 30

func create_pieces_from_board():
	piece_objects.clear()
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var value = board[i][j]
			if value != 0:
				var pos = Vector2(i, j)
				var color: int = 1 if value > 0 else -1
				var piece = Piece.new(pos, color)
				piece_objects[pos] = piece
				print("Piece created: pos=%s, color=%s" % [pos, "white" if color > 0 else "black"])

	print("Pieces initialized without starting cards.")

func setup_player_card_hands():
	white_card_deck = DeckManager.create_starting_deck()
	black_card_deck = DeckManager.create_starting_deck()
	white_card_hand = draw_starting_cards_from_deck(1)
	black_card_hand = draw_starting_cards_from_deck(-1)

	white_card_visuals = populate_card_hand(white_pieces, white_card_hand, 1)
	black_card_visuals = populate_card_hand(black_pieces, black_card_hand, -1)
	setup_deck_visuals()
	update_card_presentation()

func draw_starting_cards_from_deck(owner_color: int) -> Array[Card]:
	var hand_names: Array[String] = []
	var deck: Array[String] = get_card_deck(owner_color)
	DeckManager.draw_starting_hand(deck, hand_names)
	return create_card_hand_from_names(hand_names)

func draw_cards_from_deck(owner_color: int, amount: int) -> Array[Card]:
	var hand: Array[Card] = []
	for i in amount:
		var card_name: String = draw_card_name(owner_color)
		if card_name.is_empty():
			continue

		var card: Card = CardLibrary.duplicate_card(card_name)
		if card:
			hand.append(card)

	return hand

func draw_card_name(owner_color: int) -> String:
	var deck: Array[String] = get_card_deck(owner_color)
	if deck.is_empty():
		return ""

	return deck.pop_front()

func create_card_hand_from_names(card_names: Array) -> Array[Card]:
	var hand: Array[Card] = []
	for card_name_value in card_names:
		var card_name: String = str(card_name_value)
		var card: Card = CardLibrary.duplicate_card(card_name)
		if card:
			hand.append(card)
	return hand

func get_hand_names_from_state(player_hands: Dictionary, player_id: int) -> Array:
	if player_hands.has(player_id):
		return player_hands[player_id]
	var string_key: String = str(player_id)
	if player_hands.has(string_key):
		return player_hands[string_key]
	return []

func get_int_from_state_dict(data: Dictionary, player_id: int, default_value: int) -> int:
	if data.has(player_id):
		return int(data[player_id])
	var string_key: String = str(player_id)
	if data.has(string_key):
		return int(data[string_key])
	return default_value

func configure_card_hand_container(hand_node: Control, is_top: bool):
	var hand_width = CARD_UI_SIZE.x * PLAYER_HAND_SIZE + CARD_UI_GAP * (PLAYER_HAND_SIZE - 1)
	hand_node.visible = true
	hand_node.mouse_filter = Control.MOUSE_FILTER_PASS
	hand_node.anchor_left = 0.5
	hand_node.anchor_right = 0.5
	hand_node.offset_left = -hand_width * 0.5
	hand_node.offset_right = hand_width * 0.5

	if is_top:
		hand_node.anchor_top = 0.0
		hand_node.anchor_bottom = 0.0
		hand_node.offset_top = CARD_HAND_MARGIN
		hand_node.offset_bottom = CARD_HAND_MARGIN + CARD_UI_SIZE.y
	else:
		hand_node.anchor_top = 1.0
		hand_node.anchor_bottom = 1.0
		hand_node.offset_top = -CARD_HAND_MARGIN - CARD_UI_SIZE.y
		hand_node.offset_bottom = -CARD_HAND_MARGIN

func populate_card_hand(hand_node: Control, cards: Array[Card], owner_color: int) -> Array[CardVisual]:
	for child in hand_node.get_children():
		hand_node.remove_child(child)
		child.queue_free()

	var visuals: Array[CardVisual] = []
	for i in cards.size():
		var card_visual: CardVisual = CARD_VISUAL.instantiate() as CardVisual
		hand_node.add_child(card_visual)
		card_visual.set_hand_context(owner_color, i, get_card_home_position(i))
		card_visual.set_card(cards[i])
		connect_card_visual_signals(card_visual)
		visuals.append(card_visual)

	return visuals

func connect_card_visual_signals(card_visual: CardVisual):
	card_visual.drag_started.connect(_on_card_drag_started)
	card_visual.drag_moved.connect(_on_card_drag_moved)
	card_visual.drag_released.connect(_on_card_drag_released)

func setup_deck_visuals():
	white_deck_visual = create_deck_visual(white_pieces, 1)
	black_deck_visual = create_deck_visual(black_pieces, -1)

func create_deck_visual(hand_node: Control, owner_color: int) -> CardVisual:
	var deck_visual: CardVisual = CARD_VISUAL.instantiate() as CardVisual
	hand_node.add_child(deck_visual)
	deck_visual.set_hand_context(owner_color, -1, get_deck_home_position())
	deck_visual.set_card(null)
	deck_visual.set_face_down(true)
	deck_visual.draggable = false
	deck_visual.disabled = true
	deck_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_visual.scale = Vector2.ONE * 0.96
	deck_visual.z_index = -1
	return deck_visual

func create_hover_piece_ui():
	hover_card_preview = CARD_VISUAL.instantiate() as CardVisual
	canvas_layer.add_child(hover_card_preview)
	hover_card_preview.visible = false
	hover_card_preview.draggable = false
	hover_card_preview.disabled = true
	hover_card_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_card_preview.anchor_left = 1.0
	hover_card_preview.anchor_right = 1.0
	hover_card_preview.anchor_top = 0.5
	hover_card_preview.anchor_bottom = 0.5
	hover_card_preview.offset_left = -CARD_UI_SIZE.x - HOVER_CARD_MARGIN
	hover_card_preview.offset_right = -HOVER_CARD_MARGIN
	hover_card_preview.offset_top = -CARD_UI_SIZE.y * 0.5
	hover_card_preview.offset_bottom = CARD_UI_SIZE.y * 0.5
	hover_card_preview.z_index = 900

	hover_duration_label = Label.new()
	canvas_layer.add_child(hover_duration_label)
	hover_duration_label.visible = false
	hover_duration_label.size = Vector2(48, 32)
	hover_duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hover_duration_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hover_duration_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_duration_label.z_index = 901

	var label_settings: LabelSettings = LabelSettings.new()
	label_settings.font_size = 22
	label_settings.font_color = Color(1.0, 1.0, 1.0)
	label_settings.outline_size = 5
	label_settings.outline_color = Color(0.0, 0.0, 0.0)
	hover_duration_label.label_settings = label_settings

func create_result_ui():
	result_overlay = ColorRect.new()
	canvas_layer.add_child(result_overlay)
	result_overlay.visible = false
	result_overlay.color = Color(0.0, 0.0, 0.0, 0.62)
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	result_overlay.anchor_right = 1.0
	result_overlay.anchor_bottom = 1.0
	result_overlay.offset_left = 0.0
	result_overlay.offset_top = 0.0
	result_overlay.offset_right = 0.0
	result_overlay.offset_bottom = 0.0
	result_overlay.z_index = 2000

	result_label = Label.new()
	result_overlay.add_child(result_label)
	result_label.anchor_right = 1.0
	result_label.anchor_bottom = 1.0
	result_label.offset_left = 0.0
	result_label.offset_top = 0.0
	result_label.offset_right = 0.0
	result_label.offset_bottom = 0.0
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label_settings: LabelSettings = LabelSettings.new()
	label_settings.font_size = 72
	label_settings.font_color = Color(1.0, 1.0, 1.0)
	label_settings.outline_size = 8
	label_settings.outline_color = Color(0.0, 0.0, 0.0)
	result_label.label_settings = label_settings

func create_deck_count_ui():
	deck_count_label = Label.new()
	canvas_layer.add_child(deck_count_label)
	deck_count_label.visible = false
	deck_count_label.size = DECK_COUNT_LABEL_SIZE
	deck_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	deck_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_count_label.z_index = 950

	var label_settings: LabelSettings = LabelSettings.new()
	label_settings.font_size = 18
	label_settings.font_color = Color(1.0, 1.0, 1.0)
	label_settings.outline_size = 4
	label_settings.outline_color = Color(0.0, 0.0, 0.0)
	deck_count_label.label_settings = label_settings

func create_player_name_ui():
	player_name_labels[1] = create_player_name_label()
	player_name_labels[-1] = create_player_name_label()

func create_player_name_label() -> Label:
	var name_label: Label = Label.new()
	canvas_layer.add_child(name_label)
	name_label.visible = false
	name_label.size = PLAYER_NAME_LABEL_SIZE
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.z_index = 940

	var label_settings: LabelSettings = LabelSettings.new()
	label_settings.font_size = 20
	label_settings.font_color = Color(1.0, 1.0, 1.0)
	label_settings.outline_size = 4
	label_settings.outline_color = Color(0.0, 0.0, 0.0)
	name_label.label_settings = label_settings
	return name_label

func create_quit_confirmation_ui():
	quit_confirmation_dialog = ConfirmationDialog.new()
	canvas_layer.add_child(quit_confirmation_dialog)
	quit_confirmation_dialog.title = "Leave Game"
	quit_confirmation_dialog.dialog_text = "Do you really want to leave the game?"
	quit_confirmation_dialog.ok_button_text = "Yes"
	quit_confirmation_dialog.cancel_button_text = "No"
	quit_confirmation_dialog.exclusive = true
	quit_confirmation_dialog.confirmed.connect(_on_quit_confirmed)

func create_end_turn_ui():
	end_turn_button = Button.new()
	canvas_layer.add_child(end_turn_button)
	end_turn_button.text = "END TURN"
	end_turn_button.anchor_left = 1.0
	end_turn_button.anchor_right = 1.0
	end_turn_button.anchor_top = 1.0
	end_turn_button.anchor_bottom = 1.0
	end_turn_button.offset_left = -152.0
	end_turn_button.offset_right = -24.0
	end_turn_button.offset_top = -64.0
	end_turn_button.offset_bottom = -24.0
	end_turn_button.z_index = 960
	end_turn_button.focus_mode = Control.FOCUS_NONE
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	update_end_turn_button()

func create_hidden_card_preview_ui():
	hidden_card_preview_container = Control.new()
	canvas_layer.add_child(hidden_card_preview_container)
	hidden_card_preview_container.visible = false
	hidden_card_preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hidden_card_preview_container.anchor_left = 0.5
	hidden_card_preview_container.anchor_right = 0.5
	hidden_card_preview_container.anchor_top = 0.5
	hidden_card_preview_container.anchor_bottom = 0.5
	hidden_card_preview_container.z_index = 850

func get_card_home_position(index: int) -> Vector2:
	return Vector2(index * (CARD_UI_SIZE.x + CARD_UI_GAP), 0)

func get_deck_home_position() -> Vector2:
	return Vector2(-CARD_UI_SIZE.x - (CARD_UI_GAP * 2.0), 0)

func get_card_hand(owner_color: int) -> Array[Card]:
	return white_card_hand if owner_color == 1 else black_card_hand

func get_card_visuals(owner_color: int) -> Array[CardVisual]:
	return white_card_visuals if owner_color == 1 else black_card_visuals

func get_card_deck(owner_color: int) -> Array[String]:
	return white_card_deck if owner_color == 1 else black_card_deck

func get_card_deck_count(owner_color: int) -> int:
	if owner_color == 1:
		return white_deck_count_override if white_deck_count_override >= 0 else white_card_deck.size()
	return black_deck_count_override if black_deck_count_override >= 0 else black_card_deck.size()

func get_card_hand_node(owner_color: int) -> Control:
	return white_pieces if owner_color == 1 else black_pieces

func get_deck_visual(owner_color: int) -> CardVisual:
	return white_deck_visual if owner_color == 1 else black_deck_visual

func get_card_draw_start_position(owner_color: int) -> Vector2:
	var deck_visual: CardVisual = get_deck_visual(owner_color)
	if deck_visual and is_instance_valid(deck_visual):
		return deck_visual.global_position

	var hand_node: Control = get_card_hand_node(owner_color)
	return hand_node.global_position + get_deck_home_position()

func update_card_presentation():
	var local_color: int = get_local_view_color()
	configure_card_hand_container(white_pieces, local_color != 1)
	configure_card_hand_container(black_pieces, local_color != -1)
	update_card_face_visibility(local_color)
	update_card_drag_permissions()
	update_player_name_labels()
	update_end_turn_button()

func update_player_name_labels():
	for owner_color in [1, -1]:
		if !player_name_labels.has(owner_color):
			continue

		var name_label: Label = player_name_labels[owner_color] as Label
		var deck_visual: CardVisual = get_deck_visual(owner_color)
		if name_label == null or deck_visual == null or !is_instance_valid(deck_visual) or !deck_visual.visible:
			if name_label != null:
				name_label.visible = false
			continue

		var deck_rect: Rect2 = deck_visual.get_global_rect()
		var is_top_hand: bool = is_card_hand_top(owner_color)
		var label_x: float = deck_rect.get_center().x - PLAYER_NAME_LABEL_SIZE.x * 0.5
		var label_y: float = deck_rect.end.y + PLAYER_NAME_LABEL_GAP if is_top_hand else deck_rect.position.y - PLAYER_NAME_LABEL_SIZE.y - PLAYER_NAME_LABEL_GAP
		if label_y < 0.0:
			label_y = deck_rect.end.y + PLAYER_NAME_LABEL_GAP

		name_label.text = get_display_name_for_player(get_player_id_for_color(owner_color))
		name_label.global_position = Vector2(
			max(0.0, label_x),
			label_y
		)
		name_label.visible = true

func is_card_hand_top(owner_color: int) -> bool:
	var local_color: int = get_local_view_color()
	return owner_color != local_color

func get_display_name_for_player(player_id: int) -> String:
	if current_player_names.has(player_id):
		return str(current_player_names[player_id])
	var string_key: String = str(player_id)
	if current_player_names.has(string_key):
		return str(current_player_names[string_key])
	return "Player"

func update_card_drag_permissions():
	var active_color: int = get_controllable_color()
	var can_drag: bool = can_control_current_turn()
	for card_visual in white_card_visuals:
		card_visual.draggable = can_drag && card_visual.owner_color == active_color
	for card_visual in black_card_visuals:
		card_visual.draggable = can_drag && card_visual.owner_color == active_color

func update_end_turn_button():
	if end_turn_button == null:
		return
	end_turn_button.visible = !game_over
	end_turn_button.disabled = !can_control_current_turn()

func _on_end_turn_pressed():
	if !can_control_current_turn():
		return

	if GameController.current_game_host:
		GameController.send_action({
			"type": "end_turn",
			"player_id": get_own_player_id(),
		})
		return

	end_current_turn_locally()

func end_current_turn_locally():
	if should_tick_attached_cards_this_end_turn_locally():
		tick_attached_cards_locally()
	white = !white
	reset_current_turn_card_attach()
	state = false
	delete_dots()
	hide_hover_piece_details()
	update_card_presentation()
	display_board()
	finish_if_current_player_has_no_valid_turn()

func tick_attached_cards_locally() -> void:
	var positions: Array = piece_objects.keys()
	for position_value in positions:
		var piece_pos: Vector2 = value_to_vector2(position_value, INVALID_BOARD_POS)
		if !piece_objects.has(piece_pos):
			continue

		var piece: Piece = piece_objects[piece_pos] as Piece
		if piece == null or piece.attached_card == null:
			continue

		var expired_card: Card = piece.use_turn()
		if expired_card == null:
			continue
		if MoveRules.is_king_card(expired_card):
			handle_expired_king_card_locally(piece.color, expired_card)
			continue
		play_card_expire_animation(piece_pos, expired_card)

func handle_expired_king_card_locally(owner_color: int, expired_card: Card) -> void:
	var hand: Array[Card] = get_card_hand(owner_color)
	if hand.size() >= DeckManager.HAND_SIZE:
		print("King card deleted because the hand is full.")
		if !player_has_available_king_card(owner_color):
			finish_game(-owner_color)
		return

	var returned_card: Card = expired_card.duplicate() as Card
	if returned_card != null:
		hand.append(returned_card)

func should_tick_attached_cards_this_end_turn_locally() -> bool:
	return !white

func update_card_face_visibility(local_color: int):
	for card_visual in white_card_visuals:
		card_visual.set_face_down(card_visual.owner_color != local_color)
	for card_visual in black_card_visuals:
		card_visual.set_face_down(card_visual.owner_color != local_color)

func get_local_view_color() -> int:
	if side == null:
		return get_controllable_color()
	return get_own_color()

func get_controllable_color() -> int:
	if side == null:
		return 1 if white else -1
	return get_own_color()

func get_current_turn_color() -> int:
	return 1 if white else -1

func get_own_color() -> int:
	if side == null:
		return 1
	return 1 if side else -1

func get_player_id_for_color(owner_color: int) -> int:
	return 0 if owner_color == 1 else 1

func get_color_for_player_id(player_id: int) -> int:
	return 1 if player_id == 0 else -1

func get_own_player_id() -> int:
	return get_player_id_for_color(get_own_color())

func has_attached_card_this_turn(owner_color: int) -> bool:
	return bool(attached_card_this_turn.get(owner_color, false))

func mark_card_attached_this_turn(owner_color: int):
	attached_card_this_turn[owner_color] = true
	update_card_drag_permissions()

func reset_current_turn_card_attach():
	var current_color: int = get_current_turn_color()
	attached_card_this_turn[current_color] = false
	moved_piece_this_turn[current_color] = false
	drawn_card_this_turn[current_color] = false

func has_moved_piece_this_turn(owner_color: int) -> bool:
	return bool(moved_piece_this_turn.get(owner_color, false))

func mark_piece_moved_this_turn(owner_color: int):
	moved_piece_this_turn[owner_color] = true
	update_end_turn_button()

func has_drawn_card_this_turn(owner_color: int) -> bool:
	return bool(drawn_card_this_turn.get(owner_color, false))

func mark_card_drawn_this_turn(owner_color: int):
	drawn_card_this_turn[owner_color] = true

func _on_card_drag_started(card_visual: CardVisual):
	card_visual.set_drop_target_active(false)

func _on_card_drag_moved(card_visual: CardVisual):
	var target_pos: Vector2 = get_card_drop_piece_position(card_visual)
	card_visual.set_drop_target_active(target_pos != INVALID_BOARD_POS)
	handle_card_reorder(card_visual)

func _on_card_drag_released(card_visual: CardVisual):
	var target_pos: Vector2 = get_card_drop_piece_position(card_visual)
	if target_pos != INVALID_BOARD_POS:
		attach_card_visual_to_piece(card_visual, target_pos)
	else:
		card_visual.fly_home()

func get_card_drop_piece_position(card_visual: CardVisual) -> Vector2:
	if !can_control_current_turn() || has_attached_card_this_turn(card_visual.owner_color):
		return INVALID_BOARD_POS
	if card_visual.owner_color != get_controllable_color():
		return INVALID_BOARD_POS
	if is_mouse_out():
		return INVALID_BOARD_POS

	var board_pos: Vector2 = get_mouse_board_position()
	var card_name: String = card_visual.card.card_name if card_visual.card else ""
	if is_valid_position(board_pos) && is_piece_owned_by(board_pos, card_visual.owner_color) && can_attach_card_to_piece(board_pos, card_name, card_visual.owner_color):
		return board_pos

	return INVALID_BOARD_POS

func attach_card_visual_to_piece(card_visual: CardVisual, piece_position: Vector2):
	if not piece_objects.has(piece_position) or card_visual.card == null:
		card_visual.fly_home()
		return
	var card_name: String = card_visual.card.card_name
	if has_attached_card_this_turn(card_visual.owner_color):
		card_visual.fly_home()
		return
	if !can_attach_card_to_piece(piece_position, card_name, card_visual.owner_color):
		card_visual.fly_home()
		return

	var hand_index: int = get_card_visual_index(card_visual)
	if GameController.current_game_host:
		send_card_attach_action(card_visual.owner_color, card_name, piece_position, hand_index)
		card_visual.assign_and_hide()
		mark_card_attached_this_turn(card_visual.owner_color)
		return

	if !apply_card_to_piece(piece_position, card_name):
		card_visual.fly_home()
		return

	remove_card_from_hand(card_visual)
	mark_card_attached_this_turn(card_visual.owner_color)

	if get_parent().has_method("send_card_attach"):
		get_parent().send_card_attach(piece_position, card_name, card_visual.owner_color, hand_index, "")

func send_card_attach_action(owner_color: int, card_name: String, piece_position: Vector2, hand_index: int):
	var action: Dictionary = {
		"type": "attach_card",
		"player_id": get_player_id_for_color(owner_color),
		"card_name": card_name,
		"piece_pos": piece_position,
		"hand_index": hand_index,
	}
	GameController.send_action(action)

func can_attach_card_to_piece(piece_position: Vector2, card_name: String = "", owner_color: int = 0) -> bool:
	if not piece_objects.has(piece_position):
		return false

	var piece: Piece = piece_objects[piece_position] as Piece
	return piece.attached_card == null

func apply_card_to_piece(piece_position: Vector2, card_name: String) -> bool:
	if not piece_objects.has(piece_position):
		return false

	var piece: Piece = piece_objects[piece_position] as Piece
	if piece.attached_card != null:
		push_warning("This piece already has a card: %s" % piece_position)
		return false

	var card: Card = CardLibrary.duplicate_card(card_name)
	if card == null:
		push_warning("Card not found for attach: %s" % card_name)
		return false

	piece.attach_card(card)
	display_board()
	return true

func apply_remote_card_attach(piece_position: Vector2, card_name: String, owner_color: int, hand_index: int, _replacement_card_name: String = ""):
	if apply_card_to_piece(piece_position, card_name):
		remove_card_from_hand_index(owner_color, hand_index, false, _replacement_card_name)

func remove_card_from_hand(card_visual: CardVisual) -> String:
	return remove_card_from_hand_index(card_visual.owner_color, get_card_visual_index(card_visual), false)

func get_card_visual_index(card_visual: CardVisual) -> int:
	if card_visual.owner_color == 1:
		return white_card_visuals.find(card_visual)
	return black_card_visuals.find(card_visual)

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
		if drawn_card_name.is_empty():
			drawn_card_name = draw_card_name(owner_color)
		if !drawn_card_name.is_empty():
			insert_drawn_card(owner_color, hand_index, drawn_card_name)
		else:
			arrange_card_visuals(visuals, true)
	else:
		arrange_card_visuals(visuals, true)

	update_card_presentation()
	return drawn_card_name

func insert_drawn_card(owner_color: int, hand_index: int, card_name: String):
	var card: Card = CardLibrary.duplicate_card(card_name)
	if card == null:
		push_warning("Card not found for draw: %s" % card_name)
		return

	var visuals: Array[CardVisual] = get_card_visuals(owner_color)
	var cards: Array[Card] = get_card_hand(owner_color)
	var hand_node: Control = get_card_hand_node(owner_color)
	var insert_index: int = clampi(hand_index, 0, cards.size())
	cards.insert(insert_index, card)

	var card_visual: CardVisual = CARD_VISUAL.instantiate() as CardVisual
	hand_node.add_child(card_visual)
	card_visual.set_hand_context(owner_color, insert_index, get_card_home_position(insert_index))
	card_visual.set_card(card)
	card_visual.set_face_down(owner_color != get_local_view_color())
	connect_card_visual_signals(card_visual)
	visuals.insert(insert_index, card_visual)

	card_visual.global_position = get_card_draw_start_position(owner_color)
	card_visual.scale = Vector2.ONE * 0.72
	arrange_card_visuals(visuals, true)
	animate_card_draw(owner_color, card_visual)

func animate_card_draw(owner_color: int, card_visual: CardVisual):
	if card_visual == null or !is_instance_valid(card_visual):
		return

	var deck_visual: CardVisual = get_deck_visual(owner_color)
	if deck_visual and is_instance_valid(deck_visual):
		deck_visual.play_draw_pulse()
	card_visual.fly_from_global_position(get_card_draw_start_position(owner_color))

func get_card_names_from_hand(cards: Array[Card]) -> Array[String]:
	var names: Array[String] = []
	for card: Card in cards:
		if card:
			names.append(card.card_name)
	return names

func arrays_match(left: Array, right: Array) -> bool:
	if left.size() != right.size():
		return false
	for i in left.size():
		if left[i] != right[i]:
			return false
	return true

func animate_state_draw_if_needed(owner_color: int, previous_names: Array, current_names: Array):
	if previous_names.is_empty() or arrays_match(previous_names, current_names):
		return
	if current_names.size() < previous_names.size():
		return

	var visuals: Array[CardVisual] = get_card_visuals(owner_color)
	if visuals.is_empty():
		return

	animate_card_draw(owner_color, visuals[visuals.size() - 1])

func animate_recent_card_transfers(recent_card_transfers: Array, previous_white_names: Array, current_white_names: Array, previous_black_names: Array, current_black_names: Array):
	var used_indices_by_owner: Dictionary = {
		1: [],
		-1: [],
	}

	for transfer_value in recent_card_transfers:
		var transfer: Dictionary = transfer_value
		var target_zone: String = str(transfer.get("target_zone", ""))
		if target_zone == "deleted":
			play_transfer_source_pulse(transfer)
			play_card_transfer_burn_animation(transfer)
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

func count_card_name(card_names: Array, card_name: String) -> int:
	var count: int = 0
	for card_name_value in card_names:
		if str(card_name_value) == card_name:
			count += 1
	return count

func animate_recent_card_expirations(recent_card_expirations: Array) -> void:
	for expiration_value in recent_card_expirations:
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
		if expired_card.effect_type == CardEffect.TYPE_GIVE_CARD && expired_card.effect_trigger == CardEffect.TRIGGER_ON_EXPIRE:
			continue

		play_card_expire_animation(piece_pos, expired_card)

func play_card_transfer_burn_animation(transfer: Dictionary) -> void:
	if canvas_layer == null:
		return

	var card_name: String = str(transfer.get("card_name", ""))
	var card: Card = CardLibrary.duplicate_card(card_name)
	if card == null:
		return

	var card_visual: CardVisual = CARD_VISUAL.instantiate() as CardVisual
	canvas_layer.add_child(card_visual)
	card_visual.set_card(card)
	card_visual.set_face_down(false)
	card_visual.draggable = false
	card_visual.disabled = true
	card_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var animation_scale: float = 0.74
	var source_position: Vector2 = get_card_transfer_source_position(transfer)
	var visual_size: Vector2 = CARD_UI_SIZE * animation_scale
	card_visual.global_position = source_position - visual_size * 0.5
	card_visual.scale = Vector2.ONE * animation_scale
	card_visual.rotation = deg_to_rad(randf_range(-4.0, 4.0))
	card_visual.z_index = 980
	card_visual.play_burn_away_and_free()

func play_card_expire_animation(piece_position: Vector2, expired_card: Card) -> void:
	if expired_card == null or canvas_layer == null or !is_valid_position(piece_position):
		return

	var display_card: Card = expired_card.duplicate() as Card
	if display_card == null:
		display_card = expired_card
	display_card.duration = 0

	var card_visual: CardVisual = CARD_VISUAL.instantiate() as CardVisual
	canvas_layer.add_child(card_visual)
	card_visual.set_card(display_card)
	card_visual.set_face_down(false)
	card_visual.draggable = false
	card_visual.disabled = true
	card_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var animation_scale: float = 0.74
	var piece_screen_position: Vector2 = get_board_position_screen_position(piece_position)
	var visual_size: Vector2 = CARD_UI_SIZE * animation_scale
	card_visual.global_position = piece_screen_position - visual_size * 0.5 + Vector2(0.0, -visual_size.y * 0.72)
	card_visual.scale = Vector2.ONE * animation_scale
	card_visual.rotation = deg_to_rad(randf_range(-4.0, 4.0))
	card_visual.z_index = 980
	card_visual.play_burn_away_and_free()

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

	return get_viewport().get_visible_rect().size * 0.5

func get_card_hand_source_position(owner_color: int) -> Vector2:
	var visuals: Array[CardVisual] = get_card_visuals(owner_color)
	for card_visual: CardVisual in visuals:
		if card_visual != null and is_instance_valid(card_visual) and card_visual.visible:
			return card_visual.global_position

	var hand_node: Control = get_card_hand_node(owner_color)
	if hand_node == null:
		return get_viewport().get_visible_rect().size * 0.5

	return hand_node.global_position + get_card_home_position(maxi(0, visuals.size() - 1))

func handle_card_reorder(card_visual: CardVisual):
	if card_visual.owner_color == 1:
		handle_card_reorder_in_hand(card_visual, white_card_visuals, white_card_hand)
	else:
		handle_card_reorder_in_hand(card_visual, black_card_visuals, black_card_hand)

func handle_card_reorder_in_hand(card_visual: CardVisual, visuals: Array[CardVisual], cards: Array[Card]):
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
	if swap_index == -1 && right_index < visuals.size():
		var right_midpoint: float = (get_card_home_position(right_index).x + get_card_home_position(card_index).x) * 0.5
		if mouse_pos.x > right_midpoint:
			swap_index = right_index

	if swap_index == -1:
		return

	var visual_temp: CardVisual = visuals[card_index]
	visuals[card_index] = visuals[swap_index]
	visuals[swap_index] = visual_temp

	var card_temp: Card = cards[card_index]
	cards[card_index] = cards[swap_index]
	cards[swap_index] = card_temp

	arrange_card_visuals(visuals, true)

func arrange_card_visuals(visuals: Array[CardVisual], animate: bool):
	for i in visuals.size():
		var card_visual: CardVisual = visuals[i]
		card_visual.hand_index = i
		card_visual.set_home_position(get_card_home_position(i), animate)

func _process(_delta):
	update_hovered_piece()
	update_deck_count_hover()

func update_deck_count_hover():
	if deck_count_label == null:
		return

	var hovered_deck_color: int = get_hovered_deck_color()
	if hovered_deck_color == 0:
		deck_count_label.visible = false
		return

	var deck_visual: CardVisual = get_deck_visual(hovered_deck_color)
	if deck_visual == null or !is_instance_valid(deck_visual):
		deck_count_label.visible = false
		return

	var deck_rect: Rect2 = deck_visual.get_global_rect()
	var label_y: float = deck_rect.position.y - deck_count_label.size.y - DECK_COUNT_LABEL_GAP
	if label_y < 0.0:
		label_y = deck_rect.end.y + DECK_COUNT_LABEL_GAP

	deck_count_label.text = "%d cards" % get_card_deck_count(hovered_deck_color)
	deck_count_label.global_position = Vector2(
		deck_rect.get_center().x - deck_count_label.size.x * 0.5,
		label_y
	)
	deck_count_label.visible = true

func get_hovered_deck_color() -> int:
	if is_mouse_over_deck(1):
		return 1
	if is_mouse_over_deck(-1):
		return -1
	return 0

func is_mouse_over_deck(owner_color: int) -> bool:
	var deck_visual: CardVisual = get_deck_visual(owner_color)
	if deck_visual == null or !is_instance_valid(deck_visual) or !deck_visual.visible:
		return false

	return deck_visual.get_global_rect().has_point(get_viewport().get_mouse_position())

func try_handle_deck_click() -> bool:
	var active_color: int = get_controllable_color()
	if !can_control_current_turn() or has_drawn_card_this_turn(active_color):
		return false
	if !is_mouse_over_deck(active_color):
		return false
	if !can_draw_card_locally(active_color):
		return true

	request_card_draw(active_color)
	return true

func can_draw_card_locally(owner_color: int) -> bool:
	return get_card_deck_count(owner_color) > 0

func request_card_draw(owner_color: int):
	if GameController.current_game_host:
		GameController.send_action({
			"type": "draw_card",
			"player_id": get_player_id_for_color(owner_color),
		})
		mark_card_drawn_this_turn(owner_color)
		return

	var card_name: String = draw_card_name(owner_color)
	if card_name.is_empty():
		return
	if get_card_hand(owner_color).size() >= DeckManager.HAND_SIZE:
		play_card_transfer_burn_animation({
			"source_player_id": get_player_id_for_color(owner_color),
			"target_player_id": get_player_id_for_color(owner_color),
			"card_name": card_name,
			"source_zone": "deck",
			"target_zone": "deleted",
		})
		mark_card_drawn_this_turn(owner_color)
		return
	insert_drawn_card(owner_color, get_card_hand(owner_color).size(), card_name)
	mark_card_drawn_this_turn(owner_color)

func _input(event):
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed && !key_event.echo && key_event.keycode == KEY_ESCAPE:
			show_quit_confirmation()
			get_viewport().set_input_as_handled()
			return

	if can_control_current_turn():
		if event is InputEventMouseButton && event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if try_handle_deck_click():
					get_viewport().set_input_as_handled()
					return
				if is_mouse_out(): return
				if has_moved_piece_this_turn(get_controllable_color()):
					return
				var local_pos: Vector2 = to_local(get_global_mouse_position())

				var offset = (BOARD_SIZE * CELL_WIDTH) / 2.0
				var adjusted_x = local_pos.x + offset
				var adjusted_y = -local_pos.y + offset

				var var1 = int(adjusted_x / CELL_WIDTH)
				var var2 = int(adjusted_y / CELL_WIDTH)

				print("Click: grid=(", var1, ",", var2, ") board[", var2, "][", var1, "]=", board[var2][var1] if var2 < BOARD_SIZE && var1 < BOARD_SIZE else "invalid")

				if var1 < 0 || var1 >= BOARD_SIZE || var2 < 0 || var2 >= BOARD_SIZE:
					return

				var clicked_pos: Vector2 = Vector2(var2, var1)
				if !state && can_player_control_piece_at(clicked_pos, get_own_player_id()):
					selected_piece = clicked_pos
					show_options()
					state = true
				elif state:
					if moves.has(clicked_pos):
						send_move_action(selected_piece, clicked_pos)

					delete_dots()
					state = false
					hovered_piece = Vector2(-1, -1)
					hide_hover_piece_details()

func show_quit_confirmation():
	if quit_confirmation_dialog == null:
		return
	quit_confirmation_dialog.popup_centered(Vector2i(360, 140))

func _on_quit_confirmed():
	GameConfig.stop_ai_vs_ai_batch()
	if get_parent().has_method("close_game_connection"):
		get_parent().close_game_connection()
	if get_tree():
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func send_move_action(from_pos: Vector2, to_pos: Vector2):
	if GameController.current_game_host:
		var action: Dictionary = {
			"type": "move_piece",
			"player_id": get_own_player_id(),
			"from": from_pos,
			"to": to_pos,
		}
		GameController.send_action(action)
		mark_piece_moved_this_turn(get_controllable_color())
		return

	if get_parent().has_method("send_move"):
		get_parent().send_move(from_pos, to_pos)
	set_move(from_pos, to_pos)

func is_mouse_out():
	if get_rect().has_point(to_local(get_global_mouse_position())): return false
	return true

func get_mouse_board_position() -> Vector2:
	var local_pos: Vector2 = to_local(get_global_mouse_position())
	var offset = (BOARD_SIZE * CELL_WIDTH) / 2.0
	var adjusted_x = local_pos.x + offset
	var adjusted_y = -local_pos.y + offset
	return Vector2(int(adjusted_y / CELL_WIDTH), int(adjusted_x / CELL_WIDTH))

func update_hovered_piece():
	if state:
		return

	if game_over || is_mouse_out():
		if hovered_piece != Vector2(-1, -1):
			hovered_piece = Vector2(-1, -1)
			delete_dots()
			hide_hover_piece_details()
		return

	var board_pos: Vector2 = get_mouse_board_position()
	if board_pos == hovered_piece:
		update_hover_duration_label_position()
		return

	hovered_piece = board_pos
	delete_dots()
	hide_hover_piece_details()

	if is_valid_position(board_pos) && !is_empty(board_pos):
		moves = get_moves(board_pos)
		show_dots()
		show_hover_piece_details(board_pos)

func show_hover_piece_details(board_pos: Vector2):
	if !piece_objects.has(board_pos):
		return

	var piece: Piece = piece_objects[board_pos] as Piece
	if piece.attached_card == null:
		return

	var preview_card: Card = piece.attached_card.duplicate() as Card
	if preview_card:
		preview_card.duration = piece.turns_remaining
		hover_card_preview.set_card(preview_card)
		hover_card_preview.set_face_down(false)
		hover_card_preview.visible = true

	hover_duration_label.text = "INF" if piece.turns_remaining < 0 else str(piece.turns_remaining)
	hover_duration_label.visible = true
	update_hover_duration_label_position()

func hide_hover_piece_details():
	if hover_card_preview:
		hover_card_preview.visible = false
	if hover_duration_label:
		hover_duration_label.visible = false

func update_hover_duration_label_position():
	if !hover_duration_label or !hover_duration_label.visible:
		return
	if !is_valid_position(hovered_piece):
		return

	var piece_screen_position: Vector2 = get_board_position_screen_position(hovered_piece)
	hover_duration_label.global_position = piece_screen_position + Vector2(-hover_duration_label.size.x * 0.5, -46.0)

func get_board_position_screen_position(board_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas() * get_board_position_local_position(board_pos)

func get_board_position_local_position(board_pos: Vector2) -> Vector2:
	var offset: float = -(BOARD_SIZE * CELL_WIDTH) / 2.0
	return Vector2(board_pos.y * CELL_WIDTH + (CELL_WIDTH / 2.0) + offset, -board_pos.x * CELL_WIDTH - (CELL_WIDTH / 2.0) - offset)

func get_default_piece_texture(piece_value: int) -> Texture2D:
	match piece_value:
		-6:
			return BLACK_KING
		-5:
			return BLACK_QUEEN
		-4:
			return BLACK_ROOK
		-3:
			return BLACK_BISHOP
		-2:
			return BLACK_KNIGHT
		-1:
			return BLACK_PAWN
		6:
			return WHITE_KING
		5:
			return WHITE_QUEEN
		4:
			return WHITE_ROOK
		3:
			return WHITE_BISHOP
		2:
			return WHITE_KNIGHT
		1:
			return WHITE_PAWN

	return null

func get_attached_card_piece_texture(piece: Piece) -> Texture2D:
	if piece == null or piece.attached_card == null:
		return null
	if piece.color > 0:
		return piece.attached_card.white_piece_texture
	return piece.attached_card.black_piece_texture

func get_piece_texture_for_position(board_pos: Vector2, piece_value: int) -> Texture2D:
	var attached_texture: Texture2D = null
	if piece_objects.has(board_pos):
		var piece: Piece = piece_objects[board_pos] as Piece
		attached_texture = get_attached_card_piece_texture(piece)
	if attached_texture != null:
		return attached_texture
	return get_default_piece_texture(piece_value)

func display_board():
	print("display_board() called: white=", white, " side=", side)
	update_board_markers()
	for child in pieces_node.get_children():
		child.queue_free()

	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = TEXTURE_HOLDER.instantiate()
			if side != null && !side:
				holder.global_rotation_degrees = 180
				$"../Camera2D".global_rotation_degrees = 180
			pieces_node.add_child(holder)
			var offset = -(BOARD_SIZE * CELL_WIDTH) / 2.0
			holder.position = Vector2(j * CELL_WIDTH + (CELL_WIDTH / 2) + offset, -i * CELL_WIDTH - (CELL_WIDTH / 2) - offset)
			holder.texture = get_piece_texture_for_position(Vector2(i, j), int(board[i][j]))

	if white: turn.texture = TURN_WHITE
	else: turn.texture = TURN_BLACK

func show_options():
	moves = get_moves(selected_piece)
	if moves == []:
		state = false
		return
	delete_dots()
	show_dots()
	show_hover_piece_details(selected_piece)

func show_dots():
	for i in moves:
		var holder = TEXTURE_HOLDER.instantiate()
		dots.add_child(holder)
		holder.texture = PIECE_MOVE
		var offset = -(BOARD_SIZE * CELL_WIDTH) / 2.0
		holder.position = Vector2(i.y * CELL_WIDTH + (CELL_WIDTH / 2) + offset, -i.x * CELL_WIDTH - (CELL_WIDTH / 2) - offset)

func delete_dots():
	for child in dots.get_children():
		child.queue_free()

func set_move(start_pos : Vector2, end_pos : Vector2, promotion = null):
	if game_over:
		return

	print("set_move() start: white=", white, " start=", start_pos, " end=", end_pos, " piece=", board[start_pos.x][start_pos.y])
	var moving_color: int = 1 if board[start_pos.x][start_pos.y] > 0 else -1
	var captured_piece: Piece = piece_objects[end_pos] as Piece if piece_objects.has(end_pos) else null
	var captured_king: bool = is_king_piece(captured_piece)
	var captured_king_owner_color: int = captured_piece.color if captured_piece != null else 0
	var captured_king_card_returned: bool = true

	if piece_objects.has(start_pos):
		var piece: Piece = piece_objects[start_pos] as Piece
		piece.position = end_pos
		piece_objects.erase(start_pos)
		piece_objects[end_pos] = piece
		print("  Piece moved: %s -> %s" % [start_pos, end_pos])

	var just_now = false

	board[end_pos.x][end_pos.y] = board[start_pos.x][start_pos.y]
	board[start_pos.x][start_pos.y] = 0

	if captured_king:
		captured_king_card_returned = return_captured_king_card_to_hand(captured_piece)

	if captured_king && !captured_king_card_returned && !player_has_available_king_card(captured_king_owner_color):
		display_board()
		finish_game(-captured_king_owner_color)
		return

	var winner_color: int = get_winner_after_move(moving_color, end_pos)
	if winner_color != 0:
		display_board()
		finish_game(winner_color)
		return

	mark_piece_moved_this_turn(moving_color)
	update_card_presentation()
	print("set_move() end: waiting for END TURN")

	display_board()

	if (start_pos.x != end_pos.x || start_pos.y != end_pos.y) && (white && board[end_pos.x][end_pos.y] > 0 || !white && board[end_pos.x][end_pos.y] < 0):
		start_pos = end_pos
		show_options()
		state = true

func return_captured_king_card_to_hand(captured_piece: Piece) -> bool:
	if captured_piece == null or captured_piece.attached_card == null:
		return false
	var owner_color: int = captured_piece.color
	var hand: Array[Card] = get_card_hand(owner_color)
	if hand.size() >= DeckManager.HAND_SIZE:
		print("King card deleted because the hand is full.")
		return false
	var returned_card: Card = captured_piece.attached_card.duplicate() as Card
	if returned_card != null:
		hand.append(returned_card)
		return true
	return false

func player_has_available_king_card(owner_color: int) -> bool:
	for card: Card in get_card_hand(owner_color):
		if MoveRules.is_king_card(card):
			return true
	if DeckManager.has_king_card(get_card_deck(owner_color)):
		return true
	for position_value in piece_objects:
		var piece: Piece = piece_objects[position_value] as Piece
		if piece != null && piece.color == owner_color && MoveRules.is_king_card(piece.attached_card):
			return true
	return false

func get_winner_after_move(moving_color: int, end_pos: Vector2) -> int:
	if is_opponent_base_field(moving_color, end_pos) && is_king_piece_at(end_pos):
		return moving_color
	return 0

func is_opponent_base_field(moving_color: int, pos: Vector2) -> bool:
	if moving_color == 1:
		return pos == BLACK_BASE_FIELD
	return pos == WHITE_BASE_FIELD

func has_any_piece(owner_color: int) -> bool:
	return MoveRules.has_any_piece(piece_objects, owner_color)

func is_king_piece(piece: Piece) -> bool:
	return piece != null && MoveRules.is_king_card(piece.attached_card)

func is_king_piece_at(piece_position: Vector2) -> bool:
	if !piece_objects.has(piece_position):
		return false
	return is_king_piece(piece_objects[piece_position] as Piece)

func current_player_has_valid_turn_action() -> bool:
	var current_color: int = get_current_turn_color()
	if has_moved_piece_this_turn(current_color):
		return false
	var hand_cards: Array[Card] = get_card_hand(current_color)
	var can_attach_card: bool = !has_attached_card_this_turn(current_color)
	if MoveRules.has_valid_turn_action(piece_objects, current_color, hand_cards, can_attach_card, BOARD_SIZE, current_board_effects):
		return true
	if !has_drawn_card_this_turn(current_color) && get_card_hand(current_color).size() < DeckManager.HAND_SIZE && !get_card_deck(current_color).is_empty():
		var simulated_hand: Array[Card] = hand_cards.duplicate()
		var next_card: Card = CardLibrary.duplicate_card(get_card_deck(current_color)[0])
		if next_card != null:
			simulated_hand.append(next_card)
			return MoveRules.has_valid_turn_action(piece_objects, current_color, simulated_hand, can_attach_card, BOARD_SIZE, current_board_effects)
	return false

func finish_if_current_player_has_no_valid_turn() -> bool:
	if game_over:
		return false
	if current_player_has_valid_turn_action():
		return false

	var losing_color: int = get_current_turn_color()
	var winner_color: int = -losing_color
	print("No valid moves for player: ", losing_color, ". Winner: ", winner_color)
	finish_game(winner_color)
	return true

func finish_game(winner_color: int):
	if game_over:
		return

	game_over = true
	state = false
	hovered_piece = Vector2(-1, -1)
	delete_dots()
	hide_hover_piece_details()
	update_card_drag_permissions()
	update_end_turn_button()
	show_result_message(winner_color)

	await get_tree().create_timer(8.0).timeout
	var next_scene: String = get_next_scene_after_game(winner_color)
	if get_parent().has_method("close_game_connection"):
		get_parent().close_game_connection()
	if get_tree():
		get_tree().change_scene_to_file(next_scene)

func get_next_scene_after_game(winner_color: int) -> String:
	if GameConfig.is_ai_vs_ai_batch:
		var winner_player_id: int = get_player_id_for_color(winner_color)
		GameConfig.record_ai_vs_ai_result(winner_player_id)
		print("AI vs AI match %d/%d finished. White wins: %d, Black wins: %d" % [
			GameConfig.ai_vs_ai_matches_played,
			GameConfig.ai_vs_ai_match_count,
			int(GameConfig.ai_vs_ai_results.get(0, 0)),
			int(GameConfig.ai_vs_ai_results.get(1, 0)),
		])

		if GameConfig.should_continue_ai_vs_ai_batch():
			return "res://Scenes/main.tscn"

		GameConfig.stop_ai_vs_ai_batch()

	return MAIN_MENU_SCENE

func show_result_message(winner_color: int):
	if result_label == null or result_overlay == null:
		return

	if GameConfig.is_ai_vs_ai_batch:
		result_label.text = "%s WINS!\nMATCH %d / %d" % [
			"WHITE" if winner_color == 1 else "BLACK",
			GameConfig.ai_vs_ai_matches_played + 1,
			GameConfig.ai_vs_ai_match_count,
		]
	elif side == null:
		result_label.text = "WHITE WINS!" if winner_color == 1 else "BLACK WINS!"
	else:
		result_label.text = "YOU WON!" if winner_color == get_own_color() else "YOU LOST!"
	result_overlay.visible = true

func get_moves(selected : Vector2):
	if piece_objects.has(selected):
		var piece: Piece = piece_objects[selected] as Piece
		if piece.can_move():
			print("Using card movement: %s" % piece.get_info())
			return get_card_based_moves(selected, piece, get_move_preview_player_id(selected, piece))
		else:
			print("No usable card on this piece.")
			return []

	return []

func get_move_preview_player_id(piece_position: Vector2, piece: Piece) -> int:
	var own_player_id: int = get_own_player_id()
	if can_control_current_turn() && can_player_control_piece_at(piece_position, own_player_id):
		return own_player_id
	return get_player_id_for_color(piece.color)

func get_card_based_moves(piece_position: Vector2, piece: Piece, player_id: int) -> Array:
	var valid_moves: Array[Vector2] = MoveRules.get_piece_moves_for_player(piece_objects, piece_position, player_id, BOARD_SIZE, current_board_effects)
	print("  Valid moves: ", valid_moves)
	return valid_moves

func is_valid_position(pos : Vector2):
	if pos.x >= 0 && pos.x < BOARD_SIZE && pos.y >= 0 && pos.y < BOARD_SIZE: return true
	return false

func is_empty(pos : Vector2):
	if board[pos.x][pos.y] == 0: return true
	return false

func is_enemy(pos : Vector2):
	if white && board[pos.x][pos.y] < 0 || !white && board[pos.x][pos.y] > 0: return true
	return false

func is_enemy_for_color(pos: Vector2, owner_color: int) -> bool:
	return board[pos.x][pos.y] * owner_color < 0

func is_current_player_piece(pos : Vector2) -> bool:
	return can_player_control_piece_at(pos, get_own_player_id())

func is_own_piece(pos: Vector2) -> bool:
	return is_piece_owned_by(pos, get_controllable_color())

func is_piece_owned_by(pos: Vector2, owner_color: int) -> bool:
	return board[pos.x][pos.y] * owner_color > 0

func can_player_control_piece_at(pos: Vector2, player_id: int) -> bool:
	if !piece_objects.has(pos):
		return false
	var piece: Piece = piece_objects[pos] as Piece
	return CardEffectResolver.can_player_control_piece(piece, player_id)

func can_control_current_turn() -> bool:
	return !game_over && (side == null || side == white)

func is_in_check(king_pos: Vector2):
	var directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
	Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]

	var pawn_direction: int = 1 if white else -1
	var pawn_attacks = [
		king_pos + Vector2(pawn_direction, 1),
		king_pos + Vector2(pawn_direction, -1)
	]

	for i in pawn_attacks:
		if is_valid_position(i):
			if white && board[i.x][i.y] == -1 || !white && board[i.x][i.y] == 1: return true

	for i in directions:
		var pos = king_pos + i
		if is_valid_position(pos):
			if white && board[pos.x][pos.y] == -6 || !white && board[pos.x][pos.y] == 6: return true

	for i in directions:
		var pos = king_pos + i
		while is_valid_position(pos):
			if !is_empty(pos):
				var piece = board[pos.x][pos.y]
				if (i.x == 0 || i.y == 0) && (white && piece in [-4, -5] || !white && piece in [4, 5]):
					return true
				elif (i.x != 0 && i.y != 0) && (white && piece in [-3, -5] || !white && piece in [3, 5]):
					return true
				break
			pos += i

	var knight_directions = [Vector2(2, 1), Vector2(2, -1), Vector2(1, 2), Vector2(1, -2),
	Vector2(-2, 1), Vector2(-2, -1), Vector2(-1, 2), Vector2(-1, -2)]

	for i in knight_directions:
		var pos = king_pos + i
		if is_valid_position(pos):
			if white && board[pos.x][pos.y] == -2 || !white && board[pos.x][pos.y] == 2:
				return true

	return false

func is_stalemate():
	return !current_player_has_valid_turn_action()

func update_from_server_state(pieces_data: Dictionary, player_hands: Dictionary, current_turn: int, server_game_over: bool = false, winner_player: int = -1, player_deck_sizes: Dictionary = {}, hidden_cards: Array = [], player_base_fields: Dictionary = {}, board_effects: Array = [], player_names: Dictionary = {}, recent_card_transfers: Array = [], recent_card_expirations: Array = []):
	var previous_white_hand_names: Array[String] = get_card_names_from_hand(white_card_hand)
	var previous_black_hand_names: Array[String] = get_card_names_from_hand(black_card_hand)

	board.clear()
	for i in BOARD_SIZE:
		board.append([0, 0, 0, 0, 0])

	piece_objects.clear()
	for pos in pieces_data:
		var data: Dictionary = pieces_data[pos]
		var piece_color: int = int(data.color)
		var piece_position: Vector2 = data.position
		var piece: Piece = Piece.new(piece_position, piece_color)
		var card_name: String = str(data.card_name)
		if !card_name.is_empty():
			var card: Card = CardLibrary.duplicate_card(card_name)
			if card:
				piece.attach_card(card)
				piece.turns_remaining = int(data.turns_remaining)

		piece_objects[piece_position] = piece
		if is_valid_position(piece_position):
			board[piece_position.x][piece_position.y] = piece_color

	var was_white_turn: bool = white
	white = current_turn == 0
	if was_white_turn != white:
		reset_current_turn_card_attach()

	var current_white_hand_names: Array = get_hand_names_from_state(player_hands, 0)
	var current_black_hand_names: Array = get_hand_names_from_state(player_hands, 1)
	if !player_deck_sizes.is_empty():
		white_deck_count_override = get_int_from_state_dict(player_deck_sizes, 0, white_card_deck.size())
		black_deck_count_override = get_int_from_state_dict(player_deck_sizes, 1, black_card_deck.size())
	current_player_base_fields = parse_player_base_fields(player_base_fields)
	current_board_effects = parse_board_effects(board_effects)
	current_player_names = parse_player_names(player_names)
	white_card_hand = create_card_hand_from_names(current_white_hand_names)
	black_card_hand = create_card_hand_from_names(current_black_hand_names)
	white_card_visuals = populate_card_hand(white_pieces, white_card_hand, 1)
	black_card_visuals = populate_card_hand(black_pieces, black_card_hand, -1)
	setup_deck_visuals()

	delete_dots()
	hide_hover_piece_details()
	update_hidden_card_previews(hidden_cards)
	update_card_presentation()
	display_board()
	if has_received_server_state:
		if recent_card_transfers.is_empty():
			animate_state_draw_if_needed(1, previous_white_hand_names, current_white_hand_names)
			animate_state_draw_if_needed(-1, previous_black_hand_names, current_black_hand_names)
		else:
			animate_recent_card_transfers(recent_card_transfers, previous_white_hand_names, current_white_hand_names, previous_black_hand_names, current_black_hand_names)
		animate_recent_card_expirations(recent_card_expirations)
	has_received_server_state = true

	if server_game_over && winner_player != -1:
		finish_game(get_color_for_player_id(winner_player))

func parse_player_names(player_names: Dictionary) -> Dictionary:
	var parsed_names: Dictionary = current_player_names.duplicate()
	for player_id in [0, 1]:
		if player_names.has(player_id):
			parsed_names[player_id] = GameConfig.sanitize_player_name(str(player_names[player_id]))
			continue

		var string_key: String = str(player_id)
		if player_names.has(string_key):
			parsed_names[player_id] = GameConfig.sanitize_player_name(str(player_names[string_key]))

	return parsed_names

func update_hidden_card_previews(hidden_cards: Array):
	clear_hidden_card_previews()
	if hidden_cards.is_empty():
		if hidden_card_preview_container:
			hidden_card_preview_container.visible = false
		return

	arrange_hidden_card_preview_container(hidden_cards.size())
	hidden_card_preview_container.visible = true

	var scaled_card_size: Vector2 = CARD_UI_SIZE * HIDDEN_CARD_SCALE
	for i in hidden_cards.size():
		var hidden_card_data: Dictionary = hidden_cards[i]
		var card_name: String = str(hidden_card_data.get("card_name", ""))
		if card_name.is_empty():
			continue

		var card: Card = CardLibrary.duplicate_card(card_name)
		if card == null:
			continue

		card.duration = int(hidden_card_data.get("turns_remaining", card.duration))
		var card_visual: CardVisual = CARD_VISUAL.instantiate() as CardVisual
		hidden_card_preview_container.add_child(card_visual)
		card_visual.set_hand_context(0, i, Vector2(0.0, i * (scaled_card_size.y + HIDDEN_CARD_GAP)))
		card_visual.set_card(card)
		card_visual.set_face_down(false)
		card_visual.draggable = false
		card_visual.disabled = true
		card_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_visual.scale = Vector2.ONE * HIDDEN_CARD_SCALE
		card_visual.z_index = 850 + i
		card_visual.set_ambient_motion_enabled(true)
		hidden_card_previews.append(card_visual)

func clear_hidden_card_previews():
	for card_visual: CardVisual in hidden_card_previews:
		if card_visual and is_instance_valid(card_visual):
			card_visual.set_ambient_motion_enabled(false)
			card_visual.queue_free()
	hidden_card_previews.clear()

func arrange_hidden_card_preview_container(card_count: int):
	if hidden_card_preview_container == null:
		return

	var scaled_card_size: Vector2 = CARD_UI_SIZE * HIDDEN_CARD_SCALE
	var total_height: float = float(card_count) * scaled_card_size.y + float(maxi(0, card_count - 1)) * HIDDEN_CARD_GAP
	var board_screen_width: float = BOARD_SIZE * CELL_WIDTH * get_board_screen_scale()
	var left_offset: float = -board_screen_width * 0.5 - HIDDEN_CARD_MARGIN - scaled_card_size.x
	hidden_card_preview_container.offset_left = left_offset
	hidden_card_preview_container.offset_right = left_offset + scaled_card_size.x
	hidden_card_preview_container.offset_top = -total_height * 0.5
	hidden_card_preview_container.offset_bottom = total_height * 0.5

func get_board_screen_scale() -> float:
	var camera: Camera2D = $"../Camera2D"
	if camera == null:
		return 1.0
	return absf(camera.zoom.x)

func parse_player_base_fields(player_base_fields: Dictionary) -> Dictionary:
	var parsed_fields: Dictionary = {
		0: WHITE_BASE_FIELD,
		1: BLACK_BASE_FIELD,
	}
	if player_base_fields.is_empty():
		return parsed_fields

	for player_id in [0, 1]:
		if player_base_fields.has(player_id):
			parsed_fields[player_id] = value_to_vector2(player_base_fields[player_id], parsed_fields[player_id])
			continue

		var string_key: String = str(player_id)
		if player_base_fields.has(string_key):
			parsed_fields[player_id] = value_to_vector2(player_base_fields[string_key], parsed_fields[player_id])

	return parsed_fields

func parse_board_effects(board_effects: Array) -> Array:
	var parsed_effects: Array = []
	for effect_value in board_effects:
		var effect: Dictionary = effect_value
		var parsed_squares: Array[Vector2] = []
		var square_values: Array = effect.get("squares", [])
		for square_value in square_values:
			var square_pos: Vector2 = value_to_vector2(square_value, INVALID_BOARD_POS)
			if is_valid_position(square_pos):
				parsed_squares.append(square_pos)

		parsed_effects.append({
			"effect_type": str(effect.get("effect_type", "")),
			"squares": parsed_squares,
		})

	return parsed_effects

func value_to_vector2(value, fallback: Vector2) -> Vector2:
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
		if dict_value.has("x") && dict_value.has("y"):
			return Vector2(float(dict_value.x), float(dict_value.y))
	return fallback

func update_board_markers():
	if board_markers_node == null:
		return

	for child in board_markers_node.get_children():
		child.queue_free()

	for effect_value in current_board_effects:
		var effect: Dictionary = effect_value
		var effect_type: String = str(effect.get("effect_type", ""))
		var squares: Array = effect.get("squares", [])
		for square_value in squares:
			var square_pos: Vector2 = value_to_vector2(square_value, INVALID_BOARD_POS)
			if !is_valid_position(square_pos):
				continue
			if effect_type == CardEffect.TYPE_INVALID_SQUARES:
				add_board_square_x_marker(square_pos, Color(1.0, 0.08, 0.06, 0.9), Color(1.0, 0.0, 0.0, 0.16))
			elif effect_type == CardEffect.TYPE_FROZEN_SQUARES:
				add_board_square_x_marker(square_pos, Color(0.08, 0.4, 1.0, 0.92), Color(0.0, 0.35, 1.0, 0.18))

	for player_id in [0, 1]:
		var base_pos: Vector2 = current_player_base_fields.get(player_id, WHITE_BASE_FIELD if player_id == 0 else BLACK_BASE_FIELD)
		if is_valid_position(base_pos):
			add_board_base_marker(base_pos, player_id)

func add_board_square_fill(board_pos: Vector2, marker_color: Color):
	var rect: Rect2 = get_board_cell_rect_local(board_pos)
	var marker := Polygon2D.new()
	marker.color = marker_color
	marker.polygon = PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y),
	])
	board_markers_node.add_child(marker)

func add_board_square_x_marker(board_pos: Vector2, line_color: Color, fill_color: Color):
	add_board_square_fill(board_pos, fill_color)
	var rect: Rect2 = get_board_cell_rect_local(board_pos).grow(-CELL_WIDTH * 0.22)
	add_board_line([rect.position, rect.position + rect.size], line_color, BOARD_MARKER_LINE_WIDTH)
	add_board_line([rect.position + Vector2(0.0, rect.size.y), rect.position + Vector2(rect.size.x, 0.0)], line_color, BOARD_MARKER_LINE_WIDTH)

func add_board_base_marker(board_pos: Vector2, player_id: int):
	var outer_rect: Rect2 = get_board_cell_rect_local(board_pos).grow(-CELL_WIDTH * 0.08)
	var marker_color: Color = Color(1.0, 1.0, 1.0, 1.0) if player_id == 0 else Color(0.0, 0.0, 0.0, 1.0)
	add_board_rect_outline(outer_rect, marker_color, BOARD_MARKER_LINE_WIDTH * 1.5)

func add_board_rect_outline(rect: Rect2, line_color: Color, line_width: float):
	add_board_line([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y),
		rect.position,
	], line_color, line_width)

func add_board_line(points: Array, line_color: Color, line_width: float):
	var line := Line2D.new()
	line.default_color = line_color
	line.width = line_width
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	for point_value in points:
		line.add_point(point_value)
	board_markers_node.add_child(line)

func get_board_cell_rect_local(board_pos: Vector2) -> Rect2:
	var center: Vector2 = get_board_position_local_position(board_pos)
	return Rect2(center - Vector2.ONE * CELL_WIDTH * 0.5, Vector2.ONE * CELL_WIDTH)
