extends RefCounted
class_name AIStampValues

## Stamp values on the AI's score scale, from the stamp value estimate
## (Docs/Balance/STAMP_VALUE.md): the part of a stamp's value still ahead of it,
## and how far a fresh one is above the average stamp. The parts are worked out
## once on the main thread (prepare_stamp_values) and only read after, also from
## the search's worker threads.

const STAMP_VALUE_AFFIX_PLAY_WEIGHT: float = 0.35
const STAMP_VALUE_AFFIX_EXCHANGE_WEIGHT: float = 0.6
## Score points per stamp estimate point (Stamp.estimated_value's scale). At 5
## a captured fresh stamp is worth about what the flat 75 + 8 a turn was on
## average, but no longer the same for every stamp.
const STAMP_ESTIMATE_POINT_SCORE: float = 5.0

# stamp_name -> the parts of its estimate the AI uses (calculate_stamp_value_parts),
# filled once on the main thread and only read afterwards.
static var stamp_value_parts: Dictionary = {}
# The average enabled stamp's fresh value, in estimate points.
static var stamp_value_fresh_mean: float = 0.0

## Estimate points still ahead of a stamp with turns_left turns to go (see
## Docs/Balance/STAMP_VALUE.md): its movement part over those turns, and the
## effects that fire on every step or capture. The rest of the estimate is left
## to the scoring that sees the board: on_affix effects have fired once the
## stamp is on, and on_captured, on_expire, crown conditions and the Se-tenant
## set are scored where they happen, for whoever they help.
static func get_stamp_remaining_value(stamp: Stamp, turns_left: int) -> float:
	if stamp == null:
		return 0.0
	var parts: Dictionary = stamp_value_parts.get(stamp.stamp_name, {})
	if parts.is_empty():
		parts = calculate_stamp_value_parts(stamp, StampValueCalculator.load_weights())
	var turns: float = float(parts.duration) if stamp.duration < 0 else float(maxi(0, turns_left))
	return float(parts.movement) * pow(turns, float(parts.exponent)) + float(parts.effect_per_turn) * turns

static func get_stamp_fresh_value(stamp: Stamp) -> float:
	return get_stamp_remaining_value(stamp, stamp.duration) if stamp != null else 0.0

## A fresh stamp's value on the score scale, against the average enabled stamp.
static func get_stamp_value_above_average(stamp: Stamp) -> float:
	if stamp == null:
		return 0.0
	return (get_stamp_fresh_value(stamp) - stamp_value_fresh_mean) * STAMP_ESTIMATE_POINT_SCORE

## M × S, the exponent of T(D), D and the per-turn value of the effects that
## repeat, out of the estimate's breakdown.
static func calculate_stamp_value_parts(stamp: Stamp, weights: StampValueWeights) -> Dictionary:
	var breakdown: StampValueCalculator.Breakdown = StampValueCalculator.calculate(stamp, weights)
	var repeating_value: float = 0.0
	for effect: Dictionary in breakdown.effects:
		var trigger: String = str(effect.get("trigger", ""))
		if trigger == StampEffect.TRIGGER_ON_MOVE or trigger == StampEffect.TRIGGER_ON_CAPTURE:
			repeating_value += float(effect.get("value", 0.0))
	return {
		"movement": breakdown.movement * breakdown.role_factor,
		"exponent": weights.duration_exponent,
		"duration": breakdown.duration,
		"effect_per_turn": repeating_value / breakdown.duration if breakdown.duration > 0.0 else 0.0,
	}

## Works out every library stamp's parts once, on the main thread, so the
## parallel scoring only reads them.
static func prepare_stamp_values() -> void:
	if !stamp_value_parts.is_empty() or OS.get_thread_caller_id() != OS.get_main_thread_id():
		return
	var weights: StampValueWeights = StampValueCalculator.load_weights()
	var fresh_total: float = 0.0
	var enabled_count: int = 0
	for stamp_value in StampLibrary.all_stamps.values():
		var stamp: Stamp = stamp_value as Stamp
		if stamp == null:
			continue
		stamp_value_parts[stamp.stamp_name] = calculate_stamp_value_parts(stamp, weights)
		if stamp.enabled:
			fresh_total += get_stamp_fresh_value(stamp)
			enabled_count += 1
	stamp_value_fresh_mean = fresh_total / float(maxi(1, enabled_count))
