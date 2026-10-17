extends CanvasLayer
class_name TutorialIntro

## Grandpa's pictures, shown before anything of the tutorial's room appears.
##
## The intro is a row of beats, each started by the dialogue's Continue button
## and each holding that button back until its line is written out and its
## pictures have finished:
##
##   STAMPS    the hand (1A) and the figure (1B) draw themselves, the hand is
##             coloured, then the figure's ink gives way to its colour
##   SIGILLUM  the hand fades; the circle (2A) and the grid (2B) draw, the
##             grid is coloured
##   PENTAGON  the circle fades; the pentagon (2C) and the star (2D) draw, the
##             star is coloured
##   SEEKER    the figure hops onto the star like a piece taking a step, while
##             the pentagon closes in and cuts away everything outside it,
##             ending on the pentagon of a seeker stamp; two more stamps join
##             it, and the three behave like a codex page in a match
##   CODEX     the notebook appears under the page, with a shadow, still in
##             the middle of the screen
##   BOARD     the codex flies to where it sits in a match and loses its
##             shadow; a hand draws itself pointing at one of the player's
##             pieces, which fades in under it; then the board's grid draws,
##             the board fades in behind it, and the other pieces follow
##   INTERFACE the hand goes, the rest of the interface (all but the clock and
##             the end turn button) comes in, and the words pass to the
##             tutorial's steps (`finished`); once the first step's line is
##             written out the room draws itself, and the intro frees itself
##
## Grandpa speaks through the tutorial's own dialogue panel, handed in by
## play(), so the steps carry on in the same box without a seam. No face: the
## tutorial shows his name and words only.
##
## The figure's colour stays on top of every drawing throughout. Its colour is
## a plain TextureRect rather than its panel's own fill because a comic panel
## always keeps its ink on top; here the ink has to give way to the colour.
##
## The codex is built from the match's own parts - the stamp visuals, the
## codex script that lifts the page under the mouse, and the side panel that
## shows a hovered stamp - so it behaves exactly like the real one. Once it has
## landed where the match's codex sits it hands over to that one, which by
## then holds the same page.
##
## From BOARD on the match itself comes in, a part at a time, through the
## MatchIntroController's staging calls.

signal finished

enum Beat { STAMPS, SIGILLUM, PENTAGON, SEEKER, CODEX, BOARD, INTERFACE }

const STAMP_VISUAL_SCENE = preload("res://Scenes/StampVisual.tscn")
const MATCH_BOARD_SCRIPT = preload("res://Scenes/MatchBoard.gd")
const MATCH_STAMP_HUD_SCRIPT = preload("res://Scripts/MatchView/MatchStampHud.gd")
const STAMP_HOVER_PREVIEW_SCRIPT = preload("res://Scripts/MatchView/StampHoverPreviewController.gd")

## The canvas every tutorial picture is painted on. The pictures are full-size
## canvases with the artwork already in place, scaled to fit the screen.
const ART_SIZE: Vector2 = Vector2(1920.0, 1080.0)
## The corners of the pentagon in tutorial_2C_line.png, on that canvas.
const ART_PENTAGON: Array[Vector2] = [
	Vector2(975.0, 160.0),
	Vector2(1291.0, 386.0),
	Vector2(1174.0, 754.0),
	Vector2(788.0, 752.0),
	Vector2(666.0, 380.0),
]
## The corners of the pentagon in Assets/seeker_frame.svg, in a stamp's own
## pixels (the frame is stretched over the whole 168.7 x 229 stamp).
const STAMP_PENTAGON: Array[Vector2] = [
	Vector2(84.51, 25.84),
	Vector2(157.21, 78.56),
	Vector2(129.52, 164.31),
	Vector2(39.51, 164.31),
	Vector2(11.82, 78.56),
]
## The tip of the pointing finger in tutorial_3_line.png, on the 1920x1080
## canvas.
const ART_FINGERTIP: Vector2 = Vector2(854.5, 792.0)
## Taken from the picture the hand was placed by: there a board tile measured
## 70 x 66 pixels, the hand was drawn at 0.75 of the artwork's own size, and
## the fingertip sat 15.5 pixels left of and 12 above the middle of the
## piece's tile. Everything is scaled from the tile, so the hand fits the
## piece whatever size the board comes out at.
const POINTER_REFERENCE_TILE_SIZE: Vector2 = Vector2(70.0, 66.0)
const POINTER_REFERENCE_SCALE: float = 0.75
const POINTER_REFERENCE_FINGERTIP_OFFSET: Vector2 = Vector2(-15.5, -12.0)
## Parts of the interface the steps bring in later, if at all.
const HUD_HELD_BACK: Array[String] = ["EndTurnTab", "ChessClock"]
const INVALID_BOARD_POS: Vector2 = Vector2(-1, -1)

