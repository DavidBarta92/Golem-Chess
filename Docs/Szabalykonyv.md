# Golem – Szabálykönyv

> Ez a szabálykönyv a játék forráskódja alapján készült. Ahol a játékon belüli bélyegleírások és a kód eltérnek, a kód tényleges viselkedését írjuk le.

## 1. Áttekintés

A Golem kétszemélyes, sakkszerű stratégiai játék. Mindkét játékos hat golemet irányít egy 7×7-es táblán. A golemek önmagukban mozdulatlan kőtömbök: mozogni csak akkor tudnak, ha **bélyeget** ragasztunk rájuk. A bélyeg adja a golem mozgásmintáját, és csak korlátozott számú lépésre elég – utána lejár, és a golem újra mozdulatlanná válik.

A bélyegek a játékos **kódexéből** származnak: ez egy 15 bélyegből álló, 5 oldalra osztott pakli, amelyből egyszerre mindig csak a nyitott oldal használható.

**A játék célja:** egy **megkoronázott** saját golemmel az ellenfél **bázismezőjére** lépni. A koronát a körönként gyűlő koronapontokból lehet feltenni (lásd 2.5).

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
| **Bélyeges** | igen | csak Overseal-t | van rajta érvényes bélyeg |
| **Kimerült** | nem | ugyanúgy, mint máskor (üresen bármit, bélyegesen csak Overseal-t) | ebben a körben kapott bélyeget vagy koronát – a kör végéig nem léphet |
| **Zárolt** | nem | nem | leütés után éledt újra; addig zárolt, amíg fel nem oldják (lásd 6.) |

Egy golemen egyszerre csak egy bélyeg lehet. A bélyeg nem vehető le és nem cserélhető: addig marad rajta, amíg le nem jár, a golemet le nem ütik, vagy egy **Overseal** bélyeg le nem takarja (lásd 5.4).

### 2.3 A bélyegek

Minden bélyegnek van:

- **neve és szettje** – Udvar (Courtyard), Állatok (Animals), Flóra (Flora), Égitestek (Celestials), Építmények (Structures), Archetípusok (Archetypes), lásd 5.5;
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

### 2.5 A korona

- Mindkét játékosnak van egy **koronamérője**, amely mindkét játékos számára látható.
- A mérő minden **saját kör elején** egy pontot kap – akkor is, ha a játékos koronája a táblán van. A mérő legfeljebb **6 pontig** telik.
- A **második** játékos (a fekete) **1 pont előnnyel** indul, így ugyanabban a körszámban telik meg a mérője, mint a kezdő játékosé – ez ellensúlyozza a kezdés előnyét.
- Ha a mérő megtelt, a játékos a köre **felragasztási fázisában**, lépés előtt **felteheti a koronát** bármelyik saját golemjére: üresre vagy bélyegesre, a tábla bármely mezőjén – csak zárolt golemre nem. A koronázás:
  - az összes pontot elhasználja (a mérő 0-ra áll, és onnan töltődik tovább),
  - a megkoronázott golemet **kimeríti** erre a körre (nem léphet, de ha üres, még kaphat bélyeget),
  - lezárja a lapozást: koronázás után ebben a körben már nem lehet lapozni.
- Körönként legfeljebb **egyszer** lehet koronázni.
- Egyszerre legfeljebb **egy** saját korona lehet a táblán. Ha a mérő újra megtelik, miközben a korona a táblán van, a korona ugyanígy **áthelyezhető** egy másik saját golemre: a régiről lekerül, az új golem kimerül, és a mérő ismét 0-ra áll. Ez a kiút, ha a megkoronázott golem elakadt.
- A korona a **golemhez** tartozik, nem a bélyeghez: ha a golem bélyege lejár, a korona rajta marad.
- Ha a megkoronázott golemet **leütik** (akár bomba által), a korona visszakerül a tulajdonosához, és a mérő **0-ról** kezd újra töltődni.
- Ha a megkoronázott golem **láthatatlan**, a koronája sem látszik az ellenfél számára. A mérő viszont mindig látható.
- Bélyeghatások is adhatnak vagy elvehetnek koronapontot (lásd 7.3), és a **Se-tenant** bélyegek teli állapotban tarthatják a mérőt (lásd 5.4).

---

## 3. Győzelem és vereség

A játékban nincs döntetlen. A meccs a következő módokon érhet véget:

1. **Bázis elérése** – ha egy játékos **megkoronázott**, **saját színű** golemje az ellenfél bázismezőjére lép, azonnal nyer. (Korona nélküli golem bázisra lépése nem jelent semmit. A bázison megkoronázott golemnek le kell lépnie, majd vissza.)
2. **Nincs szabályos akció** – ha egy játékosnak a köre kezdetén nincs egyetlen szabályos akciója sem, azonnal veszít. Akciónak számít:
   - szabályos lépés egy golemmel,
   - bélyeg felragasztása (van üres, nem zárolt golem és van bélyeg a nyitott oldalon, vagy van Overseal bélyeg a nyitott oldalon és nem zárolt golem),
   - lapozás,
   - a korona feltétele (ha megtelt a mérő),
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

1. **Lapozás (opcionális)** – egyszer lapozhatsz a kódex következő nem üres oldalára. Csak akkor lehetséges, ha ebben a körben még nem ragasztottál fel bélyeget és nem koronáztál, és legalább két nem üres oldal van a kódexben. A lapozás mindig előrefelé, körkörösen történik.
2. **Felragasztás (opcionális, akárhány)** – a nyitott oldalról tetszőleges számú bélyeget felragaszthatsz üres, nem zárolt golemjeidre (egy golemre egyet). **Overseal** bélyeget bélyeges golemre is ragaszthatsz, ez letakarja a régit (lásd 5.4). A bélyeget kapó golem ebben a körben **kimerült**: nem léphet. Ebben a fázisban teheted fel a **koronát** is, ha megtelt a mérőd (lásd 2.5).
3. **Lépés (kötelező)** – léphetsz **egy** léphető golemeddel. A lépés végrehajtása **azonnal lezárja a kört**.

