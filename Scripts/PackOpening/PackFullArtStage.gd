extends Control
class_name PackFullArtStage

## A full art stamp's own moment. It lifts off the row to the middle of the
## screen and shudders with light behind it; it turns; ink floods out from it
## across the screen, and it stands there with its name until the player clicks
## or the moment has passed. Then it goes back to its place in the row.
##
## Sits over the rest of the row, under the stamp being shown, which the caller
## lifts above it. The stamp's face is the caller's to turn: `turn_face_up` is
## called at the middle of the turn.

signal finished

const FLOOD_SHADER = preload("res://Shaders/pack_reveal_flood.gdshader")
const FLOOD_NOISE_TEXTURE = preload("res://ui/themes/stamp/ink_flood_noise.png")
const LIFT_SECONDS: float = 0.8
const SHUDDER_SECONDS: float = 0.34
const SHUDDER_PIXELS: float = 4.0
const HOLD_BEFORE_TURN_SECONDS: float = 0.07
const TURN_SECONDS: float = 0.11
const FLOOD_SECONDS: float = 0.7
const NAME_DELAY_SECONDS: float = 0.4
const NAME_FADE_SECONDS: float = 0.3
## Left on its own, it goes back after this long.
const HOLD_SECONDS: float = 3.2
const RETURN_SECONDS: float = 0.42
const STAMP_SCREEN_SHARE: float = 0.6
const STAMP_CENTRE_Y: float = 0.45
const NAME_GAP: float = 16.0
const RAY_STRENGTH: float = 0.5
const POP: float = 1.08

var stamp: StampVisual
var turn_face_up: Callable
var flood: ColorRect
var flood_material: ShaderMaterial
var rays: ColorRect
var title_label: Label
var rarity_label: Label
var home_position: Vector2
var home_scale: Vector2
var home_rotation: float
var shown_scale: Vector2
var shown_position: Vector2
var showing: bool = false
var leaving: bool = false

## `stamp_size` is the stamp at scale 1.
func play(new_stamp: StampVisual, stamp_size: Vector2, print_name: String, rarity_name: String, new_turn_face_up: Callable) -> void:
	stamp = new_stamp
	turn_face_up = new_turn_face_up
	home_position = stamp.position
	home_scale = stamp.scale
	home_rotation = stamp.rotation
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var stage_size: Vector2 = get_viewport_rect().size
	size = stage_size
	shown_scale = Vector2.ONE * minf(STAMP_SCREEN_SHARE * stage_size.y / stamp_size.y, 2.4)
	var centre := Vector2(stage_size.x * 0.5, stage_size.y * STAMP_CENTRE_Y)
	shown_position = centre - stamp_size * 0.5

	_build_flood(centre / stage_size, stage_size)
	rays = PackRevealFx.add_rays(self, Rect2(Vector2.ZERO, stage_size), centre / stage_size, PackRevealFx.FULL_ART_LIGHT, 13.0)
	rays.material.set_shader_parameter("reach", 1.1)
	_build_labels(centre, stamp_size * shown_scale, stage_size, print_name, rarity_name)

	SFXManager.play("pack_full_art_tease")
	var tween := create_tween().set_parallel(true)
	tween.tween_property(stamp, "position", shown_position, LIFT_SECONDS).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(stamp, "scale", shown_scale, LIFT_SECONDS).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(stamp, "rotation", 0.0, LIFT_SECONDS).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(rays.material, "shader_parameter/strength", RAY_STRENGTH, LIFT_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(_shudder)

## The player's click: on to whatever comes next.
func advance() -> void:
	if showing and !leaving:
		_leave()

func _build_flood(origin: Vector2, stage_size: Vector2) -> void:
	flood_material = ShaderMaterial.new()
	flood_material.shader = FLOOD_SHADER
	flood_material.set_shader_parameter("front_noise", FLOOD_NOISE_TEXTURE)
	flood_material.set_shader_parameter("origin", origin)
	flood_material.set_shader_parameter("aspect", stage_size.x / maxf(stage_size.y, 1.0))
	flood_material.set_shader_parameter("rim_color", PackRevealFx.FULL_ART_LIGHT)
	flood_material.set_shader_parameter("progress", 0.0)
	flood = ColorRect.new()
	flood.name = "FullArtFlood"
	flood.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flood.size = stage_size
	flood.material = flood_material
	add_child(flood)

func _build_labels(centre: Vector2, shown_size: Vector2, stage_size: Vector2, print_name: String, rarity_name: String) -> void:
	var top: float = centre.y + shown_size.y * 0.5 + NAME_GAP
	title_label = _add_label(print_name, &"DisplayLabel", top, stage_size.x)
	rarity_label = _add_label(rarity_name.to_upper(), &"KickerLabel", top + 42.0, stage_size.x)
	rarity_label.add_theme_color_override("font_color", PackRevealFx.FULL_ART_LIGHT)

func _add_label(text: String, variation: StringName, top: float, width: float) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(0.0, top)
	label.size = Vector2(width, 40.0)
	label.modulate.a = 0.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", UiPalette.PAPER_RAISED)
	add_child(label)
	return label

func _shudder() -> void:
	var shaking: bool = SettingsDataManager.is_screen_shake_enabled()
	var tween := create_tween()
	var steps: int = int(SHUDDER_SECONDS / 0.03)
	for i in range(steps):
		var grow: float = float(i + 1) / float(steps)
		var offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * SHUDDER_PIXELS * grow
		tween.tween_property(stamp, "position", shown_position + (offset if shaking else Vector2.ZERO), 0.03)
	tween.tween_property(stamp, "position", shown_position, 0.03)
	tween.tween_interval(HOLD_BEFORE_TURN_SECONDS)
	tween.tween_property(stamp, "scale", Vector2(0.0, shown_scale.y * 1.03), TURN_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(_on_turned)
	tween.tween_property(stamp, "scale", shown_scale * POP, TURN_SECONDS * 1.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(stamp, "scale", shown_scale, 0.24).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _on_turned() -> void:
	turn_face_up.call()
	SFXManager.play("pack_full_art_reveal")
	var centre: Vector2 = shown_position + stamp.size * 0.5
	PackRevealFx.burst(self, centre, PackRevealFx.FULL_ART_LIGHT, 90, 620.0)
	PackRevealFx.sweep(stamp, PackRevealFx.FULL_ART_LIGHT)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(flood_material, "shader_parameter/progress", 1.0, FLOOD_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(title_label, "modulate:a", 1.0, NAME_FADE_SECONDS).set_delay(NAME_DELAY_SECONDS)
	tween.tween_property(rarity_label, "modulate:a", 1.0, NAME_FADE_SECONDS).set_delay(NAME_DELAY_SECONDS + 0.12)
	tween.chain().tween_callback(func() -> void: showing = true)
	tween.chain().tween_interval(HOLD_SECONDS)
	tween.chain().tween_callback(advance)

func _leave() -> void:
	leaving = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, RETURN_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(stamp, "position", home_position, RETURN_SECONDS).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(stamp, "scale", home_scale, RETURN_SECONDS).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(stamp, "rotation", home_rotation, RETURN_SECONDS).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.chain().tween_callback(func() -> void:
		finished.emit()
		queue_free()
	)
