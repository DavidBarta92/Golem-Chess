extends RefCounted

var canvas_layer: CanvasLayer
var tween_owner: Node

var deck_count_label_size: Vector2 = Vector2(88, 28)
var deck_count_label_gap: float = 8.0
var deck_counter_background_size: Vector2 = Vector2(38, 38)
var deck_counter_digit_size: Vector2 = Vector2(38, 38)
var deck_counter_digit_gap: float = 0.0
var deck_counter_frame_size: Vector2 = Vector2(82, 42)
var deck_counter_content_offset: Vector2 = Vector2(3, 2)
var deck_counter_size: Vector2 = Vector2(82, 42)
var deck_counter_roll_duration: float = 0.34
var deck_counter_motion_blur: float = 1.0
var deck_counter_offset: Vector2 = Vector2.ZERO
var deck_counter_z_index: int = 952

var deck_counter_digits_texture: Texture2D
var deck_counter_background_texture: Texture2D
var deck_counter_frame_texture: Texture2D
var deck_counter_shadow_texture: Texture2D
var deck_counter_digit_shader: Shader

var deck_visual_provider: Callable
var card_deck_count_provider: Callable
var game_over_provider: Callable

var deck_count_label: Label
var deck_counter_containers: Dictionary = {}
var deck_counter_digit_nodes: Dictionary = {}
var deck_counter_digit_materials: Dictionary = {}
var deck_counter_values: Dictionary = {
	1: -1,
	-1: -1,
}
var deck_counter_roll_values: Dictionary = {}
var deck_counter_tweens: Dictionary = {}

func configure(config: Dictionary) -> void:
	canvas_layer = config.get("canvas_layer", canvas_layer)
	tween_owner = config.get("tween_owner", tween_owner)
	deck_count_label_size = config.get("deck_count_label_size", deck_count_label_size)
	deck_count_label_gap = float(config.get("deck_count_label_gap", deck_count_label_gap))
	deck_counter_background_size = config.get("deck_counter_background_size", deck_counter_background_size)
	deck_counter_digit_size = config.get("deck_counter_digit_size", deck_counter_digit_size)
	deck_counter_digit_gap = float(config.get("deck_counter_digit_gap", deck_counter_digit_gap))
	deck_counter_frame_size = config.get("deck_counter_frame_size", deck_counter_frame_size)
	deck_counter_content_offset = config.get("deck_counter_content_offset", deck_counter_content_offset)
	deck_counter_size = config.get("deck_counter_size", deck_counter_size)
	deck_counter_roll_duration = float(config.get("deck_counter_roll_duration", deck_counter_roll_duration))
	deck_counter_motion_blur = float(config.get("deck_counter_motion_blur", deck_counter_motion_blur))
	deck_counter_offset = config.get("deck_counter_offset", deck_counter_offset)
	deck_counter_z_index = int(config.get("deck_counter_z_index", deck_counter_z_index))
	deck_counter_digits_texture = config.get("deck_counter_digits_texture", deck_counter_digits_texture)
	deck_counter_background_texture = config.get("deck_counter_background_texture", deck_counter_background_texture)
	deck_counter_frame_texture = config.get("deck_counter_frame_texture", deck_counter_frame_texture)
	deck_counter_shadow_texture = config.get("deck_counter_shadow_texture", deck_counter_shadow_texture)
	deck_counter_digit_shader = config.get("deck_counter_digit_shader", deck_counter_digit_shader)
	deck_visual_provider = config.get("deck_visual_provider", deck_visual_provider)
	card_deck_count_provider = config.get("card_deck_count_provider", card_deck_count_provider)
	game_over_provider = config.get("game_over_provider", game_over_provider)

func create_deck_count_ui() -> void:
	if canvas_layer == null or !is_instance_valid(canvas_layer):
		return

	deck_count_label = Label.new()
	canvas_layer.add_child(deck_count_label)
	deck_count_label.visible = false
	deck_count_label.size = deck_count_label_size
	deck_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	deck_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_count_label.z_index = 950

	var label_settings := LabelSettings.new()
	label_settings.font_size = 18
	label_settings.font_color = Color(1.0, 1.0, 1.0)
	label_settings.outline_size = 4
	label_settings.outline_color = Color(0.0, 0.0, 0.0)
	deck_count_label.label_settings = label_settings

func create_deck_counter_ui() -> void:
	for owner_color in [1, -1]:
		var counter_container := create_digit_counter_container("DeckCounter%d" % owner_color, owner_color)
		deck_counter_containers[owner_color] = counter_container

	update_deck_counter_ui(false)

