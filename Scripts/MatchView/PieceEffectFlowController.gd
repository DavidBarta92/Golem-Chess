extends RefCounted

const CaptureFeelLayer = preload("res://Scripts/MatchView/CaptureFeelLayer.gd")
const PIECE_HIT_REACTION_SHADER = preload("res://Shaders/piece_hit_reaction.gdshader")
## How far the struck piece's flash has faded back toward its drawing by the
## time it breaks.
const CAPTURE_HIT_FLASH_END_AMOUNT: float = 0.35
## The share of the hitstop the cracks take to run across the struck piece.
const CAPTURE_HIT_CRACK_SHARE: float = 0.6
## How far the struck piece is jolted along the blow during the hitstop, in
## board units (a square is `BoardConfig.CELL_WIDTH`).
const CAPTURE_HIT_JOLT_DISTANCE: float = 0.8

# How a capture lands on the player, by whose piece it was. One of theirs
# striking: quick, warm and bright. One of theirs struck: a longer hold, a
# heavier and slower jolt of the board, a colder light, a lower sound, and a
# wash up from their own side. A transparent light means the board's own
# `capture_sparkle_color`. Jolts are in screen pixels.
const CAPTURE_STRIKE_FEEL: Dictionary = {
	"hitstop_scale": 1.0,
	"light": Color(0.0, 0.0, 0.0, 0.0),
	"pitch_min": 1.05,
	"pitch_max": 1.12,
	"volume_db": 0.0,
	"jolt_distance": 3.5,
	"jolt_duration": 0.22,
	"jolt_swings": 2.5,
}
const CAPTURE_LOSS_FEEL: Dictionary = {
	"hitstop_scale": 1.3,
	"light": Color(0.78, 0.86, 1.0, 1.0),
	"pitch_min": 0.78,
	"pitch_max": 0.84,
	"volume_db": 1.5,
	"jolt_distance": 5.5,
	"jolt_duration": 0.42,
	"jolt_swings": 2.0,
}
const CAPTURE_LOSS_WASH_COLOR: Color = Color(0.55, 0.12, 0.1, 0.3)
const CAPTURE_LOSS_WASH_RISE_DURATION: float = 0.07
const CAPTURE_LOSS_WASH_FADE_DURATION: float = 0.65
## How far the CRT pass's colour fringes swing either way while the board
## jolts under one of the player's own pieces breaking.
const CAPTURE_LOSS_ABERRATION: float = 0.01

var match_board
var invalid_board_pos: Vector2 = Vector2(-1, -1)
var capture_feel_layer: CaptureFeelLayer

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)

func play_state_affix_animations(animations: Array[Dictionary]) -> void:
	if match_board == null:
		return

	match_board.begin_visual_process(match_board.VISUAL_PROCESS_STATE_STAMP_AFFIX)
	for animation: Dictionary in animations:
		var board_pos: Vector2 = match_board.value_to_vector2(animation.get("position", invalid_board_pos), invalid_board_pos)
		var stamp: Stamp = animation.get("stamp", null) as Stamp
		var start_texture: Texture2D = animation.get("start_texture", null) as Texture2D
		var hide_after_affix: bool = bool(animation.get("hide_after_affix", false))
		if !match_board.is_valid_position(board_pos) or stamp == null:
			match_board.finish_stamp_affix_process(board_pos)
			continue

		if hide_after_affix:
			var piece_color: int = int(animation.get("piece_color", 0))
			if piece_color == 0:
				piece_color = match_board.get_color_for_player_id(1 - match_board.get_own_player_id())
			await play_hidden_piece_invisibility_affix_animation(board_pos, stamp, start_texture, piece_color)
		else:
			await play_piece_stamp_affix_animation(board_pos, stamp, start_texture)
		match_board.finish_stamp_affix_process(board_pos)
	match_board.finish_visual_process(match_board.VISUAL_PROCESS_STATE_STAMP_AFFIX)

