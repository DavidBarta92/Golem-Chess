extends RefCounted

## The top bar's ink-line icons, drawn straight onto a CanvasItem so they need
## no imported textures. Each is laid out on a 24-unit grid (the design's SVG
## paths in Docs/TopBar/design/reference/bundle.js) and scaled into the rect.
## A mono icon drops its meaning-carrying fills and is drawn in one colour,
## as on a ribbon. Whatever its size, an icon's ordinary line (LINE on the
## grid) shows as TopBarStyle.STROKE, as the style plan asks; heavier and
## lighter lines keep their ratio to it.

const TopBarStyle = preload("res://Scripts/TopBar/TopBarStyle.gd")

const GRID: float = 24.0
const LINE: float = 1.75
## The most of a small icon its line may take, so a 9-unit check or a 7.5-unit
## hourglass keeps its openings: their lines stay under the stroke.
const MAX_STROKE_SHARE: float = 1.0 / 7.0
const CURVE_SEGMENTS: int = 10

static func draw_icon(canvas: CanvasItem, icon_name: String, rect: Rect2, color: Color, mono: bool = false) -> void:
	var scale: float = minf(rect.size.x, rect.size.y) / GRID
	var origin: Vector2 = rect.position + (rect.size - Vector2.ONE * GRID * scale) * 0.5
	var pen := _Pen.new(canvas, origin, scale, color)
	match icon_name:
		"coin":
			if !mono:
				pen.fill_circle(Vector2(12, 12), 9.0, TopBarStyle.COIN)
			pen.circle(Vector2(12, 12), 9.0)
			pen.circle(Vector2(12, 12), 5.4, 1.25)
			pen.fill_circle(Vector2(12, 12), 1.3, color)
		"draw":
			if !mono:
				pen.fill_circle(Vector2(12, 12), 9.0, TopBarStyle.DRAW)
			pen.circle(Vector2(12, 12), 9.0)
			var pencil: Array[Vector2] = [Vector2(7.7, 16.3), Vector2(8.6, 13.4), Vector2(14.8, 7.2), Vector2(16.8, 9.2), Vector2(10.6, 15.4)]
			if !mono:
				pen.fill(pencil, TopBarStyle.PAPER)
			pen.closed_line(pencil, 1.3)
			pen.line([Vector2(13.6, 8.4), Vector2(15.6, 10.4)], 1.3)
		"rank":
			pen.line([Vector2(6, 13.4), Vector2(12, 7.8), Vector2(18, 13.4)], 2.1)
			pen.line([Vector2(6, 18.6), Vector2(12, 13), Vector2(18, 18.6)], 2.1)
		"menu":
			# 6 apart rather than the design's 4.8, so the heavier stroke leaves gaps.
			pen.line(_cubic(Vector2(4.5, 6.2), Vector2(9.5, 5.7), Vector2(14.5, 5.8), Vector2(19.5, 6.2)))
			pen.line(_cubic(Vector2(4.5, 12), Vector2(9.5, 12.4), Vector2(14.5, 12.3), Vector2(19.5, 12)))
			pen.line(_cubic(Vector2(4.5, 17.8), Vector2(9.5, 17.4), Vector2(14.5, 17.4), Vector2(19.5, 17.9)))
		"gear":
			pen.closed_line(_gear_outline())
			# Smaller than the design's 3, so the heavier stroke leaves its gap.
			pen.circle(Vector2(12, 12), 2.4)
		"help":
			pen.circle(Vector2(12, 12), 9.0)
			var hook: Array[Vector2] = _cubic(Vector2(9.4, 9.6), Vector2(9.4, 8.0), Vector2(10.6, 7.0), Vector2(12, 7))
			hook.append_array(_cubic(Vector2(12, 7), Vector2(13.4, 7), Vector2(14.6, 8), Vector2(14.6, 9.4)).slice(1))
			hook.append_array(_cubic(Vector2(14.6, 9.4), Vector2(14.6, 11.4), Vector2(12, 11.6), Vector2(12, 13.8)).slice(1))
			pen.line(hook)
			pen.fill_circle(Vector2(12, 16.9), 1.0, color)
		"door":
			pen.line([Vector2(13.5, 4.5), Vector2(6.5, 4.5), Vector2(6.5, 19.5), Vector2(13.5, 19.5)])
			pen.line([Vector2(10, 12), Vector2(20, 12)])
			pen.line([Vector2(16.8, 8.8), Vector2(20, 12), Vector2(16.8, 15.2)])
		"people":
			pen.circle(Vector2(9, 8.5), 3.0)
			var shoulders: Array[Vector2] = _cubic(Vector2(3.5, 19), Vector2(4.1, 15.6), Vector2(6.2, 13.8), Vector2(9, 13.8))
			shoulders.append_array(_cubic(Vector2(9, 13.8), Vector2(11.8, 13.8), Vector2(13.9, 15.6), Vector2(14.5, 19)).slice(1))
			pen.line(shoulders)
			pen.circle(Vector2(16.5, 9.5), 2.4)
			pen.line(_cubic(Vector2(15.6, 14), Vector2(18, 13.8), Vector2(19.8, 15.4), Vector2(20.5, 18.6)))
		"person":
			pen.circle(Vector2(12, 8.5), 3.2)
			var body: Array[Vector2] = _cubic(Vector2(6, 19.5), Vector2(6.6, 15.8), Vector2(8.9, 13.9), Vector2(12, 13.9))
			body.append_array(_cubic(Vector2(12, 13.9), Vector2(15.1, 13.9), Vector2(17.4, 15.8), Vector2(18, 19.5)).slice(1))
			pen.line(body)
		"book":
			pen.closed_line(_book_page(false))
			pen.closed_line(_book_page(true))
		"hourglass":
			pen.line([Vector2(7, 4), Vector2(17, 4)])
			pen.line([Vector2(7, 20), Vector2(17, 20)])
			var side: Array[Vector2] = _cubic(Vector2(8.2, 4), Vector2(8.2, 8.6), Vector2(12, 9.6), Vector2(12, 12))
			side.append_array(_cubic(Vector2(12, 12), Vector2(12, 14.4), Vector2(8.2, 15.4), Vector2(8.2, 20)).slice(1))
			pen.line(side)
			pen.line(_mirrored(side))
		"check":
			pen.line([Vector2(6, 12.6), Vector2(9.8, 16.2), Vector2(18, 8)], 2.4)

