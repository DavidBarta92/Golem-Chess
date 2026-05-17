extends Sprite2D

signal piece_selected(piece_pos: Vector2, player_id: int)
signal card_attached(piece_pos: Vector2, card_name: String, owner_color: int, hand_index: int)
signal piece_moved(from_pos: Vector2, to_pos: Vector2, owner_color: int)
signal card_exchanged(card_name: String, owner_color: int, hand_index: int)
signal turn_ended(ending_color: int, next_color: int)
signal tutorial_action_rejected(action_name: String, context: Dictionary)

const BOARD_SIZE: int = BoardConfig.BOARD_SIZE
const CELL_WIDTH: int = BoardConfig.CELL_WIDTH

const TEXTURE_HOLDER = preload("res://Scenes/texture_holder.tscn")
const CARD_VISUAL = preload("res://Scenes/CardVisual.tscn")

const DEFAULT_PIECE_TEXTURE = preload("res://Assets/king.svg")
const OWN_DEFAULT_PIECE_TEXTURE = preload("res://Assets/king_back.svg")

const TURN_WHITE = preload("res://Assets/turn-white.png")
const TURN_BLACK = preload("res://Assets/turn-black.png")

const PIECE_MOVE = preload("res://Assets/Piece_move.png")
const PIECE_EXHAUSTED_SHADER = preload("res://Shaders/piece_exhausted.gdshader")
const OPPONENT_PIECE_RECOLOR_SHADER = preload("res://Shaders/opponent_piece_recolor.gdshader")
const PIECE_ATTACH_GLOW_SHADER = preload("res://Shaders/piece_attach_glow.gdshader")
const PIECE_ATTACH_RAYS_SHADER = preload("res://Shaders/piece_attach_rays.gdshader")
const PIECE_TEXTURE_MORPH_SHADER = preload("res://Shaders/piece_texture_morph.gdshader")
const BOARD_VISUAL_SCALE: float = 1.08
# Adjust these values to tune the board-only perspective tilt.
const BOARD_PERSPECTIVE_ENABLED: bool = true
const BOARD_PERSPECTIVE_TOP_SCALE: float = 0.74
const BOARD_PERSPECTIVE_BOTTOM_SCALE: float = 1.05
const BOARD_PERSPECTIVE_VERTICAL_SCALE: float = 0.72
const BOARD_TILE_LIGHT_COLOR = Color(0.561, 0.427, 0.165, 1.0)
const BOARD_TILE_DARK_COLOR = Color(0.408, 0.302, 0.110, 1.0)
const DEFAULT_PIECE_VISUAL_HEIGHT: float = 24.0
const DEFAULT_PIECE_BOTTOM_INSET: float = 1.5
const PIECE_PERSPECTIVE_SCALE_VARIATION: float = 0.10
const PIECE_SHADOW_NAME = "PieceShadow"
const PIECE_SHADOW_LIGHT_TEXTURE_SCALE: float = 0.22
const PIECE_SHADOW_LIGHT_SOURCE_OFFSET: float = 8.0
const PIECE_SHADOW_LIGHT_ENERGY: float = 0.30
const PIECE_SHADOW_LIGHT_COLOR = Color(1.0, 0.92, 0.72, 1.0)
const PIECE_SHADOW_LIGHT_SHADOW_COLOR = Color(0.0, 0.0, 0.0, 0.88)
const PIECE_SHADOW_LIGHT_SHADOW_SMOOTH: float = 0.0
const PIECE_LIGHT_OCCLUDER_NAME = "PieceLightOccluder"
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_WIDTH_FACTOR: float = 0.68
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_HEIGHT_FACTOR: float = 0.20
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_BOTTOM_INSET_FACTOR: float = 0.05
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_OFFSET = Vector2.ZERO
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_SEGMENTS: int = 18
const BOARD_LIGHT_RECEIVE_MASK: int = 1
const PIECE_LIGHT_OCCLUDER_MASK: int = 1
const PIECE_LIGHT_RECEIVE_MASK: int = 2
const PIECE_EFFECT_LIGHT_RECEIVE_MASK: int = 0
const ATTACH_POINT_LIGHT_NAME = "AttachPointLight"
const ATTACH_PIECE_LIGHT_NAME = "AttachPieceLight"
const ATTACH_POINT_LIGHT_TEXTURE_SIZE: int = 256
const ATTACH_POINT_LIGHT_TEXTURE_SCALE: float = 0.92
const ATTACH_POINT_LIGHT_ENERGY: float = 1.25
const ATTACH_POINT_LIGHT_COLOR = Color(1.0, 0.74, 0.24, 1.0)
const ATTACH_POINT_LIGHT_SHADOW_COLOR = Color(0.0, 0.0, 0.0, 0.52)
const ATTACH_POINT_LIGHT_SHADOW_SMOOTH: float = 2.5
const ATTACH_PIECE_LIGHT_TEXTURE_SCALE: float = 1.08
const ATTACH_PIECE_LIGHT_ENERGY: float = 0.62
const ATTACH_PIECE_LIGHT_COLOR = Color(1.0, 0.84, 0.36, 1.0)
const LIGHT_TEXTURE_GRAIN_STRENGTH: float = 0.12
const LIGHT_TEXTURE_FINE_GRAIN_STRENGTH: float = 0.045
const LIGHT_TEXTURE_GRAIN_FREQUENCY: float = 0.085
const LIGHT_TEXTURE_FINE_GRAIN_FREQUENCY: float = 0.31
const AMBIENT_BOARD_LIGHT_NAME = "AmbientBoardLight"
const AMBIENT_BOARD_FILL_LIGHT_NAME = "AmbientBoardFillLight"
const AMBIENT_BOARD_LIGHT_TEXTURE_SCALE: float = 0.92
const AMBIENT_BOARD_FILL_LIGHT_TEXTURE_SCALE: float = 2.35
const AMBIENT_BOARD_LIGHT_OFFSET = Vector2.ZERO
const AMBIENT_BOARD_LIGHT_ENERGY: float = 0.32
const AMBIENT_BOARD_FILL_LIGHT_ENERGY: float = 0.16
const AMBIENT_BOARD_LIGHT_COLOR = Color(1.0, 0.86, 0.58, 1.0)
const AMBIENT_BOARD_LIGHT_SHADOW_COLOR = Color(0.0, 0.0, 0.0, 0.50)
const AMBIENT_BOARD_LIGHT_SHADOW_SMOOTH: float = 2.0
const OPPONENT_PIECE_RECOLOR_STRENGTH: float = 0.86
const OPPONENT_PIECE_SHADOW_CHROMA: float = 0.16
const OPPONENT_PIECE_SHADOW_COLOR = Color(0.30, 0.33, 0.38, 1.0)
const OPPONENT_PIECE_MID_COLOR = Color(0.55, 0.57, 0.60, 1.0)
const OPPONENT_PIECE_HIGHLIGHT_COLOR = Color(0.78, 0.79, 0.80, 1.0)

const PLAYER_HAND_SIZE = DeckManager.HAND_SIZE
const CARD_UI_SIZE = Vector2(164, 229)
const CARD_HAND_SCALE = 0.648
const DECK_CARD_SCALE = CARD_HAND_SCALE
const CARD_UI_GAP = 10
const TOP_CARD_HAND_MARGIN = -28
const BOTTOM_CARD_HAND_MARGIN = 34
const HOVER_CARD_MARGIN = 24
const HOVER_DESCRIPTION_GAP = 14
const HOVER_DESCRIPTION_SIZE = Vector2(260, 118)
const HIDDEN_CARD_MARGIN = 24
const HIDDEN_CARD_GAP = 10
const HIDDEN_CARD_SCALE = 0.70 * 0.75
const HIDDEN_CARD_PREVIEW_ALPHA: float = 0.70
const BOARD_MARKER_LINE_WIDTH = 1.8
const SELECTED_PIECE_GLOW_NAME = "SelectedPieceGlow"
const SELECTED_PIECE_GLOW_Z_INDEX = 24
const SELECTED_PIECE_GLOW_STRENGTH: float = 1.0
const PIECE_ATTACH_GLOW_NAME = "PieceAttachGlow"
const PIECE_ATTACH_RAYS_NAME = "PieceAttachRays"
const PIECE_ATTACH_MORPH_NAME = "PieceAttachMorph"
const PIECE_ATTACH_GLOW_Z_INDEX = 30
const PIECE_ATTACH_RAYS_Z_INDEX = 31
const PIECE_ATTACH_MORPH_Z_INDEX = 33
const PIECE_ATTACH_GLOW_COLOR = Color(1.0, 0.82, 0.28, 1.0)
const PIECE_ATTACH_GLOW_SIZE: float = 4.8
const PIECE_ATTACH_GLOW_FILL_STRENGTH: float = 0.30
const PIECE_ATTACH_GLOW_BASE_STRENGTH: float = 1.0
const PIECE_ATTACH_GLOW_SWITCH_STRENGTH: float = 4.0
const PIECE_ATTACH_GLOW_SWITCH_DURATION: float = 0.06
const PIECE_ATTACH_IN_DURATION: float = 0.32
const PIECE_ATTACH_PRE_SWITCH_HOLD_DURATION: float = 0.14
const PIECE_ATTACH_MORPH_DURATION: float = 1.00
const PIECE_ATTACH_POST_SWITCH_HOLD_DURATION: float = 0.20
const PIECE_ATTACH_OUT_DURATION: float = 0.32
const PIECE_ATTACH_MORPH_NOISE_STRENGTH: float = 0.14
const PIECE_ATTACH_MORPH_SHINE_STRENGTH: float = 0.34
const PIECE_ATTACH_RAYS_START_SIZE: float = 10.0
const PIECE_ATTACH_RAYS_SWITCH_SIZE: float = 1.0
const PIECE_ATTACH_RAYS_TEXTURE_SIZE: int = 256
const PIECE_ATTACH_RAYS_OVERLAY_SCALE: float = 2.65
const PIECE_ATTACH_RAYS_LOCAL_OFFSET = Vector2.ZERO
const PIECE_ATTACH_RAYS_SPREAD: float = 0.5
const PIECE_ATTACH_RAYS_CUTOFF: float = 0.39
const PIECE_ATTACH_RAYS_SPEED: float = 1.4
const PIECE_ATTACH_RAYS_RAY1_DENSITY: float = 8.0
const PIECE_ATTACH_RAYS_RAY2_DENSITY: float = 10.0
const PIECE_ATTACH_RAYS_RAY2_INTENSITY: float = 0.3
const PIECE_ATTACH_RAYS_CORE_INTENSITY: float = 2.0
const PIECE_ATTACH_RAYS_SEED: float = 5.0
const PIECE_ATTACH_RAYS_FADE_IN_DELAY_RATIO: float = 0.0
const PIECE_ATTACH_RAYS_FADE_IN_DURATION_RATIO: float = 1.0
const LAST_MOVE_ARROW_WIDTH = 3.0
const LAST_MOVE_ARROW_ENDPOINT_INSET = 6.0
const LAST_MOVE_ARROW_HEAD_LENGTH = 8.0
const LAST_MOVE_ARROW_HEAD_HALF_WIDTH = 5.0
const LAST_MOVE_ARROW_COLOR = Color(1.0, 0.88, 0.18, 1.0)
const DECK_COUNT_LABEL_SIZE = Vector2(88, 28)
const DECK_COUNT_LABEL_GAP = 8
const PLAYER_NAME_LABEL_SIZE = Vector2(180, 28)
const PLAYER_NAME_LABEL_GAP = 8
const RULES_INFO_BUTTON_SIZE = Vector2(40, 40)
const RULES_INFO_PANEL_SIZE = Vector2(310, 286)
const RULES_INFO_PANEL_MARGIN = 24
const ACTION_STATUS_SIZE = Vector2(118, 98)
const ACTION_STATUS_MARGIN = 22
const ACTION_STATUS_ACTIVE_COLOR = Color(1.0, 1.0, 1.0, 1.0)
const ACTION_STATUS_INACTIVE_COLOR = Color(0.42, 0.42, 0.42, 1.0)
const INVALID_BOARD_POS = Vector2(-1, -1)
const WHITE_BASE_FIELD: Vector2 = BoardConfig.WHITE_BASE_FIELD
const BLACK_BASE_FIELD: Vector2 = BoardConfig.BLACK_BASE_FIELD
const MAIN_MENU_SCENE = "res://Scenes/MainMenu.tscn"
const CARD_BURN_SEQUENCE_GAP = 0.08
const TUTORIAL_ACTION_SELECT_PIECE = "select_piece"
const TUTORIAL_ACTION_ATTACH_CARD = "attach_card"
const TUTORIAL_ACTION_MOVE_PIECE = "move_piece"
const TUTORIAL_ACTION_EXCHANGE_CARD = "exchange_card"
const TUTORIAL_ACTION_END_TURN = "end_turn"
const RULES_INFO_TEXT: String = "Goal: attach a Nexus card to one of your pieces, then move that Nexus onto the opponent's base square.\n\nTurn flow:\n1. Play any number of cards from your hand onto your empty pieces.\n2. Move one ready piece using its attached card pattern.\n3. End your turn. Each card you played is replaced from your deck.\n\nCards:\n- Your hand holds up to 3 cards.\n- Once per turn, drag a hand card onto your deck to replace it.\n- Duration only drops when that piece moves.\n\nCaptures:\n- Captured pieces respawn on an empty home-row square.\n- Their attached card is removed. Nexus cards return to their owner's deck."

@onready var pieces_node = $Pieces
@onready var dots = $Dots
@onready var turn = $Turn
@onready var board_tiles_node = $BoardTiles
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
var exchanged_card_this_turn: Dictionary = {
	1: false,
	-1: false,
}
var played_card_hand_slots_this_turn: Dictionary = {
	1: [],
	-1: [],
}
var pending_card_attach_positions: Dictionary = {}
var active_card_attach_process_count: int = 0
var exchanged_card_names_this_turn: Dictionary = {
	1: [],
	-1: [],
}
var game_over: bool = false
var hover_card_preview: CardVisual
var hover_duration_label: Label
var hover_description_panel: PanelContainer
var hover_description_label: Label
var result_overlay: ColorRect
var result_label: Label
var has_received_server_state: bool = false
var deck_count_label: Label
var player_name_labels: Dictionary = {}
var quit_confirmation_dialog: ConfirmationDialog
var end_turn_button: Button
var rules_info_button: Button
var rules_info_panel: PanelContainer
var rules_info_label: Label
var action_status_container: VBoxContainer
var action_status_labels: Dictionary = {}
var white_deck_count_override: int = -1
var black_deck_count_override: int = -1
var hidden_card_preview_container: Control
var hidden_card_previews: Array[CardVisual] = []
var board_markers_node: Node2D
var attach_point_light_texture: Texture2D
var piece_attach_rays_square_texture: Texture2D
var ambient_board_light: PointLight2D
var ambient_board_fill_light: PointLight2D
var current_last_move: Dictionary = {}
var current_board_effects: Array = []
var current_player_base_fields: Dictionary = {
	0: WHITE_BASE_FIELD,
	1: BLACK_BASE_FIELD,
}
var current_player_names: Dictionary = {
	0: "Player",
	1: "Player",
}
var pending_card_burn_animations: Array = []
var card_burn_animation_sequence_running: bool = false
var local_auto_end_turn_pending: bool = false
var tutorial_mode_active: bool = false
var tutorial_constraints_enabled: bool = false
var tutorial_constraints: Dictionary = {}

var side

func set_turn(_turn):
	side = _turn
	reset_current_turn_card_attach()
	update_card_presentation()
	create_board_tiles()
	display_board()
	if side != null && !side:
		$"../Camera2D".global_rotation_degrees = 180
	else:
		$"../Camera2D".global_rotation_degrees = 0

