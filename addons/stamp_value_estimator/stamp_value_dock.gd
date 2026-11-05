@tool
extends EditorDock

# Overview of every stamp under res://Stamps: a table sortable by any column title, a set
# filter, per-set averages, and a target band that colors the values outside it. Double-click
# a row to open the stamp. The visible rows can be exported to CSV.

const StampValueTools = preload("res://addons/stamp_value_estimator/stamp_value_tools.gd")
const StampValueSelftest = preload("res://addons/stamp_value_estimator/stamp_value_selftest.gd")

enum Column { NAME, SET, ROLE, DURATION, MOVEMENT, EFFECT, TOTAL }

const COLUMN_TITLES: Array = ["Név", "Kaszt", "Szerep", "Időtartam", "M", "E", "Összérték"]
const NUMBER_COLUMNS: Array = [Column.DURATION, Column.MOVEMENT, Column.EFFECT, Column.TOTAL]
const AVERAGE_TITLES: Array = ["Kaszt", "Bélyeg", "Átlagérték", "Átl. időtartam", "Ütésarány", "Távoli arány"]
const ALL_SETS_LABEL: String = "Mind"
const TOTAL_ROW_LABEL: String = "Összes"
const DEFAULT_TARGET: float = 20.0
const DEFAULT_TOLERANCE_PERCENT: float = 15.0
const REFRESH_DELAY: float = 0.2
const METADATA_SECTION: String = "stamp_value_estimator"
const CSV_FILE_NAME: String = "stamp_values.csv"

# {stamp: Stamp, breakdown: StampValueCalculator.Breakdown} for every stamp, unfiltered.
var rows: Array[Dictionary] = []
var stamps: Array[Stamp] = []
var stamps_dirty: bool = true
var refresh_pending: bool = false
var sort_column: int = Column.TOTAL
var sort_descending: bool = true

var set_filter: OptionButton
var target_input: SpinBox
var tolerance_input: SpinBox
var split: SplitContainer
var table: Tree
var averages: Tree
var status_label: Label
var refresh_timer: Timer
var csv_dialog: EditorFileDialog
var selftest_dialog: AcceptDialog

func _init() -> void:
	title = "Bélyegértékek"
	layout_key = "StampValueEstimator"
	default_slot = DOCK_SLOT_BOTTOM
	available_layouts = DOCK_LAYOUT_ALL

	var content: VBoxContainer = VBoxContainer.new()
	add_child(content)

	var toolbar: HFlowContainer = HFlowContainer.new()
	content.add_child(toolbar)

	toolbar.add_child(_make_label("Kaszt:"))
	set_filter = OptionButton.new()
	set_filter.tooltip_text = "Csak a kiválasztott kaszt bélyegei a táblázatban."
	set_filter.add_item(ALL_SETS_LABEL)
	set_filter.item_selected.connect(_on_set_filter_selected)
	toolbar.add_child(set_filter)

	toolbar.add_child(_make_label("Célérték:"))
	target_input = SpinBox.new()
	target_input.max_value = 1000.0
	target_input.step = 0.1
	target_input.value = DEFAULT_TARGET
	target_input.value_changed.connect(_on_band_changed)
	toolbar.add_child(target_input)

	toolbar.add_child(_make_label("Tolerancia:"))
	tolerance_input = SpinBox.new()
	tolerance_input.max_value = 100.0
	tolerance_input.step = 1.0
	tolerance_input.prefix = "±"
	tolerance_input.suffix = "%"
	tolerance_input.value = DEFAULT_TOLERANCE_PERCENT
	tolerance_input.value_changed.connect(_on_band_changed)
	toolbar.add_child(tolerance_input)

	toolbar.add_child(_make_button("Frissítés", "A bélyegek újraolvasása és az értékek újraszámolása.", _on_reload_pressed))
	toolbar.add_child(_make_button("Értékek mentése", "Az elavult becsült értékek kiírása a bélyegekre most. A plugin magától is megteszi minden szerkesztés és mentés után.", _on_save_values_pressed))
	toolbar.add_child(_make_button("CSV export", "A táblázat látható sorainak mentése CSV-be.", _on_export_pressed))
	toolbar.add_child(_make_button("Önteszt", "A képlet ellenőrzése a referencia-bélyegekkel, alapsúlyokkal.", _on_selftest_pressed))

	split = SplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(split)

	table = _make_tree(COLUMN_TITLES)
	table.set_column_expand_ratio(Column.NAME, 2)
	table.column_title_clicked.connect(_on_column_title_clicked)
	table.item_activated.connect(_on_item_activated)
	split.add_child(table)

	var averages_box: VBoxContainer = VBoxContainer.new()
	averages_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	averages_box.add_child(_make_label("Kasztonkénti átlagok"))
	averages = _make_tree(AVERAGE_TITLES)
	averages.select_mode = Tree.SELECT_SINGLE
	averages_box.add_child(averages)
	split.add_child(averages_box)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(status_label)

	refresh_timer = Timer.new()
	refresh_timer.one_shot = true
	refresh_timer.wait_time = REFRESH_DELAY
	refresh_timer.timeout.connect(_refresh)
	add_child(refresh_timer)

	csv_dialog = EditorFileDialog.new()
	csv_dialog.title = "Bélyegértékek exportálása"
	csv_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	csv_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	csv_dialog.filters = PackedStringArray(["*.csv ; CSV"])
	csv_dialog.file_selected.connect(_export_csv)
	add_child(csv_dialog)

	selftest_dialog = AcceptDialog.new()
	selftest_dialog.title = "Bélyegérték önteszt"
	add_child(selftest_dialog)

	visibility_changed.connect(_on_visibility_changed)

