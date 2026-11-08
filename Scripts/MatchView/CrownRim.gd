extends Node2D

## One player's crown points, on the board itself: a row of little pits cut into
## the rim and a ring-shaped groove for the crown at its end. Painted under the
## pieces, so the opponent's stand in front of theirs. Each player's row lies to
## their own right on the rim nearest them, so seen from either side the
## opponent's is the mirror of the player's through the middle of the board.
##
## A point lights up in its pit and cools to a gold ball. When all of them are
## there they rise, rush to the groove and the crown forms in it. A point lost
## to an effect burns away like an expired stamp; one won by an effect flashes
## over the golem that set it off and rushes to the next free pit. The points
## change here only when they are told to (show_points), and one change plays
## out at a time; CrownController holds the numbers and the rules.
##
## Where things go is worked out on the flat board and put through the board's
## own perspective, so a pit lies on the wood at the far end as it does at the
## near one.

## The view turned over, so the row is somewhere else on screen.
signal rebuilt

const CrownGold = preload("res://Scripts/MatchView/CrownGold.gd")
const CrownBall = preload("res://Scripts/MatchView/CrownBall.gd")
const BURN_SHADER = preload("res://Shaders/stamp_burn.gdshader")

# In board units, on the flat board.
const PIT_RADIUS: float = 2.1
const PIT_STEP: float = 5.4
## The pit's far wall shows by this much, the wood's lit lip below it by the other.
const PIT_DEPTH: float = 0.75
const LIP_DEPTH: float = 0.3
const BALL_RADIUS: float = 1.5
const GROOVE_OUTER_RADIUS: float = 3.7
const GROOVE_INNER_RADIUS: float = 2.2
const GROOVE_GAP: float = 2.2
const RING_RADIUS: float = 3.55
## Across a ball's or the ring's glow at full heat.
const BALL_GLOW_WIDTH: float = 30.0
const RING_GLOW_WIDTH: float = 58.0
const CIRCLE_SEGMENTS: int = 28
const EDGE_WIDTH: float = 0.22

## The lights' reach as a share of their texture: a ball's is about a cell around.
const BALL_LIGHT_SCALE: float = 0.3
const BALL_LIGHT_ENERGY: float = 1.1
const RING_LIGHT_SCALE: float = 0.5
const RING_LIGHT_ENERGY: float = 1.1

const SHOW_SECONDS: float = 0.8
const FLASH_IN_SECONDS: float = 0.08
const FLASH_OUT_SECONDS: float = 0.75
const POP_SECONDS: float = 0.25
const POP_FROM_SHARE: float = 0.35
## Points that arrive together follow each other in this quickly.
const GAIN_STAGGER: float = 0.14

## How long a point won by an effect shows over its golem before it sets off.
const SOURCE_HOLD_SECONDS: float = 0.35
const FLY_SECONDS: float = 0.8
const FLIGHT_GLOW: float = 0.6
const LANDING_GLOW: float = 0.7
const LANDING_GLOW_SECONDS: float = 0.45

const MERGE_WAIT_SECONDS: float = 0.15
const MERGE_FLASH_SECONDS: float = 0.3
## Milder than a point's own flash.
const MERGE_GLOW: float = 0.45
const MERGE_FLY_SECONDS: float = 0.85
const MERGE_ARRIVED_SCALE: float = 0.55
const RING_GLOW_IN_SECONDS: float = 0.1
const RING_GLOW_OUT_SECONDS: float = 1.1
const RING_FORM_DELAY: float = 0.35
const RING_FORM_SECONDS: float = 0.6
const RING_FORM_FROM_SCALE: float = 1.25

## The same as StampVisual.play_burn_away_and_free, at a ball's size.
const BURN_SECONDS: float = 1.15
const BURN_RISE: float = 1.6
const BURN_SCALE: float = 0.82
const BURN_TILT_DEGREES: float = 7.0
const BURN_NOISE_SCALE: float = 5.0
const BURN_STAGGER: float = 0.12

