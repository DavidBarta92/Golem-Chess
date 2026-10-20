# Golem – Szabálykönyv

> Ez a szabálykönyv a játék forráskódja alapján készült. Ahol a játékon belüli bélyegleírások és a kód eltérnek, a kód tényleges viselkedését írjuk le.

## 1. Áttekintés

A Golem kétszemélyes, sakkszerű stratégiai játék. Mindkét játékos hat golemet irányít egy 7×7-es táblán. A golemek önmagukban mozdulatlan kőtömbök: mozogni csak akkor tudnak, ha **bélyeget** ragasztunk rájuk. A bélyeg adja a golem mozgásmintáját, és csak korlátozott számú lépésre elég – utána lejár, és a golem újra mozdulatlanná válik.

A bélyegek a játékos **kódexéből** származnak: ez egy 15 bélyegből álló, 5 oldalra osztott pakli, amelyből egyszerre mindig csak a nyitott oldal használható.

**A játék célja:** egy **Kereső** bélyeggel ellátott saját golemmel az ellenfél **bázismezőjére** lépni.

---

## 2. Játékelemek

### 2.1 A tábla

- 7×7 mező.
- **Alapsor:** a játékoshoz legközelebb eső sor. A fehér alapsora az 1., a feketéé a 7. sor.
- **Bázismező:** az alapsor középső (4.) mezője. Külön jelölt, kezdéskor üres. Mindkét játékosnak egy bázisa van.
- A bázismezőre bármelyik golem ráléphet, de:
  - újraéledő golem sosem kerül bázismezőre,
  - a tiltó és fagyasztó zónahatások nem érintik a bázismezőket.
- A bázis helye a játék folyamán bélyeghatással áthelyezhető (lásd 7.3). A győzelemhez mindig a bázis **aktuális** helyére kell lépni.

```
   1 2 3 4 5 6 7
7  ● ● ● ▣ ● ● ●   ← fekete alapsor, ▣ = fekete bázis
6  . . . . . . .
5  . . . . . . .
4  . . . . . . .
3  . . . . . . .
2  . . . . . . .
1  ○ ○ ○ ▢ ○ ○ ○   ← fehér alapsor, ▢ = fehér bázis
```

### 2.2 A golemek

- Játékosonként 6 golem; kezdéskor az alapsoron, a bázismező két oldalán állnak (1–3. és 5–7. oszlop).
- Minden golem egyforma. Csak a rá ragasztott bélyeg különbözteti meg őket: a bélyeg megváltoztatja a golem kinézetét, mozgását és képességeit.
- Egy golem állapotai:

| Állapot | Léphet? | Kaphat bélyeget? | Mikor |
|---|:---:|:---:|---|
| **Üres** | nem | igen | nincs rajta bélyeg (kezdéskor, lejárat vagy leütés után) |
| **Bélyeges** | igen | nem | van rajta érvényes bélyeg |
| **Kimerült** | nem | nem | ebben a körben kapott bélyeget – a kör végéig nem léphet |
| **Zárolt** | nem | nem | leütés után éledt újra; addig zárolt, amíg fel nem oldják (lásd 6.) |

Egy golemen egyszerre csak egy bélyeg lehet. A bélyeg nem vehető le és nem cserélhető: addig marad rajta, amíg le nem jár, vagy a golemet le nem ütik.

### 2.3 A bélyegek

Minden bélyegnek van:

- **neve és szettje** – Udvar (Courtyard), Állatok (Animals), Flóra (Flora), Égitestek (Celestials), Építmények (Structures), Archetípusok (Archetypes);
- **szerepe** – Egység, Kereső, Megosztott, Se-tenant vagy Overseal (lásd 5.4);
- **mozgásmintája** – egy 5×5-ös rács, a közepén a golemmel (lásd 5.1);
- **időtartama** – hány lépést tehet vele a golem (lásd 5.2);
- esetleg egy **hatása** és annak **kiváltója** (lásd 7.).

### 2.4 A kódex

- A kódex 15 bélyegből áll, amelyek **5 oldalra** oszlanak, oldalanként **3 bélyeggel**. Az oldalakat a pakli sorrendje határozza meg: az 1–3. bélyeg az 1. oldalra, a 4–6. a 2. oldalra kerül, és így tovább.
- Mindig pontosan **egy oldal van nyitva**. Csak a nyitott oldalon lévő bélyegek ragaszthatók fel – ez a játékos „keze”.
- **Nincs húzás.** A felragasztott bélyeg eltűnik az oldalról; az oldal nem töltődik újra (csak bizonyos hatások tehetnek rá bélyeget).
- Ha a nyitott oldal kiürül, a játékos következő körének kezdetén a kódex automatikusan a **következő nem üres oldalra** lapoz. Az üres oldalak kikerülnek a forgásból.
- A saját kódex tartalma a játékos számára végig ismert. Az ellenfél nyitott oldalának bélyegei **lefordítva** látszanak – csak a darabszámuk és a kódexében maradt bélyegek száma ismert.

---

## 3. Győzelem és vereség

A játékban nincs döntetlen. A meccs a következő módokon érhet véget:

