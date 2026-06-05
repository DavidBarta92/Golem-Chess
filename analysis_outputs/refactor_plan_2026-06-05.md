# Golem Refactor Plan

Date: 2026-06-05

## Summary

The largest maintainability issue is now `Scenes/MatchBoard.gd`. It has grown from the previous audit's 2706 lines / 208 functions to 8226 lines / 507 functions. It is no longer just a scene script; it contains board rendering, piece rendering, UI, animation systems, local optimistic game flow, server-state parsing, and leftover chess-era helpers.

The safest path is not a rewrite. The first goal should be to turn `MatchBoard.gd` into a thin match-scene orchestrator while extracting visual-only systems first. Rules and authoritative state should move only after there is a CLI validation path.

## Current Hotspots

| File | Lines | Functions | Notes |
| --- | ---: | ---: | --- |
| `Scenes/MatchBoard.gd` | 8226 | 507 | Highest priority. Mixed view, input, animation, state parsing, and local game flow. |
| `Scripts/AIMoveEvaluator.gd` | 3127 | 157 | Very large but domain-focused. Refactor after match scene is safer. |
| `Scenes/Deckbuilder.gd` | 1800 | 85 | Still large, but improved since pack/progress extraction. |
| `Scripts/NetworkGameHost.gd` | 1086 | 72 | Authoritative game flow plus serialization/logging. High-risk refactor target. |
| `Scripts/CardEffectResolver.gd` | 813 | 55 | Good central rules/effect layer, but broad. Should become more service-like over time. |
| `Scripts/CardVisual.gd` | 799 | 56 | Mostly isolated card visual behavior. |
| `Scenes/PortraitView.gd` | 639 | 51 | Domain-focused and acceptable for now. |
| `Scripts/AIStateSimulator.gd` | 565 | 39 | Mirrors host behavior; divergence risk. |

## `MatchBoard.gd` Responsibility Map

Observed groups:

- Scene/node wiring, constants, exported tuning values.
- Board geometry, perspective projection, tile polygons, board frame, special tiles.
- Piece sprite creation, scaling, z-order, shadows, light occluders.
- Move dots, selected piece glow, last move markers, enemy attack markers.
- Card hand/deck UI, card hover preview, card description card, drag/drop/reorder.
- Hidden card preview UI and shader snapshot behavior.
- Player portraits, timer UI, action status UI, end-turn indicator, result overlay.
- Input handling and local user actions.
- Local optimistic card attach/move/exchange/refill behavior.
- Local versions of move-base, board-zone, respawn, duration, and winner helpers.
- Server state parsing, diffing previous/current visual state, and queueing animations.
- Piece movement pathing and occlusion.
- Shatter/respawn fragment animations.
- Attach/expire/freeze/bomb/capture visual effects.

Function prefix counts in `MatchBoard.gd`:

- `get_*`: 143
- `create_*`: 48
- `update_*`: 28
- `play_*`: 22
- `is_*`: 23
- `set_*`: 18
- `apply_*`: 17
- `animate_*`: 11

This confirms the file is mostly a large visual/state orchestration layer rather than a focused gameplay rule script.

## Rule/View Separation

Current good foundations:

- `MoveRules.gd` is mostly pure movement/valid-action logic.
- `CardEffectResolver.gd` already owns many effect decisions, including base movement, bomb, board effects, card return, respawn queues, and visibility helpers.
- `GameState.gd` provides `GameStateData`, a shared state model.

Current risks:

- `MatchBoard.gd` still has local optimistic gameplay mutations that mirror host/effect logic.
- `NetworkGameHost.gd` is authoritative but also serializes state and logs events.
- `AIStateSimulator.gd` mirrors host behavior and still has some legacy direct helpers, such as simplified piece-only respawn simulation.

Target direction:

- View controllers should not decide rules.
- Authoritative gameplay decisions should live in `NetworkGameHost`, `CardEffectResolver`, `MoveRules`, or new shared services.
- The match scene should render a state and emit user intents.

## Chess-Era Names To Remove

