extends RefCounted
class_name StackbuilderPackController

const BOOSTER_PACK_TEXTURE = preload("res://Assets/booster.png")
const PACK_REWARD_CARD_COUNT: int = 3
const PACK_ICON_SIZE: Vector2 = Vector2(54, 75)
const PACK_ICON_OVERLAP: float = 18.0
const MAX_VISIBLE_PACK_ICONS: int = 4

var buy_packs_button: Button
var points_label: Label
var buy_packs_panel: PanelContainer
var pack_count_spin_box: SpinBox
var buy_packs_info_label: Label
var buy_packs_confirm_button: Button
var buy_packs_cancel_button: Button
var pack_inventory: Control
var pack_inventory_label: Label
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

	for child in pack_inventory.get_children():
		pack_inventory.remove_child(child)
		child.queue_free()

	var pack_count: int = PlayerProgressStore.get_unopened_pack_count()
	if pack_inventory_label != null:
		pack_inventory_label.text = "%d unopened" % pack_count if pack_count > 0 else "No unopened packs"
	pack_inventory.visible = pack_count > 0
	if pack_count <= 0:
		return

	var visible_count: int = mini(pack_count, MAX_VISIBLE_PACK_ICONS)
	var start_x: float = 8.0
	var start_y: float = maxf(4.0, (pack_inventory.size.y - PACK_ICON_SIZE.y - float(visible_count - 1) * 3.0) * 0.5)
	for i in range(visible_count):
		var pack_button := _create_pack_button()
		pack_inventory.add_child(pack_button)
		pack_button.size = PACK_ICON_SIZE
		pack_button.position = Vector2(start_x + float(i) * PACK_ICON_OVERLAP, start_y + float(i) * 3.0)
		pack_button.rotation = deg_to_rad(-4.0 + float(i) * 3.0)

func populate_editor_pack_preview() -> void:
	if pack_inventory == null:
		return
	if pack_inventory_label != null:
		pack_inventory_label.text = "3 unopened"
	for child in pack_inventory.get_children():
		pack_inventory.remove_child(child)
		child.queue_free()
	for i in range(3):
		var pack_card := TextureRect.new()
		pack_inventory.add_child(pack_card)
		pack_card.texture = BOOSTER_PACK_TEXTURE
		pack_card.custom_minimum_size = PACK_ICON_SIZE
		pack_card.size = PACK_ICON_SIZE
		pack_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pack_card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pack_card.position = Vector2(8.0 + float(i) * PACK_ICON_OVERLAP, 4.0 + float(i) * 3.0)
		pack_card.rotation = deg_to_rad(-4.0 + float(i) * 3.0)

func _create_pack_button() -> Button:
	var pack_button := Button.new()
	pack_button.custom_minimum_size = PACK_ICON_SIZE
	pack_button.size = PACK_ICON_SIZE
	pack_button.tooltip_text = "Open pack"
	pack_button.focus_mode = Control.FOCUS_NONE
	pack_button.clip_contents = false
	pack_button.pressed.connect(open_pack)

	var pack_art := TextureRect.new()
	pack_button.add_child(pack_art)
	pack_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	pack_art.offset_left = 4.0
	pack_art.offset_top = 4.0
	pack_art.offset_right = -4.0
	pack_art.offset_bottom = -4.0
	pack_art.texture = BOOSTER_PACK_TEXTURE
	pack_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pack_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pack_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return pack_button

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

	var rewards: Array[CardPrint] = _roll_pack_rewards()
	if rewards.is_empty():
		return
	if !PlayerProgressStore.open_pack():
		return

	for card_print: CardPrint in rewards:
		PlayerCollectionStore.add_local_print_copy(card_print.print_id)

	_show_pack_result(rewards)
	refresh_progress_ui()
	refresh_pack_inventory_ui()
	if pack_opened_callback.is_valid():
		pack_opened_callback.call(rewards)

func _roll_pack_rewards() -> Array[CardPrint]:
	var available_prints: Array[CardPrint] = []
	for card_print_value in CardPrintLibrary.get_all_prints():
		var card_print: CardPrint = card_print_value as CardPrint
		if card_print != null && CardPrintLibrary.get_card_for_print(card_print) != null:
			available_prints.append(card_print)

	var rewards: Array[CardPrint] = []
	if available_prints.is_empty():
		return rewards

	for i in range(PACK_REWARD_CARD_COUNT):
		rewards.append(available_prints[randi() % available_prints.size()])
	return rewards

func _show_pack_result(rewards: Array[CardPrint]) -> void:
	if pack_result_dialog == null or pack_result_label == null:
		return

	var lines: Array[String] = ["You opened:"]
	for card_print: CardPrint in rewards:
		var card: Card = CardPrintLibrary.get_card_for_print(card_print)
		var card_name: String = card.card_name if card != null else card_print.card_code
		if card_print.variant_id != PlayerCollectionStore.DEFAULT_VARIANT_ID:
			card_name = "%s - %s" % [card_name, card_print.get_display_name()]
		lines.append("- %s" % card_name)

	pack_result_label.text = "\n".join(lines)
	pack_result_dialog.popup_centered(Vector2i(360, 220))
