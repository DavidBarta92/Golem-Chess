@tool
extends RefCounted
class_name StampValueCalculator

# Estimated value of a stamp:
#   value = M × T(D) × S + R + ΣE
#   M     sum over the movement pattern's cells of cell type × distance × direction
#   T(D)  duration factor, D ^ exponent (an infinite duration counts as a fixed D)
#   S     role factor
#   R     role ability: a Se-tenant stamp's share of its set; 0 for the other roles
#   E     effect base value × trigger factor, per effect (a stamp has at most one today)
# All numbers come from StampValueWeights. The Stamp Value Estimator editor plugin stores
# the total on Stamp.estimated_value; the AI reads the breakdown once per stamp
# (AIStampValues.prepare_stamp_values).

const DEFAULT_WEIGHTS_PATH: String = "res://Data/Balance/stamp_value_weights.tres"
const GAME_CONFIG_PATH: String = "res://GameConfig.gd"
const GAME_STATE_PATH: String = "res://Scripts/GameState.gd"
const GRID_CENTER: int = 2

# Effects with a fixed base value, mapped to the StampValueWeights property that holds it.
const FIXED_EFFECT_WEIGHTS: Dictionary = {
	StampEffect.TYPE_INCREASE_OWN_DURATIONS: &"effect_increase_own_durations",
	StampEffect.TYPE_INCREASE_ENEMY_DURATIONS: &"effect_increase_enemy_durations",
	StampEffect.TYPE_DECREASE_OWN_DURATIONS: &"effect_decrease_own_durations",
	StampEffect.TYPE_DECREASE_ENEMY_DURATIONS: &"effect_decrease_enemy_durations",
	StampEffect.TYPE_STEAL_STAMP: &"effect_steal_stamp",
	StampEffect.TYPE_GRANT_STAMP: &"effect_grant_stamp",
	StampEffect.TYPE_GIVE_STAMP: &"effect_give_stamp",
	StampEffect.TYPE_INVISIBLE_TO_ENEMY: &"effect_invisible_to_enemy",
	StampEffect.TYPE_UNCAPTURABLE: &"effect_uncapturable",
	StampEffect.TYPE_MOVE_BASE: &"effect_move_base",
}

class Breakdown:
	extends RefCounted

	# M
	var movement: float = 0.0
	# D as the formula uses it; an infinite duration is replaced by weights.infinite_duration.
	var duration: float = 0.0
	var is_infinite_duration: bool = false
	# T(D)
	var duration_factor: float = 0.0
	# S
	var role_factor: float = 1.0
	# M × T(D) × S
	var movement_part: float = 0.0
	# R, and the set size it was worked out for (0 unless the stamp is a Se-tenant).
	var role_part: float = 0.0
	var se_tenant_set_size: int = 0
	# One entry per effect: {type, trigger, base, trigger_factor, value}.
	var effects: Array[Dictionary] = []
	# ΣE
	var effect_part: float = 0.0
	var total: float = 0.0
	# Reachable cells of the movement pattern, the c and X ones among them, and those on the outer ring.
	var cell_count: int = 0
	var capture_cell_count: int = 0
	var far_cell_count: int = 0
	# The points a crown costs and what one point is worth; 0 unless a crown effect or trigger,
	# or the Se-tenant set, used them.
	var crown_points_required: int = 0
	var crown_point_value: float = 0.0
	# Something crown-based was used but the points a crown costs could not be read; it counts as 0.
	var crown_rules_missing: bool = false
	# The stamp is a Se-tenant but the set size could not be read; R counts as 0.
	var se_tenant_rules_missing: bool = false
	# Effect types and triggers the formula has no value for; they count as 0.
	var unknown_effect_types: PackedStringArray = PackedStringArray()
	var unknown_triggers: PackedStringArray = PackedStringArray()

	func has_warnings() -> bool:
		return !unknown_effect_types.is_empty() || !unknown_triggers.is_empty() || crown_rules_missing || se_tenant_rules_missing

static func load_weights() -> StampValueWeights:
	var weights: StampValueWeights = null
	if ResourceLoader.exists(DEFAULT_WEIGHTS_PATH):
		weights = load(DEFAULT_WEIGHTS_PATH) as StampValueWeights
	if weights == null:
		push_warning("Stamp value weights not found at %s, using the defaults." % DEFAULT_WEIGHTS_PATH)
		weights = StampValueWeights.new()
	return weights

static func calculate(stamp: Stamp, weights: StampValueWeights = null) -> Breakdown:
	return calculate_values(
		stamp.movement_pattern,
		stamp.duration,
		stamp.role,
		stamp.effect_type,
		stamp.effect_trigger,
		stamp.effect_params,
		weights
	)

