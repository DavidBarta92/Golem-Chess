extends RefCounted
class_name CollectionPackShopController

## The collection's pack shop: a modal window with the packs for sale on the left,
## the chosen pack's stamps on the right, and how many to buy under them. It is
## built in code into the scene's BuyPacksPanel the first time it is needed.

const BOOSTER_PACK_TEXTURE = preload("res://Assets/booster.png")
const WINDOW_CLOSE_ICON = preload("res://ui/themes/icons/window_close_large.svg")
const COIN_TEXTURE = preload("res://Assets/coin.svg")
const STAMP_VISUAL = preload("res://Scenes/StampVisual.tscn")
const BUY_PACKS_WINDOW_MIN_SIZE: Vector2 = Vector2(860.0, 430.0)
const BUY_PACKS_WINDOW_MAX_SIZE: Vector2 = Vector2(1180.0, 640.0)
const BUY_PACKS_MODAL_BLOCKER_Z_INDEX: int = 2300
const BUY_PACKS_WINDOW_Z_INDEX: int = 2310
const BUY_PACKS_TOOLTIP_Z_INDEX: int = 2320
const BUY_PACKS_RIGHT_COLUMN_WIDTH: float = 492.0
const BUY_PACKS_PACK_CARD_SIZE: Vector2 = Vector2(132.0, 188.0)
const BUY_PACKS_CONTENT_STAMP_SCALE: float = 0.37
const BUY_PACKS_CONTENT_STAMP_CELL_SIZE: Vector2 = Vector2(62.419, 84.73)
const BUY_PACKS_CONTENT_COLUMNS: int = 5
const BUY_PACKS_CONTENT_H_SEPARATION: float = 46.0
const BUY_PACKS_CONTENT_V_SEPARATION: float = 12.0
const BUY_PACKS_CONTENT_TOP_PADDING: float = 4.0
const BUY_PACKS_STAMP_TOOLTIP_OFFSET: Vector2 = Vector2(14.0, 14.0)

var collection: Control
var buy_packs_panel: PanelContainer
## Called after a purchase, with the queue of unopened packs as it was before it.
var bought_callback: Callable
var buy_packs_modal_blocker: Control
var pack_count_spin_box: SpinBox
var buy_packs_info_label: Label
var buy_packs_confirm_button: Button
var buy_packs_cancel_button: Button
var buy_packs_title_label: Label
var buy_packs_pack_grid: GridContainer
var buy_packs_contents_title: Label
var buy_packs_contents_scroll: ScrollContainer
var buy_packs_contents_list: Control
var buy_packs_stamp_tooltip_panel: PanelContainer
var buy_packs_stamp_tooltip_label: Label
var buy_packs_pack_cards: Dictionary = {}
var buy_packs_open_tween: Tween
var selected_purchase_pack_id: String = ""

func bind(new_collection: Control, panel: PanelContainer, new_bought_callback: Callable) -> void:
	collection = new_collection
	buy_packs_panel = panel
	bought_callback = new_bought_callback
	_ensure_buy_packs_window()
	if buy_packs_panel != null:
		buy_packs_panel.visible = false

func is_open() -> bool:
	return buy_packs_panel != null and is_instance_valid(buy_packs_panel) and buy_packs_panel.visible

func show() -> void:
	if buy_packs_panel == null or pack_count_spin_box == null:
		return

	_ensure_buy_packs_window()
	_layout_buy_packs_window()
	_populate_pack_selector()
	var selected_pack: PackDefinition = _get_selected_purchase_pack()
	var pack_price: int = selected_pack.price if selected_pack != null else PlayerProgressStore.PACK_COST
	var max_pack_count: int = PlayerProgressStore.get_max_affordable_pack_count(pack_price)
	pack_count_spin_box.min_value = 0 if max_pack_count <= 0 else 1
	pack_count_spin_box.max_value = max_pack_count
	pack_count_spin_box.value = 0 if max_pack_count <= 0 else 1
	pack_count_spin_box.editable = max_pack_count > 0 and selected_pack != null
	_update_buy_packs_info()
	if buy_packs_confirm_button != null:
		buy_packs_confirm_button.disabled = max_pack_count <= 0 or selected_pack == null
	_show_buy_packs_modal_animated()

