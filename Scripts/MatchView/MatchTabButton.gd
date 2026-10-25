extends Button
class_name MatchTabButton

## A button shaped like a paper tab pushed up through the bottom edge of the
## screen, under the board.
##
## It rises into view when it can be pressed and slides back out of frame when
## it cannot, so what is open to the player reads at a glance without anything
## having to be greyed out. Nothing has to tell it when that changes: it keeps
## an eye on its own `disabled`, which spares every caller that sets it from
## knowing a tab is involved.
##
## Sideways it is placed from the 1920x1080 canvas the room is drawn on, so it
## stays under the board whatever shape the window is. Up and down it is
## anchored to the screen's own bottom edge, because that is the edge it is
## meant to be poking through.
##
## It looks like the UI's other buttons - outline, ink stamp, the hover's ink
## fill - from the theme's MatchTabButton variation, cut as a tab: rounded
## along the top, open along the bottom. Its styles leave 48 at the bottom
## (tab_height - raised_height, and 6 more), so the words sit in the part that
## shows rather than in the middle of the whole tab. Unlike the other buttons
## it is paper, not clear: the theme's "face" style, drawn on a layer of its
## own at the very back, so the hover's ink (InkHoverFill) floods in over the
## paper and under the outline and the label.

const SLIDE_SECONDS: float = 0.26

@export var canvas_centre_x: float = 960.0
@export var tab_width: float = 150.0
## Taller than it shows: the rest is the part still below the screen's edge,
## which is what makes it read as a tab rather than a floating button.
@export var tab_height: float = 114.0
@export var raised_height: float = 72.0

var _shown: float = 0.0
var _slide: Tween
var _was_disabled: bool = true

func _ready() -> void:
	anchor_top = 1.0
	anchor_bottom = 1.0
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(tab_width, tab_height)
	theme_type_variation = &"MatchTabButton"
	add_child(_Face.new(), false, Node.INTERNAL_MODE_FRONT)
	_place()
	get_viewport().size_changed.connect(_place)
	_was_disabled = disabled
	_shown = 0.0 if disabled else raised_height
	_apply_slide()
	set_process(true)

func _process(_delta: float) -> void:
	if disabled == _was_disabled:
		return
	_was_disabled = disabled
	_slide_to(0.0 if disabled else raised_height)

# --- Where it sits ------------------------------------------------------------

func _place() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var cover: float = BoardCanvas.cover(viewport_size)
	var centre_x: float = (canvas_centre_x - BoardCanvas.SIZE.x * 0.5) * cover + viewport_size.x * 0.5
	anchor_left = 0.0
	anchor_right = 0.0
	offset_left = centre_x - tab_width * 0.5
	offset_right = centre_x + tab_width * 0.5
	_apply_slide()

func _apply_slide() -> void:
	offset_top = -_shown
	offset_bottom = tab_height - _shown

func _slide_to(target: float) -> void:
	if _slide != null and _slide.is_valid():
		_slide.kill()
	_slide = create_tween()
	_slide.set_ease(Tween.EASE_OUT)
	_slide.set_trans(Tween.TRANS_BACK if target > _shown else Tween.TRANS_QUAD)
	_slide.tween_method(_set_shown, _shown, target, SLIDE_SECONDS)

func _set_shown(value: float) -> void:
	_shown = value
	_apply_slide()

# --- How it looks -------------------------------------------------------------

## The tab's paper, behind everything the button draws itself.
class _Face:
	extends Control

	func _init() -> void:
		name = "Face"
		show_behind_parent = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)

	func _ready() -> void:
		get_parent().theme_changed.connect(queue_redraw)

	func _draw() -> void:
		draw_style_box(get_parent().get_theme_stylebox(&"face"), Rect2(Vector2.ZERO, size))
