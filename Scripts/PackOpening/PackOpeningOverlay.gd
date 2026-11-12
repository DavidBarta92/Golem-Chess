extends RefCounted
class_name PackOpeningOverlay

## Opening packs, on a CanvasLayer over the whole screen: the packs to choose from,
## the one chosen framed and torn by the player's mouse, and its stamps rising out of
## it onto a PackRewardTable. "Open all" heaps every pack up at once instead. The
## steps are `overlay_state`; Docs/PackOpening/PACK_OPENING.md walks through them.

## The stamps of these packs are the player's from now on: counters and the packs
## left in the room change.
signal packs_claimed
## The overlay has done with these stamps: the room behind it may show them now.
signal rewards_put_away(rewards: Array[StampPrint], has_new_stamps: bool)
signal closed

const BOOSTER_PACK_TEXTURE = preload("res://Assets/booster.png")
const PACK_3D_VIEW = preload("res://Scenes/Pack3DView.tscn")
const MAX_SELECTION_PACK_ICONS: int = 15
## Above the top bar, under the paper texture and so printed on the same paper.
const PACK_OVERLAY_LAYER: int = 1205
const PACK_OVERLAY_DIM: Color = Color(0.0, 0.0, 0.0, 0.9)
const PACK_FLY_IN_SECONDS: float = 0.42
const PACK_FLY_STAGGER_SECONDS: float = 0.055
const PACK_FOCUS_SECONDS: float = 0.42
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
## How much of a stamp is out of the pack at the top of its rise.
const PACK_STAMP_RISE_SHARE: float = 0.62
const PACK_STAMP_RISE_SECONDS: float = 0.34
const PACK_STAMP_RISE_STAGGER: float = 0.09
## They come out as one stack, narrower than the pack: a stamp showing beside the
## pack would look as if it had come from behind it.
const PACK_STAMP_RISE_SPREAD: float = 5.0
const PACK_STAMP_RISE_DEGREES: float = 1.2
const PACK_DROP_WORLD: float = 4.4
const PACK_FALL_SECONDS: float = 0.52
## A click while the opening plays runs what is left at this speed.
const PACK_SKIP_SPEED: float = 3.5
const PACK_BATCH_GATHER_SECONDS: float = 0.26
const OVERLAY_STATE_SELECTION: String = "selection"
const OVERLAY_STATE_FOCUSED: String = "focused"
const OVERLAY_STATE_TEARING: String = "tearing"
const OVERLAY_STATE_OPENING: String = "opening"
const OVERLAY_STATE_REWARDS: String = "rewards"

## The room the overlay opens over: it holds the overlay's layer, and lends it its
## theme and viewport.
var collection: Control
## Where the stamps fly at the end: the album.
var book_node: Control
var reward_table: PackRewardTable
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
var opening_pack_nodes: Array[Control] = []
## The prints that came out of this opening and were not in the collection before.
var reward_new_print_ids: Dictionary = {}
## Claimed stamps the room behind the overlay does not show yet.
var unseen_rewards: Array[StampPrint] = []
## Changes whenever the overlay's content is thrown away, so that work spread
## over frames can tell it has been left behind.
var overlay_build_id: int = 0
var opening_tweens: Array[Tween] = []
var opening_speed: float = 1.0
var focused_pack_node: Control
var overlay_state: String = ""
var overlay_animating: bool = false

func _init(new_collection: Control, new_book_node: Control) -> void:
	collection = new_collection
	book_node = new_book_node
	reward_table = PackRewardTable.new(collection, Callable(self, "_opening_tween"))
	reward_table.all_turned.connect(Callable(self, "_on_rewards_all_turned"))
	reward_table.left.connect(Callable(self, "_finish_leaving_rewards"))

func is_active() -> bool:
	return pack_overlay != null and is_instance_valid(pack_overlay)

func can_open() -> bool:
	return PlayerProgressStore.get_unopened_pack_count() > 0 and !is_active()

func open() -> void:
	if !can_open():
		return
	_show_pack_selection_overlay(true)

func handle_back_pressed() -> bool:
	if !is_active():
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

	packs_claimed.emit()
	unseen_rewards.append_array(rewards)
	return rewards

## Rarest last, so the row builds to its best stamp from left to right.
func _roll_pack_rewards(pack_id: String) -> Array[StampPrint]:
	var pack_definition: PackDefinition = PackDefinitionLibrary.get_pack(pack_id)
	var rewards: Array[StampPrint] = PackDefinitionLibrary.roll_rewards(pack_definition, PackRewardTable.PACK_REWARD_STAMP_COUNT)
	rewards.sort_custom(func(a: StampPrint, b: StampPrint) -> bool: return a.get_rarity() < b.get_rarity())
	return rewards