func _ready() -> void:
	var settings: EditorSettings = EditorInterface.get_editor_settings()
	target_input.set_value_no_signal(float(settings.get_project_metadata(METADATA_SECTION, "target", DEFAULT_TARGET)))
	tolerance_input.set_value_no_signal(float(settings.get_project_metadata(METADATA_SECTION, "tolerance_percent", DEFAULT_TOLERANCE_PERCENT)))
	request_refresh(true)

func _enter_tree() -> void:
	EditorInterface.get_editor_undo_redo().version_changed.connect(request_refresh)
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(_on_filesystem_changed)
	EditorInterface.get_resource_filesystem().resources_reload.connect(_on_resources_reload)

func _exit_tree() -> void:
	EditorInterface.get_editor_undo_redo().version_changed.disconnect(request_refresh)
	EditorInterface.get_resource_filesystem().filesystem_changed.disconnect(_on_filesystem_changed)
	EditorInterface.get_resource_filesystem().resources_reload.disconnect(_on_resources_reload)

func _update_layout(layout: int) -> void:
	split.vertical = layout == DOCK_LAYOUT_VERTICAL

# Coalesces bursts of edits (dragging a spin box commits on every step) into one refresh,
# and waits with it while the dock is hidden.
func request_refresh(reload_stamps: bool = false) -> void:
	if reload_stamps:
		stamps_dirty = true
	if !is_visible_in_tree():
		refresh_pending = true
		return
	refresh_timer.start()

func _refresh() -> void:
	if stamps_dirty:
		stamps = StampValueTools.load_stamps()
		stamps_dirty = false

	var weights: StampValueWeights = StampValueCalculator.load_weights()
	rows.clear()
	for stamp in stamps:
		rows.append({
			"stamp": stamp,
			"breakdown": StampValueCalculator.calculate(stamp, weights),
		})

	_rebuild_set_filter()
	_render()

func _rebuild_set_filter() -> void:
	var selected_set: String = _get_selected_set()
	var set_names: PackedStringArray = PackedStringArray()
	for row in rows:
		var set_name: String = row.stamp.Set
		if !set_names.has(set_name):
			set_names.append(set_name)
	set_names.sort()

	set_filter.clear()
	set_filter.add_item(ALL_SETS_LABEL)
	for set_name in set_names:
		set_filter.add_item(set_name)
	set_filter.select(set_names.find(selected_set) + 1)

func _get_selected_set() -> String:
	if set_filter.selected <= 0:
		return ""
	return set_filter.get_item_text(set_filter.selected)

func _render() -> void:
	var band: Vector2 = _get_band()
	var visible_rows: Array[Dictionary] = _get_visible_rows()
	_render_table(visible_rows, band)
	_render_averages(band)
	_render_status(visible_rows, band)

func _get_band() -> Vector2:
	var tolerance: float = tolerance_input.value / 100.0
	return Vector2(target_input.value * (1.0 - tolerance), target_input.value * (1.0 + tolerance))

