extends Button
class_name CardVisual

signal drag_started(card_visual: CardVisual)
signal drag_moved(card_visual: CardVisual)
signal drag_released(card_visual: CardVisual)

@export var angle_x_max: float = 13.0
@export var angle_y_max: float = 13.0
@export var hover_scale: float = 1.11
@export var drag_scale: float = 1.05
@export var drop_target_scale: float = 0.5

@onready var shadow: TextureRect = $Shadow
@onready var card_face: TextureRect = $CardFace
@onready var shimmer: ColorRect = $Shimmer
@onready var duration_label: Label = $DurationLabel
@onready var name_label: Label = $NameLabel
@onready var pattern_view: CardPatternView = $PatternView

var card: Card
var face_material: ShaderMaterial
var tween_hover: Tween
var tween_reset: Tween
var tween_move: Tween
var normal_shadow_alpha: float = 0.22
var home_position: Vector2 = Vector2.ZERO
var hand_index: int = -1
var owner_color: int = 0
var draggable: bool = true
var face_down: bool = false
var is_dragging: bool = false
var is_assigned: bool = false
var is_hovered: bool = false
var drop_target_active: bool = false
var drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	pivot_offset = size * 0.5
	face_material = card_face.material.duplicate() as ShaderMaterial
	card_face.material = face_material
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	set_process(false)
	_apply_card()

