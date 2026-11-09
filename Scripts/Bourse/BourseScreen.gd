extends Control

## The Bourse (Docs/Bourse/BOURSE.md). Four views under the top bar's
## Back / My lots / Bourse:
##   * lots: the player's lots on the market, sold ones to collect, a free slot;
##   * new_lot: the album on the left, the lot being put together on the right;
##   * market: the day's lots of the made-up sellers, one blind pick from each;
##   * pick: a paid pick's five stamps face down, shuffled; the click decides.
## The values behind the prices never show; the player sees how much the buyers
## want a lot and the chance at the next buyer.

const BourseUi = preload("res://Scripts/Bourse/BourseUi.gd")
const MAIN_MENU_SCENE: String = "res://Scenes/MainMenu.tscn"
const VIEW_LOTS: String = "lots"
const VIEW_NEW_LOT: String = "new_lot"
const VIEW_MARKET: String = "market"
const VIEW_PICK: String = "pick"
const SIDE_MARGIN: float = 36.0
const TOP_MARGIN: float = 60.0 + 22.0
const BOTTOM_MARGIN: float = 24.0
const CARD_GAP: int = 16
const CARD_PADDING: float = 18.0
const CARD_SHEET_CELL: Vector2 = Vector2(68, 92)
const BUILDER_SHEET_CELL: Vector2 = Vector2(80, 109)
const ALBUM_CELL: Vector2 = Vector2(96, 130)
const ALBUM_COLUMNS: int = 3
const ALBUM_PAGE_SIZE: int = 9
const PICK_CELL: Vector2 = Vector2(132, 179)
const PICK_SMALL_CELL: Vector2 = Vector2(40, 54)
const PICK_TILT_DEGREES: float = 2.5
const PICK_FLIP_SECONDS: float = 0.18
const PRICE_REPEAT_FIRST: float = 0.4
const PRICE_REPEAT_NEXT: float = 0.06
## The album's set tabs, in the order of the mock-ups.
const SET_ORDER: Array[String] = ["Courtyard", "Structures", "Animals", "Flora", "Archetypes", "Celestials"]

var view: String = ""
var content: Control
var refresh_queued: bool = false

var countdown_label: Label
var countdown_is_market: bool = false

# The lot being put together.
var draft_print_ids: Array[String] = []
var draft_price: int = 0
var draft_price_touched: bool = false
var album_set: String = SET_ORDER[0]
var album_page: int = 0
var album_free_only: bool = true
var album_query: String = ""
var album_entries: Array[StampPrint] = []
var album_grid: GridContainer
var album_page_label: Label
var album_previous_button: Button
var album_next_button: Button
var sheet_holder: Control
var price_label: Label
var attraction_bars: BourseUi.AttractionBars
var attraction_label: Label
var hint_label: Label
var list_button: Button
var price_repeat_timer: Timer
var price_repeat_step: int = 0

# The pick under way.
var pick_cells: Array[Control] = []
var pick_done: bool = false

func _ready() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.color = UiPalette.PAPER_SHADE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	price_repeat_timer = Timer.new()
	price_repeat_timer.one_shot = true
	price_repeat_timer.timeout.connect(_on_price_repeat)
	add_child(price_repeat_timer)
	var clock := Timer.new()
	clock.wait_time = 1.0
	clock.autostart = true
	clock.timeout.connect(_update_countdown)
	add_child(clock)

	BourseStore.run_due_visits()
	# The sales are on screen now: the main menu's notice has done its job.
	BourseStore.mark_sales_announced()
	BourseStore.changed.connect(_on_bourse_changed)
	GlobalTopBar.show_bourse(_on_back_pressed, _show_lots, _show_market, VIEW_LOTS)
	if !BourseStore.get_pending_pick().is_empty():
		_show_pick()
	else:
		_show_lots()

func _exit_tree() -> void:
	if BourseStore.changed.is_connected(_on_bourse_changed):
		BourseStore.changed.disconnect(_on_bourse_changed)

func _on_back_pressed() -> void:
	match view:
		VIEW_NEW_LOT:
			_show_lots()
		VIEW_PICK:
			_show_market()
		_:
			SceneTransition.change_scene(MAIN_MENU_SCENE)

## A sale or a new day while the screen is open shows at once; the builder and
## a pick under way are left alone. The view is read when the refresh runs, not
## when the change came: paying for a pick changes the store and opens the pick
## in the same frame.
func _on_bourse_changed() -> void:
	if refresh_queued:
		return
	refresh_queued = true
	_refresh_after_change.call_deferred()