1. **Bázis elérése** – ha egy játékos **Kereső** bélyeget viselő, **saját színű** golemje az ellenfél bázismezőjére lép, azonnal nyer. (Nem Kereső golem bázisra lépése nem jelent semmit.)
2. **Nincs szabályos akció** – ha egy játékosnak a köre kezdetén nincs egyetlen szabályos akciója sem, azonnal veszít. Akciónak számít:
   - szabályos lépés egy golemmel,
   - bélyeg felragasztása (van üres, nem zárolt golem és van bélyeg a nyitott oldalon),
   - lapozás,
   - a „Kör vége” használata kimerült vagy lefagyasztott golem miatt (lásd 4.3).

   Az első körben elég, ha a játékos tud bélyeget felragasztani vagy lapozni.
3. **Lejárt óra** – ha egy játékos sakkórája 00:00-ra ér, veszít (lásd 9.).
4. **Kilépés** – csak többjátékos módban: ha egy játékos meccs közben kilép vagy megszakad a kapcsolata, az ellenfele azonnal nyer.

---

## 4. A kör menete

A fehér kezd. A játékosok felváltva jönnek; egy körben mindig egy játékos cselekszik.

### 4.1 Az első kör

Az első körben (mindkét játékos legelső körében) a golemeknek még nincs bélyege, ezért lépni nem lehet. Az első kör szabályai:

1. Opcionálisan **lapozhatsz** egyszer (csak felragasztás előtt).
2. **Legalább egy bélyeget fel kell ragasztanod** egy golemedre.
3. Ha felragasztottál legalább egyet, a **Kör vége** gombbal befejezheted a köröd.
4. Ha a nyitott oldal **mindhárom** bélyegét felragasztod, a kör **automatikusan** véget ér.

### 4.2 A további körök

A második körtől a kör kötött sorrendű, három fázisból áll:

1. **Lapozás (opcionális)** – egyszer lapozhatsz a kódex következő nem üres oldalára. Csak akkor lehetséges, ha ebben a körben még nem ragasztottál fel bélyeget, és legalább két nem üres oldal van a kódexben. A lapozás mindig előrefelé, körkörösen történik.
2. **Felragasztás (opcionális, akárhány)** – a nyitott oldalról tetszőleges számú bélyeget felragaszthatsz üres, nem zárolt golemjeidre (egy golemre egyet). A bélyeget kapó golem ebben a körben **kimerült**: nem léphet.
3. **Lépés (kötelező)** – léphetsz **egy** léphető golemeddel. A lépés végrehajtása **azonnal lezárja a kört**.

A kör tehát mindig a lépéssel ér véget. Lapozni és bélyeget felragasztani csak a lépés előtt lehet.

### 4.3 A „Kör vége” gomb

A második körtől a lépés kötelező, ezért a „Kör vége” gomb csak kivételes helyzetben használható: ha **nincs szabályos lépésed**, de

- van olyan bélyeges golemed, amely ebben a körben kapott bélyeget (kimerült), vagy
- van olyan golemed, amely léphetne, de **lefagyasztott mezőn** áll.

Ilyenkor a gombbal passzolhatsz. Tipp: ha nincs lépésed, de van felragasztható bélyeged, ragaszd fel – a kimerült golem miatt a gomb elérhetővé válik.

Ha nincs lépésed, nincs kimerült vagy lefagyasztott golemed, nem tudsz felragasztani és lapozni sem – veszítettél (lásd 3.).

### 4.4 Mi történik a kör végén

1. A tábla zónahatásai (tiltott/lefagyasztott mezők) és a golemek védőhatásai (láthatatlan, nem üthető) egy kör-lépéssel öregednek (lásd 7.4).
2. A körét befejező játékos kimerült golemjei felszabadulnak (a zároltak nem).
3. A másik játékos következik. Ha az ő nyitott oldala üres, a kódexe automatikusan a következő nem üres oldalra lapoz.
4. A rendszer ellenőrzi, hogy a soron következő játékosnak van-e szabályos akciója; ha nincs, veszít.

---

## 5. A bélyegek részletesen

### 5.1 Mozgásminta

A bélyeg mozgásmintája egy 5×5-ös rács, amelynek közepén a golem áll. A minta a **golem tulajdonosának szemszögéből** értendő: a rács **felső sora van előre** (az ellenfél felé). A fekete játékos mintái ennek megfelelően 180°-kal elfordítva érvényesek.

A rács minden mezője a következők egyike:

| Jel | Jelentés |
|:---:|---|
| `X` | **lépés vagy ütés** – üres mezőre lehet lépni, ellenséges golemet le lehet ütni |
| `m` | **csak lépés** – csak üres mezőre |
| `c` | **csak ütés** – csak ellenséges golemre |
| `.` | nem elérhető |

Fontos tulajdonságok:

- A minta közvetlenül a **célmezőket** adja meg; nem vonalak mentén mozgás, ezért a köztes mezők tartalma nem számít (a golem „átugorja” őket).
- A tábla szélén kívülre eső célmezők egyszerűen kiesnek.
- Saját golemre nem lehet lépni.
- **Tiltott** mezőre nem lehet lépni (lásd 7.3).
- **Lefagyasztott** mezőn álló golem egyáltalán nem léphet.
- **Nem üthető** golemet nem lehet leütni, még `X` vagy `c` mezőről sem.

Példa – Lándzsa (Lance): előre egy vagy két mezőt léphet vagy üthet, hátra egyet.

```
. . X . .
. . X . .
. . @ . .
. . X . .
. . . . .
```

