extends Node
class_name FeatureHint

## Gates a button behind a story unlock and draws the eye to it - a
## hand-drawn arrow, or the tutorial's glow behind it - until the player has
## used it once.
##
## Drop one of these into whichever scene owns the button, set feature_id and
## target_path, and it takes care of the rest:
##
##   locked   -> the button is disabled (the story has not unlocked it yet)
##   unlocked -> the button works; an arrow bobs next to it, or a glow pulses
##               behind it
##   used     -> the hint is gone for good, on this and every later session
##
## Adding a hint to a button somewhere else later is one more node and one
## more constant in StoryFeatures - nothing here changes.
##
## The arrow lives in its own CanvasLayer above everything (the top bar sits at
## layer 1200), and follows the target's screen rect every frame, so it works
## for buttons that animate in, re-layout on resize, or live in an autoload
## scene like GlobalTopBar. The glow is a HintGlow behind the target - its
## child, so it moves, scales and hides with it - unless glow_behind_path puts
## it further back, where it is kept on the target every frame instead.

const ARROW_CANVAS_LAYER: int = 1250
const ARROW_INK_COLOR: Color = UiPalette.INK
const ARROW_THICKNESS: float = 3.0
const ARROW_HEAD_LENGTH: float = 18.0
const ARROW_HEAD_HALF_WIDTH: float = 9.0
const RESOLVE_RETRY_FRAMES: int = 30

enum ArrowSide { LEFT, RIGHT, ABOVE, BELOW }
enum HintStyle { ARROW, GLOW }

## Which unlock this hint is about. See StoryFeatures for the known ids.
@export var feature_id: String = ""

## The button (or any Control) the arrow points at. Leave empty and set
## top_bar_button_id instead when the button lives in GlobalTopBar.
@export var target_path: NodePath

## Resolves the target from GlobalTopBar by id ("buy_packs", "settings", ...)
## for buttons that are not part of this scene.
@export var top_bar_button_id: String = ""

## Disables the target while the feature is still locked. The hint only ever
## disables - it never force-enables a button that something else turned off
## for its own reasons.
@export var lock_target_until_unlocked: bool = true

## ARROW points at the target from beside it; GLOW pulses behind it, and only
## while the target can be pressed.
@export var hint_style: HintStyle = HintStyle.ARROW

@export_group("Arrow")
@export var arrow_side: ArrowSide = ArrowSide.LEFT
## Nudges the arrow relative to the side it sits on.
@export var arrow_offset: Vector2 = Vector2.ZERO
## Gap between the arrow tip and the edge of the button.
@export_range(0.0, 200.0, 1.0) var arrow_gap: float = 14.0
@export_range(20.0, 300.0, 1.0) var arrow_length: float = 70.0
## Optional drawn arrow. Without one, an ink-style arrow is drawn in code.
@export var arrow_texture: Texture2D
@export var arrow_color: Color = ARROW_INK_COLOR
@export_range(0.0, 60.0, 1.0) var bob_distance: float = 10.0
@export_range(0.1, 4.0, 0.05) var bob_seconds: float = 0.9

@export_group("Glow")
## How far the glow spreads, as a multiple of the target's size. The default
## is the tutorial's End Turn tab glow.
@export var glow_spread: Vector2 = Vector2(2.2, 3.0)
## Puts the glow behind this node instead of right behind the target, still
## centred on the target. For a button you can see through: behind the street
## view, the Play window's glow lights only the street, and the opponent
## standing in it stays on top.
@export var glow_behind_path: NodePath

var _target: Control
var _arrow_layer: CanvasLayer
var _arrow: Control
var _glow: HintGlow
var _locked_by_hint: bool = false
var _hint_active: bool = false
var _bob_phase: float = 0.0
var _resolve_frames_left: int = RESOLVE_RETRY_FRAMES

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	set_process(true)
	_resolve_frames_left = RESOLVE_RETRY_FRAMES
	# Unlocking usually happens in a reward scene, but a feature can also be
	# unlocked while the screen holding its button is already open.
	StoryProgressStore.feature_unlocked.connect(_on_progress_changed)
	StoryProgressStore.feature_hint_seen.connect(_on_progress_changed)
	call_deferred("_refresh")

