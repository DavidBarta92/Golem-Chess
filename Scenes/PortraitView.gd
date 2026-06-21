@tool
extends Control
class_name PortraitView

const CANVAS_SIZE: Vector2 = Vector2(512, 512)
const HEAD_PIVOT: Vector2 = Vector2(256, 296)
const HEAD_TURN_DEGREES: float = 2.0
const HEAD_DRIFT_PIXELS: float = 2.0
const EYE_DRIFT_PIXELS: float = 6.0
const BREATH_PIXELS: float = 2.0
const BREATH_SCALE: float = 0.004
const BLINK_MIN_INTERVAL: float = 2.4
const BLINK_MAX_INTERVAL: float = 5.8
const BLINK_DURATION: float = 0.14
const BLINK_EYE_DROP_PIXELS: float = 22.0
const LOOK_MIN_INTERVAL: float = 1.4
const LOOK_MAX_INTERVAL: float = 3.7
const LOOK_MIN_DURATION: float = 0.16
const LOOK_MAX_DURATION: float = 0.34
const DEFAULT_LOOK_DOWN_PUPIL_OFFSET: Vector2 = Vector2(0.0, 7.0)
const TURN_FOCUS_JITTER_X: float = 1.1
const TURN_FOCUS_JITTER_Y: float = 0.7
const TURN_FOCUS_MIN_INTERVAL: float = 0.55
const TURN_FOCUS_MAX_INTERVAL: float = 1.35
const DEFAULT_LOOK_DOWN_EYELID_DROP_PIXELS: float = 5.5
const DEFAULT_LOOK_DOWN_HEAD_OFFSET: Vector2 = Vector2(0.0, 3.5)
const DEFAULT_LOOK_DOWN_HEAD_SCALE: Vector2 = Vector2(1.012, 0.985)
const TURN_FOCUS_BLEND_SPEED: float = 6.0
const HEAD_MOTION_MIN_INTERVAL: float = 2.8
const HEAD_MOTION_MAX_INTERVAL: float = 6.5
const HEAD_MOTION_MIN_DURATION: float = 0.28
const HEAD_MOTION_MAX_DURATION: float = 0.58
const PNG_EYELASH_BLINK_DROP_SCALE: float = 0.3
const PNG_EYELASH_OCCLUSION_BASE_Y: float = 125.0
const SCENE_MASK_SHADER = preload("res://Shaders/portrait_scene_mask.gdshader")
const SCENE_MASK_TEXTURE = preload("res://Assets/portrait_mask_local.png")
const EYE_OCCLUSION_SHADER = preload("res://Shaders/portrait_eye_occlusion.gdshader")

@export var portrait_config: PortraitConfig:
	set(value):
		_portrait_config = value
		if is_inside_tree():
			set_portrait_config(value)
	get:
		return _portrait_config

@export var animation_enabled: bool = true
@export var show_frame: bool = true
@export var show_background: bool = false:
	set(value):
		_show_background = value
		if is_inside_tree():
			update_background_style()
	get:
		return _show_background
@export var background_color: Color = Color(0.909804, 0.694118, 0.486275, 1.0):
	set(value):
		_background_color = value
		if is_inside_tree():
			update_background_style()
	get:
		return _background_color
@export var use_scene_mask: bool = false:
	set(value):
		_use_scene_mask = value
		if is_inside_tree():
			apply_scene_mask()
	get:
		return _use_scene_mask

var _portrait_config: PortraitConfig
var _use_scene_mask: bool = false
var _show_background: bool = false
var _background_color: Color = Color(0.909804, 0.694118, 0.486275, 1.0)
var mask_group: CanvasGroup
var background_rect: ColorRect
var canvas_root: Node2D
var torso_root: Node2D
var head_root: Node2D
var face_root: Node2D
var body_layer: Sprite2D
var neck_layer: Sprite2D
var torso_layer: Sprite2D
var head_layer: Sprite2D
var hair_layer: Sprite2D
var facial_hair_layer: Sprite2D
var eyebrows_layer: Sprite2D
var eyelash_layer: Sprite2D
var eyewhite_layer: Sprite2D
var eyes_layer: Sprite2D
var closed_eyes_layer: Sprite2D
var pupils_layer: Sprite2D
var nose_layer: Sprite2D
var brows_layer: Sprite2D
var mouth_layer: Sprite2D
var mustache_layer: Sprite2D
var rng := RandomNumberGenerator.new()
var idle_time: float = 0.0
var next_blink_time: float = 0.0
var blink_remaining: float = 0.0
var current_blink_amount: float = 0.0
var applied_config: PortraitConfig
var applied_signature: String = ""
var layer_base_positions: Dictionary = {}
var eye_occlusion_materials: Dictionary = {}
var current_pupil_offset: Vector2 = Vector2.ZERO
var pupil_from_offset: Vector2 = Vector2.ZERO
var pupil_target_offset: Vector2 = Vector2.ZERO
var pupil_motion_elapsed: float = 0.0
var pupil_motion_duration: float = 0.0
var pupil_motion_active: bool = false
var next_look_time: float = 0.0
var turn_focus_enabled: bool = false
var turn_focus_amount: float = 0.0
var head_current_offset: Vector2 = Vector2.ZERO
var head_from_offset: Vector2 = Vector2.ZERO
var head_target_offset: Vector2 = Vector2.ZERO
var head_current_rotation: float = 0.0
var head_from_rotation: float = 0.0
var head_target_rotation: float = 0.0
var head_motion_elapsed: float = 0.0
var head_motion_duration: float = 0.0
var head_motion_active: bool = false
var next_head_motion_time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	build_node_tree()
	if portrait_config == null:
		portrait_config = PortraitLibrary.get_default_player_portrait()
	set_portrait_config(portrait_config)
	set_process(animation_enabled or Engine.is_editor_hint())

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		arrange_canvas()
		queue_redraw()

