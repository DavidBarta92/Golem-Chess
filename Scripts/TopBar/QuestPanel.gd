extends MarginContainer

## The open quest's details, below the bar beside its ribbon: kind, title,
## description, progress and reward over a horizontal paper fade - the same
## device as the card descriptions, with the ribbon as its left edge. Opening
## to the left (no room on the right) mirrors the fade and keeps the text on
## the opaque side, next to the ribbon.
##
## Its height is only known once the wrapped text has been laid out, so the
## top bar waits a couple of frames after show_quest() before reading it.

signal claim_requested(quest_id: String)

const TopBarStyle = preload("res://Scripts/TopBar/TopBarStyle.gd")
const TOP_BAR_ICON_SCRIPT = preload("res://Scripts/TopBar/TopBarIcon.gd")
const InkStampMaterial = preload("res://Scripts/InkStamp/InkStampMaterial.gd")
const COIN_TEXTURE: Texture2D = preload("res://Assets/coin.svg")

const KIND_KEY: Dictionary = {
	"story": "QUEST_KIND_STORY",
	"reward": "QUEST_KIND_REWARD",
	"daily": "QUEST_KIND_DAILY",
}
## Steps up to this many show as dots, more as a bar.
const MAX_PIPS: int = 10
## The share of the width that stays opaque before the fade.
const OPAQUE_SHARE: float = 0.8

var quest_id: String = ""
var opens_left: bool = false
var _content: VBoxContainer
var _time_label: Label
var _time_urgent: bool = false
var _rest_x: float = 0.0
var _fade_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(TopBarStyle.PANEL_WIDTH, 0.0)
	add_theme_constant_override("margin_top", 12)
	add_theme_constant_override("margin_bottom", 15)
	add_theme_constant_override("margin_left", 15)
	add_theme_constant_override("margin_right", 15)
	_content = VBoxContainer.new()
	_content.custom_minimum_size = Vector2(TopBarStyle.PANEL_TEXT_WIDTH, 0.0)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_theme_constant_override("separation", 0)
	add_child(_content)
	visible = false

func is_open() -> bool:
	return visible and !quest_id.is_empty()

## Rebuilds the contents for a quest; time_left_text is empty for quests that
## do not run out.
func show_quest(quest: Dictionary, time_left_text: String, is_urgent: bool, open_left: bool) -> void:
	# A previous panel still fading out would go on moving and then hide this one.
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	quest_id = str(quest.get("id", ""))
	opens_left = open_left
	_content.size_flags_horizontal = Control.SIZE_SHRINK_END if open_left else Control.SIZE_SHRINK_BEGIN
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()

	var kind: String = str(quest.get("kind", "story"))
	var reward: String = "story" if kind == "story" else str(quest.get("reward", "coin"))
	_content.add_child(_build_kicker(kind, reward, time_left_text, is_urgent))
	_add_gap(6.0)

	var title: String = tr(str(quest.get("title", "")))
	if !title.is_empty():
		var title_label := TopBarStyle.make_label(title, &"QuestTitleLabel")
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_content.add_child(title_label)
		_add_gap(4.5)

	var text: String = tr(str(quest.get("text", "")))
	if !text.is_empty():
		_add_text(text)

	var target: int = maxi(1, int(quest.get("target", 1)))
	if target > 1:
		_add_gap(9.0)
		_content.add_child(_build_progress(clampi(int(quest.get("progress", 0)), 0, target), target, reward))

	_add_gap(9.0)
	_content.add_child(_build_footer(quest, reward))
	reset_size()
	queue_redraw()

## Moves the clock of an open daily quest on. False when the quest has just
## become urgent (or stopped being), which needs the panel rebuilt.
func update_time_left(time_left_text: String, is_urgent: bool) -> bool:
	if _time_label == null or is_urgent != _time_urgent:
		return false
	_time_label.text = time_left_text
	return true