func _refresh_after_change() -> void:
	refresh_queued = false
	if view == VIEW_LOTS:
		_show_lots()
	elif view == VIEW_MARKET:
		_show_market()

# --- Shared layout ------------------------------------------------------------------------

func _new_view(view_name: String) -> VBoxContainer:
	if content != null:
		content.queue_free()
	view = view_name
	countdown_label = null
	var margin := MarginContainer.new()
	margin.name = "View_" + view_name
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", int(SIDE_MARGIN))
	margin.add_theme_constant_override("margin_right", int(SIDE_MARGIN))
	margin.add_theme_constant_override("margin_top", int(TOP_MARGIN))
	margin.add_theme_constant_override("margin_bottom", int(BOTTOM_MARGIN))
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content = margin
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)
	return column

## Title and note on the left, a countdown on the right.
func _add_header(column: VBoxContainer, title: String, note: String, countdown_caption: String, is_market: bool) -> void:
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(header)
	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 2)
	header.add_child(texts)
	texts.add_child(BourseUi.label(title, &"ScreenTitleLabel"))
	texts.add_child(BourseUi.label(note, &"CaptionLabel"))
	var clock_row := HBoxContainer.new()
	clock_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock_row.size_flags_vertical = Control.SIZE_SHRINK_END
	clock_row.add_theme_constant_override("separation", 6)
	header.add_child(clock_row)
	clock_row.add_child(BourseUi.ClockIcon.new())
	clock_row.add_child(BourseUi.label(countdown_caption, &"Label"))
	countdown_label = BourseUi.label("", &"FieldLabel")
	countdown_label.add_theme_font_override("font", get_theme_font("font", &"Button"))
	clock_row.add_child(countdown_label)
	countdown_is_market = is_market
	_update_countdown()

func _update_countdown() -> void:
	if countdown_label == null or !is_instance_valid(countdown_label):
		return
	var seconds: int = BourseStore.get_seconds_to_next_market() if countdown_is_market else BourseStore.get_seconds_to_next_visit()
	countdown_label.text = tr("BOURSE_IN_TIME") % _format_duration(seconds)
	if seconds <= 0 and !countdown_is_market:
		BourseStore.run_due_visits()

static func _format_duration(seconds: int) -> String:
	var minutes: int = int(ceil(float(maxi(0, seconds)) / 60.0))
	if minutes >= 60:
		return TranslationServer.translate("BOURSE_DURATION_HOURS_MINUTES") % [minutes / 60, minutes % 60]
	return TranslationServer.translate("BOURSE_DURATION_MINUTES") % maxi(1, minutes)

## Four columns of the same width, whatever is in them.
func _add_card_row(column: VBoxContainer) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", CARD_GAP)
	column.add_child(row)
	return row

func _card() -> PanelContainer:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var style: StyleBox = get_theme_stylebox("panel", &"ResultPanel").duplicate()
	style.content_margin_left = CARD_PADDING
	style.content_margin_right = CARD_PADDING
	style.content_margin_top = CARD_PADDING
	style.content_margin_bottom = CARD_PADDING
	card.add_theme_stylebox_override("panel", style)
	return card

func _card_column(card: PanelContainer) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 12)
	card.add_child(column)
	return column

func _fill_row(row: HBoxContainer, columns: int) -> void:
	while row.get_child_count() < columns:
		var filler := Control.new()
		filler.mouse_filter = Control.MOUSE_FILTER_IGNORE
		filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(filler)

func _primary_button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = &"QuestClaimButton"
	button.custom_minimum_size = Vector2(0, 40)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(on_pressed)
	return button

func _secondary_button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 40)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(on_pressed)
	return button

func _stamp_name(print_id: String) -> String:
	var stamp: Stamp = StampPrintLibrary.get_stamp_for_print(StampPrintLibrary.get_print(print_id))
	return stamp.stamp_name if stamp != null else print_id

func _person_name(person: Dictionary) -> String:
	return RandomOpponentFactory.format_name(str(person.get("surname", "")), str(person.get("given_name", "")))

# --- My lots --------------------------------------------------------------------------

func _show_lots() -> void:
	GlobalTopBar.set_bourse_tab(VIEW_LOTS)
	var column: VBoxContainer = _new_view(VIEW_LOTS)
	_add_header(column, tr("BOURSE_MY_LOTS_TITLE"), tr("BOURSE_MY_LOTS_NOTE"), tr("BOURSE_NEXT_BUYER"), false)
	var row: HBoxContainer = _add_card_row(column)
	var lots: Array = BourseStore.get_lots()
	for index in range(lots.size()):
		row.add_child(_lot_card(lots[index], index + 1))
	if BourseStore.get_free_slot_count() > 0:
		row.add_child(_new_lot_card(lots.size()))
	_fill_row(row, BourseStore.LOT_SLOTS)