func _ensure_buy_packs_window() -> void:
	if buy_packs_panel == null:
		return
	if bool(buy_packs_panel.get_meta("pack_shop_window_built", false)) and buy_packs_pack_grid != null and is_instance_valid(buy_packs_pack_grid):
		return

	_clear_node_children(buy_packs_panel)
	buy_packs_panel.set_meta("pack_shop_window_built", true)
	buy_packs_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	buy_packs_panel.z_as_relative = false
	buy_packs_panel.z_index = BUY_PACKS_WINDOW_Z_INDEX
	buy_packs_panel.theme_type_variation = &"ShopWindowPanel"
	_ensure_buy_packs_modal_blocker()
	_ensure_buy_packs_stamp_tooltip()

	var root := VBoxContainer.new()
	root.name = "BuyPacksRoot"
	buy_packs_panel.add_child(root)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 0)

	var header_panel := PanelContainer.new()
	header_panel.name = "Header"
	root.add_child(header_panel)
	header_panel.custom_minimum_size = Vector2(0.0, 38.0)
	header_panel.theme_type_variation = &"ShopHeaderPanel"

	var title_row := HBoxContainer.new()
	title_row.name = "TitleRow"
	header_panel.add_child(title_row)
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title_row.add_theme_constant_override("separation", 10)

	# As wide as the close button on the other side, so the centred title sits
	# in the middle of the window, as a window's title does.
	var title_balance := Control.new()
	title_balance.name = "TitleBalance"
	title_balance.custom_minimum_size = Vector2(38.0, 0.0)
	title_balance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(title_balance)

	buy_packs_title_label = Label.new()
	buy_packs_title_label.name = "TitleLabel"
	title_row.add_child(buy_packs_title_label)
	buy_packs_title_label.text = tr("Buy Packs")
	buy_packs_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_packs_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buy_packs_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	buy_packs_title_label.theme_type_variation = &"ShopTitleLabel"

	buy_packs_cancel_button = Button.new()
	buy_packs_cancel_button.name = "CancelButton"
	title_row.add_child(buy_packs_cancel_button)
	buy_packs_cancel_button.set_meta("sfx_click", "")
	buy_packs_cancel_button.text = ""
	buy_packs_cancel_button.icon = WINDOW_CLOSE_ICON
	buy_packs_cancel_button.custom_minimum_size = Vector2(38.0, 38.0)
	buy_packs_cancel_button.focus_mode = Control.FOCUS_NONE
	buy_packs_cancel_button.tooltip_text = tr("Close")
	buy_packs_cancel_button.flat = true
	buy_packs_cancel_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buy_packs_cancel_button.expand_icon = false
	buy_packs_cancel_button.theme_type_variation = &"ShopCloseButton"
	buy_packs_cancel_button.pressed.connect(Callable(self, "_cancel_buy_packs"))

	var content_margin := MarginContainer.new()
	content_margin.name = "ContentMargin"
	root.add_child(content_margin)
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left", 14)
	content_margin.add_theme_constant_override("margin_top", 14)
	content_margin.add_theme_constant_override("margin_right", 14)
	content_margin.add_theme_constant_override("margin_bottom", 14)

	var content_row := HBoxContainer.new()
	content_row.name = "ContentRow"
	content_margin.add_child(content_row)
	content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_theme_constant_override("separation", 14)

	var pack_area := VBoxContainer.new()
	pack_area.name = "PackArea"
	content_row.add_child(pack_area)
	pack_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pack_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pack_area.add_theme_constant_override("separation", 10)

	var pack_area_title := Label.new()
	pack_area_title.name = "PackAreaTitle"
	pack_area.add_child(pack_area_title)
	pack_area_title.text = tr("Packs")
	pack_area_title.theme_type_variation = &"ShopHeadingLabel"

	var pack_scroll := ScrollContainer.new()
	pack_scroll.name = "PackScroll"
	pack_area.add_child(pack_scroll)
	pack_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pack_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pack_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	buy_packs_pack_grid = GridContainer.new()
	buy_packs_pack_grid.name = "PackGrid"
	pack_scroll.add_child(buy_packs_pack_grid)
	buy_packs_pack_grid.columns = 4
	buy_packs_pack_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_packs_pack_grid.add_theme_constant_override("h_separation", 16)
	buy_packs_pack_grid.add_theme_constant_override("v_separation", 16)

	var right_panel := PanelContainer.new()
	right_panel.name = "PackDetailsPanel"
	content_row.add_child(right_panel)
	right_panel.custom_minimum_size = Vector2(BUY_PACKS_RIGHT_COLUMN_WIDTH, 0.0)
	right_panel.theme_type_variation = &"ShopDetailsPanel"

	var right_root := VBoxContainer.new()
	right_panel.add_child(right_root)
	right_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_root.add_theme_constant_override("separation", 4)

	buy_packs_contents_title = Label.new()
	buy_packs_contents_title.name = "PackContentsTitle"
	right_root.add_child(buy_packs_contents_title)
	buy_packs_contents_title.text = tr("Pack contents")
	buy_packs_contents_title.theme_type_variation = &"ShopContentsTitleLabel"

	var contents_scroll := ScrollContainer.new()
	contents_scroll.name = "ContentsScroll"
	right_root.add_child(contents_scroll)
	buy_packs_contents_scroll = contents_scroll
	contents_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contents_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contents_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	contents_scroll.clip_contents = true
	contents_scroll.resized.connect(Callable(self, "_layout_buy_pack_contents_grid"))

	buy_packs_contents_list = Control.new()
	buy_packs_contents_list.name = "ContentsList"
	contents_scroll.add_child(buy_packs_contents_list)
	buy_packs_contents_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_packs_contents_list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var purchase_row := HBoxContainer.new()
	purchase_row.name = "PurchaseRow"
	right_root.add_child(purchase_row)
	purchase_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	purchase_row.alignment = BoxContainer.ALIGNMENT_CENTER
	purchase_row.add_theme_constant_override("separation", 10)

	var price_row := HBoxContainer.new()
	price_row.name = "TotalPriceRow"
	purchase_row.add_child(price_row)
	price_row.custom_minimum_size = Vector2(104.0, 38.0)
	price_row.alignment = BoxContainer.ALIGNMENT_CENTER
	price_row.add_theme_constant_override("separation", 5)

	var total_coin_icon := TextureRect.new()
	total_coin_icon.name = "TotalCoinIcon"
	price_row.add_child(total_coin_icon)
	total_coin_icon.texture = COIN_TEXTURE
	total_coin_icon.custom_minimum_size = Vector2(20.0, 20.0)
	total_coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	total_coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	total_coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	buy_packs_info_label = Label.new()
	buy_packs_info_label.name = "BuyPacksInfoLabel"
	price_row.add_child(buy_packs_info_label)
	buy_packs_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	buy_packs_info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	buy_packs_info_label.theme_type_variation = &"ShopTotalLabel"

	pack_count_spin_box = SpinBox.new()
	pack_count_spin_box.name = "PackCountSpinBox"
	purchase_row.add_child(pack_count_spin_box)
	pack_count_spin_box.min_value = 0
	pack_count_spin_box.max_value = 0
	pack_count_spin_box.step = 1
	pack_count_spin_box.value = 0
	pack_count_spin_box.custom_minimum_size = Vector2(70.0, 38.0)
	pack_count_spin_box.value_changed.connect(Callable(self, "_on_pack_count_spin_value_changed"))

	buy_packs_confirm_button = Button.new()
	buy_packs_confirm_button.name = "BuyButton"
	purchase_row.add_child(buy_packs_confirm_button)
	buy_packs_confirm_button.text = tr("Buy")
	buy_packs_confirm_button.custom_minimum_size = Vector2(132.0, 40.0)
	buy_packs_confirm_button.focus_mode = Control.FOCUS_NONE
	buy_packs_confirm_button.set_meta("sfx_click", "buy")
	buy_packs_confirm_button.pressed.connect(Callable(self, "_confirm_buy_packs"))

