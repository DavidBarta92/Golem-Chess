# QuestRibbon

Könyvjelzőszalag egy aktív feladathoz: a vágása a típust, a színe a jutalmat mondja meg.

| Vágás | Típus | Szín |
|---|---|---|
| Ferde (`tail-story`) | Történet | `story` |
| V-bevágás (`tail-reward`) | Jutalom | `coin` vagy `draw` |
| Bástyafogak (`tail-daily`) | Napi, 24 óra | `coin` vagy `draw` |

- Méret: `ribbon-width` × `ribbon-rest`, a képernyő felső élétől lóg; 1,5 px `ink` kontúr a két oldalon és a vágáson, felül nincs kontúr.
- Alján a jutalom ikonja (`icon-ribbon`, egyszínű): könyv, érme vagy ceruzás kör, a szalag `on-…` színében.
- **Folyamatban**: középen varrás fut le — a folytonos rész a kész arány, a szaggatott a hátralévő. Egylépéses feladatnál nincs varrás.
- **Teljesítve**: az ikon helyén papír pecsét pipával; a szalag `ribbon-done-drop`-pal lejjebb lóg és lassan leng, amíg be nem gyűjtik.
- **Lejáróban** (napi, < 1 óra): `urgent` homokóra jelvény a szalag jobb szélén.
- **Hover**: `ribbon-lift`. **Visszahúzva**: ha másik szalag nyitva van, a sáv aljáig húzódik vissza.
- Minden feladat egyféle jutalmat ad, ezért a szalag mindig egyszínű.
- Ne színezd a történet-szalagot másra, és ne használd a bordót más jelentésre.

A hívó adja: típus, jutalom, cím, haladás (`now` / `target`), teljesítve-e, lejáróban-e.