const RING_FADE_SECONDS: float = 0.6
const TAKEN_SECONDS: float = 0.2
## The crown has gone onto a golem: what is left of the row hurries out of its way.
const HURRY_SPEED: float = 4.0

var match_board
var owner_color: int = 1
var points_required: int = 6
var target_points: int = 0

var _geometry
var _light_texture: Texture2D
var _row_centre_canvas_x: float = 960.0
var _rim_y: float = 0.0
var _near: Vector2 = Vector2.DOWN
var _built_view: int = 0
var _pits: Array[Vector2] = []
var _groove: Vector2 = Vector2.ZERO
var _balls: Array = []
var _ring

## The balls lying in their pits, or standing in the crown once it is there.
var _shown: int = 0
var _ring_on: bool = false
var _ring_lifted: bool = false
var _taking: bool = false
var _sources: Array[Vector2] = []
## Points to burn before anything else, whatever the numbers say.
var _burns_due: int = 0
var _playing: bool = false
var _step: Tween
var _show_share: float = 0.0
var _ring_fade_tween: Tween

## `row_centre_canvas_x` is over what, on the 1920x1080 canvas, the row is
## centred on the player's own side.
func setup(board, new_owner_color: int, row_centre_canvas_x: float) -> void:
	match_board = board
	owner_color = new_owner_color
	_row_centre_canvas_x = row_centre_canvas_x
	_geometry = match_board.get_board_geometry()
	_rim_y = float(match_board.BOARD_SIZE * match_board.CELL_WIDTH) * 0.5 + match_board.BOARD_FRAME_VERTICAL_EXTENSION * 0.5
	_light_texture = match_board.get_piece_effect_geometry_controller().get_attach_point_light_texture()
	_ring = CrownBall.new(CrownGold.ring_texture(), _light_texture, RING_LIGHT_SCALE, RING_LIGHT_ENERGY)
	add_child(_ring)
	z_as_relative = false
	z_index = BoardGridOverlay.Z_INDEX - 1
	visible = false
	_rebuild()

func _process(_delta: float) -> void:
	# The match's intro fades the board by this node, whose children are thrown
	# away whenever the board is laid out again, so this cannot live under it.
	modulate.a = match_board.board_tiles_node.modulate.a * _show_share
	if _geometry.view_color != _built_view:
		_rebuild()

## Comes in over a moment: in a match that is under the board's own fade, in the
## tutorial it is the board's next lesson.
func show_rim() -> void:
	if visible:
		return
	visible = true
	create_tween().tween_property(self, "_show_share", 1.0, SHOW_SECONDS)

func is_ring_ready() -> bool:
	return _ring_on and !_playing and !_ring_lifted

func set_ring_lifted(lifted: bool) -> void:
	_ring_lifted = lifted
	_settle_ring()

## Pale while it cannot be taken.
func set_ring_faded(faded: bool, animate: bool) -> void:
	if _ring_fade_tween != null and _ring_fade_tween.is_valid():
		_ring_fade_tween.kill()
	var target: float = 1.0 if faded else 0.0
	if !animate:
		_ring.fade = target
		return
	_ring_fade_tween = create_tween()
	_ring_fade_tween.tween_property(_ring, "fade", target, RING_FADE_SECONDS)

## How large the crown stands in its groove, as a share of its size: it breathes
## while it can be taken.
func set_ring_pulse(grow: float) -> void:
	if _ring_on and !_playing:
		_ring.body.scale = _ring.rest_scale * grow

# --- Changing the points ------------------------------------------------------

## The points go to this, playing out what changed. `sources` are where points
## won by an effect come from, in this node's space: any more points than that
## simply light up in their pits. `burns` are points an effect took: one can go
## and the turn's point come in the same state, which the numbers alone hide.
func show_points(points: int, sources: Array[Vector2] = [], burns: int = 0) -> void:
	var gained: int = maxi(0, points - maxi(0, target_points - burns))
	target_points = clampi(points, 0, points_required)
	_burns_due += burns
	_sources.append_array(sources.slice(0, gained))
	_advance()

