extends RefCounted
class_name PackRewardTable

## The stamps out of opened packs, on the overlay's reward layer: built face down
## ahead of time, dealt onto the table, turned by the player (or by themselves for
## a whole heap of packs), and sent into the album at the end. PackOpeningOverlay
## runs the steps around it; Docs/PackOpening/PACK_OPENING.md walks through them.

## Every stamp turned and none still turning: the table waits for a click.
signal all_turned
## The stamps have gone into the album.
signal left

const STAMP_VISUAL = preload("res://Scenes/StampVisual.tscn")
const PACK_REWARD_STAMP_COUNT: int = 4
## The stamps peek this far over the torn edge before they come out.
const PACK_STAMP_PEEK: float = 9.0
## Stamps are built over several frames, this many a frame: one takes a few
## milliseconds, and a whole heap of them at once would stop the game.
const PACK_STAMPS_BUILT_PER_FRAME: int = 2
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
const PACK_LEAVE_SECONDS: float = 0.42
const PACK_LEAVE_STAGGER: float = 0.06
const PACK_LEAVE_SCALE: float = 0.14
const PACK_BATCH_FLIP_STAGGER: float = 0.06
const PACK_BATCH_FLIP_SHARE: float = 0.5
const PACK_REWARD_MAX_SCALE: float = 1.1
const PACK_REWARD_MIN_SCALE: float = 0.3
const PACK_REWARD_ROW_GAP: float = 12.0
const PACK_REWARD_SIDE_MARGIN: float = 36.0

## The overlay's reward layer: everything the table shows is built in it.
var layer: Control
## Its viewport size and scene tree are asked of this one.
var viewport_item: CanvasItem
## Gives a tween that runs with the opening, at its speed (PackOpeningOverlay._opening_tween).
var opening_tween: Callable
var stamps: Array[StampVisual] = []
var flipped: Array[bool] = []
var hitboxes: Array[Control] = []
var captions: Array[Control] = []
## The prints that came out of this opening and were not in the collection before.
var new_print_ids: Dictionary = {}
var flips_running: int = 0
var full_art_stage: PackFullArtStage
## A full art stamp is being shown: it holds up the rest of the table.
var full_art_showing: bool = false
var description_panel: PanelContainer
var description_label: RichTextLabel
## The stamp under the mouse, -1 for none.
var hovered_stamp: int = -1
## A whole heap of packs at once: no captions, and the stamps turn by themselves.
var batch: bool = false
## A batch turns its stamps one at a time: this is the pause between two.
var batch_flip_waiting: bool = false
## The stamps are dealt and can be turned.
var turning: bool = false
## They are on their way into the album.
var leaving: bool = false
## Changes whenever the table is thrown away, so that work spread over frames can
## tell it has been left behind.
var build_id: int = 0
var stack_from_pack: bool = false
var stack_opening_centre: Vector2 = Vector2.ZERO

func _init(new_viewport_item: CanvasItem, new_opening_tween: Callable) -> void:
	viewport_item = new_viewport_item
	opening_tween = new_opening_tween

func attach(new_layer: Control) -> void:
	layer = new_layer

static func get_rarity(stamp_visual: StampVisual) -> int:
	return stamp_visual.stamp_print.get_rarity() if stamp_visual.stamp_print != null else StampPrint.Rarity.BASIC

static func get_position_for_center(center: Vector2) -> Vector2:
	return center - StampVisual.STAMP_SIZE * 0.5

func get_best_rarity() -> int:
	var best: int = StampPrint.Rarity.BASIC
	for stamp_visual in stamps:
		best = maxi(best, get_rarity(stamp_visual))
	return best

func mark_new_prints(print_ids: Dictionary) -> void:
	new_print_ids = print_ids.duplicate()

