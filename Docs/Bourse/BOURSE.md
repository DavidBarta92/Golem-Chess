# The Bourse

The Bourse (Börze) is a stamp market with two sides, both on `Scenes/Bourse.tscn`:

- **My lots.** The player puts five of their free copies on a lot and names a
  price. Every two hours a made-up buyer comes and may take a lot. The buyer
  draws one of its five stamps at random. Collecting the lot pays the price,
  takes the drawn stamp out of the collection and gives the other four back.
- **Today's lots.** Four made-up sellers bring a lot of five each day. The
  player pays a lot's price and picks one stamp blind: the five are shuffled
  face down, and the card the player clicks is the stamp they get.

The player never sees a stamp's value or a lot's total. They see how much the
buyers want a lot while they build it (0–5 bars) and, once it is up, its
chance at the next buyer.

| | |
| --- | --- |
| `Scripts/Bourse/BourseStore.gd` | autoload `BourseStore`: the lots, the visits, the day's market, the picks; saves `user://bourse.json` |
| `Scripts/Bourse/BourseMarket.gd` | the numbers: market value, the buyers, sale chance, prices, the game's lots |
| `Scripts/Bourse/BourseScreen.gd` | the screen and its four views |
| `Scripts/Bourse/BourseUi.gd` | the pieces the screen builds from: stamp cells, the lot sheet, pills, bars |
| `Scripts/Bourse/BourseSaleNotice.gd` | the main menu's notice of a sale |
| `Scripts/TopBar/SaleRibbon.gd` | the top bar's notice of a sale, where the price is collected too |

The story's `trade` feature opens the screen. The id stayed `trade`, so older
saves are still valid.

## Free copies

