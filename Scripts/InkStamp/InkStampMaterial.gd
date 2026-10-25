extends RefCounted

## The ink stamp (Shaders/ink_stamp.gdshader) for a canvas item that draws its
## own ink - the top bar's ribbons, icons and progress pips - and, through
## InkStampTitles, for Display and Title text. One shared material, a seed per
## item, so two items do not show the same pattern. A material does not reach
## a control's children unless they set use_parent_material. Without the baked
## mask nothing is stamped.

const STAMP_SHADER: Shader = preload("res://Shaders/ink_stamp.gdshader")
const STAMP_MASK_PATH: String = "res://ui/themes/stamp/ink_stamp_mask.png"

static var _material: ShaderMaterial

## The shared material, or null without the mask.
static func shared() -> ShaderMaterial:
	if _material == null and ResourceLoader.exists(STAMP_MASK_PATH):
		_material = ShaderMaterial.new()
		_material.shader = STAMP_SHADER
		_material.set_shader_parameter(&"stamp_mask", load(STAMP_MASK_PATH))
	return _material

## Stamps the item, unless it has a material of its own. An item that is
## mostly ink fill (a ribbon, a pip) gets the fill's sparser specks, as the
## framed controls' ink fills do. Black art (the pager arrows, the codex
## buttons' icons) is re-inked in UiPalette.INK first: black becomes ink,
## white stays white.
static func apply(item: CanvasItem, mostly_fill: bool = false, black_art: bool = false) -> void:
	var stamp: ShaderMaterial = shared()
	if stamp == null or item.material != null:
		return
	item.material = stamp
	item.set_instance_shader_parameter(&"stamp_seed", float(item.get_instance_id() % 997))
	if mostly_fill:
		item.set_instance_shader_parameter(&"stamp_fill", 1.0)
	if black_art:
		item.set_instance_shader_parameter(&"stamp_reink", 1.0)

## Pins the pattern to a point of the item instead of its origin, for an item
## whose ink moves inside it - a ribbon pulled down carries its specks along.
static func set_anchor(item: CanvasItem, anchor: Vector2) -> void:
	if item.material != null and item.material == _material:
		item.set_instance_shader_parameter(&"stamp_anchor", anchor)

static func is_stamped(item: CanvasItem) -> bool:
	return item.material != null and item.material == _material
