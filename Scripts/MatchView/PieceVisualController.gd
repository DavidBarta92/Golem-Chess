extends RefCounted

const PIECE_GROUNDING_SCRIPT = preload("res://Scripts/MatchView/PieceGrounding.gd")

const DEFAULT_PIECE_BOTTOM_INSET: float = 1.5
const PIECE_PERSPECTIVE_SCALE_VARIATION: float = 0.10
const PIECE_LIGHT_OCCLUDER_NAME: String = "PieceLightOccluder"
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_WIDTH_FACTOR: float = 0.68
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_BOTTOM_INSET_FACTOR: float = 0.05
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_OFFSET: Vector2 = Vector2.ZERO
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_SEGMENTS: int = 18
const PIECE_FOOTPRINT_ALPHA_THRESHOLD: float = 0.04
const PIECE_FOOTPRINT_WIDTH_SCAN_START_RATIO: float = 0.6666667
const PIECE_FOOTPRINT_STABLE_WIDTH_BAND_RATIO: float = 0.25
const PIECE_FOOTPRINT_STABLE_ROW_SAMPLE_COUNT: int = 8
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_MIN_RADIUS_BOUNDS_FACTOR: float = 0.22
## A figure's base, for `base_round_depth`: the bottom share of its height it
## is looked for in, how far up (a share of the height) each row is compared
## with, and how much wider that row may be for the base to have stopped
## widening. Not the widest row near the bottom: a golem's hands hang down
## close to it.
const PIECE_FOOTPRINT_BASE_WINDOW_RATIO: float = 0.15
const PIECE_FOOTPRINT_BASE_STEP_RATIO: float = 0.03
const PIECE_FOOTPRINT_BASE_PLATEAU_GROWTH: float = 1.04

var geometry
var board_size: int = BoardConfig.BOARD_SIZE
var cell_width: int = BoardConfig.CELL_WIDTH
var view_color: int = 1
var texture_filter_value = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

var default_piece_texture: Texture2D
var own_default_piece_texture: Texture2D
var default_piece_visual_height: float = 24.0
var piece_auto_fit_height_threshold: float = 48.0

var board_light_receive_mask: int = 1
var piece_light_occluder_mask: int = 1

var piece_light_occluder_footprint_fixed_radius_y: float = 3.0

var piece_footprint_metrics_cache: Dictionary = {}

var piece_light_receive_mask: int = 2
var piece_effect_light_receive_mask: int = 0
var attach_effect_names: Array[String] = []

func configure(config: Dictionary) -> void:
	geometry = config.get("geometry", geometry)
	board_size = int(config.get("board_size", board_size))
	cell_width = int(config.get("cell_width", cell_width))
	view_color = -1 if int(config.get("view_color", view_color)) < 0 else 1
	texture_filter_value = config.get("texture_filter", texture_filter_value)

	default_piece_texture = config.get("default_piece_texture", default_piece_texture)
	own_default_piece_texture = config.get("own_default_piece_texture", own_default_piece_texture)
	default_piece_visual_height = float(config.get("default_piece_visual_height", default_piece_visual_height))
	piece_auto_fit_height_threshold = float(config.get("piece_auto_fit_height_threshold", piece_auto_fit_height_threshold))

	board_light_receive_mask = int(config.get("board_light_receive_mask", board_light_receive_mask))
	piece_light_occluder_mask = int(config.get("piece_light_occluder_mask", piece_light_occluder_mask))
	piece_light_receive_mask = int(config.get("piece_light_receive_mask", piece_light_receive_mask))
	piece_effect_light_receive_mask = int(config.get("piece_effect_light_receive_mask", piece_effect_light_receive_mask))

	piece_light_occluder_footprint_fixed_radius_y = float(config.get("piece_light_occluder_footprint_fixed_radius_y", piece_light_occluder_footprint_fixed_radius_y))
	if config.has("attach_effect_names"):
		attach_effect_names.clear()
		for effect_name_value in config.get("attach_effect_names", []):
			attach_effect_names.append(str(effect_name_value))

func is_default_piece_texture(texture_value: Texture2D) -> bool:
	return texture_value == default_piece_texture || texture_value == own_default_piece_texture

func should_fit_piece_texture_to_default_height(texture_value: Texture2D) -> bool:
	if texture_value == null:
		return false
	if is_default_piece_texture(texture_value):
		return true

	var texture_size: Vector2 = texture_value.get_size()
	return texture_size.y >= piece_auto_fit_height_threshold

