extends Control

## A standalone trial of the in-game stamp painter (Scenes/StampPainter/
## StampPainter.tscn, run it with F6). A drawing is another art for an existing
## stamp: the canvas is the size of the stamps' art, the mask guide shows what
## the stamp will hide, and the preview is a real StampVisual showing the
## drawing as the stamp's art.
##
## Drawings are saved as PNG to DRAWINGS_FOLDER under the user's Documents, one
## file per drawing, named after the stamp's code. --drawings-dir=<path> after
## `--` on the command line saves somewhere else (test runs).
##
## The texts are Hungarian only while this is a trial; they move to
## Localization/translations.csv when the painter goes into the game.

const PaintCanvas = preload("res://Scripts/StampPainter/PaintCanvas.gd")
const Palette = preload("res://Scripts/StampPainter/StampPainterPalette.gd")
const GUIDE_SHADER = preload("res://Shaders/stamp_painter_guide.gdshader")
const STAMP_VISUAL_SCENE = preload("res://Scenes/StampVisual.tscn")

const DRAWINGS_FOLDER: String = "Golem Chess/Drawings"
const DRAWINGS_DIR_ARGUMENT: String = "--drawings-dir="
const PREVIEW_SCALE: float = 1.15
const SWATCH_SIZE := Vector2(18, 18)
const SWATCH_BORDER := Color("#66594a")  # UiPalette.INK_SOFT
const GUIDE_SHADE := Color("#172c43")  # UiPalette.INK
## StampVisual's parts that the guide's markings leave out: the paper, the
## coloured square, the art and the frame (the guide shader draws the frame).
const MARKINGS_HIDDEN_PARTS: Array[String] = ["Shadow", "StampFace", "StampSquare", "StampArt", "TypeFrame", "Shimmer", "FoilTint", "FoilShine"]

const TOOLS: Array = [
	[PaintCanvas.Tool.PENCIL, "Ceruza", KEY_P],
	[PaintCanvas.Tool.BRUSH, "Ecset", KEY_B],
	[PaintCanvas.Tool.ERASER, "Radír", KEY_E],
	[PaintCanvas.Tool.FILL, "Kitöltés", KEY_G],
	[PaintCanvas.Tool.LINE, "Vonal", KEY_L],
	[PaintCanvas.Tool.RECT, "Téglalap", KEY_R],
	[PaintCanvas.Tool.ELLIPSE, "Ellipszis", KEY_O],
	[PaintCanvas.Tool.PICKER, "Színválasztó", KEY_I],
]

@onready var canvas: PaintCanvas = %Canvas
@onready var stamp_picker: OptionButton = %StampPicker
@onready var new_button: Button = %NewButton
@onready var original_button: Button = %OriginalButton
@onready var open_button: Button = %OpenButton
@onready var save_button: Button = %SaveButton
@onready var folder_button: Button = %FolderButton
@onready var tool_buttons_box: VBoxContainer = %ToolButtons
@onready var size_label: Label = %SizeLabel
@onready var size_slider: HSlider = %SizeSlider
@onready var fill_shapes_box: CheckBox = %FillShapes
@onready var undo_button: Button = %UndoButton
@onready var redo_button: Button = %RedoButton
@onready var fit_button: Button = %FitButton
@onready var preview_holder: Control = %PreviewHolder
@onready var palette_grid: GridContainer = %Palette
@onready var ink_swatch: Panel = %InkSwatch
@onready var paper_swatch: Panel = %PaperSwatch
@onready var swap_button: Button = %SwapButton
@onready var guide_toggle: CheckButton = %GuideToggle
@onready var markings_toggle: CheckBox = %MarkingsToggle
@onready var guide_strength: HSlider = %GuideStrength
@onready var status_label: Label = %Status

var stamp_code: String = ""
var preview: StampVisual
var markings: StampVisual
var guide: ColorRect
var guide_material: ShaderMaterial
var tool_buttons: Dictionary = {}  # tool -> Button
## The file the drawing was last opened from or saved to, and the stamp it was for.
var current_file: String = ""
var current_file_stamp: String = ""
var unsaved: bool = false
var cursor_text: String = ""
var message: String = ""
var open_dialog: FileDialog

