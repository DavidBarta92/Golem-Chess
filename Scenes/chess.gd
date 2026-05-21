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
const PORTRAIT_VIEW = preload("res://Scenes/PortraitView.tscn")

const BOARD_TILE_TEXTURE = preload("res://Assets/board_tile.svg")
const BOARD_TILE_BASE_WHITE_TEXTURE = preload("res://Assets/board_tile_base_white.svg")
const BOARD_TILE_BASE_BLACK_TEXTURE = preload("res://Assets/board_tile_base_black.svg")
const BOARD_TILE_FREEZE_TEXTURE = preload("res://Assets/board_tile_freeze.svg")
const BOARD_TILE_DISABLED_TEXTURE = preload("res://Assets/board_tile_disabled.svg")

const DEFAULT_PIECE_TEXTURE = preload("res://Assets/golem_front.svg")
const OWN_DEFAULT_PIECE_TEXTURE = preload("res://Assets/golem_back.svg")

const TURN_WHITE = preload("res://Assets/turn-white.png")
const TURN_BLACK = preload("res://Assets/turn-black.png")
const DECK_COUNTER_DIGITS_TEXTURE = preload("res://Assets/deck_counter_digits.png")
const DECK_COUNTER_BACKGROUND_TEXTURE = preload("res://Assets/counter_backround.png")
const DECK_COUNTER_FRAME_TEXTURE = preload("res://Assets/counter_frame.png")
const DECK_COUNTER_SHADOW_TEXTURE = preload("res://Assets/counter_shadow.png")

const PIECE_MOVE = preload("res://Assets/Piece_move.png")
const PIECE_FREEZE_CRACK_SHADER = preload("res://Shaders/piece_freeze_crack.gdshader")
const DECK_COUNTER_DIGIT_SHADER = preload("res://Shaders/deck_counter_digit.gdshader")
const PIECE_ATTACH_GLOW_SHADER = preload("res://Shaders/piece_attach_glow.gdshader")
const PIECE_ATTACH_RAYS_SHADER = preload("res://Shaders/piece_attach_rays.gdshader")
const PIECE_TEXTURE_MORPH_SHADER = preload("res://Shaders/piece_texture_morph.gdshader")
const PIECE_INVISIBILITY_REFRACT_SHADER = preload("res://Shaders/piece_invisibility_refract.gdshader")
const PIECE_EXPIRE_DISSOLVE_SHADER = preload("res://Shaders/piece_expire_dissolve.gdshader")
const BOARD_VISUAL_SCALE: float = 1.08
# Adjust these values to tune the board-only perspective tilt.
const BOARD_PERSPECTIVE_ENABLED: bool = true
const BOARD_PERSPECTIVE_TOP_SCALE: float = 0.74
const BOARD_PERSPECTIVE_BOTTOM_SCALE: float = 1.05
const BOARD_PERSPECTIVE_VERTICAL_SCALE: float = 0.72
const BOARD_SPECIAL_TILE_NONE: String = ""
const BOARD_SPECIAL_TILE_BASE_WHITE: String = "base_white"
const BOARD_SPECIAL_TILE_BASE_BLACK: String = "base_black"
const BOARD_SPECIAL_TILE_FREEZE: String = "freeze"
const BOARD_SPECIAL_TILE_DISABLED: String = "disabled"
const BOARD_SPECIAL_TILE_Z_INDEX: int = 1
const BOARD_TILE_SWAP_DURATION: float = 0.26
const BOARD_TILE_SINK_OFFSET: float = 7.0
const BOARD_TILE_SUNK_ALPHA: float = 0.32
const BOARD_TILE_SLIDE_DISTANCE_FACTOR: float = 1.06
const BOARD_TILE_DEPTH_WALL_COLOR = Color(0.07, 0.065, 0.055, 0.86)
const BOARD_TILE_OCCLUSION_LIP_COLOR = Color(0.0, 0.0, 0.0, 0.30)
const BOARD_TILE_OCCLUSION_LIP_INSET_FACTOR: float = 0.18
const BOARD_TILE_TRANSITION_COVER_Z_INDEX: int = 5
const DEFAULT_PIECE_VISUAL_HEIGHT: float = 24.0
const PIECE_AUTO_FIT_HEIGHT_THRESHOLD: float = DEFAULT_PIECE_VISUAL_HEIGHT * 2.0
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
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_FIXED_RADIUS_Y: float = 3.0
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_BOTTOM_INSET_FACTOR: float = 0.05
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_OFFSET = Vector2.ZERO
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_SEGMENTS: int = 18
const PIECE_FOOTPRINT_ALPHA_THRESHOLD: float = 0.04
const PIECE_FOOTPRINT_WIDTH_SCAN_START_RATIO: float = 0.6666667
const PIECE_FOOTPRINT_STABLE_WIDTH_BAND_RATIO: float = 0.25
const PIECE_FOOTPRINT_STABLE_ROW_SAMPLE_COUNT: int = 8
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_MIN_RADIUS_BOUNDS_FACTOR: float = 0.22
const BOARD_LIGHT_RECEIVE_MASK: int = 1
const PIECE_LIGHT_OCCLUDER_MASK: int = 1
const PIECE_LIGHT_RECEIVE_MASK: int = 2
const PIECE_EFFECT_LIGHT_RECEIVE_MASK: int = 0
const PIECE_TEXTURE_FILTER = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
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
const PLAYER_HAND_SIZE = DeckManager.HAND_SIZE
const CARD_UI_SIZE = Vector2(164, 229)
const CARD_HAND_SCALE = 0.648
const DECK_CARD_SCALE = CARD_HAND_SCALE
const CARD_UI_GAP = 10
const TOP_CARD_HAND_MARGIN = -28
const BOTTOM_CARD_HAND_MARGIN = 34
const HOVER_CARD_MARGIN = 24
const HOVER_CARD_PREVIEW_SCALE: float = 0.82
const HOVER_CARD_VERTICAL_OFFSET: float = 54.0
const HOVER_CARD_ROTATION_DEGREES: float = -4.0
const HOVER_PIECE_PREVIEW_SIZE = Vector2(188, 224)
const HOVER_PIECE_PREVIEW_VERTICAL_OFFSET: float = -78.0
const HOVER_DESCRIPTION_GAP = 14
const HOVER_DESCRIPTION_SIZE = Vector2(260, 118)
const HIDDEN_CARD_MARGIN = 24
const HIDDEN_CARD_GAP = 10
const HIDDEN_CARD_SCALE = 0.70 * 0.75
const HIDDEN_CARD_PREVIEW_ALPHA: float = 0.70
const BOARD_MARKER_LINE_WIDTH = 1.8
const CARD_ATTACH_TARGET_FILL_COLOR = Color(1.0, 0.92, 0.58, 0.24)
const CARD_ATTACH_TARGET_FILL_INSET: float = 1.0
const CARD_ATTACH_TARGET_WIGGLE_RISE: float = 2.2
const CARD_ATTACH_TARGET_WIGGLE_ROTATION_DEGREES: float = 2.2
const CARD_ATTACH_TARGET_WIGGLE_STEP_DURATION: float = 0.105
const SELECTED_PIECE_GLOW_NAME = "SelectedPieceGlow"
const SELECTED_PIECE_GLOW_Z_INDEX = 24
const SELECTED_PIECE_GLOW_STRENGTH: float = 1.0
const PIECE_FREEZE_CRACK_NAME = "PieceFreezeCrack"
const PIECE_FREEZE_CRACK_Z_INDEX = 0
const PIECE_FREEZE_CRACK_DURATION: float = 1.5
const PIECE_FREEZE_CRACK_RELEASE_DURATION: float = 1.5
const PIECE_FREEZE_CRACK_START_WIDTH: float = 0.0
const PIECE_FREEZE_CRACK_END_WIDTH: float = 0.7
const PIECE_FREEZE_CRACK_DEPTH: float = 2.46
const PIECE_FREEZE_CRACK_SCALE: float = 7.96
const PIECE_FREEZE_CRACK_ZEBRA_SCALE: float = 1.61
const PIECE_FREEZE_CRACK_ZEBRA_AMP: float = 1.33
const PIECE_FREEZE_CRACK_PROFILE: float = 0.33
const PIECE_FREEZE_CRACK_SLOPE: float = 13.03
const PIECE_FREEZE_REFRACTION_OFFSET = Vector2(24.92, 25.0)
const PIECE_FREEZE_REFLECTION_OFFSET = Vector2(1.28, 1.0)
const PIECE_FREEZE_RELEASE_NAME = "PieceFreezeRelease"
const PIECE_FREEZE_SQUARE_NAME = "PieceFreezeSquare"
const PIECE_FREEZE_SQUARE_RELEASE_NAME = "PieceFreezeSquareRelease"
const PIECE_FREEZE_SQUARE_Z_INDEX: int = 0
const PIECE_FREEZE_SQUARE_INSET: float = 0.0
const PIECE_FREEZE_SQUARE_ALPHA: float = 0.74
const PIECE_ATTACH_GLOW_NAME = "PieceAttachGlow"
const PIECE_ATTACH_RAYS_NAME = "PieceAttachRays"
const PIECE_ATTACH_MORPH_NAME = "PieceAttachMorph"
const PIECE_ATTACH_GLOW_Z_INDEX = 30
const PIECE_ATTACH_MORPH_Z_INDEX = 31
const PIECE_ATTACH_RAYS_Z_INDEX = 34
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
const PIECE_INVISIBILITY_VISIBLE_HOLD_DURATION: float = 0.50
const PIECE_INVISIBILITY_REFRACT_IN_DURATION: float = 0.42
const PIECE_INVISIBILITY_FADE_OUT_DURATION: float = 1.48
const PIECE_INVISIBILITY_REFRACT_DISTANCE: float = 16.0
const PIECE_EXPIRE_DISSOLVE_DURATION: float = 1.62
const PIECE_EXPIRE_DISSOLVE_BEAM_SIZE: float = 0.05
const PIECE_EXPIRE_DISSOLVE_NOISE_DENSITY: float = 60.0
const PIECE_EXPIRE_DISSOLVE_COLOR = Color(1.0, 0.42, 0.02, 1.0)
const LAST_MOVE_ARROW_WIDTH = 3.0
const LAST_MOVE_ARROW_ENDPOINT_INSET = 6.0
const LAST_MOVE_ARROW_HEAD_LENGTH = 8.0
const LAST_MOVE_ARROW_HEAD_HALF_WIDTH = 5.0
const LAST_MOVE_ARROW_COLOR = Color(1.0, 0.88, 0.18, 1.0)
const DECK_COUNT_LABEL_SIZE = Vector2(88, 28)
const DECK_COUNT_LABEL_GAP = 8
const DECK_COUNTER_BACKGROUND_SIZE = Vector2(38, 38)
const DECK_COUNTER_DIGIT_SIZE = DECK_COUNTER_BACKGROUND_SIZE
const DECK_COUNTER_DIGIT_GAP: float = 0.0
const DECK_COUNTER_FRAME_SIZE = Vector2(82, 42)
const DECK_COUNTER_CONTENT_OFFSET = Vector2(
	(DECK_COUNTER_FRAME_SIZE.x - (DECK_COUNTER_BACKGROUND_SIZE.x * 2.0 + DECK_COUNTER_DIGIT_GAP)) * 0.5,
	(DECK_COUNTER_FRAME_SIZE.y - DECK_COUNTER_BACKGROUND_SIZE.y) * 0.5
)
const DECK_COUNTER_SIZE = DECK_COUNTER_FRAME_SIZE
const DECK_COUNTER_ROLL_DURATION: float = 0.34
const DECK_COUNTER_MOTION_BLUR: float = 1.0
const DECK_COUNTER_OFFSET = Vector2(0.0, 0.0)
const DECK_COUNTER_Z_INDEX: int = 952
const TURN_TIMER_LIMIT_SECONDS: int = 20
const TURN_TIMER_COUNTER_KEY: int = 0
const TURN_TIMER_GAP: float = 8.0
const TURN_TIMER_Z_INDEX: int = 961
const PLAYER_NAME_LABEL_SIZE = Vector2(180, 28)
const PLAYER_NAME_LABEL_GAP = 8
const PLAYER_PORTRAIT_SIZE = Vector2(232, 272)
const PLAYER_PORTRAIT_MARGIN = 22
const PLAYER_PORTRAIT_Z_INDEX: int = 928
const RULES_INFO_BUTTON_SIZE = Vector2(40, 40)
const RULES_INFO_PANEL_SIZE = Vector2(310, 286)
const RULES_INFO_PANEL_MARGIN = 24
const ACTION_STATUS_SIZE = Vector2(132, 46)
const ACTION_STATUS_MARGIN = 22
const ACTION_STATUS_CELL_SIZE = Vector2(36, 42)
const ACTION_STATUS_CELL_GAP: int = 7
const ACTION_STATUS_FLIP_DURATION: float = 0.16
const ACTION_STATUS_ACTIVE_COLOR = Color(1.0, 1.0, 1.0, 1.0)
const ACTION_STATUS_ACTIVE_TEXT_COLOR = Color(0.05, 0.05, 0.045, 1.0)
const ACTION_STATUS_ACTIVE_BORDER_COLOR = Color(0.12, 0.10, 0.075, 1.0)
const ACTION_STATUS_INACTIVE_COLOR = Color(0.94, 0.93, 0.89, 1.0)
const ACTION_STATUS_BLOCKED_COLOR = Color(0.02, 0.02, 0.02, 1.0)
const ACTION_STATUS_STATE_ACTIVE: String = "active"
const ACTION_STATUS_STATE_EMPTY: String = "empty"
const ACTION_STATUS_STATE_BLOCKED: String = "blocked"
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
var hover_piece_preview: TextureRect
var hover_duration_label: Label
var hover_description_panel: PanelContainer
var hover_description_label: Label
var result_overlay: ColorRect
var result_label: Label
var has_received_server_state: bool = false
var deck_count_label: Label
var deck_counter_containers: Dictionary = {}
var deck_counter_digit_nodes: Dictionary = {}
var deck_counter_digit_materials: Dictionary = {}
var deck_counter_values: Dictionary = {
	1: -1,
	-1: -1,
}
var deck_counter_roll_values: Dictionary = {}
var deck_counter_tweens: Dictionary = {}
var turn_timer_counter_container: Control
var turn_timer_remaining_seconds: int = TURN_TIMER_LIMIT_SECONDS
var turn_timer_elapsed_seconds: float = 0.0
var turn_timer_turn_color: int = 0
var turn_timer_timeout_pending: bool = false
var player_name_labels: Dictionary = {}
var player_portrait_views: Dictionary = {}
var quit_confirmation_dialog: ConfirmationDialog
var end_turn_button: Button
var rules_info_button: Button
var rules_info_panel: PanelContainer
var rules_info_label: Label
var action_status_container: HBoxContainer
var action_status_cells: Dictionary = {}
var action_status_labels: Dictionary = {}
var action_status_states: Dictionary = {}
var action_status_tweens: Dictionary = {}
var white_deck_count_override: int = -1
var black_deck_count_override: int = -1
var hidden_card_preview_container: Control
var hidden_card_previews: Array[CardVisual] = []
var hidden_card_counts: Dictionary = {}
var board_markers_node: Node2D
var board_base_tiles_node: Node2D
var board_special_tiles_node: Node2D
var board_special_tile_nodes: Dictionary = {}
var board_special_tile_types: Dictionary = {}
var board_special_tiles_initialized: bool = false
var piece_effects_node: Node2D
var card_attach_target_marker: Node2D
var card_attach_target_position: Vector2 = INVALID_BOARD_POS
var card_attach_target_piece: Sprite2D
var card_attach_target_piece_base_position: Vector2 = Vector2.ZERO
var card_attach_target_piece_base_rotation: float = 0.0
var card_attach_target_piece_tween: Tween
var attach_point_light_texture: Texture2D
var piece_attach_rays_square_texture: Texture2D
var piece_freeze_visual_signatures: Dictionary = {}
var piece_footprint_metrics_cache: Dictionary = {}
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
var current_player_portraits: Dictionary = {}
var pending_card_burn_animations: Array = []
var card_burn_animation_sequence_running: bool = false
var pending_piece_revert_animations: Array[Dictionary] = []
var active_piece_revert_animation_count: int = 0
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
	create_piece_effects_node()
	create_ambient_board_light()
	board = BoardConfig.create_starting_board()

	create_pieces_from_board()
	setup_player_card_hands()
	create_hover_piece_ui()
	create_hidden_card_preview_ui()
	create_result_ui()
	create_deck_count_ui()
	create_deck_counter_ui()
	initialize_player_portraits()
	create_player_portrait_ui()
	create_player_name_ui()
	create_quit_confirmation_ui()
	create_end_turn_ui()
	create_rules_info_ui()
	create_action_status_ui()
	create_turn_timer_ui()
	if !get_viewport().size_changed.is_connected(update_player_portrait_views):
		get_viewport().size_changed.connect(update_player_portrait_views)
	update_player_name_labels()
	update_player_portrait_views()

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
		child.free()

	board_special_tile_nodes.clear()
	board_special_tile_types.clear()
	board_special_tiles_initialized = false

	board_base_tiles_node = Node2D.new()
	board_base_tiles_node.name = "BaseTiles"
	board_base_tiles_node.z_index = 0
	board_tiles_node.add_child(board_base_tiles_node)

	board_special_tiles_node = Node2D.new()
	board_special_tiles_node.name = "SpecialTiles"
	board_special_tiles_node.z_index = 1
	board_tiles_node.add_child(board_special_tiles_node)

	for row in BOARD_SIZE:
		for col in BOARD_SIZE:
			var board_pos := Vector2(row, col)
			var tile := create_board_tile_polygon(board_pos, BOARD_TILE_TEXTURE)
			tile.name = "BoardTile_%d_%d" % [row, col]
			board_base_tiles_node.add_child(tile)

