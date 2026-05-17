extends Button
class_name CardVisual

const BURN_SHADER = preload("res://Shaders/card_burn.gdshader")
const GRAYSCALE_SHADER = preload("res://Shaders/card_grayscale.gdshader")
const CARD_ART_MASK_SHADER = preload("res://Shaders/card_art_mask.gdshader")
const CARD_FRONT_TEXTURE = preload("res://Assets/stamp_base.svg")
const CARD_BACK_TEXTURE = preload("res://Assets/stamp_back.svg")
const BASIC_TYPE_FRAME_TEXTURE = preload("res://Assets/basic_frame.svg")
const NEXUS_TYPE_FRAME_TEXTURE = preload("res://Assets/nexus_frame.svg")
const SHARED_TYPE_FRAME_TEXTURE = preload("res://Assets/shared_frame.svg")
const BASIC_TYPE_MASK_TEXTURE = preload("res://Assets/basic_mask.svg")
const NEXUS_TYPE_MASK_TEXTURE = preload("res://Assets/nexus_mask.svg")
const SHARED_TYPE_MASK_TEXTURE = preload("res://Assets/shared_mask.svg")
const CARD_TEXTURE_FILTER: TextureFilter = CanvasItem.TEXTURE_FILTER_LINEAR
const CARD_ART_TEXTURE_FILTER: TextureFilter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
const CARD_SHIMMER_ENABLED: bool = false
const DRAG_TILT_FACTOR: float = 0.115
const DRAG_TILT_ROTATION_FACTOR: float = 0.0072
const DRAG_TILT_MAX: float = 46.0
const DRAG_TILT_SMOOTHING: float = 12.0
const DROP_TARGET_SCALE_IN_DURATION: float = 0.24
const DROP_TARGET_SCALE_OUT_DURATION: float = 0.12
const AMBIENT_MOTION_FLOAT_PIXELS: float = 5.5
const AMBIENT_MOTION_SIDE_PIXELS: float = 2.0
const AMBIENT_MOTION_ROTATION_DEGREES: float = 2.0
const AMBIENT_MOTION_X_TILT: float = 5.0
const AMBIENT_MOTION_Y_TILT: float = 6.0

signal drag_started(card_visual: CardVisual)
signal drag_moved(card_visual: CardVisual)
signal drag_released(card_visual: CardVisual)
signal burn_finished(card_visual: CardVisual)

@export var angle_x_max: float = 13.0
@export var angle_y_max: float = 13.0
@export var hover_scale: float = 1.11
@export var drag_scale: float = 1.05
@export var drop_target_scale: float = 0.5
@export var drop_target_drag_offset_factor: float = 0.45

@onready var shadow: TextureRect = $Shadow
@onready var card_face: TextureRect = $CardFace
@onready var type_frame: TextureRect = $TypeFrame
@onready var card_art: TextureRect = $CardArt
@onready var shimmer: ColorRect = $Shimmer
@onready var duration_label: Label = $DurationLabel
@onready var effect_icon_texture: TextureRect = $EffectIconTexture
@onready var effect_icon_label: Label = $EffectIconLabel
@onready var nexus_icon_label: Label = $NexusIconLabel
@onready var name_label: Label = $NameLabel
@onready var description_label: RichTextLabel = $DescriptionLabel
@onready var pattern_view: CardPatternView = $PatternView

var card: Card
var card_print: CardPrint
var face_material: ShaderMaterial
var card_art_material: ShaderMaterial
var shimmer_material: ShaderMaterial
var tween_hover: Tween
var tween_reset: Tween
var tween_move: Tween
var tween_burn: Tween
var normal_shadow_alpha: float = 0.0
var shimmer_time: float = 0.0
var last_position: Vector2 = Vector2.ZERO
var last_scale: Vector2 = Vector2.ONE
var last_rotation: float = 0.0
var last_x_rot: float = 0.0
var last_y_rot: float = 0.0
var home_position: Vector2 = Vector2.ZERO
var hand_index: int = -1
var owner_color: int = 0
var draggable: bool = true
var face_down: bool = false
var ambient_motion_enabled: bool = false
var ambient_motion_time: float = 0.0
var is_dragging: bool = false
var is_assigned: bool = false
var is_hovered: bool = false
var drop_target_active: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var normal_drag_offset: Vector2 = Vector2.ZERO
var last_drag_global_position: Vector2 = Vector2.ZERO
var drag_motion_velocity: Vector2 = Vector2.ZERO
var collection_owned: bool = true
var hover_raise_enabled: bool = true
var rest_scale: Vector2 = Vector2.ONE
var preview_alpha_enabled: bool = false
var preview_alpha: float = 1.0

