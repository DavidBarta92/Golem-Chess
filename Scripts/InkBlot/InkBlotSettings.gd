@tool
class_name InkBlotSettings
extends Resource

## The ink blot's values (Docs/Style/INK_BLOT.md): ink soaked unevenly into
## the paper - its density drifts in blotches, its edges wander in and out.
## One set of values per group, plus how crisp the blotches are.
##
## Tune them in Shaders/ink_blot_settings.tres. The InkBlot autoload hands
## every change to the shaders at once, in the editor's view and, with
## Debug > Synchronize Scene Changes on, in the running game. Most framed
## controls' prints are baked from the UI values (the buttons' frames are
## not): run python tools/generate_ink_stamps.py after changing those.
##
## density: 0 = even ink, 1 = the palest blotches lose all their ink.
## edge: how far an edge is pushed in or out at most, in units.
## blotch size / wander size: how big the blotches and the edge's bends are.

@export_group("UI")
## Frames, fills, hover ink, titles and the top bar's drawn items.
@export_range(0.0, 1.0, 0.01) var ui_density: float = 0.25:
	set(value):
		ui_density = value
		emit_changed()
## Only the baked frames have a wandering edge: there is room for 1.4 units.
@export_range(0.0, 1.4, 0.05) var ui_edge: float = 0.6:
	set(value):
		ui_edge = value
		emit_changed()
@export_range(4.0, 400.0, 1.0) var ui_blotch_size: float = 72.0:
	set(value):
		ui_blotch_size = value
		emit_changed()
@export_range(1.0, 100.0, 0.5) var ui_wander_size: float = 6.0:
	set(value):
		ui_wander_size = value
		emit_changed()

@export_group("Scene lines")
## The scenes' black line art: the main menu, the match, the comics, the
## tutorial, the board's grid, the portrait frame.
@export_range(0.0, 1.0, 0.01) var lines_density: float = 0.35:
	set(value):
		lines_density = value
		emit_changed()
@export_range(0.0, 8.0, 0.05) var lines_edge: float = 0.8:
	set(value):
		lines_edge = value
		emit_changed()
@export_range(4.0, 400.0, 1.0) var lines_blotch_size: float = 105.0:
	set(value):
		lines_blotch_size = value
		emit_changed()
@export_range(1.0, 100.0, 0.5) var lines_wander_size: float = 8.0:
	set(value):
		lines_wander_size = value
		emit_changed()

@export_group("Scene washes")
## The grey washes under the line art, and the collection's drawn pictures.
@export_range(0.0, 1.0, 0.01) var washes_density: float = 0.35:
	set(value):
		washes_density = value
		emit_changed()
@export_range(0.0, 8.0, 0.05) var washes_edge: float = 2.0:
	set(value):
		washes_edge = value
		emit_changed()
@export_range(4.0, 400.0, 1.0) var washes_blotch_size: float = 135.0:
	set(value):
		washes_blotch_size = value
		emit_changed()
@export_range(1.0, 100.0, 0.5) var washes_wander_size: float = 14.0:
	set(value):
		washes_wander_size = value
		emit_changed()

@export_group("Stamps")
## The stamps' printed ink: the coloured square, the art, the lettering and
## the icons. Their paper, and the pattern's markers, stay as they are.
@export_range(0.0, 1.0, 0.01) var stamps_density: float = 0.25:
	set(value):
		stamps_density = value
		emit_changed()
@export_range(0.0, 8.0, 0.05) var stamps_edge: float = 0.8:
	set(value):
		stamps_edge = value
		emit_changed()
@export_range(4.0, 400.0, 1.0) var stamps_blotch_size: float = 90.0:
	set(value):
		stamps_blotch_size = value
		emit_changed()
@export_range(1.0, 100.0, 0.5) var stamps_wander_size: float = 8.0:
	set(value):
		stamps_wander_size = value
		emit_changed()

@export_group("Blotches")
## How sharply a blotch's border is drawn: 0 soft, 1 crisp.
@export_range(0.0, 1.0, 0.01) var contrast: float = 0.35:
	set(value):
		contrast = value
		emit_changed()

## Sets the global shader uniforms of Shaders/ink_blot.gdshaderinc.
func apply() -> void:
	RenderingServer.global_shader_parameter_set(&"ink_blot_ui", Vector4(ui_density, ui_edge, ui_blotch_size, ui_wander_size))
	RenderingServer.global_shader_parameter_set(&"ink_blot_lines", Vector4(lines_density, lines_edge, lines_blotch_size, lines_wander_size))
	RenderingServer.global_shader_parameter_set(&"ink_blot_washes", Vector4(washes_density, washes_edge, washes_blotch_size, washes_wander_size))
	RenderingServer.global_shader_parameter_set(&"ink_blot_stamps", Vector4(stamps_density, stamps_edge, stamps_blotch_size, stamps_wander_size))
	RenderingServer.global_shader_parameter_set(&"ink_blot_contrast", contrast)
