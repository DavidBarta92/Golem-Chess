extends RefCounted
class_name CutGuide

## The line a cut is meant to follow: a straight tear across a pack, or the
## outline of a die, such as a square around a stamp on an envelope. Geometry
## only; CutStroke measures a drawn path against it. The points are in whatever
## space the path is drawn in. Docs/Cutting/CUTTING.md shows how the parts fit.

var points: PackedVector2Array = PackedVector2Array()
var closed: bool = false
## The whole way round, the closing side of an outline included.
var length: float = 0.0

# How far along the guide each point lies. An outline's first point comes again
# at the end of `points`, so every side is one segment.
var _distances: PackedFloat32Array = PackedFloat32Array()

static func line(from: Vector2, to: Vector2) -> CutGuide:
	return CutGuide.new(PackedVector2Array([from, to]), false)

static func outline(corners: PackedVector2Array) -> CutGuide:
	return CutGuide.new(corners, true)

static func rectangle(rect: Rect2) -> CutGuide:
	return outline(PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.end,
		rect.position + Vector2(0.0, rect.size.y),
	]))

func _init(new_points: PackedVector2Array = PackedVector2Array(), new_closed: bool = false) -> void:
	points = new_points.duplicate()
	closed = new_closed
	if closed and !points.is_empty():
		points.append(points[0])
	_distances.resize(points.size())
	for i in range(1, points.size()):
		_distances[i] = _distances[i - 1] + points[i - 1].distance_to(points[i])
	length = _distances[-1] if !_distances.is_empty() else 0.0

## The point this far along the guide.
func point_at(distance: float) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var along: float = fposmod(distance, length) if closed and length > 0.0 else clampf(distance, 0.0, length)
	for i in range(1, points.size()):
		if along <= _distances[i]:
			var side: float = _distances[i] - _distances[i - 1]
			return points[i - 1].lerp(points[i], (along - _distances[i - 1]) / side) if side > 0.0 else points[i]
	return points[-1]

## Where a point falls on the guide: x is how far along the guide its nearest
## spot lies, y how far the point is from that spot.
func project(point: Vector2) -> Vector2:
	var nearest := Vector2(0.0, INF)
	for i in range(1, points.size()):
		var spot: Vector2 = Geometry2D.get_closest_point_to_segment(point, points[i - 1], points[i])
		var away: float = point.distance_to(spot)
		if away < nearest.y:
			nearest = Vector2(_distances[i - 1] + points[i - 1].distance_to(spot), away)
	return nearest