func _ready() -> void:
	_apply_texture_filter()
	shadow.self_modulate.a = normal_shadow_alpha
	description_label.scroll_active = false
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size * 0.5
	face_material = card_face.material.duplicate() as ShaderMaterial
	card_face.material = face_material
	card_art_material = ShaderMaterial.new()
	card_art_material.shader = CARD_ART_MASK_SHADER
	card_art.material = card_art_material
	shimmer_material = shimmer.material.duplicate() as ShaderMaterial
	shimmer.material = shimmer_material
	shimmer.visible = _is_card_shimmer_enabled() && !face_down
	last_position = position
	last_scale = scale
	last_rotation = rotation
	last_x_rot = float(face_material.get_shader_parameter("x_rot"))
	last_y_rot = float(face_material.get_shader_parameter("y_rot"))
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	set_process(true)
	_apply_card()

func _apply_texture_filter() -> void:
	texture_filter = CARD_TEXTURE_FILTER
	shadow.texture_filter = CARD_TEXTURE_FILTER
	card_face.texture_filter = CARD_TEXTURE_FILTER
	type_frame.texture_filter = CARD_ART_TEXTURE_FILTER
	card_art.texture_filter = CARD_ART_TEXTURE_FILTER
	effect_icon_texture.texture_filter = CARD_TEXTURE_FILTER

func _process(_delta: float) -> void:
	if is_dragging:
		var target_global_position: Vector2 = get_global_mouse_position() - drag_offset
		update_drag_paper_motion(target_global_position, _delta)
		global_position = target_global_position
		drag_moved.emit(self)
	elif is_hovered:
		update_tilt_from_mouse()
	elif ambient_motion_enabled:
		update_ambient_motion(_delta)

	update_shimmer_time(_delta)

func update_shimmer_time(delta: float) -> void:
	if shimmer_material == null:
		return

	var moved: bool = !position.is_equal_approx(last_position)
	var scaled: bool = !scale.is_equal_approx(last_scale)
	var rotated: bool = !is_equal_approx(rotation, last_rotation)
	var current_x_rot: float = float(face_material.get_shader_parameter("x_rot"))
	var current_y_rot: float = float(face_material.get_shader_parameter("y_rot"))
	var tilted: bool = !is_equal_approx(current_x_rot, last_x_rot) || !is_equal_approx(current_y_rot, last_y_rot)
	if !face_down && visible && (moved || scaled || rotated || tilted):
		shimmer_time += delta
		shimmer_material.set_shader_parameter("shimmer_time", shimmer_time)
		_update_pattern_shimmer_space()
		pattern_view.set_shimmer_time(shimmer_time)

	last_position = position
	last_scale = scale
	last_rotation = rotation
	last_x_rot = current_x_rot
	last_y_rot = current_y_rot

func _update_pattern_shimmer_space() -> void:
	var canvas_transform: Transform2D = get_global_transform_with_canvas()
	var visual_size: Vector2 = Vector2(canvas_transform.x.length() * size.x, canvas_transform.y.length() * size.y)
	pattern_view.set_shimmer_space(canvas_transform.origin, visual_size)

func _input(event: InputEvent) -> void:
	if not is_dragging:
		return

	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and not mouse_button.pressed:
			finish_drag()
			accept_event()

func set_card(value: Card) -> void:
	card = value
	card_print = null
	if is_node_ready():
		_apply_card()

func set_card_print(value: CardPrint) -> void:
	card_print = value
	card = CardPrintLibrary.get_card_for_print(value)
	if is_node_ready():
		_apply_card()

func set_collection_owned(value: bool) -> void:
	collection_owned = value
	if is_node_ready():
		_apply_collection_state()

func set_hover_raise_enabled(value: bool) -> void:
	hover_raise_enabled = value

func set_rest_scale(value: Vector2) -> void:
	rest_scale = value
	if !is_dragging and !is_assigned:
		scale = rest_scale

