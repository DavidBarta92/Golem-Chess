@tool
extends EditorProperty

const GRID_SIZE: int = 5
const CardPatternGrid = preload("res://addons/card_pattern_editor/card_pattern_grid.gd")

var editor: VBoxContainer
var brush_picker: OptionButton
var grid
var is_updating: bool = false

func _init() -> void:
	editor = VBoxContainer.new()
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var toolbar: HBoxContainer = HBoxContainer.new()
	toolbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	brush_picker = OptionButton.new()
	brush_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brush_picker.tooltip_text = "Select the value painted by left click."
	brush_picker.add_item("Move + Capture", 1)
	brush_picker.add_item("Move Only", 2)
	brush_picker.add_item("Capture Only", 3)
	brush_picker.add_item("Empty", 0)
	brush_picker.select(0)
	brush_picker.item_selected.connect(_on_brush_selected)
	toolbar.add_child(brush_picker)

	var clear_button: Button = Button.new()
	clear_button.text = "Clear"
	clear_button.tooltip_text = "Clear the whole movement pattern."
	clear_button.pressed.connect(_on_clear_pressed)
	toolbar.add_child(clear_button)

	grid = CardPatternGrid.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.pattern_changed.connect(_on_pattern_changed)

	editor.add_child(toolbar)
	editor.add_child(grid)
	add_child(editor)
	add_focusable(grid)

func _update_property() -> void:
	var object: Object = get_edited_object()
	if object == null:
		return

	is_updating = true
	grid.set_pattern(_normalize_pattern(object.get(get_edited_property())))
	is_updating = false

func _on_brush_selected(index: int) -> void:
	grid.brush_value = brush_picker.get_item_id(index)

func _on_clear_pressed() -> void:
	grid.set_pattern(_create_empty_pattern())
	_on_pattern_changed(grid.get_pattern())

func _on_pattern_changed(pattern: Array) -> void:
	if is_updating:
		return

	emit_changed(get_edited_property(), _normalize_pattern(pattern))

func _normalize_pattern(value: Variant) -> Array:
	var normalized: Array = []

	for row_index in range(GRID_SIZE):
		var row: Array = []
		var source_row: Variant = []
		if value is Array && row_index < value.size():
			source_row = value[row_index]

		for col_index in range(GRID_SIZE):
			var cell_value: int = 0
			if source_row is Array && col_index < source_row.size():
				cell_value = clampi(int(source_row[col_index]), 0, 3)
			if row_index == 2 && col_index == 2:
				cell_value = 0
			row.append(cell_value)

		normalized.append(row)

	return normalized

func _create_empty_pattern() -> Array:
	var pattern: Array = []
	for row_index in range(GRID_SIZE):
		var row: Array = []
		for col_index in range(GRID_SIZE):
			row.append(0)
		pattern.append(row)
	return pattern
