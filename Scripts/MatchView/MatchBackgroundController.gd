@tool
extends Control
class_name MatchBackgroundController

## The room a match is played in, and the way it arrives.
##
## Two rooms, picked with `variant`:
##   KIOSK  - the stall: window, table and the opponent sitting behind it
##   MEMORY - the remembered room the tutorial plays in
##
## Both arrive the same way. Some layers are simply there when the scene opens
## (the ink that frames the shot); the rest draws or fades in:
##
##   1. the line layers draw themselves, the way the main menu background does,
##      while the far colour fades in behind them
##   2. once every line has landed, the near colour fades in
##
## The board itself is not here - it lives in the match scene, under the
## camera - but it joins the same sequence through `line_art_finished` and
## `colour_finished`, so the grid draws with the table and the tiles fade in
## with the colour.

signal line_art_finished
signal colour_finished

enum Variant { KIOSK, MEMORY }

const LINE_REVEAL_SHADER = preload("res://Shaders/mainmenu_line_reveal.gdshader")
const HIDDEN_TIME: float = -1.0

## The tone the whole room is printed on. Anything that is meant to look like
## part of the scene rather than like an overlay takes this too, which is why
## it lives here rather than on the node: there is one of it.
const PAPER_TINT: Color = Color(0.956863, 0.941176, 0.901961, 1.0)

@export var variant: Variant = Variant.KIOSK:
	set(value):
		_variant = value
		_apply_variant()
	get:
		return _variant

@export_group("Timing")
## How long an average stroke takes to draw, and the spread between the
## earliest and latest stroke. Matched to the comic pages.
@export_range(0.1, 6.0, 0.05) var line_base_duration: float = 1.6
@export_range(0.0, 6.0, 0.05) var line_max_delay: float = 1.4
@export_range(0.0, 1.0, 0.01) var line_min_duration_frac: float = 0.45
@export_range(0.0, 0.2, 0.005) var line_feather: float = 0.03
@export_range(0.0, 5.0, 0.05) var colour_fade_seconds: float = 1.5
@export var line_color: Color = Color(0.06, 0.06, 0.08, 1.0)

@export_group("Sound")
## The pen, played while the lines draw and stopped when they land.
@export var reveal_sfx_name: String = "mainmenu_drawing"

var _variant: Variant = Variant.KIOSK
var _line_materials: Array[ShaderMaterial] = []
var _reveal_tween: Tween
var _reveal_sfx_player: AudioStreamPlayer

## Layer names per variant, in the order they stack from the back.
const KIOSK_LAYERS: Dictionary = {
	"instant": ["BgBody", "BgTableBase", "BgWindowLine"],
	"lines": ["BgTableLine"],
	"far_colour": ["Bg3", "BgWindowColor"],
	"near_colour": ["BgTableColor"],
}
const MEMORY_LAYERS: Dictionary = {
	"instant": [],
	"lines": ["Bg4Line"],
	"far_colour": [],
	"near_colour": ["Bg4Color"],
}

func _ready() -> void:
	modulate = PAPER_TINT
	_apply_variant()
	if Engine.is_editor_hint():
		return
	reset_background()

func get_layers() -> Dictionary:
	return MEMORY_LAYERS if _variant == Variant.MEMORY else KIOSK_LAYERS

## Total time from begin() to the last stroke landing - what the board's own
## grid should match so the two finish together.
func get_line_duration() -> float:
	return line_base_duration + line_max_delay

## Everything hidden except the layers that are simply there.
func reset_background() -> void:
	_kill_tween()
	_stop_reveal_sfx()
	var layers: Dictionary = get_layers()

	for child in get_children():
		var rect := child as TextureRect
		if rect == null:
			continue
		var in_variant: bool = _is_in_variant(rect.name, layers)
		rect.visible = in_variant and layers["instant"].has(rect.name)
		rect.modulate.a = 1.0

	_line_materials.clear()
	for layer_name in layers["lines"]:
		var rect := get_node_or_null(NodePath(layer_name)) as TextureRect
		if rect == null:
			continue
		rect.visible = false
		var material: ShaderMaterial = _ensure_line_material(rect)
		material.set_shader_parameter("time", HIDDEN_TIME)
		_line_materials.append(material)

	for layer_name in layers["far_colour"] + layers["near_colour"]:
		var rect := get_node_or_null(NodePath(layer_name)) as TextureRect
		if rect != null:
			rect.visible = true
			rect.modulate.a = 0.0