func _ready() -> void:
	canvas.palette = Palette.all_colors()
	canvas.ink_color = Palette.ink(Palette.DEFAULT_PAIR)
	canvas.paper_color = Palette.paper(Palette.DEFAULT_PAIR)
	canvas.reset_canvas()
	_build_tool_buttons()
	_build_palette()
	_build_guide()
	_build_preview()
	_fill_stamp_picker()
	_connect_controls()
	for button: BaseButton in find_children("*", "BaseButton", true, false):
		button.focus_mode = Control.FOCUS_NONE
	_on_tool_changed(canvas.tool)
	_on_colors_changed()
	_on_brush_size_changed(canvas.brush_size)
	_update_history_buttons()
	unsaved = false
	message = "Mentés helye: %s" % _drawings_dir()
	_update_status()

func _connect_controls() -> void:
	canvas.tool_changed.connect(_on_tool_changed)
	canvas.colors_changed.connect(_on_colors_changed)
	canvas.brush_size_changed.connect(_on_brush_size_changed)
	canvas.image_changed.connect(_on_image_changed)
	canvas.cursor_moved.connect(_on_cursor_moved)
	canvas.overlay_root.resized.connect(_layout_markings)
	stamp_picker.item_selected.connect(_on_stamp_selected)
	new_button.pressed.connect(_on_new_pressed)
	original_button.pressed.connect(_on_original_pressed)
	open_button.pressed.connect(_on_open_pressed)
	save_button.pressed.connect(_save)
	folder_button.pressed.connect(_open_folder)
	size_slider.value_changed.connect(func(value: float) -> void: canvas.set_brush_size(int(value)))
	fill_shapes_box.toggled.connect(func(on: bool) -> void: canvas.shapes_filled = on)
	undo_button.pressed.connect(_undo)
	redo_button.pressed.connect(_redo)
	fit_button.pressed.connect(canvas.fit_view)
	swap_button.pressed.connect(canvas.swap_colors)
	guide_toggle.toggled.connect(func(_on: bool) -> void: _apply_guide_look())
	markings_toggle.toggled.connect(func(_on: bool) -> void: _apply_guide_look())
	guide_strength.value_changed.connect(func(_value: float) -> void: _apply_guide_look())

# --- Building the panels -----------------------------------------------------

func _build_tool_buttons() -> void:
	var group := ButtonGroup.new()
	for entry: Array in TOOLS:
		var button := Button.new()
		button.text = "%s  (%s)" % [entry[1], OS.get_keycode_string(entry[2])]
		button.toggle_mode = true
		button.button_group = group
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var tool_id: int = entry[0]
		button.pressed.connect(func() -> void: canvas.set_tool(tool_id))
		tool_buttons_box.add_child(button)
		tool_buttons[tool_id] = button

## Two rows, one column per pair: the inks above, their papers below.
func _build_palette() -> void:
	palette_grid.columns = Palette.PAIRS.size()
	for row: int in 2:
		for index: int in Palette.PAIRS.size():
			var color: Color = Palette.ink(index) if row == 0 else Palette.paper(index)
			var swatch := Panel.new()
			swatch.custom_minimum_size = SWATCH_SIZE
			swatch.tooltip_text = "%s  (%s)" % [color.to_html(false), Palette.PAIRS[index][2]]
			swatch.add_theme_stylebox_override("panel", _swatch_style(color))
			swatch.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			swatch.gui_input.connect(_on_swatch_input.bind(color))
			palette_grid.add_child(swatch)

func _swatch_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = SWATCH_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	return style

func _build_guide() -> void:
	guide = ColorRect.new()
	guide.name = "Guide"
	guide.color = Color.WHITE
	guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guide.set_anchors_preset(Control.PRESET_FULL_RECT)
	guide_material = ShaderMaterial.new()
	guide_material.shader = GUIDE_SHADER
	guide_material.set_shader_parameter("art_size", Vector2(PaintCanvas.IMAGE_SIZE))
	guide_material.set_shader_parameter("shade_color", GUIDE_SHADE)
	guide.material = guide_material
	canvas.overlay_root.add_child(guide)

	# The stamp's name, number and pattern as the stamp prints them over the art.
	markings = STAMP_VISUAL_SCENE.instantiate() as StampVisual
	canvas.overlay_root.add_child(markings)
	_make_display_only(markings)

