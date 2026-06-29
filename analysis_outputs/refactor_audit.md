# Golem Chess Refactor Audit

Date: 2026-05-10

## Magyar rovid osszefoglalo

Az elso audit alapjan nem egy nagy, mindent atiro refaktor lenne a leghatekonyabb, hanem egy kis lepesekben vegzett tisztitas. A legfontosabb teendok:

1. `Scenes/chess.gd`: tul sok felelosseget visz egyszerre, erdemes belole eloszor a board/piece renderelest, majd a kartya-hand UI-t es a szerverallapot-parse logikat kivenni.
2. `Scenes/Collection.gd`: a masik fo refaktorcelpont. Egy fajlban van a scene binding, generated UI, deck editing, stamp browser, pack vasarlas/nyitas es progress UI.
3. Het darab tracked `*.tmp` scene fajl van a repoban; ezek valoszinuleg torolheto editor-maradvanyok.
4. Van konkret regi/halott kod: `_create_saved_deck_row_old()` a `Collection.gd`-ben, illetve `if false && ...` blokkok a `NetworkGameHost.gd`-ben.
5. Sok unconditional `print()` maradt aktiv gameplay/network pathokon; ezeket erdemes debug flag moge tenni.
6. A legnagyobb architekturaris kockazat, hogy a valodi host logika es az AI simulator hasonlo szabalyokat kulon implemental. Hosszu tavon a tiszta szabalylogikat kozos helperbe kell vinni.

Javasolt elso munkacsomag: `*.tmp` fajlok eltavolitasa, `_create_saved_deck_row_old()` torlese, disabled nexus setup blokkok torlese vagy config flagre cserelese, es debug print cleanup.

## Cleanup Status - 2026-05-10

Completed in the current cleanup pass:

- Removed the seven tracked `*.tmp` scene files.
- Added `*.tmp` to `.gitignore`.
- Removed `_create_saved_deck_row_old()` from `Scenes/Collection.gd`.
- Removed the no-op `_mark_generated_ui()` functions and calls from `Scenes/Collection.gd` and `Scenes/MainMenu.gd`.
- Removed the disabled starting Nexus setup blocks from `Scripts/NetworkGameHost.gd`.
- Added `Scripts/DebugLog.gd` and routed direct debug `print()` calls through it. Direct prints now remain only inside `DebugLog`.
- Manual Godot smoke test was run by the project owner after the cleanup pass, and it passed.
- Started the first Collection split by extracting pack/progress behavior into `Scenes/CollectionPackController.gd`. `Scenes/Collection.gd` now delegates pack purchase/opening, point display, pack inventory refresh, reward rolling, and pack result dialog behavior to that controller.

Not committed yet by project owner choice.

## MatchBoard Refactor Status - 2026-06-29

Completed in this MatchBoard pass:

