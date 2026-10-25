extends CanvasLayer

## The bar across the top of the hub screens, in two zones (Docs/TopBar):
##   * left - the logo on the main menu; on a sub-screen Back, then that
##     screen's own buttons right after it. Clipped, so it gives way first.
##   * right - anchored to the right edge, right to left: menu button (out of
##     use off the main menu) -> counters (rank, coin, draw points, as the story reveals
##     them) -> quest ribbons (oldest next to the counters, each new one to its
##     left). Nothing screen-specific ever goes in here.
## The right group is laid out by hand rather than by a container, so ribbons
## and counters can slide to their new places and drop in or leave without a
## container snapping them first.

const MAIN_MENU_MODE: String = "main_menu"
const COLLECTION_MODE: String = "collection"
## Just the counters, for screens that pay coins out (reward scenes).
const POINTS_ONLY_MODE: String = "points_only"
const MAIN_MENU_SCENE: String = "res://Scenes/MainMenu.tscn"
const COLLECTION_SCENE: String = "res://Scenes/Collection.tscn"
## Arriving, a scene's items are stamped onto the paper (_stamp_items_in).
const STAMP_SECONDS: float = 0.42
const STAMP_START_SCALE: float = 1.3
## How far a stamp is turned before it lands, either way, in degrees.
const STAMP_MIN_TILT: float = 1.5
const STAMP_MAX_TILT: float = 6.0
## Leaving, they dissolve into the paper (_dissolve_items_out).
const DISSOLVE_SECONDS: float = 0.4
const ITEM_STAGGER_SECONDS: float = 0.07
const INK_DISSOLVE_SHADER: Shader = preload("res://Shaders/ink_dissolve.gdshader")
const FRONT_NOISE_PATH: String = "res://ui/themes/stamp/ink_flood_noise.png"
const LOGO_REVEAL_SHADER: Shader = preload("res://Shaders/art_line_reveal.gdshader")
## Made by tools/generate_line_reveal_mask.py (see there) from
## Assets/golem_logo_reveal_source.png, the logo rasterized at half size.
const LOGO_REVEAL_MASK_PATH: String = "res://Assets/golem_logo_reveal_mask.png"
## The logo's writing: each stroke takes up to this long, and the last starts
## this long after the first.
const LOGO_STROKE_SECONDS: float = 0.5
const LOGO_SPREAD_SECONDS: float = 1.0
const SINGLEPLAYER_UNLOCK_KEY: Key = KEY_A
const SINGLEPLAYER_UNLOCK_PRESS_COUNT: int = 3
## How often the time left on daily quests is brought up to date on screen.
const QUEST_CLOCK_SECONDS: float = 20.0
## Frames to wait at most for a quest panel's wrapped text to settle.
const PANEL_LAYOUT_FRAMES: int = 5

const TopBarStyle = preload("res://Scripts/TopBar/TopBarStyle.gd")
const QuestRibbon = preload("res://Scripts/TopBar/QuestRibbon.gd")
const QuestPanel = preload("res://Scripts/TopBar/QuestPanel.gd")
const TopBarCounter = preload("res://Scripts/TopBar/TopBarCounter.gd")
const TopBarMenu = preload("res://Scripts/TopBar/TopBarMenu.gd")

## Right to left: the rank stands next to the menu, draw points nearest the ribbons.
const COUNTER_ORDER: Array[String] = ["rank", "coin", "draw"]
const COUNTER_FEATURE: Dictionary = {
	"rank": StoryFeatures.RANK_COUNTER,
	"coin": StoryFeatures.COIN_COUNTER,
	"draw": StoryFeatures.DRAW_COUNTER,
}

@onready var root: Control = $Root
@onready var top_background: ColorRect = $Root/TopBackground
@onready var scene_items_clip: Control = $Root/SceneItemsClip
@onready var main_menu_items: HBoxContainer = $Root/SceneItemsClip/MainMenuItems
@onready var collection_items: HBoxContainer = $Root/SceneItemsClip/CollectionItems
@onready var back_button: Button = $Root/SceneItemsClip/CollectionItems/BackSlot/BackButton
@onready var buy_packs_button: Button = $Root/SceneItemsClip/CollectionItems/BuyPacksSlot/BuyPacksButton
@onready var version_label: Label = $Root/SceneItemsClip/MainMenuItems/VersionSlot/VersionLabel
@onready var logo: TextureRect = $Root/SceneItemsClip/MainMenuItems/LogoSlot/Logo
@onready var right_group: Control = $Root/RightGroup

