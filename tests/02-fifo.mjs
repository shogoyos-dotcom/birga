import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 900 } });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
const D = '2026-11-24';

const base = (items, stock) => ({
  version: 1, currency: 'UZS', me: { id: 'me', name: 'Men' },
  accounts: [{ id: 'a', name: 'Naqd', opening: 0 }], categories: [],
  transactions: [], budget: { monthly: 0 }, groups: [], items, stock
});
const load = async (items, stock) => {
  await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
  await pg.evaluate(s => localStorage.setItem('birga_v1', JSON.stringify(s)), base(items, stock));
  await pg.reload({ waitUntil: 'domcontentloaded' });
  await pg.waitForTimeout(700);
  await pg.click('[data-screen="ombor"]');
  await pg.waitForTimeout(300);
};
const norm = s => s.replace(/\s+/g, ' ').replace(/−/g, '-');

// ---- 1-holat: foydalanuvchining o'z raqamlari ----
await load(
  [{ id: 'i1', name: 'Mix', unit: 'dona', min: 0 }],
  [
    { id: 'm1', itemId: 'i1', type: 'in', qty: 100000, price: 7, date: D, note: 'Nurik', txId: null },
    { id: 'm2', itemId: 'i1', type: 'out', qty: 85000, price: 25, date: D, note: 'Aziz', txId: null },
    { id: 'm3', itemId: 'i1', type: 'in', qty: 10000, price: 8, date: D, note: 'Nurik', txId: null }
  ]);
let t = norm(await pg.locator('#screen').textContent());
must(/Sotilganning tannarxi\s*595 000/.test(t), '1-holat · tannarx = 595 000 (85 000 × 7, eng eski partiyadan)');
must(/Foyda \(FIFO\)\s*\+1 530 000/.test(t), '1-holat · foyda = +1 530 000 (2 125 000 − 595 000)');
if (await pg.locator('[data-act="nav"][data-screen="items"]').count()) { await pg.click('[data-act="nav"][data-screen="items"]'); await pg.waitForTimeout(350); }
await pg.click('.row[data-act="open-item"]'); await pg.waitForTimeout(350);
t = norm(await pg.locator('#screen').textContent());
must(/Qoldiq qiymati\s*185 000/.test(t), '1-holat · qoldiq = 185 000 (15 000×7 + 10 000×8), o‘rtachada 177 273 edi');
must(/Sotuv summasi\s*2 125 000/.test(t), '1-holat · sotuv = 2 125 000');
must(/foyda \+1 530 000/.test(t), '1-holat · rasxod qatorida foyda ko‘rinadi');
await pg.screenshot({ path: (process.argv[2] || '.') + '/f-fifo.png' });

// ---- 2-holat: bitta sotuv ikki partiyadan yechiladi ----
await load(
  [{ id: 'i1', name: 'Bolt', unit: 'dona', min: 0 }],
  [
    { id: 'm1', itemId: 'i1', type: 'in', qty: 10, price: 100, date: '2026-11-01', txId: null },
    { id: 'm2', itemId: 'i1', type: 'in', qty: 10, price: 200, date: '2026-11-02', txId: null },
    { id: 'm3', itemId: 'i1', type: 'out', qty: 15, price: 300, date: '2026-11-03', txId: null }
  ]);
if (await pg.locator('[data-act="nav"][data-screen="items"]').count()) { await pg.click('[data-act="nav"][data-screen="items"]'); await pg.waitForTimeout(350); }
await pg.click('.row[data-act="open-item"]'); await pg.waitForTimeout(350);
t = norm(await pg.locator('#screen').textContent());
must(/Sotilganning tannarxi\s*2 000/.test(t), '2-holat · tannarx = 2 000 (10×100 + 5×200)');
must(/Foyda \(FIFO\)\s*\+2 500/.test(t), '2-holat · foyda = +2 500 (4 500 − 2 000)');
must(/Qoldiq qiymati\s*1 000/.test(t), '2-holat · qoldiq = 1 000 (5 × 200, qimmat partiya qoldi)');

// ---- 3-holat: qoldiqsiz sotuv ----
await load(
  [{ id: 'i1', name: 'Gayka', unit: 'dona', min: 0 }],
  [
    { id: 'm1', itemId: 'i1', type: 'in', qty: 5, price: 100, date: '2026-11-01', txId: null },
    { id: 'm2', itemId: 'i1', type: 'out', qty: 10, price: 300, date: '2026-11-02', txId: null }
  ]);
if (await pg.locator('[data-act="nav"][data-screen="items"]').count()) { await pg.click('[data-act="nav"][data-screen="items"]'); await pg.waitForTimeout(350); }
await pg.click('.row[data-act="open-item"]'); await pg.waitForTimeout(350);
t = norm(await pg.locator('#screen').textContent());
must(/Sotilganning tannarxi\s*500/.test(t), '3-holat · tannarx = 500 (bori shu)');
must(/qoldiqsiz sotilgan/.test(t), '3-holat · qoldiqsiz sotuv haqida ogohlantirish bor');

// ---- 4-holat: eski sana keyin kiritilsa ham oldin ketadi ----
await load(
  [{ id: 'i1', name: 'Vint', unit: 'dona', min: 0 }],
  [
    { id: 'm1', itemId: 'i1', type: 'in', qty: 10, price: 500, date: '2026-11-10', txId: null },
    { id: 'm2', itemId: 'i1', type: 'in', qty: 10, price: 100, date: '2026-11-01', txId: null },
    { id: 'm3', itemId: 'i1', type: 'out', qty: 10, price: 900, date: '2026-11-20', txId: null }
  ]);
if (await pg.locator('[data-act="nav"][data-screen="items"]').count()) { await pg.click('[data-act="nav"][data-screen="items"]'); await pg.waitForTimeout(350); }
await pg.click('.row[data-act="open-item"]'); await pg.waitForTimeout(350);
t = norm(await pg.locator('#screen').textContent());
must(/Sotilganning tannarxi\s*1 000/.test(t), '4-holat · sana bo‘yicha eng eskisi (1-noyabr, 100 so‘m) ketdi');
must(/Qoldiq qiymati\s*5 000/.test(t), '4-holat · qoldiq = 10 × 500');

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
