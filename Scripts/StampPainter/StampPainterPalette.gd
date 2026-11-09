extends RefCounted

## The stamp painter's colours. Every stamp's art is two-tone - one paper
## colour and one ink of a deeper shade - so the palette is those pairs, read
## off the art in Assets/Stamps/ (the most common colour and the ink cluster),
## plus one black ink as Docs/Style/STYLE_PLAN.md asks of drawings.
## Add a pair here when a new stamp brings a new pair of colours.

## [paper, ink, the art the pair comes from]
const PAIRS: Array = [
	[Color("#d97a95"), Color("#6e3642"), "goldgeneral_1"],
	[Color("#fcecc5"), Color("#d4364a"), "knight_1"],
	[Color("#f2daca"), Color("#ce5234"), "monk_1"],
	[Color("#f4e0c8"), Color("#9a3f41"), "prince_1"],
	[Color("#dfc2ab"), Color("#292f41"), "archer_1"],
	[Color("#f8e7cc"), Color("#92aac2"), "duke_1"],
	[Color("#fefad4"), Color("#c6c053"), "wardrummer_1"],
	[Color("#cfdd78"), Color("#34654e"), "assassin_1"],
	[Color("#aeeaa7"), Color("#4f8b65"), "warlord_1"],
	[Color("#95ae94"), Color("#495548"), "silvergeneral_1"],
	[Color("#10aae0"), Color("#07394b"), "lance_1"],
	[Color("#d4e2f1"), Color("#5195e5"), "skirmisher_1"],
	[Color("#b48fd1"), Color("#6f6e5f"), "golem_1"],
	[Color("#cca6f3"), Color("#853281"), "bishop_1"],
	[Color("#ffffff"), Color("#4b5d48"), "berserk_1"],
	[Color("#ebe5d8"), Color("#1e1e22"), "black ink"],
]

## The pair a new drawing starts with.
const DEFAULT_PAIR: int = 4

static func paper(index: int) -> Color:
	return PAIRS[index][0]

static func ink(index: int) -> Color:
	return PAIRS[index][1]

## Every colour of the palette, for snapping a picked colour to it.
static func all_colors() -> PackedColorArray:
	var colors := PackedColorArray()
	for pair: Array in PAIRS:
		colors.append(pair[0])
		colors.append(pair[1])
	return colors