var current_mode: String = ""
var pending_mode: String = ""
var active_items: HBoxContainer
var scene_items_tween: Tween
var button_by_id: Dictionary = {}
var pressed_connections: Dictionary = {}
var scene_transition_active: bool = false
var singleplayer_unlock_presses: int = 0

var menu: TopBarMenu
var quest_panel: QuestPanel
var counters: Dictionary = {}
## The coin counter's parts, kept under their old names for the screens and
## reward presenters that write into them.
var points_hud: Control
var point_icon: Control
var points_label: Label
var rating_label: Label

var _ribbons: Dictionary = {}
## Quest ids oldest first, including ribbons still playing their way out.
var _ribbon_order: Array[String] = []
var _ribbons_shown: bool = false
var _quests_synced: bool = false
var _open_quest_id: String = ""
var _open_token: int = 0
var _target_x: Dictionary = {}
var _slide_tweens: Dictionary = {}
var _layout_queued: bool = false
var _dissolve_material: ShaderMaterial
var _logo_reveal_material: ShaderMaterial
## The button whose window is open over its screen (set_window_open).
var _window_opener: Button


func _ready() -> void:
	layer = 1200
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_items_clip.clip_contents = true
	scene_items_clip.mouse_filter = Control.MOUSE_FILTER_PASS
	right_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	version_label.text = "v%s" % str(ProjectSettings.get_setting("application/config/version", "0.0.8"))

	_build_counters()
	_build_menu()
	quest_panel = QuestPanel.new()
	quest_panel.name = "QuestPanel"
	quest_panel.claim_requested.connect(_on_claim_requested)
	root.add_child(quest_panel)
	# Below the ribbons, so the open ribbon is the panel's left edge.
	root.move_child(quest_panel, right_group.get_index())

	button_by_id = {
		"settings": menu.get_item("settings"),
		"exit": menu.get_item("exit"),
		"tutorial": menu.get_item("tutorial"),
		"singleplayer": menu.get_item("singleplayer"),
		"multiplayer": menu.get_item("multiplayer"),
		"back": back_button,
		"buy_packs": buy_packs_button,
	}
	for slot_button in [back_button, buy_packs_button]:
		slot_button.minimum_size_changed.connect(_fit_slot_to_button.bind(slot_button))
		_fit_slot_to_button(slot_button)
	buy_packs_button.toggled.connect(_keep_window_opener_pressed.bind(buy_packs_button))
	collection_items.visible = false
	_build_item_materials()

	root.resized.connect(_queue_layout)
	QuestStore.quest_added.connect(_on_quest_added)
	QuestStore.quest_changed.connect(_on_quest_changed)
	QuestStore.quest_removed.connect(_on_quest_removed)
	QuestStore.quest_claimed.connect(_on_quest_claimed)
	StoryProgressStore.feature_unlocked.connect(_on_feature_unlocked)

	var quest_clock := Timer.new()
	quest_clock.name = "QuestClock"
	quest_clock.wait_time = QUEST_CLOCK_SECONDS
	quest_clock.autostart = true
	quest_clock.timeout.connect(_refresh_quest_clock)
	add_child(quest_clock)


func _input(event: InputEvent) -> void:
	var mouse_button := event as InputEventMouseButton
	if mouse_button != null and mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_LEFT:
		if !_open_quest_id.is_empty() and !_is_inside_open_quest(mouse_button.position):
			_close_quest_panel()
		if menu.is_open() and !menu.contains_global_point(mouse_button.position):
			menu.set_open(false)
		return

	if event.is_action_pressed("ui_cancel") and (!_open_quest_id.is_empty() or menu.is_open()):
		_close_quest_panel()
		menu.set_open(false)
		get_viewport().set_input_as_handled()
		return

	_check_singleplayer_unlock(event)


func _check_singleplayer_unlock(event: InputEvent) -> void:
	if current_mode != MAIN_MENU_MODE or menu.get_item("singleplayer").visible:
		return
	if get_viewport().gui_get_focus_owner() is LineEdit:
		return

	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or !key_event.pressed or key_event.echo:
		return

	if key_event.keycode == SINGLEPLAYER_UNLOCK_KEY:
		singleplayer_unlock_presses += 1
		if singleplayer_unlock_presses >= SINGLEPLAYER_UNLOCK_PRESS_COUNT:
			singleplayer_unlock_presses = 0
			menu.set_item_visible("singleplayer", true)
	else:
		singleplayer_unlock_presses = 0


