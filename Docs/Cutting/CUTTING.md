# Cutting

A mouse drag measured against a line. Tearing a pack open uses it, and so does
the puzzles' reward scene, where the player cuts a stamp off an envelope by
drawing around a die (`Scripts/Puzzles/PuzzleRewardScreen.gd`,
[PUZZLES.md](../Puzzles/PUZZLES.md)).

Three parts in `Scripts/Cutting/`, none of which knows about packs:

| | |
| --- | --- |
| `CutGuide` | the line to follow: `CutGuide.line(from, to)`, `CutGuide.outline(corners)`, `CutGuide.rectangle(rect)`. Geometry only |
| `CutStroke` | one drawn path against a guide, measured while it is drawn |
| `CutArea` | a Control that turns mouse drags on it into a `CutStroke`, in its own space, and reports `cut_started`, `cut_moved`, `cut_ended` and `tapped` |

What a stroke can tell:

| | |
| --- | --- |
| `direction` | 1 along the guide, -1 against it, 0 until the path has moved |
| `get_reach(towards)` | how far along an open guide it has got, 0 to 1, counted from the end it is heading away from |
| `get_coverage()` | the share of the guide followed within `tolerance`, in any order |
| `get_mean_deviation()`, `get_max_deviation()` | how far it strayed, in the guide's units |
| `get_accuracy()` | 1 right on the guide, 0 at the tolerance on average: a score |
| `is_loop_closed()` | whether the path came back to where it began |
| `passes(min_coverage)` | it followed the guide, never strayed past the tolerance, and an outline's path closed |
| `points` | the path as drawn |

## The pack

`Scripts/PackOpening/PackTearInteraction.gd` uses a `CutGuide.line` along the top
of the pack with an infinite tolerance: only how far along counts, a tear does not
leave its line. Everything else there is the pack's own: the speed paper tears at,
that a tear never goes back, that a release past half the width finishes by itself.

## The envelope

`PuzzleRewardScreen` does this with an irregular die from `CutGuide.outline`.
Two things it learnt: the drawn path overlaps itself where it meets its start,
so trim that tail before using it as a polygon (`_cut_outline`), and keep
the stamp itself out of the `PolygonClip` - only the paper is clipped, the
stamp lies on top - so nothing that reads the screen ends up inside a clip.

```gdscript
var area := CutArea.new()
area.guide = CutGuide.rectangle(die_rect) # in the area's own space
area.tolerance = 10.0 # how far from the die the cut may stray
add_child(area)
area.cut_ended.connect(func(stroke: CutStroke) -> void:
	if stroke.passes():
		stamp_clip.polygon = stroke.points
		stamp_clip.set_clip_enabled(true)
)
```

The drawn path is the shape that was really cut, so a `PolygonClip`
(`Scenes/PolygonClip.gd`) can show the stamp with exactly that outline, wobbles
included, and `get_accuracy()` can decide how good a copy it gives. Showing the
line while it is drawn belongs to the scene: `cut_moved` hands over the stroke
with its `points` on every mouse move.

## Testing

    Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/cutting_selftest.gd

It covers the pack's line and a hand-drawn square against a die: a good cut, a
straying one, one that does not close, and one that only covers a side.
