extends Control

## The stamp painter's drawing surface: one RGBA image the size of a stamp's
## art, the tools that paint into it, undo and redo, and the view (zoom, pan).
## StampPainter.gd builds the panels around it and puts the mask guide into
## overlay_root, which always covers the image.
##
## The pixels live in a PackedByteArray; the image and its texture are synced
## from it once a frame. A stroke paints a coverage map (0-255 per pixel,
## the most any part of the stroke reached) and blends the stroke's colour over
## the pixels as they were when it started, so overlapping parts of one stroke
## do not darken and its antialiased edge stays clean.

signal image_changed
signal tool_changed(new_tool: int)
signal colors_changed
signal brush_size_changed(new_size: int)
signal cursor_moved(image_position: Vector2i, inside_image: bool)
signal view_changed

enum Tool { PENCIL, BRUSH, ERASER, FILL, LINE, RECT, ELLIPSE, PICKER }

## The size of the stamps' art (Assets/Stamps/*/*.png), so a drawing can stand in for it.
const IMAGE_SIZE := Vector2i(554, 700)
const MAX_UNDO_STEPS: int = 40
const MIN_BRUSH_SIZE: int = 1
const MAX_BRUSH_SIZE: int = 96
const MAX_ZOOM: float = 8.0
const ZOOM_STEP: float = 1.15
## From this zoom up the pixels show as squares.
const PIXEL_ZOOM: float = 2.0
const FIT_MARGIN: float = 12.0
## The fill takes colours this close to the clicked one (RGBA distance, 0-510).
const FILL_TOLERANCE: float = 40.0
const BACKDROP_COLOR := Color("#e8e3d9")  # UiPalette.PAPER_SHADE
const IMAGE_EDGE_COLOR := Color(0.09, 0.17, 0.26, 0.35)  # UiPalette.INK, faint
const CURSOR_COLOR := Color("#172c43")  # UiPalette.INK
const SHAPE_TOOLS: Array[int] = [Tool.LINE, Tool.RECT, Tool.ELLIPSE]
const STROKE_TOOLS: Array[int] = [Tool.PENCIL, Tool.BRUSH, Tool.ERASER]

var tool: int = Tool.BRUSH
var brush_size: int = 8
var shapes_filled: bool = false
## Left button paints with the ink, right button and the eraser with the paper.
var ink_color: Color = Color.BLACK
var paper_color: Color = Color.WHITE
## Colours the picker may choose; a picked colour snaps to the nearest. Empty: any colour.
var palette: PackedColorArray = PackedColorArray()

var image: Image
var texture: ImageTexture
## The guide's parent: kept over the image whatever the zoom and pan.
var overlay_root: Control
var view_scale: float = 1.0
var view_offset: Vector2 = Vector2.ZERO

var _width: int = IMAGE_SIZE.x
var _height: int = IMAGE_SIZE.y
var _pixels: PackedByteArray
var _stroke_base: PackedByteArray
var _coverage: PackedByteArray
var _undo: Array[PackedByteArray] = []
var _redo: Array[PackedByteArray] = []
var _texture_dirty: bool = false

var _active_button: int = MOUSE_BUTTON_NONE
var _active_tool: int = -1
var _stroke_color: Color
var _last_point: Vector2
var _drag_start: Vector2
var _drag_end: Vector2
var _tool_before_picker: int = Tool.BRUSH

var _view_is_fit: bool = true
var _panning: bool = false
var _space_held: bool = false
var _mouse_position: Vector2 = Vector2.ZERO
var _mouse_inside: bool = false
var _cursor_layer: Control

func _ready() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	_pixels.resize(_width * _height * 4)
	_coverage.resize(_width * _height)
	image = Image.create_empty(_width, _height, true, Image.FORMAT_RGBA8)
	_fill_pixels(paper_color)
	image.set_data(_width, _height, false, Image.FORMAT_RGBA8, _pixels)
	image.generate_mipmaps()
	texture = ImageTexture.create_from_image(image)

	overlay_root = Control.new()
	overlay_root.name = "OverlayRoot"
	overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay_root)
	_cursor_layer = Control.new()
	_cursor_layer.name = "CursorLayer"
	_cursor_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cursor_layer.draw.connect(_draw_cursor_layer)
	add_child(_cursor_layer)
	resized.connect(_on_resized)
	mouse_exited.connect(_on_mouse_exited)
	fit_view()

