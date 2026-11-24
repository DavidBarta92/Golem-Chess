extends RefCounted

# A momentary, piece-anchored animation for whenever a piece's stamp duration
# changes. Two kinds:
# - play(): the piece's own move used up a turn of its duration (see
#   PieceEffectFlowController). That comes after nearly every move a stamped
#   piece makes, so it stays quiet: the old number falls off, the new one
#   knocks in.
# - play_effect_changes(): an effect raised or lowered the duration of one or
#   several pieces. It runs as a wave out from the effect's square, and each
#   piece answers the way it does when a stamp is pressed onto it. Raised: the
#   new number knocks down onto the old one, the piece gives under it and
#   springs up, and a ring of ink runs out from its feet. Lowered: the piece is
#   pressed down, its old number is knocked off, and the ink is drawn back in.
#   A knock sounds along the wave, rising or falling with it.
# - play_move_change(): the piece that moved, whose own effect (Berserk on a
#   capture, Cherry tree on a move) changed its count as well: the effect
#   first, then the tick, in the host's order.
# Unlike StampHoverPreviewController's duration display (one persistent,
# reused instance tied to whatever's hovered), each call builds a fully
# self-contained, self-cleaning set of nodes, so several of these can run
# concurrently for different pieces without conflict.

const PieceMoveAnimator = preload("res://Scripts/MatchView/PieceMoveAnimator.gd")
const DURATION_LABEL_FONT = preload("res://Fonts/OLDENGL.TTF")
const SOFT_DROP_SHADOW_SHADER = preload("res://Shaders/soft_drop_shadow.gdshader")
const DURATION_BUBBLE_TEXTURE = preload("res://Assets/dot.svg")
const DURATION_BUBBLE_SHADER = preload("res://Shaders/move_option_dot.gdshader")
## The effects whose activation square a wave starts from.
const DURATION_EFFECT_TYPES := [
	StampEffect.TYPE_INCREASE_OWN_DURATIONS,
	StampEffect.TYPE_INCREASE_ENEMY_DURATIONS,
	StampEffect.TYPE_DECREASE_OWN_DURATIONS,
	StampEffect.TYPE_DECREASE_ENEMY_DURATIONS,
	StampEffect.TYPE_INCREASE_SELF_DURATION,
]
## On a holder while it is squashed here: its own scale and position, and the
## tween, so a second change on it before the first is over starts from its
## true size instead of keeping a squash.
const SQUASH_META: StringName = &"duration_change_squash"

var match_board
var canvas_layer: CanvasLayer

var render_size: Vector2 = Vector2(64, 48)
var vertical_offset: float = -46.0
var shadow_color: Color = Color(0.070588, 0.070588, 0.474510, 0.9)
var shadow_blur: float = 1.6
var outline_size: int = 3

# The old number shows for a moment before it goes, so it can be read.
var old_number_rest_duration: float = 0.14
var old_number_fade_in_duration: float = 0.06
# Knocked off (a count gone down): it jumps a little, then falls tilting
# and fades. Screen pixels, radians and seconds.
var old_number_knock_up_distance: float = 4.0
var old_number_knock_up_duration: float = 0.07
var old_number_fall_distance: float = 24.0
var old_number_fall_drift: float = 8.0
var old_number_fall_tilt: float = 0.6
var old_number_fall_duration: float = 0.38
# Stamped over (a count gone up): flattened under the new one as it lands.
var old_number_flatten_scale: Vector2 = Vector2(1.25, 0.25)
var old_number_flatten_duration: float = 0.09

# How a new number goes once it has been read: it rises a little and fades.
var new_number_fade_out_duration: float = 0.5
var new_number_fade_out_rise_distance: float = 8.0

# A move's own turn used (play): the new number knocks in small, soon after
# the old one starts falling, and does not stay long.
var tick_knock_delay: float = 0.1
var tick_drop_distance: float = 10.0
var tick_drop_scale: float = 1.3
var tick_drop_duration: float = 0.12
var tick_landing_squash: Vector2 = Vector2(1.12, 0.88)
var tick_settle_duration: float = 0.24
var tick_hold_duration: float = 0.3
var tick_fade_out_duration: float = 0.35

