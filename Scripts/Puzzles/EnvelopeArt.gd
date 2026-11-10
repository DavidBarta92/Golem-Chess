extends RefCounted
class_name EnvelopeArt

## The four envelopes and the marks in their corner, drawn straight onto a
## CanvasItem from the mock-ups' SVG (Docs/Letters/Borítékstílusok-html,
## Jelzések). Everything is laid out in the mock-ups' 320-unit-wide view box
## and scaled to the width asked for; lines keep their on-screen width
## whatever the scale, as the SVG's non-scaling strokes do.
##
## An envelope has no rim: its paper meets what lies behind it with no line.
## Only the lines inside it are drawn - a flap's edges, the folds of its back.
##
## An envelope is drawn in parts so the letter scene can open it:
##   front          the face with the address side and its mark
##   lining         the inside, seen through the open top
##   flap_closed    the back's flap, folded down over the opening
##   flap_open      the same flap folded up, showing its lining
##   pocket         the back below the opening, with its folds
## Every part shares the body's coordinates: (0, 0) is the top left corner of
## the envelope, and an open flap reaches above it, into negative y.

const Style = PuzzleDefinition.EnvelopeStyle
const VIEW_WIDTH: float = 320.0
const HEIGHT: Dictionary = {
	Style.BRITISH: 220.0,
	Style.HUNGARIAN: 204.0,
	Style.CZECH: 228.0,
	Style.AMERICAN: 140.0,
}
const STROKE: float = 1.5
const FOLD_STROKE: float = 1.0
const CORNER_RADIUS: float = 3.0
const CURVE_SEGMENTS: int = 24

## An envelope is a drawing, so its lines are in the drawings' black ink, not
## the UI's blue (Docs/Style/STYLE_PLAN.md).
const INK: Color = Color(0.06, 0.06, 0.08, 0.9)
const PAPER: Dictionary = {
	Style.BRITISH: Color("#f4ecd8"),
	Style.HUNGARIAN: Color("#f8f6ef"),
	Style.CZECH: Color("#e2e9ee"),
	Style.AMERICAN: Color("#fbfaf6"),
}
const FLAP: Dictionary = {
	Style.BRITISH: Color("#efe4cb"),
	Style.HUNGARIAN: Color("#ece9df"),
	Style.CZECH: Color("#d6dfe6"),
	Style.AMERICAN: Color("#f3f1ea"),
}
## The inside: the British envelope's dark blue lining from the mock-up; the
## others take a lining in their own colours.
const LINING: Dictionary = {
	Style.BRITISH: [Color("#2b3f6b"), Color("#34497a")],
	Style.HUNGARIAN: [Color("#8e3a22"), Color("#9c4329")],
	Style.CZECH: [Color("#2c4a6e"), Color("#35557b")],
	Style.AMERICAN: [Color("#2b3f6b"), Color("#b8352f")],
}
const LAID_LINE: Color = Color("#e8ddc2")
const POSTCODE_RED: Color = Color("#c4502a")
const POSTCODE_BLUE: Color = Color("#2c4a6e")
const AIRMAIL_RED: Color = Color("#b8352f")
const AIRMAIL_BLUE: Color = Color("#2b3f6b")
const AIRMAIL_BAND: float = 8.0
const POSTMARK_INK: Color = Color("#2a3550")
const WAX: Color = Color("#a3262a")
const WAX_EDGE: Color = Color("#6e1518")
const WAX_DEEP: Color = Color("#7f1a1d")
const WAX_SHINE: Color = Color("#c9524f")

## The mark's place, as a share of the envelope's width (the mock-up's).
const MARK_WIDTH: float = 0.17
## The postmark's width, in marks: a little over the mock-up's 2.1, so the
## coin's face in it still reads on an envelope in the grid.
const POSTMARK_SHARE: float = 2.4
const MARK_MARGIN: float = 0.04

static func get_height(style: int, width: float) -> float:
	return width * float(HEIGHT.get(style, 220.0)) / VIEW_WIDTH

static func get_view_height(style: int) -> float:
	return float(HEIGHT.get(style, 220.0))

# --- Parts --------------------------------------------------------------------

