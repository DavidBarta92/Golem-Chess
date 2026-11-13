extends Sprite2D

signal piece_selected(piece_pos: Vector2, player_id: int)
signal stamp_affixed(piece_pos: Vector2, stamp_name: String, owner_color: int, hand_index: int)
signal piece_moved(from_pos: Vector2, to_pos: Vector2, owner_color: int)
## A move took a golem, as the host's state brings it
## (ServerStateUpdateController). A bomb's captures are not moves and do not
## count.
signal piece_captured(by_color: int, captured_color: int, capturing_stamp_name: String, captured_stamp_name: String)
signal stamp_exchanged(stamp_name: String, owner_color: int, hand_index: int)
signal codex_page_turned(owner_color: int, page_index: int)
signal turn_ended(ending_color: int, next_color: int)
## The turn has gone over, as soon as the state says so: turn_ended waits for the
## board to show it. `animate` is false when things are only being set in place.
signal turn_changed(turn_color: int, animate: bool)
signal tutorial_action_rejected(action_name: String, context: Dictionary)
## The result has gone up on screen. See hold_after_result.
signal game_finished(winner_color: int)

const BOARD_SIZE: int = BoardConfig.BOARD_SIZE
const CELL_WIDTH: int = BoardConfig.CELL_WIDTH

const MATCH_BOARD_CONTROLLER_REGISTRY_SCRIPT = preload("res://Scripts/MatchView/MatchBoardControllerRegistry.gd")
const RESPONSIVE_REFERENCE_VIEWPORT_SIZE = Vector2(1280.0, 720.0)

const DEFAULT_PIECE_TEXTURE = preload("res://Assets/golem_front.png")
const OWN_DEFAULT_PIECE_TEXTURE = preload("res://Assets/golem_back.png")

