extends RefCounted

var canvas_layer: CanvasLayer
var card_visual_scene: PackedScene
var card_ui_size: Vector2 = Vector2(164, 229)
var card_base_texture: Texture2D
var hover_card_margin: float = 24.0
var hover_card_preview_scale: float = 0.82
var hover_card_vertical_offset: float = 54.0
var hover_card_rotation_degrees: float = -4.0
var hover_card_visual_edge_overlap: float = 12.0
var hover_piece_preview_size: Vector2 = Vector2(188, 224)
var hover_piece_preview_vertical_offset: float = -78.0
var description_text_margin: Vector2 = Vector2(22, 30)
var description_frame_edge_color: Color = Color(0.12, 0.085, 0.055, 0.62)
var description_frame_edge_thickness: float = 2.0
var description_frame_edge_horizontal_inset: float = 18.0
var description_frame_edge_vertical_inset: float = 19.0

var hover_card_group: Control
var hover_card_preview: CardVisual
var hover_piece_preview: TextureRect
var hover_duration_label: Label
var hover_description_panel: Control
var hover_description_label: Label

func configure(config: Dictionary) -> void:
	canvas_layer = config.get("canvas_layer", canvas_layer)
	card_visual_scene = config.get("card_visual_scene", card_visual_scene)
	card_ui_size = config.get("card_ui_size", card_ui_size)
	card_base_texture = config.get("card_base_texture", card_base_texture)
	hover_card_margin = float(config.get("hover_card_margin", hover_card_margin))
	hover_card_preview_scale = float(config.get("hover_card_preview_scale", hover_card_preview_scale))
	hover_card_vertical_offset = float(config.get("hover_card_vertical_offset", hover_card_vertical_offset))
	hover_card_rotation_degrees = float(config.get("hover_card_rotation_degrees", hover_card_rotation_degrees))
	hover_card_visual_edge_overlap = float(config.get("hover_card_visual_edge_overlap", hover_card_visual_edge_overlap))
	hover_piece_preview_size = config.get("hover_piece_preview_size", hover_piece_preview_size)
	hover_piece_preview_vertical_offset = float(config.get("hover_piece_preview_vertical_offset", hover_piece_preview_vertical_offset))
	description_text_margin = config.get("description_text_margin", description_text_margin)
	description_frame_edge_color = config.get("description_frame_edge_color", description_frame_edge_color)
	description_frame_edge_thickness = float(config.get("description_frame_edge_thickness", description_frame_edge_thickness))
	description_frame_edge_horizontal_inset = float(config.get("description_frame_edge_horizontal_inset", description_frame_edge_horizontal_inset))
	description_frame_edge_vertical_inset = float(config.get("description_frame_edge_vertical_inset", description_frame_edge_vertical_inset))

func create_ui() -> void:
	if canvas_layer == null or !is_instance_valid(canvas_layer):
		return
	if hover_card_group != null and is_instance_valid(hover_card_group):
		return

	hover_card_group = Control.new()
	canvas_layer.add_child(hover_card_group)
	hover_card_group.name = "HoverCardGroup"
	hover_card_group.visible = false
	hover_card_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_card_group.anchor_left = 1.0
	hover_card_group.anchor_right = 1.0
	hover_card_group.anchor_top = 0.5
	hover_card_group.anchor_bottom = 0.5
	var hover_card_group_size := Vector2(card_ui_size.x * 2.0 - hover_card_visual_edge_overlap, card_ui_size.y)
	hover_card_group.offset_right = -hover_card_margin
	hover_card_group.offset_left = hover_card_group.offset_right - hover_card_group_size.x
	hover_card_group.offset_top = -hover_card_group_size.y * 0.5 + hover_card_vertical_offset
	hover_card_group.offset_bottom = hover_card_group.offset_top + hover_card_group_size.y
	hover_card_group.pivot_offset = hover_card_group_size * 0.5
	hover_card_group.scale = Vector2.ONE * hover_card_preview_scale
	hover_card_group.rotation_degrees = hover_card_rotation_degrees
	hover_card_group.z_index = 900

	create_description_panel()
	create_piece_preview()
	create_card_preview()
	create_duration_label()