func _draw() -> void:
	if !show_frame:
		return

	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.035, 0.038, 0.045, 0.78), true)
	draw_rect(Rect2(Vector2(1, 1), Vector2(maxf(0.0, size.x - 2.0), maxf(0.0, size.y - 2.0))), Color(1.0, 0.86, 0.30, 0.30), false, 2.0)

func build_node_tree() -> void:
	if canvas_root != null:
		return

	mask_group = get_node_or_null("PortraitMaskGroup") as CanvasGroup
	if mask_group == null:
		mask_group = CanvasGroup.new()
		mask_group.name = "PortraitMaskGroup"
		add_child(mask_group)
	mask_group.z_index = 0

	background_rect = mask_group.get_node_or_null("PortraitBackground") as ColorRect
	if background_rect == null:
		background_rect = ColorRect.new()
		background_rect.name = "PortraitBackground"
		mask_group.add_child(background_rect)
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_rect.z_index = -1000

	canvas_root = mask_group.get_node_or_null("PortraitCanvas") as Node2D
	if canvas_root == null:
		canvas_root = Node2D.new()
		canvas_root.name = "PortraitCanvas"
		mask_group.add_child(canvas_root)

	var mask_debug := get_node_or_null("PortraitMaskDebug") as Control
	if mask_debug != null:
		mask_debug.visible = Engine.is_editor_hint()
		move_child(mask_debug, get_child_count() - 1)

	torso_root = canvas_root.get_node_or_null("TorsoRoot") as Node2D
	if torso_root == null:
		torso_root = Node2D.new()
		torso_root.name = "TorsoRoot"
		canvas_root.add_child(torso_root)

	head_root = canvas_root.get_node_or_null("HeadRoot") as Node2D
	if head_root == null:
		head_root = Node2D.new()
		head_root.name = "HeadRoot"
		canvas_root.add_child(head_root)
	head_root.position = get_head_pivot()

	face_root = head_root.get_node_or_null("FaceRoot") as Node2D
	if face_root == null:
		face_root = Node2D.new()
		face_root.name = "FaceRoot"
		head_root.add_child(face_root)

	apply_scene_mask()
	update_background_style()
	arrange_canvas()

func apply_scene_mask() -> void:
	update_mask_group_material()
	update_layer_scene_mask_materials()
	update_background_style()

func update_mask_group_material() -> void:
	if mask_group == null:
		return
	if !_use_scene_mask:
		mask_group.material = null
		return
	var material := mask_group.material as ShaderMaterial
	if material == null or material.shader != SCENE_MASK_SHADER:
		material = ShaderMaterial.new()
		material.shader = SCENE_MASK_SHADER
		mask_group.material = material
	material.set_shader_parameter("mask_texture", SCENE_MASK_TEXTURE)

func update_background_style() -> void:
	if background_rect == null:
		return

	background_rect.visible = _show_background
	background_rect.color = _background_color
	background_rect.material = null

func set_portrait_config(config: PortraitConfig) -> void:
	var next_config: PortraitConfig = PortraitLibrary.config_from_data_or_default(config)
	if canvas_root == null:
		_portrait_config = next_config
		applied_config = next_config
		applied_signature = ""
		return

	var next_signature: String = JSON.stringify(next_config.to_dict())
	if applied_config != null and applied_signature == next_signature:
		arrange_canvas()
		apply_current_pose()
		return

	applied_config = next_config
	applied_signature = next_signature
	_portrait_config = applied_config

	rng.seed = maxi(1, applied_config.seed)
	idle_time = rng.randf_range(0.0, 10.0)
	reset_animation_state()
	schedule_next_blink()
	schedule_next_look(0.4, 1.2)
	schedule_next_head_motion(1.0, 3.0)
	arrange_canvas()
	rebuild_layers()

func set_portrait_data(data: Dictionary, player_id: int = 0) -> void:
	set_portrait_config(PortraitLibrary.config_from_data_or_default(data, player_id))

