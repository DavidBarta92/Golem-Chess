# UI style plan

Notes for whoever brings the UI closer to the drawn world. The aim: one
palette, one type system and one line weight, kept in the themes instead of
scattered through scenes and scripts, and then an ink-stamp texture on the
UI's ink. Work through the steps at the end in order; each is one change and
one commit.

The top bar redesign ([Docs/TopBar/HANDOFF.md](../TopBar/HANDOFF.md)) follows
these rules too. Where the two disagree, this file wins — `TopBarStyle.gd`
moves onto the shared palette and type in step 6.

## Where the styling lives today

| | |
| --- | --- |
| `ui/themes/global_theme.tres` | the project theme (`project.godot` → `theme/custom`); every scene falls back to it |
| `ui/themes/collection_theme.tres` | set on `Scenes/Collection.tscn`, preloaded by `CollectionSavedDeckListController.gd`; repeats most of the global theme with its own values |
| `Scripts/UiPalette.gd` | `INK` (`#172c43`) only |
| `Scripts/CollectionPalette.gd` | `INK_SOFT`, `PAPER`, `PAPER_LIGHT`, `PAPER_HOVER` |
| `Scripts/TopBar/TopBarStyle.gd` | its own `PAPER`, `INK_SOFT`, `LINE_SOFT` and the quest colours, plus fonts |

Styling set outside the themes:

- **Scripts** calling `add_theme_*_override`: `CollectionPackController.gd` (49),
  `TopBar/QuestPanel.gd` (21), `Collection.gd` (15), `TopBar/TopBarMenu.gd` (11),
  `CollectionSavedDeckListController.gd` (10), `StampVisual.gd` (6), and about
  ten more with 1–5 each.
- **Scripts building their own `StyleBoxFlat`**: `TopBar/QuestPanel.gd`,
  `TopBar/TopBarMenu.gd`, `Collection.gd`, `MatchTabButton.gd`,
  `MatchCodexController.gd`, `CollectionStampBrowserController.gd`,
  `CollectionPackController.gd`.
- **Scenes with `theme_override_*`**: `main.tscn` (46), `Stackbuilder.tscn` (41),
  `Collection.tscn` (33), `StampVisual.tscn` (21), `DialoguePanel.tscn` (11),
  `MainMenu.tscn` (10), the settings sections (8–9 each).
- **Fonts loaded directly**: `Collection.gd`, `TopBar/TopBarStyle.gd`,
  `Story/ComicPageView.gd`, `DialoguePanel.tscn`, `StampVisual.tscn`,
  `PieceDurationChangeAnimator.gd`, `StampHoverPreviewController.gd`.
- **About 15 font sizes** in use: 12, 13, 14, 15, 16, 17, 18, 20, 21, 22, 30, 32, 44, 47, 72.

Out of scope, on purpose: the world's own lettering — `OLDENGL.TTF` (logo,
stamp numbers, duration labels) and `Rosemartin.otf` (stamp names, dialogue
panel) — and everything drawn: stamps, illustrations, comic pages.

## Palette

One source: `Scripts/UiPalette.gd`. `CollectionPalette` and `TopBarStyle`
alias its constants instead of defining their own. The themes repeat the
values (a `.tres` cannot read a constant); the comment on each constant says
so, as `UiPalette.INK`'s already does.

| constant | value | for | replaces |
| --- | --- | --- | --- |
| `INK` | `#172c43` | all UI text, outlines, icons, pressed fills, focus rings | — (keep) |
| `INK_SOFT` | `#66594a` | secondary text, placeholders, hints | `TopBarStyle.INK_SOFT` `#575e6b`, the global theme's greys `#6b6963` / `#5a5853` |
| `INK_DISABLED` | `#786e61` at 72 % | disabled text and borders | `#76746e` at 72 % / 60 % |
| `PAPER` | `#f4f0e6` | panels, the bar, menus | `TopBarStyle.PAPER` `#f2f1ea`, the global theme's `#f7f6f2` |
| `PAPER_RAISED` | `#fcf9f2` | field fills (buttons have none: outline and text only) | pure white `#ffffff` (11 uses in the global theme), `#fafaf7`, `#fbfaf7` |
| `PAPER_HOVER` | `#fffefb` | hover fill | — |
| `PAPER_SHADE` | `#e8e3d9` | disabled fills, tracks, dividers' ground | `#e3e1db`, `#e9e7e1`, `#e0ded8` |
| `LINE_SOFT` | `#bdb9ad` | hairline dividers only | — |
| `INK_INACTIVE` | `#f0abb3` | outline and label of disabled buttons and tabs (on trial) | — |
| `STORY` `COIN` `COIN_DEEP` `DRAW` `URGENT` | as in `TopBarStyle.gd` | quests and counters only — see the top bar handoff | — |

