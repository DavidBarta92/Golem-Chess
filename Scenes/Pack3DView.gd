extends Control
class_name Pack3DView

const FRONT_SHADER = preload("res://Shaders/pack_front_3d.gdshader")
const SIDE_SHADER = preload("res://Shaders/pack_side_3d.gdshader")
const VIEWPORT_SIZE: Vector2i = Vector2i(768, 1024)
const PACK_HEIGHT: float = 2.62
const PACK_WIDTH: float = PACK_HEIGHT * 0.75
const PACK_THICKNESS: float = 0.36
const FRONT_SUBDIVIDE_WIDTH: int = 48
const FRONT_SUBDIVIDE_DEPTH: int = 72
const MAX_HOVER_YAW_DEGREES: float = 9.0
const MAX_HOVER_PITCH_DEGREES: float = 7.0
const AMBIENT_YAW_DEGREES: float = 3.2
const AMBIENT_PITCH_DEGREES: float = 2.4
const AMBIENT_ROLL_DEGREES: float = 1.4
const AMBIENT_FLOAT_HEIGHT: float = 0.055
const MOTION_LERP_SPEED: float = 9.5
const FOIL_TILT_UV_SHIFT: float = 0.18

@export var front_texture: Texture2D
@export var back_texture: Texture2D
@export var height_texture: Texture2D
@export var normal_texture: Texture2D
@export var roughness_texture: Texture2D
@export var foil_mask_texture: Texture2D

var texture_rect: TextureRect
var sub_viewport: SubViewport
var camera: Camera3D
var directional_light: DirectionalLight3D
var omni_light: OmniLight3D
var pack_pivot: Node3D
var side_body: MeshInstance3D
var front_surface: MeshInstance3D
var back_surface: MeshInstance3D
var front_material: ShaderMaterial
var back_material: StandardMaterial3D
var side_material: ShaderMaterial
var default_albedo_texture: Texture2D
var default_height_texture: Texture2D
var default_normal_texture: Texture2D
var default_roughness_texture: Texture2D
var default_foil_mask_texture: Texture2D
var hovered: bool = false
var selected: bool = false
var hover_tracking_enabled: bool = true
var motion_time: float = 0.0
var current_pitch: float = 0.0
var current_yaw: float = 0.0
var current_roll: float = 0.0
var current_float: float = 0.0
var tear_cut_progress: float = 0.0
var tear_cut_y: float = 0.085
var tear_wave_strength: float = 0.012
var tear_seed: float = 0.0
var tear_edge_softness: float = 0.006

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	clip_contents = false
	_create_default_textures()
	_create_viewport_nodes()
	_create_3d_scene()
	_apply_assets()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	set_continuous_rendering(false)

func set_pack_definition(pack_definition: PackDefinition, fallback_front_texture: Texture2D = null) -> void:
	if pack_definition == null:
		set_pack_assets(fallback_front_texture)
		return

	var resolved_front: Texture2D = pack_definition.get_front_texture()
	if resolved_front == null:
		resolved_front = fallback_front_texture
	set_pack_assets(
		resolved_front,
		pack_definition.pack_back_texture,
		pack_definition.pack_height_texture,
		pack_definition.pack_normal_texture,
		pack_definition.pack_roughness_texture,
		pack_definition.pack_foil_mask_texture
	)

func set_pack_assets(
	new_front_texture: Texture2D,
	new_back_texture: Texture2D = null,
	new_height_texture: Texture2D = null,
	new_normal_texture: Texture2D = null,
	new_roughness_texture: Texture2D = null,
	new_foil_mask_texture: Texture2D = null
) -> void:
	front_texture = new_front_texture
	back_texture = new_back_texture
	height_texture = new_height_texture
	normal_texture = new_normal_texture
	roughness_texture = new_roughness_texture
	foil_mask_texture = new_foil_mask_texture
	if is_node_ready():
		_apply_assets()

func get_front_texture() -> Texture2D:
	return front_texture

func get_render_texture() -> Texture2D:
	if sub_viewport == null:
		return null
	return sub_viewport.get_texture()

func set_tear_parameters(cut_y: float, wave_strength: float, seed: float, edge_softness: float) -> void:
	tear_cut_y = cut_y
	tear_wave_strength = wave_strength
	tear_seed = seed
	tear_edge_softness = edge_softness
	_sync_tear_shader_parameters()

func set_tear_cut_progress(progress: float) -> void:
	tear_cut_progress = clampf(progress, 0.0, 1.0)
	_sync_tear_shader_parameters()
	request_static_render()

func set_selected(value: bool) -> void:
	selected = value
	set_continuous_rendering(selected or hovered)

func set_hover_tracking_enabled(value: bool) -> void:
	hover_tracking_enabled = value
	if !value:
		hovered = false
		set_continuous_rendering(selected)

func set_continuous_rendering(value: bool) -> void:
	set_process(value)
	if sub_viewport == null:
		return
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if value else SubViewport.UPDATE_ONCE