### 5.2 Időtartam

- Az időtartam azt mutatja, hány **lépést** tehet a golem a bélyeggel.
- Az időtartam **csak akkor csökken eggyel, ha az adott golem lép**. Más golem lépése, a körök múlása, a felragasztás vagy a hatások kiváltása nem fogyasztja.
- Egyes hatások módosíthatják az időtartamot (+1 / −1, lásd 7.3).
- A −1 időtartam „végtelent” jelent: az ilyen bélyeg sosem jár le. (A jelenlegi bélyegkészletben nincs ilyen.)

### 5.3 Lejárat

Ha az időtartam 0-ra csökken, a bélyeg **lejár**:

- A bélyeg lekerül a golemről; a golem újra **üres** lesz (nem léphet, de új bélyeget kaphat).
- A lejáró bélyeg **lejáratkor** kiváltódó hatása (ha van) érvényesül.
- A nem Kereső bélyeg **végleg** kikerül a játékból – nem kerül vissza a kódexbe.
- A **Kereső** bélyeg visszakerül a kódexbe, pontosan arra az oldalra és helyre, ahonnan felragasztották (lásd 5.4).

Ha a lejárat lépés miatt történik, az a lépés még teljes értékű (a golem odalép, üt, kiváltja a „lépéskor” hatását), és csak utána jár le a bélyeg.

### 5.4 Bélyegszerepek

| Szerep | Szabály |
|---|---|
| **Egység (Unit)** | Alap bélyeg, nincs külön szabálya. |
| **Kereső (Seeker)** | Csak Kereső golemmel lehet nyerni (bázisra lépéssel). Ha a Kereső bélyeg lejár, vagy a golemet leütik (akár bomba által), a bélyeg **visszakerül a kódexbe** az eredeti oldalára és helyére, így később újra felragasztható. A kódexnek tartalmaznia kell legalább egy Keresőt. |
| **Megosztott (Shared)** | A bélyeges golemet **mindkét játékos** irányíthatja a saját körében. A minta és az ütés az éppen irányító játékos szemszögéből értendő (a mintát az ő „előre” iránya szerint kell olvasni, és az ő színétől eltérő golemeket ütheti). A golem színe nem változik: csak a tulajdonosa nyerhet vele, és a tulajdonos alapsorára éled újra. |
| **Se-tenant** | Jelenleg csak a bélyeg keretében különbözik; külön játékszabálya nincs. |
| **Overseal** | Jelenleg csak a bélyeg keretében különbözik; külön játékszabálya nincs. |

---

## 6. Ütés és újraéledés

Ütés akkor történik, ha egy golem `X` vagy `c` mezőről ellenséges golemre lép. A leütött golem **nem tűnik el végleg**, hanem újraéled – de a bélyegét elveszíti.

### 6.1 Mi történik a leütött golemmel

1. A leütött golem bélyegének **„ha leütik”** hatása (ha van) kiváltódik – még mielőtt a golem lekerülne a tábláról.
2. A leütött golem elveszíti a bélyegét. A nem Kereső bélyeg végleg elvész; a **Kereső** bélyeg visszakerül a tulajdonosa kódexébe.
3. Az ütő golem a célmezőre lép; kiváltódik az **„ha üt”** hatása (ha van).
4. A leütött golem újraéled az alábbi szabályok szerint.

### 6.2 Újraéledés és zárolás

- Ha a leütött golem tulajdonosának **nincs zárolt golemje**: a golem visszakerül a saját **alapsorának egy véletlenszerű üres, nem bázis mezőjére**, **zárolt** állapotban. A zárolt golem nem léphet és nem kaphat bélyeget.
- A zárolás **nem oldódik fel magától** a körök múlásával. Csak akkor oldódik fel, ha ugyanannak a játékosnak **egy másik golemjét is leütik**.
- Ha a leütött golem tulajdonosának **már van zárolt golemje**: a zárolt golem azonnal **felszabadul**, az újonnan leütött golem viszont **végleg kikerül a játékból**.

Ezért minden második ütés ténylegesen csökkenti az ellenfél golemjeinek számát:

| Ütések száma az adott játékos ellen | Golemjei a táblán | Ebből zárolt |
|:---:|:---:|:---:|
| 0 | 6 | 0 |
| 1 | 6 | 1 |
| 2 | 5 | 0 |
| 3 | 5 | 1 |
| 4 | 4 | 0 |

- Ha az alapsoron nincs üres, nem bázis mező, a golem **várólistára** kerül, és amint felszabadul egy mező, ugyanezekkel a szabályokkal (zárolva) megjelenik. A várólistán lévő golem is „zárolt golemnek” számít a fenti szabály szempontjából.

### 6.3 Ütés hatás által

A **bomba** hatás által eltávolított golemek (saját és ellenséges egyaránt) ugyanúgy leütöttnek számítanak: bélyegüket elveszítik (a Kereső visszakerül a kódexbe), és a fenti újraéledési szabályok vonatkoznak rájuk. A bomba a **nem üthető** golemeket is eltávolítja.

---

## 7. Bélyeghatások

Egyes bélyegeknek hatásuk van, amely egy adott **kiváltó** eseménykor érvényesül. Egy bélyegnek legfeljebb egy hatása és egy kiváltója van.

### 7.1 Kiváltók

