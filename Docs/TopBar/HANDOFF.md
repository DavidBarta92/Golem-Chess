# Top bar redesign — handoff

Notes for whoever implements the new top bar in `Scenes/GlobalTopBar.tscn`.
The design is settled; nothing of it is in the game yet.

## What is where

| | |
| --- | --- |
| `design/README.md` | the design rules (Hungarian): colours, type, layout, ribbons, panel, menu, motion |
| `design/tokens.json` | every colour, size and spacing value, each with a usage note |
| `design/components/*.md` | one page per piece: TopBar, StatBlock, MenuButton, QuestRibbon, QuestPanel, QuestQueue, Icons, Button |
| `design/previews/*.html` | live sketches — open in a browser; ribbons, panel, menu and ordering are clickable |
| `design/reference/bundle.js`, `bundle.css` | how the sketches behave (ribbon drawing, panel open, FLIP slide). Reference only, not for the game |

The same system is published at <https://claude.ai/artifact/Br1X8STGmVHsgLeVpeKviv>.
`design/` has a `.gdignore`, so Godot does not import it.

## The design in short

The bar has two zones.

- **Left zone** — the logo on the main menu; on sub-screens **Back**, then that
  screen's own buttons right after it (Buy Packs lives here). It may shrink.
  Its items are stamped in and dissolve out on a scene change, and the logo
  writes itself (see Docs/Style/OVERRIDES.md, "The top bar's scene items").
- **Right group**, anchored to the right edge, right to left:
  **menu button → counters → quest ribbons**. Nothing screen-specific goes in
  here; the current overlap (Buy Packs under the rating) came from that.

**Menu button**: an icon-only square in the existing button style, on the main
menu only - elsewhere it stays in place, out of use. It opens a
dropdown, aligned to its right edge, with three groups:
Alpha Multiplayer (tagged temporary, in its own group so it can be removed in
one piece) · Settings, Tutorial · Exit. Settings, Exit and Alpha Multiplayer
leave the bar itself.

**Counters**: one block of 1–3, revealed by the story in this order:
**rank → coin → draw points**. Rank sits next to the menu; each new counter
appears at the left end of the block, the existing ones do not move.
Draw points are a circle with a pencil.

**Quest ribbons** hang from the top edge of the screen, past the bar's bottom
edge, like bookmarks.

- **Cut = quest type**: slanted cut = story, V-notch = reward, square
  crenellations = daily (24 hours).
- **Colour = reward**: story is always burgundy; reward and daily are gold
  (coins) or ink-blue (draw points) — the colour of the counter they fill.
- Every quest gives exactly one kind of reward, so a ribbon is always one colour.
- The reward's icon sits at the bottom of the ribbon; colour is never the only signal.
- **Order**: the oldest is on the right, next to the counters; each new one
  arrives on its left, dropping in from the top. When one goes (claimed or
  expired), the ribbons to its left slide one place right. The ribbons always
  stay right next to the counters, however many counters show.
- **At most 6** quests are active at once — the quest assignment guarantees
  it; the bar has no overflow state.
- States: rest, hover (drops a little), in progress (a stitch down the middle:
  solid = done, dashed = left), done (a seal with a tick, hangs lower and sways
  until claimed), expiring (daily under 1 hour: an hourglass badge),
  retracted (while another ribbon is open).

**Quest panel**: clicking a ribbon slides it down, and the description appears
on its right over a horizontal paper gradient, the same device as the card
descriptions; the ribbon becomes the panel's left edge. Content: type kicker →
title → italic text with the condition in bold → progress (dots up to 10
steps, a bar above) → reward, plus a **Claim** button when done. One panel at a
time; clicking the ribbon again, clicking elsewhere or Esc closes it. If it
does not fit on the right, it opens to the left.

## Sizes: design px → Godot units

The design was measured on a ~1900 px wide screenshot; the project's base
viewport is 1280×720. **Multiply design px by 0.75.** The current bar is 60
units tall, which is exactly the design's 80 px.