func _ready():
	randomize()
	texture = null
	apply_board_visual_scale()
	create_board_tiles()
	create_board_markers_node()
	create_ambient_board_light()
	board = BoardConfig.create_starting_board()

	create_pieces_from_board()
	setup_player_card_hands()
	create_hover_piece_ui()
	create_hidden_card_preview_ui()
	create_result_ui()
	create_deck_count_ui()
	create_player_name_ui()
	create_quit_confirmation_ui()
	create_end_turn_ui()
	create_rules_info_ui()
	create_action_status_ui()
	update_player_name_labels()

func apply_board_visual_scale() -> void:
	scale = Vector2.ONE * BOARD_VISUAL_SCALE

func set_tutorial_constraints(constraints: Dictionary) -> void:
	tutorial_constraints = constraints.duplicate(true)
	tutorial_constraints_enabled = !tutorial_constraints.is_empty() && bool(tutorial_constraints.get("enabled", true))
	refresh_tutorial_dependent_ui()

func set_tutorial_mode_active(active: bool) -> void:
	tutorial_mode_active = active

func clear_tutorial_constraints() -> void:
	tutorial_constraints.clear()
	tutorial_constraints_enabled = false
	refresh_tutorial_dependent_ui()

func refresh_tutorial_dependent_ui() -> void:
	update_card_drag_permissions()
	update_end_turn_button()
	update_action_status_ui()
	if state:
		show_options()

func is_tutorial_action_allowed(action_name: String, context: Dictionary = {}, emit_rejection: bool = false) -> bool:
	if !tutorial_constraints_enabled:
		return true
	if !is_tutorial_action_name_allowed(action_name):
		return reject_tutorial_action(action_name, context, emit_rejection)

	var allowed: bool = true
	match action_name:
		TUTORIAL_ACTION_SELECT_PIECE:
			if context.has("piece_pos"):
				allowed = tutorial_vector_allowed(["allowed_select_piece_positions", "allowed_move_sources", "allowed_piece_positions", "allowed_pieces"], context.get("piece_pos"))
		TUTORIAL_ACTION_ATTACH_CARD:
			if context.has("piece_pos"):
				allowed = allowed && tutorial_vector_allowed(["allowed_attach_piece_positions", "allowed_piece_positions", "allowed_pieces"], context.get("piece_pos"))
			if context.has("card_name"):
				allowed = allowed && tutorial_string_allowed(["allowed_attach_card_names", "allowed_card_names", "allowed_cards"], str(context.get("card_name", "")))
		TUTORIAL_ACTION_MOVE_PIECE:
			if context.has("from_pos"):
				allowed = allowed && tutorial_vector_allowed(["allowed_move_sources", "allowed_piece_positions", "allowed_pieces"], context.get("from_pos"))
			if context.has("to_pos"):
				allowed = allowed && tutorial_vector_allowed(["allowed_move_targets"], context.get("to_pos"))
		TUTORIAL_ACTION_EXCHANGE_CARD:
			if context.has("card_name"):
				allowed = allowed && tutorial_string_allowed(["allowed_exchange_card_names", "allowed_card_names", "allowed_cards"], str(context.get("card_name", "")))

	if !allowed:
		return reject_tutorial_action(action_name, context, emit_rejection)
	return true

func is_tutorial_action_name_allowed(action_name: String) -> bool:
	if !tutorial_constraints.has("allowed_actions"):
		return true
	var allowed_actions: Array = tutorial_constraint_array(["allowed_actions"])
	return allowed_actions.has(action_name)

func reject_tutorial_action(action_name: String, context: Dictionary, emit_rejection: bool) -> bool:
	if emit_rejection:
		tutorial_action_rejected.emit(action_name, context.duplicate(true))
	return false

func tutorial_string_allowed(keys: Array, candidate: String) -> bool:
	if !has_tutorial_constraint(keys):
		return true
	var allowed_values: Array = tutorial_constraint_array(keys)
	for value in allowed_values:
		if str(value) == candidate:
			return true
	return false

func tutorial_vector_allowed(keys: Array, candidate) -> bool:
	if !has_tutorial_constraint(keys):
		return true
	var allowed_values: Array = tutorial_constraint_array(keys)

	var candidate_pos: Vector2 = value_to_vector2(candidate, INVALID_BOARD_POS)
	if candidate_pos == INVALID_BOARD_POS:
		return false
	for value in allowed_values:
		if value_to_vector2(value, INVALID_BOARD_POS) == candidate_pos:
			return true
	return false

func tutorial_constraint_array(keys: Array) -> Array:
	for key_value in keys:
		var key: String = str(key_value)
		if !tutorial_constraints.has(key):
			continue
		var value = tutorial_constraints[key]
		if value is Array:
			return value
	return []

func has_tutorial_constraint(keys: Array) -> bool:
	for key_value in keys:
		if tutorial_constraints.has(str(key_value)):
			return true
	return false

func can_auto_end_turn_now() -> bool:
	if !tutorial_constraints_enabled:
		return true
	return bool(tutorial_constraints.get("allow_auto_end_turn", false))

func apply_tutorial_setup(setup: Dictionary) -> void:
	if setup.has("board"):
		set_tutorial_board_from_array(setup.get("board", []))
	if setup.has("attached_cards"):
		set_tutorial_attached_cards(setup.get("attached_cards", []))
	if setup.has("white_hand"):
		set_tutorial_card_hand(1, setup.get("white_hand", []))
	if setup.has("black_hand"):
		set_tutorial_card_hand(-1, setup.get("black_hand", []))
	if setup.has("white_deck"):
		set_tutorial_card_deck(1, setup.get("white_deck", []))
	if setup.has("black_deck"):
		set_tutorial_card_deck(-1, setup.get("black_deck", []))
	if setup.has("turn_color"):
		set_tutorial_turn(int(setup.get("turn_color", 1)))
	if bool(setup.get("reset_turn_state", true)):
		reset_tutorial_turn_state()

	update_card_presentation()
	display_board()

func set_tutorial_board_from_array(board_data: Array) -> void:
	if board_data.is_empty():
		return

	board = BoardConfig.create_empty_board()
	for row in range(mini(board_data.size(), BOARD_SIZE)):
		var row_data: Array = board_data[row] if board_data[row] is Array else []
		for col in range(mini(row_data.size(), BOARD_SIZE)):
			board[row][col] = int(row_data[col])

	piece_objects.clear()
	create_pieces_from_board()
	current_board_effects.clear()
	current_last_move.clear()
	state = false
	delete_dots()

func set_tutorial_attached_cards(attached_cards: Array) -> void:
	for entry_value in attached_cards:
		if !(entry_value is Dictionary):
			continue

		var entry: Dictionary = entry_value
		var piece_pos: Vector2 = value_to_vector2(entry.get("pos", INVALID_BOARD_POS), INVALID_BOARD_POS)
		if !piece_objects.has(piece_pos):
			continue

		var card_name: String = str(entry.get("card_name", ""))
		var card: Card = CardLibrary.duplicate_card(card_name)
		if card == null:
			push_warning("Tutorial attached card not found: %s" % card_name)
			continue

		var piece: Piece = piece_objects[piece_pos] as Piece
		piece.attach_card(card, bool(entry.get("exhausted", false)))
		piece.turns_remaining = int(entry.get("turns_remaining", card.duration))

func reset_tutorial_turn_state() -> void:
	for owner_color in [1, -1]:
		attached_card_this_turn[owner_color] = false
		moved_piece_this_turn[owner_color] = false
		exchanged_card_this_turn[owner_color] = false
		played_card_hand_slots_this_turn[owner_color] = []
		exchanged_card_names_this_turn[owner_color] = []
	local_auto_end_turn_pending = false
	state = false
	delete_dots()

func set_tutorial_card_hand(owner_color: int, card_names: Array) -> void:
	var cards: Array[Card] = create_card_hand_from_names(card_names)
	if owner_color == 1:
		white_card_hand = cards
		white_card_visuals = populate_card_hand(white_pieces, white_card_hand, 1)
	else:
		black_card_hand = cards
		black_card_visuals = populate_card_hand(black_pieces, black_card_hand, -1)
	setup_deck_visuals()

func set_tutorial_card_deck(owner_color: int, card_names: Array) -> void:
	var deck_names: Array[String] = []
	for card_name_value in card_names:
		deck_names.append(str(card_name_value))

	if owner_color == 1:
		white_card_deck = deck_names
		white_deck_count_override = -1
	else:
		black_card_deck = deck_names
		black_deck_count_override = -1
	setup_deck_visuals()

func set_tutorial_turn(owner_color: int) -> void:
	var was_white_turn: bool = white
	white = owner_color == 1
	if was_white_turn != white:
		reset_current_turn_card_attach()

func create_board_tiles():
	if board_tiles_node == null:
		board_tiles_node = Node2D.new()
		board_tiles_node.name = "BoardTiles"
		add_child(board_tiles_node)
		move_child(board_tiles_node, 0)

	board_tiles_node.z_index = 0
	for child in board_tiles_node.get_children():
		child.queue_free()

	for row in BOARD_SIZE:
		for col in BOARD_SIZE:
			var tile := Polygon2D.new()
			board_tiles_node.add_child(tile)
			tile.color = BOARD_TILE_LIGHT_COLOR if (row + col) % 2 == 0 else BOARD_TILE_DARK_COLOR
			tile.polygon = get_board_cell_polygon_local(Vector2(row, col))
			enable_canvas_item_antialiasing(tile)
			tile.z_index = 0

func enable_canvas_item_antialiasing(canvas_item: Object) -> void:
	for property: Dictionary in canvas_item.get_property_list():
		if str(property.get("name", "")) == "antialiased":
			canvas_item.set("antialiased", true)
			return

func create_board_markers_node():
	board_markers_node = Node2D.new()
	board_markers_node.name = "BoardMarkers"
	board_markers_node.z_index = 1
	add_child(board_markers_node)
	move_child(board_markers_node, 0)
	pieces_node.z_index = 10
	dots.z_index = 20
	turn.z_index = 30

func create_ambient_board_light() -> void:
	if ambient_board_light != null and is_instance_valid(ambient_board_light) and ambient_board_fill_light != null and is_instance_valid(ambient_board_fill_light):
		return

	if ambient_board_fill_light == null or !is_instance_valid(ambient_board_fill_light):
		ambient_board_fill_light = PointLight2D.new()
		ambient_board_fill_light.name = AMBIENT_BOARD_FILL_LIGHT_NAME
		ambient_board_fill_light.texture = get_attach_point_light_texture()
		ambient_board_fill_light.texture_scale = AMBIENT_BOARD_FILL_LIGHT_TEXTURE_SCALE
		ambient_board_fill_light.color = AMBIENT_BOARD_LIGHT_COLOR
		ambient_board_fill_light.energy = AMBIENT_BOARD_FILL_LIGHT_ENERGY
		ambient_board_fill_light.range_item_cull_mask = BOARD_LIGHT_RECEIVE_MASK
		ambient_board_fill_light.shadow_enabled = false
		ambient_board_fill_light.position = AMBIENT_BOARD_LIGHT_OFFSET
		add_child(ambient_board_fill_light)

	if ambient_board_light == null or !is_instance_valid(ambient_board_light):
		ambient_board_light = PointLight2D.new()
		ambient_board_light.name = AMBIENT_BOARD_LIGHT_NAME
		ambient_board_light.texture = get_attach_point_light_texture()
		ambient_board_light.texture_scale = AMBIENT_BOARD_LIGHT_TEXTURE_SCALE
		ambient_board_light.color = AMBIENT_BOARD_LIGHT_COLOR
		ambient_board_light.energy = AMBIENT_BOARD_LIGHT_ENERGY
		ambient_board_light.range_item_cull_mask = BOARD_LIGHT_RECEIVE_MASK
		ambient_board_light.shadow_enabled = false
		ambient_board_light.shadow_color = AMBIENT_BOARD_LIGHT_SHADOW_COLOR
		ambient_board_light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
		ambient_board_light.shadow_filter_smooth = AMBIENT_BOARD_LIGHT_SHADOW_SMOOTH
		ambient_board_light.shadow_item_cull_mask = PIECE_LIGHT_OCCLUDER_MASK
		ambient_board_light.position = AMBIENT_BOARD_LIGHT_OFFSET
		add_child(ambient_board_light)

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
				DebugLog.info("Piece created: pos=%s, color=%s" % [pos, "white" if color > 0 else "black"])

	DebugLog.info("Pieces initialized without starting cards.")

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
	var scaled_card_size: Vector2 = get_card_hand_layout_size()
	var hand_width = scaled_card_size.x * PLAYER_HAND_SIZE + CARD_UI_GAP * (PLAYER_HAND_SIZE - 1)
	hand_node.visible = true
	hand_node.mouse_filter = Control.MOUSE_FILTER_PASS
	hand_node.anchor_left = 0.5
	hand_node.anchor_right = 0.5
	hand_node.offset_left = -hand_width * 0.5
	hand_node.offset_right = hand_width * 0.5

	if is_top:
		hand_node.anchor_top = 0.0
		hand_node.anchor_bottom = 0.0
		hand_node.offset_top = TOP_CARD_HAND_MARGIN
		hand_node.offset_bottom = TOP_CARD_HAND_MARGIN + scaled_card_size.y
	else:
		hand_node.anchor_top = 1.0
		hand_node.anchor_bottom = 1.0
		hand_node.offset_top = -BOTTOM_CARD_HAND_MARGIN - scaled_card_size.y
		hand_node.offset_bottom = -BOTTOM_CARD_HAND_MARGIN

func populate_card_hand(hand_node: Control, cards: Array[Card], owner_color: int) -> Array[CardVisual]:
	for child in hand_node.get_children():
		hand_node.remove_child(child)
		child.queue_free()

	var visuals: Array[CardVisual] = []
	for i in cards.size():
		var card_visual: CardVisual = CARD_VISUAL.instantiate() as CardVisual
		hand_node.add_child(card_visual)
		card_visual.set_rest_scale(Vector2.ONE * CARD_HAND_SCALE)
		card_visual.set_hand_context(owner_color, i, get_card_home_position(i))
		card_visual.set_card(cards[i])
		connect_card_visual_signals(card_visual)
		visuals.append(card_visual)

	return visuals

func connect_card_visual_signals(card_visual: CardVisual):
	card_visual.drag_started.connect(_on_card_drag_started)
	card_visual.drag_moved.connect(_on_card_drag_moved)
	card_visual.drag_released.connect(_on_card_drag_released)
	card_visual.mouse_entered.connect(_on_hand_card_mouse_entered.bind(card_visual))
	card_visual.mouse_exited.connect(_on_hand_card_mouse_exited.bind(card_visual))

func setup_deck_visuals():
	free_existing_deck_visual(white_deck_visual)
	free_existing_deck_visual(black_deck_visual)
	white_deck_visual = create_deck_visual(white_pieces, 1)
	black_deck_visual = create_deck_visual(black_pieces, -1)

func free_existing_deck_visual(deck_visual: CardVisual) -> void:
	if deck_visual != null and is_instance_valid(deck_visual) and !deck_visual.is_queued_for_deletion():
		var parent_node: Node = deck_visual.get_parent()
		if parent_node != null:
			parent_node.remove_child(deck_visual)
		deck_visual.queue_free()

func create_deck_visual(hand_node: Control, owner_color: int) -> CardVisual:
	var deck_visual: CardVisual = CARD_VISUAL.instantiate() as CardVisual
	hand_node.add_child(deck_visual)
	deck_visual.set_hand_context(owner_color, -1, get_deck_home_position())
	deck_visual.set_card(null)
	deck_visual.set_face_down(true)
	deck_visual.draggable = false
	deck_visual.disabled = true
	deck_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_visual.set_rest_scale(Vector2.ONE * DECK_CARD_SCALE)
	deck_visual.z_index = -1
	return deck_visual