func create_board_tile_polygon(board_pos: Vector2, tile_texture: Texture2D) -> Polygon2D:
	var tile := Polygon2D.new()
	tile.texture = tile_texture
	tile.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tile.color = Color.WHITE
	tile.set_meta("board_pos", board_pos)
	refresh_board_tile_polygon(tile, board_pos)
	enable_canvas_item_antialiasing(tile)
	return tile

func refresh_board_tile_polygon(tile: Polygon2D, board_pos: Vector2) -> void:
	if tile == null or !is_instance_valid(tile):
		return

	var polygon: PackedVector2Array = get_board_cell_polygon_local(board_pos)
	tile.set_meta("board_pos", board_pos)
	tile.polygon = polygon
	tile.uv = get_board_tile_texture_uvs(tile.texture)

func get_board_tile_texture_uvs(tile_texture: Texture2D) -> PackedVector2Array:
	var texture_size := Vector2.ONE
	if tile_texture != null:
		texture_size = tile_texture.get_size()
	return PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(texture_size.x, 0.0),
		Vector2(texture_size.x, texture_size.y),
		Vector2(0.0, texture_size.y),
	])

func update_board_special_tiles() -> void:
	if board_special_tiles_node == null or !is_instance_valid(board_special_tiles_node):
		return

	var animate_changes: bool = board_special_tiles_initialized
	var target_tiles: Dictionary = get_board_special_tile_targets()
	var previous_types: Dictionary = board_special_tile_types.duplicate()

	for position_value in previous_types.keys():
		var board_pos: Vector2 = value_to_vector2(position_value, INVALID_BOARD_POS)
		if !is_valid_position(board_pos):
			continue

		var previous_type: String = str(previous_types[position_value])
		var target_type: String = str(target_tiles.get(board_pos, BOARD_SPECIAL_TILE_NONE))
		if previous_type == target_type:
			var existing_tile: Polygon2D = board_special_tile_nodes.get(board_pos, null) as Polygon2D
			if existing_tile != null and is_instance_valid(existing_tile):
				refresh_board_tile_polygon(existing_tile, board_pos)
				continue
			board_special_tile_nodes.erase(board_pos)
			board_special_tile_types.erase(board_pos)

		var old_tile: Polygon2D = board_special_tile_nodes.get(board_pos, null) as Polygon2D
		if old_tile != null and is_instance_valid(old_tile):
			animate_board_tile_out(old_tile, animate_changes)
		board_special_tile_nodes.erase(board_pos)
		board_special_tile_types.erase(board_pos)

	for position_value in target_tiles.keys():
		var board_pos: Vector2 = value_to_vector2(position_value, INVALID_BOARD_POS)
		if !is_valid_position(board_pos):
			continue

		var target_type: String = str(target_tiles[position_value])
		var existing_tile: Polygon2D = board_special_tile_nodes.get(board_pos, null) as Polygon2D
		if str(previous_types.get(board_pos, BOARD_SPECIAL_TILE_NONE)) == target_type and existing_tile != null and is_instance_valid(existing_tile):
			continue

		if animate_changes and !previous_types.has(board_pos):
			var base_clone := create_board_tile_polygon(board_pos, BOARD_TILE_TEXTURE)
			base_clone.name = "BoardTileSink_%d_%d" % [int(board_pos.x), int(board_pos.y)]
			base_clone.z_index = BOARD_SPECIAL_TILE_Z_INDEX
			board_special_tiles_node.add_child(base_clone)
			animate_board_tile_out(base_clone, true)

		var new_tile := create_board_tile_polygon(board_pos, get_board_special_tile_texture(target_type))
		new_tile.name = "BoardSpecialTile_%s_%d_%d" % [target_type, int(board_pos.x), int(board_pos.y)]
		new_tile.z_index = BOARD_SPECIAL_TILE_Z_INDEX + 2
		board_special_tiles_node.add_child(new_tile)
		board_special_tile_nodes[board_pos] = new_tile
		board_special_tile_types[board_pos] = target_type
		animate_board_tile_in(new_tile, board_pos, animate_changes)

	board_special_tiles_initialized = true

func get_board_special_tile_targets() -> Dictionary:
	var targets: Dictionary = {}
	for player_id in [0, 1]:
		var base_pos: Vector2 = current_player_base_fields.get(player_id, BoardConfig.get_base_field_for_player_id(player_id))
		if !is_valid_position(base_pos):
			continue
		set_board_special_tile_target(
			targets,
			base_pos,
			BOARD_SPECIAL_TILE_BASE_WHITE if player_id == 0 else BOARD_SPECIAL_TILE_BASE_BLACK
		)

	for effect_value in current_board_effects:
		var effect: Dictionary = effect_value
		var effect_type: String = str(effect.get("effect_type", ""))
		var tile_type: String = BOARD_SPECIAL_TILE_NONE
		if effect_type == CardEffect.TYPE_INVALID_SQUARES:
			tile_type = BOARD_SPECIAL_TILE_DISABLED
		elif effect_type == CardEffect.TYPE_FROZEN_SQUARES:
			tile_type = BOARD_SPECIAL_TILE_FREEZE
		if tile_type == BOARD_SPECIAL_TILE_NONE:
			continue

		var squares: Array = effect.get("squares", [])
		for square_value in squares:
			var square_pos: Vector2 = value_to_vector2(square_value, INVALID_BOARD_POS)
			if is_valid_position(square_pos):
				set_board_special_tile_target(targets, square_pos, tile_type)

	return targets

func set_board_special_tile_target(targets: Dictionary, board_pos: Vector2, tile_type: String) -> void:
	var current_type: String = str(targets.get(board_pos, BOARD_SPECIAL_TILE_NONE))
	if get_board_special_tile_priority(tile_type) >= get_board_special_tile_priority(current_type):
		targets[board_pos] = tile_type

func get_board_special_tile_priority(tile_type: String) -> int:
	match tile_type:
		BOARD_SPECIAL_TILE_BASE_WHITE, BOARD_SPECIAL_TILE_BASE_BLACK:
			return 1
		BOARD_SPECIAL_TILE_FREEZE:
			return 2
		BOARD_SPECIAL_TILE_DISABLED:
			return 3
		_:
			return 0

func get_board_special_tile_texture(tile_type: String) -> Texture2D:
	match tile_type:
		BOARD_SPECIAL_TILE_BASE_WHITE:
			return BOARD_TILE_BASE_WHITE_TEXTURE
		BOARD_SPECIAL_TILE_BASE_BLACK:
			return BOARD_TILE_BASE_BLACK_TEXTURE
		BOARD_SPECIAL_TILE_FREEZE:
			return BOARD_TILE_FREEZE_TEXTURE
		BOARD_SPECIAL_TILE_DISABLED:
			return BOARD_TILE_DISABLED_TEXTURE
		_:
			return BOARD_TILE_TEXTURE

func animate_board_tile_out(tile: Polygon2D, animate_change: bool) -> void:
	if tile == null or !is_instance_valid(tile):
		return
	if !animate_change:
		tile.queue_free()
		return

	var board_pos: Vector2 = value_to_vector2(tile.get_meta("board_pos", INVALID_BOARD_POS), INVALID_BOARD_POS)
	var sink_offset: Vector2 = get_board_tile_sink_offset()
	if is_valid_position(board_pos):
		animate_board_tile_depth_wall(board_pos, sink_offset, BOARD_TILE_SWAP_DURATION)
		create_temporary_board_tile_cover(get_board_tile_near_neighbor_position(board_pos), BOARD_TILE_SWAP_DURATION)
		create_temporary_board_tile_edge_lip(board_pos, get_board_tile_near_edge_indices(), BOARD_TILE_SWAP_DURATION)

	tile.z_index = BOARD_SPECIAL_TILE_Z_INDEX + 1
	tile.position = Vector2.ZERO
	tile.modulate = Color.WHITE
	var tween := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tile, "position", sink_offset, BOARD_TILE_SWAP_DURATION)
	tween.parallel().tween_property(tile, "modulate:a", BOARD_TILE_SUNK_ALPHA, BOARD_TILE_SWAP_DURATION)
	tween.finished.connect(func():
		if is_instance_valid(tile):
			tile.queue_free()
	)

