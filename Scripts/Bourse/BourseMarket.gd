extends RefCounted
class_name BourseMarket

## The Bourse's numbers (Docs/Bourse/BOURSE.md): what a stamp is worth on the
## market, how the made-up buyers weigh a lot of five, the chance a lot sells
## at a buyer's visit, and the lots the game puts up itself.
##
## The player never sees a value. They see what follows from it: how much the
## buyers want a lot (attraction_level) and the chance at the next buyer.

const LOT_SIZE: int = 5
## Collectors pay for scarcity, but less than in proportion to it: a print's
## factor is (the chance of a basic print / the chance of its own rarity) ^ this.
## With the reference odds below a foil is worth about 1.9 basics, a full art 3.1.
const RARITY_EXPONENT: float = 0.3
## The pack odds the rarity factors come from (PackDefinition's defaults).
const REFERENCE_FOIL_CHANCE: float = 0.1
const REFERENCE_FULL_ART_CHANCE: float = 0.02
## Coins per value point, as a share of what a booster's points cost. The
## Bourse pays less for a stamp than a booster charges (else buying boosters to
## sell their stamps would make coins out of nothing) and asks more for one
## you choose than for four you do not.
const SELL_RATE_OF_BOOSTER: float = 0.5
const BUY_RATE_OF_BOOSTER: float = 1.75
## No lot costs more than this share of a booster: one stamp stays cheaper than four.
const MAX_PRICE_OF_BOOSTER: float = 0.8
## The buyers. Each weighs a lot by (mean of value ^ alpha) ^ (1 / alpha): below
## 1 the weak stamps they will most likely draw count most, above 1 the best one
## does. One lot with a single prize and one of five middling stamps can have the
## same mean and still find different buyers.
const BUYER_TYPES: Array[Dictionary] = [
	{"alpha": 0.6, "weight": 0.4},
	{"alpha": 1.0, "weight": 0.4},
	{"alpha": 1.8, "weight": 0.2},
]
## A visit's chance tops out here: even a lot given away waits for a buyer.
const MAX_SALE_CHANCE: float = 0.8
## How quickly a buyer loses interest as the price passes what the lot is worth
## to them: at 10 % over, the chance is about a quarter of its top.
const PRICE_SOFTNESS: float = 0.1
## The game's own lots are priced as a slightly hopeful buyer sees them, then
## shaken, so some are bargains and some are not.
const MARKET_PRICE_ALPHA: float = 1.3
const MARKET_PRICE_NOISE_MIN: float = 0.8
const MARKET_PRICE_NOISE_MAX: float = 1.25
## How often a game lot carries a stamp the player does not have yet.
const NEW_STAMP_CHANCE: float = 0.6
## The kinds of lot the game puts up, and how often each comes.
const LOT_TEMPLATES: Dictionary = {
	"bargain": 0.2,
	"even": 0.25,
	"jackpot": 0.25,
	"set": 0.2,
	"collector": 0.1,
}

static var _booster_points: float = -1.0
static var _market_pool: Array[StampPrint] = []
static var _pool_by_value: Array[StampPrint] = []

## A print's market value: the stamp's estimated value times its rarity factor.
static func print_value(stamp_print: StampPrint) -> float:
	if stamp_print == null:
		return 0.0
	var stamp: Stamp = StampPrintLibrary.get_stamp_for_print(stamp_print)
	if stamp == null:
		return 0.0
	return maxf(0.0, stamp.estimated_value) * rarity_factor(stamp_print.get_rarity())

static func print_id_value(print_id: String) -> float:
	return print_value(StampPrintLibrary.get_print(print_id))

static func values_for(print_ids: Array) -> Array[float]:
	var values: Array[float] = []
	for print_id in print_ids:
		values.append(print_id_value(str(print_id)))
	return values

static func rarity_factor(rarity: int) -> float:
	var basic_chance: float = 1.0 - REFERENCE_FOIL_CHANCE - REFERENCE_FULL_ART_CHANCE
	match rarity:
		StampPrint.Rarity.FOIL:
			return pow(basic_chance / REFERENCE_FOIL_CHANCE, RARITY_EXPONENT)
		StampPrint.Rarity.FULL_ART:
			return pow(basic_chance / REFERENCE_FULL_ART_CHANCE, RARITY_EXPONENT)
	return 1.0

## What the lot is worth to a buyer of this alpha, in value points.
static func certainty_equivalent(values: Array[float], alpha: float) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value in values:
		total += pow(maxf(0.0, value), alpha)
	return pow(total / float(values.size()), 1.0 / alpha)

