# Stamp painter (trial)

A standalone scene for drawing a stamp's art in the game, MS Paint style.
Not reachable from the menus yet: open `Scenes/StampPainter/StampPainter.tscn`
and run it with F6. The texts are Hungarian only for now and move to
`Localization/translations.csv` when the painter joins the game.

## What a drawing is

Another art for an existing stamp, not a new stamp: the rules, name and
pattern stay the stamp's own. In a match only its owner sees it; the opponent
sees the stamp's original art.

## Files

| | |
| --- | --- |
| `Scenes/StampPainter/StampPainter.tscn` | the layout: tools left, canvas in the middle, preview, palette and mask guide right |
| `Scripts/StampPainter/StampPainter.gd` | the panels, the stamp picker, the preview, open and save, the keys |
| `Scripts/StampPainter/PaintCanvas.gd` | the canvas: tools, undo and redo, zoom and pan |
| `Scripts/StampPainter/StampPainterPalette.gd` | the colours |
| `Shaders/stamp_painter_guide.gdshader` | the mask guide |

## How it works

- **Canvas.** 554 × 700, the size of the stamps' art (`Assets/Stamps/`), always
  opaque like that art. The pixels are a `PackedByteArray`, synced to an
  `ImageTexture` with mipmaps once a frame (about 1.5 ms).
- **Strokes.** A stroke fills a coverage map (the most any part of the stroke
  reached each pixel) and blends its colour over the pixels as they were when
  it started. Overlaps within one stroke do not darken, and the edge stays
  antialiased. The pencil is the hard-edged version, and at 1 px it draws a plain
  Bresenham line.
- **Shapes.** While you drag, a shape is drawn as vectors. It is rasterised once,
  on release. Rectangles sit on the pixel grid, ellipses are antialiased.
- **Fill.** Scanline flood fill with a tolerance (`FILL_TOLERANCE`). The ring
  of pixels just past the filled area takes the new colour in proportion to
  how much of the old colour it holds, judged against its neighbour further
  out. That way no halo of the old paper stays along an antialiased line.
  Filling the whole canvas takes about 180 ms.
- **Undo.** A snapshot of the pixels before each operation, at most
  `MAX_UNDO_STEPS` (40; about 1.5 MB each).
- **Palette.** Every stamp's art is two-tone, one paper and one deeper ink. The
  palette is those pairs, read off the art, plus a black ink. The left mouse
  button paints with the ink; the right button and the eraser paint with the
  paper. The picker snaps to the nearest palette colour.
- **Mask guide.** Shades what the stamp will not show and draws the role's
  frame. It maps the canvas onto the stamp the way `stamp_art_mask.gdshader`
  does (the art covers the stamp and is cropped in the middle) and uses the
  role's mask, so a Unit shows a circle and a Seeker a pentagon. Over it, a
  `StampVisual` with only its markings left (name, number, pattern, effect
  icons) shows what is printed over the art. The guide can be turned off (M)
  and its strength changed.
- **Preview.** A real `StampVisual` whose print has the canvas texture as its
  art, so it updates while you draw and shows the ink blot and the frame.
  Drawings have no mask of their own yet, so nothing reaches past the frame
  the way some standard prints do.

## Where drawings go

`Documents/Golem Chess/Drawings/<stamp code>_<nn>.png`. Saving again writes to
the same file until another stamp is picked. `--drawings-dir=<path>` after `--`
on the command line saves somewhere else; test runs use it.

## Keys

P pencil, B brush, E eraser, G fill, L line, R rectangle, O ellipse, I picker;
X swaps ink and paper, `[` `]` size, M mask guide, F fit to view; wheel zooms,
middle button or Space + drag pans, Shift makes straight lines, squares and
circles; Ctrl+Z / Ctrl+Y / Ctrl+Shift+Z, Ctrl+S, Ctrl+O, Ctrl+N.

## Not done yet

- Using a drawing in the game: the collection, a print in the save, codexes.
- A mask of the drawing's own, for parts that reach past the frame.
- The texts in the translations, and a way to reach the scene from the menus.
- Tablet pressure.