var bubble_count: int = 7
var bubble_reference_size: float = 22.0
var bubble_min_size_ratio: float = 0.14
var bubble_max_size_ratio: float = 0.28
var bubble_spawn_radius: float = 9.0
var bubble_edge_softness: float = 1.0
var bubble_glow_strength: float = 1.2
var bubble_pop_in_duration: float = 0.6
var bubble_drift_duration: float = 1.0
var bubble_fade_out_duration: float = 1.5
var bubble_drift_rise_distance: float = 6.0
var bubble_fade_rise_distance: float = 6.0

# A stamp's duration knocked onto its piece (play_stamped), and a count raised
# by an effect: the new number comes down from above, larger, lands squashed
# and springs back, and its bubbles burst out as it lands. Screen pixels and
# seconds.
var stamped_drop_distance: float = 18.0
var stamped_drop_scale: float = 1.7
var stamped_drop_duration: float = 0.16
var stamped_landing_squash: Vector2 = Vector2(1.2, 0.8)
var stamped_settle_duration: float = 0.32
# Longer than a move's new number: it comes during the stamp's flash, and it
# should still be there to read once the piece's new look has come out of it.
var stamped_hold_duration: float = 1.4

# An effect's changes (play_effect_changes): the wave reaches a square this
# many seconds after the one before it, from the effect's square; the new
# number stays this long; the ring of ink is this share of a square across
# (a stamp pressed on makes a 0.55 one).
var effect_wave_step: float = 0.08
var effect_hold_duration: float = 0.9
var effect_ink_ring_radius: float = 0.42
# Raised: as the new number lands the piece gives under it, then springs up a
# little larger than itself and settles back. Squashes are (width, height)
# about the feet.
var raise_press_squash: Vector2 = Vector2(1.07, 0.88)
var raise_press_duration: float = 0.06
var raise_pop_stretch: Vector2 = Vector2(1.04, 1.09)
var raise_pop_duration: float = 0.16
var raise_settle_duration: float = 0.45
# Lowered: pressed down and a little narrower as its number is knocked off,
# held there a moment, and let up slowly, without springing.
var lower_press_squash: Vector2 = Vector2(0.96, 0.86)
var lower_press_duration: float = 0.08
var lower_press_hold: float = 0.12
var lower_release_duration: float = 0.4
# A piece's own effect changing its count as it moves (play_move_change) or
# as its stamp goes on (play_stamped_change): the number before the second
# step stays this long, then that step takes it, the two crossing over this
# long.
var move_effect_hold_duration: float = 0.35
var move_effect_handover_duration: float = 0.06
# The knock along the wave: one for each ring of squares out from the effect,
# going up a step a ring when counts are raised and down when they are
# lowered.
var effect_sound: String = "stamp_glue"
var effect_sound_volume_db: float = -6.0
var raise_first_pitch: float = 1.1
var lower_first_pitch: float = 0.92
var effect_pitch_step: float = 0.07
var effect_pitch_min: float = 0.6
var effect_pitch_max: float = 1.6

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	canvas_layer = config.get("canvas_layer", canvas_layer)
	render_size = config.get("render_size", render_size)
	vertical_offset = float(config.get("vertical_offset", vertical_offset))
	shadow_color = config.get("shadow_color", shadow_color)
	shadow_blur = float(config.get("shadow_blur", shadow_blur))
	outline_size = int(config.get("outline_size", outline_size))
	bubble_count = int(config.get("bubble_count", bubble_count))

# A piece's own move used a turn of its duration. board_pos must still hold
# the piece (old_duration and new_duration are just numbers to show -- this
# doesn't read the piece itself). Pass -1 for an infinite duration on either
# side.
func play(board_pos: Vector2, old_duration: int, new_duration: int) -> void:
	if !_can_play(board_pos):
		return
	var base_position: Vector2 = _get_base_position(board_pos)
	_knock_off_number(base_position, old_duration)
	_knock_in_number(base_position, new_duration, old_number_rest_duration + tick_knock_delay, tick_drop_distance, tick_drop_scale, tick_drop_duration, tick_landing_squash, tick_settle_duration, tick_hold_duration, tick_fade_out_duration)