func create_description_panel() -> void:
	hover_description_panel = Control.new()
	hover_card_group.add_child(hover_description_panel)
	hover_description_panel.name = "HoverDescriptionCard"
	hover_description_panel.visible = false
	hover_description_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_description_panel.anchor_left = 0.0
	hover_description_panel.anchor_right = 0.0
	hover_description_panel.anchor_top = 0.0
	hover_description_panel.anchor_bottom = 0.0
	hover_description_panel.offset_left = 0.0
	hover_description_panel.offset_right = card_ui_size.x
	hover_description_panel.offset_top = 0.0
	hover_description_panel.offset_bottom = card_ui_size.y
	hover_description_panel.z_index = 0

	var hover_description_base := TextureRect.new()
	hover_description_panel.add_child(hover_description_base)
	hover_description_base.name = "CardBase"
	hover_description_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_description_base.anchor_left = 0.0
	hover_description_base.anchor_right = 1.0
	hover_description_base.anchor_top = 0.0
	hover_description_base.anchor_bottom = 1.0
	hover_description_base.offset_left = 0.0
	hover_description_base.offset_right = 0.0
	hover_description_base.offset_top = 0.0
	hover_description_base.offset_bottom = 0.0
	hover_description_base.texture = card_base_texture
	hover_description_base.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	hover_description_base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hover_description_base.stretch_mode = TextureRect.STRETCH_SCALE

	for edge_data: Dictionary in [
		{
			"name": "TopFrameEdge",
			"y": description_frame_edge_vertical_inset,
		},
		{
			"name": "BottomFrameEdge",
			"y": card_ui_size.y - description_frame_edge_vertical_inset - description_frame_edge_thickness,
		},
	]:
		var edge := ColorRect.new()
		hover_description_panel.add_child(edge)
		edge.name = str(edge_data["name"])
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		edge.color = description_frame_edge_color
		edge.offset_left = description_frame_edge_horizontal_inset
		edge.offset_right = card_ui_size.x - description_frame_edge_horizontal_inset
		edge.offset_top = float(edge_data["y"])
		edge.offset_bottom = float(edge_data["y"]) + description_frame_edge_thickness

	hover_description_label = Label.new()
	hover_description_panel.add_child(hover_description_label)
	hover_description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_description_label.anchor_left = 0.0
	hover_description_label.anchor_right = 1.0
	hover_description_label.anchor_top = 0.0
	hover_description_label.anchor_bottom = 1.0
	hover_description_label.offset_left = description_text_margin.x
	hover_description_label.offset_right = -description_text_margin.x
	hover_description_label.offset_top = description_text_margin.y
	hover_description_label.offset_bottom = -description_text_margin.y
	hover_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hover_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hover_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hover_description_label.add_theme_font_size_override("font_size", 16)
	hover_description_label.add_theme_color_override("font_color", Color(0.12, 0.085, 0.055))
	hover_description_label.add_theme_color_override("font_shadow_color", Color(1.0, 0.96, 0.82, 0.48))
	hover_description_label.add_theme_constant_override("shadow_offset_x", 1)
	hover_description_label.add_theme_constant_override("shadow_offset_y", 1)

func create_piece_preview() -> void:
	hover_piece_preview = TextureRect.new()
	canvas_layer.add_child(hover_piece_preview)
	hover_piece_preview.visible = false
	hover_piece_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_piece_preview.anchor_left = 1.0
	hover_piece_preview.anchor_right = 1.0
	hover_piece_preview.anchor_top = 0.5
	hover_piece_preview.anchor_bottom = 0.5
	hover_piece_preview.offset_left = -hover_piece_preview_size.x - hover_card_margin
	hover_piece_preview.offset_right = -hover_card_margin
	hover_piece_preview.offset_top = -hover_piece_preview_size.y * 0.5 + hover_piece_preview_vertical_offset
	hover_piece_preview.offset_bottom = hover_piece_preview_size.y * 0.5 + hover_piece_preview_vertical_offset
	hover_piece_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hover_piece_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hover_piece_preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	hover_piece_preview.z_index = 899

