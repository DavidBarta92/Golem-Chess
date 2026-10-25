extends RefCounted

const BURN_SHADER = preload("res://Shaders/stamp_burn.gdshader")
const GLOW_SHADER = preload("res://Shaders/piece_attach_glow.gdshader")
const InkStampMaterial = preload("res://Scripts/InkStamp/InkStampMaterial.gd")

var match_board

var canvas_layer: CanvasLayer
var cell_size: Vector2 = Vector2(42.0, 42.0)
var cell_gap: float = 6.0
var grid_columns: int = 6
var grid_right_margin: float = 24.0
var grid_bottom_margin: float = 24.0
var icon_padding: float = 5.0
var pop_in_duration: float = 0.22
var reflow_duration: float = 0.22
# Matches StampVisual.play_burn_away_and_free()'s own timing/motion (same
# BURN_SHADER, same rise/shrink/rotate drift) so an effect icon disappears
# with the exact same animation as an expired stamp disappearing above a
# piece.
var burn_duration: float = 1.15
var burn_rise_distance: float = 28.0
var burn_scale_multiplier: float = 0.82
var burn_rotation_jitter_degrees: float = 7.0
var flash_step_duration: float = 0.11
var flash_scale_peak: float = 1.15
# The activation flash uses piece_attach_glow.gdshader (same shader/pattern
# PieceEffectAnimator uses for the piece-attach glow pulse) on the icon
# itself, rather than a plain scale/modulate punch.
var flash_glow_color: Color = Color(1.0, 0.85, 0.35, 1.0)
var flash_glow_size: float = 5.0
var flash_glow_fill_strength: float = 0.35
var flash_glow_peak_strength: float = 4.0
var flash_glow_fade_duration: float = 0.3
# These standalone icon SVGs are drawn edge-to-edge in their own viewBox (no
# transparent margin around the glyph), so the glow shader's own edge-alpha
# expansion has no room to bleed into within the source texture. Scaling the
# whole glow copy up during the flash guarantees a visible halo regardless
# (it pokes out past the crisp icon on top purely by being drawn bigger),
# on top of whatever the shader's own expansion contributes.
var flash_glow_scale_peak: float = 1.5
# A slow, soft breathing pulse played continuously on any persistent entry
# while it isn't otherwise flashing, so "this effect is still in effect"
# reads differently on-screen from the sharp "it just activated" flash.
var idle_pulse_peak_strength: float = 2.2
var idle_pulse_scale_peak: float = 1.28
var idle_pulse_half_duration: float = 1.1
# Icons sit dimmed by default so the grid doesn't compete for attention with
# the board, and snap to full opacity while the mouse is over them.
var icon_default_opacity: float = 0.7
var icon_hover_opacity: float = 1.0
var icon_hover_fade_duration: float = 0.12

const STATEFUL_EFFECT_TYPES := [
	StampEffect.TYPE_FROZEN_SQUARES,
	StampEffect.TYPE_INVALID_SQUARES,
	StampEffect.TYPE_INVISIBLE_TO_ENEMY,
	StampEffect.TYPE_UNCAPTURABLE,
]

var container: Control
var _active_entries_by_key: Dictionary = {}
var _order: Array = []

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	canvas_layer = config.get("canvas_layer", canvas_layer)
	cell_size = config.get("cell_size", cell_size)
	cell_gap = float(config.get("cell_gap", cell_gap))
	grid_columns = int(config.get("grid_columns", grid_columns))
	grid_right_margin = float(config.get("grid_right_margin", grid_right_margin))
	grid_bottom_margin = float(config.get("grid_bottom_margin", grid_bottom_margin))

func create_ui() -> void:
	if canvas_layer == null or !is_instance_valid(canvas_layer):
		return
	if container != null and is_instance_valid(container):
		return

	container = Control.new()
	canvas_layer.add_child(container)
	container.name = "BoardEffectIconGrid"
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.anchor_left = 1.0
	container.anchor_right = 1.0
	container.anchor_top = 1.0
	container.anchor_bottom = 1.0
	container.offset_left = 0.0
	container.offset_right = 0.0
	container.offset_top = 0.0
	container.offset_bottom = 0.0
	container.z_index = 890

