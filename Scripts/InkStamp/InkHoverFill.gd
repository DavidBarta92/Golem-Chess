extends Node

## Buttons fill with ink when hovered: the ink floods in from the edges along
## a ragged front, like ink spreading into paper (Shaders/ink_flood.gdshader),
## over FILL_SECONDS, and drains back out when the pointer leaves. The fill is
## a layer behind the button, so the outline and the label stay on top; the
## label turns from ink to paper as the ink reaches it. Pressing still fills
## at once - that is the pressed style.
##
## For the buttons drawn with the theme's plain hover - Button, MenuButton,
## OptionButton - and the match's tabs (MatchTabButton). Variations with a
## hover of their own, and flat buttons, are left alone.
##
## A popup menu's hover is a band of ink too, and its label turns to paper on
## it - but a popup draws a radio item's mark untinted. The theme's mark is
## white; while a popup is open, each radio item's mark is tinted here with
## its item's label colour: ink, paper on the hovered item.

const FLOOD_SHADER: Shader = preload("res://Shaders/ink_flood.gdshader")
const FRONT_NOISE_PATH: String = "res://ui/themes/stamp/ink_flood_noise.png"
const STAMP_MASK_PATH: String = "res://ui/themes/stamp/ink_stamp_mask.png"
## Theme types whose hover style floods.
const FLOODED_TYPES: Array[StringName] = [&"Button", &"MatchTabButton"]
const FILL_SECONDS: float = 0.5
const DRAIN_SECONDS: float = 0.25

var _material: ShaderMaterial
var _hover_styles: Array[StyleBox] = []
## Popup menus open now, whose radio marks follow the hover.
var _open_popups: Array[PopupMenu] = []

func _ready() -> void:
	set_process(false)
	var theme: Theme = ThemeDB.get_project_theme()
	if theme != null and ResourceLoader.exists(FRONT_NOISE_PATH) and ResourceLoader.exists(STAMP_MASK_PATH):
		for type in FLOODED_TYPES:
			if theme.has_stylebox(&"hover", type):
				_hover_styles.append(theme.get_stylebox(&"hover", type))
		_material = ShaderMaterial.new()
		_material.shader = FLOOD_SHADER
		_material.set_shader_parameter(&"front_noise", load(FRONT_NOISE_PATH))
		_material.set_shader_parameter(&"stamp_mask", load(STAMP_MASK_PATH))
	get_tree().node_added.connect(_on_node_added)
	_visit(get_tree().root)

func _process(_delta: float) -> void:
	for popup in _open_popups.duplicate():
		if !is_instance_valid(popup) or !popup.visible:
			_open_popups.erase(popup)
			continue
		_tint_radio_marks(popup)
	if _open_popups.is_empty():
		set_process(false)

