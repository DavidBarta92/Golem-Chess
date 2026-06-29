extends RefCounted

var match_board
var board_kuwahara_shader: Shader
var piece_kuwahara_shader: Shader
var board_shader_overlay_z_index: int = 220
var board_shader_radius: int = 1
var piece_kuwahara_radius: int = 2
var board_frame_width: float = BoardConfig.CELL_WIDTH
var board_frame_vertical_extension: float = BoardConfig.CELL_WIDTH

var ambient_board_light_name: String = "AmbientBoardLight"
var ambient_board_fill_light_name: String = "AmbientBoardFillLight"
var ambient_board_light_texture_scale: float = 0.92
var ambient_board_fill_light_texture_scale: float = 2.35
var ambient_board_light_offset: Vector2 = Vector2.ZERO
var ambient_board_light_energy: float = 0.32
var ambient_board_fill_light_energy: float = 0.16
var ambient_board_light_color: Color = Color(1.0, 0.86, 0.58, 1.0)
var ambient_board_light_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.50)
var ambient_board_light_shadow_smooth: float = 2.0
var board_light_receive_mask: int = 1
var piece_light_occluder_mask: int = 1

var ambient_board_light: PointLight2D
var ambient_board_fill_light: PointLight2D
var board_shader_backbuffer: BackBufferCopy
var board_shader_overlay: ColorRect
var board_shader_material: ShaderMaterial
var piece_kuwahara_material: ShaderMaterial

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	board_kuwahara_shader = config.get("board_kuwahara_shader", board_kuwahara_shader)
	piece_kuwahara_shader = config.get("piece_kuwahara_shader", piece_kuwahara_shader)
	board_shader_overlay_z_index = int(config.get("board_shader_overlay_z_index", board_shader_overlay_z_index))
	board_shader_radius = int(config.get("board_shader_radius", board_shader_radius))
	piece_kuwahara_radius = int(config.get("piece_kuwahara_radius", piece_kuwahara_radius))
	board_frame_width = float(config.get("board_frame_width", board_frame_width))
	board_frame_vertical_extension = float(config.get("board_frame_vertical_extension", board_frame_vertical_extension))

	ambient_board_light_name = str(config.get("ambient_board_light_name", ambient_board_light_name))
	ambient_board_fill_light_name = str(config.get("ambient_board_fill_light_name", ambient_board_fill_light_name))
	ambient_board_light_texture_scale = float(config.get("ambient_board_light_texture_scale", ambient_board_light_texture_scale))
	ambient_board_fill_light_texture_scale = float(config.get("ambient_board_fill_light_texture_scale", ambient_board_fill_light_texture_scale))
	ambient_board_light_offset = config.get("ambient_board_light_offset", ambient_board_light_offset)
	ambient_board_light_energy = float(config.get("ambient_board_light_energy", ambient_board_light_energy))
	ambient_board_fill_light_energy = float(config.get("ambient_board_fill_light_energy", ambient_board_fill_light_energy))
	ambient_board_light_color = config.get("ambient_board_light_color", ambient_board_light_color)
	ambient_board_light_shadow_color = config.get("ambient_board_light_shadow_color", ambient_board_light_shadow_color)
	ambient_board_light_shadow_smooth = float(config.get("ambient_board_light_shadow_smooth", ambient_board_light_shadow_smooth))
	board_light_receive_mask = int(config.get("board_light_receive_mask", board_light_receive_mask))
	piece_light_occluder_mask = int(config.get("piece_light_occluder_mask", piece_light_occluder_mask))