Rules:

- **No pure white anywhere in the UI.** Fills are `PAPER_RAISED`, at most.
- **The UI's ink is blue (`INK`); the drawings' ink is black.** That split is
  deliberate: blue marks what you can press or read as interface. Do not mix
  black outlines into the UI or blue into the art.
- `INK_SOFT` on `PAPER` is about 6:1 — fine for text. `INK_DISABLED` is for
  disabled states only.

## Type

Two families with fixed roles. Alegreya is the world's voice, Alegreya Sans
the interface's. The fonts are already in `Fonts/` (Alegreya as two variable
files, Alegreya Sans as static weights).

| role | family | weight | size | where |
| --- | --- | --- | --- | --- |
| `Display` | Alegreya | Bold (700) | 32 | screen titles |
| `Title` | Alegreya | SemiBold (600) | 22 | panel and section titles: „Kódexeim”, quest titles, dialog headings |
| `Flavor` | Alegreya Italic | Regular (400) | 16 | flavor and quest text; its key condition in Alegreya Sans Bold, upright |
| `Body` | Alegreya Sans | Regular | 16 | descriptions, list items, settings text |
| `Button` | Alegreya Sans | Bold | 16 | buttons, tabs, option buttons |
| `MenuItem` | Alegreya Sans | Medium | 16 | dropdown and popup menu rows |
| `Number` | Alegreya Sans | Medium, tabular lining figures | 17 | counters, scores, page numbers |
| `Label` | Alegreya Sans | Medium | 14 | field labels, small headings, „2 db” |
| `Kicker` | Alegreya Sans | Bold, upper case, +8 % tracking | 12 | the quest panel's type line |
| `Caption` | Alegreya Sans | Medium | 13 | hints, progress counts, timestamps |

Rules:

- **Ten roles, no other sizes.** Something that does not fit a role is a new
  role, added here first. The bigger one-off sizes (44, 47, 72) are display
  numbers in the match; give each a role or leave it with a note saying why.
- **No Light or Thin below 22.** They fall apart under the stamp texture.
- **Bold means "act" or "this matters"**: buttons, the kicker, and the key
  condition inside flavor text. Not whole paragraphs.
- **At most two weights per family on one screen.**
- **Numbers that change** use tabular lining figures (`tnum`, `lnum`), so a
  counter does not shift as it counts.
- Alegreya Sans runs smaller and narrower than Elms Sans. The sizes above
  already allow for it; check them against Elms Sans screenshots, and check
  every fixed-width slot with the Hungarian strings, which are the longest.

In Godot: one `FontVariation` per role (weight through
`variation_opentype` `wght` for the variable Alegreya files; `tnum` / `lnum`
through `opentype_features`), and one **theme type variation** per role
(`TitleLabel`, `FlavorLabel`, `CaptionLabel`, `KickerLabel`, `NumberLabel`, …)
in `global_theme.tres`. A node then sets `theme_type_variation` instead of
overriding font and size, and changing a font later is a single edit.
RichTextLabel keeps its own fonts for bold and italic; point those at the
same variations.

## Line weight

Measured at the 1280×720 base:

| | | |
| --- | --- | --- |
| hairline | 1 | dividers, list separators — never around something you can press |
| stroke | 2 | every control border: buttons, fields, panels, tabs, the menu, ribbon outlines |
| strong | 3 | focused and primary controls |
| icon stroke | 2 at display size | icons drawn on a 24 grid scale their stroke so it shows as 2 |

Corner radius stays as it is (3–4). Today almost every border in both themes
is 1; that thin, even line is the main reason the UI looks foreign next to
the drawings. Compare 2 against the line art on the main menu before you
commit to it — if the art reads heavier, use 2.5 or 3 as the stroke.