| Kiváltó | Mikor érvényesül |
|---|---|
| **Felragasztáskor** | amint a bélyeg a golemre kerül |
| **Lépéskor** | minden alkalommal, amikor a golem lép (az időtartam csökkenése előtt; a bélyeg utolsó lépésénél is) |
| **Ha üt** | amikor a golem leüt egy ellenséges golemet (a lépés után) |
| **Ha leütik** | amikor a golemet leütik (mielőtt lekerülne a tábláról) |
| **Lejáratkor** | amikor a bélyeg időtartama 0-ra csökken – lépés vagy időtartam-csökkentő hatás miatt |
| **Szimbólumszámra** | felragasztáskor, ha a játékosnak legalább 3 azonos szimbólumú bélyeges golemje van a táblán (a jelenlegi bélyegkészletben nincs ilyen bélyeg) |

Különleges eset: ha egy „ha leütik” hatás (pl. bomba) eltávolítja az **ütő** golemet is, az ütés nem jön létre – az ütő golem nem lép el a helyéről –, de a kör így is véget ér.

### 7.2 Hatásmezők

Több hatás egy 5×5-ös **hatásmintát** használ, amely ugyanúgy értendő, mint a mozgásminta: a golem a közepén áll, a felső sor van előre, a fekete játékosnál 180°-kal elfordítva. A táblán kívülre eső mezők kiesnek.

### 7.3 Hatástípusok

| Hatás | Leírás |
|---|---|
| **Bélyeglopás** (steal_stamp) | Egy véletlenszerű bélyeg az ellenfél nyitott oldaláról (beállítástól függően a kódexe többi oldaláról) a saját nyitott oldaladra kerül. Ha a nyitott oldalad tele van (3 bélyeg), az ellopott bélyeg megsemmisül. |
| **Előhívás** (grant_stamp) | Egy megnevezett bélyeget (alapértelmezésben a hatást kiváltó bélyeg saját nevével egyezőt) a kódexed egy **másik**, nem nyitott oldaláról a nyitott oldalra tesz. Ha nincs ilyen bélyeg a többi oldalon, nem történik semmi; ha a nyitott oldal tele van, a bélyeg elvész. |
| **Átadás** (give_stamp) | Egy véletlenszerű bélyeg a saját nyitott oldaladról az ellenfél nyitott oldalára kerül. Ha az ellenfél oldala tele van, a bélyeg megsemmisül. |
| **Bázis áthelyezése** (move_base) | A saját bázisod a hatásminta (első) jelölt mezőjére kerül. Nem kerülhet a táblán kívülre, sem az ellenfél bázisára – ilyenkor nem történik semmi. Az ellenfélnek ezután az új helyre kell eljutnia a Keresőjével. |
| **Tiltott mezők** (invalid_squares) | A jelölt mezőkre 3 kör-lépésig **senki nem léphet** (sem lépéssel, sem ütéssel). A rajtuk álló golemek maradhatnak és elléphetnek. Bázismező nem tiltható. |
| **Lefagyasztás** (frozen_squares) | A jelölt mezőkön álló golemek 3 kör-lépésig **nem léphetnek** (a saját golemjeid sem, ha ott állnak). A lefagyasztott mezőre lépni lehet – aki odalép, az is lefagy. Bázismező nem fagyasztható. |
| **Bomba** (bomb) | A jelölt mezőkön álló **minden golem** – saját és ellenséges egyaránt – leütöttnek számít (lásd 6.3). |
| **Láthatatlan** (invisible_to_enemy) | 3 kör-lépésig az ellenfél nem látja a golemet: sem a helyét, sem a bélyegét, sem a lépését. A golem attól még a táblán van, és leüthető, ha az ellenfél a mezőjére lép. |
| **Nem üthető** (uncapturable) | 3 kör-lépésig a golemet nem lehet lépéssel leütni. A bomba ellen nem véd. |
| **+1 saját időtartam** (increase_own_durations) | Minden bélyeges golemed időtartama 1-gyel nő. |
| **+1 ellenséges időtartam** (increase_enemy_durations) | Az ellenfél minden bélyeges golemjének időtartama 1-gyel nő. |
| **−1 saját időtartam** (decrease_own_durations) | Minden bélyeges golemed időtartama 1-gyel csökken. Ami 0-ra ér, lejár (a Kereső visszakerül a kódexbe). |
| **−1 ellenséges időtartam** (decrease_enemy_durations) | Az ellenfél minden bélyeges golemjének időtartama 1-gyel csökken; ami 0-ra ér, lejár. |
| **+1 saját bélyeg** (increase_self_duration) | Csak ennek a bélyegnek az időtartama nő 1-gyel. |

Az időtartam-módosítók a végtelen (−1) időtartamú bélyegeket nem érintik.

### 7.4 Az időzített hatások élettartama

A tiltott és lefagyasztott mezők, valamint a láthatatlan és nem üthető védelem mindig pontosan **3 kör-lépésig** tart, a bélyeg időtartamától függetlenül. A számláló minden kör végén csökken, kivéve a létrehozás körének végét. A hatás tehát érvényes:

1. a létrehozó játékos aktuális körének hátralévő részében,
2. az ellenfél következő körében,
3. a létrehozó játékos következő körében,
4. az ellenfél azt követő körében,