func set_face_down(value: bool) -> void:
	face_down = value
	if is_node_ready():
		_apply_face_state()
		_apply_collection_state()

func set_ambient_motion_enabled(value: bool) -> void:
	ambient_motion_enabled = value
	ambient_motion_time = randf() * TAU
	if !value and is_node_ready():
		position = home_position
		rotation = 0.0
		if face_material:
			face_material.set_shader_parameter("x_rot", 0.0)
			face_material.set_shader_parameter("y_rot", 0.0)

func set_preview_alpha(value: float) -> void:
	preview_alpha_enabled = true
	preview_alpha = clampf(value, 0.0, 1.0)
	if is_node_ready():
		apply_preview_alpha()

func apply_preview_alpha() -> void:
	apply_preview_alpha_to_node(self, preview_alpha)

func apply_preview_alpha_to_node(node: Node, alpha: float) -> void:
	if node != shadow and node is CanvasItem:
		var canvas_item := node as CanvasItem
		var color: Color = canvas_item.self_modulate
		color.a = alpha
		canvas_item.self_modulate = color

	for child: Node in node.get_children():
		apply_preview_alpha_to_node(child, alpha)

func set_hand_context(new_owner_color: int, new_hand_index: int, new_home_position: Vector2) -> void:
	owner_color = new_owner_color
	hand_index = new_hand_index
	set_home_position(new_home_position, false)

func set_home_position(new_home_position: Vector2, animate: bool) -> void:
	home_position = new_home_position
	if is_dragging or is_assigned:
		return

	if animate:
		_kill_move_tween()
		tween_move = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween_move.tween_property(self, "position", home_position, 0.18)
	else:
		position = home_position

func set_drop_target_active(active: bool) -> void:
	if drop_target_active == active or is_assigned:
		return

	drop_target_active = active
	var target_scale: Vector2 = rest_scale * (drop_target_scale if active else drag_scale)
	if is_dragging:
		drag_offset = normal_drag_offset * (drop_target_drag_offset_factor if active else 1.0)
		global_position = get_global_mouse_position() - drag_offset
	_tween_scale(target_scale, DROP_TARGET_SCALE_IN_DURATION if active else DROP_TARGET_SCALE_OUT_DURATION)

func fly_home() -> void:
	is_dragging = false
	drop_target_active = false
	z_index = 0
	disabled = false
	_kill_move_tween()
	tween_move = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween_move.tween_property(self, "position", home_position, 0.26)
	tween_move.parallel().tween_property(self, "scale", rest_scale, 0.22)
	tween_move.parallel().tween_property(self, "rotation", 0.0, 0.22)
	tween_move.parallel().tween_property(face_material, "shader_parameter/x_rot", 0.0, 0.22)
	tween_move.parallel().tween_property(face_material, "shader_parameter/y_rot", 0.0, 0.22)
	tween_move.parallel().tween_property(shadow, "self_modulate:a", normal_shadow_alpha, 0.22)

func fly_from_global_position(start_global_position: Vector2) -> void:
	is_dragging = false
	drop_target_active = false
	_kill_hover_tweens()
	_kill_move_tween()

	global_position = start_global_position
	scale = rest_scale * 0.52
	rotation = deg_to_rad(-8.0 if owner_color == 1 else 8.0)
	z_index = 90
	shadow.self_modulate.a = 0.4

	tween_move = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween_move.tween_property(self, "position", home_position, 0.44)
	tween_move.parallel().tween_property(self, "scale", rest_scale, 0.38)
	tween_move.parallel().tween_property(self, "rotation", 0.0, 0.38)
	tween_move.parallel().tween_property(shadow, "self_modulate:a", normal_shadow_alpha, 0.38)
	tween_move.tween_callback(Callable(self, "_finish_draw_fly"))

func play_draw_pulse() -> void:
	_kill_hover_tweens()
	tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_hover.tween_property(self, "scale", rest_scale * 1.05, 0.08)
	tween_hover.tween_property(self, "scale", rest_scale * 0.96, 0.16)

func _finish_draw_fly() -> void:
	z_index = 0

