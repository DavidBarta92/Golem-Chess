extends RefCounted

const PIECE_MOVE_SHADOW_SHADER = preload("res://Shaders/piece_move_shadow.gdshader")

var geometry
var piece_visuals
var tween_owner: Node
var cell_width: int = BoardConfig.CELL_WIDTH
var board_size: int = BoardConfig.BOARD_SIZE
var move_duration: float = 0.32
var move_lift_ratio: float = 0.16
var lift_duration: float = 0.16
var drop_duration: float = 0.18
var wobble_step_duration: float = 0.12
var wobble_rotation_degrees: float = 2.4
var movement_tilt_degrees: float = 1.4
var movement_shadow_color: Color = Color(0.03, 0.025, 0.02, 0.30)
var movement_shadow_radius_scale: Vector2 = Vector2(0.92, 0.72)
var movement_shadow_ground_edge_softness: float = 0.10
var movement_shadow_lifted_edge_softness: float = 0.72
var movement_shadow_lifted_scale: Vector2 = Vector2(1.38, 1.28)
var movement_shadow_lifted_alpha: float = 0.42
var movement_shadow_z_offset: int = -2
var lifted_z_offset: int = 2
var corner_rounding_ratio: float = 0.28
var corner_sample_count: int = 4
var pieces_node: Node
var local_space_node: Node2D
var avoid_occupied_footprints: bool = true
var footprint_clearance: float = 2.0
var footprint_fixed_radius_y: float = 3.0
var route_z_front_offset: int = 1
var route_z_back_offset: int = -1
var view_color: int = 1
var invalid_board_pos: Vector2 = Vector2(-1, -1)
var piece_exists_provider: Callable = Callable()
var sprite_bounds_provider: Callable = Callable()
var movement_shadow_texture: Texture2D
var last_wobble_variant_index: int = -1

func configure(config: Dictionary) -> void:
	geometry = config.get("geometry", geometry)
	piece_visuals = config.get("piece_visuals", piece_visuals)
	tween_owner = config.get("tween_owner", tween_owner)
	cell_width = int(config.get("cell_width", cell_width))
	board_size = int(config.get("board_size", board_size))
	move_duration = float(config.get("move_duration", move_duration))
	move_lift_ratio = float(config.get("move_lift_ratio", move_lift_ratio))
	lift_duration = float(config.get("lift_duration", lift_duration))
	drop_duration = float(config.get("drop_duration", drop_duration))
	wobble_step_duration = float(config.get("wobble_step_duration", wobble_step_duration))
	wobble_rotation_degrees = float(config.get("wobble_rotation_degrees", wobble_rotation_degrees))
	movement_tilt_degrees = float(config.get("movement_tilt_degrees", movement_tilt_degrees))
	movement_shadow_color = config.get("movement_shadow_color", movement_shadow_color)
	movement_shadow_radius_scale = config.get("movement_shadow_radius_scale", movement_shadow_radius_scale)
	movement_shadow_ground_edge_softness = float(config.get("movement_shadow_ground_edge_softness", movement_shadow_ground_edge_softness))
	movement_shadow_lifted_edge_softness = float(config.get("movement_shadow_lifted_edge_softness", movement_shadow_lifted_edge_softness))
	movement_shadow_lifted_scale = config.get("movement_shadow_lifted_scale", movement_shadow_lifted_scale)
	movement_shadow_lifted_alpha = float(config.get("movement_shadow_lifted_alpha", movement_shadow_lifted_alpha))
	movement_shadow_z_offset = int(config.get("movement_shadow_z_offset", movement_shadow_z_offset))
	lifted_z_offset = int(config.get("lifted_z_offset", lifted_z_offset))
	corner_rounding_ratio = float(config.get("corner_rounding_ratio", corner_rounding_ratio))
	corner_sample_count = int(config.get("corner_sample_count", corner_sample_count))
	pieces_node = config.get("pieces_node", pieces_node)
	local_space_node = config.get("local_space_node", local_space_node)
	avoid_occupied_footprints = bool(config.get("avoid_occupied_footprints", avoid_occupied_footprints))
	footprint_clearance = float(config.get("footprint_clearance", footprint_clearance))
	footprint_fixed_radius_y = float(config.get("footprint_fixed_radius_y", footprint_fixed_radius_y))
	route_z_front_offset = int(config.get("route_z_front_offset", route_z_front_offset))
	route_z_back_offset = int(config.get("route_z_back_offset", route_z_back_offset))
	view_color = -1 if int(config.get("view_color", view_color)) < 0 else 1
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)
	piece_exists_provider = config.get("piece_exists_provider", piece_exists_provider)
	sprite_bounds_provider = config.get("sprite_bounds_provider", sprite_bounds_provider)