# A stamp has just gone onto the piece on board_pos: the duration it brings
# comes down onto it with a knock, holds so it can be read, and goes the way
# every new number does. -1 is an infinite duration.
func play_stamped(board_pos: Vector2, duration: int) -> void:
	if !_can_play(board_pos):
		return
	_knock_in_number(_get_base_position(board_pos), duration, 0.0, stamped_drop_distance, stamped_drop_scale, stamped_drop_duration, stamped_landing_squash, stamped_settle_duration, stamped_hold_duration, new_number_fade_out_duration)

## A stamp gone onto the piece on `board_pos` brought `brought` turns and the
## piece has `final`: its own on_affix effect, which fires once the count is
## set, changed it (War Drummer raises its side's counts, its own among
## them). The count it brought knocks on, then the effect's change follows
## from it. Without one this is play_stamped.
func play_stamped_change(board_pos: Vector2, brought: int, final: int) -> void:
	if !_can_play(board_pos):
		return
	if brought == final or brought < 0 or final < 0:
		play_stamped(board_pos, final)
		return
	_knock_in_number(_get_base_position(board_pos), brought, 0.0, stamped_drop_distance, stamped_drop_scale, stamped_drop_duration, stamped_landing_squash, stamped_settle_duration, move_effect_hold_duration, move_effect_handover_duration)
	var change: Tween = canvas_layer.create_tween()
	change.tween_interval(stamped_drop_duration + stamped_settle_duration + move_effect_hold_duration)
	change.tween_callback(play_effect_change.bind(board_pos, brought, final, 0.0, raise_first_pitch if final > brought else lower_first_pitch))

## Effects raised or lowered these pieces' durations: `changes` are
## {position, old_duration, new_duration}, as
## MatchStateSyncController.collect_state_duration_change_animations gives
## them; `sources` the squares the effects came from (see
## get_duration_effect_sources). The wave runs out from the nearest source;
## with none, every piece answers at once.
func play_effect_changes(changes: Array, sources: Array) -> void:
	var waves: Array[Dictionary] = []
	# The nearest ring each way: its knock is the first heard, at the first pitch.
	var first_ring: Dictionary = {}
	for change_value in changes:
		if !(change_value is Dictionary):
			continue
		var change: Dictionary = change_value
		var board_pos: Vector2 = BoardConfig.value_to_vector2(change.get("position", Vector2(-1, -1)), Vector2(-1, -1))
		if !MoveRules.is_valid_position(board_pos):
			continue
		var old_duration: int = int(change.get("old_duration", 0))
		var new_duration: int = int(change.get("new_duration", 0))
		if old_duration == new_duration:
			continue
		var raised: bool = new_duration > old_duration
		var distance: float = _get_source_distance(board_pos, sources)
		var ring: int = roundi(distance)
		first_ring[raised] = mini(int(first_ring.get(raised, ring)), ring)
		waves.append({
			"position": board_pos,
			"old_duration": old_duration,
			"new_duration": new_duration,
			"raised": raised,
			"distance": distance,
			"ring": ring,
		})

	var sounded: Dictionary = {}
	for wave: Dictionary in waves:
		var raised: bool = wave["raised"]
		var ring: int = wave["ring"]
		var pitch: float = 0.0
		var sound_key: String = "%s:%d" % [raised, ring]
		if !sounded.has(sound_key):
			sounded[sound_key] = true
			var steps: int = ring - int(first_ring.get(raised, ring))
			pitch = raise_first_pitch + effect_pitch_step * steps if raised else lower_first_pitch - effect_pitch_step * steps
			pitch = clampf(pitch, effect_pitch_min, effect_pitch_max)
		play_effect_change(wave["position"], wave["old_duration"], wave["new_duration"], float(wave["distance"]) * effect_wave_step, pitch)