## The small ribbon silhouette in front of a quest's kind: the same cut as the
## ribbon, filled with the reward's colour.
static func draw_mini_ribbon(canvas: CanvasItem, kind: String, rect: Rect2, fill_color: Color, ink: Color) -> void:
	# The silhouette is 28 x 40 inside a -2..30 x -2..42 box.
	var scale: float = minf(rect.size.x / 32.0, rect.size.y / 44.0)
	var origin: Vector2 = rect.position + Vector2(2.0, 2.0) * scale
	var outline: Array[Vector2]
	match kind:
		"story":
			outline = [Vector2(0, 0), Vector2(28, 0), Vector2(28, 30), Vector2(0, 40)]
		"daily":
			outline = [Vector2(0, 0), Vector2(28, 0), Vector2(28, 40), Vector2(22, 40), Vector2(22, 32), Vector2(17, 32), Vector2(17, 40), Vector2(11, 40), Vector2(11, 32), Vector2(6, 32), Vector2(6, 40), Vector2(0, 40)]
		_:
			outline = [Vector2(0, 0), Vector2(28, 0), Vector2(28, 40), Vector2(14, 30), Vector2(0, 40)]
	var points := PackedVector2Array()
	for point in outline:
		points.append(origin + point * scale)
	canvas.draw_colored_polygon(points, fill_color)
	points.append(points[0])
	canvas.draw_polyline(points, ink, stroke_for(minf(rect.size.x, rect.size.y)), true)

