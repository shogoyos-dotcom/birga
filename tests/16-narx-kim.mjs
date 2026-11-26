import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
// serviceWorkers: 'block' — SW sahifa marshrutlarini chetlab o'tadi, quyidagi
// patch esa aynan shu marshrutga tayanadi
const pg = await b.newPage({ viewport: { width: 390, height: 1000 }, hasTouch: true, isMobile: true,
                             serviceWorkers: 'block' });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });

// guruhning ega oynalari uchun kirgan foydalanuvchini taqlid qilamiz (tests/README.md)
await pg.route('**/index.html*', async route => {
  const res = await route.fetch();
  const body = (await res.text()).replace('var SB=null, SB_UID=null,', "var SB=null, SB_UID='u1',");
  // keshga tushsa keyingi yuklashda patchsiz HTML qaytadi
  const headers = Object.assign({}, res.headers(), { 'cache-control': 'no-store' });
  await route.fulfill({ response: res, body, headers });
});
await pg.route('**/supabase*.js', r => r.abort());

// modal yopilishini kutamiz — aks holda scrim keyingi bosishni to'sadi
const closeSheet = async () => {
  await pg.locator('#modal .close-x').evaluate(e => e.click());
  await pg.waitForFunction(() => { const m = document.getElementById('modal'); return m && m.hidden; }, null, { timeout: 5000 });
  await pg.waitForTimeout(200);
};

const now = new Date(), ym = now.toISOString().slice(0, 7);
const dd = n => ym + '-' + String(n).padStart(2, '0');

// ================= 1) NARX ESLAB QOLINADI =================
await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.evaluate(o => localStorage.setItem('birga_v1', JSON.stringify({
  version: 1, currency: 'UZS', me: { id: 'me', name: 'Men' },
  accounts: [{ id: 'a', name: 'Naqd', opening: 0 }], categories: [],
  transactions: [], budget: { monthly: 0 }, groups: [],
  items: [{ id: 'i1', name: 'Etiketka', unit: 'dona', min: 0 },
          { id: 'i2', name: 'Skotch',   unit: 'dona', min: 0 }],
  stock: [
    { id: 's1', itemId: 'i1', type: 'in',  qty: 100, price: 8500,  date: o.d3, txId: null },
    { id: 's2', itemId: 'i1', type: 'out', qty: 40,  price: 15000, date: o.d7, txId: null },
    { id: 's3', itemId: 'i2', type: 'in',  qty: 50,  price: 3000,  date: o.d5, txId: null }
  ]
})), { d3: dd(3), d5: dd(5), d7: dd(7) });
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
await pg.click('[data-screen="ombor"]'); await pg.waitForTimeout(400);
await pg.click('#fab'); await pg.waitForTimeout(600);

const price = pg.locator('#modal input[name="price"]');
must(await price.inputValue() === '8500', 'Yangi prihodda oxirgi kirim narxi o‘zi turadi (8500)');
must(await pg.locator('#modal input[name="qty"]').inputValue() === '', 'Miqdor esa bo‘sh qoladi');

await pg.click('#modal #mseg button[data-t="out"]'); await pg.waitForTimeout(300);
must(await price.inputValue() === '15000', 'Rasxodga o‘tilsa — oxirgi SOTISH narxi (15000)');

await pg.selectOption('#modal select[name="itemId"]', 'i2'); await pg.waitForTimeout(300);
must(await price.inputValue() === '', 'Sotilmagan tovarda narx bo‘sh');

await pg.click('#modal #mseg button[data-t="in"]'); await pg.waitForTimeout(300);
must(await price.inputValue() === '3000', 'O‘sha tovarning kirim narxi (3000)');

// qo'lda yozilgan narxga tegilmasin
await price.fill('9999');
await pg.selectOption('#modal select[name="itemId"]', 'i1'); await pg.waitForTimeout(300);
must(await price.inputValue() === '9999', 'Qo‘lda yozilgan narx saqlanadi — ustiga yozilmaydi');

// taklif qilingan narx bilan saqlansa ham to'g'ri yozilsin
await price.fill(''); await pg.waitForTimeout(200);
await pg.selectOption('#modal select[name="itemId"]', 'i2'); await pg.waitForTimeout(300);
await pg.fill('#modal input[name="qty"]', '7');
await pg.click('#modal button[type="submit"]'); await pg.waitForTimeout(600);
const last = await pg.evaluate(() => {
  const st = JSON.parse(localStorage.getItem('birga_v1'));
  return st.stock[st.stock.length - 1];
});
must(last.itemId === 'i2' && last.qty === 7 && last.price === 3000,
     'Taklif qilingan narx bilan saqlandi: ' + JSON.stringify({ q: last.qty, p: last.price }));
