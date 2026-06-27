extends Control

const CARD_VISUAL = preload("res://Scenes/CardVisual.tscn")
const PACK_CONTROLLER_SCRIPT = preload("res://Scenes/StackbuilderPackController.gd")
const WINDOW_CLOSE_ICON: Texture2D = preload("res://ui/themes/icons/window_close.svg")
const CODEX_TITLE_FONT: FontFile = preload("res://Fonts/ElmsSans-ExtraBold.ttf")
const MAIN_MENU_SCENE = "res://Scenes/MainMenu.tscn"
const CARD_VISUAL_SIZE: Vector2 = Vector2(164, 229)
const TOP_BAR_HEIGHT: int = 60
const LAYOUT_WIDTH: int = 894
const LEFT_COLUMN_WIDTH: int = 260
const MIDDLE_COLUMN_WIDTH: int = 520
const RIGHT_COLUMN_WIDTH: int = 360
const LEFT_INFO_HEIGHT: int = 420
const LEFT_PACK_HEIGHT: int = 170
const PACK_PANEL_MIN_HEIGHT: int = 104
const DESKTOP_CARDS_PER_PAGE: int = 9
const DESKTOP_CARD_COLUMNS: int = 3
const DESKTOP_CARD_SLOT_SIZE: Vector2 = Vector2(128, 142)
const MEDIUM_CARDS_PER_PAGE: int = 6
const MEDIUM_CARD_COLUMNS: int = 3
const MEDIUM_CARD_SLOT_SIZE: Vector2 = Vector2(118, 140)
const COMPACT_CARDS_PER_PAGE: int = 4
const COMPACT_CARD_COLUMNS: int = 2
const COMPACT_CARD_SLOT_SIZE: Vector2 = Vector2(120, 168)
const DECK_EDIT_CARD_SLOT_SIZE: Vector2 = Vector2(100, 140)
const DECK_SLOT_REMOVE_BUTTON_SIZE: Vector2 = Vector2(20, 20)
const CODEX_PAGE_TITLE_FONT_SIZE: int = 19
const CODEX_PAGE_GRID_HORIZONTAL_GAP: int = 8
const CODEX_PAGE_BOTTOM_SPACING: int = 2
const CODEX_EDITOR_LIST_SPACING: int = 4
const CODEX_SCROLL_WHEEL_IMPULSE: float = 620.0
const CODEX_SCROLL_MAX_VELOCITY: float = 2600.0
const CODEX_SCROLL_FRICTION: float = 7.0
const CODEX_SCROLL_EDGE_IMPULSE: float = 260.0
const CODEX_SCROLL_EDGE_SPRING: float = 46.0
const CODEX_SCROLL_EDGE_DAMPING: float = 10.0
const CODEX_SCROLL_MAX_OVERSHOOT: float = 30.0
const MAX_DECK_SIZE: int = 15
const CODEX_PAGE_COUNT: int = 5
const CODEX_STAMPS_PER_PAGE: int = 3
const MAX_COPIES_PER_CARD: int = PlayerDeckStore.MAX_COPIES_PER_CARD
const REMOVE_BUTTON_VISIBLE_SECONDS: float = 1.0
const CARD_DESCRIPTION_HEIGHT: int = 76
const GRID_BACKGROUND_SHADER = preload("res://Shaders/stackbuilder_grid_background.gdshader")
const MAGNIFIER_SHADER = preload("res://Shaders/stackbuilder_magnifier.gdshader")
const MAGNIFIER_GLASS_TEXTURE = preload("res://Assets/glass.png")
const MAGNIFIER_CASE_CLOSED_TEXTURE = preload("res://Assets/magnifying_glass_case_closed.png")
const MAGNIFIER_CASE_OPENED_TEXTURE = preload("res://Assets/magnifying_glass_case_opened.png")
const COIN_TEXTURE: Texture2D = preload("res://Assets/coin.svg")
const MAGNIFIER_CASE_DEFAULT_SIZE: Vector2 = Vector2(54, 121)
const MAGNIFIER_CASE_PRESSED_SCALE: float = 0.92
const MAGNIFIER_CASE_PRESS_IN_SECONDS: float = 0.055
const MAGNIFIER_CASE_PRESS_OUT_SECONDS: float = 0.075
const MAGNIFIER_LENS_SIZE: Vector2 = Vector2(220, 220)
const MAGNIFIER_Z_INDEX: int = 1800
const MAGNIFIER_GLASS_SOURCE_SIZE: Vector2 = Vector2(337, 570)
const MAGNIFIER_GLASS_LENS_SOURCE_RECT: Rect2 = Rect2(15, 15, 305, 305)
const MAGNIFIER_GLASS_ROTATION_DEGREES: float = -36.0
const HOVER_DESCRIPTION_SIZE: Vector2 = Vector2(300, 132)
const CARD_SLOT_SCALE_MULTIPLIER: float = 0.88
const STACKBUILDER_BACKGROUND_COLOR: Color = Color("#f9e7ce")
const STACKBUILDER_GRID_LINE_COLOR: Color = Color("#d9d0d5")
const TOP_BAR_BACKGROUND_COLOR: Color = Color(0.9366637, 0.9330646, 0.89437205, 1.0)
const BROWSER_CARD_VERTICAL_OFFSET: float = -12.0
const DECK_EDIT_CARD_VERTICAL_OFFSET: float = -8.0

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
var is_editing_deck_name: bool = false
var current_cards_per_page: int = DESKTOP_CARDS_PER_PAGE
var current_card_columns: int = DESKTOP_CARD_COLUMNS
var current_card_slot_size: Vector2 = DESKTOP_CARD_SLOT_SIZE
var codex_scroll_velocity: float = 0.0
var codex_scroll_overshoot: float = 0.0
var codex_scroll_overshoot_velocity: float = 0.0
var deck_selector_scroll_velocity: float = 0.0
var deck_selector_scroll_overshoot: float = 0.0
var deck_selector_scroll_overshoot_velocity: float = 0.0

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
var deck_title_label: Label
var deck_name_display: Label
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
var pack_panel: PanelContainer
var pack_inventory: Control
var pack_inventory_label: Label
var pack_result_dialog: AcceptDialog
var pack_result_label: Label
var pack_controller
var grid_background: ColorRect
var magnifier_backbuffer: BackBufferCopy
var magnifier_case_button: Control
var magnifier_case_click_area: Button
var magnifier_case_closed_image: TextureRect
var magnifier_case_opened_image: TextureRect
var magnifier_case_tween: Tween
var magnifier_group: Control
var magnifier_material: ShaderMaterial
var magnifier_screen_lens: ColorRect
var hover_description_panel: PanelContainer
var hover_description_label: Label
var grid_background_material: ShaderMaterial
var magnifier_enabled: bool = false
var magnifier_previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE

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
	_update_codex_scroll_inertia(_delta)
	_update_deck_selector_scroll_inertia(_delta)
	_update_magnifier_position()

