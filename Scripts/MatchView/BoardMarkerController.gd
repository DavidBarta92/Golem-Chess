extends RefCounted

const INVALID_BOARD_POS = Vector2(-1, -1)

const MOVE_OPTION_DOT_TEXTURE: Texture2D = preload("res://Assets/dot.svg")
const MOVE_OPTION_DOT_SHADER: Shader = preload("res://Shaders/move_option_dot.gdshader")
const MOVE_OPTION_DOT_CELL_WIDTH_RATIO: float = 0.58
const MOVE_OPTION_DOT_SHADER_SPEED: float = 0.24
const MOVE_OPTION_DOT_SHADER_GLOW_STRENGTH: float = 2.0
const MOVE_OPTION_DOT_SHADER_EDGE_SOFTNESS: float = 0.85
const MOVE_OPTION_DOT_SHADER_PULSE_MIN_SCALE: float = 0.88
const MOVE_OPTION_DOT_SHADER_PULSE_MAX_SCALE: float = 1.18
const MOVE_OPTION_DOT_SHADER_COLOR: Color = Color(1.0, 0.94, 0.78, 1.0)
# The dots come up in a wave out from the piece, each popping up a moment
# after the one a square nearer.
const MOVE_OPTION_WAVE_SECONDS_PER_SQUARE: float = 0.035
const MOVE_OPTION_POP_SECONDS: float = 0.18
# Where one of the player's own pieces could take: a bigger, warmer star, and
# the piece standing there trembles as the wave reaches it.
const CAPTURE_TARGET_STAR_SCALE: float = 1.75
const CAPTURE_TARGET_STAR_COLOR: Color = Color(1.0, 0.8, 0.42, 1.0)
const CAPTURE_TARGET_TREMBLE_DISTANCE: float = 0.7
const CAPTURE_TARGET_TREMBLE_SECONDS: float = 0.26
const CAPTURE_TARGET_TREMBLE_SWINGS: float = 3.0
const LAST_MOVE_ARROW_COLOR: Color = Color(1.0, 0.88, 0.18, 1.0)
const LAST_MOVE_ARROW_WIDTH: float = 3.0
const LAST_MOVE_ARROW_ENDPOINT_INSET: float = 6.0
const LAST_MOVE_ARROW_HEAD_LENGTH: float = 8.0
const LAST_MOVE_ARROW_HEAD_HALF_WIDTH: float = 5.0

var geometry
var visuals
var dots_node: Node
var board_markers_node: Node2D
var texture_holder_scene: PackedScene
var cell_width: float = 36.0
var board_size: int = 9
var enemy_attack_marker_color: Color = Color(1.0, 0.05, 0.03, 0.105)

var piece_objects_provider: Callable
var board_effects_provider: Callable
var current_last_move_provider: Callable
var local_view_color_provider: Callable
var local_view_ready_provider: Callable
var own_player_id_provider: Callable
var can_move_action_now_provider: Callable
var can_player_control_piece_at_provider: Callable
var piece_holder_provider: Callable
var update_special_tiles_callback: Callable

var move_option_dot_pulse_material: ShaderMaterial
var move_option_dot_static_material: ShaderMaterial
var capture_target_star_material: ShaderMaterial

