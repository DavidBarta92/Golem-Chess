# StatBlock

Egy blokk 1–3 számlálóval — rang, érme, rajzpont —, amelyek a sztori során egyenként, ebben a sorrendben jelennek meg.

- Sorrend: a rang áll a menü mellett, az érme tőle balra, a rajzpont a blokk bal szélén. Minden új a blokk bal szélére érkezik; ami már látszik, nem mozdul.
- Ikon (`icon-stat`) + szám (`stat-number`, táblázatos számjegyek), köztük `space-2`; számlálók között `space-6`.
- Számformátum: négy jegyig egyben (`1000`), ötjegyűtől szóközzel tagolva (`12 400`).
- Változáskor a szám röviden felugrik, mellette „+50” úszik fel: érménél `coin-deep`, rajzpontnál `draw`, rangnál `ink`.
- Ne tegyél keretet vagy hátteret a blokk köré — a közök fogják össze.

A hívó adja: a látható számlálókat megjelenési sorrendben, és az értékeiket.