func _unhandled_input(event: InputEvent) -> void:
	if magnifier_enabled && event.is_action_pressed("ui_cancel"):
		_set_magnifier_enabled(false)
		get_viewport().set_input_as_handled()
		return
	if _handle_elastic_scroll_unhandled_input(event):
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if magnifier_enabled:
		Input.set_mouse_mode(magnifier_previous_mouse_mode)

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
	_setup_grid_background()
	root_margin = $RootMargin
	main_center = $RootMargin/MainCenter
	main_layout = $RootMargin/MainCenter/MainLayout
	left_column = $RootMargin/MainCenter/MainLayout/LeftColumn
	middle_column = $RootMargin/MainCenter/MainLayout/MiddleColumn
	deck_panel_frame = $RootMargin/MainCenter/MainLayout/DeckPanelFrame
	deck_panel_frame.add_theme_stylebox_override("panel", _create_panel_style(Color(0.93, 0.93, 0.9), Color.TRANSPARENT, 0, 10))
	right_column = $RootMargin/MainCenter/MainLayout/DeckPanelFrame/RightColumn
	card_description_panel = get_node_or_null("RootMargin/MainCenter/MainLayout/LeftColumn/CardDescriptionPanel") as PanelContainer
	preview_card_holder = get_node_or_null("RootMargin/MainCenter/MainLayout/LeftColumn/CardDescriptionPanel/InfoRoot/PreviewCardHolder") as Control
	card_description_label = get_node_or_null("RootMargin/MainCenter/MainLayout/LeftColumn/CardDescriptionPanel/InfoRoot/CardDescriptionLabel") as Label
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
	_ensure_deck_name_display()
	deck_list_scroll = $RootMargin/MainCenter/MainLayout/DeckPanelFrame/RightColumn/DeckListScroll
	deck_list = $RootMargin/MainCenter/MainLayout/DeckPanelFrame/RightColumn/DeckListScroll/DeckList
	deck_list.mouse_filter = Control.MOUSE_FILTER_PASS
	deck_card_scroll = $RootMargin/MainCenter/MainLayout/DeckPanelFrame/RightColumn/DeckCardScroll
	deck_card_list = $RootMargin/MainCenter/MainLayout/DeckPanelFrame/RightColumn/DeckCardScroll/DeckCardList
	deck_card_list.add_theme_constant_override("separation", CODEX_EDITOR_LIST_SPACING)
	deck_count_label = $RootMargin/MainCenter/MainLayout/DeckPanelFrame/RightColumn/DeckFooter/DeckCountLabel
	done_button = $RootMargin/MainCenter/MainLayout/DeckPanelFrame/RightColumn/DeckFooter/DoneButton
	top_bar = $TopBar
	buy_packs_button = $TopBar/BuyPacksButton
	points_label = $TopBar/PointsContainer/PointsLabel
	pack_panel = get_node_or_null("RootMargin/MainCenter/MainLayout/LeftColumn/PackPanel") as PanelContainer
	if pack_panel == null:
		pack_panel = get_node_or_null("RootMargin/MainCenter/MainLayout/MiddleColumn/PackPanel") as PanelContainer
	if pack_panel != null:
		pack_inventory = pack_panel.get_node_or_null("PackRoot/PackInventory") as Control
		pack_inventory_label = pack_panel.get_node_or_null("PackRoot/PackInventoryLabel") as Label
		if pack_inventory == null:
			pack_inventory = pack_panel.get_node_or_null("PackRoot/PackContentRow/PackInventory") as Control
		if pack_inventory_label == null:
			pack_inventory_label = pack_panel.get_node_or_null("PackRoot/PackContentRow/PackInventoryLabel") as Label
	buy_packs_panel = $BuyPacksPanel
	pack_count_spin_box = $BuyPacksPanel/BuyPacksRoot/PackCountSpinBox
	buy_packs_info_label = $BuyPacksPanel/BuyPacksRoot/BuyPacksInfoLabel
	buy_packs_confirm_button = $BuyPacksPanel/BuyPacksRoot/ButtonRow/BuyButton
	pack_result_dialog = $PackResultDialog
	pack_result_label = $PackResultDialog/PackResultLabel
	remove_card_button = $RemoveCardButton
	remove_card_timer = $RemoveCardTimer
	deck_title_label = get_node_or_null("RootMargin/MainCenter/MainLayout/DeckPanelFrame/RightColumn/DeckTitle") as Label
	if deck_title_label != null:
		deck_title_label.text = "My codexes"
	new_deck_button.text = "New codex"
	deck_name_edit.placeholder_text = "Codex name"
	_configure_inventory_block()
	_move_pack_panel_under_browser()
	_remove_card_info_panel()
	_setup_hover_description_panel()

	_connect_once($TopBar/BackButton.pressed, Callable(self, "_on_back_pressed"))
	_connect_once(owned_only_check.toggled, Callable(self, "_on_owned_only_toggled"))
	_connect_once(search_field.text_changed, Callable(self, "_on_search_text_changed"))
	_connect_once(previous_button.pressed, Callable(self, "_on_previous_pressed"))
	_connect_once(next_button.pressed, Callable(self, "_on_next_pressed"))
	_connect_once(new_deck_button.pressed, Callable(self, "_on_new_deck_pressed"))
	_connect_once(deck_editor_back_button.pressed, Callable(self, "_on_deck_editor_back_pressed"))
	_connect_once(deck_name_display.gui_input, Callable(self, "_on_deck_name_display_gui_input"))
	_connect_once(deck_name_edit.text_changed, Callable(self, "_on_deck_name_changed"))
	_connect_once(deck_name_edit.text_submitted, Callable(self, "_on_deck_name_edit_submitted"))
	_connect_once(deck_name_edit.focus_exited, Callable(self, "_finish_deck_name_edit"))
	_connect_once(done_button.pressed, Callable(self, "_on_done_pressed"))
	_connect_once(remove_card_button.pressed, Callable(self, "_on_remove_card_pressed"))
	_connect_once(remove_card_timer.timeout, Callable(self, "_hide_remove_card_button"))
	_connect_once(deck_card_scroll.resized, Callable(self, "_on_deck_card_scroll_resized"))
	_connect_once(deck_list_scroll.gui_input, Callable(self, "_on_deck_selector_scroll_gui_input"))
	_connect_once(deck_card_scroll.gui_input, Callable(self, "_on_codex_scroll_gui_input"))

	buy_packs_panel.visible = false
	deck_list_scroll.clip_contents = true
	deck_list.clip_contents = false
	deck_card_scroll.visible = false
	deck_card_scroll.clip_contents = true
	deck_card_list.clip_contents = false
	deck_name_edit.visible = false
	deck_editor_back_button.visible = false
	deck_count_label.visible = false
	done_button.visible = false
	remove_card_button.visible = false
	$TopBackground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$TopBackground.color = TOP_BAR_BACKGROUND_COLOR
	$TopBackground.move_to_front()
	top_bar.move_to_front()
	_setup_magnifier()

func _configure_inventory_block() -> void:
	var browser_frame := get_node_or_null("RootMargin/MainCenter/MainLayout/MiddleColumn/BrowserFrame") as PanelContainer
	if browser_frame != null:
		browser_frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		browser_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var browser_title := get_node_or_null("RootMargin/MainCenter/MainLayout/MiddleColumn/BrowserFrame/Browser/BrowserTitle") as Label
	if browser_title != null:
		browser_title.visible = false

	if browser != null:
		browser.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		browser.add_theme_constant_override("separation", 4)
	if card_grid != null:
		card_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

func _move_pack_panel_under_browser() -> void:
	if pack_panel == null:
		return
	if middle_column == null:
		return
	middle_column.add_theme_constant_override("separation", 10)

	var previous_parent: Node = pack_panel.get_parent()
	if previous_parent != middle_column:
		if previous_parent != null:
			previous_parent.remove_child(pack_panel)
		middle_column.add_child(pack_panel)

	pack_panel.custom_minimum_size = Vector2(0, PACK_PANEL_MIN_HEIGHT)
	pack_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pack_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pack_panel.add_theme_stylebox_override("panel", _create_panel_style(Color(0.93, 0.93, 0.9), Color(0.1, 0.1, 0.1, 0.65), 0, 10))

	var pack_root := pack_panel.get_node_or_null("PackRoot") as Container
	if pack_root == null:
		return
	pack_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pack_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pack_root.add_theme_constant_override("separation", 0)

	var pack_title := pack_root.get_node_or_null("PackTitle") as Label
	if pack_title != null:
		pack_title.visible = false

	var content_row := pack_root.get_node_or_null("PackContentRow") as HBoxContainer
	if content_row == null:
		content_row = HBoxContainer.new()
		content_row.name = "PackContentRow"
		pack_root.add_child(content_row)
	content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.alignment = BoxContainer.ALIGNMENT_CENTER
	content_row.add_theme_constant_override("separation", 16)
	pack_root.move_child(content_row, 0)

	if pack_inventory_label != null:
		if pack_inventory_label.get_parent() != content_row:
			var label_parent: Node = pack_inventory_label.get_parent()
			if label_parent != null:
				label_parent.remove_child(pack_inventory_label)
			content_row.add_child(pack_inventory_label)
		pack_inventory_label.custom_minimum_size = Vector2(132, 78)
		pack_inventory_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		pack_inventory_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pack_inventory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pack_inventory_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	if pack_inventory != null:
		if pack_inventory.get_parent() != content_row:
			var inventory_parent: Node = pack_inventory.get_parent()
			if inventory_parent != null:
				inventory_parent.remove_child(pack_inventory)
			content_row.add_child(pack_inventory)
		pack_inventory.custom_minimum_size = Vector2(0, 86)
		pack_inventory.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pack_inventory.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pack_inventory.clip_contents = false

func _remove_card_info_panel() -> void:
	if card_description_panel != null:
		var panel_parent: Node = card_description_panel.get_parent()
		if panel_parent != null:
			panel_parent.remove_child(card_description_panel)
		card_description_panel.queue_free()
	card_description_panel = null
	card_description_label = null
	preview_card_holder = null
	preview_card_visual = null

	if left_column != null:
		left_column.visible = false
		left_column.custom_minimum_size = Vector2.ZERO
		left_column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		left_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

func _setup_hover_description_panel() -> void:
	if hover_description_panel == null or !is_instance_valid(hover_description_panel):
		hover_description_panel = PanelContainer.new()
		hover_description_panel.name = "HoverDescriptionPanel"
		hover_description_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hover_description_panel.custom_minimum_size = HOVER_DESCRIPTION_SIZE
		hover_description_panel.size = HOVER_DESCRIPTION_SIZE
		hover_description_panel.z_as_relative = false
		hover_description_panel.z_index = MAGNIFIER_Z_INDEX + 12
		hover_description_panel.visible = false
		add_child(hover_description_panel)

		var style := _create_panel_style(Color(0.93, 0.93, 0.9, 0.96), Color(0.1, 0.1, 0.1, 0.58), 0, 10)
		style.content_margin_left = 16
		style.content_margin_top = 14
		style.content_margin_right = 16
		style.content_margin_bottom = 14
		hover_description_panel.add_theme_stylebox_override("panel", style)

		hover_description_label = Label.new()
		hover_description_panel.add_child(hover_description_label)
		hover_description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hover_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		hover_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hover_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hover_description_label.add_theme_font_size_override("font_size", 16)
		hover_description_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))
	elif hover_description_label == null or !is_instance_valid(hover_description_label):
		if hover_description_panel.get_child_count() > 0:
			hover_description_label = hover_description_panel.get_child(0) as Label