func _build_preview() -> void:
	preview = STAMP_VISUAL_SCENE.instantiate() as StampVisual
	preview_holder.add_child(preview)
	_make_display_only(preview)
	preview.scale = Vector2.ONE * PREVIEW_SCALE
	preview_holder.custom_minimum_size = preview.size * PREVIEW_SCALE

func _make_display_only(visual: StampVisual) -> void:
	visual.draggable = false
	visual.disabled = true
	visual.set_hover_raise_enabled(false)
	visual.pivot_offset = Vector2.ZERO
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Control in visual.find_children("*", "Control", true, false):
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _fill_stamp_picker() -> void:
	var stamps: Array = StampLibrary.all_stamps.values()
	stamps.sort_custom(_stamp_sorts_before)
	var first_with_art: int = -1
	for stamp: Stamp in stamps:
		var code: String = _code_of(stamp)
		stamp_picker.add_item("%s  ·  %s" % [stamp.stamp_name, stamp.Set])
		stamp_picker.set_item_metadata(stamp_picker.item_count - 1, code)
		if first_with_art < 0 && _original_art(code) != null:
			first_with_art = stamp_picker.item_count - 1
	if stamp_picker.item_count > 0:
		var start: int = maxi(first_with_art, 0)
		stamp_picker.select(start)
		_on_stamp_selected(start)

## By set, then by name.
static func _stamp_sorts_before(a: Stamp, b: Stamp) -> bool:
	if a.Set != b.Set:
		return a.Set < b.Set
	return a.stamp_name.naturalnocasecmp_to(b.stamp_name) < 0

# --- The stamp ---------------------------------------------------------------

func _on_stamp_selected(index: int) -> void:
	stamp_code = str(stamp_picker.get_item_metadata(index))
	preview.set_stamp_print(_drawing_print(canvas.texture))
	markings.set_stamp_print(_drawing_print(null))
	# Applying a stamp makes a StampVisual clickable again.
	_make_display_only(preview)
	_make_display_only(markings)
	for part_name: String in MARKINGS_HIDDEN_PARTS:
		var part := markings.get_node_or_null(part_name) as CanvasItem
		if part != null:
			part.visible = false
	# StampVisual knows which mask and frame a stamp's role has.
	guide_material.set_shader_parameter("type_mask_texture", markings._get_type_mask_texture())
	guide_material.set_shader_parameter("type_frame_texture", markings._get_type_frame_texture())
	guide_material.set_shader_parameter("stamp_size", markings.size)
	original_button.disabled = _original_art(stamp_code) == null
	_layout_markings()
	_apply_guide_look()
	_update_status()

## The drawing as one of the stamp's prints, in memory only.
func _drawing_print(art: Texture2D) -> StampPrint:
	var drawing := StampPrint.new()
	drawing.print_id = "%s.drawing" % stamp_code
	drawing.stamp_code = stamp_code
	drawing.variant_id = StampPrintLibrary.STANDARD_VARIANT_ID
	drawing.variant_name = "Drawing"
	drawing.stamp_art = art
	return drawing

func _original_art(code: String) -> Texture2D:
	var standard: StampPrint = StampPrintLibrary.get_print(StampPrintLibrary.get_default_print_id_for_stamp_code(code))
	if standard != null && standard.stamp_art != null:
		return standard.stamp_art
	var stamp: Stamp = StampLibrary.get_stamp_by_code(code)
	return stamp.stamp_art if stamp != null else null

func _code_of(stamp: Stamp) -> String:
	var code: String = stamp.stamp_code.strip_edges()
	return code if !code.is_empty() else stamp.stamp_name

## The markings stand where the stamp stands over the art: the art covers the
## stamp and is cropped in the middle, so the stamp is as tall as the art.
func _layout_markings() -> void:
	if markings == null:
		return
	var art_rect: Vector2 = canvas.overlay_root.size
	var stamp_size: Vector2 = markings.size
	if art_rect.y <= 0.0 || stamp_size.y <= 0.0:
		return
	var art_aspect: float = art_rect.x / art_rect.y
	var stamp_aspect: float = stamp_size.x / stamp_size.y
	var stamp_scale: float = art_rect.y / stamp_size.y if art_aspect >= stamp_aspect else art_rect.x / stamp_size.x
	markings.pivot_offset = Vector2.ZERO
	markings.scale = Vector2.ONE * stamp_scale
	markings.position = (art_rect - stamp_size * stamp_scale) * 0.5

