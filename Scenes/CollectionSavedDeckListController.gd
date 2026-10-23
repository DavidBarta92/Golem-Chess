extends RefCounted
class_name CollectionSavedDeckListController

const STAMP_VISUAL = preload("res://Scenes/StampVisual.tscn")
const CODEX_TEXTURE: Texture2D = preload("res://Assets/collection_codex.png")
const CODEX_FOLD_TEXTURE: Texture2D = preload("res://Assets/collection_codex_folder.png")
const EDIT_ICON: Texture2D = preload("res://Assets/edit.png")
const DELETE_ICON: Texture2D = preload("res://Assets/delete.png")
const COLLECTION_THEME: Theme = preload("res://ui/themes/collection_theme.tres")
const INK_TINT_SHADER = preload("res://Shaders/ink_tint.gdshader")
## A warm dark grey, a little lighter than the ink of the buttons.
const CODEX_NAME_COLOR: Color = CollectionPalette.INK
## Small enough for most names to fit; a long one wraps onto a second line
## before it is cut.
const CODEX_NAME_FONT_SIZE: int = 16
const CODEX_NAME_MAX_LINES: int = 2
const CODEX_COUNT_COLOR: Color = Color(0.95, 0.92, 0.86)
const CODEX_COUNT_INCOMPLETE_COLOR: Color = Color(0.93, 0.33, 0.27)
const MIN_MATCHES_FOR_WIN_RATE: int = 3
const CODEX_PREVIEW_STAMP_SCALE: float = 0.38
const CODEX_ICON_BUTTON_SIZE: Vector2 = Vector2(40, 40)
const CODEX_ICON_BUTTON_ICON_MARGIN: float = 10.0
# Layout inside a codex, in the codex art's own pixels (the art is 551 x 208:
# rings along the top, paper down to y 110, the fold below that). The name
# sits on the paper, the stamps peek out of the fold, count and buttons sit
# on the fold.
const CODEX_ART_NAME_RECT: Rect2 = Rect2(30, 38, 256, 74)
const CODEX_ART_FOOTER_RECT: Rect2 = Rect2(30, 122, 494, 72)
const CODEX_ART_PREVIEW_STAMP_TOP_LEFTS: Array[Vector2] = [Vector2(292, 40), Vector2(364, 34), Vector2(436, 40)]
const CODEX_PREVIEW_STAMP_ROTATIONS: Array[float] = [-8.0, 8.0, -4.0]

var collection
var deck_list: VBoxContainer
var stamp_visual_size: Vector2 = Vector2(168.7, 229)
var max_deck_size: int = 6
var codex_size: Vector2 = Vector2(368, 139)
var icon_ink_material: ShaderMaterial

var reset_scroll_callback: Callable = Callable()
var edit_deck_callback: Callable = Callable()
var editor_back_callback: Callable = Callable()
var print_for_deck_stamp_provider: Callable = Callable()

func bind(config: Dictionary) -> void:
	collection = config.get("collection", collection)
	deck_list = config.get("deck_list", deck_list) as VBoxContainer
	stamp_visual_size = config.get("stamp_visual_size", stamp_visual_size)
	max_deck_size = int(config.get("max_deck_size", max_deck_size))
	codex_size = config.get("codex_size", codex_size)
	reset_scroll_callback = config.get("reset_scroll_callback", reset_scroll_callback)
	edit_deck_callback = config.get("edit_deck_callback", edit_deck_callback)
	editor_back_callback = config.get("editor_back_callback", editor_back_callback)
	print_for_deck_stamp_provider = config.get("print_for_deck_stamp_provider", print_for_deck_stamp_provider)

func populate_saved_decks_list() -> void:
	if deck_list == null:
		return

	for child in deck_list.get_children():
		deck_list.remove_child(child)
		child.queue_free()

	if reset_scroll_callback.is_valid():
		reset_scroll_callback.call()

	var saved_decks: Array = PlayerDeckStore.list_decks()
	if saved_decks.is_empty():
		var empty_label := Label.new()
		deck_list.add_child(empty_label)
		empty_label.text = tr("No saved codexes")
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return

	for deck_data in saved_decks:
		if !(deck_data is Dictionary):
			continue
		deck_list.add_child(create_saved_deck_row(deck_data))

