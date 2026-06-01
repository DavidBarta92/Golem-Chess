extends RefCounted
class_name Piece

var position: Vector2
var color: int  # 1 = white, -1 = black
var attached_card: Card = null
var turns_remaining: int = 0
var exhausted_this_turn: bool = false
var respawn_cooldown_turns: int = 0

func _init(pos: Vector2, col: int):
	position = pos
	color = col

func attach_card(card: Card, exhaust_for_turn: bool = true):
	attached_card = card
	turns_remaining = card.duration
	exhausted_this_turn = exhaust_for_turn
	DebugLog.info("Card attached: %s to %s piece (position: %s, turns: %d)" % [card.card_name, "white" if color > 0 else "black", position, turns_remaining])

func detach_card() -> Card:
	var old_card = attached_card
	attached_card = null
	turns_remaining = 0
	exhausted_this_turn = false
	DebugLog.info("Card detached: %s" % old_card.card_name if old_card else "")
	return old_card

func can_move() -> bool:
	return !is_respawn_locked() && !exhausted_this_turn && attached_card != null && (turns_remaining > 0 || turns_remaining == -1)
	# return has_card() && (turns_remaining > 0 || turns_remaining == -1)

func can_receive_card() -> bool:
	return !is_respawn_locked() && attached_card == null

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
	if attached_card:
		return attached_card.get_directions()
	return []

func use_turn() -> Card:
	if attached_card == null:
		return null

	if turns_remaining == -1:
		DebugLog.info("Infinite card used: %s" % attached_card.card_name)
		return null

	if turns_remaining > 0:
		turns_remaining -= 1
		DebugLog.info("Card used: %s - turns remaining: %d" % [attached_card.card_name, turns_remaining])
		if turns_remaining == 0:
			return detach_card()

	return null

func get_info() -> String:
	if attached_card:
		if turns_remaining == -1:
			return "%s (infinite)" % attached_card.card_name
		return "%s (%d turns left)" % [attached_card.card_name, turns_remaining]
	return "No card"

func has_card() -> bool:
	return attached_card != null