# The filtered rows in the current sort order.
func _get_visible_rows() -> Array[Dictionary]:
	var selected_set: String = _get_selected_set()
	var visible_rows: Array[Dictionary] = []
	for row in rows:
		if selected_set.is_empty() || row.stamp.Set == selected_set:
			visible_rows.append(row)
	visible_rows.sort_custom(_compare_rows)
	return visible_rows

func _compare_rows(a: Dictionary, b: Dictionary) -> bool:
	var key_a: Variant = _get_sort_key(a)
	var key_b: Variant = _get_sort_key(b)
	if key_a == key_b:
		return a.stamp.stamp_name.naturalnocasecmp_to(b.stamp.stamp_name) < 0
	if sort_descending:
		return key_a > key_b
	return key_a < key_b

func _get_sort_key(row: Dictionary) -> Variant:
	var stamp: Stamp = row.stamp
	var breakdown: StampValueCalculator.Breakdown = row.breakdown
	match sort_column:
		Column.NAME:
			return stamp.stamp_name.to_lower()
		Column.SET:
			return stamp.Set.to_lower()
		Column.ROLE:
			return StampValueTools.role_name(stamp.role).to_lower()
		Column.DURATION:
			return breakdown.duration
		Column.MOVEMENT:
			return breakdown.movement
		Column.EFFECT:
			return breakdown.effect_part
	return breakdown.total

func _render_table(visible_rows: Array[Dictionary], band: Vector2) -> void:
	for column in range(COLUMN_TITLES.size()):
		var column_title: String = COLUMN_TITLES[column]
		if column == sort_column:
			column_title += " ▼" if sort_descending else " ▲"
		table.set_column_title(column, column_title)

	table.clear()
	var root: TreeItem = table.create_item()
	for row in visible_rows:
		var stamp: Stamp = row.stamp
		var breakdown: StampValueCalculator.Breakdown = row.breakdown
		var item: TreeItem = table.create_item(root)
		item.set_metadata(Column.NAME, stamp)
		item.set_text(Column.NAME, stamp.stamp_name)
		item.set_text(Column.SET, stamp.Set)
		item.set_text(Column.ROLE, StampValueTools.role_name(stamp.role))
		item.set_text(Column.DURATION, "∞" if breakdown.is_infinite_duration else str(stamp.duration))
		item.set_text(Column.MOVEMENT, "%.2f" % breakdown.movement)
		item.set_text(Column.EFFECT, "%.2f" % breakdown.effect_part)
		item.set_text(Column.TOTAL, "%.2f" % breakdown.total)
		for column in NUMBER_COLUMNS:
			item.set_text_alignment(column, HORIZONTAL_ALIGNMENT_RIGHT)
		_color_by_band(item, Column.TOTAL, breakdown.total, band)

		var tooltip: String = "%s\n\n%s" % ["\n".join(StampValueTools.describe(breakdown)), stamp.resource_path]
		if !stamp.enabled:
			item.set_custom_color(Column.NAME, get_theme_color(&"font_disabled_color", &"Editor"))
			tooltip = "Kikapcsolt bélyeg (enabled = false).\n\n" + tooltip
		if breakdown.has_warnings():
			item.set_icon(Column.NAME, get_theme_icon(&"NodeWarning", &"EditorIcons"))
			item.set_custom_color(Column.NAME, get_theme_color(&"warning_color", &"Editor"))
			tooltip = "%s\n\n%s" % ["\n".join(StampValueTools.warning_lines(breakdown)), tooltip]
		for column in range(COLUMN_TITLES.size()):
			item.set_tooltip_text(column, tooltip)

func _render_averages(band: Vector2) -> void:
	var groups: Dictionary = {}
	var all_stamps: Dictionary = _make_group()
	for row in rows:
		var set_name: String = row.stamp.Set
		if !groups.has(set_name):
			groups[set_name] = _make_group()
		_add_to_group(groups[set_name], row.breakdown)
		_add_to_group(all_stamps, row.breakdown)

	averages.clear()
	var root: TreeItem = averages.create_item()
	var set_names: Array = groups.keys()
	set_names.sort()
	for set_name in set_names:
		_add_average_item(root, set_name, groups[set_name], band)
	if !rows.is_empty():
		_add_average_item(root, TOTAL_ROW_LABEL, all_stamps, band)

func _make_group() -> Dictionary:
	return {"count": 0, "value": 0.0, "duration": 0.0, "cells": 0, "capture_cells": 0, "far_cells": 0}

