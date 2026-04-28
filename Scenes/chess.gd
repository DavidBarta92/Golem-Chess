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
const STARTING_PLAYER_HAND_SIZE = 3
const PLAYER_DECK_SIZE = 24
const CARD_UI_SIZE = Vector2(112, 156)
const CARD_UI_GAP = 12
const CARD_HAND_MARGIN = 18
const HOVER_CARD_MARGIN = 24
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
var game_over: bool = false
var hover_card_preview: CardVisual
var hover_duration_label: Label
var result_overlay: ColorRect
var result_label: Label

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
	board.append([1, 1, 1, 1, 1])
	board.append([0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0])
	board.append([-1, -1, -1, -1, -1])

	create_pieces_from_board()
	setup_player_card_hands()
	create_hover_piece_ui()
	create_result_ui()

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
				print("đź”· Piece lĂ©trehozva: pos=%s, color=%s" % [pos, "fehĂ©r" if color > 0 else "fekete"])

	print("Babuk letrehozva kezdokartya nelkul.")

func setup_player_card_hands():
	white_card_deck = create_random_card_deck()
	black_card_deck = create_random_card_deck()
	white_card_hand = draw_cards_from_deck(1, STARTING_PLAYER_HAND_SIZE)
	black_card_hand = draw_cards_from_deck(-1, STARTING_PLAYER_HAND_SIZE)

	white_card_visuals = populate_card_hand(white_pieces, white_card_hand, 1)
	black_card_visuals = populate_card_hand(black_pieces, black_card_hand, -1)
	setup_deck_visuals()
	update_card_presentation()

func create_random_card_deck() -> Array[String]:
	var deck: Array[String] = []
	var card_names: Array = CardLibrary.get_all_card_names()

	if card_names.is_empty():
		push_warning("Nincs betoltott kartya, nem lehet paklit generalni!")
		return deck

	for i in PLAYER_DECK_SIZE:
		var card_name: String = str(card_names[randi() % card_names.size()])
		deck.append(card_name)

	return deck

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
		deck.append_array(create_random_card_deck())
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

func update_card_drag_permissions():
	var active_color: int = get_controllable_color()
	var can_drag: bool = can_control_current_turn()
	for card_visual in white_card_visuals:
		card_visual.draggable = can_drag && card_visual.owner_color == active_color
	for card_visual in black_card_visuals:
		card_visual.draggable = can_drag && card_visual.owner_color == active_color

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
	attached_card_this_turn[get_current_turn_color()] = false

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
	if is_valid_position(board_pos) && is_piece_owned_by(board_pos, card_visual.owner_color) && can_attach_card_to_piece(board_pos):
		return board_pos

	return INVALID_BOARD_POS

func attach_card_visual_to_piece(card_visual: CardVisual, piece_position: Vector2):
	if not piece_objects.has(piece_position) or card_visual.card == null:
		card_visual.fly_home()
		return
	if has_attached_card_this_turn(card_visual.owner_color):
		card_visual.fly_home()
		return
	if !can_attach_card_to_piece(piece_position):
		card_visual.fly_home()
		return

	var card_name: String = card_visual.card.card_name
	var hand_index: int = get_card_visual_index(card_visual)
	if GameController.current_game_host:
		send_card_attach_action(card_visual.owner_color, card_name, piece_position, hand_index)
		card_visual.assign_and_hide()
		mark_card_attached_this_turn(card_visual.owner_color)
		return

	if !apply_card_to_piece(piece_position, card_name):
		card_visual.fly_home()
		return

	var replacement_card_name: String = remove_card_from_hand(card_visual)
	mark_card_attached_this_turn(card_visual.owner_color)

	if get_parent().has_method("send_card_attach"):
		get_parent().send_card_attach(piece_position, card_name, card_visual.owner_color, hand_index, replacement_card_name)

func send_card_attach_action(owner_color: int, card_name: String, piece_position: Vector2, hand_index: int):
	var action: Dictionary = {
		"type": "attach_card",
		"player_id": get_player_id_for_color(owner_color),
		"card_name": card_name,
		"piece_pos": piece_position,
		"hand_index": hand_index,
	}
	GameController.send_action(action)

func can_attach_card_to_piece(piece_position: Vector2) -> bool:
	if not piece_objects.has(piece_position):
		return false

	var piece: Piece = piece_objects[piece_position] as Piece
	return piece.attached_card == null

