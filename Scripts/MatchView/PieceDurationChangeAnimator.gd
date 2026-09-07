extends RefCounted

# A momentary, piece-anchored animation for whenever a piece's stamp duration
# changes -- currently played after a piece's own move consumes a turn of its
# duration (see PieceEffectFlowController), but written to be reusable for any
# future duration change (effects can raise or lower one or several pieces'
# duration at once). Unlike StampHoverPreviewController's duration display
# (one persistent, reused instance tied to whatever's hovered), each play()
# call builds a fully self-contained, self-cleaning set of nodes, so several
# of these can run concurrently for different pieces without conflict.

const DURATION_LABEL_FONT = preload("res://Fonts/OLDENGL.TTF")
const SOFT_DROP_SHADOW_SHADER = preload("res://Shaders/soft_drop_shadow.gdshader")
const DURATION_BUBBLE_TEXTURE = preload("res://Assets/dot.svg")
const DURATION_BUBBLE_SHADER = preload("res://Shaders/move_option_dot.gdshader")

var match_board
var canvas_layer: CanvasLayer

var render_size: Vector2 = Vector2(64, 48)
var vertical_offset: float = -46.0
var shadow_color: Color = Color(0.070588, 0.070588, 0.474510, 0.9)
var shadow_blur: float = 1.6
var outline_size: int = 3

var crossfade_duration: float = 0.7
var old_number_rise_distance: float = 10.0
var new_number_rise_distance: float = 16.0
var new_number_hold_duration: float = 0.6
var new_number_fade_out_duration: float = 0.5
var new_number_fade_out_rise_distance: float = 8.0

var bubble_count: int = 7
var bubble_reference_size: float = 22.0
var bubble_min_size_ratio: float = 0.14
var bubble_max_size_ratio: float = 0.28
var bubble_spawn_radius: float = 9.0
var bubble_edge_softness: float = 1.0
var bubble_glow_strength: float = 1.2
var bubble_pop_in_duration: float = 0.6
var bubble_drift_duration: float = 1.0
var bubble_fade_out_duration: float = 1.5
var bubble_drift_rise_distance: float = 6.0
var bubble_fade_rise_distance: float = 6.0

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	canvas_layer = config.get("canvas_layer", canvas_layer)
	render_size = config.get("render_size", render_size)
	vertical_offset = float(config.get("vertical_offset", vertical_offset))
	shadow_color = config.get("shadow_color", shadow_color)
	shadow_blur = float(config.get("shadow_blur", shadow_blur))
	outline_size = int(config.get("outline_size", outline_size))
	bubble_count = int(config.get("bubble_count", bubble_count))

# board_pos must still hold the piece whose duration changed (old_duration
# and new_duration are just numbers to show -- this doesn't read the piece
# itself). Pass -1 for an infinite duration on either side.
func play(board_pos: Vector2, old_duration: int, new_duration: int) -> void:
	if match_board == null or canvas_layer == null or !is_instance_valid(canvas_layer):
		return
	if !match_board.is_valid_position(board_pos):
		return

	var screen_position: Vector2 = match_board.get_board_position_screen_position(board_pos)
	var base_position: Vector2 = screen_position + Vector2(-render_size.x * 0.5, vertical_offset)

	_play_old_number(base_position, old_duration)
	_play_new_number(base_position, new_duration)
	for i in bubble_count:
		_spawn_bubble(base_position)

func _format_duration_text(duration: int) -> String:
	return "INF" if duration < 0 else str(duration)

func _build_number_instance(text: String) -> Dictionary:
	var viewport := SubViewport.new()
	canvas_layer.add_child(viewport)
	viewport.size = Vector2i(render_size)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true

	var label := Label.new()
	viewport.add_child(label)
	label.visible = true
	label.text = text
	label.size = render_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var label_settings := LabelSettings.new()
	label_settings.font = DURATION_LABEL_FONT
	label_settings.font_size = 22
	label_settings.font_color = Color(1.0, 1.0, 1.0)
	label_settings.outline_size = outline_size
	label_settings.outline_color = Color(shadow_color.r, shadow_color.g, shadow_color.b, 1.0)
	label.label_settings = label_settings

	var display := TextureRect.new()
	canvas_layer.add_child(display)
	display.size = render_size
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	display.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.z_index = 901
	display.texture = viewport.get_texture()

	var display_material := ShaderMaterial.new()
	display_material.shader = SOFT_DROP_SHADOW_SHADER
	display_material.set_shader_parameter("shadow_color", shadow_color)
	display_material.set_shader_parameter("blur_std", shadow_blur)
	display_material.set_shader_parameter("control_rect_size", render_size)
	display.material = display_material

	return {"viewport": viewport, "label": label, "display": display}

