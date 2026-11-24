import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 1000 } });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });
pg.on('dialog', d => d.accept());

const D = '2026-11-20';
await pg.route('**/supabase*.js', r => r.abort());
await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.evaluate(d => localStorage.setItem('birga_v1', JSON.stringify({
  version: 1, currency: 'UZS', me: { id: 'me', name: 'Men' },
  accounts: [{ id: 'a', name: 'Naqd', opening: 0 }], categories: [],
  transactions: [], budget: { monthly: 0 }, groups: [],
  items: [
    { id: 'i1', name: 'Etiketka', unit: 'quti', min: 0, cat: 'Tovar' },
    { id: 'i2', name: 'Skotch',   unit: 'dona', min: 0, cat: 'Tovar' },
    { id: 'i3', name: 'Shakar',   unit: 'kg',   min: 0, cat: 'Oziq-ovqat' },
    { id: 'i4', name: 'Qalam',    unit: 'dona', min: 0 }
  ],
  stock: [
    { id: 's1', itemId: 'i1', type: 'in', qty: 100, price: 20000, date: d, txId: null },
    { id: 's2', itemId: 'i2', type: 'in', qty: 50,  price: 10000, date: d, txId: null },
    { id: 's3', itemId: 'i3', type: 'in', qty: 200, price: 9000,  date: d, txId: null },
    { id: 's4', itemId: 'i4', type: 'in', qty: 10,  price: 3000,  date: d, txId: null }
  ]
})), D);
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
await pg.click('[data-screen="ombor"]'); await pg.waitForTimeout(500);

// ---------- Turkumlar kartasi ----------
const tc = pg.locator('.card', { hasText: 'Turkumlar' });
must(await tc.count() === 1, '«Turkumlar» kartasi bor');
let t = (await tc.textContent()).replace(/\s+/g, ' ');
// Tovar: 100×20 000 + 50×10 000 = 2 500 000 ; Oziq-ovqat: 200×9 000 = 1 800 000 ; Turkumsiz: 30 000
must(/Tovar · 2 ta\s*2 500 000/.test(t),      'Tovar turkumi: 2 ta · 2 500 000');
must(/Oziq-ovqat · 1 ta\s*1 800 000/.test(t), 'Oziq-ovqat turkumi: 1 ta · 1 800 000');
must(/Turkumsiz · 1 ta\s*30 000/.test(t),     'Turkumsiz: 1 ta · 30 000');
must(/Jami \(hammasi birga\)\s*4 330 000/.test(t), 'JAMI hammasi birga: 4 330 000');
// jami = ombor qiymati bilan bir xil bo'lsin
must(/Ombor qiymati\s*4 330 000/.test((await pg.locator('#screen').textContent()).replace(/\s+/g, ' ')),
     'Jami «Ombor qiymati» bilan mos');
must(await tc.locator('.bltrack').count() === 3, 'Har turkum uchun ustun bor');
await pg.screenshot({ path: (process.argv[2] || '.') + '/t-turkum.png' });

// ---------- Tovarlar ekranida filtr ----------
await pg.click('[data-act="nav"][data-screen="items"]'); await pg.waitForTimeout(400);
must(await pg.locator('[data-act="icat"]').count() === 4, 'Turkum chiplari: Hamma + 3 ta');
must(await pg.locator('.row[data-act="open-item"]').count() === 4, 'Boshida hamma tovar');
must(/Tovar · 20 000/.test(await pg.locator('#screen').textContent()), 'Qatorda turkum yozilgan');
await pg.click('[data-act="icat"][data-c="Tovar"]'); await pg.waitForTimeout(400);
must(await pg.locator('.row[data-act="open-item"]').count() === 2, '«Tovar» filtri: 2 ta qoldi');
t = await pg.locator('#screen').textContent();
must(/Etiketka/.test(t) && /Skotch/.test(t) && !/Shakar/.test(t), 'Faqat shu turkum tovarlari');
await pg.click('[data-act="icat"][data-c=""]'); await pg.waitForTimeout(400);
must(await pg.locator('.row[data-act="open-item"]').count() === 4, '«Hamma turkum» qaytardi');

// ---------- yangi tovarga turkum berish ----------
await pg.click('[data-act="add-item"]'); await pg.waitForTimeout(400);
must(await pg.locator('#modal input[name="cat"]').count() === 1, 'Tovar oynasida «Turkum» maydoni bor');
must(await pg.locator('#modal datalist#catlist option').count() >= 2, 'Turkum takliflari bor');
await pg.fill('#modal input[name="name"]', 'Guruch');
await pg.fill('#modal input[name="cat"]', 'Oziq-ovqat');
await pg.click('#modal button[type="submit"]'); await pg.waitForTimeout(500);
await pg.click('[data-act="icat"][data-c="Oziq-ovqat"]'); await pg.waitForTimeout(400);
must(await pg.locator('.row[data-act="open-item"]').count() === 2, 'Yangi tovar o‘z turkumiga tushdi');

// tahrirlashda turkum saqlanganmi
await pg.click('.row[data-act="open-item"]:has-text("Guruch")'); await pg.waitForTimeout(400);
await pg.click('[data-act="edit-item"]'); await pg.waitForTimeout(400);
must(await pg.locator('#modal input[name="cat"]').inputValue() === 'Oziq-ovqat', 'Turkum tahrirlashda ko‘rinadi');
await pg.click('#modal .close-x'); await pg.waitForTimeout(300);

// ---------- turkum bitta bo'lsa karta chiqmasin ----------
await pg.evaluate(() => {
  const st = JSON.parse(localStorage.getItem('birga_v1'));
  st.items.forEach(i => { i.cat = 'Tovar'; });
  localStorage.setItem('birga_v1', JSON.stringify(st));
});
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
await pg.click('[data-screen="ombor"]'); await pg.waitForTimeout(500);
must(!/Turkumlar/.test(await pg.locator('#screen').textContent()), 'Bitta turkum bo‘lsa karta chiqmaydi');

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
