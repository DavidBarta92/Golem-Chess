extends RefCounted
class_name CollectionPackController

const BOOSTER_PACK_TEXTURE = preload("res://Assets/booster.png")
const PACK_3D_VIEW = preload("res://Scenes/Pack3DView.tscn")
const PACK_TEAR_PIECE_SHADER = preload("res://Shaders/pack_tear_piece.gdshader")
const STAMP_VISUAL = preload("res://Scenes/StampVisual.tscn")
const PACK_REWARD_STAMP_COUNT: int = 4
const MAX_VISIBLE_PACK_ICONS: int = 4
const PACK_OVERLAY_Z_INDEX: int = 2200
const PACK_FLY_IN_SECONDS: float = 0.42
const PACK_FLY_STAGGER_SECONDS: float = 0.055
const PACK_FOCUS_SECONDS: float = 0.42
const PACK_VISUAL_SIZE_SCALE: float = 1.15
const PACK_FOCUSED_SCALE: float = 1.61
const PACK_TEAR_SECONDS: float = 1.05
const PACK_TEAR_CUT_SECONDS: float = 0.28
const PACK_TEAR_TO_FALL_DELAY: float = 0.42
const PACK_TEAR_CUT_Y: float = 0.085
const PACK_TEAR_WAVE_STRENGTH: float = 0.012
const PACK_TEAR_EDGE_SOFTNESS: float = 0.006
const PACK_FALL_SECONDS: float = 1.12
const PACK_REWARD_SPREAD_DELAY: float = 0.56
const PACK_REWARD_SPREAD_SECONDS: float = 0.44
const PACK_REWARD_FLIP_SECONDS: float = 0.18
const PACK_REWARD_MAX_SCALE: float = 0.72
const PACK_REWARD_MIN_SCALE: float = 0.38
const PACK_REWARD_SIDE_MARGIN: float = 36.0
const STAMP_VISUAL_SIZE: Vector2 = Vector2(168.7, 229.0)
const OVERLAY_STATE_SELECTION: String = "selection"
const OVERLAY_STATE_FOCUSED: String = "focused"
const OVERLAY_STATE_OPENING: String = "opening"
const OVERLAY_STATE_REWARDS: String = "rewards"

var collection: Control
var buy_packs_button: Button
var points_label: Label
var buy_packs_panel: PanelContainer
var pack_select_option: OptionButton
var pack_count_spin_box: SpinBox
var buy_packs_info_label: Label
var buy_packs_confirm_button: Button
var buy_packs_cancel_button: Button
var pack_notice_panel: Control
var pack_inventory: Control
var pack_inventory_label: Label
var pack_preview_nodes: Array[Control] = []
var pack_result_dialog: AcceptDialog
var pack_result_label: Label
var pack_opened_callback: Callable
var pack_click_area: Control
var pack_overlay: Control
var pack_overlay_backbuffer: BackBufferCopy
var pack_blur_rect: ColorRect
var pack_layer: Control
var reward_layer: Control
var opening_pack_nodes: Array[Control] = []
var revealed_stamp_nodes: Array[StampVisual] = []
var reward_stamp_flipped: Array[bool] = []
var reward_flip_hitboxes: Array[Control] = []
var focused_pack_node: Control
var overlay_state: String = ""
var overlay_animating: bool = false
var reward_flip_in_progress: bool = false
var selected_purchase_pack_id: String = ""

func bind(nodes: Dictionary, opened_callback: Callable = Callable()) -> void:
	collection = nodes.get("collection", null) as Control
	buy_packs_button = nodes.get("buy_packs_button", null) as Button
	points_label = nodes.get("points_label", null) as Label
	buy_packs_panel = nodes.get("buy_packs_panel", null) as PanelContainer
	pack_count_spin_box = nodes.get("pack_count_spin_box", null) as SpinBox
	buy_packs_info_label = nodes.get("buy_packs_info_label", null) as Label
	buy_packs_confirm_button = nodes.get("buy_packs_confirm_button", null) as Button
	buy_packs_cancel_button = nodes.get("buy_packs_cancel_button", null) as Button
	pack_notice_panel = nodes.get("pack_notice_panel", null) as Control
	pack_inventory = nodes.get("pack_inventory", null) as Control
	pack_inventory_label = nodes.get("pack_inventory_label", null) as Label
	pack_result_dialog = nodes.get("pack_result_dialog", null) as AcceptDialog
	pack_result_label = nodes.get("pack_result_label", null) as Label
	pack_opened_callback = opened_callback
	if collection == null and pack_notice_panel != null:
		collection = pack_notice_panel.get_tree().current_scene as Control

	if !Engine.is_editor_hint():
		PackDefinitionLibrary.ensure_loaded()
		PlayerProgressStore.ensure_loaded()
		PlayerCollectionStore.ensure_loaded()

	_ensure_buy_pack_selector()
	_connect_once(buy_packs_button, "pressed", Callable(self, "show_buy_packs"))
	_connect_once(pack_inventory, "resized", Callable(self, "refresh_pack_inventory_ui"))
	_connect_once(pack_count_spin_box, "value_changed", Callable(self, "on_pack_count_spin_value_changed"))
	_connect_once(buy_packs_cancel_button, "pressed", Callable(self, "cancel_buy_packs"))
	_connect_once(buy_packs_confirm_button, "pressed", Callable(self, "confirm_buy_packs"))
	_collect_pack_preview_nodes()

	if buy_packs_panel != null:
		buy_packs_panel.visible = false
	refresh_progress_ui()
	refresh_pack_inventory_ui()

func _connect_once(node: Object, signal_name: StringName, callable: Callable) -> void:
	if node == null:
		return
	if !node.has_signal(signal_name):
		return
	if !node.is_connected(signal_name, callable):
		node.connect(signal_name, callable)

func _ensure_buy_pack_selector() -> void:
	if buy_packs_panel == null:
		return
	if pack_select_option != null and is_instance_valid(pack_select_option):
		return

	var root := buy_packs_panel.get_node_or_null("BuyPacksRoot") as VBoxContainer
	if root == null:
		for child in buy_packs_panel.get_children():
			if child is VBoxContainer:
				root = child as VBoxContainer
				break
	if root == null:
		return

	pack_select_option = root.get_node_or_null("PackSelectOption") as OptionButton
	if pack_select_option == null:
		pack_select_option = OptionButton.new()
		pack_select_option.name = "PackSelectOption"
		pack_select_option.custom_minimum_size = Vector2(0.0, 32.0)
		root.add_child(pack_select_option)
		root.move_child(pack_select_option, mini(1, root.get_child_count() - 1))

	if !pack_select_option.item_selected.is_connected(Callable(self, "_on_purchase_pack_selected")):
		pack_select_option.item_selected.connect(_on_purchase_pack_selected)
	if buy_packs_panel.offset_bottom < 250.0:
		buy_packs_panel.offset_bottom = 250.0

