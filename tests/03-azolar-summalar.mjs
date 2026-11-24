import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
const log = []; let fails = 0;
const must = (c, m) => { const line = (c ? '✓ ' : '✗ FAIL ') + m; log.push(line); console.log(line); if (!c) fails++; };

const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 840 } });
const errs = [];
pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });

const d = new Date(); const ym = d.toISOString().slice(0, 7);
const prev = new Date(d.getFullYear(), d.getMonth() - 1, 15).toISOString().slice(0, 10);
const seeded = {
  version: 1, currency: 'UZS', me: { id: 'me', name: 'Men' },
  accounts: [{ id: 'a_cash', name: 'Naqd pul', opening: 500000 }],
  categories: [{ id: 'c_food', name: 'Oziq-ovqat', kind: 'expense' }, { id: 'c_tr', name: 'Transport', kind: 'expense' }, { id: 'c_sal', name: 'Oylik', kind: 'income' }],
  transactions: [
    { id: 't1', accountId: 'a_cash', categoryId: 'c_sal', amount: 5000000, type: 'income', note: 'Oylik', date: ym + '-02' },
    { id: 't2', accountId: 'a_cash', categoryId: 'c_food', amount: 800000, type: 'expense', note: 'Bozor', date: ym + '-03' },
    { id: 't3', accountId: 'a_cash', categoryId: 'c_tr', amount: 300000, type: 'expense', note: 'Yoqilg‘i', date: ym + '-04' },
    { id: 't4', accountId: 'a_cash', categoryId: 'c_sal', amount: 4000000, type: 'income', note: 'O‘tgan oy', date: prev }
  ],
  budget: { monthly: 2000000 }, items: [], stock: [], groups: [{
    id: 'g1', name: 'Sayohat', currency: 'UZS', meMemberId: 'me', remote: false,
    members: [{ id: 'me', name: 'Men', role: 'owner', user_id: 'u1' }],
    expenses: [{ id: 'e1', title: 'Ovqat', categoryId: 'c_food', amount: 300000, type: 'expense', paidBy: 'me', date: ym + '-05', splits: [{ memberId: 'me', share: 300000 }] }],
    settlements: []
  }]
};

// Supabase CDN sini bloklaymiz: ilova «bulut sozlanmagan» rejimiga o'tadi,
// guruhlar keshdan tiklanadi va test takrorlanuvchi bo'ladi
await pg.route('**/supabase*.js', r => r.abort());
await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.evaluate(s => {
  localStorage.setItem('birga_v1', JSON.stringify(s));
  localStorage.setItem('birga_groups_cache', JSON.stringify(s.groups));
}, seeded);
await pg.reload({ waitUntil: 'domcontentloaded' });
await pg.waitForTimeout(900);

// ---------- GURUHLAR (bulut uzilishidan oldin, darhol) ----------
let t;
await pg.click('[data-screen="groups"]'); await pg.waitForTimeout(350);
t = await pg.locator('#screen').textContent();
must(/Guruhlar bo‘yicha xarajat/.test(t), 'Guruhlarda grafik bor');
must(!/Hammasini bir martaga hisoblash/.test(t), '«Hammasini bir martaga hisoblash» olib tashlandi');
await pg.screenshot({ path: (process.argv[2] || '.') + '/g-guruhlar.png' });
await pg.click('[data-screen="home"]'); await pg.waitForTimeout(300);

// ---------- GRAFIKA ----------
t = await pg.locator('#screen').textContent();
must(/Oxirgi 6 oy/.test(t), 'Asosiyda «Oxirgi 6 oy» grafigi bor');
must(await pg.locator('#screen svg path').count() >= 3, 'Grafikda ustunlar chizilgan: ' + await pg.locator('#screen svg path').count() + ' ta');
must(/Kirim/.test(await pg.locator('.chleg').textContent()) && /Chiqim/.test(await pg.locator('.chleg').textContent()), 'Grafikda izoh (legend) bor');
const fills = await pg.$$eval('#screen svg path', els => [...new Set(els.map(e => getComputedStyle(e).fill))]);
must(fills.length === 2, 'Ikki xil rang ishlatilgan: ' + fills.join(' / '));
await pg.screenshot({ path: (process.argv[2] || '.') + '/g-asosiy.png' });

await pg.click('[data-screen="tx"]'); await pg.waitForTimeout(400);
t = await pg.locator('#screen').textContent();
must(/Chiqim — kategoriyalar/.test(t), 'Amaliyotlarda kategoriya grafigi bor');
must(await pg.locator('.bltrack span').count() >= 2, 'Kategoriya ustunlari chizilgan');
const w1 = await pg.locator('.bltrack span').first().evaluate(e => e.style.width);
must(parseFloat(w1) === 100, 'Eng katta kategoriya to‘liq ustun (' + w1 + ')');
await pg.click('.chip[data-f="income"]'); await pg.waitForTimeout(400);
must(/Kirim — kategoriyalar/.test(await pg.locator('#screen').textContent()), 'Filtr «Kirim» ga o‘tsa grafik ham o‘zgaradi');
await pg.click('.chip[data-f="all"]'); await pg.waitForTimeout(300);
await pg.screenshot({ path: (process.argv[2] || '.') + '/g-amaliyot.png' });

