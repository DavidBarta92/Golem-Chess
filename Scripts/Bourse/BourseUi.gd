extends RefCounted

## Small pieces the Bourse screen builds from: stamps in cells, a lot's sheet,
## pills, bars, the coin price. Nothing here knows about the store.

const STAMP_VISUAL = preload("res://Scenes/StampVisual.tscn")
const PORTRAIT_VIEW = preload("res://Scenes/PortraitView.tscn")
const COIN_TEXTURE: Texture2D = preload("res://Assets/coin.svg")
const FADE_SHADER = preload("res://Shaders/collection_unowned_stamp.gdshader")
const InkStampMaterial = preload("res://Scripts/InkStamp/InkStampMaterial.gd")
const STAMP_SIZE: Vector2 = Vector2(168.7, 229)
## A faded stamp: one left out of a pick, or with no copy left to put on a lot.
const FADED_OPACITY: float = 0.4
const SHEET_GAP: int = 6
const PILL_HEIGHT: float = 18.0
## Where the head sits across a portrait's picture strip.
const PORTRAIT_HEAD_X: float = 0.385

static var _fade_material: ShaderMaterial

## A stamp drawn at the size of `cell_size`, centred, still and deaf to the
## mouse. The cell holds it as meta "stamp_visual". An empty id gives an empty cell.
static func stamp_cell(print_id: String, cell_size: Vector2, face_down: bool = false, faded: bool = false) -> Control:
	var cell := Control.new()
	cell.custom_minimum_size = cell_size
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stamp_print: StampPrint = StampPrintLibrary.get_print(print_id) if !print_id.is_empty() else null
	if stamp_print == null:
		return cell
	var visual := STAMP_VISUAL.instantiate() as StampVisual
	var holder: Node = cell
	if faded:
		holder = fade_group()
		cell.add_child(holder)
	holder.add_child(visual)
	visual.custom_minimum_size = STAMP_SIZE
	visual.size = STAMP_SIZE
	visual.pivot_offset = STAMP_SIZE * 0.5
	visual.set_hover_raise_enabled(false)
	visual.set_stamp_print(stamp_print)
	visual.set_face_down(face_down)
	visual.set_collection_owned(true)
	var scale_factor: float = minf(cell_size.x / STAMP_SIZE.x, cell_size.y / STAMP_SIZE.y)
	visual.set_rest_scale(Vector2.ONE * scale_factor)
	visual.scale = Vector2.ONE * scale_factor
	visual.draggable = false
	visual.disabled = true
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.position = (cell_size - STAMP_SIZE) * 0.5
	visual.home_position = visual.position
	if face_down:
		# The stamp's own back is paper on paper here; an ink back reads as a
		# card waiting to be turned. It turns with the stamp, being its child.
		var back := StampBack.new()
		back.name = "BourseBack"
		visual.add_child(back)
	cell.set_meta("stamp_visual", visual)
	return cell

## The stamp flattened first, then faded as a whole, so its layers do not show
## through each other (as the album's unowned stamps are).
static func fade_group() -> CanvasGroup:
	if _fade_material == null:
		_fade_material = ShaderMaterial.new()
		_fade_material.shader = FADE_SHADER
		_fade_material.set_shader_parameter("opacity", FADED_OPACITY)
		_fade_material.set_shader_parameter("saturation", 1.0)
	var group := CanvasGroup.new()
	group.material = _fade_material
	return group

## A lot's sheet: a paper card with a double rule, three stamps over two.
## `print_ids` shorter than five leaves empty places, drawn as dashed boxes
## with a plus when `show_empty` is set. `on_pressed(index)`, when valid, makes
## each filled place a button. `faded` and `highlight` are indices.
static func lot_sheet(print_ids: Array, cell_size: Vector2, show_empty: bool = false, on_pressed: Callable = Callable(), faded: Array = [], highlight: int = -1, title: String = "") -> PanelContainer:
	var outer := PanelContainer.new()
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_theme_stylebox_override("panel", _rule_style(UiPalette.PAPER_RAISED, 5))
	var inner := PanelContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_stylebox_override("panel", _rule_style(Color(0, 0, 0, 0), 10))
	outer.add_child(inner)
	var rows := VBoxContainer.new()
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation", SHEET_GAP)
	rows.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_child(rows)
	if !title.is_empty():
		var title_label := label(title, &"KickerLabel")
		title_label.uppercase = true
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rows.add_child(title_label)
	for row_range in [[0, 3], [3, 5]]:
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", SHEET_GAP)
		rows.add_child(row)
		for index in range(row_range[0], row_range[1]):
			var print_id: String = str(print_ids[index]) if index < print_ids.size() else ""
			if print_id.is_empty():
				row.add_child(empty_slot(cell_size) if show_empty else spacer(cell_size))
				continue
			var cell: Control = stamp_cell(print_id, cell_size, false, faded.has(index))
			if index == highlight:
				cell.add_child(_highlight_frame(cell_size))
			if on_pressed.is_valid():
				cell.add_child(click_area(on_pressed.bind(index)))
			row.add_child(cell)
	return outer

