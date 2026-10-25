extends Control

const STAMP_VISUAL = preload("res://Scenes/StampVisual.tscn")
const PACK_CONTROLLER_SCRIPT = preload("res://Scenes/CollectionPackController.gd")
const STAMP_BROWSER_CONTROLLER_SCRIPT = preload("res://Scenes/CollectionStampBrowserController.gd")
const SAVED_DECK_LIST_CONTROLLER_SCRIPT = preload("res://Scenes/CollectionSavedDeckListController.gd")
const INTRO_CONTROLLER_SCRIPT = preload("res://Scenes/CollectionIntroController.gd")
const ELASTIC_SCROLL_SCRIPT = preload("res://Scenes/CollectionElasticScroll.gd")
const WINDOW_CLOSE_ICON: Texture2D = preload("res://ui/themes/icons/window_close.svg")
const MAIN_MENU_SCENE = "res://Scenes/MainMenu.tscn"
const STAMP_VISUAL_SIZE: Vector2 = Vector2(168.7, 229)
const TOP_BAR_HEIGHT: int = 60
const RIGHT_COLUMN_WIDTH: int = 360
# The album (book and tabs) is drawn bigger than the frame around it so the
# stamps read better. It is scaled about the book's left edge at the tabs' top,
# and that point is moved up so the tabs start where the search row's bottom
# used to be; the book's bottom then leaves room for the control bar under it.
const ALBUM_SCALE: float = 1.1
const ALBUM_PIVOT_DESIGN: Vector2 = Vector2(336, 230)
const ALBUM_PIVOT_TARGET_DESIGN: Vector2 = Vector2(336, 174)
const BROWSER_STAMPS_PER_PAGE: int = 9
const BROWSER_STAMP_COLUMNS: int = 3
# The stamp slots grow with the album.
const BROWSER_STAMP_SLOT_SIZE: Vector2 = Vector2(128, 142) * ALBUM_SCALE
const BROWSER_STAMP_GAP: Vector2 = Vector2(8, 2) * ALBUM_SCALE
const DECK_EDIT_STAMP_SLOT_SIZE: Vector2 = Vector2(100, 140)
const DECK_SLOT_REMOVE_BUTTON_SIZE: Vector2 = Vector2(20, 20)
const CODEX_PAGE_GRID_HORIZONTAL_GAP: int = 8
const CODEX_PAGE_BOTTOM_SPACING: int = 2
const PAGER_BUTTON_PRESSED_SCALE: float = 0.92
const PAGER_BUTTON_PRESS_IN_SECONDS: float = 0.055
const PAGER_BUTTON_PRESS_OUT_SECONDS: float = 0.075
const CODEX_EDITOR_LIST_SPACING: int = 4
const MAX_DECK_SIZE: int = 15
const CODEX_PAGE_COUNT: int = 5
const CODEX_STAMPS_PER_PAGE: int = 3
const MAX_COPIES_PER_STAMP: int = PlayerDeckStore.MAX_COPIES_PER_STAMP
# The book art (background, tags, book, codex) is drawn on one 1919x1079 frame;
# BookStage holds it at that size and is scaled to fit the viewport, and the
# rects below are in the frame's pixels.
const BOOK_DESIGN_SIZE: Vector2 = Vector2(1919, 1079)
const BOOK_LEFT_PAGE_DESIGN_RECT: Rect2 = Rect2(410, 302, 587, 655)
const BOOK_TOP_EDGE_DESIGN_Y: float = 298.0
const BOOK_BOTTOM_EDGE_DESIGN_Y: float = 966.0
const BOOK_LEFT_EDGE_DESIGN_X: float = 336.0
const CODEX_DESIGN_RECT: Rect2 = Rect2(1202, 594, 551, 208)
const SET_TAG_NODE_NAMES: Dictionary = {
	"Animals": "AnimalsTag",
	"Flora": "FloraTag",
	"Celestials": "CelestialsTag",
	"Archetypes": "ArchetypesTag",
	"Courtyard": "CourtyardTag",
	"Structures": "StructuresTag",
}
const SET_TAG_SHADOW_SHADER = preload("res://Shaders/collection_tag_shadow.gdshader")
const SET_TAG_SHADOW_COLOR: Color = Color8(211, 213, 216)
const SET_TAG_POP_SCALE: float = 1.06
const SET_TAG_POP_IN_SECONDS: float = 0.07
const SET_TAG_POP_OUT_SECONDS: float = 0.14
# The search tools and the pager share one bar under the album.
const CONTROL_BAR_GAP_BELOW_BOOK: float = 8.0
const CONTROL_BAR_GAP_BEFORE_PANEL: float = 16.0
const CONTROL_BAR_BOTTOM_MARGIN: float = 6.0
const CONTROL_BAR_MIN_GAP: float = 12.0
## The search field gives up width first when a longer translation of "My
## stamps" would push the tools into the pager.
const SEARCH_FIELD_WIDTH: float = 140.0
const SEARCH_FIELD_MIN_WIDTH: float = 90.0
const PACK_NOTICE_Z_INDEX: int = 25
const DECK_PANEL_Z_INDEX: int = PACK_NOTICE_Z_INDEX + 5
# A warm paper grey: a step darker than the codex art's paper so the codexes
# still stand out on it.
const DECK_PANEL_BACKGROUND_COLOR: Color = UiPalette.PAPER_SHADE
const DECK_PANEL_SIDE_PADDING: float = 10.0
# How far the panel sits left of where the codex art is placed in the frame.
const DECK_PANEL_LEFT_SHIFT: float = 40.0
const DECK_PANEL_BOTTOM_RADIUS: int = 10
const DECK_PANEL_CONTENT_TOP_MARGIN: float = 12.0
const DECK_PANEL_BOTTOM_MARGIN: float = 24.0
const DECK_PANEL_SLIDE_DELAY: float = 0.2
const DECK_PANEL_SLIDE_SECONDS: float = 0.3
const DECK_PANEL_SLIDE_OVERSHOOT: float = 16.0
const DECK_PANEL_BOUNCE_OFFSETS: Array[float] = [-6.0, 2.0, 0.0]
const DECK_PANEL_BOUNCE_SECONDS: Array[float] = [0.1, 0.08, 0.07]
const MAGNIFIER_SHADER = preload("res://Shaders/collection_magnifier.gdshader")
const MAGNIFIER_GLASS_TEXTURE = preload("res://Assets/glass.png")
const MAGNIFIER_CASE_CLOSED_TEXTURE = preload("res://Assets/magnifying_glass_case_closed.png")
const MAGNIFIER_CASE_OPENED_TEXTURE = preload("res://Assets/magnifying_glass_case_opened.png")
const MAGNIFIER_CASE_DEFAULT_SIZE: Vector2 = Vector2(54, 121)
const MAGNIFIER_CASE_PRESSED_SCALE: float = 0.92
const MAGNIFIER_CASE_PRESS_IN_SECONDS: float = 0.055
const MAGNIFIER_CASE_PRESS_OUT_SECONDS: float = 0.075
const MAGNIFIER_LENS_SIZE: Vector2 = Vector2(220, 220)
const MAGNIFIER_ZOOM: float = 1.85
const MAGNIFIER_DISTORTION: float = 0.12
## The lens view renders a little more than the lens itself, so the rim's
## barrel distortion still has picture to sample.
const MAGNIFIER_VIEW_COVERAGE: float = 1.0 + MAGNIFIER_DISTORTION
## Render layer (layer 20) of the lens and the description beside it. The lens
## view leaves this layer out, so the lens never draws itself into itself.
const MAGNIFIER_SELF_VISIBILITY_LAYER: int = 1 << 19
const MAGNIFIER_Z_INDEX: int = 1800
const MAGNIFIER_CASE_Z_INDEX: int = MAGNIFIER_Z_INDEX + 10
const MAGNIFIER_LENS_Z_INDEX: int = MAGNIFIER_Z_INDEX + 30
const DRAGGED_STAMP_Z_INDEX: int = MAGNIFIER_LENS_Z_INDEX + 40
const MAGNIFIER_GLASS_SOURCE_SIZE: Vector2 = Vector2(337, 570)
const MAGNIFIER_GLASS_LENS_SOURCE_RECT: Rect2 = Rect2(15, 15, 305, 305)
const MAGNIFIER_GLASS_ROTATION_DEGREES: float = -36.0
const HOVER_DESCRIPTION_WIDTH: float = 300.0
# Same line as beside the dialogue panels' text in the match.
const HOVER_DESCRIPTION_LINE_WIDTH: float = 1.5
const HOVER_DESCRIPTION_LINE_COLOR: Color = CollectionPalette.INK
const InkStampMaterial = preload("res://Scripts/InkStamp/InkStampMaterial.gd")
const STAMP_SLOT_SCALE_MULTIPLIER: float = 0.88
const BROWSER_STAMP_VERTICAL_OFFSET: float = -12.0
const DECK_EDIT_STAMP_VERTICAL_OFFSET: float = -8.0

var is_creating_deck: bool = false
var editing_deck_id: String = ""
var selected_deck_stamps: Array = []
var dragged_print_id: String = ""
var hovered_browser_stamp_name: String = ""
var editing_deck_has_missing_stamps: bool = false
var is_editing_deck_name: bool = false
var codex_scroll_motion
var deck_selector_scroll_motion

