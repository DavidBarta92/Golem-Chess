extends RefCounted

## Sizes, colours, fonts and timings of the global top bar, taken from the
## design in Docs/TopBar (design px x 0.75 = Godot units at the 1280x720 base).
## Ink is the game's own UiPalette.INK; the other colours have no game
## equivalent yet - see Docs/TopBar/design/tokens.json for what each is for.

const PAPER: Color = Color("#f2f1ea")
const PAPER_HOVER: Color = Color("#e8e6dc")
const INK: Color = UiPalette.INK
const INK_SOFT: Color = Color("#575e6b")
const LINE_SOFT: Color = Color("#bdb9ad")
## Story ribbons and nothing else.
const STORY: Color = Color("#7a2230")
## A fill only; coin-related text on paper uses COIN_DEEP.
const COIN: Color = Color("#e3b02a")
const COIN_DEEP: Color = Color("#8a5d00")
const DRAW: Color = Color("#2c6e9e")
## Only a daily quest with less than an hour left.
const URGENT: Color = Color("#b44a12")
const PANEL_FILL: Color = Color(0.94902, 0.945098, 0.917647, 0.96)

const BAR_HEIGHT: float = 60.0
const BAR_MARGIN: float = 24.0
## Ribbons <-> counters, counter <-> counter, counters <-> menu.
const GROUP_GAP: float = 18.0
const RIBBON_GAP: float = 6.0
const BUTTON_SIZE: float = 40.0

const RIBBON_WIDTH: float = 21.0
## Measured from the top of the screen, so a resting ribbon hangs 12 below the bar.
const RIBBON_REST: float = 72.0
const RIBBON_LIFT: float = 4.5
const RIBBON_DONE_DROP: float = 9.0
const RIBBON_RETRACTED: float = 54.0
const RIBBON_OUTLINE: float = 1.5
const TAIL_DEPTH: Dictionary = {
	"story": 7.5,
	"reward": 6.75,
	"daily": 4.5,
}

const PANEL_WIDTH: float = 270.0
const PANEL_TEXT_WIDTH: float = 204.0
const MENU_WIDTH: float = 180.0
const MENU_ROW: float = 33.0
const MENU_DROP_GAP: float = 7.5

const ICON_STAT: float = 18.0
const ICON_MENU: float = 15.0
const ICON_RIBBON: float = 12.0

const FONT_SIZE_STAT: int = 17
const FONT_SIZE_MENU: int = 13
const FONT_SIZE_CAPTION: int = 10
const FONT_SIZE_KICKER: int = 9
const FONT_SIZE_TITLE: int = 15
const FONT_SIZE_TEXT: int = 12
const FONT_SIZE_FLOAT: int = 11

## Ribbon down / up: hover, open, retract.
const RIBBON_MOVE_SECONDS: float = 0.24
const PANEL_IN_SECONDS: float = 0.2
const PANEL_IN_DELAY_SECONDS: float = 0.09
const PANEL_OUT_SECONDS: float = 0.16
const PANEL_SLIDE: float = 6.0
const RIBBON_ARRIVE_SECONDS: float = 0.52
const RIBBON_CLAIM_SECONDS: float = 0.42
const RIBBON_EXPIRE_SECONDS: float = 0.62
## Ribbons and counters changing place.
const SLIDE_SECONDS: float = 0.28
const SWAY_DEGREES: float = 1.6
const SWAY_CYCLE_SECONDS: float = 3.0
const MENU_IN_SECONDS: float = 0.16
const MENU_OUT_SECONDS: float = 0.14

const FONT_REGULAR: FontFile = preload("res://Fonts/ElmsSans-Regular.ttf")
const FONT_MEDIUM: FontFile = preload("res://Fonts/ElmsSans-Medium.ttf")
const FONT_SEMIBOLD: FontFile = preload("res://Fonts/ElmsSans-SemiBold.ttf")
const FONT_ITALIC: FontFile = preload("res://Fonts/ElmsSans-Italic.ttf")

static var _tabular_font: FontVariation
static var _kicker_font: FontVariation

## The ribbon's fill for a reward: story is always burgundy.
static func reward_color(reward: String) -> Color:
	match reward:
		"coin":
			return COIN
		"draw":
			return DRAW
	return STORY

## Icon and stitching on a ribbon of that reward: paper on burgundy and blue,
## ink on gold.
static func on_reward_color(reward: String) -> Color:
	return INK if reward == "coin" else PAPER

## Text tied to a reward, readable on paper.
static func reward_text_color(reward: String) -> Color:
	match reward:
		"coin":
			return COIN_DEEP
		"draw":
			return DRAW
	return STORY

## Up to four digits in one piece (1000), from five on grouped by spaces (12 400).
static func format_number(value: int) -> String:
	var digits: String = str(absi(value))
	if absi(value) >= 10000:
		var grouped: String = ""
		while digits.length() > 3:
			grouped = " " + digits.substr(digits.length() - 3) + grouped
			digits = digits.substr(0, digits.length() - 3)
		digits += grouped
	return ("-" if value < 0 else "") + digits

## Regular weight with tabular figures, so a counter keeps its width as it changes.
static func tabular_font() -> Font:
	if _tabular_font == null:
		_tabular_font = FontVariation.new()
		_tabular_font.base_font = FONT_REGULAR
		_tabular_font.opentype_features = {TextServerManager.get_primary_interface().name_to_tag("tnum"): 1}
	return _tabular_font

## SemiBold, spaced out, for the upper-case quest kind above a quest's title.
static func kicker_font() -> Font:
	if _kicker_font == null:
		_kicker_font = FontVariation.new()
		_kicker_font.base_font = FONT_SEMIBOLD
		_kicker_font.spacing_glyph = 1
	return _kicker_font

## A label with no theme padding, in the given font, size and colour.
static func make_label(text: String, font: Font, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("line_spacing", 0)
	return label