func create_digit_counter_container(counter_name: String, digit_owner_key: int) -> Control:
	if canvas_layer == null or !is_instance_valid(canvas_layer):
		return null

	var counter_container := Control.new()
	canvas_layer.add_child(counter_container)
	counter_container.name = counter_name
	counter_container.visible = false
	counter_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter_container.size = deck_counter_size
	counter_container.z_index = deck_counter_z_index

	var frame_rect := TextureRect.new()
	counter_container.add_child(frame_rect)
	frame_rect.name = "Frame"
	frame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_rect.texture = deck_counter_frame_texture
	frame_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	frame_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame_rect.stretch_mode = TextureRect.STRETCH_SCALE
	frame_rect.size = deck_counter_frame_size
	frame_rect.position = Vector2.ZERO
	frame_rect.z_index = 0

	var digit_nodes: Array = []
	for digit_index in range(2):
		var digit_position := deck_counter_content_offset + Vector2(digit_index * (deck_counter_background_size.x + deck_counter_digit_gap), 0.0)

		var background_rect := TextureRect.new()
		counter_container.add_child(background_rect)
		background_rect.name = "Background%d" % digit_index
		background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background_rect.texture = deck_counter_background_texture
		background_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background_rect.stretch_mode = TextureRect.STRETCH_SCALE
		background_rect.size = deck_counter_background_size
		background_rect.position = digit_position
		background_rect.z_index = 1

		var digit_rect := TextureRect.new()
		counter_container.add_child(digit_rect)
		digit_rect.name = "Digit%d" % digit_index
		digit_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		digit_rect.texture = deck_counter_digits_texture
		digit_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		digit_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		digit_rect.stretch_mode = TextureRect.STRETCH_SCALE
		digit_rect.size = deck_counter_digit_size
		digit_rect.position = digit_position
		digit_rect.z_index = 2

		var digit_material := ShaderMaterial.new()
		digit_material.shader = deck_counter_digit_shader
		digit_material.set_shader_parameter("digit_atlas", deck_counter_digits_texture)
		digit_material.set_shader_parameter("roll_value", 0.0)
		digit_material.set_shader_parameter("roll_direction", 1.0)
		digit_material.set_shader_parameter("motion_blur", 0.0)
		digit_material.set_shader_parameter("frame_count", 10.0)
		digit_rect.material = digit_material

		var digit_key: String = get_deck_counter_digit_key(digit_owner_key, digit_index)
		deck_counter_digit_materials[digit_key] = digit_material
		deck_counter_roll_values[digit_key] = 0.0
		digit_nodes.append(digit_rect)

		var shadow_rect := TextureRect.new()
		counter_container.add_child(shadow_rect)
		shadow_rect.name = "Shadow%d" % digit_index
		shadow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow_rect.texture = deck_counter_shadow_texture
		shadow_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		shadow_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shadow_rect.stretch_mode = TextureRect.STRETCH_SCALE
		shadow_rect.size = deck_counter_background_size
		shadow_rect.position = digit_position
		shadow_rect.z_index = 3

	deck_counter_digit_nodes[digit_owner_key] = digit_nodes
	return counter_container

func update_deck_counter_ui(animate: bool = true) -> void:
	for owner_color in [1, -1]:
		var counter_container: Control = deck_counter_containers.get(owner_color, null) as Control
		if counter_container == null:
			continue

		var deck_visual: CardVisual = get_deck_visual(owner_color)
		if is_game_over() or deck_visual == null or !is_instance_valid(deck_visual) or !deck_visual.visible:
			counter_container.visible = false
			continue

		var deck_rect: Rect2 = deck_visual.get_global_rect()
		counter_container.global_position = deck_rect.get_center() - deck_counter_size * 0.5 + deck_counter_offset
		counter_container.visible = true
		set_deck_counter_value(owner_color, get_card_deck_count(owner_color), animate)

func set_deck_counter_value(owner_color: int, count: int, animate: bool) -> void:
	var safe_count: int = clampi(count, 0, 99)
	var previous_count: int = int(deck_counter_values.get(owner_color, -1))
	if previous_count == safe_count:
		return

	deck_counter_values[owner_color] = safe_count
	var should_animate: bool = animate and previous_count >= 0
	var direction: int = 1
	if should_animate and safe_count < previous_count:
		direction = -1

	var tens_digit: int = floori(float(safe_count) / 10.0)
	var ones_digit: int = safe_count % 10
	update_deck_counter_digit(owner_color, 0, tens_digit, direction, should_animate)
	update_deck_counter_digit(owner_color, 1, ones_digit, direction, should_animate)