és a létrehozó játékos harmadik körének kezdetére megszűnik. Ha a golem elveszíti a bélyegét (lejárat, leütés), a rajta lévő védelem is azonnal megszűnik; a tábla-zónák viszont a létrehozó golem sorsától függetlenül kitartanak.

### 7.5 Feloldási sorrend egy lépésnél

Haladó játékosoknak – egy lépés eseményei ebben a sorrendben történnek:

1. A leütendő golem **„ha leütik”** hatása.
2. A leütött golem Kereső bélyege visszakerül a kódexbe.
3. Az ütő golem a célmezőre kerül.
4. Az ütő golem **„ha üt”** hatása.
5. A leütött golem elveszíti a bélyegét és újraéled (zárolás / feloldás).
6. **Győzelem-ellenőrzés:** ha a lépő golem Kereső, és az ellenfél bázisán áll, a játék véget ér.
7. A lépő golem **„lépéskor”** hatása.
8. Az időtartam eggyel csökken; ha 0, a bélyeg lejár és a **„lejáratkor”** hatás kiváltódik.
9. A kör véget ér.

---

## 8. Kódex- és pakliépítési szabályok

- Egy kódex **pontosan 15 bélyegből** áll.
- Minden bélyegből legfeljebb **2 példány** lehet a kódexben.
- A kódexnek legalább **egy Kereső** bélyeget kell tartalmaznia.
- Csak a gyűjteményben meglévő bélyegek használhatók.
- A bélyegek sorrendje számít: ez határozza meg, mi kerül az egyes oldalakra (1–3 → 1. oldal, 4–6 → 2. oldal, …, 13–15 → 5. oldal).

A kezdőpakli („Nagyapa kódexe”) sorrendben: Lance, Archer, Monk / Silver General, War Drummer, Berserk / Gold General, Warlord, Knight / The Golem, Lance, Berserk / Silver General, Archer, Monk.

---

## 9. Óra

- Minden meccsen – egyjátékos, történet és többjátékos módban is – mindkét játékosnak **10 perc** áll rendelkezésére a **teljes meccsre** (sakkóra).
- Az óra csak a saját köröd alatt fut.
- Ha az órád 00:00-ra ér, azonnal veszítesz.
- Kivétel: a történet legelső főnökmeccsei óra nélkül zajlanak.

---

## 10. Játékmódok röviden

| Mód | Jellemzők |
|---|---|
| **Egyjátékos** | Meccs a gépi ellenfél ellen, 1–12 közötti nehézségi szinttel. A játékos fehérrel játszik és kezd. 10 perces sakkóra játékosonként. Győzelemért 5 pont jár. |
| **Történet** | Egymást követő főnökök saját, előre megírt kódexekkel. Győzelemmel nyílik a folytatás; vereség után ugyanaz a meccs újrajátszható. |
| **Többjátékos** | Két emberi játékos (saját szerver vagy Steam). A színeket a rendszer véletlenszerűen osztja ki; a fehér kezd. 10 perces sakkóra játékosonként. Aki kilép, veszít. Győzelemért nem jár pont. |
| **Oktató** | Lépésről lépésre vezetett meccs, amely a fenti szabályokat mutatja be. |
| **Gyűjtemény** | Csomagok vásárlása pontokért (egy csomag 4 bélyeget ad), kódexek szerkesztése a 8. pont szabályai szerint. |

---

## 11. Gyors összefoglaló

1. 7×7 tábla, 6–6 golem az alapsoron, a bázis az alapsor közepe.
2. A golem csak bélyeggel léphet; a bélyeg adja a mintát és az időtartamot.
3. Kódex: 15 bélyeg, 5 oldal × 3; csak a nyitott oldal használható; nincs húzás.
4. Első kör: legalább egy bélyeg felragasztása, majd Kör vége (3 felragasztás után automatikus).
5. Későbbi körök: (lapozás) → (felragasztás) → **lépés, ami kötelező és lezárja a kört**.
6. A most bélyegzett golem a körben kimerült. Kör vége gomb csak akkor, ha nincs lépés, de van kimerült vagy lefagyasztott golem.
7. Lépésenként −1 időtartam; 0-nál a bélyeg lejár (a Kereső visszakerül a kódexbe, a többi elvész).
8. A leütött golem zárolva éled újra az alapsoron; a következő leütés feloldja, de az az újabb golem végleg elvész.
9. Győzelem: Kereső golem az ellenfél bázisán. Vereség: nincs akció a kör elején, vagy lejárt óra.

## Függelék – Bélyeglista

A lista a játékban jelenleg engedélyezett és csomagból/történetből elérhető bélyegeket tartalmazza, szettenként. A minták a golem szemszögéből értendők: a **felső sor van előre** (az ellenfél felé), a rács közepén (`@`) áll a golem.

Jelmagyarázat – mozgás: `X` lépés vagy ütés · `m` csak lépés (üres mezőre) · `c` csak ütés · `.` nem elérhető. Hatásmező: `#`.


### Udvar (Courtyard)