func _process(_delta: float) -> void:
	if _texture_dirty:
		_sync_texture()

# --- Public API -------------------------------------------------------------

func set_tool(new_tool: int) -> void:
	if new_tool == tool:
		return
	if new_tool == Tool.PICKER:
		_tool_before_picker = tool
	tool = new_tool
	tool_changed.emit(tool)
	_cursor_layer.queue_redraw()

func set_brush_size(new_size: int) -> void:
	new_size = clampi(new_size, MIN_BRUSH_SIZE, MAX_BRUSH_SIZE)
	if new_size == brush_size:
		return
	brush_size = new_size
	brush_size_changed.emit(brush_size)
	_cursor_layer.queue_redraw()

func set_ink_color(color: Color) -> void:
	ink_color = color
	colors_changed.emit()

func set_paper_color(color: Color) -> void:
	paper_color = color
	colors_changed.emit()

func swap_colors() -> void:
	var previous_ink: Color = ink_color
	ink_color = paper_color
	paper_color = previous_ink
	colors_changed.emit()

func set_space_held(held: bool) -> void:
	_space_held = held
	if !held && _panning && _active_button == MOUSE_BUTTON_NONE:
		_panning = false

func can_undo() -> bool:
	return !_undo.is_empty()

func can_redo() -> bool:
	return !_redo.is_empty()

func undo() -> void:
	if _undo.is_empty() || _active_button != MOUSE_BUTTON_NONE:
		return
	_redo.append(_pixels)
	_pixels = _undo.pop_back()
	_mark_changed()

func redo() -> void:
	if _redo.is_empty() || _active_button != MOUSE_BUTTON_NONE:
		return
	_undo.append(_pixels)
	_pixels = _redo.pop_back()
	_mark_changed()

## A blank sheet in the paper colour, with no history: for a new painter.
func reset_canvas() -> void:
	_fill_pixels(paper_color)
	_undo.clear()
	_redo.clear()
	_texture_dirty = true
	queue_redraw()

## Paints the whole image with the paper colour; undo brings the drawing back.
func clear_canvas() -> void:
	_push_undo()
	_fill_pixels(paper_color)
	_mark_changed()

## Replaces the drawing with an image (an earlier drawing, a stamp's own art).
## One of another size is scaled to cover the canvas and cropped in the middle,
## as a stamp shows its art. Undo brings the previous drawing back.
func load_image(source: Image) -> void:
	if source == null || source.is_empty():
		return
	var loaded: Image = source.duplicate() as Image
	if loaded.is_compressed():
		loaded.decompress()
	loaded.clear_mipmaps()
	loaded.convert(Image.FORMAT_RGBA8)
	if loaded.get_size() != IMAGE_SIZE:
		var cover: float = maxf(float(_width) / loaded.get_width(), float(_height) / loaded.get_height())
		var scaled_size := Vector2i(ceili(loaded.get_width() * cover), ceili(loaded.get_height() * cover))
		loaded.resize(scaled_size.x, scaled_size.y, Image.INTERPOLATE_LANCZOS)
		@warning_ignore("integer_division")
		var crop_origin := (scaled_size - IMAGE_SIZE) / 2
		loaded = loaded.get_region(Rect2i(crop_origin, IMAGE_SIZE))
	_push_undo()
	_pixels = loaded.get_data()
	_mark_changed()

## The drawing as it is now, without mipmaps, for saving.
func get_image_copy() -> Image:
	return Image.create_from_data(_width, _height, false, Image.FORMAT_RGBA8, _pixels)

func fit_view() -> void:
	var available: Vector2 = size - Vector2.ONE * FIT_MARGIN * 2.0
	if available.x <= 0.0 || available.y <= 0.0:
		return
	view_scale = minf(available.x / _width, available.y / _height)
	view_offset = ((size - Vector2(_width, _height) * view_scale) * 0.5).round()
	_view_is_fit = true
	_apply_view()

func zoom_at(canvas_position: Vector2, factor: float) -> void:
	var image_position: Vector2 = (canvas_position - view_offset) / view_scale
	view_scale = clampf(view_scale * factor, _fit_scale() * 0.5, MAX_ZOOM)
	view_offset = canvas_position - image_position * view_scale
	_view_is_fit = false
	_apply_view()

