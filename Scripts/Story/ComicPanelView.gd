@tool
extends Control
class_name ComicPanelView

## One box on a comic page - the unit that draws itself when the player clicks.
##
## Art comes in pairs, one panel per pair:
##   <scene>_<n>_line.png   black line art on transparency
##   <scene>_<n>_color.png  the colour underneath, same canvas size
##
## Both sit on a full-size transparent canvas with the artwork already in the
## right place, so a panel is simply a full-rect Control and the transparency
## does the positioning. Nothing has to be placed by hand unless a page wants
## something unusual.
##
## When the panel is revealed the line draws itself the way the main menu
## background does, and once the ink has landed the colour fades in *under* it
## over fill_fade_duration. The line art therefore always stays on top.
##
## The drawing effect needs a reveal mask generated from the line art:
##
##     python tools/generate_line_reveal_mask.py Assets/Comic/1_1_line.png
##
## which writes 1_1_line_reveal_mask.png next to it. Assign that mask to
## reveal_mask - not the raw line art - and the colour png to fill_texture.
##
## With no mask assigned the panel still works: it just fades the colour in, so
## a page can be blocked out before the art exists.

signal reveal_started
signal reveal_finished

const LINE_REVEAL_SHADER = preload("res://Shaders/mainmenu_line_reveal.gdshader")
const EDITOR_PREVIEW_TIME: float = 1000.0
## Shader time for "not drawn at all". The reveal is per stroke, each with its
## own random start delay, so at time 0 the strokes that drew the shortest
## straw are already showing their first pixels - which on a page with a couple
## of thousand strokes reads as specks scattered over an empty panel. Winding
## the clock back before every delay keeps the panel properly blank.
const HIDDEN_TIME: float = -1.0
const PLACEHOLDER_LINE_COLOR: Color = Color(0.45, 0.43, 0.5, 0.85)
const PLACEHOLDER_DASH_LENGTH: float = 12.0
const PLACEHOLDER_UNREVEALED_ALPHA: float = 0.18

@export_group("Art")
## The generated *_line_reveal_mask.png, not the raw line art.
@export var reveal_mask: Texture2D:
	set(value):
		_reveal_mask = value
		_apply_textures()
	get:
		return _reveal_mask

## The *_color.png, faded in under the ink once the line is drawn.
@export var fill_texture: Texture2D:
	set(value):
		_fill_texture = value
		_apply_textures()
	get:
		return _fill_texture

@export var line_color: Color = Color(0.06, 0.06, 0.08, 1.0):
	set(value):
		_line_color = value
		_apply_shader_parameters()
	get:
		return _line_color

## Off keeps the aspect ratio of the art inside the panel rect; on stretches it
## to fill the rect exactly.
@export var stretch_to_fit: bool = false:
	set(value):
		_stretch_to_fit = value
		_apply_stretch_mode()
	get:
		return _stretch_to_fit

@export_group("Timing")
## Seconds to wait after this panel is triggered before the ink starts.
@export_range(0.0, 5.0, 0.05) var delay_before: float = 0.0
## How long an average stroke takes to draw.
@export_range(0.1, 6.0, 0.05) var base_duration: float = 1.1:
	set(value):
		_base_duration = value
		_apply_shader_parameters()
	get:
		return _base_duration
## Spread between the earliest and the latest stroke start.
@export_range(0.0, 6.0, 0.05) var max_delay: float = 0.9:
	set(value):
		_max_delay = value
		_apply_shader_parameters()
	get:
		return _max_delay
## Short strokes finish faster than long ones; this is the floor.
@export_range(0.0, 1.0, 0.01) var min_duration_frac: float = 0.45:
	set(value):
		_min_duration_frac = value
		_apply_shader_parameters()
	get:
		return _min_duration_frac
@export_range(0.0, 0.2, 0.005) var feather: float = 0.03:
	set(value):
		_feather = value
		_apply_shader_parameters()
	get:
		return _feather
@export_range(0.0, 4.0, 0.05) var fill_fade_duration: float = 1.5
## When the colour starts fading in, as a fraction of the ink animation.
## 1.0 waits for the line to finish, which is the house style.
@export_range(0.0, 1.0, 0.01) var fill_fade_start_ratio: float = 1.0