func play_piece_stamp_affix_animation(piece_position: Vector2, stamp: Stamp, start_texture: Texture2D = null) -> void:
	if match_board == null or match_board.should_skip_visual_animations() or !match_board.is_inside_tree():
		return
	if stamp == null or !match_board.piece_objects.has(piece_position):
		return

	var piece: Piece = match_board.piece_objects[piece_position] as Piece
	if piece == null:
		return

	var affixed_texture: Texture2D = match_board.get_piece_texture_resolver().get_stamp_piece_texture_for_color(stamp, piece.color)
	if affixed_texture == null:
		return

	var holder: Sprite2D = match_board.get_piece_holder_at(piece_position)
	if holder == null or holder.texture == null:
		return

	if start_texture != null and holder.texture != start_texture:
		holder.texture = start_texture
		match_board.refresh_piece_holder_visual(holder, piece_position)

	SFXManager.play("attach_stamp")
	var reveal_visual: StampVisual = match_board.get_stamp_animation_controller().play_stamp_affix_reveal(stamp, piece.color)
	await match_board.get_piece_effect_animator().play_affix_sequence(holder, piece_position, affixed_texture, {
		"post_morph_callback": Callable(self, "apply_visible_piece_attach_morph_result").bind(piece_position, affixed_texture),
		"disable_holder_occluder": true,
	})
	match_board.get_stamp_animation_controller().finish_stamp_affix_reveal(reveal_visual)

func apply_visible_piece_attach_morph_result(holder: Sprite2D, piece_position: Vector2, affixed_texture: Texture2D) -> void:
	if match_board == null or holder == null or !is_instance_valid(holder):
		return

	holder.texture = affixed_texture
	match_board.refresh_piece_holder_visual(holder, piece_position)

func play_hidden_piece_invisibility_affix_animation(piece_position: Vector2, stamp: Stamp, start_texture: Texture2D, piece_color: int) -> void:
	if match_board == null or match_board.should_skip_visual_animations() or !match_board.is_inside_tree():
		return
	if stamp == null or !match_board.is_valid_position(piece_position):
		return
	if start_texture == null:
		start_texture = match_board.get_piece_texture_resolver().get_default_piece_texture(piece_color)
	if start_texture == null:
		return

	var holder: Sprite2D = create_hidden_invisibility_animation_holder(piece_position, start_texture)
	if holder == null:
		return

	var affixed_texture: Texture2D = match_board.get_piece_texture_resolver().get_stamp_piece_texture_for_color(stamp, piece_color)
	if affixed_texture == null:
		affixed_texture = start_texture

	SFXManager.play("attach_stamp")
	var completed: bool = await match_board.get_piece_effect_animator().play_affix_sequence(holder, piece_position, affixed_texture, {
		"post_morph_callback": Callable(self, "apply_hidden_piece_attach_morph_result").bind(piece_position, affixed_texture),
		"disable_holder_occluder": false,
	})
	if !completed:
		return

	SFXManager.play("invisibility_effect")
	await match_board.get_piece_effect_animator().play_invisibility_exit(holder)

func apply_hidden_piece_attach_morph_result(holder: Sprite2D, piece_position: Vector2, affixed_texture: Texture2D) -> void:
	if match_board == null or holder == null or !is_instance_valid(holder):
		return

	holder.texture = affixed_texture
	match_board.get_piece_visuals().apply_visual_size(holder, piece_position)

func play_local_move_transition(move_context: Dictionary) -> void:
	if match_board == null:
		return

	var start_pos: Vector2 = move_context.get("start_pos", invalid_board_pos)
	var end_pos: Vector2 = move_context.get("end_pos", invalid_board_pos)
	var moving_start_texture: Texture2D = move_context.get("moving_start_texture", null) as Texture2D
	var moving_piece_visible_to_enemy: bool = bool(move_context.get("moving_piece_visible_to_enemy", true))
	var should_play_capture_shatter: bool = bool(move_context.get("should_play_capture_shatter", false))
	var captured_start_texture: Texture2D = move_context.get("captured_start_texture", null) as Texture2D

	match_board.display_board()
	var capture_placeholder: Sprite2D = create_piece_move_capture_placeholder(end_pos, captured_start_texture) if should_play_capture_shatter else null
	var capture_impact_callback: Callable = Callable()
	if should_play_capture_shatter:
		var captured_piece: Piece = move_context.get("captured_piece", null) as Piece
		var captured_color: int = captured_piece.color if captured_piece != null else 0
		var shatter_respawn_pos: Vector2 = match_board.value_to_vector2(move_context.get("shatter_respawn_pos", invalid_board_pos), invalid_board_pos)
		var shatter_fragment_group: String = str(move_context.get("shatter_fragment_group", match_board.PIECE_SHATTER_FRAGMENT_GROUP_NONE))
		var capturing_cast: String = get_capturing_cast_sound_name(end_pos)
		capture_impact_callback = func() -> float:
			return play_capture_contact(captured_color, start_pos, end_pos, capturing_cast, capture_placeholder, func() -> void:
				match_board.get_piece_respawn_fragment_coordinator().play_capture_shatter_animation(end_pos, shatter_respawn_pos, captured_color, shatter_fragment_group, captured_start_texture, end_pos - start_pos)
			)
	await play_piece_move_animation(start_pos, end_pos, moving_start_texture, moving_piece_visible_to_enemy, capture_impact_callback)
	if is_instance_valid(capture_placeholder):
		capture_placeholder.queue_free()
	var pending_respawn_arrivals: Array = move_context.get("pending_respawn_arrivals", [])
	if !pending_respawn_arrivals.is_empty():
		match_board.get_piece_respawn_fragment_coordinator().play_pending_edge_respawn_arrival_animations(pending_respawn_arrivals)
	match_board.call_deferred("play_pending_piece_revert_animations")

