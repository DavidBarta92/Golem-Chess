extends Control

const CARD_VISUAL = preload("res://Scenes/CardVisual.tscn")
const MAIN_MENU_SCENE = "res://Scenes/MainMenu.tscn"
const CARD_VISUAL_SIZE: Vector2 = Vector2(164, 229)
const DESKTOP_CARDS_PER_PAGE: int = 8
const DESKTOP_CARD_COLUMNS: int = 4
const DESKTOP_CARD_SLOT_SIZE: Vector2 = Vector2(148, 207)
const MEDIUM_CARDS_PER_PAGE: int = 6
const MEDIUM_CARD_COLUMNS: int = 3
const MEDIUM_CARD_SLOT_SIZE: Vector2 = Vector2(132, 184)
const COMPACT_CARDS_PER_PAGE: int = 4
const COMPACT_CARD_COLUMNS: int = 2
const COMPACT_CARD_SLOT_SIZE: Vector2 = Vector2(120, 168)
const MAX_DECK_SIZE: int = 15
const REMOVE_BUTTON_VISIBLE_SECONDS: float = 1.0
const CARD_DESCRIPTION_HEIGHT: int = 76

var all_card_prints: Array = []
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
var main_layout: HBoxContainer
var browser: VBoxContainer
var deck_panel_frame: PanelContainer
var card_grid: GridContainer
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

func _ready() -> void:
	_build_ui()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_apply_responsive_layout(false)
	_load_cards()
	_show_page(0)

func _process(_delta: float) -> void:
	_update_browser_card_description_hover()

func _build_ui() -> void:
	root_margin = MarginContainer.new()
	add_child(root_margin)
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 34)
	root_margin.add_theme_constant_override("margin_top", 30)
	root_margin.add_theme_constant_override("margin_right", 34)
	root_margin.add_theme_constant_override("margin_bottom", 30)

	main_layout = HBoxContainer.new()
	root_margin.add_child(main_layout)
	main_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_layout.add_theme_constant_override("separation", 28)

	browser = VBoxContainer.new()
	main_layout.add_child(browser)
	browser.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	browser.size_flags_vertical = Control.SIZE_EXPAND_FILL
	browser.add_theme_constant_override("separation", 18)

	card_grid = GridContainer.new()
	browser.add_child(card_grid)
	card_grid.columns = current_card_columns
	card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_grid.add_theme_constant_override("h_separation", 20)
	card_grid.add_theme_constant_override("v_separation", 20)

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

	card_description_panel = PanelContainer.new()
	browser.add_child(card_description_panel)
	card_description_panel.custom_minimum_size = Vector2(0, CARD_DESCRIPTION_HEIGHT)
	card_description_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var description_style: StyleBoxFlat = StyleBoxFlat.new()
	description_style.bg_color = Color(0.05, 0.055, 0.065, 0.86)
	description_style.border_color = Color(1.0, 1.0, 1.0, 0.14)
	description_style.border_width_left = 1
	description_style.border_width_top = 1
	description_style.border_width_right = 1
	description_style.border_width_bottom = 1
	description_style.corner_radius_top_left = 6
	description_style.corner_radius_top_right = 6
	description_style.corner_radius_bottom_left = 6
	description_style.corner_radius_bottom_right = 6
	description_style.content_margin_left = 14
	description_style.content_margin_top = 10
	description_style.content_margin_right = 14
	description_style.content_margin_bottom = 10
	card_description_panel.add_theme_stylebox_override("panel", description_style)

	card_description_label = Label.new()
	card_description_panel.add_child(card_description_label)
	card_description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card_description_label.add_theme_font_size_override("font_size", 16)
	card_description_label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.9))

	deck_panel_frame = PanelContainer.new()
	main_layout.add_child(deck_panel_frame)
	deck_panel_frame.custom_minimum_size = Vector2(230, 0)

	var deck_panel := VBoxContainer.new()
	deck_panel_frame.add_child(deck_panel)
	deck_panel.custom_minimum_size = Vector2(230, 0)
	deck_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_panel.add_theme_constant_override("separation", 12)

	var deck_title := Label.new()
	deck_panel.add_child(deck_title)
	deck_title.text = "My decks"
	deck_title.add_theme_font_size_override("font_size", 22)
	deck_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	new_deck_button = Button.new()
	deck_panel.add_child(new_deck_button)
	new_deck_button.text = "New deck"
	new_deck_button.custom_minimum_size = Vector2(0, 42)
	new_deck_button.pressed.connect(_on_new_deck_pressed)

	deck_editor_back_button = Button.new()
	deck_panel.add_child(deck_editor_back_button)
	deck_editor_back_button.text = "Back"
	deck_editor_back_button.custom_minimum_size = Vector2(0, 42)
	deck_editor_back_button.visible = false
	deck_editor_back_button.pressed.connect(_on_deck_editor_back_pressed)

	deck_name_edit = LineEdit.new()
	deck_panel.add_child(deck_name_edit)
	deck_name_edit.placeholder_text = "Deck name"
	deck_name_edit.custom_minimum_size = Vector2(0, 40)
	deck_name_edit.visible = false
	deck_name_edit.text_changed.connect(_on_deck_name_changed)

	deck_list_scroll = ScrollContainer.new()
	deck_panel.add_child(deck_list_scroll)
	deck_list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	deck_list = VBoxContainer.new()
	deck_list_scroll.add_child(deck_list)
	deck_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_list.add_theme_constant_override("separation", 8)

	deck_card_scroll = ScrollContainer.new()
	deck_panel.add_child(deck_card_scroll)
	deck_card_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_card_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	deck_card_scroll.visible = false

	deck_card_list = VBoxContainer.new()
	deck_card_scroll.add_child(deck_card_list)
	deck_card_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_card_list.add_theme_constant_override("separation", 8)

	var deck_panel_spacer := Control.new()
	deck_panel.add_child(deck_panel_spacer)
	deck_panel_spacer.custom_minimum_size = Vector2(0, 4)

	var deck_footer := HBoxContainer.new()
	deck_panel.add_child(deck_footer)
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

	var back_button := Button.new()
	add_child(back_button)
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(112, 42)
	back_button.anchor_left = 0.0
	back_button.anchor_top = 1.0
	back_button.anchor_right = 0.0
	back_button.anchor_bottom = 1.0
	back_button.offset_left = 24.0
	back_button.offset_top = -66.0
	back_button.offset_right = 136.0
	back_button.offset_bottom = -24.0
	back_button.pressed.connect(_on_back_pressed)

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

	_populate_saved_decks_list()