func animate_board_tile_in(tile: Polygon2D, board_pos: Vector2, animate_change: bool) -> void:
	if tile == null or !is_instance_valid(tile):
		return
	if !animate_change:
		tile.position = Vector2.ZERO
		tile.modulate = Color.WHITE
		return

	var slide_offset: Vector2 = get_board_tile_slide_offset(board_pos)
	create_temporary_board_tile_cover(get_board_tile_slide_cover_position(board_pos, slide_offset), BOARD_TILE_SWAP_DURATION)
	create_temporary_board_tile_edge_lip(board_pos, get_board_tile_entry_edge_indices(slide_offset), BOARD_TILE_SWAP_DURATION)

	tile.position = slide_offset
	tile.modulate = Color.WHITE
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tile, "position", Vector2.ZERO, BOARD_TILE_SWAP_DURATION)

func get_board_tile_slide_offset(board_pos: Vector2) -> Vector2:
	var bounds: Rect2 = get_board_cell_rect_local(board_pos)
	var distance: float = maxf(bounds.size.x, bounds.size.y) * BOARD_TILE_SLIDE_DISTANCE_FACTOR
	match randi() % 4:
		0:
			return Vector2(distance, 0.0)
		1:
			return Vector2(-distance, 0.0)
		2:
			return Vector2(0.0, distance)
		_:
			return Vector2(0.0, -distance)

func get_board_tile_sink_offset() -> Vector2:
	return get_board_near_direction_local() * BOARD_TILE_SINK_OFFSET

func get_board_near_direction_local() -> Vector2:
	return Vector2(0.0, -1.0) if get_board_view_color() < 0 else Vector2(0.0, 1.0)

func get_board_tile_near_neighbor_position(board_pos: Vector2) -> Vector2:
	var row_delta: int = 1 if get_board_view_color() < 0 else -1
	return board_pos + Vector2(row_delta, 0.0)

func get_board_tile_far_neighbor_position(board_pos: Vector2) -> Vector2:
	var row_delta: int = -1 if get_board_view_color() < 0 else 1
	return board_pos + Vector2(row_delta, 0.0)

func get_board_tile_near_edge_indices() -> Array:
	if get_board_view_color() < 0:
		return [0, 1]
	return [2, 3]

func get_board_tile_far_edge_indices() -> Array:
	if get_board_view_color() < 0:
		return [2, 3]
	return [0, 1]

func get_board_tile_entry_edge_indices(slide_offset: Vector2) -> Array:
	if absf(slide_offset.x) > absf(slide_offset.y):
		if slide_offset.x > 0.0:
			return [1, 2]
		return [3, 0]
	if slide_offset.y * get_board_near_direction_local().y > 0.0:
		return get_board_tile_near_edge_indices()
	return get_board_tile_far_edge_indices()

func get_board_tile_slide_cover_position(board_pos: Vector2, slide_offset: Vector2) -> Vector2:
	if absf(slide_offset.x) > absf(slide_offset.y):
		var col_delta: int = 1 if slide_offset.x > 0.0 else -1
		return board_pos + Vector2(0.0, col_delta)
	if slide_offset.y * get_board_near_direction_local().y > 0.0:
		return get_board_tile_near_neighbor_position(board_pos)
	return get_board_tile_far_neighbor_position(board_pos)

func animate_board_tile_depth_wall(board_pos: Vector2, sink_offset: Vector2, duration: float) -> void:
	if board_special_tiles_node == null or !is_instance_valid(board_special_tiles_node):
		return

	var wall := Polygon2D.new()
	wall.name = "BoardTileDepthWall_%d_%d" % [int(board_pos.x), int(board_pos.y)]
	wall.color = BOARD_TILE_DEPTH_WALL_COLOR
	wall.z_index = BOARD_SPECIAL_TILE_Z_INDEX + BOARD_TILE_TRANSITION_COVER_Z_INDEX - 1
	enable_canvas_item_antialiasing(wall)
	board_special_tiles_node.add_child(wall)
	set_board_tile_depth_wall_polygon(wall, board_pos, sink_offset, 0.0)

	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_method(set_board_tile_depth_wall_progress.bind(wall, board_pos, sink_offset), 0.0, 1.0, duration)
	tween.finished.connect(func():
		if is_instance_valid(wall):
			wall.queue_free()
	)

func set_board_tile_depth_wall_progress(progress: float, wall: Polygon2D, board_pos: Vector2, sink_offset: Vector2) -> void:
	if is_instance_valid(wall):
		set_board_tile_depth_wall_polygon(wall, board_pos, sink_offset, progress)

func set_board_tile_depth_wall_polygon(wall: Polygon2D, board_pos: Vector2, sink_offset: Vector2, progress: float) -> void:
	if wall == null or !is_instance_valid(wall):
		return

	var polygon: PackedVector2Array = get_board_cell_polygon_local(board_pos)
	if polygon.size() < 4:
		return

	var edge_indices: Array = get_board_tile_far_edge_indices()
	var edge_a: Vector2 = polygon[int(edge_indices[0])]
	var edge_b: Vector2 = polygon[int(edge_indices[1])]
	var current_offset: Vector2 = sink_offset * clampf(progress, 0.0, 1.0)
	wall.polygon = PackedVector2Array([
		edge_a,
		edge_b,
		edge_b + current_offset,
		edge_a + current_offset,
	])
	wall.modulate = Color(1.0, 1.0, 1.0, clampf(progress * 1.15, 0.0, 1.0))

func create_temporary_board_tile_cover(board_pos: Vector2, duration: float) -> void:
	if board_special_tiles_node == null or !is_instance_valid(board_special_tiles_node):
		return
	if !is_valid_position(board_pos):
		return

	var cover := create_board_tile_polygon(board_pos, get_board_visible_tile_texture(board_pos))
	cover.name = "BoardTileTransitionCover_%d_%d" % [int(board_pos.x), int(board_pos.y)]
	cover.z_index = BOARD_SPECIAL_TILE_Z_INDEX + BOARD_TILE_TRANSITION_COVER_Z_INDEX
	board_special_tiles_node.add_child(cover)
	var tween := create_tween()
	tween.tween_interval(duration)
	tween.finished.connect(func():
		if is_instance_valid(cover):
			cover.queue_free()
	)

func create_temporary_board_tile_edge_lip(board_pos: Vector2, edge_indices: Array, duration: float) -> void:
	if board_special_tiles_node == null or !is_instance_valid(board_special_tiles_node):
		return
	if !is_valid_position(board_pos) or edge_indices.size() < 2:
		return

	var polygon: PackedVector2Array = get_board_cell_polygon_local(board_pos)
	if polygon.size() < 4:
		return

	var center: Vector2 = get_board_position_local_position(board_pos)
	var edge_a: Vector2 = polygon[int(edge_indices[0])]
	var edge_b: Vector2 = polygon[int(edge_indices[1])]
	var lip := Polygon2D.new()
	lip.name = "BoardTileTransitionLip_%d_%d" % [int(board_pos.x), int(board_pos.y)]
	lip.color = BOARD_TILE_OCCLUSION_LIP_COLOR
	lip.z_index = BOARD_SPECIAL_TILE_Z_INDEX + BOARD_TILE_TRANSITION_COVER_Z_INDEX + 1
	lip.polygon = PackedVector2Array([
		edge_a,
		edge_b,
		edge_b.lerp(center, BOARD_TILE_OCCLUSION_LIP_INSET_FACTOR),
		edge_a.lerp(center, BOARD_TILE_OCCLUSION_LIP_INSET_FACTOR),
	])
	enable_canvas_item_antialiasing(lip)
	board_special_tiles_node.add_child(lip)

	var tween := create_tween()
	tween.tween_interval(duration)
	tween.finished.connect(func():
		if is_instance_valid(lip):
			lip.queue_free()
	)

func get_board_visible_tile_texture(board_pos: Vector2) -> Texture2D:
	var tile_type: String = str(board_special_tile_types.get(board_pos, BOARD_SPECIAL_TILE_NONE))
	return get_board_special_tile_texture(tile_type)

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

func create_piece_effects_node() -> void:
	if piece_effects_node != null and is_instance_valid(piece_effects_node):
		return

	piece_effects_node = Node2D.new()
	piece_effects_node.name = "PieceEffects"
	piece_effects_node.z_index = 12
	add_child(piece_effects_node)

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

	hover_piece_preview = TextureRect.new()
	canvas_layer.add_child(hover_piece_preview)
	hover_piece_preview.visible = false
	hover_piece_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_piece_preview.anchor_left = 1.0
	hover_piece_preview.anchor_right = 1.0
	hover_piece_preview.anchor_top = 0.5
	hover_piece_preview.anchor_bottom = 0.5
	hover_piece_preview.offset_left = -HOVER_PIECE_PREVIEW_SIZE.x - HOVER_CARD_MARGIN
	hover_piece_preview.offset_right = -HOVER_CARD_MARGIN
	hover_piece_preview.offset_top = -HOVER_PIECE_PREVIEW_SIZE.y * 0.5 + HOVER_PIECE_PREVIEW_VERTICAL_OFFSET
	hover_piece_preview.offset_bottom = HOVER_PIECE_PREVIEW_SIZE.y * 0.5 + HOVER_PIECE_PREVIEW_VERTICAL_OFFSET
	hover_piece_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hover_piece_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hover_piece_preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	hover_piece_preview.z_index = 899

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
	hover_card_preview.offset_top = -CARD_UI_SIZE.y * 0.5 + HOVER_CARD_VERTICAL_OFFSET
	hover_card_preview.offset_bottom = CARD_UI_SIZE.y * 0.5 + HOVER_CARD_VERTICAL_OFFSET
	hover_card_preview.set_rest_scale(Vector2.ONE * HOVER_CARD_PREVIEW_SCALE)
	hover_card_preview.rotation_degrees = HOVER_CARD_ROTATION_DEGREES
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

func create_deck_counter_ui() -> void:
	for owner_color in [1, -1]:
		var counter_container := create_digit_counter_container("DeckCounter%d" % owner_color, owner_color)
		deck_counter_containers[owner_color] = counter_container

	update_deck_counter_ui(false)

func create_digit_counter_container(counter_name: String, digit_owner_key: int) -> Control:
	var counter_container := Control.new()
	canvas_layer.add_child(counter_container)
	counter_container.name = counter_name
	counter_container.visible = false
	counter_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter_container.size = DECK_COUNTER_SIZE
	counter_container.z_index = DECK_COUNTER_Z_INDEX

	var frame_rect := TextureRect.new()
	counter_container.add_child(frame_rect)
	frame_rect.name = "Frame"
	frame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_rect.texture = DECK_COUNTER_FRAME_TEXTURE
	frame_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	frame_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame_rect.stretch_mode = TextureRect.STRETCH_SCALE
	frame_rect.size = DECK_COUNTER_FRAME_SIZE
	frame_rect.position = Vector2.ZERO
	frame_rect.z_index = 0

	var digit_nodes: Array = []
	for digit_index in range(2):
		var digit_position := DECK_COUNTER_CONTENT_OFFSET + Vector2(digit_index * (DECK_COUNTER_BACKGROUND_SIZE.x + DECK_COUNTER_DIGIT_GAP), 0.0)

		var background_rect := TextureRect.new()
		counter_container.add_child(background_rect)
		background_rect.name = "Background%d" % digit_index
		background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background_rect.texture = DECK_COUNTER_BACKGROUND_TEXTURE
		background_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background_rect.stretch_mode = TextureRect.STRETCH_SCALE
		background_rect.size = DECK_COUNTER_BACKGROUND_SIZE
		background_rect.position = digit_position
		background_rect.z_index = 1

		var digit_rect := TextureRect.new()
		counter_container.add_child(digit_rect)
		digit_rect.name = "Digit%d" % digit_index
		digit_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		digit_rect.texture = DECK_COUNTER_DIGITS_TEXTURE
		digit_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		digit_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		digit_rect.stretch_mode = TextureRect.STRETCH_SCALE
		digit_rect.size = DECK_COUNTER_DIGIT_SIZE
		digit_rect.position = digit_position
		digit_rect.z_index = 2

		var digit_material := ShaderMaterial.new()
		digit_material.shader = DECK_COUNTER_DIGIT_SHADER
		digit_material.set_shader_parameter("digit_atlas", DECK_COUNTER_DIGITS_TEXTURE)
		digit_material.set_shader_parameter("roll_value", 0.0)
		digit_material.set_shader_parameter("roll_direction", 1.0)
		digit_material.set_shader_parameter("motion_blur", 0.0)
		digit_material.set_shader_parameter("frame_count", 10.0)
		digit_rect.material = digit_material

		var digit_key: String = get_deck_counter_digit_key(digit_owner_key, digit_index)
		deck_counter_digit_materials[digit_key] = digit_material
		deck_counter_roll_values[digit_key] = 0.0
		digit_nodes.append(digit_rect)

		var shadow_rect := TextureRect.new()
		counter_container.add_child(shadow_rect)
		shadow_rect.name = "Shadow%d" % digit_index
		shadow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow_rect.texture = DECK_COUNTER_SHADOW_TEXTURE
		shadow_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		shadow_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shadow_rect.stretch_mode = TextureRect.STRETCH_SCALE
		shadow_rect.size = DECK_COUNTER_BACKGROUND_SIZE
		shadow_rect.position = digit_position
		shadow_rect.z_index = 3

	deck_counter_digit_nodes[digit_owner_key] = digit_nodes
	return counter_container