func show_main_menu(settings_pressed: Callable, exit_pressed: Callable, singleplayer_pressed: Callable = Callable(), multiplayer_pressed: Callable = Callable(), tutorial_pressed: Callable = Callable()) -> void:
	_replace_button_connection(menu.get_item("settings"), settings_pressed)
	_replace_button_connection(menu.get_item("exit"), exit_pressed)
	_replace_button_connection(menu.get_item("singleplayer"), singleplayer_pressed)
	_replace_button_connection(menu.get_item("multiplayer"), multiplayer_pressed)
	_replace_button_connection(menu.get_item("tutorial"), tutorial_pressed)
	menu.set_item_visible("settings", settings_pressed.is_valid())
	menu.set_item_visible("exit", exit_pressed.is_valid())
	menu.set_item_visible("multiplayer", multiplayer_pressed.is_valid())
	menu.set_item_visible("tutorial", tutorial_pressed.is_valid())
	_show_mode(MAIN_MENU_MODE)


func show_collection(back_pressed: Callable, buy_packs_pressed: Callable = Callable()) -> void:
	_replace_button_connection(back_button, back_pressed)
	_replace_button_connection(buy_packs_button, buy_packs_pressed)
	set_window_open("buy_packs", false)
	_show_mode(COLLECTION_MODE)


## While a screen's own window is open over it (the collection's pack shop),
## the button that opened it stays pressed in ink and Back is out of use;
## both come back when it closes.
func set_window_open(opener_id: String, open: bool) -> void:
	if !open:
		_release_window_opener()
		return
	var opener: Button = get_button(opener_id)
	if opener != null:
		opener.toggle_mode = true
		opener.set_pressed_no_signal(true)
	_window_opener = opener
	back_button.disabled = true


func _release_window_opener() -> void:
	if _window_opener != null:
		_window_opener.toggle_mode = false
		_window_opener.set_pressed_no_signal(false)
	_window_opener = null
	back_button.disabled = false


## A pressed opener clicked again stays pressed: its window is still open.
func _keep_window_opener_pressed(pressed: bool, button: Button) -> void:
	if !pressed and button == _window_opener:
		button.set_pressed_no_signal(true)


## Shows only the bar and its counters - no menu items, no ribbons - so a
## reward scene has a real counter for its coins to fly into. The coin counter
## shows here even before the story has revealed it. Leaving the scene hides
## it again through prepare_for_scene_change like any other mode.
func show_points_only() -> void:
	if scene_items_tween != null and scene_items_tween.is_valid():
		scene_items_tween.kill()
	_close_quest_panel(false)
	menu.close_now()
	_settle_items(main_menu_items)
	_settle_items(collection_items)
	main_menu_items.visible = false
	collection_items.visible = false
	root.visible = true
	top_background.visible = true
	menu.visible = false
	current_mode = POINTS_ONLY_MODE
	pending_mode = ""
	active_items = null
	_set_ribbons_shown(false)
	refresh_points()
	_layout_right_group(false)

## Centre of the coin icon in screen space - the target for flying coins.
func get_coin_global_center() -> Vector2:
	if point_icon == null:
		return Vector2.ZERO
	return point_icon.global_position + point_icon.size * 0.5

## Writes a number into the counter without touching the store, for count-up
## animations. refresh_points() puts the real value back.
func set_displayed_points(value: int) -> void:
	if counters.has("coin"):
		counters["coin"].set_value(maxi(0, value))

## A quick grow-and-settle on the counter, for when a coin lands in it.
func pulse_points_hud() -> void:
	if counters.has("coin"):
		counters["coin"].pulse()

func prepare_for_scene_change(target_scene_path: String) -> void:
	_close_quest_panel(false)
	menu.close_now()
	# A screen's window does not outlive the screen.
	_release_window_opener()
	var target_mode: String = _mode_for_scene_path(target_scene_path)
	if target_mode == current_mode:
		return

	pending_mode = target_mode
	if current_mode.is_empty() or active_items == null:
		if target_mode.is_empty():
			root.visible = false
		return

	_dissolve_items_out(active_items, target_mode.is_empty())


func set_scene_transition_active(active: bool) -> void:
	scene_transition_active = active
	_set_container_items_interactive(active_items, !scene_transition_active and root.visible)
	_set_right_group_interactive(!scene_transition_active)


## Reloads every counter from the stores.
func refresh_points() -> void:
	if points_label == null:
		return
	if Engine.is_editor_hint():
		for counter in counters.values():
			counter.set_value_text("0")
		return
	PlayerProgressStore.ensure_loaded()
	counters["coin"].set_value(PlayerProgressStore.get_points())
	counters["draw"].set_value(PlayerProgressStore.get_draw_points())
	refresh_rating()
	_refresh_counter_visibility(false)