func get_visual_transform_for_texture(texture_value: Texture2D, board_pos: Vector2) -> Dictionary:
	var visual_transform := {
		"scale": Vector2.ONE,
		"offset": Vector2.ZERO,
	}
	if texture_value == null:
		return visual_transform

	var perspective_scale: float = get_perspective_scale(board_pos)
	if should_fit_piece_texture_to_default_height(texture_value):
		var texture_size: Vector2 = texture_value.get_size()
		if texture_size.y > 0.0:
			var visual_scale: float = (default_piece_visual_height / texture_size.y) * perspective_scale
			var cell_bounds: Rect2 = geometry.get_cell_rect_local(board_pos) if geometry != null else Rect2()
			var cell_bottom_offset: float = cell_bounds.end.y - get_position_local(board_pos).y
			visual_transform["scale"] = Vector2.ONE * visual_scale
			visual_transform["offset"] = Vector2(0.0, (cell_bottom_offset - DEFAULT_PIECE_BOTTOM_INSET) / visual_scale - (texture_size.y * 0.5))
		return visual_transform

	visual_transform["scale"] = Vector2.ONE * perspective_scale
	return visual_transform

func apply_visual_size(holder: Sprite2D, board_pos: Vector2) -> void:
	apply_texture_filter(holder)
	holder.scale = Vector2.ONE
	holder.offset = Vector2.ZERO
	if holder.texture == null:
		return

	var visual_transform: Dictionary = get_visual_transform_for_texture(holder.texture, board_pos)
	holder.scale = visual_transform.get("scale", Vector2.ONE)
	holder.offset = visual_transform.get("offset", Vector2.ZERO)

func apply_texture_filter(holder: Sprite2D) -> void:
	if holder == null or !is_instance_valid(holder):
		return

	holder.texture_filter = texture_filter_value

func get_perspective_scale(board_pos: Vector2) -> float:
	var center_row: float = float(board_size - 1) * 0.5
	if center_row <= 0.0:
		return 1.0

	var row_delta_from_center: float = (center_row - board_pos.x) * float(view_color)
	var normalized_distance: float = clampf(row_delta_from_center / center_row, -1.0, 1.0)
	return 1.0 + normalized_distance * PIECE_PERSPECTIVE_SCALE_VARIATION

## Where a square sits in the drawing order: the nearer the viewer, the higher.
## Ranks are spaced `BoardConfig.DEPTH_Z_STRIDE` apart rather than one, so there
## is room between them for a piece in flight; see that constant. This is the
## only place the spacing is applied - everything else asks here.
func get_depth_z_index(board_pos: Vector2) -> int:
	var rank: int = int(board_pos.x) if view_color < 0 else board_size - 1 - int(board_pos.x)
	return rank * BoardConfig.DEPTH_Z_STRIDE

func get_holder_at(pieces_node: Node, board_pos: Vector2, invalid_pos: Vector2) -> Sprite2D:
	if pieces_node == null:
		return null

	for child in pieces_node.get_children():
		var holder: Sprite2D = child as Sprite2D
		if holder == null or holder.is_queued_for_deletion():
			continue
		var holder_pos: Vector2 = BoardConfig.value_to_vector2(holder.get_meta("board_pos", invalid_pos), invalid_pos)
		if holder_pos == board_pos:
			return holder

	return null

func apply_holder_base_visual(holder: Sprite2D, board_pos: Vector2) -> void:
	if holder == null or !is_instance_valid(holder):
		return

	holder.light_mask = piece_light_receive_mask
	holder.position = get_position_local(board_pos)
	holder.z_index = get_depth_z_index(board_pos)
	apply_visual_size(holder, board_pos)

func apply_respawn_lock_opacity(holder: Sprite2D, is_hidden_for_respawn: bool, is_respawn_locked: bool) -> void:
	if holder == null or !is_instance_valid(holder):
		return

	var alpha: float = 1.0
	if is_hidden_for_respawn:
		alpha = 0.0
	elif is_respawn_locked:
		alpha = 0.5
	var tint: Color = holder.self_modulate
	tint.a = alpha
	holder.self_modulate = tint

## Stands a piece on the board (PieceGrounding). A piece of the other side
## is seen from the front, lit from ours, so nothing falls in front of it.
## A shadow already there for the same side is kept: it fits itself to a new
## picture, and making it anew would cut short a fade it is in.
func apply_shadow(holder: Sprite2D, piece_color: int, own_color: int) -> void:
	if holder == null or !is_instance_valid(holder):
		return
	var seen_from_front: bool = piece_color * own_color < 0
	var existing = get_shadow(holder)
	if existing != null and piece_color != 0 and existing.is_seen_from_front() == seen_from_front:
		return
	remove_shadow(holder)
	if holder.texture == null or piece_color == 0:
		return
	add_shadow(holder, seen_from_front)

