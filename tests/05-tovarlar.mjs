import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 900 } });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });

const D = '2026-11-24', D2 = '2026-11-20';
const items = [
  { id: 'i1', name: 'Shakar', unit: 'kg', min: 100 },
  { id: 'i2', name: 'Anor', unit: 'dona', min: 0 },
  { id: 'i3', name: 'Mix', unit: 'dona', min: 0 }
];
const stock = [
  // Shakar: 100 @ 10 000 → sotildi 60 @ 15 000 ; qoldiq 40 × 10 000 = 400 000 ; foyda 900 000 - 600 000 = 300 000
  { id: 's1', itemId: 'i1', type: 'in', qty: 100, price: 10000, date: D2, txId: null },
  { id: 's2', itemId: 'i1', type: 'out', qty: 60, price: 15000, date: D, txId: null },
  // Anor: 10 @ 5 000, hech narsa sotilmagan ; qoldiq 50 000
  { id: 's3', itemId: 'i2', type: 'in', qty: 10, price: 5000, date: D2, txId: null },
  // Mix: 1000 @ 7 → sotildi 900 @ 5 (zarar) ; qoldiq 100×7=700 ; foyda 4500-6300 = -1800
  { id: 's4', itemId: 'i3', type: 'in', qty: 1000, price: 7, date: D2, txId: null },
  { id: 's5', itemId: 'i3', type: 'out', qty: 900, price: 5, date: D, txId: null }
];
await pg.route('**/supabase*.js', r => r.abort());
await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.evaluate(d => localStorage.setItem('birga_v1', JSON.stringify({
  version: 1, currency: 'UZS', me: { id: 'me', name: 'Men' },
  accounts: [{ id: 'a', name: 'Naqd', opening: 0 }], categories: [{ id: 'c1', name: 'Oylik', kind: 'income' }],
  transactions: [{ id: 't1', accountId: 'a', categoryId: 'c1', amount: 1000000, type: 'income', note: '', date: '2026-11-05' }],
  budget: { monthly: 0 }, groups: [], items: d.items, stock: d.stock
})), { items, stock });
await pg.reload({ waitUntil: 'domcontentloaded' });
await pg.waitForTimeout(800);

// ---------- OMBOR bosh ekrani ----------
await pg.click('[data-screen="ombor"]'); await pg.waitForTimeout(400);
let t = await pg.locator('#screen').textContent();
must(/Tovarlar \(3\)/.test(t), 'Omborda «Tovarlar (3)» tugmasi bor');
must(/⚠ 1/.test(t), 'Tugmada kam qolgan soni ko‘rinadi');
must(await pg.locator('.bltrack span').count() >= 3, 'Omborda grafik bor: ' + await pg.locator('.bltrack span').count() + ' ta ustun');
must(await pg.locator('#omsearch').count() === 0 && await pg.locator('.row[data-act="open-item"]').count() === 0, 'Ro‘yxat va qidiruv bosh ekrandan olindi');
await pg.screenshot({ path: (process.argv[2] || '.') + '/y-ombor.png' });

// grafik: qiymat → foyda
const valW = await pg.locator('.bltrack span').first().evaluate(e => e.style.width);
await pg.click('[data-act="schart"][data-m="profit"]'); await pg.waitForTimeout(400);
t = await pg.locator('#screen').textContent();
must(/\+300 000/.test(t), 'Foyda grafigida Shakar +300 000');
must(/−1 800|-1 800/.test(t), 'Zarar ham ko‘rinadi (Mix −1 800)');
const cols = await pg.$$eval('.bltrack span', e => [...new Set(e.map(x => getComputedStyle(x).backgroundColor))]);
must(cols.length === 2, 'Foyda yashil, zarar qizil: ' + cols.join(' / '));
await pg.screenshot({ path: (process.argv[2] || '.') + '/y-foyda.png' });
await pg.click('[data-act="schart"][data-m="value"]'); await pg.waitForTimeout(300);

// ---------- TOVARLAR ro'yxati ----------
await pg.click('[data-act="nav"][data-screen="items"]'); await pg.waitForTimeout(400);
t = await pg.locator('#screen').textContent();
must(await pg.locator('#omsearch').count() === 1, 'Tovarlar ekranida qidiruv bor');
must(await pg.locator('#omsort option').count() >= 8, 'Saralash ro‘yxatida variantlar bor: ' + await pg.locator('#omsort option').count());
const names = () => pg.$$eval('.row .t', e => e.map(x => x.textContent.replace(/\s*⚠/, '').trim()));
must(JSON.stringify(await names()) === JSON.stringify(['Anor', 'Mix', 'Shakar']), 'Boshida alifbo tartibida: ' + (await names()).join(', '));