func _lot_card(lot: Dictionary, number: int) -> PanelContainer:
	var card: PanelContainer = _card()
	var column: VBoxContainer = _card_column(card)
	var is_sold: bool = str(lot.get("state", "")) == BourseStore.STATE_SOLD
	var print_ids: Array = lot.get("print_ids", [])

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(top)
	var kicker := BourseUi.label(tr("BOURSE_LOT_SOLD") if is_sold else tr("BOURSE_LOT_LISTED"), &"KickerLabel")
	kicker.uppercase = true
	if is_sold:
		kicker.add_theme_color_override("font_color", UiPalette.COIN_DEEP)

	kicker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(kicker)
	top.add_child(BourseUi.label(tr("BOURSE_LOT_NUMBER") % number, &"CaptionLabel"))

	var faded: Array = []
	if is_sold:
		faded.append(print_ids.find(str(lot.get("sold_print_id", ""))))
	var sheet: PanelContainer = BourseUi.lot_sheet(print_ids, CARD_SHEET_CELL, false, Callable(), faded)
	column.add_child(sheet)

	if is_sold:
		var buyer: String = _person_name(lot.get("buyer", {}))
		column.add_child(BourseUi.label(tr("BOURSE_BUYER_PICKED") % [buyer, _stamp_name(str(lot.get("sold_print_id", "")))], &"", true))
		var payout := HBoxContainer.new()
		payout.mouse_filter = Control.MOUSE_FILTER_IGNORE
		payout.add_theme_constant_override("separation", 10)
		column.add_child(payout)
		var coins: HBoxContainer = BourseUi.coin_amount(int(lot.get("price", 0)), &"TitleLabel", 22.0, "+")
		(coins.get_child(1) as Label).add_theme_color_override("font_color", UiPalette.COIN_DEEP)
		payout.add_child(coins)
		var note := BourseUi.label(tr("BOURSE_SOLD_PAYOUT"), &"CaptionLabel", true)
		note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		payout.add_child(note)
		column.add_child(_primary_button(tr("BOURSE_COLLECT"), _on_collect_pressed.bind(str(lot.get("lot_id", "")))))
		return card

	var price_row := HBoxContainer.new()
	price_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(price_row)
	var price_caption := BourseUi.label(tr("BOURSE_ASKING_PRICE"), &"FieldLabel")
	price_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	price_row.add_child(price_caption)
	price_row.add_child(BourseUi.coin_amount(int(lot.get("price", 0)), &"TitleLabel", 20.0))

	var chance: float = BourseStore.get_sale_chance(lot)
	var chance_row := HBoxContainer.new()
	chance_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(chance_row)
	var chance_caption := BourseUi.label(tr("BOURSE_CHANCE_NEXT_BUYER"), &"CaptionLabel")
	chance_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chance_row.add_child(chance_caption)
	chance_row.add_child(BourseUi.label("%d%%" % roundi(chance * 100.0), &"FieldLabel"))
	var bar := BourseUi.ChanceBar.new()
	bar.value = chance
	column.add_child(bar)
	column.add_child(_secondary_button(tr("BOURSE_WITHDRAW"), _on_withdraw_pressed.bind(str(lot.get("lot_id", "")))))
	return card

func _new_lot_card(used: int) -> Control:
	var card := Control.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 420)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var outline := BourseUi.DashedBox.new()
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(outline)
	outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centre := VBoxContainer.new()
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_theme_constant_override("separation", 8)
	card.add_child(centre)
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var plus := _PlusCircle.new()
	plus.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	centre.add_child(plus)
	var title := BourseUi.label(tr("BOURSE_NEW_LOT"), &"TitleLabel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centre.add_child(title)
	var slots := BourseUi.label(tr("BOURSE_SLOTS_USED").format({"used": used, "total": BourseStore.LOT_SLOTS}), &"CaptionLabel")
	slots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centre.add_child(slots)
	card.add_child(BourseUi.click_area(_show_new_lot))
	return card

func _on_withdraw_pressed(lot_id: String) -> void:
	BourseStore.withdraw_lot(lot_id)

func _on_collect_pressed(lot_id: String) -> void:
	if !BourseStore.collect_lot(lot_id).is_empty():
		SFXManager.play("buy")
		GlobalTopBar.refresh_points()
		GlobalTopBar.pulse_points_hud()

# --- A new lot ----------------------------------------------------------------------------

func _show_new_lot() -> void:
	GlobalTopBar.set_bourse_tab(VIEW_LOTS)
	draft_print_ids.clear()
	draft_price = 0
	draft_price_touched = false
	album_page = 0
	album_query = ""
	var column: VBoxContainer = _new_view(VIEW_NEW_LOT)
	column.add_theme_constant_override("separation", 0)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 24)
	column.add_child(row)
	row.add_child(_build_album())
	row.add_child(_build_lot_builder())
	_refresh_album_entries()
	_refresh_builder()