@export var line_keys: Array[String] = [
	"TUTORIAL_INTRO_1",
	"TUTORIAL_INTRO_2",
	"TUTORIAL_INTRO_3",
	"TUTORIAL_INTRO_4",
	"TUTORIAL_INTRO_5",
	"TUTORIAL_INTRO_6",
]
## The codex page the pentagon turns into. The seeker the pentagon lands on
## is the one at seeker_stamp_index; the others join it afterwards.
@export var codex_stamp_names: Array[String] = ["Knight", "Silver General", "Warlord"]
@export var seeker_stamp_index: int = 1
## Where the codex sits in the match, so the page lands exactly there.
@export var match_codex_path: NodePath = NodePath("../CanvasLayer/Codex")

@export_group("Timing")
@export_range(0.0, 5.0, 0.05) var figure_crossfade_seconds: float = 1.5
## How long the previous beat's drawings take to fade when the next one starts.
@export_range(0.0, 5.0, 0.05) var art_fade_out_seconds: float = 1.0

@export_group("Figure hop")
## In pixels of the 1920x1080 artwork. The figure first lifts, then comes
## down until its foot touches the top quarter of the star, then drops onto it.
@export var hop_rise_pixels: float = 18.0
@export var hop_touch_pixels: float = 54.0
@export var hop_land_pixels: float = 87.0
@export_range(0.0, 2.0, 0.01) var hop_rise_seconds: float = 0.22
@export_range(0.0, 2.0, 0.01) var hop_fall_seconds: float = 0.32
@export_range(0.0, 1.0, 0.01) var hop_land_seconds: float = 0.07

@export_group("Pentagon")
@export_range(0.5, 10.0, 0.05) var shrink_seconds: float = 3.5
## Above 1 the pentagon starts slowly and gathers speed; 3 is a cubic ease-in.
@export_range(1.0, 6.0, 0.1) var shrink_ease_power: float = 3.0
## The last stretch of the shrink, in which what is left inside the pentagon
## fades and the stamp appears behind it.
@export_range(0.0, 5.0, 0.05) var final_fade_seconds: float = 1.0
## The drawn pentagon is gone by the time it lands on the stamp.
@export_range(0.0, 5.0, 0.05) var pentagon_fade_seconds: float = 0.6
@export_range(0.0, 5.0, 0.05) var side_stamps_delay: float = 0.25
@export_range(0.0, 5.0, 0.05) var side_stamps_fade_seconds: float = 0.5

@export_group("Codex")
@export_range(0.0, 5.0, 0.05) var codex_fly_seconds: float = 0.9
@export_range(0.0, 5.0, 0.05) var codex_reveal_seconds: float = 0.8
## Where the notebook's shadow falls, in screen pixels.
@export var codex_shadow_offset: Vector2 = Vector2(8.0, 9.0)
@export_range(0.0, 5.0, 0.05) var codex_shadow_fade_seconds: float = 0.6

@export_group("Board")
## Which of the player's pieces the hand points at: the row nearest the
## player, counted from the left, starting at 0.
@export var pointer_piece_index: int = 2

@onready var _root: Control = $Root
@onready var _codex_holder: Control = $Root/CodexHolder
## Untyped: it carries the match codex script (lifting, swaying), whose
## members a TextureRect type would hide.
@onready var _codex_art = $Root/CodexHolder/CodexArt
@onready var _codex_hand: Control = $Root/CodexHolder/CodexHand
@onready var _codex_shadow: TextureRect = $Root/CodexHolder/CodexArt/Shadow
@onready var _pointer_panel: ComicPanelView = $Root/PointerPanel
@onready var _art_clip: PolygonClip = $Root/ArtClip
@onready var _hand_panel: ComicPanelView = $Root/ArtClip/HandPanel
@onready var _circle_panel: ComicPanelView = $Root/ArtClip/CirclePanel
@onready var _grid_panel: ComicPanelView = $Root/ArtClip/GridPanel
@onready var _star_panel: ComicPanelView = $Root/ArtClip/StarPanel
@onready var _figure_color: TextureRect = $Root/ArtClip/FigureColor
@onready var _figure_panel: ComicPanelView = $Root/ArtClip/FigurePanel
@onready var _pentagon_panel: ComicPanelView = $Root/PentagonPanel

