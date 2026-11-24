import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 950 } });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });

// bugungi oyni olamiz — "kelajak kunlari ko'rsatilmasin" qoidasi shu oyga tegishli
const now = new Date();
const ym = now.toISOString().slice(0, 7);
const dd = n => ym + '-' + String(n).padStart(2, '0');
const D3 = dd(3), D7 = dd(7);
await pg.route('**/supabase*.js', r => r.abort());
await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.evaluate(d => localStorage.setItem('birga_v1', JSON.stringify({
  version: 1, currency: 'UZS', me: { id: 'me', name: 'Men' },
  accounts: [{ id: 'a', name: 'Naqd', opening: 0 }],
  categories: [{ id: 'c1', name: 'Oziq-ovqat', kind: 'expense' }, { id: 'c3', name: 'Transport', kind: 'expense' }, { id: 'c2', name: 'Oylik', kind: 'income' }],
  transactions: [
    { id: 't1', accountId: 'a', categoryId: 'c2', amount: 2000000, type: 'income', note: 'Oylik', date: d.D3 },
    { id: 't2', accountId: 'a', categoryId: 'c1', amount: 400000, type: 'expense', note: 'Bozor', date: d.D3 },
    { id: 't3', accountId: 'a', categoryId: 'c3', amount: 150000, type: 'expense', note: 'Taksi', date: d.D3 }
  ],
  budget: { monthly: 0 }, groups: [], settings: { chartMonths: 1 },
  items: [{ id: 'i1', name: 'Shakar', unit: 'kg', min: 0 }],
  stock: [
    { id: 's1', itemId: 'i1', type: 'in', qty: 100, price: 10000, date: d.D3, txId: null },
    { id: 's2', itemId: 'i1', type: 'out', qty: 60, price: 15000, date: d.D7, txId: null }
  ]
})), { D3, D7 });
await pg.reload({ waitUntil: 'domcontentloaded' });
await pg.waitForTimeout(900);

// ---------- kunlar ro'yxati olib tashlandi: grafikning o'zi yetarli ----------
let t = await pg.locator('#screen').textContent();
must(!/Kunlar/.test(t), 'Asosiyda «Kunlar» ro‘yxati yo‘q');
must(await pg.locator('.row[data-act="open-day"]').count() === 0, 'Kun qatorlari yo‘q');

// ---------- grafikdan bosish ----------
must(await pg.locator('svg rect[data-act="open-day"]').count() > 0, 'Grafik ustunlari bosiladigan');
await pg.click('svg rect[data-act="open-day"][data-d="' + D3 + '"]'); await pg.waitForTimeout(500);
t = await pg.locator('#screen').textContent();
must(/Kirim\s*2 000 000/.test(t.replace(/\s+/g, ' ')), 'Hisobotda kirim 2 000 000');
must(/Chiqim\s*550 000/.test(t.replace(/\s+/g, ' ')), 'Hisobotda chiqim 550 000');
must(/\+1 450 000/.test(t), 'Sof natija +1 450 000');
must(/Chiqim — kategoriyalar/.test(t), 'Kategoriyalar grafigi bor');
must(/Oziq-ovqat/.test(t) && /Transport/.test(t), 'Ikkala kategoriya ham ko‘rinadi');
must(/Ombor/.test(t) && /Prihod/.test(t), 'Ombor bo‘limi bor (o‘sha kuni prihod bo‘lgan)');
must(/Amaliyotlar/.test(t) && /Oylik/.test(t) && /Bozor/.test(t) && /Taksi/.test(t), 'Uchala amaliyot ro‘yxatda');
await pg.screenshot({ path: (process.argv[2] || '.') + '/k-hisobot.png' });

// kun almashtirish
await pg.click('.icon-btn[data-act="open-day"][aria-label="Keyingi kun"]'); await pg.waitForTimeout(400);
must(/4-/.test(await pg.locator('.month-label').textContent()), 'Keyingi kunga o‘tdi: ' + (await pg.locator('.month-label').textContent()).trim());
must(/yozuv yo‘q/.test(await pg.locator('#screen').textContent()), 'Bo‘sh kunda tegishli xabar');
await pg.click('.icon-btn[data-act="open-day"][aria-label="Oldingi kun"]'); await pg.waitForTimeout(400);
must(/3-/.test(await pg.locator('.month-label').textContent()), 'Oldingi kunga qaytdi');

// ---------- sotuv kuni: foyda ----------
await pg.click('.back-btn'); await pg.waitForTimeout(400);
await pg.click('svg rect[data-act="open-day"][data-d="' + D7 + '"]'); await pg.waitForTimeout(500);
t = await pg.locator('#screen').textContent().then(x => x.replace(/\s+/g, ' '));
must(/Sotuv\s*900 000/.test(t), 'Sotuv kuni: sotuv 900 000 (60 × 15 000)');
must(/Foyda \(FIFO\)\s*\+300 000/.test(t), 'O‘sha kunning foydasi +300 000 (900 000 − 60×10 000)');
await pg.screenshot({ path: (process.argv[2] || '.') + '/k-sotuv.png' });

// FAB o'sha kun sanasi bilan ochilsin
await pg.click('#fab'); await pg.waitForTimeout(400);
must(await pg.locator('input[name="date"]').inputValue() === D7, 'Kun ekranida + bosilsa sana o‘sha kun: ' + await pg.locator('input[name="date"]').inputValue());
await pg.click('.close-x'); await pg.waitForTimeout(300);

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
