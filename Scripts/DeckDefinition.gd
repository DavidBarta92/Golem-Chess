@tool
extends Resource
class_name DeckDefinition

## A ready-made deck that lives in the game's database, not in the player's
## save: the pool the story draws from when it needs a random opponent.
##
## Save one .tres per deck under Decks/. Like a boss deck it is a plain list of
## Stamp resources in draw order, and it never depends on what the player owns.
## Keep decks to one set - a random opponent is meant to read as "a Flora
## player", not a grab bag.

@export var deck_id: String = ""
@export var deck_name: String = ""
## The set every stamp in this deck belongs to; informational, used to label
## and group decks.
@export_enum("Animals", "Flora", "Celestials", "Archetypes", "Courtyard", "Structures") var set_name: String = "Courtyard"
## Draw order: the match deals from the top, three to a codex page.
@export var stamps: Array[Stamp] = []

func get_stamp_names() -> Array[String]:
	var stamp_names: Array[String] = []
	for stamp in stamps:
		if stamp == null:
			continue
		var stamp_name: String = str(stamp.stamp_name).strip_edges()
		if !stamp_name.is_empty():
			stamp_names.append(stamp_name)
	return stamp_names

func is_playable() -> bool:
	return get_stamp_names().size() >= DeckManager.DECK_SIZE
