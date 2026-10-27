extends CanvasLayer

## What a capture does on the screen rather than on the board: the wash that
## rises from the player's side when the piece was theirs. Above the HUD,
## under the vignette and the paper texture, so it reads as printed on the
## same paper. `PieceEffectFlowController` makes one per board and decides
## what each capture gets.

const WASH_SHADER = preload("res://Shaders/capture_loss_wash.gdshader")
const LAYER: int = 2

var _wash: ColorRect
var _wash_material: ShaderMaterial
var _wash_tween: Tween

func _init() -> void:
	layer = LAYER
	name = "CaptureFeelLayer"

## The wash from the player's own side: up quickly, then slowly away.
func wash_from_own_side(color: Color, rise_duration: float, fade_duration: float) -> void:
	if _wash == null:
		_wash_material = ShaderMaterial.new()
		_wash_material.shader = WASH_SHADER
		# A parameter cannot be tweened before it has a value of its own.
		_wash_material.set_shader_parameter(&"amount", 0.0)
		_wash = ColorRect.new()
		_wash.name = "LossWash"
		_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_wash.set_anchors_preset(Control.PRESET_FULL_RECT)
		_wash.material = _wash_material
		add_child(_wash)
	_wash_material.set_shader_parameter(&"wash_color", color)
	if _wash_tween != null and _wash_tween.is_valid():
		_wash_tween.kill()
	_wash_tween = create_tween()
	_wash_tween.tween_property(_wash_material, "shader_parameter/amount", 1.0, rise_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_wash_tween.tween_property(_wash_material, "shader_parameter/amount", 0.0, fade_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
