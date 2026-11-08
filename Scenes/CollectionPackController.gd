extends RefCounted
class_name CollectionPackController

const BOOSTER_PACK_TEXTURE = preload("res://Assets/booster.png")
const PACK_3D_VIEW = preload("res://Scenes/Pack3DView.tscn")
const WINDOW_CLOSE_ICON = preload("res://ui/themes/icons/window_close_large.svg")
const COIN_TEXTURE = preload("res://Assets/coin.svg")
const STAMP_VISUAL = preload("res://Scenes/StampVisual.tscn")
const PACK_REWARD_STAMP_COUNT: int = 4
const MAX_VISIBLE_PACK_ICONS: int = 4
const MAX_SELECTION_PACK_ICONS: int = 15
## Above the top bar, under the paper texture and so printed on the same paper.
const PACK_OVERLAY_LAYER: int = 1205
const PACK_OVERLAY_DIM: Color = Color(0.0, 0.0, 0.0, 0.9)
const PACK_FLY_IN_SECONDS: float = 0.42
const PACK_FLY_STAGGER_SECONDS: float = 0.055
const PACK_FOCUS_SECONDS: float = 0.42
const PACK_INVENTORY_PREVIEW_SCALE: float = 1.1
const PACK_VISUAL_SIZE_SCALE: float = 1.15
## How tall the pack being opened stands, as a share of the screen.
const PACK_FOCUSED_HEIGHT_SHARE: float = 0.56
const PACK_FOCUSED_FOIL: float = 0.22
const PACK_TEAR_CUT_Y: float = 0.085
const PACK_TEAR_WAVE_STRENGTH: float = 0.012
const PACK_TEAR_EDGE_SOFTNESS: float = 0.006
## How long the torn pack holds its breath before the stamps come, by the best
## rarity inside: the rarer, the longer the light has to build.
const PACK_BREATH_SECONDS: Dictionary = {
	StampPrint.Rarity.BASIC: 0.14,
	StampPrint.Rarity.FOIL: 0.5,
	StampPrint.Rarity.FULL_ART: 0.95,
}
const PACK_LIGHT_STRENGTH: Dictionary = {
	StampPrint.Rarity.FOIL: 0.42,
	StampPrint.Rarity.FULL_ART: 0.9,
}
const PACK_LIGHT_SHAKE: float = 0.012
const PACK_KICK_WORLD: float = 0.09
## The stamps peek this far over the torn edge before they come out.
const PACK_STAMP_PEEK: float = 9.0
## How much of a stamp is out of the pack at the top of its rise.
const PACK_STAMP_RISE_SHARE: float = 0.62
const PACK_STAMP_RISE_SECONDS: float = 0.34
const PACK_STAMP_RISE_STAGGER: float = 0.09
## They come out as one stack, narrower than the pack: a stamp showing beside the
## pack would look as if it had come from behind it.
const PACK_STAMP_RISE_SPREAD: float = 5.0
const PACK_STAMP_RISE_DEGREES: float = 1.2
## Stamps are built over several frames, this many a frame: one takes a few
## milliseconds, and a whole heap of them at once would stop the game.
const PACK_STAMPS_BUILT_PER_FRAME: int = 2
const PACK_DROP_WORLD: float = 4.4
const PACK_FALL_SECONDS: float = 0.52
const PACK_REWARD_SPREAD_SECONDS: float = 0.44
const PACK_REWARD_SPREAD_STAGGER: float = 0.05
const PACK_REWARD_FLIP_SECONDS: float = 0.18
## A turned stamp jumps a little, as the reward scenes' cards do.
const PACK_REWARD_HOP_HEIGHT: float = 0.1
const PACK_REWARD_HOP_GROW: float = 0.06
const PACK_REWARD_FOIL_LIFT: float = 14.0
const PACK_REWARD_FOIL_LIFT_SECONDS: float = 0.16
const PACK_REWARD_CAPTION_SIZE: Vector2 = Vector2(230.0, 44.0)
const PACK_REWARD_CAPTION_GAP: float = 10.0
const PACK_REWARD_DESCRIPTION_WIDTH: float = 320.0
## What the description leaves free at the edges of the screen, and under it for the hint.
const PACK_REWARD_DESCRIPTION_MARGIN: float = 16.0
const PACK_REWARD_DESCRIPTION_FOOTER: float = 44.0
## A click while the opening plays runs what is left at this speed.
const PACK_SKIP_SPEED: float = 3.5
const PACK_LEAVE_SECONDS: float = 0.42
const PACK_LEAVE_STAGGER: float = 0.06
const PACK_LEAVE_SCALE: float = 0.14
const PACK_BATCH_GATHER_SECONDS: float = 0.26
const PACK_BATCH_FLIP_STAGGER: float = 0.06
const PACK_BATCH_FLIP_SHARE: float = 0.5
const PACK_REWARD_MAX_SCALE: float = 1.1
const PACK_REWARD_MIN_SCALE: float = 0.3
const PACK_REWARD_ROW_GAP: float = 12.0
const PACK_REWARD_SIDE_MARGIN: float = 36.0
const STAMP_VISUAL_SIZE: Vector2 = Vector2(168.7, 229.0)
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
const OVERLAY_STATE_SELECTION: String = "selection"
const OVERLAY_STATE_FOCUSED: String = "focused"
const OVERLAY_STATE_TEARING: String = "tearing"
const OVERLAY_STATE_OPENING: String = "opening"
const OVERLAY_STATE_REWARDS: String = "rewards"

var collection: Control
var points_label: Label
var buy_packs_panel: PanelContainer
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
var pack_notice_panel: Control
var pack_inventory: Control
var pack_preview_nodes: Array[Control] = []
var pack_inventory_arrival_tweens: Dictionary = {}
var pack_opened_callback: Callable
var pack_click_area: Control
var pack_overlay_layer: CanvasLayer
var pack_overlay: Control
var pack_dim_rect: ColorRect
var pack_layer: Control
var reward_layer: Control
var pack_fx_layer: Control
var pack_footer: Control
var pack_hint_label: Label
var pack_footer_buttons: Control
var open_all_button: Button
var pack_tear: PackTearInteraction
var pack_light: ColorRect
var book_node: Control
var opening_pack_nodes: Array[Control] = []
var revealed_stamp_nodes: Array[StampVisual] = []
var reward_stamp_flipped: Array[bool] = []
var reward_flip_hitboxes: Array[Control] = []
var reward_captions: Array[Control] = []
## The prints that came out of this opening and were not in the collection before.
var reward_new_print_ids: Dictionary = {}
## Claimed stamps the room behind the overlay does not show yet.
var unseen_rewards: Array[StampPrint] = []
var reward_flips_running: int = 0
var full_art_stage: PackFullArtStage
var reward_description_panel: PanelContainer
var reward_description_label: RichTextLabel
## The stamp under the mouse, -1 for none.
var hovered_reward_stamp: int = -1
## Changes whenever the overlay's content is thrown away, so that work spread
## over frames can tell it has been left behind.
var overlay_build_id: int = 0
var batch_opening: bool = false
## A batch turns its stamps one at a time: this is the pause between two.
var batch_flip_waiting: bool = false
var opening_tweens: Array[Tween] = []
var opening_speed: float = 1.0
var focused_pack_node: Control
var overlay_state: String = ""
var overlay_animating: bool = false
var reward_flip_in_progress: bool = false
var selected_purchase_pack_id: String = ""

func bind(nodes: Dictionary, opened_callback: Callable = Callable()) -> void:
	collection = nodes.get("collection", null) as Control
	points_label = nodes.get("points_label", null) as Label
	buy_packs_panel = nodes.get("buy_packs_panel", null) as PanelContainer
	pack_notice_panel = nodes.get("pack_notice_panel", null) as Control
	pack_inventory = nodes.get("pack_inventory", null) as Control
	book_node = nodes.get("book_node", null) as Control
	pack_opened_callback = opened_callback

	PackDefinitionLibrary.ensure_loaded()
	PlayerProgressStore.ensure_loaded()
	PlayerCollectionStore.ensure_loaded()

	# Creates the shop window, including the spin box and buttons connected below.
	_ensure_buy_packs_window()
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
	_connect_once(contents_scroll, "resized", Callable(self, "_layout_buy_pack_contents_grid"))

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

	buy_packs_confirm_button = Button.new()
	buy_packs_confirm_button.name = "BuyButton"
	purchase_row.add_child(buy_packs_confirm_button)
	buy_packs_confirm_button.text = tr("Buy")
	buy_packs_confirm_button.custom_minimum_size = Vector2(132.0, 40.0)
	buy_packs_confirm_button.focus_mode = Control.FOCUS_NONE
	buy_packs_confirm_button.set_meta("sfx_click", "buy")

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
	_connect_once(buy_packs_modal_blocker, "gui_input", Callable(self, "_on_buy_packs_modal_blocker_gui_input"))

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

func is_buy_packs_modal_open() -> bool:
	return buy_packs_panel != null and is_instance_valid(buy_packs_panel) and buy_packs_panel.visible

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
	var preview_pack_ids: Array[String] = _get_unopened_pack_ids_for_display(MAX_VISIBLE_PACK_ICONS)
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