static func draw_front(canvas: CanvasItem, style: int, width: float) -> void:
	var pen := _Pen.new(canvas, width)
	var h: float = get_view_height(style)
	pen.paper_rect(Rect2(1, 1, 318, h - 2), PAPER[style])
	match style:
		Style.BRITISH:
			_draw_laid(pen, h, true)
		Style.HUNGARIAN:
			for x in [194.0, 220.0, 246.0, 272.0]:
				pen.rect_outline(Rect2(x, 160, 22, 26), POSTCODE_RED, 1.3)
		Style.CZECH:
			for x in [24.0, 48.0, 72.0, 104.0, 128.0]:
				pen.rect_outline(Rect2(x, 184, 20, 26), POSTCODE_BLUE, 1.3)
		Style.AMERICAN:
			_draw_airmail_band(pen, Rect2(1, 1, 318, h - 2), true)

static func draw_lining(canvas: CanvasItem, style: int, width: float) -> void:
	var pen := _Pen.new(canvas, width)
	var h: float = get_view_height(style)
	var colors: Array = LINING[style]
	var body := PackedVector2Array([Vector2(1, 1), Vector2(319, 1), Vector2(319, h - 1), Vector2(1, h - 1)])
	pen.fill(body, colors[0])
	pen.stripes(body, 10.0, 2.0, 30.0, colors[1])

static func draw_flap(canvas: CanvasItem, style: int, width: float, open: bool) -> void:
	var pen := _Pen.new(canvas, width)
	var flap: PackedVector2Array = get_flap_polygon(style)
	if open:
		for i in range(flap.size()):
			flap[i].y = -flap[i].y + 2.0
		pen.fill(flap, FLAP[style])
		var colors: Array = LINING[style]
		for inset in Geometry2D.offset_polygon(flap, -9.0):
			var lined: PackedVector2Array = inset
			pen.fill(lined, colors[0])
			pen.stripes(lined, 10.0, 2.0, 30.0, colors[1])
	else:
		pen.fill(flap, FLAP[style])
		if style == Style.BRITISH:
			_draw_laid_in(pen, flap)
	# Every edge but the top one, which is the envelope's own.
	var edges: PackedVector2Array = flap.slice(1)
	edges.append(flap[0])
	pen.line(edges, INK, STROKE)

static func draw_pocket(canvas: CanvasItem, style: int, width: float) -> void:
	var pen := _Pen.new(canvas, width)
	var h: float = get_view_height(style)
	var pocket: PackedVector2Array = get_pocket_polygon(style)
	pen.fill(pocket, PAPER[style])
	match style:
		Style.BRITISH:
			_draw_laid_in(pen, pocket)
		Style.AMERICAN:
			for band in [Rect2(1, 1, AIRMAIL_BAND, h - 2), Rect2(319 - AIRMAIL_BAND, 1, AIRMAIL_BAND, h - 2), Rect2(1, h - 1 - AIRMAIL_BAND, 318, AIRMAIL_BAND)]:
				for part in Geometry2D.intersect_polygons(_rect_points(band), pocket):
					_draw_airmail_stripes(pen, part)
	for fold in get_fold_lines(style):
		pen.line(fold, INK, FOLD_STROKE)
	# Only the notch, where the pocket meets the lining; its other sides are
	# the envelope's own.
	pen.line(pocket.slice(0, pocket.size() - 2), INK, STROKE)

## The back as it lies in the grid, flap down.
static func draw_back(canvas: CanvasItem, style: int, width: float) -> void:
	draw_pocket(canvas, style, width)
	draw_flap(canvas, style, width, false)

# --- Shapes ---------------------------------------------------------------------

static func get_flap_polygon(style: int) -> PackedVector2Array:
	match style:
		Style.HUNGARIAN:
			return PackedVector2Array([Vector2(1, 1), Vector2(319, 1), Vector2(300, 66), Vector2(20, 66)])
		Style.CZECH:
			var points := PackedVector2Array([Vector2(1, 1)])
			points.append_array(_cubic(Vector2(319, 1), Vector2(306, 112), Vector2(14, 112), Vector2(1, 1)))
			return points
		Style.AMERICAN:
			return PackedVector2Array([Vector2(1, 1), Vector2(319, 1), Vector2(160, 80)])
	return PackedVector2Array([Vector2(1, 1), Vector2(319, 1), Vector2(160, 150)])

