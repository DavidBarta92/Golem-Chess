extends Node

## The Bourse's state (Docs/Bourse/BOURSE.md), saved in user://bourse.json:
##   * the player's lots: five free copies and an asking price each, up to
##     LOT_SLOTS of them. A buyer comes every VISIT_SECONDS and rolls each lot
##     against its sale chance (BourseMarket.sale_chance). A sold lot waits
##     for the player: collecting it pays the price, takes the stamp the buyer
##     drew out of the collection and frees the other four.
##   * the game's lots of the day: MARKET_LOTS_PER_DAY made-up sellers, one
##     blind pick from each. A pick is paid first and its order shuffled and
##     saved before the cards are shown, so leaving midway cannot draw again.
##
## Copies on a lot stay in the collection until the lot is settled; the
## collection counts them as taken (PlayerCollectionStore._prepare_reservations).

signal changed
## Lots that sold during the visits just run, for the notice.
signal lots_sold(lots: Array)

const BOURSE_PATH: String = "user://bourse.json"
const BOURSE_SCHEMA_VERSION: int = 1
const LOT_SLOTS: int = 4
const VISIT_SECONDS: int = 2 * 3600
## Visits made up for when the game was closed, at most: a day's worth.
const MAX_CATCH_UP_VISITS: int = 12
const MARKET_LOTS_PER_DAY: int = 4
const CHECK_SECONDS: float = 20.0
const STATE_LISTED: String = "listed"
const STATE_SOLD: String = "sold"

var data: Dictionary = {}
var is_loaded: bool = false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	var timer := Timer.new()
	timer.name = "VisitClock"
	timer.wait_time = CHECK_SECONDS
	timer.autostart = true
	timer.timeout.connect(func() -> void: run_due_visits())
	add_child(timer)

func ensure_loaded() -> void:
	if is_loaded:
		return
	var raw: Dictionary = SaveIO.read_json(BOURSE_PATH)
	data = _normalize(raw)
	is_loaded = true
	if raw.is_empty():
		save()

func save() -> bool:
	ensure_loaded()
	return SaveIO.write_json(BOURSE_PATH, data, BOURSE_SCHEMA_VERSION)

# --- The player's lots -------------------------------------------------------------

func get_lots() -> Array:
	ensure_loaded()
	return (data["lots"] as Array).duplicate(true)

func get_lot(lot_id: String) -> Dictionary:
	ensure_loaded()
	for lot in data["lots"]:
		if str(lot.get("lot_id", "")) == lot_id:
			return (lot as Dictionary).duplicate(true)
	return {}

func get_free_slot_count() -> int:
	ensure_loaded()
	return maxi(0, LOT_SLOTS - (data["lots"] as Array).size())

## Copies of each print held by the player's lots, sold ones included until
## they are collected: the collection does not count them as free.
func get_reserved_print_counts() -> Dictionary:
	ensure_loaded()
	var counts: Dictionary = {}
	for lot in data["lots"]:
		for print_id in lot.get("print_ids", []):
			counts[str(print_id)] = int(counts.get(str(print_id), 0)) + 1
	return counts

## Puts five free copies up at `price`. Returns the lot, or {} when it cannot go
## up (no slot, not five stamps, a copy that is not free, a price out of range).
func list_lot(print_ids: Array, price: int) -> Dictionary:
	ensure_loaded()
	if get_free_slot_count() <= 0 or print_ids.size() != BourseMarket.LOT_SIZE:
		return {}
	if price < 1 or price > BourseMarket.max_price():
		return {}
	var needed: Dictionary = {}
	for print_id in print_ids:
		needed[str(print_id)] = int(needed.get(str(print_id), 0)) + 1
	for print_id in needed.keys():
		if PlayerCollectionStore.get_free_count_for_print_id(str(print_id)) < int(needed[print_id]):
			return {}

	var ids: Array[String] = []
	for print_id in print_ids:
		ids.append(str(print_id))
	var lot: Dictionary = {
		"lot_id": "lot_%d_%d" % [int(Time.get_unix_time_from_system()), _rng.randi() % 100000],
		"print_ids": ids,
		"price": price,
		"listed_at": int(Time.get_unix_time_from_system()),
		"state": STATE_LISTED,
	}
	(data["lots"] as Array).append(lot)
	save()
	PlayerCollectionStore.invalidate_reserved_copies()
	QuestStore.record_event(QuestCondition.EVENT_LOT_LISTED)
	changed.emit()
	return lot.duplicate(true)

## Takes a lot that has not sold back down; its copies are free again.
func withdraw_lot(lot_id: String) -> bool:
	ensure_loaded()
	var index: int = _find_lot_index(lot_id)
	if index < 0 or str(data["lots"][index].get("state", "")) != STATE_LISTED:
		return false
	(data["lots"] as Array).remove_at(index)
	save()
	PlayerCollectionStore.invalidate_reserved_copies()
	changed.emit()
	return true