func set_expression(expression: String) -> void:
	if applied_config == null:
		return
	applied_config.expression = PortraitConfig.sanitize_expression(expression)
	apply_expression()

func set_turn_focus(enabled: bool) -> void:
	if turn_focus_enabled == enabled:
		return

	turn_focus_enabled = enabled
	pupil_motion_active = false
	if enabled:
		start_pupil_motion(get_turn_focus_pupil_target())
	else:
		start_pupil_motion(Vector2.ZERO)

func rebuild_layers() -> void:
	clear_dynamic_layers(torso_root)
	clear_dynamic_layers(head_root)
	layer_base_positions.clear()
	eye_occlusion_materials.clear()
	body_layer = null
	neck_layer = null
	torso_layer = null
	head_layer = null
	hair_layer = null
	facial_hair_layer = null
	eyebrows_layer = null
	eyelash_layer = null
	eyewhite_layer = null
	eyes_layer = null
	closed_eyes_layer = null
	pupils_layer = null
	nose_layer = null
	mouth_layer = null
	brows_layer = null
	mustache_layer = null
	face_root = null

	head_root.position = get_head_pivot()
	head_root.rotation_degrees = 0.0
	head_root.scale = Vector2.ONE
	torso_root.position = Vector2.ZERO
	torso_root.scale = Vector2.ONE

	if !applied_config.png_part_ids.is_empty():
		rebuild_png_layers()
	else:
		rebuild_legacy_layers()

	apply_expression()
	apply_pupil_position()
	apply_blink_pose()

func rebuild_png_layers() -> void:
	var parts: Dictionary = applied_config.png_part_ids
	var head_categories: Array[String] = [
		"hair",
		"facial_hair",
		"eyebrows",
		"pupils",
		"eyelash",
		"eyewhite",
		"nose",
		"mouth",
		"head",
	]
	var body_categories: Array[String] = ["body", "neck"]

	for category in PortraitLibrary.PNG_LAYER_ORDER:
		var parent: Node2D = torso_root if category in body_categories else head_root
		if !(category in head_categories) and !(category in body_categories):
			continue
		var layer: Sprite2D = add_layer(
			parent,
			category,
			str(parts.get(category, "")),
			Color.WHITE,
			get_layer_local_offset(category, parent)
		)
		assign_png_layer(category, layer)

	eyes_layer = eyelash_layer
	brows_layer = eyebrows_layer
	mustache_layer = facial_hair_layer
	torso_layer = body_layer
	setup_png_eye_occlusion()

func setup_png_eye_occlusion() -> void:
	if eyelash_layer == null or eyelash_layer.texture == null:
		return
	apply_eye_occlusion_material(eyewhite_layer)
	apply_eye_occlusion_material(pupils_layer)

func apply_eye_occlusion_material(layer: Sprite2D) -> void:
	if layer == null:
		return
	var material := ShaderMaterial.new()
	material.shader = EYE_OCCLUSION_SHADER
	material.set_shader_parameter("scene_mask_texture", SCENE_MASK_TEXTURE)
	material.set_shader_parameter("scene_mask_enabled", 0.0)
	material.set_shader_parameter("occlusion_bottom_y_pixels", PNG_EYELASH_OCCLUSION_BASE_Y)
	material.set_shader_parameter("mask_strength", 0.0)
	layer.material = material
	eye_occlusion_materials[layer] = material

func update_layer_scene_mask_materials() -> void:
	for layer in layer_base_positions.keys():
		if layer is Sprite2D and is_instance_valid(layer):
			apply_scene_mask_material_to_layer(layer as Sprite2D)
	for material in eye_occlusion_materials.values():
		var shader_material := material as ShaderMaterial
		if shader_material != null:
			shader_material.set_shader_parameter("scene_mask_enabled", 0.0)

func apply_scene_mask_material_to_layer(layer: Sprite2D) -> void:
	if layer == null:
		return
	if eye_occlusion_materials.has(layer):
		var eye_material := eye_occlusion_materials[layer] as ShaderMaterial
		if eye_material != null:
			eye_material.set_shader_parameter("scene_mask_enabled", 0.0)
		return
	layer.material = null

