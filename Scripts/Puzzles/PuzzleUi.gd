extends RefCounted
class_name PuzzleUi

## Small pieces shared by the Puzzles screen, the letter and the puzzle's own
## board: labels in the theme's type roles without their padding, the
## letter's fonts, and the words for a reward.

const LETTER_FONT_PATH: String = "res://Fonts/Alegreya-VariableFont_wght.ttf"
## The signature: Alegreya's italic is the nearest the game's fonts come to a
## hand. A script face would be closer (the mock-up's Caveat).
const SIGNATURE_FONT_PATH: String = "res://Fonts/Alegreya-Italic-VariableFont_wght.ttf"
const OPENTYPE_WEIGHT: int = 2003265652

static var _letter_font: FontVariation
static var _signature_font: Font

## A label in one of the theme's type roles (CaptionLabel, KickerLabel, ...),
## without the padding the theme gives labels.
static func label(text: String, variation: StringName = &"", color: Color = Color(0, 0, 0, 0)) -> Label:
	var result := Label.new()
	result.text = text
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if variation != &"":
		result.theme_type_variation = variation
	result.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	if color.a > 0.0:
		result.add_theme_color_override("font_color", color)
	return result

## Alegreya at its regular weight: the letters are the world's voice.
static func letter_font() -> FontVariation:
	if _letter_font == null:
		_letter_font = FontVariation.new()
		_letter_font.base_font = load(LETTER_FONT_PATH) as Font
		_letter_font.variation_opentype = {OPENTYPE_WEIGHT: 400}
	return _letter_font

static func signature_font() -> Font:
	if _signature_font == null:
		var italic := FontVariation.new()
		italic.base_font = load(SIGNATURE_FONT_PATH) as Font
		italic.variation_opentype = {OPENTYPE_WEIGHT: 500}
		_signature_font = italic
	return _signature_font

## "50 coins", "3 draw points", "Warlord".
static func describe_reward(puzzle: PuzzleDefinition) -> String:
	match puzzle.reward_kind:
		PuzzleDefinition.RewardKind.COINS:
			return TranslationServer.translate("PUZZLE_REWARD_COINS") % puzzle.reward_amount
		PuzzleDefinition.RewardKind.DRAW_POINTS:
			return TranslationServer.translate("PUZZLE_REWARD_DRAW_POINTS") % puzzle.reward_amount
	var stamp: Stamp = puzzle.get_reward_stamp()
	var stamp_name: String = TranslationServer.translate(stamp.stamp_name) if stamp != null else "?"
	if puzzle.reward_amount > 1:
		return "%d × %s" % [puzzle.reward_amount, stamp_name]
	return stamp_name

## The paper-and-ink panel the puzzle's board uses for its task and results.
static func panel_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = UiPalette.PAPER
	box.border_color = UiPalette.INK
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 14
	box.content_margin_bottom = 14
	box.shadow_color = Color(0, 0, 0, 0.18)
	box.shadow_size = 10
	box.shadow_offset = Vector2(0, 4)
	box.anti_aliasing = true
	return box

## A board seen from above: the puzzle's golems as dots, the player's open,
## the opponent's filled, a crowned one ringed; the two bases shaded. The
## player's side is at the bottom. Its ink (draw_board_sketch_ink) is drawn
## apart from its paper, so the ink alone can take the UI's ink stamp.
static func draw_board_sketch_paper(canvas: CanvasItem, rect: Rect2, paper: Color) -> void:
	canvas.draw_rect(rect, paper)

static func draw_board_sketch_ink(canvas: CanvasItem, rect: Rect2, puzzle: PuzzleDefinition, paper: Color, ink: Color) -> void:
	var cells: int = BoardConfig.BOARD_SIZE
	var cell: float = rect.size.x / float(cells)
	for base_square in ["d1", "d7"]:
		var base: Vector2 = PuzzleSquares.to_board(base_square)
		canvas.draw_rect(Rect2(rect.position + Vector2(base.y, cells - 1 - base.x) * cell, Vector2.ONE * cell), Color(ink, 0.12))
	for i in range(1, cells):
		var offset: float = cell * i
		canvas.draw_line(rect.position + Vector2(offset, 0), rect.position + Vector2(offset, rect.size.y), Color(ink, 0.45), 1.0)
		canvas.draw_line(rect.position + Vector2(0, offset), rect.position + Vector2(rect.size.x, offset), Color(ink, 0.45), 1.0)
	canvas.draw_rect(rect, ink, false, 1.5)
	if puzzle == null:
		return
	var radius: float = cell * 0.3
	for piece in puzzle.pieces:
		if piece == null:
			continue
		var pos: Vector2 = piece.get_board_position()
		if pos == PuzzleSquares.INVALID:
			continue
		var center: Vector2 = rect.position + (Vector2(pos.y, cells - 1 - pos.x) + Vector2(0.5, 0.5)) * cell
		if piece.side == PuzzlePiece.Side.OPPONENT:
			canvas.draw_circle(center, radius, ink)
		else:
			canvas.draw_circle(center, radius, paper)
			canvas.draw_arc(center, radius, 0.0, TAU, 20, ink, 1.4, true)
		if piece.crowned:
			canvas.draw_arc(center, radius + cell * 0.12, 0.0, TAU, 24, UiPalette.COIN_DEEP, 1.6, true)

## A soft round glow of `color`, `alpha` at its heart and none at its rim.
static func glow_texture(color: Color, alpha: float) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(color, alpha))
	gradient.set_color(1, Color(color, 0.0))
	gradient.add_point(0.45, Color(color, alpha * 0.55))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 256
	texture.height = 256
	return texture
