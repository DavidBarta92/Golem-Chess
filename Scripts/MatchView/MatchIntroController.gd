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
## A single-player match the player can bring any of several codexes to opens
## on that choice instead (DeckChoicePanel). Only the table's lines draw at
## first, with the far colour behind them; then the choice fades in on the
## empty table and the match waits on it. Once it is settled the choice goes,
## the grid draws, the near colour and the board fade in, and the pieces and
## the interface follow as above. The game itself is only set up at that
## point (deck_chosen), so it deals from the codex that was picked.
##
## Everything is null-safe: a scene missing any of these parts still plays,
## just without that step.

## The codex choice is settled; the game can be set up.
signal deck_chosen
## The interface has started to come in - the first moment anything said in
## the opponent's panel can be seen.
signal interface_revealed

@export var background_path: NodePath = NodePath("../BackgroundLayer/MatchBackground")
@export var match_board_path: NodePath = NodePath("../MatchBoard")
## Off for a scene that shows something else first and calls begin() itself -
## the tutorial opens on Grandpa's pictures before the room draws.
@export var auto_begin: bool = true

## The name `MatchBoard` gives a piece's shadow - kept in step with its
## `PIECE_SHADOW_NAME`, which cannot be referenced from here because that
## script has no class_name.
const PIECE_SHADOW_NAME: String = "PieceShadow"
const DECK_CHOICE_PANEL_SCRIPT = preload("res://Scripts/MatchView/DeckChoicePanel.gd")

@export_group("Timing")
@export_range(0.0, 5.0, 0.05) var board_fade_seconds: float = 1.5
@export_range(0.0, 1.0, 0.01) var piece_stagger_seconds: float = 0.1
@export_range(0.0, 5.0, 0.05) var piece_fade_seconds: float = 0.5
@export_range(0.0, 5.0, 0.05) var hud_fade_seconds: float = 0.8
## The codex choice comes in at the same pace as the room's colours and goes
## a little quicker, so the grid is not kept waiting.
@export_range(0.0, 5.0, 0.05) var deck_choice_fade_in_seconds: float = 1.5
@export_range(0.0, 5.0, 0.05) var deck_choice_fade_out_seconds: float = 0.8

var _background: MatchBackgroundController
var _match_board: Node2D
var _grid_overlay: BoardGridOverlay
var _has_begun: bool = false
var _lines_pending: int = 0
var _offers_deck_choice: bool = false
var _deck_choice: VBoxContainer
var _interface_revealed: bool = false

func _ready() -> void:
	_background = get_node_or_null(background_path) as MatchBackgroundController
	_match_board = get_node_or_null(match_board_path) as Node2D
	if _match_board != null:
		_grid_overlay = _match_board.get_node_or_null("BoardGridOverlay") as BoardGridOverlay
	_dress_the_room()
	_hold_pieces_back()
	if !auto_begin:
		return
	_offers_deck_choice = _should_offer_deck_choice()
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
		_background.hold_near_colour = _offers_deck_choice
		_background.line_art_finished.connect(_on_line_art_finished, CONNECT_ONE_SHOT)
		_background.begin()
	# With a codex to choose, the grid waits until it is chosen.
	if _grid_overlay != null and !_offers_deck_choice:
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
	if _offers_deck_choice:
		_show_deck_choice()
		return
	_bring_in_board()

## The board with the table's colour, so the two read as one surface; the
## pieces from half way through that, and the interface once it is done.
func _bring_in_board() -> void:
	_fade_in(_get_board_nodes(), board_fade_seconds, 0.0)
	await get_tree().create_timer(board_fade_seconds * 0.5).timeout
	_fade_in_staggered(_get_piece_nodes(), piece_fade_seconds, piece_stagger_seconds)
	await get_tree().create_timer(maxf(0.0, board_fade_seconds * 0.5)).timeout
	_fade_in(_get_hud_nodes(), hud_fade_seconds, 0.0)
	_interface_revealed = true
	interface_revealed.emit()

## True while the match waits on the player's codex - the scene's own start
## (Multiplayer) holds the game back until deck_chosen.
func is_offering_deck_choice() -> bool:
	return _offers_deck_choice

func is_interface_revealed() -> bool:
	return _interface_revealed

# --- The codex choice ---------------------------------------------------------

## Offered in a single-player match against the computer when the player can
## bring a codex of their own and has more than one to bring. Not when the
## story lends or forces one, not in multiplayer (the codex went to the server
## with the player), and not in the tutorial, which never calls begin().
func _should_offer_deck_choice() -> bool:
	if !GameConfig.is_singleplayer or GameConfig.is_ai_vs_ai_batch or GameConfig.is_dedicated_server:
		return false
	if !GameConfig.player_controllers.values().has(GameConfig.CONTROLLER_HUMAN):
		return false
	if GameConfig.has_player_deck_override():
		return false
	var boss_node: BossGameStoryNode = StoryManager.get_active_boss_node()
	if boss_node != null and !boss_node.force_player_deck_id.strip_edges().is_empty():
		return false
	return DECK_CHOICE_PANEL_SCRIPT.has_choice()