func _layout_hover_description_panel() -> void:
	if hover_description_panel == null or !is_instance_valid(hover_description_panel):
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var target_position := Vector2(74.0, TOP_BAR_HEIGHT + 22.0)
	if magnifier_enabled and magnifier_group != null and is_instance_valid(magnifier_group):
		target_position = magnifier_group.position + Vector2(MAGNIFIER_LENS_SIZE.x + 12.0, 8.0)
		if target_position.x + HOVER_DESCRIPTION_SIZE.x > viewport_size.x - 12.0:
			target_position.x = magnifier_group.position.x - HOVER_DESCRIPTION_SIZE.x - 12.0
	elif magnifier_case_button != null and is_instance_valid(magnifier_case_button):
		var case_size := magnifier_case_button.size
		if case_size == Vector2.ZERO:
			case_size = MAGNIFIER_CASE_DEFAULT_SIZE
		target_position = magnifier_case_button.position + Vector2(case_size.x + 12.0, -2.0)

	hover_description_panel.size = HOVER_DESCRIPTION_SIZE
	target_position.x = clampf(target_position.x, 12.0, maxf(12.0, viewport_size.x - HOVER_DESCRIPTION_SIZE.x - 12.0))
	target_position.y = clampf(target_position.y, TOP_BAR_HEIGHT + 8.0, maxf(TOP_BAR_HEIGHT + 8.0, viewport_size.y - HOVER_DESCRIPTION_SIZE.y - 12.0))
	hover_description_panel.position = target_position

func _build_ui() -> void:
	_setup_grid_background()
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

	card_description_panel = null
	card_description_label = null
	preview_card_holder = null
	preview_card_visual = null

	create_pack_inventory_ui()

	middle_column = VBoxContainer.new()
	main_layout.add_child(middle_column)
	middle_column.custom_minimum_size = Vector2(MIDDLE_COLUMN_WIDTH, 0)
	middle_column.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var browser_frame := PanelContainer.new()
	middle_column.add_child(browser_frame)
	browser_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	browser_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	browser_frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	browser = VBoxContainer.new()
	browser_frame.add_child(browser)
	browser.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	browser.size_flags_vertical = Control.SIZE_EXPAND_FILL
	browser.add_theme_constant_override("separation", 4)

	var browser_title := Label.new()
	browser.add_child(browser_title)
	browser_title.visible = false
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
	card_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card_grid.add_theme_constant_override("h_separation", 8)
	card_grid.add_theme_constant_override("v_separation", 2)

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
	deck_panel_frame.add_theme_stylebox_override("panel", _create_panel_style(Color(0.93, 0.93, 0.9), Color.TRANSPARENT, 0, 10))

	right_column = VBoxContainer.new()
	deck_panel_frame.add_child(right_column)
	right_column.custom_minimum_size = Vector2(RIGHT_COLUMN_WIDTH, 0)
	right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.add_theme_constant_override("separation", 12)

	deck_title_label = Label.new()
	right_column.add_child(deck_title_label)
	deck_title_label.text = "My codexes"
	deck_title_label.add_theme_font_size_override("font_size", 22)
	deck_title_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))
	deck_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	new_deck_button = Button.new()
	right_column.add_child(new_deck_button)
	new_deck_button.text = "New codex"
	new_deck_button.custom_minimum_size = Vector2(0, 42)
	new_deck_button.pressed.connect(_on_new_deck_pressed)

	deck_editor_back_button = Button.new()
	right_column.add_child(deck_editor_back_button)
	deck_editor_back_button.text = "Cancel"
	deck_editor_back_button.custom_minimum_size = Vector2(0, 42)
	deck_editor_back_button.visible = false
	deck_editor_back_button.pressed.connect(_on_deck_editor_back_pressed)

	deck_name_display = Label.new()
	right_column.add_child(deck_name_display)
	_configure_deck_name_display()
	deck_name_display.gui_input.connect(_on_deck_name_display_gui_input)

	deck_name_edit = LineEdit.new()
	right_column.add_child(deck_name_edit)
	deck_name_edit.placeholder_text = "Codex name"
	deck_name_edit.custom_minimum_size = Vector2(0, 40)
	deck_name_edit.visible = false
	deck_name_edit.text_changed.connect(_on_deck_name_changed)
	deck_name_edit.text_submitted.connect(_on_deck_name_edit_submitted)
	deck_name_edit.focus_exited.connect(_finish_deck_name_edit)
	_sync_deck_name_display()

	deck_list_scroll = ScrollContainer.new()
	right_column.add_child(deck_list_scroll)
	deck_list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	deck_list_scroll.clip_contents = true
	deck_list_scroll.gui_input.connect(_on_deck_selector_scroll_gui_input)

	deck_list = VBoxContainer.new()
	deck_list_scroll.add_child(deck_list)
	deck_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_list.clip_contents = false
	deck_list.mouse_filter = Control.MOUSE_FILTER_PASS
	deck_list.add_theme_constant_override("separation", 8)

	deck_card_scroll = ScrollContainer.new()
	right_column.add_child(deck_card_scroll)
	deck_card_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_card_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	deck_card_scroll.clip_contents = true
	deck_card_scroll.visible = false
	deck_card_scroll.resized.connect(_on_deck_card_scroll_resized)
	deck_card_scroll.gui_input.connect(_on_codex_scroll_gui_input)

	deck_card_list = VBoxContainer.new()
	deck_card_scroll.add_child(deck_card_list)
	deck_card_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_card_list.clip_contents = false
	deck_card_list.add_theme_constant_override("separation", CODEX_EDITOR_LIST_SPACING)

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
	_configure_inventory_block()
	_move_pack_panel_under_browser()
	_remove_card_info_panel()
	_setup_hover_description_panel()
	_setup_magnifier()

func _setup_grid_background() -> void:
	if grid_background_material == null:
		grid_background_material = ShaderMaterial.new()
		grid_background_material.shader = GRID_BACKGROUND_SHADER
		grid_background_material.set_shader_parameter("base_color", STACKBUILDER_BACKGROUND_COLOR)
		grid_background_material.set_shader_parameter("line_color", STACKBUILDER_GRID_LINE_COLOR)
		grid_background_material.set_shader_parameter("cell_size", 32.0)
		grid_background_material.set_shader_parameter("line_width", 0.65)

	if grid_background == null or !is_instance_valid(grid_background):
		grid_background = get_node_or_null("GridBackground") as ColorRect
	if grid_background == null:
		grid_background = ColorRect.new()
		grid_background.name = "GridBackground"
		add_child(grid_background)

	grid_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid_background.offset_left = 0.0
	grid_background.offset_top = 0.0
	grid_background.offset_right = 0.0
	grid_background.offset_bottom = 0.0
	grid_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid_background.color = STACKBUILDER_BACKGROUND_COLOR
	grid_background.material = grid_background_material
	move_child(grid_background, 0)

func _setup_magnifier() -> void:
	if magnifier_backbuffer == null or !is_instance_valid(magnifier_backbuffer):
		magnifier_backbuffer = BackBufferCopy.new()
		magnifier_backbuffer.name = "MagnifierBackBuffer"
		magnifier_backbuffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
		magnifier_backbuffer.z_as_relative = false
		magnifier_backbuffer.z_index = MAGNIFIER_Z_INDEX - 1
		magnifier_backbuffer.visible = false
		add_child(magnifier_backbuffer)

	if magnifier_material == null:
		magnifier_material = ShaderMaterial.new()
		magnifier_material.shader = MAGNIFIER_SHADER
		magnifier_material.set_shader_parameter("zoom", 1.85)
		magnifier_material.set_shader_parameter("distortion", 0.12)
		magnifier_material.set_shader_parameter("edge_feather", 0.025)
		magnifier_material.set_shader_parameter("glass_tint", Color(0.9, 0.97, 1.0, 0.12))

	if magnifier_group == null or !is_instance_valid(magnifier_group):
		magnifier_group = Control.new()
		magnifier_group.name = "MagnifierLens"
		magnifier_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
		magnifier_group.clip_contents = false
		magnifier_group.size = MAGNIFIER_LENS_SIZE
		magnifier_group.z_as_relative = false
		magnifier_group.z_index = MAGNIFIER_Z_INDEX
		magnifier_group.visible = false
		add_child(magnifier_group)
		_build_magnifier_lens_visuals()

	_bind_magnifier_case_button()

	_layout_magnifier_case_button()
	_set_magnifier_enabled(magnifier_enabled)

func _bind_magnifier_case_button() -> void:
	var legacy_button := get_node_or_null("MagnifierButton") as Button
	if legacy_button != null:
		legacy_button.queue_free()

	magnifier_case_button = get_node_or_null("MagnifierCaseButton") as Control
	if magnifier_case_button == null or !is_instance_valid(magnifier_case_button):
		magnifier_case_button = _create_magnifier_case_button()

	magnifier_case_closed_image = magnifier_case_button.get_node_or_null("ClosedImage") as TextureRect
	magnifier_case_opened_image = magnifier_case_button.get_node_or_null("OpenedImage") as TextureRect
	magnifier_case_click_area = magnifier_case_button.get_node_or_null("ClickArea") as Button

	if magnifier_case_closed_image != null:
		magnifier_case_closed_image.texture = MAGNIFIER_CASE_CLOSED_TEXTURE
		magnifier_case_closed_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if magnifier_case_opened_image != null:
		magnifier_case_opened_image.texture = MAGNIFIER_CASE_OPENED_TEXTURE
		magnifier_case_opened_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if magnifier_case_click_area != null:
		magnifier_case_click_area.tooltip_text = "Magnifier"
		magnifier_case_click_area.flat = true
		magnifier_case_click_area.focus_mode = Control.FOCUS_NONE
		_connect_once(magnifier_case_click_area.pressed, Callable(self, "_on_magnifier_case_pressed"))

	magnifier_case_button.z_as_relative = false
	magnifier_case_button.z_index = MAGNIFIER_Z_INDEX + 10
	magnifier_case_button.pivot_offset = magnifier_case_button.size * 0.5
	_set_magnifier_case_opened(magnifier_enabled)

