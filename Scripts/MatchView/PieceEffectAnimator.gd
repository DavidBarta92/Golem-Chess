extends RefCounted

var geometry
var piece_visuals
var pieces_node: Node
var piece_effects_node: Node
var tween_owner: Node
var texture_holder_scene: PackedScene
var cell_width: int = BoardConfig.CELL_WIDTH
var board_size: int = BoardConfig.BOARD_SIZE
var texture_filter_value = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
var board_light_receive_mask: int = 1
var piece_light_receive_mask: int = 2
var piece_effect_light_receive_mask: int = 0
var piece_light_occluder_mask: int = 1
var flipped_view: bool = false

var capture_flash_texture: Texture2D
var capture_flash_color: Color = Color(1.0, 0.92, 0.56, 1.0)
var capture_flash_duration: float = 0.75
var capture_flash_size_ratio: float = 1.95
var capture_flash_start_scale_ratio: float = 0.16
var capture_flash_rotation_degrees: float = 22.0
var default_piece_visual_height: float = 24.0

var bomb_warning_texture: Texture2D
var bomb_warning_color: Color = Color(1.0, 0.56, 0.56, 1.0)
var bomb_warning_duration: float = 1.5
var bomb_warning_rise_distance: float = 7.0
var bomb_warning_size_ratio: float = 1.15
var bomb_warning_target_y_offset: float = -6.0
var bomb_warning_z_offset: int = 7

var piece_expire_dissolve_shader: Shader
var piece_expire_dissolve_duration: float = 1.62
var piece_expire_dissolve_beam_size: float = 0.05
var piece_expire_dissolve_noise_density: float = 60.0
var piece_expire_dissolve_color: Color = Color(1.0, 0.42, 0.02, 1.0)

var piece_invisibility_refract_shader: Shader
var piece_invisibility_visible_hold_duration: float = 0.50
var piece_invisibility_refract_in_duration: float = 0.42
var piece_invisibility_fade_out_duration: float = 1.48
var piece_invisibility_refract_distance: float = 16.0

var attach_point_light_name: String = "AttachPointLight"
var attach_piece_light_name: String = "AttachPieceLight"
var attach_point_light_texture_scale: float = 0.92
var attach_point_light_color: Color = Color(1.0, 0.74, 0.24, 1.0)
var attach_point_light_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.52)
var attach_point_light_shadow_smooth: float = 2.5
var attach_piece_light_texture_scale: float = 1.08
var attach_piece_light_color: Color = Color(1.0, 0.84, 0.36, 1.0)
var attach_point_light_energy: float = 1.25
var attach_piece_light_energy: float = 0.62
var piece_attach_glow_name: String = "PieceAttachGlow"
var piece_attach_rays_name: String = "PieceAttachRays"
var piece_attach_morph_name: String = "PieceAttachMorph"
var piece_effect_occlusion_dim_name: String = "PieceEffectOcclusionDim"
var piece_attach_glow_z_index: int = 0
var piece_attach_rays_z_index: int = 0
var piece_attach_morph_z_index: int = 0
var piece_effect_occlusion_dim_z_index: int = 0
var piece_attach_glow_shader: Shader
var piece_attach_rays_shader: Shader
var piece_texture_morph_shader: Shader
var piece_attach_glow_color: Color = Color(1.0, 0.82, 0.28, 1.0)
var occluded_piece_effect_dim_color: Color = Color(0.0, 0.0, 0.0, 0.34)
var piece_attach_glow_size: float = 4.8
var piece_attach_glow_fill_strength: float = 0.30
var piece_attach_glow_base_strength: float = 1.0
var piece_attach_glow_switch_strength: float = 4.0
var piece_attach_glow_switch_duration: float = 0.06
var piece_attach_in_duration: float = 0.32
var piece_attach_pre_switch_hold_duration: float = 0.14
var piece_attach_morph_duration: float = 1.00
var piece_attach_post_switch_hold_duration: float = 0.20
var piece_attach_morph_noise_strength: float = 0.14
var piece_attach_morph_shine_strength: float = 0.34
var piece_attach_out_duration: float = 0.32
var piece_attach_rays_start_size: float = 10.0
var piece_attach_rays_switch_size: float = 1.0
var piece_attach_rays_texture_size: int = 256
var piece_attach_rays_overlay_scale: float = 2.65
var piece_attach_rays_local_offset: Vector2 = Vector2.ZERO
var piece_attach_rays_spread: float = 0.5
var piece_attach_rays_cutoff: float = 0.39
var piece_attach_rays_speed: float = 1.4
var piece_attach_rays_ray1_density: float = 8.0
var piece_attach_rays_ray2_density: float = 10.0
var piece_attach_rays_ray2_intensity: float = 0.3
var piece_attach_rays_core_intensity: float = 2.0
var piece_attach_rays_seed: float = 5.0
var piece_attach_rays_fade_in_delay_ratio: float = 0.0
var piece_attach_rays_fade_in_duration_ratio: float = 1.0
var attach_point_light_texture_provider: Callable = Callable()
var piece_light_global_position_provider: Callable = Callable()
var sprite_bounds_provider: Callable = Callable()
var piece_attach_rays_square_texture: Texture2D