## The width an icon's ordinary line shows at, for an icon that size.
static func stroke_for(icon_size: float) -> float:
	return minf(TopBarStyle.STROKE, icon_size * MAX_STROKE_SHARE)

static func _cubic(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for index in range(CURVE_SEGMENTS + 1):
		var t: float = float(index) / float(CURVE_SEGMENTS)
		var u: float = 1.0 - t
		points.append(p0 * u * u * u + p1 * 3.0 * u * u * t + p2 * 3.0 * u * t * t + p3 * t * t * t)
	return points

static func _mirrored(points: Array[Vector2]) -> Array[Vector2]:
	var mirrored: Array[Vector2] = []
	for point in points:
		mirrored.append(Vector2(GRID - point.x, point.y))
	return mirrored

static func _book_page(right: bool) -> Array[Vector2]:
	var page: Array[Vector2] = _cubic(Vector2(3.5, 6.5), Vector2(6.5, 5.5), Vector2(9.3, 5.6), Vector2(12, 7.3))
	page.append_array(_cubic(Vector2(12, 18.5), Vector2(9.3, 16.9), Vector2(6.5, 16.7), Vector2(3.5, 17.7)))
	return _mirrored(page) if right else page

static func _gear_outline() -> Array[Vector2]:
	var teeth: int = 8
	var outer: float = 9.4
	var inner: float = 7.2
	var step: float = TAU / float(teeth)
	var points: Array[Vector2] = []
	for index in range(teeth):
		var angle: float = index * step - PI * 0.5
		points.append(Vector2(12, 12) + Vector2.from_angle(angle - step * 0.22) * inner)
		points.append(Vector2(12, 12) + Vector2.from_angle(angle - step * 0.13) * outer)
		points.append(Vector2(12, 12) + Vector2.from_angle(angle + step * 0.13) * outer)
		points.append(Vector2(12, 12) + Vector2.from_angle(angle + step * 0.22) * inner)
	return points

## Draws grid-space shapes into the icon's rect.
class _Pen:
	var canvas: CanvasItem
	var origin: Vector2
	var scale: float
	var color: Color

	func _init(target: CanvasItem, at: Vector2, unit: float, ink: Color) -> void:
		canvas = target
		origin = at
		scale = unit
		color = ink

	func _map(points: Array[Vector2]) -> PackedVector2Array:
		var mapped := PackedVector2Array()
		for point in points:
			mapped.append(origin + point * scale)
		return mapped

	func _width(grid_width: float) -> float:
		# stroke_for(), for the icon's size.
		return minf(TopBarStyle.STROKE, GRID * scale * MAX_STROKE_SHARE) * grid_width / LINE

	## An open stroke with round ends.
	func line(points: Array[Vector2], grid_width: float = LINE) -> void:
		var mapped: PackedVector2Array = _map(points)
		var width: float = _width(grid_width)
		canvas.draw_polyline(mapped, color, width, true)
		if width >= 1.5:
			canvas.draw_circle(mapped[0], width * 0.5, color)
			canvas.draw_circle(mapped[mapped.size() - 1], width * 0.5, color)

	func closed_line(points: Array[Vector2], grid_width: float = LINE) -> void:
		var mapped: PackedVector2Array = _map(points)
		mapped.append(mapped[0])
		canvas.draw_polyline(mapped, color, _width(grid_width), true)

	func fill(points: Array[Vector2], fill_color: Color) -> void:
		canvas.draw_colored_polygon(_map(points), fill_color)

	func circle(center: Vector2, radius: float, grid_width: float = LINE) -> void:
		canvas.draw_arc(origin + center * scale, radius * scale, 0.0, TAU, 40, color, _width(grid_width), true)

	func fill_circle(center: Vector2, radius: float, fill_color: Color) -> void:
		canvas.draw_circle(origin + center * scale, radius * scale, fill_color, true, -1.0, true)