- Extracted server-state visual completion into `Scripts/MatchState/ServerStateVisualUpdateController.gd`.
- `Scenes/MatchBoard.gd` now delegates bomb-warning delay, post-server-state animation sequencing, hidden last-move reveal, and pending attach cleanup to the new visual update controller.
- `Scripts/MatchState/ServerStateUpdateController.gd` still owns server-state application/parsing, but now hands visual completion to the dedicated controller.
- Extracted local stamp attach/exchange action handling into `Scripts/MatchState/LocalStampActionController.gd`.
- `Scenes/MatchBoard.gd` keeps compatibility wrapper methods for existing callbacks from `StampInteractionController`, but no longer contains the full stamp attach/apply implementation.
- `Scripts/MatchView/MatchBoardLifecycleController.gd` initializes both new controllers during MatchBoard startup.
- Added `Scripts/MatchView/VisualProcessTracker.gd` and moved active visual-process counters into it.
- Replaced direct `active_*` animation/process counter usage with `begin_visual_process()`, `finish_visual_process()`, and `has_active_visual_processes()`.
- `Scripts/MatchState/TurnFlowController.gd` now waits on the shared visual-process tracker instead of checking scattered MatchBoard counters.
- Extracted Codex UI and page state into `Scripts/MatchView/MatchCodexController.gd`.
- `Scenes/MatchBoard.gd` now keeps only thin Codex wrapper methods for existing collaborators.
- Updated `Scripts/MatchView/StampHandStateController.gd` to access Codex panel/pages through MatchBoard wrapper methods instead of direct MatchBoard Codex fields.
- Extracted board visual environment setup into `Scripts/MatchView/BoardEnvironmentController.gd`.
- `Scenes/MatchBoard.gd` now delegates ambient board lights, board shader overlay/backbuffer, shader material refresh, overlay rect calculation, and piece Kuwahara material creation to the environment controller.
- Pruned MatchBoard wrapper methods for Codex and board environment behavior after updating internal collaborators to call the owning controllers directly.
- Updated lifecycle, piece display, tutorial, turn flow/action, server state, local move/stamp, and stamp hand state controllers to use `get_match_codex_controller()` / `get_board_environment_controller()` directly where appropriate.
- Extracted piece texture resolution into `Scripts/MatchView/PieceTextureResolver.gd`.
- `PieceTextureResolver` now owns default piece texture selection, attached-stamp piece texture lookup, stamp preview textures, and piece visual-state snapshots.
- Moved piece holder refresh, visual sizing, respawn opacity, selected glow coordination, shadow, and light occluder application into `Scripts/MatchView/PieceDisplayController.gd`.
- Pruned the MatchBoard piece visual wrapper block for texture lookup, default texture checks, footprint metrics, depth/z-index, visual transforms, shadow, and occluder helpers.
- Extracted attach/move visual orchestration into `Scripts/MatchView/PieceEffectFlowController.gd`.
- `PieceEffectFlowController` now owns visible/hidden stamp attach setup, hidden attach morph result, state attach sequencing, local move transition visuals, server-state move visuals, capture placeholders, capture invisibility reveal, and move visual-process tracking.
- `Scripts/MatchState/LocalMoveFlowController.gd`, `Scripts/MatchState/LocalStampActionController.gd`, and `Scripts/MatchState/ServerStateVisualUpdateController.gd` now call the piece effect flow controller instead of MatchBoard visual wrappers.
- Pruned the shatter/respawn wrapper family from `Scenes/MatchBoard.gd`; local move/stamp flow, server-state update/visual update, piece display, and effect flow now call `PieceRespawnFragmentCoordinator` directly.
- Extracted light texture, piece-light position, and sprite texture bounds helpers into `Scripts/MatchView/PieceEffectGeometryController.gd`.
- `PieceMoveAnimator`, `PieceEffectAnimator`, `BoardEnvironmentController`, and `PieceDisplayController` now receive light/bounds behavior through the geometry controller instead of MatchBoard helper methods.
- Extracted small local gameplay helpers into `Scripts/MatchState/LocalGameplayController.gd`, including local move preview resolution, stamp-based move lookup, tutorial target filtering, and local played-stamp refill.
- `Scripts/MatchView/MatchInputController.gd` now asks the local gameplay controller for hover/selected move previews instead of calling MatchBoard move helpers.
- Godot headless smoke test passed after this refactor pass: `godot4.exe.exe --headless --path . --scene res://Scenes/main.tscn --quit-after 5`.
- Extracted MatchBoard controller construction/wiring into `Scripts/MatchView/MatchBoardControllerRegistry.gd`.
- `Scenes/MatchBoard.gd` now keeps stable getter facade methods, while controller instances, init order, and sync/config dictionaries live in the registry.
- `Scripts/MatchView/MatchBoardLifecycleController.gd` now initializes startup controllers through the registry instead of calling individual MatchBoard init methods.
- `Scenes/MatchBoard.gd` is now under the 2000-line target after the registry extraction.

Still worth doing later:

- Consider moving pending visual queues into a dedicated coordinator after the active-counter migration has had a smoke-test pass.
- Consider whether the remaining MatchBoard compatibility wrappers around input/HUD/stamp hand APIs should stay as scene-level facade methods or be pruned once all collaborators use controllers directly.