A kör tehát mindig a lépéssel ér véget. Lapozni és bélyeget felragasztani csak a lépés előtt lehet.

### 4.3 A „Kör vége” gomb

A második körtől a lépés kötelező, ezért a „Kör vége” gomb csak kivételes helyzetben használható: ha **nincs szabályos lépésed**, de

- van olyan golemed, amely ebben a körben kapott bélyeget vagy koronát (kimerült), vagy
- van olyan golemed, amely léphetne, de **lefagyasztott mezőn** áll.

Ilyenkor a gombbal passzolhatsz. Tipp: ha nincs lépésed, de van felragasztható bélyeged, ragaszd fel – a kimerült golem miatt a gomb elérhetővé válik.

Ha nincs lépésed, nincs kimerült vagy lefagyasztott golemed, nem tudsz felragasztani és lapozni sem – veszítettél (lásd 3.).

### 4.4 Mi történik a kör végén

1. A tábla zónahatásai (tiltott/lefagyasztott mezők) és a golemek védőhatásai (láthatatlan, nem üthető) egy kör-lépéssel öregednek (lásd 7.4).
2. A körét befejező játékos kimerült golemjei felszabadulnak (a zároltak nem).
3. Akinek a körben megszakadt a **Se-tenant** sora, annak a mérője 0-ra áll (lásd 5.4).
4. A másik játékos következik, és kap egy koronapontot. Ha az ő nyitott oldala üres, a kódexe automatikusan a következő nem üres oldalra lapoz.
5. A rendszer ellenőrzi, hogy a soron következő játékosnak van-e szabályos akciója; ha nincs, veszít.

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

Ha a lejárat lépés miatt történik, az a lépés még teljes értékű (a golem odalép, üt, vagy ha nem üt, kiváltja a „lépéskor” hatását), és csak utána jár le a bélyeg.

### 5.4 Bélyegszerepek

| Szerep | Szabály |
|---|---|
| **Egység (Unit)** | Alap bélyeg, nincs külön szabálya. |
| **Kereső (Seeker)** | Ha a Kereső bélyeg lejár, vagy a golemet leütik (akár bomba által), a bélyeg **visszakerül a kódexbe** az eredeti oldalára és helyére, így később újra felragasztható. A győzelemhez nincs köze: nyerni a koronával lehet (lásd 2.5). |
| **Megosztott (Shared)** | A bélyeges golemet **mindkét játékos** irányíthatja a saját körében. A minta és az ütés az éppen irányító játékos szemszögéből értendő (a mintát az ő „előre” iránya szerint kell olvasni, és az ő színétől eltérő golemeket ütheti). A golem színe nem változik: csak a tulajdonosa nyerhet vele, és a tulajdonos alapsorára éled újra. |
| **Se-tenant** | Ha egyszerre legalább **3** saját golemeden Se-tenant bélyeg van (a „sor”), a koronamérőd **mindig tele van**: koronázás után azonnal újratelik, és a −1 ellenséges koronapont sem csökkenti. Koronázni így is körönként egyszer lehet. Ha a sor megszakad, mert egy Se-tenant bélyeget leütnek, lejár vagy egy Overseal letakarja, és 3 alá csökken a számuk, a mérő **0-ra esik**, és onnan körönként töltődik tovább. (Egy bélyegből 2 példány is lehet a kódexben: 4 Se-tenant golemből egy elvesztése még nem szakítja meg a sort.) |
| **Overseal** | **Bármelyik saját**, nem zárolt golemre felragasztható, akkor is, ha már van rajta bélyeg – ellenséges golemre nem. A letakart bélyeg **hatás nélkül elvész** (a „lejáratkor” hatása sem sül el), kivéve a **Kereső** bélyeget, amely visszakerül a kódexbe az eredeti oldalára és helyére. A golem koronája megmarad, és az Overseal bélyeg teljes időtartamával indul. |

### 5.5 A szettek karaktere

A hat szett hat különböző játékstílust ad. Egy szett karakterét három tengely és a saját hatáscsaládjai határozzák meg:

- **ütés** – mennyi ütőmezője (`X` és `c`) van egy bélyegnek;
- **távolság** – a minta a golem melletti mezőkön (belső gyűrű) vagy két mezőre (külső gyűrű) dolgozik;
- **élettartam** – hány lépésig tart egy bélyeg.

A tengelyek a szett egészét írják le, nem minden egyes bélyegét. Egy „kevés ütés” szettben is lehet 1–2 erősen ütő bélyeg: ezek a szett szándékos kivételei.

| Szett | Ütés | Távolság | Élettartam | Játékstílus |
|---|---|---|---|---|
| **Udvar** | sok | messze | rövid | gyors, közvetlen támadás |
| **Építmények** | sok | közel | hosszú | lassan előrenyomuló erőd |
| **Archetípusok** | sok | közel | rövid | hatásokból épített láncok |
| **Állatok** | kevés | messze | rövid | kitérő portyázás |
| **Flóra** | kevés | közel | hosszú | az ellenfél kifárasztása |
| **Égitestek** | kevés | messze | hosszú | idő és korona |

A szettek jelenlegi átlagai (viszonyítási alap új bélyegekhez, nem kötelező érték):

| Szett | Ütőmező bélyegenként | Külső gyűrű a mezők között | Átlagos időtartam |
|---|:---:|:---:|:---:|
| **Udvar** | 4,9 | 43% | 1,5 |
| **Építmények** | 3,8 | 24% | 2,7 |
| **Archetípusok** | 4,0 | 0% | 2,1 |
| **Állatok** | 2,9 | 55% | 2,0 |
| **Flóra** | 2,5 | 6% | 2,9 |
| **Égitestek** | 3,1 | 56% | 3,1 |

