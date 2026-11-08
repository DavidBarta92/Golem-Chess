extends RefCounted
class_name CutStroke

## One drawn path measured against a CutGuide, while it is being drawn: how far
## it has got, how much of the guide it has followed, and how far it strayed.
## Feed it with begin() and extend(), in the guide's space; CutArea does that
## for a mouse.
##
## `points` is the path as drawn. For a cut around an outline that is the shape
## actually cut out, which a PolygonClip can show.

## The path is measured at this spacing, so a fast mouse leaves no gaps.
const SAMPLE_SPACING: float = 3.0
## The guide is divided into stretches this long to tell which it has been followed along.
const COVERAGE_STRETCH: float = 6.0

var guide: CutGuide
## How far from the guide the path may stray and still count as following it.
var tolerance: float = 12.0
var points: PackedVector2Array = PackedVector2Array()
## 1 along the guide's own direction, -1 against it, 0 until the path has moved.
var direction: int = 0

var _start_along: float = 0.0
var _least_along: float = INF
var _most_along: float = -INF
var _covered: PackedByteArray = PackedByteArray()
var _sample_count: int = 0
var _deviation_sum: float = 0.0
var _max_deviation: float = 0.0

func _init(new_guide: CutGuide, new_tolerance: float = 12.0) -> void:
	guide = new_guide
	tolerance = new_tolerance
	_covered.resize(maxi(1, int(ceil(guide.length / COVERAGE_STRETCH))))

func begin(point: Vector2) -> void:
	points.append(point)
	_start_along = guide.project(point).x
	_measure(point)

func extend(point: Vector2) -> void:
	if points.is_empty():
		begin(point)
		return
	var last: Vector2 = points[-1]
	var steps: int = maxi(1, int(ceil(last.distance_to(point) / SAMPLE_SPACING)))
	for i in range(1, steps + 1):
		_measure(last.lerp(point, float(i) / float(steps)))
	points.append(point)

## How far along the guide the path has reached, 0 to 1, counted from the end it
## is heading away from. Pass a direction to count from that end instead.
func get_reach(towards: int = 0) -> float:
	if guide.length <= 0.0 or _most_along < _least_along:
		return 0.0
	var heading: int = towards if towards != 0 else direction
	if heading == 0:
		return 0.0
	var reached: float = _most_along if heading > 0 else guide.length - _least_along
	return clampf(reached / guide.length, 0.0, 1.0)

## The share of the guide the path has followed within the tolerance, in any order.
func get_coverage() -> float:
	return float(_covered.count(1)) / float(_covered.size())

func get_mean_deviation() -> float:
	return _deviation_sum / float(_sample_count) if _sample_count > 0 else 0.0

func get_max_deviation() -> float:
	return _max_deviation

## 1 for a path right on the guide, 0 for one straying as far as the tolerance on average.
func get_accuracy() -> float:
	return clampf(1.0 - get_mean_deviation() / maxf(tolerance, 0.001), 0.0, 1.0)

## Whether the path came back to where it began.
func is_loop_closed() -> bool:
	return points.size() > 2 and points[0].distance_to(points[-1]) <= tolerance * 2.0

## Whether this is a good cut: it followed the guide all the way, never strayed
## past the tolerance, and an outline's path met itself.
func passes(min_coverage: float = 0.95) -> bool:
	if get_coverage() < min_coverage or _max_deviation > tolerance:
		return false
	return !guide.closed or is_loop_closed()

func _measure(point: Vector2) -> void:
	var spot: Vector2 = guide.project(point)
	_sample_count += 1
	_deviation_sum += spot.y
	_max_deviation = maxf(_max_deviation, spot.y)
	_least_along = minf(_least_along, spot.x)
	_most_along = maxf(_most_along, spot.x)
	if spot.y <= tolerance:
		var stretch: int = int(spot.x / guide.length * float(_covered.size())) if guide.length > 0.0 else 0
		_covered[mini(stretch, _covered.size() - 1)] = 1
	if direction == 0 and absf(spot.x - _start_along) >= SAMPLE_SPACING:
		direction = 1 if spot.x > _start_along else -1