func refresh_rating() -> void:
	if rating_label == null:
		return
	if Engine.is_editor_hint():
		rating_label.text = "-"
		return
	counters["rank"].set_value(PlayerProgressStore.get_rating())


func get_button(button_id: String) -> Button:
	return button_by_id.get(button_id, null) as Button


func _build_counters() -> void:
	for kind in COUNTER_ORDER:
		var counter := TopBarCounter.new(kind)
		counter.visible = false
		right_group.add_child(counter)
		counter.minimum_size_changed.connect(_on_counter_size_changed.bind(counter))
		counters[kind] = counter
	points_hud = counters["coin"]
	point_icon = counters["coin"].icon_control
	points_label = counters["coin"].value_label
	rating_label = counters["rank"].value_label


func _build_menu() -> void:
	menu = TopBarMenu.new()
	menu.visible = false
	right_group.add_child(menu)
	menu.add_item(0, "multiplayer", "people", "Alpha Multiplayer", "TOPBAR_TEMPORARY_TAG")
	menu.add_item(0, "singleplayer", "person", "Singleplayer", "TOPBAR_TEMPORARY_TAG")
	menu.add_item(1, "settings", "gear", "Settings")
	menu.add_item(1, "tutorial", "help", "Tutorial")
	menu.add_item(2, "exit", "door", "Exit")
	# Revealed by pressing A three times on the main menu.
	menu.set_item_visible("singleplayer", false)
	menu.opened.connect(_close_quest_panel)


func _show_mode(mode: String) -> void:
	var target_items := _container_for_mode(mode)
	if target_items == null:
		return

	# Already up (another bar screen, or a reward scene's counters): slide into the new layout.
	var bar_was_visible: bool = root.visible
	root.visible = true
	top_background.visible = true
	# Off the main menu the menu button stays, out of use, so nothing shifts.
	menu.visible = true
	menu.button.disabled = mode != MAIN_MENU_MODE
	if menu.button.disabled:
		menu.close_now()
	_set_ribbons_shown(true)
	refresh_points()
	_layout_right_group(bar_was_visible)

	if current_mode == mode and active_items == target_items:
		target_items.visible = true
		_settle_items(target_items)
		_set_container_items_interactive(target_items, !scene_transition_active)
		return

	# The other row too when the bar first comes up on this screen, not the
	# main menu's.
	for items in [main_menu_items, collection_items]:
		if items != target_items:
			items.visible = false

	current_mode = mode
	pending_mode = ""
	active_items = target_items
	_stamp_items_in(target_items)


# --- Right group layout ---------------------------------------------------------

func _queue_layout() -> void:
	if _layout_queued:
		return
	_layout_queued = true
	_run_queued_layout.call_deferred()


func _run_queued_layout() -> void:
	_layout_queued = false
	_layout_right_group(false)


## Places the menu, counters and ribbons from the right edge leftwards and
## gives the left zone whatever is left. Animated, things slide to their new
## places; a ribbon that is new gets its place at once (it drops in from above).
func _layout_right_group(animate: bool) -> void:
	var bar_width: float = root.size.x
	if bar_width <= 0.0:
		return
	animate = animate and root.is_visible_in_tree()
	var cursor: float = bar_width - TopBarStyle.BAR_MARGIN
	var left_edge: float = cursor

	if menu.visible:
		left_edge = cursor - TopBarStyle.BUTTON_SIZE
		_place(menu, Vector2(left_edge, (TopBarStyle.BAR_HEIGHT - TopBarStyle.BUTTON_SIZE) * 0.5), animate, true)
		cursor = left_edge - TopBarStyle.GROUP_GAP

	for kind in COUNTER_ORDER:
		var counter: Control = counters[kind]
		if !counter.visible:
			continue
		var counter_size: Vector2 = counter.get_combined_minimum_size()
		left_edge = cursor - counter_size.x
		_place(counter, Vector2(left_edge, roundf((TopBarStyle.BAR_HEIGHT - counter_size.y) * 0.5)), animate, true)
		cursor = left_edge - TopBarStyle.GROUP_GAP

	if _ribbons_shown:
		for quest_id in _ribbon_order:
			var ribbon: Control = _ribbons[quest_id]
			left_edge = cursor - TopBarStyle.RIBBON_WIDTH
			_place(ribbon, Vector2(left_edge, 0.0), animate, false)
			cursor = left_edge - TopBarStyle.RIBBON_GAP

	var clip_right: float = left_edge - TopBarStyle.GROUP_GAP if left_edge < bar_width - TopBarStyle.BAR_MARGIN else bar_width - TopBarStyle.BAR_MARGIN
	scene_items_clip.offset_right = clip_right - bar_width