## Settles a sold lot: the price comes in, the stamp the buyer drew leaves the
## collection, the other four are free again. Returns {"coins": n,
## "print_id": the stamp that went}, or {} for a lot that is not sold.
func collect_lot(lot_id: String) -> Dictionary:
	ensure_loaded()
	var index: int = _find_lot_index(lot_id)
	if index < 0 or str(data["lots"][index].get("state", "")) != STATE_SOLD:
		return {}
	var lot: Dictionary = data["lots"][index]
	var sold_print_id: String = str(lot.get("sold_print_id", ""))
	var coins: int = int(lot.get("price", 0))
	# The lot goes first: from then on its copies are free, and the sold one can
	# leave the collection as a free copy.
	(data["lots"] as Array).remove_at(index)
	save()
	PlayerCollectionStore.invalidate_reserved_copies()
	PlayerCollectionStore.remove_free_print_copy(sold_print_id)
	PlayerProgressStore.add_points(coins)
	QuestStore.record_event(QuestCondition.EVENT_LOT_SOLD)
	changed.emit()
	return {"coins": coins, "print_id": sold_print_id}

func get_sale_chance(lot: Dictionary) -> float:
	return BourseMarket.sale_chance(BourseMarket.values_for(lot.get("print_ids", [])), int(lot.get("price", 0)))

func get_seconds_to_next_visit() -> int:
	ensure_loaded()
	return maxi(0, int(data["next_visit_at"]) - int(Time.get_unix_time_from_system()))

## Sold lots whose notice has not been shown yet.
func get_unannounced_sales() -> Array:
	ensure_loaded()
	var sales: Array = []
	for lot in data["lots"]:
		if str(lot.get("state", "")) == STATE_SOLD and !bool(lot.get("announced", false)):
			sales.append((lot as Dictionary).duplicate(true))
	return sales

func mark_sales_announced() -> void:
	ensure_loaded()
	var any: bool = false
	for lot in data["lots"]:
		if str(lot.get("state", "")) == STATE_SOLD and !bool(lot.get("announced", false)):
			lot["announced"] = true
			any = true
	if any:
		save()

func get_sold_count() -> int:
	ensure_loaded()
	var count: int = 0
	for lot in data["lots"]:
		if str(lot.get("state", "")) == STATE_SOLD:
			count += 1
	return count

## Runs the buyers' visits that are due, up to now (`now_unix` for tests), and
## returns the lots that sold.
func run_due_visits(now_unix: int = -1) -> Array:
	ensure_loaded()
	var now: int = now_unix if now_unix >= 0 else int(Time.get_unix_time_from_system())
	var next_visit: int = int(data["next_visit_at"])
	if now < next_visit:
		return []
	var due: int = (now - next_visit) / VISIT_SECONDS + 1
	if due > MAX_CATCH_UP_VISITS:
		next_visit += (due - MAX_CATCH_UP_VISITS) * VISIT_SECONDS
		due = MAX_CATCH_UP_VISITS

	var sold: Array = []
	for i in range(due):
		var visit_at: int = next_visit + i * VISIT_SECONDS
		for lot in data["lots"]:
			if str(lot.get("state", "")) != STATE_LISTED or int(lot.get("listed_at", 0)) > visit_at:
				continue
			if _rng.randf() >= get_sale_chance(lot):
				continue
			_mark_sold(lot, visit_at)
			sold.append((lot as Dictionary).duplicate(true))
	data["next_visit_at"] = next_visit + due * VISIT_SECONDS
	save()
	if !sold.is_empty():
		lots_sold.emit(sold)
	changed.emit()
	return sold

## A buyer takes a listed lot at once, whatever its chance - for the main
## menu's developer tools. Returns the sold lot, or {} for one not listed.
func sell_lot_now(lot_id: String) -> Dictionary:
	ensure_loaded()
	var index: int = _find_lot_index(lot_id)
	if index < 0 or str(data["lots"][index].get("state", "")) != STATE_LISTED:
		return {}
	var lot: Dictionary = data["lots"][index]
	_mark_sold(lot, int(Time.get_unix_time_from_system()))
	save()
	var sold: Dictionary = lot.duplicate(true)
	lots_sold.emit([sold])
	changed.emit()
	return sold

## The buyer draws one of the five at random.
func _mark_sold(lot: Dictionary, sold_at: int) -> void:
	var print_ids: Array = lot.get("print_ids", [])
	lot["state"] = STATE_SOLD
	lot["sold_at"] = sold_at
	lot["sold_print_id"] = str(print_ids[_rng.randi_range(0, print_ids.size() - 1)])
	lot["buyer"] = RandomOpponentFactory.create_person(_rng)
	lot["announced"] = false

