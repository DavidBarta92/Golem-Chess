# UI styling: themes, roles and overrides

Where the UI's styling lives after steps 2 to 6 of
[STYLE_PLAN.md](STYLE_PLAN.md): the type roles, the theme type variations,
the theme lookup rules that decide where a new variation has to go, and every
override still set in a scene or script, with the reason.

- **Step 2** moved the static styling into theme type variations and changed
  no visible value. A dump of every value each Control resolves to (fonts,
  sizes, colours, constants, styleboxes, icons) was taken before and after,
  across all scenes in `Scenes/` and the live collection (browser, codex
  editor, shop) and top bar (every quest panel, the menu, a claim): 4131
  nodes, 0 differences. Pack cards and the few labels only built in a match
  were checked one by one, old overrides against the new variation.
- **Step 3** switched the UI from Elms Sans to Alegreya / Alegreya Sans
  through ten type roles. It was checked with before/after screenshots of the
  main menu, the top bar menu, the settings tabs, the collection, the codex
  editor, the shop, a placeholder screen, the match end panel and the
  tutorial, in Hungarian and English: no text overflows.
- **Step 4** switched both themes to the new palette and line weights, checked
  the same way. The collection theme's buttons, check boxes and fields were
  the new palette's first draft; the global theme now has them, so the
  collection theme keeps only its own variations.
- **Step 5** gave the UI's ink the stamp: framed controls and ink fills
  through `InkStampStyleBox` and baked prints, Display and Title text through
  a shader. Checked on screenshots at 1280x720 and 1920x1080.