func assign_and_hide() -> void:
	is_assigned = true
	is_dragging = false
	drop_target_active = false
	disabled = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func play_burn_away_and_free() -> void:
	is_assigned = true
	is_dragging = false
	is_hovered = false
	drop_target_active = false
	draggable = false
	disabled = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	face_down = false
	z_index = 980
	_kill_hover_tweens()
	_kill_move_tween()
	_kill_burn_tween()
	shadow.visible = false
	shadow.self_modulate.a = 0.0
	modulate.a = 1.0
	shimmer.visible = false

	await get_tree().process_frame
	if !is_inside_tree():
		return

	var burn_material: ShaderMaterial = ShaderMaterial.new()
	burn_material.shader = BURN_SHADER
	burn_material.set_shader_parameter("burn_progress", 0.0)
	burn_material.set_shader_parameter("seed", randf() * 1000.0)
	var burn_snapshot: TextureRect = await create_burn_snapshot_rect(burn_material)
	if burn_snapshot == null:
		card_face.material = burn_material

	tween_burn = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween_burn.tween_property(burn_material, "shader_parameter/burn_progress", 1.0, 1.15)
	tween_burn.parallel().tween_property(self, "position", position + Vector2(0.0, -28.0), 1.15)
	tween_burn.parallel().tween_property(self, "scale", scale * 0.82, 1.15)
	tween_burn.parallel().tween_property(self, "rotation", rotation + deg_to_rad(randf_range(-7.0, 7.0)), 1.15)
	tween_burn.tween_callback(Callable(self, "_finish_burn_away"))

func _finish_burn_away() -> void:
	burn_finished.emit(self)
	queue_free()

func create_burn_snapshot_rect(burn_material: ShaderMaterial) -> TextureRect:
	var snapshot_texture: Texture2D = await create_card_snapshot_texture()
	if snapshot_texture == null:
		return null

	set_card_content_visible(false)
	var snapshot_rect := TextureRect.new()
	snapshot_rect.name = "BurnSnapshot"
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
	snapshot_rect.material = burn_material
	snapshot_rect.z_index = 500
	add_child(snapshot_rect)
	return snapshot_rect

func create_card_snapshot_texture() -> Texture2D:
	var viewport_size := Vector2i(maxi(1, int(ceil(size.x))), maxi(1, int(ceil(size.y))))
	var snapshot_viewport := SubViewport.new()
	snapshot_viewport.transparent_bg = true
	snapshot_viewport.size = viewport_size
	snapshot_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	snapshot_viewport.disable_3d = true

	var snapshot_source: CardVisual = duplicate() as CardVisual
	if snapshot_source == null:
		snapshot_viewport.queue_free()
		return null
	snapshot_source.position = Vector2.ZERO
	snapshot_source.rotation = 0.0
	snapshot_source.scale = Vector2.ONE
	snapshot_source.is_dragging = false
	snapshot_source.is_hovered = false
	snapshot_source.ambient_motion_enabled = false
	snapshot_source.drop_target_active = false
	snapshot_source.modulate = Color.WHITE
	snapshot_source.self_modulate = Color.WHITE
	if snapshot_source is Control:
		var source_control := snapshot_source as Control
		source_control.offset_left = 0.0
		source_control.offset_top = 0.0
		source_control.offset_right = size.x
		source_control.offset_bottom = size.y
		source_control.mouse_filter = Control.MOUSE_FILTER_IGNORE

	snapshot_viewport.add_child(snapshot_source)
	add_child(snapshot_viewport)
	await get_tree().process_frame
	if !is_inside_tree() or !is_instance_valid(snapshot_viewport) or !is_instance_valid(snapshot_source):
		if is_instance_valid(snapshot_viewport):
			snapshot_viewport.queue_free()
		return null

	prepare_card_snapshot_source(snapshot_source)

	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if !is_inside_tree() or !is_instance_valid(snapshot_viewport):
		return null

	var viewport_texture: ViewportTexture = snapshot_viewport.get_texture()
	if viewport_texture == null:
		snapshot_viewport.queue_free()
		return null

	var image: Image = viewport_texture.get_image()
	snapshot_viewport.queue_free()
	if image == null or image.get_width() <= 0 or image.get_height() <= 0:
		return null

	return ImageTexture.create_from_image(image)

