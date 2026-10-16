extends Node

## Loads every DeckDefinition under Decks/ once and hands them out by id or at
## random. Mirrors PackDefinitionLibrary so the two databases feel the same.

const DECKS_PATH: String = "res://Decks/"

var all_decks: Dictionary = {}
var deck_order: Array[String] = []
var is_loaded: bool = false

func _ready() -> void:
	load_all_decks()

func ensure_loaded() -> void:
	if is_loaded:
		return
	load_all_decks()

func load_all_decks() -> void:
	all_decks.clear()
	deck_order.clear()

	var dir := DirAccess.open(DECKS_PATH)
	if dir != null:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				var resource_file_name: String = file_name.trim_suffix(".remap")
				if resource_file_name.ends_with(".tres"):
					var deck_definition := load(DECKS_PATH + resource_file_name) as DeckDefinition
					if deck_definition != null:
						_register_deck(deck_definition, resource_file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

	deck_order.sort()
	is_loaded = true
	DebugLog.info("DeckDefinitionLibrary loaded: %d decks" % all_decks.size())

func get_deck(deck_id: String) -> DeckDefinition:
	ensure_loaded()
	return all_decks.get(deck_id.strip_edges())

func get_all_decks() -> Array[DeckDefinition]:
	ensure_loaded()
	var decks: Array[DeckDefinition] = []
	for deck_id in deck_order:
		var deck_definition := all_decks.get(deck_id) as DeckDefinition
		if deck_definition != null:
			decks.append(deck_definition)
	return decks

func get_playable_decks() -> Array[DeckDefinition]:
	var playable: Array[DeckDefinition] = []
	for deck_definition in get_all_decks():
		if deck_definition.is_playable():
			playable.append(deck_definition)
	return playable

## A random full deck, or null when the database is empty. `rng` lets a caller
## make the pick reproducible.
func pick_random_deck(rng: RandomNumberGenerator = null) -> DeckDefinition:
	var playable: Array[DeckDefinition] = get_playable_decks()
	if playable.is_empty():
		return null
	var index: int = rng.randi_range(0, playable.size() - 1) if rng != null else randi() % playable.size()
	return playable[index]

func _register_deck(deck_definition: DeckDefinition, file_name: String) -> void:
	var deck_id: String = deck_definition.deck_id.strip_edges()
	if deck_id.is_empty():
		deck_id = file_name.get_basename()
		deck_definition.deck_id = deck_id
	if all_decks.has(deck_id):
		push_warning("DeckDefinitionLibrary: duplicate deck id '%s' (%s); keeping the first." % [deck_id, file_name])
		return
	all_decks[deck_id] = deck_definition
	deck_order.append(deck_id)