# Recomputes which effects are currently active on the board (both players)
# and adds/removes/reflows grid cells to match. Call once per state sync,
# before any activation flash for that same sync (see
# ServerStateVisualUpdateController.finish()) so an effect that both appears
# and fires for the first time in one sync already has a cell to flash.
# recent_effect_activations (same array animate_recent_effect_activations
# gets right after) is used here too: a persistent entry whose trigger just
# fired AND is leaving the active set this same sync (on_captured/on_expire --
# the piece/stamp is gone by the time this recompute runs) still needs to
# flash before it burns away, instead of silently vanishing.
func refresh_active_effects(recent_effect_activations: Array = []) -> void:
	create_ui()
	if container == null or !is_instance_valid(container) or match_board == null:
		return

	var animate: bool = bool(match_board.has_received_server_state) and !bool(match_board.should_skip_visual_animations())
	var activated_keys_this_sync: Dictionary = _collect_activated_keys(recent_effect_activations)

	var new_entries: Array = compute_active_entries()
	var new_keys: Dictionary = {}
	for entry in new_entries:
		new_keys[str(entry.get("key", ""))] = true

	var removed_keys: Array = []
	for key in _order:
		if !new_keys.has(key):
			removed_keys.append(key)
	for key in removed_keys:
		if activated_keys_this_sync.has(str(key)):
			_flash_then_burn_entry(str(key), animate)
		else:
			_burn_away_entry(str(key), animate)

	for entry in new_entries:
		var key: String = str(entry.get("key", ""))
		if !_active_entries_by_key.has(key):
			_add_entry(entry, animate)

	_relayout(animate)

	if animate:
		_ensure_idle_pulses(activated_keys_this_sync)

# Starts the idle pulse for any currently-active entry that doesn't already
# have one running (a fresh add on this sync, or one added on an earlier
# sync where animate was false -- e.g. the very first sync after connecting,
# before has_received_server_state flips true -- and so never got one
# scheduled at all). Entries with a fresh activation this sync are skipped:
# animate_recent_effect_activations (called right after this function, see
# ServerStateVisualUpdateController.finish()) flashes those and starts their
# idle pulse itself once the flash ends -- starting it here too would race a
# second, separately running tween against that flash over the same
# properties (glow_strength, glow_rect scale) and make them fight each frame.
func _ensure_idle_pulses(activated_keys_this_sync: Dictionary) -> void:
	for key in _order:
		if activated_keys_this_sync.has(key):
			continue
		if !_active_entries_by_key.has(key):
			continue
		var record: Dictionary = _active_entries_by_key[key]
		if !bool(record.get("entry", {}).get("continuously_active", false)):
			continue
		var idle_tween: Tween = record.get("idle_tween") as Tween
		if idle_tween != null and idle_tween.is_valid():
			continue
		_start_idle_pulse(key)

func _collect_activated_keys(recent_effect_activations: Array) -> Dictionary:
	var keys: Dictionary = {}
	if match_board == null:
		return keys
	for activation_value in recent_effect_activations:
		if !(activation_value is Dictionary):
			continue
		var activation: Dictionary = activation_value
		var source_pos: Vector2 = match_board.value_to_vector2(activation.get("source_pos", Vector2(-1, -1)), Vector2(-1, -1))
		if match_board.is_valid_position(source_pos):
			keys["piece:" + str(source_pos)] = true
	return keys

