extends RefCounted
class_name CollectionElasticScroll

## Wheel scrolling for one of the codex panel's lists: a wheel step sets the
## list gliding, and pushing past either end lets it stretch a little and
## spring back. The ScrollContainer's own wheel scrolling is kept out of it.

const WHEEL_IMPULSE: float = 620.0
const MAX_VELOCITY: float = 2600.0
const FRICTION: float = 7.0
const EDGE_IMPULSE: float = 260.0
const EDGE_SPRING: float = 46.0
const EDGE_DAMPING: float = 10.0
const MAX_OVERSHOOT: float = 30.0

var scroll: ScrollContainer
var content: Control
## Whether the list is showing and should take the wheel.
var is_active: Callable
var velocity: float = 0.0
var overshoot: float = 0.0
var overshoot_velocity: float = 0.0

func _init(scroll_container: ScrollContainer, scroll_content: Control, active_check: Callable) -> void:
	scroll = scroll_container
	content = scroll_content
	is_active = active_check
	scroll.gui_input.connect(_on_scroll_gui_input)

func _on_scroll_gui_input(event: InputEvent) -> void:
	if is_active.call() and handle_wheel(event):
		scroll.accept_event()

## Takes a wheel step that no control took while the mouse is over the list.
func handle_unhandled_wheel(event: InputEvent) -> bool:
	if !(event is InputEventMouseButton) or !is_active.call():
		return false
	if !scroll.get_global_rect().has_point(scroll.get_viewport().get_mouse_position()):
		return false
	return handle_wheel(event)

func handle_wheel(event: InputEvent) -> bool:
	var direction: float = _get_wheel_direction(event)
	if direction == 0.0:
		return false

	var max_scroll: float = get_max_scroll()
	var current_scroll: float = float(scroll.scroll_vertical)
	if max_scroll <= 0.0 or (current_scroll <= 0.0 and direction < 0.0) or (current_scroll >= max_scroll and direction > 0.0):
		overshoot_velocity += -direction * EDGE_IMPULSE
	else:
		velocity = clampf(velocity + direction * WHEEL_IMPULSE, -MAX_VELOCITY, MAX_VELOCITY)
	return true

func update(delta: float) -> void:
	if !is_active.call():
		reset()
		return

	var max_scroll: float = get_max_scroll()
	if max_scroll <= 0.0:
		velocity = 0.0
	else:
		var current_scroll: float = clampf(float(scroll.scroll_vertical), 0.0, max_scroll)
		if absf(velocity) > 0.5:
			var next_scroll: float = current_scroll + velocity * delta
			if next_scroll < 0.0:
				overshoot_velocity += -next_scroll * EDGE_SPRING
				next_scroll = 0.0
				velocity *= 0.16
			elif next_scroll > max_scroll:
				overshoot_velocity -= (next_scroll - max_scroll) * EDGE_SPRING
				next_scroll = max_scroll
				velocity *= 0.16
			scroll.scroll_vertical = int(round(next_scroll))
			var friction_weight: float = 1.0 - exp(-FRICTION * delta)
			velocity = lerpf(velocity, 0.0, friction_weight)
		else:
			velocity = 0.0

	var spring_acceleration: float = -overshoot * EDGE_SPRING - overshoot_velocity * EDGE_DAMPING
	overshoot_velocity += spring_acceleration * delta
	overshoot += overshoot_velocity * delta
	overshoot = clampf(overshoot, -MAX_OVERSHOOT, MAX_OVERSHOOT)
	if absf(overshoot) < 0.1 and absf(overshoot_velocity) < 0.1:
		overshoot = 0.0
		overshoot_velocity = 0.0
	_apply_visual()

func reset() -> void:
	velocity = 0.0
	overshoot = 0.0
	overshoot_velocity = 0.0
	content.scale = Vector2.ONE
	content.position.y = -float(scroll.scroll_vertical)

func get_max_scroll() -> float:
	var scroll_bar := scroll.get_v_scroll_bar()
	if scroll_bar != null:
		return maxf(0.0, scroll_bar.max_value - scroll_bar.page)
	var content_height: float = maxf(content.size.y, content.get_combined_minimum_size().y)
	return maxf(0.0, content_height - scroll.size.y)

func _apply_visual() -> void:
	content.scale = Vector2.ONE
	content.position.y = round(-float(scroll.scroll_vertical) + overshoot)

func _get_wheel_direction(event: InputEvent) -> float:
	if !(event is InputEventMouseButton):
		return 0.0
	var mouse_button := event as InputEventMouseButton
	if !mouse_button.pressed:
		return 0.0
	if mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		return 1.0
	if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP:
		return -1.0
	return 0.0
