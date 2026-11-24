import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 900 } });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });

const ym = '2026-11';
await pg.route('**/supabase*.js', r => r.abort());
await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.evaluate(y => localStorage.setItem('birga_v1', JSON.stringify({
  version: 1, currency: 'UZS', me: { id: 'me', name: 'Men' },
  accounts: [{ id: 'a', name: 'Naqd pul', opening: 0 }],
  categories: [{ id: 'c1', name: 'Oziq-ovqat', kind: 'expense' }, { id: 'c2', name: 'Oylik', kind: 'income' }],
  transactions: [{ id: 't1', accountId: 'a', categoryId: 'c2', amount: 2000000, type: 'income', note: '', date: y + '-05' },
                 { id: 't2', accountId: 'a', categoryId: 'c1', amount: 450000, type: 'expense', note: '', date: y + '-06' }],
  budget: { monthly: 0 }, groups: [],
  items: [{ id: 'i1', name: 'Shakar', unit: 'kg', min: 0 }],
  stock: [{ id: 's1', itemId: 'i1', type: 'in', qty: 100, price: 10000, date: y + '-05', note: '', txId: null },
          { id: 's2', itemId: 'i1', type: 'out', qty: 40, price: 15000, date: y + '-06', note: '', txId: null }]
})), ym);
await pg.reload({ waitUntil: 'domcontentloaded' });
await pg.waitForTimeout(900);

const nav = () => pg.$$eval('.tab', e => e.map(x => x.textContent.trim()));
const scr = () => pg.locator('#screen').textContent();

// ---------- O'ZBEK (asl) ----------
must((await nav()).join('|') === 'Asosiy|Amaliyotlar|Ombor|Guruhlar|Profil', 'O‘zbekcha menyu: ' + (await nav()).join(' '));
must(/Bu oy sof natija/.test(await scr()), 'O‘zbekcha ekran');

// ---------- til kartasi ----------
await pg.click('[data-screen="profil"]'); await pg.waitForTimeout(400);
must(await pg.locator('[data-act="set-lang"]').count() === 3, 'Profilda 3 ta til tugmasi');
must(/O‘zbek/.test(await scr()) && /Русский/.test(await scr()) && /English/.test(await scr()), 'Uchala til nomi ko‘rinadi');

// ---------- RUSCHA ----------
await pg.click('[data-act="set-lang"][data-l="ru"]'); await pg.waitForTimeout(600);
must((await nav()).join('|') === 'Главная|Операции|Склад|Группы|Профиль', 'Ruscha menyu: ' + (await nav()).join(' '));
let t = await scr();
must(/Профиль/.test(t) && /Счета/.test(t) && /Категории/.test(t), 'Profil ruschaga o‘tdi');
must(/Наличные/.test(t), 'Hisob nomi ham tarjima qilindi (Naqd pul → Наличные)');
await pg.screenshot({ path: (process.argv[2] || '.') + '/t-ru-profil.png' });

await pg.click('[data-screen="home"]'); await pg.waitForTimeout(500);
t = await scr();
must(/Чистый итог за месяц/.test(t), 'Asosiy ekran ruscha');
must(/Приход/.test(t) && /Расход/.test(t), 'Kirim/Chiqim tarjima qilindi');
must(/сум/.test(t) && !/so'm/.test(t), 'Valyuta «сум» bo‘ldi');
must(/Ноябрь/.test(t), 'Oy nomi ruscha');
await pg.screenshot({ path: (process.argv[2] || '.') + '/t-ru-asosiy.png' });

await pg.click('[data-screen="ombor"]'); await pg.waitForTimeout(500);
t = await scr();
must(/Стоимость склада/.test(t) && /Прибыль \(FIFO\)/.test(t), 'Ombor ruscha');
must(/Себестоимость продаж/.test(t), 'Tannarx tarjima qilindi');
must(/Товары \(1\)/.test(t), 'Son bilan qo‘shilgan matn ham to‘g‘ri: ' + (t.match(/Товары \([^)]*\)/) || [''])[0]);
await pg.screenshot({ path: (process.argv[2] || '.') + '/t-ru-ombor.png' });

// ---------- INGLIZCHA ----------
await pg.click('[data-screen="profil"]'); await pg.waitForTimeout(400);
await pg.click('[data-act="set-lang"][data-l="en"]'); await pg.waitForTimeout(600);
must((await nav()).join('|') === 'Home|Transactions|Inventory|Groups|Profile', 'Inglizcha menyu: ' + (await nav()).join(' '));
await pg.click('[data-screen="ombor"]'); await pg.waitForTimeout(500);
t = await scr();
must(/Inventory value/.test(t) && /Profit \(FIFO\)/.test(t), 'Ombor inglizcha');
must(/Cost of goods sold/.test(t), 'Tannarx inglizcha');
await pg.screenshot({ path: (process.argv[2] || '.') + '/t-en-ombor.png' });

// ---------- modal va ogohlantirish ----------
await pg.click('[data-act="nav"][data-screen="items"]'); await pg.waitForTimeout(400);
await pg.click('[data-act="add-item"]'); await pg.waitForTimeout(400);
must(/New item/.test(await pg.locator('#modal').textContent()), 'Modal sarlavhasi tarjima qilindi');
must(/Unit/.test(await pg.locator('#modal').textContent()), 'Modal ichidagi yorliqlar ham');
const unitVal = await pg.locator('select[name="unit"]').inputValue();
must(unitVal === 'dona', 'O‘lchov birligi QIYMATI o‘zbekcha qoldi (saqlash uchun): ' + unitVal);
await pg.screenshot({ path: (process.argv[2] || '.') + '/t-en-modal.png' });
await pg.click('.close-x'); await pg.waitForTimeout(300);

// ---------- tanlov saqlanadimi ----------
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
must((await nav()).join('|') === 'Home|Transactions|Inventory|Groups|Profile', 'Til tanlovi saqlanadi');

// ---------- o'zbekchaga qaytish ----------
await pg.click('[data-screen="profil"]'); await pg.waitForTimeout(400);
await pg.click('[data-act="set-lang"][data-l="uz"]'); await pg.waitForTimeout(600);
must((await nav()).join('|') === 'Asosiy|Amaliyotlar|Ombor|Guruhlar|Profil', 'O‘zbekchaga qaytdi');
must(/Foydalanuvchi/.test(await scr()), 'Matnlar asl holatda');

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
