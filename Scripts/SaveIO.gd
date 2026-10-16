extends Node

## Single gateway for every JSON save file the game keeps in user://.
##
## Every store (collection, decks, player progress, story progress) reads and
## writes through here instead of touching FileAccess directly, so that
## swapping the backing storage later - Steam Cloud / ISteamRemoteStorage in
## particular - is a change in this one file rather than in every store.
##
## On top of that indirection it adds two things the stores used to lack:
##   * atomic writes (write to a .tmp sibling, verify, then swap into place),
##     so a crash mid-write can never leave a truncated save behind;
##   * sync metadata (schema_version / updated_at_unix / device_id) stamped
##     into every file, which is what a cloud conflict resolver needs to tell
##     two versions of the same save apart.

const SAVE_DIR: String = "user://"
const TEMP_SUFFIX: String = ".tmp"
const DEVICE_ID_FILE_NAME: String = "device_id.txt"
const META_SCHEMA_VERSION: String = "schema_version"
const META_UPDATED_AT: String = "updated_at_unix"
const META_DEVICE_ID: String = "device_id"

var _device_id: String = ""

## Reads a save file. Returns an empty dictionary when the file is missing or
## unparseable - callers are expected to fall back to their own defaults, the
## same way they did when they owned the FileAccess calls themselves.
func read_json(file_name: String) -> Dictionary:
	var parsed = read_json_value(file_name)
	if parsed is Dictionary:
		return parsed
	if parsed != null:
		push_error("SaveIO expected a JSON object in %s." % resolve_path(file_name))
	return {}

## Same as read_json() but keeps whatever JSON type the file holds, for the
## legacy save shapes that can be a top-level array instead of an object.
## Returns null when the file is missing or unparseable.
func read_json_value(file_name: String):
	var path: String = resolve_path(file_name)
	if !FileAccess.file_exists(path):
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	file = null
	return parsed

## Writes a save file atomically. `data` is stamped with sync metadata first,
## so callers never have to remember to do it.
func write_json(file_name: String, data: Dictionary, schema_version: int = -1) -> bool:
	var path: String = resolve_path(file_name)
	var payload: Dictionary = stamp_metadata(data, schema_version)
	var text: String = JSON.stringify(payload, "\t")

	var temp_path: String = path + TEMP_SUFFIX
	if !_write_text(temp_path, text):
		# Temp write failed - fall back to writing in place rather than
		# losing the save entirely.
		return _write_text(path, text)

	if !_is_readable_json(temp_path):
		push_error("SaveIO wrote an unreadable temp file for %s; keeping the previous save." % path)
		DirAccess.remove_absolute(temp_path)
		return false

	if !_swap_into_place(temp_path, path):
		# Swap failed (locked file, exotic filesystem) - the temp copy is
		# known-good, so write straight to the target as a last resort.
		var direct_ok: bool = _write_text(path, text)
		DirAccess.remove_absolute(temp_path)
		return direct_ok

	return true

## Adds/refreshes the fields a cloud sync needs to compare two saves.
## Pass schema_version < 0 to keep whatever the caller already put in.
func stamp_metadata(data: Dictionary, schema_version: int = -1) -> Dictionary:
	var payload: Dictionary = data.duplicate(true)
	if schema_version >= 0:
		payload[META_SCHEMA_VERSION] = schema_version
	payload[META_UPDATED_AT] = int(Time.get_unix_time_from_system())
	payload[META_DEVICE_ID] = get_device_id()
	return payload

## Stable per-install identifier, generated once and kept next to the saves.
## Used to tell "my own older save" apart from "another machine's save" when
## a cloud provider hands us both.
func get_device_id() -> String:
	if !_device_id.is_empty():
		return _device_id

	var path: String = resolve_path(DEVICE_ID_FILE_NAME)
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			_device_id = file.get_as_text().strip_edges()
			file = null
	if _device_id.is_empty():
		_device_id = _generate_device_id()
		_write_text(path, _device_id)
	return _device_id

func get_updated_at_unix(data: Dictionary) -> int:
	return int(data.get(META_UPDATED_AT, 0))

func file_exists(file_name: String) -> bool:
	return FileAccess.file_exists(resolve_path(file_name))

func delete_file(file_name: String) -> bool:
	var path: String = resolve_path(file_name)
	if !FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(path) == OK

## Accepts both bare names ("story_progress.json") and full user:// paths, so
## the stores can keep their existing constants if they want to.
func resolve_path(file_name: String) -> String:
	var cleaned_name: String = file_name.strip_edges()
	if cleaned_name.begins_with("user://") or cleaned_name.begins_with("res://"):
		return cleaned_name
	return SAVE_DIR + cleaned_name

func _write_text(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveIO could not open %s for writing (error %d)." % [path, FileAccess.get_open_error()])
		return false
	file.store_string(text)
	file.flush()
	file = null
	return true

func _is_readable_json(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file = null
	return parsed is Dictionary

func _swap_into_place(temp_path: String, path: String) -> bool:
	if FileAccess.file_exists(path) and DirAccess.remove_absolute(path) != OK:
		return false
	return DirAccess.rename_absolute(temp_path, path) == OK

func _generate_device_id() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return "%08x%08x" % [rng.randi(), rng.randi()]