This is a first-pass audit focused on finding high-value cleanup and refactor targets after recent structural changes. It is intentionally conservative: items are grouped by risk so cleanup can start without destabilizing gameplay.

## Executive Summary

The codebase is still compact enough to refactor safely, but several scripts have grown into multi-responsibility modules. The highest-value work is not a broad rewrite; it is extracting clear subsystems from the two largest scene scripts, then consolidating duplicated game-flow helpers shared by local UI, network host, and AI simulation.

Top priorities:

1. Split `Scenes/chess.gd` responsibilities. It is 2706 lines with 208 functions and contains board rendering, UI, input, local game flow, server-state parsing, stamp animation, and move helpers.
2. Split `Scenes/Collection.gd` responsibilities. It is 1975 lines with 89 functions and now mixes scene binding, generated UI, stamp browsing, deck editing, pack purchase/opening, progress display, and layout behavior.
3. Remove tracked temporary scene files. Seven `*.tmp` files are currently tracked by git.
4. Remove or gate runtime debug prints. Network/gameplay paths still emit many unconditional `print()` calls.
5. Consolidate duplicated turn/stamp/state logic between `NetworkGameHost.gd`, `AIStateSimulator.gd`, `MoveRules.gd`, and `Scenes/chess.gd`.

Godot CLI validation could not be run from this environment because `godot` is not on PATH.

## Size And Complexity Hotspots

| File | Lines | Functions | Risk | Notes |
| --- | ---: | ---: | --- | --- |
| `Scenes/chess.gd` | 2706 | 208 | High | Central gameplay scene with too many responsibilities. |
| `Scenes/Collection.gd` | 1975 | 89 | High | UI, data operations, pack economy, deck editing, and responsive layout are mixed. |
| `Scripts/AIMoveEvaluator.gd` | 1182 | 60 | Medium/High | Scoring logic is large, but domain focused. Refactor after behavior checks. |
| `Scripts/NetworkGameHost.gd` | 1133 | 72 | High | Authoritative game flow, serialization, logging, and stamp lifecycle logic are mixed. |
| `Scripts/StampEffectResolver.gd` | 723 | 47 | Medium/High | Effect handling is domain focused but shares logic with host/simulator. |
| `Scripts/MatchCsvLogger.gd` | 577 | 32 | Medium | Logging normalization overlaps with other serialization helpers. |
| `Scripts/StampVisual.gd` | 561 | 45 | Medium | Visual behavior is sizeable but mostly isolated. |
| `Scripts/AIStateSimulator.gd` | 517 | 35 | Medium/High | Mirrors real game rules; divergence risk is important. |

## Immediate Cleanup Candidates

These should be safe if done in small commits and verified in Godot afterward.

### 1. Tracked temporary scene files

These files look like editor/temp artifacts and are tracked:

- `Scenes/board.tscn3834333426.tmp`
- `Scenes/board.tscn4597667203.tmp`
- `Scenes/board.tscn7073209188.tmp`
- `Scenes/main.tscn3398103455.tmp`
- `Scenes/main.tscn8338301778.tmp`
- `Scenes/main.tscn8366440746.tmp`
- `Scenes/main.tscn8604787053.tmp`

Recommended action:

- Confirm they are not intentionally used.
- Remove them from git.
- Add an ignore rule for `*.tmp` if Godot keeps producing these.

### 2. Dead/old code in `Collection.gd`

`Scenes/Collection.gd` contains both:

- `_create_saved_deck_row()` at line 1627
- `_create_saved_deck_row_old()` at line 1763

Only `_create_saved_deck_row()` is referenced by `_populate_saved_decks_list()`. `_create_saved_deck_row_old()` appears removable.

Also present:

- `_mark_generated_ui(_node: Node) -> void` is called in several places but currently only `pass`es. If it is no longer needed, remove the function and calls. If it is intended as future cleanup support, implement it or document the intent.

### 3. Disabled code in `NetworkGameHost.gd`