The Bourse brought a rule that holds across the game: **a copy is in one place
at a time.** A codex slot holds a copy of its own, and so does a stamp on a
lot. Everywhere a count is shown (the collection album, the Bourse's album) it
is the **free** copies: owned, minus those in codexes, minus those on lots.

- `PlayerCollectionStore.get_free_count_for_print_id(print_id, ignore_deck_id)`
  works it out. The codex being edited passes its own id, so the copies on its
  pages count as its own.
- `get_copy_locations(print_id)` says where the taken copies are. The album
  shows it on hover ("Flora 1: 2 · Bourse: 1").
- The album draws an owned stamp with no free copy in colour but faded, with
  "0 pcs" under it.
- The codex editor only takes a stamp with a free copy. Dragging one in lowers
  the count, and taking one out raises it again.
- Counting is per print. Two basic Dukes are interchangeable, so there are no
  per-copy ids. The rule only decides how many of a print are taken.

**The switch to this rule.** Before it, a codex only had to own a stamp, so one
Duke could sit in eleven codexes. The first load under the rule gives every
codex the copies it lacks (`settle_codex_copies`), once. The flag
`codex_copies_settled` in `player_collection.json` records that. On the
author's save this added 10 copies. After that, copies are never handed out
for a codex again, with two exceptions:

- the starting codex on a first run;
- Grandpa's codex in its reward scene.

When a deleted starting codex is put back on a later load, it comes only if
its copies are free.

## What a stamp is worth

    market value = estimated_value × rarity factor
    rarity factor = (basic chance / the print's chance) ^ 0.3

`estimated_value` is the stamp's strength in play
([STAMP_VALUE.md](../Balance/STAMP_VALUE.md)). The rarity factor adds the
collector's price. The odds come from PackDefinition's defaults (foil 10 %,
full art 2 %), which gives foil ≈ 1.92 and full art ≈ 3.11. The exponent
keeps it well under the raw scarcity (8.8× and 44×).

## The buyers

A buyer draws at random, so what a lot is worth to them depends on how its
value is spread, not only on its total. Each buyer weighs a lot by:

    CE_α = ( mean of value^α ) ^ (1/α)

- Below 1, α makes the weak stamps count most, because those are what the
  buyer will most likely draw.
- Above 1, the best stamp counts most.

Three kinds of buyer come: cautious (α 0.6, 40 %), even (α 1, 40 %) and
gamblers (α 1.8, 20 %). A lot of one prize and four fillers has about the same
mean as five middling stamps, but finds different buyers:

| price (of a fair 17) | one prize, four fillers | five middling |
| --- | --- | --- |
| 15 | 50 % | 60 % |
| 18 | 28 % | 26 % |
| 20 | 19 % | 13 % |

The chance a lot sells at one visit:

    chance = 0.8 × Σ share × σ( (CE_α × sell rate / price − 1) / 0.1 )

The screen shows exactly this number, since the kind of buyer is part of the
roll. The 0.8 cap means that even a lot given away waits for a buyer. The
builder's bars are `round(chance / 0.8 × 5)`.

## Coins

Coins were made ten times finer for the Bourse:

- A win pays 50 (`WIN_POINTS_PER_WIN`).
- A booster costs 150 (`PACK_COST`, `PackDefinition.price`). The set packs'
  placeholder price of 1 was raised to 150 with it.
- The story's coin rewards are 30 / 300 / 300.
- A save from before has its coins multiplied once on load. The
  `coin_scale` key in `player_progress.json` records it.

All Bourse rates hang on the booster:

    booster's points  = 4 × mean basic value of the market × mean rarity factor   (≈ 85)
    booster rate      = 150 / booster's points                                    (≈ 1.76 coins a point)
    sell rate         = 0.5  × booster rate     what buyers pay for the player's stamps
    buy rate          = 1.75 × booster rate     what the game asks for its own

- Selling is cheaper than a booster, so buying boosters to sell their stamps
  loses coins.
- Buying a chosen stamp costs more per point than a blind booster, but a
  single stamp still costs less than a booster.
- No lot costs more than 80 % of a booster (`max_price`, 120).
- The gap between the two rates is where coins leave the game.

A lot of five average stamps sells for about 17 coins, the price the builder
suggests. A game lot of average stamps costs about 60.

## The game's lots

At local midnight `BourseStore` makes four lots
(`BourseMarket.generate_lot`). Each comes from one of these kinds:

| kind | share | what is in it |
| --- | --- | --- |
| bargain | 20 % | five from the cheaper half |
| even | 25 % | five from the middle |
| jackpot | 25 % | one from the top 15 % or a foil / full art, four from the cheaper half |
| set | 20 % | five of one set |
| collector | 10 % | two foils or full arts, three of anything |

The stamps come from what the packs on sale can drop. In 60 % of the lots one
stamp is swapped for one the player does not have yet. Two lots of the same
day never bring the same new stamp: a player who lacked only Puffball found it
in every lot until that rule. The price is `CE(α 1.3) × buy rate × a random
0.8–1.25`, rounded to 5. So the game's lots are not free money, and now and
then one is a bargain.

The sellers and the buyers are made like the random story opponents
(`RandomOpponentFactory.create_person`). Their names are kept as parts and
ordered by the game's language: "Kovács Anna" in Hungarian, "Anna Kovács" in
English. The face comes from `portrait_seed`.

## Time and saves

- A visit every 2 hours (`VISIT_SECONDS`). The first one is due two hours after
  the first load.
- Visits missed while the game was closed are run on the next load or check, up
  to 12 of them.
- A timer checks every 20 s on any screen.
- A lot listed after a visit's time is not rolled at that visit.
- **The order of the writes** always favours the player if the game stops
  midway:
  - A pick saves its shuffled order before the coins go, so leaving or
    crashing cannot draw again.
  - The picked stamp is added before the pick is marked done.
  - Collecting removes the lot first, then the sold copy, then pays.

## The screen

- The top bar has a row of its own: Back, My lots, Bourse
  (`GlobalTopBar.show_bourse` and `set_bourse_tab`). The open tab is pressed in
  ink. The pick view shows Back alone.
- Back goes up one level: from the builder to My lots, from a pick to the
  market, otherwise to the main menu.
- The builder's album shows owned prints of one set. "Free only" (on by
  default) hides those with no free copy. A click adds a copy to the lot, and a
  click on the lot's stamp takes it off.
- The price follows the stamps until the player changes it. Holding − or +
  repeats.
- A sale while the screen is open shows at once. The view is read when the
  refresh runs, not when the store changed: paying for a pick changes the
  store and opens the pick in the same frame.
- The main menu's notice ("Kovács Anna picked from your lot: Duke") shows
  while sales are unseen and the `trade` feature is open. Opening the Bourse
  marks them seen; collecting the sale from the top bar takes it off too.
- **The top bar's notice.** Each sold lot also hangs in the top bar, among the
  quest ribbons, until it is collected: a gold ribbon like a coin quest's,
  with a rounded foot. Clicking it opens a panel like a done quest's: the
  buyer, the stamp they took, the price and Claim, which settles the lot as
  the screen's Collect does. Its look and behaviour are in
  [HANDOFF.md](../TopBar/HANDOFF.md) (Sale notices).

## Tuning

Every number is a constant at the top of `BourseMarket.gd` (rates, buyers,
rarity, the game's lots) and `BourseStore.gd` (slots, visit time, catch-up,
lots a day). The coin amounts are in `PlayerProgressStore.gd`, the packs'
`price` and the reward scenes' `grant_points`.

## Testing

The main menu's developer window (A three times, in a debug build) has a
Bourse section for the top bar's notices:

- **+ Sold lot (spare copies)** lists five copies at the builder's price and
  sells the lot at once (`BourseStore.sell_lot_now`). It is a real sale:
  collecting it pays the price and takes the drawn stamp out of the
  collection, so the copies come from the prints with the most free copies,
  never a print's last free one.
- **Sell my oldest listed lot**: a buyer for a lot of the player's at once.
- **Unlock Bourse**: the story's `trade` feature, without which no notice
  shows. Sales made before it come down when it is unlocked.

Run the store and the screen with `APPDATA` pointed at a scratch folder holding
a copy of the save, as the other harnesses do. The first load under the
free-copy rule changes `player_collection.json`, and the first load under the
coin scale changes `player_progress.json`. A run on the real save would do
both for good.
