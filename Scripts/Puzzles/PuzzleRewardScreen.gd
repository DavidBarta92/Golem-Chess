extends Control

## Where a solved puzzle pays out (Scenes/PuzzleReward.tscn), one of three
## ways, by the puzzle's reward:
##   * coins pour into the picture and, on a click, fly up into the top bar's
##     coin counter, which counts up as they land (CoinDropPresenter);
##   * a draw point appears in the middle and, on a click, flies up into its
##     counter (a drawn animation is to come in its place);
##   * the puzzle's envelope, its stamp ringed by a dashed die - a new shape
##     every time. Followed round with the left button held, the die cuts the
##     stamp out (Scripts/Cutting, as the pack's tear does); the envelope drops
##     away and the stamp comes to the middle, as a pack's stamps are shown:
##     a basic one just floats, a foil has a blue-grey glow round it, a full
##     art the whole screen's golden light behind it.
## A puzzle solved again plays the same, but nothing is paid: the counters do
## not move. Docs/Puzzles/PUZZLES.md.

const PUZZLES_SCENE: String = "res://Scenes/Puzzles.tscn"
const TopBarIcons = preload("res://Scripts/TopBar/TopBarIcons.gd")
const InkStampMaterial = preload("res://Scripts/InkStamp/InkStampMaterial.gd")
const STAMP_VISUAL_SCENE: PackedScene = preload("res://Scenes/StampVisual.tscn")
const STAMP_CARD_SIZE: Vector2 = Vector2(168.7, 229.0)
## The layer coins and draw points fly on, over the top bar.
const FLY_LAYER: int = 1250
const TITLE_TOP: float = 78.0
const PRESENT_CENTRE_Y: float = 0.56
const FOOT_MARGIN: float = 34.0
const GOLD_FLECK: Color = Color("#f2c14e")
const DRAW_FLECK: Color = Color("#8fbbe0")

# The envelope to cut.
## How wide the envelope lies, and where its stamp sits on it, as shares of
## that width: further in from the corner than on the letters' screen, so the
## die has room round it.
const ENVELOPE_WIDTH: float = 620.0
const ENVELOPE_CENTRE_Y: float = 0.53
const STAMP_SHARE: float = 0.2
const STAMP_INSET: Vector2 = Vector2(0.13, 0.1)
const STAMP_TILT_DEGREES: float = 2.5
## The die: at least this far outside the stamp, and up to this much more.
const DIE_MARGIN: float = 24.0
const DIE_SPREAD: float = 30.0
const DIE_EDGE_INSET: float = 10.0
const DIE_DASH: float = 9.0
const DIE_GAP: float = 6.0
## How far a cut may stray from the die and still count, and how much of it
## has to be followed.
const CUT_TOLERANCE: float = 18.0
const CUT_COVERAGE: float = 0.9
const CUT_LINE: Color = Color(0.06, 0.06, 0.08, 0.85)
## The cut edge round the hole and round the piece, and the piece's shadow.
const CUT_EDGE: Color = Color(0.06, 0.06, 0.08, 0.45)
const PIECE_SHADOW: Color = Color(0, 0, 0, 0.16)
const PIECE_SHADOW_OFFSET: Vector2 = Vector2(5, 8)
const PackController = preload("res://Scenes/CollectionPackController.gd")
## The reveal is played on the dark a pack is opened on, so a foil's glow and
## a full art's light show as they do there.
const REVEAL_DIM: Color = PackController.PACK_OVERLAY_DIM
const REVEAL_DIM_SECONDS: float = 0.5
const ENVELOPE_LEAVE_SECONDS: float = 0.7
const STAMP_TO_CENTRE_SECONDS: float = 0.75
const STAMP_SHOW_SCALE: float = 1.3
const STAMP_FLOAT_PIXELS: float = 6.0
const STAMP_FLOAT_SECONDS: float = 1.6
const FULL_ART_RAY_STRENGTH: float = 0.55

# The draw point.
const DRAW_POINT_SIZE: float = 96.0
const DRAW_FLY_SECONDS: float = 0.7

var puzzle: PuzzleDefinition
var paid_now: bool = false
var stage: Control
var hint_label: Label
var continue_button: Button
var _button_sheet: PanelContainer

