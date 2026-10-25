# QuestQueue

A szalagok sorrendje és mozgása: a legrégebbi a jobb szélen, minden új balra tőle érkezik.

- Érkezés: az új szalag a sor bal végére kerül, fentről ereszkedik le enyhe túllendüléssel (520 ms). A többi nem mozdul.
- Eltűnés: begyűjtéskor egy kis rántás lefelé, aztán felhúzódik (420 ms); lejáratkor elszürkül, elhalványul és felhúzódik (620 ms). Utána a **tőle balra lévők** egy hellyel jobbra csúsznak (280 ms); a jobbra lévők a helyükön maradnak.
- Új számláló megjelenésekor a teljes szalagsor balra csúszik ugyanígy — mindig közvetlenül a számlálók mellett marad.
- A játék egyszerre legfeljebb 6 feladatot ad ki; a sávnak nincs túlcsordulási állapota. A bemutatóban 6 szalagnál a hozzáadó gombok letiltódnak.
- Megvalósítás: a DOM-ban korsorrend, a konténer `row-reverse`; a csúszás FLIP — mérés a változás előtt és után, a különbség `translateX`-ként visszajátszva.
