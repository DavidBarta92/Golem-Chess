extends RefCounted
class_name CollectionStampBrowserController

const STAMP_VISUAL = preload("res://Scenes/StampVisual.tscn")

var collection
var stamp_grid: GridContainer
var search_field: LineEdit
var owned_only_check: CheckBox
var previous_button: Button
var next_button: Button
var page_label: Label
var pager_back_icon: Texture2D
var pager_next_icon: Texture2D
var codex_title_font: FontFile

var clear_hover_callback: Callable = Callable()
var update_deck_editor_callback: Callable = Callable()
var stamp_mouse_entered_callback: Callable = Callable()
var stamp_mouse_exited_callback: Callable = Callable()
var stamp_drag_started_callback: Callable = Callable()
var stamp_drag_released_callback: Callable = Callable()
var deck_stamp_display_name_provider: Callable = Callable()

var all_stamp_prints: Array = []
var filtered_stamp_prints: Array = []
var active_set_filter: String = ""
var current_page: int = 0
var current_stamps_per_page: int = 9
var current_stamp_columns: int = 3
var current_stamp_slot_size: Vector2 = Vector2(128, 142)
var current_stamp_grid_vertical_gap: int = 2
var pager_button_press_tweens: Dictionary = {}

var stamp_visual_size: Vector2 = Vector2(168.7, 229)
var stamp_slot_scale_multiplier: float = 0.88
var browser_stamp_vertical_offset: float = -12.0
var deck_slot_remove_button_size: Vector2 = Vector2(20, 20)
var pager_button_pressed_scale: float = 0.92
var pager_button_press_in_seconds: float = 0.055
var pager_button_press_out_seconds: float = 0.075

func bind(config: Dictionary) -> void:
	collection = config.get("collection", collection)
	stamp_grid = config.get("stamp_grid", stamp_grid) as GridContainer
	search_field = config.get("search_field", search_field) as LineEdit
	owned_only_check = config.get("owned_only_check", owned_only_check) as CheckBox
	previous_button = config.get("previous_button", previous_button) as Button
	next_button = config.get("next_button", next_button) as Button
	page_label = config.get("page_label", page_label) as Label
	pager_back_icon = config.get("pager_back_icon", pager_back_icon) as Texture2D
	pager_next_icon = config.get("pager_next_icon", pager_next_icon) as Texture2D
	codex_title_font = config.get("codex_title_font", codex_title_font) as FontFile
	stamp_visual_size = config.get("stamp_visual_size", stamp_visual_size)
	stamp_slot_scale_multiplier = float(config.get("stamp_slot_scale_multiplier", stamp_slot_scale_multiplier))
	browser_stamp_vertical_offset = float(config.get("browser_stamp_vertical_offset", browser_stamp_vertical_offset))
	deck_slot_remove_button_size = config.get("deck_slot_remove_button_size", deck_slot_remove_button_size)
	pager_button_pressed_scale = float(config.get("pager_button_pressed_scale", pager_button_pressed_scale))
	pager_button_press_in_seconds = float(config.get("pager_button_press_in_seconds", pager_button_press_in_seconds))
	pager_button_press_out_seconds = float(config.get("pager_button_press_out_seconds", pager_button_press_out_seconds))
	clear_hover_callback = config.get("clear_hover_callback", clear_hover_callback)
	update_deck_editor_callback = config.get("update_deck_editor_callback", update_deck_editor_callback)
	stamp_mouse_entered_callback = config.get("stamp_mouse_entered_callback", stamp_mouse_entered_callback)
	stamp_mouse_exited_callback = config.get("stamp_mouse_exited_callback", stamp_mouse_exited_callback)
	stamp_drag_started_callback = config.get("stamp_drag_started_callback", stamp_drag_started_callback)
	stamp_drag_released_callback = config.get("stamp_drag_released_callback", stamp_drag_released_callback)
	deck_stamp_display_name_provider = config.get("deck_stamp_display_name_provider", deck_stamp_display_name_provider)

func load_stamps() -> void:
	if StampLibrary.all_stamps.is_empty():
		StampLibrary.load_all_stamps()
	StampPrintLibrary.ensure_loaded()
	PlayerCollectionStore.ensure_loaded()
	PlayerDeckStore.ensure_loaded()
	all_stamp_prints = StampPrintLibrary.get_all_prints()
	refresh_stamp_filter(false)