#### Udvar (Courtyard) – a katonák

Tempóval nyer: korán nyomást gyakorol, és nem hagy időt az ellenfélnek. Bélyegei erősek, de gyorsan lejárnak, ezért a szett a saját idejét is húzza.

- **Mozgás:** ugrások és vonalak a külső gyűrűig, főleg `X` mezőkkel.
- **Élettartam:** főleg 1–2 lépés.
- **Hatáscsalád:** morál, vagyis +1 időtartam a saját bélyegeknek. Minden kiváltóra másik bélyeg jut: felragasztáskor War Drummer, ütéskor Warlord, leütéskor Skirmisher, koronázáskor The Golem. A Berserk csak önmagát hosszabbítja. Kiegészítésként láthatatlanság: Prince, Assassin.
- **Szerepek:** itt van a legtöbb Kereső (3).
- **Új bélyeg:** rövid élet, sok `X`, messzire érő minta. Hatásként morált kapjon, vagy maradjon hatás nélküli erős harcos.

#### Építmények (Structures) – az erődítmény

Lassan, zárt alakzatban nyomul előre. Ami a közelébe kerül, azt leüti, és a terepet is a maga javára alakítja.

- **Mozgás:** belső gyűrű, sok `c` mezővel: a fal lecsap, de nem mozdul ki a helyéről.
- **Élettartam:** hosszú, főleg 3 lépés.
- **Hatáscsalád:** terep és védelem. Tiltott mezők (Tortoise, Mantlet, War Chariot), nem üthető (Fortress).
- **Kivételek:** a két ostromgép, a Trebuchet és a Ballista messzire lő, de ott csak `c` mezői vannak. A Bicycle Se-tenant bélyeg: messzire ugrik, és koronapontot ad.
- **Új bélyeg:** belső gyűrű, `c` mezők, hosszú élet, terep- vagy védelmi hatás. Külső gyűrűt csak ostromgép kapjon, és ott csak `c` mezőt.

#### Archetípusok (Archetypes) – a szerepek

Egy-egy bélyeg önmagában nem kiemelkedő, a hatások láncolata viszi a játékot. Ez a szett gazdálkodik a legjobban a kódexével: pótolja a felhasznált bélyegeit, és elveszi az ellenfélét.

- **Mozgás:** minden bélyeg a teljes belső gyűrűt fedi, 4 `c` és 4 `m` mezővel, különböző forgatásban. Külső gyűrűt egyik sem használ.
- **Élettartam:** rövid, főleg 2 lépés.
- **Hatáscsalád:** kódex-gazdálkodás. Előhívás (Advocate, Architect, Consul, Logician), bélyeglopás (Entertainer, Protagonist, Virtuoso). A bélyegek szinte mindegyikének van hatása.
- **Új bélyeg:** a 4 `c` + 4 `m` belső gyűrű új forgatása, és mindenképpen legyen hatása.

#### Állatok (Animals) – a portyázók

Nem szemtől szemben harcol, hanem megkerüli az ellenfelet, és a koronát viszi be, mielőtt utolérnék.

- **Mozgás:** ugrások és távoli átlók, főleg `m` mezőkkel. Ütni leginkább előre tud.
- **Élettartam:** rövid, főleg 2 lépés.
- **Hatáscsalád:** kitérés. Láthatatlanság (Fox, Crocodile, Cat), nem üthető (Horse, Dragon, Goat).
- **Kivételek:** a Dragon, a Dragonhorse és a Rhinoceros erősen üt.
- **Új bélyeg:** ugró, messzire érő minta kevés ütőmezővel, rövid élet, és olyan hatás, amely megvédi a golemet.

#### Flóra (Flora) – a kert

Lassan terjed, keveset üt, és kivárja, hogy az ellenfél kifogyjon a lehetőségekből. Gyakran úgy nyer, hogy az ellenfélnek nem marad szabályos akciója. Ha pedig elindul a koronával, azt lassan, de biztosan célba viszi.

- **Mozgás:** belső gyűrű, főleg `m` mezőkkel.
- **Élettartam:** hosszú, főleg 3 lépés. A Lotus rövid életű kivétel.
- **Hatáscsalád:** csali, koronafojtás és kitartó koronavivők. Leütéskor robbanó gombák (Fly agaric, Puffball), koronapont elvétele (Lotus, Orchid), a bázis áthelyezése (Oak). A koronát a Cherry tree és a Rose viszi célba: az első nem fogy el, amíg csak lép, a második lépés után nem üthető.
- **Szerepek:** itt van a legtöbb Overseal (5), ezek a gombák. Egy lejáró vagy rossz helyen álló bélyeget bármikor lecserélnek.
- **Kivételek:** a Magnolia és az Orchid messzire is ér, a Cactus körben üt.
- **Új bélyeg:** közeli `m` minta, hosszú élet, és olyan hatás, amely lassítja vagy kifárasztja az ellenfelet, vagy kitartóvá teszi a koronavivőt.

#### Égitestek (Celestials) – a pályák és az idő

Hosszú távra tervez: az időt és a koronát irányítja. Keveset üt, de korán koronát szerez, és az ellenfél bélyegeit is rövidíti.

- **Mozgás:** a tengelyeken két mezőnyire lévő „pályapontokra” ugrik, kevés mezővel.
- **Élettartam:** hosszú, főleg 3 lépés.
- **Hatáscsalád:** idő (Black Hole, Saturn, Comet, Venus), lefagyasztás (Neptune, Mercury), korona (Sun, North Star), kozmikus robbanások (Jupiter, Nova). A koronát a Mercury viszi célba: megkoronázásakor lefagyasztja a szomszédos mezőket, aztán ugrással elhagyja őket.
- **Szerepek:** a Se-tenant sor itt van otthon (Sun, Moon, Earth).
- **Kivételek:** a Black Hole és a Mars közelharcos, 8 ütőmezővel. A Black Hole minden lépése a saját bélyegek idejéből megy.
- **Új bélyeg:** kevés, tengelyen fekvő távoli mező, hosszú élet, idő- vagy koronahatás.

