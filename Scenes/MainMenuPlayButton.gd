extends ArtworkCroppedButton

## The main menu's Play window. Not a button of its own any more, and it does
## not pop on hover: hovering it stamps three small buttons onto the middle of
## its pane one after the other, the way the top bar's items arrive
## (InkStampMotion), and leaving it dissolves them again. They step up from
## left to right along the pane's slant (row_slope). Each is an icon-only
## button in the usual ink style, framed at rest and flooded on hover:
##   story  - burgundy, a book (the story quest ribbon's colour and icon): the
##            story's next fight (StoryManager.continue_story_if_ready)
##   random - ink, a person: a generated opponent
##            (StoryManager.start_random_opponent_match)
##   online - a globe, inactive for now: multiplayer, later
## Story and random can be turned off with set_mode_enabled. The story button
## is also off while the story has nothing Play can start (all done, or
## waiting for a story quest to be claimed).
##
## Choosing one dissolves the three buttons first; only then does the window
## slide from slide_start_offset to slide_end_offset (both relative to its
## natural resting position, tweak in the Inspector), easing in from a
## standstill up to full speed. The scene change starts
## scene_change_lead_distance pixels before the slide reaches the end point,
## so the fade overlaps the tail end of the movement.

const InkStampMotion = preload("res://Scripts/InkStamp/InkStampMotion.gd")
const TopBarIcon = preload("res://Scripts/TopBar/TopBarIcon.gd")
const TopBarStyle = preload("res://Scripts/TopBar/TopBarStyle.gd")

const MODE_STORY: StringName = &"story"
const MODE_RANDOM: StringName = &"random"
const MODE_ONLINE: StringName = &"online"
## Left to right. The online button stays inactive until multiplayer is
## wired up here.
const MODES: Array[Dictionary] = [
	{"mode": MODE_STORY, "icon": "book", "variation": &"StoryButton", "tooltip": "PLAY_MODE_STORY", "sfx": "play_button_click"},
	{"mode": MODE_RANDOM, "icon": "person", "variation": &"", "tooltip": "PLAY_MODE_RANDOM", "sfx": "play_button_click"},
	{"mode": MODE_ONLINE, "icon": "globe", "variation": &"", "tooltip": "PLAY_MODE_ONLINE", "sfx": ""},
]
## The top bar's square icon button (TopBarStyle.BUTTON_SIZE) and icon.
const MODE_BUTTON_SIZE: float = TopBarStyle.BUTTON_SIZE
const MODE_ICON_SIZE: float = TopBarStyle.ICON_MENU
## The design's space-4 (16 px), at the game's 0.75.
const MODE_BUTTON_GAP: float = 12.0

@export var slide_start_offset: Vector2 = Vector2.ZERO
@export var slide_end_offset: Vector2 = Vector2(0.0, -40.0)
@export var slide_duration: float = 0.5
@export var scene_change_lead_distance: float = 25.0
## The middle of the window's pane, in the artwork's own pixels: the middle
## button sits on it. Measured as the centroid of the open pane.
@export var pane_centre: Vector2 = Vector2(589.0, 606.0)
## How much higher each button sits than the one on its left, per unit of
## sideways distance: the slant of the pane's midline in the artwork (its top
## edge rises about 0.29, its bottom edge about 0.5).
@export var row_slope: float = 0.39

var _slide_tween: Tween
var _slide_start_pos: Vector2
var _slide_end_pos: Vector2
var _scene_change_triggered: bool = false

## A plain Control, not a container: a container's layout pass would set the
## buttons' scale and rotation back while they are being stamped in.
var _mode_row: Control
## Mode -> its Button, in MODES order.
var _mode_buttons: Dictionary = {}
var _mode_enabled: Dictionary = {MODE_STORY: true, MODE_RANDOM: true, MODE_ONLINE: false}
var _row_tween: Tween
var _row_shown: bool = false
var _pointer_inside: bool = false
## Set once a mode is chosen: the window is on its way out.
var _chosen_mode: StringName = &""

