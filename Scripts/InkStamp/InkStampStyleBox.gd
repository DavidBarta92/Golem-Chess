@tool
class_name InkStampStyleBox
extends StyleBox

## A StyleBoxFlat printed like a rubber stamp: the same shape and colours, with
## a little ink missing in small specks and slightly ragged edges (see
## Docs/Style/STYLE_PLAN.md, "Ink-stamp texture"). The prints are 9-patch PNGs
## baked by tools/generate_ink_stamps.py into ui/themes/stamp/, a few variants
## per style; each control draws the variant its canvas item picks, so two
## neighbours rarely share a pattern. Edges and centre tile instead of
## stretching, so the specks keep their size on a control of any size.
## Without baked prints it draws the plain shape.
##
## The content margins, expand margins and shadow all come from the shape.
## After changing the shape, run the tool again.

const STAMP_DIR: String = "res://ui/themes/stamp/"
## Transparent border around the shape in each print, room for ragged edges.
## Keep these two in step with PAD and CORNER_EXTRA in the tool.
const PAD: int = 2
const CORNER_EXTRA: int = 2

## What is printed: geometry, colours, margins, shadow. Also the fallback.
@export var shape: StyleBoxFlat:
	set(value):
		if shape != null and shape.changed.is_connected(_sync_from_shape):
			shape.changed.disconnect(_sync_from_shape)
		shape = value
		if shape != null:
			shape.changed.connect(_sync_from_shape)
		_sync_from_shape()
## The prints are <stamp_name>_<n>.png in STAMP_DIR, n from 0.
@export var stamp_name: String = "":
	set(value):
		stamp_name = value
		_prints_loaded = false
		emit_changed()
@export_range(1, 16) var variants: int = 4:
	set(value):
		variants = value
		_prints_loaded = false
		emit_changed()

var _prints: Array[Texture2D] = []
var _prints_loaded: bool = false
var _shadow: StyleBoxFlat

## The corner size, per side, of a print of this shape: the 9-patch margins.
static func patch_margins(flat: StyleBoxFlat) -> Vector4i:
	var left: float = maxf(maxf(flat.corner_radius_top_left, flat.corner_radius_bottom_left), flat.border_width_left)
	var top: float = maxf(maxf(flat.corner_radius_top_left, flat.corner_radius_top_right), flat.border_width_top)
	var right: float = maxf(maxf(flat.corner_radius_top_right, flat.corner_radius_bottom_right), flat.border_width_right)
	var bottom: float = maxf(maxf(flat.corner_radius_bottom_left, flat.corner_radius_bottom_right), flat.border_width_bottom)
	return Vector4i(
		PAD + ceili(left) + CORNER_EXTRA,
		PAD + ceili(top) + CORNER_EXTRA,
		PAD + ceili(right) + CORNER_EXTRA,
		PAD + ceili(bottom) + CORNER_EXTRA
	)

func _sync_from_shape() -> void:
	_shadow = null
	if shape != null:
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			set_content_margin(side, shape.get_margin(side))
		if shape.shadow_size > 0 and shape.shadow_color.a > 0.0:
			_shadow = StyleBoxFlat.new()
			_shadow.bg_color = Color(0, 0, 0, 0)
			# As a StyleBoxFlat does: a box with a centre has its shadow under
			# all of it, not just around it - else an offset shadow leaves an
			# unshaded band along the box's edge.
			_shadow.draw_center = shape.draw_center
			_shadow.shadow_color = shape.shadow_color
			_shadow.shadow_size = shape.shadow_size
			_shadow.shadow_offset = shape.shadow_offset
			_shadow.corner_radius_top_left = shape.corner_radius_top_left
			_shadow.corner_radius_top_right = shape.corner_radius_top_right
			_shadow.corner_radius_bottom_right = shape.corner_radius_bottom_right
			_shadow.corner_radius_bottom_left = shape.corner_radius_bottom_left
	emit_changed()

func _area(rect: Rect2) -> Rect2:
	return rect.grow_individual(shape.expand_margin_left, shape.expand_margin_top, shape.expand_margin_right, shape.expand_margin_bottom)

func _get_draw_rect(rect: Rect2) -> Rect2:
	if shape == null:
		return rect
	return _area(rect).grow(PAD)

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	# A flat box draws nothing in an empty rect (a scroll bar with nothing to
	# scroll asks for one); the padding around a print must not either.
	if shape == null or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var print_texture: Texture2D = _print_for(to_canvas_item)
	if print_texture == null:
		shape.draw(to_canvas_item, rect)
		return
	var area: Rect2 = _area(rect)
	if _shadow != null:
		_shadow.draw(to_canvas_item, area)
	var margins: Vector4i = patch_margins(shape)
	RenderingServer.canvas_item_add_nine_patch(
		to_canvas_item,
		area.grow(PAD),
		Rect2(Vector2.ZERO, print_texture.get_size()),
		print_texture.get_rid(),
		Vector2(margins.x, margins.y),
		Vector2(margins.z, margins.w),
		RenderingServer.NINE_PATCH_TILE,
		RenderingServer.NINE_PATCH_TILE
	)

func _print_for(canvas_item: RID) -> Texture2D:
	if !_prints_loaded:
		_load_prints()
	if _prints.is_empty():
		return null
	return _prints[canvas_item.get_id() % _prints.size()]

func _load_prints() -> void:
	_prints_loaded = true
	_prints.clear()
	if stamp_name.is_empty():
		return
	for index in range(variants):
		var path: String = "%s%s_%d.png" % [STAMP_DIR, stamp_name, index]
		if ResourceLoader.exists(path):
			var texture := load(path) as Texture2D
			if texture != null:
				_prints.append(texture)