func _create_magnifier_case_button() -> Control:
	var case_button := Control.new()
	case_button.name = "MagnifierCaseButton"
	case_button.size = MAGNIFIER_CASE_DEFAULT_SIZE
	case_button.position = Vector2(16.0, TOP_BAR_HEIGHT + 22.0)
	case_button.pivot_offset = MAGNIFIER_CASE_DEFAULT_SIZE * 0.5
	case_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(case_button)

	var closed_image := TextureRect.new()
	closed_image.name = "ClosedImage"
	_configure_magnifier_case_image(closed_image, MAGNIFIER_CASE_CLOSED_TEXTURE)
	case_button.add_child(closed_image)

	var opened_image := TextureRect.new()
	opened_image.name = "OpenedImage"
	_configure_magnifier_case_image(opened_image, MAGNIFIER_CASE_OPENED_TEXTURE)
	opened_image.visible = false
	case_button.add_child(opened_image)

	var click_area := Button.new()
	click_area.name = "ClickArea"
	click_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	click_area.tooltip_text = "Magnifier"
	click_area.focus_mode = Control.FOCUS_NONE
	click_area.flat = true
	case_button.add_child(click_area)

	return case_button

func _configure_magnifier_case_image(image: TextureRect, texture: Texture2D) -> void:
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _build_magnifier_lens_visuals() -> void:
	if magnifier_group == null:
		return

	for child in magnifier_group.get_children():
		magnifier_group.remove_child(child)
		child.queue_free()

	var lens := ColorRect.new()
	magnifier_group.add_child(lens)
	lens.name = "LensShader"
	lens.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lens.color = Color.WHITE
	lens.size = MAGNIFIER_LENS_SIZE
	lens.material = magnifier_material
	lens.z_index = 1
	magnifier_screen_lens = lens

	var glass_scale: float = MAGNIFIER_LENS_SIZE.x / MAGNIFIER_GLASS_LENS_SOURCE_RECT.size.x
	var glass_overlay := TextureRect.new()
	magnifier_group.add_child(glass_overlay)
	glass_overlay.name = "GlassOverlay"
	glass_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glass_overlay.texture = MAGNIFIER_GLASS_TEXTURE
	glass_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	glass_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glass_overlay.stretch_mode = TextureRect.STRETCH_SCALE
	glass_overlay.size = MAGNIFIER_GLASS_SOURCE_SIZE * glass_scale
	glass_overlay.position = -MAGNIFIER_GLASS_LENS_SOURCE_RECT.position * glass_scale
	glass_overlay.pivot_offset = (MAGNIFIER_GLASS_LENS_SOURCE_RECT.position + MAGNIFIER_GLASS_LENS_SOURCE_RECT.size * 0.5) * glass_scale
	glass_overlay.rotation = deg_to_rad(MAGNIFIER_GLASS_ROTATION_DEGREES)
	glass_overlay.z_index = 3

func _layout_magnifier_case_button() -> void:
	if magnifier_case_button == null:
		return

	if magnifier_case_button.size == Vector2.ZERO:
		magnifier_case_button.size = MAGNIFIER_CASE_DEFAULT_SIZE
	magnifier_case_button.pivot_offset = magnifier_case_button.size * 0.5
	if hover_description_panel != null and hover_description_panel.visible:
		_layout_hover_description_panel()

func _on_magnifier_case_pressed() -> void:
	if magnifier_case_button == null:
		return

	var next_enabled := !magnifier_enabled
	if magnifier_case_tween != null and magnifier_case_tween.is_valid():
		magnifier_case_tween.kill()

	magnifier_case_button.pivot_offset = magnifier_case_button.size * 0.5
	magnifier_case_tween = create_tween()
	magnifier_case_tween.set_trans(Tween.TRANS_SINE)
	magnifier_case_tween.set_ease(Tween.EASE_IN_OUT)
	magnifier_case_tween.tween_property(magnifier_case_button, "scale", Vector2.ONE * MAGNIFIER_CASE_PRESSED_SCALE, MAGNIFIER_CASE_PRESS_IN_SECONDS)
	magnifier_case_tween.tween_callback(func():
		_set_magnifier_case_opened(next_enabled)
		_set_magnifier_enabled(next_enabled)
	)
	magnifier_case_tween.tween_property(magnifier_case_button, "scale", Vector2.ONE, MAGNIFIER_CASE_PRESS_OUT_SECONDS)

func _set_magnifier_case_opened(is_opened: bool) -> void:
	if magnifier_case_closed_image != null and is_instance_valid(magnifier_case_closed_image):
		magnifier_case_closed_image.visible = !is_opened
	if magnifier_case_opened_image != null and is_instance_valid(magnifier_case_opened_image):
		magnifier_case_opened_image.visible = is_opened

func _set_magnifier_enabled(is_enabled: bool) -> void:
	var was_enabled: bool = magnifier_enabled
	if is_enabled && !was_enabled:
		magnifier_previous_mouse_mode = Input.get_mouse_mode()

	magnifier_enabled = is_enabled
	_set_magnifier_case_opened(is_enabled)
	if magnifier_group != null:
		magnifier_group.visible = is_enabled
	if magnifier_backbuffer != null:
		magnifier_backbuffer.visible = is_enabled

	if is_enabled:
		if !was_enabled:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		_update_magnifier_position(true)
	elif was_enabled:
		Input.set_mouse_mode(magnifier_previous_mouse_mode)

func _update_magnifier_position(force_update: bool = false) -> void:
	if !magnifier_enabled && !force_update:
		return
	if magnifier_group == null or magnifier_material == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var half_lens_size: Vector2 = MAGNIFIER_LENS_SIZE * 0.5
	var lens_position: Vector2 = mouse_position - half_lens_size
	lens_position.x = clampf(lens_position.x, 0.0, maxf(0.0, viewport_size.x - MAGNIFIER_LENS_SIZE.x))
	lens_position.y = clampf(lens_position.y, TOP_BAR_HEIGHT, maxf(TOP_BAR_HEIGHT, viewport_size.y - MAGNIFIER_LENS_SIZE.y))
	magnifier_group.position = lens_position

	var lens_center: Vector2 = lens_position + half_lens_size
	magnifier_material.set_shader_parameter("center_screen_uv", Vector2(lens_center.x / viewport_size.x, lens_center.y / viewport_size.y))
	if hover_description_panel != null and hover_description_panel.visible:
		_layout_hover_description_panel()

func _create_panel_style(bg_color: Color, border_color: Color, radius_top: int, radius_bottom: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	var border_width: int = 0 if border_color.a <= 0.0 else 1
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
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
		deck_list.add_child(_create_editor_deck_row("Codex %d" % (i + 1)))

func _create_editor_deck_row(deck_name: String) -> Control:
	var row_frame := Control.new()
	row_frame.custom_minimum_size = Vector2(0, 148)
	row_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_frame.mouse_filter = Control.MOUSE_FILTER_PASS
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
	front_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	front_panel.anchor_left = 0.0
	front_panel.anchor_top = 0.0
	front_panel.anchor_right = 1.0
	front_panel.anchor_bottom = 1.0
	front_panel.offset_top = 64.0
	front_panel.add_theme_stylebox_override("panel", _create_dark_panel_style(0, 20))

	var content := VBoxContainer.new()
	front_panel.add_child(content)
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	content.add_child(name_label)
	name_label.text = deck_name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.9))

	var footer := HBoxContainer.new()
	content.add_child(footer)
	footer.mouse_filter = Control.MOUSE_FILTER_PASS
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

	footer.add_child(_create_circle_icon_button("E", "Edit codex"))
	footer.add_child(_create_circle_icon_button("X", "Delete codex"))
	return row_frame

func create_top_progress_ui() -> void:
	var top_background := ColorRect.new()
	top_background.name = "TopBackground"
	add_child(top_background)
	top_background.anchor_left = 0.0
	top_background.anchor_right = 1.0
	top_background.anchor_top = 0.0
	top_background.anchor_bottom = 0.0
	top_background.offset_left = 0.0
	top_background.offset_top = 0.0
	top_background.offset_right = 0.0
	top_background.offset_bottom = TOP_BAR_HEIGHT
	top_background.color = TOP_BAR_BACKGROUND_COLOR

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

	var point_icon := TextureRect.new()
	points_container.add_child(point_icon)
	point_icon.custom_minimum_size = Vector2(24, 24)
	point_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	point_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	point_icon.texture = COIN_TEXTURE
	point_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	point_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	points_label = Label.new()
	points_container.add_child(points_label)
	points_label.custom_minimum_size = Vector2(70, 32)
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	points_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_label.add_theme_font_size_override("font_size", 20)
	points_label.add_theme_color_override("font_color", Color(0.07, 0.055, 0.095))

func create_pack_inventory_ui() -> void:
	if left_column == null:
		return

	pack_panel = PanelContainer.new()
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
	card_visual.position = (available_size - CARD_VISUAL_SIZE * scale_factor) * 0.5 + Vector2(0.0, BROWSER_CARD_VERTICAL_OFFSET)
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

	return minf(slot_size.x / CARD_VISUAL_SIZE.x, slot_size.y / CARD_VISUAL_SIZE.y) * CARD_SLOT_SCALE_MULTIPLIER

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
	_sync_deck_card_list_width()
	_layout_magnifier_case_button()
	_update_magnifier_position(true)
	_layout_hover_description_panel()