## The back below the opening: notched at the top where the side flaps meet.
static func get_pocket_polygon(style: int) -> PackedVector2Array:
	var h: float = get_view_height(style)
	var notch: Array[Vector2] = []
	match style:
		Style.BRITISH:
			notch = [Vector2(160, 89)]
		Style.HUNGARIAN:
			notch = [Vector2(110, 58), Vector2(210, 58)]
		Style.CZECH:
			notch = [Vector2(160, 96)]
		Style.AMERICAN:
			notch = [Vector2(160, 58)]
	var points := PackedVector2Array([Vector2(1, 1)])
	points.append_array(PackedVector2Array(notch))
	points.append_array(PackedVector2Array([Vector2(319, 1), Vector2(319, h - 1), Vector2(1, h - 1)]))
	return points

static func get_fold_lines(style: int) -> Array[PackedVector2Array]:
	var h: float = get_view_height(style)
	match style:
		Style.HUNGARIAN:
			return [PackedVector2Array([Vector2(1, h - 1), Vector2(120, 104), Vector2(200, 104), Vector2(319, h - 1)])]
		Style.CZECH:
			return [PackedVector2Array([Vector2(1, h - 1), Vector2(136, 118)]), PackedVector2Array([Vector2(319, h - 1), Vector2(184, 118)])]
		Style.AMERICAN:
			return [PackedVector2Array([Vector2(9, 131), Vector2(130, 74)]), PackedVector2Array([Vector2(311, 131), Vector2(190, 74)])]
	return [PackedVector2Array([Vector2(1, h - 1), Vector2(150, 118)]), PackedVector2Array([Vector2(319, h - 1), Vector2(170, 118)])]

## The mark's box on the front, in the envelope's own pixels: the stamp's
## size (a stamp is 1.36 times as tall as it is wide) at the top right.
static func get_stamp_rect(width: float) -> Rect2:
	var mark_width: float = width * MARK_WIDTH
	var mark_size := Vector2(mark_width, mark_width * 1.36)
	return Rect2(Vector2(width - width * MARK_MARGIN - mark_size.x, width * MARK_MARGIN), mark_size)

# --- Marks ----------------------------------------------------------------------

## A round postmark with cancellation waves and, struck in the middle, the
## coin's own face: a 1 between two sprigs of laurel (Assets/coin.svg). The
## postage - the reward - is paid in coins. Drawn in ink only, so it can take
## the UI's ink stamp on a layer of its own.
static func draw_postmark(canvas: CanvasItem, width: float) -> void:
	var mark_width: float = width * MARK_WIDTH * POSTMARK_SHARE
	var scale: float = mark_width / 120.0
	var origin := Vector2(width - width * 0.025 - mark_width, width * 0.03)
	var ink := Color(POSTMARK_INK, 0.88)
	var pivot: Vector2 = origin + Vector2(60, 30) * scale
	canvas.draw_set_transform(pivot, deg_to_rad(-10.0), Vector2.ONE * scale)
	var centre := Vector2(30, 0)
	_dashed_arc(canvas, centre, 27.0, [22.0, 2.0, 9.0, 2.0], ink, 2.2)
	var font: Font = _numeral_font()
	var numeral_size: int = 30
	var numeral_width: float = font.get_string_size("1", HORIZONTAL_ALIGNMENT_LEFT, -1, numeral_size).x
	canvas.draw_string(font, centre + Vector2(-numeral_width * 0.5, numeral_size * 0.36), "1", HORIZONTAL_ALIGNMENT_LEFT, -1, numeral_size, ink)
	for side in [-1.0, 1.0]:
		_draw_laurel_sprig(canvas, centre, side, ink)
	# The SVG's "q6.5 -6 13 0 t13 0 ...": a wave 26 long and 3 high.
	for y in [-12.0, 0.0, 12.0]:
		var wave: PackedVector2Array = PackedVector2Array()
		for i in range(53):
			var x: float = -58.0 + float(i)
			wave.append(Vector2(x, y - 3.0 * sin(PI * (x + 58.0) / 13.0)))
		_dashed_polyline(canvas, wave, [40.0, 3.0, 18.0, 2.0], ink, 2.2)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## One sprig beside the 1, `side` -1 to its left and 1 to its right: a stem