# --- The game's lots of the day ------------------------------------------------------

## Today's lots, made when the day's first question comes.
func get_market_lots() -> Array:
	ensure_loaded()
	var today: String = Time.get_date_string_from_system()
	if str(data["market_day"]) != today:
		data["market_day"] = today
		data["market_lots"] = _make_market_lots()
		data.erase("pending_pick")
		save()
		changed.emit()
	return (data["market_lots"] as Array).duplicate(true)

func get_market_lot(lot_id: String) -> Dictionary:
	for lot in get_market_lots():
		if str(lot.get("lot_id", "")) == lot_id:
			return lot
	return {}

## New lots come at local midnight.
func get_seconds_to_next_market() -> int:
	var time: Dictionary = Time.get_time_dict_from_system()
	return maxi(1, 86400 - (int(time.hour) * 3600 + int(time.minute) * 60 + int(time.second)))

## The pick paid for but not yet made, or {}: {"lot_id", "order": five print ids}.
func get_pending_pick() -> Dictionary:
	ensure_loaded()
	var pending = data.get("pending_pick", {})
	return (pending as Dictionary).duplicate(true) if pending is Dictionary else {}

## Pays for a pick from a game lot and shuffles its stamps. False when the lot
## is gone or picked, another pick is waiting, or the coins are short.
func start_pick(lot_id: String) -> bool:
	var lot: Dictionary = get_market_lot(lot_id)
	if lot.is_empty() or !str(lot.get("picked_print_id", "")).is_empty() or !get_pending_pick().is_empty():
		return false
	var price: int = int(lot.get("price", 0))
	if PlayerProgressStore.get_points() < price:
		return false
	var order: Array = (lot.get("print_ids", []) as Array).duplicate()
	order.shuffle()
	data["pending_pick"] = {"lot_id": lot_id, "order": order, "price": price}
	save()
	if !PlayerProgressStore.spend_points(price):
		data.erase("pending_pick")
		save()
		return false
	changed.emit()
	return true

## The player turned card `index`: that stamp is theirs. Returns its print id.
func finish_pick(index: int) -> String:
	var pending: Dictionary = get_pending_pick()
	var order: Array = pending.get("order", [])
	if order.is_empty() or index < 0 or index >= order.size():
		return ""
	var print_id: String = str(order[index])
	# The stamp first: a crash after it costs the player nothing.
	PlayerCollectionStore.add_local_print_copy(print_id)
	for lot in data["market_lots"]:
		if str(lot.get("lot_id", "")) == str(pending.get("lot_id", "")):
			lot["picked_print_id"] = print_id
	data.erase("pending_pick")
	save()
	QuestStore.record_event(QuestCondition.EVENT_LOT_BOUGHT)
	changed.emit()
	return print_id

func _make_market_lots() -> Array:
	PlayerCollectionStore.ensure_loaded()
	var is_owned := func(print_id: String) -> bool: return PlayerCollectionStore.owns_print_id(print_id)
	var lots: Array = []
	var new_used: Dictionary = {}
	for i in range(MARKET_LOTS_PER_DAY):
		var print_ids: Array[String] = BourseMarket.generate_lot(_rng, is_owned, new_used)

		if print_ids.is_empty():
			continue
		lots.append({
			"lot_id": "market_%s_%d" % [str(data["market_day"]), i],
			"seller": RandomOpponentFactory.create_person(_rng),
			"print_ids": print_ids,
			"price": BourseMarket.market_price(BourseMarket.values_for(print_ids), _rng),
			"picked_print_id": "",
		})
	return lots

# --- Save shape ---------------------------------------------------------------------

func _find_lot_index(lot_id: String) -> int:
	var lots: Array = data["lots"]
	for index in range(lots.size()):
		if str(lots[index].get("lot_id", "")) == lot_id:
			return index
	return -1

func _normalize(raw: Dictionary) -> Dictionary:
	var normalized: Dictionary = {
		"schema_version": BOURSE_SCHEMA_VERSION,
		"lots": [],
		"next_visit_at": int(raw.get("next_visit_at", int(Time.get_unix_time_from_system()) + VISIT_SECONDS)),
		"market_day": str(raw.get("market_day", "")),
		"market_lots": [],
	}
	for lot in raw.get("lots", []):
		if lot is Dictionary and (lot.get("print_ids", []) as Array).size() == BourseMarket.LOT_SIZE:
			normalized["lots"].append(lot)
	for lot in raw.get("market_lots", []):
		if lot is Dictionary:
			normalized["market_lots"].append(lot)
	if raw.get("pending_pick", null) is Dictionary:
		normalized["pending_pick"] = raw["pending_pick"]
	return normalized