func rebuild_legacy_layers() -> void:
	torso_layer = add_layer(torso_root, "torso", applied_config.torso_id, applied_config.clothing_color, get_layer_local_offset("torso", torso_root))
	body_layer = torso_layer
	head_layer = add_layer(head_root, "head", applied_config.head_id, applied_config.skin_color, get_layer_local_offset("head", head_root))
	hair_layer = add_layer(head_root, "hair", applied_config.hair_id, applied_config.hair_color, get_layer_local_offset("hair", head_root))

	face_root = head_root.get_node_or_null("FaceRoot") as Node2D
	if face_root == null:
		face_root = Node2D.new()
		face_root.name = "FaceRoot"
		head_root.add_child(face_root)
	face_root.z_index = 3

	pupils_layer = add_layer(face_root, "pupils", applied_config.pupils_id, applied_config.eye_color, get_layer_local_offset("pupils", face_root))
	eyes_layer = add_layer(face_root, "eyes", applied_config.eyes_id, Color.WHITE, get_layer_local_offset("eyes", face_root))
	closed_eyes_layer = add_layer(face_root, "closed_eyes", applied_config.closed_eyes_id, applied_config.hair_color, get_layer_local_offset("closed_eyes", face_root))
	mouth_layer = add_layer(face_root, "mouth", applied_config.mouth_id, applied_config.mouth_color, get_layer_local_offset("mouth", face_root))
	mustache_layer = add_layer(face_root, "mustache", applied_config.mustache_id, applied_config.hair_color, get_layer_local_offset("mustache", face_root))
	nose_layer = add_layer(face_root, "nose", applied_config.nose_id, applied_config.skin_color.darkened(0.12), get_layer_local_offset("nose", face_root))
	brows_layer = add_layer(face_root, "brows", applied_config.brows_id, applied_config.hair_color, get_layer_local_offset("brows", face_root))

func assign_png_layer(category: String, layer: Sprite2D) -> void:
	match category:
		"body":
			body_layer = layer
		"neck":
			neck_layer = layer
		"head":
			head_layer = layer
		"hair":
			hair_layer = layer
		"facial_hair":
			facial_hair_layer = layer
		"eyebrows":
			eyebrows_layer = layer
		"pupils":
			pupils_layer = layer
		"eyelash":
			eyelash_layer = layer
		"eyewhite":
			eyewhite_layer = layer
		"nose":
			nose_layer = layer
		"mouth":
			mouth_layer = layer

func add_layer(parent: Node2D, category: String, part_id: String, tint: Color, layer_offset: Vector2) -> Sprite2D:
	var resolved_id: String = str(part_id).strip_edges()
	if resolved_id.is_empty():
		return null

	var texture: Texture2D = PortraitLibrary.get_part_texture(category, resolved_id)
	if texture == null:
		return null

	var sprite := get_or_create_layer(parent, category, resolved_id)
	var created_by_code: bool = bool(sprite.get_meta("_created_by_code", false))
	var base_position: Vector2 = sprite.position
	if created_by_code:
		base_position = layer_offset
		sprite.position = layer_offset
		sprite.remove_meta("_created_by_code")
	sprite.name = get_layer_node_name(category, resolved_id)
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.centered = false
	sprite.modulate = get_layer_tint(tint)
	sprite.z_as_relative = false
	sprite.z_index = PortraitLibrary.get_render_order_z_index(category)
	sprite.set_meta("category", category)
	sprite.set_meta("base_position", base_position)
	sprite.set_meta("base_modulate", sprite.modulate)
	layer_base_positions[sprite] = base_position
	apply_scene_mask_material_to_layer(sprite)
	return sprite

func get_or_create_layer(parent: Node2D, category: String, part_id: String) -> Sprite2D:
	var layer := find_layer(parent, category)
	if layer != null:
		return layer
	var resolved_id: String = str(part_id).strip_edges()
	layer = Sprite2D.new()
	layer.name = get_layer_node_name(category, resolved_id)
	layer.set_meta("_created_by_code", true)
	parent.add_child(layer)
	return layer

func get_layer_node_name(category: String, part_id: String) -> String:
	return "%s_%s" % [PortraitLibrary.normalize_category(category), str(part_id).strip_edges()]

func clear_dynamic_layers(parent: Node) -> void:
	for child in parent.get_children():
		if child is Sprite2D:
			(child as Sprite2D).texture = null
			(child as Sprite2D).material = null
		clear_dynamic_layers(child)

func find_layer(parent: Node, category: String) -> Sprite2D:
	var normalized_category := PortraitLibrary.normalize_category(category)
	for child in parent.get_children():
		if child is Sprite2D and get_layer_category(child as Sprite2D) == normalized_category:
			return child
	for child in parent.get_children():
		var prefix: String = category.capitalize()
		if child is Sprite2D and str(child.name).begins_with(prefix):
			return child
	return null

func apply_expression() -> void:
	if brows_layer == null and mouth_layer == null:
		return

	var mouth_id: String = applied_config.mouth_id
	if brows_layer != null:
		brows_layer.rotation_degrees = 0.0
		brows_layer.scale = Vector2.ONE
		brows_layer.position = get_layer_base_position(brows_layer)

	if applied_config.png_part_ids.is_empty():
		match applied_config.expression:
			"happy":
				mouth_id = "mouth_smile"
				if brows_layer != null:
					brows_layer.rotation_degrees = -1.4
					brows_layer.position = get_layer_base_position(brows_layer) + Vector2(0.0, -2.0)
			"stern":
				mouth_id = "mouth_neutral"
				if brows_layer != null:
					brows_layer.rotation_degrees = 2.0
					brows_layer.scale = Vector2(0.98, 1.0)
					brows_layer.position = get_layer_base_position(brows_layer) + Vector2(0.0, 2.0)
			"worried":
				mouth_id = "mouth_frown"
				if brows_layer != null:
					brows_layer.rotation_degrees = -2.2
					brows_layer.position = get_layer_base_position(brows_layer) + Vector2(0.0, 1.0)
	elif brows_layer != null:
		match applied_config.expression:
			"happy":
				brows_layer.position = get_layer_base_position(brows_layer) + Vector2(0.0, -1.0)
			"stern":
				brows_layer.rotation_degrees = 1.0
				brows_layer.position = get_layer_base_position(brows_layer) + Vector2(0.0, 1.0)
			"worried":
				brows_layer.rotation_degrees = -1.0
				brows_layer.position = get_layer_base_position(brows_layer) + Vector2(0.0, 1.0)

	if mouth_layer != null and applied_config.png_part_ids.is_empty():
		mouth_layer.texture = PortraitLibrary.get_part_texture("mouth", mouth_id)

