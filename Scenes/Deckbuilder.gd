extends Control

const CARD_VISUAL = preload("res://Scenes/CardVisual.tscn")
const PACK_CONTROLLER_SCRIPT = preload("res://Scenes/DeckbuilderPackController.gd")
const MAIN_MENU_SCENE = "res://Scenes/MainMenu.tscn"
const CARD_VISUAL_SIZE: Vector2 = Vector2(164, 229)
const TOP_BAR_HEIGHT: int = 60
const LAYOUT_WIDTH: int = 1128
const LEFT_COLUMN_WIDTH: int = 260
const MIDDLE_COLUMN_WIDTH: int = 520
const RIGHT_COLUMN_WIDTH: int = 320
const LEFT_INFO_HEIGHT: int = 420
const LEFT_PACK_HEIGHT: int = 170
const DESKTOP_CARDS_PER_PAGE: int = 9
const DESKTOP_CARD_COLUMNS: int = 3
const DESKTOP_CARD_SLOT_SIZE: Vector2 = Vector2(128, 142)
const MEDIUM_CARDS_PER_PAGE: int = 6
const MEDIUM_CARD_COLUMNS: int = 3
const MEDIUM_CARD_SLOT_SIZE: Vector2 = Vector2(118, 140)
const COMPACT_CARDS_PER_PAGE: int = 4
const COMPACT_CARD_COLUMNS: int = 2
const COMPACT_CARD_SLOT_SIZE: Vector2 = Vector2(120, 168)
const DECK_EDIT_CARD_SLOT_SIZE: Vector2 = Vector2(108, 151)
const MAX_DECK_SIZE: int = 15
const MAX_COPIES_PER_CARD: int = PlayerDeckStore.MAX_COPIES_PER_CARD
const REMOVE_BUTTON_VISIBLE_SECONDS: float = 1.0
const CARD_DESCRIPTION_HEIGHT: int = 76

var all_card_prints: Array = []
var filtered_card_prints: Array = []
var current_page: int = 0
var is_creating_deck: bool = false
var editing_deck_id: String = ""
var selected_deck_cards: Array = []
var dragged_print_id: String = ""
var hovered_deck_card_index: int = -1
var hovered_browser_card_name: String = ""
var editing_deck_has_missing_cards: bool = false
var current_cards_per_page: int = DESKTOP_CARDS_PER_PAGE
var current_card_columns: int = DESKTOP_CARD_COLUMNS
var current_card_slot_size: Vector2 = DESKTOP_CARD_SLOT_SIZE

var root_margin: MarginContainer
var main_center: HBoxContainer
var main_layout: HBoxContainer
var left_column: VBoxContainer
var middle_column: VBoxContainer
var right_column: VBoxContainer
var browser: VBoxContainer
var deck_panel_frame: PanelContainer
var card_grid: GridContainer
var search_field: LineEdit
var owned_only_check: CheckBox
var previous_button: Button
var next_button: Button
var page_label: Label
var new_deck_button: Button
var deck_editor_back_button: Button
var deck_name_edit: LineEdit
var deck_list_scroll: ScrollContainer
var deck_list: VBoxContainer
var deck_card_scroll: ScrollContainer
var deck_card_list: VBoxContainer
var deck_count_label: Label
var done_button: Button
var remove_card_button: Button
var remove_card_timer: Timer
var card_description_panel: PanelContainer
var card_description_label: Label
var preview_card_holder: Control
var preview_card_visual: CardVisual
var top_bar: HBoxContainer
var buy_packs_button: Button
var points_label: Label
var buy_packs_panel: PanelContainer
var pack_count_spin_box: SpinBox
var buy_packs_info_label: Label
var buy_packs_confirm_button: Button
var pack_inventory: Control
var pack_inventory_label: Label
var pack_result_dialog: AcceptDialog
var pack_result_label: Label
var pack_controller: DeckbuilderPackController

func _ready() -> void:
	randomize()
	_bind_scene_ui()
	_setup_pack_controller()
	_connect_viewport_resize()
	_apply_responsive_layout(false)
	_load_cards()
	_populate_saved_decks_list()
	_show_page(0)

func _process(_delta: float) -> void:
	_update_browser_card_description_hover()

func _connect_viewport_resize() -> void:
	var resize_callable := Callable(self, "_on_viewport_size_changed")
	if !get_viewport().size_changed.is_connected(resize_callable):
		get_viewport().size_changed.connect(_on_viewport_size_changed)

func _connect_once(signal_value: Signal, callable: Callable) -> void:
	if !signal_value.is_connected(callable):
		signal_value.connect(callable)

func _setup_pack_controller() -> void:
	pack_controller = PACK_CONTROLLER_SCRIPT.new()
	var buy_packs_cancel_button := get_node_or_null("BuyPacksPanel/BuyPacksRoot/ButtonRow/CancelButton") as Button
	pack_controller.bind({
		"buy_packs_button": buy_packs_button,
		"points_label": points_label,
		"buy_packs_panel": buy_packs_panel,
		"pack_count_spin_box": pack_count_spin_box,
		"buy_packs_info_label": buy_packs_info_label,
		"buy_packs_confirm_button": buy_packs_confirm_button,
		"buy_packs_cancel_button": buy_packs_cancel_button,
		"pack_inventory": pack_inventory,
		"pack_inventory_label": pack_inventory_label,
		"pack_result_dialog": pack_result_dialog,
		"pack_result_label": pack_result_label,
	}, Callable(self, "_on_pack_opened"))

func _bind_scene_ui() -> void:
	root_margin = $RootMargin
	main_center = $RootMargin/MainCenter
	main_layout = $RootMargin/MainCenter/MainLayout
	left_column = $RootMargin/MainCenter/MainLayout/LeftColumn
	middle_column = $RootMargin/MainCenter/MainLayout/MiddleColumn
	deck_panel_frame = $RootMargin/MainCenter/MainLayout/DeckPanelFrame
	right_column = $RootMargin/MainCenter/MainLayout/DeckPanelFrame/RightColumn
	card_description_panel = $RootMargin/MainCenter/MainLayout/LeftColumn/CardDescriptionPanel
	preview_card_holder = $RootMargin/MainCenter/MainLayout/LeftColumn/CardDescriptionPanel/InfoRoot/PreviewCardHolder
	card_description_label = $RootMargin/MainCenter/MainLayout/LeftColumn/CardDescriptionPanel/InfoRoot/CardDescriptionLabel
	browser = $RootMargin/MainCenter/MainLayout/MiddleColumn/BrowserFrame/Browser
	card_grid = $RootMargin/MainCenter/MainLayout/MiddleColumn/BrowserFrame/Browser/CardGrid
	owned_only_check = $RootMargin/MainCenter/MainLayout/MiddleColumn/BrowserFrame/Browser/BrowserTools/OwnedOnlyCheck
	search_field = $RootMargin/MainCenter/MainLayout/MiddleColumn/BrowserFrame/Browser/BrowserTools/SearchField
	previous_button = $RootMargin/MainCenter/MainLayout/MiddleColumn/BrowserFrame/Browser/Pager/PreviousButton
	page_label = $RootMargin/MainCenter/MainLayout/MiddleColumn/BrowserFrame/Browser/Pager/PageLabel
	next_button = $RootMargin/MainCenter/MainLayout/MiddleColumn/BrowserFrame/Browser/Pager/NextButton
	new_deck_button = $RootMargin/MainCenter/MainLayout/DeckPanelFrame/RightColumn/NewDeckButton
	deck_editor_back_button = $RootMargin/MainCenter/MainLayout/DeckPanelFrame/RightColumn/DeckFooter/DeckEditorBackButton
	deck_name_edit = $RootMargin/MainCenter/MainLayout/DeckPanelFrame/RightColumn/DeckNameEdit
	deck_list_scroll = $RootMargin/MainCenter/MainLayout/DeckPanelFrame/RightColumn/DeckListScroll
	deck_list = $RootMargin/MainCenter/MainLayout/DeckPanelFrame/RightColumn/DeckListScroll/DeckList
	deck_card_scroll = $RootMargin/MainCenter/MainLayout/DeckPanelFrame/RightColumn/DeckCardScroll
	deck_card_list = $RootMargin/MainCenter/MainLayout/DeckPanelFrame/RightColumn/DeckCardScroll/DeckCardList
	deck_count_label = $RootMargin/MainCenter/MainLayout/DeckPanelFrame/RightColumn/DeckFooter/DeckCountLabel
	done_button = $RootMargin/MainCenter/MainLayout/DeckPanelFrame/RightColumn/DeckFooter/DoneButton
	top_bar = $TopBar
	buy_packs_button = $TopBar/BuyPacksButton
	points_label = $TopBar/PointsContainer/PointsLabel
	pack_inventory = $RootMargin/MainCenter/MainLayout/LeftColumn/PackPanel/PackRoot/PackInventory
	pack_inventory_label = $RootMargin/MainCenter/MainLayout/LeftColumn/PackPanel/PackRoot/PackInventoryLabel
	buy_packs_panel = $BuyPacksPanel
	pack_count_spin_box = $BuyPacksPanel/BuyPacksRoot/PackCountSpinBox
	buy_packs_info_label = $BuyPacksPanel/BuyPacksRoot/BuyPacksInfoLabel
	buy_packs_confirm_button = $BuyPacksPanel/BuyPacksRoot/ButtonRow/BuyButton
	pack_result_dialog = $PackResultDialog
	pack_result_label = $PackResultDialog/PackResultLabel
	remove_card_button = $RemoveCardButton
	remove_card_timer = $RemoveCardTimer

	var preview_placeholder := preview_card_holder.get_node_or_null("PreviewPlaceholder")
	if preview_placeholder != null:
		preview_placeholder.visible = false
	preview_card_visual = CARD_VISUAL.instantiate() as CardVisual
	preview_card_holder.add_child(preview_card_visual)
	preview_card_visual.custom_minimum_size = CARD_VISUAL_SIZE
	preview_card_visual.size = CARD_VISUAL_SIZE
	preview_card_visual.set_hover_raise_enabled(false)
	preview_card_visual.draggable = false
	preview_card_visual.disabled = true
	preview_card_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_card_visual.visible = false

	_connect_once($TopBar/BackButton.pressed, Callable(self, "_on_back_pressed"))
	_connect_once(owned_only_check.toggled, Callable(self, "_on_owned_only_toggled"))
	_connect_once(search_field.text_changed, Callable(self, "_on_search_text_changed"))
	_connect_once(previous_button.pressed, Callable(self, "_on_previous_pressed"))
	_connect_once(next_button.pressed, Callable(self, "_on_next_pressed"))
	_connect_once(new_deck_button.pressed, Callable(self, "_on_new_deck_pressed"))
	_connect_once(deck_editor_back_button.pressed, Callable(self, "_on_deck_editor_back_pressed"))
	_connect_once(deck_name_edit.text_changed, Callable(self, "_on_deck_name_changed"))
	_connect_once(done_button.pressed, Callable(self, "_on_done_pressed"))
	_connect_once(remove_card_button.pressed, Callable(self, "_on_remove_card_pressed"))
	_connect_once(remove_card_timer.timeout, Callable(self, "_hide_remove_card_button"))
	_connect_once(preview_card_holder.resized, Callable(self, "_layout_preview_card"))

	buy_packs_panel.visible = false
	deck_card_scroll.visible = false
	deck_name_edit.visible = false
	deck_editor_back_button.visible = false
	deck_count_label.visible = false
	done_button.visible = false
	remove_card_button.visible = false
	$TopBackground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$TopBackground.move_to_front()
	top_bar.move_to_front()