func _ready() -> void:
	# The window itself takes no clicks, only the hover.
	button_mask = 0
	focus_mode = Control.FOCUS_NONE
	_build_mode_row()
	super()
	# The window turns pressable (the opponent has walked up) or not.
	draw.connect(_queue_sync)
	_refresh_mode_buttons()

## Turns the story or the random opponent button on or off.
func set_mode_enabled(mode: StringName, enabled: bool) -> void:
	if mode == MODE_ONLINE or !_mode_enabled.has(mode):
		return
	_mode_enabled[mode] = enabled
	_refresh_mode_buttons()

func _build_mode_row() -> void:
	_mode_row = Control.new()
	_mode_row.name = "ModeButtons"
	_mode_row.visible = false
	_mode_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_mode_row)
	for spec in MODES:
		var mode: StringName = spec["mode"]
		var button := Button.new()
		button.name = "%sButton" % String(mode).capitalize()
		button.custom_minimum_size = Vector2.ONE * MODE_BUTTON_SIZE
		button.focus_mode = Control.FOCUS_NONE
		# Hovering a button still hovers the window (_notification).
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		button.theme_type_variation = spec["variation"]
		button.tooltip_text = spec["tooltip"]
		button.set_meta("sfx_click", spec["sfx"])
		var icon = TopBarIcon.new(spec["icon"], MODE_ICON_SIZE)
		icon.position = (button.custom_minimum_size - icon.custom_minimum_size) * 0.5
		icon.size = icon.custom_minimum_size
		button.add_child(icon)
		button.draw.connect(_sync_icon.bind(button, icon))
		button.pressed.connect(_on_mode_pressed.bind(mode))
		_mode_row.add_child(button)
		_mode_buttons[mode] = button

func _refresh_mode_buttons() -> void:
	for mode in _mode_buttons:
		var enabled: bool = _mode_enabled.get(mode, false)
		if mode == MODE_STORY:
			enabled = enabled and StoryManager.can_continue_story()
		(_mode_buttons[mode] as Button).disabled = !enabled

## The glyph is a child, not the button's icon, so it follows the label's
## colour by hand, as the top bar's menu glyph does: through the hover's
## flood (InkHoverFill tints the label), paper when pressed, the inactive
## colour when off.
func _sync_icon(button: Button, icon: Control) -> void:
	var colour: StringName = &"font_color"
	if button.disabled:
		colour = &"font_disabled_color"
	elif button.button_pressed:
		colour = &"font_pressed_color"
	elif button.is_hovered():
		colour = &"font_hover_color"
	icon.color = button.get_theme_color(colour)

func _layout_to_artwork() -> void:
	super()
	_place_mode_row()

## A rising stair centred on the pane, which the artwork's cover scaling moves
## and sizes: one button size plus the gap apart sideways, each row_slope of
## that higher than the last.
func _place_mode_row() -> void:
	if _mode_row == null or _padded_rect.size.x <= 0.0 or _padded_rect.size.y <= 0.0:
		return
	var centre: Vector2 = (pane_centre - _padded_rect.position) / _padded_rect.size * size
	var pitch: float = MODE_BUTTON_SIZE + MODE_BUTTON_GAP
	var step := Vector2(pitch, -pitch * row_slope)
	var button_size: Vector2 = Vector2.ONE * MODE_BUTTON_SIZE
	var count: int = _mode_row.get_child_count()
	var span: Vector2 = (step * float(count - 1)).abs() + button_size
	_mode_row.size = span
	_mode_row.position = centre - span * 0.5
	for index in count:
		var button := _mode_row.get_child(index) as Control
		var offset: Vector2 = step * (float(index) - float(count - 1) * 0.5)
		button.size = button_size
		button.position = span * 0.5 + offset - button_size * 0.5