`Scripts/NetworkGameHost.gd` contains two permanently disabled branches:

- `if false && white_piece:`
- `if false && black_piece:`

This appears to be old starting-nexus setup. It should either be removed or turned into a named configuration flag if still useful for testing.

### 4. Debug prints in gameplay paths

Unconditional prints remain in active runtime paths:

- `Scenes/chess.gd`: 13 debug prints
- `Scenes/Multiplayer.gd`: 26 debug prints
- `Scripts/NetworkGameHost.gd`: 22 debug prints
- `Scripts/StampEffectResolver.gd`: 10 debug prints
- `Scripts/DeckManager.gd`: 7 debug prints
- `Scripts/Piece.gd`: 4 debug prints
- smaller counts in `StampLibrary.gd`, `GameController.gd`, `JoinMenu.gd`, `StampPrintLibrary.gd`

Recommended action:

- Add a small `DebugLog` helper or `GameConfig.debug_logging_enabled`.
- Keep warnings/errors for real failure cases.
- Gate verbose per-move/per-stamp logs.

## Main Refactor Targets

### `Scenes/chess.gd`

Current responsibilities observed:

- Board setup and tile rendering
- Piece rendering and marker rendering
- Mouse/input handling
- Stamp hand setup, drag/drop, reorder, hover, deck visual, hidden-stamp previews
- Local turn flow
- Server action sending
- Server state parsing
- Stamp transfer/expiration animations
- Winner/game-over handling
- AI-vs-AI batch transition handling
- Board effect and last-move marker rendering

Recommended extraction order:

1. `BoardView.gd`: board tile rendering, piece rendering, move dots, selected/last-move markers.
2. `StampHandView.gd`: hand/deck visuals, drag/drop signals, hover preview.
3. `GameStateViewAdapter.gd`: parse server state dictionaries into view-safe structures.
4. `GameResultFlow.gd` or helper methods: winner handling, AI batch continuation, reward grant.

Risk notes:

- Do not change gameplay rules while extracting UI/render code.
- `update_from_server_state()` is a good boundary: split parsing from rendering/animation, but keep behavior identical first.
- Many helper functions convert between `Vector2`, arrays, dictionaries, player ids, and colors. Move these only after tests/smoke checks exist.

### `Scenes/Collection.gd`

Current responsibilities observed:

- Scene node binding
- Generated UI construction
- Responsive layout
- Stamp browsing/filtering/pagination
- Stamp preview and hover descriptions
- Deck creation/edit/save/delete
- Owned-stamp validation
- Pack purchase/opening
- Progress and pack inventory UI

Recommended extraction order:

1. Done: remove `_create_saved_deck_row_old()` and decide `_mark_generated_ui()` fate.
2. Done: extract pack/progress behavior into `CollectionPackController.gd`. This is fairly isolated around `PlayerProgressStore` and `PlayerCollectionStore`.
3. Extract stamp browser pagination/filtering into `CollectionStampBrowser.gd`.
4. Extract saved deck list and selected deck editor into separate components.

Risk notes:

- Keep `PlayerDeckStore` as the source of truth during the first refactor.
- Avoid changing deck stamp dictionary shape during UI extraction.
- Pack rewards currently operate directly on print ids and collection store; preserve that contract.

### `Scripts/NetworkGameHost.gd`

Current responsibilities observed:

- Owns authoritative `GameStateData`
- Handles player actions
- Applies stamp effects and turn transitions
- Serializes per-viewer state
- Logs match/stamp/move events
- Broadcasts state
- Contains duplicate stamp/turn lifecycle helpers also mirrored in AI simulation

Recommended extraction order:

1. Extract state serialization to `GameStateSerializer.gd`.
2. Extract logging calls/context building to a host logger adapter.
3. Consolidate stamp return/refill/expiration helpers with AI simulator or a shared rules service.

Risk notes:

- This file is gameplay-authoritative. Refactor behind tests or repeated manual smoke checks.
- Serialization changes can break multiplayer visibility and hidden-stamp behavior.