func update_deck_counter_ui(animate: bool = true) -> void:
	for owner_color in [1, -1]:
		var counter_container: Control = deck_counter_containers.get(owner_color, null) as Control
		if counter_container == null:
			continue

		var deck_visual: CardVisual = get_deck_visual(owner_color)
		if game_over or deck_visual == null or !is_instance_valid(deck_visual) or !deck_visual.visible:
			counter_container.visible = false
			continue

		var deck_rect: Rect2 = deck_visual.get_global_rect()
		counter_container.global_position = deck_rect.get_center() - DECK_COUNTER_SIZE * 0.5 + DECK_COUNTER_OFFSET
		counter_container.visible = true
		set_deck_counter_value(owner_color, get_card_deck_count(owner_color), animate)

func set_deck_counter_value(owner_color: int, count: int, animate: bool) -> void:
	var safe_count: int = clampi(count, 0, 99)
	var previous_count: int = int(deck_counter_values.get(owner_color, -1))
	if previous_count == safe_count:
		return

	deck_counter_values[owner_color] = safe_count
	var should_animate: bool = animate and previous_count >= 0
	var direction: int = 1
	if should_animate and safe_count < previous_count:
		direction = -1

	var tens_digit: int = floori(float(safe_count) / 10.0)
	var ones_digit: int = safe_count % 10
	update_deck_counter_digit(owner_color, 0, tens_digit, direction, should_animate)
	update_deck_counter_digit(owner_color, 1, ones_digit, direction, should_animate)

func update_deck_counter_digit(owner_color: int, digit_index: int, target_digit: int, direction: int, animate: bool) -> void:
	var digit_key: String = get_deck_counter_digit_key(owner_color, digit_index)
	var digit_material: ShaderMaterial = deck_counter_digit_materials.get(digit_key, null) as ShaderMaterial
	if digit_material == null:
		return

	var previous_tween: Tween = deck_counter_tweens.get(digit_key, null) as Tween
	if previous_tween != null:
		previous_tween.kill()
		deck_counter_tweens.erase(digit_key)

	var current_roll: float = float(deck_counter_roll_values.get(digit_key, float(target_digit)))
	var target_roll: float = float(target_digit)
	if animate:
		target_roll = get_deck_counter_target_roll(current_roll, target_digit, direction)

	deck_counter_roll_values[digit_key] = target_roll
	digit_material.set_shader_parameter("roll_direction", float(direction))
	if !animate or is_equal_approx(current_roll, target_roll):
		digit_material.set_shader_parameter("roll_value", target_roll)
		digit_material.set_shader_parameter("motion_blur", 0.0)
		return

	digit_material.set_shader_parameter("motion_blur", DECK_COUNTER_MOTION_BLUR)
	var tween := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	deck_counter_tweens[digit_key] = tween
	tween.tween_property(digit_material, "shader_parameter/roll_value", target_roll, DECK_COUNTER_ROLL_DURATION)
	tween.parallel().tween_property(digit_material, "shader_parameter/motion_blur", 0.0, DECK_COUNTER_ROLL_DURATION)
	tween.finished.connect(func():
		if deck_counter_tweens.get(digit_key, null) == tween:
			deck_counter_tweens.erase(digit_key)
		if is_instance_valid(digit_material):
			digit_material.set_shader_parameter("roll_value", target_roll)
			digit_material.set_shader_parameter("motion_blur", 0.0)
	)

func get_deck_counter_target_roll(current_roll: float, target_digit: int, direction: int) -> float:
	var current_digit: int = positive_mod_int(roundi(current_roll), 10)
	if direction >= 0:
		var forward_steps: int = positive_mod_int(target_digit - current_digit, 10)
		return current_roll + float(forward_steps)

	var backward_steps: int = positive_mod_int(current_digit - target_digit, 10)
	return current_roll - float(backward_steps)

func get_deck_counter_digit_key(owner_color: int, digit_index: int) -> String:
	return "%d_%d" % [owner_color, digit_index]

func positive_mod_int(value: int, divisor: int) -> int:
	var result: int = value % divisor
	if result < 0:
		result += divisor
	return result

func initialize_player_portraits() -> void:
	current_player_portraits = {
		0: PortraitLibrary.get_default_portrait_for_player_id(0),
		1: PortraitLibrary.get_default_portrait_for_player_id(1),
	}

func create_player_portrait_ui() -> void:
	player_portrait_views[1] = create_player_portrait_view()
	player_portrait_views[-1] = create_player_portrait_view()
	update_player_portrait_views()

func create_player_portrait_view() -> PortraitView:
	var portrait_view: PortraitView = PORTRAIT_VIEW.instantiate() as PortraitView
	canvas_layer.add_child(portrait_view)
	portrait_view.visible = false
	portrait_view.size = PLAYER_PORTRAIT_SIZE
	portrait_view.custom_minimum_size = PLAYER_PORTRAIT_SIZE
	portrait_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_view.z_index = PLAYER_PORTRAIT_Z_INDEX
	portrait_view.show_frame = true
	return portrait_view

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
	action_status_container = HBoxContainer.new()
	canvas_layer.add_child(action_status_container)
	action_status_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_status_container.anchor_left = 0.5
	action_status_container.anchor_right = 0.5
	action_status_container.anchor_top = 0.5
	action_status_container.anchor_bottom = 0.5
	action_status_container.custom_minimum_size = ACTION_STATUS_SIZE
	action_status_container.z_index = 910
	action_status_container.add_theme_constant_override("separation", ACTION_STATUS_CELL_GAP)

	var label_settings := LabelSettings.new()
	label_settings.font_size = 25
	label_settings.font_color = ACTION_STATUS_ACTIVE_TEXT_COLOR
	label_settings.outline_size = 0

	var action_letters: Dictionary = {
		"Switch": "S",
		"Attach": "A",
		"Move": "M",
	}
	for action_name in ["Switch", "Attach", "Move"]:
		var action_cell := PanelContainer.new()
		action_status_container.add_child(action_cell)
		action_cell.custom_minimum_size = ACTION_STATUS_CELL_SIZE
		action_cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		action_cell.pivot_offset = ACTION_STATUS_CELL_SIZE * 0.5
		action_cell.scale = Vector2.ONE

		var action_label := Label.new()
		action_cell.add_child(action_label)
		action_label.text = str(action_letters[action_name])
		action_label.custom_minimum_size = ACTION_STATUS_CELL_SIZE
		action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		action_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		action_label.label_settings = label_settings.duplicate()
		action_status_cells[action_name] = action_cell
		action_status_labels[action_name] = action_label

	arrange_action_status_ui()
	update_action_status_ui()

func create_turn_timer_ui() -> void:
	turn_timer_counter_container = create_digit_counter_container("TurnTimerCounter", TURN_TIMER_COUNTER_KEY)
	turn_timer_counter_container.z_index = TURN_TIMER_Z_INDEX
	set_deck_counter_value(TURN_TIMER_COUNTER_KEY, TURN_TIMER_LIMIT_SECONDS, false)
	reset_turn_timer()
	arrange_turn_timer_ui()
	update_turn_timer_visibility()

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
	update_player_portrait_views()
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

func update_player_portrait_views() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	for owner_color in [1, -1]:
		var portrait_view: PortraitView = player_portrait_views.get(owner_color, null) as PortraitView
		if portrait_view == null or !is_instance_valid(portrait_view):
			continue

		var player_id: int = get_player_id_for_color(owner_color)
		portrait_view.set_portrait_config(get_portrait_config_for_player(player_id))
		portrait_view.set_turn_focus(owner_color == get_current_turn_color())
		portrait_view.size = PLAYER_PORTRAIT_SIZE
		portrait_view.visible = true

		var is_top_portrait: bool = is_card_hand_top(owner_color)
		var portrait_y: float = PLAYER_PORTRAIT_MARGIN
		if !is_top_portrait:
			portrait_y = viewport_size.y - PLAYER_PORTRAIT_SIZE.y - PLAYER_PORTRAIT_MARGIN

		portrait_view.position = Vector2(PLAYER_PORTRAIT_MARGIN, maxf(PLAYER_PORTRAIT_MARGIN, portrait_y))

func get_portrait_config_for_player(player_id: int) -> PortraitConfig:
	if current_player_portraits.has(player_id):
		return PortraitLibrary.config_from_data_or_default(current_player_portraits[player_id], player_id)

	var string_key: String = str(player_id)
	if current_player_portraits.has(string_key):
		return PortraitLibrary.config_from_data_or_default(current_player_portraits[string_key], player_id)

	return PortraitLibrary.get_default_portrait_for_player_id(player_id)

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
	var had_pending_attach: bool = pending_card_attach_positions.has(piece_position)
	if pending_card_attach_positions.has(piece_position):
		pending_card_attach_positions.erase(piece_position)
		active_card_attach_process_count = maxi(0, active_card_attach_process_count - 1)
	if had_pending_attach:
		refresh_piece_freeze_overlay(piece_position)
	update_card_drag_permissions()
	update_action_status_ui()

func has_pending_visual_processes() -> bool:
	return active_card_attach_process_count > 0 or active_piece_revert_animation_count > 0 or card_burn_animation_sequence_running or !pending_card_burn_animations.is_empty() or !pending_piece_revert_animations.is_empty()

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
	var action_state: String = ACTION_STATUS_STATE_BLOCKED
	if can_control_current_turn():
		action_state = ACTION_STATUS_STATE_ACTIVE if is_available else ACTION_STATUS_STATE_EMPTY
	set_action_status_cell_state(action_name, action_state)

func set_action_status_cell_state(action_name: String, action_state: String) -> void:
	var action_cell: PanelContainer = action_status_cells.get(action_name, null) as PanelContainer
	if action_cell == null:
		return

	var previous_state: String = str(action_status_states.get(action_name, ""))
	if previous_state == action_state:
		return
	action_status_states[action_name] = action_state

	var previous_tween: Tween = action_status_tweens.get(action_name, null) as Tween
	if previous_tween != null:
		previous_tween.kill()

	if previous_state == "":
		apply_action_status_cell_state(action_name, action_state)
		return

	action_cell.pivot_offset = ACTION_STATUS_CELL_SIZE * 0.5
	var tween: Tween = create_tween()
	action_status_tweens[action_name] = tween
	tween.finished.connect(func():
		if action_status_tweens.get(action_name, null) == tween:
			action_status_tweens.erase(action_name)
	)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(action_cell, "scale:y", 0.0, ACTION_STATUS_FLIP_DURATION * 0.5)
	tween.tween_callback(Callable(self, "apply_action_status_cell_state").bind(action_name, action_state))
	tween.tween_property(action_cell, "scale:y", 1.0, ACTION_STATUS_FLIP_DURATION * 0.5)

func apply_action_status_cell_state(action_name: String, action_state: String) -> void:
	var action_cell: PanelContainer = action_status_cells.get(action_name, null) as PanelContainer
	var action_label: Label = action_status_labels.get(action_name, null) as Label
	if action_cell == null or action_label == null:
		return

	var cell_color: Color = ACTION_STATUS_ACTIVE_COLOR
	var border_color: Color = ACTION_STATUS_ACTIVE_BORDER_COLOR
	var label_color: Color = ACTION_STATUS_ACTIVE_TEXT_COLOR
	var label_text: String = get_action_status_letter(action_name)
	if action_state == ACTION_STATUS_STATE_EMPTY:
		cell_color = ACTION_STATUS_INACTIVE_COLOR
		label_text = ""
	elif action_state == ACTION_STATUS_STATE_BLOCKED:
		cell_color = ACTION_STATUS_BLOCKED_COLOR
		border_color = Color(0.0, 0.0, 0.0, 1.0)
		label_text = ""

	var style_box := StyleBoxFlat.new()
	style_box.bg_color = cell_color
	style_box.border_color = border_color
	style_box.set_border_width_all(2)
	style_box.set_corner_radius_all(3)
	action_cell.add_theme_stylebox_override("panel", style_box)
	action_label.text = label_text

	var label_settings: LabelSettings = action_label.label_settings
	if label_settings != null:
		label_settings.font_color = label_color

func get_action_status_letter(action_name: String) -> String:
	match action_name:
		"Switch":
			return "S"
		"Attach":
			return "A"
		"Move":
			return "M"
	return ""

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

func reset_turn_timer() -> void:
	turn_timer_turn_color = get_current_turn_color()
	turn_timer_elapsed_seconds = 0.0
	turn_timer_remaining_seconds = TURN_TIMER_LIMIT_SECONDS
	turn_timer_timeout_pending = false
	set_deck_counter_value(TURN_TIMER_COUNTER_KEY, TURN_TIMER_LIMIT_SECONDS, false)
	update_turn_timer_visibility()

