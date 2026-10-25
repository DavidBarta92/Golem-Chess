extends Control

## The menu button at the right end of the bar and its dropdown of the game's
## general commands, in groups: the temporary developer entries (Alpha
## Multiplayer, in a group of their own so they come out in one piece) ·
## Settings, Tutorial · Exit. The dropdown hangs from the button's right edge.
## Closes on a second click, on choosing an item, and when the top bar sees a
## click elsewhere or Esc.

signal item_pressed(item_id: String)
signal opened

const TopBarStyle = preload("res://Scripts/TopBar/TopBarStyle.gd")
const TOP_BAR_ICON_SCRIPT = preload("res://Scripts/TopBar/TopBarIcon.gd")

const ROW_PADDING: float = 12.0
const ROW_ICON_GAP: int = 9
const GROUP_GAP: float = 4.5

var button: Button
var _button_icon: Control
var _dropdown: PanelContainer
var _groups: Array[VBoxContainer] = []
var _separators: Array[Control] = []
var _items: Dictionary = {}
## Each row's content box, to size the row to it.
var _row_contents: Dictionary = {}
var _open: bool = false
var _tween: Tween

func _init() -> void:
	name = "Menu"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2.ONE * TopBarStyle.BUTTON_SIZE
	size = custom_minimum_size

	button = Button.new()
	button.name = "MenuButton"
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.size = custom_minimum_size
	button.tooltip_text = "TOPBAR_MENU"
	button.toggled.connect(_on_button_toggled)
	button.draw.connect(_sync_button_icon)
	add_child(button)
	_button_icon = TOP_BAR_ICON_SCRIPT.new("menu", TopBarStyle.ICON_STAT, TopBarStyle.INK)
	_button_icon.position = (custom_minimum_size - _button_icon.custom_minimum_size) * 0.5
	_button_icon.size = _button_icon.custom_minimum_size
	button.add_child(_button_icon)

	_dropdown = PanelContainer.new()
	_dropdown.name = "Dropdown"
	_dropdown.visible = false
	_dropdown.mouse_filter = Control.MOUSE_FILTER_STOP
	_dropdown.custom_minimum_size = Vector2(TopBarStyle.MENU_WIDTH, 0.0)
	_dropdown.theme_type_variation = &"TopBarDropdown"
	_dropdown.resized.connect(_align_dropdown)
	add_child(_dropdown)

	var rows := VBoxContainer.new()
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation", 0)
	_dropdown.add_child(rows)
	for group_index in range(3):
		if group_index > 0:
			var separator := _Separator.new()
			rows.add_child(separator)
			_separators.append(separator)
		var group := VBoxContainer.new()
		group.mouse_filter = Control.MOUSE_FILTER_IGNORE
		group.add_theme_constant_override("separation", 0)
		rows.add_child(group)
		_groups.append(group)

## Adds a row: group 0 is the temporary developer group, 1 the general
## commands, 2 the way out. tag_key adds a dashed "temporary" style label.
func add_item(group_index: int, item_id: String, icon_name: String, label_key: String, tag_key: String = "") -> Button:
	var row := Button.new()
	row.name = "%sItem" % item_id.capitalize().replace(" ", "")
	row.focus_mode = Control.FOCUS_NONE
	row.custom_minimum_size = Vector2(0.0, TopBarStyle.MENU_ROW)
	row.theme_type_variation = &"TopBarMenuRow"

	var content := HBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", ROW_ICON_GAP)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = ROW_PADDING
	content.offset_right = -ROW_PADDING
	row.add_child(content)
	var icon = TOP_BAR_ICON_SCRIPT.new(icon_name, TopBarStyle.ICON_MENU, TopBarStyle.INK)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content.add_child(icon)
	var label := TopBarStyle.make_label(label_key, &"TopBarMenuItemLabel")
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(label)
	if !tag_key.is_empty():
		var tag := _Tag.new(tag_key)
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		content.add_child(tag)
	_row_contents[row] = content
	content.minimum_size_changed.connect(_fit_rows)

	row.pressed.connect(_on_item_pressed.bind(item_id))
	_groups[clampi(group_index, 0, _groups.size() - 1)].add_child(row)
	_items[item_id] = row
	_fit_rows()
	_refresh_groups()
	return row

## A row is a Button, which does not size itself to its children. Run again
## on opening: while the dropdown is hidden, translated labels do not report
## their new size.
func _fit_rows() -> void:
	for row in _row_contents:
		row.custom_minimum_size.x = _row_contents[row].get_combined_minimum_size().x + ROW_PADDING * 2.0
	_dropdown.reset_size()

## Keeps the dropdown hanging from the button's right edge whatever its width.
func _align_dropdown() -> void:
	_dropdown.position.x = TopBarStyle.BUTTON_SIZE - _dropdown.size.x

func get_item(item_id: String) -> Button:
	return _items.get(item_id, null) as Button

func set_item_visible(item_id: String, item_visible: bool) -> void:
	var row: Button = get_item(item_id)
	if row == null:
		return
	row.visible = item_visible
	_refresh_groups()

func is_open() -> bool:
	return _open