func add_shadow(holder: Sprite2D, seen_from_front: bool, with_foot_shade: bool = true) -> Node2D:
	var grounding: Node2D = PIECE_GROUNDING_SCRIPT.new(Callable(self, "get_footprint_metrics"), Callable(self, "get_footprint_geometry"), seen_from_front, with_foot_shade)
	holder.add_child(grounding)
	return grounding

func get_shadow(holder: Sprite2D) -> Node2D:
	if holder == null or !is_instance_valid(holder):
		return null
	return holder.get_node_or_null(PIECE_GROUNDING_SCRIPT.NODE_NAME) as Node2D

func remove_shadow(holder: Sprite2D) -> void:
	var existing: Node = get_shadow(holder)
	if existing != null:
		existing.free()

## A stamp's flash and the like: the shadow fades to `alpha` over `seconds`.
func fade_shadow(holder: Sprite2D, alpha: float, seconds: float) -> void:
	var existing = get_shadow(holder)
	if existing != null:
		existing.fade_to(alpha, seconds)

## One picture of a piece giving way to another on its square - its stamp
## running out, the old picture burning away in `leaving` over the piece's
## holder `staying` - and the old picture's shadow giving way to the new one's
## over `seconds`.
func cross_fade_shadow(leaving: Sprite2D, staying: Sprite2D, seconds: float) -> void:
	var staying_shadow = get_shadow(staying)
	if staying_shadow == null or leaving == null or !is_instance_valid(leaving) or leaving.texture == null:
		return
	var leaving_shadow = add_shadow(leaving, staying_shadow.is_seen_from_front(), false)
	leaving_shadow.fade_to(0.0, seconds)
	staying_shadow.fade_to(0.0, 0.0)
	staying_shadow.fade_to(1.0, seconds)

## The piece goes up off the board: its shadow stays where it stood and fades
## over `seconds`. Answers which side it was for - 1 seen from the front, 0
## from behind, -1 none - so that `land_shadow` can bring the same back.
func lift_shadow(holder: Sprite2D, seconds: float) -> int:
	var existing = get_shadow(holder)
	if existing == null:
		return -1
	var side: int = 1 if existing.is_seen_from_front() else 0
	existing.lift_off(seconds)
	return side

## The piece is dropping onto its square from `lift_height` above it: its
## shadow comes in on the ground under it over `seconds`.
func land_shadow(holder: Sprite2D, side: int, seconds: float, lift_height: float) -> void:
	if side < 0 or holder == null or !is_instance_valid(holder) or holder.texture == null:
		return
	remove_shadow(holder)
	var grounding = add_shadow(holder, side == 1)
	grounding.settle_in(seconds, lift_height)

func apply_light_occluder(holder: Sprite2D, has_piece: bool) -> void:
	remove_light_occluder(holder)
	if holder == null or !is_instance_valid(holder) or holder.texture == null or !has_piece:
		return

	var footprint: Dictionary = get_footprint_geometry(holder)
	var center: Vector2 = footprint.get("center", Vector2.ZERO)
	var radius_x: float = float(footprint.get("radius_x", 0.0))
	var radius_y: float = float(footprint.get("radius_y", 0.0))
	if bool(footprint.get("empty", true)) or radius_x <= 0.0 or radius_y <= 0.0:
		return

	var occluder := LightOccluder2D.new()
	occluder.name = PIECE_LIGHT_OCCLUDER_NAME
	occluder.occluder_light_mask = piece_light_occluder_mask

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

func remove_light_occluder(holder: Sprite2D) -> void:
	if holder == null or !is_instance_valid(holder):
		return

	var existing_occluder: Node = holder.get_node_or_null(PIECE_LIGHT_OCCLUDER_NAME)
	if existing_occluder != null:
		existing_occluder.free()