func get_image_rect() -> Rect2:
	return Rect2(view_offset, Vector2(_width, _height) * view_scale)

# --- Input -------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null:
		_mouse_position = motion.position
		_mouse_inside = true
		if _panning:
			view_offset += motion.relative
			_view_is_fit = false
			_apply_view()
			accept_event()
			return
		var image_position: Vector2 = _to_image(motion.position)
		cursor_moved.emit(Vector2i(image_position.floor()), _is_inside_image(image_position))
		if _active_button != MOUSE_BUTTON_NONE:
			_continue_operation(image_position)
		_cursor_layer.queue_redraw()
		accept_event()
		return

	var button := event as InputEventMouseButton
	if button == null:
		return
	match button.button_index:
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
			if button.pressed:
				zoom_at(button.position, ZOOM_STEP if button.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / ZOOM_STEP)
			accept_event()
		MOUSE_BUTTON_MIDDLE:
			_panning = button.pressed
			accept_event()
		MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
			if button.pressed:
				if _space_held && button.button_index == MOUSE_BUTTON_LEFT:
					_panning = true
				elif _active_button == MOUSE_BUTTON_NONE:
					_begin_operation(button.button_index, _to_image(button.position))
			else:
				if _panning && button.button_index == MOUSE_BUTTON_LEFT:
					_panning = false
				elif button.button_index == _active_button:
					_end_operation(_to_image(button.position))
			accept_event()

func _on_mouse_exited() -> void:
	_mouse_inside = false
	_cursor_layer.queue_redraw()

func _to_image(canvas_position: Vector2) -> Vector2:
	return (canvas_position - view_offset) / view_scale

func _is_inside_image(image_position: Vector2) -> bool:
	return image_position.x >= 0.0 && image_position.y >= 0.0 && image_position.x < _width && image_position.y < _height

# --- Operations --------------------------------------------------------------

func _begin_operation(mouse_button: int, point: Vector2) -> void:
	var with_paper: bool = mouse_button == MOUSE_BUTTON_RIGHT || tool == Tool.ERASER
	_stroke_color = paper_color if with_paper else ink_color
	match tool:
		Tool.PICKER:
			_pick_color(point, mouse_button)
		Tool.FILL:
			_push_undo()
			if _flood_fill(point, _stroke_color):
				_mark_changed()
			else:
				_undo.pop_back()
		Tool.PENCIL, Tool.BRUSH, Tool.ERASER:
			_active_button = mouse_button
			_active_tool = tool
			_push_undo()
			_begin_stroke()
			_last_point = _snap_stroke_point(point)
			_paint_segment(_last_point, _last_point)
		Tool.LINE, Tool.RECT, Tool.ELLIPSE:
			_active_button = mouse_button
			_active_tool = tool
			_drag_start = point
			_drag_end = point
			queue_redraw()

func _continue_operation(point: Vector2) -> void:
	if _active_tool in STROKE_TOOLS:
		var next_point: Vector2 = _snap_stroke_point(point)
		_paint_segment(_last_point, next_point)
		_last_point = next_point
	elif _active_tool in SHAPE_TOOLS:
		_drag_end = _constrain_shape_end(_drag_start, point)
		queue_redraw()

func _end_operation(point: Vector2) -> void:
	if _active_tool in STROKE_TOOLS:
		_continue_operation(point)
		_mark_changed()
	elif _active_tool in SHAPE_TOOLS:
		_drag_end = _constrain_shape_end(_drag_start, point)
		_push_undo()
		_begin_stroke()
		var dirty: Rect2i = _rasterize_shape(_active_tool, _drag_start, _drag_end)
		if dirty.has_area():
			_composite(dirty, _stroke_color)
			_mark_changed()
		else:
			_undo.pop_back()
	_active_button = MOUSE_BUTTON_NONE
	_active_tool = -1
	queue_redraw()

func _pick_color(point: Vector2, mouse_button: int) -> void:
	if !_is_inside_image(point):
		return
	var index: int = (int(point.y) * _width + int(point.x)) * 4
	var picked := Color8(_pixels[index], _pixels[index + 1], _pixels[index + 2])
	picked = _nearest_palette_color(picked)
	if mouse_button == MOUSE_BUTTON_RIGHT:
		set_paper_color(picked)
	else:
		set_ink_color(picked)
	set_tool(_tool_before_picker)