func play_move_sequence(
	holder: Sprite2D,
	from_pos: Vector2,
	to_pos: Vector2,
	start_scale: Vector2,
	end_scale: Vector2,
	start_offset: Vector2,
	end_offset: Vector2
) -> bool:
	if holder == null or !is_instance_valid(holder) or !_is_valid_position(from_pos) or !_is_valid_position(to_pos):
		return false
	if !can_create_tween():
		return false

	var route_points: Array[Vector2] = get_smoothed_route_points(get_route_points(from_pos, to_pos, holder))
	var travel_duration: float = get_animation_duration(route_points, from_pos, to_pos)
	var start_ground_pos: Vector2 = get_position_local(from_pos)
	var end_ground_pos: Vector2 = get_position_local(to_pos)
	var perspective_scale: float = piece_visuals.get_perspective_scale(from_pos) if piece_visuals != null else 1.0
	var lift_height: float = float(cell_width) * move_lift_ratio * perspective_scale
	var resting_rotation: float = holder.rotation
	var movement_shadow: Sprite2D = create_movement_shadow(holder, from_pos)

	holder.position = start_ground_pos
	holder.z_index = get_z_index_for_local_position(start_ground_pos, holder) + lifted_z_offset
	var lift_tween: Tween = create_animation_tween()
	if lift_tween == null:
		cleanup_movement_shadow(movement_shadow)
		return false
	lift_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	lift_tween.tween_property(holder, "position:y", start_ground_pos.y - lift_height, lift_duration)
	var shadow_material: ShaderMaterial = movement_shadow.material as ShaderMaterial if movement_shadow != null else null
	var shadow_ground_scale: Vector2 = movement_shadow.scale if movement_shadow != null else Vector2.ONE
	if shadow_material != null:
		lift_tween.parallel().tween_property(movement_shadow, "scale", shadow_ground_scale * movement_shadow_lifted_scale, lift_duration)
		lift_tween.parallel().tween_property(shadow_material, "shader_parameter/alpha_strength", movement_shadow_lifted_alpha, lift_duration)
		lift_tween.parallel().tween_property(shadow_material, "shader_parameter/edge_softness", movement_shadow_lifted_edge_softness, lift_duration)
	await lift_tween.finished
	if !is_move_holder_active(holder):
		cleanup_movement_shadow(movement_shadow)
		return false

	var travel_tween: Tween = create_animation_tween()
	if travel_tween == null:
		cleanup_movement_shadow(movement_shadow)
		return false
	travel_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	travel_tween.tween_method(
		func(progress: float): update_holder_travel(
			holder,
			route_points,
			to_pos,
			start_scale,
			end_scale,
			start_offset,
			end_offset,
			lift_height,
			movement_shadow,
			resting_rotation,
			get_arrival_progress(progress, route_points, from_pos, to_pos)
		),
		0.0,
		1.0,
		travel_duration
	)
	await travel_tween.finished
	if !is_move_holder_active(holder):
		cleanup_movement_shadow(movement_shadow)
		return false

	var drop_tween: Tween = create_animation_tween()
	if drop_tween == null:
		cleanup_movement_shadow(movement_shadow)
		return false
	drop_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	drop_tween.tween_property(holder, "position:y", end_ground_pos.y, drop_duration)
	drop_tween.parallel().tween_property(holder, "rotation", resting_rotation, drop_duration)
	if shadow_material != null:
		drop_tween.parallel().tween_property(movement_shadow, "scale", shadow_ground_scale, drop_duration)
		drop_tween.parallel().tween_property(shadow_material, "shader_parameter/alpha_strength", 1.0, drop_duration)
		drop_tween.parallel().tween_property(shadow_material, "shader_parameter/edge_softness", movement_shadow_ground_edge_softness, drop_duration)
	await drop_tween.finished
	if !is_move_holder_active(holder):
		cleanup_movement_shadow(movement_shadow)
		return false

	holder.position = end_ground_pos
	holder.z_index = get_depth_z_index(to_pos)
	var wobble_tween: Tween = create_animation_tween()
	if wobble_tween == null:
		holder.rotation = resting_rotation
		cleanup_movement_shadow(movement_shadow)
		return false
	wobble_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	var wobble_angle: float = deg_to_rad(wobble_rotation_degrees)
	var wobble_variant: Dictionary = get_random_wobble_variant()
	var wobble_angles: Array = wobble_variant.get("angles", [])
	var wobble_durations: Array = wobble_variant.get("durations", [])
	for index in wobble_angles.size():
		var duration_scale: float = float(wobble_durations[index]) if index < wobble_durations.size() else 1.0
		wobble_tween.tween_property(
			holder,
			"rotation",
			resting_rotation + wobble_angle * float(wobble_angles[index]),
			wobble_step_duration * duration_scale
		)
	await wobble_tween.finished
	cleanup_movement_shadow(movement_shadow)
	if is_instance_valid(holder):
		holder.rotation = resting_rotation
	return is_move_holder_active(holder)

func create_movement_shadow(holder: Sprite2D, from_pos: Vector2) -> Sprite2D:
	if holder == null or !is_instance_valid(holder) or pieces_node == null or !is_instance_valid(pieces_node):
		return null

	var footprint: Dictionary = get_footprint_board_geometry(holder)
	if bool(footprint.get("empty", true)):
		return null
	var radius_x: float = float(footprint.get("radius_x", 0.0)) * movement_shadow_radius_scale.x
	var radius_y: float = float(footprint.get("radius_y", 0.0)) * movement_shadow_radius_scale.y
	if radius_x <= 0.0 or radius_y <= 0.0:
		return null

	var shadow := Sprite2D.new()
	shadow.name = "PieceMoveGroundShadow"
	shadow.z_index = get_depth_z_index(from_pos) + movement_shadow_z_offset
	shadow.light_mask = 0
	shadow.texture = get_movement_shadow_texture()
	shadow.scale = Vector2(radius_x * 2.0 / float(shadow.texture.get_width()), radius_y * 2.0 / float(shadow.texture.get_height()))
	var shadow_material := ShaderMaterial.new()
	shadow_material.shader = PIECE_MOVE_SHADOW_SHADER
	shadow_material.set_shader_parameter("shadow_color", movement_shadow_color)
	shadow_material.set_shader_parameter("alpha_strength", 0.0)
	shadow_material.set_shader_parameter("edge_softness", movement_shadow_ground_edge_softness)
	shadow.material = shadow_material
	pieces_node.add_child(shadow)

	var footprint_center: Vector2 = footprint.get("center", get_position_local(from_pos))
	if pieces_node is Node2D and local_space_node != null and is_instance_valid(local_space_node):
		shadow.position = (pieces_node as Node2D).to_local(local_space_node.to_global(footprint_center))
	else:
		shadow.position = footprint_center
	return shadow