func set_open(open: bool) -> void:
	if open == _open:
		return
	_open = open
	button.set_pressed_no_signal(open)
	_sync_button_icon()
	if _tween != null and _tween.is_valid():
		_tween.kill()

	# Wider than MENU_WIDTH only if a row needs it.
	var rest_y: float = TopBarStyle.BUTTON_SIZE + TopBarStyle.MENU_DROP_GAP
	_tween = create_tween()
	_tween.set_parallel(true)
	if open:
		_dropdown.modulate.a = 0.0
		_dropdown.visible = true
		_fit_rows()
		_align_dropdown()
		_dropdown.position.y = rest_y - 3.0
		_tween.tween_property(_dropdown, "modulate:a", 1.0, TopBarStyle.MENU_IN_SECONDS).set_ease(Tween.EASE_OUT)
		_tween.tween_property(_dropdown, "position:y", rest_y, TopBarStyle.MENU_IN_SECONDS).set_ease(Tween.EASE_OUT)
		opened.emit()
	else:
		_tween.tween_property(_dropdown, "modulate:a", 0.0, TopBarStyle.MENU_OUT_SECONDS)
		_tween.tween_property(_dropdown, "position:y", rest_y - 3.0, TopBarStyle.MENU_OUT_SECONDS)
		_tween.chain().tween_callback(_dropdown.hide)

func close_now() -> void:
	set_open(false)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_dropdown.visible = false

## True over the button or the open dropdown - what an outside click is not.
func contains_global_point(point: Vector2) -> bool:
	if !is_visible_in_tree():
		return false
	if button.get_global_rect().has_point(point):
		return true
	return _dropdown.visible and _dropdown.get_global_rect().has_point(point)

## The glyph is a child, not the button's icon, so it follows the button's
## label colour by hand: paper on the pressed button, the inactive colour
## while out of use, and through the hover's ink fill (InkHoverFill), which
## tints the label as the ink comes in.
func _sync_button_icon() -> void:
	var colour: StringName = &"font_color"
	if button.disabled:
		colour = &"font_disabled_color"
	elif button.button_pressed:
		colour = &"font_pressed_color"
	elif button.is_hovered():
		colour = &"font_hover_color"
	_button_icon.color = button.get_theme_color(colour)

func _on_button_toggled(pressed: bool) -> void:
	set_open(pressed)

func _on_item_pressed(item_id: String) -> void:
	set_open(false)
	item_pressed.emit(item_id)

## A group shows only with a visible row in it; a separator only between two shown groups.
func _refresh_groups() -> void:
	var any_shown_before: bool = false
	for group_index in range(_groups.size()):
		var group: VBoxContainer = _groups[group_index]
		var has_visible_row: bool = false
		for row in group.get_children():
			if (row as Control).visible:
				has_visible_row = true
				break
		group.visible = has_visible_row
		if group_index > 0:
			_separators[group_index - 1].visible = has_visible_row and any_shown_before
		any_shown_before = any_shown_before or has_visible_row
	_dropdown.reset_size()

## The thin rule between two groups.
class _Separator:
	extends Control

	func _init() -> void:
		custom_minimum_size = Vector2(0.0, GROUP_GAP * 2.0 + 1.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var y: float = floorf(size.y * 0.5) + 0.5
		draw_line(Vector2(0.0, y), Vector2(size.x, y), TopBarStyle.LINE_SOFT, 1.0)

## A small dashed pill label, e.g. "TEMPORARY".
class _Tag:
	extends MarginContainer

	const DASH: float = 3.0
	const GAP: float = 2.0
	const LINE_WIDTH: float = 1.5

	func _init(text_key: String) -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_theme_constant_override("margin_left", 7)
		add_theme_constant_override("margin_right", 7)
		add_theme_constant_override("margin_top", 0)
		add_theme_constant_override("margin_bottom", 0)
		var label := TopBarStyle.make_label(text_key, &"TopBarTagLabel")
		label.uppercase = true
		label.custom_minimum_size = Vector2(0.0, 16.0)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(label)

	func _draw() -> void:
		var radius: float = (size.y - LINE_WIDTH) * 0.5
		var left := Vector2(radius + LINE_WIDTH * 0.5, size.y * 0.5)
		var right := Vector2(size.x - radius - LINE_WIDTH * 0.5, size.y * 0.5)
		# The pill's outline as one path: top edge, right cap, bottom edge, left cap.
		var path := PackedVector2Array([left + Vector2(0.0, -radius), right + Vector2(0.0, -radius)])
		for step in range(1, 13):
			path.append(right + Vector2.from_angle(-PI * 0.5 + PI * step / 12.0) * radius)
		path.append(left + Vector2(0.0, radius))
		for step in range(1, 13):
			path.append(left + Vector2.from_angle(PI * 0.5 + PI * step / 12.0) * radius)

		var drawing: bool = true
		var left_in_run: float = DASH
		for index in range(path.size() - 1):
			var from: Vector2 = path[index]
			var to: Vector2 = path[index + 1]
			var length: float = from.distance_to(to)
			var travelled: float = 0.0
			while travelled < length:
				var run: float = minf(left_in_run, length - travelled)
				var start: Vector2 = from.lerp(to, travelled / length)
				var end: Vector2 = from.lerp(to, (travelled + run) / length)
				if drawing:
					draw_line(start, end, TopBarStyle.INK_SOFT, LINE_WIDTH, true)
				travelled += run
				left_in_run -= run
				if left_in_run <= 0.0:
					drawing = !drawing
					left_in_run = DASH if drawing else GAP