const VISUAL_PROCESS_STAMP_AFFIX: String = "stamp_affix"
const VISUAL_PROCESS_STATE_STAMP_AFFIX: String = "state_stamp_affix"
const VISUAL_PROCESS_PIECE_REVERT: String = "piece_revert"
const VISUAL_PROCESS_PIECE_MOVE: String = "piece_move"
const VISUAL_PROCESS_PIECE_SHATTER: String = "piece_shatter"
const VISUAL_PROCESS_BOMB_WARNING: String = "bomb_warning"
# Fitted to the board drawn in Assets/board_grid_line.png, the same way the
# perspective constants above are. The drawing's outer frame is a band at the
# far and near ends only - on the left and right the board's edge and the grid's
# edge are the same stroke - so the frame is a cell deep and barely a third of a
# pixel wide. The side is the darker face the player looks onto, below the near
# frame line. Worst error against the ink: 1.8 px of a 1919 px wide drawing.
# The frame is the drawing's outer ring: one cell on all four sides, which is
# what turns the 7x7 the game is played on into the 9x9 that is drawn.
const BOARD_FRAME_WIDTH: float = CELL_WIDTH
const BOARD_FRAME_VERTICAL_EXTENSION: float = CELL_WIDTH
const BOARD_FRAME_COLOR = Color(0.40, 0.32, 0.30, 1.0)
const BOARD_SIDE_COLOR = Color(0.02, 0.12, 0.16, 1.0)
const DEFAULT_PIECE_VISUAL_HEIGHT: float = 24.0
const PIECE_AUTO_FIT_HEIGHT_THRESHOLD: float = DEFAULT_PIECE_VISUAL_HEIGHT * 2.0
const PIECE_SHADOW_LIGHT_ENERGY: float = 0.30
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_FIXED_RADIUS_Y: float = 3.0
const BOARD_LIGHT_RECEIVE_MASK: int = 1
const PIECE_LIGHT_OCCLUDER_MASK: int = 1
const PIECE_LIGHT_RECEIVE_MASK: int = 2
const PIECE_EFFECT_LIGHT_RECEIVE_MASK: int = 0
const PIECE_TEXTURE_FILTER = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
const PLAYER_HAND_SIZE = DeckManager.HAND_SIZE
const STAMP_UI_SIZE = Vector2(168.7, 229)
const STAMP_HAND_SCALE = 0.648
const DECK_STAMP_SCALE = STAMP_HAND_SCALE
const STAMP_RETURN_TO_DECK_END_SCALE: float = DECK_STAMP_SCALE * 0.50
const STAMP_UI_GAP = 10
const BOTTOM_STAMP_HAND_MARGIN = 34
const HOVER_STAMP_MARGIN = 24
const HOVER_STAMP_EXTRA_LEFT_OFFSET: float = 16.0
const HOVER_STAMP_PREVIEW_SCALE: float = 0.82
const HOVER_STAMP_VERTICAL_OFFSET: float = 26.0
const HOVER_STAMP_ROTATION_DEGREES: float = -4.0
const HOVER_PIECE_PREVIEW_SIZE = Vector2(188, 224)
const HOVER_PIECE_PREVIEW_VERTICAL_OFFSET: float = -78.0
const HOVER_DESCRIPTION_TEXT_MARGIN = Vector2(22, 30)
const HOVER_DESCRIPTION_PANEL_GAP: float = 8.0
const HOVER_DESCRIPTION_PANEL_WIDTH: float = 271.6
const HOVER_DESCRIPTION_PANEL_HEIGHT: float = 229.0
const HOVER_DURATION_SHADOW_COLOR: Color = Color(0.070588, 0.070588, 0.474510, 0.9)
const HOVER_DURATION_SHADOW_BLUR: float = 1.6
const HOVER_DURATION_OUTLINE_SIZE: int = 3
const DECK_COUNTER_BACKGROUND_SIZE = Vector2(38, 38)
const DECK_COUNTER_DIGIT_SIZE = DECK_COUNTER_BACKGROUND_SIZE
const DECK_COUNTER_DIGIT_GAP: float = 0.0
const DECK_COUNTER_FRAME_SIZE = Vector2(82, 42)
const DECK_COUNTER_CONTENT_OFFSET = Vector2(
	(DECK_COUNTER_FRAME_SIZE.x - (DECK_COUNTER_BACKGROUND_SIZE.x * 2.0 + DECK_COUNTER_DIGIT_GAP)) * 0.5,
	(DECK_COUNTER_FRAME_SIZE.y - DECK_COUNTER_BACKGROUND_SIZE.y) * 0.5
)
const DECK_COUNTER_SIZE = DECK_COUNTER_FRAME_SIZE
const PLAYER_PORTRAIT_SIZE = Vector2(116, 136)
const PLAYER_PORTRAIT_TOP_POSITION = Vector2(70, 4)
const INVALID_BOARD_POS = Vector2(-1, -1)
const WHITE_BASE_FIELD: Vector2 = BoardConfig.WHITE_BASE_FIELD
const BLACK_BASE_FIELD: Vector2 = BoardConfig.BLACK_BASE_FIELD
const MAIN_MENU_SCENE = "res://Scenes/MainMenu.tscn"
# The Esc menu's own buttons, beside the dialog's OK (which leaves the match).
const QUIT_DIALOG_RETRY_ACTION: StringName = &"retry"
const QUIT_DIALOG_CANCEL_ACTION: StringName = &"cancel"
const TUTORIAL_ACTION_SELECT_PIECE = "select_piece"
const TUTORIAL_ACTION_AFFIX_STAMP = "affix_stamp"
const TUTORIAL_ACTION_MOVE_PIECE = "move_piece"
const TUTORIAL_ACTION_EXCHANGE_STAMP = "exchange_stamp"
const TUTORIAL_ACTION_TURN_PAGE = "turn_page"
const TUTORIAL_ACTION_END_TURN = "end_turn"
const TUTORIAL_ACTION_PLACE_CROWN = "place_crown"
# Translation key, not display text - the actual paragraph lives in Localization/translations.csv.
const PIECE_SHATTER_FRAGMENT_GROUP_NONE: String = ""
const PIECE_SHATTER_FRAGMENT_GROUP_BOTTOM: String = "bottom"
const PIECE_SHATTER_FRAGMENT_GROUP_TOP: String = "top"
const PIECE_SHATTER_FRAGMENT_GROUP_PENDING: String = "pending"
const PIECE_SHATTER_ROUTE_Z_FRONT_OFFSET: int = 2
const PIECE_SHATTER_ROUTE_Z_BACK_OFFSET: int = -1
const PIECE_MOVE_ROUTE_Z_FRONT_OFFSET: int = 1
const PIECE_MOVE_ROUTE_Z_BACK_OFFSET: int = -1

@export_group("Piece Shatter")
@export_range(0, 64, 1) var piece_shatter_debris_count: int = 18
@export_range(0, 3, 1) var piece_shatter_returning_debris_count: int = 3
@export_range(0.05, 2.0, 0.01) var piece_shatter_scatter_duration: float = 0.46
@export_range(0.05, 2.0, 0.01) var piece_shatter_fade_duration: float = 0.42
@export_range(0.05, 2.0, 0.01) var piece_shatter_return_duration: float = 0.38
@export_range(0.02, 1.0, 0.01) var piece_shatter_return_fade_duration: float = 0.16
@export_range(0.0, 1.0, 0.01) var piece_shatter_fragment_settle_duration: float = 0.24
@export_range(0.1, 2.0, 0.05) var piece_shatter_scatter_radius: float = 0.84
@export_range(0.0, 1.0, 0.05) var piece_shatter_scatter_jitter: float = 0.28
## A chip's size, as a share of the height of the drawing it breaks off from.
@export_range(0.01, 0.5, 0.01) var piece_shatter_min_chip_size: float = 0.09
@export_range(0.01, 0.5, 0.01) var piece_shatter_max_chip_size: float = 0.26
## How long after a piece breaks its chips lie about before they soak into
## the paper (over `piece_shatter_fade_duration`). The next move clears them
## sooner.
@export_range(0.0, 6.0, 0.1) var piece_shatter_debris_linger_duration: float = 2.4
@export var piece_shatter_avoid_occupied_cells: bool = true
@export_range(0.0, 0.45, 0.01) var piece_shatter_route_jitter_ratio: float = 0.12