func _visit(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_visit(child)

func _on_node_added(node: Node) -> void:
	var popup := node as PopupMenu
	if popup != null:
		var opened: Callable = _on_popup_opened.bind(popup)
		if !popup.about_to_popup.is_connected(opened):
			popup.about_to_popup.connect(opened)
		return
	var button := node as Button
	if button == null:
		return
	var entered: Callable = _on_mouse_entered.bind(button)
	if !button.mouse_entered.is_connected(entered):
		button.mouse_entered.connect(entered)
	var exited: Callable = _on_mouse_exited.bind(button)
	if !button.mouse_exited.is_connected(exited):
		button.mouse_exited.connect(exited)
	# The button's own hover, which it redraws on: in an embedded window (the
	# settings dialog's OK) the pointer can reach it without mouse_entered.
	var drawn: Callable = _on_button_drawn.bind(button)
	if !button.draw.is_connected(drawn):
		button.draw.connect(drawn)

func _on_mouse_entered(button: Button) -> void:
	if _material == null or button.disabled or button.flat or !_hover_styles.has(button.get_theme_stylebox(&"hover")):
		return
	var flood: _Flood = _flood_of(button)
	if flood == null:
		flood = _Flood.new(button, _material)
		# Internal, so scripts walking the button's children do not meet it.
		button.add_child(flood, false, Node.INTERNAL_MODE_FRONT)
		button.set_meta(&"ink_flood", flood)
	flood.fill_to(1.0, FILL_SECONDS)

func _on_mouse_exited(button: Button) -> void:
	var flood: _Flood = _flood_of(button)
	if flood != null:
		flood.fill_to(0.0, DRAIN_SECONDS)

func _on_button_drawn(button: Button) -> void:
	if button.is_hovered():
		_on_mouse_entered(button)
	else:
		_on_mouse_exited(button)

## Takes a button's ink away at once: for a button on its way out, which
## leaves in a way of its own (the top bar's dissolve).
func clear(button: Button) -> void:
	var flood: _Flood = _flood_of(button)
	if flood != null:
		flood.empty()

func _on_popup_opened(popup: PopupMenu) -> void:
	if !_open_popups.has(popup):
		_open_popups.append(popup)
	_tint_radio_marks(popup)
	set_process(true)

## Ink on the radio items, paper on the hovered one, as their labels are.
func _tint_radio_marks(popup: PopupMenu) -> void:
	var hovered: int = popup.get_focused_item()
	for index in range(popup.item_count):
		if !popup.is_item_radio_checkable(index):
			continue
		var colour: StringName = &"font_color"
		if popup.is_item_disabled(index):
			colour = &"font_disabled_color"
		elif index == hovered:
			colour = &"font_hover_color"
		var tint: Color = popup.get_theme_color(colour)
		if popup.get_item_icon_modulate(index) != tint:
			popup.set_item_icon_modulate(index, tint)

func _flood_of(button: Button) -> _Flood:
	if !button.has_meta(&"ink_flood"):
		return null
	var flood = button.get_meta(&"ink_flood")
	return flood as _Flood if is_instance_valid(flood) else null

## The ink behind one button, and its label's turn from ink to paper.
class _Flood:
	extends Control

	## The label's colours that follow the ink, and the colour each turns to.
	const LABEL_COLOURS: Dictionary = {
		&"font_color": &"font_pressed_color",
		&"font_hover_color": &"font_pressed_color",
		&"font_focus_color": &"font_pressed_color",
		&"icon_normal_color": &"icon_pressed_color",
		&"icon_hover_color": &"icon_pressed_color",
		&"icon_focus_color": &"icon_pressed_color",
	}
	## The label turns as the ink closes over the middle, where it sits.
	const LABEL_TURN_START: float = 0.7
	const LABEL_TURN_END: float = 0.95

	var button: Button
	var progress: float = 0.0
	## Where the ink is heading: 1 hovered, 0 not.
	var target: float = 0.0
	var _tween: Tween
	var _label_from: Dictionary = {}
	var _label_to: Dictionary = {}
	## Overrides the button had of its own, put back once the ink has drained.
	var _own_overrides: Dictionary = {}

	func _init(owner_button: Button, flood_material: ShaderMaterial) -> void:
		button = owner_button
		name = "InkFlood"
		material = flood_material
		show_behind_parent = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)

	func _ready() -> void:
		set_instance_shader_parameter(&"flood_seed", float(get_instance_id() % 997))
		set_instance_shader_parameter(&"flood_progress", 0.0)
		resized.connect(_sync_shape)
		# A button that turns disabled under the pointer shows no ink.
		button.draw.connect(queue_redraw)
		_sync_shape()

	func _draw() -> void:
		if button.disabled:
			return
		draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)

	func empty() -> void:
		if _tween != null and _tween.is_valid():
			_tween.kill()
		target = 0.0
		# Already dry, the label has its own colours back.
		if progress > 0.0:
			_set_progress(0.0)

	func fill_to(new_target: float, seconds: float) -> void:
		var running: bool = _tween != null and _tween.is_valid()
		# Asked again on every redraw while the hover lasts: carry on.
		if is_equal_approx(new_target, target) and (running or is_equal_approx(progress, target)):
			return
		target = new_target
		if running:
			_tween.kill()
		if is_equal_approx(progress, target):
			return
		# Slow at both ends: the first blotches creep in, the last islands of
		# paper close slowly.
		_tween = create_tween()
		_tween.set_trans(Tween.TRANS_SINE)
		_tween.set_ease(Tween.EASE_IN_OUT)
		_tween.tween_method(_set_progress, progress, target, seconds * absf(target - progress))

	func _set_progress(value: float) -> void:
		if progress <= 0.0 and value > 0.0:
			_take_label_colours()
		progress = value
		set_instance_shader_parameter(&"flood_progress", value)
		_tint_label()

	## Size and corners from the button's hover style, which the ink fills.
	func _sync_shape() -> void:
		set_instance_shader_parameter(&"flood_size", size)
		var style: StyleBox = button.get_theme_stylebox(&"hover")
		var flat: StyleBoxFlat = (style as InkStampStyleBox).shape if style is InkStampStyleBox else style as StyleBoxFlat
		if flat != null:
			set_instance_shader_parameter(&"flood_radii", Vector4(flat.corner_radius_top_left, flat.corner_radius_top_right, flat.corner_radius_bottom_right, flat.corner_radius_bottom_left))

	func _take_label_colours() -> void:
		_label_from.clear()
		_label_to.clear()
		_own_overrides.clear()
		for colour in LABEL_COLOURS:
			if button.has_theme_color_override(colour):
				_own_overrides[colour] = button.get_theme_color(colour)
			_label_from[colour] = button.get_theme_color(colour)
			_label_to[colour] = button.get_theme_color(LABEL_COLOURS[colour])

	func _tint_label() -> void:
		button.begin_bulk_theme_override()
		if progress <= 0.0:
			for colour in LABEL_COLOURS:
				if _own_overrides.has(colour):
					button.add_theme_color_override(colour, _own_overrides[colour])
				else:
					button.remove_theme_color_override(colour)
		else:
			var turn: float = smoothstep(LABEL_TURN_START, LABEL_TURN_END, progress)
			for colour in _label_from:
				button.add_theme_color_override(colour, (_label_from[colour] as Color).lerp(_label_to[colour], turn))
		button.end_bulk_theme_override()
