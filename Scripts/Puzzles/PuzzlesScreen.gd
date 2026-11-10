extends Control

## The Puzzles screen (Docs/Letters, "Levelek"): every puzzle arrives as a
## letter, eight envelopes to a page. Clicking one opens it (LetterOpening);
## the letter's button takes the player to the puzzle's board
## (Scenes/PuzzleMatch.tscn). Docs/Puzzles/PUZZLES.md has the whole of it.

const MAIN_MENU_SCENE: String = "res://Scenes/MainMenu.tscn"
const InkStampMaterial = preload("res://Scripts/InkStamp/InkStampMaterial.gd")
const PUZZLE_MATCH_SCENE: String = "res://Scenes/PuzzleMatch.tscn"
const COLUMNS: int = 4
const PER_PAGE: int = 8
## The mock-up's measures at 1440, on the 1280 base.
const SIDE_MARGIN: float = 36.0
const TOP_MARGIN: float = 60.0 + 30.0
const COLUMN_GAP: int = 23
const ROW_GAP: int = 20
const CELL_HEIGHT: float = 178.0
const ENVELOPE_WIDTH: float = 222.0
const WIDE_ENVELOPE_WIDTH: float = 267.0
## How far an envelope lifts under the mouse, and how long it takes.
const HOVER_LIFT: float = 9.0
const HOVER_SECONDS: float = 0.24
const TILTS: Array[float] = [-3.0, 2.0, -1.5, 2.5, 1.5, -2.0, 3.0, -1.0]

var puzzles: Array[PuzzleDefinition] = []
var page: int = 0
var grid: GridContainer
var count_label: Label
var page_dots: Control
var previous_button: Button
var next_button: Button
var _cells: Dictionary = {}
var _opening: LetterOpening

func _ready() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.color = UiPalette.PAPER_SHADE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	puzzles = PuzzleLibrary.get_puzzles()
	page = clampi(PuzzleStore.last_page, 0, _page_count() - 1)
	GlobalTopBar.show_back_only(_on_back_pressed)
	_build()
	_show_page()

func _on_back_pressed() -> void:
	if _opening != null:
		_opening.put_away()
		return
	PuzzleStore.last_page = 0
	SceneTransition.change_scene(MAIN_MENU_SCENE)

## The wheel turns the page anywhere on the screen, envelopes included, which
## would otherwise keep it to themselves.
func _input(event: InputEvent) -> void:
	var wheel := event as InputEventMouseButton
	if wheel == null or !wheel.pressed or _opening != null:
		return
	if wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN or wheel.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
		_turn_page(1)
		get_viewport().set_input_as_handled()
	elif wheel.button_index == MOUSE_BUTTON_WHEEL_UP or wheel.button_index == MOUSE_BUTTON_WHEEL_LEFT:
		_turn_page(-1)
		get_viewport().set_input_as_handled()

# --- Layout ---------------------------------------------------------------------

func _build() -> void:
	var margin := MarginContainer.new()
	margin.name = "Layout"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", int(SIDE_MARGIN))
	margin.add_theme_constant_override("margin_right", int(SIDE_MARGIN))
	margin.add_theme_constant_override("margin_top", int(TOP_MARGIN))
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)

	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(header)
	var titles := VBoxContainer.new()
	titles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 4)
	header.add_child(titles)
	titles.add_child(PuzzleUi.label(tr("PUZZLES_SCREEN_TITLE"), &"ScreenTitleLabel"))
	titles.add_child(PuzzleUi.label(tr("PUZZLES_SCREEN_SUBTITLE"), &"", UiPalette.INK_SOFT))
	count_label = PuzzleUi.label("", &"FieldLabel")
	count_label.size_flags_vertical = Control.SIZE_SHRINK_END
	header.add_child(count_label)

	grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_theme_constant_override("h_separation", COLUMN_GAP)
	grid.add_theme_constant_override("v_separation", ROW_GAP)
	column.add_child(grid)

	if puzzles.is_empty():
		var empty := PuzzleUi.label(tr("PUZZLES_NONE"), &"", UiPalette.INK_SOFT)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.custom_minimum_size = Vector2(0, 200)
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		column.add_child(empty)

	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	column.add_child(_build_pager())