## The choice on the empty table, in a layer of its own so the interface's
## fades leave it alone.
func _show_deck_choice() -> void:
	var layer := CanvasLayer.new()
	layer.name = "DeckChoiceLayer"
	add_child(layer)
	_deck_choice = DECK_CHOICE_PANEL_SCRIPT.new()
	_deck_choice.name = "DeckChoice"
	_deck_choice.modulate = MatchBackgroundController.PAPER_TINT
	_deck_choice.modulate.a = 0.0
	layer.add_child(_deck_choice)
	_deck_choice.chosen.connect(_on_deck_chosen, CONNECT_ONE_SHOT)
	get_viewport().size_changed.connect(_place_deck_choice)
	_place_deck_choice()
	# Laid out by the next frame; placed again then, when its size is known.
	_place_deck_choice.call_deferred()

	var fade := _deck_choice.create_tween()
	fade.tween_property(_deck_choice, "modulate:a", 1.0, deck_choice_fade_in_seconds)
	_deck_choice.begin()

## Centred on the middle of the board that is about to be drawn under it.
func _place_deck_choice() -> void:
	if _deck_choice == null or !is_instance_valid(_deck_choice):
		return
	var centre: Vector2 = get_viewport().get_visible_rect().size * 0.5
	if _match_board != null and _match_board.has_method("get_board_position_screen_position"):
		var middle: float = float(BoardConfig.BOARD_SIZE - 1) * 0.5
		centre = _match_board.get_board_position_screen_position(Vector2(middle, middle))
	_deck_choice.reset_size()
	_deck_choice.position = centre - _deck_choice.size * 0.5

## The codex is settled: the game is set up with it while the choice fades,
## then the grid draws and the rest of the board follows.
func _on_deck_chosen(deck_id: String) -> void:
	GameConfig.set_selected_deck_id(deck_id)
	if GameConfig.ai_mirrors_player_deck and !GameConfig.has_ai_opponent_deck_override():
		GameConfig.select_deck_for_both_players(deck_id)
	deck_chosen.emit()

	if get_viewport().size_changed.is_connected(_place_deck_choice):
		get_viewport().size_changed.disconnect(_place_deck_choice)
	var fade := _deck_choice.create_tween()
	fade.tween_property(_deck_choice, "modulate:a", 0.0, deck_choice_fade_out_seconds)
	await fade.finished
	_deck_choice.get_parent().queue_free()
	_deck_choice = null
	draw_grid(_on_grid_drawn_after_choice)

func _on_grid_drawn_after_choice() -> void:
	if _background != null:
		_background.fade_in_near_colour()
	_bring_in_board()

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
	_let_pieces_through()

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
			_show_hud_node(node)

## One part of the interface, there at once - for a scene that uses it before
## the rest arrives (the tutorial's intro talks through the dialogue panel).
func show_hud_node_now(node: CanvasItem) -> void:
	if node != null and is_instance_valid(node):
		_show_hud_node(node)

func _show_hud_node(node: CanvasItem) -> void:
	node.modulate.a = 1.0
	_set_hud_mouse_enabled(node, true)

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
	var pieces: CanvasItem = _get_pieces_layer()
	if pieces == null:
		return nodes
	for child in pieces.get_children():
		var holder := child as Sprite2D
		if holder != null and holder.texture != null:
			nodes.append(holder)
	return nodes

## The node every piece holder sits under.
func _get_pieces_layer() -> CanvasItem:
	if _match_board == null:
		return null
	return _match_board.get_node_or_null("Pieces") as CanvasItem

## The pieces kept out of sight as a whole until the first of them is brought
## in, from the very first frame rather than from begin(). Fading each piece is
## not enough on its own: the board lays its pieces out again more than once
## while the match is being set up, and each time it throws the old holders
## away and makes new ones at full strength - which would stand on the table
## through the whole drawing of the room, then blink out as the wave reset them.
func _hold_pieces_back() -> void:
	var pieces: CanvasItem = _get_pieces_layer()
	if pieces != null:
		pieces.visible = false

## Every piece being brought in has been faded down by now, and an empty
## holder has nothing to show, so the layer can be drawn again.
func _let_pieces_through() -> void:
	var pieces: CanvasItem = _get_pieces_layer()
	if pieces != null:
		pieces.visible = true

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
		_set_hud_mouse_enabled(node, true)
		var tween := node.create_tween()
		if delay > 0.0:
			tween.tween_interval(delay)
		tween.tween_property(node, "modulate:a", 1.0, seconds)

func _fade_in_staggered(nodes: Array[CanvasItem], seconds: float, stagger: float) -> void:
	for index in range(nodes.size()):
		var delay: float = index * stagger
		_fade_in([nodes[index]], seconds, delay)
		_raise_piece_shadow(nodes[index], seconds, delay)
	_let_pieces_through()

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
	var nodes: Array[CanvasItem] = _get_hud_nodes()
	_set_alpha(nodes, alpha)
	for node in nodes:
		_set_hud_mouse_enabled(node, alpha > 0.0)

## Hidden is only see-through: a faded-out stamp in the hand still answers the
## pointer - it lifts, it plays its sound, the side panel shows it. So the
## interface also stops taking the mouse while it is hidden, the whole branch
## at once, and takes it again as each part comes in.
func _set_hud_mouse_enabled(node: CanvasItem, enabled: bool) -> void:
	var control := node as Control
	if control == null or !is_instance_valid(control):
		return
	control.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED if enabled else Control.MOUSE_BEHAVIOR_DISABLED

func _set_alpha(nodes: Array[CanvasItem], alpha: float) -> void:
	for node in nodes:
		if is_instance_valid(node):
			node.modulate.a = alpha

func _get_view_color() -> int:
	if _match_board != null and _match_board.has_method("get_board_view_color"):
		return int(_match_board.get_board_view_color())
	return 1
