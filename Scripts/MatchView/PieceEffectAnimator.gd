extends RefCounted

const PIECE_CAPTURE_SPARKLE_SHADER: Shader = preload("res://Shaders/piece_capture_sparkle.gdshader")
const BOMB_WARNING_TEXTURE: Texture2D = preload("res://Assets/stamp_pattern_bomb.svg")
const BOMB_WARNING_Z_OFFSET: int = 7
const PIECE_EXPIRE_DISSOLVE_SHADER: Shader = preload("res://Shaders/piece_expire_dissolve.gdshader")
const PIECE_EXPIRE_DISSOLVE_DURATION: float = 1.62
const PIECE_EXPIRE_DISSOLVE_BEAM_SIZE: float = 0.05
const PIECE_EXPIRE_DISSOLVE_NOISE_DENSITY: float = 60.0
const PIECE_EXPIRE_DISSOLVE_COLOR: Color = Color(1.0, 0.42, 0.02, 1.0)
const PIECE_INVISIBILITY_REFRACT_SHADER: Shader = preload("res://Shaders/piece_invisibility_refract.gdshader")
const PIECE_INVISIBILITY_VISIBLE_HOLD_DURATION: float = 0.50
const PIECE_INVISIBILITY_REFRACT_IN_DURATION: float = 0.42
const PIECE_INVISIBILITY_FADE_OUT_DURATION: float = 1.48
const PIECE_INVISIBILITY_REFRACT_DISTANCE: float = 16.0
const ATTACH_POINT_LIGHT_NAME: String = "AttachPointLight"
const ATTACH_PIECE_LIGHT_NAME: String = "AttachPieceLight"
const ATTACH_POINT_LIGHT_TEXTURE_SCALE: float = 0.92
const ATTACH_POINT_LIGHT_COLOR: Color = Color(1.0, 0.74, 0.24, 1.0)
const ATTACH_POINT_LIGHT_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.52)
const ATTACH_POINT_LIGHT_SHADOW_SMOOTH: float = 2.5
const ATTACH_PIECE_LIGHT_TEXTURE_SCALE: float = 1.08
const ATTACH_PIECE_LIGHT_COLOR: Color = Color(1.0, 0.84, 0.36, 1.0)
const ATTACH_POINT_LIGHT_ENERGY: float = 1.25
const ATTACH_PIECE_LIGHT_ENERGY: float = 0.62
const PIECE_ATTACH_GLOW_NAME: String = "PieceAttachGlow"
const PIECE_ATTACH_TARGET_GLOW_NAME: String = "PieceAttachTargetGlow"
const PIECE_ATTACH_RAYS_NAME: String = "PieceAttachRays"
const PIECE_ATTACH_MORPH_NAME: String = "PieceAttachMorph"
const PIECE_EFFECT_OCCLUSION_DIM_NAME: String = "PieceEffectOcclusionDim"
const PIECE_ATTACH_GLOW_Z_INDEX: int = 26
const PIECE_ATTACH_RAYS_Z_INDEX: int = 25
const PIECE_ATTACH_MORPH_Z_INDEX: int = 1
const PIECE_EFFECT_OCCLUSION_DIM_Z_INDEX: int = 0
const PIECE_ATTACH_GLOW_SHADER: Shader = preload("res://Shaders/piece_attach_glow.gdshader")
const PIECE_ATTACH_RAYS_SHADER: Shader = preload("res://Shaders/piece_attach_rays.gdshader")
const PIECE_TEXTURE_MORPH_SHADER: Shader = preload("res://Shaders/piece_texture_morph.gdshader")
const PIECE_ATTACH_GLOW_COLOR: Color = Color(1.0, 0.82, 0.28, 1.0)
const PIECE_ATTACH_GLOW_SIZE: float = 4.8
const PIECE_ATTACH_GLOW_FILL_STRENGTH: float = 0.30
const PIECE_ATTACH_GLOW_BASE_STRENGTH: float = 1.0
const PIECE_ATTACH_GLOW_SWITCH_STRENGTH: float = 4.0
const PIECE_ATTACH_GLOW_SWITCH_DURATION: float = 0.06
const PIECE_ATTACH_IN_DURATION: float = 0.32
const PIECE_ATTACH_PRE_SWITCH_HOLD_DURATION: float = 0.14
const PIECE_ATTACH_MORPH_DURATION: float = 1.00
const PIECE_ATTACH_TARGET_APPEAR_DURATION: float = 0.50
const PIECE_ATTACH_POST_SWITCH_HOLD_DURATION: float = 0.20
const PIECE_ATTACH_MORPH_NOISE_STRENGTH: float = 0.14
const PIECE_ATTACH_MORPH_SHINE_STRENGTH: float = 0.34
const PIECE_ATTACH_OUT_DURATION: float = 0.32
const PIECE_ATTACH_RAYS_START_SIZE: float = 10.0
const PIECE_ATTACH_RAYS_SWITCH_SIZE: float = 1.0
const PIECE_ATTACH_RAYS_TEXTURE_SIZE: int = 256
const PIECE_ATTACH_RAYS_OVERLAY_SCALE: float = 2.65
const PIECE_ATTACH_RAYS_LOCAL_OFFSET: Vector2 = Vector2.ZERO
const PIECE_ATTACH_RAYS_SPREAD: float = 0.5
const PIECE_ATTACH_RAYS_CUTOFF: float = 0.39
const PIECE_ATTACH_RAYS_SPEED: float = 1.4
const PIECE_ATTACH_RAYS_RAY1_DENSITY: float = 8.0
const PIECE_ATTACH_RAYS_RAY2_DENSITY: float = 10.0
const PIECE_ATTACH_RAYS_RAY2_INTENSITY: float = 0.3
const PIECE_ATTACH_RAYS_CORE_INTENSITY: float = 2.0
const PIECE_ATTACH_RAYS_SEED: float = 5.0
const PIECE_ATTACH_RAYS_FADE_IN_DELAY_RATIO: float = 0.0
const PIECE_ATTACH_RAYS_FADE_IN_DURATION_RATIO: float = 1.0