#### Szabályok új bélyeg tervezéséhez

1. A három tengelyből legalább kettőn illeszkedjen a szetthez. Az eltérés legyen szándékos, és szettenként csak 1–2 ilyen kivétel legyen.
2. A mozgásminta ne legyen mezőre pontosan azonos egy másik szett bélyegével. Szetten belül lehet közös a forma.
3. A hatás a szett saját hatáscsaládjából jöjjön. Ha másik szett hatását kölcsönzi, más kiváltóval tegye.

---

## 6. Ütés és újraéledés

Ütés akkor történik, ha egy golem `X` vagy `c` mezőről ellenséges golemre lép. A leütött golem **nem tűnik el végleg**, hanem újraéled – de a bélyegét elveszíti.

### 6.1 Mi történik a leütött golemmel

1. Az ütő golem a célmezőre lép, a leütött golem lekerül a tábláról.
2. A leütött golem bélyegének **„ha leütik”** hatása (ha van) kiváltódik – már az ütő golemmel a mezőjén, így az ottani mezőt is jelölő bomba az ütő golemet is leüti (lásd 7.1).
3. Kiváltódik az ütő golem **„ha üt”** hatása (ha van).
4. A leütött golem elveszíti a bélyegét. A nem Kereső bélyeg végleg elvész; a **Kereső** bélyeg visszakerül a tulajdonosa kódexébe. Ha a golemen **korona** volt, az is lekerül, és a tulajdonos mérője 0-ról kezd újra töltődni.
5. A leütött golem újraéled az alábbi szabályok szerint.

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

A **bomba** hatás által eltávolított golemek (saját és ellenséges egyaránt) ugyanúgy leütöttnek számítanak: bélyegüket és koronájukat elveszítik (a Kereső visszakerül a kódexbe), és a fenti újraéledési szabályok vonatkoznak rájuk. A bomba a **nem üthető** golemeket is eltávolítja. A bomba által leütött golem előbb lekerül a tábláról, és csak utána sül el a saját „ha leütik” hatása: egy újabb bomba így láncreakciót indíthat, de ugyanazt a golemet nem találja el kétszer.

---

## 7. Bélyeghatások

Egyes bélyegeknek hatásuk van, amely egy adott **kiváltó** eseménykor érvényesül. Egy bélyegnek legfeljebb egy hatása és egy kiváltója van.

### 7.1 Kiváltók

| Kiváltó | Mikor érvényesül |
|---|---|
| **Felragasztáskor** | amint a bélyeg a golemre kerül |
| **Lépéskor** | minden alkalommal, amikor a golem lép, kivéve ha a lépéssel üt (az időtartam csökkenése előtt; a bélyeg utolsó lépésénél is) |
| **Ha üt** | amikor a golem leüt egy ellenséges golemet (a lépés után) |
| **Ha leütik** | amikor a golemet leütik – lépéssel leütve azután, hogy az ütő golem a mezőjére lépett |
| **Lejáratkor** | amikor a bélyeg időtartama 0-ra csökken – lépés vagy időtartam-csökkentő hatás miatt |
| **Szimbólumszámra** | felragasztáskor, ha a játékosnak legalább 3 azonos szimbólumú bélyeges golemje van a táblán (a jelenlegi bélyegkészletben nincs ilyen bélyeg) |
| **Korona-feltétel** | egyszer, abban a pillanatban, amikor a bélyeges golemre felkerül a korona – feltételkor vagy áthelyezéskor. Ha a bélyeget egy már megkoronázott golemre ragasztják, nem sül el. |

Különleges eset: ha egy „ha leütik” hatás (pl. a leütött golem mezejét is jelölő bomba) az **ütő** golemet is leüti, a lépésnek nincs további következménye – sem „ha üt”, sem „lépéskor” hatás, a megkoronázott ütő golem a bázisra lépve sem nyer –, és a kör véget ér.

### 7.2 Hatásmezők

Több hatás egy 5×5-ös **hatásmintát** használ, amely ugyanúgy értendő, mint a mozgásminta: a golem a közepén áll, a felső sor van előre, a fekete játékosnál 180°-kal elfordítva. A táblán kívülre eső mezők kiesnek.

### 7.3 Hatástípusok

| Hatás | Leírás |
|---|---|
| **Bélyeglopás** (steal_stamp) | Egy véletlenszerű bélyeg az ellenfél nyitott oldaláról (beállítástól függően a kódexe többi oldaláról) a saját nyitott oldaladra kerül. Ha a nyitott oldalad tele van (3 bélyeg), az ellopott bélyeg megsemmisül. |
| **Előhívás** (grant_stamp) | A megnevezett bélyeg egy **új példányát** ragasztja a kódexedbe (a bélyeget a hatás beállítása adja meg; ha nincs megadva, a hatást kiváltó bélyeg maga). A legközelebbi üres helyre kerül: ha a nyitott oldalon van üres hely, oda (így rögtön kijátszható), különben a következő oldalak közül lapozási sorrendben az elsőre, ahol van. Ha a kódexben sehol nincs üres hely, a bélyeg elvész. |
| **Átadás** (give_stamp) | Egy véletlenszerű bélyeg a saját nyitott oldaladról az ellenfél nyitott oldalára kerül. Ha az ellenfél oldala tele van, a bélyeg megsemmisül. |
| **Bázis áthelyezése** (move_base) | A saját bázisod a hatásminta (első) jelölt mezőjére kerül. Nem kerülhet a táblán kívülre, sem az ellenfél bázisára – ilyenkor nem történik semmi. Az ellenfélnek ezután az új helyre kell eljutnia a megkoronázott golemjével. |
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
| **+1 saját koronapont** (gain_crown_point) | A koronamérőd 1 ponttal nő, legfeljebb a teli mérőig – akkor is, ha a koronád a táblán van. |
| **−1 ellenséges koronapont** (remove_enemy_crown_point) | Az ellenfél koronamérője 1 ponttal csökken; 0 alá nem megy. Teljes Se-tenant sorral rendelkező ellenfélnél hatástalan, mert a mérője azonnal újratelik. |