var _beat: Beat = Beat.STAMPS
var _speaker_name: String = ""
var _dialogue: DialoguePanel
var _is_finishing: bool = false

## Continue is held back until a beat's pieces have all reported in; a gate
## counts them down. The id keeps a late report from an earlier beat from
## opening the current one.
var _gate_id: int = 0
var _gate_pending: int = 0
var _gate_callback: Callable

var _stamp_hud
var _hover
var _codex_stamps: Array[StampVisual] = []
var _codex_centre_offset: Vector2 = Vector2.ZERO
## True while the page sits in the middle of the screen, before it flies home.
var _codex_centred: bool = false
var _figure_rest_y: float = 0.0
var _board
var _match_intro: MatchIntroController
var _pointer_piece: CanvasItem

func _ready() -> void:
	_figure_color.modulate.a = 0.0
	_figure_panel.fade_out_seconds = figure_crossfade_seconds
	_art_clip.set_clip_enabled(false)
	_codex_shadow.modulate.a = 0.0
	# The hand lies on the board, so it is printed on the room's paper like
	# everything else there; its ink is not touched by modulate either way.
	_pointer_panel.modulate = MatchBackgroundController.PAPER_TINT

## Starts the first beat. Returns immediately; listen to `finished`. The board
## and the match intro are what the later beats bring in; both must already be
## hidden (MatchIntroController.hide_everything()). `dialogue` is the panel the
## tutorial's steps use, which Grandpa talks through from his first line.
func play(speaker_name: String, board, match_intro: MatchIntroController, dialogue: DialoguePanel) -> void:
	_speaker_name = speaker_name
	_board = board
	_match_intro = match_intro
	_dialogue = dialogue
	# Hidden with the rest of the interface; the words come first.
	_match_intro.show_hud_node_now(_dialogue)
	_dialogue.continue_requested.connect(_on_continue_requested)
	_build_codex()
	get_viewport().size_changed.connect(_on_viewport_resized)

	_beat = Beat.STAMPS
	var gate: int = _open_gate(2, _crossfade_figure)
	_report_to_gate(_dialogue.line_finished, gate)
	_report_to_gate(_hand_panel.reveal_finished, gate)
	_hand_panel.reveal()
	_figure_panel.reveal()
	_say(0)

func _on_continue_requested() -> void:
	if _is_finishing:
		return
	_dialogue.set_continue_allowed(false)
	match _beat:
		Beat.STAMPS:
			_play_sigillum()
		Beat.SIGILLUM:
			_play_pentagon()
		Beat.PENTAGON:
			_play_seeker()
		Beat.SEEKER:
			_play_codex()
		Beat.CODEX:
			_play_board()
		Beat.BOARD:
			_play_interface()

# --- Beats --------------------------------------------------------------------

## Once the line is written out and the hand is coloured, the figure's ink
## fades away while its colour fades in in its place.
func _crossfade_figure() -> void:
	# The figure's own ink may still be landing if its strokes run longer.
	_figure_panel.finish_reveal_now()
	_figure_panel.fade_out()
	var tween := create_tween()
	tween.tween_property(_figure_color, "modulate:a", 1.0, maxf(0.05, figure_crossfade_seconds))
	tween.tween_callback(_allow_continue)

func _play_sigillum() -> void:
	_beat = Beat.SIGILLUM
	_fade_away(_hand_panel)
	var gate: int = _open_gate(2, _allow_continue)
	_report_to_gate(_dialogue.line_finished, gate)
	# The grid reports in once its colour has faded in under the ink.
	_report_to_gate(_grid_panel.reveal_finished, gate)
	_circle_panel.reveal()
	_grid_panel.reveal()
	_say(1)

func _play_pentagon() -> void:
	_beat = Beat.PENTAGON
	_fade_away(_circle_panel)
	var gate: int = _open_gate(2, _allow_continue)
	_report_to_gate(_dialogue.line_finished, gate)
	_report_to_gate(_star_panel.reveal_finished, gate)
	_pentagon_panel.reveal()
	_star_panel.reveal()
	_say(2)