func prepare_card_snapshot_source(snapshot_source: CardVisual) -> void:
	if snapshot_source == null or !is_instance_valid(snapshot_source):
		return

	snapshot_source.is_dragging = false
	snapshot_source.is_hovered = false
	snapshot_source.is_assigned = false
	snapshot_source.drop_target_active = false
	snapshot_source.ambient_motion_enabled = false
	snapshot_source.preview_alpha_enabled = false
	snapshot_source.collection_owned = true
	snapshot_source.face_down = face_down
	snapshot_source.modulate = Color.WHITE
	snapshot_source.self_modulate = Color.WHITE
	snapshot_source.position = Vector2.ZERO
	snapshot_source.rotation = 0.0
	snapshot_source.scale = Vector2.ONE
	snapshot_source.z_index = 0
	if snapshot_source is Control:
		var source_control := snapshot_source as Control
		source_control.offset_left = 0.0
		source_control.offset_top = 0.0
		source_control.offset_right = size.x
		source_control.offset_bottom = size.y
		source_control.pivot_offset = size * 0.5

	if card_print != null:
		snapshot_source.set_card_print(card_print)
	else:
		snapshot_source.set_card(card)
	snapshot_source.set_face_down(face_down)
	snapshot_source.set_card_content_visible(true)
	snapshot_source.disabled = true
	snapshot_source.mouse_filter = Control.MOUSE_FILTER_IGNORE
	snapshot_source.shimmer.visible = false
	snapshot_source.shadow.visible = false
	snapshot_source.shadow.self_modulate.a = 0.0
	if snapshot_source.face_material != null:
		snapshot_source.face_material.set_shader_parameter("x_rot", 0.0)
		snapshot_source.face_material.set_shader_parameter("y_rot", 0.0)

func set_card_content_visible(value: bool) -> void:
	card_face.visible = value
	type_frame.visible = value && !face_down && card != null && type_frame.texture != null
	card_art.visible = value && !face_down && card_art.texture != null
	duration_label.visible = value && !face_down
	effect_icon_texture.visible = value && !face_down && card != null && card.has_effect() && card.effect_icon != null
	effect_icon_label.visible = value && !face_down && card != null && card.has_effect() && card.effect_icon == null
	nexus_icon_label.visible = false
	name_label.visible = value && !face_down
	description_label.visible = value && !face_down
	pattern_view.visible = value && !face_down

func _apply_card() -> void:
	if card == null:
		name_label.text = ""
		description_label.text = ""
		duration_label.text = ""
		effect_icon_texture.texture = null
		effect_icon_label.text = ""
		nexus_icon_label.visible = false
		pattern_view.set_card(null)
	else:
		name_label.text = card.card_name
		description_label.text = card.description.strip_edges()
		duration_label.text = "INF" if card.duration < 0 else str(card.duration)
		effect_icon_texture.texture = card.effect_icon
		effect_icon_label.text = CardEffect.get_effect_label(card.effect_type)
		pattern_view.set_card(card)

	_apply_art_state()
	_apply_face_state()
	_apply_collection_state()
	if preview_alpha_enabled:
		apply_preview_alpha()

func _apply_art_state() -> void:
	var type_frame_texture: Texture2D = _get_type_frame_texture()
	var type_mask_texture: Texture2D = _get_type_mask_texture()
	var art_texture: Texture2D = _get_card_art_texture()
	var card_mask_texture: Texture2D = _get_card_art_mask_texture()
	var has_card_art: bool = art_texture != null
	var has_card_mask: bool = card_mask_texture != null
	var uses_masked_art: bool = _uses_masked_card_art()

	type_frame.texture = type_frame_texture
	type_frame.visible = !face_down && card != null && type_frame_texture != null

	card_art.texture = art_texture if has_card_art else null
	card_art.visible = !face_down && has_card_art
	if uses_masked_art && card_art_material != null:
		card_art.material = card_art_material
		card_art_material.set_shader_parameter("type_mask_texture", type_mask_texture)
		card_art_material.set_shader_parameter("card_mask_texture", card_mask_texture if has_card_mask else type_mask_texture)
		card_art_material.set_shader_parameter("has_card_mask", has_card_mask)
	else:
		card_art.material = null

func _get_card_art_texture() -> Texture2D:
	if card_print != null && card_print.card_art != null:
		return card_print.card_art
	if card != null:
		return card.card_art
	return null

func _get_card_art_mask_texture() -> Texture2D:
	if card_print != null && card_print.card_art_mask != null:
		return card_print.card_art_mask
	if card_print != null && card_print.variant_id == "full_art":
		return CARD_FRONT_TEXTURE
	if card != null:
		return card.card_art_mask
	return null