func _ensure_buy_packs_modal_blocker() -> void:
	if collection == null or !is_instance_valid(collection):
		return
	if buy_packs_modal_blocker != null and is_instance_valid(buy_packs_modal_blocker):
		return

	buy_packs_modal_blocker = Control.new()
	buy_packs_modal_blocker.name = "BuyPacksModalBlocker"
	collection.add_child(buy_packs_modal_blocker)
	buy_packs_modal_blocker.z_as_relative = false
	buy_packs_modal_blocker.z_index = BUY_PACKS_MODAL_BLOCKER_Z_INDEX
	buy_packs_modal_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	buy_packs_modal_blocker.visible = false
	buy_packs_modal_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	buy_packs_modal_blocker.offset_left = 0.0
	buy_packs_modal_blocker.offset_top = 0.0
	buy_packs_modal_blocker.offset_right = 0.0
	buy_packs_modal_blocker.offset_bottom = 0.0
	buy_packs_modal_blocker.gui_input.connect(Callable(self, "_on_buy_packs_modal_blocker_gui_input"))

func _on_buy_packs_modal_blocker_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventMouseMotion or event is InputEventKey:
		buy_packs_modal_blocker.accept_event()

func _ensure_buy_packs_stamp_tooltip() -> void:
	if collection == null or !is_instance_valid(collection):
		return
	if buy_packs_stamp_tooltip_panel != null and is_instance_valid(buy_packs_stamp_tooltip_panel):
		return

	buy_packs_stamp_tooltip_panel = PanelContainer.new()
	buy_packs_stamp_tooltip_panel.name = "BuyPackStampTooltip"
	collection.add_child(buy_packs_stamp_tooltip_panel)
	buy_packs_stamp_tooltip_panel.visible = false
	buy_packs_stamp_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buy_packs_stamp_tooltip_panel.z_as_relative = false
	buy_packs_stamp_tooltip_panel.z_index = BUY_PACKS_TOOLTIP_Z_INDEX
	buy_packs_stamp_tooltip_panel.theme_type_variation = &"ShopTooltipPanel"

	buy_packs_stamp_tooltip_label = Label.new()
	buy_packs_stamp_tooltip_label.name = "TooltipLabel"
	buy_packs_stamp_tooltip_panel.add_child(buy_packs_stamp_tooltip_label)
	buy_packs_stamp_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buy_packs_stamp_tooltip_label.theme_type_variation = &"ShopTooltipLabel"