## One piece's count raised or lowered by an effect, `delay` seconds from now.
## `pitch` is its knock's, 0 for none (another piece of its ring sounds it).
## `hold` and `fade` are how long the new number stays and goes, below 0 the
## usual. Returns when, from now, it starts to go.
func play_effect_change(board_pos: Vector2, old_duration: int, new_duration: int, delay: float = 0.0, pitch: float = 0.0, hold: float = -1.0, fade: float = -1.0) -> float:
	if !_can_play(board_pos) or old_duration == new_duration:
		return 0.0
	var hold_duration: float = effect_hold_duration if hold < 0.0 else hold
	var fade_duration: float = new_number_fade_out_duration if fade < 0.0 else fade
	var raised: bool = new_duration > old_duration
	var settled_at: float = old_number_rest_duration + stamped_drop_duration + stamped_settle_duration if raised else old_number_rest_duration + tick_knock_delay + tick_drop_duration + tick_settle_duration
	if delay > 0.0:
		var wait: Tween = canvas_layer.create_tween()
		wait.tween_interval(delay)
		wait.tween_callback(play_effect_change.bind(board_pos, old_duration, new_duration, 0.0, pitch, hold_duration, fade_duration))
		return delay + settled_at + hold_duration

	var base_position: Vector2 = _get_base_position(board_pos)
	if raised:
		_play_raise(board_pos, base_position, old_duration, new_duration, pitch, hold_duration, fade_duration)
	else:
		_play_lower(board_pos, base_position, old_duration, new_duration, pitch, hold_duration, fade_duration)
	return settled_at + hold_duration

## The piece that moved to `board_pos`, its count going from `old_duration` to
## `new_duration`. The move used a turn of it, which is the quiet tick (play);
## anything more came from an effect that fired before the turn was taken
## (the host resolves on_capture and on_move before
## consume_moved_piece_duration), so that plays first, then the tick from the
## number it left. Berserk and Cherry tree give back the turn the move used:
## shown as only the difference, their count ended where it began and nothing
## showed at all. -1 is an infinite duration, which no move uses up.
func play_move_change(board_pos: Vector2, old_duration: int, new_duration: int) -> void:
	if !_can_play(board_pos) or (old_duration < 0 and new_duration < 0):
		return
	if old_duration < 0 or new_duration < 0:
		play_effect_change(board_pos, old_duration, new_duration, 0.0, raise_first_pitch if new_duration < 0 else lower_first_pitch)
		return
	var before_tick: int = new_duration + 1
	if before_tick == old_duration:
		play(board_pos, old_duration, new_duration)
		return
	var tick_at: float = play_effect_change(board_pos, old_duration, before_tick, 0.0, raise_first_pitch if before_tick > old_duration else lower_first_pitch, move_effect_hold_duration, move_effect_handover_duration)
	var tick: Tween = canvas_layer.create_tween()
	tick.tween_interval(tick_at)
	tick.tween_callback(play.bind(board_pos, before_tick, new_duration))

## The squares the duration effects among `activations` (a state's
## recent_effect_activations) came from.
func get_duration_effect_sources(activations: Array) -> Array:
	var sources: Array = []
	for activation_value in activations:
		if !(activation_value is Dictionary):
			continue
		var activation: Dictionary = activation_value
		var stamp: Stamp = StampLibrary.get_stamp(str(activation.get("stamp_name", "")))
		if stamp == null or !DURATION_EFFECT_TYPES.has(stamp.effect_type):
			continue
		var source_pos: Vector2 = BoardConfig.value_to_vector2(activation.get("source_pos", Vector2(-1, -1)), Vector2(-1, -1))
		if MoveRules.is_valid_position(source_pos) and !sources.has(source_pos):
			sources.append(source_pos)
	return sources

func _can_play(board_pos: Vector2) -> bool:
	if match_board == null or canvas_layer == null or !is_instance_valid(canvas_layer):
		return false
	return MoveRules.is_valid_position(board_pos)

func _get_base_position(board_pos: Vector2) -> Vector2:
	var screen_position: Vector2 = match_board.get_board_position_screen_position(board_pos)
	return screen_position + Vector2(-render_size.x * 0.5, vertical_offset)