func _build_album() -> Control:
	var album := VBoxContainer.new()
	album.mouse_filter = Control.MOUSE_FILTER_IGNORE
	album.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	album.size_flags_stretch_ratio = 1.1
	album.add_theme_constant_override("separation", 0)

	var tabs := TabBar.new()
	tabs.focus_mode = Control.FOCUS_NONE
	for style_name in ["tab_selected", "tab_unselected", "tab_hovered", "tab_disabled", "tab_focus"]:
		tabs.add_theme_stylebox_override(style_name, get_theme_stylebox(style_name, &"TabContainer"))
	for color_name in ["font_selected_color", "font_unselected_color", "font_hovered_color", "font_disabled_color"]:
		tabs.add_theme_color_override(color_name, get_theme_color(color_name, &"TabContainer"))
	for set_name in SET_ORDER:
		tabs.add_tab(tr(set_name))
	tabs.current_tab = SET_ORDER.find(album_set)
	tabs.tab_changed.connect(func(tab: int) -> void:
		album_set = SET_ORDER[tab]
		album_page = 0
		_refresh_album_entries())
	album.add_child(tabs)

	var panel: PanelContainer = _card()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	album.add_child(panel)
	album_grid = GridContainer.new()
	album_grid.columns = ALBUM_COLUMNS
	album_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	album_grid.add_theme_constant_override("h_separation", 24)
	album_grid.add_theme_constant_override("v_separation", 10)
	album_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	album_grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_child(album_grid)

	var tools := HBoxContainer.new()
	tools.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tools.add_theme_constant_override("separation", 14)
	album.add_child(BourseUi.spacer(Vector2(0, 10)))
	album.add_child(tools)
	var free_only := CheckBox.new()
	free_only.text = tr("BOURSE_FREE_ONLY")
	free_only.focus_mode = Control.FOCUS_NONE
	free_only.button_pressed = album_free_only
	free_only.toggled.connect(func(pressed: bool) -> void:
		album_free_only = pressed
		album_page = 0
		_refresh_album_entries())
	tools.add_child(free_only)
	var search := LineEdit.new()
	search.placeholder_text = tr("Search")
	search.custom_minimum_size = Vector2(150, 0)
	search.clear_button_enabled = true
	search.text_changed.connect(func(text: String) -> void:
		album_query = text.strip_edges().to_lower()
		album_page = 0
		_refresh_album_entries())
	tools.add_child(search)
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tools.add_child(spacer)
	album_previous_button = _pager_button(preload("res://ui/themes/icons/back.png"), -1)
	tools.add_child(album_previous_button)
	album_page_label = BourseUi.label("", &"NumberLabel")
	album_page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tools.add_child(album_page_label)
	album_next_button = _pager_button(preload("res://ui/themes/icons/next.png"), 1)
	tools.add_child(album_next_button)
	return album

func _pager_button(icon: Texture2D, step: int) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"PagerArrowButton"
	button.icon = icon
	button.expand_icon = true
	button.custom_minimum_size = Vector2(34, 34)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void:
		album_page = clampi(album_page + step, 0, maxi(0, _album_page_count() - 1))
		_show_album_page())
	return button

## The prints of the set the player owns, narrowed by the search and, with
## "Free only", to those with a copy free outside this lot.
func _refresh_album_entries() -> void:
	album_entries.clear()
	for stamp_print_value in StampPrintLibrary.get_all_prints():
		var stamp_print := stamp_print_value as StampPrint
		if stamp_print == null:
			continue
		var stamp: Stamp = StampPrintLibrary.get_stamp_for_print(stamp_print)
		if stamp == null or !stamp.enabled or stamp.Set != album_set:
			continue
		if PlayerCollectionStore.get_owned_count_for_print_id(stamp_print.print_id) <= 0:
			continue
		if album_free_only and PlayerCollectionStore.get_free_count_for_print_id(stamp_print.print_id) <= 0:
			continue
		if !album_query.is_empty() and stamp.stamp_name.to_lower().find(album_query) == -1:
			continue
		album_entries.append(stamp_print)
	_show_album_page()

func _album_page_count() -> int:
	return maxi(1, int(ceil(float(album_entries.size()) / float(ALBUM_PAGE_SIZE))))

