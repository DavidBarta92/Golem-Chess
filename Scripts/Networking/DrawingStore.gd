class_name DrawingStore
extends RefCounted

## The players' own drawings (Docs/StampPainter/STAMP_PAINTER.md) in a match:
## this player's from the drawings folder, the other players' as they arrive
## over the network, kept on disk by their hash so each travels once.
##
## A drawing rides in a stamp's print slot as "drawing:<sha-256 of the PNG>":
## it goes wherever the stamp's print goes (GameStateData's print pages, the
## state, StampVisual), and whoever has to show it and has not got the picture
## asks for it by that hash (drawing_wanted; Multiplayer sends the request).
## Until it comes, the stamp shows in its standard print.
##
## Which drawing a stamp uses: the newest one in the drawings folder for that
## stamp's code (the painter names them <stamp code>_<nn>.png), for every copy
## of the stamp in the player's codex.

## A picture that was not here is now: the stamps waiting for it redraw.
signal drawing_ready(drawing_hash: String)
## Someone wants to show a picture that is not here.
signal drawing_wanted(drawing_hash: String)

const PRINT_PREFIX: String = "drawing:"
const DRAWINGS_FOLDER: String = "Golem Chess/Drawings"
const DRAWINGS_DIR_ARGUMENT: String = "--drawings-dir="
const CACHE_DIR: String = "user://drawing_cache"
## The art's size (Assets/Stamps/); a drawing of any other size is refused.
const ART_SIZE: Vector2i = Vector2i(554, 700)
## A full-colour PNG of that size stays well under this.
const MAX_BYTES: int = 1500000
const CHUNK_BYTES: int = 30000
## How long before the same picture is asked for again.
const REQUEST_RETRY_SECONDS: float = 6.0

static var _instance: DrawingStore

var _bytes_by_hash: Dictionary = {}
var _textures_by_hash: Dictionary = {}
var _prints: Dictionary = {}
var _local_by_stamp_code: Dictionary = {}
var _local_scanned: bool = false
var _requested_at: Dictionary = {}
## Pictures on their way in: hash -> {"total", "chunks": {index: bytes}}.
var _incoming: Dictionary = {}

static func instance() -> DrawingStore:
	if _instance == null:
		_instance = DrawingStore.new()
	return _instance

static func is_drawing_print_id(print_id: String) -> bool:
	if !print_id.begins_with(PRINT_PREFIX):
		return false
	var drawing_hash: String = print_id.trim_prefix(PRINT_PREFIX)
	return drawing_hash.length() == 64 and drawing_hash.is_valid_hex_number()

static func hash_of_print_id(print_id: String) -> String:
	return print_id.trim_prefix(PRINT_PREFIX) if is_drawing_print_id(print_id) else ""

static func drawings_dir() -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(DRAWINGS_DIR_ARGUMENT):
			return argument.trim_prefix(DRAWINGS_DIR_ARGUMENT)
	var documents: String = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if documents.is_empty():
		return ProjectSettings.globalize_path("user://drawings")
	return documents.path_join(DRAWINGS_FOLDER)

## This player's drawing for a stamp, as a print id; "" when they have none.
func get_local_print_id(stamp_code: String) -> String:
	_scan_local()
	var drawing_hash: String = str(_local_by_stamp_code.get(stamp_code, ""))
	return PRINT_PREFIX + drawing_hash if !drawing_hash.is_empty() else ""

## Looks at the drawings folder again (after the painter saved).
func rescan_local() -> void:
	_local_scanned = false

func _scan_local() -> void:
	if _local_scanned:
		return
	_local_scanned = true
	_local_by_stamp_code.clear()
	var directory: String = drawings_dir()
	var dir := DirAccess.open(directory)
	if dir == null:
		return
	# Newest first, and the newest that is a proper drawing wins.
	var by_code: Dictionary = {}
	for file_name in dir.get_files():
		if file_name.get_extension().to_lower() != "png":
			continue
		var base: String = file_name.get_basename()
		var split: int = base.rfind("_")
		if split <= 0 or !base.substr(split + 1).is_valid_int():
			continue
		var stamp_code: String = base.substr(0, split)
		if !by_code.has(stamp_code):
			by_code[stamp_code] = []
		by_code[stamp_code].append([int(base.substr(split + 1)), directory.path_join(file_name)])
	for stamp_code in by_code:
		var candidates: Array = by_code[stamp_code]
		candidates.sort_custom(func(a, b): return a[0] > b[0])
		for candidate in candidates:
			var drawing_hash: String = _accept(FileAccess.get_file_as_bytes(str(candidate[1])))
			if !drawing_hash.is_empty():
				_local_by_stamp_code[stamp_code] = drawing_hash
				break