func play_state_piece_move_animation(state_piece_move_animation: Dictionary, state_piece_shatter_animations: Array) -> void:
	if match_board == null:
		return

	var move_to_pos: Vector2 = match_board.value_to_vector2(state_piece_move_animation.get("to", invalid_board_pos), invalid_board_pos)
	var move_from_pos: Vector2 = match_board.value_to_vector2(state_piece_move_animation.get("from", invalid_board_pos), invalid_board_pos)
	var move_piece_color: int = int(state_piece_move_animation.get("piece_color", 0))
	var captured_texture: Texture2D = state_piece_move_animation.get("captured_texture", null) as Texture2D
	var capture_placeholder: Sprite2D = create_piece_move_capture_placeholder(move_to_pos, captured_texture)
	if capture_placeholder != null and bool(state_piece_move_animation.get("captured_reveal_from_invisibility", false)):
		play_capture_invisibility_reveal(capture_placeholder)

	var capture_shatter_animation_index: int = get_piece_shatter_animation_index_for_source(state_piece_shatter_animations, move_to_pos) if capture_placeholder != null else -1
	var capture_shatter_animation: Dictionary = state_piece_shatter_animations[capture_shatter_animation_index] if capture_shatter_animation_index >= 0 else {}
	var capture_impact_callback: Callable = Callable()
	if capture_placeholder != null:
		var capturing_cast: String = get_capturing_cast_sound_name(move_to_pos)
		capture_impact_callback = func() -> float:
			var captured_color: int = 0
			var break_callback: Callable = Callable()
			if !capture_shatter_animation.is_empty():
				# Taken off the list at contact, so the shatter still to come
				# after the hitstop is not played a second time with the rest.
				remove_piece_shatter_animation_from_list(state_piece_shatter_animations, capture_shatter_animation, capture_shatter_animation_index)
				captured_color = int(capture_shatter_animation.get("piece_color", 0))
				break_callback = func() -> void:
					match_board.get_piece_respawn_fragment_coordinator().play_capture_shatter_animation(
						move_to_pos,
						match_board.value_to_vector2(capture_shatter_animation.get("respawn_pos", invalid_board_pos), invalid_board_pos),
						captured_color,
						str(capture_shatter_animation.get("fragment_group", match_board.PIECE_SHATTER_FRAGMENT_GROUP_NONE)),
						captured_texture,
						move_to_pos - move_from_pos
					)
			return play_capture_contact(captured_color, move_from_pos, move_to_pos, capturing_cast, capture_placeholder, break_callback)

	var move_start_texture: Texture2D = state_piece_move_animation.get("start_texture", null) as Texture2D
	var hide_after_move: bool = bool(state_piece_move_animation.get("hide_after_move", false))
	await play_piece_move_animation(
		move_from_pos,
		move_to_pos,
		move_start_texture,
		bool(state_piece_move_animation.get("visible_to_enemy", true)),
		capture_impact_callback,
		hide_after_move
	)
	if is_instance_valid(capture_placeholder):
		capture_placeholder.queue_free()
	if move_piece_color != 0:
		match_board.piece_moved.emit(move_from_pos, move_to_pos, move_piece_color)
	# Taken first, gone from sight after: the piece that struck stays in view
	# where it landed just long enough to go out of it.
	if hide_after_move:
		await play_hidden_piece_vanish(move_to_pos, move_start_texture)

	# A stamp that expired as part of this move (turns_remaining hit 0) gets
	# its own expire animation elsewhere instead -- only a genuine decrement
	# that the piece is still carrying afterward gets this one, same as the
	# local-move path in LocalMoveFlowController.consume_moved_piece_duration_locally().
	if state_piece_move_animation.has("old_duration"):
		var old_duration: int = int(state_piece_move_animation.get("old_duration", 0))
		var new_duration: int = int(state_piece_move_animation.get("new_duration", 0))
		if old_duration != new_duration:
			var moved_piece: Piece = match_board.piece_objects.get(move_to_pos, null) as Piece
			if moved_piece != null and moved_piece.affixed_stamp != null:
				match_board.play_duration_change_animation(move_to_pos, old_duration, new_duration)