@export_group("Flow")
## When on, this panel is revealed together with the one before it instead of
## waiting for its own click - for a beat that needs two boxes at once.
@export var reveal_with_previous: bool = false
## The pen scratching away while the line draws itself (an SFXManager group
## name - a file name under Audio/SFX/ without the extension). It is stopped
## when the ink lands, so it tracks the drawing rather than ringing on over the
## next panel. Clear it for a silent panel.
@export var reveal_sfx_name: String = "mainmenu_drawing"
@export_range(0.0, 1.0, 0.01) var reveal_sfx_fade_out_seconds: float = 0.18

## An extra one-shot for the beat itself - a door, a bell - played as the panel
## starts drawing and left to ring out on its own. Optional.
@export var extra_sfx_name: String = ""

## A beat that is only a line of dialogue: nothing is drawn, not even the
## blocking-out outline, and the page moves straight on to the words. For an
## opening line spoken over an empty page.
@export var dialogue_only: bool = false

## Seconds after this panel's last line has finished typing before the page
## moves on by itself. Negative waits for a click, which is the normal case.
## Use it for a closing run that should play out on its own.
@export_range(-1.0, 20.0, 0.1) var auto_advance_after_seconds: float = -1.0

@export_group("Flourish")
## A glint when the panel lands and then a slow pulse underneath it. Meant for
## a small bright thing, a star on a title, rather than for a whole drawing.
## See ComicPanelFlourish for what the glint is and why it is not the match's
## capture sparkle.
@export var appear_sparkle: bool = false
@export_range(0.1, 4.0, 0.05) var sparkle_seconds: float = 0.85
@export var pulsing_glow: bool = false
@export var glow_color: Color = Color(1.0, 0.86, 0.45, 1.0)
@export_range(0.0, 4.0, 0.05) var glow_strength: float = 1.4
@export_range(0.2, 8.0, 0.1) var glow_period_seconds: float = 2.2

@export_group("Disappearing")
## When the panel at this path starts drawing, this one fades away. Leave empty
## for a panel that stays for the rest of the page.
@export var hide_when_revealed: NodePath
@export_range(0.0, 5.0, 0.05) var fade_out_seconds: float = 1.0

@export_group("Dialogue")
## What is said beside this panel, in order. Shown once the panel has finished
## drawing; the page then waits for its Continue button, one press per line,
## instead of a plain click. Empty for a silent panel.
@export var dialogue_lines: Array[ComicDialogueLine] = []

## Where this panel's text sits, in the page's design space (the same 1280x720
## the page is authored in). Leave the size at zero to use wherever the page's
## dialogue box was placed in the editor.
@export var dialogue_rect: Rect2 = Rect2()

var _reveal_mask: Texture2D
var _fill_texture: Texture2D
var _line_color: Color = Color(0.06, 0.06, 0.08, 1.0)
var _stretch_to_fit: bool = false
var _base_duration: float = 1.1
var _max_delay: float = 0.9
var _min_duration_frac: float = 0.45
var _feather: float = 0.03

var _lines_rect: TextureRect
var _fill_rect: TextureRect
var _line_material: ShaderMaterial
var _reveal_tween: Tween
var _fill_tween: Tween
var _is_revealing: bool = false
var _is_revealed: bool = false
var _fade_out_tween: Tween
var _is_fading_out: bool = false
var _is_hidden: bool = false
var _reveal_sfx_player: AudioStreamPlayer
var _placeholder_alpha: float = 1.0
var _glow_overlay: CanvasItem

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_layers()
	_apply_textures()
	_apply_shader_parameters()
	_apply_stretch_mode()

	if Engine.is_editor_hint():
		_show_fully_drawn()
		return
	reset_panel()

func has_dialogue() -> bool:
	return !get_dialogue_lines().is_empty()

## The lines worth showing - anything left blank in the editor is skipped.
func get_dialogue_lines() -> Array[ComicDialogueLine]:
	var lines: Array[ComicDialogueLine] = []
	for line in dialogue_lines:
		if line != null and !line.is_empty():
			lines.append(line)
	return lines

## Total time from trigger to the panel being fully there - the ink drawn *and*
## the colour faded in under it.
func get_reveal_duration() -> float:
	return delay_before + _get_appearance_duration()

## Ink plus colour fade, measured from the end of delay_before. The colour
## starts partway through the ink (fill_fade_start_ratio) and runs for
## fill_fade_duration, which can finish after the last stroke.
func _get_appearance_duration() -> float:
	if dialogue_only:
		return 0.0
	var ink_duration: float = _base_duration + _max_delay
	if _fill_texture == null:
		return ink_duration
	return maxf(ink_duration, ink_duration * fill_fade_start_ratio + fill_fade_duration)