func _uses_masked_card_art() -> bool:
	if card_print != null:
		return card_print.uses_masked_art()
	return true

func _is_card_shimmer_enabled() -> bool:
	if CARD_SHIMMER_ENABLED:
		return true
	return card_print != null && card_print.card_shimmer_enabled

func _get_type_frame_texture() -> Texture2D:
	if card != null && MoveRules.is_nexus_card(card):
		return NEXUS_TYPE_FRAME_TEXTURE
	if card != null && MoveRules.is_shared_card(card):
		return SHARED_TYPE_FRAME_TEXTURE

	return BASIC_TYPE_FRAME_TEXTURE

func _get_type_mask_texture() -> Texture2D:
	if card != null && MoveRules.is_nexus_card(card):
		return NEXUS_TYPE_MASK_TEXTURE
	if card != null && MoveRules.is_shared_card(card):
		return SHARED_TYPE_MASK_TEXTURE

	return BASIC_TYPE_MASK_TEXTURE

func _apply_face_state() -> void:
	var has_effect_icon: bool = card != null && card.has_effect()
	name_label.visible = !face_down
	description_label.visible = !face_down
	duration_label.visible = !face_down
	effect_icon_texture.visible = !face_down && has_effect_icon && card.effect_icon != null
	effect_icon_label.visible = !face_down && has_effect_icon && card.effect_icon == null
	nexus_icon_label.visible = false
	pattern_view.visible = !face_down
	shimmer.visible = _is_card_shimmer_enabled() && !face_down
	_apply_art_state()
	card_face.texture = CARD_BACK_TEXTURE if face_down else CARD_FRONT_TEXTURE
	card_face.material = null if face_down else face_material
	if face_down:
		rotation = 0.0
		scale = rest_scale

func _apply_collection_state() -> void:
	if collection_owned:
		card_face.texture = CARD_BACK_TEXTURE if face_down else CARD_FRONT_TEXTURE
		card_face.material = null if face_down else face_material
		shimmer.visible = _is_card_shimmer_enabled() && !face_down
		self_modulate = Color.WHITE
		disabled = false
		mouse_filter = Control.MOUSE_FILTER_STOP
		return

	var grayscale_material := ShaderMaterial.new()
	grayscale_material.shader = GRAYSCALE_SHADER
	grayscale_material.set_shader_parameter("strength", 1.0)
	grayscale_material.set_shader_parameter("darken", 0.24)
	card_face.texture = CARD_FRONT_TEXTURE
	card_face.material = grayscale_material
	self_modulate = Color(0.72, 0.72, 0.72, 1.0)
	shimmer.visible = false
	draggable = false
	disabled = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			accept_event()
			start_drag()
		return

	if not event is InputEventMouseMotion:
		return
	if is_dragging:
		return

	update_tilt_from_mouse()

func start_drag() -> void:
	if not draggable or is_assigned or face_down:
		return

	_kill_hover_tweens()
	_kill_move_tween()
	is_dragging = true
	is_hovered = false
	drop_target_active = false
	disabled = false
	move_to_front()
	z_index = 100
	drag_offset = get_global_mouse_position() - global_position
	normal_drag_offset = drag_offset
	last_drag_global_position = global_position
	drag_motion_velocity = Vector2.ZERO
	scale = rest_scale * drag_scale
	drag_started.emit(self)

func finish_drag() -> void:
	is_dragging = false
	drag_motion_velocity = Vector2.ZERO
	reset_drag_paper_motion()
	drag_released.emit(self)

func _on_mouse_entered() -> void:
	if is_dragging or is_assigned or face_down or !collection_owned:
		return

	is_hovered = true
	if hover_raise_enabled:
		move_to_front()
		z_index = 50
	if tween_reset and tween_reset.is_running():
		tween_reset.kill()
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween_hover.tween_property(self, "scale", rest_scale * hover_scale, 0.18)
	tween_hover.parallel().tween_property(shadow, "self_modulate:a", 0.34, 0.18)

func _on_mouse_exited() -> void:
	if is_dragging or is_assigned or face_down or !collection_owned:
		return

	is_hovered = false
	if hover_raise_enabled:
		z_index = 0
	reset_tilt_and_scale()

