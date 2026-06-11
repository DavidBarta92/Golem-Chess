extends RefCounted

var tween_owner: Node
var geometry
var visuals
var board_markers_node: Node2D
var freeze_shader: Shader
var square_texture_provider: Callable
var sync_overlay_to_holder_callback: Callable
var piece_holder_provider: Callable
var should_skip_visual_animations_provider: Callable
var pending_attach_positions_provider: Callable
var piece_objects_provider: Callable
var board_effects_provider: Callable
var player_id_for_color_callback: Callable
var is_valid_position_callback: Callable

var crack_name: String = "PieceFreezeCrack"
var release_name: String = "PieceFreezeRelease"
var square_name: String = "PieceFreezeSquare"
var square_release_name: String = "PieceFreezeSquareRelease"
var crack_z_index: int = 0
var square_z_index: int = 0
var crack_duration: float = 1.5
var crack_release_duration: float = 1.5
var crack_start_width: float = 0.0
var crack_end_width: float = 0.7
var crack_depth: float = 2.46
var crack_scale: float = 7.96
var crack_zebra_scale: float = 1.61
var crack_zebra_amp: float = 1.33
var crack_profile: float = 0.33
var crack_slope: float = 13.03
var refraction_offset: Vector2 = Vector2.ZERO
var reflection_offset: Vector2 = Vector2.ZERO
var square_inset: float = 0.0
var square_alpha: float = 0.74
var piece_effect_light_receive_mask: int = 0

var freeze_visual_signatures: Dictionary = {}

func configure(config: Dictionary) -> void:
	tween_owner = config.get("tween_owner", tween_owner)
	geometry = config.get("geometry", geometry)
	visuals = config.get("visuals", visuals)
	board_markers_node = config.get("board_markers_node", board_markers_node)
	freeze_shader = config.get("freeze_shader", freeze_shader)
	square_texture_provider = config.get("square_texture_provider", square_texture_provider)
	sync_overlay_to_holder_callback = config.get("sync_overlay_to_holder_callback", sync_overlay_to_holder_callback)
	piece_holder_provider = config.get("piece_holder_provider", piece_holder_provider)
	should_skip_visual_animations_provider = config.get("should_skip_visual_animations_provider", should_skip_visual_animations_provider)
	pending_attach_positions_provider = config.get("pending_attach_positions_provider", pending_attach_positions_provider)
	piece_objects_provider = config.get("piece_objects_provider", piece_objects_provider)
	board_effects_provider = config.get("board_effects_provider", board_effects_provider)
	player_id_for_color_callback = config.get("player_id_for_color_callback", player_id_for_color_callback)
	is_valid_position_callback = config.get("is_valid_position_callback", is_valid_position_callback)

	crack_name = str(config.get("crack_name", crack_name))
	release_name = str(config.get("release_name", release_name))
	square_name = str(config.get("square_name", square_name))
	square_release_name = str(config.get("square_release_name", square_release_name))
	crack_z_index = int(config.get("crack_z_index", crack_z_index))
	square_z_index = int(config.get("square_z_index", square_z_index))
	crack_duration = float(config.get("crack_duration", crack_duration))
	crack_release_duration = float(config.get("crack_release_duration", crack_release_duration))
	crack_start_width = float(config.get("crack_start_width", crack_start_width))
	crack_end_width = float(config.get("crack_end_width", crack_end_width))
	crack_depth = float(config.get("crack_depth", crack_depth))
	crack_scale = float(config.get("crack_scale", crack_scale))
	crack_zebra_scale = float(config.get("crack_zebra_scale", crack_zebra_scale))
	crack_zebra_amp = float(config.get("crack_zebra_amp", crack_zebra_amp))
	crack_profile = float(config.get("crack_profile", crack_profile))
	crack_slope = float(config.get("crack_slope", crack_slope))
	refraction_offset = config.get("refraction_offset", refraction_offset)
	reflection_offset = config.get("reflection_offset", reflection_offset)
	square_inset = float(config.get("square_inset", square_inset))
	square_alpha = float(config.get("square_alpha", square_alpha))
	piece_effect_light_receive_mask = int(config.get("piece_effect_light_receive_mask", piece_effect_light_receive_mask))

