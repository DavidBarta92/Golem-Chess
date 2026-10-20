extends RefCounted
class_name CollectionPalette

## The ink and paper tones the Collection's UI uses instead of pure black and
## cold greys, so its buttons and labels sit with the drawn world. The ink is
## the shared UiPalette.INK.
## ui/themes/collection_theme.tres repeats these values for the themed controls;
## change both together.

const INK: Color = UiPalette.INK
const INK_SOFT: Color = Color(0.4, 0.35, 0.29)
const PAPER: Color = Color(0.957, 0.941, 0.902)
## The near-white the buttons are filled with.
const PAPER_LIGHT: Color = Color(0.988, 0.976, 0.949)
const PAPER_HOVER: Color = Color(1.0, 0.996, 0.984)
