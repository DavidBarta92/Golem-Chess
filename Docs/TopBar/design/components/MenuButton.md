# MenuButton

Ikonos menü gomb a sáv jobb szélén; kattintásra lenyíló doboz nyílik a játék általános parancsaival.

- Gomb: `button-size` négyzet, `radius-md`, 1,5 px `ink` keret, `paper` kitöltés; hoverre `paper-hover`, nyitva `ink` kitöltés `paper` ikonnal.
- Lenyíló: a gomb jobb széléhez igazodik, alatta 10 px-re; `menu-width`, `radius-lg`, `shadow-menu`. Sorok `menu-row` magasak: `icon-menu` ikon + `menu-item` szöveg.
- Tartalom, csoportonként: **Alpha Multiplayer** („ideiglenes” címkével, saját csoportban, hogy egyben kivehető legyen) · **Beállítások**, **Tutorial** · **Kilépés** (külön, alul).
- Bezár: újra a gombra kattintás, egy menüpont választása, kattintás máshova, Esc. Ha a menü nyílik, a nyitott küldetéspanel bezárul.
- `aria-haspopup="menu"` és `aria-expanded` a gombon; a pontok `role="menuitem"`.
