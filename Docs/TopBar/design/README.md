A Golem felső sávja papír és tinta: krémszínű lap, sötét tintakontúr, szín csak ott, ahol jelent valamit. A sáv két részből áll — bal oldalon a képernyő saját gombjai, jobb oldalon egy fix csoport: **küldetésszalagok → számlálók → menü**. Ez a rendszer ennek a csoportnak a formáit, színeit, méreteit és mozgását rögzíti.

## Szöveg és hang

- Magyar felület, mondatkezdő nagybetűvel: „Beállítások”, „Csomagvásárlás”, „Új kódex”. Gombon egy-két szó.
- A küldetésleírás a kártyaleírások mintáját követi: dőlt alapszöveg (`quest-text`), benne a pontos feltétel félkövéren és állóan (`quest-key`):
  > *Aki háromszor áll fel, negyedszer is fel fog.* **Győzz le 3 ellenfelet** *többjátékos módban.*
- A cím rövid főnévi szerkezet: „Három párbaj”, „Bélyeggyűjtő”, „A nagypapa kódexe”.
- Számok: négy jegyig egyben (`1000`), ötjegyűtől szóközzel tagolva (`12 400`). Mértékegység nincs — az ikon mondja meg, mi a szám.
- Hátralévő idő: „még 17 ó 05 p”; egy óra alatt „még 48 perc”.
- Nincs felkiáltójel, nincs emoji.

## Színek

- `paper` a sáv, a gombok és a lenyíló háttere; `paper-deep` a jelenet a sáv alatt. `ink` minden szöveg, kontúr és ikonvonal; `ink-soft` a másodlagos szöveg.
- **A szalag vágása a feladat típusát, a színe a jutalmat jelzi.** A két szabály független, így minden kombináció egy pillantással olvasható.

| Szalag alja | Típus | Szín |
|---|---|---|
| Ferde vágás | Történet — teljesítve a sztori megy tovább | `story` (bordó), mindig |
| V-bevágás | Jutalom | `coin` (arany) vagy `draw` (tintakék) |
| Bástyafogak | Napi — 24 óra alatt kell teljesíteni | `coin` vagy `draw` |

- Minden feladat pontosan egyféle jutalmat ad, így a szalagnak mindig egy színe van — kétszínű szalag nincs.
- A szalag színe a számlálóé, amelyiket tölti: arany szalag → érme, kék szalag → rajzpont (a ceruzás kör is kék). A bordó csak a történeté — sehol máshol ne használd.
- A szín sosem áll egyedül: a szalagon mindig ott a jutalom ikonja (könyv, érme, ceruzás kör), a típust pedig a vágás mondja meg.
- Szalagon az ikon és a varrás `on-story` / `on-coin` / `on-draw`: bordón és kéken papír, aranyon tinta.
- `coin` csak kitöltés; érméhez kötött szöveg papíron `coin-deep` („+50”, JUTALOM kicker).
- `urgent` kizárólag a lejáróban lévő napi feladaté: homokóra jelvény és hátralévő idő.
- A küldetéspanel háttere `panel-from` → `panel-to` vízszintes átmenet — ugyanaz a fogás, mint a kártyaleírásoknál.

## Tipográfia

- Egy család, `ui`. A vázlatok Lexenddel készültek; ez helyettesítő, a játék saját betűtípusa kerüljön a helyére.
- `button-label` a szöveges gombokon, `stat-number` a számlálókon (táblázatos számjegyekkel, hogy változáskor ne ugráljon a szélesség), `menu-item` a lenyílóban, `caption` a haladás-, idő- és jutalomfeliratokhoz.
- Küldetéspanel: `quest-kicker` (nagybetűs típus), `quest-title`, `quest-text` + `quest-key`.

## A sáv elrendezése

- Magasság `bar-height`, háttér `paper`, oldalmargó `space-8`.
- **Bal zóna**: a főképernyőn a logó; alképernyőn a „Vissza” és közvetlenül utána az adott képernyő saját gombjai (pl. „Csomagvásárlás”). Ez a zóna zsugorodik, ha fogy a hely.
- **Jobb csoport**, jobbról balra: menü gomb → `space-6` → számlálók → `space-6` → szalagok. A csoport a jobb szélhez van rögzítve, így a szalagok mindig közvetlenül a számlálók mellett vannak, akárhány számláló látszik.
- Képernyőfüggő gomb soha ne kerüljön a jobb csoportba — a mostani csúszás (Csomagvásárlás a rang alatt) ebből jön.
- Megvalósítás: a számlálók és a szalagok konténere `flex-direction: row-reverse`, a DOM-ban megjelenési sorrendben vannak (a legrégebbi az első). Új elem = hozzáfűzés, és magától balra kerül.

## Számlálók

- Egy blokk 1–3 elemmel, ebben a sorrendben adagolja őket a sztori: **rang → érme → rajzpont**. Mindegyik a blokk bal szélén jelenik meg, a korábbiak a helyükön maradnak — a rang áll a menü mellett, a rajzpont a szalagok mellett.
- Ikon `icon-stat`, ikon és szám között `space-2`, számlálók között `space-6`. Nincs keret vagy háttér a blokk körül.
- Változáskor a szám röviden felugrik, mellette „+50” úszik fel a számláló színében (`coin-deep`, `draw`, rangnál `ink`).

