extends OptionElement
class_name VSyncElement

func _init() -> void:
	IDENTIFIER = "VSync"
	DEFAULT_VALUE = "Enabled"
	OPTION_LIST_ = {
		"Disabled": DisplayServer.VSYNC_DISABLED,
		"Enabled": DisplayServer.VSYNC_ENABLED,
		"Adaptive": DisplayServer.VSYNC_ADAPTIVE,
	}

func load_settings() -> void:
	super.load_settings()
	call_deferred("update_max_fps_enabled")

func option_selected(index: int) -> void:
	super.option_selected(index)
	update_max_fps_enabled()

func _apply_settings() -> void:
	DisplayServer.window_set_vsync_mode(OPTION_LIST_[currentValue])

	if currentValue != "Disabled":
		Engine.max_fps = 0
	elif ParentRef.ELEMENT_REFERENCE_TABLE_.has("MaxFPS"):
		ParentRef.ELEMENT_REFERENCE_TABLE_["MaxFPS"]._apply_settings()

func update_max_fps_enabled() -> void:
	if not ParentRef.ELEMENT_REFERENCE_TABLE_.has("MaxFPS"):
		return
	var max_fps_element: OptionElement = ParentRef.ELEMENT_REFERENCE_TABLE_["MaxFPS"]
	var vsync_active: bool = currentValue != "Disabled"
	max_fps_element.OptionsRef.disabled = vsync_active
	if vsync_active:
		# V-Sync already caps the frame rate, so Max FPS is forced to Unlimited
		# to avoid showing a stale value that no longer has any effect.
		max_fps_element.currentValue = "Unlimited"
		max_fps_element.init_element()