@export_group("Capture Sparkle")
@export var capture_sparkle_color: Color = Color(1.0, 0.95, 0.78, 1.0)
@export_range(0.05, 2.0, 0.01) var capture_sparkle_duration: float = 0.4
@export_range(0.05, 1.0, 0.01) var capture_sparkle_fade_out_ratio: float = 0.65
@export_range(0.2, 6.0, 0.05) var capture_sparkle_size_ratio: float = 2.15
@export_range(100.0, 10000.0, 50.0) var capture_sparkle_shader_scale: float = 10000.0
@export_range(0.0, 1.0, 0.01) var capture_sparkle_decay_magnitude: float = 0.06
@export_range(-20.0, 20.0, 0.05) var capture_sparkle_rotate_speed: float = 2.25
@export_range(0.0, 5.0, 0.01) var capture_sparkle_time_speed: float = 2.76
@export_range(0.0, 10.0, 0.01) var capture_sparkle_frequency_base: float = 1.0
@export_range(0.0, 10.0, 0.01) var capture_sparkle_frequency_disturbance_scale: float = 0.16
@export_range(0.0, 20.0, 0.1) var capture_sparkle_circle_ratio: float = 0.0

@export_group("Piece Movement")
@export var piece_move_animation_enabled: bool = true
@export var piece_move_avoid_occupied_footprints: bool = true
@export_range(0.05, 1.0, 0.01) var piece_move_duration: float = 0.32
@export_range(0.0, 0.5, 0.01) var piece_move_lift_ratio: float = 0.16
@export_range(0.05, 0.5, 0.01) var piece_move_lift_duration: float = 0.16
@export_range(0.05, 0.5, 0.01) var piece_move_drop_duration: float = 0.18
@export_range(0.03, 0.3, 0.01) var piece_move_wobble_step_duration: float = 0.12
@export_range(0.0, 8.0, 0.1) var piece_move_wobble_rotation_degrees: float = 2.4
@export_range(0.0, 5.0, 0.1) var piece_move_travel_tilt_degrees: float = 1.4
@export_range(0.2, 0.55, 0.01) var piece_move_capture_approach_edge_ratio: float = 0.42
@export_range(0.0, 0.6, 0.01) var piece_move_capture_approach_hold_duration: float = 0.25
@export_range(0.05, 0.35, 0.01) var piece_move_capture_push_duration: float = 0.14
## Both pieces hold still this long at the moment of contact, the struck one
## flashing and cracking, before it breaks and the striker recoils.
@export_range(0.0, 0.2, 0.01) var piece_move_capture_hitstop_duration: float = 0.1
@export_range(0.05, 0.35, 0.01) var piece_move_capture_recoil_duration: float = 0.12
@export_range(0.05, 0.5, 0.01) var piece_move_capture_center_settle_duration: float = 0.24
@export_range(0.0, 18.0, 0.5) var piece_move_capture_push_rotation_degrees: float = 8.0
@export var piece_move_shadow_color: Color = Color(0.03, 0.025, 0.02, 0.85)
@export var piece_move_shadow_radius_scale: Vector2 = Vector2(1.30, 1.15)
@export_range(0.01, 0.9, 0.01) var piece_move_shadow_ground_edge_softness: float = 0.35
@export_range(0.01, 0.9, 0.01) var piece_move_shadow_lifted_edge_softness: float = 0.72
@export var piece_move_shadow_lifted_scale: Vector2 = Vector2(1.38, 1.28)
@export_range(0.05, 1.0, 0.01) var piece_move_shadow_lifted_alpha: float = 0.25
@export_range(0.0, 16.0, 0.5) var piece_move_footprint_clearance: float = 2.0

@export_group("Piece Effect Occlusion")
@export var occluded_piece_effect_dim_color: Color = Color(0.0, 0.0, 0.0, 0.34)

@export_group("Bomb Warning")
@export var bomb_warning_color: Color = Color(1.0, 0.56, 0.56, 1.0)
@export_range(0.2, 3.0, 0.05) var bomb_warning_duration: float = 1.5
@export_range(0.0, 24.0, 0.5) var bomb_warning_rise_distance: float = 7.0
@export_range(0.2, 3.0, 0.05) var bomb_warning_size_ratio: float = 1.15
@export_range(-24.0, 24.0, 0.5) var bomb_warning_target_y_offset: float = -6.0

@export_group("Board Shadow")
@export var board_shadow_enabled: bool = true
@export var board_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.24)
@export var board_shadow_offset: Vector2 = Vector2(9.0, 14.0)
@export_range(0.0, 24.0, 0.5) var board_shadow_spread: float = 7.0
@export_range(1, 8, 1) var board_shadow_steps: int = 4