func _free_number_instance(instance: Dictionary) -> void:
	var viewport: SubViewport = instance.get("viewport") as SubViewport
	var display: TextureRect = instance.get("display") as TextureRect
	if display != null and is_instance_valid(display):
		display.queue_free()
	if viewport != null and is_instance_valid(viewport):
		viewport.queue_free()

# The outgoing value: sits at rest, then drifts up a little while fading out
# -- it's leaving, not settling anywhere.
func _play_old_number(base_position: Vector2, old_duration: int) -> void:
	var instance: Dictionary = _build_number_instance(_format_duration_text(old_duration))
	var display: TextureRect = instance["display"]
	display.global_position = base_position

	var tween: Tween = display.create_tween()
	tween.tween_property(display, "position:y", display.position.y - old_number_rise_distance, crossfade_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(display, "modulate:a", 0.0, crossfade_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(Callable(self, "_free_number_instance").bind(instance))

# The incoming value: rises up from below into the resting spot while fading
# in (in parallel with the old one leaving), holds there so it's actually
# readable, then fades out in place -- the whole thing is a momentary beat,
# not a persistent marker.
func _play_new_number(base_position: Vector2, new_duration: int) -> void:
	var instance: Dictionary = _build_number_instance(_format_duration_text(new_duration))
	var display: TextureRect = instance["display"]
	display.global_position = base_position + Vector2(0.0, new_number_rise_distance)
	display.modulate.a = 0.0

	var tween: Tween = display.create_tween()
	tween.tween_property(display, "position:y", base_position.y, crossfade_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(display, "modulate:a", 1.0, crossfade_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(new_number_hold_duration)
	tween.tween_property(display, "position:y", base_position.y - new_number_fade_out_rise_distance, new_number_fade_out_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(display, "modulate:a", 0.0, new_number_fade_out_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(Callable(self, "_free_number_instance").bind(instance))

# Same look and per-bubble lifecycle as StampHoverPreviewController's hover
# bubbles (see that file for why each piece here -- the shader choice, the
# three-phase appear/drift/fade timing -- is the way it is); the only
# difference is that here all of them pop at once, right at the start,
# instead of building up gradually over a held hover.
func _spawn_bubble(base_position: Vector2) -> void:
	var bubble := TextureRect.new()
	canvas_layer.add_child(bubble)
	bubble.texture = DURATION_BUBBLE_TEXTURE
	bubble.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bubble.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bubble.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.z_index = 900

	var diameter: float = bubble_reference_size * randf_range(bubble_min_size_ratio, bubble_max_size_ratio)
	bubble.size = Vector2.ONE * diameter
	bubble.pivot_offset = bubble.size * 0.5

	var bubble_material := ShaderMaterial.new()
	bubble_material.shader = DURATION_BUBBLE_SHADER
	bubble_material.set_shader_parameter("color", shadow_color)
	bubble_material.set_shader_parameter("edge_softness", bubble_edge_softness)
	bubble_material.set_shader_parameter("glow_strength", bubble_glow_strength)
	bubble_material.set_shader_parameter("pulse_strength", 0.0)
	bubble.material = bubble_material

	var display_center: Vector2 = base_position + render_size * 0.5
	var angle: float = randf_range(0.0, TAU)
	var dist: float = randf_range(0.0, bubble_spawn_radius)
	bubble.global_position = display_center + Vector2(cos(angle), sin(angle)) * dist - bubble.size * 0.5

	bubble.scale = Vector2.ZERO
	bubble.modulate.a = 0.0
	var base_y: float = bubble.position.y

	var tween: Tween = bubble.create_tween()
	tween.tween_property(bubble, "scale", Vector2.ONE, bubble_pop_in_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(bubble, "modulate:a", 1.0, bubble_pop_in_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(bubble, "position:y", base_y - bubble_drift_rise_distance, bubble_drift_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(bubble, "position:y", base_y - bubble_drift_rise_distance - bubble_fade_rise_distance, bubble_fade_out_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(bubble, "modulate:a", 0.0, bubble_fade_out_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(Callable(bubble, "queue_free"))