## bending out and up from under the numeral, four leaves along it.
static func _draw_laurel_sprig(canvas: CanvasItem, centre: Vector2, side: float, ink: Color) -> void:
	var start: Vector2 = centre + Vector2(side * 3.0, 15.0)
	var control: Vector2 = centre + Vector2(side * 19.0, 13.0)
	var end: Vector2 = centre + Vector2(side * 20.0, -9.0)
	var stem := PackedVector2Array()
	for i in range(13):
		var t: float = float(i) / 12.0
		stem.append(start.lerp(control, t).lerp(control.lerp(end, t), t))
	canvas.draw_polyline(stem, ink, 1.4, true)
	for leaf in range(4):
		var t: float = 0.3 + 0.21 * leaf
		var at: Vector2 = start.lerp(control, t).lerp(control.lerp(end, t), t)
		var ahead: Vector2 = start.lerp(control, t + 0.05).lerp(control.lerp(end, t + 0.05), t + 0.05)
		var along: Vector2 = (ahead - at).normalized()
		# Leaves alternate inwards and outwards of the stem, pointing up it.
		var out: Vector2 = Vector2(-along.y, along.x) * (1.0 if leaf % 2 == 0 else -1.0) * side
		_draw_leaf(canvas, at, at + (along * 0.75 + out * 0.65).normalized() * 7.5, 2.1, ink)
	_draw_leaf(canvas, end, end + Vector2(side * 0.25, -1.0).normalized() * 7.0, 2.0, ink)

## A pointed leaf from `base` to `tip`, `half_width` across at its widest.
static func _draw_leaf(canvas: CanvasItem, base: Vector2, tip: Vector2, half_width: float, ink: Color) -> void:
	var along: Vector2 = tip - base
	var across: Vector2 = Vector2(-along.y, along.x).normalized() * half_width
	var leaf := PackedVector2Array()
	for i in range(9):
		var t: float = float(i) / 8.0
		leaf.append(base + along * t + across * sin(PI * t))
	for i in range(7, 0, -1):
		var t: float = float(i) / 8.0
		leaf.append(base + along * t - across * sin(PI * t))
	canvas.draw_colored_polygon(leaf, ink)

static var _numeral: FontVariation

## The coin's numeral is a heavy serif; Alegreya at its boldest is the
## nearest in the game's fonts.
static func _numeral_font() -> Font:
	if _numeral == null:
		_numeral = FontVariation.new()
		_numeral.base_font = load("res://Fonts/Alegreya-VariableFont_wght.ttf") as Font
		_numeral.variation_opentype = {2003265652: 800}
	return _numeral

## Red wax with a pencil pressed into it: the reward is draw points.
static func draw_wax_seal(canvas: CanvasItem, width: float) -> void:
	var seal_width: float = width * MARK_WIDTH * 1.15
	var scale: float = seal_width / 60.0
	var origin := Vector2(width - width * MARK_MARGIN - seal_width, width * 0.035)
	canvas.draw_set_transform(origin + Vector2(0, 1.0), 0.0, Vector2.ONE * scale)
	var blob: PackedVector2Array = _wax_blob()
	canvas.draw_colored_polygon(blob, Color(0, 0, 0, 0.18))
	canvas.draw_set_transform(origin, 0.0, Vector2.ONE * scale)
	canvas.draw_circle(Vector2(51, 48), 4.5, WAX)
	canvas.draw_circle(Vector2(8, 44), 3.0, WAX)
	canvas.draw_colored_polygon(blob, WAX)
	blob.append(blob[0])
	canvas.draw_polyline(blob, WAX_EDGE, 1.2, true)
	canvas.draw_arc(Vector2(30, 30), 16.0, 0.0, TAU, 40, WAX_DEEP, 2.2, true)
	canvas.draw_arc(Vector2(30, 30), 16.0, deg_to_rad(-145.0), deg_to_rad(-95.0), 12, Color(WAX_SHINE, 0.8), 1.5, true)
	# The pencil, after the top bar's draw point icon, pressed in.
	var pencil: Array[Vector2] = [Vector2(7.7, 16.3), Vector2(8.6, 13.4), Vector2(14.8, 7.2), Vector2(16.8, 9.2), Vector2(10.6, 15.4)]
	var pressed := PackedVector2Array()
	for point in pencil:
		pressed.append((point - Vector2(12, 12)) * 1.45 + Vector2(30, 30))
	canvas.draw_colored_polygon(pressed, WAX_DEEP)
	canvas.draw_line((Vector2(13.6, 8.4) - Vector2(12, 12)) * 1.45 + Vector2(30, 30), (Vector2(15.6, 10.4) - Vector2(12, 12)) * 1.45 + Vector2(30, 30), WAX, 1.2, true)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func _wax_blob() -> PackedVector2Array:
	var points := PackedVector2Array([Vector2(30, 3)])
	var segments: Array = [
		[Vector2(40, 2), Vector2(47, 8), Vector2(52, 13)],
		[Vector2(58, 19), Vector2(58, 27), Vector2(57, 33)],
		[Vector2(56, 42), Vector2(52, 49), Vector2(44, 54)],
		[Vector2(37, 58), Vector2(27, 58), Vector2(19, 55)],
		[Vector2(11, 51), Vector2(5, 45), Vector2(3, 36)],
		[Vector2(1, 27), Vector2(4, 18), Vector2(10, 12)],
		[Vector2(15, 6), Vector2(22, 3), Vector2(30, 3)],
	]
	var start := Vector2(30, 3)
	for segment in segments:
		var curve: PackedVector2Array = _cubic(start, segment[0], segment[1], segment[2], 8)
		points.append_array(curve.slice(1))
		start = segment[2]
	points.remove_at(points.size() - 1)
	return points

