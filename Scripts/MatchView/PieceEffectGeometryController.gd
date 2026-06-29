extends RefCounted

var match_board
var invalid_board_pos: Vector2 = Vector2(-1, -1)
var attach_point_light_texture_size: int = 256
var light_texture_grain_strength: float = 0.12
var light_texture_fine_grain_strength: float = 0.045
var light_texture_grain_frequency: float = 0.085
var light_texture_fine_grain_frequency: float = 0.31

var attach_point_light_texture: Texture2D

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)
	attach_point_light_texture_size = int(config.get("attach_point_light_texture_size", attach_point_light_texture_size))
	light_texture_grain_strength = float(config.get("light_texture_grain_strength", light_texture_grain_strength))
	light_texture_fine_grain_strength = float(config.get("light_texture_fine_grain_strength", light_texture_fine_grain_strength))
	light_texture_grain_frequency = float(config.get("light_texture_grain_frequency", light_texture_grain_frequency))
	light_texture_fine_grain_frequency = float(config.get("light_texture_fine_grain_frequency", light_texture_fine_grain_frequency))

func get_attach_point_light_texture() -> Texture2D:
	if attach_point_light_texture != null:
		return attach_point_light_texture

	var texture_size: int = attach_point_light_texture_size
	var image := Image.create(texture_size, texture_size, false, Image.FORMAT_RGBA8)
	var center := Vector2(float(texture_size) * 0.5, float(texture_size) * 0.5)
	var radius: float = float(texture_size) * 0.5
	var grain_noise := FastNoiseLite.new()
	grain_noise.seed = 91357
	grain_noise.frequency = light_texture_grain_frequency
	grain_noise.fractal_octaves = 3
	grain_noise.fractal_gain = 0.52
	var fine_grain_noise := FastNoiseLite.new()
	fine_grain_noise.seed = 24731
	fine_grain_noise.frequency = light_texture_fine_grain_frequency
	fine_grain_noise.fractal_octaves = 2
	fine_grain_noise.fractal_gain = 0.44
	for y in texture_size:
		for x in texture_size:
			var pixel_pos := Vector2(float(x) + 0.5, float(y) + 0.5)
			var distance_ratio: float = clampf(pixel_pos.distance_to(center) / radius, 0.0, 1.0)
			var alpha: float = pow(1.0 - distance_ratio, 1.85)
			var grain: float = grain_noise.get_noise_2d(float(x), float(y)) * light_texture_grain_strength
			grain += fine_grain_noise.get_noise_2d(float(x), float(y)) * light_texture_fine_grain_strength
			alpha = clampf(alpha * (1.0 + grain), 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))

	attach_point_light_texture = ImageTexture.create_from_image(image)
	return attach_point_light_texture

func get_piece_light_global_position_for_texture(holder: Sprite2D, texture_value: Texture2D) -> Vector2:
	if match_board == null or holder == null or !is_instance_valid(holder):
		return Vector2.ZERO

	var board_pos: Vector2 = match_board.value_to_vector2(holder.get_meta("board_pos", invalid_board_pos), invalid_board_pos)
	if !match_board.is_valid_position(board_pos):
		return holder.to_global(holder.offset)

	var visual_transform: Dictionary = match_board.get_piece_visuals().get_visual_transform_for_texture(texture_value, board_pos)
	var visual_scale: Vector2 = visual_transform.get("scale", holder.scale)
	var visual_offset: Vector2 = visual_transform.get("offset", holder.offset)
	var scaled_offset := Vector2(visual_offset.x * visual_scale.x, visual_offset.y * visual_scale.y)
	var parent_node := holder.get_parent()
	if parent_node is Node2D:
		var parent_2d := parent_node as Node2D
		return parent_2d.to_global(holder.position + scaled_offset.rotated(holder.rotation))

	return holder.to_global(visual_offset)

func get_sprite_texture_bounds_local(sprite: Sprite2D) -> Rect2:
	if match_board == null or sprite == null or !is_instance_valid(sprite) or sprite.texture == null:
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
		board_points.append(match_board.to_local(sprite.to_global(corner)))

	return match_board.get_points_bounds_local(board_points)