func get_layer_base_position(layer: Sprite2D) -> Vector2:
	return get_layer_rest_position(layer) + get_layer_pose_offset(get_layer_category(layer))

func get_layer_rest_position(layer: Sprite2D) -> Vector2:
	if layer == null:
		return Vector2.ZERO
	if layer.has_meta("base_position"):
		return PortraitConfig.value_to_vector2(layer.get_meta("base_position"), Vector2.ZERO)
	if layer_base_positions.has(layer):
		return PortraitConfig.value_to_vector2(layer_base_positions[layer], Vector2.ZERO)
	if layer.get_parent() == torso_root:
		return get_layer_local_offset("torso", torso_root)
	return Vector2.ZERO

func get_layer_category(layer: Sprite2D) -> String:
	if layer != null and layer.has_meta("category"):
		return str(layer.get_meta("category"))
	if layer != null:
		var node_name := str(layer.name).to_lower()
		for category in PortraitLibrary.REQUIRED_PNG_CATEGORIES:
			if node_name.begins_with(category):
				return category
	return ""

func get_layer_pose_offset(category: String) -> Vector2:
	if applied_config == null or category.is_empty():
		return Vector2.ZERO

	var pose_offsets: Dictionary = applied_config.look_down_layer_offsets
	if pose_offsets.has(category):
		return PortraitConfig.value_to_vector2(pose_offsets[category], Vector2.ZERO) * turn_focus_amount
	if category == "closed_eyes" and pose_offsets.has("eyes"):
		return PortraitConfig.value_to_vector2(pose_offsets["eyes"], Vector2.ZERO) * turn_focus_amount
	return Vector2.ZERO

func get_layer_base_modulate(layer: Sprite2D) -> Color:
	if layer == null:
		return Color.WHITE
	if layer.has_meta("base_modulate"):
		var meta_value = layer.get_meta("base_modulate")
		if meta_value is Color:
			return meta_value
	return Color.WHITE

func reset_static_layer_positions() -> void:
	for layer in [body_layer, neck_layer, torso_layer, head_layer, hair_layer, facial_hair_layer, eyebrows_layer, eyelash_layer, eyewhite_layer, eyes_layer, closed_eyes_layer, pupils_layer, mouth_layer, mustache_layer, nose_layer, brows_layer]:
		if layer != null and is_instance_valid(layer):
			layer.position = get_layer_base_position(layer)
			layer.scale = Vector2.ONE
			set_layer_alpha(layer, 1.0)

func arrange_canvas() -> void:
	if mask_group == null:
		return

	var available_size: Vector2 = size
	if available_size.x <= 0.0 or available_size.y <= 0.0:
		available_size = custom_minimum_size

	var composition_size: Vector2 = get_composition_size()
	var scale_factor: float = minf(available_size.x / composition_size.x, available_size.y / composition_size.y)
	var canvas_position: Vector2 = (available_size - composition_size * scale_factor) * 0.5

	if background_rect != null:
		background_rect.position = Vector2.ZERO
		background_rect.size = composition_size

	mask_group.scale = Vector2.ONE * scale_factor
	mask_group.position = canvas_position
	if canvas_root != null:
		canvas_root.scale = Vector2.ONE

func get_composition_size() -> Vector2:
	if _use_scene_mask and SCENE_MASK_TEXTURE != null:
		return SCENE_MASK_TEXTURE.get_size()
	return get_canvas_size()

func get_canvas_size() -> Vector2:
	if applied_config == null:
		return CANVAS_SIZE
	return Vector2(maxf(1.0, applied_config.canvas_size.x), maxf(1.0, applied_config.canvas_size.y))

func get_head_pivot() -> Vector2:
	if applied_config == null:
		return HEAD_PIVOT
	return applied_config.head_pivot

func get_layer_local_offset(category: String, parent: Node2D) -> Vector2:
	var canvas_offset: Vector2 = get_layer_canvas_offset(category)
	if parent == torso_root:
		return canvas_offset
	return canvas_offset - get_head_pivot()

