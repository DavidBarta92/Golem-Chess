# Ink blot

Ink soaked unevenly into the paper. Inside the ink, its density drifts in
blotches; along its edge, the ink is pushed in and out by a noise field, the
way ink bleeds into paper. It is the look of the Rorschach ink test shader on
godotshaders.com, written anew for this game: that shader is CC BY-NC-SA,
which a paid game cannot ship, so none of its code is used.

It sits on top of the ink stamp ([OVERRIDES.md](OVERRIDES.md), "Ink stamp"):
the stamp's specks stay, the blot adds the uneven density and the wandering
edge.

## Tuning

Everything is in `Shaders/ink_blot_settings.tres`. Open it in the inspector:
the `InkBlot` autoload (a tool script) passes every change to the shaders at
once, in the editor's view and, with Debug > Synchronize Scene Changes on, in
the running game.

Each group has four values:

| value | |
| --- | --- |
| density | 0 = even ink; 1 = the palest blotches lose all their ink |
| edge | how far an edge is pushed in or out at most, in units |
| blotch size | how big the blotches are, in units |
| wander size | how big the edge's bends are, in units |

`contrast` (one for all groups) sets how crisp a blotch's border is.

- **Most of the UI's frames are baked.** After changing a UI value, run
  `python tools/generate_ink_stamps.py`; the editor imports the prints when it
  next gets focus. The buttons' frames, the titles, the hover's ink and the
  top bar's drawn items follow the settings live.
- `project.godot` (`[shader_globals]`) only declares the uniforms, with the
  starting values. The `.tres` wins, so tune there, not in Project Settings >
  Shader Globals.

## Where it is

| group | what | how |
| --- | --- | --- |
| UI | the frames of the buttons that flood (Button, MenuButton, OptionButton, the match's tabs) and of the spin boxes' arrows: density live, edge baked | `ink_frame.gdshader`, given by `InkHoverFill`; their styles have `live_blot` on |
| | every other framed control's print: sliders' grabbers, fields, tabs, panels, windows, popups, progress bars | baked into the prints, density and edge |
| | the hover's ink, Display and Title text, the top bar's drawn items | `ink_flood.gdshader`, `ink_stamp.gdshader`, density only |
| Scene lines | all line art drawn by `mainmenu_line_reveal.gdshader`: the main menu, the match's room, the board's grid, the portrait frame, the comics, the tutorial, the collection's opening | in that shader |
| Scene washes | the grey washes under the line art: the match room's table and the memory room, every comic and tutorial panel's fill (`ComicPanelView`), the tutorial's figure, the collection's background | `ink_blot_washes.tres` |
| | the collection's book and magnifier case, pictures on their own paper: ink is taken away towards that paper's white | `ink_blot_pictures.tres` |
| Stamps | the coloured square: density, and an edge that only bites in, so the ink never spreads past the square | `stamp_square_gradient.gdshader` |
| | the art and the role frame: lightened towards the stamp's white paper, not let through to the square beneath | `stamp_art_mask.gdshader` |
| | the name, the duration, the effect and trigger icons, a separate role frame: density only | `stamp_layer.gdshader` |

Left out on purpose:

- The stamp pattern's markers. They show what the stamp does, so they must be
  easy to read.
- In the match's room, the opponent's body and the two window frames, line
  and wash alike.
- Paper: the stamp's face, the match room's sheet and table base, the scenes'
  paper overlay.
- Text with no stamp of its own (Body, Button labels and so on), as with the
  ink stamp.
- Things with a shader of their own, for now: the collection's set tabs, the
  codex, the main menu's street and opponent, the logo.

## How it works

`Shaders/ink_blot.gdshaderinc` holds the uniforms and three functions:

- `ink_blot_density(group, position, seed)` - the share of the ink kept.
- `ink_blot_wander(group, position, seed)` - how far the edge is pushed, in
  units.
- `ink_blot_uv_shift(shift, uv, position)` - that push as a UV offset, worked
  out from screen-space derivatives, so a shader samples its own texture where
  the wandering edge puts it. Call it outside any branch.

The noise is `ui/themes/stamp/ink_blot_noise.png`, baked by the same tool as
the prints: blotches in red (spread evenly over 0..1, so density means the
same at any setting), the edge's wander in green and blue. It tiles and has
mipmaps.

Positions are the item's own units (`VERTEX` from `vertex()`), so the
blotches stay put on an item as it moves or scales. A seed per item keeps
neighbours from sharing a pattern.

- **A stamp's seed comes from its print** (`print_id`, else the stamp's code),
  never from the node. A stamp keeps the same worn look in the hand, on the
  collection's pages and in a codex, however often its node is made anew. Its
  layers share one position space and the seed
  (`Shaders/stamp_ink_blot.gdshaderinc`; `StampVisual` sets
  `stamp_blot_frame` on each layer), so the blotches run across the stamp as
  one print.
- **A flooded button's frame and its hover ink share a seed** (the button's),
  and both work in the button's own units. The hover's state (`flood_*`) is
  copied onto the button too, so where the hover's ink already lies, the
  frame adds only what that ink lacks: one layer of ink, not two. Otherwise a
  pale blotch lets paper through the hover's ink but not through the outline
  on top of it, and the outline shows as a dark frame. The frame shader tells
  the print from the label by the texture's shape: a print is never square, a
  font atlas always is.

The edge is never moved on text: lettering samples a font atlas, and a pushed
sample would pick up the next glyph.

**Adding it to something new:** a plain picture takes one of the two
materials. A shader of its own includes `ink_blot.gdshaderinc`, passes
`VERTEX` to the fragment in a varying, and multiplies its ink by
`ink_blot_density()`; for the edge, it samples its texture at
`UV + ink_blot_uv_shift(ink_blot_wander(...), UV, position)`.

**Cost:** two noise samples per pixel, and the shifted sample replaces the
texture's own. The match's room has several full-screen layers; the noise is
small and cached, so the fill rate is what counts.