func request_static_render() -> void:
	if sub_viewport != null:
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func _process(delta: float) -> void:
	if pack_pivot == null:
		return

	motion_time += delta
	var target_yaw: float = sin(motion_time * 0.92) * AMBIENT_YAW_DEGREES
	var target_pitch: float = sin(motion_time * 0.74 + 1.15) * AMBIENT_PITCH_DEGREES
	var target_roll: float = sin(motion_time * 1.08 + 0.65) * AMBIENT_ROLL_DEGREES
	var target_float: float = sin(motion_time * 1.18) * AMBIENT_FLOAT_HEIGHT

	if hovered and hover_tracking_enabled:
		var local_mouse: Vector2 = get_local_mouse_position()
		var safe_size: Vector2 = size.max(Vector2.ONE)
		var x_ratio: float = clampf(local_mouse.x / safe_size.x, 0.0, 1.0)
		var y_ratio: float = clampf(local_mouse.y / safe_size.y, 0.0, 1.0)
		target_yaw = lerpf(-MAX_HOVER_YAW_DEGREES, MAX_HOVER_YAW_DEGREES, x_ratio)
		target_pitch = lerpf(MAX_HOVER_PITCH_DEGREES, -MAX_HOVER_PITCH_DEGREES, y_ratio)
		target_roll = target_yaw * 0.08

	var smoothing: float = 1.0 - exp(-MOTION_LERP_SPEED * maxf(delta, 0.001))
	current_yaw = lerpf(current_yaw, target_yaw, smoothing)
	current_pitch = lerpf(current_pitch, target_pitch, smoothing)
	current_roll = lerpf(current_roll, target_roll, smoothing)
	current_float = lerpf(current_float, target_float, smoothing)
	pack_pivot.rotation_degrees = Vector3(current_pitch, current_yaw, current_roll)
	pack_pivot.position.y = current_float
	_update_foil_tilt_offset()

func _create_viewport_nodes() -> void:
	texture_rect = TextureRect.new()
	texture_rect.name = "RenderedTexture"
	add_child(texture_rect)
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_rect.offset_left = 0.0
	texture_rect.offset_top = 0.0
	texture_rect.offset_right = 0.0
	texture_rect.offset_bottom = 0.0
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	sub_viewport = SubViewport.new()
	sub_viewport.name = "PackSubViewport"
	add_child(sub_viewport)
	sub_viewport.size = VIEWPORT_SIZE
	sub_viewport.transparent_bg = true
	sub_viewport.own_world_3d = true
	sub_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	sub_viewport.msaa_3d = Viewport.MSAA_4X
	texture_rect.texture = sub_viewport.get_texture()

func _create_3d_scene() -> void:
	var scene_root := Node3D.new()
	scene_root.name = "Pack3DScene"
	sub_viewport.add_child(scene_root)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0.0, 0.0, 6.35)
	camera.fov = 28.0
	camera.near = 0.03
	camera.far = 20.0
	camera.current = true
	scene_root.add_child(camera)

	directional_light = DirectionalLight3D.new()
	directional_light.name = "DirectionalLight3D"
	directional_light.light_energy = 1.65
	directional_light.rotation_degrees = Vector3(-34.0, -26.0, 0.0)
	scene_root.add_child(directional_light)

	omni_light = OmniLight3D.new()
	omni_light.name = "OmniLight3D"
	omni_light.position = Vector3(-1.1, 1.15, 2.0)
	omni_light.light_energy = 1.2
	omni_light.omni_range = 5.0
	scene_root.add_child(omni_light)

	pack_pivot = Node3D.new()
	pack_pivot.name = "PackPivot"
	scene_root.add_child(pack_pivot)

	_create_side_body()
	_create_front_surface()
	_create_back_surface()

func _create_side_body() -> void:
	side_material = ShaderMaterial.new()
	side_material.shader = SIDE_SHADER
	side_material.set_shader_parameter("pack_width", PACK_WIDTH)
	side_material.set_shader_parameter("pack_height", PACK_HEIGHT)

	var side_mesh := BoxMesh.new()
	side_mesh.size = Vector3(PACK_WIDTH, PACK_HEIGHT, PACK_THICKNESS)
	side_body = MeshInstance3D.new()
	side_body.name = "SideThicknessBox"
	side_body.mesh = side_mesh
	side_body.position = Vector3(0.0, 0.0, -PACK_THICKNESS * 0.55)
	side_body.material_override = side_material
	pack_pivot.add_child(side_body)

func _create_front_surface() -> void:
	front_material = ShaderMaterial.new()
	front_material.shader = FRONT_SHADER

	var front_mesh := PlaneMesh.new()
	front_mesh.size = Vector2(PACK_WIDTH, PACK_HEIGHT)
	front_mesh.subdivide_width = FRONT_SUBDIVIDE_WIDTH
	front_mesh.subdivide_depth = FRONT_SUBDIVIDE_DEPTH
	front_mesh.orientation = PlaneMesh.FACE_Z

	front_surface = MeshInstance3D.new()
	front_surface.name = "FrontSurface"
	front_surface.mesh = front_mesh
	front_surface.position = Vector3(0.0, 0.0, 0.025)
	front_surface.material_override = front_material
	front_surface.custom_aabb = AABB(
		Vector3(-PACK_WIDTH * 0.62, -PACK_HEIGHT * 0.62, -0.28),
		Vector3(PACK_WIDTH * 1.24, PACK_HEIGHT * 1.24, 0.58)
	)
	pack_pivot.add_child(front_surface)