func _on_purchase_pack_selected(_index: int) -> void:
	var pack_definition: PackDefinition = _get_selected_purchase_pack()
	selected_purchase_pack_id = pack_definition.get_resolved_id() if pack_definition != null else ""
	update_buy_packs_info()

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
		preview.tooltip_text = "Open pack"
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
	if Engine.is_editor_hint():
		points_label.text = "0"
		return
	points_label.text = str(PlayerProgressStore.get_points())

func refresh_pack_inventory_ui() -> void:
	if Engine.is_editor_hint() or pack_inventory == null:
		return

	if pack_preview_nodes.is_empty():
		_collect_pack_preview_nodes()

	var pack_count: int = PlayerProgressStore.get_unopened_pack_count()
	var preview_pack_ids: Array[String] = _get_unopened_pack_ids_for_display(MAX_VISIBLE_PACK_ICONS)
	if pack_inventory_label != null:
		pack_inventory_label.text = "%d unopened" % pack_count if pack_count > 0 else "No unopened packs"
	if pack_notice_panel != null:
		pack_notice_panel.visible = pack_count > 0
	pack_inventory.visible = pack_count > 0
	for i in range(pack_preview_nodes.size()):
		var preview := pack_preview_nodes[i]
		preview.visible = i < preview_pack_ids.size()
		if preview is TextureRect and i < preview_pack_ids.size():
			var texture_preview := preview as TextureRect
			texture_preview.texture = PackDefinitionLibrary.get_pack_front_texture(preview_pack_ids[i], BOOSTER_PACK_TEXTURE)
	_sync_pack_click_area()

func populate_editor_pack_preview() -> void:
	if pack_inventory == null:
		return
	if pack_inventory_label != null:
		pack_inventory_label.text = "4 unopened"
	if pack_notice_panel != null:
		pack_notice_panel.visible = true
	_collect_pack_preview_nodes()
	for preview in pack_preview_nodes:
		preview.visible = true

func show_buy_packs() -> void:
	if buy_packs_panel == null or pack_count_spin_box == null:
		return

	_ensure_buy_pack_selector()
	_populate_pack_selector()
	var selected_pack: PackDefinition = _get_selected_purchase_pack()
	var pack_price: int = selected_pack.price if selected_pack != null else PlayerProgressStore.PACK_COST
	var max_pack_count: int = PlayerProgressStore.get_max_affordable_pack_count(pack_price)
	pack_count_spin_box.min_value = 0 if max_pack_count <= 0 else 1
	pack_count_spin_box.max_value = max_pack_count
	pack_count_spin_box.value = 0 if max_pack_count <= 0 else 1
	pack_count_spin_box.editable = max_pack_count > 0 and selected_pack != null
	update_buy_packs_info()
	if buy_packs_confirm_button != null:
		buy_packs_confirm_button.disabled = max_pack_count <= 0 or selected_pack == null
	buy_packs_panel.visible = true
	buy_packs_panel.move_to_front()

func on_pack_count_spin_value_changed(_value: float) -> void:
	update_buy_packs_info()

func _populate_pack_selector() -> void:
	_ensure_buy_pack_selector()
	if pack_select_option == null or !is_instance_valid(pack_select_option):
		return

	PackDefinitionLibrary.ensure_loaded()
	var available_packs: Array[PackDefinition] = PackDefinitionLibrary.get_available_packs()
	pack_select_option.clear()
	for pack_definition in available_packs:
		var item_index: int = pack_select_option.item_count
		pack_select_option.add_item("%s - %d points" % [pack_definition.get_display_name(), pack_definition.price])
		pack_select_option.set_item_metadata(item_index, pack_definition.get_resolved_id())

	if available_packs.is_empty():
		selected_purchase_pack_id = ""
		pack_select_option.disabled = true
		return

	pack_select_option.disabled = false
	var selected_index: int = 0
	for i in range(pack_select_option.item_count):
		if str(pack_select_option.get_item_metadata(i)) == selected_purchase_pack_id:
			selected_index = i
			break
	pack_select_option.select(selected_index)
	selected_purchase_pack_id = str(pack_select_option.get_item_metadata(selected_index))

func _get_selected_purchase_pack() -> PackDefinition:
	if pack_select_option != null and is_instance_valid(pack_select_option) and pack_select_option.item_count > 0:
		var selected_index: int = pack_select_option.selected
		if selected_index >= 0 and selected_index < pack_select_option.item_count:
			selected_purchase_pack_id = str(pack_select_option.get_item_metadata(selected_index))
	if selected_purchase_pack_id.is_empty():
		var first_pack: PackDefinition = PackDefinitionLibrary.get_first_available_pack()
		selected_purchase_pack_id = first_pack.get_resolved_id() if first_pack != null else ""
	return PackDefinitionLibrary.get_pack(selected_purchase_pack_id)

func update_buy_packs_info() -> void:
	if buy_packs_info_label == null or pack_count_spin_box == null:
		return

	var selected_pack: PackDefinition = _get_selected_purchase_pack()
	if selected_pack == null:
		buy_packs_info_label.text = "No available packs."
		if buy_packs_confirm_button != null:
			buy_packs_confirm_button.disabled = true
		return

	var max_pack_count: int = PlayerProgressStore.get_max_affordable_pack_count(selected_pack.price)
	if max_pack_count <= 0:
		buy_packs_info_label.text = "%s: %d points\nNot enough points." % [
			selected_pack.get_display_name(),
			selected_pack.price,
		]
		if buy_packs_confirm_button != null:
			buy_packs_confirm_button.disabled = true
		return

	var pack_count: int = int(pack_count_spin_box.value)
	var total_cost: int = pack_count * selected_pack.price
	buy_packs_info_label.text = "%s | %d points each | Max: %d\nCost: %d points" % [
		selected_pack.get_display_name(),
		selected_pack.price,
		max_pack_count,
		total_cost,
	]
	if buy_packs_confirm_button != null:
		buy_packs_confirm_button.disabled = pack_count <= 0

func confirm_buy_packs() -> void:
	var pack_count: int = int(pack_count_spin_box.value) if pack_count_spin_box != null else 0
	var selected_pack: PackDefinition = _get_selected_purchase_pack()
	if selected_pack == null:
		return
	if !PlayerProgressStore.purchase_packs(pack_count, selected_pack.get_resolved_id(), selected_pack.price):
		return

	if buy_packs_panel != null:
		buy_packs_panel.visible = false
	refresh_progress_ui()
	refresh_pack_inventory_ui()

func cancel_buy_packs() -> void:
	if buy_packs_panel != null:
		buy_packs_panel.visible = false

