extends RefCounted

const DEBRIS_SHADER = preload("res://Shaders/piece_debris.gdshader")

# The chips that fly off a broken piece fall under a gravity of their own.
# Heights and fall speeds are in the board's local units as drawn (a piece
# stands about 24 tall); distances along the ground are on the board's plane
# before the perspective, where a square is `cell_width` across.
const DEBRIS_GRAVITY: float = 260.0
const DEBRIS_MIN_LAUNCH_RISE: float = 20.0
const DEBRIS_MAX_LAUNCH_RISE: float = 75.0
## About how long a chip is in the air before it first lands; with
## `scatter_radius` it sets how fast the chips leave.
const DEBRIS_FLIGHT_TIME: float = 0.5
## How far either side of the blow the chips thrown along it fan out, radians.
const DEBRIS_BLOW_SPREAD: float = 0.66
## The share of chips that spray off any way at all, slower, instead.
const DEBRIS_SPRAY_SHARE: float = 0.2
## Chips sitting further out on the piece fly off a little faster sideways.
const DEBRIS_OUTWARD_SPEED: float = 1.5
## What a bounce keeps of a chip's fall speed and of its speed along the ground.
const DEBRIS_BOUNCE_RISE_KEPT: float = 0.32
const DEBRIS_BOUNCE_GROUND_KEPT: float = 0.55
const DEBRIS_MAX_BOUNCES: int = 3
## A chip that would bounce up slower than this lies down instead.
const DEBRIS_MIN_BOUNCE_RISE: float = 16.0
const DEBRIS_SLIDE_FRICTION: float = 110.0
const DEBRIS_MAX_SPIN: float = 14.0
const DEBRIS_MIN_TURN_SPEED: float = 5.0
const DEBRIS_MAX_TURN_SPEED: float = 18.0
## How dark a chip gets turned edge-on, and how much darker its underside is.
const DEBRIS_EDGE_ON_SHADE: float = 0.6
const DEBRIS_UNDERSIDE_SHADE: float = 0.82
const DEBRIS_SIMULATION_DURATION: float = 1.2
const DEBRIS_SHADOW_COLOR: Color = Color(0.03, 0.025, 0.02, 0.26)
const DEBRIS_SHADOW_Z_OFFSET: int = -2
## Blotch size of the chips' soaking, in their own units (pixels of the
## drawing they broke off).
const DEBRIS_BLOT_SIZE: float = 40.0
## How quickly chips still lying about soak away once the next move begins.
const DEBRIS_CLEAR_DURATION: float = 0.25
# The bigger chips click as they first land: a piece set down, played high,
# short and quiet. A few to a break, so a burst ticks rather than rattles.
const DEBRIS_CLICK_SOUND: String = "piece_placed"
const DEBRIS_CLICK_MIN_PITCH: float = 1.9
const DEBRIS_CLICK_MAX_PITCH: float = 2.5
const DEBRIS_CLICK_VOLUME_DB: float = -14.0
const DEBRIS_CLICKS_PER_BREAK: int = 3
## A chip clicks if it is at least this far from the smallest size to the largest.
const DEBRIS_CLICK_SIZE_SHARE: float = 0.4

# The blot left on the square a piece broke on: ink soaked into the board,
# stretched along the blow, spreading for a moment and then soaking away.
# Painted onto the board, so below the grid (z 9) and the bomb warnings, but
# over the special tiles (z 1).
const STAIN_Z_INDEX: int = 2
const STAIN_COLOR: Color = Color(0.14, 0.11, 0.09, 0.22)
## Its half-width across the blow, as a share of a square.
const STAIN_RADIUS: float = 0.36
const STAIN_STRETCH: float = 1.35
const STAIN_SPREAD_DURATION: float = 0.35
const STAIN_SOAK_DURATION: float = 3.6
const STAIN_TEXTURE_SIZE: int = 128
const STAIN_BLOT_SIZE: float = 22.0
## Where its soaking starts: a little ink is already gone, so the blot's edge
## is ragged from the first.
const STAIN_FIRST_SOAK: float = 0.18

# A drawing's shape is read off a grid this fine, for where chips can come from.
const SHAPE_SAMPLE_COLUMNS: int = 12
const SHAPE_SAMPLE_ROWS: int = 20
const SHAPE_OPAQUE_ALPHA: float = 0.5

# The returning fragments are a fixed cut of the drawing, top and bottom
# halves in three pieces each, the same every time so that two halves broken
# off at different times still fit together.
const FRAGMENT_CUT_SEED: int = 4111
const FRAGMENT_CUT_HEIGHT: float = 0.5
## How far the cut lines zigzag, as a share of the drawing's size.
const FRAGMENT_CUT_JAG: float = 0.07

class DebrisChip:
	var node: Polygon2D
	var shadow: Polygon2D
	## On the board's plane, from the point under the piece's feet.
	var ground: Vector2
	var velocity: Vector2
	var height: float
	var rise_speed: float
	var spin_angle: float
	var spin: float
	## How far the chip has turned over about its own axis.
	var turn: float
	var turn_speed: float
	var bounces: int = 0
	var lying: bool = false
	var clicks: bool = false

class DebrisBurst:
	var chips: Array[DebrisChip] = []
	var ground_origin: Vector2
	## Board plane to local: a step along the plane's x and y, as drawn.
	var plane: Transform2D
	var up: Vector2
	var base_rotation: float
	var visual_scale: Vector2
	var time: float = 0.0
	var tween: Tween
	## The chips have come to rest; until then they are not cleared early.
	var settled: bool = false
	var clear_requested: bool = false
	var soak: float = 0.0
	var clicks_left: int = DEBRIS_CLICKS_PER_BREAK

var geometry
var piece_visuals
var pieces_node: Node
var piece_effects_node: Node
var tween_owner: Node
var board_size: int = BoardConfig.BOARD_SIZE
var cell_width: int = BoardConfig.CELL_WIDTH
var view_color: int = 1
var invalid_board_pos: Vector2 = Vector2(-1, -1)
var texture_filter_value = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
var piece_effect_light_receive_mask: int = 0
var flipped_view: bool = false

var returning_debris_count: int = 3
var scatter_duration: float = 0.46
var fade_duration: float = 0.42
var return_duration: float = 0.38
var return_fade_duration: float = 0.16
var fragment_settle_duration: float = 0.24
var scatter_radius: float = 0.84
var scatter_jitter: float = 0.28
var min_chip_size: float = 0.09
var max_chip_size: float = 0.26
var debris_linger_duration: float = 2.4
var avoid_occupied_cells: bool = true
var route_jitter_ratio: float = 0.12
var fragment_landing_hold_duration: float = 0.08
var route_z_front_offset: int = 2
var route_z_back_offset: int = -1
var route_direct_fallback_offset: float = 0.72
var return_acceleration_progress: float = 0.5
var fragment_group_bottom: String = "bottom"

var route_cell_blocked_provider: Callable = Callable()
var finish_respawn_fragment_callback: Callable = Callable()
var antialias_provider: Callable = Callable()

var texture_shapes: Dictionary = {}
var fragment_cuts: Dictionary = {}
var debris_bursts: Array[DebrisBurst] = []
var stains: Array[Sprite2D] = []
var debris_material: ShaderMaterial
var stain_material: ShaderMaterial
var stain_texture: Texture2D