func is_revealing() -> bool:
	return _is_revealing

func is_revealed() -> bool:
	return _is_revealed

func is_fading_out() -> bool:
	return _is_fading_out

func is_hidden_by_other() -> bool:
	return _is_hidden

## Fades this panel away - called by the page when the panel this one waits on
## starts drawing.
func fade_out() -> void:
	if _is_hidden or _is_fading_out:
		return
	_is_fading_out = true
	if fade_out_seconds <= 0.0:
		finish_fade_out_now()
		return

	_kill_fade_out_tween()
	_fade_out_tween = create_tween()
	_fade_out_tween.tween_method(Callable(self, "_set_panel_alpha"), 1.0, 0.0, fade_out_seconds)
	_fade_out_tween.tween_callback(Callable(self, "finish_fade_out_now"))

## Fades the whole panel, both layers.
##
## The node's own modulate cannot do this: the line-reveal shader writes COLOR
## from scratch and never reads the incoming modulate, so modulating the panel
## only ever faded the colour underneath while the ink stayed solid - and then
## vanished in one frame when the panel was hidden. The ink is faded through
## its own line_color instead, which works because every panel builds its own
## material.
func _set_panel_alpha(alpha: float) -> void:
	if _fill_rect != null:
		_fill_rect.modulate.a = alpha
	if _line_material != null:
		var faded_line_color: Color = _line_color
		faded_line_color.a = _line_color.a * alpha
		_line_material.set_shader_parameter("line_color", faded_line_color)

## Snaps to gone - what a click does while the panel is still fading.
func finish_fade_out_now() -> void:
	_kill_fade_out_tween()
	_is_fading_out = false
	_is_hidden = true
	_set_panel_alpha(0.0)
	visible = false

## Back to blank. The page calls this before the first click.
func reset_panel() -> void:
	_kill_tweens()
	_kill_pulse()
	_stop_reveal_sfx(0.0)
	_is_revealing = false
	_is_revealed = false
	_is_fading_out = false
	_is_hidden = false
	visible = true
	modulate.a = 1.0
	_apply_shader_parameters()
	if _line_material != null:
		_line_material.set_shader_parameter("time", HIDDEN_TIME)
	if _lines_rect != null:
		_lines_rect.modulate.a = 1.0
		# Hidden outright as well as wound back, so no single frame can flash.
		_lines_rect.visible = false
	if _fill_rect != null:
		_fill_rect.modulate.a = 0.0
	_placeholder_alpha = PLACEHOLDER_UNREVEALED_ALPHA
	queue_redraw()

## Draws the panel. Returns immediately; listen to reveal_finished for the end.
func reveal() -> void:
	if _is_revealing or _is_revealed:
		return

	_is_revealing = true
	reveal_started.emit()

	if dialogue_only:
		_on_reveal_complete()
		return

	if _reveal_mask == null:
		_reveal_without_mask()
		return

	_kill_tweens()
	_line_material.set_shader_parameter("time", HIDDEN_TIME)
	_lines_rect.modulate.a = 1.0
	# Stays invisible through delay_before; the ink tween turns it on.
	_lines_rect.visible = delay_before <= 0.0

	var ink_duration: float = _base_duration + _max_delay
	_reveal_tween = create_tween()
	if delay_before > 0.0:
		_reveal_tween.tween_interval(delay_before)
	_reveal_tween.tween_callback(Callable(self, "_play_reveal_sfx"))
	_reveal_tween.tween_callback(Callable(self, "_show_lines_layer"))
	_reveal_tween.tween_method(Callable(self, "_set_reveal_time"), 0.0, ink_duration, ink_duration)
	# The colour is still fading in when the last stroke lands, so the panel is
	# not finished until that has caught up.
	var fade_tail: float = _get_appearance_duration() - ink_duration
	if fade_tail > 0.0:
		_reveal_tween.tween_interval(fade_tail)
	_reveal_tween.tween_callback(Callable(self, "_on_reveal_complete"))
	_start_fill_fade(delay_before + ink_duration * fill_fade_start_ratio)

## Snaps to the finished state - what a click does while ink is still flowing.
func finish_reveal_now() -> void:
	if _is_revealed:
		return
	_kill_tweens()
	_show_fully_drawn()
	_on_reveal_complete()

## Everything this panel is in the middle of, snapped to its end state.
func finish_all_now() -> void:
	finish_reveal_now()
	if _is_fading_out:
		finish_fade_out_now()