func show_buy_packs() -> void:
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
	update_buy_packs_info()
	if buy_packs_confirm_button != null:
		buy_packs_confirm_button.disabled = max_pack_count <= 0 or selected_pack == null
	_show_buy_packs_modal_animated()

func on_pack_count_spin_value_changed(_value: float) -> void:
	update_buy_packs_info()

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
	_connect_once(cell, "mouse_entered", Callable(self, "_show_buy_pack_stamp_tooltip").bind(stamp_display_name))
	_connect_once(cell, "mouse_exited", Callable(self, "_hide_buy_pack_stamp_tooltip"))
	_connect_once(cell, "gui_input", Callable(self, "_on_buy_pack_content_stamp_gui_input"))

	var stamp_visual := STAMP_VISUAL.instantiate() as StampVisual
	cell.add_child(stamp_visual)
	stamp_visual.custom_minimum_size = STAMP_VISUAL_SIZE
	stamp_visual.size = STAMP_VISUAL_SIZE
	stamp_visual.pivot_offset = STAMP_VISUAL_SIZE * 0.5
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
	_connect_once(cell, "resized", Callable(self, "_layout_pack_contents_stamp").bind(cell, stamp_visual))
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
	var visual_size: Vector2 = STAMP_VISUAL_SIZE * stamp_scale
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

func update_buy_packs_info() -> void:
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

func confirm_buy_packs() -> void:
	var pack_count: int = int(pack_count_spin_box.value) if pack_count_spin_box != null else 0
	var selected_pack: PackDefinition = _get_selected_purchase_pack()
	if selected_pack == null:
		return
	var previous_preview_ids: Array[String] = _get_unopened_pack_ids_for_display(MAX_VISIBLE_PACK_ICONS)
	if !PlayerProgressStore.purchase_packs(pack_count, selected_pack.get_resolved_id(), selected_pack.price):
		return

	SFXManager.play("buy_packs_window_closing")
	_set_buy_packs_modal_visible(false)
	refresh_progress_ui()
	refresh_pack_inventory_ui(true, previous_preview_ids)

func cancel_buy_packs() -> void:
	SFXManager.play("buy_packs_window_closing")
	_hide_buy_packs_modal_animated()

func _get_unopened_pack_ids_for_display(max_count: int = -1) -> Array[String]:
	return PlayerProgressStore.get_unopened_pack_queue(max_count)

func open_pack() -> void:
	show_pack_opening_view()

func show_pack_opening_view() -> void:
	if PlayerProgressStore.get_unopened_pack_count() <= 0:
		return
	if is_pack_overlay_active():
		return
	_hide_pack_click_area()
	_show_pack_selection_overlay(true)

func is_pack_overlay_active() -> bool:
	return pack_overlay != null and is_instance_valid(pack_overlay)

func handle_back_pressed() -> bool:
	if !is_pack_overlay_active():
		return false
	if overlay_state == OVERLAY_STATE_TEARING:
		# A pack once started cannot be closed again: it finishes.
		if pack_tear != null and is_instance_valid(pack_tear):
			pack_tear.tear_by_itself()
		return true
	if overlay_animating:
		_speed_up_opening()
		return true

	if overlay_state == OVERLAY_STATE_REWARDS:
		_leave_rewards()
		return true

	if overlay_state == OVERLAY_STATE_FOCUSED:
		_show_pack_selection_overlay(false)
		return true

	_close_pack_overlay(true)
	return true

## Opens these packs together: the stamps are the player's from here on, with one
## save for all of them. The room behind the overlay is brought up to date when the
## overlay has done with them, in _refresh_room_behind_overlay: it takes too long
## for the moment the mouse takes hold of a pack.
func _claim_packs(pack_ids: Array[String]) -> Array[StampPrint]:
	var rewards: Array[StampPrint] = []
	for pack_id in pack_ids:
		var pack_rewards: Array[StampPrint] = _roll_pack_rewards(pack_id)
		if !pack_rewards.is_empty() and PlayerProgressStore.open_pack(pack_id, false):
			rewards.append_array(pack_rewards)
	if rewards.is_empty():
		return rewards

	PlayerProgressStore.save_progress()
	var print_ids: Array[String] = []
	for stamp_print: StampPrint in rewards:
		print_ids.append(stamp_print.print_id)
		if !PlayerCollectionStore.owns_print(stamp_print):
			reward_new_print_ids[stamp_print.print_id] = true
	PlayerCollectionStore.add_local_print_copies(print_ids)

	refresh_progress_ui()
	refresh_pack_inventory_ui()
	unseen_rewards.append_array(rewards)
	return rewards

func _refresh_room_behind_overlay() -> void:
	if unseen_rewards.is_empty():
		return
	if pack_opened_callback.is_valid():
		pack_opened_callback.call(unseen_rewards, !reward_new_print_ids.is_empty())
	unseen_rewards = []

func _ensure_pack_overlay() -> void:
	if is_pack_overlay_active():
		pack_overlay.visible = true
		return
	if collection == null or !is_instance_valid(collection):
		return

	pack_overlay_layer = CanvasLayer.new()
	pack_overlay_layer.name = "PackOpeningLayer"
	pack_overlay_layer.layer = PACK_OVERLAY_LAYER
	collection.add_child(pack_overlay_layer)

	pack_overlay = Control.new()
	pack_overlay.name = "PackOpeningOverlay"
	# A CanvasLayer cuts a control off from the theme above it.
	pack_overlay.theme = collection.theme
	pack_overlay_layer.add_child(pack_overlay)
	pack_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pack_overlay.clip_contents = false
	_sync_pack_overlay_rect()

	pack_dim_rect = ColorRect.new()
	pack_dim_rect.name = "PackOpeningDim"
	pack_overlay.add_child(pack_dim_rect)
	pack_dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	pack_dim_rect.offset_left = 0.0
	pack_dim_rect.offset_top = 0.0
	pack_dim_rect.offset_right = 0.0
	pack_dim_rect.offset_bottom = 0.0
	pack_dim_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pack_dim_rect.color = PACK_OVERLAY_DIM

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

	pack_fx_layer = Control.new()
	pack_fx_layer.name = "PackEffectsLayer"
	pack_overlay.add_child(pack_fx_layer)
	pack_fx_layer.z_index = 25
	pack_fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	pack_fx_layer.offset_left = 0.0
	pack_fx_layer.offset_top = 0.0
	pack_fx_layer.offset_right = 0.0
	pack_fx_layer.offset_bottom = 0.0
	pack_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_pack_overlay_footer()
	_connect_once(pack_overlay, "gui_input", Callable(self, "_on_pack_overlay_gui_input"))

	var viewport := collection.get_viewport()
	if viewport != null:
		_connect_once(viewport, "size_changed", Callable(self, "_on_pack_overlay_viewport_resized"))

## The line of text under the action, and the buttons of the choosing screen:
## the overlay covers the top bar and its back button.
func _build_pack_overlay_footer() -> void:
	pack_footer = VBoxContainer.new()
	pack_footer.name = "PackOverlayFooter"
	pack_overlay.add_child(pack_footer)
	pack_footer.z_index = 40
	pack_footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pack_footer.anchor_left = 0.0
	pack_footer.anchor_right = 1.0
	pack_footer.anchor_top = 1.0
	pack_footer.anchor_bottom = 1.0
	pack_footer.offset_top = -104.0
	pack_footer.offset_bottom = -18.0
	pack_footer.alignment = BoxContainer.ALIGNMENT_END
	pack_footer.add_theme_constant_override("separation", 10)

	pack_hint_label = Label.new()
	pack_hint_label.name = "PackHint"
	pack_footer.add_child(pack_hint_label)
	pack_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pack_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pack_hint_label.add_theme_color_override("font_color", Color(UiPalette.PAPER_RAISED, 0.82))

	var buttons_centre := CenterContainer.new()
	buttons_centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pack_footer.add_child(buttons_centre)
	pack_footer_buttons = buttons_centre

	var buttons_panel := PanelContainer.new()
	buttons_panel.theme_type_variation = &"ShopWindowPanel"
	buttons_centre.add_child(buttons_panel)

	var buttons_margin := MarginContainer.new()
	buttons_panel.add_child(buttons_margin)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		buttons_margin.add_theme_constant_override(side, 8)

	var buttons_row := HBoxContainer.new()
	buttons_margin.add_child(buttons_row)
	buttons_row.add_theme_constant_override("separation", 10)

	var back_button := Button.new()
	back_button.text = tr("Back")
	back_button.custom_minimum_size = Vector2(120.0, 36.0)
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.pressed.connect(Callable(self, "_on_pack_footer_back_pressed"))
	buttons_row.add_child(back_button)

	open_all_button = Button.new()
	open_all_button.text = tr("Open all")
	open_all_button.custom_minimum_size = Vector2(150.0, 36.0)
	open_all_button.focus_mode = Control.FOCUS_NONE
	open_all_button.pressed.connect(Callable(self, "_open_all_packs"))
	buttons_row.add_child(open_all_button)

