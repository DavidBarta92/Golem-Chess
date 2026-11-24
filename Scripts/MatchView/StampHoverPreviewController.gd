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

## The info coming up from nothing: the stamp flutters in from the right -
## this far, turned this much further, over this long - and the piece pops up
## from behind it, past its place, and drops back onto it with a squash.
## Screen pixels, degrees and seconds.
const ENTER_SLIDE_DISTANCE: float = 70.0
const ENTER_TURN_DEGREES: float = 9.0
const ENTER_SECONDS: float = 0.2
const PIECE_POP_DELAY: float = 0.07
const PIECE_POP_START_DROP: float = 110.0
const PIECE_POP_START_SCALE: float = 0.8
const PIECE_POP_OVERSHOOT: float = 22.0
const PIECE_POP_RISE_SECONDS: float = 0.15
const PIECE_POP_FALL_SECONDS: float = 0.11
const PIECE_LAND_SQUASH: Vector2 = Vector2(1.08, 0.9)
const PIECE_LAND_SQUASH_SECONDS: float = 0.04
const PIECE_LAND_SETTLE_SECONDS: float = 0.14
const DESCRIPTION_DELAY: float = 0.1
## Going, and moving on to another piece or stamp: quick.
const LEAVE_SECONDS: float = 0.1
const SWITCH_FROM_ALPHA: float = 0.3
const SWITCH_SECONDS: float = 0.1

enum Arrival { ENTER, SWITCH, STAY }

## How close the description may come to the board (BoardCanvas.BOARD_RIGHT_X).
const BOARD_GAP: float = 12.0
## A faint wash of paper behind the description, so the ink lines drawn on
## the table behind it do not cut through the words: this opaque, its edge
## feathered out this far, the corners this round, reaching this far past
## the text's top and bottom. It is as tall as the text.
const BACKING_ALPHA: float = 0.6
const BACKING_FEATHER_ALPHA: float = 0.35
const BACKING_FEATHER: int = 10
const BACKING_CORNER_RADIUS: int = 12
const BACKING_PAD: float = 4.0

var canvas_layer: CanvasLayer
var stamp_visual_scene: PackedScene
var stamp_ui_size: Vector2 = Vector2(168.7, 229)
## The info column's distance from the screen's right edge.
var hover_stamp_margin: float = 14.0
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
var hover_description_backing: Panel
var hover_description_label: RichTextLabel
var description_icon_font_size: int = 16
var hover_fade_in_duration: float = 0.16
var duration_fade_out_duration: float = 0.35

var is_reveal_blocked_provider: Callable

## Each part's coming-up and going tweens, by part.
var _appear_tweens: Dictionary = {}
var _leave_tweens: Dictionary = {}
## Where the stamp and the piece rest, from their layout in create_ui().
var _stamp_rest_offset_right: float = 0.0
var _piece_rest_offset_top: float = 0.0
var _duration_bubble_spawn_tween: Tween
var _duration_overflow_fade_tween: Tween
var _duration_bubble_needs_initial_burst: bool = false

func configure(config: Dictionary) -> void:
	canvas_layer = config.get("canvas_layer", canvas_layer)
	stamp_visual_scene = config.get("stamp_visual_scene", stamp_visual_scene)
	stamp_ui_size = config.get("stamp_ui_size", stamp_ui_size)
	hover_stamp_margin = float(config.get("hover_stamp_margin", hover_stamp_margin))
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
	layout()
	var viewport: Viewport = canvas_layer.get_viewport()
	if viewport != null and !viewport.size_changed.is_connected(layout):
		viewport.size_changed.connect(layout)

## Places the column across: the description's right edge `hover_stamp_margin`
## from the screen's, as wide as the room up to the board allows
## (`description_panel_width` at most), the stamp and the piece centred over
## it. The board's reach comes off the drawn room (BoardCanvas), so the column
## keeps clear of it on every screen shape, and is placed again when the
## window changes shape. Up and down it keeps its place by the screen's middle.
func layout() -> void:
	if canvas_layer == null or !is_instance_valid(canvas_layer) or hover_stamp_group == null:
		return
	var viewport_size: Vector2 = canvas_layer.get_viewport().get_visible_rect().size
	var board_right: float = BoardCanvas.to_viewport(Vector2(BoardCanvas.BOARD_RIGHT_X, 0.0), viewport_size).x
	var room: float = viewport_size.x - hover_stamp_margin - (board_right + BOARD_GAP)
	var width: float = clampf(room, stamp_ui_size.x * hover_stamp_preview_scale, description_panel_width)
	# From the right edge, where every part of the column is anchored.
	var centre_x: float = -hover_stamp_margin - width * 0.5

	_stamp_rest_offset_right = centre_x + stamp_ui_size.x * 0.5
	_set_stamp_slide(0.0)
	hover_piece_preview.offset_left = centre_x - hover_piece_preview_size.x * 0.5
	hover_piece_preview.offset_right = centre_x + hover_piece_preview_size.x * 0.5
	hover_description_panel.offset_left = centre_x - width * 0.5
	hover_description_panel.offset_right = centre_x + width * 0.5
	_fit_backing()

