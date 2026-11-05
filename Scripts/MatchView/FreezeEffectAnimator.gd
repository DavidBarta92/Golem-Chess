extends RefCounted

## The ice on a frozen piece and its square: Docs/Style/FREEZE_ICE.md. Tune the look in
## the two materials; they are copied per square, so a change shows on the next piece
## that freezes.

const PIECE_ICE_MATERIAL: ShaderMaterial = preload("res://Shaders/piece_freeze_ice.tres")
const SQUARE_ICE_MATERIAL: ShaderMaterial = preload("res://Shaders/square_freeze_ice.tres")
const ICE_PARAMETER: String = "shader_parameter/ice_freeze"
const ICE_NAME: String = "PieceFreezeIce"
const RELEASE_NAME: String = "PieceFreezeRelease"
const SQUARE_NAME: String = "PieceFreezeSquare"
const SQUARE_RELEASE_NAME: String = "PieceFreezeSquareRelease"
const FREEZE_DURATION: float = 1.5
const RELEASE_DURATION: float = 1.5

var tween_owner: Node
var geometry
var visuals
var board_markers_node: Node2D
var square_texture_provider: Callable
var sync_overlay_to_holder_callback: Callable
var footprint_metrics_provider: Callable
var piece_holder_provider: Callable
var should_skip_visual_animations_provider: Callable
var pending_affix_positions_provider: Callable
var piece_objects_provider: Callable
var board_effects_provider: Callable
var player_id_for_color_callback: Callable
var is_valid_position_callback: Callable

var piece_effect_light_receive_mask: int = 0

var freeze_visual_signatures: Dictionary = {}

func configure(config: Dictionary) -> void:
	tween_owner = config.get("tween_owner", tween_owner)
	geometry = config.get("geometry", geometry)
	visuals = config.get("visuals", visuals)
	board_markers_node = config.get("board_markers_node", board_markers_node)
	square_texture_provider = config.get("square_texture_provider", square_texture_provider)
	sync_overlay_to_holder_callback = config.get("sync_overlay_to_holder_callback", sync_overlay_to_holder_callback)
	footprint_metrics_provider = config.get("footprint_metrics_provider", footprint_metrics_provider)
	piece_holder_provider = config.get("piece_holder_provider", piece_holder_provider)
	should_skip_visual_animations_provider = config.get("should_skip_visual_animations_provider", should_skip_visual_animations_provider)
	pending_affix_positions_provider = config.get("pending_affix_positions_provider", pending_affix_positions_provider)
	piece_objects_provider = config.get("piece_objects_provider", piece_objects_provider)
	board_effects_provider = config.get("board_effects_provider", board_effects_provider)
	player_id_for_color_callback = config.get("player_id_for_color_callback", player_id_for_color_callback)
	is_valid_position_callback = config.get("is_valid_position_callback", is_valid_position_callback)

	piece_effect_light_receive_mask = int(config.get("piece_effect_light_receive_mask", piece_effect_light_receive_mask))

func apply_overlay(holder: Sprite2D, board_pos: Vector2) -> void:
	remove_overlay(holder)
	remove_square_overlay(board_pos)
	if get_pending_affix_positions().has(board_pos):
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

	var piece_ice: ShaderMaterial = create_ice_material(PIECE_ICE_MATERIAL, board_pos, 0.0 if should_animate else 1.0)
	var square_ice: ShaderMaterial = create_ice_material(SQUARE_ICE_MATERIAL, board_pos, 0.0 if should_animate else 1.0)
	create_piece_overlay(holder, ICE_NAME, piece_ice)
	create_square_overlay(board_pos, square_ice, SQUARE_NAME)
	if should_animate and can_create_tween():
		SFXManager.play("piece_freezes")
		tween_ice([piece_ice, square_ice], 1.0, FREEZE_DURATION, Tween.EASE_OUT)

func refresh(board_pos: Vector2) -> void:
	var holder: Sprite2D = get_piece_holder_at(board_pos)
	if holder == null or !is_instance_valid(holder):
		return
	apply_overlay(holder, board_pos)

func create_piece_overlay(holder: Sprite2D, overlay_name: String, ice_material: ShaderMaterial) -> Sprite2D:
	var overlay := Sprite2D.new()
	overlay.name = overlay_name
	if sync_overlay_to_holder_callback.is_valid():
		sync_overlay_to_holder_callback.call(overlay, holder)
	# The ice hides the piece, so the piece's hover dim and fade have to carry over.
	overlay.self_modulate = holder.self_modulate
	fit_ice_to_holder(ice_material, holder)
	overlay.material = ice_material
	holder.add_child(overlay)
	return overlay

func create_square_overlay(board_pos: Vector2, ice_material: ShaderMaterial, overlay_name: String) -> Polygon2D:
	if board_markers_node == null or !is_instance_valid(board_markers_node):
		return null
	if ice_material == null or !is_valid_position(board_pos) or geometry == null:
		return null

	var points: PackedVector2Array = geometry.get_cell_polygon_local(board_pos, 0.0)
	if points.size() < 3:
		return null

	var overlay := Polygon2D.new()
	overlay.name = get_square_node_name(board_pos, overlay_name)
	overlay.set_meta("board_pos", board_pos)
	overlay.polygon = points
	overlay.texture = get_square_texture()
	# Polygon2D reads its uv in the texture's pixels, and the shader wants 0..1.
	if visuals != null and overlay.texture != null:
		overlay.uv = Transform2D().scaled(overlay.texture.get_size()) * visuals.get_cell_polygon_uvs(points)
	overlay.material = ice_material
	overlay.light_mask = piece_effect_light_receive_mask
	if visuals != null:
		visuals.enable_canvas_item_antialiasing(overlay)
	board_markers_node.add_child(overlay)
	return overlay