func _show_buy_pack_stamp_tooltip(text: String) -> void:
	_ensure_buy_packs_stamp_tooltip()
	if buy_packs_stamp_tooltip_panel == null or !is_instance_valid(buy_packs_stamp_tooltip_panel):
		return
	if buy_packs_stamp_tooltip_label == null or !is_instance_valid(buy_packs_stamp_tooltip_label):
		return
	if text.strip_edges().is_empty():
		_hide_buy_pack_stamp_tooltip()
		return

	buy_packs_stamp_tooltip_label.text = text
	buy_packs_stamp_tooltip_panel.size = buy_packs_stamp_tooltip_panel.get_combined_minimum_size()
	buy_packs_stamp_tooltip_panel.visible = true
	buy_packs_stamp_tooltip_panel.move_to_front()
	_position_buy_pack_stamp_tooltip()

func _hide_buy_pack_stamp_tooltip() -> void:
	if buy_packs_stamp_tooltip_panel != null and is_instance_valid(buy_packs_stamp_tooltip_panel):
		buy_packs_stamp_tooltip_panel.visible = false

func _position_buy_pack_stamp_tooltip() -> void:
	if collection == null or !is_instance_valid(collection):
		return
	if buy_packs_stamp_tooltip_panel == null or !is_instance_valid(buy_packs_stamp_tooltip_panel):
		return
	if !buy_packs_stamp_tooltip_panel.visible:
		return

	var tooltip_size: Vector2 = buy_packs_stamp_tooltip_panel.size
	if tooltip_size == Vector2.ZERO:
		tooltip_size = buy_packs_stamp_tooltip_panel.get_combined_minimum_size()
	var viewport_size: Vector2 = _get_viewport_size()
	var desired_position: Vector2 = collection.get_global_mouse_position() + BUY_PACKS_STAMP_TOOLTIP_OFFSET
	desired_position.x = clampf(desired_position.x, 8.0, maxf(8.0, viewport_size.x - tooltip_size.x - 8.0))
	desired_position.y = clampf(desired_position.y, 8.0, maxf(8.0, viewport_size.y - tooltip_size.y - 8.0))
	buy_packs_stamp_tooltip_panel.global_position = desired_position

func _set_buy_packs_modal_visible(visible: bool) -> void:
	if !visible and buy_packs_open_tween != null and buy_packs_open_tween.is_valid():
		buy_packs_open_tween.kill()
		buy_packs_open_tween = null
	if !visible:
		_hide_buy_pack_stamp_tooltip()
	if buy_packs_modal_blocker != null and is_instance_valid(buy_packs_modal_blocker):
		buy_packs_modal_blocker.visible = visible
		if visible:
			buy_packs_modal_blocker.move_to_front()
	if buy_packs_panel != null and is_instance_valid(buy_packs_panel):
		buy_packs_panel.visible = visible
		if !visible:
			buy_packs_panel.modulate.a = 1.0
		if visible:
			buy_packs_panel.move_to_front()
	GlobalTopBar.set_window_open("buy_packs", visible)