func _play_seeker() -> void:
	_beat = Beat.SEEKER
	_hop_figure()
	_shrink_pentagon()

## The notebook appears under the page where it is, in the middle of the
## screen, and casts a shadow.
func _play_codex() -> void:
	_beat = Beat.CODEX
	var gate: int = _open_gate(2, _allow_continue)
	_report_to_gate(_dialogue.line_finished, gate)
	var tween := create_tween()
	tween.tween_property(_codex_art, "self_modulate:a", 1.0, maxf(0.05, codex_reveal_seconds))
	tween.parallel().tween_property(_codex_shadow, "modulate:a", 1.0, maxf(0.05, codex_reveal_seconds))
	tween.tween_callback(_gate_step.bind(gate))
	_say(4)

## The codex goes home, and the board starts to come in.
func _play_board() -> void:
	_beat = Beat.BOARD
	if _hover != null:
		_hover.hide()
	_set_codex_interactive(false)
	var gate: int = _open_gate(2, _allow_continue)
	_report_to_gate(_dialogue.line_finished, gate)
	_codex_centred = false
	var tween := create_tween()
	tween.tween_property(_codex_holder, "position", Vector2.ZERO, maxf(0.05, codex_fly_seconds)) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_on_codex_landed.bind(gate))
	_say(5)

## Home: the shadow fades and the hand starts to draw, at the same moment.
func _on_codex_landed(gate: int) -> void:
	var tween := create_tween()
	tween.tween_property(_codex_shadow, "modulate:a", 0.0, maxf(0.05, codex_shadow_fade_seconds))
	tween.tween_callback(_hand_over_codex)
	_point_at_piece(gate)

## The stand-in has been lying exactly on the match's codex, which holds the
## same page; swapping the two is invisible, and from here on the stamps are
## the match's own.
func _hand_over_codex() -> void:
	_codex_holder.visible = false
	if _match_intro != null:
		_match_intro.show_codex_now()

## The hand draws itself pointing at one of the player's pieces; its colour
## comes in a moment after the ink starts, and the piece fades in with it.
func _point_at_piece(gate: int) -> void:
	var target: Vector2 = _find_pointer_target()
	if target == INVALID_BOARD_POS or _match_intro == null:
		_on_pointer_drawn(gate)
		return
	_place_pointer(target)
	_pointer_piece = _board.get_piece_holder_at(target)
	var ink_seconds: float = _pointer_panel.base_duration + _pointer_panel.max_delay
	var colour_delay: float = _pointer_panel.delay_before + ink_seconds * _pointer_panel.fill_fade_start_ratio
	if _pointer_piece != null:
		_match_intro.reveal_piece(_pointer_piece, _pointer_panel.fill_fade_duration, colour_delay)
		# Set down under the hand: the sound a piece makes landing on its
		# square at the end of a move.
		var placed := create_tween()
		placed.tween_interval(colour_delay)
		placed.tween_callback(SFXManager.play.bind("piece_placed"))
	_pointer_panel.reveal_finished.connect(_on_pointer_drawn.bind(gate), CONNECT_ONE_SHOT)
	_pointer_panel.reveal()

func _on_pointer_drawn(gate: int) -> void:
	if _match_intro == null:
		_gate_step(gate)
		return
	_match_intro.draw_grid(_on_grid_drawn.bind(gate))

## The board fades in behind the fresh grid, then the other pieces arrive.
func _on_grid_drawn(gate: int) -> void:
	_match_intro.fade_in_board()
	var others: Array[CanvasItem] = []
	for piece in _match_intro.get_piece_nodes():
		if piece != _pointer_piece:
			others.append(piece)
	var board_half: float = _match_intro.board_fade_seconds * 0.5
	var tween := create_tween()
	tween.tween_interval(board_half)
	tween.tween_callback(_match_intro.reveal_pieces.bind(others))
	tween.tween_interval(maxf(board_half, _match_intro.get_pieces_reveal_duration(others.size())))
	tween.tween_callback(_gate_step.bind(gate))