# --- Paper ----------------------------------------------------------------------

## Laid paper: fine horizontal lines, and with `chain_lines` the wider-spaced
## vertical ones.
static func _draw_laid(pen: _Pen, h: float, chain_lines: bool) -> void:
	var y: float = 4.0
	while y < h - 2.0:
		pen.rect(Rect2(2, y, 316, 1.2), LAID_LINE)
		y += 4.0
	if chain_lines:
		for x in [64.0, 128.0, 192.0, 256.0]:
			pen.rect(Rect2(x - 0.6, 2, 1.2, h - 4), LAID_LINE)

## Laid lines inside a shape.
static func _draw_laid_in(pen: _Pen, shape: PackedVector2Array) -> void:
	var bounds: Rect2 = _bounds(shape)
	var y: float = ceilf(bounds.position.y / 4.0) * 4.0
	while y < bounds.end.y:
		for part in Geometry2D.intersect_polygons(_rect_points(Rect2(bounds.position.x, y, bounds.size.x, 1.2)), shape):
			pen.fill(part, LAID_LINE)
		y += 4.0

static func _draw_airmail_band(pen: _Pen, outer: Rect2, all_sides: bool) -> void:
	var bands: Array[Rect2] = [
		Rect2(outer.position, Vector2(outer.size.x, AIRMAIL_BAND)),
		Rect2(Vector2(outer.position.x, outer.end.y - AIRMAIL_BAND), Vector2(outer.size.x, AIRMAIL_BAND)),
		Rect2(outer.position + Vector2(0, AIRMAIL_BAND), Vector2(AIRMAIL_BAND, outer.size.y - AIRMAIL_BAND * 2.0)),
		Rect2(Vector2(outer.end.x - AIRMAIL_BAND, outer.position.y + AIRMAIL_BAND), Vector2(AIRMAIL_BAND, outer.size.y - AIRMAIL_BAND * 2.0)),
	]
	if !all_sides:
		bands.remove_at(0)
	for band in bands:
		_draw_airmail_stripes(pen, _rect_points(band))

## Red and blue stripes at 45°, 22 apart, as the mock-up's airmail pattern.
static func _draw_airmail_stripes(pen: _Pen, area: PackedVector2Array) -> void:
	pen.stripes(area, 22.0, 7.0, 45.0, AIRMAIL_RED)
	pen.stripes(area, 22.0, 7.0, 45.0, AIRMAIL_BLUE, 11.0)

static func _rect_points(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])

static func _bounds(points: PackedVector2Array) -> Rect2:
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	return bounds

static func _cubic(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, segments: int = CURVE_SEGMENTS) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		points.append(p0.bezier_interpolate(p1, p2, p3, t))
	return points

