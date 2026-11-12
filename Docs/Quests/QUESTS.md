# Quests

The quests hang in the top bar as ribbons ([TopBar/HANDOFF.md](../TopBar/HANDOFF.md)).
There are three kinds:

| kind | in the save | where it comes from | runs out | reward |
| --- | --- | --- | --- | --- |
| story | `story` | a `QuestStoryNode` in the story | never | the story goes on |
| daily | `daily` | drawn from the templates, one a day | at local midnight | 80 coins |
| regular | `reward` | drawn from the templates, one a day while there are fewer than 3 | never | 40 coins |

The numbers are in `Quests/quest_settings.tres` (`QuestSettings`), so they can
change without code.

| | |
| --- | --- |
| `Scripts/QuestStore.gd` | autoload: the active quests and the schedule, `user://quests.json`; `record_event` |
| `Scripts/Quests/QuestDirector.gd` | a child of `QuestStore` (`QuestStore.director`): hands quests out, swaps, story quests |
| `Scripts/Quests/QuestCondition.gd` | the conditions: which event moves which, what the XY can be, what is available |
| `Scripts/Quests/QuestTemplate.gd` | one kind of daily or regular quest (`Quests/Templates/*.tres`) |
| `Scripts/Quests/QuestSettings.gd` | rewards, budgets, limits (`Quests/quest_settings.tres`) |
| `Scripts/Quests/QuestLibrary.gd` | finds the templates and the settings |
| `Scripts/Story/QuestStoryNode.gd` | a story beat that is a quest |

## What a quest asks for

Every quest that moves on by itself has a **condition** (what), a **param**
(the XY: which kind) and a **target** (the X: how many).

| condition | moved on by | param (empty: any) |
| --- | --- | --- |
| `WIN_MATCHES` | a match won | `singleplayer` / `multiplayer` |
| `PLAY_MATCHES` | a match finished, won or lost | `singleplayer` / `multiplayer` |
| `AFFIX_STAMPS` | a stamp the player puts on a golem of theirs | a set: `Animals`, `Flora`, … |
| `AFFIX_ROLE` | the same, of a role | a role: `Seeker`, `Shared`, `Se-tenant`, `Overseal` (needed) |
| `AFFIX_EFFECT` | the same, with an effect | an effect type: `bomb`, `frozen_squares`, … (needed) |
| `AFFIX_SPECIFIC` | the same, one stamp | a stamp's name (needed) |
| `CAPTURE_PIECES` | a move of the player's takes a golem | the capturing stamp's name |
| `LOSE_PIECES` | a move of the opponent's takes one of the player's | — |
| `PLACE_CROWNS` | the player crowns a golem (moving the crown counts too) | — |
| `WIN_WITH_STAMP` | a match won with the stamp in the codex played | a stamp's name (needed) |
| `CODEX_WITH_STAMP` | a codex saved with X copies of the stamp | a stamp's name (needed) |
| `BUY_PACKS` | packs bought in the Collection | a pack id |
| `LIST_LOTS` | a lot put up on the Bourse | — |
| `SELL_LOTS` | the price of a sold lot collected | — |
| `BUY_LOTS` | a stamp picked from one of the day's lots | — |
| `SOLVE_PUZZLES` | a puzzle solved for the first time | — |
| `OPEN_SCREEN` | a screen opened | `collection` / `bourse` / `puzzles` (needed) |

A match counts when a player of this machine's own plays it, the story's
included, but never the tutorial, a puzzle board or an AI batch. Captures and
losses are a move's: a bomb's do not count, as in the puzzles. The codex of
`WIN_WITH_STAMP` is the one played: the player's own, or the one the story lent.
`CODEX_WITH_STAMP` is a level, not a sum: its progress is the most copies a
saved codex has held.

**Where the XY comes from.** A template names its values in `param_pool`. A
template that names none, for a condition that needs one, takes them from
where the player stands (`QuestCondition.dynamic_params`):

- roles, effects, and stamps (`AFFIX_*`, `WIN_WITH_STAMP`): those in the
  player's playable codexes, Unit left out, so the quest can be done with a
  codex they have;
- `CODEX_WITH_STAMP`: a stamp the player owns that is in no codex, as a nudge
  to try it.