func set_points_at_once(points: int, required: int) -> void:
	if _step != null and _step.is_valid():
		_step.kill()
	_step = null
	_playing = false
	_taking = false
	_burns_due = 0
	_sources.clear()
	if required != points_required:
		points_required = required
		_rebuild()
	target_points = clampi(points, 0, points_required)
	_shown = target_points
	_ring_on = _shown >= points_required
	_settle_balls()
	_ring.reset()
	_settle_ring()

## The crown has gone onto a golem. It leaves with no fuss, and takes the points
## with it.
func take_crown() -> void:
	_taking = true
	target_points = 0
	_burns_due = 0
	if _step != null and _step.is_valid():
		_step.set_speed_scale(HURRY_SPEED)
	_advance()

func _advance() -> void:
	if _playing:
		return
	_playing = true
	var step: Tween = _next_step()
	while step != null:
		_step = step
		await step.finished
		step = _next_step()
	_step = null
	_playing = false
	_settle_ring()

func _next_step() -> Tween:
	if _taking:
		_taking = false
		return _play_crown_taken() if _ring_on or _shown > 0 else null
	var burn_to: int = maxi(0, mini(target_points, _shown - _burns_due))
	_burns_due = 0
	if _ring_on and burn_to < points_required:
		return _play_ring_burning(burn_to)
	if _shown > burn_to:
		return _play_points_burning(burn_to)
	if _shown < target_points:
		return _play_points_arriving()
	if _shown >= points_required and !_ring_on:
		return _play_crown_forming()
	return null

func _new_step() -> Tween:
	return create_tween().set_parallel(true)

# --- What plays ---------------------------------------------------------------

func _play_points_arriving() -> Tween:
	var tween: Tween = _new_step()
	for index in range(_shown, target_points):
		var delay: float = float(index - _shown) * GAIN_STAGGER
		if _sources.is_empty():
			_light_up(tween, _balls[index], delay)
		else:
			_fly_in(tween, _balls[index], _sources.pop_front(), delay)
	_shown = target_points
	return tween