await pg.screenshot({ path: (process.argv[2] || '.') + '/n-narx.png' });

// ================= 2) KIM VA QACHON =================
const ME = '__me__';
const grp = {
  id: 'g1', name: 'ETIKETKA', currency: 'UZS', meMemberId: ME,
  members: [{ id: ME, name: 'Men', role: 'owner', user_id: 'u1' },
            { id: 'm2', name: 'Aziz', role: 'editor', user_id: 'u2' }],
  expenses: [
    { id: 'e1', type: 'expense', title: 'Qog‘oz', amount: 500000, paidBy: ME, date: dd(10),
      splits: [{ memberId: 'm2', share: 500000 }],
      createdAt: '2026-11-24T09:15:00Z', createdBy: 'u2',
      updatedAt: '2026-11-25T14:40:00Z', updatedBy: 'u1' },
    // hech kim o'zgartirmagan
    { id: 'e2', type: 'expense', title: 'Bo‘yoq', amount: 100000, paidBy: ME, date: dd(11),
      splits: [{ memberId: 'm2', share: 100000 }],
      createdAt: '2026-11-26T06:00:00Z', createdBy: 'u1' }
  ],
  settlements: [],
  items: [{ id: 'gi1', name: 'Plyonka', unit: 'metr', min: 0 }],
  stock: [{ id: 'gs1', itemId: 'gi1', type: 'in', qty: 10, price: 1000, date: dd(9), txId: null,
            createdAt: '2026-11-23T07:05:00Z', createdBy: 'u2' }]
};
await pg.evaluate(o => {
  localStorage.setItem('birga_v1', JSON.stringify({
    version: 1, currency: 'UZS', me: { id: 'me', name: 'Men' },
    accounts: [{ id: 'a', name: 'Naqd', opening: 0 }], categories: [],
    transactions: [], budget: { monthly: 0 }, groups: [o.g],
    items: [], stock: [], settings: { omborScope: 'g1' }
  }));
  localStorage.setItem('birga_groups_cache', JSON.stringify([o.g]));
}, { g: grp });
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(1000);
await pg.click('[data-screen="groups"]'); await pg.waitForTimeout(400);
await pg.click('.row.tap'); await pg.waitForTimeout(500);

// o'zgartirilgan amaliyot
await pg.locator('.row.tap[data-act="edit-expense"]', { hasText: 'Qog‘oz' }).first().evaluate(e => e.click());
await pg.waitForTimeout(600);
let t = (await pg.locator('#modal').textContent()).replace(/\s+/g, ' ');
must(/Qo‘shdi\s*Aziz · 24-noy 09:15/.test(t), 'Kim qo‘shgani va qachoni: Aziz · 24-noy 09:15');
must(/O‘zgartirdi\s*Men · 25-noy 14:40/.test(t), 'Kim o‘zgartirgani: Men · 25-noy 14:40');
await pg.screenshot({ path: (process.argv[2] || '.') + '/n-kim.png' });
await closeSheet();

// o'zgartirilmagan amaliyotda «O'zgartirdi» qatori bo'lmasin
await pg.locator('.row.tap[data-act="edit-expense"]', { hasText: 'Bo‘yoq' }).first().evaluate(e => e.click());
await pg.waitForTimeout(600);
t = (await pg.locator('#modal').textContent()).replace(/\s+/g, ' ');
must(/Qo‘shdi\s*Men · 26-noy/.test(t), 'Ikkinchisini men qo‘shganman');
must(!/O‘zgartirdi/.test(t), 'O‘zgartirilmagan bo‘lsa — o‘sha qator chiqmaydi');
await closeSheet();

// ombor harakatida ham
await pg.click('[data-screen="ombor"]'); await pg.waitForTimeout(600);
await pg.click('[data-act="nav"][data-screen="items"]'); await pg.waitForTimeout(500);
await pg.locator('.row[data-act="open-item"]').first().evaluate(e => e.click()); await pg.waitForTimeout(500);
await pg.locator('.row[data-act="move-view"]').first().evaluate(e => e.click()); await pg.waitForTimeout(600);
t = (await pg.locator('#modal').textContent()).replace(/\s+/g, ' ');
must(/Qo‘shdi\s*Aziz · 23-noy 07:05/.test(t), 'Ombor harakatida ham: Aziz · 23-noy 07:05');
await pg.screenshot({ path: (process.argv[2] || '.') + '/n-ombor.png' });

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