func _refresh_room_behind_overlay() -> void:
	if unseen_rewards.is_empty():
		return
	rewards_put_away.emit(unseen_rewards, !reward_new_print_ids.is_empty())
	unseen_rewards = []

func _ensure_pack_overlay() -> void:
	if is_active():
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
	reward_table.attach(reward_layer)

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
	pack_overlay.gui_input.connect(Callable(self, "_on_pack_overlay_gui_input"))

	var viewport := collection.get_viewport()
	var on_resized := Callable(self, "_on_pack_overlay_viewport_resized")
	# The viewport outlives the overlay, which is built again for every opening.
	if viewport != null and !viewport.size_changed.is_connected(on_resized):
		viewport.size_changed.connect(on_resized)

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
	if !is_active():
		return

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
	var visible_pack_ids: Array[String] = PlayerProgressStore.get_unopened_pack_queue(MAX_SELECTION_PACK_ICONS)
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
		if build_id != overlay_build_id or !is_active() or overlay_state != OVERLAY_STATE_SELECTION:
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
	if !is_active() or overlay_state != OVERLAY_STATE_FOCUSED:
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
		if build_id != overlay_build_id or !is_active():
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
	reward_table.prepare(PackRewardTable.PACK_REWARD_STAMP_COUNT, [], false, _get_pack_opening_line(pack_view).get_center())

## The moment the mouse takes hold of the pack it is opened: the stamps are in
## the collection and in the pack from here on, whatever the tear does.
func _on_pack_tear_started() -> void:
	overlay_state = OVERLAY_STATE_TEARING
	_set_pack_hint("")
	reward_new_print_ids.clear()
	var pack_ids: Array[String] = [str(focused_pack_node.get_meta("pack_id", ""))]
	var rewards: Array[StampPrint] = _claim_packs(pack_ids)
	reward_table.mark_new_prints(reward_new_print_ids)
	reward_table.assign_prints(rewards)

func _on_pack_torn(_direction: int) -> void:
	pack_tear = null
	overlay_state = OVERLAY_STATE_OPENING
	overlay_animating = true
	opening_speed = 1.0
	if reward_table.stamps.is_empty():
		_show_pack_selection_overlay(true)
		return

	var pack_view := focused_pack_node as Pack3DView
	var rarity: int = reward_table.get_best_rarity()
	var opening_centre: Vector2 = _get_pack_opening_line(pack_view).get_center()
	SFXManager.play("pack_tear_finish")
	pack_view.release_flap()
	PackRevealFx.burst(pack_fx_layer, opening_centre, PackRevealFx.PAPER_FLECK, 34, 300.0)
	_play_pack_kick(pack_view)
	reward_table.add_auras()
	if rarity != StampPrint.Rarity.BASIC:
		_show_pack_light(pack_view, rarity)
	_raise_reward_stamps(float(PACK_BREATH_SECONDS[rarity]))

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
	var stamps: Array[StampVisual] = reward_table.stamps
	var count: int = stamps.size()
	var positions: Array[Vector2] = _get_reward_rise_positions(count)
	for i in range(count):
		var stamp_visual: StampVisual = stamps[i]
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
	var stamp_size: Vector2 = StampVisual.STAMP_SIZE * reward_table.stamps[0].rest_scale
	var centre_y: float = opening.position.y + stamp_size.y * (0.5 - PACK_STAMP_RISE_SHARE)
	for i in range(count):
		var spread: float = (float(i) - float(count - 1) * 0.5) * PACK_STAMP_RISE_SPREAD
		positions.append(PackRewardTable.get_position_for_center(Vector2(opening.get_center().x + spread, centre_y)))
	return positions

## How long after it starts to fall the pack has dropped below the stamps' feet.
func _get_pack_clear_seconds(pack_view: Pack3DView) -> float:
	var stamp_height: float = StampVisual.STAMP_SIZE.y * reward_table.stamps[0].rest_scale.y
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
	reward_table.arrange(true)
	_finish_opening_after(reward_table.get_spread_seconds())

func _finish_opening_after(seconds: float) -> void:
	var finish_tween := _opening_tween()
	finish_tween.tween_interval(seconds)
	finish_tween.tween_callback(Callable(self, "_finish_pack_open_animation"))

## A tween that runs with the opening: a click while it plays speeds them all up.
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

