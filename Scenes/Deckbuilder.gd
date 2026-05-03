extends Control

const CARD_VISUAL = preload("res://Scenes/CardVisual.tscn")
const MAIN_MENU_SCENE = "res://Scenes/MainMenu.tscn"
const CARDS_PER_PAGE: int = 8
const CARD_COLUMNS: int = 4
const CARD_SIZE: Vector2 = Vector2(126, 176)
const MAX_DECK_SIZE: int = 15

var all_card_names: Array = []
var current_page: int = 0
var is_creating_deck: bool = false
var selected_deck_cards: Array = []
var dragged_card_name: String = ""

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

func _ready() -> void:
	_build_ui()
	_load_cards()
	_show_page(0)

func _build_ui() -> void:
	var root := MarginContainer.new()
	add_child(root)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 34)
	root.add_theme_constant_override("margin_top", 30)
	root.add_theme_constant_override("margin_right", 34)
	root.add_theme_constant_override("margin_bottom", 30)

	var main_layout := HBoxContainer.new()
	root.add_child(main_layout)
	main_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_layout.add_theme_constant_override("separation", 28)

	var browser := VBoxContainer.new()
	main_layout.add_child(browser)
	browser.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	browser.size_flags_vertical = Control.SIZE_EXPAND_FILL
	browser.add_theme_constant_override("separation", 18)

	card_grid = GridContainer.new()
	browser.add_child(card_grid)
	card_grid.columns = CARD_COLUMNS
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

	var deck_panel_frame := PanelContainer.new()
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
	_populate_saved_decks_list()

func _load_cards() -> void:
	if CardLibrary.all_cards.is_empty():
		CardLibrary.load_all_cards()
	PlayerCollectionStore.ensure_loaded()
	PlayerDeckStore.ensure_loaded()
	all_card_names = CardLibrary.get_all_card_names()
	all_card_names.sort()

func _show_page(page_index: int) -> void:
	current_page = clampi(page_index, 0, max(0, _get_page_count() - 1))
	for child in card_grid.get_children():
		card_grid.remove_child(child)
		child.queue_free()

	var start_index: int = current_page * CARDS_PER_PAGE
	var end_index: int = min(start_index + CARDS_PER_PAGE, all_card_names.size())
	for index in range(start_index, end_index):
		var card_name: String = str(all_card_names[index])
		var card: Card = CardLibrary.duplicate_card(card_name)
		if card == null:
			continue

		var card_visual: CardVisual = CARD_VISUAL.instantiate() as CardVisual
		card_grid.add_child(card_visual)
		card_visual.custom_minimum_size = CARD_SIZE
		card_visual.draggable = is_creating_deck
		card_visual.set_hover_raise_enabled(false)
		card_visual.set_card(card)
		card_visual.set_face_down(false)
		card_visual.set_collection_owned(PlayerCollectionStore.owns_card(card))
		card_visual.drag_started.connect(_on_card_drag_started.bind(card_name))
		card_visual.drag_released.connect(_on_card_drag_released.bind(card_name))

	page_label.text = "%d / %d" % [current_page + 1, max(1, _get_page_count())]
	previous_button.disabled = current_page <= 0
	next_button.disabled = current_page >= _get_page_count() - 1
	_update_deck_editor_state()

func _get_page_count() -> int:
	return int(ceil(float(all_card_names.size()) / float(CARDS_PER_PAGE)))

func _on_previous_pressed() -> void:
	_show_page(current_page - 1)

func _on_next_pressed() -> void:
	_show_page(current_page + 1)

func _on_new_deck_pressed() -> void:
	is_creating_deck = true
	selected_deck_cards.clear()
	dragged_card_name = ""
	deck_name_edit.text = ""
	_refresh_selected_deck_cards()
	_update_deck_editor_state()
	_show_page(current_page)

func _on_deck_editor_back_pressed() -> void:
	is_creating_deck = false
	selected_deck_cards.clear()
	dragged_card_name = ""
	_refresh_selected_deck_cards()
	_update_deck_editor_state()
	_show_page(current_page)

func _on_deck_name_changed(_new_text: String) -> void:
	_update_deck_editor_state()