func configure(config: Dictionary) -> void:
	geometry = config.get("geometry", geometry)
	piece_visuals = config.get("piece_visuals", piece_visuals)
	pieces_node = config.get("pieces_node", pieces_node)
	piece_effects_node = config.get("piece_effects_node", piece_effects_node)
	tween_owner = config.get("tween_owner", tween_owner)
	board_size = int(config.get("board_size", board_size))
	cell_width = int(config.get("cell_width", cell_width))
	view_color = -1 if int(config.get("view_color", view_color)) < 0 else 1
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)
	texture_filter_value = config.get("texture_filter", texture_filter_value)
	piece_effect_light_receive_mask = int(config.get("piece_effect_light_receive_mask", piece_effect_light_receive_mask))
	flipped_view = bool(config.get("flipped_view", flipped_view))

	returning_debris_count = int(config.get("returning_debris_count", returning_debris_count))
	scatter_duration = float(config.get("scatter_duration", scatter_duration))
	fade_duration = float(config.get("fade_duration", fade_duration))
	return_duration = float(config.get("return_duration", return_duration))
	return_fade_duration = float(config.get("return_fade_duration", return_fade_duration))
	fragment_settle_duration = float(config.get("fragment_settle_duration", fragment_settle_duration))
	scatter_radius = float(config.get("scatter_radius", scatter_radius))
	scatter_jitter = float(config.get("scatter_jitter", scatter_jitter))
	min_chip_size = float(config.get("min_chip_size", min_chip_size))
	max_chip_size = float(config.get("max_chip_size", max_chip_size))
	debris_linger_duration = float(config.get("debris_linger_duration", debris_linger_duration))
	avoid_occupied_cells = bool(config.get("avoid_occupied_cells", avoid_occupied_cells))
	route_jitter_ratio = float(config.get("route_jitter_ratio", route_jitter_ratio))
	fragment_landing_hold_duration = float(config.get("fragment_landing_hold_duration", fragment_landing_hold_duration))
	route_z_front_offset = int(config.get("route_z_front_offset", route_z_front_offset))
	route_z_back_offset = int(config.get("route_z_back_offset", route_z_back_offset))
	route_direct_fallback_offset = float(config.get("route_direct_fallback_offset", route_direct_fallback_offset))
	return_acceleration_progress = float(config.get("return_acceleration_progress", return_acceleration_progress))
	fragment_group_bottom = str(config.get("fragment_group_bottom", fragment_group_bottom))

	route_cell_blocked_provider = config.get("route_cell_blocked_provider", route_cell_blocked_provider)
	finish_respawn_fragment_callback = config.get("finish_respawn_fragment_callback", finish_respawn_fragment_callback)
	antialias_provider = config.get("antialias_provider", antialias_provider)

## One piece of `get_fragment_cut()` of `texture_value`, standing where the
## whole drawing would: it is drawn with the piece's own scale and offset, so
## the pieces of a cut laid side by side make up the piece.
func create_fragment(source_pos: Vector2, texture_value: Texture2D, cut_polygon: PackedVector2Array, fragment_index: int) -> Polygon2D:
	if texture_value == null or cut_polygon.size() < 3 or piece_effects_node == null or !is_instance_valid(piece_effects_node):
		return null
	if !MoveRules.is_valid_position(source_pos):
		return null

	var fragment: Polygon2D = create_fragment_node(texture_value, cut_polygon)
	fragment.name = "PieceShatterFragment_%d" % fragment_index
	fragment.position = get_position_local(source_pos)
	fragment.set_meta("board_pos", source_pos)
	fragment.z_index = get_z_index_for_local_position(fragment.position)
	apply_fragment_visual_size(fragment, source_pos)
	return fragment

func create_pending_edge_fragment_markers(piece_color: int, texture_value: Texture2D, cut_polygons: Array[PackedVector2Array]) -> Array[Polygon2D]:
	var fragments: Array[Polygon2D] = []
	if texture_value == null or piece_effects_node == null or !is_instance_valid(piece_effects_node):
		return fragments

	var home_pos: Vector2 = Vector2(BoardConfig.get_home_row_for_player_id(BoardConfig.get_player_id_for_color(piece_color)), BoardConfig.CENTER_INDEX)
	for fragment_index in range(cut_polygons.size()):
		if cut_polygons[fragment_index].size() < 3:
			continue

		var fragment: Polygon2D = create_fragment_node(texture_value, cut_polygons[fragment_index])
		fragment.name = "PendingRespawnFragment_%d" % fragment_index
		fragment.position = get_pending_respawn_edge_fragment_target(piece_color, fragment_index)
		fragment.z_index = get_z_index_for_local_position(fragment.position)
		apply_fragment_visual_size(fragment, home_pos)
		fragments.append(fragment)
	return fragments

func create_fragment_node(texture_value: Texture2D, cut_polygon: PackedVector2Array) -> Polygon2D:
	var fragment := Polygon2D.new()
	if flipped_view:
		fragment.global_rotation_degrees = 180
	piece_effects_node.add_child(fragment)
	fragment.light_mask = piece_effect_light_receive_mask
	fragment.texture_filter = texture_filter_value
	fragment.texture = texture_value
	# Centred on the texture, as a Sprite2D draws it, so the piece's offset
	# and scale place it the same way.
	var half_size: Vector2 = texture_value.get_size() * 0.5
	var points := PackedVector2Array()
	for point: Vector2 in cut_polygon:
		points.append(point - half_size)
	fragment.polygon = points
	fragment.uv = cut_polygon
	fragment.z_as_relative = false
	fragment.self_modulate = Color.WHITE
	# No antialiasing: its soft edge would show as a seam between fragments
	# lying side by side.
	return fragment

func animate_fragment(fragment: Polygon2D, scatter_target: Vector2, source_pos: Vector2, respawn_pos: Vector2, fragment_group: String, fragment_index: int) -> void:
	if fragment == null or !is_instance_valid(fragment) or !MoveRules.is_valid_position(respawn_pos):
		return

	var rest_rotation: float = fragment.rotation
	var target_transform: Dictionary = get_visual_transform_for_texture(fragment.texture, respawn_pos)
	var target_scale: Vector2 = target_transform.get("scale", fragment.scale)
	var target_offset: Vector2 = target_transform.get("offset", fragment.offset)
	var fall_duration: float = maxf(0.05, scatter_duration * 0.62)
	var bounce_duration: float = maxf(0.03, scatter_duration * 0.18)
	var roll_duration: float = maxf(0.03, scatter_duration * 0.20)
	var bounce_target: Vector2 = scatter_target + Vector2(randf_range(-5.0, 5.0), -randf_range(5.0, 10.0))
	var settled_target: Vector2 = scatter_target + Vector2(randf_range(-4.0, 4.0), randf_range(-2.0, 2.0))
	var scattered_rotation: float = rest_rotation + randf_range(-PI * 0.75, PI * 0.75)
	var settled_rotation: float = scattered_rotation + randf_range(-PI * 0.18, PI * 0.18)
	var return_path: Array[Vector2] = [settled_target]
	return_path.append_array(get_return_route_points(source_pos, respawn_pos, fragment_index))

	var tween: Tween = create_animation_tween()
	if tween == null:
		return
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(local_pos: Vector2): update_item_motion(fragment, local_pos), fragment.position, scatter_target, fall_duration)
	tween.parallel().tween_property(fragment, "rotation", scattered_rotation, fall_duration)
	tween.parallel().tween_property(fragment, "scale", fragment.scale * randf_range(0.92, 1.12), fall_duration)

	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_method(func(local_pos: Vector2): update_item_motion(fragment, local_pos), scatter_target, bounce_target, bounce_duration)
	tween.parallel().tween_property(fragment, "rotation", scattered_rotation + randf_range(-PI * 0.10, PI * 0.10), bounce_duration)

	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(func(local_pos: Vector2): update_item_motion(fragment, local_pos), bounce_target, settled_target, roll_duration)
	tween.parallel().tween_property(fragment, "rotation", settled_rotation, roll_duration)

	var rolling_player_box: Array = [null]
	tween.tween_interval(fragment_settle_duration)
	tween.tween_callback(func(): rolling_player_box[0] = SFXManager.play("piece_rolling"))
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(progress: float): update_respawn_path_motion(fragment, return_path, get_return_motion_progress(progress), respawn_pos), 0.0, 1.0, return_duration)
	tween.parallel().tween_property(fragment, "rotation", rest_rotation, return_duration)
	tween.parallel().tween_property(fragment, "scale", target_scale, return_duration)
	tween.parallel().tween_property(fragment, "offset", target_offset, return_duration)
	tween.tween_callback(func():
		var rolling_player: AudioStreamPlayer = rolling_player_box[0]
		if rolling_player != null:
			rolling_player.stop()
	)
	tween_respawn_finish_callback(tween, respawn_pos)
	if fragment_group == fragment_group_bottom:
		return

	tween.tween_interval(fragment_landing_hold_duration)
	tween.tween_property(fragment, "self_modulate:a", 0.0, return_fade_duration)
	tween.finished.connect(func():
		if is_instance_valid(fragment):
			fragment.queue_free()
	)

