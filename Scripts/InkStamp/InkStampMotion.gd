extends RefCounted

## How UI items arrive on the paper and leave it (Docs/Style/OVERRIDES.md,
## "The top bar's scene items"): stamped in, dissolved out. Shared by the top
## bar's left zone and the main menu's Play window, so the two move alike.
## The caller owns the tween, in parallel mode, and gives each item its delay.

const INK_DISSOLVE_SHADER: Shader = preload("res://Shaders/ink_dissolve.gdshader")
const FRONT_NOISE_PATH: String = "res://ui/themes/stamp/ink_flood_noise.png"

## Arriving, an item starts from nothing, STAMP_START_SCALE times its size and
## turned STAMP_MIN_TILT..STAMP_MAX_TILT degrees either way, and drops onto
## its place on an exponential ease-in - slowly, then all at once - in
## STAMP_SECONDS, fully opaque halfway down so the drop still shows.
const STAMP_SECONDS: float = 0.42
const STAMP_START_SCALE: float = 1.3
const STAMP_MIN_TILT: float = 1.5
const STAMP_MAX_TILT: float = 6.0
## Leaving, paper floods in over it from its edges along the hover's ragged
## front (Shaders/ink_dissolve.gdshader) while it fades.
const DISSOLVE_SECONDS: float = 0.4
## Between one item and the next, both ways.
const ITEM_STAGGER_SECONDS: float = 0.07

static var _dissolve_material: ShaderMaterial

## Puts the item at the start of its drop and adds the drop to the tween.
static func stamp_in(tween: Tween, item: Control, delay: float) -> void:
	item.modulate.a = 0.0
	item.scale = Vector2.ONE * STAMP_START_SCALE
	item.rotation = deg_to_rad(randf_range(STAMP_MIN_TILT, STAMP_MAX_TILT)) * (1.0 if randf() < 0.5 else -1.0)
	# By then the item has been laid out, so its middle is known.
	tween.tween_callback(func() -> void: item.pivot_offset = item.size * 0.5).set_delay(delay)
	tween.tween_property(item, "scale", Vector2.ONE, STAMP_SECONDS).set_delay(delay).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_property(item, "rotation", 0.0, STAMP_SECONDS).set_delay(delay).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_property(item, "modulate:a", 1.0, STAMP_SECONDS * 0.5).set_delay(delay)

## Adds the item's dissolve to the tween. Settle it once the tween is done.
static func dissolve_out(tween: Tween, item: Control, delay: float) -> void:
	# A clicked or hovered button still holds its hover ink, on a layer of its own.
	var hover_fill: Node = _hover_fill()
	if item is Button and hover_fill != null:
		hover_fill.clear(item)
	var dissolve: ShaderMaterial = _dissolve()
	if dissolve != null:
		item.material = dissolve
		item.set_instance_shader_parameter(&"dissolve_seed", float(item.get_instance_id() % 997))
		item.set_instance_shader_parameter(&"dissolve_size", item.size)
		item.set_instance_shader_parameter(&"dissolve_progress", 0.0)
		tween.tween_method(func(progress: float) -> void: item.set_instance_shader_parameter(&"dissolve_progress", progress), 0.0, 1.0, DISSOLVE_SECONDS).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(item, "modulate:a", 0.0, DISSOLVE_SECONDS).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

## Back to rest, whatever was under way.
static func settle(item: Control) -> void:
	item.material = null
	# A button's frame draws its ink blot live; give that back.
	var hover_fill: Node = _hover_fill()
	if item is Button and hover_fill != null:
		hover_fill.frame(item)
	item.modulate.a = 1.0
	item.scale = Vector2.ONE
	item.rotation = 0.0

static func _dissolve() -> ShaderMaterial:
	if _dissolve_material == null and ResourceLoader.exists(FRONT_NOISE_PATH):
		_dissolve_material = ShaderMaterial.new()
		_dissolve_material.shader = INK_DISSOLVE_SHADER
		_dissolve_material.set_shader_parameter(&"front_noise", load(FRONT_NOISE_PATH))
	return _dissolve_material

static func _hover_fill() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("InkHoverFill") if tree != null else null
