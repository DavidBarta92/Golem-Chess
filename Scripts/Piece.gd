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
	print("🎴 Kártya csatolva: %s a %s bábuhoz (pozíció: %s, körök: %d)" % [card.card_name, "fehér" if color > 0 else "fekete", position, turns_remaining])

func detach_card() -> Card:
	var old_card = attached_card
	attached_card = null
	turns_remaining = 0
	print("♻️ Kártya lecsatolva: %s (visszakerül a pakliba)" % old_card.card_name if old_card else "")
	return old_card

func can_move() -> bool:
	# Végtelen kártya (-1) vagy van hátralevő kör
	return attached_card != null && (turns_remaining > 0 || turns_remaining == -1)
	# return has_card() && (turns_remaining > 0 || turns_remaining == -1)

func get_movement_directions() -> Array:
	if attached_card:
		return attached_card.get_directions()
	return []

func use_turn():
	# Ha végtelen (-1), ne csökkentsük
	if turns_remaining == -1:
		print("⏱️ Végtelen kártya használata: %s" % attached_card.card_name)
		return
	
	if turns_remaining > 0:
		turns_remaining -= 1
		print("⏱️ Kártya használat: %s - hátralevő körök: %d" % [attached_card.card_name, turns_remaining])
		if turns_remaining == 0:
			detach_card()

func get_info() -> String:
	if attached_card:
		if turns_remaining == -1:
			return "%s (végtelen)" % attached_card.card_name
		return "%s (még %d kör)" % [attached_card.card_name, turns_remaining]
	return "Nincs kártya"
	
func has_card() -> bool:
	return attached_card != null
