extends RefCounted
class_name Piece

var position: Vector2
var color: int  # 1 = white, -1 = black
var attached_card: Card = null
var turns_remaining: int = 0

func _init(pos: Vector2, col: int):
	position = pos
	color = col

func attach_card(card: Card):
	attached_card = card
	turns_remaining = card.duration
	print("Card attached: %s to %s piece (position: %s, turns: %d)" % [card.card_name, "white" if color > 0 else "black", position, turns_remaining])

func detach_card() -> Card:
	var old_card = attached_card
	attached_card = null
	turns_remaining = 0
	print("Card detached: %s" % old_card.card_name if old_card else "")
	return old_card

func can_move() -> bool:
	return attached_card != null && (turns_remaining > 0 || turns_remaining == -1)
	# return has_card() && (turns_remaining > 0 || turns_remaining == -1)

func get_movement_directions() -> Array:
	if attached_card:
		return attached_card.get_directions()
	return []

func use_turn() -> Card:
	if turns_remaining == -1:
		print("Infinite card used: %s" % attached_card.card_name)
		return null

	if turns_remaining > 0:
		turns_remaining -= 1
		print("Card used: %s - turns remaining: %d" % [attached_card.card_name, turns_remaining])
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