## Ink-stamp texture

The UI's ink is pressed onto the paper like a rubber stamp: a little ink
missing in small specks, slightly ragged edges, faintly uneven density. The
game is about stamps, so this ties the interface to the world without
redrawing it.

**Where**

- Yes: control frames and filled states (buttons, toggles, fields, option
  buttons, tabs, panel frames, the menu), icons, the top bar's drawn items
  (ribbons, counter icons, menu button), and `Display` / `Title` text.
- No: `Body`, `Button` labels, `Number`, `Label`, `Caption`, `Kicker` — small
  text loses its strokes. Not on stamps, illustrations or comics, which are
  already printed or drawn.

**How it looks**

- Ink is taken away, never lightened: specks show the paper beneath, so it
  works on any ground.
- Lighter than the reference image — about 10–20 % of the ink missing.
- The speck size is fixed in screen units (1–2 at the base resolution),
  whatever the size of the control. It must not stretch with a button.
- Two controls side by side do not show the same pattern.
- It does not move. No `TIME` in the shader.

**How to build it in Godot.** A shader on a `Button` would texture its label
too, so frames and text take different routes:

1. **Frames and fills → `StyleBoxTexture`.** One 9-patch PNG per state
   (normal, hover, pressed / toggled, disabled, focus) with the stroke and the
   specks baked in, edges and centre set to tile, not stretch. Make the
   strips long (256 px or more) so buttons of different widths land on
   different parts of the pattern. Generate the PNGs with a small script from
   noise parameters, so they can be tuned and regenerated, and keep them in
   `ui/themes/stamp/`. They replace the `StyleBoxFlat` entries in the themes;
   the line weight is baked into the PNGs.
2. **Icons, the top bar's drawn items and titles → `Shaders/ink_stamp.gdshader`.**
   A canvas-item shader that cuts alpha with a noise texture (fine noise for
   the specks, coarse noise for density) sampled in local pixel space, so the
   speck size stays fixed. Each node gets its own seed — a per-node material,
   or an instance uniform if Godot 4.7 allows them on canvas items (check).
   `paper_texture` and `ink_tint` are a good starting point.
3. **States.** Every state gets the texture, focus too; otherwise hover and
   pressed look like a different system.

Try it on one screen (the collection) first, at 1280×720 and 1920×1080,
before rolling it out.

## Order of work

Each step is one VS Code prompt and one commit. Steps 1 and 2 are pure
refactors: the game must look the same afterwards, so compare screenshots of
the main menu, the collection, the deck builder, a match and the settings
before and after. They come first because, without them, every later step
would touch 15–20 files; after them, each is a few theme edits.

0. **Commit what is in progress** (the top bar work, the theme and font
   changes) so there is a clean point to return to.
1. **One palette.** Extend `UiPalette.gd` with the table above, at today's
   values (no visual change yet); make `CollectionPalette` and `TopBarStyle`
   alias it.
2. **Styling into the themes.** `collection_theme.tres` keeps only what
   differs from the global theme (Godot falls back to the project theme for
   anything a theme lacks — verify on the collection screen). Turn the
   scattered overrides and the directly loaded fonts into theme type
   variations, biggest first: `CollectionPackController.gd`, `main.tscn`,
   `Stackbuilder.tscn`, `Collection.tscn`/`.gd`, the top bar scripts. Write
   down whatever has to stay an override, and why.
3. **Type.** Add the font variations and type variations from the table,
   map every text node to a role, and switch the UI from Elms Sans to
   Alegreya / Alegreya Sans. Check Hungarian and English for overflow.
4. **Palette and line weight.** Switch to the new values: no white, one paper,
   warm `INK_SOFT`, borders to 2.
5. **Ink stamp.** Build the shader and the 9-patch generator, try them on the
   collection, tune, then roll them out across the themes.
6. **Top bar and icons.** Move `TopBarStyle.gd` onto the shared palette and
   type, give the ribbons, counter icons and menu the stamp, and bring the
   icons to the 2-unit stroke.

The top bar design in `Docs/TopBar/design/` still shows Lexend and the
sketch's cooler paper. Read this file over it for type and colour.
