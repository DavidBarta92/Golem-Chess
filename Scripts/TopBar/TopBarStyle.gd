extends RefCounted

## Sizes, colours and timings of the global top bar, taken from the design in
## Docs/TopBar (design px x 0.75 = Godot units at the 1280x720 base), on the
## shared palette and type of Docs/Style/STYLE_PLAN.md. Its text styles are
## theme type variations in ui/themes/global_theme.tres, each a type role
## without the label padding (TopBarStatLabel is NumberLabel, QuestTitleLabel
## TitleLabel, ...), plus QuestText, QuestClaimButton, TopBarMenuRow and
## TopBarDropdown; the colours here are for what the bar draws itself.

const INK: Color = UiPalette.INK
const INK_SOFT: Color = UiPalette.INK_SOFT
const PAPER: Color = UiPalette.PAPER
const PAPER_SHADE: Color = UiPalette.PAPER_SHADE
const LINE_SOFT: Color = UiPalette.LINE_SOFT
const STORY: Color = UiPalette.STORY
const COIN: Color = UiPalette.COIN
const COIN_DEEP: Color = UiPalette.COIN_DEEP
const DRAW: Color = UiPalette.DRAW
const URGENT: Color = UiPalette.URGENT
const PANEL_FILL: Color = Color(PAPER, 0.96)

## The plan's stroke: every outline the bar draws - ribbons, seals, badges, pips.
const STROKE: float = 2.0

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
const TAIL_DEPTH: Dictionary = {
	"story": 7.5,
	"reward": 6.75,
	"daily": 4.5,
}

## Wider than the design's 270 / 204, for the shared type sizes.
const PANEL_WIDTH: float = 340.0
const PANEL_TEXT_WIDTH: float = 256.0
const MENU_WIDTH: float = 180.0
const MENU_ROW: float = 33.0
const MENU_DROP_GAP: float = 7.5

## Bigger than the design's 18 / 15, so the plan's 2-unit icon stroke
## (TopBarIcons) leaves them open.
const ICON_STAT: float = 20.0
const ICON_MENU: float = 20.0
const ICON_RIBBON: float = 12.0

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

## A label in one of the bar's text styles - a theme type variation: a type
## role without the theme's label padding.
static func make_label(text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.theme_type_variation = variation
	return label