## The hand goes and the interface comes in, and the words pass to the
## tutorial's steps: the first step's line is Grandpa's next one. Once it is
## written out the room draws itself, and the intro's work is done.
func _play_interface() -> void:
	_beat = Beat.INTERFACE
	_is_finishing = true
	_fade_away(_pointer_panel)
	if _match_intro != null:
		_match_intro.reveal_hud(HUD_HELD_BACK)
	_dialogue.continue_requested.disconnect(_on_continue_requested)
	_dialogue.line_finished.connect(_on_handover_line_typed, CONNECT_ONE_SHOT)
	finished.emit()

func _on_handover_line_typed() -> void:
	if _match_intro == null:
		queue_free()
		return
	_match_intro.draw_room(queue_free)

# --- The figure's step --------------------------------------------------------

## The way a piece steps from one square to the next: a small lift, down onto
## the edge of the star, then a sudden drop as it settles.
func _hop_figure() -> void:
	var scale_factor: float = _art_scale()
	_figure_rest_y = _figure_color.position.y
	SFXManager.play("piece_lifted")
	var tween := create_tween()
	tween.tween_property(_figure_color, "position:y", _figure_rest_y - hop_rise_pixels * scale_factor, hop_rise_seconds) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_figure_color, "position:y", _figure_rest_y + hop_touch_pixels * scale_factor, hop_fall_seconds) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_figure_color, "position:y", _figure_rest_y + hop_land_pixels * scale_factor, hop_land_seconds) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(SFXManager.play.bind("piece_placed"))

# --- The pentagon closing in --------------------------------------------------

func _shrink_pentagon() -> void:
	_pentagon_panel.pivot_offset = _art_to_local(_get_centre(ART_PENTAGON))
	_apply_shrink(0.0)
	_art_clip.set_clip_enabled(true)

	var shrink := create_tween()
	shrink.tween_method(_apply_shrink, 0.0, 1.0, shrink_seconds)
	shrink.tween_callback(_on_shrink_finished)

	var fades := create_tween()
	fades.tween_interval(maxf(0.0, shrink_seconds - final_fade_seconds))
	fades.tween_callback(_start_final_fades)

	_pentagon_panel.fade_out_seconds = pentagon_fade_seconds
	var pentagon_fade := create_tween()
	pentagon_fade.tween_interval(maxf(0.0, shrink_seconds - pentagon_fade_seconds))
	pentagon_fade.tween_callback(_pentagon_panel.fade_out)

## Moves the drawn pentagon and the mask together, from where the drawing
## sits to the pentagon on the seeker stamp. Worked out afresh every frame, so
## the pentagon follows the codex page if it sways.
func _apply_shrink(progress: float) -> void:
	var eased: float = pow(clampf(progress, 0.0, 1.0), shrink_ease_power)
	var start_centre: Vector2 = _art_to_local(_get_centre(ART_PENTAGON))
	var start_width: float = _get_width(ART_PENTAGON) * _art_scale()

	var stamp: StampVisual = _get_seeker_stamp()
	var target_centre: Vector2 = start_centre
	var target_scale: float = 1.0
	if stamp != null:
		var to_clip: Transform2D = _art_clip.get_global_transform().affine_inverse() * stamp.get_global_transform()
		target_centre = to_clip * _get_centre(STAMP_PENTAGON)
		target_scale = _get_width(STAMP_PENTAGON) * to_clip.get_scale().x / maxf(1.0, start_width)

	var pentagon_scale: float = lerpf(1.0, target_scale, eased)
	var centre: Vector2 = start_centre.lerp(target_centre, eased)
	_pentagon_panel.scale = Vector2.ONE * pentagon_scale
	_pentagon_panel.position = centre - start_centre

	var mask := PackedVector2Array()
	for corner in ART_PENTAGON:
		mask.append(centre + (_art_to_local(corner) - start_centre) * pentagon_scale)
	_art_clip.polygon = mask

## The last second: what is still inside the pentagon fades, and the stamp
## appears behind it.
func _start_final_fades() -> void:
	for child in _art_clip.get_children():
		if child is ComicPanelView:
			var panel := child as ComicPanelView
			panel.fade_out_seconds = final_fade_seconds
			panel.fade_out()
		elif child is CanvasItem:
			create_tween().tween_property(child, "modulate:a", 0.0, maxf(0.05, final_fade_seconds))

	var stamp: StampVisual = _get_seeker_stamp()
	if stamp != null:
		create_tween().tween_property(stamp, "modulate:a", 1.0, maxf(0.05, final_fade_seconds))