var right_column: VBoxContainer
var deck_panel_frame: PanelContainer
var stamp_grid: GridContainer
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
var deck_stamp_scroll: ScrollContainer
var deck_stamp_list: VBoxContainer
var deck_count_label: Label
var done_button: Button
var buy_packs_button: Button
var points_label: Label
var buy_packs_panel: PanelContainer
var pack_panel: Control
var pack_inventory: Control
var pack_controller
var stamp_browser_controller
var saved_deck_list_controller
var intro_controller
var collection_background: TextureRect
var book_stage: Control
var book_image: TextureRect
var book_shadow: TextureRect
var deck_header: HBoxContainer
var set_tags: Dictionary = {}
var set_tag_pop_tween: Tween
var browser_tools: HBoxContainer
var pager: HBoxContainer
var deck_panel_rest_position: Vector2 = Vector2.ZERO
var deck_panel_slide_offset: float = 0.0
var deck_panel_slide_tween: Tween
var magnifier_viewport: SubViewport
var magnifier_case_button: Control
var magnifier_case_click_area: Button
var magnifier_case_closed_image: TextureRect
var magnifier_case_opened_image: TextureRect
var magnifier_case_tween: Tween
var magnifier_group: Control
var magnifier_material: ShaderMaterial
var magnifier_screen_lens: ColorRect
var hover_description_panel: PanelContainer
var hover_description_label: RichTextLabel
var magnifier_enabled: bool = false
var magnifier_previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	randomize()
	# Binding the tags already asks the browser for its active filter.
	stamp_browser_controller = STAMP_BROWSER_CONTROLLER_SCRIPT.new()
	_bind_scene_ui()
	_setup_elastic_scrolls()
	_setup_pack_controller()
	_setup_stamp_browser_controller()
	_setup_saved_deck_list_controller()
	_setup_intro_controller()
	_connect_viewport_resize()
	_layout_collection_scene()
	_load_stamps()
	_populate_saved_decks_list()
	_show_page(0)
	_play_deck_panel_slide_in()

func _process(delta: float) -> void:
	_update_browser_stamp_description_hover()
	codex_scroll_motion.update(delta)
	deck_selector_scroll_motion.update(delta)
	_update_magnifier_position()

func _unhandled_input(event: InputEvent) -> void:
	if magnifier_enabled && event.is_action_pressed("ui_cancel"):
		_set_magnifier_enabled(false)
		get_viewport().set_input_as_handled()
		return
	if pack_controller != null and pack_controller.is_buy_packs_modal_open():
		if event is InputEventMouseButton or event is InputEventMouseMotion:
			get_viewport().set_input_as_handled()
			return
	if codex_scroll_motion.handle_unhandled_wheel(event) or deck_selector_scroll_motion.handle_unhandled_wheel(event):
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
	pack_controller.bind({
		"collection": self,
		"points_label": points_label,
		"buy_packs_panel": buy_packs_panel,
		"pack_notice_panel": pack_panel,
		"pack_inventory": pack_inventory,
	}, Callable(self, "_on_pack_opened"))

func _setup_elastic_scrolls() -> void:
	# The page editor scrolls while a codex is being made, the codex list otherwise.
	codex_scroll_motion = ELASTIC_SCROLL_SCRIPT.new(deck_stamp_scroll, deck_stamp_list,
		func() -> bool: return is_creating_deck and deck_stamp_scroll.visible)
	deck_selector_scroll_motion = ELASTIC_SCROLL_SCRIPT.new(deck_list_scroll, deck_list,
		func() -> bool: return !is_creating_deck and deck_list_scroll.visible)

func _setup_stamp_browser_controller() -> void:
	stamp_browser_controller.bind({
		"collection": self,
		"stamp_grid": stamp_grid,
		"search_field": search_field,
		"owned_only_check": owned_only_check,
		"previous_button": previous_button,
		"next_button": next_button,
		"page_label": page_label,
		"count_badge_font": get_theme_font("font", &"FieldLabel"),
		"count_badge_font_size": get_theme_font_size("font_size", &"FieldLabel"),
		"stamp_visual_size": STAMP_VISUAL_SIZE,
		"stamp_slot_scale_multiplier": STAMP_SLOT_SCALE_MULTIPLIER,
		"browser_stamp_vertical_offset": BROWSER_STAMP_VERTICAL_OFFSET,
		"deck_slot_remove_button_size": DECK_SLOT_REMOVE_BUTTON_SIZE,
		"pager_button_pressed_scale": PAGER_BUTTON_PRESSED_SCALE,
		"pager_button_press_in_seconds": PAGER_BUTTON_PRESS_IN_SECONDS,
		"pager_button_press_out_seconds": PAGER_BUTTON_PRESS_OUT_SECONDS,
		"clear_hover_callback": Callable(self, "_clear_browser_stamp_description"),
		"update_deck_editor_callback": Callable(self, "_update_deck_editor_state"),
		"stamp_mouse_entered_callback": Callable(self, "_on_browser_stamp_mouse_entered"),
		"stamp_mouse_exited_callback": Callable(self, "_on_browser_stamp_mouse_exited"),
		"stamp_drag_started_callback": Callable(self, "_on_stamp_drag_started"),
		"stamp_drag_released_callback": Callable(self, "_on_stamp_drag_released"),
		"deck_stamp_display_name_provider": Callable(self, "_get_deck_stamp_display_name"),
	})
	stamp_browser_controller.apply_layout(
		BROWSER_STAMP_COLUMNS,
		BROWSER_STAMPS_PER_PAGE,
		BROWSER_STAMP_SLOT_SIZE,
		roundi(BROWSER_STAMP_GAP.x),
		roundi(BROWSER_STAMP_GAP.y)
	)
	_configure_pager_buttons()

func _setup_saved_deck_list_controller() -> void:
	saved_deck_list_controller = SAVED_DECK_LIST_CONTROLLER_SCRIPT.new()
	saved_deck_list_controller.bind({
		"collection": self,
		"deck_list": deck_list,
		"stamp_visual_size": STAMP_VISUAL_SIZE,
		"max_deck_size": MAX_DECK_SIZE,
		"reset_scroll_callback": Callable(deck_selector_scroll_motion, "reset"),
		"edit_deck_callback": Callable(self, "_on_edit_deck_pressed"),
		"editor_back_callback": Callable(self, "_on_deck_editor_back_pressed"),
		"print_for_deck_stamp_provider": Callable(self, "_get_print_for_deck_stamp"),
		"codex_size": _get_codex_row_size(),
	})

func _setup_intro_controller() -> void:
	intro_controller = INTRO_CONTROLLER_SCRIPT.new()
	var drawn_nodes: Array = [collection_background, book_image]
	drawn_nodes.append_array(set_tags.values())
	drawn_nodes.append(magnifier_case_closed_image)
	intro_controller.bind({
		"collection": self,
		"drawn_nodes": drawn_nodes,
		"fill_only_nodes": [book_shadow],
		"late_nodes": [stamp_grid, browser_tools, pager, pack_panel],
	})
	intro_controller.prepare()

func _bind_set_tags() -> void:
	set_tags.clear()
	if book_stage == null:
		return
	for set_id in SET_TAG_NODE_NAMES:
		var tag := book_stage.get_node_or_null(str(SET_TAG_NODE_NAMES[set_id])) as TextureButton
		if tag == null:
			continue
		set_tags[set_id] = tag
		var tag_material := ShaderMaterial.new()
		tag_material.shader = SET_TAG_SHADOW_SHADER
		tag_material.set_shader_parameter("shadow_color", SET_TAG_SHADOW_COLOR)
		tag_material.set_shader_parameter("shadow_start", _get_set_tag_shadow_start(tag))
		tag.material = tag_material
		tag.focus_mode = Control.FOCUS_NONE
		tag.tooltip_text = tr(set_id)
		_build_set_tag_click_mask(tag)
		_connect_once(tag.pressed, Callable(self, "_on_set_tag_pressed").bind(set_id))
	_apply_set_tag_states()

# The shade covers the lower third of the part of the tag that still shows
# above the book's top edge.
func _get_set_tag_shadow_start(tag: Control) -> float:
	if tag.size.y <= 0.0:
		return 1.0
	var visible_height: float = BOOK_TOP_EDGE_DESIGN_Y - tag.position.y
	var shadow_top: float = BOOK_TOP_EDGE_DESIGN_Y - visible_height / 3.0
	return clampf((shadow_top - tag.position.y) / tag.size.y, 0.0, 1.0)

# A tag only reacts where it shows above the book's top edge. Below that it is
# either hidden behind the book or, when pulled in front, lies over the page
# where the top row of stamps sits.
func _build_set_tag_click_mask(tag: TextureButton) -> void:
	if tag.texture_normal == null:
		return
	var image: Image = tag.texture_normal.get_image()
	if image == null or tag.size.y <= 0.0:
		return
	if image.is_compressed():
		image.decompress()

	var click_mask := BitMap.new()
	click_mask.create_from_image_alpha(image)
	var visible_rows: int = clampi(int(round((BOOK_TOP_EDGE_DESIGN_Y - tag.position.y) / tag.size.y * image.get_height())), 0, image.get_height())
	click_mask.set_bit_rect(Rect2i(0, visible_rows, image.get_width(), image.get_height() - visible_rows), false)
	tag.texture_click_mask = click_mask