func update_turn_timer(delta: float) -> void:
	if turn_timer_counter_container == null:
		return
	if game_over:
		turn_timer_counter_container.visible = false
		return

	var current_turn_color: int = get_current_turn_color()
	if turn_timer_turn_color != current_turn_color:
		reset_turn_timer()

	update_turn_timer_visibility()
	if !should_run_turn_timer() or turn_timer_timeout_pending:
		return

	turn_timer_elapsed_seconds += maxf(delta, 0.0)
	var remaining_seconds: int = clampi(ceili(float(TURN_TIMER_LIMIT_SECONDS) - turn_timer_elapsed_seconds), 0, TURN_TIMER_LIMIT_SECONDS)
	if remaining_seconds != turn_timer_remaining_seconds:
		turn_timer_remaining_seconds = remaining_seconds
		set_deck_counter_value(TURN_TIMER_COUNTER_KEY, remaining_seconds, true)

	if turn_timer_elapsed_seconds >= float(TURN_TIMER_LIMIT_SECONDS):
		turn_timer_timeout_pending = true
		call_deferred("_on_turn_timer_timeout", current_turn_color)

func update_turn_timer_visibility() -> void:
	if turn_timer_counter_container == null:
		return
	turn_timer_counter_container.visible = !game_over and should_show_turn_timer()

func should_show_turn_timer() -> bool:
	if GameConfig.is_ai_vs_ai_batch:
		return false
	return can_control_current_turn() and is_current_turn_human_controlled()

func should_run_turn_timer() -> bool:
	if !should_show_turn_timer():
		return false
	if !is_tutorial_action_allowed(TUTORIAL_ACTION_END_TURN):
		return false
	return true

func is_current_turn_human_controlled() -> bool:
	var player_id: int = get_player_id_for_color(get_current_turn_color())
	if GameConfig.is_singleplayer:
		return GameConfig.get_player_controller(player_id) == GameConfig.CONTROLLER_HUMAN
	return true

func _on_turn_timer_timeout(expected_turn_color: int) -> void:
	if !is_inside_tree():
		return
	await request_end_turn(false, expected_turn_color)
	if !is_inside_tree() or get_current_turn_color() != expected_turn_color:
		return
	if GameController.current_game_host == null:
		turn_timer_timeout_pending = false

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
	await request_end_turn(true)

func request_end_turn(emit_tutorial_rejection: bool, expected_turn_color: int = 0) -> void:
	if !can_control_current_turn():
		return
	if expected_turn_color != 0 and get_current_turn_color() != expected_turn_color:
		return
	if !is_tutorial_action_allowed(TUTORIAL_ACTION_END_TURN, {
		"owner_color": get_controllable_color(),
		"player_id": get_own_player_id(),
	}, emit_tutorial_rejection):
		return

	await wait_for_pending_visual_processes()
	if !can_control_current_turn():
		return
	if expected_turn_color != 0 and get_current_turn_color() != expected_turn_color:
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
	update_card_attach_target_feedback(INVALID_BOARD_POS)

func _on_card_drag_moved(card_visual: CardVisual):
	var target_pos: Vector2 = get_card_drop_piece_position(card_visual)
	var can_drop_on_deck: bool = can_drop_card_on_deck(card_visual)
	card_visual.set_drop_target_active(target_pos != INVALID_BOARD_POS or can_drop_on_deck)
	update_card_attach_target_feedback(target_pos)
	handle_card_reorder(card_visual)

func _on_card_drag_released(card_visual: CardVisual):
	var target_pos: Vector2 = get_card_drop_piece_position(card_visual)
	update_card_attach_target_feedback(INVALID_BOARD_POS)
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
	if board_markers_node == null:
		return null

	var marker_group := Node2D.new()
	marker_group.name = "CardAttachTargetMarker"
	marker_group.z_index = 0
	var marker := Polygon2D.new()
	marker.name = "Fill"
	marker.color = CARD_ATTACH_TARGET_FILL_COLOR
	marker.polygon = get_board_cell_polygon_local(target_pos, CARD_ATTACH_TARGET_FILL_INSET)
	enable_canvas_item_antialiasing(marker)
	marker_group.add_child(marker)
	board_markers_node.add_child(marker_group)
	return marker_group

func start_card_attach_target_piece_wiggle(target_pos: Vector2) -> void:
	var holder: Sprite2D = get_piece_holder_at(target_pos)
	if holder == null or !is_instance_valid(holder):
		return

	card_attach_target_piece = holder
	card_attach_target_piece_base_position = holder.position
	card_attach_target_piece_base_rotation = holder.rotation
	var lift: Vector2 = Vector2(0.0, -CARD_ATTACH_TARGET_WIGGLE_RISE)
	var tilt: float = deg_to_rad(CARD_ATTACH_TARGET_WIGGLE_ROTATION_DEGREES)
	card_attach_target_piece_tween = create_tween().set_loops().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	card_attach_target_piece_tween.tween_property(holder, "position", card_attach_target_piece_base_position + lift, CARD_ATTACH_TARGET_WIGGLE_STEP_DURATION)
	card_attach_target_piece_tween.parallel().tween_property(holder, "rotation", card_attach_target_piece_base_rotation + tilt, CARD_ATTACH_TARGET_WIGGLE_STEP_DURATION)
	card_attach_target_piece_tween.tween_property(holder, "position", card_attach_target_piece_base_position, CARD_ATTACH_TARGET_WIGGLE_STEP_DURATION)
	card_attach_target_piece_tween.parallel().tween_property(holder, "rotation", card_attach_target_piece_base_rotation - tilt, CARD_ATTACH_TARGET_WIGGLE_STEP_DURATION)
	card_attach_target_piece_tween.tween_property(holder, "position", card_attach_target_piece_base_position + lift * 0.55, CARD_ATTACH_TARGET_WIGGLE_STEP_DURATION)
	card_attach_target_piece_tween.parallel().tween_property(holder, "rotation", card_attach_target_piece_base_rotation, CARD_ATTACH_TARGET_WIGGLE_STEP_DURATION)
	card_attach_target_piece_tween.tween_property(holder, "position", card_attach_target_piece_base_position, CARD_ATTACH_TARGET_WIGGLE_STEP_DURATION)

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

func get_state_card_expiration_events(previous_snapshot: Dictionary, recent_card_expirations: Array) -> Array[Dictionary]:
	var expiration_events: Array[Dictionary] = []
	var known_expirations: Dictionary = {}
	for expiration_value in recent_card_expirations:
		if !(expiration_value is Dictionary):
			continue

		var expiration: Dictionary = (expiration_value as Dictionary).duplicate(true)
		var board_pos: Vector2 = value_to_vector2(expiration.get("piece_pos", INVALID_BOARD_POS), INVALID_BOARD_POS)
		var card_name: String = str(expiration.get("card_name", ""))
		if !is_valid_position(board_pos) or card_name.is_empty():
			continue

		expiration["piece_pos"] = board_pos
		expiration_events.append(expiration)
		known_expirations[get_card_expiration_signature(board_pos, card_name, int(expiration.get("player_id", -1)))] = true

	for position_value in previous_snapshot:
		var board_pos: Vector2 = value_to_vector2(position_value, INVALID_BOARD_POS)
		if !is_valid_position(board_pos) or !piece_objects.has(board_pos):
			continue

		var previous_state: Dictionary = previous_snapshot[position_value]
		var expired_card_name: String = str(previous_state.get("card_name", ""))
		if expired_card_name.is_empty():
			continue

		var piece: Piece = piece_objects[board_pos] as Piece
		if piece == null or piece.attached_card != null:
			continue
		if int(previous_state.get("color", 0)) != piece.color:
			continue

		var player_id: int = get_player_id_for_color(piece.color)
		var signature: String = get_card_expiration_signature(board_pos, expired_card_name, player_id)
		if known_expirations.has(signature):
			continue

		expiration_events.append({
			"player_id": player_id,
			"card_name": expired_card_name,
			"piece_pos": board_pos,
		})
		known_expirations[signature] = true

	return expiration_events

func get_card_expiration_signature(piece_pos: Vector2, card_name: String, player_id: int) -> String:
	return "%d,%d:%d:%s" % [int(piece_pos.x), int(piece_pos.y), player_id, card_name]

func get_previous_state_texture(previous_state: Dictionary, piece_color: int) -> Texture2D:
	var texture_value: Texture2D = previous_state.get("texture", null) as Texture2D
	if texture_value != null:
		return texture_value
	return get_default_piece_texture(piece_color)

func collect_piece_revert_animations(previous_snapshot: Dictionary, card_expiration_events: Array) -> Array[Dictionary]:
	var animations: Array[Dictionary] = []
	if !has_received_server_state or should_skip_visual_animations():
		return animations

	var used_previous_positions: Dictionary = {}
	for expiration_value in card_expiration_events:
		if !(expiration_value is Dictionary):
			continue

		var expiration: Dictionary = expiration_value
		var board_pos: Vector2 = value_to_vector2(expiration.get("piece_pos", INVALID_BOARD_POS), INVALID_BOARD_POS)
		if !is_valid_position(board_pos) or !piece_objects.has(board_pos):
			continue

		var expired_card_name: String = str(expiration.get("card_name", ""))
		if expired_card_name.is_empty():
			continue

		var piece: Piece = piece_objects[board_pos] as Piece
		if piece == null or piece.attached_card != null:
			continue

		var expiration_player_id: int = int(expiration.get("player_id", -1))
		if expiration_player_id >= 0 and get_player_id_for_color(piece.color) != expiration_player_id:
			continue

		var previous_state: Dictionary = find_previous_expiring_piece_state(
			previous_snapshot,
			used_previous_positions,
			piece.color,
			expired_card_name,
			board_pos
		)
		if previous_state.is_empty():
			continue

		animations.append({
			"position": board_pos,
			"start_texture": get_previous_state_texture(previous_state, piece.color),
		})

	return animations

func find_previous_expiring_piece_state(previous_snapshot: Dictionary, used_previous_positions: Dictionary, piece_color: int, expired_card_name: String, preferred_pos: Vector2) -> Dictionary:
	if previous_snapshot.has(preferred_pos) and !used_previous_positions.has(preferred_pos):
		var preferred_state: Dictionary = previous_snapshot[preferred_pos]
		if int(preferred_state.get("color", 0)) == piece_color and str(preferred_state.get("card_name", "")) == expired_card_name:
			used_previous_positions[preferred_pos] = true
			return preferred_state

	for position_value in previous_snapshot:
		var previous_pos: Vector2 = value_to_vector2(position_value, INVALID_BOARD_POS)
		if used_previous_positions.has(previous_pos):
			continue

		var previous_state: Dictionary = previous_snapshot[position_value]
		if int(previous_state.get("color", 0)) != piece_color:
			continue
		if str(previous_state.get("card_name", "")) != expired_card_name:
			continue

		used_previous_positions[previous_pos] = true
		return previous_state

	return {}

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

func queue_piece_revert_animation(piece_position: Vector2, start_texture: Texture2D) -> void:
	if start_texture == null or !is_valid_position(piece_position):
		return

	pending_piece_revert_animations.append({
		"position": piece_position,
		"start_texture": start_texture,
	})

func play_pending_piece_revert_animations() -> void:
	if pending_piece_revert_animations.is_empty():
		return

	var animations: Array[Dictionary] = pending_piece_revert_animations.duplicate()
	pending_piece_revert_animations.clear()
	play_piece_revert_animations(animations)

func play_piece_revert_animations(animations: Array[Dictionary]) -> void:
	for animation: Dictionary in animations:
		var board_pos: Vector2 = value_to_vector2(animation.get("position", INVALID_BOARD_POS), INVALID_BOARD_POS)
		var start_texture: Texture2D = animation.get("start_texture", null) as Texture2D
		play_piece_revert_animation(board_pos, start_texture)

func play_piece_revert_animation(piece_position: Vector2, start_texture: Texture2D) -> void:
	if should_skip_visual_animations() or start_texture == null or !is_valid_position(piece_position):
		return

	var overlay: Sprite2D = create_piece_effect_holder(piece_position, start_texture, "PieceExpireDissolve")
	if overlay == null:
		return

	active_piece_revert_animation_count += 1

	var material := ShaderMaterial.new()
	material.shader = PIECE_EXPIRE_DISSOLVE_SHADER
	material.set_shader_parameter("progress", 0.0)
	material.set_shader_parameter("beam_size", PIECE_EXPIRE_DISSOLVE_BEAM_SIZE)
	material.set_shader_parameter("noise_density", PIECE_EXPIRE_DISSOLVE_NOISE_DENSITY)
	material.set_shader_parameter("color", PIECE_EXPIRE_DISSOLVE_COLOR)
	overlay.material = material

	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(material, "shader_parameter/progress", 1.0, PIECE_EXPIRE_DISSOLVE_DURATION)
	await tween.finished
	if is_instance_valid(overlay):
		overlay.queue_free()
	active_piece_revert_animation_count = maxi(0, active_piece_revert_animation_count - 1)

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