func _get_source_distance(board_pos: Vector2, sources: Array) -> float:
	var nearest: float = -1.0
	for source_value in sources:
		var distance: float = board_pos.distance_to(BoardConfig.value_to_vector2(source_value, board_pos))
		if nearest < 0.0 or distance < nearest:
			nearest = distance
	return maxf(nearest, 0.0)

# Raised: the old number shows, the new one knocks down onto it and flattens
# it, and as it lands the piece gives and springs up, the ink runs out and the
# knock sounds.
func _play_raise(board_pos: Vector2, base_position: Vector2, old_duration: int, new_duration: int, pitch: float, hold_duration: float, fade_duration: float) -> void:
	_flatten_number(base_position, old_duration, old_number_rest_duration + stamped_drop_duration)
	var landed := func() -> void:
		_squash_piece(board_pos, [
			[raise_press_squash, raise_press_duration, Tween.EASE_OUT, Tween.TRANS_QUAD],
			[raise_pop_stretch, raise_pop_duration, Tween.EASE_OUT, Tween.TRANS_QUAD],
			[Vector2.ONE, raise_settle_duration, Tween.EASE_OUT, Tween.TRANS_BACK],
		])
		_play_ink_ring(board_pos, false)
		if pitch > 0.0:
			SFXManager.play_pitched(effect_sound, pitch, effect_sound_volume_db)
	_knock_in_number(base_position, new_duration, old_number_rest_duration, stamped_drop_distance, stamped_drop_scale, stamped_drop_duration, stamped_landing_squash, stamped_settle_duration, hold_duration, fade_duration, landed)

# Lowered: the old number shows, then the piece is pressed down, the number is
# knocked off it, the ink is drawn back in and the knock sounds; the new
# number comes in small after it.
func _play_lower(board_pos: Vector2, base_position: Vector2, old_duration: int, new_duration: int, pitch: float, hold_duration: float, fade_duration: float) -> void:
	_knock_off_number(base_position, old_duration)
	var knocked := func() -> void:
		_squash_piece(board_pos, [
			[lower_press_squash, lower_press_duration, Tween.EASE_OUT, Tween.TRANS_QUAD],
			[lower_press_squash, lower_press_hold, Tween.EASE_IN_OUT, Tween.TRANS_LINEAR],
			[Vector2.ONE, lower_release_duration, Tween.EASE_IN_OUT, Tween.TRANS_SINE],
		])
		_play_ink_ring(board_pos, true)
		if pitch > 0.0:
			SFXManager.play_pitched(effect_sound, pitch, effect_sound_volume_db)
	var knock: Tween = canvas_layer.create_tween()
	knock.tween_interval(old_number_rest_duration)
	knock.tween_callback(knocked)
	_knock_in_number(base_position, new_duration, old_number_rest_duration + tick_knock_delay, tick_drop_distance, tick_drop_scale, tick_drop_duration, tick_landing_squash, tick_settle_duration, hold_duration, fade_duration)

func _play_ink_ring(board_pos: Vector2, inward: bool) -> void:
	var holder: Sprite2D = match_board.get_piece_holder_at(board_pos)
	if holder == null or !is_instance_valid(holder) or holder.texture == null:
		return
	match_board.get_piece_shatter_animator().play_ink_ring(board_pos, holder.texture, effect_ink_ring_radius, inward)

## The piece on board_pos squashed through `steps`, each [squash, seconds,
## ease, trans], about its feet. On the holder, so a redraw of the board
## stops it.
func _squash_piece(board_pos: Vector2, steps: Array) -> void:
	var holder: Sprite2D = match_board.get_piece_holder_at(board_pos)
	if holder == null or !is_instance_valid(holder) or holder.texture == null:
		return
	var rest: Dictionary = holder.get_meta(SQUASH_META, {})
	if rest.is_empty():
		rest = {"scale": holder.scale, "position": holder.position}
	else:
		var running = rest.get("tween", null)
		if running is Tween and running.is_valid():
			running.kill()
	var base_scale: Vector2 = rest["scale"]
	var base_position: Vector2 = rest["position"]

	var from: Vector2 = Vector2(
		holder.scale.x / base_scale.x if absf(base_scale.x) > 0.0001 else 1.0,
		holder.scale.y / base_scale.y if absf(base_scale.y) > 0.0001 else 1.0
	)
	var tween: Tween = holder.create_tween()
	for step: Array in steps:
		var squash_from: Vector2 = from
		var squash_to: Vector2 = step[0]
		tween.tween_method(func(progress: float): PieceMoveAnimator.set_squash(holder, base_scale, base_position, squash_from.lerp(squash_to, progress)), 0.0, 1.0, float(step[1])).set_ease(step[2]).set_trans(step[3])
		from = squash_to
	tween.tween_callback(func():
		if is_instance_valid(holder):
			holder.remove_meta(SQUASH_META)
	)
	rest["tween"] = tween
	holder.set_meta(SQUASH_META, rest)