func get_movement_shadow_texture() -> Texture2D:
	if movement_shadow_texture != null:
		return movement_shadow_texture

	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	movement_shadow_texture = ImageTexture.create_from_image(image)
	return movement_shadow_texture

func get_random_wobble_variant() -> Dictionary:
	var variants: Array[Dictionary] = [
		{"angles": [1.0, -1.0, 0.48, -0.34, 0.0], "durations": [1.0, 1.25, 1.0, 1.0, 1.0]},
		{"angles": [1.10, -0.28, 0.0], "durations": [1.20, 1.35, 1.10]},
		{"angles": [-1.10, 0.28, 0.0], "durations": [1.20, 1.35, 1.10]},
		{"angles": [0.25, -0.16, 0.0], "durations": [1.05, 1.15, 1.0]},
		{"angles": [-0.30, 0.18, -0.08, 0.0], "durations": [1.0, 1.10, 0.95, 1.0]},
		{"angles": [1.18, -1.02, 0.78, -0.58, 0.38, -0.20, 0.0], "durations": [0.95, 1.15, 1.0, 1.0, 0.95, 0.90, 1.0]},
		{"angles": [-1.18, 1.02, -0.78, 0.58, -0.38, 0.20, 0.0], "durations": [0.95, 1.15, 1.0, 1.0, 0.95, 0.90, 1.0]},
		{"angles": [0.68, -0.52, 0.22, 0.0], "durations": [1.15, 1.25, 1.05, 1.0]},
		{"angles": [-0.82, 0.38, -0.12, 0.0], "durations": [1.25, 1.30, 1.05, 1.0]},
		{"angles": [1.25, -0.45, 0.16, -0.06, 0.0], "durations": [1.30, 1.35, 1.0, 0.90, 1.0]},
	]
	var variant_index: int = randi_range(0, variants.size() - 1)
	if variants.size() > 1 and variant_index == last_wobble_variant_index:
		variant_index = (variant_index + randi_range(1, variants.size() - 1)) % variants.size()
	last_wobble_variant_index = variant_index
	return variants[variant_index]

func cleanup_movement_shadow(shadow) -> void:
	if shadow != null and is_instance_valid(shadow):
		shadow.queue_free()

func can_create_tween() -> bool:
	return tween_owner != null and is_instance_valid(tween_owner) and tween_owner.is_inside_tree()

func create_animation_tween() -> Tween:
	if !can_create_tween():
		return null
	return tween_owner.create_tween()

func is_move_holder_active(holder) -> bool:
	return can_create_tween() and holder != null and is_instance_valid(holder) and holder is Sprite2D

func get_route_points(from_pos: Vector2, to_pos: Vector2, moving_holder: Sprite2D) -> Array[Vector2]:
	var start_point: Vector2 = get_position_local(from_pos)
	var end_point: Vector2 = get_position_local(to_pos)
	var direct_points: Array[Vector2] = [start_point, end_point]
	if !avoid_occupied_footprints:
		return direct_points

	var blocking_holders: Array[Sprite2D] = get_direct_blocking_holders(from_pos, to_pos, moving_holder)
	if blocking_holders.is_empty():
		return direct_points

	return get_detour_route_points(from_pos, to_pos, moving_holder, blocking_holders)

func get_animation_duration(route_points: Array[Vector2], from_pos: Vector2, to_pos: Vector2) -> float:
	var route_length: float = get_route_length(route_points)
	var reference_distance: float = get_reference_step_distance(from_pos, to_pos)
	if route_length <= 0.0 or reference_distance <= 0.0:
		return move_duration

	return maxf(move_duration, move_duration * route_length / reference_distance)