func configure(config: Dictionary) -> void:
	geometry = config.get("geometry", geometry)
	piece_visuals = config.get("piece_visuals", piece_visuals)
	pieces_node = config.get("pieces_node", pieces_node)
	piece_effects_node = config.get("piece_effects_node", piece_effects_node)
	tween_owner = config.get("tween_owner", tween_owner)
	texture_holder_scene = config.get("texture_holder_scene", texture_holder_scene)
	cell_width = int(config.get("cell_width", cell_width))
	board_size = int(config.get("board_size", board_size))
	texture_filter_value = config.get("texture_filter", texture_filter_value)
	board_light_receive_mask = int(config.get("board_light_receive_mask", board_light_receive_mask))
	piece_light_receive_mask = int(config.get("piece_light_receive_mask", piece_light_receive_mask))
	piece_effect_light_receive_mask = int(config.get("piece_effect_light_receive_mask", piece_effect_light_receive_mask))
	piece_light_occluder_mask = int(config.get("piece_light_occluder_mask", piece_light_occluder_mask))
	flipped_view = bool(config.get("flipped_view", flipped_view))

	capture_flash_texture = config.get("capture_flash_texture", capture_flash_texture)
	capture_flash_color = config.get("capture_flash_color", capture_flash_color)
	capture_flash_duration = float(config.get("capture_flash_duration", capture_flash_duration))
	capture_flash_size_ratio = float(config.get("capture_flash_size_ratio", capture_flash_size_ratio))
	capture_flash_start_scale_ratio = float(config.get("capture_flash_start_scale_ratio", capture_flash_start_scale_ratio))
	capture_flash_rotation_degrees = float(config.get("capture_flash_rotation_degrees", capture_flash_rotation_degrees))
	default_piece_visual_height = float(config.get("default_piece_visual_height", default_piece_visual_height))

	bomb_warning_texture = config.get("bomb_warning_texture", bomb_warning_texture)
	bomb_warning_color = config.get("bomb_warning_color", bomb_warning_color)
	bomb_warning_duration = float(config.get("bomb_warning_duration", bomb_warning_duration))
	bomb_warning_rise_distance = float(config.get("bomb_warning_rise_distance", bomb_warning_rise_distance))
	bomb_warning_size_ratio = float(config.get("bomb_warning_size_ratio", bomb_warning_size_ratio))
	bomb_warning_target_y_offset = float(config.get("bomb_warning_target_y_offset", bomb_warning_target_y_offset))
	bomb_warning_z_offset = int(config.get("bomb_warning_z_offset", bomb_warning_z_offset))

	piece_expire_dissolve_shader = config.get("piece_expire_dissolve_shader", piece_expire_dissolve_shader)
	piece_expire_dissolve_duration = float(config.get("piece_expire_dissolve_duration", piece_expire_dissolve_duration))
	piece_expire_dissolve_beam_size = float(config.get("piece_expire_dissolve_beam_size", piece_expire_dissolve_beam_size))
	piece_expire_dissolve_noise_density = float(config.get("piece_expire_dissolve_noise_density", piece_expire_dissolve_noise_density))
	piece_expire_dissolve_color = config.get("piece_expire_dissolve_color", piece_expire_dissolve_color)

	piece_invisibility_refract_shader = config.get("piece_invisibility_refract_shader", piece_invisibility_refract_shader)
	piece_invisibility_visible_hold_duration = float(config.get("piece_invisibility_visible_hold_duration", piece_invisibility_visible_hold_duration))
	piece_invisibility_refract_in_duration = float(config.get("piece_invisibility_refract_in_duration", piece_invisibility_refract_in_duration))
	piece_invisibility_fade_out_duration = float(config.get("piece_invisibility_fade_out_duration", piece_invisibility_fade_out_duration))
	piece_invisibility_refract_distance = float(config.get("piece_invisibility_refract_distance", piece_invisibility_refract_distance))

	attach_point_light_name = str(config.get("attach_point_light_name", attach_point_light_name))
	attach_piece_light_name = str(config.get("attach_piece_light_name", attach_piece_light_name))
	attach_point_light_texture_scale = float(config.get("attach_point_light_texture_scale", attach_point_light_texture_scale))
	attach_point_light_color = config.get("attach_point_light_color", attach_point_light_color)
	attach_point_light_shadow_color = config.get("attach_point_light_shadow_color", attach_point_light_shadow_color)
	attach_point_light_shadow_smooth = float(config.get("attach_point_light_shadow_smooth", attach_point_light_shadow_smooth))
	attach_piece_light_texture_scale = float(config.get("attach_piece_light_texture_scale", attach_piece_light_texture_scale))
	attach_piece_light_color = config.get("attach_piece_light_color", attach_piece_light_color)
	attach_point_light_energy = float(config.get("attach_point_light_energy", attach_point_light_energy))
	attach_piece_light_energy = float(config.get("attach_piece_light_energy", attach_piece_light_energy))
	piece_attach_glow_name = str(config.get("piece_attach_glow_name", piece_attach_glow_name))
	piece_attach_rays_name = str(config.get("piece_attach_rays_name", piece_attach_rays_name))
	piece_attach_morph_name = str(config.get("piece_attach_morph_name", piece_attach_morph_name))
	piece_effect_occlusion_dim_name = str(config.get("piece_effect_occlusion_dim_name", piece_effect_occlusion_dim_name))
	piece_attach_glow_z_index = int(config.get("piece_attach_glow_z_index", piece_attach_glow_z_index))
	piece_attach_rays_z_index = int(config.get("piece_attach_rays_z_index", piece_attach_rays_z_index))
	piece_attach_morph_z_index = int(config.get("piece_attach_morph_z_index", piece_attach_morph_z_index))
	piece_effect_occlusion_dim_z_index = int(config.get("piece_effect_occlusion_dim_z_index", piece_effect_occlusion_dim_z_index))
	piece_attach_glow_shader = config.get("piece_attach_glow_shader", piece_attach_glow_shader)
	piece_attach_rays_shader = config.get("piece_attach_rays_shader", piece_attach_rays_shader)
	piece_texture_morph_shader = config.get("piece_texture_morph_shader", piece_texture_morph_shader)
	piece_attach_glow_color = config.get("piece_attach_glow_color", piece_attach_glow_color)
	occluded_piece_effect_dim_color = config.get("occluded_piece_effect_dim_color", occluded_piece_effect_dim_color)
	piece_attach_glow_size = float(config.get("piece_attach_glow_size", piece_attach_glow_size))
	piece_attach_glow_fill_strength = float(config.get("piece_attach_glow_fill_strength", piece_attach_glow_fill_strength))
	piece_attach_glow_base_strength = float(config.get("piece_attach_glow_base_strength", piece_attach_glow_base_strength))
	piece_attach_glow_switch_strength = float(config.get("piece_attach_glow_switch_strength", piece_attach_glow_switch_strength))
	piece_attach_glow_switch_duration = float(config.get("piece_attach_glow_switch_duration", piece_attach_glow_switch_duration))
	piece_attach_in_duration = float(config.get("piece_attach_in_duration", piece_attach_in_duration))
	piece_attach_pre_switch_hold_duration = float(config.get("piece_attach_pre_switch_hold_duration", piece_attach_pre_switch_hold_duration))
	piece_attach_morph_duration = float(config.get("piece_attach_morph_duration", piece_attach_morph_duration))
	piece_attach_post_switch_hold_duration = float(config.get("piece_attach_post_switch_hold_duration", piece_attach_post_switch_hold_duration))
	piece_attach_morph_noise_strength = float(config.get("piece_attach_morph_noise_strength", piece_attach_morph_noise_strength))
	piece_attach_morph_shine_strength = float(config.get("piece_attach_morph_shine_strength", piece_attach_morph_shine_strength))
	piece_attach_out_duration = float(config.get("piece_attach_out_duration", piece_attach_out_duration))
	piece_attach_rays_start_size = float(config.get("piece_attach_rays_start_size", piece_attach_rays_start_size))
	piece_attach_rays_switch_size = float(config.get("piece_attach_rays_switch_size", piece_attach_rays_switch_size))
	piece_attach_rays_texture_size = int(config.get("piece_attach_rays_texture_size", piece_attach_rays_texture_size))
	piece_attach_rays_overlay_scale = float(config.get("piece_attach_rays_overlay_scale", piece_attach_rays_overlay_scale))
	piece_attach_rays_local_offset = config.get("piece_attach_rays_local_offset", piece_attach_rays_local_offset)
	piece_attach_rays_spread = float(config.get("piece_attach_rays_spread", piece_attach_rays_spread))
	piece_attach_rays_cutoff = float(config.get("piece_attach_rays_cutoff", piece_attach_rays_cutoff))
	piece_attach_rays_speed = float(config.get("piece_attach_rays_speed", piece_attach_rays_speed))
	piece_attach_rays_ray1_density = float(config.get("piece_attach_rays_ray1_density", piece_attach_rays_ray1_density))
	piece_attach_rays_ray2_density = float(config.get("piece_attach_rays_ray2_density", piece_attach_rays_ray2_density))
	piece_attach_rays_ray2_intensity = float(config.get("piece_attach_rays_ray2_intensity", piece_attach_rays_ray2_intensity))
	piece_attach_rays_core_intensity = float(config.get("piece_attach_rays_core_intensity", piece_attach_rays_core_intensity))
	piece_attach_rays_seed = float(config.get("piece_attach_rays_seed", piece_attach_rays_seed))
	piece_attach_rays_fade_in_delay_ratio = float(config.get("piece_attach_rays_fade_in_delay_ratio", piece_attach_rays_fade_in_delay_ratio))
	piece_attach_rays_fade_in_duration_ratio = float(config.get("piece_attach_rays_fade_in_duration_ratio", piece_attach_rays_fade_in_duration_ratio))
	attach_point_light_texture_provider = config.get("attach_point_light_texture_provider", attach_point_light_texture_provider)
	piece_light_global_position_provider = config.get("piece_light_global_position_provider", piece_light_global_position_provider)
	sprite_bounds_provider = config.get("sprite_bounds_provider", sprite_bounds_provider)