func _load_cards() -> void:
	if CardLibrary.all_cards.is_empty():
		CardLibrary.load_all_cards()
	CardPrintLibrary.ensure_loaded()
	PlayerCollectionStore.ensure_loaded()
	PlayerDeckStore.ensure_loaded()
	all_card_prints = CardPrintLibrary.get_all_prints()

func _show_page(page_index: int) -> void:
	current_page = clampi(page_index, 0, max(0, _get_page_count() - 1))
	_clear_browser_card_description()
	for child in card_grid.get_children():
		card_grid.remove_child(child)
		child.queue_free()

	var start_index: int = current_page * current_cards_per_page
	var end_index: int = min(start_index + current_cards_per_page, all_card_prints.size())
	for index in range(start_index, end_index):
		var card_print: CardPrint = all_card_prints[index] as CardPrint
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
		card_visual.mouse_entered.connect(_on_browser_card_mouse_entered.bind(card))
		card_visual.mouse_exited.connect(_on_browser_card_mouse_exited.bind(card.card_name))
		card_visual.drag_started.connect(_on_card_drag_started.bind(card_print.print_id))
		card_visual.drag_released.connect(_on_card_drag_released.bind(card_print.print_id))

	page_label.text = "%d / %d" % [current_page + 1, max(1, _get_page_count())]
	previous_button.disabled = current_page <= 0
	next_button.disabled = current_page >= _get_page_count() - 1
	_update_deck_editor_state()

