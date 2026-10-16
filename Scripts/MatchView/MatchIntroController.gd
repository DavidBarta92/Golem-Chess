extends Node
class_name MatchIntroController

## Brings a match on screen the way the comic pages do: the room draws itself,
## then the board, then the pieces, then everything else.
##
## The order is fixed and the pieces of it live apart - the room is a
## background in its own CanvasLayer, the grid belongs to the board because
## nothing else can sit between tiles and pieces, and the HUD is built at
## runtime by half a dozen controllers. This node is the only place that knows
## how they are sequenced:
##
##   1. the table's lines and the board's grid draw themselves together, while
##      the far colour (sky, window) fades in behind
##   2. when the ink has landed, the near colour fades in, and with it the
##      board - tiles, frame and the side the player looks at
##   3. the pieces arrive one at a time
##   4. the rest of the interface follows
##
## Everything is null-safe: a scene missing any of these parts still plays,
## just without that step.

@export var background_path: NodePath = NodePath("../BackgroundLayer/MatchBackground")
@export var match_board_path: NodePath = NodePath("../MatchBoard")
## Off for a scene that shows something else first and calls begin() itself -
## the tutorial opens on Grandpa's pictures before the room draws.
@export var auto_begin: bool = true

## The name `MatchBoard` gives a piece's shadow - kept in step with its
## `PIECE_SHADOW_NAME`, which cannot be referenced from here because that
## script has no class_name.
const PIECE_SHADOW_NAME: String = "PieceShadow"

@export_group("Timing")
@export_range(0.0, 5.0, 0.05) var board_fade_seconds: float = 1.5
@export_range(0.0, 1.0, 0.01) var piece_stagger_seconds: float = 0.1
@export_range(0.0, 5.0, 0.05) var piece_fade_seconds: float = 0.5
@export_range(0.0, 5.0, 0.05) var hud_fade_seconds: float = 0.8

var _background: MatchBackgroundController
var _match_board: Node2D
var _grid_overlay: BoardGridOverlay
var _has_begun: bool = false
var _lines_pending: int = 0

func _ready() -> void:
	_background = get_node_or_null(background_path) as MatchBackgroundController
	_match_board = get_node_or_null(match_board_path) as Node2D
	if _match_board != null:
		_grid_overlay = _match_board.get_node_or_null("BoardGridOverlay") as BoardGridOverlay
	_dress_the_room()
	if !auto_begin:
		return
	# The board builds its tiles and pieces over the first few frames.
	call_deferred("begin")

## Which room this match is played in, and whether the opponent has a codex on
## the table. Both come from whoever started the match - a boss carries them,
## a warm-up match leaves them at the usual kiosk - and both have to be settled
## before the room draws itself.
func _dress_the_room() -> void:
	if _background == null:
		return
	_background.variant = GameConfig.match_room_variant as MatchBackgroundController.Variant
	var codex: Node = _background.get_node_or_null("OpponentCodexSlot/Codex")
	if codex != null and codex is CanvasItem:
		(codex as CanvasItem).visible = GameConfig.match_show_opponent_codex

func begin() -> void:
	if _has_begun:
		return
	_has_begun = true

	_set_board_alpha(0.0)
	_set_pieces_alpha(0.0)
	_quench_piece_shadows()
	_set_hud_alpha(0.0)

	_lines_pending = 0
	if _background != null:
		_lines_pending += 1
		_background.line_art_finished.connect(_on_line_art_finished, CONNECT_ONE_SHOT)
		_background.begin()
	if _grid_overlay != null:
		_lines_pending += 1
		_grid_overlay.set_view_color(_get_view_color())
		_grid_overlay.reveal_finished.connect(_on_line_art_finished, CONNECT_ONE_SHOT)
		_grid_overlay.begin()

	if _lines_pending == 0:
		_on_line_art_finished()

func _on_line_art_finished() -> void:
	_lines_pending = maxi(0, _lines_pending - 1)
	if _lines_pending > 0:
		return

	# The board arrives with the table's colour, so the two read as one surface.
	_fade_in(_get_board_nodes(), board_fade_seconds, 0.0)
	await get_tree().create_timer(board_fade_seconds * 0.5).timeout
	_fade_in_staggered(_get_piece_nodes(), piece_fade_seconds, piece_stagger_seconds)
	await get_tree().create_timer(maxf(0.0, board_fade_seconds * 0.5)).timeout
	_fade_in(_get_hud_nodes(), hud_fade_seconds, 0.0)