func get_layer_canvas_offset(category: String) -> Vector2:
	if applied_config == null:
		return Vector2.ZERO

	var layer_offsets: Dictionary = applied_config.layer_offsets
	if layer_offsets.has(category):
		return PortraitConfig.value_to_vector2(layer_offsets[category], Vector2.ZERO)
	if category == "closed_eyes" and layer_offsets.has("eyes"):
		return PortraitConfig.value_to_vector2(layer_offsets["eyes"], applied_config.head_origin)
	if category == "torso":
		return applied_config.torso_layer_offset
	return applied_config.head_origin

func get_layer_tint(tint: Color) -> Color:
	if applied_config != null and applied_config.use_asset_colors:
		return Color.WHITE
	return tint

func reset_animation_state() -> void:
	next_blink_time = 0.0
	blink_remaining = 0.0
	current_blink_amount = 0.0
	current_pupil_offset = Vector2.ZERO
	pupil_from_offset = Vector2.ZERO
	pupil_target_offset = Vector2.ZERO
	pupil_motion_elapsed = 0.0
	pupil_motion_duration = 0.0
	pupil_motion_active = false
	next_look_time = 0.0
	turn_focus_amount = 0.0
	head_current_offset = Vector2.ZERO
	head_from_offset = Vector2.ZERO
	head_target_offset = Vector2.ZERO
	head_current_rotation = 0.0
	head_from_rotation = 0.0
	head_target_rotation = 0.0
	head_motion_elapsed = 0.0
	head_motion_duration = 0.0
	head_motion_active = false
	next_head_motion_time = 0.0

func _process(delta: float) -> void:
	if applied_config == null:
		return
	if Engine.is_editor_hint():
		return

	idle_time += delta
	update_torso_breath()
	update_turn_focus_pose(delta)
	update_head_motion(delta)
	update_pupil_look(delta)
	update_blink(delta)

func update_torso_breath() -> void:
	if torso_root == null:
		return
	if !applied_config.torso_breath_enabled:
		torso_root.position = Vector2.ZERO
		torso_root.scale = Vector2.ONE
		return

	var seed_offset: float = float(applied_config.seed % 97) * 0.017
	var breath: float = sin(idle_time * 1.18 + seed_offset)
	torso_root.position = Vector2(0.0, breath * BREATH_PIXELS)
	torso_root.scale = Vector2(1.0, 1.0 + breath * BREATH_SCALE)

func update_head_motion(delta: float) -> void:
	if head_root == null:
		return
	if !applied_config.occasional_head_motion_enabled:
		head_current_offset = Vector2.ZERO
		head_current_rotation = 0.0
		apply_head_transform()
		return

	if head_motion_active:
		head_motion_elapsed = minf(head_motion_elapsed + delta, head_motion_duration)
		var t: float = ease_unit(head_motion_elapsed / maxf(0.001, head_motion_duration))
		head_current_offset = head_from_offset.lerp(head_target_offset, t)
		head_current_rotation = head_from_rotation + (head_target_rotation - head_from_rotation) * t
		if head_motion_elapsed >= head_motion_duration:
			head_motion_active = false
			if head_target_offset.length_squared() > 0.01 or absf(head_target_rotation) > 0.01:
				schedule_next_head_motion(0.18, 0.55)
			else:
				schedule_next_head_motion()
	else:
		next_head_motion_time -= delta
		if next_head_motion_time <= 0.0:
			if head_current_offset.length_squared() > 0.01 or absf(head_current_rotation) > 0.01:
				start_head_motion(Vector2.ZERO, 0.0)
			else:
				var target_offset := Vector2(rng.randf_range(-HEAD_DRIFT_PIXELS, HEAD_DRIFT_PIXELS), rng.randf_range(-0.8, 0.8))
				var target_rotation := rng.randf_range(-HEAD_TURN_DEGREES, HEAD_TURN_DEGREES)
				start_head_motion(target_offset, target_rotation)

	apply_head_transform()

func update_turn_focus_pose(delta: float) -> void:
	var target_amount: float = 1.0 if turn_focus_enabled else 0.0
	var previous_amount: float = turn_focus_amount
	turn_focus_amount = move_toward(turn_focus_amount, target_amount, delta * TURN_FOCUS_BLEND_SPEED)
	if !is_equal_approx(previous_amount, turn_focus_amount):
		apply_current_pose()

func apply_head_transform() -> void:
	if head_root == null:
		return

	head_root.position = get_head_pivot() + head_current_offset + get_look_down_head_offset() * turn_focus_amount
	head_root.rotation_degrees = head_current_rotation * (1.0 - turn_focus_amount * 0.35)
	head_root.scale = Vector2.ONE.lerp(get_look_down_head_scale(), turn_focus_amount)

func apply_current_pose() -> void:
	apply_head_transform()
	for layer in [head_layer, hair_layer, facial_hair_layer, eyebrows_layer, eyelash_layer, eyewhite_layer, closed_eyes_layer, mouth_layer, mustache_layer, nose_layer]:
		if layer != null and is_instance_valid(layer):
			layer.position = get_layer_base_position(layer)
	apply_expression()
	apply_pupil_position()
	apply_blink_pose()