Completed low-risk technical renames:

- `Scenes/MatchBoard.gd` is now the match board scene script.
- `Scenes/MatchBoard.tscn` is now the packed match board scene.
- The instantiated scene node is now `MatchBoard`.
- References were updated in `Scenes/main.tscn`, `Scenes/Tutorial.tscn`, `Scenes/Multiplayer.gd`, and `Scenes/TutorialController.gd`.

Likely dead/stale chess helpers in `MatchBoard.gd`:

- `is_in_check(king_pos)`
- `is_stalemate()`
- `set_move(..., promotion = null)` parameter
- `is_enemy`, `is_enemy_for_color`, `is_current_player_piece`, `is_own_piece` may be removable wrappers, but verify after extraction.

Higher-risk content/resource names:

- `Assets/white_knight.png`, `black_rook.png`, etc.
- `Cards/king_card.tres`, `rook_card.tres`, `pawn_card.tres`, etc.
- `PieceVisualSets/king.tres`
- main scene style resources still reference old chess piece textures.

Recommendation: do technical renames first. Asset/card resource renames should be a separate migration because `.tres`, `.tscn`, `.import`, card codes, saves, and collection/deck data may reference them.

## Suspected Cleanup Candidates

Static reference scan found these likely review candidates. Do not delete blindly; Godot callbacks, signals, and external tooling can hide references.

`Scenes/MatchBoard.gd`:

- `has_attached_card_this_turn`
- `apply_remote_card_attach`
- `is_enemy`
- `is_enemy_for_color`
- `is_current_player_piece`
- `is_own_piece`
- `is_in_check`
- `is_stalemate`

Other scripts:

- `GameState._init()` only contains `pass`.
- `Piece.tick_respawn_cooldown()` currently only contains `pass`.
- `AIStateSimulator.respawn_captured_piece_in_pieces()` and related helpers look like legacy/simple simulation paths; compare with `CardEffectResolver` before removing.
- Several `DebugLog.info` calls are still very chatty in gameplay/network paths. Keep diagnostics, but gate verbose logs behind categories or flags.

## Proposed Extraction Sequence

### Phase 0: Validation Setup

Goal: make refactors less scary.

1. Make Godot CLI available.
   - Current check: `godot` and `godot4` are not on PATH.
   - Working local path confirmed by project owner: `C:\Program Files\Godot\godot4.exe.exe`.
   - Confirmed project-load command:
     ```powershell
     $env:GODOT_BIN = "C:\Program Files\Godot\godot4.exe.exe"; & $env:GODOT_BIN --headless --path "C:\Users\barta\Documents\GitHub\Golem-Chess" --quit
     ```
   - Confirmed output starts with `Godot Engine v4.6.2.stable.official.71f334935`.
   - No test/addon directory was found.
   - Optionally add this executable directory to PATH later, but the explicit path is enough for refactor validation.
2. Document a local command:
   - `$env:GODOT_BIN = "C:\path\to\Godot_v4.6*.exe"`
   - `& $env:GODOT_BIN --headless --path . --quit`
3. Add a tiny CLI test runner later:
   - `& $env:GODOT_BIN --headless --path . --script res://Tests/cli/run_tests.gd`
4. First pure tests should cover:
   - `BoardConfig`
   - `MoveRules`
   - `CardEffectResolver` base move / bomb / respawn queue / visibility helpers
   - `GameStateData` serialization helpers once extracted

### Phase 1: Rename Without Behavior Change

Goal: remove chess naming while keeping behavior identical.

Status: completed for the scene script, packed scene, instantiated node name, and direct scene/script references.

1. Keep checking future changes against the new `MatchBoard` naming.
2. Avoid broad asset/resource renames until `.tres`, `.import`, saves, and deck data can be migrated safely.
3. Remove or rename stale chess helpers only after CLI load check passes.

### Phase 2: Extract Board Visuals

Goal: move low-risk visual code first.

Create:

- `Scripts/MatchView/BoardGeometry.gd`
- `Scripts/MatchView/BoardVisualController.gd`