func get_footprint_geometry(holder: Sprite2D) -> Dictionary:
	if holder == null or !is_instance_valid(holder) or holder.texture == null:
		return {"empty": true}

	var texture_size: Vector2 = holder.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return {"empty": true}

	var metrics: Dictionary = get_footprint_metrics(holder.texture)
	if metrics.is_empty():
		return get_fallback_footprint_geometry(holder, texture_size)

	var lower_width: float = maxf(1.0, float(metrics.get("lower_width", metrics.get("widest_width", texture_size.x))))
	var lower_center_x: float = float(metrics.get("lower_center_x", metrics.get("widest_center_x", texture_size.x * 0.5)))
	var bottom_y: float = float(metrics.get("bottom_y", texture_size.y - 1.0))
	var bounds_width: float = maxf(1.0, float(metrics.get("right_x", texture_size.x - 1.0)) - float(metrics.get("left_x", 0.0)) + 1.0)
	var radius_x: float = maxf(
		lower_width * PIECE_LIGHT_OCCLUDER_FOOTPRINT_WIDTH_FACTOR * 0.5,
		bounds_width * PIECE_LIGHT_OCCLUDER_FOOTPRINT_MIN_RADIUS_BOUNDS_FACTOR
	)
	var radius_y: float = get_footprint_fixed_radius_y(holder)
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

func get_footprint_fixed_radius_y(holder: Sprite2D) -> float:
	var scale_y: float = absf(holder.scale.y) if holder != null else 1.0
	if scale_y <= 0.0001:
		return piece_light_occluder_footprint_fixed_radius_y
	return piece_light_occluder_footprint_fixed_radius_y / scale_y

func get_fallback_footprint_geometry(holder: Sprite2D, texture_size: Vector2) -> Dictionary:
	var radius_x: float = texture_size.x * PIECE_LIGHT_OCCLUDER_FOOTPRINT_WIDTH_FACTOR * 0.5
	var radius_y: float = get_footprint_fixed_radius_y(holder)
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

func get_footprint_metrics(texture_value: Texture2D) -> Dictionary:
	if texture_value == null:
		return {}

	var cache_key: String = get_footprint_metrics_cache_key(texture_value)
	if piece_footprint_metrics_cache.has(cache_key):
		return piece_footprint_metrics_cache[cache_key]

	var metrics: Dictionary = measure_footprint_metrics(texture_value)
	piece_footprint_metrics_cache[cache_key] = metrics
	return metrics

func get_footprint_metrics_cache_key(texture_value: Texture2D) -> String:
	if texture_value.resource_path != "":
		return "%s:%s" % [texture_value.resource_path, texture_value.get_size()]
	return "%s:%s" % [str(texture_value.get_rid()), texture_value.get_size()]

func measure_footprint_metrics(texture_value: Texture2D) -> Dictionary:
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

	# How far up from its lowest pixel the bottom of the figure stops widening:
	# little for flat feet, most of the depth of the ellipse a round base is
	# drawn as; none if it is still widening at the top of the window.
	# `visible_rows` runs from the bottom up.
	var base_window: float = float(alpha_height) * PIECE_FOOTPRINT_BASE_WINDOW_RATIO
	var base_step: int = maxi(1, int(round(float(alpha_height) * PIECE_FOOTPRINT_BASE_STEP_RATIO)))
	var base_round_depth: float = 0.0
	for row_index in range(visible_rows.size() - base_step):
		var row: Dictionary = visible_rows[row_index]
		var depth: float = float(max_y - int(row.get("y", max_y)))
		if depth > base_window:
			break
		var row_above: Dictionary = visible_rows[row_index + base_step]
		if float(row_above.get("width", 0)) <= float(row.get("width", 0)) * PIECE_FOOTPRINT_BASE_PLATEAU_GROWTH:
			base_round_depth = depth
			break

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
		"base_round_depth": base_round_depth,
	}

func set_light_occluder_enabled(holder: Sprite2D, is_enabled: bool) -> void:
	if holder == null or !is_instance_valid(holder):
		return

	var occluder: LightOccluder2D = holder.get_node_or_null(PIECE_LIGHT_OCCLUDER_NAME) as LightOccluder2D
	if occluder != null:
		occluder.occluder_light_mask = piece_light_occluder_mask if is_enabled else 0

func sync_sprite_overlay_to_holder(overlay: Sprite2D, holder: Sprite2D) -> void:
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
	overlay.light_mask = piece_effect_light_receive_mask
	overlay.texture_filter = texture_filter_value
	overlay.position = Vector2.ZERO
	overlay.rotation = 0.0
	overlay.scale = Vector2.ONE

func remove_named_child_effects(holder: Sprite2D, effect_names: Array[String]) -> void:
	if holder == null or !is_instance_valid(holder):
		return

	for effect_name in effect_names:
		var existing_effect: Node = holder.get_node_or_null(effect_name)
		if existing_effect != null:
			existing_effect.free()

func remove_attach_effects(holder: Sprite2D) -> void:
	remove_named_child_effects(holder, attach_effect_names)

func get_position_local(board_pos: Vector2) -> Vector2:
	if geometry == null:
		return Vector2.ZERO
	return geometry.get_position_local(board_pos)