func _on_set_tag_pressed(set_id: String) -> void:
	var next_filter: String = "" if stamp_browser_controller.active_set_filter == set_id else set_id
	stamp_browser_controller.set_active_set_filter(next_filter)
	_apply_set_tag_states()
	if set_tags.has(next_filter):
		_play_set_tag_pop(set_tags[next_filter] as Control)

func _apply_set_tag_states() -> void:
	if book_stage == null or book_image == null:
		return
	var active_filter: String = stamp_browser_controller.active_set_filter
	for set_id in set_tags:
		var tag: TextureButton = set_tags[set_id]
		var is_active: bool = set_id == active_filter
		var tag_material := tag.material as ShaderMaterial
		if tag_material != null:
			tag_material.set_shader_parameter("shadow_amount", 0.0 if is_active else 1.0)
		if is_active:
			book_stage.move_child(tag, book_stage.get_child_count() - 1)
			continue
		tag.scale = Vector2.ONE
		if tag.get_index() > book_image.get_index():
			book_stage.move_child(tag, book_image.get_index())

func _play_set_tag_pop(tag: Control) -> void:
	if tag == null:
		return
	if set_tag_pop_tween != null and set_tag_pop_tween.is_valid():
		set_tag_pop_tween.kill()
	tag.pivot_offset = Vector2(tag.size.x * 0.5, tag.size.y)
	tag.scale = Vector2.ONE
	set_tag_pop_tween = create_tween()
	set_tag_pop_tween.set_trans(Tween.TRANS_SINE)
	set_tag_pop_tween.set_ease(Tween.EASE_OUT)
	set_tag_pop_tween.tween_property(tag, "scale", Vector2.ONE * SET_TAG_POP_SCALE, SET_TAG_POP_IN_SECONDS)
	set_tag_pop_tween.tween_property(tag, "scale", Vector2.ONE, SET_TAG_POP_OUT_SECONDS)

func _bind_scene_ui() -> void:
	_bind_book_stage()
	deck_panel_frame = $DeckPanelFrame
	var deck_panel_style := _create_panel_style(DECK_PANEL_BACKGROUND_COLOR, Color.TRANSPARENT, 0, DECK_PANEL_BOTTOM_RADIUS)
	deck_panel_style.content_margin_left = DECK_PANEL_SIDE_PADDING
	deck_panel_style.content_margin_right = DECK_PANEL_SIDE_PADDING
	deck_panel_style.content_margin_top = TOP_BAR_HEIGHT + DECK_PANEL_CONTENT_TOP_MARGIN
	deck_panel_frame.add_theme_stylebox_override("panel", deck_panel_style)
	# The packs peek out from behind the codex panel, never across it.
	deck_panel_frame.z_as_relative = false
	deck_panel_frame.z_index = DECK_PANEL_Z_INDEX
	right_column = $DeckPanelFrame/RightColumn
	browser_tools = $BrowserTools
	stamp_grid = $StampGrid
	stamp_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owned_only_check = $BrowserTools/OwnedOnlyCheck
	search_field = $BrowserTools/SearchField
	pager = $Pager
	previous_button = $Pager/PreviousButton
	page_label = $Pager/PageLabel
	next_button = $Pager/NextButton
	deck_header = $DeckPanelFrame/RightColumn/DeckHeader
	new_deck_button = $DeckPanelFrame/RightColumn/DeckHeader/NewDeckButton
	deck_editor_back_button = $DeckPanelFrame/RightColumn/DeckFooter/DeckEditorBackButton
	deck_name_edit = $DeckPanelFrame/RightColumn/DeckNameEdit
	_ensure_deck_name_display()
	deck_list_scroll = $DeckPanelFrame/RightColumn/DeckListScroll
	# Codex rows are drawn at the codex art's width; a scrollbar would squeeze them.
	deck_list_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	deck_list = $DeckPanelFrame/RightColumn/DeckListScroll/DeckList
	deck_list.mouse_filter = Control.MOUSE_FILTER_PASS
	deck_stamp_scroll = $DeckPanelFrame/RightColumn/DeckStampScroll
	deck_stamp_list = $DeckPanelFrame/RightColumn/DeckStampScroll/DeckStampList
	deck_stamp_list.add_theme_constant_override("separation", CODEX_EDITOR_LIST_SPACING)
	deck_count_label = $DeckPanelFrame/RightColumn/DeckFooter/DeckCountLabel
	done_button = $DeckPanelFrame/RightColumn/DeckFooter/DoneButton
	GlobalTopBar.show_collection(Callable(self, "_on_back_pressed"), Callable(self, "_on_buy_packs_pressed"))
	buy_packs_button = GlobalTopBar.get_button("buy_packs")
	if buy_packs_button != null:
		buy_packs_button.set_meta("sfx_click", "buy_packs_window_opening")
	points_label = GlobalTopBar.points_label
	pack_panel = $PackNoticePanel
	pack_inventory = $PackNoticePanel/PackNoticeRoot/PackInventory
	# The pack controller builds the shop window inside this panel.
	buy_packs_panel = $BuyPacksPanel
	deck_title_label = get_node_or_null("DeckPanelFrame/RightColumn/DeckHeader/DeckTitle") as Label
	if deck_title_label != null:
		deck_title_label.text = tr("My codexes")
	new_deck_button.text = "+ " + tr("New codex")
	deck_name_edit.placeholder_text = tr("Codex name")
	_configure_pack_notice_panel()
	_setup_hover_description_panel()

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
	_connect_once(deck_stamp_scroll.resized, Callable(self, "_on_deck_stamp_scroll_resized"))

	buy_packs_panel.visible = false
	deck_list_scroll.clip_contents = true
	deck_list.clip_contents = false
	deck_stamp_scroll.visible = false
	deck_stamp_scroll.clip_contents = true
	deck_stamp_list.clip_contents = false
	deck_name_edit.visible = false
	deck_editor_back_button.visible = false
	deck_count_label.visible = false
	done_button.visible = false
	_setup_magnifier()


func _configure_pager_buttons() -> void:
	stamp_browser_controller.configure_pager_buttons()
	# The arrow art is black; re-ink and stamp it like the UI's other ink - a
	# disc of ink, so with the fill's specks. PagerArrowButton keeps the icon
	# colours raised paper, not ink, so the theme's ink does not darken the
	# arrow's light chevron first.
	for button in [previous_button, next_button]:
		if button == null:
			continue
		InkStampMaterial.apply(button, true, true)
		button.theme_type_variation = &"PagerArrowButton"

func _configure_pack_notice_panel() -> void:
	if pack_panel == null:
		return
	pack_panel.clip_contents = false
	pack_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	pack_panel.z_as_relative = false
	pack_panel.z_index = PACK_NOTICE_Z_INDEX

	var pack_root := pack_panel.get_node_or_null("PackNoticeRoot") as Control
	if pack_root == null:
		return
	pack_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pack_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pack_root.mouse_filter = Control.MOUSE_FILTER_PASS

	if pack_inventory != null:
		pack_inventory.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pack_inventory.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pack_inventory.mouse_filter = Control.MOUSE_FILTER_PASS
		pack_inventory.clip_contents = false

func _setup_hover_description_panel() -> void:
	if hover_description_panel == null or !is_instance_valid(hover_description_panel):
		hover_description_panel = PanelContainer.new()
		hover_description_panel.name = "HoverDescriptionPanel"
		hover_description_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hover_description_panel.custom_minimum_size = Vector2(HOVER_DESCRIPTION_WIDTH, 0.0)
		hover_description_panel.z_as_relative = false
		hover_description_panel.z_index = MAGNIFIER_Z_INDEX + 12
		hover_description_panel.visible = false
		add_child(hover_description_panel)
		# A paper fade from the left, starting in the old panel colour.
		hover_description_panel.theme_type_variation = &"StampDescriptionPanel"
		hover_description_panel.draw.connect(_draw_hover_description_line)
		# The text decides the height; refit whenever it changes what it needs.
		hover_description_panel.minimum_size_changed.connect(_on_hover_description_minimum_size_changed)

		hover_description_label = RichTextLabel.new()
		hover_description_panel.add_child(hover_description_label)
		hover_description_label.bbcode_enabled = true
		hover_description_label.fit_content = true
		hover_description_label.scroll_active = false
		var panel_style: StyleBox = hover_description_panel.get_theme_stylebox("panel")
		hover_description_label.custom_minimum_size = Vector2(HOVER_DESCRIPTION_WIDTH - panel_style.get_margin(SIDE_LEFT) - panel_style.get_margin(SIDE_RIGHT), 0.0)
		hover_description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hover_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hover_description_label.theme_type_variation = &"StampDescriptionText"
	elif hover_description_label == null or !is_instance_valid(hover_description_label):
		if hover_description_panel.get_child_count() > 0:
			hover_description_label = hover_description_panel.get_child(0) as RichTextLabel

func _draw_hover_description_line() -> void:
	hover_description_panel.draw_rect(Rect2(0.0, 0.0, HOVER_DESCRIPTION_LINE_WIDTH, hover_description_panel.size.y), HOVER_DESCRIPTION_LINE_COLOR)

func _on_hover_description_minimum_size_changed() -> void:
	if hover_description_panel != null and hover_description_panel.visible:
		_layout_hover_description_panel()