func _process(_delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position() - drag_offset
		drag_moved.emit(self)
		return

	if is_hovered:
		update_tilt_from_mouse()

func _input(event: InputEvent) -> void:
	if not is_dragging:
		return

	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and not mouse_button.pressed:
			finish_drag()
			accept_event()

func set_card(value: Card) -> void:
	card = value
	if is_node_ready():
		_apply_card()

func set_face_down(value: bool) -> void:
	face_down = value
	if is_node_ready():
		_apply_face_state()

func set_hand_context(new_owner_color: int, new_hand_index: int, new_home_position: Vector2) -> void:
	owner_color = new_owner_color
	hand_index = new_hand_index
	set_home_position(new_home_position, false)

func set_home_position(new_home_position: Vector2, animate: bool) -> void:
	home_position = new_home_position
	if is_dragging or is_assigned:
		return

	if animate:
		_kill_move_tween()
		tween_move = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween_move.tween_property(self, "position", home_position, 0.18)
	else:
		position = home_position

func set_drop_target_active(active: bool) -> void:
	if drop_target_active == active or is_assigned:
		return

	drop_target_active = active
	var target_scale: Vector2 = Vector2.ONE * (drop_target_scale if active else drag_scale)
	_tween_scale(target_scale, 0.12)

func fly_home() -> void:
	is_dragging = false
	drop_target_active = false
	set_process(false)
	z_index = 0
	disabled = false
	_kill_move_tween()
	tween_move = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween_move.tween_property(self, "position", home_position, 0.26)
	tween_move.parallel().tween_property(self, "scale", Vector2.ONE, 0.22)
	tween_move.parallel().tween_property(self, "rotation", 0.0, 0.22)
	tween_move.parallel().tween_property(face_material, "shader_parameter/x_rot", 0.0, 0.22)
	tween_move.parallel().tween_property(face_material, "shader_parameter/y_rot", 0.0, 0.22)
	tween_move.parallel().tween_property(shadow, "self_modulate:a", normal_shadow_alpha, 0.22)

func fly_from_global_position(start_global_position: Vector2) -> void:
	is_dragging = false
	drop_target_active = false
	set_process(false)
	_kill_hover_tweens()
	_kill_move_tween()

	global_position = start_global_position
	scale = Vector2.ONE * 0.52
	rotation = deg_to_rad(-8.0 if owner_color == 1 else 8.0)
	z_index = 90
	shadow.self_modulate.a = 0.4

	tween_move = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween_move.tween_property(self, "position", home_position, 0.44)
	tween_move.parallel().tween_property(self, "scale", Vector2.ONE, 0.38)
	tween_move.parallel().tween_property(self, "rotation", 0.0, 0.38)
	tween_move.parallel().tween_property(shadow, "self_modulate:a", normal_shadow_alpha, 0.38)
	tween_move.tween_callback(Callable(self, "_finish_draw_fly"))

func play_draw_pulse() -> void:
	_kill_hover_tweens()
	tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_hover.tween_property(self, "scale", Vector2.ONE * 1.05, 0.08)
	tween_hover.tween_property(self, "scale", Vector2.ONE * 0.96, 0.16)

func _finish_draw_fly() -> void:
	z_index = 0

func assign_and_hide() -> void:
	is_assigned = true
	is_dragging = false
	drop_target_active = false
	set_process(false)
	disabled = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func _apply_card() -> void:
	if card == null:
		name_label.text = ""
		duration_label.text = ""
		pattern_view.set_pattern([])
	else:
		name_label.text = card.card_name
		duration_label.text = "INF" if card.duration < 0 else str(card.duration)
		pattern_view.set_pattern(card.movement_pattern)

	_apply_face_state()

func _apply_face_state() -> void:
	name_label.visible = !face_down
	duration_label.visible = !face_down
	pattern_view.visible = !face_down
	shimmer.visible = !face_down
	card_face.material = null if face_down else face_material
	if face_down:
		rotation = 0.0
		scale = Vector2.ONE

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			start_drag()
			accept_event()
		return

	if not event is InputEventMouseMotion:
		return
	if is_dragging:
		return

	update_tilt_from_mouse()

func start_drag() -> void:
	if not draggable or is_assigned or face_down:
		return

	_kill_hover_tweens()
	_kill_move_tween()
	is_dragging = true
	is_hovered = false
	drop_target_active = false
	disabled = false
	set_process(true)
	move_to_front()
	z_index = 100
	drag_offset = get_global_mouse_position() - global_position
	scale = Vector2.ONE * drag_scale
	drag_started.emit(self)

func finish_drag() -> void:
	is_dragging = false
	set_process(false)
	drag_released.emit(self)

func _on_mouse_entered() -> void:
	if is_dragging or is_assigned or face_down:
		return

	is_hovered = true
	set_process(true)
	move_to_front()
	z_index = 50
	if tween_reset and tween_reset.is_running():
		tween_reset.kill()
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween_hover.tween_property(self, "scale", Vector2.ONE * hover_scale, 0.18)
	tween_hover.parallel().tween_property(shadow, "self_modulate:a", 0.34, 0.18)

func _on_mouse_exited() -> void:
	if is_dragging or is_assigned or face_down:
		return

	is_hovered = false
	set_process(false)
	z_index = 0
	reset_tilt_and_scale()

func update_tilt_from_mouse() -> void:
	if face_down:
		return

	var mouse_pos: Vector2 = get_local_mouse_position()
	var x_ratio: float = clampf(mouse_pos.x / size.x, 0.0, 1.0)
	var y_ratio: float = clampf(mouse_pos.y / size.y, 0.0, 1.0)
	var y_rot: float = lerpf(-angle_y_max, angle_y_max, x_ratio)
	var x_rot: float = lerpf(angle_x_max, -angle_x_max, y_ratio)

	face_material.set_shader_parameter("x_rot", x_rot)
	face_material.set_shader_parameter("y_rot", y_rot)
	rotation = deg_to_rad(y_rot * 0.08)

func reset_tilt_and_scale() -> void:
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	if tween_reset and tween_reset.is_running():
		tween_reset.kill()
	tween_reset = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween_reset.tween_property(self, "scale", Vector2.ONE, 0.24)
	tween_reset.parallel().tween_property(self, "rotation", 0.0, 0.24)
	tween_reset.parallel().tween_property(shadow, "self_modulate:a", normal_shadow_alpha, 0.24)
	if face_material:
		tween_reset.parallel().tween_property(face_material, "shader_parameter/x_rot", 0.0, 0.24)
		tween_reset.parallel().tween_property(face_material, "shader_parameter/y_rot", 0.0, 0.24)

func _tween_scale(target_scale: Vector2, duration: float) -> void:
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_hover.tween_property(self, "scale", target_scale, duration)

func _kill_hover_tweens() -> void:
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	if tween_reset and tween_reset.is_running():
		tween_reset.kill()

func _kill_move_tween() -> void:
	if tween_move and tween_move.is_running():
		tween_move.kill()