# --- Staged by hand -----------------------------------------------------------
#
# A scene that tells its own story - the tutorial - brings the match in a part
# at a time and in its own order, between lines of dialogue, instead of
# calling begin(). It hides everything first and then asks for each part.

## Everything out of sight, nothing started. begin() will not run after this.
func hide_everything() -> void:
	_has_begun = true
	_set_board_alpha(0.0)
	_set_pieces_alpha(0.0)
	_quench_piece_shadows()
	_set_hud_alpha(0.0)

## The pieces standing on the board, as their holders.
func get_piece_nodes() -> Array[CanvasItem]:
	return _get_piece_nodes()

## One piece, shadow and all.
func reveal_piece(piece: CanvasItem, seconds: float, delay: float = 0.0) -> void:
	_fade_in([piece], seconds, delay)
	_raise_piece_shadow(piece, seconds, delay)

func reveal_pieces(pieces: Array[CanvasItem]) -> void:
	_fade_in_staggered(pieces, piece_fade_seconds, piece_stagger_seconds)

## How long reveal_pieces() takes for this many pieces.
func get_pieces_reveal_duration(piece_count: int) -> float:
	return piece_fade_seconds + maxf(0.0, piece_count - 1) * piece_stagger_seconds

## The board's grid drawing itself, with the pen scratching while it does -
## on its own there is no room drawing alongside to carry the sound.
func draw_grid(on_finished: Callable) -> void:
	if _grid_overlay == null:
		on_finished.call()
		return
	var pen: AudioStreamPlayer = SFXManager.play("mainmenu_drawing")
	_grid_overlay.set_view_color(_get_view_color())
	_grid_overlay.reveal_finished.connect(_on_grid_drawn.bind(pen, on_finished), CONNECT_ONE_SHOT)
	_grid_overlay.begin()

func _on_grid_drawn(pen: AudioStreamPlayer, on_finished: Callable) -> void:
	if pen != null and is_instance_valid(pen) and pen.playing:
		pen.stop()
	on_finished.call()

## The tiles, frame and side, fading in under the grid.
func fade_in_board() -> void:
	_fade_in(_get_board_nodes(), board_fade_seconds, 0.0)

## The codex, the hand on it, and every part of the interface that keeps
## itself out of sight until it has something to show (the hovered stamp's
## preview, the counters), all at once - for taking over from a stand-in
## codex that has been lying exactly where this one is.
func show_codex_now() -> void:
	for node in _get_hud_nodes():
		var node_name: String = String(node.name)
		if node_name == "Codex" or node_name.ends_with("_pieces") or !node.visible:
			node.modulate.a = 1.0

## Fades in whatever of the interface is still hidden, except the named nodes.
func reveal_hud(except_names: Array[String] = []) -> void:
	var nodes: Array[CanvasItem] = []
	for node in _get_hud_nodes():
		if node.modulate.a < 1.0 and !except_names.has(String(node.name)):
			nodes.append(node)
	_fade_in(nodes, hud_fade_seconds, 0.0)

## Fades in just the named parts of the interface.
func reveal_hud_nodes(names: Array[String]) -> void:
	var nodes: Array[CanvasItem] = []
	for node in _get_hud_nodes():
		if node.modulate.a < 1.0 and names.has(String(node.name)):
			nodes.append(node)
	_fade_in(nodes, hud_fade_seconds, 0.0)

## A part of the interface by name, or null.
func get_hud_node(node_name: String) -> CanvasItem:
	for node in _get_hud_nodes():
		if String(node.name) == node_name:
			return node
	return null

## The room drawing itself in. `on_finished` runs once its colour is in.
func draw_room(on_finished: Callable) -> void:
	if _background == null:
		on_finished.call()
		return
	_background.colour_finished.connect(on_finished, CONNECT_ONE_SHOT)
	_background.begin()

# --- What fades ---------------------------------------------------------------