@export_group("Board Shader")
@export var board_shader_enabled: bool = true
@export_range(0.0, 128.0, 1.0) var board_shader_margin: float = CELL_WIDTH * 3.5
@export var board_shader_offset: Vector3 = Vector3.ZERO

@export_group("Piece Shader")
@export var piece_kuwahara_enabled: bool = false
@export var piece_kuwahara_offset: Vector3 = Vector3.ZERO

@onready var pieces_node = $Pieces
@onready var dots = $Dots
@onready var board_tiles_node = $BoardTiles
@onready var canvas_layer = $"../CanvasLayer"
@onready var white_pieces = $"../CanvasLayer/white_pieces"
@onready var black_pieces = $"../CanvasLayer/black_pieces"
@onready var codex_visual = get_node_or_null("../CanvasLayer/Codex")
# Searched for rather than addressed by path: the codex lives among the
# background's layers, and which layer it sits between is a matter of what
# should cover its foot - it has been moved once already, and a stale path
# here fails silently, leaving the codex sitting still through a whole match.
@onready var opponent_codex_visual = _find_opponent_codex()

var board : Array
var piece_objects: Dictionary = {}
var white : bool = true
var state : bool = false
var moves = []
var selected_piece : Vector2
var hovered_piece : Vector2 = Vector2(-1, -1)
var hover_highlighted_piece : Vector2 = Vector2(-1, -1)
var white_stamp_deck: Array[String] = []
var black_stamp_deck: Array[String] = []
var white_stamp_hand: Array[Stamp] = []
var black_stamp_hand: Array[Stamp] = []
var white_stamp_visuals: Array[StampVisual] = []
var black_stamp_visuals: Array[StampVisual] = []
var white_deck_visual: StampVisual
var black_deck_visual: StampVisual
var affixed_stamp_this_turn: Dictionary = {
	1: false,
	-1: false,
}
var affixed_stamp_count_this_turn: Dictionary = {0: 0, 1: 0}
var completed_turn_counts: Dictionary = {0: 0, 1: 0}
var moved_piece_this_turn: Dictionary = {
	1: false,
	-1: false,
}
var exchanged_stamp_this_turn: Dictionary = {
	1: false,
	-1: false,
}
var has_turned_page_this_turn: Dictionary = {
	1: false,
	-1: false,
}
var played_stamp_hand_slots_this_turn: Dictionary = {
	1: [],
	-1: [],
}
var pending_stamp_affix_positions: Dictionary = {}
var exchanged_stamp_names_this_turn: Dictionary = {
	1: [],
	-1: [],
}
var game_over: bool = false
var hover_stamp_group: Control
var hover_stamp_preview: StampVisual
var hover_piece_preview: TextureRect
var hover_duration_label: Label
var hover_description_panel: Control
var hover_description_label: RichTextLabel
var has_received_server_state: bool = false
var quit_confirmation_dialog: AcceptDialog
var quit_retry_button: Button
var white_deck_count_override: int = -1
var black_deck_count_override: int = -1
var hidden_stamp_counts: Dictionary = {}
var controller_registry
var board_markers_node: Node2D
var board_frame_node: Node2D
var board_base_tiles_node: Node2D
var board_special_tiles_node: Node2D
var board_special_tile_nodes: Dictionary = {}
var board_special_tile_types: Dictionary = {}
var board_special_tiles_initialized: bool = false
var piece_effects_node: Node2D
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
var pending_piece_shatter_respawn_reveal_counts: Dictionary = {}
var pending_piece_shatter_respawn_reveal_groups: Dictionary = {}
var respawn_piece_shatter_fragment_markers: Dictionary = {}
var pending_edge_respawn_fragment_markers: Dictionary = {}
var tutorial_mode_active: bool = false
## Set by a scene that takes over once the result is up (the tutorial's
## outro): the result stays on screen and moving on is that scene's business,
## instead of the match leaving on its own after a wait.
var hold_after_result: bool = false
var tutorial_constraints_enabled: bool = false
var tutorial_constraints: Dictionary = {}

## The colour the board is seen from (null before a match sets it). Setting it
## turns the controllers that draw by it round too.
var side:
	set(value):
		side = value
		if controller_registry != null:
			controller_registry.apply_view()

func _ready():
	get_match_board_lifecycle_controller().ready()

func get_controller_registry():
	if controller_registry == null:
		controller_registry = MATCH_BOARD_CONTROLLER_REGISTRY_SCRIPT.new()
		controller_registry.configure({
			"match_board": self,
		})
	return controller_registry

func get_match_board_lifecycle_controller():
	return get_controller_registry().get_match_board_lifecycle_controller()

func get_board_geometry():
	return get_controller_registry().get_board_geometry()

func get_board_visuals():
	return get_controller_registry().get_board_visuals()

func get_board_environment_controller():
	return get_controller_registry().get_board_environment_controller()

func get_visual_process_tracker():
	return get_controller_registry().get_visual_process_tracker()