## Moves an item of the right group to its place; x slides when animated, y
## is set at once when set_y (ribbons animate their own y).
func _place(item: Control, target: Vector2, animate: bool, set_y: bool) -> void:
	var known: bool = _target_x.has(item)
	var previous_x: float = _target_x.get(item, target.x)
	_target_x[item] = target.x
	if set_y:
		item.position.y = target.y
	if animate and known and !is_equal_approx(previous_x, target.x):
		var running: Tween = _slide_tweens.get(item, null)
		if running != null and running.is_valid():
			running.kill()
		var slide := item.create_tween()
		slide.tween_property(item, "position:x", target.x, TopBarStyle.SLIDE_SECONDS).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		_slide_tweens[item] = slide
		return
	var stale: Tween = _slide_tweens.get(item, null)
	if stale != null and stale.is_valid():
		if animate and known:
			return
		stale.kill()
	item.position.x = target.x


func _on_counter_size_changed(counter: Control) -> void:
	counter.reset_size()
	_queue_layout()


func _set_right_group_interactive(interactive: bool) -> void:
	var filter: Control.MouseFilter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	menu.button.mouse_filter = filter
	for ribbon in _ribbons.values():
		if !ribbon.is_leaving():
			ribbon.mouse_filter = filter


# --- Counters ---------------------------------------------------------------------

func _is_counter_unlocked(kind: String) -> bool:
	if Engine.is_editor_hint():
		return true
	return StoryProgressStore.is_feature_unlocked(COUNTER_FEATURE.get(kind, ""))


func _refresh_counter_visibility(animate: bool) -> void:
	var changed: bool = false
	for kind in COUNTER_ORDER:
		var counter: TopBarCounter = counters[kind]
		var shown: bool = _is_counter_unlocked(kind) or (kind == "coin" and current_mode == POINTS_ONLY_MODE)
		if counter.visible == shown:
			continue
		changed = true
		counter.visible = shown
		if shown:
			counter.reset_size()
			if animate:
				counter.play_pop()
	if changed:
		_layout_right_group(animate)


func _on_feature_unlocked(feature_id: String) -> void:
	if !COUNTER_FEATURE.values().has(feature_id) or !root.visible:
		return
	_close_quest_panel()
	_refresh_counter_visibility(true)


# --- Quest ribbons ----------------------------------------------------------------

func _set_ribbons_shown(shown: bool) -> void:
	if shown and !_quests_synced:
		_quests_synced = true
		QuestStore.expire_overdue_quests()
		_sync_ribbons()
	_ribbons_shown = shown
	if !shown:
		_close_quest_panel(false)
	for ribbon in _ribbons.values():
		ribbon.visible = shown


## Matches the ribbons to the store without animation: for a first showing,
## where the bar should simply look like the save.
func _sync_ribbons() -> void:
	var active_ids: Dictionary = {}
	for quest in QuestStore.get_active_quests():
		var quest_id: String = str(quest["id"])
		active_ids[quest_id] = true
		if _ribbons.has(quest_id):
			_ribbons[quest_id].configure(quest, QuestStore.is_urgent(quest))
		else:
			_add_ribbon(quest, false)
	for quest_id in _ribbon_order.duplicate():
		if !active_ids.has(quest_id):
			_drop_ribbon(quest_id)


func _ribbons_on_screen() -> bool:
	return _ribbons_shown and root.is_visible_in_tree()


func _add_ribbon(quest: Dictionary, animate: bool) -> void:
	var quest_id: String = str(quest["id"])
	if _ribbons.has(quest_id):
		return
	_close_quest_panel()
	var ribbon := QuestRibbon.new()
	ribbon.name = "Ribbon_%s" % quest_id
	ribbon.visible = _ribbons_shown
	right_group.add_child(ribbon)
	# Under the menu, so its dropdown covers the ribbons.
	right_group.move_child(ribbon, menu.get_index())
	ribbon.configure(quest, QuestStore.is_urgent(quest))
	ribbon.pressed.connect(_on_ribbon_pressed.bind(quest_id))
	if scene_transition_active:
		ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ribbons[quest_id] = ribbon
	_ribbon_order.append(quest_id)
	_layout_right_group(animate)
	if animate:
		ribbon.play_arrival()