func create_ice_material(template: ShaderMaterial, board_pos: Vector2, amount: float) -> ShaderMaterial:
	var ice_material: ShaderMaterial = template.duplicate()
	ice_material.set_shader_parameter("ice_freeze", amount)
	ice_material.set_shader_parameter("ice_seed", Vector2(fposmod(board_pos.x * 0.37, 1.0), fposmod(board_pos.y * 0.61, 1.0)))
	return ice_material

## Tells the ice how big the piece is on the board and where in its picture the
## figure stands. The pictures' sizes differ; the pieces on the board do not.
func fit_ice_to_holder(ice_material: ShaderMaterial, holder: Sprite2D) -> void:
	var texture_size: Vector2 = holder.texture.get_size()
	ice_material.set_shader_parameter("art_size", texture_size * holder.scale)
	var metrics: Dictionary = footprint_metrics_provider.call(holder.texture) if footprint_metrics_provider.is_valid() else {}
	if !metrics.is_empty():
		ice_material.set_shader_parameter("figure_rows", Vector2(metrics["top_y"], metrics["bottom_y"]) / texture_size.y)

func tween_ice(ice_materials: Array, amount: float, duration: float, ease_type: Tween.EaseType) -> Tween:
	var tween: Tween = tween_owner.create_tween().set_parallel(true).set_ease(ease_type).set_trans(Tween.TRANS_SINE)
	for ice_material: ShaderMaterial in ice_materials:
		tween.tween_property(ice_material, ICE_PARAMETER, amount, duration)
	return tween

func play_release_animation(holder: Sprite2D, board_pos: Vector2) -> void:
	if holder == null or !is_instance_valid(holder) or holder.texture == null:
		return
	if should_skip_visual_animations() or !can_create_tween():
		return

	var existing_release: Node = holder.get_node_or_null(RELEASE_NAME)
	if existing_release != null:
		existing_release.free()
	var piece_ice: ShaderMaterial = create_ice_material(PIECE_ICE_MATERIAL, board_pos, 1.0)
	var square_ice: ShaderMaterial = create_ice_material(SQUARE_ICE_MATERIAL, board_pos, 1.0)
	var release_overlay: Sprite2D = create_piece_overlay(holder, RELEASE_NAME, piece_ice)
	var square_release: Polygon2D = create_square_overlay(board_pos, square_ice, SQUARE_RELEASE_NAME)
	var tween: Tween = tween_ice([piece_ice, square_ice], 0.0, RELEASE_DURATION, Tween.EASE_IN)
	# Held weakly: a refresh while the release is still playing frees both
	# overlays at once (apply_overlay), and a lambda that had captured them
	# outright would then be called with freed objects.
	var release_ref: WeakRef = weakref(release_overlay)
	var square_ref: WeakRef = weakref(square_release)
	tween.finished.connect(func():
		for overlay_ref: WeakRef in [release_ref, square_ref]:
			var overlay: Node = overlay_ref.get_ref() as Node
			if overlay != null:
				overlay.queue_free()
	)

func remove_overlay(holder: Sprite2D) -> void:
	if holder == null or !is_instance_valid(holder):
		return

	var existing_freeze: Node = holder.get_node_or_null(ICE_NAME)
	if existing_freeze != null:
		existing_freeze.free()
	var existing_label: Node = holder.get_node_or_null("RespawnCooldownLabel")
	if existing_label != null:
		existing_label.free()

func remove_square_overlay(board_pos: Vector2) -> void:
	if board_markers_node == null or !is_instance_valid(board_markers_node):
		return

	var existing_square: Node = board_markers_node.get_node_or_null(get_square_node_name(board_pos, SQUARE_NAME))
	if existing_square != null:
		existing_square.free()

## The piece went out of sight with its ice on, so there is nothing left to melt
## when it comes back.
func forget(board_pos: Vector2) -> void:
	freeze_visual_signatures.erase(board_pos)

## The ice over a piece, for whatever has to follow the piece's tint.
func get_overlay(holder: Sprite2D) -> Sprite2D:
	return holder.get_node_or_null(ICE_NAME) as Sprite2D

func get_visual_signature(board_pos: Vector2) -> String:
	var piece_objects: Dictionary = get_piece_objects()
	if !piece_objects.has(board_pos):
		return ""

	var piece: Piece = piece_objects[board_pos] as Piece
	if piece == null:
		return ""

	var player_id: int = get_player_id_for_color(piece.color)
	var is_frozen_square: bool = StampEffectResolver.is_square_frozen(get_board_effects(), board_pos, player_id)
	# Locked golems carry the flag too, for as long as they stay locked, but they
	# are not frozen: they lie as rubble, or at half opacity without the shatter.
	var is_exhausted_piece: bool = piece.exhausted_this_turn and !piece.is_respawn_locked()
	if !is_frozen_square and !is_exhausted_piece:
		return ""

	var affixed_stamp_name: String = ""
	if piece.affixed_stamp != null:
		affixed_stamp_name = piece.affixed_stamp.stamp_name

	return "%s:%s:%s:%s:%s" % [
		board_pos,
		piece.color,
		affixed_stamp_name,
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

func get_pending_affix_positions() -> Dictionary:
	if pending_affix_positions_provider.is_valid():
		var value = pending_affix_positions_provider.call()
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