var geometry
var piece_visuals
var pieces_node: Node
var piece_effects_node: Node
var tween_owner: Node
var texture_holder_scene: PackedScene
var cell_width: int = BoardConfig.CELL_WIDTH
var texture_filter_value = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
var board_light_receive_mask: int = 1
var piece_light_receive_mask: int = 2
var piece_effect_light_receive_mask: int = 0
var piece_light_occluder_mask: int = 1
var flipped_view: bool = false

var default_piece_visual_height: float = 24.0

var capture_sparkle_color: Color = Color(1.0, 0.95, 0.78, 1.0)
var capture_sparkle_duration: float = 0.85
var capture_sparkle_fade_out_ratio: float = 0.6
var capture_sparkle_size_ratio: float = 2.2
var capture_sparkle_shader_scale: float = 7500.0
var capture_sparkle_decay_magnitude: float = 0.1
var capture_sparkle_rotate_speed: float = 0.6
var capture_sparkle_time_speed: float = 1.0
var capture_sparkle_frequency_base: float = 1.0
var capture_sparkle_frequency_disturbance_scale: float = 0.4
var capture_sparkle_circle_ratio: float = 0.0

var bomb_warning_color: Color = Color(1.0, 0.56, 0.56, 1.0)
var bomb_warning_duration: float = 1.5
var bomb_warning_rise_distance: float = 7.0
var bomb_warning_size_ratio: float = 1.15
var bomb_warning_target_y_offset: float = -6.0


var occluded_piece_effect_dim_color: Color = Color(0.0, 0.0, 0.0, 0.34)
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
	texture_filter_value = config.get("texture_filter", texture_filter_value)
	board_light_receive_mask = int(config.get("board_light_receive_mask", board_light_receive_mask))
	piece_light_receive_mask = int(config.get("piece_light_receive_mask", piece_light_receive_mask))
	piece_effect_light_receive_mask = int(config.get("piece_effect_light_receive_mask", piece_effect_light_receive_mask))
	piece_light_occluder_mask = int(config.get("piece_light_occluder_mask", piece_light_occluder_mask))
	flipped_view = bool(config.get("flipped_view", flipped_view))
	default_piece_visual_height = float(config.get("default_piece_visual_height", default_piece_visual_height))

	capture_sparkle_color = config.get("capture_sparkle_color", capture_sparkle_color)
	capture_sparkle_duration = float(config.get("capture_sparkle_duration", capture_sparkle_duration))
	capture_sparkle_fade_out_ratio = float(config.get("capture_sparkle_fade_out_ratio", capture_sparkle_fade_out_ratio))
	capture_sparkle_size_ratio = float(config.get("capture_sparkle_size_ratio", capture_sparkle_size_ratio))
	capture_sparkle_shader_scale = float(config.get("capture_sparkle_shader_scale", capture_sparkle_shader_scale))
	capture_sparkle_decay_magnitude = float(config.get("capture_sparkle_decay_magnitude", capture_sparkle_decay_magnitude))
	capture_sparkle_rotate_speed = float(config.get("capture_sparkle_rotate_speed", capture_sparkle_rotate_speed))
	capture_sparkle_time_speed = float(config.get("capture_sparkle_time_speed", capture_sparkle_time_speed))
	capture_sparkle_frequency_base = float(config.get("capture_sparkle_frequency_base", capture_sparkle_frequency_base))
	capture_sparkle_frequency_disturbance_scale = float(config.get("capture_sparkle_frequency_disturbance_scale", capture_sparkle_frequency_disturbance_scale))
	capture_sparkle_circle_ratio = float(config.get("capture_sparkle_circle_ratio", capture_sparkle_circle_ratio))

	bomb_warning_color = config.get("bomb_warning_color", bomb_warning_color)
	bomb_warning_duration = float(config.get("bomb_warning_duration", bomb_warning_duration))
	bomb_warning_rise_distance = float(config.get("bomb_warning_rise_distance", bomb_warning_rise_distance))
	bomb_warning_size_ratio = float(config.get("bomb_warning_size_ratio", bomb_warning_size_ratio))
	bomb_warning_target_y_offset = float(config.get("bomb_warning_target_y_offset", bomb_warning_target_y_offset))


	occluded_piece_effect_dim_color = config.get("occluded_piece_effect_dim_color", occluded_piece_effect_dim_color)
	attach_point_light_texture_provider = config.get("attach_point_light_texture_provider", attach_point_light_texture_provider)
	piece_light_global_position_provider = config.get("piece_light_global_position_provider", piece_light_global_position_provider)
	sprite_bounds_provider = config.get("sprite_bounds_provider", sprite_bounds_provider)

