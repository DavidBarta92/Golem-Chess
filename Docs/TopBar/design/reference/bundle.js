/* Golem felső sáv — a previewk közös segédei. Sima JS, nincs React: window.Golem. */
(function () {
  'use strict';

  var TAIL = { story: 10, reward: 9, daily: 6 };
  var TAIL_VAR = { story: '--tail-story', reward: '--tail-reward', daily: '--tail-daily' };
  var KIND_LABEL = { story: 'Történet', reward: 'Jutalom', daily: 'Napi' };
  var STAT_LABEL = { coin: 'Érme', draw: 'Rajzpont', rank: 'Rang' };
  var REWARD_ICON = { story: 'book', coin: 'coin', draw: 'draw' };

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c];
    });
  }

  // 1000 marad, ötjegyűtől szóközzel tagolva: 12 400
  function fmt(n) {
    var s = String(Math.round(n));
    return Math.abs(n) >= 10000 ? s.replace(/\B(?=(\d{3})+(?!\d))/g, ' ') : s;
  }

  function gear() {
    var n = 8, ro = 9.4, ri = 7.2, step = Math.PI * 2 / n, d = '';
    function pt(r, a) { return (12 + r * Math.cos(a)).toFixed(2) + ' ' + (12 + r * Math.sin(a)).toFixed(2); }
    for (var i = 0; i < n; i++) {
      var a = i * step - Math.PI / 2;
      d += (i ? 'L' : 'M') + pt(ri, a - step * 0.22) + 'L' + pt(ro, a - step * 0.13) + 'L' + pt(ro, a + step * 0.13) + 'L' + pt(ri, a + step * 0.22);
    }
    return '<path d="' + d + 'Z"/><circle cx="12" cy="12" r="3"/>';
  }

  // 24-es rács, tintavonal; .f-* = jelentést hordozó kitöltés
  var ICONS = {
    coin: '<circle class="f-coin" cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5.4" stroke-width="1.25"/><circle class="f-ink" cx="12" cy="12" r="1.3"/>',
    draw: '<circle class="f-draw" cx="12" cy="12" r="9"/><path class="f-paper" d="M7.7 16.3l.9-2.9 6.2-6.2 2 2-6.2 6.2z" stroke-width="1.3"/><path d="M13.6 8.4l2 2" stroke-width="1.3"/>',
    rank: '<path d="M6 13.4 12 7.8l6 5.6" stroke-width="2.1"/><path d="M6 18.6 12 13l6 5.6" stroke-width="2.1"/>',
    menu: '<path d="M4.5 7.2c5-.5 10-.4 15 0"/><path d="M4.5 12c5 .4 10 .3 15 0"/><path d="M4.5 16.8c5-.4 10-.4 15 .1"/>',
    gear: gear(),
    help: '<circle cx="12" cy="12" r="9"/><path d="M9.4 9.6c0-1.6 1.2-2.6 2.6-2.6s2.6 1 2.6 2.4c0 2-2.6 2.2-2.6 4.4"/><circle class="f-ink" cx="12" cy="16.9" r="1"/>',
    door: '<path d="M13.5 4.5h-7v15h7"/><path d="M10 12h10"/><path d="M16.8 8.8 20 12l-3.2 3.2"/>',
    people: '<circle cx="9" cy="8.5" r="3"/><path d="M3.5 19c.6-3.4 2.7-5.2 5.5-5.2s4.9 1.8 5.5 5.2"/><circle cx="16.5" cy="9.5" r="2.4"/><path d="M15.6 14c2.4-.2 4.2 1.4 4.9 4.6"/>',
    book: '<path d="M3.5 6.5c3-1 5.8-.9 8.5.8v11.2c-2.7-1.6-5.5-1.8-8.5-.8z"/><path d="M20.5 6.5c-3-1-5.8-.9-8.5.8v11.2c2.7-1.6 5.5-1.8 8.5-.8z"/>',
    hourglass: '<path d="M7 4h10M7 20h10"/><path d="M8.2 4c0 4.6 3.8 5.6 3.8 8s-3.8 3.4-3.8 8M15.8 4c0 4.6-3.8 5.6-3.8 8s3.8 3.4 3.8 8"/>',
    check: '<path d="M6 12.6l3.8 3.6L18 8" stroke-width="2.4"/>',
    plus: '<path d="M12 6v12M6 12h12" stroke-width="2"/>'
  };

  function icon(name, size, mono) {
    size = size || 24;
    return '<svg class="gi' + (mono ? ' gi-mono' : '') + '" width="' + size + '" height="' + size + '" viewBox="0 0 24 24" aria-hidden="true" focusable="false">' + (ICONS[name] || '') + '</svg>';
  }

  // A szalag vége. A felső 2 px a test alá csúszik, így nincs varrat.
  function tail(kind) {
    var d = TAIL[kind], h = d + 2, lo = h - 0.75, a = 0.75, b = 27.25, fill, line;
    if (kind === 'story') {
      fill = 'M0 0H28V3L0 ' + h + 'Z';
      line = 'M' + a + ' 0V' + lo + 'L' + b + ' 3V0';
    } else if (kind === 'reward') {
      fill = 'M0 0H28V' + h + 'L14 2L0 ' + h + 'Z';
      line = 'M' + a + ' 0V' + lo + 'L14 2.6L' + b + ' ' + lo + 'V0';
    } else {
      fill = 'M0 0H28V' + h + 'H22V2H17V' + h + 'H11V2H6V' + h + 'H0Z';
      line = 'M' + a + ' 0V' + lo + 'H6V2.6H11V' + lo + 'H17V2.6H22V' + lo + 'H' + b + 'V0';
    }
    return '<svg class="gb-rb-tail" width="28" height="' + h + '" viewBox="0 0 28 ' + h + '" aria-hidden="true">' +
      '<path class="gb-rb-tail-fill" d="' + fill + '"/><path class="gb-rb-tail-line" d="' + line + '"/></svg>';
  }

  // kis szalagsziluett a panel kickeréhez
  function mini(kind) {
    var d = kind === 'story' ? 'M0 0H28V30L0 40Z' : kind === 'reward' ? 'M0 0H28V40L14 30L0 40Z' : 'M0 0H28V40H22V32H17V40H11V32H6V40H0Z';
    return '<svg class="gb-mini" width="10" height="14" viewBox="-2 -2 32 44" aria-hidden="true"><path d="' + d + '"/></svg>';
  }

  function norm(q) {
    var kind = TAIL[q.kind] ? q.kind : 'reward';
    return { kind: kind, reward: kind === 'story' ? 'story' : (q.reward === 'draw' ? 'draw' : 'coin') };
  }

  function ribbon(q) {
    q = q || {};
    var n = norm(q), kind = n.kind, reward = n.reward;
    var cls = 'gb-rb' + (q.done ? ' is-done' : '') + (q.state ? ' is-' + q.state : '');
    var inner = '<span class="gb-rb-body"></span>' + tail(kind);
    if (!q.plain) {
      if (q.progress && !q.done && q.progress.target > 1) {
        inner += '<span class="gb-rb-seam" style="--p:' + Math.min(1, q.progress.now / q.progress.target).toFixed(3) + '"></span>';
      }
      inner += q.done
        ? '<span class="gb-rb-seal">' + icon('check', 12) + '</span>'
        : '<span class="gb-rb-glyph">' + icon(REWARD_ICON[reward], 16, true) + '</span>';
      if (q.urgent && !q.done) inner += '<span class="gb-rb-urgent">' + icon('hourglass', 10, true) + '</span>';
    }
    var label = KIND_LABEL[kind] + (q.title ? ': ' + q.title : '') + (q.done ? ' — teljesítve' : '');
    return '<button type="button" class="' + cls + '" data-kind="' + kind + '" data-reward="' + reward + '"' +
      (q.id ? ' data-id="' + esc(q.id) + '"' : '') +
      ' style="--tail:var(' + TAIL_VAR[kind] + ',' + TAIL[kind] + 'px)' + (q.style ? ';' + q.style : '') + '"' +
      ' aria-label="' + esc(label) + '" aria-expanded="false">' + inner + '</button>';
  }

  function stat(kind, value) {
    return '<div class="gb-stat" data-stat="' + kind + '" data-value="' + value + '" title="' + STAT_LABEL[kind] + '">' +
      icon(kind, 24) + '<span class="gb-stat-n">' + fmt(value) + '</span></div>';
  }

  function button(label, o) {
    o = o || {};
    var cls = 'gb-btn' + (o.variant ? ' gb-btn-' + o.variant : '') + (o.size === 'sm' ? ' gb-btn-sm' : '') + (o.cls ? ' ' + o.cls : '');
    return '<button type="button" class="' + cls + '"' + (o.disabled ? ' disabled' : '') + (o.attrs ? ' ' + o.attrs : '') + '>' +
      (o.icon ? icon(o.icon, 20) : '') + esc(label) + '</button>';
  }

  function iconButton(name, label, o) {
    o = o || {};
    return '<button type="button" class="gb-btn gb-btn-icon' + (o.cls ? ' ' + o.cls : '') + '" aria-label="' + esc(label) + '"' + (o.attrs ? ' ' + o.attrs : '') + '>' + icon(name, 24) + '</button>';
  }

  function menuItem(ic, label, extra) {
    return '<button type="button" class="gb-dd-item" role="menuitem">' + icon(ic, 20) + '<span>' + esc(label) + '</span>' + (extra || '') + '</button>';
  }

  function menu(open) {
    return '<div class="gb-menu' + (open ? ' is-open' : '') + '">' +
      iconButton('menu', 'Menü', { attrs: 'aria-haspopup="menu" aria-expanded="' + (open ? 'true' : 'false') + '"' }) +
      '<div class="gb-dd" role="menu">' +
        '<div class="gb-dd-group">' + menuItem('people', 'Alpha Multiplayer', '<span class="gb-tag">ideiglenes</span>') + '</div>' +
        '<div class="gb-dd-group">' + menuItem('gear', 'Beállítások') + menuItem('help', 'Tutorial') + '</div>' +
        '<div class="gb-dd-group">' + menuItem('door', 'Kilépés') + '</div>' +
      '</div></div>';
  }

  function progress(p) {
    var now = Math.max(0, Math.min(p.now, p.target)), h = '<div class="gb-q-prog">';
    if (p.target <= 10) {
      for (var i = 0; i < p.target; i++) h += '<i class="gb-pip' + (i < now ? ' is-on' : '') + '"></i>';
    } else {
      h += '<span class="gb-track"><i style="width:' + (now / p.target * 100).toFixed(1) + '%"></i></span>';
    }
    return h + '<span class="gb-q-count">' + now + ' / ' + p.target + '</span></div>';
  }

  function rewardText(q, reward) {
    if (reward === 'story') return '<b>a történet folytatódik</b>' + icon('book', 18);
    return '<b>+' + fmt(q.amount || 0) + '</b>' + icon(reward, 18);
  }

  function panel(q) {
    var n = norm(q), h = '<div class="gb-panel-in">';
    h += '<div class="gb-q-kicker">' + mini(n.kind) + '<span>' + KIND_LABEL[n.kind] + '</span>';
    if (n.kind === 'daily' && q.timeLeft) {
      h += '<span class="gb-q-time' + (q.urgent ? ' is-urgent' : '') + '">' + (q.urgent ? icon('hourglass', 14, true) : '') + esc(q.timeLeft) + '</span>';
    }
    h += '</div>';
    if (q.title) h += '<h3 class="gb-q-title">' + esc(q.title) + '</h3>';
    if (q.text) h += '<p class="gb-q-text">' + q.text + '</p>';
    if (q.progress && q.progress.target > 1) h += progress(q.progress);
    h += '<div class="gb-q-foot"><div class="gb-q-reward"><span>Jutalom</span>' + rewardText(q, n.reward) + '</div>' +
      (q.done ? button('Begyűjtés', { variant: 'primary', size: 'sm', cls: 'gb-claim' }) : '') + '</div>';
    return h + '</div>';
  }

  function logo() {
    return '<span class="gb-logo">Golem<small>v0.1.4</small></span>';
  }

  function bar(o) {
    o = o || {};
    return '<div class="gb-bar">' +
      '<div class="gb-left">' + (o.left || '') + '</div>' +
      '<div class="gb-right">' +
        '<div class="gb-ribbons">' + (o.quests || []).map(ribbon).join('') + '</div>' +
        '<div class="gb-stats">' + (o.stats || []).map(function (s) { return stat(s[0], s[1]); }).join('') + '</div>' +
        menu(o.menuOpen) +
      '</div></div>';
  }

  // Élő sáv: szalag nyitása, menü, hozzáadás / eltűnés FLIP-csúszással.
  function mount(root, o) {
    o = o || {};
    var seq = 0;
    var quests = (o.quests || []).map(function (q) { q = Object.assign({}, q); q.id = q.id || 'q' + (++seq); return q; });
    root.innerHTML = '<div class="gb-stage"' + (o.height ? ' style="height:' + o.height + 'px"' : '') + '>' +
      bar(Object.assign({}, o, { quests: quests })) + '</div>';
    var stage = root.firstChild, barEl = stage.querySelector('.gb-bar'),
      rbs = barEl.querySelector('.gb-ribbons'), statsEl = barEl.querySelector('.gb-stats'),
      menuEl = barEl.querySelector('.gb-menu'), menuBtn = menuEl.querySelector('.gb-btn');
    var panelEl = document.createElement('div');
    panelEl.className = 'gb-panel';
    panelEl.setAttribute('role', 'region');
    barEl.appendChild(panelEl);
    var openId = null;

    function find(id) { for (var i = 0; i < quests.length; i++) if (quests[i].id === id) return quests[i]; return null; }
    function rbEl(id) { return rbs.querySelector('[data-id="' + id + '"]'); }

    function fit() {
      var el = openId && rbEl(openId);
      if (el) el.style.height = (barEl.offsetHeight + panelEl.offsetHeight) + 'px';
    }

    function open(id) {
      var q = find(id), el = rbEl(id);
      if (!q || !el) return;
      if (openId) close();
      setMenu(false);
      openId = id;
      panelEl.innerHTML = panel(q);
      panelEl.setAttribute('data-reward', el.getAttribute('data-reward'));
      panelEl.setAttribute('aria-label', el.getAttribute('aria-label'));
      var w = panelEl.offsetWidth, right = el.offsetLeft + el.offsetWidth;
      var toLeft = right + w > barEl.clientWidth;
      panelEl.classList.toggle('is-left', toLeft);
      panelEl.style.left = (toLeft ? el.offsetLeft - w : right) + 'px';
      rbs.classList.add('has-open');
      el.classList.add('is-open');
      el.setAttribute('aria-expanded', 'true');
      fit();
      panelEl.classList.add('is-open');
      var claim = panelEl.querySelector('.gb-claim');
      if (claim) claim.addEventListener('click', function (e) { e.stopPropagation(); remove(id, 'claim'); });
    }

    function close() {
      if (!openId) return;
      var el = rbEl(openId);
      if (el) { el.classList.remove('is-open'); el.setAttribute('aria-expanded', 'false'); el.style.height = ''; }
      rbs.classList.remove('has-open');
      panelEl.classList.remove('is-open');
      openId = null;
    }

    function setMenu(v) {
      menuEl.classList.toggle('is-open', v);
      menuBtn.setAttribute('aria-expanded', v ? 'true' : 'false');
    }

    function flip(mutate) {
      var els = [].slice.call(rbs.children).concat([].slice.call(statsEl.children));
      var before = els.map(function (el) { return el.offsetLeft; });
      mutate();
      els.forEach(function (el, i) {
        if (!el.isConnected) return;
        var dx = before[i] - el.offsetLeft;
        if (dx) el.animate([{ transform: 'translateX(' + dx + 'px)' }, { transform: 'translateX(0)' }], { duration: 280, easing: 'cubic-bezier(.2,.8,.2,1)' });
      });
    }

    function add(q) {
      q = Object.assign({}, q);
      q.id = 'q' + (++seq);
      close();
      quests.push(q);
      flip(function () { rbs.insertAdjacentHTML('beforeend', ribbon(q)); });
      var el = rbEl(q.id);
      el.classList.add('is-new');
      el.addEventListener('animationend', function done(ev) {
        if (ev.animationName === 'gb-drop') { el.classList.remove('is-new'); el.removeEventListener('animationend', done); }
      });
      return q.id;
    }

    function remove(id, how) {
      var el = rbEl(id);
      if (!el || el.classList.contains('is-leaving')) return;
      if (openId === id) close();
      quests = quests.filter(function (q) { return q.id !== id; });
      el.classList.add('is-leaving');
      var frames = how === 'expire'
        ? [{ opacity: 1, filter: 'grayscale(0)', transform: 'translateY(0)' },
           { opacity: 0.7, filter: 'grayscale(1)', transform: 'translateY(0)', offset: 0.45 },
           { opacity: 0, filter: 'grayscale(1)', transform: 'translateY(-40%)' }]
        : [{ transform: 'translateY(0)' }, { transform: 'translateY(8px)', offset: 0.25 }, { transform: 'translateY(-115%)' }];
      var ms = how === 'expire' ? 620 : 420;
      el.animate(frames, { duration: ms, easing: 'ease-in', fill: 'forwards' });
      after(ms, function () { flip(function () { el.remove(); }); });
    }

    // időzítő az onfinish helyett: rejtett lapon az animáció nem fut le
    function after(ms, fn) { setTimeout(fn, ms + 20); }

    function addStat(kind, value) {
      if (statsEl.querySelector('[data-stat="' + kind + '"]')) return;
      close();
      flip(function () { statsEl.insertAdjacentHTML('beforeend', stat(kind, value)); });
      statsEl.lastElementChild.classList.add('is-new');
    }

    function removeStat(kind) {
      var el = kind ? statsEl.querySelector('[data-stat="' + kind + '"]') : statsEl.lastElementChild;
      if (!el) return;
      close();
      el.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 160, fill: 'forwards' });
      after(160, function () { flip(function () { el.remove(); }); });
    }

    function bump(kind, delta) {
      var el = statsEl.querySelector('[data-stat="' + kind + '"]');
      if (!el) return;
      var n = el.querySelector('.gb-stat-n'), v = (+el.getAttribute('data-value') || 0) + delta;
      el.setAttribute('data-value', v);
      n.textContent = fmt(v);
      n.animate([{ transform: 'translateY(0)' }, { transform: 'translateY(-3px)' }, { transform: 'translateY(0)' }], { duration: 260, easing: 'ease-out' });
      var f = document.createElement('span');
      f.className = 'gb-float';
      f.setAttribute('data-stat', kind);
      f.textContent = (delta > 0 ? '+' : '−') + fmt(Math.abs(delta));
      el.appendChild(f);
      setTimeout(function () { f.remove(); }, 1200);
    }

    rbs.addEventListener('click', function (e) {
      var el = e.target.closest('.gb-rb');
      if (!el || el.classList.contains('is-leaving')) return;
      e.stopPropagation();
      var id = el.getAttribute('data-id');
      if (o.onRibbon) o.onRibbon(id, api); else if (openId === id) close(); else open(id);
    });
    panelEl.addEventListener('click', function (e) { e.stopPropagation(); });
    menuBtn.addEventListener('click', function (e) {
      e.stopPropagation();
      var v = !menuEl.classList.contains('is-open');
      if (v) close();
      setMenu(v);
    });
    menuEl.querySelector('.gb-dd').addEventListener('click', function (e) {
      e.stopPropagation();
      if (e.target.closest('.gb-dd-item')) setMenu(false);
    });
    document.addEventListener('click', function () { close(); setMenu(false); });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') { close(); setMenu(false); } });
    if (document.fonts && document.fonts.ready) document.fonts.ready.then(fit);

    var api = {
      open: open, close: close, add: add, remove: remove, addStat: addStat, removeStat: removeStat,
      bump: bump, setMenu: setMenu, list: function () { return quests.slice(); }, stage: stage, bar: barEl
    };
    return api;
  }

  window.Golem = {
    TAIL: TAIL, icon: icon, tail: tail, ribbon: ribbon, stat: stat, button: button, iconButton: iconButton,
    menu: menu, panel: panel, bar: bar, logo: logo, mount: mount, fmt: fmt
  };
})();