func _build_ui() -> void:
	create_top_progress_ui()

	root_margin = MarginContainer.new()
	add_child(root_margin)
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 0)
	root_margin.add_theme_constant_override("margin_top", TOP_BAR_HEIGHT + 28)
	root_margin.add_theme_constant_override("margin_right", 0)
	root_margin.add_theme_constant_override("margin_bottom", 24)

	main_center = HBoxContainer.new()
	root_margin.add_child(main_center)
	main_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_center.add_theme_constant_override("separation", 0)

	var left_layout_spacer := Control.new()
	main_center.add_child(left_layout_spacer)
	left_layout_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	main_layout = HBoxContainer.new()
	main_center.add_child(main_layout)
	main_layout.custom_minimum_size = Vector2(LAYOUT_WIDTH, 0)
	main_layout.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_layout.add_theme_constant_override("separation", 14)

	var right_layout_spacer := Control.new()
	main_center.add_child(right_layout_spacer)
	right_layout_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	left_column = VBoxContainer.new()
	main_layout.add_child(left_column)
	left_column.custom_minimum_size = Vector2(LEFT_COLUMN_WIDTH, 0)
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.add_theme_constant_override("separation", 18)

	card_description_panel = PanelContainer.new()
	left_column.add_child(card_description_panel)
	card_description_panel.custom_minimum_size = Vector2(LEFT_COLUMN_WIDTH, LEFT_INFO_HEIGHT)
	card_description_panel.add_theme_stylebox_override("panel", _create_panel_style(Color(0.93, 0.93, 0.9), Color(0.1, 0.1, 0.1, 0.65), 0, 10))

	var info_root := VBoxContainer.new()
	card_description_panel.add_child(info_root)
	info_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_root.add_theme_constant_override("separation", 10)

	var info_title := Label.new()
	info_root.add_child(info_title)
	info_title.text = "Card Info"
	info_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_title.add_theme_font_size_override("font_size", 20)
	info_title.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))

	preview_card_holder = Control.new()
	info_root.add_child(preview_card_holder)
	preview_card_holder.custom_minimum_size = Vector2(0, 260)
	preview_card_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_card_holder.clip_contents = false

	if Engine.is_editor_hint():
		preview_card_holder.add_child(_create_editor_card_placeholder("Hovered Card"))
	else:
		preview_card_visual = CARD_VISUAL.instantiate() as CardVisual
		preview_card_holder.add_child(preview_card_visual)
		preview_card_visual.custom_minimum_size = CARD_VISUAL_SIZE
		preview_card_visual.size = CARD_VISUAL_SIZE
		preview_card_visual.set_hover_raise_enabled(false)
		preview_card_visual.draggable = false
		preview_card_visual.disabled = true
		preview_card_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_card_visual.visible = false
		preview_card_holder.resized.connect(_layout_preview_card)

	card_description_label = Label.new()
	info_root.add_child(card_description_label)
	card_description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_description_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	card_description_label.add_theme_font_size_override("font_size", 16)
	card_description_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))

	create_pack_inventory_ui()

	middle_column = VBoxContainer.new()
	main_layout.add_child(middle_column)
	middle_column.custom_minimum_size = Vector2(MIDDLE_COLUMN_WIDTH, 0)
	middle_column.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var browser_frame := PanelContainer.new()
	middle_column.add_child(browser_frame)
	browser_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	browser_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	browser_frame.add_theme_stylebox_override("panel", _create_panel_style(Color(0.93, 0.93, 0.9), Color(0.1, 0.1, 0.1, 0.65), 0, 10))

	browser = VBoxContainer.new()
	browser_frame.add_child(browser)
	browser.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	browser.size_flags_vertical = Control.SIZE_EXPAND_FILL
	browser.add_theme_constant_override("separation", 8)

	var browser_title := Label.new()
	browser.add_child(browser_title)
	browser_title.text = "Inventory"
	browser_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	browser_title.add_theme_font_size_override("font_size", 20)
	browser_title.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))

	var browser_tools := HBoxContainer.new()
	browser.add_child(browser_tools)
	browser_tools.custom_minimum_size = Vector2(0, 42)
	browser_tools.add_theme_constant_override("separation", 10)

	owned_only_check = CheckBox.new()
	browser_tools.add_child(owned_only_check)
	owned_only_check.text = "My collection"
	owned_only_check.button_pressed = false
	owned_only_check.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))
	owned_only_check.toggled.connect(_on_owned_only_toggled)

	var tool_spacer := Control.new()
	browser_tools.add_child(tool_spacer)
	tool_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	search_field = LineEdit.new()
	browser_tools.add_child(search_field)
	search_field.placeholder_text = "Search"
	search_field.custom_minimum_size = Vector2(150, 34)
	search_field.text_changed.connect(_on_search_text_changed)

	card_grid = GridContainer.new()
	browser.add_child(card_grid)
	card_grid.columns = current_card_columns
	card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_grid.add_theme_constant_override("h_separation", 20)
	card_grid.add_theme_constant_override("v_separation", 8)

	var pager := HBoxContainer.new()
	browser.add_child(pager)
	pager.alignment = BoxContainer.ALIGNMENT_CENTER
	pager.add_theme_constant_override("separation", 16)

	previous_button = Button.new()
	pager.add_child(previous_button)
	previous_button.custom_minimum_size = Vector2(54, 42)
	previous_button.text = "<"
	previous_button.pressed.connect(_on_previous_pressed)

	page_label = Label.new()
	pager.add_child(page_label)
	page_label.custom_minimum_size = Vector2(92, 42)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	next_button = Button.new()
	pager.add_child(next_button)
	next_button.custom_minimum_size = Vector2(54, 42)
	next_button.text = ">"
	next_button.pressed.connect(_on_next_pressed)

	deck_panel_frame = PanelContainer.new()
	main_layout.add_child(deck_panel_frame)
	deck_panel_frame.custom_minimum_size = Vector2(RIGHT_COLUMN_WIDTH, 0)
	deck_panel_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_panel_frame.add_theme_stylebox_override("panel", _create_panel_style(Color(0.93, 0.93, 0.9), Color(0.1, 0.1, 0.1, 0.65), 0, 10))

	right_column = VBoxContainer.new()
	deck_panel_frame.add_child(right_column)
	right_column.custom_minimum_size = Vector2(RIGHT_COLUMN_WIDTH, 0)
	right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.add_theme_constant_override("separation", 12)

	var deck_title := Label.new()
	right_column.add_child(deck_title)
	deck_title.text = "My decks"
	deck_title.add_theme_font_size_override("font_size", 22)
	deck_title.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))
	deck_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	new_deck_button = Button.new()
	right_column.add_child(new_deck_button)
	new_deck_button.text = "New deck"
	new_deck_button.custom_minimum_size = Vector2(0, 42)
	new_deck_button.pressed.connect(_on_new_deck_pressed)

	deck_editor_back_button = Button.new()
	right_column.add_child(deck_editor_back_button)
	deck_editor_back_button.text = "Cancel"
	deck_editor_back_button.custom_minimum_size = Vector2(0, 42)
	deck_editor_back_button.visible = false
	deck_editor_back_button.pressed.connect(_on_deck_editor_back_pressed)

	deck_name_edit = LineEdit.new()
	right_column.add_child(deck_name_edit)
	deck_name_edit.placeholder_text = "Deck name"
	deck_name_edit.custom_minimum_size = Vector2(0, 40)
	deck_name_edit.visible = false
	deck_name_edit.text_changed.connect(_on_deck_name_changed)

	deck_list_scroll = ScrollContainer.new()
	right_column.add_child(deck_list_scroll)
	deck_list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	deck_list = VBoxContainer.new()
	deck_list_scroll.add_child(deck_list)
	deck_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_list.add_theme_constant_override("separation", 8)

	deck_card_scroll = ScrollContainer.new()
	right_column.add_child(deck_card_scroll)
	deck_card_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_card_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	deck_card_scroll.visible = false

	deck_card_list = VBoxContainer.new()
	deck_card_scroll.add_child(deck_card_list)
	deck_card_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_card_list.add_theme_constant_override("separation", 12)

	var deck_panel_spacer := Control.new()
	right_column.add_child(deck_panel_spacer)
	deck_panel_spacer.custom_minimum_size = Vector2(0, 4)

	var deck_footer := HBoxContainer.new()
	right_column.add_child(deck_footer)
	deck_footer.alignment = BoxContainer.ALIGNMENT_END
	deck_footer.add_theme_constant_override("separation", 10)

	deck_count_label = Label.new()
	deck_footer.add_child(deck_count_label)
	deck_count_label.custom_minimum_size = Vector2(64, 42)
	deck_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	deck_count_label.text = "0/%d" % MAX_DECK_SIZE
	deck_count_label.visible = false

	done_button = Button.new()
	deck_footer.add_child(done_button)
	done_button.text = "Done"
	done_button.custom_minimum_size = Vector2(78, 42)
	done_button.visible = false
	done_button.pressed.connect(_on_done_pressed)

	if deck_editor_back_button.get_parent() != null:
		deck_editor_back_button.get_parent().remove_child(deck_editor_back_button)
	deck_footer.add_child(deck_editor_back_button)

	create_buy_packs_dialog()
	create_pack_result_dialog()

	remove_card_button = Button.new()
	add_child(remove_card_button)
	remove_card_button.text = "X"
	remove_card_button.tooltip_text = "Remove card"
	remove_card_button.custom_minimum_size = Vector2(30, 30)
	remove_card_button.size = Vector2(30, 30)
	remove_card_button.visible = false
	remove_card_button.z_index = 20
	remove_card_button.pressed.connect(_on_remove_card_pressed)

	remove_card_timer = Timer.new()
	add_child(remove_card_timer)
	remove_card_timer.one_shot = true
	remove_card_timer.wait_time = REMOVE_BUTTON_VISIBLE_SECONDS
	remove_card_timer.timeout.connect(_hide_remove_card_button)

	if Engine.is_editor_hint():
		_populate_editor_preview_content()
	else:
		_populate_saved_decks_list()
		_refresh_progress_ui()
		_refresh_pack_inventory_ui()
	if top_bar != null:
		top_bar.move_to_front()

