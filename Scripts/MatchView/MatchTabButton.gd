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

const SLIDE_SECONDS: float = 0.26

@export var canvas_centre_x: float = 960.0
@export var tab_width: float = 150.0
## Taller than it shows: the rest is the part still below the screen's edge,
## which is what makes it read as a tab rather than a floating button.
@export var tab_height: float = 114.0
@export var raised_height: float = 72.0

@export_group("Look")
@export var face_color: Color = Color(0.956863, 0.941176, 0.901961, 1.0)
@export var hover_color: Color = Color(1.0, 0.99, 0.96, 1.0)
@export var pressed_color: Color = Color(0.88, 0.86, 0.81, 1.0)
@export var edge_color: Color = UiPalette.INK

var _shown: float = 0.0
var _slide: Tween
var _was_disabled: bool = true

func _ready() -> void:
	anchor_top = 1.0
	anchor_bottom = 1.0
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(tab_width, tab_height)
	_apply_look()
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

## Rounded along the top, square along the bottom, and with its words sitting
## in the part that shows rather than in the middle of the whole tab.
func _apply_look() -> void:
	var radius: int = 10
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = face_color
		if state == "hover":
			box.bg_color = hover_color
		elif state == "pressed":
			box.bg_color = pressed_color
		box.border_color = edge_color
		box.border_width_left = 2
		box.border_width_top = 2
		box.border_width_right = 2
		box.corner_radius_top_left = radius
		box.corner_radius_top_right = radius
		box.content_margin_left = 12
		box.content_margin_right = 12
		box.content_margin_top = 8
		box.content_margin_bottom = maxf(tab_height - raised_height + 6.0, 6.0)
		add_theme_stylebox_override(state, box)
	add_theme_color_override("font_color", edge_color)
	add_theme_color_override("font_hover_color", edge_color)
	add_theme_color_override("font_pressed_color", edge_color)
	add_theme_color_override("font_disabled_color", edge_color)