func _nearest_palette_color(color: Color) -> Color:
	if palette.is_empty():
		return color
	var best: Color = palette[0]
	var best_distance: float = INF
	for candidate: Color in palette:
		var distance: float = Vector3(candidate.r - color.r, candidate.g - color.g, candidate.b - color.b).length_squared()
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best

## The pencil lands on pixel centres (odd sizes) or corners (even sizes), so
## its hard dots are symmetric; the brush and eraser go where the mouse is.
func _snap_stroke_point(point: Vector2) -> Vector2:
	if _active_tool != Tool.PENCIL:
		return point
	if brush_size % 2 == 1:
		return point.floor() + Vector2(0.5, 0.5)
	return point.round()

## Shift keeps lines at 45 degree steps and makes squares and circles.
func _constrain_shape_end(start: Vector2, end: Vector2) -> Vector2:
	if !Input.is_key_pressed(KEY_SHIFT):
		return end
	var delta: Vector2 = end - start
	if _active_tool == Tool.LINE:
		var step: float = PI / 4.0
		var angle: float = roundf(delta.angle() / step) * step
		return start + Vector2.from_angle(angle) * delta.length()
	var side: float = maxf(absf(delta.x), absf(delta.y))
	return start + Vector2(side * signf(delta.x if delta.x != 0.0 else 1.0), side * signf(delta.y if delta.y != 0.0 else 1.0))

# --- Painting ----------------------------------------------------------------

func _begin_stroke() -> void:
	_stroke_base = _pixels.duplicate()
	_coverage.fill(0)

func _paint_segment(from: Vector2, to: Vector2) -> void:
	var dirty: Rect2i
	if _active_tool == Tool.PENCIL && brush_size == 1:
		dirty = _cover_pixel_line(Vector2i(from.floor()), Vector2i(to.floor()))
	else:
		dirty = _cover_segment(from, to, maxf(brush_size * 0.5, 0.5), _active_tool == Tool.PENCIL)
	if dirty.has_area():
		_composite(dirty, _stroke_color)
		_texture_dirty = true

## A one pixel wide line with no antialiasing (Bresenham), for the 1 px pencil.
func _cover_pixel_line(from: Vector2i, to: Vector2i) -> Rect2i:
	var x: int = from.x
	var y: int = from.y
	var dx: int = absi(to.x - from.x)
	var dy: int = -absi(to.y - from.y)
	var step_x: int = 1 if from.x < to.x else -1
	var step_y: int = 1 if from.y < to.y else -1
	var error: int = dx + dy
	while true:
		if x >= 0 && y >= 0 && x < _width && y < _height:
			_coverage[y * _width + x] = 255
		if x == to.x && y == to.y:
			break
		var doubled: int = error * 2
		if doubled >= dy:
			error += dy
			x += step_x
		if doubled <= dx:
			error += dx
			y += step_y
	return _clip_rect(Rect2i(mini(from.x, to.x), mini(from.y, to.y), absi(to.x - from.x) + 1, absi(to.y - from.y) + 1))

## Covers every pixel whose centre lies within radius of the segment: a
## capsule, so strokes have round ends and joins. hard leaves the edge
## unsmoothed (the pencil); otherwise the edge is antialiased over one pixel.
func _cover_segment(from: Vector2, to: Vector2, radius: float, hard: bool) -> Rect2i:
	var reach: float = radius + 1.0
	var bounds: Rect2i = _clip_rect(Rect2i(
		floori(minf(from.x, to.x) - reach), floori(minf(from.y, to.y) - reach),
		ceili(absf(to.x - from.x) + reach * 2.0) + 1, ceili(absf(to.y - from.y) + reach * 2.0) + 1))
	if !bounds.has_area():
		return bounds
	var along_x: float = to.x - from.x
	var along_y: float = to.y - from.y
	var length_squared: float = along_x * along_x + along_y * along_y
	var inverse_length_squared: float = 1.0 / length_squared if length_squared > 0.000001 else 0.0
	var radius_squared: float = radius * radius
	for y: int in range(bounds.position.y, bounds.end.y):
		var center_y: float = y + 0.5
		var row_start: int = bounds.position.x
		var row_end: int = bounds.end.x
		# Only the part of the row the capsule can reach.
		if absf(along_y) > 0.0001:
			var t_low: float = clampf((center_y - reach - from.y) / along_y, 0.0, 1.0)
			var t_high: float = clampf((center_y + reach - from.y) / along_y, 0.0, 1.0)
			var x_low: float = from.x + along_x * t_low
			var x_high: float = from.x + along_x * t_high
			row_start = maxi(row_start, floori(minf(x_low, x_high) - reach))
			row_end = mini(row_end, ceili(maxf(x_low, x_high) + reach) + 1)
		var row: int = y * _width
		for x: int in range(row_start, row_end):
			var center_x: float = x + 0.5
			var t: float = clampf(((center_x - from.x) * along_x + (center_y - from.y) * along_y) * inverse_length_squared, 0.0, 1.0)
			var offset_x: float = center_x - from.x - along_x * t
			var offset_y: float = center_y - from.y - along_y * t
			var distance_squared: float = offset_x * offset_x + offset_y * offset_y
			var value: int
			if hard:
				if distance_squared > radius_squared:
					continue
				value = 255
			else:
				var edge: float = radius + 0.5 - sqrt(distance_squared)
				if edge <= 0.0:
					continue
				value = 255 if edge >= 1.0 else int(edge * 255.0 + 0.5)
			if value > _coverage[row + x]:
				_coverage[row + x] = value
	return bounds

