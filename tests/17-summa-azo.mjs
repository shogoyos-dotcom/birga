import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
// serviceWorkers: 'block' — pastdagi sahifa patchi page.route ga tayanadi (tests/README.md)
const pg = await b.newPage({ viewport: { width: 390, height: 1000 }, hasTouch: true, isMobile: true,
                             serviceWorkers: 'block' });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });

await pg.route('**/index.html*', async route => {
  const res = await route.fetch();
  const body = (await res.text()).replace('var SB=null, SB_UID=null,', "var SB=null, SB_UID='u1',");
  await route.fulfill({ response: res, body });
});
await pg.route('**/supabase*.js', r => r.abort());

const now = new Date(), ym = now.toISOString().slice(0, 7);
const dd = n => ym + '-' + String(n).padStart(2, '0');

// ========== 1) IZOH TAKLIFLARI va SUMMA ↔ NARX ==========
await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.evaluate(o => localStorage.setItem('birga_v1', JSON.stringify({
  version: 1, currency: 'UZS', me: { id: 'me', name: 'Men' },
  accounts: [{ id: 'a', name: 'Naqd', opening: 0 }], categories: [],
  transactions: [], budget: { monthly: 0 }, groups: [],
  items: [{ id: 'i1', name: 'Etiketka', unit: 'dona', min: 0 }],
  stock: [
    { id: 's1', itemId: 'i1', type: 'in', qty: 100, price: 6, date: o.d3, note: 'Nurik', txId: null },
    { id: 's2', itemId: 'i1', type: 'in', qty: 50,  price: 7, date: o.d5, note: 'Aziz erkinov', txId: null },
    // takrorlangan izoh ikki marta chiqmasin
    { id: 's3', itemId: 'i1', type: 'in', qty: 10,  price: 7, date: o.d5, note: 'Nurik', txId: null }
  ]
})), { d3: dd(3), d5: dd(5) });
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
await pg.click('[data-screen="ombor"]'); await pg.waitForTimeout(400);
await pg.click('#fab'); await pg.waitForTimeout(600);

const hints = await pg.locator('#modal #notehints option').evaluateAll(o => o.map(x => x.value));
must(hints.length === 2, 'Takrorlangan izoh bir marta: ' + JSON.stringify(hints));
must(hints[0] === 'Nurik', 'Eng oxirgi izoh birinchi turadi');
must(hints.indexOf('Aziz erkinov') >= 0, 'Oldingi izohlar ham taklifda');
must(await pg.locator('#modal input[name="note"]').getAttribute('list') === 'notehints',
     'Izoh maydoni taklif ro‘yxatiga ulangan');

const qty = pg.locator('#modal input[name="qty"]');
const price = pg.locator('#modal input[name="price"]');
const tot = pg.locator('#modal input[name="total"]');
must(await tot.count() === 1, '«Summa (jami)» maydoni bor');
must(await price.inputValue() === '7', 'Narx oxirgisidan to‘lgan (7)');
must(await tot.inputValue() === '', 'Miqdor yo‘q ekan — summa bo‘sh');

await qty.fill('100'); await pg.waitForTimeout(250);
must(await tot.inputValue() === '700', 'Miqdor yozilsa summa chiqadi: 100 × 7 = 700');
await price.fill('8'); await pg.waitForTimeout(250);
must(await tot.inputValue() === '800', 'Narx o‘zgarsa summa ham: 100 × 8 = 800');

// summani yozsa — dona narxi chiqsin
await tot.fill('1200'); await pg.waitForTimeout(250);
must(await price.inputValue() === '12', 'Summa yozilsa dona narxi chiqadi: 1200 ÷ 100 = 12');
await qty.fill('30'); await pg.waitForTimeout(250);
must(await tot.inputValue() === '360', 'Miqdor o‘zgarsa summa qayta hisoblanadi: 30 × 12 = 360');
await pg.screenshot({ path: (process.argv[2] || '.') + '/s-summa.png' });

// saqlanganda narx va miqdor to'g'ri tushsin
await pg.fill('#modal input[name="note"]', 'Nurik');
await pg.click('#modal button[type="submit"]'); await pg.waitForTimeout(600);
const saved = await pg.evaluate(() => {
  const st = JSON.parse(localStorage.getItem('birga_v1'));
  return st.stock[st.stock.length - 1];
});
must(saved.qty === 30 && saved.price === 12 && saved.note === 'Nurik',
     'Saqlandi: ' + JSON.stringify({ q: saved.qty, p: saved.price, n: saved.note }));