func _create_panel_style(bg_color: Color, border_color: Color, radius_top: int, radius_bottom: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = radius_top
	style.corner_radius_top_right = radius_top
	style.corner_radius_bottom_left = radius_bottom
	style.corner_radius_bottom_right = radius_bottom
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	return style

func _create_dark_panel_style(radius_top: int, radius_bottom: int) -> StyleBoxFlat:
	return _create_panel_style(Color(0.035, 0.035, 0.04, 0.95), Color(1.0, 1.0, 1.0, 0.18), radius_top, radius_bottom)

func _create_editor_card_placeholder(label_text: String) -> Control:
	var card_panel := PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(112, 156)
	card_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.98, 0.96, 1.0)
	style.border_color = Color(0.08, 0.08, 0.08, 0.85)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	card_panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	card_panel.add_child(label)
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))
	return card_panel

func _populate_editor_preview_content() -> void:
	_refresh_progress_ui()
	if card_description_label != null:
		card_description_label.text = "Card descriptions appear here when the mouse is over a card."
	if pack_controller != null:
		pack_controller.populate_editor_pack_preview()
	_populate_editor_card_grid_preview()
	_populate_editor_deck_preview()
	if page_label != null:
		page_label.text = "1 / 3"
	if previous_button != null:
		previous_button.disabled = true
	if next_button != null:
		next_button.disabled = false
	_update_deck_editor_state()

func _populate_editor_card_grid_preview() -> void:
	if card_grid == null:
		return
	for child in card_grid.get_children():
		card_grid.remove_child(child)
		child.queue_free()
	for i in range(DESKTOP_CARDS_PER_PAGE):
		var slot := Control.new()
		card_grid.add_child(slot)
		slot.custom_minimum_size = current_card_slot_size
		var placeholder := _create_editor_card_placeholder("Card")
		slot.add_child(placeholder)
		placeholder.position = (current_card_slot_size - placeholder.custom_minimum_size) * 0.5

func _populate_editor_deck_preview() -> void:
	if deck_list == null:
		return
	for child in deck_list.get_children():
		deck_list.remove_child(child)
		child.queue_free()
	for i in range(2):
		deck_list.add_child(_create_editor_deck_row("Deck %d" % (i + 1)))

func _create_editor_deck_row(deck_name: String) -> Control:
	var row_frame := Control.new()
	row_frame.custom_minimum_size = Vector2(0, 148)
	row_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_frame.clip_contents = false

	var preview_offsets: Array = [Vector2(76, -2), Vector2(126, -6), Vector2(176, -2)]
	var preview_rotations: Array = [-8.0, 8.0, -4.0]
	for i in range(3):
		var preview_card := _create_editor_card_placeholder("Card")
		row_frame.add_child(preview_card)
		preview_card.custom_minimum_size = Vector2(60, 78)
		preview_card.size = Vector2(60, 78)
		preview_card.position = preview_offsets[i]
		preview_card.rotation = deg_to_rad(preview_rotations[i])

	var front_panel := PanelContainer.new()
	row_frame.add_child(front_panel)
	front_panel.anchor_left = 0.0
	front_panel.anchor_top = 0.0
	front_panel.anchor_right = 1.0
	front_panel.anchor_bottom = 1.0
	front_panel.offset_top = 64.0
	front_panel.add_theme_stylebox_override("panel", _create_dark_panel_style(0, 20))

	var content := VBoxContainer.new()
	front_panel.add_child(content)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	content.add_child(name_label)
	name_label.text = deck_name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.9))

	var footer := HBoxContainer.new()
	content.add_child(footer)
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 8)

	var count_label := Label.new()
	footer.add_child(count_label)
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count_label.text = "15/15"
	count_label.add_theme_font_size_override("font_size", 18)
	count_label.add_theme_color_override("font_color", Color(0.86, 0.86, 0.82))

	footer.add_child(_create_circle_icon_button("E", "Edit deck"))
	footer.add_child(_create_circle_icon_button("X", "Delete deck"))
	return row_frame