## The window's hover counts its buttons too: the mouse_entered / mouse_exited
## signals are the window's own area only (moving onto a button would be
## leaving the window), these notifications take in its children - as long as
## the buttons let the pointer through (MOUSE_FILTER_PASS), which a STOP
## child would not.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			_pointer_inside = true
			_sync_mode_row()
		NOTIFICATION_MOUSE_EXIT:
			_pointer_inside = false
			_sync_mode_row()

## No pop on hover any more: the buttons come in instead (_notification).
func _on_hover() -> void:
	pass

func _on_pressed() -> void:
	pass

func _queue_sync() -> void:
	call_deferred("_sync_mode_row")

## Stamps the buttons in while the pointer is over a pressable window, and
## dissolves them when it leaves - from wherever the last move had got to.
## Once a mode is chosen they are on their way out for good (_on_mode_pressed).
func _sync_mode_row() -> void:
	if !_chosen_mode.is_empty():
		return
	var wanted: bool = _pointer_inside and !disabled
	if wanted == _row_shown:
		return
	_row_shown = wanted
	if wanted:
		_stamp_mode_buttons_in()
	else:
		_dissolve_mode_buttons()

func _restart_row_tween() -> void:
	if _row_tween != null and _row_tween.is_valid():
		_row_tween.kill()
	_row_tween = create_tween()
	_row_tween.set_parallel(true)

func _stamp_mode_buttons_in() -> void:
	_restart_row_tween()
	_refresh_mode_buttons()
	_place_mode_row()
	_mode_row.visible = true
	var delay: float = 0.0
	for button in _mode_buttons.values():
		InkStampMotion.settle(button)
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		InkStampMotion.stamp_in(_row_tween, button, delay)
		delay += InkStampMotion.ITEM_STAGGER_SECONDS
	_row_tween.chain().tween_callback(_settle_mode_buttons)

## Left to right, as they came. The row hides once the last one is gone;
## anything chained onto _row_tween after this runs then too.
func _dissolve_mode_buttons() -> void:
	_restart_row_tween()
	var delay: float = 0.0
	for button in _mode_buttons.values():
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		InkStampMotion.dissolve_out(_row_tween, button, delay)
		delay += InkStampMotion.ITEM_STAGGER_SECONDS
	_row_tween.chain().tween_callback(_finish_mode_row_out)

func _settle_mode_buttons() -> void:
	for button in _mode_buttons.values():
		InkStampMotion.settle(button)

func _finish_mode_row_out() -> void:
	_settle_mode_buttons()
	_mode_row.visible = false

## The buttons leave first, then the window goes up.
func _on_mode_pressed(mode: StringName) -> void:
	if !_chosen_mode.is_empty():
		return
	_chosen_mode = mode
	# The window is what the Play hint pointed at, and it is used now.
	StoryProgressStore.mark_feature_hint_seen(StoryFeatures.PLAY)
	AmbienceManager.set_muffled(false, 2.0)
	_dissolve_mode_buttons()
	_row_tween.tween_callback(_start_slide)

func _start_slide() -> void:
	_scene_change_triggered = false
	_slide_start_pos = _base_position + slide_start_offset
	_slide_end_pos = _base_position + slide_end_offset
	position = _slide_start_pos
	_slide_tween = create_tween()
	_slide_tween.tween_method(_on_slide_step, 0.0, 1.0, slide_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _on_slide_step(t: float) -> void:
	position = _slide_start_pos.lerp(_slide_end_pos, t)
	if !_scene_change_triggered and position.distance_to(_slide_end_pos) <= scene_change_lead_distance:
		_scene_change_triggered = true
		_trigger_play_scene_change()

func _trigger_play_scene_change() -> void:
	match _chosen_mode:
		MODE_STORY:
			# Pressable only while the story can go on; should it have finished
			# meanwhile, the player still gets a match.
			if !StoryManager.continue_story_if_ready():
				StoryManager.start_random_opponent_match()
		MODE_RANDOM:
			StoryManager.start_random_opponent_match()