func create_effect_holder(piece_position: Vector2, texture_value: Texture2D, holder_name: String = "PieceEffect") -> Sprite2D:
	if texture_value == null or !_is_valid_position(piece_position) or !has_effect_parent():
		return null

	var holder: Sprite2D = null
	if texture_holder_scene != null:
		holder = texture_holder_scene.instantiate() as Sprite2D
	else:
		holder = Sprite2D.new()
	if holder == null:
		return null

	if flipped_view:
		holder.global_rotation_degrees = 180
	piece_effects_node.add_child(holder)
	holder.name = holder_name
	holder.light_mask = piece_effect_light_receive_mask
	holder.texture_filter = texture_filter_value
	holder.position = get_position_local(piece_position)
	holder.set_meta("board_pos", piece_position)
	holder.z_as_relative = false
	holder.z_index = get_piece_effect_z_index(piece_position)
	holder.texture = texture_value
	holder.self_modulate = Color.WHITE
	apply_piece_visual_size(holder, piece_position)
	return holder

func create_attach_point_light(holder: Sprite2D) -> PointLight2D:
	if holder == null or !is_instance_valid(holder):
		return null

	var parent_node: Node = get_light_parent()
	if parent_node == null:
		return null

	var point_light := PointLight2D.new()
	point_light.name = attach_point_light_name
	point_light.texture = get_attach_point_light_texture()
	point_light.texture_scale = attach_point_light_texture_scale
	point_light.color = attach_point_light_color
	point_light.energy = 0.0
	point_light.range_item_cull_mask = board_light_receive_mask
	point_light.shadow_enabled = true
	point_light.shadow_color = attach_point_light_shadow_color
	point_light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	point_light.shadow_filter_smooth = attach_point_light_shadow_smooth
	point_light.shadow_item_cull_mask = piece_light_occluder_mask
	parent_node.add_child(point_light)
	point_light.global_position = get_piece_light_global_position(holder, holder.texture)
	return point_light

func create_attach_sprite_light(holder: Sprite2D) -> PointLight2D:
	if holder == null or !is_instance_valid(holder):
		return null

	var parent_node: Node = get_light_parent()
	if parent_node == null:
		return null

	var piece_light := PointLight2D.new()
	piece_light.name = attach_piece_light_name
	piece_light.texture = get_attach_point_light_texture()
	piece_light.texture_scale = attach_piece_light_texture_scale
	piece_light.color = attach_piece_light_color
	piece_light.energy = 0.0
	piece_light.range_item_cull_mask = piece_light_receive_mask
	piece_light.shadow_enabled = false
	parent_node.add_child(piece_light)
	piece_light.global_position = get_piece_light_global_position(holder, holder.texture)
	return piece_light