# One entry per currently-affected piece (so e.g. three frozen_squares-
# granting stamps on the board show three icons, not one deduplicated by
# type). Two independent questions decide each entry:
#
# 1. Does it get a lingering entry at all, or just a one-off flash? Decided
#    by the stamp's TRIGGER: TRIGGER_ON_AFFIX fires exactly once, at the
#    instant the stamp is placed, and can never fire again for that stamp.
#    By the time this recompute runs that instant has already passed, so an
#    on_affix stamp only gets a lingering entry here if it's a stateful
#    effect (see below) whose window is still open -- otherwise it only got
#    a one-off appear+flash+burn in animate_recent_effect_activations, and
#    there's nothing left to show. Every other trigger (on_move, on_capture,
#    on_symbol_count, on_captured, on_expire, ...) can in principle fire
#    again while the stamp remains affixed, so it always gets a lingering
#    entry for as long as the stamp is affixed, whether or not it happens to
#    be active right now.
# 2. Given a lingering entry, is the effect actually doing something right
#    now ("continuously_active", gets the slow idle pulse -- see
#    _ensure_idle_pulses/play_activation_flash_by_key) or just present and
#    waiting for its trigger to fire (no pulse, sits still except for the
#    sharp flash exactly when it fires)? This is decided by the effect TYPE,
#    not the trigger -- e.g. increase_self_duration-on_capture never has
#    anything ongoing between captures, while STATEFUL_EFFECT_TYPES
#    (frozen/invalid squares, invisibility, uncapturable) represent an
#    actual ongoing state whenever their own separate timer says so --
#    squares via current_board_effects
#    (StampEffectResolver.BOARD_ZONE_EFFECT_TURNS), invisibility/uncapturable
#    via Piece.protection_turns_remaining
#    (StampEffectResolver.tick_piece_protection_windows) -- both independent
#    of the stamp's own (move-based) duration. So e.g. a Numero_5
#    (invalid_squares, on_move) that hasn't moved yet this session, or whose
#    last zone already expired, still shows its icon (rule 1: on_move keeps
#    it lingering) but doesn't pulse (rule 2: no zone currently open) --
#    until it moves again and actually opens one.
func compute_active_entries() -> Array:
	var entries: Array = []
	if match_board == null:
		return entries

	for pos in match_board.piece_objects.keys():
		var piece: Piece = match_board.piece_objects[pos] as Piece
		if piece == null:
			continue

		var board_pos: Vector2 = match_board.value_to_vector2(pos, Vector2(-1, -1))

		if piece.hidden_from_viewer:
			entries.append(_make_entry(pos, StampEffect.TYPE_INVISIBLE_TO_ENEMY, board_pos, true))
			continue

		var stamp: Stamp = piece.affixed_stamp
		if stamp == null or !stamp.has_effect():
			continue

		var is_stateful: bool = STATEFUL_EFFECT_TYPES.has(stamp.effect_type)
		var currently_active: bool = is_stateful and _is_stateful_effect_currently_active(piece, board_pos, stamp)

		if stamp.effect_trigger == StampEffect.TRIGGER_ON_AFFIX:
			if currently_active:
				entries.append(_make_entry(pos, stamp.effect_type, board_pos, true))
			continue

		entries.append(_make_entry(pos, stamp.effect_type, board_pos, currently_active))

	return entries

func _make_entry(pos, effect_type: String, board_pos: Vector2, continuously_active: bool) -> Dictionary:
	return {
		"key": "piece:" + str(pos),
		"effect_type": effect_type,
		"board_pos": board_pos,
		"continuously_active": continuously_active,
	}

func _is_stateful_effect_currently_active(piece: Piece, board_pos: Vector2, stamp: Stamp) -> bool:
	match stamp.effect_type:
		StampEffect.TYPE_INVISIBLE_TO_ENEMY, StampEffect.TYPE_UNCAPTURABLE:
			# The local player always sees their own piece (hidden_from_viewer
			# is only ever true for the *enemy's* view of it), and
			# uncapturable never hides anything -- protection_turns_remaining
			# (synced from the server) is what tells the client whether the
			# protection window is actually still running right now.
			return piece.protection_turns_remaining > 0
		StampEffect.TYPE_FROZEN_SQUARES, StampEffect.TYPE_INVALID_SQUARES:
			return _board_effects_has_source(board_pos, stamp.effect_type)
	return false

func _board_effects_has_source(board_pos: Vector2, effect_type: String) -> bool:
	if match_board == null:
		return false
	for board_effect_value in match_board.current_board_effects:
		if !(board_effect_value is Dictionary):
			continue
		var board_effect: Dictionary = board_effect_value
		if str(board_effect.get("effect_type", "")) != effect_type:
			continue
		if board_effect.get("source_pos", Vector2(-1, -1)) == board_pos:
			return true
	return false