| token | design px | Godot |
| --- | --- | --- |
| `bar-height` | 80 | 60 |
| `button-size` (menu button square) | 52 | 39 (the current buttons are 40 — keep 40) |
| `ribbon-width` | 28 | 21 |
| `ribbon-rest` (from the top of the screen) | 96 | 72 |
| `ribbon-lift` / `ribbon-done-drop` | 6 / 12 | 4.5 / 9 |
| `tail-story` / `tail-reward` / `tail-daily` | 10 / 9 / 6 | 7.5 / 6.75 / 4.5 |
| `panel-width` / `panel-text` | 360 / 272 | 270 / 204 |
| `menu-width` / `menu-row` | 240 / 44 | 180 / 33 |
| gaps: ribbons `space-2`, groups and counters `space-6`, bar margin `space-8` | 8 / 24 / 32 | 6 / 18 / 24 |

Motion timings in `design/README.md` (Mozgás) are in milliseconds and carry over as they are.

## Use what the game already has

The sketches used stand-ins; the game's own versions win:

- **Ink**: `UiPalette.INK` (`#172c43`), not the sketch's `ink` (`#1f2733`).
- **Font**: Elms Sans from `Fonts/` via `ui/themes/global_theme.tres`, not Lexend.
- **Coin**: `Assets/coin.svg`. **Rank**: the existing `Scripts/Rating/RatingBadgeIcon.gd`.
- **Logo**: `Assets/golem_painted_vector_transparent_2.svg` as now.
- **Bar background**: keep `Shaders/top_bar_gradient.gdshader`.
- **Labels** go through `Localization/translations.csv` like the existing ones.
- New colours with no game equivalent: `story` `#7a2230`, `coin` `#e3b02a`,
  `coin-deep` `#8a5d00`, `draw` `#2c6e9e`, `urgent` `#b44a12`, and the panel
  gradient `#f2f1ea` at 96 % → 0 %. Their usage notes are in `design/tokens.json`.

## The current code

- `Scenes/GlobalTopBar.tscn` / `.gd` — a `CanvasLayer` autoload (layer 1200).
  It sits above the scene transition fade (1000) and the popup windows (1024).
  The scenes' paper texture (`PaperTextureLayer`, 1210) is printed over it,
  and the CRT pass (`Scenes/CrtOverlay.tscn`, `CANVAS_LAYER_MAX`) over
  everything.
  `SceneItemsClip` holds `MainMenuItems` and `CollectionItems` (the left zone
  plus, today, Settings/Exit/Alpha Multiplayer); `PointsHud` is the coin; the
  rating HUD is built in code (`_build_rating_hud`, fixed offsets
  `RATING_HUD_OFFSET_*`). The fixed offsets are what let things overlap — the
  right group should become one right-anchored `HBoxContainer`.
- Callers that rely on its API — keep these working or update them together:
  - `MainMenu.gd` → `show_main_menu(settings, exit, singleplayer, multiplayer)`,
    `points_label`, `refresh_points()`, and `top_background.size.y` for the
    settings dialog;
  - `Collection.gd` → `show_collection(back, buy_packs)`, `get_button("buy_packs")`;
  - `GameResultController.gd` → `refresh_rating()`;
  - `Scripts/Story/Rewards/CoinDropPresenter.gd` → `get_coin_global_center()`,
    `pulse_points_hud()`;
  - `Scripts/Story/FeatureHint.gd` → `top_bar_button_id`;
  - `Scripts/SceneTransition.gd`.
- There is a Quests screen (`QUESTS_BUTTON` in the translations), but I found
  no quest data model the ribbons could read, and no draw-point currency yet.

## Godot notes

- **Newest on the left**: insert ribbons and counters at index 0 of their
  `HBoxContainer` (`add_child` then `move_child(node, 0)`); the oldest stays last.
- **Ribbon**: a custom `Control` whose `_draw()` fills the body and draws the
  tail polygon plus a 1.5-unit ink outline on the sides and the cut (no top
  edge). The three tail outlines are in `tail()` in `design/reference/bundle.js`.
  Tween its height for hover, done, retract and open.
- **Sliding**: a container snaps children to their new place. Remember each
  ribbon's x before the change, wait one frame for the container to sort, then
  tween from the old x to the new one (what the sketches call FLIP).
- **Panel**: a `Control` with a `GradientTexture2D` or a small shader for the
  paper fade, positioned from the open ribbon's right edge, below the bar.
- **Menu**: a `PanelContainer` with a `StyleBoxFlat` (ink border, radius ≈ 7.5,
  paper fill) that closes on outside click and `ui_cancel`.

## Not decided yet

- Which story beat reveals each counter.
- Where quests come from: their data, assignment and the 6-quest cap.
- The design files still show the stand-ins (Lexend, sketch coin, plain-text
  logo); in the game, use the real ones listed above.