func get_smoothed_route_points(route_points: Array[Vector2]) -> Array[Vector2]:
	if route_points.size() <= 2:
		return route_points

	var smoothed_points: Array[Vector2] = [route_points[0]]
	for index in range(1, route_points.size() - 1):
		var previous_point: Vector2 = route_points[index - 1]
		var corner_point: Vector2 = route_points[index]
		var next_point: Vector2 = route_points[index + 1]
		var incoming: Vector2 = corner_point - previous_point
		var outgoing: Vector2 = next_point - corner_point
		var incoming_length: float = incoming.length()
		var outgoing_length: float = outgoing.length()
		if incoming_length <= 0.001 or outgoing_length <= 0.001:
			append_route_point(smoothed_points, corner_point)
			continue

		var corner_radius: float = minf(incoming_length, outgoing_length) * corner_rounding_ratio
		corner_radius = minf(corner_radius, float(cell_width) * 0.46)
		var entry_point: Vector2 = corner_point - incoming.normalized() * corner_radius
		var exit_point: Vector2 = corner_point + outgoing.normalized() * corner_radius
		append_route_point(smoothed_points, entry_point)
		for sample_index in range(1, corner_sample_count + 1):
			var sample_progress: float = float(sample_index) / float(corner_sample_count + 1)
			append_route_point(smoothed_points, get_quadratic_curve_point(entry_point, corner_point, exit_point, sample_progress))
		append_route_point(smoothed_points, exit_point)

	append_route_point(smoothed_points, route_points[route_points.size() - 1])
	return smoothed_points

func get_quadratic_curve_point(start_point: Vector2, control_point: Vector2, end_point: Vector2, progress: float) -> Vector2:
	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	var inverse_progress: float = 1.0 - clamped_progress
	var start_weight: float = inverse_progress * inverse_progress
	var control_weight: float = 2.0 * inverse_progress * clamped_progress
	var end_weight: float = clamped_progress * clamped_progress
	return start_point * start_weight + control_point * control_weight + end_point * end_weight

func get_arrival_progress(progress: float, route_points: Array[Vector2], from_pos: Vector2, to_pos: Vector2) -> float:
	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	var route_length: float = get_route_length(route_points)
	var reference_distance: float = get_reference_step_distance(from_pos, to_pos)
	if route_length <= 0.001 or reference_distance <= 0.001:
		return clamped_progress

	var deceleration_distance: float = minf(route_length, reference_distance)
	var deceleration_ratio: float = deceleration_distance / route_length
	var deceleration_start: float = clampf(1.0 - deceleration_ratio, 0.0, 0.98)
	if clamped_progress <= deceleration_start:
		return clamped_progress

	var local_progress: float = (clamped_progress - deceleration_start) / maxf(0.001, 1.0 - deceleration_start)
	return deceleration_start + (1.0 - deceleration_start) * get_deceleration_curve(local_progress)

func get_deceleration_curve(progress: float) -> float:
	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	var progress_squared: float = clamped_progress * clamped_progress
	var progress_cubed: float = progress_squared * clamped_progress
	var progress_fourth: float = progress_cubed * clamped_progress
	var progress_fifth: float = progress_fourth * clamped_progress
	return clamped_progress + 4.0 * progress_cubed - 7.0 * progress_fourth + 3.0 * progress_fifth

func get_route_length(route_points: Array[Vector2]) -> float:
	if route_points.size() < 2:
		return 0.0

	var route_length: float = 0.0
	for index in range(route_points.size() - 1):
		route_length += route_points[index].distance_to(route_points[index + 1])
	return route_length

func get_reference_step_distance(from_pos: Vector2, to_pos: Vector2) -> float:
	if geometry == null:
		return float(cell_width)

	var direction: Vector2 = to_pos - from_pos
	var step := Vector2(signf(direction.x), signf(direction.y))
	if step == Vector2.ZERO:
		step = Vector2(0.0, 1.0)

	var reference_neighbor: Vector2 = from_pos + step
	if !_is_valid_position(reference_neighbor):
		reference_neighbor = to_pos - step
	if !_is_valid_position(reference_neighbor):
		var perspective_scale: float = piece_visuals.get_perspective_scale(from_pos) if piece_visuals != null else 1.0
		return float(cell_width) * perspective_scale

	return geometry.get_position_local(from_pos).distance_to(geometry.get_position_local(reference_neighbor))

func append_route_point(route_points: Array[Vector2], point: Vector2) -> void:
	if route_points.is_empty() or route_points[route_points.size() - 1].distance_squared_to(point) > 4.0:
		route_points.append(point)

func get_direct_blocking_holders(from_pos: Vector2, to_pos: Vector2, moving_holder: Sprite2D) -> Array[Sprite2D]:
	var blocking_holders: Array[Sprite2D] = []
	if pieces_node == null or moving_holder == null or !is_instance_valid(moving_holder):
		return blocking_holders

	var start_point: Vector2 = get_position_local(from_pos)
	var end_point: Vector2 = get_position_local(to_pos)
	var moving_footprint: Dictionary = get_footprint_board_geometry(moving_holder)
	if bool(moving_footprint.get("empty", true)):
		return blocking_holders

	var moving_radius_x: float = float(moving_footprint.get("radius_x", 0.0))
	var moving_radius_y: float = float(moving_footprint.get("radius_y", 0.0))
	for child in pieces_node.get_children():
		var holder: Sprite2D = child as Sprite2D
		if !should_consider_blocking_holder(holder, moving_holder, from_pos, to_pos):
			continue

		var blocker_footprint: Dictionary = get_footprint_board_geometry(holder)
		if bool(blocker_footprint.get("empty", true)):
			continue
		var blocker_center: Vector2 = blocker_footprint.get("center", Vector2.ZERO)
		if does_segment_touch_footprint(
			start_point,
			end_point,
			blocker_center,
			moving_radius_x,
			moving_radius_y,
			float(blocker_footprint.get("radius_x", 0.0)),
			float(blocker_footprint.get("radius_y", 0.0))
		):
			blocking_holders.append(holder)

	return blocking_holders