func _reveal_without_mask() -> void:
	# No line art yet (or a painted panel that should not be inked in): fade
	# the fill in on its own so the page still reads correctly.
	_kill_tweens()
	var fade_duration: float = maxf(0.05, fill_fade_duration)
	_fill_rect.modulate.a = 0.0
	_reveal_tween = create_tween()
	if delay_before > 0.0:
		_reveal_tween.tween_interval(delay_before)
	_reveal_tween.tween_callback(Callable(self, "_play_reveal_sfx"))
	_reveal_tween.tween_method(Callable(self, "_set_fade_in_progress"), _placeholder_alpha, 1.0, fade_duration)
	_reveal_tween.tween_callback(Callable(self, "_on_reveal_complete"))

func _start_fill_fade(start_delay: float) -> void:
	if _fill_texture == null:
		return
	_fill_rect.modulate.a = 0.0
	_fill_tween = create_tween()
	if start_delay > 0.0:
		_fill_tween.tween_interval(start_delay)
	_fill_tween.tween_property(_fill_rect, "modulate:a", 1.0, maxf(0.05, fill_fade_duration))

## Drives both the fill fade and the placeholder outline, so a page without
## art still reads as "this box just appeared".
func _set_fade_in_progress(alpha_value: float) -> void:
	if _fill_rect != null:
		_fill_rect.modulate.a = alpha_value
	_placeholder_alpha = alpha_value
	queue_redraw()

func _show_lines_layer() -> void:
	if _lines_rect != null:
		_lines_rect.visible = _reveal_mask != null

func _set_reveal_time(time_value: float) -> void:
	if _line_material != null:
		_line_material.set_shader_parameter("time", time_value)

func _on_reveal_complete() -> void:
	_is_revealing = false
	_is_revealed = true
	_placeholder_alpha = 1.0
	queue_redraw()
	_stop_reveal_sfx(reveal_sfx_fade_out_seconds)
	_play_flourish()
	reveal_finished.emit()

## The glint and the pulse, once the panel is all the way there.
func _play_flourish() -> void:
	if Engine.is_editor_hint():
		return
	if _fill_rect == null:
		return
	if pulsing_glow:
		_kill_pulse()
		_glow_overlay = ComicPanelFlourish.start_pulse(
			_fill_rect, glow_color, glow_strength, glow_period_seconds,
			sparkle_seconds if appear_sparkle else 0.0)
	if appear_sparkle:
		ComicPanelFlourish.play_glint(
			_fill_rect, _glow_overlay, glow_strength, sparkle_seconds)

func _kill_pulse() -> void:
	if _glow_overlay != null and is_instance_valid(_glow_overlay):
		_glow_overlay.queue_free()
	_glow_overlay = null

func _play_reveal_sfx() -> void:
	if Engine.is_editor_hint():
		return
	if !reveal_sfx_name.strip_edges().is_empty():
		_reveal_sfx_player = SFXManager.play(reveal_sfx_name.strip_edges())
	if !extra_sfx_name.strip_edges().is_empty():
		SFXManager.play(extra_sfx_name.strip_edges())

## Silences the pen when the ink lands. The SFX pool hands its players out
## round-robin, so this only touches the player while it is still the one
## playing our sound - otherwise a later sound would be cut off instead.
func _stop_reveal_sfx(fade_seconds: float) -> void:
	var player: AudioStreamPlayer = _reveal_sfx_player
	_reveal_sfx_player = null
	if player == null or !is_instance_valid(player) or !player.playing:
		return

	if fade_seconds <= 0.0:
		_reset_sfx_player(player)
		return
	var tween := player.create_tween()
	tween.tween_property(player, "volume_db", -40.0, fade_seconds)
	tween.tween_callback(Callable(self, "_reset_sfx_player").bind(player))

func _reset_sfx_player(player: AudioStreamPlayer) -> void:
	if player == null or !is_instance_valid(player):
		return
	player.stop()
	player.volume_db = 0.0

func _show_fully_drawn() -> void:
	if _line_material != null:
		_line_material.set_shader_parameter("time", EDITOR_PREVIEW_TIME)
	if _lines_rect != null:
		_lines_rect.visible = _reveal_mask != null
		_lines_rect.modulate.a = 1.0
	if _fill_rect != null:
		_fill_rect.modulate.a = 1.0
	_placeholder_alpha = 1.0
	queue_redraw()