func get_board_tile_controller():
	return get_controller_registry().get_board_tile_controller()

func get_board_marker_controller():
	return get_controller_registry().get_board_marker_controller()

func get_match_state_sync_controller():
	return get_controller_registry().get_match_state_sync_controller()

func get_server_state_update_controller():
	return get_controller_registry().get_server_state_update_controller()

func get_server_state_visual_update_controller():
	return get_controller_registry().get_server_state_visual_update_controller()

func get_local_stamp_action_controller():
	return get_controller_registry().get_local_stamp_action_controller()

func get_local_gameplay_controller():
	return get_controller_registry().get_local_gameplay_controller()

func get_tutorial_match_adapter():
	return get_controller_registry().get_tutorial_match_adapter()

func get_game_result_controller():
	return get_controller_registry().get_game_result_controller()

func get_turn_flow_controller():
	return get_controller_registry().get_turn_flow_controller()

func get_turn_action_state_controller():
	return get_controller_registry().get_turn_action_state_controller()

func get_piece_objects() -> Dictionary:
	return piece_objects

func get_current_board_effects() -> Array:
	return current_board_effects

func get_current_last_move() -> Dictionary:
	return current_last_move

func get_pending_stamp_affix_positions() -> Dictionary:
	return pending_stamp_affix_positions

func get_piece_texture_resolver():
	return get_controller_registry().get_piece_texture_resolver()

func get_piece_visuals():
	return get_controller_registry().get_piece_visuals()

func get_piece_effect_geometry_controller():
	return get_controller_registry().get_piece_effect_geometry_controller()

func get_piece_move_animator():
	return get_controller_registry().get_piece_move_animator()

func has_piece_object_at(board_pos: Vector2) -> bool:
	return piece_objects.has(board_pos)

func get_piece_shatter_animator():
	return get_controller_registry().get_piece_shatter_animator()

func get_piece_respawn_fragment_coordinator():
	return get_controller_registry().get_piece_respawn_fragment_coordinator()

func get_piece_display_controller():
	return get_controller_registry().get_piece_display_controller()

func get_piece_effect_animator():
	return get_controller_registry().get_piece_effect_animator()

func get_piece_effect_flow_controller():
	return get_controller_registry().get_piece_effect_flow_controller()

func get_freeze_effect_animator():
	return get_controller_registry().get_freeze_effect_animator()

func get_board_effect_icon_grid_controller():
	return get_controller_registry().get_board_effect_icon_grid_controller()

func get_stamp_hud_controller():
	return get_controller_registry().get_stamp_hud_controller()

func get_match_codex_controller():
	return get_controller_registry().get_match_codex_controller()

func get_crown_controller():
	return get_controller_registry().get_crown_controller()

func play_codex_page_turn_animation() -> void:
	if codex_visual != null and is_instance_valid(codex_visual):
		codex_visual.play_turn_page_animation()

func play_opponent_codex_page_turn_animation() -> void:
	if opponent_codex_visual != null and is_instance_valid(opponent_codex_visual):
		opponent_codex_visual.play_turn_page_animation()

func set_codex_hand_follower(hand_node: Control) -> void:
	if codex_visual != null and is_instance_valid(codex_visual):
		codex_visual.set_hand_follower(hand_node)

func run_when_codex_off_screen(callback: Callable) -> void:
	if codex_visual != null and is_instance_valid(codex_visual):
		codex_visual.run_when_off_screen(callback)
	else:
		callback.call()

func refresh_stamp_hand_visuals(owner_color: int) -> void:
	if owner_color == 1:
		white_stamp_visuals = get_stamp_hand_state_controller().populate_stamp_hand(white_pieces, white_stamp_hand, 1)
	else:
		black_stamp_visuals = get_stamp_hand_state_controller().populate_stamp_hand(black_pieces, black_stamp_hand, -1)
	get_stamp_hand_state_controller().setup_deck_visuals()
	get_stamp_hand_state_controller().update_stamp_presentation()

func set_codex_turn_active(active: bool) -> void:
	if codex_visual != null and is_instance_valid(codex_visual):
		codex_visual.set_turn_active(active)

func set_opponent_codex_turn_active(active: bool) -> void:
	if opponent_codex_visual != null and is_instance_valid(opponent_codex_visual):
		opponent_codex_visual.set_turn_active(active)

func get_stamp_hover_preview_controller():
	return get_controller_registry().get_stamp_hover_preview_controller()

func get_piece_duration_change_animator():
	return get_controller_registry().get_piece_duration_change_animator()

func get_stamp_interaction_controller():
	return get_controller_registry().get_stamp_interaction_controller()

func get_stamp_animation_controller():
	return get_controller_registry().get_stamp_animation_controller()

func get_visible_viewport_size() -> Vector2:
	return get_viewport().get_visible_rect().size

func get_board_screen_size() -> float:
	return BOARD_SIZE * CELL_WIDTH * get_board_screen_scale()