func create_saved_deck_row(deck_data: Dictionary) -> Control:
	var ownership_info: Dictionary = PlayerDeckStore.get_deck_ownership_info(deck_data)
	var is_playable: bool = bool(ownership_info.get("is_playable", false))
	var owned_count: int = int(ownership_info.get("owned_count", 0))

	var row_frame := Control.new()
	row_frame.custom_minimum_size = codex_size
	row_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_frame.mouse_filter = Control.MOUSE_FILTER_PASS
	row_frame.clip_contents = false

	var art_scale: float = codex_size.x / float(CODEX_TEXTURE.get_width())
	row_frame.add_child(create_codex_art_layer(CODEX_TEXTURE))

	var preview_prints: Array = get_deck_preview_prints(deck_data)
	for index in range(preview_prints.size()):
		var preview_print: StampPrint = preview_prints[index] as StampPrint
		if preview_print == null:
			continue
		var preview_visual := create_small_deck_preview_stamp(preview_print)
		row_frame.add_child(preview_visual)
		# The visual scales around its centre, so offset its position to put the
		# drawn stamp's top-left corner where the layout wants it.
		var drawn_top_left: Vector2 = CODEX_ART_PREVIEW_STAMP_TOP_LEFTS[index] * art_scale
		preview_visual.position = drawn_top_left - preview_visual.pivot_offset * (1.0 - CODEX_PREVIEW_STAMP_SCALE)
		preview_visual.rotation = deg_to_rad(CODEX_PREVIEW_STAMP_ROTATIONS[index])

	row_frame.add_child(create_codex_art_layer(CODEX_FOLD_TEXTURE))

	var name_label := Label.new()
	row_frame.add_child(name_label)
	name_label.position = CODEX_ART_NAME_RECT.position * art_scale
	name_label.size = CODEX_ART_NAME_RECT.size * art_scale
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = str(deck_data.get("name", tr("Unnamed codex")))
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = CODEX_NAME_MAX_LINES
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", CODEX_NAME_FONT_SIZE)
	name_label.add_theme_constant_override("line_spacing", 0)
	name_label.add_theme_color_override("font_color", CODEX_NAME_COLOR)

	var footer := HBoxContainer.new()
	row_frame.add_child(footer)
	footer.position = CODEX_ART_FOOTER_RECT.position * art_scale
	footer.size = CODEX_ART_FOOTER_RECT.size * art_scale
	footer.mouse_filter = Control.MOUSE_FILTER_PASS
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 8)

	var count_label := Label.new()
	footer.add_child(count_label)
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.text = "%d/%d" % [owned_count if !is_playable else max_deck_size, max_deck_size]
	if is_playable:
		count_label.text += "  " + get_win_rate_text(deck_data)
		var stats: Dictionary = PlayerDeckStore.get_deck_stats(deck_data)
		count_label.tooltip_text = tr("CODEX_WIN_RATE_TOOLTIP").format({"won": int(stats["won"]), "played": int(stats["played"])})
		count_label.mouse_filter = Control.MOUSE_FILTER_PASS
	count_label.add_theme_font_size_override("font_size", 18)
	count_label.add_theme_color_override("font_color", CODEX_COUNT_INCOMPLETE_COLOR if !is_playable else CODEX_COUNT_COLOR)

	var edit_button := create_circle_icon_button(EDIT_ICON, tr("Edit codex"))
	footer.add_child(edit_button)
	if edit_deck_callback.is_valid():
		edit_button.pressed.connect(edit_deck_callback.bind(deck_data.duplicate(true)))

	var delete_button := create_circle_icon_button(DELETE_ICON, tr("Delete codex"))
	footer.add_child(delete_button)
	delete_button.pressed.connect(on_delete_deck_pressed.bind(str(deck_data.get("deck_id", ""))))

	return row_frame

## Share of the matches won with the codex since it last changed. Too few to
## mean anything shows a dash rather than a 100% after a single win.
func get_win_rate_text(deck_data: Dictionary) -> String:
	var stats: Dictionary = PlayerDeckStore.get_deck_stats(deck_data)
	var played: int = int(stats["played"])
	if played < MIN_MATCHES_FOR_WIN_RATE:
		return "-%"
	return "%d%%" % int(round(100.0 * float(stats["won"]) / float(played)))