func _build_layers() -> void:
	_fill_rect = get_node_or_null("Fill") as TextureRect
	if _fill_rect == null:
		_fill_rect = TextureRect.new()
		_fill_rect.name = "Fill"
		add_child(_fill_rect, false, Node.INTERNAL_MODE_FRONT)
	_lines_rect = get_node_or_null("Lines") as TextureRect
	if _lines_rect == null:
		_lines_rect = TextureRect.new()
		_lines_rect.name = "Lines"
		add_child(_lines_rect, false, Node.INTERNAL_MODE_FRONT)

	for layer in [_fill_rect, _lines_rect]:
		layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	# Each panel animates on its own clock, so it needs its own material - a
	# material shared through the .tscn would make every panel on the page
	# draw in lockstep.
	_line_material = ShaderMaterial.new()
	_line_material.shader = LINE_REVEAL_SHADER
	_lines_rect.material = _line_material

func _apply_textures() -> void:
	if _lines_rect == null or _fill_rect == null:
		return
	_lines_rect.texture = _reveal_mask
	_lines_rect.visible = _reveal_mask != null
	_fill_rect.texture = _fill_texture
	if Engine.is_editor_hint():
		_show_fully_drawn()
	queue_redraw()

func _apply_shader_parameters() -> void:
	if _line_material == null:
		return
	_line_material.set_shader_parameter("base_duration", _base_duration)
	_line_material.set_shader_parameter("max_delay", _max_delay)
	_line_material.set_shader_parameter("min_duration_frac", _min_duration_frac)
	_line_material.set_shader_parameter("feather", _feather)
	_line_material.set_shader_parameter("line_color", _line_color)

## The rect the drawing occupies inside this panel. The layers fit the texture
## in and centre it (KEEP_ASPECT_CENTERED), so this is that same fit worked out
## again - anything placed against the picture rather than against the panel
## has to go through here.
func get_art_rect() -> Rect2:
	var texture: Texture2D = _fill_texture if _fill_texture != null else _reveal_mask
	if texture == null or _stretch_to_fit:
		return Rect2(Vector2.ZERO, size)
	var art_size: Vector2 = texture.get_size()
	if art_size.x <= 0.0 or art_size.y <= 0.0:
		return Rect2(Vector2.ZERO, size)

	var fit: float = minf(size.x / art_size.x, size.y / art_size.y)
	var fitted: Vector2 = art_size * fit
	return Rect2((size - fitted) * 0.5, fitted)

func _apply_stretch_mode() -> void:
	var mode: int = TextureRect.STRETCH_SCALE if _stretch_to_fit else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if _lines_rect != null:
		_lines_rect.stretch_mode = mode
	if _fill_rect != null:
		_fill_rect.stretch_mode = mode

func _kill_fade_out_tween() -> void:
	if _fade_out_tween != null and _fade_out_tween.is_valid():
		_fade_out_tween.kill()

func _kill_tweens() -> void:
	if _reveal_tween != null and _reveal_tween.is_valid():
		_reveal_tween.kill()
	if _fill_tween != null and _fill_tween.is_valid():
		_fill_tween.kill()

func _draw() -> void:
	# An art-less panel would be invisible, which makes both laying a page out
	# in the editor and clicking through it in a test run impossible. Outline
	# the rect instead so a page can be blocked out and played before any
	# drawing exists. Never shown in a release build.
	if dialogue_only:
		return
	if _reveal_mask != null or _fill_texture != null:
		return
	if !Engine.is_editor_hint() and !OS.is_debug_build():
		return
	_draw_placeholder_outline()

func _draw_placeholder_outline() -> void:
	var placeholder_color: Color = PLACEHOLDER_LINE_COLOR
	placeholder_color.a *= (1.0 if Engine.is_editor_hint() else _placeholder_alpha)
	if placeholder_color.a <= 0.01:
		return

	var rect := Rect2(Vector2.ZERO, size)
	var corners: Array[Vector2] = [
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y),
	]
	for i in range(corners.size()):
		_draw_dashed_line(corners[i], corners[(i + 1) % corners.size()], placeholder_color)

func _draw_dashed_line(from: Vector2, to: Vector2, line_col: Color) -> void:
	var total_length: float = from.distance_to(to)
	if total_length <= 0.0:
		return
	var direction: Vector2 = (to - from) / total_length
	var travelled: float = 0.0
	while travelled < total_length:
		var segment_end: float = minf(travelled + PLACEHOLDER_DASH_LENGTH, total_length)
		draw_line(from + direction * travelled, from + direction * segment_end, line_col, 1.5)
		travelled = segment_end + PLACEHOLDER_DASH_LENGTH

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