func animate_pending_edge_fragment(fragment: Polygon2D, scatter_target: Vector2, source_pos: Vector2, piece_color: int, fragment_index: int) -> void:
	if fragment == null or !is_instance_valid(fragment):
		return

	var rest_rotation: float = fragment.rotation
	var fall_duration: float = maxf(0.05, scatter_duration * 0.62)
	var bounce_duration: float = maxf(0.03, scatter_duration * 0.18)
	var roll_duration: float = maxf(0.03, scatter_duration * 0.20)
	var bounce_target: Vector2 = scatter_target + Vector2(randf_range(-5.0, 5.0), -randf_range(5.0, 10.0))
	var settled_target: Vector2 = scatter_target + Vector2(randf_range(-4.0, 4.0), randf_range(-2.0, 2.0))
	var edge_target: Vector2 = get_pending_respawn_edge_fragment_target(piece_color, fragment_index)
	var scattered_rotation: float = rest_rotation + randf_range(-PI * 0.75, PI * 0.75)
	var settled_rotation: float = scattered_rotation + randf_range(-PI * 0.18, PI * 0.18)
	var return_path: Array[Vector2] = [settled_target]
	return_path.append_array(get_edge_route_points(source_pos, edge_target, fragment_index))
	return_path.append(edge_target)

	var tween: Tween = create_animation_tween()
	if tween == null:
		return
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(local_pos: Vector2): update_item_motion(fragment, local_pos), fragment.position, scatter_target, fall_duration)
	tween.parallel().tween_property(fragment, "rotation", scattered_rotation, fall_duration)
	tween.parallel().tween_property(fragment, "scale", fragment.scale * randf_range(0.92, 1.12), fall_duration)

	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_method(func(local_pos: Vector2): update_item_motion(fragment, local_pos), scatter_target, bounce_target, bounce_duration)
	tween.parallel().tween_property(fragment, "rotation", scattered_rotation + randf_range(-PI * 0.10, PI * 0.10), bounce_duration)

	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(func(local_pos: Vector2): update_item_motion(fragment, local_pos), bounce_target, settled_target, roll_duration)
	tween.parallel().tween_property(fragment, "rotation", settled_rotation, roll_duration)

	var rolling_player_box: Array = [null]
	tween.tween_interval(fragment_settle_duration)
	tween.tween_callback(func(): rolling_player_box[0] = SFXManager.play("piece_rolling"))
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(progress: float): update_item_path_motion(fragment, return_path, get_return_motion_progress(progress)), 0.0, 1.0, return_duration)
	tween.parallel().tween_property(fragment, "rotation", rest_rotation, return_duration)
	tween.tween_callback(func():
		var rolling_player: AudioStreamPlayer = rolling_player_box[0]
		if rolling_player != null:
			rolling_player.stop()
	)

func animate_pending_edge_arrival_fragment(fragment: Polygon2D, respawn_pos: Vector2, fragment_group: String, fragment_index: int) -> void:
	if fragment == null or !is_instance_valid(fragment) or !MoveRules.is_valid_position(respawn_pos):
		return

	var rest_rotation: float = fragment.rotation
	var target_transform: Dictionary = get_visual_transform_for_texture(fragment.texture, respawn_pos)
	var target_scale: Vector2 = target_transform.get("scale", fragment.scale)
	var target_offset: Vector2 = target_transform.get("offset", fragment.offset)
	var start_pos: Vector2 = fragment.position
	var target_pos: Vector2 = get_position_local(respawn_pos)
	var path_points: Array[Vector2] = [start_pos]
	path_points.append_array(get_edge_route_points(get_nearest_board_position_for_local_position(start_pos), target_pos, fragment_index))
	path_points.append(target_pos)

	var tween: Tween = create_animation_tween()
	if tween == null:
		return
	var rolling_player_box: Array = [null]
	tween.tween_callback(func(): rolling_player_box[0] = SFXManager.play("piece_rolling"))
	tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(progress: float): update_respawn_path_motion(fragment, path_points, get_return_motion_progress(progress), respawn_pos), 0.0, 1.0, return_duration)
	tween.parallel().tween_property(fragment, "rotation", rest_rotation, return_duration)
	tween.parallel().tween_property(fragment, "scale", target_scale, return_duration)
	tween.parallel().tween_property(fragment, "offset", target_offset, return_duration)
	tween.tween_callback(func():
		var rolling_player: AudioStreamPlayer = rolling_player_box[0]
		if rolling_player != null:
			rolling_player.stop()
	)
	tween_respawn_finish_callback(tween, respawn_pos)
	if fragment_group == fragment_group_bottom:
		return

	tween.tween_interval(fragment_landing_hold_duration)
	tween.tween_property(fragment, "self_modulate:a", 0.0, return_fade_duration)
	tween.finished.connect(func():
		if is_instance_valid(fragment):
			fragment.queue_free()
	)

## Chips broken off `texture_value`, the drawing the piece at `source_pos`
## showed: each starts where it sat on the piece, is thrown along
## `blow_direction` (board steps, from the striker's square towards the
## piece's; zero throws them every way), bounces and slides to rest, then
## fades.
func play_debris(source_pos: Vector2, texture_value: Texture2D, chip_count: int, blow_direction: Vector2 = Vector2.ZERO) -> void:
	if texture_value == null or chip_count <= 0 or !MoveRules.is_valid_position(source_pos):
		return
	if piece_effects_node == null or !is_instance_valid(piece_effects_node):
		return

	var shape: Dictionary = get_texture_shape(texture_value)
	var opaque_points: PackedVector2Array = shape.get("opaque_points", PackedVector2Array())
	if opaque_points.is_empty():
		return
	var used_rect: Rect2 = shape.get("used_rect", Rect2())
	var sample_cell: Vector2 = used_rect.size / Vector2(SHAPE_SAMPLE_COLUMNS, SHAPE_SAMPLE_ROWS)
	var visual_transform: Dictionary = get_visual_transform_for_texture(texture_value, source_pos)

	var burst := DebrisBurst.new()
	burst.visual_scale = visual_transform.get("scale", Vector2.ONE)
	burst.base_rotation = PI if flipped_view else 0.0
	burst.up = get_screen_up()
	burst.plane = get_board_plane_transform(source_pos)
	var visual_offset: Vector2 = visual_transform.get("offset", Vector2.ZERO)
	var piece_position: Vector2 = get_position_local(source_pos)
	var feet_point := Vector2(used_rect.get_center().x, used_rect.end.y)
	burst.ground_origin = piece_position + get_texture_point_local(feet_point, texture_value, burst.visual_scale, visual_offset, burst.base_rotation)
	var to_plane: Transform2D = burst.plane.affine_inverse()

	var flat_blow := Vector2.ZERO
	if blow_direction != Vector2.ZERO:
		flat_blow = (BoardConfig.get_cell_center_local(source_pos + blow_direction) - BoardConfig.get_cell_center_local(source_pos)).normalized()
	var base_speed: float = float(cell_width) * scatter_radius / DEBRIS_FLIGHT_TIME
	var chip_size_min: float = minf(min_chip_size, max_chip_size)
	var chip_size_max: float = maxf(min_chip_size, max_chip_size)

	for chip_index in range(chip_count):
		var chip_center: Vector2 = opaque_points[randi() % opaque_points.size()]
		chip_center += Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)) * sample_cell
		# Mostly small, the odd bigger one.
		var size_share: float = pow(randf(), 1.5)
		var radius: float = used_rect.size.y * lerpf(chip_size_min, chip_size_max, size_share) * 0.5

		var chip := DebrisChip.new()
		chip.node = create_debris_chip_node(texture_value, chip_center, radius, chip_index)
		chip.shadow = create_debris_shadow_node(radius * absf(burst.visual_scale.x), chip_index)

		var from_feet: Vector2 = piece_position + get_texture_point_local(chip_center, texture_value, burst.visual_scale, visual_offset, burst.base_rotation) - burst.ground_origin
		chip.height = maxf(0.0, from_feet.dot(burst.up))
		chip.ground = to_plane.basis_xform(from_feet - burst.up * from_feet.dot(burst.up))

		var direction: Vector2
		var speed: float
		if flat_blow == Vector2.ZERO:
			direction = Vector2.RIGHT.rotated(randf() * TAU)
			speed = base_speed * randf_range(0.4, 1.1)
		elif randf() < DEBRIS_SPRAY_SHARE:
			direction = Vector2.RIGHT.rotated(randf() * TAU)
			speed = base_speed * randf_range(0.15, 0.55)
		else:
			# Bunched towards the line of the blow rather than spread evenly.
			direction = flat_blow.rotated(randf_range(-DEBRIS_BLOW_SPREAD, DEBRIS_BLOW_SPREAD) * randf())
			speed = base_speed * randf_range(0.55, 1.35)
		chip.velocity = direction * speed + chip.ground * DEBRIS_OUTWARD_SPEED
		chip.rise_speed = randf_range(DEBRIS_MIN_LAUNCH_RISE, DEBRIS_MAX_LAUNCH_RISE)
		chip.spin = randf_range(-DEBRIS_MAX_SPIN, DEBRIS_MAX_SPIN)
		chip.turn_speed = randf_range(DEBRIS_MIN_TURN_SPEED, DEBRIS_MAX_TURN_SPEED) * (1.0 if randf() < 0.5 else -1.0)
		chip.clicks = size_share >= DEBRIS_CLICK_SIZE_SHARE
		burst.chips.append(chip)
		place_debris_chip(burst, chip)

	play_stain(burst.ground_origin, burst.plane, flat_blow)

	burst.tween = create_animation_tween()
	if burst.tween == null:
		free_debris(burst)
		return
	debris_bursts.append(burst)
	burst.tween.tween_method(func(time: float): step_debris(burst, time), 0.0, DEBRIS_SIMULATION_DURATION, DEBRIS_SIMULATION_DURATION)
	burst.tween.tween_callback(func(): settle_debris(burst))