func _on_pack_footer_back_pressed() -> void:
	if overlay_state == OVERLAY_STATE_SELECTION:
		_close_pack_overlay(true)

func _set_pack_hint(text: String) -> void:
	if pack_hint_label != null and is_instance_valid(pack_hint_label):
		pack_hint_label.text = text
	if pack_footer_buttons != null and is_instance_valid(pack_footer_buttons):
		pack_footer_buttons.visible = overlay_state == OVERLAY_STATE_SELECTION and !overlay_animating
	if open_all_button != null and is_instance_valid(open_all_button):
		open_all_button.visible = opening_pack_nodes.size() > 1

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
	# Clicks go by tree order, not by z_index: these stay in front of the pack layer.
	pack_fx_layer.move_to_front()
	pack_footer.move_to_front()
	pack_overlay.visible = true
	pack_overlay.modulate.a = 0.0 if animate_in else 1.0
	_sync_pack_overlay_rect()

	if animate_in:
		var fade_tween := pack_overlay.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		fade_tween.tween_property(pack_overlay, "modulate:a", 1.0, 0.16)

	var build_id: int = overlay_build_id
	var visible_pack_ids: Array[String] = _get_unopened_pack_ids_for_display(MAX_SELECTION_PACK_ICONS)
	var target_positions: Array[Vector2] = _get_selection_pack_positions(visible_pack_ids.size())
	for i in range(visible_pack_ids.size()):
		var pack_id: String = visible_pack_ids[i]
		var pack_node := _create_opening_pack_node(i, pack_id, visible_pack_ids.size())
		opening_pack_nodes.append(pack_node)
		pack_layer.add_child(pack_node)
		var target_position: Vector2 = target_positions[i]
		pack_node.set_meta("selection_position", target_position)
		if animate_in:
			pack_node.position = _get_edge_start_position(i, target_position, pack_node.size)
			pack_node.scale = Vector2.ONE * 0.86
			var tween := pack_overlay.create_tween()
			tween.tween_interval(float(i) * PACK_FLY_STAGGER_SECONDS)
			tween.tween_callback(func(): SFXManager.play("pack_whoosh"))
			tween.tween_property(pack_node, "position", target_position, PACK_FLY_IN_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween.parallel().tween_property(pack_node, "scale", Vector2.ONE, PACK_FLY_IN_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		else:
			pack_node.position = target_position
			pack_node.scale = Vector2.ONE
		# One a frame: each brings its own 3D view, and they arrive one by one anyway.
		await collection.get_tree().process_frame
		if build_id != overlay_build_id or !is_pack_overlay_active() or overlay_state != OVERLAY_STATE_SELECTION:
			return

	_set_pack_hint(tr("Choose a pack to open"))
	if animate_in:
		var gate_tween := pack_overlay.create_tween()
		gate_tween.tween_interval(PACK_FLY_IN_SECONDS + maxf(0.0, float(visible_pack_ids.size() - 1) * PACK_FLY_STAGGER_SECONDS))
		gate_tween.tween_callback(Callable(self, "_finish_pack_selection_fly_in"))
	else:
		_start_selection_pack_ambient_motion()

func _create_opening_pack_node(index: int, pack_id: String, selection_count: int = 1) -> Control:
	var pack_definition: PackDefinition = PackDefinitionLibrary.get_pack(pack_id)
	var pack_texture: Texture2D = PackDefinitionLibrary.get_pack_front_texture(pack_id, BOOSTER_PACK_TEXTURE)
	var pack_size: Vector2 = _get_selection_pack_visual_size(selection_count, pack_texture)
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

func _stop_pack_ambient_motion(pack_node: Control, reset_shader_tilt: bool = true) -> void:
	if pack_node == null or !is_instance_valid(pack_node):
		return
	if pack_node is Pack3DView:
		var pack_view := pack_node as Pack3DView
		if reset_shader_tilt:
			pack_view.set_tear_front(0.0)
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

func _focus_overlay_pack(pack_node: Control) -> void:
	if pack_node == null or !is_instance_valid(pack_node):
		return

	overlay_state = OVERLAY_STATE_FOCUSED
	overlay_animating = true
	focused_pack_node = pack_node
	var focused_position: Vector2 = _get_focused_pack_position(pack_node.size)
	_set_pack_hint("")

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
				tween.parallel().tween_method(Callable(node, "set_foil_opacity"), 0.0, PACK_FOCUSED_FOIL, PACK_FOCUS_SECONDS)
			tween.parallel().tween_property(node, "position", focused_position, PACK_FOCUS_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tween.parallel().tween_property(node, "scale", Vector2.ONE * _get_focused_pack_scale(node), PACK_FOCUS_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween.parallel().tween_property(node, "rotation", 0.0, PACK_FOCUS_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		else:
			node.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tween.tween_property(node, "modulate:a", 0.0, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
			tween.parallel().tween_property(node, "scale", Vector2.ONE * 0.72, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	var gate_tween := pack_overlay.create_tween()
	gate_tween.tween_interval(PACK_FOCUS_SECONDS)
	gate_tween.tween_callback(Callable(self, "_finish_pack_focus"))

func _finish_pack_focus() -> void:
	if !is_pack_overlay_active() or overlay_state != OVERLAY_STATE_FOCUSED:
		return
	overlay_animating = false
	_start_pack_tear()
	_release_other_packs()

## The packs not chosen are out of sight by now. Each holds a 3D view of its own:
## one a frame, so that letting them go does not catch the moment the tear starts.
func _release_other_packs() -> void:
	var build_id: int = overlay_build_id
	for node in opening_pack_nodes.duplicate():
		if node == focused_pack_node or node == null or !is_instance_valid(node):
			continue
		_stop_pack_ambient_motion(node, false)
		node.queue_free()
		opening_pack_nodes.erase(node)
		await collection.get_tree().process_frame
		if build_id != overlay_build_id or !is_pack_overlay_active():
			return

## Puts the pack on the whole screen, unchanged, and hands it to the player's mouse.
func _start_pack_tear() -> void:
	var pack_view := focused_pack_node as Pack3DView
	if pack_view == null or !is_instance_valid(pack_view):
		return

	var stage_size: Vector2 = _get_viewport_size()
	pack_view.set_tear_parameters(PACK_TEAR_CUT_Y, PACK_TEAR_WAVE_STRENGTH, randf(), PACK_TEAR_EDGE_SOFTNESS)
	pack_view.frame_on_stage(pack_view.position + pack_view.size * 0.5, pack_view.get_frame_height(), stage_size, collection.get_window().size)
	pack_view.rotation = 0.0
	pack_view.scale = Vector2.ONE
	# Lifted over the other packs while they were there; now it stays under the effects.
	pack_view.z_index = 0
	_apply_pack_control_size(pack_view, stage_size)
	pack_view.position = Vector2.ZERO
	# The cut area takes the clicks on the pack; the rest of the stage is background.
	pack_view.mouse_filter = Control.MOUSE_FILTER_IGNORE

	pack_tear = PackTearInteraction.new()
	pack_tear.name = "PackTear"
	pack_fx_layer.add_child(pack_tear)
	pack_tear.bind(pack_view, pack_view.stage_pack_area, PACK_TEAR_CUT_Y)
	pack_tear.tear_started.connect(Callable(self, "_on_pack_tear_started"))
	pack_tear.tear_finished.connect(Callable(self, "_on_pack_torn"))
	_set_pack_hint(tr("Drag along the top of the pack to tear it open"))
	# Ready before the mouse comes down, so that the tear starts without a stutter.
	_prepare_reward_stamps(PACK_REWARD_STAMP_COUNT)

## The moment the mouse takes hold of the pack it is opened: the stamps are in
## the collection and in the pack from here on, whatever the tear does.
func _on_pack_tear_started() -> void:
	overlay_state = OVERLAY_STATE_TEARING
	_set_pack_hint("")
	reward_new_print_ids.clear()
	var pack_ids: Array[String] = [str(focused_pack_node.get_meta("pack_id", ""))]
	var rewards: Array[StampPrint] = _claim_packs(pack_ids)
	_assign_reward_prints(rewards)

func _on_pack_torn(_direction: int) -> void:
	pack_tear = null
	overlay_state = OVERLAY_STATE_OPENING
	overlay_animating = true
	opening_speed = 1.0
	if revealed_stamp_nodes.is_empty():
		_show_pack_selection_overlay(true)
		return

	var pack_view := focused_pack_node as Pack3DView
	var rarity: int = _get_best_reward_rarity()
	var opening_centre: Vector2 = _get_pack_opening_line(pack_view).get_center()
	SFXManager.play("pack_tear_finish")
	pack_view.release_flap()
	PackRevealFx.burst(pack_fx_layer, opening_centre, PackRevealFx.PAPER_FLECK, 34, 300.0)
	_play_pack_kick(pack_view)
	_add_reward_auras()
	if rarity != StampPrint.Rarity.BASIC:
		_show_pack_light(pack_view, rarity)
	_raise_reward_stamps(float(PACK_BREATH_SECONDS[rarity]))

func _get_best_reward_rarity() -> int:
	var best: int = StampPrint.Rarity.BASIC
	for stamp_visual in revealed_stamp_nodes:
		best = maxi(best, _get_reward_rarity(stamp_visual))
	return best

func _get_reward_rarity(stamp_visual: StampVisual) -> int:
	return stamp_visual.stamp_print.get_rarity() if stamp_visual.stamp_print != null else StampPrint.Rarity.BASIC

## The torn edge on the overlay, from one side of the pack to the other.
func _get_pack_opening_line(pack_view: Pack3DView) -> Rect2:
	var pack_area: Rect2 = pack_view.stage_pack_area
	return Rect2(pack_area.position + Vector2(0.0, pack_area.size.y * PACK_TEAR_CUT_Y), Vector2(pack_area.size.x, 0.0))

## The pack jumps as the strain goes out of it.
func _play_pack_kick(pack_view: Pack3DView) -> void:
	var kick: float = PACK_KICK_WORLD if SettingsDataManager.is_screen_shake_enabled() else 0.0
	var tween := _opening_tween()
	tween.tween_property(pack_view, "drop_offset", Vector3(0.0, -kick, 0.0), 0.06).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(pack_view, "drop_offset", Vector3.ZERO, 0.24).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	var settle := _opening_tween()
	settle.tween_method(Callable(pack_view, "set_swell"), 1.0, 0.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

## Light out of the torn top, in the colour of the best stamp inside. A pack
## shows it only when it has something to show: it never promises in vain.
func _show_pack_light(pack_view: Pack3DView, rarity: int) -> void:
	var opening: Rect2 = _get_pack_opening_line(pack_view)
	var light_size := Vector2(opening.size.x * 3.2, opening.position.y + 120.0)
	var light_rect := Rect2(opening.get_center() - Vector2(light_size.x * 0.5, light_size.y), light_size)
	pack_light = PackRevealFx.add_rays(pack_fx_layer, light_rect, Vector2(0.5, 1.0), PackRevealFx.get_light_color(rarity))
	var tween := _opening_tween()
	tween.tween_property(pack_light.material, "shader_parameter/strength", float(PACK_LIGHT_STRENGTH[rarity]), float(PACK_BREATH_SECONDS[rarity]) * 0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	if rarity == StampPrint.Rarity.FULL_ART:
		SFXManager.play("pack_full_art_tease")
		if SettingsDataManager.is_screen_shake_enabled():
			tween.parallel().tween_property(pack_view, "shake_amount", PACK_LIGHT_SHAKE, float(PACK_BREATH_SECONDS[rarity]) * 0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	else:
		SFXManager.play("pack_foil_tease")

func _fade_pack_light() -> void:
	if pack_light == null or !is_instance_valid(pack_light):
		return
	var tween := _opening_tween()
	tween.tween_property(pack_light.material, "shader_parameter/strength", 0.0, PACK_FALL_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(Callable(pack_light, "queue_free"))
	pack_light = null

## The stamps come up out of the torn top one by one. They stand behind the
## pack's face, so its torn edge hides them until they rise over it.
func _raise_reward_stamps(start_delay: float) -> void:
	var count: int = revealed_stamp_nodes.size()
	var positions: Array[Vector2] = _get_reward_rise_positions(count)
	for i in range(count):
		var stamp_visual: StampVisual = revealed_stamp_nodes[i]
		var rise_rotation: float = deg_to_rad((float(i) - float(count - 1) * 0.5) * PACK_STAMP_RISE_DEGREES)
		var tween := _opening_tween()
		tween.tween_interval(start_delay + float(i) * PACK_STAMP_RISE_STAGGER)
		tween.tween_callback(func() -> void: SFXManager.play("field_slips"))
		tween.tween_property(stamp_visual, "position", positions[i], PACK_STAMP_RISE_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.parallel().tween_property(stamp_visual, "rotation", rise_rotation, PACK_STAMP_RISE_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	var deal_tween := _opening_tween()
	deal_tween.tween_interval(start_delay + float(count - 1) * PACK_STAMP_RISE_STAGGER + PACK_STAMP_RISE_SECONDS)
	deal_tween.tween_callback(Callable(self, "_drop_pack_and_deal"))

func _get_reward_rise_positions(count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var pack_view := focused_pack_node as Pack3DView
	var opening: Rect2 = _get_pack_opening_line(pack_view)
	var stamp_size: Vector2 = STAMP_VISUAL_SIZE * revealed_stamp_nodes[0].rest_scale
	var centre_y: float = opening.position.y + stamp_size.y * (0.5 - PACK_STAMP_RISE_SHARE)
	for i in range(count):
		var spread: float = (float(i) - float(count - 1) * 0.5) * PACK_STAMP_RISE_SPREAD
		positions.append(_get_stamp_position_for_center(Vector2(opening.get_center().x + spread, centre_y)))
	return positions

## How long after it starts to fall the pack has dropped below the stamps' feet.
func _get_pack_clear_seconds(pack_view: Pack3DView) -> float:
	var stamp_height: float = STAMP_VISUAL_SIZE.y * revealed_stamp_nodes[0].rest_scale.y
	var world_per_unit: float = Pack3DView.PACK_HEIGHT / pack_view.stage_pack_area.size.y
	var clear_world: float = stamp_height * (1.0 - PACK_STAMP_RISE_SHARE) * world_per_unit
	# The fall eases in by the cube of its time.
	return PACK_FALL_SECONDS * pow(clear_world / PACK_DROP_WORLD, 1.0 / 3.0)

## The empty pack falls away, and only when it has fallen clear do the stamps part:
## any sooner and they would show on both sides of it, as if they had lain behind it.
func _drop_pack_and_deal() -> void:
	_fade_pack_light()
	var pack_view := focused_pack_node as Pack3DView
	var deal_tween := _opening_tween()
	deal_tween.tween_interval(_get_pack_clear_seconds(pack_view))
	deal_tween.tween_callback(Callable(self, "_deal_reward_stamps"))
	var tween := _opening_tween()
	tween.tween_property(pack_view, "drop_offset", Vector3(0.0, -PACK_DROP_WORLD, 0.0), PACK_FALL_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(pack_view, "pull_yaw", randf_range(-14.0, 14.0), PACK_FALL_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(pack_view, "shake_amount", 0.0, 0.1)
	tween.tween_callback(Callable(pack_view, "queue_free"))

func _deal_reward_stamps() -> void:
	_arrange_reward_stamps(true)
	_finish_opening_after(_get_reward_spread_seconds())

func _finish_opening_after(seconds: float) -> void:
	var finish_tween := _opening_tween()
	finish_tween.tween_interval(seconds)
	finish_tween.tween_callback(Callable(self, "_finish_pack_open_animation"))

func _opening_tween() -> Tween:
	var tween := pack_overlay.create_tween()
	tween.set_speed_scale(opening_speed)
	opening_tweens.append(tween)
	return tween

func _speed_up_opening() -> void:
	if overlay_state != OVERLAY_STATE_OPENING:
		return
	opening_speed = PACK_SKIP_SPEED
	for tween in opening_tweens:
		if tween.is_valid():
			tween.set_speed_scale(opening_speed)

func _add_reward_auras() -> void:
	for stamp_visual in revealed_stamp_nodes:
		var rarity: int = _get_reward_rarity(stamp_visual)
		if rarity == StampPrint.Rarity.BASIC:
			continue
		var aura: ColorRect = PackRevealFx.add_aura(stamp_visual, rarity)
		aura.modulate.a = 0.0
		_opening_tween().tween_property(aura, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

## All the packs on the screen at once: they go together into one heap, and the
## stamps deal out onto the table and turn over by themselves, rarest last.
func _open_all_packs() -> void:
	if overlay_state != OVERLAY_STATE_SELECTION or overlay_animating or opening_pack_nodes.is_empty():
		return
	overlay_state = OVERLAY_STATE_OPENING
	overlay_animating = true
	opening_speed = 1.0
	batch_opening = true
	_set_pack_hint("")
	reward_new_print_ids.clear()

	var pack_ids: Array[String] = []
	for pack_node in opening_pack_nodes:
		pack_ids.append(str(pack_node.get_meta("pack_id", "")))
	var rewards: Array[StampPrint] = _claim_packs(pack_ids)
	var heap: Vector2 = _get_viewport_size() * 0.5
	for pack_node in opening_pack_nodes:
		_stop_pack_ambient_motion(pack_node, false)
		pack_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tween := _opening_tween()
		tween.tween_property(pack_node, "position", heap - pack_node.size * 0.5, PACK_BATCH_GATHER_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(pack_node, "scale", Vector2.ONE * 0.5, PACK_BATCH_GATHER_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	rewards.sort_custom(func(a: StampPrint, b: StampPrint) -> bool: return a.get_rarity() < b.get_rarity())

	var started_msec: int = Time.get_ticks_msec()
	await _prepare_reward_stamps(rewards.size(), rewards)
	if !is_pack_overlay_active() or overlay_state != OVERLAY_STATE_OPENING:
		return
	reward_layer.visible = false
	var gathered_seconds: float = float(Time.get_ticks_msec() - started_msec) / 1000.0
	var deal_tween := _opening_tween()
	deal_tween.tween_interval(maxf(0.0, PACK_BATCH_GATHER_SECONDS - gathered_seconds))
	deal_tween.tween_callback(Callable(self, "_deal_batch_rewards").bind(heap))

func _deal_batch_rewards(heap: Vector2) -> void:
	reward_layer.visible = true
	SFXManager.play("pack_tear_finish")
	PackRevealFx.burst(pack_fx_layer, heap, PackRevealFx.PAPER_FLECK, 60, 420.0)
	for pack_node in opening_pack_nodes:
		if pack_node != null and is_instance_valid(pack_node):
			pack_node.queue_free()
	opening_pack_nodes.clear()
	_add_reward_auras()
	_arrange_reward_stamps(true)
	_finish_opening_after(_get_reward_spread_seconds())

## Builds a face-down stack of this many stamps, a few each frame. The prints may
## come later, through _assign_reward_prints: a stamp's back shows nothing of them.
func _prepare_reward_stamps(count: int, stamp_prints: Array[StampPrint] = []) -> void:
	if reward_layer == null or !is_instance_valid(reward_layer):
		return

	_clear_reward_stamps()
	reward_layer.visible = true
	reward_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	var build_id: int = overlay_build_id
	while revealed_stamp_nodes.size() < count:
		var index: int = revealed_stamp_nodes.size()
		_add_reward_stamp(count, stamp_prints[index] if index < stamp_prints.size() else null)
		if (index + 1) % PACK_STAMPS_BUILT_PER_FRAME == 0:
			await collection.get_tree().process_frame
			if build_id != overlay_build_id or !is_pack_overlay_active():
				return

func _add_reward_stamp(stack_size: int, stamp_print: StampPrint) -> void:
	var viewport_size: Vector2 = _get_viewport_size()
	var scale_factor: float = _get_reward_stamp_scale(viewport_size, stack_size)
	var stack_center: Vector2 = viewport_size * 0.5
	var pack_view := focused_pack_node as Pack3DView
	if !batch_opening and pack_view != null and is_instance_valid(pack_view):
		var opening: Rect2 = _get_pack_opening_line(pack_view)
		stack_center = opening.get_center() + Vector2(0.0, STAMP_VISUAL_SIZE.y * scale_factor * 0.5 - PACK_STAMP_PEEK)

	var stamp_visual := STAMP_VISUAL.instantiate() as StampVisual
	reward_layer.add_child(stamp_visual)
	stamp_visual.size = STAMP_VISUAL_SIZE
	stamp_visual.custom_minimum_size = STAMP_VISUAL_SIZE
	stamp_visual.pivot_offset = STAMP_VISUAL_SIZE * 0.5
	if stamp_print != null:
		stamp_visual.set_stamp_print(stamp_print)
	stamp_visual.set_collection_owned(true)
	stamp_visual.set_face_down(true)
	stamp_visual.set_hover_raise_enabled(false)
	stamp_visual.set_rest_scale(Vector2.ONE * scale_factor)
	stamp_visual.draggable = false
	stamp_visual.disabled = true
	stamp_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# A stack by hand: no two lie quite the same.
	stamp_visual.position = _get_stamp_position_for_center(stack_center) + Vector2(randf_range(-3.0, 3.0), randf_range(-1.5, 1.5))
	stamp_visual.rotation = deg_to_rad(randf_range(-1.6, 1.6))
	stamp_visual.home_position = stamp_visual.position
	stamp_visual.z_index = revealed_stamp_nodes.size()
	PackRevealFx.add_shadow(stamp_visual)
	revealed_stamp_nodes.append(stamp_visual)
	reward_stamp_flipped.append(false)

## The prints for a stack prepared without them. The mouse may come down before the
## stack is finished, and a pack short of stamps gives fewer than the stack holds.
func _assign_reward_prints(rewards: Array[StampPrint]) -> void:
	while revealed_stamp_nodes.size() < rewards.size():
		_add_reward_stamp(rewards.size(), null)
	while revealed_stamp_nodes.size() > rewards.size():
		revealed_stamp_nodes.pop_back().queue_free()
		reward_stamp_flipped.pop_back()
	for i in range(rewards.size()):
		revealed_stamp_nodes[i].set_stamp_print(rewards[i])

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
			var tween := _opening_tween()
			tween.tween_interval(float(i) * _get_reward_spread_stagger())
			if !batch_opening:
				tween.tween_callback(func() -> void: SFXManager.play_pitched("field_slips", randf_range(0.92, 1.08), 0.0))
			tween.tween_property(stamp_visual, "position", positions[i], PACK_REWARD_SPREAD_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tween.parallel().tween_property(stamp_visual, "scale", target_scale, PACK_REWARD_SPREAD_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween.parallel().tween_property(stamp_visual, "rotation", deg_to_rad(randf_range(-2.0, 2.0)), PACK_REWARD_SPREAD_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		else:
			stamp_visual.position = positions[i]
			stamp_visual.scale = target_scale
			stamp_visual.rotation = 0.0

	_sync_reward_flip_hitboxes()
	_layout_reward_captions()
	if animated:
		var float_tween := _opening_tween()
		float_tween.tween_interval(_get_reward_spread_seconds())
		float_tween.tween_callback(Callable(self, "_enable_reward_stamp_float"))
	else:
		_enable_reward_stamp_float()

func _get_reward_spread_stagger() -> float:
	# A big deal has to stay short as a whole.
	return PACK_REWARD_SPREAD_STAGGER if revealed_stamp_nodes.size() <= PACK_REWARD_STAMP_COUNT else 0.012

func _get_reward_spread_seconds() -> float:
	return PACK_REWARD_SPREAD_SECONDS + float(revealed_stamp_nodes.size() - 1) * _get_reward_spread_stagger()

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
		hitbox.mouse_entered.connect(Callable(self, "_on_reward_stamp_mouse_entered").bind(reward_flip_hitboxes.size()))
		hitbox.mouse_exited.connect(Callable(self, "_on_reward_stamp_mouse_exited").bind(reward_flip_hitboxes.size()))
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
		# A turned stamp still knows the mouse is on it, but leaves its clicks to
		# the overlay, like the rest of the table.
		hitbox.mouse_filter = Control.MOUSE_FILTER_PASS if reward_stamp_flipped[i] else Control.MOUSE_FILTER_STOP

func _on_reward_stamp_hitbox_gui_input(event: InputEvent, stamp_index: int) -> void:
	if !(event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or !mouse_event.pressed:
		return
	if stamp_index < 0 or stamp_index >= revealed_stamp_nodes.size() or reward_stamp_flipped[stamp_index]:
		return
	var hitbox: Control = reward_flip_hitboxes[stamp_index] if stamp_index < reward_flip_hitboxes.size() else null
	if hitbox != null and is_instance_valid(hitbox):
		hitbox.accept_event()
	if overlay_animating or reward_flip_in_progress:
		_advance_full_art_stage()
		return
	_flip_reward_stamp(stamp_index)

func _on_reward_stamp_mouse_entered(stamp_index: int) -> void:
	hovered_reward_stamp = stamp_index
	_show_reward_description()

func _on_reward_stamp_mouse_exited(stamp_index: int) -> void:
	if hovered_reward_stamp == stamp_index:
		hovered_reward_stamp = -1
		_hide_reward_description()

## What the stamp under the mouse does. A stamp still lying face down keeps its secret.
func _show_reward_description() -> void:
	if hovered_reward_stamp < 0 or hovered_reward_stamp >= revealed_stamp_nodes.size():
		return
	if reward_flip_in_progress or overlay_state != OVERLAY_STATE_REWARDS or overlay_animating:
		return
	var stamp_visual: StampVisual = revealed_stamp_nodes[hovered_reward_stamp]
	if !reward_stamp_flipped[hovered_reward_stamp] or stamp_visual.face_down:
		return
	var stamp: Stamp = StampPrintLibrary.get_stamp_for_print(stamp_visual.stamp_print)
	var description: String = stamp.get_display_description().strip_edges() if stamp != null else ""
	if description.is_empty():
		return

	_ensure_reward_description()
	var font_size: int = reward_description_label.get_theme_font_size("normal_font_size")
	var text: String = DescriptionMarkup.to_bbcode(description, font_size)
	# On a big table the stamps have no captions, and are too small to read.
	reward_description_label.text = "[b]%s[/b]\n%s" % [stamp.stamp_name, text] if batch_opening else text
	reward_description_panel.visible = true
	_layout_reward_description()

func _hide_reward_description() -> void:
	if reward_description_panel != null and is_instance_valid(reward_description_panel):
		reward_description_panel.visible = false

func _ensure_reward_description() -> void:
	if reward_description_panel != null and is_instance_valid(reward_description_panel):
		return
	reward_description_panel = PanelContainer.new()
	reward_description_panel.name = "RewardDescription"
	reward_description_panel.theme_type_variation = &"ShopWindowPanel"
	reward_description_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_description_panel.custom_minimum_size = Vector2(PACK_REWARD_DESCRIPTION_WIDTH, 0.0)
	reward_description_panel.z_index = 700
	reward_layer.add_child(reward_description_panel)
	reward_description_panel.minimum_size_changed.connect(Callable(self, "_layout_reward_description"))

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_description_panel.add_child(margin)
	for side in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(side, 14)
	for side in ["margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 10)

	reward_description_label = RichTextLabel.new()
	reward_description_label.bbcode_enabled = true
	reward_description_label.fit_content = true
	reward_description_label.scroll_active = false
	reward_description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_description_label.custom_minimum_size = Vector2(PACK_REWARD_DESCRIPTION_WIDTH - 28.0, 0.0)
	reward_description_label.theme_type_variation = &"StampDescriptionText"
	margin.add_child(reward_description_label)

## Under the stamp and its caption, or over the stamp when there is no room left
## below it, as on the bottom rows of a big table.
func _layout_reward_description() -> void:
	if reward_description_panel == null or !is_instance_valid(reward_description_panel) or !reward_description_panel.visible:
		return
	if hovered_reward_stamp < 0 or hovered_reward_stamp >= revealed_stamp_nodes.size():
		return
	var stamp_visual: StampVisual = revealed_stamp_nodes[hovered_reward_stamp]
	var viewport_size: Vector2 = _get_viewport_size()
	var panel_size: Vector2 = reward_description_panel.get_combined_minimum_size()
	reward_description_panel.size = panel_size
	var centre: Vector2 = stamp_visual.home_position + STAMP_VISUAL_SIZE * 0.5
	var half_height: float = STAMP_VISUAL_SIZE.y * stamp_visual.rest_scale.y * 0.5
	var caption_height: float = 0.0 if batch_opening else PACK_REWARD_CAPTION_SIZE.y + PACK_REWARD_CAPTION_GAP
	var top: float = centre.y + half_height + caption_height + PACK_REWARD_CAPTION_GAP
	if top + panel_size.y > viewport_size.y - PACK_REWARD_DESCRIPTION_FOOTER:
		top = centre.y - half_height - PACK_REWARD_CAPTION_GAP - panel_size.y
	var margin: float = PACK_REWARD_DESCRIPTION_MARGIN
	reward_description_panel.position = Vector2(
		clampf(centre.x - panel_size.x * 0.5, margin, viewport_size.x - panel_size.x - margin),
		clampf(top, margin, viewport_size.y - panel_size.y - margin)
	)

## Turns a stamp by its rarity. Stamps can turn side by side, however fast the
## clicks come; only a full art stamp holds up the rest while it is shown.
func _flip_reward_stamp(stamp_index: int) -> void:
	if stamp_index < 0 or stamp_index >= revealed_stamp_nodes.size():
		return
	var stamp_visual: StampVisual = revealed_stamp_nodes[stamp_index]
	if stamp_visual == null or !is_instance_valid(stamp_visual) or reward_stamp_flipped[stamp_index]:
		return

	reward_stamp_flipped[stamp_index] = true
	reward_flips_running += 1
	_sync_reward_flip_hitboxes()
	stamp_visual.set_ambient_motion_enabled(false)
	stamp_visual.set_hover_raise_enabled(false)
	stamp_visual.draggable = false
	stamp_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp_visual.disabled = true
	stamp_visual.z_index = 120 + stamp_index
	match _get_reward_rarity(stamp_visual):
		StampPrint.Rarity.FULL_ART:
			_show_full_art_stamp(stamp_index)
		StampPrint.Rarity.FOIL:
			_lift_foil_stamp(stamp_index)
		_:
			_play_flip_sound()
			_turn_reward_stamp(stamp_index, Callable())

func _play_flip_sound() -> void:
	# A wave of stamps turning is one sound, not sixty.
	if !batch_opening:
		SFXManager.play("codex_fold")
	elif reward_flips_running <= 2:
		SFXManager.play_pitched("stamp_up", randf_range(0.9, 1.15), 0.0)

## A foil stamp rises off the table with a shimmer before it turns.
func _lift_foil_stamp(stamp_index: int) -> void:
	var stamp_visual: StampVisual = revealed_stamp_nodes[stamp_index]
	SFXManager.play("pack_foil_tease")
	var on_face_up := Callable(self, "_reveal_foil_stamp").bind(stamp_visual)
	if batch_opening:
		_turn_reward_stamp(stamp_index, on_face_up)
		return
	var tween := stamp_visual.create_tween()
	tween.tween_property(stamp_visual, "position:y", stamp_visual.home_position.y - PACK_REWARD_FOIL_LIFT, PACK_REWARD_FOIL_LIFT_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(Callable(self, "_turn_reward_stamp").bind(stamp_index, on_face_up))

func _reveal_foil_stamp(stamp_visual: StampVisual) -> void:
	SFXManager.play("pack_foil_reveal")
	PackRevealFx.sweep(stamp_visual, PackRevealFx.FOIL_LIGHT)
	PackRevealFx.burst(reward_layer, stamp_visual.position + STAMP_VISUAL_SIZE * 0.5, PackRevealFx.FOIL_LIGHT, 26, 260.0)
	_quiet_reward_aura(stamp_visual)

## Once it is face up a stamp needs its glow no more: it has its foil.
func _quiet_reward_aura(stamp_visual: StampVisual) -> void:
	var aura := stamp_visual.get_node_or_null("RarityAura") as CanvasItem
	if aura != null:
		stamp_visual.create_tween().tween_property(aura, "modulate:a", 0.32, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func _turn_reward_stamp(stamp_index: int, on_face_up: Callable) -> void:
	var stamp_visual: StampVisual = revealed_stamp_nodes[stamp_index]
	var seconds: float = PACK_REWARD_FLIP_SECONDS * (PACK_BATCH_FLIP_SHARE if batch_opening else 1.0)
	var target_scale: Vector2 = stamp_visual.rest_scale
	var squash_scale := Vector2(0.0, target_scale.y * 1.02)
	var tween := stamp_visual.create_tween()
	tween.tween_property(stamp_visual, "scale", squash_scale, seconds).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(Callable(self, "_turn_reward_stamp_face_up").bind(stamp_visual))
	if on_face_up.is_valid():
		tween.tween_callback(on_face_up)
	tween.tween_property(stamp_visual, "scale", target_scale, seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(stamp_visual, "position", stamp_visual.home_position, seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(stamp_visual, "rotation", deg_to_rad(randf_range(-1.6, 1.6)), seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	if !batch_opening:
		var height: float = STAMP_VISUAL_SIZE.y * target_scale.y * PACK_REWARD_HOP_HEIGHT
		tween.tween_property(stamp_visual, "position:y", stamp_visual.home_position.y - height, 0.09).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.parallel().tween_property(stamp_visual, "scale", target_scale * (1.0 + PACK_REWARD_HOP_GROW), 0.09).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(stamp_visual, "position:y", stamp_visual.home_position.y, 0.24).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(stamp_visual, "scale", target_scale, 0.24).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(Callable(self, "_finish_reward_stamp_flip").bind(stamp_index))

func _show_full_art_stamp(stamp_index: int) -> void:
	var stamp_visual: StampVisual = revealed_stamp_nodes[stamp_index]
	reward_flip_in_progress = true
	_hide_reward_description()
	stamp_visual.z_index = 300
	full_art_stage = PackFullArtStage.new()
	full_art_stage.name = "FullArtStage"
	full_art_stage.z_index = 250
	reward_layer.add_child(full_art_stage)
	full_art_stage.finished.connect(Callable(self, "_finish_full_art_stamp").bind(stamp_index))
	var turn_up := Callable(self, "_turn_reward_stamp_face_up").bind(stamp_visual)
	full_art_stage.play(stamp_visual, STAMP_VISUAL_SIZE, _get_reward_stamp_name(stamp_visual), tr("Full Art"), turn_up)

func _finish_full_art_stamp(stamp_index: int) -> void:
	full_art_stage = null
	reward_flip_in_progress = false
	revealed_stamp_nodes[stamp_index].z_index = 120 + stamp_index
	_quiet_reward_aura(revealed_stamp_nodes[stamp_index])
	_finish_reward_stamp_flip(stamp_index)

func _advance_full_art_stage() -> void:
	if full_art_stage != null and is_instance_valid(full_art_stage):
		full_art_stage.advance()

func _turn_reward_stamp_face_up(stamp_visual: StampVisual) -> void:
	if stamp_visual == null or !is_instance_valid(stamp_visual):
		return
	stamp_visual.set_face_down(false)
	stamp_visual.disabled = true
	stamp_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp_visual.scale = Vector2(0.0, stamp_visual.scale.y)

func _finish_reward_stamp_flip(stamp_index: int) -> void:
	reward_flips_running -= 1
	var stamp_visual: StampVisual = revealed_stamp_nodes[stamp_index] if stamp_index >= 0 and stamp_index < revealed_stamp_nodes.size() else null
	if stamp_visual != null and is_instance_valid(stamp_visual):
		stamp_visual.disabled = true
		stamp_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stamp_visual.position = stamp_visual.home_position
		stamp_visual.set_ambient_motion_enabled(true)
		_add_reward_caption(stamp_visual)
	# The mouse may have been waiting on this stamp all through its turn.
	if hovered_reward_stamp == stamp_index:
		_show_reward_description()
	if batch_opening:
		_flip_next_batch_stamp()
	if _are_all_reward_stamps_flipped() and reward_flips_running == 0:
		SFXManager.play("stamp_up")
		_set_pack_hint(tr("Click to continue"))

## The name under a turned stamp, and what is special about it. The stamp's own
## small lettering is for the album; here it should read at a glance.
func _add_reward_caption(stamp_visual: StampVisual) -> void:
	if batch_opening or reward_layer == null or !is_instance_valid(reward_layer):
		return
	var caption := VBoxContainer.new()
	caption.name = "RewardCaption"
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.custom_minimum_size = PACK_REWARD_CAPTION_SIZE
	caption.size = PACK_REWARD_CAPTION_SIZE
	caption.set_meta("stamp_visual", stamp_visual)
	caption.add_theme_constant_override("separation", 2)
	reward_layer.add_child(caption)
	reward_captions.append(caption)

	var name_label := Label.new()
	caption.add_child(name_label)
	name_label.text = _get_reward_stamp_name(stamp_visual)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.add_theme_color_override("font_color", UiPalette.PAPER_RAISED)

	var note: String = _get_reward_stamp_note(stamp_visual)
	if !note.is_empty():
		var note_label := Label.new()
		caption.add_child(note_label)
		note_label.text = note.to_upper()
		note_label.theme_type_variation = &"KickerLabel"
		note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var rarity: int = _get_reward_rarity(stamp_visual)
		note_label.add_theme_color_override("font_color", UiPalette.COIN if rarity == StampPrint.Rarity.BASIC else PackRevealFx.get_light_color(rarity))
	_layout_reward_captions()
	caption.modulate.a = 0.0
	caption.create_tween().tween_property(caption, "modulate:a", 1.0, 0.18)

func _layout_reward_captions() -> void:
	for caption in reward_captions:
		var stamp_visual := caption.get_meta("stamp_visual") as StampVisual
		if stamp_visual == null or !is_instance_valid(stamp_visual):
			continue
		var centre: Vector2 = stamp_visual.home_position + STAMP_VISUAL_SIZE * 0.5
		var half_height: float = STAMP_VISUAL_SIZE.y * stamp_visual.rest_scale.y * 0.5
		caption.position = Vector2(centre.x - caption.size.x * 0.5, centre.y + half_height + PACK_REWARD_CAPTION_GAP)

func _get_reward_stamp_name(stamp_visual: StampVisual) -> String:
	var stamp: Stamp = StampPrintLibrary.get_stamp_for_print(stamp_visual.stamp_print)
	return stamp.stamp_name if stamp != null else stamp_visual.stamp_print.get_display_name()

func _get_reward_stamp_note(stamp_visual: StampVisual) -> String:
	var notes: PackedStringArray = PackedStringArray()
	match _get_reward_rarity(stamp_visual):
		StampPrint.Rarity.FOIL:
			notes.append(tr("Foil"))
		StampPrint.Rarity.FULL_ART:
			notes.append(tr("Full Art"))
	if reward_new_print_ids.has(stamp_visual.stamp_print.print_id):
		notes.append(tr("New"))
	return " · ".join(notes)

## The next stamp in reading order; a batch and a click on the table both turn this one.
func _get_next_unflipped_stamp() -> int:
	return reward_stamp_flipped.find(false)

func _flip_next_batch_stamp() -> void:
	if !batch_opening or reward_flip_in_progress or overlay_state != OVERLAY_STATE_REWARDS:
		return
	var next_stamp: int = _get_next_unflipped_stamp()
	if next_stamp >= 0 and !batch_flip_waiting:
		batch_flip_waiting = true
		_flip_reward_stamp(next_stamp)
		var tween := pack_overlay.create_tween()
		tween.tween_interval(PACK_BATCH_FLIP_STAGGER)
		tween.tween_callback(func() -> void:
			batch_flip_waiting = false
			_flip_next_batch_stamp()
		)

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
	pack_overlay.accept_event()
	if full_art_stage != null and is_instance_valid(full_art_stage):
		full_art_stage.advance()
		return
	match overlay_state:
		OVERLAY_STATE_FOCUSED, OVERLAY_STATE_TEARING, OVERLAY_STATE_OPENING:
			if overlay_state != OVERLAY_STATE_FOCUSED or !overlay_animating:
				handle_back_pressed()
		OVERLAY_STATE_REWARDS:
			_on_reward_table_clicked()

## A click on the table turns the next stamp, and once all are turned it moves on.
func _on_reward_table_clicked() -> void:
	if overlay_animating or reward_flip_in_progress:
		return
	var next_stamp: int = _get_next_unflipped_stamp()
	if next_stamp >= 0:
		_flip_reward_stamp(next_stamp)
	elif reward_flips_running == 0:
		handle_back_pressed()

func _are_all_reward_stamps_flipped() -> bool:
	return !revealed_stamp_nodes.is_empty() and !reward_stamp_flipped.has(false)

## The stamps go off into the album, and the room is back.
func _leave_rewards() -> void:
	overlay_animating = true
	_set_pack_hint("")
	_hide_reward_description()
	for caption in reward_captions:
		caption.create_tween().tween_property(caption, "modulate:a", 0.0, 0.12)
	var book_centre: Vector2 = _get_book_centre()
	var stagger: float = PACK_LEAVE_STAGGER if revealed_stamp_nodes.size() <= PACK_REWARD_STAMP_COUNT else 0.01
	for i in range(revealed_stamp_nodes.size()):
		var stamp_visual: StampVisual = revealed_stamp_nodes[i]
		stamp_visual.set_ambient_motion_enabled(false)
		var tween := pack_overlay.create_tween()
		tween.tween_interval(float(i) * stagger)
		tween.tween_property(stamp_visual, "position", _get_stamp_position_for_center(book_centre), PACK_LEAVE_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(stamp_visual, "scale", Vector2.ONE * PACK_LEAVE_SCALE, PACK_LEAVE_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(stamp_visual, "rotation", deg_to_rad(randf_range(-22.0, 22.0)), PACK_LEAVE_SECONDS)
		tween.tween_callback(Callable(stamp_visual, "hide"))
		if i < PACK_REWARD_STAMP_COUNT:
			tween.tween_callback(func() -> void: SFXManager.play("stamp_glue"))

	var gate_tween := pack_overlay.create_tween()
	gate_tween.tween_interval(PACK_LEAVE_SECONDS + float(revealed_stamp_nodes.size() - 1) * stagger + 0.06)
	gate_tween.tween_callback(Callable(self, "_finish_leaving_rewards"))

func _finish_leaving_rewards() -> void:
	if !is_pack_overlay_active():
		return
	# Nothing moves at this moment, so the time it takes does not show.
	_refresh_room_behind_overlay()
	if PlayerProgressStore.get_unopened_pack_count() > 0:
		_show_pack_selection_overlay(true)
	else:
		_close_pack_overlay(true)

func _get_book_centre() -> Vector2:
	if book_node == null or !is_instance_valid(book_node):
		return _get_viewport_size() * 0.5
	return book_node.get_global_rect().get_center()

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
	if batch_opening:
		_flip_next_batch_stamp()
	else:
		_set_pack_hint(tr("Click the stamps to turn them over"))

func _finish_pack_selection_fly_in() -> void:
	if !is_pack_overlay_active() or overlay_state != OVERLAY_STATE_SELECTION:
		return
	overlay_animating = false
	_set_pack_hint(tr("Choose a pack to open"))
	_start_selection_pack_ambient_motion()

func _on_pack_overlay_viewport_resized() -> void:
	if !is_pack_overlay_active():
		return
	_sync_pack_overlay_rect()
	if overlay_state == OVERLAY_STATE_SELECTION:
		_layout_selection_packs(false)
	elif overlay_state == OVERLAY_STATE_FOCUSED:
		# The pack and its tear line are laid out for the old size: choosing again is simplest.
		_show_pack_selection_overlay(false)
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
		_apply_pack_control_size(pack_node, _get_selection_pack_visual_size(opening_pack_nodes.size(), pack_texture))
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
	var pack_size: Vector2 = _get_selection_pack_visual_size(count)
	var columns: int = _get_selection_grid_columns(count)
	var rows: int = int(ceil(float(count) / float(columns)))
	var side_margin: float = maxf(72.0, viewport_size.x * 0.07)
	var vertical_margin: float = maxf(64.0, viewport_size.y * 0.075)
	var gap_x: float = _get_selection_grid_gap_x(viewport_size)
	var gap_y: float = _get_selection_grid_gap_y(viewport_size)
	var grid_height: float = pack_size.y * float(rows) + gap_y * float(maxi(0, rows - 1))
	var max_start_y: float = maxf(vertical_margin, viewport_size.y - vertical_margin - grid_height)
	var start_y: float = clampf(viewport_size.y * 0.5 - grid_height * 0.5, vertical_margin, max_start_y)

	for row in range(rows):
		var first_index: int = row * columns
		var row_count: int = mini(columns, count - first_index)
		var row_width: float = pack_size.x * float(row_count) + gap_x * float(maxi(0, row_count - 1))
		var start_x: float = clampf(
			viewport_size.x * 0.5 - row_width * 0.5,
			side_margin,
			maxf(side_margin, viewport_size.x - side_margin - row_width)
		)
		for column in range(row_count):
			var index: int = first_index + column
			if index >= count:
				break
			positions.append(Vector2(
				start_x + float(column) * (pack_size.x + gap_x),
				start_y + float(row) * (pack_size.y + gap_y)
			))
	return positions

func _get_reward_stamp_positions(count: int, scale_factor: float) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if count <= 0:
		return positions

	var viewport_size: Vector2 = _get_viewport_size()
	var visual_size: Vector2 = STAMP_VISUAL_SIZE * scale_factor
	var columns: int = _get_reward_columns(count)
	var rows: int = int(ceil(float(count) / float(columns)))
	var gap: float = _get_reward_stamp_gap(viewport_size, columns, scale_factor)
	var grid_height: float = visual_size.y * float(rows) + PACK_REWARD_ROW_GAP * float(rows - 1)
	var min_y: float = 48.0
	var max_y: float = maxf(min_y, viewport_size.y - grid_height - 48.0)
	# A single row stands a little low, with the captions under it.
	var middle: float = 0.5 if rows > 1 else 0.46
	var top: float = clampf(viewport_size.y * middle - grid_height * 0.5, min_y, max_y)
	for i in range(count):
		var row: int = i / columns
		var row_count: int = mini(columns, count - row * columns)
		var row_width: float = visual_size.x * float(row_count) + gap * float(maxi(0, row_count - 1))
		var column: int = i - row * columns
		var center := Vector2(
			(viewport_size.x - row_width) * 0.5 + visual_size.x * 0.5 + float(column) * (visual_size.x + gap),
			top + visual_size.y * 0.5 + float(row) * (visual_size.y + PACK_REWARD_ROW_GAP)
		)
		positions.append(_get_stamp_position_for_center(center))
	return positions

## One row for a pack, and the most square table for a whole heap.
func _get_reward_columns(count: int) -> int:
	if count <= PACK_REWARD_STAMP_COUNT:
		return maxi(1, count)
	return maxi(PACK_REWARD_STAMP_COUNT, int(ceil(sqrt(float(count) * 1.8))))

func _get_stamp_position_for_center(center: Vector2) -> Vector2:
	return center - STAMP_VISUAL_SIZE * 0.5

func _get_reward_stamp_scale(viewport_size: Vector2, count: int) -> float:
	if count <= 0:
		return PACK_REWARD_MAX_SCALE
	var columns: int = _get_reward_columns(count)
	var rows: int = int(ceil(float(count) / float(columns)))
	var gap: float = clampf(viewport_size.x * 0.034, 18.0, 42.0)
	var available_width: float = maxf(120.0, viewport_size.x - PACK_REWARD_SIDE_MARGIN * 2.0)
	var width_scale: float = (available_width - gap * float(maxi(0, columns - 1))) / (STAMP_VISUAL_SIZE.x * float(columns))
	var available_height: float = viewport_size.y - 180.0 - PACK_REWARD_ROW_GAP * float(rows - 1)
	var height_scale: float = maxf(PACK_REWARD_MIN_SCALE, available_height / (STAMP_VISUAL_SIZE.y * float(rows)))
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

func _get_selection_pack_visual_size(count: int, pack_texture: Texture2D = null) -> Vector2:
	var base_size: Vector2 = _get_pack_visual_size(pack_texture)
	if count <= 0:
		return base_size

	var viewport_size: Vector2 = _get_viewport_size()
	var columns: int = _get_selection_grid_columns(count)
	var rows: int = int(ceil(float(count) / float(columns)))
	var side_margin: float = maxf(72.0, viewport_size.x * 0.07)
	var vertical_margin: float = maxf(64.0, viewport_size.y * 0.075)
	var gap_x: float = _get_selection_grid_gap_x(viewport_size)
	var gap_y: float = _get_selection_grid_gap_y(viewport_size)
	var available_width: float = maxf(base_size.x, viewport_size.x - side_margin * 2.0 - gap_x * float(maxi(0, columns - 1)))
	var available_height: float = maxf(base_size.y, viewport_size.y - vertical_margin * 2.0 - gap_y * float(maxi(0, rows - 1)))
	var width_scale: float = available_width / (base_size.x * float(columns))
	var height_scale: float = available_height / (base_size.y * float(rows))
	var fit_scale: float = clampf(minf(1.0, minf(width_scale, height_scale)), 0.58, 1.0)
	return base_size * fit_scale

func _get_selection_grid_columns(count: int) -> int:
	if count <= 1:
		return 1
	if count <= 4:
		return count
	if count <= 6:
		return 3
	if count <= 8:
		return 4
	return 5

func _get_selection_grid_gap_x(viewport_size: Vector2) -> float:
	return clampf(viewport_size.x * 0.035, 22.0, 54.0)

func _get_selection_grid_gap_y(viewport_size: Vector2) -> float:
	return clampf(viewport_size.y * 0.035, 20.0, 42.0)

func _get_pack_visual_size(pack_texture: Texture2D = null) -> Vector2:
	var viewport_size: Vector2 = _get_viewport_size()
	var texture: Texture2D = pack_texture if pack_texture != null else BOOSTER_PACK_TEXTURE
	var texture_size: Vector2 = texture.get_size()
	var aspect: float = texture_size.x / maxf(1.0, texture_size.y)
	var height: float = clampf(viewport_size.y * 0.24, 132.0, 190.0)
	return Vector2(height * aspect, height) * PACK_VISUAL_SIZE_SCALE

func _get_focused_pack_scale(pack_node: Control) -> float:
	var pack_view := pack_node as Pack3DView
	if pack_view == null:
		return 1.0
	# Whatever the size it had among the others.
	var wanted_frame_height: float = _get_viewport_size().y * PACK_FOCUSED_HEIGHT_SHARE / Pack3DView.get_pack_share()
	return wanted_frame_height / maxf(pack_view.get_frame_height() / pack_view.scale.y, 1.0)

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
	overlay_build_id += 1
	_clear_reward_stamps()
	opening_tweens.clear()
	opening_speed = 1.0
	batch_opening = false
	batch_flip_waiting = false
	pack_tear = null
	pack_light = null
	full_art_stage = null
	if pack_fx_layer != null and is_instance_valid(pack_fx_layer):
		_remove_layer_children(pack_fx_layer, false)
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
	reward_captions.clear()
	reward_flip_in_progress = false
	reward_flips_running = 0
	hovered_reward_stamp = -1
	reward_description_panel = null
	reward_description_label = null

func _close_pack_overlay(animated: bool) -> void:
	if !is_pack_overlay_active():
		return

	var overlay_to_close := pack_overlay
	var layer_to_close := pack_overlay_layer
	overlay_build_id += 1
	hovered_reward_stamp = -1
	reward_description_panel = null
	reward_description_label = null
	for node in opening_pack_nodes:
		if node != null and is_instance_valid(node):
			_stop_pack_ambient_motion(node, false)
	pack_overlay = null
	pack_overlay_layer = null
	pack_dim_rect = null
	pack_layer = null
	reward_layer = null
	pack_fx_layer = null
	pack_footer = null
	pack_hint_label = null
	pack_footer_buttons = null
	open_all_button = null
	pack_tear = null
	pack_light = null
	full_art_stage = null
	opening_tweens.clear()
	opening_speed = 1.0
	batch_opening = false
	batch_flip_waiting = false
	opening_pack_nodes.clear()
	revealed_stamp_nodes.clear()
	reward_stamp_flipped.clear()
	reward_flip_hitboxes.clear()
	reward_captions.clear()
	focused_pack_node = null
	overlay_state = ""
	overlay_animating = false
	reward_flip_in_progress = false
	reward_flips_running = 0

	if animated and is_instance_valid(overlay_to_close):
		overlay_to_close.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tween := overlay_to_close.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(overlay_to_close, "modulate:a", 0.0, 0.16)
		tween.tween_callback(Callable(layer_to_close, "queue_free"))
	elif is_instance_valid(layer_to_close):
		layer_to_close.queue_free()
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
	if is_pack_overlay_active():
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

## Rarest last, so the row builds to its best stamp from left to right.
func _roll_pack_rewards(pack_id: String) -> Array[StampPrint]:
	var pack_definition: PackDefinition = PackDefinitionLibrary.get_pack(pack_id)
	var rewards: Array[StampPrint] = PackDefinitionLibrary.roll_rewards(pack_definition, PACK_REWARD_STAMP_COUNT)
	rewards.sort_custom(func(a: StampPrint, b: StampPrint) -> bool: return a.get_rarity() < b.get_rarity())
	return rewards