Move first:

- board perspective/projection helpers
- tile polygon and UV helpers
- board frame/side/special tile visuals
- board markers and move dots

Reason: this is mostly deterministic drawing code and has lower gameplay risk.

### Phase 3: Extract Piece Visuals

Create:

- `Scripts/MatchView/PieceVisualController.gd`
- `Scripts/MatchView/PieceOcclusionController.gd`

Move:

- piece holder creation/update
- visual scale/texture filter
- depth/z-index calculation
- shadows and light occluders
- selected glow and freeze overlays

Keep `MatchBoard.gd` as owner of actual `piece_objects` until later.

### Phase 4: Extract Animators

Create:

- `Scripts/MatchView/PieceMoveAnimator.gd`
- `Scripts/MatchView/PieceShatterAnimator.gd`
- `Scripts/MatchView/PieceEffectAnimator.gd`
- `Scripts/MatchView/CardAnimationController.gd`

Move:

- movement routing and easing
- shatter fragments and respawn fragment travel
- capture flash
- attach/expire/freeze/bomb visual effects
- card draw/return/burn animations

Important: each animator should receive board geometry and scene nodes as dependencies instead of reaching into the whole match scene.

### Phase 5: Extract Card HUD

Create:

- `Scripts/MatchView/MatchCardHud.gd`
- `Scripts/MatchView/CardHoverPreviewController.gd`
- `Scripts/MatchView/HiddenCardPreviewController.gd`

Move:

- hand/deck UI creation
- card visual arrangement
- hover preview and description card
- hidden card preview list and shader snapshot
- deck counter UI
- card drag/drop/reorder signals

Risk: medium. This touches a lot of UI and input behavior.

### Phase 6: Extract Server State Adapter

Create:

- `Scripts/MatchState/MatchStateParser.gd`
- `Scripts/MatchState/MatchVisualDiff.gd`

Move:

- `parse_player_names`
- `parse_player_portraits`
- `parse_player_base_fields`
- `parse_board_effects`
- `parse_last_move`
- `value_to_vector2`
- visual snapshot/diff collection helpers
- pending animation event collection

Goal: `update_from_server_state()` should become orchestration, not parsing plus diffing plus rendering.

### Phase 7: Consolidate Gameplay Lifecycle

Create only after tests exist:

- `Scripts/Rules/CardLifecycleService.gd`
- `Scripts/Rules/TurnLifecycleService.gd`
- maybe `Scripts/State/GameStateSerializer.gd`

Move/share:

- played card slot tracking
- refill/exchange/card return
- duration consumption
- captured piece respawn handling
- base-field validation
- winner/no-valid-action checks

Goal: reduce divergence between `NetworkGameHost.gd`, `AIStateSimulator.gd`, `CardEffectResolver.gd`, and the local match scene.

### Phase 8: Host/AI Convergence

1. Extract host serialization from `NetworkGameHost.gd`.
2. Make `AIStateSimulator` reuse shared lifecycle helpers.
3. Keep `AIMoveEvaluator.gd` behavior stable until rule convergence is tested.

## Manual Smoke Checklist

Run after each extraction chunk:

1. Player vs player local match loads.
2. Player vs AI match loads and turn timer does not appear.
3. Card attach animation works, including occlusion.
4. Move dots show active/passive state correctly.
5. Piece movement animation works for own and enemy pieces.
6. Capture triggers flash and shatter.
7. Respawn fragments go to home row or edge queue.
8. Bomb warning appears only on occupied bomb targets.
9. Move-base effect does nothing if target already has another base.
10. Nexus card returns to deck instead of burning.
11. Hidden/invisible card preview shader appears.
12. Deckbuilder still opens and saved decks load.

## Recommended First Work Item

Do not start by moving gameplay rules. Start with:

1. Add/document Godot CLI command.
2. Remove obviously stale chess helpers (`is_in_check`, `is_stalemate`, unused `promotion`) after a load check.
3. Extract `BoardGeometry` and `BoardVisualController`.

This should reduce file size and cognitive load without changing rules.
