@tool
extends EditorProperty

# The read-only "Becsült érték" field of a Stamp: the live estimate and its breakdown. Any edit,
# undo or redo (of this stamp or of the weights) and any reload from disk recalculates it; the
# plugin writes the result to Stamp.estimated_value.

const StampValueTools = preload("res://addons/stamp_value_estimator/stamp_value_tools.gd")

var value_label: Label
var breakdown_label: RichTextLabel

func _init() -> void:
	value_label = Label.new()
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(value_label)

	var details: VBoxContainer = VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	breakdown_label = RichTextLabel.new()
	breakdown_label.bbcode_enabled = true
	breakdown_label.fit_content = true
	breakdown_label.scroll_active = false
	breakdown_label.selection_enabled = true
	breakdown_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_child(breakdown_label)

	var weights_button: LinkButton = LinkButton.new()
	weights_button.text = "Súlyok hangolása"
	weights_button.tooltip_text = StampValueCalculator.DEFAULT_WEIGHTS_PATH
	weights_button.pressed.connect(_on_weights_pressed)
	details.add_child(weights_button)

	add_child(details)
	set_bottom_editor(details)

func _enter_tree() -> void:
	EditorInterface.get_editor_undo_redo().version_changed.connect(_refresh)
	EditorInterface.get_resource_filesystem().resources_reload.connect(_on_resources_reload)

func _exit_tree() -> void:
	EditorInterface.get_editor_undo_redo().version_changed.disconnect(_refresh)
	EditorInterface.get_resource_filesystem().resources_reload.disconnect(_on_resources_reload)

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		value_label.add_theme_font_override(&"font", get_theme_font(&"bold", &"EditorFonts"))

func _update_property() -> void:
	_refresh()

func _refresh() -> void:
	var stamp: Stamp = get_edited_object() as Stamp
	if stamp == null:
		return

	var weights: StampValueWeights = StampValueCalculator.load_weights()
	_render(stamp, StampValueCalculator.calculate(stamp, weights), weights)

func _render(stamp: Stamp, breakdown: StampValueCalculator.Breakdown, weights: StampValueWeights) -> void:
	value_label.text = "%.2f" % breakdown.total

	var lines: PackedStringArray = PackedStringArray()
	for line in StampValueTools.describe(breakdown):
		lines.append(_escape_bbcode(line))
	# The plugin stores the new value a frame later, or after the weights are saved.
	if StampValueTools.is_stale(stamp, breakdown):
		var pending_text: String = "a súlyok mentésekor frissül" if StampValueTools.are_weights_unsaved(weights) else "frissül"
		lines.append("Mentett érték: %.2f (%s)" % [stamp.estimated_value, pending_text])
	var warning_color: String = get_theme_color(&"warning_color", &"Editor").to_html(false)
	for warning in StampValueTools.warning_lines(breakdown):
		lines.append("[color=#%s]⚠ %s[/color]" % [warning_color, _escape_bbcode(warning)])

	breakdown_label.text = "\n".join(lines)
	draw_warning = breakdown.has_warnings()

func _on_resources_reload(_paths: PackedStringArray) -> void:
	_refresh()

func _on_weights_pressed() -> void:
	EditorInterface.edit_resource(StampValueCalculator.load_weights())

func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]")