func apply_overlay(holder: Sprite2D, board_pos: Vector2) -> void:
	remove_overlay(holder)
	remove_square_overlay(board_pos)
	if get_pending_attach_positions().has(board_pos):
		return
	if holder == null or !is_instance_valid(holder) or holder.texture == null:
		freeze_visual_signatures.erase(board_pos)
		return

	var freeze_signature: String = get_visual_signature(board_pos)
	if freeze_signature.is_empty():
		if freeze_visual_signatures.has(board_pos):
			play_release_animation(holder, board_pos)
		freeze_visual_signatures.erase(board_pos)
		return

	var previous_signature: String = str(freeze_visual_signatures.get(board_pos, ""))
	var should_animate: bool = previous_signature != freeze_signature and !should_skip_visual_animations()
	freeze_visual_signatures[board_pos] = freeze_signature

	var freeze_material: ShaderMaterial = create_crack_material(crack_start_width if should_animate else crack_end_width)
	create_piece_overlay(holder, crack_name, freeze_material)
	create_square_overlay(board_pos, freeze_material, square_name)
	if should_animate and can_create_tween():
		var tween: Tween = tween_owner.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(freeze_material, "shader_parameter/crack_width", crack_end_width, crack_duration)

func refresh(board_pos: Vector2) -> void:
	var holder: Sprite2D = get_piece_holder_at(board_pos)
	if holder == null or !is_instance_valid(holder):
		return
	apply_overlay(holder, board_pos)

func create_piece_overlay(holder: Sprite2D, overlay_name: String, freeze_material: ShaderMaterial) -> Sprite2D:
	var overlay := Sprite2D.new()
	overlay.name = overlay_name
	overlay.z_index = crack_z_index
	overlay.z_as_relative = true
	if sync_overlay_to_holder_callback.is_valid():
		sync_overlay_to_holder_callback.call(overlay, holder)
	overlay.material = freeze_material
	holder.add_child(overlay)
	return overlay

func create_square_overlay(board_pos: Vector2, freeze_material: ShaderMaterial, overlay_name: String) -> Polygon2D:
	if board_markers_node == null or !is_instance_valid(board_markers_node):
		return null
	if freeze_material == null or !is_valid_position(board_pos) or geometry == null:
		return null

	var points: PackedVector2Array = geometry.get_cell_polygon_local(board_pos, square_inset)
	if points.size() < 3:
		return null

	var overlay := Polygon2D.new()
	overlay.name = get_square_node_name(board_pos, overlay_name)
	overlay.set_meta("board_pos", board_pos)
	overlay.polygon = points
	overlay.uv = visuals.get_cell_polygon_uvs(points) if visuals != null else PackedVector2Array()
	overlay.texture = get_square_texture()
	overlay.color = Color(1.0, 1.0, 1.0, square_alpha)
	overlay.material = freeze_material
	overlay.z_index = square_z_index
	overlay.light_mask = piece_effect_light_receive_mask
	if visuals != null:
		visuals.enable_canvas_item_antialiasing(overlay)
	board_markers_node.add_child(overlay)
	return overlay

func create_crack_material(
	crack_width: float,
	effect_alpha: float = 1.0,
	alpha_from_cracks: bool = false
) -> ShaderMaterial:
	var freeze_material := ShaderMaterial.new()
	freeze_material.shader = freeze_shader
	freeze_material.set_shader_parameter("crack_depth", crack_depth)
	freeze_material.set_shader_parameter("crack_scale", crack_scale)
	freeze_material.set_shader_parameter("crack_zebra_scale", crack_zebra_scale)
	freeze_material.set_shader_parameter("crack_zebra_amp", crack_zebra_amp)
	freeze_material.set_shader_parameter("crack_profile", crack_profile)
	freeze_material.set_shader_parameter("crack_slope", crack_slope)
	freeze_material.set_shader_parameter("crack_width", crack_width)
	freeze_material.set_shader_parameter("effect_alpha", effect_alpha)
	freeze_material.set_shader_parameter("alpha_from_cracks", alpha_from_cracks)
	freeze_material.set_shader_parameter("refraction_offset", refraction_offset)
	freeze_material.set_shader_parameter("reflection_offset", reflection_offset)
	return freeze_material