static func empty_slot(cell_size: Vector2) -> Control:
	var slot := DashedBox.new()
	slot.custom_minimum_size = cell_size
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.show_plus = true
	return slot

static func spacer(min_size: Vector2) -> Control:
	var control := Control.new()
	control.custom_minimum_size = min_size
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return control

## A see-through button over a whole cell.
static func click_area(on_pressed: Callable) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"BareButton"
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(on_pressed)
	# A StampVisual is a Button too; this tells the two apart.
	button.set_meta("click_area", true)
	return button

static func label(text: String, variation: StringName = &"", wrap: bool = false) -> Label:
	var result := Label.new()
	result.text = text
	if variation != &"":
		result.theme_type_variation = variation
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return result

## A coin and its amount, side by side.
static func coin_amount(amount: int, variation: StringName = &"NumberLabel", icon_size: float = 18.0, prefix: String = "") -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 5)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(coin_icon(icon_size))
	row.add_child(label("%s%d" % [prefix, amount], variation))
	return row

static func coin_icon(icon_size: float) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = COIN_TEXTURE
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon

## "2 pcs" on an ink pill, as under the album's stamps.
static func count_pill(count: int) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = UiPalette.INK
	style.set_corner_radius_all(int(PILL_HEIGHT * 0.5))
	style.corner_detail = 12
	style.content_margin_left = 8
	style.content_margin_right = 8
	pill.add_theme_stylebox_override("panel", style)
	pill.custom_minimum_size = Vector2(0, PILL_HEIGHT)
	var text := label(TranslationServer.translate("%d pcs") % count, &"FieldLabel")
	text.add_theme_color_override("font_color", UiPalette.PAPER_RAISED)
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_child(text)
	InkStampMaterial.apply(pill, true)
	return pill

## A small portrait in a square ink frame, still. The portrait's picture is a
## wide strip (PortraitView.PICTURE_SIZE) with the head in its middle, so the
## picture is zoomed in on the head and the view's own clip cuts the rest. (A
## clipping parent around the view instead leaves it blank: its picture is a
## CanvasGroup.)
static func portrait(seed_value: int, display_name: String, side: float) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(side, side)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = UiPalette.PAPER_SHADE
	style.border_color = UiPalette.INK
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(2)
	frame.add_theme_stylebox_override("panel", style)
	var config: PortraitConfig = PortraitLibrary.create_random_portrait(seed_value)
	config.display_name = display_name
	var view := PORTRAIT_VIEW.instantiate() as PortraitView
	view.animation_enabled = false
	view.show_frame = false
	view.show_background = true
	view.background_color = UiPalette.PAPER_SHADE
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.portrait_config = config
	view.custom_minimum_size = Vector2(side - 4.0, side - 4.0)
	frame.add_child(view)
	# The view fits the whole strip on every resize; zoom in after it.
	view.ready.connect(_zoom_portrait.bind(view), CONNECT_DEFERRED | CONNECT_ONE_SHOT)
	view.resized.connect(_zoom_portrait.bind(view), CONNECT_DEFERRED)
	return frame

## The strip's height a quarter taller than the frame, the head (at about
## PORTRAIT_HEAD_X of the strip's width, not its middle) in the middle: the
## head fills the frame.
static func _zoom_portrait(view: PortraitView) -> void:
	if !is_instance_valid(view) or view.picture_group == null:
		return
	var inner: Vector2 = view.size
	var picture: Vector2 = PortraitView.PICTURE_SIZE
	var scale_factor: float = inner.y * 1.25 / picture.y
	view.picture_group.scale = Vector2.ONE * scale_factor
	view.picture_group.position = Vector2(inner.x * 0.5 - picture.x * scale_factor * PORTRAIT_HEAD_X, 0.0)

