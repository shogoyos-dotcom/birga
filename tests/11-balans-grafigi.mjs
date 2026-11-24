import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 950 } });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });

// Shoxrux hammasini to'lagan → unga qaytariladi (yashil, tepada),
// qolgan uchtasi qarzdor (qizil, pastda).
const grp = {
  id: 'g1', name: 'ETIKETKA', currency: 'UZS', meMemberId: 'me',
  members: [
    { id: 'me', name: 'Shoxrux',  role: 'owner',  user_id: 'u1' },
    { id: 'm2', name: 'Etiketka', role: 'editor', user_id: 'u2' },
    { id: 'm3', name: 'Izzat',    role: 'viewer', user_id: 'u3' },
    { id: 'm4', name: 'Ismoil',   role: 'viewer', user_id: 'u4' }
  ],
  expenses: [
    { id: 'e1', type: 'expense', title: 'Qarz', amount: 495438, paidBy: 'me', date: '2026-11-24', splits: [{ memberId: 'm2', share: 495438 }] },
    { id: 'e2', type: 'expense', title: 'Qarz', amount: 13065,  paidBy: 'me', date: '2026-11-24', splits: [{ memberId: 'm4', share: 13065 }] },
    { id: 'e3', type: 'expense', title: 'Qarz', amount: 59760,  paidBy: 'me', date: '2026-11-24', splits: [{ memberId: 'm3', share: 59760 }] }
  ],
  settlements: [], items: [], stock: []
};
await pg.route('**/supabase*.js', r => r.abort());
await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.evaluate(g => {
  localStorage.setItem('birga_v1', JSON.stringify({
    version: 1, currency: 'UZS', me: { id: 'me', name: 'Shoxrux' },
    accounts: [{ id: 'a', name: 'Naqd', opening: 0 }], categories: [],
    transactions: [], budget: { monthly: 0 }, groups: [g], items: [], stock: []
  }));
  localStorage.setItem('birga_groups_cache', JSON.stringify([g]));
}, grp);
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
await pg.click('[data-screen="groups"]'); await pg.waitForTimeout(400);
await pg.click('.row.tap'); await pg.waitForTimeout(600);

const card = pg.locator('.card', { hasText: 'Kim qancha' });
must(await card.count() === 1, '«Kim qancha» grafigi bor');
must(await card.locator('svg').count() === 1, 'Ichida SVG bor');

// yashil = puli bor (tepada), qizil = qarzdor (pastda)
const green = card.locator('path[style*="ch-in"]');
const red   = card.locator('path[style*="ch-out"]');
must(await green.count() === 1, 'Bitta yashil ustun (Shoxruxga qaytariladi)');
must(await red.count() === 3,   'Uchta qizil ustun (qarzdorlar)');

// nol chizig'i va ustunlarning tomoni
const geo = await card.evaluate(el => {
  const z = el.querySelector('svg line');
  const zy = parseFloat(z.getAttribute('y1'));
  const box = p => { const b = p.getBBox(); return { top: b.y, bottom: b.y + b.height }; };
  return {
    zeroY: zy,
    green: [...el.querySelectorAll('path[style*="ch-in"]')].map(box),
    red:   [...el.querySelectorAll('path[style*="ch-out"]')].map(box)
  };
});
must(geo.green.every(g => g.bottom <= geo.zeroY + 0.5), 'Yashil ustunlar nol chizig‘idan TEPADA');
must(geo.red.every(r => r.top >= geo.zeroY - 0.5),      'Qizil ustunlar nol chizig‘idan PASTDA');

// eng kattasi to'liq balandlikda, kichigi kichik
must(geo.green[0].bottom - geo.green[0].top > 50, 'Eng katta balans to‘liq balandlikda');
const reds = geo.red.map(r => r.bottom - r.top).sort((a, b) => b - a);
must(reds[0] > reds[2], 'Qarzi kattaroqning ustuni ham uzunroq');

const t = await card.textContent();
must(/Puli bor/.test(t) && /Qarzdor/.test(t), 'Izoh (legenda) bor: Puli bor / Qarzdor');
must(/Shoxrux/.test(t) && /Izzat/.test(t) && /Ismoil/.test(t), 'A‘zo ismlari yozilgan');
must(/\+568 ming/.test(t), 'Yashil ustunda summa: +568 ming');
must(/−495 ming/.test(t), 'Qizil ustunda summa: −495 ming');

// hamma hisobi teng bo'lsa grafik chiqmasin
await pg.evaluate(() => {
  const st = JSON.parse(localStorage.getItem('birga_v1'));
  st.groups[0].expenses = [];
  localStorage.setItem('birga_v1', JSON.stringify(st));
  localStorage.setItem('birga_groups_cache', JSON.stringify(st.groups));
});
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
await pg.click('[data-screen="groups"]'); await pg.waitForTimeout(400);
await pg.click('.row.tap'); await pg.waitForTimeout(600);
must(!/Kim qancha/.test(await pg.locator('#screen').textContent()), 'Hamma teng bo‘lsa grafik chiqmaydi');

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
