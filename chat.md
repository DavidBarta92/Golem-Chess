




```mermaid
flowchart TD
	A([Start: Bevezető comic scene]) --> B[Emlék a nagyapáról, szintén comic scene]
	B --> C[Tutorial]
	C --> D[Boss 1 meccs]
	D --> E{Nyertél?}
	E -- Nem --> F[Átvezető comic scene az újra kezdéshez]
	F --> D
	E -- Igen --> G[Reward scene: Megkapod a boss bélyegeit, erre majd kell egy naimáció, hogy beröppennek a kártyák a képre lefordított állapotban és egyesével rájuk kell kattintani, hogy megfoduljanak, mint amikor boostert nyitsz, csak most több kártyával. A kapott 15 lap ebben a sorrendben lesz a játékos aktív paklija, amíg a Collection meg nem nyílik]
	E -- Igen --> A1[(Progress mentés)]
	G --> H[comic scene, átvezető a következő meccshez]
	H --> I[Boss 2 meccs]
	I --> J{Nyertél?}
	J -- Nem --> K[Átvezető comic scene az újra kezdéshez]
	K --> I
	J -- Igen --> L[Átvezető comic scene elmagyarázni a collection menüt]
	J -- Igen --> A2[(Progress mentés, Colletion menü feloldás)]
	L -- Feloldódik a collection menü --> M[Main menü]
	M --> N[Colection menü]
	N --> M
	M -- ha Boss 2-t legyőzted --> O[Comic scene, ami felvezeti a Boss 3-at]
	O --> P[Boss 3 meccs]
	P --> Q{Nyertél?}
	Q -- Nem --> Q1{Új játék azonnal?} -- Igen --> P
	Q1 -- Nem --> M
	Q -- Igen --> R[Comic scene, amin elmagyarázzuk hogyna működik a Buy Pack menüpont, itt legelőször csak egy pack elérhető: a Citadel Guard]
	Q -- Igen --> A3[(Progress mentés, Buy Pack gomb feloldás, Citadel Guard pack feloldás)]
	R --> N
	N --> S[Buy Pack menü]
	S --> N
	M -- ha Boss 3-t legyőzted --> T[comic scene, ami felvezeti a Boss 4-et]
	T --> U[Boss 4 meccs]
	U --> V{Nyertél?}
	V -- Igen --> W[Reward scene ahol coinokat kapunk. Ehhez egy olyan animációt szeretném majd, hogy a coinok fentről be esnek a képbe, három coin, kicsit mocorognak mintha egy asztal estek volna le majd végül megállapodnak, ha rájukattintunk akkor a 3 kis coin felröppen a jobb felső sarokba, ahol megejelnik a szokásos coin jelző és ott a szám feljebb megy]
	V -- Igen --> A4[(Progress mentés, Hunter's Pack és Beast Engines pack feloldás)]
    V -- Nem --> Q2{Új játék azonnal?} -- Igen --> U 
    Q2 -- Nem --> M
    W --> M
    M -- ha Boss 4-t legyőzted --> X1[Egy random meccs, egyenként a Play gombról indítva; nyerni nem kell, mindegyik után vissza a főmenübe; a(z) 2. Play után jön a boss] --> X[comic scene, ami felvezeti a Boss 5-öt]
    X --> Y[Boss 5 meccs]
    Y --> Z{Nyertél?}
    Z -- Igen --> AA[Reward scene itt egy bélyeg repül be a képbe, ezt a bélyeget majd az aditorból akarom beállítani hogy melyik legyen, maga a berepüles kicsit fentről, oldalról történjen, amikor megáll a kép közepén legyne lefordítva és kattintásra forduljon meg, amikor megfordul legyne mögötte olyan iece attach glow shader effect]
    Z -- Igen --> A5[(Progress mentés, az award scen-en beállított bélyeget megkapjuk, Forest Fortress, Overgrown Defense, Deep in the Wild pack feloldás)]
    Z -- Nem -->  Q3{Új játék azonnal?} -- Igen --> Y
    Q3 -- Nem --> M
    AA --> M
    M -- ha Boss 5-t legyőzted --> X2[Egy random meccs, egyenként a Play gombról indítva; nyerni nem kell, mindegyik után vissza a főmenübe; a(z) 2. Play után jön a boss] --> AB[Comic scene ami felvezeti Boss 6-ot]
    AB --> AC[Boss 6 meccs]
    AC --> AD{Nyertél?}
    AD -- Igen --> AE[comic scene, ami felvezeti a multiplayert, ez majd egy jelenet lesz egy telefonhívásról és ezt követően lesz egy új gomb a főmenüben]
    AD -- Igen --> A6[(Progress mentés, multiplayer gomb feloldása a főmenüben)]
    AD -- Nem -->  Q4{Új játék azonnal?} -- Igen --> AC
    Q4 -- Nem --> M
    AE -- elérhetővé válik a multiplayer menüpont a főmenüben, ez nem a mostani multiplayer gomb hanem majd egy új --> M
    M -- ha Boss 6-t legyőzted --> X3[Két random meccs, egyenként a Play gombról indítva; nyerni nem kell, mindegyik után vissza a főmenübe; a(z) 3. Play után jön a boss] --> AF[Comic scene ami felvezeti Boss 7-et]
    AF --> AG[Boss 7 meccs]
    AG --> AH{Nyertél?}
    AH -- Igen --> AI[Reward scene, amin egy vadonat új élyeg repül be a képbe, szintén lefordítva szintén glow effectel]
    AH -- Igen --> A7[(Progress mentés, az award scenen beállított bélyeget megkapjuk, , Masked Council, Runeworks, Inner Instinct, Se-tenant Harmony pack feloldás)]
    AH -- Nem -->  Q5{Új játék azonnal?} -- Igen --> AG
    Q5 -- Nem --> M
    AI --> M
    M -- Boss 6 után --> MULTY[Multiplayer scene]
    M -- ha Boss 7-t legyőzted --> X4[Két random meccs, egyenként a Play gombról indítva; nyerni nem kell, mindegyik után vissza a főmenübe; a(z) 3. Play után jön a boss] --> AJ[Comic scene ami felvezeti Boss 8-at]
    AJ --> AK[Boss 8 meccs]
    AK --> AL{Nyertél?}
    AL -- Igen --> AM[Comic scene, egy levelet kapsz valakitől]
    AL -- Igen --> A8[(Progress mentés, quests gomb feloldása a főmenüben)]
    AL -- Nem -->  Q6{Új játék azonnal?} -- Igen --> AK
    Q6 -- Nem --> M
    AM --> AN[Ez egy vadonatúj scene típus lesz, az a neve hogy Quest, egy levél csúszik be a képbe, ha rákattintasz kinyílik és kirajzlódik a board, amin egy előre beállított játékállás lesz, előre meg lesz határozva a cél, és ha ezt teljesíti a játékos akkor nyert]
    AN --> AO[Szintén egy vadonat új scene, ahol az előbbi borítékot látjuk majd és a rajta lévő bélyeget körbe kell rajzolni, ha eszt a játékos megteszi akkor mondthatni kivágta a bélyegt és megkapj az a collectionbe]
    AO --> M
    M -- Boss 8 után --> AN
    M -- ha Boss 8-t legyőzted --> X5[Három random meccs, egyenként a Play gombról indítva; nyerni nem kell, mindegyik után vissza a főmenübe; a(z) 4. Play után jön a boss] --> AP[Comic scene ami felvezeti Boss 9-et]
    AP --> AQ[Boss 9 meccs]
    AQ --> AR{Nyertél?}
    AR -- Igen --> AS[Reward scene, egy új bélyeg berepül lefordítva, és van a szokásos glow effect]
    AR -- Igen --> A9[(Progress mentés, az award scenen beállított bélyeget megkapjuk, March of Mars, Heavenly Bastion, Zodiac Stew pack feloldás)]
    AR -- Nem -->  Q7{Új játék azonnal?} -- Igen --> AQ
    Q7 -- Nem --> M
    AS --> M
    M -- ha Boss 9-t legyőzted --> X6[Három random meccs, egyenként a Play gombról indítva; nyerni nem kell, mindegyik után vissza a főmenübe; a(z) 4. Play után jön a boss] --> AT[Comic scene ami felvezeti Boss 10-et]
    AT --> AU[Boss 10 meccs]
    AU --> AV{Nyertél?}
    AV -- Igen --> AW[Egy vadonat új scene jön, az a neve hogy trade, később részletezem]
    AV -- Igen --> A10[(Progress mentés, trade gomb feloldása a főmenüben)]
    AV -- Nem -->  Q8{Új játék azonnal?} -- Igen --> AU
    Q8 -- Nem --> M
    AW --> M
    M -- ha Boss 10-t legyőzted --> X7[Egy random meccs, egyenként a Play gombról indítva; nyerni nem kell, mindegyik után vissza a főmenübe; a(z) 2. Play után jön a boss] --> AX[Comic scene ami felvezeti Boss 11-et]
    AX --> AY[Boss 11 meccs]
    AY --> AZ{Nyertél?}
    AZ -- Igen --> BA[Reward scene, amin nagyon sok coin hullik le az asztalra, majd katitntásra felrepülnek a jobb felső sarokba]
    AZ -- Igen --> A11[(Progress mentés, Moonlight Garden, Cosmic Oracle pack feloldás)]
    AZ -- Nem -->  Q9{Új játék azonnal?} -- Igen --> AY
    Q9 -- Nem --> M
    BA --> M
    M -- ha Boss 11-t legyőzted --> X8[Egy random meccs, egyenként a Play gombról indítva; nyerni nem kell, mindegyik után vissza a főmenübe; a(z) 2. Play után jön a boss] --> BB[Comic scene ami felvezeti Boss 12-et]
    BB --> BC[Boss 12 meccs]
    BC --> BD{Nyertél?}
    BD -- Igen --> BE[Reward scene, amin nagyon sok coin hullik le az asztalra, majd katitntásra felrepülnek a jobb felső sarokba és egy értékes bélyeget is kapsz]
    BD -- Igen --> A12[(Progress mentés, az award scenen beállított bélyeget megkapjuk)]
    BD -- Nem -->  Q10{Új játék azonnal?} -- Igen --> BC
    Q10 -- Nem --> M
    BE --> BF([End: Lezáró comic scene])
    BF --> M
```
