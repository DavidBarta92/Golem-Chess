# Puzzles

Every puzzle arrives as a letter. The main menu's Puzzles button (the story
feature `quests`, `StoryFeatures.PUZZLES`) opens the letters; clicking an
envelope opens it, and the letter's button puts the puzzle's position on a
board. The look follows the mock-ups in [Docs/Letters](../Letters) (also as
`Golem – Bélyegbörze layoutok.pdf`).

| | |
| --- | --- |
| `Scenes/Puzzles.tscn`, `Scripts/Puzzles/PuzzlesScreen.gd` | the letters, eight to a page |
| `Scripts/Puzzles/LetterOpening.gd`, `LetterView.gd` | opening an envelope, and the letter |
| `Scripts/Puzzles/EnvelopeArt.gd`, `EnvelopeView.gd` | the four envelopes and the three marks, drawn in code |
| `Scenes/PuzzleMatch.tscn`, `Scripts/Puzzles/PuzzleController.gd`, `PuzzleHud.gd` | the board a puzzle is played on |
| `Scenes/PuzzleReward.tscn`, `Scripts/Puzzles/PuzzleRewardScreen.gd` | where a solved puzzle pays out |
| `Scripts/Puzzles/PuzzleDefinition.gd` + `PuzzlePiece`, `PuzzleGoal`, `PuzzleOpponentTurn` | the data |
| `Scripts/Puzzles/PuzzleLibrary.gd` | finds the puzzles under `res://Puzzles/` |
| `Scripts/Puzzles/PuzzleStore.gd` | what the player has done with them (`user://puzzles.json`) |

## Making a puzzle

In the FileSystem dock, right-click `Puzzles/` → *New Resource…* →
`PuzzleDefinition`, and save it there (subfolders are fine). The screen lists
every enabled one it finds, in `order`. Copying one of the three that are
there and changing it is the quickest start.

A puzzle with something wrong in it - no id, two golems on a square, a goal
pointing at a square nobody starts on - is left off the screen with a warning
in the Output panel saying what.

### The letter

- `puzzle_id` — the save remembers progress under it; never change it once
  the puzzle has shipped.
- `sender` — Grandpa, Edmund, Jakub or Darnell. It decides the envelope
  (Hungarian, British, Czech, American) and the name under it.
- `greeting`, `body`, `closing`, `signature`, `task` — each goes through the
  language files, so a key from `Localization/translations.csv` and plain
  text both work. An empty line in `body` starts a new paragraph (in the csv,
  `\n\n`). An empty `signature` signs with the sender's usual name. `task` is
  the one line shown under FELADVÁNY on the letter and on the board.

### The reward

`reward_kind` decides the mark in the envelope's corner too:

| reward | mark | fields |
| --- | --- | --- |
| `STAMP` | the stamp itself, stuck on a little crooked | `reward_stamp` (or `reward_print` for a foil or full art), `reward_amount` copies |
| `COINS` | a postmark struck with the coin's face, a 1 between laurels (`Assets/coin.svg`) | `reward_amount` |
| `DRAW_POINTS` | a red wax seal with a pencil | `reward_amount` |

A puzzle pays once, ever: replaying a solved one plays the reward scene
again, but the counters do not move and no stamp is added.

### The reward scene

Solving a puzzle leaves the board for `Scenes/PuzzleReward.tscn`, which pays
out by the reward:

- **Coins** fall into the picture over a golden glow (the story's
  `CoinDropPresenter`, handed the amount directly) and, on a click, fly up
  into the top bar's coin counter, which counts up as they land.
- **A draw point** appears in the middle and, on a click, flies up into the
  draw counter. A drawn animation is to come in its place.