func _show_album_page() -> void:
	if album_grid == null:
		return
	album_page = clampi(album_page, 0, _album_page_count() - 1)
	for child in album_grid.get_children():
		child.queue_free()
	var start: int = album_page * ALBUM_PAGE_SIZE
	for index in range(start, mini(start + ALBUM_PAGE_SIZE, album_entries.size())):
		album_grid.add_child(_album_cell(album_entries[index]))
	if album_entries.is_empty():
		var empty := BourseUi.label(tr("No stamps found"), &"CaptionLabel")
		empty.custom_minimum_size = Vector2(240, 120)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		album_grid.add_child(empty)
	album_page_label.text = "%d / %d" % [album_page + 1, _album_page_count()]
	album_previous_button.disabled = album_page <= 0
	album_next_button.disabled = album_page >= _album_page_count() - 1

## A stamp, its free count under it on a pill, a tick while it is on the lot.
## Faded and deaf once no copy is left outside the lot.
func _album_cell(stamp_print: StampPrint) -> Control:
	var left: int = _album_copies_left(stamp_print.print_id)
	var cell := VBoxContainer.new()
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_theme_constant_override("separation", -6)
	cell.alignment = BoxContainer.ALIGNMENT_CENTER
	var stamp_cell: Control = BourseUi.stamp_cell(stamp_print.print_id, ALBUM_CELL, false, left <= 0)
	cell.add_child(stamp_cell)
	if draft_print_ids.has(stamp_print.print_id):
		var badge := BourseUi.CheckBadge.new()
		badge.position = Vector2(ALBUM_CELL.x - 18, -4)
		stamp_cell.add_child(badge)
	if left > 0:
		stamp_cell.add_child(BourseUi.click_area(_on_album_stamp_pressed.bind(stamp_print.print_id)))
	var pill: PanelContainer = BourseUi.count_pill(left)
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cell.add_child(pill)
	return cell

func _album_copies_left(print_id: String) -> int:
	return PlayerCollectionStore.get_free_count_for_print_id(print_id) - draft_print_ids.count(print_id)

func _on_album_stamp_pressed(print_id: String) -> void:
	if draft_print_ids.size() >= BourseMarket.LOT_SIZE or _album_copies_left(print_id) <= 0:
		return
	draft_print_ids.append(print_id)
	SFXManager.play("stamp_up")
	_show_album_page()
	_refresh_builder()

func _on_sheet_stamp_pressed(index: int) -> void:
	if index < 0 or index >= draft_print_ids.size():
		return
	draft_print_ids.remove_at(index)
	_show_album_page()
	_refresh_builder()

func _build_lot_builder() -> Control:
	var panel: PanelContainer = _card()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style: StyleBox = panel.get_theme_stylebox("panel")
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 22
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)

	var titles := VBoxContainer.new()
	titles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.add_theme_constant_override("separation", 2)
	column.add_child(titles)
	titles.add_child(BourseUi.label(tr("BOURSE_NEW_LOT_TITLE"), &"PanelTitleLabel"))
	titles.add_child(BourseUi.label(tr("BOURSE_NEW_LOT_NOTE"), &"CaptionLabel", true))

	var body := HBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override("separation", 22)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	sheet_holder = CenterContainer.new()
	sheet_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet_holder.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	body.add_child(sheet_holder)

	var side := VBoxContainer.new()
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 8)
	body.add_child(side)
	side.add_child(BourseUi.label(tr("BOURSE_ASKING_PRICE"), &"FieldLabel"))
	var stepper := HBoxContainer.new()
	stepper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stepper.add_theme_constant_override("separation", 10)
	side.add_child(stepper)
	stepper.add_child(_price_step_button("−", -1))
	var amount := HBoxContainer.new()
	amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount.add_theme_constant_override("separation", 5)
	amount.custom_minimum_size = Vector2(64, 0)
	amount.alignment = BoxContainer.ALIGNMENT_CENTER
	amount.add_child(BourseUi.coin_icon(18.0))
	price_label = BourseUi.label("", &"TitleLabel")
	amount.add_child(price_label)
	stepper.add_child(amount)
	stepper.add_child(_price_step_button("+", 1))
	side.add_child(BourseUi.spacer(Vector2(0, 12)))
	side.add_child(BourseUi.label(tr("BOURSE_ATTRACTION"), &"FieldLabel"))
	attraction_bars = BourseUi.AttractionBars.new()
	side.add_child(attraction_bars)
	attraction_label = BourseUi.label("", &"TitleLabel")
	side.add_child(attraction_label)
	side.add_child(BourseUi.label(tr("BOURSE_ATTRACTION_NOTE"), &"CaptionLabel", true))

	column.add_child(HSeparator.new())
	var footer := HBoxContainer.new()
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_theme_constant_override("separation", 12)
	column.add_child(footer)
	hint_label = BourseUi.label("", &"FieldLabel", true)
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(hint_label)
	var cancel: Button = _secondary_button(tr("Cancel"), _show_lots)
	cancel.custom_minimum_size.x = 96
	footer.add_child(cancel)
	list_button = _primary_button(tr("BOURSE_LIST"), _on_list_pressed)
	footer.add_child(list_button)
	return panel