func _build_pager() -> Control:
	var pager := HBoxContainer.new()
	pager.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pager.alignment = BoxContainer.ALIGNMENT_CENTER
	pager.add_theme_constant_override("separation", 14)
	previous_button = _pager_button(preload("res://ui/themes/icons/back.png"), -1)
	pager.add_child(previous_button)
	page_dots = Control.new()
	page_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_dots.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	page_dots.draw.connect(_draw_page_dots)
	InkStampMaterial.apply(page_dots, true)
	pager.add_child(page_dots)
	next_button = _pager_button(preload("res://ui/themes/icons/next.png"), 1)
	pager.add_child(next_button)
	var hint := PuzzleUi.label(tr("PUZZLES_SCROLL_HINT"), &"CaptionLabel", UiPalette.INK_SOFT)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pager.add_child(hint)
	return pager

## The collection's pager arrows: the black disc art re-inked and stamped like
## the UI's other ink (Collection._configure_pager_buttons).
func _pager_button(icon: Texture2D, step: int) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"PagerArrowButton"
	InkStampMaterial.apply(button, true, true)
	button.icon = icon
	button.expand_icon = true
	button.custom_minimum_size = Vector2(34, 34)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_turn_page.bind(step))
	return button

func _draw_page_dots() -> void:
	var count: int = _page_count()
	var spacing: float = 16.0
	page_dots.custom_minimum_size = Vector2(maxf(spacing * count - 6.0, 10.0), 10.0)
	for index in range(count):
		var centre := Vector2(5.0 + spacing * index, 5.0)
		if index == page:
			page_dots.draw_circle(centre, 5.0, UiPalette.INK)
		else:
			page_dots.draw_arc(centre, 4.25, 0.0, TAU, 20, UiPalette.INK, 1.5, true)

func _page_count() -> int:
	return maxi(1, ceili(float(puzzles.size()) / float(PER_PAGE)))

func _turn_page(step: int) -> void:
	var target: int = clampi(page + step, 0, _page_count() - 1)
	if target == page:
		return
	page = target
	PuzzleStore.last_page = page
	SFXManager.play("codex_fold")
	_show_page()

func _show_page() -> void:
	for child in grid.get_children():
		child.queue_free()
	_cells.clear()
	var start: int = page * PER_PAGE
	for index in range(start, mini(start + PER_PAGE, puzzles.size())):
		var cell := _build_cell(puzzles[index], TILTS[index % TILTS.size()])
		grid.add_child(cell)
		_cells[puzzles[index].puzzle_id] = cell
	var unopened: int = PuzzleStore.count_unopened(puzzles)
	count_label.text = tr("PUZZLES_COUNT") % [puzzles.size(), unopened]
	previous_button.disabled = page <= 0
	next_button.disabled = page >= _page_count() - 1
	page_dots.queue_redraw()

# --- One envelope ---------------------------------------------------------------

## An envelope lying a little crooked, with the sender and where the puzzle
## stands under it. It straightens and lifts under the mouse.
func _build_cell(puzzle: PuzzleDefinition, tilt: float) -> Control:
	var cell := VBoxContainer.new()
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_theme_constant_override("separation", 8)

	var style: int = puzzle.get_envelope_style()
	var width: float = WIDE_ENVELOPE_WIDTH if style == PuzzleDefinition.EnvelopeStyle.AMERICAN else ENVELOPE_WIDTH
	var envelope_size := Vector2(width, EnvelopeArt.get_height(style, width))

	var button := Button.new()
	button.name = "Envelope_" + puzzle.puzzle_id
	button.theme_type_variation = &"BareButton"
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, CELL_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = tr("PUZZLE_REWARD_LINE") % PuzzleUi.describe_reward(puzzle)
	cell.add_child(button)

	var holder := _EnvelopeHolder.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = envelope_size
	holder.pivot_offset = envelope_size * 0.5
	holder.rest_tilt = deg_to_rad(tilt)
	holder.rotation = holder.rest_tilt
	button.add_child(holder)
	var envelope := EnvelopeView.new(style, EnvelopeView.Part.FRONT)
	envelope.size = envelope_size
	envelope.set_mark(puzzle.reward_kind, puzzle.get_reward_stamp(), puzzle.reward_print)
	holder.add_child(envelope)
	holder.envelope = envelope
	var state: PuzzleStore.State = PuzzleStore.get_state(puzzle.puzzle_id)
	if state == PuzzleStore.State.NEW:
		holder.add_child(_new_badge())

	var place := func() -> void:
		holder.rest_position = (button.size - envelope_size) * 0.5
		holder.position = holder.rest_position + Vector2(0, -HOVER_LIFT * holder.lift)
	button.resized.connect(place)
	place.call_deferred()
	button.mouse_entered.connect(holder.set_hovered.bind(true))
	button.mouse_exited.connect(holder.set_hovered.bind(false))
	button.pressed.connect(_open_letter.bind(puzzle, holder))

	var sender := PuzzleUi.label(puzzle.get_sender_name())
	sender.add_theme_font_override("font", get_theme_font("font", "Button"))
	sender.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.add_child(sender)
	cell.add_child(_state_line(state))
	return cell

