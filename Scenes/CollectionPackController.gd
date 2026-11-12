extends RefCounted
class_name CollectionPackController

## The collection room's packs: the unopened ones lying in the room, the shop that
## sells more (CollectionPackShopController), and the overlay that opens them
## (PackOpeningOverlay, Docs/PackOpening/PACK_OPENING.md). This one ties them to
## the room: the packs in it, the click on them, and the counters.

const BOOSTER_PACK_TEXTURE = preload("res://Assets/booster.png")
const MAX_VISIBLE_PACK_ICONS: int = 4
const PACK_INVENTORY_PREVIEW_SCALE: float = 1.1

var collection: Control
var points_label: Label
var pack_notice_panel: Control
var pack_inventory: Control
var pack_preview_nodes: Array[Control] = []
var pack_inventory_arrival_tweens: Dictionary = {}
var pack_opened_callback: Callable
var pack_click_area: Control
var shop: CollectionPackShopController
var overlay: PackOpeningOverlay

func bind(nodes: Dictionary, opened_callback: Callable = Callable()) -> void:
	collection = nodes.get("collection", null) as Control
	points_label = nodes.get("points_label", null) as Label
	pack_notice_panel = nodes.get("pack_notice_panel", null) as Control
	pack_inventory = nodes.get("pack_inventory", null) as Control
	pack_opened_callback = opened_callback

	PackDefinitionLibrary.ensure_loaded()
	PlayerProgressStore.ensure_loaded()
	PlayerCollectionStore.ensure_loaded()

	shop = CollectionPackShopController.new()
	shop.bind(collection, nodes.get("buy_packs_panel", null) as PanelContainer, Callable(self, "_on_packs_bought"))
	overlay = PackOpeningOverlay.new(collection, nodes.get("book_node", null) as Control)
	overlay.packs_claimed.connect(Callable(self, "_on_packs_claimed"))
	overlay.rewards_put_away.connect(Callable(self, "_on_rewards_put_away"))
	overlay.closed.connect(Callable(self, "_sync_pack_click_area"))

	_connect_once(pack_inventory, "resized", Callable(self, "refresh_pack_inventory_ui"))
	_collect_pack_preview_nodes()
	refresh_progress_ui()
	refresh_pack_inventory_ui()

func _connect_once(node: Object, signal_name: StringName, callable: Callable) -> void:
	if node == null:
		return
	if !node.has_signal(signal_name):
		return
	if !node.is_connected(signal_name, callable):
		node.connect(signal_name, callable)

func show_buy_packs() -> void:
	shop.show()

func is_buy_packs_modal_open() -> bool:
	return shop != null and shop.is_open()

func open_pack() -> void:
	if !overlay.can_open():
		return
	_hide_pack_click_area()
	overlay.open()

func handle_back_pressed() -> bool:
	return overlay != null and overlay.handle_back_pressed()

func _on_packs_bought(previous_queue: Array[String]) -> void:
	refresh_progress_ui()
	refresh_pack_inventory_ui(true, previous_queue)

func _on_packs_claimed() -> void:
	refresh_progress_ui()
	refresh_pack_inventory_ui()

func _on_rewards_put_away(rewards: Array[StampPrint], has_new_stamps: bool) -> void:
	if pack_opened_callback.is_valid():
		pack_opened_callback.call(rewards, has_new_stamps)

func _collect_pack_preview_nodes() -> void:
	pack_preview_nodes.clear()
	if pack_inventory == null:
		return
	PackDefinitionLibrary.ensure_loaded()
	if pack_notice_panel != null:
		pack_notice_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var pack_root := pack_inventory.get_parent() as Control
	if pack_root != null:
		pack_root.mouse_filter = Control.MOUSE_FILTER_PASS
	pack_inventory.mouse_filter = Control.MOUSE_FILTER_PASS

	for i in range(MAX_VISIBLE_PACK_ICONS):
		var preview := pack_inventory.get_node_or_null("PackPreview%d" % (i + 1)) as Control
		if preview == null:
			continue
		pack_preview_nodes.append(preview)
		preview.mouse_filter = Control.MOUSE_FILTER_STOP
		preview.mouse_default_cursor_shape = Control.CURSOR_ARROW
		preview.tooltip_text = tr("Open pack")
		preview.set_meta("inventory_base_position", preview.position)
		preview.set_meta("inventory_base_rotation", preview.rotation)
		preview.pivot_offset = preview.size * 0.5
		preview.scale = Vector2.ONE * PACK_INVENTORY_PREVIEW_SCALE
		if preview is TextureRect:
			var texture_preview := preview as TextureRect
			texture_preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			texture_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_connect_once(preview, "gui_input", Callable(self, "_on_pack_preview_gui_input").bind(preview))
	_sync_pack_click_area()