func _get_page_count() -> int:
	return int(ceil(float(all_card_prints.size()) / float(current_cards_per_page)))

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
	var next_columns: int = DESKTOP_CARD_COLUMNS
	var next_cards_per_page: int = DESKTOP_CARDS_PER_PAGE
	var next_card_slot_size: Vector2 = DESKTOP_CARD_SLOT_SIZE
	var next_margin: int = 34
	var next_gap: int = 20
	var next_layout_gap: int = 28
	var next_deck_width: int = 230

	if viewport_width < 980.0:
		next_columns = COMPACT_CARD_COLUMNS
		next_cards_per_page = COMPACT_CARDS_PER_PAGE
		next_card_slot_size = COMPACT_CARD_SLOT_SIZE
		next_margin = 18
		next_gap = 14
		next_layout_gap = 18
		next_deck_width = 220
	elif viewport_width < 1180.0:
		next_columns = MEDIUM_CARD_COLUMNS
		next_cards_per_page = MEDIUM_CARDS_PER_PAGE
		next_card_slot_size = MEDIUM_CARD_SLOT_SIZE
		next_margin = 24
		next_gap = 16
		next_layout_gap = 22
		next_deck_width = 224

	var layout_changed: bool = next_columns != current_card_columns or next_cards_per_page != current_cards_per_page
	current_card_columns = next_columns
	current_cards_per_page = next_cards_per_page
	current_card_slot_size = next_card_slot_size

	if root_margin != null:
		root_margin.add_theme_constant_override("margin_left", next_margin)
		root_margin.add_theme_constant_override("margin_top", next_margin)
		root_margin.add_theme_constant_override("margin_right", next_margin)
		root_margin.add_theme_constant_override("margin_bottom", next_margin)
	if main_layout != null:
		main_layout.add_theme_constant_override("separation", next_layout_gap)
	if card_grid != null:
		card_grid.columns = current_card_columns
		card_grid.add_theme_constant_override("h_separation", next_gap)
		card_grid.add_theme_constant_override("v_separation", next_gap)
	if deck_panel_frame != null:
		deck_panel_frame.custom_minimum_size = Vector2(next_deck_width, 0)

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

func _on_browser_card_mouse_entered(card: Card) -> void:
	if card == null:
		return

	hovered_browser_card_name = card.card_name
	card_description_label.text = card.description.strip_edges()

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
	card_description_label.text = hovered_card.description.strip_edges()

func _clear_browser_card_description() -> void:
	hovered_browser_card_name = ""
	if card_description_label != null:
		card_description_label.text = ""

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
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

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
			visual.draggable = is_creating_deck && !editing_deck_has_missing_cards && visual.collection_owned && !_is_card_already_selected(visual.card) && selected_deck_cards.size() < MAX_DECK_SIZE
			visual.disabled = !visual.collection_owned

func _can_complete_deck() -> bool:
	return is_creating_deck && !editing_deck_has_missing_cards && !deck_name_edit.text.strip_edges().is_empty() && selected_deck_cards.size() == MAX_DECK_SIZE && _has_selected_nexus_card()

func _can_add_print_to_deck(print_id: String) -> bool:
	if editing_deck_has_missing_cards:
		return false

	var card_print: CardPrint = CardPrintLibrary.get_print(print_id)
	var card: Card = CardPrintLibrary.get_card_for_print(card_print)
	return card != null && PlayerCollectionStore.owns_print(card_print) && !_is_card_already_selected(card) && selected_deck_cards.size() < MAX_DECK_SIZE

func _refresh_selected_deck_cards() -> void:
	for child in deck_card_list.get_children():
		deck_card_list.remove_child(child)
		child.queue_free()

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
		deck_card_list.add_child(_create_deck_card_row(card, card_print, index))

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

	var row_frame := PanelContainer.new()
	row_frame.custom_minimum_size = Vector2(0, 58 if !is_playable else 44)
	row_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var row := HBoxContainer.new()
	row_frame.add_child(row)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var name_stack := VBoxContainer.new()
	row.add_child(name_stack)
	name_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	name_stack.add_theme_constant_override("separation", 0)

	var name_label := Label.new()
	name_stack.add_child(name_label)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.text = str(deck_data.get("name", "Unnamed deck"))
	name_label.clip_text = true

	if !is_playable:
		var status_label := Label.new()
		name_stack.add_child(status_label)
		status_label.text = "%d/%d cards" % [owned_count, MAX_DECK_SIZE]
		status_label.add_theme_font_size_override("font_size", 12)
		status_label.add_theme_color_override("font_color", Color(0.95, 0.18, 0.18))
		status_label.clip_text = true

	var edit_button := Button.new()
	row.add_child(edit_button)
	edit_button.text = "✎"
	edit_button.tooltip_text = "Edit deck"
	edit_button.custom_minimum_size = Vector2(34, 34)
	edit_button.pressed.connect(_on_edit_deck_pressed.bind(deck_data.duplicate(true)))

	return row_frame

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

func _is_card_already_selected(card: Card) -> bool:
	if card == null:
		return false

	var card_code: String = PlayerCollectionStore.get_card_code(card)
	for deck_card in selected_deck_cards:
		if deck_card is Dictionary && str(deck_card.get("card_code", "")) == card_code:
			return true
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