func get_game_result_context() -> Dictionary:
	return {
		"is_ai_vs_ai_batch": GameConfig.is_ai_vs_ai_batch,
		"ai_matches_played": GameConfig.ai_vs_ai_matches_played,
		"ai_match_count": GameConfig.ai_vs_ai_match_count,
		"side_is_null": side == null,
	}

func get_deck_counter_controller():
	return get_controller_registry().get_deck_counter_controller()

func get_turn_hud_controller():
	return get_controller_registry().get_turn_hud_controller()

func get_player_portrait_top_position() -> Vector2:
	return scale_canvas_point_from_reference(PLAYER_PORTRAIT_TOP_POSITION)

func get_scaled_player_portrait_size() -> Vector2:
	return scale_canvas_size_from_reference(PLAYER_PORTRAIT_SIZE)

func scale_canvas_point_from_reference(point: Vector2) -> Vector2:
	return point * get_canvas_scale_from_reference()

func scale_canvas_size_from_reference(source_size: Vector2) -> Vector2:
	return source_size * get_canvas_scale_from_reference()

func get_canvas_scale_from_reference() -> Vector2:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return Vector2.ONE
	return Vector2(
		viewport_size.x / RESPONSIVE_REFERENCE_VIEWPORT_SIZE.x,
		viewport_size.y / RESPONSIVE_REFERENCE_VIEWPORT_SIZE.y
	)

func get_match_input_controller():
	return get_controller_registry().get_match_input_controller()

func get_stamp_hand_state_controller():
	return get_controller_registry().get_stamp_hand_state_controller()

func is_game_over() -> bool:
	return game_over

func is_end_turn_tutorial_allowed() -> bool:
	return get_tutorial_match_adapter().is_action_allowed(TUTORIAL_ACTION_END_TURN)

func should_show_first_turn_end_button() -> bool:
	var player_id: int = BoardConfig.get_player_id_for_color(get_current_turn_color())
	if int(completed_turn_counts.get(player_id, 0)) == 0:
		return true
	return can_end_turn_for_frozen_piece()

func can_end_first_turn() -> bool:
	if !should_show_first_turn_end_button():
		return false
	var player_id: int = BoardConfig.get_player_id_for_color(get_current_turn_color())
	if int(completed_turn_counts.get(player_id, 0)) == 0:
		return int(affixed_stamp_count_this_turn.get(player_id, 0)) >= 1
	return can_end_turn_for_frozen_piece()

## The host's NetworkGameHost.can_end_turn_due_to_frozen_piece, on what this
## board shows: a turn with no move left in it may end by the button when a
## golem that could move is frozen.
func can_end_turn_for_frozen_piece() -> bool:
	var current_color: int = get_current_turn_color()
	if bool(moved_piece_this_turn.get(current_color, false)):
		return false
	if MoveRules.has_valid_piece_move(piece_objects, current_color, BOARD_SIZE, current_board_effects):
		return false
	return MoveRules.has_frozen_movable_piece(piece_objects, current_color, BOARD_SIZE, current_board_effects)

func defer_turn_timer_timeout(expected_turn_color: int) -> void:
	get_turn_flow_controller().on_turn_timer_timeout.call_deferred(expected_turn_color)

func _find_opponent_codex() -> Node:
	var background: Node = get_node_or_null("../BackgroundLayer/MatchBackground")
	if background == null:
		return null
	return background.find_child("Codex", true, false)

## The room this match is played in. Lives outside the HUD's layer, so the
## pieces of interface drawn into it are reached through here.
func get_match_background() -> Node:
	return get_node_or_null("../BackgroundLayer/MatchBackground")

func create_board_markers_node():
	board_markers_node = Node2D.new()
	board_markers_node.name = "BoardMarkers"
	board_markers_node.z_index = 1
	add_child(board_markers_node)
	move_child(board_markers_node, 0)
	pieces_node.z_index = 10
	# The pieces reach from here up to one rank stride per rank, so the dots
	# clear the whole band rather than sitting a fixed few slots above it.
	dots.z_index = pieces_node.z_index + BOARD_SIZE * BoardConfig.DEPTH_Z_STRIDE + 8
	get_controller_registry().reconfigure_all()

func create_piece_effects_node() -> void:
	if piece_effects_node != null and is_instance_valid(piece_effects_node):
		return

	# The controllers hold the node in their configs; a new one means new configs.
	get_controller_registry().reconfigure_all()
	piece_effects_node = Node2D.new()
	piece_effects_node.name = "PieceEffects"
	piece_effects_node.z_index = 12
	add_child(piece_effects_node)

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

	DebugLog.info("Pieces initialized without starting stamps.")

func create_hover_piece_ui():
	var hover_controller = get_stamp_hover_preview_controller()
	hover_controller.create_ui()
	hover_stamp_group = hover_controller.hover_stamp_group
	hover_stamp_preview = hover_controller.hover_stamp_preview
	hover_piece_preview = hover_controller.hover_piece_preview
	hover_duration_label = hover_controller.hover_duration_label
	hover_description_panel = hover_controller.hover_description_panel
	hover_description_label = hover_controller.hover_description_label