func _apply_guide_look() -> void:
	var strength: float = guide_strength.value
	guide.visible = guide_toggle.button_pressed
	markings.visible = guide_toggle.button_pressed && markings_toggle.button_pressed
	guide_material.set_shader_parameter("shade_alpha", strength)
	guide_material.set_shader_parameter("frame_alpha", 1.0)
	markings.modulate.a = clampf(strength + 0.25, 0.0, 1.0)

# --- Canvas feedback ---------------------------------------------------------

func _on_tool_changed(new_tool: int) -> void:
	# button_pressed (not set_pressed_no_signal) lets the group release the others;
	# it emits toggled only, and the buttons listen to pressed.
	if tool_buttons.has(new_tool):
		(tool_buttons[new_tool] as Button).button_pressed = true
	_update_status()

func _on_colors_changed() -> void:
	ink_swatch.add_theme_stylebox_override("panel", _swatch_style(canvas.ink_color))
	paper_swatch.add_theme_stylebox_override("panel", _swatch_style(canvas.paper_color))

func _on_brush_size_changed(new_size: int) -> void:
	size_label.text = "Méret: %d px" % new_size
	size_slider.set_value_no_signal(new_size)
	_update_status()

func _on_image_changed() -> void:
	unsaved = true
	_update_history_buttons()
	_update_status()

func _on_cursor_moved(image_position: Vector2i, inside: bool) -> void:
	cursor_text = "%d, %d" % [image_position.x, image_position.y] if inside else ""
	_update_status()

func _on_swatch_input(event: InputEvent, color: Color) -> void:
	var button := event as InputEventMouseButton
	if button == null || !button.pressed:
		return
	if button.button_index == MOUSE_BUTTON_LEFT:
		canvas.set_ink_color(color)
	elif button.button_index == MOUSE_BUTTON_RIGHT:
		canvas.set_paper_color(color)

func _update_history_buttons() -> void:
	undo_button.disabled = !canvas.can_undo()
	redo_button.disabled = !canvas.can_redo()

func _update_status() -> void:
	if status_label == null:
		return
	var parts: PackedStringArray = []
	if !cursor_text.is_empty():
		parts.append(cursor_text)
	var file_text: String = current_file.get_file() if !current_file.is_empty() else "új rajz"
	parts.append(file_text + (" *" if unsaved else ""))
	if !message.is_empty():
		parts.append(message)
	status_label.text = "   ·   ".join(parts)

func _undo() -> void:
	canvas.undo()
	_update_history_buttons()

func _redo() -> void:
	canvas.redo()
	_update_history_buttons()

# --- Files -------------------------------------------------------------------

func _drawings_dir() -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(DRAWINGS_DIR_ARGUMENT):
			return argument.trim_prefix(DRAWINGS_DIR_ARGUMENT)
	var documents: String = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if documents.is_empty():
		return ProjectSettings.globalize_path("user://drawings")
	return documents.path_join(DRAWINGS_FOLDER)

func _on_new_pressed() -> void:
	canvas.clear_canvas()
	current_file = ""
	message = "Új rajz (Vissza: Ctrl+Z)"
	_update_status()

func _on_original_pressed() -> void:
	var art: Texture2D = _original_art(stamp_code)
	if art == null:
		return
	canvas.load_image(art.get_image())
	current_file = ""
	message = "A bélyeg eredeti rajza betöltve"
	_update_status()

func _on_open_pressed() -> void:
	if open_dialog == null:
		open_dialog = FileDialog.new()
		open_dialog.title = "Rajz megnyitása"
		open_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		open_dialog.access = FileDialog.ACCESS_FILESYSTEM
		open_dialog.filters = PackedStringArray(["*.png ; PNG"])
		open_dialog.use_native_dialog = true
		open_dialog.file_selected.connect(_open_file)
		add_child(open_dialog)
	var directory: String = _drawings_dir()
	DirAccess.make_dir_recursive_absolute(directory)
	open_dialog.current_dir = directory
	open_dialog.popup_centered_ratio(0.6)

