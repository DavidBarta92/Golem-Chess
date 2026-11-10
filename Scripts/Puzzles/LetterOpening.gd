extends Control
class_name LetterOpening

## A letter being opened over the Puzzles screen (Docs/Letters, "Megnyitott
## levél"): the screen goes dark as it does for a pack, the envelope lifts out
## of the grid, turns over on its way to the bottom of the screen, its flap
## opens, and the letter slides out of it and comes to rest in front.
## Clicking the dark, the close button or Escape puts it away.
##
## The timings are the mock-up's CSS: the envelope 0.55 s, the flap from
## 0.60 s, the letter from 1.0 s to 1.75 s, the close button after it.

signal closed
signal solve_requested(puzzle: PuzzleDefinition)

const PackController = preload("res://Scenes/CollectionPackController.gd")
const InkStampMaterial = preload("res://Scripts/InkStamp/InkStampMaterial.gd")
## The dark behind a pack being opened, and the layer it opens on, so a letter
## covers the screen the same way.
const DIM_COLOR: Color = PackController.PACK_OVERLAY_DIM
const LAYER: int = PackController.PACK_OVERLAY_LAYER
## The open envelope: the mock-up's 540 at 1440, on the 1280 base.
const OPEN_WIDTH: float = 480.0
## The layout is the mock-up's 1280 x 720 frame, centred in the window.
const FRAME_SIZE: Vector2 = Vector2(1280, 720)
const LETTER_TOP: float = 23.0
const LETTER_TILT_DEGREES: float = -1.0
const LETTER_INSIDE_SCALE: float = 0.62
const CLOSE_SIZE: float = 46.0
const CLOSE_GAP: float = 21.0

const DIM_SECONDS: float = 0.35
const FLIGHT_SECONDS: float = 0.55
const FLAP_START: float = 0.6
const FLAP_CLOSE_SECONDS: float = 0.18
const FLAP_OPEN_SECONDS: float = 0.2
const LETTER_START: float = 1.0
const LETTER_RISE_SECONDS: float = 0.4
const LETTER_SETTLE_SECONDS: float = 0.35
const CLOSE_FADE_SECONDS: float = 0.3
const PUT_AWAY_SECONDS: float = 0.25

## Envelope parts in front of and behind the letter.
const Z_LINING: int = 1
const Z_FLAP_OPEN: int = 2
const Z_LETTER_INSIDE: int = 3
const Z_POCKET: int = 4
const Z_FLAP_CLOSED: int = 5
const Z_LETTER_OUT: int = 6

var puzzle: PuzzleDefinition
var _dim: ColorRect
var _rig: Control
var _front: EnvelopeView
var _back_parts: Array[EnvelopeView] = []
var _flap_closed: EnvelopeView
var _flap_open: EnvelopeView
var _letter: LetterView
var _close_button: Button
var _from_rect: Rect2
var _from_rotation: float = 0.0
var _closing: bool = false

## Opens `letter_puzzle`'s envelope, starting from where it lies on the
## screen: `from_rect` is its rectangle unturned, `from_rotation` its tilt.
static func open(parent: Node, letter_puzzle: PuzzleDefinition, from_rect: Rect2, from_rotation: float) -> LetterOpening:
	var layer := CanvasLayer.new()
	layer.name = "LetterLayer"
	layer.layer = LAYER
	parent.add_child(layer)
	var opening := LetterOpening.new()
	opening.puzzle = letter_puzzle
	opening._from_rect = from_rect
	opening._from_rotation = from_rotation
	opening.theme = (parent as Control).theme if parent is Control else null
	layer.add_child(opening)
	return opening

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	_play()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		put_away()