func _apply_responsive_layout(refresh_page: bool) -> void:
	var viewport_width: float = get_viewport_rect().size.x
	var viewport_height: float = get_viewport_rect().size.y
	var next_columns: int = DESKTOP_CARD_COLUMNS
	var next_cards_per_page: int = DESKTOP_CARDS_PER_PAGE
	var next_card_slot_size: Vector2 = DESKTOP_CARD_SLOT_SIZE
	var next_margin: int = 24
	var next_h_gap: int = 8
	var next_v_gap: int = 2
	var next_layout_gap: int = 14
	var next_layout_width: int = LAYOUT_WIDTH
	var next_left_width: int = 0
	var next_middle_width: int = MIDDLE_COLUMN_WIDTH
	var next_deck_width: int = RIGHT_COLUMN_WIDTH

	if viewport_width < 980.0:
		next_columns = COMPACT_CARD_COLUMNS
		next_cards_per_page = COMPACT_CARDS_PER_PAGE
		next_card_slot_size = COMPACT_CARD_SLOT_SIZE
		next_margin = 16
		next_h_gap = 6
		next_v_gap = 3
		next_layout_gap = 12
		next_middle_width = 360
		next_deck_width = RIGHT_COLUMN_WIDTH
		next_layout_width = next_middle_width + next_deck_width + next_layout_gap
	elif viewport_width < 1180.0:
		next_columns = MEDIUM_CARD_COLUMNS
		next_cards_per_page = MEDIUM_CARDS_PER_PAGE
		next_card_slot_size = MEDIUM_CARD_SLOT_SIZE
		next_margin = 18
		next_h_gap = 7
		next_v_gap = 3
		next_layout_gap = 12
		next_middle_width = 460
		next_deck_width = RIGHT_COLUMN_WIDTH
		next_layout_width = next_middle_width + next_deck_width + next_layout_gap

	var layout_changed: bool = next_columns != current_card_columns or next_cards_per_page != current_cards_per_page
	current_card_columns = next_columns
	current_cards_per_page = next_cards_per_page
	current_card_slot_size = next_card_slot_size
	var available_height: int = maxi(360, int(viewport_height) - TOP_BAR_HEIGHT - next_margin * 2)

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
		left_column.visible = false
	if middle_column != null:
		middle_column.custom_minimum_size = Vector2(next_middle_width, 0)
	if pack_panel != null:
		pack_panel.custom_minimum_size = Vector2(0, clampi(available_height - 560, PACK_PANEL_MIN_HEIGHT, LEFT_PACK_HEIGHT))
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

func _on_deck_card_scroll_resized() -> void:
	_sync_deck_card_list_width()

func _sync_deck_card_list_width() -> void:
	if deck_card_scroll == null or deck_card_list == null:
		return
	var content_width: float = deck_card_scroll.size.x
	if content_width <= 0.0:
		content_width = right_column.size.x if right_column != null else float(RIGHT_COLUMN_WIDTH)
	content_width = maxf(0.0, content_width)
	deck_card_list.custom_minimum_size = Vector2(content_width, deck_card_list.custom_minimum_size.y)
	for child in deck_card_list.get_children():
		if child is Control and child.has_meta("codex_page_grid_wrapper"):
			var wrapper := child as Control
			wrapper.custom_minimum_size = Vector2(content_width, DECK_EDIT_CARD_SLOT_SIZE.y)

func _on_codex_scroll_gui_input(event: InputEvent) -> void:
	if deck_card_scroll == null or !is_creating_deck or !deck_card_scroll.visible:
		return
	if _handle_codex_scroll_wheel(event):
		deck_card_scroll.accept_event()

func _on_deck_selector_scroll_gui_input(event: InputEvent) -> void:
	if deck_list_scroll == null or is_creating_deck or !deck_list_scroll.visible:
		return
	if _handle_deck_selector_scroll_wheel(event):
		deck_list_scroll.accept_event()

func _handle_elastic_scroll_unhandled_input(event: InputEvent) -> bool:
	if !(event is InputEventMouseButton):
		return false
	var mouse_position := get_viewport().get_mouse_position()
	if is_creating_deck and deck_card_scroll != null and deck_card_scroll.visible and deck_card_scroll.get_global_rect().has_point(mouse_position):
		return _handle_codex_scroll_wheel(event)
	if !is_creating_deck and deck_list_scroll != null and deck_list_scroll.visible and deck_list_scroll.get_global_rect().has_point(mouse_position):
		return _handle_deck_selector_scroll_wheel(event)
	return false

func _handle_codex_scroll_wheel(event: InputEvent) -> bool:
	var direction: float = _get_scroll_wheel_direction(event)
	if direction == 0.0:
		return false

	var max_scroll: float = _get_codex_scroll_max()
	var current_scroll: float = float(deck_card_scroll.scroll_vertical)
	if max_scroll <= 0.0 or (current_scroll <= 0.0 and direction < 0.0) or (current_scroll >= max_scroll and direction > 0.0):
		codex_scroll_overshoot_velocity += -direction * CODEX_SCROLL_EDGE_IMPULSE
	else:
		codex_scroll_velocity = clampf(
			codex_scroll_velocity + direction * CODEX_SCROLL_WHEEL_IMPULSE,
			-CODEX_SCROLL_MAX_VELOCITY,
			CODEX_SCROLL_MAX_VELOCITY
		)
	return true

func _handle_deck_selector_scroll_wheel(event: InputEvent) -> bool:
	var direction: float = _get_scroll_wheel_direction(event)
	if direction == 0.0:
		return false

	var max_scroll: float = _get_deck_selector_scroll_max()
	var current_scroll: float = float(deck_list_scroll.scroll_vertical)
	if max_scroll <= 0.0 or (current_scroll <= 0.0 and direction < 0.0) or (current_scroll >= max_scroll and direction > 0.0):
		deck_selector_scroll_overshoot_velocity += -direction * CODEX_SCROLL_EDGE_IMPULSE
	else:
		deck_selector_scroll_velocity = clampf(
			deck_selector_scroll_velocity + direction * CODEX_SCROLL_WHEEL_IMPULSE,
			-CODEX_SCROLL_MAX_VELOCITY,
			CODEX_SCROLL_MAX_VELOCITY
		)
	return true

func _get_scroll_wheel_direction(event: InputEvent) -> float:
	if !(event is InputEventMouseButton):
		return 0.0
	var mouse_button := event as InputEventMouseButton
	if !mouse_button.pressed:
		return 0.0
	if mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		return 1.0
	if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP:
		return -1.0
	return 0.0

func _update_codex_scroll_inertia(delta: float) -> void:
	if deck_card_scroll == null or deck_card_list == null:
		return
	if !is_creating_deck or !deck_card_scroll.visible:
		_reset_codex_scroll_motion()
		return

	var max_scroll: float = _get_codex_scroll_max()
	if max_scroll <= 0.0:
		codex_scroll_velocity = 0.0
	else:
		var current_scroll: float = clampf(float(deck_card_scroll.scroll_vertical), 0.0, max_scroll)
		if absf(codex_scroll_velocity) > 0.5:
			var next_scroll: float = current_scroll + codex_scroll_velocity * delta
			if next_scroll < 0.0:
				codex_scroll_overshoot_velocity += -next_scroll * CODEX_SCROLL_EDGE_SPRING
				next_scroll = 0.0
				codex_scroll_velocity *= 0.16
			elif next_scroll > max_scroll:
				codex_scroll_overshoot_velocity -= (next_scroll - max_scroll) * CODEX_SCROLL_EDGE_SPRING
				next_scroll = max_scroll
				codex_scroll_velocity *= 0.16
			deck_card_scroll.scroll_vertical = int(round(next_scroll))
			var friction_weight: float = 1.0 - exp(-CODEX_SCROLL_FRICTION * delta)
			codex_scroll_velocity = lerpf(codex_scroll_velocity, 0.0, friction_weight)
		else:
			codex_scroll_velocity = 0.0

	var spring_acceleration: float = -codex_scroll_overshoot * CODEX_SCROLL_EDGE_SPRING - codex_scroll_overshoot_velocity * CODEX_SCROLL_EDGE_DAMPING
	codex_scroll_overshoot_velocity += spring_acceleration * delta
	codex_scroll_overshoot += codex_scroll_overshoot_velocity * delta
	codex_scroll_overshoot = clampf(codex_scroll_overshoot, -CODEX_SCROLL_MAX_OVERSHOOT, CODEX_SCROLL_MAX_OVERSHOOT)
	if absf(codex_scroll_overshoot) < 0.1 and absf(codex_scroll_overshoot_velocity) < 0.1:
		codex_scroll_overshoot = 0.0
		codex_scroll_overshoot_velocity = 0.0
	_apply_codex_scroll_elastic_visual()