func create_top_progress_ui() -> void:
	var top_background := ColorRect.new()
	add_child(top_background)
	top_background.anchor_left = 0.0
	top_background.anchor_right = 1.0
	top_background.anchor_top = 0.0
	top_background.anchor_bottom = 0.0
	top_background.offset_left = 0.0
	top_background.offset_top = 0.0
	top_background.offset_right = 0.0
	top_background.offset_bottom = TOP_BAR_HEIGHT
	top_background.color = Color(0.36, 0.32, 0.32, 1.0)

	top_bar = HBoxContainer.new()
	add_child(top_bar)
	top_bar.anchor_left = 0.0
	top_bar.anchor_right = 1.0
	top_bar.anchor_top = 0.0
	top_bar.anchor_bottom = 0.0
	top_bar.offset_left = 24.0
	top_bar.offset_right = -24.0
	top_bar.offset_top = 10.0
	top_bar.offset_bottom = TOP_BAR_HEIGHT - 8.0
	top_bar.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_bar.add_theme_constant_override("separation", 12)

	var back_button := Button.new()
	top_bar.add_child(back_button)
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(112, 40)
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.pressed.connect(_on_back_pressed)

	var top_spacer := Control.new()
	top_bar.add_child(top_spacer)
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	buy_packs_button = Button.new()
	top_bar.add_child(buy_packs_button)
	buy_packs_button.text = "Buy Packs"
	buy_packs_button.custom_minimum_size = Vector2(124, 38)
	buy_packs_button.focus_mode = Control.FOCUS_NONE
	buy_packs_button.pressed.connect(_on_buy_packs_pressed)

	var points_container := HBoxContainer.new()
	top_bar.add_child(points_container)
	points_container.custom_minimum_size = Vector2(116, 38)
	points_container.alignment = BoxContainer.ALIGNMENT_END
	points_container.add_theme_constant_override("separation", 8)

	var point_icon := PanelContainer.new()
	points_container.add_child(point_icon)
	point_icon.custom_minimum_size = Vector2(18, 18)
	point_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = Color(1.0, 0.82, 0.12)
	icon_style.border_color = Color(0.58, 0.42, 0.02)
	icon_style.border_width_left = 1
	icon_style.border_width_top = 1
	icon_style.border_width_right = 1
	icon_style.border_width_bottom = 1
	icon_style.corner_radius_top_left = 9
	icon_style.corner_radius_top_right = 9
	icon_style.corner_radius_bottom_left = 9
	icon_style.corner_radius_bottom_right = 9
	point_icon.add_theme_stylebox_override("panel", icon_style)

	points_label = Label.new()
	points_container.add_child(points_label)
	points_label.custom_minimum_size = Vector2(78, 32)
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	points_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_label.add_theme_font_size_override("font_size", 20)
	points_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82))

func create_pack_inventory_ui() -> void:
	if left_column == null:
		return

	var pack_panel := PanelContainer.new()
	left_column.add_child(pack_panel)
	pack_panel.custom_minimum_size = Vector2(LEFT_COLUMN_WIDTH, LEFT_PACK_HEIGHT)
	pack_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pack_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pack_panel.add_theme_stylebox_override("panel", _create_panel_style(Color(0.93, 0.93, 0.9), Color(0.1, 0.1, 0.1, 0.65), 0, 10))

	var pack_root := VBoxContainer.new()
	pack_panel.add_child(pack_root)
	pack_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pack_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pack_root.add_theme_constant_override("separation", 8)

	var pack_title := Label.new()
	pack_root.add_child(pack_title)
	pack_title.text = "Packs"
	pack_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pack_title.add_theme_font_size_override("font_size", 20)
	pack_title.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))

	pack_inventory_label = Label.new()
	pack_root.add_child(pack_inventory_label)
	pack_inventory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pack_inventory_label.add_theme_font_size_override("font_size", 14)
	pack_inventory_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))

	pack_inventory = Control.new()
	pack_root.add_child(pack_inventory)
	pack_inventory.custom_minimum_size = Vector2(0, 116)
	pack_inventory.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pack_inventory.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pack_inventory.clip_contents = false
	pack_inventory.resized.connect(_refresh_pack_inventory_ui)

func create_buy_packs_dialog() -> void:
	buy_packs_panel = PanelContainer.new()
	add_child(buy_packs_panel)
	buy_packs_panel.visible = false
	buy_packs_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	buy_packs_panel.z_index = 100
	buy_packs_panel.anchor_left = 1.0
	buy_packs_panel.anchor_right = 1.0
	buy_packs_panel.anchor_top = 0.0
	buy_packs_panel.anchor_bottom = 0.0
	buy_packs_panel.offset_left = -344.0
	buy_packs_panel.offset_right = -24.0
	buy_packs_panel.offset_top = 64.0
	buy_packs_panel.offset_bottom = 206.0

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.055, 0.065, 0.96)
	panel_style.border_color = Color(1.0, 1.0, 1.0, 0.18)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.content_margin_left = 12
	panel_style.content_margin_top = 10
	panel_style.content_margin_right = 12
	panel_style.content_margin_bottom = 10
	buy_packs_panel.add_theme_stylebox_override("panel", panel_style)

	var root := VBoxContainer.new()
	buy_packs_panel.add_child(root)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 6)

	var title_label := Label.new()
	root.add_child(title_label)
	title_label.text = "Buy Packs"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82))

	buy_packs_info_label = Label.new()
	root.add_child(buy_packs_info_label)
	buy_packs_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	buy_packs_info_label.add_theme_font_size_override("font_size", 13)

	pack_count_spin_box = SpinBox.new()
	root.add_child(pack_count_spin_box)
	pack_count_spin_box.min_value = 0
	pack_count_spin_box.max_value = 0
	pack_count_spin_box.step = 1
	pack_count_spin_box.value = 0
	pack_count_spin_box.custom_minimum_size = Vector2(0, 32)
	pack_count_spin_box.value_changed.connect(_on_pack_count_spin_value_changed)

	var button_row := HBoxContainer.new()
	root.add_child(button_row)
	button_row.alignment = BoxContainer.ALIGNMENT_END
	button_row.add_theme_constant_override("separation", 8)

	var cancel_button := Button.new()
	button_row.add_child(cancel_button)
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(76, 30)
	cancel_button.pressed.connect(_on_buy_packs_canceled)

	buy_packs_confirm_button = Button.new()
	button_row.add_child(buy_packs_confirm_button)
	buy_packs_confirm_button.text = "Buy"
	buy_packs_confirm_button.custom_minimum_size = Vector2(76, 30)
	buy_packs_confirm_button.pressed.connect(_on_buy_packs_confirmed)

func create_pack_result_dialog() -> void:
	pack_result_dialog = AcceptDialog.new()
	add_child(pack_result_dialog)
	pack_result_dialog.title = "Pack Opened"
	pack_result_dialog.exclusive = true
	pack_result_dialog.min_size = Vector2i(360, 220)

	pack_result_label = Label.new()
	pack_result_dialog.add_child(pack_result_label)
	pack_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pack_result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pack_result_label.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _refresh_progress_ui() -> void:
	if pack_controller != null:
		pack_controller.refresh_progress_ui()

func _refresh_pack_inventory_ui() -> void:
	if pack_controller != null:
		pack_controller.refresh_pack_inventory_ui()

func _load_cards() -> void:
	if CardLibrary.all_cards.is_empty():
		CardLibrary.load_all_cards()
	CardPrintLibrary.ensure_loaded()
	PlayerCollectionStore.ensure_loaded()
	PlayerDeckStore.ensure_loaded()
	all_card_prints = CardPrintLibrary.get_all_prints()
	_refresh_card_filter(false)

func _on_buy_packs_pressed() -> void:
	if pack_controller != null:
		pack_controller.show_buy_packs()

func _on_pack_count_spin_value_changed(_value: float) -> void:
	if pack_controller != null:
		pack_controller.on_pack_count_spin_value_changed(_value)

func _update_buy_packs_info() -> void:
	if pack_controller != null:
		pack_controller.update_buy_packs_info()

func _on_buy_packs_confirmed() -> void:
	if pack_controller != null:
		pack_controller.confirm_buy_packs()

func _on_buy_packs_canceled() -> void:
	if pack_controller != null:
		pack_controller.cancel_buy_packs()

func _on_pack_pressed() -> void:
	if pack_controller != null:
		pack_controller.open_pack()

func _on_pack_opened(_rewards: Array[CardPrint]) -> void:
	_populate_saved_decks_list()
	_update_deck_editor_state()
	_refresh_card_filter(false)

