extends TextureRect

const SWAY_ANGLE_DEGREES: float = 0.7
const SWAY_HALF_DURATION: float = 4.0

const SLIDE_DISTANCE: float = 650.0
const SLIDE_DOWN_DURATION: float = 0.45
const SLIDE_UP_DURATION: float = 0.35
const SLIDE_HOLD_DURATION: float = 0.6

const HOVER_LIFT_DISTANCE: float = 14.0
const HOVER_MOVE_SPEED: float = 900.0
const HOVER_MOVE_MIN_DURATION: float = 0.12
const HOVER_MOVE_MAX_DURATION: float = 0.4
const HOVER_SHAKE_AMPLITUDE: float = 3.0
const HOVER_SHAKE_STEP_DURATION: float = 0.045

const SUNK_VISIBLE_HEIGHT: float = 26.0
const SINK_FALL_DURATION: float = 0.22
const SINK_BOUNCE_DISTANCE: float = 10.0
const SINK_BOUNCE_DURATION: float = 0.11

var rest_position: Vector2
var rest_center_x: float
var rest_visible_center_y: float
var hand_follower: Control
var hand_follower_rest_y: float = 0.0

var sway_tween: Tween
var slide_tween: Tween
var hide_tween: Tween
var vertical_tween: Tween
var shake_tween: Tween

var page_slide_offset: float = 0.0
var vertical_offset: float = 0.0
var shake_offset_x: float = 0.0

var turn_base_offset: float = 0.0
var is_turn_active: bool = true
var is_off_screen: bool = false
var pending_screen_exit_callback: Callable
var is_hovered: bool = false

func _ready() -> void:
	rest_position = position
	rest_center_x = rest_position.x + size.x * 0.5
	rest_visible_center_y = (rest_position.y + get_viewport_rect().size.y) * 0.5
	pivot_offset = Vector2(size.x * 0.5, 0.0)
	set_process(true)
	start_sway()

func _process(_delta: float) -> void:
	update_hover_state()

# Polls rect containment directly instead of relying on Control's
# mouse_entered/exited, which only fires for the single topmost overlapped
# control -- with the stamps drawn on top of the codex, that system would
# never report the codex as hovered wherever a stamp covers it.
func update_hover_state() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var hovering: bool = get_global_rect().has_point(mouse_pos)
	if !hovering and hand_follower != null and is_instance_valid(hand_follower):
		hovering = hand_follower.get_global_rect().has_point(mouse_pos)
	if hovering == is_hovered:
		return
	is_hovered = hovering
	if hovering:
		play_hover_shake()
	animate_vertical_offset_smooth(get_target_vertical_offset())

func set_hand_follower(hand_node: Control) -> void:
	if hand_follower != hand_node:
		if hand_follower != null and is_instance_valid(hand_follower):
			hand_follower.rotation_degrees = 0.0
		hand_follower = hand_node
		if hand_follower != null and is_instance_valid(hand_follower):
			hand_follower_rest_y = hand_follower.position.y
		sync_follower_rotation()
	apply_follower_position()

func start_sway() -> void:
	sway_tween = create_tween().set_loops().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	sway_tween.tween_method(set_sway_rotation, 0.0, SWAY_ANGLE_DEGREES, SWAY_HALF_DURATION)
	sway_tween.tween_method(set_sway_rotation, SWAY_ANGLE_DEGREES, -SWAY_ANGLE_DEGREES, SWAY_HALF_DURATION * 2.0)
	sway_tween.tween_method(set_sway_rotation, -SWAY_ANGLE_DEGREES, 0.0, SWAY_HALF_DURATION)

func set_sway_rotation(value: float) -> void:
	rotation_degrees = value
	sync_follower_rotation()

func sync_follower_rotation() -> void:
	if hand_follower != null and is_instance_valid(hand_follower):
		hand_follower.rotation_degrees = rotation_degrees

func get_total_y_offset() -> float:
	return page_slide_offset + vertical_offset

func apply_position() -> void:
	position = rest_position + Vector2(shake_offset_x, get_total_y_offset())
	apply_follower_position()

func apply_follower_position() -> void:
	if hand_follower != null and is_instance_valid(hand_follower):
		hand_follower.position.y = hand_follower_rest_y + get_total_y_offset()

func set_page_slide_offset(value: float) -> void:
	page_slide_offset = value
	apply_position()

func set_vertical_offset(value: float) -> void:
	vertical_offset = value
	apply_position()

func set_shake_offset_x(value: float) -> void:
	shake_offset_x = value
	apply_position()

# While sunk (opponent's turn), hovering should reveal the stamps fully,
# same as an active turn -- not just nudge up a few pixels.
func get_target_vertical_offset() -> float:
	if is_hovered:
		return 0.0 if turn_base_offset > 0.0 else -HOVER_LIFT_DISTANCE
	return turn_base_offset