Az időtartam-módosítók a végtelen (−1) időtartamú bélyegeket nem érintik.

### 7.4 Az időzített hatások élettartama

A tiltott és lefagyasztott mezők, valamint a láthatatlan és nem üthető védelem mindig pontosan **3 kör-lépésig** tart, a bélyeg időtartamától függetlenül. A számláló minden kör végén csökken, kivéve a létrehozás körének végét. A hatás tehát érvényes:

1. a létrehozó játékos aktuális körének hátralévő részében,
2. az ellenfél következő körében,
3. a létrehozó játékos következő körében,
4. az ellenfél azt követő körében,

és a létrehozó játékos harmadik körének kezdetére megszűnik. Ha a golem elveszíti a bélyegét (lejárat, leütés, Overseal-letakarás), a rajta lévő védelem is azonnal megszűnik; a tábla-zónák viszont a létrehozó golem sorsától függetlenül kitartanak.

### 7.5 Feloldási sorrend egy lépésnél

Haladó játékosoknak – egy lépés eseményei ebben a sorrendben történnek:

1. A leütendő golem **„ha leütik”** hatása.
2. A leütött golem Kereső bélyege visszakerül a kódexbe.
3. Az ütő golem a célmezőre kerül.
4. Az ütő golem **„ha üt”** hatása.
5. A leütött golem elveszíti a bélyegét és újraéled (zárolás / feloldás).
6. **Győzelem-ellenőrzés:** ha a lépő golem a lépő játékos megkoronázott golemje, és az ellenfél bázisán áll, a játék véget ér.
7. A lépő golem **„lépéskor”** hatása – csak ha nem ütött.
8. Az időtartam eggyel csökken; ha 0, a bélyeg lejár és a **„lejáratkor”** hatás kiváltódik.
9. A kör véget ér.

---

## 8. Kódex- és pakliépítési szabályok

- Egy kódex **pontosan 15 bélyegből** áll.
- Minden bélyegből legfeljebb **2 példány** lehet a kódexben.
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
5. Későbbi körök: (lapozás) → (felragasztás, koronázás) → **lépés, ami kötelező és lezárja a kört**.
6. A most bélyegzett golem a körben kimerült. Kör vége gomb csak akkor, ha nincs lépés, de van kimerült vagy lefagyasztott golem.
7. Lépésenként −1 időtartam; 0-nál a bélyeg lejár (a Kereső visszakerül a kódexbe, a többi elvész). Az Overseal bélyeges golemre is ragasztható, és hatás nélkül letakarja a régi bélyeget.
8. A leütött golem zárolva éled újra az alapsoron; a következő leütés feloldja, de az az újabb golem végleg elvész.
9. Korona: saját körönként +1 pont (a fekete 1 ponttal indul); 6 pontnál feltehető bármelyik golemre, ami arra a körre kimeríti. Újabb 6 ponttal áthelyezhető egy másik golemre. Leütéskor elvész, és a pontok 0-ról gyűlnek újra. 3 Se-tenant bélyeges golemmel a mérő mindig tele van; ha a sor megszakad, 0-ra esik.
10. Győzelem: megkoronázott golem az ellenfél bázisán. Vereség: nincs akció a kör elején, vagy lejárt óra.

## Függelék – Bélyeglista

A lista a játékban jelenleg engedélyezett és csomagból/történetből elérhető bélyegeket tartalmazza, szettenként. A minták a golem szemszögéből értendők: a **felső sor van előre** (az ellenfél felé), a rács közepén (`@`) áll a golem.

Jelmagyarázat – mozgás: `X` lépés vagy ütés · `m` csak lépés (üres mezőre) · `c` csak ütés · `.` nem elérhető. Hatásmező: `#` (ha a rács közepén áll, a golem saját mezője is a hatásmező része).


### Udvar (Courtyard)

| Bélyeg | Szerep | Időtartam | Mozgásminta | Hatás |
|---|---|:---:|---|---|
| **Archer ★** | Egység | 1 | <code>..c..<br>..m..<br>cm@mc<br>..m..<br>..c..</code> | – |
| **Assassin** | Egység | 2 | <code>.....<br>ccmcc<br>..@..<br>ccmcc<br>.....</code> | *ha üt:* Láthatatlan: az ellenfél 3 kör-lépésig nem látja ezt a golemet |
| **Berserk ★** | Egység | 1 | <code>..X..<br>.X.X.<br>..@..<br>.X.X.<br>..X..</code> | *ha üt:* +1 időtartam erre a bélyegre |
| **Bishop** | Egység | 1 | <code>X...X<br>.X.X.<br>..@..<br>.X.X.<br>X...X</code> | – |
| **Duke** | Egység | 1 | <code>.X.X.<br>..X..<br>X.@.X<br>..X..<br>.X.X.</code> | – |
| **Gold General ★** | Kereső | 2 | <code>X...X<br>.XXX.<br>.m@m.<br>.mmm.<br>.....</code> | – |
| **Knight ★** | Egység | 2 | <code>.X.X.<br>X...X<br>..@..<br>X...X<br>.X.X.</code> | – |
| **Lance ★** | Egység | 1 | <code>.XXX.<br>..X..<br>..@..<br>..X..<br>.....</code> | – |
| **Monk ★** | Egység | 1 | <code>..X..<br>.X.X.<br>..@..<br>.XXX.<br>.....</code> | – |
| **Prince** | Kereső | 2 | <code>.....<br>.mmm.<br>.m@m.<br>..m..<br>.....</code> | *felragasztáskor:* Láthatatlan: az ellenfél 3 kör-lépésig nem látja ezt a golemet |
| **Silver General ★** | Kereső | 2 | <code>c...c<br>.XXX.<br>.m@m.<br>.mmm.<br>.....</code> | – |
| **Skirmisher** | Egység | 1 | <code>..c..<br>c...c<br>..@..<br>..m..<br>m...m</code> | *ha leütik:* +1 időtartam minden bélyeges golemedre |
| **The Golem ★** | Egység | 2 | <code>.....<br>..X..<br>.X@X.<br>..X..<br>.....</code> | *ha megkoronázzák:* +1 időtartam minden bélyeges golemedre |
| **War Drummer ★** | Egység | 3 | <code>.....<br>.m.m.<br>..@..<br>.m.m.<br>.....</code> | *felragasztáskor:* +1 időtartam minden bélyeges golemedre |
| **Warlord ★** | Egység | 1 | <code>.X.X.<br>X...X<br>..@..<br>..m..<br>.....</code> | *ha üt:* +1 időtartam minden bélyeges golemedre |