func _show_page(page_index: int) -> void:
	current_page = clampi(page_index, 0, max(0, _get_page_count() - 1))
	_clear_browser_card_description()
	for child in card_grid.get_children():
		card_grid.remove_child(child)
		child.queue_free()

	var start_index: int = current_page * current_cards_per_page
	var end_index: int = min(start_index + current_cards_per_page, filtered_card_prints.size())
	if filtered_card_prints.is_empty():
		var empty_label := Label.new()
		card_grid.add_child(empty_label)
		empty_label.text = "No cards found"
		empty_label.custom_minimum_size = Vector2(0, 120)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))

	for index in range(start_index, end_index):
		var card_print: CardPrint = filtered_card_prints[index] as CardPrint
		if card_print == null:
			continue
		var card: Card = CardPrintLibrary.get_card_for_print(card_print)
		if card == null:
			continue

		var card_visual: CardVisual = CARD_VISUAL.instantiate() as CardVisual
		var owned_count: int = PlayerCollectionStore.get_owned_count_for_print_id(card_print.print_id)
		var card_slot: Control = _create_browser_card_slot(card_visual, owned_count)
		card_grid.add_child(card_slot)
		card_visual.draggable = is_creating_deck
		card_visual.set_hover_raise_enabled(false)
		card_visual.set_card_print(card_print)
		card_visual.set_face_down(false)
		card_visual.set_collection_owned(owned_count > 0)
		card_visual.mouse_entered.connect(_on_browser_card_mouse_entered.bind(card, card_print))
		card_visual.mouse_exited.connect(_on_browser_card_mouse_exited.bind(card.card_name))
		card_visual.drag_started.connect(_on_card_drag_started.bind(card_print.print_id))
		card_visual.drag_released.connect(_on_card_drag_released.bind(card_print.print_id))

	page_label.text = "%d / %d" % [current_page + 1, max(1, _get_page_count())]
	previous_button.disabled = current_page <= 0
	next_button.disabled = current_page >= _get_page_count() - 1
	_update_deck_editor_state()

func _get_page_count() -> int:
	return int(ceil(float(filtered_card_prints.size()) / float(current_cards_per_page)))

func _refresh_card_filter(reset_page: bool = true) -> void:
	filtered_card_prints.clear()
	var query: String = search_field.text.strip_edges().to_lower() if search_field != null else ""
	var owned_only: bool = owned_only_check.button_pressed if owned_only_check != null else false

	for card_print_value in all_card_prints:
		var card_print: CardPrint = card_print_value as CardPrint
		if card_print == null:
			continue
		var card: Card = CardPrintLibrary.get_card_for_print(card_print)
		if card == null:
			continue

		var owned_count: int = PlayerCollectionStore.get_owned_count_for_print_id(card_print.print_id)
		if owned_only && owned_count <= 0:
			continue

		var display_name: String = _get_deck_card_display_name(card, card_print).to_lower()
		if !query.is_empty() && display_name.find(query) == -1 && card.card_name.to_lower().find(query) == -1:
			continue

		filtered_card_prints.append(card_print)

	if card_grid != null:
		_show_page(0 if reset_page else current_page)

func _create_browser_card_slot(card_visual: CardVisual, owned_count: int) -> Control:
	var card_slot := Control.new()
	card_slot.custom_minimum_size = current_card_slot_size
	card_slot.mouse_filter = Control.MOUSE_FILTER_PASS
	card_slot.clip_contents = false
	card_slot.add_child(card_visual)
	card_slot.add_child(_create_print_count_badge(owned_count))
	card_slot.resized.connect(_on_browser_card_slot_resized.bind(card_slot, card_visual))
	_configure_browser_card_layout(card_slot, card_visual)
	return card_slot

func _configure_browser_card_layout(card_slot: Control, card_visual: CardVisual) -> void:
	card_slot.custom_minimum_size = current_card_slot_size
	card_visual.custom_minimum_size = CARD_VISUAL_SIZE
	card_visual.size = CARD_VISUAL_SIZE
	var scale_factor: float = _get_card_scale_for_slot_size(current_card_slot_size)
	card_visual.set_rest_scale(Vector2.ONE * scale_factor)
	var available_size: Vector2 = card_slot.size
	if available_size.x <= 0.0 or available_size.y <= 0.0:
		available_size = current_card_slot_size
	card_visual.position = (available_size - CARD_VISUAL_SIZE * scale_factor) * 0.5
	_update_print_count_badge_layout(card_slot, card_visual)

func _create_print_count_badge(owned_count: int) -> Control:
	var badge := PanelContainer.new()
	badge.name = "CountBadge"
	badge.visible = owned_count > 1
	badge.custom_minimum_size = Vector2(26, 26)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.z_index = 20

	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.08, 0.08, 0.08, 0.92)
	badge_style.border_color = Color(1.0, 1.0, 1.0, 0.94)
	badge_style.border_width_left = 2
	badge_style.border_width_top = 2
	badge_style.border_width_right = 2
	badge_style.border_width_bottom = 2
	badge_style.corner_radius_top_left = 13
	badge_style.corner_radius_top_right = 13
	badge_style.corner_radius_bottom_left = 13
	badge_style.corner_radius_bottom_right = 13
	badge.add_theme_stylebox_override("panel", badge_style)

	var label := Label.new()
	badge.add_child(label)
	label.text = str(owned_count)
	label.custom_minimum_size = Vector2(22, 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color.WHITE)
	return badge

func _update_print_count_badge_layout(card_slot: Control, card_visual: CardVisual) -> void:
	var badge: Control = card_slot.get_node_or_null("CountBadge") as Control
	if badge == null:
		return
	badge.size = badge.custom_minimum_size
	badge.position = card_visual.position + Vector2(-7, -7)

func _on_browser_card_slot_resized(card_slot: Control, card_visual: CardVisual) -> void:
	if card_visual != null:
		_configure_browser_card_layout(card_slot, card_visual)

func _get_card_scale_for_slot_size(slot_size: Vector2) -> float:
	if slot_size.x <= 0.0 or slot_size.y <= 0.0:
		return 1.0

	return minf(slot_size.x / CARD_VISUAL_SIZE.x, slot_size.y / CARD_VISUAL_SIZE.y)

func _get_browser_card_visual(node: Node) -> CardVisual:
	if node is CardVisual:
		return node as CardVisual

	for child in node.get_children():
		if child is CardVisual:
			return child as CardVisual

	return null

func _get_scaled_card_rect(card_visual: CardVisual) -> Rect2:
	var scaled_size: Vector2 = CARD_VISUAL_SIZE * card_visual.scale
	var scaled_top_left: Vector2 = card_visual.global_position + card_visual.pivot_offset * (Vector2.ONE - card_visual.scale)
	return Rect2(scaled_top_left, scaled_size)

func _on_viewport_size_changed() -> void:
	_apply_responsive_layout(true)

func _apply_responsive_layout(refresh_page: bool) -> void:
	var viewport_width: float = get_viewport_rect().size.x
	var viewport_height: float = get_viewport_rect().size.y
	var next_columns: int = DESKTOP_CARD_COLUMNS
	var next_cards_per_page: int = DESKTOP_CARDS_PER_PAGE
	var next_card_slot_size: Vector2 = DESKTOP_CARD_SLOT_SIZE
	var next_margin: int = 24
	var next_h_gap: int = 20
	var next_v_gap: int = 8
	var next_layout_gap: int = 14
	var next_layout_width: int = LAYOUT_WIDTH
	var next_left_width: int = LEFT_COLUMN_WIDTH
	var next_middle_width: int = MIDDLE_COLUMN_WIDTH
	var next_deck_width: int = RIGHT_COLUMN_WIDTH

	if viewport_width < 980.0:
		next_columns = COMPACT_CARD_COLUMNS
		next_cards_per_page = COMPACT_CARDS_PER_PAGE
		next_card_slot_size = COMPACT_CARD_SLOT_SIZE
		next_margin = 16
		next_h_gap = 14
		next_v_gap = 8
		next_layout_gap = 12
		next_left_width = 210
		next_middle_width = 360
		next_deck_width = 300
		next_layout_width = next_left_width + next_middle_width + next_deck_width + next_layout_gap * 2
	elif viewport_width < 1180.0:
		next_columns = MEDIUM_CARD_COLUMNS
		next_cards_per_page = MEDIUM_CARDS_PER_PAGE
		next_card_slot_size = MEDIUM_CARD_SLOT_SIZE
		next_margin = 18
		next_h_gap = 16
		next_v_gap = 8
		next_layout_gap = 12
		next_left_width = 230
		next_middle_width = 460
		next_deck_width = 310
		next_layout_width = next_left_width + next_middle_width + next_deck_width + next_layout_gap * 2

	var layout_changed: bool = next_columns != current_card_columns or next_cards_per_page != current_cards_per_page
	current_card_columns = next_columns
	current_cards_per_page = next_cards_per_page
	current_card_slot_size = next_card_slot_size
	var available_height: int = maxi(360, int(viewport_height) - TOP_BAR_HEIGHT - next_margin * 2)
	var next_info_height: int = mini(LEFT_INFO_HEIGHT, maxi(320, available_height - LEFT_PACK_HEIGHT - 18))

	if root_margin != null:
		root_margin.add_theme_constant_override("margin_left", next_margin)
		root_margin.add_theme_constant_override("margin_top", TOP_BAR_HEIGHT + next_margin)
		root_margin.add_theme_constant_override("margin_right", next_margin)
		root_margin.add_theme_constant_override("margin_bottom", next_margin)
	if main_layout != null:
		main_layout.custom_minimum_size = Vector2(next_layout_width, 0)
		main_layout.add_theme_constant_override("separation", next_layout_gap)
	if left_column != null:
		left_column.custom_minimum_size = Vector2(next_left_width, 0)
	if card_description_panel != null:
		card_description_panel.custom_minimum_size = Vector2(next_left_width, next_info_height)
	if middle_column != null:
		middle_column.custom_minimum_size = Vector2(next_middle_width, 0)
	if card_grid != null:
		card_grid.columns = current_card_columns
		card_grid.add_theme_constant_override("h_separation", next_h_gap)
		card_grid.add_theme_constant_override("v_separation", next_v_gap)
	if deck_panel_frame != null:
		deck_panel_frame.custom_minimum_size = Vector2(next_deck_width, 0)
	if right_column != null:
		right_column.custom_minimum_size = Vector2(next_deck_width, 0)

	if refresh_page:
		if layout_changed:
			_show_page(current_page)
		else:
			_update_existing_card_sizes()