static func _dashed_arc(canvas: CanvasItem, center: Vector2, radius: float, dashes: Array, color: Color, line_width: float) -> void:
	var circle := PackedVector2Array()
	for i in range(73):
		circle.append(center + Vector2.from_angle(TAU * float(i) / 72.0) * radius)
	_dashed_polyline(canvas, circle, dashes, color, line_width)

## A polyline drawn as dashes and gaps in turn, an SVG dasharray.
static func _dashed_polyline(canvas: CanvasItem, points: PackedVector2Array, dashes: Array, color: Color, line_width: float) -> void:
	var dash_index: int = 0
	var left: float = float(dashes[0])
	var drawing: bool = true
	var current := PackedVector2Array([points[0]])
	for i in range(1, points.size()):
		var from: Vector2 = points[i - 1]
		var to: Vector2 = points[i]
		var length: float = from.distance_to(to)
		var done: float = 0.0
		while length - done > left:
			done += left
			var at: Vector2 = from.lerp(to, done / length)
			if drawing:
				current.append(at)
				if current.size() >= 2:
					canvas.draw_polyline(current, color, line_width, true)
			current = PackedVector2Array([at])
			drawing = !drawing
			dash_index = (dash_index + 1) % dashes.size()
			left = float(dashes[dash_index])
		left -= length - done
		if drawing:
			current.append(to)
	if drawing and current.size() >= 2:
		canvas.draw_polyline(current, color, line_width, true)

## Draws in the 320-unit view box, scaled to the width asked for.
class _Pen:
	var canvas: CanvasItem
	var scale: float

	func _init(target: CanvasItem, width: float) -> void:
		canvas = target
		scale = width / VIEW_WIDTH

	func _at(point: Vector2) -> Vector2:
		return point * scale

	func _all(points: PackedVector2Array) -> PackedVector2Array:
		var scaled := PackedVector2Array()
		for point in points:
			scaled.append(point * scale)
		return scaled

	func fill(points: PackedVector2Array, color: Color) -> void:
		if points.size() < 3:
			return
		var scaled: PackedVector2Array = _all(points)
		if Geometry2D.triangulate_polygon(scaled).is_empty():
			return
		canvas.draw_colored_polygon(scaled, color)

	func rect(area: Rect2, color: Color) -> void:
		canvas.draw_rect(Rect2(area.position * scale, area.size * scale), color)

	func rect_outline(area: Rect2, color: Color, line_width: float) -> void:
		canvas.draw_rect(Rect2(area.position * scale, area.size * scale), color, false, maxf(1.0, line_width * scale))

	## A paper body with rounded corners.
	func paper_rect(area: Rect2, color: Color) -> void:
		var box := StyleBoxFlat.new()
		box.bg_color = color
		box.set_corner_radius_all(int(round(CORNER_RADIUS * scale)))
		box.anti_aliasing = true
		canvas.draw_style_box(box, Rect2(area.position * scale, area.size * scale))

	func line(points: PackedVector2Array, color: Color, line_width: float) -> void:
		canvas.draw_polyline(_all(points), color, line_width, true)

	## Parallel stripes `stripe` wide every `period` units, turned `angle`
	## degrees, inside `area`.
	func stripes(area: PackedVector2Array, period: float, stripe: float, angle: float, color: Color, offset: float = 0.0) -> void:
		var bounds: Rect2 = EnvelopeArt._bounds(area)
		var direction := Vector2.from_angle(deg_to_rad(angle))
		var across := Vector2(-direction.y, direction.x)
		var corners: Array[Vector2] = [bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)]
		var low: float = INF
		var high: float = -INF
		for corner in corners:
			var depth: float = corner.dot(direction)
			low = minf(low, depth)
			high = maxf(high, depth)
		var reach: float = bounds.size.length()
		var along: float = bounds.get_center().dot(across)
		var at: float = floorf((low - offset) / period) * period + offset
		while at < high:
			var band := PackedVector2Array([
				direction * at + across * (along - reach),
				direction * (at + stripe) + across * (along - reach),
				direction * (at + stripe) + across * (along + reach),
				direction * at + across * (along + reach),
			])
			for part in Geometry2D.intersect_polygons(band, area):
				fill(part, color)
			at += period
