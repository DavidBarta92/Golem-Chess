class_name PlayerProfile
extends RefCounted

## What one player brings to a match. A joining player sends it to the host
## once (Multiplayer.register_player_profile and the server-room calls); a
## single-player match builds both players' here too.
##
## It has two faces, because the host and the opponent may know different
## things:
## - to_dict(): all of it, for the host, which deals from the deck.
## - to_public_dict(): what the other board may show, the name and the
##   portrait. The host sends both players' public faces to every board once,
##   when the match starts (NetworkGameHost.broadcast_player_profiles); they
##   never ride along in the state that goes out after every action.
##
## Per-player data still to come is a field here, a line in to_dict() and
## from_dict(), and a line in to_public_dict() if the opponent may see it.
## Two kinds do not belong here:
## - Anything about one stamp that the opponent may only learn once the stamp
##   is in play (the print it is in): sent in the public face it would list
##   the whole codex. The host keeps it here and puts it into the state next
##   to that stamp, when the stamp shows (GameStateSerializer).
## - An image: it needs its own transfer, by hash. Only the hash goes here.

const PUBLIC_DEFAULT_NAME: String = "Player"

var player_name: String = ""
var deck_stamp_names: Array[String] = []
## The print each of those stamps is in, alongside deck_stamp_names ("" or a
## short list: the standard print). For the host only: it puts a stamp's print
## into the state when the stamp shows, so the opponent never gets the list.
var deck_print_ids: Array[String] = []
## A PortraitConfig as a dictionary: the ids of the parts it is built from.
var portrait: Dictionary = {}

## This machine's player, as the menus set them up.
static func local() -> PlayerProfile:
	var profile := PlayerProfile.new()
	profile.player_name = GameConfig.get_local_player_name()
	profile.deck_stamp_names = GameConfig.get_selected_deck_stamp_names()
	profile.deck_print_ids = with_local_drawings(profile.deck_stamp_names, GameConfig.get_selected_deck_print_ids())
	profile.portrait = GameConfig.get_local_portrait_data()
	return profile

## The prints with this player's own drawing in place of the print, for every
## stamp they have drawn one for (DrawingStore).
static func with_local_drawings(stamp_names: Array, print_ids: Array) -> Array[String]:
	var output: Array[String] = []
	for index in range(stamp_names.size()):
		var print_id: String = str(print_ids[index]) if index < print_ids.size() else ""
		var stamp: Stamp = StampLibrary.get_stamp(str(stamp_names[index]))
		var drawing_print_id: String = DrawingStore.instance().get_local_print_id(stamp.stamp_code) if stamp != null else ""
		output.append(drawing_print_id if !drawing_print_id.is_empty() else print_id)
	return output

## The hashes of the drawings among the prints.
func get_drawing_hashes() -> Array[String]:
	var hashes: Array[String] = []
	for print_id in deck_print_ids:
		var drawing_hash: String = DrawingStore.hash_of_print_id(print_id)
		if !drawing_hash.is_empty() and !hashes.has(drawing_hash):
			hashes.append(drawing_hash)
	return hashes

## A profile as it arrived over the network. Whatever is missing or malformed
## falls back to a default, so a peer's profile is always usable; the portrait
## falls back to the default for fallback_player_id.
static func from_dict(data, fallback_player_id: int = 0) -> PlayerProfile:
	var source: Dictionary = data if data is Dictionary else {}
	var profile := PlayerProfile.new()
	profile.player_name = GameConfig.sanitize_player_name(str(source.get("name", "")))
	var deck_value = source.get("deck", [])
	if deck_value is Array:
		for stamp_name_value in deck_value:
			profile.deck_stamp_names.append(str(stamp_name_value))
	var prints_value = source.get("deck_prints", [])
	if prints_value is Array:
		for print_id_value in prints_value:
			profile.deck_print_ids.append(str(print_id_value))
	profile.portrait = PortraitLibrary.config_from_data_or_default(source.get("portrait", {}), fallback_player_id).to_dict()
	return profile

## What a board shows for a player nobody has a profile for.
static func default_public_dict(player_id: int) -> Dictionary:
	return {
		"name": TranslationServer.translate(PUBLIC_DEFAULT_NAME),
		"portrait": PortraitLibrary.get_default_portrait_for_player_id(player_id).to_dict(),
	}

func to_dict() -> Dictionary:
	return {
		"name": player_name,
		"deck": deck_stamp_names.duplicate(),
		"deck_prints": deck_print_ids.duplicate(),
		"portrait": portrait.duplicate(true),
	}

## The portrait goes through the same check as a received one, with the right
## player's default behind it, so what a board gets is always drawable.
func to_public_dict(player_id: int) -> Dictionary:
	return {
		"name": player_name,
		"portrait": PortraitLibrary.config_from_data_or_default(portrait, player_id).to_dict(),
	}