func apply_card_to_piece(piece_position: Vector2, card_name: String) -> bool:
	if not piece_objects.has(piece_position):
		return false

	var piece: Piece = piece_objects[piece_position] as Piece
	if piece.attached_card != null:
		push_warning("Ehhez a babuhoz mar tartozik kartya: %s" % piece_position)
		return false

	var card: Card = CardLibrary.duplicate_card(card_name)
	if card == null:
		push_warning("Nem talalhato kartya a babuhoz csatolashoz: %s" % card_name)
		return false

	piece.attach_card(card)
	display_board()
	return true

func apply_remote_card_attach(piece_position: Vector2, card_name: String, owner_color: int, hand_index: int, replacement_card_name: String = ""):
	if apply_card_to_piece(piece_position, card_name):
		remove_card_from_hand_index(owner_color, hand_index, true, replacement_card_name)

func remove_card_from_hand(card_visual: CardVisual) -> String:
	return remove_card_from_hand_index(card_visual.owner_color, get_card_visual_index(card_visual), true)

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
		push_warning("Nem talalhato kartya huzashoz: %s" % card_name)
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

func _input(event):
	if can_control_current_turn():
		if event is InputEventMouseButton && event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if is_mouse_out(): return
				var local_pos: Vector2 = to_local(get_global_mouse_position())

				var offset = (BOARD_SIZE * CELL_WIDTH) / 2.0
				var adjusted_x = local_pos.x + offset
				var adjusted_y = -local_pos.y + offset

				var var1 = int(adjusted_x / CELL_WIDTH)
				var var2 = int(adjusted_y / CELL_WIDTH)

				print("KattintĂˇs: grid=(", var1, ",", var2, ") board[", var2, "][", var1, "]=", board[var2][var1] if var2 < BOARD_SIZE && var1 < BOARD_SIZE else "invalid")

				if var1 < 0 || var1 >= BOARD_SIZE || var2 < 0 || var2 >= BOARD_SIZE:
					return

				if !state && (white && board[var2][var1] > 0 || !white && board[var2][var1] < 0):
					selected_piece = Vector2(var2, var1)
					show_options()
					state = true
				elif state:
					if moves.has(Vector2(var2, var1)):
						send_move_action(selected_piece, Vector2(var2, var1))

					delete_dots()
					state = false
					hovered_piece = Vector2(-1, -1)
					hide_hover_piece_details()

func send_move_action(from_pos: Vector2, to_pos: Vector2):
	if GameController.current_game_host:
		var action: Dictionary = {
			"type": "move_piece",
			"player_id": get_own_player_id(),
			"from": from_pos,
			"to": to_pos,
		}
		GameController.send_action(action)
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
	print("đźŽ¨ display_board() hĂ­vva: white=", white, " side=", side)
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

	print("đź”„ set_move KEZDĂ‰S: white=", white, " start=", start_pos, " end=", end_pos, " bĂˇbu=", board[start_pos.x][start_pos.y])
	var moving_color: int = 1 if board[start_pos.x][start_pos.y] > 0 else -1

	if piece_objects.has(start_pos):
		var piece: Piece = piece_objects[start_pos] as Piece
		piece.position = end_pos
		piece_objects.erase(start_pos)
		piece_objects[end_pos] = piece
		print("  đź”· Piece mozgatva: %s -> %s" % [start_pos, end_pos])

	var just_now = false

	board[end_pos.x][end_pos.y] = board[start_pos.x][start_pos.y]
	board[start_pos.x][start_pos.y] = 0

	if piece_objects.has(end_pos):
		var piece: Piece = piece_objects[end_pos] as Piece
		if piece.attached_card:
			piece.use_turn()

	var winner_color: int = get_winner_after_move(moving_color, end_pos)
	if winner_color != 0:
		display_board()
		finish_game(winner_color)
		return

	white = !white
	reset_current_turn_card_attach()
	update_card_presentation()
	print("âś… set_move VĂ‰GE: white MOST=", white)

	display_board()

	if (start_pos.x != end_pos.x || start_pos.y != end_pos.y) && (white && board[end_pos.x][end_pos.y] > 0 || !white && board[end_pos.x][end_pos.y] < 0):
		start_pos = end_pos
		show_options()
		state = true
	elif is_stalemate():
		print("DRAW")