## Claimed and discarded ribbons are pulled up, expired ones grey out first;
## once gone, the ribbons to their left slide one place right.
func _remove_ribbon(quest_id: String, reason: String) -> void:
	var ribbon = _ribbons.get(quest_id, null)
	if ribbon == null or ribbon.is_leaving():
		return
	if _open_quest_id == quest_id:
		_close_quest_panel()
	if !_ribbons_on_screen():
		_drop_ribbon(quest_id)
		return
	ribbon.left_bar.connect(_drop_ribbon.bind(quest_id), CONNECT_ONE_SHOT)
	ribbon.play_leave("expire" if reason == QuestStore.REASON_EXPIRED else "claim")


func _drop_ribbon(quest_id: String) -> void:
	var ribbon = _ribbons.get(quest_id, null)
	if ribbon == null:
		return
	if _open_quest_id == quest_id:
		_close_quest_panel(false)
	_ribbons.erase(quest_id)
	_ribbon_order.erase(quest_id)
	_target_x.erase(ribbon)
	_slide_tweens.erase(ribbon)
	ribbon.queue_free()
	_layout_right_group(true)


func _on_quest_added(quest: Dictionary) -> void:
	if _quests_synced:
		_add_ribbon(quest, _ribbons_on_screen())


func _on_quest_changed(quest: Dictionary) -> void:
	var quest_id: String = str(quest.get("id", ""))
	if !_quests_synced or !_ribbons.has(quest_id):
		return
	_ribbons[quest_id].configure(quest, QuestStore.is_urgent(quest))
	if _open_quest_id == quest_id:
		_open_quest_panel(quest_id, false)


func _on_quest_removed(quest: Dictionary, reason: String) -> void:
	if _quests_synced:
		_remove_ribbon(str(quest.get("id", "")), reason)


## A claimed reward lands in its counter with a hop and a floating "+50".
func _on_quest_claimed(quest: Dictionary) -> void:
	var reward: String = str(quest.get("reward", ""))
	if !counters.has(reward):
		return
	refresh_points()
	if counters[reward].visible and root.is_visible_in_tree():
		counters[reward].play_bump(int(quest.get("amount", 0)))


func _on_claim_requested(quest_id: String) -> void:
	QuestStore.claim_quest(quest_id)


## The time left on daily quests moves on: urgency on the ribbons, the clock
## in an open panel.
func _refresh_quest_clock() -> void:
	if !_quests_synced or !root.visible:
		return
	for quest in QuestStore.get_active_quests():
		var quest_id: String = str(quest["id"])
		if !_ribbons.has(quest_id) or int(quest.get("expires_at", 0)) <= 0:
			continue
		_ribbons[quest_id].configure(quest, QuestStore.is_urgent(quest))
		if _open_quest_id == quest_id:
			if !quest_panel.update_time_left(QuestStore.format_time_left(quest), QuestStore.is_urgent(quest)):
				_open_quest_panel(quest_id, false)


# --- Quest panel ------------------------------------------------------------------

func _on_ribbon_pressed(quest_id: String) -> void:
	if _open_quest_id == quest_id:
		_close_quest_panel()
		return
	_close_quest_panel()
	_open_quest_panel(quest_id, true)


## Opens (or, with replay off, refreshes in place) the panel beside a ribbon:
## the other ribbons draw up, and once the wrapped text has a height the
## ribbon runs down to the panel's bottom and the panel fades in beside it.
## Opens to the left when it would run off the right edge of the screen.
func _open_quest_panel(quest_id: String, replay: bool) -> void:
	var ribbon = _ribbons.get(quest_id, null)
	var quest: Dictionary = QuestStore.get_quest(quest_id)
	if ribbon == null or quest.is_empty() or ribbon.is_leaving():
		return
	if replay:
		menu.set_open(false)
	_open_quest_id = quest_id
	_open_token += 1
	var token: int = _open_token

	var ribbon_x: float = _target_x.get(ribbon, ribbon.position.x)
	var open_left: bool = ribbon_x + TopBarStyle.RIBBON_WIDTH + TopBarStyle.PANEL_WIDTH > root.size.x
	quest_panel.show_quest(quest, QuestStore.format_time_left(quest), QuestStore.is_urgent(quest), open_left)
	quest_panel.position = Vector2(ribbon_x - TopBarStyle.PANEL_WIDTH if open_left else ribbon_x + TopBarStyle.RIBBON_WIDTH, TopBarStyle.BAR_HEIGHT)
	for other_id in _ribbons:
		if other_id != quest_id:
			_ribbons[other_id].set_retracted(true)
	quest_panel.visible = true
	quest_panel.modulate.a = 0.0 if replay else 1.0

	# The wrapped title and text need a layout pass or two before the panel's
	# height is right; wait until it stops changing.
	var last_height: float = -1.0
	for _frame in range(PANEL_LAYOUT_FRAMES):
		await get_tree().process_frame
		if token != _open_token:
			return
		quest_panel.reset_size()
		if is_equal_approx(quest_panel.size.y, last_height):
			break
		last_height = quest_panel.size.y

	ribbon.set_retracted(false)
	ribbon.set_open(true, TopBarStyle.BAR_HEIGHT + quest_panel.size.y)
	if replay:
		quest_panel.play_in()