func _get_unopened_pack_ids_for_display(max_count: int = -1) -> Array[String]:
	var pack_counts: Dictionary = PlayerProgressStore.get_unopened_pack_counts()
	var pack_ids: Array[String] = []
	var used_pack_ids: Dictionary = {}

	for pack_definition in PackDefinitionLibrary.get_all_packs():
		var pack_id: String = pack_definition.get_resolved_id()
		used_pack_ids[pack_id] = true
		var count: int = int(pack_counts.get(pack_id, 0))
		for i in range(count):
			pack_ids.append(pack_id)
			if max_count >= 0 and pack_ids.size() >= max_count:
				return pack_ids

	var unknown_pack_ids: Array[String] = []
	for pack_id_value in pack_counts.keys():
		var pack_id: String = str(pack_id_value)
		if !used_pack_ids.has(pack_id):
			unknown_pack_ids.append(pack_id)
	unknown_pack_ids.sort()
	for pack_id in unknown_pack_ids:
		var count: int = int(pack_counts.get(pack_id, 0))
		for i in range(count):
			pack_ids.append(pack_id)
			if max_count >= 0 and pack_ids.size() >= max_count:
				return pack_ids
	return pack_ids

func open_pack() -> void:
	show_pack_opening_view()

func show_pack_opening_view() -> void:
	if PlayerProgressStore.get_unopened_pack_count() <= 0:
		return
	if is_pack_overlay_active():
		return
	_hide_pack_click_area()
	if collection == null or !is_instance_valid(collection):
		_claim_pack_rewards(true)
		return

	_show_pack_selection_overlay(true)

func is_pack_overlay_active() -> bool:
	return pack_overlay != null and is_instance_valid(pack_overlay)

func handle_back_pressed() -> bool:
	if !is_pack_overlay_active():
		return false
	if overlay_animating:
		return true

	if overlay_state == OVERLAY_STATE_REWARDS:
		if PlayerProgressStore.get_unopened_pack_count() > 0:
			_show_pack_selection_overlay(true)
		else:
			_close_pack_overlay(true)
		return true

	if overlay_state == OVERLAY_STATE_FOCUSED:
		_show_pack_selection_overlay(false)
		return true

	_close_pack_overlay(true)
	return true

func _claim_pack_rewards(show_result: bool, pack_id: String = "") -> Array[StampPrint]:
	var empty_rewards: Array[StampPrint] = []
	var normalized_pack_id: String = pack_id.strip_edges()
	if normalized_pack_id.is_empty():
		normalized_pack_id = PlayerProgressStore.get_first_unopened_pack_id()
	if PlayerProgressStore.get_unopened_pack_count(normalized_pack_id) <= 0:
		return empty_rewards

	var rewards: Array[StampPrint] = _roll_pack_rewards(normalized_pack_id)
	if rewards.is_empty():
		return empty_rewards
	if !PlayerProgressStore.open_pack(normalized_pack_id):
		return empty_rewards

	for stamp_print: StampPrint in rewards:
		PlayerCollectionStore.add_local_print_copy(stamp_print.print_id)

	if show_result:
		_show_pack_result(rewards)
	refresh_progress_ui()
	refresh_pack_inventory_ui()
	if pack_opened_callback.is_valid():
		pack_opened_callback.call(rewards)
	return rewards

func _ensure_pack_overlay() -> void:
	if is_pack_overlay_active():
		pack_overlay.visible = true
		return
	if collection == null or !is_instance_valid(collection):
		return

	pack_overlay = Control.new()
	pack_overlay.name = "PackOpeningOverlay"
	collection.add_child(pack_overlay)
	pack_overlay.z_as_relative = false
	pack_overlay.z_index = PACK_OVERLAY_Z_INDEX
	pack_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pack_overlay.clip_contents = false
	_sync_pack_overlay_rect()

	pack_overlay_backbuffer = BackBufferCopy.new()
	pack_overlay_backbuffer.name = "PackOpeningBackBuffer"
	pack_overlay_backbuffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	pack_overlay.add_child(pack_overlay_backbuffer)

	pack_blur_rect = ColorRect.new()
	pack_blur_rect.name = "PackOpeningDim"
	pack_overlay.add_child(pack_blur_rect)
	pack_blur_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	pack_blur_rect.offset_left = 0.0
	pack_blur_rect.offset_top = 0.0
	pack_blur_rect.offset_right = 0.0
	pack_blur_rect.offset_bottom = 0.0
	pack_blur_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pack_blur_rect.color = Color(0.0, 0.0, 0.0, 0.82)

	reward_layer = Control.new()
	reward_layer.name = "PackRewardLayer"
	pack_overlay.add_child(reward_layer)
	reward_layer.z_index = 10
	reward_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	reward_layer.offset_left = 0.0
	reward_layer.offset_top = 0.0
	reward_layer.offset_right = 0.0
	reward_layer.offset_bottom = 0.0
	reward_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	reward_layer.clip_contents = false

	pack_layer = Control.new()
	pack_layer.name = "PackLayer"
	pack_overlay.add_child(pack_layer)
	pack_layer.z_index = 20
	pack_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	pack_layer.offset_left = 0.0
	pack_layer.offset_top = 0.0
	pack_layer.offset_right = 0.0
	pack_layer.offset_bottom = 0.0
	pack_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	pack_layer.clip_contents = false
	_connect_once(pack_overlay, "gui_input", Callable(self, "_on_pack_overlay_gui_input"))

	var viewport := collection.get_viewport()
	if viewport != null:
		_connect_once(viewport, "size_changed", Callable(self, "_on_pack_overlay_viewport_resized"))

func _sync_pack_overlay_rect() -> void:
	if pack_overlay == null or !is_instance_valid(pack_overlay):
		return
	pack_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pack_overlay.offset_left = 0.0
	pack_overlay.offset_top = 0.0
	pack_overlay.offset_right = 0.0
	pack_overlay.offset_bottom = 0.0