func _add_to_group(group: Dictionary, breakdown: StampValueCalculator.Breakdown) -> void:
	group.count += 1
	group.value += breakdown.total
	group.duration += breakdown.duration
	group.cells += breakdown.cell_count
	group.capture_cells += breakdown.capture_cell_count
	group.far_cells += breakdown.far_cell_count

# The ratios pool the cells of the whole set: c and X cells, and outer ring cells, over every reachable cell.
func _add_average_item(root: TreeItem, set_name: String, group: Dictionary, band: Vector2) -> void:
	var average_value: float = group.value / group.count
	var item: TreeItem = averages.create_item(root)
	item.set_text(0, set_name)
	item.set_text(1, str(group.count))
	item.set_text(2, "%.2f" % average_value)
	item.set_text(3, "%.2f" % (group.duration / group.count))
	item.set_text(4, _format_ratio(group.capture_cells, group.cells))
	item.set_text(5, _format_ratio(group.far_cells, group.cells))
	for column in range(1, AVERAGE_TITLES.size()):
		item.set_text_alignment(column, HORIZONTAL_ALIGNMENT_RIGHT)
	_color_by_band(item, 2, average_value, band)
	if set_name == TOTAL_ROW_LABEL:
		item.set_custom_bg_color(0, get_theme_color(&"dark_color_2", &"Editor"))

func _format_ratio(part: int, whole: int) -> String:
	if whole == 0:
		return "–"
	return "%.0f%%" % (100.0 * part / whole)

func _color_by_band(item: TreeItem, column: int, value: float, band: Vector2) -> void:
	if value > band.y:
		item.set_custom_color(column, get_theme_color(&"error_color", &"Editor"))
	elif value < band.x:
		item.set_custom_color(column, get_theme_color(&"accent_color", &"Editor"))

func _render_status(visible_rows: Array[Dictionary], band: Vector2) -> void:
	var above: int = 0
	var below: int = 0
	var warnings: int = 0
	for row in visible_rows:
		var breakdown: StampValueCalculator.Breakdown = row.breakdown
		if breakdown.total > band.y:
			above += 1
		elif breakdown.total < band.x:
			below += 1
		if breakdown.has_warnings():
			warnings += 1

	var stale: int = 0
	for row in rows:
		if StampValueTools.is_stale(row.stamp, row.breakdown):
			stale += 1

	var parts: PackedStringArray = PackedStringArray()
	var count_text: String = "%d bélyeg" % visible_rows.size()
	if visible_rows.size() != rows.size():
		count_text = "%d / %d bélyeg" % [visible_rows.size(), rows.size()]
	parts.append(count_text)
	parts.append("sáv: %.2f – %.2f" % [band.x, band.y])
	parts.append("%d a sáv felett (piros), %d alatta (kék)" % [above, below])
	if warnings > 0:
		parts.append("%d figyelmeztetés" % warnings)
	if stale == 0:
		parts.append("minden mentett érték naprakész")
	elif StampValueTools.are_weights_unsaved(StampValueCalculator.load_weights()):
		parts.append("%d bélyeg mentett értéke a súlyok mentésekor frissül" % stale)
	else:
		parts.append("%d bélyeg mentett értéke elavult" % stale)
	status_label.text = " · ".join(parts)

