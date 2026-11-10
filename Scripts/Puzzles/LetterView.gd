extends Control
class_name LetterView

## The letter out of an envelope (Docs/Letters, "Megnyitott levél"): the
## greeting, the body, the signature in a hand, and at the foot the puzzle -
## a sketch of its board, the task, what it pays, and the button that takes
## the player to it.

signal solve_requested

## The mock-up's 600 x 590 at 1440, on the 1280 base.
const LETTER_SIZE: Vector2 = Vector2(533, 524)
const PAPER: Color = Color("#fbf7ec")
const FOLD_LINE: Color = Color("#ebe2cc")
const FOOT_RULE: Color = Color("#cfc4a8")
const SKETCH_PAPER: Color = Color("#f4ecd8")
const SKETCH_SIZE: float = 84.0
const PADDING: Vector4 = Vector4(46, 38, 46, 30)
const GREETING_SIZE: int = 18
const BODY_SIZE: int = 16
const BODY_LINE_SPACING: int = 7
const SIGNATURE_SIZE: int = 34
const SOLVE_BUTTON_HEIGHT: float = 34.0
const InkStampMaterial = preload("res://Scripts/InkStamp/InkStampMaterial.gd")

var puzzle: PuzzleDefinition
var solve_button: Button
var _foot: Control

func _init(letter_puzzle: PuzzleDefinition = null) -> void:
	puzzle = letter_puzzle
	size = LETTER_SIZE
	custom_minimum_size = LETTER_SIZE
	pivot_offset = LETTER_SIZE * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	_build()

func _draw() -> void:
	var paper := StyleBoxFlat.new()
	paper.bg_color = PAPER
	paper.set_corner_radius_all(3)
	paper.shadow_color = Color(0, 0, 0, 0.4)
	paper.shadow_size = 28
	paper.shadow_offset = Vector2(0, 20)
	paper.anti_aliasing = true
	draw_style_box(paper, Rect2(Vector2.ZERO, size))
	# Where it was folded in three to go in the envelope.
	for fold in [196.0 / 590.0, 393.0 / 590.0]:
		draw_line(Vector2(0, size.y * fold), Vector2(size.x, size.y * fold), FOLD_LINE, 1.0)
	if _foot != null and _foot.is_inside_tree():
		# A dashed rule across the top of the foot.
		var y: float = (get_global_transform().affine_inverse() * _foot.get_global_transform() * Vector2.ZERO).y
		var x: float = PADDING.x
		while x < size.x - PADDING.z:
			draw_line(Vector2(x, y), Vector2(minf(x + 4.0, size.x - PADDING.z), y), FOOT_RULE, 1.0)
			x += 7.0

func _build() -> void:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", int(PADDING.x))
	margin.add_theme_constant_override("margin_top", int(PADDING.y))
	margin.add_theme_constant_override("margin_right", int(PADDING.z))
	margin.add_theme_constant_override("margin_bottom", int(PADDING.w))
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	if puzzle == null:
		return
	var greeting: String = tr(puzzle.greeting)
	if !greeting.strip_edges().is_empty():
		column.add_child(_letter_label(greeting, GREETING_SIZE))
	for paragraph in puzzle.get_body_paragraphs():
		column.add_child(_letter_label(paragraph, BODY_SIZE))
	var closing: String = tr(puzzle.closing)
	if !closing.strip_edges().is_empty():
		column.add_child(_letter_label(closing, BODY_SIZE))
	var signature := PuzzleUi.label(puzzle.get_signature())
	signature.add_theme_font_override("font", PuzzleUi.signature_font())
	signature.add_theme_font_size_override("font_size", SIGNATURE_SIZE)
	signature.add_theme_constant_override("line_spacing", 0)
	column.add_child(signature)

	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	_foot = _build_foot()
	column.add_child(_foot)
	_foot.item_rect_changed.connect(queue_redraw)

func _letter_label(text: String, font_size: int) -> Label:
	var result := PuzzleUi.label(text)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_override("font", PuzzleUi.letter_font())
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_constant_override("line_spacing", BODY_LINE_SPACING)
	return result

## The sketch of the board, FELADVÁNY and the task, and Megoldom.
func _build_foot() -> Control:
	var holder := MarginContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_theme_constant_override("margin_top", 16)
	var foot := HBoxContainer.new()
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.add_theme_constant_override("separation", 18)
	holder.add_child(foot)

	var sketch := Control.new()
	sketch.custom_minimum_size = Vector2.ONE * SKETCH_SIZE
	sketch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sketch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sketch.draw.connect(func() -> void:
		PuzzleUi.draw_board_sketch_paper(sketch, Rect2(Vector2.ZERO, sketch.size), SKETCH_PAPER))
	foot.add_child(sketch)
	# The sketch's ink on its own layer, stamped like the UI's other ink.
	var sketch_ink := Control.new()
	sketch_ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sketch_ink.size = Vector2.ONE * SKETCH_SIZE
	sketch_ink.draw.connect(func() -> void:
		PuzzleUi.draw_board_sketch_ink(sketch_ink, Rect2(Vector2.ZERO, sketch_ink.size), puzzle, SKETCH_PAPER, UiPalette.INK))
	sketch.add_child(sketch_ink)
	InkStampMaterial.apply(sketch_ink)

	var words := VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.size_flags_vertical = Control.SIZE_SHRINK_END
	words.add_theme_constant_override("separation", 3)
	words.add_child(PuzzleUi.label(tr("PUZZLE_KICKER").to_upper(), &"KickerLabel"))
	var task := PuzzleUi.label(tr(puzzle.task))
	task.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(task)
	var reward_text: String = tr("PUZZLE_REWARD_LINE") % PuzzleUi.describe_reward(puzzle)
	if PuzzleStore.is_solved(puzzle.puzzle_id):
		reward_text = tr("PUZZLE_ALREADY_SOLVED")
	words.add_child(PuzzleUi.label(reward_text, &"CaptionLabel", UiPalette.INK_SOFT))
	foot.add_child(words)

	solve_button = Button.new()
	solve_button.text = tr("PUZZLE_SOLVE")
	solve_button.custom_minimum_size = Vector2(0, SOLVE_BUTTON_HEIGHT)
	solve_button.size_flags_vertical = Control.SIZE_SHRINK_END
	solve_button.focus_mode = Control.FOCUS_NONE
	solve_button.pressed.connect(func() -> void: solve_requested.emit())
	foot.add_child(solve_button)
	return holder