func _update_deck_selector_scroll_inertia(delta: float) -> void:
	if deck_list_scroll == null or deck_list == null:
		return
	if is_creating_deck or !deck_list_scroll.visible:
		_reset_deck_selector_scroll_motion()
		return

	var max_scroll: float = _get_deck_selector_scroll_max()
	if max_scroll <= 0.0:
		deck_selector_scroll_velocity = 0.0
	else:
		var current_scroll: float = clampf(float(deck_list_scroll.scroll_vertical), 0.0, max_scroll)
		if absf(deck_selector_scroll_velocity) > 0.5:
			var next_scroll: float = current_scroll + deck_selector_scroll_velocity * delta
			if next_scroll < 0.0:
				deck_selector_scroll_overshoot_velocity += -next_scroll * CODEX_SCROLL_EDGE_SPRING
				next_scroll = 0.0
				deck_selector_scroll_velocity *= 0.16
			elif next_scroll > max_scroll:
				deck_selector_scroll_overshoot_velocity -= (next_scroll - max_scroll) * CODEX_SCROLL_EDGE_SPRING
				next_scroll = max_scroll
				deck_selector_scroll_velocity *= 0.16
			deck_list_scroll.scroll_vertical = int(round(next_scroll))
			var friction_weight: float = 1.0 - exp(-CODEX_SCROLL_FRICTION * delta)
			deck_selector_scroll_velocity = lerpf(deck_selector_scroll_velocity, 0.0, friction_weight)
		else:
			deck_selector_scroll_velocity = 0.0

	var spring_acceleration: float = -deck_selector_scroll_overshoot * CODEX_SCROLL_EDGE_SPRING - deck_selector_scroll_overshoot_velocity * CODEX_SCROLL_EDGE_DAMPING
	deck_selector_scroll_overshoot_velocity += spring_acceleration * delta
	deck_selector_scroll_overshoot += deck_selector_scroll_overshoot_velocity * delta
	deck_selector_scroll_overshoot = clampf(deck_selector_scroll_overshoot, -CODEX_SCROLL_MAX_OVERSHOOT, CODEX_SCROLL_MAX_OVERSHOOT)
	if absf(deck_selector_scroll_overshoot) < 0.1 and absf(deck_selector_scroll_overshoot_velocity) < 0.1:
		deck_selector_scroll_overshoot = 0.0
		deck_selector_scroll_overshoot_velocity = 0.0
	_apply_deck_selector_scroll_elastic_visual()

func _get_codex_scroll_max() -> float:
	if deck_card_scroll == null or deck_card_list == null:
		return 0.0
	var scroll_bar := deck_card_scroll.get_v_scroll_bar()
	if scroll_bar != null:
		return maxf(0.0, scroll_bar.max_value - scroll_bar.page)
	var content_height: float = maxf(deck_card_list.size.y, deck_card_list.get_combined_minimum_size().y)
	return maxf(0.0, content_height - deck_card_scroll.size.y)

func _get_deck_selector_scroll_max() -> float:
	if deck_list_scroll == null or deck_list == null:
		return 0.0
	var scroll_bar := deck_list_scroll.get_v_scroll_bar()
	if scroll_bar != null:
		return maxf(0.0, scroll_bar.max_value - scroll_bar.page)
	var content_height: float = maxf(deck_list.size.y, deck_list.get_combined_minimum_size().y)
	return maxf(0.0, content_height - deck_list_scroll.size.y)

func _apply_codex_scroll_elastic_visual() -> void:
	if deck_card_scroll == null or deck_card_list == null:
		return
	var scroll_y: float = float(deck_card_scroll.scroll_vertical)
	deck_card_list.scale = Vector2.ONE
	deck_card_list.position.y = round(-scroll_y + codex_scroll_overshoot)

func _apply_deck_selector_scroll_elastic_visual() -> void:
	if deck_list_scroll == null or deck_list == null:
		return
	var scroll_y: float = float(deck_list_scroll.scroll_vertical)
	deck_list.scale = Vector2.ONE
	deck_list.position.y = round(-scroll_y + deck_selector_scroll_overshoot)

func _reset_codex_scroll_motion() -> void:
	codex_scroll_velocity = 0.0
	codex_scroll_overshoot = 0.0
	codex_scroll_overshoot_velocity = 0.0
	if deck_card_list != null:
		deck_card_list.scale = Vector2.ONE
		if deck_card_scroll != null:
			deck_card_list.position.y = -float(deck_card_scroll.scroll_vertical)

func _reset_deck_selector_scroll_motion() -> void:
	deck_selector_scroll_velocity = 0.0
	deck_selector_scroll_overshoot = 0.0
	deck_selector_scroll_overshoot_velocity = 0.0
	if deck_list != null:
		deck_list.scale = Vector2.ONE
		if deck_list_scroll != null:
			deck_list.position.y = -float(deck_list_scroll.scroll_vertical)

func _on_previous_pressed() -> void:
	_show_page(current_page - 1)

func _on_next_pressed() -> void:
	_show_page(current_page + 1)

func _on_search_text_changed(_new_text: String) -> void:
	_refresh_card_filter(true)

func _on_owned_only_toggled(_pressed: bool) -> void:
	_refresh_card_filter(true)

func _ensure_deck_name_display() -> void:
	if deck_name_edit == null:
		return
	var parent := deck_name_edit.get_parent()
	if parent == null:
		return
	deck_name_display = parent.get_node_or_null("DeckNameDisplay") as Label
	if deck_name_display == null:
		deck_name_display = Label.new()
		deck_name_display.name = "DeckNameDisplay"
		parent.add_child(deck_name_display)
		parent.move_child(deck_name_display, deck_name_edit.get_index())
	_configure_deck_name_display()

func _configure_deck_name_display() -> void:
	if deck_name_display == null:
		return
	deck_name_display.custom_minimum_size = Vector2(0.0, 40.0)
	deck_name_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_name_display.visible = false
	deck_name_display.mouse_filter = Control.MOUSE_FILTER_STOP
	deck_name_display.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	deck_name_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_name_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	deck_name_display.clip_text = true
	deck_name_display.add_theme_font_override("font", CODEX_TITLE_FONT)
	deck_name_display.add_theme_font_size_override("font_size", 22)
	_sync_deck_name_display()

func _sync_deck_name_display() -> void:
	if deck_name_display == null or deck_name_edit == null:
		return
	var name_text: String = deck_name_edit.text.strip_edges()
	deck_name_display.text = name_text if !name_text.is_empty() else "New"
	deck_name_display.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08) if !name_text.is_empty() else Color(0.26, 0.26, 0.24))

func _on_deck_name_display_gui_input(event: InputEvent) -> void:
	if !is_creating_deck:
		return
	if !(event is InputEventMouseButton):
		return
	var mouse_button := event as InputEventMouseButton
	if mouse_button.button_index != MOUSE_BUTTON_LEFT or !mouse_button.pressed:
		return
	accept_event()
	_start_deck_name_edit()

func _start_deck_name_edit() -> void:
	if !is_creating_deck:
		return
	is_editing_deck_name = true
	_update_deck_editor_state()
	call_deferred("_focus_deck_name_edit")

func _focus_deck_name_edit() -> void:
	if deck_name_edit == null or !deck_name_edit.visible:
		return
	deck_name_edit.grab_focus()
	deck_name_edit.select_all()

func _finish_deck_name_edit() -> void:
	if !is_editing_deck_name:
		return
	is_editing_deck_name = false
	_sync_deck_name_display()
	_update_deck_editor_state()

func _on_deck_name_edit_submitted(_new_text: String) -> void:
	_finish_deck_name_edit()

func _on_new_deck_pressed() -> void:
	is_creating_deck = true
	editing_deck_id = ""
	editing_deck_has_missing_cards = false
	is_editing_deck_name = false
	selected_deck_cards.clear()
	_ensure_selected_deck_slots()
	dragged_print_id = ""
	hovered_deck_card_index = -1
	deck_name_edit.text = ""
	_sync_deck_name_display()
	_hide_remove_card_button()
	_refresh_selected_deck_cards()
	_update_deck_editor_state()
	_show_page(current_page)

func _on_deck_editor_back_pressed() -> void:
	is_creating_deck = false
	editing_deck_id = ""
	editing_deck_has_missing_cards = false
	is_editing_deck_name = false
	selected_deck_cards.clear()
	dragged_print_id = ""
	hovered_deck_card_index = -1
	_hide_remove_card_button()
	_refresh_selected_deck_cards()
	_update_deck_editor_state()
	_show_page(current_page)

func _on_deck_name_changed(_new_text: String) -> void:
	_sync_deck_name_display()
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
	if card_grid == null or hover_description_label == null:
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
	if hover_description_label != null:
		hover_description_label.text = ""
	if hover_description_panel != null:
		hover_description_panel.visible = false

func _show_card_preview(card: Card, card_print: CardPrint = null) -> void:
	if card == null:
		return

	hovered_browser_card_name = card.card_name
	var description: String = card.description.strip_edges()
	if hover_description_label != null:
		hover_description_label.text = description
	if hover_description_panel != null:
		hover_description_panel.visible = !description.is_empty()
		if hover_description_panel.visible:
			_layout_hover_description_panel()

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
		var drop_index: int = _get_deck_drop_index(mouse_position)
		if drop_index >= 0 && !_is_deck_slot_empty(drop_index):
			drop_index = -1
		if drop_index == -1:
			drop_index = _get_first_empty_deck_slot()
		if drop_index != -1:
			_set_deck_slot(drop_index, _create_deck_card_entry(print_id, drop_index))
		_reindex_selected_deck_cards()
		_refresh_selected_deck_cards()
		_update_deck_editor_state()

	dragged_print_id = ""
	call_deferred("_show_page", current_page)

func _get_deck_drop_index(mouse_position: Vector2) -> int:
	if deck_card_list == null:
		return -1
	return _find_deck_slot_index_at_position(deck_card_list, mouse_position)

func _find_deck_slot_index_at_position(node: Node, mouse_position: Vector2) -> int:
	for child in node.get_children():
		if child is Control:
			var control := child as Control
			if control.has_meta("deck_slot_index") and control.get_global_rect().has_point(mouse_position):
				return int(control.get_meta("deck_slot_index"))
		var nested_index: int = _find_deck_slot_index_at_position(child, mouse_position)
		if nested_index != -1:
			return nested_index
	return -1

