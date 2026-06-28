extends RefCounted
class_name CollectionPackController

const BOOSTER_PACK_TEXTURE = preload("res://Assets/booster.png")
const PACK_REWARD_STAMP_COUNT: int = 3
const MAX_VISIBLE_PACK_ICONS: int = 4

var buy_packs_button: Button
var points_label: Label
var buy_packs_panel: PanelContainer
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

func bind(nodes: Dictionary, opened_callback: Callable = Callable()) -> void:
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

	if !Engine.is_editor_hint():
		PlayerProgressStore.ensure_loaded()
		PlayerCollectionStore.ensure_loaded()

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

func _collect_pack_preview_nodes() -> void:
	pack_preview_nodes.clear()
	if pack_inventory == null:
		return

	for i in range(MAX_VISIBLE_PACK_ICONS):
		var preview := pack_inventory.get_node_or_null("PackPreview%d" % (i + 1)) as Control
		if preview == null:
			continue
		pack_preview_nodes.append(preview)
		preview.mouse_filter = Control.MOUSE_FILTER_STOP
		preview.tooltip_text = "Open pack"
		if preview is TextureRect:
			var texture_preview := preview as TextureRect
			texture_preview.texture = BOOSTER_PACK_TEXTURE
			texture_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_connect_once(preview, "gui_input", Callable(self, "_on_pack_preview_gui_input").bind(preview))

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
	if pack_inventory_label != null:
		pack_inventory_label.text = "%d unopened" % pack_count if pack_count > 0 else "No unopened packs"
	if pack_notice_panel != null:
		pack_notice_panel.visible = pack_count > 0
	pack_inventory.visible = pack_count > 0
	var visible_count: int = mini(pack_count, MAX_VISIBLE_PACK_ICONS)
	for i in range(pack_preview_nodes.size()):
		pack_preview_nodes[i].visible = i < visible_count

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

	var max_pack_count: int = PlayerProgressStore.get_max_affordable_pack_count()
	pack_count_spin_box.min_value = 0 if max_pack_count <= 0 else 1
	pack_count_spin_box.max_value = max_pack_count
	pack_count_spin_box.value = 0 if max_pack_count <= 0 else 1
	pack_count_spin_box.editable = max_pack_count > 0
	update_buy_packs_info()
	if buy_packs_confirm_button != null:
		buy_packs_confirm_button.disabled = max_pack_count <= 0
	buy_packs_panel.visible = true
	buy_packs_panel.move_to_front()

func on_pack_count_spin_value_changed(_value: float) -> void:
	update_buy_packs_info()

func update_buy_packs_info() -> void:
	if buy_packs_info_label == null or pack_count_spin_box == null:
		return

	var max_pack_count: int = PlayerProgressStore.get_max_affordable_pack_count()
	if max_pack_count <= 0:
		buy_packs_info_label.text = "Pack: %d points\nNot enough points." % PlayerProgressStore.PACK_COST
		return

	var pack_count: int = int(pack_count_spin_box.value)
	var total_cost: int = pack_count * PlayerProgressStore.PACK_COST
	buy_packs_info_label.text = "%d points each | Max: %d\nCost: %d points" % [
		PlayerProgressStore.PACK_COST,
		max_pack_count,
		total_cost,
	]

func confirm_buy_packs() -> void:
	var pack_count: int = int(pack_count_spin_box.value) if pack_count_spin_box != null else 0
	if !PlayerProgressStore.purchase_packs(pack_count):
		return

	if buy_packs_panel != null:
		buy_packs_panel.visible = false
	refresh_progress_ui()
	refresh_pack_inventory_ui()

func cancel_buy_packs() -> void:
	if buy_packs_panel != null:
		buy_packs_panel.visible = false

func open_pack() -> void:
	if PlayerProgressStore.get_unopened_pack_count() <= 0:
		return

	var rewards: Array[StampPrint] = _roll_pack_rewards()
	if rewards.is_empty():
		return
	if !PlayerProgressStore.open_pack():
		return

	for stamp_print: StampPrint in rewards:
		PlayerCollectionStore.add_local_print_copy(stamp_print.print_id)

	_show_pack_result(rewards)
	refresh_progress_ui()
	refresh_pack_inventory_ui()
	if pack_opened_callback.is_valid():
		pack_opened_callback.call(rewards)

func _roll_pack_rewards() -> Array[StampPrint]:
	var available_prints: Array[StampPrint] = []
	for stamp_print_value in StampPrintLibrary.get_all_prints():
		var stamp_print: StampPrint = stamp_print_value as StampPrint
		if stamp_print != null && StampPrintLibrary.get_stamp_for_print(stamp_print) != null:
			available_prints.append(stamp_print)

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
