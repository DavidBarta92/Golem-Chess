extends HBoxContainer

## One counter of the top bar's block - rank, coin or draw points: an icon and
## a number in tabular figures, with no frame around it. It sits free in the
## bar (not in a container), so it can scale for its pop and pulse; its size
## follows its contents.

const TopBarStyle = preload("res://Scripts/TopBar/TopBarStyle.gd")
const TOP_BAR_ICON_SCRIPT = preload("res://Scripts/TopBar/TopBarIcon.gd")
const RATING_BADGE_ICON_SCRIPT = preload("res://Scripts/Rating/RatingBadgeIcon.gd")
const COIN_TEXTURE: Texture2D = preload("res://Assets/coin.svg")

const TOOLTIP_KEY: Dictionary = {
	"rank": "RATING_NAME",
	"coin": "TOPBAR_COINS",
	"draw": "TOPBAR_DRAW_POINTS",
}
const FLOAT_SECONDS: float = 1.1

var kind: String = "coin"
var icon_control: Control
var value_label: Label

func _init(counter_kind: String = "coin") -> void:
	kind = counter_kind
	name = "%sCounter" % kind.capitalize()
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_constant_override("separation", 6)
	tooltip_text = TOOLTIP_KEY.get(kind, "")

	match kind:
		"coin":
			var coin := TextureRect.new()
			coin.texture = COIN_TEXTURE
			coin.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_control = coin
		"rank":
			var badge = RATING_BADGE_ICON_SCRIPT.new()
			badge.color = TopBarStyle.INK
			icon_control = badge
		_:
			icon_control = TOP_BAR_ICON_SCRIPT.new("draw", TopBarStyle.ICON_STAT, TopBarStyle.INK)
	icon_control.custom_minimum_size = Vector2.ONE * TopBarStyle.ICON_STAT
	icon_control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_control)

	value_label = TopBarStyle.make_label("0", TopBarStyle.tabular_font(), TopBarStyle.FONT_SIZE_STAT, TopBarStyle.INK)
	value_label.custom_minimum_size = Vector2(20.0, 0.0)
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(value_label)

func set_value(value: int) -> void:
	set_value_text(TopBarStyle.format_number(value))

func set_value_text(text: String) -> void:
	if value_label.text == text:
		return
	value_label.text = text
	reset_size()

## Appearing for the first time: grows in from small with a slight overshoot.
func play_pop() -> void:
	pivot_offset = size * 0.5
	scale = Vector2.ONE * 0.6
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.27)
	tween.tween_property(self, "scale", Vector2.ONE * 1.08, 0.27).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", Vector2.ONE, 0.11).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## A quick grow-and-settle, for when a coin lands in it.
func pulse() -> void:
	pivot_offset = size * 0.5
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.18, 0.07).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

## The value changed by delta: the number hops and "+50" floats up beside it,
## in the counter's own text colour.
func play_bump(delta: int) -> void:
	if delta == 0:
		return
	var hop := create_tween()
	hop.tween_property(value_label, "position:y", value_label.position.y - 3.0, 0.11).set_ease(Tween.EASE_OUT)
	hop.tween_property(value_label, "position:y", value_label.position.y, 0.15).set_ease(Tween.EASE_IN)

	var float_color: Color = TopBarStyle.INK
	if kind == "coin":
		float_color = TopBarStyle.COIN_DEEP
	elif kind == "draw":
		float_color = TopBarStyle.DRAW
	var text: String = ("+" if delta > 0 else "−") + TopBarStyle.format_number(absi(delta))
	var floater := TopBarStyle.make_label(text, TopBarStyle.FONT_SEMIBOLD, TopBarStyle.FONT_SIZE_FLOAT, float_color)
	# Top level, so the row does not lay it out and a pop or pulse leaves it alone.
	floater.top_level = true
	add_child(floater)
	var start: Vector2 = global_position + Vector2(22.5, 0.0)
	floater.global_position = start
	floater.modulate.a = 0.0
	var rise := floater.create_tween()
	rise.tween_property(floater, "global_position:y", start.y - 18.0, FLOAT_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	var fade := floater.create_tween()
	fade.tween_property(floater, "modulate:a", 1.0, FLOAT_SECONDS * 0.2)
	fade.tween_property(floater, "modulate:a", 0.0, FLOAT_SECONDS * 0.8)
	fade.tween_callback(floater.queue_free)