func create_hover_piece_ui():
	hover_description_panel = PanelContainer.new()
	canvas_layer.add_child(hover_description_panel)
	hover_description_panel.visible = false
	hover_description_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_description_panel.anchor_left = 1.0
	hover_description_panel.anchor_right = 1.0
	hover_description_panel.anchor_top = 0.5
	hover_description_panel.anchor_bottom = 0.5
	hover_description_panel.offset_right = -CARD_UI_SIZE.x - HOVER_CARD_MARGIN - HOVER_DESCRIPTION_GAP
	hover_description_panel.offset_left = hover_description_panel.offset_right - HOVER_DESCRIPTION_SIZE.x
	hover_description_panel.offset_top = -HOVER_DESCRIPTION_SIZE.y * 0.5
	hover_description_panel.offset_bottom = HOVER_DESCRIPTION_SIZE.y * 0.5
	hover_description_panel.z_index = 900
	var description_style: StyleBoxFlat = StyleBoxFlat.new()
	description_style.bg_color = Color(0.05, 0.055, 0.065, 0.86)
	description_style.border_color = Color(1.0, 1.0, 1.0, 0.16)
	description_style.border_width_left = 1
	description_style.border_width_top = 1
	description_style.border_width_right = 1
	description_style.border_width_bottom = 1
	description_style.corner_radius_top_left = 6
	description_style.corner_radius_top_right = 6
	description_style.corner_radius_bottom_left = 6
	description_style.corner_radius_bottom_right = 6
	description_style.content_margin_left = 12
	description_style.content_margin_top = 10
	description_style.content_margin_right = 12
	description_style.content_margin_bottom = 10
	hover_description_panel.add_theme_stylebox_override("panel", description_style)

	hover_description_label = Label.new()
	hover_description_panel.add_child(hover_description_label)
	hover_description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hover_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hover_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hover_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hover_description_label.add_theme_font_size_override("font_size", 15)
	hover_description_label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.9))

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

func create_rules_info_ui():
	rules_info_button = Button.new()
	canvas_layer.add_child(rules_info_button)
	rules_info_button.text = "i"
	rules_info_button.tooltip_text = "Rules"
	rules_info_button.anchor_left = 1.0
	rules_info_button.anchor_right = 1.0
	rules_info_button.anchor_top = 1.0
	rules_info_button.anchor_bottom = 1.0
	var button_right_offset: float = end_turn_button.offset_left - 8.0
	rules_info_button.offset_left = button_right_offset - RULES_INFO_BUTTON_SIZE.x
	rules_info_button.offset_right = button_right_offset
	rules_info_button.offset_top = end_turn_button.offset_top
	rules_info_button.offset_bottom = end_turn_button.offset_bottom
	rules_info_button.z_index = 960
	rules_info_button.focus_mode = Control.FOCUS_NONE
	rules_info_button.pressed.connect(_on_rules_info_pressed)

	rules_info_panel = PanelContainer.new()
	canvas_layer.add_child(rules_info_panel)
	rules_info_panel.visible = false
	rules_info_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	rules_info_panel.anchor_left = 0.5
	rules_info_panel.anchor_right = 0.5
	rules_info_panel.anchor_top = 0.5
	rules_info_panel.anchor_bottom = 0.5
	rules_info_panel.z_index = 970

	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.055, 0.065, 0.92)
	panel_style.border_color = Color(1.0, 1.0, 1.0, 0.18)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.content_margin_left = 14
	panel_style.content_margin_top = 12
	panel_style.content_margin_right = 14
	panel_style.content_margin_bottom = 12
	rules_info_panel.add_theme_stylebox_override("panel", panel_style)

	var panel_layout: VBoxContainer = VBoxContainer.new()
	rules_info_panel.add_child(panel_layout)
	panel_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_layout.add_theme_constant_override("separation", 8)

	var title_label: Label = Label.new()
	panel_layout.add_child(title_label)
	title_label.text = "How to Play"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.add_theme_font_size_override("font_size", 17)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82))

	rules_info_label = Label.new()
	panel_layout.add_child(rules_info_label)
	rules_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules_info_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules_info_label.text = RULES_INFO_TEXT
	rules_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_info_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	rules_info_label.add_theme_font_size_override("font_size", 13)
	rules_info_label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.9))

	arrange_rules_info_panel()
	update_rules_info_ui()

func create_action_status_ui() -> void:
	action_status_container = VBoxContainer.new()
	canvas_layer.add_child(action_status_container)
	action_status_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_status_container.anchor_left = 0.5
	action_status_container.anchor_right = 0.5
	action_status_container.anchor_top = 0.5
	action_status_container.anchor_bottom = 0.5
	action_status_container.custom_minimum_size = ACTION_STATUS_SIZE
	action_status_container.z_index = 910
	action_status_container.add_theme_constant_override("separation", 8)

	var label_settings := LabelSettings.new()
	label_settings.font_size = 24
	label_settings.font_color = ACTION_STATUS_ACTIVE_COLOR
	label_settings.outline_size = 5
	label_settings.outline_color = Color(0.0, 0.0, 0.0)

	for action_name in ["Switch", "Attach", "Move"]:
		var action_label := Label.new()
		action_status_container.add_child(action_label)
		action_label.text = action_name
		action_label.custom_minimum_size = Vector2(ACTION_STATUS_SIZE.x, 26)
		action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		action_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		action_label.label_settings = label_settings.duplicate()
		action_status_labels[action_name] = action_label

	arrange_action_status_ui()
	update_action_status_ui()

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

func get_card_hand_layout_size() -> Vector2:
	return CARD_UI_SIZE * CARD_HAND_SCALE

func get_card_hand_step() -> float:
	return get_card_hand_layout_size().x + CARD_UI_GAP

func get_card_home_position(index: int) -> Vector2:
	return Vector2(index * get_card_hand_step(), 0)

func get_deck_home_position() -> Vector2:
	return Vector2(-(CARD_UI_SIZE.x * DECK_CARD_SCALE) - (CARD_UI_GAP * 2.0), 0)

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
	update_rules_info_ui()
	update_action_status_ui()

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
		card_visual.draggable = can_drag_card_visual_now(card_visual, active_color, can_drag)
	for card_visual in black_card_visuals:
		card_visual.draggable = can_drag_card_visual_now(card_visual, active_color, can_drag)

func can_drag_card_visual_now(card_visual: CardVisual, active_color: int, can_drag: bool) -> bool:
	if !can_drag or card_visual == null or card_visual.owner_color != active_color:
		return false
	if card_visual.card == null:
		return false
	if !tutorial_constraints_enabled:
		return true

	var context: Dictionary = {
		"owner_color": card_visual.owner_color,
		"card_name": card_visual.card.card_name,
		"hand_index": get_card_visual_index(card_visual),
	}
	return is_tutorial_action_allowed(TUTORIAL_ACTION_ATTACH_CARD, context) or is_tutorial_action_allowed(TUTORIAL_ACTION_EXCHANGE_CARD, context)

func update_end_turn_button():
	if end_turn_button == null:
		return
	end_turn_button.visible = !game_over
	end_turn_button.disabled = !can_control_current_turn() or !is_tutorial_action_allowed(TUTORIAL_ACTION_END_TURN)

func begin_card_attach_process(piece_position: Vector2) -> void:
	if !pending_card_attach_positions.has(piece_position):
		active_card_attach_process_count += 1
	pending_card_attach_positions[piece_position] = true

func finish_card_attach_process(piece_position: Vector2) -> void:
	if pending_card_attach_positions.has(piece_position):
		pending_card_attach_positions.erase(piece_position)
		active_card_attach_process_count = maxi(0, active_card_attach_process_count - 1)
	update_card_drag_permissions()
	update_action_status_ui()

func has_pending_visual_processes() -> bool:
	return active_card_attach_process_count > 0 or card_burn_animation_sequence_running or !pending_card_burn_animations.is_empty()

func wait_for_pending_visual_processes() -> void:
	while is_inside_tree() and has_pending_visual_processes():
		await get_tree().process_frame

func update_rules_info_ui():
	if rules_info_button == null:
		return

	rules_info_button.visible = !game_over
	if game_over && rules_info_panel != null:
		rules_info_panel.visible = false

func update_action_status_ui() -> void:
	if action_status_container == null:
		return

	action_status_container.visible = !game_over
	set_action_status_label("Switch", can_switch_action_now())
	set_action_status_label("Attach", can_attach_action_now())
	set_action_status_label("Move", can_move_action_now())

func set_action_status_label(action_name: String, is_available: bool) -> void:
	var action_label: Label = action_status_labels.get(action_name, null) as Label
	if action_label == null:
		return

	var label_settings: LabelSettings = action_label.label_settings
	if label_settings != null:
		label_settings.font_color = ACTION_STATUS_ACTIVE_COLOR if is_available else ACTION_STATUS_INACTIVE_COLOR

func can_switch_action_now() -> bool:
	if !can_control_current_turn():
		return false
	if !is_tutorial_action_allowed(TUTORIAL_ACTION_EXCHANGE_CARD):
		return false
	var owner_color: int = get_controllable_color()
	return can_exchange_card_locally(owner_color) && has_tutorial_allowed_exchange_card(owner_color)

func has_tutorial_allowed_exchange_card(owner_color: int) -> bool:
	if !tutorial_constraints_enabled:
		return true

	var hand_cards: Array[Card] = get_card_hand(owner_color)
	for card: Card in hand_cards:
		if card == null:
			continue
		if is_tutorial_action_allowed(TUTORIAL_ACTION_EXCHANGE_CARD, {
			"owner_color": owner_color,
			"card_name": card.card_name,
		}):
			return true
	return false

func can_attach_action_now() -> bool:
	if !can_control_current_turn():
		return false
	if !is_tutorial_action_allowed(TUTORIAL_ACTION_ATTACH_CARD):
		return false

	var owner_color: int = get_controllable_color()
	var hand_cards: Array[Card] = get_card_hand(owner_color)
	if hand_cards.is_empty():
		return false

	for position_value in piece_objects:
		var piece: Piece = piece_objects[position_value] as Piece
		if piece == null or piece.color != owner_color or piece.attached_card != null:
			continue

		for card: Card in hand_cards:
			if !MoveRules.card_can_be_used(card):
				continue
			if !is_tutorial_action_allowed(TUTORIAL_ACTION_ATTACH_CARD, {
				"owner_color": owner_color,
				"piece_pos": position_value,
				"card_name": card.card_name,
			}):
				continue
			if MoveRules.can_attach_card_for_turn(piece_objects, owner_color, card):
				return true

	return false

func can_move_action_now() -> bool:
	if !can_control_current_turn():
		return false
	if !is_tutorial_action_allowed(TUTORIAL_ACTION_MOVE_PIECE):
		return false

	var owner_color: int = get_controllable_color()
	if has_moved_piece_this_turn(owner_color):
		return false
	return has_tutorial_allowed_piece_move(owner_color)

func has_tutorial_allowed_piece_move(owner_color: int) -> bool:
	for position_value in piece_objects:
		var piece_pos: Vector2 = value_to_vector2(position_value, INVALID_BOARD_POS)
		var piece: Piece = piece_objects[position_value] as Piece
		if piece == null or piece.color != owner_color or !piece.can_move():
			continue

		var player_id: int = get_player_id_for_color(owner_color)
		var valid_moves: Array[Vector2] = MoveRules.get_piece_moves_for_player(piece_objects, piece_pos, player_id, BOARD_SIZE, current_board_effects)
		for target_pos: Vector2 in valid_moves:
			if is_tutorial_action_allowed(TUTORIAL_ACTION_MOVE_PIECE, {
				"owner_color": owner_color,
				"from_pos": piece_pos,
				"to_pos": target_pos,
			}):
				return true
	return false

func has_remaining_turn_action_now() -> bool:
	return can_switch_action_now() or can_attach_action_now() or can_move_action_now()

func maybe_auto_end_turn_locally() -> void:
	if GameController.current_game_host:
		return
	if !can_auto_end_turn_now():
		return
	if local_auto_end_turn_pending or game_over or !can_control_current_turn():
		return
	if has_remaining_turn_action_now():
		return

	local_auto_end_turn_pending = true
	call_deferred("_auto_end_turn_locally_if_still_needed")

func _auto_end_turn_locally_if_still_needed() -> void:
	local_auto_end_turn_pending = false
	if GameController.current_game_host or game_over or !can_control_current_turn():
		return
	await wait_for_pending_visual_processes()
	if game_over or !can_control_current_turn():
		return
	if has_remaining_turn_action_now():
		return
	end_current_turn_locally()

func _on_rules_info_pressed():
	if rules_info_panel == null:
		return

	rules_info_panel.visible = !rules_info_panel.visible
	if rules_info_panel.visible:
		arrange_rules_info_panel()

func _on_end_turn_pressed():
	if !can_control_current_turn():
		return
	if !is_tutorial_action_allowed(TUTORIAL_ACTION_END_TURN, {
		"owner_color": get_controllable_color(),
		"player_id": get_own_player_id(),
	}, true):
		return

	await wait_for_pending_visual_processes()
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
	local_auto_end_turn_pending = false
	var ending_color: int = get_current_turn_color()
	refill_played_cards_locally(ending_color)
	clear_exchanged_card_names_this_turn(ending_color)
	tick_board_effects_locally()
	clear_piece_exhaustion_for_color(ending_color)
	white = !white
	reset_current_turn_card_attach()
	state = false
	delete_dots()
	hide_hover_piece_details()
	update_card_presentation()
	display_board()
	turn_ended.emit(ending_color, get_current_turn_color())
	finish_if_current_player_has_no_valid_turn()

func tick_board_effects_locally() -> void:
	var remaining_effects: Array = []
	for effect_value in current_board_effects:
		if !(effect_value is Dictionary):
			continue

		var effect: Dictionary = effect_value
		var turns_remaining: int = int(effect.get("turns_remaining", -1))
		if turns_remaining == -1:
			remaining_effects.append(effect)
			continue

		turns_remaining -= 1
		if turns_remaining <= 0:
			continue

		effect["turns_remaining"] = turns_remaining
		remaining_effects.append(effect)

	current_board_effects = remaining_effects

func handle_expired_nexus_card_locally(owner_color: int, expired_card: Card) -> void:
	DeckManager.return_card_to_deck(get_card_deck(owner_color), expired_card.card_name)

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
	return BoardConfig.get_player_id_for_color(owner_color)

func get_color_for_player_id(player_id: int) -> int:
	return BoardConfig.get_color_for_player_id(player_id)

func get_own_player_id() -> int:
	return get_player_id_for_color(get_own_color())

func has_attached_card_this_turn(owner_color: int) -> bool:
	return false

func mark_card_attached_this_turn(owner_color: int):
	update_card_drag_permissions()
	update_action_status_ui()

func reset_current_turn_card_attach():
	var current_color: int = get_current_turn_color()
	attached_card_this_turn[current_color] = false
	moved_piece_this_turn[current_color] = false
	exchanged_card_this_turn[current_color] = false
	played_card_hand_slots_this_turn[current_color] = []
	exchanged_card_names_this_turn[current_color] = []
	update_action_status_ui()

func clear_piece_exhaustion_for_color(owner_color: int) -> void:
	for position_value in piece_objects:
		var piece: Piece = piece_objects[position_value] as Piece
		if piece != null && piece.color == owner_color:
			piece.exhausted_this_turn = false

func has_moved_piece_this_turn(owner_color: int) -> bool:
	return bool(moved_piece_this_turn.get(owner_color, false))

func mark_piece_moved_this_turn(owner_color: int):
	moved_piece_this_turn[owner_color] = true
	update_end_turn_button()
	update_action_status_ui()

func has_exchanged_card_this_turn(owner_color: int) -> bool:
	return bool(exchanged_card_this_turn.get(owner_color, false))

func mark_card_exchanged_this_turn(owner_color: int):
	exchanged_card_this_turn[owner_color] = true
	update_action_status_ui()

func _on_card_drag_started(card_visual: CardVisual):
	hide_hover_piece_details()
	card_visual.set_drop_target_active(false)