func get_footprint_board_geometry(holder: Sprite2D) -> Dictionary:
	if holder == null or !is_instance_valid(holder):
		return {"empty": true}

	var footprint: Dictionary = piece_visuals.get_footprint_geometry(holder) if piece_visuals != null else {}
	if bool(footprint.get("empty", true)):
		return {"empty": true}

	var footprint_center: Vector2 = footprint.get("center", Vector2.ZERO)
	var center: Vector2 = holder.position + Vector2(footprint_center.x * holder.scale.x, footprint_center.y * holder.scale.y)
	if local_space_node != null and is_instance_valid(local_space_node):
		center = local_space_node.to_local(holder.to_global(footprint_center))
	return {
		"empty": false,
		"center": center,
		"radius_x": absf(holder.scale.x) * float(footprint.get("radius_x", 0.0)),
		"radius_y": absf(holder.scale.y) * float(footprint.get("radius_y", 0.0)),
	}

func does_segment_touch_footprint(
	segment_start: Vector2,
	segment_end: Vector2,
	footprint_center: Vector2,
	moving_radius_x: float,
	moving_radius_y: float,
	blocker_radius_x: float,
	blocker_radius_y: float
) -> bool:
	var closest_point: Vector2 = get_closest_point_on_segment(footprint_center, segment_start, segment_end)
	var combined_radius_x: float = maxf(1.0, moving_radius_x + blocker_radius_x + footprint_clearance)
	var combined_radius_y: float = maxf(1.0, moving_radius_y + blocker_radius_y + footprint_clearance)
	var normalized_delta := Vector2(
		(closest_point.x - footprint_center.x) / combined_radius_x,
		(closest_point.y - footprint_center.y) / combined_radius_y
	)
	return normalized_delta.length_squared() <= 1.0

func get_closest_point_on_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> Vector2:
	var segment: Vector2 = segment_end - segment_start
	var segment_length_squared: float = segment.length_squared()
	if segment_length_squared <= 0.0001:
		return segment_start

	var progress: float = clampf((point - segment_start).dot(segment) / segment_length_squared, 0.0, 1.0)
	return segment_start + segment * progress

func get_detour_route_points(from_pos: Vector2, to_pos: Vector2, moving_holder: Sprite2D, blocking_holders: Array[Sprite2D]) -> Array[Vector2]:
	var start_point: Vector2 = get_position_local(from_pos)
	var end_point: Vector2 = get_position_local(to_pos)
	var travel: Vector2 = end_point - start_point
	var travel_length: float = travel.length()
	if travel_length <= 0.0001:
		return [start_point, end_point]

	var moving_footprint: Dictionary = get_footprint_board_geometry(moving_holder)
	var moving_radius_x: float = float(moving_footprint.get("radius_x", float(cell_width) * 0.25))
	var moving_radius_y: float = float(moving_footprint.get("radius_y", footprint_fixed_radius_y))
	var route_blockers: Array[Sprite2D] = []
	for blocker: Sprite2D in blocking_holders:
		if blocker != null and is_instance_valid(blocker) and !route_blockers.has(blocker):
			route_blockers.append(blocker)

	var best_route: Array[Vector2] = [start_point, end_point]
	var best_score: float = INF
	for attempt in range(3):
		var attempt_best_route: Array[Vector2] = []
		var attempt_best_collisions: Array[Sprite2D] = []
		var attempt_best_score: float = INF
		for side_sign: float in [-1.0, 1.0]:
			var candidate_route: Array[Vector2] = build_detour_route_points(
				start_point,
				end_point,
				travel,
				travel_length,
				moving_radius_x,
				moving_radius_y,
				route_blockers,
				side_sign
			)
			candidate_route = simplify_route_points(candidate_route, moving_holder, from_pos, to_pos)
			var collision_holders: Array[Sprite2D] = get_route_blocking_holders(candidate_route, moving_holder, from_pos, to_pos)
			var route_score: float = float(collision_holders.size()) * float(cell_width) * 12.0 + get_route_length(candidate_route)
			if route_score < attempt_best_score:
				attempt_best_score = route_score
				attempt_best_route = candidate_route
				attempt_best_collisions = collision_holders

		if attempt_best_score < best_score:
			best_score = attempt_best_score
			best_route = attempt_best_route
		if attempt_best_collisions.is_empty():
			return attempt_best_route

		var added_blocker: bool = false
		for blocker: Sprite2D in attempt_best_collisions:
			if blocker != null and is_instance_valid(blocker) and !route_blockers.has(blocker):
				route_blockers.append(blocker)
				added_blocker = true
		if !added_blocker:
			break

	return best_route