### Állatok (Animals)

| Bélyeg | Szerep | Időtartam | Mozgásminta | Hatás |
|---|---|:---:|---|---|
| **Bear** | Egység | 2 | <code>X...X<br>..X..<br>..@..<br>..m..<br>m...m</code> | – |
| **Blackbird** | Egység | 2 | <code>m.m.m<br>.....<br>m.@.m<br>.....<br>m.m.m</code> | – |
| **Cat** | Kereső | 2 | <code>X...X<br>.X.X.<br>..@..<br>..m..<br>.....</code> | *ha üt:* Láthatatlan: az ellenfél 3 kör-lépésig nem látja ezt a golemet |
| **Crocodile** | Egység | 2 | <code>.....<br>.cXc.<br>.c@c.<br>..m..<br>.....</code> | *felragasztáskor:* Láthatatlan: az ellenfél 3 kör-lépésig nem látja ezt a golemet |
| **Dog** | Egység | 2 | <code>m...m<br>.ccc.<br>..@..<br>..m..<br>.....</code> | – |
| **Dragon** | Egység | 2 | <code>.....<br>.X.X.<br>.X@X.<br>.X.X.<br>.....</code> | *ha üt:* Nem üthető: ezt a golemet 3 kör-lépésig nem lehet leütni |
| **Dragonhorse** | Egység | 2 | <code>.m.m.<br>mc.cm<br>.c@c.<br>mc.cm<br>.m.m.</code> | – |
| **Duck** | Megosztott | 2 | <code>mmmmm<br>mmmmm<br>mm@mm<br>mmmmm<br>mmmmm</code> | – |
| **Elephant** | Egység | 3 | <code>X...X<br>.....<br>..@..<br>.....<br>m...m</code> | – |
| **Fox** | Egység | 2 | <code>.X.X.<br>.....<br>..@..<br>.....<br>.X.X.</code> | *lépéskor:* Láthatatlan: az ellenfél 3 kör-lépésig nem látja ezt a golemet |
| **Goat** | Egység | 2 | <code>...m.<br>m....<br>..@.m<br>.m...<br>.....</code> | *ha megkoronázzák:* Nem üthető: ezt a golemet 3 kör-lépésig nem lehet leütni |
| **Heron** | Egység | 2 | <code>.X.X.<br>..m..<br>.m@m.<br>..m..<br>.m.m.</code> | – |
| **Horse** | Egység | 1 | <code>.X.X.<br>m...m<br>..@..<br>m...m<br>.m.m.</code> | *felragasztáskor:* Nem üthető: ezt a golemet 3 kör-lépésig nem lehet leütni |
| **Rhinoceros** | Egység | 2 | <code>.ccc.<br>.XXX.<br>.m@m.<br>.mmm.<br>.....</code> | – |
| **Turtle** | Egység | 2 | <code>.....<br>.mXm.<br>.m@m.<br>.m.m.<br>.....</code> | – |

### Flóra (Flora)

| Bélyeg | Szerep | Időtartam | Mozgásminta | Hatás |
|---|---|:---:|---|---|
| **Baobab** | Egység | 3 | <code>.....<br>.XmX.<br>.m@m.<br>.XmX.<br>.....</code> | – |
| **Cactus** | Egység | 3 | <code>.....<br>.ccc.<br>.c@c.<br>.ccc.<br>.....</code> | – |
| **Chanterelle** | Overseal | 2 | <code>.....<br>.mXm.<br>..@..<br>.m.m.<br>.....</code> | – |
| **Cherry tree** | Egység | 3 | <code>.....<br>.mXm.<br>.m@m.<br>.mmm.<br>.....</code> | *lépéskor:* +1 időtartam erre a bélyegre |
| **Fly agaric** | Overseal | 2 | <code>.....<br>.m.m.<br>.m@m.<br>..m..<br>.....</code> | *ha leütik:* Bomba: a jelölt mezőkön álló minden golem (saját is!) leütöttnek számít <code>.....<br>.....<br>..#..<br>.....<br>.....</code> |
| **Larch** | Egység | 4 | <code>.....<br>.mXm.<br>.X@X.<br>.mmm.<br>.....</code> | – |
| **Lotus** | Kereső | 1 | <code>.....<br>.XmX.<br>.m@m.<br>.mmm.<br>.....</code> | *ha megkoronázzák:* −1 koronapont az ellenfélnek |
| **Magnolia** | Egység | 3 | <code>..X..<br>..X..<br>mm@mm<br>..m..<br>..X..</code> | – |
| **Oak** | Egység | 4 | <code>.....<br>.mmm.<br>.m@m.<br>.mmm.<br>.....</code> | *lépéskor:* Bázis áthelyezése: a bázisod a jelölt mezőre kerül <code>.....<br>..#..<br>..@..<br>.....<br>.....</code> |
| **Olive tree** | Egység | 3 | <code>.....<br>.mXm.<br>.m@m.<br>.mmm.<br>.....</code> | *lejáratkor:* Bélyeglopás: egy véletlen bélyeg az ellenfél nyitott oldaláról a tiédre kerül |
| **Orchid** | Egység | 3 | <code>..X..<br>.mXm.<br>..@..<br>.mXm.<br>..X..</code> | *lépéskor:* −1 koronapont az ellenfélnek |
| **Puffball** | Overseal | 2 | <code>.....<br>.mmm.<br>..@..<br>.m.m.<br>.....</code> | *ha leütik:* Bomba: a jelölt mezőkön álló minden golem (saját is!) leütöttnek számít <code>.....<br>.###.<br>.###.<br>.###.<br>.....</code> |
| **Rose** | Egység | 4 | <code>.....<br>.XmX.<br>.m@m.<br>.XmX.<br>.....</code> | *lépéskor:* Nem üthető: ezt a golemet 3 kör-lépésig nem lehet leütni |
| **Shaggy mane** | Overseal | 3 | <code>.....<br>.X.X.<br>..@..<br>.m.m.<br>.....</code> | – |
| **Yellow coral** | Overseal | 3 | <code>.....<br>.X.X.<br>..@..<br>.X.X.<br>.....</code> | – |

