extends PanelContainer

## The main menu's word that a buyer picked from one of the player's lots:
## "Kovács Anna picked from your lot: Duke", and a way to the Bourse. It sits
## above the story buttons, shows while sales wait unseen, and goes once the
## Bourse has been opened (BourseScreen marks them seen) or the sale is
## collected from its notice in the top bar (GlobalTopBar's SaleRibbon). A sale
## during the visit to the menu brings it up there and then.

const BOURSE_SCENE: String = "res://Scenes/Bourse.tscn"
const MAX_LINES: int = 2
## Its bottom edge, up from the screen's: clear of the story buttons.
const BOTTOM_OFFSET: float = 210.0
const RIGHT_OFFSET: float = 24.0
const WIDTH: float = 300.0

var lines: VBoxContainer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var style: StyleBox = get_theme_stylebox("panel", &"ResultPanel").duplicate()
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style)
	custom_minimum_size = Vector2(WIDTH, 0)
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_right = -RIGHT_OFFSET
	offset_left = -RIGHT_OFFSET - WIDTH
	offset_bottom = -BOTTOM_OFFSET
	offset_top = -BOTTOM_OFFSET

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	var kicker := Label.new()
	kicker.text = tr("BOURSE_LOT_SOLD")
	kicker.uppercase = true
	kicker.theme_type_variation = &"KickerLabel"
	kicker.add_theme_color_override("font_color", UiPalette.COIN_DEEP)
	column.add_child(kicker)
	lines = VBoxContainer.new()
	lines.add_theme_constant_override("separation", 4)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(lines)
	var button := Button.new()
	button.text = tr("BOURSE_NOTICE_OPEN")
	button.theme_type_variation = &"QuestClaimButton"
	button.custom_minimum_size = Vector2(0, 36)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void:
		button.disabled = true
		SceneTransition.change_scene(BOURSE_SCENE))
	column.add_child(button)

	BourseStore.changed.connect(_refresh)
	BourseStore.run_due_visits()
	_refresh()

func _exit_tree() -> void:
	if BourseStore.changed.is_connected(_refresh):
		BourseStore.changed.disconnect(_refresh)

func _refresh() -> void:
	var sales: Array = BourseStore.get_unannounced_sales()
	visible = !sales.is_empty() and StoryProgressStore.is_feature_unlocked(StoryFeatures.TRADE)
	for child in lines.get_children():
		child.queue_free()
	for index in range(mini(MAX_LINES, sales.size())):
		var sale: Dictionary = sales[index]
		var buyer: Dictionary = sale.get("buyer", {})
		var stamp: Stamp = StampPrintLibrary.get_stamp_for_print(StampPrintLibrary.get_print(str(sale.get("sold_print_id", ""))))
		var line := Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.text = tr("BOURSE_NOTICE_SOLD") % [
			RandomOpponentFactory.format_name(str(buyer.get("surname", "")), str(buyer.get("given_name", ""))),
			stamp.stamp_name if stamp != null else "",
		]
		lines.add_child(line)
	if sales.size() > MAX_LINES:
		var more := Label.new()
		more.theme_type_variation = &"CaptionLabel"
		more.text = "+%d" % (sales.size() - MAX_LINES)
		lines.add_child(more)
