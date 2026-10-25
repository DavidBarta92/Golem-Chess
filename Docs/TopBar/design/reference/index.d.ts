// Golem felső sáv — a previewk segédeinek típusai (sima JS, window.Golem, HTML-stringet adnak vissza).
// A játékban a README szabályai a mérvadók; ez a kód csak a vázlatokat rajzolja.

/** story = ferde vágás, reward = V-bevágás, daily = bástyafogak */
export type QuestKind = 'story' | 'reward' | 'daily';
/** A szalag színe: coin = arany, draw = tintakék. A történet mindig bordó. */
export type Reward = 'coin' | 'draw';
export type StatKind = 'coin' | 'draw' | 'rank';
export type IconName = 'coin' | 'draw' | 'rank' | 'menu' | 'gear' | 'help' | 'door' | 'people' | 'book' | 'hourglass' | 'check' | 'plus';

export interface Quest {
  kind: QuestKind;
  /** Csak reward és daily esetén; story-nál figyelmen kívül marad. */
  reward?: Reward;
  title?: string;
  /** Dőlt leírás; a pontos feltétel <b>…</b> között. */
  text?: string;
  /** target > 1 esetén varrás a szalagon, pöttyök (≤10) vagy csík (>10) a panelen. */
  progress?: { now: number; target: number };
  /** Jutalom mennyisége (érme / rajzpont). */
  amount?: number;
  /** Napi feladat hátralévő ideje, pl. „még 17 ó 05 p”. */
  timeLeft?: string;
  /** Egy óránál kevesebb van hátra. */
  urgent?: boolean;
  /** Teljesítve, begyűjtésre vár. */
  done?: boolean;
}

export interface QuestRibbonProps extends Quest {
  /** Statikus bemutatóhoz. */
  state?: 'hover' | 'retracted';
  /** Csak a szalag teste és vége, ikon nélkül. */
  plain?: boolean;
  id?: string;
}
export declare function ribbon(props: QuestRibbonProps): string;

export interface QuestPanelProps extends Quest {}
export declare function panel(props: QuestPanelProps): string;

export interface StatBlockProps { kind: StatKind; value: number }
export declare function stat(kind: StatKind, value: number): string;

export interface ButtonProps { variant?: 'primary'; size?: 'sm'; icon?: IconName; disabled?: boolean; cls?: string; attrs?: string }
export declare function button(label: string, props?: ButtonProps): string;
export declare function iconButton(name: IconName, label: string, props?: { cls?: string; attrs?: string }): string;

export interface MenuButtonProps { open?: boolean }
export declare function menu(open?: boolean): string;

export interface IconsProps { name: IconName; size?: number; mono?: boolean }
export declare function icon(name: IconName, size?: number, mono?: boolean): string;

export interface TopBarProps {
  /** A bal zóna HTML-je: logó vagy Vissza + a képernyő saját gombjai. */
  left?: string;
  /** Korsorrendben, a legrégebbi az első — jobb szélre kerül. */
  quests?: QuestRibbonProps[];
  /** Megjelenési sorrendben — az első a menü mellé kerül. */
  stats?: Array<[StatKind, number]>;
  menuOpen?: boolean;
}
export declare function bar(props: TopBarProps): string;

export interface QuestQueueProps extends TopBarProps {
  /** A színpad (sáv + jelenet) magassága px-ben. */
  height?: number;
  /** Ha meg van adva, szalagra kattintáskor ez fut a panel nyitása helyett. */
  onRibbon?: (id: string, api: TopBarApi) => void;
}
export interface TopBarApi {
  open(id: string): void;
  close(): void;
  /** Új szalag a sor bal végére; visszaadja az azonosítóját. */
  add(q: Quest): string;
  /** claim = begyűjtve (felhúzódik), expire = lejárt (elszürkül). */
  remove(id: string, how?: 'claim' | 'expire'): void;
  addStat(kind: StatKind, value: number): void;
  removeStat(kind?: StatKind): void;
  bump(kind: StatKind, delta: number): void;
  setMenu(open: boolean): void;
  list(): Quest[];
}
export declare function mount(root: HTMLElement, props: QuestQueueProps): TopBarApi;

declare global {
  interface Window {
    Golem: {
      TAIL: Record<QuestKind, number>;
      icon: typeof icon; tail(kind: QuestKind): string; ribbon: typeof ribbon; stat: typeof stat;
      button: typeof button; iconButton: typeof iconButton; menu: typeof menu; panel: typeof panel;
      bar: typeof bar; logo(): string; mount: typeof mount; fmt(n: number): string;
    };
  }
}