func _on_progress_changed(changed_feature_id: String) -> void:
	if changed_feature_id == feature_id.strip_edges():
		_refresh()

func _exit_tree() -> void:
	_release_target_lock()
	_destroy_arrow()
	# At once, not faded: a top bar button outlives this scene.
	if _glow != null and is_instance_valid(_glow):
		_glow.queue_free()
	_glow = null

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if _target == null or !is_instance_valid(_target):
		# Targets in autoload scenes (GlobalTopBar) are wired up by whichever
		# screen is opening, which can land a frame or two after this node.
		if _resolve_frames_left > 0:
			_resolve_frames_left -= 1
			_refresh()
		return

	if _hint_active and hint_style == HintStyle.GLOW:
		_sync_glow()

	if _arrow == null:
		return

	_bob_phase = fmod(_bob_phase + delta / maxf(0.05, bob_seconds), 1.0)
	_update_arrow_placement()

## Re-evaluates lock and hint state. Call after unlocking a feature while the
## screen holding the button is already open.
func _refresh() -> void:
	_target = _resolve_target()
	if _target == null:
		return

	_resolve_frames_left = 0
	_apply_lock_state()
	_apply_hint_state()

func _resolve_target() -> Control:
	if !top_bar_button_id.strip_edges().is_empty():
		var top_bar := get_node_or_null("/root/GlobalTopBar")
		if top_bar != null and top_bar.has_method("get_button"):
			return top_bar.get_button(top_bar_button_id.strip_edges()) as Control
		return null

	if target_path.is_empty():
		return null
	return get_node_or_null(target_path) as Control

func _apply_lock_state() -> void:
	if !lock_target_until_unlocked:
		return

	var button := _target as BaseButton
	if button == null:
		return

	if StoryProgressStore.is_feature_unlocked(feature_id):
		_release_target_lock()
		return

	if !button.disabled:
		button.disabled = true
		_locked_by_hint = true

func _release_target_lock() -> void:
	if !_locked_by_hint:
		return
	_locked_by_hint = false
	var button := _target as BaseButton
	if button != null and is_instance_valid(button):
		button.disabled = false

func _apply_hint_state() -> void:
	var should_show: bool = StoryProgressStore.should_show_feature_hint(feature_id)
	if should_show == _hint_active:
		return

	_hint_active = should_show
	if should_show:
		if hint_style == HintStyle.GLOW:
			_sync_glow()
		else:
			_create_arrow()
		_connect_target()
	else:
		_destroy_arrow()
		_dismiss_glow()

func _connect_target() -> void:
	var button := _target as BaseButton
	if button != null:
		if !button.pressed.is_connected(_on_target_used):
			button.pressed.connect(_on_target_used)
		return

	if !_target.gui_input.is_connected(_on_target_gui_input):
		_target.gui_input.connect(_on_target_gui_input)

func _on_target_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event != null and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		_on_target_used()

func _on_target_used() -> void:
	StoryProgressStore.mark_feature_hint_seen(feature_id)
	_hint_active = false
	_destroy_arrow()
	_dismiss_glow()

## The glow says "press this now", so it stays away while the target is
## disabled - the Play button is, until the opponent has walked up to the
## window.
func _sync_glow() -> void:
	if _glow != null and !is_instance_valid(_glow):
		_glow = null
	var button := _target as BaseButton
	var pressable: bool = button == null or !button.disabled
	if pressable and _glow == null:
		var host: Control = _resolve_glow_host()
		_glow = HintGlow.attach(host, _glow_centre_on(host), _target.size * glow_spread)
	elif !pressable and _glow != null:
		_dismiss_glow()
	elif _glow != null:
		# Buttons in a container, or laid over the artwork, get their size a
		# frame late and again on every window resize.
		var host := _glow.get_parent() as Control
		_glow.place(_glow_centre_on(host), _target.size * glow_spread)
		_glow.visible = _target.is_visible_in_tree()