# The stamp being cut.
var _envelope_group: Control
var _envelope_size: Vector2
var _die: PackedVector2Array
var _guide_layer: Control
var _trail_layer: Control
var _hole: Control
var _hole_polygon: PackedVector2Array
var _piece: PolygonClip
var _piece_shadow: Control
var _stamp: StampVisual
var _cut_area: CutArea
var _trail: PackedVector2Array
var _cut_done: bool = false

# The draw point.
var _draw_point: Control
var _float_tween: Tween

func _ready() -> void:
	puzzle = PuzzleLibrary.get_puzzle(PuzzleStore.active_puzzle_id)
	paid_now = PuzzleStore.last_reward_paid
	if puzzle == null:
		SceneTransition.change_scene(PUZZLES_SCENE)
		return
	stage = Control.new()
	stage.name = "Stage"
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_titles()
	_build_foot()
	match puzzle.reward_kind:
		PuzzleDefinition.RewardKind.COINS:
			_play_coins()
		PuzzleDefinition.RewardKind.DRAW_POINTS:
			_play_draw_point()
		_:
			GlobalTopBar.show_points_only()
			_play_stamp_cut.call_deferred()

func _build_titles() -> void:
	var titles := VBoxContainer.new()
	titles.name = "Titles"
	titles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.add_theme_constant_override("separation", 4)
	add_child(titles)
	titles.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	titles.offset_top = TITLE_TOP
	var heading := PuzzleUi.label(tr("PUZZLE_SOLVED_TITLE"), &"DisplayLabel")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titles.add_child(heading)
	var line: String = tr("PUZZLE_REWARD_FROM") % puzzle.get_sender_name() if paid_now else tr("PUZZLE_SOLVED_AGAIN")
	var subtitle := PuzzleUi.label(line, &"", UiPalette.INK_SOFT)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titles.add_child(subtitle)

## The hint for what to do next, and the way back once it is done.
func _build_foot() -> void:
	var foot := VBoxContainer.new()
	foot.name = "Foot"
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.add_theme_constant_override("separation", 10)
	add_child(foot)
	foot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	foot.offset_top = -120.0
	foot.offset_bottom = -FOOT_MARGIN
	hint_label = PuzzleUi.label("", &"", UiPalette.INK_SOFT)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_child(hint_label)
	var button_row := CenterContainer.new()
	button_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.add_child(button_row)
	# Bare on paper; on the stamp's dark it gets a sheet of paper under it, as
	# a pack's buttons have on theirs.
	_button_sheet = PanelContainer.new()
	_button_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_button_sheet.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	button_row.add_child(_button_sheet)
	continue_button = Button.new()
	continue_button.text = tr("PUZZLE_BACK_TO_LETTERS")
	continue_button.custom_minimum_size = Vector2(0, 38)
	continue_button.focus_mode = Control.FOCUS_NONE
	continue_button.modulate.a = 0.0
	continue_button.disabled = true
	continue_button.pressed.connect(func() -> void: SceneTransition.change_scene(PUZZLES_SCENE))
	_button_sheet.add_child(continue_button)

func _show_hint(key: String) -> void:
	hint_label.text = tr(key)
	hint_label.modulate.a = 0.0
	create_tween().tween_property(hint_label, "modulate:a", 1.0, 0.3)

func _finish() -> void:
	hint_label.text = ""
	continue_button.disabled = false
	create_tween().tween_property(continue_button, "modulate:a", 1.0, 0.35)

func _present_rect() -> Rect2:
	var view: Vector2 = get_viewport_rect().size
	var rect_size := Vector2(minf(view.x - 200.0, 820.0), 420.0)
	return Rect2(Vector2((view.x - rect_size.x) * 0.5, view.y * PRESENT_CENTRE_Y - rect_size.y * 0.5), rect_size)

# --- Coins ----------------------------------------------------------------------

func _play_coins() -> void:
	var shower := _CoinShower.new()
	shower.name = "Coins"
	shower.amount = puzzle.reward_amount
	var rect: Rect2 = _present_rect()
	shower.position = rect.position
	shower.size = rect.size
	stage.add_child(shower)
	shower.ready_to_collect.connect(func() -> void: _show_hint("PUZZLE_REWARD_COLLECT_COINS"))
	shower.clicked.connect(func(_at: Vector2) -> void:
		if shower._accepting_click:
			hint_label.text = "")
	shower.presentation_finished.connect(_finish)
	shower.begin(null, paid_now)