func build_detour_route_points(
	start_point: Vector2,
	end_point: Vector2,
	travel: Vector2,
	travel_length: float,
	moving_radius_x: float,
	moving_radius_y: float,
	blocking_holders: Array[Sprite2D],
	side_sign: float
) -> Array[Vector2]:
	if travel_length <= 0.0001:
		return [start_point, end_point]

	var travel_direction: Vector2 = travel / travel_length
	var perpendicular := Vector2(-travel_direction.y, travel_direction.x)
	var blocker_entries: Array[Dictionary] = []
	for blocker: Sprite2D in blocking_holders:
		if blocker == null or !is_instance_valid(blocker):
			continue
		var blocker_footprint: Dictionary = get_footprint_board_geometry(blocker)
		if bool(blocker_footprint.get("empty", true)):
			continue

		var blocker_center: Vector2 = blocker_footprint.get("center", Vector2.ZERO)
		var projection: float = clampf((blocker_center - start_point).dot(travel) / maxf(1.0, travel.length_squared()), 0.0, 1.0)
		var combined_radius_x: float = moving_radius_x + float(blocker_footprint.get("radius_x", 0.0)) + footprint_clearance
		var combined_radius_y: float = moving_radius_y + float(blocker_footprint.get("radius_y", 0.0)) + footprint_clearance
		blocker_entries.append({
			"center": blocker_center,
			"projection": projection,
			"along_radius": get_ellipse_radius_in_direction(travel_direction, combined_radius_x, combined_radius_y),
			"side_radius": get_ellipse_radius_in_direction(perpendicular, combined_radius_x, combined_radius_y),
		})

	if blocker_entries.is_empty():
		return [start_point, end_point]

	blocker_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("projection", 0.0)) < float(b.get("projection", 0.0))
	)

	var route_points: Array[Vector2] = [start_point]
	for entry: Dictionary in blocker_entries:
		var projection: float = float(entry.get("projection", 0.0))
		var side_offset: float = float(entry.get("side_radius", float(cell_width) * 0.35)) + maxf(4.0, footprint_clearance * 1.5)
		var along_offset: float = float(entry.get("along_radius", float(cell_width) * 0.25)) * 0.65
		var progress_margin: float = clampf(along_offset / travel_length, 0.04, 0.22)
		var before_progress: float = clampf(projection - progress_margin, 0.0, 1.0)
		var after_progress: float = clampf(projection + progress_margin, 0.0, 1.0)
		var side_vector: Vector2 = perpendicular * side_sign * side_offset
		append_route_point(route_points, start_point + travel * before_progress + side_vector)
		append_route_point(route_points, start_point + travel * after_progress + side_vector)

	append_route_point(route_points, end_point)
	return route_points

func get_ellipse_radius_in_direction(direction: Vector2, radius_x: float, radius_y: float) -> float:
	if direction.length_squared() <= 0.0001:
		return maxf(radius_x, radius_y)

	var normalized_direction: Vector2 = direction.normalized()
	var safe_radius_x: float = maxf(1.0, radius_x)
	var safe_radius_y: float = maxf(1.0, radius_y)
	var denominator: float = (normalized_direction.x * normalized_direction.x) / (safe_radius_x * safe_radius_x)
	denominator += (normalized_direction.y * normalized_direction.y) / (safe_radius_y * safe_radius_y)
	if denominator <= 0.0001:
		return maxf(safe_radius_x, safe_radius_y)

	return 1.0 / sqrt(denominator)

func simplify_route_points(route_points: Array[Vector2], moving_holder: Sprite2D, from_pos: Vector2, to_pos: Vector2) -> Array[Vector2]:
	if route_points.size() <= 3:
		return route_points

	var simplified_points: Array[Vector2] = [route_points[0]]
	var index: int = 1
	while index < route_points.size() - 1:
		var previous_point: Vector2 = simplified_points[simplified_points.size() - 1]
		var next_point: Vector2 = route_points[index + 1]
		if !does_segment_touch_any_occupied_footprint(previous_point, next_point, moving_holder, from_pos, to_pos):
			index += 1
			continue

		append_route_point(simplified_points, route_points[index])
		index += 1

	append_route_point(simplified_points, route_points[route_points.size() - 1])
	return simplified_points

func get_route_blocking_holders(route_points: Array[Vector2], moving_holder: Sprite2D, from_pos: Vector2, to_pos: Vector2) -> Array[Sprite2D]:
	var blocking_holders: Array[Sprite2D] = []
	if route_points.size() < 2 or pieces_node == null:
		return blocking_holders

	var moving_footprint: Dictionary = get_footprint_board_geometry(moving_holder)
	if bool(moving_footprint.get("empty", true)):
		return blocking_holders
	var moving_radius_x: float = float(moving_footprint.get("radius_x", float(cell_width) * 0.25))
	var moving_radius_y: float = float(moving_footprint.get("radius_y", footprint_fixed_radius_y))

	for child in pieces_node.get_children():
		var holder: Sprite2D = child as Sprite2D
		if !should_consider_blocking_holder(holder, moving_holder, from_pos, to_pos):
			continue

		var blocker_footprint: Dictionary = get_footprint_board_geometry(holder)
		if bool(blocker_footprint.get("empty", true)):
			continue
		var blocker_center: Vector2 = blocker_footprint.get("center", Vector2.ZERO)
		for route_index in range(route_points.size() - 1):
			if does_segment_touch_footprint(
				route_points[route_index],
				route_points[route_index + 1],
				blocker_center,
				moving_radius_x,
				moving_radius_y,
				float(blocker_footprint.get("radius_x", 0.0)),
				float(blocker_footprint.get("radius_y", 0.0))
			):
				blocking_holders.append(holder)
				break

	return blocking_holders

func does_segment_touch_any_occupied_footprint(segment_start: Vector2, segment_end: Vector2, moving_holder: Sprite2D, from_pos: Vector2, to_pos: Vector2) -> bool:
	var route_points: Array[Vector2] = [segment_start, segment_end]
	return !get_route_blocking_holders(route_points, moving_holder, from_pos, to_pos).is_empty()

