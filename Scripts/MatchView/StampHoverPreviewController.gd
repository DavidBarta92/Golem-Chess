extends RefCounted

const DURATION_LABEL_FONT = preload("res://Fonts/OLDENGL.TTF")
const SOFT_DROP_SHADOW_SHADER = preload("res://Shaders/soft_drop_shadow.gdshader")
const DURATION_BUBBLE_TEXTURE = preload("res://Assets/dot.svg")
# A procedural, UV-distance-based soft circle (already used for the board's
# move-option dots) rather than SOFT_DROP_SHADOW_SHADER: that shader blurs by
# sampling neighboring texels of the bound texture, so at the bubbles' tiny
# final size (a couple of screen pixels) the blur radius -- fixed as a
# fraction of dot.svg's 64px source -- collapses to a sub-pixel amount and
# reads as no blur at all. This shader instead computes the falloff purely
# from UV, so it looks identically soft at any display size.
const DURATION_BUBBLE_SHADER = preload("res://Shaders/move_option_dot.gdshader")

var canvas_layer: CanvasLayer
var stamp_visual_scene: PackedScene
var stamp_ui_size: Vector2 = Vector2(168.7, 229)
var hover_stamp_margin: float = 24.0
var hover_stamp_extra_left_offset: float = 16.0
var hover_stamp_preview_scale: float = 0.82
var hover_stamp_vertical_offset: float = 54.0
var hover_stamp_rotation_degrees: float = -4.0
var hover_piece_preview_size: Vector2 = Vector2(188, 224)
var hover_piece_preview_vertical_offset: float = -78.0
var description_text_margin: Vector2 = Vector2(22, 30)
var description_panel_gap: float = 8.0
var description_panel_width: float = 271.6
var description_panel_height: float = 229.0
var duration_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.9)
var duration_shadow_blur: float = 0.6
var duration_outline_size: int = 1
var duration_render_size: Vector2 = Vector2(64, 48)
var duration_bubble_edge_softness: float = 1.0
var duration_bubble_glow_strength: float = 1.2
var duration_bubble_reference_size: float = 22.0
var duration_bubble_min_size_ratio: float = 0.14
var duration_bubble_max_size_ratio: float = 0.28
var duration_bubble_spawn_radius: float = 9.0
var duration_bubble_initial_spawn_count: int = 4
var duration_bubble_pop_in_duration: float = 0.6
var duration_bubble_drift_duration: float = 1.0
var duration_bubble_fade_out_duration: float = 1.5
var duration_bubble_drift_rise_distance: float = 6.0
var duration_bubble_fade_rise_distance: float = 6.0
var duration_bubble_spawn_intervals: Array[float] = [0.6, 0.85, 0.65, 0.8]

var hover_stamp_group: Control
var hover_stamp_preview: StampVisual
var hover_piece_preview: TextureRect
var hover_duration_label: Label
var duration_render_viewport: SubViewport
var hover_duration_display: TextureRect
# A second, independent render instance used only to fade out whatever the
# primary (hover_duration_label/hover_duration_display) was just showing --
# see hide(). Keeping the primary always instant-show/instant-hide means
# switching straight from one piece to another can show the new number right
# away without cutting off the old one's fade.
var _duration_overflow_viewport: SubViewport
var _duration_overflow_label: Label
var _duration_overflow_display: TextureRect
var hover_description_panel: Control
var hover_description_label: RichTextLabel
var description_icon_font_size: int = 16
var hover_fade_in_duration: float = 0.16
var duration_fade_out_duration: float = 0.35

var is_reveal_blocked_provider: Callable

var _stamp_group_fade_tween: Tween
var _piece_preview_fade_tween: Tween
var _description_panel_fade_tween: Tween
var _duration_bubble_spawn_tween: Tween
var _duration_overflow_fade_tween: Tween
var _duration_bubble_needs_initial_burst: bool = false