func show_page(page_index: int) -> void:
	current_page = clampi(page_index, 0, max(0, get_page_count() - 1))
	if clear_hover_callback.is_valid():
		clear_hover_callback.call()
	if stamp_grid == null:
		return
	for child in stamp_grid.get_children():
		stamp_grid.remove_child(child)
		child.queue_free()

	var start_index: int = current_page * current_stamps_per_page
	var end_index: int = min(start_index + current_stamps_per_page, filtered_stamp_prints.size())
	if filtered_stamp_prints.is_empty():
		var empty_label := Label.new()
		stamp_grid.add_child(empty_label)
		empty_label.text = tr("No stamps found")
		empty_label.custom_minimum_size = Vector2(0, 120)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))

	for index in range(start_index, end_index):
		var stamp_print: StampPrint = filtered_stamp_prints[index] as StampPrint
		if stamp_print == null:
			continue
		var stamp: Stamp = StampPrintLibrary.get_stamp_for_print(stamp_print)
		if stamp == null:
			continue

		var stamp_visual: StampVisual = STAMP_VISUAL.instantiate() as StampVisual
		var owned_count: int = PlayerCollectionStore.get_owned_count_for_print_id(stamp_print.print_id)
		var stamp_slot: Control = create_browser_stamp_slot(stamp_visual, owned_count)
		stamp_grid.add_child(stamp_slot)
		stamp_visual.draggable = collection != null and bool(collection.is_creating_deck)
		stamp_visual.set_hover_raise_enabled(false)
		stamp_visual.set_stamp_print(stamp_print)
		stamp_visual.set_face_down(false)
		stamp_visual.set_collection_owned(owned_count > 0)
		if stamp_mouse_entered_callback.is_valid():
			stamp_visual.mouse_entered.connect(stamp_mouse_entered_callback.bind(stamp, stamp_print))
		if stamp_mouse_exited_callback.is_valid():
			stamp_visual.mouse_exited.connect(stamp_mouse_exited_callback.bind(stamp.stamp_name))
		if stamp_drag_started_callback.is_valid():
			stamp_visual.drag_started.connect(stamp_drag_started_callback.bind(stamp_print.print_id))
		if stamp_drag_released_callback.is_valid():
			stamp_visual.drag_released.connect(stamp_drag_released_callback.bind(stamp_print.print_id))

	if page_label != null:
		page_label.text = "%d / %d" % [current_page + 1, max(1, get_page_count())]
	if previous_button != null:
		previous_button.disabled = current_page <= 0
	if next_button != null:
		next_button.disabled = current_page >= get_page_count() - 1
	if update_deck_editor_callback.is_valid():
		update_deck_editor_callback.call()

func get_page_count() -> int:
	return int(ceil(float(filtered_stamp_prints.size()) / float(current_stamps_per_page)))

func refresh_stamp_filter(reset_page: bool = true) -> void:
	filtered_stamp_prints.clear()
	var query: String = search_field.text.strip_edges().to_lower() if search_field != null else ""
	var owned_only: bool = owned_only_check.button_pressed if owned_only_check != null else false

	for stamp_print_value in all_stamp_prints:
		var stamp_print: StampPrint = stamp_print_value as StampPrint
		if stamp_print == null:
			continue
		var stamp: Stamp = StampPrintLibrary.get_stamp_for_print(stamp_print)
		if stamp == null:
			continue

		# Skip disabled stamps
		if not stamp.enabled:
			continue

		# Filter by "My collection" owned-only
		var owned_count: int = PlayerCollectionStore.get_owned_count_for_print_id(stamp_print.print_id)
		if owned_only && owned_count <= 0:
			continue

		# Filter by active set filter if any
		if active_set_filter != "" and stamp.Set != active_set_filter:
			continue

		var display_name: String = get_deck_stamp_display_name(stamp, stamp_print).to_lower()
		if !query.is_empty() && display_name.find(query) == -1 && stamp.stamp_name.to_lower().find(query) == -1:
			continue

		filtered_stamp_prints.append(stamp_print)

	if stamp_grid != null:
		show_page(0 if reset_page else current_page)

func get_deck_stamp_display_name(stamp: Stamp, stamp_print: StampPrint) -> String:
	if deck_stamp_display_name_provider.is_valid():
		return str(deck_stamp_display_name_provider.call(stamp, stamp_print))
	if stamp_print == null or stamp_print.variant_id == PlayerCollectionStore.DEFAULT_VARIANT_ID:
		return stamp.stamp_name
	return "%s - %s" % [stamp.stamp_name, stamp_print.get_display_name()]

func set_active_set_filter(set_name: String) -> void:
	# set_name empty string clears filter
	active_set_filter = str(set_name)
	refresh_stamp_filter(true)

