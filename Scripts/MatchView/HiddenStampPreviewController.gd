extends RefCounted

var canvas_layer: CanvasLayer
var stamp_visual_scene: PackedScene
var stamp_ui_size: Vector2 = Vector2(168.7, 229)
var hidden_stamp_margin: float = 24.0
var hidden_stamp_gap: float = 10.0
var hidden_stamp_scale: float = 0.525
var hidden_stamp_preview_alpha: float = 0.70
var board_size: int = BoardConfig.BOARD_SIZE
var cell_width: int = BoardConfig.CELL_WIDTH
var hidden_stamp_invisibility_shader: Shader
var hidden_stamp_invisibility_radius: float = 0.32
var hidden_stamp_invisibility_effect_control: float = 0.76
var hidden_stamp_invisibility_burn_speed: float = 0.0
var hidden_stamp_invisibility_shape: float = 0.2
var board_screen_scale_provider: Callable = Callable()

var container: Control
var previews: Array[StampVisual] = []
var hidden_stamp_invisibility_noise_texture: Texture2D

func configure(config: Dictionary) -> void:
	canvas_layer = config.get("canvas_layer", canvas_layer)
	stamp_visual_scene = config.get("stamp_visual_scene", stamp_visual_scene)
	stamp_ui_size = config.get("stamp_ui_size", stamp_ui_size)
	hidden_stamp_margin = float(config.get("hidden_stamp_margin", hidden_stamp_margin))
	hidden_stamp_gap = float(config.get("hidden_stamp_gap", hidden_stamp_gap))
	hidden_stamp_scale = float(config.get("hidden_stamp_scale", hidden_stamp_scale))
	hidden_stamp_preview_alpha = float(config.get("hidden_stamp_preview_alpha", hidden_stamp_preview_alpha))
	board_size = int(config.get("board_size", board_size))
	cell_width = int(config.get("cell_width", cell_width))
	hidden_stamp_invisibility_shader = config.get("hidden_stamp_invisibility_shader", hidden_stamp_invisibility_shader)
	hidden_stamp_invisibility_radius = float(config.get("hidden_stamp_invisibility_radius", hidden_stamp_invisibility_radius))
	hidden_stamp_invisibility_effect_control = float(config.get("hidden_stamp_invisibility_effect_control", hidden_stamp_invisibility_effect_control))
	hidden_stamp_invisibility_burn_speed = float(config.get("hidden_stamp_invisibility_burn_speed", hidden_stamp_invisibility_burn_speed))
	hidden_stamp_invisibility_shape = float(config.get("hidden_stamp_invisibility_shape", hidden_stamp_invisibility_shape))
	board_screen_scale_provider = config.get("board_screen_scale_provider", board_screen_scale_provider)

func create_ui() -> Control:
	if container != null and is_instance_valid(container):
		return container
	if canvas_layer == null or !is_instance_valid(canvas_layer):
		return null

	container = Control.new()
	canvas_layer.add_child(container)
	container.visible = false
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.anchor_left = 0.5
	container.anchor_right = 0.5
	container.anchor_top = 0.5
	container.anchor_bottom = 0.5
	container.z_index = 850
	return container

func update_previews(hidden_stamps: Array) -> void:
	clear_previews()
	var preview_container: Control = create_ui()
	if preview_container == null:
		return
	if hidden_stamps.is_empty():
		preview_container.visible = false
		return

	arrange_container(hidden_stamps.size())
	preview_container.visible = true

	var scaled_stamp_size: Vector2 = stamp_ui_size * hidden_stamp_scale
	for i in hidden_stamps.size():
		var hidden_stamp_data: Dictionary = hidden_stamps[i]
		var stamp_name: String = str(hidden_stamp_data.get("stamp_name", ""))
		if stamp_name.is_empty():
			continue

		var stamp: Stamp = StampLibrary.duplicate_stamp(stamp_name)
		if stamp == null:
			continue

		stamp.duration = int(hidden_stamp_data.get("turns_remaining", stamp.duration))
		var stamp_visual: StampVisual = stamp_visual_scene.instantiate() as StampVisual if stamp_visual_scene != null else null
		if stamp_visual == null:
			continue

		preview_container.add_child(stamp_visual)
		stamp_visual.set_hand_context(0, i, Vector2(0.0, i * (scaled_stamp_size.y + hidden_stamp_gap)))
		stamp_visual.set_stamp(stamp)
		stamp_visual.set_face_down(false)
		stamp_visual.draggable = false
		stamp_visual.disabled = true
		stamp_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stamp_visual.scale = Vector2.ONE * hidden_stamp_scale
		stamp_visual.set_preview_alpha(hidden_stamp_preview_alpha)
		stamp_visual.z_index = 850 + i
		stamp_visual.set_ambient_motion_enabled(true)
		previews.append(stamp_visual)
		apply_invisibility_preview_shader(stamp_visual)