func _layout_hover_description_panel() -> void:
	if hover_description_panel == null or !is_instance_valid(hover_description_panel):
		return

	# Asking for no height lets the panel settle at what its text needs.
	hover_description_panel.size = Vector2(HOVER_DESCRIPTION_WIDTH, 0.0)
	var panel_size: Vector2 = hover_description_panel.size
	var viewport_size: Vector2 = get_viewport_rect().size
	var target_position := Vector2(74.0, TOP_BAR_HEIGHT + 22.0)
	if magnifier_enabled and magnifier_group != null and is_instance_valid(magnifier_group):
		target_position = magnifier_group.position + Vector2(MAGNIFIER_LENS_SIZE.x + 12.0, 8.0)
		if target_position.x + panel_size.x > viewport_size.x - 12.0:
			target_position.x = magnifier_group.position.x - panel_size.x - 12.0
	elif magnifier_case_button != null and is_instance_valid(magnifier_case_button):
		var case_size := magnifier_case_button.size
		if case_size == Vector2.ZERO:
			case_size = MAGNIFIER_CASE_DEFAULT_SIZE
		target_position = magnifier_case_button.position + Vector2(case_size.x + 12.0, -2.0)

	target_position.x = clampf(target_position.x, 12.0, maxf(12.0, viewport_size.x - panel_size.x - 12.0))
	target_position.y = clampf(target_position.y, TOP_BAR_HEIGHT + 8.0, maxf(TOP_BAR_HEIGHT + 8.0, viewport_size.y - panel_size.y - 12.0))
	hover_description_panel.position = target_position

func _bind_book_stage() -> void:
	collection_background = get_node_or_null("CollectionBackground") as TextureRect
	book_stage = get_node_or_null("BookStage") as Control
	if book_stage == null:
		return
	book_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	book_image = book_stage.get_node_or_null("BookImage") as TextureRect
	book_shadow = book_stage.get_node_or_null("BookShadow") as TextureRect
	_layout_book_stage()
	_bind_set_tags()

func _get_book_fit_scale() -> float:
	var viewport_size: Vector2 = get_viewport_rect().size
	return minf(viewport_size.x / BOOK_DESIGN_SIZE.x, viewport_size.y / BOOK_DESIGN_SIZE.y)

func _get_book_origin() -> Vector2:
	return ((get_viewport_rect().size - BOOK_DESIGN_SIZE * _get_book_fit_scale()) * 0.5).round()

func _design_to_screen(design_point: Vector2) -> Vector2:
	return _get_book_origin() + design_point * _get_book_fit_scale()

## Where a point of the book art lands once the album is scaled up.
func _album_to_screen(design_point: Vector2) -> Vector2:
	return _design_to_screen(ALBUM_PIVOT_TARGET_DESIGN + (design_point - ALBUM_PIVOT_DESIGN) * ALBUM_SCALE)

func _album_rect_to_screen(design_rect: Rect2) -> Rect2:
	return Rect2(_album_to_screen(design_rect.position), design_rect.size * _get_book_fit_scale() * ALBUM_SCALE)

func _get_codex_row_size() -> Vector2:
	return (CODEX_DESIGN_RECT.size * _get_book_fit_scale()).round()

func _layout_collection_scene() -> void:
	_layout_book_stage()
	_layout_stamp_browser()
	_layout_deck_panel()

func _layout_book_stage() -> void:
	if book_stage == null:
		return
	book_stage.size = BOOK_DESIGN_SIZE
	book_stage.scale = Vector2.ONE * _get_book_fit_scale() * ALBUM_SCALE
	book_stage.position = _album_to_screen(Vector2.ZERO)

# The stamps sit centred on the book's left page.
func _layout_stamp_browser() -> void:
	var page_rect: Rect2 = _album_rect_to_screen(BOOK_LEFT_PAGE_DESIGN_RECT)
	if stamp_grid != null:
		var stamp_bounds: Rect2 = stamp_browser_controller.get_page_stamp_bounds()
		stamp_grid.position = (page_rect.get_center() - stamp_bounds.get_center()).round()
	_layout_control_bar()

# "My stamps", the search field and the pager share one bar under the
# album: the tools from the book's left edge, the pager up against the codex
# panel.
func _layout_control_bar() -> void:
	if browser_tools == null or pager == null:
		return
	var bar_left: float = _album_to_screen(Vector2(BOOK_LEFT_EDGE_DESIGN_X, 0.0)).x
	var bar_right: float = _get_deck_panel_left() - CONTROL_BAR_GAP_BEFORE_PANEL
	var pager_size: Vector2 = pager.get_combined_minimum_size()
	if search_field != null:
		search_field.custom_minimum_size.x = SEARCH_FIELD_WIDTH
		var overflow: float = browser_tools.get_combined_minimum_size().x + CONTROL_BAR_MIN_GAP + pager_size.x - (bar_right - bar_left)
		if overflow > 0.0:
			search_field.custom_minimum_size.x = maxf(SEARCH_FIELD_MIN_WIDTH, SEARCH_FIELD_WIDTH - overflow)
	var tools_size: Vector2 = browser_tools.get_combined_minimum_size()
	var bar_height: float = maxf(tools_size.y, pager_size.y)
	var book_bottom: float = _album_to_screen(Vector2(0.0, BOOK_BOTTOM_EDGE_DESIGN_Y)).y
	var bar_top: float = minf(book_bottom + CONTROL_BAR_GAP_BELOW_BOOK, get_viewport_rect().size.y - bar_height - CONTROL_BAR_BOTTOM_MARGIN)
	browser_tools.size = tools_size
	browser_tools.position = Vector2(bar_left, bar_top + (bar_height - tools_size.y) * 0.5).round()
	pager.size = pager_size
	pager.position = Vector2(bar_right - pager_size.x, bar_top + (bar_height - pager_size.y) * 0.5).round()

# The codex panel follows the codex art's place in the book frame horizontally
# and runs from behind the global top bar down to the bottom margin.
func _layout_deck_panel() -> void:
	if deck_panel_frame == null:
		return
	var codex_width: float = _get_codex_row_size().x
	var panel_size := Vector2(
		codex_width + DECK_PANEL_SIDE_PADDING * 2.0,
		maxf(0.0, get_viewport_rect().size.y - DECK_PANEL_BOTTOM_MARGIN)
	)
	if right_column != null:
		right_column.custom_minimum_size = Vector2(codex_width, 0.0)
	# Codex rows built from now on take the new size.
	if saved_deck_list_controller != null:
		saved_deck_list_controller.codex_size = _get_codex_row_size()
	deck_panel_frame.custom_minimum_size = Vector2(panel_size.x, 0.0)
	deck_panel_frame.size = panel_size
	deck_panel_rest_position = Vector2(_get_deck_panel_left(), 0.0)
	_apply_deck_panel_slide_offset()

## The panel's left edge: where the codex art sits in the book frame, nudged
## a little left.
func _get_deck_panel_left() -> float:
	return roundf(_design_to_screen(CODEX_DESIGN_RECT.position).x - DECK_PANEL_SIDE_PADDING - DECK_PANEL_LEFT_SHIFT)

func _apply_deck_panel_slide_offset() -> void:
	if deck_panel_frame != null:
		deck_panel_frame.position = deck_panel_rest_position + Vector2(0.0, deck_panel_slide_offset)

func _set_deck_panel_slide_offset(value: float) -> void:
	deck_panel_slide_offset = value
	_apply_deck_panel_slide_offset()

# The panel drops out from under the global top bar like a drawer: one quick
# slide past its rest position, then a couple of small settling bounces.
func _play_deck_panel_slide_in() -> void:
	if deck_panel_frame == null:
		return
	if deck_panel_slide_tween != null and deck_panel_slide_tween.is_valid():
		deck_panel_slide_tween.kill()

	var hidden_offset: float = -maxf(0.0, deck_panel_frame.size.y - TOP_BAR_HEIGHT)
	var slide_callable := Callable(self, "_set_deck_panel_slide_offset")
	_set_deck_panel_slide_offset(hidden_offset)
	# The first frames after a scene change can be long (loading, shader
	# warm-up) and would swallow most of the drop; start once they are through.
	await get_tree().process_frame
	await get_tree().process_frame
	if !is_inside_tree():
		return
	# The drawn parts of the room draw themselves while the panel drops.
	if intro_controller != null:
		intro_controller.play(DECK_PANEL_SLIDE_DELAY)
	deck_panel_slide_tween = create_tween()
	deck_panel_slide_tween.tween_interval(DECK_PANEL_SLIDE_DELAY)
	deck_panel_slide_tween.tween_method(slide_callable, hidden_offset, DECK_PANEL_SLIDE_OVERSHOOT, DECK_PANEL_SLIDE_SECONDS) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var previous_offset: float = DECK_PANEL_SLIDE_OVERSHOOT
	for index in range(DECK_PANEL_BOUNCE_OFFSETS.size()):
		var next_offset: float = DECK_PANEL_BOUNCE_OFFSETS[index]
		deck_panel_slide_tween.tween_method(slide_callable, previous_offset, next_offset, DECK_PANEL_BOUNCE_SECONDS[index]) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		previous_offset = next_offset