func _update_existing_card_sizes() -> void:
	if card_grid == null:
		return
	for child in card_grid.get_children():
		var card_visual: CardVisual = _get_browser_card_visual(child)
		if card_visual != null && child is Control:
			_configure_browser_card_layout(child as Control, card_visual)

func _on_previous_pressed() -> void:
	_show_page(current_page - 1)

func _on_next_pressed() -> void:
	_show_page(current_page + 1)

func _on_search_text_changed(_new_text: String) -> void:
	_refresh_card_filter(true)

func _on_owned_only_toggled(_pressed: bool) -> void:
	_refresh_card_filter(true)

func _on_new_deck_pressed() -> void:
	is_creating_deck = true
	editing_deck_id = ""
	editing_deck_has_missing_cards = false
	selected_deck_cards.clear()
	dragged_print_id = ""
	hovered_deck_card_index = -1
	deck_name_edit.text = ""
	_hide_remove_card_button()
	_refresh_selected_deck_cards()
	_update_deck_editor_state()
	_show_page(current_page)

func _on_deck_editor_back_pressed() -> void:
	is_creating_deck = false
	editing_deck_id = ""
	editing_deck_has_missing_cards = false
	selected_deck_cards.clear()
	dragged_print_id = ""
	hovered_deck_card_index = -1
	_hide_remove_card_button()
	_refresh_selected_deck_cards()
	_update_deck_editor_state()
	_show_page(current_page)

func _on_deck_name_changed(_new_text: String) -> void:
	_update_deck_editor_state()

func _on_browser_card_mouse_entered(card: Card, card_print: CardPrint = null) -> void:
	if card == null:
		return

	hovered_browser_card_name = card.card_name
	_show_card_preview(card, card_print)

func _on_browser_card_mouse_exited(card_name: String) -> void:
	if hovered_browser_card_name != card_name:
		return

	_clear_browser_card_description()

func _update_browser_card_description_hover() -> void:
	if card_grid == null or card_description_label == null:
		return

	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var hovered_card: Card = null
	for child in card_grid.get_children():
		var card_visual: CardVisual = _get_browser_card_visual(child)
		if card_visual != null && card_visual.is_visible_in_tree() && _get_scaled_card_rect(card_visual).has_point(mouse_position):
			hovered_card = card_visual.card
			break

	if hovered_card == null && deck_card_list != null:
		for child in deck_card_list.get_children():
			if !(child is Control):
				continue

			var deck_card_row: Control = child as Control
			if !deck_card_row.is_visible_in_tree() or !deck_card_row.get_global_rect().has_point(mouse_position):
				continue

			hovered_card = CardLibrary.get_card(str(deck_card_row.get_meta("card_name", "")))
			break

	if hovered_card == null:
		if !hovered_browser_card_name.is_empty():
			_clear_browser_card_description()
		return

	if hovered_browser_card_name == hovered_card.card_name:
		return

	hovered_browser_card_name = hovered_card.card_name
	_show_card_preview(hovered_card)

func _clear_browser_card_description() -> void:
	hovered_browser_card_name = ""
	if card_description_label != null:
		card_description_label.text = ""
	if preview_card_visual != null:
		preview_card_visual.visible = false

func _show_card_preview(card: Card, card_print: CardPrint = null) -> void:
	if card == null:
		return

	hovered_browser_card_name = card.card_name
	if card_description_label != null:
		card_description_label.text = card.description.strip_edges()
	if preview_card_visual != null:
		if card_print != null:
			preview_card_visual.set_card_print(card_print)
		else:
			preview_card_visual.set_card(card)
		preview_card_visual.set_face_down(false)
		preview_card_visual.set_collection_owned(true)
		preview_card_visual.draggable = false
		preview_card_visual.disabled = true
		preview_card_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_card_visual.visible = true
		_layout_preview_card()

func _layout_preview_card() -> void:
	if preview_card_holder == null or preview_card_visual == null:
		return

	var holder_size: Vector2 = preview_card_holder.size
	if holder_size.x <= 0.0 or holder_size.y <= 0.0:
		holder_size = preview_card_holder.custom_minimum_size
	var scale_factor: float = minf(holder_size.x / CARD_VISUAL_SIZE.x, holder_size.y / CARD_VISUAL_SIZE.y) * 0.92
	preview_card_visual.set_rest_scale(Vector2.ONE * scale_factor)
	preview_card_visual.size = CARD_VISUAL_SIZE
	preview_card_visual.position = (holder_size - CARD_VISUAL_SIZE * scale_factor) * 0.5

func _on_card_drag_started(_card_visual: CardVisual, print_id: String) -> void:
	dragged_print_id = print_id

func _on_card_drag_released(_card_visual: CardVisual, print_id: String) -> void:
	if !is_creating_deck:
		return

	var mouse_position := get_viewport().get_mouse_position()
	if deck_card_scroll.get_global_rect().has_point(mouse_position) && _can_add_print_to_deck(print_id):
		selected_deck_cards.append(_create_deck_card_entry(print_id, selected_deck_cards.size()))
		_refresh_selected_deck_cards()
		_update_deck_editor_state()

	dragged_print_id = ""
	call_deferred("_show_page", current_page)

func _on_done_pressed() -> void:
	if !_can_complete_deck():
		return

	if editing_deck_id.is_empty():
		PlayerDeckStore.save_new_deck(deck_name_edit.text, selected_deck_cards)
	else:
		PlayerDeckStore.save_existing_deck(editing_deck_id, deck_name_edit.text, selected_deck_cards)
	is_creating_deck = false
	editing_deck_id = ""
	editing_deck_has_missing_cards = false
	selected_deck_cards.clear()
	deck_name_edit.text = ""
	hovered_deck_card_index = -1
	_hide_remove_card_button()
	_refresh_selected_deck_cards()
	_populate_saved_decks_list()
	_update_deck_editor_state()
	_show_page(current_page)

func _on_back_pressed() -> void:
	SceneTransition.change_scene(MAIN_MENU_SCENE)

func _update_deck_editor_state() -> void:
	if new_deck_button == null:
		return

	new_deck_button.visible = !is_creating_deck
	deck_editor_back_button.visible = is_creating_deck
	deck_name_edit.visible = is_creating_deck
	deck_list_scroll.visible = !is_creating_deck
	deck_card_scroll.visible = is_creating_deck
	deck_count_label.visible = is_creating_deck
	done_button.visible = is_creating_deck
	deck_count_label.text = "%d/%d" % [selected_deck_cards.size(), MAX_DECK_SIZE]
	done_button.disabled = !_can_complete_deck()

	for child in card_grid.get_children():
		var visual: CardVisual = _get_browser_card_visual(child)
		if visual != null:
			visual.draggable = is_creating_deck && !editing_deck_has_missing_cards && visual.collection_owned && _can_add_card_to_deck(visual.card) && selected_deck_cards.size() < MAX_DECK_SIZE
			visual.disabled = !visual.collection_owned

func _can_complete_deck() -> bool:
	return is_creating_deck && !editing_deck_has_missing_cards && !deck_name_edit.text.strip_edges().is_empty() && selected_deck_cards.size() == MAX_DECK_SIZE && _has_selected_nexus_card() && !_has_too_many_card_copies()

func _can_add_print_to_deck(print_id: String) -> bool:
	if editing_deck_has_missing_cards:
		return false

	var card_print: CardPrint = CardPrintLibrary.get_print(print_id)
	var card: Card = CardPrintLibrary.get_card_for_print(card_print)
	return card != null && PlayerCollectionStore.owns_print(card_print) && _can_add_card_to_deck(card) && selected_deck_cards.size() < MAX_DECK_SIZE