func _open_file(path: String) -> void:
	var loaded: Image = Image.load_from_file(path)
	if loaded == null || loaded.is_empty():
		message = "Nem sikerült megnyitni: %s" % path.get_file()
		_update_status()
		return
	canvas.load_image(loaded)
	_select_stamp_for_file(path)
	current_file = path
	current_file_stamp = stamp_code
	unsaved = false
	message = "Megnyitva"
	_update_status()

## A drawing is named <stamp code>_<number>.png; picking the stamp back from it.
func _select_stamp_for_file(path: String) -> void:
	var base: String = path.get_file().get_basename()
	var separator: int = base.rfind("_")
	if separator <= 0:
		return
	var code: String = base.substr(0, separator)
	for index: int in stamp_picker.item_count:
		if str(stamp_picker.get_item_metadata(index)).to_lower() == code:
			stamp_picker.select(index)
			_on_stamp_selected(index)
			return

func _save() -> void:
	var directory: String = _drawings_dir()
	var error: Error = DirAccess.make_dir_recursive_absolute(directory)
	if error != OK:
		message = "Nem sikerült létrehozni a mappát: %s" % directory
		_update_status()
		return
	var path: String = current_file
	if path.is_empty() || current_file_stamp != stamp_code:
		path = _next_free_path(directory)
	error = canvas.get_image_copy().save_png(path)
	if error != OK:
		message = "Nem sikerült menteni (%s)" % error_string(error)
		_update_status()
		return
	current_file = path
	current_file_stamp = stamp_code
	unsaved = false
	message = "Elmentve: %s" % path
	_update_status()

func _next_free_path(directory: String) -> String:
	var name_base: String = _file_safe(stamp_code)
	var number: int = 1
	while FileAccess.file_exists(directory.path_join("%s_%02d.png" % [name_base, number])):
		number += 1
	return directory.path_join("%s_%02d.png" % [name_base, number])

func _file_safe(text: String) -> String:
	var safe: String = ""
	for character: String in text.to_lower():
		safe += character if (character >= "a" && character <= "z") || (character >= "0" && character <= "9") || character == "-" else "_"
	return safe if !safe.is_empty() else "stamp"

func _open_folder() -> void:
	var directory: String = _drawings_dir()
	DirAccess.make_dir_recursive_absolute(directory)
	if !current_file.is_empty() && FileAccess.file_exists(current_file):
		OS.shell_show_in_file_manager(current_file)
	else:
		OS.shell_open(directory)

# --- Keys --------------------------------------------------------------------

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null:
		return
	if key.keycode == KEY_SPACE:
		canvas.set_space_held(key.pressed)
		get_viewport().set_input_as_handled()
		return
	if !key.pressed || key.echo && key.keycode not in [KEY_BRACKETLEFT, KEY_BRACKETRIGHT]:
		return
	var handled: bool = true
	if key.ctrl_pressed:
		match key.keycode:
			KEY_Z:
				if key.shift_pressed:
					_redo()
				else:
					_undo()
			KEY_Y:
				_redo()
			KEY_S:
				_save()
			KEY_O:
				_on_open_pressed()
			KEY_N:
				_on_new_pressed()
			_:
				handled = false
	else:
		handled = _handle_plain_key(key.keycode)
	if handled:
		get_viewport().set_input_as_handled()

func _handle_plain_key(keycode: Key) -> bool:
	for entry: Array in TOOLS:
		if entry[2] == keycode:
			canvas.set_tool(entry[0])
			return true
	match keycode:
		KEY_X:
			canvas.swap_colors()
		KEY_M:
			guide_toggle.button_pressed = !guide_toggle.button_pressed
		KEY_F:
			canvas.fit_view()
		KEY_BRACKETLEFT:
			canvas.set_brush_size(canvas.brush_size - _size_step())
		KEY_BRACKETRIGHT:
			canvas.set_brush_size(canvas.brush_size + _size_step())
		_:
			return false
	return true

## [ and ] change the size by about an eighth, at least by one pixel.
func _size_step() -> int:
	return maxi(1, roundi(canvas.brush_size / 8.0))