func get_z_index_for_local_position(local_pos: Vector2, moving_holder: Sprite2D = null) -> int:
	var nearest_pos: Vector2 = get_nearest_board_position_for_local_position(local_pos)
	if !_is_valid_position(nearest_pos):
		return 0
	var nearest_center: Vector2 = get_position_local(nearest_pos)
	var front_side: bool = (local_pos.y - nearest_center.y) * float(view_color) >= 0.0
	var side_offset: int = route_z_front_offset if front_side else route_z_back_offset
	var base_z_index: int = get_depth_z_index(nearest_pos) + side_offset
	return get_occlusion_z_index_for_local_position(local_pos, moving_holder, base_z_index)

func get_occlusion_z_index_for_local_position(local_pos: Vector2, moving_holder: Sprite2D, base_z_index: int) -> int:
	if pieces_node == null:
		return base_z_index

	var moving_radius_x: float = float(cell_width) * 0.24
	var moving_radius_y: float = footprint_fixed_radius_y
	var moving_bounds := Rect2()
	var has_moving_bounds: bool = false
	if moving_holder != null and is_instance_valid(moving_holder):
		var moving_footprint: Dictionary = get_footprint_board_geometry(moving_holder)
		if !bool(moving_footprint.get("empty", true)):
			moving_radius_x = float(moving_footprint.get("radius_x", moving_radius_x))
			moving_radius_y = float(moving_footprint.get("radius_y", moving_radius_y))
		moving_bounds = get_sprite_texture_bounds_local(moving_holder).grow(footprint_clearance)
		has_moving_bounds = moving_bounds.size.x > 0.0 and moving_bounds.size.y > 0.0

	var closest_score: float = INF
	var occlusion_z_index: int = base_z_index
	for child in pieces_node.get_children():
		var holder: Sprite2D = child as Sprite2D
		if !should_consider_occlusion_holder(holder, moving_holder):
			continue

		var holder_footprint: Dictionary = get_footprint_board_geometry(holder)
		if bool(holder_footprint.get("empty", true)):
			continue

		var holder_center: Vector2 = holder_footprint.get("center", Vector2.ZERO)
		var combined_radius_x: float = maxf(1.0, moving_radius_x + float(holder_footprint.get("radius_x", 0.0)) + footprint_clearance)
		var combined_radius_y: float = maxf(1.0, moving_radius_y + float(holder_footprint.get("radius_y", 0.0)) + footprint_clearance)
		var normalized_delta := Vector2(
			(local_pos.x - holder_center.x) / combined_radius_x,
			(local_pos.y - holder_center.y) / combined_radius_y
		)
		var overlap_score: float = normalized_delta.length_squared()
		var texture_bounds_overlap: bool = false
		if has_moving_bounds:
			var holder_bounds: Rect2 = get_sprite_texture_bounds_local(holder)
			texture_bounds_overlap = holder_bounds.size.x > 0.0 and holder_bounds.size.y > 0.0 and moving_bounds.intersects(holder_bounds, true)
		if (!texture_bounds_overlap and overlap_score > 1.25) or overlap_score >= closest_score:
			continue

		closest_score = overlap_score
		var moving_is_on_front_side: bool = (local_pos.y - holder_center.y) * float(view_color) >= 0.0
		occlusion_z_index = int(holder.z_index) + (route_z_front_offset if moving_is_on_front_side else route_z_back_offset)

	return occlusion_z_index

func update_holder_travel(
	holder: Sprite2D,
	route_points: Array[Vector2],
	to_pos: Vector2,
	start_scale: Vector2,
	end_scale: Vector2,
	start_offset: Vector2,
	end_offset: Vector2,
	lift_height: float,
	movement_shadow: Sprite2D,
	resting_rotation: float,
	progress: float
) -> void:
	if holder == null or !is_instance_valid(holder):
		return

	var ground_pos: Vector2 = get_polyline_position(route_points, progress)
	if route_points.is_empty() and geometry != null:
		ground_pos = geometry.get_position_local(to_pos)
	var local_pos: Vector2 = ground_pos + Vector2(0.0, -lift_height)
	holder.position = local_pos
	holder.scale = start_scale.lerp(end_scale, progress)
	holder.offset = start_offset.lerp(end_offset, progress)
	holder.z_index = get_z_index_for_local_position(ground_pos, holder) + lifted_z_offset
	holder.rotation = get_travel_rotation(route_points, progress, resting_rotation)
	update_movement_shadow_position(movement_shadow, holder, lift_height)

func get_travel_rotation(route_points: Array[Vector2], progress: float, resting_rotation: float) -> float:
	if route_points.size() < 2 or movement_tilt_degrees <= 0.0:
		return resting_rotation
	var sample_distance: float = 0.025
	var before: Vector2 = get_polyline_position(route_points, maxf(0.0, progress - sample_distance))
	var after: Vector2 = get_polyline_position(route_points, minf(1.0, progress + sample_distance))
	var direction: Vector2 = (after - before).normalized()
	var start_blend: float = smoothstep(0.0, 0.14, progress)
	var end_blend: float = 1.0 - smoothstep(0.82, 1.0, progress)
	var tilt: float = deg_to_rad(movement_tilt_degrees) * direction.x * start_blend * end_blend
	return resting_rotation + tilt