func _on_card_drag_moved(card_visual: CardVisual):
	var target_pos: Vector2 = get_card_drop_piece_position(card_visual)
	var can_drop_on_deck: bool = can_drop_card_on_deck(card_visual)
	card_visual.set_drop_target_active(target_pos != INVALID_BOARD_POS or can_drop_on_deck)
	handle_card_reorder(card_visual)

func _on_card_drag_released(card_visual: CardVisual):
	var target_pos: Vector2 = get_card_drop_piece_position(card_visual)
	if target_pos != INVALID_BOARD_POS:
		attach_card_visual_to_piece(card_visual, target_pos)
	elif can_drop_card_on_deck(card_visual):
		exchange_card_visual_with_deck(card_visual)
	else:
		card_visual.fly_home()

func _on_hand_card_mouse_entered(card_visual: CardVisual) -> void:
	if card_visual == null or !is_instance_valid(card_visual):
		return
	if card_visual.card == null or card_visual.face_down or card_visual.is_dragging:
		return

	show_hover_card_description(card_visual.card)

func _on_hand_card_mouse_exited(_card_visual: CardVisual) -> void:
	hide_hover_piece_details()

func show_hover_card_description(card: Card) -> void:
	if card == null:
		return

	hide_hover_piece_details()
	var description: String = card.description.strip_edges()
	if description.is_empty():
		return

	hover_description_label.text = description
	hover_description_panel.visible = true

func get_card_drop_piece_position(card_visual: CardVisual) -> Vector2:
	if !can_control_current_turn():
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

func can_drop_card_on_deck(card_visual: CardVisual) -> bool:
	if card_visual == null or !is_instance_valid(card_visual):
		return false
	if card_visual.card == null:
		return false
	if !can_exchange_card_locally(card_visual.owner_color):
		return false
	if !is_tutorial_action_allowed(TUTORIAL_ACTION_EXCHANGE_CARD, {
		"owner_color": card_visual.owner_color,
		"card_name": card_visual.card.card_name,
	}):
		return false
	return is_mouse_over_deck(card_visual.owner_color)

func can_exchange_card_locally(owner_color: int) -> bool:
	if !can_control_current_turn():
		return false
	if owner_color != get_controllable_color():
		return false
	if !is_tutorial_action_allowed(TUTORIAL_ACTION_EXCHANGE_CARD, {
		"owner_color": owner_color,
	}):
		return false
	if has_exchanged_card_this_turn(owner_color):
		return false
	if get_card_hand(owner_color).is_empty():
		return false
	return get_card_deck_count(owner_color) > 0

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
	if !is_tutorial_action_allowed(TUTORIAL_ACTION_EXCHANGE_CARD, {
		"owner_color": owner_color,
		"card_name": card_name,
		"hand_index": hand_index,
	}, true):
		card_visual.fly_home()
		return

	if GameController.current_game_host:
		if send_card_exchange_action(owner_color, card_name, hand_index):
			mark_card_exchanged_this_turn(owner_color)
			card_exchanged.emit(card_name, owner_color, hand_index)
		if is_instance_valid(card_visual):
			card_visual.fly_home()
		return

	var deck: Array[String] = get_card_deck(owner_color)
	if deck.is_empty():
		card_visual.fly_home()
		return

	var replacement_card_name: String = draw_exchange_replacement_card_name(deck, card_name)
	if replacement_card_name.is_empty():
		card_visual.fly_home()
		return

	remove_card_from_hand_index(owner_color, hand_index, true, replacement_card_name)
	DeckManager.return_card_to_deck(deck, card_name)
	record_exchanged_card_name_this_turn(owner_color, card_name)
	mark_card_exchanged_this_turn(owner_color)
	card_exchanged.emit(card_name, owner_color, hand_index)

func send_card_exchange_action(owner_color: int, card_name: String, hand_index: int) -> bool:
	return bool(GameController.send_action({
		"type": "exchange_card",
		"player_id": get_player_id_for_color(owner_color),
		"card_name": card_name,
		"hand_index": hand_index,
	}))

func draw_exchange_replacement_card_name(deck: Array, returned_card_name: String) -> String:
	return draw_card_from_deck_avoiding_names(deck, [returned_card_name])

func draw_refill_card_name(owner_color: int) -> String:
	var deck: Array[String] = get_card_deck(owner_color)
	var protected_names: Array = exchanged_card_names_this_turn.get(owner_color, [])
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
	var exchanged_names: Array = exchanged_card_names_this_turn.get(owner_color, [])
	exchanged_names.append(card_name)
	exchanged_card_names_this_turn[owner_color] = exchanged_names

func clear_exchanged_card_names_this_turn(owner_color: int) -> void:
	exchanged_card_names_this_turn[owner_color] = []

func attach_card_visual_to_piece(card_visual: CardVisual, piece_position: Vector2) -> void:
	if card_visual == null or !is_instance_valid(card_visual):
		return
	if not piece_objects.has(piece_position) or card_visual.card == null:
		card_visual.fly_home()
		return
	var attach_card: Card = card_visual.card
	var card_name: String = attach_card.card_name
	var owner_color: int = card_visual.owner_color
	var hand_index: int = get_card_visual_index(card_visual)
	if !is_tutorial_action_allowed(TUTORIAL_ACTION_ATTACH_CARD, {
		"owner_color": owner_color,
		"piece_pos": piece_position,
		"card_name": card_name,
		"hand_index": hand_index,
	}, true):
		card_visual.fly_home()
		return
	if !can_attach_card_to_piece(piece_position, card_name, owner_color):
		card_visual.fly_home()
		return

	var start_texture: Texture2D = null
	var holder: Sprite2D = get_piece_holder_at(piece_position)
	if holder != null and is_instance_valid(holder):
		start_texture = holder.texture

	begin_card_attach_process(piece_position)

	if GameController.current_game_host:
		record_played_card_hand_slot(owner_color, hand_index)
		card_visual.assign_and_hide()
		if !send_card_attach_action(owner_color, card_name, piece_position, hand_index):
			finish_card_attach_process(piece_position)
			return
		mark_card_attached_this_turn(owner_color)
		card_attached.emit(piece_position, card_name, owner_color, hand_index)
		return

	if !apply_card_to_piece(piece_position, card_name):
		finish_card_attach_process(piece_position)
		if is_instance_valid(card_visual):
			card_visual.fly_home()
		return

	record_played_card_hand_slot(owner_color, hand_index)
	if is_instance_valid(card_visual):
		remove_card_from_hand(card_visual)
	else:
		remove_card_from_hand_index(owner_color, hand_index, false)
	mark_card_attached_this_turn(owner_color)
	card_attached.emit(piece_position, card_name, owner_color, hand_index)

	if get_parent().has_method("send_card_attach"):
		get_parent().send_card_attach(piece_position, card_name, owner_color, hand_index, "")

	await play_piece_card_attach_animation(piece_position, attach_card, start_texture)
	finish_card_attach_process(piece_position)

func send_card_attach_action(owner_color: int, card_name: String, piece_position: Vector2, hand_index: int) -> bool:
	var action: Dictionary = {
		"type": "attach_card",
		"player_id": get_player_id_for_color(owner_color),
		"card_name": card_name,
		"piece_pos": piece_position,
		"hand_index": hand_index,
	}
	return bool(GameController.send_action(action))

func can_attach_card_to_piece(piece_position: Vector2, card_name: String = "", owner_color: int = 0) -> bool:
	if not piece_objects.has(piece_position):
		return false
	if pending_card_attach_positions.has(piece_position):
		return false
	if !is_tutorial_action_allowed(TUTORIAL_ACTION_ATTACH_CARD, {
		"owner_color": owner_color,
		"piece_pos": piece_position,
		"card_name": card_name,
	}):
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
	apply_local_card_effect_trigger(CardEffect.TRIGGER_ON_ATTACH, piece_position, piece, card)
	display_board()
	return true

func apply_local_card_effect_trigger(trigger: String, source_pos: Vector2, piece: Piece, card: Card) -> void:
	if GameController.current_game_host:
		return
	if piece == null or card == null or !card.has_effect() or card.effect_trigger != trigger:
		return

	match card.effect_type:
		CardEffect.TYPE_INVALID_SQUARES, CardEffect.TYPE_FROZEN_SQUARES:
			add_local_board_zone_effect(source_pos, piece, card)

func add_local_board_zone_effect(source_pos: Vector2, piece: Piece, card: Card) -> void:
	var squares: Array[Vector2] = CardEffectResolver.get_effect_squares(card, source_pos, BOARD_SIZE, piece.color)
	if card.effect_type == CardEffect.TYPE_INVALID_SQUARES:
		squares = filter_base_fields_from_local_effect_squares(squares)
	if squares.is_empty():
		return

	var turns_remaining: int = int(card.effect_settings.get("turns_remaining", card.duration))
	if turns_remaining == 0:
		turns_remaining = 1

	current_board_effects.append({
		"effect_type": card.effect_type,
		"owner_player_id": get_player_id_for_color(piece.color),
		"target_player_id": int(card.effect_settings.get("target_player_id", -1)),
		"squares": squares,
		"turns_remaining": turns_remaining,
	})

func filter_base_fields_from_local_effect_squares(squares: Array[Vector2]) -> Array[Vector2]:
	var filtered_squares: Array[Vector2] = []
	for square_pos: Vector2 in squares:
		var is_base_field: bool = false
		for player_id in [0, 1]:
			if square_pos == current_player_base_fields.get(player_id, BoardConfig.get_base_field_for_player_id(player_id)):
				is_base_field = true
				break
		if !is_base_field:
			filtered_squares.append(square_pos)
	return filtered_squares

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
	card_visual.set_rest_scale(Vector2.ONE * CARD_HAND_SCALE)
	card_visual.set_hand_context(owner_color, insert_index, get_card_home_position(insert_index))
	card_visual.set_card(card)
	card_visual.set_face_down(owner_color != get_local_view_color())
	connect_card_visual_signals(card_visual)
	visuals.insert(insert_index, card_visual)

	card_visual.global_position = get_card_draw_start_position(owner_color)
	card_visual.scale = Vector2.ONE * CARD_HAND_SCALE
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
			queue_card_transfer_burn_animation(transfer)
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

		queue_card_expire_animation(piece_pos, expired_card)

func queue_card_transfer_burn_animation(transfer: Dictionary) -> void:
	pending_card_burn_animations.append({
		"type": "transfer",
		"transfer": transfer.duplicate(true),
	})
	process_card_burn_animation_queue()

func play_card_transfer_burn_animation(transfer: Dictionary) -> CardVisual:
	if canvas_layer == null:
		return null

	var card_name: String = str(transfer.get("card_name", ""))
	var card: Card = CardLibrary.duplicate_card(card_name)
	if card == null:
		return null

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
	return card_visual

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
		elif animation_type == "expire":
			var piece_position: Vector2 = value_to_vector2(animation_data.get("piece_position", INVALID_BOARD_POS), INVALID_BOARD_POS)
			var expired_card: Card = animation_data.get("expired_card", null) as Card
			card_visual = play_card_expire_animation(piece_position, expired_card)
		if card_visual != null and is_instance_valid(card_visual):
			await card_visual.burn_finished
		if !pending_card_burn_animations.is_empty() and get_tree() != null:
			await get_tree().create_timer(CARD_BURN_SEQUENCE_GAP).timeout

	card_burn_animation_sequence_running = false

func play_card_expire_animation(piece_position: Vector2, expired_card: Card) -> CardVisual:
	if expired_card == null or canvas_layer == null or !is_valid_position(piece_position):
		return null

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

	var animation_scale: float = 0.74 * 0.75
	var piece_screen_position: Vector2 = get_board_position_screen_position(piece_position)
	var visual_size: Vector2 = CARD_UI_SIZE * animation_scale
	card_visual.global_position = piece_screen_position - visual_size * 0.5 + Vector2(0.0, -visual_size.y * 0.72)
	card_visual.scale = Vector2.ONE * animation_scale
	card_visual.rotation = deg_to_rad(randf_range(-4.0, 4.0))
	card_visual.z_index = 980
	card_visual.play_burn_away_and_free()
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
	update_action_status_ui()
	arrange_action_status_ui()
	if rules_info_panel != null && rules_info_panel.visible:
		arrange_rules_info_panel()
	maybe_auto_end_turn_locally()

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

func select_piece_for_action(piece_pos: Vector2) -> bool:
	var player_id: int = get_own_player_id()
	if !can_player_control_piece_at(piece_pos, player_id):
		return false
	if !is_tutorial_action_allowed(TUTORIAL_ACTION_SELECT_PIECE, {
		"owner_color": get_controllable_color(),
		"player_id": player_id,
		"piece_pos": piece_pos,
	}, true):
		return false

	selected_piece = piece_pos
	state = true
	piece_selected.emit(piece_pos, player_id)
	show_options()
	return state

func try_move_selected_piece(target_pos: Vector2) -> bool:
	if !state or !moves.has(target_pos):
		return false
	if !is_tutorial_action_allowed(TUTORIAL_ACTION_MOVE_PIECE, {
		"owner_color": get_controllable_color(),
		"player_id": get_own_player_id(),
		"from_pos": selected_piece,
		"to_pos": target_pos,
	}, true):
		return false

	send_move_action(selected_piece, target_pos)
	return true

func clear_piece_selection() -> void:
	delete_dots()
	state = false
	update_selected_piece_glow()
	hovered_piece = Vector2(-1, -1)
	hide_hover_piece_details()

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
				if is_mouse_out(): return
				if has_moved_piece_this_turn(get_controllable_color()):
					return
				var clicked_pos: Vector2 = get_mouse_board_position()
				var clicked_cell_value = "invalid"
				if is_valid_position(clicked_pos):
					clicked_cell_value = board[int(clicked_pos.x)][int(clicked_pos.y)]

				DebugLog.info("Click: board[%s][%s]=%s" % [
					int(clicked_pos.x),
					int(clicked_pos.y),
					clicked_cell_value,
				])

				if !is_valid_position(clicked_pos):
					return

				if !state && can_player_control_piece_at(clicked_pos, get_own_player_id()):
					select_piece_for_action(clicked_pos)
				elif state:
					if moves.has(clicked_pos):
						try_move_selected_piece(clicked_pos)
					clear_piece_selection()

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
	if !is_tutorial_action_allowed(TUTORIAL_ACTION_MOVE_PIECE, {
		"owner_color": get_controllable_color(),
		"player_id": get_own_player_id(),
		"from_pos": from_pos,
		"to_pos": to_pos,
	}, true):
		return

	if GameController.current_game_host:
		var action: Dictionary = {
			"type": "move_piece",
			"player_id": get_own_player_id(),
			"from": from_pos,
			"to": to_pos,
		}
		GameController.send_action(action)
		mark_piece_moved_this_turn(get_controllable_color())
		piece_moved.emit(from_pos, to_pos, get_controllable_color())
		return

	if get_parent().has_method("send_move"):
		get_parent().send_move(from_pos, to_pos)
	set_move(from_pos, to_pos)

func is_mouse_out():
	return get_mouse_board_position() == INVALID_BOARD_POS

func get_board_rect_local() -> Rect2:
	var rect: Rect2 = get_board_unprojected_rect_local()
	return get_points_bounds_local(PackedVector2Array([
		project_board_point_local(rect.position),
		project_board_point_local(rect.position + Vector2(rect.size.x, 0.0)),
		project_board_point_local(rect.position + rect.size),
		project_board_point_local(rect.position + Vector2(0.0, rect.size.y)),
	]))

func get_board_unprojected_rect_local() -> Rect2:
	return BoardConfig.get_board_rect_local()