| Bélyeg | Szerep | Időtartam | Mozgásminta | Hatás |
|---|---|:---:|---|---|
| **Archer ★** | Egység | 1 | <code>..c..<br>.c.c.<br>c.@.c<br>.c.c.<br>..c..</code> | – |
| **Assassin ★** | Egység | 2 | <code>.....<br>ccccc<br>..@..<br>ccccc<br>.....</code> | *felragasztáskor:* Láthatatlan: az ellenfél 3 kör-lépésig nem látja ezt a golemet |
| **Berserk ★** | Egység | 1 | <code>..X..<br>.X.X.<br>..@..<br>.X.X.<br>..X..</code> | *ha üt:* +1 időtartam erre a bélyegre |
| **Duke ★** | Egység | 1 | <code>.X.X.<br>..X..<br>X.@.X<br>..X..<br>.X.X.</code> | – |
| **Gold General ★** | Egység | 1 | <code>X...X<br>.XXX.<br>.X@X.<br>..X..<br>.....</code> | – |
| **Knight ★** | Egység | 4 | <code>.X.X.<br>X...X<br>..@..<br>X...X<br>.X.X.</code> | – |
| **Lance ★** | Egység | 2 | <code>..X..<br>..X..<br>..@..<br>..X..<br>.....</code> | – |
| **Prince ★** | Kereső | 1 | <code>.....<br>.m.m.<br>..@..<br>.m.m.<br>.....</code> | *felragasztáskor:* Láthatatlan: az ellenfél 3 kör-lépésig nem látja ezt a golemet |
| **Silver General ★** | Egység | 3 | <code>c...c<br>.ccc.<br>.m@m.<br>..m..<br>.....</code> | – |
| **The Golem ★** | Egység | 2 | <code>.....<br>..X..<br>.X@X.<br>..X..<br>.....</code> | *ha üt:* +1 időtartam erre a bélyegre |
| **War Drummer ★** | Egység | 4 | <code>.....<br>.m.m.<br>..@..<br>.m.m.<br>.....</code> | *felragasztáskor:* +1 időtartam minden bélyeges golemedre |
| **Warlord ★** | Egység | 1 | <code>.X.X.<br>X...X<br>..@..<br>.....<br>.....</code> | *lépéskor:* +1 időtartam minden bélyeges golemedre |

### Állatok (Animals)

| Bélyeg | Szerep | Időtartam | Mozgásminta | Hatás |
|---|---|:---:|---|---|
| **Bear** | Egység | 3 | <code>X...X<br>..X..<br>..@..<br>..m..<br>m...m</code> | *ha üt:* −1 időtartam minden bélyeges golemedre |
| **Blackbird** | Egység | 2 | <code>m.m.m<br>.....<br>m.@.m<br>.....<br>m.m.m</code> | – |
| **Cat** | Kereső | 3 | <code>X...X<br>.X.X.<br>..@..<br>..m..<br>.....</code> | – |
| **Crocodile** | Egység | 3 | <code>.....<br>.cXc.<br>.c@c.<br>..m..<br>.....</code> | *ha üt:* −1 időtartam minden bélyeges golemedre |
| **Dog** | Egység | 4 | <code>X...X<br>.ccc.<br>..@..<br>..m..<br>.....</code> | – |
| **Dragon** | Egység | 2 | <code>.....<br>.X.X.<br>.X@X.<br>.X.X.<br>.....</code> | – |
| **Dragonhorse** | Egység | 2 | <code>.m.m.<br>mc.cm<br>.c@c.<br>mc.cm<br>.m.m.</code> | – |
| **Duck** | Megosztott | 4 | <code>mmmmm<br>mmmmm<br>mm@mm<br>mmmmm<br>mmmmm</code> | – |
| **Elephant** | Egység | 4 | <code>X...X<br>.....<br>..@..<br>.....<br>X...X</code> | – |
| **Fox** | Egység | 2 | <code>.X.X.<br>.....<br>..@..<br>.....<br>.X.X.</code> | – |
| **Goat** | Egység | 2 | <code>...X.<br>.X...<br>..@.m<br>.m...<br>.....</code> | – |
| **Heron** | Egység | 2 | <code>.m.m.<br>..m..<br>.m@m.<br>..m..<br>.m.m.</code> | – |
| **Horse** | Egység | 2 | <code>.m.m.<br>m...m<br>..@..<br>m...m<br>.m.m.</code> | – |
| **Rhinoceros** | Egység | 2 | <code>.ccc.<br>.XXX.<br>.m@m.<br>.mmm.<br>.....</code> | – |
| **Turtle** | Kereső | 2 | <code>.....<br>.mmm.<br>.m@m.<br>.mmm.<br>.....</code> | – |

### Flóra (Flora)