func _on_done_pressed() -> void:
	if !_can_complete_deck():
		return

	var cards_to_save: Array = _get_selected_deck_cards_for_save()
	if editing_deck_id.is_empty():
		PlayerDeckStore.save_new_deck(deck_name_edit.text, cards_to_save)
	else:
		PlayerDeckStore.save_existing_deck(editing_deck_id, deck_name_edit.text, cards_to_save)
	is_creating_deck = false
	editing_deck_id = ""
	editing_deck_has_missing_cards = false
	is_editing_deck_name = false
	selected_deck_cards.clear()
	deck_name_edit.text = ""
	_sync_deck_name_display()
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

	if deck_title_label != null:
		deck_title_label.visible = !is_creating_deck
	new_deck_button.visible = !is_creating_deck
	deck_editor_back_button.visible = is_creating_deck
	if !is_creating_deck:
		is_editing_deck_name = false
	if deck_name_display != null:
		deck_name_display.visible = is_creating_deck && !is_editing_deck_name
	deck_name_edit.visible = is_creating_deck && is_editing_deck_name
	deck_list_scroll.visible = !is_creating_deck
	deck_card_scroll.visible = is_creating_deck
	deck_count_label.visible = is_creating_deck
	done_button.visible = is_creating_deck
	_sync_deck_card_list_width()
	deck_count_label.text = "%d/%d" % [_get_selected_deck_card_count(), MAX_DECK_SIZE]
	done_button.disabled = !_can_complete_deck()

	for child in card_grid.get_children():
		var visual: CardVisual = _get_browser_card_visual(child)
		if visual != null:
			visual.draggable = is_creating_deck && !editing_deck_has_missing_cards && visual.collection_owned && _can_add_card_to_deck(visual.card) && _get_selected_deck_card_count() < MAX_DECK_SIZE
			visual.disabled = !visual.collection_owned

func _can_complete_deck() -> bool:
	return is_creating_deck && !editing_deck_has_missing_cards && !deck_name_edit.text.strip_edges().is_empty() && _get_selected_deck_card_count() == MAX_DECK_SIZE && _has_selected_nexus_card() && !_has_too_many_card_copies()

func _can_add_print_to_deck(print_id: String) -> bool:
	if editing_deck_has_missing_cards:
		return false

	var card_print: CardPrint = CardPrintLibrary.get_print(print_id)
	var card: Card = CardPrintLibrary.get_card_for_print(card_print)
	return card != null && PlayerCollectionStore.owns_print(card_print) && _can_add_card_to_deck(card) && _get_selected_deck_card_count() < MAX_DECK_SIZE

func _reindex_selected_deck_cards() -> void:
	_ensure_selected_deck_slots()
	for index in range(selected_deck_cards.size()):
		if selected_deck_cards[index] is Dictionary:
			var deck_card: Dictionary = selected_deck_cards[index]
			deck_card["slot"] = index
			selected_deck_cards[index] = deck_card

func _ensure_selected_deck_slots() -> void:
	while selected_deck_cards.size() < MAX_DECK_SIZE:
		selected_deck_cards.append(null)
	if selected_deck_cards.size() > MAX_DECK_SIZE:
		selected_deck_cards.resize(MAX_DECK_SIZE)

func _get_selected_deck_card_count() -> int:
	var count: int = 0
	for deck_card in selected_deck_cards:
		if deck_card is Dictionary:
			count += 1
	return count

func _get_first_empty_deck_slot() -> int:
	_ensure_selected_deck_slots()
	for index in range(selected_deck_cards.size()):
		if _is_deck_slot_empty(index):
			return index
	return -1

func _is_deck_slot_empty(deck_card_index: int) -> bool:
	if deck_card_index < 0 or deck_card_index >= selected_deck_cards.size():
		return true
	return !(selected_deck_cards[deck_card_index] is Dictionary)

func _set_deck_slot(deck_card_index: int, deck_card) -> void:
	_ensure_selected_deck_slots()
	if deck_card_index < 0 or deck_card_index >= selected_deck_cards.size():
		return
	if deck_card is Dictionary:
		var normalized_card: Dictionary = (deck_card as Dictionary).duplicate(true)
		normalized_card["slot"] = deck_card_index
		selected_deck_cards[deck_card_index] = normalized_card
	else:
		selected_deck_cards[deck_card_index] = null

func _swap_or_move_deck_slots(source_index: int, target_index: int) -> void:
	_ensure_selected_deck_slots()
	if source_index < 0 or source_index >= selected_deck_cards.size():
		return
	if target_index < 0 or target_index >= selected_deck_cards.size():
		return
	if source_index == target_index:
		return
	if !(selected_deck_cards[source_index] is Dictionary):
		return

	var source_card = selected_deck_cards[source_index]
	var target_card = selected_deck_cards[target_index]
	selected_deck_cards[target_index] = source_card
	selected_deck_cards[source_index] = target_card if target_card is Dictionary else null
	_reindex_selected_deck_cards()

func _get_selected_deck_cards_for_save() -> Array:
	var cards: Array = []
	_ensure_selected_deck_slots()
	for index in range(selected_deck_cards.size()):
		var deck_card = selected_deck_cards[index]
		if !(deck_card is Dictionary):
			continue
		var saved_card: Dictionary = (deck_card as Dictionary).duplicate(true)
		saved_card["slot"] = index
		cards.append(saved_card)
	return cards

func _refresh_selected_deck_cards() -> void:
	_ensure_selected_deck_slots()
	_sync_deck_card_list_width()
	for child in deck_card_list.get_children():
		deck_card_list.remove_child(child)
		child.queue_free()

	for page_index in range(CODEX_PAGE_COUNT):
		_add_selected_deck_section("Page %d" % (page_index + 1), page_index)

func _add_selected_deck_section(title: String, page_index: int) -> void:
	var section_title := Label.new()
	deck_card_list.add_child(section_title)
	section_title.text = title
	section_title.custom_minimum_size = Vector2(0.0, 28.0)
	section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	section_title.add_theme_font_size_override("font_size", CODEX_PAGE_TITLE_FONT_SIZE)
	section_title.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))

	var section_line := HSeparator.new()
	deck_card_list.add_child(section_line)

	var section_grid_wrapper := CenterContainer.new()
	deck_card_list.add_child(section_grid_wrapper)
	section_grid_wrapper.set_meta("codex_page_grid_wrapper", true)
	section_grid_wrapper.custom_minimum_size = Vector2(_get_deck_card_list_content_width(), DECK_EDIT_CARD_SLOT_SIZE.y)
	section_grid_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_grid_wrapper.clip_contents = false

	var section_grid := GridContainer.new()
	section_grid_wrapper.add_child(section_grid)
	section_grid.columns = CODEX_STAMPS_PER_PAGE
	section_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	section_grid.clip_contents = false
	section_grid.add_theme_constant_override("h_separation", CODEX_PAGE_GRID_HORIZONTAL_GAP)
	section_grid.add_theme_constant_override("v_separation", 4)

	for page_slot in range(CODEX_STAMPS_PER_PAGE):
		var deck_card_index: int = page_index * CODEX_STAMPS_PER_PAGE + page_slot
		if deck_card_index < selected_deck_cards.size() and selected_deck_cards[deck_card_index] is Dictionary:
			var deck_card: Dictionary = selected_deck_cards[deck_card_index]
			var card_print: CardPrint = _get_print_for_deck_card(deck_card)
			var card: Card = CardPrintLibrary.get_card_for_print(card_print)
			if card == null:
				card = CardLibrary.duplicate_card(str(deck_card.get("card_name", "")))
			if card != null:
				section_grid.add_child(_create_selected_deck_card_slot(card, card_print, deck_card_index))
				continue
		section_grid.add_child(_create_empty_codex_slot(deck_card_index))

	var bottom_spacer := Control.new()
	deck_card_list.add_child(bottom_spacer)
	bottom_spacer.custom_minimum_size = Vector2(0.0, CODEX_PAGE_BOTTOM_SPACING)

func _get_deck_card_list_content_width() -> float:
	if deck_card_scroll != null and deck_card_scroll.size.x > 0.0:
		return deck_card_scroll.size.x
	if deck_card_list != null and deck_card_list.size.x > 0.0:
		return deck_card_list.size.x
	if right_column != null and right_column.size.x > 0.0:
		return right_column.size.x
	return float(RIGHT_COLUMN_WIDTH)

func _create_empty_codex_slot(deck_card_index: int) -> Control:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = DECK_EDIT_CARD_SLOT_SIZE
	slot.mouse_filter = Control.MOUSE_FILTER_PASS
	slot.set_meta("deck_slot_index", deck_card_index)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.075, 0.18)
	style.border_color = Color(0.1, 0.1, 0.1, 0.32)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	slot.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	slot.add_child(label)
	label.text = "Empty"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.28, 0.28, 0.28))
	return slot