func _rasterize_shape(shape_tool: int, start: Vector2, end: Vector2) -> Rect2i:
	match shape_tool:
		Tool.LINE:
			return _cover_segment(start, end, maxf(brush_size * 0.5, 0.5), false)
		Tool.RECT:
			return _cover_rect(_shape_pixel_rect(start, end))
		Tool.ELLIPSE:
			return _cover_ellipse(_shape_pixel_rect(start, end))
	return Rect2i()

## The pixels a rectangle or ellipse drag spans, both corners included.
func _shape_pixel_rect(start: Vector2, end: Vector2) -> Rect2i:
	var a := Vector2i(start.floor())
	var b := Vector2i(end.floor())
	return Rect2i(mini(a.x, b.x), mini(a.y, b.y), absi(b.x - a.x) + 1, absi(b.y - a.y) + 1)

## Rectangles sit on the pixel grid, so they need no smoothing: the outline is
## brush_size pixels wide, inside the dragged rectangle.
func _cover_rect(rect: Rect2i) -> Rect2i:
	var bounds: Rect2i = _clip_rect(rect)
	if !bounds.has_area():
		return bounds
	var thickness: int = brush_size
	for y: int in range(bounds.position.y, bounds.end.y):
		var row: int = y * _width
		var in_band_row: bool = shapes_filled || y < rect.position.y + thickness || y >= rect.end.y - thickness
		for x: int in range(bounds.position.x, bounds.end.x):
			if in_band_row || x < rect.position.x + thickness || x >= rect.end.x - thickness:
				_coverage[row + x] = 255
	return bounds

## An ellipse inscribed in rect, its outline brush_size wide and centred on the
## curve, antialiased. Rows only visit the band between an outer and an inner
## ellipse; inside the inner one a filled ellipse is solid.
func _cover_ellipse(rect: Rect2i) -> Rect2i:
	var radius: float = maxf(brush_size * 0.5, 0.5)
	var center := Vector2(rect.position) + Vector2(rect.size) * 0.5
	var axis_x: float = rect.size.x * 0.5
	var axis_y: float = rect.size.y * 0.5
	if axis_x < 1.0 || axis_y < 1.0:
		return _cover_segment(Vector2(rect.position) + Vector2(0.5, 0.5), Vector2(rect.end) - Vector2(0.5, 0.5), radius, false)
	var reach: float = radius + 1.0
	var bounds: Rect2i = _clip_rect(Rect2i(rect.position - Vector2i.ONE * ceili(reach), rect.size + Vector2i.ONE * ceili(reach) * 2))
	if !bounds.has_area():
		return bounds
	var outer_x: float = axis_x + reach
	var outer_y: float = axis_y + reach
	var inner_x: float = axis_x - reach
	var inner_y: float = axis_y - reach
	var axis_x4: float = pow(axis_x, 4.0)
	var axis_y4: float = pow(axis_y, 4.0)
	for y: int in range(bounds.position.y, bounds.end.y):
		var offset_y: float = y + 0.5 - center.y
		if absf(offset_y) >= outer_y:
			continue
		var outer_half: float = outer_x * sqrt(1.0 - pow(offset_y / outer_y, 2.0))
		var inner_half: float = -1.0
		if inner_x > 0.0 && inner_y > 0.0 && absf(offset_y) < inner_y:
			inner_half = inner_x * sqrt(1.0 - pow(offset_y / inner_y, 2.0))
		var row: int = y * _width
		var row_start: int = maxi(bounds.position.x, floori(center.x - outer_half))
		var row_end: int = mini(bounds.end.x, ceili(center.x + outer_half) + 1)
		for x: int in range(row_start, row_end):
			var offset_x: float = x + 0.5 - center.x
			if absf(offset_x) < inner_half:
				if shapes_filled:
					_coverage[row + x] = 255
				continue
			# Distance to the curve, to first order: (g - 1) / |grad g|.
			var g: float = sqrt(pow(offset_x / axis_x, 2.0) + pow(offset_y / axis_y, 2.0))
			var gradient: float = sqrt(offset_x * offset_x / axis_x4 + offset_y * offset_y / axis_y4)
			var signed_distance: float = (g - 1.0) * g / maxf(gradient, 0.000001)
			var edge: float = radius + 0.5 - (signed_distance if shapes_filled else absf(signed_distance))
			if edge <= 0.0:
				continue
			var value: int = 255 if edge >= 1.0 else int(edge * 255.0 + 0.5)
			if value > _coverage[row + x]:
				_coverage[row + x] = value
	return bounds