## The picture's bytes, from memory or the cache; empty when it is not here.
func get_bytes(drawing_hash: String) -> PackedByteArray:
	if _bytes_by_hash.has(drawing_hash):
		return _bytes_by_hash[drawing_hash]
	var path: String = CACHE_DIR.path_join(drawing_hash + ".png")
	if FileAccess.file_exists(path):
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
		if _accept(bytes) == drawing_hash:
			return bytes
	return PackedByteArray()

func has_drawing(drawing_hash: String) -> bool:
	return !get_bytes(drawing_hash).is_empty()

## The stamp's print with this drawing as its art; null while the picture is
## not here, and then it is asked for.
func get_print(print_id: String, stamp_code: String) -> StampPrint:
	var drawing_hash: String = hash_of_print_id(print_id)
	if drawing_hash.is_empty():
		return null
	var key: String = drawing_hash + "|" + stamp_code
	if _prints.has(key):
		return _prints[key]
	var texture: Texture2D = _get_texture(drawing_hash)
	if texture == null:
		want(drawing_hash)
		return null
	var drawing := StampPrint.new()
	drawing.print_id = print_id
	drawing.stamp_code = stamp_code
	drawing.variant_id = StampPrintLibrary.STANDARD_VARIANT_ID
	drawing.variant_name = "Drawing"
	drawing.stamp_art = texture
	_prints[key] = drawing
	return drawing

func _get_texture(drawing_hash: String) -> Texture2D:
	if _textures_by_hash.has(drawing_hash):
		return _textures_by_hash[drawing_hash]
	var bytes: PackedByteArray = get_bytes(drawing_hash)
	if bytes.is_empty():
		return null
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK:
		return null
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_textures_by_hash[drawing_hash] = texture
	return texture

## Asks for a picture that is not here, at most once every few seconds.
func want(drawing_hash: String) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - float(_requested_at.get(drawing_hash, -1000.0)) < REQUEST_RETRY_SECONDS:
		return
	_requested_at[drawing_hash] = now
	drawing_wanted.emit(drawing_hash)

## The picture cut up for sending: [[index, total, bytes], ...].
func get_chunks(drawing_hash: String) -> Array:
	var bytes: PackedByteArray = get_bytes(drawing_hash)
	var chunks: Array = []
	if bytes.is_empty():
		return chunks
	var total: int = ceili(float(bytes.size()) / CHUNK_BYTES)
	for index in range(total):
		chunks.append([index, total, bytes.slice(index * CHUNK_BYTES, mini((index + 1) * CHUNK_BYTES, bytes.size()))])
	return chunks

## One piece of a picture off the network. True once the whole picture is in
## and is what its hash says; anything else that is wrong with it drops it.
func receive_chunk(drawing_hash: String, index: int, total: int, chunk: PackedByteArray) -> bool:
	if drawing_hash.length() != 64 or !drawing_hash.is_valid_hex_number() or has_drawing(drawing_hash):
		return false
	if total <= 0 or total > ceili(float(MAX_BYTES) / CHUNK_BYTES) or index < 0 or index >= total or chunk.size() > CHUNK_BYTES:
		_incoming.erase(drawing_hash)
		return false
	var entry: Dictionary = _incoming.get(drawing_hash, {"total": total, "chunks": {}})
	if int(entry["total"]) != total:
		entry = {"total": total, "chunks": {}}
	entry["chunks"][index] = chunk
	_incoming[drawing_hash] = entry
	if (entry["chunks"] as Dictionary).size() < total:
		return false
	var bytes := PackedByteArray()
	for chunk_index in range(total):
		bytes.append_array(entry["chunks"][chunk_index])
	_incoming.erase(drawing_hash)
	if _accept(bytes) != drawing_hash:
		push_warning("A drawing arrived that is not what its hash says; dropped.")
		_bytes_by_hash.erase(_hash(bytes))
		return false
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	var file := FileAccess.open(CACHE_DIR.path_join(drawing_hash + ".png"), FileAccess.WRITE)
	if file != null:
		file.store_buffer(bytes)
		file.close()
	drawing_ready.emit(drawing_hash)
	return true

## Takes the bytes in if they are a PNG of the art's size and not too big;
## returns their hash, or "" when they are refused.
func _accept(bytes: PackedByteArray) -> String:
	if bytes.is_empty() or bytes.size() > MAX_BYTES:
		return ""
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK or image.get_size() != ART_SIZE:
		return ""
	var drawing_hash: String = _hash(bytes)
	_bytes_by_hash[drawing_hash] = bytes
	return drawing_hash

func _hash(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