func _price_step_button(text: String, step: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(40, 40)
	button.focus_mode = Control.FOCUS_NONE
	# Held down, the price keeps going: first after a pause, then quickly.
	button.button_down.connect(func() -> void:
		price_repeat_step = step
		_step_price(step)
		price_repeat_timer.start(PRICE_REPEAT_FIRST))
	button.button_up.connect(func() -> void:
		price_repeat_step = 0
		price_repeat_timer.stop())
	return button

func _on_price_repeat() -> void:
	if price_repeat_step == 0:
		return
	_step_price(price_repeat_step)
	price_repeat_timer.start(PRICE_REPEAT_NEXT)

func _step_price(step: int) -> void:
	draft_price = clampi(draft_price + step, 1, BourseMarket.max_price())
	draft_price_touched = true
	_refresh_builder()

## The sheet, the price, the bars and the hint, after any change. The price
## follows the stamps until the player sets it.
func _refresh_builder() -> void:
	if sheet_holder == null:
		return
	for child in sheet_holder.get_children():
		child.queue_free()
	sheet_holder.add_child(BourseUi.lot_sheet(draft_print_ids, BUILDER_SHEET_CELL, true, _on_sheet_stamp_pressed, [], -1, tr("BOURSE_SHEET_LABEL")))

	var values: Array[float] = BourseMarket.values_for(draft_print_ids)
	if !draft_price_touched:
		draft_price = BourseMarket.suggested_price(values) if !values.is_empty() else 1
	price_label.text = str(draft_price)
	var level: int = BourseMarket.attraction_level(BourseMarket.sale_chance(values, draft_price)) if !values.is_empty() else 0
	attraction_bars.level = level
	attraction_bars.queue_redraw()
	attraction_label.text = tr("BOURSE_ATTRACTION_%d" % level) if !values.is_empty() else ""

	var missing: int = BourseMarket.LOT_SIZE - draft_print_ids.size()
	hint_label.text = tr("BOURSE_ADD_MORE") % missing if missing > 0 else tr("BOURSE_READY_TO_LIST")
	list_button.disabled = missing > 0

func _on_list_pressed() -> void:
	if BourseStore.list_lot(draft_print_ids, draft_price).is_empty():
		return
	SFXManager.play("attach_stamp")
	_show_lots()

# --- The day's market ------------------------------------------------------------------

func _show_market() -> void:
	GlobalTopBar.set_bourse_tab(VIEW_MARKET)
	var column: VBoxContainer = _new_view(VIEW_MARKET)
	_add_header(column, tr("BOURSE_MARKET_TITLE"), tr("BOURSE_MARKET_NOTE") % BourseStore.MARKET_LOTS_PER_DAY, tr("BOURSE_NEW_LOTS"), true)
	var row: HBoxContainer = _add_card_row(column)
	var pending_lot_id: String = str(BourseStore.get_pending_pick().get("lot_id", ""))
	for lot in BourseStore.get_market_lots():
		row.add_child(_market_card(lot, pending_lot_id))
	_fill_row(row, BourseStore.MARKET_LOTS_PER_DAY)

func _market_card(lot: Dictionary, pending_lot_id: String) -> PanelContainer:
	var card: PanelContainer = _card()
	var column: VBoxContainer = _card_column(card)
	var picked_print_id: String = str(lot.get("picked_print_id", ""))
	var lot_id: String = str(lot.get("lot_id", ""))
	column.add_child(_seller_row(lot.get("seller", {}), tr("BOURSE_SELLER_CLOSED") if !picked_print_id.is_empty() else tr("BOURSE_SELLER_TODAY")))

	var print_ids: Array = lot.get("print_ids", [])
	if picked_print_id.is_empty():
		column.add_child(BourseUi.lot_sheet(print_ids, CARD_SHEET_CELL))
	else:
		var picked_index: int = print_ids.find(picked_print_id)
		var faded: Array = []
		for index in range(print_ids.size()):
			if index != picked_index:
				faded.append(index)
		column.add_child(BourseUi.lot_sheet(print_ids, CARD_SHEET_CELL, false, Callable(), faded, picked_index))
		var picked := BourseUi.label(tr("BOURSE_PICKED_STAMP") % _stamp_name(picked_print_id), &"FieldLabel", true)
		picked.custom_minimum_size = Vector2(0, 40)
		picked.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		column.add_child(picked)
		return card

	if lot_id == pending_lot_id:
		column.add_child(_primary_button(tr("BOURSE_RESUME_PICK"), _show_pick))
		return card
	var price: int = int(lot.get("price", 0))
	var button: Button = _primary_button("", _on_pick_pressed.bind(lot_id))
	var inside := HBoxContainer.new()
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.alignment = BoxContainer.ALIGNMENT_CENTER
	inside.add_theme_constant_override("separation", 10)
	button.add_child(inside)
	inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var pick_text := BourseUi.label(tr("BOURSE_PICK"), &"")
	pick_text.add_theme_font_override("font", get_theme_font("font", &"Button"))
	pick_text.add_theme_color_override("font_color", UiPalette.PAPER_RAISED)
	inside.add_child(pick_text)
	var divider := VSeparator.new()
	divider.custom_minimum_size = Vector2(1, 18)
	divider.modulate = Color(UiPalette.PAPER_RAISED, 0.5)
	inside.add_child(divider)
	var cost: HBoxContainer = BourseUi.coin_amount(price, &"", 16.0)
	(cost.get_child(1) as Label).add_theme_font_override("font", get_theme_font("font", &"Button"))
	(cost.get_child(1) as Label).add_theme_color_override("font_color", UiPalette.PAPER_RAISED)
	inside.add_child(cost)
	var affordable: bool = PlayerProgressStore.get_points() >= price and pending_lot_id.is_empty()
	button.disabled = !affordable
	if PlayerProgressStore.get_points() < price:
		button.tooltip_text = tr("BOURSE_NOT_ENOUGH_COINS")
	column.add_child(button)
	return card

func _seller_row(seller: Dictionary, caption: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	var name_text: String = _person_name(seller)
	row.add_child(BourseUi.portrait(int(seller.get("portrait_seed", 1)), name_text, 42.0))
	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override("separation", 0)
	row.add_child(texts)
	var name_label := BourseUi.label(name_text, &"FieldLabel")
	name_label.add_theme_font_override("font", get_theme_font("font", &"Button"))
	texts.add_child(name_label)
	texts.add_child(BourseUi.label(caption, &"CaptionLabel"))
	return row

func _on_pick_pressed(lot_id: String) -> void:
	if !BourseStore.start_pick(lot_id):
		return
	GlobalTopBar.refresh_points()
	_show_pick()

# --- A pick ----------------------------------------------------------------------------------

func _show_pick() -> void:
	var pending: Dictionary = BourseStore.get_pending_pick()
	if pending.is_empty():
		_show_market()
		return
	var lot: Dictionary = BourseStore.get_market_lot(str(pending.get("lot_id", "")))
	if lot.is_empty():
		_show_market()
		return
	GlobalTopBar.set_bourse_tab("")
	pick_done = false
	pick_cells.clear()
	var column: VBoxContainer = _new_view(VIEW_PICK)
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	column.add_theme_constant_override("separation", 14)
	var seller: Dictionary = lot.get("seller", {})

	var seller_row := HBoxContainer.new()
	seller_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seller_row.alignment = BoxContainer.ALIGNMENT_CENTER
	seller_row.add_theme_constant_override("separation", 10)
	column.add_child(seller_row)
	seller_row.add_child(BourseUi.portrait(int(seller.get("portrait_seed", 1)), _person_name(seller), 42.0))
	var seller_texts := VBoxContainer.new()
	seller_texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seller_texts.add_theme_constant_override("separation", 0)
	seller_row.add_child(seller_texts)
	var lot_name := BourseUi.label(tr("BOURSE_SELLER_LOT") % _person_name(seller), &"FieldLabel")
	lot_name.add_theme_font_override("font", get_theme_font("font", &"Button"))
	seller_texts.add_child(lot_name)
	var paid := HBoxContainer.new()
	paid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paid.add_theme_constant_override("separation", 5)
	paid.add_child(BourseUi.label(tr("BOURSE_PAID"), &"CaptionLabel"))
	paid.add_child(BourseUi.coin_amount(int(pending.get("price", lot.get("price", 0))), &"CaptionLabel", 13.0))
	seller_texts.add_child(paid)

	var title := BourseUi.label(tr("BOURSE_PICK_TITLE"), &"ScreenTitleLabel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.name = "PickTitle"
	column.add_child(title)
	var note := BourseUi.label(tr("BOURSE_PICK_NOTE") % str(seller.get("given_name", "")), &"CaptionLabel")
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.name = "PickNote"
	column.add_child(note)

	var cards := HBoxContainer.new()
	cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 22)
	column.add_child(BourseUi.spacer(Vector2(0, 8)))
	column.add_child(cards)
	var order: Array = pending.get("order", [])
	for index in range(order.size()):
		var cell: Control = BourseUi.stamp_cell(str(order[index]), PICK_CELL, true)
		cell.rotation = deg_to_rad(randf_range(-PICK_TILT_DEGREES, PICK_TILT_DEGREES))
		cell.pivot_offset = PICK_CELL * 0.5
		cell.add_child(BourseUi.click_area(_on_pick_card_pressed.bind(index)))
		cards.add_child(cell)
		pick_cells.append(cell)

	column.add_child(BourseUi.spacer(Vector2(0, 12)))
	var was_on := BourseUi.label(tr("BOURSE_PICK_WAS_ON"), &"CaptionLabel")
	was_on.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(was_on)
	var small_row := HBoxContainer.new()
	small_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	small_row.alignment = BoxContainer.ALIGNMENT_CENTER
	small_row.add_theme_constant_override("separation", 8)
	column.add_child(small_row)
	for print_id in lot.get("print_ids", []):
		small_row.add_child(BourseUi.stamp_cell(str(print_id), PICK_SMALL_CELL))

	var done_row := HBoxContainer.new()
	done_row.name = "DoneRow"
	done_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	done_row.alignment = BoxContainer.ALIGNMENT_CENTER
	done_row.modulate.a = 0.0
	column.add_child(done_row)
	var done_button: Button = _primary_button(tr("BOURSE_PICK_DONE"), _show_market)
	done_button.custom_minimum_size.x = 200
	done_button.disabled = true
	done_row.add_child(done_button)

## The click decides: the card turns, the stamp is the player's, and a moment
## later the other four turn too, faded, to show what else was there.
func _on_pick_card_pressed(index: int) -> void:
	if pick_done:
		return
	var print_id: String = BourseStore.finish_pick(index)
	if print_id.is_empty():
		return
	pick_done = true
	for cell in pick_cells:
		for child in cell.get_children():
			if child.has_meta("click_area"):
				child.queue_free()
	SFXManager.play("codex_fold")
	_turn_pick_card(pick_cells[index], 0.0, false)
	var delay: float = 0.7
	for other in range(pick_cells.size()):
		if other != index:
			_turn_pick_card(pick_cells[other], delay, true)
			delay += 0.08
	var title := content.find_child("PickTitle", true, false) as Label
	if title != null:
		title.text = tr("BOURSE_YOU_GOT") % _stamp_name(print_id)
	var note := content.find_child("PickNote", true, false) as Label
	if note != null:
		note.text = ""
	var done_row := content.find_child("DoneRow", true, false) as Control
	if done_row != null:
		var tween := create_tween()
		tween.tween_interval(delay + 0.3)
		tween.tween_property(done_row, "modulate:a", 1.0, 0.25)
		tween.tween_callback(func() -> void:
			for child in done_row.get_children():
				if child is Button:
					(child as Button).disabled = false)
	GlobalTopBar.refresh_points()

func _turn_pick_card(cell: Control, delay: float, fade: bool) -> void:
	var visual := cell.get_meta("stamp_visual", null) as StampVisual
	if visual == null:
		return
	var rest: Vector2 = visual.rest_scale
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(visual, "scale", Vector2(0.0, rest.y * 1.02), PICK_FLIP_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(func() -> void:
		visual.set_face_down(false)
		var back := visual.get_node_or_null("BourseBack")
		if back != null:
			back.queue_free()
		if fade:
			var group: CanvasGroup = BourseUi.fade_group()
			cell.add_child(group)
			visual.reparent(group, false))
	tween.tween_property(visual, "scale", rest, PICK_FLIP_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	if !fade:
		cell.z_index = 5
		tween.tween_property(cell, "scale", Vector2.ONE * 1.08, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(cell, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


## The free slot's sign: a plus in an ink circle.
class _PlusCircle extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(44, 44)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var centre: Vector2 = size * 0.5
		draw_arc(centre, 20.0, 0.0, TAU, 48, UiPalette.INK, 1.5, true)
		draw_line(centre - Vector2(9, 0), centre + Vector2(9, 0), UiPalette.INK, 1.5, true)
		draw_line(centre - Vector2(0, 9), centre + Vector2(0, 9), UiPalette.INK, 1.5, true)