func _create_selected_deck_card_slot(card: Card, card_print: CardPrint, deck_card_index: int) -> Control:
	var card_slot := Control.new()
	card_slot.custom_minimum_size = DECK_EDIT_CARD_SLOT_SIZE
	card_slot.mouse_filter = Control.MOUSE_FILTER_PASS
	card_slot.clip_contents = false
	card_slot.set_meta("deck_slot_index", deck_card_index)
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
	card_visual.draggable = is_creating_deck && !editing_deck_has_missing_cards
	card_visual.disabled = false
	card_visual.mouse_filter = Control.MOUSE_FILTER_PASS
	card_visual.mouse_entered.connect(_on_browser_card_mouse_entered.bind(card, card_print))
	card_visual.mouse_exited.connect(_on_browser_card_mouse_exited.bind(card.card_name if card != null else ""))
	card_visual.drag_started.connect(_on_selected_deck_card_drag_started.bind(deck_card_index))
	card_visual.drag_released.connect(_on_selected_deck_card_drag_released.bind(deck_card_index))

	var remove_button: Control = null
	if !editing_deck_has_missing_cards:
		remove_button = _create_deck_slot_remove_button(deck_card_index)
		card_slot.add_child(remove_button)
		card_slot.mouse_entered.connect(_set_slot_remove_button_visible.bind(remove_button, true))
		card_slot.mouse_exited.connect(_queue_slot_remove_button_hover_update.bind(card_slot, remove_button))
		card_visual.mouse_entered.connect(_set_slot_remove_button_visible.bind(remove_button, true))
		card_visual.mouse_exited.connect(_queue_slot_remove_button_hover_update.bind(card_slot, remove_button))
		remove_button.mouse_entered.connect(_set_slot_remove_button_visible.bind(remove_button, true))
		remove_button.mouse_exited.connect(_queue_slot_remove_button_hover_update.bind(card_slot, remove_button))

	card_slot.resized.connect(_layout_selected_deck_card_slot.bind(card_slot, card_visual, remove_button))
	_layout_selected_deck_card_slot(card_slot, card_visual, remove_button)

	return card_slot

func _layout_selected_deck_card_slot(card_slot: Control, card_visual: CardVisual, remove_button: Control = null) -> void:
	if card_slot == null or card_visual == null:
		return

	card_slot.custom_minimum_size = DECK_EDIT_CARD_SLOT_SIZE
	var slot_size: Vector2 = card_slot.size
	if slot_size.x <= 0.0 or slot_size.y <= 0.0:
		slot_size = DECK_EDIT_CARD_SLOT_SIZE
	var scale_factor: float = _get_card_scale_for_slot_size(DECK_EDIT_CARD_SLOT_SIZE)
	card_visual.set_rest_scale(Vector2.ONE * scale_factor)
	card_visual.size = CARD_VISUAL_SIZE
	var scaled_card_size: Vector2 = CARD_VISUAL_SIZE * scale_factor
	var desired_draw_top_left: Vector2 = (slot_size - scaled_card_size) * 0.5 + Vector2(0.0, DECK_EDIT_CARD_VERTICAL_OFFSET)
	var home_position: Vector2 = _get_card_visual_position_for_draw_top_left(card_visual, desired_draw_top_left, scale_factor)
	card_visual.set_home_position(home_position, false)
	_layout_deck_slot_remove_button(card_visual, remove_button)

func _get_card_visual_position_for_draw_top_left(card_visual: CardVisual, draw_top_left: Vector2, scale_factor: float) -> Vector2:
	var pivot: Vector2 = card_visual.pivot_offset
	if pivot == Vector2.ZERO:
		pivot = CARD_VISUAL_SIZE * 0.5
	return draw_top_left - pivot * (Vector2.ONE - Vector2.ONE * scale_factor)

func _get_card_visual_draw_top_left(card_visual: CardVisual) -> Vector2:
	var pivot: Vector2 = card_visual.pivot_offset
	if pivot == Vector2.ZERO:
		pivot = CARD_VISUAL_SIZE * 0.5
	return card_visual.position + pivot * (Vector2.ONE - card_visual.rest_scale)

func _create_deck_slot_remove_button(deck_card_index: int) -> Control:
	var root := Control.new()
	root.tooltip_text = "Remove card"
	root.custom_minimum_size = DECK_SLOT_REMOVE_BUTTON_SIZE
	root.size = DECK_SLOT_REMOVE_BUTTON_SIZE
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.visible = false
	root.z_index = 80
	root.gui_input.connect(_on_deck_slot_remove_button_gui_input.bind(deck_card_index))

	var background := Panel.new()
	root.add_child(background)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_theme_stylebox_override("panel", _create_deck_slot_remove_button_style(Color(0.02, 0.02, 0.02, 0.96)))

	var icon := TextureRect.new()
	root.add_child(icon)
	icon.texture = WINDOW_CLOSE_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 4.0
	icon.offset_top = 4.0
	icon.offset_right = -4.0
	icon.offset_bottom = -4.0
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return root

func _on_deck_slot_remove_button_gui_input(event: InputEvent, deck_card_index: int) -> void:
	if !(event is InputEventMouseButton):
		return
	var mouse_button := event as InputEventMouseButton
	if mouse_button.button_index != MOUSE_BUTTON_LEFT or !mouse_button.pressed:
		return
	accept_event()
	_on_remove_selected_deck_card_pressed(deck_card_index)

func _create_deck_slot_remove_button_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	style.bg_color = bg_color
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	var radius: int = int(DECK_SLOT_REMOVE_BUTTON_SIZE.x * 0.5)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style

func _layout_deck_slot_remove_button(card_visual: CardVisual, remove_button: Control) -> void:
	if card_visual == null or remove_button == null or !is_instance_valid(remove_button):
		return

	remove_button.custom_minimum_size = DECK_SLOT_REMOVE_BUTTON_SIZE
	remove_button.size = DECK_SLOT_REMOVE_BUTTON_SIZE
	var scaled_card_size: Vector2 = CARD_VISUAL_SIZE * card_visual.rest_scale
	var card_top_left: Vector2 = _get_card_visual_draw_top_left(card_visual)
	remove_button.position = card_top_left + Vector2(scaled_card_size.x - DECK_SLOT_REMOVE_BUTTON_SIZE.x - 2.0, 2.0)

func _set_slot_remove_button_visible(remove_button: Control, should_show: bool) -> void:
	if remove_button == null or !is_instance_valid(remove_button):
		return
	remove_button.visible = should_show && is_creating_deck && !editing_deck_has_missing_cards

func _queue_slot_remove_button_hover_update(card_slot: Control, remove_button: Control) -> void:
	call_deferred("_update_slot_remove_button_hover", card_slot, remove_button)

func _update_slot_remove_button_hover(card_slot: Control, remove_button: Control) -> void:
	if card_slot == null or remove_button == null or !is_instance_valid(card_slot) or !is_instance_valid(remove_button):
		return
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var is_hovered: bool = card_slot.get_global_rect().has_point(mouse_position)
	_set_slot_remove_button_visible(remove_button, is_hovered)

func _on_selected_deck_card_drag_started(_card_visual: CardVisual, deck_card_index: int) -> void:
	hovered_deck_card_index = deck_card_index
	_hide_remove_card_button()
	_set_deck_card_drag_floating(_card_visual, true)

func _on_selected_deck_card_drag_released(card_visual: CardVisual, deck_card_index: int) -> void:
	_set_deck_card_drag_floating(card_visual, false)
	if !is_creating_deck or editing_deck_has_missing_cards:
		if card_visual != null and is_instance_valid(card_visual):
			card_visual.fly_home()
		return

	var mouse_position := get_viewport().get_mouse_position()
	if !deck_card_scroll.get_global_rect().has_point(mouse_position):
		if card_visual != null and is_instance_valid(card_visual):
			card_visual.fly_home()
		return

	var target_index: int = _get_deck_drop_index(mouse_position)
	if target_index < 0 or target_index >= MAX_DECK_SIZE or target_index == deck_card_index:
		if card_visual != null and is_instance_valid(card_visual):
			card_visual.fly_home()
		return

	_swap_or_move_deck_slots(deck_card_index, target_index)
	hovered_deck_card_index = -1
	_hide_remove_card_button()
	_refresh_selected_deck_cards()
	_update_deck_editor_state()

func _set_deck_card_drag_floating(card_visual: CardVisual, floating: bool) -> void:
	if card_visual == null or !is_instance_valid(card_visual):
		return
	var previous_global_position: Vector2 = card_visual.global_position
	card_visual.top_level = floating
	card_visual.global_position = previous_global_position
	if floating:
		card_visual.z_index = MAGNIFIER_Z_INDEX + 20

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
	_reset_deck_selector_scroll_motion()

	var saved_decks: Array = PlayerDeckStore.list_decks()
	if saved_decks.is_empty():
		var empty_label := Label.new()
		deck_list.add_child(empty_label)
		empty_label.text = "No saved codexes"
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
	row_frame.mouse_filter = Control.MOUSE_FILTER_PASS
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
	front_panel.mouse_filter = Control.MOUSE_FILTER_PASS
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
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)

	var name_label := Label.new()
	content.add_child(name_label)
	name_label.text = str(deck_data.get("name", "Unnamed codex"))
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.9))

	var footer := HBoxContainer.new()
	content.add_child(footer)
	footer.mouse_filter = Control.MOUSE_FILTER_PASS
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

	var edit_button := _create_circle_icon_button("E", "Edit codex")
	footer.add_child(edit_button)
	edit_button.pressed.connect(_on_edit_deck_pressed.bind(deck_data.duplicate(true)))

	var delete_button := _create_circle_icon_button("X", "Delete codex")
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
	is_editing_deck_name = false
	editing_deck_id = str(deck_data.get("deck_id", ""))
	deck_name_edit.text = str(deck_data.get("name", ""))
	_sync_deck_name_display()
	selected_deck_cards.clear()
	_ensure_selected_deck_slots()
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
			var slot_index: int = int(normalized_card.get("slot", index))
			if slot_index < 0 or slot_index >= MAX_DECK_SIZE or !_is_deck_slot_empty(slot_index):
				slot_index = _get_first_empty_deck_slot()
			if slot_index == -1:
				break
			_set_deck_slot(slot_index, normalized_card)

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

	selected_deck_cards[hovered_deck_card_index] = null
	_reindex_selected_deck_cards()

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
