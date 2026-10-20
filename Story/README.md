# Story mode

Everything the story plays is authored in the editor. This file is the map:
what lives where, and how to add the next chapter.

## The shape of it

`Story/story_definition.tres` is the whole story: an ordered list of chapters,
each an ordered list of **nodes**. `StoryManager` derives "where the player is"
as *the first node whose id is not in the completed set* — progress is never a
counter, so inserting or reordering nodes does not break existing saves. Node
ids are the save key, so **never rename an id that has shipped**.

Five node types:

| Node | Plays | Key fields |
| --- | --- | --- |
| `ComicStoryNode` | a run of comic pages | `page_paths: Array[String]` |
| `TutorialStoryNode` | the scripted tutorial match | `tutorial_scene_path` |
| `BossGameStoryNode` | a match against an authored opponent | `boss`, `defeat_behavior`, `defeat_page_paths` |
| `RandomMatchStoryNode` | warm-up matches against generated opponents | `match_count` |
| `SceneStoryNode` | any other beat that is just its own scene | `scene_path` |
| `RewardStoryNode` | the "you unlocked something" screen | `reward_scene_path` |

Nodes name their scenes by **path** (`@export_file`), never as a
`PackedScene`. `StoryManager` loads the whole definition at startup, and a
`PackedScene` reference would load every comic page, the tutorial and the
reward screens with all their art right then - over a gigabyte of textures
held for the whole session. A path is loaded only when its node plays.

Flags on every node:

- `auto_continue_after_completion` — finishing chains straight into the next
  node with no hub in between (comic → boss → reward). Off means finishing
  leaves the story, and it only continues the next time Play is pressed.
- `blocks_hub_until_completed` — launching the game jumps straight here instead
  of showing the main menu. The whole intro chapter is flagged, so the main menu
  first appears after Boss 2.
- `completion_scene_path` — where a non-chaining node lands instead of the hub. The
  Buy Pack explainer drops the player into the Collection next to the new
  button.
- `unlocks_feature` / `unlocks_packs` — applied when the node completes: a
  menu button (see *Unlocking and introducing a menu button*) and/or pack ids
  that become purchasable.

A comic node with no pages yet is skipped at runtime, so the ladder is
playable before the art exists.

A `SceneStoryNode` scene calls `StoryManager.finish_current_node()` when it is
done - that is its whole contract. The story opens with one
(`Scenes/Story/LanguageSelectScene.tscn`): a first-run language picker that
writes the choice into the same settings store the Settings menu reads, so the
two never disagree. It is a placeholder for a proper first-run panel.

### Losing a boss fight

The node never completes on a loss. What happens next is the boss node's
`defeat_behavior`:

- `PROMPT_RETRY` (the default) — a "play again right away?" prompt
  (`Scenes/Story/RetryPromptScene.tscn`). Yes restarts the fight, no returns to
  the hub, where Play brings it back.
- `COMIC_THEN_RETRY` — the node's `defeat_page_paths` play, then the fight restarts
  with no way out. Only for Boss 1 and 2, which happen before the hub exists.

### Warm-up matches

A `RandomMatchStoryNode` sits before a boss and needs `match_count` matches
*started* — not won — before it completes. Each press of Play runs one:

- a random opponent from `RandomOpponentFactory` — name from
  `Data/random_opponent_names.json` (surname first, Hungarian order), a
  generated portrait, and a random deck from `Decks/`;
- difficulty is the level of the last boss beaten (`difficulty_override` on
  the node pins it instead);
- win or lose, the match ends at the hub. The count is the node's attempt
  counter in the save, so this needs no state of its own.

`Decks/` holds `DeckDefinition` resources (`deck_id`, `set_name`, `stamps`),
loaded by the `DeckDefinitionLibrary` autoload. The thirty there are
single-set, 15 stamps, max two copies, two Seekers (borrowed `Prince` /
`Numero_3` for Structures and Celestials, which have none of their own) — the
same rules as the boss decks. Add more by dropping a `.tres` in the folder.

### The player's first deck

`DeckManager.STARTING_DECK` is Grandpa's deck (`Story/Bosses/boss_01.tres`),
card for card, and the default collection is empty: a new player borrows
Grandpa's stamps from the tutorial on. `Scenes/Reward/Reward01GrandpaDeck.tscn`
is where they formally become the player's — it tops the collection up to the
deck's counts and renames the default "New" deck, made from the same list on
the first run, to Grandpa's codex in the current language ("Nagypapa codexe"
in Hungarian). Keep the two lists in sync if the boss deck changes.