## Blends color over the stroke's starting pixels by the coverage, inside rect.
func _composite(rect: Rect2i, color: Color) -> void:
	var red: int = color.r8
	var green: int = color.g8
	var blue: int = color.b8
	for y: int in range(rect.position.y, rect.end.y):
		var row: int = y * _width
		for x: int in range(rect.position.x, rect.end.x):
			var value: int = _coverage[row + x]
			if value == 0:
				continue
			var index: int = (row + x) * 4
			if value == 255:
				_pixels[index] = red
				_pixels[index + 1] = green
				_pixels[index + 2] = blue
				_pixels[index + 3] = 255
				continue
			var amount: float = value / 255.0
			var base_red: int = _stroke_base[index]
			var base_green: int = _stroke_base[index + 1]
			var base_blue: int = _stroke_base[index + 2]
			var base_alpha: int = _stroke_base[index + 3]
			_pixels[index] = int(base_red + (red - base_red) * amount + 0.5)
			_pixels[index + 1] = int(base_green + (green - base_green) * amount + 0.5)
			_pixels[index + 2] = int(base_blue + (blue - base_blue) * amount + 0.5)
			_pixels[index + 3] = int(base_alpha + (255 - base_alpha) * amount + 0.5)

## Scanline flood fill from point. Pixels close to the clicked colour are
## filled. The ring of pixels just past them is the antialiased edge of a line:
## each is part line, part old colour, so it gets the new colour in that share,
## judged against its neighbour further out - no halo of the old colour stays.
func _flood_fill(point: Vector2, color: Color) -> bool:
	if !_is_inside_image(point):
		return false
	var seed_index: int = int(point.y) * _width + int(point.x)
	var seed_red: int = _pixels[seed_index * 4]
	var seed_green: int = _pixels[seed_index * 4 + 1]
	var seed_blue: int = _pixels[seed_index * 4 + 2]
	var seed_alpha: int = _pixels[seed_index * 4 + 3]
	var red: int = color.r8
	var green: int = color.g8
	var blue: int = color.b8
	if red == seed_red && green == seed_green && blue == seed_blue && seed_alpha == 255:
		return false
	var tolerance_squared: float = FILL_TOLERANCE * FILL_TOLERANCE
	var pixels: PackedByteArray = _pixels
	# 0 not visited, 1 filled, 2 an edge pixel already blended.
	var marks := PackedByteArray()
	marks.resize(_width * _height)
	var edge_pixels := PackedInt32Array()
	var stack := PackedInt32Array([seed_index])
	while !stack.is_empty():
		var start_index: int = stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		if marks[start_index] != 0:
			continue
		@warning_ignore("integer_division")
		var y: int = start_index / _width
		var row: int = y * _width
		var left: int = start_index - row
		var right: int = left
		# Grow the span left and right along the row.
		while left > 0:
			var i: int = (row + left - 1) * 4
			var dr: int = pixels[i] - seed_red
			var dg: int = pixels[i + 1] - seed_green
			var db: int = pixels[i + 2] - seed_blue
			var da: int = pixels[i + 3] - seed_alpha
			if marks[row + left - 1] != 0 || dr * dr + dg * dg + db * db + da * da > tolerance_squared:
				break
			left -= 1
		while right < _width - 1:
			var i: int = (row + right + 1) * 4
			var dr: int = pixels[i] - seed_red
			var dg: int = pixels[i + 1] - seed_green
			var db: int = pixels[i + 2] - seed_blue
			var da: int = pixels[i + 3] - seed_alpha
			if marks[row + right + 1] != 0 || dr * dr + dg * dg + db * db + da * da > tolerance_squared:
				break
			right += 1
		for x: int in range(left, right + 1):
			marks[row + x] = 1
		if left > 0 && marks[row + left - 1] == 0:
			edge_pixels.append(row + left - 1)
			edge_pixels.append(row + left)
		if right < _width - 1 && marks[row + right + 1] == 0:
			edge_pixels.append(row + right + 1)
			edge_pixels.append(row + right)
		# Seed the rows above and below: one start per run of matching pixels.
		for next_y: int in [y - 1, y + 1]:
			if next_y < 0 || next_y >= _height:
				continue
			var next_row: int = next_y * _width
			var in_run: bool = false
			for x: int in range(left, right + 1):
				var n: int = next_row + x
				if marks[n] != 0:
					in_run = false
					continue
				var i: int = n * 4
				var dr: int = pixels[i] - seed_red
				var dg: int = pixels[i + 1] - seed_green
				var db: int = pixels[i + 2] - seed_blue
				var da: int = pixels[i + 3] - seed_alpha
				if dr * dr + dg * dg + db * db + da * da <= tolerance_squared:
					if !in_run:
						stack.append(n)
						in_run = true
				else:
					in_run = false
					edge_pixels.append(n)
					edge_pixels.append(row + x)

	# Blend the edge ring before painting the fill, while the colours are the old ones.
	var edge_colors := PackedByteArray()
	var edge_targets := PackedInt32Array()
	for e: int in range(0, edge_pixels.size(), 2):
		var edge: int = edge_pixels[e]
		var inner: int = edge_pixels[e + 1]
		if marks[edge] != 0:
			continue
		marks[edge] = 2
		var outer: int = edge * 2 - inner
		if outer < 0 || outer >= _width * _height:
			continue
		# A horizontal step must stay on its row.
		@warning_ignore("integer_division")
		if absi(edge - inner) == 1 && outer / _width != edge / _width:
			continue
		var i: int = edge * 4
		var o: int = outer * 4
		var edge_distance: float = Vector4(pixels[i] - seed_red, pixels[i + 1] - seed_green, pixels[i + 2] - seed_blue, pixels[i + 3] - seed_alpha).length()
		var outer_distance: float = Vector4(pixels[o] - seed_red, pixels[o + 1] - seed_green, pixels[o + 2] - seed_blue, pixels[o + 3] - seed_alpha).length()
		if outer_distance <= edge_distance + 1.0:
			continue
		var old_share: float = 1.0 - edge_distance / outer_distance
		edge_targets.append(i)
		edge_colors.append(clampi(int(pixels[i] + (red - seed_red) * old_share + 0.5), 0, 255))
		edge_colors.append(clampi(int(pixels[i + 1] + (green - seed_green) * old_share + 0.5), 0, 255))
		edge_colors.append(clampi(int(pixels[i + 2] + (blue - seed_blue) * old_share + 0.5), 0, 255))
	for t: int in edge_targets.size():
		var i: int = edge_targets[t]
		pixels[i] = edge_colors[t * 3]
		pixels[i + 1] = edge_colors[t * 3 + 1]
		pixels[i + 2] = edge_colors[t * 3 + 2]

	for index: int in marks.size():
		if marks[index] == 1:
			var i: int = index * 4
			pixels[i] = red
			pixels[i + 1] = green
			pixels[i + 2] = blue
			pixels[i + 3] = 255
	_pixels = pixels
	return true