static func mean(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value in values:
		total += value
	return total / float(values.size())

## The value points a booster brings on average: four stamps of the market's
## mean value, with the reference odds of foil and full art.
static func get_booster_points() -> float:
	if _booster_points > 0.0:
		return _booster_points
	var basic_values: Array[float] = []
	for stamp_print in get_market_pool():
		if stamp_print.get_rarity() == StampPrint.Rarity.BASIC:
			basic_values.append(print_value(stamp_print))
	var mean_value: float = mean(basic_values) if !basic_values.is_empty() else 20.0
	var basic_chance: float = 1.0 - REFERENCE_FOIL_CHANCE - REFERENCE_FULL_ART_CHANCE
	var rarity_mean: float = basic_chance \
		+ REFERENCE_FOIL_CHANCE * rarity_factor(StampPrint.Rarity.FOIL) \
		+ REFERENCE_FULL_ART_CHANCE * rarity_factor(StampPrint.Rarity.FULL_ART)
	_booster_points = maxf(1.0, 4.0 * mean_value * rarity_mean)
	return _booster_points

static func booster_coins_per_point() -> float:
	return float(PlayerProgressStore.PACK_COST) / get_booster_points()

static func sell_coins_per_point() -> float:
	return booster_coins_per_point() * SELL_RATE_OF_BOOSTER

static func buy_coins_per_point() -> float:
	return booster_coins_per_point() * BUY_RATE_OF_BOOSTER

static func max_price() -> int:
	return maxi(1, int(floor(float(PlayerProgressStore.PACK_COST) * MAX_PRICE_OF_BOOSTER)))

## The chance a buyer takes the player's lot at one visit. The buyer's kind is
## part of the roll, so this is the whole chance, as the screen shows it.
static func sale_chance(values: Array[float], price: int) -> float:
	if values.is_empty():
		return 0.0
	var coins_per_point: float = sell_coins_per_point()
	var chance: float = 0.0
	for buyer_type in BUYER_TYPES:
		var worth: float = certainty_equivalent(values, float(buyer_type["alpha"])) * coins_per_point
		var ratio: float = worth / float(maxi(1, price))
		chance += float(buyer_type["weight"]) * _logistic((ratio - 1.0) / PRICE_SOFTNESS)
	return clampf(chance * MAX_SALE_CHANCE, 0.0, MAX_SALE_CHANCE)

## 0-5 bars for the lot being built: the chance against the best a lot can do.
static func attraction_level(chance: float) -> int:
	return clampi(roundi(chance / MAX_SALE_CHANCE * 5.0), 0, 5)

## Where the price starts when the player builds a lot: what an even-minded
## buyer would pay, so the bars start in the middle.
static func suggested_price(values: Array[float]) -> int:
	return clampi(roundi(mean(values) * sell_coins_per_point()), 1, max_price())

## The price the game asks for one of its own lots.
static func market_price(values: Array[float], rng: RandomNumberGenerator) -> int:
	var worth: float = certainty_equivalent(values, MARKET_PRICE_ALPHA) * buy_coins_per_point()
	var price: float = worth * rng.randf_range(MARKET_PRICE_NOISE_MIN, MARKET_PRICE_NOISE_MAX)
	# Round to 5 above 20, as a dealer would mark it.
	var rounded: int = roundi(price / 5.0) * 5 if price > 20.0 else roundi(price)
	return clampi(rounded, 1, max_price())

# --- The game's own lots ----------------------------------------------------------

## Every print a pack on sale can drop: what the made-up sellers have to offer.
static func get_market_pool() -> Array[StampPrint]:
	if !_market_pool.is_empty():
		return _market_pool
	PackDefinitionLibrary.ensure_loaded()
	var by_id: Dictionary = {}
	for pack in PackDefinitionLibrary.get_available_packs():
		for stamp_print in PackDefinitionLibrary.get_reward_print_pool(pack):
			var stamp: Stamp = StampPrintLibrary.get_stamp_for_print(stamp_print)
			if stamp != null and stamp.enabled:
				by_id[stamp_print.print_id] = stamp_print
	for stamp_print in by_id.values():
		_market_pool.append(stamp_print)
	_pool_by_value = _market_pool.duplicate()
	_pool_by_value.sort_custom(func(a: StampPrint, b: StampPrint) -> bool: return print_value(a) < print_value(b))
	return _market_pool

## Five print ids for a game lot. `is_owned` answers whether the player has a
## print, so most lots carry something new to them. `new_used` holds the new
## prints the day's other lots already brought: a player who lacks only one
## stamp would otherwise find it in nearly every lot.
static func generate_lot(rng: RandomNumberGenerator, is_owned: Callable, new_used: Dictionary = {}) -> Array[String]:
	get_market_pool()
	var lot: Array[StampPrint] = []
	if _pool_by_value.is_empty():
		return []
	var template: String = _pick_weighted(rng, LOT_TEMPLATES)
	var basics: Array[StampPrint] = _pool_by_value.filter(func(p: StampPrint) -> bool: return p.get_rarity() == StampPrint.Rarity.BASIC)
	if basics.is_empty():
		basics = _pool_by_value
	var size: int = basics.size()
	match template:
		"bargain":
			for i in range(LOT_SIZE):
				lot.append(basics[rng.randi_range(0, maxi(0, size / 2 - 1))])
		"even":
			for i in range(LOT_SIZE):
				lot.append(basics[rng.randi_range(size / 4, maxi(size / 4, size * 3 / 4 - 1))])
		"jackpot":
			var rare: Array[StampPrint] = _pool_by_value.filter(func(p: StampPrint) -> bool: return p.get_rarity() != StampPrint.Rarity.BASIC)
			if rare.is_empty() or rng.randf() < 0.5:
				lot.append(basics[rng.randi_range(maxi(0, size - maxi(1, size * 15 / 100)), size - 1)])
			else:
				lot.append(rare[rng.randi_range(0, rare.size() - 1)])
			for i in range(LOT_SIZE - 1):
				lot.append(basics[rng.randi_range(0, maxi(0, size / 2 - 1))])
		"set":
			var sets: Array[String] = []
			for stamp_print in basics:
				var stamp_set: String = _get_set(stamp_print)
				if !sets.has(stamp_set):
					sets.append(stamp_set)
			var chosen_set: String = sets[rng.randi_range(0, sets.size() - 1)]
			var in_set: Array[StampPrint] = _pool_by_value.filter(func(p: StampPrint) -> bool: return _get_set(p) == chosen_set)
			for i in range(LOT_SIZE):
				lot.append(in_set[rng.randi_range(0, in_set.size() - 1)])
		_:
			var rare_prints: Array[StampPrint] = _pool_by_value.filter(func(p: StampPrint) -> bool: return p.get_rarity() != StampPrint.Rarity.BASIC)
			for i in range(LOT_SIZE):
				var from: Array[StampPrint] = rare_prints if !rare_prints.is_empty() and i < 2 else _market_pool
				lot.append(from[rng.randi_range(0, from.size() - 1)])

	if is_owned.is_valid() and rng.randf() < NEW_STAMP_CHANCE:
		_ensure_new_stamp(lot, rng, is_owned, template, new_used)

	var print_ids: Array[String] = []
	for stamp_print in lot:
		print_ids.append(stamp_print.print_id)
	print_ids.shuffle()
	return print_ids

## Swaps a stamp the player has for one they lack, unless the lot already has
## one. The jackpot's prize stays where it is.
static func _ensure_new_stamp(lot: Array[StampPrint], rng: RandomNumberGenerator, is_owned: Callable, template: String, new_used: Dictionary) -> void:
	for stamp_print in lot:
		if !bool(is_owned.call(stamp_print.print_id)):
			new_used[stamp_print.print_id] = true
			return
	var lot_set: String = _get_set(lot[0]) if template == "set" else ""
	var unowned: Array[StampPrint] = _market_pool.filter(func(p: StampPrint) -> bool:
		return !bool(is_owned.call(p.print_id)) and !new_used.has(p.print_id) and (lot_set.is_empty() or _get_set(p) == lot_set))
	if unowned.is_empty():
		return
	var first_slot: int = 1 if template == "jackpot" else 0
	var new_print: StampPrint = unowned[rng.randi_range(0, unowned.size() - 1)]
	lot[rng.randi_range(first_slot, lot.size() - 1)] = new_print
	new_used[new_print.print_id] = true


static func _get_set(stamp_print: StampPrint) -> String:
	var stamp: Stamp = StampPrintLibrary.get_stamp_for_print(stamp_print)
	return stamp.Set if stamp != null else ""

static func _pick_weighted(rng: RandomNumberGenerator, weights: Dictionary) -> String:
	var total: float = 0.0
	for weight in weights.values():
		total += float(weight)
	var roll: float = rng.randf() * total
	for key in weights.keys():
		roll -= float(weights[key])
		if roll <= 0.0:
			return str(key)
	return str(weights.keys().back())

static func _logistic(x: float) -> float:
	return 1.0 / (1.0 + exp(-x))