## The menu Esc brings up over a match: leave it, start it over, or go back to
## it, in that order. The dialog's own OK is the leave button and the other two
## are lined up after it. Which of the first two a match offers is settled each
## time the menu opens (show_quit_confirmation).
func create_quit_confirmation_ui():
	quit_confirmation_dialog = AcceptDialog.new()
	canvas_layer.add_child(quit_confirmation_dialog)
	quit_confirmation_dialog.ok_button_text = tr("MATCH_MENU_LEAVE")
	quit_retry_button = quit_confirmation_dialog.add_button(tr("MATCH_MENU_RETRY"), true, QUIT_DIALOG_RETRY_ACTION)
	quit_confirmation_dialog.add_button(tr("Cancel"), true, QUIT_DIALOG_CANCEL_ACTION)
	quit_confirmation_dialog.exclusive = true
	quit_confirmation_dialog.confirmed.connect(_on_quit_confirmed)
	quit_confirmation_dialog.custom_action.connect(_on_quit_dialog_action)

func begin_stamp_affix_process(piece_position: Vector2) -> void:
	if !pending_stamp_affix_positions.has(piece_position):
		get_visual_process_tracker().begin(VISUAL_PROCESS_STAMP_AFFIX)
	pending_stamp_affix_positions[piece_position] = true

func finish_stamp_affix_process(piece_position: Vector2) -> void:
	var had_pending_affix: bool = pending_stamp_affix_positions.has(piece_position)
	if pending_stamp_affix_positions.has(piece_position):
		pending_stamp_affix_positions.erase(piece_position)
		get_visual_process_tracker().finish(VISUAL_PROCESS_STAMP_AFFIX)
	if had_pending_affix:
		get_piece_display_controller().refresh_piece_freeze_overlay(piece_position)
	get_stamp_hand_state_controller().update_stamp_drag_permissions()

func update_stamp_face_visibility(local_color: int):
	for stamp_visual in white_stamp_visuals:
		stamp_visual.set_face_down(stamp_visual.owner_color != local_color)
	for stamp_visual in black_stamp_visuals:
		stamp_visual.set_face_down(stamp_visual.owner_color != local_color)

func get_local_view_color() -> int:
	if side == null:
		return get_controllable_color()
	return get_own_color()

func is_local_view_ready() -> bool:
	return side != null or GameConfig.is_singleplayer or tutorial_mode_active

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

func get_color_for_player_id(player_id: int) -> int:
	return BoardConfig.get_color_for_player_id(player_id)

func get_own_player_id() -> int:
	return BoardConfig.get_player_id_for_color(get_own_color())

func show_hover_stamp_description(stamp: Stamp) -> void:
	if stamp == null:
		return

	hide_hover_piece_details()
	get_stamp_hover_preview_controller().show_stamp_only(stamp)

func get_state_stamp_expiration_events(previous_snapshot: Dictionary, recent_stamp_expirations: Array, recent_bomb_effects: Array) -> Array[Dictionary]:
	return get_match_state_sync_controller().get_state_stamp_expiration_events(previous_snapshot, recent_stamp_expirations, recent_bomb_effects, piece_objects)

func play_piece_revert_animations(animations: Array[Dictionary]) -> void:
	for animation: Dictionary in animations:
		var board_pos: Vector2 = BoardConfig.value_to_vector2(animation.get("position", INVALID_BOARD_POS), INVALID_BOARD_POS)
		var start_texture: Texture2D = animation.get("start_texture", null) as Texture2D
		play_piece_revert_animation(board_pos, start_texture)

func play_piece_revert_animation(piece_position: Vector2, start_texture: Texture2D) -> void:
	if should_skip_visual_animations() or start_texture == null or !MoveRules.is_valid_position(piece_position):
		return

	get_visual_process_tracker().begin(VISUAL_PROCESS_PIECE_REVERT)
	SFXManager.play("stamp_duration_over")
	await get_piece_effect_animator().play_piece_revert(piece_position, start_texture)
	get_visual_process_tracker().finish(VISUAL_PROCESS_PIECE_REVERT)

func get_stamp_hand_source_position(owner_color: int) -> Vector2:
	var visuals: Array[StampVisual] = get_stamp_hand_state_controller().get_stamp_visuals(owner_color)
	for stamp_visual: StampVisual in visuals:
		if stamp_visual != null and is_instance_valid(stamp_visual) and stamp_visual.visible:
			return stamp_visual.global_position

	var hand_node: Control = get_stamp_hand_state_controller().get_stamp_hand_node(owner_color)
	if hand_node == null:
		return get_viewport().get_visible_rect().size * 0.5

	return hand_node.global_position + get_stamp_hand_state_controller().get_stamp_home_position(maxi(0, visuals.size() - 1))

func _process(delta):
	get_match_input_controller().process(delta)

func _input(event):
	get_match_input_controller().handle_input(event)

