extends CanvasLayer

const MAIN_MENU_MODE: String = "main_menu"
const COLLECTION_MODE: String = "collection"
## Just the coin counter, for screens that pay coins out (reward scenes).
const POINTS_ONLY_MODE: String = "points_only"
const MAIN_MENU_SCENE: String = "res://Scenes/MainMenu.tscn"
const COLLECTION_SCENE: String = "res://Scenes/Collection.tscn"
const SLIDE_DISTANCE: float = 64.0
const SLIDE_OUT_SECONDS: float = 0.16
const SLIDE_IN_SECONDS: float = 0.18
const ITEM_STAGGER_SECONDS: float = 0.045
const TOP_BAR_BACKGROUND_COLOR: Color = Color(0.9366637, 0.9330646, 0.89437205, 1.0)
const TOP_BAR_TEXT_COLOR: Color = Color(0.06666667, 0.05490196, 0.09411765, 1.0)
const VERSION_TEXT_COLOR: Color = Color(0.61960787, 0.6039216, 0.6862745, 1.0)
const SINGLEPLAYER_UNLOCK_KEY: Key = KEY_A
const SINGLEPLAYER_UNLOCK_PRESS_COUNT: int = 3

@onready var root: Control = $Root
@onready var top_background: ColorRect = $Root/TopBackground
@onready var scene_items_clip: Control = $Root/SceneItemsClip
@onready var main_menu_items: HBoxContainer = $Root/SceneItemsClip/MainMenuItems
@onready var collection_items: HBoxContainer = $Root/SceneItemsClip/CollectionItems
@onready var singleplayer_slot: Control = $Root/SceneItemsClip/MainMenuItems/SingleplayerSlot
@onready var singleplayer_button: Button = $Root/SceneItemsClip/MainMenuItems/SingleplayerSlot/SingleplayerButton
@onready var multiplayer_button: Button = $Root/SceneItemsClip/MainMenuItems/MultiplayerSlot/MultiplayerButton
@onready var settings_button: Button = $Root/SceneItemsClip/MainMenuItems/SettingsSlot/SettingsButton
@onready var exit_button: Button = $Root/SceneItemsClip/MainMenuItems/ExitSlot/ExitButton
@onready var back_button: Button = $Root/SceneItemsClip/CollectionItems/BackSlot/BackButton
@onready var buy_packs_button: Button = $Root/SceneItemsClip/CollectionItems/BuyPacksSlot/BuyPacksButton
@onready var version_label: Label = $Root/SceneItemsClip/MainMenuItems/VersionSlot/VersionLabel
@onready var points_hud: Control = $Root/PointsHud
@onready var point_icon: TextureRect = $Root/PointsHud/Coin
@onready var points_label: Label = $Root/PointsHud/PointsLabel

var current_mode: String = ""
var pending_mode: String = ""
var active_items: HBoxContainer
var scene_items_tween: Tween
var button_by_id: Dictionary = {}
var pressed_connections: Dictionary = {}
var rest_positions: Dictionary = {}
var scene_transition_active: bool = false
var singleplayer_unlock_presses: int = 0


func _ready() -> void:
	layer = 1200
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_background.color = TOP_BAR_BACKGROUND_COLOR
	top_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_items_clip.clip_contents = true
	scene_items_clip.mouse_filter = Control.MOUSE_FILTER_PASS
	points_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	point_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	points_label.add_theme_color_override("font_color", TOP_BAR_TEXT_COLOR)
	version_label.text = "v%s alpha" % str(ProjectSettings.get_setting("application/config/version", "0.0.8"))
	version_label.add_theme_color_override("font_color", VERSION_TEXT_COLOR)
	button_by_id = {
		"settings": settings_button,
		"exit": exit_button,
		"back": back_button,
		"buy_packs": buy_packs_button,
		"singleplayer": singleplayer_button,
		"multiplayer": multiplayer_button,
	}
	_reset_container_items(main_menu_items)
	_reset_container_items(collection_items)
	collection_items.visible = false
	refresh_points()