// ========== 2) A'ZO USTIGA BOSILGANDA ==========
const ME = '__me__';
const grp = {
  id: 'g1', name: 'ETIKETKA', currency: 'UZS', meMemberId: ME,
  members: [{ id: ME, name: 'Men', role: 'owner', user_id: 'u1' },
            { id: 'm2', name: 'Aziz', role: 'editor', user_id: 'u2' },
            { id: 'm3', name: 'Bek', role: 'viewer', user_id: 'u3' }],
  expenses: [
    { id: 'e1', type: 'expense', title: 'Qog‘oz', amount: 600000, paidBy: ME, date: dd(10),
      splits: [{ memberId: 'm2', share: 400000 }, { memberId: 'm3', share: 200000 }] },
    { id: 'e2', type: 'expense', title: 'Ijara', amount: 300000, paidBy: 'm2', date: dd(12),
      splits: [{ memberId: ME, share: 150000 }, { memberId: 'm2', share: 150000 }] },
    { id: 'e3', type: 'income', title: 'Buyurtma', amount: 500000, paidBy: 'm2', date: dd(14),
      splits: [{ memberId: 'm2', share: 500000 }] }
  ],
  settlements: [], items: [], stock: []
};
await pg.evaluate(o => {
  localStorage.setItem('birga_v1', JSON.stringify({
    version: 1, currency: 'UZS', me: { id: 'me', name: 'Men' },
    accounts: [{ id: 'a', name: 'Naqd', opening: 0 }], categories: [],
    transactions: [], budget: { monthly: 0 }, groups: [o.g], items: [], stock: []
  }));
  localStorage.setItem('birga_groups_cache', JSON.stringify([o.g]));
}, { g: grp });
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(1000);
await pg.click('[data-screen="groups"]'); await pg.waitForTimeout(400);
await pg.click('.row.tap'); await pg.waitForTimeout(500);
await pg.click('[data-act="gtab"][data-tab="balances"]'); await pg.waitForTimeout(500);

must(await pg.locator('[data-act="member-view"]').count() === 3, 'Uchala a‘zo qatori ham bosiladi');
must(/3 ta amaliyot/.test(await pg.locator('#screen').textContent()), 'Qatorda nechta amaliyoti yozilgan');

await pg.locator('[data-act="member-view"]', { hasText: 'Aziz' }).first().evaluate(e => e.click());
await pg.waitForTimeout(600);
let t = (await pg.locator('#modal').textContent()).replace(/\s+/g, ' ');
// Aziz: −400 000 (Qog'oz ulushi) + 300 000 − 150 000 (Ijara) + 0 (tushum) = −250 000
must(/−250 000/.test(t), 'Balansi −250 000');
must(/U qaytaradi\s*250 000/.test(t), 'Qaysi tomonga qarzdorligi yozilgan');
must(/Qatnashgan amaliyoti\s*3/.test(t), 'Uchala amaliyotda ham qatnashgan');
must(/U to‘lagan \(xarajat\)\s*300 000/.test(t), 'U to‘lagan xarajat 300 000');
must(/Uning ulushi \(xarajat\)\s*550 000/.test(t), 'Uning ulushi 550 000 (400 000 + 150 000)');
must(/U qabul qilgan \(tushum\)\s*500 000/.test(t), 'Tushumni u qabul qilgan');
must(/Qog‘oz/.test(t) && /Ijara/.test(t) && /Buyurtma/.test(t), 'Uchala amaliyot ro‘yxatda');
// qator ichida nom bilan sana orasida bo'sh joy yo'q — \s* bilan
must(/Buyurtma\s*14-noy/.test(t) && t.indexOf('Buyurtma') < t.indexOf('Ijara')
     && t.indexOf('Ijara') < t.indexOf('Qog‘oz'), 'Yangisidan eskisiga tartiblangan');
must(/ulushi 400 000/.test(t), 'Har amaliyotda uning ulushi ko‘rinadi');
await pg.screenshot({ path: (process.argv[2] || '.') + '/s-azo.png' });

// ro'yxatdagi amaliyotni bosganda o'sha amaliyot ochilsin
await pg.locator('#modal [data-act="entry-view"]', { hasText: 'Ijara' }).first().evaluate(e => e.click());
await pg.waitForTimeout(600);
t = (await pg.locator('#modal').textContent()).replace(/\s+/g, ' ');
must(/Bo‘linishi/.test(t) && /Kim to‘ladi\s*Aziz/.test(t), 'Amaliyot ustiga bosilsa o‘sha amaliyot ochiladi');

// qatnashmagan a'zo
await pg.locator('#modal .close-x').evaluate(e => e.click());
await pg.waitForFunction(() => { const m = document.getElementById('modal'); return m && m.hidden; });
await pg.waitForTimeout(300);
await pg.evaluate(() => {
  const st = JSON.parse(localStorage.getItem('birga_v1'));
  st.groups[0].expenses = [];
  localStorage.setItem('birga_v1', JSON.stringify(st));
  localStorage.setItem('birga_groups_cache', JSON.stringify(st.groups));
});
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
await pg.click('[data-screen="groups"]'); await pg.waitForTimeout(400);
await pg.click('.row.tap'); await pg.waitForTimeout(500);
await pg.click('[data-act="gtab"][data-tab="balances"]'); await pg.waitForTimeout(500);
await pg.locator('[data-act="member-view"]', { hasText: 'Bek' }).first().evaluate(e => e.click());
await pg.waitForTimeout(600);
must(/hech qaysi amaliyotda qatnashmagan/.test(await pg.locator('#modal').textContent()),
     'Amaliyoti yo‘q a‘zoga tushunarli xabar');

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