func project_board_point_local(point: Vector2) -> Vector2:
	if !BOARD_PERSPECTIVE_ENABLED:
		return point

	var half_size: float = BoardConfig.get_board_pixel_size() * 0.5
	if half_size <= 0.0:
		return point

	var board_view_color: int = get_board_view_color()
	var top_factor: float = clampf((half_size - point.y) / (half_size * 2.0), 0.0, 1.0)
	if board_view_color < 0:
		top_factor = 1.0 - top_factor
	var horizontal_scale: float = lerpf(BOARD_PERSPECTIVE_BOTTOM_SCALE, BOARD_PERSPECTIVE_TOP_SCALE, top_factor)
	var projected_x: float = point.x * horizontal_scale
	var projected_y: float = half_size - ((half_size - point.y) * BOARD_PERSPECTIVE_VERTICAL_SCALE)
	if board_view_color < 0:
		projected_y = -half_size + ((point.y + half_size) * BOARD_PERSPECTIVE_VERTICAL_SCALE)
	return Vector2(projected_x, projected_y)

func get_board_view_color() -> int:
	if side != null && !side:
		return -1
	return 1

func get_board_cell_polygon_local(board_pos: Vector2, inset: float = 0.0) -> PackedVector2Array:
	var center: Vector2 = BoardConfig.get_cell_center_local(board_pos)
	var half_cell: float = CELL_WIDTH * 0.5
	var corners := [
		center + Vector2(-half_cell, -half_cell),
		center + Vector2(half_cell, -half_cell),
		center + Vector2(half_cell, half_cell),
		center + Vector2(-half_cell, half_cell),
	]
	var polygon := PackedVector2Array()
	var projected_center: Vector2 = get_board_position_local_position(board_pos)
	var inset_factor: float = clampf(inset / half_cell, 0.0, 0.95) if half_cell > 0.0 else 0.0
	for corner: Vector2 in corners:
		var projected_corner: Vector2 = project_board_point_local(corner)
		polygon.append(projected_corner.lerp(projected_center, inset_factor))
	return polygon

func get_points_bounds_local(points: PackedVector2Array) -> Rect2:
	if points.size() == 0:
		return Rect2()

	var min_point: Vector2 = points[0]
	var max_point: Vector2 = points[0]
	for point: Vector2 in points:
		min_point.x = min(min_point.x, point.x)
		min_point.y = min(min_point.y, point.y)
		max_point.x = max(max_point.x, point.x)
		max_point.y = max(max_point.y, point.y)
	return Rect2(min_point, max_point - min_point)

func get_mouse_board_position() -> Vector2:
	var local_pos: Vector2 = to_local(get_global_mouse_position())
	for row in BOARD_SIZE:
		for col in BOARD_SIZE:
			var board_pos := Vector2(row, col)
			if Geometry2D.is_point_in_polygon(local_pos, get_board_cell_polygon_local(board_pos)):
				return board_pos
	return INVALID_BOARD_POS

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
		hover_card_preview.disabled = true
		hover_card_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hover_card_preview.visible = true
		hover_description_label.text = preview_card.description.strip_edges()
		hover_description_panel.visible = !hover_description_label.text.is_empty()

	hover_duration_label.text = "INF" if piece.turns_remaining < 0 else str(piece.turns_remaining)
	hover_duration_label.visible = true
	update_hover_duration_label_position()

func hide_hover_piece_details():
	if hover_card_preview:
		hover_card_preview.visible = false
	if hover_description_panel:
		hover_description_panel.visible = false
	if hover_description_label:
		hover_description_label.text = ""
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
	return project_board_point_local(BoardConfig.get_cell_center_local(board_pos))

func get_default_piece_texture(piece_value: int) -> Texture2D:
	if piece_value == 0:
		return null
	if piece_value * get_own_color() > 0:
		return OWN_DEFAULT_PIECE_TEXTURE
	return DEFAULT_PIECE_TEXTURE

func is_default_piece_texture(texture_value: Texture2D) -> bool:
	return texture_value == DEFAULT_PIECE_TEXTURE || texture_value == OWN_DEFAULT_PIECE_TEXTURE

func get_piece_visual_transform_for_texture(texture_value: Texture2D, board_pos: Vector2) -> Dictionary:
	var visual_transform := {
		"scale": Vector2.ONE,
		"offset": Vector2.ZERO,
	}
	if texture_value == null:
		return visual_transform

	var perspective_scale: float = get_piece_perspective_scale(board_pos)
	if is_default_piece_texture(texture_value):
		var texture_size: Vector2 = texture_value.get_size()
		if texture_size.y > 0.0:
			var visual_scale: float = (DEFAULT_PIECE_VISUAL_HEIGHT / texture_size.y) * perspective_scale
			var cell_bounds: Rect2 = get_board_cell_rect_local(board_pos)
			var cell_bottom_offset: float = cell_bounds.end.y - get_board_position_local_position(board_pos).y
			visual_transform["scale"] = Vector2.ONE * visual_scale
			visual_transform["offset"] = Vector2(0.0, (cell_bottom_offset - DEFAULT_PIECE_BOTTOM_INSET) / visual_scale - (texture_size.y * 0.5))
		return visual_transform

	visual_transform["scale"] = Vector2.ONE * perspective_scale
	return visual_transform

func get_piece_light_global_position_for_texture(holder: Sprite2D, texture_value: Texture2D) -> Vector2:
	if holder == null or !is_instance_valid(holder):
		return Vector2.ZERO

	var board_pos: Vector2 = value_to_vector2(holder.get_meta("board_pos", INVALID_BOARD_POS), INVALID_BOARD_POS)
	if !is_valid_position(board_pos):
		return holder.to_global(holder.offset)

	var visual_transform: Dictionary = get_piece_visual_transform_for_texture(texture_value, board_pos)
	var visual_scale: Vector2 = visual_transform.get("scale", holder.scale)
	var visual_offset: Vector2 = visual_transform.get("offset", holder.offset)
	var scaled_offset := Vector2(visual_offset.x * visual_scale.x, visual_offset.y * visual_scale.y)
	var parent_node := holder.get_parent()
	if parent_node is Node2D:
		var parent_2d := parent_node as Node2D
		return parent_2d.to_global(holder.position + scaled_offset.rotated(holder.rotation))

	return holder.to_global(visual_offset)

func apply_piece_visual_size(holder: Sprite2D, board_pos: Vector2) -> void:
	holder.scale = Vector2.ONE
	holder.offset = Vector2.ZERO
	if holder.texture == null:
		return

	var visual_transform: Dictionary = get_piece_visual_transform_for_texture(holder.texture, board_pos)
	holder.scale = visual_transform.get("scale", Vector2.ONE)
	holder.offset = visual_transform.get("offset", Vector2.ZERO)

func get_piece_perspective_scale(board_pos: Vector2) -> float:
	var center_row: float = float(BOARD_SIZE - 1) * 0.5
	if center_row <= 0.0:
		return 1.0

	var row_delta_from_center: float = (center_row - board_pos.x) * float(get_board_view_color())
	var normalized_distance: float = clampf(row_delta_from_center / center_row, -1.0, 1.0)
	return 1.0 + normalized_distance * PIECE_PERSPECTIVE_SCALE_VARIATION

func get_piece_depth_z_index(board_pos: Vector2) -> int:
	if get_board_view_color() < 0:
		return int(board_pos.x)
	return BOARD_SIZE - 1 - int(board_pos.x)

func apply_piece_shadow(holder: Sprite2D, board_pos: Vector2) -> void:
	remove_piece_shadow(holder)
	if holder == null or !is_instance_valid(holder) or holder.texture == null or !piece_objects.has(board_pos):
		return

	var texture_size: Vector2 = holder.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	var radius_y: float = texture_size.y * PIECE_LIGHT_OCCLUDER_FOOTPRINT_HEIGHT_FACTOR * 0.5
	var visual_bottom_y: float = holder.offset.y + texture_size.y * (0.5 - PIECE_LIGHT_OCCLUDER_FOOTPRINT_BOTTOM_INSET_FACTOR)
	var footprint_center := Vector2(
		holder.offset.x + PIECE_LIGHT_OCCLUDER_FOOTPRINT_OFFSET.x,
		visual_bottom_y - radius_y + PIECE_LIGHT_OCCLUDER_FOOTPRINT_OFFSET.y
	)

	var shadow := PointLight2D.new()
	shadow.name = PIECE_SHADOW_NAME
	shadow.top_level = true
	shadow.texture = get_attach_point_light_texture()
	shadow.texture_scale = PIECE_SHADOW_LIGHT_TEXTURE_SCALE
	shadow.color = PIECE_SHADOW_LIGHT_COLOR
	shadow.energy = PIECE_SHADOW_LIGHT_ENERGY
	shadow.range_item_cull_mask = BOARD_LIGHT_RECEIVE_MASK
	shadow.shadow_enabled = true
	shadow.shadow_color = PIECE_SHADOW_LIGHT_SHADOW_COLOR
	shadow.shadow_filter = Light2D.SHADOW_FILTER_NONE
	shadow.shadow_filter_smooth = PIECE_SHADOW_LIGHT_SHADOW_SMOOTH
	shadow.shadow_item_cull_mask = PIECE_LIGHT_OCCLUDER_MASK
	holder.add_child(shadow)
	var piece: Piece = piece_objects[board_pos] as Piece
	var light_source_y_direction: float = -float(get_board_view_color())
	if piece != null and piece.color * get_own_color() < 0:
		light_source_y_direction *= -1.0
	shadow.global_position = holder.to_global(footprint_center) + Vector2(0.0, PIECE_SHADOW_LIGHT_SOURCE_OFFSET * light_source_y_direction)

func remove_piece_shadow(holder: Sprite2D) -> void:
	var existing_shadow: Node = holder.get_node_or_null(PIECE_SHADOW_NAME)
	if existing_shadow != null:
		existing_shadow.free()

func apply_piece_light_occluder(holder: Sprite2D, board_pos: Vector2) -> void:
	remove_piece_light_occluder(holder)
	if holder.texture == null or !piece_objects.has(board_pos):
		return

	var texture_size: Vector2 = holder.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	var occluder := LightOccluder2D.new()
	occluder.name = PIECE_LIGHT_OCCLUDER_NAME
	occluder.occluder_light_mask = PIECE_LIGHT_OCCLUDER_MASK

	var radius_x: float = texture_size.x * PIECE_LIGHT_OCCLUDER_FOOTPRINT_WIDTH_FACTOR * 0.5
	var radius_y: float = texture_size.y * PIECE_LIGHT_OCCLUDER_FOOTPRINT_HEIGHT_FACTOR * 0.5
	if radius_x <= 0.0 or radius_y <= 0.0:
		return

	var visual_bottom_y: float = holder.offset.y + texture_size.y * (0.5 - PIECE_LIGHT_OCCLUDER_FOOTPRINT_BOTTOM_INSET_FACTOR)
	var center: Vector2 = Vector2(
		holder.offset.x + PIECE_LIGHT_OCCLUDER_FOOTPRINT_OFFSET.x,
		visual_bottom_y - radius_y + PIECE_LIGHT_OCCLUDER_FOOTPRINT_OFFSET.y
	)
	var segments: int = maxi(8, PIECE_LIGHT_OCCLUDER_FOOTPRINT_SEGMENTS)
	var footprint_polygon := PackedVector2Array()
	for point_index in segments:
		var angle: float = TAU * float(point_index) / float(segments)
		footprint_polygon.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))

	var occluder_polygon := OccluderPolygon2D.new()
	occluder_polygon.closed = true
	occluder_polygon.polygon = footprint_polygon
	occluder.occluder = occluder_polygon
	holder.add_child(occluder)

func remove_piece_light_occluder(holder: Sprite2D) -> void:
	var existing_occluder: Node = holder.get_node_or_null(PIECE_LIGHT_OCCLUDER_NAME)
	if existing_occluder != null:
		existing_occluder.free()

func set_piece_light_occluder_enabled(holder: Sprite2D, is_enabled: bool) -> void:
	if holder == null or !is_instance_valid(holder):
		return

	var occluder: LightOccluder2D = holder.get_node_or_null(PIECE_LIGHT_OCCLUDER_NAME) as LightOccluder2D
	if occluder != null:
		occluder.occluder_light_mask = PIECE_LIGHT_OCCLUDER_MASK if is_enabled else 0

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

func get_card_piece_texture_for_color(card: Card, piece_color: int) -> Texture2D:
	if card == null:
		return null
	if piece_color > 0:
		return card.white_piece_texture
	return card.black_piece_texture

func get_piece_visual_texture(piece: Piece) -> Texture2D:
	if piece == null:
		return null

	var attached_texture: Texture2D = get_attached_card_piece_texture(piece)
	if attached_texture != null:
		return attached_texture
	return get_default_piece_texture(piece.color)

func get_piece_visual_state_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for position_value in piece_objects:
		var board_pos: Vector2 = value_to_vector2(position_value, INVALID_BOARD_POS)
		var piece: Piece = piece_objects[position_value] as Piece
		if piece == null:
			continue

		snapshot[board_pos] = {
			"color": piece.color,
			"card_name": piece.attached_card.card_name if piece.attached_card != null else "",
			"texture": get_piece_visual_texture(piece),
		}

	return snapshot

func collect_state_attach_animations(previous_snapshot: Dictionary) -> Array[Dictionary]:
	var animations: Array[Dictionary] = []
	if !has_received_server_state or should_skip_visual_animations():
		return animations

	for position_value in piece_objects:
		var board_pos: Vector2 = value_to_vector2(position_value, INVALID_BOARD_POS)
		if !previous_snapshot.has(board_pos):
			continue

		var piece: Piece = piece_objects[position_value] as Piece
		if piece == null or piece.attached_card == null:
			continue

		var previous_state: Dictionary = previous_snapshot[board_pos]
		if int(previous_state.get("color", 0)) != piece.color:
			continue
		if str(previous_state.get("card_name", "")) == piece.attached_card.card_name:
			continue

		animations.append({
			"position": board_pos,
			"card": piece.attached_card,
			"start_texture": previous_state.get("texture", get_default_piece_texture(piece.color)),
		})

	return animations

func play_state_attach_animations(animations: Array[Dictionary]) -> void:
	for animation: Dictionary in animations:
		var board_pos: Vector2 = value_to_vector2(animation.get("position", INVALID_BOARD_POS), INVALID_BOARD_POS)
		var card: Card = animation.get("card", null) as Card
		var start_texture: Texture2D = animation.get("start_texture", null) as Texture2D
		if !is_valid_position(board_pos) or card == null:
			finish_card_attach_process(board_pos)
			continue

		await play_piece_card_attach_animation(board_pos, card, start_texture)
		finish_card_attach_process(board_pos)

func get_piece_holder_at(board_pos: Vector2) -> Sprite2D:
	if pieces_node == null:
		return null

	for child in pieces_node.get_children():
		var holder: Sprite2D = child as Sprite2D
		if holder == null or holder.is_queued_for_deletion():
			continue
		var holder_pos: Vector2 = value_to_vector2(holder.get_meta("board_pos", INVALID_BOARD_POS), INVALID_BOARD_POS)
		if holder_pos == board_pos:
			return holder

	return null

func refresh_piece_holder_visual(holder: Sprite2D, board_pos: Vector2) -> void:
	if holder == null or !is_instance_valid(holder):
		return

	holder.light_mask = PIECE_LIGHT_RECEIVE_MASK
	holder.position = get_board_position_local_position(board_pos)
	holder.z_index = get_piece_depth_z_index(board_pos)
	apply_piece_visual_size(holder, board_pos)
	apply_piece_light_occluder(holder, board_pos)
	apply_piece_shadow(holder, board_pos)
	apply_piece_exhausted_material(holder, board_pos)
	apply_selected_piece_glow(holder, board_pos)