# The codex and its fold are cut from the same frame, so drawing both over the
# full codex rect keeps the fold lined up with the codex's sides and bottom.
func create_codex_art_layer(texture: Texture2D) -> TextureRect:
	var art := TextureRect.new()
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.size = codex_size
	return art

func get_deck_preview_prints(deck_data: Dictionary) -> Array:
	var preview_prints: Array = []
	var deck_stamps = deck_data.get("stamps", [])
	if !(deck_stamps is Array):
		return preview_prints

	var candidate_indexes: Array = [0, int(deck_stamps.size() / 2), maxi(0, deck_stamps.size() - 1)]
	for candidate_index in candidate_indexes:
		if candidate_index < 0 or candidate_index >= deck_stamps.size():
			continue
		var deck_stamp = deck_stamps[candidate_index]
		if !(deck_stamp is Dictionary):
			continue
		var stamp_print: StampPrint = get_print_for_deck_stamp(deck_stamp)
		if stamp_print != null && !preview_prints.has(stamp_print):
			preview_prints.append(stamp_print)
		if preview_prints.size() >= 3:
			break
	return preview_prints

func create_small_deck_preview_stamp(stamp_print: StampPrint) -> StampVisual:
	var stamp_visual := STAMP_VISUAL.instantiate() as StampVisual
	stamp_visual.custom_minimum_size = stamp_visual_size
	stamp_visual.size = stamp_visual_size
	stamp_visual.set_hover_raise_enabled(false)
	stamp_visual.set_stamp_print(stamp_print)
	stamp_visual.set_face_down(false)
	stamp_visual.set_collection_owned(true)
	stamp_visual.pivot_offset = stamp_visual_size * 0.5
	stamp_visual.set_rest_scale(Vector2.ONE * CODEX_PREVIEW_STAMP_SCALE)
	stamp_visual.draggable = false
	stamp_visual.disabled = true
	stamp_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return stamp_visual

## A round version of the Collection's buttons: the same near-white fill and
## thin ink outline (from collection_theme.tres), with the icon re-inked warm.
func create_circle_icon_button(icon: Texture2D, tooltip: String) -> Button:
	var button := Button.new()
	button.tooltip_text = tooltip
	button.custom_minimum_size = CODEX_ICON_BUTTON_SIZE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	var radius: int = int(CODEX_ICON_BUTTON_SIZE.x * 0.5)
	var pressed_style := _round_theme_button_style("hover", radius)
	pressed_style.bg_color = CollectionPalette.PAPER
	button.add_theme_stylebox_override("normal", _round_theme_button_style("normal", radius))
	button.add_theme_stylebox_override("hover", _round_theme_button_style("hover", radius))
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("hover_pressed", pressed_style)

	if icon_ink_material == null:
		icon_ink_material = ShaderMaterial.new()
		icon_ink_material.shader = INK_TINT_SHADER
		icon_ink_material.set_shader_parameter("ink_color", CollectionPalette.INK)
	var icon_rect := TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.texture = icon
	icon_rect.material = icon_ink_material
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon_rect)
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, int(CODEX_ICON_BUTTON_ICON_MARGIN))
	return button

func _round_theme_button_style(style_name: String, radius: int) -> StyleBoxFlat:
	var style := COLLECTION_THEME.get_stylebox(style_name, "Button").duplicate() as StyleBoxFlat
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(0.0)
	return style

func on_delete_deck_pressed(deck_id: String) -> void:
	if deck_id.is_empty():
		return
	PlayerDeckStore.delete_deck(deck_id)
	if collection != null and str(collection.editing_deck_id) == deck_id and editor_back_callback.is_valid():
		editor_back_callback.call()
	populate_saved_decks_list()

func get_print_for_deck_stamp(deck_stamp: Dictionary) -> StampPrint:
	if print_for_deck_stamp_provider.is_valid():
		return print_for_deck_stamp_provider.call(deck_stamp) as StampPrint
	return null