func update_pupil_look(delta: float) -> void:
	if pupils_layer == null:
		return

	if turn_focus_enabled:
		update_turn_focus_look(delta)
		return

	if pupil_motion_active:
		pupil_motion_elapsed = minf(pupil_motion_elapsed + delta, pupil_motion_duration)
		var t: float = ease_unit(pupil_motion_elapsed / maxf(0.001, pupil_motion_duration))
		current_pupil_offset = pupil_from_offset.lerp(pupil_target_offset, t)
		if pupil_motion_elapsed >= pupil_motion_duration:
			pupil_motion_active = false
			schedule_next_look()
	else:
		next_look_time -= delta
		if next_look_time <= 0.0:
			var target_offset := Vector2.ZERO
			if rng.randf() > 0.28:
				target_offset = Vector2(rng.randf_range(-EYE_DRIFT_PIXELS, EYE_DRIFT_PIXELS), rng.randf_range(-1.2, 1.0))
			start_pupil_motion(target_offset)

	apply_pupil_position()

func update_turn_focus_look(delta: float) -> void:
	if pupil_motion_active:
		pupil_motion_elapsed = minf(pupil_motion_elapsed + delta, pupil_motion_duration)
		var t: float = ease_unit(pupil_motion_elapsed / maxf(0.001, pupil_motion_duration))
		current_pupil_offset = pupil_from_offset.lerp(pupil_target_offset, t)
		if pupil_motion_elapsed >= pupil_motion_duration:
			pupil_motion_active = false
			schedule_next_look(TURN_FOCUS_MIN_INTERVAL, TURN_FOCUS_MAX_INTERVAL)
	else:
		next_look_time -= delta
		if next_look_time <= 0.0:
			start_pupil_motion(get_turn_focus_pupil_target())

	apply_pupil_position()

func update_blink(delta: float) -> void:
	if blink_remaining > 0.0:
		blink_remaining = maxf(0.0, blink_remaining - delta)
		var progress: float = 1.0 - blink_remaining / BLINK_DURATION
		current_blink_amount = sin(clampf(progress, 0.0, 1.0) * PI)
		apply_blink_pose()
		if blink_remaining <= 0.0:
			current_blink_amount = 0.0
			apply_blink_pose()
			schedule_next_blink()
		return

	next_blink_time -= delta
	if next_blink_time <= 0.0:
		blink_remaining = BLINK_DURATION
		current_blink_amount = 0.0
		apply_blink_pose()

func apply_pupil_position() -> void:
	if pupils_layer == null:
		return
	pupils_layer.position = get_layer_base_position(pupils_layer) + current_pupil_offset
	pupils_layer.scale = get_png_eye_squash_scale()

func apply_blink_pose() -> void:
	if applied_config == null:
		return

	if applied_config.blink_style == "move_eyes":
		if !applied_config.png_part_ids.is_empty():
			apply_png_blink_pose()
			return

		if eyes_layer != null:
			eyes_layer.visible = true
			eyes_layer.position = get_layer_base_position(eyes_layer) + Vector2(0.0, get_eyelid_drop_pixels())
		if eyelash_layer != null and eyelash_layer != eyes_layer:
			eyelash_layer.visible = true
			eyelash_layer.position = get_layer_base_position(eyelash_layer) + Vector2(0.0, get_eyelid_drop_pixels())
		if closed_eyes_layer != null:
			closed_eyes_layer.visible = false
		if pupils_layer != null:
			apply_pupil_position()
			var pupil_alpha: float = 1.0 - clampf((current_blink_amount - 0.25) / 0.75, 0.0, 1.0)
			pupils_layer.visible = pupil_alpha > 0.05
			set_layer_alpha(pupils_layer, pupil_alpha)
		return

	update_blink_layers(current_blink_amount > 0.0 or blink_remaining > 0.0)

func apply_png_blink_pose() -> void:
	var eye_drop: float = get_png_eye_drop_pixels()
	if eyelash_layer != null:
		eyelash_layer.visible = true
		eyelash_layer.position = get_layer_base_position(eyelash_layer) + Vector2(0.0, eye_drop)
		eyelash_layer.scale = Vector2.ONE
	if eyes_layer != null and eyes_layer != eyelash_layer:
		eyes_layer.visible = true
		eyes_layer.position = get_layer_base_position(eyes_layer) + Vector2(0.0, eye_drop)
		eyes_layer.scale = Vector2.ONE
	if eyewhite_layer != null:
		eyewhite_layer.visible = true
		eyewhite_layer.position = get_layer_base_position(eyewhite_layer) + Vector2(0.0, eye_drop)
		eyewhite_layer.scale = Vector2.ONE
	if pupils_layer != null:
		apply_pupil_position()
		pupils_layer.visible = true
		set_layer_alpha(pupils_layer, 1.0)
	update_eye_occlusion_materials(eye_drop)