## Fades in and slides 6 from the ribbon's side, a beat after the ribbon starts.
func play_in() -> void:
	_rest_x = position.x
	visible = true
	modulate.a = 0.0
	position.x = _rest_x + _slide_offset()
	_restart_fade()
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(self, "modulate:a", 1.0, TopBarStyle.PANEL_IN_SECONDS).set_delay(TopBarStyle.PANEL_IN_DELAY_SECONDS).set_ease(Tween.EASE_OUT)
	_fade_tween.tween_property(self, "position:x", _rest_x, TopBarStyle.PANEL_IN_SECONDS).set_delay(TopBarStyle.PANEL_IN_DELAY_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func play_out() -> void:
	quest_id = ""
	if !visible:
		return
	_restart_fade()
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(self, "modulate:a", 0.0, TopBarStyle.PANEL_OUT_SECONDS).set_ease(Tween.EASE_IN)
	_fade_tween.tween_property(self, "position:x", _rest_x + _slide_offset(), TopBarStyle.PANEL_OUT_SECONDS).set_ease(Tween.EASE_IN)
	_fade_tween.chain().tween_callback(hide)

func hide_now() -> void:
	quest_id = ""
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	visible = false

func _restart_fade() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()

func _slide_offset() -> float:
	return TopBarStyle.PANEL_SLIDE if opens_left else -TopBarStyle.PANEL_SLIDE

func _draw() -> void:
	var opaque_width: float = size.x * OPAQUE_SHARE
	var fill: Color = TopBarStyle.PANEL_FILL
	var clear := Color(fill, 0.0)
	if opens_left:
		var fade_width: float = size.x - opaque_width
		draw_rect(Rect2(fade_width, 0.0, opaque_width, size.y), fill)
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(fade_width, 0), Vector2(fade_width, size.y), Vector2(0, size.y)]), PackedColorArray([clear, fill, fill, clear]))
	else:
		draw_rect(Rect2(0.0, 0.0, opaque_width, size.y), fill)
		draw_polygon(PackedVector2Array([Vector2(opaque_width, 0), Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(opaque_width, size.y)]), PackedColorArray([fill, clear, clear, fill]))

func _add_gap(height: float) -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, height)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(gap)

func _build_kicker(kind: String, reward: String, time_left_text: String, is_urgent: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 4)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN

	var mini_ribbon = TOP_BAR_ICON_SCRIPT.new("mini_" + kind, 0.0, TopBarStyle.INK)
	mini_ribbon.custom_minimum_size = Vector2(10.0, 14.0)
	mini_ribbon.fill_color = TopBarStyle.reward_color(reward)
	mini_ribbon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(mini_ribbon)
	var kicker := TopBarStyle.make_label(KIND_KEY.get(kind, "QUEST_KIND_REWARD"), &"QuestKickerLabel")
	kicker.add_theme_color_override("font_color", TopBarStyle.reward_text_color(reward))
	kicker.uppercase = true
	row.add_child(kicker)

	_time_label = null
	_time_urgent = is_urgent
	if !time_left_text.is_empty():
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(spacer)
		var time_color: Color = TopBarStyle.URGENT if is_urgent else TopBarStyle.INK_SOFT
		if is_urgent:
			var hourglass = TOP_BAR_ICON_SCRIPT.new("hourglass", 13.0, time_color, true)
			hourglass.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(hourglass)
		_time_label = TopBarStyle.make_label(time_left_text, &"QuestUrgentCaptionLabel" if is_urgent else &"QuestCaptionLabel")
		row.add_child(_time_label)
	return row

## Italic like a card description, the exact condition upright in bold: <b>...</b>.
## Added before the text is set, so the icon size comes from the theme.
func _add_text(text: String) -> void:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.theme_type_variation = &"QuestText"
	_content.add_child(label)
	label.text = DescriptionMarkup.to_bbcode(text, label.get_theme_font_size("normal_font_size"))