## Draws the room in.
func begin() -> void:
	reset_background()
	var layers: Dictionary = get_layers()
	var ink_duration: float = get_line_duration()

	for layer_name in layers["lines"]:
		var rect := get_node_or_null(NodePath(layer_name)) as TextureRect
		if rect != null:
			rect.visible = true
	_play_reveal_sfx()

	for layer_name in layers["far_colour"]:
		_fade_in(layer_name, 0.0)

	_reveal_tween = create_tween()
	_reveal_tween.tween_method(Callable(self, "_set_line_time"), 0.0, ink_duration, ink_duration)
	_reveal_tween.tween_callback(Callable(self, "_on_lines_finished"))

func _on_lines_finished() -> void:
	_stop_reveal_sfx()
	line_art_finished.emit()
	for layer_name in get_layers()["near_colour"]:
		_fade_in(layer_name, 0.0)
	var tween := create_tween()
	tween.tween_interval(colour_fade_seconds)
	tween.tween_callback(Callable(self, "_on_colour_finished"))

func _on_colour_finished() -> void:
	colour_finished.emit()

func _fade_in(layer_name: String, delay: float) -> void:
	var rect := get_node_or_null(NodePath(layer_name)) as TextureRect
	if rect == null:
		return
	rect.visible = true
	rect.modulate.a = 0.0
	var tween := rect.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(rect, "modulate:a", 1.0, colour_fade_seconds)

func _set_line_time(time_value: float) -> void:
	for material in _line_materials:
		material.set_shader_parameter("time", time_value)

## Every line layer animates on the same clock here, but each still needs its
## own material so the two variants cannot tread on each other.
func _ensure_line_material(rect: TextureRect) -> ShaderMaterial:
	var material := rect.material as ShaderMaterial
	if material == null or material.shader != LINE_REVEAL_SHADER:
		material = ShaderMaterial.new()
		material.shader = LINE_REVEAL_SHADER
		rect.material = material
	material.set_shader_parameter("base_duration", line_base_duration)
	material.set_shader_parameter("max_delay", line_max_delay)
	material.set_shader_parameter("min_duration_frac", line_min_duration_frac)
	material.set_shader_parameter("feather", line_feather)
	material.set_shader_parameter("line_color", line_color)
	return material

## Shows only the layers this variant uses; in the editor they are all drawn
## so a room can be looked at without running the game.
func _apply_variant() -> void:
	var layers: Dictionary = get_layers()
	for child in get_children():
		var rect := child as TextureRect
		if rect == null:
			continue
		var in_variant: bool = _is_in_variant(rect.name, layers)
		if Engine.is_editor_hint():
			rect.visible = in_variant
			if in_variant and layers["lines"].has(rect.name):
				_ensure_line_material(rect).set_shader_parameter("time", 1000.0)
		elif !in_variant:
			rect.visible = false

func _is_in_variant(layer_name: String, layers: Dictionary) -> bool:
	for key in layers:
		if layers[key].has(layer_name):
			return true
	return false

func _play_reveal_sfx() -> void:
	if Engine.is_editor_hint() or reveal_sfx_name.strip_edges().is_empty():
		return
	_reveal_sfx_player = SFXManager.play(reveal_sfx_name.strip_edges())

func _stop_reveal_sfx() -> void:
	var player: AudioStreamPlayer = _reveal_sfx_player
	_reveal_sfx_player = null
	if player != null and is_instance_valid(player) and player.playing:
		player.stop()

func _kill_tween() -> void:
	if _reveal_tween != null and _reveal_tween.is_valid():
		_reveal_tween.kill()