func create_effect_holder(piece_position: Vector2, texture_value: Texture2D, holder_name: String = "PieceEffect") -> Sprite2D:
	if texture_value == null or !MoveRules.is_valid_position(piece_position) or !has_effect_parent():
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
	point_light.name = ATTACH_POINT_LIGHT_NAME
	point_light.texture = get_attach_point_light_texture()
	point_light.texture_scale = ATTACH_POINT_LIGHT_TEXTURE_SCALE
	point_light.color = ATTACH_POINT_LIGHT_COLOR
	point_light.energy = 0.0
	point_light.range_item_cull_mask = board_light_receive_mask
	point_light.shadow_enabled = true
	point_light.shadow_color = ATTACH_POINT_LIGHT_SHADOW_COLOR
	point_light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	point_light.shadow_filter_smooth = ATTACH_POINT_LIGHT_SHADOW_SMOOTH
	point_light.shadow_item_cull_mask = piece_light_occluder_mask
	parent_node.add_child(point_light)
	point_light.global_position = get_piece_light_global_position(holder, holder.texture)
	return point_light

func create_affix_sprite_light(holder: Sprite2D) -> PointLight2D:
	if holder == null or !is_instance_valid(holder):
		return null

	var parent_node: Node = get_light_parent()
	if parent_node == null:
		return null

	var piece_light := PointLight2D.new()
	piece_light.name = ATTACH_PIECE_LIGHT_NAME
	piece_light.texture = get_attach_point_light_texture()
	piece_light.texture_scale = ATTACH_PIECE_LIGHT_TEXTURE_SCALE
	piece_light.color = ATTACH_PIECE_LIGHT_COLOR
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

func cleanup_affix_animation_layers(holder, point_light, piece_light, occlusion_dimmers: Array[Sprite2D]) -> void:
	cleanup_attach_point_light(holder, point_light, piece_light)
	end_effect_occlusion_dimming(occlusion_dimmers)
	remove_attach_effects_if_holder_valid(holder)

func create_affix_glow_overlay(holder: Sprite2D) -> Sprite2D:
	return create_glow_overlay(holder, PIECE_ATTACH_GLOW_NAME, PIECE_ATTACH_GLOW_Z_INDEX, 0.0)

func create_affix_target_glow_overlay(holder: Sprite2D, target_texture: Texture2D, glow_material: ShaderMaterial) -> Sprite2D:
	if holder == null or !is_instance_valid(holder) or target_texture == null or glow_material == null:
		return null

	var overlay := Sprite2D.new()
	overlay.name = PIECE_ATTACH_TARGET_GLOW_NAME
	overlay.z_index = PIECE_ATTACH_GLOW_Z_INDEX
	overlay.z_as_relative = true
	sync_sprite_overlay_to_holder(overlay, holder)
	apply_morph_overlay_target_visual(overlay, holder, target_texture)
	overlay.material = glow_material
	overlay.self_modulate.a = 0.0
	holder.add_child(overlay)
	return overlay