func _resolve_glow_host() -> Control:
	if glow_behind_path.is_empty():
		return _target
	var host := get_node_or_null(glow_behind_path) as Control
	return host if host != null else _target

## The target's middle, in the host's own pixels.
func _glow_centre_on(host: Control) -> Vector2:
	var centre: Vector2 = _target.size * 0.5
	if host == _target:
		return centre
	return host.get_global_transform().affine_inverse() * (_target.get_global_transform() * centre)

func _dismiss_glow() -> void:
	if _glow != null and is_instance_valid(_glow):
		_glow.dismiss()
	_glow = null

func _create_arrow() -> void:
	if _arrow != null:
		return

	_arrow_layer = CanvasLayer.new()
	_arrow_layer.layer = ARROW_CANVAS_LAYER
	add_child(_arrow_layer)

	_arrow = Control.new()
	_arrow.name = "FeatureHintArrow"
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.draw.connect(_on_arrow_draw)
	_arrow_layer.add_child(_arrow)
	_update_arrow_placement()

func _destroy_arrow() -> void:
	if _arrow_layer != null and is_instance_valid(_arrow_layer):
		_arrow_layer.queue_free()
	_arrow_layer = null
	_arrow = null

func _update_arrow_placement() -> void:
	if _arrow == null or _target == null or !is_instance_valid(_target):
		return

	var visible_target: bool = _target.is_visible_in_tree()
	_arrow.visible = visible_target
	if !visible_target:
		return

	var target_rect: Rect2 = _target.get_global_rect()
	var bob: float = sin(_bob_phase * TAU) * bob_distance
	var arrow_size := Vector2(arrow_length, arrow_length)
	var origin: Vector2 = target_rect.get_center()

	match arrow_side:
		ArrowSide.LEFT:
			origin.x = target_rect.position.x - arrow_gap - arrow_length + bob
			origin.y -= arrow_length * 0.5
		ArrowSide.RIGHT:
			origin.x = target_rect.end.x + arrow_gap - bob
			origin.y -= arrow_length * 0.5
		ArrowSide.ABOVE:
			origin.x -= arrow_length * 0.5
			origin.y = target_rect.position.y - arrow_gap - arrow_length + bob
		ArrowSide.BELOW:
			origin.x -= arrow_length * 0.5
			origin.y = target_rect.end.y + arrow_gap - bob

	_arrow.size = arrow_size
	_arrow.position = origin + arrow_offset
	_arrow.queue_redraw()

func _on_arrow_draw() -> void:
	if arrow_texture != null:
		_arrow.draw_texture_rect(arrow_texture, Rect2(Vector2.ZERO, _arrow.size), false, arrow_color)
		return
	_draw_ink_arrow()

## A simple two-stroke arrow in the game's ink colour, pointing at the button.
func _draw_ink_arrow() -> void:
	var half: float = _arrow.size.y * 0.5
	var tail: Vector2
	var tip: Vector2

	match arrow_side:
		ArrowSide.LEFT:
			tail = Vector2(0.0, half)
			tip = Vector2(_arrow.size.x, half)
		ArrowSide.RIGHT:
			tail = Vector2(_arrow.size.x, half)
			tip = Vector2(0.0, half)
		ArrowSide.ABOVE:
			tail = Vector2(_arrow.size.x * 0.5, 0.0)
			tip = Vector2(_arrow.size.x * 0.5, _arrow.size.y)
		ArrowSide.BELOW:
			tail = Vector2(_arrow.size.x * 0.5, _arrow.size.y)
			tip = Vector2(_arrow.size.x * 0.5, 0.0)

	_arrow.draw_line(tail, tip, arrow_color, ARROW_THICKNESS, true)

	var direction: Vector2 = (tip - tail).normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	var head_base: Vector2 = tip - direction * ARROW_HEAD_LENGTH
	var head_points := PackedVector2Array([
		tip,
		head_base + perpendicular * ARROW_HEAD_HALF_WIDTH,
		head_base - perpendicular * ARROW_HEAD_HALF_WIDTH,
	])
	_arrow.draw_colored_polygon(head_points, arrow_color)