The events are reported where they happen, through
`QuestStore.record_event(event, data)`:

| event | reported by |
| --- | --- |
| `match_finished` | `GameResultController.record_quest_result` (with the codex played) |
| `stamp_affixed` | `QuestDirector`, from the board's `stamp_affixed` signal (it finds boards as they enter the tree) |
| `piece_captured`, `piece_lost` | `QuestDirector`, from the board's `piece_captured` signal |
| `crown_placed` | `QuestDirector`, from the crown controller's `crowned` signal |
| `codex_saved` | `PlayerDeckStore.save_new_deck` / `save_existing_deck` |
| `packs_bought` | `PlayerProgressStore.purchase_packs` |
| `lot_listed` | `BourseStore.list_lot` |
| `lot_sold` | `BourseStore.collect_lot` |
| `lot_bought` | `BourseStore.finish_pick` |
| `puzzle_solved` | `PuzzleController._solve`, on the first solve only |
| `screen_opened` | `QuestDirector`, from `SceneTree.scene_changed` |

**The board's capture and crown signals** (added for the quests, usable by
anything):

- `MatchBoard.piece_captured(by_color, captured_color, capturing_stamp_name,
  captured_stamp_name)`. In a match on a host it comes from the state: the
  host sends its last move with every update, so a capture is reported once,
  when a new last move with a captured colour arrives
  (`ServerStateUpdateController._report_new_capture`; not on the first state,
  which may carry an old move). The capturing stamp is read from the board
  before the update, since a stamp can run out on the very move. Without a
  host (tutorial, puzzles) `LocalMoveFlowController` emits it as the move is
  played. Checked against the match log over four AI matches: the same
  captures, sides and stamps.
- `CrownController.crowned(owner_color)`: when the host's state shows a colour
  has crowned this turn, or when a crown is placed in a match without a host
  (`crown_placed` comes only then).

**Adding a condition**: a value in `QuestCondition.Type` and `IDS`, its event
in `progress_for`, what it needs in `is_available`, its XY values in
`param_options`, and texts in `Localization/translations.csv`
(`QUEST_<ID>_TITLE`, `QUEST_<ID>_TEXT`, `QUEST_<ID>_PARAM_TEXT`, each with a
`_ONE` form for a count of one if the English needs it). Then report the event
from where it happens. A condition that needs an XY from the player's
state belongs in `needs_param` and `dynamic_params`; one that reaches a level
rather than adding steps, in `is_level`.

## Daily and regular quests

`QuestDirector.refresh()` runs when the top bar first shows its ribbons, every
minute after that, and whenever a quest is claimed or removed, a story node
finishes or a feature unlocks.

- **The daily**: the first refresh of a local day hands one out, unless an
  unfinished daily is still up. It runs out at the next local midnight. It is
  never the same template as yesterday's, unless nothing else can be done.
- **Regular quests**: one new a day, while there are fewer than `regular_max`
  (3). They never run out. If there are 3, the day's new one waits until one
  of them is claimed.
- **One place stays free for the story's quest**: the generated quests leave a
  place of the 6 empty while the story has none up.
- A regular quest is never the same template as one already up.

### Templates

Each `.tres` under `Quests/Templates/` is a `QuestTemplate`. A new one is in
the draw as soon as it is saved there.

- `template_id`: the save remembers it, so keep it once it has shipped.
- `condition`, and `param_pool`: the XY values to choose from. One is picked
  among those the player can do now (`QuestCondition.is_available`). For
  example, a set is asked for only if the player has a playable codex of it.
- `pools`: daily, regular or both. `weight`: how likely it is drawn.
- `requires_features`: `StoryFeatures` ids it waits for. Together with
  `is_available`, this is how the quests follow the story: Bourse quests come
  once the Bourse is open, puzzle quests once the letters are.
- `title`, `text`: empty means the condition's own texts.

### How big a quest is

The size of a quest is counted in **matches' worth of play**: the daily asks
for `daily_budget_matches` (3), a regular one for `regular_budget_matches`
(1.5, since it pays half). A template's `per_match` says how much of its
condition one match brings, and

    X = round(budget × per_match), rounded to round_to, between min_count and max_count