func update_movement_shadow_position(shadow: Sprite2D, holder: Sprite2D, lift_height: float) -> void:
	if shadow == null or !is_instance_valid(shadow):
		return
	var footprint: Dictionary = get_footprint_board_geometry(holder)
	if bool(footprint.get("empty", true)):
		return
	var ground_center: Vector2 = footprint.get("center", holder.position) + Vector2(0.0, lift_height)
	shadow.z_index = get_z_index_for_local_position(ground_center, holder) + movement_shadow_z_offset
	if pieces_node is Node2D and local_space_node != null and is_instance_valid(local_space_node):
		shadow.position = (pieces_node as Node2D).to_local(local_space_node.to_global(ground_center))
	else:
		shadow.position = ground_center

func get_polyline_position(path_points: Array[Vector2], progress: float) -> Vector2:
	if path_points.is_empty():
		return Vector2.ZERO
	if path_points.size() == 1:
		return path_points[0]

	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	var total_length: float = get_route_length(path_points)
	if total_length <= 0.0001:
		return path_points[path_points.size() - 1]

	var target_distance: float = total_length * clamped_progress
	var traversed_distance: float = 0.0
	for index in range(path_points.size() - 1):
		var segment_start: Vector2 = path_points[index]
		var segment_end: Vector2 = path_points[index + 1]
		var segment_length: float = segment_start.distance_to(segment_end)
		if segment_length <= 0.0001:
			continue
		if traversed_distance + segment_length >= target_distance:
			var segment_progress: float = (target_distance - traversed_distance) / segment_length
			return segment_start.lerp(segment_end, segment_progress)
		traversed_distance += segment_length

	return path_points[path_points.size() - 1]

func get_position_local(board_pos: Vector2) -> Vector2:
	if geometry == null:
		return Vector2.ZERO
	return geometry.get_position_local(board_pos)

func get_depth_z_index(board_pos: Vector2) -> int:
	if view_color < 0:
		return int(board_pos.x)
	return board_size - 1 - int(board_pos.x)

func get_nearest_board_position_for_local_position(local_pos: Vector2) -> Vector2:
	if geometry == null:
		return invalid_board_pos

	var nearest_pos: Vector2 = invalid_board_pos
	var nearest_distance_squared: float = INF
	for row in range(board_size):
		for col in range(board_size):
			var board_pos := Vector2(row, col)
			var distance_squared: float = local_pos.distance_squared_to(get_position_local(board_pos))
			if distance_squared < nearest_distance_squared:
				nearest_distance_squared = distance_squared
				nearest_pos = board_pos
	return nearest_pos

func get_sprite_texture_bounds_local(sprite: Sprite2D) -> Rect2:
	if sprite_bounds_provider.is_valid():
		var provided_bounds = sprite_bounds_provider.call(sprite)
		if provided_bounds is Rect2:
			return provided_bounds
	if sprite == null or !is_instance_valid(sprite) or sprite.texture == null:
		return Rect2()

	var texture_size: Vector2 = sprite.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Rect2()

	var local_top_left: Vector2 = sprite.offset
	if sprite.centered:
		local_top_left -= texture_size * 0.5
	var local_bottom_right: Vector2 = local_top_left + texture_size
	var corners := PackedVector2Array([
		local_top_left,
		Vector2(local_bottom_right.x, local_top_left.y),
		local_bottom_right,
		Vector2(local_top_left.x, local_bottom_right.y),
	])
	var board_points := PackedVector2Array()
	for corner: Vector2 in corners:
		if local_space_node != null and is_instance_valid(local_space_node):
			board_points.append(local_space_node.to_local(sprite.to_global(corner)))
		else:
			board_points.append(sprite.position + corner * sprite.scale)

	return get_points_bounds_local(board_points)

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

func should_consider_blocking_holder(holder: Sprite2D, moving_holder: Sprite2D, from_pos: Vector2, to_pos: Vector2) -> bool:
	if !should_consider_visible_holder(holder, moving_holder):
		return false

	var holder_pos: Vector2 = value_to_vector2(holder.get_meta("board_pos", invalid_board_pos), invalid_board_pos)
	if !_is_valid_position(holder_pos) or holder_pos == from_pos or holder_pos == to_pos:
		return false
	return piece_exists_at(holder_pos)

func should_consider_occlusion_holder(holder: Sprite2D, moving_holder: Sprite2D) -> bool:
	if !should_consider_visible_holder(holder, moving_holder):
		return false

	var holder_pos: Vector2 = value_to_vector2(holder.get_meta("board_pos", invalid_board_pos), invalid_board_pos)
	return _is_valid_position(holder_pos) and piece_exists_at(holder_pos)

func should_consider_visible_holder(holder: Sprite2D, moving_holder: Sprite2D) -> bool:
	if holder == null or !is_instance_valid(holder) or holder == moving_holder:
		return false
	return holder.texture != null and holder.visible and holder.self_modulate.a > 0.01 and holder.modulate.a > 0.01

func piece_exists_at(board_pos: Vector2) -> bool:
	if piece_exists_provider.is_valid():
		return bool(piece_exists_provider.call(board_pos))
	return true

func _is_valid_position(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x < board_size and pos.y >= 0 and pos.y < board_size

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