func _setup_magnifier() -> void:
	# The lens shows a second render of the room's own canvas, zoomed in around
	# the lens, rather than the finished screen stretched: the stamps are drawn
	# again from their full-size art, so their detail is really there.
	if magnifier_viewport == null or !is_instance_valid(magnifier_viewport):
		magnifier_viewport = SubViewport.new()
		magnifier_viewport.name = "MagnifierView"
		magnifier_viewport.world_2d = get_viewport().find_world_2d()
		magnifier_viewport.canvas_cull_mask = 0xFFFFFFFF ^ MAGNIFIER_SELF_VISIBILITY_LAYER
		magnifier_viewport.transparent_bg = true
		magnifier_viewport.disable_3d = true
		magnifier_viewport.gui_disable_input = true
		magnifier_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child(magnifier_viewport)

	if magnifier_material == null:
		magnifier_material = ShaderMaterial.new()
		magnifier_material.shader = MAGNIFIER_SHADER
		magnifier_material.set_shader_parameter("lens_texture", magnifier_viewport.get_texture())
		magnifier_material.set_shader_parameter("coverage", MAGNIFIER_VIEW_COVERAGE)
		magnifier_material.set_shader_parameter("distortion", MAGNIFIER_DISTORTION)
		magnifier_material.set_shader_parameter("edge_feather", 0.025)
		magnifier_material.set_shader_parameter("glass_tint", Color(0.9, 0.97, 1.0, 0.12))

	if magnifier_group == null or !is_instance_valid(magnifier_group):
		magnifier_group = Control.new()
		magnifier_group.name = "MagnifierLens"
		magnifier_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
		magnifier_group.clip_contents = false
		magnifier_group.size = MAGNIFIER_LENS_SIZE
		magnifier_group.z_as_relative = false
		magnifier_group.z_index = MAGNIFIER_LENS_Z_INDEX
		magnifier_group.visible = false
		magnifier_group.visibility_layer = MAGNIFIER_SELF_VISIBILITY_LAYER
		add_child(magnifier_group)
		_build_magnifier_lens_visuals()
	if hover_description_panel != null and is_instance_valid(hover_description_panel):
		hover_description_panel.visibility_layer = MAGNIFIER_SELF_VISIBILITY_LAYER

	_bind_magnifier_case_button()
	_sync_magnifier_z_order()

	_layout_magnifier_case_button()
	_set_magnifier_enabled(magnifier_enabled)

func _sync_magnifier_z_order() -> void:
	if magnifier_case_button != null and is_instance_valid(magnifier_case_button):
		magnifier_case_button.z_as_relative = false
		magnifier_case_button.z_index = MAGNIFIER_CASE_Z_INDEX
	if magnifier_group != null and is_instance_valid(magnifier_group):
		magnifier_group.z_as_relative = false
		magnifier_group.z_index = MAGNIFIER_LENS_Z_INDEX

func _bind_magnifier_case_button() -> void:
	magnifier_case_button = $MagnifierCaseButton
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
		magnifier_case_click_area.tooltip_text = tr("Magnifier")
		magnifier_case_click_area.flat = true
		magnifier_case_click_area.focus_mode = Control.FOCUS_NONE
		_connect_once(magnifier_case_click_area.pressed, Callable(self, "_on_magnifier_case_pressed"))

	magnifier_case_button.z_as_relative = false
	magnifier_case_button.z_index = MAGNIFIER_CASE_Z_INDEX
	magnifier_case_button.pivot_offset = magnifier_case_button.size * 0.5
	_set_magnifier_case_opened(magnifier_enabled)

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
	_sync_magnifier_z_order()
	_set_magnifier_case_opened(is_enabled)
	if magnifier_group != null:
		magnifier_group.visible = is_enabled
	if magnifier_viewport != null:
		magnifier_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if is_enabled else SubViewport.UPDATE_DISABLED

	if is_enabled:
		if !was_enabled:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		_update_magnifier_position(true)
		_update_browser_stamp_description_hover()
	elif was_enabled:
		Input.set_mouse_mode(magnifier_previous_mouse_mode)
		_clear_browser_stamp_description()

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

	_sync_magnifier_view(lens_position + half_lens_size)
	if hover_description_panel != null and hover_description_panel.visible:
		_layout_hover_description_panel()

## Points the lens view at the screen point under the lens centre. The view is
## rendered at the window's real pixel density, and its transform starts from
## the screen's own canvas transform, so what the lens shows stays exactly
## over what is beneath it - also during the scene-change zoom.
func _sync_magnifier_view(lens_center: Vector2) -> void:
	if magnifier_viewport == null:
		return
	var pixel_scale: float = maxf(1.0, float(get_window().size.x) / maxf(1.0, get_viewport_rect().size.x))
	var view_size := Vector2i((MAGNIFIER_LENS_SIZE * MAGNIFIER_VIEW_COVERAGE * pixel_scale).ceil())
	if magnifier_viewport.size != view_size:
		magnifier_viewport.size = view_size
	var zoom_into_view := Transform2D(0.0, Vector2.ONE * MAGNIFIER_ZOOM * pixel_scale, 0.0, Vector2(view_size) * 0.5)
	magnifier_viewport.canvas_transform = zoom_into_view * Transform2D(0.0, -lens_center) * get_viewport().canvas_transform

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

func _load_stamps() -> void:
	stamp_browser_controller.load_stamps()

func _on_buy_packs_pressed() -> void:
	# Its button stays pressed while the shop is open; a second click is nothing.
	if pack_controller != null and !pack_controller.is_buy_packs_modal_open():
		pack_controller.show_buy_packs()

func _on_pack_opened(_rewards: Array[StampPrint]) -> void:
	_populate_saved_decks_list()
	_update_deck_editor_state()
	_refresh_stamp_filter(false)

func _show_page(page_index: int) -> void:
	stamp_browser_controller.show_page(page_index)

func _refresh_stamp_filter(reset_page: bool = true) -> void:
	stamp_browser_controller.refresh_stamp_filter(reset_page)

func _get_stamp_scale_for_slot_size(slot_size: Vector2) -> float:
	return stamp_browser_controller.get_stamp_scale_for_slot_size(slot_size)

func _get_browser_stamp_visual(node: Node) -> StampVisual:
	return stamp_browser_controller.get_browser_stamp_visual(node)

func _get_hovered_stamp_visual(node: Node, mouse_position: Vector2) -> StampVisual:
	return stamp_browser_controller.get_hovered_stamp_visual(node, mouse_position)

func _on_viewport_size_changed() -> void:
	_layout_collection_scene()
	stamp_browser_controller.update_existing_stamp_sizes()
	_sync_deck_stamp_list_width()
	_layout_magnifier_case_button()
	_update_magnifier_position(true)
	_layout_hover_description_panel()

func _on_deck_stamp_scroll_resized() -> void:
	_sync_deck_stamp_list_width()

func _sync_deck_stamp_list_width() -> void:
	if deck_stamp_scroll == null or deck_stamp_list == null:
		return
	var content_width: float = deck_stamp_scroll.size.x
	if content_width <= 0.0:
		content_width = right_column.size.x if right_column != null else float(RIGHT_COLUMN_WIDTH)
	content_width = maxf(0.0, content_width)
	deck_stamp_list.custom_minimum_size = Vector2(content_width, deck_stamp_list.custom_minimum_size.y)
	for child in deck_stamp_list.get_children():
		if child is Control and child.has_meta("codex_page_grid_wrapper"):
			var wrapper := child as Control
			wrapper.custom_minimum_size = Vector2(content_width, DECK_EDIT_STAMP_SLOT_SIZE.y)

func _on_previous_pressed() -> void:
	stamp_browser_controller.show_previous_page()

func _on_next_pressed() -> void:
	stamp_browser_controller.show_next_page()

func _on_search_text_changed(_new_text: String) -> void:
	_refresh_stamp_filter(true)

func _on_owned_only_toggled(_pressed: bool) -> void:
	_refresh_stamp_filter(true)

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
	_sync_deck_name_display()

func _sync_deck_name_display() -> void:
	if deck_name_display == null or deck_name_edit == null:
		return
	var name_text: String = deck_name_edit.text.strip_edges()
	deck_name_display.text = name_text if !name_text.is_empty() else tr("New")
	deck_name_display.theme_type_variation = &"CodexNameLabel" if !name_text.is_empty() else &"CodexNamePlaceholderLabel"

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
	editing_deck_has_missing_stamps = false
	is_editing_deck_name = false
	selected_deck_stamps.clear()
	_ensure_selected_deck_slots()
	dragged_print_id = ""
	deck_name_edit.text = ""
	_sync_deck_name_display()
	_refresh_selected_deck_stamps()
	_update_deck_editor_state()
	_show_page(stamp_browser_controller.get_current_page())

func _on_deck_editor_back_pressed() -> void:
	is_creating_deck = false
	editing_deck_id = ""
	editing_deck_has_missing_stamps = false
	is_editing_deck_name = false
	selected_deck_stamps.clear()
	dragged_print_id = ""
	_refresh_selected_deck_stamps()
	_update_deck_editor_state()
	_show_page(stamp_browser_controller.get_current_page())

func _on_deck_name_changed(_new_text: String) -> void:
	_sync_deck_name_display()
	_update_deck_editor_state()

func _on_browser_stamp_mouse_entered(stamp: Stamp, stamp_print: StampPrint = null) -> void:
	if stamp == null:
		return
	if !magnifier_enabled:
		return

	hovered_browser_stamp_name = stamp.stamp_name
	_show_stamp_preview(stamp, stamp_print)

func _on_browser_stamp_mouse_exited(stamp_name: String) -> void:
	if hovered_browser_stamp_name != stamp_name:
		return

	_clear_browser_stamp_description()