func _refresh_selected_deck_cards() -> void:
	for child in deck_card_list.get_children():
		deck_card_list.remove_child(child)
		child.queue_free()

	var nexus_cards: Array = []
	var unit_cards: Array = []
	for index in range(selected_deck_cards.size()):
		var deck_card = selected_deck_cards[index]
		if !(deck_card is Dictionary):
			continue
		var card_print: CardPrint = _get_print_for_deck_card(deck_card)
		var card: Card = CardPrintLibrary.get_card_for_print(card_print)
		if card == null:
			card = CardLibrary.duplicate_card(str(deck_card.get("card_name", "")))
		if card == null:
			continue
		var entry := {
			"card": card,
			"card_print": card_print,
			"index": index,
		}
		if MoveRules.is_nexus_card(card):
			nexus_cards.append(entry)
		else:
			unit_cards.append(entry)

	_add_selected_deck_section("Nexus", nexus_cards)
	_add_selected_deck_section("Units", unit_cards)

func _add_selected_deck_section(title: String, entries: Array) -> void:
	var section_title := Label.new()
	deck_card_list.add_child(section_title)
	section_title.text = title
	section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section_title.add_theme_font_size_override("font_size", 20)
	section_title.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))

	var section_line := HSeparator.new()
	deck_card_list.add_child(section_line)

	var section_grid := GridContainer.new()
	deck_card_list.add_child(section_grid)
	section_grid.columns = 2
	section_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_grid.add_theme_constant_override("h_separation", 10)
	section_grid.add_theme_constant_override("v_separation", 12)

	if entries.is_empty():
		var empty_label := Label.new()
		section_grid.add_child(empty_label)
		empty_label.text = "Empty"
		empty_label.custom_minimum_size = Vector2(0, 36)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.28, 0.28, 0.28))
		return

	for entry in entries:
		if !(entry is Dictionary):
			continue
		var card: Card = entry.get("card", null) as Card
		var card_print: CardPrint = entry.get("card_print", null) as CardPrint
		var deck_card_index: int = int(entry.get("index", -1))
		section_grid.add_child(_create_selected_deck_card_slot(card, card_print, deck_card_index))

func _create_selected_deck_card_slot(card: Card, card_print: CardPrint, deck_card_index: int) -> Control:
	var card_slot := Control.new()
	card_slot.custom_minimum_size = DECK_EDIT_CARD_SLOT_SIZE
	card_slot.mouse_filter = Control.MOUSE_FILTER_PASS
	card_slot.clip_contents = false
	if card != null:
		card_slot.set_meta("card_name", card.card_name)

	var card_visual := CARD_VISUAL.instantiate() as CardVisual
	card_slot.add_child(card_visual)
	card_visual.custom_minimum_size = CARD_VISUAL_SIZE
	card_visual.size = CARD_VISUAL_SIZE
	card_visual.set_hover_raise_enabled(false)
	if card_print != null:
		card_visual.set_card_print(card_print)
	else:
		card_visual.set_card(card)
	card_visual.set_face_down(false)
	card_visual.set_collection_owned(true)
	card_visual.draggable = false
	card_visual.disabled = false
	card_visual.mouse_filter = Control.MOUSE_FILTER_STOP
	card_visual.mouse_entered.connect(_on_browser_card_mouse_entered.bind(card, card_print))
	card_visual.mouse_exited.connect(_on_browser_card_mouse_exited.bind(card.card_name if card != null else ""))
	card_slot.resized.connect(_layout_selected_deck_card_slot.bind(card_slot, card_visual))
	_layout_selected_deck_card_slot(card_slot, card_visual)

	if !editing_deck_has_missing_cards:
		var remove_button := _create_circle_icon_button("X", "Remove card")
		card_slot.add_child(remove_button)
		remove_button.custom_minimum_size = Vector2(28, 28)
		remove_button.size = Vector2(28, 28)
		remove_button.position = Vector2(DECK_EDIT_CARD_SLOT_SIZE.x - 30.0, 0.0)
		remove_button.z_index = 30
		remove_button.pressed.connect(_on_remove_selected_deck_card_pressed.bind(deck_card_index))

	return card_slot

func _layout_selected_deck_card_slot(card_slot: Control, card_visual: CardVisual) -> void:
	if card_slot == null or card_visual == null:
		return

	card_slot.custom_minimum_size = DECK_EDIT_CARD_SLOT_SIZE
	var scale_factor: float = _get_card_scale_for_slot_size(DECK_EDIT_CARD_SLOT_SIZE)
	card_visual.set_rest_scale(Vector2.ONE * scale_factor)
	card_visual.size = CARD_VISUAL_SIZE
	card_visual.position = (DECK_EDIT_CARD_SLOT_SIZE - CARD_VISUAL_SIZE * scale_factor) * 0.5

func _on_remove_selected_deck_card_pressed(deck_card_index: int) -> void:
	hovered_deck_card_index = deck_card_index
	_on_remove_card_pressed()

func _create_deck_card_row(card: Card, card_print: CardPrint, deck_card_index: int) -> Control:
	var row_frame := PanelContainer.new()
	row_frame.custom_minimum_size = Vector2(0, 34)
	row_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	row_frame.set_meta("card_name", card.card_name)
	row_frame.mouse_entered.connect(_on_deck_card_row_mouse_entered.bind(deck_card_index, row_frame))

	var row := HBoxContainer.new()
	row_frame.add_child(row)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var duration_label := Label.new()
	row.add_child(duration_label)
	duration_label.custom_minimum_size = Vector2(34, 0)
	duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	duration_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	duration_label.text = "INF" if card.duration < 0 else str(card.duration)

	var name_label := Label.new()
	row.add_child(name_label)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.text = _get_deck_card_display_name(card, card_print)
	name_label.clip_text = true

	if card.has_effect():
		if card.effect_icon != null:
			var effect_texture := TextureRect.new()
			row.add_child(effect_texture)
			effect_texture.custom_minimum_size = Vector2(24, 24)
			effect_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			effect_texture.texture = card.effect_icon
		else:
			var effect_label := Label.new()
			row.add_child(effect_label)
			effect_label.custom_minimum_size = Vector2(32, 0)
			effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			effect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			effect_label.text = CardEffect.get_effect_label(card.effect_type)

	return row_frame

func _populate_saved_decks_list() -> void:
	for child in deck_list.get_children():
		deck_list.remove_child(child)
		child.queue_free()

	var saved_decks: Array = PlayerDeckStore.list_decks()
	if saved_decks.is_empty():
		var empty_label := Label.new()
		deck_list.add_child(empty_label)
		empty_label.text = "No saved decks"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return

	for deck_data in saved_decks:
		if !(deck_data is Dictionary):
			continue
		deck_list.add_child(_create_saved_deck_row(deck_data))

func _create_saved_deck_row(deck_data: Dictionary) -> Control:
	var ownership_info: Dictionary = PlayerDeckStore.get_deck_ownership_info(deck_data)
	var is_playable: bool = bool(ownership_info.get("is_playable", false))
	var owned_count: int = int(ownership_info.get("owned_count", 0))

	var row_frame := Control.new()
	row_frame.custom_minimum_size = Vector2(0, 148)
	row_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_frame.clip_contents = false

	var preview_prints: Array = _get_deck_preview_prints(deck_data)
	var preview_offsets: Array = [Vector2(76, -2), Vector2(126, -6), Vector2(176, -2)]
	var preview_rotations: Array = [-8.0, 8.0, -4.0]
	for index in range(preview_prints.size()):
		var preview_print: CardPrint = preview_prints[index] as CardPrint
		if preview_print == null:
			continue
		var preview_visual := _create_small_deck_preview_card(preview_print)
		row_frame.add_child(preview_visual)
		preview_visual.position = preview_offsets[index]
		preview_visual.rotation = deg_to_rad(preview_rotations[index])

	var front_panel := PanelContainer.new()
	row_frame.add_child(front_panel)
	front_panel.anchor_left = 0.0
	front_panel.anchor_top = 0.0
	front_panel.anchor_right = 1.0
	front_panel.anchor_bottom = 1.0
	front_panel.offset_left = 0.0
	front_panel.offset_top = 64.0
	front_panel.offset_right = 0.0
	front_panel.offset_bottom = 0.0
	front_panel.add_theme_stylebox_override("panel", _create_dark_panel_style(0, 20))

	var content := VBoxContainer.new()
	front_panel.add_child(content)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)

	var name_label := Label.new()
	content.add_child(name_label)
	name_label.text = str(deck_data.get("name", "Unnamed deck"))
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.9))

	var footer := HBoxContainer.new()
	content.add_child(footer)
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 8)

	var count_label := Label.new()
	footer.add_child(count_label)
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.text = "%d/%d" % [owned_count if !is_playable else MAX_DECK_SIZE, MAX_DECK_SIZE]
	count_label.add_theme_font_size_override("font_size", 18)
	count_label.add_theme_color_override("font_color", Color(0.95, 0.2, 0.2) if !is_playable else Color(0.86, 0.86, 0.82))

	var edit_button := _create_circle_icon_button("E", "Edit deck")
	footer.add_child(edit_button)
	edit_button.pressed.connect(_on_edit_deck_pressed.bind(deck_data.duplicate(true)))

	var delete_button := _create_circle_icon_button("X", "Delete deck")
	footer.add_child(delete_button)
	delete_button.pressed.connect(_on_delete_deck_pressed.bind(str(deck_data.get("deck_id", ""))))

	return row_frame

