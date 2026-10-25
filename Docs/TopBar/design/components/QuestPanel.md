# QuestPanel

A feladat részletei: a szalagra kattintva a szalag lecsúszik, és jobbra mellette színátmenetes háttéren megjelenik a leírás és a haladás.

- A szalag maga a panel bal szegélye (mint a kártyaleírás tintacsíkja); a hossza a sáv + a panel magassága.
- Háttér: `panel-from` → `panel-to` vízszintes átmenet, 80 %-ig átlátszatlan. Szélesség `panel-width`, a szöveg `panel-text`-en belül marad. A panel belecsúszhat a sáv jobb margójába; csak ha a képernyő szélén is túllógna, akkor nyílik balra.
- Sorrend fentről:
  1. kicker (`quest-kicker`): kis szalagsziluett + TÖRTÉNET / JUTALOM / NAPI, a jutalom szövegszínében (`story`, `coin-deep`, `draw`); napinál jobbra a hátralévő idő `caption`-nel, egy óra alatt `urgent`;
  2. cím (`quest-title`);
  3. leírás (`quest-text`, dőlt), benne a feltétel `quest-key`-jel;
  4. haladás: 10 lépésig pöttyök, fölötte csík, mellette „2 / 3”;
  5. jutalom sor („Jutalom +50 ⦿”); teljesítve mellette **Begyűjtés** (primary, kicsi).
- Egyszerre egy panel. Bezár: a szalagra újra kattintás, kattintás máshova, Esc.
- Ha jobbra nem fér ki, balra nyílik, és az átmenet tükröződik.
- Mozgás: a szalag 240 ms alatt csúszik le, a panel 90 ms késéssel 200 ms alatt úszik be 8 px-ről.