func _process(delta):
	update_hovered_piece()
	update_deck_count_hover()
	update_deck_counter_ui()
	update_action_status_ui()
	arrange_action_status_ui()
	update_turn_timer(delta)
	arrange_turn_timer_ui()
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
	var linear_depth_factor: float
	var near_y: float
	var far_direction: float
	if board_view_color < 0:
		near_y = -half_size
		far_direction = 1.0
		linear_depth_factor = clampf((point.y + half_size) / (half_size * 2.0), 0.0, 1.0)
	else:
		near_y = half_size
		far_direction = -1.0
		linear_depth_factor = clampf((half_size - point.y) / (half_size * 2.0), 0.0, 1.0)

	var projected_depth_factor: float = get_board_projected_depth_factor(linear_depth_factor)
	var horizontal_scale: float = lerpf(BOARD_PERSPECTIVE_BOTTOM_SCALE, BOARD_PERSPECTIVE_TOP_SCALE, projected_depth_factor)
	var projected_x: float = point.x * horizontal_scale
	var far_y: float = near_y + (far_direction * half_size * 2.0 * BOARD_PERSPECTIVE_VERTICAL_SCALE)
	var projected_y: float = lerpf(near_y, far_y, projected_depth_factor)
	return Vector2(projected_x, projected_y)

func get_board_projected_depth_factor(linear_depth_factor: float) -> float:
	var depth_factor: float = clampf(linear_depth_factor, 0.0, 1.0)
	var top_scale: float = max(BOARD_PERSPECTIVE_TOP_SCALE, 0.001)
	var bottom_scale: float = max(BOARD_PERSPECTIVE_BOTTOM_SCALE, 0.001)
	var perspective_strength: float = max((bottom_scale / top_scale) - 1.0, 0.0)
	if perspective_strength <= 0.0001:
		return depth_factor

	return clampf(
		(depth_factor * (1.0 + perspective_strength)) / (1.0 + perspective_strength * depth_factor),
		0.0,
		1.0
	)

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
		hover_card_preview.rotation_degrees = HOVER_CARD_ROTATION_DEGREES
		hover_card_preview.set_rest_scale(Vector2.ONE * HOVER_CARD_PREVIEW_SCALE)
		hover_card_preview.visible = true
		show_hover_piece_preview(preview_card, piece.color)
		hover_description_label.text = preview_card.description.strip_edges()
		hover_description_panel.visible = !hover_description_label.text.is_empty()

	hover_duration_label.text = "INF" if piece.turns_remaining < 0 else str(piece.turns_remaining)
	hover_duration_label.visible = true
	update_hover_duration_label_position()

func hide_hover_piece_details():
	if hover_card_preview:
		hover_card_preview.visible = false
	if hover_piece_preview:
		hover_piece_preview.visible = false
		hover_piece_preview.texture = null
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

func show_hover_piece_preview(card: Card, piece_color: int) -> void:
	if hover_piece_preview == null:
		return

	var preview_texture: Texture2D = get_card_piece_preview_texture(card, piece_color)
	if preview_texture == null:
		hover_piece_preview.visible = false
		hover_piece_preview.texture = null
		return

	hover_piece_preview.texture = preview_texture
	hover_piece_preview.visible = true

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

func should_fit_piece_texture_to_default_height(texture_value: Texture2D) -> bool:
	if texture_value == null:
		return false
	if is_default_piece_texture(texture_value):
		return true

	var texture_size: Vector2 = texture_value.get_size()
	return texture_size.y >= PIECE_AUTO_FIT_HEIGHT_THRESHOLD

func get_piece_visual_transform_for_texture(texture_value: Texture2D, board_pos: Vector2) -> Dictionary:
	var visual_transform := {
		"scale": Vector2.ONE,
		"offset": Vector2.ZERO,
	}
	if texture_value == null:
		return visual_transform

	var perspective_scale: float = get_piece_perspective_scale(board_pos)
	if should_fit_piece_texture_to_default_height(texture_value):
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
	apply_piece_texture_filter(holder)
	holder.scale = Vector2.ONE
	holder.offset = Vector2.ZERO
	if holder.texture == null:
		return

	var visual_transform: Dictionary = get_piece_visual_transform_for_texture(holder.texture, board_pos)
	holder.scale = visual_transform.get("scale", Vector2.ONE)
	holder.offset = visual_transform.get("offset", Vector2.ZERO)

func apply_piece_texture_filter(holder: Sprite2D) -> void:
	if holder == null or !is_instance_valid(holder):
		return

	holder.texture_filter = PIECE_TEXTURE_FILTER

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

	var footprint: Dictionary = get_piece_footprint_geometry(holder)
	var footprint_center: Vector2 = footprint.get("center", Vector2.ZERO)
	if bool(footprint.get("empty", true)):
		return

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
	if holder == null or !is_instance_valid(holder):
		return

	var existing_shadow: Node = holder.get_node_or_null(PIECE_SHADOW_NAME)
	if existing_shadow != null:
		existing_shadow.free()

func apply_piece_light_occluder(holder: Sprite2D, board_pos: Vector2) -> void:
	remove_piece_light_occluder(holder)
	if holder == null or !is_instance_valid(holder) or holder.texture == null or !piece_objects.has(board_pos):
		return

	var footprint: Dictionary = get_piece_footprint_geometry(holder)
	var center: Vector2 = footprint.get("center", Vector2.ZERO)
	var radius_x: float = float(footprint.get("radius_x", 0.0))
	var radius_y: float = float(footprint.get("radius_y", 0.0))
	if bool(footprint.get("empty", true)) or radius_x <= 0.0 or radius_y <= 0.0:
		return

	var occluder := LightOccluder2D.new()
	occluder.name = PIECE_LIGHT_OCCLUDER_NAME
	occluder.occluder_light_mask = PIECE_LIGHT_OCCLUDER_MASK

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
	if holder == null or !is_instance_valid(holder):
		return

	var existing_occluder: Node = holder.get_node_or_null(PIECE_LIGHT_OCCLUDER_NAME)
	if existing_occluder != null:
		existing_occluder.free()

func get_piece_footprint_geometry(holder: Sprite2D) -> Dictionary:
	if holder == null or !is_instance_valid(holder) or holder.texture == null:
		return {"empty": true}

	var texture_size: Vector2 = holder.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return {"empty": true}

	var metrics: Dictionary = get_piece_footprint_metrics(holder.texture)
	if metrics.is_empty():
		return get_fallback_piece_footprint_geometry(holder, texture_size)

	var lower_width: float = maxf(1.0, float(metrics.get("lower_width", metrics.get("widest_width", texture_size.x))))
	var lower_center_x: float = float(metrics.get("lower_center_x", metrics.get("widest_center_x", texture_size.x * 0.5)))
	var bottom_y: float = float(metrics.get("bottom_y", texture_size.y - 1.0))
	var bounds_width: float = maxf(1.0, float(metrics.get("right_x", texture_size.x - 1.0)) - float(metrics.get("left_x", 0.0)) + 1.0)
	var radius_x: float = maxf(
		lower_width * PIECE_LIGHT_OCCLUDER_FOOTPRINT_WIDTH_FACTOR * 0.5,
		bounds_width * PIECE_LIGHT_OCCLUDER_FOOTPRINT_MIN_RADIUS_BOUNDS_FACTOR
	)
	var radius_y: float = get_piece_footprint_fixed_radius_y(holder)
	var center := Vector2(
		holder.offset.x + lower_center_x - texture_size.x * 0.5 + PIECE_LIGHT_OCCLUDER_FOOTPRINT_OFFSET.x,
		holder.offset.y + bottom_y - texture_size.y * 0.5 - radius_y + PIECE_LIGHT_OCCLUDER_FOOTPRINT_OFFSET.y
	)

	return {
		"empty": false,
		"center": center,
		"radius_x": radius_x,
		"radius_y": radius_y,
	}

func get_piece_footprint_fixed_radius_y(holder: Sprite2D) -> float:
	var scale_y: float = absf(holder.scale.y) if holder != null else 1.0
	if scale_y <= 0.0001:
		return PIECE_LIGHT_OCCLUDER_FOOTPRINT_FIXED_RADIUS_Y
	return PIECE_LIGHT_OCCLUDER_FOOTPRINT_FIXED_RADIUS_Y / scale_y

func get_fallback_piece_footprint_geometry(holder: Sprite2D, texture_size: Vector2) -> Dictionary:
	var radius_x: float = texture_size.x * PIECE_LIGHT_OCCLUDER_FOOTPRINT_WIDTH_FACTOR * 0.5
	var radius_y: float = get_piece_footprint_fixed_radius_y(holder)
	if radius_x <= 0.0 or radius_y <= 0.0:
		return {"empty": true}

	var visual_bottom_y: float = holder.offset.y + texture_size.y * (0.5 - PIECE_LIGHT_OCCLUDER_FOOTPRINT_BOTTOM_INSET_FACTOR)
	return {
		"empty": false,
		"center": Vector2(
			holder.offset.x + PIECE_LIGHT_OCCLUDER_FOOTPRINT_OFFSET.x,
			visual_bottom_y - radius_y + PIECE_LIGHT_OCCLUDER_FOOTPRINT_OFFSET.y
		),
		"radius_x": radius_x,
		"radius_y": radius_y,
	}

func get_piece_footprint_metrics(texture_value: Texture2D) -> Dictionary:
	if texture_value == null:
		return {}

	var cache_key: String = get_piece_footprint_metrics_cache_key(texture_value)
	if piece_footprint_metrics_cache.has(cache_key):
		return piece_footprint_metrics_cache[cache_key]

	var metrics: Dictionary = measure_piece_footprint_metrics(texture_value)
	piece_footprint_metrics_cache[cache_key] = metrics
	return metrics

func get_piece_footprint_metrics_cache_key(texture_value: Texture2D) -> String:
	if texture_value.resource_path != "":
		return "%s:%s" % [texture_value.resource_path, texture_value.get_size()]
	return "%s:%s" % [str(texture_value.get_rid()), texture_value.get_size()]

func measure_piece_footprint_metrics(texture_value: Texture2D) -> Dictionary:
	var image: Image = texture_value.get_image()
	if image == null or image.is_empty():
		return {}
	if image.is_compressed() and image.decompress() != OK:
		return {}

	var image_width: int = image.get_width()
	var image_height: int = image.get_height()
	if image_width <= 0 or image_height <= 0:
		return {}

	var min_x: int = image_width
	var max_x: int = -1
	var min_y: int = image_height
	var max_y: int = -1
	var widest_min_x: int = 0
	var widest_max_x: int = -1
	var widest_y: int = 0
	var widest_width: int = 0
	var fallback_widest_min_x: int = 0
	var fallback_widest_max_x: int = -1
	var fallback_widest_y: int = 0
	var fallback_widest_width: int = 0
	var lower_scan_start_y: int = clampi(int(floor(float(image_height) * PIECE_FOOTPRINT_WIDTH_SCAN_START_RATIO)), 0, image_height - 1)
	var visible_rows: Array[Dictionary] = []

	for y in range(image_height - 1, -1, -1):
		var row_min_x: int = image_width
		var row_max_x: int = -1
		for x in range(image_width):
			if image.get_pixel(x, y).a <= PIECE_FOOTPRINT_ALPHA_THRESHOLD:
				continue

			row_min_x = mini(row_min_x, x)
			row_max_x = maxi(row_max_x, x)
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
			min_y = mini(min_y, y)
			max_y = maxi(max_y, y)

		if row_max_x >= row_min_x:
			var row_width: int = row_max_x - row_min_x + 1
			visible_rows.append({
				"y": y,
				"min_x": row_min_x,
				"max_x": row_max_x,
				"width": row_width,
			})

			if row_width > fallback_widest_width:
				fallback_widest_width = row_width
				fallback_widest_min_x = row_min_x
				fallback_widest_max_x = row_max_x
				fallback_widest_y = y

			if y >= lower_scan_start_y and row_width > widest_width:
				widest_width = row_width
				widest_min_x = row_min_x
				widest_max_x = row_max_x
				widest_y = y

	if widest_width <= 0:
		widest_width = fallback_widest_width
		widest_min_x = fallback_widest_min_x
		widest_max_x = fallback_widest_max_x
		widest_y = fallback_widest_y

	if max_x < min_x or max_y < min_y or widest_width <= 0:
		return {}

	var stable_rows: Array[Dictionary] = []
	var alpha_height: int = max_y - min_y + 1
	var stable_band_start_y: int = maxi(
		lower_scan_start_y,
		clampi(int(floor(float(max_y) - float(alpha_height) * PIECE_FOOTPRINT_STABLE_WIDTH_BAND_RATIO)), min_y, max_y)
	)
	for row: Dictionary in visible_rows:
		if int(row.get("y", 0)) >= stable_band_start_y:
			stable_rows.append(row)
	if stable_rows.is_empty():
		for row: Dictionary in visible_rows:
			stable_rows.append(row)

	stable_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var width_a: int = int(a.get("width", 0))
		var width_b: int = int(b.get("width", 0))
		if width_a == width_b:
			return int(a.get("y", 0)) > int(b.get("y", 0))
		return width_a > width_b
	)

	var sample_count: int = mini(PIECE_FOOTPRINT_STABLE_ROW_SAMPLE_COUNT, stable_rows.size())
	var width_sum: float = 0.0
	var weighted_center_sum: float = 0.0
	var weight_sum: float = 0.0
	for sample_index in range(sample_count):
		var sample_row: Dictionary = stable_rows[sample_index]
		var sample_width: float = float(sample_row.get("width", 1))
		var sample_center_x: float = (float(sample_row.get("min_x", 0)) + float(sample_row.get("max_x", 0))) * 0.5
		width_sum += sample_width
		weighted_center_sum += sample_center_x * sample_width
		weight_sum += sample_width

	var lower_width: float = width_sum / float(sample_count) if sample_count > 0 else float(widest_width)
	var lower_center_x: float = weighted_center_sum / weight_sum if weight_sum > 0.0 else (float(widest_min_x) + float(widest_max_x)) * 0.5

	return {
		"left_x": float(min_x),
		"right_x": float(max_x),
		"top_y": float(min_y),
		"bottom_y": float(max_y),
		"widest_width": float(widest_width),
		"widest_center_x": (float(widest_min_x) + float(widest_max_x)) * 0.5,
		"widest_y": float(widest_y),
		"lower_width": lower_width,
		"lower_center_x": lower_center_x,
	}