func configure(config: Dictionary) -> void:
	canvas_layer = config.get("canvas_layer", canvas_layer)
	stamp_visual_scene = config.get("stamp_visual_scene", stamp_visual_scene)
	stamp_ui_size = config.get("stamp_ui_size", stamp_ui_size)
	hover_stamp_margin = float(config.get("hover_stamp_margin", hover_stamp_margin))
	hover_stamp_extra_left_offset = float(config.get("hover_stamp_extra_left_offset", hover_stamp_extra_left_offset))
	hover_stamp_preview_scale = float(config.get("hover_stamp_preview_scale", hover_stamp_preview_scale))
	hover_stamp_vertical_offset = float(config.get("hover_stamp_vertical_offset", hover_stamp_vertical_offset))
	hover_stamp_rotation_degrees = float(config.get("hover_stamp_rotation_degrees", hover_stamp_rotation_degrees))
	hover_piece_preview_size = config.get("hover_piece_preview_size", hover_piece_preview_size)
	hover_piece_preview_vertical_offset = float(config.get("hover_piece_preview_vertical_offset", hover_piece_preview_vertical_offset))
	description_text_margin = config.get("description_text_margin", description_text_margin)
	description_panel_gap = float(config.get("description_panel_gap", description_panel_gap))
	description_panel_width = float(config.get("description_panel_width", description_panel_width))
	description_panel_height = float(config.get("description_panel_height", description_panel_height))
	duration_shadow_color = config.get("duration_shadow_color", duration_shadow_color)
	duration_shadow_blur = float(config.get("duration_shadow_blur", duration_shadow_blur))
	duration_outline_size = int(config.get("duration_outline_size", duration_outline_size))
	is_reveal_blocked_provider = config.get("is_reveal_blocked_provider", is_reveal_blocked_provider)

func is_reveal_blocked() -> bool:
	if is_reveal_blocked_provider.is_valid():
		return bool(is_reveal_blocked_provider.call())
	return false

func create_ui() -> void:
	if canvas_layer == null or !is_instance_valid(canvas_layer):
		return
	if hover_stamp_group != null and is_instance_valid(hover_stamp_group):
		return

	hover_stamp_group = Control.new()
	canvas_layer.add_child(hover_stamp_group)
	hover_stamp_group.name = "HoverStampGroup"
	hover_stamp_group.visible = false
	hover_stamp_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_stamp_group.anchor_left = 1.0
	hover_stamp_group.anchor_right = 1.0
	hover_stamp_group.anchor_top = 0.5
	hover_stamp_group.anchor_bottom = 0.5
	hover_stamp_group.offset_right = -hover_stamp_margin - hover_stamp_extra_left_offset
	hover_stamp_group.offset_left = hover_stamp_group.offset_right - stamp_ui_size.x
	hover_stamp_group.offset_top = -stamp_ui_size.y * 0.5 + hover_stamp_vertical_offset
	hover_stamp_group.offset_bottom = hover_stamp_group.offset_top + stamp_ui_size.y
	hover_stamp_group.pivot_offset = stamp_ui_size * 0.5
	hover_stamp_group.scale = Vector2.ONE * hover_stamp_preview_scale
	hover_stamp_group.rotation_degrees = hover_stamp_rotation_degrees
	hover_stamp_group.z_index = 900

	create_description_panel()
	create_piece_preview()
	create_stamp_preview()
	create_duration_label()

func create_description_panel() -> void:
	hover_description_panel = Control.new()
	canvas_layer.add_child(hover_description_panel)
	hover_description_panel.name = "HoverDescriptionPanel"
	hover_description_panel.visible = false
	hover_description_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_description_panel.anchor_left = 1.0
	hover_description_panel.anchor_right = 1.0
	hover_description_panel.anchor_top = 0.5
	hover_description_panel.anchor_bottom = 0.5
	hover_description_panel.offset_right = -hover_stamp_margin - stamp_ui_size.x - description_panel_gap
	hover_description_panel.offset_left = hover_description_panel.offset_right - description_panel_width
	hover_description_panel.offset_top = -description_panel_height * 0.5 + hover_stamp_vertical_offset
	hover_description_panel.offset_bottom = description_panel_height * 0.5 + hover_stamp_vertical_offset
	hover_description_panel.z_index = 899

	hover_description_label = RichTextLabel.new()
	hover_description_panel.add_child(hover_description_label)
	hover_description_label.bbcode_enabled = true
	hover_description_label.fit_content = false
	hover_description_label.scroll_active = false
	hover_description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_description_label.anchor_left = 0.0
	hover_description_label.anchor_right = 1.0
	hover_description_label.anchor_top = 0.0
	hover_description_label.anchor_bottom = 1.0
	hover_description_label.offset_left = description_text_margin.x
	hover_description_label.offset_right = -description_text_margin.x
	hover_description_label.offset_top = description_text_margin.y
	hover_description_label.offset_bottom = -description_text_margin.y
	hover_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hover_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hover_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hover_description_label.add_theme_font_size_override("normal_font_size", description_icon_font_size)
	hover_description_label.add_theme_color_override("default_color", UiPalette.INK)
	hover_description_label.add_theme_color_override("font_shadow_color", Color(1.0, 0.96, 0.82, 0.48))
	hover_description_label.add_theme_constant_override("shadow_offset_x", 1)
	hover_description_label.add_theme_constant_override("shadow_offset_y", 1)