func _create_back_surface() -> void:
	back_material = StandardMaterial3D.new()
	back_material.roughness = 0.82
	back_material.metallic = 0.0
	back_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	back_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	back_material.alpha_scissor_threshold = 0.035

	var back_mesh := QuadMesh.new()
	back_mesh.size = Vector2(PACK_WIDTH, PACK_HEIGHT)
	back_surface = MeshInstance3D.new()
	back_surface.name = "BackSurface"
	back_surface.mesh = back_mesh
	back_surface.position = Vector3(0.0, 0.0, -PACK_THICKNESS - 0.045)
	back_surface.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	back_surface.material_override = back_material
	pack_pivot.add_child(back_surface)

func _apply_assets() -> void:
	if front_material == null:
		return

	var resolved_front: Texture2D = front_texture if front_texture != null else default_albedo_texture
	var resolved_back: Texture2D = back_texture if back_texture != null else resolved_front
	var resolved_height: Texture2D = height_texture if height_texture != null else default_height_texture
	var resolved_normal: Texture2D = normal_texture if normal_texture != null else default_normal_texture
	var resolved_roughness: Texture2D = roughness_texture if roughness_texture != null else default_roughness_texture
	var resolved_foil_mask: Texture2D = foil_mask_texture if foil_mask_texture != null else default_foil_mask_texture

	front_material.set_shader_parameter("albedo_texture", resolved_front)
	front_material.set_shader_parameter("height_texture", resolved_height)
	front_material.set_shader_parameter("normal_texture", resolved_normal)
	front_material.set_shader_parameter("roughness_texture", resolved_roughness)
	front_material.set_shader_parameter("foil_mask_texture", resolved_foil_mask)
	front_material.set_shader_parameter("has_height_texture", height_texture != null)
	front_material.set_shader_parameter("has_normal_texture", normal_texture != null)
	front_material.set_shader_parameter("has_roughness_texture", roughness_texture != null)
	front_material.set_shader_parameter("has_foil_mask_texture", foil_mask_texture != null)
	front_material.set_shader_parameter("foil_tilt_offset", Vector2.ZERO)
	_sync_tear_shader_parameters()

	if back_material != null:
		back_material.albedo_texture = resolved_back
	if side_material != null:
		side_material.set_shader_parameter("side_texture", resolved_back)
		side_material.set_shader_parameter("mask_texture", resolved_front)
	request_static_render()

func _update_foil_tilt_offset() -> void:
	if front_material == null:
		return

	var yaw_ratio: float = clampf(current_yaw / MAX_HOVER_YAW_DEGREES, -1.0, 1.0)
	var pitch_ratio: float = clampf(current_pitch / MAX_HOVER_PITCH_DEGREES, -1.0, 1.0)
	var counter_tilt_offset := Vector2(-yaw_ratio, pitch_ratio) * FOIL_TILT_UV_SHIFT
	front_material.set_shader_parameter("foil_tilt_offset", counter_tilt_offset)

func _sync_tear_shader_parameters() -> void:
	if front_material != null:
		front_material.set_shader_parameter("tear_cut_progress", tear_cut_progress)
		front_material.set_shader_parameter("tear_cut_y", tear_cut_y)
		front_material.set_shader_parameter("tear_wave_strength", tear_wave_strength)
		front_material.set_shader_parameter("tear_seed", tear_seed)
		front_material.set_shader_parameter("tear_edge_softness", tear_edge_softness)
	if side_material != null:
		side_material.set_shader_parameter("tear_cut_progress", tear_cut_progress)
		side_material.set_shader_parameter("tear_cut_y", tear_cut_y)
		side_material.set_shader_parameter("tear_wave_strength", tear_wave_strength)
		side_material.set_shader_parameter("tear_seed", tear_seed)
		side_material.set_shader_parameter("tear_edge_softness", tear_edge_softness)

func _create_default_textures() -> void:
	default_albedo_texture = _create_color_texture(Color(1.0, 1.0, 1.0, 1.0))
	default_height_texture = _create_color_texture(Color(0.5, 0.5, 0.5, 1.0))
	default_normal_texture = _create_color_texture(Color(0.5, 0.5, 1.0, 1.0))
	default_roughness_texture = _create_color_texture(Color(0.48, 0.48, 0.48, 1.0))
	default_foil_mask_texture = _create_color_texture(Color(0.0, 0.0, 0.0, 1.0))

func _create_color_texture(color: Color) -> Texture2D:
	var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.set_pixel(0, 0, color)
	return ImageTexture.create_from_image(image)

func _on_mouse_entered() -> void:
	hovered = true
	set_continuous_rendering(true)

func _on_mouse_exited() -> void:
	hovered = false
	set_continuous_rendering(selected)