func get_attach_point_light_texture() -> Texture2D:
	if attach_point_light_texture != null:
		return attach_point_light_texture

	var texture_size: int = ATTACH_POINT_LIGHT_TEXTURE_SIZE
	var image := Image.create(texture_size, texture_size, false, Image.FORMAT_RGBA8)
	var center := Vector2(float(texture_size) * 0.5, float(texture_size) * 0.5)
	var radius: float = float(texture_size) * 0.5
	var grain_noise := FastNoiseLite.new()
	grain_noise.seed = 91357
	grain_noise.frequency = LIGHT_TEXTURE_GRAIN_FREQUENCY
	grain_noise.fractal_octaves = 3
	grain_noise.fractal_gain = 0.52
	var fine_grain_noise := FastNoiseLite.new()
	fine_grain_noise.seed = 24731
	fine_grain_noise.frequency = LIGHT_TEXTURE_FINE_GRAIN_FREQUENCY
	fine_grain_noise.fractal_octaves = 2
	fine_grain_noise.fractal_gain = 0.44
	for y in texture_size:
		for x in texture_size:
			var pixel_pos := Vector2(float(x) + 0.5, float(y) + 0.5)
			var distance_ratio: float = clampf(pixel_pos.distance_to(center) / radius, 0.0, 1.0)
			var alpha: float = pow(1.0 - distance_ratio, 1.85)
			var grain: float = grain_noise.get_noise_2d(float(x), float(y)) * LIGHT_TEXTURE_GRAIN_STRENGTH
			grain += fine_grain_noise.get_noise_2d(float(x), float(y)) * LIGHT_TEXTURE_FINE_GRAIN_STRENGTH
			alpha = clampf(alpha * (1.0 + grain), 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))

	attach_point_light_texture = ImageTexture.create_from_image(image)
	return attach_point_light_texture

func create_piece_attach_point_light(holder: Sprite2D) -> PointLight2D:
	if holder == null or !is_instance_valid(holder):
		return null

	var point_light := PointLight2D.new()
	point_light.name = ATTACH_POINT_LIGHT_NAME
	point_light.texture = get_attach_point_light_texture()
	point_light.texture_scale = ATTACH_POINT_LIGHT_TEXTURE_SCALE
	point_light.color = ATTACH_POINT_LIGHT_COLOR
	point_light.energy = 0.0
	point_light.range_item_cull_mask = BOARD_LIGHT_RECEIVE_MASK
	point_light.shadow_enabled = true
	point_light.shadow_color = ATTACH_POINT_LIGHT_SHADOW_COLOR
	point_light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	point_light.shadow_filter_smooth = ATTACH_POINT_LIGHT_SHADOW_SMOOTH
	point_light.shadow_item_cull_mask = PIECE_LIGHT_OCCLUDER_MASK
	add_child(point_light)
	point_light.global_position = get_piece_light_global_position_for_texture(holder, holder.texture)
	return point_light

func create_piece_attach_sprite_light(holder: Sprite2D) -> PointLight2D:
	if holder == null or !is_instance_valid(holder):
		return null

	var piece_light := PointLight2D.new()
	piece_light.name = ATTACH_PIECE_LIGHT_NAME
	piece_light.texture = get_attach_point_light_texture()
	piece_light.texture_scale = ATTACH_PIECE_LIGHT_TEXTURE_SCALE
	piece_light.color = ATTACH_PIECE_LIGHT_COLOR
	piece_light.energy = 0.0
	piece_light.range_item_cull_mask = PIECE_LIGHT_RECEIVE_MASK
	piece_light.shadow_enabled = false
	add_child(piece_light)
	piece_light.global_position = get_piece_light_global_position_for_texture(holder, holder.texture)
	return piece_light

func update_attach_point_light_position(point_light: PointLight2D, holder: Sprite2D) -> void:
	if point_light == null or !is_instance_valid(point_light) or holder == null or !is_instance_valid(holder):
		return

	point_light.global_position = get_piece_light_global_position_for_texture(holder, holder.texture)

func cleanup_piece_attach_point_light(holder, point_light, piece_light = null) -> void:
	if point_light != null and is_instance_valid(point_light):
		point_light.queue_free()
	if piece_light != null and is_instance_valid(piece_light):
		piece_light.queue_free()
	if holder != null and is_instance_valid(holder) and holder is Sprite2D:
		set_piece_light_occluder_enabled(holder as Sprite2D, true)

func apply_piece_morph_overlay_target_visual(morph_overlay: Sprite2D, holder: Sprite2D, target_texture: Texture2D) -> void:
	if morph_overlay == null or !is_instance_valid(morph_overlay) or holder == null or !is_instance_valid(holder):
		return

	morph_overlay.texture = target_texture
	var board_pos: Vector2 = value_to_vector2(holder.get_meta("board_pos", INVALID_BOARD_POS), INVALID_BOARD_POS)
	if !is_valid_position(board_pos):
		return

	var target_transform: Dictionary = get_piece_visual_transform_for_texture(target_texture, board_pos)
	var target_scale: Vector2 = target_transform.get("scale", Vector2.ONE)
	morph_overlay.offset = target_transform.get("offset", Vector2.ZERO)
	morph_overlay.scale = Vector2(
		target_scale.x / holder.scale.x if absf(holder.scale.x) > 0.0001 else target_scale.x,
		target_scale.y / holder.scale.y if absf(holder.scale.y) > 0.0001 else target_scale.y
	)

func play_piece_texture_morph(holder: Sprite2D, target_texture: Texture2D, duration: float, point_light: PointLight2D = null, piece_light: PointLight2D = null) -> void:
	if holder == null or !is_instance_valid(holder) or target_texture == null:
		return
	if duration <= 0.0:
		return

	var existing_morph: Node = holder.get_node_or_null(PIECE_ATTACH_MORPH_NAME)
	if existing_morph != null:
		existing_morph.free()

	var morph_overlay := Sprite2D.new()
	morph_overlay.name = PIECE_ATTACH_MORPH_NAME
	morph_overlay.z_index = PIECE_ATTACH_MORPH_Z_INDEX
	morph_overlay.z_as_relative = true
	sync_piece_attach_overlay_to_holder(morph_overlay, holder)
	apply_piece_morph_overlay_target_visual(morph_overlay, holder, target_texture)
	morph_overlay.light_mask = PIECE_LIGHT_RECEIVE_MASK

	var morph_material := ShaderMaterial.new()
	morph_material.shader = PIECE_TEXTURE_MORPH_SHADER
	morph_material.set_shader_parameter("morph_progress", 0.0)
	morph_material.set_shader_parameter("noise_strength", PIECE_ATTACH_MORPH_NOISE_STRENGTH)
	morph_material.set_shader_parameter("shine_strength", PIECE_ATTACH_MORPH_SHINE_STRENGTH)
	morph_material.set_shader_parameter("shine_color", PIECE_ATTACH_GLOW_COLOR)
	morph_overlay.material = morph_material
	holder.add_child(morph_overlay)

	var target_light_position: Vector2 = get_piece_light_global_position_for_texture(holder, target_texture)
	var morph_tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	morph_tween.tween_property(morph_material, "shader_parameter/morph_progress", 1.0, duration)
	if point_light != null and is_instance_valid(point_light):
		morph_tween.parallel().tween_property(point_light, "global_position", target_light_position, duration)
	if piece_light != null and is_instance_valid(piece_light):
		morph_tween.parallel().tween_property(piece_light, "global_position", target_light_position, duration)
	await morph_tween.finished

func play_piece_card_attach_animation(piece_position: Vector2, card: Card, start_texture: Texture2D = null) -> void:
	if should_skip_visual_animations() or !is_inside_tree():
		return
	if card == null or !piece_objects.has(piece_position):
		return

	var piece: Piece = piece_objects[piece_position] as Piece
	if piece == null:
		return

	var attached_texture: Texture2D = get_card_piece_texture_for_color(card, piece.color)
	if attached_texture == null:
		return

	var holder: Sprite2D = get_piece_holder_at(piece_position)
	if holder == null or holder.texture == null:
		return

	if start_texture != null and holder.texture != start_texture:
		holder.texture = start_texture
		refresh_piece_holder_visual(holder, piece_position)

	var attach_point_light: PointLight2D = create_piece_attach_point_light(holder)
	var attach_piece_light: PointLight2D = create_piece_attach_sprite_light(holder)
	set_piece_light_occluder_enabled(holder, false)
	remove_piece_attach_effects(holder)
	var glow_overlay: Sprite2D = create_piece_attach_glow_overlay(holder)
	var rays_overlay: Sprite2D = create_piece_attach_rays_overlay(holder)
	var glow_material: ShaderMaterial = glow_overlay.material as ShaderMaterial
	var rays_material: ShaderMaterial = rays_overlay.material as ShaderMaterial

	var in_tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	in_tween.tween_property(glow_material, "shader_parameter/glow_strength", PIECE_ATTACH_GLOW_BASE_STRENGTH, PIECE_ATTACH_IN_DURATION)
	in_tween.parallel().tween_property(rays_material, "shader_parameter/size", PIECE_ATTACH_RAYS_SWITCH_SIZE, PIECE_ATTACH_IN_DURATION)
	in_tween.parallel().tween_property(rays_material, "shader_parameter/alpha_strength", 1.0, PIECE_ATTACH_IN_DURATION * PIECE_ATTACH_RAYS_FADE_IN_DURATION_RATIO).set_delay(PIECE_ATTACH_IN_DURATION * PIECE_ATTACH_RAYS_FADE_IN_DELAY_RATIO)
	if attach_point_light != null:
		in_tween.parallel().tween_property(attach_point_light, "energy", ATTACH_POINT_LIGHT_ENERGY, PIECE_ATTACH_IN_DURATION)
	if attach_piece_light != null:
		in_tween.parallel().tween_property(attach_piece_light, "energy", ATTACH_PIECE_LIGHT_ENERGY, PIECE_ATTACH_IN_DURATION)
	await in_tween.finished

	if !is_inside_tree() or !is_instance_valid(holder):
		cleanup_piece_attach_point_light(holder, attach_point_light, attach_piece_light)
		return

	await get_tree().create_timer(PIECE_ATTACH_PRE_SWITCH_HOLD_DURATION).timeout
	if !is_inside_tree() or !is_instance_valid(holder):
		cleanup_piece_attach_point_light(holder, attach_point_light, attach_piece_light)
		return

	var switch_tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	switch_tween.tween_property(glow_material, "shader_parameter/glow_strength", PIECE_ATTACH_GLOW_SWITCH_STRENGTH, PIECE_ATTACH_GLOW_SWITCH_DURATION)
	await switch_tween.finished
	if !is_inside_tree() or !is_instance_valid(holder):
		cleanup_piece_attach_point_light(holder, attach_point_light, attach_piece_light)
		return

	await play_piece_texture_morph(holder, attached_texture, PIECE_ATTACH_MORPH_DURATION, attach_point_light, attach_piece_light)
	if !is_inside_tree() or !is_instance_valid(holder):
		cleanup_piece_attach_point_light(holder, attach_point_light, attach_piece_light)
		return

	holder.texture = attached_texture
	refresh_piece_holder_visual(holder, piece_position)
	var morph_overlay: Node = holder.get_node_or_null(PIECE_ATTACH_MORPH_NAME)
	if morph_overlay != null:
		morph_overlay.queue_free()
	set_piece_light_occluder_enabled(holder, false)
	update_attach_point_light_position(attach_point_light, holder)
	update_attach_point_light_position(attach_piece_light, holder)
	sync_piece_attach_overlay_to_holder(glow_overlay, holder)
	apply_piece_attach_rays_overlay_transform(rays_overlay, holder)

	await get_tree().create_timer(PIECE_ATTACH_POST_SWITCH_HOLD_DURATION).timeout
	if !is_inside_tree() or !is_instance_valid(holder):
		cleanup_piece_attach_point_light(holder, attach_point_light, attach_piece_light)
		return

	var out_tween: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	out_tween.tween_property(glow_material, "shader_parameter/glow_strength", 0.0, PIECE_ATTACH_OUT_DURATION)
	out_tween.parallel().tween_property(rays_material, "shader_parameter/size", PIECE_ATTACH_RAYS_START_SIZE, PIECE_ATTACH_OUT_DURATION)
	out_tween.parallel().tween_property(rays_material, "shader_parameter/alpha_strength", 0.0, PIECE_ATTACH_OUT_DURATION)
	if attach_point_light != null:
		out_tween.parallel().tween_property(attach_point_light, "energy", 0.0, PIECE_ATTACH_OUT_DURATION)
	if attach_piece_light != null:
		out_tween.parallel().tween_property(attach_piece_light, "energy", 0.0, PIECE_ATTACH_OUT_DURATION)
	await out_tween.finished

	if is_instance_valid(glow_overlay):
		glow_overlay.queue_free()
	if is_instance_valid(rays_overlay):
		rays_overlay.queue_free()
	cleanup_piece_attach_point_light(holder, attach_point_light, attach_piece_light)

func create_piece_attach_glow_overlay(holder: Sprite2D) -> Sprite2D:
	return create_piece_glow_overlay(holder, PIECE_ATTACH_GLOW_NAME, PIECE_ATTACH_GLOW_Z_INDEX, 0.0)

func create_piece_glow_overlay(holder: Sprite2D, effect_name: String, z_index: int, glow_strength: float) -> Sprite2D:
	var overlay := Sprite2D.new()
	overlay.name = effect_name
	overlay.z_index = z_index
	overlay.z_as_relative = true
	sync_piece_attach_overlay_to_holder(overlay, holder)

	var material := ShaderMaterial.new()
	material.shader = PIECE_ATTACH_GLOW_SHADER
	material.set_shader_parameter("glow_color", PIECE_ATTACH_GLOW_COLOR)
	material.set_shader_parameter("glow_strength", glow_strength)
	material.set_shader_parameter("glow_size", PIECE_ATTACH_GLOW_SIZE)
	material.set_shader_parameter("fill_strength", PIECE_ATTACH_GLOW_FILL_STRENGTH)
	overlay.material = material

	holder.add_child(overlay)
	return overlay

func create_piece_attach_rays_overlay(holder: Sprite2D) -> Sprite2D:
	var overlay := Sprite2D.new()
	overlay.name = PIECE_ATTACH_RAYS_NAME
	overlay.z_index = PIECE_ATTACH_RAYS_Z_INDEX
	overlay.z_as_relative = true
	apply_piece_attach_rays_overlay_transform(overlay, holder)

	var material := ShaderMaterial.new()
	material.shader = PIECE_ATTACH_RAYS_SHADER
	material.set_shader_parameter("gradient", create_piece_attach_rays_gradient_texture())
	material.set_shader_parameter("spread", PIECE_ATTACH_RAYS_SPREAD)
	material.set_shader_parameter("cutoff", PIECE_ATTACH_RAYS_CUTOFF)
	material.set_shader_parameter("speed", PIECE_ATTACH_RAYS_SPEED)
	material.set_shader_parameter("ray1_density", PIECE_ATTACH_RAYS_RAY1_DENSITY)
	material.set_shader_parameter("ray2_density", PIECE_ATTACH_RAYS_RAY2_DENSITY)
	material.set_shader_parameter("ray2_intensity", PIECE_ATTACH_RAYS_RAY2_INTENSITY)
	material.set_shader_parameter("core_intensity", PIECE_ATTACH_RAYS_CORE_INTENSITY)
	material.set_shader_parameter("size", PIECE_ATTACH_RAYS_START_SIZE)
	material.set_shader_parameter("alpha_strength", 0.0)
	material.set_shader_parameter("seed", PIECE_ATTACH_RAYS_SEED)
	overlay.material = material

	holder.add_child(overlay)
	return overlay