func _show_buy_packs_modal_animated() -> void:
	if buy_packs_panel == null or !is_instance_valid(buy_packs_panel):
		return
	_set_buy_packs_modal_visible(true)
	if buy_packs_open_tween != null and buy_packs_open_tween.is_valid():
		buy_packs_open_tween.kill()

	var final_top: float = buy_packs_panel.offset_top
	var final_bottom: float = buy_packs_panel.offset_bottom
	buy_packs_panel.set_meta("buy_packs_final_top", final_top)
	buy_packs_panel.set_meta("buy_packs_final_bottom", final_bottom)
	buy_packs_panel.modulate.a = 0.0
	buy_packs_panel.offset_top = final_top - 28.0
	buy_packs_panel.offset_bottom = final_bottom - 28.0

	buy_packs_open_tween = buy_packs_panel.create_tween()
	buy_packs_open_tween.set_parallel(true)
	buy_packs_open_tween.tween_property(buy_packs_panel, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	buy_packs_open_tween.tween_property(buy_packs_panel, "offset_top", final_top, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	buy_packs_open_tween.tween_property(buy_packs_panel, "offset_bottom", final_bottom, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _hide_buy_packs_modal_animated() -> void:
	if buy_packs_panel == null or !is_instance_valid(buy_packs_panel):
		_set_buy_packs_modal_visible(false)
		return
	if !buy_packs_panel.visible:
		_set_buy_packs_modal_visible(false)
		return
	if buy_packs_open_tween != null and buy_packs_open_tween.is_valid():
		buy_packs_open_tween.kill()

	var final_top: float = float(buy_packs_panel.get_meta("buy_packs_final_top", buy_packs_panel.offset_top))
	var final_bottom: float = float(buy_packs_panel.get_meta("buy_packs_final_bottom", buy_packs_panel.offset_bottom))
	buy_packs_panel.modulate.a = 1.0

	buy_packs_open_tween = buy_packs_panel.create_tween()
	buy_packs_open_tween.tween_property(buy_packs_panel, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	buy_packs_open_tween.parallel().tween_property(buy_packs_panel, "offset_top", final_top - 28.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	buy_packs_open_tween.parallel().tween_property(buy_packs_panel, "offset_bottom", final_bottom - 28.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	buy_packs_open_tween.tween_callback(Callable(self, "_finish_hide_buy_packs_modal").bind(final_top, final_bottom))

func _finish_hide_buy_packs_modal(final_top: float, final_bottom: float) -> void:
	if buy_packs_modal_blocker != null and is_instance_valid(buy_packs_modal_blocker):
		buy_packs_modal_blocker.visible = false
	if buy_packs_panel != null and is_instance_valid(buy_packs_panel):
		buy_packs_panel.visible = false
		buy_packs_panel.modulate.a = 1.0
		buy_packs_panel.offset_top = final_top
		buy_packs_panel.offset_bottom = final_bottom
	buy_packs_open_tween = null
	GlobalTopBar.set_window_open("buy_packs", false)

func _clear_node_children(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _on_purchase_pack_card_pressed(pack_id: String) -> void:
	selected_purchase_pack_id = pack_id
	_update_buy_pack_card_selection()
	_refresh_buy_pack_contents()
	_update_buy_packs_info()

func _on_pack_count_spin_value_changed(_value: float) -> void:
	_update_buy_packs_info()

func _populate_pack_selector() -> void:
	_ensure_buy_packs_window()
	if buy_packs_pack_grid == null or !is_instance_valid(buy_packs_pack_grid):
		return

	PackDefinitionLibrary.ensure_loaded()
	var available_packs: Array[PackDefinition] = PackDefinitionLibrary.get_available_packs()
	_clear_node_children(buy_packs_pack_grid)
	buy_packs_pack_cards.clear()

	if available_packs.is_empty():
		selected_purchase_pack_id = ""
		_refresh_buy_pack_contents()
		return

	var has_selected_pack: bool = false
	for pack_definition in available_packs:
		if pack_definition.get_resolved_id() == selected_purchase_pack_id:
			has_selected_pack = true
			break
	if !has_selected_pack:
		selected_purchase_pack_id = available_packs[0].get_resolved_id()

	for pack_definition in available_packs:
		var card := _create_buy_pack_card(pack_definition)
		buy_packs_pack_grid.add_child(card)
		buy_packs_pack_cards[pack_definition.get_resolved_id()] = card

	_update_buy_pack_card_selection()
	_refresh_buy_pack_contents()

func _layout_buy_packs_window() -> void:
	if buy_packs_panel == null or !is_instance_valid(buy_packs_panel):
		return
	var viewport_size: Vector2 = _get_viewport_size()
	var max_window_width: float = maxf(560.0, minf(BUY_PACKS_WINDOW_MAX_SIZE.x, viewport_size.x - 48.0))
	var max_window_height: float = maxf(360.0, minf(BUY_PACKS_WINDOW_MAX_SIZE.y, viewport_size.y - 64.0))
	var min_window_width: float = minf(BUY_PACKS_WINDOW_MIN_SIZE.x, max_window_width)
	var min_window_height: float = minf(BUY_PACKS_WINDOW_MIN_SIZE.y, max_window_height)
	var window_size := Vector2(
		clampf(viewport_size.x * 0.78, min_window_width, max_window_width),
		clampf(viewport_size.y * 0.68, min_window_height, max_window_height)
	)
	buy_packs_panel.anchor_left = 0.5
	buy_packs_panel.anchor_right = 0.5
	buy_packs_panel.anchor_top = 0.5
	buy_packs_panel.anchor_bottom = 0.5
	buy_packs_panel.offset_left = -window_size.x * 0.5
	buy_packs_panel.offset_right = window_size.x * 0.5
	buy_packs_panel.offset_top = -window_size.y * 0.5
	buy_packs_panel.offset_bottom = window_size.y * 0.5

func _create_buy_pack_card(pack_definition: PackDefinition) -> Button:
	var pack_id: String = pack_definition.get_resolved_id()
	var card := Button.new()
	card.name = "PackCard_%s" % pack_id
	card.custom_minimum_size = BUY_PACKS_PACK_CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	card.toggle_mode = true
	card.text = ""
	card.mouse_default_cursor_shape = Control.CURSOR_ARROW
	card.theme_type_variation = &"PackCardButton"

	var root := VBoxContainer.new()
	card.add_child(root)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 9.0
	root.offset_top = 9.0
	root.offset_right = -9.0
	root.offset_bottom = -9.0
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("separation", 6)

	var texture_rect := TextureRect.new()
	root.add_child(texture_rect)
	texture_rect.custom_minimum_size = Vector2(0.0, 102.0)
	texture_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texture_rect.texture = pack_definition.get_front_texture()
	if texture_rect.texture == null:
		texture_rect.texture = BOOSTER_PACK_TEXTURE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	var name_label := Label.new()
	root.add_child(name_label)
	name_label.text = pack_definition.get_display_name()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.theme_type_variation = &"PackCardNameLabel"
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var price_row := HBoxContainer.new()
	root.add_child(price_row)
	price_row.alignment = BoxContainer.ALIGNMENT_CENTER
	price_row.add_theme_constant_override("separation", 4)
	price_row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var coin_icon := TextureRect.new()
	price_row.add_child(coin_icon)
	coin_icon.texture = COIN_TEXTURE
	coin_icon.custom_minimum_size = Vector2(16.0, 16.0)
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var price_label := Label.new()
	price_row.add_child(price_label)
	price_label.text = "%d" % pack_definition.price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.theme_type_variation = &"PackCardPriceLabel"
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	card.pressed.connect(Callable(self, "_on_purchase_pack_card_pressed").bind(pack_id))
	return card

func _update_buy_pack_card_selection() -> void:
	for pack_id_value in buy_packs_pack_cards.keys():
		var pack_id: String = str(pack_id_value)
		var card := buy_packs_pack_cards.get(pack_id) as Button
		if card == null or !is_instance_valid(card):
			continue
		var selected: bool = pack_id == selected_purchase_pack_id
		card.button_pressed = selected
		# The selected card keeps its selected look under the mouse too.
		card.theme_type_variation = &"PackCardButtonSelected" if selected else &"PackCardButton"

func _refresh_buy_pack_contents() -> void:
	if buy_packs_contents_list == null or !is_instance_valid(buy_packs_contents_list):
		return
	_hide_buy_pack_stamp_tooltip()
	_clear_node_children(buy_packs_contents_list)
	if buy_packs_contents_scroll != null and is_instance_valid(buy_packs_contents_scroll):
		buy_packs_contents_scroll.scroll_vertical = 0

	var selected_pack: PackDefinition = _get_selected_purchase_pack()
	if selected_pack == null:
		if buy_packs_contents_title != null:
			buy_packs_contents_title.text = tr("Pack contents")
		_add_pack_contents_label(tr("No available packs."))
		return

	if buy_packs_contents_title != null:
		buy_packs_contents_title.text = selected_pack.get_display_name()

	var print_pool: Array[StampPrint] = PackDefinitionLibrary.get_reward_print_pool(selected_pack)
	var added_count: int = 0
	for stamp_print in print_pool:
		if StampPrintLibrary.get_stamp_for_print(stamp_print) == null:
			continue
		_add_pack_contents_stamp(stamp_print)
		added_count += 1

	if added_count <= 0:
		_add_pack_contents_label(tr("This pack has no configured stamps."))
	_queue_buy_pack_contents_grid_layout()

func _add_pack_contents_label(text: String) -> void:
	if buy_packs_contents_list == null or !is_instance_valid(buy_packs_contents_list):
		return
	var label := Label.new()
	buy_packs_contents_list.add_child(label)
	label.custom_minimum_size = Vector2(BUY_PACKS_RIGHT_COLUMN_WIDTH - 36.0, 32.0)
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.theme_type_variation = &"ShopNoteLabel"
	_queue_buy_pack_contents_grid_layout()

func _add_pack_contents_stamp(stamp_print: StampPrint) -> void:
	if buy_packs_contents_list == null or !is_instance_valid(buy_packs_contents_list):
		return
	var cell := Control.new()
	cell.name = "ContentStampCell"
	buy_packs_contents_list.add_child(cell)
	cell.custom_minimum_size = BUY_PACKS_CONTENT_STAMP_CELL_SIZE
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	cell.mouse_filter = Control.MOUSE_FILTER_PASS
	var stamp_display_name: String = _get_stamp_print_display_name(stamp_print)
	cell.tooltip_text = stamp_display_name
	cell.mouse_entered.connect(Callable(self, "_show_buy_pack_stamp_tooltip").bind(stamp_display_name))
	cell.mouse_exited.connect(Callable(self, "_hide_buy_pack_stamp_tooltip"))
	cell.gui_input.connect(Callable(self, "_on_buy_pack_content_stamp_gui_input"))

	var stamp_visual := STAMP_VISUAL.instantiate() as StampVisual
	cell.add_child(stamp_visual)
	stamp_visual.custom_minimum_size = StampVisual.STAMP_SIZE
	stamp_visual.size = StampVisual.STAMP_SIZE
	stamp_visual.pivot_offset = StampVisual.STAMP_SIZE * 0.5
	stamp_visual.set_hover_raise_enabled(false)
	stamp_visual.set_stamp_print(stamp_print)
	stamp_visual.set_face_down(false)
	stamp_visual.set_collection_owned(true)
	stamp_visual.set_rest_scale(Vector2.ONE * BUY_PACKS_CONTENT_STAMP_SCALE)
	stamp_visual.scale = Vector2.ONE * BUY_PACKS_CONTENT_STAMP_SCALE
	stamp_visual.draggable = false
	stamp_visual.disabled = true
	stamp_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout_pack_contents_stamp(cell, stamp_visual)
	cell.resized.connect(Callable(self, "_layout_pack_contents_stamp").bind(cell, stamp_visual))
	_queue_buy_pack_contents_grid_layout()

func _on_buy_pack_content_stamp_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_position_buy_pack_stamp_tooltip()

func _queue_buy_pack_contents_grid_layout() -> void:
	if buy_packs_contents_list == null or !is_instance_valid(buy_packs_contents_list):
		return
	_layout_buy_pack_contents_grid()
	call_deferred("_layout_buy_pack_contents_grid")

func _layout_buy_pack_contents_grid() -> void:
	if buy_packs_contents_list == null or !is_instance_valid(buy_packs_contents_list):
		return

	var content_width: float = _get_buy_pack_contents_width()
	buy_packs_contents_list.position = Vector2.ZERO
	var stamp_cells: Array[Control] = []
	var label_controls: Array[Control] = []
	for child in buy_packs_contents_list.get_children():
		var control := child as Control
		if control == null:
			continue
		if control is Label:
			label_controls.append(control)
		else:
			stamp_cells.append(control)

	var y: float = 0.0
	for label_control in label_controls:
		label_control.position = Vector2.ZERO
		label_control.size = Vector2(content_width, maxf(32.0, label_control.get_combined_minimum_size().y))
		y = maxf(y, label_control.size.y)

	if !stamp_cells.is_empty():
		var column_count: int = BUY_PACKS_CONTENT_COLUMNS
		var cell_width: float = BUY_PACKS_CONTENT_STAMP_CELL_SIZE.x
		var row_height: float = BUY_PACKS_CONTENT_STAMP_CELL_SIZE.y
		var available_gap: float = (content_width - cell_width * float(column_count)) / float(maxi(1, column_count - 1))
		var gap_width: float = minf(BUY_PACKS_CONTENT_H_SEPARATION, maxf(0.0, available_gap))
		var group_width: float = cell_width * float(column_count) + gap_width * float(column_count - 1)
		var start_x: float = maxf(0.0, (content_width - group_width) * 0.5)
		y += BUY_PACKS_CONTENT_TOP_PADDING
		for i in range(stamp_cells.size()):
			var cell: Control = stamp_cells[i]
			var column: int = i % column_count
			var row: int = int(i / column_count)
			cell.position = Vector2(
				start_x + float(column) * (cell_width + gap_width),
				y + float(row) * (row_height + BUY_PACKS_CONTENT_V_SEPARATION)
			)
			cell.size = Vector2(cell_width, row_height)
			if cell.get_child_count() > 0:
				var stamp_visual := cell.get_child(0) as StampVisual
				if stamp_visual != null:
					_layout_pack_contents_stamp(cell, stamp_visual)
		var row_count: int = int(ceil(float(stamp_cells.size()) / float(column_count)))
		y += float(row_count) * row_height + float(maxi(0, row_count - 1)) * BUY_PACKS_CONTENT_V_SEPARATION

	buy_packs_contents_list.custom_minimum_size = Vector2(content_width, y)
	buy_packs_contents_list.size = Vector2(content_width, y)

func _get_buy_pack_contents_width() -> float:
	if buy_packs_contents_scroll != null and is_instance_valid(buy_packs_contents_scroll):
		var scrollbar_width: float = 0.0
		var vertical_bar := buy_packs_contents_scroll.get_v_scroll_bar()
		if vertical_bar != null and vertical_bar.visible:
			scrollbar_width = vertical_bar.size.x
		if buy_packs_contents_scroll.size.x > 0.0:
			return maxf(BUY_PACKS_CONTENT_STAMP_CELL_SIZE.x, buy_packs_contents_scroll.size.x - scrollbar_width)
	if buy_packs_contents_list != null and is_instance_valid(buy_packs_contents_list) and buy_packs_contents_list.size.x > 0.0:
		return buy_packs_contents_list.size.x
	return BUY_PACKS_RIGHT_COLUMN_WIDTH - 24.0

func _layout_pack_contents_stamp(cell: Control, stamp_visual: StampVisual) -> void:
	if cell == null or !is_instance_valid(cell) or stamp_visual == null or !is_instance_valid(stamp_visual):
		return
	var cell_size: Vector2 = cell.size
	if cell_size == Vector2.ZERO:
		cell_size = cell.custom_minimum_size
	var stamp_scale := Vector2(absf(stamp_visual.scale.x), absf(stamp_visual.scale.y))
	var visual_size: Vector2 = StampVisual.STAMP_SIZE * stamp_scale
	var desired_top_left := Vector2(maxf(0.0, (cell_size.x - visual_size.x) * 0.5), 0.0)
	var pivot_compensation := Vector2(
		stamp_visual.pivot_offset.x * (1.0 - stamp_scale.x),
		stamp_visual.pivot_offset.y * (1.0 - stamp_scale.y)
	)
	stamp_visual.position = desired_top_left - pivot_compensation

func _get_stamp_print_display_name(stamp_print: StampPrint) -> String:
	var stamp: Stamp = StampPrintLibrary.get_stamp_for_print(stamp_print)
	if stamp == null:
		return stamp_print.get_display_name()
	var display_name: String = stamp.stamp_name
	if stamp_print.variant_id != PlayerCollectionStore.DEFAULT_VARIANT_ID:
		display_name = "%s - %s" % [display_name, stamp_print.get_display_name()]
	return display_name

func _get_selected_purchase_pack() -> PackDefinition:
	if selected_purchase_pack_id.is_empty():
		var first_pack: PackDefinition = PackDefinitionLibrary.get_first_available_pack()
		selected_purchase_pack_id = first_pack.get_resolved_id() if first_pack != null else ""
	return PackDefinitionLibrary.get_pack(selected_purchase_pack_id)

func _update_buy_packs_info() -> void:
	if buy_packs_info_label == null or pack_count_spin_box == null:
		return

	var selected_pack: PackDefinition = _get_selected_purchase_pack()
	if selected_pack == null:
		buy_packs_info_label.text = "0"
		if buy_packs_confirm_button != null:
			buy_packs_confirm_button.disabled = true
		return

	var max_pack_count: int = PlayerProgressStore.get_max_affordable_pack_count(selected_pack.price)
	if max_pack_count <= 0:
		pack_count_spin_box.min_value = 0
		pack_count_spin_box.max_value = 0
		pack_count_spin_box.value = 0
		pack_count_spin_box.editable = false
		buy_packs_info_label.text = "0"
		if buy_packs_confirm_button != null:
			buy_packs_confirm_button.disabled = true
		return

	pack_count_spin_box.min_value = 1
	pack_count_spin_box.max_value = max_pack_count
	pack_count_spin_box.editable = true
	if int(pack_count_spin_box.value) < 1:
		pack_count_spin_box.value = 1
	if int(pack_count_spin_box.value) > max_pack_count:
		pack_count_spin_box.value = max_pack_count

	var pack_count: int = int(pack_count_spin_box.value)
	var total_cost: int = pack_count * selected_pack.price
	buy_packs_info_label.text = "%d" % total_cost
	if buy_packs_confirm_button != null:
		buy_packs_confirm_button.disabled = pack_count <= 0 or total_cost > PlayerProgressStore.get_points()

func _confirm_buy_packs() -> void:
	var pack_count: int = int(pack_count_spin_box.value) if pack_count_spin_box != null else 0
	var selected_pack: PackDefinition = _get_selected_purchase_pack()
	if selected_pack == null:
		return
	var previous_queue: Array[String] = PlayerProgressStore.get_unopened_pack_queue()
	if !PlayerProgressStore.purchase_packs(pack_count, selected_pack.get_resolved_id(), selected_pack.price):
		return

	SFXManager.play("buy_packs_window_closing")
	_set_buy_packs_modal_visible(false)
	if bought_callback.is_valid():
		bought_callback.call(previous_queue)

func _cancel_buy_packs() -> void:
	SFXManager.play("buy_packs_window_closing")
	_hide_buy_packs_modal_animated()

func _get_viewport_size() -> Vector2:
	if collection != null and is_instance_valid(collection):
		return collection.get_viewport_rect().size
	return Vector2(1280.0, 720.0)
