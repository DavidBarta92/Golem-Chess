extends Node

const DEFAULT_CLICK_SOUND: String = "button_click"
const DEFAULT_HOVER_SOUND: String = "button_hover"

func _ready() -> void:
	_connect_existing_buttons(get_tree().root)
	get_tree().node_added.connect(Callable(self, "_on_node_added"))

func _connect_existing_buttons(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_connect_existing_buttons(child)

func _on_node_added(node: Node) -> void:
	var button: BaseButton = node as BaseButton
	if button == null:
		return

	var press_callable: Callable = Callable(self, "_on_button_pressed").bind(button)
	if !button.pressed.is_connected(press_callable):
		button.pressed.connect(press_callable)

	var hover_callable: Callable = Callable(self, "_on_button_hovered").bind(button)
	if !button.mouse_entered.is_connected(hover_callable):
		button.mouse_entered.connect(hover_callable)

func _on_button_pressed(button: BaseButton) -> void:
	SFXManager.play(str(button.get_meta("sfx_click", DEFAULT_CLICK_SOUND)))

func _on_button_hovered(button: BaseButton) -> void:
	if button.disabled:
		return
	SFXManager.play(str(button.get_meta("sfx_hover", DEFAULT_HOVER_SOUND)))