### Égitestek (Celestials)

| Bélyeg | Szerep | Időtartam | Mozgásminta | Hatás |
|---|---|:---:|---|---|
| **Black Hole** | Overseal | 8 | <code>.....<br>.XXX.<br>.X@X.<br>.XXX.<br>.....</code> | *lépéskor:* −1 időtartam minden bélyeges golemedre |
| **Comet** | Megosztott | 1 | <code>.XXX.<br>..m..<br>..@..<br>..m..<br>.XXX.</code> | *lejáratkor:* −1 időtartam minden ellenséges bélyeges golemre |
| **Earth** | Se-tenant | 3 | <code>.....<br>..X..<br>.m@m.<br>m...m<br>.....</code> | – |
| **Jupiter** | Egység | 2 | <code>..m..<br>.....<br>m.@.m<br>.....<br>..m..</code> | *felragasztáskor:* Bomba: a jelölt mezőkön álló minden golem (saját is!) leütöttnek számít <code>.....<br>.###.<br>.#@#.<br>.###.<br>.....</code> |
| **Mars** | Egység | 3 | <code>.....<br>.cXc.<br>.X@X.<br>.cXc.<br>.....</code> | – |
| **Mercury** | Egység | 4 | <code>..X..<br>.....<br>m.@.m<br>.....<br>..m..</code> | *ha megkoronázzák:* Lefagyasztás: a jelölt mezőkön álló golemek 3 kör-lépésig nem léphetnek <code>.....<br>.###.<br>.#@#.<br>.###.<br>.....</code> |
| **Moon** | Se-tenant | 3 | <code>.....<br>X...X<br>.m@m.<br>..m..<br>.....</code> | – |
| **Nebula** | Egység | 4 | <code>.....<br>..m..<br>.X@X.<br>..m..<br>.....</code> | – |
| **Neptune** | Egység | 3 | <code>.mmm.<br>..m..<br>..@..<br>..m..<br>.mmm.</code> | *felragasztáskor:* Lefagyasztás: a jelölt mezőkön álló golemek 3 kör-lépésig nem léphetnek <code>.....<br>.###.<br>..@..<br>.....<br>.....</code> |
| **North Star** | Egység | 4 | <code>.ccc.<br>.....<br>c.@.c<br>.....<br>..c..</code> | *ha üt:* −1 koronapont az ellenfélnek |
| **Nova** | Egység | 2 | <code>..m..<br>.....<br>m.@.m<br>.....<br>..m..</code> | *felragasztáskor:* Bomba: a jelölt mezőkön álló minden golem (saját is!) leütöttnek számít <code>.###.<br>#####<br>##@##<br>#####<br>.###.</code> |
| **Saturn** | Egység | 3 | <code>..X..<br>.....<br>X.@.X<br>.....<br>..m..</code> | *felragasztáskor:* −1 időtartam minden ellenséges bélyeges golemre |
| **Sun** | Se-tenant | 3 | <code>.....<br>.X.X.<br>m.@.m<br>.m.m.<br>.....</code> | *felragasztáskor:* +1 koronapont |
| **Uranus** | Egység | 2 | <code>.....<br>..m..<br>Xm@mX<br>..m..<br>.....</code> | – |
| **Venus** | Egység | 2 | <code>.X.X.<br>.....<br>X.@.X<br>.....<br>.X.X.</code> | *ha üt:* +1 időtartam minden ellenséges bélyeges golemre |

### Építmények (Structures)