func _add_entry(entry: Dictionary, animate: bool) -> Tween:
	var key: String = str(entry.get("key", ""))
	var cell: Control = _create_cell(entry)
	_active_entries_by_key[key] = {"entry": entry, "cell": cell}
	_order.append(key)
	# Adds only ever happen after removals in the same refresh (see
	# refresh_active_effects), so the append-time index already matches this
	# cell's final slot -- place it there directly so _relayout doesn't slide
	# it in from the Control default (0, 0).
	cell.position = _get_slot_local_position(_order.size() - 1)

	if !animate:
		return null
	cell.scale = Vector2.ZERO
	var pop_tween: Tween = cell.create_tween()
	pop_tween.tween_property(cell, "scale", Vector2.ONE, pop_in_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	return pop_tween

func _create_cell(entry: Dictionary) -> Control:
	var cell := Control.new()
	container.add_child(cell)
	cell.name = "EffectCell_" + str(entry.get("key", ""))
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.custom_minimum_size = cell_size
	cell.size = cell_size
	cell.pivot_offset = cell_size * 0.5
	cell.modulate.a = icon_default_opacity

	# Hovering an effect icon shows the same piece+stamp+description panel as
	# hovering the piece itself on the board (match_board.show_hover_piece_details
	# already no-ops safely if the local player isn't entitled to know the
	# stamp, e.g. an opponent's still-hidden piece).
	var board_pos: Vector2 = entry.get("board_pos", Vector2(-1, -1))
	cell.mouse_entered.connect(Callable(self, "_on_cell_mouse_entered").bind(board_pos, cell))
	cell.mouse_exited.connect(Callable(self, "_on_cell_mouse_exited").bind(cell))

	var effect_type: String = str(entry.get("effect_type", ""))
	# The plain EFFECT_ICON_TEXTURES/TRIGGER_ICON_TEXTURES (used on the stamp
	# card's EffectArt/TriggerArt) are not single centered glyphs -- they're
	# faint, repeating watermark-style patterns drawn across a whole
	# stamp-card-sized canvas (their paths even extend outside the declared
	# viewBox). Stretched into a small grid cell that shows only a tiny
	# fragment of one repeat. EFFECT_ICON_STANDALONE_TEXTURES is a real single
	# glyph in a tight viewBox, built for exactly this kind of isolated
	# display, so it's used here instead. There's no standalone equivalent
	# for trigger icons in the project, so the trigger icon is omitted.
	var effect_icon: Texture2D = StampEffect.get_effect_icon_standalone_texture(effect_type)
	var icon_area: Vector2 = cell_size - Vector2.ONE * icon_padding * 2.0

	# GLOW_SHADER fully replaces COLOR with just the glow silhouette (alpha 0
	# at glow_strength 0) rather than compositing onto the source texture --
	# it's meant to sit on a separate overlay behind the real icon, the same
	# way PieceEffectAnimator.create_glow_overlay() duplicates the piece
	# sprite for its own attach-glow instead of shading the piece directly.
	var glow_rect := TextureRect.new()
	cell.add_child(glow_rect)
	glow_rect.name = "EffectIconGlow"
	glow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow_rect.texture = effect_icon
	glow_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	glow_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow_rect.size = icon_area
	glow_rect.position = Vector2.ONE * icon_padding
	glow_rect.pivot_offset = icon_area * 0.5

	# glow_size is measured in the *texture's own* pixels (glow_size *
	# TEXTURE_PIXEL_SIZE), but these standalone icon SVGs are rasterized much
	# larger (svg/scale in their .import) than the ~32px they're displayed at
	# here -- a fixed glow_size tuned for a roughly 1:1 sprite (as used
	# elsewhere for pieces) ends up under a screen pixel wide and invisible.
	# Scale it by the actual texture-to-display ratio so the glow reads as a
	# constant number of screen pixels regardless of the source asset's raw
	# resolution.
	var glow_material := ShaderMaterial.new()
	glow_material.shader = GLOW_SHADER
	glow_material.set_shader_parameter("glow_color", flash_glow_color)
	glow_material.set_shader_parameter("glow_strength", 0.0)
	var texture_to_display_ratio: float = 1.0
	if effect_icon != null and icon_area.x > 0.0:
		texture_to_display_ratio = float(effect_icon.get_width()) / icon_area.x
	glow_material.set_shader_parameter("glow_size", flash_glow_size * texture_to_display_ratio)
	glow_material.set_shader_parameter("fill_strength", flash_glow_fill_strength)
	glow_rect.material = glow_material

	var effect_rect := TextureRect.new()
	cell.add_child(effect_rect)
	effect_rect.name = "EffectIcon"
	effect_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_rect.texture = effect_icon
	effect_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	effect_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	effect_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	effect_rect.size = icon_area
	effect_rect.position = Vector2.ONE * icon_padding
	# Printed with the UI's ink stamp; filled glyphs, so with the fill's specks.
	# The cell's own fade (icon_default_opacity) sits on top of it, and the burn
	# takes the material over when the icon goes.
	InkStampMaterial.apply(effect_rect, true)

	return cell

func _on_cell_mouse_entered(board_pos: Vector2, cell: Control) -> void:
	_animate_cell_opacity(cell, icon_hover_opacity)
	if match_board == null or !match_board.is_valid_position(board_pos):
		return
	match_board.show_hover_piece_details(board_pos)
	match_board.set_hover_highlighted_piece(board_pos)

func _on_cell_mouse_exited(cell: Control) -> void:
	_animate_cell_opacity(cell, icon_default_opacity)
	if match_board == null:
		return
	match_board.hide_hover_piece_details()

func _animate_cell_opacity(cell: Control, target_alpha: float) -> void:
	if cell == null or !is_instance_valid(cell):
		return
	var existing_tween: Tween = cell.get_meta("opacity_tween", null) as Tween
	if existing_tween != null and existing_tween.is_valid():
		existing_tween.kill()
	var tween: Tween = cell.create_tween()
	tween.tween_property(cell, "modulate:a", target_alpha, icon_hover_fade_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	cell.set_meta("opacity_tween", tween)

func _burn_away_entry(key: String, animate: bool) -> void:
	if !_active_entries_by_key.has(key):
		return
	var record: Dictionary = _active_entries_by_key[key]
	var cell: Control = record.get("cell") as Control
	_kill_idle_tween(record)
	_active_entries_by_key.erase(key)
	_order.erase(key)

	if cell == null or !is_instance_valid(cell):
		return
	if !animate:
		cell.queue_free()
		return

	_start_burn_on_cell(cell)

func _start_burn_on_cell(cell: Control) -> void:
	if cell == null or !is_instance_valid(cell):
		return
	# cell itself is a plain Control with no draw calls of its own -- a
	# material set on it has nothing to shade and is invisible. The burn has
	# to go on the TextureRect that actually draws the icon; cell.material
	# was a no-op here, which is why only the position/scale/rotation drift
	# below was ever visible.
	var icon_rect: TextureRect = cell.get_node_or_null("EffectIcon") as TextureRect
	if icon_rect == null:
		return
	var burn_material := ShaderMaterial.new()
	burn_material.shader = BURN_SHADER
	burn_material.set_shader_parameter("burn_progress", 0.0)
	burn_material.set_shader_parameter("seed", randf() * 1000.0)
	icon_rect.material = burn_material

	var burn_tween: Tween = cell.create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	burn_tween.tween_property(burn_material, "shader_parameter/burn_progress", 1.0, burn_duration)
	burn_tween.parallel().tween_property(cell, "position", cell.position + Vector2(0.0, -burn_rise_distance), burn_duration)
	burn_tween.parallel().tween_property(cell, "scale", cell.scale * burn_scale_multiplier, burn_duration)
	burn_tween.parallel().tween_property(cell, "rotation", cell.rotation + deg_to_rad(randf_range(-burn_rotation_jitter_degrees, burn_rotation_jitter_degrees)), burn_duration)
	burn_tween.tween_callback(Callable(cell, "queue_free"))

# Used when a persistent entry's departure this sync coincides with its own
# trigger firing (on_captured/on_expire): the entry is leaving the active set
# either way, but it should flash first so the activation is actually visible
# instead of the icon just silently vanishing mid-flash.
func _flash_then_burn_entry(key: String, animate: bool) -> void:
	if !_active_entries_by_key.has(key):
		return
	var record: Dictionary = _active_entries_by_key[key]
	var cell: Control = record.get("cell") as Control
	_kill_idle_tween(record)
	_active_entries_by_key.erase(key)
	_order.erase(key)

	if cell == null or !is_instance_valid(cell):
		return
	if !animate:
		cell.queue_free()
		return

	var tween: Tween = cell.create_tween()
	_append_flash_steps(tween, cell)
	tween.tween_callback(Callable(self, "_start_burn_on_cell").bind(cell))

func _get_glow_rect(cell: Control) -> TextureRect:
	if cell == null or !is_instance_valid(cell):
		return null
	return cell.get_node_or_null("EffectIconGlow") as TextureRect

func _kill_idle_tween(record: Dictionary) -> void:
	var idle_tween: Tween = record.get("idle_tween") as Tween
	if idle_tween != null and idle_tween.is_valid():
		idle_tween.kill()
	record.erase("idle_tween")

# Starts (or restarts) the slow idle breathing pulse for a still-active entry.
# Always stops any existing one first, since this is also used to resume the
# idle loop right after a sharp activation flash finishes, and the two must
# never run at once -- they animate the same properties (glow_strength,
# glow_rect scale) and would otherwise fight each other every frame.
func _start_idle_pulse(key: String) -> void:
	if !_active_entries_by_key.has(key):
		return
	var record: Dictionary = _active_entries_by_key[key]
	_kill_idle_tween(record)

	var cell: Control = record.get("cell") as Control
	var glow_rect: TextureRect = _get_glow_rect(cell)
	var glow_material: ShaderMaterial = glow_rect.material as ShaderMaterial if glow_rect != null else null
	if glow_rect == null or glow_material == null:
		return

	var idle_tween: Tween = cell.create_tween().set_loops()
	idle_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.tween_property(glow_material, "shader_parameter/glow_strength", idle_pulse_peak_strength, idle_pulse_half_duration)
	idle_tween.parallel().tween_property(glow_rect, "scale", Vector2.ONE * idle_pulse_scale_peak, idle_pulse_half_duration)
	idle_tween.tween_property(glow_material, "shader_parameter/glow_strength", 0.0, idle_pulse_half_duration)
	idle_tween.parallel().tween_property(glow_rect, "scale", Vector2.ONE, idle_pulse_half_duration)
	record["idle_tween"] = idle_tween

func _stop_idle_pulse(key: String) -> void:
	if !_active_entries_by_key.has(key):
		return
	_kill_idle_tween(_active_entries_by_key[key])

func _append_flash_steps(tween: Tween, cell: Control) -> void:
	var glow_rect: TextureRect = _get_glow_rect(cell)
	var glow_material: ShaderMaterial = glow_rect.material as ShaderMaterial if glow_rect != null else null

	tween.tween_property(cell, "scale", Vector2.ONE * flash_scale_peak, flash_step_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	if glow_material != null:
		tween.parallel().tween_property(glow_material, "shader_parameter/glow_strength", flash_glow_peak_strength, flash_step_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	if glow_rect != null:
		# The shader's own edge-alpha expansion has little room to work with
		# on these edge-to-edge icon SVGs (see the comment on
		# flash_glow_scale_peak), so scaling the whole glow copy up is what
		# actually guarantees a visible halo poking out past the crisp icon.
		tween.parallel().tween_property(glow_rect, "scale", Vector2.ONE * flash_glow_scale_peak, flash_step_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	tween.tween_property(cell, "scale", Vector2.ONE, flash_glow_fade_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	if glow_material != null:
		tween.parallel().tween_property(glow_material, "shader_parameter/glow_strength", 0.0, flash_glow_fade_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	if glow_rect != null:
		tween.parallel().tween_property(glow_rect, "scale", Vector2.ONE, flash_glow_fade_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)

# Row 0 sits at the bottom edge (grid_bottom_margin), column 0 sits closest
# to the right edge (grid_right_margin) -- extra rows past grid_columns
# entries stack upward.
func _get_slot_local_position(index: int) -> Vector2:
	var column: int = index % grid_columns
	var row: int = index / grid_columns
	var step: Vector2 = cell_size + Vector2.ONE * cell_gap
	var x: float = -grid_right_margin - cell_size.x - float(column) * step.x
	var y: float = -grid_bottom_margin - cell_size.y - float(row) * step.y
	return Vector2(x, y)

func _relayout(animate: bool) -> void:
	for index in _order.size():
		var key: String = _order[index]
		if !_active_entries_by_key.has(key):
			continue
		var cell: Control = _active_entries_by_key[key].get("cell") as Control
		if cell == null or !is_instance_valid(cell):
			continue
		var target_position: Vector2 = _get_slot_local_position(index)
		if !animate or cell.position.is_equal_approx(target_position):
			cell.position = target_position
			continue
		var move_tween: Tween = cell.create_tween()
		move_tween.tween_property(cell, "position", target_position, reflow_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func play_activation_flash_by_key(key: String) -> void:
	if !_active_entries_by_key.has(key):
		return
	var record: Dictionary = _active_entries_by_key[key]
	var cell: Control = record.get("cell") as Control
	if cell == null or !is_instance_valid(cell):
		return
	_stop_idle_pulse(key)
	var tween: Tween = cell.create_tween()
	_append_flash_steps(tween, cell)
	# Only resume idle pulsing afterward for effects that are actually still
	# in effect (see compute_active_entries) -- an event-triggered effect
	# like increase_self_duration-on_capture has nothing ongoing between
	# firings, so it should go back to sitting still, not keep breathing.
	if bool(record.get("entry", {}).get("continuously_active", false)):
		tween.tween_callback(Callable(self, "_start_idle_pulse").bind(key))

# Every entry (zone-type included -- see compute_active_entries) is keyed by
# the piece position that carries the stamp, so no per-effect-type branching
# is needed here: a matching persistent entry just flashes; a trigger with no
# persistent entry (TRIGGER_ON_AFFIX) plays a one-off appear+flash+burn so
# its single activation is still visible for a moment, per the current
# design (on_affix effects are meaningful only at the instant they fire).
func animate_recent_effect_activations(recent_effect_activations: Array) -> void:
	if match_board == null:
		return

	var animate: bool = bool(match_board.has_received_server_state) and !bool(match_board.should_skip_visual_animations())

	for activation_value in recent_effect_activations:
		if !(activation_value is Dictionary):
			continue

		var activation: Dictionary = activation_value
		var stamp_name: String = str(activation.get("stamp_name", ""))
		if stamp_name.is_empty():
			continue

		var source_pos: Vector2 = match_board.value_to_vector2(activation.get("source_pos", Vector2(-1, -1)), Vector2(-1, -1))
		if !match_board.is_valid_position(source_pos):
			continue

		var key: String = "piece:" + str(source_pos)
		if _active_entries_by_key.has(key):
			play_activation_flash_by_key(key)
			continue

		_play_ephemeral_activation(key, source_pos, animate)

func _play_ephemeral_activation(key: String, board_pos: Vector2, animate: bool) -> void:
	if match_board == null or !match_board.piece_objects.has(board_pos):
		return
	var piece: Piece = match_board.piece_objects[board_pos] as Piece
	if piece == null or piece.affixed_stamp == null:
		return

	var entry: Dictionary = {
		"key": key,
		"effect_type": piece.affixed_stamp.effect_type,
		"board_pos": board_pos,
	}
	var pop_tween: Tween = _add_entry(entry, animate)
	_relayout(animate)

	if !animate or pop_tween == null:
		_burn_away_entry(key, animate)
		return

	var record: Dictionary = _active_entries_by_key.get(key, {})
	var cell: Control = record.get("cell") as Control
	if cell == null or !is_instance_valid(cell):
		return

	_append_flash_steps(pop_tween, cell)
	pop_tween.tween_callback(Callable(self, "_burn_away_entry").bind(key, animate))