func _on_pack_preview_gui_input(event: InputEvent, preview: Control) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			open_pack()
			preview.accept_event()

func refresh_progress_ui() -> void:
	if points_label == null:
		return
	# Through the bar, so the number gets its grouping (12 400) like everywhere else.
	GlobalTopBar.refresh_points()

func refresh_pack_inventory_ui(animate_new: bool = false, previous_preview_ids: Array[String] = []) -> void:
	if pack_inventory == null:
		return

	if pack_preview_nodes.is_empty():
		_collect_pack_preview_nodes()

	var pack_count: int = PlayerProgressStore.get_unopened_pack_count()
	var preview_pack_ids: Array[String] = PlayerProgressStore.get_unopened_pack_queue(MAX_VISIBLE_PACK_ICONS)
	if pack_notice_panel != null:
		pack_notice_panel.visible = pack_count > 0
	pack_inventory.visible = pack_count > 0
	for i in range(pack_preview_nodes.size()):
		var preview := pack_preview_nodes[i]
		preview.visible = i < preview_pack_ids.size()
		if preview is TextureRect and i < preview_pack_ids.size():
			var texture_preview := preview as TextureRect
			texture_preview.texture = PackDefinitionLibrary.get_pack_front_texture(preview_pack_ids[i], BOOSTER_PACK_TEXTURE)
		if preview.visible:
			var previous_pack_id: String = previous_preview_ids[i] if i < previous_preview_ids.size() else ""
			var should_animate: bool = animate_new and (i >= previous_preview_ids.size() or previous_pack_id != preview_pack_ids[i])
			if should_animate:
				_play_pack_inventory_arrival(preview, i)
			else:
				_reset_pack_inventory_preview_transform(preview)
	_sync_pack_click_area()

func _reset_pack_inventory_preview_transform(preview: Control) -> void:
	if preview == null or !is_instance_valid(preview):
		return
	var tween: Tween = pack_inventory_arrival_tweens.get(preview, null) as Tween
	if tween != null and tween.is_valid():
		tween.kill()
	pack_inventory_arrival_tweens.erase(preview)
	var base_position: Vector2 = preview.get_meta("inventory_base_position", preview.position) as Vector2
	var base_rotation: float = float(preview.get_meta("inventory_base_rotation", preview.rotation))
	preview.position = base_position
	preview.rotation = base_rotation
	preview.scale = Vector2.ONE * PACK_INVENTORY_PREVIEW_SCALE
	preview.modulate.a = 1.0