| Bélyeg | Szerep | Időtartam | Mozgásminta | Hatás |
|---|---|:---:|---|---|
| **Ballista** | Egység | 2 | <code>.ccc.<br>ccccc<br>..@..<br>..m..<br>.....</code> | *lejáratkor:* Átadás: egy véletlen bélyeg a nyitott oldaladról az ellenfél nyitott oldalára kerül |
| **Bastion** | Egység | 3 | <code>.....<br>.c.c.<br>.X@X.<br>.....<br>.....</code> | *felragasztáskor:* Előhívás: egy új **Lance** bélyeget ragaszt a kódexed legközelebbi üres helyére |
| **Bicycle** | Se-tenant | 3 | <code>X.m.X<br>.....<br>m.@.m<br>.....<br>X.m.X</code> | *felragasztáskor:* +1 koronapont |
| **Bombard** | Egység | 3 | <code>.....<br>.XcX.<br>.m@m.<br>.....<br>.....</code> | *lépéskor:* Bomba: a jelölt mezőkön álló minden golem (saját is!) leütöttnek számít <code>.###.<br>.#.#.<br>..@..<br>.....<br>.....</code> |
| **Castle** | Egység | 2 | <code>.....<br>.XXX.<br>.X@X.<br>.mmm.<br>.....</code> | – |
| **Citadel** | Overseal | 2 | <code>.....<br>.m.m.<br>.m@m.<br>.m.m.<br>.....</code> | – |
| **Fortress** | Egység | 2 | <code>.....<br>..c..<br>.m@m.<br>..c..<br>.....</code> | *felragasztáskor:* Nem üthető: ezt a golemet 3 kör-lépésig nem lehet leütni |
| **Gate** | Egység | 3 | <code>.....<br>.cXc.<br>..@..<br>..m..<br>.....</code> | – |
| **Mantlet** | Egység | 3 | <code>.....<br>..m..<br>.m@m.<br>..m..<br>.....</code> | *lépéskor:* Tiltott mezők: a jelölt mezőkre 3 kör-lépésig nem lehet lépni <code>.....<br>#####<br>..@..<br>.....<br>.....</code> |
| **Shrine** | Egység | 3 | <code>.....<br>.cXc.<br>.m@m.<br>..m..<br>.....</code> | – |
| **Temple** | Egység | 3 | <code>.....<br>.cmc.<br>.X@X.<br>..m..<br>.....</code> | – |
| **Tortoise** | Egység | 3 | <code>.....<br>..X..<br>.m@m.<br>..m..<br>.....</code> | *felragasztáskor:* Tiltott mezők: a jelölt mezőkre 3 kör-lépésig nem lehet lépni <code>..#..<br>.#.#.<br>#.@.#<br>.#.#.<br>..#..</code> |
| **Tower** | Egység | 3 | <code>.....<br>.XXX.<br>.X@X.<br>.c.c.<br>.....</code> | – |
| **Trebuchet** | Egység | 2 | <code>.ccc.<br>c...c<br>c.@.c<br>c...c<br>.....</code> | – |
| **War Chariot** | Egység | 3 | <code>.....<br>.XXX.<br>.m@m.<br>..X..<br>.....</code> | *ha leütik:* Tiltott mezők: a jelölt mezőkre 3 kör-lépésig nem lehet lépni <code>.....<br>.###.<br>.#@#.<br>.###.<br>.....</code> |

### Archetípusok (Archetypes)

| Bélyeg | Szerep | Időtartam | Mozgásminta | Hatás |
|---|---|:---:|---|---|
| **Adventurer** | Kereső | 1 | <code>.....<br>.ccc.<br>.c@m.<br>.mmm.<br>.....</code> | – |
| **Advocate** | Egység | 2 | <code>.....<br>.mcm.<br>.c@m.<br>.cmc.<br>.....</code> | *lejáratkor:* Előhívás: egy új **Sun** bélyeget ragaszt a kódexed legközelebbi üres helyére |
| **Architect** | Egység | 2 | <code>.....<br>.mcm.<br>.m@c.<br>.cmc.<br>.....</code> | *felragasztáskor:* Előhívás: egy új **Architect** bélyeget ragaszt a kódexed legközelebbi üres helyére |
| **Campaigner** | Egység | 2 | <code>.....<br>.cmm.<br>.c@m.<br>.ccm.<br>.....</code> | *lépéskor:* −1 koronapont az ellenfélnek |
| **Commander** | Egység | 1 | <code>.....<br>.mmm.<br>.m@c.<br>.ccc.<br>.....</code> | – |
| **Consul** | Egység | 2 | <code>.....<br>.mmc.<br>.c@m.<br>.mcc.<br>.....</code> | *felragasztáskor:* Előhívás: egy új **Moon** bélyeget ragaszt a kódexed legközelebbi üres helyére |
| **Defender** | Egység | 2 | <code>.....<br>.mcc.<br>.c@m.<br>.mmc.<br>.....</code> | *felragasztáskor:* Nem üthető: ezt a golemet 3 kör-lépésig nem lehet leütni |
| **Entertainer** | Egység | 2 | <code>.....<br>.cmc.<br>.c@m.<br>.mcm.<br>.....</code> | *ha üt:* Bélyeglopás: egy véletlen bélyeg az ellenfél nyitott oldaláról a tiédre kerül |
| **Entrepreneur** | Egység | 1 | <code>.....<br>.cmc.<br>.m@c.<br>.mcm.<br>.....</code> | *lejáratkor:* +1 időtartam minden bélyeges golemedre |
| **Executive** | Egység | 4 | <code>.....<br>.mmc.<br>.m@c.<br>.mcc.<br>.....</code> | *ha üt:* Bomba: a jelölt mezőkön álló minden golem (saját is!) leütöttnek számít <code>.#...<br>.##..<br>.#@..<br>.#...<br>.....</code> |
| **Logician** | Egység | 2 | <code>.....<br>.ccm.<br>.m@c.<br>.cmm.<br>.....</code> | *lépéskor:* Előhívás: egy új **Bicycle** bélyeget ragaszt a kódexed legközelebbi üres helyére |
| **Logistician** | Egység | 2 | <code>.....<br>.mcc.<br>.m@c.<br>.mmc.<br>.....</code> | – |
| **Mediator** | Egység | 1 | <code>.....<br>.ccm.<br>.c@m.<br>.cmm.<br>.....</code> | *lejáratkor:* +1 időtartam minden bélyeges golemedre |
| **Protagonist** | Egység | 4 | <code>.....<br>.mmm.<br>.c@m.<br>.ccc.<br>.....</code> | *lépéskor:* Bélyeglopás: egy véletlen bélyeg az ellenfél nyitott oldaláról a tiédre kerül |
| **Virtuoso** | Kereső | 3 | <code>.....<br>.ccc.<br>.m@c.<br>.mmm.<br>.....</code> | *ha üt:* Bélyeglopás: egy véletlen bélyeg az ellenfél nyitott oldaláról a tiédre kerül |

★ = a kezdőpakli („Nagyapa kódexe”) része.