func configure(config: Dictionary) -> void:
	geometry = config.get("geometry", geometry)
	visuals = config.get("visuals", visuals)
	dots_node = config.get("dots_node", dots_node)
	board_markers_node = config.get("board_markers_node", board_markers_node)
	texture_holder_scene = config.get("texture_holder_scene", texture_holder_scene)
	cell_width = float(config.get("cell_width", cell_width))
	board_size = int(config.get("board_size", board_size))
	enemy_attack_marker_color = config.get("enemy_attack_marker_color", enemy_attack_marker_color)

	piece_objects_provider = config.get("piece_objects_provider", piece_objects_provider)
	board_effects_provider = config.get("board_effects_provider", board_effects_provider)
	current_last_move_provider = config.get("current_last_move_provider", current_last_move_provider)
	local_view_color_provider = config.get("local_view_color_provider", local_view_color_provider)
	local_view_ready_provider = config.get("local_view_ready_provider", local_view_ready_provider)
	own_player_id_provider = config.get("own_player_id_provider", own_player_id_provider)
	can_move_action_now_provider = config.get("can_move_action_now_provider", can_move_action_now_provider)
	can_player_control_piece_at_provider = config.get("can_player_control_piece_at_provider", can_player_control_piece_at_provider)
	piece_holder_provider = config.get("piece_holder_provider", piece_holder_provider)
	update_special_tiles_callback = config.get("update_special_tiles_callback", update_special_tiles_callback)

func show_dots(moves: Array, source_pos: Vector2 = INVALID_BOARD_POS) -> void:
	if dots_node == null or !is_instance_valid(dots_node):
		return

	var own_move: bool = should_pulse_move_option_dots(source_pos)
	var dot_material: ShaderMaterial = get_move_option_dot_material(own_move)
	for move_value in moves:
		var board_pos: Vector2 = BoardConfig.value_to_vector2(move_value, INVALID_BOARD_POS)
		if !MoveRules.is_valid_position(board_pos):
			continue
		if texture_holder_scene == null or MOVE_OPTION_DOT_TEXTURE == null:
			continue

		var takes: bool = own_move and is_visible_capture_target(source_pos, board_pos)
		var holder = texture_holder_scene.instantiate()
		dots_node.add_child(holder)
		holder.texture = MOVE_OPTION_DOT_TEXTURE
		holder.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		holder.material = get_capture_target_star_material() if takes else dot_material
		holder.position = geometry.get_position_local(board_pos) if geometry != null else Vector2.ZERO
		var dot_scale: Vector2 = get_move_option_dot_scale(board_pos) * (CAPTURE_TARGET_STAR_SCALE if takes else 1.0)
		pop_move_option_dot(holder, dot_scale, source_pos, board_pos, takes)