The `per_match` values come from the author's real matches against the AI
(60 since September 2026, in `ai_match_logs/matches.csv` and
`stamp_events.csv`):

| measured | value |
| --- | --- |
| a match | 4.8 min median, 5.4 mean |
| wins | 56–62 % of matches → `per_match` 0.55 |
| stamps the player affixes | 6.8 a match → 7 |
| golems the player captures | 0.92 a match → 0.9 |
| golems the player loses | 0.85 a match → 0.85 |

Estimates, not measured (the logs do not tell them apart yet):

| estimated | `per_match` | why |
| --- | --- | --- |
| crowns | 0.7 | the logs predate the crown rule |
| a role's stamps, an effect's | 1.2 | 7 affixes a match × a few copies of 15 in the codex |
| one stamp | 0.6 | 7 × one or two copies of 15 |

| template | daily | regular |
| --- | --- | --- |
| `win_matches` | 2 | 1 |
| `play_matches` | 3 | 2 |
| `affix_stamps` | 20 | 10 |
| `affix_stamps_of_set` | — | 10 |
| `affix_role`, `affix_effect` | 4 | 2 |
| `affix_specific` | — | 1 |
| `capture_pieces` | 3 | 1 |
| `lose_pieces` | — | 1 |
| `place_crowns` | 2 | 1 |
| `win_with_stamp` | — | 1 |
| `codex_with_stamp`, `buy_packs`, `list_lots`, `sell_lots`, `buy_lots`, `solve_puzzles` | — | 1 |

Some templates are rarer than others (`weight`): losing golems 0.4, the
Bourse's and the codex's 0.6, buying packs 0.6.

Three matches take a practised player about 15–20 minutes. A newer player is
slower. If the daily should really fill 45 minutes, raise
`daily_budget_matches`.

### Swapping

A regular quest that is not done shows **Swap** (Csere) in its panel, once a
day (`regular_swaps_per_day`). It is taken down and another regular quest goes
up in its place, of a template not already up. The daily and the story's
quests cannot be swapped.

## Story quests

A `QuestStoryNode` is a node in `Story/story_definition.tres` like the others
([Story/README.md](../../Story/README.md)). Fields: `condition`, `count`,
`param` (the inspector offers the values the condition takes), `title`, `text`
(empty: the condition's own; `{count}` and `{param}` work in them).

- When the story reaches it, its quest goes up as a story ribbon, with the key
  `story:` + the node's id.
- Until the quest is claimed, the story waits there. **Play** starts an
  ordinary match, as it does when the story has nothing waiting, and the
  node never blocks the hub.
- Claiming the quest completes the node (`StoryManager.complete_quest_node`).
  Its `unlocks_feature` / `unlocks_packs` come with the claim. With
  `auto_continue_after_completion` the next node starts at once.
- A node before it that chains into it (`auto_continue_after_completion`)
  puts the quest up and returns to the hub.

Example: "Open the Collection" is `OPEN_SCREEN` with param `collection`. The
node before it has to unlock the `collection` feature, so the button works.

## The save

`user://quests.json` holds, next to the quests, a `schedule`: which day the
daily and the regular quest last came (`daily_day`, `regular_day`), the last
daily's template, and today's swaps. A quest keeps `condition`, `param` and
`template`. Quests from before this (the developer window's samples) have no
condition and move on only by the developer buttons.

## Trying it

The developer window (A three times on the main menu, in a debug build),
Quests section:

- **+ Generated daily**, **+ Generated regular**: one drawn now, whatever the
  day. The regular limit and the free place for the story still hold.
- **New quest day**: forgets what today has handed out and swapped, then
  hands out what is due.
- The status line shows the swaps left today.

Run harnesses with `APPDATA` pointed at a copy of the save. The first look at
the bar hands out real quests and writes the schedule into `quests.json`.

## Open

- All 15 conditions of the first list are in, plus play matches and open a
  screen. The crown, role, effect and single-stamp sizes are estimates; the
  match logs could measure them once they record crowns and roles.
- A bomb's captures do not count for capture or loss quests.
- The reward is coins for both kinds; draw points are a setting away
  (`*_reward_kind`).
- Nothing tells the player that a new daily or regular quest has come, other
  than the ribbon dropping in.