- **A stamp**: the puzzle's envelope comes in with the stamp on it, ringed by
  a dashed die - a few straight sides at random angles, a new shape every
  time (`_make_die`). Followed round with the left button held, it cuts the
  stamp out, through `Scripts/Cutting` ([CUTTING.md](../Cutting/CUTTING.md)):
  the piece comes away with the line really drawn as its edge
  (`PolygonClip`), the envelope drops off the screen, the paper falls away,
  and the stamp comes to the middle on the pack opening's dark: a basic one
  floats, a foil gets the pack's blue-grey glow and run of light, a full art
  the pack's golden rays across the whole screen (`PackRevealFx`). A cut that
  strays more than `CUT_TOLERANCE` or does not go round heals, and says so.

The rarity comes from `reward_print` (a basic print without one). The glow
behind the coins is painted rather than added light, and the stamp's reveal
is played on the dark, because added light does not show on paper.

### The board

Squares are written as a chess player would, from the player's side: columns
`a`–`g` left to right, rows `1`–`7` from the player's base line to the
opponent's. `d1` is the player's base, `d7` the opponent's. The player is
always white and always moves first.

- `pieces` — one `PuzzlePiece` per golem: `side`, `square`, the `stamp` it
  wears (empty: bare), `moves_left` (-1: the stamp's own duration),
  `exhausted` (it may not move this turn), `crowned` (one per side at most).
  The inspector's list names each one ("Player d3 Knight (crowned)").
- `player_codex`, `opponent_codex` — page after page, three to a page; the
  first page is the open one. Leave an entry empty for an empty slot, so a
  stamp can be put on the second page on purpose.
- `player_crown_points`, `opponent_crown_points` — where the meters stand; 6
  is full.

The position is treated as the middle of a game: both sides have played a
turn, so the first-turn rules (a stamp first, End Turn after it) do not apply.
Every turn ends with a move, or with End Turn when no move is possible.

### The goal

`goals` all have to hold at once; `turn_limit` is how many of the player's
turns that may take. The puzzle is solved the moment the last goal is met -
checked after every stamp, crown and move - and failed when the turns run out,
the opponent wins, or the player is left with nothing to do.

| kind | holds when | reads |
| --- | --- | --- |
| `WIN_GAME` | a crowned golem of the player's steps onto the opponent's base | |
| `CAPTURE_PIECE` | the opponent golem that starts on `target_square` has been captured | `target_square` |
| `CAPTURE_COUNT` | the player's moves have captured `count` golems | `count` |
| `REACH_SQUARE` | a golem of the player's stands on `target_square` | `target_square`, `piece_square`, `stamp` |
| `STAMP_DURATION` | a golem of the player's has `count` moves left (`comparison`) | `count`, `comparison`, `piece_square`, `stamp` |
| `AFFIX_STAMP` | the player has affixed `stamp` (any if empty) `count` times | `stamp`, `count`, `piece_square` |
| `PLACE_CROWN` | the player has crowned a golem | `piece_square` |

`piece_square` names a golem by the square it *starts* on and follows it
wherever it goes. The inspector shows only the fields the chosen kind reads.
Captures count when the player's move takes a golem; a bomb's do not.

### The opponent

- `opponent_takes_chances` — before each of its turns the opponent wins if it
  can, or else captures one of the player's golems if it can: a crowned one
  first, then one a goal is about, then the one with most moves left. That is
  its whole defence; it does not look further ahead. Off: it only ever does
  what its script says.
- `opponent_turns` — its turns in order, one `PuzzleOpponentTurn` each:
  optionally a stamp from its open page onto one of its golems
  (`affix_stamp`, `affix_square`), then optionally a move (`move_from`,
  `move_to`). A move that is no longer possible is skipped with a warning;
  once the script runs out the opponent passes. Having nothing to do never
  loses it the game (`MatchBoard.scripted_turn_colors`).

The letter should tell the player what to expect of the opponent: Grandpa's
says his golem "never passes up a capture", Jakub's that his golems will not
stir.

## How the board plays it

`Scenes/PuzzleMatch.tscn` is the tutorial's scene without the tutorial:
the board runs locally, with no host, in tutorial mode (`hold_after_result`,
no rating, no story), on the plain white `MatchBackgroundController.Variant.PLAIN`
room, with no clock (`TurnHudController.clock_enabled`), no opponent codex and
no vignette. During the player's turns nothing is constrained; during the
opponent's, nothing may be touched. Restart sets the position up again in
place, or reloads the scene if the game is over or something is still moving.

**The local engine knows fewer stamp effects than the host does.** On the
puzzle board (and in the tutorial) these work: moving the base, forbidden and
frozen squares, invisibility, uncapturable, a stamp's own +1, and every
golem's +1/−1 (own or enemy - the War Drummer, the Warlord), on affix, on
move and on capture. These do **not** happen yet: stealing, granting or giving
stamps, bombs, crown points from effects, and the on-captured, on-expire,
symbol-count and crown-condition triggers. Build puzzles around the first
list, or add the effect to `LocalStateMutator.apply_stamp_effect_trigger`
first (`StampEffectResolver` has the host's version to follow).

## The three puzzles

Spoilers, for whoever changes them. Each was checked by brute force over every
way the player's turns can go, and played through in the game.

- **Grandpa — a trap** (`grandpa_01`, a Bishop). His crowned golem (Lance,
  2 moves) heads from d4 for your base, but takes any golem it can reach. No
  stamp in your codex can reach d2, where it is going. Put the Bishop on f1
  (or b1), and make the forced move with your Lance from e1 to e2 (or d3): he
  takes the bait, and the Bishop takes him there.
- **Edmund — win in two** (`edmund_01`, 3 draw points). Your crowned Knight on
  d3 has one move left, and the next one would win from c5 or e5. Turn the
  page, affix the War Drummer anywhere (every stamped golem +1), then Knight to
  c5 - the Bishop on f6 covers e5 - and to d7.
- **Jakub — patience** (`jakub_01`, 100 coins). The War Drummer in the a1
  corner (1 move, blocked by b2) has to reach 5 in three turns. The Warlord has
  to go on d3 in the first turn and the turn ends without a move; then two
  Warlord captures (+1 each) and both War Drummers from page two (+1 each),
  in either order. Start with the drummers and you reach 4.

## Tuning

- the open letter's timings, sizes and layout: constants at the top of
  `LetterOpening.gd` (the mock-up's CSS, scaled 1440 → 1280) and `LetterView.gd`
- the grid: `PuzzlesScreen.gd` (`ENVELOPE_WIDTH`, `HOVER_LIFT`, `TILTS`, …)
- the envelopes' and marks' colours and shapes: `EnvelopeArt.gd`, in the
  mock-ups' 320-unit view box. An envelope has no rim - only its shadow sets
  it off - and the lines inside it (a flap's edges, the folds) are the
  drawings' black (`EnvelopeArt.INK`), not the UI's blue
- the UI's ink stamp (`InkStampMaterial`) is on the pager arrows and dots,
  the letter's close button and board sketch, and the postmark; each draws
  its paper apart from its ink, so only the ink takes the specks
- the reward scene: the constants at the top of `PuzzleRewardScreen.gd` (the
  envelope's size, where its stamp sits, the die's margins, the cut's
  tolerance, the reveal's timings)
- the dark behind an open letter is the pack opening's
  (`PackOpeningOverlay.PACK_OVERLAY_DIM`), on the same layer
- the opponent's pace: the exports on `PuzzleController` in `PuzzleMatch.tscn`

All three scenes carry the paper texture overlay (`PaperTextureLayer`, layer
1210) the other scenes do; the board keeps its plain white under it.

## Open

- The signature is in Alegreya Italic; the mock-up's is a script face
  (Caveat), which the game does not have.
- Nothing in the story unlocks puzzles one by one: every enabled puzzle is
  there once the Puzzles button is.
- The opponent's defence is one move deep. A puzzle that needs real defence
  has to script it.