func _update_browser_stamp_description_hover() -> void:
	if !magnifier_enabled:
		if !hovered_browser_stamp_name.is_empty() or (hover_description_panel != null and hover_description_panel.visible):
			_clear_browser_stamp_description()
		return
	if stamp_grid == null or hover_description_label == null:
		return

	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var hovered_stamp: Stamp = null
	var hovered_stamp_visual: StampVisual = _get_hovered_stamp_visual(stamp_grid, mouse_position)
	if hovered_stamp_visual != null:
		hovered_stamp = hovered_stamp_visual.stamp

	if hovered_stamp == null && deck_stamp_list != null:
		hovered_stamp_visual = _get_hovered_stamp_visual(deck_stamp_list, mouse_position)
		if hovered_stamp_visual != null:
			hovered_stamp = hovered_stamp_visual.stamp

	if hovered_stamp == null:
		if !hovered_browser_stamp_name.is_empty():
			_clear_browser_stamp_description()
		return

	if hovered_browser_stamp_name == hovered_stamp.stamp_name:
		return

	hovered_browser_stamp_name = hovered_stamp.stamp_name
	_show_stamp_preview(hovered_stamp)

func _clear_browser_stamp_description() -> void:
	hovered_browser_stamp_name = ""
	if hover_description_label != null:
		hover_description_label.text = ""
	if hover_description_panel != null:
		hover_description_panel.visible = false

func _show_stamp_preview(stamp: Stamp, stamp_print: StampPrint = null) -> void:
	if stamp == null:
		return

	hovered_browser_stamp_name = stamp.stamp_name
	var description: String = stamp.get_display_description().strip_edges()
	if hover_description_label != null:
		hover_description_label.text = DescriptionMarkup.to_bbcode(description, hover_description_label.get_theme_font_size("normal_font_size"))
	if hover_description_panel != null:
		hover_description_panel.visible = !description.is_empty()
		if hover_description_panel.visible:
			_layout_hover_description_panel()

func _on_stamp_drag_started(stamp_visual: StampVisual, print_id: String) -> void:
	dragged_print_id = print_id
	_set_stamp_drag_floating(stamp_visual, true)

func _on_stamp_drag_released(stamp_visual: StampVisual, print_id: String) -> void:
	_set_stamp_drag_floating(stamp_visual, false)
	if !is_creating_deck:
		return

	var mouse_position := get_viewport().get_mouse_position()
	if deck_stamp_scroll.get_global_rect().has_point(mouse_position) && _can_add_print_to_deck(print_id):
		var drop_index: int = _get_deck_drop_index(mouse_position)
		if drop_index >= 0 && !_is_deck_slot_empty(drop_index):
			drop_index = -1
		if drop_index == -1:
			drop_index = _get_first_empty_deck_slot()
		if drop_index != -1:
			_set_deck_slot(drop_index, _create_deck_stamp_entry(print_id, drop_index))
		_reindex_selected_deck_stamps()
		_refresh_selected_deck_stamps()
		_update_deck_editor_state()

	dragged_print_id = ""
	call_deferred("_show_page", stamp_browser_controller.get_current_page())

func _get_deck_drop_index(mouse_position: Vector2) -> int:
	if deck_stamp_list == null:
		return -1
	return _find_deck_slot_index_at_position(deck_stamp_list, mouse_position)

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

	var stamps_to_save: Array = _get_selected_deck_stamps_for_save()
	if editing_deck_id.is_empty():
		PlayerDeckStore.save_new_deck(deck_name_edit.text, stamps_to_save)
	else:
		PlayerDeckStore.save_existing_deck(editing_deck_id, deck_name_edit.text, stamps_to_save)
	is_creating_deck = false
	editing_deck_id = ""
	editing_deck_has_missing_stamps = false
	is_editing_deck_name = false
	selected_deck_stamps.clear()
	deck_name_edit.text = ""
	_sync_deck_name_display()
	_refresh_selected_deck_stamps()
	_populate_saved_decks_list()
	_update_deck_editor_state()
	_show_page(stamp_browser_controller.get_current_page())

func _on_back_pressed() -> void:
	if pack_controller != null and pack_controller.handle_back_pressed():
		return
	SceneTransition.change_scene(MAIN_MENU_SCENE)

func _update_deck_editor_state() -> void:
	if new_deck_button == null:
		return

	if deck_header != null:
		deck_header.visible = !is_creating_deck
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
	deck_stamp_scroll.visible = is_creating_deck
	deck_count_label.visible = is_creating_deck
	done_button.visible = is_creating_deck
	_sync_deck_stamp_list_width()
	deck_count_label.text = "%d/%d" % [_get_selected_deck_stamp_count(), MAX_DECK_SIZE]
	done_button.disabled = !_can_complete_deck()

	for child in stamp_grid.get_children():
		var visual: StampVisual = _get_browser_stamp_visual(child)
		if visual != null:
			visual.draggable = is_creating_deck && !editing_deck_has_missing_stamps && visual.collection_owned && _can_add_stamp_to_deck(visual.stamp) && _get_selected_deck_stamp_count() < MAX_DECK_SIZE
			visual.disabled = false
			# A stamp that cannot be picked up stays quiet under the mouse; an
			# empty name plays nothing, no meta falls back to the usual hover.
			if visual.draggable:
				visual.remove_meta("sfx_hover")
			else:
				visual.set_meta("sfx_hover", "")

func _can_complete_deck() -> bool:
	return is_creating_deck && !editing_deck_has_missing_stamps && !deck_name_edit.text.strip_edges().is_empty() && _get_selected_deck_stamp_count() == MAX_DECK_SIZE && _has_selected_seeker_stamp() && !_has_too_many_stamp_copies()

func _can_add_print_to_deck(print_id: String) -> bool:
	if editing_deck_has_missing_stamps:
		return false

	var stamp_print: StampPrint = StampPrintLibrary.get_print(print_id)
	var stamp: Stamp = StampPrintLibrary.get_stamp_for_print(stamp_print)
	return stamp != null && PlayerCollectionStore.owns_print(stamp_print) && _can_add_stamp_to_deck(stamp) && _get_selected_deck_stamp_count() < MAX_DECK_SIZE

func _reindex_selected_deck_stamps() -> void:
	_ensure_selected_deck_slots()
	for index in range(selected_deck_stamps.size()):
		if selected_deck_stamps[index] is Dictionary:
			var deck_stamp: Dictionary = selected_deck_stamps[index]
			deck_stamp["slot"] = index
			selected_deck_stamps[index] = deck_stamp

func _ensure_selected_deck_slots() -> void:
	while selected_deck_stamps.size() < MAX_DECK_SIZE:
		selected_deck_stamps.append(null)
	if selected_deck_stamps.size() > MAX_DECK_SIZE:
		selected_deck_stamps.resize(MAX_DECK_SIZE)

func _get_selected_deck_stamp_count() -> int:
	var count: int = 0
	for deck_stamp in selected_deck_stamps:
		if deck_stamp is Dictionary:
			count += 1
	return count

func _get_first_empty_deck_slot() -> int:
	_ensure_selected_deck_slots()
	for index in range(selected_deck_stamps.size()):
		if _is_deck_slot_empty(index):
			return index
	return -1

func _is_deck_slot_empty(deck_stamp_index: int) -> bool:
	if deck_stamp_index < 0 or deck_stamp_index >= selected_deck_stamps.size():
		return true
	return !(selected_deck_stamps[deck_stamp_index] is Dictionary)

func _set_deck_slot(deck_stamp_index: int, deck_stamp) -> void:
	_ensure_selected_deck_slots()
	if deck_stamp_index < 0 or deck_stamp_index >= selected_deck_stamps.size():
		return
	if deck_stamp is Dictionary:
		var normalized_stamp: Dictionary = (deck_stamp as Dictionary).duplicate(true)
		normalized_stamp["slot"] = deck_stamp_index
		selected_deck_stamps[deck_stamp_index] = normalized_stamp
	else:
		selected_deck_stamps[deck_stamp_index] = null

func _swap_or_move_deck_slots(source_index: int, target_index: int) -> void:
	_ensure_selected_deck_slots()
	if source_index < 0 or source_index >= selected_deck_stamps.size():
		return
	if target_index < 0 or target_index >= selected_deck_stamps.size():
		return
	if source_index == target_index:
		return
	if !(selected_deck_stamps[source_index] is Dictionary):
		return

	var source_stamp = selected_deck_stamps[source_index]
	var target_stamp = selected_deck_stamps[target_index]
	selected_deck_stamps[target_index] = source_stamp
	selected_deck_stamps[source_index] = target_stamp if target_stamp is Dictionary else null
	_reindex_selected_deck_stamps()

func _get_selected_deck_stamps_for_save() -> Array:
	var stamps: Array = []
	_ensure_selected_deck_slots()
	for index in range(selected_deck_stamps.size()):
		var deck_stamp = selected_deck_stamps[index]
		if !(deck_stamp is Dictionary):
			continue
		var saved_stamp: Dictionary = (deck_stamp as Dictionary).duplicate(true)
		saved_stamp["slot"] = index
		stamps.append(saved_stamp)
	return stamps

func _refresh_selected_deck_stamps() -> void:
	_ensure_selected_deck_slots()
	_sync_deck_stamp_list_width()
	for child in deck_stamp_list.get_children():
		deck_stamp_list.remove_child(child)
		child.queue_free()

	for page_index in range(CODEX_PAGE_COUNT):
		_add_selected_deck_section(tr("Page %d") % (page_index + 1), page_index)