## The chips have come to rest: they lie for the rest of
## `debris_linger_duration`, then soak into the paper - at once if the next
## move began while they were still flying.
func settle_debris(burst: DebrisBurst) -> void:
	burst.settled = true
	if burst.clear_requested:
		soak_debris(burst, 0.0, DEBRIS_CLEAR_DURATION)
	else:
		soak_debris(burst, maxf(0.0, debris_linger_duration - DEBRIS_SIMULATION_DURATION), fade_duration)

func soak_debris(burst: DebrisBurst, delay: float, duration: float) -> void:
	if burst.tween != null and burst.tween.is_valid():
		burst.tween.kill()
	burst.tween = create_animation_tween()
	if burst.tween == null:
		free_debris(burst)
		return
	if delay > 0.0:
		burst.tween.tween_interval(delay)
	burst.tween.tween_method(func(soak: float): set_debris_soak(burst, soak), burst.soak, 1.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	burst.tween.tween_callback(func(): free_debris(burst))

func set_debris_soak(burst: DebrisBurst, soak: float) -> void:
	burst.soak = soak
	for chip: DebrisChip in burst.chips:
		if is_instance_valid(chip.node):
			chip.node.set_instance_shader_parameter(&"soak", soak)
		if is_instance_valid(chip.shadow):
			chip.shadow.modulate.a = 1.0 - soak

## The next move is beginning: chips lying about soak away quickly, and those
## still in the air as soon as they land, so the board reads clearly again.
## The blots go on soaking in at their own pace.
func soak_away_debris() -> void:
	for burst: DebrisBurst in debris_bursts.duplicate():
		if burst.clear_requested:
			continue
		burst.clear_requested = true
		if burst.settled:
			soak_debris(burst, 0.0, DEBRIS_CLEAR_DURATION)

## For a board replaced wholesale: every chip and blot gone at once.
func clear_debris() -> void:
	for burst: DebrisBurst in debris_bursts.duplicate():
		if burst.tween != null and burst.tween.is_valid():
			burst.tween.kill()
		free_debris(burst)
	for stain: Sprite2D in stains:
		if is_instance_valid(stain):
			stain.queue_free()
	stains.clear()

func get_debris_material() -> ShaderMaterial:
	if debris_material == null:
		debris_material = ShaderMaterial.new()
		debris_material.shader = DEBRIS_SHADER
		debris_material.set_shader_parameter(&"blot_size", DEBRIS_BLOT_SIZE)
	return debris_material

## The blot on the square under the broken piece, stretched along the blow on
## the board's plane: it spreads out quickly, then soaks in.
func play_stain(ground_origin: Vector2, plane: Transform2D, flat_blow: Vector2) -> void:
	var along: Vector2 = flat_blow if flat_blow != Vector2.ZERO else Vector2.RIGHT.rotated(randf() * TAU)
	along = along.rotated(randf_range(-0.3, 0.3))
	var radius: float = float(cell_width) * STAIN_RADIUS
	var half_texture: float = float(STAIN_TEXTURE_SIZE) * 0.5
	var x_axis: Vector2 = plane.basis_xform(along) * radius * STAIN_STRETCH / half_texture
	var y_axis: Vector2 = plane.basis_xform(along.orthogonal()) * radius / half_texture
	# Leaning the way the blow sent the pieces.
	var center: Vector2 = ground_origin + plane.basis_xform(along * radius * 0.35 if flat_blow != Vector2.ZERO else Vector2.ZERO)

	var stain := Sprite2D.new()
	stain.name = "PieceShatterStain"
	stain.texture = get_stain_texture()
	stain.material = get_stain_material()
	stain.self_modulate = STAIN_COLOR
	stain.modulate.a = 0.0
	stain.light_mask = 0
	stain.z_as_relative = false
	stain.z_index = STAIN_Z_INDEX
	piece_effects_node.add_child(stain)
	stain.set_instance_shader_parameter(&"soak_seed", randf() * 10.0)
	set_stain_soak(stain, STAIN_FIRST_SOAK)
	set_stain_spread(stain, x_axis, y_axis, center, 0.7)
	stains.append(stain)

	# The stain's own tween: a board replaced under it (clear_debris) frees the
	# stain half way through, and the tween has to go with it.
	var tween: Tween = stain.create_tween()
	tween.tween_method(func(spread: float): set_stain_spread(stain, x_axis, y_axis, center, spread), 0.7, 1.0, STAIN_SPREAD_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(stain, "modulate:a", 1.0, STAIN_SPREAD_DURATION * 0.3)
	tween.tween_method(func(soak: float): set_stain_soak(stain, soak), STAIN_FIRST_SOAK, 1.0, STAIN_SOAK_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func():
		stains.erase(stain)
		if is_instance_valid(stain):
			stain.queue_free()
	)

func set_stain_spread(stain: Sprite2D, x_axis: Vector2, y_axis: Vector2, center: Vector2, spread: float) -> void:
	if is_instance_valid(stain):
		stain.transform = Transform2D(x_axis * spread, y_axis * spread, center)

func set_stain_soak(stain: Sprite2D, soak: float) -> void:
	if is_instance_valid(stain):
		stain.set_instance_shader_parameter(&"soak", soak)

func get_stain_material() -> ShaderMaterial:
	if stain_material == null:
		stain_material = ShaderMaterial.new()
		stain_material.shader = DEBRIS_SHADER
		stain_material.set_shader_parameter(&"blot_size", STAIN_BLOT_SIZE)
	return stain_material

## A soft round blot, white, tinted by `STAIN_COLOR`; its ragged edge comes
## from the soaking.
func get_stain_texture() -> Texture2D:
	if stain_texture != null:
		return stain_texture

	var image := Image.create(STAIN_TEXTURE_SIZE, STAIN_TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	var half_size: float = float(STAIN_TEXTURE_SIZE) * 0.5
	for y in range(STAIN_TEXTURE_SIZE):
		for x in range(STAIN_TEXTURE_SIZE):
			var distance: float = Vector2(float(x) + 0.5 - half_size, float(y) + 0.5 - half_size).length() / half_size
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, 1.0 - smoothstep(0.55, 1.0, distance)))
	stain_texture = ImageTexture.create_from_image(image)
	return stain_texture

func create_debris_chip_node(texture_value: Texture2D, chip_center: Vector2, radius: float, chip_index: int) -> Polygon2D:
	var texture_rect := Rect2(Vector2.ZERO, texture_value.get_size())
	var chip := Polygon2D.new()
	chip.name = "PieceShatterChip_%d" % chip_index
	chip.texture = texture_value
	chip.texture_filter = texture_filter_value
	chip.light_mask = piece_effect_light_receive_mask
	chip.z_as_relative = false
	chip.material = get_debris_material()
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	var point_count: int = randi_range(3, 5)
	var stretch := Vector2(1.0, randf_range(0.45, 1.0))
	var tilt: float = randf() * TAU
	for point_index in range(point_count):
		var angle: float = TAU * float(point_index) / float(point_count) + randf_range(-0.3, 0.3)
		var point: Vector2 = (Vector2(cos(angle), sin(angle)) * stretch * radius * randf_range(0.6, 1.08)).rotated(tilt)
		var texture_point: Vector2 = (chip_center + point).clamp(texture_rect.position, texture_rect.end)
		uv.append(texture_point)
		points.append(texture_point - chip_center)
	chip.polygon = points
	chip.uv = uv
	enable_antialiasing(chip)
	piece_effects_node.add_child(chip)
	chip.set_instance_shader_parameter(&"soak_seed", randf() * 10.0)
	return chip

func create_debris_shadow_node(radius: float, chip_index: int) -> Polygon2D:
	var shadow := Polygon2D.new()
	shadow.name = "PieceShatterChipShadow_%d" % chip_index
	shadow.color = DEBRIS_SHADOW_COLOR
	shadow.light_mask = 0
	shadow.z_as_relative = false
	var points := PackedVector2Array()
	for point_index in range(10):
		var angle: float = TAU * float(point_index) / 10.0
		points.append(Vector2(cos(angle), sin(angle) * 0.45) * radius * 0.9)
	shadow.polygon = points
	enable_antialiasing(shadow)
	piece_effects_node.add_child(shadow)
	return shadow

func step_debris(burst: DebrisBurst, time: float) -> void:
	var delta: float = maxf(0.0, time - burst.time)
	burst.time = time
	for chip: DebrisChip in burst.chips:
		var landed: bool = advance_debris_chip(chip, delta)
		if landed and chip.clicks and chip.bounces == 1 and burst.clicks_left > 0:
			burst.clicks_left -= 1
			SFXManager.play_pitched(DEBRIS_CLICK_SOUND, randf_range(DEBRIS_CLICK_MIN_PITCH, DEBRIS_CLICK_MAX_PITCH), DEBRIS_CLICK_VOLUME_DB)
		place_debris_chip(burst, chip)

## Moves a chip on by `delta`; true on the step it hits the ground.
func advance_debris_chip(chip: DebrisChip, delta: float) -> bool:
	if !chip.lying:
		chip.rise_speed -= DEBRIS_GRAVITY * delta
		chip.height += chip.rise_speed * delta
		chip.ground += chip.velocity * delta
		chip.spin_angle += chip.spin * delta
		chip.turn += chip.turn_speed * delta
		if chip.height > 0.0 or chip.rise_speed >= 0.0:
			return false

		chip.height = 0.0
		chip.bounces += 1
		var bounce_rise: float = -chip.rise_speed * DEBRIS_BOUNCE_RISE_KEPT
		chip.velocity *= DEBRIS_BOUNCE_GROUND_KEPT
		chip.spin *= 0.5
		chip.turn_speed *= 0.4
		if chip.bounces >= DEBRIS_MAX_BOUNCES or bounce_rise < DEBRIS_MIN_BOUNCE_RISE:
			chip.lying = true
			chip.rise_speed = 0.0
		else:
			chip.rise_speed = bounce_rise
		return true

	# Lying: it slides to a stop and settles face up or face down.
	var speed: float = maxf(0.0, chip.velocity.length() - DEBRIS_SLIDE_FRICTION * delta)
	chip.velocity = chip.velocity.normalized() * speed
	chip.ground += chip.velocity * delta
	chip.spin *= exp(-8.0 * delta)
	chip.spin_angle += chip.spin * delta
	chip.turn = lerpf(chip.turn, roundf(chip.turn / PI) * PI, 1.0 - exp(-14.0 * delta))
	return false

func place_debris_chip(burst: DebrisBurst, chip: DebrisChip) -> void:
	if !is_instance_valid(chip.node) or !is_instance_valid(chip.shadow):
		return

	var ground_local: Vector2 = burst.ground_origin + burst.plane.basis_xform(chip.ground)
	chip.node.position = ground_local + burst.up * chip.height
	chip.node.rotation = burst.base_rotation + chip.spin_angle
	# Turning over about its own axis: squeezed edge-on, mirrored past it.
	var facing: float = cos(chip.turn)
	var facing_sign: float = 1.0 if facing >= 0.0 else -1.0
	chip.node.scale = Vector2(burst.visual_scale.x * facing_sign * maxf(absf(facing), 0.06), burst.visual_scale.y)
	var shade: float = lerpf(DEBRIS_EDGE_ON_SHADE, 1.0, absf(facing)) * (1.0 if facing >= 0.0 else DEBRIS_UNDERSIDE_SHADE)
	chip.node.self_modulate = Color(shade, shade, shade, 1.0)
	chip.node.z_index = get_z_index_for_local_position(ground_local)

	chip.shadow.position = ground_local
	chip.shadow.z_index = get_ground_shadow_z_index(ground_local)
	var lift: float = clampf(chip.height / float(cell_width), 0.0, 1.0)
	chip.shadow.scale = Vector2.ONE * lerpf(1.0, 0.55, lift)
	chip.shadow.self_modulate.a = lerpf(1.0, 0.35, lift)

func free_debris(burst: DebrisBurst) -> void:
	for chip: DebrisChip in burst.chips:
		if is_instance_valid(chip.node):
			chip.node.queue_free()
		if is_instance_valid(chip.shadow):
			chip.shadow.queue_free()
	burst.chips.clear()
	debris_bursts.erase(burst)

## Where pixel `texture_point` of a piece's drawing is drawn, from the piece's
## position, for a Sprite2D centred on the texture.
func get_texture_point_local(texture_point: Vector2, texture_value: Texture2D, visual_scale: Vector2, visual_offset: Vector2, base_rotation: float) -> Vector2:
	return ((texture_point - texture_value.get_size() * 0.5 + visual_offset) * visual_scale).rotated(base_rotation)

## The board's plane around `board_pos` as drawn: a step along its x and y,
## perspective included. Taken as flat over the square or two debris crosses.
func get_board_plane_transform(board_pos: Vector2) -> Transform2D:
	var center: Vector2 = BoardConfig.get_cell_center_local(board_pos)
	if geometry == null:
		return Transform2D.IDENTITY
	var projected_center: Vector2 = geometry.project_point_local(center, false)
	return Transform2D(
		geometry.project_point_local(center + Vector2.RIGHT, false) - projected_center,
		geometry.project_point_local(center + Vector2.DOWN, false) - projected_center,
		Vector2.ZERO
	)

## Up on screen, in local units: the camera is turned round for the second
## player, and pieces with it.
func get_screen_up() -> Vector2:
	return Vector2.DOWN if flipped_view else Vector2.UP

## Where a drawing has ink, read once per texture: the rectangle it fills and
## a grid of points inside it that are not transparent.
func get_texture_shape(texture_value: Texture2D) -> Dictionary:
	if texture_shapes.has(texture_value):
		return texture_shapes[texture_value]

	var used_rect := Rect2(Vector2.ZERO, texture_value.get_size())
	var image: Image = texture_value.get_image()
	if image != null and image.is_compressed():
		image.decompress()
	var can_read: bool = image != null and !image.is_empty() and !image.is_compressed() and Vector2(image.get_size()) == used_rect.size
	if can_read:
		var image_used_rect: Rect2i = image.get_used_rect()
		if image_used_rect.has_area():
			used_rect = Rect2(image_used_rect)

	var opaque_points := PackedVector2Array()
	for row in range(SHAPE_SAMPLE_ROWS):
		for column in range(SHAPE_SAMPLE_COLUMNS):
			var point: Vector2 = used_rect.position + used_rect.size * Vector2((float(column) + 0.5) / SHAPE_SAMPLE_COLUMNS, (float(row) + 0.5) / SHAPE_SAMPLE_ROWS)
			if !can_read or image.get_pixelv(Vector2i(point)).a >= SHAPE_OPAQUE_ALPHA:
				opaque_points.append(point)

	var shape := {
		"used_rect": used_rect,
		"opaque_points": opaque_points,
	}
	texture_shapes[texture_value] = shape
	return shape

## `texture_value`'s drawing cut into six, in texture pixels: top left, top
## centre, top right, then the bottom three. Neighbours share their edges
## exactly, so the pieces fit back together without a gap.
func get_fragment_cut(texture_value: Texture2D) -> Array[PackedVector2Array]:
	if !fragment_cuts.has(texture_value):
		fragment_cuts[texture_value] = build_fragment_cut(texture_value)
	return fragment_cuts[texture_value].polygons

## Where `texture_value`'s drawing cracks before it breaks: the lines of its
## `get_fragment_cut()` and a few short cracks off them, as segments (from in
## xy, to in zw) in texture pixels.
func get_fragment_crack_segments(texture_value: Texture2D) -> PackedVector4Array:
	get_fragment_cut(texture_value)
	var segments := PackedVector4Array()
	for line: PackedVector2Array in fragment_cuts[texture_value].crack_lines:
		for index in range(line.size() - 1):
			segments.append(Vector4(line[index].x, line[index].y, line[index + 1].x, line[index + 1].y))
	return segments

func build_fragment_cut(texture_value: Texture2D) -> Dictionary:

	var texture_rect := Rect2(Vector2.ZERO, texture_value.get_size())
	var used_rect: Rect2 = get_texture_shape(texture_value).get("used_rect", texture_rect)
	var area: Rect2 = used_rect.grow(2.0).intersection(texture_rect)
	var jag: Vector2 = area.size * FRAGMENT_CUT_JAG
	var rng := RandomNumberGenerator.new()
	rng.seed = FRAGMENT_CUT_SEED

	var left: float = area.position.x
	var right: float = area.end.x
	var top: float = area.position.y
	var bottom: float = area.end.y
	var middle: float = top + area.size.y * FRAGMENT_CUT_HEIGHT
	var third: float = area.size.x / 3.0
	var top_left := Vector2(left, top)
	var top_right := Vector2(right, top)
	var bottom_left := Vector2(left, bottom)
	var bottom_right := Vector2(right, bottom)
	var middle_left := Vector2(left, middle + rng.randf_range(-jag.y, jag.y))
	var middle_right := Vector2(right, middle + rng.randf_range(-jag.y, jag.y))
	var middle_1 := Vector2(left + third + rng.randf_range(-jag.x, jag.x), middle + rng.randf_range(-jag.y, jag.y))
	var middle_2 := Vector2(left + third * 2.0 + rng.randf_range(-jag.x, jag.x), middle + rng.randf_range(-jag.y, jag.y))
	var top_1 := Vector2(left + third + rng.randf_range(-jag.x, jag.x), top)
	var top_2 := Vector2(left + third * 2.0 + rng.randf_range(-jag.x, jag.x), top)
	var bottom_1 := Vector2(left + third + rng.randf_range(-jag.x, jag.x), bottom)
	var bottom_2 := Vector2(left + third * 2.0 + rng.randf_range(-jag.x, jag.x), bottom)

	var across_0: PackedVector2Array = get_jagged_cut(middle_left, middle_1, jag.y, rng, area)
	var across_1: PackedVector2Array = get_jagged_cut(middle_1, middle_2, jag.y, rng, area)
	var across_2: PackedVector2Array = get_jagged_cut(middle_2, middle_right, jag.y, rng, area)
	var down_1_top: PackedVector2Array = get_jagged_cut(top_1, middle_1, jag.x, rng, area)
	var down_1_bottom: PackedVector2Array = get_jagged_cut(middle_1, bottom_1, jag.x, rng, area)
	var down_2_top: PackedVector2Array = get_jagged_cut(top_2, middle_2, jag.x, rng, area)
	var down_2_bottom: PackedVector2Array = get_jagged_cut(middle_2, bottom_2, jag.x, rng, area)

	var cut: Array[PackedVector2Array] = [
		join_cut_edges([PackedVector2Array([top_left]), down_1_top, reversed_cut(across_0)]),
		join_cut_edges([down_2_top, reversed_cut(across_1), reversed_cut(down_1_top)]),
		join_cut_edges([PackedVector2Array([top_2, top_right, middle_right]), reversed_cut(across_2), reversed_cut(down_2_top)]),
		join_cut_edges([across_0, down_1_bottom, PackedVector2Array([bottom_left])]),
		join_cut_edges([across_1, down_2_bottom, reversed_cut(down_1_bottom)]),
		join_cut_edges([across_2, PackedVector2Array([bottom_right]), reversed_cut(down_2_bottom)]),
	]

	var crack_lines: Array[PackedVector2Array] = [across_0, across_1, across_2, down_1_top, down_1_bottom, down_2_top, down_2_bottom]
	# A few short cracks branching off the cut, so that it reads as broken
	# rather than ruled.
	for line: PackedVector2Array in [across_1, down_1_top, down_2_bottom]:
		var from: Vector2 = line[rng.randi_range(1, line.size() - 2)]
		var turn: float = rng.randf_range(0.6, 1.1) * (1.0 if rng.randf() < 0.5 else -1.0)
		var heading: Vector2 = (line[line.size() - 1] - line[0]).normalized().rotated(turn)
		var to: Vector2 = (from + heading * area.size.y * rng.randf_range(0.05, 0.09)).clamp(area.position, area.end)
		crack_lines.append(PackedVector2Array([from, to]))

	return {
		"polygons": cut,
		"crack_lines": crack_lines,
	}

## A cut line from `from` to `to` with two kinks, pushed at most `amount`
## either side.
func get_jagged_cut(from: Vector2, to: Vector2, amount: float, rng: RandomNumberGenerator, area: Rect2) -> PackedVector2Array:
	var side: Vector2 = (to - from).orthogonal().normalized()
	var points := PackedVector2Array([from])
	for kink in [0.36, 0.68]:
		var point: Vector2 = from.lerp(to, kink + rng.randf_range(-0.08, 0.08)) + side * rng.randf_range(-amount, amount)
		points.append(point.clamp(area.position, area.end))
	points.append(to)
	return points

func reversed_cut(points: PackedVector2Array) -> PackedVector2Array:
	var reversed := points.duplicate()
	reversed.reverse()
	return reversed

## Edges walked round a fragment, one after another, with the corner each
## shares with the next (and the last with the first) kept once.
func join_cut_edges(edges: Array) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for edge: PackedVector2Array in edges:
		for point: Vector2 in edge:
			if polygon.is_empty() or !polygon[polygon.size() - 1].is_equal_approx(point):
				polygon.append(point)
	if polygon.size() > 1 and polygon[0].is_equal_approx(polygon[polygon.size() - 1]):
		polygon.remove_at(polygon.size() - 1)
	return polygon

func get_return_route_points(source_pos: Vector2, respawn_pos: Vector2, fragment_index: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if !MoveRules.is_valid_position(respawn_pos):
		return points

	var route_cells: Array[Vector2] = get_route_cells(source_pos, respawn_pos)
	if route_cells.size() > 2:
		for route_index in range(1, route_cells.size() - 1):
			points.append(get_route_cell_local_point(route_cells[route_index], fragment_index, route_index))
	else:
		points.append_array(get_direct_fallback_route_points(source_pos, respawn_pos, fragment_index))

	points.append(get_position_local(respawn_pos))
	return points

func get_route_cells(source_pos: Vector2, respawn_pos: Vector2) -> Array[Vector2]:
	var fallback: Array[Vector2] = []
	if MoveRules.is_valid_position(source_pos):
		fallback.append(source_pos)
	if MoveRules.is_valid_position(respawn_pos) and respawn_pos != source_pos:
		fallback.append(respawn_pos)
	if !avoid_occupied_cells or !MoveRules.is_valid_position(source_pos) or !MoveRules.is_valid_position(respawn_pos):
		return fallback

	var open_cells: Array[Vector2] = [source_pos]
	var came_from: Dictionary = {}
	came_from[source_pos] = invalid_board_pos
	while !open_cells.is_empty():
		var current_pos: Vector2 = open_cells.pop_front()
		if current_pos == respawn_pos:
			return reconstruct_route_cells(came_from, respawn_pos)

		for direction: Vector2 in get_route_directions(current_pos, respawn_pos):
			var next_pos: Vector2 = current_pos + direction
			if came_from.has(next_pos):
				continue
			if is_route_cell_blocked(next_pos, source_pos, respawn_pos):
				continue
			if absf(direction.x) > 0.0 and absf(direction.y) > 0.0:
				var horizontal_pos: Vector2 = current_pos + Vector2(direction.x, 0.0)
				var vertical_pos: Vector2 = current_pos + Vector2(0.0, direction.y)
				if is_route_cell_blocked(horizontal_pos, source_pos, respawn_pos) and is_route_cell_blocked(vertical_pos, source_pos, respawn_pos):
					continue

			came_from[next_pos] = current_pos
			open_cells.append(next_pos)

	return fallback

func reconstruct_route_cells(came_from: Dictionary, end_pos: Vector2) -> Array[Vector2]:
	var route: Array[Vector2] = []
	var current_pos: Vector2 = end_pos
	while MoveRules.is_valid_position(current_pos):
		route.push_front(current_pos)
		current_pos = BoardConfig.value_to_vector2(came_from.get(current_pos, invalid_board_pos), invalid_board_pos)
	return route

func get_route_directions(current_pos: Vector2, target_pos: Vector2) -> Array[Vector2]:
	var directions: Array[Vector2] = [
		Vector2(-1, 0),
		Vector2(1, 0),
		Vector2(0, -1),
		Vector2(0, 1),
		Vector2(-1, -1),
		Vector2(-1, 1),
		Vector2(1, -1),
		Vector2(1, 1),
	]
	directions.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return (current_pos + a).distance_squared_to(target_pos) < (current_pos + b).distance_squared_to(target_pos)
	)
	return directions

func get_route_cell_local_point(board_pos: Vector2, fragment_index: int, route_index: int) -> Vector2:
	var center: Vector2 = get_position_local(board_pos)
	var jitter_radius: float = float(cell_width) * route_jitter_ratio * get_perspective_scale(board_pos)
	if jitter_radius <= 0.0:
		return center
	var jitter_angle: float = randf_range(0.0, TAU) + float(fragment_index + route_index) * 0.37
	var jitter := Vector2(cos(jitter_angle), sin(jitter_angle) * 0.65) * randf_range(jitter_radius * 0.35, jitter_radius)
	return center + jitter

func get_direct_fallback_route_points(source_pos: Vector2, respawn_pos: Vector2, fragment_index: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if !MoveRules.is_valid_position(source_pos) or !MoveRules.is_valid_position(respawn_pos) or source_pos == respawn_pos:
		return points

	var source_center: Vector2 = get_position_local(source_pos)
	var target_center: Vector2 = get_position_local(respawn_pos)
	var travel: Vector2 = target_center - source_center
	if travel.length_squared() <= 0.001:
		return points

	var side_sign: float = 1.0 if fragment_index % 2 == 0 else -1.0
	var perpendicular: Vector2 = Vector2(-travel.y, travel.x).normalized() * side_sign
	var route_offset: Vector2 = perpendicular * float(cell_width) * route_direct_fallback_offset
	points.append(source_center.lerp(target_center, 0.36) + route_offset)
	points.append(source_center.lerp(target_center, 0.68) + route_offset * 0.58)
	return points

func get_pending_respawn_edge_anchor_local(piece_color: int) -> Vector2:
	var player_id: int = BoardConfig.get_player_id_for_color(piece_color)
	var home_row: int = BoardConfig.get_home_row_for_player_id(player_id)
	var home_pos: Vector2 = Vector2(home_row, BoardConfig.CENTER_INDEX)
	var inside_row: int = clampi(home_row + (1 if home_row == 0 else -1), 0, board_size - 1)
	var inside_pos: Vector2 = Vector2(inside_row, BoardConfig.CENTER_INDEX)
	var home_center: Vector2 = get_position_local(home_pos)
	var inside_center: Vector2 = get_position_local(inside_pos)
	var outward: Vector2 = home_center - inside_center
	if outward.length_squared() <= 0.001:
		outward = Vector2(0.0, 1.0 if home_row == 0 else -1.0)
	return home_center + outward.normalized() * float(cell_width) * 1.15

func get_pending_respawn_edge_fragment_target(piece_color: int, fragment_index: int) -> Vector2:
	var anchor: Vector2 = get_pending_respawn_edge_anchor_local(piece_color)
	var player_id: int = BoardConfig.get_player_id_for_color(piece_color)
	var home_row: int = BoardConfig.get_home_row_for_player_id(player_id)
	var home_center: Vector2 = get_position_local(Vector2(home_row, BoardConfig.CENTER_INDEX))
	var outward: Vector2 = anchor - home_center
	if outward.length_squared() <= 0.001:
		outward = Vector2(0.0, 1.0)
	outward = outward.normalized()
	var tangent := Vector2(-outward.y, outward.x)
	var spread_offset: float = float(fragment_index - 1) * float(cell_width) * 0.26
	var depth_offset: float = float((fragment_index % 2) - 0.5) * float(cell_width) * 0.10
	return anchor + tangent * spread_offset + outward * depth_offset

func get_edge_route_points(source_pos: Vector2, target_local_pos: Vector2, fragment_index: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if !MoveRules.is_valid_position(source_pos):
		return points

	var source_center: Vector2 = get_position_local(source_pos)
	var travel: Vector2 = target_local_pos - source_center
	if travel.length_squared() <= 0.001:
		return points

	var side_sign: float = 1.0 if fragment_index % 2 == 0 else -1.0
	var perpendicular: Vector2 = Vector2(-travel.y, travel.x).normalized() * side_sign
	var route_offset: Vector2 = perpendicular * float(cell_width) * route_direct_fallback_offset
	points.append(source_center.lerp(target_local_pos, 0.42) + route_offset)
	points.append(source_center.lerp(target_local_pos, 0.72) + route_offset * 0.48)
	return points

## With a `blow_direction` (board steps), the first indices go to the squares
## most nearly along it, so the fragments fly on the way the blow sent them.
func get_scatter_target(source_pos: Vector2, debris_index: int, blow_direction: Vector2 = Vector2.ZERO) -> Vector2:
	var directions: Array[Vector2] = [
		Vector2(-1, -1),
		Vector2(-1, 0),
		Vector2(-1, 1),
		Vector2(0, -1),
		Vector2(0, 1),
		Vector2(1, -1),
		Vector2(1, 0),
		Vector2(1, 1),
	]
	if blow_direction != Vector2.ZERO:
		var blow: Vector2 = blow_direction.normalized()
		directions.sort_custom(func(a: Vector2, b: Vector2) -> bool:
			return a.normalized().dot(blow) > b.normalized().dot(blow)
		)
	var direction: Vector2 = get_scatter_direction(source_pos, debris_index, directions)
	var source_center: Vector2 = get_position_local(source_pos)
	var target_pos: Vector2 = source_pos + direction
	var target_center: Vector2 = source_center
	if MoveRules.is_valid_position(target_pos):
		target_center = get_position_local(target_pos)
	else:
		target_center = source_center + direction.normalized() * float(cell_width) * scatter_radius

	var travel: Vector2 = target_center - source_center
	var jitter_radius: float = maxf(3.0, float(cell_width) * scatter_jitter)
	var jitter: Vector2 = Vector2(randf_range(-jitter_radius, jitter_radius), randf_range(-jitter_radius, jitter_radius))
	var travel_factor_min: float = minf(scatter_radius * 0.68, scatter_radius)
	var travel_factor_max: float = maxf(travel_factor_min, scatter_radius)
	return source_center + travel * randf_range(travel_factor_min, travel_factor_max) + jitter

func get_scatter_direction(source_pos: Vector2, debris_index: int, directions: Array[Vector2]) -> Vector2:
	if directions.is_empty():
		return Vector2.ZERO
	if !avoid_occupied_cells:
		return directions[debris_index % directions.size()]

	var start_index: int = debris_index % directions.size()
	for offset in range(directions.size()):
		var direction: Vector2 = directions[(start_index + offset) % directions.size()]
		var target_pos: Vector2 = source_pos + direction
		if is_route_cell_blocked(target_pos, source_pos, invalid_board_pos):
			continue
		if absf(direction.x) > 0.0 and absf(direction.y) > 0.0:
			var horizontal_pos: Vector2 = source_pos + Vector2(direction.x, 0.0)
			var vertical_pos: Vector2 = source_pos + Vector2(0.0, direction.y)
			if is_route_cell_blocked(horizontal_pos, source_pos, invalid_board_pos) and is_route_cell_blocked(vertical_pos, source_pos, invalid_board_pos):
				continue
		return direction

	return directions[start_index]

func update_item_path_motion(item: Node2D, path_points: Array[Vector2], progress: float) -> void:
	update_item_motion(item, get_polyline_position(path_points, progress))

func update_respawn_path_motion(item: Node2D, path_points: Array[Vector2], progress: float, respawn_pos: Vector2) -> void:
	var local_pos: Vector2 = get_polyline_position(path_points, progress)
	update_respawn_item_motion(item, local_pos, respawn_pos)

func update_item_motion(item: Node2D, local_pos: Vector2) -> void:
	if item == null or !is_instance_valid(item):
		return
	item.position = local_pos
	item.z_index = get_z_index_for_local_position(local_pos)

func update_respawn_item_motion(item: Node2D, local_pos: Vector2, respawn_pos: Vector2) -> void:
	if item == null or !is_instance_valid(item):
		return
	item.position = local_pos
	item.z_index = get_respawn_z_index_for_local_position(local_pos, respawn_pos)

func get_return_motion_progress(progress: float) -> float:
	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	var split_progress: float = clampf(return_acceleration_progress, 0.05, 0.95)
	if clamped_progress <= split_progress:
		var acceleration_progress: float = clamped_progress / split_progress
		return split_progress * get_exponential_ease_in_progress(acceleration_progress)

	var deceleration_progress: float = (clamped_progress - split_progress) / (1.0 - split_progress)
	return split_progress + (1.0 - split_progress) * get_exponential_ease_out_progress(deceleration_progress)

func get_exponential_ease_in_progress(progress: float) -> float:
	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	if clamped_progress <= 0.0:
		return 0.0
	if clamped_progress >= 1.0:
		return 1.0
	return pow(2.0, 10.0 * (clamped_progress - 1.0))

func get_exponential_ease_out_progress(progress: float) -> float:
	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	if clamped_progress <= 0.0:
		return 0.0
	if clamped_progress >= 1.0:
		return 1.0
	return 1.0 - pow(2.0, -10.0 * clamped_progress)

func get_polyline_position(path_points: Array[Vector2], progress: float) -> Vector2:
	if path_points.is_empty():
		return Vector2.ZERO
	if path_points.size() == 1:
		return path_points[0]

	var total_length: float = 0.0
	var segment_lengths: Array[float] = []
	for index in range(path_points.size() - 1):
		var segment_length: float = maxf(0.001, path_points[index].distance_to(path_points[index + 1]))
		segment_lengths.append(segment_length)
		total_length += segment_length

	var target_distance: float = clampf(progress, 0.0, 1.0) * total_length
	var covered_distance: float = 0.0
	for index in range(segment_lengths.size()):
		var segment_length: float = segment_lengths[index]
		if covered_distance + segment_length >= target_distance:
			var segment_progress: float = (target_distance - covered_distance) / segment_length
			return path_points[index].lerp(path_points[index + 1], segment_progress)
		covered_distance += segment_length

	return path_points[path_points.size() - 1]

func get_z_index_for_local_position(local_pos: Vector2) -> int:
	var base_z_index: int = int(pieces_node.z_index) if pieces_node != null else 0
	var nearest_pos: Vector2 = get_nearest_board_position_for_local_position(local_pos)
	if !MoveRules.is_valid_position(nearest_pos):
		return base_z_index

	var nearest_center: Vector2 = get_position_local(nearest_pos)
	var front_side: bool = (local_pos.y - nearest_center.y) * float(view_color) >= 0.0
	var side_offset: int = route_z_front_offset if front_side else route_z_back_offset
	return base_z_index + get_depth_z_index(nearest_pos) + side_offset

## On the ground under whatever stands nearest: below the pieces of that rank,
## as `PieceMoveAnimator`'s shadow of a piece in flight is.
func get_ground_shadow_z_index(local_pos: Vector2) -> int:
	var base_z_index: int = int(pieces_node.z_index) if pieces_node != null else 0
	var nearest_pos: Vector2 = get_nearest_board_position_for_local_position(local_pos)
	if !MoveRules.is_valid_position(nearest_pos):
		return base_z_index + DEBRIS_SHADOW_Z_OFFSET
	return base_z_index + get_depth_z_index(nearest_pos) + DEBRIS_SHADOW_Z_OFFSET

func get_respawn_z_index_for_local_position(local_pos: Vector2, respawn_pos: Vector2) -> int:
	var base_z_index: int = int(pieces_node.z_index) if pieces_node != null else 0
	if MoveRules.is_valid_position(respawn_pos):
		var nearest_pos: Vector2 = get_nearest_board_position_for_local_position(local_pos)
		if nearest_pos == respawn_pos:
			return base_z_index + get_depth_z_index(respawn_pos)
	return get_z_index_for_local_position(local_pos)

func get_nearest_board_position_for_local_position(local_pos: Vector2) -> Vector2:
	var nearest_pos: Vector2 = invalid_board_pos
	var nearest_distance: float = INF
	for row in range(board_size):
		for col in range(board_size):
			var board_pos := Vector2(row, col)
			var distance: float = local_pos.distance_squared_to(get_position_local(board_pos))
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_pos = board_pos
	return nearest_pos

func get_position_local(board_pos: Vector2, clamp_to_board: bool = true) -> Vector2:
	if geometry == null:
		return Vector2.ZERO
	return geometry.get_position_local(board_pos, clamp_to_board)

func get_visual_transform_for_texture(texture_value: Texture2D, board_pos: Vector2) -> Dictionary:
	if piece_visuals == null:
		return {"scale": Vector2.ONE, "offset": Vector2.ZERO}
	return piece_visuals.get_visual_transform_for_texture(texture_value, board_pos)

func apply_fragment_visual_size(fragment: Polygon2D, board_pos: Vector2) -> void:
	var visual_transform: Dictionary = get_visual_transform_for_texture(fragment.texture, board_pos)
	fragment.scale = visual_transform.get("scale", Vector2.ONE)
	fragment.offset = visual_transform.get("offset", Vector2.ZERO)

func get_perspective_scale(board_pos: Vector2) -> float:
	if piece_visuals == null:
		return 1.0
	return piece_visuals.get_perspective_scale(board_pos)

func get_depth_z_index(board_pos: Vector2) -> int:
	if piece_visuals != null:
		return piece_visuals.get_depth_z_index(board_pos)
	var rank: int = int(board_pos.x) if view_color < 0 else board_size - 1 - int(board_pos.x)
	return rank * BoardConfig.DEPTH_Z_STRIDE

func is_route_cell_blocked(board_pos: Vector2, source_pos: Vector2, respawn_pos: Vector2) -> bool:
	if route_cell_blocked_provider.is_valid():
		return bool(route_cell_blocked_provider.call(board_pos, source_pos, respawn_pos))
	if !MoveRules.is_valid_position(board_pos):
		return true
	return board_pos != source_pos and board_pos != respawn_pos

func tween_respawn_finish_callback(tween: Tween, respawn_pos: Vector2) -> void:
	if tween != null and finish_respawn_fragment_callback.is_valid():
		tween.tween_callback(finish_respawn_fragment_callback.bind(respawn_pos))

func create_animation_tween() -> Tween:
	if tween_owner == null or !is_instance_valid(tween_owner):
		return null
	return tween_owner.create_tween()

func enable_antialiasing(canvas_item: Object) -> void:
	if antialias_provider.is_valid():
		antialias_provider.call(canvas_item)