func _format_duration_text(duration: int) -> String:
	return "INF" if duration < 0 else str(duration)

func _build_number_instance(text: String) -> Dictionary:
	var viewport := SubViewport.new()
	canvas_layer.add_child(viewport)
	viewport.size = Vector2i(render_size)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true

	var label := Label.new()
	viewport.add_child(label)
	label.visible = true
	label.text = text
	label.size = render_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var label_settings := LabelSettings.new()
	label_settings.font = DURATION_LABEL_FONT
	label_settings.font_size = 22
	label_settings.font_color = Color(1.0, 1.0, 1.0)
	label_settings.outline_size = outline_size
	label_settings.outline_color = Color(shadow_color.r, shadow_color.g, shadow_color.b, 1.0)
	label.label_settings = label_settings

	var display := TextureRect.new()
	canvas_layer.add_child(display)
	display.size = render_size
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	display.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.z_index = 901
	display.texture = viewport.get_texture()

	var display_material := ShaderMaterial.new()
	display_material.shader = SOFT_DROP_SHADOW_SHADER
	display_material.set_shader_parameter("shadow_color", shadow_color)
	display_material.set_shader_parameter("blur_std", shadow_blur)
	display_material.set_shader_parameter("control_rect_size", render_size)
	display.material = display_material

	return {"viewport": viewport, "label": label, "display": display}

func _free_number_instance(instance: Dictionary) -> void:
	var viewport: SubViewport = instance.get("viewport") as SubViewport
	var display: TextureRect = instance.get("display") as TextureRect
	if display != null and is_instance_valid(display):
		display.queue_free()
	if viewport != null and is_instance_valid(viewport):
		viewport.queue_free()