func update_attach_point_light_position(point_light, holder) -> void:
	if point_light == null or !is_instance_valid(point_light) or !(point_light is PointLight2D):
		return
	if holder == null or !is_instance_valid(holder) or !(holder is Sprite2D):
		return

	var piece_light := point_light as PointLight2D
	var holder_sprite := holder as Sprite2D

	piece_light.global_position = get_piece_light_global_position(holder_sprite, holder_sprite.texture)

func cleanup_attach_point_light(holder, point_light, piece_light = null) -> void:
	if point_light != null and is_instance_valid(point_light):
		point_light.queue_free()
	if piece_light != null and is_instance_valid(piece_light):
		piece_light.queue_free()
	set_holder_light_occluder_enabled(holder, true)

func cleanup_attach_animation_layers(holder, point_light, piece_light, occlusion_dimmers: Array[Sprite2D]) -> void:
	cleanup_attach_point_light(holder, point_light, piece_light)
	end_effect_occlusion_dimming(occlusion_dimmers)

func create_attach_glow_overlay(holder: Sprite2D) -> Sprite2D:
	return create_glow_overlay(holder, piece_attach_glow_name, piece_attach_glow_z_index, 0.0)

func create_glow_overlay(holder: Sprite2D, effect_name: String, z_index: int, glow_strength: float) -> Sprite2D:
	if holder == null or !is_instance_valid(holder):
		return null

	var overlay := Sprite2D.new()
	overlay.name = effect_name
	overlay.z_index = z_index
	overlay.z_as_relative = true
	sync_sprite_overlay_to_holder(overlay, holder)

	var material := ShaderMaterial.new()
	material.shader = piece_attach_glow_shader
	material.set_shader_parameter("glow_color", piece_attach_glow_color)
	material.set_shader_parameter("glow_strength", glow_strength)
	material.set_shader_parameter("glow_size", piece_attach_glow_size)
	material.set_shader_parameter("fill_strength", piece_attach_glow_fill_strength)
	overlay.material = material

	holder.add_child(overlay)
	return overlay

func create_attach_rays_overlay(holder: Sprite2D) -> Sprite2D:
	if holder == null or !is_instance_valid(holder):
		return null

	var overlay := Sprite2D.new()
	overlay.name = piece_attach_rays_name
	overlay.z_index = piece_attach_rays_z_index
	overlay.z_as_relative = true
	apply_attach_rays_overlay_transform(overlay, holder)

	var material := ShaderMaterial.new()
	material.shader = piece_attach_rays_shader
	material.set_shader_parameter("gradient", create_attach_rays_gradient_texture())
	material.set_shader_parameter("spread", piece_attach_rays_spread)
	material.set_shader_parameter("cutoff", piece_attach_rays_cutoff)
	material.set_shader_parameter("speed", piece_attach_rays_speed)
	material.set_shader_parameter("ray1_density", piece_attach_rays_ray1_density)
	material.set_shader_parameter("ray2_density", piece_attach_rays_ray2_density)
	material.set_shader_parameter("ray2_intensity", piece_attach_rays_ray2_intensity)
	material.set_shader_parameter("core_intensity", piece_attach_rays_core_intensity)
	material.set_shader_parameter("size", piece_attach_rays_start_size)
	material.set_shader_parameter("alpha_strength", 0.0)
	material.set_shader_parameter("seed", piece_attach_rays_seed)
	overlay.material = material

	holder.add_child(overlay)
	return overlay

func apply_attach_rays_overlay_transform(overlay, holder) -> void:
	if overlay == null or !is_instance_valid(overlay) or !(overlay is Sprite2D):
		return
	if holder == null or !is_instance_valid(holder) or !(holder is Sprite2D):
		return

	var overlay_sprite := overlay as Sprite2D
	var holder_sprite := holder as Sprite2D

	overlay_sprite.texture = get_attach_rays_square_texture()
	overlay_sprite.centered = true
	overlay_sprite.offset = Vector2.ZERO
	overlay_sprite.flip_h = false
	overlay_sprite.flip_v = false
	overlay_sprite.region_enabled = false
	overlay_sprite.hframes = 1
	overlay_sprite.vframes = 1
	overlay_sprite.frame = 0
	overlay_sprite.light_mask = piece_effect_light_receive_mask
	overlay_sprite.texture_filter = texture_filter_value

	var holder_texture_size: Vector2 = holder_sprite.texture.get_size() if holder_sprite.texture != null else Vector2.ONE * piece_attach_rays_texture_size
	var square_side: float = maxf(holder_texture_size.x, holder_texture_size.y)
	var overlay_scale_value: float = (square_side / float(piece_attach_rays_texture_size)) * piece_attach_rays_overlay_scale
	overlay_sprite.scale = Vector2.ONE * overlay_scale_value
	overlay_sprite.position = holder_sprite.offset + piece_attach_rays_local_offset