func create_ambient_board_light() -> void:
	if ambient_board_light != null and is_instance_valid(ambient_board_light) and ambient_board_fill_light != null and is_instance_valid(ambient_board_fill_light):
		return

	if ambient_board_fill_light == null or !is_instance_valid(ambient_board_fill_light):
		ambient_board_fill_light = PointLight2D.new()
		ambient_board_fill_light.name = ambient_board_fill_light_name
		ambient_board_fill_light.texture = match_board.get_piece_effect_geometry_controller().get_attach_point_light_texture()
		ambient_board_fill_light.texture_scale = ambient_board_fill_light_texture_scale
		ambient_board_fill_light.color = ambient_board_light_color
		ambient_board_fill_light.energy = ambient_board_fill_light_energy
		ambient_board_fill_light.range_item_cull_mask = board_light_receive_mask
		ambient_board_fill_light.shadow_enabled = false
		ambient_board_fill_light.position = ambient_board_light_offset
		match_board.add_child(ambient_board_fill_light)

	if ambient_board_light == null or !is_instance_valid(ambient_board_light):
		ambient_board_light = PointLight2D.new()
		ambient_board_light.name = ambient_board_light_name
		ambient_board_light.texture = match_board.get_piece_effect_geometry_controller().get_attach_point_light_texture()
		ambient_board_light.texture_scale = ambient_board_light_texture_scale
		ambient_board_light.color = ambient_board_light_color
		ambient_board_light.energy = ambient_board_light_energy
		ambient_board_light.range_item_cull_mask = board_light_receive_mask
		ambient_board_light.shadow_enabled = false
		ambient_board_light.shadow_color = ambient_board_light_shadow_color
		ambient_board_light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
		ambient_board_light.shadow_filter_smooth = ambient_board_light_shadow_smooth
		ambient_board_light.shadow_item_cull_mask = piece_light_occluder_mask
		ambient_board_light.position = ambient_board_light_offset
		match_board.add_child(ambient_board_light)

func create_board_shader_overlay() -> void:
	if !match_board.board_shader_enabled:
		remove_board_shader_overlay()
		return

	if board_shader_material == null:
		board_shader_material = ShaderMaterial.new()
		board_shader_material.shader = board_kuwahara_shader
	update_board_shader_material()

	if board_shader_backbuffer == null or !is_instance_valid(board_shader_backbuffer):
		board_shader_backbuffer = BackBufferCopy.new()
		board_shader_backbuffer.name = "BoardShaderBackBuffer"
		board_shader_backbuffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
		board_shader_backbuffer.z_as_relative = false
		board_shader_backbuffer.z_index = board_shader_overlay_z_index - 1
		match_board.add_child(board_shader_backbuffer)

	if board_shader_overlay == null or !is_instance_valid(board_shader_overlay):
		board_shader_overlay = ColorRect.new()
		board_shader_overlay.name = "BoardShaderOverlay"
		board_shader_overlay.color = Color.WHITE
		board_shader_overlay.material = board_shader_material
		board_shader_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		board_shader_overlay.z_as_relative = false
		board_shader_overlay.z_index = board_shader_overlay_z_index
		board_shader_overlay.light_mask = 0
		match_board.add_child(board_shader_overlay)

	update_board_shader_overlay_rect()

func remove_board_shader_overlay() -> void:
	if board_shader_overlay != null and is_instance_valid(board_shader_overlay):
		board_shader_overlay.queue_free()
	if board_shader_backbuffer != null and is_instance_valid(board_shader_backbuffer):
		board_shader_backbuffer.queue_free()
	board_shader_overlay = null
	board_shader_backbuffer = null

func update_board_shader_material() -> void:
	if board_shader_material == null:
		return
	board_shader_material.set_shader_parameter("radius", board_shader_radius)
	board_shader_material.set_shader_parameter("offset", match_board.board_shader_offset)

func update_board_shader_overlay_rect() -> void:
	if board_shader_overlay == null or !is_instance_valid(board_shader_overlay):
		return

	var overlay_rect: Rect2 = get_board_shader_overlay_rect()
	board_shader_overlay.position = overlay_rect.position
	board_shader_overlay.size = overlay_rect.size

func get_board_shader_overlay_rect() -> Rect2:
	var board_polygon: PackedVector2Array = match_board.get_projected_board_rect_polygon(
		board_frame_width,
		board_frame_vertical_extension,
		false
	)
	if board_polygon.size() == 0:
		return BoardConfig.get_board_rect_local().grow(match_board.board_shader_margin)

	return match_board.get_board_geometry().get_points_bounds_local(board_polygon).grow(match_board.board_shader_margin)

func get_piece_kuwahara_material() -> ShaderMaterial:
	if !match_board.piece_kuwahara_enabled:
		return null
	if piece_kuwahara_material == null:
		piece_kuwahara_material = ShaderMaterial.new()
		piece_kuwahara_material.shader = piece_kuwahara_shader
	piece_kuwahara_material.set_shader_parameter("radius", piece_kuwahara_radius)
	piece_kuwahara_material.set_shader_parameter("offset", match_board.piece_kuwahara_offset)
	return piece_kuwahara_material
