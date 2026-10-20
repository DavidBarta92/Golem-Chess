extends RefCounted
class_name UiPalette

## The ink the UI is drawn in wherever it would otherwise be black: button
## labels and outlines, titles, focus rings, pressed fills, HUD outlines.
## ui/themes/global_theme.tres and ui/themes/collection_theme.tres repeat it
## for the themed controls, and Shaders/ink_tint.gdshader as its default;
## change them together. Shadows, dimming overlays, the drawn line art and the
## match's deck counter clock digits stay black on purpose.

const INK: Color = Color("#172c43")