func _new_badge() -> Control:
	var badge := PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = UiPalette.INK
	box.set_corner_radius_all(9)
	box.content_margin_left = 9
	box.content_margin_right = 9
	box.content_margin_top = 1
	box.content_margin_bottom = 2
	badge.add_theme_stylebox_override("panel", box)
	badge.add_child(PuzzleUi.label(tr("PUZZLE_NEW_BADGE"), &"KickerLabel", UiPalette.PAPER_RAISED))
	badge.position = Vector2(-11, -9)
	return badge

func _state_line(state: PuzzleStore.State) -> Control:
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override("separation", 5)
	if state == PuzzleStore.State.SOLVED:
		var check := Control.new()
		check.custom_minimum_size = Vector2(13, 13)
		check.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		check.draw.connect(func() -> void:
			check.draw_polyline(PackedVector2Array([Vector2(2.8, 6.7), Vector2(5.6, 9.3), Vector2(10.2, 3.7)]), UiPalette.INK_SOFT, 1.75, true))
		line.add_child(check)
	var keys: Dictionary = {
		PuzzleStore.State.NEW: "PUZZLE_STATE_NEW",
		PuzzleStore.State.OPEN: "PUZZLE_STATE_OPEN",
		PuzzleStore.State.SOLVED: "PUZZLE_STATE_SOLVED",
	}
	line.add_child(PuzzleUi.label(tr(keys[state]), &"CaptionLabel", UiPalette.INK_SOFT))
	return line

# --- Opening a letter -----------------------------------------------------------

func _open_letter(puzzle: PuzzleDefinition, holder: Control) -> void:
	if _opening != null:
		return
	var from_rect := Rect2(holder.get_global_transform() * Vector2.ZERO, holder.size)
	# The holder turns about its centre; its unturned rect shares that centre.
	var centre: Vector2 = holder.get_global_transform() * (holder.size * 0.5)
	from_rect.position = centre - holder.size * 0.5
	holder.modulate.a = 0.0
	PuzzleStore.mark_opened(puzzle.puzzle_id)
	_opening = LetterOpening.open(self, puzzle, from_rect, holder.rotation)
	_opening.solve_requested.connect(_on_solve_requested)
	_opening.closed.connect(func() -> void:
		_opening = null
		_show_page())

func _on_solve_requested(puzzle: PuzzleDefinition) -> void:
	PuzzleStore.active_puzzle_id = puzzle.puzzle_id
	SceneTransition.change_scene(PUZZLE_MATCH_SCENE)

## Holds an envelope at its tilt, and straightens and lifts it under the
## mouse, its shadow growing as it rises.
class _EnvelopeHolder:
	extends Control

	var envelope: EnvelopeView
	var rest_tilt: float = 0.0
	var rest_position: Vector2 = Vector2.ZERO
	var lift: float = 0.0
	var _tween: Tween

	func set_hovered(hovered: bool) -> void:
		if _tween != null and _tween.is_valid():
			_tween.kill()
		_tween = create_tween()
		_tween.tween_method(_set_lift, lift, 1.0 if hovered else 0.0, HOVER_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		if hovered:
			SFXManager.play("button_hover")

	func _set_lift(value: float) -> void:
		lift = value
		rotation = lerpf(rest_tilt, 0.0, lift)
		position = rest_position + Vector2(0, -HOVER_LIFT * lift)
		queue_redraw()

	func _draw() -> void:
		var shadow := StyleBoxFlat.new()
		shadow.bg_color = Color(0, 0, 0, 0)
		shadow.shadow_color = Color(UiPalette.INK, lerpf(0.16, 0.28, lift))
		shadow.shadow_size = int(round(lerpf(2.0, 14.0, lift)))
		shadow.shadow_offset = Vector2(0, lerpf(2.0, 14.0, lift))
		shadow.set_corner_radius_all(3)
		draw_style_box(shadow, Rect2(Vector2.ZERO, size))