func get_attach_rays_square_texture() -> Texture2D:
	if piece_attach_rays_square_texture != null:
		return piece_attach_rays_square_texture

	var image := Image.create(piece_attach_rays_texture_size, piece_attach_rays_texture_size, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	piece_attach_rays_square_texture = ImageTexture.create_from_image(image)
	return piece_attach_rays_square_texture

func create_attach_rays_gradient_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_offset(0, 0.0)
	gradient.set_color(0, Color(1.0, 0.42, 0.0, 0.0))
	gradient.set_offset(1, 1.0)
	gradient.set_color(1, Color(1.0, 0.96, 0.03, 1.0))
	gradient.add_point(0.18, Color(1.0, 0.48, 0.02, 0.10))
	gradient.add_point(0.42, Color(1.0, 0.52, 0.02, 0.72))
	gradient.add_point(0.72, Color(1.0, 0.74, 0.03, 0.96))

	var texture := GradientTexture1D.new()
	texture.width = 256
	texture.gradient = gradient
	return texture

func sync_sprite_overlay_to_holder(overlay, holder) -> void:
	if piece_visuals == null:
		return
	if overlay == null or !is_instance_valid(overlay) or !(overlay is Sprite2D):
		return
	if holder == null or !is_instance_valid(holder) or !(holder is Sprite2D):
		return

	piece_visuals.sync_sprite_overlay_to_holder(overlay as Sprite2D, holder as Sprite2D)

func remove_attach_effects(holder: Sprite2D) -> void:
	if piece_visuals != null:
		piece_visuals.remove_attach_effects(holder)

func play_attach_sequence(holder: Sprite2D, board_pos: Vector2, target_texture: Texture2D, options: Dictionary = {}) -> bool:
	if holder == null or !is_instance_valid(holder) or target_texture == null:
		return false
	if !is_tween_owner_inside_tree():
		return false

	var disable_holder_occluder: bool = bool(options.get("disable_holder_occluder", true))
	var post_morph_callback: Callable = options.get("post_morph_callback", Callable())
	var occlusion_dimmers: Array[Sprite2D] = begin_effect_occlusion_dimming(holder, board_pos)
	var attach_point_light: PointLight2D = create_attach_point_light(holder)
	var attach_piece_light: PointLight2D = null
	if occlusion_dimmers.is_empty():
		attach_piece_light = create_attach_sprite_light(holder)
	if disable_holder_occluder:
		set_holder_light_occluder_enabled(holder, false)

	remove_attach_effects(holder)
	var glow_overlay: Sprite2D = create_attach_glow_overlay(holder)
	var rays_overlay: Sprite2D = create_attach_rays_overlay(holder)
	if glow_overlay == null or rays_overlay == null:
		cleanup_attach_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false

	var glow_material: ShaderMaterial = glow_overlay.material as ShaderMaterial
	var rays_material: ShaderMaterial = rays_overlay.material as ShaderMaterial
	if glow_material == null or rays_material == null:
		cleanup_attach_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false

	var in_tween: Tween = create_animation_tween()
	if in_tween == null:
		cleanup_attach_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false
	in_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	in_tween.tween_property(glow_material, "shader_parameter/glow_strength", piece_attach_glow_base_strength, piece_attach_in_duration)
	in_tween.parallel().tween_property(rays_material, "shader_parameter/size", piece_attach_rays_switch_size, piece_attach_in_duration)
	in_tween.parallel().tween_property(rays_material, "shader_parameter/alpha_strength", 1.0, piece_attach_in_duration * piece_attach_rays_fade_in_duration_ratio).set_delay(piece_attach_in_duration * piece_attach_rays_fade_in_delay_ratio)
	tween_effect_occlusion_dimming(in_tween, occlusion_dimmers, occluded_piece_effect_dim_color.a, piece_attach_in_duration)
	if attach_point_light != null:
		in_tween.parallel().tween_property(attach_point_light, "energy", attach_point_light_energy, piece_attach_in_duration)
	if attach_piece_light != null:
		in_tween.parallel().tween_property(attach_piece_light, "energy", attach_piece_light_energy, piece_attach_in_duration)
	await in_tween.finished

	if !is_attach_holder_active(holder):
		cleanup_attach_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false

	var pre_switch_hold_completed: bool = await await_attach_interval(piece_attach_pre_switch_hold_duration)
	if !pre_switch_hold_completed:
		cleanup_attach_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false
	if !is_attach_holder_active(holder):
		cleanup_attach_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false

	var switch_tween: Tween = create_animation_tween()
	if switch_tween == null:
		cleanup_attach_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false
	switch_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	switch_tween.tween_property(glow_material, "shader_parameter/glow_strength", piece_attach_glow_switch_strength, piece_attach_glow_switch_duration)
	await switch_tween.finished
	if !is_attach_holder_active(holder):
		cleanup_attach_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false

	await play_texture_morph(holder, target_texture, piece_attach_morph_duration, attach_point_light, attach_piece_light)
	if !is_attach_holder_active(holder):
		cleanup_attach_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false

	if post_morph_callback.is_valid():
		post_morph_callback.call(holder)
	else:
		holder.texture = target_texture
		apply_piece_visual_size(holder, board_pos)

	var morph_overlay: Node = holder.get_node_or_null(piece_attach_morph_name)
	if morph_overlay != null:
		morph_overlay.queue_free()
	if disable_holder_occluder:
		set_holder_light_occluder_enabled(holder, false)
	update_attach_point_light_position(attach_point_light, holder)
	update_attach_point_light_position(attach_piece_light, holder)
	sync_sprite_overlay_to_holder(glow_overlay, holder)
	apply_attach_rays_overlay_transform(rays_overlay, holder)

	var post_switch_hold_completed: bool = await await_attach_interval(piece_attach_post_switch_hold_duration)
	if !post_switch_hold_completed:
		cleanup_attach_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false
	if !is_attach_holder_active(holder):
		cleanup_attach_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false

	var out_tween: Tween = create_animation_tween()
	if out_tween == null:
		cleanup_attach_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false
	out_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	out_tween.tween_property(glow_material, "shader_parameter/glow_strength", 0.0, piece_attach_out_duration)
	out_tween.parallel().tween_property(rays_material, "shader_parameter/size", piece_attach_rays_start_size, piece_attach_out_duration)
	out_tween.parallel().tween_property(rays_material, "shader_parameter/alpha_strength", 0.0, piece_attach_out_duration)
	tween_effect_occlusion_dimming(out_tween, occlusion_dimmers, 0.0, piece_attach_out_duration)
	if attach_point_light != null:
		out_tween.parallel().tween_property(attach_point_light, "energy", 0.0, piece_attach_out_duration)
	if attach_piece_light != null:
		out_tween.parallel().tween_property(attach_piece_light, "energy", 0.0, piece_attach_out_duration)
	await out_tween.finished

	if is_instance_valid(glow_overlay):
		glow_overlay.queue_free()
	if is_instance_valid(rays_overlay):
		rays_overlay.queue_free()
	cleanup_attach_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
	return true

func begin_effect_occlusion_dimming(effect_holder: Sprite2D, board_pos: Vector2) -> Array[Sprite2D]:
	var dimmers: Array[Sprite2D] = []
	if occluded_piece_effect_dim_color.a <= 0.0:
		return dimmers

	for occluding_holder: Sprite2D in get_effect_occluding_holders(effect_holder, board_pos):
		var dimmer: Sprite2D = create_effect_occlusion_dim_overlay(occluding_holder)
		if dimmer != null:
			dimmers.append(dimmer)
	return dimmers

func get_effect_occluding_holders(effect_holder: Sprite2D, board_pos: Vector2) -> Array[Sprite2D]:
	var occluding_holders: Array[Sprite2D] = []
	if effect_holder == null or !is_instance_valid(effect_holder) or pieces_node == null or !_is_valid_position(board_pos):
		return occluding_holders

	var effect_bounds: Rect2 = get_sprite_texture_bounds_local(effect_holder)
	if effect_bounds.size.x <= 0.0 or effect_bounds.size.y <= 0.0:
		return occluding_holders

	effect_bounds = effect_bounds.grow(float(cell_width) * 0.08)
	var effect_depth: int = get_depth_z_index(board_pos)
	for child in pieces_node.get_children():
		var holder: Sprite2D = child as Sprite2D
		if holder == null or !is_instance_valid(holder) or holder.is_queued_for_deletion():
			continue
		if holder.texture == null or !holder.visible or holder.self_modulate.a <= 0.01 or holder.modulate.a <= 0.01:
			continue

		var holder_pos: Vector2 = get_holder_board_pos(holder)
		if !_is_valid_position(holder_pos) or holder_pos == board_pos:
			continue
		if get_depth_z_index(holder_pos) <= effect_depth:
			continue

		var holder_bounds: Rect2 = get_sprite_texture_bounds_local(holder)
		if holder_bounds.size.x <= 0.0 or holder_bounds.size.y <= 0.0:
			continue
		if effect_bounds.intersects(holder_bounds, true):
			occluding_holders.append(holder)

	return occluding_holders

func create_effect_occlusion_dim_overlay(holder: Sprite2D) -> Sprite2D:
	if holder == null or !is_instance_valid(holder) or holder.texture == null:
		return null

	var dimmer: Sprite2D = holder.get_node_or_null(piece_effect_occlusion_dim_name) as Sprite2D
	var current_alpha: float = 0.0
	if dimmer == null:
		dimmer = Sprite2D.new()
		dimmer.name = piece_effect_occlusion_dim_name
		dimmer.z_index = piece_effect_occlusion_dim_z_index
		dimmer.z_as_relative = true
		holder.add_child(dimmer)
	else:
		current_alpha = dimmer.self_modulate.a

	sync_sprite_overlay_to_holder(dimmer, holder)
	dimmer.light_mask = 0
	dimmer.self_modulate = Color(
		occluded_piece_effect_dim_color.r,
		occluded_piece_effect_dim_color.g,
		occluded_piece_effect_dim_color.b,
		current_alpha
	)
	return dimmer

func tween_effect_occlusion_dimming(tween: Tween, dimmers: Array[Sprite2D], target_alpha: float, duration: float) -> void:
	if tween == null:
		return
	for dimmer: Sprite2D in dimmers:
		if dimmer == null or !is_instance_valid(dimmer):
			continue
		tween.parallel().tween_property(dimmer, "self_modulate:a", target_alpha, duration)

func end_effect_occlusion_dimming(dimmers: Array[Sprite2D]) -> void:
	for dimmer: Sprite2D in dimmers:
		if dimmer == null or !is_instance_valid(dimmer):
			continue
		if dimmer.self_modulate.a <= 0.01:
			dimmer.queue_free()
			continue

		var tween: Tween = create_animation_tween()
		if tween == null:
			dimmer.queue_free()
			continue
		tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		tween.tween_property(dimmer, "self_modulate:a", 0.0, piece_attach_out_duration)
		tween.finished.connect(func():
			if is_instance_valid(dimmer):
				dimmer.queue_free()
		)

func apply_morph_overlay_target_visual(morph_overlay: Sprite2D, holder: Sprite2D, target_texture: Texture2D) -> void:
	if morph_overlay == null or !is_instance_valid(morph_overlay) or holder == null or !is_instance_valid(holder):
		return

	morph_overlay.texture = target_texture
	var board_pos: Vector2 = get_holder_board_pos(holder)
	if !_is_valid_position(board_pos):
		return

	var target_transform: Dictionary = get_piece_visual_transform(target_texture, board_pos)
	var target_scale: Vector2 = target_transform.get("scale", Vector2.ONE)
	morph_overlay.offset = target_transform.get("offset", Vector2.ZERO)
	morph_overlay.scale = Vector2(
		target_scale.x / holder.scale.x if absf(holder.scale.x) > 0.0001 else target_scale.x,
		target_scale.y / holder.scale.y if absf(holder.scale.y) > 0.0001 else target_scale.y
	)

func play_texture_morph(holder: Sprite2D, target_texture: Texture2D, duration: float, point_light: PointLight2D = null, piece_light: PointLight2D = null) -> void:
	if holder == null or !is_instance_valid(holder) or target_texture == null:
		return
	if duration <= 0.0 or piece_texture_morph_shader == null:
		return

	var existing_morph: Node = holder.get_node_or_null(piece_attach_morph_name)
	if existing_morph != null:
		existing_morph.free()

	var morph_overlay := Sprite2D.new()
	morph_overlay.name = piece_attach_morph_name
	morph_overlay.z_index = piece_attach_morph_z_index
	morph_overlay.z_as_relative = true
	sync_sprite_overlay_to_holder(morph_overlay, holder)
	apply_morph_overlay_target_visual(morph_overlay, holder, target_texture)
	morph_overlay.light_mask = piece_light_receive_mask

	var morph_material := ShaderMaterial.new()
	morph_material.shader = piece_texture_morph_shader
	morph_material.set_shader_parameter("morph_progress", 0.0)
	morph_material.set_shader_parameter("noise_strength", piece_attach_morph_noise_strength)
	morph_material.set_shader_parameter("shine_strength", piece_attach_morph_shine_strength)
	morph_material.set_shader_parameter("shine_color", piece_attach_glow_color)
	morph_overlay.material = morph_material
	holder.add_child(morph_overlay)

	var target_light_position: Vector2 = get_piece_light_global_position(holder, target_texture)
	var morph_tween: Tween = create_animation_tween()
	if morph_tween == null:
		return
	morph_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	morph_tween.tween_property(morph_material, "shader_parameter/morph_progress", 1.0, duration)
	if point_light != null and is_instance_valid(point_light):
		morph_tween.parallel().tween_property(point_light, "global_position", target_light_position, duration)
	if piece_light != null and is_instance_valid(piece_light):
		morph_tween.parallel().tween_property(piece_light, "global_position", target_light_position, duration)
	await morph_tween.finished

func play_piece_revert(piece_position: Vector2, start_texture: Texture2D) -> void:
	if start_texture == null or piece_expire_dissolve_shader == null:
		return

	var overlay: Sprite2D = create_effect_holder(piece_position, start_texture, "PieceExpireDissolve")
	if overlay == null:
		return

	var material := ShaderMaterial.new()
	material.shader = piece_expire_dissolve_shader
	material.set_shader_parameter("progress", 0.0)
	material.set_shader_parameter("beam_size", piece_expire_dissolve_beam_size)
	material.set_shader_parameter("noise_density", piece_expire_dissolve_noise_density)
	material.set_shader_parameter("color", piece_expire_dissolve_color)
	overlay.material = material

	var tween: Tween = create_animation_tween()
	if tween == null:
		if is_instance_valid(overlay):
			overlay.queue_free()
		return
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(material, "shader_parameter/progress", 1.0, piece_expire_dissolve_duration)
	await tween.finished
	if is_instance_valid(overlay):
		overlay.queue_free()

func play_invisibility_exit(holder: Sprite2D) -> void:
	if holder == null or !is_instance_valid(holder) or piece_invisibility_refract_shader == null:
		return
	if !is_tween_owner_inside_tree():
		return

	var scene_tree: SceneTree = tween_owner.get_tree()
	if scene_tree == null:
		return
	await scene_tree.create_timer(piece_invisibility_visible_hold_duration).timeout
	if !is_tween_owner_inside_tree() or !is_instance_valid(holder):
		return

	var refract_material := ShaderMaterial.new()
	refract_material.shader = piece_invisibility_refract_shader
	refract_material.set_shader_parameter("dist", piece_invisibility_refract_distance)
	refract_material.set_shader_parameter("alpha", 0.0)
	holder.material = refract_material

	var refract_tween: Tween = create_animation_tween()
	if refract_tween == null:
		return
	refract_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	refract_tween.tween_property(refract_material, "shader_parameter/alpha", 1.0, piece_invisibility_refract_in_duration)
	await refract_tween.finished
	if !is_tween_owner_inside_tree() or !is_instance_valid(holder):
		return

	var fade_tween: Tween = create_animation_tween()
	if fade_tween == null:
		return
	fade_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	fade_tween.tween_property(holder, "self_modulate:a", 0.0, piece_invisibility_fade_out_duration)
	await fade_tween.finished
	if is_instance_valid(holder):
		holder.queue_free()

func play_capture_flash(board_pos: Vector2) -> void:
	if capture_flash_texture == null or !has_effect_parent():
		return

	var flash := Sprite2D.new()
	if flipped_view:
		flash.global_rotation_degrees = 180
	piece_effects_node.add_child(flash)
	flash.name = "CaptureFlash"
	flash.light_mask = piece_effect_light_receive_mask
	flash.texture_filter = texture_filter_value
	flash.texture = capture_flash_texture
	flash.position = get_position_local(board_pos) + Vector2(
		0.0,
		-default_piece_visual_height * 0.18 * get_perspective_scale(board_pos)
	)
	flash.z_as_relative = true
	flash.z_index = 96
	flash.self_modulate = capture_flash_color

	var texture_size: Vector2 = capture_flash_texture.get_size()
	var texture_extent: float = maxf(texture_size.x, texture_size.y)
	var target_scale := Vector2.ONE
	if texture_extent > 0.0:
		var target_size: float = float(cell_width) * capture_flash_size_ratio * get_perspective_scale(board_pos)
		target_scale = Vector2.ONE * (target_size / texture_extent)

	flash.scale = target_scale * capture_flash_start_scale_ratio
	var rotation_direction: float = 1.0 if randf() >= 0.5 else -1.0
	flash.rotation = randf_range(-0.08, 0.08)
	var end_rotation: float = flash.rotation + deg_to_rad(capture_flash_rotation_degrees) * rotation_direction
	var motion_tween: Tween = create_animation_tween()
	if motion_tween == null:
		flash.queue_free()
		return
	motion_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	motion_tween.tween_property(flash, "scale", target_scale, capture_flash_duration)
	motion_tween.parallel().tween_property(flash, "rotation", end_rotation, capture_flash_duration)

	var fade_tween: Tween = create_animation_tween()
	if fade_tween == null:
		return
	fade_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fade_tween.tween_interval(capture_flash_duration * 0.18)
	fade_tween.tween_property(flash, "self_modulate:a", 0.0, capture_flash_duration * 0.82)
	fade_tween.finished.connect(func():
		if is_instance_valid(flash):
			flash.queue_free()
	)

func play_bomb_warning(target_pos: Vector2) -> void:
	if bomb_warning_texture == null or !has_effect_parent():
		return

	var marker := Sprite2D.new()
	if flipped_view:
		marker.global_rotation_degrees = 180
	piece_effects_node.add_child(marker)
	marker.name = "BombWarning"
	marker.light_mask = piece_effect_light_receive_mask
	marker.texture_filter = texture_filter_value
	marker.texture = bomb_warning_texture
	marker.z_as_relative = false
	marker.z_index = get_piece_effect_z_index(target_pos) + bomb_warning_z_offset
	marker.self_modulate = Color(bomb_warning_color.r, bomb_warning_color.g, bomb_warning_color.b, 0.0)

	var target_position: Vector2 = get_bomb_warning_target_position(target_pos)
	marker.position = target_position + Vector2(0.0, bomb_warning_rise_distance * get_perspective_scale(target_pos))

	var texture_size: Vector2 = bomb_warning_texture.get_size()
	var texture_extent: float = maxf(texture_size.x, texture_size.y)
	if texture_extent > 0.0:
		var target_size: float = float(cell_width) * bomb_warning_size_ratio * get_perspective_scale(target_pos)
		marker.scale = Vector2.ONE * (target_size / texture_extent)

	var tween: Tween = create_animation_tween()
	if tween == null:
		marker.queue_free()
		return
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(marker, "position", target_position, bomb_warning_duration)
	tween.parallel().tween_property(marker, "self_modulate:a", bomb_warning_color.a, bomb_warning_duration)
	tween.finished.connect(func():
		if is_instance_valid(marker):
			marker.queue_free()
	)

func get_bomb_warning_target_position(target_pos: Vector2) -> Vector2:
	return get_position_local(target_pos) + Vector2(0.0, bomb_warning_target_y_offset * get_perspective_scale(target_pos))

func get_piece_effect_z_index(board_pos: Vector2) -> int:
	var base_z_index: int = int(pieces_node.z_index) if pieces_node != null else 0
	return base_z_index + get_depth_z_index(board_pos)

func get_position_local(board_pos: Vector2) -> Vector2:
	if geometry == null:
		return Vector2.ZERO
	return geometry.get_position_local(board_pos)

func get_perspective_scale(board_pos: Vector2) -> float:
	if piece_visuals == null:
		return 1.0
	return piece_visuals.get_perspective_scale(board_pos)

func get_depth_z_index(board_pos: Vector2) -> int:
	if piece_visuals == null:
		return 0
	return piece_visuals.get_depth_z_index(board_pos)

func apply_piece_visual_size(holder: Sprite2D, board_pos: Vector2) -> void:
	if piece_visuals != null:
		piece_visuals.apply_visual_size(holder, board_pos)

func get_light_parent() -> Node:
	if tween_owner != null and is_instance_valid(tween_owner):
		return tween_owner
	if piece_effects_node != null and is_instance_valid(piece_effects_node):
		return piece_effects_node
	return null

func get_attach_point_light_texture() -> Texture2D:
	if attach_point_light_texture_provider.is_valid():
		var provided_texture: Texture2D = attach_point_light_texture_provider.call() as Texture2D
		if provided_texture != null:
			return provided_texture
	return null

func get_piece_light_global_position(holder: Sprite2D, texture_value: Texture2D) -> Vector2:
	if piece_light_global_position_provider.is_valid():
		var provided_position = piece_light_global_position_provider.call(holder, texture_value)
		if provided_position is Vector2:
			return provided_position
	if holder == null or !is_instance_valid(holder):
		return Vector2.ZERO
	return holder.to_global(holder.offset)

func get_piece_visual_transform(texture_value: Texture2D, board_pos: Vector2) -> Dictionary:
	if piece_visuals == null:
		return {}
	return piece_visuals.get_visual_transform_for_texture(texture_value, board_pos)

func set_holder_light_occluder_enabled(holder, is_enabled: bool) -> void:
	if holder != null and is_instance_valid(holder) and holder is Sprite2D and piece_visuals != null:
		piece_visuals.set_light_occluder_enabled(holder as Sprite2D, is_enabled)

func is_attach_holder_active(holder) -> bool:
	return is_tween_owner_inside_tree() and holder != null and is_instance_valid(holder) and holder is Sprite2D

func await_attach_interval(duration: float) -> bool:
	if duration <= 0.0:
		return is_tween_owner_inside_tree()
	if !is_tween_owner_inside_tree():
		return false

	var scene_tree: SceneTree = tween_owner.get_tree()
	if scene_tree == null:
		return false
	await scene_tree.create_timer(duration).timeout
	return is_tween_owner_inside_tree()

func get_sprite_texture_bounds_local(sprite: Sprite2D) -> Rect2:
	if sprite_bounds_provider.is_valid():
		var provided_bounds = sprite_bounds_provider.call(sprite)
		if provided_bounds is Rect2:
			return provided_bounds
	return Rect2()

func get_holder_board_pos(holder: Sprite2D) -> Vector2:
	if holder == null or !is_instance_valid(holder):
		return Vector2(-1, -1)
	var board_pos_value = holder.get_meta("board_pos", Vector2(-1, -1))
	if board_pos_value is Vector2:
		return board_pos_value
	return Vector2(-1, -1)

func has_effect_parent() -> bool:
	return piece_effects_node != null and is_instance_valid(piece_effects_node)

func create_animation_tween() -> Tween:
	if tween_owner == null or !is_instance_valid(tween_owner):
		return null
	return tween_owner.create_tween()

func is_tween_owner_inside_tree() -> bool:
	return tween_owner != null and is_instance_valid(tween_owner) and tween_owner.is_inside_tree()

func _is_valid_position(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x < board_size and pos.y >= 0 and pos.y < board_size