static func calculate_values(
	movement_pattern: Array,
	duration: int,
	role: int,
	effect_type: String,
	effect_trigger: String,
	effect_params: Array,
	weights: StampValueWeights = null
) -> Breakdown:
	if weights == null:
		weights = load_weights()

	var result: Breakdown = Breakdown.new()
	_add_movement(result, movement_pattern, weights)
	result.is_infinite_duration = duration < 0
	result.duration = weights.infinite_duration if result.is_infinite_duration else float(duration)
	result.duration_factor = duration_factor(result.duration, weights)
	result.role_factor = role_factor(role, weights)
	result.movement_part = result.movement * result.duration_factor * result.role_factor
	if role == Stamp.Role.SE_TENANT:
		_add_se_tenant_set(result, weights)

	if !effect_type.is_empty() && effect_type != StampEffect.TYPE_NONE:
		_add_effect(result, effect_type, effect_trigger, effect_params, weights)

	result.total = result.movement_part + result.role_part + result.effect_part
	return result

static func duration_factor(duration: float, weights: StampValueWeights) -> float:
	return pow(maxf(duration, 0.0), weights.duration_exponent)

static func role_factor(role: int, weights: StampValueWeights) -> float:
	match role:
		Stamp.Role.SEEKER:
			return weights.role_seeker
		Stamp.Role.SHARED:
			return weights.role_shared
		Stamp.Role.SE_TENANT:
			return weights.role_se_tenant
		Stamp.Role.OVERSEAL:
			return weights.role_overseal
	return weights.role_other

# The number of Se-tenant golems that keep the crown meter full: weights.se_tenant_set_size
# when set, else GameStateData.SE_TENANT_SET_SIZE. 0 when neither can be read.
static func se_tenant_set_size(weights: StampValueWeights = null) -> int:
	if weights != null && weights.se_tenant_set_size > 0:
		return weights.se_tenant_set_size
	# Loaded here rather than named, so the plugin does not depend on the game's scripts compiling.
	var game_state_script: Script = load(GAME_STATE_PATH) as Script
	if game_state_script == null:
		return 0
	var set_size: Variant = game_state_script.get_script_constant_map().get(&"SE_TENANT_SET_SIZE")
	return maxi(1, set_size) if set_size is int else 0

# The points a crown costs: weights.crown_points_required when set, else the running game's
# GameConfig, else (in the editor, where that autoload does not run) the default written in
# GameConfig.gd. 0 when none of them can be read.
static func crown_points_required(weights: StampValueWeights = null) -> int:
	if weights != null && weights.crown_points_required > 0:
		return weights.crown_points_required

	if !Engine.is_editor_hint():
		var tree: SceneTree = Engine.get_main_loop() as SceneTree
		var game_config: Node = tree.root.get_node_or_null(^"GameConfig") if tree != null else null
		if game_config != null:
			var live_points: Variant = game_config.get(&"crown_points_required")
			if live_points is int:
				return maxi(1, live_points)

	# A plain var has no default the editor can ask the script for, so it is read from the source.
	var game_config_script: Script = load(GAME_CONFIG_PATH) as Script
	if game_config_script == null:
		return 0
	var declaration: RegEx = RegEx.create_from_string("(?m)^var\\s+crown_points_required\\b[^=\\n]*=\\s*(\\d+)")
	var found: RegExMatch = declaration.search(game_config_script.source_code)
	if found == null:
		return 0
	return maxi(1, found.get_string(1).to_int())

static func _use_crown_rules(result: Breakdown, weights: StampValueWeights) -> void:
	if result.crown_points_required > 0 || result.crown_rules_missing:
		return
	result.crown_points_required = crown_points_required(weights)
	if result.crown_points_required <= 0:
		result.crown_rules_missing = true
		return
	result.crown_point_value = weights.crown_meter_value / float(result.crown_points_required)

# While the set is whole the crown meter stays full, so the turns it is used on are worth a
# meter less the turn's own point; when the set breaks the meter drops to 0. Each of the set's
# stamps carries an equal share.
static func _add_se_tenant_set(result: Breakdown, weights: StampValueWeights) -> void:
	_use_crown_rules(result, weights)
	if result.crown_rules_missing:
		return
	result.se_tenant_set_size = se_tenant_set_size(weights)
	if result.se_tenant_set_size <= 0:
		result.se_tenant_rules_missing = true
		return
	var points: float = float(result.crown_points_required)
	var used_points: float = result.duration * weights.se_tenant_whole_share * weights.se_tenant_crown_use_rate * (points - 1.0)
	var lost_points: float = weights.se_tenant_break_meter_share * points
	var set_value: float = (used_points - lost_points) * result.crown_point_value
	result.role_part = weights.se_tenant_set_chance * set_value / float(result.se_tenant_set_size)

static func _add_movement(result: Breakdown, pattern: Array, weights: StampValueWeights) -> void:
	for row in range(pattern.size()):
		var cells: Array = pattern[row]
		for col in range(cells.size()):
			if row == GRID_CENTER && col == GRID_CENTER:
				continue
			var cell: int = int(cells[col])
			if cell == StampEffect.MOVEMENT_NONE:
				continue

			var row_offset: int = row - GRID_CENTER
			var distance: int = maxi(absi(col - GRID_CENTER), absi(row_offset))
			result.movement += _cell_type_weight(cell, weights) * _distance_weight(distance, weights) * _direction_weight(row_offset, weights)
			result.cell_count += 1
			if cell != StampEffect.MOVEMENT_MOVE_ONLY:
				result.capture_cell_count += 1
			if distance > 1:
				result.far_cell_count += 1