func _on_card_drag_started(_card_visual: CardVisual, card_name: String) -> void:
	dragged_card_name = card_name

func _on_card_drag_released(_card_visual: CardVisual, card_name: String) -> void:
	if !is_creating_deck:
		return

	var mouse_position := get_viewport().get_mouse_position()
	if deck_card_scroll.get_global_rect().has_point(mouse_position) && _can_add_card_to_deck(card_name):
		selected_deck_cards.append(_create_deck_card_entry(card_name, selected_deck_cards.size()))
		_refresh_selected_deck_cards()
		_update_deck_editor_state()

	dragged_card_name = ""
	call_deferred("_show_page", current_page)

func _on_done_pressed() -> void:
	if !_can_complete_deck():
		return

	PlayerDeckStore.save_new_deck(deck_name_edit.text, selected_deck_cards)
	is_creating_deck = false
	selected_deck_cards.clear()
	deck_name_edit.text = ""
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

	for card_visual in card_grid.get_children():
		if card_visual is CardVisual:
			var visual := card_visual as CardVisual
			visual.draggable = is_creating_deck && visual.collection_owned && !_is_card_already_selected(visual.card) && selected_deck_cards.size() < MAX_DECK_SIZE
			visual.disabled = !visual.collection_owned

func _can_complete_deck() -> bool:
	return is_creating_deck && !deck_name_edit.text.strip_edges().is_empty() && selected_deck_cards.size() == MAX_DECK_SIZE

func _can_add_card_to_deck(card_name: String) -> bool:
	var card: Card = CardLibrary.get_card(card_name)
	return card != null && PlayerCollectionStore.owns_card(card) && !_is_card_already_selected(card) && selected_deck_cards.size() < MAX_DECK_SIZE

func _refresh_selected_deck_cards() -> void:
	for child in deck_card_list.get_children():
		deck_card_list.remove_child(child)
		child.queue_free()

	for deck_card in selected_deck_cards:
		if !(deck_card is Dictionary):
			continue
		var card: Card = CardLibrary.duplicate_card(str(deck_card.get("card_name", "")))
		if card == null:
			continue
		deck_card_list.add_child(_create_deck_card_row(card))

func _create_deck_card_row(card: Card) -> Control:
	var row_frame := PanelContainer.new()
	row_frame.custom_minimum_size = Vector2(0, 34)
	row_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL

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
	name_label.text = card.card_name
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
	var row_frame := PanelContainer.new()
	row_frame.custom_minimum_size = Vector2(0, 44)
	row_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var row := VBoxContainer.new()
	row_frame.add_child(row)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	row.add_child(name_label)
	name_label.text = str(deck_data.get("name", "Unnamed deck"))
	name_label.clip_text = true

	var cards_value = deck_data.get("cards", [])
	var card_count: int = cards_value.size() if cards_value is Array else 0
	var count_label := Label.new()
	row.add_child(count_label)
	count_label.text = "%d/%d" % [card_count, MAX_DECK_SIZE]
	count_label.add_theme_font_size_override("font_size", 12)

	return row_frame

func _create_deck_card_entry(card_name: String, slot: int) -> Dictionary:
	var card: Card = CardLibrary.get_card(card_name)
	if card == null:
		return {}

	var owned_item: Dictionary = PlayerCollectionStore.get_first_owned_item_for_card(card)
	var card_code: String = PlayerCollectionStore.get_card_code(card)
	var variant_id: String = str(owned_item.get("variant_id", PlayerCollectionStore.DEFAULT_VARIANT_ID))
	if variant_id.is_empty():
		variant_id = PlayerCollectionStore.DEFAULT_VARIANT_ID

	return {
		"slot": slot,
		"card_code": card_code,
		"card_name": card.card_name,
		"variant_id": variant_id,
		"variant_name": str(owned_item.get("variant_name", PlayerCollectionStore.DEFAULT_VARIANT_NAME)),
		"collection_instance_id": str(owned_item.get("instance_id", "")),
		"item_def_key": str(owned_item.get("item_def_key", PlayerCollectionStore.get_item_def_key(card_code, variant_id))),
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