func _add_selected_deck_section(title: String, page_index: int) -> void:
	var section_title := Label.new()
	deck_stamp_list.add_child(section_title)
	section_title.text = title
	section_title.custom_minimum_size = Vector2(0.0, 28.0)
	section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	section_title.theme_type_variation = &"CodexPageTitleLabel"

	var section_line := HSeparator.new()
	deck_stamp_list.add_child(section_line)

	var section_grid_wrapper := CenterContainer.new()
	deck_stamp_list.add_child(section_grid_wrapper)
	section_grid_wrapper.set_meta("codex_page_grid_wrapper", true)
	section_grid_wrapper.custom_minimum_size = Vector2(_get_deck_stamp_list_content_width(), DECK_EDIT_STAMP_SLOT_SIZE.y)
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
		var deck_stamp_index: int = page_index * CODEX_STAMPS_PER_PAGE + page_slot
		if deck_stamp_index < selected_deck_stamps.size() and selected_deck_stamps[deck_stamp_index] is Dictionary:
			var deck_stamp: Dictionary = selected_deck_stamps[deck_stamp_index]
			var stamp_print: StampPrint = _get_print_for_deck_stamp(deck_stamp)
			var stamp: Stamp = StampPrintLibrary.get_stamp_for_print(stamp_print)
			if stamp == null:
				stamp = StampLibrary.duplicate_stamp(str(deck_stamp.get("stamp_name", "")))
			if stamp != null:
				section_grid.add_child(_create_selected_deck_stamp_slot(stamp, stamp_print, deck_stamp_index))
				continue
		section_grid.add_child(_create_empty_codex_slot(deck_stamp_index))

	var bottom_spacer := Control.new()
	deck_stamp_list.add_child(bottom_spacer)
	bottom_spacer.custom_minimum_size = Vector2(0.0, CODEX_PAGE_BOTTOM_SPACING)

func _get_deck_stamp_list_content_width() -> float:
	if deck_stamp_scroll != null and deck_stamp_scroll.size.x > 0.0:
		return deck_stamp_scroll.size.x
	if deck_stamp_list != null and deck_stamp_list.size.x > 0.0:
		return deck_stamp_list.size.x
	if right_column != null and right_column.size.x > 0.0:
		return right_column.size.x
	return float(RIGHT_COLUMN_WIDTH)

func _create_empty_codex_slot(deck_stamp_index: int) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = DECK_EDIT_STAMP_SLOT_SIZE
	slot.mouse_filter = Control.MOUSE_FILTER_PASS
	slot.clip_contents = false
	slot.set_meta("deck_slot_index", deck_stamp_index)
	return slot

func _create_selected_deck_stamp_slot(stamp: Stamp, stamp_print: StampPrint, deck_stamp_index: int) -> Control:
	var stamp_slot := Control.new()
	stamp_slot.custom_minimum_size = DECK_EDIT_STAMP_SLOT_SIZE
	stamp_slot.mouse_filter = Control.MOUSE_FILTER_PASS
	stamp_slot.clip_contents = false
	stamp_slot.set_meta("deck_slot_index", deck_stamp_index)
	if stamp != null:
		stamp_slot.set_meta("stamp_name", stamp.stamp_name)

	var stamp_visual := STAMP_VISUAL.instantiate() as StampVisual
	stamp_slot.add_child(stamp_visual)
	stamp_visual.custom_minimum_size = STAMP_VISUAL_SIZE
	stamp_visual.size = STAMP_VISUAL_SIZE
	stamp_visual.set_hover_raise_enabled(false)
	if stamp_print != null:
		stamp_visual.set_stamp_print(stamp_print)
	else:
		stamp_visual.set_stamp(stamp)
	stamp_visual.set_face_down(false)
	stamp_visual.set_collection_owned(true)
	stamp_visual.draggable = is_creating_deck && !editing_deck_has_missing_stamps
	stamp_visual.disabled = false
	stamp_visual.mouse_filter = Control.MOUSE_FILTER_PASS
	stamp_visual.mouse_entered.connect(_on_browser_stamp_mouse_entered.bind(stamp, stamp_print))
	stamp_visual.mouse_exited.connect(_on_browser_stamp_mouse_exited.bind(stamp.stamp_name if stamp != null else ""))
	stamp_visual.drag_started.connect(_on_selected_deck_stamp_drag_started.bind(deck_stamp_index))
	stamp_visual.drag_released.connect(_on_selected_deck_stamp_drag_released.bind(deck_stamp_index))

	var remove_button: Control = null
	if !editing_deck_has_missing_stamps:
		remove_button = _create_deck_slot_remove_button(deck_stamp_index)
		stamp_slot.add_child(remove_button)
		stamp_slot.mouse_entered.connect(_set_slot_remove_button_visible.bind(remove_button, true))
		stamp_slot.mouse_exited.connect(_queue_slot_remove_button_hover_update.bind(stamp_slot, remove_button))
		stamp_visual.mouse_entered.connect(_set_slot_remove_button_visible.bind(remove_button, true))
		stamp_visual.mouse_exited.connect(_queue_slot_remove_button_hover_update.bind(stamp_slot, remove_button))
		remove_button.mouse_entered.connect(_set_slot_remove_button_visible.bind(remove_button, true))
		remove_button.mouse_exited.connect(_queue_slot_remove_button_hover_update.bind(stamp_slot, remove_button))

	stamp_slot.resized.connect(_layout_selected_deck_stamp_slot.bind(stamp_slot, stamp_visual, remove_button))
	_layout_selected_deck_stamp_slot(stamp_slot, stamp_visual, remove_button)

	return stamp_slot

func _layout_selected_deck_stamp_slot(stamp_slot: Control, stamp_visual: StampVisual, remove_button: Control = null) -> void:
	if stamp_slot == null or stamp_visual == null:
		return

	stamp_slot.custom_minimum_size = DECK_EDIT_STAMP_SLOT_SIZE
	var slot_size: Vector2 = stamp_slot.size
	if slot_size.x <= 0.0 or slot_size.y <= 0.0:
		slot_size = DECK_EDIT_STAMP_SLOT_SIZE
	var scale_factor: float = _get_stamp_scale_for_slot_size(DECK_EDIT_STAMP_SLOT_SIZE)
	stamp_visual.set_rest_scale(Vector2.ONE * scale_factor)
	stamp_visual.size = STAMP_VISUAL_SIZE
	var scaled_stamp_size: Vector2 = STAMP_VISUAL_SIZE * scale_factor
	var desired_draw_top_left: Vector2 = (slot_size - scaled_stamp_size) * 0.5 + Vector2(0.0, DECK_EDIT_STAMP_VERTICAL_OFFSET)
	var home_position: Vector2 = _get_stamp_visual_position_for_draw_top_left(stamp_visual, desired_draw_top_left, scale_factor)
	stamp_visual.set_home_position(home_position, false)
	_layout_deck_slot_remove_button(stamp_visual, remove_button)

func _get_stamp_visual_position_for_draw_top_left(stamp_visual: StampVisual, draw_top_left: Vector2, scale_factor: float) -> Vector2:
	var pivot: Vector2 = stamp_visual.pivot_offset
	if pivot == Vector2.ZERO:
		pivot = STAMP_VISUAL_SIZE * 0.5
	return draw_top_left - pivot * (Vector2.ONE - Vector2.ONE * scale_factor)

func _get_stamp_visual_draw_top_left(stamp_visual: StampVisual) -> Vector2:
	var pivot: Vector2 = stamp_visual.pivot_offset
	if pivot == Vector2.ZERO:
		pivot = STAMP_VISUAL_SIZE * 0.5
	return stamp_visual.position + pivot * (Vector2.ONE - stamp_visual.rest_scale)

func _create_deck_slot_remove_button(deck_stamp_index: int) -> Control:
	var root := Control.new()
	root.tooltip_text = tr("Remove stamp")
	root.custom_minimum_size = DECK_SLOT_REMOVE_BUTTON_SIZE
	root.size = DECK_SLOT_REMOVE_BUTTON_SIZE
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.visible = false
	root.z_index = 80
	root.gui_input.connect(_on_deck_slot_remove_button_gui_input.bind(deck_stamp_index))

	var background := Panel.new()
	root.add_child(background)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_theme_stylebox_override("panel", _create_deck_slot_remove_button_style(Color(CollectionPalette.INK, 0.96)))

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

func _on_deck_slot_remove_button_gui_input(event: InputEvent, deck_stamp_index: int) -> void:
	if !(event is InputEventMouseButton):
		return
	var mouse_button := event as InputEventMouseButton
	if mouse_button.button_index != MOUSE_BUTTON_LEFT or !mouse_button.pressed:
		return
	accept_event()
	_on_remove_selected_deck_stamp_pressed(deck_stamp_index)

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

func _layout_deck_slot_remove_button(stamp_visual: StampVisual, remove_button: Control) -> void:
	if stamp_visual == null or remove_button == null or !is_instance_valid(remove_button):
		return

	remove_button.custom_minimum_size = DECK_SLOT_REMOVE_BUTTON_SIZE
	remove_button.size = DECK_SLOT_REMOVE_BUTTON_SIZE
	var scaled_stamp_size: Vector2 = STAMP_VISUAL_SIZE * stamp_visual.rest_scale
	var stamp_top_left: Vector2 = _get_stamp_visual_draw_top_left(stamp_visual)
	remove_button.position = stamp_top_left + Vector2(scaled_stamp_size.x - DECK_SLOT_REMOVE_BUTTON_SIZE.x - 2.0, 2.0)