func _get_deck_preview_prints(deck_data: Dictionary) -> Array:
	var preview_prints: Array = []
	var deck_cards = deck_data.get("cards", [])
	if !(deck_cards is Array):
		return preview_prints

	var candidate_indexes: Array = [0, int(deck_cards.size() / 2), maxi(0, deck_cards.size() - 1)]
	for candidate_index in candidate_indexes:
		if candidate_index < 0 or candidate_index >= deck_cards.size():
			continue
		var deck_card = deck_cards[candidate_index]
		if !(deck_card is Dictionary):
			continue
		var card_print: CardPrint = _get_print_for_deck_card(deck_card)
		if card_print != null && !preview_prints.has(card_print):
			preview_prints.append(card_print)
		if preview_prints.size() >= 3:
			break
	return preview_prints

func _create_small_deck_preview_card(card_print: CardPrint) -> CardVisual:
	var card_visual := CARD_VISUAL.instantiate() as CardVisual
	card_visual.custom_minimum_size = CARD_VISUAL_SIZE
	card_visual.size = CARD_VISUAL_SIZE
	card_visual.set_hover_raise_enabled(false)
	card_visual.set_card_print(card_print)
	card_visual.set_face_down(false)
	card_visual.set_collection_owned(true)
	card_visual.set_rest_scale(Vector2.ONE * 0.38)
	card_visual.draggable = false
	card_visual.disabled = true
	card_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card_visual

func _create_circle_icon_button(text_value: String, tooltip: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(40, 40)
	button.focus_mode = Control.FOCUS_NONE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.72, 0.68, 0.68, 1.0)
	style.border_color = Color(0.08, 0.08, 0.08, 0.65)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	return button

func _on_delete_deck_pressed(deck_id: String) -> void:
	if deck_id.is_empty():
		return
	PlayerDeckStore.delete_deck(deck_id)
	if editing_deck_id == deck_id:
		_on_deck_editor_back_pressed()
	_populate_saved_decks_list()

func _get_print_for_deck_card(deck_card: Dictionary) -> CardPrint:
	var print_id: String = str(deck_card.get("print_id", ""))
	if !print_id.is_empty():
		var card_print: CardPrint = CardPrintLibrary.get_print(print_id)
		if card_print != null:
			return card_print

	var card_code: String = str(deck_card.get("card_code", ""))
	if card_code.is_empty():
		var card: Card = CardLibrary.get_card(str(deck_card.get("card_name", "")))
		if card != null:
			card_code = PlayerCollectionStore.get_card_code(card)

	var variant_id: String = str(deck_card.get("variant_id", PlayerCollectionStore.DEFAULT_VARIANT_ID))
	return CardPrintLibrary.get_print(CardPrintLibrary.get_print_id(card_code, variant_id))

func _get_deck_card_display_name(card: Card, card_print: CardPrint) -> String:
	if card_print == null or card_print.variant_id == PlayerCollectionStore.DEFAULT_VARIANT_ID:
		return card.card_name
	return "%s - %s" % [card.card_name, card_print.get_display_name()]

func _create_deck_card_entry(print_id: String, slot: int) -> Dictionary:
	var card_print: CardPrint = CardPrintLibrary.get_print(print_id)
	var card: Card = CardPrintLibrary.get_card_for_print(card_print)
	if card == null:
		return {}

	var owned_item: Dictionary = PlayerCollectionStore.get_owned_item_for_print(card_print)
	var card_code: String = PlayerCollectionStore.get_card_code(card)
	var variant_id: String = str(owned_item.get("variant_id", card_print.variant_id))
	if variant_id.is_empty():
		variant_id = PlayerCollectionStore.DEFAULT_VARIANT_ID

	return {
		"slot": slot,
		"print_id": card_print.print_id,
		"card_code": card_code,
		"card_name": card.card_name,
		"variant_id": variant_id,
		"variant_name": str(owned_item.get("variant_name", card_print.get_display_name())),
		"collection_instance_id": str(owned_item.get("instance_id", "")),
		"item_def_key": str(owned_item.get("item_def_key", card_print.print_id)),
		"steam_item_instance_id": str(owned_item.get("steam_item_instance_id", "")),
		"steam_item_def_id": str(owned_item.get("steam_item_def_id", "")),
	}

func _can_add_card_to_deck(card: Card) -> bool:
	if card == null:
		return false

	return _get_selected_card_count(card) < MAX_COPIES_PER_CARD

func _get_selected_card_count(card: Card) -> int:
	if card == null:
		return 0

	var card_code: String = PlayerCollectionStore.get_card_code(card)
	var count: int = 0
	for deck_card in selected_deck_cards:
		if deck_card is Dictionary && str(deck_card.get("card_code", "")) == card_code:
			count += 1
	return count

func _has_too_many_card_copies() -> bool:
	var card_counts: Dictionary = {}
	for deck_card in selected_deck_cards:
		if !(deck_card is Dictionary):
			continue

		var card_code: String = str(deck_card.get("card_code", "")).strip_edges()
		if card_code.is_empty():
			continue

		var next_count: int = int(card_counts.get(card_code, 0)) + 1
		if next_count > MAX_COPIES_PER_CARD:
			return true
		card_counts[card_code] = next_count
	return false

func _has_selected_nexus_card() -> bool:
	for deck_card in selected_deck_cards:
		if !(deck_card is Dictionary):
			continue

		var card_print: CardPrint = _get_print_for_deck_card(deck_card)
		var print_card: Card = CardPrintLibrary.get_card_for_print(card_print)
		if MoveRules.is_nexus_card(print_card):
			return true

		var card: Card = CardLibrary.get_card(str(deck_card.get("card_name", "")))
		if MoveRules.is_nexus_card(card):
			return true

		var card_by_code: Card = CardLibrary.get_card_by_code(str(deck_card.get("card_code", "")))
		if MoveRules.is_nexus_card(card_by_code):
			return true

	return false

func _on_edit_deck_pressed(deck_data: Dictionary) -> void:
	is_creating_deck = true
	editing_deck_id = str(deck_data.get("deck_id", ""))
	deck_name_edit.text = str(deck_data.get("name", ""))
	selected_deck_cards.clear()
	var ownership_info: Dictionary = PlayerDeckStore.get_deck_ownership_info(deck_data)
	editing_deck_has_missing_cards = int(ownership_info.get("missing_count", 0)) > 0

	var cards: Array = []
	if editing_deck_has_missing_cards:
		cards = PlayerDeckStore.get_owned_cards_from_deck(deck_data)
	else:
		var deck_cards = deck_data.get("cards", [])
		if deck_cards is Array:
			cards = deck_cards

	for index in range(cards.size()):
		var deck_card = cards[index]
		if deck_card is Dictionary:
			var normalized_card: Dictionary = deck_card.duplicate(true)
			normalized_card["slot"] = index
			selected_deck_cards.append(normalized_card)

	dragged_print_id = ""
	hovered_deck_card_index = -1
	_hide_remove_card_button()
	_refresh_selected_deck_cards()
	_update_deck_editor_state()
	_show_page(current_page)

func _on_deck_card_row_mouse_entered(deck_card_index: int, row_frame: Control) -> void:
	if !is_creating_deck or editing_deck_has_missing_cards:
		return

	hovered_deck_card_index = deck_card_index
	var row_rect := row_frame.get_global_rect()
	remove_card_button.global_position = Vector2(row_rect.end.x + 6.0, row_rect.position.y + row_rect.size.y * 0.5 - remove_card_button.size.y * 0.5)
	remove_card_button.visible = true
	remove_card_button.move_to_front()
	remove_card_timer.start()

func _on_remove_card_pressed() -> void:
	if editing_deck_has_missing_cards:
		_hide_remove_card_button()
		return

	if hovered_deck_card_index < 0 or hovered_deck_card_index >= selected_deck_cards.size():
		_hide_remove_card_button()
		return

	selected_deck_cards.remove_at(hovered_deck_card_index)
	for index in range(selected_deck_cards.size()):
		if selected_deck_cards[index] is Dictionary:
			var deck_card: Dictionary = selected_deck_cards[index]
			deck_card["slot"] = index
			selected_deck_cards[index] = deck_card

	hovered_deck_card_index = -1
	_hide_remove_card_button()
	_refresh_selected_deck_cards()
	_update_deck_editor_state()
	_show_page(current_page)

func _hide_remove_card_button() -> void:
	if remove_card_button == null:
		return

	remove_card_button.visible = false
	if remove_card_timer != null && !remove_card_timer.is_stopped():
		remove_card_timer.stop()