func _close_quest_panel(animate: bool = true) -> void:
	if _open_quest_id.is_empty():
		return
	var ribbon = _ribbons.get(_open_quest_id, null)
	_open_quest_id = ""
	_open_token += 1
	if ribbon != null:
		ribbon.set_open(false)
	for other in _ribbons.values():
		other.set_retracted(false)
	if animate:
		quest_panel.play_out()
	else:
		quest_panel.hide_now()


func _is_inside_open_quest(point: Vector2) -> bool:
	if quest_panel.visible and quest_panel.get_global_rect().has_point(point):
		return true
	var ribbon = _ribbons.get(_open_quest_id, null)
	return ribbon != null and ribbon.get_global_rect().has_point(point)


# --- Left zone --------------------------------------------------------------------

func _replace_button_connection(button: Button, pressed_callable: Callable) -> void:
	if button == null:
		return

	if pressed_connections.has(button):
		var previous_callable: Callable = pressed_connections[button]
		if previous_callable.is_valid() and button.pressed.is_connected(previous_callable):
			button.pressed.disconnect(previous_callable)
		pressed_connections.erase(button)

	if pressed_callable.is_valid():
		button.pressed.connect(pressed_callable)
		pressed_connections[button] = pressed_callable


## A left-zone button sits centred in a slot of its own (the slot is what the
## row lays out, the button slides in it); the slot widens with a long label
## such as "Csomagvásárlás", so the next button never runs into it.
func _fit_slot_to_button(slot_button: Button) -> void:
	var slot := slot_button.get_parent() as Control
	if slot != null:
		slot.custom_minimum_size.x = slot_button.get_combined_minimum_size().x


func _container_for_mode(mode: String) -> HBoxContainer:
	match mode:
		MAIN_MENU_MODE:
			return main_menu_items
		COLLECTION_MODE:
			return collection_items
	return null


func _build_item_materials() -> void:
	if ResourceLoader.exists(FRONT_NOISE_PATH):
		_dissolve_material = ShaderMaterial.new()
		_dissolve_material.shader = INK_DISSOLVE_SHADER
		_dissolve_material.set_shader_parameter(&"front_noise", load(FRONT_NOISE_PATH))
	if ResourceLoader.exists(LOGO_REVEAL_MASK_PATH):
		_logo_reveal_material = ShaderMaterial.new()
		_logo_reveal_material.shader = LOGO_REVEAL_SHADER
		_logo_reveal_material.set_shader_parameter(&"reveal_mask", load(LOGO_REVEAL_MASK_PATH))
		_logo_reveal_material.set_shader_parameter(&"base_duration", LOGO_STROKE_SECONDS)
		_logo_reveal_material.set_shader_parameter(&"max_delay", LOGO_SPREAD_SECONDS)


## Leaving, a scene's items go the way the hover's ink comes in, turned inside
## out: paper floods in over each from its edges along the same ragged front
## (Shaders/ink_dissolve.gdshader), while it fades.
func _dissolve_items_out(container: HBoxContainer, hide_shell_after: bool) -> void:
	if container == null:
		return
	if scene_items_tween != null and scene_items_tween.is_valid():
		scene_items_tween.kill()

	_set_container_items_interactive(container, false)
	var hover_fill: Node = get_node_or_null("/root/InkHoverFill")
	scene_items_tween = create_tween()
	scene_items_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	scene_items_tween.set_parallel(true)
	var animated_items := _get_animated_items(container)
	for index in range(animated_items.size()):
		var item := animated_items[index]
		var delay: float = index * ITEM_STAGGER_SECONDS
		# A clicked button still holds its hover ink, on a layer of its own.
		if item is Button and hover_fill != null:
			hover_fill.clear(item)
		if _dissolve_material != null:
			item.material = _dissolve_material
			item.set_instance_shader_parameter(&"dissolve_seed", float(item.get_instance_id() % 997))
			item.set_instance_shader_parameter(&"dissolve_size", item.size)
			item.set_instance_shader_parameter(&"dissolve_progress", 0.0)
			scene_items_tween.tween_method(_set_dissolve.bind(item), 0.0, 1.0, DISSOLVE_SECONDS).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		scene_items_tween.tween_property(item, "modulate:a", 0.0, DISSOLVE_SECONDS).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	scene_items_tween.chain().tween_callback(Callable(self, "_finish_items_out").bind(container, hide_shell_after))