## All the packs on the screen at once: they go together into one heap, and the
## stamps deal out onto the table and turn over by themselves, rarest last.
func _open_all_packs() -> void:
	if overlay_state != OVERLAY_STATE_SELECTION or overlay_animating or opening_pack_nodes.is_empty():
		return
	overlay_state = OVERLAY_STATE_OPENING
	overlay_animating = true
	opening_speed = 1.0
	_set_pack_hint("")
	reward_new_print_ids.clear()

	var pack_ids: Array[String] = []
	for pack_node in opening_pack_nodes:
		pack_ids.append(str(pack_node.get_meta("pack_id", "")))
	var rewards: Array[StampPrint] = _claim_packs(pack_ids)
	reward_table.mark_new_prints(reward_new_print_ids)
	var heap: Vector2 = _get_viewport_size() * 0.5
	for pack_node in opening_pack_nodes:
		_stop_pack_ambient_motion(pack_node, false)
		pack_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tween := _opening_tween()
		tween.tween_property(pack_node, "position", heap - pack_node.size * 0.5, PACK_BATCH_GATHER_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(pack_node, "scale", Vector2.ONE * 0.5, PACK_BATCH_GATHER_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	rewards.sort_custom(func(a: StampPrint, b: StampPrint) -> bool: return a.get_rarity() < b.get_rarity())

	var started_msec: int = Time.get_ticks_msec()
	await reward_table.prepare(rewards.size(), rewards, true)
	if !is_active() or overlay_state != OVERLAY_STATE_OPENING:
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
	reward_table.add_auras()
	reward_table.arrange(true)
	_finish_opening_after(reward_table.get_spread_seconds())

func _on_pack_overlay_gui_input(event: InputEvent) -> void:
	if !(event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or !mouse_event.pressed:
		return
	pack_overlay.accept_event()
	if reward_table.advance_full_art_stage():
		return
	match overlay_state:
		OVERLAY_STATE_FOCUSED, OVERLAY_STATE_TEARING, OVERLAY_STATE_OPENING:
			if overlay_state != OVERLAY_STATE_FOCUSED or !overlay_animating:
				handle_back_pressed()
		OVERLAY_STATE_REWARDS:
			# A click on the table turns the next stamp, and once all are turned it moves on.
			if reward_table.click_table():
				handle_back_pressed()

func _on_rewards_all_turned() -> void:
	_set_pack_hint(tr("Click to continue"))

## The stamps go off into the album, and the room is back.
func _leave_rewards() -> void:
	overlay_animating = true
	_set_pack_hint("")
	reward_table.leave(_get_book_centre())

func _finish_leaving_rewards() -> void:
	if !is_active():
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
	if !is_active() or overlay_state != OVERLAY_STATE_OPENING:
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
	reward_table.start_turning()
	if !reward_table.batch:
		_set_pack_hint(tr("Click the stamps to turn them over"))

func _finish_pack_selection_fly_in() -> void:
	if !is_active() or overlay_state != OVERLAY_STATE_SELECTION:
		return
	overlay_animating = false
	_set_pack_hint(tr("Choose a pack to open"))
	_start_selection_pack_ambient_motion()

func _on_pack_overlay_viewport_resized() -> void:
	if !is_active():
		return
	_sync_pack_overlay_rect()
	if overlay_state == OVERLAY_STATE_SELECTION:
		_layout_selection_packs(false)
	elif overlay_state == OVERLAY_STATE_FOCUSED:
		# The pack and its tear line are laid out for the old size: choosing again is simplest.
		_show_pack_selection_overlay(false)
	elif overlay_state == OVERLAY_STATE_REWARDS:
		reward_table.arrange(false)

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
	reward_table.reset()
	opening_tweens.clear()
	opening_speed = 1.0
	pack_tear = null
	pack_light = null
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

func _close_pack_overlay(animated: bool) -> void:
	if !is_active():
		return

	var overlay_to_close := pack_overlay
	var layer_to_close := pack_overlay_layer
	overlay_build_id += 1
	reward_table.forget()
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
	opening_tweens.clear()
	opening_speed = 1.0
	opening_pack_nodes.clear()
	focused_pack_node = null
	overlay_state = ""
	overlay_animating = false

	if animated and is_instance_valid(overlay_to_close):
		overlay_to_close.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tween := overlay_to_close.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(overlay_to_close, "modulate:a", 0.0, 0.16)
		tween.tween_callback(Callable(layer_to_close, "queue_free"))
	elif is_instance_valid(layer_to_close):
		layer_to_close.queue_free()
	closed.emit()