## A boss fight can be started over and, from the third boss on, left; any
## other match - a warm-up, one with no story behind it, multiplayer - can only
## be left.
func show_quit_confirmation():
	if quit_confirmation_dialog == null:
		return
	var can_leave: bool = StoryManager.can_leave_active_match()
	var can_restart: bool = StoryManager.can_restart_active_match()
	quit_confirmation_dialog.get_ok_button().visible = can_leave
	quit_retry_button.visible = can_restart
	if can_leave and can_restart:
		quit_confirmation_dialog.title = tr("MATCH_MENU_LEAVE_OR_RETRY_TITLE")
		quit_confirmation_dialog.dialog_text = tr("MATCH_MENU_LEAVE_OR_RETRY_TEXT")
	elif can_restart:
		quit_confirmation_dialog.title = tr("MATCH_MENU_RETRY_TITLE")
		quit_confirmation_dialog.dialog_text = tr("MATCH_MENU_RETRY_TEXT")
	else:
		quit_confirmation_dialog.title = tr("Leave Game")
		quit_confirmation_dialog.dialog_text = tr("Do you really want to leave the game?")
	quit_confirmation_dialog.popup_centered(Vector2i(360, 140))

func _on_quit_confirmed():
	GameConfig.stop_ai_vs_ai_batch()
	if get_parent().has_method("close_game_connection"):
		get_parent().close_game_connection()
	if get_tree():
		SceneTransition.change_scene(MAIN_MENU_SCENE)

func _on_quit_dialog_action(action: StringName) -> void:
	quit_confirmation_dialog.hide()
	if action == QUIT_DIALOG_RETRY_ACTION:
		_on_retry_confirmed()

## The fight starts over: the story sets it up again from its node, so it
## comes in exactly as it did the first time.
func _on_retry_confirmed() -> void:
	if get_parent().has_method("close_game_connection"):
		get_parent().close_game_connection()
	StoryManager.restart_active_match()

func get_board_view_color() -> int:
	if side != null && !side:
		return -1
	return 1

func get_mouse_board_position() -> Vector2:
	var local_pos: Vector2 = to_local(get_global_mouse_position())
	return get_board_geometry().get_mouse_board_position(local_pos, INVALID_BOARD_POS)

func hide_hover_piece_details():
	get_match_input_controller().hide_hover_piece_details()
	clear_hover_highlighted_piece()

func get_board_position_screen_position(board_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas() * get_board_geometry().get_position_local(board_pos)

func get_piece_holder_at(board_pos: Vector2) -> Sprite2D:
	return get_piece_visuals().get_holder_at(pieces_node, board_pos, INVALID_BOARD_POS)

func collect_bomb_warning_animations(recent_bomb_effects: Array, previous_snapshot: Dictionary) -> Array[Dictionary]:
	return get_match_state_sync_controller().collect_bomb_warning_animations(recent_bomb_effects, previous_snapshot, has_received_server_state, should_skip_visual_animations())

func play_bomb_warning_animations(animations: Array[Dictionary]) -> void:
	for animation: Dictionary in animations:
		var target_pos: Vector2 = BoardConfig.value_to_vector2(animation.get("target_pos", INVALID_BOARD_POS), INVALID_BOARD_POS)
		play_bomb_warning_animation(target_pos)

func play_bomb_warning_animation(target_pos: Vector2) -> void:
	if !MoveRules.is_valid_position(target_pos):
		return
	if piece_effects_node == null or !is_instance_valid(piece_effects_node):
		create_piece_effects_node()
	if piece_effects_node == null:
		return
	get_piece_effect_animator().play_bomb_warning(target_pos)

func set_hover_highlighted_piece(board_pos: Vector2) -> void:
	if hover_highlighted_piece == board_pos:
		return
	hover_highlighted_piece = board_pos
	get_piece_display_controller().update_piece_hover_dim()

func clear_hover_highlighted_piece() -> void:
	set_hover_highlighted_piece(INVALID_BOARD_POS)

func is_empty(pos : Vector2):
	if board[pos.x][pos.y] == 0: return true
	return false

func is_piece_owned_by(pos: Vector2, owner_color: int) -> bool:
	return board[pos.x][pos.y] * owner_color > 0

func can_player_control_piece_at(pos: Vector2, player_id: int) -> bool:
	if !piece_objects.has(pos):
		return false
	var piece: Piece = piece_objects[pos] as Piece
	return StampEffectResolver.can_player_control_piece(piece, player_id)

func can_control_current_turn() -> bool:
	if game_over:
		return false
	if side == null:
		return GameConfig.is_singleplayer or tutorial_mode_active
	return side == white

func should_skip_visual_animations() -> bool:
	return GameConfig.should_skip_ai_vs_ai_delays()

func get_board_screen_scale() -> float:
	var camera: Camera2D = $"../Camera2D"
	if camera == null:
		return absf(global_scale.x)
	return absf(camera.zoom.x) * absf(global_scale.x)
