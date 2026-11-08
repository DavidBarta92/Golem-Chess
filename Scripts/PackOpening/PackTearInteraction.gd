extends Control
class_name PackTearInteraction

## The player tears a pack open. A drag along the top of the pack runs the tear
## after the mouse, either way across; a click tears it by itself. Reading the
## mouse is the shared cut logic (CutArea); what belongs to a pack is here: the
## tear follows at the speed paper tears, it never goes back, and the pack
## swells, gives and rustles with it.
##
## Sits over the whole overlay, so its positions are the overlay's. It is done
## when `tear_finished` has been sent and frees itself.

signal tear_started
signal tear_finished(direction: int)

## The pack's picture has an empty border this wide, as a share of its width on
## each side: the tear, and the mouse's way, run between the printed edges.
const EDGE_MARGIN: float = 0.12
## How quickly the tear closes on the mouse.
const FOLLOW_RATE: float = 18.0
## However fast the mouse, paper tears at this speed, in pack widths a second.
const MAX_TEAR_SPEED: float = 5.5
const SELF_TEAR_SPEED: float = 3.4
## Let go past this share of the width and the rest goes by itself.
const FINISH_BY_ITSELF_FROM: float = 0.55
## Mouse this close to the far edge counts as there.
const END_MARGIN: float = 0.02
## A rustle every time the tear has run this much further.
const SOUND_STEP: float = 0.075
const WIND_UP_SECONDS: float = 0.3
const WIND_UP_SHAKE: float = 0.014
const TEAR_SHAKE: float = 0.006
const PULL_DEGREES: float = 7.0
const SETTLE_SECONDS: float = 0.14
## The printed "tear here" line and its running glint.
const HINT_DASH: float = 11.0
const HINT_GAP: float = 8.0
const HINT_RUN_SECONDS: float = 1.5
const HINT_COLOR: Color = Color(UiPalette.INK, 0.62)
const HINT_GLINT_COLOR: Color = Color(UiPalette.INK, 1.0)

var pack_view: Pack3DView
var cut_area: CutArea
var guide_start: Vector2
var guide_end: Vector2
var front: float = 0.0
var target_front: float = 0.0
var direction: int = 0
var started: bool = false
var tearing_by_itself: bool = false
var done: bool = false
var hint_time: float = 0.0
var next_sound_at: float = 0.0
var flecks: CPUParticles2D

## `pack_area` is the pack on the overlay; the guide runs along `cut_y` of its height.
func bind(new_pack_view: Pack3DView, pack_area: Rect2, cut_y: float) -> void:
	pack_view = new_pack_view
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin: float = pack_area.size.x * EDGE_MARGIN
	guide_start = pack_area.position + Vector2(margin, pack_area.size.y * cut_y)
	guide_end = guide_start + Vector2(pack_area.size.x - margin * 2.0, 0.0)

	cut_area = CutArea.new()
	cut_area.name = "PackCutArea"
	cut_area.position = pack_area.position
	cut_area.size = pack_area.size
	# Only how far along it counts: a tear does not leave its line, wherever the mouse goes.
	cut_area.tolerance = INF
	cut_area.guide = CutGuide.line(guide_start - pack_area.position, guide_end - pack_area.position)
	add_child(cut_area)
	cut_area.cut_started.connect(_on_cut_started)
	cut_area.cut_moved.connect(_on_cut_moved)
	cut_area.cut_ended.connect(_on_cut_ended)
	cut_area.tapped.connect(func(_position: Vector2) -> void: tear_by_itself())
	cut_area.mouse_entered.connect(func() -> void: pack_view.set_hovered(true))
	cut_area.mouse_exited.connect(func() -> void: pack_view.set_hovered(false))

	flecks = PackRevealFx.make_tear_flecks()
	add_child(flecks)

