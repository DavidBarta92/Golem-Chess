# Networking

What a networked match sends, where each kind of data belongs, and the rules
that break builds when they are forgotten.

## The pieces

| | |
| --- | --- |
| `Scenes/Multiplayer.gd` | Root of the match scene. Connects (direct ENet, the dedicated server's room, Steam), keeps who plays which side (`peer_player_ids`) and what each player brought (`peer_profiles`), and holds every RPC. |
| `Scripts/NetworkGameHost.gd` | The rules, on the machine that hosts (single player included). Applies actions, then sends the state. |
| `Scripts/Networking/GameStateSerializer.gd` | The state after every action, cut to what each player may know. |
| `Scripts/Networking/PlayerProfile.gd` | What a player brings to a match: name, codex, portrait. |
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
- **Per stamp, and the opponent may learn it only once the stamp shows** (the
  print a stamp is in): the player's choices travel to the host in the profile;
  `GameStateSerializer` puts the value next to the stamp wherever it writes a
  visible one. In the public profile it would list the whole codex.
- **An image** (a player's own drawing): only its hash goes into the profile or
  next to the stamp. The image needs a transfer of its own - asked for by hash,
  cached, sent in pieces if large - and never rides in the state.

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
- **Hidden information.** Both players' hands and codex pages go to both boards
  (`player_hands`, `player_codex_state`). A board shows only its own, but a
  modified client could read the other's. Worth closing before public matches.

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