func clear_previews() -> void:
	for stamp_visual: StampVisual in previews:
		if stamp_visual and is_instance_valid(stamp_visual):
			stamp_visual.set_ambient_motion_enabled(false)
			stamp_visual.queue_free()
	previews.clear()

func arrange_container(stamp_count: int) -> void:
	if container == null or !is_instance_valid(container):
		return

	var scaled_stamp_size: Vector2 = stamp_ui_size * hidden_stamp_scale
	var total_height: float = float(stamp_count) * scaled_stamp_size.y + float(maxi(0, stamp_count - 1)) * hidden_stamp_gap
	var board_screen_width: float = float(board_size * cell_width) * get_board_screen_scale()
	var left_offset: float = -board_screen_width * 0.5 - hidden_stamp_margin - scaled_stamp_size.x
	container.offset_left = left_offset
	container.offset_right = left_offset + scaled_stamp_size.x
	container.offset_top = -total_height * 0.5
	container.offset_bottom = total_height * 0.5

func get_previews() -> Array[StampVisual]:
	return previews

func get_noise_texture() -> Texture2D:
	if hidden_stamp_invisibility_noise_texture != null:
		return hidden_stamp_invisibility_noise_texture

	var noise := FastNoiseLite.new()
	noise.seed = 18473
	noise.frequency = 0.085
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.52

	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	texture.noise = noise
	hidden_stamp_invisibility_noise_texture = texture
	return hidden_stamp_invisibility_noise_texture

func create_invisibility_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = hidden_stamp_invisibility_shader
	material.set_shader_parameter("textureNoise", get_noise_texture())
	material.set_shader_parameter("radius", hidden_stamp_invisibility_radius)
	material.set_shader_parameter("effectControl", hidden_stamp_invisibility_effect_control)
	material.set_shader_parameter("burnSpeed", hidden_stamp_invisibility_burn_speed)
	material.set_shader_parameter("shape", hidden_stamp_invisibility_shape)
	return material

func apply_invisibility_preview_shader(stamp_visual: StampVisual) -> void:
	if stamp_visual == null or !is_instance_valid(stamp_visual):
		return

	await stamp_visual.get_tree().process_frame
	if stamp_visual == null or !is_instance_valid(stamp_visual):
		return

	var snapshot_texture: Texture2D = await stamp_visual.create_stamp_snapshot_texture()
	if snapshot_texture == null or stamp_visual == null or !is_instance_valid(stamp_visual):
		return

	stamp_visual.set_stamp_content_visible(false)
	if stamp_visual.shadow != null:
		stamp_visual.shadow.visible = false
	if stamp_visual.shimmer != null:
		stamp_visual.shimmer.visible = false

	var snapshot_rect := TextureRect.new()
	snapshot_rect.name = "HiddenInvisibilitySnapshot"
	snapshot_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	snapshot_rect.layout_mode = 1
	snapshot_rect.anchor_left = 0.0
	snapshot_rect.anchor_top = 0.0
	snapshot_rect.anchor_right = 1.0
	snapshot_rect.anchor_bottom = 1.0
	snapshot_rect.offset_left = 0.0
	snapshot_rect.offset_top = 0.0
	snapshot_rect.offset_right = 0.0
	snapshot_rect.offset_bottom = 0.0
	snapshot_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	snapshot_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
	snapshot_rect.texture = snapshot_texture
	snapshot_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	snapshot_rect.material = create_invisibility_material()
	snapshot_rect.self_modulate = Color(1.0, 1.0, 1.0, hidden_stamp_preview_alpha)
	snapshot_rect.z_index = 500
	stamp_visual.add_child(snapshot_rect)

func get_board_screen_scale() -> float:
	if board_screen_scale_provider.is_valid():
		var provided_scale = board_screen_scale_provider.call()
		if provided_scale is float or provided_scale is int:
			return float(provided_scale)
	return 1.0
