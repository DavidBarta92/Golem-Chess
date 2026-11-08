extends SceneTree

# Headless run of the cut logic's self-test; the exit code is 1 if a case fails:
#   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/cutting_selftest.gd
# The scripts are loaded by path because a --script file must not name project classes.

var CutGuide: Script
var CutStroke: Script
var checked: int = 0
var failed: int = 0

func _initialize() -> void:
	CutGuide = load("res://Scripts/Cutting/CutGuide.gd")
	CutStroke = load("res://Scripts/Cutting/CutStroke.gd")
	_test_tear_along_a_line()
	_test_die_cut_around_a_square()
	# A script that fails to compile skips the checks; that must not read as a pass.
	var passed: bool = failed == 0 and checked > 0
	print("Cutting self-test: %s" % ("%d passed" % checked if passed else "%d of %d failed" % [failed, checked]))
	quit(0 if passed else 1)

func _check(name: String, passed: bool, detail: Variant = "") -> void:
	print("%s  %s  %s" % ["ok  " if passed else "FAIL", name, str(detail)])
	checked += 1
	if !passed:
		failed += 1

func _stroke(guide: Object, path: Array, tolerance: float) -> Object:
	var stroke: Object = CutStroke.new(guide, tolerance)
	stroke.begin(path[0])
	for i in range(1, path.size()):
		stroke.extend(path[i])
	return stroke

func _test_tear_along_a_line() -> void:
	var guide: Object = CutGuide.line(Vector2(0, 0), Vector2(300, 0))
	var forward: Object = _stroke(guide, [Vector2(10, 4), Vector2(150, -3)], 1000.0)
	_check("a drag heads along the line", forward.direction == 1, forward.direction)
	_check("reach counts from the far end it left", is_equal_approx(forward.get_reach(), 0.5), forward.get_reach())

	var backward: Object = _stroke(guide, [Vector2(290, 0), Vector2(60, 40)], 1000.0)
	_check("a drag the other way heads against it", backward.direction == -1, backward.direction)
	_check("reach counts from that end", is_equal_approx(backward.get_reach(), 0.8), backward.get_reach())
	_check("a second stroke can count from the first one's end", is_equal_approx(backward.get_reach(1), 290.0 / 300.0), backward.get_reach(1))

	var still: Object = _stroke(guide, [Vector2(100, 0), Vector2(100, 200)], 1000.0)
	_check("a drag across the line goes nowhere", still.direction == 0 and still.get_reach() == 0.0, still.direction)

	var fast: Object = _stroke(guide, [Vector2(0, 0), Vector2(300, 0)], 12.0)
	_check("one huge mouse step leaves no gaps", is_equal_approx(fast.get_coverage(), 1.0), fast.get_coverage())

func _test_die_cut_around_a_square() -> void:
	var rect := Rect2(0, 0, 100, 100)
	var guide: Object = CutGuide.rectangle(rect)
	_check("the outline's length includes the closing side", is_equal_approx(guide.length, 400.0), guide.length)
	_check("point_at goes round", guide.point_at(250.0).is_equal_approx(Vector2(50, 100)), guide.point_at(250.0))
	_check("project finds the side", guide.project(Vector2(50, 106)).is_equal_approx(Vector2(250, 6)), guide.project(Vector2(50, 106)))

	var loop: Array = [Vector2(0, 0), Vector2(100, 4), Vector2(96, 100), Vector2(4, 96), Vector2(0, 0)]
	var good: Object = _stroke(guide, loop, 12.0)
	_check("a hand-drawn square close to the die passes", good.passes(), [good.get_coverage(), good.get_max_deviation()])
	_check("accuracy is high but not perfect", good.get_accuracy() > 0.7 and good.get_accuracy() < 1.0, good.get_accuracy())

	var straying: Object = _stroke(guide, [Vector2(0, 0), Vector2(100, 0), Vector2(130, 100), Vector2(0, 100), Vector2(0, 0)], 12.0)
	_check("straying past the tolerance fails", !straying.passes(), straying.get_max_deviation())

	var open: Object = _stroke(guide, [Vector2(0, 0), Vector2(100, 0), Vector2(100, 100), Vector2(0, 100)], 12.0)
	_check("a loop that does not close fails", !open.passes(), open.points.size())

	var part: Object = _stroke(guide, [Vector2(0, 0), Vector2(100, 0), Vector2(0, 0)], 12.0)
	_check("going back the same way covers only that side", !part.passes() and part.get_coverage() < 0.3, part.get_coverage())