func _on_shrink_finished() -> void:
	_art_clip.set_clip_enabled(false)
	_art_clip.visible = false
	_pentagon_panel.finish_fade_out_now()

	var stamp: StampVisual = _get_seeker_stamp()
	if stamp != null:
		stamp.modulate.a = 1.0

	var tween := create_tween()
	tween.tween_interval(side_stamps_delay)
	var has_side_stamps: bool = false
	for index in range(_codex_stamps.size()):
		if index == seeker_stamp_index:
			continue
		var side_stamp: StampVisual = _codex_stamps[index]
		if has_side_stamps:
			tween.parallel()
		tween.tween_property(side_stamp, "modulate:a", 1.0, maxf(0.05, side_stamps_fade_seconds))
		has_side_stamps = true
	tween.tween_callback(_on_codex_page_shown)

func _on_codex_page_shown() -> void:
	_set_codex_interactive(true)
	var gate: int = _open_gate(1, _allow_continue)
	_report_to_gate(_dialogue.line_finished, gate)
	_say(3)

# --- The pointing hand --------------------------------------------------------

## The piece the hand points at: in the row nearest the player, the one at
## pointer_piece_index counted from the left. Worked out from where the pieces
## land on screen, so it holds whichever side the board is seen from.
func _find_pointer_target() -> Vector2:
	if _board == null:
		return INVALID_BOARD_POS
	var positions: Array = _board.piece_objects.keys()
	if positions.is_empty():
		return INVALID_BOARD_POS
	var near_y: float = -INF
	for pos in positions:
		near_y = maxf(near_y, _screen_position(pos).y)
	var row: Array = positions.filter(func(pos): return absf(_screen_position(pos).y - near_y) < 2.0)
	row.sort_custom(func(a, b): return _screen_position(a).x < _screen_position(b).x)
	return row[clampi(pointer_piece_index, 0, row.size() - 1)]

func _screen_position(board_pos: Vector2) -> Vector2:
	return _board.get_board_position_screen_position(board_pos)

## Sizes and places the hand from the piece's tile, the way it sat in the
## reference picture.
func _place_pointer(board_pos: Vector2) -> void:
	var to_screen: Transform2D = _board.get_global_transform_with_canvas()
	var cell_points: PackedVector2Array = _board.get_board_cell_polygon_local(board_pos)
	var cell := Rect2(to_screen * cell_points[0], Vector2.ZERO)
	for point in cell_points:
		cell = cell.expand(to_screen * point)
	var to_root: Transform2D = _root.get_global_transform().affine_inverse()
	var hand_scale: float = POINTER_REFERENCE_SCALE * cell.size.x / POINTER_REFERENCE_TILE_SIZE.x
	var fingertip: Vector2 = to_root * (cell.get_center() + POINTER_REFERENCE_FINGERTIP_OFFSET / POINTER_REFERENCE_TILE_SIZE * cell.size)
	_pointer_panel.pivot_offset = Vector2.ZERO
	_pointer_panel.scale = Vector2.ONE * hand_scale
	_pointer_panel.position = fingertip - ART_FINGERTIP * hand_scale

# --- The codex ----------------------------------------------------------------