# The outgoing value, knocked off: it shows at rest, jumps a little, and falls
# away tilting to one side while it fades.
func _knock_off_number(base_position: Vector2, old_duration: int) -> void:
	var instance: Dictionary = _build_number_instance(_format_duration_text(old_duration))
	var display: TextureRect = instance["display"]
	display.pivot_offset = render_size * 0.5
	display.global_position = base_position
	display.modulate.a = 0.0
	var side: float = 1.0 if randf() < 0.5 else -1.0

	var tween: Tween = display.create_tween()
	tween.tween_property(display, "modulate:a", 1.0, old_number_fade_in_duration)
	tween.tween_interval(maxf(old_number_rest_duration - old_number_fade_in_duration, 0.0))
	tween.tween_property(display, "position:y", base_position.y - old_number_knock_up_distance, old_number_knock_up_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(display, "position:y", base_position.y + old_number_fall_distance, old_number_fall_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(display, "position:x", base_position.x + side * old_number_fall_drift, old_number_fall_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(display, "rotation", side * old_number_fall_tilt, old_number_fall_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(display, "modulate:a", 0.0, old_number_fall_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(Callable(self, "_free_number_instance").bind(instance))

# The outgoing value, stamped over: it shows at rest until `flatten_at`, when
# the new one lands on it, and is pressed flat and gone.
func _flatten_number(base_position: Vector2, old_duration: int, flatten_at: float) -> void:
	var instance: Dictionary = _build_number_instance(_format_duration_text(old_duration))
	var display: TextureRect = instance["display"]
	display.pivot_offset = Vector2(render_size.x * 0.5, render_size.y * 0.75)
	display.global_position = base_position
	display.modulate.a = 0.0

	var tween: Tween = display.create_tween()
	tween.tween_property(display, "modulate:a", 1.0, old_number_fade_in_duration)
	tween.tween_interval(maxf(flatten_at - old_number_fade_in_duration, 0.0))
	tween.tween_property(display, "scale", old_number_flatten_scale, old_number_flatten_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(display, "modulate:a", 0.0, old_number_flatten_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(Callable(self, "_free_number_instance").bind(instance))

# The incoming value, knocked in after `delay`: it comes down `drop_distance`
# from above at `drop_scale`, lands squashed on its bottom edge (`landed` is
# called then, and its bubbles burst out), springs back, holds so it can be
# read, then rises a little and fades.
func _knock_in_number(base_position: Vector2, new_duration: int, delay: float, drop_distance: float, drop_scale: float, drop_duration: float, landing_squash: Vector2, settle_duration: float, hold_duration: float, fade_out_duration: float, landed: Callable = Callable()) -> void:
	var instance: Dictionary = _build_number_instance(_format_duration_text(new_duration))
	var display: TextureRect = instance["display"]
	display.pivot_offset = Vector2(render_size.x * 0.5, render_size.y * 0.75)
	display.global_position = base_position - Vector2(0.0, drop_distance)
	display.scale = Vector2.ONE * drop_scale
	display.modulate.a = 0.0

	var tween: Tween = display.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(display, "position:y", base_position.y, drop_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(display, "scale", landing_squash, drop_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(display, "modulate:a", 1.0, drop_duration * 0.5)
	tween.tween_callback(func():
		for i in bubble_count:
			_spawn_bubble(base_position)
		if landed.is_valid():
			landed.call()
	)
	tween.tween_property(display, "scale", Vector2.ONE, settle_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(hold_duration)
	tween.tween_property(display, "position:y", base_position.y - new_number_fade_out_rise_distance, fade_out_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(display, "modulate:a", 0.0, fade_out_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(Callable(self, "_free_number_instance").bind(instance))

# Same look and per-bubble lifecycle as StampHoverPreviewController's hover
# bubbles (see that file for why each piece here -- the shader choice, the
# three-phase appear/drift/fade timing -- is the way it is); the only
# difference is that here all of them pop at once, as the new number lands,
# instead of building up gradually over a held hover.
func _spawn_bubble(base_position: Vector2) -> void:
	var bubble := TextureRect.new()
	canvas_layer.add_child(bubble)
	bubble.texture = DURATION_BUBBLE_TEXTURE
	bubble.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bubble.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bubble.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.z_index = 900

	var diameter: float = bubble_reference_size * randf_range(bubble_min_size_ratio, bubble_max_size_ratio)
	bubble.size = Vector2.ONE * diameter
	bubble.pivot_offset = bubble.size * 0.5

	var bubble_material := ShaderMaterial.new()
	bubble_material.shader = DURATION_BUBBLE_SHADER
	bubble_material.set_shader_parameter("color", shadow_color)
	bubble_material.set_shader_parameter("edge_softness", bubble_edge_softness)
	bubble_material.set_shader_parameter("glow_strength", bubble_glow_strength)
	bubble_material.set_shader_parameter("pulse_strength", 0.0)
	bubble.material = bubble_material

	var display_center: Vector2 = base_position + render_size * 0.5
	var angle: float = randf_range(0.0, TAU)
	var dist: float = randf_range(0.0, bubble_spawn_radius)
	bubble.global_position = display_center + Vector2(cos(angle), sin(angle)) * dist - bubble.size * 0.5

	bubble.scale = Vector2.ZERO
	bubble.modulate.a = 0.0
	var base_y: float = bubble.position.y

	var tween: Tween = bubble.create_tween()
	tween.tween_property(bubble, "scale", Vector2.ONE, bubble_pop_in_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(bubble, "modulate:a", 1.0, bubble_pop_in_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(bubble, "position:y", base_y - bubble_drift_rise_distance, bubble_drift_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(bubble, "position:y", base_y - bubble_drift_rise_distance - bubble_fade_rise_distance, bubble_fade_out_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(bubble, "modulate:a", 0.0, bubble_fade_out_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(Callable(bubble, "queue_free"))