## Küldetésszalagok

- Szélesség `ribbon-width`, nyugalmi hossz `ribbon-rest` a képernyő felső élétől — `space-4`-gyel lóg túl a sáv alján, mint egy könyvjelző a lapok közül. Szalagok között `space-2`.
- Vágásmélység: `tail-story`, `tail-reward`, `tail-daily` (a bástya fogai 6 / 5 / 6 / 5 / 6 px). Kontúr 1,5 px `ink` a két oldalon és a vágáson.
- **Sorrend**: a legrégebbi a jobb szélen, a számlálók mellett; minden új balra tőle érkezik, fentről leereszkedve. Ha egy szalag eltűnik (begyűjtötték vagy lejárt), a tőle balra lévők egy hellyel jobbra csúsznak; a jobbra lévők nem mozdulnak.
- A játék egyszerre legfeljebb 6 feladatot ad ki, így legfeljebb 6 szalag lóg. A sávnak nincs túlcsordulási állapota („+N” csonk, görgetés) — ezt a feladatkiosztás garantálja.
- Állapotok:
  - **alap** — a jutalom ikonja a szalag alján;
  - **hover** — `ribbon-lift`-tel lejjebb csúszik;
  - **folyamatban** — középen varrás fut le: a folytonos rész a haladás, a szaggatott a hátralévő;
  - **teljesítve** — az ikon helyén pecsét pipával, a szalag `ribbon-done-drop`-pal lejjebb lóg és lassan leng, amíg be nem gyűjtik;
  - **lejáróban** — napi feladatnál egy óra alatt `urgent` homokóra a szalag szélén;
  - **visszahúzva** — amíg egy másik szalag nyitva van, a többi a sáv aljáig húzódik vissza, hogy ne lógjon a panelbe.

## Küldetéspanel

- Kattintásra a szalag lecsúszik a panel aljáig, és jobbra mellette megjelenik a panel; a szalag maga a panel bal szegélye, mint a kártyaleírás tintacsíkja.
- Szélesség `panel-width`; a szöveg `panel-text` szélességen belül marad, hogy az átlátszatlan részre essen.
- Tartalom fentről: típus (`quest-kicker` kis szalagsziluettel; napinál mellette a hátralévő idő) → cím → leírás → haladás → jutalom. Teljesített feladatnál „Begyűjtés” (primary gomb).
- Haladás: 10 lépésig pöttyök (egy pötty = egy lépés), fölötte csík; mellette „2 / 3” `caption`-nel.
- Egyszerre egy panel lehet nyitva. Bezár: újra a szalagra kattintás, kattintás máshova, Esc. Ha jobbra nem fér ki, balra nyílik, az átmenet tükröződik.

## Menü

- Ikonos gomb a jobb szélen, a meglévő gombstílusban: `button-size` négyzet, `radius-md`, 1,5 px `ink` keret, `paper` kitöltés. Nyitva `ink` kitöltés, `paper` ikon.
- A lenyíló a gomb jobb széléhez igazodik: `menu-width`, `radius-lg`, `shadow-menu`; sorai `menu-row` magasak, `icon-menu` ikon + `menu-item` szöveg.
- Sorrend: Alpha Multiplayer (saját csoportban, „ideiglenes” címkével, hogy egy mozdulattal kivehető legyen) · Beállítások, Tutorial · Kilépés (külön, a lista alján).

## Mozgás

- Szalag le / fel (hover, nyitás, visszahúzódás): 240 ms, `cubic-bezier(.2,.8,.2,1)`.
- Panel: 200 ms áttűnés + 8 px csúszás, 90 ms késéssel, hogy a szalag induljon előbb.
- Új szalag: fentről ereszkedik enyhe túllendüléssel, 520 ms.
- Begyűjtés: kis rántás lefelé, aztán felhúzódik (420 ms). Lejárat: elszürkül, elhalványul, felhúzódik (620 ms).
- Helycsere (szalagok, számlálók): 280 ms csúszás.
- Teljesített szalag lengése: ±1,6°, 3 s ciklus.
- `prefers-reduced-motion` esetén nincs lengés, ereszkedés és csúszás — az állapotok azonnal váltanak.

## Ikonok

- Tintavonalas ikonok 24 px-es rácson, 1,75 px vonal, kerek végek; kitöltés csak jelentést hordozó színből (`coin`, `draw`).
- Méretek: számláló `icon-stat`, menü `icon-menu`, szalag `icon-ribbon`. Szalagon az ikon egyszínű, a szalag `on-…` színében.
- Az ikonok vázlatok. Az érme helyére a játék saját érmerajza kerüljön; a rang a meglévő dupla csúcsív.
- A Golem logó nincs a rendszerben: a vázlatokon sima szöveg helyettesíti.

## Fókusz és elérhetőség

- Minden gomb és szalag billentyűzettel elérhető; fókuszban `focus-ring` (2 px papír rés, 2 px tömör tinta).
- A szalag `button` elem `aria-expanded`-del, a címkéje „Típus: cím”; a panel ugyanezt a címkét kapja.
- Szöveg minden alapon legalább 4,5:1: `ink`, `ink-soft`, `story`, `coin-deep`, `draw`, `urgent` papíron; ikonok a szalagokon legalább 3:1.