func get_winner_after_move(moving_color: int, end_pos: Vector2) -> int:
	if is_opponent_base_field(moving_color, end_pos):
		return moving_color
	if !has_any_piece(-moving_color):
		return moving_color
	return 0

func is_opponent_base_field(moving_color: int, pos: Vector2) -> bool:
	if moving_color == 1:
		return pos == BLACK_BASE_FIELD
	return pos == WHITE_BASE_FIELD

func has_any_piece(owner_color: int) -> bool:
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			if board[i][j] * owner_color > 0:
				return true
	return false

func finish_game(winner_color: int):
	if game_over:
		return

	game_over = true
	state = false
	hovered_piece = Vector2(-1, -1)
	delete_dots()
	hide_hover_piece_details()
	update_card_drag_permissions()
	show_result_message(winner_color)

	await get_tree().create_timer(8.0).timeout
	if get_parent().has_method("close_game_connection"):
		get_parent().close_game_connection()
	if get_tree():
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func show_result_message(winner_color: int):
	if result_label == null or result_overlay == null:
		return

	if side == null:
		result_label.text = "FEHĂ‰R NYERT!" if winner_color == 1 else "FEKETE NYERT!"
	else:
		result_label.text = "NYERTĂ‰L!" if winner_color == get_own_color() else "VESZTETTĂ‰L!"
	result_overlay.visible = true

func get_moves(selected : Vector2):
	if piece_objects.has(selected):
		var piece: Piece = piece_objects[selected] as Piece
		if piece.can_move():
			print("đźŽ´ KĂˇrtya mozgĂˇs hasznĂˇlata: %s" % piece.get_info())
			return get_card_based_moves(selected, piece)
		else:
			print("âš ď¸Ź Nincs hasznĂˇlhatĂł kĂˇrtya ezen a bĂˇbun!")
			return []

	return []

func get_card_based_moves(piece_position: Vector2, piece: Piece) -> Array:
	var _moves: Array = []
	var directions: Array = piece.get_movement_directions()

	print("  đź“Ť IrĂˇnyok: ", directions)

	for direction: Vector2 in directions:
		var target_pos: Vector2 = piece_position + (direction * piece.color)

		if !is_valid_position(target_pos):
			continue

		if is_empty(target_pos) || is_enemy_for_color(target_pos, piece.color):
			var original_value: int = board[target_pos.x][target_pos.y]
			board[target_pos.x][target_pos.y] = board[piece_position.x][piece_position.y]
			board[piece_position.x][piece_position.y] = 0

			_moves.append(target_pos)

			board[piece_position.x][piece_position.y] = board[target_pos.x][target_pos.y]
			board[target_pos.x][target_pos.y] = original_value

	print("  âś… Ă‰rvĂ©nyes lĂ©pĂ©sek: ", _moves)
	return _moves

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
	return white && board[pos.x][pos.y] > 0 || !white && board[pos.x][pos.y] < 0

func is_own_piece(pos: Vector2) -> bool:
	return is_piece_owned_by(pos, get_controllable_color())

func is_piece_owned_by(pos: Vector2, owner_color: int) -> bool:
	return board[pos.x][pos.y] * owner_color > 0

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
	if white:
		for i in BOARD_SIZE:
			for j in BOARD_SIZE:
				if board[i][j] > 0:
					if get_moves(Vector2(i, j)) != []: return false

	else:
		for i in BOARD_SIZE:
			for j in BOARD_SIZE:
				if board[i][j] < 0:
					if get_moves(Vector2(i, j)) != []: return false
	return true

func update_from_server_state(pieces_data: Dictionary, player_hands: Dictionary, current_turn: int, server_game_over: bool = false, winner_player: int = -1):
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

	white_card_hand = create_card_hand_from_names(get_hand_names_from_state(player_hands, 0))
	black_card_hand = create_card_hand_from_names(get_hand_names_from_state(player_hands, 1))
	white_card_visuals = populate_card_hand(white_pieces, white_card_hand, 1)
	black_card_visuals = populate_card_hand(black_pieces, black_card_hand, -1)
	setup_deck_visuals()

	delete_dots()
	hide_hover_piece_details()
	update_card_presentation()
	display_board()

	if server_game_over && winner_player != -1:
		finish_game(get_color_for_player_id(winner_player))