| Bélyeg | Szerep | Időtartam | Mozgásminta | Hatás |
|---|---|:---:|---|---|
| **Baobab** | Egység | 3 | <code>.....<br>.mmm.<br>.m@m.<br>.mmm.<br>.....</code> | – |
| **Cactus** | Kereső | 6 | <code>.....<br>.ccc.<br>.c@c.<br>.ccc.<br>.....</code> | – |
| **Chanterelle** | Overseal | 2 | <code>m.m.m<br>.....<br>..@..<br>.....<br>m...m</code> | – |
| **Cherry tree** | Egység | 3 | <code>.....<br>.mXm.<br>.m@m.<br>.mmm.<br>.....</code> | – |
| **Fly agaric** | Egység | 3 | <code>..m..<br>.c.c.<br>m.@.m<br>.c.c.<br>..m..</code> | – |
| **Larch** | Egység | 3 | <code>.....<br>.mmm.<br>.m@m.<br>.mmm.<br>.....</code> | – |
| **Lotus** | Egység | 4 | <code>.....<br>.mmm.<br>.m@m.<br>.mmm.<br>.....</code> | *felragasztáskor:* Előhívás: a(z) **Lotus** bélyeget a kódexed egy másik oldaláról a nyitott oldalra teszi |
| **Magnolia** | Egység | 1 | <code>..m..<br>m...m<br>..@..<br>m...m<br>..m..</code> | – |
| **Oak** | Egység | 3 | <code>.....<br>.mmm.<br>.m@m.<br>.mmm.<br>.....</code> | – |
| **Olive tree** | Egység | 3 | <code>.....<br>.mmm.<br>.m@m.<br>.mmm.<br>.....</code> | – |
| **Orchid** | Egység | 1 | <code>.X.X.<br>.m.m.<br>..@..<br>.m.m.<br>.X.X.</code> | – |
| **Rose** | Egység | 1 | <code>m.m.m<br>.X.X.<br>m.@.m<br>.X.X.<br>m.m.m</code> | – |
| **Shaggy mane** | Overseal | 3 | <code>m...m<br>.m.m.<br>..@..<br>.m.m.<br>m...m</code> | – |
| **Yellow coral** | Overseal | 3 | <code>m...m<br>.X.X.<br>..@..<br>.m.m.<br>.....</code> | – |

### Égitestek (Celestials)

| Bélyeg | Szerep | Időtartam | Mozgásminta | Hatás |
|---|---|:---:|---|---|
| **Black Hole** | Overseal | 8 | <code>.....<br>.XXX.<br>.X@X.<br>.XXX.<br>.....</code> | *lépéskor:* −1 időtartam minden bélyeges golemedre |
| **Comet** | Egység | 5 | <code>.....<br>..X..<br>.X@X.<br>..X..<br>.....</code> | – |
| **Earth** | Se-tenant | 5 | <code>.....<br>..X..<br>.X@X.<br>..X..<br>.....</code> | – |
| **Jupiter** | Egység | 5 | <code>.....<br>..X..<br>.X@X.<br>..X..<br>.....</code> | – |
| **Mars** | Egység | 5 | <code>.....<br>..X..<br>.X@X.<br>..X..<br>.....</code> | – |
| **Mercury** | Egység | 5 | <code>.....<br>..X..<br>.X@X.<br>..X..<br>.....</code> | – |
| **Moon** | Se-tenant | 5 | <code>.....<br>..X..<br>.X@X.<br>..X..<br>.....</code> | – |
| **Nebula** | Egység | 5 | <code>.....<br>..X..<br>.X@X.<br>..X..<br>.....</code> | – |
| **Neptune** | Egység | 5 | <code>.....<br>..X..<br>.X@X.<br>..X..<br>.....</code> | – |
| **North Star** | Egység | 5 | <code>.....<br>..X..<br>.X@X.<br>..X..<br>.....</code> | – |
| **Nova** | Egység | 2 | <code>.....<br>..m..<br>.m@m.<br>..m..<br>.....</code> | *lejáratkor:* Bomba: a jelölt mezőkön álló minden golem (saját is!) leütöttnek számít <code>.###.<br>#####<br>##.##<br>#####<br>.###.</code> |
| **Saturn** | Egység | 5 | <code>.....<br>..X..<br>.X@X.<br>..X..<br>.....</code> | – |
| **Sun** | Se-tenant | 5 | <code>.....<br>..X..<br>.X@X.<br>..X..<br>.....</code> | – |
| **Uranus** | Egység | 5 | <code>.....<br>..X..<br>.X@X.<br>..X..<br>.....</code> | – |
| **Venus** | Egység | 5 | <code>.....<br>..X..<br>.X@X.<br>..X..<br>.....</code> | – |

### Építmények (Structures)

| Bélyeg | Szerep | Időtartam | Mozgásminta | Hatás |
|---|---|:---:|---|---|
| **Ballista** | Egység | 3 | <code>..X..<br>..X..<br>mm@mm<br>..m..<br>..m..</code> | – |
| **Bastion** | Egység | 3 | <code>..X..<br>..X..<br>mm@mm<br>..m..<br>..m..</code> | – |
| **Bicycle** | Egység | 3 | <code>..X..<br>..X..<br>mm@mm<br>..m..<br>..m..</code> | – |
| **Bombard** | Egység | 3 | <code>..X..<br>..X..<br>mm@mm<br>..m..<br>..m..</code> | – |
| **Castle** | Egység | 3 | <code>..X..<br>..X..<br>mm@mm<br>..m..<br>..m..</code> | – |
| **Citadel** | Egység | 3 | <code>..X..<br>..X..<br>mm@mm<br>..m..<br>..m..</code> | – |
| **Fortress** | Egység | 3 | <code>..X..<br>..X..<br>mm@mm<br>..m..<br>..m..</code> | – |
| **Gate** | Egység | 3 | <code>..X..<br>..X..<br>mm@mm<br>..m..<br>..m..</code> | – |
| **Mantlet** | Egység | 3 | <code>.....<br>..m..<br>.m@m.<br>..m..<br>.....</code> | *lépéskor:* Tiltott mezők: a jelölt mezőkre 3 kör-lépésig nem lehet lépni <code>.....<br>#####<br>.....<br>.....<br>.....</code> |
| **Shrine** | Egység | 3 | <code>..X..<br>..X..<br>mm@mm<br>..m..<br>..m..</code> | – |
| **Temple** | Egység | 3 | <code>..X..<br>..X..<br>mm@mm<br>..m..<br>..m..</code> | – |
| **Tortoise** | Egység | 3 | <code>..X..<br>..X..<br>mm@mm<br>..m..<br>..m..</code> | *felragasztáskor:* Tiltott mezők: a jelölt mezőkre 3 kör-lépésig nem lehet lépni |
| **Tower** | Egység | 3 | <code>..X..<br>..X..<br>mm@mm<br>..m..<br>..m..</code> | – |
| **Trebuchet** | Egység | 3 | <code>..X..<br>..X..<br>mm@mm<br>..m..<br>..m..</code> | – |
| **War Chariot** | Egység | 3 | <code>..X..<br>..X..<br>mm@mm<br>..m..<br>..m..</code> | – |