func _input(event: InputEvent) -> void:
	if current_mode != MAIN_MENU_MODE or singleplayer_slot.visible:
		return
	if get_viewport().gui_get_focus_owner() is LineEdit:
		return

	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or !key_event.pressed or key_event.echo:
		return

	if key_event.keycode == SINGLEPLAYER_UNLOCK_KEY:
		singleplayer_unlock_presses += 1
		if singleplayer_unlock_presses >= SINGLEPLAYER_UNLOCK_PRESS_COUNT:
			_reveal_singleplayer_button()
	else:
		singleplayer_unlock_presses = 0


func _reveal_singleplayer_button() -> void:
	singleplayer_unlock_presses = 0
	if singleplayer_slot.visible:
		return
	singleplayer_slot.visible = true
	await get_tree().process_frame
	rest_positions.erase(singleplayer_button)
	_reset_container_items(main_menu_items)


func show_main_menu(settings_pressed: Callable, exit_pressed: Callable, singleplayer_pressed: Callable = Callable(), multiplayer_pressed: Callable = Callable()) -> void:
	_replace_button_connection(settings_button, settings_pressed)
	_replace_button_connection(exit_button, exit_pressed)
	_replace_button_connection(singleplayer_button, singleplayer_pressed)
	_replace_button_connection(multiplayer_button, multiplayer_pressed)
	_show_mode(MAIN_MENU_MODE)


func show_collection(back_pressed: Callable, buy_packs_pressed: Callable = Callable()) -> void:
	_replace_button_connection(back_button, back_pressed)
	_replace_button_connection(buy_packs_button, buy_packs_pressed)
	_show_mode(COLLECTION_MODE)


## Shows only the bar and its coin counter - no menu items - so a reward scene
## has a real counter for its coins to fly into. Leaving the scene hides it
## again through prepare_for_scene_change like any other mode.
func show_points_only() -> void:
	if scene_items_tween != null and scene_items_tween.is_valid():
		scene_items_tween.kill()
	main_menu_items.visible = false
	collection_items.visible = false
	root.visible = true
	top_background.visible = true
	points_hud.visible = true
	current_mode = POINTS_ONLY_MODE
	pending_mode = ""
	active_items = null
	refresh_points()

## Centre of the coin icon in screen space - the target for flying coins.
func get_coin_global_center() -> Vector2:
	if point_icon == null:
		return Vector2.ZERO
	return point_icon.global_position + point_icon.size * 0.5

## Writes a number into the counter without touching the store, for count-up
## animations. refresh_points() puts the real value back.
func set_displayed_points(value: int) -> void:
	if points_label != null:
		points_label.text = str(maxi(0, value))

