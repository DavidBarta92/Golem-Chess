@tool
extends EditorPlugin

# Adds the "Becsült érték" Inspector field and the Bélyegértékek dock, and keeps every stamp's
# stored estimated_value in step with the weights (see StampValueTools.sync_stamps). It syncs
# after every edit, undo or redo, every save (Ctrl+S saves without a resource_saved signal, but
# each save is followed by filesystem_changed) and every reload from disk.

const StampValueInspectorPlugin = preload("res://addons/stamp_value_estimator/stamp_value_inspector_plugin.gd")
const StampValueDock = preload("res://addons/stamp_value_estimator/stamp_value_dock.gd")
const StampValueTools = preload("res://addons/stamp_value_estimator/stamp_value_tools.gd")

var inspector_plugin: EditorInspectorPlugin
var dock: StampValueDock
# Held so the stamps stay in the resource cache: a value stored only in memory must survive
# until the user's save writes it.
var stamps: Array[Stamp] = []
var sync_queued: bool = false

func _enter_tree() -> void:
	inspector_plugin = StampValueInspectorPlugin.new()
	add_inspector_plugin(inspector_plugin)
	dock = StampValueDock.new()
	add_dock(dock)

	EditorInterface.get_editor_undo_redo().version_changed.connect(_queue_sync)
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(_on_filesystem_changed)
	EditorInterface.get_resource_filesystem().resources_reload.connect(_on_resources_reload)
	resource_saved.connect(_on_resource_saved)
	_on_filesystem_changed()

func _exit_tree() -> void:
	EditorInterface.get_editor_undo_redo().version_changed.disconnect(_queue_sync)
	EditorInterface.get_resource_filesystem().filesystem_changed.disconnect(_on_filesystem_changed)
	EditorInterface.get_resource_filesystem().resources_reload.disconnect(_on_resources_reload)
	resource_saved.disconnect(_on_resource_saved)
	stamps.clear()

	if dock != null:
		remove_dock(dock)
		dock.queue_free()
		dock = null
	if inspector_plugin != null:
		remove_inspector_plugin(inspector_plugin)
		inspector_plugin = null

func _on_filesystem_changed() -> void:
	stamps = StampValueTools.load_stamps()
	_queue_sync()

func _on_resources_reload(_paths: PackedStringArray) -> void:
	_queue_sync()

func _on_resource_saved(_resource: Resource) -> void:
	_queue_sync()

# One sync per frame at most, after the edit or save that asked for it has finished.
func _queue_sync() -> void:
	if sync_queued:
		return
	sync_queued = true
	_sync.call_deferred()

func _sync() -> void:
	sync_queued = false
	var counts: Dictionary = StampValueTools.sync_stamps(stamps)
	if counts.saved + counts.failed > 0:
		StampValueTools.report(counts)
		if dock != null:
			dock.request_refresh()