func play_release_animation(holder: Sprite2D, board_pos: Vector2) -> void:
	if holder == null or !is_instance_valid(holder) or holder.texture == null:
		return
	if should_skip_visual_animations() or !can_create_tween():
		return

	var existing_release: Node = holder.get_node_or_null(release_name)
	if existing_release != null:
		existing_release.free()
	var freeze_material: ShaderMaterial = create_crack_material(crack_end_width)
	var release_overlay: Sprite2D = create_piece_overlay(holder, release_name, freeze_material)
	var square_release: Polygon2D = create_square_overlay(board_pos, freeze_material, square_release_name)
	var tween: Tween = tween_owner.create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(freeze_material, "shader_parameter/crack_width", crack_start_width, crack_release_duration)
	tween.finished.connect(func():
		if is_instance_valid(release_overlay):
			release_overlay.queue_free()
		if is_instance_valid(square_release):
			square_release.queue_free()
	)

func remove_overlay(holder: Sprite2D) -> void:
	if holder == null or !is_instance_valid(holder):
		return

	var existing_freeze: Node = holder.get_node_or_null(crack_name)
	if existing_freeze != null:
		existing_freeze.free()
	var existing_label: Node = holder.get_node_or_null("RespawnCooldownLabel")
	if existing_label != null:
		existing_label.free()

func remove_square_overlay(board_pos: Vector2) -> void:
	if board_markers_node == null or !is_instance_valid(board_markers_node):
		return

	var existing_square: Node = board_markers_node.get_node_or_null(get_square_node_name(board_pos, square_name))
	if existing_square != null:
		existing_square.free()

func get_visual_signature(board_pos: Vector2) -> String:
	var piece_objects: Dictionary = get_piece_objects()
	if !piece_objects.has(board_pos):
		return ""

	var piece: Piece = piece_objects[board_pos] as Piece
	if piece == null:
		return ""

	var player_id: int = get_player_id_for_color(piece.color)
	var is_frozen_square: bool = CardEffectResolver.is_square_frozen(get_board_effects(), board_pos, player_id)
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

func get_square_node_name(board_pos: Vector2, overlay_name: String) -> String:
	return "%s_%d_%d" % [overlay_name, int(board_pos.x), int(board_pos.y)]

func get_square_texture() -> Texture2D:
	if square_texture_provider.is_valid():
		var value = square_texture_provider.call()
		if value is Texture2D:
			return value
	return null

func get_piece_holder_at(board_pos: Vector2) -> Sprite2D:
	if piece_holder_provider.is_valid():
		var value = piece_holder_provider.call(board_pos)
		if value is Sprite2D:
			return value
	return null

func should_skip_visual_animations() -> bool:
	return bool(should_skip_visual_animations_provider.call()) if should_skip_visual_animations_provider.is_valid() else false

func get_pending_attach_positions() -> Dictionary:
	if pending_attach_positions_provider.is_valid():
		var value = pending_attach_positions_provider.call()
		if value is Dictionary:
			return value
	return {}

func get_piece_objects() -> Dictionary:
	if piece_objects_provider.is_valid():
		var value = piece_objects_provider.call()
		if value is Dictionary:
			return value
	return {}

func get_board_effects() -> Array:
	if board_effects_provider.is_valid():
		var value = board_effects_provider.call()
		if value is Array:
			return value
	return []

func get_player_id_for_color(piece_color: int) -> int:
	if player_id_for_color_callback.is_valid():
		return int(player_id_for_color_callback.call(piece_color))
	return 0

func is_valid_position(board_pos: Vector2) -> bool:
	return bool(is_valid_position_callback.call(board_pos)) if is_valid_position_callback.is_valid() else false

func can_create_tween() -> bool:
	return tween_owner != null and is_instance_valid(tween_owner) and tween_owner.is_inside_tree()