func create_piece_preview() -> void:
	hover_piece_preview = TextureRect.new()
	canvas_layer.add_child(hover_piece_preview)
	hover_piece_preview.visible = false
	hover_piece_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_piece_preview.anchor_left = 1.0
	hover_piece_preview.anchor_right = 1.0
	hover_piece_preview.anchor_top = 0.5
	hover_piece_preview.anchor_bottom = 0.5
	hover_piece_preview.offset_left = -hover_piece_preview_size.x - hover_stamp_margin
	hover_piece_preview.offset_right = -hover_stamp_margin
	hover_piece_preview.offset_top = -hover_piece_preview_size.y * 0.5 + hover_piece_preview_vertical_offset
	hover_piece_preview.offset_bottom = hover_piece_preview_size.y * 0.5 + hover_piece_preview_vertical_offset
	hover_piece_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hover_piece_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hover_piece_preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	hover_piece_preview.z_index = 899

func create_stamp_preview() -> void:
	hover_stamp_preview = stamp_visual_scene.instantiate() as StampVisual if stamp_visual_scene != null else null
	if hover_stamp_preview == null:
		return

	hover_stamp_group.add_child(hover_stamp_preview)
	hover_stamp_preview.visible = false
	hover_stamp_preview.draggable = false
	hover_stamp_preview.disabled = true
	hover_stamp_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_stamp_preview.anchor_left = 0.0
	hover_stamp_preview.anchor_right = 0.0
	hover_stamp_preview.anchor_top = 0.0
	hover_stamp_preview.anchor_bottom = 0.0
	hover_stamp_preview.offset_left = 0.0
	hover_stamp_preview.offset_right = stamp_ui_size.x
	hover_stamp_preview.offset_top = 0.0
	hover_stamp_preview.offset_bottom = stamp_ui_size.y
	hover_stamp_preview.set_rest_scale(Vector2.ONE)
	hover_stamp_preview.rotation_degrees = 0.0
	hover_stamp_preview.z_index = 1

func create_duration_label() -> void:
	# A canvas_item shader can't blur a Label's own glyphs directly: each
	# glyph is a separate small quad cut from a shared font atlas, so there's
	# no single rect size to hand the shader that would be correct for every
	# glyph at once (see SOFT_DROP_SHADOW_SHADER's control_rect_size). So the
	# text is instead rendered plain into an offscreen SubViewport, and an
	# ordinary TextureRect -- exactly like the bubbles below -- shows that
	# render with the same shader applied to the whole thing at once, blurred
	# edges included.
	var primary: Dictionary = _build_duration_render_instance()
	duration_render_viewport = primary["viewport"]
	hover_duration_label = primary["label"]
	hover_duration_display = primary["display"]

	var overflow: Dictionary = _build_duration_render_instance()
	_duration_overflow_viewport = overflow["viewport"]
	_duration_overflow_label = overflow["label"]
	_duration_overflow_display = overflow["display"]