## The wash behind the description, as wide as its box and as tall as the
## text in it now.
func _fit_backing() -> void:
	if hover_description_backing == null or hover_description_label == null:
		return
	var text_height: float = float(hover_description_label.get_content_height()) if !hover_description_label.text.is_empty() else 0.0
	hover_description_backing.visible = text_height > 0.0
	hover_description_backing.position = Vector2(0.0, description_text_margin.y - BACKING_PAD)
	hover_description_backing.size = Vector2(hover_description_panel.size.x, text_height + BACKING_PAD * 2.0)

func create_description_panel() -> void:
	hover_description_panel = Control.new()
	canvas_layer.add_child(hover_description_panel)
	hover_description_panel.name = "HoverDescriptionPanel"
	hover_description_panel.visible = false
	hover_description_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Under the stamp (and the piece over it): beside it, on the left, it
	# reached onto the board on every screen narrower than 16:9. Across, it is
	# placed by layout().
	hover_description_panel.anchor_left = 1.0
	hover_description_panel.anchor_right = 1.0
	hover_description_panel.anchor_top = 0.5
	hover_description_panel.anchor_bottom = 0.5
	var stamp_bottom: float = hover_stamp_vertical_offset + stamp_ui_size.y * hover_stamp_preview_scale * 0.5
	hover_description_panel.offset_top = stamp_bottom + description_panel_gap
	hover_description_panel.offset_bottom = hover_description_panel.offset_top + description_panel_height
	hover_description_panel.z_index = 899

	hover_description_backing = Panel.new()
	hover_description_panel.add_child(hover_description_backing)
	hover_description_backing.name = "Backing"
	hover_description_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var wash := StyleBoxFlat.new()
	wash.bg_color = Color(UiPalette.PAPER, BACKING_ALPHA)
	wash.shadow_color = Color(UiPalette.PAPER, BACKING_FEATHER_ALPHA)
	wash.shadow_size = BACKING_FEATHER
	wash.set_corner_radius_all(BACKING_CORNER_RADIUS)
	wash.anti_aliasing = true
	hover_description_backing.add_theme_stylebox_override("panel", wash)

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
	hover_description_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
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
	# Across, it is placed by layout().
	_piece_rest_offset_top = -hover_piece_preview_size.y * 0.5 + hover_piece_preview_vertical_offset
	hover_piece_preview.offset_top = _piece_rest_offset_top
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

	var arrival: int = _take_arrival(hover_stamp_group)
	hover_stamp_preview.set_stamp(preview_stamp)
	hover_stamp_preview.set_face_down(false)
	hover_stamp_preview.disabled = true
	hover_stamp_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_stamp_preview.rotation_degrees = 0.0
	hover_stamp_preview.set_rest_scale(Vector2.ONE)
	hover_stamp_group.visible = true
	hover_stamp_preview.visible = true
	match arrival:
		Arrival.ENTER:
			_enter_stamp()
		Arrival.SWITCH:
			_switch_in(hover_stamp_group)
	show_description(preview_stamp.get_display_description().strip_edges())

func show_description(description: String) -> void:
	if hover_description_label == null or hover_description_panel == null:
		return
	var arrival: int = _take_arrival(hover_description_panel)
	hover_description_label.text = DescriptionMarkup.to_bbcode(description, description_icon_font_size)
	if description.is_empty():
		_put_away(hover_description_panel)
		return
	hover_description_panel.visible = true
	_fit_backing()
	match arrival:
		Arrival.ENTER:
			_fade_in(hover_description_panel, DESCRIPTION_DELAY)
		Arrival.SWITCH:
			_switch_in(hover_description_panel)

func show_piece_preview(preview_texture: Texture2D) -> void:
	if hover_piece_preview == null:
		return
	var arrival: int = _take_arrival(hover_piece_preview)
	if preview_texture == null:
		_put_away(hover_piece_preview)
		return

	hover_piece_preview.texture = preview_texture
	hover_piece_preview.visible = true
	match arrival:
		Arrival.ENTER:
			_pop_piece()
		Arrival.SWITCH:
			_switch_in(hover_piece_preview)

## How a part comes up now: from nothing, in place of what it was just
## showing (hide() and a show in the same frame is the cursor moving on to
## another piece or stamp), or over itself. A part on its way out stays.
func _take_arrival(part: Control) -> int:
	var leaving: Tween = _leave_tweens.get(part, null)
	if leaving != null and leaving.is_valid():
		leaving.kill()
		_leave_tweens.erase(part)
		return Arrival.SWITCH
	return Arrival.STAY if part.visible else Arrival.ENTER