func _light_up(tween: Tween, ball, delay: float, glow: float = 1.0) -> void:
	tween.tween_callback(ball.appear_at.bind(ball.rest_position)).set_delay(delay)
	tween.tween_method(ball.set_glow, 0.0, glow, FLASH_IN_SECONDS).set_delay(delay)
	tween.tween_method(ball.set_glow, glow, 0.0, FLASH_OUT_SECONDS).set_delay(delay + FLASH_IN_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(ball.body, "scale", ball.rest_scale, POP_SECONDS).from(ball.rest_scale * POP_FROM_SHARE).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _fly_in(tween: Tween, ball, source: Vector2, delay: float) -> void:
	var departs: float = delay + SOURCE_HOLD_SECONDS
	var arrives: float = departs + FLY_SECONDS
	tween.tween_callback(ball.appear_at.bind(source)).set_delay(delay)
	tween.tween_callback(ball.set_aloft.bind(_get_aloft_z())).set_delay(delay)
	tween.tween_method(ball.set_glow, 0.0, 1.0, FLASH_IN_SECONDS).set_delay(delay)
	tween.tween_method(ball.set_glow, 1.0, FLIGHT_GLOW, SOURCE_HOLD_SECONDS - FLASH_IN_SECONDS).set_delay(delay + FLASH_IN_SECONDS)
	tween.tween_property(ball.body, "scale", ball.rest_scale, POP_SECONDS).from(ball.rest_scale * POP_FROM_SHARE).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(ball, "position", ball.rest_position, FLY_SECONDS).from(source).set_delay(departs).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_callback(ball.land).set_delay(arrives)
	tween.tween_method(ball.set_glow, LANDING_GLOW, 0.0, LANDING_GLOW_SECONDS).set_delay(arrives).set_trans(Tween.TRANS_SINE)

func _play_crown_forming() -> Tween:
	var tween: Tween = _new_step()
	var departs: float = MERGE_WAIT_SECONDS + MERGE_FLASH_SECONDS
	var arrives: float = departs + MERGE_FLY_SECONDS
	var groove_at: Vector2 = _ring.rest_position
	for index in _shown:
		var ball = _balls[index]
		ball.light_share = 1.0 / float(_shown)
		tween.tween_method(ball.set_glow, 0.0, MERGE_GLOW, MERGE_FLASH_SECONDS).set_delay(MERGE_WAIT_SECONDS)
		tween.tween_property(ball, "position", groove_at, MERGE_FLY_SECONDS).from(ball.rest_position).set_delay(departs).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tween.tween_property(ball.body, "scale", ball.rest_scale * MERGE_ARRIVED_SCALE, MERGE_FLY_SECONDS).set_delay(departs).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tween.tween_callback(ball.reset).set_delay(arrives)

	# The balls' lights go out as they arrive, into this one, and it dies down
	# with the crown coming up out of it.
	tween.tween_callback(_begin_ring).set_delay(arrives)
	tween.tween_method(_ring.set_glow, 0.0, 1.0, RING_GLOW_IN_SECONDS).set_delay(arrives)
	tween.tween_method(_ring.set_glow, 1.0, 0.0, RING_GLOW_OUT_SECONDS).set_delay(arrives + RING_GLOW_IN_SECONDS).set_trans(Tween.TRANS_SINE)
	var forms: float = arrives + RING_FORM_DELAY
	tween.tween_property(_ring.body, "modulate:a", 1.0, RING_FORM_SECONDS).from(0.0).set_delay(forms)
	tween.tween_property(_ring.body, "scale", _ring.rest_scale, RING_FORM_SECONDS).from(_ring.rest_scale * RING_FORM_FROM_SCALE).set_delay(forms).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish_ring).set_delay(arrives + RING_GLOW_IN_SECONDS + RING_GLOW_OUT_SECONDS)
	return tween

func _begin_ring() -> void:
	_ring.body.modulate.a = 0.0
	_ring.appear_at(_ring.rest_position)

func _finish_ring() -> void:
	_ring_on = true

func _play_points_burning(burn_to: int) -> Tween:
	var tween: Tween = _new_step()
	var order: int = 0
	for index in range(_shown - 1, burn_to - 1, -1):
		_burn(tween, _balls[index], float(order) * BURN_STAGGER)
		order += 1
	_shown = burn_to
	return tween

## A point taken off a full meter: the crown is what its points had become, so
## it burns, and the points that are left come back to their pits.
func _play_ring_burning(burn_to: int) -> Tween:
	var tween: Tween = _new_step()
	_ring_on = false
	_burn(tween, _ring, 0.0)
	_shown = burn_to
	for index in _shown:
		_balls[index].light_share = 1.0 / float(_shown)
		_light_up(tween, _balls[index], float(index) * GAIN_STAGGER, MERGE_GLOW)
	return tween

func _burn(tween: Tween, ball, delay: float) -> void:
	var burn := ShaderMaterial.new()
	burn.shader = BURN_SHADER
	burn.set_shader_parameter("burn_progress", 0.0)
	burn.set_shader_parameter("seed", randf() * 1000.0)
	burn.set_shader_parameter("noise_scale", BURN_NOISE_SCALE)
	var body: Sprite2D = ball.body
	var tilt: float = deg_to_rad(randf_range(-BURN_TILT_DEGREES, BURN_TILT_DEGREES))
	tween.tween_callback(body.set_material.bind(burn)).set_delay(delay)
	tween.tween_property(burn, "shader_parameter/burn_progress", 1.0, BURN_SECONDS).set_delay(delay).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(body, "position", Vector2.UP * BURN_RISE, BURN_SECONDS).set_delay(delay)
	tween.tween_property(body, "scale", body.scale * BURN_SCALE, BURN_SECONDS).set_delay(delay)
	tween.tween_property(body, "rotation", tilt, BURN_SECONDS).set_delay(delay)
	tween.tween_callback(ball.reset).set_delay(delay + BURN_SECONDS)