func _set_dissolve(progress: float, item: CanvasItem) -> void:
	item.set_instance_shader_parameter(&"dissolve_progress", progress)


func _finish_items_out(container: HBoxContainer, hide_shell_after: bool) -> void:
	if container != null:
		_settle_items(container)
		container.visible = false
	if active_items == container:
		active_items = null
	current_mode = ""

	if hide_shell_after and pending_mode.is_empty():
		root.visible = false


## Arriving, a scene's items are stamped onto the paper: from nothing, a
## third larger and a little turned, each drops onto its place - slowly, then
## all at once - and is fully inked halfway down, so the drop still shows. The
## main menu's logo writes itself instead, letter by letter.
func _stamp_items_in(container: HBoxContainer) -> void:
	if container == null:
		return
	if scene_items_tween != null and scene_items_tween.is_valid():
		scene_items_tween.kill()

	container.visible = true
	_set_container_items_interactive(container, false)
	scene_items_tween = create_tween()
	scene_items_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	scene_items_tween.set_parallel(true)
	var delay: float = 0.0
	for item in _get_animated_items(container):
		_settle_item(item)
		if item == logo and _logo_reveal_material != null:
			_write_logo()
			continue
		item.modulate.a = 0.0
		item.scale = Vector2.ONE * STAMP_START_SCALE
		item.rotation = deg_to_rad(randf_range(STAMP_MIN_TILT, STAMP_MAX_TILT)) * (1.0 if randf() < 0.5 else -1.0)
		# By then the item has been laid out, so its middle is known.
		scene_items_tween.tween_callback(_centre_pivot.bind(item)).set_delay(delay)
		scene_items_tween.tween_property(item, "scale", Vector2.ONE, STAMP_SECONDS).set_delay(delay).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		scene_items_tween.tween_property(item, "rotation", 0.0, STAMP_SECONDS).set_delay(delay).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		scene_items_tween.tween_property(item, "modulate:a", 1.0, STAMP_SECONDS * 0.5).set_delay(delay)
		delay += ITEM_STAGGER_SECONDS
	scene_items_tween.chain().tween_callback(Callable(self, "_finish_items_in").bind(container))


func _centre_pivot(item: Control) -> void:
	item.pivot_offset = item.size * 0.5


## The logo drawn the way the main menu's room draws itself
## (Shaders/art_line_reveal.gdshader), left to right.
func _write_logo() -> void:
	logo.material = _logo_reveal_material
	var duration: float = LOGO_STROKE_SECONDS + LOGO_SPREAD_SECONDS
	_set_logo_time(0.0)
	scene_items_tween.tween_method(_set_logo_time, 0.0, duration, duration)


func _set_logo_time(time: float) -> void:
	_logo_reveal_material.set_shader_parameter(&"time", time)


func _finish_items_in(container: HBoxContainer) -> void:
	_settle_items(container)
	_set_container_items_interactive(container, !scene_transition_active)


## Back to rest, whatever was under way.
func _settle_items(container: HBoxContainer) -> void:
	for item in _get_animated_items(container):
		_settle_item(item)


func _settle_item(item: Control) -> void:
	item.material = null
	item.modulate.a = 1.0
	item.scale = Vector2.ONE
	item.rotation = 0.0


func _get_animated_items(container: HBoxContainer) -> Array[Control]:
	var animated_items: Array[Control] = []
	if container == null:
		return animated_items

	for slot in container.get_children():
		if !(slot is Control):
			continue
		if str(slot.name).to_lower().contains("spacer"):
			continue
		for child in slot.get_children():
			if child is Control:
				animated_items.append(child as Control)
				break
	return animated_items


func _set_container_items_interactive(container: HBoxContainer, interactive: bool) -> void:
	if container == null:
		return
	for item in _get_animated_items(container):
		_set_control_tree_interactive(item, interactive)


func _set_control_tree_interactive(node: Node, interactive: bool) -> void:
	if node is BaseButton:
		var button := node as BaseButton
		button.mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_control_tree_interactive(child, interactive)


func _mode_for_scene_path(scene_path: String) -> String:
	if scene_path == MAIN_MENU_SCENE or scene_path.ends_with("/MainMenu.tscn"):
		return MAIN_MENU_MODE
	if scene_path == COLLECTION_SCENE or scene_path.ends_with("/Collection.tscn"):
		return COLLECTION_MODE
	return ""