func create_glow_overlay(holder: Sprite2D, effect_name: String, z_index: int, glow_strength: float) -> Sprite2D:
	if holder == null or !is_instance_valid(holder):
		return null

	var overlay := Sprite2D.new()
	overlay.name = effect_name
	overlay.z_index = z_index
	overlay.z_as_relative = true
	sync_sprite_overlay_to_holder(overlay, holder)

	var material := ShaderMaterial.new()
	material.shader = PIECE_ATTACH_GLOW_SHADER
	material.set_shader_parameter("glow_color", PIECE_ATTACH_GLOW_COLOR)
	material.set_shader_parameter("glow_strength", glow_strength)
	material.set_shader_parameter("glow_size", PIECE_ATTACH_GLOW_SIZE)
	material.set_shader_parameter("fill_strength", PIECE_ATTACH_GLOW_FILL_STRENGTH)
	overlay.material = material

	holder.add_child(overlay)
	return overlay

func create_affix_rays_overlay(holder: Sprite2D) -> Sprite2D:
	if holder == null or !is_instance_valid(holder):
		return null

	var overlay := Sprite2D.new()
	overlay.name = PIECE_ATTACH_RAYS_NAME
	overlay.z_index = PIECE_ATTACH_RAYS_Z_INDEX
	overlay.z_as_relative = true
	apply_affix_rays_overlay_transform(overlay, holder)

	var material := ShaderMaterial.new()
	material.shader = PIECE_ATTACH_RAYS_SHADER
	material.set_shader_parameter("gradient", create_affix_rays_gradient_texture())
	material.set_shader_parameter("spread", PIECE_ATTACH_RAYS_SPREAD)
	material.set_shader_parameter("cutoff", PIECE_ATTACH_RAYS_CUTOFF)
	material.set_shader_parameter("speed", PIECE_ATTACH_RAYS_SPEED)
	material.set_shader_parameter("ray1_density", PIECE_ATTACH_RAYS_RAY1_DENSITY)
	material.set_shader_parameter("ray2_density", PIECE_ATTACH_RAYS_RAY2_DENSITY)
	material.set_shader_parameter("ray2_intensity", PIECE_ATTACH_RAYS_RAY2_INTENSITY)
	material.set_shader_parameter("core_intensity", PIECE_ATTACH_RAYS_CORE_INTENSITY)
	material.set_shader_parameter("size", PIECE_ATTACH_RAYS_START_SIZE)
	material.set_shader_parameter("alpha_strength", 0.0)
	material.set_shader_parameter("seed", PIECE_ATTACH_RAYS_SEED)
	overlay.material = material

	holder.add_child(overlay)
	return overlay

func apply_affix_rays_overlay_transform(overlay, holder) -> void:
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

	var holder_texture_size: Vector2 = holder_sprite.texture.get_size() if holder_sprite.texture != null else Vector2.ONE * PIECE_ATTACH_RAYS_TEXTURE_SIZE
	var square_side: float = maxf(holder_texture_size.x, holder_texture_size.y)
	var overlay_scale_value: float = (square_side / float(PIECE_ATTACH_RAYS_TEXTURE_SIZE)) * PIECE_ATTACH_RAYS_OVERLAY_SCALE
	overlay_sprite.scale = Vector2.ONE * overlay_scale_value
	overlay_sprite.position = holder_sprite.offset + PIECE_ATTACH_RAYS_LOCAL_OFFSET