## The stamp flutters in from the right and turns into its place.
func _enter_stamp() -> void:
	_kill_appear(hover_stamp_group)
	_set_stamp_slide(ENTER_SLIDE_DISTANCE)
	hover_stamp_group.rotation_degrees = hover_stamp_rotation_degrees + ENTER_TURN_DEGREES
	hover_stamp_group.modulate.a = 0.0
	var tween: Tween = hover_stamp_group.create_tween()
	tween.tween_method(_set_stamp_slide, ENTER_SLIDE_DISTANCE, 0.0, ENTER_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(hover_stamp_group, "rotation_degrees", hover_stamp_rotation_degrees, ENTER_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(hover_stamp_group, "modulate:a", 1.0, ENTER_SECONDS * 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_appear_tweens[hover_stamp_group] = tween

## The piece pops up from behind the stamp, past its place, and drops back
## onto it with a little squash.
func _pop_piece() -> void:
	_kill_appear(hover_piece_preview)
	hover_piece_preview.pivot_offset = Vector2(hover_piece_preview_size.x * 0.5, hover_piece_preview_size.y)
	_set_piece_lift(-PIECE_POP_START_DROP)
	hover_piece_preview.scale = Vector2.ONE * PIECE_POP_START_SCALE
	hover_piece_preview.modulate.a = 0.0
	var tween: Tween = hover_piece_preview.create_tween()
	tween.tween_interval(PIECE_POP_DELAY)
	tween.tween_method(_set_piece_lift, -PIECE_POP_START_DROP, PIECE_POP_OVERSHOOT, PIECE_POP_RISE_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(hover_piece_preview, "scale", Vector2.ONE, PIECE_POP_RISE_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(hover_piece_preview, "modulate:a", 1.0, PIECE_POP_RISE_SECONDS * 0.4)
	tween.tween_method(_set_piece_lift, PIECE_POP_OVERSHOOT, 0.0, PIECE_POP_FALL_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(hover_piece_preview, "scale", PIECE_LAND_SQUASH, PIECE_LAND_SQUASH_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(hover_piece_preview, "scale", Vector2.ONE, PIECE_LAND_SETTLE_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_appear_tweens[hover_piece_preview] = tween

func _fade_in(part: Control, delay: float) -> void:
	_kill_appear(part)
	part.modulate.a = 0.0
	var tween: Tween = part.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(part, "modulate:a", 1.0, hover_fade_in_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_appear_tweens[part] = tween

## Showing something else in its place: back where it rests, the new content
## coming up quickly from faint.
func _switch_in(part: Control) -> void:
	_kill_appear(part)
	_rest(part)
	part.modulate.a = SWITCH_FROM_ALPHA
	var tween: Tween = part.create_tween()
	tween.tween_property(part, "modulate:a", 1.0, SWITCH_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_appear_tweens[part] = tween

## Fades a part out quickly, then puts it away.
func _leave(part: Control) -> void:
	if part == null or !is_instance_valid(part) or !part.visible:
		return
	var leaving: Tween = _leave_tweens.get(part, null)
	if leaving != null and leaving.is_valid():
		return
	_kill_appear(part)
	var tween: Tween = part.create_tween()
	tween.tween_property(part, "modulate:a", 0.0, LEAVE_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_put_away.bind(part))
	_leave_tweens[part] = tween

func _put_away(part: Control) -> void:
	_kill_appear(part)
	_leave_tweens.erase(part)
	part.visible = false
	part.modulate.a = 1.0
	_rest(part)
	if part == hover_stamp_group and hover_stamp_preview != null:
		hover_stamp_preview.visible = false
	elif part == hover_piece_preview:
		hover_piece_preview.texture = null
	elif part == hover_description_panel and hover_description_label != null:
		hover_description_label.text = ""

func _rest(part: Control) -> void:
	if part == hover_stamp_group:
		_set_stamp_slide(0.0)
		hover_stamp_group.rotation_degrees = hover_stamp_rotation_degrees
	elif part == hover_piece_preview:
		_set_piece_lift(0.0)
		hover_piece_preview.scale = Vector2.ONE

func _kill_appear(part: Control) -> void:
	var appearing: Tween = _appear_tweens.get(part, null)
	if appearing != null and appearing.is_valid():
		appearing.kill()
	_appear_tweens.erase(part)

## The stamp's place, moved `distance` to the right; computed from its layout,
## never read back off the control (see MATCH_SCENE.md).
func _set_stamp_slide(distance: float) -> void:
	hover_stamp_group.offset_right = _stamp_rest_offset_right + distance
	hover_stamp_group.offset_left = _stamp_rest_offset_right + distance - stamp_ui_size.x

## The piece's place, raised by `height` (lowered when below 0).
func _set_piece_lift(height: float) -> void:
	hover_piece_preview.offset_top = _piece_rest_offset_top - height
	hover_piece_preview.offset_bottom = _piece_rest_offset_top - height + hover_piece_preview_size.y

func hide() -> void:
	for part in [hover_stamp_group, hover_piece_preview, hover_description_panel]:
		_leave(part)
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
