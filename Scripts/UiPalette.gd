extends RefCounted
class_name UiPalette

## The UI's one palette (Docs/Style/STYLE_PLAN.md). CollectionPalette and the
## top bar's TopBarStyle alias these constants instead of defining their own.
## A .tres cannot read a constant, so ui/themes/global_theme.tres repeats the
## values (and collection_theme.tres for its own variations); change them
## there together with the constant.
##
## The UI's ink is blue, the drawings' ink black: shadows, dimming overlays,
## the drawn line art and the match's deck counter clock digits stay black on
## purpose. No pure white anywhere in the UI - PAPER_RAISED at most.

## The ink the UI is drawn in wherever it would otherwise be black: button
## labels and outlines, titles, focus rings, pressed fills, HUD outlines, icons.
## Shaders/ink_stamp.gdshader repeats it as the ink it re-inks black art in.
const INK: Color = Color("#172c43")
## Secondary text, placeholders, hints; about 6:1 on PAPER. Also the outline of
## controls one step back: unselected pack cards.
const INK_SOFT: Color = Color("#66594a")
## Disabled text and borders only.
const INK_DISABLED: Color = Color(Color("#786e61"), 0.72)
## Panels, the bar, menus, dialogs. The hub and story scenes repeat it as their
## paper (background ColorRects, the paper_texture overlay's paper_color).
const PAPER: Color = Color("#f4f0e6")
## Field fills, and light text on ink (never pure white). Buttons have no fill:
## outline and text only.
const PAPER_RAISED: Color = Color("#fcf9f2")
## Hover fill, for the few controls that keep a fill.
const PAPER_HOVER: Color = Color("#fffefb")
## Disabled fills, tracks, the ground under dividers.
const PAPER_SHADE: Color = Color("#e8e3d9")
## Inactive controls' outline and label, on trial: disabled buttons (at 60 %,
## so they also read as faded) and disabled tabs. Their fill stays clear.
const INK_INACTIVE: Color = Color("#f0abb3")
## Hairline dividers only - never around something you can press.
const LINE_SOFT: Color = Color("#bdb9ad")

# Quests and counters only (the top bar, Docs/TopBar/HANDOFF.md).

## Story quests and nothing else.
const STORY: Color = Color("#7a2230")
## A fill only; coin-related text on paper uses COIN_DEEP.
const COIN: Color = Color("#e3b02a")
const COIN_DEEP: Color = Color("#8a5d00")
## Draw points: a fill, and readable as text on paper too.
const DRAW: Color = Color("#2c6e9e")
## Only a daily quest with less than an hour left.
const URGENT: Color = Color("#b44a12")