func should_play_piece_move_animation(from_pos: Vector2, to_pos: Vector2, visible_to_enemy: bool = true) -> bool:
	if match_board == null:
		return false
	if !match_board.piece_move_animation_enabled or match_board.should_skip_visual_animations() or !match_board.is_inside_tree():
		return false
	if !match_board.is_valid_position(from_pos) or !match_board.is_valid_position(to_pos):
		return false
	return from_pos != to_pos

## `hidden_at_end` is for a piece the viewer cannot see once it lands: its
## square's holder has nothing to draw, so the move is drawn with
## `start_texture` and the holder is left empty again when it is over.
func play_piece_move_animation(
	from_pos: Vector2,
	to_pos: Vector2,
	start_texture: Texture2D = null,
	visible_to_enemy: bool = true,
	capture_impact_callback: Callable = Callable(),
	hidden_at_end: bool = false
) -> void:
	if !should_play_piece_move_animation(from_pos, to_pos, visible_to_enemy):
		return

	var holder: Sprite2D = match_board.get_piece_holder_at(to_pos)
	if holder == null or !is_instance_valid(holder):
		return
	if holder.texture == null and !(hidden_at_end and start_texture != null):
		return

	match_board.begin_visual_process(match_board.VISUAL_PROCESS_PIECE_MOVE)
	# Whatever the last blow left lying about soaks away as the next move begins.
	match_board.get_piece_shatter_animator().soak_away_debris()
	var end_texture: Texture2D = holder.texture
	var display_texture: Texture2D = start_texture if start_texture != null else end_texture
	# It is `display_texture` that is drawn the whole way, so the move is sized
	# by that drawing at both ends. Sized by the square's drawing instead - the
	# golem, for a piece whose stamp ran out with this move - a stamped piece
	# shrank and lifted off on the way, the golem's canvas being far larger.
	# Once it lands the square's drawing takes over and the revert burns the
	# old one away.
	var start_transform: Dictionary = match_board.get_piece_visuals().get_visual_transform_for_texture(display_texture, from_pos)
	var end_transform: Dictionary = match_board.get_piece_visuals().get_visual_transform_for_texture(display_texture, to_pos)
	var start_scale: Vector2 = start_transform.get("scale", holder.scale)
	var end_scale: Vector2 = end_transform.get("scale", holder.scale)
	var start_offset: Vector2 = start_transform.get("offset", holder.offset)
	var end_offset: Vector2 = end_transform.get("offset", holder.offset)

	holder.texture = display_texture
	holder.position = match_board.get_board_position_local_position(from_pos)
	holder.scale = start_scale
	holder.offset = start_offset
	match_board.get_piece_visuals().remove_shadow(holder)
	match_board.get_piece_visuals().remove_light_occluder(holder)
	SFXManager.play("piece_lifted")
	var landed_callback: Callable = func() -> void:
		SFXManager.play("piece_placed")
	await match_board.get_piece_move_animator().play_move_sequence(
		holder,
		from_pos,
		to_pos,
		start_scale,
		end_scale,
		start_offset,
		end_offset,
		capture_impact_callback,
		landed_callback
	)

	if is_instance_valid(holder):
		holder.texture = end_texture
		match_board.refresh_piece_holder_visual(holder, to_pos)
	match_board.finish_visual_process(match_board.VISUAL_PROCESS_PIECE_MOVE)

func create_piece_move_capture_placeholder(board_pos: Vector2, texture_value: Texture2D) -> Sprite2D:
	if match_board == null or texture_value == null or !match_board.is_valid_position(board_pos):
		return null

	var placeholder: Sprite2D = create_piece_effect_holder(board_pos, texture_value, "PieceMoveCaptureTarget")
	if placeholder == null:
		return null
	placeholder.z_index = match_board.pieces_node.z_index + match_board.get_piece_visuals().get_depth_z_index(board_pos)
	return placeholder

