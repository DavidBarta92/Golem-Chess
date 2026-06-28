extends RefCounted
class_name Piece

var position: Vector2
var color: int  # 1 = white, -1 = black
var attached_stamp: Stamp = null
var turns_remaining: int = 0
var exhausted_this_turn: bool = false
var respawn_cooldown_turns: int = 0
var hidden_from_viewer: bool = false

func _init(pos: Vector2, col: int):
	position = pos
	color = col

func attach_stamp(stamp: Stamp, exhaust_for_turn: bool = true):
	attached_stamp = stamp
	turns_remaining = stamp.duration
	exhausted_this_turn = exhaust_for_turn
	DebugLog.info("Stamp attached: %s to %s piece (position: %s, turns: %d)" % [stamp.stamp_name, "white" if color > 0 else "black", position, turns_remaining])

func detach_stamp() -> Stamp:
	var old_stamp = attached_stamp
	attached_stamp = null
	turns_remaining = 0
	exhausted_this_turn = false
	DebugLog.info("Stamp detached: %s" % old_stamp.stamp_name if old_stamp else "")
	return old_stamp

func can_move() -> bool:
	return !is_respawn_locked() && !exhausted_this_turn && attached_stamp != null && (turns_remaining > 0 || turns_remaining == -1)
	# return has_stamp() && (turns_remaining > 0 || turns_remaining == -1)

func can_receive_stamp() -> bool:
	return !is_respawn_locked() && attached_stamp == null

func is_respawn_locked() -> bool:
	return respawn_cooldown_turns > 0

func set_respawn_cooldown(turns: int) -> void:
	respawn_cooldown_turns = 1 if turns > 0 else 0
	if respawn_cooldown_turns > 0:
		exhausted_this_turn = true
	else:
		exhausted_this_turn = false

func tick_respawn_cooldown() -> void:
	pass

func get_movement_directions() -> Array:
	if attached_stamp:
		return attached_stamp.get_directions()
	return []

func use_turn() -> Stamp:
	if attached_stamp == null:
		return null

	if turns_remaining == -1:
		DebugLog.info("Infinite stamp used: %s" % attached_stamp.stamp_name)
		return null

	if turns_remaining > 0:
		turns_remaining -= 1
		DebugLog.info("Stamp used: %s - turns remaining: %d" % [attached_stamp.stamp_name, turns_remaining])
		if turns_remaining == 0:
			return detach_stamp()

	return null

func get_info() -> String:
	if attached_stamp:
		if turns_remaining == -1:
			return "%s (infinite)" % attached_stamp.stamp_name
		return "%s (%d turns left)" % [attached_stamp.stamp_name, turns_remaining]
	return "No stamp"

func has_stamp() -> bool:
	return attached_stamp != null