func _build() -> void:
	_dim = ColorRect.new()
	_dim.color = DIM_COLOR
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.modulate.a = 0.0
	add_child(_dim)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.gui_input.connect(func(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			put_away())

	var style: int = puzzle.get_envelope_style()
	var body := Vector2(OPEN_WIDTH, EnvelopeArt.get_height(style, OPEN_WIDTH))
	_rig = Control.new()
	_rig.name = "Envelope"
	_rig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rig.size = body
	_rig.pivot_offset = body * 0.5
	add_child(_rig)
	_front = _add_part(style, EnvelopeView.Part.FRONT, body, Z_FLAP_CLOSED)
	_front.set_mark(puzzle.reward_kind, puzzle.get_reward_stamp(), puzzle.reward_print)
	_back_parts.append(_add_part(style, EnvelopeView.Part.LINING, body, Z_LINING))
	_flap_open = _add_part(style, EnvelopeView.Part.FLAP_OPEN, body, Z_FLAP_OPEN)
	_back_parts.append(_flap_open)
	_back_parts.append(_add_part(style, EnvelopeView.Part.POCKET, body, Z_POCKET))
	_flap_closed = _add_part(style, EnvelopeView.Part.FLAP_CLOSED, body, Z_FLAP_CLOSED)
	_back_parts.append(_flap_closed)
	for back_part in _back_parts:
		back_part.visible = false
	_flap_open.pivot_offset = Vector2(body.x * 0.5, 1.0)
	_flap_open.scale.y = 0.0
	_flap_closed.pivot_offset = Vector2(body.x * 0.5, 1.0)

	_letter = LetterView.new(puzzle)
	_letter.z_index = Z_LETTER_INSIDE
	_letter.visible = false
	_letter.solve_requested.connect(func() -> void: solve_requested.emit(puzzle))
	add_child(_letter)

	_close_button = Button.new()
	_close_button.theme_type_variation = &"BareButton"
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.custom_minimum_size = Vector2.ONE * CLOSE_SIZE
	_close_button.size = Vector2.ONE * CLOSE_SIZE
	_close_button.tooltip_text = tr("PUZZLE_CLOSE_LETTER")
	_close_button.z_index = Z_LETTER_OUT
	_close_button.modulate.a = 0.0
	_close_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_close_button.draw.connect(_draw_close_button_paper)
	_close_button.pressed.connect(put_away)
	add_child(_close_button)
	# Its ink on a layer of its own, stamped like the UI's other ink; the paper
	# disc under it stays whole.
	var close_ink := Control.new()
	close_ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close_ink.size = Vector2.ONE * CLOSE_SIZE
	close_ink.draw.connect(_draw_close_button_ink.bind(close_ink))
	_close_button.add_child(close_ink)
	InkStampMaterial.apply(close_ink)

func _add_part(style: int, part: EnvelopeView.Part, body: Vector2, z: int) -> EnvelopeView:
	var view := EnvelopeView.new(style, part)
	view.size = body
	view.z_index = z
	_rig.add_child(view)
	return view

func _draw_close_button_paper() -> void:
	var hovered: bool = _close_button.is_hovered()
	_close_button.draw_circle(_close_button.size * 0.5, CLOSE_SIZE * 0.5 - 1.0, UiPalette.PAPER_HOVER if hovered else UiPalette.PAPER)

func _draw_close_button_ink(ink_layer: Control) -> void:
	var centre: Vector2 = ink_layer.size * 0.5
	ink_layer.draw_arc(centre, CLOSE_SIZE * 0.5 - 1.5, 0.0, TAU, 40, UiPalette.INK, 2.5, true)
	var arm: float = 6.5
	ink_layer.draw_line(centre + Vector2(-arm, -arm), centre + Vector2(arm, arm), UiPalette.INK, 2.5, true)
	ink_layer.draw_line(centre + Vector2(arm, -arm), centre + Vector2(-arm, arm), UiPalette.INK, 2.5, true)

# --- Where things end up --------------------------------------------------------

func _frame_origin() -> Vector2:
	return ((get_viewport_rect().size - FRAME_SIZE) * 0.5).floor()

## The open envelope's centre: at the foot of the screen, under the letter.
func _rig_target_centre() -> Vector2:
	var frame: Vector2 = _frame_origin()
	return Vector2(frame.x + FRAME_SIZE.x * 0.5, frame.y + FRAME_SIZE.y - _rig.size.y * 0.5)

func _letter_final_centre() -> Vector2:
	var frame: Vector2 = _frame_origin()
	return Vector2(frame.x + FRAME_SIZE.x * 0.5, frame.y + LETTER_TOP + LetterView.LETTER_SIZE.y * 0.5)

func _rig_top() -> float:
	return _rig_target_centre().y - _rig.size.y * 0.5

# --- The opening ----------------------------------------------------------------

func _play() -> void:
	SFXManager.play("pack_whoosh")
	var dim_tween := create_tween()
	dim_tween.tween_property(_dim, "modulate:a", 1.0, DIM_SECONDS).set_ease(Tween.EASE_OUT)

	_set_flight(0.0)
	var flight := create_tween()
	flight.tween_method(_set_flight, 0.0, 1.0, FLIGHT_SECONDS)

	var flap := create_tween()
	flap.tween_interval(FLAP_START)
	flap.tween_callback(SFXManager.play.bind("codex_fold"))
	flap.tween_property(_flap_closed, "scale:y", 0.0, FLAP_CLOSE_SECONDS).set_ease(Tween.EASE_IN)
	flap.tween_property(_flap_open, "scale:y", 1.0, FLAP_OPEN_SECONDS).set_ease(Tween.EASE_OUT)

	var letter := create_tween()
	letter.tween_interval(LETTER_START)
	letter.tween_callback(_start_letter)
	letter.tween_property(_letter, "position:y", _letter_rise_centre_y() - LetterView.LETTER_SIZE.y * 0.5, LETTER_RISE_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	letter.tween_callback(func() -> void: _letter.z_index = Z_LETTER_OUT)
	letter.tween_property(_letter, "position", _letter_final_centre() - LetterView.LETTER_SIZE * 0.5, LETTER_SETTLE_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	letter.parallel().tween_property(_letter, "scale", Vector2.ONE, LETTER_SETTLE_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	letter.parallel().tween_property(_letter, "rotation", deg_to_rad(LETTER_TILT_DEGREES), LETTER_SETTLE_SECONDS).set_ease(Tween.EASE_OUT)
	letter.tween_callback(_show_close_button)

## The flight out of the grid: `t` from 0 (lying where it was) to 1 (open at
## the foot of the screen). Half way it is edge on, and turns over.
func _set_flight(t: float) -> void:
	var eased: float = ease(t, 0.35)
	var start_centre: Vector2 = _from_rect.get_center()
	var start_scale: float = _from_rect.size.x / _rig.size.x if _rig.size.x > 0.0 else 1.0
	var centre: Vector2 = start_centre.lerp(_rig_target_centre(), eased)
	# A lift out of the grid before it heads off.
	centre.y -= sin(t * PI) * 40.0
	var grow: float = lerpf(start_scale, 1.0, eased)
	var turn: float = cos(t * PI)
	_rig.rotation = lerp_angle(_from_rotation, 0.0, eased)
	_rig.scale = Vector2(grow * maxf(absf(turn), 0.02), grow)
	_rig.position = centre - _rig.size * 0.5
	var showing_back: bool = turn < 0.0
	_front.visible = !showing_back
	for back_part in _back_parts:
		back_part.visible = showing_back

## In the envelope, small, behind its front.
func _start_letter() -> void:
	var inside_centre := Vector2(_rig_target_centre().x, _rig_top() + _rig.size.y * 0.25 + LetterView.LETTER_SIZE.y * LETTER_INSIDE_SCALE * 0.5)
	_letter.scale = Vector2.ONE * LETTER_INSIDE_SCALE
	_letter.position = inside_centre - LetterView.LETTER_SIZE * 0.5
	_letter.rotation = 0.0
	_letter.visible = true
	SFXManager.play("field_slips")

## Just clear of the envelope, still small.
func _letter_rise_centre_y() -> float:
	return _rig_top() + 16.0 - LetterView.LETTER_SIZE.y * LETTER_INSIDE_SCALE * 0.5

func _show_close_button() -> void:
	var letter_rect := Rect2(_letter_final_centre() - LetterView.LETTER_SIZE * 0.5, LetterView.LETTER_SIZE)
	_close_button.position = Vector2(letter_rect.end.x + CLOSE_GAP, letter_rect.position.y)
	_close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_close_button, "modulate:a", 1.0, CLOSE_FADE_SECONDS)

## Fades it all out and hands the screen back.
func put_away() -> void:
	if _closing:
		return
	_closing = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	SFXManager.play("buy_packs_window_closing")
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, PUT_AWAY_SECONDS)
	tween.tween_callback(func() -> void:
		closed.emit()
		get_parent().queue_free())
