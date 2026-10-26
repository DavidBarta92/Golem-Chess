extends Resource
class_name FoilStyle

## A print's foil look: bands of colour from a gradient, bent by a height-map pattern,
## flowing while the stamp moves or tilts, with optional glitter. A print picks one in
## StampPrint.foil_style; the styles live in res://FoilStyles/.

enum Area {
	WHOLE_STAMP,
	WHITE_PARTS,
}

## Where the foil shows: over the whole stamp, or only on its white parts (white art
## lines, markers, name, duration). On white parts only the tint counts.
@export var area: Area = Area.WHOLE_STAMP

@export_group("Color")
## The bands' colours, from one end of a run to the other.
@export var gradient: Gradient
## On: each run goes there and back, so the gradient's two ends need not match.
## Off: runs repeat, for a gradient that already loops (like a full rainbow).
@export var gradient_mirrored: bool = true

@export_group("Pattern")
## A grayscale height map: light is high, dark is low. Empty gives plain bands.
@export var height_map: Texture2D
## One pattern tile spans this many stamp heights.
@export var pattern_scale: float = 1.0
## How far the pattern shifts the bands, in gradient runs from its darkest to its lightest.
@export var pattern_bend: float = 0.5

@export_group("Bands")
## About how many gradient runs fit across the stamp.
@export var band_density: float = 1.0
## The direction the colours run in, in degrees: 0 left to right, 90 top to bottom.
@export_range(0.0, 360.0) var band_angle: float = 45.0
## Gradient runs per second the stamp spends moving or tilting.
@export var speed: float = 0.5

@export_group("Blend")
## Multiplies the stamp by the band colour: light parts take the colour, black stays black.
@export_range(0.0, 1.0) var tint_strength: float = 1.0
## Adds the band colour as light, so the foil glows on dark parts too. Whole stamp only.
@export_range(0.0, 1.0) var shine_strength: float = 0.0

@export_group("Sparkle")
## The share of glitter points that can flash. Whole stamp only.
@export_range(0.0, 1.0) var sparkle_amount: float = 0.0
## The spacing of the glitter points, in stamp pixels.
@export var sparkle_size: float = 6.0

@export_group("White Parts")
## On white parts: where white starts and where it is full, by a pixel's darkest channel.
## The stamp's paper is 0.82, so it stays below the default start.
@export_range(0.0, 1.0) var white_start: float = 0.88
@export_range(0.0, 1.0) var white_full: float = 0.97

var gradient_texture: GradientTexture1D

func get_gradient_texture() -> GradientTexture1D:
	if gradient_texture == null:
		gradient_texture = GradientTexture1D.new()
		gradient_texture.width = 256
		gradient_texture.gradient = gradient if gradient != null else Gradient.new()
	return gradient_texture

# Fills the foil uniforms of Shaders/foil.gdshaderinc; StampVisual adds the stamp's size,
# each layer's place in it and the flow time.
func apply_to(material: ShaderMaterial) -> void:
	material.set_shader_parameter("foil_gradient", get_gradient_texture())
	material.set_shader_parameter("foil_gradient_mirrored", gradient_mirrored)
	material.set_shader_parameter("foil_height_map", height_map)
	material.set_shader_parameter("foil_has_height_map", height_map != null)
	material.set_shader_parameter("foil_pattern_scale", pattern_scale)
	material.set_shader_parameter("foil_pattern_bend", pattern_bend)
	material.set_shader_parameter("foil_band_density", band_density)
	material.set_shader_parameter("foil_band_direction", Vector2.from_angle(deg_to_rad(band_angle)))
	material.set_shader_parameter("foil_speed", speed)
	material.set_shader_parameter("foil_tint_strength", tint_strength)
	material.set_shader_parameter("foil_shine_strength", shine_strength)
	material.set_shader_parameter("foil_sparkle_amount", sparkle_amount)
	material.set_shader_parameter("foil_sparkle_size", sparkle_size)
	material.set_shader_parameter("foil_white_start", white_start)
	material.set_shader_parameter("foil_white_full", white_full)