func _build_duration_render_instance() -> Dictionary:
	var viewport := SubViewport.new()
	canvas_layer.add_child(viewport)
	viewport.size = Vector2i(duration_render_size)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true

	var label := Label.new()
	viewport.add_child(label)
	label.visible = false
	label.size = duration_render_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var label_settings: LabelSettings = LabelSettings.new()
	label_settings.font = DURATION_LABEL_FONT
	label_settings.font_size = 22
	label_settings.font_color = Color(1.0, 1.0, 1.0)
	label_settings.outline_size = duration_outline_size
	label_settings.outline_color = Color(duration_shadow_color.r, duration_shadow_color.g, duration_shadow_color.b, 1.0)
	label.label_settings = label_settings

	var display := TextureRect.new()
	canvas_layer.add_child(display)
	display.visible = false
	display.size = duration_render_size
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	display.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.z_index = 901
	display.texture = viewport.get_texture()

	var display_material := ShaderMaterial.new()
	display_material.shader = SOFT_DROP_SHADOW_SHADER
	display_material.set_shader_parameter("shadow_color", duration_shadow_color)
	display_material.set_shader_parameter("blur_std", duration_shadow_blur)
	display_material.set_shader_parameter("control_rect_size", duration_render_size)
	display.material = display_material

	return {"viewport": viewport, "label": label, "display": display}

func show_piece_details(preview_stamp: Stamp, preview_texture: Texture2D, duration_text: String) -> void:
	if is_reveal_blocked():
		return

	show_stamp_only(preview_stamp)
	show_piece_preview(preview_texture)
	if hover_duration_label != null and hover_duration_display != null:
		# The primary display is always instant show/hide -- any fade-out
		# plays on the separate overflow instance instead (see hide()), so
		# there's never anything here to interrupt or reset.
		hover_duration_label.text = duration_text
		hover_duration_label.visible = true
		hover_duration_display.visible = true
		start_duration_bubbles()

func show_stamp_only(preview_stamp: Stamp) -> void:
	if preview_stamp == null or hover_stamp_preview == null or is_reveal_blocked():
		return

	hover_stamp_preview.set_stamp(preview_stamp)
	hover_stamp_preview.set_face_down(false)
	hover_stamp_preview.disabled = true
	hover_stamp_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_stamp_preview.rotation_degrees = 0.0
	hover_stamp_preview.set_rest_scale(Vector2.ONE)
	var was_group_visible: bool = hover_stamp_group.visible
	hover_stamp_group.visible = true
	hover_stamp_preview.visible = true
	if !was_group_visible:
		fade_in_stamp_group()
	show_description(preview_stamp.get_display_description().strip_edges())

func show_description(description: String) -> void:
	if hover_description_label == null or hover_description_panel == null:
		return
	hover_description_label.text = DescriptionMarkup.to_bbcode(description, description_icon_font_size)
	var should_show: bool = !description.is_empty()
	var was_visible: bool = hover_description_panel.visible
	hover_description_panel.visible = should_show
	if should_show and !was_visible:
		fade_in_description_panel()

func show_piece_preview(preview_texture: Texture2D) -> void:
	if hover_piece_preview == null:
		return
	if preview_texture == null:
		hover_piece_preview.visible = false
		hover_piece_preview.texture = null
		return

	var was_visible: bool = hover_piece_preview.visible
	hover_piece_preview.texture = preview_texture
	hover_piece_preview.visible = true
	if !was_visible:
		fade_in_piece_preview()