func _play_crown_taken() -> Tween:
	var tween: Tween = _new_step()
	var going: Array = _balls.slice(0, _shown) if !_ring_on else [_ring]
	for ball in going:
		tween.tween_property(ball, "modulate:a", 0.0, TAKEN_SECONDS)
		tween.tween_callback(ball.reset).set_delay(TAKEN_SECONDS)
	_ring_on = false
	_ring_lifted = false
	_shown = 0
	_sources.clear()
	return tween

func _get_aloft_z() -> int:
	return match_board.pieces_node.z_index + match_board.BOARD_SIZE * BoardConfig.DEPTH_Z_STRIDE + 10

# --- Where things are ---------------------------------------------------------

func get_row_screen_rect() -> Rect2:
	var rect := Rect2(_to_screen(_circle(_pits[0], PIT_RADIUS)[0]), Vector2.ZERO)
	for pit in _pits:
		for point in _circle(pit, PIT_RADIUS):
			rect = rect.expand(_to_screen(point))
	return rect.merge(get_groove_screen_rect())

func get_groove_screen_rect() -> Rect2:
	var outline: PackedVector2Array = _circle(_groove, GROOVE_OUTER_RADIUS)
	var rect := Rect2(_to_screen(outline[0]), Vector2.ZERO)
	for point in outline:
		rect = rect.expand(_to_screen(point))
	return rect