func set_piece_light_occluder_enabled(holder: Sprite2D, is_enabled: bool) -> void:
	if holder == null or !is_instance_valid(holder):
		return

	var occluder: LightOccluder2D = holder.get_node_or_null(PIECE_LIGHT_OCCLUDER_NAME) as LightOccluder2D
	if occluder != null:
		occluder.occluder_light_mask = PIECE_LIGHT_OCCLUDER_MASK if is_enabled else 0

func get_attached_card_piece_texture(piece: Piece) -> Texture2D:
	if piece == null or piece.attached_card == null:
		return null
	return piece.attached_card.get_piece_texture(piece.color, get_piece_board_view(piece.color))

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
	return card.get_piece_texture(piece_color, get_piece_board_view(piece_color))

func get_card_piece_preview_texture(card: Card, piece_color: int) -> Texture2D:
	if card == null:
		return null
	return card.get_piece_preview_texture(piece_color)

func get_piece_board_view(piece_color: int) -> String:
	if piece_color * get_own_color() > 0:
		return PieceVisualSet.VIEW_BACK
	return PieceVisualSet.VIEW_FRONT

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

func collect_state_attach_animations(previous_snapshot: Dictionary, hidden_cards: Array = [], previous_hidden_card_counts: Dictionary = {}) -> Array[Dictionary]:
	var animations: Array[Dictionary] = []
	if !has_received_server_state or should_skip_visual_animations():
		return animations

	var animated_positions: Dictionary = {}
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
		animated_positions[board_pos] = true

	append_hidden_invisibility_attach_animations(animations, animated_positions, previous_snapshot, hidden_cards, previous_hidden_card_counts)

	return animations

func append_hidden_invisibility_attach_animations(animations: Array[Dictionary], animated_positions: Dictionary, previous_snapshot: Dictionary, hidden_cards: Array, previous_hidden_card_counts: Dictionary) -> void:
	var used_positions: Dictionary = animated_positions.duplicate()
	var new_hidden_card_counts: Dictionary = get_new_hidden_card_counts(hidden_cards, previous_hidden_card_counts)
	for hidden_card_value in hidden_cards:
		if !(hidden_card_value is Dictionary):
			continue

		var hidden_card_data: Dictionary = hidden_card_value
		var owner_player_id: int = int(hidden_card_data.get("owner_player_id", -1))
		if owner_player_id < 0 or owner_player_id == get_own_player_id():
			continue

		var card_name: String = str(hidden_card_data.get("card_name", ""))
		var hidden_signature: String = get_hidden_card_signature(owner_player_id, card_name)
		var new_count: int = int(new_hidden_card_counts.get(hidden_signature, 0))
		if new_count <= 0:
			continue

		var card: Card = CardLibrary.duplicate_card(card_name)
		if card == null or card.effect_type != CardEffect.TYPE_INVISIBLE_TO_ENEMY:
			continue

		var piece_color: int = get_color_for_player_id(owner_player_id)
		var hidden_pos: Vector2 = find_recently_hidden_piece_position(previous_snapshot, used_positions, piece_color)
		if hidden_pos == INVALID_BOARD_POS:
			continue

		var previous_state: Dictionary = previous_snapshot[hidden_pos]
		animations.append({
			"position": hidden_pos,
			"card": card,
			"start_texture": get_previous_state_texture(previous_state, piece_color),
			"piece_color": piece_color,
			"hide_after_attach": true,
		})
		used_positions[hidden_pos] = true
		new_hidden_card_counts[hidden_signature] = new_count - 1

func find_recently_hidden_piece_position(previous_snapshot: Dictionary, used_positions: Dictionary, piece_color: int) -> Vector2:
	for position_value in previous_snapshot:
		var board_pos: Vector2 = value_to_vector2(position_value, INVALID_BOARD_POS)
		if !is_valid_position(board_pos) or used_positions.has(board_pos) or piece_objects.has(board_pos):
			continue

		var previous_state: Dictionary = previous_snapshot[position_value]
		if int(previous_state.get("color", 0)) != piece_color:
			continue
		var previous_card_name: String = str(previous_state.get("card_name", ""))
		if !previous_card_name.is_empty():
			continue
		return board_pos

	return INVALID_BOARD_POS

func get_hidden_card_counts_from_state(hidden_cards: Array) -> Dictionary:
	var counts: Dictionary = {}
	for hidden_card_value in hidden_cards:
		if !(hidden_card_value is Dictionary):
			continue

		var hidden_card_data: Dictionary = hidden_card_value
		var owner_player_id: int = int(hidden_card_data.get("owner_player_id", -1))
		var card_name: String = str(hidden_card_data.get("card_name", ""))
		if owner_player_id < 0 or card_name.is_empty():
			continue

		var signature: String = get_hidden_card_signature(owner_player_id, card_name)
		counts[signature] = int(counts.get(signature, 0)) + 1

	return counts

func get_new_hidden_card_counts(hidden_cards: Array, previous_hidden_card_counts: Dictionary) -> Dictionary:
	var current_counts: Dictionary = get_hidden_card_counts_from_state(hidden_cards)
	var new_counts: Dictionary = {}
	for signature in current_counts:
		var current_count: int = int(current_counts.get(signature, 0))
		var previous_count: int = int(previous_hidden_card_counts.get(signature, 0))
		var added_count: int = current_count - previous_count
		if added_count > 0:
			new_counts[signature] = added_count
	return new_counts

func get_hidden_card_signature(owner_player_id: int, card_name: String) -> String:
	return "%d:%s" % [owner_player_id, card_name]

func play_state_attach_animations(animations: Array[Dictionary]) -> void:
	for animation: Dictionary in animations:
		var board_pos: Vector2 = value_to_vector2(animation.get("position", INVALID_BOARD_POS), INVALID_BOARD_POS)
		var card: Card = animation.get("card", null) as Card
		var start_texture: Texture2D = animation.get("start_texture", null) as Texture2D
		var hide_after_attach: bool = bool(animation.get("hide_after_attach", false))
		if !is_valid_position(board_pos) or card == null:
			finish_card_attach_process(board_pos)
			continue

		if hide_after_attach:
			var piece_color: int = int(animation.get("piece_color", 0))
			if piece_color == 0:
				piece_color = get_color_for_player_id(1 - get_own_player_id())
			await play_hidden_piece_invisibility_attach_animation(board_pos, card, start_texture, piece_color)
		else:
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
	apply_piece_freeze_overlay(holder, board_pos)
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

func play_hidden_piece_invisibility_attach_animation(piece_position: Vector2, card: Card, start_texture: Texture2D, piece_color: int) -> void:
	if should_skip_visual_animations() or !is_inside_tree():
		return
	if card == null or !is_valid_position(piece_position):
		return
	if start_texture == null:
		start_texture = get_default_piece_texture(piece_color)
	if start_texture == null:
		return

	var holder: Sprite2D = create_hidden_invisibility_animation_holder(piece_position, start_texture)
	if holder == null:
		return

	var attached_texture: Texture2D = get_card_piece_texture_for_color(card, piece_color)
	if attached_texture == null:
		attached_texture = start_texture

	var attach_point_light: PointLight2D = create_piece_attach_point_light(holder)
	var attach_piece_light: PointLight2D = create_piece_attach_sprite_light(holder)
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
	apply_piece_visual_size(holder, piece_position)
	var morph_overlay: Node = holder.get_node_or_null(PIECE_ATTACH_MORPH_NAME)
	if morph_overlay != null:
		morph_overlay.queue_free()
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

	if !is_inside_tree() or !is_instance_valid(holder):
		return

	await get_tree().create_timer(PIECE_INVISIBILITY_VISIBLE_HOLD_DURATION).timeout
	if !is_inside_tree() or !is_instance_valid(holder):
		return

	var refract_material := ShaderMaterial.new()
	refract_material.shader = PIECE_INVISIBILITY_REFRACT_SHADER
	refract_material.set_shader_parameter("dist", PIECE_INVISIBILITY_REFRACT_DISTANCE)
	refract_material.set_shader_parameter("alpha", 0.0)
	holder.material = refract_material

	var refract_tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	refract_tween.tween_property(refract_material, "shader_parameter/alpha", 1.0, PIECE_INVISIBILITY_REFRACT_IN_DURATION)
	await refract_tween.finished
	if !is_inside_tree() or !is_instance_valid(holder):
		return

	var fade_tween: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	fade_tween.tween_property(holder, "self_modulate:a", 0.0, PIECE_INVISIBILITY_FADE_OUT_DURATION)
	await fade_tween.finished
	if is_instance_valid(holder):
		holder.queue_free()

func create_piece_effect_holder(piece_position: Vector2, texture_value: Texture2D, holder_name: String = "PieceEffect") -> Sprite2D:
	if texture_value == null or !is_valid_position(piece_position):
		return null
	if piece_effects_node == null or !is_instance_valid(piece_effects_node):
		create_piece_effects_node()
	if piece_effects_node == null:
		return null

	var holder: Sprite2D = TEXTURE_HOLDER.instantiate() as Sprite2D
	if holder == null:
		return null
	if side != null && !side:
		holder.global_rotation_degrees = 180
	piece_effects_node.add_child(holder)
	holder.name = holder_name
	holder.light_mask = PIECE_EFFECT_LIGHT_RECEIVE_MASK
	holder.texture_filter = PIECE_TEXTURE_FILTER
	holder.position = get_board_position_local_position(piece_position)
	holder.set_meta("board_pos", piece_position)
	holder.z_index = get_piece_depth_z_index(piece_position)
	holder.texture = texture_value
	holder.self_modulate = Color.WHITE
	apply_piece_visual_size(holder, piece_position)
	return holder

func create_hidden_invisibility_animation_holder(piece_position: Vector2, start_texture: Texture2D) -> Sprite2D:
	return create_piece_effect_holder(piece_position, start_texture, "HiddenInvisibilityPiece")

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
	overlay.texture_filter = PIECE_TEXTURE_FILTER

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
	overlay.texture_filter = PIECE_TEXTURE_FILTER
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
	clear_card_attach_target_feedback()
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
			apply_piece_freeze_overlay(holder, Vector2(i, j))
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

func apply_piece_freeze_overlay(holder: Sprite2D, board_pos: Vector2) -> void:
	remove_piece_freeze_overlay(holder)
	remove_piece_freeze_square_overlay(board_pos)
	if pending_card_attach_positions.has(board_pos):
		return
	if holder == null or !is_instance_valid(holder) or holder.texture == null:
		piece_freeze_visual_signatures.erase(board_pos)
		return

	var freeze_signature: String = get_piece_freeze_visual_signature(board_pos)
	if freeze_signature.is_empty():
		if piece_freeze_visual_signatures.has(board_pos):
			play_piece_freeze_release_animation(holder, board_pos)
		piece_freeze_visual_signatures.erase(board_pos)
		return

	var previous_signature: String = str(piece_freeze_visual_signatures.get(board_pos, ""))
	var should_animate: bool = previous_signature != freeze_signature and !should_skip_visual_animations()
	piece_freeze_visual_signatures[board_pos] = freeze_signature

	var freeze_material: ShaderMaterial = create_piece_freeze_crack_material(PIECE_FREEZE_CRACK_START_WIDTH if should_animate else PIECE_FREEZE_CRACK_END_WIDTH)
	create_piece_freeze_overlay(holder, PIECE_FREEZE_CRACK_NAME, freeze_material)
	create_piece_freeze_square_overlay(board_pos, freeze_material, PIECE_FREEZE_SQUARE_NAME)
	if should_animate:
		var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(freeze_material, "shader_parameter/crack_width", PIECE_FREEZE_CRACK_END_WIDTH, PIECE_FREEZE_CRACK_DURATION)

func refresh_piece_freeze_overlay(board_pos: Vector2) -> void:
	var holder: Sprite2D = get_piece_holder_at(board_pos)
	if holder == null or !is_instance_valid(holder):
		return

	apply_piece_freeze_overlay(holder, board_pos)