func _play_pack_inventory_arrival(preview: Control, index: int) -> void:
	if preview == null or !is_instance_valid(preview):
		return

	_reset_pack_inventory_preview_transform(preview)
	var base_position: Vector2 = preview.get_meta("inventory_base_position", preview.position) as Vector2
	var base_rotation: float = float(preview.get_meta("inventory_base_rotation", preview.rotation))
	var base_scale := Vector2.ONE * PACK_INVENTORY_PREVIEW_SCALE
	var start_rotation: float = base_rotation + deg_to_rad(randf_range(-4.0, 4.0))
	preview.modulate.a = 0.0
	preview.position = base_position + Vector2(0.0, -24.0)
	preview.rotation = start_rotation
	preview.scale = base_scale * 1.18

	var tween := preview.create_tween()
	pack_inventory_arrival_tweens[preview] = tween
	tween.tween_interval(float(index) * 0.045)
	tween.tween_property(preview, "position", base_position, 0.34).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(preview, "scale", base_scale, 0.34).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(preview, "rotation", base_rotation, 0.34).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(preview, "modulate:a", 1.0, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(preview, "rotation", base_rotation + deg_to_rad(3.2), 0.055).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(preview, "rotation", base_rotation - deg_to_rad(2.2), 0.07).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(preview, "rotation", base_rotation + deg_to_rad(1.1), 0.06).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(preview, "rotation", base_rotation, 0.075).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(Callable(self, "_finish_pack_inventory_arrival").bind(preview))

func _finish_pack_inventory_arrival(preview: Control) -> void:
	if preview == null or !is_instance_valid(preview):
		return
	pack_inventory_arrival_tweens.erase(preview)
	var base_position: Vector2 = preview.get_meta("inventory_base_position", preview.position) as Vector2
	var base_rotation: float = float(preview.get_meta("inventory_base_rotation", preview.rotation))
	preview.position = base_position
	preview.rotation = base_rotation
	preview.scale = Vector2.ONE * PACK_INVENTORY_PREVIEW_SCALE
	preview.modulate.a = 1.0
	_sync_pack_click_area()

func _ensure_pack_click_area() -> void:
	if pack_click_area != null and is_instance_valid(pack_click_area):
		return
	if collection == null or !is_instance_valid(collection):
		return

	pack_click_area = Control.new()
	pack_click_area.name = "PackPreviewClickArea"
	collection.add_child(pack_click_area)
	pack_click_area.z_as_relative = false
	pack_click_area.z_index = 32
	pack_click_area.mouse_filter = Control.MOUSE_FILTER_STOP
	pack_click_area.mouse_default_cursor_shape = Control.CURSOR_ARROW
	pack_click_area.visible = false
	pack_click_area.clip_contents = false
	pack_click_area.gui_input.connect(Callable(self, "_on_pack_click_area_gui_input"))

func _sync_pack_click_area() -> void:
	if overlay != null and overlay.is_active():
		_hide_pack_click_area()
		return
	if PlayerProgressStore.get_unopened_pack_count() <= 0:
		_hide_pack_click_area()
		return
	if pack_preview_nodes.is_empty():
		_hide_pack_click_area()
		return

	_ensure_pack_click_area()
	if pack_click_area == null or !is_instance_valid(pack_click_area):
		return

	var canvas_rect := Rect2()
	var has_rect: bool = false
	for preview in pack_preview_nodes:
		if preview == null or !is_instance_valid(preview) or !preview.visible or !preview.is_visible_in_tree():
			continue
		var preview_rect: Rect2 = _get_control_canvas_rect(preview)
		if preview_rect.size.x <= 0.0 or preview_rect.size.y <= 0.0:
			continue
		if has_rect:
			canvas_rect = canvas_rect.merge(preview_rect)
		else:
			canvas_rect = preview_rect
			has_rect = true

	if !has_rect:
		_hide_pack_click_area()
		return

	var local_rect: Rect2 = _canvas_rect_to_collection_rect(canvas_rect).grow(14.0)
	pack_click_area.position = local_rect.position
	pack_click_area.size = local_rect.size
	pack_click_area.visible = true
	pack_click_area.move_to_front()

func _hide_pack_click_area() -> void:
	if pack_click_area != null and is_instance_valid(pack_click_area):
		pack_click_area.visible = false

func _on_pack_click_area_gui_input(event: InputEvent) -> void:
	if !(event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or !mouse_event.pressed:
		return
	pack_click_area.accept_event()
	open_pack()

func _get_control_canvas_rect(control: Control) -> Rect2:
	var transform := control.get_global_transform_with_canvas()
	var corners: Array[Vector2] = [
		Vector2.ZERO,
		Vector2(control.size.x, 0.0),
		control.size,
		Vector2(0.0, control.size.y),
	]
	var min_point: Vector2 = transform * corners[0]
	var max_point: Vector2 = min_point
	for i in range(1, corners.size()):
		var point: Vector2 = transform * corners[i]
		min_point = min_point.min(point)
		max_point = max_point.max(point)
	return Rect2(min_point, max_point - min_point)

func _canvas_rect_to_collection_rect(canvas_rect: Rect2) -> Rect2:
	if collection == null or !is_instance_valid(collection):
		return canvas_rect

	var transform := collection.get_global_transform_with_canvas().affine_inverse()
	var corners: Array[Vector2] = [
		canvas_rect.position,
		canvas_rect.position + Vector2(canvas_rect.size.x, 0.0),
		canvas_rect.position + canvas_rect.size,
		canvas_rect.position + Vector2(0.0, canvas_rect.size.y),
	]
	var min_point: Vector2 = transform * corners[0]
	var max_point: Vector2 = min_point
	for i in range(1, corners.size()):
		var point: Vector2 = transform * corners[i]
		min_point = min_point.min(point)
		max_point = max_point.max(point)
	return Rect2(min_point, max_point - min_point)