## The story's coin drop, with a golden glow rising behind the pile and a
## spray of gold where each coin lands. The glow is painted, not added light:
## added light does not show on paper.
class _CoinShower:
	extends CoinDropPresenter

	signal ready_to_collect

	var _light: TextureRect

	func _start() -> void:
		_light = TextureRect.new()
		_light.texture = PuzzleUi.glow_texture(PackRevealFx.FULL_ART_LIGHT, 0.5)
		_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_light.size = Vector2(size.x * 1.2, size.y * 1.3)
		_light.position = Vector2(size.x * 0.5, size.y * table_line_ratio) - _light.size * 0.5
		_light.modulate.a = 0.0
		add_child(_light)
		create_tween().tween_property(_light, "modulate:a", 1.0, 1.6).set_ease(Tween.EASE_OUT)
		super()

	func _drop_coin(coin: TextureRect, rest: Vector2, delay: float) -> void:
		super(coin, rest, delay)
		get_tree().create_timer(delay + drop_seconds).timeout.connect(func() -> void:
			if is_inside_tree():
				PackRevealFx.burst(self, rest + Vector2.ONE * coin_size * 0.5, GOLD_FLECK, 8, 180.0))

	func _on_coin_landed() -> void:
		super()
		if _accepting_click:
			ready_to_collect.emit()

	func _fly_to_counter() -> void:
		super()
		if _light != null:
			create_tween().tween_property(_light, "modulate:a", 0.0, 0.8)

# --- The draw point -------------------------------------------------------------

## A draw point in the middle; a click sends it up into its counter. A drawn
## animation is to come here.
func _play_draw_point() -> void:
	GlobalTopBar.show_points_only(["coin", "draw"])
	var total: int = PlayerProgressStore.get_draw_points()
	GlobalTopBar.set_displayed_counter("draw", total - puzzle.reward_amount if paid_now else total)

	_draw_point = Control.new()
	_draw_point.name = "DrawPoint"
	_draw_point.size = Vector2.ONE * DRAW_POINT_SIZE
	_draw_point.pivot_offset = _draw_point.size * 0.5
	_draw_point.mouse_filter = Control.MOUSE_FILTER_STOP
	_draw_point.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_draw_point.draw.connect(func() -> void:
		TopBarIcons.draw_icon(_draw_point, "draw", Rect2(Vector2.ZERO, _draw_point.size), UiPalette.INK))
	stage.add_child(_draw_point)
	InkStampMaterial.apply(_draw_point, true)
	_draw_point.position = _present_rect().get_center() - _draw_point.size * 0.5
	_draw_point.scale = Vector2.ZERO
	var amount := PuzzleUi.label("+%d" % puzzle.reward_amount, &"TitleLabel")
	amount.position = Vector2(DRAW_POINT_SIZE * 0.86, DRAW_POINT_SIZE * 0.7)
	_draw_point.add_child(amount)

	var appear := create_tween()
	appear.tween_interval(0.35)
	appear.tween_callback(func() -> void:
		SFXManager.play("stamp_up")
		PackRevealFx.burst(stage, _draw_point.position + _draw_point.size * 0.5, DRAW_FLECK, 26, 260.0))
	appear.tween_property(_draw_point, "scale", Vector2.ONE, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	appear.tween_callback(func() -> void:
		_float(_draw_point)
		_show_hint("PUZZLE_REWARD_COLLECT_DRAW")
		_draw_point.gui_input.connect(_on_draw_point_input))

func _on_draw_point_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or !click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	_draw_point.gui_input.disconnect(_on_draw_point_input)
	_draw_point.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.text = ""
	if _float_tween != null:
		_float_tween.kill()
	var layer := CanvasLayer.new()
	layer.layer = FLY_LAYER
	add_child(layer)
	_draw_point.reparent(layer, true)
	SFXManager.play("pack_whoosh")
	var start: Vector2 = _draw_point.position
	var end: Vector2 = GlobalTopBar.get_counter_global_center("draw") - _draw_point.size * 0.5
	var lift := Vector2(randf_range(-80.0, 80.0), -140.0)
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		var middle: Vector2 = start.lerp(end, 0.5) + lift
		_draw_point.position = start.lerp(middle, t).lerp(middle.lerp(end, t), t)
		_draw_point.scale = Vector2.ONE.lerp(Vector2.ONE * 0.24, t)
		_draw_point.rotation = t * TAU * 0.5, 0.0, 1.0, DRAW_FLY_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void:
		_draw_point.queue_free()
		SFXManager.play("buy")
		GlobalTopBar.set_displayed_counter("draw", PlayerProgressStore.get_draw_points())
		GlobalTopBar.pulse_counter("draw"))
	tween.tween_interval(0.35)
	tween.tween_callback(_finish)