## Lays the page out the way the match does, then moves the whole codex so the
## page sits in the middle of the screen with the notebook hidden. Everything
## starts invisible; the seeker appears as the pentagon lands on it.
func _build_codex() -> void:
	_match_codex_layout()

	_stamp_hud = MATCH_STAMP_HUD_SCRIPT.new()
	_stamp_hud.configure({
		"stamp_visual_scene": STAMP_VISUAL_SCENE,
		"stamp_ui_size": MATCH_BOARD_SCRIPT.STAMP_UI_SIZE,
		"player_hand_size": MATCH_BOARD_SCRIPT.PLAYER_HAND_SIZE,
		"stamp_hand_scale": MATCH_BOARD_SCRIPT.STAMP_HAND_SCALE,
		"stamp_ui_gap": MATCH_BOARD_SCRIPT.STAMP_UI_GAP,
		"bottom_stamp_hand_margin": MATCH_BOARD_SCRIPT.BOTTOM_STAMP_HAND_MARGIN,
	})
	_stamp_hud.configure_hand_container(_codex_hand, false)
	_stamp_hud.align_hand_container_to_codex(_codex_hand, _codex_art)

	var stamps: Array[Stamp] = []
	for stamp_name in codex_stamp_names:
		var stamp: Stamp = StampLibrary.duplicate_stamp(stamp_name)
		if stamp != null:
			stamps.append(stamp)
	_codex_stamps = _stamp_hud.populate_stamp_hand(_codex_hand, stamps, 1, Callable(self, "_connect_codex_stamp"))
	_codex_art.set_hand_follower(_codex_hand)

	_codex_art.self_modulate.a = 0.0
	_codex_shadow.texture = _codex_art.texture
	_codex_shadow.offset_left = codex_shadow_offset.x
	_codex_shadow.offset_right = codex_shadow_offset.x
	_codex_shadow.offset_top = codex_shadow_offset.y
	_codex_shadow.offset_bottom = codex_shadow_offset.y
	for stamp_visual in _codex_stamps:
		stamp_visual.draggable = false
		stamp_visual.modulate.a = 0.0
	_set_codex_interactive(false)

	_hover = STAMP_HOVER_PREVIEW_SCRIPT.new()
	_hover.configure({
		"canvas_layer": self,
		"stamp_visual_scene": STAMP_VISUAL_SCENE,
		"stamp_ui_size": MATCH_BOARD_SCRIPT.STAMP_UI_SIZE,
		"hover_stamp_margin": MATCH_BOARD_SCRIPT.HOVER_STAMP_MARGIN,
		"hover_stamp_extra_left_offset": MATCH_BOARD_SCRIPT.HOVER_STAMP_EXTRA_LEFT_OFFSET,
		"hover_stamp_preview_scale": MATCH_BOARD_SCRIPT.HOVER_STAMP_PREVIEW_SCALE,
		"hover_stamp_vertical_offset": MATCH_BOARD_SCRIPT.HOVER_STAMP_VERTICAL_OFFSET,
		"hover_stamp_rotation_degrees": MATCH_BOARD_SCRIPT.HOVER_STAMP_ROTATION_DEGREES,
		"hover_piece_preview_size": MATCH_BOARD_SCRIPT.HOVER_PIECE_PREVIEW_SIZE,
		"hover_piece_preview_vertical_offset": MATCH_BOARD_SCRIPT.HOVER_PIECE_PREVIEW_VERTICAL_OFFSET,
		"description_text_margin": MATCH_BOARD_SCRIPT.HOVER_DESCRIPTION_TEXT_MARGIN,
		"description_panel_gap": MATCH_BOARD_SCRIPT.HOVER_DESCRIPTION_PANEL_GAP,
		"description_panel_width": MATCH_BOARD_SCRIPT.HOVER_DESCRIPTION_PANEL_WIDTH,
		"description_panel_height": MATCH_BOARD_SCRIPT.HOVER_DESCRIPTION_PANEL_HEIGHT,
		"duration_shadow_color": MATCH_BOARD_SCRIPT.HOVER_DURATION_SHADOW_COLOR,
		"duration_shadow_blur": MATCH_BOARD_SCRIPT.HOVER_DURATION_SHADOW_BLUR,
		"duration_outline_size": MATCH_BOARD_SCRIPT.HOVER_DURATION_OUTLINE_SIZE,
	})
	_hover.create_ui()

	_centre_codex()

## Copies where the match's codex sits, so the page lands on it exactly. The
## scene carries the same values; this only matters if they drift apart.
func _match_codex_layout() -> void:
	var reference := get_node_or_null(match_codex_path) as Control
	if reference != null:
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			_codex_art.set_anchor(side, reference.get_anchor(side))
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			_codex_art.set_offset(side, reference.get_offset(side))
		if reference is TextureRect:
			_codex_art.texture = (reference as TextureRect).texture
	_codex_art.base_offset = Vector2(_codex_art.offset_left, _codex_art.offset_top)
	_codex_art.pivot_offset = Vector2(_codex_art.size.x * 0.5, 0.0)
	_codex_art.capture_rest_position()

## Moves the whole codex so its page is centred on the screen. Flying it home
## later is just this offset going back to zero.
func _centre_codex() -> void:
	if _codex_stamps.is_empty():
		return
	var bounds: Rect2 = _codex_stamps[0].get_global_rect()
	for stamp_visual in _codex_stamps:
		bounds = bounds.merge(stamp_visual.get_global_rect())
	_codex_centre_offset = _root.get_global_rect().get_center() - bounds.get_center()
	_codex_holder.position = _codex_centre_offset
	_codex_centred = true