func get_attach_rays_square_texture() -> Texture2D:
	if piece_attach_rays_square_texture != null:
		return piece_attach_rays_square_texture

	var image := Image.create(PIECE_ATTACH_RAYS_TEXTURE_SIZE, PIECE_ATTACH_RAYS_TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	piece_attach_rays_square_texture = ImageTexture.create_from_image(image)
	return piece_attach_rays_square_texture

func create_affix_rays_gradient_texture() -> Texture2D:
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

func remove_attach_effects_if_holder_valid(holder) -> void:
	if holder != null and is_instance_valid(holder) and holder is Sprite2D:
		remove_attach_effects(holder as Sprite2D)

func play_affix_sequence(holder: Sprite2D, board_pos: Vector2, target_texture: Texture2D, options: Dictionary = {}) -> bool:
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
		attach_piece_light = create_affix_sprite_light(holder)
	if disable_holder_occluder:
		set_holder_light_occluder_enabled(holder, false)

	remove_attach_effects(holder)
	var glow_overlay: Sprite2D = create_affix_glow_overlay(holder)
	var rays_overlay: Sprite2D = create_affix_rays_overlay(holder)
	if glow_overlay == null or rays_overlay == null:
		cleanup_affix_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false

	var glow_material: ShaderMaterial = glow_overlay.material as ShaderMaterial
	var rays_material: ShaderMaterial = rays_overlay.material as ShaderMaterial
	if glow_material == null or rays_material == null:
		cleanup_affix_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false
	var target_glow_overlay: Sprite2D = create_affix_target_glow_overlay(holder, target_texture, glow_material)
	if target_glow_overlay == null:
		cleanup_affix_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false

	var in_tween: Tween = create_animation_tween()
	if in_tween == null:
		cleanup_affix_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false
	in_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	in_tween.tween_property(glow_material, "shader_parameter/glow_strength", PIECE_ATTACH_GLOW_BASE_STRENGTH, PIECE_ATTACH_IN_DURATION)
	in_tween.parallel().tween_property(rays_material, "shader_parameter/size", PIECE_ATTACH_RAYS_SWITCH_SIZE, PIECE_ATTACH_IN_DURATION)
	in_tween.parallel().tween_property(rays_material, "shader_parameter/alpha_strength", 1.0, PIECE_ATTACH_IN_DURATION * PIECE_ATTACH_RAYS_FADE_IN_DURATION_RATIO).set_delay(PIECE_ATTACH_IN_DURATION * PIECE_ATTACH_RAYS_FADE_IN_DELAY_RATIO)
	tween_effect_occlusion_dimming(in_tween, occlusion_dimmers, occluded_piece_effect_dim_color.a, PIECE_ATTACH_IN_DURATION)
	if attach_point_light != null:
		in_tween.parallel().tween_property(attach_point_light, "energy", ATTACH_POINT_LIGHT_ENERGY, PIECE_ATTACH_IN_DURATION)
	if attach_piece_light != null:
		in_tween.parallel().tween_property(attach_piece_light, "energy", ATTACH_PIECE_LIGHT_ENERGY, PIECE_ATTACH_IN_DURATION)
	await in_tween.finished

	if !is_affix_holder_active(holder):
		cleanup_affix_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false

	var pre_switch_hold_completed: bool = await await_affix_interval(PIECE_ATTACH_PRE_SWITCH_HOLD_DURATION)
	if !pre_switch_hold_completed:
		cleanup_affix_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false
	if !is_affix_holder_active(holder):
		cleanup_affix_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false

	var switch_tween: Tween = create_animation_tween()
	if switch_tween == null:
		cleanup_affix_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false
	switch_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	switch_tween.tween_property(glow_material, "shader_parameter/glow_strength", PIECE_ATTACH_GLOW_SWITCH_STRENGTH, PIECE_ATTACH_GLOW_SWITCH_DURATION)
	await switch_tween.finished
	if !is_affix_holder_active(holder):
		cleanup_affix_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false

	await play_texture_morph(holder, target_texture, PIECE_ATTACH_MORPH_DURATION, attach_point_light, attach_piece_light, target_glow_overlay)
	if !is_affix_holder_active(holder):
		cleanup_affix_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false

	if post_morph_callback.is_valid():
		post_morph_callback.call(holder)
	else:
		holder.texture = target_texture
		apply_piece_visual_size(holder, board_pos)

	var morph_overlay: Node = holder.get_node_or_null(PIECE_ATTACH_MORPH_NAME)
	if morph_overlay != null:
		morph_overlay.queue_free()
	if is_instance_valid(target_glow_overlay):
		target_glow_overlay.queue_free()
	if disable_holder_occluder:
		set_holder_light_occluder_enabled(holder, false)
	update_attach_point_light_position(attach_point_light, holder)
	update_attach_point_light_position(attach_piece_light, holder)
	sync_sprite_overlay_to_holder(glow_overlay, holder)
	apply_affix_rays_overlay_transform(rays_overlay, holder)

	var post_switch_hold_completed: bool = await await_affix_interval(PIECE_ATTACH_POST_SWITCH_HOLD_DURATION)
	if !post_switch_hold_completed:
		cleanup_affix_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false
	if !is_affix_holder_active(holder):
		cleanup_affix_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false

	var out_tween: Tween = create_animation_tween()
	if out_tween == null:
		cleanup_affix_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
		return false
	out_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	out_tween.tween_property(glow_material, "shader_parameter/glow_strength", 0.0, PIECE_ATTACH_OUT_DURATION)
	out_tween.parallel().tween_property(rays_material, "shader_parameter/size", PIECE_ATTACH_RAYS_START_SIZE, PIECE_ATTACH_OUT_DURATION)
	out_tween.parallel().tween_property(rays_material, "shader_parameter/alpha_strength", 0.0, PIECE_ATTACH_OUT_DURATION)
	tween_effect_occlusion_dimming(out_tween, occlusion_dimmers, 0.0, PIECE_ATTACH_OUT_DURATION)
	if attach_point_light != null:
		out_tween.parallel().tween_property(attach_point_light, "energy", 0.0, PIECE_ATTACH_OUT_DURATION)
	if attach_piece_light != null:
		out_tween.parallel().tween_property(attach_piece_light, "energy", 0.0, PIECE_ATTACH_OUT_DURATION)
	await out_tween.finished

	if is_instance_valid(glow_overlay):
		glow_overlay.queue_free()
	if is_instance_valid(target_glow_overlay):
		target_glow_overlay.queue_free()
	if is_instance_valid(rays_overlay):
		rays_overlay.queue_free()
	cleanup_affix_animation_layers(holder, attach_point_light, attach_piece_light, occlusion_dimmers)
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
	if effect_holder == null or !is_instance_valid(effect_holder) or pieces_node == null or !MoveRules.is_valid_position(board_pos):
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
		if !MoveRules.is_valid_position(holder_pos) or holder_pos == board_pos:
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

	var dimmer: Sprite2D = holder.get_node_or_null(PIECE_EFFECT_OCCLUSION_DIM_NAME) as Sprite2D
	var current_alpha: float = 0.0
	if dimmer == null:
		dimmer = Sprite2D.new()
		dimmer.name = PIECE_EFFECT_OCCLUSION_DIM_NAME
		dimmer.z_index = PIECE_EFFECT_OCCLUSION_DIM_Z_INDEX
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
		tween.tween_property(dimmer, "self_modulate:a", 0.0, PIECE_ATTACH_OUT_DURATION)
		tween.finished.connect(func():
			if is_instance_valid(dimmer):
				dimmer.queue_free()
		)

func apply_morph_overlay_target_visual(morph_overlay: Sprite2D, holder: Sprite2D, target_texture: Texture2D) -> void:
	if morph_overlay == null or !is_instance_valid(morph_overlay) or holder == null or !is_instance_valid(holder):
		return

	morph_overlay.texture = target_texture
	var board_pos: Vector2 = get_holder_board_pos(holder)
	if !MoveRules.is_valid_position(board_pos):
		return

	var target_transform: Dictionary = get_piece_visual_transform(target_texture, board_pos)
	var target_scale: Vector2 = target_transform.get("scale", Vector2.ONE)
	morph_overlay.offset = target_transform.get("offset", Vector2.ZERO)
	morph_overlay.scale = Vector2(
		target_scale.x / holder.scale.x if absf(holder.scale.x) > 0.0001 else target_scale.x,
		target_scale.y / holder.scale.y if absf(holder.scale.y) > 0.0001 else target_scale.y
	)

func play_texture_morph(holder: Sprite2D, target_texture: Texture2D, duration: float, point_light: PointLight2D = null, piece_light: PointLight2D = null, target_glow_overlay: Sprite2D = null) -> void:
	if holder == null or !is_instance_valid(holder) or target_texture == null:
		return
	if duration <= 0.0 or PIECE_TEXTURE_MORPH_SHADER == null:
		return

	var existing_morph: Node = holder.get_node_or_null(PIECE_ATTACH_MORPH_NAME)
	if existing_morph != null:
		existing_morph.free()

	var morph_overlay := Sprite2D.new()
	morph_overlay.name = PIECE_ATTACH_MORPH_NAME
	morph_overlay.z_index = PIECE_ATTACH_MORPH_Z_INDEX
	morph_overlay.z_as_relative = true
	sync_sprite_overlay_to_holder(morph_overlay, holder)
	apply_morph_overlay_target_visual(morph_overlay, holder, target_texture)
	morph_overlay.light_mask = piece_light_receive_mask

	var morph_material := ShaderMaterial.new()
	morph_material.shader = PIECE_TEXTURE_MORPH_SHADER
	morph_material.set_shader_parameter("morph_progress", 0.0)
	morph_material.set_shader_parameter("noise_strength", PIECE_ATTACH_MORPH_NOISE_STRENGTH)
	morph_material.set_shader_parameter("shine_strength", PIECE_ATTACH_MORPH_SHINE_STRENGTH)
	morph_material.set_shader_parameter("shine_color", PIECE_ATTACH_GLOW_COLOR)
	morph_overlay.material = morph_material
	holder.add_child(morph_overlay)

	var target_light_position: Vector2 = get_piece_light_global_position(holder, target_texture)
	var morph_tween: Tween = create_animation_tween()
	if morph_tween == null:
		return
	morph_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	var target_appear_duration: float = clampf(PIECE_ATTACH_TARGET_APPEAR_DURATION, 0.0, duration)
	if target_appear_duration <= 0.0:
		morph_material.set_shader_parameter("morph_progress", 1.0)
		if target_glow_overlay != null and is_instance_valid(target_glow_overlay):
			target_glow_overlay.self_modulate.a = 1.0
	else:
		morph_tween.tween_property(morph_material, "shader_parameter/morph_progress", 1.0, target_appear_duration)
		if target_glow_overlay != null and is_instance_valid(target_glow_overlay):
			morph_tween.parallel().tween_property(target_glow_overlay, "self_modulate:a", 1.0, target_appear_duration)
	if point_light != null and is_instance_valid(point_light):
		morph_tween.parallel().tween_property(point_light, "global_position", target_light_position, duration)
	if piece_light != null and is_instance_valid(piece_light):
		morph_tween.parallel().tween_property(piece_light, "global_position", target_light_position, duration)
	await morph_tween.finished

func play_piece_revert(piece_position: Vector2, start_texture: Texture2D) -> void:
	if start_texture == null or PIECE_EXPIRE_DISSOLVE_SHADER == null:
		return

	var overlay: Sprite2D = create_effect_holder(piece_position, start_texture, "PieceExpireDissolve")
	if overlay == null:
		return

	var material := ShaderMaterial.new()
	material.shader = PIECE_EXPIRE_DISSOLVE_SHADER
	material.set_shader_parameter("progress", 0.0)
	material.set_shader_parameter("beam_size", PIECE_EXPIRE_DISSOLVE_BEAM_SIZE)
	material.set_shader_parameter("noise_density", PIECE_EXPIRE_DISSOLVE_NOISE_DENSITY)
	material.set_shader_parameter("color", PIECE_EXPIRE_DISSOLVE_COLOR)
	overlay.material = material

	var tween: Tween = create_animation_tween()
	if tween == null:
		if is_instance_valid(overlay):
			overlay.queue_free()
		return
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(material, "shader_parameter/progress", 1.0, PIECE_EXPIRE_DISSOLVE_DURATION)
	await tween.finished
	if is_instance_valid(overlay):
		overlay.queue_free()

func play_invisibility_exit(holder: Sprite2D) -> void:
	if holder == null or !is_instance_valid(holder) or PIECE_INVISIBILITY_REFRACT_SHADER == null:
		return
	if !is_tween_owner_inside_tree():
		return

	var scene_tree: SceneTree = tween_owner.get_tree()
	if scene_tree == null:
		return
	await scene_tree.create_timer(PIECE_INVISIBILITY_VISIBLE_HOLD_DURATION).timeout
	if !is_tween_owner_inside_tree() or !is_instance_valid(holder):
		return

	var refract_material := ShaderMaterial.new()
	refract_material.shader = PIECE_INVISIBILITY_REFRACT_SHADER
	refract_material.set_shader_parameter("dist", PIECE_INVISIBILITY_REFRACT_DISTANCE)
	refract_material.set_shader_parameter("alpha", 0.0)
	holder.material = refract_material

	var refract_tween: Tween = create_animation_tween()
	if refract_tween == null:
		return
	refract_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	refract_tween.tween_property(refract_material, "shader_parameter/alpha", 1.0, PIECE_INVISIBILITY_REFRACT_IN_DURATION)
	await refract_tween.finished
	if !is_tween_owner_inside_tree() or !is_instance_valid(holder):
		return

	var fade_tween: Tween = create_animation_tween()
	if fade_tween == null:
		return
	fade_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	fade_tween.tween_property(holder, "self_modulate:a", 0.0, PIECE_INVISIBILITY_FADE_OUT_DURATION)
	await fade_tween.finished
	if is_instance_valid(holder):
		holder.queue_free()

func play_invisibility_reveal(holder: Sprite2D) -> void:
	if holder == null or !is_instance_valid(holder) or PIECE_INVISIBILITY_REFRACT_SHADER == null:
		return
	if !is_tween_owner_inside_tree():
		return

	holder.self_modulate.a = 0.0
	var refract_material := ShaderMaterial.new()
	refract_material.shader = PIECE_INVISIBILITY_REFRACT_SHADER
	refract_material.set_shader_parameter("dist", PIECE_INVISIBILITY_REFRACT_DISTANCE)
	refract_material.set_shader_parameter("alpha", 1.0)
	holder.material = refract_material

	var reveal_tween: Tween = create_animation_tween()
	if reveal_tween == null:
		holder.self_modulate.a = 1.0
		holder.material = null
		return
	reveal_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	reveal_tween.tween_property(holder, "self_modulate:a", 1.0, PIECE_INVISIBILITY_REFRACT_IN_DURATION)
	reveal_tween.parallel().tween_property(refract_material, "shader_parameter/alpha", 0.0, PIECE_INVISIBILITY_REFRACT_IN_DURATION)
	await reveal_tween.finished
	if is_instance_valid(holder):
		holder.material = null
		holder.self_modulate.a = 1.0

## `color` stands in for `capture_sparkle_color` when it is not transparent.
func play_capture_sparkle(board_pos: Vector2, color: Color = Color.TRANSPARENT) -> void:
	if PIECE_CAPTURE_SPARKLE_SHADER == null or !has_effect_parent():
		return

	var sparkle := Sprite2D.new()
	if flipped_view:
		sparkle.global_rotation_degrees = 180
	piece_effects_node.add_child(sparkle)
	sparkle.name = "CaptureSparkle"
	sparkle.light_mask = piece_effect_light_receive_mask
	sparkle.texture_filter = texture_filter_value
	sparkle.texture = get_attach_rays_square_texture()
	sparkle.position = get_position_local(board_pos) + Vector2(
		0.0,
		-default_piece_visual_height * 0.18 * get_perspective_scale(board_pos)
	)
	sparkle.z_as_relative = false
	sparkle.z_index = get_piece_effect_z_index(board_pos)

	var material := ShaderMaterial.new()
	material.shader = PIECE_CAPTURE_SPARKLE_SHADER
	material.set_shader_parameter("color", color if color.a > 0.0 else capture_sparkle_color)
	material.set_shader_parameter("scale", capture_sparkle_shader_scale)
	material.set_shader_parameter("circle_ratio", capture_sparkle_circle_ratio)
	material.set_shader_parameter("decay_magnitude", capture_sparkle_decay_magnitude)
	material.set_shader_parameter("rotate_speed", capture_sparkle_rotate_speed)
	material.set_shader_parameter("time_speed", capture_sparkle_time_speed)
	material.set_shader_parameter("frequency_base", capture_sparkle_frequency_base)
	material.set_shader_parameter("frequency_disturbance_scale", capture_sparkle_frequency_disturbance_scale)
	material.set_shader_parameter("alpha_strength", 1.0)
	sparkle.material = material

	var texture_size: Vector2 = sparkle.texture.get_size()
	var texture_extent: float = maxf(texture_size.x, texture_size.y)
	if texture_extent > 0.0:
		var target_size: float = float(cell_width) * capture_sparkle_size_ratio * get_perspective_scale(board_pos)
		sparkle.scale = Vector2.ONE * (target_size / texture_extent)

	var fade_tween: Tween = create_animation_tween()
	if fade_tween == null:
		sparkle.queue_free()
		return
	fade_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fade_tween.tween_interval(capture_sparkle_duration * (1.0 - capture_sparkle_fade_out_ratio))
	fade_tween.tween_property(material, "shader_parameter/alpha_strength", 0.0, capture_sparkle_duration * capture_sparkle_fade_out_ratio)
	fade_tween.finished.connect(func():
		if is_instance_valid(sparkle):
			sparkle.queue_free()
	)

func play_bomb_warning(target_pos: Vector2) -> void:
	if BOMB_WARNING_TEXTURE == null or !has_effect_parent():
		return

	var marker := Sprite2D.new()
	if flipped_view:
		marker.global_rotation_degrees = 180
	piece_effects_node.add_child(marker)
	marker.name = "BombWarning"
	marker.light_mask = piece_effect_light_receive_mask
	marker.texture_filter = texture_filter_value
	marker.texture = BOMB_WARNING_TEXTURE
	marker.z_as_relative = false
	marker.z_index = get_piece_effect_z_index(target_pos) + BOMB_WARNING_Z_OFFSET
	marker.self_modulate = Color(bomb_warning_color.r, bomb_warning_color.g, bomb_warning_color.b, 0.0)

	var target_position: Vector2 = get_bomb_warning_target_position(target_pos)
	marker.position = target_position + Vector2(0.0, bomb_warning_rise_distance * get_perspective_scale(target_pos))

	var texture_size: Vector2 = BOMB_WARNING_TEXTURE.get_size()
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

func is_affix_holder_active(holder) -> bool:
	return is_tween_owner_inside_tree() and holder != null and is_instance_valid(holder) and holder is Sprite2D

func await_affix_interval(duration: float) -> bool:
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
