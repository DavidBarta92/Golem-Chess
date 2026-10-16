extends RewardSceneBase

## The first reward: Grandpa's deck becomes the player's own.
##
## The player has been playing with these exact stamps since the tutorial (they
## are the game's starting deck), so this is where they are *recorded* - the
## collection ends up holding every copy the deck uses, and a saved deck with
## the same 15 stamps in the same order is created and selected. Nothing the
## player can see changes until the Collection opens two fights later; the
## reward moment is the reveal animation and the fact that the cards are now
## theirs on paper.
##
## Idempotent on top of the base payout guard: quantities are topped up to the
## deck's counts, never added blindly, so a re-entered scene or the copies the
## deck store already granted cannot inflate the collection.

const DECK_NAME_KEY: String = "REWARD_GRANDPA_DECK_NAME"

## The deck being handed over. Defaults to the fixed starting deck, which is
## Grandpa's; set it to the boss's own definition to keep the two in one place.
@export var boss: BossDefinition

func _on_reward_ready(granted_now: bool) -> void:
	if !granted_now:
		return

	var stamp_names: Array[String] = boss.get_deck_stamp_names() if boss != null else DeckManager.create_starting_deck()
	_top_up_collection(stamp_names)
	_ensure_saved_deck(stamp_names)

## The cards dealt onto the table: the deck itself, duplicates included, in
## draw order.
func get_presented_stamps() -> Array[Stamp]:
	var stamps: Array[Stamp] = []
	if boss != null:
		for stamp in boss.deck_stamps:
			if stamp != null:
				stamps.append(stamp)
	if stamps.is_empty():
		for stamp_name in DeckManager.create_starting_deck():
			var stamp: Stamp = StampLibrary.get_stamp(stamp_name)
			if stamp != null:
				stamps.append(stamp)
	return stamps

## Brings each stamp's owned count up to how many copies the deck plays.
func _top_up_collection(stamp_names: Array[String]) -> void:
	var wanted_counts: Dictionary = {}
	for stamp_name in stamp_names:
		wanted_counts[stamp_name] = int(wanted_counts.get(stamp_name, 0)) + 1

	for stamp_name in wanted_counts:
		var stamp: Stamp = StampLibrary.get_stamp(stamp_name)
		if stamp == null:
			continue
		var owned: int = PlayerCollectionStore.get_owned_count_for_stamp(stamp)
		for _i in range(maxi(0, int(wanted_counts[stamp_name]) - owned)):
			PlayerCollectionStore.add_local_stamp_copy(stamp_name)

## Saves the deck under Grandpa's name and makes it the selected deck, unless a
## deck with these exact stamps already exists (a re-entry, or the default
## "New" deck the store creates from the same list).
func _ensure_saved_deck(stamp_names: Array[String]) -> void:
	for deck in PlayerDeckStore.list_decks():
		if !(deck is Dictionary):
			continue
		if PlayerDeckStore.get_stamp_names_from_deck(deck) == stamp_names:
			GameConfig.set_selected_deck_id(str(deck.get("deck_id", "")))
			return

	var saved: Dictionary = PlayerDeckStore.save_new_deck(tr(DECK_NAME_KEY), stamp_names)
	var deck_id: String = str(saved.get("deck_id", ""))
	if !deck_id.is_empty():
		GameConfig.set_selected_deck_id(deck_id)