- **Step 6** moved the top bar onto the shared palette and type, gave its
  ribbons, icons, pips, menu and claim button the stamp, and brought its
  icons and outlines to the 2-unit stroke. Checked on screenshots of every
  quest panel, the menu and the counters at both sizes, in Hungarian and
  English; the other screens are unchanged apart from the titles' speck
  patterns (their seed comes from the node's instance id).

## Ink stamp

**Frames and fills.** `Scripts/InkStamp/InkStampStyleBox.gd` is a StyleBox
that wraps a StyleBoxFlat - its `shape`, which holds the geometry and colours,
and gives the content margins, expand margins and shadow - and draws a print of
that shape. The prints are 9-patch PNGs in `ui/themes/stamp/`, baked by
`tools/generate_ink_stamps.py`, four variants per style. Edges and centre
tile, so a speck keeps its size on a control of any size. Each control draws
the variant its canvas item picks, so two neighbours rarely share a pattern.
The plan suggested long strips for this; with tiling, every control would
still start on the same stretch of the strip, so variants do the job. A
missing print falls back to drawing the shape plainly.

- The border and any ink fill get the specks; a paper fill stays whole (ink
  is taken away, never lightened). Ink fills, and the inside of a thick
  border, get half as many specks as a line.
- The shadow is drawn plainly, under the whole box when the box has a centre,
  as a StyleBoxFlat draws it. (Drawn only around the box, an offset shadow
  left an unshaded band under every window and dialog.)
- About 4-10 % of the ink is missing, drifting across a control; specks are
  0.35-0.75 units across, in clusters of one or two; edges wander by up to
  0.35 units. All of it is set by the constants at the top of the tool.
- A side with no border (a tab's open bottom, a dialog body's top) prints no
  ink: there the inner edge wanders with the outer one.
- **After changing a stamped style's shape** (a colour, a border, a radius),
  or after adding an `InkStampStyleBox`, run
  `python tools/generate_ink_stamps.py`. The editor imports the PNGs when it
  next gets focus.

Stamped: buttons in every state including focus, fields, tabs, panels,
dialogs, windows, popups, grabbers, progress bars, list selection, the codex
rows' round icon buttons (`CodexIconButton`), the match's tabs
(`MatchTabButton`), the collection's shop, pack
cards, stamp slots and deck preview, and the top bar's dropdown
(`TopBarDropdown`) and quest claim button. Not stamped: hairline separators,
the paper-shade fills with no border (tracks, check box hover, the top bar
menu's row hover), and the few boxes still built in code (the codex panel,
the stamp remove button). The collection's stamp count badge, also built in
code, is stamped through `InkStampMaterial` (an ink pill, so with the fill's
specks).

**Drawn items and titles.** `Shaders/ink_stamp.gdshader` takes ink away with
masks baked by the same tool (`ui/themes/stamp/ink_stamp_mask.png`: a line's
specks in red, the sparser specks of an ink fill in green), sampled in the
item's own pixels and shifted by an instance uniform per node.
`Scripts/InkStamp/InkStampMaterial.gd` holds the one shared material:
`apply(item)` stamps an item with its own seed, `apply(item, true)` with the
fill's specks for an item that is mostly ink fill, and
`apply(item, mostly_fill, true)` re-inks black UI art in `INK` first (black
becomes ink, white stays white) - the job `Shaders/ink_tint.gdshader` did
before it was removed.

- **Titles.** `Scripts/InkStamp/InkStampTitles.gd` (an autoload) stamps every
  Label whose font resolves to Display or Title, from whatever variation; a
  label that has a material of its own keeps it. Smaller text is not stamped.
- **The top bar's drawn items** stamp themselves in `_ready`: the icons
  (`TopBarIcon`, the counters' `RatingBadgeIcon`) with the line's specks, the
  ribbons and the quest panel's pips and track with the fill's. A ribbon pins
  its pattern to its foot (`InkStampMaterial.set_anchor`), so the specks
  travel with the cut when it is pulled down instead of the cut sliding over
  them. The coin (`Assets/coin.svg`) is game art, so it is not stamped.
- **Black UI art**, re-inked and stamped: the collection pager's arrows (a
  disc of ink, so with the fill's specks) and the codex buttons' icons.
- **In a match**: the active effects' icons in the bottom right corner
  (`BoardEffectIconGridController`; filled glyphs, so the fill's specks,
  under the cell's own half-transparent fade), and every dialogue's line
  beside the words (`DialoguePanel`'s `DialogueLine`).

## The top bar's scene items: stamped in, dissolved out

The bar's left zone (the logo and version on the main menu, Back and Buy
Packs on the collection) no longer slides in from above and out upwards.

- **Arriving**, each item is stamped onto the paper (`_stamp_items_in` in
  `Scenes/GlobalTopBar.gd`): from nothing, 30 % larger and turned 1.5-6
  degrees either way at random, it drops onto its place on an exponential
  ease-in - slowly, then all at once - in 0.42 s, fully opaque halfway down
  so the drop still shows. Items follow 0.07 s apart.
- **The main menu's logo** writes itself instead, left to right, the way the
  main menu's room draws itself: `Shaders/art_line_reveal.gdshader` (the
  room's line reveal, keeping the art's colours) with
  `Assets/golem_logo_reveal_mask.png`, made by
  `tools/generate_line_reveal_mask.py --ink-from-alpha --left-to-right` from
  `Assets/golem_logo_reveal_source.png` (the logo SVG rasterized at half
  size; the command is in the tool's docstring).
- **Leaving**, each item dissolves (`Shaders/ink_dissolve.gdshader`): the
  hover's ink front turned inside out - paper floods in over it from its
  edges along the same ragged front (`Shaders/ink_front.gdshaderinc`, shared
  with the hover) - while it fades, in 0.4 s. A clicked button's hover ink is
  taken away first (`InkHoverFill.clear`).
- **The menu button** stays on the collection, out of use, instead of
  leaving, so the counters and ribbons do not shift.
- **The pack shop**: while it is open, Buy Packs stays pressed in ink and
  Back is out of use (`GlobalTopBar.set_window_open`).

## Hover: the ink floods in

A hovered button fills with ink from its edges along a ragged front, like
ink spreading into paper, in 0.5 s (slow at both ends: the first blotches
creep in, the last islands of paper close slowly); when the pointer leaves,
the ink drains back out in 0.25 s. Pressing still fills at once - that is
the pressed style.

- `Scripts/InkStamp/InkHoverFill.gd` (an autoload) gives a button a layer
  behind it (`show_behind_parent`, an internal child, made on its first
  hover) drawn by `Shaders/ink_flood.gdshader`, so the outline and the label
  stay on top. The ink gets the stamp's fill specks, as the pressed print has.
  It follows `mouse_entered` / `mouse_exited` and also the button's own hover
  state each time the button redraws, for a button in an embedded window (the
  settings dialog's OK) that the pointer can reach without the signals.
- The front wanders by `ui/themes/stamp/ink_flood_noise.png` (blotches and a
  finer wander), sampled in the button's own pixels, so the blotches keep
  their size on any button. `tools/generate_ink_stamps.py` bakes it with the
  stamps; `FLOOD_BLOTCH_SCALE` / `FLOOD_WANDER_SCALE` there and `raggedness`
  in the shader set the look, `FILL_SECONDS` / `DRAIN_SECONDS` the timing.
- The label turns from ink to paper as the ink closes over the middle, where
  it sits: the autoload sets the label colours as overrides while the ink is
  in, and puts back the button's own overrides when it has drained. The top
  bar's menu glyph is a child, not the button's icon, so `TopBarMenu.gd`
  makes it follow the button's label colour.
- It floods the buttons drawn with the theme's plain hover - `Button`,
  `MenuButton`, `OptionButton` - and the match's tabs (`MatchTabButton`).
  Variations with a hover of their own (the codex rows' round buttons, pack
  cards, the top bar's menu rows), flat buttons and disabled buttons are left
  alone.

## Palette and line weight

`Scripts/UiPalette.gd` is the source; `ui/themes/global_theme.tres` repeats
the values. What each one is used for:

- **INK** - all text, outlines, icons, pressed fills, focus rings.
- **INK_SOFT** - secondary text, placeholders, hints, and the outline of a
  control one step back: unselected pack cards. Also the
  quest claim button's hover fill (the top bar design's hover, moved onto
  the palette).
- **INK_DISABLED** - disabled text, icons and outlines.
- **PAPER** - panels, dialogs, windows, menus, popups, the shop window, the
  top bar's dropdown and quest panel.
- **PAPER_RAISED** - field fills, the codex rows' round icon buttons, and
  light text or icons on ink (pressed buttons, selected text). Never pure
  white.
- **PAPER_HOVER** - the hover fill of what still has a fill (the round icon
  buttons).
- **PAPER_SHADE** - disabled fills, tracks, read-only
  fields, the shop's details panel, the selected pack card, the codex panel,
  and in the top bar the menu rows' hover (they darken), empty progress pips
  and the progress track.
- **LINE_SOFT** - hairline separators and list guides only.
- **INK_INACTIVE** (`#f0abb3`, on trial) - the outline, label and icon of
  inactive controls: disabled buttons (at 60 % opacity, so they also read as
  faded) and disabled tabs, whose fill is clear too. Other disabled controls
  keep `INK_DISABLED`.

**Dropdowns.** An `OptionButton` is a button like the others; its arrow
(`ui/themes/icons/option_arrow.svg`, white) is tinted with its label's
colour (`modulate_arrow`): ink at rest, paper when open (pressed) or flooded.
Its list is a `PopupMenu` with a panel of its own (`StyleBox_popup_menu`: the
popups' paper, stroke and shadow, no side padding) and an ink hover band
(`StyleBox_popup_menu_hover`) that runs from wall to wall; the items keep
their own padding (`item_start_padding` / `item_end_padding` 14). Only the
selected item shows a mark (`popup_radio_checked.svg`, a white dot; the
unchecked mark is an empty icon of the same size). A popup draws that mark
untinted, so `InkHoverFill` tints each radio item's mark with its label's
colour while the popup is open: ink, paper on the hovered item.

**Tabs follow the buttons.** An unselected tab is clear, its outline and
label in ink, like a button at rest; hovered, it stays clear with its top
edge thickened to 3; the selected tab is filled with ink and its label is
paper (`PAPER_RAISED`), like a button the hover's ink has flooded.

**Buttons have no fill.** `Button`, `MenuButton`, `OptionButton` and the
`SpinBox` arrows show only their outline and text, normal, hovered and
disabled alike (`draw_center = false` in their styles); hover thickens the
outline to 3, disabled draws outline and text in `INK_INACTIVE`, and only
pressed or toggled fills with ink.
Over a drawing, such as the main menu's, the drawing's lines show through.
Three kinds keep a fill: the codex rows' round icon buttons
(`CodexIconButton`), which sit on the codex's dark fold - they have the
Button weights (2, hover 3) round, on paper, with a paper halo outside the
ring (a shadow in paper colour) so the ring reads against the fold; the
quest claim button, the top bar's one primary action, in ink; and the shop's
pack cards.

**Windows** have a paper title bar like the rest of them, the title and the
close cross (`ui/themes/icons/window_close_ink.svg`) in ink, and a stroke
all round (`StyleBox_window`: its 38-unit expand margin holds the title).
No line under the title: the dialog body (`StyleBox_dialog_body`) has no top
edge, so title bar and body are one sheet. It has no shadow of its own (the
window casts one), and it reaches 4 units above the window's content
(`expand_margin_top`): an embedded window's content is rendered to a texture
of its own, where a half-transparent edge darkens, and the print's ragged top
edge left a faint line under the title until it was pushed out of the
content. The collection's shop window does
the same: its header (`ShopHeaderPanel`) draws nothing, title and cross in
ink.

**The collection's paper overlay** (`Shaders/paper_texture.gdshader`) now
covers the codex panel too; the cut-out it used to leave there is gone.

**The scene transition's fade** shows `PAPER` once the paper finish has
printed over it: the finish multiplies by its tint, which on the main menu
and the collection is the paper colour itself (their art is white), so the
fade is white there and `PAPER` where a scene has no tint
(`SceneTransition._sync_fade_colour`). It used to be `PAPER` under the tint
too, a shade darker than the menus.

Line weight at the 1280x720 base:

- **Stroke (2)** - every control's outline: buttons, fields, panels, tabs,
  dialogs, windows, grabbers, progress bars, pack cards, the top bar's
  dropdown; and what the top bar draws: ribbon outlines, the done seal, the
  urgent badge, the progress pips and track (`TopBarStyle.STROKE`).
- **Strong (3)** - the focus ring, a focused field, a hovered button, the
  selected and hovered tab's top edge, the selected pack card. Hover keeps
  thickening the outline by one, as it did from 1 to 2 before.
- **Hairline (1)** - separators, the top bar menu's too.
- **Icon stroke (2 at display size)** - `TopBarIcons` scales an icon's
  ordinary line so it shows as 2 whatever the icon's size, but never more
  than a seventh of the icon, so the smallest (the 9-unit check in the done
  seal, the hourglass in the urgent badge) keep their openings. For it to fit,
  the menu and counter icons grew from 15 / 18 to 20, the gear's middle
  circle shrank and the menu glyph's lines moved apart.

2 was compared against the main menu's line art and reads close to it, so the
stroke stayed at 2. Corner radii are as they were; the top bar's dropdown
took the popups' radius (5) and shadow instead of its own 8.

**Not on the palette.** The network status line over the match stays cream
with a black shadow, to read over the board. The codex row's "incomplete" red
carries meaning the palette has no colour for. Stamps keep their own
lettering colours. The top bar's gradient (`Shaders/top_bar_gradient.gdshader`) keeps
its own paper tones: it is the bar's lighting, not a fill.

## Type roles

One `FontVariation` per role (`Font_*` sub-resources of
`ui/themes/global_theme.tres`) and one theme type variation per role. A node
sets `theme_type_variation`; changing a role is one edit in the theme.

| role | variation | font | size |
| --- | --- | --- | --- |
| Display | `DisplayLabel` | Alegreya, `wght` 700, lining tabular figures | 32 |
| Title | `TitleLabel` | Alegreya, `wght` 600 | 22 |
| Flavor | `FlavorLabel`; `RichTextLabel` by default | Alegreya Italic, `wght` 400; bold = Alegreya Sans Bold, upright | 16 |
| Body | `Label` itself | Alegreya Sans Regular | 16 |
| Button | `Button` itself | Alegreya Sans Bold | 16 |
| MenuItem | `MenuItemLabel`; `PopupMenu` | Alegreya Sans Medium | 16 |
| Number | `NumberLabel` | Alegreya Sans Medium, `tnum` + `lnum` | 17 |
| Label | `FieldLabel` | Alegreya Sans Medium | 14 |
| Kicker | `KickerLabel` | Alegreya Sans Bold, `spacing_glyph` 1; set `uppercase` on the node | 12 |
| Caption | `CaptionLabel`; tooltips (`TooltipLabel`) | Alegreya Sans Medium | 13 |

The plan's "Label" role is `FieldLabel`, so it does not read as `LabelLabel`.

**Base types.** `Label`, `LineEdit`, `TextEdit`, `SpinBox`, `ItemList`,
`Tree`, `CheckBox` and `CheckButton` are Body. `Button`, `OptionButton`,
`MenuButton` and the tabs of `TabContainer` are Button. `PopupMenu` is
MenuItem, `ProgressBar` text is Caption, and window and dialog titles are
Title. The theme's `default_font` is Body.

**Step 2's variations are based on the roles** and keep only what is their
own (a colour, an outline):

- Display: `ScreenTitleLabel`, `PromptTitleLabel`, `LanguageTitleLabel`,
  `CountdownLabel`.
- Title: `PanelTitleLabel`, `ResultTitleLabel`, `NextBossStakesLabel`,
  `CodexListTitleLabel` („Kódexeim”), `CodexNameLabel`, `CodexPageTitleLabel`,
  `ShopTitleLabel`, `ShopHeadingLabel`, `ShopContentsTitleLabel`.
- Number: `CodexRowCountLabel`, `ShopTotalLabel`.
- Label (`FieldLabel`): `CodexCountLabel`, `PackCardNameLabel`,
  `PackCardPriceLabel`.
- Caption: `VersionLabel`, `ShopTooltipLabel`, `ShopNoteLabel`.
- Body: `ResultMessageLabel`, `CodexRowNameLabel`, `NetworkStatusLabel`,
  `DeckPreviewLabel`.
- Flavor: `StampDescriptionText`, the dialogue text.

**Plain nodes given a role.** The settings' field labels and the keyboard
heading are `FieldLabel`, and the sliders' values are `NumberLabel`. The
collection's page number and codex count are `NumberLabel`. The older menus
(single player, multiplayer, quick play, join) get `DisplayLabel` titles,
`FieldLabel` fields and `CaptionLabel` status lines. The server room panel's
title is `TitleLabel`. The collection's "2 db" badges take `FieldLabel`'s
font and size.

**One-off sizes, with Display's face.** The match result line (72) and the
speaker's initial in an empty portrait frame (44) use `DisplayLabel` for the
face. Their size comes from their own `LabelSettings`: big display text that
fits no role size. The countdowns use Display at 32. Display has lining
tabular figures, so a countdown does not shift as it counts.

**The top bar's labels are roles too** (step 6), at the role sizes, which
are bigger than the top bar design's - the quest panel grew from 270 to 340
for them:

- Number: `TopBarStatLabel` (the counters).
- Label (`FieldLabel`): `TopBarFloatLabel` (the floating "+50"),
  `QuestAmountLabel`.
- MenuItem: `TopBarMenuItemLabel`.
- Kicker: `QuestKickerLabel`, `TopBarTagLabel` (the menu's "temporary" tag).
- Title: `QuestTitleLabel`, so quest titles get the stamp like other titles.
- Caption: `QuestCaptionLabel` / `QuestUrgentCaptionLabel` (time left, the
  reward's caption), `QuestCountLabel` (progress).
- Flavor: `QuestText`, a RichTextLabel taking the base type's fonts.

A variation has one base, so each of them repeats the two entries the old
`TopBarLabel` gave them: no label padding (`StyleBox_bare`) and tight lines
(`line_spacing` / `line_separation` 0). The claim button takes the Button
role's font and size. Elms Sans is out of the global theme.

**Not on the roles:** the world's own lettering (OLDENGL, Rosemartin), as the
plan says.

**A rule the table cannot keep.** "At most two weights per family on one
screen": Body (Regular), Button (Bold) and the Medium roles (Label, Caption,
Number, MenuItem) meet on most screens, which makes three weights of Alegreya
Sans. The table wins for now; settle this in the plan if it matters.

## Where the variations live

**`ui/themes/global_theme.tres`**

- The role fonts and role variations above, and the base types.
- Screens: `ScreenTitleLabel`, `PromptTitleLabel`, `LanguageTitleLabel`,
  `CountdownLabel`, `PanelTitleLabel`, `ResultPanel` / `ResultTitleLabel` /
  `ResultMessageLabel` (match end), `NextBossStakesLabel` (main menu),
  `NetworkStatusLabel`, `CodexCountLabel` (the match codex's page counts),
  `VersionLabel` (top bar), `BareButton` (a button with no frame in any state:
  stamps).
- `MatchTabButton` - the match's tabs (Turn page, End turn): the Button look,
  cut as a tab rising from the screen's bottom edge (rounded top, open
  bottom, 48 at the bottom for the part below the edge). Unlike other buttons
  they are paper (`PAPER`): the variation's own `face` style, which
  `MatchTabButton.gd` draws on a layer at the very back, so the hover's ink
  floods in over the paper and under the outline and the label. Until now
  `MatchTabButton.gd` built its own paper boxes.
- Buttons of the collection that are buttons like any other:
  `CodexIconButton` (the codex rows' round icon buttons) and
  `PagerArrowButton` (the pager's arrows), moved here from the collection
  theme.
- Top bar: the labels listed under the type roles above (`TopBarStatLabel`,
  `TopBarFloatLabel`, `TopBarMenuItemLabel`, `TopBarTagLabel`,
  `QuestKickerLabel`, `QuestTitleLabel`, `QuestCaptionLabel`,
  `QuestUrgentCaptionLabel`, `QuestCountLabel`, `QuestAmountLabel`,
  `QuestText`), plus `QuestClaimButton`, `TopBarMenuRow` and
  `TopBarDropdown`.

**`ui/themes/collection_theme.tres`** - everything under `Collection.tscn`:
`StampSlotPanel`, `DeckPreviewPanel` /
`DeckPreviewLabel`, the codex labels (`CodexListTitleLabel`, `CodexNameLabel`,
`CodexNamePlaceholderLabel`, `CodexPageTitleLabel`, `CodexRowNameLabel`,
`CodexRowCountLabel`, `CodexRowCountIncompleteLabel`),
`StampDescriptionPanel` / `StampDescriptionText`, and the shop (`Shop*`,
`PackCard*`). Since step 3 it has no font of its own (it used to set Alegreya
as its default font), and since step 4 no Button, CheckBox or LineEdit entries
either: it holds only its own variations.

## Theme lookup rules

Godot checks the themes of the node's ancestors first (the collection theme,
for anything under the collection), then the project theme. For fonts and
font sizes, a theme's `default_font` / `default_font_size` can answer before
the base type's entry does. The consequences, found while doing steps 2 and 3:

1. **A base-type entry in the collection theme shadows the global
   variations.** Until step 4 the collection theme had its own Button,
   CheckBox and LineEdit entries, so a variation of those for a node under
   the collection had to live in the collection theme. It has none now; if
   one comes back, the rule does too.
2. **CheckBox inherits Button.** Without its own entry, a CheckBox picks up
   a theme's *Button* entry before another theme's CheckBox one. A theme
   that gets Button entries needs CheckBox entries alongside them.
3. **Declare every collection variation in the global theme too**, with only
   its `base_type`. Otherwise, for a font or size the variation does not set,
   Godot returns the global theme's default font and size, not the base type's.
   A frameless Button got 16 instead of 15, and a label would stop following
   `Label`'s size when it changes.
4. **A class that only inherits its theme items gets the default instead.**
   An `AcceptDialog` did not take `Window`'s title font, and a
   `ConfirmationDialog` did not take `AcceptDialog`'s: their titles were in
   the default font at 16 until each got its own `title_font` /
   `title_font_size` entry. Give such classes their own font and size entries.

## What stays an override, and why

**Layout, not style.** Container separations, margins and the odd
`line_spacing`: they belong to one container's layout, not to a look shared
across the UI. All the remaining `separation` / `margin_*` overrides in
scenes and scripts are of this kind.

**Chosen at runtime from data.**

- `QuestPanel.gd` - the kicker's colour follows the quest's reward.
- `TopBarCounter.gd` - the floating "+50" takes its counter's colour.
- `MatchCodexController.gd` - the codex page counter's current-page disc in
  the match.
- `StampVisual.gd` - a stamp's name and duration lettering per print.
- `StampHoverPreviewController.gd` - the match description's size comes from
  an exported parameter (its face is Flavor, from the theme).
- `ComicPageView.gd` - the end byline's font, size and colour are exported
  per comic page.

**Derived from the theme at runtime**, so they follow theme edits on their
own:

- `MoveEndsTurnDialog.gd` - its buttons are the theme's Button styles with
  tighter margins, and a 14 font size to match.

**Shapes sized from layout constants.**

- `Collection.gd` - the codex panel's top margin makes room for the top bar
  (`TOP_BAR_HEIGHT`), and the stamp-remove button is a circle as wide as
  `DECK_SLOT_REMOVE_BUTTON_SIZE`.
- `CollectionStampBrowserController.gd` - the count badge is a pill as tall
  as `COUNT_BADGE_HEIGHT`.
- `QuestPanel.gd` - the progress pips and track are drawn in `_draw`, in
  `TopBarStyle`'s colours and stroke.

**Big display text** - `TurnHudController.gd` (72) and `DialoguePanel.tscn`'s
portrait initial (44): sizes in `LabelSettings`, the face from `DisplayLabel`.

**The world's own lettering and drawing - out of scope by the plan:**

- `StampVisual.tscn` - the duration (OLDENGL), name (Rosemartin) and seeker
  labels.
- `DialoguePanel.tscn` - the speaker's Rosemartin name, and the dialogue
  text's black ink (its face and size are Flavor's).
- `main.tscn` - the codex page buttons, each with its own painted textures.
- `DeckCounterController.gd` - the deck counter clock, black on purpose.
- `PieceDurationChangeAnimator.gd`, `StampHoverPreviewController.gd` - OLDENGL
  for duration numbers.

**Other.**

- `Collection.tscn` `DeckPanelFrame` - its stylebox is an editor placeholder;
  `Collection.gd` replaces it at runtime (see above).
- `MainMenu.tscn` dev tools window - debug-only labels, not part of the
  game's look.
- `Scenes/Stackbuilder.tscn` - deleted after step 2: the collection's old
  scene, replaced by `Collection.tscn` in June and loaded by nothing since.
