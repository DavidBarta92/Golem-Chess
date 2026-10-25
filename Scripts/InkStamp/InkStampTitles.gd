extends Node

## Gives Display and Title text the ink stamp (InkStampMaterial): any Label
## whose font resolves to the Display or Title role, wherever it comes from -
## its own type variation or one based on those roles. Smaller text is left
## alone: it would lose its strokes. A label with a material of its own keeps
## it. Drawn items (the top bar's ribbons and icons) stamp themselves.

const InkStampMaterial = preload("res://Scripts/InkStamp/InkStampMaterial.gd")

var _stamped_fonts: Array[Font] = []

func _ready() -> void:
	var theme: Theme = ThemeDB.get_project_theme()
	if theme == null or InkStampMaterial.shared() == null:
		return
	for role in [&"DisplayLabel", &"TitleLabel"]:
		if theme.has_font(&"font", role):
			_stamped_fonts.append(theme.get_font(&"font", role))
	get_tree().node_added.connect(_on_node_added)
	_visit(get_tree().root)

func _visit(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_visit(child)

func _on_node_added(node: Node) -> void:
	var label := node as Label
	if label == null:
		return
	# The role can arrive after the label: a script often sets the variation
	# once the label is in the tree.
	if !label.theme_changed.is_connected(_refresh):
		label.theme_changed.connect(_refresh.bind(label))
	_refresh(label)

func _refresh(label: Label) -> void:
	if !is_instance_valid(label) or !label.is_inside_tree():
		return
	if _stamped_fonts.has(label.get_theme_font(&"font")):
		InkStampMaterial.apply(label)
	elif InkStampMaterial.is_stamped(label):
		label.material = null
