extends Sprite2D
class_name BoardGridOverlay

## The hand-drawn grid that sits on the board: above the tiles, under the
## pieces. It draws itself the way the background's line layers do, and the
## board's perspective is fitted to it, so the tiles land inside the ink.
##
## It lives inside the board rather than in the background because nothing
## else can get between the tiles and the pieces - both are in the same world
## canvas. That has one consequence worth knowing: the camera turns 180
## degrees when the player is black, so the grid is turned back by the same
## amount. Being centred on the camera, that cancels exactly, and the drawing
## stays the right way up whichever side is being played.

const LINE_REVEAL_SHADER = preload("res://Shaders/mainmenu_line_reveal.gdshader")
const HIDDEN_TIME: float = -1.0

## Where the drawing sits in the board's stack. Everything painted onto the
## board's surface goes under it, everything standing on the board goes over
## it, and the gap between the two is exactly one slot wide:
##
##   -24  the board's shadow          |
##    -4  the side and the frame      |  under the grid: the board itself
##     0  the base tiles              |  and anything painted on it
##   1-8  special tiles, the danger   |
##        and freeze tints, markers,  |
##        and the covers a tile slides under while it changes
##   --- 9: this drawing ---
##    10  the pieces                  |  over the grid: anything standing
##    12  piece effects               |  on the board
##    20  the move option dots        |
##
## A new tile layer belongs below 9; anything that stands on a square belongs
## above it.
const Z_INDEX: int = 9

signal reveal_finished

@export_range(0.1, 6.0, 0.05) var base_duration: float = 1.6
@export_range(0.0, 6.0, 0.05) var max_delay: float = 1.4
@export_range(0.0, 1.0, 0.01) var min_duration_frac: float = 0.45
@export_range(0.0, 0.2, 0.005) var feather: float = 0.03
@export var line_color: Color = Color(0.06, 0.06, 0.08, 1.0)

var _material: ShaderMaterial
var _tween: Tween

func _ready() -> void:
	centered = true
	z_index = Z_INDEX
	_material = ShaderMaterial.new()
	_material.shader = LINE_REVEAL_SHADER
	material = _material
	_apply_parameters()
	_fit_to_canvas()
	reset_overlay()

## Puts the drawing on the canvas at its authored size. Nothing here depends on
## the window: the camera is what follows the viewport, and it carries this
## along with the board, so the two can never drift apart. The png is a few
## pixels short of 1920x1080 and is treated as a centred crop of it, which
## leaves it half a pixel out at the sides - a third of a screen pixel.
func _fit_to_canvas() -> void:
	if texture == null:
		return
	scale = Vector2.ONE / BoardCanvas.PIXELS_PER_UNIT
	position = Vector2.ZERO

## Turns the drawing back upright when the camera is looking from the black
## side. Called by the board whenever the view side is set.
func set_view_color(view_color: int) -> void:
	rotation_degrees = 180.0 if view_color < 0 else 0.0

func reset_overlay() -> void:
	_kill_tween()
	visible = false
	if _material != null:
		_material.set_shader_parameter("time", HIDDEN_TIME)

func show_fully_drawn() -> void:
	_kill_tween()
	visible = true
	if _material != null:
		_material.set_shader_parameter("time", 1000.0)

func get_reveal_duration() -> float:
	return base_duration + max_delay

func begin() -> void:
	_kill_tween()
	_apply_parameters()
	visible = true
	_material.set_shader_parameter("time", 0.0)

	var duration: float = get_reveal_duration()
	_tween = create_tween()
	_tween.tween_method(Callable(self, "_set_time"), 0.0, duration, duration)
	_tween.tween_callback(Callable(self, "_on_finished"))

func _set_time(value: float) -> void:
	if _material != null:
		_material.set_shader_parameter("time", value)

func _on_finished() -> void:
	reveal_finished.emit()

func _apply_parameters() -> void:
	if _material == null:
		return
	_material.set_shader_parameter("base_duration", base_duration)
	_material.set_shader_parameter("max_delay", max_delay)
	_material.set_shader_parameter("min_duration_frac", min_duration_frac)
	_material.set_shader_parameter("feather", feather)
	_material.set_shader_parameter("line_color", line_color)

func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