## The board as the player sees it: the tiles, and whatever the board sprite
## itself draws (its frame and the side facing the player).
func _get_board_nodes() -> Array[CanvasItem]:
	var nodes: Array[CanvasItem] = []
	if _match_board == null:
		return nodes
	var tiles := _match_board.get_node_or_null("BoardTiles") as CanvasItem
	if tiles != null:
		nodes.append(tiles)
	return nodes

## The pieces standing on the board when the match opens. Every square owns a
## holder sprite whether or not there is a piece in it, so only the holders
## with something to show take part - otherwise the wave would spend five
## seconds staggering empty squares, and a piece played during it would arrive
## half faded.
func _get_piece_nodes() -> Array[CanvasItem]:
	var nodes: Array[CanvasItem] = []
	if _match_board == null:
		return nodes
	var pieces := _match_board.get_node_or_null("Pieces")
	if pieces == null:
		return nodes
	for child in pieces.get_children():
		var holder := child as Sprite2D
		if holder != null and holder.texture != null:
			nodes.append(holder)
	return nodes

## The interface the match builds at runtime - codex, stamp hand, portraits,
## deck counters - all of which land in the match's own CanvasLayer.
func _get_hud_nodes() -> Array[CanvasItem]:
	var nodes: Array[CanvasItem] = []
	if _match_board == null:
		return nodes
	var canvas := _match_board.get_node_or_null("../CanvasLayer")
	if canvas == null:
		return nodes
	for child in canvas.get_children():
		var item := child as CanvasItem
		if item != null:
			nodes.append(item)
	return nodes

# --- Fading -------------------------------------------------------------------

func _fade_in(nodes: Array[CanvasItem], seconds: float, delay: float) -> void:
	for node in nodes:
		if !is_instance_valid(node):
			continue
		node.modulate.a = 0.0
		var tween := node.create_tween()
		if delay > 0.0:
			tween.tween_interval(delay)
		tween.tween_property(node, "modulate:a", 1.0, seconds)

func _fade_in_staggered(nodes: Array[CanvasItem], seconds: float, stagger: float) -> void:
	for index in range(nodes.size()):
		var delay: float = index * stagger
		_fade_in([nodes[index]], seconds, delay)
		_raise_piece_shadow(nodes[index], seconds, delay)

# --- Piece shadows ------------------------------------------------------------
#
# A piece's shadow is not drawn, it is cast: a PointLight2D parented to the
# piece, throwing the piece's own occluder onto the board. A light pays no
# attention to modulate, so fading a piece in leaves its shadow burning at full
# strength from the moment the scene opens - twelve dark ovals sitting on an
# empty board. Its energy has to be taken down and brought back up by hand, in
# step with the piece it belongs to.

func _get_piece_shadow(piece: CanvasItem) -> Light2D:
	if !is_instance_valid(piece):
		return null
	return piece.get_node_or_null(NodePath(PIECE_SHADOW_NAME)) as Light2D

## Switches the shadows off without touching their energy, so the authored
## value is still there to be read when each one is brought back.
func _quench_piece_shadows() -> void:
	for piece in _get_piece_nodes():
		var shadow: Light2D = _get_piece_shadow(piece)
		if shadow != null:
			shadow.enabled = false

func _raise_piece_shadow(piece: CanvasItem, seconds: float, delay: float) -> void:
	var shadow: Light2D = _get_piece_shadow(piece)
	if shadow == null:
		return
	var target: float = shadow.energy
	shadow.energy = 0.0
	shadow.enabled = true
	var tween := shadow.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(shadow, "energy", target, seconds)

func _set_board_alpha(alpha: float) -> void:
	_set_alpha(_get_board_nodes(), alpha)

func _set_pieces_alpha(alpha: float) -> void:
	_set_alpha(_get_piece_nodes(), alpha)

func _set_hud_alpha(alpha: float) -> void:
	_set_alpha(_get_hud_nodes(), alpha)

func _set_alpha(nodes: Array[CanvasItem], alpha: float) -> void:
	for node in nodes:
		if is_instance_valid(node):
			node.modulate.a = alpha

func _get_view_color() -> int:
	if _match_board != null and _match_board.has_method("get_board_view_color"):
		return int(_match_board.get_board_view_color())
	return 1