func update_tilt_from_mouse() -> void:
	if face_down or !collection_owned:
		return

	var mouse_pos: Vector2 = get_local_mouse_position()
	var x_ratio: float = clampf(mouse_pos.x / size.x, 0.0, 1.0)
	var y_ratio: float = clampf(mouse_pos.y / size.y, 0.0, 1.0)
	var y_rot: float = lerpf(-angle_y_max, angle_y_max, x_ratio)
	var x_rot: float = lerpf(angle_x_max, -angle_x_max, y_ratio)

	face_material.set_shader_parameter("x_rot", x_rot)
	face_material.set_shader_parameter("y_rot", y_rot)
	rotation = deg_to_rad(y_rot * 0.08)

func update_drag_paper_motion(target_global_position: Vector2, delta: float) -> void:
	if face_down or !collection_owned or face_material == null:
		return

	var safe_delta: float = maxf(delta, 0.001)
	var instant_velocity: Vector2 = (target_global_position - last_drag_global_position) / safe_delta
	var smoothing_weight: float = 1.0 - exp(-DRAG_TILT_SMOOTHING * safe_delta)
	drag_motion_velocity = drag_motion_velocity.lerp(instant_velocity, smoothing_weight)
	last_drag_global_position = target_global_position

	var local_velocity: Vector2 = drag_motion_velocity.rotated(-get_global_transform().get_rotation())
	var x_rot: float = clampf(-local_velocity.y * DRAG_TILT_FACTOR, -DRAG_TILT_MAX, DRAG_TILT_MAX)
	var y_rot: float = clampf(local_velocity.x * DRAG_TILT_FACTOR, -DRAG_TILT_MAX, DRAG_TILT_MAX)

	face_material.set_shader_parameter("x_rot", x_rot)
	face_material.set_shader_parameter("y_rot", y_rot)
	rotation = deg_to_rad(clampf(local_velocity.x * DRAG_TILT_ROTATION_FACTOR, -14.0, 14.0))

func reset_drag_paper_motion() -> void:
	if face_material == null:
		return

	var tween_drag_reset: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_drag_reset.tween_property(self, "rotation", 0.0, 0.16)
	tween_drag_reset.parallel().tween_property(face_material, "shader_parameter/x_rot", 0.0, 0.16)
	tween_drag_reset.parallel().tween_property(face_material, "shader_parameter/y_rot", 0.0, 0.16)

func update_ambient_motion(delta: float) -> void:
	if face_down or !collection_owned or face_material == null:
		return

	ambient_motion_time += delta
	var sway: float = sin(ambient_motion_time * 1.35)
	var side_sway: float = sin(ambient_motion_time * 1.05 + 1.3)
	var tilt: float = sin(ambient_motion_time * 1.85 + 0.7)
	position = home_position + Vector2(side_sway * AMBIENT_MOTION_SIDE_PIXELS, sway * AMBIENT_MOTION_FLOAT_PIXELS)
	rotation = deg_to_rad(sway * AMBIENT_MOTION_ROTATION_DEGREES)
	face_material.set_shader_parameter("x_rot", tilt * AMBIENT_MOTION_X_TILT)
	face_material.set_shader_parameter("y_rot", sway * AMBIENT_MOTION_Y_TILT)

func reset_tilt_and_scale() -> void:
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	if tween_reset and tween_reset.is_running():
		tween_reset.kill()
	tween_reset = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween_reset.tween_property(self, "scale", rest_scale, 0.24)
	tween_reset.parallel().tween_property(self, "rotation", 0.0, 0.24)
	tween_reset.parallel().tween_property(shadow, "self_modulate:a", normal_shadow_alpha, 0.24)
	if face_material:
		tween_reset.parallel().tween_property(face_material, "shader_parameter/x_rot", 0.0, 0.24)
		tween_reset.parallel().tween_property(face_material, "shader_parameter/y_rot", 0.0, 0.24)

func _tween_scale(target_scale: Vector2, duration: float) -> void:
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_hover.tween_property(self, "scale", target_scale, duration)

func _kill_hover_tweens() -> void:
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	if tween_reset and tween_reset.is_running():
		tween_reset.kill()

func _kill_move_tween() -> void:
	if tween_move and tween_move.is_running():
		tween_move.kill()

func _kill_burn_tween() -> void:
	if tween_burn and tween_burn.is_running():
		tween_burn.kill()