## The moment of contact, for both kinds of capture: the sparkle and the
## sounds, the board's jolt and the struck piece's hit reaction, each as
## `CAPTURE_STRIKE_FEEL` or `CAPTURE_LOSS_FEEL` has it for the player
## watching. `captured_color` is 0 when it is not known, which gets the
## sounds and the hit but no sparkle. Answers the hitstop, for
## `PieceMoveAnimator` to hold the striker still that long.
func play_capture_contact(captured_color: int, from_pos: Vector2, to_pos: Vector2, capturing_cast: String, capture_placeholder: Sprite2D, break_callback: Callable) -> float:
	var own_loss: bool = captured_color != 0 and captured_color == match_board.get_own_color()
	var feel: Dictionary = CAPTURE_LOSS_FEEL if own_loss else CAPTURE_STRIKE_FEEL
	var light: Color = feel.light if feel.light.a > 0.0 else match_board.capture_sparkle_color
	# Shaking and flashing are for those who have not turned them off.
	var calm: bool = !SettingsDataManager.is_screen_shake_enabled()
	var blow: Vector2 = (match_board.get_board_position_local_position(to_pos) - match_board.get_board_position_local_position(from_pos)).normalized()

	if captured_color != 0:
		match_board.get_piece_respawn_fragment_coordinator().play_capture_impact_effects(to_pos, light)
	if !capturing_cast.is_empty():
		SFXManager.play(capturing_cast)
	SFXManager.play_pitched("piece_captured", randf_range(feel.pitch_min, feel.pitch_max), feel.volume_db)

	if !calm:
		var camera: MatchCamera = match_board.get_viewport().get_camera_2d() as MatchCamera
		if camera != null:
			camera.jolt(blow, feel.jolt_distance, feel.jolt_duration, feel.jolt_swings)
		if own_loss:
			get_capture_feel_layer().wash_from_own_side(CAPTURE_LOSS_WASH_COLOR, CAPTURE_LOSS_WASH_RISE_DURATION, CAPTURE_LOSS_WASH_FADE_DURATION)
			SettingsDataManager.wobble_crt_aberration(CAPTURE_LOSS_ABERRATION, feel.jolt_duration, feel.jolt_swings)

	var hitstop_duration: float = match_board.piece_move_capture_hitstop_duration * feel.hitstop_scale
	play_capture_hit_reaction(capture_placeholder, blow, break_callback, hitstop_duration, light, calm)
	return hitstop_duration

func get_capture_feel_layer() -> CaptureFeelLayer:
	if capture_feel_layer == null or !is_instance_valid(capture_feel_layer):
		capture_feel_layer = CaptureFeelLayer.new()
		match_board.add_child(capture_feel_layer)
	return capture_feel_layer