## Builds a face-down stack of this many stamps, a few each frame. The prints may
## come later, through assign_prints: a stamp's back shows nothing of them. With an
## `opening_centre` the stack stands in a torn pack's top, without one in the middle
## of the screen.
func prepare(count: int, stamp_prints: Array[StampPrint] = [], new_batch: bool = false, opening_centre = null) -> void:
	if layer == null or !is_instance_valid(layer):
		return

	_free_stamps()
	batch = new_batch
	stack_from_pack = opening_centre is Vector2
	stack_opening_centre = opening_centre if opening_centre is Vector2 else Vector2.ZERO
	layer.visible = true
	layer.mouse_filter = Control.MOUSE_FILTER_PASS
	var prepare_build_id: int = build_id
	while stamps.size() < count:
		var index: int = stamps.size()
		_add_stamp(count, stamp_prints[index] if index < stamp_prints.size() else null)
		if (index + 1) % PACK_STAMPS_BUILT_PER_FRAME == 0:
			await viewport_item.get_tree().process_frame
			if prepare_build_id != build_id or layer == null or !is_instance_valid(layer):
				return

func _add_stamp(stack_size: int, stamp_print: StampPrint) -> void:
	var viewport_size: Vector2 = _get_viewport_size()
	var scale_factor: float = _get_stamp_scale(viewport_size, stack_size)
	var stack_center: Vector2 = viewport_size * 0.5
	if !batch and stack_from_pack:
		stack_center = stack_opening_centre + Vector2(0.0, StampVisual.STAMP_SIZE.y * scale_factor * 0.5 - PACK_STAMP_PEEK)

	var stamp_visual := STAMP_VISUAL.instantiate() as StampVisual
	layer.add_child(stamp_visual)
	stamp_visual.size = StampVisual.STAMP_SIZE
	stamp_visual.custom_minimum_size = StampVisual.STAMP_SIZE
	stamp_visual.pivot_offset = StampVisual.STAMP_SIZE * 0.5
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
	stamp_visual.position = get_position_for_center(stack_center) + Vector2(randf_range(-3.0, 3.0), randf_range(-1.5, 1.5))
	stamp_visual.rotation = deg_to_rad(randf_range(-1.6, 1.6))
	stamp_visual.home_position = stamp_visual.position
	stamp_visual.z_index = stamps.size()
	PackRevealFx.add_shadow(stamp_visual)
	stamps.append(stamp_visual)
	flipped.append(false)

## The prints for a stack prepared without them. The mouse may come down before the
## stack is finished, and a pack short of stamps gives fewer than the stack holds.
func assign_prints(rewards: Array[StampPrint]) -> void:
	while stamps.size() < rewards.size():
		_add_stamp(rewards.size(), null)
	while stamps.size() > rewards.size():
		stamps.pop_back().queue_free()
		flipped.pop_back()
	for i in range(rewards.size()):
		stamps[i].set_stamp_print(rewards[i])