## Finishes the tear without the mouse, from wherever it has got to.
func tear_by_itself() -> void:
	if tearing_by_itself or done:
		return
	_start()
	if direction == 0:
		_set_direction(1)
	if front > 0.0:
		tearing_by_itself = true
		return
	var wind_up := create_tween().set_parallel(true)
	wind_up.tween_method(Callable(pack_view, "set_swell"), 0.0, 0.8, WIND_UP_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	wind_up.tween_property(pack_view, "shake_amount", _scaled_shake(WIND_UP_SHAKE), WIND_UP_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	wind_up.chain().tween_callback(func() -> void: tearing_by_itself = true)

func _start() -> void:
	if started:
		return
	started = true
	queue_redraw()
	create_tween().tween_property(pack_view, "motion_amount", 0.0, SETTLE_SECONDS)
	pack_view.set_hover_tracking_enabled(false)
	SFXManager.play("pack_crinkle")
	tear_started.emit()

func _set_direction(new_direction: int) -> void:
	direction = new_direction
	pack_view.set_tear_direction(direction)

func _on_cut_started(_stroke: CutStroke) -> void:
	_start()

func _on_cut_moved(stroke: CutStroke) -> void:
	if tearing_by_itself:
		return
	if direction == 0 and stroke.direction != 0:
		_set_direction(stroke.direction)
	if direction != 0:
		target_front = maxf(target_front, stroke.get_reach(direction))

func _on_cut_ended(_stroke: CutStroke) -> void:
	if direction == 0 or target_front >= FINISH_BY_ITSELF_FROM:
		tear_by_itself()

func _process(delta: float) -> void:
	if done:
		return
	if !started:
		hint_time += delta
		queue_redraw()
		return
	if tearing_by_itself:
		target_front = minf(1.0, target_front + SELF_TEAR_SPEED * delta)
	var previous: float = front
	var closing: float = lerpf(front, target_front, 1.0 - exp(-FOLLOW_RATE * delta))
	front = minf(closing, front + MAX_TEAR_SPEED * delta)
	if target_front >= 1.0 - END_MARGIN and front >= 1.0 - END_MARGIN:
		front = 1.0
	_show_front(previous, delta)
	if front >= 1.0:
		_finish()

func _show_front(previous: float, delta: float) -> void:
	var moved: float = front - previous
	pack_view.set_tear_front(lerpf(EDGE_MARGIN, 1.0 - EDGE_MARGIN, front) if front > 0.0 else 0.0)
	if !tearing_by_itself or front > 0.0:
		pack_view.set_swell(lerpf(0.8 if tearing_by_itself else 0.0, 1.0, front))
	pack_view.pull_yaw = -float(direction) * PULL_DEGREES * sin(front * PI)
	pack_view.shake_amount = _scaled_shake(TEAR_SHAKE) * minf(moved / maxf(delta, 0.001), 1.0)

	var running: bool = moved > 0.0005
	flecks.position = _front_position()
	flecks.direction = Vector2(-float(direction) * 0.6, -1.0)
	flecks.emitting = running
	while running and front >= next_sound_at:
		next_sound_at += SOUND_STEP
		SFXManager.play_pitched("pack_tear", randf_range(0.9, 1.14), 0.0)

func _front_position() -> Vector2:
	var along: float = front if direction >= 0 else 1.0 - front
	return guide_start.lerp(guide_end, along)

func _finish() -> void:
	done = true
	flecks.emitting = false
	pack_view.pull_yaw = 0.0
	pack_view.shake_amount = 0.0
	tear_finished.emit(direction)
	queue_free()

func _scaled_shake(amount: float) -> float:
	return amount if SettingsDataManager.is_screen_shake_enabled() else 0.0

## "Tear here", as a pack would have it printed.
func _draw() -> void:
	if started:
		return
	var width: float = guide_end.x - guide_start.x
	var glint: float = fposmod(hint_time / HINT_RUN_SECONDS, 1.0) * width
	var x: float = 0.0
	while x < width:
		var dash_end: float = minf(x + HINT_DASH, width)
		var lit: bool = glint >= x - HINT_GAP and glint < dash_end + HINT_GAP
		var y: float = guide_start.y
		draw_line(Vector2(guide_start.x + x, y), Vector2(guide_start.x + dash_end, y), HINT_GLINT_COLOR if lit else HINT_COLOR, 3.0 if lit else 2.0, true)
		x += HINT_DASH + HINT_GAP