// ---------- OMBOR: narx mantiqi ----------
await pg.click('[data-screen="ombor"]'); await pg.waitForTimeout(300);
await pg.click('#fab'); await pg.waitForTimeout(300);
must(await pg.locator('input[name="name"]').count() > 0, 'Bo‘sh omborda + bosilsa avval tovar oynasi ochiladi');
await pg.fill('input[name="name"]', 'Mix');
await pg.click('form button[type="submit"]'); await pg.waitForTimeout(500);
must(await pg.locator('#mseg').count() > 0, 'Tovar saqlangach prihod oynasi o‘zi ochiladi');
const mv = async (type, qty, price) => {
  if (await pg.locator('#mseg').count() === 0) { await pg.click('#fab'); await pg.waitForTimeout(300); }
  await pg.click(`#mseg button[data-t="${type}"]`);
  await pg.fill('input[name="qty"]', String(qty));
  await pg.fill('input[name="price"]', String(price));
  await pg.click('form button[type="submit"]'); await pg.waitForTimeout(400);
};
await mv('in', 100000, 7);   // 700 000
await mv('out', 85000, 25);  // 2 125 000
await mv('in', 10000, 8);    //  80 000

if (await pg.locator('[data-act="nav"][data-screen="items"]').count()) { await pg.click('[data-act="nav"][data-screen="items"]'); await pg.waitForTimeout(350); }
await pg.click('.row[data-act="open-item"]'); await pg.waitForTimeout(400);
t = await pg.locator('#screen').textContent();
must(/Oxirgi kirim narxi\s*8 so'm/.test(t.replace(/\s+/g, ' ')), 'Oxirgi kirim narxi = 8 so‘m (eng keyin kiritilgani)');
must(/O‘rtacha kirim narxi\s*7[.,]09 so'm/.test(t.replace(/\s+/g, ' ')), 'O‘rtacha kirim narxi = 7.09 so‘m (780 000 / 110 000)');
// qoldiq 25 000 × 7.0909 = 177 273
must(/185 000/.test(t), 'Qoldiq qiymati FIFO bo‘yicha: 185 000 so‘m (15 000×7 + 10 000×8)');
const firstMove = await pg.locator('.row[data-act="edit-move"]').first().textContent();
must(/8 so'm/.test(firstMove), 'Harakatlar ro‘yxatida eng yangisi tepada: ' + firstMove.replace(/\s+/g, ' ').trim().slice(0, 40));
await pg.screenshot({ path: (process.argv[2] || '.') + '/g-tovar.png' });

// ---------- tovar tanlashda yangi tovar ----------
await pg.click('[data-act="add-move"][data-t="in"]'); await pg.waitForTimeout(300);
const opts = await pg.$$eval('select[name="itemId"] option', e => e.map(x => x.textContent));
must(opts.some(o => /Yangi tovar/.test(o)), 'Tovar tanlashda «+ Yangi tovar…» bor');
await pg.selectOption('select[name="itemId"]', '__new'); await pg.waitForTimeout(400);
must(await pg.locator('input[name="name"]').count() > 0, '«Yangi tovar» tanlansa tovar oynasi ochiladi');
await pg.fill('input[name="name"]', 'Bolt');
await pg.click('form button[type="submit"]'); await pg.waitForTimeout(500);
const sel = await pg.locator('select[name="itemId"]').inputValue().catch(() => '');
const selText = sel ? await pg.locator('select[name="itemId"] option:checked').textContent() : '';
must(/Bolt/.test(selText), 'Yangi tovar saqlangach, prihod oynasi o‘sha tovar bilan ochiladi');

// ---------- kassa izohi ----------
await pg.fill('input[name="qty"]', '10');
await pg.fill('input[name="price"]', '5000');
await pg.waitForTimeout(200);
let hint = await pg.locator('#mhint').textContent();
must(/Faqat ombor hisobi/.test(hint), 'Belgilanmagan holatda izoh: ' + hint.slice(0, 50));
await pg.check('input[name="kassa"]'); await pg.waitForTimeout(250);
hint = await pg.locator('#mhint').textContent();
must(/50 000/.test(hint) && /CHIQIM/.test(hint), 'Belgilangach aniq summa: ' + hint.slice(0, 60));
await pg.screenshot({ path: (process.argv[2] || '.') + '/g-kassa.png' });
await pg.click('.close-x'); await pg.waitForTimeout(300);

// ---------- hisobni noldan boshlash ----------
await pg.click('[data-screen="profil"]'); await pg.waitForTimeout(400);
must(/Hisobni noldan boshlash/.test(await pg.locator('#screen').textContent()), 'Profilda «Hisobni noldan boshlash» tugmasi bor');
const gBefore = await pg.evaluate(() => (JSON.parse(localStorage.getItem('birga_v1')).groups || []).length);
pg.once('dialog', dl => dl.accept());
await pg.click('[data-act="zero-data"]'); await pg.waitForTimeout(600);
const st = await pg.evaluate(() => JSON.parse(localStorage.getItem('birga_v1')));
must(st.transactions.length === 0 && st.stock.length === 0 && st.items.length === 0, 'Amaliyotlar va ombor tozalandi');
must(st.accounts.every(a => a.opening === 0) && st.budget.monthly === 0, 'Hisoblar qoldig‘i va byudjet 0');
must(st.groups.length === gBefore, 'Guruhlar soni o‘zgarmadi (oldin ' + gBefore + ', keyin ' + st.groups.length + ')');

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs.slice(0, 2).join(' / ') : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI (' + log.length + ' ta)'));
process.exit(fails ? 1 : 0);
