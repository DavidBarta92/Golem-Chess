extends RefCounted
class_name BoardCanvas

## The one rule that holds a match scene together.
##
## Everything drawn in a match - the room behind it, the grid the board stands
## on - is authored on the same 1920x1080 canvas, and the background layers put
## it on screen the same way: scaled to cover the viewport, aspect kept, centred
## (TextureRect's KEEP_ASPECT_COVERED). The board, its pieces and its markers
## are not drawings, though. They live in world space under a camera that knows
## nothing about that canvas.
##
## This ties the two together: one world unit is 4.5 canvas pixels, and the
## camera's zoom follows the canvas' own scale. Reshape the window and the
## drawings and the board grow and shrink as one, because both are keyed off
## `cover()`.
##
## Two things follow from this, and breaking either pulls the board off the
## drawn table:
##
## - `MatchBoard` must not carry a scale of its own. Its size comes from the
##   perspective constants, which are fitted to the ink in
##   `Assets/board_grid_line.png` in these very units.
## - anything placed in world space to line up with a drawing is positioned in
##   canvas pixels divided by `PIXELS_PER_UNIT`, never in screen pixels.

const SIZE: Vector2 = Vector2(1920.0, 1080.0)

## Canvas pixels to a world unit. Chosen so a 16:9 window - the shape the game
## is authored at - comes out at zoom 3.24, the scale everything in a match was
## tuned at before the camera started following the canvas (zoom 3 with a 1.08
## scale on the board). Keeping it there means every other world measurement -
## piece heights, tile sink offsets, marker dots, shadows - is the size it has
## always been. Changing it means re-fitting the board.
const PIXELS_PER_UNIT: float = 4.86

## The middle of the board's near rim: the band between the last playable row
## and the board's edge. Somewhere to stand a small readout so that it sits on
## the board rather than beside it.
const RIM_CENTRE: Vector2 = Vector2(959.5, 893.75)

## A line down the room to the right of the board, clear of everything else,
## along which a small object can be hung.
const RIGHT_SIDE_X: float = 1700.0

## How much a canvas pixel is stretched to fill this viewport. The same number
## the background's TextureRects arrive at on their own.
static func cover(viewport_size: Vector2) -> float:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return 1.0
	return maxf(viewport_size.x / SIZE.x, viewport_size.y / SIZE.y)

## The camera zoom that puts world space and the canvas at the same scale.
static func zoom_for(viewport_size: Vector2) -> float:
	return PIXELS_PER_UNIT * cover(viewport_size)

## World size of something measured on the canvas.
static func to_world(canvas_pixels: float) -> float:
	return canvas_pixels / PIXELS_PER_UNIT

## Where a point on the canvas lands on screen.
static func to_viewport(canvas_point: Vector2, viewport_size: Vector2) -> Vector2:
	return (canvas_point - SIZE * 0.5) * cover(viewport_size) + viewport_size * 0.5