func update_deck_counter_digit(owner_color: int, digit_index: int, target_digit: int, direction: int, animate: bool) -> void:
	var digit_key: String = get_deck_counter_digit_key(owner_color, digit_index)
	var digit_material: ShaderMaterial = deck_counter_digit_materials.get(digit_key, null) as ShaderMaterial
	if digit_material == null:
		return

	var previous_tween: Tween = deck_counter_tweens.get(digit_key, null) as Tween
	if previous_tween != null:
		previous_tween.kill()
		deck_counter_tweens.erase(digit_key)

	var current_roll: float = float(deck_counter_roll_values.get(digit_key, float(target_digit)))
	var target_roll: float = float(target_digit)
	if animate:
		target_roll = get_deck_counter_target_roll(current_roll, target_digit, direction)

	deck_counter_roll_values[digit_key] = target_roll
	digit_material.set_shader_parameter("roll_direction", float(direction))
	if !animate or is_equal_approx(current_roll, target_roll):
		digit_material.set_shader_parameter("roll_value", target_roll)
		digit_material.set_shader_parameter("motion_blur", 0.0)
		return

	digit_material.set_shader_parameter("motion_blur", deck_counter_motion_blur)
	var tween: Tween = null
	if tween_owner != null and is_instance_valid(tween_owner):
		tween = tween_owner.create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	if tween == null:
		digit_material.set_shader_parameter("roll_value", target_roll)
		digit_material.set_shader_parameter("motion_blur", 0.0)
		return

	deck_counter_tweens[digit_key] = tween
	tween.tween_property(digit_material, "shader_parameter/roll_value", target_roll, deck_counter_roll_duration)
	tween.parallel().tween_property(digit_material, "shader_parameter/motion_blur", 0.0, deck_counter_roll_duration)
	tween.finished.connect(func():
		if deck_counter_tweens.get(digit_key, null) == tween:
			deck_counter_tweens.erase(digit_key)
		if is_instance_valid(digit_material):
			digit_material.set_shader_parameter("roll_value", target_roll)
			digit_material.set_shader_parameter("motion_blur", 0.0)
	)

func update_deck_count_hover() -> void:
	if deck_count_label == null:
		return

	var hovered_deck_color: int = get_hovered_deck_color()
	if hovered_deck_color == 0:
		deck_count_label.visible = false
		return

	var deck_visual: CardVisual = get_deck_visual(hovered_deck_color)
	if deck_visual == null or !is_instance_valid(deck_visual):
		deck_count_label.visible = false
		return

	var deck_rect: Rect2 = deck_visual.get_global_rect()
	var label_y: float = deck_rect.position.y - deck_count_label.size.y - deck_count_label_gap
	if label_y < 0.0:
		label_y = deck_rect.end.y + deck_count_label_gap

	deck_count_label.text = "%d cards" % get_card_deck_count(hovered_deck_color)
	deck_count_label.global_position = Vector2(
		deck_rect.get_center().x - deck_count_label.size.x * 0.5,
		label_y
	)
	deck_count_label.visible = true

func get_hovered_deck_color() -> int:
	for owner_color in [1, -1]:
		if is_mouse_over_deck(owner_color):
			return owner_color
	return 0

func is_mouse_over_deck(owner_color: int) -> bool:
	var deck_visual: CardVisual = get_deck_visual(owner_color)
	if deck_visual == null or !is_instance_valid(deck_visual) or !deck_visual.visible:
		return false
	if canvas_layer == null or !is_instance_valid(canvas_layer):
		return false
	return deck_visual.get_global_rect().has_point(canvas_layer.get_viewport().get_mouse_position())

func get_deck_counter_target_roll(current_roll: float, target_digit: int, direction: int) -> float:
	var current_digit: int = positive_mod_int(roundi(current_roll), 10)
	if direction >= 0:
		var forward_steps: int = positive_mod_int(target_digit - current_digit, 10)
		return current_roll + float(forward_steps)

	var backward_steps: int = positive_mod_int(current_digit - target_digit, 10)
	return current_roll - float(backward_steps)

func get_deck_counter_digit_key(owner_color: int, digit_index: int) -> String:
	return "%d_%d" % [owner_color, digit_index]

func positive_mod_int(value: int, divisor: int) -> int:
	var result: int = value % divisor
	if result < 0:
		result += divisor
	return result

func get_deck_visual(owner_color: int) -> CardVisual:
	if deck_visual_provider.is_valid():
		return deck_visual_provider.call(owner_color) as CardVisual
	return null

func get_card_deck_count(owner_color: int) -> int:
	if card_deck_count_provider.is_valid():
		return int(card_deck_count_provider.call(owner_color))
	return 0

func is_game_over() -> bool:
	if game_over_provider.is_valid():
		return bool(game_over_provider.call())
	return false