func _build_progress(progress: int, target: int, reward: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	var fill_color: Color = TopBarStyle.reward_color(reward)
	if target <= MAX_PIPS:
		for index in range(target):
			var pip := _Pip.new()
			pip.filled = index < progress
			pip.fill_color = fill_color
			row.add_child(pip)
	else:
		var track := _Track.new()
		track.ratio = float(progress) / float(target)
		track.fill_color = fill_color
		row.add_child(track)
	var count := TopBarStyle.make_label("%d / %d" % [progress, target], &"QuestCountLabel")
	count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(count)
	return row

func _build_footer(quest: Dictionary, reward: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 9)

	var reward_row := HBoxContainer.new()
	reward_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_row.add_theme_constant_override("separation", 4)
	reward_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	reward_row.add_child(TopBarStyle.make_label(tr("QUEST_REWARD_LABEL"), &"QuestCaptionLabel"))
	var amount_text: String = tr("QUEST_STORY_CONTINUES") if reward == "story" else "+" + TopBarStyle.format_number(int(quest.get("amount", 0)))
	reward_row.add_child(TopBarStyle.make_label(amount_text, &"QuestAmountLabel"))
	reward_row.add_child(_reward_icon(reward))
	row.add_child(reward_row)

	if bool(quest.get("done", false)):
		row.add_child(_build_claim_button(reward))
	return row

func _reward_icon(reward: String) -> Control:
	if reward == "coin":
		var coin := TextureRect.new()
		coin.texture = COIN_TEXTURE
		coin.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coin.custom_minimum_size = Vector2.ONE * 16.0
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return coin
	var icon = TOP_BAR_ICON_SCRIPT.new("draw" if reward == "draw" else "book", 16.0, TopBarStyle.INK)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return icon

## The panel's one primary action: ink fill, paper text, small.
func _build_claim_button(reward: String) -> Button:
	var button := Button.new()
	button.text = tr("QUEST_CLAIM")
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0.0, 30.0)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.theme_type_variation = &"QuestClaimButton"
	if reward != "story":
		button.set_meta("sfx_click", "buy")
	button.pressed.connect(func() -> void: claim_requested.emit(quest_id))
	return button

## One step of a quest up to ten steps long; an empty one is a paper-shade slot.
class _Pip:
	extends Control

	const RADIUS: float = 5.0

	var filled: bool = false
	var fill_color: Color = Color.WHITE

	func _init() -> void:
		custom_minimum_size = Vector2.ONE * RADIUS * 2.0
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		InkStampMaterial.apply(self, true)

	func _draw() -> void:
		var center: Vector2 = size * 0.5
		draw_circle(center, RADIUS, fill_color if filled else TopBarStyle.PAPER_SHADE, true, -1.0, true)
		draw_arc(center, RADIUS - TopBarStyle.STROKE * 0.5, 0.0, TAU, 24, TopBarStyle.INK, TopBarStyle.STROKE, true)

## The progress of a quest longer than ten steps.
class _Track:
	extends Control

	var ratio: float = 0.0
	var fill_color: Color = Color.WHITE

	func _init() -> void:
		custom_minimum_size = Vector2(0.0, 8.0)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		InkStampMaterial.apply(self, true)

	func _draw() -> void:
		var track := StyleBoxFlat.new()
		track.bg_color = TopBarStyle.PAPER_SHADE
		track.set_corner_radius_all(4)
		draw_style_box(track, Rect2(Vector2.ZERO, size))
		if ratio > 0.0:
			var fill := StyleBoxFlat.new()
			fill.bg_color = fill_color
			fill.set_corner_radius_all(4)
			draw_style_box(fill, Rect2(Vector2.ZERO, Vector2(maxf(size.y, size.x * clampf(ratio, 0.0, 1.0)), size.y)))
		var border := StyleBoxFlat.new()
		border.draw_center = false
		border.set_border_width_all(int(TopBarStyle.STROKE))
		border.border_color = TopBarStyle.INK
		border.set_corner_radius_all(4)
		draw_style_box(border, Rect2(Vector2.ZERO, size))