func _on_viewport_resized() -> void:
	# Once the containers have taken the new size.
	call_deferred("_relayout_codex")

## The page is laid out against the screen once, in _build_codex(). When the
## window changes size afterwards - the editor's embedded game view does, as
## it opens - the notebook finds its new resting place by itself but the page
## would stay where it was, and the two come apart. So both are laid out
## again from scratch, and centred again if the page is still waiting in the
## middle.
func _relayout_codex() -> void:
	if _stamp_hud == null or _codex_stamps.is_empty() or !_codex_holder.visible:
		return
	_codex_holder.position = Vector2.ZERO
	_codex_art.capture_rest_position()
	_stamp_hud.configure_hand_container(_codex_hand, false)
	_stamp_hud.align_hand_container_to_codex(_codex_hand, _codex_art)
	# The codex reads where the page rests only when it is handed a new one.
	_codex_art.set_hand_follower(null)
	_codex_art.set_hand_follower(_codex_hand)
	if _codex_centred:
		_centre_codex()

func _connect_codex_stamp(stamp_visual: StampVisual) -> void:
	stamp_visual.mouse_entered.connect(_on_codex_stamp_entered.bind(stamp_visual))
	stamp_visual.mouse_exited.connect(_on_codex_stamp_exited)

func _on_codex_stamp_entered(stamp_visual: StampVisual) -> void:
	if _hover == null or stamp_visual == null or stamp_visual.stamp == null:
		return
	_hover.show_stamp_only(stamp_visual.stamp)

func _on_codex_stamp_exited() -> void:
	if _hover != null:
		_hover.hide()

## Off while the page is still being formed: the stamps ignore the mouse and
## the codex does not lift, so nothing moves the seeker the pentagon is
## aiming for.
func _set_codex_interactive(enabled: bool) -> void:
	for stamp_visual in _codex_stamps:
		stamp_visual.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	_codex_art.set_process(enabled)

func _get_seeker_stamp() -> StampVisual:
	if seeker_stamp_index < 0 or seeker_stamp_index >= _codex_stamps.size():
		return null
	return _codex_stamps[seeker_stamp_index]

# --- Helpers ------------------------------------------------------------------

func _say(line_index: int) -> void:
	var key: String = line_keys[line_index] if line_index < line_keys.size() else ""
	_dialogue.show_line(_speaker_name, tr(key), null, false)

func _allow_continue() -> void:
	_dialogue.set_continue_allowed(true)

func _fade_away(panel: ComicPanelView) -> void:
	panel.fade_out_seconds = art_fade_out_seconds
	panel.finish_reveal_now()
	panel.fade_out()

func _open_gate(count: int, on_open: Callable) -> int:
	_gate_id += 1
	_gate_pending = count
	_gate_callback = on_open
	if count <= 0:
		on_open.call()
	return _gate_id

## One report towards a gate, when `source` next fires. A lambda rather than
## _gate_step bound to the gate: Godot takes a method bound to different
## arguments for the same connection, so a report still waiting on the same
## signal from an earlier gate would make this one fail to connect.
func _report_to_gate(source: Signal, gate_id: int) -> void:
	source.connect(func() -> void: _gate_step(gate_id), CONNECT_ONE_SHOT)

func _gate_step(gate_id: int) -> void:
	if gate_id != _gate_id or _gate_pending <= 0:
		return
	_gate_pending -= 1
	if _gate_pending == 0:
		_gate_callback.call()

## How much the artwork is scaled to fit the screen, the way the pictures'
## TextureRects do it (keep aspect, centred).
func _art_scale() -> float:
	var area: Vector2 = _root.size
	return minf(area.x / ART_SIZE.x, area.y / ART_SIZE.y)

func _art_to_local(point: Vector2) -> Vector2:
	var scale_factor: float = _art_scale()
	return (_root.size - ART_SIZE * scale_factor) * 0.5 + point * scale_factor

func _get_centre(points: Array[Vector2]) -> Vector2:
	return _get_bounds(points).get_center()

func _get_width(points: Array[Vector2]) -> float:
	return _get_bounds(points).size.x

func _get_bounds(points: Array[Vector2]) -> Rect2:
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	return bounds