await pg.selectOption('#omsort', 'qty-d'); await pg.waitForTimeout(400);
must(JSON.stringify(await names()) === JSON.stringify(['Mix', 'Shakar', 'Anor']), 'Qoldiq ko‘pdan kamga: ' + (await names()).join(', '));
await pg.selectOption('#omsort', 'price-d'); await pg.waitForTimeout(400);
must((await names())[0] === 'Shakar', 'Narxi qimmatdan: birinchi Shakar (10 000)');
await pg.selectOption('#omsort', 'profit-d'); await pg.waitForTimeout(400);
let n = await names();
must(n[0] === 'Shakar' && n[n.length - 1] === 'Mix', 'Foyda bo‘yicha: Shakar birinchi, zararli Mix oxirida');
must(/foyda \+300 000/.test(await pg.locator('#screen').textContent()), 'Foyda tartibida qator ostida foyda yoziladi');
await pg.selectOption('#omsort', 'value-d'); await pg.waitForTimeout(400);
must((await names())[0] === 'Shakar', 'Qoldiq qiymati bo‘yicha: Shakar (400 000) birinchi');
await pg.screenshot({ path: (process.argv[2] || '.') + '/y-tovarlar.png' });

// saralash saqlanadimi
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(800);
await pg.click('[data-screen="ombor"]'); await pg.waitForTimeout(300);
await pg.click('[data-act="nav"][data-screen="items"]'); await pg.waitForTimeout(400);
must(await pg.locator('#omsort').inputValue() === 'value-d', 'Saralash tanlovi saqlanadi');

// filtrlar
await pg.click('.chip[data-act="sfilter"][data-f="low"]'); await pg.waitForTimeout(400);
must(JSON.stringify(await names()) === JSON.stringify(['Shakar']), 'Kam qolgan filtri: faqat Shakar (40 < 100)');
await pg.click('.chip[data-act="sfilter"][data-f="profit"]'); await pg.waitForTimeout(400);
must(JSON.stringify(await names()) === JSON.stringify(['Shakar']), 'Foyda keltirgan filtri ishlaydi');
await pg.click('.chip[data-act="sfilter"][data-f="all"]'); await pg.waitForTimeout(300);

// qidiruv
await pg.fill('#omsearch', 'ano'); await pg.waitForTimeout(500);
must(JSON.stringify(await names()) === JSON.stringify(['Anor']), 'Qidiruv ishlaydi');
await pg.fill('#omsearch', ''); await pg.waitForTimeout(400);

// tovardan orqaga → Tovarlar
await pg.click('.row[data-act="open-item"]'); await pg.waitForTimeout(400);
must(/‹ Tovarlar/.test(await pg.locator('.back-btn').textContent()), 'Tovar ekranidan orqaga — Tovarlar ro‘yxatiga');

// ---------- 1 oylik grafik ----------
await pg.click('[data-screen="home"]'); await pg.waitForTimeout(400);
must(await pg.locator('[data-act="chmon"][data-n="1"]').count() > 0, 'Asosiyda «1 oy» tugmachasi bor');
await pg.click('[data-act="chmon"][data-n="1"]'); await pg.waitForTimeout(400);
must(/— kunlar/.test(await pg.locator('#screen').textContent()), '1 oyga o‘tdi — kunlik grafik chiqdi');

// ---------- o'rnatish tugmasi ----------
await pg.click('[data-screen="profil"]'); await pg.waitForTimeout(400);
must(await pg.locator('[data-act="install-app"]').count() > 0, 'Profilda «Telefonga o‘rnatish» TUGMASI bor (matn emas)');
const order = await pg.$$eval('.card h2', e => e.map(x => x.textContent));
const ix = order.indexOf('Ilovani o‘rnatish');
must(ix >= 0 && ix <= 2, 'Karta yuqorida turibdi (' + (ix + 1) + '-o‘rin: ' + order.slice(0, 3).join(', ') + ')');
await pg.click('[data-act="install-app"]'); await pg.waitForTimeout(400);
must(/Qanday o‘rnatiladi/.test(await pg.locator('#modal').textContent()), 'Brauzer taklif qilmasa — ko‘rsatma oynasi ochiladi');
must(/Ilovani o‘rnatish|Bosh ekranga qo‘shish/.test(await pg.locator('#modal').textContent()), 'Ko‘rsatmada qadamlar bor');
await pg.screenshot({ path: (process.argv[2] || '.') + '/y-install.png' });

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