func _fill_pixels(color: Color) -> void:
	var filled: Image = Image.create_empty(_width, _height, false, Image.FORMAT_RGBA8)
	filled.fill(color)
	_pixels = filled.get_data()

func _clip_rect(rect: Rect2i) -> Rect2i:
	return rect.intersection(Rect2i(0, 0, _width, _height))

func _push_undo() -> void:
	_undo.append(_pixels.duplicate())
	if _undo.size() > MAX_UNDO_STEPS:
		_undo.pop_front()
	_redo.clear()

func _mark_changed() -> void:
	_texture_dirty = true
	image_changed.emit()

func _sync_texture() -> void:
	_texture_dirty = false
	image.set_data(_width, _height, false, Image.FORMAT_RGBA8, _pixels)
	image.generate_mipmaps()
	texture.update(image)
	queue_redraw()

# --- View and drawing --------------------------------------------------------

func _fit_scale() -> float:
	var available: Vector2 = size - Vector2.ONE * FIT_MARGIN * 2.0
	return maxf(minf(available.x / _width, available.y / _height), 0.05)

func _on_resized() -> void:
	if _view_is_fit:
		fit_view()
	else:
		_apply_view()

func _apply_view() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if view_scale >= PIXEL_ZOOM else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	overlay_root.position = view_offset
	overlay_root.size = Vector2(_width, _height) * view_scale
	queue_redraw()
	_cursor_layer.queue_redraw()
	view_changed.emit()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKDROP_COLOR)
	var image_rect: Rect2 = get_image_rect()
	draw_rect(image_rect.grow(1.0), IMAGE_EDGE_COLOR, false, 1.0)
	draw_texture_rect(texture, image_rect, false)
	if _active_tool in SHAPE_TOOLS:
		_draw_shape_preview()