## The dot pops up once the wave from `source_pos` has come this far, and a
## piece that could be taken here trembles as it does.
func pop_move_option_dot(holder: Sprite2D, dot_scale: Vector2, source_pos: Vector2, board_pos: Vector2, takes: bool) -> void:
	var delay: float = 0.0
	if MoveRules.is_valid_position(source_pos):
		delay = (board_pos - source_pos).length() * MOVE_OPTION_WAVE_SECONDS_PER_SQUARE
	holder.scale = dot_scale * 0.01
	var tween: Tween = holder.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(holder, "scale", dot_scale, MOVE_OPTION_POP_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	if takes:
		tween.parallel().tween_callback(tremble_piece_at.bind(board_pos))

## Whether the piece at `target_pos` is one the player can see belonging to the
## other side from the piece at `source_pos`. A piece hidden from the viewer
## gets a plain dot, as it would have before: the dots must not give it away.
func is_visible_capture_target(source_pos: Vector2, target_pos: Vector2) -> bool:
	var piece_objects: Dictionary = get_piece_objects()
	var source_piece: Piece = piece_objects.get(source_pos, null) as Piece
	var target_piece: Piece = piece_objects.get(target_pos, null) as Piece
	if source_piece == null or target_piece == null or target_piece.hidden_from_viewer:
		return false
	return target_piece.color != source_piece.color

func tremble_piece_at(board_pos: Vector2) -> void:
	if !piece_holder_provider.is_valid() or geometry == null:
		return
	var holder: Sprite2D = piece_holder_provider.call(board_pos) as Sprite2D
	if holder == null or !is_instance_valid(holder) or holder.texture == null:
		return
	# From where it stands, not from where a tremble still running left it.
	var rest_position: Vector2 = geometry.get_position_local(board_pos)
	var tween: Tween = holder.create_tween()
	tween.tween_method(func(progress: float):
		holder.position = rest_position + Vector2(CAPTURE_TARGET_TREMBLE_DISTANCE * sin(progress * TAU * CAPTURE_TARGET_TREMBLE_SWINGS) * (1.0 - progress), 0.0)
	, 0.0, 1.0, CAPTURE_TARGET_TREMBLE_SECONDS)
	tween.tween_callback(func(): holder.position = rest_position)

func delete_dots() -> void:
	if dots_node == null or !is_instance_valid(dots_node):
		return
	for child in dots_node.get_children():
		child.queue_free()

func update_markers() -> void:
	if board_markers_node == null or !is_instance_valid(board_markers_node):
		return

	if update_special_tiles_callback.is_valid():
		update_special_tiles_callback.call()
	for child in board_markers_node.get_children():
		child.queue_free()

	if SettingsDataManager.is_enemy_attack_markers_enabled() and is_local_view_ready():
		add_enemy_attack_markers()
	if SettingsDataManager.is_last_move_arrow_enabled() and is_local_view_ready():
		add_last_move_arrow_marker()

func add_enemy_attack_markers() -> void:
	var enemy_color: int = -get_local_view_color()
	var attacked_squares: Array[Vector2] = MoveRules.get_attacked_squares_for_player(
		get_piece_objects(),
		enemy_color,
		board_size,
		get_board_effects()
	)
	for square_pos: Vector2 in attacked_squares:
		add_board_square_fill(square_pos, enemy_attack_marker_color)

func add_last_move_arrow_marker() -> void:
	var current_last_move: Dictionary = get_current_last_move()
	if current_last_move.is_empty() or !bool(current_last_move.get("visible_to_enemy", true)) or !bool(current_last_move.get("show_arrow", true)):
		return

	var mover_color: int = int(current_last_move.get("piece_color", 0))
	if mover_color == 0 or mover_color == get_local_view_color():
		return

	var from_pos: Vector2 = BoardConfig.value_to_vector2(current_last_move.get("from", INVALID_BOARD_POS), INVALID_BOARD_POS)
	var to_pos: Vector2 = BoardConfig.value_to_vector2(current_last_move.get("to", INVALID_BOARD_POS), INVALID_BOARD_POS)
	if !MoveRules.is_valid_position(from_pos) or !MoveRules.is_valid_position(to_pos) or from_pos == to_pos:
		return
	if !get_piece_objects().has(to_pos):
		return

	add_board_arrow(from_pos, to_pos, LAST_MOVE_ARROW_COLOR, LAST_MOVE_ARROW_WIDTH)

func add_board_square_fill(board_pos: Vector2, marker_color: Color):
	if visuals == null:
		return null
	return visuals.create_square_fill(board_markers_node, board_pos, marker_color)

func add_board_line(points: Array, line_color: Color, line_width: float):
	if visuals == null:
		return null
	return visuals.add_line(board_markers_node, points, line_color, line_width)

func add_board_arrow(from_pos: Vector2, to_pos: Vector2, arrow_color: Color, line_width: float):
	if visuals == null:
		return null
	return visuals.add_arrow(
		board_markers_node,
		from_pos,
		to_pos,
		arrow_color,
		line_width,
		LAST_MOVE_ARROW_ENDPOINT_INSET,
		LAST_MOVE_ARROW_HEAD_LENGTH,
		LAST_MOVE_ARROW_HEAD_HALF_WIDTH
	)

func get_move_option_dot_material(should_pulse: bool) -> ShaderMaterial:
	if should_pulse:
		if move_option_dot_pulse_material == null:
			move_option_dot_pulse_material = create_move_option_dot_material(1.0)
		return move_option_dot_pulse_material

	if move_option_dot_static_material == null:
		move_option_dot_static_material = create_move_option_dot_material(0.0)
	return move_option_dot_static_material

func get_capture_target_star_material() -> ShaderMaterial:
	if capture_target_star_material == null:
		capture_target_star_material = create_move_option_dot_material(1.0)
		capture_target_star_material.set_shader_parameter("star", 1.0)
		capture_target_star_material.set_shader_parameter("color", CAPTURE_TARGET_STAR_COLOR)
	return capture_target_star_material

func create_move_option_dot_material(pulse_strength: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = MOVE_OPTION_DOT_SHADER
	material.set_shader_parameter("speed", MOVE_OPTION_DOT_SHADER_SPEED)
	material.set_shader_parameter("glow_strength", MOVE_OPTION_DOT_SHADER_GLOW_STRENGTH)
	material.set_shader_parameter("edge_softness", MOVE_OPTION_DOT_SHADER_EDGE_SOFTNESS)
	material.set_shader_parameter("pulse_min_scale", MOVE_OPTION_DOT_SHADER_PULSE_MIN_SCALE)
	material.set_shader_parameter("pulse_max_scale", MOVE_OPTION_DOT_SHADER_PULSE_MAX_SCALE)
	material.set_shader_parameter("color", MOVE_OPTION_DOT_SHADER_COLOR)
	material.set_shader_parameter("pulse_strength", pulse_strength)
	return material

func get_move_option_dot_scale(board_pos: Vector2) -> Vector2:
	if MOVE_OPTION_DOT_TEXTURE == null:
		return Vector2.ONE
	var texture_size: Vector2 = MOVE_OPTION_DOT_TEXTURE.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Vector2.ONE
	if geometry == null:
		var fallback_scale: float = (cell_width * MOVE_OPTION_DOT_CELL_WIDTH_RATIO) / texture_size.x
		return Vector2(fallback_scale, fallback_scale)

	var cell_bounds: Rect2 = geometry.get_points_bounds_local(geometry.get_cell_polygon_local(board_pos))
	var target_width: float = cell_width * MOVE_OPTION_DOT_CELL_WIDTH_RATIO
	if cell_bounds.size.x <= 0.0 or cell_bounds.size.y <= 0.0:
		var fallback_scale: float = target_width / texture_size.x
		return Vector2(fallback_scale, fallback_scale)
	var target_height: float = target_width * (cell_bounds.size.y / cell_bounds.size.x)
	return Vector2(target_width / texture_size.x, target_height / texture_size.y)

func should_pulse_move_option_dots(source_pos: Vector2) -> bool:
	if source_pos == INVALID_BOARD_POS:
		return false
	if can_move_action_now_provider.is_valid() and !bool(can_move_action_now_provider.call()):
		return false
	if can_player_control_piece_at_provider.is_valid() and !bool(can_player_control_piece_at_provider.call(source_pos, get_own_player_id())):
		return false
	var piece_objects: Dictionary = get_piece_objects()
	var piece: Piece = piece_objects[source_pos] as Piece if piece_objects.has(source_pos) else null
	return piece != null and piece.can_move()

func get_piece_objects() -> Dictionary:
	if piece_objects_provider.is_valid():
		var value = piece_objects_provider.call()
		if value is Dictionary:
			return value
	return {}

func get_board_effects() -> Array:
	if board_effects_provider.is_valid():
		var value = board_effects_provider.call()
		if value is Array:
			return value
	return []

func get_current_last_move() -> Dictionary:
	if current_last_move_provider.is_valid():
		var value = current_last_move_provider.call()
		if value is Dictionary:
			return value
	return {}

func get_local_view_color() -> int:
	if local_view_color_provider.is_valid():
		return int(local_view_color_provider.call())
	return 1

func is_local_view_ready() -> bool:
	if local_view_ready_provider.is_valid():
		return bool(local_view_ready_provider.call())
	return true

func get_own_player_id() -> int:
	if own_player_id_provider.is_valid():
		return int(own_player_id_provider.call())
	return 0