func _on_column_title_clicked(column: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	if column == sort_column:
		sort_descending = !sort_descending
	else:
		sort_column = column
		# Names read best A to Z, numbers largest first.
		sort_descending = NUMBER_COLUMNS.has(column)
	_render()

func _on_item_activated() -> void:
	var item: TreeItem = table.get_selected()
	if item == null:
		return
	var stamp: Stamp = item.get_metadata(Column.NAME) as Stamp
	if stamp != null:
		EditorInterface.edit_resource(stamp)

func _on_set_filter_selected(_index: int) -> void:
	_render()

func _on_band_changed(_value: float) -> void:
	var settings: EditorSettings = EditorInterface.get_editor_settings()
	settings.set_project_metadata(METADATA_SECTION, "target", target_input.value)
	settings.set_project_metadata(METADATA_SECTION, "tolerance_percent", tolerance_input.value)
	_render()

func _on_visibility_changed() -> void:
	if is_visible_in_tree() && refresh_pending:
		refresh_pending = false
		refresh_timer.start()

func _on_filesystem_changed() -> void:
	request_refresh(true)

func _on_resources_reload(_paths: PackedStringArray) -> void:
	request_refresh()

func _on_reload_pressed() -> void:
	request_refresh(true)

func _on_save_values_pressed() -> void:
	StampValueTools.report(StampValueTools.sync_stamps(StampValueTools.load_stamps()))
	request_refresh()

func _on_export_pressed() -> void:
	var default_path: String = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join(CSV_FILE_NAME)
	csv_dialog.current_path = EditorInterface.get_editor_settings().get_project_metadata(METADATA_SECTION, "csv_path", default_path)
	csv_dialog.popup_file_dialog()

func _export_csv(path: String) -> void:
	var toaster: EditorToaster = EditorInterface.get_editor_toaster()
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		toaster.push_toast("Bélyegértékek: nem sikerült írni: %s (%s)" % [path, error_string(FileAccess.get_open_error())], EditorToaster.SEVERITY_ERROR)
		return

	var band: Vector2 = _get_band()
	var visible_rows: Array[Dictionary] = _get_visible_rows()
	file.store_csv_line(PackedStringArray([
		"name", "code", "set", "role", "enabled", "duration", "M", "T(D)", "S", "movement_part",
		"R", "E", "total", "band", "cells", "capture_cells", "far_cells", "effect_type", "effect_trigger",
		"stored_value", "warnings", "path",
	]))
	for row in visible_rows:
		var stamp: Stamp = row.stamp
		var breakdown: StampValueCalculator.Breakdown = row.breakdown
		var band_label: String = "in"
		if breakdown.total > band.y:
			band_label = "above"
		elif breakdown.total < band.x:
			band_label = "below"
		file.store_csv_line(PackedStringArray([
			stamp.stamp_name,
			stamp.stamp_code,
			stamp.Set,
			StampValueTools.role_name(stamp.role),
			str(stamp.enabled),
			str(stamp.duration),
			"%.4f" % breakdown.movement,
			"%.4f" % breakdown.duration_factor,
			"%.4f" % breakdown.role_factor,
			"%.4f" % breakdown.movement_part,
			"%.4f" % breakdown.role_part,
			"%.4f" % breakdown.effect_part,
			"%.4f" % breakdown.total,
			band_label,
			str(breakdown.cell_count),
			str(breakdown.capture_cell_count),
			str(breakdown.far_cell_count),
			stamp.effect_type,
			stamp.effect_trigger,
			"%.2f" % stamp.estimated_value,
			" ".join(StampValueTools.warning_lines(breakdown)),
			stamp.resource_path,
		]))
	file.close()

	EditorInterface.get_editor_settings().set_project_metadata(METADATA_SECTION, "csv_path", path)
	toaster.push_toast("Bélyegértékek: %d sor exportálva: %s" % [visible_rows.size(), path])
	# Godot imports a .csv inside the project as translations.
	if path.to_lower().begins_with(ProjectSettings.globalize_path("res://").to_lower()):
		toaster.push_toast("A projekt mappájába mentett CSV-t a Godot fordításként importálja, érdemes a projekten kívülre menteni.", EditorToaster.SEVERITY_WARNING)

func _on_selftest_pressed() -> void:
	var lines: PackedStringArray = PackedStringArray()
	var all_passed: bool = true
	for result in StampValueSelftest.run():
		lines.append(StampValueSelftest.describe(result))
		all_passed = all_passed && result.passed
	lines.insert(0, "Minden referencia-bélyeg rendben (alapsúlyok).\n" if all_passed else "Van eltérés a referenciaértékektől (alapsúlyok).\n")
	selftest_dialog.dialog_text = "\n".join(lines)
	selftest_dialog.popup_centered()

func _make_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	return label

func _make_button(text: String, tooltip: String, on_pressed: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.pressed.connect(on_pressed)
	return button

func _make_tree(titles: Array) -> Tree:
	var tree: Tree = Tree.new()
	tree.columns = titles.size()
	tree.column_titles_visible = true
	tree.hide_root = true
	tree.select_mode = Tree.SELECT_ROW
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.custom_minimum_size = Vector2(0.0, 120.0) * EditorInterface.get_editor_scale()
	for column in range(titles.size()):
		tree.set_column_title(column, titles[column])
		tree.set_column_clip_content(column, true)
	return tree