func _show_pack_selection_overlay(animate_in: bool) -> void:
	if PlayerProgressStore.get_unopened_pack_count() <= 0:
		_close_pack_overlay(true)
		return

	_ensure_pack_overlay()
	if !is_pack_overlay_active():
		return

	_hide_pack_click_area()
	_reset_pack_overlay_content()
	overlay_state = OVERLAY_STATE_SELECTION
	overlay_animating = animate_in
	focused_pack_node = null
	if reward_layer != null and is_instance_valid(reward_layer):
		reward_layer.z_index = 10
		reward_layer.visible = false
		reward_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if pack_layer != null and is_instance_valid(pack_layer):
		pack_layer.visible = true
		pack_layer.mouse_filter = Control.MOUSE_FILTER_PASS
		pack_layer.z_index = 20
		pack_layer.move_to_front()
	pack_overlay.visible = true
	pack_overlay.modulate.a = 0.0 if animate_in else 1.0
	_sync_pack_overlay_rect()

	if animate_in:
		var fade_tween := pack_overlay.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		fade_tween.tween_property(pack_overlay, "modulate:a", 1.0, 0.16)

	var visible_pack_ids: Array[String] = _get_unopened_pack_ids_for_display(MAX_VISIBLE_PACK_ICONS)
	var target_positions: Array[Vector2] = _get_selection_pack_positions(visible_pack_ids.size())
	for i in range(visible_pack_ids.size()):
		var pack_id: String = visible_pack_ids[i]
		var pack_node := _create_opening_pack_node(i, pack_id)
		opening_pack_nodes.append(pack_node)
		pack_layer.add_child(pack_node)
		var target_position: Vector2 = target_positions[i]
		pack_node.set_meta("selection_position", target_position)
		if animate_in:
			pack_node.position = _get_edge_start_position(i, target_position, pack_node.size)
			pack_node.scale = Vector2.ONE * 0.86
			var tween := pack_overlay.create_tween()
			tween.tween_interval(float(i) * PACK_FLY_STAGGER_SECONDS)
			tween.tween_property(pack_node, "position", target_position, PACK_FLY_IN_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween.parallel().tween_property(pack_node, "scale", Vector2.ONE, PACK_FLY_IN_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		else:
			pack_node.position = target_position
			pack_node.scale = Vector2.ONE

	if animate_in:
		var gate_tween := pack_overlay.create_tween()
		gate_tween.tween_interval(PACK_FLY_IN_SECONDS + maxf(0.0, float(visible_pack_ids.size() - 1) * PACK_FLY_STAGGER_SECONDS))
		gate_tween.tween_callback(Callable(self, "_finish_pack_selection_fly_in"))
	else:
		_start_selection_pack_ambient_motion()

func _create_opening_pack_node(index: int, pack_id: String) -> Control:
	var pack_definition: PackDefinition = PackDefinitionLibrary.get_pack(pack_id)
	var pack_texture: Texture2D = PackDefinitionLibrary.get_pack_front_texture(pack_id, BOOSTER_PACK_TEXTURE)
	var pack_size: Vector2 = _get_pack_visual_size(pack_texture)
	var pack_node := PACK_3D_VIEW.instantiate() as Pack3DView
	pack_node.name = "OpeningPack%d" % (index + 1)
	pack_node.set_meta("pack_id", pack_id)
	pack_node.set_pack_definition(pack_definition, BOOSTER_PACK_TEXTURE)
	_apply_pack_control_size(pack_node, pack_size)
	pack_node.mouse_filter = Control.MOUSE_FILTER_STOP
	pack_node.mouse_default_cursor_shape = Control.CURSOR_ARROW
	pack_node.rotation = deg_to_rad(randf_range(-8.0, 8.0))
	pack_node.gui_input.connect(Callable(self, "_on_opening_pack_gui_input").bind(pack_node))
	return pack_node

func _apply_pack_control_size(pack_node: Control, pack_size: Vector2) -> void:
	if pack_node == null or !is_instance_valid(pack_node):
		return
	var current_position: Vector2 = pack_node.position
	pack_node.anchor_left = 0.0
	pack_node.anchor_top = 0.0
	pack_node.anchor_right = 0.0
	pack_node.anchor_bottom = 0.0
	pack_node.offset_left = 0.0
	pack_node.offset_top = 0.0
	pack_node.offset_right = pack_size.x
	pack_node.offset_bottom = pack_size.y
	pack_node.custom_minimum_size = pack_size
	pack_node.size = pack_size
	pack_node.position = current_position
	pack_node.pivot_offset = pack_size * 0.5

func _start_selection_pack_ambient_motion() -> void:
	if overlay_state != OVERLAY_STATE_SELECTION or overlay_animating:
		return
	var should_render_single_pack: bool = opening_pack_nodes.size() <= 1
	for i in range(opening_pack_nodes.size()):
		var pack_node: Control = opening_pack_nodes[i]
		if pack_node == null or !is_instance_valid(pack_node):
			continue
		if pack_node is Pack3DView:
			var pack_view := pack_node as Pack3DView
			pack_view.set_hover_tracking_enabled(true)
			pack_view.set_selected(should_render_single_pack)
			if !should_render_single_pack:
				pack_view.request_static_render()

func _start_pack_ambient_motion(pack_node: Control, _index: int) -> void:
	if pack_node == null or !is_instance_valid(pack_node):
		return
	if pack_node is Pack3DView:
		(pack_node as Pack3DView).set_selected(opening_pack_nodes.size() <= 1)

func _stop_pack_ambient_motion(pack_node: Control, reset_shader_tilt: bool = true) -> void:
	if pack_node == null or !is_instance_valid(pack_node):
		return
	if pack_node is Pack3DView:
		var pack_view := pack_node as Pack3DView
		if reset_shader_tilt:
			pack_view.set_tear_cut_progress(0.0)
		pack_view.set_selected(false)
		pack_view.request_static_render()

func _on_opening_pack_gui_input(event: InputEvent, pack_node: Control) -> void:
	if !(event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or !mouse_event.pressed:
		return
	pack_node.accept_event()
	if overlay_animating:
		if overlay_state != OVERLAY_STATE_SELECTION:
			return
		overlay_animating = false

	if overlay_state == OVERLAY_STATE_SELECTION:
		_focus_overlay_pack(pack_node)
	elif overlay_state == OVERLAY_STATE_FOCUSED and pack_node == focused_pack_node:
		_open_focused_overlay_pack()

func _focus_overlay_pack(pack_node: Control) -> void:
	if pack_node == null or !is_instance_valid(pack_node):
		return

	overlay_state = OVERLAY_STATE_FOCUSED
	overlay_animating = true
	focused_pack_node = pack_node
	var focused_position: Vector2 = _get_focused_pack_position(pack_node.size)

	for node in opening_pack_nodes:
		if node == null or !is_instance_valid(node):
			continue
		_stop_pack_ambient_motion(node, false)
		var tween := pack_overlay.create_tween()
		if node == pack_node:
			node.z_index = 40
			node.mouse_filter = Control.MOUSE_FILTER_STOP
			if node is Pack3DView:
				(node as Pack3DView).set_selected(true)
			tween.tween_property(node, "position", focused_position, PACK_FOCUS_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tween.parallel().tween_property(node, "scale", Vector2.ONE * PACK_FOCUSED_SCALE, PACK_FOCUS_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween.parallel().tween_property(node, "rotation", 0.0, PACK_FOCUS_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		else:
			node.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tween.tween_property(node, "modulate:a", 0.0, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
			tween.parallel().tween_property(node, "scale", Vector2.ONE * 0.72, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	var gate_tween := pack_overlay.create_tween()
	gate_tween.tween_interval(PACK_FOCUS_SECONDS)
	gate_tween.tween_callback(Callable(self, "_finish_overlay_animation"))

func _open_focused_overlay_pack() -> void:
	if focused_pack_node == null or !is_instance_valid(focused_pack_node):
		return

	var pack_id: String = str(focused_pack_node.get_meta("pack_id", ""))
	var rewards: Array[StampPrint] = _claim_pack_rewards(false, pack_id)
	if rewards.is_empty():
		return

	overlay_state = OVERLAY_STATE_OPENING
	overlay_animating = true
	focused_pack_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stop_pack_ambient_motion(focused_pack_node, false)
	if focused_pack_node is Pack3DView:
		(focused_pack_node as Pack3DView).set_selected(true)
	for node in opening_pack_nodes:
		if node != focused_pack_node and node != null and is_instance_valid(node):
			_stop_pack_ambient_motion(node, false)
			node.queue_free()
	opening_pack_nodes.clear()
	opening_pack_nodes.append(focused_pack_node)

	_create_reward_stamp_stack(rewards)
	var fall_start_delay: float = _play_pack_tear_animation(focused_pack_node)

	var viewport_size: Vector2 = _get_viewport_size()
	var exit_position := Vector2(
		focused_pack_node.position.x,
		viewport_size.y + focused_pack_node.size.y * focused_pack_node.scale.y + 96.0
	)
	var fall_rotation: float = deg_to_rad(randf_range(-10.0, 10.0))
	var fall_tween := pack_overlay.create_tween()
	fall_tween.tween_interval(fall_start_delay)
	fall_tween.tween_property(focused_pack_node, "position", exit_position, PACK_FALL_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	fall_tween.parallel().tween_property(focused_pack_node, "rotation", fall_rotation, PACK_FALL_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	fall_tween.tween_callback(Callable(focused_pack_node, "queue_free"))

	var spread_tween := pack_overlay.create_tween()
	spread_tween.tween_interval(fall_start_delay + PACK_REWARD_SPREAD_DELAY)
	spread_tween.tween_callback(Callable(self, "_arrange_reward_stamps").bind(true))

	var finish_tween := pack_overlay.create_tween()
	finish_tween.tween_interval(fall_start_delay + PACK_FALL_SECONDS + 0.08)
	finish_tween.tween_callback(Callable(self, "_finish_pack_open_animation"))

func _play_pack_tear_animation(pack_node: Control) -> float:
	if pack_node == null or !is_instance_valid(pack_node):
		return 0.0
	if pack_overlay == null or !is_instance_valid(pack_overlay):
		return 0.0
	if pack_layer == null or !is_instance_valid(pack_layer):
		return 0.0

	var tear_seed: float = randf()
	if pack_node is Pack3DView:
		var pack_view := pack_node as Pack3DView
		pack_view.set_tear_parameters(PACK_TEAR_CUT_Y, PACK_TEAR_WAVE_STRENGTH, tear_seed, PACK_TEAR_EDGE_SOFTNESS)
		pack_view.set_tear_cut_progress(0.0)
		var cut_tween := pack_overlay.create_tween()
		cut_tween.tween_method(Callable(pack_view, "set_tear_cut_progress"), 0.0, 1.0, PACK_TEAR_CUT_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	var tear_texture: Texture2D = _get_pack_texture_for_node(pack_node)
	if tear_texture == null:
		return PACK_TEAR_TO_FALL_DELAY

	var tear_piece := TextureRect.new()
	tear_piece.name = "PackTopTearPiece"
	pack_layer.add_child(tear_piece)
	tear_piece.z_index = pack_node.z_index + 8
	tear_piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tear_piece.texture = tear_texture
	tear_piece.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tear_piece.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tear_piece.stretch_mode = TextureRect.STRETCH_SCALE
	tear_piece.position = pack_node.position
	tear_piece.size = pack_node.size
	tear_piece.scale = pack_node.scale
	tear_piece.rotation = pack_node.rotation
	tear_piece.pivot_offset = pack_node.pivot_offset

	var tear_material := ShaderMaterial.new()
	tear_material.shader = PACK_TEAR_PIECE_SHADER
	tear_material.set_shader_parameter("tear_cut_y", PACK_TEAR_CUT_Y)
	tear_material.set_shader_parameter("tear_wave_strength", PACK_TEAR_WAVE_STRENGTH)
	tear_material.set_shader_parameter("tear_seed", tear_seed)
	tear_material.set_shader_parameter("tear_edge_softness", PACK_TEAR_EDGE_SOFTNESS)
	tear_piece.material = tear_material

	var viewport_size: Vector2 = _get_viewport_size()
	var side_direction: float = -1.0 if randf() < 0.5 else 1.0
	var target_position: Vector2 = pack_node.position + Vector2(
		side_direction * (viewport_size.x * 0.16 + randf_range(18.0, 54.0)),
		-viewport_size.y * 0.38 - pack_node.size.y * pack_node.scale.y * 0.18
	)
	var target_rotation: float = pack_node.rotation + deg_to_rad(side_direction * randf_range(46.0, 68.0))
	var target_scale: Vector2 = pack_node.scale * Vector2(0.92, 0.86)

	var fly_tween := pack_overlay.create_tween()
	fly_tween.tween_property(tear_piece, "position", target_position, PACK_TEAR_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	fly_tween.parallel().tween_property(tear_piece, "rotation", target_rotation, PACK_TEAR_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	fly_tween.parallel().tween_property(tear_piece, "scale", target_scale, PACK_TEAR_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	fly_tween.tween_callback(Callable(tear_piece, "queue_free"))

	var fade_tween := pack_overlay.create_tween()
	fade_tween.tween_interval(PACK_TEAR_SECONDS * 0.58)
	fade_tween.tween_property(tear_piece, "modulate:a", 0.0, PACK_TEAR_SECONDS * 0.42).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	return PACK_TEAR_TO_FALL_DELAY

func _create_reward_stamp_stack(rewards: Array[StampPrint]) -> void:
	if reward_layer == null or !is_instance_valid(reward_layer):
		return

	_clear_reward_stamps()
	reward_layer.visible = true
	reward_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	var viewport_size: Vector2 = _get_viewport_size()
	var scale_factor: float = _get_reward_stamp_scale(viewport_size, rewards.size())
	var stack_center: Vector2 = viewport_size * 0.5
	if focused_pack_node != null and is_instance_valid(focused_pack_node):
		stack_center = focused_pack_node.position + focused_pack_node.size * 0.5
	var stack_position: Vector2 = _get_stamp_position_for_center(stack_center)
	for i in range(rewards.size()):
		var stamp_visual := STAMP_VISUAL.instantiate() as StampVisual
		if stamp_visual == null:
			continue
		reward_layer.add_child(stamp_visual)
		stamp_visual.size = STAMP_VISUAL_SIZE
		stamp_visual.custom_minimum_size = STAMP_VISUAL_SIZE
		stamp_visual.pivot_offset = STAMP_VISUAL_SIZE * 0.5
		stamp_visual.set_stamp_print(rewards[i])
		stamp_visual.set_collection_owned(true)
		stamp_visual.set_face_down(true)
		stamp_visual.set_hover_raise_enabled(false)
		stamp_visual.set_rest_scale(Vector2.ONE * scale_factor)
		stamp_visual.draggable = false
		stamp_visual.disabled = true
		stamp_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stamp_visual.position = stack_position
		stamp_visual.home_position = stack_position
		stamp_visual.z_index = i
		revealed_stamp_nodes.append(stamp_visual)
		reward_stamp_flipped.append(false)

func _arrange_reward_stamps(animated: bool) -> void:
	if revealed_stamp_nodes.is_empty():
		return

	var viewport_size: Vector2 = _get_viewport_size()
	var scale_factor: float = _get_reward_stamp_scale(viewport_size, revealed_stamp_nodes.size())
	var target_scale := Vector2.ONE * scale_factor
	var positions: Array[Vector2] = _get_reward_stamp_positions(revealed_stamp_nodes.size(), scale_factor)
	for i in range(revealed_stamp_nodes.size()):
		var stamp_visual: StampVisual = revealed_stamp_nodes[i]
		if stamp_visual == null or !is_instance_valid(stamp_visual):
			continue
		stamp_visual.set_ambient_motion_enabled(false)
		stamp_visual.home_position = positions[i]
		stamp_visual.rest_scale = target_scale
		stamp_visual.z_index = i
		if animated:
			var tween := stamp_visual.create_tween()
			tween.tween_property(stamp_visual, "position", positions[i], PACK_REWARD_SPREAD_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tween.parallel().tween_property(stamp_visual, "scale", target_scale, PACK_REWARD_SPREAD_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween.parallel().tween_property(stamp_visual, "rotation", deg_to_rad(randf_range(-2.0, 2.0)), PACK_REWARD_SPREAD_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		else:
			stamp_visual.position = positions[i]
			stamp_visual.scale = target_scale
			stamp_visual.rotation = 0.0

	_sync_reward_flip_hitboxes()
	if animated:
		var float_tween := pack_overlay.create_tween()
		float_tween.tween_interval(PACK_REWARD_SPREAD_SECONDS)
		float_tween.tween_callback(Callable(self, "_enable_reward_stamp_float"))
	else:
		_enable_reward_stamp_float()

func _enable_reward_stamp_float() -> void:
	for stamp_visual in revealed_stamp_nodes:
		if stamp_visual == null or !is_instance_valid(stamp_visual):
			continue
		stamp_visual.home_position = stamp_visual.position
		stamp_visual.set_ambient_motion_enabled(true)
	_sync_reward_flip_hitboxes()

func _sync_reward_flip_hitboxes() -> void:
	if reward_layer == null or !is_instance_valid(reward_layer):
		return

	while reward_flip_hitboxes.size() < revealed_stamp_nodes.size():
		var hitbox := Control.new()
		hitbox.name = "RewardStampHitbox%d" % (reward_flip_hitboxes.size() + 1)
		hitbox.z_index = 500 + reward_flip_hitboxes.size()
		hitbox.mouse_filter = Control.MOUSE_FILTER_STOP
		hitbox.mouse_default_cursor_shape = Control.CURSOR_ARROW
		hitbox.clip_contents = false
		reward_layer.add_child(hitbox)
		hitbox.gui_input.connect(Callable(self, "_on_reward_stamp_hitbox_gui_input").bind(reward_flip_hitboxes.size()))
		reward_flip_hitboxes.append(hitbox)

	for i in range(reward_flip_hitboxes.size()):
		var hitbox: Control = reward_flip_hitboxes[i]
		if hitbox == null or !is_instance_valid(hitbox):
			continue
		var stamp_visual: StampVisual = revealed_stamp_nodes[i] if i < revealed_stamp_nodes.size() else null
		if stamp_visual == null or !is_instance_valid(stamp_visual):
			hitbox.visible = false
			hitbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			continue
		var hitbox_rect: Rect2 = _get_reward_stamp_hitbox_rect(stamp_visual)
		hitbox.position = hitbox_rect.position
		hitbox.size = hitbox_rect.size
		hitbox.visible = overlay_state == OVERLAY_STATE_REWARDS
		hitbox.mouse_filter = Control.MOUSE_FILTER_STOP if hitbox.visible else Control.MOUSE_FILTER_IGNORE

func _on_reward_stamp_hitbox_gui_input(event: InputEvent, stamp_index: int) -> void:
	if !(event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or !mouse_event.pressed:
		return
	if stamp_index < 0 or stamp_index >= revealed_stamp_nodes.size():
		return
	var hitbox: Control = reward_flip_hitboxes[stamp_index] if stamp_index < reward_flip_hitboxes.size() else null
	if hitbox != null and is_instance_valid(hitbox):
		hitbox.accept_event()
	if overlay_animating or reward_flip_in_progress:
		return
	if stamp_index < reward_stamp_flipped.size() and reward_stamp_flipped[stamp_index]:
		return
	_flip_reward_stamp(stamp_index)

func _flip_reward_stamp(stamp_index: int) -> void:
	if stamp_index < 0 or stamp_index >= revealed_stamp_nodes.size():
		return
	var stamp_visual: StampVisual = revealed_stamp_nodes[stamp_index]
	if stamp_visual == null or !is_instance_valid(stamp_visual):
		return

	reward_flip_in_progress = true
	var hitbox: Control = reward_flip_hitboxes[stamp_index] if stamp_index < reward_flip_hitboxes.size() else null
	if hitbox != null and is_instance_valid(hitbox):
		hitbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	stamp_visual.set_ambient_motion_enabled(false)
	stamp_visual.set_hover_raise_enabled(false)
	stamp_visual.draggable = false
	stamp_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp_visual.disabled = true
	stamp_visual.z_index = 120 + stamp_index
	var target_scale: Vector2 = stamp_visual.rest_scale
	var squash_scale := Vector2(0.0, target_scale.y * 1.02)
	var tween := stamp_visual.create_tween()
	tween.tween_property(stamp_visual, "scale", squash_scale, PACK_REWARD_FLIP_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(Callable(self, "_turn_reward_stamp_face_up").bind(stamp_visual))
	tween.tween_property(stamp_visual, "scale", target_scale, PACK_REWARD_FLIP_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(stamp_visual, "rotation", deg_to_rad(randf_range(-1.6, 1.6)), PACK_REWARD_FLIP_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(Callable(self, "_finish_reward_stamp_flip").bind(stamp_index))

func _turn_reward_stamp_face_up(stamp_visual: StampVisual) -> void:
	if stamp_visual == null or !is_instance_valid(stamp_visual):
		return
	stamp_visual.set_face_down(false)
	stamp_visual.disabled = true
	stamp_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp_visual.scale = Vector2(0.0, stamp_visual.scale.y)

func _finish_reward_stamp_flip(stamp_index: int) -> void:
	if stamp_index >= 0 and stamp_index < reward_stamp_flipped.size():
		reward_stamp_flipped[stamp_index] = true
	var stamp_visual: StampVisual = revealed_stamp_nodes[stamp_index] if stamp_index >= 0 and stamp_index < revealed_stamp_nodes.size() else null
	if stamp_visual != null and is_instance_valid(stamp_visual):
		stamp_visual.disabled = true
		stamp_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stamp_visual.home_position = stamp_visual.position
		stamp_visual.set_ambient_motion_enabled(true)
	reward_flip_in_progress = false
	_sync_reward_flip_hitboxes()

func _get_reward_stamp_hitbox_rect(stamp_visual: StampVisual) -> Rect2:
	var scale_factor: float = maxf(stamp_visual.rest_scale.x, stamp_visual.rest_scale.y)
	if scale_factor <= 0.0:
		scale_factor = maxf(absf(stamp_visual.scale.x), absf(stamp_visual.scale.y))
	var visual_size: Vector2 = STAMP_VISUAL_SIZE * maxf(scale_factor, PACK_REWARD_MIN_SCALE)
	var visual_center: Vector2 = stamp_visual.home_position + STAMP_VISUAL_SIZE * 0.5
	return Rect2(visual_center - visual_size * 0.5, visual_size).grow(8.0)

func _on_pack_overlay_gui_input(event: InputEvent) -> void:
	if !(event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or !mouse_event.pressed:
		return
	if overlay_state != OVERLAY_STATE_REWARDS or overlay_animating or reward_flip_in_progress:
		return
	if !_are_all_reward_stamps_flipped():
		return
	pack_overlay.accept_event()
	handle_back_pressed()

func _are_all_reward_stamps_flipped() -> bool:
	if revealed_stamp_nodes.is_empty() or reward_stamp_flipped.size() < revealed_stamp_nodes.size():
		return false
	for i in range(revealed_stamp_nodes.size()):
		if i >= reward_stamp_flipped.size() or !reward_stamp_flipped[i]:
			return false
	return true

func _finish_pack_open_animation() -> void:
	if !is_pack_overlay_active() or overlay_state != OVERLAY_STATE_OPENING:
		return
	opening_pack_nodes.clear()
	focused_pack_node = null
	if pack_layer != null and is_instance_valid(pack_layer):
		pack_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pack_layer.visible = false
	if reward_layer != null and is_instance_valid(reward_layer):
		reward_layer.visible = true
		reward_layer.mouse_filter = Control.MOUSE_FILTER_PASS
		reward_layer.z_index = 30
		reward_layer.move_to_front()
	overlay_state = OVERLAY_STATE_REWARDS
	overlay_animating = false
	_sync_reward_flip_hitboxes()

func _finish_overlay_animation() -> void:
	if is_pack_overlay_active():
		overlay_animating = false

func _finish_pack_selection_fly_in() -> void:
	if !is_pack_overlay_active() or overlay_state != OVERLAY_STATE_SELECTION:
		return
	overlay_animating = false
	_start_selection_pack_ambient_motion()

func _on_pack_overlay_viewport_resized() -> void:
	if !is_pack_overlay_active():
		return
	_sync_pack_overlay_rect()
	if overlay_state == OVERLAY_STATE_SELECTION:
		_layout_selection_packs(false)
	elif overlay_state == OVERLAY_STATE_FOCUSED and focused_pack_node != null and is_instance_valid(focused_pack_node):
		var pack_texture: Texture2D = _get_pack_texture_for_node(focused_pack_node)
		_apply_pack_control_size(focused_pack_node, _get_pack_visual_size(pack_texture))
		focused_pack_node.position = _get_focused_pack_position(focused_pack_node.size)
	elif overlay_state == OVERLAY_STATE_REWARDS:
		_arrange_reward_stamps(false)

func _layout_selection_packs(animated: bool) -> void:
	var restart_ambient: bool = overlay_state == OVERLAY_STATE_SELECTION and !overlay_animating
	var positions: Array[Vector2] = _get_selection_pack_positions(opening_pack_nodes.size())
	for i in range(opening_pack_nodes.size()):
		var pack_node: Control = opening_pack_nodes[i]
		if pack_node == null or !is_instance_valid(pack_node):
			continue
		_stop_pack_ambient_motion(pack_node, false)
		var pack_texture: Texture2D = _get_pack_texture_for_node(pack_node)
		_apply_pack_control_size(pack_node, _get_pack_visual_size(pack_texture))
		if animated:
			var tween := pack_overlay.create_tween()
			tween.tween_property(pack_node, "position", positions[i], 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		else:
			pack_node.position = positions[i]
		pack_node.set_meta("selection_position", positions[i])
	if restart_ambient:
		if animated:
			var gate_tween := pack_overlay.create_tween()
			gate_tween.tween_interval(0.22)
			gate_tween.tween_callback(Callable(self, "_start_selection_pack_ambient_motion"))
		else:
			_start_selection_pack_ambient_motion()

func _get_selection_pack_positions(count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if count <= 0:
		return positions

	var viewport_size: Vector2 = _get_viewport_size()
	var pack_size: Vector2 = _get_pack_visual_size()
	var side_margin: float = maxf(118.0, pack_size.x * 1.05)
	var available_width: float = maxf(pack_size.x, viewport_size.x - side_margin * 2.0)
	var gap: float = clampf(viewport_size.x * 0.115, pack_size.x * 0.92, pack_size.x * 1.72)
	if count > 1:
		gap = minf(gap, maxf(18.0, (available_width - pack_size.x * float(count)) / float(count - 1)))
	var row_width: float = pack_size.x * float(count) + gap * float(maxi(0, count - 1))
	var start_x: float = (viewport_size.x - row_width) * 0.5
	var y: float = clampf(
		viewport_size.y * 0.52 - pack_size.y * 0.5,
		96.0,
		maxf(96.0, viewport_size.y - pack_size.y - 72.0)
	)

	for i in range(count):
		var center_x: float = viewport_size.x * 0.5
		if count > 1:
			center_x = start_x + pack_size.x * 0.5 + float(i) * (pack_size.x + gap)
		positions.append(Vector2(center_x - pack_size.x * 0.5, y))
	return positions

func _get_reward_stamp_positions(count: int, scale_factor: float) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if count <= 0:
		return positions

	var viewport_size: Vector2 = _get_viewport_size()
	var visual_size: Vector2 = STAMP_VISUAL_SIZE * scale_factor
	var gap: float = _get_reward_stamp_gap(viewport_size, count, scale_factor)
	var row_width: float = visual_size.x * float(count) + gap * float(maxi(0, count - 1))
	var start_x: float = (viewport_size.x - row_width) * 0.5
	var min_y: float = 96.0
	var max_y: float = maxf(min_y, viewport_size.y - visual_size.y - 48.0)
	var y: float = clampf(viewport_size.y * 0.58 - visual_size.y * 0.5, min_y, max_y)
	for i in range(count):
		var center := Vector2(
			start_x + visual_size.x * 0.5 + float(i) * (visual_size.x + gap),
			y + visual_size.y * 0.5
		)
		positions.append(_get_stamp_position_for_center(center))
	return positions

func _get_stamp_position_for_center(center: Vector2) -> Vector2:
	return center - STAMP_VISUAL_SIZE * 0.5

func _get_reward_stamp_scale(viewport_size: Vector2, count: int) -> float:
	if count <= 0:
		return PACK_REWARD_MAX_SCALE
	var gap: float = clampf(viewport_size.x * 0.034, 18.0, 42.0)
	var available_width: float = maxf(120.0, viewport_size.x - PACK_REWARD_SIDE_MARGIN * 2.0)
	var width_scale: float = (available_width - gap * float(maxi(0, count - 1))) / (STAMP_VISUAL_SIZE.x * float(count))
	var height_scale: float = maxf(PACK_REWARD_MIN_SCALE, (viewport_size.y - 180.0) / STAMP_VISUAL_SIZE.y)
	return clampf(minf(PACK_REWARD_MAX_SCALE, minf(width_scale, height_scale)), PACK_REWARD_MIN_SCALE, PACK_REWARD_MAX_SCALE)

func _get_reward_stamp_gap(viewport_size: Vector2, count: int, scale_factor: float) -> float:
	if count <= 1:
		return 0.0
	var base_gap: float = clampf(viewport_size.x * 0.034, 18.0, 42.0)
	var visual_width: float = STAMP_VISUAL_SIZE.x * scale_factor
	var available_width: float = maxf(120.0, viewport_size.x - PACK_REWARD_SIDE_MARGIN * 2.0)
	var max_gap: float = maxf(8.0, (available_width - visual_width * float(count)) / float(count - 1))
	return minf(base_gap, max_gap)

func _get_pack_texture_for_node(pack_node: Control) -> Texture2D:
	if pack_node is Pack3DView:
		return (pack_node as Pack3DView).get_front_texture()
	if pack_node is TextureRect:
		return (pack_node as TextureRect).texture
	return null

func _get_pack_visual_size(pack_texture: Texture2D = null) -> Vector2:
	var viewport_size: Vector2 = _get_viewport_size()
	var texture: Texture2D = pack_texture if pack_texture != null else BOOSTER_PACK_TEXTURE
	var texture_size: Vector2 = texture.get_size()
	var aspect: float = texture_size.x / maxf(1.0, texture_size.y)
	var height: float = clampf(viewport_size.y * 0.24, 132.0, 190.0)
	return Vector2(height * aspect, height) * PACK_VISUAL_SIZE_SCALE

func _get_focused_pack_position(pack_size: Vector2) -> Vector2:
	var viewport_size: Vector2 = _get_viewport_size()
	return viewport_size * 0.5 - pack_size * 0.5

func _get_edge_start_position(index: int, target_position: Vector2, pack_size: Vector2) -> Vector2:
	var viewport_size: Vector2 = _get_viewport_size()
	match index % 4:
		0:
			return Vector2(-pack_size.x - 64.0, target_position.y)
		1:
			return Vector2(viewport_size.x + 64.0, target_position.y)
		2:
			return Vector2(target_position.x, -pack_size.y - 64.0)
		_:
			return Vector2(target_position.x, viewport_size.y + 64.0)

func _get_viewport_size() -> Vector2:
	if collection != null and is_instance_valid(collection):
		return collection.get_viewport_rect().size
	if pack_overlay != null and is_instance_valid(pack_overlay):
		return pack_overlay.get_viewport_rect().size
	return Vector2(1280.0, 720.0)

func _reset_pack_overlay_content() -> void:
	_clear_reward_stamps()
	for node in opening_pack_nodes:
		if node != null and is_instance_valid(node):
			_stop_pack_ambient_motion(node, false)
	opening_pack_nodes.clear()
	focused_pack_node = null
	if pack_layer != null and is_instance_valid(pack_layer):
		_remove_layer_children(pack_layer, true)
	if reward_layer != null and is_instance_valid(reward_layer):
		_remove_layer_children(reward_layer, false)

func _remove_layer_children(layer: Control, stop_pack_motion: bool) -> void:
	if layer == null or !is_instance_valid(layer):
		return
	for child in layer.get_children():
		if stop_pack_motion and child is Control:
			_stop_pack_ambient_motion(child as Control, false)
		if child.get_parent() == layer:
			layer.remove_child(child)
		if !child.is_queued_for_deletion():
			child.queue_free()

func _clear_reward_stamps() -> void:
	for stamp_visual in revealed_stamp_nodes:
		if stamp_visual != null and is_instance_valid(stamp_visual):
			var parent := stamp_visual.get_parent()
			if parent != null:
				parent.remove_child(stamp_visual)
			if !stamp_visual.is_queued_for_deletion():
				stamp_visual.queue_free()
	revealed_stamp_nodes.clear()
	for hitbox in reward_flip_hitboxes:
		if hitbox != null and is_instance_valid(hitbox):
			var parent := hitbox.get_parent()
			if parent != null:
				parent.remove_child(hitbox)
			if !hitbox.is_queued_for_deletion():
				hitbox.queue_free()
	reward_flip_hitboxes.clear()
	reward_stamp_flipped.clear()
	reward_flip_in_progress = false

func _close_pack_overlay(animated: bool) -> void:
	if !is_pack_overlay_active():
		return

	var overlay_to_close := pack_overlay
	for node in opening_pack_nodes:
		if node != null and is_instance_valid(node):
			_stop_pack_ambient_motion(node, false)
	pack_overlay = null
	pack_overlay_backbuffer = null
	pack_blur_rect = null
	pack_layer = null
	reward_layer = null
	opening_pack_nodes.clear()
	revealed_stamp_nodes.clear()
	reward_stamp_flipped.clear()
	reward_flip_hitboxes.clear()
	focused_pack_node = null
	overlay_state = ""
	overlay_animating = false
	reward_flip_in_progress = false

	if animated and is_instance_valid(overlay_to_close):
		overlay_to_close.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tween := overlay_to_close.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(overlay_to_close, "modulate:a", 0.0, 0.16)
		tween.tween_callback(Callable(overlay_to_close, "queue_free"))
	elif is_instance_valid(overlay_to_close):
		overlay_to_close.queue_free()
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
	_connect_once(pack_click_area, "gui_input", Callable(self, "_on_pack_click_area_gui_input"))

func _sync_pack_click_area() -> void:
	if Engine.is_editor_hint() or is_pack_overlay_active():
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

func _roll_pack_rewards(pack_id: String) -> Array[StampPrint]:
	var pack_definition: PackDefinition = PackDefinitionLibrary.get_pack(pack_id)
	var available_prints: Array[StampPrint] = PackDefinitionLibrary.get_reward_print_pool(pack_definition)

	var rewards: Array[StampPrint] = []
	if available_prints.is_empty():
		return rewards

	for i in range(PACK_REWARD_STAMP_COUNT):
		rewards.append(available_prints[randi() % available_prints.size()])
	return rewards

func _show_pack_result(rewards: Array[StampPrint]) -> void:
	if pack_result_dialog == null or pack_result_label == null:
		return

	var lines: Array[String] = ["You opened:"]
	for stamp_print: StampPrint in rewards:
		var stamp: Stamp = StampPrintLibrary.get_stamp_for_print(stamp_print)
		var stamp_name: String = stamp.stamp_name if stamp != null else stamp_print.stamp_code
		if stamp_print.variant_id != PlayerCollectionStore.DEFAULT_VARIANT_ID:
			stamp_name = "%s - %s" % [stamp_name, stamp_print.get_display_name()]
		lines.append("- %s" % stamp_name)

	pack_result_label.text = "\n".join(lines)
	pack_result_dialog.popup_centered(Vector2i(360, 220))