func create_browser_stamp_slot(stamp_visual: StampVisual, owned_count: int) -> Control:
	var stamp_slot := Control.new()
	stamp_slot.custom_minimum_size = current_stamp_slot_size
	stamp_slot.mouse_filter = Control.MOUSE_FILTER_PASS
	stamp_slot.clip_contents = false
	stamp_slot.add_child(stamp_visual)
	stamp_slot.add_child(create_print_count_badge(owned_count))
	stamp_slot.resized.connect(on_browser_stamp_slot_resized.bind(stamp_slot, stamp_visual))
	configure_browser_stamp_layout(stamp_slot, stamp_visual)
	return stamp_slot

func configure_browser_stamp_layout(stamp_slot: Control, stamp_visual: StampVisual) -> void:
	stamp_slot.custom_minimum_size = current_stamp_slot_size
	stamp_visual.custom_minimum_size = stamp_visual_size
	stamp_visual.size = stamp_visual_size
	var scale_factor: float = get_stamp_scale_for_slot_size(current_stamp_slot_size)
	stamp_visual.set_rest_scale(Vector2.ONE * scale_factor)
	var available_size: Vector2 = stamp_slot.size
	if available_size.x <= 0.0 or available_size.y <= 0.0:
		available_size = current_stamp_slot_size
	stamp_visual.position = (available_size - stamp_visual_size * scale_factor) * 0.5 + Vector2(0.0, browser_stamp_vertical_offset)
	update_print_count_badge_layout(stamp_slot, stamp_visual)

func create_print_count_badge(owned_count: int) -> Control:
	var badge := Control.new()
	badge.name = "CountBadge"
	badge.visible = owned_count > 1
	badge.custom_minimum_size = deck_slot_remove_button_size
	badge.size = deck_slot_remove_button_size
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.z_index = 20

	var background := Panel.new()
	badge.add_child(background)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_theme_stylebox_override("panel", create_count_badge_style())

	var number := Control.new()
	badge.add_child(number)
	number.set_anchors_preset(Control.PRESET_FULL_RECT)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number.draw.connect(func() -> void:
		draw_print_count_badge_number(number, str(owned_count), 11 if owned_count < 10 else 9)
	)
	return badge

func create_count_badge_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.02, 0.96)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	return style

func draw_print_count_badge_number(canvas: Control, text: String, font_size: int) -> void:
	if canvas == null or codex_title_font == null:
		return

	var canvas_size: Vector2 = canvas.size
	if canvas_size.x <= 0.0 or canvas_size.y <= 0.0:
		canvas_size = deck_slot_remove_button_size

	var text_size: Vector2 = codex_title_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var ascent: float = codex_title_font.get_ascent(font_size)
	var descent: float = codex_title_font.get_descent(font_size)
	var text_height: float = ascent + descent
	var draw_position := Vector2(
		(canvas_size.x - text_size.x) * 0.5,
		(canvas_size.y - text_height) * 0.5 + ascent
	)
	canvas.draw_string(codex_title_font, draw_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color.WHITE)

func update_print_count_badge_layout(stamp_slot: Control, stamp_visual: StampVisual) -> void:
	var badge: Control = stamp_slot.get_node_or_null("CountBadge") as Control
	if badge == null:
		return
	badge.size = badge.custom_minimum_size
	var scaled_stamp_size: Vector2 = stamp_visual_size * stamp_visual.rest_scale
	var stamp_top_left: Vector2 = get_stamp_visual_draw_top_left(stamp_visual)
	badge.position = stamp_top_left + Vector2(scaled_stamp_size.x - badge.size.x - 2.0, 2.0)

func on_browser_stamp_slot_resized(stamp_slot: Control, stamp_visual: StampVisual) -> void:
	if stamp_visual != null:
		configure_browser_stamp_layout(stamp_slot, stamp_visual)

func get_stamp_scale_for_slot_size(slot_size: Vector2) -> float:
	if slot_size.x <= 0.0 or slot_size.y <= 0.0:
		return 1.0
	return minf(slot_size.x / stamp_visual_size.x, slot_size.y / stamp_visual_size.y) * stamp_slot_scale_multiplier

func get_browser_stamp_visual(node: Node) -> StampVisual:
	if node is StampVisual:
		return node as StampVisual

	for child in node.get_children():
		if child is StampVisual:
			return child as StampVisual

	return null

func get_hovered_stamp_visual(node: Node, mouse_position: Vector2) -> StampVisual:
	if node is StampVisual:
		var stamp_visual := node as StampVisual
		if stamp_visual.stamp != null and !stamp_visual.face_down and stamp_visual.is_visible_in_tree() and get_stamp_visual_screen_rect(stamp_visual).has_point(mouse_position):
			return stamp_visual
		return null

	for child in node.get_children():
		var hovered_stamp_visual: StampVisual = get_hovered_stamp_visual(child, mouse_position)
		if hovered_stamp_visual != null:
			return hovered_stamp_visual

	return null