### AI and Rules Layer

`AIStateSimulator.gd` mirrors real host behavior. This is useful for AI but dangerous if it drifts from `NetworkGameHost.gd`.

Recommended direction:

- Treat `MoveRules.gd` as the shared pure-rules layer.
- Move pure stamp lifecycle decisions into shared helpers where possible.
- Keep AI scoring in `AIMoveEvaluator.gd`, but move reusable simulation mechanics out of scoring.

Candidate duplication zones:

- `duplicate_*` helper families in `AIStateSimulator.gd`, `MatchCsvLogger.gd`, `NetworkGameHost.gd`, and `Scenes/Multiplayer.gd`.
- `Vector2` serialization/parsing in `NetworkGameHost.gd`, `Scenes/chess.gd`, `StampEffectResolver.gd`, and loggers.
- Stamp hand/deck refill and return behavior in `NetworkGameHost.gd`, `AIStateSimulator.gd`, `DeckManager.gd`, and local UI code.

## Architecture Observations

### Autoloads

Configured autoloads:

- `StampLibrary`
- `StampPrintLibrary`
- `PlayerCollectionStore`
- `PlayerDeckStore`
- `PlayerProgressStore`
- `GameConfig`
- `PlayerSettingsStore`
- `GameController`

This is reasonable for a small Godot project, but the stores are now strongly coupled:

- `PlayerDeckStore` calls `StampLibrary`, `StampPrintLibrary`, and `PlayerCollectionStore`.
- `PlayerCollectionStore` calls `StampLibrary` and `StampPrintLibrary`.
- `GameConfig` calls `PlayerDeckStore`.
- UI scenes call most stores directly.

Recommended direction:

- Keep autoloads for now.
- Avoid adding new cross-store dependencies.
- Consider a thin `DeckService` later if deck/collection/progress coupling keeps growing.

### `GameController`

`Scripts/GameController.gd` is tiny, but its comment says `LocalGameHost or NetworkGameHost`. No `LocalGameHost` was found. This is either stale terminology or a missing abstraction. Clarify before building more code around it.

## Suggested Refactor Sequence

### Phase 0: Validation setup

Goal: make refactors less scary.

- Add a short manual smoke checklist to `README.md`.
- If Godot CLI is available locally, document the exact command for project/script validation.
- Optional later: add minimal GDScript test runner for pure scripts like `MoveRules`, `BoardConfig`, `DeckManager`, and store normalization.

### Phase 1: Low-risk cleanup

1. Remove tracked `*.tmp` scene files.
2. Remove `_create_saved_deck_row_old()`.
3. Remove or implement no-op `_mark_generated_ui()` calls in `Collection.gd` and `MainMenu.gd`.
4. Remove `if false && ...` branches in `NetworkGameHost.gd`.
5. Gate debug prints.

### Phase 2: Collection split

Start here because the active editor tab is `Collection.gd`, and its risks are mostly UI/data-flow rather than core move rules.

1. Extract pack purchase/opening UI.
2. Extract stamp browser filtering/pagination.
3. Extract saved deck list rendering.
4. Keep final deck save/load calls in the scene until the UI split stabilizes.

### Phase 3: Chess scene split

1. Extract board/piece marker rendering.
2. Extract stamp hand view behavior.
3. Extract server-state parsing helpers.
4. Only after that, consider moving local gameplay helpers into shared rules/services.

### Phase 4: Host/simulator convergence

1. Extract `GameStateSerializer`.
2. Extract common stamp lifecycle helpers.
3. Compare `NetworkGameHost` and `AIStateSimulator` behavior for capture, expiration, refill, nexus return, board effects, and last move.

## First Recommended Work Item

Start with a cleanup PR/chunk:

- delete tracked `*.tmp` scene files,
- remove `_create_saved_deck_row_old()`,
- remove the disabled starting-nexus branches,
- add a debug flag or remove the noisiest debug prints.

This gives immediate cleanup value and creates confidence before touching the large behavioral files.