static func _rule_style(fill: Color, padding: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = UiPalette.INK
	style.set_border_width_all(1)
	style.set_content_margin_all(padding)
	return style

static func _highlight_frame(cell_size: Vector2) -> Panel:
	var frame := Panel.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = UiPalette.INK
	style.set_border_width_all(3)
	style.set_corner_radius_all(2)
	frame.add_theme_stylebox_override("panel", style)
	frame.position = Vector2(-4, -4)
	frame.size = cell_size + Vector2(8, 8)
	return frame


## The back of a stamp to be picked: ink inside the perforated edge, a star in
## a ring, the game's name.
class StampBack extends Control:
	const INSET: Vector2 = Vector2(17, 19)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = STAMP_SIZE
		custom_minimum_size = STAMP_SIZE

	func _draw() -> void:
		var inner := Rect2(INSET, size - INSET * 2.0)
		draw_rect(inner, UiPalette.INK)
		var centre: Vector2 = inner.get_center() - Vector2(0, 14)
		draw_arc(centre, 34.0, 0.0, TAU, 48, UiPalette.PAPER_RAISED, 2.0, true)
		var star := PackedVector2Array()
		for i in range(10):
			var radius: float = 15.0 if i % 2 == 0 else 6.5
			var angle: float = -PI * 0.5 + i * PI / 5.0
			star.append(centre + Vector2(cos(angle), sin(angle)) * radius)
		star.append(star[0])
		draw_polyline(star, UiPalette.PAPER_RAISED, 2.0, true)
		var font: Font = get_theme_default_font()
		var text: String = "GOLEM"
		var font_size: int = 18
		var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(font, Vector2(inner.get_center().x - width * 0.5, centre.y + 62.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiPalette.PAPER_RAISED)


## An empty place on a sheet: a dashed outline, a plus in the middle.
class DashedBox extends Control:
	var show_plus: bool = false

	func _draw() -> void:
		var rect := Rect2(Vector2(1, 1), size - Vector2(2, 2))
		var corners: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
		for i in range(4):
			draw_dashed_line(corners[i], corners[(i + 1) % 4], UiPalette.INK_SOFT, 1.0, 4.0)
		if show_plus:
			var centre: Vector2 = size * 0.5
			draw_line(centre - Vector2(6, 0), centre + Vector2(6, 0), UiPalette.INK, 1.5)
			draw_line(centre - Vector2(0, 6), centre + Vector2(0, 6), UiPalette.INK, 1.5)


## The chance at the next buyer: a track and its ink fill.
class ChanceBar extends Control:
	var value: float = 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(0, 9)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var track := StyleBoxFlat.new()
		track.bg_color = UiPalette.PAPER_RAISED
		track.border_color = UiPalette.INK
		track.set_border_width_all(1)
		track.set_corner_radius_all(2)
		draw_style_box(track, Rect2(Vector2.ZERO, size))
		if value > 0.0:
			draw_rect(Rect2(Vector2(1, 1), Vector2((size.x - 2.0) * clampf(value, 0.0, 1.0), size.y - 2.0)), UiPalette.INK)


## Five bars for how much the buyers want a lot.
class AttractionBars extends Control:
	var level: int = 0

	func _init() -> void:
		custom_minimum_size = Vector2(5 * 26 + 4 * 5, 10)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		for i in range(5):
			var rect := Rect2(Vector2(i * 31.0, 0.0), Vector2(26.0, size.y))
			var style := StyleBoxFlat.new()
			style.bg_color = UiPalette.INK if i < level else UiPalette.PAPER_RAISED
			style.border_color = UiPalette.INK
			style.set_border_width_all(1)
			style.set_corner_radius_all(2)
			draw_style_box(style, rect)


## A clock face for the countdowns.
class ClockIcon extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(16, 16)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var centre: Vector2 = size * 0.5
		var radius: float = minf(size.x, size.y) * 0.5 - 1.0
		draw_arc(centre, radius, 0.0, TAU, 32, UiPalette.INK, 1.5, true)
		draw_line(centre, centre + Vector2(0, -radius * 0.6), UiPalette.INK, 1.5, true)
		draw_line(centre, centre + Vector2(radius * 0.45, 0), UiPalette.INK, 1.5, true)


## A tick in an ink circle: this stamp is on the lot.
class CheckBadge extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(22, 22)
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var centre: Vector2 = size * 0.5
		draw_circle(centre, size.x * 0.5, UiPalette.INK)
		draw_polyline(PackedVector2Array([centre + Vector2(-5, 0), centre + Vector2(-1.5, 3.5), centre + Vector2(5, -4)]), UiPalette.PAPER_RAISED, 2.0, true)
