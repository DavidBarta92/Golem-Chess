extends RefCounted

## Stands in for the Multiplayer scene when a board plays on a host of its own,
## with no network: the tutorial and the puzzles
## (TutorialMatchAdapter.start_local_host). NetworkGameHost asks it what it
## would ask the Multiplayer node - which board shows the match, who sits on
## which side, the players' names - and nothing more.

## The one peer is this machine, and its player is white.
var connected_peer_ids: Array = [1]
var peer_player_ids: Dictionary = {1: 0}
var match_board

func _init(board = null) -> void:
	match_board = board

func get_match_board():
	return match_board if match_board != null and is_instance_valid(match_board) else null

## No match log and no Codex bridge for these (NetworkGameHost).
func is_local_scripted_match() -> bool:
	return true

## The names and portraits the board already shows: a board on its own host
## keeps the ones its scene gave it. A side with no name yet is left out, and
## the board keeps whatever it has for it.
func get_public_player_profiles() -> Dictionary:
	var profiles: Dictionary = {}
	var board = get_match_board()
	if board == null:
		return profiles
	for player_id in [0, 1]:
		if !board.current_player_names.has(player_id):
			continue
		var portrait = board.current_player_portraits.get(player_id, null)
		profiles[player_id] = {
			"name": str(board.current_player_names[player_id]),
			"portrait": portrait.to_dict() if portrait != null and portrait.has_method("to_dict") else PortraitLibrary.get_default_portrait_for_player_id(player_id).to_dict(),
		}
	return profiles