func create_piece_freeze_overlay(holder: Sprite2D, overlay_name: String, freeze_material: ShaderMaterial) -> Sprite2D:
	var overlay := Sprite2D.new()
	overlay.name = overlay_name
	overlay.z_index = PIECE_FREEZE_CRACK_Z_INDEX
	overlay.z_as_relative = true
	sync_piece_attach_overlay_to_holder(overlay, holder)
	overlay.material = freeze_material
	holder.add_child(overlay)
	return overlay

func create_piece_freeze_square_overlay(board_pos: Vector2, freeze_material: ShaderMaterial, overlay_name: String) -> Polygon2D:
	if board_markers_node == null or !is_instance_valid(board_markers_node):
		return null
	if freeze_material == null or !is_valid_position(board_pos):
		return null

	var points: PackedVector2Array = get_board_cell_polygon_local(board_pos, PIECE_FREEZE_SQUARE_INSET)
	if points.size() < 3:
		return null

	var overlay := Polygon2D.new()
	overlay.name = get_piece_freeze_square_node_name(board_pos, overlay_name)
	overlay.set_meta("board_pos", board_pos)
	overlay.polygon = points
	overlay.uv = get_board_cell_polygon_uvs(points)
	overlay.texture = get_piece_attach_rays_square_texture()
	overlay.color = Color(1.0, 1.0, 1.0, PIECE_FREEZE_SQUARE_ALPHA)
	overlay.material = freeze_material
	overlay.z_index = PIECE_FREEZE_SQUARE_Z_INDEX
	overlay.light_mask = PIECE_EFFECT_LIGHT_RECEIVE_MASK
	enable_canvas_item_antialiasing(overlay)
	board_markers_node.add_child(overlay)
	return overlay

func get_piece_freeze_square_node_name(board_pos: Vector2, overlay_name: String) -> String:
	return "%s_%d_%d" % [overlay_name, int(board_pos.x), int(board_pos.y)]

func get_board_cell_polygon_uvs(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() == 4:
		return PackedVector2Array([
			Vector2(0.0, 0.0),
			Vector2(1.0, 0.0),
			Vector2(1.0, 1.0),
			Vector2(0.0, 1.0),
		])

	var bounds: Rect2 = get_points_bounds_local(points)
	var uv_points := PackedVector2Array()
	for point: Vector2 in points:
		var uv := Vector2.ZERO
		if bounds.size.x > 0.0001:
			uv.x = (point.x - bounds.position.x) / bounds.size.x
		if bounds.size.y > 0.0001:
			uv.y = (point.y - bounds.position.y) / bounds.size.y
		uv_points.append(uv)
	return uv_points

func create_piece_freeze_crack_material(
	crack_width: float,
	effect_alpha: float = 1.0,
	alpha_from_cracks: bool = false
) -> ShaderMaterial:
	var freeze_material := ShaderMaterial.new()
	freeze_material.shader = PIECE_FREEZE_CRACK_SHADER
	freeze_material.set_shader_parameter("crack_depth", PIECE_FREEZE_CRACK_DEPTH)
	freeze_material.set_shader_parameter("crack_scale", PIECE_FREEZE_CRACK_SCALE)
	freeze_material.set_shader_parameter("crack_zebra_scale", PIECE_FREEZE_CRACK_ZEBRA_SCALE)
	freeze_material.set_shader_parameter("crack_zebra_amp", PIECE_FREEZE_CRACK_ZEBRA_AMP)
	freeze_material.set_shader_parameter("crack_profile", PIECE_FREEZE_CRACK_PROFILE)
	freeze_material.set_shader_parameter("crack_slope", PIECE_FREEZE_CRACK_SLOPE)
	freeze_material.set_shader_parameter("crack_width", crack_width)
	freeze_material.set_shader_parameter("effect_alpha", effect_alpha)
	freeze_material.set_shader_parameter("alpha_from_cracks", alpha_from_cracks)
	freeze_material.set_shader_parameter("refraction_offset", PIECE_FREEZE_REFRACTION_OFFSET)
	freeze_material.set_shader_parameter("reflection_offset", PIECE_FREEZE_REFLECTION_OFFSET)
	return freeze_material

func play_piece_freeze_release_animation(holder: Sprite2D, board_pos: Vector2) -> void:
	if holder == null or !is_instance_valid(holder) or holder.texture == null:
		return
	if should_skip_visual_animations() or !is_inside_tree():
		return

	var existing_release: Node = holder.get_node_or_null(PIECE_FREEZE_RELEASE_NAME)
	if existing_release != null:
		existing_release.free()
	var freeze_material: ShaderMaterial = create_piece_freeze_crack_material(PIECE_FREEZE_CRACK_END_WIDTH)
	var release_overlay: Sprite2D = create_piece_freeze_overlay(holder, PIECE_FREEZE_RELEASE_NAME, freeze_material)
	var square_release: Polygon2D = create_piece_freeze_square_overlay(board_pos, freeze_material, PIECE_FREEZE_SQUARE_RELEASE_NAME)
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(freeze_material, "shader_parameter/crack_width", PIECE_FREEZE_CRACK_START_WIDTH, PIECE_FREEZE_CRACK_RELEASE_DURATION)
	tween.finished.connect(func():
		if is_instance_valid(release_overlay):
			release_overlay.queue_free()
		if is_instance_valid(square_release):
			square_release.queue_free()
	)

func remove_piece_freeze_overlay(holder: Sprite2D) -> void:
	if holder == null or !is_instance_valid(holder):
		return

	var existing_freeze: Node = holder.get_node_or_null(PIECE_FREEZE_CRACK_NAME)
	if existing_freeze != null:
		existing_freeze.free()

func remove_piece_freeze_square_overlay(board_pos: Vector2) -> void:
	if board_markers_node == null or !is_instance_valid(board_markers_node):
		return

	var existing_square: Node = board_markers_node.get_node_or_null(get_piece_freeze_square_node_name(board_pos, PIECE_FREEZE_SQUARE_NAME))
	if existing_square != null:
		existing_square.free()

func get_piece_freeze_visual_signature(board_pos: Vector2) -> String:
	if !piece_objects.has(board_pos):
		return ""

	var piece: Piece = piece_objects[board_pos] as Piece
	if piece == null:
		return ""

	var player_id: int = get_player_id_for_color(piece.color)
	var is_frozen_square: bool = CardEffectResolver.is_square_frozen(current_board_effects, board_pos, player_id)
	var is_exhausted_piece: bool = piece.exhausted_this_turn
	if !is_frozen_square and !is_exhausted_piece:
		return ""

	var attached_card_name: String = ""
	if piece.attached_card != null:
		attached_card_name = piece.attached_card.card_name

	return "%s:%s:%s:%s:%s" % [
		board_pos,
		piece.color,
		attached_card_name,
		is_exhausted_piece,
		is_frozen_square,
	]

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
	call_deferred("play_pending_piece_revert_animations")

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
	var expiring_piece_texture: Texture2D = get_piece_visual_texture(piece)
	var expired_card: Card = piece.use_turn()
	if expired_card == null:
		return

	queue_piece_revert_animation(piece_pos, expiring_piece_texture)
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

func update_from_server_state(pieces_data: Dictionary, player_hands: Dictionary, current_turn: int, server_game_over: bool = false, winner_player: int = -1, player_deck_sizes: Dictionary = {}, hidden_cards: Array = [], player_base_fields: Dictionary = {}, board_effects: Array = [], player_names: Dictionary = {}, recent_card_transfers: Array = [], recent_card_expirations: Array = [], last_move: Dictionary = {}, player_portraits: Dictionary = {}):
	var previous_piece_visual_state: Dictionary = get_piece_visual_state_snapshot()
	var previous_hidden_card_counts: Dictionary = hidden_card_counts.duplicate()
	var current_hidden_card_counts: Dictionary = get_hidden_card_counts_from_state(hidden_cards)
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
	current_player_portraits = parse_player_portraits(player_portraits)
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
	var card_expiration_events: Array[Dictionary] = get_state_card_expiration_events(previous_piece_visual_state, recent_card_expirations)
	var state_attach_animations: Array[Dictionary] = collect_state_attach_animations(previous_piece_visual_state, hidden_cards, previous_hidden_card_counts)
	var state_piece_revert_animations: Array[Dictionary] = collect_piece_revert_animations(previous_piece_visual_state, card_expiration_events)
	hidden_card_counts = current_hidden_card_counts
	var animated_attach_positions: Dictionary = get_attach_animation_positions(state_attach_animations)
	for position_value in animated_attach_positions.keys():
		var animated_attach_pos: Vector2 = value_to_vector2(position_value, INVALID_BOARD_POS)
		if is_valid_position(animated_attach_pos):
			begin_card_attach_process(animated_attach_pos)
	display_board()
	finish_resolved_pending_card_attach_processes(animated_attach_positions)
	if !state_attach_animations.is_empty():
		call_deferred("play_state_attach_animations", state_attach_animations)
	if !state_piece_revert_animations.is_empty():
		call_deferred("play_piece_revert_animations", state_piece_revert_animations)
	if has_received_server_state && !should_skip_visual_animations():
		if recent_card_transfers.is_empty():
			animate_state_draw_if_needed(1, previous_white_hand_names, current_white_hand_names)
			animate_state_draw_if_needed(-1, previous_black_hand_names, current_black_hand_names)
		else:
			animate_recent_card_transfers(recent_card_transfers, previous_white_hand_names, current_white_hand_names, previous_black_hand_names, current_black_hand_names)
		animate_recent_card_expirations(card_expiration_events)
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

func parse_player_portraits(player_portraits: Dictionary) -> Dictionary:
	var parsed_portraits: Dictionary = current_player_portraits.duplicate()
	if parsed_portraits.is_empty():
		parsed_portraits = {
			0: PortraitLibrary.get_default_portrait_for_player_id(0),
			1: PortraitLibrary.get_default_portrait_for_player_id(1),
		}

	for player_id in [0, 1]:
		if player_portraits.has(player_id):
			parsed_portraits[player_id] = PortraitLibrary.config_from_data_or_default(player_portraits[player_id], player_id)
			continue

		var string_key: String = str(player_id)
		if player_portraits.has(string_key):
			parsed_portraits[player_id] = PortraitLibrary.config_from_data_or_default(player_portraits[string_key], player_id)

	return parsed_portraits

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

	action_status_container.anchor_left = 1.0
	action_status_container.anchor_right = 1.0
	action_status_container.anchor_top = 1.0
	action_status_container.anchor_bottom = 1.0

	var button_center_x: float = -ACTION_STATUS_MARGIN - ACTION_STATUS_SIZE.x * 0.5
	var bottom_offset: float = -ACTION_STATUS_MARGIN - ACTION_STATUS_SIZE.y
	if end_turn_button != null:
		button_center_x = (end_turn_button.offset_left + end_turn_button.offset_right) * 0.5
		bottom_offset = end_turn_button.offset_top - 8.0
	var left_offset: float = button_center_x - ACTION_STATUS_SIZE.x * 0.5
	var top_offset: float = bottom_offset - ACTION_STATUS_SIZE.y
	action_status_container.offset_left = left_offset
	action_status_container.offset_right = left_offset + ACTION_STATUS_SIZE.x
	action_status_container.offset_top = top_offset
	action_status_container.offset_bottom = bottom_offset

func arrange_turn_timer_ui() -> void:
	if turn_timer_counter_container == null:
		return

	turn_timer_counter_container.anchor_left = 1.0
	turn_timer_counter_container.anchor_right = 1.0
	turn_timer_counter_container.anchor_top = 1.0
	turn_timer_counter_container.anchor_bottom = 1.0

	var button_center_x: float = -ACTION_STATUS_MARGIN - DECK_COUNTER_SIZE.x * 0.5
	var bottom_offset: float = -ACTION_STATUS_MARGIN - ACTION_STATUS_SIZE.y - TURN_TIMER_GAP
	if action_status_container != null:
		button_center_x = (action_status_container.offset_left + action_status_container.offset_right) * 0.5
		bottom_offset = action_status_container.offset_top - TURN_TIMER_GAP
	elif end_turn_button != null:
		button_center_x = (end_turn_button.offset_left + end_turn_button.offset_right) * 0.5
		bottom_offset = end_turn_button.offset_top - TURN_TIMER_GAP

	var left_offset: float = button_center_x - DECK_COUNTER_SIZE.x * 0.5
	var top_offset: float = bottom_offset - DECK_COUNTER_SIZE.y
	turn_timer_counter_container.offset_left = left_offset
	turn_timer_counter_container.offset_right = left_offset + DECK_COUNTER_SIZE.x
	turn_timer_counter_container.offset_top = top_offset
	turn_timer_counter_container.offset_bottom = bottom_offset

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

	update_board_special_tiles()
	for child in board_markers_node.get_children():
		child.queue_free()

	if PlayerSettingsStore.is_enemy_attack_markers_enabled():
		add_enemy_attack_markers()
	if PlayerSettingsStore.is_last_move_arrow_enabled():
		add_last_move_arrow_marker()

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
