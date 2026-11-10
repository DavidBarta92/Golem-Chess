extends Control
class_name PuzzleHud

## What a puzzle's board shows on top of the match's own interface: the task
## in the top left corner with the moves used and the way out, and when it
## fails, why, in the middle. A solved puzzle goes on to the reward scene.

signal restart_requested
signal leave_requested

const MARGIN: float = 24.0
const TASK_WIDTH: float = 300.0
const RESULT_WIDTH: float = 380.0
const FADE_SECONDS: float = 0.4

var puzzle: PuzzleDefinition
var _task_panel: PanelContainer
var _moves_label: Label
var _result_layer: Control

func _init(hud_puzzle: PuzzleDefinition = null) -> void:
	puzzle = hud_puzzle
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_task_panel()

func fade_in() -> void:
	_task_panel.modulate.a = 0.0
	_task_panel.visible = true
	create_tween().tween_property(_task_panel, "modulate:a", 1.0, FADE_SECONDS)

## "Move 1 of 2" while it is on; the moves are the player's turns.
func set_moves(used: int, limit: int) -> void:
	_moves_label.text = tr("PUZZLE_MOVES") % [mini(used + 1, limit), limit]

func set_moves_text(text: String) -> void:
	_moves_label.text = text

func _build_task_panel() -> void:
	_task_panel = PanelContainer.new()
	_task_panel.visible = false
	_task_panel.add_theme_stylebox_override("panel", PuzzleUi.panel_style())
	_task_panel.position = Vector2(MARGIN, MARGIN)
	_task_panel.custom_minimum_size = Vector2(TASK_WIDTH, 0)
	add_child(_task_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_task_panel.add_child(column)
	var kicker: String = tr("PUZZLE_KICKER").to_upper()
	if puzzle != null:
		kicker += "  ·  " + puzzle.get_sender_name().to_upper()
	column.add_child(PuzzleUi.label(kicker, &"KickerLabel", UiPalette.INK_SOFT))
	var task := PuzzleUi.label(tr(puzzle.task) if puzzle != null else "", &"TitleLabel")
	task.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	task.custom_minimum_size = Vector2(TASK_WIDTH - 36.0, 0)
	column.add_child(task)
	_moves_label = PuzzleUi.label("", &"CaptionLabel", UiPalette.INK_SOFT)
	column.add_child(_moves_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	column.add_child(buttons)
	buttons.add_child(_button(tr("PUZZLE_RESTART"), restart_requested.emit))
	buttons.add_child(_button(tr("PUZZLE_BACK_TO_LETTERS"), leave_requested.emit))

## The UI's own button: an outline that fills with ink under the mouse.
func _button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 38)
	button.pressed.connect(on_pressed)
	return button

# --- The result -----------------------------------------------------------------

## Failed: why, and the way to try again.
func show_failed(reason: String) -> void:
	_show_result(tr("PUZZLE_FAILED_TITLE"), [reason])

func hide_result() -> void:
	if _result_layer != null:
		_result_layer.queue_free()
		_result_layer = null

func _show_result(title: String, lines: Array[String]) -> void:
	hide_result()
	_result_layer = Control.new()
	_result_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_result_layer)
	_result_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.35)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_layer.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centre := CenterContainer.new()
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_layer.add_child(centre)
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", PuzzleUi.panel_style())
	panel.custom_minimum_size = Vector2(RESULT_WIDTH, 0)
	centre.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var heading := PuzzleUi.label(title, &"DisplayLabel")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	for line in lines:
		var words := PuzzleUi.label(line)
		words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.custom_minimum_size = Vector2(RESULT_WIDTH - 36.0, 0)
		column.add_child(words)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	buttons.add_child(_button(tr("PUZZLE_TRY_AGAIN"), restart_requested.emit))
	buttons.add_child(_button(tr("PUZZLE_BACK_TO_LETTERS"), leave_requested.emit))

	panel.modulate.a = 0.0
	panel.pivot_offset = Vector2(RESULT_WIDTH * 0.5, 120)
	panel.scale = Vector2.ONE * 0.94
	var tween := create_tween().set_parallel()
	tween.tween_property(panel, "modulate:a", 1.0, FADE_SECONDS)
	tween.tween_property(panel, "scale", Vector2.ONE, FADE_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