func create_card_preview() -> void:
	hover_card_preview = card_visual_scene.instantiate() as CardVisual if card_visual_scene != null else null
	if hover_card_preview == null:
		return

	hover_card_group.add_child(hover_card_preview)
	hover_card_preview.visible = false
	hover_card_preview.draggable = false
	hover_card_preview.disabled = true
	hover_card_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_card_preview.anchor_left = 0.0
	hover_card_preview.anchor_right = 0.0
	hover_card_preview.anchor_top = 0.0
	hover_card_preview.anchor_bottom = 0.0
	hover_card_preview.offset_left = card_ui_size.x - hover_card_visual_edge_overlap
	hover_card_preview.offset_right = card_ui_size.x * 2.0 - hover_card_visual_edge_overlap
	hover_card_preview.offset_top = 0.0
	hover_card_preview.offset_bottom = card_ui_size.y
	hover_card_preview.set_rest_scale(Vector2.ONE)
	hover_card_preview.rotation_degrees = 0.0
	hover_card_preview.z_index = 1

func create_duration_label() -> void:
	hover_duration_label = Label.new()
	canvas_layer.add_child(hover_duration_label)
	hover_duration_label.visible = false
	hover_duration_label.size = Vector2(48, 32)
	hover_duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hover_duration_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hover_duration_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_duration_label.z_index = 901

	var label_settings: LabelSettings = LabelSettings.new()
	label_settings.font_size = 22
	label_settings.font_color = Color(1.0, 1.0, 1.0)
	label_settings.outline_size = 5
	label_settings.outline_color = Color(0.0, 0.0, 0.0)
	hover_duration_label.label_settings = label_settings

func show_piece_details(preview_card: Card, preview_texture: Texture2D, duration_text: String) -> void:
	if preview_card != null and hover_card_preview != null:
		hover_card_preview.set_card(preview_card)
		hover_card_preview.set_face_down(false)
		hover_card_preview.disabled = true
		hover_card_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hover_card_preview.rotation_degrees = 0.0
		hover_card_preview.set_rest_scale(Vector2.ONE)
		hover_card_group.visible = true
		hover_card_preview.visible = true
		show_description(preview_card.description.strip_edges())

	show_piece_preview(preview_texture)
	if hover_duration_label != null:
		hover_duration_label.text = duration_text
		hover_duration_label.visible = true

func show_description(description: String) -> void:
	if hover_description_label == null or hover_description_panel == null:
		return
	hover_description_label.text = description
	hover_description_panel.visible = !description.is_empty()
	if !description.is_empty() and hover_card_group != null:
		hover_card_group.visible = true

func show_piece_preview(preview_texture: Texture2D) -> void:
	if hover_piece_preview == null:
		return
	if preview_texture == null:
		hover_piece_preview.visible = false
		hover_piece_preview.texture = null
		return

	hover_piece_preview.texture = preview_texture
	hover_piece_preview.visible = true

func hide() -> void:
	if hover_card_group:
		hover_card_group.visible = false
	if hover_card_preview:
		hover_card_preview.visible = false
	if hover_piece_preview:
		hover_piece_preview.visible = false
		hover_piece_preview.texture = null
	if hover_description_panel:
		hover_description_panel.visible = false
	if hover_description_label:
		hover_description_label.text = ""
	if hover_duration_label:
		hover_duration_label.visible = false

func update_duration_label_position(piece_screen_position: Vector2) -> void:
	if !hover_duration_label or !hover_duration_label.visible:
		return
	hover_duration_label.global_position = piece_screen_position + Vector2(-hover_duration_label.size.x * 0.5, -46.0)