## A slow bob and sway, for what waits in the middle.
func _float(item: Control) -> void:
	var rest_y: float = item.position.y
	var rest_rotation: float = item.rotation
	_float_tween = item.create_tween().set_loops()
	_float_tween.tween_property(item, "position:y", rest_y - STAMP_FLOAT_PIXELS, STAMP_FLOAT_SECONDS * 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_float_tween.parallel().tween_property(item, "rotation", rest_rotation + deg_to_rad(1.2), STAMP_FLOAT_SECONDS * 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_float_tween.tween_property(item, "position:y", rest_y + STAMP_FLOAT_PIXELS, STAMP_FLOAT_SECONDS * 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_float_tween.parallel().tween_property(item, "rotation", rest_rotation - deg_to_rad(1.2), STAMP_FLOAT_SECONDS * 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

# --- The stamp ------------------------------------------------------------------

func _play_stamp_cut() -> void:
	var style: int = puzzle.get_envelope_style()
	_envelope_size = Vector2(ENVELOPE_WIDTH, EnvelopeArt.get_height(style, ENVELOPE_WIDTH))
	var view: Vector2 = get_viewport_rect().size
	var origin := Vector2((view.x - _envelope_size.x) * 0.5, view.y * ENVELOPE_CENTRE_Y - _envelope_size.y * 0.5)

	_envelope_group = _EnvelopeShadow.new()
	_envelope_group.name = "Envelope"
	_envelope_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_envelope_group.position = origin
	_envelope_group.size = _envelope_size
	stage.add_child(_envelope_group)
	var envelope := EnvelopeView.new(style, EnvelopeView.Part.FRONT)
	envelope.size = _envelope_size
	_envelope_group.add_child(envelope)

	var stamp_rect: Rect2 = _stamp_rect()
	_die = _make_die(stamp_rect)
	_hole = Control.new()
	_hole.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hole.size = _envelope_size
	_hole.visible = false
	_hole.draw.connect(func() -> void:
		if _hole_polygon.size() >= 3:
			_hole.draw_colored_polygon(_hole_polygon, UiPalette.PAPER)
			var edge: PackedVector2Array = _hole_polygon.duplicate()
			edge.append(_hole_polygon[0])
			_hole.draw_polyline(edge, CUT_EDGE, 1.5, true))
	_envelope_group.add_child(_hole)
	_guide_layer = Control.new()
	_guide_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_guide_layer.size = _envelope_size
	_guide_layer.draw.connect(_draw_die)
	_envelope_group.add_child(_guide_layer)
	InkStampMaterial.apply(_guide_layer)
	_trail_layer = Control.new()
	_trail_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_trail_layer.size = _envelope_size
	_trail_layer.draw.connect(func() -> void:
		if _trail.size() >= 2:
			_trail_layer.draw_polyline(_trail, CUT_LINE, 2.0, true))
	_envelope_group.add_child(_trail_layer)

	# The piece the cut takes out: the envelope's paper inside the cut line,
	# with its shadow under it and its cut edge.
	_piece_shadow = Control.new()
	_piece_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_piece_shadow.position = origin
	_piece_shadow.size = _envelope_size
	_piece_shadow.visible = false
	_piece_shadow.draw.connect(func() -> void:
		if _hole_polygon.size() >= 3:
			_piece_shadow.draw_set_transform(PIECE_SHADOW_OFFSET)
			_piece_shadow.draw_colored_polygon(_hole_polygon, PIECE_SHADOW))
	stage.add_child(_piece_shadow)
	_piece = PolygonClip.new()
	_piece.name = "CutPiece"
	_piece.position = origin
	_piece.size = _envelope_size
	_piece.visible = false
	stage.add_child(_piece)
	var piece_paper := EnvelopeView.new(style, EnvelopeView.Part.FRONT)
	piece_paper.size = _envelope_size
	_piece.add_child(piece_paper)
	var piece_edge := Control.new()
	piece_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	piece_edge.size = _envelope_size
	piece_edge.draw.connect(func() -> void:
		if _hole_polygon.size() >= 3:
			var edge: PackedVector2Array = _hole_polygon.duplicate()
			edge.append(_hole_polygon[0])
			piece_edge.draw_polyline(edge, CUT_EDGE, 3.0, true))
	_piece.add_child(piece_edge)

	_stamp = STAMP_VISUAL_SCENE.instantiate() as StampVisual
	stage.add_child(_stamp)
	_stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stamp.size = STAMP_CARD_SIZE
	_stamp.pivot_offset = STAMP_CARD_SIZE * 0.5
	_stamp.draggable = false
	_stamp.disabled = true
	_stamp.set_hover_raise_enabled(false)
	_stamp.set_ambient_motion_enabled(false)
	_stamp.set_collection_owned(true)
	if puzzle.reward_print != null:
		_stamp.set_stamp_print(puzzle.reward_print)
	else:
		_stamp.set_stamp(puzzle.get_reward_stamp())
	var card_scale: float = stamp_rect.size.x / STAMP_CARD_SIZE.x
	_stamp.set_rest_scale(Vector2.ONE * card_scale)
	_stamp.scale = Vector2.ONE * card_scale
	_stamp.rotation = deg_to_rad(STAMP_TILT_DEGREES)
	_stamp.position = origin + stamp_rect.get_center() - STAMP_CARD_SIZE * 0.5

	_cut_area = CutArea.new()
	_cut_area.name = "CutArea"
	_cut_area.position = origin
	_cut_area.size = _envelope_size
	_cut_area.guide = CutGuide.outline(_die)
	_cut_area.tolerance = CUT_TOLERANCE
	_cut_area.mouse_default_cursor_shape = Control.CURSOR_CROSS
	stage.add_child(_cut_area)
	_cut_area.cut_started.connect(_on_cut_moved)
	_cut_area.cut_moved.connect(_on_cut_moved)
	_cut_area.cut_ended.connect(_on_cut_ended)

	# In from below.
	for item: CanvasItem in [_envelope_group, _stamp]:
		item.modulate.a = 0.0
	var arrive := create_tween().set_parallel()
	for item: Control in [_envelope_group, _stamp]:
		var rest: float = item.position.y
		item.position.y = rest + 60.0
		arrive.tween_property(item, "position:y", rest, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		arrive.tween_property(item, "modulate:a", 1.0, 0.4)
	_show_hint("PUZZLE_REWARD_CUT_HINT")

## Where the stamp is stuck on this envelope, in its own pixels.
func _stamp_rect() -> Rect2:
	var width: float = _envelope_size.x * STAMP_SHARE
	var stamp_size := Vector2(width, width * STAMP_CARD_SIZE.y / STAMP_CARD_SIZE.x)
	return Rect2(Vector2(_envelope_size.x * (1.0 - STAMP_INSET.x) - width, _envelope_size.x * STAMP_INSET.y), stamp_size)

## A die round the stamp: a few straight sides at irregular angles and
## distances - a new one every time - always clear of the stamp and inside
## the envelope.
func _make_die(stamp_rect: Rect2) -> PackedVector2Array:
	var keep_clear: Rect2 = stamp_rect.grow(DIE_MARGIN)
	var bounds: Rect2 = Rect2(Vector2.ZERO, _envelope_size).grow(-DIE_EDGE_INSET)
	var centre: Vector2 = stamp_rect.get_center()
	var clear_corners := PackedVector2Array([keep_clear.position, Vector2(keep_clear.end.x, keep_clear.position.y), keep_clear.end, Vector2(keep_clear.position.x, keep_clear.end.y)])
	for attempt in range(24):
		var corner_count: int = randi_range(6, 9)
		var points := PackedVector2Array()
		for i in range(corner_count):
			var angle: float = TAU * (float(i) + randf_range(-0.3, 0.3)) / float(corner_count)
			var direction := Vector2.from_angle(angle)
			# Out to the edge of the clear area that way, and some more.
			var half: Vector2 = keep_clear.size * 0.5
			var reach: float = minf(half.x / maxf(absf(direction.x), 0.001), half.y / maxf(absf(direction.y), 0.001))
			var corner: Vector2 = centre + direction * (reach * randf_range(1.05, 1.3) + randf_range(0.0, DIE_SPREAD))
			points.append(corner.clamp(bounds.position, bounds.end))
		var die: PackedVector2Array = Geometry2D.convex_hull(points)
		if die.size() > 1 and die[0] == die[-1]:
			die.remove_at(die.size() - 1)
		var holds_stamp: bool = die.size() >= 3
		for corner in clear_corners:
			holds_stamp = holds_stamp and Geometry2D.is_point_in_polygon(corner, die)
		if holds_stamp:
			return die
	# Never fails in practice; the clear area itself, then.
	return clear_corners

func _draw_die() -> void:
	if _die.size() < 3:
		return
	var closed: PackedVector2Array = _die.duplicate()
	closed.append(_die[0])
	for i in range(1, closed.size()):
		var from: Vector2 = closed[i - 1]
		var to: Vector2 = closed[i]
		var length: float = from.distance_to(to)
		var at: float = 0.0
		while at < length:
			var dash_end: float = minf(at + DIE_DASH, length)
			_guide_layer.draw_line(from.lerp(to, at / length), from.lerp(to, dash_end / length), UiPalette.INK, 2.0, true)
			at += DIE_DASH + DIE_GAP

func _on_cut_moved(stroke: CutStroke) -> void:
	if _cut_done:
		return
	_trail = stroke.points
	_trail_layer.modulate.a = 1.0
	_trail_layer.queue_redraw()

func _on_cut_ended(stroke: CutStroke) -> void:
	if _cut_done:
		return
	if !stroke.passes(CUT_COVERAGE):
		# Off the line, or not the whole way round: the cut heals.
		var heal := create_tween()
		heal.tween_property(_trail_layer, "modulate:a", 0.0, 0.4)
		_show_hint("PUZZLE_REWARD_CUT_RETRY")
		return
	_cut_done = true
	_cut_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cut_out(_cut_outline(stroke))

## The line the cut really took, wobbles and all, as a shape that can be
## filled: the overlap where it met its start trimmed, too close points
## dropped. A path that will not make a shape gives the die's own.
func _cut_outline(stroke: CutStroke) -> PackedVector2Array:
	var outline := PackedVector2Array()
	var start: Vector2 = stroke.points[0]
	var travelled: float = 0.0
	for i in range(stroke.points.size()):
		var point: Vector2 = stroke.points[i]
		if i > 0:
			travelled += point.distance_to(stroke.points[i - 1])
		if travelled > CUT_TOLERANCE * 4.0 and point.distance_to(start) < CUT_TOLERANCE * 0.5:
			break
		if outline.is_empty() or outline[-1].distance_to(point) >= 3.0:
			outline.append(point)
	if outline.size() < 3 or Geometry2D.triangulate_polygon(outline).is_empty():
		return _die
	return outline

## The piece comes free, the envelope drops away, and the stamp comes to the
## middle to be shown off.
func _cut_out(outline: PackedVector2Array) -> void:
	SFXManager.play("stamp_tear_up")
	hint_label.text = ""
	_hole_polygon = outline
	_hole.visible = true
	_hole.queue_redraw()
	_piece.polygon = outline
	_piece.set_clip_enabled(true)
	_piece.visible = true
	for edge_layer in _piece.get_children():
		edge_layer.queue_redraw()
	_piece_shadow.visible = true
	_piece_shadow.queue_redraw()
	_guide_layer.visible = false
	_trail_layer.visible = false

	var tween := create_tween()
	# The piece lifts a little off the envelope with its stamp.
	tween.tween_property(_piece, "position:y", _piece.position.y - 14.0, 0.25).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_piece_shadow, "position:y", _piece_shadow.position.y - 8.0, 0.25).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_stamp, "position:y", _stamp.position.y - 14.0, 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_callback(SFXManager.play.bind("pack_whoosh"))
	tween.tween_property(_envelope_group, "position:y", get_viewport_rect().size.y + 40.0, ENVELOPE_LEAVE_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	# The paper round the stamp falls away after it.
	tween.parallel().tween_property(_piece, "modulate:a", 0.0, ENVELOPE_LEAVE_SECONDS * 0.8).set_delay(ENVELOPE_LEAVE_SECONDS * 0.3)
	tween.parallel().tween_property(_piece, "position:y", _piece.position.y + 90.0, ENVELOPE_LEAVE_SECONDS).set_delay(ENVELOPE_LEAVE_SECONDS * 0.3).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_piece_shadow, "modulate:a", 0.0, ENVELOPE_LEAVE_SECONDS * 0.5).set_delay(ENVELOPE_LEAVE_SECONDS * 0.3)
	var centre: Vector2 = _present_rect().get_center()
	tween.parallel().tween_property(_stamp, "position", centre - STAMP_CARD_SIZE * 0.5, STAMP_TO_CENTRE_SECONDS).set_delay(0.15).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(_stamp, "scale", Vector2.ONE * STAMP_SHOW_SCALE, STAMP_TO_CENTRE_SECONDS).set_delay(0.15).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(_stamp, "rotation", 0.0, STAMP_TO_CENTRE_SECONDS).set_delay(0.15)
	tween.tween_callback(_show_stamp)

## As a pack shows its stamps, on the dark a pack is opened on: a basic one
## floats, a foil has its blue-grey glow, a full art the whole screen's golden
## light behind it.
func _show_stamp() -> void:
	_stamp.set_rest_scale(Vector2.ONE * STAMP_SHOW_SCALE)
	var rarity: int = puzzle.reward_print.get_rarity() if puzzle.reward_print != null else StampPrint.Rarity.BASIC
	var centre: Vector2 = _stamp.position + STAMP_CARD_SIZE * 0.5

	var dim := ColorRect.new()
	dim.name = "RevealDim"
	dim.color = REVEAL_DIM
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.modulate.a = 0.0
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	create_tween().tween_property(dim, "modulate:a", 1.0, REVEAL_DIM_SECONDS)
	if rarity == StampPrint.Rarity.FULL_ART:
		var view := Rect2(Vector2.ZERO, get_viewport_rect().size)
		var rays: ColorRect = PackRevealFx.add_rays(self, view, centre / view.size, PackRevealFx.FULL_ART_LIGHT, 13.0)
		create_tween().tween_property(rays.material, "shader_parameter/strength", FULL_ART_RAY_STRENGTH, 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_stamp.reparent(self, true)
	match rarity:
		StampPrint.Rarity.FOIL:
			SFXManager.play("pack_foil_reveal")
			var aura: ColorRect = PackRevealFx.add_aura(_stamp, rarity)
			aura.modulate.a = 0.0
			create_tween().tween_property(aura, "modulate:a", 1.0, 0.5)
			PackRevealFx.sweep(_stamp, PackRevealFx.FOIL_LIGHT)
			PackRevealFx.burst(self, centre, PackRevealFx.FOIL_LIGHT, 30, 300.0)
		StampPrint.Rarity.FULL_ART:
			SFXManager.play("pack_full_art_reveal")
			PackRevealFx.add_aura(_stamp, rarity)
			PackRevealFx.sweep(_stamp, PackRevealFx.FULL_ART_LIGHT)
			PackRevealFx.burst(self, centre, PackRevealFx.FULL_ART_LIGHT, 44, 380.0)
	_float(_stamp)
	var name_label := PuzzleUi.label(PuzzleUi.describe_reward(puzzle), &"TitleLabel", UiPalette.PAPER_RAISED)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.size = Vector2(400, 30)
	name_label.position = Vector2(centre.x - 200.0, centre.y + STAMP_CARD_SIZE.y * STAMP_SHOW_SCALE * 0.5 + 14.0)
	name_label.modulate.a = 0.0
	add_child(name_label)
	create_tween().tween_property(name_label, "modulate:a", 1.0, 0.4)
	# The way back comes up over the dark, on its sheet of paper.
	_button_sheet.theme_type_variation = &"ShopWindowPanel"
	_button_sheet.remove_theme_stylebox_override("panel")
	move_child(_button_sheet.get_parent().get_parent(), -1)
	_finish()

## A soft shadow under the envelope being cut.
class _EnvelopeShadow:
	extends Control

	func _draw() -> void:
		var shadow := StyleBoxFlat.new()
		shadow.bg_color = Color(0, 0, 0, 0)
		shadow.shadow_color = Color(0, 0, 0, 0.18)
		shadow.shadow_size = 14
		shadow.shadow_offset = Vector2(0, 8)
		shadow.set_corner_radius_all(3)
		draw_style_box(shadow, Rect2(Vector2.ZERO, size))
