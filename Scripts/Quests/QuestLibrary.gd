extends RefCounted
class_name QuestLibrary

## Every quest template under res://Quests/Templates/ (subfolders too), loaded
## once, and the settings next to them.

const TEMPLATES_PATH: String = "res://Quests/Templates"
const SETTINGS_PATH: String = "res://Quests/quest_settings.tres"

static var _templates: Array[QuestTemplate] = []
static var _settings: QuestSettings
static var _loaded: bool = false

## The enabled templates, by id.
static func get_templates() -> Array[QuestTemplate]:
	if !_loaded:
		_load()
	return _templates.duplicate()

static func get_template(template_id: String) -> QuestTemplate:
	for template in get_templates():
		if template.template_id == template_id:
			return template
	return null

static func get_settings() -> QuestSettings:
	if !_loaded:
		_load()
	return _settings

static func reload() -> void:
	_loaded = false
	_templates.clear()
	_settings = null

static func _load() -> void:
	_loaded = true
	_templates.clear()
	_settings = load(SETTINGS_PATH) as QuestSettings if ResourceLoader.exists(SETTINGS_PATH) else null
	if _settings == null:
		push_warning("Quest settings not found at %s; using the defaults." % SETTINGS_PATH)
		_settings = QuestSettings.new()
	var seen_ids: Dictionary = {}
	for path in PuzzleLibrary._find_resource_paths(TEMPLATES_PATH):
		var template := load(path) as QuestTemplate
		if template == null or !template.enabled:
			continue
		if template.template_id.strip_edges().is_empty():
			push_warning("Quest template %s left out: no template_id." % path)
			continue
		if seen_ids.has(template.template_id):
			push_warning("Quest template %s left out: template_id '%s' is used by %s too." % [path, template.template_id, seen_ids[template.template_id]])
			continue
		seen_ids[template.template_id] = path
		_templates.append(template)
	_templates.sort_custom(func(a: QuestTemplate, b: QuestTemplate) -> bool: return a.template_id < b.template_id)