### Archetípusok (Archetypes)

| Bélyeg | Szerep | Időtartam | Mozgásminta | Hatás |
|---|---|:---:|---|---|
| **Adventurer** | Egység | 3 | <code>.....<br>.ccc.<br>.c@X.<br>.XXX.<br>.....</code> | – |
| **Advocate** | Egység | 3 | <code>.....<br>.XcX.<br>.c@X.<br>.cXc.<br>.....</code> | *lejáratkor:* Előhívás: a(z) **King** bélyeget a kódexed egy másik oldaláról a nyitott oldalra teszi |
| **Architect** | Egység | 3 | <code>.....<br>.XcX.<br>.X@c.<br>.cXc.<br>.....</code> | *lejáratkor:* Átadás: egy véletlen bélyeg a nyitott oldaladról az ellenfél nyitott oldalára kerül |
| **Bishop** | Egység | 3 | <code>X...X<br>.X.X.<br>..@..<br>.X.X.<br>X...X</code> | – |
| **Campaigner** | Egység | 3 | <code>.....<br>.cXX.<br>.c@X.<br>.ccX.<br>.....</code> | – |
| **Commander** | Egység | 3 | <code>.....<br>.XXX.<br>.X@c.<br>.ccc.<br>.....</code> | – |
| **Consul** | Egység | 3 | <code>.....<br>.XXc.<br>.c@X.<br>.Xcc.<br>.....</code> | – |
| **Defender** | Egység | 3 | <code>.....<br>.Xcc.<br>.c@X.<br>.XXc.<br>.....</code> | – |
| **Entertainer** | Egység | 3 | <code>.....<br>.cXc.<br>.c@X.<br>.XcX.<br>.....</code> | – |
| **Entrepreneur** | Egység | 3 | <code>.....<br>.cXc.<br>.X@c.<br>.XcX.<br>.....</code> | – |
| **Executive** | Egység | 3 | <code>.....<br>.XXc.<br>.X@c.<br>.Xcc.<br>.....</code> | – |
| **Logician** | Egység | 3 | <code>.....<br>.ccX.<br>.X@c.<br>.cXX.<br>.....</code> | *ha üt:* Előhívás: a(z) **King** bélyeget a kódexed egy másik oldaláról a nyitott oldalra teszi |
| **Logistician** | Egység | 3 | <code>.....<br>.Xcc.<br>.X@c.<br>.XXc.<br>.....</code> | – |
| **Mediator** | Egység | 3 | <code>.....<br>.ccX.<br>.c@X.<br>.cXX.<br>.....</code> | – |
| **Numero_1** | Egység | 2 | <code>.mmm.<br>.....<br>..@..<br>.....<br>.mmm.</code> | – |
| **Numero_2** | Egység | 2 | <code>.....<br>..c..<br>mm@mm<br>..c..<br>.....</code> | – |
| **Numero_3** | Kereső | 3 | <code>.....<br>..m..<br>.m@m.<br>..m..<br>.....</code> | *lépéskor:* Tiltott mezők: a jelölt mezőkre 3 kör-lépésig nem lehet lépni <code>#####<br>.....<br>.....<br>.....<br>.....</code> |
| **Numero_4** | Egység | 1 | <code>.....<br>..c..<br>.c@c.<br>..c..<br>.....</code> | *lépéskor:* Láthatatlan: az ellenfél 3 kör-lépésig nem látja ezt a golemet |
| **Numero_5** | Egység | 2 | <code>.....<br>ccXcc<br>..@..<br>..m..<br>.....</code> | *lépéskor:* Lefagyasztás: a jelölt mezőkön álló golemek 3 kör-lépésig nem léphetnek <code>.....<br>####.<br>.....<br>.....<br>.....</code> |
| **Numero_6** | Egység | 2 | <code>m.m.m<br>.....<br>m.@.m<br>.....<br>m.m.m</code> | *lépéskor:* Nem üthető: ezt a golemet 3 kör-lépésig nem lehet leütni |
| **Numero_7** | Egység | 2 | <code>..m..<br>.....<br>.m@m.<br>.....<br>..m..</code> | – |
| **Protagonist** | Egység | 3 | <code>.....<br>.XXX.<br>.c@X.<br>.ccc.<br>.....</code> | – |
| **Virtuoso** | Egység | 3 | <code>.....<br>.ccc.<br>.X@c.<br>.XXX.<br>.....</code> | – |

★ = a kezdőpakli („Nagyapa kódexe”) része.