func _set_slot_remove_button_visible(remove_button: Control, should_show: bool) -> void:
	if remove_button == null or !is_instance_valid(remove_button):
		return
	remove_button.visible = should_show && is_creating_deck && !editing_deck_has_missing_stamps

func _queue_slot_remove_button_hover_update(stamp_slot: Control, remove_button: Control) -> void:
	call_deferred("_update_slot_remove_button_hover", stamp_slot, remove_button)

func _update_slot_remove_button_hover(stamp_slot: Control, remove_button: Control) -> void:
	if stamp_slot == null or remove_button == null or !is_instance_valid(stamp_slot) or !is_instance_valid(remove_button):
		return
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var is_hovered: bool = stamp_slot.get_global_rect().has_point(mouse_position)
	_set_slot_remove_button_visible(remove_button, is_hovered)

func _on_selected_deck_stamp_drag_started(_stamp_visual: StampVisual, deck_stamp_index: int) -> void:
	_set_stamp_drag_floating(_stamp_visual, true)

func _on_selected_deck_stamp_drag_released(stamp_visual: StampVisual, deck_stamp_index: int) -> void:
	_set_stamp_drag_floating(stamp_visual, false)
	if !is_creating_deck or editing_deck_has_missing_stamps:
		if stamp_visual != null and is_instance_valid(stamp_visual):
			stamp_visual.fly_home()
		return

	var mouse_position := get_viewport().get_mouse_position()
	if !deck_stamp_scroll.get_global_rect().has_point(mouse_position):
		if stamp_visual != null and is_instance_valid(stamp_visual):
			stamp_visual.fly_home()
		return

	var target_index: int = _get_deck_drop_index(mouse_position)
	if target_index < 0 or target_index >= MAX_DECK_SIZE or target_index == deck_stamp_index:
		if stamp_visual != null and is_instance_valid(stamp_visual):
			stamp_visual.fly_home()
		return

	_swap_or_move_deck_slots(deck_stamp_index, target_index)
	_refresh_selected_deck_stamps()
	_update_deck_editor_state()

func _set_stamp_drag_floating(stamp_visual: StampVisual, floating: bool) -> void:
	if stamp_visual == null or !is_instance_valid(stamp_visual):
		return
	var previous_global_position: Vector2 = stamp_visual.global_position
	stamp_visual.top_level = floating
	stamp_visual.global_position = previous_global_position
	if floating:
		stamp_visual.z_as_relative = false
		stamp_visual.z_index = DRAGGED_STAMP_Z_INDEX
	else:
		stamp_visual.z_as_relative = true
		stamp_visual.z_index = 0

func _on_remove_selected_deck_stamp_pressed(deck_stamp_index: int) -> void:
	if editing_deck_has_missing_stamps:
		return
	if deck_stamp_index < 0 or deck_stamp_index >= selected_deck_stamps.size():
		return

	selected_deck_stamps[deck_stamp_index] = null
	_reindex_selected_deck_stamps()
	_refresh_selected_deck_stamps()
	_update_deck_editor_state()
	_show_page(stamp_browser_controller.get_current_page())

func _populate_saved_decks_list() -> void:
	saved_deck_list_controller.populate_saved_decks_list()

func _get_print_for_deck_stamp(deck_stamp: Dictionary) -> StampPrint:
	var print_id: String = str(deck_stamp.get("print_id", ""))
	if !print_id.is_empty():
		var stamp_print: StampPrint = StampPrintLibrary.get_print(print_id)
		if stamp_print != null:
			return stamp_print

	var stamp_code: String = str(deck_stamp.get("stamp_code", ""))
	if stamp_code.is_empty():
		var stamp: Stamp = StampLibrary.get_stamp(str(deck_stamp.get("stamp_name", "")))
		if stamp != null:
			stamp_code = PlayerCollectionStore.get_stamp_code(stamp)

	var variant_id: String = str(deck_stamp.get("variant_id", PlayerCollectionStore.DEFAULT_VARIANT_ID))
	return StampPrintLibrary.get_print(StampPrintLibrary.get_print_id(stamp_code, variant_id))

func _get_deck_stamp_display_name(stamp: Stamp, stamp_print: StampPrint) -> String:
	if stamp_print == null or stamp_print.variant_id == PlayerCollectionStore.DEFAULT_VARIANT_ID:
		return stamp.stamp_name
	return "%s - %s" % [stamp.stamp_name, stamp_print.get_display_name()]

func _create_deck_stamp_entry(print_id: String, slot: int) -> Dictionary:
	var stamp_print: StampPrint = StampPrintLibrary.get_print(print_id)
	var stamp: Stamp = StampPrintLibrary.get_stamp_for_print(stamp_print)
	if stamp == null:
		return {}

	var owned_item: Dictionary = PlayerCollectionStore.get_owned_item_for_print(stamp_print)
	var stamp_code: String = PlayerCollectionStore.get_stamp_code(stamp)
	var variant_id: String = str(owned_item.get("variant_id", stamp_print.variant_id))
	if variant_id.is_empty():
		variant_id = PlayerCollectionStore.DEFAULT_VARIANT_ID

	return {
		"slot": slot,
		"print_id": stamp_print.print_id,
		"stamp_code": stamp_code,
		"stamp_name": stamp.stamp_name,
		"variant_id": variant_id,
		"variant_name": str(owned_item.get("variant_name", stamp_print.get_display_name())),
		"collection_instance_id": str(owned_item.get("instance_id", "")),
		"item_def_key": str(owned_item.get("item_def_key", stamp_print.print_id)),
		"steam_item_instance_id": str(owned_item.get("steam_item_instance_id", "")),
		"steam_item_def_id": str(owned_item.get("steam_item_def_id", "")),
	}

func _can_add_stamp_to_deck(stamp: Stamp) -> bool:
	if stamp == null:
		return false

	return _get_selected_stamp_count(stamp) < MAX_COPIES_PER_STAMP

func _get_selected_stamp_count(stamp: Stamp) -> int:
	if stamp == null:
		return 0

	var stamp_code: String = PlayerCollectionStore.get_stamp_code(stamp)
	var count: int = 0
	for deck_stamp in selected_deck_stamps:
		if deck_stamp is Dictionary && str(deck_stamp.get("stamp_code", "")) == stamp_code:
			count += 1
	return count

func _has_too_many_stamp_copies() -> bool:
	var stamp_counts: Dictionary = {}
	for deck_stamp in selected_deck_stamps:
		if !(deck_stamp is Dictionary):
			continue

		var stamp_code: String = str(deck_stamp.get("stamp_code", "")).strip_edges()
		if stamp_code.is_empty():
			continue

		var next_count: int = int(stamp_counts.get(stamp_code, 0)) + 1
		if next_count > MAX_COPIES_PER_STAMP:
			return true
		stamp_counts[stamp_code] = next_count
	return false

func _has_selected_seeker_stamp() -> bool:
	for deck_stamp in selected_deck_stamps:
		if !(deck_stamp is Dictionary):
			continue

		var stamp_print: StampPrint = _get_print_for_deck_stamp(deck_stamp)
		var print_stamp: Stamp = StampPrintLibrary.get_stamp_for_print(stamp_print)
		if MoveRules.is_seeker_stamp(print_stamp):
			return true

		var stamp: Stamp = StampLibrary.get_stamp(str(deck_stamp.get("stamp_name", "")))
		if MoveRules.is_seeker_stamp(stamp):
			return true

		var stamp_by_code: Stamp = StampLibrary.get_stamp_by_code(str(deck_stamp.get("stamp_code", "")))
		if MoveRules.is_seeker_stamp(stamp_by_code):
			return true

	return false

func _on_edit_deck_pressed(deck_data: Dictionary) -> void:
	is_creating_deck = true
	is_editing_deck_name = false
	editing_deck_id = str(deck_data.get("deck_id", ""))
	deck_name_edit.text = str(deck_data.get("name", ""))
	_sync_deck_name_display()
	selected_deck_stamps.clear()
	_ensure_selected_deck_slots()
	var ownership_info: Dictionary = PlayerDeckStore.get_deck_ownership_info(deck_data)
	editing_deck_has_missing_stamps = int(ownership_info.get("missing_count", 0)) > 0

	var stamps: Array = []
	if editing_deck_has_missing_stamps:
		stamps = PlayerDeckStore.get_owned_stamps_from_deck(deck_data)
	else:
		var deck_stamps = deck_data.get("stamps", [])
		if deck_stamps is Array:
			stamps = deck_stamps

	for index in range(stamps.size()):
		var deck_stamp = stamps[index]
		if deck_stamp is Dictionary:
			var normalized_stamp: Dictionary = deck_stamp.duplicate(true)
			var slot_index: int = int(normalized_stamp.get("slot", index))
			if slot_index < 0 or slot_index >= MAX_DECK_SIZE or !_is_deck_slot_empty(slot_index):
				slot_index = _get_first_empty_deck_slot()
			if slot_index == -1:
				break
			_set_deck_slot(slot_index, normalized_stamp)

	dragged_print_id = ""
	_refresh_selected_deck_stamps()
	_update_deck_editor_state()
	_show_page(stamp_browser_controller.get_current_page())