func apply_piece_attach_rays_overlay_transform(overlay: Sprite2D, holder: Sprite2D) -> void:
	if overlay == null or !is_instance_valid(overlay) or holder == null or !is_instance_valid(holder):
		return

	overlay.texture = get_piece_attach_rays_square_texture()
	overlay.centered = true
	overlay.offset = Vector2.ZERO
	overlay.flip_h = false
	overlay.flip_v = false
	overlay.region_enabled = false
	overlay.hframes = 1
	overlay.vframes = 1
	overlay.frame = 0
	overlay.light_mask = PIECE_EFFECT_LIGHT_RECEIVE_MASK

	var holder_texture_size: Vector2 = holder.texture.get_size() if holder.texture != null else Vector2.ONE * PIECE_ATTACH_RAYS_TEXTURE_SIZE
	var square_side: float = maxf(holder_texture_size.x, holder_texture_size.y)
	var overlay_scale_value: float = (square_side / float(PIECE_ATTACH_RAYS_TEXTURE_SIZE)) * PIECE_ATTACH_RAYS_OVERLAY_SCALE
	overlay.scale = Vector2.ONE * overlay_scale_value
	overlay.position = holder.offset + PIECE_ATTACH_RAYS_LOCAL_OFFSET

func get_piece_attach_rays_square_texture() -> Texture2D:
	if piece_attach_rays_square_texture != null:
		return piece_attach_rays_square_texture

	var image := Image.create(PIECE_ATTACH_RAYS_TEXTURE_SIZE, PIECE_ATTACH_RAYS_TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	piece_attach_rays_square_texture = ImageTexture.create_from_image(image)
	return piece_attach_rays_square_texture

func create_piece_attach_rays_gradient_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_offset(0, 0.0)
	gradient.set_color(0, Color(1.0, 0.42, 0.0, 0.0))
	gradient.set_offset(1, 1.0)
	gradient.set_color(1, Color(1.0, 0.96, 0.03, 1.0))
	gradient.add_point(0.18, Color(1.0, 0.48, 0.02, 0.10))
	gradient.add_point(0.42, Color(1.0, 0.52, 0.02, 0.72))
	gradient.add_point(0.72, Color(1.0, 0.74, 0.03, 0.96))

	var texture := GradientTexture1D.new()
	texture.width = 256
	texture.gradient = gradient
	return texture

func sync_piece_attach_overlay_to_holder(overlay: Sprite2D, holder: Sprite2D) -> void:
	if overlay == null or !is_instance_valid(overlay) or holder == null or !is_instance_valid(holder):
		return

	overlay.texture = holder.texture
	overlay.centered = holder.centered
	overlay.offset = holder.offset
	overlay.flip_h = holder.flip_h
	overlay.flip_v = holder.flip_v
	overlay.region_enabled = holder.region_enabled
	overlay.region_rect = holder.region_rect
	overlay.hframes = holder.hframes
	overlay.vframes = holder.vframes
	overlay.frame = holder.frame
	overlay.light_mask = PIECE_EFFECT_LIGHT_RECEIVE_MASK
	overlay.position = Vector2.ZERO
	overlay.rotation = 0.0
	overlay.scale = Vector2.ONE

func remove_piece_attach_effects(holder: Sprite2D) -> void:
	if holder == null or !is_instance_valid(holder):
		return

	for effect_name in [PIECE_ATTACH_GLOW_NAME, PIECE_ATTACH_RAYS_NAME, PIECE_ATTACH_MORPH_NAME]:
		var existing_effect: Node = holder.get_node_or_null(effect_name)
		if existing_effect != null:
			existing_effect.free()

func get_attach_animation_positions(animations: Array[Dictionary]) -> Dictionary:
	var positions: Dictionary = {}
	for animation: Dictionary in animations:
		var board_pos: Vector2 = value_to_vector2(animation.get("position", INVALID_BOARD_POS), INVALID_BOARD_POS)
		if is_valid_position(board_pos):
			positions[board_pos] = true
	return positions

func finish_resolved_pending_card_attach_processes(excluded_positions: Dictionary = {}) -> void:
	for position_value in pending_card_attach_positions.keys():
		var board_pos: Vector2 = value_to_vector2(position_value, INVALID_BOARD_POS)
		if excluded_positions.has(board_pos):
			continue
		if !piece_objects.has(board_pos):
			finish_card_attach_process(position_value)
			continue

		finish_card_attach_process(position_value)

func clear_resolved_pending_card_attach_positions() -> void:
	for position_value in pending_card_attach_positions.keys():
		var board_pos: Vector2 = value_to_vector2(position_value, INVALID_BOARD_POS)
		if !piece_objects.has(board_pos):
			finish_card_attach_process(position_value)

func display_board():
	DebugLog.info("display_board() called: white=%s side=%s" % [white, side])
	clear_resolved_pending_card_attach_positions()
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
			holder.light_mask = PIECE_LIGHT_RECEIVE_MASK
			holder.position = get_board_position_local_position(Vector2(i, j))
			holder.set_meta("board_pos", Vector2(i, j))
			holder.z_index = get_piece_depth_z_index(Vector2(i, j))
			holder.texture = get_piece_texture_for_position(Vector2(i, j), int(board[i][j]))
			apply_piece_visual_size(holder, Vector2(i, j))
			apply_piece_light_occluder(holder, Vector2(i, j))
			apply_piece_shadow(holder, Vector2(i, j))
			apply_piece_exhausted_material(holder, Vector2(i, j))
			apply_selected_piece_glow(holder, Vector2(i, j))

	if white: turn.texture = TURN_WHITE
	else: turn.texture = TURN_BLACK

func apply_selected_piece_glow(holder: Sprite2D, board_pos: Vector2) -> void:
	remove_selected_piece_glow(holder)
	if !state or board_pos != selected_piece or holder.texture == null:
		return
	if !piece_objects.has(board_pos):
		return

	create_piece_glow_overlay(holder, SELECTED_PIECE_GLOW_NAME, SELECTED_PIECE_GLOW_Z_INDEX, SELECTED_PIECE_GLOW_STRENGTH)

func remove_selected_piece_glow(holder: Sprite2D) -> void:
	var existing_glow: Node = holder.get_node_or_null(SELECTED_PIECE_GLOW_NAME)
	if existing_glow != null:
		existing_glow.free()

func update_selected_piece_glow() -> void:
	if pieces_node == null:
		return

	for child in pieces_node.get_children():
		var holder: Sprite2D = child as Sprite2D
		if holder == null:
			continue

		var board_pos: Vector2 = value_to_vector2(holder.get_meta("board_pos", INVALID_BOARD_POS), INVALID_BOARD_POS)
		apply_selected_piece_glow(holder, board_pos)

func apply_piece_exhausted_material(holder: Sprite2D, board_pos: Vector2) -> void:
	holder.material = null
	if !piece_objects.has(board_pos):
		return

	var piece: Piece = piece_objects[board_pos] as Piece
	if piece == null:
		return

	if piece.exhausted_this_turn:
		var exhausted_material := ShaderMaterial.new()
		exhausted_material.shader = PIECE_EXHAUSTED_SHADER
		holder.material = exhausted_material
		return

	if should_apply_opponent_piece_recolor(holder, piece):
		holder.material = create_opponent_piece_recolor_material()

func should_apply_opponent_piece_recolor(holder: Sprite2D, piece: Piece) -> bool:
	if holder.texture != DEFAULT_PIECE_TEXTURE:
		return false
	return piece.color * get_own_color() < 0

func create_opponent_piece_recolor_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = OPPONENT_PIECE_RECOLOR_SHADER
	material.set_shader_parameter("recolor_strength", OPPONENT_PIECE_RECOLOR_STRENGTH)
	material.set_shader_parameter("shadow_chroma_strength", OPPONENT_PIECE_SHADOW_CHROMA)
	material.set_shader_parameter("shadow_color", OPPONENT_PIECE_SHADOW_COLOR)
	material.set_shader_parameter("mid_color", OPPONENT_PIECE_MID_COLOR)
	material.set_shader_parameter("highlight_color", OPPONENT_PIECE_HIGHLIGHT_COLOR)
	return material

func show_options():
	moves = get_moves(selected_piece)
	if moves == []:
		state = false
		update_selected_piece_glow()
		return
	delete_dots()
	show_dots()
	update_selected_piece_glow()
	show_hover_piece_details(selected_piece)

func show_dots():
	for i in moves:
		var holder = TEXTURE_HOLDER.instantiate()
		dots.add_child(holder)
		holder.texture = PIECE_MOVE
		holder.position = get_board_position_local_position(i)

func delete_dots():
	for child in dots.get_children():
		child.queue_free()

func set_move(start_pos : Vector2, end_pos : Vector2, promotion = null):
	if game_over:
		return

	DebugLog.info("set_move() start: white=%s start=%s end=%s piece=%s" % [white, start_pos, end_pos, board[start_pos.x][start_pos.y]])
	var moving_color: int = 1 if board[start_pos.x][start_pos.y] > 0 else -1
	var captured_piece: Piece = piece_objects[end_pos] as Piece if piece_objects.has(end_pos) else null
	var captured_nexus: bool = is_nexus_piece(captured_piece)
	var moving_piece_visible_to_enemy: bool = true

	if piece_objects.has(start_pos):
		var piece: Piece = piece_objects[start_pos] as Piece
		moving_piece_visible_to_enemy = !CardEffectResolver.piece_has_attached_effect(piece, CardEffect.TYPE_INVISIBLE_TO_ENEMY)
		piece.position = end_pos
		piece_objects.erase(start_pos)
		piece_objects[end_pos] = piece
		DebugLog.info("  Piece moved: %s -> %s" % [start_pos, end_pos])

	var just_now = false

	board[end_pos.x][end_pos.y] = board[start_pos.x][start_pos.y]
	board[start_pos.x][start_pos.y] = 0

	if captured_nexus:
		return_captured_nexus_card_to_deck(captured_piece)
	if captured_piece != null:
		captured_piece.detach_card()

	record_last_move_locally(moving_color, start_pos, end_pos, moving_piece_visible_to_enemy)
	piece_moved.emit(start_pos, end_pos, moving_color)

	var winner_color: int = get_winner_after_move(moving_color, end_pos)
	if winner_color != 0:
		display_board()
		finish_game(winner_color)
		return

	var moving_piece: Piece = piece_objects[end_pos] as Piece if piece_objects.has(end_pos) else null
	if moving_piece != null:
		apply_local_card_effect_trigger(CardEffect.TRIGGER_ON_MOVE, end_pos, moving_piece, moving_piece.attached_card)
	consume_moved_piece_duration_locally(moving_piece, end_pos)
	if game_over:
		display_board()
		return

	if captured_piece != null:
		respawn_captured_piece_locally(captured_piece)

	mark_piece_moved_this_turn(moving_color)
	update_card_presentation()
	DebugLog.info("set_move() end: waiting for END TURN")

	display_board()

	if (start_pos.x != end_pos.x || start_pos.y != end_pos.y) && (white && board[end_pos.x][end_pos.y] > 0 || !white && board[end_pos.x][end_pos.y] < 0):
		start_pos = end_pos
		show_options()
		state = true

func return_captured_nexus_card_to_deck(captured_piece: Piece) -> void:
	if captured_piece == null or captured_piece.attached_card == null:
		return
	DeckManager.return_card_to_deck(get_card_deck(captured_piece.color), captured_piece.attached_card.card_name)

func record_last_move_locally(moving_color: int, from_pos: Vector2, to_pos: Vector2, visible_to_enemy: bool) -> void:
	if from_pos == to_pos:
		current_last_move = {}
		return

	current_last_move = {
		"from": from_pos,
		"to": to_pos,
		"player_id": get_player_id_for_color(moving_color),
		"piece_color": moving_color,
		"visible_to_enemy": visible_to_enemy,
	}

func record_played_card_hand_slot(owner_color: int, current_hand_index: int) -> void:
	if current_hand_index < 0:
		return
	var played_slots: Array = played_card_hand_slots_this_turn.get(owner_color, [])
	played_slots.append(get_original_hand_slot_for_play(owner_color, current_hand_index))
	played_card_hand_slots_this_turn[owner_color] = played_slots

func get_original_hand_slot_for_play(owner_color: int, current_hand_index: int) -> int:
	var played_slots: Array = played_card_hand_slots_this_turn.get(owner_color, [])
	for candidate in range(current_hand_index, DeckManager.HAND_SIZE):
		if played_slots.has(candidate):
			continue

		var previous_slots_before_candidate: int = 0
		for slot_value in played_slots:
			if int(slot_value) < candidate:
				previous_slots_before_candidate += 1
		if candidate - previous_slots_before_candidate == current_hand_index:
			return candidate
	return clampi(current_hand_index, 0, DeckManager.HAND_SIZE - 1)

func refill_played_cards_locally(owner_color: int) -> void:
	var played_slots: Array = played_card_hand_slots_this_turn.get(owner_color, [])
	if played_slots.is_empty():
		return

	played_slots.sort()
	for slot_value in played_slots:
		var hand: Array[Card] = get_card_hand(owner_color)
		if hand.size() >= DeckManager.HAND_SIZE:
			break

		var card_name: String = draw_refill_card_name(owner_color)
		if card_name.is_empty():
			break
		insert_drawn_card(owner_color, int(slot_value), card_name)

	played_card_hand_slots_this_turn[owner_color] = []

func consume_moved_piece_duration_locally(piece: Piece, piece_pos: Vector2) -> void:
	if piece == null or piece.attached_card == null:
		return

	var owner_color: int = piece.color
	var expired_card: Card = piece.use_turn()
	if expired_card == null:
		return

	if MoveRules.is_nexus_card(expired_card):
		handle_expired_nexus_card_locally(owner_color, expired_card)
		return

	queue_card_expire_animation(piece_pos, expired_card)

func respawn_captured_piece_locally(captured_piece: Piece) -> bool:
	if captured_piece == null:
		return false

	var respawn_pos: Vector2 = get_random_empty_home_position_locally(captured_piece.color)
	if respawn_pos == INVALID_BOARD_POS:
		push_warning("No empty home row square for captured piece respawn.")
		return false

	captured_piece.position = respawn_pos
	captured_piece.exhausted_this_turn = false
	piece_objects[respawn_pos] = captured_piece
	board[respawn_pos.x][respawn_pos.y] = captured_piece.color
	return true

func get_random_empty_home_position_locally(owner_color: int) -> Vector2:
	var player_id: int = get_player_id_for_color(owner_color)
	var home_row: int = BoardConfig.get_home_row_for_player_id(player_id)
	var empty_positions: Array[Vector2] = []
	for col in BoardConfig.BOARD_SIZE:
		var pos: Vector2 = Vector2(home_row, col)
		if !piece_objects.has(pos):
			empty_positions.append(pos)

	if empty_positions.is_empty():
		return INVALID_BOARD_POS

	return empty_positions[randi() % empty_positions.size()]

func player_has_available_nexus_card(owner_color: int) -> bool:
	for card: Card in get_card_hand(owner_color):
		if MoveRules.is_nexus_card(card):
			return true
	if DeckManager.has_nexus_card(get_card_deck(owner_color)):
		return true
	for position_value in piece_objects:
		var piece: Piece = piece_objects[position_value] as Piece
		if piece != null && piece.color == owner_color && MoveRules.is_nexus_card(piece.attached_card):
			return true
	return false

func get_winner_after_move(moving_color: int, end_pos: Vector2) -> int:
	if is_opponent_base_field(moving_color, end_pos) && is_nexus_piece_at(end_pos):
		return moving_color
	return 0

func is_opponent_base_field(moving_color: int, pos: Vector2) -> bool:
	if moving_color == 1:
		return pos == BLACK_BASE_FIELD
	return pos == WHITE_BASE_FIELD

func has_any_piece(owner_color: int) -> bool:
	return MoveRules.has_any_piece(piece_objects, owner_color)

func is_nexus_piece(piece: Piece) -> bool:
	return piece != null && MoveRules.is_nexus_card(piece.attached_card)

func is_nexus_piece_at(piece_position: Vector2) -> bool:
	if !piece_objects.has(piece_position):
		return false
	return is_nexus_piece(piece_objects[piece_position] as Piece)

func current_player_has_valid_turn_action() -> bool:
	var current_color: int = get_current_turn_color()
	if has_moved_piece_this_turn(current_color):
		return can_exchange_card_locally(current_color)
	var hand_cards: Array[Card] = get_card_hand(current_color)
	var can_attach_card: bool = true
	if MoveRules.has_valid_turn_action(piece_objects, current_color, hand_cards, can_attach_card, BOARD_SIZE, current_board_effects):
		return true
	if can_exchange_card_locally(current_color):
		return true
	return false

func finish_if_current_player_has_no_valid_turn() -> bool:
	if game_over:
		return false
	if current_player_has_valid_turn_action():
		return false

	var losing_color: int = get_current_turn_color()
	var winner_color: int = -losing_color
	DebugLog.info("No valid moves for player: %s. Winner: %s" % [losing_color, winner_color])
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
	award_win_points_if_applicable(winner_color)
	show_result_message(winner_color)

	var result_wait_seconds: float = 0.05 if should_skip_visual_animations() else 8.0
	await get_tree().create_timer(result_wait_seconds).timeout
	var next_scene: String = get_next_scene_after_game(winner_color)
	if get_parent().has_method("close_game_connection"):
		get_parent().close_game_connection()
	if get_tree():
		get_tree().change_scene_to_file(next_scene)

func get_next_scene_after_game(winner_color: int) -> String:
	if GameConfig.is_ai_vs_ai_batch:
		var winner_player_id: int = get_player_id_for_color(winner_color)
		GameConfig.record_ai_vs_ai_result(winner_player_id)
		DebugLog.info("AI vs AI match %d/%d finished. White wins: %d, Black wins: %d" % [
			GameConfig.ai_vs_ai_matches_played,
			GameConfig.ai_vs_ai_match_count,
			int(GameConfig.ai_vs_ai_results.get(0, 0)),
			int(GameConfig.ai_vs_ai_results.get(1, 0)),
		])

		if GameConfig.should_continue_ai_vs_ai_batch():
			return "res://Scenes/main.tscn"

		GameConfig.stop_ai_vs_ai_batch()

	return MAIN_MENU_SCENE

func award_win_points_if_applicable(winner_color: int) -> void:
	if !should_award_win_points(winner_color):
		return

	PlayerProgressStore.add_points(PlayerProgressStore.WIN_POINTS_PER_WIN)

func should_award_win_points(winner_color: int) -> bool:
	if tutorial_mode_active:
		return false
	if GameConfig.is_ai_vs_ai_batch:
		return false

	if side == null:
		if GameConfig.is_singleplayer:
			var winner_player_id: int = get_player_id_for_color(winner_color)
			return GameConfig.get_player_controller(winner_player_id) == GameConfig.CONTROLLER_HUMAN
		return true

	return winner_color == get_own_color()

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
			DebugLog.info("Using card movement: %s" % piece.get_info())
			return get_card_based_moves(selected, piece, get_move_preview_player_id(selected, piece))
		else:
			DebugLog.info("No usable card on this piece.")
			return []

	return []

func get_move_preview_player_id(piece_position: Vector2, piece: Piece) -> int:
	var own_player_id: int = get_own_player_id()
	if can_control_current_turn() && can_player_control_piece_at(piece_position, own_player_id):
		return own_player_id
	return get_player_id_for_color(piece.color)

func get_card_based_moves(piece_position: Vector2, piece: Piece, player_id: int) -> Array:
	var valid_moves: Array[Vector2] = MoveRules.get_piece_moves_for_player(piece_objects, piece_position, player_id, BOARD_SIZE, current_board_effects)
	valid_moves = filter_tutorial_move_targets(piece_position, valid_moves, piece.color)
	DebugLog.info("  Valid moves: %s" % [valid_moves])
	return valid_moves

func filter_tutorial_move_targets(from_pos: Vector2, candidate_moves: Array[Vector2], owner_color: int) -> Array[Vector2]:
	if !tutorial_constraints_enabled:
		return candidate_moves

	var filtered_moves: Array[Vector2] = []
	for to_pos: Vector2 in candidate_moves:
		if is_tutorial_action_allowed(TUTORIAL_ACTION_MOVE_PIECE, {
			"owner_color": owner_color,
			"from_pos": from_pos,
			"to_pos": to_pos,
		}):
			filtered_moves.append(to_pos)
	return filtered_moves

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

func update_from_server_state(pieces_data: Dictionary, player_hands: Dictionary, current_turn: int, server_game_over: bool = false, winner_player: int = -1, player_deck_sizes: Dictionary = {}, hidden_cards: Array = [], player_base_fields: Dictionary = {}, board_effects: Array = [], player_names: Dictionary = {}, recent_card_transfers: Array = [], recent_card_expirations: Array = [], last_move: Dictionary = {}):
	var previous_piece_visual_state: Dictionary = get_piece_visual_state_snapshot()
	var previous_white_hand_names: Array[String] = get_card_names_from_hand(white_card_hand)
	var previous_black_hand_names: Array[String] = get_card_names_from_hand(black_card_hand)

	board = BoardConfig.create_empty_board()

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
				piece.exhausted_this_turn = bool(data.get("exhausted_this_turn", false))

		piece_objects[piece_position] = piece
		if is_valid_position(piece_position):
			board[piece_position.x][piece_position.y] = piece_color

	var was_white_turn: bool = white
	white = current_turn == 0
	var should_emit_turn_ended: bool = false
	var server_ending_color: int = 0
	if was_white_turn != white:
		reset_current_turn_card_attach()
		if has_received_server_state:
			should_emit_turn_ended = true
			server_ending_color = 1 if was_white_turn else -1

	var current_white_hand_names: Array = get_hand_names_from_state(player_hands, 0)
	var current_black_hand_names: Array = get_hand_names_from_state(player_hands, 1)
	if !player_deck_sizes.is_empty():
		white_deck_count_override = get_int_from_state_dict(player_deck_sizes, 0, white_card_deck.size())
		black_deck_count_override = get_int_from_state_dict(player_deck_sizes, 1, black_card_deck.size())
	current_player_base_fields = parse_player_base_fields(player_base_fields)
	current_board_effects = parse_board_effects(board_effects)
	current_player_names = parse_player_names(player_names)
	current_last_move = parse_last_move(last_move)
	white_card_hand = create_card_hand_from_names(current_white_hand_names)
	black_card_hand = create_card_hand_from_names(current_black_hand_names)
	white_card_visuals = populate_card_hand(white_pieces, white_card_hand, 1)
	black_card_visuals = populate_card_hand(black_pieces, black_card_hand, -1)
	setup_deck_visuals()

	delete_dots()
	hide_hover_piece_details()
	update_hidden_card_previews(hidden_cards)
	update_card_presentation()
	var state_attach_animations: Array[Dictionary] = collect_state_attach_animations(previous_piece_visual_state)
	var animated_attach_positions: Dictionary = get_attach_animation_positions(state_attach_animations)
	display_board()
	finish_resolved_pending_card_attach_processes(animated_attach_positions)
	if !state_attach_animations.is_empty():
		call_deferred("play_state_attach_animations", state_attach_animations)
	if has_received_server_state && !should_skip_visual_animations():
		if recent_card_transfers.is_empty():
			animate_state_draw_if_needed(1, previous_white_hand_names, current_white_hand_names)
			animate_state_draw_if_needed(-1, previous_black_hand_names, current_black_hand_names)
		else:
			animate_recent_card_transfers(recent_card_transfers, previous_white_hand_names, current_white_hand_names, previous_black_hand_names, current_black_hand_names)
		animate_recent_card_expirations(recent_card_expirations)
	if should_emit_turn_ended:
		turn_ended.emit(server_ending_color, get_current_turn_color())
	has_received_server_state = true

	if server_game_over && winner_player != -1:
		finish_game(get_color_for_player_id(winner_player))

func should_skip_visual_animations() -> bool:
	return GameConfig.should_skip_ai_vs_ai_delays()

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
		card_visual.set_preview_alpha(HIDDEN_CARD_PREVIEW_ALPHA)
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

func arrange_rules_info_panel():
	if rules_info_panel == null:
		return

	var board_screen_size: float = BOARD_SIZE * CELL_WIDTH * get_board_screen_scale()
	var left_offset: float = -board_screen_size * 0.5 - RULES_INFO_PANEL_MARGIN - RULES_INFO_PANEL_SIZE.x
	var top_offset: float = -board_screen_size * 0.5
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var min_top_offset: float = -viewport_size.y * 0.5 + RULES_INFO_PANEL_MARGIN
	var max_top_offset: float = viewport_size.y * 0.5 - RULES_INFO_PANEL_SIZE.y - RULES_INFO_PANEL_MARGIN
	left_offset = max(left_offset, -viewport_size.x * 0.5 + RULES_INFO_PANEL_MARGIN)
	top_offset = min_top_offset if max_top_offset < min_top_offset else clampf(top_offset, min_top_offset, max_top_offset)
	rules_info_panel.offset_left = left_offset
	rules_info_panel.offset_right = left_offset + RULES_INFO_PANEL_SIZE.x
	rules_info_panel.offset_top = top_offset
	rules_info_panel.offset_bottom = top_offset + RULES_INFO_PANEL_SIZE.y

func arrange_action_status_ui() -> void:
	if action_status_container == null:
		return

	var board_screen_size: float = BOARD_SIZE * CELL_WIDTH * get_board_screen_scale()
	var left_offset: float = board_screen_size * 0.5 + ACTION_STATUS_MARGIN
	var top_offset: float = -ACTION_STATUS_SIZE.y * 0.5
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var max_left_offset: float = viewport_size.x * 0.5 - ACTION_STATUS_SIZE.x - ACTION_STATUS_MARGIN
	if left_offset > max_left_offset:
		left_offset = -board_screen_size * 0.5 - ACTION_STATUS_MARGIN - ACTION_STATUS_SIZE.x
	var min_left_offset: float = -viewport_size.x * 0.5 + ACTION_STATUS_MARGIN
	left_offset = max(left_offset, min_left_offset)
	action_status_container.offset_left = left_offset
	action_status_container.offset_right = left_offset + ACTION_STATUS_SIZE.x
	action_status_container.offset_top = top_offset
	action_status_container.offset_bottom = top_offset + ACTION_STATUS_SIZE.y

func get_board_screen_scale() -> float:
	var camera: Camera2D = $"../Camera2D"
	if camera == null:
		return absf(global_scale.x)
	return absf(camera.zoom.x) * absf(global_scale.x)

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

func parse_last_move(last_move: Dictionary) -> Dictionary:
	if last_move.is_empty():
		return {}

	var from_pos: Vector2 = value_to_vector2(last_move.get("from", INVALID_BOARD_POS), INVALID_BOARD_POS)
	var to_pos: Vector2 = value_to_vector2(last_move.get("to", INVALID_BOARD_POS), INVALID_BOARD_POS)
	if !is_valid_position(from_pos) or !is_valid_position(to_pos) or from_pos == to_pos:
		return {}

	return {
		"from": from_pos,
		"to": to_pos,
		"player_id": int(last_move.get("player_id", -1)),
		"piece_color": int(last_move.get("piece_color", 0)),
		"visible_to_enemy": bool(last_move.get("visible_to_enemy", true)),
	}

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

	if PlayerSettingsStore.is_enemy_attack_markers_enabled():
		add_enemy_attack_markers()
	if PlayerSettingsStore.is_last_move_arrow_enabled():
		add_last_move_arrow_marker()

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
		var base_pos: Vector2 = current_player_base_fields.get(player_id, BoardConfig.get_base_field_for_player_id(player_id))
		if is_valid_position(base_pos):
			add_board_base_marker(base_pos, player_id)

func add_enemy_attack_markers():
	var enemy_color: int = -get_local_view_color()
	var attacked_squares: Array[Vector2] = MoveRules.get_attacked_squares_for_player(piece_objects, enemy_color, BOARD_SIZE, current_board_effects)
	for square_pos: Vector2 in attacked_squares:
		add_board_square_fill(square_pos, Color(1.0, 0.05, 0.03, 0.105))

func add_last_move_arrow_marker():
	if current_last_move.is_empty() or !bool(current_last_move.get("visible_to_enemy", true)):
		return

	var mover_color: int = int(current_last_move.get("piece_color", 0))
	if mover_color == 0 or mover_color == get_local_view_color():
		return

	var from_pos: Vector2 = value_to_vector2(current_last_move.get("from", INVALID_BOARD_POS), INVALID_BOARD_POS)
	var to_pos: Vector2 = value_to_vector2(current_last_move.get("to", INVALID_BOARD_POS), INVALID_BOARD_POS)
	if !is_valid_position(from_pos) or !is_valid_position(to_pos) or from_pos == to_pos:
		return
	if !piece_objects.has(to_pos):
		return

	add_board_arrow(from_pos, to_pos, LAST_MOVE_ARROW_COLOR, LAST_MOVE_ARROW_WIDTH)

func add_board_square_fill(board_pos: Vector2, marker_color: Color):
	var marker := Polygon2D.new()
	marker.color = marker_color
	marker.polygon = get_board_cell_polygon_local(board_pos)
	enable_canvas_item_antialiasing(marker)
	board_markers_node.add_child(marker)

func add_board_square_x_marker(board_pos: Vector2, line_color: Color, fill_color: Color):
	add_board_square_fill(board_pos, fill_color)
	var points: PackedVector2Array = get_board_cell_polygon_local(board_pos, CELL_WIDTH * 0.22)
	add_board_line([points[0], points[2]], line_color, BOARD_MARKER_LINE_WIDTH)
	add_board_line([points[3], points[1]], line_color, BOARD_MARKER_LINE_WIDTH)

func add_board_base_marker(board_pos: Vector2, player_id: int):
	var outer_polygon: PackedVector2Array = get_board_cell_polygon_local(board_pos, CELL_WIDTH * 0.08)
	var marker_color: Color = Color(1.0, 1.0, 1.0, 1.0) if player_id == 0 else Color(0.0, 0.0, 0.0, 1.0)
	add_board_polygon_outline(outer_polygon, marker_color, BOARD_MARKER_LINE_WIDTH * 1.5)

func add_board_polygon_outline(points: PackedVector2Array, line_color: Color, line_width: float):
	if points.size() < 2:
		return

	var line_points: Array = []
	for point: Vector2 in points:
		line_points.append(point)
	line_points.append(points[0])
	add_board_line(line_points, line_color, line_width)

func add_board_line(points: Array, line_color: Color, line_width: float):
	var line := Line2D.new()
	line.default_color = line_color
	line.width = line_width
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	enable_canvas_item_antialiasing(line)
	for point_value in points:
		line.add_point(point_value)
	board_markers_node.add_child(line)

func add_board_arrow(from_pos: Vector2, to_pos: Vector2, arrow_color: Color, line_width: float):
	var start_point: Vector2 = get_board_position_local_position(from_pos)
	var end_point: Vector2 = get_board_position_local_position(to_pos)
	var direction: Vector2 = end_point - start_point
	if direction.length() <= 0.0:
		return

	var normalized_direction: Vector2 = direction.normalized()
	var perpendicular: Vector2 = Vector2(-normalized_direction.y, normalized_direction.x)
	start_point += normalized_direction * LAST_MOVE_ARROW_ENDPOINT_INSET
	end_point -= normalized_direction * LAST_MOVE_ARROW_ENDPOINT_INSET

	var arrow_head := Polygon2D.new()
	var head_base: Vector2 = end_point - normalized_direction * LAST_MOVE_ARROW_HEAD_LENGTH
	add_board_line([start_point, head_base], arrow_color, line_width)
	arrow_head.color = arrow_color
	arrow_head.polygon = PackedVector2Array([
		end_point,
		head_base + perpendicular * LAST_MOVE_ARROW_HEAD_HALF_WIDTH,
		head_base - perpendicular * LAST_MOVE_ARROW_HEAD_HALF_WIDTH,
	])
	enable_canvas_item_antialiasing(arrow_head)
	board_markers_node.add_child(arrow_head)

func get_board_cell_rect_local(board_pos: Vector2) -> Rect2:
	return get_points_bounds_local(get_board_cell_polygon_local(board_pos))