static func _cell_type_weight(cell: int, weights: StampValueWeights) -> float:
	match cell:
		StampEffect.MOVEMENT_MOVE_ONLY:
			return weights.cell_move_only
		StampEffect.MOVEMENT_CAPTURE_ONLY:
			return weights.cell_capture_only
		StampEffect.MOVEMENT_MOVE_AND_CAPTURE:
			return weights.cell_move_and_capture
	return 0.0

static func _distance_weight(distance: int, weights: StampValueWeights) -> float:
	return weights.distance_near if distance <= 1 else weights.distance_far

static func _direction_weight(row_offset: int, weights: StampValueWeights) -> float:
	# The top row is forward, so rows above the golem point at the enemy.
	if row_offset < 0:
		return weights.direction_forward
	if row_offset > 0:
		return weights.direction_backward
	return weights.direction_side

static func _add_effect(result: Breakdown, effect_type: String, effect_trigger: String, effect_params: Array, weights: StampValueWeights) -> void:
	var base: float = _effect_base_value(result, effect_type, effect_params, weights)
	var trigger_factor: float = _trigger_factor(result, effect_trigger, weights)
	var value: float = base * trigger_factor
	result.effects.append({
		"type": effect_type,
		"trigger": effect_trigger,
		"base": base,
		"trigger_factor": trigger_factor,
		"value": value,
	})
	result.effect_part += value

static func _effect_base_value(result: Breakdown, effect_type: String, effect_params: Array, weights: StampValueWeights) -> float:
	match effect_type:
		StampEffect.TYPE_INCREASE_SELF_DURATION:
			# Worth what the extra steps add to this stamp's own movement part.
			var longer_factor: float = duration_factor(result.duration + weights.increase_self_duration_amount, weights)
			return result.movement * (longer_factor - result.duration_factor) * result.role_factor
		StampEffect.TYPE_INVALID_SQUARES:
			return weights.invalid_squares_per_cell * _count_marked_cells(effect_params)
		StampEffect.TYPE_FROZEN_SQUARES:
			return weights.frozen_squares_per_cell * _count_marked_cells(effect_params)
		StampEffect.TYPE_BOMB:
			var cell_value: float = weights.bomb_enemy_density * weights.bomb_enemy_golem_value - weights.bomb_own_density * weights.bomb_own_golem_value
			return cell_value * _count_marked_cells(effect_params)
		StampEffect.TYPE_GAIN_CROWN_POINT:
			_use_crown_rules(result, weights)
			return weights.gain_crown_point_amount * result.crown_point_value
		StampEffect.TYPE_REMOVE_ENEMY_CROWN_POINT:
			_use_crown_rules(result, weights)
			return weights.remove_enemy_crown_point_amount * result.crown_point_value

	if FIXED_EFFECT_WEIGHTS.has(effect_type):
		return float(weights.get(FIXED_EFFECT_WEIGHTS[effect_type]))

	result.unknown_effect_types.append(effect_type)
	return 0.0

static func _trigger_factor(result: Breakdown, effect_trigger: String, weights: StampValueWeights) -> float:
	match effect_trigger:
		StampEffect.TRIGGER_ON_AFFIX:
			return weights.trigger_on_affix
		StampEffect.TRIGGER_ON_MOVE:
			# Fires on every step, so D times over the stamp's life.
			return weights.trigger_on_move_per_duration * result.duration
		StampEffect.TRIGGER_ON_CAPTURE:
			return weights.trigger_on_capture_per_duration * result.duration
		StampEffect.TRIGGER_ON_CAPTURED:
			return weights.trigger_on_captured
		StampEffect.TRIGGER_ON_EXPIRE:
			return weights.trigger_on_expire
		StampEffect.TRIGGER_ON_SYMBOL_COUNT:
			return weights.trigger_on_symbol_count
		StampEffect.TRIGGER_CROWN_CONDITION:
			# Fires at most once, so the crown chances within the stamp's life count up to one.
			_use_crown_rules(result, weights)
			if result.crown_rules_missing:
				return 0.0
			var crown_chances: float = minf(1.0, result.duration / float(result.crown_points_required))
			return crown_chances * weights.trigger_crown_condition_pick_chance

	result.unknown_triggers.append(effect_trigger)
	return 0.0

# Effect patterns include the golem's own square (see Stamp.get_effect_offsets).
static func _count_marked_cells(pattern: Array) -> int:
	var count: int = 0
	for cells in pattern:
		if !(cells is Array):
			continue
		for cell in cells:
			if int(cell) != 0:
				count += 1
	return count