## A quick grow-and-settle on the counter, for when a coin lands in it.
func pulse_points_hud() -> void:
	if points_hud == null:
		return
	points_hud.pivot_offset = points_hud.size * 0.5
	var tween := points_hud.create_tween()
	tween.tween_property(points_hud, "scale", Vector2.ONE * 1.18, 0.07).set_ease(Tween.EASE_OUT)
	tween.tween_property(points_hud, "scale", Vector2.ONE, 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func prepare_for_scene_change(target_scene_path: String) -> void:
	var target_mode: String = _mode_for_scene_path(target_scene_path)
	if target_mode == current_mode:
		return

	pending_mode = target_mode
	if current_mode.is_empty() or active_items == null:
		if target_mode.is_empty():
			root.visible = false
		return

	_animate_items_out(active_items, target_mode.is_empty())


func set_scene_transition_active(active: bool) -> void:
	scene_transition_active = active
	_set_container_items_interactive(active_items, !scene_transition_active and root.visible)


func refresh_points() -> void:
	if points_label == null:
		return
	if Engine.is_editor_hint():
		points_label.text = "0"
		return
	PlayerProgressStore.ensure_loaded()
	points_label.text = str(PlayerProgressStore.get_points())


func get_button(button_id: String) -> Button:
	return button_by_id.get(button_id, null) as Button


func _show_mode(mode: String) -> void:
	var target_items := _container_for_mode(mode)
	if target_items == null:
		return

	root.visible = true
	top_background.visible = true
	points_hud.visible = true
	refresh_points()

	if current_mode == mode and active_items == target_items:
		target_items.visible = true
		_reset_container_items(target_items)
		_set_container_items_interactive(target_items, !scene_transition_active)
		return

	if active_items != null and active_items != target_items:
		active_items.visible = false

	current_mode = mode
	pending_mode = ""
	active_items = target_items
	_animate_items_in(target_items)


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


func _container_for_mode(mode: String) -> HBoxContainer:
	match mode:
		MAIN_MENU_MODE:
			return main_menu_items
		COLLECTION_MODE:
			return collection_items
	return null


func _animate_items_out(container: HBoxContainer, hide_shell_after: bool) -> void:
	if container == null:
		return
	if scene_items_tween != null and scene_items_tween.is_valid():
		scene_items_tween.kill()

	_set_container_items_interactive(container, false)
	var animated_items := _get_animated_items(container)
	_remember_rest_positions(animated_items)

	scene_items_tween = create_tween()
	scene_items_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	scene_items_tween.set_parallel(true)
	scene_items_tween.set_trans(Tween.TRANS_SINE)
	scene_items_tween.set_ease(Tween.EASE_IN)
	for index in range(animated_items.size()):
		var item := animated_items[index]
		var rest_position: Vector2 = rest_positions.get(item, item.position)
		scene_items_tween.tween_property(item, "position:y", rest_position.y - SLIDE_DISTANCE, SLIDE_OUT_SECONDS).set_delay(index * ITEM_STAGGER_SECONDS)
	scene_items_tween.chain().tween_callback(Callable(self, "_finish_items_out").bind(container, hide_shell_after))


func _finish_items_out(container: HBoxContainer, hide_shell_after: bool) -> void:
	if container != null:
		_reset_container_items(container)
		container.visible = false
	if active_items == container:
		active_items = null
	current_mode = ""

	if hide_shell_after and pending_mode.is_empty():
		root.visible = false


func _animate_items_in(container: HBoxContainer) -> void:
	if container == null:
		return
	if scene_items_tween != null and scene_items_tween.is_valid():
		scene_items_tween.kill()

	var animated_items := _get_animated_items(container)
	_remember_rest_positions(animated_items)
	for item in animated_items:
		var rest_position: Vector2 = rest_positions.get(item, item.position)
		item.position.y = rest_position.y - SLIDE_DISTANCE

	container.visible = true
	_set_container_items_interactive(container, false)

	scene_items_tween = create_tween()
	scene_items_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	scene_items_tween.set_parallel(true)
	scene_items_tween.set_trans(Tween.TRANS_SINE)
	scene_items_tween.set_ease(Tween.EASE_OUT)
	for index in range(animated_items.size()):
		var item := animated_items[index]
		var rest_position: Vector2 = rest_positions.get(item, item.position)
		scene_items_tween.tween_property(item, "position:y", rest_position.y, SLIDE_IN_SECONDS).set_delay(index * ITEM_STAGGER_SECONDS)
	scene_items_tween.chain().tween_callback(Callable(self, "_finish_items_in").bind(container))


func _finish_items_in(container: HBoxContainer) -> void:
	_reset_container_items(container)
	_set_container_items_interactive(container, !scene_transition_active)


func _reset_container_items(container: HBoxContainer) -> void:
	if container == null:
		return
	var animated_items := _get_animated_items(container)
	_remember_rest_positions(animated_items)
	for item in animated_items:
		var rest_position: Vector2 = rest_positions.get(item, item.position)
		# Only y is animated; x follows the item's anchors, which move it when
		# its translated text makes it wider than when the rest was recorded.
		item.position.y = rest_position.y


func _remember_rest_positions(animated_items: Array[Control]) -> void:
	for item in animated_items:
		if !rest_positions.has(item):
			rest_positions[item] = item.position


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