func play_hover_shake() -> void:
	if shake_tween != null and shake_tween.is_valid():
		shake_tween.kill()
	shake_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	shake_tween.tween_method(set_shake_offset_x, 0.0, HOVER_SHAKE_AMPLITUDE, HOVER_SHAKE_STEP_DURATION)
	shake_tween.tween_method(set_shake_offset_x, HOVER_SHAKE_AMPLITUDE, -HOVER_SHAKE_AMPLITUDE, HOVER_SHAKE_STEP_DURATION * 2.0)
	shake_tween.tween_method(set_shake_offset_x, -HOVER_SHAKE_AMPLITUDE, 0.0, HOVER_SHAKE_STEP_DURATION)

func animate_vertical_offset_smooth(target: float) -> void:
	if vertical_tween != null and vertical_tween.is_valid():
		vertical_tween.kill()
	var distance: float = absf(target - vertical_offset)
	var duration: float = clampf(distance / HOVER_MOVE_SPEED, HOVER_MOVE_MIN_DURATION, HOVER_MOVE_MAX_DURATION)
	vertical_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	vertical_tween.tween_method(set_vertical_offset, vertical_offset, target, duration)

func set_turn_active(active: bool) -> void:
	if is_turn_active == active:
		return
	is_turn_active = active
	var sunk_distance: float = max((get_viewport_rect().size.y - rest_position.y) - SUNK_VISIBLE_HEIGHT, 0.0)
	turn_base_offset = 0.0 if active else sunk_distance
	animate_vertical_offset_bounce(get_target_vertical_offset())

func animate_vertical_offset_bounce(target: float) -> void:
	if vertical_tween != null and vertical_tween.is_valid():
		vertical_tween.kill()
	var start: float = vertical_offset
	if is_equal_approx(start, target):
		set_vertical_offset(target)
		return
	var direction_sign: float = 1.0 if target > start else -1.0
	var overshoot: float = target + direction_sign * SINK_BOUNCE_DISTANCE
	var rebound: float = target - direction_sign * SINK_BOUNCE_DISTANCE * 0.4
	vertical_tween = create_tween()
	vertical_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	vertical_tween.tween_method(set_vertical_offset, start, overshoot, SINK_FALL_DURATION)
	vertical_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	vertical_tween.tween_method(set_vertical_offset, overshoot, rebound, SINK_BOUNCE_DURATION)
	vertical_tween.tween_method(set_vertical_offset, rebound, target, SINK_BOUNCE_DURATION)

func play_turn_page_animation() -> void:
	if slide_tween != null and slide_tween.is_valid():
		slide_tween.kill()
	if hide_tween != null and hide_tween.is_valid():
		hide_tween.kill()
	set_page_slide_offset(0.0)
	set_hand_follower_visible(true)
	is_off_screen = false
	pending_screen_exit_callback = Callable()

	slide_tween = create_tween()
	slide_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	slide_tween.tween_method(set_page_slide_offset, 0.0, SLIDE_DISTANCE, SLIDE_DOWN_DURATION)
	slide_tween.tween_interval(SLIDE_HOLD_DURATION)
	slide_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	slide_tween.tween_callback(Callable(self, "_on_screen_return"))
	slide_tween.tween_method(set_page_slide_offset, SLIDE_DISTANCE, 0.0, SLIDE_UP_DURATION)

	# The codex crosses below the screen partway through the down-slide, not
	# at its end -- flag that moment as its own tween (rather than a step
	# within slide_tween) so it can fire mid-flight without splitting the
	# down-slide into two tweeners, which would kill its single continuous
	# ease-in curve.
	var screen_exit_progress: float = clampf((get_viewport_rect().size.y - rest_position.y) / SLIDE_DISTANCE, 0.0, 1.0)
	var screen_exit_delay: float = SLIDE_DOWN_DURATION * sqrt(screen_exit_progress)
	hide_tween = create_tween()
	hide_tween.tween_interval(screen_exit_delay)
	hide_tween.tween_callback(Callable(self, "_on_screen_exit"))

func _on_screen_exit() -> void:
	is_off_screen = true
	set_hand_follower_visible(false)
	if pending_screen_exit_callback.is_valid():
		var callback: Callable = pending_screen_exit_callback
		pending_screen_exit_callback = Callable()
		callback.call()

func _on_screen_return() -> void:
	is_off_screen = false
	set_hand_follower_visible(true)

# Lets the caller defer applying the new page's stamp data (populate_stamp_hand)
# until the codex has actually left the screen -- e.g. a networked turn-page
# action can resolve well before the down-slide finishes, and swapping the
# cards right then would show the old->new change while still visible. If no
# slide is currently in flight (e.g. an unusually slow response landing after
# the whole animation already finished), runs immediately rather than waiting
# for an exit event that may never come again.
func run_when_off_screen(callback: Callable) -> void:
	var animation_active: bool = (slide_tween != null and slide_tween.is_valid()) or (hide_tween != null and hide_tween.is_valid())
	if is_off_screen or !animation_active:
		callback.call()
	else:
		pending_screen_exit_callback = callback

func set_hand_follower_visible(value: bool) -> void:
	# Uses modulate rather than the "visible" property: a server-state
	# refresh landing mid-animation calls configure_hand_container(), which
	# always forces visible = true, and would silently cancel a hide done
	# that way. Alpha isn't touched by that code path, so it sticks.
	if hand_follower != null and is_instance_valid(hand_follower):
		hand_follower.modulate.a = 1.0 if value else 0.0