func get_stamp_visual_screen_rect(stamp_visual: StampVisual) -> Rect2:
	var transform: Transform2D = stamp_visual.get_global_transform_with_canvas()
	var corner_a: Vector2 = transform * Vector2.ZERO
	var corner_b: Vector2 = transform * Vector2(stamp_visual.size.x, 0.0)
	var corner_c: Vector2 = transform * stamp_visual.size
	var corner_d: Vector2 = transform * Vector2(0.0, stamp_visual.size.y)
	var min_position := Vector2(
		minf(minf(corner_a.x, corner_b.x), minf(corner_c.x, corner_d.x)),
		minf(minf(corner_a.y, corner_b.y), minf(corner_c.y, corner_d.y))
	)
	var max_position := Vector2(
		maxf(maxf(corner_a.x, corner_b.x), maxf(corner_c.x, corner_d.x)),
		maxf(maxf(corner_a.y, corner_b.y), maxf(corner_c.y, corner_d.y))
	)
	return Rect2(min_position, max_position - min_position)

func get_stamp_visual_draw_top_left(stamp_visual: StampVisual) -> Vector2:
	var pivot: Vector2 = stamp_visual.pivot_offset
	if pivot == Vector2.ZERO:
		pivot = stamp_visual.size * 0.5
	return stamp_visual.position + pivot * (Vector2.ONE - stamp_visual.rest_scale)

func apply_layout(columns: int, stamps_per_page: int, slot_size: Vector2, horizontal_gap: int, vertical_gap: int) -> bool:
	var layout_changed: bool = columns != current_stamp_columns or stamps_per_page != current_stamps_per_page
	current_stamp_columns = columns
	current_stamps_per_page = stamps_per_page
	current_stamp_slot_size = slot_size
	current_stamp_grid_vertical_gap = vertical_gap
	if stamp_grid != null:
		stamp_grid.columns = current_stamp_columns
		stamp_grid.add_theme_constant_override("h_separation", horizontal_gap)
		stamp_grid.add_theme_constant_override("v_separation", vertical_gap)
		update_stamp_grid_reserved_size()
	return layout_changed

func update_stamp_grid_reserved_size() -> void:
	if stamp_grid == null:
		return
	var row_count: int = maxi(1, int(ceil(float(current_stamps_per_page) / float(maxi(1, current_stamp_columns)))))
	var reserved_height: float = current_stamp_slot_size.y * row_count + current_stamp_grid_vertical_gap * maxi(0, row_count - 1)
	stamp_grid.custom_minimum_size = Vector2(0.0, reserved_height)
	stamp_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

func update_existing_stamp_sizes() -> void:
	if stamp_grid == null:
		return
	for child in stamp_grid.get_children():
		var stamp_visual: StampVisual = get_browser_stamp_visual(child)
		if stamp_visual != null && child is Control:
			configure_browser_stamp_layout(child as Control, stamp_visual)

func configure_pager_buttons() -> void:
	connect_pager_button_animation(previous_button)
	connect_pager_button_animation(next_button)

func apply_generated_pager_button_visual(button: Button, icon: Texture2D) -> void:
	if button == null:
		return
	button.text = ""
	button.icon = icon
	button.expand_icon = true
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.pivot_offset = button.custom_minimum_size * 0.5

	var empty_style := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)
	button.add_theme_stylebox_override("disabled", empty_style)

	connect_pager_button_animation(button)

func connect_pager_button_animation(button: Button) -> void:
	if button == null:
		return
	button.pivot_offset = button.custom_minimum_size * 0.5
	var callable := Callable(self, "on_pager_button_down").bind(button)
	if !button.button_down.is_connected(callable):
		button.button_down.connect(callable)

func on_pager_button_down(button: Button) -> void:
	animate_pager_button_press(button)

func animate_pager_button_press(button: Button) -> void:
	if collection == null or button == null:
		return
	if pager_button_press_tweens.has(button):
		var previous_tween: Tween = pager_button_press_tweens[button] as Tween
		if previous_tween != null and previous_tween.is_valid():
			previous_tween.kill()

	var button_size: Vector2 = button.size
	if button_size == Vector2.ZERO:
		button_size = button.custom_minimum_size
	button.pivot_offset = button_size * 0.5

	var tween: Tween = collection.create_tween()
	pager_button_press_tweens[button] = tween
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(button, "scale", Vector2.ONE * pager_button_pressed_scale, pager_button_press_in_seconds)
	tween.tween_property(button, "scale", Vector2.ONE, pager_button_press_out_seconds)

func show_previous_page() -> void:
	show_page(current_page - 1)

func show_next_page() -> void:
	show_page(current_page + 1)

func get_current_page() -> int:
	return current_page

func get_current_stamp_slot_size() -> Vector2:
	return current_stamp_slot_size
