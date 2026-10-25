# TopBar

A felső sáv két zónája: bal oldalon a képernyő saját gombjai, jobb oldalon a fix csoport — szalagok → számlálók → menü.

- **Bal zóna** (`.gb-left`): a főképernyőn a logó; alképernyőn a „Vissza” és közvetlenül utána a képernyő saját gombjai (pl. „Csomagvásárlás”). Ez zsugorodik, ha fogy a hely.
- **Jobb csoport** (`.gb-right`): a jobb szélhez rögzítve, `space-6` közökkel. Soha ne tegyél bele képernyőfüggő gombot — a mostani átfedés (Csomagvásárlás a rang alatt) ebből jön.
- A számlálók és a szalagok konténere `flex-direction: row-reverse`; a DOM-ban megjelenési / korsorrendben vannak, így az új elem egyszerű hozzáfűzéssel balra kerül, és a szalagok mindig a számlálók mellett maradnak.
- Magasság `bar-height`, oldalmargó `space-8`, háttér `paper`. A sáv alatti jelenet `paper-deep`; a szalagok ebbe lógnak bele `space-4`-nyit.

A hívó adja: a bal zóna tartalmát, a szalagok listáját (legrégebbi elöl), a számlálók listáját (elsőként megjelent elöl).