func _to_screen(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas() * point

func _rebuild() -> void:
	_built_view = _geometry.view_color
	_near = _geometry.get_near_direction_local()
	var pit_span: float = float(points_required - 1) * PIT_STEP
	var row_width: float = pit_span + PIT_RADIUS + GROOVE_GAP + GROOVE_OUTER_RADIUS * 2.0 + PIT_RADIUS
	var first_x: float = _get_row_centre_x() - row_width * 0.5 + PIT_RADIUS
	_pits.clear()
	for index in points_required:
		_pits.append(_on_owner_side(first_x + float(index) * PIT_STEP))
	_groove = _on_owner_side(first_x + pit_span + PIT_RADIUS + GROOVE_GAP + GROOVE_OUTER_RADIUS)

	# The camera turns over for the black side; what is on the board stands up
	# the same either way.
	var upright: float = PI if _built_view < 0 else 0.0
	while _balls.size() < points_required:
		var ball = CrownBall.new(CrownGold.ball_texture(), _light_texture, BALL_LIGHT_SCALE, BALL_LIGHT_ENERGY)
		add_child(ball)
		_balls.append(ball)
	for index in points_required:
		var pit: Vector2 = _pits[index]
		var sink: Vector2 = _near * PIT_DEPTH * 0.5 * _get_unit_at(pit).y
		_balls[index].rotation = upright
		_balls[index].set_rest(_project(pit) + sink, _get_picture_scale(pit, BALL_RADIUS, CrownGold.BALL_SIZE, true), BALL_GLOW_WIDTH)
	_ring.rotation = upright
	_ring.set_rest(_project(_groove), _get_picture_scale(_groove, RING_RADIUS, CrownGold.RING_SIZE, false), RING_GLOW_WIDTH, _get_lean_at(_groove))
	queue_redraw()
	rebuilt.emit()

## The whole row is a mirror through the board's middle: white's side, turned
## over, is black's.
func _on_owner_side(x: float) -> Vector2:
	return Vector2(x, _rim_y) * float(owner_color)

## The flat board's x that lands under this canvas x on the rim nearest the viewer.
func _get_row_centre_x() -> float:
	var near_point := Vector2(1.0, _rim_y * float(_built_view))
	var width_at_rim: float = absf(_project(near_point).x)
	return BoardCanvas.to_world(_row_centre_canvas_x - BoardCanvas.SIZE.x * 0.5) / width_at_rim

func _project(point: Vector2) -> Vector2:
	return _geometry.project_point_local(point, false)

## How wide and how deep one board unit comes out, here.
func _get_unit_at(point: Vector2) -> Vector2:
	return Vector2(
		(_project(point + Vector2.RIGHT) - _project(point - Vector2.RIGHT)).length(),
		(_project(point + Vector2.DOWN) - _project(point - Vector2.DOWN)).length()
	) * 0.5

## Off the middle of the board a circle on it leans towards the far end, the way
## the board's own sides do. Node2D.skew's angle.
func _get_lean_at(point: Vector2) -> float:
	var towards_viewer: Vector2 = _project(point + Vector2.DOWN) - _project(point - Vector2.DOWN)
	return atan2(-towards_viewer.x, towards_viewer.y)

## A ball is as round from anywhere; the ring lies on the board.
func _get_picture_scale(point: Vector2, radius: float, picture_size: int, round_picture: bool) -> Vector2:
	var unit: Vector2 = _get_unit_at(point)
	var picture_scale: Vector2 = unit * radius * 2.0 / float(picture_size)
	return Vector2.ONE * picture_scale.x if round_picture else picture_scale

func _settle_balls() -> void:
	for index in points_required:
		_balls[index].reset()
		_balls[index].visible = index < _shown and !_ring_on

func _settle_ring() -> void:
	if _playing:
		return
	_ring.visible = _ring_on and !_ring_lifted

# --- The cuts in the wood -----------------------------------------------------

func _draw() -> void:
	var wood: Color = match_board.BOARD_FRAME_COLOR
	var wall: Color = match_board.BOARD_SIDE_COLOR
	var pit_floor: Color = wall.lerp(wood, 0.28)
	var lip: Color = wood.lightened(0.16)
	for pit in _pits:
		_draw_cut(_circle(pit, PIT_RADIUS), pit, wall, pit_floor, lip)
	_draw_cut(_circle(_groove, GROOVE_OUTER_RADIUS), _groove, wall, pit_floor, lip)
	# The island in the groove, standing up out of its floor with its near side showing.
	var island: PackedVector2Array = _circle(_groove, GROOVE_INNER_RADIUS)
	_fill(_shifted(island, _near * PIT_DEPTH * _get_unit_at(_groove).y), wall)
	_fill(island, wood)

## From the board's angle the far wall of a pit shows and the near one does not:
## the floor is the same shape, slid towards the viewer, and only as far as it
## stays inside the pit's mouth.
func _draw_cut(mouth: PackedVector2Array, centre: Vector2, wall: Color, pit_floor: Color, lip: Color) -> void:
	var deep: float = _get_unit_at(centre).y
	_fill(_shifted(mouth, _near * LIP_DEPTH * deep), lip)
	_fill(mouth, wall)
	for floor_part in Geometry2D.intersect_polygons(mouth, _shifted(mouth, _near * PIT_DEPTH * deep)):
		_fill(floor_part, pit_floor)

func _fill(polygon: PackedVector2Array, colour: Color) -> void:
	draw_colored_polygon(polygon, colour)
	var closed: PackedVector2Array = polygon.duplicate()
	closed.append(polygon[0])
	draw_polyline(closed, colour, EDGE_WIDTH, true)

func _shifted(polygon: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	return Transform2D(0.0, by) * polygon

## A circle on the flat board, as it comes out in perspective.
func _circle(centre: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in CIRCLE_SEGMENTS:
		var angle: float = TAU * float(index) / float(CIRCLE_SEGMENTS)
		points.append(_project(centre + Vector2(cos(angle), sin(angle)) * radius))
	return points