func add_auras() -> void:
	for stamp_visual in stamps:
		var rarity: int = get_rarity(stamp_visual)
		if rarity == StampPrint.Rarity.BASIC:
			continue
		var aura: ColorRect = PackRevealFx.add_aura(stamp_visual, rarity)
		aura.modulate.a = 0.0
		(opening_tween.call() as Tween).tween_property(aura, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func arrange(animated: bool) -> void:
	if stamps.is_empty():
		return

	var viewport_size: Vector2 = _get_viewport_size()
	var scale_factor: float = _get_stamp_scale(viewport_size, stamps.size())
	var target_scale := Vector2.ONE * scale_factor
	var positions: Array[Vector2] = _get_stamp_positions(stamps.size(), scale_factor)
	for i in range(stamps.size()):
		var stamp_visual: StampVisual = stamps[i]
		if stamp_visual == null or !is_instance_valid(stamp_visual):
			continue
		stamp_visual.set_ambient_motion_enabled(false)
		stamp_visual.home_position = positions[i]
		stamp_visual.rest_scale = target_scale
		stamp_visual.z_index = i
		if animated:
			var tween: Tween = opening_tween.call()
			tween.tween_interval(float(i) * _get_spread_stagger())
			if !batch:
				tween.tween_callback(func() -> void: SFXManager.play_pitched("field_slips", randf_range(0.92, 1.08), 0.0))
			tween.tween_property(stamp_visual, "position", positions[i], PACK_REWARD_SPREAD_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tween.parallel().tween_property(stamp_visual, "scale", target_scale, PACK_REWARD_SPREAD_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween.parallel().tween_property(stamp_visual, "rotation", deg_to_rad(randf_range(-2.0, 2.0)), PACK_REWARD_SPREAD_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		else:
			stamp_visual.position = positions[i]
			stamp_visual.scale = target_scale
			stamp_visual.rotation = 0.0

	_sync_hitboxes()
	_layout_captions()
	if animated:
		var float_tween: Tween = opening_tween.call()
		float_tween.tween_interval(get_spread_seconds())
		float_tween.tween_callback(Callable(self, "_enable_stamp_float"))
	else:
		_enable_stamp_float()

func _get_spread_stagger() -> float:
	# A big deal has to stay short as a whole.
	return PACK_REWARD_SPREAD_STAGGER if stamps.size() <= PACK_REWARD_STAMP_COUNT else 0.012

func get_spread_seconds() -> float:
	return PACK_REWARD_SPREAD_SECONDS + float(stamps.size() - 1) * _get_spread_stagger()

func _enable_stamp_float() -> void:
	for stamp_visual in stamps:
		if stamp_visual == null or !is_instance_valid(stamp_visual):
			continue
		stamp_visual.home_position = stamp_visual.position
		stamp_visual.set_ambient_motion_enabled(true)
	_sync_hitboxes()

## The stamps are dealt: from here on they can be turned. A batch starts turning
## them by itself.
func start_turning() -> void:
	turning = true
	leaving = false
	_sync_hitboxes()
	if batch:
		_flip_next_batch_stamp()

func _sync_hitboxes() -> void:
	if layer == null or !is_instance_valid(layer):
		return

	while hitboxes.size() < stamps.size():
		var hitbox := Control.new()
		hitbox.name = "RewardStampHitbox%d" % (hitboxes.size() + 1)
		hitbox.z_index = 500 + hitboxes.size()
		hitbox.mouse_filter = Control.MOUSE_FILTER_STOP
		hitbox.mouse_default_cursor_shape = Control.CURSOR_ARROW
		hitbox.clip_contents = false
		layer.add_child(hitbox)
		hitbox.gui_input.connect(Callable(self, "_on_hitbox_gui_input").bind(hitboxes.size()))
		hitbox.mouse_entered.connect(Callable(self, "_on_stamp_mouse_entered").bind(hitboxes.size()))
		hitbox.mouse_exited.connect(Callable(self, "_on_stamp_mouse_exited").bind(hitboxes.size()))
		hitboxes.append(hitbox)

	for i in range(hitboxes.size()):
		var hitbox: Control = hitboxes[i]
		if hitbox == null or !is_instance_valid(hitbox):
			continue
		var stamp_visual: StampVisual = stamps[i] if i < stamps.size() else null
		if stamp_visual == null or !is_instance_valid(stamp_visual):
			hitbox.visible = false
			hitbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			continue
		var hitbox_rect: Rect2 = _get_hitbox_rect(stamp_visual)
		hitbox.position = hitbox_rect.position
		hitbox.size = hitbox_rect.size
		hitbox.visible = turning
		# A turned stamp still knows the mouse is on it, but leaves its clicks to
		# the overlay, like the rest of the table.
		hitbox.mouse_filter = Control.MOUSE_FILTER_PASS if flipped[i] else Control.MOUSE_FILTER_STOP

func _on_hitbox_gui_input(event: InputEvent, stamp_index: int) -> void:
	if !(event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or !mouse_event.pressed:
		return
	if stamp_index < 0 or stamp_index >= stamps.size() or flipped[stamp_index]:
		return
	var hitbox: Control = hitboxes[stamp_index] if stamp_index < hitboxes.size() else null
	if hitbox != null and is_instance_valid(hitbox):
		hitbox.accept_event()
	if leaving or full_art_showing:
		advance_full_art_stage()
		return
	_flip_stamp(stamp_index)

func _on_stamp_mouse_entered(stamp_index: int) -> void:
	hovered_stamp = stamp_index
	_show_description()

func _on_stamp_mouse_exited(stamp_index: int) -> void:
	if hovered_stamp == stamp_index:
		hovered_stamp = -1
		_hide_description()

## What the stamp under the mouse does. A stamp still lying face down keeps its secret.
func _show_description() -> void:
	if hovered_stamp < 0 or hovered_stamp >= stamps.size():
		return
	if full_art_showing or !turning or leaving:
		return
	var stamp_visual: StampVisual = stamps[hovered_stamp]
	if !flipped[hovered_stamp] or stamp_visual.face_down:
		return
	var stamp: Stamp = StampPrintLibrary.get_stamp_for_print(stamp_visual.stamp_print)
	var description: String = stamp.get_display_description().strip_edges() if stamp != null else ""
	if description.is_empty():
		return

	_ensure_description()
	var font_size: int = description_label.get_theme_font_size("normal_font_size")
	var text: String = DescriptionMarkup.to_bbcode(description, font_size)
	# On a big table the stamps have no captions, and are too small to read.
	description_label.text = "[b]%s[/b]\n%s" % [stamp.stamp_name, text] if batch else text
	description_panel.visible = true
	_layout_description()

func _hide_description() -> void:
	if description_panel != null and is_instance_valid(description_panel):
		description_panel.visible = false

func _ensure_description() -> void:
	if description_panel != null and is_instance_valid(description_panel):
		return
	description_panel = PanelContainer.new()
	description_panel.name = "RewardDescription"
	description_panel.theme_type_variation = &"ShopWindowPanel"
	description_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description_panel.custom_minimum_size = Vector2(PACK_REWARD_DESCRIPTION_WIDTH, 0.0)
	description_panel.z_index = 700
	layer.add_child(description_panel)
	description_panel.minimum_size_changed.connect(Callable(self, "_layout_description"))

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description_panel.add_child(margin)
	for side in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(side, 14)
	for side in ["margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 10)

	description_label = RichTextLabel.new()
	description_label.bbcode_enabled = true
	description_label.fit_content = true
	description_label.scroll_active = false
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.custom_minimum_size = Vector2(PACK_REWARD_DESCRIPTION_WIDTH - 28.0, 0.0)
	description_label.theme_type_variation = &"StampDescriptionText"
	margin.add_child(description_label)

## Under the stamp and its caption, or over the stamp when there is no room left
## below it, as on the bottom rows of a big table.
func _layout_description() -> void:
	if description_panel == null or !is_instance_valid(description_panel) or !description_panel.visible:
		return
	if hovered_stamp < 0 or hovered_stamp >= stamps.size():
		return
	var stamp_visual: StampVisual = stamps[hovered_stamp]
	var viewport_size: Vector2 = _get_viewport_size()
	var panel_size: Vector2 = description_panel.get_combined_minimum_size()
	description_panel.size = panel_size
	var centre: Vector2 = stamp_visual.home_position + StampVisual.STAMP_SIZE * 0.5
	var half_height: float = StampVisual.STAMP_SIZE.y * stamp_visual.rest_scale.y * 0.5
	var caption_height: float = 0.0 if batch else PACK_REWARD_CAPTION_SIZE.y + PACK_REWARD_CAPTION_GAP
	var top: float = centre.y + half_height + caption_height + PACK_REWARD_CAPTION_GAP
	if top + panel_size.y > viewport_size.y - PACK_REWARD_DESCRIPTION_FOOTER:
		top = centre.y - half_height - PACK_REWARD_CAPTION_GAP - panel_size.y
	var margin: float = PACK_REWARD_DESCRIPTION_MARGIN
	description_panel.position = Vector2(
		clampf(centre.x - panel_size.x * 0.5, margin, viewport_size.x - panel_size.x - margin),
		clampf(top, margin, viewport_size.y - panel_size.y - margin)
	)

## Turns a stamp by its rarity. Stamps can turn side by side, however fast the
## clicks come; only a full art stamp holds up the rest while it is shown.
func _flip_stamp(stamp_index: int) -> void:
	if stamp_index < 0 or stamp_index >= stamps.size():
		return
	var stamp_visual: StampVisual = stamps[stamp_index]
	if stamp_visual == null or !is_instance_valid(stamp_visual) or flipped[stamp_index]:
		return

	flipped[stamp_index] = true
	flips_running += 1
	_sync_hitboxes()
	stamp_visual.set_ambient_motion_enabled(false)
	stamp_visual.set_hover_raise_enabled(false)
	stamp_visual.draggable = false
	stamp_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp_visual.disabled = true
	stamp_visual.z_index = 120 + stamp_index
	match get_rarity(stamp_visual):
		StampPrint.Rarity.FULL_ART:
			_show_full_art_stamp(stamp_index)
		StampPrint.Rarity.FOIL:
			_lift_foil_stamp(stamp_index)
		_:
			_play_flip_sound()
			_turn_stamp(stamp_index, Callable())

func _play_flip_sound() -> void:
	# A wave of stamps turning is one sound, not sixty.
	if !batch:
		SFXManager.play("codex_fold")
	elif flips_running <= 2:
		SFXManager.play_pitched("stamp_up", randf_range(0.9, 1.15), 0.0)

## A foil stamp rises off the table with a shimmer before it turns.
func _lift_foil_stamp(stamp_index: int) -> void:
	var stamp_visual: StampVisual = stamps[stamp_index]
	SFXManager.play("pack_foil_tease")
	var on_face_up := Callable(self, "_reveal_foil_stamp").bind(stamp_visual)
	if batch:
		_turn_stamp(stamp_index, on_face_up)
		return
	var tween := stamp_visual.create_tween()
	tween.tween_property(stamp_visual, "position:y", stamp_visual.home_position.y - PACK_REWARD_FOIL_LIFT, PACK_REWARD_FOIL_LIFT_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(Callable(self, "_turn_stamp").bind(stamp_index, on_face_up))

func _reveal_foil_stamp(stamp_visual: StampVisual) -> void:
	SFXManager.play("pack_foil_reveal")
	PackRevealFx.sweep(stamp_visual, PackRevealFx.FOIL_LIGHT)
	PackRevealFx.burst(layer, stamp_visual.position + StampVisual.STAMP_SIZE * 0.5, PackRevealFx.FOIL_LIGHT, 26, 260.0)
	_quiet_aura(stamp_visual)

## Once it is face up a stamp needs its glow no more: it has its foil.
func _quiet_aura(stamp_visual: StampVisual) -> void:
	var aura := stamp_visual.get_node_or_null("RarityAura") as CanvasItem
	if aura != null:
		stamp_visual.create_tween().tween_property(aura, "modulate:a", 0.32, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func _turn_stamp(stamp_index: int, on_face_up: Callable) -> void:
	var stamp_visual: StampVisual = stamps[stamp_index]
	var seconds: float = PACK_REWARD_FLIP_SECONDS * (PACK_BATCH_FLIP_SHARE if batch else 1.0)
	var target_scale: Vector2 = stamp_visual.rest_scale
	var squash_scale := Vector2(0.0, target_scale.y * 1.02)
	var tween := stamp_visual.create_tween()
	tween.tween_property(stamp_visual, "scale", squash_scale, seconds).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(Callable(self, "_turn_stamp_face_up").bind(stamp_visual))
	if on_face_up.is_valid():
		tween.tween_callback(on_face_up)
	tween.tween_property(stamp_visual, "scale", target_scale, seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(stamp_visual, "position", stamp_visual.home_position, seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(stamp_visual, "rotation", deg_to_rad(randf_range(-1.6, 1.6)), seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	if !batch:
		var height: float = StampVisual.STAMP_SIZE.y * target_scale.y * PACK_REWARD_HOP_HEIGHT
		tween.tween_property(stamp_visual, "position:y", stamp_visual.home_position.y - height, 0.09).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.parallel().tween_property(stamp_visual, "scale", target_scale * (1.0 + PACK_REWARD_HOP_GROW), 0.09).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(stamp_visual, "position:y", stamp_visual.home_position.y, 0.24).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(stamp_visual, "scale", target_scale, 0.24).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(Callable(self, "_finish_stamp_flip").bind(stamp_index))

func _show_full_art_stamp(stamp_index: int) -> void:
	var stamp_visual: StampVisual = stamps[stamp_index]
	full_art_showing = true
	_hide_description()
	stamp_visual.z_index = 300
	full_art_stage = PackFullArtStage.new()
	full_art_stage.name = "FullArtStage"
	full_art_stage.z_index = 250
	layer.add_child(full_art_stage)
	full_art_stage.finished.connect(Callable(self, "_finish_full_art_stamp").bind(stamp_index))
	var turn_up := Callable(self, "_turn_stamp_face_up").bind(stamp_visual)
	full_art_stage.play(stamp_visual, StampVisual.STAMP_SIZE, _get_stamp_name(stamp_visual), tr("Full Art"), turn_up)

func _finish_full_art_stamp(stamp_index: int) -> void:
	full_art_stage = null
	full_art_showing = false
	stamps[stamp_index].z_index = 120 + stamp_index
	_quiet_aura(stamps[stamp_index])
	_finish_stamp_flip(stamp_index)

## Moves a full art stamp's showing on, if one is being shown.
func advance_full_art_stage() -> bool:
	if full_art_stage != null and is_instance_valid(full_art_stage):
		full_art_stage.advance()
		return true
	return false

func _turn_stamp_face_up(stamp_visual: StampVisual) -> void:
	if stamp_visual == null or !is_instance_valid(stamp_visual):
		return
	stamp_visual.set_face_down(false)
	stamp_visual.disabled = true
	stamp_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp_visual.scale = Vector2(0.0, stamp_visual.scale.y)

func _finish_stamp_flip(stamp_index: int) -> void:
	flips_running -= 1
	var stamp_visual: StampVisual = stamps[stamp_index] if stamp_index >= 0 and stamp_index < stamps.size() else null
	if stamp_visual != null and is_instance_valid(stamp_visual):
		stamp_visual.disabled = true
		stamp_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stamp_visual.position = stamp_visual.home_position
		stamp_visual.set_ambient_motion_enabled(true)
		_add_caption(stamp_visual)
	# The mouse may have been waiting on this stamp all through its turn.
	if hovered_stamp == stamp_index:
		_show_description()
	if batch:
		_flip_next_batch_stamp()
	if _are_all_stamps_flipped() and flips_running == 0:
		SFXManager.play("stamp_up")
		all_turned.emit()

## The name under a turned stamp, and what is special about it. The stamp's own
## small lettering is for the album; here it should read at a glance.
func _add_caption(stamp_visual: StampVisual) -> void:
	if batch or layer == null or !is_instance_valid(layer):
		return
	var caption := VBoxContainer.new()
	caption.name = "RewardCaption"
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.custom_minimum_size = PACK_REWARD_CAPTION_SIZE
	caption.size = PACK_REWARD_CAPTION_SIZE
	caption.set_meta("stamp_visual", stamp_visual)
	caption.add_theme_constant_override("separation", 2)
	layer.add_child(caption)
	captions.append(caption)

	var name_label := Label.new()
	caption.add_child(name_label)
	name_label.text = _get_stamp_name(stamp_visual)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.add_theme_color_override("font_color", UiPalette.PAPER_RAISED)

	var note: String = _get_stamp_note(stamp_visual)
	if !note.is_empty():
		var note_label := Label.new()
		caption.add_child(note_label)
		note_label.text = note.to_upper()
		note_label.theme_type_variation = &"KickerLabel"
		note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var rarity: int = get_rarity(stamp_visual)
		note_label.add_theme_color_override("font_color", UiPalette.COIN if rarity == StampPrint.Rarity.BASIC else PackRevealFx.get_light_color(rarity))
	_layout_captions()
	caption.modulate.a = 0.0
	caption.create_tween().tween_property(caption, "modulate:a", 1.0, 0.18)

func _layout_captions() -> void:
	for caption in captions:
		var stamp_visual := caption.get_meta("stamp_visual") as StampVisual
		if stamp_visual == null or !is_instance_valid(stamp_visual):
			continue
		var centre: Vector2 = stamp_visual.home_position + StampVisual.STAMP_SIZE * 0.5
		var half_height: float = StampVisual.STAMP_SIZE.y * stamp_visual.rest_scale.y * 0.5
		caption.position = Vector2(centre.x - caption.size.x * 0.5, centre.y + half_height + PACK_REWARD_CAPTION_GAP)

func _get_stamp_name(stamp_visual: StampVisual) -> String:
	var stamp: Stamp = StampPrintLibrary.get_stamp_for_print(stamp_visual.stamp_print)
	return stamp.stamp_name if stamp != null else stamp_visual.stamp_print.get_display_name()

func _get_stamp_note(stamp_visual: StampVisual) -> String:
	var notes: PackedStringArray = PackedStringArray()
	match get_rarity(stamp_visual):
		StampPrint.Rarity.FOIL:
			notes.append(tr("Foil"))
		StampPrint.Rarity.FULL_ART:
			notes.append(tr("Full Art"))
	if new_print_ids.has(stamp_visual.stamp_print.print_id):
		notes.append(tr("New"))
	return " · ".join(notes)

## The next stamp in reading order; a batch and a click on the table both turn this one.
func _get_next_unflipped_stamp() -> int:
	return flipped.find(false)

func _flip_next_batch_stamp() -> void:
	if !batch or full_art_showing or !turning:
		return
	var next_stamp: int = _get_next_unflipped_stamp()
	if next_stamp >= 0 and !batch_flip_waiting:
		batch_flip_waiting = true
		_flip_stamp(next_stamp)
		var tween := layer.create_tween()
		tween.tween_interval(PACK_BATCH_FLIP_STAGGER)
		tween.tween_callback(func() -> void:
			batch_flip_waiting = false
			_flip_next_batch_stamp()
		)

func _get_hitbox_rect(stamp_visual: StampVisual) -> Rect2:
	var scale_factor: float = maxf(stamp_visual.rest_scale.x, stamp_visual.rest_scale.y)
	if scale_factor <= 0.0:
		scale_factor = maxf(absf(stamp_visual.scale.x), absf(stamp_visual.scale.y))
	var visual_size: Vector2 = StampVisual.STAMP_SIZE * maxf(scale_factor, PACK_REWARD_MIN_SCALE)
	var visual_center: Vector2 = stamp_visual.home_position + StampVisual.STAMP_SIZE * 0.5
	return Rect2(visual_center - visual_size * 0.5, visual_size).grow(8.0)

## A click on the table turns the next stamp. True once all are turned: then the
## table is done with, and the overlay moves on.
func click_table() -> bool:
	if leaving or full_art_showing:
		return false
	var next_stamp: int = _get_next_unflipped_stamp()
	if next_stamp >= 0:
		_flip_stamp(next_stamp)
		return false
	return flips_running == 0

func _are_all_stamps_flipped() -> bool:
	return !stamps.is_empty() and !flipped.has(false)

## The stamps go off into the album, whose middle is `album_centre`.
func leave(album_centre: Vector2) -> void:
	leaving = true
	_hide_description()
	for caption in captions:
		caption.create_tween().tween_property(caption, "modulate:a", 0.0, 0.12)
	var stagger: float = PACK_LEAVE_STAGGER if stamps.size() <= PACK_REWARD_STAMP_COUNT else 0.01
	for i in range(stamps.size()):
		var stamp_visual: StampVisual = stamps[i]
		stamp_visual.set_ambient_motion_enabled(false)
		var tween := layer.create_tween()
		tween.tween_interval(float(i) * stagger)
		tween.tween_property(stamp_visual, "position", get_position_for_center(album_centre), PACK_LEAVE_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(stamp_visual, "scale", Vector2.ONE * PACK_LEAVE_SCALE, PACK_LEAVE_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(stamp_visual, "rotation", deg_to_rad(randf_range(-22.0, 22.0)), PACK_LEAVE_SECONDS)
		tween.tween_callback(Callable(stamp_visual, "hide"))
		if i < PACK_REWARD_STAMP_COUNT:
			tween.tween_callback(func() -> void: SFXManager.play("stamp_glue"))

	var gate_tween := layer.create_tween()
	gate_tween.tween_interval(PACK_LEAVE_SECONDS + float(stamps.size() - 1) * stagger + 0.06)
	gate_tween.tween_callback(func() -> void: left.emit())

func _get_stamp_positions(count: int, scale_factor: float) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if count <= 0:
		return positions

	var viewport_size: Vector2 = _get_viewport_size()
	var visual_size: Vector2 = StampVisual.STAMP_SIZE * scale_factor
	var columns: int = _get_columns(count)
	var rows: int = int(ceil(float(count) / float(columns)))
	var gap: float = _get_stamp_gap(viewport_size, columns, scale_factor)
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
		positions.append(get_position_for_center(center))
	return positions

## One row for a pack, and the most square table for a whole heap.
func _get_columns(count: int) -> int:
	if count <= PACK_REWARD_STAMP_COUNT:
		return maxi(1, count)
	return maxi(PACK_REWARD_STAMP_COUNT, int(ceil(sqrt(float(count) * 1.8))))

func _get_stamp_scale(viewport_size: Vector2, count: int) -> float:
	if count <= 0:
		return PACK_REWARD_MAX_SCALE
	var columns: int = _get_columns(count)
	var rows: int = int(ceil(float(count) / float(columns)))
	var gap: float = clampf(viewport_size.x * 0.034, 18.0, 42.0)
	var available_width: float = maxf(120.0, viewport_size.x - PACK_REWARD_SIDE_MARGIN * 2.0)
	var width_scale: float = (available_width - gap * float(maxi(0, columns - 1))) / (StampVisual.STAMP_SIZE.x * float(columns))
	var available_height: float = viewport_size.y - 180.0 - PACK_REWARD_ROW_GAP * float(rows - 1)
	var height_scale: float = maxf(PACK_REWARD_MIN_SCALE, available_height / (StampVisual.STAMP_SIZE.y * float(rows)))
	return clampf(minf(PACK_REWARD_MAX_SCALE, minf(width_scale, height_scale)), PACK_REWARD_MIN_SCALE, PACK_REWARD_MAX_SCALE)

func _get_stamp_gap(viewport_size: Vector2, count: int, scale_factor: float) -> float:
	if count <= 1:
		return 0.0
	var base_gap: float = clampf(viewport_size.x * 0.034, 18.0, 42.0)
	var visual_width: float = StampVisual.STAMP_SIZE.x * scale_factor
	var available_width: float = maxf(120.0, viewport_size.x - PACK_REWARD_SIDE_MARGIN * 2.0)
	var max_gap: float = maxf(8.0, (available_width - visual_width * float(count)) / float(count - 1))
	return minf(base_gap, max_gap)

func _get_viewport_size() -> Vector2:
	if viewport_item != null and is_instance_valid(viewport_item):
		return viewport_item.get_viewport_rect().size
	return Vector2(1280.0, 720.0)

func _free_stamps() -> void:
	for stamp_visual in stamps:
		if stamp_visual != null and is_instance_valid(stamp_visual):
			var parent := stamp_visual.get_parent()
			if parent != null:
				parent.remove_child(stamp_visual)
			if !stamp_visual.is_queued_for_deletion():
				stamp_visual.queue_free()
	stamps.clear()
	for hitbox in hitboxes:
		if hitbox != null and is_instance_valid(hitbox):
			var parent := hitbox.get_parent()
			if parent != null:
				parent.remove_child(hitbox)
			if !hitbox.is_queued_for_deletion():
				hitbox.queue_free()
	hitboxes.clear()
	flipped.clear()
	captions.clear()
	full_art_showing = false
	flips_running = 0
	hovered_stamp = -1
	description_panel = null
	description_label = null

## Throws the table away for a new choice of packs: the rest of the layer's
## children are the overlay's to clear.
func reset() -> void:
	build_id += 1
	_free_stamps()
	full_art_stage = null
	batch = false
	batch_flip_waiting = false
	turning = false
	leaving = false

## The overlay is closing and takes its layers, and everything on them, with it.
func forget() -> void:
	build_id += 1
	hovered_stamp = -1
	description_panel = null
	description_label = null
	full_art_stage = null
	batch = false
	batch_flip_waiting = false
	stamps.clear()
	flipped.clear()
	hitboxes.clear()
	captions.clear()
	full_art_showing = false
	flips_running = 0
	turning = false
	leaving = false
	layer = null
