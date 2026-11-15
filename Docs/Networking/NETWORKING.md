# Networking

What a networked match sends, where each kind of data belongs, and the rules
that break builds when they are forgotten.

## The pieces

| | |
| --- | --- |
| `Scenes/Multiplayer.gd` | Root of the match scene. Connects (direct ENet, the dedicated server's room, Steam), keeps who plays which side (`peer_player_ids`) and what each player brought (`peer_profiles`), and holds every RPC. |
| `Scripts/NetworkGameHost.gd` | The rules, on the machine that hosts (single player included). Applies actions, then sends the state. |
| `Scripts/Networking/GameStateSerializer.gd` | The state after every action, cut to what each player may know. |
| `Scripts/Networking/PlayerProfile.gd` | What a player brings to a match: name, codex, the print of each stamp in it, portrait. |
| `Scripts/Networking/DrawingStore.gd` | The players' own drawings: this player's from the drawings folder, the others' by hash, cached on disk. |
| `Scripts/MatchState/ServerStateUpdateController.gd` | The board's end of both: `apply_state_data()` and `apply_player_profiles()`. |
| `Scripts/MatchState/LocalMatchLink.gd` | Stands in for the Multiplayer scene when the tutorial or a puzzle plays on a host of its own, with no network. |

Over Steam the same RPCs run on a `SteamMultiplayerPeer` instead of ENet, so
nothing below depends on how the players are connected.

## Two kinds of data

| | Once per match | After every action |
| --- | --- | --- |
| What | each player's `PlayerProfile` | `GameStateSerializer.serialize_for_player()` |
| Sent by | `NetworkGameHost.broadcast_player_profiles()`, from `initialize_game()` | `NetworkGameHost.broadcast_full_state()` |
| RPC | `receive_player_profiles` | `receive_game_state` |
| Read by | `apply_player_profiles()` | `apply_state_data()` |

A client sends its whole profile (`to_dict()`, codex included) to the host
once, after the version check: `register_player_profile`, or on the dedicated
server `enter_custom_server_room` / `join_custom_lobby`. The host passes on
only the public face (`to_public_dict()`: name and portrait). The boards keep
the profiles to the end, so the result still names a player who left.

## Adding data

- **Per player, fixed for the match, the opponent may see it:** a field on
  `PlayerProfile`, in `to_dict()`, `from_dict()` and `to_public_dict()`; read it
  in `apply_player_profiles()`.
- **Per player, only the host needs it:** a field in `to_dict()` and
  `from_dict()` only.
- **Per stamp, and the opponent may learn it only once the stamp shows:** as
  the print is (below). In the public profile it would list the whole codex.
- **An image:** only its hash travels with the data; the picture goes as the
  drawings do (below), never in the state.

## Prints

Which print a stamp is in (`StampPrint`: standard, foil, full art) is the
player's own choice per codex slot. It goes to the host in the profile
(`deck_print_ids`, alongside the stamp names) and from there travels with the
stamp: `GameStateData.player_codex_print_pages` has the same shape as the
codex pages, and every function that moves a stamp in or out of a page moves
its print too (`_print_page`); a stamp on a golem carries it as the meta
`print_id`; a stolen or given stamp keeps it (`last_removed_print_id`). The
state names it next to each stamp the viewer may see (`print_id` on a piece
and on an expiration, `player_hand_prints` for the viewer's own hand), the
board puts it on the `Stamp` it makes, and `StampVisual.set_stamp` shows a
stamp that names its print in that print. `""` is the standard print. The host
checks that a print is one of that stamp's; whether the player owns it is not
checked - it changes nothing but the look.

Not carried yet: the stamp flying back to a codex or between players
(`recent_stamp_transfers`) is drawn in its standard print.

## Drawings

A player's own drawing (`Docs/StampPainter/STAMP_PAINTER.md`) rides in the print
slot as `drawing:<sha-256 of the PNG>`, so it goes wherever a print goes. For
each stamp the newest proper drawing in the drawings folder is used
(`DrawingStore.get_local_print_id`), on every copy in the codex.

The picture itself travels once per machine, by hash: the host asks a
registering player for the pictures their profile names
(`request_missing_drawings_from`), and a board that has to show one it has not
got asks the host (`DrawingStore.drawing_wanted` -> `send_drawing_request`).
The answer comes in pieces of 30 kB (`send_drawing_chunk`); the receiver puts
them together, takes the result only if it is a PNG of the art's size, under
1.5 MB, with that very hash, and keeps it in `user://drawing_cache`. Until
then the stamp shows in its standard print and redraws when the picture lands
(`DrawingStore.drawing_ready`). The host takes pictures only from a player in
the match and only ones that player's profile names; a client only from the
host.

## Hidden information

A viewer's state holds their own hand and codex pages only. Of the other
player's it holds the page counts and the open page's index
(`GameStateSerializer.can_view_codex`). So nothing on a board may ask what the
other side holds: a scripted opponent's hand is read from the host
(`TutorialMatchAdapter.play_scripted_affix`). Still sent: the name of a stamp
on a golem hidden from the viewer (`hidden_stamps`), which the board uses to
show that stamp going on before the golem vanishes.

## Rules that bite

- **RPC numbering.** Godot numbers a node's RPCs by their sorted names and
  checks nothing across peers. `announce_client_version` and
  `announce_host_version` must stay the first two names alphabetically, with
  their signatures (Multiplayer.gd, region "Version handshake"). A build that
  adds, removes, renames or re-signs an RPC needs a new
  `application/config/version` in `project.godot`, or an older build with the
  same number misreads it. The profile change of 2026-11-13 added, renamed and
  re-signed RPCs, so it needs one.
- **The dedicated server** has to be redeployed whenever the version changes.

## Testing

- Two or three game instances on one machine - host and client, or a dedicated
  server and two clients - each driven by a `--script` harness and each with its
  own copy of the save (`APPDATA` pointed at a scratch folder). Run the clients
  windowed: under `--headless` a stamp running out never finishes its burn
  animation, and the match stalls there.
- After a player's first turn, a turn ends only with a move
  (`NetworkGameHost.can_end_turn_by_button`), so a harness has to move.
- The serialization can be compared without a network: two hosts with no
  multiplayer node, the same seeded legal actions
  (`CodexBridge.serialize_legal_actions`), and the serialized state of every
  viewer compared after each one.
