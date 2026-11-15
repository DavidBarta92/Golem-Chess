# The main menu

The main menu is Anna's shop, drawn in layers on the menu art's canvas
(1919x1077). Every layer is the full canvas with its drawing in place, so it
lines up with the room by itself. The scene lays each layer over the screen
like the background: scaled to cover it and centred. The menu's buttons are
drawings in the room, and the story brings them in one by one.

## The art

Everything the menu draws is in `Assets/MainMenu`:

| file | what it is |
| --- | --- |
| `mainmenu_bg_1.png` | the room's line art. The game does not load it: it is the source of the reveal mask |
| `mainmenu_bg_1_reveal_mask.png` | built from `bg_1`: how each line draws itself. `_reveal_debug.png` shows the strokes in colours |
| `mainmenu_bg_1color.png` | the room's colour, laid under the lines |
| `mainmenu_bg_2.png` | the room in front of the street, with the window panes cut out, so the opponent shows through the panes only |
| `mainmenu_opponent.png` | the opponent who walks up to the window |
| `mainmenu_*_button.png` | the buttons (below) |
| `mainmenu_*_cover.png` | what hides a button until the story unlocks it |
| `mainmenu_bourse_extra.png` | the Bourse's notices on the left wall, which come with its button |
| `Built/` | the buttons, covers and extras trimmed to their drawing (built) |
| `Anna/` | Anna ([ANNA.md](ANNA.md)) |

After changing any of them, run:

    python tools/build_main_menu_art.py

and let the editor import the new files. It trims every button, cover and
extra layer to its drawing into `Built/`, each with an `AtlasTexture` (`.tres`)
that puts the drawing back in its place on the full canvas. The scene uses
those. Loaded whole, each layer would take a screen-sized texture in video
memory (8 MB) for a few hundred pixels of drawing. The tool also remakes the
reveal mask when `mainmenu_bg_1.png` is newer than the mask. Until the tool has
run, the game still shows the old drawing.

## Opening the menu

- The room's lines draw themselves (the shader's `base_duration` 1.6 s plus
  `max_delay` 1.8 s on `BackgroundLines`).
- Meanwhile the buttons fade in, 0.4 s after the menu opens, over 1.4 s. A
  locked button with a cover is the exception: the cover fades in alone, and
  the button is put behind it only once the cover is whole, so it never shows
  through. An unlocked button has no cover and fades in with the rest.
- Once the last line has landed, the colour fades in under the lines over
  1.5 s, as on a comic page, through the same ink blot washes
  (`Shaders/ink_blot_washes.tres`).
- The opponent starts walking up to the window after 1 s (`MainMenuStreetView`),
  and Play takes clicks once he has arrived.

The timings are in the **Arriving** group on the `MainMenu` node
(`buttons_fade_delay`, `buttons_fade_seconds`, `colour_fade_seconds`). Anna
stands there from the start.

## The buttons

| button | drawing | feature | unlocked | before that | opens |
| --- | --- | --- | --- | --- | --- |
| `PlayButton` | the window frame | `play` | from the start | | the Play window ([Story/README.md](../../Story/README.md)) |
| `CollectionButton` | the books on the shelf | `collection` | after Boss 2 (`comic_ch00_collection`) | there, but takes no clicks | `Collection.tscn` |
| `PuzzlesButton` | the parcel in the shelf | `quests` | after Boss 8 (`comic_ch06_letter`) | not there | `Puzzles.tscn` |
| `BourseButton` | the notices on the window, with `BourseExtra` on the wall | `trade` | after Boss 10 (`comic_ch08_trade`) | not there, nor the wall's | `Bourse.tscn` |
| `MultiplayerButton` | the phone | `multiplayer` | after Boss 6 (`comic_ch04_phone_call`) | under a box | nothing yet: it takes no clicks |
| `DrawButton` | the drawing things | `draw` | when Boss 12 is beaten (`boss_12_match`) | under a box | the stamp painter |

A button the player has not clicked yet glows behind (its `FeatureHint`), until
the first click. The phone does not glow, because it takes no clicks. It will
glow once it does.

The buttons are `MainMenuFeatureButton`s (`Scenes/MainMenuFeatureButton.gd`):

- `feature_id`: the unlock the button waits for.
- `locked_look`: what the button looks like before the unlock: `SHOWN`,
  `HIDDEN` or `COVERED`.
- `cover_path`: the cover over a `COVERED` button.
- `extra_paths`: drawings that come and go with a `HIDDEN` button.
- `target_scene_path`: the screen the button opens.
- `available`: whether the button takes clicks once unlocked.

The button locks itself, so its `FeatureHint` has `lock_target_until_unlocked`
off. To make the phone work, give `MultiplayerButton` a `target_scene_path` and
tick `available`. Its hint then glows on its own.

## Adding a button

1. Draw it on the full canvas in its place, save it as
   `mainmenu_<name>_button.png` in `Assets/MainMenu` (and a
   `mainmenu_<name>_cover.png` if it needs one), and run the tool.
2. In `MainMenu.tscn`, copy `DrawButton` (and `DrawCover`) and point them at
   the new `.tres` files in `Built/`. A cover or an extra is a `TextureRect`
   over the whole menu (`expand_mode` ignore size, `stretch_mode` keep aspect
   covered, mouse ignored). The scene's order is the drawing order: put a
   cover after its button, and anything nearer the viewer later.
3. Give the button a feature: a constant in `StoryFeatures`, its id on the
   story node that unlocks it (`unlocks_feature`), and a glowing `FeatureHint`
   ([Story/README.md](../../Story/README.md), *Unlocking and introducing a menu
   button*).