## The shape being dragged, drawn as vectors until the button is let go.
func _draw_shape_preview() -> void:
	var color: Color = _stroke_color
	var width: float = maxf(brush_size * view_scale, 1.0)
	match _active_tool:
		Tool.LINE:
			var from: Vector2 = view_offset + _drag_start * view_scale
			var to: Vector2 = view_offset + _drag_end * view_scale
			draw_line(from, to, color, width, true)
			draw_circle(from, width * 0.5, color, true, -1.0, true)
			draw_circle(to, width * 0.5, color, true, -1.0, true)
		Tool.RECT:
			var rect: Rect2i = _shape_pixel_rect(_drag_start, _drag_end)
			var screen := Rect2(view_offset + Vector2(rect.position) * view_scale, Vector2(rect.size) * view_scale)
			if shapes_filled || rect.size.x <= brush_size * 2 || rect.size.y <= brush_size * 2:
				draw_rect(screen, color)
			else:
				var band: float = brush_size * view_scale
				draw_rect(Rect2(screen.position, Vector2(screen.size.x, band)), color)
				draw_rect(Rect2(screen.position + Vector2(0.0, screen.size.y - band), Vector2(screen.size.x, band)), color)
				draw_rect(Rect2(screen.position + Vector2(0.0, band), Vector2(band, screen.size.y - band * 2.0)), color)
				draw_rect(Rect2(screen.position + Vector2(screen.size.x - band, band), Vector2(band, screen.size.y - band * 2.0)), color)
		Tool.ELLIPSE:
			var rect: Rect2i = _shape_pixel_rect(_drag_start, _drag_end)
			var center: Vector2 = view_offset + (Vector2(rect.position) + Vector2(rect.size) * 0.5) * view_scale
			var axes: Vector2 = Vector2(rect.size) * 0.5 * view_scale
			var points := PackedVector2Array()
			var grow: float = width * 0.5 if shapes_filled else 0.0
			for i: int in 72:
				var angle: float = TAU * i / 72.0
				points.append(center + Vector2(cos(angle) * (axes.x + grow), sin(angle) * (axes.y + grow)))
			if shapes_filled:
				draw_colored_polygon(points, color)
			else:
				points.append(points[0])
				draw_polyline(points, color, width, true)

func _draw_cursor_layer() -> void:
	if !_mouse_inside || _panning:
		return
	if tool in STROKE_TOOLS || tool in SHAPE_TOOLS:
		var radius: float = maxf(brush_size * 0.5 * view_scale, 2.0)
		_cursor_layer.draw_arc(_mouse_position, radius + 1.0, 0.0, TAU, 48, Color(1, 1, 1, 0.7), 1.0, true)
		_cursor_layer.draw_arc(_mouse_position, radius, 0.0, TAU, 48, CURSOR_COLOR, 1.0, true)