## The struck piece through the hitstop the striker holds at contact: lit up
## in `light`, cracking and jolted along the blow, then gone, and
## `break_callback` shatters it. A `calm` hit cracks without the flash.
func play_capture_hit_reaction(capture_placeholder: Sprite2D, blow: Vector2, break_callback: Callable, hitstop_duration: float, light: Color, calm: bool) -> void:
	var finish: Callable = func() -> void:
		if is_instance_valid(capture_placeholder):
			capture_placeholder.queue_free()
		if break_callback.is_valid():
			break_callback.call()

	if hitstop_duration <= 0.0 or !match_board.is_inside_tree():
		finish.call()
		return

	var tween: Tween = match_board.create_tween()
	tween.tween_interval(hitstop_duration)
	if is_instance_valid(capture_placeholder):
		# A placeholder still carrying the invisibility reveal's material is
		# left as it is rather than having that animation cut short.
		if capture_placeholder.material == null and capture_placeholder.texture != null:
			var hit_material: ShaderMaterial = create_capture_hit_material(capture_placeholder, blow, light, 0.0 if calm else 1.0)
			capture_placeholder.material = hit_material
			if !calm:
				tween.parallel().tween_property(hit_material, "shader_parameter/flash_amount", CAPTURE_HIT_FLASH_END_AMOUNT, hitstop_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
			tween.parallel().tween_property(hit_material, "shader_parameter/crack_reach", capture_placeholder.texture.get_size().length(), hitstop_duration * CAPTURE_HIT_CRACK_SHARE).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

		var rest_position: Vector2 = capture_placeholder.position
		tween.parallel().tween_method(func(progress: float): update_capture_hit_jolt(capture_placeholder, rest_position, blow, progress), 0.0, 1.0, hitstop_duration)
	tween.tween_callback(finish)

## The struck piece lit up, with cracks ready to run along the lines it will
## break on (`PieceShatterAnimator.get_fragment_crack_segments()`), starting
## on the side the blow came from.
func create_capture_hit_material(capture_placeholder: Sprite2D, blow: Vector2, light: Color, flash_amount: float) -> ShaderMaterial:
	var texture_value: Texture2D = capture_placeholder.texture
	var shatter_animator = match_board.get_piece_shatter_animator()
	var used_rect: Rect2 = shatter_animator.get_texture_shape(texture_value).get("used_rect", Rect2(Vector2.ZERO, texture_value.get_size()))
	var crack_segments: PackedVector4Array = shatter_animator.get_fragment_crack_segments(texture_value)
	# The blow as it falls on the drawing, which is turned round with the
	# camera for the second player.
	var blow_on_drawing: Vector2 = blow.rotated(-capture_placeholder.rotation)
	var crack_origin: Vector2 = used_rect.get_center() + Vector2(-blow_on_drawing.x * used_rect.size.x * 0.3, -used_rect.size.y * 0.08)

	var hit_material := ShaderMaterial.new()
	hit_material.shader = PIECE_HIT_REACTION_SHADER
	hit_material.set_shader_parameter("flash_color", light)
	hit_material.set_shader_parameter("flash_amount", flash_amount)
	hit_material.set_shader_parameter("crack_segments", crack_segments)
	hit_material.set_shader_parameter("crack_segment_count", crack_segments.size())
	hit_material.set_shader_parameter("crack_origin", crack_origin)
	hit_material.set_shader_parameter("crack_reach", 0.0)
	return hit_material

func update_capture_hit_jolt(capture_placeholder: Sprite2D, rest_position: Vector2, blow: Vector2, progress: float) -> void:
	if !is_instance_valid(capture_placeholder):
		return
	capture_placeholder.position = rest_position + blow * CAPTURE_HIT_JOLT_DISTANCE * sin(progress * PI * 3.0) * (1.0 - progress)

## A piece the viewer cannot see, going out of sight where it stands: the
## same shimmer and fade as one hidden by a fresh stamp, played on a stand-in
## because the square's own holder has nothing to draw.
func play_hidden_piece_vanish(piece_position: Vector2, texture_value: Texture2D) -> void:
	if match_board == null or match_board.should_skip_visual_animations() or !match_board.is_inside_tree():
		return
	var stand_in: Sprite2D = create_hidden_invisibility_animation_holder(piece_position, texture_value)
	if stand_in == null:
		return
	SFXManager.play("invisibility_effect")
	await match_board.get_piece_effect_animator().play_invisibility_exit(stand_in)

func play_capture_invisibility_reveal(capture_placeholder: Sprite2D) -> void:
	if match_board != null:
		match_board.get_piece_effect_animator().play_invisibility_reveal(capture_placeholder)

func create_hidden_invisibility_animation_holder(piece_position: Vector2, start_texture: Texture2D) -> Sprite2D:
	return create_piece_effect_holder(piece_position, start_texture, "HiddenInvisibilityPiece")

func create_piece_effect_holder(piece_position: Vector2, texture_value: Texture2D, holder_name: String = "PieceEffect") -> Sprite2D:
	if match_board == null or texture_value == null or !match_board.is_valid_position(piece_position):
		return null
	if match_board.piece_effects_node == null or !is_instance_valid(match_board.piece_effects_node):
		match_board.create_piece_effects_node()
	if match_board.piece_effects_node == null:
		return null
	return match_board.get_piece_effect_animator().create_effect_holder(piece_position, texture_value, holder_name)

func get_piece_shatter_animation_index_for_source(animations: Array, source_pos: Vector2) -> int:
	for index in range(animations.size()):
		var animation: Dictionary = animations[index]
		var animation_source_pos: Vector2 = match_board.value_to_vector2(animation.get("source_pos", invalid_board_pos), invalid_board_pos)
		if animation_source_pos != source_pos:
			continue
		return index
	return -1

func remove_piece_shatter_animation_from_list(animations: Array, animation: Dictionary, preferred_index: int) -> void:
	if preferred_index >= 0 and preferred_index < animations.size() and animations[preferred_index] == animation:
		animations.remove_at(preferred_index)
		return
	animations.erase(animation)

func get_capturing_cast_sound_name(capturing_piece_pos: Vector2) -> String:
	if match_board == null:
		return ""
	var capturing_piece: Piece = match_board.piece_objects.get(capturing_piece_pos, null) as Piece
	if capturing_piece == null or capturing_piece.affixed_stamp == null:
		return ""
	return "%s_capture" % capturing_piece.affixed_stamp.Set.to_lower()