func update_eye_occlusion_materials(eyelash_drop: float) -> void:
	var strength: float = clampf(maxf(current_blink_amount, turn_focus_amount * 0.45), 0.0, 1.0)
	for layer in eye_occlusion_materials.keys():
		if layer == null or !is_instance_valid(layer):
			continue
		var material: ShaderMaterial = eye_occlusion_materials[layer] as ShaderMaterial
		if material == null:
			continue
		var occlusion_bottom_y: float = PNG_EYELASH_OCCLUSION_BASE_Y + eyelash_drop
		if layer == pupils_layer:
			occlusion_bottom_y -= current_pupil_offset.y
		material.set_shader_parameter("occlusion_bottom_y_pixels", occlusion_bottom_y)
		material.set_shader_parameter("mask_strength", strength)

func update_blink_layers(blinking: bool) -> void:
	if eyes_layer != null:
		eyes_layer.visible = !blinking
		eyes_layer.position = get_layer_base_position(eyes_layer) + Vector2(0.0, get_eyelid_drop_pixels())
	if pupils_layer != null:
		pupils_layer.visible = !blinking
		apply_pupil_position()
		set_layer_alpha(pupils_layer, 1.0)
	if closed_eyes_layer != null:
		closed_eyes_layer.visible = blinking
		closed_eyes_layer.position = get_layer_base_position(closed_eyes_layer)

func schedule_next_blink() -> void:
	next_blink_time = rng.randf_range(BLINK_MIN_INTERVAL, BLINK_MAX_INTERVAL)

func get_eyelid_drop_pixels() -> float:
	return current_blink_amount * BLINK_EYE_DROP_PIXELS + turn_focus_amount * get_look_down_eyelid_drop_pixels()

func get_png_eyelash_drop_pixels() -> float:
	return current_blink_amount * BLINK_EYE_DROP_PIXELS * PNG_EYELASH_BLINK_DROP_SCALE + turn_focus_amount * get_look_down_eyelid_drop_pixels()

func get_png_eye_drop_pixels() -> float:
	return get_png_eyelash_drop_pixels()

func get_png_eye_squash_scale() -> Vector2:
	return Vector2.ONE

func schedule_next_look(min_delay: float = LOOK_MIN_INTERVAL, max_delay: float = LOOK_MAX_INTERVAL) -> void:
	next_look_time = rng.randf_range(min_delay, max_delay)

func schedule_next_head_motion(min_delay: float = HEAD_MOTION_MIN_INTERVAL, max_delay: float = HEAD_MOTION_MAX_INTERVAL) -> void:
	next_head_motion_time = rng.randf_range(min_delay, max_delay)

func start_pupil_motion(target_offset: Vector2) -> void:
	pupil_from_offset = current_pupil_offset
	pupil_target_offset = target_offset
	pupil_motion_elapsed = 0.0
	pupil_motion_duration = rng.randf_range(LOOK_MIN_DURATION, LOOK_MAX_DURATION)
	pupil_motion_active = true

func get_turn_focus_pupil_target() -> Vector2:
	return get_look_down_pupil_offset() + Vector2(
		rng.randf_range(-TURN_FOCUS_JITTER_X, TURN_FOCUS_JITTER_X),
		rng.randf_range(-TURN_FOCUS_JITTER_Y, TURN_FOCUS_JITTER_Y)
	)

func get_look_down_pupil_offset() -> Vector2:
	if applied_config == null:
		return DEFAULT_LOOK_DOWN_PUPIL_OFFSET
	return applied_config.look_down_pupil_offset

func get_look_down_eyelid_drop_pixels() -> float:
	if applied_config == null:
		return DEFAULT_LOOK_DOWN_EYELID_DROP_PIXELS
	return applied_config.look_down_eyelid_drop_pixels

func get_look_down_head_offset() -> Vector2:
	if applied_config == null:
		return DEFAULT_LOOK_DOWN_HEAD_OFFSET
	return applied_config.look_down_head_offset

func get_look_down_head_scale() -> Vector2:
	if applied_config == null:
		return DEFAULT_LOOK_DOWN_HEAD_SCALE
	return applied_config.look_down_head_scale

func start_head_motion(target_offset: Vector2, target_rotation: float) -> void:
	head_from_offset = head_current_offset
	head_target_offset = target_offset
	head_from_rotation = head_current_rotation
	head_target_rotation = target_rotation
	head_motion_elapsed = 0.0
	head_motion_duration = rng.randf_range(HEAD_MOTION_MIN_DURATION, HEAD_MOTION_MAX_DURATION)
	head_motion_active = true

func set_layer_alpha(layer: Sprite2D, alpha: float) -> void:
	if layer == null:
		return
	var base_modulate: Color = get_layer_base_modulate(layer)
	base_modulate.a *= clampf(alpha, 0.0, 1.0)
	layer.modulate = base_modulate

func ease_unit(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