Before that the deck is only lent. The tutorial builds the player's codex from
`boss_01.tres` itself, and the first boss node has `lent_player_deck` set to
Grandpa: the player fights with his deck whatever their save has selected
(an older save's default deck may still hold an earlier starting list).

### Packs

The shop only lists packs the story has unlocked for this save
(`StoryProgressStore.unlocked_pack_ids`, filled by nodes' `unlocks_packs`),
on top of the pack's own `available` flag. A fresh save sees an empty shop
until the Buy Pack explainer after Boss 3. The Basic Pack is never unlocked and
is on its way out.

## Adding a boss

1. Duplicate one of `Story/Bosses/boss_NN.tres`.
2. Set `boss_id`, `display_name` and `ai_difficulty_level` (1–12).
   Leave `localize_display_name` off for a proper name that should read the
   same in every language; tick it to treat `display_name` as a translation
   key looked up in `Localization/translations.csv`.
3. Portrait: tick **Fill portrait from generator** to get a real
   `PortraitConfig` in the slot, then edit its parts and colours like any other
   portrait. Leave the slot empty and the boss uses a generated face.
4. Deck: drag `Stamp` resources from `Stamps/` into `deck_stamps`, in draw
   order. Leave it empty and the boss plays `DeckManager.STARTING_DECK`.
   Either way a boss **never** touches the player's saved decks or collection.
5. Point a `BossGameStoryNode` in `story_definition.tres` at the new `.tres`.

## Boss dialogue

Every boss speaks through the opponent panel the match HUD already builds, so
lines simply open a text box under the opponent's name and portrait, type
themselves out, and close again. They never take clicks — the match carries on
underneath. All of it is driven by `BossDialogueDirector`, which sits in
`Scenes/main.tscn` and removes itself when the match is not a story fight.

Lines are translation keys unless the boss has `localize_lines` turned off.

### The set pieces

| Field | When |
| --- | --- |
| `intro_lines` | as the match opens |
| `victory_lines` | the **boss** won, i.e. the player lost |
| `defeat_lines` | the **boss** lost, i.e. the player won |

One variant is picked per firing, and never the same one twice in a row — the
last index used is remembered per boss for the whole session, so a boss does
not greet the player with the same line two fights running.

The closing lines land in different places, because the two paths end
differently: on a **win** the line is handed to the reward scene and spoken
there by the boss (with the boss's own portrait) before the reward's own
dialogue; on a **loss** there is no reward scene, so the boss speaks it over
the finished board during the wait before the defeat comic.

### Reactions

`reactions` holds one `BossReaction` per trigger. Each has its own `lines`, a
`chance`, and optionally `bypass_cooldown`.

| Trigger | Fires when | Default chance |
| --- | --- | --- |
| `entered_route_setup` | the AI settles into building a route | 0.4 |
| `entered_active_seeker_push` | the AI has a live Seeker heading for the player's base | 0.7 |
| `entered_endgame_seeker_finish` | the AI is low on resources and goes all in | 0.9 |
| `entered_soft_defense` | enemy pieces are gathering near the AI's base | 0.5 |
| `entered_emergency_defense` | the player can win next move, or their Seeker is close | 1.0, bypasses cooldown |
| `boss_captured_piece` | the boss takes a piece | 0.3 |
| `boss_piece_captured` | the player takes one of the boss's pieces | 0.35 |
| `stamp_played` | the boss affixes the stamp set on that entry | 0.8 |

The five `entered_*` triggers are the AI's own strategy modes, read straight
out of `AIStrategyDirector` — the AI is not modified to support this, its mode
is simply published on every turn. They fire on *entering* a mode, never while
it persists, or a boss would repeat itself for a whole defensive phase. The
AI's sixth mode, `opening`, has no trigger: that beat belongs to `intro_lines`.

`stamp_played` entries need a `stamp` assigned; one with an empty slot never
fires. Each boss ships with five of them, which is the "one line per notable
stamp" list.

### How often a boss speaks

Two things keep it from becoming noise:

- a **global cooldown** of 2 boss turns between any two lines — this is what
  actually stops two reactions landing on the same chaotic turn, and it counts
  the intro and the closing line too;
- a **per-trigger chance**, because the triggers are not equal: taking a piece
  happens constantly and is rarely worth a line, while being one move from
  losing happens once a match and should always land.

When several triggers fire on the same turn only one line comes out, chosen by
priority: a strategy shift beats a stamp, which beats yet another capture.
A trigger that loses its chance roll passes the turn to the next candidate
rather than silencing it — a low chance means "this kind of event is rarely
worth a line", not "this turn goes quiet".

Tuning lives in two places: the per-trigger `chance` in each boss `.tres`, and
`REACTION_COOLDOWN_TURNS` / the visible-duration constants at the top of
`Scripts/Story/BossDialogueDirector.gd`.

## Adding a comic page

### The art

Two PNGs per panel, same canvas size, the artwork already positioned on a
transparent background, named `<scene>_<n>_line.png` and `<scene>_<n>_color.png`
under `Assets/Comic/`. Because the transparency does the positioning, a panel is
just a full-rect node - nothing to place by hand.

Each line drawing needs a reveal mask generated from it:

```
python tools/generate_line_reveal_mask.py Assets/Comic/1_1_line.png
```

That writes `1_1_line_reveal_mask.png` next to it. Assign the **mask** to the
panel's `reveal_mask` (not the raw line art) and the colour png to
`fill_texture`. Re-run it whenever a drawing changes.

**A drawing that fades out needs `--threshold`.** The script only skeletonizes
ink above the threshold (0.4 by default); everything fainter still *renders*,
but it borrows its timing from whichever stroke happens to be nearest, so pale
areas pop in with an unrelated line somewhere else. If a drawing fades towards
its edges, lower the threshold until the pale lines get strokes of their own,
and open the `<name>_reveal_debug.png` it writes alongside: every line that
should draw itself wants its own colour, and there should be no speckle where
the paper is blank. Fewer strokes at a lower threshold is a good sign - it
means pale lines are joining up instead of breaking into dashes.

### Waiting for a click

A page that has been read and is waiting shows the player what to do: after
`idle_hint_seconds` (15 s) with no click, `Assets/left-click.png` fades up in
the bottom right of the drawing over a second, and is given one rock about its
centre so the eye catches it. Any click takes it away and puts the clock back
to zero.

The clock runs in `_process` rather than off a timer because "idle" is the
whole condition — nothing drawing, nothing typing, page not finished — and
that is easier to read once a frame than to arm and cancel at each of the half
dozen places a page moves on.

### The reveal

Every panel appears the same way: the line draws itself the way the main menu
background does, and once the ink has landed the colour fades in *under* it over
`fill_fade_duration` (1.5s), so the line art always stays on top. The panel only
counts as revealed when the colour has arrived too - clicking during either
stage snaps straight to the finished state.

### Building the page

1. **Scene → New Inherited Scene** from `Scenes/Comic/ComicPage.tscn`, saved
   under `Story/Comic/` (e.g. `ch00_intro_p01.tscn`).
2. Instance `Scenes/Comic/ComicPanel.tscn` under `Panels` once per panel, in
   reveal order, each anchored full-rect, with its mask and colour assigned.
3. The first panel reveals itself when the page opens; every later one waits
   for a click. `reveal_with_previous` on a panel joins it to the group above,
   for a beat that needs two panels at once.
4. Per panel: `delay_before` holds it back; `reveal_sfx_name` is the pen
   scratching away (defaults to `mainmenu_drawing`, so every panel on every
   page is audible without being set up - clear it for a silent panel) and is
   stopped when the ink lands so it tracks the drawing instead of ringing on
   over the next panel; `extra_sfx_name` is an optional one-shot for the beat
   itself, left to ring out.
5. Per page: `sfx_on_page_start`; `ambience_mode` (the match leaves the bed
   muffled, so a street-noise page has to ask for `OPEN`); `music_mode`
   (`SILENT` runs the page on ambience alone and puts the music back on the way
   out); `music_cue_on_start` / `music_cue_on_finish` (see *Music*);
   `end_hold_seconds`.

Nothing of a panel shows before it starts drawing. That needs saying because
the reveal is per stroke, each with its own random start delay: left at time
zero, the strokes that drew the shortest straw are already showing their first
pixels, which on a page with a couple of thousand strokes looks like specks
scattered over an empty panel. A reset panel is wound back behind every delay
*and* hidden outright.

Reveal order is scene-tree order, so reordering panels in the Scene dock
reorders the reveal. A panel with no art draws a dashed placeholder box in the
editor, so a page can be blocked out before the drawings exist.

### Panels that make way

A panel can be sent away by a later one: point its `hide_when_revealed` at the
panel whose drawing should remove it, and it fades out over `fade_out_seconds`
(1s) while that panel draws. Several panels can name the same trigger - scene 2
clears the page in waves that way. A click during the fade snaps it to gone,
along with the panel being drawn.

The fade cannot go through the panel's `modulate`: the line-reveal shader
writes `COLOR` from scratch and never reads it, so modulating a panel fades
only the colour underneath while the ink stays solid and then disappears in one
frame. `_set_panel_alpha()` drives both layers instead - the colour through its
modulate, the ink through its own `line_color` alpha, which is per-panel
because every panel builds its own material.

### Dialogue on a panel

A panel can carry dialogue: fill its `dialogue_lines` with `ComicDialogueLine`
resources (`speaker`, `text` - translation keys unless `localize` is off). More
than one is fine; the page steps through them before moving on to the next
panel. The text appears **as its panel starts drawing**, not after, so the
drawing and what is said about it arrive together.

A click is the only control. It snaps whatever is mid-animation to its end -
the ink, the panels on their way out, the typewriter - and once nothing is
moving it shows the next line, or the next panel. There is no Continue button.

`speaker_gap` on a line pulls the name and the words closer together. The
default spacing suits a wide box; a line squeezed between two drawings often
needs the tight one (`0`).

`dialogue_rect` says where that panel's text sits, in the page's 1280x720
design space. Only the top-left and the **width** are used: the height is left
to the text, so a two-word line does not sit in a tall empty frame and a long
one is never clipped. The authored height is the room the layout reserves, and
a line that outgrows it prints a warning naming the panel and the size it
needed. Leave the rect at zero size to use wherever the page's box was placed
in the editor.

Three things the boxes need that are easy to get wrong:

- A `Control` grows to meet its minimum size but never shrinks back, so the box
  is re-fitted after every line. Without that it keeps the height of the
  longest line so far, and the very first line - measured while the box is
  still hidden and has no width to wrap against - leaves it taller than the
  screen.
- Width is what shapes the column. Grandpa's long lines need 600px of height in
  a 205px column but only 300 in a 385px one, which is the difference between
  running off the bottom and fitting comfortably.
- There are **two** boxes, `DialogueA` and `DialogueB`, taking turns. The
  outgoing line fades over `dialogue_fade_out_seconds` while the next panel is
  already drawing its own line somewhere else on the page, and one box cannot
  be in both states at once. Reusing a box kills its fade first, and a fade
  that finishes after its box has been handed a new line leaves it alone.

### Why text sits inside ArtFrame

Panels fill the screen and their textures are `KEEP_ASPECT_CENTERED`, so the
artwork scales and re-centres when the window is resized. Anything anchored to
the viewport instead - a text box, a button - would drift across the picture as
that happens. `ArtFrame` is a `design_size` (1280x720) rectangle that is scaled
and centred exactly the way the artwork is, and the dialogue and Continue
button live inside it. Author their offsets in that 1280x720 space and they
stay put on the picture at any window size; at the project's base window the
scale is 1, so what you place is what you get.

## Adding a reward scene

**Scene → New Inherited Scene** from `Scenes/Reward/RewardScene.tscn`, saved
under `Scenes/Reward/`. The base gives you the left column (preset image on
top, character dialogue underneath) and an empty `RightColumn` — build whatever
that particular reward needs in there, since every reward is its own scene.

Fields: `reward_id` (**must be unique and must never change once shipped** —
it is what stops a reward paying out twice), `reward_image`, `speaker_name` /
`speaker_portrait` / `dialogue_lines`, and the payout: `unlocks_features`,
`grant_points`, `grant_pack_ids`, `grant_stamps`.

For custom behaviour, override `_on_reward_ready(granted_now)` (build the
right-hand visuals; `granted_now` is false on a re-entry, so skip the fanfare)
and `_on_reward_finished()`.

The seven in the story, all inherited from `RewardScene.tscn`:

| Scene | After | Pays out |
| --- | --- | --- |
| `Reward01GrandpaDeck` | Boss 1 | Grandpa's 15 stamps become the player's deck |
| `Reward04Coins` | Boss 4 | 3 coins |
| `Reward05Stamp` / `07` / `09` | Boss 5 / 7 / 9 | the stamp set in `grant_stamps` |
| `Reward11Coins` | Boss 11 | 30 coins |
| `Reward12Final` | Boss 12 | 30 coins + the stamp in `grant_stamps` |

### Presenters

The animated centrepiece of a reward is a `RewardPresenter` node inside
`RightColumn`; the base scene finds it, starts it once the payout is recorded,
and only leaves when both the presentation and the dialogue are done. Three
kinds, in `Scripts/Story/Rewards/`:

| Presenter | Shows | Input |
| --- | --- | --- |
| `CardFlipPresenter` | every card from `get_presented_stamps()` dealt face down into a grid | click each card to flip it |
| `CoinDropPresenter` | `grant_points` coins (capped at `max_visible_coins`) dropped and bounced onto the table; the top bar shows just its coin counter | one click sends them flying into the counter, which counts up |
| `StampRevealPresenter` | the first `grant_stamps` entry flying in face down | one click flips it, with the attach glow blooming behind |

`SequencePresenter` runs child presenters one after another (the final reward:
coins, then the stamp). Timings, sounds and sizes are exports on each node.
The coin presenter puts the top bar into `GlobalTopBar.show_points_only()` so
the coins have a real counter to fly to.

## Music

The music is eight stems in `Audio/Music/` (`chords`, `chords_dreamy`, `color`,
`color_dreamy`, `drums`, `ostinato`, `pad`, `tune`), all the same length.
`MusicManager` starts every one of them silent when the game launches and
never stops them: they loop together in one `AudioStreamSynchronized`, so the
story only ever fades stems up and down, and anything that comes in lands in
time with what is already playing. A new stem is just a file dropped into the
folder; its loop is set up in code (the files have no loop points of their
own, and the importer brings them in with a loop end of 0).

A change is a `MusicCue` resource: a list of `MusicStemFade`s (stem, in/out,
seconds, delay) plus an optional ambience change (filter `OPEN` / `MUFFLED`,
and a volume in dB, applied through an amplify effect `AmbienceManager` adds
to the Ambience bus at runtime). The stem name `*` means every stem. Two fades
on the same stem in one cue run one after the other in delay order, so
"everything out over 4 s, then one stem back over 30 s" is two fades on that
stem with the second delayed by 4 s. A fade replaces whatever that stem was doing; stems a cue
does not name carry on.

Where cues are authored:

| Field | Fires |
| --- | --- |
| `ComicPanelView.music_cue` | as the panel starts drawing |
| `ComicDialogueLine.music_cue` | as the line appears |
| `ComicPageView.music_cue_on_start` / `_on_finish` | as the page opens / hands control back (the end button on a title card) |
| `TutorialIntro.music_cue_on_start` / `line_music_cues` | as the intro starts / as each `line_keys` entry appears (same order) |
| `BossDefinition.music_cue_on_match_start` | as the match scene opens |
| `BossDefinition.music_cue_on_defeat_line` | as the boss's parting line appears in the reward scene |
| `SceneMusicCue` node | as the scene it sits in opens (Collection); the Main Menu's has `play_on_ready` off and is started by `MainMenu.gd` only once the hub is really shown, because the menu is the game's first scene and forwards to the story while the hub is locked |

`MusicStemCycle` (in the Main Menu) brings one stem in and out on its own
timer - the chords come in, stay a minute, go, and come back after a quiet
minute or two - and takes it away when the scene closes; in the Main Menu it waits for `start()` the same way.

The intro chapter's cues are in `ch00_intro_p01` (panel 2), `ch00_memory_p01`
(two of Gabi's and Grandpa's lines), `TutorialIntro.tscn`, `boss_01.tres` and
`ch00_bridge_p01` (page start, two lines, the title card's button). Starting
the game part-way through the story starts the music from silence, not from
where that point of the story would have left it.

## Unlocking and introducing a menu button

A "feature" is a button the story unlocks and then points at. Ids live in
`Scripts/Story/StoryFeatures.gd` (`play`, `collection`, `buy_packs`, `multiplayer`, `quests`, `trade`). The last three open placeholder screens (`Scenes/Quests.tscn`, `Trade.tscn`, `StoryMultiplayer.tscn` — a title and a Back button) from plain buttons in the main menu's `StoryButtons` box; replace the buttons with artwork and the screens with real ones when they are designed.

To gate and introduce a new button:

1. Add a constant to `StoryFeatures` and list it in `ALL_FEATURE_IDS`.
2. Add a `FeatureHint` node to the scene that owns the button, set
   `feature_id` and `target_path` (or `top_bar_button_id` for a
   `GlobalTopBar` button), and pick `arrow_side` / `arrow_offset`.
3. Put the feature id in some reward scene's `unlocks_features`.

The hint then handles all three states on its own: locked → the button is
disabled; unlocked → an ink arrow bobs next to it; clicked once → the arrow is
gone for good. Set `lock_target_until_unlocked = false` for a button that
should stay usable and only wants the arrow (that is how Play is set up).

## Saves

`user://story_progress.json`, schema 3, written through `Scripts/SaveIO.gd`:

- `completed_node_ids`, `unlocked_features`, `seen_feature_hints`,
  `granted_reward_ids`, `node_attempts`, `unlocked_pack_ids`

All four save files (story, player progress, collection, decks) go through
`SaveIO`, which writes atomically (temp file, verify, swap) and stamps
`schema_version` / `updated_at_unix` / `device_id` into every file. Steam Cloud
integration should be a change inside `SaveIO` and nowhere else; the timestamp
and device id are there for its conflict resolution.

Note for existing saves: features are unlocked by the story, so a save made
before this existed starts with only `play` unlocked and has to earn the rest.

## Testing without playing through

`story_definition.tres` has a **Debug** group:

- `debug_jump_to_node_id` — treats everything before that node as completed.
- Per node, `force_completed` — treats just that node as completed.

Both are ignored in release builds. `StoryProgressStore.reset_progress()`
wipes story progress entirely.

## Warning before a move spends the turn

A move always ends the turn — `NetworkGameHost.handle_move` ends it as soon as
the move lands — so the click that moves a piece is the last moment at which a
stamp could still have gone onto a sleeping golem. That is easy to spend by
accident, so the move waits on a question first.

`TurnFlowController.should_warn_before_move()` decides whether to ask: the
setting is on, the turn is the player's, and `can_affix_action_now()` — a stamp
in hand and a golem with none to put it on. `MatchInputController` holds the
move while `MoveEndsTurnDialog` is up, and answers it three ways:

- **Ok** sends the held move
- **Cancel** drops it. Nothing has to be undone: the piece never moved, so the
  turn is still open and the stamp is still in hand
- **Don't show again** sends the move and turns the setting off for good
  (`WarnBeforeMoveEndsTurn` in the UI section of settings.cfg)

Note that the End Turn button is **not** where this belongs. It is not a free
way to end a turn: `NetworkGameHost.can_end_turn_by_button` only allows it on a
player's first turn once a stamp is on, or when a frozen piece has left them
with nothing else. A turn otherwise ends by being spent.

## The two tabs under the board

Turn Page and End Turn are no longer buttons sitting in a corner. They are
tabs pushed up through the bottom edge of the screen, under the board's near
corners — Turn Page on the left, End Turn on the right — and they say what is
open to the player by rising into view, rather than by going grey.
`Scripts/MatchView/MatchTabButton.gd` is the whole of it.

A tab is taller than it shows; the rest stays below the screen's edge, which
is what makes it read as a tab. `tab_height` and `raised_height` are the two
numbers that set that, and the face ends at its own black outline — there is
nothing drawn behind or around it. Sideways it is placed from `canvas_centre_x`
on the 1920x1080 canvas, so it stays under the board at any window shape; up
and down it is anchored to the screen's own bottom edge, because that is the
edge it pokes through.

A closing turn makes the same click whichever side closed it, and the click
belongs to the clock's rocker: `MatchClock.set_player_to_move` plays
`SWITCH_SOUND` on the frame the switch starts to tip, and makes no sound when
it is already where it is going. Hanging it on the movement rather than on
whatever caused the turn to end means every way of ending one sounds alike -
the End Turn button, a move that closes the turn, and the opponent's turn
coming back all throw the same switch. It used to hang on the button, which is
why closing a turn by *moving* was silent.

Nothing has to tell a tab when to move: it watches its own `disabled` and
slides itself. That is deliberate — the two buttons have their `disabled` set
from half a dozen places, and none of them should have to know a tab is
involved.

The P / A / M action letters, the "i" button and the rules panel it opened are
gone, along with their constants and the calls that kept them up to date.

## The codex's resting place

The player's codex is anchored to the middle of the screen's bottom edge, so
where it rests depends on the viewport's **width** — and the viewport's width
changes whenever the window changes shape, because the game stretches to
`expand`.

`codex_visual.gd` works its resting place out from the anchors, and works it
out again on every resize. It cannot simply read `position`: the moment
anything moves the codex — a hover lift, a page turn, the sink between turns
— `apply_position()` overwrites the offsets with `rest_position`. Capture that
once at startup, as it used to, and the first of those after a resize yanks the
codex to where it belonged at the old window size. It showed up as the codex
jumping sideways the first time a stamp was affixed, because reaching for the
codex hovers it.

## The codex counter in a match

The boxed panel that used to sit at the bottom of a match is gone. What is left
of it is two loose pieces, both under `CanvasLayer/CodexPanel` (now a plain
transparent Control) and driven by `MatchCodexController`:

- the **Turn Page button**, on the left edge of the screen
- the **page counter**, standing on the board's near rim — the band between the
  last playable row and the board's edge — placed from `BoardCanvas.RIM_CENTRE`
  so it follows the board at any window shape.

The **turn clocks** hang in the top right-hand corner, placed across from
`BoardCanvas.RIGHT_SIDE_X` and held against the top of the screen: two of them
in one drawn frame, the opponent above and the player below, ten minutes each.

The rule is the host's, not the interface's. `NetworkGameHost.process` takes
time off whoever is on the move and calls `finish_game` on the other player
when a clock reaches zero, so a client can never disagree about whose time ran
out. That used to be skipped in single player; it no longer is. The HUD counts
down its own copy only so the digits move smoothly between state syncs — the
host's figures overwrite it on every one.

The clock is three drawn sheets and two counters, stacked: the backing
(`Assets/clock_frame_back.png`) behind everything, the rocker, the counters,
and the tag (`Assets/clock_frame_double.png`) over the top. All three sheets
share one canvas, so each simply fills the clock and none has to be fitted to
the others — that is what keeps the digit cards' edges from showing against
the room.

The tag is a tag on a string.
`CLOCK_ART_SIZE`, `CLOCK_WINDOW_TOP`, `CLOCK_WINDOW_BOTTOM` and
`CLOCK_FACE_CENTRE` in `TurnHudController` are measured on that art —
re-measure them whenever it is redrawn.

Two things keep the clock steady while the drawing changes around it. The
scale comes from the **window height**, so a counter always fits a window
exactly and the slots stay the size they were however the art is resized; the
colon gap takes up the slack. And the clock is placed by `CLOCK_FACE_CENTRE`
rather than by the middle of the image, so drawing more tag — a longer string,
say — moves the artwork without moving the thing the player reads.

The whole thing moves as one object: `MatchClock` is the container and the
drawn tag and both counters are its children. Two movements, and they are not the
same kind: a gentle **tilt** about its middle the whole time, the codex's own
rhythm, and a sideways **swing** when the turn passes. The idle one is a tilt
because a slide has to go through the layout, which rounds it to whole pixels
— three pixels over four seconds then reads as stepping rather than floating.
The knock is large and quick enough that the rounding does not show. The turn
change is read from the turn colour every frame rather than from a signal,
because none fires on exactly that.

On its left is a **rocker**, `Assets/clock_frame_button.png`, tucked behind
the tag at the same scale. Its pivot is the red dot painted on the art
(`BUTTON_PIVOT`), set just inside the tag's left edge (`BUTTON_PIVOT_ON_FRAME`)
so the dot itself never shows and only the wedges to the left of it do. Upright
it shows the white wedge and the move is the player's; tipped by
`BUTTON_TILT_DEGREES` it carries the black wedge across and the move is the
opponent's. About sixteen logical pixels of it are in view — widen that by
moving the pivot right, not by moving the whole button.

`MatchClock` publishes `sway_offset` rather than moving itself: the clock's
place on screen is worked out from the canvas every frame by
`arrange_turn_timer_ui`, and two writers for one position would fight.

It sits at **z 890**, under the stamp previews and the flash a played stamp
makes (899 to 980), so those always read over it. The whole
thing is scaled so a window is exactly as tall as one counter, and each
counter is built with no frame and no colon of its own, because the drawing
supplies both and is laid over the top. The counter works out its own colon
gap from the width it is told to fill, since only it knows how wide a digit
is.

Each page's number sits in a square slot, and the page the player is on is
marked with a filled white disc behind black text; the rest keep the pale
colour they had, which reads against the dark rim. The disc is a `StyleBoxFlat` whose corner radius is half the
slot's side, which on a square slot is a circle.

**The tutorial still carries the older boxed layout**, so the controller reads
whichever it finds: slots mean the match layout, and it marks the current page
and stands the row on the rim; plain labels mean the tutorial's box, which
keeps its "Page 1 / 5" label, its gold highlight, and its place. `marks_current_page`
is the switch. When the tutorial is reworked, this fork goes.

## When the opponent is on screen

In a match the opponent is not a standing part of the interface. They appear
because they have something to say, and they go once it has been read.
`Scripts/MatchView/OpponentSpeechPanel.gd` owns that, driving the shared
`DialoguePanel` from outside so none of it leaks into the comics or the
tutorial, which use the same panel on their own terms.

One line's life:

1. the portrait frame draws itself, the face fades in behind it after
   `portrait_delay`, then the words after `speech_delay`
2. the words hold for `line_seconds` (15 s), counted down by a dial beneath
   them, in the corner the Continue button would occupy
3. pointing at the face or the words **stops that clock**, so a line being
   read never goes out from under the pointer; move away and it starts again
   where it left off
4. the face and the words fade out together over `fade_seconds` (1 s)

A second line arriving mid-hold does not restart any of this. Only the words
leave and come back — the speaker has not gone anywhere — and the hold starts
again. For the same reason a line already being up is no longer a reason for
`BossDialogueDirector` to stay quiet; the cooldown of two boss turns is what
keeps the boss from chattering.

Two details worth knowing:

- **The frame is `Assets/portrait_frame.png`**, a drawn rectangle, with its
  mask generated the way every other line layer's is:
  `python tools/generate_line_reveal_mask.py Assets/portrait_frame.png`. It is
  laid over the **picture's own edges**, and lined up by the stroke rather than
  by the file: the ink does not start at the png's border, and is not inset by
  the same amount on every side (`FRAME_ART_STROKE` holds the measured centre
  lines — re-measure them if the drawing is redone). It is laid over the
  picture rather than over the slot it sits in: the
  portrait keeps its aspect and is centred in that slot, which leaves about ten
  pixels of slack down each side. A container stretches its children to fill
  it, so the frame lives inside a holder the container can stretch and is
  placed by hand within that. It comes out thinner than it is drawn, the
  picture being smaller than the artwork. If the file is missing the step is skipped and the face
  opens the sequence instead. Its ink is faded through the shader's
  `line_color`, not through modulate, which the reveal shader never reads: that
  is the same trap the comic panels fell into.
- **The hover is read from the mouse position rather than from
  `mouse_entered`.** The panel lets every click through to the board underneath
  it, so it is never told when the pointer arrives. Nothing in the panel takes
  mouse input at all, which is what keeps a line sitting over the board from
  swallowing a click meant for a square.

The opponent's face now appears *only* when something speaks through this
panel. A match with no dialogue behind it — multiplayer, a random warm-up
opponent — therefore shows no opponent name or portrait at all.

## How a match comes on screen

A match opens the way a comic page does: the room draws itself, then the board,
then the pieces, then everything else. The sequence lives in one place,
`Scripts/MatchView/MatchIntroController.gd`, which both `Scenes/main.tscn` and
`Scenes/Tutorial.tscn` carry as a plain node next to the board.

### The room

`Scenes/MatchBackground.tscn` holds nine full-rect layers stacked back to
front, and `MatchBackgroundController` decides which of them a match uses:

- **KIOSK** (normal matches) — `Bg3`, `BgBody`, `BgTableBase`, `BgTableColor`,
  `BgTableLine`, `BgWindowColor`, `BgWindowLine`
- **MEMORY** (the tutorial) — `Bg4Line`, `Bg4Color`

A boss chooses its own room. `BossDefinition.room_variant` and
`show_opponent_codex` travel through `GameConfig.set_match_room()` and are
applied by `MatchIntroController._dress_the_room()` before the room draws
itself. Both Grandpa matches are played in MEMORY, and the first of them has
no opponent codex on the table yet. A warm-up match clears the setting and
gets the kiosk.

Pick one with the `variant` switch on the node; the editor draws whichever is
selected, fully revealed, so a room can be looked at without running the game.

Underneath them both is `PaperBase`, a plain white `ColorRect`, and the whole
background is modulated by the comic pages' paper tone,
`MatchBackgroundController.PAPER_TINT`. That constant is the single source:
the controller applies it to itself on ready, and the opponent's panel and the
clock take it too, so their whites are the same white as the room's rather
than a colder one laid over it. That one
multiply is what puts a match on the same paper the comics are printed on: the
flat white in `bg3` and `bg_table_base` comes out as paper, and the tutorial —
whose art covers barely a fifth of the screen — gets paper behind it instead of
the black it used to show. The line layers are unaffected, since the reveal
shader writes `COLOR` itself and never reads modulate.

The opponent's panel is dropped by `OPPONENT_PANEL_DROP` so its words land
below the drawn window rather than across its lower frame. That is set on this
panel alone, through `DialoguePanel.set_vertical_nudge` — the comics and the
tutorial share the scene and want it where it is.

`OpponentCodexSlot` sits between `BgBody` and `BgTableBase` and holds the
opponent's codex, so the table's edge covers its foot. Two things hang off
that, both of which broke when it was moved there:

- `MatchBoard` finds the codex with `find_child`, not by node path. A stale
  path fails silently and the codex simply stops moving for a whole match.
- how far it sinks between turns is measured against the table's edge
  (`TABLE_EDGE_CANVAS_Y`, taken from where `bg_table_base` and `bg_table_line`
  first cover it), not against its own height. Sinking by its own height used
  to leave a sliver of its top showing; behind the table it put the whole
  thing out of sight. The edge moves with the window's shape, so the distance
  is worked out again on every resize.

The codex itself is still placed in viewport coordinates rather than canvas
ones, so it drifts across the drawing as the window changes shape.

Each line layer uses a generated mask, not the raw drawing. The commands, which
have to be re-run whenever the art changes:

```
python tools/generate_line_reveal_mask.py Assets/bg_table_line.png
python tools/generate_line_reveal_mask.py Assets/board_grid_line.png
python tools/generate_line_reveal_mask.py Assets/bg4_line.png --threshold 0.06
```

`bg4_line` is drawn dark at the top and fades away towards the edges, so it
needs the lower threshold - see *A drawing that fades out* above. At the
default the pale two thirds of it contributed 715 pixels out of 19154 and would
not have drawn itself at all.

Each variant sorts its layers into four roles, in `KIOSK_LAYERS` /
`MEMORY_LAYERS`:

| role | what happens to it |
| --- | --- |
| `instant` | already there when the scene opens — the ink that frames the shot |
| `lines` | draws itself with the line-reveal shader |
| `far_colour` | fades in *while* the lines draw |
| `near_colour` | fades in once every line has landed |

### One canvas, two coordinate systems

This is the thing to understand before touching the board, and it is written
down in `Scripts/MatchView/BoardCanvas.gd`.

Every drawing in a match is authored on the same **1920x1080 canvas** and put on
screen the same way: scaled to cover the viewport, aspect kept, centred. How big
a canvas pixel is therefore depends on the window's shape — the game stretches
to `expand`, so a wider window makes the viewport wider and the art bigger.

The board is not a drawing. It is built in world space, under a camera, out of
numbers that do not know the window exists. So the two are tied together by one
rule:

> **one world unit is 4.86 canvas pixels, and the camera's zoom follows the
> canvas scale** (`zoom = 4.86 x cover`).

At a 16:9 window that works out to zoom 3.24, which is the scale everything in
a match was always tuned at, so piece heights, tile sink offsets, marker dots
and shadows all keep the size they have always had. At any other window shape
the drawings and the board now grow and shrink together. `MatchCamera` applies this and re-applies it when the window changes.

Two things follow, and breaking either pulls the board off the drawn table:

- **`BOARD_VISUAL_SCALE` must stay 1.0.** The board's size comes from the
  perspective constants, which are fitted in these units. A scale on the node
  multiplies the board *and its grid* without touching the art behind them —
  which is exactly the bug that made the board eight percent too big and the
  grid hang off the screen.
- **anything placed in world space to line up with a drawing** is positioned in
  canvas pixels over `PIXELS_PER_UNIT`, never in screen pixels.

### The board

Two things sit in the match scene rather than the background, because nothing
else can get between the tiles and the pieces — both live in the same world
canvas:

- `BoardGridOverlay` (in `Scenes/MatchBoard.tscn`, between `BoardTiles` and
  `Pieces`) draws the hand-drawn grid with the same shader as the background's
  line layers. It is turned 180° when the player is black, which cancels the
  camera's own rotation, so the drawing stays upright whichever side is played.

  It sits at **z 9**, which is the one slot between everything painted onto the
  board and everything standing on it. Under it: the base tiles, the special
  tiles, the danger and freeze tints, the markers, and the covers a tile slides
  under while it changes (z -24 to 8). Over it: the pieces (10 to 16), their
  effects (12) and the move option dots (20). The last-move arrow is the one
  marker that belongs over the grid rather than under it — it points at a
  square, so it has to be read against the lines — and it gets there by sitting
  in its own `LastMoveArrow` node at z 10, which still leaves it behind every
  piece. A new tile layer belongs below 9;
  anything that stands on a square belongs above it. The list is written out in
  the script.
- `BoardTiles` holds the whole board: `BoardFrame` (the outer frame strips and
  the darker side face the player looks onto), `BaseTiles` and `SpecialTiles`.
  Fading `BoardTiles` fades all of it, since `modulate` propagates.

The board's perspective is **fitted to the drawing**, not the other way round.
The constants in `Scenes/MatchBoard.gd` —
`BOARD_PERSPECTIVE_TOP_SCALE` / `_BOTTOM_SCALE` / `_VERTICAL_SCALE` /
`_NEAR_OFFSET`, `BOARD_FRAME_WIDTH`, `BOARD_FRAME_VERTICAL_EXTENSION`,
`BOARD_SIDE_THICKNESS` — were solved against the ink in
`Assets/board_grid_line.png`.

**What that drawing actually is matters, and it is easy to get wrong: it is a
9x9 grid, not a 7x7 one.** The playable board is the inner 7x7; the outer ring
of cells is the frame, which is why `BOARD_FRAME_WIDTH` and
`BOARD_FRAME_VERTICAL_EXTENSION` are both one cell. Every line in the drawing,
including the eight that bound the playable rows, runs the full width of the
ring. Read it as a 7x7 and the fit comes out 9/7 too wide: the tiles stop
landing on the drawn lines and the pieces straddle them.

With the right reading, all ten row lines land within 2 px of the ink on a
1920 px wide canvas, where the ink itself is 3 to 5 px thick, and the ten
column lines — which were never fitted, so they are a free check — fall within
3.7 px. **Redrawing the grid means re-fitting them**; changing them without
redrawing the grid pulls the tiles out of the drawing.

One wrinkle: `board_grid_line.png` is 1919x1077, not 1920x1080 like the rest of
the art, and is treated as a centred crop of the canvas. That leaves it about a
pixel low on screen. Re-exporting it at exactly 1920x1080 removes the last of
that error — and would need the constants re-fitted once more.

### The order

1. the table's lines and the board's grid draw themselves together (1.6 s a
   stroke, spread over 1.4 s), while the far colour fades in behind them
2. when the last stroke lands, the near colour and the board fade in together
   over 1.5 s, so the two read as one surface
3. halfway through that, the pieces arrive one at a time, 0.1 s apart, each
   with its shadow
4. then the rest of the interface — codex, stamp hand, portraits, deck counters

Steps 3 and 4 are driven off node lists, not off a scene layout:
`_get_piece_nodes()` takes the holders under `Pieces` that actually have a
texture (every square owns a holder whether or not a piece stands on it, so
the twelve starting pieces stagger over 1.2 s instead of forty-nine empty
squares over five), and `_get_hud_nodes()` takes the `CanvasItem` children of
the match's own `CanvasLayer`, which is where the HUD controllers build
themselves at runtime. Anything added to either later simply appears at full
opacity.

A piece's shadow needs handling of its own. It is not drawn but cast: a
`PointLight2D` parented to the piece, throwing the piece's occluder onto the
board. A light ignores modulate, so without this the twelve shadows sat on an
empty board from the moment the scene opened, waiting for their pieces. The
intro switches them off up front and tweens each one's `energy` back to its
authored value on the same delay and over the same time as the piece above it.

The timings are exported on the node (`board_fade_seconds`,
`piece_stagger_seconds`, `piece_fade_seconds`, `hud_fade_seconds`), and every
step is null-safe: a scene missing any of these parts still plays, just
without that step.