func fade_in_stamp_group() -> void:
	if hover_stamp_group == null or !is_instance_valid(hover_stamp_group):
		return
	if _stamp_group_fade_tween != null and _stamp_group_fade_tween.is_valid():
		_stamp_group_fade_tween.kill()
	hover_stamp_group.modulate.a = 0.0
	_stamp_group_fade_tween = hover_stamp_group.create_tween()
	_stamp_group_fade_tween.tween_property(hover_stamp_group, "modulate:a", 1.0, hover_fade_in_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func fade_in_piece_preview() -> void:
	if hover_piece_preview == null or !is_instance_valid(hover_piece_preview):
		return
	if _piece_preview_fade_tween != null and _piece_preview_fade_tween.is_valid():
		_piece_preview_fade_tween.kill()
	hover_piece_preview.modulate.a = 0.0
	_piece_preview_fade_tween = hover_piece_preview.create_tween()
	_piece_preview_fade_tween.tween_property(hover_piece_preview, "modulate:a", 1.0, hover_fade_in_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func fade_in_description_panel() -> void:
	if hover_description_panel == null or !is_instance_valid(hover_description_panel):
		return
	if _description_panel_fade_tween != null and _description_panel_fade_tween.is_valid():
		_description_panel_fade_tween.kill()
	hover_description_panel.modulate.a = 0.0
	_description_panel_fade_tween = hover_description_panel.create_tween()
	_description_panel_fade_tween.tween_property(hover_description_panel, "modulate:a", 1.0, hover_fade_in_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func hide() -> void:
	if _stamp_group_fade_tween != null and _stamp_group_fade_tween.is_valid():
		_stamp_group_fade_tween.kill()
	if _piece_preview_fade_tween != null and _piece_preview_fade_tween.is_valid():
		_piece_preview_fade_tween.kill()
	if _description_panel_fade_tween != null and _description_panel_fade_tween.is_valid():
		_description_panel_fade_tween.kill()
	if hover_stamp_group:
		hover_stamp_group.visible = false
		hover_stamp_group.modulate.a = 1.0
	if hover_stamp_preview:
		hover_stamp_preview.visible = false
	if hover_piece_preview:
		hover_piece_preview.visible = false
		hover_piece_preview.texture = null
		hover_piece_preview.modulate.a = 1.0
	if hover_description_panel:
		hover_description_panel.visible = false
		hover_description_panel.modulate.a = 1.0
	if hover_description_label:
		hover_description_label.text = ""
	if hover_duration_display != null and is_instance_valid(hover_duration_display) and hover_duration_display.visible:
		_start_duration_overflow_fade_out()
		hover_duration_label.visible = false
		hover_duration_display.visible = false
	# Only stops new bubbles from spawning -- any already in flight keep
	# playing out their own drift-and-fade animation independently (see
	# _spawn_duration_bubble()), instead of vanishing along with the number.
	stop_duration_bubbles()

# Snapshots whatever the primary display was just showing (text + position)
# onto the overflow instance and fades that out, so the primary is instantly
# free to show a different piece's number right away (see
# show_piece_details()) without cutting this fade short.
func _start_duration_overflow_fade_out() -> void:
	if _duration_overflow_label == null or !is_instance_valid(_duration_overflow_label):
		return
	if _duration_overflow_display == null or !is_instance_valid(_duration_overflow_display):
		return
	if _duration_overflow_fade_tween != null and _duration_overflow_fade_tween.is_valid():
		_duration_overflow_fade_tween.kill()

	_duration_overflow_label.text = hover_duration_label.text
	_duration_overflow_label.visible = true
	_duration_overflow_display.global_position = hover_duration_display.global_position
	_duration_overflow_display.modulate.a = 1.0
	_duration_overflow_display.visible = true

	_duration_overflow_fade_tween = _duration_overflow_display.create_tween()
	_duration_overflow_fade_tween.tween_property(_duration_overflow_display, "modulate:a", 0.0, duration_fade_out_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_duration_overflow_fade_tween.tween_callback(Callable(self, "_finish_duration_overflow_fade_out"))

func _finish_duration_overflow_fade_out() -> void:
	if _duration_overflow_display != null and is_instance_valid(_duration_overflow_display):
		_duration_overflow_display.visible = false
	if _duration_overflow_label != null and is_instance_valid(_duration_overflow_label):
		_duration_overflow_label.visible = false

func update_duration_label_position(piece_screen_position: Vector2) -> void:
	if !hover_duration_display or !hover_duration_display.visible:
		return
	hover_duration_display.global_position = piece_screen_position + Vector2(-hover_duration_display.size.x * 0.5, -46.0)

	# Deferred from start_duration_bubbles() until the display has actually
	# been moved to this hover target -- spawning right there would still be
	# using last hover's (or the default) position.
	if _duration_bubble_needs_initial_burst:
		_duration_bubble_needs_initial_burst = false
		for i in duration_bubble_initial_spawn_count:
			_spawn_duration_bubble()

# Loops for as long as the duration number stays visible, popping a new
# bubble at each step (after an immediate initial burst -- see
# update_duration_label_position()). The intervals are uneven on purpose
# (rather than one fixed repeat) so the spawns don't read as a metronome;
# combined with each bubble's own lifetime below this settles around 4-5
# bubbles visible at once thereafter.
func start_duration_bubbles() -> void:
	stop_duration_bubbles()
	if hover_duration_display == null or !is_instance_valid(hover_duration_display):
		return

	_duration_bubble_needs_initial_burst = true
	_duration_bubble_spawn_tween = hover_duration_display.create_tween()
	_duration_bubble_spawn_tween.set_loops()
	for interval in duration_bubble_spawn_intervals:
		_duration_bubble_spawn_tween.tween_callback(Callable(self, "_spawn_duration_bubble"))
		_duration_bubble_spawn_tween.tween_interval(interval)

func stop_duration_bubbles() -> void:
	if _duration_bubble_spawn_tween != null and _duration_bubble_spawn_tween.is_valid():
		_duration_bubble_spawn_tween.kill()
	_duration_bubble_spawn_tween = null
	_duration_bubble_needs_initial_burst = false

func _spawn_duration_bubble() -> void:
	if hover_duration_display == null or !is_instance_valid(hover_duration_display) or !hover_duration_display.visible:
		return
	if canvas_layer == null or !is_instance_valid(canvas_layer):
		return

	var bubble := TextureRect.new()
	# A sibling of hover_duration_display under canvas_layer, not a child of
	# it: its position below is a one-off snapshot rather than something that
	# tracks the display, so a bubble spawned for one hover keeps playing out
	# in place (see hide()) even once hover_duration_display has moved on to
	# a different piece, or hidden entirely.
	canvas_layer.add_child(bubble)
	bubble.texture = DURATION_BUBBLE_TEXTURE
	bubble.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bubble.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bubble.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# One below hover_duration_display's own 901, so the number always reads
	# on top of the bubbles.
	bubble.z_index = 900
	# DURATION_BUBBLE_SHADER writes the final color itself (see its "color"
	# param below) and ignores the bound texture entirely, so self_modulate
	# must stay white here -- tinting it would multiply on top of that and
	# double-darken the result.

	var diameter: float = duration_bubble_reference_size * randf_range(duration_bubble_min_size_ratio, duration_bubble_max_size_ratio)
	bubble.size = Vector2.ONE * diameter
	bubble.pivot_offset = bubble.size * 0.5

	var bubble_material := ShaderMaterial.new()
	bubble_material.shader = DURATION_BUBBLE_SHADER
	bubble_material.set_shader_parameter("color", duration_shadow_color)
	bubble_material.set_shader_parameter("edge_softness", duration_bubble_edge_softness)
	bubble_material.set_shader_parameter("glow_strength", duration_bubble_glow_strength)
	bubble_material.set_shader_parameter("pulse_strength", 0.0)
	bubble.material = bubble_material

	var display_center: Vector2 = hover_duration_display.global_position + hover_duration_display.size * 0.5
	var angle: float = randf_range(0.0, TAU)
	var dist: float = randf_range(0.0, duration_bubble_spawn_radius)
	bubble.global_position = display_center + Vector2(cos(angle), sin(angle)) * dist - bubble.size * 0.5

	bubble.scale = Vector2.ZERO
	bubble.modulate.a = 0.0
	var base_y: float = bubble.position.y

	# Three unhurried phases, matching how they're meant to read: appear, then
	# drift while fully visible, then fade out while still drifting.
	var tween: Tween = bubble.create_tween()
	tween.tween_property(bubble, "scale", Vector2.ONE, duration_bubble_pop_in_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(bubble, "modulate:a", 1.0, duration_bubble_pop_in_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(bubble, "position:y", base_y - duration_bubble_drift_rise_distance, duration_bubble_drift_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(bubble, "position:y", base_y - duration_bubble_drift_rise_distance - duration_bubble_fade_rise_distance, duration_bubble_fade_out_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(bubble, "modulate:a", 0.0, duration_bubble_fade_out_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(Callable(bubble, "queue_free"))
